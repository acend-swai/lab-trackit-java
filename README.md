# lab-trackit-java

Lab repository for the workshop **Agentic Coding in Practice**, Workshop-Tage 2026.

TrackIt is a small task management tool. A task has a title, a project and a status.
The application grows over the workshop: one module adds one stage.

## Branches

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
read the same file and there is only one place to change it. Lab 1.1 uses it as the
grounding for the second half of the comparison. Lab 1.2 writes one from scratch.

## OpenCode against OpenRouter

Lab 1.1 runs the same task once more through OpenCode against an open-weight model. The
gateway is OpenRouter and your key arrives by mail; it starts with `sk-or-v1-`.

Store it once, inside OpenCode:

```bash
opencode
/connect
```

Search for OpenRouter and paste the key. It is saved to
`~/.local/share/opencode/auth.json`, not read from `.env`.

`opencode.json` in the repo root already lists the three models for the lab. Switch
between them in the session with `/models`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "openrouter": {
      "models": {
        "qwen/qwen3.8-max-0902": {},
        "moonshotai/kimi-k3": {},
        "deepseek/deepseek-v4-flash": {}
      }
    }
  }
}
```

Docs: <https://openrouter.ai/docs/cookbook/coding-agents/opencode-integration>
