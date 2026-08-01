# Install keepmenu (KeePass entry picker driven through the Omarchy menu).
# pinentry-gnome3 matches the gnome-keyring stack Omarchy already installs, and
# the Quickshell menu has no obscured-input mode to prompt for the database
# passphrase safely.

omarchy-pkg-add pinentry-gnome3 || echo "Warning: pinentry-gnome3 failed to install."
omarchy-pkg-aur-add keepmenu || echo "Warning: keepmenu failed to install."
