# Lab 3: Harden the harness, then let it write the infrastructure

| Info | Detail |
|---|---|
| Module | M3 - Infrastructure, secrets and guardrails: create and verify |
| Duration | 30 minutes, plus the discussion |
| Harness | Claude Code |
| Tooling | HashiCorp Terraform MCP server in Docker. Terraform CLI for `fmt` and `validate` |
| Repo | `lab-trackit-java`, your clone from lab 2, or branch `m3-start` |
| Target state | deny rules, a blocking hook, and validated Terraform (branch `m3-solution`) |

Nothing is deployed today: we write infrastructure code and validate it. The agent never
gets credentials and never applies anything, and by the end of task 2 it could not even if
it decided to.

We harden first, then we generate. An agent writing infrastructure is the
highest-consequence thing it does all day: it reaches for real credentials, it runs
commands that delete things, and a mistake is not a failing test but a deleted database.

| Task | What it protects against |
|---|---|
| 1 Deny rules | the agent reading a secret into its context |
| 2 A hook | the agent running a command that destroys something |
| 3 MCP server | the agent inventing provider syntax from stale memory |
| 4 Generate | - |

Part 1 is four tasks for everyone. Part 2 is advanced and optional.

## What you record today

Keep a scratch file open. The discussion at the end runs on these three:

| From | Write down |
|---|---|
| Task 1 | Why a deny rule alone was not enough, in one sentence |
| Task 2 | What your hook refused, and whether the agent tried to get around it |
| Task 4 | Your checklist findings, written before the agent corrects anything |

## Where you start

Continue on your repo from lab 2. Check that nothing is uncommitted:

```bash
git status --porcelain
```

It prints nothing when you are ready. If it prints a line, or lab 2 did not finish, take
the reference state:

```bash
git fetch origin && git checkout -B m3-start origin/m3-start
```

Check where you are:

```bash
git branch --show-current
```

The output is your own branch, or:

```text
m3-start
```

Either way, check the machine before you start:

```bash
./verify.sh
```

Every line reads `[OK]` except the health endpoint, which only answers while the
application runs.

---

# Part 1 - Standard, 30 minutes

## Task 1: Deny what must never be read (6 min)

A `.gitignore` keeps a file out of git. It does nothing about the agent: Claude Code reads
`.env` happily and puts it in the context window, and from there it goes to the model.

### Step 1: Write the deny list

