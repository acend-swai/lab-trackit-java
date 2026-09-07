#!/usr/bin/env bash
#
# Stop hook. Drafts a local PR description whenever an in-flight OpenSpec
# change exists, so the DoD gate (scripts/dod_check.sh, ADR-0002) always has
# something concrete to point at once the session ends - rather than relying
# on whoever opens the PR to remember the link.
#
# Writes only .github/PR_DRAFT.md, a local scratch file, never opens or
# updates a real pull request - that stays a human action.
set -uo pipefail

project_dir="${CLAUDE_PROJECT_DIR:-.}"
cd "$project_dir" || exit 0

changes_dir="openspec/changes"
draft="$project_dir/.github/PR_DRAFT.md"

[ -d "$changes_dir" ] || exit 0

# In-flight changes are the directories directly under openspec/changes/,
# excluding the archive/ subtree.
mapfile -t in_flight < <(find "$changes_dir" -mindepth 1 -maxdepth 1 -type d ! -name archive 2> /dev/null | sort)

if [ "${#in_flight[@]}" -eq 0 ]; then
  exit 0
fi

{
  echo "<!-- Draft written by .claude/hooks/pr-summary.sh - review and edit before opening the PR. -->"
  echo ""
  echo "## Summary"
  echo ""
  for dir in "${in_flight[@]}"; do
    name=$(basename "$dir")
    echo "- Implements \`$name\`"
  done
  echo ""

  # The format below is not cosmetic: scripts/dod_check.sh parses it. It needs a
  # line starting "Spec:" and real "- [ ]" / "- [x]" checklist lines. A heading
  # with a bare path underneath, or a "3/7 tasks checked" summary, parses as
  # neither, and the draft fails the gate it exists to feed.
  echo "## Spec"
  echo ""
  for dir in "${in_flight[@]}"; do
    echo "Spec: $dir/proposal.md"
  done
  echo ""
  echo "## Acceptance criteria"
  echo ""
  for dir in "${in_flight[@]}"; do
    tasks_file="$dir/tasks.md"
    [ -f "$tasks_file" ] || continue
    # Copy the checklist verbatim, checkbox state included, so the gate counts
    # what tasks.md actually says rather than a summary of it.
    grep -E '^- \[[ x]\] ' "$tasks_file" || true
  done
  echo ""
  echo "## Out of scope"
  echo ""
  echo "<!-- Required for every unchecked box above. Write one line per box, or check it. -->"
  echo ""
  echo "## Verification"
  echo ""
  echo '```'
  echo "Paste the real test output here, quoted, not summarised."
  echo '```'
} > "$draft"

echo "pr-summary.sh: wrote $draft from ${#in_flight[@]} in-flight OpenSpec change(s)"
exit 0
