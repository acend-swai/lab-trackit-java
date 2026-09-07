# Lab 1.2: Give the agent your patterns, and let it build two subsystems

| Info | Detail |
|---|---|
| Module | M1.2 - Extending and scoping the agent: skills, agents, plugins, MCP |
| Duration | 40 minutes in two halves, 25 and 15, with the MCP input between them |
| Harness | Claude Code |
| Stack | Java 21, Spring Boot 3.5 and Maven in `backend/`. Vue 3, Vite and TypeScript in `frontend/`. PostgreSQL 17 from `compose.yaml` |
| Repo | `lab-trackit-java`, branch `m1-2-start` |
| Target state | tasks stored in PostgreSQL, task board in the browser (branch `m1-2-solution`) |

Today TrackIt keeps its tasks in memory and has no screen. By the end of this lab a task
survives a restart and you can add one in a browser.

We are not going to write either subsystem. The branch ships two **skills**, short files
that describe how this project does persistence and how it does screens. You give Claude
Code the job, the right skill fires by itself, and your work is to check what came out.

| Mechanism | What it is | Where you meet it |
|---|---|---|
| Skill | a written working instruction: how something is done here | Part 1, given to you |
| Agent | a worker with its own context, model and limits | Part 1 given, Part 3 you write one |
| Plugin | how a skill or agent travels between repos and teams | Part 2, you install one |
| MCP | a connection to something outside this repo | Part 2, one command |

## Which parts you do

Parts 1 and 2 are for everyone. Part 1 runs before the MCP input, Part 2 after it. You
write no skill, agent or configuration file in either.

Part 3 is advanced and optional. Nothing later in the day depends on it. If you finish
Part 1 early, go to task A2, it is the most useful one.

## What you record today

The fifteen-minute discussion at the end runs on your answers, and every one of them is
something you can only see while you work. Keep a scratch file open and write the line when
it happens:

| From | Write down |
|---|---|
| Task 2 | Did the skill fire on the first try? If not, what did its description say? |
| Task 3 | What did the tests tell you, and what did they not tell you? |
| Task 5 | What the plugin's "Will install" pane listed, and whether you would put that plugin in your team's `.claude/settings.json` |
| Task 7 | Your four answers per component, plus the verdict line |

## Return to your own clone

Lab 1.1 task 5 moved you into the second clone, `trackit-b`. Check where you are, and go
back to your own clone if that is where you ended up:

```bash
pwd                    # if this ends in /trackit-b, run the next line
cd ../trackit
git status --porcelain
```

`pwd` ends in `/trackit`, and `git status --porcelain` prints nothing.

**Warning.** If `git status --porcelain` prints a line, deal with it before you continue.
`git checkout` refuses to switch branches over uncommitted work:

```bash
git add -A && git commit -m "chore: end of lab 1.1"
```

## Check out the branch that ships the skills

Fetch the branch and land on it:

```bash
git fetch origin
git checkout -b m1-2-start origin/m1-2-start
```

`git branch --show-current` prints:

```text
m1-2-start
```

**Note.** If you added a second remote in lab 1.1 and it carries the same branch names, a
plain `git checkout m1-2-start` fails with `matched multiple (2) remote tracking branches`.
The line above names the remote, so it works either way. If the branch already exists
locally, drop the `-b` and the `origin/m1-2-start`.

**Note.** You do not need your lab 1.1 result here. `m1-2-start` is the lab 1.1 solution
with new scaffolding on top.

## Rebuild the devcontainer, then verify

The database and the frontend arrive with this branch, so the container you built in lab
1.1 does not have them yet. Run the check to see that:

```bash
./verify.sh
```

**Expect this first run to report `[MISSING]`.** These two lines are the ones that matter:

```text
[MISSING] docker - lab 1.2 needs it to start the database
[MISSING] frontend dependencies - run: cd frontend && npm ci
```

Rebuild the devcontainer from the command palette, *Dev Containers: Rebuild Container*. The
rebuild reads this branch's `.devcontainer/`, which adds the docker CLI, pulls `postgres:17`
and runs `npm ci` in `frontend/`. It takes a few minutes and you only do it once.

Then open a **new** terminal and run the check again:

```bash
./verify.sh
```

Every line now reads `[OK]` except the last one, the health endpoint, which only answers
while the application runs. These four are the ones the rebuild fixed:

```text
[OK]      docker (Docker version 27.3.1, build ce12230)
[OK]      postgres:17 image present
[OK]      database container healthy
[OK]      frontend dependencies installed
```

PostgreSQL starts with the devcontainer, so `database container healthy` reads `[OK]`
without you starting anything.

**Note.** Outside the devcontainer you also get `[MISSING] OPENROUTER_API_KEY not
exported`. Fix it the way lab 1.1 did, with `set -a; source .env; set +a`. Nothing in this
lab uses that key, so it is not a reason to stop.

**Note.** There is deliberately no container for the application itself, that is M3. The
database is defined in `compose.yaml`, which M3 builds around.