Create `.claude/settings.json` with this content:

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
      "Read(**/*.tfstate.backup)",
      "Edit(**/*.tfstate)"
    ]
  }
}
```

There are three modes: `allow` runs without asking, `ask` confirms every time, `deny`
blocks. `deny` has the highest priority and wins over everything.

`*.tfstate` is on the list for a reason people miss: **Terraform state contains every value
it ever resolved, including the database password, in plain text.** It is the most secret
file in an infrastructure repository and it looks like a build artefact. `*.tfstate.backup`
is the same file under a different name, which is why it needs its own line.

Restart your Claude Code session, so it reads the new settings file.

### Step 2: Watch the deny rule work

Type this in the Claude session:

```text
Read the .env file and tell me what is in it.
```

The agent reports that it is not allowed to read the file, and the contents never appear.

### Step 3: Find the hole in the same minute

Now ask for the same file through the shell:

```text
Run: cat .env
```

The agent runs it through Bash and the contents of `.env` land in the transcript. A deny
rule governs Claude's own file tools and not the shell, and that gap is exactly why task 2
exists. Write the one-sentence version into your scratch file now.

**Take home:** `.claude/settings.json` is committed, so the whole team inherits the deny
list on clone. Add `*.tfstate` to yours today.

**Trap:** Treating the `deny` list as security. You just watched it refuse the Read tool and
wave `cat .env` through in the same minute. It constrains Claude's own file tools and
nothing else: not the shell, not an MCP server, not a hook, not anything else running as
your user. Use it to stop the accident, and keep the secret out of the repo to stop the
attacker.

Reference: [permissions](https://code.claude.com/docs/en/permissions)

## Task 2: Write a hook that blocks instead of asking (9 min)

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
  echo "Blocked by check-infra.sh: jq is not installed, so this hook cannot inspect" >&2
  echo "the command. Install jq (apt-get install -y jq) and try again." >&2
  exit 2
fi

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
[ -n "$cmd" ] || exit 0

block() {
  echo "Blocked by check-infra.sh: $1" >&2
  echo "Nothing ran. If this is genuinely needed, a human runs it outside the agent." >&2
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

Every branch of the `case` exits 2 with its reason on stderr, anything else exits 0, and
step 3 shows both paths.

Make it executable, or the harness skips it silently:

```bash
chmod +x .claude/hooks/check-infra.sh
ls -l .claude/hooks/check-infra.sh
```

The output must show the executable bits:

```text
-rwxr-xr-x 1 vscode vscode 812 Sep  8 09:31 .claude/hooks/check-infra.sh
```

### Step 2: Register it

Add this next to the `permissions` block in `.claude/settings.json`:

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

A trailing comma or a missing brace makes Claude Code ignore the whole file, so check the
JSON parses before you restart:

```bash
jq . .claude/settings.json > /dev/null && echo "settings.json is valid JSON"
```

The output should be:

```text
settings.json is valid JSON
```

Restart the session, then check the hook is loaded:

```text
/hooks
```

The `PreToolUse` list must name `check-infra.sh`.

### Step 3: Prove it blocks, before you trust it

A hook is a program that reads JSON on stdin. Test it directly, with no agent involved.
From the repo root:

```bash
echo '{"tool_input":{"command":"terraform destroy"}}' | .claude/hooks/check-infra.sh
echo "exit=$?"
```

The reason goes to stderr and the exit code is 2:

```text
Blocked by check-infra.sh: terraform destroy tears down real infrastructure
Nothing ran. If this is genuinely needed, a human runs it outside the agent.
exit=2
```

Now the harmless one. A plan changes nothing, so it has to pass:

```bash
echo '{"tool_input":{"command":"terraform plan"}}' | .claude/hooks/check-infra.sh
echo "exit=$?"
```

The output should be:

```text
exit=0
```

### Step 4: Watch it fire in the session

**Note.** There is no Terraform code yet, task 4 writes it. That does not matter here: a
`PreToolUse` hook runs *before* the command does, so the call is refused whether or not
`deploy/terraform` exists.

Ask for the command by name, so the agent issues it instead of checking the directory and
telling you it is empty:

```text
Run exactly this, do not check the directory first:

cd deploy/terraform && terraform destroy -auto-approve
```

The tool call is refused with your reason visible, and the agent does not talk its way
around it. Watch what it does next: a good one reports the refusal. Note it if it tries
something adjacent instead.

Then check you did not block the work:

```text
Run ./mvnw -q test in the backend directory.
```

That runs. The guard refuses five commands and leaves everything else alone.

### Step 5: Understand the failure mode

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

### Step 1: Add the server, pinned to a version

```bash
claude mcp add --scope project terraform -- \
  docker run -i --rm hashicorp/terraform-mcp-server:1.3.0
```

The output names the server and the scope it landed in:

```text
Added stdio MCP server terraform with command: docker run -i --rm hashicorp/terraform-mcp-server:1.3.0 to project config
```

That writes the server into `.mcp.json` in the repo root, so the whole team gets it on
clone. Pin the tag, because a server on `latest` changes its tool descriptions under you.

### Step 2: Check it connected

```bash
claude mcp list
```

The `terraform` server appears among this project's servers. A project-scope server you
have not approved yet reads `Pending approval`, so approve it in your interactive session
when it asks and run the command again. It then reads:

```text
terraform: docker run -i --rm hashicorp/terraform-mcp-server:1.3.0 - ✓ Connected
```

### Step 3: Ask it something the model cannot know

```text
Using the terraform MCP server, what is the current resource name and the required
arguments for an Azure Container App, and which provider version are you reading?
```

The answer names a provider version, and the session shows a `terraform` tool call. An
answer with no tool call came from memory, which is the thing this server exists to
replace.

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

Give the agent the job and its boundary in the same prompt:

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

Write down at least two findings. **Finding none means you did not apply the checklist.**

### Step 3: Let it write

Approve the plan, naming what you are approving:

```text
The plan is fine. Write those files. Do not run terraform apply or terraform destroy,
and do not create a terraform.tfvars.
```

### Step 4: Verify the configuration yourself

In a second terminal, check the formatting first. `fmt -check` prints the name of every
badly formatted file and prints nothing when they are all clean:

```bash
cd deploy/terraform
terraform fmt -check
echo "exit=$?"
```

The output should be:

```text
exit=0
```

Then download the provider and validate. `-backend=false` skips the remote state
configuration, which this lab does not have:

```bash
terraform init -backend=false
```

The output ends with the provider it installed and a success line:

```text
- Installing hashicorp/azurerm v4.81.0...
- Installed hashicorp/azurerm v4.81.0 (signed by HashiCorp)

