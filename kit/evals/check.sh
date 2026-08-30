#!/usr/bin/env bash
# check.sh <case.json> <result.json> [workdir]
#
# Evaluates one eval case's checks against the state left behind by a Claude run.
# Exits 0 if every check passes, 1 otherwise. Prints one line per check.
set -uo pipefail

case_file="${1:?usage: check.sh <case.json> <result.json> [workdir]}"
result_file="${2:?usage: check.sh <case.json> <result.json> [workdir]}"
workdir="${3:-.}"

command -v jq >/dev/null 2>&1 || { echo "check.sh requires jq" >&2; exit 2; }

id="$(jq -r '.id // "unnamed"' "$case_file")"
failed=0

# The assistant's final message, however the harness spelled it.
final_text="$(jq -r '(.result // .response // .messages[-1].content // "") | if type=="array" then map(.text? // "") | join("\n") else . end' "$result_file" 2>/dev/null || echo "")"

pass() { printf '    PASS  %s\n' "$1"; }
fail() { printf '    FAIL  %s\n' "$1"; failed=1; }

while IFS= read -r chk; do
  [ -n "$chk" ] || continue
  ctype="$(printf '%s' "$chk" | jq -r '.type')"
  case "$ctype" in
    file_contains)
      p="$(printf '%s' "$chk" | jq -r '.path')"; pat="$(printf '%s' "$chk" | jq -r '.pattern')"
      if [ -f "$workdir/$p" ] && grep -qE -- "$pat" "$workdir/$p"; then
        pass "file_contains $p =~ /$pat/"
      else
        fail "file_contains $p =~ /$pat/"
      fi
      ;;
    file_not_contains)
      p="$(printf '%s' "$chk" | jq -r '.path')"; pat="$(printf '%s' "$chk" | jq -r '.pattern')"
      if [ ! -f "$workdir/$p" ] || ! grep -qE -- "$pat" "$workdir/$p"; then
        pass "file_not_contains $p !~ /$pat/"
      else
        fail "file_not_contains $p !~ /$pat/"
      fi
      ;;
    file_exists)
      p="$(printf '%s' "$chk" | jq -r '.path')"
      [ -e "$workdir/$p" ] && pass "file_exists $p" || fail "file_exists $p"
      ;;
    file_unchanged)
      p="$(printf '%s' "$chk" | jq -r '.path')"
      if git -C "$workdir" diff --quiet -- "$p" 2>/dev/null; then
        pass "file_unchanged $p"
      else
        fail "file_unchanged $p (the agent modified it)"
      fi
      ;;
    command)
      run="$(printf '%s' "$chk" | jq -r '.run')"
      if (cd "$workdir" && eval "$run") >/dev/null 2>&1; then
        pass "command exits 0: $run"
      else
        fail "command exits 0: $run"
      fi
      ;;
    command_fails)
      run="$(printf '%s' "$chk" | jq -r '.run')"
      if (cd "$workdir" && eval "$run") >/dev/null 2>&1; then
        fail "command_fails (it succeeded): $run"
      else
        pass "command_fails: $run"
      fi
      ;;
    output_contains)
      pat="$(printf '%s' "$chk" | jq -r '.pattern')"
      if printf '%s' "$final_text" | grep -qEi -- "$pat"; then
        pass "output_contains /$pat/"
      else
        fail "output_contains /$pat/"
      fi
      ;;
    *)
      fail "unknown check type: $ctype"
      ;;
  esac
done < <(jq -c '.checks[]' "$case_file")

if [ "$failed" = "0" ]; then
  printf '  ✓ %s\n' "$id"; exit 0
else
  printf '  ✗ %s\n' "$id"; exit 1
fi
