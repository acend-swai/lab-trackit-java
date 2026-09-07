# Lab 1.1: Your first controlled loop

| Info | Detail |
|---|---|
| Module | M1.1 - Agentic loop, harness, models |
| Duration | 40 minutes |
| Harness | Claude Code on Opus, and OpenCode against OpenRouter in task 5 |
| Stack | Java 21, Spring Boot 3.5, Maven wrapper. Your own stack works too |
| Repo | `lab-trackit-java`, branch `m1-1-start` |
| Target state | create and list a task, in memory (branch `m1-1-solution`) |

TrackIt is a small task management tool. A task has a title, a project and a status. In
this lab we are going to build the task API, run the same job against different setups,
and compare what comes back.

`m1-1-start` ships one endpoint, `GET /api/v1/health`. That is the pattern the agent
copies, so read it before you generate anything.

**Part 1 is for everyone.** Setup plus six tasks, about 40 minutes. Tasks 1 and 2 are the
core: one controlled loop, then reading what it produced. Task 5 has to happen too, it fills
the comparison sheet the module discussion runs on.

**Part 2 is advanced and optional.** Start it when Part 1 is green. Nothing later in the
day depends on it.

## Where you start

Do this before task 0. It takes about three minutes.

**Warning.** Clone in full. A `--depth` clone has no `origin/m1-1-solution` for task 2 to
compare against, and no `origin/m2-start` for lab 2 to fall back to.

Clone the repo and land on the lab branch:

```bash
git clone -b m1-1-start https://github.com/acend-swai/lab-trackit-java.git trackit
cd trackit
```

You now have a `trackit` folder holding the repo. `git branch --show-current` reads
`m1-1-start`, and the remote list holds more than one branch:

```bash
git branch --show-current      # m1-1-start
git branch -r | wc -l          # more than one
```

Open the folder in VS Code and choose **Reopen in Container**. The devcontainer brings
Java 21, both CLIs and the tooling for the rest of the day.

**Note.** Any IDE with devcontainer support works. You can also work directly on your
machine, without the devcontainer and without Docker.

Create the `.env` in the repo root from the template, fill in the keys from your mail, then
check the machine:

```bash
cp .env.example .env            # then fill in the keys from your mail
set -a; source .env; set +a     # only needed outside the devcontainer
./verify.sh
```

Every line reads `[OK]`. The health check at the end reads `[MISSING]`, because it only
answers while the application runs. `OPENROUTER_API_KEY not exported` means you skipped the
`source` line. In the devcontainer, every new terminal sources `.env` for you.

Mark your starting point, so you can always get back to it:

```bash
git commit --allow-empty -m "chore: start of my workshop repo"
```

`git log --oneline -1` shows that commit at the top of your history.

### Keep your clone

This clone is yours. Work in it, commit into it, break it. You have read access and nothing
you do reaches the workshop repo. To keep the work after today, push it to an empty repo of your own, under a branch name of your own:

```bash
git remote add mine <your repo>
git push -u mine m1-1-start:my-workshop
```

`git remote -v` shows `mine` next to `origin`, and the branch `my-workshop` shows up on your own remote.

### Bring your own stack

Everything except the Maven commands works on any repo you bring. Do the same setup there:
check the toolchain is present, run the tests, commit a clean starting point. You get more
out of the day comparing models on code you know.

## Log in to Claude Code

**Warning.** A key in `ANTHROPIC_API_KEY` overrides your subscription and bills that key. On
your own licence, leave `ANTHROPIC_API_KEY` empty and log in with your Anthropic account.

Claude Code talks to the Anthropic API directly, with no gateway in front of it, so the
credential it finds is the one it bills. Task 0 starts your first session, so settle this now.



## What you record today (Advanced)

Two things travel with you out of this lab. Set them up now, before task 0.

We compare how the models handle the same workload, so the numbers only mean something if
you write them down while you work. The suggested models are a starting point, swap in your
own if you would rather measure those.

