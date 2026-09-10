#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

dmenu="$ROOT/bin/omarchy-menu-dmenu"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mock_bin="$tmpdir/bin"
mkdir -p "$mock_bin"

cat >"$mock_bin/omarchy-menu-input" <<'SH'
#!/bin/bash

printf 'input: %s\n' "$*"
SH

cat >"$mock_bin/omarchy-menu-select" <<'SH'
#!/bin/bash

printf 'select: %s\n' "$*"
SH

chmod +x "$mock_bin/omarchy-menu-input" "$mock_bin/omarchy-menu-select"

run_dmenu() {
  local stdin="$1"
  shift
  printf '%s' "$stdin" | PATH="$mock_bin:$PATH" "$dmenu" "$@"
}

# dmenu with nothing on stdin still prompts and returns typed text, so the shim
# routes an empty option list to the free-text menu instead of failing. This is
# how keepmenu asks for its database path on first run.
output=$(run_dmenu "" -p "Enter path")
[[ $output == "input: Enter path --width 520" ]] ||
  fail "empty stdin prompts for free-text input" "output: $output"
pass "empty stdin prompts for free-text input"

# Blank lines are skipped while collecting options, so a stdin of only newlines
# is still an empty option list.
output=$(run_dmenu $'\n\n' -p "Enter path")
[[ $output == "input: Enter path --width 520" ]] ||
  fail "blank-only stdin prompts for free-text input" "output: $output"
pass "blank-only stdin prompts for free-text input"

output=$(run_dmenu "" -p "Enter path" -- --width 400)
[[ $output == "input: Enter path --width 400" ]] ||
  fail "an explicit width wins over the widened default" "output: $output"
pass "an explicit width wins over the widened default"

# Options on stdin keep going to the selection menu.
output=$(run_dmenu $'alpha\nbeta\n' -p Pick)
[[ $output == "select: Pick alpha beta" ]] ||
  fail "options on stdin go to the selection menu" "output: $output"
pass "options on stdin go to the selection menu"

output=$(run_dmenu $'alpha\n' -p Pick -- --width 400)
[[ $output == "select: Pick alpha -- --width 400" ]] ||
  fail "options on stdin forward menu args to the selection menu" "output: $output"
pass "options on stdin forward menu args to the selection menu"
