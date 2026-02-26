# Setup GPG configuration with multiple keyservers for better reliability
sudo mkdir -p /etc/gnupg
sudo cp ~/.local/share/omarchy/default/gpg/dirmngr.conf /etc/gnupg/
sudo chmod 644 /etc/gnupg/dirmngr.conf

if [[ -z ${OMARCHY_INSTALLING:-} ]]; then
  sudo gpgconf --kill dirmngr 2>/dev/null || true
  sudo gpgconf --launch dirmngr 2>/dev/null || true
fi
