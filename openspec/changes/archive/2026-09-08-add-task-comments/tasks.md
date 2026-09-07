# Implementation tasks: Add task comments

Ordered checklist. Write the tests FIRST from the acceptance scenarios, confirm they
fail, and only then implement.

- [x] 1. Write `backend/src/test/java/ch/acend/trackit/web/CommentControllerTest.java`
      from the acceptance scenarios, one test per scenario. Confirm they FAIL.
- [x] 2. Add the `Comment` record and `CommentEntity` in `domain/`, entity beside the
      record as the house pattern requires.
- [x] 3. Add `CommentRepository` in `repository/`, with
      `findByTaskIdOrderByCreatedAtAsc`.
- [x] 4. Add the Flyway migration `V2__create_comment.sql` with the foreign key and the
      cascade.
- [x] 5. Add `CreateCommentRequest` in `dto/` carrying the validation bounds from the
      spec, not from a guess.
- [x] 6. Add `CommentService` in `service/`, rejecting a comment on a task that does not
      exist with `TaskNotFoundException`.
- [x] 7. Add `CommentController` in `web/`, mapped under `/api/v1/tasks/{taskId}/comments`.
- [x] 8. Run `cd backend && ./mvnw -q test` until green, then read every acceptance
      scenario and point at the test that proves it.
- [x] 9. Review at source: if a test was wrong, fix the spec scenario and regenerate. Do
      not hand-patch the test to make it pass.
