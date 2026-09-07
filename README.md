# lab-trackit-java

Lab repository for the workshop **Agentic Coding in Practice**, Workshop-Tage 2026.

TrackIt is a small task management tool. A task has a title, a project and a status.
The application grows over the workshop: one module adds one stage.

## Branches

The lab instruction for the branch you are on is in **[LAB.md](LAB.md)** in this root.

`main` is the same commit as `m1-1-start`, so a plain clone starts you where the day
starts. Each module has a `-start` branch and a `-solution` branch; every `-start` branch
compiles and its tests pass before you touch anything.

```bash
git clone -b m1-1-start https://github.com/acend-swai/lab-trackit-java.git trackit
```

The repo is public, so this needs no account and no token. Clone it in full - a `--depth`
clone has no `origin/m1-1-solution` to compare against and no `origin/m2-start` to fall
back to. Your clone is yours: nothing you commit reaches this repo, and if you want to
keep your work, add a remote of your own and push there.

| Module | Start | Solution | Stage |
|---|---|---|---|
| M1.1 Agentic loop | `m1-1-start` | `m1-1-solution` | create and list a task, in memory |
| M1.2 Extending and scoping | `m1-2-start` | `m1-2-solution` | tasks in PostgreSQL and a task board in the browser, built with the skills the repo ships |
| M2 Spec first | `m2-start` | `m2-solution` | comments on tasks, specified before written |
| M3 Infrastructure | `m3-start` | `m3-solution` | deny rules, a blocking hook, and Terraform that validates |

`m1-2-mid` is an extra rejoin point inside lab 1.2: the state after task 4, with the
database and the frontend built, before any MCP work. Check out that branch to continue
the second half of the lab from a known-good state.

`m4-full-agentic` is a standalone branch on top of `m3-solution` - it carries M1.1, M1.2,
M2 and M3 in full, not a fresh checkout. It extends the OpenSpec workflow and the
`check-infra.sh` guardrails from M2 and M3 with a named agent roster
(planner/implementer/tester/security) shared byte-for-byte between Claude Code and GitHub
Copilot, a Definition-of-Done gate enforced in CI, CODEOWNERS protecting the harness and
infrastructure code from an agent's own edits, and a merge to `main` that publishes a
container image to GHCR - never applying the Terraform underneath it.

```bash
git clone -b m4-full-agentic https://github.com/acend-swai/lab-trackit-java.git trackit-capstone
```

On that branch, `docs/adr/0002-full-agentic-capstone-platform.md` records what the setup
is and deliberately is not, `docs/adr/0003-agent-security-boundary.md` the security
boundary, and `openspec/changes/add-task-summary/` holds an unimplemented feature the
branch ships ready to build.

## Requirements

Java 21 and the Maven wrapper in `backend/`, Node 22 for `frontend/`, and Docker for the
database - or the devcontainer in `.devcontainer/`, which brings all three.

`m1-1-*` needs none of it beyond Java: the database and the frontend arrive on the lab 1.2
branches, and `verify.sh` only checks for them where they exist.

## Package namespace

Java code lives under `ch.acend.trackit`, matching the `acend-swai` organisation this
repository belongs to.

## The database

From `m1-2-start` onward the repo carries `compose.yaml` with a single Postgres service:

```bash
docker compose up -d
docker compose ps          # STATUS must read "healthy"
```

That is the database only. The application has no container of its own yet. M3 writes
the infrastructure code for it - Terraform against Azure Container Apps - and validates
it without applying anything.

## Lab handouts

`LAB.md` in the repo root is the handout for the branch you are on. Each branch carries
its own, so switching branches switches the handout with it.

## Verify before the lab

```bash
./verify.sh
```

Every line must read `[OK]`. The build check downloads dependencies on the first run,
so do this before the workshop day, not during it.

## Run it

```bash
cd backend
./mvnw spring-boot:run
curl -s localhost:8080/api/v1/health
```

Answers `{"status":"ok"}`. On `m1-1-start` that is the only endpoint - that is correct.

From `m1-2-solution` onward the frontend runs alongside it:

```bash
cd frontend
npm run dev            # http://localhost:5173
```

The Vite dev server proxies `/api` to port 8080, so the browser sees one origin.

## Your `.env`

Your personal `.env` arrives by mail on the morning of the workshop. Put it in the repo
root, next to this README. It is in `.gitignore`.

Claude Code runs against the Anthropic API directly, no gateway. With your own licence,
log in with your account and leave `ANTHROPIC_API_KEY` empty - a key set there overrides
your subscription. Without a licence, use the key from your mail. The OpenRouter key
belongs to OpenCode alone.

## Context file

`AGENTS.md` holds the project context: stack, layering, coding standards, the git rules
and the entity model. `CLAUDE.md` is one line, `@AGENTS.md`, so Claude Code and OpenCode
read the same file and there is only one place to change it. Task 1 of lab 1.1 compares a
run without that context against a run with it; task 2 has `/init` generate one and asks
what it could not know.

It matters twice over from lab 1.2: every agent you start inherits this file, so a gap in
it becomes the same gap in every agent at once.

## OpenCode against OpenRouter

Lab 1.1 runs the same task once more through OpenCode against an open-weight model. The
gateway is OpenRouter and your key arrives by mail in `.env`; it starts with `sk-or-v1-`.

`opencode.json` in the repo root reads that key from the environment and lists the models
for the lab.

**Run these two.** Both are open weights, but only one of them runs on hardware you own,
so the variable is how much model the loop can afford when the repository may not leave the
building:

| Model id | Size | 4-bit footprint |
|---|---|---|
| `moonshotai/kimi-k3` | frontier MoE, open weights | far beyond a workstation |
| `qwen/qwen3-coder-next` | 80B MoE, 3B active, 262k context | about 46 GB |

Give both the same task and the same prompt. The question is not which answer is prettier,
it is **where the smaller model breaks**: tool selection, sticking to `AGENTS.md`, reading
its own error output, or knowing when it is done.

**Then take any others you have time for.** The first two still fit on a workstation, the
last two do not:

| Model id | What it is | 4-bit footprint |
|---|---|---|
| `mistralai/devstral-2512` | Devstral 2, 123B dense | about 62 GB |
| `nvidia/nemotron-3-super-120b-a12b` | 120B MoE, 12B active, 1M context | about 60 GB |
| `deepseek/deepseek-v4-flash` | frontier MoE, open weights | far beyond a workstation |
| `qwen/qwen3.8-max-0902` | Qwen flagship, hosted only | not open weights |

Switch between them in the session with `/models`. The footprints are the published 4-bit
requirements.

OpenCode reads the environment, not the file. In the devcontainer this is done for you:
every new terminal sources `.env`, bash or zsh, login shell or not, and it is re-read on
each shell start - so a key you paste in later works in the next terminal, no rebuild.
Open a fresh terminal after editing `.env`.

Outside the container, export it yourself before starting OpenCode:

```bash
set -a; source .env; set +a
opencode
```

Docs: <https://openrouter.ai/docs/cookbook/coding-agents/opencode-integration>
