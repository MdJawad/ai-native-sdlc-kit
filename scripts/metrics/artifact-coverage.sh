#!/usr/bin/env bash
#
# The honest adoption measure: what share of merged work carries a committed plan.md.
#
#   artifact-coverage.sh [--target <repo>] [--since 90.days] [--trunk main] [--artifacts-dir sdlc]
#
# Read-only.
set -uo pipefail

TARGET="."; SINCE="90.days"; TRUNK=""; DIR="sdlc"
while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --since) SINCE="$2"; shift 2 ;;
    --trunk) TRUNK="$2"; shift 2 ;;
    --artifacts-dir) DIR="$2"; shift 2 ;;
    -h|--help) sed -n '3,8p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
cd "$TARGET" 2>/dev/null || { echo "no such directory: $TARGET" >&2; exit 2; }
git rev-parse --git-dir >/dev/null 2>&1 || { echo "not a git repository" >&2; exit 2; }
[ -n "$TRUNK" ] || TRUNK="$(git symbolic-ref --short HEAD 2>/dev/null || echo main)"

echo "Artifact coverage on $TRUNK, last $SINCE"
echo

# Merges (or, in a repo that does not merge, plain commits) in the window.
merges="$(git log "$TRUNK" --since="$SINCE" --merges --format=%H 2>/dev/null | wc -l | tr -d ' ')"
commits="$(git log "$TRUNK" --since="$SINCE" --no-merges --format=%H 2>/dev/null | wc -l | tr -d ' ')"

if [ "$merges" -gt 0 ]; then unit="merge"; total="$merges"; else unit="commit"; total="$commits"; fi
[ "$total" -gt 0 ] || { echo "No $unit""s in the window. Nothing to measure."; exit 0; }

plans="$(git log "$TRUNK" --since="$SINCE" --diff-filter=A --format=%H -- "$DIR/*/plan.md" ":(exclude)$DIR/templates/*" 2>/dev/null | wc -l | tr -d ' ')"
intents="$(git log "$TRUNK" --since="$SINCE" --diff-filter=A --format=%H -- "$DIR/*/intent.md" ":(exclude)$DIR/templates/*" 2>/dev/null | wc -l | tr -d ' ')"
specs="$(git log "$TRUNK" --since="$SINCE" --diff-filter=A --format=%H -- "$DIR/*/spec.md" ":(exclude)$DIR/templates/*" 2>/dev/null | wc -l | tr -d ' ')"

pct() { [ "$2" -eq 0 ] && { printf '0'; return; }; awk -v a="$1" -v b="$2" 'BEGIN{printf "%.0f", 100*a/b}'; }

printf '  %-24s %5s\n' "${unit}s in window" "$total"
printf '  %-24s %5s   %s%%\n' "with an intent.md" "$intents" "$(pct "$intents" "$total")"
printf '  %-24s %5s   %s%%\n' "with a spec.md"    "$specs"   "$(pct "$specs" "$total")"
printf '  %-24s %5s   %s%%  <- coverage\n' "with a plan.md" "$plans" "$(pct "$plans" "$total")"

cov="$(pct "$plans" "$total")"
echo
if   [ "$cov" -eq 0 ];  then echo "  Not adopted yet. Run the chain on one real change, end to end, and commit all three."
elif [ "$cov" -lt 25 ]; then echo "  Piloting. Latency numbers from here describe the pilot, not the team."
elif [ "$cov" -lt 70 ]; then echo "  Partial adoption. Worth asking which changes skip the chain, and whether the reason is good."
else echo "  Adopted. The lagging indicators in docs/04-metrics.md are now the ones worth watching."
fi

cat <<'NOTE'

  Counting the introduction of an artifact, not its correctness. High coverage with thin specs is
  a different problem, and this script cannot see it.
NOTE
