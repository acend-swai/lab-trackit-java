# Lab 1.1: your first controlled loop

| Info | Detail |
|---|---|
| Module | M1.1 - Agentic loop, harness, models |
| Duration | 40 minutes, plus 5 minutes of discussion before the break |
| Harness | Claude Code. For task 4 also OpenCode against OpenRouter |
| Stack | Java 21, Spring Boot 3.5, Maven wrapper. Your own stack works too - every reference artefact is Java |
| Repo | `lab-trackit-java`, branch `m1-1-start` |
| Target state | create and list a task, in memory (branch `m1-1-solution`) |

**The lab has two parts.**

**Part 1 is for everyone.** Four tasks, guided, with the commands in this handout. Work
through it in order.

**Part 2 is advanced.** Start it only when Part 1 runs green. It is marked
**ADVANCED** on every task and it is optional - nothing in the afternoon depends on it.

Task 4 in Part 1 has to happen. The discussion after the lab is five minutes long and
runs on your comparison rows, so bring them filled in.

## What you build

TrackIt is a small task management tool. A task has a title, a project and a status.
Today it holds tasks in memory. Persistence comes in M2, the container in M3.

`m1-1-start` has one endpoint, `GET /api/v1/health`. That is your reference pattern -
read it before you have anything generated. The branch also ships `AGENTS.md` and its
one-line `CLAUDE.md`: task 1 compares a run without that context against a run with it,
task 2 writes one from scratch.

## Standard commands you use today

Use the built-in commands rather than doing things by hand. Each one is a feature worth
knowing on its own.

