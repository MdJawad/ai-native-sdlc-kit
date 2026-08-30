#!/usr/bin/env bash
# Stage 5 (trunk-local profile) — the coordinator's gate.
#
# A unit branch being green is not the check that matters. The check that matters is the full
# verification command on the MERGED tree, which a per-branch CI run structurally cannot give you:
# every branch can be green and the merge still red.
#
#   ci/local/pre-merge-gate.sh <branch> [--trunk <name>] [--verify "<command>"]
#
# Merges <branch> into the trunk locally, re-runs the verification command on the result, and
# reports. It does not push. It does not resolve conflicts.
set -uo pipefail

branch="${1:?usage: pre-merge-gate.sh <branch> [--trunk <name>] [--verify \"<command>\"]}"; shift
trunk="${SDLC_TRUNK:-main}"
verify="${SDLC_VERIFY:-}"

while [ $# -gt 0 ]; do
  case "$1" in
    --trunk) trunk="$2"; shift 2 ;;
    --verify) verify="$2"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [ -z "$verify" ]; then
  for candidate in "make all" "npm test" "make test"; do
    cmd="${candidate%% *}"
    command -v "$cmd" >/dev/null 2>&1 && { verify="$candidate"; break; }
  done
fi
[ -n "$verify" ] || { echo "No verification command. Set SDLC_VERIFY or pass --verify." >&2; exit 2; }

say() { printf '\n\033[1m== %s\033[0m\n' "$1"; }

say "Pre-merge gate: $branch → $trunk"
echo "Verification: $verify"

[ -z "$(git status --porcelain)" ] || { echo "Working tree is dirty. Commit or stash first." >&2; exit 1; }

say "1/4 The diff you are approving"
git --no-pager diff --stat "$trunk...$branch"
echo
echo "Read it in full before continuing:  git diff $trunk...$branch"

say "2/4 Merging locally"
git checkout "$trunk" >/dev/null 2>&1 || { echo "Cannot check out $trunk" >&2; exit 1; }
if ! git merge --no-ff --no-edit "$branch"; then
  echo >&2
  echo "MERGE CONFLICT. Resolve it by hand — this script will not guess." >&2
  echo "Abort with: git merge --abort" >&2
  exit 1
fi

say "3/4 Verifying the merged tree"
if ! eval "$verify"; then
  say "GATE RED"
  echo "The merged tree fails verification. Each branch may have been green on its own;"
  echo "this is exactly the failure a per-branch check cannot catch."
  echo
  echo "Undo the merge with:  git reset --hard HEAD~1"
  exit 1
fi

say "4/4 GATE GREEN"
echo "$branch is merged into $trunk and the merged tree verifies."
echo
echo "Nothing has been pushed. Pushing is the user's decision, made by hand:"
echo "  git push <remote> $trunk"
