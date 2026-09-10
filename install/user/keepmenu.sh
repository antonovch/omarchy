# Install keepmenu (KeePass entry picker driven through the Omarchy menu).
#
# The passphrase prompt goes to `omarchy-pinentry` (config/keepmenu/config.ini),
# a pinentry backend that ships with Omarchy itself and prompts through the
# Quickshell shell, so no separate pinentry package/gnome-keyring dependency is
# needed here.

omarchy-pkg-aur-add keepmenu || echo "Warning: keepmenu failed to install."
