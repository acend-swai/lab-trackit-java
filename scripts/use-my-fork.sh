#!/usr/bin/env bash
#
# use-my-fork.sh - send your commits to your own fork, keep getting lab updates
# from the workshop repo.
#
# WHY this exists: a fork carries the SAME branch names as the workshop repo. Once
# both remotes have `m1-2-start`, `git checkout m1-2-start` fails with "matched more
# than one remote tracking branch" and the participant is stuck on a git problem
# instead of the lab. This wires the clone so that never happens:
#
#   origin              the workshop repo, read-only, where lab branches come from
#   mine                your fork, where every `git push` lands
#   remote.pushDefault  routes a bare `git push` to `mine`
#   checkout.defaultRemote  makes `git checkout mN-start` mean origin, always
#
# Run it from the repo root, once, after cloning:
#   scripts/use-my-fork.sh https://github.com/<your-user>/lab-trackit-java.git
#
# It is idempotent - running it twice is harmless. It pushes nothing on its own.

set -uo pipefail

UPSTREAM_MATCH="acend-swai/lab-trackit-java"

die() { echo "ERROR: $*" >&2; exit 1; }

FORK_URL="${1:-}"
[ -n "$FORK_URL" ] || die "give your fork URL: scripts/use-my-fork.sh <your fork URL>"

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || die "run this inside the trackit clone"
cd "$ROOT" || die "cannot enter $ROOT"

case "$FORK_URL" in
  *"$UPSTREAM_MATCH"*)
    die "that is the workshop repo, not your fork. Fork it on GitHub first, then pass your own URL." ;;
  http*|git@*) ;;
  *) die "that does not look like a git URL: $FORK_URL" ;;
esac

# The clone may have been made FROM the fork rather than from the workshop repo.
# In that case origin points at the fork, so move it to `mine` and restore origin.
ORIGIN_URL=$(git remote get-url origin 2>/dev/null || echo "")
case "$ORIGIN_URL" in
  *"$UPSTREAM_MATCH"*) ;;
  "") die "this clone has no 'origin' remote" ;;
  *)
    # The clone was made from the fork. Point origin back at the workshop repo and
    # fetch it, so the lab branches resolve to origin from here on.
    echo "note: origin was not the workshop repo, repointing it"
    git remote set-url origin "https://github.com/${UPSTREAM_MATCH}.git" || die "could not repoint origin"
    git fetch --quiet origin || die "could not fetch the workshop repo"
    ;;
esac

if git remote get-url mine > /dev/null 2>&1; then
  git remote set-url mine "$FORK_URL" || die "could not update the 'mine' remote"
else
  git remote add mine "$FORK_URL" || die "could not add the 'mine' remote"
fi

git config remote.pushDefault mine     || die "could not set remote.pushDefault"
git config checkout.defaultRemote origin || die "could not set checkout.defaultRemote"

# Prove the fork is reachable and writable before the participant trusts it.
if ! git ls-remote --exit-code mine > /dev/null 2>&1; then
  echo
  echo "WARNING: cannot reach $FORK_URL"
  echo "         Check the URL and your GitHub login, then run this again."
  exit 1
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo
echo "Done. Your clone is wired up:"
echo
git remote -v | sed 's/^/  /'
echo
echo "  git push          goes to mine ($FORK_URL)"
echo "  git fetch origin  brings lab updates from the workshop repo"
echo
echo "Push this branch to your fork now:"
echo
echo "  git push -u mine $BRANCH"
echo
