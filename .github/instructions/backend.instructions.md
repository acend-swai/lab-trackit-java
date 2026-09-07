---
applyTo: "backend/**"
---

# Backend instructions

Full detail: `AGENTS.md` (Coding Standards, Persistence rules). This file is
the path-scoped summary for Copilot; where the two disagree, `AGENTS.md` wins.

- Java 21, records for value types, no Lombok. Four spaces, no tabs, one
  class per file.
- Constructor injection only, never field injection.
- `web/` - one `@RestController` per resource, `@RequestMapping("/api/v1/...")`,
  delegates to `service/`, returns the domain record, never a `dto`.
- `service/` - business logic, one class per resource.
- `domain/` - records and enums, no framework annotations on the record
  itself. A JPA entity is a **separate** class in the same package
  (`TaskEntity` beside `Task`), never the record with annotations added.
- `dto/` - request payloads, validation annotations live here, never in
  `domain`.
- `repository/` - one Spring Data interface per entity.
- Storage is PostgreSQL. `spring.jpa.hibernate.ddl-auto` MUST be `validate`.
  Schema changes arrive as a new Flyway migration in
  `src/main/resources/db/migration/`, named `V<n>__<snake_case>.sql`, and an
  already-committed migration is never edited.
- Test classes use `@WebMvcTest(TheController.class)` with `MockMvc`, mock the
  service with `@MockitoBean`, and name methods as a sentence:
  `postTaskReturnsCreated`. Every new endpoint needs at least one test.
- Do not add a dependency to `pom.xml` without saying so first.
- Do not read or write `.env`, `*.key`, `*.pem`, or anything under `secrets/`.
