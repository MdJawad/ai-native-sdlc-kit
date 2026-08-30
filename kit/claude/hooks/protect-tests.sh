#!/usr/bin/env bash
# PreToolUse(Edit|Write|MultiEdit|NotebookEdit) — an agent must not edit an existing test to make a
# failure go away. Stage 4a: write the failing test first, then fix the code, not the test.
#
# Deliberately narrow, so it does not get in the way of real work:
#   - creating a NEW test file is allowed (landing an acceptance test is the point);
#   - editing an EXISTING, tracked test file is blocked;
#   - SDLC_ALLOW_TEST_EDITS=1 is the documented escape hatch for a genuine test refactor.
set -uo pipefail
# shellcheck source=_sdlc_lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/_sdlc_lib.sh"

sdlc_require_parser
sdlc_read_payload

[ "${SDLC_ALLOW_TEST_EDITS:-0}" = "1" ] && exit 0

file_path="$(sdlc_json '.tool_input.file_path')"
[ -n "$file_path" ] || exit 0

# Test-path patterns. Override by listing your own (one extended-regex per line) in
# .sdlc-ai/test-patterns.txt.
patterns_file="$(sdlc_config test-patterns.txt)"
if [ -n "$patterns_file" ]; then
  matched=0
  while IFS= read -r pat; do
    case "$pat" in ''|'#'*) continue ;; esac
    if printf '%s' "$file_path" | grep -Eq "$pat"; then matched=1; break; fi
  done < "$patterns_file"
else
  matched=0
  printf '%s' "$file_path" | grep -Eq \
    '(^|/)(tests?|spec|__tests__|itest)/|(^|/)(test_[^/]+|[^/]+_test)\.(py|go|rb|rs|java|kt)$|\.(test|spec)\.(js|jsx|ts|tsx)$|Test[^/]*\.(java|kt|cs)$' \
    && matched=1
fi
[ "$matched" = "1" ] || exit 0

# New file? Allow — landing a new test is encouraged.
[ -e "$file_path" ] || exit 0

cat >&2 <<MSG
BLOCKED: $file_path is an existing test file.

Tests are the evidence a change works, so they are not edited to make a failure go away.
If a test is failing, fix the code it is testing.

If this is a legitimate test change — a new case, a refactor, an assertion that was genuinely
wrong — say so and ask the user to re-run with SDLC_ALLOW_TEST_EDITS=1, or to make the edit
themselves. Do not work around this by writing the file another way.
MSG
exit 2
