#!/usr/bin/env bash
# PreToolUse(Edit|Write|MultiEdit|NotebookEdit) — refuse edits to protected paths: generated code,
# frozen packages, vendored directories, anything a platform team owns.
#
# Patterns live in .sdlc-ai/protected-paths.txt, one glob per line, relative to the repo root.
# No file means nothing is protected — this hook is inert until you configure it.
set -uo pipefail
# shellcheck source=_sdlc_lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/_sdlc_lib.sh"

sdlc_require_parser
sdlc_read_payload

file_path="$(sdlc_json '.tool_input.file_path')"
[ -n "$file_path" ] || exit 0

patterns_file="$(sdlc_config protected-paths.txt)"
[ -n "$patterns_file" ] || exit 0

root="$(sdlc_project_dir)"
rel="${file_path#"$root"/}"

while IFS= read -r line; do
  pat="${line%%#*}"
  pat="$(printf '%s' "$pat" | sed 's/[[:space:]]*$//')"
  [ -n "$pat" ] || continue
  # shellcheck disable=SC2254
  if [[ "$rel" == $pat || "$file_path" == $pat ]]; then
    cat >&2 <<MSG
BLOCKED: $rel is a protected path (matched "$pat" in .sdlc-ai/protected-paths.txt).

This path is owned elsewhere — generated output, a frozen package, or a platform-team
dependency. Editing it here would be overwritten or would breach an ownership boundary.

Change the source that generates it, or the unfrozen equivalent. If the change genuinely
belongs here, it needs the path's owner, not a workaround.
MSG
    exit 2
  fi
done < "$patterns_file"
exit 0
