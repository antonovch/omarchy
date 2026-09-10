#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

pinentry="$ROOT/bin/omarchy-pinentry"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

setup_scenario() {
  scenario_dir="$tmpdir/$1"
  mock_bin="$scenario_dir/bin"
  call_log="$scenario_dir/calls"
  mkdir -p "$mock_bin"
  : >"$call_log"
}

run_pinentry() {
  set +e
  output=$(PATH="$mock_bin:$PATH" "$pinentry" <<<"$1")
  exit_status=$?
  set -e
  mapfile -t calls <"$call_log"
}

# A submitted password comes back as a `D <pin>` line followed by `OK`, and the
# shell is asked to show the SETDESC message that came before GETPIN.
setup_scenario success
cat >"$mock_bin/omarchy-shell" <<'SH'
#!/bin/bash

printf '%s\n' "$*" >>"$CALL_LOG"
payload="$3"
selection_file=$(perl -MJSON::PP=decode_json -e 'print decode_json($ARGV[0])->{selectionFile}' "$payload")
done_file=$(perl -MJSON::PP=decode_json -e 'print decode_json($ARGV[0])->{doneFile}' "$payload")
printf '%s' "hunter2" > "$selection_file"
: > "$done_file"
printf 'ok\n'
SH
chmod +x "$mock_bin/omarchy-shell"
CALL_LOG="$call_log" run_pinentry $'SETDESC Enter password for vault.kdbx\nGETPIN\n'

[[ ${calls[0]} == "pinentry show "*"vault.kdbx"* ]] ||
  fail "pinentry forwards the SETDESC message to the shell" "call: ${calls[0]:-<none>}"
pass "pinentry forwards the SETDESC message to the shell"

grep -qF 'OK Pleased to meet you' <<<"$output" ||
  fail "pinentry greets on startup" "output: $output"
pass "pinentry greets on startup"

grep -qF 'D hunter2' <<<"$output" ||
  fail "pinentry returns the typed password as a D line" "output: $output"
pass "pinentry returns the typed password as a D line"

[[ $(tail -n1 <<<"$output") == "OK" ]] ||
  fail "pinentry confirms the password with a trailing OK" "output: $output"
pass "pinentry confirms the password with a trailing OK"

# A caller that describes the secret poorly is overridden by the label, so the
# dialog can say which password it wants.
setup_scenario labelled
cat >"$mock_bin/omarchy-shell" <<'SH'
#!/bin/bash

printf '%s\n' "$*" >>"$CALL_LOG"
payload="$3"
selection_file=$(perl -MJSON::PP=decode_json -e 'print decode_json($ARGV[0])->{selectionFile}' "$payload")
done_file=$(perl -MJSON::PP=decode_json -e 'print decode_json($ARGV[0])->{doneFile}' "$payload")
printf '%s' "hunter2" > "$selection_file"
: > "$done_file"
printf 'ok\n'
SH
chmod +x "$mock_bin/omarchy-shell"
CALL_LOG="$call_log" OMARCHY_PINENTRY_LABEL="KeePass database: ~/Sync/passes.kdbx" \
  run_pinentry $'SETDESC Enter Password\nGETPIN\n'

[[ ${calls[0]} == *"passes.kdbx"* && ${calls[0]} != *"Enter Password"* ]] ||
  fail "the label replaces a vague SETDESC" "call: ${calls[0]:-<none>}"
pass "the label replaces a vague SETDESC"

# Cancelling (an empty selection file) reports an Assuan cancellation error,
# never a D line.
setup_scenario cancel
cat >"$mock_bin/omarchy-shell" <<'SH'
#!/bin/bash

printf '%s\n' "$*" >>"$CALL_LOG"
payload="$3"
done_file=$(perl -MJSON::PP=decode_json -e 'print decode_json($ARGV[0])->{doneFile}' "$payload")
: > "$done_file"
printf 'ok\n'
SH
chmod +x "$mock_bin/omarchy-shell"
CALL_LOG="$call_log" run_pinentry $'SETDESC Enter password for vault.kdbx\nGETPIN\n'

grep -qF 'ERR 83886179' <<<"$output" ||
  fail "pinentry reports cancellation as an Assuan ERR" "output: $output"
pass "pinentry reports cancellation as an Assuan ERR"

! grep -qF 'D ' <<<"$output" ||
  fail "pinentry never emits a D line on cancel" "output: $output"
pass "pinentry never emits a D line on cancel"
