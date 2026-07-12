# Detect MacBook models that need SPI keyboard modules
if omarchy-hw-macbook-butterfly; then
  product_name="$(cat /sys/class/dmi/id/product_name 2>/dev/null)"
  echo "Detected MacBook with SPI keyboard: $product_name"

  if pacman -Q linux-cachyos &>/dev/null || pacman -Q linux-cachyos-lto &>/dev/null; then
    sudo pacman -S --noconfirm --needed linux-cachyos-headers
  fi

  omarchy-pkg-add macbook12-spi-driver-dkms
  if [[ "$product_name" == "MacBook8,1" ]]; then
    echo "MODULES=(applespi spi_pxa2xx_platform spi_pxa2xx_pci)" | sudo tee /etc/mkinitcpio.conf.d/macbook_spi_modules.conf >/dev/null
  else
    echo "MODULES=(applespi intel_lpss_pci spi_pxa2xx_platform)" | sudo tee /etc/mkinitcpio.conf.d/macbook_spi_modules.conf >/dev/null
  fi
fi
