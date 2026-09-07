# Lab 1.2: give the agent your patterns, and let it build two subsystems

| Info | Detail |
|---|---|
| Module | M1.2 - Extending and scoping the agent: skills, agents, plugins, MCP |
| Duration | 40 minutes in two halves, 25 and 15, with the MCP input between them |
| Harness | Claude Code |
| Stack | Java 21, Spring Boot 3.5 and Maven in `backend/`. Vue 3, Vite and TypeScript in `frontend/`. PostgreSQL 17 from `compose.yaml` |
| Repo | `lab-trackit-java`, branch `m1-2-start` |
| Target state | tasks stored in PostgreSQL, task board in the browser (branch `m1-2-solution`) |

**The lab has three parts.**

**Part 1 and Part 2 are for everyone.** Part 1 runs before the MCP input, Part 2 after
it. You do not write a skill, an agent or a configuration file in either part - you use
the ones the branch ships and you check what they did. Six tasks, all with the commands
in this handout.

**Part 3 is advanced and optional.** That is where you write your own skill, define your
own agents, run two of them in parallel and narrow an MCP server. Start it only when
Parts 1 and 2 run green. **Nothing later in the day depends on Part 3** - the afternoon
starts from the state Part 1 produces.

If you finish Part 1 with time to spare, go to Part 3 task A2. It is the most useful one.

## What you build

Today TrackIt keeps its tasks in a list in memory and has no screen. By the end of this
lab a task survives a restart of the application, and you can add one in a browser.

That is two subsystems, and you are not going to write either of them. The branch ships
two **skills** - short files that describe how this project does persistence and how it
does screens. You give Claude Code the job, the right skill fires by itself, and your
work is to check what came out.

| Mechanism | What it is | Where you meet it |
|---|---|---|
| Skill | a written working instruction: how something is done here | Part 1, given to you |
| Agent | a worker with its own context, model and limits | Part 1 given, Part 3 you write one |
| MCP | a connection to something outside this repo | Part 2, one command |
| Plugin | how skills and agents reach the rest of your team | Part 3 |

## Where you start

```bash
git fetch origin
git checkout m1-2-start
docker compose up -d
./verify.sh
```

`docker compose up -d` starts PostgreSQL and nothing else. There is deliberately no
container for the application itself - that is M3.

Every line of `./verify.sh` must read `[OK]` except the health endpoint at the end, which
only answers while the application runs.

**If lab 1.1 did not finish:** you are on the right branch already. `m1-2-start` is the
lab 1.1 solution with new scaffolding on top, so nothing you missed blocks you here.

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

All of these are files in the repository, committed and reviewed like code. None of them
is a personal setting.

`/help` lists the commands your version has. Versions differ - trust `/help` over any
handout, including this one.

---

# Part 1 - Standard, 25 minutes

Everyone works through this part. You will not write a skill or an agent here.

## Task 1 - Re-ground the harness (4 min)

The repo changed since you wrote `AGENTS.md` in lab 1.1. It has a task API now, a
frontend folder, a database and three skills. Your context file describes none of that,
and everything you run today reads it.

**Step 1 - see what the repo looks like to a fresh reader.**

```text
/init
```

`/init` scans the repo and writes a `CLAUDE.md` describing what it found. This project
keeps its rules in `AGENTS.md`, so you are not keeping that file - you are reading it.

**Step 2 - compare it with your rules.**

```bash
diff <(sed -n '1,200p' CLAUDE.md) AGENTS.md | head -40
```

Look for what `/init` found that `AGENTS.md` does not mention.

**Step 3 - put the pointer back.**

```bash
git checkout -- CLAUDE.md
```

Now open `AGENTS.md` and find these three rules. They are already there, and they are
what the next two tasks are held to:

- the JPA entity is a separate class from the record
- the schema belongs to a Flyway migration, never to `ddl-auto`
- a view calls `api/`, never `axios` directly

**Expected result.** `CLAUDE.md` is one line again, and you can point at those three
rules in `AGENTS.md`.

**Take this to your team**

