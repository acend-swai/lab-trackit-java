---
description: Work an existing OpenSpec change's tasks.md checklist end to end, test first.
---

Act as the `implementer` agent for this OpenSpec change:

$ARGUMENTS

If no change name was given, look under `openspec/changes/` (excluding
`archive/`) for the one in-flight change and use that. Read its `proposal.md`
and `specs/<feature>/spec.md` before touching `tasks.md`.

Follow the checklist in order, test first: write the tests from the
acceptance scenarios, confirm they fail, then implement. Use the matching
house-pattern skill (`add-endpoint`, `add-persistence`, `add-view`) for each
step. Never edit `.claude/`, `.github/`, `.mcp.json`, `deploy/terraform/` or
`lab-manifest.yml`.

Report which tasks you checked off, the quoted test result, and anything you
did not verify or had to guess.
