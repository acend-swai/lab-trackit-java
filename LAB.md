# Lab 2: Spec first, decide it before the agent decides it for you

| Info | Detail |
|---|---|
| Module | M2 - Spec-first: research, the OpenSpec cycle, tests from the spec |
| Duration | 30 minutes, plus the discussion |
| Harness | Claude Code |
| Tooling | OpenSpec, `@fission-ai/openspec`, you install it in task 1. Needs Node 20.19 or newer |
| Repo | `lab-trackit-java`, your clone from lab 1.2, or branch `m2-start` |
| Target state | task comments, specified before written (branch `m2-solution`) |

We are going to add **comments on tasks**: one new entity, two endpoints, one migration. A
task records what has to happen, it does not record what you found out on the way.

Four decisions are hiding inside it:

- Who wrote a comment, when TrackIt has no user table?
- How long may a comment be?
- What order do comments come back in?
- What happens to comments when the task is deleted?

An agent answers all four of these **without asking you**. The spec is where you answer
them first.

Part 1 is six tasks for everyone: you write the spec, the agent writes the code. Part 2 is
advanced and optional.

## What you record today

Keep a scratch file open. Three lines, written when they happen, and the discussion at the
end runs on them:

| From | Write down |
|---|---|
| Task 2 | The one thing the research report got wrong or missed |
| Task 4 | Which of the four decisions the agent made that you would not have |
| Task 5 | Any scenario that had no test, and how you found out |

## Where you start

Check that the suite on your repo from lab 1.2 is green and nothing is uncommitted:

```bash
cd backend && ./mvnw -q test && cd ..
git status --porcelain
```

Both commands print nothing when you are ready: `-q` silences Maven unless a test fails,
and `git status --porcelain` prints one line per uncommitted file.

If either prints something, take the reference state instead. Commit what you have first,
because `git checkout` refuses to switch branches over uncommitted work:

```bash
git add -A && git commit -m "chore: end of lab 1.2"
git fetch origin && git checkout -B m2-start origin/m2-start
```

Either way, check where you are:

```bash
git branch --show-current
```

The output is your own branch, or:

```text
m2-start
```

Either branch gives you tasks in PostgreSQL and a task board in the browser, which is what
this lab builds on.

---

# Part 1 - Standard, 30 minutes

## Task 1: Install OpenSpec and initialise it (3 min)

### Step 1: Check the Node version

OpenSpec is an npm package and its `engines` field requires Node 20.19 or newer:

```bash
node --version
```

The output must be 20.19 or higher:

```text
v24.19.0
```

### Step 2: Install the OpenSpec CLI

Install it globally, so `openspec` is a command in every terminal you open today:

```bash
npm install -g @fission-ai/openspec@latest
```

Check that the command is on your PATH:

```bash
openspec --version
```

The output is the version you just installed:

```text
1.12.0
```

**Note.** `npx @fission-ai/openspec` runs the package once out of the npx cache and installs
no command. Every later task types `openspec` directly, which is why you install it here.

### Step 3: Initialise OpenSpec in the repo root

`--tools claude` names the harness, so the command does not stop on an interactive picker:

```bash
openspec init --tools claude
```

The output ends with what it created:

```text
OpenSpec Setup Complete

Created: Claude Code
6 skills and 6 commands in .claude/
Config: openspec/config.yaml (schema: spec-driven)
```

It creates the `openspec/` directory and writes the OpenSpec commands and skills into
`.claude/`. It runs on your machine, needs no API key and no MCP server: it manages spec
files, and your agent writes the code.

### Step 4: Check the commands arrived

The commands are files, so list them rather than trusting the summary:

```bash
ls .claude/commands/opsx/
```

The output should be:

```text
apply.md  archive.md  explore.md  propose.md  sync.md  update.md
```

Four of those six are the cycle you run today: `explore`, `propose`, `apply`, `archive`.

### Step 5: Load the commands into your session

Claude Code reads `.claude/commands/` when a session starts, so the session you already
have open does not know about these six files yet. Restart it, then type a single slash:

```text
/
```

`/opsx:propose` and the other five appear in the list. If they do not, you restarted a
session whose working directory is not the repo root: check with `pwd` and restart from
there.

### Step 6: Commit the scaffold

`openspec init` wrote files into your working tree. They belong in the repo, so commit them
before the first agent run, and every later `git status` shows only what the agent changed:

