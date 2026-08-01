# Install the AUR-built drivers and fan control Intel MacBooks (non-T2) need.
#
# These live in a per-user leaf rather than install/hardware/apple/ because
# omarchy-pkg-aur-add shells out to yay, and makepkg refuses to build as root.
# The root leaves under install/hardware/apple/ handle the module and suspend
# configuration that needs no package building.

if omarchy-hw-intel-macbook; then
  product_name="$(cat /sys/class/dmi/id/product_name 2>/dev/null)"

  # Audio via the snd-hda-macbookpro DKMS driver (MacBookPro9,x through 14,x).
  # Non-fatal: omarchy-reinstall-mac-audio can rebuild it against a new kernel.
  if [[ $product_name =~ ^MacBookPro ]]; then
    echo "Installing MacBook Pro audio driver..."
    omarchy-pkg-aur-add snd-hda-macbookpro-dkms-git ||
      echo "Warning: snd-hda-macbookpro-dkms-git failed; run omarchy-reinstall-mac-audio later."
  fi

  echo "Installing FaceTime HD webcam drivers..."
  omarchy-pkg-aur-add facetimehd-firmware facetimehd-dkms-git ||
    echo "Warning: FaceTime HD packages failed; the webcam will not work."

  # T2 MacBooks get t2fanrd via install/hardware/apple/fix-t2.sh; Intel (non-T2)
  # MacBooks need mbpfan, since t2fanrd drives its curve through the T2 SMC path.
  echo "Installing fan control for Intel MacBook..."
  if omarchy-pkg-aur-add mbpfan; then
    sudo tee /etc/mbpfan.conf >/dev/null <<EOF
[general]
min_fan1_speed = 1200
max_fan1_speed = 7200
low_temp = 63
high_temp = 75
max_temp = 90
polling_interval = 3
EOF

    sudo systemctl enable --now mbpfan.service
  else
    echo "Warning: mbpfan failed to install; fans stay on the firmware curve."
  fi
fi
