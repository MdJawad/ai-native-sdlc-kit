#!/usr/bin/env bash
#
# Stage 1 and 2 leading indicators, measured rather than asserted.
#
#   stage-latency.sh [--target <repo>] [--artifacts-dir sdlc]
#
# For every change under the artifacts directory, reports the wall-clock gap between the commits
# that first introduced intent.md, spec.md and plan.md. Read-only.
set -uo pipefail

TARGET="."; DIR="sdlc"
while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --artifacts-dir) DIR="$2"; shift 2 ;;
    -h|--help) sed -n '3,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
cd "$TARGET" 2>/dev/null || { echo "no such directory: $TARGET" >&2; exit 2; }
git rev-parse --git-dir >/dev/null 2>&1 || { echo "not a git repository" >&2; exit 2; }

# First commit that introduced a path, as a unix timestamp.
first_commit_ts() {
  git log --diff-filter=A --format=%at -- "$1" 2>/dev/null | tail -1
}
human() { # seconds → "3d 4h" / "5h 12m" / "18m"
  local s="$1"
  if   [ "$s" -ge 86400 ]; then printf '%dd %dh' $((s/86400)) $(((s%86400)/3600))
  elif [ "$s" -ge 3600 ];  then printf '%dh %dm' $((s/3600))  $(((s%3600)/60))
  else printf '%dm' $((s/60)); fi
}

printf '%-34s %12s %12s %12s\n' "CHANGE" "INTENT→SPEC" "SPEC→PLAN" "INTENT→PLAN"
printf '%-34s %12s %12s %12s\n' "----------------------------------" "------------" "------------" "------------"

found=0; sum_ip=0; n_ip=0
for d in "$DIR"/*/; do
  slug="$(basename "$d")"
  [ "$slug" = "templates" ] && continue
  [ -d "$d" ] || continue
  found=1

  i="$(first_commit_ts "${d}intent.md")"; s="$(first_commit_ts "${d}spec.md")"; p="$(first_commit_ts "${d}plan.md")"
  is="—"; sp="—"; ip="—"
  [ -n "$i" ] && [ -n "$s" ] && is="$(human $((s - i)))"
  [ -n "$s" ] && [ -n "$p" ] && sp="$(human $((p - s)))"
  if [ -n "$i" ] && [ -n "$p" ]; then ip="$(human $((p - i)))"; sum_ip=$((sum_ip + p - i)); n_ip=$((n_ip + 1)); fi
  [ -z "$i" ] && slug="$slug (uncommitted)"
  printf '%-34s %12s %12s %12s\n' "$slug" "$is" "$sp" "$ip"
done

[ "$found" = "1" ] || { echo "No changes found under $DIR/. Nothing to measure yet."; exit 0; }
[ "$n_ip" -gt 0 ] && printf '\nMean intent→plan over %d change(s): %s\n' "$n_ip" "$(human $((sum_ip / n_ip)))"

cat <<'NOTE'

Latency falling is the signal that the practice is being used — not the win. The win is in the
lagging column (rework, escaped defects) a quarter later. Read artifact-coverage.sh first: a
brilliant latency number over 12% of changes tells you about the 12%.
NOTE
