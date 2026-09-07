# Claude Code reference

The commands, keys and files you use in Claude Code. Keep this after the workshop.

Versions differ. Run `/help` for what your build has, and `claude --version` to see which
build that is. This page was written against 2.1.263.

## Slash commands

Type these into the normal prompt. Most queue behind a running turn.

| Command | What it does | Where today |
|---|---|---|
| `/init` | Reads the repo and writes a `CLAUDE.md` describing it | Lab 1.1, lab 1.2 |
| `/context` | What fills the context window right now | Lab 1.1, lab 1.2 |
| `/compact` | Summarises the session and frees the window. Takes a focus, `/compact keep the API design` | |
| `/clear` | Throws the conversation away and starts fresh. Costs nothing | |
| `/usage` | Tokens and cost for this session. `/cost` shows the same session block | Lab 1.1 |
| `/model` | Switches the model mid-session | Lab 1.1 |
| `/effort` | Sets thinking effort: low, medium, high, max | |
| `/permissions` | Allow, ask and deny rules per tool | Lab 1.1, lab 3 |
| `/hooks` | Shows the hooks that are loaded, and whether yours registered | Lab 3 |
| `/agents` | Lists and edits subagents | Lab 1.2 |
| `/mcp` | MCP server status, and reconnects them | Lab 1.2, lab 3 |
| `/plugin` | Installs and manages plugins and marketplaces | Lab 1.2, lab 3 |
| `/rewind` | Steps back to an earlier checkpoint, conversation and code | |
| `/resume` | Switches to another saved conversation | |
| `/help` | Every command your build has | Lab 2 |

**Tip:** `/clear` between unrelated tasks. Stale context is sent again on every turn, so it
costs tokens on work it has nothing to do with.

## Keys and input

| Key | What it does |
|---|---|
| `Esc` | Interrupts mid-turn and keeps the work so far. Closes a dialog, declines a prompt |
| `Esc` `Esc` | On an empty prompt, opens the rewind menu. With text, clears the draft |
| `Shift+Tab` | Cycles the permission mode. See the table below |
| `Ctrl+R` | Searches your command history |
| `Ctrl+C` | Interrupts. Twice on an empty prompt, exits Claude Code |
| `Ctrl+D` | Exits Claude Code |
| `@` | Opens the file picker, and puts that file in context |
| `!` | Runs the rest of the line as a shell command, without a turn |
| `#` | Writes the rest of the line to memory |

## Permission modes

`Shift+Tab` cycles them. The status bar names the active one:

| Status bar | Mode | What runs without asking |
|---|---|---|
| `⏸ manual mode on` | `default` | Reads only. You approve every edit and command |
| `⏵⏵ auto mode on` | `auto` | A classifier model reviews actions instead of you |
| `⏵⏵ accept edits on` | `acceptEdits` | File edits, plus `mkdir`, `touch`, `mv`, `cp` |
| `⏸ plan mode on` | `plan` | Reads and explores, writes a plan, edits nothing |

On a Pro, Max or Team plan a session starts in **auto mode**. The first `Shift+Tab` press
takes you from auto to manual, and the cycle then runs manual, accept edits, plan, and back
to manual. Auto mode rejoins the cycle at the end.

**Warning.** `bypassPermissions` skips every check. It is not in the cycle, and it belongs
in a container or VM, never on your working machine.

## Context files

| File | Scope | What it is for |
|---|---|---|
| `CLAUDE.md` | Project, committed | The rules Claude Code reads on every turn |
| `AGENTS.md` | Project, committed | The same rules, read by OpenCode and others |
| `CLAUDE.local.md` | Project, yours | Your own notes. Belongs in `.gitignore` |
| `~/.claude/CLAUDE.md` | You, every project | Your own conventions, everywhere |
| `.claude/settings.json` | Project, committed | Permissions, hooks, plugins for the team |
| `.claude/settings.local.json` | Project, yours | Your overrides. Belongs in `.gitignore` |
| `.mcp.json` | Project, committed | The MCP servers this project uses |

Claude Code reads `CLAUDE.md`, not `AGENTS.md`. To keep one file instead of two, make
`CLAUDE.md` a one-line pointer:

```bash
printf '@AGENTS.md\n' > CLAUDE.md
```

Check it:

```bash
cat CLAUDE.md
```

The output should be:

```text
@AGENTS.md
```

That is what this lab repo does, so Claude Code and OpenCode read the same rules.

## Running it

| Command | What it does |
|---|---|
| `claude` | Starts an interactive session |
| `claude -c` | Continues the most recent conversation here |
| `claude --resume` | Opens the session picker |
| `claude -p "<prompt>"` | Runs one prompt, prints the answer, exits |
| `claude --model opus` | Starts on a named model. Takes `opus`, `sonnet`, `haiku` |
| `claude --permission-mode plan` | Starts in a mode. Also `manual`, `auto`, `acceptEdits` |
| `claude --version` | The build you are on |

Headless mode reads stdin, which is how Claude Code goes into a script or a pipeline:

```bash
echo "Reply with exactly: OK" | claude -p --model haiku
```

The output should be:

```text
OK
```

Pipe a real file the same way, for example `cat build.log | claude -p "explain this error"`.

**Tip:** `claude -p` with `--output-format json` gives you a parseable result, which is what
you want in CI rather than prose.

## Extending it

Each of these is a file in the repo, so it is reviewed and committed like code.

| Extension | Lives in | What it is |
|---|---|---|
| Skill | `.claude/skills/<name>/SKILL.md` | A procedure Claude loads when it is relevant |
| Subagent | `.claude/agents/<name>.md` | A separate agent with its own context and tools |
| Hook | `.claude/hooks/*.sh` | A script that runs on an event, and can refuse the action |
| Custom command | `.claude/commands/<name>.md` | Your own slash command |
| MCP server | `.mcp.json` | An external tool or data source |
| Plugin | Installed with `/plugin` | Skills, agents, hooks and MCP servers bundled together |

Lab 1.2 builds skills, subagents, an MCP connection and a plugin. Lab 3 builds a hook that
refuses an action.

**Trap:** Everything in a context file is sent on every turn. A permission dialog is a
prompt, and prompts get clicked through. What actually stops a command is a hook that
refuses it.

## Further reading

- Slash commands: <https://code.claude.com/docs/en/commands>
- Keyboard shortcuts: <https://code.claude.com/docs/en/keybindings>
- Permission modes: <https://code.claude.com/docs/en/permission-modes>
- Costs and usage: <https://code.claude.com/docs/en/costs>
- Memory and `CLAUDE.md`: <https://code.claude.com/docs/en/memory>
- Headless mode: <https://code.claude.com/docs/en/headless>
- Skills: <https://code.claude.com/docs/en/skills>
- Hooks: <https://code.claude.com/docs/en/hooks>
