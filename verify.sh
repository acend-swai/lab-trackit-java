#!/usr/bin/env bash
#
# Pre-workshop verification for lab-trackit-java.
# Same idiom as acend-swai/lab-hello-world: every line reads [OK] or [MISSING].

set -uo pipefail

echo "lab-trackit-java - verification"
echo "-------------------------------"

check_cmd() {
  local label="$1" cmd="$2"
  if command -v "$cmd" > /dev/null 2>&1; then
    echo "[OK]      $label ($("$cmd" --version 2>&1 | head -n1))"
  else
    echo "[MISSING] $label - command '$cmd' not found"
  fi
}

check_url() {
  local label="$1" url="$2"
  if curl -sf --max-time 3 "$url" > /dev/null; then
    echo "[OK]      $label"
  else
    echo "[MISSING] $label - $url not reachable"
  fi
}

check_java_21() {
  local v
  v=$(java -version 2>&1 | head -n1)
  if echo "$v" | grep -qE '"(21|22|23|24|25)'; then
    echo "[OK]      Java 21 or newer ($v)"
  else
    echo "[MISSING] Java 21 or newer - found: $v"
  fi
}

check_java_21
check_cmd "Node (installs the CLIs)" node
check_cmd "Claude Code CLI"          claude
check_cmd "OpenCode CLI"             opencode

if [ ! -f .env ]; then
  echo "[MISSING] .env - it arrives by mail on the workshop morning"
elif grep -qE '^OPENROUTER_API_KEY=.+' .env; then
  echo "[OK]      .env present, OpenRouter key set"
else
  echo "[MISSING] .env is there but OPENROUTER_API_KEY is empty - OpenCode needs it in lab 1.1"
fi

# opencode.json reads the key from the environment, so the file alone is not enough.
if [ -n "${OPENROUTER_API_KEY:-}" ]; then
  echo "[OK]      OPENROUTER_API_KEY exported in this shell"
else
  echo "[MISSING] OPENROUTER_API_KEY not exported - run: set -a; source .env; set +a"
fi

echo "-------------------------------"
echo "Build check (this downloads dependencies on the first run):"
( cd backend && ./mvnw -q -B test > /tmp/trackit-verify.log 2>&1 \
  && echo "[OK]      ./mvnw test" \
  || { echo "[MISSING] ./mvnw test failed - see /tmp/trackit-verify.log"; tail -5 /tmp/trackit-verify.log; } )

echo "-------------------------------"
echo "Every line above must show [OK] before the lab starts."
echo
echo "The next check answers only while the application runs, so [MISSING] here is"
echo "expected before the lab and is not a problem:"
check_url "Health endpoint" "http://localhost:8080/api/v1/health"
