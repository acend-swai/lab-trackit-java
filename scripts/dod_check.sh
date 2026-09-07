#!/usr/bin/env bash
#
# Definition-of-Done gate, enforced as code - see
# docs/adr/0002-full-agentic-capstone-platform.md.
#
# Reads a PR body (default .github/PR_DRAFT.md, or a file given as $1, or
# stdin with `-`) and checks:
#
#   1. A "Spec:" line pointing at an OpenSpec change's proposal.md that
#      actually exists in the repo, OR a non-empty "no-spec: <reason>" line.
#   2. At least one acceptance-criteria checklist line ("- [ ]" / "- [x]"),
#      unless the PR declared no-spec.
#   3. Every unchecked "- [ ]" line is covered by a non-empty "## Out of
#      scope" section - the PR must say what it deliberately left undone,
#      not just leave a box empty.
#
# Exit 0 and a summary line on success. Exit 1 and the specific failure(s)
# otherwise - never a vague "DoD check failed" with no reason.
set -uo pipefail

usage() { echo "usage: $0 [pr-body-file|-]" >&2; exit 2; }

input_file="${1:-.github/PR_DRAFT.md}"

if [ "$input_file" = "-" ]; then
  body=$(cat)
elif [ -f "$input_file" ]; then
  body=$(cat "$input_file")
else
  echo "FAIL: no PR body found at '$input_file' and none piped on stdin." >&2
  usage
fi

fail=0
findings=()

add_finding() {
  findings+=("$1")
  fail=1
}

spec_line=$(printf '%s\n' "$body" | grep -m1 -E '^Spec:[[:space:]]*\S' || true)
nospec_line=$(printf '%s\n' "$body" | grep -m1 -E '^no-spec:[[:space:]]*\S' || true)

if [ -z "$spec_line" ] && [ -z "$nospec_line" ]; then
  add_finding "no 'Spec: <path>' line and no 'no-spec: <reason>' line found"
fi

if [ -n "$spec_line" ]; then
  spec_path=$(printf '%s' "$spec_line" | sed -E 's/^Spec:[[:space:]]*//')
  if [ ! -f "$spec_path" ]; then
    add_finding "linked spec '$spec_path' does not exist in this repo"
  fi
fi

unchecked_count=$(printf '%s\n' "$body" | grep -cE '^- \[ \]' || true)
checked_count=$(printf '%s\n' "$body" | grep -cE '^- \[x\]' || true)
total_count=$((unchecked_count + checked_count))

if [ -z "$nospec_line" ] && [ "$total_count" -eq 0 ]; then
  add_finding "no acceptance-criteria checklist lines found ('- [ ]' / '- [x]')"
fi

if [ "$unchecked_count" -gt 0 ]; then
  out_of_scope=$(printf '%s\n' "$body" | awk '/^## Out of scope/{flag=1; next} /^## /{flag=0} flag' | tr -d '[:space:]')
  if [ -z "$out_of_scope" ]; then
    add_finding "$unchecked_count unchecked acceptance criterion/criteria, but '## Out of scope' is missing or empty"
  fi
fi

if [ "$fail" -eq 0 ]; then
  echo "DoD check passed: $checked_count/$total_count acceptance criteria checked${spec_line:+, spec linked}${nospec_line:+, no-spec declared}."
  exit 0
fi

echo "DoD check FAILED:" >&2
for f in "${findings[@]}"; do
  echo "  - $f" >&2
done
exit 1
