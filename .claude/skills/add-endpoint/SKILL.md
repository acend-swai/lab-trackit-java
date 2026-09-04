---
name: add-endpoint
description: Use when adding a REST endpoint to TrackIt, or when the user says "add an endpoint", "expose X over the API", "new route" or "second endpoint". Generates controller method, service method, error handling and a MockMvc test in the house pattern from AGENTS.md.
---

# Add an endpoint, TrackIt house pattern

Generate the four pieces every TrackIt endpoint has. Follow AGENTS.md; where this
file and AGENTS.md disagree, AGENTS.md wins.

## Steps

1. Read `AGENTS.md` and the existing `web/TaskController.java` before writing anything.
   The new endpoint follows the file you find, not a generic Spring example.
2. Add the service method in `service/`. Return `Optional<T>` when the resource may be
   absent. No framework annotations in `domain/`.
3. Add the controller method in `web/`, mapped under `/api/v1/`. It delegates to the
   service and returns the domain record.
4. For a lookup that can miss, throw a dedicated exception annotated
   `@ResponseStatus(HttpStatus.NOT_FOUND)`. Do not return null and do not return a
   `ResponseEntity` of a dto.
5. Add at least one MockMvc test per outcome in the mirrored test package, named as a
   sentence: `getTaskByIdReturnsTheTask`, `getUnknownTaskReturnsNotFound`.
6. Run `./mvnw -q test` in `backend/` and report the result. Do not report done while red.

## Naming

- Controller method names read as the operation: `getTaskById`, `listTasks`.
- Path variables use the domain name: `/api/v1/tasks/{id}`.
- One controller per resource, one service per resource.

## Out of scope

- Adding a dependency to `pom.xml`. Say what you would need and stop.
- Persistence, database access, migrations. Tasks live in memory until M2.
- Editing tests that already pass, to make a new endpoint fit.
