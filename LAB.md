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

## Where you start

Task 4 of lab 1.1 left you in the second clone, `trackit-b`. Go back to your own clone
first, and check that nothing is uncommitted:

```bash
cd ../trackit          # skip this if you never left
git status --porcelain
```

`pwd` ends in `/trackit`, and `git status --porcelain` prints nothing. If it prints a line,
commit it or throw it away, `git checkout` refuses to switch over uncommitted work:

```bash
git add -A && git commit -m "chore: end of lab 1.1"
```

Now fetch the branch that ships the skills, and check the environment:

```bash
git fetch origin
git checkout m1-2-start
./verify.sh
```

Every line of `./verify.sh` reads `[OK]` except the health endpoint, which only answers
while the application runs. PostgreSQL runs inside the devcontainer, so the line
`database container healthy` reads `[OK]` before you start. If that line fails, rebuild the
container from the command palette, *Dev Containers: Rebuild Container*.

There is deliberately no container for the application itself, that is M3. The database is
defined in `compose.yaml`, which M3 builds around.

**Note:** You do not need your lab 1.1 result here. `m1-2-start` is the lab 1.1 solution
with new scaffolding on top.

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

### Step 1: See what a fresh reader sees

```text
/init
```

`/init` scans the repo and writes a `CLAUDE.md` describing what it found. We are not
keeping that file, we are reading it.

### Step 2: Compare it with your rules

Put the fresh description next to the rules you wrote:

```bash
diff <(sed -n '1,200p' CLAUDE.md) AGENTS.md | head -40
```

The `<` lines come from `CLAUDE.md`. In them you see what `/init` found and `AGENTS.md`
never mentions: the task API, the `frontend/` folder, the database and the three skills.
Those are your gaps.

### Step 3: Put the pointer back

Throw the generated file away and keep only the gaps you just found:

```bash
git checkout -- CLAUDE.md
```

The command prints nothing. `cat CLAUDE.md` shows the single line that points at
`AGENTS.md` again.

Now open `AGENTS.md` and find these three rules. The next two tasks are held to them:

- The JPA entity is a separate class from the record
- The schema belongs to a Flyway migration, never to `ddl-auto`
- A view calls `api/`, never `axios` directly

**Take home:** Re-run `/init` whenever the repo shape changes. Keep the gaps it found, not
the file it wrote.

**Trap:** Committing the `/init` output over a curated `AGENTS.md`. That overwrites
judgement with description.

