if [[ -n ${OMARCHY_ONLINE_INSTALL:-} ]]; then
  # Install build tools
  sudo pacman -S --needed --noconfirm base-devel

  # Configure pacman
  mirror=${OMARCHY_MIRROR:-"edge"}
  SRC_CONF="$HOME/.local/share/omarchy/default/pacman/pacman.conf"
  SRC_MIRROR="$HOME/.local/share/omarchy/default/pacman/mirrorlist-${mirror}"

  REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  REFRESH_SCRIPT="$REPO_ROOT/bin/omarchy-refresh-pacman"

  if [[ -x "$REFRESH_SCRIPT" ]]; then
    "$REFRESH_SCRIPT" "$mirror"
  else
    echo "Warning: $REFRESH_SCRIPT not found or not executable; falling back to copying files" >&2
    sudo cp -f "$SRC_CONF" /etc/pacman.conf
    sudo cp -f "$SRC_MIRROR" /etc/pacman.d/mirrorlist
  fi

  sudo pacman-key --recv-keys 40DFB630FF42BCFFB047046CF0134EE680CAC571 --keyserver keys.openpgp.org
  sudo pacman-key --lsign-key 40DFB630FF42BCFFB047046CF0134EE680CAC571

  sudo pacman -Sy
  sudo pacman -S --noconfirm --needed omarchy-keyring


  # Refresh all repos
  sudo pacman -Syyu --noconfirm
fi