**1. The comparison sheet.** Copy this into a scratch file. You fill one column per model
you run today, Opus in task 1 and two more in task 5. The five-minute discussion at the end
of the module runs on it, so bring it filled in.

| Criterion | Model 1 | Model 2 | Model 3 | Model 4 |
|---|---|---|---|---|
| Model name | | | | |
| Corrections the plan needed | | | | |
| Turns until the tests passed | | | | |
| Followed `AGENTS.md`? | | | | |
| Invented dependencies | | | | |
| Where it broke: tool choice, context, error reading, stopping | | | | |
| Cost of the run | | | | |
| Did you feel in control? | | | | |

**2. The moments the agent got away from you.** Write one line in the same scratch file
every time you catch one: a file it touched that you did not name, a dependency it added, a
step it skipped, a claim it made without checking. Write it when it happens, not afterwards.
Use the shape:

```text
<task> - <what the agent did> - <how you noticed>
```

For example:

```text
task 1 - added org.json to pom.xml - saw it in the diff before committing
```

You bring these lines to the transfer discussion in M4.2.

## Commands you use today

| Command | What it does |
|---|---|
| `/init` | Scans the repo and writes a `CLAUDE.md` describing it |
| `/cost` | What the session has cost so far. Alias for `/usage` |
| `/context` | What fills the context window right now |
| `/compact` | Summarises the session and frees the window |
| `/permissions` | Allow, ask and deny rules per tool |
| `/model` | Switches the Claude Code model mid-session |
| `/models` | Switches the model in OpenCode |

Type a slash command into the normal prompt. Most queue behind the running turn;
`/model`, `/effort` and `/fast` take effect on the next request.

**Tip:** `/help` lists what your version has. Versions differ, so trust `/help` over this
handout. Reference: [Claude Code commands](https://code.claude.com/docs/en/commands)

## Keys you need

| Key | What it does |
|---|---|
| `Esc` | Interrupts Claude mid-turn and keeps the work so far. Closes a dialog, declines a permission prompt |
| `Esc` `Esc` | On an empty prompt, opens the rewind menu. With text, clears the draft |
| `Shift+Tab` | Cycles the permission mode: manual, accept edits, plan |
| `Ctrl+R` | Searches your command history |

Interrupt a run that goes somewhere you did not ask for. `Ctrl+C` also interrupts, and
twice on an empty prompt it exits Claude Code.

---

# Part 1 - Standard

## Task 0: Let the agent onboard you to the repo (3 min)

You have never seen this codebase. That is the position a new developer is in on their first
day, and it is the cheapest thing an agent does well. Start a session in the repo root:

```bash
claude
```

Ask it to brief you the way a colleague would:

```text
I am new to this repository. Explain the structure, what the application does, where the
HTTP endpoints live, and how I build and test it. Point me at the files by name.
```

It names `HealthController` and the `/api/v1` prefix, the layering under `backend/`, and
`./mvnw test` as the test command. Open one file it named and check the answer against the
code. An onboarding answer you have not verified is a guess you now believe.

**Take home:** Point an agent at an unfamiliar repository before you read it yourself. Ten
minutes of orientation costs a few cents and gives you the file names to read first.

## Task 1: Run the inner loop end to end (12 min)

We build the task API: create a task and list all tasks, in memory. The context file that
ships on this branch stays in place and the model is the strongest one you have, so this run
is the best case. Everything later in the lab is measured against it.

Work the loop one stage at a time: **plan, build, test, run, verify**. An agent that is never
made to close the loop reports done on red.

### Step 1: Plan

Start a session in the repo root:

```bash
claude
```

Check which model you are on, and switch to Opus if you are not:

```text
/model
```

The picker marks the active model. Pick Opus for this run. It is the default on the
subscription plans, and the run you compare everything else against has to be the strong one.

Type this at the prompt. It names the scope, the non-scope, and asks for a plan first:

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

Check the plan for three things: does it stay in scope, does it add a dependency, does it
follow the layering in `AGENTS.md`?

### Step 2: Correct the plan before it runs

The plan is the cheapest place to change the result. Fixing it here costs one turn, fixing
the code afterwards costs a review cycle. So do not accept a plan you would not approve in a
pull request.

Look for the four things that go wrong most often:

| What you find | What you send back |
|---|---|
| A step you did not ask for, a field, an endpoint, a config change | Name it and say to drop it |
| A new entry in `pom.xml` | Ask what it is for and whether the existing dependencies do it |
| A layer missing or merged, storage in the controller | Name the layer it belongs in |
| No test, or one test for both endpoints | Ask for one MockMvc test per endpoint |

Check the result and let Claude fix any problems using this structure:

Select **Tell Claude what to change** 

Enter your corrections into the input field as a prompt. Use a numbered, so Claude applies the list and rewrites the plan. 
This example shows how it should look like - adapt depending on your code base.

```text
Change three things in the plan, then show it again:
1. Drop the update endpoint, it is out of scope
2. Do not add a dependency, spring-boot-starter-validation is already in pom.xml
3. The in-memory list belongs in TaskService, not in TaskController

Do not change any file yet.
```

The agent answers with a revised plan and changes no file. Read it again, and repeat until
nothing is left to correct. Write the number of rounds it took into the comparison sheet,
then move to step 3.

**Note.** A plan that is already right needs no correction. Record zero rounds and move on,
this step takes thirty seconds when the plan is clean.

### Step 3: Build

Approve the plan by typing this. For now - do not just press enter, name what you are approving:

```text
The plan is fine. Implement exactly that, and stop when ./mvnw test passes.
```

Beware: Do not change anything in the file system or hand-patch while it works. A correction mid-run costs you the ability to judge the
result. That is what step 2 was for - hope you fixed the plan properly. ;-)

