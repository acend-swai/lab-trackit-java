---
mode: agent
description: Draft an OpenSpec change (proposal, spec, tasks) for a feature request. Writes no code.
---

Read `AGENTS.md` and `openspec/specs/` first, then produce
`openspec/changes/<kebab-case-name>/` with `proposal.md`, `tasks.md` and
`specs/<feature>/spec.md`, following the shape of
`openspec/changes/archive/*/` exactly - Why / What changes / Decisions /
Out of scope in the proposal, Requirement / Scenario (Given/When/Then) in the
spec, an ordered and entirely unchecked checklist in tasks.md.

Do not touch `backend/` or `frontend/`. Stop once the change directory is
written and report the requirement/scenario count - implementation is a
separate pass (`plan.prompt.md`).
