# Local git hooks

This directory is not wired in by git automatically - opt in once per clone:

```bash
git config core.hooksPath .githooks
```

`pre-push` runs the backend tests (if `backend/` changed) and
`terraform fmt -check`/`terraform validate` (if `deploy/terraform/` changed)
before a push, and reminds you what the real Definition-of-Done gate in CI
(`.github/workflows/dod-check.yml`, `scripts/dod_check.sh`) will check against
your PR body once one exists. The full gate cannot run here - a PR body does
not exist at push time - so treat this hook as a fast local smoke test, not a
substitute for CI.
