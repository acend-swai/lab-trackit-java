#!/usr/bin/env python3
"""
Lab branch content validator.

Asserts that each lab-trackit start branch contains exactly the files its labs
expect: every `must_exist` path is present, and every `must_not_exist` path
(files students create during the lab) is absent.

Source of truth: workshop-2-days/labs/lab-manifest.yml
Branch trees are read with `git ls-tree -r --name-only <ref>/<branch>`.

WHY: the blockN-start branches are hand-authored snapshots that drift silently
(see docs/lab-repos.md). This check fails the build when a branch ships a file a
lab is meant to create, or is missing a file a lab reads as pre-existing.

Usage:
    scripts/validate_lab_branches.py [--repo PATH] [--remote NAME]

  --repo    Path to a lab-trackit clone/submodule (default: the submodule at
            workshop-2-days/labs/lab-trackit relative to this repo root).
  --remote  Remote prefix for branch refs, e.g. "origin" -> origin/block4-start
            (default: origin). Use "" to read local branches by bare name.

Exit code 0 = all branches match the manifest; 1 = drift or setup error.

The manifest parser intentionally avoids PyYAML (unavailable / unstable in some
CI images here). It supports two shapes, both PyYAML-free:

  FLAT (lab-trackit):              NESTED (customer repos, e.g. pitc):
    block4-start:                    branches:
      must_exist:                      block4-start:
        - AGENTS.md                      role: ...            # scalar keys ignored
      must_not_exist:                    must_exist:
        - .mcp.json                        - AGENTS.md
                                         must_not_exist:
                                           - .mcp.json

The parser keys on indentation: it finds branch keys, then `must_exist:` /
`must_not_exist:` mappings under them, then `- path` list items. A top-level
`branches:` container is entered if present; any other top-level block (e.g.
`stack:`) is skipped. Scalar keys like `role:`/`off:` (a value after the colon)
are ignored. Inline `# comments` and blank lines are ignored.
"""

import argparse
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_MANIFEST = REPO_ROOT / "workshop-2-days" / "labs" / "lab-manifest.yml"
DEFAULT_REPO = REPO_ROOT / "workshop-2-days" / "labs" / "lab-trackit"


def strip_comment(line: str) -> str:
    """Remove a trailing ' # comment'. No '#' appears inside our paths/keys."""
    if "#" in line:
        line = line.split("#", 1)[0]
    return line.rstrip()


RULE_KEYS = ("must_exist", "must_not_exist")


def _unquote(s: str) -> str:
    s = s.strip()
    if len(s) >= 2 and s[0] == s[-1] and s[0] in "\"'":
        return s[1:-1]
    return s


