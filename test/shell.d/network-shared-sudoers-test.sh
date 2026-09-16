#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

net_shared="$ROOT/bin/omarchy-network-shared"
sudoers_file="$ROOT/etc/sudoers.d/omarchy-network-shared"
rule='%wheel ALL=(root) NOPASSWD: /usr/bin/omarchy-network-shared shared, /usr/bin/omarchy-network-shared wan'

# Exactly one rule, matched whole. A second line -- or the same command with its
# arguments dropped, which sudoers reads as "any arguments" -- would widen the
# grant while leaving this line in place.
rules=$(grep -vE '^[[:space:]]*(#|$)' "$sudoers_file")
[[ $rules == "$rule" ]] ||
  fail "network-shared sudoers file carries exactly the shared/wan rule and nothing else" "got: $rules"

if command -v visudo >/dev/null; then
  visudo -cf "$sudoers_file" >/dev/null || fail "network-shared sudoers rule parses"
fi

grep -Fx 'PACKAGED_PATH=/usr/bin/omarchy-network-shared' "$net_shared" >/dev/null ||
  fail "omarchy-network-shared elevates the path the sudoers rule names"

# `sudo -l` on its own answers whether a command is permitted, not whether it
# is passwordless, and Omarchy ships a blanket %wheel rule that permits
# everything. Only the long listing prints the matched entry's tags.
grep -E 'sudo -n -l -l' "$net_shared" >/dev/null ||
  fail "omarchy-network-shared reads the grant from the long sudo listing"

pass "network-shared sudoers rule is scoped to the shared/wan modes"

# The privileged half runs as root under sudo's secure_path, and a dev link
# (etc/sudoers.d/omarchy-dev-path) prepends a user-writable checkout bin/ to it.
# nmcli, ufw and omarchy-cmd-present are never this script's own checkout, so
# once it holds root the script pins PATH to trusted system directories and
# never resolves one of them out of the checkout. The unprivileged wrapper
# phase keeps the caller's PATH, which is why the pin is gated on EUID rather
# than set unconditionally.
grep -Eq '^\s*export PATH=/usr/local/sbin:/usr/local/bin:/usr/bin' "$net_shared" ||
  fail "omarchy-network-shared pins PATH to trusted system directories when it holds root"
# require_root carries its own `(( EUID == 0 ))`, so matching that text alone
# would pass with the pin deleted. Anchor on the unindented guard and require the
# pin to be the line it opens.
gated=$(grep -A1 -E '^if \(\( EUID == 0 \)\); then$' "$net_shared" || true)
[[ $gated == *"export PATH=/usr/local/sbin:/usr/local/bin:/usr/bin"* ]] ||
  fail "omarchy-network-shared gates the trusted-PATH pin on holding root"

# The no-argument path only reads the current mode, so exercise the privileged
# phase directly when the suite is root and as namespaced root otherwise. This
# reaches nmcli while EUID is 0 without giving an ordinary test run any host
# privileges.
root_runner=()
if (( EUID != 0 )); then
  root_runner=(unshare --user --map-root-user)
fi

# A sandbox or a hardened kernel can refuse unprivileged user namespaces, and
# the non-graphical suites have to stay green on any machine -- a skip is a
# passing test. Only the runtime probe needs the namespace; the static checks
# above and the elevation checks below run either way.
if (( EUID == 0 )) || unshare --user --map-root-user true 2>/dev/null; then
  poison_dir=$(mktemp -d)
  poison_ran="$poison_dir/ran"
  cat >"$poison_dir/nmcli" <<SH
#!/bin/bash
printf 'x' >"$poison_ran"
exec "/usr/bin/nmcli" "\$@"
SH
  chmod +x "$poison_dir/nmcli"

  PATH="$poison_dir:$PATH" "${root_runner[@]}" bash "$net_shared" </dev/null >/dev/null 2>&1 || true
  if [[ -e $poison_ran ]]; then
    rm -rf "$poison_dir"
    fail "root omarchy-network-shared resolved a bare helper from the front of PATH instead of a trusted system path"
  fi
  rm -rf "$poison_dir"
  pass "root omarchy-network-shared resolves system helpers from a trusted PATH, not the invocation PATH"
