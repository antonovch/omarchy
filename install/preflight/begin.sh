clear_logo
gum style --foreground 3 --padding "1 0 0 $PADDING_LEFT" "Installing..."
echo

# Authenticate sudo upfront so subsequent sudo calls (including yay builds) don't prompt
sudo -v

start_install_log
