# ADR 0001: Layered Spring architecture with records in the domain

## Status

Accepted.

## Context

This repository is a teaching artefact. Participants have an agent generate code into
it, so the structure has to be obvious from four file names and hard to drift from. It
also has to mirror `acend-swai/lab-trackit`, the Python line, so the two remain
comparable across a workshop.

## Decision

Four packages, one responsibility each: `web`, `service`, `domain`, `dto`. Domain types
are records without framework annotations. Controllers take a service by constructor
injection. Requests carry validation annotations in `dto`, never in `domain`.

## Consequences

An agent asked for a new endpoint has one obvious place per file, which makes drift
visible in review rather than invisible in a diff. The cost is four small files for a
feature that would fit in one - deliberate, because the layering is what participants
are meant to see.

Persistence in M2 adds an entity next to the record instead of annotating it, which
keeps the API shape stable when the storage changes.
