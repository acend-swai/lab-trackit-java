# Copilot instructions for lab-trackit-java (m4-full-agentic)

This file is the Copilot-side equivalent of `AGENTS.md`, which stays the
single source of truth - if the two ever disagree, `AGENTS.md` wins and this
file is stale and should be fixed. Path-scoped detail lives in
`.github/instructions/*.instructions.md`, not repeated here.

## Project

TrackIt - task management for small teams. Java 21, Spring Boot 3.5, Maven,
JUnit 5 + MockMvc. Frontend: Vue 3, Vite, TypeScript, PrimeVue. PostgreSQL 17.
Package root: `ch.acend.trackit`.

## Spec-first workflow

This repo uses OpenSpec, not ad-hoc feature branches:

- `openspec/specs/` is the live, merged truth about how TrackIt behaves today.
  Read the relevant one before changing behaviour it already describes.
- `openspec/changes/<name>/` holds a change in flight: `proposal.md` (why,
  what, decisions, out of scope), `specs/<feature>/spec.md` (Requirement /
  Scenario, Given/When/Then), `tasks.md` (an ordered, unchecked-until-done
  checklist).
- Write the tests from the acceptance scenarios first, confirm they fail,
  then implement. A checklist item is done once its step is verified, not
  once it is written.
- A pull request must link the change it implements (or state
  `no-spec: <reason>` in the body) - `scripts/dod_check.sh` enforces this in
  CI, see `.github/workflows/dod-check.yml`.

## House coding pattern

- `backend/src/main/java/ch/acend/trackit/{web,service,domain,dto,repository}`,
  one class per resource per layer. Constructor injection only. Controllers
  are `@RestController` under `/api/v1/...` and return the domain record, not
  a dto. Validation annotations live in `dto`, never in `domain`.
- Persistence: the JPA entity is a separate class from the record
  (`TaskEntity` beside `Task`), one `*Repository` per entity,
  `ddl-auto: validate`, schema changes only via a new Flyway migration.
- Frontend: `<script setup lang="ts">` only, one API module per resource in
  `src/api/`, one view per route registered in `src/router/index.ts`.
- Full detail: `AGENTS.md`.

## What you must never do

- Add a dependency to `pom.xml` or `package.json` without saying so first.
- Read or write `.env`, any `*.key`/`*.pem`, `terraform.tfvars`, or any
  `*.tfstate` file. These are as sensitive as a database password.
- Run `terraform apply` or `terraform destroy`, in a workflow or by hand.
  `deploy/terraform/` is written and validated, never applied - see
  `docs/adr/0002-full-agentic-capstone-platform.md`.
- Edit `.claude/`, `.github/`, `.mcp.json`, `deploy/terraform/`, or
  `lab-manifest.yml` - `.github/CODEOWNERS` requires a human reviewer on
  these regardless of who opened the PR (`docs/adr/0003-agent-security-boundary.md`).
- Amend an accepted commit, or force-push.

## Where to look

- `AGENTS.md` - the full project context, always wins over this file.
- `openspec/specs/`, `openspec/changes/` - the spec-first workflow above.
- `docs/adr/` - why the architecture and the harness are shaped this way.
- `.github/instructions/*.instructions.md` - path-scoped rules for
  `backend/`, `frontend/` and `deploy/terraform/`.
