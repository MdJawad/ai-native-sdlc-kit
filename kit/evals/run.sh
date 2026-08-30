#!/usr/bin/env bash
# run.sh [--case <id>] [--repo <path>]
#
# Runs the agent-configuration eval suite. Each case runs in a throwaway git worktree, so a case
# that edits files never dirties the repository it is testing.
#
# Requires: claude, jq, git, and ANTHROPIC_API_KEY (or a configured Claude Code auth).
set -uo pipefail

repo="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
only=""
while [ $# -gt 0 ]; do
  case "$1" in
    --case) only="$2"; shift 2 ;;
    --repo) repo="$2"; shift 2 ;;
    -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

here="$(cd "$(dirname "$0")" && pwd)"
cases_dir="$here/cases"
command -v claude >/dev/null 2>&1 || { echo "run.sh requires the claude CLI" >&2; exit 2; }
command -v jq >/dev/null 2>&1 || { echo "run.sh requires jq" >&2; exit 2; }

total=0; passed=0
tmproot="$(mktemp -d)"
cleanup() {
  for wt in "$tmproot"/*; do
    [ -d "$wt" ] && git -C "$repo" worktree remove --force "$wt" 2>/dev/null
  done
  rm -rf "$tmproot"
}
trap cleanup EXIT

for case_file in "$cases_dir"/*.json; do
  [ -f "$case_file" ] || continue
  id="$(jq -r '.id' "$case_file")"
  [ -n "$only" ] && [ "$only" != "$id" ] && continue
  total=$((total + 1))

  desc="$(jq -r '.description // ""' "$case_file")"
  prompt="$(jq -r '.prompt' "$case_file")"
  tools="$(jq -r '.allowed_tools // "Read,Edit,Write,Glob,Grep,Bash"' "$case_file")"

  echo "── $id — $desc"
  wt="$tmproot/$id"
  if ! git -C "$repo" worktree add --detach "$wt" HEAD >/dev/null 2>&1; then
    echo "  ✗ $id — could not create a worktree (is the repo clean and committed?)"; continue
  fi

  result="$wt/.eval-result.json"
  if ! (cd "$wt" && claude -p "$prompt" --allowedTools "$tools" --output-format json > "$result" 2>"$wt/.eval-stderr"); then
    echo "  ! claude exited non-zero:"; sed 's/^/    /' "$wt/.eval-stderr" | head -5
  fi
  [ -s "$result" ] || echo '{}' > "$result"

  if bash "$here/check.sh" "$case_file" "$result" "$wt"; then
    passed=$((passed + 1))
  fi
done

echo
echo "eval suite: $passed/$total passed"
[ "$passed" = "$total" ]
