#!/usr/bin/env bash
# Output helpers. Every mutating helper honours DRY_RUN.
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'; C_RED=$'\033[31m'; C_GRN=$'\033[32m'
  C_YEL=$'\033[33m'; C_OFF=$'\033[0m'
else
  C_BOLD=""; C_DIM=""; C_RED=""; C_GRN=""; C_YEL=""; C_OFF=""
fi

say()  { printf '%s\n' "$*"; }
head_() { printf '\n%s%s%s\n' "$C_BOLD" "$*" "$C_OFF"; }
ok()   { printf '  %s+%s %s\n' "$C_GRN" "$C_OFF" "$*"; }
same() { printf '  %s=%s %s %s(unchanged)%s\n' "$C_DIM" "$C_OFF" "$1" "$C_DIM" "$C_OFF"; }
warn() { printf '  %s!%s %s\n' "$C_YEL" "$C_OFF" "$*"; }
err()  { printf '%sERROR%s %s\n' "$C_RED" "$C_OFF" "$*" >&2; }
die()  { err "$*"; exit 1; }
plan() { printf '  %s→%s %s\n' "$C_DIM" "$C_OFF" "$*"; }

# sha256 of a file, portable across macOS and Linux.
sha_of() {
  [ -f "$1" ] || { printf 'absent'; return; }
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | cut -d' ' -f1
  elif command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1
  else cksum "$1" | cut -d' ' -f1; fi
}

# Path relative to the install target, for readable output.
relp() { printf '%s' "${1#"${TARGET:-}"/}"; }
