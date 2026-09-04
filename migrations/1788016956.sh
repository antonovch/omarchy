echo "Stop udiskie from prompting for a passphrase on every encrypted drive insert"

# Only seed. A user who already has a udiskie config keeps it; the explicit
# way to take the shipped default is omarchy-refresh-config udiskie/config.yml.
[[ -f "$HOME/.config/udiskie/config.yml" ]] || omarchy-refresh-config udiskie/config.yml

# Outside a graphical session -- an update over SSH -- there is no running
# udiskie to hand the new config to; the next login's autostart picks it up.
if systemctl --user is-active --quiet graphical-session.target; then
  pkill -x udiskie >/dev/null 2>&1 || true
  uwsm-app -- udiskie --automount --no-notify --no-tray >/dev/null 2>&1 &
  disown
fi
