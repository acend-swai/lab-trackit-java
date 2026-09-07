# MCP scoping, one section per server

Reference answers for lab 1.2, task 6. Three lines per server, then a verdict.
A server nobody can describe in three lines does not get committed.

## context7

- Slice: public documentation of open-source libraries. Nothing of ours.
- Credential: none. Anonymous, rate-limited. A key would only raise the limit.
- Direction: read-only. Its two tools resolve a library id and fetch docs.
- Exposure: private data no, untrusted content yes (docs are third-party text),
  outbound channel no. Two of three, so the chain does not close.

Why it was worth connecting here: `frontend-builder` writes Vue 3 and PrimeVue 4.
Without this server it writes them from memory, and memory is older than
`frontend/package.json`. With it, the agent reads the current API. That is the whole
case for an MCP server in one sentence - it is not extra capability, it is current
information.

## github

- Slice: issues, and only issues. The toolset is selected in the URL path,
  `/x/issues`, and `/readonly` keeps it to read tools.
- Credential: my own account through OAuth, so it sees what I see. For a team
  setup this should be a service account with repository-level access.
- Direction: read-only, enforced by the endpoint rather than by a prompt.
- Exposure: private data yes (our issues), untrusted content yes (issue text is
  written by anyone who can open one), outbound channel no while it stays
  read-only. Adding a writing server to the same session closes the chain.

## What narrowing changed

Before: `https://api.githubcopilot.com/mcp/` with the full toolset. The agent could
comment and close issues.

After: `/x/issues/readonly`. The task - summarise the open issues that touch the task
API - still works, because it only ever needed to read. The write tools were never
used; they were only available. That is the usual finding, and it is the argument for
narrowing by default rather than after an incident.

## The database

Not connected through MCP in this lab, and the reason is the point. TrackIt now has a
real PostgreSQL, so the tempting move is to hand the agent a database server. Ask the
three questions first:

- Slice: which schema, which tables. `trackit`, one table, is a different object from
  a production schema with customer rows in it.
- Credential: the application's own connection string reaches everything the
  application reaches. A dedicated role reaches what you granted it.
- Direction: `GRANT SELECT` is read-only in a way that survives a persuasive prompt.
  "Please only read" is not.

The limit lives in the grant, in the same way the GitHub limit lives in the endpoint.
Task A3 builds the read-only role and proves it by making the agent attempt a write.
A denial coming back from PostgreSQL is evidence. An agent promising not to write is
not.
