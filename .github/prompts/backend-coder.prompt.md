---
mode: agent
description: Implement one backend task from an OpenSpec change's tasks.md, following the TrackIt house pattern.
---

Read `.github/instructions/backend.instructions.md` and `AGENTS.md` first.
Implement the next unchecked backend task in the relevant
`openspec/changes/<name>/tasks.md`, staying inside `backend/`.

Constructor injection only. Controllers return the domain record, never a
`dto`. A JPA entity is a separate class from its record. Schema changes are a
new Flyway migration, never `ddl-auto`. Write or update the MockMvc test for
this step before you consider it done, and run `./mvnw -q test` - quote the
result, do not summarise it. Do not add a dependency to `pom.xml` without
saying so first.