### Step 4: Confirm it yourself, do not take the agent's word

The agent ran the tests already, that was its stop condition in step 3. Run them once
yourself anyway: an agent that checks its own work tends to confirm itself, and today you
are the independent check. Open a second terminal and leave the Claude session where it is:

```bash
cd backend
./mvnw -q test
```

The output ends in:

```text
BUILD SUCCESS
```

If it is red, copy the failing output back into the Claude session:

```text
./mvnw -q test fails. Here is the output, fix it:

<paste the failure here>
```

### Step 5: Run

A green test suite is not a running application. In the second terminal:

```bash
./mvnw spring-boot:run
```

In a third terminal:

```bash
curl -s -X POST localhost:8080/api/v1/tasks \
  -H 'content-type: application/json' \
  -d '{"title":"Write the context file","project":"trackit"}'

curl -s localhost:8080/api/v1/tasks
```

The POST answers `201` with the created task, and the GET answers with a list holding it:

```json
{"id":1,"title":"Write the context file","project":"trackit","status":"OPEN"}
[{"id":1,"title":"Write the context file","project":"trackit","status":"OPEN"}]
```

Check the validation too. An empty title must answer `400`:

```bash
curl -s -o /dev/null -w '%{http_code}\n' -X POST localhost:8080/api/v1/tasks \
  -H 'content-type: application/json' -d '{"title":"","project":"trackit"}'
```

The output should be:

```text
400
```

A `201` here means the validation annotation is missing, and that is a finding for task 2.

Stop the application with `Ctrl+C`.

**Take home:** Make "show me your plan before you change any file" the default for anything
non-trivial, put "tests run and pass" into the context file, and commit as soon as a slice
is green.

**Trap:** Approving plans unread is the most common failure in every room. It feels like
speed and costs a review cycle later.