| Command | What it does | Details |
|---|---|---|
| `/init` | Scans the repo and writes a `CLAUDE.md` describing it. Used in task 2 | [init](https://code.claude.com/docs/en/commands) |
| `/cost` | Shows what the session has cost so far. Alias for `/usage` | [costs](https://code.claude.com/docs/en/costs) |
| `/context` | Shows what fills the context window right now | [commands](https://code.claude.com/docs/en/commands) |
| `/compact` | Summarises the session and frees the window | [commands](https://code.claude.com/docs/en/commands) |
| `/permissions` | Allow, ask and deny rules per tool, in a dialog | [permissions](https://code.claude.com/docs/en/permissions) |
| `/models` | In OpenCode: switch the model at runtime. Task 1 | [opencode config](https://opencode.ai/docs/config/) |

`/help` lists everything your version has. Versions differ - trust `/help` over any
handout, including this one.

---

# Part 1 - Standard

Everyone works through this part. About 36 of the 40 minutes.

## Task 1 - The same task, three times (10 min)

One task, run three times, so that only one thing changes per run: how much context the
agent has, and how much model is behind the loop.

**Step 1 - set up and check.**

```bash
git clone -b m1-1-start https://github.com/acend-swai/lab-trackit-java.git trackit
cd trackit
cp ~/Downloads/trackit.env .env       # the file from your mail
set -a; source .env; set +a           # OpenCode reads the environment, not the file
./verify.sh
git commit --allow-empty -m "chore: start of my workshop repo"
```

Every line must read `[OK]`, except the health check at the very end - that answers only
while the application runs, so `[MISSING]` there is expected now. If
`OPENROUTER_API_KEY not exported` appears, you skipped the `source` line. In the
devcontainer every new terminal sources `.env` for you.

Claude Code talks to the Anthropic API directly, with no gateway in front of it. If you
have your own licence, log in with your account and leave `ANTHROPIC_API_KEY` empty - a
key set there overrides your subscription.

**The task, identical in all three runs.** Paste it verbatim each time:

```text
Add two endpoints to the task API: create a task, and list all tasks. Keep the tasks in
memory. Follow the patterns this project already uses, and make sure the tests pass.
```

**Step 2 - run it without grounding.** Move the context file aside, so the agent works
from the code alone:

```bash
mv AGENTS.md AGENTS.md.off
claude
```

Give it the task. Watch where it guesses: package layout, the `/api/v1` prefix,
constructor injection, whether it writes a test at all. Do not correct it. When it
reports done, note what it produced and throw the run away:

```bash
git checkout -- . && git clean -fd
```

**Step 3 - run it with grounding.** Put the context file back and start a fresh session:

```bash
mv AGENTS.md.off AGENTS.md
claude
```

`AGENTS.md` holds the stack, the layering, the coding standards, the git rules and the
entity model. `CLAUDE.md` is one line, `@AGENTS.md`, so Claude Code and OpenCode read the
same file. Give it the same task, unchanged.

**Expected result.** The grounded run lands on `web/`, `service/`, `domain/` and `dto/`,
uses `@RequestMapping("/api/v1/...")`, injects through the constructor and writes a
`@WebMvcTest`. Keep this run - it is your F1 state.

**Step 4 - run it on an open-weight model.** Same task, same prompt, through OpenCode
against OpenRouter. Two models, one small and one large, so the only variable is how much
model is behind the loop:

```bash
opencode
```

Then `/models`, and run the task once per model:

| Model id | What it is | 4-bit footprint |
|---|---|---|
| `qwen/qwen3-coder-30b-a3b-instruct` | 30B MoE, the small one | 16 GB, measured on our hardware |
| `qwen/qwen3-coder-next` | 80B MoE, 3B active, 262k context | about 46 GB |

`opencode.json` in the repo root lists these and reads your key from the environment.
Others are in the README if you have time - the last three do not fit on a workstation,
which is the whole point when the repository may not leave the building.

**The question is not which answer is prettier. It is where the small model breaks:**

- tool selection - did it pick the right tool for the step?
- sticking to `AGENTS.md` - or did it drift from the standards?
- reading its own error output - did it act on the failure, or repeat itself?
- knowing when it is done - did it stop while red, or never stop?

Write one line per model on your comparison sheet. The module discussion runs on these
rows.

**Take this to your team**

| | In this lab | In your repo |
|---|---|---|
| Pre-check | `./verify.sh` checks Java, both CLIs, the key and the build | Write one for your own repo and check the *agent* prerequisites, not just the app. Run it in onboarding and in CI |
| Key handling | `.env` in the repo root, capped, expires tonight | The key belongs in your secret store. `.env` goes into `.gitignore` in the first commit, never later |
| The comparison | grounded against ungrounded, on the same prompt | Do this once with your own repo before you judge any model. Most "the model is bad" verdicts are missing context, not missing capability |
| Model choice | one small, one large, same family | Judge on iterations to green, not on wall-clock time. The small one is the interesting one - it shows you which step your task actually depends on |

**Tip.** The `[OK]` line format costs nothing and pays for itself the first time someone
says "it does not work". A pre-check that names which line failed turns a 20-minute
debugging conversation into one sentence.

**Reference.** [Claude Code commands](https://code.claude.com/docs/en/commands) ·
[OpenCode configuration](https://opencode.ai/docs/config/) ·
[OpenRouter with OpenCode](https://openrouter.ai/docs/cookbook/coding-agents/opencode-integration)

## Task 2 - Generate the context file, then sharpen it (6 min)

The context file is the strongest control you have over the loop. There is deliberately
none on this branch. Do not write it from scratch - let Claude Code write the first draft
and then turn it into rules.

**Step 1 - generate it.**

```text
/init
```

`/init` reads the repo and writes a `CLAUDE.md` that describes what it found: the stack,
the layout, how to build and test. That is a description, not a set of rules - which is
exactly the gap you close in step 3.

**Step 2 - adopt the repo convention.** This project keeps its rules in `AGENTS.md` and
leaves `CLAUDE.md` as a one-line pointer, so every tool in the room reads the same file.

```bash
mv CLAUDE.md AGENTS.md
printf '@AGENTS.md\n' > CLAUDE.md
```

`copilot-instructions.md`, `CLAUDE.md` and `AGENTS.md` are the same idea in three tools.
Pick one per repo and point the others at it.

**Step 3 - turn the description into rules.** Read what `/init` produced and add what it
cannot know. These three blocks are the minimum, because each one changes what the agent
does:

```markdown
## Coding Standards
- Records for value types, no Lombok
- Constructor injection only, never field injection
- Tests use @WebMvcTest(TheController.class) and inject MockMvc
- Test names read as a sentence: postTaskReturnsCreated

## Constraints
- DO NOT add a dependency to pom.xml without saying so first
- DO NOT put business logic in a controller
- Every new endpoint MUST have at least one MockMvc test

## Git rules
- Commit before every non-trivial task
- Commit as soon as a slice runs green
- No amend on an accepted commit
- No force-push
```

**Step 4 - check that it took effect.** Ask something the agent can only answer from the
file:

```text
Which test naming convention does this project use, and what do you have to ask me
about before you do it?
```

It should name the sentence-style test names and the dependency rule without being told.

*If it does not:* the file is in the wrong place, or the session started before you wrote
it. Restart the session and ask again.

**Take this to your team**

| | In this lab | In your repo |
|---|---|---|
| How it starts | `/init` writes the first draft | Same - run it once per repo, then curate. Never hand-write from nothing |
| What goes in | four rule blocks that change behaviour | Only rules the agent cannot infer: your conventions, forbidden paths, the dependency rule, your git rules |
| Where it lives | committed at the repo root | Committed and reviewed in pull requests like code. It is configuration, not a note |
| Which file | `AGENTS.md` plus a `CLAUDE.md` pointer | Pick one name per repo and point the others at it, so Copilot, Claude Code and the rest read the same rules |

**Tip.** The test for every line: what would the agent do differently because of it? A
line that fails that test is costing you tokens on every single turn. Check the size with
`/context`.

**Trap.** Teams write a 400-line context file, feel organised, and pay for it on every
request. Short and enforced beats long and ignored.

**Reference.** [Claude Code commands](https://code.claude.com/docs/en/commands) ·
[skills and context](https://code.claude.com/docs/en/skills)

## Task 3 - The first controlled loop (10 min)

Have the task API built: create a task and list all tasks. In memory, no database.

Work the five steps in order. The order is the lesson.

**Step 1 - write the task with an explicit non-scope.** Start from this text:

```text
Add two endpoints to trackit, following the pattern in HealthController:
- POST /api/v1/tasks takes title and project, stores the task, returns 201 and the task
- GET /api/v1/tasks returns all stored tasks

A task has id, title, project and status. New tasks are OPEN.

In scope: an in-memory store in the service layer, a record for the task, a request DTO
with validation, one MockMvc test per endpoint.
Not in scope: a database, a frontend, authentication, updating or deleting tasks.

Show me your plan before you change any file.
```

**Step 2 - read the plan.** Before you approve, check three things: does it stay in
scope, does it add a dependency, does it follow the layering in your context file?

**Step 3 - approve the run.**

**Step 4 - check the result yourself.**

```bash
cd backend
./mvnw -q test
./mvnw spring-boot:run
```

In a second terminal:

```bash
curl -s -X POST localhost:8080/api/v1/tasks \
  -H 'content-type: application/json' \
  -d '{"title":"Write the context file","project":"trackit"}'

curl -s localhost:8080/api/v1/tasks
```

Expected output, exactly:

```json
201 {"id":1,"title":"Write the context file","project":"trackit","status":"OPEN"}
[{"id":1,"title":"Write the context file","project":"trackit","status":"OPEN"}]
```

An empty title must answer `400`. `./mvnw test` passes. You can explain every file that
was created.

**Step 5 - commit.**

```bash
cd .. && git add . && git commit -m "feat: create and list tasks in memory"
```

That commit is your rollback point for the rest of the day.

**Then look at what it cost.**

```text
/cost
```

Write the figure down. It is the number the module asks you for: the cost of one full
loop on your own repo.

**Write down one moment.** The point where the agent did something you did not ask for: a file it touched, a dependency it added, a step it skipped, or a claim it made without checking. One line is enough. It is yours to keep - the transfer discussion in M4.2 comes back to
it, and it is the most useful thing you take back to your own team.

Compare against the reference when you are done:

```bash
git diff origin/m1-1-solution --stat
```

A different file list is fine. Check one thing: does your version follow the rules you
wrote in `AGENTS.md`? If it does not, the rule was too vague - that is the finding, not
the diff.

**Take this to your team**

| | In this lab | In your repo |
|---|---|---|
| Plan first | "show me your plan before you change any file" | Make it the default for anything non-trivial. For risky changes, the plan is a review artefact, not a formality |
| Non-scope | written into the task text | Keep it. Naming what is *not* in scope is what stops the agent widening the change |
| Definition of done | you run the tests yourself | Put "tests run and pass" into the context file, and enforce it in CI. The agent does not do it unasked |
| Rollback | commit as soon as it is green | Commit cadence per slice. Every green commit is a point you can return to |
| Cost | `/cost` after the run | Measure one real loop on your own repo before you budget for a team |

**Tip.** Read the plan for one thing: what does it touch that you did not ask about? That
is where the scope creep lives, and it is visible in ten seconds.

**Trap.** Approving plans unread is the most common failure in this room and in every
room. It feels like speed and it costs a review cycle later.

**Reference.** [Claude Code commands](https://code.claude.com/docs/en/commands) ·
[costs and usage](https://code.claude.com/docs/en/costs)

## Task 4 - Same task, second model (10 min)

Run task 3 again against a different model through the gateway. **Use the same task
text** - the comparison only holds if the input is identical.

Work on a throwaway copy so your own state stays intact:

```bash
cd .. && git clone -b m1-1-start trackit trackit-b && cd trackit-b
cp ../trackit/.env . && set -a && source .env && set +a
cp ../trackit/AGENTS.md .
opencode
```

Switch the model inside opencode and run your task text again:

```text
/models
```

The models offered are the ones in `GATEWAY_MODELS` in your `.env`. Do one run against a
commercial model and one against an open-weights model. Fill one row per model on the
comparison sheet.

| Criterion | Model A | Model B |
|---|---|---|
| Model name | | |
| Turns until the tests passed | | |
| Followed `AGENTS.md`? | | |
| Invented dependencies | | |
| Cost of the run | | |
| Did you feel in control? | | |

**End of Part 1.** If you are here with time left, go to Part 2. If not, stop - you have
everything the discussion and the afternoon need.

---

**Take this to your team**

| | In this lab | In your repo |
|---|---|---|
| Model choice | two models, same task text | Run the same bake-off on *your* codebase before you standardise. A leaderboard says nothing about your repo |
| Criteria | the sheet: turns, adherence, invented dependencies, cost | Keep your own sheet. Iterations and rule adherence predict review load; wall-clock time does not |
| Access | one gateway key per person, budget capped | A gateway instead of individual subscriptions gives you cost visibility, model choice and one place to revoke |
| Fair comparison | identical prompt for every model | Same rule. The moment someone tunes the prompt per model, the comparison is worthless |

**Tip.** Try the deliberately small model on mechanical work - a rename, a test stub, a
format pass. Keep the large model for planning. Decide by task class, not by preference.

**Trap.** "The cheap model is worse" is usually "the cheap model needed a clearer task".
Note *where* it broke before you conclude anything.

**Reference.** [opencode providers](https://opencode.ai/docs/providers/) ·
[opencode configuration](https://opencode.ai/docs/config/)

# Part 2 - ADVANCED

**Optional.** Start only when Part 1 runs green and your commit is in place. Nothing
later in the day depends on this part.

Each task deepens one task from Part 1. Pick the ones that interest you; they are
independent of each other.

## Task A1 - ADVANCED - Two harnesses on one repo

*Deepens task 1.*

Start opencode on the same repo in a second terminal, alongside your Claude Code
session. Both read the same `.env`.

```bash
opencode
```

Then answer, in one line each: what does each session know that the other does not, and
what happens if both edit the same file.

**Take this to your team**

Two sessions is a habit, not a feature: one drives the change you are committing, the
other explores or reads. What the exploring session learns never pollutes the one you
ship from.

**Trap.** Two agents editing the same file will fight. Give each one its own git worktree
before you run them in parallel, and never point two sessions at the same working tree.

**Reference.** [Claude Code commands](https://code.claude.com/docs/en/commands)

## Task A2 - ADVANCED - Derive the context file from the code

*Deepens task 2.*

Throw away the template block from task 2 and write `AGENTS.md` from what is actually
in the repo. Read `HealthController`, `docs/architecture.md` and
`docs/adr/0001-layered-spring-architecture.md` first.

Then answer: which of your rules would the agent have followed anyway, and which one
actually changes its behaviour? That second answer is the only part of a context file
that earns its tokens.

**Also build the context in layers** instead of one file: project rules in `AGENTS.md`,
test conventions in a second context file inside the test directory, plus a scratch file
for findings during the session. Then run `/context` and say which of these files
is sent on every turn, and what that costs you.

**Take this to your team**

Layers are how a context file stays short: repo-wide rules at the root, specifics next to
the code they govern, and a scratch file for what you learn during a session. In a
monorepo that is the difference between a usable file and an unreadable one.

**Tip.** The question from this task is the one to ask at every review: which of these
rules would the agent have followed anyway? Delete those.

**Trap.** Every layer is sent on every turn. `/context` tells you what you are paying.

**Reference.** [skills and context](https://code.claude.com/docs/en/skills) ·
[Claude Code commands](https://code.claude.com/docs/en/commands)

## Task A3 - ADVANCED - Plan and execute, strictly separated

*Deepens task 3.*

Do the feature again on a fresh clone, and this time:

1. Write the task text yourself, without the template.
2. Have it plan in one turn. Do not let it execute. Judge the plan.
3. Restrict the tool permissions to what this task actually needs, with
   `/permissions` - deny what the task does not require.
4. Execute in a new turn.
5. When it is done, ask:

```text
Where were you uncertain in this task, and what did you guess?
```

Compare the two runs: did the strict separation change the result, or only your
confidence in it?

**Take this to your team**

Permission rules belong in the repository, not in each developer's head. Committed rules
mean the whole team gets the same deny list, and a new joiner inherits it on clone.

**Tip.** Build the deny list from what went wrong, not from imagination. One real
incident is worth twenty hypothetical rules.

**Trap.** A permission dialog is a prompt, and prompts get clicked through. What actually
stops a command is a hook that refuses it - that is M3, and it is the difference between
"the agent should not" and "the agent cannot".

**Reference.** [permissions](https://code.claude.com/docs/en/permissions) ·
[hooks](https://code.claude.com/docs/en/hooks) ·
[subagents](https://code.claude.com/docs/en/sub-agents)

## Task A4 - ADVANCED - Three models, and where the small one breaks

*Deepens task 4.*

Run a third model, deliberately under 20 GB. Then name the step in the loop where it
breaks. Tick one on the comparison sheet:

- Tool choice - picked the wrong tool, or none
- Context adherence - ignored `AGENTS.md`
- Error reading - misread the test output or the exit code
- Knowing when to stop - stopped while red, or would not stop

That answer is worth more than the timings, and it is the one the room wants to hear.

---

**Take this to your team**

A small local model is the answer to a question several people in this room have: code
that may not leave the company. It does not have to be as good as the hosted model - it
has to be good enough for the task class you give it.

**Tip.** Judge a local model on iterations to green, not on speed. The measured numbers
behind the module slide are in the incratec proof-of-concept: three open-weights models,
14 to 42 GB, all reached green on a bounded task with tests, and the 16 GB class was the
practical entry point.

**Trap.** The same run showed the task was too easy to rank the three models. Do not
generalise from one bounded task to "local models are fine" - or to the opposite.

**Reference.** [opencode providers](https://opencode.ai/docs/providers/) ·
incratec measurement, `research/2026-08-26_opencode-local-models-poc/RESULTS.md`

## Bring to the discussion

Five minutes, one question, so have your answer ready in a sentence:

- **What did the smaller model do differently, and where exactly did it break?**

Three more are worth answering for yourself. They come back in M3 and in the transfer
discussion after lunch:

- The point where your loop got away from you
- Whether you approved a plan you had not really read
- Whether you have code that must not go to a hosted model, and what you do today

## Further reading

- Claude Code settings and context files: <https://code.claude.com/docs/en/settings>
- opencode configuration and model switching: <https://opencode.ai/docs/config/>
- This repo's own decisions: `docs/architecture.md`, `docs/adr/0001-*`
