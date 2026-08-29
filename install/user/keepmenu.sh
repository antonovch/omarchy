# Install keepmenu (KeePass entry picker driven through the Omarchy menu).
#
# The passphrase prompt goes to pinentry rather than the Omarchy menu, which has
# no obscured-input mode. config/keepmenu/config.ini asks for pinentry-gnome3:
# that is a binary inside the pinentry package, not a package of its own, and it
# talks to the gnome-keyring/gcr stack Omarchy already installs. gnupg depends on
# pinentry, so this is normally a no-op -- it is here so the config's requirement
# is stated rather than assumed.
omarchy-pkg-add pinentry || echo "Warning: pinentry failed to install; keepmenu cannot prompt for the database passphrase."

omarchy-pkg-aur-add keepmenu || echo "Warning: keepmenu failed to install."
