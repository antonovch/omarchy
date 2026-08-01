# Fix keyboard and Wi-Fi module params for Intel MacBooks (non-T2)
# Covers MacBook8-10, MacBookPro9-14, MacBookAir5-7 (2012-2017)
#
# Audio, webcam and fan control need AUR-built packages, so they live in
# install/user/hardware/apple/fix-intel-macbook.sh instead.

if omarchy-hw-intel-macbook; then
  echo "Detected Intel MacBook: $(cat /sys/class/dmi/id/product_name 2>/dev/null)"

  # applespi module parameters for the SPI keyboard models
  if omarchy-hw-macbook-butterfly; then
    echo "Configuring applespi keyboard parameters..."
    mkdir -p /etc/modprobe.d
    cat <<EOF >/etc/modprobe.d/applespi.conf
options applespi fnmode=2
options applespi fnremap=1
options applespi iso_layout=0
EOF
  fi

  # fix-fkeys.sh already wrote fnmode=2 for Apple-style keyboards generally.
  # swap_opt_cmd is Mac-body-specific, so only add it here and only once.
  if [[ -f /etc/modprobe.d/hid_apple.conf ]]; then
    if ! grep -q "swap_opt_cmd" /etc/modprobe.d/hid_apple.conf; then
      echo "options hid_apple swap_opt_cmd=1" >>/etc/modprobe.d/hid_apple.conf
    fi
  else
    mkdir -p /etc/modprobe.d
    cat <<EOF >/etc/modprobe.d/hid_apple.conf
options hid_apple fnmode=2
options hid_apple swap_opt_cmd=1
EOF
  fi

  # Intel MacBook Wi-Fi (iwlwifi) drops connections with power saving enabled
  if [[ ! -f /etc/modprobe.d/iwlwifi.conf ]]; then
    echo "Disabling iwlwifi power saving for stability..."
    mkdir -p /etc/modprobe.d
    cat <<EOF >/etc/modprobe.d/iwlwifi.conf
# Disable power saving on Intel WiFi for MacBook stability
options iwlwifi power_save=0
options iwlmvm power_scheme=1
EOF
  fi
fi
