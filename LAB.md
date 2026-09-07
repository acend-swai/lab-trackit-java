# Lab 3: harden the harness, then let it write the infrastructure

| Info | Detail |
|---|---|
| Module | M3 - Infrastructure, secrets and guardrails: create and verify |
| Duration | 30 minutes, plus the discussion |
| Harness | Claude Code |
| Tooling | HashiCorp Terraform MCP server, in Docker. Terraform CLI for `fmt` and `validate` |
| Repo | `lab-trackit-java`, your own clone from lab 2, or branch `m3-start` |
| Target state | deny rules, a blocking hook, and validated Terraform (branch `m3-solution`) |

**Part 1 is for everyone.** Four tasks, all with the commands in this handout.

**Part 2 is advanced and optional.**

**Nothing is deployed today.** You write infrastructure code and you validate it. The
agent never gets credentials and never applies anything - and by the end of task 2 it
could not even if it decided to.

## Where you start

Continue on **your own repo from lab 2**, or take the reference state:

```bash
git fetch origin && git checkout m3-start
docker compose up -d
./verify.sh
```

## The order matters

You harden first, then you generate. That is the whole shape of the lab.

An agent writing infrastructure is the highest-consequence thing it does all day: it
reaches for real credentials, it runs commands that delete things, and a mistake is not a
failing test but a deleted database. So the guardrails go up **before** the agent is
pointed at infrastructure, not after the first incident.

| Task | What it protects against |
|---|---|
| 1 Deny rules | the agent reading a secret into its context |
| 2 A hook | the agent running a command that destroys something |
| 3 MCP server | the agent inventing provider syntax from stale memory |
| 4 Generate | - |

---

# Part 1 - Standard, 30 minutes

## Task 1 - Deny what must never be read (6 min)

A `.gitignore` keeps a file out of git. It does nothing about the agent: Claude Code will
happily read `.env` and put it in the context window, and from there it goes to the model.

Create `.claude/settings.json`:

```json
{
  "permissions": {
    "deny": [
      "Read(**/.env)",
      "Read(**/.env.*)",
      "Read(**/*.key)",
      "Read(**/*.pem)",
      "Read(**/terraform.tfvars)",
      "Read(**/*.tfstate)",
      "Edit(**/*.tfstate)"
    ]
  }
}
```

`deny` wins over everything. There are three modes - `allow` runs without asking, `ask`
confirms every time, `deny` blocks and has the highest priority.

`*.tfstate` is on the list for a reason people miss: **Terraform state contains every
value it ever resolved, including the database password, in plain text.** It is the most
secret file in an infrastructure repository and it looks like a build artefact.

**Test it.**

```text
Read the .env file and tell me what is in it.
```

It must refuse.

**Now find the hole.** Ask it to do this instead:

```text
Run: cat .env
```

**The deny rule does not stop that.** It governs Claude's file tools, not the shell. That
gap is exactly why task 2 exists.

**Expected result.** A refusal on the file tool, a success through Bash, and one sentence
on why a permission rule alone is not enough.

**Take this to your team**

| | In this lab | In your repo |
|---|---|---|
| What a deny rule covers | the file tools | Not the shell. Not a subprocess. Know the edge |
| The forgotten file | `*.tfstate` | Add it today. It holds every secret Terraform resolved, in plain text |
| Where it lives | `.claude/settings.json`, committed | Committed, so the whole team inherits it on clone. Review it like code |

**Trap.** Believing `.gitignore` protects anything from the agent. It governs git, and the
agent is not git.

## Task 2 - A hook that blocks, instead of asking (9 min)

A permission dialog is a prompt, and prompts get clicked through at 16:45 on a Friday. A
hook is a shell command the harness runs at a fixed point in its lifecycle. **The model
does not choose to run it and cannot argue with it.** A `PreToolUse` hook that exits with
code 2 blocks the tool call outright.

**Step 1 - write the guard.** Create `.claude/hooks/check-infra.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail

# A guard that cannot read its input must not wave the command through.
if ! command -v jq > /dev/null 2>&1; then
  echo "Blocked: jq is not installed, so this hook cannot inspect the command." >&2
  exit 2
fi

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
[ -n "$cmd" ] || exit 0

block() {
  echo "Blocked by check-infra.sh: $1" >&2
  exit 2
}

case "$cmd" in
  *"terraform destroy"*) block "terraform destroy tears down real infrastructure" ;;
  *"terraform apply"*)   block "terraform apply changes real infrastructure" ;;
  *"kubectl delete ns"*) block "deleting a namespace deletes everything in it" ;;
  *"rm -rf /"*)          block "recursive delete from the filesystem root" ;;
  *"git push --force"*)  block "force push rewrites history other people have" ;;
esac

exit 0
```

