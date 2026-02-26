if [[ -n ${OMARCHY_ONLINE_INSTALL:-} ]]; then
  # Install build tools
  omarchy-pkg-add base-devel

  # Configure pacman
  channel=${OMARCHY_CHANNEL:-"stable"}
  SRC_CONF="$OMARCHY_PATH/default/pacman/pacman-$channel.conf"
  SRC_MIRROR="$OMARCHY_PATH/default/pacman/mirrorlist-$channel"

  REFRESH_SCRIPT="$OMARCHY_PATH/bin/omarchy-refresh-pacman"

  if [[ -x "$REFRESH_SCRIPT" ]]; then
    "$REFRESH_SCRIPT" "$channel"
  else
    echo "Warning: $REFRESH_SCRIPT not found or not executable; falling back to copying files" >&2
    sudo cp -f "$SRC_CONF" /etc/pacman.conf
    sudo cp -f "$SRC_MIRROR" /etc/pacman.d/omarchy-mirrorlist
  fi

  sudo pacman-key --recv-keys 40DFB630FF42BCFFB047046CF0134EE680CAC571 --keyserver keys.openpgp.org
  sudo pacman-key --lsign-key 40DFB630FF42BCFFB047046CF0134EE680CAC571

  sudo pacman -Syyu --noconfirm
  omarchy-pkg-add omarchy-keyring

  # Refresh all repos
  sudo pacman -Syyuu --noconfirm
fi
