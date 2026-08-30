#!/usr/bin/env bash
# Stage 6 — the detection script. Deterministic; no model involved in deciding whether to act.
#
#   watch-band.sh [--config .sdlc-ai/bands.yaml] [--dry-run]
#
# Reads the metric, compares it to the rolling baseline, and invokes Claude at the tier the deviation
# earns. Run it from cron, a scheduled CI workflow, or a webhook receiver.
set -uo pipefail

config="${SDLC_BANDS:-.sdlc-ai/bands.yaml}"
dry_run=0
while [ $# -gt 0 ]; do
  case "$1" in
    --config) config="$2"; shift 2 ;;
    --dry-run) dry_run=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

command -v yq >/dev/null 2>&1 || { echo "watch-band.sh requires yq" >&2; exit 2; }
[ -f "$config" ] || { echo "No band config at $config" >&2; exit 2; }

metric="$(yq e '.metric' "$config")"
source_cmd="$(yq e '.source.command' "$config")"
history="${SDLC_BAND_HISTORY:-.sdlc-ai/band-history/${metric}.txt}"
mkdir -p "$(dirname "$history")"

value="$(eval "$source_cmd" 2>/dev/null | tail -1 | tr -d '[:space:]')"
case "$value" in
  ''|*[!0-9.-]*) echo "Metric '$metric' did not produce a number (got: '$value')" >&2; exit 1 ;;
esac

# Append first, so the baseline includes this reading whatever happens next.
printf '%s\n' "$value" >> "$history"

# Enough history for a baseline to mean anything?
count="$(wc -l < "$history" | tr -d ' ')"
if [ "$count" -lt 10 ]; then
  echo "$metric = $value — building baseline ($count/10 readings). No action."
  exit 0
fi

stats="$(awk '{s+=$1; ss+=$1*$1; n++} END {m=s/n; v=ss/n-m*m; if(v<0)v=0; printf "%.6f %.6f", m, sqrt(v)}' "$history")"
mean="${stats%% *}"
sd="${stats##* }"

if [ "$(awk -v s="$sd" 'BEGIN{print (s+0 < 1e-9) ? 1 : 0}')" = "1" ]; then
  echo "$metric = $value — baseline has no variance yet. No action."
  exit 0
fi

sigma="$(awk -v v="$value" -v m="$mean" -v s="$sd" 'BEGIN{d=(v-m)/s; if(d<0)d=-d; printf "%.2f", d}')"
tier=""
for t in 3 2 1; do
  if [ "$(awk -v x="$sigma" -v t="$t" 'BEGIN{print (x+0 >= t+0) ? 1 : 0}')" = "1" ]; then tier="${t}sigma"; break; fi
done

echo "$metric = $value  (mean $mean, sd $sd, $sigma sigma)"
[ -n "$tier" ] || { echo "Within band. No action."; exit 0; }

action="$(yq e ".tiers.${tier}.action" "$config")"
tools="$(yq e ".tiers.${tier}.tools // \"Read,Grep,Glob\"" "$config")"
echo "Band breached at ${tier} → action: ${action}"

[ "$action" = "log" ] && exit 0

prompt="The metric ${metric} read ${value}, which is ${sigma} standard deviations from its rolling
baseline (mean ${mean}, sd ${sd}). This is a ${tier} breach.

Investigate and report what changed. Use only evidence you can actually gather — logs, recent commits,
recent runs. State clearly what you confirmed and what is a hypothesis you could not confirm. Do not
present a plausible cause as an established one."

if [ "$action" = "propose" ]; then
  prompt="${prompt}

Then write your finding as sdlc/<slug>/intent.md using sdlc/templates/intent.md. Put the anomaly and
its evidence under Problem, set the author to the monitoring system, and put anything unconfirmed under
Open questions. Say whether a regression eval is owed.

Do not deploy, do not push, and do not act outside the routes this band permits."
fi

if [ "$dry_run" = "1" ]; then
  echo "--- dry run; would invoke claude with tools: $tools ---"
  printf '%s\n' "$prompt"
  exit 0
fi

command -v claude >/dev/null 2>&1 || { echo "claude CLI not found" >&2; exit 2; }
claude -p "$prompt" --allowedTools "$tools"
