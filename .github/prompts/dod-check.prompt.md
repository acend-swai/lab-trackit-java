---
mode: agent
description: Run the Definition-of-Done gate locally against the current PR description, the way CI will.
---

Run `scripts/dod_check.sh` against this PR's body, exactly as
`.github/workflows/dod-check.yml` will in CI. If `.github/PR_DRAFT.md` exists,
use it as the input.

Report the script's output verbatim. If it fails, name exactly which check
failed (missing spec link, an unchecked task with no `## Out of scope`
covering it, or a missing `no-spec: <reason>` line) and what to add.
