#!/usr/bin/env bash
# PreToolUse(Bash) — trunk-local profile. Remote write operations are the user's decision, made by
# hand after review. This is the deterministic form of the rule most repos write in prose and hope for.
#
# Blocked:  git push · git remote add/set-url/remove · git send-email
#           gh pr create/merge/close · gh release create · gh repo create/delete
#           gh api with a write method
# Allowed:  everything read-only, including git fetch/pull and gh pr view / gh run view.
set -uo pipefail
# shellcheck source=_sdlc_lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/_sdlc_lib.sh"

sdlc_require_parser
sdlc_read_payload

cmd="$(sdlc_json '.tool_input.command')"
[ -n "$cmd" ] || exit 0

deny() {
  cat >&2 <<MSG
BLOCKED: $1

Remote write operations are the user's to make, by hand, after they have reviewed the change.
Work here merges locally into the trunk; nothing is pushed from a session.

Do this instead: finish the change, get the verification command green, and commit on your own
branch. Then tell the user exactly what you would push and let them run it. Do not look for
another route to the same effect.
MSG
  exit 2
}

# Normalise: strip quotes so `git "push"` is caught, collapse whitespace.
norm="$(printf '%s' "$cmd" | tr -d '"'\''' | tr -s '[:space:]' ' ')"

printf '%s' "$norm" | grep -Eq '(^|[;&|] *)git +([^ ]+ +)*push\b'            && deny "git push"
printf '%s' "$norm" | grep -Eq '(^|[;&|] *)git +([^ ]+ +)*remote +(add|set-url|remove|rm)\b' && deny "git remote write"
printf '%s' "$norm" | grep -Eq '(^|[;&|] *)git +([^ ]+ +)*send-email\b'      && deny "git send-email"
printf '%s' "$norm" | grep -Eq '(^|[;&|] *)gh +pr +(create|merge|close|edit|ready|review)\b'  && deny "gh pr write"
printf '%s' "$norm" | grep -Eq '(^|[;&|] *)gh +(release|repo|workflow) +(create|delete|edit|run)\b' && deny "gh write"
printf '%s' "$norm" | grep -Eq '(^|[;&|] *)gh +api\b.*(-X|--method) *(POST|PUT|PATCH|DELETE)' && deny "gh api write"

exit 0