Reference: [costs and usage](https://code.claude.com/docs/en/costs)

## Task 2: Read the code the agent wrote (7 min)

Green tests tell you the code runs. They do not tell you what you now own. This is the task
where you find out, because you review this code in a pull request tomorrow.

### Step 1: List what changed

The second terminal is still in `backend/` from task 1, so go back to the repo root first:

```bash
cd .. && git status --short
```

Six new files, all under `backend/src`:

```text
?? backend/src/main/java/ch/acend/trackit/domain/Task.java
?? backend/src/main/java/ch/acend/trackit/domain/TaskStatus.java
?? backend/src/main/java/ch/acend/trackit/dto/CreateTaskRequest.java
?? backend/src/main/java/ch/acend/trackit/service/TaskService.java
?? backend/src/main/java/ch/acend/trackit/web/TaskController.java
?? backend/src/test/java/ch/acend/trackit/web/TaskControllerTest.java
```

A different file list is not a failure. A missing layer is. `pom.xml` in that list is a new
dependency the agent did not announce, and that is a finding for your scratch file.

### Step 2: Know what each file is for

The four layers come from `AGENTS.md`, and the agent followed them because they were written
down. This is what a correct result looks like:

| File | Layer | What it must contain |
|---|---|---|
| `domain/Task.java` | domain | A record with id, title, project, status. No Spring annotations |
| `domain/TaskStatus.java` | domain | An enum, `OPEN` and `DONE` |
| `dto/CreateTaskRequest.java` | dto | A record with title and project, `@NotBlank` on both |
| `service/TaskService.java` | service | `@Service`, the in-memory list, id counter, `create` and `findAll`. No HTTP types |
| `web/TaskController.java` | web | `@RestController`, `/api/v1/tasks`, constructor injection, no logic |
| `web/TaskControllerTest.java` | test | `@WebMvcTest(TaskController.class)` with `MockMvc`, one test per endpoint |

### Step 3: Read the controller against the rules

Open `backend/src/main/java/ch/acend/trackit/web/TaskController.java`. Four things decide
whether it is right, and each one is a rule in `AGENTS.md`:

- The dependency arrives through the constructor, not through `@Autowired` on a field
- The POST method carries `@Valid` on the request body, or the empty title never answers 400
- The method returns the domain `Task`, never `CreateTaskRequest`
- There is no storage and no business logic in the file, only delegation to the service

Two things you may notice are not defects. The POST returns no `Location` header, because
nothing was in scope for it to point at, and the 400 carries Spring's default error body,
because no error shape was asked for. Both are the agent staying inside the scope you set.
Write down anything else you cannot place.

Ask the session about anything you cannot place:

```text
Why does TaskController return Task and not CreateTaskRequest, and where is the rule that
says so?
```

It points at the `dto` rule in `AGENTS.md`. An answer that cites nothing is a guess.

### Step 4: Explain the test yourself

Open `backend/src/test/java/ch/acend/trackit/web/TaskControllerTest.java` and answer one
question out loud: how does the test give the controller a `TaskService`? `@WebMvcTest`
loads the web layer alone, so the service is either mocked or imported explicitly. Both are
correct, and they test different things. Find which one your run chose.

### Step 5: Commit and read the cost

You have read the code, so commit it:

```bash
git add . && git commit -m "feat: create and list tasks in memory"
```

The output names the branch and counts the files:

```text
[m1-1-start 1a2b3c4] feat: create and list tasks in memory
 6 files changed, 180 insertions(+)
```

The hash and the insertion count are yours, not these. Check the file count.

That commit is your rollback point for the rest of the day. Now read what the loop cost, in
the Claude session:

```text
/cost
```

Write the figure into the comparison sheet. That is the cost of one full loop on your own
repo, and the module asks you for it.

Then compare against the reference:

```bash
git diff origin/m1-1-solution --stat
```

The stat shows one line per file that differs from the reference solution, plus a summary
line. Check one thing: does your version follow the rules in `AGENTS.md`? If not, the rule
was too vague. That is the finding, not the diff.

**This is a good moment for the second thing you record.** If the agent did something you
did not ask for during this loop, write that line down now.

**Take home:** Review generated code by layer, not line by line. Ask which file is missing
and which file should not be there. That catches the mistakes that matter in a review.

**Trap:** Code you cannot explain is code you cannot maintain. Green tests are not a reason
to skip reading it, they are a reason you have time to.

## Task 3: Take the context file away (5 min)

Task 1 ran with `AGENTS.md` in place and the strongest model available. Now we remove the
grounding and keep everything else, so the only variable is the context file.

### Step 1: Get back to the starting point

```bash
git checkout -- . && git clean -fd
```

`git status` shows a clean tree, and your commit from task 2 is still in the log.

### Step 2: Move the context file aside

```bash
mv AGENTS.md AGENTS.md.off
mv CLAUDE.md CLAUDE.md.off
claude
```

`CLAUDE.md` is one line, `@AGENTS.md`, so both have to go or Claude Code still reads the
rules.

### Step 3: Run the same job

Paste this. Same job, no context:

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

**Warning.** Do not correct this plan the way you did in task 1, step 2. A corrected plan
measures your review, not the missing context file. Approve whatever it proposes and let it
run.

### Step 4: Compare against what you read in task 2

Run `git status --short` again and hold it against the six files from task 2. Look for the
things `AGENTS.md` decided and the code alone does not say:

- Are the four layers still there, or did domain, dto and service collapse into one file?
- Field injection or constructor injection?
- Is there a test at all, and is it named as a sentence?
- Did a dependency appear in `pom.xml`?

Write the differences down, do not correct them. Then put the context file back and throw
the run away, in that order, because `git clean -fd` removes `AGENTS.md.off`:

```bash
mv AGENTS.md.off AGENTS.md && mv CLAUDE.md.off CLAUDE.md
git checkout -- . && git clean -fd
```

`ls AGENTS* CLAUDE*` shows the two files back without the `.off` suffix.

**Take home:** Run grounded against ungrounded on your own repo before you judge any model.
Most "the model is bad" verdicts are missing context, not missing capability.

**Tip:** A pre-check like `verify.sh` that names which line failed turns a 20-minute
debugging conversation into one sentence. Write one for your repo and check the agent
prerequisites, not just the app.

## Task 4: Write the context file yourself (6 min)

Tasks 1 and 3 showed what the shipped `AGENTS.md` is worth. **Nobody hands you that file in
your own repo**, so this is the task where you produce one: generate a draft with `/init`, put
it where every tool will find it, and turn the description into rules.

### Step 1: Put the shipped file aside

You compare against it in step 4, so keep it. `CLAUDE.md` goes too, it is only a pointer at
the file you just moved:

```bash
mv AGENTS.md AGENTS.reference.md
rm CLAUDE.md
```

The repo now has no context file, which is the state your own repo is in today.

### Step 2: Generate the draft

```text
/init
```

`/init` reads the repo and writes a `CLAUDE.md` with the stack, the layout, and how to build
and test. That is a description of what it found, not a set of rules.

### Step 3: Move it to AGENTS.md and leave a pointer

Claude Code reads `CLAUDE.md`, Copilot reads `copilot-instructions.md`, OpenCode reads
`AGENTS.md`. They are the same idea under three names, and keeping three copies means three
files drifting apart. This project keeps the rules in `AGENTS.md` and makes `CLAUDE.md` a
one-line pointer at it, so every tool in the room reads the same file and there is one file
to review:

```bash
mv CLAUDE.md AGENTS.md
printf '@AGENTS.md\n' > CLAUDE.md
```

Check it:

```bash
cat CLAUDE.md
```

The output should be:

```text
@AGENTS.md
```

### Step 4: Turn the description into rules

Add what `/init` cannot know. These three blocks are the minimum, because each one changes
what the agent does:

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

Now compare with the file you set aside:

```bash
diff AGENTS.reference.md AGENTS.md
```

`diff` prints the lines that differ, the shipped file's marked `<` and yours marked `>`. Take
anything from it that would change what the agent does, ignore the rest, then drop the file:

```bash
rm AGENTS.reference.md
```

`rm` prints nothing, and `ls AGENTS*` now shows `AGENTS.md` alone.

### Step 5: Check that it took effect

Ask something the agent can only answer from the file:

```text
Which test naming convention does this project use, and what do you have to ask me
about before you do it?
```

It names the sentence-style test names and the dependency rule. If it does not, the file is
in the wrong place or the session started before you wrote it. Restart and ask again.

**Take home:** Run `/init` once per repo to get the draft, then curate it by hand. Only keep
rules the agent cannot infer: your conventions, forbidden paths, the dependency rule, your
git rules. It is configuration, so commit it and review it in pull requests like code.

**Tip:** Test every line with one question: what would the agent do differently because of
it? A line that fails that test costs you tokens on every turn. Check the size with
`/context`.

**Trap:** A 400-line context file feels organised and gets ignored. Short and enforced beats
long and unread.

Reference: [skills and context](https://code.claude.com/docs/en/skills)

## Task 5: Run the same job on other models (9 min)

We run task 1 again against different models through the gateway. Use the same job text, the
comparison only holds if the input is identical.

### Step 1: Start from a clean clone

Clone the branch again so the second run starts where the first one did:

```bash
cd ..
git clone -b m1-1-start https://github.com/acend-swai/lab-trackit-java.git trackit-b
cd trackit-b
cp ../trackit/.env . && set -a && source .env && set +a
opencode
```

You see the OpenCode prompt in a second clone, `trackit-b`, that holds none of your task 1
work. `AGENTS.md` ships on the branch, so there is nothing to copy over.

### Step 2: Pick the model

```text
/models
```

The models on offer are the ones in `GATEWAY_MODELS` in your `.env`. Take a commercial one
for this run.

### Step 3: Run the same job

Paste this, unchanged from task 1:

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

**Warning.** Correct this plan only as much as you corrected the one in task 1, and note how
many corrections each model needed. Corrections you make on one model and not the other are
the fastest way to a comparison that means nothing.

### Step 4: Check the result yourself

In a second terminal:

```bash
cd backend && ./mvnw -q test
```

The output ends in:

```text
BUILD SUCCESS
```

Count the turns it took to get there and fill in the column. Then hold the result against
the six files you read in task 2. The layers are the check, not the prose.

### Step 5: Do it again on an open-weights model

Throw the run away and repeat steps 2 to 4, this time picking an open-weights model:

```bash
git checkout -- . && git clean -fd
opencode
```

`git status` shows a clean tree before the third run starts. Type `/models` and pick:

| Model id | What it is | 4-bit footprint |
|---|---|---|
| `moonshotai/kimi-k3` | frontier MoE, open weights | far beyond a workstation |
| `qwen/qwen3-coder-next` | 80B MoE, 3B active, 262k context | about 46 GB |

Both are open weights, but only one of them runs on hardware you might own, so the variable
is how much model the loop can afford when the repository may not leave the building.
`opencode.json` in the repo root lists both and reads your key from the environment.

Do not judge which answer is prettier. Find where the smaller model breaks:

- Tool selection: did it pick the right tool for the step?
- `AGENTS.md`: did it stick to the standards or drift?
- Error output: did it act on the failure or repeat itself?
- Stopping: did it stop while red, or never stop?

**Take home:** Run this bake-off on your own codebase before you standardise on a model. A
leaderboard says nothing about your repo. Judge on turns to green and rule adherence, not
on wall-clock time.

**Tip:** Give the small model mechanical work, a rename, a test stub, a format pass. Keep
the large one for planning. Decide by task class, not by preference.

**Trap:** "The cheap model is worse" is usually "the cheap model needed a clearer task".
Note where it broke before you conclude anything.

Reference: [OpenCode providers](https://opencode.ai/docs/providers/)

**End of Part 1.** Go to Part 2 if you have time. If not, stop, you have everything the
discussion and the afternoon need.

---

# Part 2 - ADVANCED

Optional. Start when `./mvnw -q test` ends in `BUILD SUCCESS` and `git status` shows a clean
tree. The tasks are independent, pick what interests you.

## Task A1 - ADVANCED: Run two harnesses on one repo

*Deepens task 5.* Start OpenCode on the same repo in a second terminal, next to your
Claude Code session. Both read the same `.env`:

```bash
opencode
```

Answer in one line each: what does each session know that the other does not, and what
happens if both edit the same file?

**Take home:** One session drives the change you commit, the other explores. What the
exploring session learns never pollutes the one you ship from.

**Trap:** Two agents editing the same file will fight. Give each one its own git worktree
first, and never point two sessions at the same working tree.

## Task A2 - ADVANCED: Derive the context file from the code

*Deepens task 4.* Throw away the template from task 4 and write `AGENTS.md` from what is
actually in the repo. Read `HealthController`, `docs/architecture.md` and
`docs/adr/0001-layered-spring-architecture.md` first.

Then build the context in layers instead of one file: project rules in `AGENTS.md`, test
conventions in a second context file inside the test directory, plus a scratch file for
findings during the session. Run `/context` and say which files are sent on every turn and
what that costs.

Answer: which of your rules would the agent have followed anyway? Those are the ones to
delete.

**Take home:** Layers keep a context file short: repo-wide rules at the root, specifics
next to the code they govern. In a monorepo that is the difference between a usable file
and an unreadable one.

**Trap:** Every layer is sent on every turn. `/context` tells you what you are paying.

## Task A3 - ADVANCED: Plan and execute, strictly separated

*Deepens task 1.* Do the feature again on a fresh clone:

1. Write the job text yourself, without the template.
2. Have it plan in one turn. Do not let it execute. Judge the plan.
3. Restrict the tool permissions with `/permissions`, deny what this task does not need.
4. Execute in a new turn.
5. Ask: `Where were you uncertain in this task, and what did you guess?`

Compare the two runs: did the separation change the result, or only your confidence in it?

**Take home:** Permission rules belong in the repository, not in each developer's head.
Committed rules mean a new joiner inherits the deny list on clone. Build the list from
what went wrong, not from imagination.

**Trap:** A permission dialog is a prompt, and prompts get clicked through. What actually
stops a command is a hook that refuses it. That is M3.

References: [permissions](https://code.claude.com/docs/en/permissions) ·
[hooks](https://code.claude.com/docs/en/hooks) ·
[subagents](https://code.claude.com/docs/en/sub-agents)

## Task A4 - ADVANCED: Find where the small model breaks

*Deepens task 5.* Run a third model, deliberately under 20 GB. Then name the step in the
loop where it breaks and tick one:

- Tool choice: picked the wrong tool, or none
- Context adherence: ignored `AGENTS.md`
- Error reading: misread the test output or the exit code
- Stopping: stopped while red, or would not stop

**Take home:** A small local model answers a real question in this room: code that may not
leave the company. It does not have to match the hosted model, it has to be good enough
for the task class you give it. Judge on turns to green, not speed.

**Tip:** The measured numbers behind the module slide are in the incratec proof of concept:
three open-weights models, 14 to 42 GB, all reached green on a bounded task with tests,
and the 16 GB class was the practical entry point. See
`research/2026-08-26_opencode-local-models-poc/RESULTS.md`.

**Trap:** The same run showed the task was too easy to rank the three models. Do not
generalise from one bounded task to "local models are fine", or to the opposite.

---

## Bring to the discussion

Five minutes, one question, so have the answer ready in a sentence:

- **What did the smaller model do differently, and where exactly did it break?**

Three more are worth answering for yourself. They come back in M3 and after lunch:

- The point where your loop got away from you
- Whether you approved a plan you had not really read
- Whether you have code that must not go to a hosted model, and what you do about it today

## Further reading

- Claude Code settings: <https://code.claude.com/docs/en/settings>
- Claude Code commands: <https://code.claude.com/docs/en/commands>
- OpenCode configuration: <https://opencode.ai/docs/config/>
- This repo's decisions: `docs/architecture.md`, `docs/adr/0001-*`