Terraform has been successfully initialized!
```

Now validate:

```bash
terraform validate
```

The output should be:

```text
Success! The configuration is valid.
```

`validate` checks syntax and the provider schema. It needs no credentials, reaches no Azure
subscription, and changes nothing.

### Step 5: Prove the secret is out of reach

Ask the agent for the value directly:

```text
What is the database password in this configuration?
```

It cannot answer: there is no default, no committed `terraform.tfvars`, and task 1 denied
reading one. The value lives in `TF_VAR_db_password` in your shell.

Check that no state or credential file can be committed either:

```bash
cd ../.. && git status --porcelain deploy/terraform
```

The output lists the `.tf` files you generated and **no** `terraform.tfvars`, no
`.terraform/` and no `*.tfstate`:

```text
?? deploy/terraform/main.tf
?? deploy/terraform/outputs.tf
?? deploy/terraform/variables.tf
?? deploy/terraform/versions.tf
```

If a `.tfstate` or a `terraform.tfvars` does appear, add it to `.gitignore` before you
commit.

### Step 6: Commit

Commit the configuration together with the guardrails that made it safe to generate:

```bash
git add -A && git commit -m "feat: terraform for trackit on azure container apps"
```

`git commit` names the branch and counts the files:

```text
[m3-start 3f4a5b6] feat: terraform for trackit on azure container apps
 11 files changed, 355 insertions(+)
