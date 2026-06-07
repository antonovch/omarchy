# Enable DDC/CI external display brightness control via i2c-dev.
# Adds user to the i2c group (created by ddcutil's udev rules) and ensures
# the i2c-dev kernel module is loaded at boot.

sudo usermod -aG i2c ${USER}

echo "i2c-dev" | sudo tee /etc/modules-load.d/i2c.conf >/dev/null
