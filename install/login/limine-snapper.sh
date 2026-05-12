if command -v limine &>/dev/null; then
  IS_CACHYOS=false
  if [[ -f /etc/cachyos-release || ( -f /etc/pacman.conf && $(grep -ic 'cachyos' /etc/pacman.conf) -gt 0 ) ]]; then
    IS_CACHYOS=true
  fi

  if [[ $IS_CACHYOS == true ]]; then
    # CachyOS already handles UKI generation via its own presets; adding
    # limine-mkinitcpio-hook would produce a second competing UKI entry
    sudo pacman -S --noconfirm --needed limine-snapper-sync
  else
    sudo pacman -S --noconfirm --needed limine-snapper-sync limine-mkinitcpio-hook
  fi

  if [[ $IS_CACHYOS == true ]]; then
    echo "CachyOS detected: using systemd-based initramfs hooks for improved LUKS support"
    sudo tee /etc/mkinitcpio.conf.d/omarchy_hooks.conf <<EOF >/dev/null
HOOKS=(base systemd plymouth autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck sd-btrfs-overlayfs)
EOF
  else
  sudo tee /etc/mkinitcpio.conf.d/omarchy_hooks.conf <<EOF >/dev/null
HOOKS=(base udev plymouth keyboard autodetect microcode modconf kms keymap consolefont block encrypt filesystems fsck btrfs-overlayfs)
EOF
  fi

  sudo tee /etc/mkinitcpio.conf.d/thunderbolt_module.conf <<EOF >/dev/null
MODULES+=(thunderbolt)
EOF

  echo "Regenerating initramfs with new hooks..."
  sudo mkinitcpio -P -S autorun

  # Detect boot mode
  [[ -d /sys/firmware/efi ]] && EFI=true

  # Find config location
  if [[ -f /boot/EFI/arch-limine/limine.conf ]]; then
    limine_config="/boot/EFI/arch-limine/limine.conf"
  elif [[ -f /boot/EFI/BOOT/limine.conf ]]; then
    limine_config="/boot/EFI/BOOT/limine.conf"
  elif [[ -f /boot/EFI/limine/limine.conf ]]; then
    limine_config="/boot/EFI/limine/limine.conf"
  elif [[ -f /boot/limine/limine.conf ]]; then
    limine_config="/boot/limine/limine.conf"
  elif [[ -f /boot/limine.conf ]]; then
    limine_config="/boot/limine.conf"
  else
    limine_config=""
  fi

  CMDLINE=$(grep "^[[:space:]]*cmdline:" "${limine_config:-/dev/null}" | head -1 | sed 's/^[[:space:]]*cmdline:[[:space:]]*//')

  # Write /etc/default/limine *before* installing limine-mkinitcpio-hook, whose
  # post-transaction deploy hook runs limine-install and reads this file. Without
  # it, ESP_PATH falls back to bootctl, which in a chroot prints a warning that
  # gets captured as the path and trips a spurious "invalid ESP" error.
  sudo cp $OMARCHY_PATH/default/limine/default.conf /etc/default/limine
  sudo sed -i "s|@@CMDLINE@@|$CMDLINE|g" /etc/default/limine

  # Append any drop-in kernel cmdline configs (from hardware fix scripts, etc.)
  for dropin in /etc/limine-entry-tool.d/*.conf; do
    [ -f "$dropin" ] && cat "$dropin" | sudo tee -a /etc/default/limine >/dev/null
  done

  if [[ $IS_CACHYOS != true && -z $limine_config ]]; then
    echo "Limine config not found, skipping Limine sync"
    exit 0
  fi

  # Remove the original config file if it's not /boot/limine.conf, so the deploy
  # hook doesn't see conflicting configs on the same ESP.
  if [[ $limine_config != "/boot/limine.conf" ]] && [[ -f $limine_config ]]; then
    sudo rm "$limine_config"
  fi

  # Let limine-update regenerate /boot/limine.conf based on /etc/default/limine
  # Don't overwrite the existing limine.conf - preserve CachyOS styling
  if [[ $IS_CACHYOS != true ]]; then
    # Remove any non-standard limine.conf locations (archinstall may place it elsewhere)
    for cfg in /boot/limine/limine.conf /boot/EFI/limine/limine.conf /boot/EFI/BOOT/limine.conf /boot/EFI/arch-limine/limine.conf; do
      [[ -f $cfg ]] && sudo rm "$cfg"
    done

    sudo cp $OMARCHY_PATH/default/limine/default.conf /etc/default/limine
    sudo sed -i "s|@@CMDLINE@@|$CMDLINE|g" /etc/default/limine

    # Append any drop-in kernel cmdline configs (from hardware fix scripts, etc.)
    for dropin in /etc/limine-entry-tool.d/*.conf; do
      [ -f "$dropin" ] && cat "$dropin" | sudo tee -a /etc/default/limine >/dev/null
    done

    # UKI and EFI fallback are EFI only
    if [[ -z $EFI ]]; then
      sudo sed -i '/^ENABLE_UKI=/d; /^ENABLE_LIMINE_FALLBACK=/d' /etc/default/limine
    fi
  fi

  sudo pacman -S --noconfirm --needed limine-snapper-sync limine-mkinitcpio-hook

  # Only snapshot root — /home is user data; rolling it back loses user work
  if ! sudo snapper list-configs 2>/dev/null | grep -q "root"; then
    sudo snapper -c root create-config /
  fi
  sudo cp $OMARCHY_PATH/default/snapper/root /etc/snapper/configs/root

  # Disable btrfs quotas — full qgroup accounting is a major performance drag
  sudo btrfs quota disable / 2>/dev/null || true

  chrootable_systemctl_enable limine-snapper-sync.service
fi

# Snapper-safe: skip if /boot is not usable
if ! mountpoint -q /boot || [[ ! -r /boot ]]; then
  echo "Limine: /boot not available, skipping non-essential steps"
  exit 0
fi

echo "Re-enabling mkinitcpio hooks..."

# Restore the specific mkinitcpio pacman hooks
if [[ -f /usr/share/libalpm/hooks/90-mkinitcpio-install.hook.disabled ]]; then
  sudo mv /usr/share/libalpm/hooks/90-mkinitcpio-install.hook.disabled /usr/share/libalpm/hooks/90-mkinitcpio-install.hook
fi

if [[ -f /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook.disabled ]]; then
  sudo mv /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook.disabled /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook
fi

echo "mkinitcpio hooks re-enabled"

# Installing limine-mkinitcpio-hook above already triggered a full UKI rebuild
# (via 80-limine-efi-deploy.hook + 90-mkinitcpio-install.hook), which writes the
# boot entries into /boot/limine.conf. Only fall back to limine-update if those
# hooks didn't run for some reason — running it unconditionally rebuilds every
# UKI a second time.
if ! grep -q "^/+" /boot/limine.conf; then
  sudo limine-update
fi

if ! grep -q "^/+" /boot/limine.conf; then
  echo "Error: failed to add boot entries to /boot/limine.conf" >&2
  exit 1
fi

if [[ -n $EFI ]] && efibootmgr &>/dev/null; then
  # Remove the archinstall-created Limine entry
  while IFS= read -r bootnum; do
    sudo efibootmgr -b "$bootnum" -B >/dev/null 2>&1
  done < <(efibootmgr | grep -E "^Boot[0-9]{4}\*? Arch Linux Limine" | sed 's/^Boot\([0-9]\{4\}\).*/\1/')
fi
