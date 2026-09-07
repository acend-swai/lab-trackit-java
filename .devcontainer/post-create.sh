#!/usr/bin/env bash
#
# Devcontainer post-create for lab-trackit-java.
#
# Installs the two AI coding CLIs the workshop runs on (Claude Code, OpenCode),
# makes .env part of the environment of every shell, and warms every toolchain the
# day needs: Maven for the backend, npm for the frontend, and the Postgres image
# for the database. Every step verifies itself and prints a loud WARNING when it
# fails - a broken install must never pass silently, or a participant only finds
# out at the start of the first lab.
#
# The frontend and the database arrive on the lab 1.2 branch. The guards below keep
# this one script correct on every branch, including the ones that have neither.
#
# Baseline: acend-swai/lab-hello-world (same npm packages, same [OK] idiom).

set -uo pipefail

WORKSPACE="$PWD"
ENV_SNIPPET="$HOME/.trackit-env.sh"

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

# OpenCode reads OPENROUTER_API_KEY from the environment and does not load .env
# itself. One snippet holds the logic; every shell startup file sources it, so
# interactive and login shells, bash and zsh, all see the same variables. It
# re-reads .env on every shell start, which is what makes a key added later work
# in the next terminal without a rebuild.
echo "--- wiring .env into every shell"
cat > "$ENV_SNIPPET" <<SNIPPET
# lab-trackit-java: put .env into the environment. Written by post-create.sh.
if [ -f "$WORKSPACE/.env" ]; then
  set -a
  . "$WORKSPACE/.env"
  set +a
fi
SNIPPET

if [ -f "$ENV_SNIPPET" ]; then
  echo "[OK]      $ENV_SNIPPET written"
else
  warn "could not write $ENV_SNIPPET - run 'set -a; source .env; set +a' before starting OpenCode"
fi

source_line=". \"\$HOME/.trackit-env.sh\""
guarded="[ -f \"\$HOME/.trackit-env.sh\" ] && $source_line"
for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
  [ -e "$rc" ] || touch "$rc" 2> /dev/null || continue
  if grep -qF "trackit-env.sh" "$rc" 2> /dev/null; then
    echo "[OK]      $(basename "$rc") already sources it"
  elif printf '%s\n' "$guarded" >> "$rc"; then
    echo "[OK]      $(basename "$rc") sources it now"
  else
    warn "could not extend $rc"
  fi
done

echo "--- warming the Maven cache"
if ( cd backend && ./mvnw -q -B dependency:go-offline ); then
  echo "[OK]      Maven dependencies cached"
else
  warn "Maven dependencies could not be downloaded. Run './mvnw -B test' in backend/ before the workshop day."
fi

# The frontend toolchain is installed here, not during the lab. Fifteen minutes of
# lab time does not survive an npm install on conference wifi.
if [ -d frontend ]; then
  echo "--- installing the frontend toolchain"
  if ( cd frontend && npm ci --no-audit --no-fund ); then
    echo "[OK]      frontend dependencies installed"
  else
    warn "npm ci failed in frontend/. Run it by hand before the workshop day."
  fi
fi

# Pulling postgres:17 on the workshop morning is the single slowest thing that can
# happen in the room. Do it now, while the container builds.
if [ -f compose.yaml ]; then
  echo "--- pre-pulling the database image"
  if docker pull postgres:17 > /dev/null 2>&1; then
    echo "[OK]      postgres:17 pulled"
  else
    warn "postgres:17 could not be pulled. Run 'docker pull postgres:17' before the workshop day."
  fi
fi

echo "-------------------------------"
echo "Setup done. Open a NEW terminal so .env is loaded, then run ./verify.sh -"
echo "every line must read [OK]."
