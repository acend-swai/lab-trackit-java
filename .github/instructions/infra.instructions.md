---
applyTo: "deploy/terraform/**"
---

# Infrastructure instructions

Full detail: `AGENTS.md` (Infrastructure rules), `docs/adr/0002-full-agentic-capstone-platform.md`,
`docs/adr/0003-agent-security-boundary.md`. This file is the path-scoped
summary for Copilot; where the two disagree, `AGENTS.md` wins.

- Format with `terraform fmt`, and every change must pass `terraform validate`.
- Provider versions are pinned. Never `latest`, for a provider or a container
  image tag.
- No credential has a default and none is ever written into a file.
  Credentials arrive through environment variables (`TF_VAR_*`). Never create
  `terraform.tfvars` - `terraform.tfvars.example` is the template, and the
  real file stays untracked and unread.
- **This configuration is written and validated here, never applied.**
  `terraform apply` and `terraform destroy` do not belong in any workflow or
  any local step you take, regardless of what the task asks - the repo's own
  guard (`.claude/hooks/check-infra.sh`) blocks them for a reason.
- `.github/CODEOWNERS` requires human review on every file under this path -
  a Copilot-opened PR touching `deploy/terraform/` does not merge on its own.
- Review every change against: secrets, public network exposure, unpinned
  image tags, missing resource limits, and missing backup/persistence
  settings. Finding none of these on an infrastructure change usually means
  the checklist was not applied, not that the change is clean.
