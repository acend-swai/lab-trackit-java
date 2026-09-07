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

**An agent answers all four without asking you.** The spec is where you answer them first.

**Part 1 is for everyone.** Six tasks. You write the spec, the agent writes the code, and
that split is the whole module.

**Part 2 is advanced and optional.** Start it when Part 1 is green.

## What you record today

Keep a scratch file open. Three lines, written when they happen, and the discussion at the
end runs on them:

| From | Write down |
|---|---|
| Task 2 | The one thing the research report got wrong or missed |
| Task 4 | Which of the four decisions the agent made that you would not have |
| Task 5 | Any scenario that had no test, and how you found out |

## Where you start

Continue on your own repo from lab 1.2. Check it first:

```bash
cd backend && ./mvnw -q test && cd ..
git status --porcelain
```

Tests green, nothing uncommitted. If either fails, take the reference state:

```bash
git fetch origin && git checkout m2-start
docker compose up -d
```

Either way you have tasks in PostgreSQL and a task board in the browser.

---

# Part 1 - Standard, 30 minutes

## Task 1: Install OpenSpec and initialise it (3 min)

```bash
node --version          # must be 20.19 or newer
npx -y @fission-ai/openspec@latest init
```

`init` creates the `openspec/` directory and registers the OpenSpec skills with your
harness. It runs on your machine, needs no API key and no MCP server: it manages spec
files, and your agent writes the code.

Check the skills arrived:

```text
/help
```

You see `/opsx:explore`, `/opsx:propose`, `/opsx:apply` and `/opsx:archive`. Those four are
the cycle.

**Take home:** Specs live in `openspec/`, committed and reviewed like code. A spec in a
ticket is not a spec your agent can read.

Reference: [OpenSpec on GitHub](https://github.com/Fission-AI/OpenSpec)

## Task 2: Explore before you specify (4 min)

Do not describe the repo to the agent. Have it read the repo:

```text
/opsx:explore comments on tasks
```

It reads the code and reports what it found: the layering, the persistence pattern from
lab 1.2, the migration convention, how tests are written here.

Read the report and find one thing it got wrong or missed. There is usually one, and it is
cheaper to find now than in a spec built on top of it.

**Take home:** Facts come from the code, read by the agent, never from your memory of the
code. Yours is out of date too.

**Trap:** A confident research summary about a file the agent never opened. Ask which files
it read.

## Task 3: Propose the change (7 min)

```text
/opsx:propose add task comments
```

It writes three files into `openspec/changes/add-task-comments/`:

| File | What it holds |
|---|---|
| `proposal.md` | why, what changes, what is out of scope |
| `specs/task-comments/spec.md` | requirements, each with Given/When/Then scenarios |
| `tasks.md` | the ordered implementation checklist |

Do not approve it yet. Task 4 is where you earn the module.

**Tip:** A proposal with no "out of scope" section is not finished. That section is what
stops the change growing while you are not looking.

## Task 4: Review the spec, this is your part (5 min)

**This is the task the module exists for.** Everything else today can be delegated.

Open `specs/task-comments/spec.md` and answer these four. For each one: did the agent
decide it, and did it tell you?

- Who wrote the comment? There is no user table.
- How long may a body be?
- What order do comments come back in?
- What happens to comments when the task is deleted?

Then check the scenarios against three tests:

| Test | A scenario fails it when |
|---|---|
| Testable | you cannot write a MockMvc test from it without inventing a detail |
| Unambiguous | two people would build different things from the same words |
| Complete | the unhappy path is missing: no 404, no validation failure, no empty list |

Fix the spec, not the code. Edit `spec.md` directly, or tell the agent what to change and
why. Whatever you leave in here is what gets built.

You end with at least one scenario you changed and one decision you overrode. Nobody gets
zero.

**Take home:** Move review earlier. A wrong decision costs one line in a spec and a
refactor after the code exists. Agents specify the happy path, so every missing unhappy
path becomes a production incident with your name on it.

**Tip:** Read each scenario and ask: could I hand this to somebody and get back something I
did not expect? If yes, it is not specified, it is described.

**Trap:** Approving the spec because it reads well. It reads well because a language model
wrote it. Check what it decided, not how it sounds.

## Task 5: Implement against the approved spec (9 min)

```text
/opsx:apply add-task-comments
```

It works the checklist in `tasks.md`: **tests first, from the acceptance scenarios**, then
the code until they pass.

Watch the order. If it writes the implementation before the tests, stop it and say so. A
test written after the code tests the code, a test written from the spec tests the spec.

```bash
cd backend && ./mvnw -q test
```

Now the check that matters, and it is not the test count: **open `spec.md` next to the test
file and point at the test that proves each scenario.** Every scenario needs one. A
scenario with no test is a requirement nobody implemented, and a green suite will not tell
you.

```bash
./mvnw spring-boot:run
```

```bash
curl -s -X POST localhost:8080/api/v1/tasks/1/comments \
  -H 'content-type: application/json' \
  -d '{"author":"you","body":"Specified before it was written."}'

curl -s localhost:8080/api/v1/tasks/1/comments
curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/api/v1/tasks/404/comments
```

The last one prints `404`.

**Take home:** Make "every scenario points at a test" the merge gate, not a coverage
percentage. Line coverage does not tell you a requirement is missing, scenario coverage
does.

**Trap:** "All tests pass" while a scenario has no test at all. That is the failure this
task is built to catch.

## Task 6: Archive the change (2 min)

```text
/opsx:archive add-task-comments
```

The change moves to `openspec/changes/archive/<date>-add-task-comments/`, and its
requirements merge into `openspec/specs/task-comments/spec.md`.

That merged file is the point of the whole tool: **the current truth about how TrackIt
behaves**, in a form your agent reads on the next change. A spec that only describes last
sprint is documentation. This one is context.

```bash
git add -A && git commit -m "feat: comment on a task, specified first"
```

`openspec/changes/` is empty, `openspec/specs/` is populated, and you have a commit.

**Take home:** A change exists like a branch: propose, review, apply, then merge into the
truth. Archiving is the compounding part, every change makes the next one better specified.

---

# Part 2 - ADVANCED

Optional. Start when Part 1 is green and committed.

## Task A1 - ADVANCED: Decide before the agent does

*Deepens task 4.* Start over on a fresh branch. Before running `/opsx:propose`, write the
four decisions down yourself. Then propose, and compare.

Where you agreed, the agent's default was fine. Where you differed is where you need a rule
in `AGENTS.md`, not a correction every time.

**Take home:** The point is not that the agent is wrong. It is that you cannot tell which
defaults are safe until you have written yours down once.

## Task A2 - ADVANCED: A skill that enforces the cycle

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

## Task A4 - ADVANCED: The next change, in half the time

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
