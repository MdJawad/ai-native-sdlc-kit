#!/usr/bin/env bash
# PostToolUse(Edit|Write|MultiEdit) — run the repo's formatter after an edit so style never drifts
# and never becomes something a human reviews.
#
# Set the command in .sdlc-ai/format-command.txt (a single line, run from the repo root; the edited
# file's path is appended). No file means this hook does nothing.
#
# Advisory by nature: this hook never blocks. A formatter failure is reported, not fatal.
set -uo pipefail
# shellcheck source=_sdlc_lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/_sdlc_lib.sh"

command -v jq >/dev/null 2>&1 || command -v python3 >/dev/null 2>&1 || exit 0
sdlc_read_payload

file_path="$(sdlc_json '.tool_input.file_path')"
[ -n "$file_path" ] || exit 0
[ -f "$file_path" ] || exit 0

cmd_file="$(sdlc_config format-command.txt)"
[ -n "$cmd_file" ] || exit 0
fmt="$(grep -v '^[[:space:]]*#' "$cmd_file" | grep -v '^[[:space:]]*$' | head -1)"
[ -n "$fmt" ] || exit 0

cd "$(sdlc_project_dir)" || exit 0
if ! out="$(eval "$fmt \"$file_path\"" 2>&1)"; then
  echo "sdlc-ai: formatter failed on $file_path" >&2
  echo "$out" >&2
fi
exit 0