## What the branch ships

| Path | What it is |
|---|---|
| `.claude/skills/commit-message/SKILL.md` | writes a commit message in the house format |
| `.claude/skills/add-persistence/SKILL.md` | how this project moves storage to PostgreSQL |
| `.claude/skills/add-view/SKILL.md` | how this project adds a screen |
| `.claude/agents/api-reviewer.md` | a read-only reviewer for REST endpoints |
| `frontend/` | the Vue scaffold, dependencies already installed |
| `compose.yaml` | the PostgreSQL service |
| `docs/mcp-candidates.md` | the MCP servers for Part 2, each one checked |

These are files in the repository, committed and reviewed like code. None of them is a
personal setting.

---

# Part 1 - Standard, 25 minutes

## Task 1: Re-ground the harness (4 min)

The repo grew since you wrote `AGENTS.md` in lab 1.1. It has a task API, a frontend
folder, a database and three skills. Your context file describes none of that.

### Step 1: Put the pointer aside

`CLAUDE.md` on this branch is one line, `@AGENTS.md`. Move it away first, because `/init`
suggests improvements to a context file that already exists instead of writing a fresh
description, and a fresh description is what we want to read:

```bash
mv CLAUDE.md CLAUDE.md.off
ls CLAUDE*
```

The output should be:

```text
CLAUDE.md.off
```

### Step 2: See what a fresh reader sees

Start a session in the repo root:

```bash
claude
```

Ask it to describe the repo:

```text
/init
```

`/init` scans the repo and writes a `CLAUDE.md` with the stack, the layout, and how to
build and test. We are not keeping that file, we are reading it.

### Step 3: Compare it with your rules

Put the fresh description next to the rules you wrote:

```bash
diff CLAUDE.md AGENTS.md | head -40
```

`diff` marks lines from `CLAUDE.md` with `<` and lines from `AGENTS.md` with `>`. The output
is long, and it looks like this:

```text
< ## Frontend
< Vue 3 with Vite and TypeScript in `frontend/`, PrimeVue components.
< Dev server: `npm run dev` on port 5173.
---
> ## Coding Standards
> - Records for value types, no Lombok
```

Read the `<` lines. In them you find what `/init` saw and `AGENTS.md` never mentions: the
task API, the `frontend/` folder, the database and the three skills. Those are your gaps.

### Step 4: Put the pointer back

Throw the generated file away and restore the one line, in that order:

```bash
rm CLAUDE.md
mv CLAUDE.md.off CLAUDE.md
cat CLAUDE.md
```

The output should be:

```text
@AGENTS.md
```

You keep the gaps you just read, not the file that showed them to you.

### Step 5: Find the three rules the next tasks are held to

Open `AGENTS.md` and find these three lines. Tasks 3 and 4 check the agent against them:

- The JPA entity is a separate class from the record
- The schema belongs to a Flyway migration, never to `ddl-auto`
- A view calls `api/`, never `axios` directly

**Take home:** Re-run `/init` whenever the repo shape changes. Keep the gaps it found, not
the file it wrote.

**Trap:** Committing the `/init` output over a curated `AGENTS.md`. That overwrites
judgement with description.

