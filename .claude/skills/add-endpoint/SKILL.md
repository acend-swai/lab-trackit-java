---
name: add-endpoint
description: Use when adding a REST endpoint to TrackIt, or when the user says "add an endpoint", "expose X over the API", "new route", "second endpoint", "a summary endpoint" or "count them per status". Generates controller method, service method, error handling and a MockMvc test in the house pattern from AGENTS.md. Covers both a lookup that can miss and a read-only aggregate.
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

# Add an endpoint, TrackIt house pattern

Reference answer for lab 1.2, task A1. Generate the four pieces every TrackIt endpoint
has. Follow `AGENTS.md`; where this file and `AGENTS.md` disagree, `AGENTS.md` wins.

## Steps

1. Read `AGENTS.md` and the existing `web/TaskController.java` before writing anything.
   The new endpoint follows the file you find, not a generic Spring example.
2. Add the service method in `service/`. Return `Optional<T>` when the resource may be
   absent, and read through the repository - storage is PostgreSQL, not a list.
3. Add the controller method in `web/`, mapped under `/api/v1/`. It delegates to the
   service and returns the domain record.
4. For a lookup that can miss, throw a dedicated exception annotated
   `@ResponseStatus(HttpStatus.NOT_FOUND)`. Do not return null and do not return a
   `ResponseEntity` of a dto.
5. Add at least one MockMvc test per outcome in the mirrored test package, named as a
   sentence: `getTaskByIdReturnsTheTask`, `getUnknownTaskReturnsNotFound`. The service is
   mocked with `@MockitoBean`, so stub the call each test needs.
6. Run `./mvnw -q test` in `backend/` and report the result. Do not report done while red.

## Aggregates and other read-only endpoints

A summary or count endpoint is not a lookup, and steps 2 and 4 do not apply to it. Four
rules instead:

1. **No path variable, no 404.** An empty result is a valid `200`. `GET .../summary` with
   an empty table answers with zeroes, it does not answer "not found".
2. **Count in the database.** Use a derived query such as `countByStatus`, or a
   projection. Never load every row and count in Java - that is correct on ten rows and
   an outage on ten million.
3. **Every key is always present.** When the response is keyed by an enum, every value of
   that enum appears, including the ones at `0`. Omitting a key at zero makes every
   consumer treat "missing" and "zero" as the same case.
4. **Test the empty case and the zero-key case explicitly.** They are the two that break,
   and they are invisible in a test that seeds one row per status.

## Naming

- Controller method names read as the operation: `getTaskById`, `listTasks`.
- Path variables use the domain name: `/api/v1/tasks/{id}`.
- One controller per resource, one service per resource.

## Out of scope

- Adding a dependency to `pom.xml`. Say what you would need and stop.
- Schema changes. A new column or table is a Flyway migration and belongs to the
  `add-persistence` skill.
- Editing tests that already pass, to make a new endpoint fit.
