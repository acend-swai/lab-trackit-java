#!/usr/bin/env bash
#
# validate-all-branches.sh - check out every lab branch in its own worktree and
# actually RUN it: tests, typecheck, database, terraform, hooks, CI gates.
#
# WHY this exists: verify.sh answers "are the tools installed", and
# scripts/validate_lab_branches.py answers "does each branch contain the right
# files". Neither answers "does the lab work". This does, and it needs Docker,
# so it belongs on a workstation or in the devcontainer, not in a sandbox.
#
# It never touches your current checkout. Every branch gets a worktree under
# ../.trackit-worktrees/, run one at a time because they share ports 8080,
# 5173 and 5432.
#
# Usage, from the repo root:
#   scripts/validate-all-branches.sh                 # every branch
#   scripts/validate-all-branches.sh m2-solution     # one or more branches
#   scripts/validate-all-branches.sh --no-docker     # skip everything needing a DB
#   scripts/validate-all-branches.sh --keep          # leave the worktrees for poking at
#
# Exit 0 only when every check on every branch passed.

set -uo pipefail

ROOT=$(git rev-parse --show-toplevel) || { echo "not a git repo" >&2; exit 2; }
WT_BASE="$(dirname "$ROOT")/.trackit-worktrees"

ALL_BRANCHES=(m1-1-start m1-1-solution m1-2-start m1-2-mid m1-2-solution
              m2-start m2-solution m3-start m3-solution m4-full-agentic)

USE_DOCKER=1
KEEP=0
declare -a WANTED=()
for arg in "$@"; do
  case "$arg" in
    --no-docker) USE_DOCKER=0 ;;
    --keep)      KEEP=1 ;;
    -h|--help)   sed -n '2,26p' "$0"; exit 0 ;;
    *)           WANTED+=("$arg") ;;
  esac
