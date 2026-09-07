# Spec: Task Status Summary

Every requirement below is testable - a MockMvc test must be writable from it.
Follow the pattern in `backend/src/test/java/ch/acend/trackit/web/TaskControllerTest.java`.

## ADDED Requirements

### Requirement: Summarize tasks by status

A client can ask how many tasks exist per status without listing and counting
them itself.

#### Scenario: Summary with a mix of statuses

- **Given** three tasks with status `OPEN` and one task with status `DONE`
- **When** the client GETs `/api/v1/tasks/summary`
- **Then** the response is `200` and the body is `{"open":3,"done":1}`

#### Scenario: Summary with no tasks

- **Given** no tasks exist
- **When** the client GETs `/api/v1/tasks/summary`
- **Then** the response is `200` and the body is `{"open":0,"done":0}`

#### Scenario: A status with no tasks is still present at zero

- **Given** two tasks, both with status `OPEN`
- **When** the client GETs `/api/v1/tasks/summary`
- **Then** the response is `200`, `open` is `2`, and `done` is present and `0`

#### Scenario: The counts add up to the total

- **Given** any number of tasks in any mix of statuses
- **When** the client GETs `/api/v1/tasks/summary`
- **Then** the sum of every value in the response equals the total number of
  tasks returned by `GET /api/v1/tasks`
