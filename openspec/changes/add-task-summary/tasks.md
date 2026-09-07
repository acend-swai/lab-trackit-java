# Implementation tasks: Add task status summary

Ordered checklist. Write the tests FIRST from the acceptance scenarios, confirm
they fail, and only then implement. Left unchecked on purpose - this is the
slice a full-agentic run carries to green, not a pre-baked diff.

- [ ] 1. Write `backend/src/test/java/ch/acend/trackit/web/TaskSummaryControllerTest.java`
      from the acceptance scenarios, one test per scenario. Confirm they FAIL.
- [ ] 2. Add a query method to `TaskRepository` that returns a per-status count
      without loading every row (`countByStatus`, or a projection - the
      implementer's call, either satisfies the spec).
- [ ] 3. Add `TaskSummary` in `domain/` - a record, `Map<TaskStatus, Long>` or
      one field per status, whichever reads more plainly as JSON matching the
      spec's `{"open":n,"done":n}` shape.
- [ ] 4. Add a summary method to `TaskService`, ensuring every `TaskStatus`
      value is present in the result even when its count is zero.
- [ ] 5. Add `TaskSummaryController` in `web/`, mapped at `GET /api/v1/tasks/summary`.
- [ ] 6. Run `cd backend && ./mvnw -q test` until green, then read every
      acceptance scenario and point at the test that proves it.
- [ ] 7. Review at source: if a test was wrong, fix the spec scenario and
      regenerate. Do not hand-patch the test to make it pass.