```bash
git add openspec/ .claude/
git commit -m "chore: add OpenSpec scaffold"
```

`git commit` prints the branch and the file count. The scaffold is 15 files, the six
commands, the six skills, `config.yaml` and two `.gitkeep`:

```text
[m2-start 4f2a1c9] chore: add OpenSpec scaffold
 15 files changed, 892 insertions(+)
```

The hash and the insertion count are yours, not these. Check that nothing was left behind:

```bash
git status --porcelain
```

The output is empty.

**Take home:** Specs live in `openspec/`, committed and reviewed like code. A spec in a
ticket is not a spec your agent can read.

Reference: [OpenSpec on GitHub](https://github.com/Fission-AI/OpenSpec)

## Task 2: Explore before you specify (4 min)

### Step 1: Have the agent read the repo

Do not describe the repo to the agent, it is about to read it. Type this in the Claude
session:

```text
/opsx:explore comments on tasks
```

It reports what it found in the code: the layering, the persistence pattern from lab 1.2,
the migration convention, how tests are written here. It writes no files, so your working
tree is unchanged since the commit in task 1:

```bash
git status --porcelain
```

The output is empty. If it lists `openspec/` or `.claude/`, you skipped the commit in task
1 step 6: run it now, then continue.

## Task 3: Propose the change (7 min)

### Step 1: Ask for the proposal

A proposal turns your one-line request into requirements you can argue with:

```text
/opsx:propose add task comments
```

It creates the change directory and writes the artefacts the `spec-driven` schema defines.

### Step 2: Check what it produced

The CLI reports artefact completion, so ask it rather than opening files to find out:

```bash
openspec status --change add-task-comments
```

The output names the change, the schema, the directory and one line per artefact:

```text
Change: add-task-comments
Schema: spec-driven
Change root: /workspaces/trackit/openspec/changes/add-task-comments
Progress: 3/4 artifacts complete

[x] proposal
[x] specs
[ ] design
[x] tasks
```

Your `Change root:` is your own path, not this one.

**Expect `3/4` here, with `[ ] design`.** The `spec-driven` schema writes `design.md` only
for a cross-cutting change, a new dependency or a hard migration, and task comments is none
of those. Three artefacts is the finished state for this change:

| File | What it holds |
|---|---|
| `proposal.md` | why, what changes, what is out of scope |
| `specs/task-comments/spec.md` | requirements, each with Given/When/Then scenarios |
| `tasks.md` | the ordered implementation checklist |

Read the marker before you judge the number:

| Marker | What it means |
|---|---|
| `[x]` | written |
| `[ ]` | not written, and nothing is stopping it |
| `[-]` | blocked, the line names the artefact it waits for |
| `[~]` | skipped, the change sets `skip_specs` in `.openspec.yaml` |

A `[-]` on `specs` or `tasks` means the proposal stopped early. Ask the agent to finish that
artefact before you go on.

Do not approve it yet. Task 4 reviews it first.

**Tip:** A proposal with no "out of scope" section is not finished. That section is what
stops the change growing while you are not looking.

## Task 4: Review the spec, this is your part (5 min)

### Step 1: Answer the four questions against the spec

Open `openspec/changes/add-task-comments/specs/task-comments/spec.md` and answer these
four. For each one: did the agent decide it, and did it tell you?

- Who wrote the comment? There is no user table.
- How long may a body be?
- What order do comments come back in?
- What happens to comments when the task is deleted?

Write the decision you disagree with into your scratch file now, before you change
anything.

### Step 2: Hold every scenario to three tests

| Test | A scenario fails it when |
|---|---|
| Testable | you cannot write a MockMvc test from it without inventing a detail |
| Unambiguous | two people would build different things from the same words |
| Complete | the unhappy path is missing: no 404, no validation failure, no empty list |

A scenario that passes all three reads like this one, from the reference spec:

```text
#### Scenario: Commenting on a task that does not exist

- **Given** no task with id 404
- **When** the client POSTs a valid comment to `/api/v1/tasks/404/comments`
- **Then** the response is `404` and no comment is stored
```

### Step 3: Fix the spec, not the code

Edit `spec.md` directly, or tell the agent what to change and why:

```text
In spec.md, the body limit is a decision I want to make: cap it at 2000 characters and
add a scenario for a body one character over the limit. Change nothing else.
```

Whatever you leave in here is what gets built.

### Step 4: Check the spec is still valid

The CLI parses the spec structure, so a heading it cannot read surfaces now rather than
halfway through the implementation in task 5:

```bash
openspec validate add-task-comments
```

The first line is the verdict, and after your edits it usually reads:

```text
Change 'add-task-comments' is valid
```

**Note.** `is valid` can still be followed by `⚠ [WARNING]` lines, most often
`should contain SHALL or MUST`. Warnings do not fail the change. Read the marker, not the
line count: `✗ [ERROR]` fails, `⚠ [WARNING]` does not.

### Step 5: Read a failure when you get one

Editing `spec.md` by hand is what breaks the structure, so run the validate again after
every hand edit. Two errors account for nearly all of them:

| Error line | What you did | Fix |
|---|---|---|
| `is missing requirement text` | a `### Requirement:` heading runs straight into `#### Scenario:` | write one sentence between them |
| `No delta sections found` | the requirements sit under no delta header | add `## ADDED Requirements` above the first requirement |

The first one looks like this, naming the requirement it means:

```text
Change 'add-task-comments' has issues
✗ [ERROR] task-comments/spec.md: ADDED "List the comments on a task" is missing requirement text
```

Fix it by writing that sentence directly above the first scenario of the requirement it
names:

```text
The comments on a task come back in the order they were written.
```

Validate again and the verdict returns to `is valid`.

**Note.** `openspec validate add-task-comments --strict` fails the change on warnings too.
Use it when you want the RFC 2119 wording enforced, not while you are still editing.

You end with at least one scenario you changed and one decision you overrode. If you
changed nothing, read the four questions against the spec again: the agent decided all four
somewhere.

**Take home:** Move review earlier. A wrong decision costs one line in a spec and a
refactor after the code exists. Agents specify the happy path, so every missing unhappy
path becomes a production incident with your name on it.

**Tip:** Read each scenario and ask: could I hand this to somebody and get back something I
did not expect? If yes, it is not specified, it is described.

**Trap:** Approving the spec because it reads well. It reads well because a language model
wrote it. Check what it decided, not how it sounds.

## Task 5: Implement against the approved spec (9 min)

### Step 1: Hand the building over

The spec says what to build, so let the agent build it:

```text
/opsx:apply add-task-comments
```

It works the checklist in `tasks.md`: **tests first, from the acceptance scenarios**, then
the code until they pass.

### Step 2: Watch the order it writes in

Read the file names as they scroll past. `CommentControllerTest.java` must be written
before `CommentController.java`. If the implementation goes first, press `Esc` to interrupt
and type:

```text
Stop. Write the tests from the acceptance scenarios in spec.md first, then the code until
they pass.
```

A test written after the code is shaped by the code it found, so it passes without ever
checking the scenario. Order it the other way and the test fails until the code satisfies
the spec.

### Step 3: Run the suite yourself

Do not take the agent's word for a green suite. In a second terminal:

```bash
cd backend && ./mvnw -q test
```

`-q` prints only failures, so a passing suite prints nothing at all and returns you to the
prompt. Anything else is a failure: copy the output back into the Claude session and let it
fix the code.

### Step 4: Point at the test for every scenario

Now the check that matters, and it is not the test count. Count both sides:

```bash
grep -c '^#### Scenario:' openspec/changes/add-task-comments/specs/task-comments/spec.md
grep -c '@Test' backend/src/test/java/ch/acend/trackit/web/CommentControllerTest.java
```

On the reference solution the two numbers do not match:

```text
9
7
```

Your own numbers differ from these, because your spec is the one you edited in task 4. Two
numbers that match are not proof either: it is the names that have to line up. List both:

```bash
grep '^#### Scenario:' openspec/changes/add-task-comments/specs/task-comments/spec.md
grep -oE 'void [a-zA-Z_]+' backend/src/test/java/ch/acend/trackit/web/CommentControllerTest.java
```

On the reference the seven test names cover seven of the nine scenarios:

```text
void postCommentReturnsCreated
void postCommentWithoutAuthorReturnsBadRequest
void postCommentWithEmptyBodyReturnsBadRequest
void postCommentLongerThanTheLimitReturnsBadRequest
void postCommentOnUnknownTaskReturnsNotFound
void getCommentsReturnsThemOldestFirst
void getCommentsForUnknownTaskReturnsNotFound
```

Two scenarios have no test: "A task with no comments" and "Deleting a task removes its
comments". Read why the second one cannot have one:

```bash
grep 'REFERENCES' backend/src/main/resources/db/migration/V2__create_comment.sql
```

The output shows the cascade is in the database, not in the application:

```text
    task_id    BIGINT       NOT NULL REFERENCES task (id) ON DELETE CASCADE,
```

A MockMvc test drives the controller, so it never reaches that line. Nothing about a green
suite told you the requirement was untested.

Do the same match on your own spec, by hand, and write into your scratch file every
scenario with no test name against it. A scenario with no test is a requirement nobody
implemented.

### Step 5: Start the application

Reuse the terminal you ran the suite in, and start the backend from `backend/`:

```bash
./mvnw spring-boot:run
```

Spring Boot logs a `Started` line once it is up:

```text
Started TrackitApplication in 4.312 seconds (process running for 4.9)
```

Until that line appears, `localhost:8080` refuses the connection. Leave it running.

### Step 6: Exercise the new endpoint

In a third terminal, post a comment on task 1:

```bash
curl -s -X POST localhost:8080/api/v1/tasks/1/comments \
  -H 'content-type: application/json' \
  -d '{"author":"you","body":"Specified before it was written."}'
```

The output carries a generated `id` and `createdAt`:

```json
{"id":1,"taskId":1,"author":"you","body":"Specified before it was written.","createdAt":"2026-09-08T09:14:22.481Z"}
```

Read it back, then ask for a task that does not exist:

```bash
curl -s localhost:8080/api/v1/tasks/1/comments
curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/api/v1/tasks/404/comments
```

The first prints a list holding the comment you just posted. The second prints only the
status code:

```text
404
```

That 404 is a scenario from your spec, answered by the running application.

### Step 7: Start the frontend and look at the board

The backend is one half. Start the other half in a fourth terminal, with the application
from step 5 still running:

```bash
cd frontend
npm run dev
```

Vite prints the address it serves on:

```text
  ➜  Local:   http://localhost:5173/
```

Open <http://localhost:5173>. The board lists the tasks from the database, including task
1, the one you just commented on. Add a task in the form and it appears in the list.

**Note.** The board shows tasks, not comments. Nobody specified a comment view, so the
agent built none: the spec covered two endpoints and that is exactly what exists. Your
comment is in the database and answers on `/api/v1/tasks/1/comments`, and there is no
screen that shows it.

Prove that from the browser rather than from `curl`. Open
<http://localhost:5173/api/v1/tasks/1/comments> in a second tab:

```json
[{"id":1,"taskId":1,"author":"you","body":"Specified before it was written.","createdAt":"2026-09-08T09:14:22.481Z"}]
```

That URL works on port 5173 because `frontend/vite.config.ts` proxies `/api` to
`localhost:8080`, so the browser talks to one origin and no CORS rule has to be written.

Leave both running. Stop them with `Ctrl+C` in their own terminals when the lab is done.

**Take home:** Make "every scenario points at a test" the merge gate, not a coverage
percentage. Line coverage does not tell you a requirement is missing, scenario coverage
does.

**Trap:** "All tests pass" while a scenario has no test at all. That is the failure this
task is built to catch.

## Task 6: Archive the change (2 min)

### Step 1: Fold the change into the standing spec

The code is in and the tests pass, so archive it:

```text
/opsx:archive add-task-comments
```

Two things happen: the change directory moves under `openspec/changes/archive/` behind a
`YYYY-MM-DD-` prefix, and its requirements merge into `openspec/specs/task-comments/spec.md`.

### Step 2: Check the archive happened

`list` shows only changes still in flight, so an archived change is gone from it:

```bash
openspec list
ls openspec/changes/archive/
```

You see the change is no longer active, and the dated directory holds it instead:

```text
No active changes found.
2026-09-08-add-task-comments
```

Your date prefix is the day you run it, not this one.

### Step 3: Read what the merge produced

The merged spec is the file the whole cycle exists to produce, so count what landed in it:

```bash
grep -c '^#### Scenario:' openspec/specs/task-comments/spec.md
```

Every scenario your change specified is now in the standing spec, nine on the reference
solution:

```text
9
```

That file is **the current truth about how TrackIt behaves**, in a form your agent reads on
the next change. A spec that only describes last sprint is documentation. This one is
context.

### Step 4: Commit the code and the spec together

```bash
git add -A && git commit -m "feat: comment on a task, specified first"
```

`git commit` names the branch and counts the files:

```text
[m2-start 7a8b9c0] feat: comment on a task, specified first
 15 files changed, 541 insertions(+), 2 deletions(-)
```

The hash and the counts are yours, not these. `git status --porcelain` prints nothing
afterwards.

**Take home:** A change exists like a branch: propose, review, apply, then merge into the
truth. Archiving is the compounding part, every change makes the next one better specified.

---

# Part 2 - ADVANCED

Optional. Start when `./mvnw -q test` prints nothing and `git status --porcelain` prints
nothing.

## Task A1 - ADVANCED: Decide before the agent does

*Deepens task 4.* Branch away from your finished work so the reference stays intact:

```bash
git checkout -b m2-my-decisions
```

Write your four answers into a scratch file before you run anything. Then propose the same
change again:

```text
/opsx:propose add task comments
```

Diff its four decisions against yours. Every difference is a rule that belongs in
`AGENTS.md`, where it applies to every future change, instead of a correction you type
again each time.

**Take home:** The point is not that the agent is wrong. It is that you cannot tell which
defaults are safe until you have written yours down once.

## Task A2 - ADVANCED: Write a skill that enforces the cycle

*Builds on lab 1.2 task A1.* Ask Claude Code to write the skill:

```text
Write .claude/skills/spec-review/SKILL.md. Given a change directory, it checks every
#### Scenario: against testable, unambiguous and complete, and prints one line per
failure with the scenario name. It reports per criterion even when it finds nothing.
```

Run it against the spec you approved in task 4:

```text
Use the spec-review skill on openspec/changes/add-task-comments/
```

It prints one line per finding. Read them against the spec: at least one is something you
passed over in task 4.

**Trap:** A skill that answers "the spec looks good" has no value. If that is what you get,
the description is too vague, so name the three criteria in it explicitly.

## Task A3 - ADVANCED: Break the spec on purpose

*Deepens task 5.* The body limit of 2000 is written in more places than one. Find them:

```bash
grep -rn '2000' backend/src/main openspec/specs/task-comments/spec.md
```

The output should be four lines on the reference solution: the column width, the scenario,
and the DTO twice, once in a comment and once in the annotation that enforces it.

```text
backend/src/main/resources/db/migration/V2__create_comment.sql:5:    body       VARCHAR(2000) NOT NULL,
openspec/specs/task-comments/spec.md:34:#### Scenario: A comment body is capped at 2000 characters
backend/src/main/java/ch/acend/trackit/dto/CreateCommentRequest.java:8: * of 1 to 2000 characters.
backend/src/main/java/ch/acend/trackit/dto/CreateCommentRequest.java:12:        @NotBlank @Size(max = 2000) String body) {
```

That prose line in the DTO is the one to watch: nothing enforces it, so it is the copy that
goes stale first.

Now change the limit to 200 through the cycle, not by hand:

```text
/opsx:propose cap comment bodies at 200 characters
```

Let it apply, then look for whatever still says 2000. A word-boundary match keeps `200`
from matching inside `2000`:

```bash
grep -rnw '2000' backend/src/main openspec/specs/task-comments/spec.md
```

Every line this still prints is a copy the change missed. Check the migration first: adding
a second migration that alters the column is the step most often skipped, and while the
column is still `VARCHAR(2000)` the database accepts values your new rule rejects.

**Take home:** A limit written in four places drifts. That is the argument for the spec
being the source the others are generated from.

## Task A4 - ADVANCED: Run the next change in half the time

Note the clock, then run the whole cycle for a second feature, for example a due date on a
task:

```text
/opsx:propose add a due date to a task
```

Time it against your first run. The merged spec from task 6 is context the agent now reads
for free, so the explore step has less to discover.

**Take home:** That difference is the return on the whole practice, and it only shows up on
the second change.

## Bring to the discussion

- **Which decision did the agent make that you would not have?**
- **Which scenario had no test, and how would you have found out without checking?**
- **Which part of your lab 1.2 prompt is now redundant, because the spec says it?**

## Further reading

- OpenSpec: <https://github.com/Fission-AI/OpenSpec>
- This repo's decisions: `docs/architecture.md`, `docs/adr/0001-*`
- The merged spec you produced: `openspec/specs/task-comments/spec.md`
