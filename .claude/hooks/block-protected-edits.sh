#!/usr/bin/env bash
#
# PreToolUse hook, matcher Edit|Write. Blocks any write under the paths that
# define the harness and CI itself - see docs/adr/0003-agent-security-boundary.md.
#
# No bypass, no agent_type exception. If a protected file genuinely needs to
# change, a human edits it directly, outside the harness - that friction is
# the point (ADR-0003), not a gap to close.
set -uo pipefail

# A guard that cannot read its input must not wave the write through.
if ! command -v jq > /dev/null 2>&1; then
  echo "Blocked: jq is not installed, so this hook cannot inspect the edit." >&2
  exit 2
fi

input=$(cat)
path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
[ -n "$path" ] || exit 0

# Normalize to a path relative to the project root, best-effort, so a
# protected match works whether the tool passed an absolute or relative path.
rel="$path"
if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
  rel="${path#"$CLAUDE_PROJECT_DIR"/}"
fi

block() {
  echo "Blocked by block-protected-edits.sh: $1 is protected - $2" >&2
  exit 2
}

case "$rel" in
  .claude/*)             block "$rel" "changes to the harness itself need a human, not an agent" ;;
  .github/*)              block "$rel" "CI, Copilot config and CODEOWNERS need a human, not an agent" ;;
  .mcp.json)              block "$rel" "the MCP allow-list needs a human, not an agent" ;;
  deploy/terraform/*)     block "$rel" "infrastructure code changes need a human review, not just a green plan" ;;
  lab-manifest.yml)       block "$rel" "the branch content contract needs a human, not an agent" ;;
  .githooks/*)            block "$rel" "the local pre-push gate needs a human, not an agent" ;;
esac

exit 0
