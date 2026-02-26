# Ensure that F-keys on Apple-like keyboards (such as Lofree Flow84) are always F-keys
if [[ ! -f /etc/modprobe.d/hid_apple.conf ]]; then
  echo "MODULES+=(hid_apple)" | sudo tee /etc/mkinitcpio.conf.d/hid_apple.conf >/dev/null
  echo "options hid_apple fnmode=2"           | sudo tee /etc/modprobe.d/hid_apple.conf
  echo "options hid_apple swap_opt_cmd=1"     | sudo tee -a /etc/modprobe.d/hid_apple.conf
  # echo "options hid_apple swap_fn_leftctrl=1" | sudo tee -a /etc/modprobe.d/hid_apple.conf
fi
