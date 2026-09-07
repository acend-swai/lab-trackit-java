---
mode: agent
description: Work an existing OpenSpec change's tasks.md checklist end to end, test first.
---

Find the in-flight change under `openspec/changes/` (excluding `archive/`).
Read its `proposal.md` and `specs/<feature>/spec.md` before touching
`tasks.md`. Work the checklist in order: write the tests from the acceptance
scenarios first, confirm they fail, then implement, following whichever
house-pattern instructions file applies
(`.github/instructions/backend.instructions.md` or
`frontend.instructions.md`).

Never edit `.claude/`, `.github/`, `.mcp.json`, `deploy/terraform/` or
`lab-manifest.yml` - these require a human reviewer regardless
(`.github/CODEOWNERS`). Report which tasks you checked off, the quoted test
result, and anything unverified or guessed.
