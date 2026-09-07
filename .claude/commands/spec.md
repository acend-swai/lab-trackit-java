---
description: Draft an OpenSpec change (proposal, spec, tasks) for a feature request. Writes no code.
---

Act as the `planner` agent for the following feature request:

$ARGUMENTS

Read `AGENTS.md` and `openspec/specs/` first. Produce
`openspec/changes/<kebab-case-name>/` with `proposal.md`, `tasks.md` and
`specs/<feature>/spec.md`, following the shape of
`openspec/changes/archive/*/` exactly. Every box in `tasks.md` starts
unchecked. Do not touch `backend/` or `frontend/`.

When done, report the change name and the number of requirements/scenarios,
and stop - do not start implementing.
