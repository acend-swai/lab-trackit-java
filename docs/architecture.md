# Architecture

Spring Boot 3.5, Java 21, Maven. One module, layered by responsibility. No database
until M2, no frontend in this line.

## Layers

| Package | Holds | Rule |
|---|---|---|
| `web` | REST controllers | no business logic, no storage |
| `service` | business logic | knows nothing about HTTP |
| `domain` | records and enums | no framework annotations |
| `dto` | request payloads with validation | never returned, only accepted |

A request travels `web` to `service` to `domain` and back. A controller never reaches
past `service`.

## Why records for the domain

A task is a value. Records make it immutable and keep equality by value, which is what
tests want. Persistence in M2 introduces entities; the records stay as the API shape.

## Endpoints

| Method | Path | Returns |
|---|---|---|
| GET | `/api/v1/health` | `{"status":"ok"}` |
| POST | `/api/v1/tasks` | 201 and the created task |
| GET | `/api/v1/tasks` | all tasks |

The `/api/v1` prefix is fixed. New resources go under it.
