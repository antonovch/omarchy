# Fix audio, webcam, and keyboard module params for Intel MacBooks (non-T2)
# Covers MacBook8-10, MacBookPro9-14, MacBookAir5-7 (2012-2017)

if ! omarchy-hw-intel-macbook; then
  return 0 2>/dev/null || exit 0
fi

product_name="$(cat /sys/class/dmi/id/product_name 2>/dev/null)"
echo "Detected Intel MacBook: $product_name"

# Ensure kernel headers are available for DKMS modules
if pacman -Q linux-cachyos &>/dev/null || pacman -Q linux-cachyos-lto &>/dev/null; then
  sudo pacman -S --noconfirm --needed linux-cachyos-headers
fi

# 1) Audio support via snd-hda-macbookpro DKMS driver
#    Supports MacBookPro9,x through MacBookPro14,x
if [[ $product_name =~ ^MacBookPro ]]; then
  echo "Installing MacBook Pro audio driver..."
  omarchy-pkg-aur-add snd-hda-macbookpro-dkms-git
fi

# 2) FaceTime HD webcam support
echo "Installing FaceTime HD webcam drivers..."
omarchy-pkg-aur-add facetimehd-firmware facetimehd-dkms-git

# 3) Configure applespi module parameters for SPI keyboard models
if [[ $product_name =~ MacBook[89],1|MacBook10,1|MacBookPro13,[123]|MacBookPro14,[123] ]]; then
  echo "Configuring applespi keyboard parameters..."
  cat <<EOF | sudo tee /etc/modprobe.d/applespi.conf >/dev/null
# Apple SPI keyboard settings for Intel MacBooks
options applespi fnmode=2
options applespi fnremap=1
options applespi iso_layout=0
EOF
fi

# 4) Ensure hid_apple is loaded in initramfs for compatibility with older models
#    and external Apple keyboards. The fix-fkeys.sh script may have already created
#    this, but we ensure swap_opt_cmd is set for Intel MacBook keyboard layout.
if [[ ! -f /etc/mkinitcpio.conf.d/hid_apple.conf ]]; then
  echo "MODULES+=(hid_apple)" | sudo tee /etc/mkinitcpio.conf.d/hid_apple.conf >/dev/null
fi

if [[ ! -f /etc/modprobe.d/hid_apple.conf ]]; then
  cat <<EOF | sudo tee /etc/modprobe.d/hid_apple.conf >/dev/null
options hid_apple fnmode=2
options hid_apple swap_opt_cmd=1
EOF
else
  # Ensure swap_opt_cmd is present if the file already exists
  if ! grep -q "swap_opt_cmd" /etc/modprobe.d/hid_apple.conf; then
    echo "options hid_apple swap_opt_cmd=1" | sudo tee -a /etc/modprobe.d/hid_apple.conf >/dev/null
  fi
fi

# 5) Disable iwlwifi power saving for stability
#    Intel MacBook WiFi (iwlwifi) can drop connections with power saving enabled
if [[ ! -f /etc/modprobe.d/iwlwifi.conf ]]; then
  echo "Disabling iwlwifi power saving for stability..."
  cat <<EOF | sudo tee /etc/modprobe.d/iwlwifi.conf >/dev/null
# Disable power saving on Intel WiFi for MacBook stability
options iwlwifi power_save=0
options iwlmvm power_scheme=1
EOF
fi

# 6) Set up Retina display monitor config if eDP-1 is present and no monitorv2 configured yet
if hyprctl monitors -j 2>/dev/null | grep -q '"name": "eDP-1"'; then
  if ! grep -q "monitorv2" ~/.config/hypr/monitors.conf 2>/dev/null; then
    echo "Configuring Retina display for MacBook..."
    cat <<'EOF' > ~/.config/hypr/monitors.conf
# Intel MacBook Retina display (auto-configured by Omarchy)
# See https://wiki.hyprland.org/Configuring/Monitors/

env = GDK_SCALE, 1.25

monitorv2 {
    output = eDP-1
    mode = 2560x1600@60
    position = auto
    scale = 1.33
}

# Add external monitor configuration below
# monitorv2 {
#     output = DP-1
#     mode = preferred
#     position = auto
#     scale = 1
# }
EOF
  fi
fi
