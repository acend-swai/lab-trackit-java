# Change: Add task comments

Reference answer for lab 2. Produced by the OpenSpec cycle before any code existed.

## Why

A task records what has to happen, but not what was found out along the way. Today that
context lives in chat and is lost. Teams need a place to record a finding against the task
it belongs to, so the next person reads it with the work rather than beside it.

The Python line of this project (`acend-swai/lab-trackit`) already carries a comment
entity, so this keeps the two lines comparable.

## What changes

- New `Comment` entity, belonging to exactly one `Task`.
- `POST /api/v1/tasks/{taskId}/comments` creates a comment.
- `GET /api/v1/tasks/{taskId}/comments` lists them, oldest first.
- New `comment` table with a foreign key to `task`, added by a Flyway migration.

## Decisions

Each of these was open before the spec and is closed by it. That is the point of writing
the spec first - the agent would otherwise have decided all four silently.

- A comment carries `author` as free text. There is no user table in TrackIt, and
  inventing one is a bigger change than this one.
- `body` is limited to **2000 characters**. Long enough for a real finding, short enough
  that it cannot be used as a file store.
- Comments are returned **oldest first**. A discussion reads in the order it happened.
- Deleting a task deletes its comments (`ON DELETE CASCADE`). An orphan comment has no
  meaning.

## Out of scope

- Editing or deleting a comment.
- Threading, mentions, reactions, attachments.
- Comments in the frontend. The API is the deliverable.
- Any user or authentication concept.
