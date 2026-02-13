if command -v limine &>/dev/null; then
  sudo pacman -S --noconfirm --needed limine-snapper-sync limine-mkinitcpio-hook

  if [[ -f /etc/cachyos-release || ( -f /etc/pacman.conf && $(grep -ic 'cachyos' /etc/pacman.conf) -gt 0 ) ]]; then
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

  # Extract cmdline from existing config or /proc/cmdline
  CMDLINE=""
  
  # Try /etc/default/limine first
  if [[ -f /etc/default/limine ]]; then
    CMDLINE=$(grep "^KERNEL_CMDLINE\[default\]=" /etc/default/limine | head -1 | sed 's/^KERNEL_CMDLINE\[default\]="\(.*\)"/\1/' | sed 's/\(quiet\|splash\|loglevel=[0-9]*\)//g' | xargs)
  fi
  
  # Try existing limine.conf entries
  if [[ -z $CMDLINE ]]; then
    for cfg in /boot/limine.conf /boot/limine/limine.conf /boot/EFI/limine/limine.conf /boot/EFI/BOOT/limine.conf /boot/EFI/arch-limine/limine.conf; do
      if [[ -f $cfg ]]; then
        CMDLINE=$(grep "^[[:space:]]*CMDLINE=" "$cfg" | head -1 | sed 's/^[[:space:]]*CMDLINE=//' | sed 's/\(quiet\|splash\|loglevel=[0-9]*\)//g' | xargs)
        [[ -n $CMDLINE ]] && break
      fi
    done
  fi
  
  # Fall back to /proc/cmdline
  if [[ -z $CMDLINE ]]; then
    CMDLINE=$(cat /proc/cmdline | sed 's/\(quiet\|splash\|loglevel=[0-9]*\)//g' | xargs)
  fi

  # Create or update /etc/default/limine with Omarchy settings
  if [[ ! -f /etc/default/limine ]]; then
    # No existing config, create from template
    sudo cp $OMARCHY_PATH/default/limine/default.conf /etc/default/limine
    sudo sed -i "s|@@CMDLINE@@|$CMDLINE|g" /etc/default/limine
    
    # Remove UKI settings on non-EFI systems
    if [[ -z $EFI ]]; then
      sudo sed -i '/^ENABLE_UKI=/d; /^ENABLE_LIMINE_FALLBACK=/d' /etc/default/limine
    fi
  else
    # Existing config, merge Omarchy settings
    echo "Merging Omarchy settings into existing /etc/default/limine..."
    
    # Update or add cmdline (preserve existing, just ensure quiet splash)
    if ! grep -q "quiet splash" /etc/default/limine; then
      sudo sed -i '/^KERNEL_CMDLINE\[default\]+=/d' /etc/default/limine
      echo 'KERNEL_CMDLINE[default]+="quiet splash"' | sudo tee -a /etc/default/limine >/dev/null
    fi
    
    # Add Omarchy branding if not present
    if ! grep -q "^TARGET_OS_NAME=" /etc/default/limine; then
      echo 'TARGET_OS_NAME="Omarchy"' | sudo tee -a /etc/default/limine >/dev/null
    fi
    
    # Add UKI settings for EFI systems
    if [[ -n $EFI ]]; then
      if ! grep -q "^ENABLE_UKI=" /etc/default/limine; then
        echo 'ENABLE_UKI=yes' | sudo tee -a /etc/default/limine >/dev/null
      fi
      if ! grep -q "^CUSTOM_UKI_NAME=" /etc/default/limine; then
        echo 'CUSTOM_UKI_NAME="omarchy"' | sudo tee -a /etc/default/limine >/dev/null
      fi
      if ! grep -q "^ENABLE_LIMINE_FALLBACK=" /etc/default/limine; then
        echo 'ENABLE_LIMINE_FALLBACK=yes' | sudo tee -a /etc/default/limine >/dev/null
      fi
    fi
    
    # Add snapshot settings if not present
    if ! grep -q "^MAX_SNAPSHOT_ENTRIES=" /etc/default/limine; then
      echo 'MAX_SNAPSHOT_ENTRIES=5' | sudo tee -a /etc/default/limine >/dev/null
    fi
    if ! grep -q "^SNAPSHOT_FORMAT_CHOICE=" /etc/default/limine; then
      echo 'SNAPSHOT_FORMAT_CHOICE=5' | sudo tee -a /etc/default/limine >/dev/null
    fi
  fi

  # Let limine-update regenerate /boot/limine.conf based on /etc/default/limine
  # Don't overwrite the existing limine.conf - preserve CachyOS styling


  # Match Snapper configs if not installing from the ISO
  if [[ -z ${OMARCHY_CHROOT_INSTALL:-} ]]; then
    if ! sudo snapper list-configs 2>/dev/null | grep -q "root"; then
      sudo snapper -c root create-config /
    fi

    if ! sudo snapper list-configs 2>/dev/null | grep -q "home"; then
      sudo snapper -c home create-config /home
    fi
  fi

  # Enable quota to allow space-aware algorithms to work
  sudo btrfs quota enable /

  # Tweak default Snapper configs
  sudo sed -i 's/^TIMELINE_CREATE="yes"/TIMELINE_CREATE="no"/' /etc/snapper/configs/{root,home}
  sudo sed -i 's/^NUMBER_LIMIT="50"/NUMBER_LIMIT="5"/' /etc/snapper/configs/{root,home}
  sudo sed -i 's/^NUMBER_LIMIT_IMPORTANT="10"/NUMBER_LIMIT_IMPORTANT="5"/' /etc/snapper/configs/{root,home}
  sudo sed -i 's/^SPACE_LIMIT="0.5"/SPACE_LIMIT="0.3"/' /etc/snapper/configs/{root,home}
  sudo sed -i 's/^FREE_LIMIT="0.2"/FREE_LIMIT="0.3"/' /etc/snapper/configs/{root,home}

  chrootable_systemctl_enable limine-snapper-sync.service
