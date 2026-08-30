#!/usr/bin/env bash
#
# The repo's one verification command. Exits non-zero on any failure.
#
#   1. Shell syntax on every script
#   2. JSON and YAML validity
#   3. Skill and subagent frontmatter
#   4. Manifest completeness — every kit file is installed by something
#   5. Hook block/allow behaviour
#   6. A full install → idempotency → conflict → profile-switch → uninstall round trip
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2
ROOT="$PWD"
FIXTURE="$ROOT/.check-fixture"
PASS=0; FAIL=0

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then G=$'\033[32m'; R=$'\033[31m'; B=$'\033[1m'; O=$'\033[0m'; else G=""; R=""; B=""; O=""; fi
sec() { printf '\n%s%s%s\n' "$B" "$1" "$O"; }
ok()  { printf '  %s✓%s %s\n' "$G" "$O" "$1"; PASS=$((PASS+1)); }
no()  { printf '  %s✗%s %s\n' "$R" "$O" "$1"; FAIL=$((FAIL+1)); }
t()   { if eval "$2" >/dev/null 2>&1; then ok "$1"; else no "$1"; fi; }

for dep in git jq yq python3; do
  command -v "$dep" >/dev/null 2>&1 || { echo "missing dependency: $dep" >&2; exit 2; }
done

sec "1. Shell syntax"
while IFS= read -r f; do
  if bash -n "$f" 2>/dev/null; then PASS=$((PASS+1)); else no "bash -n ${f#"$ROOT"/}"; fi
done < <(find . -name '*.sh' -not -path './.git/*' -not -path './.check-fixture/*')
ok "$(find . -name '*.sh' -not -path './.git/*' -not -path './.check-fixture/*' | wc -l | tr -d ' ') shell scripts parse"

sec "2. JSON and YAML"
while IFS= read -r f; do
  python3 -c "import json,sys;json.load(open(sys.argv[1]))" "$f" 2>/dev/null || no "invalid JSON: ${f#"$ROOT"/}"
done < <(find . -name '*.json' -not -path './.git/*' -not -path './.check-fixture/*')
ok "all JSON files parse"
while IFS= read -r f; do
  yq e 'true' "$f" >/dev/null 2>&1 || no "invalid YAML: ${f#"$ROOT"/}"
done < <(find . \( -name '*.yml' -o -name '*.yaml' -o -name '*.yaml.template' \) -not -path './.git/*' -not -path './.check-fixture/*')
ok "all YAML files parse"
t "plugin.json paths all resolve" \
  "python3 -c \"import json,os,sys; p=json.load(open('.claude-plugin/plugin.json')); m=[x for k in ('skills','agents','commands') for x in p.get(k,[]) if not os.path.exists(x.lstrip('./'))]; sys.exit(1 if m else 0)\""

t "every internal markdown link resolves" \
  "python3 -c \"
import re, sys, pathlib
bad = []
for md in pathlib.Path('.').rglob('*.md'):
    if '.git' in md.parts or '.check-fixture' in str(md): continue
    for m in re.finditer(r'\\[[^]]+\\]\\(([^)#]+?)(?:#[^)]*)?\\)', md.read_text()):
        t = m.group(1).strip()
        if t.startswith(('http://','https://','mailto:')): continue
        if not (md.parent / t).exists(): bad.append(f'{md}: {t}')
sys.exit(1 if bad else 0)\""
t "no absolute user paths committed" \
  "! grep -rIqE '(/Users/|/home/)[a-z]' --exclude-dir=.git --exclude-dir=.check-fixture ."

