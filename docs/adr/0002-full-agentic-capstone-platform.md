# 2. Full-agentic capstone platform

## Status

Accepted

## Context

`m4-full-agentic` is a standalone branch on top of `m3-solution` - it carries M1.1,
M1.2, M2 and M3 in full, not a fresh checkout. By the time this branch starts, the
repository already has:

- a deny list and a fail-closed `PreToolUse` hook (`.claude/hooks/check-infra.sh`)
  blocking destructive infrastructure commands (M3)
- two file-partitioned subsystem agents, `db-builder` and `frontend-builder`, that
  can run in the same turn because their write scopes never overlap, plus a
  read-only `api-reviewer` (M1.2/M3)
- a spec-first workflow that is not something this branch introduces: OpenSpec
  (`openspec/changes/` in flight, `openspec/specs/` merged and live) is already the
  house convention as of M2, with one archived change (`add-task-comments`) as the
  worked example
- Terraform for Azure Container Apps in `deploy/terraform/`, written and validated,
  never applied (M3)

The workshop's Stufe 4 asks for one more thing none of that gives you: a session
that goes from a feature request to a merged, deployed artifact without a human
in the implementation loop - while keeping every guardrail above intact, and
without the harness deciding for itself what "done" means.

## Decision

`m4-full-agentic` adds five things, each extending an existing mechanism rather
than replacing it:

1. **A spec-first agent roster.** `planner` authors an OpenSpec change (proposal,
   spec, tasks) from a request and writes no code. `implementer` works the
   resulting `tasks.md` checklist, tests first. `tester` verifies every acceptance
   scenario in the spec has a passing test naming it. `security` re-runs the
   infrastructure checklist from `LAB.md` task 4 and checks the protected-path
   list from ADR-0003 is intact. These sit alongside `db-builder`,
   `frontend-builder` and `api-reviewer` - they do not replace the subsystem split
   for backend/frontend work, they cover the parts that split does not: writing
   the spec, and closing the loop against it.

2. **GitHub Copilot parity.** The same instructions and agent roster are mirrored
   into `.github/` - `copilot-instructions.md`, `instructions/*.instructions.md`,
   and byte-identical `agents/*.agent.md` copies of the roles that make sense for
   a single cloud-run agent (`planner`, `implementer`, `tester`, `security`,
   `api-reviewer`). `db-builder` and `frontend-builder` are deliberately **not**
   mirrored - see "Out of scope" below.

3. **Definition-of-Done as code.** A pull request must link an OpenSpec change
   directory or declare `no-spec: <reason>`, and every task in that change's
   `tasks.md` must be checked or the change's `proposal.md` must carry an
   `## Out of scope` line explaining why not. `scripts/dod_check.sh` enforces
   this in CI (`dod-check.yml`) and, best-effort, in a local pre-push hook.

4. **CODEOWNERS on the harness itself.** The files that make every rule above
   enforceable - `.claude/`, `.github/`, `.mcp.json`, `deploy/terraform/`,
   `lab-manifest.yml` - require human review to change, whether the PR was
   opened by a person, Claude Code, or Copilot's cloud agent. See ADR-0003.

5. **A path to a running artifact, without breaking "never applied."** On a
   push to `main`, CI builds the backend into a container image with Spring
   Boot's Cloud Native Buildpacks (`spring-boot:build-image`, no Dockerfile) and
   publishes it to GHCR under an immutable tag. A second job runs
   `terraform fmt -check`, `terraform validate` and `terraform plan` against
   `deploy/terraform/` with that image tag as `backend_image` - skipped with a
   clear message if no Azure credentials are configured as repository secrets,
   so the workflow never hard-fails in a training fork. **`terraform apply` is
   never a CI step.** The plan is the artifact a human reviews before running
   apply themselves, by hand, exactly as M3 already requires of an agent.

The capstone demo itself is `openspec/changes/add-task-summary/` - a small
reporting feature (`GET /api/v1/tasks/summary`, counts per status), specified
end to end but deliberately left unimplemented (see
`lab-manifest.yml`'s `must_not_exist` for this branch), so a live run can carry
it from proposal to a green, DoD-passing PR.

## What this deliberately is not

- **Not a new security model.** `check-infra.sh` is unchanged beyond nothing;
  this branch adds a second, independent hook next to it (ADR-0003), it does not
  touch the destructive-command blocklist.
- **Not a replacement for OpenSpec.** An earlier draft of this branch invented a
  `docs/spec/NNN-*.md` convention. That was wrong - OpenSpec was already the
  house convention as of M2 and is used here unchanged.
- **Not a mandate to actually deploy anything.** "Written and validated, never
  applied" (`AGENTS.md`) continues to hold in CI as much as it holds for an
  agent in a terminal.

## Consequences

- Two more files to keep in sync per agent role (`.claude/agents/*.md` and
  `.github/agents/*.agent.md`), checked by `scripts/check_agent_parity.sh` in CI
  (`agent-parity.yml`).
- A heavier PR template and a DoD gate that can block a merge on process, not
  only on failing tests.
- A deploy workflow that publishes a real, runnable image on every merge to
  `main`, but stops short of a real environment until a human runs
  `terraform apply` locally with their own Azure credentials.

## Alternatives considered

- **Applying Terraform in CI via OIDC.** Rejected - it contradicts the M3 house
  rule in `AGENTS.md` ("Terraform ... is written and validated, never applied")
  and the pedagogical point of that rule: applying infrastructure is a decision
  a human makes, deliberately, not a side effect of a green pipeline.
- **A bespoke spec format for the capstone feature.** Rejected once fresh
  inspection of `m3-solution` showed OpenSpec already in place with a worked
  example (`add-task-comments`). Building a second convention next to a working
  one would only teach the wrong lesson.
