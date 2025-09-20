# Install all base packages
mapfile -t packages < <(grep -v '^#' "$OMARCHY_INSTALL/omarchy-base.packages" | grep -v '^$')
sudo pacman -S --noconfirm --needed "${packages[@]}"

mapfile -t packages < <(grep -v '^#' "$OMARCHY_INSTALL/omarchy-aur.packages" | grep -v '^$')
yay -S --noconfirm --needed "${packages[@]}"
