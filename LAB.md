# Lab 2: Spec first, decide it before the agent decides it for you

| Info | Detail |
|---|---|
| Module | M2 - Spec-first: research, the OpenSpec cycle, tests from the spec |
| Duration | 30 minutes, plus the discussion |
| Harness | Claude Code |
| Tooling | OpenSpec, `@fission-ai/openspec`, installed in task 1. Needs Node 20.19 or newer |
| Repo | `lab-trackit-java`, your clone from lab 1.2, or branch `m2-start` |
| Target state | task comments, specified before written (branch `m2-solution`) |

We are going to add **comments on tasks**: one new entity, two endpoints, one migration. A
task records what has to happen, it does not record what you found out on the way.

The feature is small on purpose, because the module is not about the feature. It is about
the four decisions hiding inside it:

- Who wrote a comment, when TrackIt has no user table?
- How long may a comment be?
- What order do comments come back in?
- What happens to comments when the task is deleted?

An agent answers all four of these **without asking you**. The spec is where you answer
them first.

Part 1 is six tasks for everyone: you write the spec, the agent writes the code, and that
split is the whole module. Part 2 is advanced and optional.

## What you record today

Keep a scratch file open. Three lines, written when they happen, and the discussion at the
end runs on them:

| From | Write down |
|---|---|
| Task 2 | The one thing the research report got wrong or missed |
| Task 4 | Which of the four decisions the agent made that you would not have |
| Task 5 | Any scenario that had no test, and how you found out |

## Where you start

Continue on your own repo from lab 1.2. Check that the suite is green and nothing is
uncommitted:

```bash
cd backend && ./mvnw -q test && cd ..
git status --porcelain
```

Both commands print nothing when you are ready: `-q` silences Maven unless a test fails,
and `git status --porcelain` prints one line per uncommitted file.

If either prints something, take the reference state instead:

```bash
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

You now have tasks in PostgreSQL and a task board in the browser.

---

# Part 1 - Standard, 30 minutes

## Task 1: Install OpenSpec and initialise it (3 min)

### Step 1: Check the Node version

OpenSpec runs from `npx` and its `engines` field requires Node 20.19 or newer:

```bash
node --version
```

The output must be 20.19 or higher:

```text
v24.19.0
```

### Step 2: Initialise OpenSpec in the repo root

`--tools claude` names the harness, so the command does not stop on an interactive picker:

```bash
npx -y @fission-ai/openspec@latest init --tools claude
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

### Step 3: Check the commands arrived

The commands are files, so list them rather than trusting the summary:

```bash
ls .claude/commands/opsx/
```

The output should be:

```text
apply.md  archive.md  explore.md  propose.md  sync.md  update.md
```

Four of those six are the cycle you run today: `explore`, `propose`, `apply`, `archive`.
Restart your Claude Code session so it picks them up, then type `/` and confirm
`/opsx:propose` is offered.

**Take home:** Specs live in `openspec/`, committed and reviewed like code. A spec in a
ticket is not a spec your agent can read.

**Trap:** Running `init` without `--tools`. It then asks which harness to configure and
waits, which looks like a hang in a terminal you have stopped watching.

