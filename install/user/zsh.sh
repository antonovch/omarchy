# zsh with oh-my-zsh as the login shell. Omarchy seeds ~/.bashrc from /etc/skel,
# so the zsh equivalent is placed here instead.

omarchy-pkg-add zsh || return 0

if [[ ! -d $HOME/.oh-my-zsh ]]; then
  echo "Installing oh-my-zsh..."
  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended ||
    echo "Warning: oh-my-zsh install failed; ~/.zshrc will load without it."
fi

ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
if [[ ! -d $ZSH_CUSTOM/plugins/zsh-autosuggestions ]]; then
  git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions" 2>/dev/null ||
    echo "Warning: could not install zsh-autosuggestions."
fi

# Don't clobber a ~/.zshrc that has already been edited on this machine.
if [[ ! -f $HOME/.zshrc ]]; then
  cp "$OMARCHY_PATH/default/zshrc" "$HOME/.zshrc"
fi

if [[ $SHELL != "/bin/zsh" ]] && omarchy-cmd-present zsh; then
  sudo chsh -s /bin/zsh "$(id -un)"
fi
