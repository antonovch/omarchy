# Ensure that F-keys on Apple-like keyboards (such as Lofree Flow84) are always F-keys.
# Apple Silicon is left alone: the omarchy-mac package owns its keyboard mode.
conf="${OMARCHY_HID_APPLE_CONF:-/etc/modprobe.d/hid_apple.conf}"
if [[ ! -f $conf ]] && ! omarchy-hw-aarch64-apple; then
  sudo mkdir -p "$(dirname "$conf")"
  echo "options hid_apple fnmode=2" | sudo tee "$conf" >/dev/null
fi

# Built-in Apple keyboards need hid_apple in the initramfs to be usable at the
# encryption passphrase prompt. MODULES+= so other drop-ins keep their modules.
if [[ ! -f /etc/mkinitcpio.conf.d/hid_apple.conf ]]; then
  sudo mkdir -p /etc/mkinitcpio.conf.d
  echo "MODULES+=(hid_apple)" | sudo tee /etc/mkinitcpio.conf.d/hid_apple.conf >/dev/null
fi
