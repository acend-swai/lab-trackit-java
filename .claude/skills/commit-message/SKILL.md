---
name: commit-message
description: Use when writing a commit message for this repository, or when the user says "commit this", "write a commit message", or "stage and commit". Produces a message in the TrackIt house format and checks it against the git rules in AGENTS.md.
disallowed-tools: Write, Edit
---

# Commit message, TrackIt house format

Write the message for the staged change. Never amend, never force-push.

## Steps

1. Read what is staged with `git diff --cached --stat` and `git diff --cached`.
2. If nothing is staged, say so and stop. Do not stage anything yourself.
3. Write the message in this shape:

```
<area>: <what changed, imperative, max 60 characters>

<why it changed, one or two sentences. Skip this block for a one-line change.>
```

4. `<area>` is the package or folder the change touches: `web`, `service`, `domain`,
   `dto`, `docs`, `ci`, or `lab`.
5. Check the message against the git rules in AGENTS.md before you print it.
6. Print the message. Let the user run the commit.

## Rules

- Imperative mood: "add the task endpoint", not "added" or "adds".
- No ticket numbers, no emoji, no trailing full stop in the subject.
- One logical change per commit. If the diff covers two, say so and propose two messages.

## Out of scope

- Staging files, committing, pushing. This skill writes text, nothing else.
- Rewriting history in any form.
