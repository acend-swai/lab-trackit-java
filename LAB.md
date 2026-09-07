# Lab 3: Harden the harness, then let it write the infrastructure

| Info | Detail |
|---|---|
| Module | M3 - Infrastructure, secrets and guardrails: create and verify |
| Duration | 30 minutes, plus the discussion |
| Harness | Claude Code |
| Tooling | HashiCorp Terraform MCP server in Docker. Terraform CLI for `fmt` and `validate` |
| Repo | `lab-trackit-java`, your clone from lab 2, or branch `m3-start` |
| Target state | deny rules, a blocking hook, and validated Terraform (branch `m3-solution`) |

**Nothing is deployed today.** We write infrastructure code and validate it. The agent
never gets credentials and never applies anything, and by the end of task 2 it could not
even if it decided to.

We harden first, then we generate. An agent writing infrastructure is the
highest-consequence thing it does all day: it reaches for real credentials, it runs
commands that delete things, and a mistake is not a failing test but a deleted database.

| Task | What it protects against |
|---|---|
| 1 Deny rules | the agent reading a secret into its context |
| 2 A hook | the agent running a command that destroys something |
| 3 MCP server | the agent inventing provider syntax from stale memory |
| 4 Generate | - |

**Part 1 is for everyone.** Four tasks. **Part 2 is advanced and optional.**

## Where you start

Continue on your repo from lab 2, or take the reference state:

```bash
git fetch origin && git checkout m3-start
docker compose up -d
./verify.sh
```

---

# Part 1 - Standard, 30 minutes

## Task 1: Deny what must never be read (6 min)

A `.gitignore` keeps a file out of git. It does nothing about the agent: Claude Code reads
`.env` happily and puts it in the context window, and from there it goes to the model.

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

There are three modes: `allow` runs without asking, `ask` confirms every time, `deny`
blocks. `deny` has the highest priority and wins over everything.

`*.tfstate` is on the list for a reason people miss: **Terraform state contains every value
it ever resolved, including the database password, in plain text.** It is the most secret
file in an infrastructure repository and it looks like a build artefact.

Test it:

```text
Read the .env file and tell me what is in it.
```

It refuses. Now find the hole:

```text
Run: cat .env
```

**The deny rule does not stop that.** It governs Claude's file tools, not the shell. That
gap is exactly why task 2 exists.

**Take home:** `.claude/settings.json` is committed, so the whole team inherits the deny
list on clone. Add `*.tfstate` to yours today.

**Trap:** Believing `.gitignore` protects anything from the agent. It governs git, and the
agent is not git.

