# Configure pacman via the centralized refresh script
mirror=${OMARCHY_MIRROR:-"edge"}
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REFRESH_SCRIPT="$REPO_ROOT/bin/omarchy-refresh-pacman"

if [[ -x "$REFRESH_SCRIPT" ]]; then
  "$REFRESH_SCRIPT" "$mirror"
else
  # Fallback: copy the channel files directly
  SRC_CONF="$HOME/.local/share/omarchy/default/pacman/pacman-${mirror}.conf"
  SRC_MIRROR="$HOME/.local/share/omarchy/default/pacman/mirrorlist-${mirror}"
  sudo cp -f "$SRC_CONF" /etc/pacman.conf
  sudo cp -f "$SRC_MIRROR" /etc/pacman.d/mirrorlist
fi

if lspci -nn | grep -q "106b:180[12]"; then
  ARCH_SERVER='Server = https://github.com/NoaHimesaka1873/arch-mact2-mirror/releases/download/release'

  if grep -q '^\[arch-mact2\]' /etc/pacman.conf; then
    if sed -n "/^\[arch-mact2\]/,/^\[/p" /etc/pacman.conf | grep -q 'pkgs.omarchy.org'; then
      sudo sed -i "/^\[arch-mact2\]/,/^\[/ s|^Server = .*|${ARCH_SERVER}|" /etc/pacman.conf
    else
      sudo sed -i "/^\[arch-mact2\]/ a ${ARCH_SERVER}" /etc/pacman.conf
    fi

    if ! sed -n "/^\[arch-mact2\]/,/^\[/p" /etc/pacman.conf | grep -q '^SigLevel'; then
      sudo sed -i "/^\[arch-mact2\]/ a SigLevel = Never" /etc/pacman.conf
    fi
  else
    cat <<EOF | sudo tee -a /etc/pacman.conf >/dev/null

[arch-mact2]
${ARCH_SERVER}
SigLevel = Never
EOF
  fi
fi