fi

# Snapper-safe: skip if /boot is not usable
if ! mountpoint -q /boot || [[ ! -r /boot ]]; then
  echo "Limine: /boot not available, skipping non-essential steps"
  exit 0
fi

echo "Re-enabling mkinitcpio hooks..."

# Restore the specific mkinitcpio pacman hooks
if [ -f /usr/share/libalpm/hooks/90-mkinitcpio-install.hook.disabled ]; then
  sudo mv /usr/share/libalpm/hooks/90-mkinitcpio-install.hook.disabled /usr/share/libalpm/hooks/90-mkinitcpio-install.hook
fi

if [ -f /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook.disabled ]; then
  sudo mv /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook.disabled /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook
fi

echo "mkinitcpio hooks re-enabled"

sudo limine-update

if [[ -n $EFI ]] && efibootmgr &>/dev/null; then
    # Remove the archinstall-created Limine entry
  while IFS= read -r bootnum; do
    sudo efibootmgr -b "$bootnum" -B >/dev/null 2>&1
  done < <(efibootmgr | grep -E "^Boot[0-9]{4}\*? Arch Linux Limine" | sed 's/^Boot\([0-9]\{4\}\).*/\1/')
fi

# Move this to a utility to allow manual activation
# if [[ -n $EFI ]] && efibootmgr &>/dev/null &&
#   ! cat /sys/class/dmi/id/bios_vendor 2>/dev/null | grep -qi "American Megatrends" &&
#   ! cat /sys/class/dmi/id/bios_vendor 2>/dev/null | grep -qi "Apple"; then
#
#   uki_file=$(find /boot/EFI/Linux/ -name "omarchy*.efi" -printf "%f\n" 2>/dev/null | head -1)
#
#   if [[ -n "$uki_file" ]]; then
#     sudo efibootmgr --create \
#       --disk "$(findmnt -n -o SOURCE /boot | sed 's/p\?[0-9]*$//')" \
#       --part "$(findmnt -n -o SOURCE /boot | grep -o 'p\?[0-9]*$' | sed 's/^p//')" \
#       --label "Omarchy" \
#       --loader "\\EFI\\Linux\\$uki_file"
#   fi
# fi
