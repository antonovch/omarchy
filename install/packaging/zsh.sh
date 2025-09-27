#!/bin/bash

echo "Installing zsh and oh-my-zsh..."

# Install packages
omarchy-pkg-add zsh zsh-autosuggestions

# Install oh-my-zsh non-interactively
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Set zsh as default shell
if [ "$SHELL" != "/bin/zsh" ]; then
  sudo chsh -s /bin/zsh $USER
fi
