#!/usr/bin/env bash
# PreToolUse(Bash) — pr-github profile. A production deploy requires a named release authorisation.
# The agent does everything up to this gate and nothing past it.
#
# Configure what counts as a production deploy in .sdlc-ai/production-gate.txt (one extended-regex
# per line). Without that file the default below matches the common shapes.
set -uo pipefail
# shellcheck source=_sdlc_lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/_sdlc_lib.sh"

sdlc_require_parser
sdlc_read_payload

cmd="$(sdlc_json '.tool_input.command')"
[ -n "$cmd" ] || exit 0

matched=0
patterns_file="$(sdlc_config production-gate.txt)"
if [ -n "$patterns_file" ]; then
  while IFS= read -r pat; do
    case "$pat" in ''|'#'*) continue ;; esac
    printf '%s' "$cmd" | grep -Eq "$pat" && { matched=1; break; }
  done < "$patterns_file"
else
  printf '%s' "$cmd" | grep -Eqi 'deploy' && \
  printf '%s' "$cmd" | grep -Eqi '\b(prod|production)\b' && matched=1
fi
[ "$matched" = "1" ] || exit 0

if [ -n "${RELEASE_APPROVAL:-}" ]; then
  echo "sdlc-ai: production deploy authorised by RELEASE_APPROVAL=${RELEASE_APPROVAL}" >&2
  exit 0
fi

cat >&2 <<MSG
BLOCKED: this looks like a production deploy, and no release authorisation is present.

Production deploys need a named human authorisation. Set RELEASE_APPROVAL to the release
authorisation reference (change ticket, release manager sign-off) in the environment that runs
the deploy.

Prepare everything up to this point — build, tests, changelog, the deploy command itself — and
hand it to the release manager. Do not deploy to another environment as a substitute, and do not
look for an unguarded path to the same effect.
MSG
exit 2
