---
name: add-persistence
description: Use when moving a TrackIt resource from in-memory storage to PostgreSQL, or when the user says "persist", "store in the database", "add an entity", "add a repository", or "add a migration". Applies the TrackIt persistence house pattern - entity beside the record, Spring Data repository, Flyway migration, ddl-auto validate.
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

# Add persistence, TrackIt house pattern

Move one resource from an in-memory collection to PostgreSQL without changing the API
shape. The record in `domain` is the API shape and does not gain annotations.

## Before you start

Read `AGENTS.md` and `docs/architecture.md`. The persistence rules there win over
anything in this file.

Adding a dependency needs the user's agreement first. Say which ones you need and wait.

## Steps

1. **Dependencies.** In `backend/pom.xml`, add and name them to the user:
   - `spring-boot-starter-data-jpa`
   - `flyway-core` and `flyway-database-postgresql` (since Flyway 10 the database
     support is a separate module; without it startup fails on a Postgres URL)
   - `org.postgresql:postgresql` at `runtime` scope

2. **Entity.** Create `domain/<Thing>Entity.java`. A separate class from the record,
   never the record with annotations on it. `@Entity`, `@Table(name = "<thing>")`,
   `@Id @GeneratedValue(strategy = GenerationType.IDENTITY)`, and enums stored with
   `@Enumerated(EnumType.STRING)`. Give it a `toDomain()` returning the record, and a
   protected no-arg constructor for JPA.

3. **Repository.** Create `repository/<Thing>Repository.java`, an interface extending
   `JpaRepository<<Thing>Entity, Long>`. Nothing else in it unless a query is needed.

4. **Migration.** Create
   `backend/src/main/resources/db/migration/V<n>__<snake_case>.sql` with the `CREATE
   TABLE`. Column types match the entity. Never edit a migration that is already
   committed - add the next one.

5. **Configuration.** In `application.yml` set the datasource from environment
   variables with a development default, `spring.jpa.hibernate.ddl-auto: validate` and
   `spring.flyway.enabled: true`. Never `create` or `update`.

6. **Service.** Replace the in-memory collection with constructor-injected repository
   calls. Write methods carry `@Transactional`, read methods `@Transactional(readOnly
   = true)`. The service keeps returning the record, not the entity.

7. **Tests.** A `@WebMvcTest` that imported the real service will now fail to start,
   because the service reaches a repository that the slice does not create. Replace
   `@Import(<Thing>Service.class)` with a `@MockitoBean` field and stub the calls the
   test needs.

8. **Verify.** `cd backend && ./mvnw -q test` must end in `BUILD SUCCESS`. Then say
   plainly that green tests do not prove persistence, and that the proof is a restart
   of the application with the row still present.

## Rules

- The record in `domain` is not annotated and does not change.
- No `ddl-auto` other than `validate`.
- No credential written into a file. Environment variable with a development default.
- One resource per run. If asked for two, do the first and say so.

## Out of scope

- Starting or stopping the database container.
- Editing anything under `frontend/`.
- Seed or demo data.
