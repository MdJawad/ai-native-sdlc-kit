#!/usr/bin/env bash
# Shared helpers for the sdlc-ai hooks. Sourced, never executed directly.
#
# Hook contract (Claude Code):
#   stdin  — a JSON object describing the tool call
#   exit 0 — allow
#   exit 2 — BLOCK. stderr is fed back to Claude, so the message must say what to do instead.
#   other  — non-blocking error, surfaced to the user
#
# These hooks are deterministic controls, so they FAIL CLOSED: if no JSON parser is available
# the hook blocks rather than waving the call through. See docs/03-governance.md.

sdlc_payload=""

sdlc_read_payload() {
  sdlc_payload="$(cat)"
}

# sdlc_json <jq-path> — e.g. sdlc_json '.tool_input.command'
# Prints the value, or an empty string if absent/null.
sdlc_json() {
  local path="$1"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$sdlc_payload" | jq -r "$path // \"\"" 2>/dev/null
    return
  fi
  if command -v python3 >/dev/null 2>&1; then
    printf '%s' "$sdlc_payload" | python3 -c '
import json, sys
path = sys.argv[1].lstrip(".").split(".")
try:
    node = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for key in path:
    if isinstance(node, dict) and key in node:
        node = node[key]
    else:
        sys.exit(0)
if node is not None:
    sys.stdout.write(node if isinstance(node, str) else json.dumps(node))
' "$path" 2>/dev/null
    return
  fi
  # No parser. Signal the caller to fail closed.
  return 1
}

sdlc_require_parser() {
  if ! command -v jq >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
    echo "sdlc-ai hook: neither jq nor python3 is available, so this guard cannot read the tool call." >&2
    echo "Install jq. This hook fails closed by design — a guard that cannot inspect the call must not allow it." >&2
    exit 2
  fi
}

# Repo root, preferring the project dir Claude Code exports.
sdlc_project_dir() {
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
    printf '%s' "$CLAUDE_PROJECT_DIR"
  else
    git rev-parse --show-toplevel 2>/dev/null || pwd
  fi
}

# sdlc_config <filename> — path to a config file under .sdlc-ai/, or empty if absent.
sdlc_config() {
  local f
  f="$(sdlc_project_dir)/.sdlc-ai/$1"
  [ -f "$f" ] && printf '%s' "$f"
}