Reference: [Claude Code commands](https://code.claude.com/docs/en/commands)

## Task 2: Use the skill and the agent the branch ships (5 min)

### Step 1: Fire the skill without naming it

Stage the working tree:

```bash
git add -A
```

`git add` prints nothing. Now ask for a message:

```text
Write me a commit message for what I just staged.
```

You did not name the skill. It fired because its `description` matches what you asked.
Open `.claude/skills/commit-message/SKILL.md` and read that field, it lists the phrasings
it answers to. That field is the whole trigger mechanism.

Notice what it did not do: it printed a message and stopped. Its frontmatter says
`disallowed-tools: Write, Edit`, so it could not commit even if it decided to.

### Step 2: Run the agent

Send the same repository to a worker with its own context:

```text
Use the api-reviewer agent to review the task API.
```

Read `.claude/agents/api-reviewer.md` while it runs: `tools: Read, Grep, Glob` and
`model: haiku`. It has its own context window, a cheaper model, and cannot edit or run
anything.

### Step 3: Name the difference

One line each, for the discussion:

- The skill changed **how** something was done in your session.
- The agent did a job **somewhere else** and handed back a report.

**Take home:** `disallowed-tools` in a skill genuinely removes tools, but `allowed-tools`
only pre-approves and restricts nothing. An agent's `tools` list is an allowlist, so an
agent is a real boundary. That is the reason to reach for one.

**Tip:** When a skill does not fire, fix the description first, not the body. Write
descriptions as the phrasings people actually type.

**Trap:** Treating a skill as a sandbox. If you need something to be unable to write, use
an agent.

References: [skills](https://code.claude.com/docs/en/skills) ·
[subagents](https://code.claude.com/docs/en/sub-agents)

## Task 3: Put the tasks in the database (8 min)

Read `.claude/skills/add-persistence/SKILL.md` first, it is one page and it is the house
pattern for this job. Then give Claude Code the work:

```text
Move task storage out of the in-memory list in TaskService and into PostgreSQL.
The database is already running from compose.yaml.

Show me your plan before you change any file.
```

You did not name the skill. Check that it fired: the plan mentions an entity *beside* the
record, a Flyway migration, and `ddl-auto: validate`. If it does not, type this and let it
start again, because a plan that ignores the skill produces code that ignores it too:

```text
That plan does not follow the add-persistence skill in .claude/skills. Read it and plan
again.
```

It will ask you about dependencies, because `AGENTS.md` forbids adding one silently. Read
what it wants and why, then approve by naming what you are approving:

```text
The plan is fine and those dependencies are fine. Implement exactly that, and stop when
./mvnw test passes.
```

### Verify, in this order

Run the suite first:

```bash
cd backend
./mvnw -q test
```

The run ends in `BUILD SUCCESS`. Hand the failing output back to Claude Code if it does
not.

Start the application against the database:

```bash
./mvnw spring-boot:run
```

Spring Boot logs a `Started` line once it is up. Leave it running in that terminal.

In a second terminal, create a task:

```bash
curl -s -X POST localhost:8080/api/v1/tasks \
  -H 'content-type: application/json' \
  -d '{"title":"Survive a restart","project":"trackit"}'
```

The command returns the created task as JSON, with a generated `id` and the title you sent.

Now the check the tests cannot make. Stop the application with `Ctrl+C`, start it again,
and ask for the list:

```bash
curl -s localhost:8080/api/v1/tasks
```

You see `Survive a restart` in the list, returned by a process that started with an empty
memory. Look in the database yourself:

```bash
docker exec trackit-db psql -U trackit -d trackit -c 'SELECT * FROM task;'
```

`psql` prints one row per stored task, and yours is among them.

A green test suite proved none of that. The controller test mocks the service away, so the
whole storage path is absent from the run. Persistence is proven by a restart and by
nothing else.

Commit the slice now that it survives a restart:

```bash
cd .. && git add -A && git commit -m "feat: store tasks in postgres"
```

**Take home:** For every feature, name the check the test suite cannot make, then make it.
That is your real acceptance criterion.

**Tip:** Anything you have typed into a prompt three times is a skill.

**Trap:** `BUILD SUCCESS` feeling like proof. The suite passes with no database running
at all.

Reference: [skills](https://code.claude.com/docs/en/skills)

## Task 4: Put the tasks on a screen (8 min)

Same shape, other subsystem. Read `.claude/skills/add-view/SKILL.md`, then:

```text
Build the task board in the frontend: list all tasks, and add a new one.
Use the existing REST API. Show me your plan before you change any file.
```

Check the skill fired: the plan mentions a typed API module under `src/api/`, one view per
route, and the route going into `router/index.ts`. Then approve:

```text
The plan is fine. Implement exactly that, and stop when npx vue-tsc -b exits 0.
```

In a second terminal:

```bash
cd frontend
npx vue-tsc -b     # must exit 0
npm run dev
```

Open <http://localhost:5173> with the backend still running, add a task, and see it in the
list. Reload the page, it is still there, because it is in the database now.

Commit the board:

```bash
cd .. && git add -A && git commit -m "feat: add the task board"
```

Note roughly how long the two jobs took in sequence. Task A2 does the same two jobs at the
same time, and the comparison is the point of that task.

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

Claude Code registers Anthropic's official marketplace, `claude-plugins-official`, on its
first interactive start, so there is nothing to add. Cycle the tabs with `Tab`:

| Tab | What it holds |
|---|---|
| Discover | plugins from every marketplace you have added |
| Installed | what you have, and what you can disable or remove |
| Marketplaces | the catalogues themselves |
| Errors | anything that failed to load |

### Step 2: Read before you install

Go to **Discover** and select **commit-commands**. Do not press install yet. The details
pane is the review surface:

- **Context cost**: what this plugin adds to your context window on *every turn*
- **Last updated**: whether anyone still maintains it
- **Will install**: every command, agent, skill, hook, MCP server and LSP server it brings

Read the "Will install" list out loud to yourself. A plugin runs with your permissions, on
your files. This pane is the last moment saying no costs you nothing.

### Step 3: Install it at user scope

Install it by name, marketplace included:

```text
/plugin install commit-commands@claude-plugins-official
```

Choose **User** scope, yourself, across all projects. If the summary says
`Run /reload-plugins to activate.`, run that.

### Step 4: Use it

Call the plugin's own command:

```text
/commit-commands:commit
```

You now have two ways to write a commit message: the repo's own `commit-message` skill,
which fires from its description, and this one, which you call by name. Plugin skills are
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

### Step 1: Connect it

One command, from `docs/mcp-candidates.md`, where every entry was run and checked:

```bash
claude mcp add --scope project --transport http context7 https://mcp.context7.com/mcp
```

`--scope project` writes `.mcp.json` in the repo root. That file is committed, so this is a
team decision, the same distinction you just met with plugin scopes.

### Step 2: Approve it and check it connected

Ask Claude Code what it now holds:

```bash
claude mcp list
```

A project-scope server shows as `Pending approval` until you approve it in an interactive
session. A server arriving through a `git pull` does not connect silently.

### Step 3: Use it on a real question

Ask something the model cannot answer from memory:

```text
Using the context7 docs, check the PrimeVue 4 API used in the task board. Name
anything that is deprecated or renamed in the version in package.json, and quote the
doc line you got it from.
```

The server shows connected and the agent called one of its tools. Finding no problem is a
good outcome, "the code matches the current docs, and here is the line that says so" is a
real answer.

### Where to find the servers that are not on our list

Three directories carry them, and you vet before you add, not after:

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

Answer these for the plugin and again for the MCP server, in a new file
`docs/mcp-scoping.md`:

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

Optional. Start when `./mvnw -q test` passes and `git status` lists nothing uncommitted
from Parts 1 and 2. The tasks are independent, so do **task A2 first** if you only do one.

## Task A1 - ADVANCED: Write a skill of your own

*Deepens tasks 3 and 4.* Write `add-endpoint`: generate a new REST endpoint in the house
pattern, including the service method, the error handling and a MockMvc test. Start from
this frontmatter:

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

`git worktree list` now shows a second working tree at `../trackit-parallel`.

### Step 2: Write two agent definitions

Use `/agents`, or write the files directly:

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

### Step 5: Compare

Against your Part 1 run: how long did it take, and what did you give up? You reviewed two
reports instead of two plans, and you never saw either plan before it ran.

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
to, and an instruction is not a boundary. Give each one its own working tree:

```bash
git worktree add ../trackit-db -b m1-2-db
git worktree add ../trackit-fe -b m1-2-fe
```

`git worktree list` now shows three working trees, one per branch.

Run one agent in each, then merge both branches back in your original tree:

```bash
git merge m1-2-db m1-2-fe
```

You see either one merge commit across both branches, or `CONFLICT` lines naming every file
both agents touched.

Answer: which conflicts did git surface that the single-tree run would have silently lost,
and what did the isolation cost the frontend agent?

**Take home:** Worktrees make parallel agent work reviewable. Each branch is a diff a human
can read, and git enforces the partition instead of a paragraph in a markdown file.

**Trap:** Merging two agent branches without reading either diff. You now have two
unreviewed changes instead of one.

Reference: [git worktree](https://git-scm.com/docs/git-worktree)

## Task A4 - ADVANCED: Add a marketplace nobody vetted for you

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

Plugins from it install as `@claude-community`. Browse **Discover** and find one that
would be useful in your own work.

### Step 2: Before you install it, find out who wrote it

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

*Deepens tasks 6 and 7.* Add the GitHub server, narrowed:

```bash
claude mcp add --scope project github --transport http \
  https://api.githubcopilot.com/mcp/x/issues/readonly
claude mcp login github
```

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

*Deepens task 7.* Give the agent a way into the database that cannot write:

```bash
docker exec trackit-db psql -U trackit -d trackit -c "
  CREATE ROLE trackit_ro LOGIN PASSWORD 'readonly';
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

Prove the limit instead of trusting it:

```bash
docker exec trackit-db psql -U trackit_ro -d trackit -c 'SELECT * FROM task;'
docker exec trackit-db psql -U trackit_ro -d trackit -c "DELETE FROM task;"
```

The first command prints the task rows. The second one is refused:

```text
ERROR:  permission denied for table task
```

Now ask the agent to delete all tasks through that connection and record what comes back.

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