Reference: [OpenSpec on GitHub](https://github.com/Fission-AI/OpenSpec)

## Task 2: Explore before you specify (4 min)

### Step 1: Have the agent read the repo

Do not describe the repo to the agent. Type this in the Claude session:

```text
/opsx:explore comments on tasks
```

It reads the code and reports what it found: the layering, the persistence pattern from
lab 1.2, the migration convention, how tests are written here. Explore mode reads and
thinks, it writes no code.

### Step 2: Find the one thing it got wrong

Read the report and find one thing it got wrong or missed, then write that line into your
scratch file. There is usually one, and it is cheaper to find now than in a spec built on
top of it.

If the report reads plausibly but names no file, ask:

```text
Which files did you actually open? List them.
```

**Take home:** Facts come from the code, read by the agent, never from your memory of the
code. Yours is out of date too.

**Trap:** A confident research summary about a file the agent never opened. The file list
is how you tell the difference.

## Task 3: Propose the change (7 min)

### Step 1: Ask for the proposal

A proposal turns your one-line request into requirements you can argue with:

```text
/opsx:propose add task comments
```

It creates the change directory and writes the artefacts the `spec-driven` schema defines.

### Step 2: Check what it produced

The CLI reports artefact completion, so ask it rather than reading four files to find out:

```bash
npx -y @fission-ai/openspec@latest status --change add-task-comments
```

Every artefact reads complete when the proposal is finished:

```text
Change: add-task-comments
Schema: spec-driven
Progress: 4/4 artifacts complete

[x] proposal
[x] specs
[x] design
[x] tasks
```

An artefact still marked `[ ]` or `[-]` means the proposal stopped early. Ask the agent to
finish that artefact before you go on.

Those four artefacts live in `openspec/changes/add-task-comments/`:

| File | What it holds |
|---|---|
| `proposal.md` | why, what changes, what is out of scope |
| `specs/task-comments/spec.md` | requirements, each with Given/When/Then scenarios |
| `design.md` | how it is built |
| `tasks.md` | the ordered implementation checklist |

Do not approve it yet. Task 4 is where you earn the module.

**Tip:** A proposal with no "out of scope" section is not finished. That section is what
stops the change growing while you are not looking.

## Task 4: Review the spec, this is your part (5 min)

This is the task the module exists for, and the one thing today you cannot delegate.

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

The CLI parses the spec structure, so a broken heading or a scenario it cannot read shows
up here rather than in task 5:

```bash
npx -y @fission-ai/openspec@latest validate add-task-comments
```

The first line is the verdict, and warnings below it are style advice, not failures:

```text
Change 'add-task-comments' is valid
⚠ [WARNING] task-comments/spec.md: ADDED "Add a comment to a task" should contain SHALL or MUST (RFC 2119 best practice for English specs)
```

If it reports `has issues` with `No deltas found`, the requirement headings are missing
their `## ADDED Requirements` delta header. Tell the agent to add it and validate again.

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

### Step 2: Watch the order

If it writes the implementation before the tests, press `Esc` to interrupt and type:

```text
Stop. Write the tests from the acceptance scenarios in spec.md first, then the code until
they pass.
```

A test written after the code tests the code, a test written from the spec tests the spec.

### Step 3: Run the suite yourself

In a second terminal:

```bash
cd backend && ./mvnw -q test
```

`-q` prints only failures, so a passing suite prints nothing at all and returns you to the
prompt. Hand any failing output back to the Claude session.

### Step 4: Point at the test for every scenario

Now the check that matters, and it is not the test count. Open `spec.md` next to
`backend/src/test/java/ch/acend/trackit/web/CommentControllerTest.java` and point at the
test that proves each scenario.

Count both sides:

```bash
grep -c '^#### Scenario:' openspec/changes/add-task-comments/specs/task-comments/spec.md
grep -c '@Test' backend/src/test/java/ch/acend/trackit/web/CommentControllerTest.java
```

On the reference solution the two numbers do not match:

```text
9
7
```

That gap is the point of this step. List the test names next to the scenario names:

```bash
grep '^#### Scenario:' openspec/changes/add-task-comments/specs/task-comments/spec.md
grep -o 'void [a-zA-Z]*' backend/src/test/java/ch/acend/trackit/web/CommentControllerTest.java
```

Two scenarios in the reference have no MockMvc test: "A task with no comments" and
"Deleting a task removes its comments". The second one cannot have one, because the spec
puts the cascade in the database rather than in the application, and a controller test
never reaches it. Nothing about a green suite told you that.

Do the same match on your own spec, by hand, and write what you find into your scratch
file. A scenario with no test is a requirement nobody implemented.

### Step 5: Start the application

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

The change moves to `openspec/changes/archive/<date>-add-task-comments/`, and its
requirements merge into `openspec/specs/task-comments/spec.md`.

### Step 2: Check the archive happened

`list` shows changes still in flight, so an archived change is gone from it:

```bash
npx -y @fission-ai/openspec@latest list
ls openspec/specs/task-comments/spec.md
```

The output should be:

```text
No active changes found.
openspec/specs/task-comments/spec.md
```

That merged file is the point of the whole tool: **the current truth about how TrackIt
behaves**, in a form your agent reads on the next change. A spec that only describes last
sprint is documentation. This one is context.

### Step 3: Commit the code and the spec together

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

*Deepens task 4.* Start over on a fresh branch. Before running `/opsx:propose`, write the
four decisions down yourself. Then propose, and compare.

Where you agreed, the agent's default was fine. Where you differed is where you need a rule
in `AGENTS.md`, not a correction every time.

**Take home:** The point is not that the agent is wrong. It is that you cannot tell which
defaults are safe until you have written yours down once.

## Task A2 - ADVANCED: Write a skill that enforces the cycle

*Builds on lab 1.2 task A1.* Write `.claude/skills/spec-review/SKILL.md`: given a change
directory, it checks every scenario against testable, unambiguous and complete, and reports
one line per failure.

Run it on the spec you approved in task 4. It finds something you missed.

**Trap:** A skill that says "the spec looks good" has no value. Make it report findings, or
say explicitly per criterion that it checked and found none.

## Task A3 - ADVANCED: Break the spec on purpose

*Deepens task 5.* Change one scenario in the archived spec: make the body limit 200
characters instead of 2000. Run `/opsx:propose` for the change and let it apply.

Then answer: did it update the migration, the DTO, the test and the spec? Which did it
miss?

**Take home:** A change that touches four files is where drift starts, and it is the
argument for the spec being the source rather than one of the four.

## Task A4 - ADVANCED: Run the next change in half the time

Run the whole cycle again for a second feature of your choosing and time it against your
first run. The merged spec from task 6 is now context the agent reads for free.

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
