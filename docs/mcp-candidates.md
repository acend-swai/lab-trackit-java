# MCP server candidates for lab 3

Pick ONE. Every command below was run against Claude Code v2.1.258 on 4 September 2026
and the resulting `.mcp.json` was checked. Versions are pinned on purpose - a server that
floats on `@latest` can change its tool descriptions under you.

`--scope project` writes `.mcp.json` in the repo root. That file is committed, so this is
a team decision, not a local convenience.

## 1. Documentation - Context7 (read-only, remote, no key needed)

```bash
claude mcp add --scope project --transport http context7 https://mcp.context7.com/mcp
```

Tools: `resolve-library-id`, `query-docs`. Cannot write anything.
Good first choice if you have no real system-of-record case in mind.

If it rate-limits (the whole room shares one address), ask the trainer for the key and add
`--header "Authorization: Bearer <key>"`.

## 2. Filesystem - scoped to one directory (CAN WRITE)

```bash
claude mcp add --scope project filesystem \
  -- npx -y @modelcontextprotocol/server-filesystem@2026.8.31 "$PWD/sandbox"
```

The allowed directory is a positional argument, not a flag. Several are space-separated.
`sandbox/` exists in this repo for exactly this - do not point it at your home directory.

Tools include `write_file`, `edit_file`, `move_file`. This is the candidate to pick if you
want to feel what "it can write" means when you narrow it in task 3.2.

## 3. Browser - Playwright (CAN WRITE, in the sense that matters)

```bash
claude mcp add --scope project playwright \
  -- npx -y @playwright/mcp@0.0.80 --isolated
```

`--isolated` keeps the profile in memory. Without it, two clients in the same workspace
fight over one browser profile.

It drives a real browser, so it clicks and submits on any site you are logged into. Point
it at a public page, never at a tab with your own session.

## 4. Issue tracker - GitHub, issues only, read-only

```bash
claude mcp add --scope project github --transport http \
  https://api.githubcopilot.com/mcp/x/issues/readonly
claude mcp login github
```

The scope is in the URL: `/x/issues` selects the toolset, `/readonly` restricts it to read
tools. That is the shape to remember - the limit lives in the endpoint, not in a prompt.

Full access would be `https://api.githubcopilot.com/mcp/` with OAuth or a token. Do not
use that one today.

## Not on this list, and why

- `@modelcontextprotocol/server-github` is deprecated and frozen at 2025.4.8. The
  `modelcontextprotocol/servers` README still shows it in an example further down the same
  file that archives it. If you copy from there, you install a dead package.
- Atlassian's server is OAuth-only with no token path, which does not fit a 15-minute slot.

## What to expect

A project-scope server shows as `Pending approval` in `claude mcp list` until you approve
it in an interactive session. A server arriving through a `git pull` does not connect
silently - that is the point of the prompt.
