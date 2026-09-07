# Security model - m4-full-agentic

This branch is a teaching artifact for running an AI coding agent with real
autonomy, safely. Every mechanism below either already existed on
`m3-solution` or is new here, and is called out as such - nothing is
reinvented, and nothing security-relevant is left to "the agent should not."

## Layer 1 - what an agent can read (M3, unchanged)

`.claude/settings.json` denies reading `.env`, `*.key`, `*.pem`,
`terraform.tfvars` and `*.tfstate`. This governs Claude Code's own file tools,
not the shell - it does not stop `cat .env` from a `Bash` tool call. That gap
is exactly why layer 2 exists.

## Layer 2 - what an agent can run (M3, unchanged)

`.claude/hooks/check-infra.sh`, a fail-closed `PreToolUse` hook on `Bash`,
blocks `terraform apply`/`destroy`, `kubectl delete ns`, `rm -rf /` and
`git push --force` outright (exit code 2). Missing `jq` blocks every `Bash`
call rather than silently letting everything through - a guard that fails
open is worse than none.

## Layer 3 - what an agent can edit (new on this branch)

`.claude/hooks/block-protected-edits.sh`, a second fail-closed `PreToolUse`
hook on `Edit|Write`, blocks any write under `.claude/`, `.github/`,
`.mcp.json`, `deploy/terraform/`, `lab-manifest.yml` or `.githooks/` -
unconditionally, no bypass. An agent that can rewrite the file defining what
it is allowed to do has no boundary, only a suggestion. See
`docs/adr/0003-agent-security-boundary.md` for why this is deliberately blunt
rather than offering an escape hatch.

## Layer 4 - what merges without a human (new on this branch)

`.github/CODEOWNERS` requires human review on the same path list as layer 3,
so the boundary holds for a pull request opened by GitHub Copilot's cloud
agent too - it does not run local hooks, CODEOWNERS is the only thing that
reaches it.

## Layer 5 - what "done" means (new on this branch)

A pull request must link an OpenSpec change (`Spec: openspec/changes/<name>/proposal.md`)
or declare `no-spec: <reason>`, and every unchecked acceptance criterion needs
an `## Out of scope` entry explaining why. `scripts/dod_check.sh` enforces
this in `.github/workflows/dod-check.yml` - a green pipeline is not enough to
merge if the process was skipped.

## Layer 6 - what "shipped" means (new on this branch)

Merging to `main` builds the backend into a container image with Cloud
Native Buildpacks and publishes it to GHCR (`.github/workflows/deploy.yml`).
A second job runs `terraform fmt`/`validate`/`plan` against the published
image tag - **never `terraform apply`**. Applying stays a decision a human
makes locally, with their own Azure credentials, exactly as the M3
infrastructure rules already require of an agent.

## MCP servers (M3, unchanged)

`.mcp.json` connects `context7` (public library docs, read-only, no
credential), `github` (scoped to `/x/issues/readonly`, my own OAuth) and
`terraform` (the official HashiCorp server, reads the public provider
registry, holds no credential of mine). None of them can write to this repo
or apply infrastructure. See `docs/mcp-scoping.md` for the full reasoning
behind each scope.

## Reporting an issue

This is a workshop lab repository with synthetic data and no production
deployment behind it. If you find a real security issue in the mechanisms
above (a hook that fails open when it should fail closed, a deny rule that
does not cover what it claims to), open an issue - there is no separate
private disclosure channel for a teaching repository.