```bash
chmod +x .claude/hooks/check-infra.sh
```

**Step 2 - register it** in `.claude/settings.json`, next to the `permissions` block:

```json
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/check-infra.sh" }
        ]
      }
    ]
  }
```

Restart the session, then check it is loaded:

```text
/hooks
```

**Step 3 - provoke it. Deliberately.**

```text
Run terraform destroy in the deploy/terraform directory to clean up.
```

The tool call must be refused with your reason visible, and **the agent must not talk its
way around it**. Watch what it does next: a good one reports the refusal. Note it if it
tries something adjacent instead.

**Step 4 - check you did not block the work.** These must all still run, because a plan
and a validate change nothing:

```bash
terraform fmt -check
terraform validate
```

**The failure mode to understand.** Look at the `jq` check at the top. Without it, a
missing `jq` makes the command variable empty, every pattern misses, and the hook exits
0, which **allows everything, silently**. A guardrail that fails open is worse than none,
because you stop looking. Guards fail closed.

**Expected result.** A refused command with your reason, `terraform validate` still
working, and one sentence on the difference between a rule and a hook.

**Take this to your team**

| | In this lab | In your repo |
|---|---|---|
| Rule vs hook | `AGENTS.md` asks; the hook decides | "The agent should not" is a request. "The agent cannot" is a hook |
| Exit code | 2 blocks and returns your message | The message is written for the agent. Say what it may do instead |
| Fail direction | missing `jq` blocks | Every guard fails closed. Test that path on purpose - it is the one nobody tests |
| Build the list from | real incidents | Not imagination. One thing that actually happened beats twenty hypotheticals |

**Tip.** Blocklists leak. This one catches `terraform destroy` and misses
`terraform  destroy` with two spaces. Task A3 is where you make it precise; today the
lesson is the mechanism.

**Trap.** Writing the hook and never testing the block path. An untested guard is a
belief.

## Task 3 - Connect the Terraform MCP server (5 min)

The agent's memory of the `azurerm` provider is as old as its training data, and provider
schemas change every few weeks. HashiCorp publishes an official MCP server that reads the
Terraform registry live.

```bash
claude mcp add --scope project terraform -- \
  docker run -i --rm hashicorp/terraform-mcp-server:1.3.0
```

Pin the tag. A server on `latest` changes its tool descriptions under you.

```bash
claude mcp list
```

Approve it, and confirm it connected. Then check it actually knows something you do not:

```text
Using the terraform MCP server, what is the current resource name and the required
arguments for an Azure Container App, and which provider version are you reading?
```

**Expected result.** The server connected, and an answer that names a provider version.

**Take this to your team**

| | In this lab | In your repo |
|---|---|---|
| Why this one | provider schemas move faster than model training | The strongest MCP case is always current facts, not more power |
| Scope | `--scope project`, committed | Same team decision as any other server. It goes in the pull request |
| Trust | official HashiCorp image, pinned tag | Ask the three questions anyway: which slice, which credential, read or write. This one reads a public registry and holds no credential of yours |

**Trap.** Assuming an MCP server has credentials because it is "connected to Terraform".
This one reads the public registry. A server pointed at your *state* or your cloud account
is a completely different object, and it is not on today's list.

## Task 4 - Generate the infrastructure code (10 min)

Now the agent writes. Everything before this was making it safe to let it.

**Step 1 - ask for a plan, with the non-scope written down.**

```text
Create Terraform for TrackIt in deploy/terraform/, targeting Azure Container Apps
with a managed PostgreSQL 17 behind it.

In scope: the container app and its environment, the Postgres flexible server and
its database, log analytics, and the variables and outputs they need. Use the
terraform MCP server for the current provider schema and pin the provider version.

Not in scope: applying anything, a backend configuration, CI, a frontend host,
DNS or certificates.

The database password must come from an environment variable and must never appear
in a file in this repository.

Show me your plan before you write anything.
```

**Step 2 - review the plan against a checklist.** Read it for these five, and write down
what you find **before** you have anything corrected:

