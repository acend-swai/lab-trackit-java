---
description: Run the Definition-of-Done gate locally against the current branch, the way CI will.
---

Run `scripts/dod_check.sh` against this branch's PR description, exactly as
`.github/workflows/dod-check.yml` will in CI.

If `.github/PR_DRAFT.md` exists (written by the `pr-summary.sh` Stop hook),
use it as the PR body input. Otherwise ask for the PR body, or accept it as
an argument:

$ARGUMENTS

Report the script's output verbatim. If it fails, name exactly which check
failed (missing spec link, an unchecked task with no `## Out of scope`
covering it, or a missing `no-spec: <reason>` line) and what to add - do not
paraphrase the failure into something vaguer than what the script printed.
