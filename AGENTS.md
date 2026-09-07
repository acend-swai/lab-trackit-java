# AGENTS.md

## Project Overview

TrackIt - simple task management tool for small teams.
Tech stack: Java 21, Spring Boot 3.5, Maven. Tests with JUnit 5 and MockMvc.

This is the Java line of the TrackIt lab project. The Python line lives in
`acend-swai/lab-trackit` and carries the same domain.

## Architecture

- backend/src/main/java/ch/acend/trackit/
  - web/ - REST controllers, one per resource (e.g. TaskController.java)
  - service/ - business logic, one per resource (e.g. TaskService.java)
  - domain/ - records and enums, no framework annotations
  - dto/ - request payloads with validation annotations
  - TrackitApplication.java - the Spring Boot entry point
- backend/src/test/java/ch/acend/trackit/ - tests, mirroring the main package
- docs/adr/ - one file per architectural decision

## Coding Standards

- Java 21, records for value types, no Lombok
- Constructor injection only, never field injection
- Four spaces, no tabs. One class per file
- Controllers are annotated `@RestController` with `@RequestMapping("/api/v1/...")`
- Test classes use `@WebMvcTest(TheController.class)` and inject `MockMvc`
- Test method names read as a sentence: `postTaskReturnsCreated`
- Validation annotations belong in `dto`, never in `domain`

## Constraints

- DO NOT add a dependency to pom.xml without saying so first
- DO NOT put business logic in a controller
- DO NOT return a `dto` type from a controller - return the domain record
- DO NOT read or write anything under `secrets/`
- Every new endpoint MUST have at least one MockMvc test

## Git rules

- Commit before every non-trivial task
- Commit as soon as a slice runs green
- No amend on an accepted commit
- No force-push

## Entity Model

- Task: id (long), title (String), project (String), status (OPEN or DONE)

Tasks live in memory in TaskService. Lab 1.2 moves them into PostgreSQL.
