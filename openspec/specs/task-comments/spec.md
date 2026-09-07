# Spec: Task Comments

The live spec for task comments. Merged from change `add-task-comments` when it was
archived on 8 September 2026. Every requirement is covered by a test in
`backend/src/test/java/ch/acend/trackit/web/CommentControllerTest.java`.

## Requirements

### Requirement: Add a comment to a task

A user records a finding against the task it belongs to. The comment carries who wrote it
and when it was written.

#### Scenario: Adding a comment to an existing task

- **Given** a task with id 7
- **When** the client POSTs `{"author":"alice","body":"The restart check found this."}`
  to `/api/v1/tasks/7/comments`
- **Then** the response is `201`, carries a generated `id` and `createdAt`, and echoes
  `taskId` 7

#### Scenario: A comment needs an author

- **Given** a task with id 7
- **When** the client POSTs a comment with an empty `author`
- **Then** the response is `400` and no comment is stored

#### Scenario: A comment needs a body

- **Given** a task with id 7
- **When** the client POSTs a comment with an empty `body`
- **Then** the response is `400` and no comment is stored

#### Scenario: A comment body is capped at 2000 characters

- **Given** a task with id 7
- **When** the client POSTs a comment whose `body` is 2001 characters long
- **Then** the response is `400` and no comment is stored

#### Scenario: Commenting on a task that does not exist

- **Given** no task with id 404
- **When** the client POSTs a valid comment to `/api/v1/tasks/404/comments`
- **Then** the response is `404` and no comment is stored

### Requirement: List the comments on a task

#### Scenario: Comments come back oldest first

- **Given** a task with two comments, written a minute apart
- **When** the client GETs `/api/v1/tasks/7/comments`
- **Then** the response is `200` and the earlier comment is first in the list

#### Scenario: A task with no comments

- **Given** a task with id 7 and no comments
- **When** the client GETs `/api/v1/tasks/7/comments`
- **Then** the response is `200` and the list is empty

#### Scenario: Listing comments on a task that does not exist

- **Given** no task with id 404
- **When** the client GETs `/api/v1/tasks/404/comments`
- **Then** the response is `404`

### Requirement: Comments do not outlive their task

#### Scenario: Deleting a task removes its comments

- **Given** a task with two comments
- **When** the task row is deleted
- **Then** both comment rows are gone, enforced by the database rather than by the
  application