| | In this lab | In your repo |
|---|---|---|
| When to re-run `/init` | after the repo grew a subsystem | Whenever the shape changes. A context file written once goes stale silently |
| What you keep | the gaps it found, not the file it wrote | `/init` describes. You decide. Mine the output, throw the file away |

**Tip.** Read `/init` output as a report on what a newcomer can infer without asking.
Everything it got right is something you do not need to write down.

**Trap.** Running `/init` and committing the result over a curated `AGENTS.md`. It
overwrites judgement with description.

**Reference.** [Claude Code commands](https://code.claude.com/docs/en/commands)

## Task 2 - Use the skill and the agent the branch ships (5 min)

Two mechanisms, one repo, so you can see the difference before you rely on either.

**Step 1 - the skill.** Stage something and ask for a message:

```bash
git add -A
```

```text
Write me a commit message for what I just staged.
```

**You did not name the skill.** It fired because its `description` matches what you
asked. Open `.claude/skills/commit-message/SKILL.md` and read that field - it lists the
phrasings it answers to. That field is the whole trigger mechanism, and it is the thing
that goes wrong when a skill does not fire.

Notice what it did not do: it printed a message and stopped. Its frontmatter says
`disallowed-tools: Write, Edit`, so it could not commit even if it decided to.

**Step 2 - the agent.** Point the reviewer at the task API:

```text
Use the api-reviewer agent to review the task API.
```

Read `.claude/agents/api-reviewer.md` while it runs: `tools: Read, Grep, Glob` and
`model: haiku`. It has its own context window, a cheaper model, and cannot edit or run
anything.

**Step 3 - name the difference.** One line each, for the discussion:

- The skill changed **how** something was done in your session.
- The agent did a job **somewhere else** and handed back a report.

**Expected result.** A commit message you did not write, a review you did not do
yourself, and one sentence on which of the two you would reach for next time.

**Take this to your team**

| | In this lab | In your repo |
|---|---|---|
| Trigger | the `description` field, matched against what you typed | Write descriptions as the phrasings people actually use, not as a summary |
| Skill permissions | `disallowed-tools` genuinely removes tools | `allowed-tools` only pre-approves. It restricts nothing. A skill is not a permission boundary |
| Agent permissions | `tools` is an allowlist | An agent IS a boundary. That is the real reason to reach for one |
| Model choice | `haiku` for a read-only review | Cheap model for mechanical review, expensive one for planning |

**Tip.** When a skill does not fire, fix the description first, not the body. Nobody
reads the body until the description matched.

**Trap.** Treating a skill as a sandbox. If you need something to be *unable* to write,
that is an agent.

**Reference.** [skills](https://code.claude.com/docs/en/skills) ·
[subagents](https://code.claude.com/docs/en/sub-agents)

## Task 3 - Put the tasks in the database (8 min)

The branch ships `.claude/skills/add-persistence/SKILL.md`. Read it first - it is one
page, and it is the house pattern for this job. Then give Claude Code the work:

```text
Move task storage out of the in-memory list in TaskService and into PostgreSQL.
The database is already running from compose.yaml.

Show me your plan before you change any file.
```

You did not name the skill. Check that it fired: the plan should mention an entity
*beside* the record, a Flyway migration, and `ddl-auto: validate`. If it does not, say
so and let it start again - a plan that ignores the skill will produce code that ignores
it too.

**It will ask you about dependencies.** `AGENTS.md` forbids adding one silently. Read
what it wants and why before you approve.

**Then verify, in this order.**

```bash
cd backend
./mvnw -q test
```

Ends in `BUILD SUCCESS`. Hand it back with the failing output if not.

```bash
./mvnw spring-boot:run
```

In a second terminal:

```bash
curl -s -X POST localhost:8080/api/v1/tasks \
  -H 'content-type: application/json' \
  -d '{"title":"Survive a restart","project":"trackit"}'
```

**Now the check the tests cannot make.** Stop the application with `Ctrl+C`, start it
again, and ask for the list:

```bash
curl -s localhost:8080/api/v1/tasks
```

The task must still be there. And look in the database yourself:

```bash
docker compose exec db psql -U trackit -d trackit -c 'SELECT * FROM task;'
```

**A green test suite did not prove any of that.** The controller test mocks the service
away, so the whole storage path is absent from the run. Persistence is proven by a
restart, and by nothing else. This is the most useful habit in the lab: for every
feature, name the check the test suite cannot make, and then make it.

```bash
cd .. && git add -A && git commit -m "feat: store tasks in postgres"
```

**Expected result.** A row in the `task` table that survives a restart, and one sentence
on what the tests were and were not telling you.

**Take this to your team**

| | In this lab | In your repo |
|---|---|---|
| What a skill buys you | the pattern applied without you re-typing it | Anything you have typed into a prompt three times is a skill |
| Checking it fired | the plan mentions the pattern | Read the plan for the rule, not just the steps. A plan that skips it produces code that skips it |
| Dependencies | the agent names them and waits | Put "name a dependency before adding it" in your context file. It is the cheapest guardrail there is |
| Definition of done | restart, then look in the database | Name the check the test suite cannot make. That is your real acceptance criterion |

**Tip.** Read the plan for one thing: what does it touch that you did not ask about?
That is where scope creep lives, and it is visible in ten seconds.

**Trap.** `BUILD SUCCESS` feeling like proof. Here it is green with no database running
at all.

**Reference.** [skills](https://code.claude.com/docs/en/skills) ·
[Claude Code commands](https://code.claude.com/docs/en/commands)

## Task 4 - Put the tasks on a screen (8 min)

Same shape, other subsystem. The branch ships `.claude/skills/add-view/SKILL.md`. Read
it, then:

```text
Build the task board in the frontend: list all tasks, and add a new one.
Use the existing REST API. Show me your plan before you change any file.
```

Check the skill fired: the plan should mention a typed API module under `src/api/`, one
view per route, and the route going into `router/index.ts`.

**Verify.**

```bash
cd frontend
npx vue-tsc -b     # must exit 0
npm run dev
```

Open <http://localhost:5173> with the backend still running, add a task, and see it in
the list. Then reload the page - it is still there, because it is in the database now.

```bash
cd .. && git add -A && git commit -m "feat: add the task board"
```

**Expected result.** A task you added in the browser, visible after a reload, and stored
in PostgreSQL.

**You have now done the two jobs one after the other.** Note roughly how long that took.
Task A2 in Part 3 does the same two jobs at the same time, and the comparison is the
point of that task.

**Take this to your team**

| | In this lab | In your repo |
|---|---|---|
| Two subsystems, one session | done in sequence, one skill each | Fine for two. The cost shows up when it is five |
| The API contract | the agent read the controller to learn it | Have it read the real contract, never describe it in the prompt. The prompt goes stale, the code does not |
| Verification | typecheck, then the browser | A green build is not a working screen. Open it |

**Tip.** `npx vue-tsc -b` catches the mismatch between the TypeScript type and the Java
record faster than clicking does.

**Trap.** Trusting a screen that renders. Renders and reads-the-right-data are different
claims.

**Reference.** [skills](https://code.claude.com/docs/en/skills)

---

# Part 2 - Standard, 15 minutes

Start this after the MCP input.

## Task 5 - Connect one server and use it (7 min)

Your session just wrote Vue 3 and PrimeVue 4 from what the model remembers. Its memory is
older than the versions in `frontend/package.json`. That gap is the case for MCP: not
extra capability, current information.

**Step 1 - connect it.** One command, from `docs/mcp-candidates.md`, where every entry
was run and checked:

```bash
claude mcp add --scope project --transport http context7 https://mcp.context7.com/mcp
```

`--scope project` writes `.mcp.json` in the repo root. That file is committed, so this is
a team decision, not a local convenience.

**Step 2 - approve it and check it connected.**

```bash
claude mcp list
```

A project-scope server shows as `Pending approval` until you approve it in an interactive
session. A server arriving through a `git pull` does not connect silently. That prompt is
the feature, not an annoyance.

**Step 3 - use it on a real question.**

```text
Using the context7 docs, check the PrimeVue 4 API used in the task board. Name
anything that is deprecated or renamed in the version in package.json, and quote the
doc line you got it from.
```

**Expected result.** The server shows connected, and the agent called one of its tools in
a task you can name. Finding no problem is a fine outcome - "the code matches the current
docs, and here is the line that says so" is a real answer.

**Take this to your team**

| | In this lab | In your repo |
|---|---|---|
| Why connect one | the model's library knowledge is older than your lockfile | The best MCP cases are current information, not more power |
| Scope | `--scope project`, committed | Team decision, reviewed in a pull request |
| Approval | pending until approved interactively | Keep it that way. A server that connects on `git pull` is a supply-chain path |
| Cost | every connected server's tool descriptions sit in context | Check with `/context`. Connect what the repo needs, not what looks useful |

**Tip.** Ask for the quoted doc line, not the conclusion. It turns an unverifiable claim
into a citation you can check in five seconds.

**Trap.** Connecting five servers because they all look useful. Every tool description is
in the context window on every turn.

**Reference.** [MCP](https://code.claude.com/docs/en/mcp) · `docs/mcp-candidates.md`

## Task 6 - Write down what it can reach (8 min)

No configuration in this task. Three questions, answered in writing, in a new file
`docs/mcp-scoping.md`:

- **Slice.** Which part of the system does it expose? Not "GitHub" - which repositories,
  which resource type.
- **Credential.** Which one does it use, and where does it come from? Your own account, a
  service account, none at all?
- **Direction.** Read-only or writing? And is that enforced by the endpoint, or only
  requested in a prompt?

Then one more line. Three things together make a session dangerous:

- access to private data
- content from an untrusted source entering the context
- a channel to the outside

With all three, content can act as an instruction and data can leave. Removing any one
breaks the chain. Tick the ones present in your session and write one verdict line.

**Expected result.** Four written lines you can read out in the discussion.

**Take this to your team**

| | In this lab | In your repo |
|---|---|---|
| The three questions | slice, credential, direction | Ask them before connecting, every time. They take a minute and they are the whole review |
| Where a limit lives | in the endpoint, in the grant, in the token | Never in the prompt. A prompt-level limit is a request, and requests get argued with |
| Vetting | a tool description is third-party text in your context | Review a server before committing it to a team repo. The description is an input, not documentation |

**Tip.** A server nobody can describe in three lines does not get committed. That rule
alone removes most of the risk.

**Trap.** "It is read-only" because the prompt said so. Read-only is a property of the
endpoint or the database grant.

**Reference.** [MCP](https://code.claude.com/docs/en/mcp) ·
[permissions](https://code.claude.com/docs/en/permissions)

---

# Part 3 - ADVANCED

**Optional.** Start only when Parts 1 and 2 run green and your commits are in place.
Nothing later in the day depends on this part.

The tasks are independent - pick what interests you. **A2 is the one to do first** if you
only do one.

## Task A1 - ADVANCED - Write a skill of your own

*Deepens tasks 3 and 4.*

You used two skills. Write a third. `add-endpoint`: generate a new REST endpoint in the
house pattern, including the service method, the error handling and a MockMvc test.

```markdown
---
name: add-endpoint
description: Use when adding a REST endpoint to TrackIt, or when the user says "add an
  endpoint", "expose X over the API" or "new route". Generates controller method,
  service method, error handling and a MockMvc test in the house pattern.
---
```

Then use it to add `GET /api/v1/tasks/{id}`, returning 404 for an unknown id.

The three fields that decide whether this works:

| Field | Gets it wrong when | Costs you |
|---|---|---|
| `description` | it summarises instead of listing phrasings | the skill never fires |
| `allowed-tools` | you expect it to restrict | it pre-approves only. Use an agent for a real limit |
| the Rules block | it repeats what the code already shows | tokens on every turn, no behaviour change |

Then answer: which of your rules would the agent have followed anyway? Delete those.

**Take this to your team**

Rules go in `AGENTS.md`, procedures go in a skill. Mixing them makes both unreadable, and
a duplicated line drifts in two places at once.

**Tip.** Write the description last, after the body, when you know what the skill
actually does.

**Trap.** A skill that restates the context file. Every duplicated line is sent twice.

**Reference.** [skills](https://code.claude.com/docs/en/skills)

## Task A2 - ADVANCED - Two agents, one turn, two subsystems

*Deepens tasks 3 and 4. Start here if you only do one advanced task.*

In Part 1 you did the database and the frontend one after the other. They are
independent jobs. Do them again, at the same time.

**Step 1 - throw the work away and start from the same place.**

```bash
git worktree add ../trackit-parallel m1-2-start
cd ../trackit-parallel
```

**Step 2 - write two agent definitions.** Use `/agents`, or write the files directly:

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

`frontend-builder` is the mirror image: owns `frontend/`, may **read** `backend/` to
learn the API shape, follows the `add-view` skill, quotes `npx vue-tsc -b`.

**Step 3 - understand why this is safe before you run it.**

The two agents run at the same time in the same working tree. That is safe for exactly
one reason: **their file spaces do not overlap.** One writes `backend/`, the other writes
`frontend/`. Take that away and they overwrite each other's edits with no conflict marker
and no error.

That partition is the thing you are designing. The tool list is how you enforce it.

**Step 4 - dispatch both in one message.**

```text
Use the db-builder agent to move task storage into PostgreSQL, and at the same time
use the frontend-builder agent to build the task board.

Run them in parallel. Do not edit any file yourself. When both report back, show me
both reports unchanged.
```

Both run in the background and report as they finish. While they work you are doing
nothing. That is the point of the exercise and it is also the uncomfortable part.

**Step 5 - compare.** Against your Part 1 run: how long did it take, and what did you
give up? You reviewed two reports instead of two plans, and you never saw either plan
before it ran.

**Take this to your team**

| | In this lab | In your repo |
|---|---|---|
| When an agent is worth it | two jobs at once, each reporting back compressed | Parallelism, or a fresh context window. "It is specialised" is not a reason - a skill can be specialised |
| How parallel stays safe | disjoint file spaces, enforced by the tool list | Partition by module, package or service. If you cannot draw the line, run them in sequence |
| What the report is for | claims you then check | Make "what did you NOT verify" a required section. It is the most useful line an agent writes |
| What it costs | you approve no plans | For risky work, sequential with plan review beats parallel. Choose deliberately |

**Tip.** Two or three high-leverage agents beat fifteen overlapping ones. Every agent is
another definition to keep true as the repo changes.

**Trap.** Two agents in one working tree with overlapping paths. There is no conflict
marker - the second write simply wins, and you find out in review.

**Reference.** [subagents](https://code.claude.com/docs/en/sub-agents)

## Task A3 - ADVANCED - Make the partition real with worktrees

*Deepens task A2.*

In A2 the agents stayed out of each other's way because you told them to. An instruction
is not a boundary. Give each one a working tree of its own:

```bash
git worktree add ../trackit-db -b m1-2-db
git worktree add ../trackit-fe -b m1-2-fe
```

Run one agent in each, then merge:

```bash
git merge m1-2-db m1-2-fe
```

Then answer: which conflicts did git surface that the single-tree run would have silently
lost? And what did the isolation cost - what did the frontend agent no longer know?

**Take this to your team**

Worktrees make parallel agent work reviewable. Each branch is a diff a human can read,
and git enforces the partition instead of a paragraph in a markdown file.

**Trap.** Merging two agent branches without reading either diff. You now have two
unreviewed changes instead of one.

**Reference.** [git worktree](https://git-scm.com/docs/git-worktree)

## Task A4 - ADVANCED - Narrow the exposure and re-run

*Deepens tasks 5 and 6.*

Add the GitHub server, then narrow it and see what breaks:

```bash
claude mcp add --scope project github --transport http \
  https://api.githubcopilot.com/mcp/x/issues/readonly
claude mcp login github
```

`/x/issues` selects the toolset, `/readonly` restricts it to read tools. **The limit lives
in the endpoint, not in a prompt.** Compare with the full-access URL and give the agent a
task that reads issues. It still works, because it only ever needed to read.

**Take this to your team**

Narrow first and see what breaks. Almost nothing does, and you learn what the task
actually needed rather than what it was given.

**Trap.** The write tools were available, never used. That is the usual finding, and it
is the argument for narrowing by default rather than after an incident.

**Reference.** [MCP](https://code.claude.com/docs/en/mcp)

## Task A5 - ADVANCED - Bundle into a plugin and hand it over

*Deepens tasks A1 and A2.*

Your skills and agents are the TrackIt house pattern. Bundle them into a plugin and give
it to a neighbour, who installs it and runs it on their own clone.

**Before they install it, the receiving side names out loud what it can reach in their
repository.** That is the review, and it is the whole exercise. A plugin runs with your
permissions, in your repo, on your files.

Then answer: what would you have to know about a plugin from outside your company before
installing it, and how would you find that out?

**Take this to your team**

A skill is for you, a plugin is how the standard reaches everyone else. That is the answer
to "one agent configuration across all our repositories", and it makes the review question
sharper, not softer - a bad rule now applies everywhere at once.

**Trap.** Installing a plugin because a colleague recommended it. The question is not
whether they trust it, it is what its agents can reach in *your* repository.

**Reference.** [plugins](https://code.claude.com/docs/en/plugins)

## Task A6 - ADVANCED - A database role the agent cannot write through

*Deepens task 6. This is the answer to the survey question about protecting database
areas from agent access.*

You have a real database now. Give the agent a way in that cannot write:

```bash
docker compose exec db psql -U trackit -d trackit -c "
  CREATE ROLE trackit_ro LOGIN PASSWORD 'readonly';
  GRANT CONNECT ON DATABASE trackit TO trackit_ro;
  GRANT USAGE ON SCHEMA public TO trackit_ro;
  GRANT SELECT ON ALL TABLES IN SCHEMA public TO trackit_ro;"
```

Prove the limit rather than trusting it:

```bash
docker compose exec db psql -U trackit_ro -d trackit -c 'SELECT * FROM task;'
docker compose exec db psql -U trackit_ro -d trackit -c "DELETE FROM task;"
```

The second must fail with a permission error. Now ask the agent to delete all tasks
through that connection and record what comes back.

Then answer: what does this protect, and what does it not?

**Take this to your team**

This is the shape of the answer whenever someone asks how to keep an agent out of a table.
Not a prompt, not a tool description, not a promise from the model - a role with a grant,
and a denial from the database as evidence.

**Tip.** `GRANT SELECT ON ALL TABLES` covers today's tables only. New tables are not
included. `ALTER DEFAULT PRIVILEGES` is the part people forget.

**Trap.** Read-only is not harmless. The role still reads every row it was granted, and
that data goes into a context window. Scope the schema too, not only the direction.

**Reference.** [PostgreSQL GRANT](https://www.postgresql.org/docs/17/sql-grant.html)

## Task A7 - ADVANCED - Build a minimal MCP server

*Deepens task 5.*

Write an MCP server with exactly one tool that returns something from this repo - the list
of Flyway migrations, say. Connect it at project scope and use it.

Then assess it as you would a third-party one: which permissions does it hold, and what
happens if its tool description is untrustworthy? Write a description that would
plausibly get an agent to do something the user did not ask for. Do not ship it - the
exercise is seeing how short it can be.

**Take this to your team**

Writing one is the fastest way to understand that a tool description is content you are
injecting into your own context window.

**Trap.** Reviewing a server by reading its README. The README is not what enters the
context. The tool descriptions are, and they can differ.

**Reference.** [MCP](https://code.claude.com/docs/en/mcp) ·
[Model Context Protocol specification](https://modelcontextprotocol.io/)

---

## Bring to the discussion

Fifteen minutes, and it runs on your answers. Everyone has these two:

- **Did the skill fire on the first try? If not, what did its description say?**
- **What did the tests tell you, and what did they not tell you?**

If you got into Part 3:

- **Skill or agent - which did you reach for, and on which criterion?**
- **Which server would you not commit to your team repository, and why?**

## Further reading

- Skills: <https://code.claude.com/docs/en/skills>
- Subagents: <https://code.claude.com/docs/en/sub-agents>
- Plugins: <https://code.claude.com/docs/en/plugins>
- MCP: <https://code.claude.com/docs/en/mcp>
- This repo's own decisions: `docs/architecture.md`, `docs/adr/0001-*`,
  `docs/mcp-candidates.md`