sec "3. Frontmatter"
for f in kit/claude/skills/*/SKILL.md kit/claude/agents/*.md kit/claude/commands/*.md; do
  n="${f#kit/claude/}"
  head -1 "$f" | grep -q '^---$' || { no "$n: no opening ---"; continue; }
  body="$(awk 'NR>1 && /^---$/{exit} NR>1{print}' "$f")"
  printf '%s\n' "$body" | yq e 'true' - >/dev/null 2>&1 || { no "$n: frontmatter is not valid YAML"; continue; }
  case "$f" in
    */commands/*) key="description" ;;
    *)            key="name" ;;
  esac
  printf '%s\n' "$body" | grep -q "^$key:" || { no "$n: frontmatter has no '$key'"; continue; }
  printf '%s\n' "$body" | grep -q "^description:" || { no "$n: frontmatter has no 'description'"; continue; }
  PASS=$((PASS+1))
done
ok "skills, agents and commands all carry valid frontmatter"

sec "4. Manifest completeness"
MISSING=0
while IFS= read -r f; do
  rel="${f#kit/}"
  case "$rel" in manifest.yaml|enterprise/*) continue ;; esac
  # A file is covered if the manifest names it, or names a directory containing it.
  if ! yq e -r '.modules[].entries[].src' kit/manifest.yaml | while read -r src; do
        case "$rel" in "$src"|"$src"/*) echo hit; break ;; esac
      done | grep -q hit; then
    no "not installed by any module: kit/$rel"; MISSING=$((MISSING+1))
  fi
done < <(find kit -type f)
[ "$MISSING" = "0" ] && ok "every kit file is covered by kit/manifest.yaml"
while IFS= read -r src; do
  [ -e "kit/$src" ] || no "manifest names a missing source: kit/$src"
done < <(yq e -r '.modules[].entries[].src' kit/manifest.yaml)
ok "every manifest source exists"

sec "5. Hook behaviour"
H="$ROOT/kit/claude/hooks"
HT="$ROOT/.check-fixture-hooks"; rm -rf "$HT"; mkdir -p "$HT/tests" "$HT/src/gen" "$HT/.sdlc-ai"
touch "$HT/tests/test_a.py" "$HT/src/app.py" "$HT/src/gen/api.py"
printf 'src/gen/**\n' > "$HT/.sdlc-ai/protected-paths.txt"
hook() { CLAUDE_PROJECT_DIR="$HT" ${3:-} bash "$H/$1" >/dev/null 2>&1 <<<"$2"; echo $?; }
hk()  { local got; got="$(CLAUDE_PROJECT_DIR="$HT" bash "$H/$1" >/dev/null 2>&1 <<<"$2"; echo $?)"
        if [ "$got" = "$3" ]; then ok "$4"; else no "$4 (expected exit $3, got $got)"; fi; }
hk no-remote-push.sh '{"tool_input":{"command":"git push origin main"}}'          2 "blocks git push"
hk no-remote-push.sh '{"tool_input":{"command":"make test && git push"}}'         2 "blocks a chained push"
hk no-remote-push.sh '{"tool_input":{"command":"gh pr create --fill"}}'           2 "blocks gh pr create"
hk no-remote-push.sh '{"tool_input":{"command":"gh api -X POST /repos/x/y"}}'     2 "blocks gh api writes"
hk no-remote-push.sh '{"tool_input":{"command":"git remote add up git@x:y"}}'     2 "blocks git remote add"
hk no-remote-push.sh '{"tool_input":{"command":"git status"}}'                    0 "allows git status"
hk no-remote-push.sh '{"tool_input":{"command":"git fetch origin"}}'              0 "allows git fetch"
hk no-remote-push.sh '{"tool_input":{"command":"gh pr view 12"}}'                 0 "allows gh pr view"
hk protect-tests.sh  "{\"tool_input\":{\"file_path\":\"$HT/tests/test_a.py\"}}"   2 "blocks editing an existing test"
hk protect-tests.sh  "{\"tool_input\":{\"file_path\":\"$HT/tests/test_new.py\"}}" 0 "allows creating a new test"
hk protect-tests.sh  "{\"tool_input\":{\"file_path\":\"$HT/src/app.py\"}}"        0 "allows editing source"
hk protect-paths.sh  "{\"tool_input\":{\"file_path\":\"$HT/src/gen/api.py\"}}"    2 "blocks a protected path"
hk protect-paths.sh  "{\"tool_input\":{\"file_path\":\"$HT/src/app.py\"}}"        0 "allows an unprotected path"
hk production-gate.sh '{"tool_input":{"command":"./deploy.sh production"}}'       2 "blocks an unauthorised production deploy"
hk production-gate.sh '{"tool_input":{"command":"./deploy.sh staging"}}'          0 "allows a staging deploy"
got="$(CLAUDE_PROJECT_DIR="$HT" SDLC_ALLOW_TEST_EDITS=1 bash "$H/protect-tests.sh" >/dev/null 2>&1 <<<"{\"tool_input\":{\"file_path\":\"$HT/tests/test_a.py\"}}"; echo $?)"
[ "$got" = "0" ] && ok "SDLC_ALLOW_TEST_EDITS escape hatch works" || no "SDLC_ALLOW_TEST_EDITS escape hatch"
got="$(CLAUDE_PROJECT_DIR="$HT" RELEASE_APPROVAL=CHG-1 bash "$H/production-gate.sh" >/dev/null 2>&1 <<<'{"tool_input":{"command":"./deploy.sh production"}}'; echo $?)"
[ "$got" = "0" ] && ok "RELEASE_APPROVAL authorises a production deploy" || no "RELEASE_APPROVAL gate"
rm -rf "$HT"

sec "6. Install round trip"
rm -rf "$FIXTURE"; mkdir -p "$FIXTURE/.claude" "$FIXTURE/.github/workflows" "$FIXTURE/tests" "$FIXTURE/src"
(
  cd "$FIXTURE" || exit 1
  git init -q -b main
  git config user.email check@example.invalid; git config user.name check
  printf '# Fixture\n\n## Invariants\n1. Never do the bad thing.\n' > CLAUDE.md
  echo '{ "permissions": { "allow": ["Bash(make test)"] }, "enabledMcpjsonServers": ["playwright"] }' > .claude/settings.json
  printf 'name: ci\non: [push]\n' > .github/workflows/ci.yml
  printf '.venv/\n\n# local agent config\n.claude/\n' > .gitignore
  touch tests/test_thing.py src/app.py
  git add -A && git commit -qm baseline
)
t "refuses to install while .claude/ is gitignored" "! install/install.sh --target '$FIXTURE' --dry-run"
t "the refusal wrote nothing"                       "[ -z \"\$(git -C '$FIXTURE' status --porcelain)\" ]"
( cd "$FIXTURE" && printf '.venv/\n.claude/settings.local.json\n.claude/worktrees/\n' > .gitignore && git add -A && git commit -qm unignore )
t "dry run succeeds"        "install/install.sh --target '$FIXTURE' --profile trunk-local --dry-run"
t "dry run wrote nothing"   "[ -z \"\$(git -C '$FIXTURE' status --porcelain)\" ]"
t "install succeeds"        "install/install.sh --target '$FIXTURE' --profile trunk-local"
t "CLAUDE.md kept its heading"        "grep -q '^# Fixture' '$FIXTURE/CLAUDE.md'"
t "CLAUDE.md kept its invariant"      "grep -q 'Never do the bad thing' '$FIXTURE/CLAUDE.md'"
t "CLAUDE.md gained exactly 2 blocks" "[ \$(grep -c 'sdlc-ai:begin' '$FIXTURE/CLAUDE.md') -eq 2 ]"
t "settings.json kept its permission" "jq -e '.permissions.allow|index(\"Bash(make test)\")' '$FIXTURE/.claude/settings.json'"
t "settings.json kept its mcp server" "jq -e '.enabledMcpjsonServers|index(\"playwright\")' '$FIXTURE/.claude/settings.json'"
t "settings.json gained the hooks"    "jq -e '.hooks.PreToolUse|length==2' '$FIXTURE/.claude/settings.json'"
t "existing ci.yml untouched"         "git -C '$FIXTURE' diff --quiet -- .github/workflows/ci.yml"
t "no spurious .sdlc-ai-new"          "[ -z \"\$(find '$FIXTURE' -name '*.sdlc-ai-new')\" ]"
t "trunk-local assets present"        "[ -x '$FIXTURE/.claude/hooks/no-remote-push.sh' ] && [ -x '$FIXTURE/ci/local/pre-merge-gate.sh' ]"
t "pr-github assets absent"           "[ ! -e '$FIXTURE/.claude/hooks/production-gate.sh' ] && [ ! -e '$FIXTURE/.github/workflows/claude-review.yml' ]"
BEFORE="$(git -C "$FIXTURE" status --porcelain | sort)"
OUT="$(install/install.sh --target "$FIXTURE" --profile trunk-local 2>&1)"
t "second run is a no-op"             "[ \"\$(git -C '$FIXTURE' status --porcelain | sort)\" = \"\$BEFORE\" ]"
t "second run wrote 0 files"          "echo \"\$OUT\" | grep -q '0 file(s) written'"
t "hooks not duplicated"              "jq -e '.hooks.PreToolUse|length==2' '$FIXTURE/.claude/settings.json'"
t "blocks not duplicated"             "[ \$(grep -c 'sdlc-ai:begin' '$FIXTURE/CLAUDE.md') -eq 2 ]"
echo '# local tweak' >> "$FIXTURE/REVIEW.md"; cp "$FIXTURE/REVIEW.md" "$FIXTURE/../.check-review"
OUT="$(install/install.sh --target "$FIXTURE" --profile trunk-local 2>&1)"
t "an edited file is preserved"       "cmp -s '$FIXTURE/REVIEW.md' '$FIXTURE/../.check-review'"
t "the conflict is reported"          "echo \"\$OUT\" | grep -q 'REVIEW.md exists and differs'"
t "the new version lands beside it"   "[ -f '$FIXTURE/REVIEW.md.sdlc-ai-new' ]"
rm -f "$FIXTURE/REVIEW.md.sdlc-ai-new" "$FIXTURE/../.check-review"
cp kit/review/REVIEW.md "$FIXTURE/REVIEW.md"
OUT="$(install/install.sh --target "$FIXTURE" --profile pr-github 2>&1)"
t "profile switch removes old assets" "[ ! -e '$FIXTURE/.claude/hooks/no-remote-push.sh' ] && [ ! -e '$FIXTURE/ci/local/pre-merge-gate.sh' ]"
t "profile switch adds new assets"    "[ -x '$FIXTURE/.claude/hooks/production-gate.sh' ] && [ -f '$FIXTURE/.github/workflows/claude-review.yml' ]"
t "profile switch keeps shared ones"  "[ -x '$FIXTURE/.claude/hooks/protect-tests.sh' ] && [ -f '$FIXTURE/sdlc/README.md' ]"
t "the settings.json caveat is stated" "echo \"\$OUT\" | grep -q 'still registered'"
install/install.sh --target "$FIXTURE" --profile trunk-local >/dev/null 2>&1
t "uninstall succeeds"                "install/uninstall.sh --target '$FIXTURE'"
t "CLAUDE.md restored"                "git -C '$FIXTURE' diff --quiet -- CLAUDE.md"
t "settings.json restored"            "git -C '$FIXTURE' diff --quiet -- .claude/settings.json"
t "the fixture is byte-identical to its baseline" "[ -z \"\$(git -C '$FIXTURE' status --porcelain)\" ]"
rm -rf "$FIXTURE"

sec "Result"
if [ "$FAIL" -eq 0 ]; then
  printf '  %s%d checks passed%s\n\n' "$G" "$PASS" "$O"; exit 0
else
  printf '  %s%d passed, %d FAILED%s\n\n' "$R" "$PASS" "$FAIL" "$O"; exit 1
fi