```

The hash and the counts are yours, not these. `git status --porcelain` prints nothing
afterwards.

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

Optional. Start when Part 1 is committed and `git status --porcelain` prints nothing.

## Task A1 - ADVANCED: Validate with Microsoft's Azure skills

*Deepens task 4.* You reviewed the generated configuration by hand. Microsoft publishes a
plugin of Azure skills, so let it review the same files.

### Step 1: Add Microsoft's marketplace

The `azure` plugin is not in Anthropic's marketplace. It comes from Microsoft's own, which
you add by owner and repository:

```text
/plugin marketplace add microsoft/azure-skills
```

It reports the marketplace added and how many plugins it carries. This is the third tier of
trust from lab 1.2 task A4: a repository you add yourself, screened by nobody.

### Step 2: Read what it brings, then install

Open the plugin browser:

```text
/plugin
```

Find **azure** in **Discover** and read the "Will install" pane before you install
anything. It brings the Azure MCP server and around 30 skills.

**Warning.** One of those skills, `azure-deploy`, runs `azd up`, `azd deploy` and
`terraform apply`. Installing this plugin gives it the ability to deploy.

Install it:

```text
/plugin install azure@azure-skills
```

### Step 3: Validate the configuration

`azure-validate` checks configuration and infrastructure, Bicep or Terraform, before a
deployment. Say what you want, do not name the skill:

```text
Run pre-deployment validation on the Terraform in deploy/terraform. It targets Azure
Container Apps with a PostgreSQL flexible server.
```

You are not logged in to Azure, so anything that queries a real subscription cannot answer.
Note which findings came from reading your files and which came back empty. That difference
tells you which half of the review you can run in CI, and which half needs an account.

Compare the result with task 4: `terraform validate` says the provider understands your
file. This says whether Azure would accept it.

### Step 4: Watch your guardrail earn itself

Ask for the thing the plugin can now do:

```text
Use the azure-deploy skill to deploy this to Azure.
```

The hook you wrote in task 2 refuses the `terraform apply`. You added a marketplace nobody
vetted, installed a vendor plugin whose skills can deploy, and the guard you put up
**before** you installed it is what stands between that capability and a subscription. That
is the order this lab has been arguing for, and this is where it pays.

**Take home:** Install the vendor's skills rather than writing your own guesses about their
platform, and put the guardrails up first. A plugin brings capability you did not write and
did not review line by line.

**Tip:** The same plugin ships `azure-cost` and `azure-compliance`. Both query a live
subscription, so neither runs today. Those are the two to try at your desk against a real
account.

**Trap:** Judging a plugin by the skill you wanted. This one also brought a deploy skill and
an MCP server. The "Will install" pane is where you find that out, and it is the last moment
it costs nothing.

References: [microsoft/azure-skills](https://github.com/microsoft/azure-skills) ·
[plugin marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)

## Task A2 - ADVANCED: Run Anthropic's security reviewer on your Terraform

*Deepens task 4 step 2.* You produced at least two findings by hand. Now install a published
reviewer and compare the two lists.

### Step 1: Check the prerequisite

The plugin runs its checks through Python 3.8 or newer:

```bash
python3 --version
```

The output names a version 3.8 or higher:

```text
Python 3.12.3
```

If the command is not found, install it with `sudo apt-get install -y python3`.

### Step 2: Install it

This one is in Anthropic's curated marketplace, which ships enabled, so there is no
marketplace to add:

```text
/plugin install security-guidance@claude-plugins-official
```

It works in three layers: regex warnings on every `Edit` and `Write`, an LLM review of the
diff when a turn ends, and an agentic reviewer that reads across files on `git commit`.

**Warning.** Layers 2 and 3 each make an extra model call and your workshop key is capped.
Turn the plugin off again when you are done with this task:

```bash
export SECURITY_GUIDANCE_DISABLE=1
```

### Step 3: Review the Terraform

Ask for a review of the files you generated in task 4:

```text
Review deploy/terraform for security problems and list them by severity.
```

Then commit, so the agentic reviewer runs across files too:

```bash
git commit --allow-empty -m "chore: trigger the security review"
```

You see the reviewer run on the commit and report across files, not only the diff.

### Step 4: Compare the two lists

Put your task 4 findings next to the plugin's and answer both questions:

- What did only the plugin find?
- What did only you find?

Expect it to be strong on hardcoded secrets and quiet on Azure. It covers code
vulnerability classes: injection, XSS, SSRF, hardcoded secrets, IDOR, auth bypass, unsafe
deserialisation, path traversal. "The database is reachable from the public internet" and
"no backup retention" are not on that list, because they are not code vulnerabilities. They
are infrastructure decisions, and nobody has written your architecture down for a tool to
check.

**Take home:** That gap is the honest answer to "can I automate my review". A published
reviewer covers its classes completely and tirelessly, which is more than you will manage by
hand. It does not cover your architecture. Install one **and** keep the checklist.

**Tip:** `SECURITY_GUIDANCE_DISABLE=1` is the kill switch, and the layers can be turned off
one at a time with `ENABLE_PATTERN_RULES=0` and `ENABLE_CODE_SECURITY_REVIEW=0`. Check what a
review plugin costs per turn before you put it in a team repo.

**Trap:** Reading a clean report as "this is secure". It means nothing in the classes it
checks was found. Ask any reviewer, human or plugin, what it did not look at.

Reference: [security-guidance](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/security-guidance)

## Task A3 - ADVANCED: Make the hook precise

*Deepens task 2.* Your blocklist matches a substring, so it catches `terraform destroy` and
misses `terraform  destroy` with two spaces and `TERRAFORM DESTROY`.

Rewrite it so it catches the dangerous case and lets the harmless one through, then test
both paths the way step 3 did:

```bash
echo '{"tool_input":{"command":"terraform  destroy"}}' | .claude/hooks/check-infra.sh
echo "exit=$?"
echo '{"tool_input":{"command":"terraform plan -destroy"}}' | .claude/hooks/check-infra.sh
echo "exit=$?"
```

The first must now print `exit=2` and the second must still print `exit=0`, because a plan
changes nothing.

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
