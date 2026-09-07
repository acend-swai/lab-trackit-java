# Architecture

Spring Boot 3.5, Java 21, Maven for the backend. Vue 3, Vite and TypeScript for the
frontend. PostgreSQL 17 for storage. One backend module, layered by responsibility.

## Backend layers

| Package | Holds | Rule |
|---|---|---|
| `web` | REST controllers | no business logic, no storage |
| `service` | business logic | knows nothing about HTTP |
| `domain` | records, enums, JPA entities | records carry no framework annotations |
| `dto` | request payloads with validation | never returned, only accepted |

A request travels `web` to `service` to `domain` and back. A controller never reaches
past `service`.

## Why records for the domain

A task is a value. Records make it immutable and keep equality by value, which is what
tests want. Persistence adds a `TaskEntity` next to the record rather than annotating
it, so the API shape survives a change of storage.

## Frontend layers

| Folder | Holds | Rule |
|---|---|---|
| `api/` | one typed module per resource | the only place that speaks HTTP |
| `views/` | one component per route | owns loading and error state |
| `components/` | reusable pieces | never call the API themselves |
| `router/` | the route table | the only place routes are registered |

The Vite dev server proxies `/api` to the backend on port 8080. The browser sees one
origin, so there is no CORS configuration to get wrong.

## Storage

PostgreSQL 17, started from `compose.yaml` in the repo root. The schema is owned by
Flyway migrations in `backend/src/main/resources/db/migration/`. Hibernate runs with
`ddl-auto: validate` so a drifted schema fails at startup instead of being silently
rewritten.

## Endpoints

| Method | Path | Returns |
|---|---|---|
| GET | `/api/v1/health` | `{"status":"ok"}` |
| POST | `/api/v1/tasks` | 201 and the created task |
| GET | `/api/v1/tasks` | all tasks |
| POST | `/api/v1/tasks/{taskId}/comments` | 201 and the created comment |
| GET | `/api/v1/tasks/{taskId}/comments` | the task's comments, oldest first |

The `/api/v1` prefix is fixed. New resources go under it. A request naming a task that
does not exist answers 404, raised by `TaskNotFoundException`.

## Specs

`openspec/specs/` holds the live behaviour spec, merged from each archived change. It is
the file to read before proposing a change and the file to change before writing code.
`openspec/changes/` holds whatever is in flight.
