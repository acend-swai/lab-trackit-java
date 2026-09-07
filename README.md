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

| Module | Start | Solution | Stage |
|---|---|---|---|
| M1.1 Agentic loop | `m1-1-start` | `m1-1-solution` | create and list a task, in memory |
| M1.2 Extending and scoping | `m1-2-start` | `m1-2-solution` | second endpoint from your own skill, plus one scoped MCP server |
| M2 Spec first | `m2-start` | `m2-solution` | persistence and validation, spec-driven |
| M3 Infrastructure | `m3-start` | `m3-solution` | container setup, verified locally |
| M4 Capstone | `m4-start` | `m4-solution` | reporting end to end |

`m1-2-mid` is an extra rejoin point inside lab 2: the state after task 2.3, before any MCP
work. Use it if you lose the first half of that lab and want to be with the room again for
the second.

## Requirements

Java 21 and the Maven wrapper in `backend/`, or the devcontainer in `.devcontainer/`.
Nothing else. No database, no frontend - both arrive in later modules.

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

## OpenCode against OpenRouter

Lab 1.1 runs the same task once more through OpenCode against an open-weight model. The
gateway is OpenRouter and your key arrives by mail in `.env`; it starts with `sk-or-v1-`.

`opencode.json` in the repo root reads that key from the environment and lists the models
for the lab.

**Run these two.** Same family, two sizes, so the only variable is how much model is
behind the loop:

| Model id | Size | 4-bit footprint |
|---|---|---|
| `qwen/qwen3-coder-30b-a3b-instruct` | 30B MoE, the small one | 16 GB, measured |
| `qwen/qwen3-coder-next` | 80B MoE, 3B active, 262k context | about 46 GB |

Give both the same task and the same prompt. The question is not which answer is prettier,
it is **where the small model breaks**: tool selection, sticking to `AGENTS.md`, reading
its own error output, or knowing when it is done.

**Then take any others you have time for.** The first three still fit on a workstation, the
last three do not - which is the whole point when the repository may not leave the building:

| Model id | What it is | 4-bit footprint |
|---|---|---|
| `mistralai/devstral-2512` | Devstral 2, 123B dense | about 62 GB |
| `nvidia/nemotron-3-super-120b-a12b` | 120B MoE, 12B active, 1M context | about 60 GB |
| `moonshotai/kimi-k3` | frontier MoE, open weights | far beyond a workstation |
| `deepseek/deepseek-v4-flash` | frontier MoE, open weights | far beyond a workstation |
| `qwen/qwen3.8-max-0902` | Qwen flagship, hosted only | not open weights |

Switch between them in the session with `/models`. The 16 GB figure is measured on our own
hardware; the others are the published 4-bit requirements.

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
