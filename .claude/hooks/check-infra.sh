#!/usr/bin/env bash
#
# PreToolUse hook for the Bash tool. Refuses destructive infrastructure commands
# before they run.
#
# WHY a hook and not a rule in AGENTS.md: a rule is a request the model may reason
# its way past. This runs every time, decided by the shell and not by the model.
# Exit code 2 blocks the tool call outright and hands stderr back to the agent as
# the reason.
#
# Exit codes:
#   0  allow
#   2  block, and tell the agent why
#
# Hook input arrives as JSON on stdin. The command is at .tool_input.command.

set -uo pipefail

# A guard that cannot read its input must not wave the command through. Fail closed:
# a missing jq blocks and says so, rather than silently allowing everything. This is
# the difference between a guardrail and the appearance of one.
if ! command -v jq > /dev/null 2>&1; then
  echo "Blocked by check-infra.sh: jq is not installed, so this hook cannot inspect" >&2
  echo "the command. Install jq (apt-get install -y jq) and try again." >&2
  exit 2
fi

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

# No command to inspect means nothing to block.
[ -n "$cmd" ] || exit 0

# One pattern per line, so a reader can see exactly what is refused and why.
# Anchored where it matters: "terraform destroy" is blocked, "terraform plan -destroy"
# is not, because a plan changes nothing.
block() {
  echo "Blocked by check-infra.sh: $1" >&2
  echo "Nothing ran. If this is genuinely needed, a human runs it outside the agent." >&2
  exit 2
}

case "$cmd" in
  *"terraform destroy"*)          block "terraform destroy tears down real infrastructure" ;;
  *"terraform apply"*)            block "terraform apply changes real infrastructure - this lab plans and validates only" ;;
  *"kubectl delete ns"*)          block "deleting a namespace deletes everything in it" ;;
  *"kubectl delete namespace"*)   block "deleting a namespace deletes everything in it" ;;
  *"rm -rf /"*)                   block "recursive delete from the filesystem root" ;;
  *"git push --force"*|*"git push -f"*) block "force push rewrites history other people have" ;;
  *"DROP DATABASE"*|*"drop database"*)  block "dropping the database destroys the data the app depends on" ;;
  *"az group delete"*)            block "deleting a resource group deletes every resource in it" ;;
esac

# A plan, a validate, a fmt and a state list are all read-only. They pass.
exit 0
