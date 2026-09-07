---
description: Scaffold a new Architecture Decision Record with the next free number.
---

Write a new ADR for this decision:

$ARGUMENTS

Steps:

1. List `docs/adr/` and find the highest existing `000N-*.md` number. The new
   file is `docs/adr/000<N+1>-<kebab-case-slug>.md`, four digits, zero-padded.
2. Follow the Nygard shape used by every existing ADR in this repo: `## Status`
   (start at `Proposed` unless told otherwise), `## Context`, `## Decision`,
   `## Consequences`, and `## Alternatives considered` when there is a real
   alternative worth naming.
3. Read at least `docs/adr/0001-layered-spring-architecture.md` first, so the
   new file's tone and section depth match the existing ones rather than
   inventing a new house style.
4. Do not renumber or edit any existing ADR - once committed, an ADR's number
   and content are fixed; a later decision that changes course gets its own
   new ADR referencing the one it supersedes.

Report the new file's path and number when done.