def parse_manifest(path: Path) -> dict:
    """Parse the restricted-YAML manifest into {branch: {rule_key: [paths]}}.

    Indent-aware so it handles both the flat lab-trackit shape (branches at
    column 0) and the nested customer shape (branches under a `branches:`
    container, indented). Top-level blocks other than `branches:` (e.g.
    `stack:`) are skipped; scalar keys like `role:`/`off:` are ignored.
    """
    text = path.read_text(encoding="utf-8")

    # NESTED shape if a top-level `branches:` container exists anywhere; then
    # every column-0 key other than `branches:` (e.g. `stack:`) is NOT a branch
    # and is skipped. FLAT shape (lab-trackit) has no `branches:` line, so
    # column-0 keys are the branch names themselves.
    nested = any(
        strip_comment(ln).strip() == "branches:" for ln in text.splitlines()
    )

    manifest: dict = {}
    branch = None
    branch_indent = None  # column at which branch keys live
    key = None            # current rule key (must_exist / must_not_exist)
    in_branches = not nested  # flat shape: branches start immediately
    skip_block_indent = None  # skip a non-branch top-level block (e.g. stack:)

    for raw in text.splitlines():
        line = strip_comment(raw)
        if not line.strip():
            continue
        indent = len(line) - len(line.lstrip(" "))
        stripped = line.strip()

        # Inside a skipped top-level block (e.g. stack:), ignore deeper lines.
        if skip_block_indent is not None:
            if indent > skip_block_indent:
                continue
            skip_block_indent = None  # block ended

        # Top-level (column 0) keys.
        if indent == 0:
            if nested:
                if stripped == "branches:":
                    in_branches = True
                    branch = None
                    key = None
                    branch_indent = None
                else:
                    # any other top-level block (stack:, a stray scalar) - skip
                    skip_block_indent = 0
                continue
            # FLAT shape: column-0 key is a branch name
            if stripped.endswith(":") and " " not in stripped[:-1]:
                branch = stripped[:-1].strip()
                manifest[branch] = {}
                branch_indent = 0
                key = None
                continue
            skip_block_indent = 0
            continue

        # Indented lines. Establish the branch-key indent on first nested branch.
        if in_branches and branch_indent is None:
            branch_indent = indent

        if indent == branch_indent and stripped.endswith(":") and ":" not in stripped[:-1]:
            # a branch name (nested shape) - or could be a scalar; branch names
            # have nothing after the colon
            branch = stripped[:-1].strip()
            manifest[branch] = {}
            key = None
            continue

        if stripped.startswith("- "):
            if branch is None or key is None:
                raise ValueError(f"list item outside a rule key: {raw!r}")
            manifest[branch][key].append(_unquote(stripped[2:]))
            continue

        if stripped.endswith(":"):
            k = stripped[:-1].strip()
            if k in RULE_KEYS:
                if branch is None:
                    raise ValueError(f"rule key outside a branch: {raw!r}")
                key = k
                manifest[branch][key] = []
            else:
                key = None  # some other mapping key we don't track
            continue

        # scalar key:value (role:, off:, app_state:, ...) - ignore, end any list
        if ":" in stripped:
            key = None
            continue

        raise ValueError(f"unrecognized manifest line: {raw!r}")

    return manifest


def branch_files(repo: Path, ref: str) -> set:
    """Return the set of tracked file paths for a branch ref via git ls-tree."""
    result = subprocess.run(
        ["git", "-C", str(repo), "ls-tree", "-r", "--name-only", ref],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"git ls-tree failed for {ref}: {result.stderr.strip()}"
        )
    return {ln for ln in result.stdout.splitlines() if ln}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--repo", default=str(DEFAULT_REPO))
    ap.add_argument("--remote", default="origin")
    ap.add_argument("--manifest", default=str(DEFAULT_MANIFEST))
    args = ap.parse_args()

    repo = Path(args.repo)
    manifest_path = Path(args.manifest)

    if not manifest_path.is_file():
        print(f"ERROR: manifest not found: {manifest_path}", file=sys.stderr)
        return 1
    if not (repo / ".git").exists() and not (repo.parent / ".git").exists():
        print(f"ERROR: not a git repo: {repo}", file=sys.stderr)
        return 1

    manifest = parse_manifest(manifest_path)
    prefix = f"{args.remote}/" if args.remote else ""

    total_problems = 0
    for branch, rules in manifest.items():
        ref = f"{prefix}{branch}"
        try:
            files = branch_files(repo, ref)
        except RuntimeError as exc:
            print(f"[{branch}] ERROR: {exc}", file=sys.stderr)
            total_problems += 1
            continue

        problems = []
        for path in rules.get("must_exist", []):
            # allow directory-style entries: present if any tracked file is under it
            present = path in files or any(
                f == path or f.startswith(path.rstrip("/") + "/") for f in files
            )
            if not present:
                problems.append(f"  MISSING (must_exist):     {path}")
        for path in rules.get("must_not_exist", []):
            present = path in files or any(
                f == path or f.startswith(path.rstrip("/") + "/") for f in files
            )
            if present:
                problems.append(f"  PRESENT (must_not_exist): {path}")

        if problems:
            print(f"[{branch}] {len(problems)} problem(s):")
            print("\n".join(problems))
            total_problems += len(problems)
        else:
            print(f"[{branch}] OK")

    if total_problems:
        print(f"\nFAILED: {total_problems} lab-branch drift problem(s).")
        return 1
    print("\nPASSED: all start branches match the lab manifest.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
