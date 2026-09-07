# Lab 1.2: teach the harness your patterns, then run two builds at once

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
it. Work through them in order.

**Part 3 is advanced.** Start it only when Parts 1 and 2 run green. Every task is
marked **ADVANCED** and all of them are optional.

Task 4 has to happen. It is the state the afternoon builds on, and the discussion runs
on what the two agents reported back.

## What you build

Today TrackIt keeps its tasks in a list in memory and has no screen. By the end of this
lab a task survives a restart of the application, and you can add one in a browser.

That is two subsystems, and you are not going to write either of them. You are going to
write down how this project does persistence and how it does screens, hand each one to
its own agent, and run both at the same time.

The four mechanisms of this module map onto that one job:

| Mechanism | Its job today |
|---|---|
| Skill | your house pattern, written once, so the agent stops inventing one |
| Agent | who does the work, with its own context, its own model, its own limits |
| MCP | what the agent can reach when the answer is not in this repo |
| Plugin | how both of them reach the rest of your team (Part 3) |

## Where you start

```bash
git fetch origin
git checkout m1-2-start
docker compose up -d
./verify.sh
```

`docker compose up -d` starts PostgreSQL and nothing else. There is deliberately no
container for the application itself - that is M3.

Every line of `./verify.sh` must read `[OK]` except the health endpoint at the end,
which only answers while the application runs.

`m1-2-start` carries the state after lab 1.1 plus three things you did not have before:
the `frontend/` scaffold with its dependencies already installed, `compose.yaml`, and
one skill and one agent that somebody else wrote for you.

**If lab 1.1 did not finish:** you are on the right branch already. `m1-2-start` is the
lab 1.1 solution with the new scaffolding on top, so nothing you missed blocks you here.

## Where these things live

| Thing | Path | Scope |
|---|---|---|
| Skill | `.claude/skills/<name>/SKILL.md` | committed, so the team gets it |
| Agent | `.claude/agents/<name>.md` | committed, so the team gets it |
| MCP server | `.mcp.json` in the repo root | committed, so the team gets it |
| Context file | `AGENTS.md`, with `CLAUDE.md` pointing at it | committed |

All four are configuration in the repository, reviewed in a pull request like code. None
of them is a personal setting.

`/help` lists the commands your version has. Versions differ - trust `/help` over any
handout, including this one.

---

# Part 1 - Standard, 25 minutes

## Task 1 - Re-ground the harness (4 min)

The repo changed since you wrote `AGENTS.md`. It has a task API now, a frontend folder,
a database and two files in `.claude/`. Your context file describes none of that.

This matters more today than yesterday: in task 4 you start two agents, and **every
agent you start inherits this file.** A gap here becomes the same gap twice, in
parallel.

**Step 1 - see what the repo looks like to a fresh reader.**

```text
/init
```

`/init` scans the repo and writes a `CLAUDE.md` describing what it found. This project
keeps its rules in `AGENTS.md`, so you are not going to keep that file - you are going
to read it and mine it.

**Step 2 - diff the description against your rules.**

```bash
diff <(sed -n '1,200p' CLAUDE.md) AGENTS.md | head -40
```

Look for what `/init` found that `AGENTS.md` does not mention. The frontend folder and
the database are the two that matter today.

**Step 3 - restore the pointer and fix the gap.**

```bash
git checkout -- CLAUDE.md
```

Now open `AGENTS.md` and check that it says, in words an agent can follow:

- where frontend code lives and what shape it takes
- that the schema belongs to a migration and not to `ddl-auto`
- that the JPA entity is a separate class from the record

Those three blocks are already in the file on this branch. Read them - they are what
your skills encode in task 3, and what your agents are held to in task 4.

**Expected result.** `CLAUDE.md` is one line again, and you can point at the three
blocks in `AGENTS.md` that will govern the two builds.

**Take this to your team**

| | In this lab | In your repo |
|---|---|---|
| When to re-run `/init` | after the repo grew a subsystem | Whenever the shape changes. A context file written once goes stale silently |
| What you keep | the gaps it found, not the file it wrote | `/init` describes. You decide. Mine the output, throw the file away |
| Why it matters more with agents | two agents inherit the same file | Every subagent starts from your project context. One vague rule becomes N vague agents |

