---
description: Guided checklist from a green branch to a merged PR that publishes a container image. Never merges or pushes on its own.
---

Walk through the release checklist for the current branch. This command never
runs `git push`, `git merge`, `gh pr merge`, or anything that changes what is
on GitHub - every step that does needs the user to run it themselves, on
purpose (`AGENTS.md` git rules: no force-push, the user commits and merges).

$ARGUMENTS

1. Run `git status --short` and stop if anything is uncommitted - name what it is.
2. Run `cd backend && ./mvnw -q test` and quote the result.
3. If `deploy/terraform/` changed, run `terraform fmt -check` and
   `terraform validate` from that directory and quote the result. Never run
   `terraform plan` or `terraform apply` here - `check-infra.sh` blocks
   `apply`/`destroy` anyway, and a plan needs credentials this session does
   not have.
4. Act as `tester`: confirm every acceptance scenario in the relevant OpenSpec
   change has a passing test naming it.
5. Act as `security` if `deploy/terraform/`, `.claude/` or `.github/` changed
   in this branch.
6. Run `/dod-check` and report its result.
7. If every step above passed, print the exact commands the user runs next -
   do not run them:
   ```
   git push -u origin <branch>
   gh pr create --fill
   ```
   and remind them that merging to `main` triggers `.github/workflows/deploy.yml`,
   which builds and publishes a container image to GHCR but never runs
   `terraform apply`.

If any step failed, stop there and report exactly what failed - do not
continue down the checklist past a failure.
