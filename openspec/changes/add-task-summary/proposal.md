# Change: Add task status summary

The live-demo slice for `m4-full-agentic` (docs/adr/0002). Specified end to end,
deliberately left unimplemented so a full-agentic run can carry it from this
proposal through a green, DoD-passing pull request.

## Why

TrackIt can list every task, but nobody can answer "how many are still open"
without counting the list by hand. A small dashboard or a stand-up needs the
count, not the rows.

## What changes

- New endpoint `GET /api/v1/tasks/summary` returning the count of tasks per
  status.
- No new entity, no migration - this reads the existing `task` table, it does
  not change its shape.

## Decisions

Each of these was open before the spec and is closed by it - the point of
writing the spec first.

- The response shape is a flat object with one key per `TaskStatus` value,
  `{"open": <n>, "done": <n>}`. Nesting under a wrapper (`{"counts": {...}}`)
  would only make every consumer unwrap it for no benefit.
- A status with zero tasks is still present in the response, at `0`. Omitting
  a status at zero forces every consumer to treat "key missing" and "key is
  zero" as the same case, and the API should not ask them to.
- The endpoint has no query parameters. Scoping by project is a bigger change
  than this one and is out of scope below.

## Out of scope

- Filtering the summary by project, date range, or any other dimension.
- A summary in the frontend. The API is the deliverable.
- Any change to how a task's status is set - this endpoint only reads.
