#!/usr/bin/env bash
#
# Devcontainer post-create for lab-trackit-java.
#
# Installs the two AI coding CLIs the workshop runs on (Claude Code, OpenCode),
# seeds .env and warms the Maven cache. Every step verifies itself and prints a
# loud WARNING when it fails - a broken install must never pass silently, or a
# participant only finds out at the start of the first lab.
#
# Baseline: acend-swai/lab-hello-world (same npm packages, same [OK] idiom).

set -uo pipefail

warn() { echo "WARNING: $*" >&2; }

install_cli() {
  local label="$1" pkg="$2" cmd="$3"
  echo "--- installing $label ($pkg)"
  if ! npm install -g "$pkg"; then
    warn "$label install failed. Check network and proxy, then run: npm install -g $pkg"
    return 1
  fi
  if ! command -v "$cmd" > /dev/null 2>&1; then
    warn "$label installed but '$cmd' is not on PATH. Run: npm install -g $pkg"
    return 1
  fi
  echo "[OK]      $label ($("$cmd" --version 2>&1 | head -n1))"
}

install_cli "Claude Code CLI" "@anthropic-ai/claude-code" claude
install_cli "OpenCode CLI"    "opencode-ai"               opencode

if [ -f .env ]; then
  echo "[OK]      .env already present, left untouched"
elif cp .env.example .env; then
  echo "[OK]      .env created from .env.example - your personal key arrives by mail"
else
  warn ".env could not be created. Copy .env.example to .env by hand."
fi

echo "--- warming the Maven cache"
if ( cd backend && ./mvnw -q -B dependency:go-offline ); then
  echo "[OK]      Maven dependencies cached"
else
  warn "Maven dependencies could not be downloaded. Run './mvnw -B test' in backend/ before the workshop day."
fi

echo "-------------------------------"
echo "Setup done. Run ./verify.sh - every line must read [OK]."
