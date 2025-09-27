#!/bin/bash

echo "Installing zsh and oh-my-zsh..."

# Install packages
omarchy-pkg-add zsh

# Install oh-my-zsh non-interactively
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Install zsh-autosuggestions plugin
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi


# Set zsh as default shell
if [ "$SHELL" != "/bin/zsh" ]; then
  sudo chsh -s /bin/zsh $USER
fi
