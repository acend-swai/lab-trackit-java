---
mode: agent
description: Write the tests for an OpenSpec change's acceptance scenarios, before any implementation exists.
---

Read the relevant `openspec/changes/<name>/specs/<feature>/spec.md`. Write one
test per `#### Scenario`, following the existing pattern in
`backend/src/test/java/ch/acend/trackit/web/TaskControllerTest.java`
(`@WebMvcTest`, `MockMvc`, service mocked with `@MockitoBean`, method names
that read as a sentence: `postTaskReturnsCreated`).

Run `./mvnw -q test` and confirm every new test FAILS - there is no
implementation yet. Quote the failure output. Do not write or touch any
production code in `src/main/`; that is a separate step
(`backend-coder.prompt.md`).