Reference: [Claude Code commands](https://code.claude.com/docs/en/commands)

## Task 2: Use a skill and an agent (5 min)

### Step 1: Fire the skill without naming it

Stage the working tree, so there is something to write a message about:

```bash
git add -A
```

`git add` prints nothing. Now ask for a message, in the Claude session:

```text
Write me a commit message for what I just staged.
```

It answers with a message in the house format, `<area>: <what changed>`, and it changes no
file.

You did not name the skill. It fired because its `description` matches what you asked.
Open `.claude/skills/commit-message/SKILL.md` and read that field, it lists the phrasings
it answers to. That field is the whole trigger mechanism.

Notice what it did not do: it printed a message and stopped. Its frontmatter reads
`disallowed-tools: Write, Edit`, so it could not commit even if it decided to.

### Step 2: Run the agent

Send the same repository to a worker with its own context:

```text
Use the api-reviewer agent to review the task API.
```

It reports one line per finding and closes with a verdict line:

```text
verdict: 0 blocker, 2 should, 1 note
```

Your counts will differ. Read `.claude/agents/api-reviewer.md` while it runs:
`tools: Read, Grep, Glob` and `model: haiku`. It has its own context window, a cheaper
model, and cannot edit or run anything.

### Step 3: Name the difference

Write one line each, for the discussion. Answer them from what you just watched, not from
the definitions at the top of this handout:

- Where did the skill's work happen, and where did the agent's?
- Which of the two came back with a report, and what was in your session afterwards?

**Take home:** `disallowed-tools` in a skill genuinely removes tools, but `allowed-tools`
only pre-approves and restricts nothing. An agent's `tools` list is an allowlist, so an
agent is a real boundary.

**Tip:** When a skill does not fire, fix the description first, not the body. Write
descriptions as the phrasings people actually type.

**Trap:** Do NOT treat a skill as a sandbox. If you need something to be unable to write, use
an agent.

References: [skills](https://code.claude.com/docs/en/skills) ·
[subagents](https://code.claude.com/docs/en/sub-agents)

## Task 3: Put the tasks in the database (8 min)

Read `.claude/skills/add-persistence/SKILL.md` first, it is one page and it is the house
pattern for this job.

### Step 1: Give it the job, and ask for a plan

Type this in the Claude session:

```text
Move task storage out of the in-memory list in TaskService and into PostgreSQL.
The database is already running from compose.yaml.

Show me your plan before you change any file.
```

### Step 2: Check that the skill fired

You did not name the skill, so check the plan for the three things the skill prescribes: an
entity *beside* the record, a Flyway migration, and `ddl-auto: validate`.

If all three are in the plan, the skill fired. Go to Step 3.

Send the plan back only when one of the three is actually missing. A plan that ignores the
skill produces code that ignores it too:

```text
That plan does not follow the add-persistence skill in .claude/skills. Read it and plan
again.
```

**Note.** Sending back a plan that already follows the skill costs you a turn and gets you a
question back, because there is nothing for it to correct. Read the three before you type.

### Step 3: Approve the dependencies by name

It asks you about dependencies, because `AGENTS.md` forbids adding one silently. It needs
`spring-boot-starter-data-jpa`, `flyway-core`, `flyway-database-postgresql` and the
PostgreSQL driver. Read what it asks for, then approve by naming what you are approving:

```text
The plan is fine and those dependencies are fine. Implement exactly that, and stop when
./mvnw test passes.
```

### Step 4: Run the test suite yourself

Terminal 1 is the Claude session. Open a second terminal and run the suite there without
`-q`, because the build result is the line you came to read:

```bash
cd backend
./mvnw test
```

The output ends in a count of the tests and the build result:

```text
[INFO] Results:
[INFO]
[INFO] Tests run: 4, Failures: 0, Errors: 0, Skipped: 0
[INFO]
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
```

Hand the failing output back to the Claude session if it does not.

**Note.** `./mvnw -q test` prints no `BUILD SUCCESS` and no test count. `-q` hides
everything at INFO level, and the build result is an INFO line. Under `-q` a passing run and
a failing run look nearly identical, so use it only where you check the exit code instead.

### Step 5: Start the application against the database

The tests are done, so reuse terminal 2 for the application:

```bash
./mvnw spring-boot:run
```

On the first start Flyway creates the table, and Spring Boot logs a `Started` line once it
is up. These are an excerpt, the rest of the startup log is between them:

```text
o.f.core.internal.command.DbMigrate  : Migrating schema "public" to version "1 - create task table"
o.f.core.internal.command.DbMigrate  : Successfully applied 1 migration to schema "public", now at version v1
ch.acend.trackit.TrackitApplication  : Started TrackitApplication in 1.493 seconds (process running for 1.599)
```

Those two `DbMigrate` lines are the migration doing the work. Hibernate is on
`ddl-auto: validate` and creates nothing, so a run without them has no table.

**Note.** Only the first start migrates. On later starts Flyway finds version 1 already
applied and logs no `Migrating` line, which is correct.

Leave it running in that terminal.

### Step 6: Create a task

In a third terminal:

```bash
curl -s -X POST localhost:8080/api/v1/tasks \
  -H 'content-type: application/json' \
  -d '{"title":"Survive a restart","project":"trackit"}'
```

The output holds a generated id and the title you sent:

```json
{"id":1,"title":"Survive a restart","project":"trackit","status":"OPEN"}
```

Note your id. It is `1` on a fresh database, and higher if you have run this lab before,
because the `pgdata` volume in `compose.yaml` keeps the rows between runs.

### Step 7: Make the check the tests cannot make

Stop the application with `Ctrl+C` in terminal 2, start it again with
`./mvnw spring-boot:run`, and ask for the list from terminal 3:

```bash
curl -s localhost:8080/api/v1/tasks
```

The output is the task you created, returned by a process that started with an empty memory:

```json
[{"id":1,"title":"Survive a restart","project":"trackit","status":"OPEN"}]
```

Look in the database yourself:

```bash
docker exec trackit-db psql -U trackit -d trackit -c 'SELECT * FROM task;'
```

`psql` prints one row per stored task, and yours is among them:

```text
 id |       title       | project | status
----+-------------------+---------+--------
  1 | Survive a restart | trackit | OPEN
(1 row)
```

The id and the row count are yours. Both are higher if the volume already held tasks.

A green test suite proved none of that. The controller test mocks the service away, so the
whole storage path is absent from the run. Persistence is proven by a restart and by
nothing else.

### Step 8: Commit the slice

It survives a restart, so commit it. Stop the application with `Ctrl+C` in terminal 2, then
commit from the repo root:

```bash
cd .. && git add -A && git commit -m "service: store tasks in postgres"
```

`git commit` names the branch and counts the files:

```text
[m1-2-start 4d5e6f7] service: store tasks in postgres
 7 files changed, 214 insertions(+), 11 deletions(-)
```

Seven files: `pom.xml`, the entity, the repository, the migration, `application.yml`, the
service, and the controller test. The hash and the line counts are yours, not these.

### Step 9: Find what it refused to touch

Skip this step if you are short of time, Task 4 needs the full 8 minutes.

The skill forbids annotating the `Task` record, and `AGENTS.md` is outside this job. Both
now contradict the code. Ask the session what it left alone:

```text
Which files did you notice were now wrong, but leave unchanged, and why?
```

It names the javadoc on the `Task` record, `Persistence arrives in M2; for now tasks live in
memory`, and the closing line of the Entity Model section in `AGENTS.md`. Both describe
in-memory storage that you just replaced.

An agent that stops at a boundary it can see past is the behaviour you want. It reported the
inconsistency instead of widening its own scope to fix it. Leave both as they are, M2 covers
them.

**Take home:** For every feature, name the check the test suite cannot make, then make it.
That is your real acceptance criterion.

**Tip:** Anything you have typed into a prompt three times is a skill.

**Trap:** `BUILD SUCCESS` feeling like proof. The suite passes with no database running
at all.

Reference: [skills](https://code.claude.com/docs/en/skills)

## Task 4: Put the tasks on a screen (8 min)

Same shape, other subsystem. Read `.claude/skills/add-view/SKILL.md` first.

### Step 1: Give it the job

```text
Build the task board in the frontend: list all tasks, and add a new one.
Use the existing REST API. Show me your plan before you change any file.
```

### Step 2: Check that the skill fired, then approve

Check the plan for the three things `add-view` prescribes: a typed API module under
`src/api/`, one view per route, and the route registered in `router/index.ts`. Then
approve:

```text
The plan is fine. Implement exactly that, and stop when npx vue-tsc -b exits 0.
```

### Step 3: Check the types yourself

In a third terminal:

```bash
cd frontend
npx vue-tsc -b
echo "exit=$?"
```

`vue-tsc` prints nothing when the types line up, and the exit code is what you check:

```text
exit=0
```

### Step 4: Start the dev server and use the board

```bash
npm run dev
```

Vite prints the address:

```text
  ➜  Local:   http://localhost:5173/
```

With the backend still running, open <http://localhost:5173>, add a task, and see it appear
in the list. Reload the page. The task is still there, because it is in the database now.

### Step 5: Commit the board

Go back to the repo root and commit:

```bash
cd .. && git add -A && git commit -m "web: add the task board"
```

Write down how long the two jobs took in sequence. Task A2 runs the same two jobs at the
same time and asks you to compare.

**Take home:** Have the agent read the real API contract instead of describing it in the
prompt. The prompt goes stale, the code does not.

**Tip:** `npx vue-tsc -b` catches the mismatch between the TypeScript type and the Java
record faster than clicking does.

**Trap:** Trusting a screen that renders. Renders and reads-the-right-data are different
claims.

---

# Part 2 - Standard, 15 minutes

Start this after the MCP input. Both things here come from **outside your repository**: a
plugin somebody else wrote, and a server somebody else runs. Ask the same question of
both: what can it reach, and how do you know before you say yes?

## Task 5: Install a plugin somebody else wrote (5 min)

Most useful skills are not in your repo. They arrive as **plugins** from a marketplace, and
installing one is two keystrokes, which is exactly why the review matters.

### Step 1: Open the plugin manager

Run this in your Claude Code session:

```text
/plugin
```

A pane opens on the marketplace browser. Claude Code registers Anthropic's official
marketplace, `claude-plugins-official`, on its first interactive start, so there is nothing
to add. Cycle the tabs with `Tab`:

| Tab | What it holds |
|---|---|
| Discover | plugins from every marketplace you have added |
| Installed | what you have, and what you can disable or remove |
| Marketplaces | the catalogues themselves |
| Errors | anything that failed to load |

### Step 2: Read the details pane before you install

Go to **Discover** and select **commit-commands**. Do not press install yet. The details
pane is the review surface, and three fields carry the review:

- **Context cost**: what this plugin adds to your context window on *every turn*
- **Last updated**: whether anyone still maintains it
- **Will install**: every command, agent, skill, hook, MCP server and LSP server it brings

Read the "Will install" list out loud to yourself, and write it into your scratch file for
task 7. A plugin runs with your permissions, on your files. This pane is the last moment
saying no costs you nothing.

### Step 3: Install it at user scope

Install it by name, marketplace included:

```text
/plugin install commit-commands@claude-plugins-official
```

Choose **User** scope, so it belongs to you across all projects. If the summary reads
`Run /reload-plugins to activate.`, run that.

### Step 4: Use it

Call the plugin's own command:

```text
/commit-commands:commit
```

It proposes a commit message, the same job the repo's own skill did in task 2.

You now have two ways to write a commit message: the repo's `commit-message` skill, which
fires from its description, and this one, which you call by name. Plugin commands are
namespaced, `/commit-commands:commit`, so an installed plugin can never shadow something
you wrote.

**Take home:** **Project** scope adds the plugin to `.claude/settings.json` and it ships to
everyone who clones. That is a pull-request decision, not a personal one. Check the context
cost too, every installed plugin is paid for on every turn whether you use it or not.

**Tip:** This repo is Java plus TypeScript, so `jdtls-lsp` and `typescript-lsp` would give
Claude real type errors and go-to-definition after every edit. They need the language
server binary installed separately, so set them up at your desk rather than in a 5-minute
lab slot.

**Tip:** The **Installed** tab flags plugins you have not used in two weeks. Uninstall
those, they still cost startup and context.

**Trap:** "It is from a marketplace, so it is safe." The official marketplace is curated by
Anthropic and the community one passes automated screening. Neither is a guarantee about
what the code does on your machine.

References: [discover and install plugins](https://code.claude.com/docs/en/discover-plugins) ·
[plugins](https://code.claude.com/docs/en/plugins)

## Task 6: Connect one MCP server and use it (5 min)

Your session wrote Vue 3 and PrimeVue 4 from what the model remembers, and its memory is
older than the versions in `frontend/package.json`. That gap is the case for MCP: not extra
capability, current information.

### Step 1: Connect the server

One command, from `docs/mcp-candidates.md`, where every entry was run and checked:

```bash
claude mcp add --scope project --transport http context7 https://mcp.context7.com/mcp
```

The output names the server and the scope it landed in:

```text
Added HTTP MCP server context7 with URL: https://mcp.context7.com/mcp to project config
```

`--scope project` writes `.mcp.json` in the repo root. That file is committed, so this is a
team decision, the same distinction you just met with plugin scopes.

### Step 2: Check that it connected

Ask Claude Code what it now holds:

```bash
claude mcp list
```

A project-scope server you have not approved yet reads:

```text
context7: https://mcp.context7.com/mcp (HTTP) - Pending approval
```

Approve it in your interactive session when it asks, then run `claude mcp list` again. It
reads `Connected`. A server arriving through a `git pull` does not connect silently.

### Step 3: Use it on a real question

Ask something the model cannot answer from memory:

```text
Using the context7 docs, check the PrimeVue 4 API used in the task board. Name
anything that is deprecated or renamed in the version in package.json, and quote the
doc line you got it from.
```

The answer quotes a documentation line, and the session shows a `context7` tool call.
Finding no problem is a good outcome, "the code matches the current docs, and here is the
line that says so" is a real answer.

**Note.** The whole room shares one address, so it can rate-limit. Ask the trainer for the
key and add `--header "Authorization: Bearer <key>"` to the command in step 1.

### Step 4: Note where the other servers come from

Three directories carry the servers that are not on our list, and you vet before you add,
not after:

| Directory | What it gives you |
|---|---|
| <https://registry.modelcontextprotocol.io> | the official registry, authoritative server metadata |
| <https://www.pulsemcp.com> | curated and filterable, with an official-provider filter |
| <https://glama.ai/mcp/servers> | a quality, security and licence grade per server, and an in-browser Inspector to exercise one before you install it |

**Take home:** The best MCP cases are current information, not more power. Scope it to the
project, commit it, review it in a pull request, and keep the approval prompt.

**Tip:** Ask for the quoted doc line, not the conclusion. It turns an unverifiable claim
into a citation you can check in five seconds.

**Trap:** Connecting five servers because they all look useful. Tool descriptions sit in
your context every turn. Check with `/context`.

References: [MCP](https://code.claude.com/docs/en/mcp) · `docs/mcp-candidates.md`

## Task 7: Write down what they can reach (5 min)

No configuration here. You brought in a plugin and a server, and this task is the review
you run on both.

### Step 1: Answer four questions per component

Create `docs/mcp-scoping.md` and answer these four for the plugin, then again for the MCP
server:

- **Slice.** Which part of which system does it touch? Not "GitHub", but which
repositories and which resource type. For the plugin: which of your files and which tools.
- **Credential.** Which one does it use, and where does it come from? Your own account, a
service account, none at all?
- **Direction.** Read-only or writing? Is that enforced by the endpoint, or only requested
in a prompt?
- **Maintainer.** Who publishes it, and when did they last touch it? An abandoned server
still runs, and it is nobody's job to patch it.

### Step 2: Tick the three conditions and write a verdict

Three things together make a session dangerous:

- access to private data
- content from an untrusted source entering the context
- a channel to the outside

With all three, content can act as an instruction and data can leave. Removing any one
breaks the chain. Tick the ones present in your session and write one verdict line under
your four answers.

### Step 3: Read what happened when all three lined up

In CamoLeak, hidden instructions in a pull request description were read by GitHub Copilot,
which then read the victim's private repositories under their own permissions and leaked
the content through GitHub's own image proxy. The exfiltration channel was a domain the
organisation already trusted, so monitoring saw ordinary image loads. All three conditions,
and the exit was the one nobody had thought of as an exit.

Source:
<https://www.blackfog.com/camoleak-how-github-copilot-became-an-exfiltration-channel/>

**Take home:** These four questions work for anything you install. They take a minute and
they are the whole review.

**Tip:** Anything nobody can describe in three lines does not get committed.

**Trap:** "It is read-only" because the prompt said so. Read-only is a property of the
endpoint or the database grant, never of a prompt.

References: [MCP](https://code.claude.com/docs/en/mcp) ·
[permissions](https://code.claude.com/docs/en/permissions)

---

# Part 3 - ADVANCED

Optional. Start when `./mvnw -q test` ends in `BUILD SUCCESS` and `git status --porcelain`
prints nothing. The tasks are independent, so do **task A2 first** if you only do one.

## Task A1 - ADVANCED: Write a skill of your own

*Deepens tasks 3 and 4.* Write `add-endpoint`: generate a new REST endpoint in the house
pattern, including the service method, the error handling and a MockMvc test.

### Step 1: Start from this frontmatter

Create `.claude/skills/add-endpoint/SKILL.md` with these lines at the top:

```markdown
---
name: add-endpoint
description: Use when adding a REST endpoint to TrackIt, or when the user says "add an
  endpoint", "expose X over the API" or "new route". Generates controller method,
  service method, error handling and a MockMvc test in the house pattern.
---
```

Those lines are the frontmatter only. The body below it, the steps the skill follows, is
what you write.

### Step 2: Use it on a real endpoint

Then use it to add `GET /api/v1/tasks/{id}`, returning 404 for an unknown id.

Three fields decide whether this works:

| Field | Gets it wrong when | Costs you |
|---|---|---|
| `description` | it summarises instead of listing phrasings | the skill never fires |
| `allowed-tools` | you expect it to restrict | it pre-approves only. Use an agent for a real limit |
| the Rules block | it repeats what the code already shows | tokens on every turn, no behaviour change |

**Take home:** Rules go in `AGENTS.md`, procedures go in a skill. Mixing them makes both
unreadable and a duplicated line drifts in two places at once.

**Tip:** Write the description last, when you know what the skill actually does.

Reference: [skills](https://code.claude.com/docs/en/skills)

## Task A2 - ADVANCED: Run two agents in one turn

*Deepens tasks 3 and 4. Start here if you only do one advanced task.*

In Part 1 you did the database and the frontend one after the other. They are independent
jobs, so we do them at the same time.

### Step 1: Start from the same place

Give the parallel run its own working tree, checked out at the branch you started from:

```bash
git worktree add ../trackit-parallel m1-2-start
cd ../trackit-parallel
```

`git worktree list` now shows a second working tree:

```text
/workspaces/trackit             1a2b3c4 [m1-2-start]
/workspaces/trackit-parallel    1a2b3c4 [m1-2-start]
```

The paths and the hash are yours, not these.

### Step 2: Write two agent definitions

Use `/agents`, or write the files directly. This is `.claude/agents/db-builder.md`:

```markdown
---
name: db-builder
description: Moves TrackIt storage from memory to PostgreSQL. Owns backend/ and
  nothing else. Run it alongside frontend-builder when both subsystems change at once.
tools: Read, Grep, Glob, Edit, Write, Bash
model: sonnet
---

# db-builder

You own the backend. Follow the `add-persistence` skill.

## Your boundary
- Write only under `backend/`
- Never edit frontend/, compose.yaml, .env, AGENTS.md or .claude/
- Never run git commit, git checkout or git stash. The user commits

## Report back, under 15 lines
1. Files created and changed, one line each
2. Dependencies added, with a reason each
3. The result of ./mvnw -q test, quoted, not summarised
4. What you did NOT verify
5. Anything you guessed
```

`frontend-builder` is the mirror image: it owns `frontend/`, may **read** `backend/` to
learn the API shape, follows the `add-view` skill, and quotes `npx vue-tsc -b`.

### Step 3: Understand why this is safe

Both agents run at the same time in the same working tree. That is safe for exactly one
reason: **their file spaces do not overlap.** Take that away and they overwrite each
other's edits with no conflict marker and no error. The tool list is how you enforce it.

### Step 4: Dispatch both in one message

```text
Use the db-builder agent to move task storage into PostgreSQL, and at the same time
use the frontend-builder agent to build the task board.

Run them in parallel. Do not edit any file yourself. When both report back, show me
both reports unchanged.
```

Both run in the background and report as they finish. While they work you are doing
nothing.

### Step 5: Compare against your Part 1 run

Answer two things: how long did it take, and what did you give up? You reviewed two reports
instead of two plans, and you never saw either plan before it ran.

**Take home:** Reach for an agent for parallelism or a fresh context window. "It is
specialised" is not a reason, a skill can be specialised. Make "what did you NOT verify" a
required section of every report.

**Tip:** Two or three high-leverage agents beat fifteen overlapping ones. Every agent is
another definition to keep true as the repo changes.

**Trap:** Two agents in one working tree with overlapping paths. There is no conflict
marker, the second write wins and you find out in review.

Reference: [subagents](https://code.claude.com/docs/en/sub-agents)

## Task A3 - ADVANCED: Make the partition real with worktrees

*Deepens task A2.* In A2 the agents stayed out of each other's way because you told them
to, and an instruction is not a boundary. Give each one its own working tree.

### Step 1: Create one worktree per agent

```bash
git worktree add ../trackit-db -b m1-2-db
git worktree add ../trackit-fe -b m1-2-fe
```

`git worktree list` now shows three working trees, one per branch.

### Step 2: Run one agent in each, then merge

Run `db-builder` in `../trackit-db` and `frontend-builder` in `../trackit-fe`, then merge
both branches back in your original tree:

```bash
git merge m1-2-db m1-2-fe
```

Two outcomes are possible and both are useful. Where the partition held, the output reads:

```text
Fast-forwarding to: m1-2-db
Trying simple merge with m1-2-fe
Merge made by the 'octopus' strategy.
 backend/src/main/java/ch/acend/trackit/domain/TaskEntity.java | 24 ++++++
 frontend/src/views/TaskBoardView.vue                          | 61 +++++++++++
```

Where the two agents touched the same file, `git` names every one of them:

```text
Fast-forwarding to: m1-2-db
Trying simple merge with m1-2-fe
Simple merge did not work, trying automatic merge.
Auto-merging backend/src/main/resources/application.yml
ERROR: content conflict in backend/src/main/resources/application.yml
fatal: merge program failed
Automatic merge failed; fix conflicts and then commit the result.
```

**Note.** A three-way octopus merge reports `ERROR: content conflict in <file>`, not the
`CONFLICT (content):` line a normal two-branch merge prints. Merge the branches one at a
time if you would rather see the familiar form.

Answer: which conflicts did git surface that the single-tree run would have silently lost,
and what did the isolation cost the frontend agent?

**Take home:** Worktrees make parallel agent work reviewable. Each branch is a diff a human
can read, and git enforces the partition instead of a paragraph in a markdown file.

**Trap:** Merging two agent branches without reading either diff. You now have two
unreviewed changes instead of one.

Reference: [git worktree](https://git-scm.com/docs/git-worktree)

## Task A4 - ADVANCED: Add marketplaces

*Deepens task 5.* A marketplace is just a repository with a
`.claude-plugin/marketplace.json` in it. There are three tiers of trust:

| Source | What screening it had | How you add it |
|---|---|---|
| `claude-plugins-official` | curated by Anthropic | already there |
| `claude-community` | automated validation and safety screening, pinned to a commit SHA | `/plugin marketplace add anthropics/claude-plugins-community` |
| anyone's repository | **none** | `/plugin marketplace add owner/repo` |

### Step 1: Add the community marketplace

Add it by owner and repository:

```text
/plugin marketplace add anthropics/claude-plugins-community
```

It reports the marketplace added and how many plugins it carries. Plugins from it install
as `@claude-community`. Browse **Discover** and find one that would be useful in your own
work.

### Step 2: Find out who wrote it, before you install it

Open its homepage from the details pane and answer four things in writing:

- Who publishes it, and would you run their shell script on your laptop?
- When was it last updated, and does it still work against your Claude Code version?
- Does the "Will install" pane list anything the description did not lead you to expect?
- Does it bring an MCP server or a hook? Those two reach furthest.

### Step 3: Judge the third tier without installing it

Do not install one. Find a plugin marketplace in a repository belonging to neither
Anthropic nor your employer, and say what would have to be true for you to add it.
`/plugin marketplace add owner/repo` clones and trusts it with no screening whatsoever.

**Take home:** A plugin is a dependency that executes arbitrary code with your user
privileges, so it belongs in whatever review your other dependencies get. The team version
is `extraKnownMarketplaces` in `.claude/settings.json`: the repository names the
marketplaces it trusts, everyone who clones gets that list, and adding to it is a pull
request somebody reviews.

**Tip:** Look hardest at hooks. A skill only runs when something matches it, a hook runs on
an event whether or not you asked.

**Trap:** Auto-update is off by default for third-party marketplaces and on for
Anthropic's. Turning it on for someone else's means agreeing to run code you have not seen.

References: [discover and install plugins](https://code.claude.com/docs/en/discover-plugins) ·
[plugin marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)

## Task A5 - ADVANCED: Narrow the exposure and re-run

*Deepens tasks 6 and 7.* Add the GitHub server, narrowed to read-only issues:

```bash
claude mcp add --scope project github --transport http \
  https://api.githubcopilot.com/mcp/x/issues/readonly
claude mcp login github
```

`claude mcp login` opens a browser for the OAuth flow and reports the account it
authenticated.

`/x/issues` selects the toolset and `/readonly` restricts it to read tools. **The limit
lives in the endpoint, not in a prompt.** Compare with the full-access URL and give the
agent a task that reads issues. It still works, because it only ever needed to read.

**Take home:** Narrow first and see what breaks. Almost nothing does, and you learn what
the task actually needed rather than what it was given.

**Trap:** The write tools were available and never used. That is the usual finding, and it
is the argument for narrowing by default rather than after an incident.

Reference: [MCP](https://code.claude.com/docs/en/mcp)

## Task A6 - ADVANCED: Bundle into a plugin and hand it over

*Deepens tasks A1, A2 and A4.* Bundle your skills and agents into a plugin and give it to a
neighbour, who installs it and runs it on their own clone.

Before they install it, the receiving side names out loud what it can reach in *their*
repository. That is the review, and it is the whole exercise.

**Take home:** A skill is for you, a plugin is how the standard reaches everyone else. That
is the answer to "one agent configuration across all our repositories", and it makes the
review question sharper, because a bad rule now applies everywhere at once.

**Trap:** Installing a plugin because a colleague recommended it. The question is not
whether they trust it, it is what its agents can reach in your repository.

Reference: [plugins](https://code.claude.com/docs/en/plugins)

## Task A7 - ADVANCED: Give the agent a read-only database role

*Deepens task 7.* Give the agent a way into the database that cannot write.

### Step 1: Create the role and grant it reads

```bash
docker exec trackit-db psql -U trackit -d trackit -c "
  CREATE ROLE trackit_ro LOGIN PASSWORD '<a password you choose>';
  GRANT CONNECT ON DATABASE trackit TO trackit_ro;
  GRANT USAGE ON SCHEMA public TO trackit_ro;
  GRANT SELECT ON ALL TABLES IN SCHEMA public TO trackit_ro;"
```

`psql` prints one tag per statement, so the output should be:

```text
CREATE ROLE
GRANT
GRANT
GRANT
```

### Step 2: Prove the limit instead of trusting it

```bash
docker exec trackit-db psql -U trackit_ro -d trackit -c 'SELECT * FROM task;'
docker exec trackit-db psql -U trackit_ro -d trackit -c "DELETE FROM task;"
```

The first command prints the task rows. The second one is refused:

```text
ERROR:  permission denied for table task
```

### Step 3: Send the agent at it

Ask the agent to delete all tasks through that connection, and record what comes back. The
refusal comes from the database, not from the model's willingness.

**Take home:** This is the shape of the answer whenever someone asks how to keep an agent
out of a table. Not a prompt, not a tool description, not a promise from the model: a role
with a grant, and a denial from the database as evidence.

**Tip:** `GRANT SELECT ON ALL TABLES` covers today's tables only. New tables are not
included, and `ALTER DEFAULT PRIVILEGES` is the part people forget.

**Trap:** Read-only is not harmless. The role still reads every row it was granted, and
that data goes into a context window. Scope the schema too, not only the direction.

Reference: [PostgreSQL GRANT](https://www.postgresql.org/docs/17/sql-grant.html)

## Task A8 - ADVANCED: Build a minimal MCP server

*Deepens task 6.* Write an MCP server with exactly one tool that returns something from
this repo, the list of Flyway migrations for example. Connect it at project scope and use
it.

Then assess it as you would a third-party one: which permissions does it hold, and what
happens if its tool description is untrustworthy? Write a description that would plausibly
get an agent to do something the user did not ask for. Do not ship it.

**Take home:** Writing one is the fastest way to understand that a tool description is
content you inject into your own context window.

**Trap:** Reviewing a server by reading its README. The README is not what enters the
context, the tool descriptions are, and they can differ.

References: [MCP](https://code.claude.com/docs/en/mcp) ·
[Model Context Protocol specification](https://modelcontextprotocol.io/)

---

## Bring to the discussion

Fifteen minutes, and it runs on your answers. Everyone has these three:

- **Did the skill fire on the first try? If not, what did its description say?**
- **What did the tests tell you, and what did they not tell you?**
- **What did the plugin's "Will install" pane say, and would you put that plugin in your
team's `.claude/settings.json`?**

If you got into Part 3:

- **Skill or agent, which did you reach for and on which criterion?**
- **Which marketplace would you add to your team repository, and which would you not?**

## Further reading

- Skills: <https://code.claude.com/docs/en/skills>
- Subagents: <https://code.claude.com/docs/en/sub-agents>
- Finding and installing plugins: <https://code.claude.com/docs/en/discover-plugins>
- Building plugins: <https://code.claude.com/docs/en/plugins>
- Plugin marketplaces: <https://code.claude.com/docs/en/plugin-marketplaces>
- The plugin catalogue in a browser: <https://claude.com/plugins>
- MCP: <https://code.claude.com/docs/en/mcp>
- This repo's decisions: `docs/architecture.md`, `docs/adr/0001-*`, `docs/mcp-candidates.md`
