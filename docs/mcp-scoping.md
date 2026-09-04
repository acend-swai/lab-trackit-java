# MCP scoping, one section per server

Reference answers for lab 3, task 3.2. Three lines per server, then a verdict.
A server nobody can describe in three lines does not get committed.

## context7

- Slice: public documentation of open-source libraries. Nothing of ours.
- Credential: none. Anonymous, rate-limited. A key would only raise the limit.
- Direction: read-only. Its two tools resolve a library id and fetch docs.
- Exposure: private data no, untrusted content yes (docs are third-party text),
  outbound channel no. Two of three, so the chain does not close.

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
API - still works. Nothing broke, because the task never needed to write.

That is the useful outcome of the exercise: the write access was never load-bearing,
it was just the default.
