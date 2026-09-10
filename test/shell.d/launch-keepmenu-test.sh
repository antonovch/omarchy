#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

launcher="$ROOT/bin/omarchy-launch-keepmenu"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mock_bin="$tmpdir/bin"
mkdir -p "$mock_bin"
cat >"$mock_bin/keepmenu" <<'SH'
#!/bin/bash

printf 'keepmenu:%s|%s\n' "$*" "${OMARCHY_PINENTRY_LABEL:-}"
SH
chmod +x "$mock_bin/keepmenu"

new_home() {
  fake_home="$tmpdir/$1"
  alias_path="$fake_home/.local/state/omarchy/keepmenu/dmenu"
  config_file="$fake_home/.config/keepmenu/config.ini"
  mkdir -p "$fake_home"
}

run_launcher() {
  HOME="$fake_home" OMARCHY_PATH="$ROOT" PATH="$mock_bin:$PATH" "$launcher" "$@"
}

# A first launch has to build everything: the dmenu-named alias, the seeded
# config, and the pointer between them.
new_home fresh
output=$(run_launcher)

[[ $output == "keepmenu:|KeePass database" ]] ||
  fail "launcher hands off to keepmenu" "output: $output"
pass "launcher hands off to keepmenu"

[[ -x $alias_path ]] ||
  fail "launcher creates an executable dmenu alias" "missing: $alias_path"
pass "launcher creates an executable dmenu alias"

grep -q "exec omarchy-menu-dmenu" "$alias_path" ||
  fail "the alias delegates to omarchy-menu-dmenu" "$(cat "$alias_path")"
pass "the alias delegates to omarchy-menu-dmenu"

grep -qF "dmenu_command = $alias_path" "$config_file" ||
  fail "launcher points keepmenu at the alias" "$(grep dmenu_command "$config_file")"
pass "launcher points keepmenu at the alias"

# The seed has to be the shipped config, not keepmenu's own bare default.
grep -q "^pinentry = omarchy-pinentry$" "$config_file" ||
  fail "launcher seeds the shipped Omarchy config" "$(cat "$config_file")"
pass "launcher seeds the shipped Omarchy config"

# Running again must not append a second pointer or disturb the first.
run_launcher >/dev/null
(( $(grep -c "^dmenu_command" "$config_file") == 1 )) ||
  fail "launcher stays idempotent" "$(grep -n dmenu_command "$config_file")"
pass "launcher stays idempotent"

# The passphrase dialog has to name the database, not just say "password".
new_home labelled
mkdir -p "$(dirname "$config_file")"
printf '[dmenu]\ndmenu_command = omarchy-menu-dmenu\n[database]\ndatabase_1 = ~/Sync/passes.kdbx\nkeyfile_1 = \n' >"$config_file"
output=$(run_launcher)

[[ $output == "keepmenu:|KeePass database: ~/Sync/passes.kdbx" ]] ||
  fail "launcher names the single configured database" "output: $output"
pass "launcher names the single configured database"

# A user who picked their own menu keeps it; only the shipped default is claimed.
new_home custom
mkdir -p "$(dirname "$config_file")"
printf '[dmenu]\ndmenu_command = rofi -dmenu\npinentry = omarchy-pinentry\n' >"$config_file"
run_launcher >/dev/null

grep -q "^dmenu_command = rofi -dmenu$" "$config_file" ||
  fail "launcher leaves a customized menu command alone" "$(grep dmenu_command "$config_file")"
pass "launcher leaves a customized menu command alone"
