#!/usr/bin/env bash
#
# PostToolUse hook, matcher Edit|Write. Runs the backend test suite after a
# backend edit and surfaces the result - see docs/adr/0003-agent-security-boundary.md.
#
# Non-blocking on purpose: this is feedback, not a gate. A gate that fires on
# every keystroke-sized edit would make normal test-first work (red, then
# green) impossible. The gate lives in CI (dod-check.yml) and in the tester
# agent, not here.
set -uo pipefail

if ! command -v jq > /dev/null 2>&1; then
  # Fail open here is acceptable: this hook only ever adds information, it
  # never blocks. Contrast with check-infra.sh and block-protected-edits.sh,
  # which fail closed because they gate an action.
  exit 0
fi

input=$(cat)
path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
[ -n "$path" ] || exit 0

case "$path" in
  *backend/*) ;;
  *) exit 0 ;;
esac

project_dir="${CLAUDE_PROJECT_DIR:-.}"
if [ ! -x "$project_dir/backend/mvnw" ]; then
  exit 0
fi

output=$(cd "$project_dir/backend" && ./mvnw -q -B test 2>&1)
status=$?

if [ "$status" -eq 0 ]; then
  echo "run-tests.sh: backend tests green after edit to $path"
else
  {
    echo "run-tests.sh: backend tests RED after edit to $path"
    echo "$output" | tail -30
  } >&2
fi

exit 0
