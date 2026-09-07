# 3. Agent security boundary for the harness itself

## Status

Accepted

## Context

M3 already established two independent enforcement layers, and the lesson both
of them teach is the same one: "the agent should not" is a request, a
mechanism that runs without asking is a guarantee.

- `.claude/settings.json` denies reading credentials and Terraform state
  (`Read(**/.env)`, `Read(**/*.tfstate)`, ...).
- `.claude/hooks/check-infra.sh`, a fail-closed `PreToolUse` hook on `Bash`,
  blocks `terraform apply`/`destroy` and a handful of other destructive command
  patterns outright, exit code 2, no dialog to click through.

Full-agentic operation adds one more class of file that needs the same
treatment and does not yet have it: **the harness and CI configuration**
itself - `.claude/`, `.github/`, `.mcp.json`, `deploy/terraform/`, and
`lab-manifest.yml`. An agent that can freely rewrite the file that defines what
it is allowed to do has no boundary at all, only a suggestion. This applies
doubly once GitHub Copilot's cloud agent is in scope (ADR-0002): it does not
run local hooks, so a PreToolUse hook alone cannot be the whole answer.

## Decision

1. **A second, independent PreToolUse hook.** `.claude/hooks/block-protected-edits.sh`
   matches `Edit|Write` and blocks any write under a fixed path list (see the
   script for the exact list) unconditionally - no bypass, no `agent_type`
   exception. If a protected file genuinely needs to change, a human edits it
   directly, outside the harness. This is a deliberate choice: an earlier
   design considered porting the `agent_type == "planner"` bypass proposed in
   `cust-vbs-aisepoc`'s ADR-018, and rejected it - that mechanism was never
   implemented even in the reference repo (its own ADR is still "Proposed"),
   and it reintroduces exactly the "the agent decides for itself" failure mode
   that M3 task 2 (`LAB.md`) is built to demonstrate is not good enough.

2. **CODEOWNERS on the same path list.** `.github/CODEOWNERS` requires human
   review on `.claude/`, `.github/`, `.mcp.json`, `deploy/terraform/` and
   `lab-manifest.yml`, so the boundary holds for a PR opened by Copilot's cloud
   agent exactly as it holds for Claude Code locally - a hook cannot reach a
   PR Claude Code never ran a Bash tool inside of, CODEOWNERS can.

3. **`run-tests.sh`, a PostToolUse hook on backend edits**, runs
   `./mvnw -q test` after every `Edit`/`Write` under `backend/` and surfaces the
   result. "Never report done while red" (`AGENTS.md`, every skill in this
   repo) is now backed by a signal the agent sees automatically, not only by
   its own discipline.

4. **`pr-summary.sh`, a Stop hook**, drafts a local PR description
   (`.github/PR_DRAFT.md`) naming the in-flight OpenSpec change directory
   whenever one exists, so the DoD gate (ADR-0002) always has something
   concrete to point at once a session ends, rather than relying on whoever
   opens the PR to remember to write the link by hand.

5. **`security` (new agent, ADR-0002)** re-runs the five-point infrastructure
   checklist from `LAB.md` task 4 (secrets, network exposure, image tags,
   resource limits, persistence/backup) and additionally checks: the deny list
   in `.claude/settings.json` is unchanged or only additive, `block-protected-edits.sh`
   still lists every path CODEOWNERS protects, and no OpenSpec change's
   `## Out of scope` section was used to wave through something CODEOWNERS
   should have caught instead.

## Consequences

- A legitimate change to the harness itself - adding a deny rule, widening an
  MCP server's scope, adding a workflow - cannot be made by an agent in a
  single pass. A human makes that edit directly; an agent can then update the
  docs and tests around it. That friction is the point, not a gap to close.
- Two hooks now run on every relevant tool call (`check-infra.sh` on `Bash`,
  `block-protected-edits.sh` on `Edit`/`Write`), each independently fail-closed
  and each responsible for one thing. Neither is a superset of the other.

## Alternatives considered

- **An `agent_type` bypass** (see Decision 1) - rejected, not implemented even
  upstream, and defeats the mechanism's purpose.
- **A single combined hook** covering both `Bash` and `Edit`/`Write` - rejected
  in favour of two small, single-purpose scripts. `check-infra.sh` already
  existed on `m3-solution` with its own tested blocklist; folding a second,
  unrelated concern into it would make the one file harder to reason about and
  risk a regression in a hook the workshop already relies on.
