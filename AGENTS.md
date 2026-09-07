# AGENTS.md

## Project Overview

TrackIt - simple task management tool for small teams.
Tech stack: Java 21, Spring Boot 3.5, Maven. Tests with JUnit 5 and MockMvc.
Frontend: Vue 3, Vite, TypeScript, PrimeVue. Database: PostgreSQL 17.

This is the Java line of the TrackIt lab project. The Python line lives in
`acend-swai/lab-trackit` and carries the same domain.

## Architecture

- backend/src/main/java/ch/acend/trackit/
  - web/ - REST controllers, one per resource (e.g. TaskController.java)
  - service/ - business logic, one per resource (e.g. TaskService.java)
  - domain/ - records and enums, no framework annotations
  - dto/ - request payloads with validation annotations
  - repository/ - Spring Data interfaces, one per entity
  - TrackitApplication.java - the Spring Boot entry point
- backend/src/test/java/ch/acend/trackit/ - tests, mirroring the main package
- backend/src/main/resources/db/migration/ - Flyway migrations, one per change
- frontend/src/
  - api/ - one module per resource, all HTTP through `api/client.ts`
  - views/ - one component per route, named `<Thing>View.vue`
  - components/ - reusable pieces, no HTTP calls of their own
  - router/index.ts - every route registered here and nowhere else
- docs/adr/ - one file per architectural decision
- openspec/specs/ - the live spec, merged from archived changes. Read it before
  proposing a change; it is the current truth about how TrackIt behaves
- openspec/changes/ - changes in flight, one directory each
- deploy/terraform/ - infrastructure as code. Written and validated, never applied

## Coding Standards

- Java 21, records for value types, no Lombok
- Constructor injection only, never field injection
- Four spaces, no tabs. One class per file
- Controllers are annotated `@RestController` with `@RequestMapping("/api/v1/...")`
- Test classes use `@WebMvcTest(TheController.class)` and inject `MockMvc`
- Test method names read as a sentence: `postTaskReturnsCreated`
- Validation annotations belong in `dto`, never in `domain`
- A controller test mocks its service with `@MockitoBean`. `@Import` of a real
  service only works while that service reaches nothing outside itself
- Vue components use `<script setup lang="ts">`, never the options API
- A view calls `api/`, never `axios` directly

## Persistence rules

- Storage is PostgreSQL, reached through Spring Data JPA
- The JPA entity is a SEPARATE class in `domain`, e.g. `TaskEntity`. Never annotate
  the record - the record stays the API shape when the storage changes
- One `*Repository` interface per entity, extending `JpaRepository`
- The schema is created by a Flyway migration, never by `ddl-auto`.
  `spring.jpa.hibernate.ddl-auto` MUST be `validate`
- Migrations are named `V<n>__<snake_case_description>.sql` and are never edited
  once committed
- The datasource URL, user and password come from environment variables with a
  development default, never a hardcoded production value

## Frontend rules

- One API module per resource in `frontend/src/api/`, exporting typed functions
- Types mirror the backend record field for field
- A view owns its loading and error state and renders both
- New route goes into `router/index.ts`; nothing else registers routes
- The dev server proxies `/api` to port 8080, so URLs stay relative

## Constraints

- DO NOT add a dependency to pom.xml or package.json without saying so first
- DO NOT put business logic in a controller
- DO NOT return a `dto` type from a controller - return the domain record
- DO NOT read or write anything under `secrets/`
- DO NOT edit files outside the subsystem you were asked to change
- Every new endpoint MUST have at least one MockMvc test
- Every schema change MUST arrive as a new Flyway migration

## Git rules

- Commit before every non-trivial task
- Commit as soon as a slice runs green
- No amend on an accepted commit
- No force-push

## Entity Model

- Task: id (long), title (String), project (String), status (OPEN or DONE)
- Comment: id (long), taskId (long), author (String), body (String, max 2000),
  createdAt (Instant). Belongs to exactly one Task and is deleted with it

Both are stored in PostgreSQL. The bounds on Comment come from
`openspec/specs/task-comments/spec.md`, not from a guess - change the spec first.

## Infrastructure rules

- Terraform lives in `deploy/terraform/`, is formatted with `terraform fmt` and must
  pass `terraform validate`
- Provider versions are pinned. Never `latest`, for a provider or an image tag
- No credential has a default and none is written into a file. They arrive through
  environment variables, `TF_VAR_*` for Terraform
- The configuration is written and validated here, never applied. `terraform apply` and
  `terraform destroy` are blocked by `.claude/hooks/check-infra.sh`