**Tip.** Read `/init` output as a report on what a newcomer can infer without asking.
Everything it got right is something you do not need to write down.

**Trap.** Running `/init` and committing the result over a curated `AGENTS.md`. It
overwrites judgement with description.

**Reference.** [Claude Code commands](https://code.claude.com/docs/en/commands) ·
[settings and context files](https://code.claude.com/docs/en/settings)

## Task 2 - Use the skill and the agent somebody else wrote (5 min)

Before you write your own, run the two that ship on this branch. They exist so you can
see the difference between the two mechanisms on the same repo.

**Step 1 - the skill.** `.claude/skills/commit-message/SKILL.md` is a working
instruction. Stage something and ask for a message:

```bash
git add -A
```

```text
Write me a commit message for what I just staged.
```

You did not name the skill. It fired because its `description` matches what you asked.
Open the file and read that field - it lists the phrasings it answers to. That field is
the entire trigger mechanism.

Notice what it did not do: it printed a message and stopped. Its frontmatter says
`disallowed-tools: Write, Edit`, so it could not commit even if it decided to.

**Step 2 - the agent.** `.claude/agents/api-reviewer.md` is a different thing. Point it
at the task API:

```text
Use the api-reviewer agent to review the task API.
```

Read its frontmatter while it runs: `tools: Read, Grep, Glob` and `model: haiku`. It has
its own context window, a cheaper model, and cannot edit or run anything.

**Step 3 - name the difference.** One line each, for the discussion:

- The skill changed **how** something was done in your session.
- The agent did a job **somewhere else** and handed back a report.

**Expected result.** A commit message you did not write, a review you did not read
yourself, and one sentence on which mechanism you would reach for next time.

**Take this to your team**

| | In this lab | In your repo |
|---|---|---|
| Trigger | the `description` field, matched against what you typed | Write descriptions as the phrasings people actually use, not as a summary of the skill |
| Skill permissions | `disallowed-tools` genuinely removes tools | `allowed-tools` only pre-approves. It restricts nothing. A skill is not a permission boundary |
| Agent permissions | `tools` is an allowlist, `disallowedTools` a denylist applied first | An agent IS a boundary. That is the real reason to reach for one |
| Model choice | `haiku` for a read-only review | Cheap model for mechanical review, expensive one for planning. Set it per agent, not per session |

**Tip.** When a skill does not fire, the description is the first thing to fix, not the
body. Nobody reads the body until the description matched.

**Trap.** Treating a skill as a sandbox. `allowed-tools` reads like a restriction and is
not one. If you need something to be unable to write, that is an agent.

**Reference.** [skills](https://code.claude.com/docs/en/skills) ·
[subagents](https://code.claude.com/docs/en/sub-agents)

## Task 3 - Write the two skills - your house patterns (8 min)

Two subsystems, two house patterns. Write one skill each. You are not writing code here,
you are writing down the decisions you would otherwise repeat in every prompt.

Create `.claude/skills/add-persistence/SKILL.md` and `.claude/skills/add-view/SKILL.md`.
Each needs frontmatter and a short body:

```markdown
---
name: add-persistence
description: Use when moving a TrackIt resource from in-memory storage to PostgreSQL,
  or when the user says "persist", "store in the database", "add an entity", "add a
  repository", or "add a migration". Applies the TrackIt persistence house pattern.
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

# Add persistence, TrackIt house pattern

## Steps
1. Dependencies, named to the user before they are added
2. Entity as a SEPARATE class beside the record, never annotations on the record
3. Repository interface extending JpaRepository
4. Flyway migration V<n>__<name>.sql, never ddl-auto
5. Service switches to the repository, keeps returning the record
6. Fix the test the change breaks
7. Run the tests and quote the result

## Rules
- ddl-auto is `validate`, never `create` or `update`
- Credentials come from environment variables with a development default
- Never touch frontend/
```

The `add-view` skill has the same shape and encodes the frontend rules from `AGENTS.md`:
typed API module per resource, one view per route, loading and error state rendered, the
route registered only in `router/index.ts`, never `axios` outside `api/`.

**The three fields that decide whether this works:**

| Field | Gets it wrong when | Costs you |
|---|---|---|
| `description` | it summarises instead of listing phrasings | the skill never fires |
| `allowed-tools` | you expect it to restrict | it pre-approves only. Use an agent for a real limit |
| the Rules block | it repeats what the code already shows | tokens on every turn, no behaviour change |

**Check that they are visible.** Ask, in a fresh session:

```text
Which skills do you have available in this project, and when would each one fire?
```

It should name both and paraphrase your trigger phrasings back at you.

*If one is missing:* the path is wrong. It is `.claude/skills/<name>/SKILL.md` - a
directory per skill, and the file is named `SKILL.md` exactly.

**Expected result.** Two skill directories, both listed back to you, each describing a
pattern that is in `AGENTS.md` rather than one you invented here.

**Track E:** copy both scaffolds above and adapt the Rules block.

**Track A:** write both from scratch without the scaffold, and make the rules
falsifiable. For each rule, name the wrong thing the agent would otherwise do.

**Take this to your team**

| | In this lab | In your repo |
|---|---|---|
| What goes in a skill | the procedure: which files, in what order, verified how | The things you re-type into prompts. If you have typed it three times, it is a skill |
| What stays in the context file | the constraints that hold everywhere | Rules go in `AGENTS.md`, procedures in a skill. Mixing them makes both unreadable |
| How you know it works | ask the agent to list its skills | Same. And the first real use is the test, not the writing |
| Review | you read your own | Skills are committed configuration. They belong in pull requests, because a bad skill is wrong in every future session |

**Tip.** Write the description last, after the body, when you know what the skill
actually does. Descriptions written first describe the intention, not the skill.

**Trap.** A skill that restates `AGENTS.md`. Every duplicated line is sent twice and
drifts independently. The skill says how; the context file says what is true.

**Reference.** [skills](https://code.claude.com/docs/en/skills) ·
[settings](https://code.claude.com/docs/en/settings)

## Task 4 - Two agents, one turn, two subsystems (8 min)

Now the part the module is really about. You have two independent jobs. Running them one
after the other wastes half the time you have. Running them together is only safe if you
design it that way.

**Step 1 - write the two agent definitions.**

`.claude/agents/db-builder.md` and `.claude/agents/frontend-builder.md`. You can use
`/agents` to create them interactively, or write the files directly:

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
learn the API shape, follows the `add-view` skill, quotes `npx vue-tsc -b` and
`npm run build`.

**Step 2 - see why the boundary is the whole design.**

The two agents run at the same time in the same working tree. That is safe for exactly
one reason: **their file spaces do not overlap.** One writes `backend/`, the other writes
`frontend/`. Take that away and they overwrite each other's edits with no error and no
warning.

That partition is the thing you are designing. The tool restriction is how you enforce
it.

**Step 3 - dispatch both in one message.**

```text
Use the db-builder agent to move task storage from the in-memory list into
PostgreSQL, and at the same time use the frontend-builder agent to build the task
board: list all tasks and add a new one.

Run them in parallel. Do not edit any file yourself. When both report back, show me
both reports unchanged.
```

Both run in the background and report as they finish. While they work, watch what you
are actually doing: nothing. That is the point of the exercise and it is also the
uncomfortable part.

**Step 4 - read both reports before you run anything.**

Three questions per report:

- Which dependencies did it add, and would you have approved them?
- What did it say it did **not** verify?
- What did it guess?

**Step 5 - verify it yourself. The reports are claims.**

```bash
cd backend && ./mvnw -q test && ./mvnw spring-boot:run
```

In a second terminal:

```bash
cd frontend && npm run dev
```

Open <http://localhost:5173>, add a task, and see it in the list.

**Now the check the tests cannot make.** Stop the backend with `Ctrl+C`, start it again,
and reload the page. The task must still be there.

A green test suite did not prove that. `@WebMvcTest` mocks the service away, so the
whole storage path is absent from the run. **Persistence is proven by a restart, and by
nothing else.**

```bash
docker compose exec db psql -U trackit -d trackit -c 'SELECT * FROM task;'
```

**Step 6 - commit.**

```bash
git add -A && git commit -m "feat: store tasks in postgres and add the task board"
```

**Expected result.** A row in the `task` table that survives a restart, a task board in
the browser, and two agent reports you have actually read.

**Track A:** before you dispatch, give each agent its own git worktree so the partition
is enforced by git rather than by an instruction. See task A1.

**Take this to your team**

| | In this lab | In your repo |
|---|---|---|
| When an agent is worth it | two jobs at once, each reporting back compressed | Parallelism, or a fresh context window. "It is specialised" is not a reason - a skill can be specialised |
| How parallel stays safe | disjoint file spaces, enforced by the tool list | Partition by module, package or service. If you cannot draw the line, run them one after the other |
| What the report is for | claims you then check | Make "what did you NOT verify" a required section. It is the most useful line an agent writes |
| Definition of done | restart the app, not just green tests | Name the check the test suite cannot make, per feature. That is your real acceptance criterion |

**Tip.** Two or three high-leverage agents beat fifteen overlapping ones. Every agent you
add is another definition to keep true as the repo changes.

**Trap.** Two agents in one working tree with overlapping paths. There is no conflict
marker and no error - the second write simply wins, and you find out in review.

**Reference.** [subagents](https://code.claude.com/docs/en/sub-agents) ·
[skills](https://code.claude.com/docs/en/skills)

---

# Part 2 - Standard, 15 minutes

Start this after the MCP input.

## Task 5 - Connect a server where the model is actually weak (8 min)

Your frontend agent just wrote Vue 3 and PrimeVue 4 from memory. Its memory is older
than the versions in `frontend/package.json`. That gap is the case for MCP: not extra
capability, current information.

**Step 1 - pick one server** from `docs/mcp-candidates.md`. Every command there was run
and checked. Context7 is the one that pays off today:

```bash
claude mcp add --scope project --transport http context7 https://mcp.context7.com/mcp
```

`--scope project` writes `.mcp.json` in the repo root. That file is committed, so this
is a team decision, not a local convenience.

**Step 2 - approve it and check it connected.**

```bash
claude mcp list
```

A project-scope server shows as `Pending approval` until you approve it in an
interactive session. A server arriving through a `git pull` does not connect silently.
That prompt is the feature.

**Step 3 - use it on a real question.**

```text
Using the context7 docs, check the PrimeVue 4 API that frontend-builder used in the
task board. Name anything it used that is deprecated or renamed in the version in
package.json, and quote the doc line you got it from.
```

**Expected result.** The server shows connected, and the agent called one of its tools
in a task you can name. Whether it found a problem or not is a fine outcome - "the code
matches the current docs, and here is the line that says so" is a real answer.

**Take this to your team**

| | In this lab | In your repo |
|---|---|---|
| Why connect one | the model's library knowledge is older than your lockfile | The best MCP cases are current information, not more power |
| Scope | `--scope project`, committed | Team decision, reviewed in a pull request. Personal scope is for personal tools |
| Approval | pending until approved interactively | Keep it that way. A server that connects on `git pull` is a supply-chain path |
| Cost | every connected server's tool descriptions sit in context | Check with `/context`. Connect what this repo needs, not what looks useful |

**Tip.** Ask for the quoted doc line, not the conclusion. It turns an unverifiable claim
into a citation you can check in five seconds.

**Trap.** Connecting five servers because they all look useful. Every tool description
is in the context window on every turn, and badly described tools make the agent pick
wrongly.

**Reference.** [MCP](https://code.claude.com/docs/en/mcp) ·
`docs/mcp-candidates.md`

## Task 6 - Scope the access and judge the exposure (7 min)

**Step 1 - answer three questions in writing** for your server. Put them in
`docs/mcp-scoping.md`:

- **Slice.** Which part of the system does it expose? Not "GitHub" - which repositories,
  which resource type.
- **Credential.** Which one does it use, and where does it come from? Your own account,
  a service account, none at all?
- **Direction.** Read-only or writing? And is that enforced by the endpoint, or only
  requested in a prompt?

**Step 2 - narrow it by one step and re-run the task.** With the GitHub server, the
narrowing is in the URL:

```bash
claude mcp remove github
claude mcp add --scope project github --transport http \
  https://api.githubcopilot.com/mcp/x/issues/readonly
```

`/x/issues` selects the toolset, `/readonly` restricts it to read tools. **The limit
lives in the endpoint, not in a prompt.** Re-run your task. It almost certainly still
works, because it only ever needed to read.

**Step 3 - the combined exposure.** Three elements. Tick the ones present in your
session:

- [ ] access to private data
- [ ] content from an untrusted source entering the context
- [ ] a channel to the outside

With all three, content can act as an instruction and data can leave. Removing any one
breaks the chain. Write one verdict line.

**Expected result.** Three answered lines, a task that still works on the narrowed
exposure or a documented reason why it does not, and one exposure verdict.

**Take this to your team**

| | In this lab | In your repo |
|---|---|---|
| The three questions | slice, credential, direction | Ask them before connecting, every time. They take a minute and they are the whole review |
| Where a limit lives | in the endpoint, in the grant, in the token | Never in the prompt. A prompt-level limit is a request, and requests get argued with |
| Vetting | a tool description is third-party text in your context | Review a server before committing it to a team repo. The description is an input, not documentation |
| The chain | private data plus untrusted content plus an outbound channel | Design so all three never meet in one session. That is the practical rule |

**Tip.** Narrow first and see what breaks. Almost nothing does, and you learn what the
task actually needed rather than what it was given.

**Trap.** "It is read-only" because the prompt said so. Read-only is a property of the
endpoint or the database grant. Everything else is a hope.

**Reference.** [MCP](https://code.claude.com/docs/en/mcp) ·
[permissions](https://code.claude.com/docs/en/permissions)

---

# Part 3 - ADVANCED

**Optional.** Start only when Parts 1 and 2 run green and your commit is in place.
Nothing later in the day depends on this part. The tasks are independent - pick what
interests you.

## Task A1 - ADVANCED - Make the partition real with worktrees

*Deepens task 4.*

In task 4 the two agents stayed out of each other's way because you told them to. An
instruction is not a boundary. Give each one a working tree of its own:

```bash
git worktree add ../trackit-db  -b m1-2-db
git worktree add ../trackit-fe -b m1-2-fe
```

Run one agent in each, then merge:

```bash
git merge m1-2-db m1-2-fe
```

Then answer: which conflicts did git surface that the single-tree run would have
silently lost? And what did the isolation cost you - what did the frontend agent no
longer know?

**Take this to your team**

Worktrees are how parallel agent work becomes reviewable. Each branch is a diff a human
can read, and git enforces the partition instead of a paragraph in a markdown file. The
cost is real: an isolated agent cannot see the other one's in-progress contract.

**Trap.** Merging two agent branches without reading either diff. You now have two
unreviewed changes instead of one.

**Reference.** [subagents](https://code.claude.com/docs/en/sub-agents) ·
[git worktree](https://git-scm.com/docs/git-worktree)

## Task A2 - ADVANCED - Bundle both into a plugin and hand it over

*Deepens tasks 3 and 4.*

Your two skills and two agents are the TrackIt house pattern. Right now they exist in
one repository. Bundle them into a plugin and give it to a neighbour, who installs it
and runs it on their own clone.

**Before they install it, the receiving side names out loud what it can reach in their
repository.** That is the review, and it is the whole exercise. A plugin runs with your
permissions, in your repo, on your files.

Then answer: what would you have to know about a plugin from outside your company
before installing it, and how would you find that out?

**Take this to your team**

A skill is for you, a plugin is how the standard reaches everyone else. That is the
answer to "one agent configuration across all our repositories" - but it makes the
review question sharper, not softer, because a bad rule now applies everywhere at once.

**Tip.** Version the plugin and treat an update like a dependency bump. It changes
behaviour in every repository that installed it.

**Trap.** Installing a plugin because a colleague recommended it. The question is not
whether they trust it, it is what its agents can reach in *your* repository.

**Reference.** [plugins](https://code.claude.com/docs/en/plugins) ·
[skills](https://code.claude.com/docs/en/skills)

## Task A3 - ADVANCED - A database role the agent cannot write through

*Deepens task 6. This is the answer to the survey question about protecting database
areas from agent access.*

You now have a real database. Give the agent a way in that cannot write:

```bash
docker compose exec db psql -U trackit -d trackit -c "
  CREATE ROLE trackit_ro LOGIN PASSWORD 'readonly';
  GRANT CONNECT ON DATABASE trackit TO trackit_ro;
  GRANT USAGE ON SCHEMA public TO trackit_ro;
  GRANT SELECT ON ALL TABLES IN SCHEMA public TO trackit_ro;"
```

Then prove the limit rather than trusting it:

```bash
docker compose exec db psql -U trackit_ro -d trackit -c 'SELECT * FROM task;'
docker compose exec db psql -U trackit_ro -d trackit -c "DELETE FROM task;"
```

The second command must fail with a permission error. Now ask the agent to delete all
tasks through that connection and record what comes back.

Then answer: what does this protect, and what does it not? Name one thing a read-only
role still lets an agent do that you might not want.

**Take this to your team**

This is the shape of the answer whenever someone asks how to keep an agent out of a
table. Not a prompt, not a tool description, not a promise from the model - a role with
a grant, and a denial from the database as evidence. A database MCP server pointed at
this role is a different object from one holding the application credential.

**Tip.** `GRANT SELECT ON ALL TABLES` covers today's tables only. New tables are not
included. `ALTER DEFAULT PRIVILEGES` is the part people forget.

**Trap.** Read-only is not harmless. The role can still read every row in every table it
was granted, and that data goes into a context window. Scope the schema too, not only
the direction.

**Reference.** [PostgreSQL GRANT](https://www.postgresql.org/docs/17/sql-grant.html) ·
`docs/mcp-candidates.md`

## Task A4 - ADVANCED - Build a minimal MCP server and look at what it holds

*Deepens task 5.*

Write an MCP server with exactly one tool that returns something from this repo - the
list of Flyway migrations, say. Connect it at project scope and use it.

Then assess it as you would a third-party one: which permissions does it hold right now,
and what happens if its tool description is untrustworthy? Write a tool description that
would plausibly get an agent to do something the user did not ask for. Do not ship it -
the exercise is seeing how short it can be.

**Take this to your team**

Writing one is the fastest way to understand that a tool description is content you are
injecting into your own context window. Everything a server tells the agent about itself
is a claim from a third party.

**Trap.** Reviewing a server by reading its README. The README is not what enters the
context. The tool descriptions are, and they can differ.

**Reference.** [MCP](https://code.claude.com/docs/en/mcp) ·
[Model Context Protocol specification](https://modelcontextprotocol.io/)

---

## Bring to the discussion

Fifteen minutes, and it runs on your answers. Have these ready in a sentence each:

- **Skill or agent - which did you reach for, and on which criterion?**
- **Whose skill did not fire, and what did the description say?**
- **Which server would you not commit to your team repository, and why?**

Two more are worth answering for yourself. They come back in M3 and in the transfer
discussion:

- What did the two agents do while you were not watching, and how would you have noticed
  if one of them had been wrong?
- Which check in your own project can only be made by running the thing, never by the
  test suite?

## Further reading

- Skills: <https://code.claude.com/docs/en/skills>
- Subagents: <https://code.claude.com/docs/en/sub-agents>
- Plugins: <https://code.claude.com/docs/en/plugins>
- MCP: <https://code.claude.com/docs/en/mcp>
- This repo's own decisions: `docs/architecture.md`, `docs/adr/0001-*`,
  `docs/mcp-candidates.md`