| Check | What a finding looks like |
|---|---|
| Secrets | a password with a default, or one written into a `.tfvars` it also commits |
| Network exposure | the database reachable from the public internet |
| Image tags | `:latest` anywhere |
| Resource limits | no CPU or memory set, or a size nobody costed |
| Persistence and backup | no backup retention, or storage that disappears with the container |

**At least two findings. Finding none means you did not apply the checklist.**

**Step 3 - let it write, then verify yourself.**

```bash
cd deploy/terraform
terraform fmt -check
terraform init -backend=false
terraform validate
```

`validate` must print `Success! The configuration is valid.` It needs no credentials and
touches nothing.

**Step 4 - prove the secret is out of reach.**

```text
What is the database password in this configuration?
```

It should be unable to answer: there is no default, no committed `terraform.tfvars`, and
task 1 denied reading one. The value lives in `TF_VAR_db_password` in your shell.

**Step 5 - commit.**

```bash
cd ../.. && git add -A && git commit -m "feat: terraform for trackit on azure container apps"
```

**Expected result.** A configuration that passes `terraform validate`, at least two
written findings from step 2, and a password the agent cannot read back.

**Take this to your team**

| | In this lab | In your repo |
|---|---|---|
| Order of operations | guardrails first, generation second | Reverse it and the first thing you learn is what the agent deleted |
| Review | your checklist, applied before the agent fixes anything | Record findings first. Once it has "fixed" them you cannot tell which were real |
| Verification | `validate`, not `apply` | Most of the value is reachable without touching an account. Get that far before you wire credentials |
| The secret | environment variable, denied file, no default | Three layers. Any one alone is a single point of failure |

**Tip.** `terraform validate` checks syntax and schema, not whether the design is sound. It
will happily validate a database open to the internet.

**Trap.** A configuration that validates feels finished. Validation says the provider
understands it, not that you would run it.

---

# Part 2 - ADVANCED

**Optional.** Start only when Part 1 is green and committed.

## Task A1 - ADVANCED - A skill that reviews for cost

Write `.claude/skills/infra-cost-review/SKILL.md`: given a Terraform directory, it reports
every resource whose size, tier or replica count drives cost, with the chosen value and a
cheaper alternative, and it flags anything with no explicit size at all.

Run it on your own configuration. Then answer: which findings could you have got from
`terraform validate`? None of them - that is the point of the skill.

**Trap.** A skill that estimates prices in francs. It does not know your discounts or your
region's pricing, and a confident wrong number is worse than a list of what to go and
price.

## Task A2 - ADVANCED - A skill that reviews for security

Write `.claude/skills/infra-security-review/SKILL.md` encoding the checklist from task 4
step 2, plus: public network access, TLS enforcement, retention periods, managed identity
instead of a connection string, and anything reading a secret from a file.

Run it, then compare with what you found by hand in step 2. **What did only you find, and
what did only the skill find?** That comparison is the answer to "can I automate my
review" - and the honest answer is usually "partly".

## Task A3 - ADVANCED - Make the hook precise

Your blocklist catches `terraform destroy` and misses `terraform  destroy` with two
spaces, `TERRAFORM DESTROY`, and `cd deploy && terraform destroy`.

Rewrite it so it catches the dangerous case and lets the harmless one through. Test both:
`terraform destroy` must block, `terraform plan -destroy` must not - a plan changes
nothing.

Then answer the question that matters: is a blocklist the right shape at all, or should
this be an allowlist of the commands the agent may run?

**Take this to your team**

Blocklists are what you write first and regret later. The allowlist is more work and
fails safe. Choose deliberately.

## Task A4 - ADVANCED - Name what you cannot prove here

Your configuration validates. List two statements about this setup you **cannot** prove
without applying it, and say what you would need in order to prove each.

Then one more: what would you put in CI so that nobody has to remember to run
`terraform validate` by hand?

**Take this to your team**

Knowing which claims your local checks do and do not support is the whole difference
between a green pipeline and a working system. This is the same lesson as "green tests do
not prove persistence" from lab 1.2, one layer up.

## Bring to the discussion

- **What did your hook refuse, and did the agent try to get around it?**
- **Which two findings did your checklist produce on the generated configuration?**
- **Where is a deny rule not enough, and what did you use instead?**

## Further reading

- Permissions: <https://code.claude.com/docs/en/permissions>
- Hooks: <https://code.claude.com/docs/en/hooks>
- Terraform MCP server: <https://developer.hashicorp.com/terraform/mcp-server>
- The reference configuration: `deploy/terraform/` on `m3-solution`