else
  pass "no unprivileged user namespace; skipping the root trusted-PATH probe"
fi

# require_root returns immediately for root, so the stubs below would not stand
# between the script and the host's real NetworkManager and firewall.
if (( EUID == 0 )); then
  pass "running as root; skipping the elevation checks, which would rewrite this machine's network mode"
  exit 0
fi

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

stub_bin="$test_tmp/bin"
mkdir -p "$stub_bin"

# A single wired device with an active profile in "wan" mode, so wired_device,
# connection_for and current_mode all resolve without touching the real host.
cat >"$stub_bin/nmcli" <<'SH'
#!/bin/bash
case "$*" in
  "-t -f DEVICE,TYPE device status")
    echo "eth0:ethernet"
    ;;
  "-t -f UUID,DEVICE connection show --active")
    echo "11111111-1111-1111-1111-111111111111:eth0"
    ;;
  "-g ipv4.method connection show 11111111-1111-1111-1111-111111111111")
    echo "auto"
    ;;
esac
exit 0
SH
chmod +x "$stub_bin/nmcli"

# pkexec stands in for the exec at the end of require_root, so the network and
# firewall writes below it never run and real pkexec is never reached.
cat >"$stub_bin/pkexec" <<'SH'
#!/bin/bash
printf 'pkexec %s\n' "$*" >"$ELEVATION_LOG"
SH
chmod +x "$stub_bin/pkexec"

# The sudo stub plays both parts: it answers the passwordless probe from
# STUB_GRANTED, the modes etc/sudoers.d/omarchy-network-shared covers on this
# machine, and logs the elevation otherwise. STUB_GRANTED empty stands for an
# install whose omarchy-settings predates the file.
cat >"$stub_bin/sudo" <<'SH'
#!/bin/bash
if [[ $1 == -n && $2 == -l ]]; then
  for granted in ${STUB_GRANTED-shared wan}; do
    [[ ${!#} == "$granted" ]] || continue
    echo "    Options: !authenticate"
    exit 0
  done
  echo "    Matched: ${!#}"
  exit 0
fi
printf 'sudo %s\n' "$*" >"$ELEVATION_LOG"
SH
chmod +x "$stub_bin/sudo"

elevation_for() {
  : >"$test_tmp/elevation"
  ELEVATION_LOG="$test_tmp/elevation" \
  PATH="$stub_bin:$PATH" \
    bash "$net_shared" "$1" </dev/null >/dev/null
  cat "$test_tmp/elevation"
}

for target in shared wan; do
  elevation=$(elevation_for "$target")
  [[ $elevation == "sudo /usr/bin/omarchy-network-shared $target" ]] ||
    fail "omarchy-network-shared takes the passwordless sudo grant for $target without a terminal" "got: $elevation"
done

pass "omarchy-network-shared elevates shared/wan through sudo, not polkit"

# A dev-linked checkout elevates the packaged path like everyone else, rather
# than handing sudo a path no rule can name and losing the grant.
dev_linked=$(OMARCHY_PATH="$test_tmp/checkout" elevation_for shared)
[[ $dev_linked == "sudo /usr/bin/omarchy-network-shared shared" ]] ||
  fail "omarchy-network-shared elevates the system install wherever OMARCHY_PATH points" "got: $dev_linked"

# The grant is what makes sudo passwordless, so its absence -- an install still
# on an older omarchy-settings -- has to route to polkit. Betting on sudo here
# leaves the menu's one-click toggle execing into a password prompt it has no
# terminal to show.
ungranted=$(STUB_GRANTED="" elevation_for shared)
[[ $ungranted == "pkexec /usr/bin/omarchy-network-shared shared" ]] ||
  fail "omarchy-network-shared falls back to polkit where the sudoers grant is not installed" "got: $ungranted"

pass "omarchy-network-shared falls back to polkit wherever the grant does not reach"
