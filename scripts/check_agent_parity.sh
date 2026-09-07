#!/usr/bin/env bash
#
# Checks that the agent roster meant for both harnesses stays byte-identical
# between .claude/agents/<name>.md and .github/agents/<name>.agent.md - see
# docs/adr/0002-full-agentic-capstone-platform.md.
#
# db-builder and frontend-builder are deliberately EXCLUDED from this parity
# check: they are a Claude-Code-specific pattern (two agents in one turn,
# safe only because their write scopes are partitioned) that does not map to
# GitHub Copilot's single cloud coding agent. Mirroring them would produce a
# file nobody can act on and a false sense of parity.
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root" || exit 2

# The roster that IS meant to run under both harnesses.
mirrored=(api-reviewer planner implementer tester security)
# The roster that is Claude-Code-only, on purpose - never expect a mirror.
excluded=(db-builder frontend-builder)

fail=0

for name in "${mirrored[@]}"; do
  src=".claude/agents/${name}.md"
  dst=".github/agents/${name}.agent.md"

  if [ ! -f "$src" ]; then
    echo "FAIL: $src is in the mirrored roster but does not exist" >&2
    fail=1
    continue
  fi
  if [ ! -f "$dst" ]; then
    echo "FAIL: $dst is missing for mirrored agent '$name'" >&2
    fail=1
    continue
  fi
  if ! diff -q "$src" "$dst" > /dev/null 2>&1; then
    echo "FAIL: $src and $dst have drifted - they must be byte-identical" >&2
    diff "$src" "$dst" >&2 || true
    fail=1
  fi
done

for name in "${excluded[@]}"; do
  dst=".github/agents/${name}.agent.md"
  if [ -f "$dst" ]; then
    echo "FAIL: $dst exists but '$name' is Claude-Code-only by design (see script header) - remove the mirror, not the source" >&2
    fail=1
  fi
done

# Anything under .github/agents/ that is neither mirrored nor excluded is an
# orphan - either add it to the mirrored roster above, or explain why not.
if [ -d .github/agents ]; then
  while IFS= read -r -d '' f; do
    base=$(basename "$f" .agent.md)
    known=0
    for name in "${mirrored[@]}" "${excluded[@]}"; do
      [ "$base" = "$name" ] && known=1 && break
    done
    if [ "$known" -eq 0 ]; then
      echo "FAIL: .github/agents/${base}.agent.md is not in this script's mirrored or excluded roster - update scripts/check_agent_parity.sh" >&2
      fail=1
    fi
  done < <(find .github/agents -maxdepth 1 -name '*.agent.md' -print0)
fi

if [ "$fail" -eq 0 ]; then
  echo "Agent parity OK: ${#mirrored[@]} mirrored, ${#excluded[@]} deliberately Claude-Code-only."
  exit 0
fi

exit 1