done
[ ${#WANTED[@]} -gt 0 ] || WANTED=("${ALL_BRANCHES[@]}")

PASS=0; FAIL=0; SKIP=0
declare -a RESULTS=()

ok()   { echo "    [PASS] $1"; PASS=$((PASS+1)); RESULTS+=("PASS  $BR  $1"); }
bad()  { echo "    [FAIL] $1${2:+ - $2}"; FAIL=$((FAIL+1)); RESULTS+=("FAIL  $BR  $1${2:+ - $2}"); }
skip() { echo "    [skip] $1${2:+ - $2}"; SKIP=$((SKIP+1)); }

# Run a command, capture output, report PASS/FAIL, keep the log on failure.
run_check() {
  local label="$1"; shift
  local log; log=$(mktemp)
  if "$@" > "$log" 2>&1; then
    ok "$label"
  else
    bad "$label" "exit $?"
    echo "      ---- last 15 lines ----"
    tail -15 "$log" | sed 's/^/      /'
  fi
  rm -f "$log"
}

compose_down() {
  # Always -v. Going from a branch with V2__create_comment.sql back to one
  # without it leaves Flyway with an applied migration it cannot find, and the
  # next boot fails with a validation error that looks like a lab bug.
  docker compose down -v > /dev/null 2>&1 || true
}

free_port() {
  local p="$1"
  if command -v lsof > /dev/null 2>&1; then
    lsof -ti tcp:"$p" 2> /dev/null | xargs -r kill -9 2> /dev/null || true
  fi
}

echo "worktrees under: $WT_BASE"
mkdir -p "$WT_BASE"

for BR in "${WANTED[@]}"; do
  echo
  echo "=============================================================="
  echo "  $BR"
  echo "=============================================================="

  git -C "$ROOT" rev-parse --verify -q "$BR" > /dev/null || {
    BR="$BR"; bad "branch exists"; continue
  }

  WT="$WT_BASE/$BR"
  git -C "$ROOT" worktree remove --force "$WT" > /dev/null 2>&1 || true
  git -C "$ROOT" worktree add -q --detach "$WT" "$BR" || { bad "worktree add"; continue; }
  cd "$WT" || { bad "cd worktree"; continue; }

  # ---------- backend ----------
  if [ -d backend ]; then
    ( cd backend && ./mvnw -q -B test ) > /tmp/mvn-$BR.log 2>&1 \
      && ok "backend tests" \
      || { bad "backend tests" "see /tmp/mvn-$BR.log"; tail -12 /tmp/mvn-$BR.log | sed 's/^/      /'; }
  else
    skip "backend tests" "no backend/"
  fi

  # ---------- frontend ----------
  if [ -d frontend ]; then
    [ -d frontend/node_modules ] || (cd frontend && npm ci --no-audit --no-fund > /dev/null 2>&1)
    ( cd frontend && npx vue-tsc -b ) > /dev/null 2>&1 && ok "frontend typecheck" || bad "frontend typecheck"
    ( cd frontend && npm run build ) > /dev/null 2>&1 && ok "frontend build" || bad "frontend build"
  else
    skip "frontend" "no frontend/"
  fi

  # ---------- database, the part only Docker can prove ----------
  if [ -f compose.yaml ] && [ "$USE_DOCKER" = 1 ]; then
    free_port 8080; compose_down
    if docker compose up -d > /dev/null 2>&1; then
      for _ in $(seq 1 30); do
        docker compose exec -T db pg_isready -U trackit > /dev/null 2>&1 && break
        sleep 2
      done
      docker compose exec -T db pg_isready -U trackit > /dev/null 2>&1 \
        && ok "postgres reachable" || bad "postgres reachable" "never became ready"

      ( cd backend && ./mvnw -q -B spring-boot:run > /tmp/boot-$BR.log 2>&1 ) &
      APP_PID=$!
      for _ in $(seq 1 45); do
        curl -sf --max-time 2 localhost:8080/api/v1/health > /dev/null 2>&1 && break
        sleep 2
      done

      if curl -sf --max-time 3 localhost:8080/api/v1/health > /dev/null 2>&1; then
        ok "application boots against postgres"

        curl -s -X POST localhost:8080/api/v1/tasks -H 'content-type: application/json' \
          -d '{"title":"survives a restart","project":"validate"}' > /dev/null 2>&1

        # THE check the test suite cannot make: kill it, start it, look again.
        kill "$APP_PID" 2> /dev/null; wait "$APP_PID" 2> /dev/null; free_port 8080
        ( cd backend && ./mvnw -q -B spring-boot:run > /tmp/boot2-$BR.log 2>&1 ) &
        APP_PID=$!
        for _ in $(seq 1 45); do
          curl -sf --max-time 2 localhost:8080/api/v1/health > /dev/null 2>&1 && break
          sleep 2
        done
        if curl -s --max-time 3 localhost:8080/api/v1/tasks 2>/dev/null | grep -q "survives a restart"; then
          ok "task survives a restart (persistence is real)"
        else
          bad "task survives a restart" "the row was gone after a restart"
        fi

        docker compose exec -T db psql -U trackit -d trackit -c 'SELECT count(*) FROM task;' \
          > /dev/null 2>&1 && ok "task table queryable" || bad "task table queryable"
      else
        bad "application boots against postgres" "see /tmp/boot-$BR.log"
      fi
      kill "$APP_PID" 2> /dev/null; wait "$APP_PID" 2> /dev/null
      free_port 8080
      compose_down
    else
      bad "docker compose up"
    fi
  elif [ -f compose.yaml ]; then
    skip "database checks" "--no-docker"
  else
    skip "database checks" "no compose.yaml"
  fi

  # ---------- terraform ----------
  if [ -d deploy/terraform ]; then
    if command -v terraform > /dev/null 2>&1; then
      ( cd deploy/terraform && terraform fmt -check ) > /dev/null 2>&1 \
        && ok "terraform fmt" || bad "terraform fmt"
      ( cd deploy/terraform && terraform init -backend=false -input=false > /dev/null 2>&1 \
        && terraform validate > /dev/null 2>&1 ) \
        && ok "terraform validate" || bad "terraform validate"
    else
      skip "terraform" "CLI not installed"
    fi
  fi

  # ---------- guard hooks ----------
  if [ -x .claude/hooks/check-infra.sh ]; then
    printf '{"tool_input":{"command":"terraform destroy"}}' | .claude/hooks/check-infra.sh > /dev/null 2>&1
    [ $? -eq 2 ] && ok "check-infra blocks destroy" || bad "check-infra blocks destroy" "did not exit 2"
    printf '{"tool_input":{"command":"terraform plan"}}' | .claude/hooks/check-infra.sh > /dev/null 2>&1
    [ $? -eq 0 ] && ok "check-infra allows plan" || bad "check-infra allows plan"
  fi
  if [ -x .claude/hooks/block-protected-edits.sh ]; then
    printf '{"tool_input":{"file_path":".claude/agents/planner.md"}}' | .claude/hooks/block-protected-edits.sh > /dev/null 2>&1
    [ $? -eq 2 ] && ok "protected-edits blocks .claude/" || bad "protected-edits blocks .claude/"
    printf '{"tool_input":{"file_path":"backend/pom.xml"}}' | .claude/hooks/block-protected-edits.sh > /dev/null 2>&1
    [ $? -eq 0 ] && ok "protected-edits allows backend/" || bad "protected-edits allows backend/"
  fi

  # ---------- CI gates ----------
  [ -x scripts/check_agent_parity.sh ] && run_check "agent parity" bash scripts/check_agent_parity.sh
  if [ -x scripts/dod_check.sh ]; then
    printf 'Spec: openspec/changes/add-task-summary/proposal.md\n\n## Acceptance criteria\n\n- [x] done\n' \
      | scripts/dod_check.sh - > /dev/null 2>&1
    [ $? -eq 0 ] && ok "dod gate passes a good body" || bad "dod gate passes a good body"
    printf '## Acceptance criteria\n\n- [ ] not done\n' | scripts/dod_check.sh - > /dev/null 2>&1
    [ $? -eq 1 ] && ok "dod gate fails a bad body" || bad "dod gate fails a bad body"
  fi

  cd "$ROOT" || exit 2
  [ "$KEEP" = 1 ] || git worktree remove --force "$WT" > /dev/null 2>&1
done

git -C "$ROOT" worktree prune
echo
echo "=============================================================="
printf '  %d passed, %d failed, %d skipped\n' "$PASS" "$FAIL" "$SKIP"
echo "=============================================================="
if [ "$FAIL" -gt 0 ]; then
  echo
  echo "Failures:"
  printf '%s\n' "${RESULTS[@]}" | grep '^FAIL' | sed 's/^/  /'
  exit 1
fi
