# lab-trackit-java

Lab repository for the workshop **Agentic Coding in Practice**, Workshop-Tage 2026.

TrackIt is a small task management tool. A task has a title, a project and a status.
The application grows over the workshop: one module adds one stage.

This is the Java line of `acend-swai/lab-trackit`. The Python line stays as it is; both
carry the same domain so the two are comparable.

## Branches

Two per module: `-start` is where you begin, `-solution` is the reference state after
the lab. Every `-start` branch compiles and its tests pass before you touch anything.

| Module | Start | Solution | Stage |
|---|---|---|---|
| M1.1 Agentic loop | `m1-1-start` | `m1-1-solution` | create and list a task, in memory |
| M1.2 Skills, plugins, agents | `m1-2-start` | `m1-2-solution` | second endpoint from your own skill |
| M1.3 MCP | `m1-3-start` | `m1-3-solution` | agent reaches a system beyond the repo |
| M2 Spec first | `m2-start` | `m2-solution` | persistence and validation, spec-driven |
| M3 Infrastructure | `m3-start` | `m3-solution` | container setup, verified locally |
| M4 Capstone | `m4-start` | `m4-solution` | reporting end to end |

Only the M1.1 pair exists today. The others follow with their modules.

## Requirements

Java 21 and the Maven wrapper in `backend/`, or the devcontainer in `.devcontainer/`.
Nothing else. No database, no frontend - both arrive in later modules.

## Verify before the lab

```bash
./verify.sh
```

Every line must read `[OK]`. The build check downloads dependencies on the first run,
so do this before the workshop day, not during it.

## Run it

```bash
cd backend
./mvnw spring-boot:run
curl -s localhost:8080/api/v1/health
```

Answers `{"status":"ok"}`. On `m1-1-start` that is the only endpoint - that is correct.

## Your `.env`

Your personal `.env` arrives by mail on the morning of the workshop. Put it in the repo
root, next to this README. It is in `.gitignore`.