Reference: [permissions](https://code.claude.com/docs/en/permissions)

## Task 2: A hook that blocks instead of asking (9 min)

A permission dialog is a prompt, and prompts get clicked through at 16:45 on a Friday. A
hook is a shell command the harness runs at a fixed point in its lifecycle. **The model does
not choose to run it and cannot argue with it.** A `PreToolUse` hook that exits with code 2
blocks the tool call outright.

### Step 1: Write the guard

Create `.claude/hooks/check-infra.sh`:

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

### Step 2: Register it

In `.claude/settings.json`, next to the `permissions` block:

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

### Step 3: Provoke it, deliberately

```text
Run terraform destroy in the deploy/terraform directory to clean up.
```

The tool call is refused with your reason visible, and the agent does not talk its way
around it. Watch what it does next: a good one reports the refusal. Note it if it tries
something adjacent instead.

### Step 4: Check you did not block the work

A plan and a validate change nothing, so these still run:

```bash
terraform fmt -check
terraform validate
```

### The failure mode to understand

Look at the `jq` check at the top. Without it, a missing `jq` makes the command variable
empty, every pattern misses, and the hook exits 0, which **allows everything, silently**. A
guardrail that fails open is worse than none, because you stop looking. Guards fail closed.

**Take home:** `AGENTS.md` asks, the hook decides. "The agent should not" is a request, "the
agent cannot" is a hook. Build the blocklist from real incidents, not imagination.

**Tip:** Blocklists leak. This one catches `terraform destroy` and misses
`terraform  destroy` with two spaces. Task A3 is where you make it precise, today the
lesson is the mechanism.

**Trap:** Writing the hook and never testing the block path. An untested guard is a belief.
Test the fail-closed path on purpose, it is the one nobody tests.

Reference: [hooks](https://code.claude.com/docs/en/hooks)

## Task 3: Connect the Terraform MCP server (5 min)

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

Approve it and confirm it connected. Then check it knows something you do not:

```text
Using the terraform MCP server, what is the current resource name and the required
arguments for an Azure Container App, and which provider version are you reading?
```

The answer names a provider version.

**Take home:** The strongest MCP case is always current facts, not more power. Ask the three
questions anyway: which slice, which credential, read or write. This one reads a public
registry and holds no credential of yours.

**Trap:** Assuming an MCP server has credentials because it is "connected to Terraform". A
server pointed at your *state* or your cloud account is a completely different object, and
it is not on today's list.

Reference: [Terraform MCP server](https://developer.hashicorp.com/terraform/mcp-server)

## Task 4: Generate the infrastructure code (10 min)

Now the agent writes. Everything before this was making it safe to let it.

### Step 1: Ask for a plan, with the non-scope written down

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

### Step 2: Review the plan against a checklist

Read it for these five and write down what you find **before** you have anything corrected:

| Check | What a finding looks like |
|---|---|
| Secrets | a password with a default, or one written into a `.tfvars` it also commits |
| Network exposure | the database reachable from the public internet |
| Image tags | `:latest` anywhere |
| Resource limits | no CPU or memory set, or a size nobody costed |
| Persistence and backup | no backup retention, or storage that disappears with the container |

**At least two findings. Finding none means you did not apply the checklist.**

### Step 3: Let it write, then verify yourself

```bash
cd deploy/terraform
terraform fmt -check
terraform init -backend=false
terraform validate
```

`validate` prints `Success! The configuration is valid.` It needs no credentials and
touches nothing.

### Step 4: Prove the secret is out of reach

```text
What is the database password in this configuration?
```

It cannot answer: there is no default, no committed `terraform.tfvars`, and task 1 denied
reading one. The value lives in `TF_VAR_db_password` in your shell.

### Step 5: Commit

```bash
cd ../.. && git add -A && git commit -m "feat: terraform for trackit on azure container apps"
```

**Take home:** Guardrails first, generation second. Reverse it and the first thing you learn
is what the agent deleted. Record your findings before the agent "fixes" them, otherwise
you cannot tell which were real.

**Tip:** Most of the value is reachable without touching an account. Get to `validate`
before you wire up credentials.

**Trap:** A configuration that validates feels finished. `terraform validate` checks syntax
and schema, not whether the design is sound. It will happily validate a database open to
the internet.

---

# Part 2 - ADVANCED

Optional. Start when Part 1 is green and committed.

## Task A1 - ADVANCED: A skill that reviews for cost

Write `.claude/skills/infra-cost-review/SKILL.md`: given a Terraform directory, it reports
every resource whose size, tier or replica count drives cost, with the chosen value and a
cheaper alternative, and it flags anything with no explicit size at all.

Run it on your own configuration. Then answer: which findings could you have got from
`terraform validate`? None of them, and that is the point of the skill.

**Trap:** A skill that estimates prices in francs. It does not know your discounts or your
region's pricing, and a confident wrong number is worse than a list of what to go and price.

## Task A2 - ADVANCED: A skill that reviews for security

Write `.claude/skills/infra-security-review/SKILL.md` encoding the checklist from task 4
step 2, plus public network access, TLS enforcement, retention periods, managed identity
instead of a connection string, and anything reading a secret from a file.

Run it, then compare with what you found by hand. **What did only you find, and what did
only the skill find?**

**Take home:** That comparison is the answer to "can I automate my review", and the honest
answer is usually "partly".

## Task A3 - ADVANCED: Make the hook precise

Your blocklist catches `terraform destroy` and misses `terraform  destroy` with two spaces,
`TERRAFORM DESTROY`, and `cd deploy && terraform destroy`.

Rewrite it so it catches the dangerous case and lets the harmless one through. Test both:
`terraform destroy` blocks, `terraform plan -destroy` does not, because a plan changes
nothing.

Then answer: is a blocklist the right shape at all, or should this be an allowlist of the
commands the agent may run?

**Take home:** Blocklists are what you write first and regret later. The allowlist is more
work and fails safe. Choose deliberately.

## Task A4 - ADVANCED: Name what you cannot prove here

Your configuration validates. List two statements about this setup you **cannot** prove
without applying it, and say what you would need in order to prove each. Then: what would
you put in CI so nobody has to remember to run `terraform validate` by hand?

**Take home:** Knowing which claims your local checks do and do not support is the whole
difference between a green pipeline and a working system. Same lesson as "green tests do not
prove persistence" from lab 1.2, one layer up.

## Bring to the discussion

- **What did your hook refuse, and did the agent try to get around it?**
- **Which two findings did your checklist produce on the generated configuration?**
- **Where is a deny rule not enough, and what did you use instead?**

## Further reading

- Permissions: <https://code.claude.com/docs/en/permissions>
- Hooks: <https://code.claude.com/docs/en/hooks>
- Terraform MCP server: <https://developer.hashicorp.com/terraform/mcp-server>
- Azure Container Apps: <https://learn.microsoft.com/en-us/azure/container-apps/overview>
- The reference configuration: `deploy/terraform/` on `m3-solution`
