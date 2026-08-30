#!/usr/bin/env bash
#
# sdlc-ai — install the AI-native SDLC kit into a repository.
#
#   install.sh --target <repo> [--profile trunk-local|pr-github] [--modules a,b,c]
#              [--artifacts-dir sdlc] [--dry-run] [--force]
#
# Idempotent. Merges rather than overwrites. Never touches anything it did not write, and records
# what it did in <target>/.sdlc-ai/manifest.lock so upgrade and uninstall are exact.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
KIT="$(cd "$HERE/.." && pwd)/kit"
. "$HERE/lib/log.sh"
. "$HERE/lib/manifest.sh"
. "$HERE/lib/merge_json.sh"
. "$HERE/lib/merge_block.sh"

TARGET=""; PROFILE="trunk-local"; MODULES="all"; ARTIFACTS_DIR="sdlc"
DRY_RUN=0; FORCE=0
KIT_VERSION="$(yq e -r '.version' "$KIT/manifest.yaml" 2>/dev/null || echo unknown)"

usage() { sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --profile) PROFILE="$2"; shift 2 ;;
    --modules) MODULES="$2"; shift 2 ;;
    --artifacts-dir) ARTIFACTS_DIR="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --force) FORCE=1; shift ;;
    -h|--help) usage 0 ;;
    *) err "unknown argument: $1"; usage 2 ;;
  esac
done

# ── Preflight ───────────────────────────────────────────────────────────────
[ -n "$TARGET" ] || die "--target is required. Run with --help."
TARGET="$(cd "$TARGET" 2>/dev/null && pwd)" || die "target directory does not exist"
[ -d "$TARGET/.git" ] || die "$TARGET is not a git repository. The artifacts and the audit trail are commits; this kit needs git."
case "$PROFILE" in trunk-local|pr-github) ;; *) die "unknown profile '$PROFILE' (expected trunk-local or pr-github)" ;; esac
command -v yq >/dev/null 2>&1 || die "yq is required to read the kit manifest"
command -v jq >/dev/null 2>&1 || die "jq is required to merge settings.json (and by the hooks at runtime)"

ALL_MODULES="$(yq e -r '.modules | keys | join(",")' "$KIT/manifest.yaml")"
[ "$MODULES" = "all" ] && MODULES="$ALL_MODULES"
for m in ${MODULES//,/ }; do
  printf '%s' ",$ALL_MODULES," | grep -q ",$m," || die "unknown module '$m'. Available: $ALL_MODULES"
done

head_ "sdlc-ai v$KIT_VERSION → $TARGET"
say   "  profile:  $PROFILE"
say   "  modules:  $MODULES"
[ "$DRY_RUN" = "1" ] && say "  ${C_YEL}DRY RUN — nothing will be written${C_OFF}"

# ── The .gitignore check. Not a warning; a stop. ─────────────────────────────
if git -C "$TARGET" check-ignore -q .claude 2>/dev/null; then
  head_ "${C_RED}Blocked: .claude/ is gitignored in this repository${C_OFF}"
  cat <<'MSG'
  Everything this kit installs under .claude/ — skills, hooks, subagents, settings — is meant to be
  reviewed, owned and diffed like any other code. Installing it into an ignored directory produces a
  setup that works on your machine and exists nowhere else.

  Replace the blanket ignore with the two things that genuinely are local:

      # Agent configuration is reviewed code — only these are local
      .claude/settings.local.json
      .claude/worktrees/

  Then re-run. Use --force to install anyway; the files will not be version-controlled.
MSG
  [ "$FORCE" = "1" ] || exit 1
  warn "--force given; continuing with .claude/ ignored"
fi

remap() { # artifacts live under --artifacts-dir
  case "$1" in
    sdlc/*) printf '%s/%s' "$ARTIFACTS_DIR" "${1#sdlc/}" ;;
    *) printf '%s' "$1" ;;
  esac
}

# ── Profile switch: retire the previous profile's Stage 5 assets ────────────
PREV_PROFILE=""
if [ -f "$(lock_path)" ]; then
  PREV_PROFILE="$(awk '$1=="meta"{for(i=2;i<=NF;i++){split($i,kv,"=");if(kv[1]=="profile")print kv[2]}}' "$(lock_path)" | head -1)"
fi
if [ -n "$PREV_PROFILE" ] && [ "$PREV_PROFILE" != "$PROFILE" ]; then
  head_ "Switching profile: $PREV_PROFILE → $PROFILE"
  while IFS='|' read -r _m prof _mode _src dest; do
    [ "$prof" = "$PREV_PROFILE" ] || continue
    dest="$(remap "$dest")"
    [ -e "$TARGET/$dest" ] || continue
    case "$dest" in *settings.json) continue ;; esac   # merged, not owned — left for the user
    if lock_owns_unmodified "$dest"; then
      if [ "$DRY_RUN" = "1" ]; then plan "remove $dest (belongs to $PREV_PROFILE)"
      else rm -f "$TARGET/$dest"; ok "removed $dest (belongs to $PREV_PROFILE)"; fi
    else
      warn "$dest belongs to $PREV_PROFILE but you edited it — keeping it"
    fi
  done < <(yq e -r '.modules | to_entries | .[] | .value.entries[] | [.src, (.profile // "any"), .mode, .src, .dest] | join("|")' "$KIT/manifest.yaml")
  warn "The $PREV_PROFILE hook is still registered in .claude/settings.json — remove that entry by hand."
fi

# ── Apply ───────────────────────────────────────────────────────────────────
lock_init; lock_meta
CONFLICTS=0; WROTE=0; MERGE_FAILURES=0

# place <src-abs> <dest-rel> <executable 0|1>
place() {
  local src="$1" rel="$2" exe="$3" abs="$TARGET/$2"
  if [ -f "$abs" ] && ! cmp -s "$src" "$abs"; then
    if lock_owns_unmodified "$rel"; then
      : # we wrote it and nobody has touched it — safe to update
    else
      if [ "$DRY_RUN" = "1" ]; then
        warn "$rel exists and differs → would write $rel.sdlc-ai-new"
      else
        cp "$src" "$abs.sdlc-ai-new"
        warn "$rel exists and differs → wrote $rel.sdlc-ai-new (merge it by hand)"
      fi
      CONFLICTS=$((CONFLICTS + 1)); return
    fi
  fi
  if cmp -s "$src" "$abs" 2>/dev/null; then same "$rel"; lock_file "$rel"; return; fi
  if [ "$DRY_RUN" = "1" ]; then plan "write $rel"; WROTE=$((WROTE + 1)); return; fi
  mkdir -p "$(dirname "$abs")"
  cp "$src" "$abs"
  [ "$exe" = "1" ] && chmod +x "$abs"
  ok "$rel"; lock_file "$rel"; WROTE=$((WROTE + 1))
}

CURRENT_MODULE=""
while IFS='|' read -r module profile mode src dest; do
  [ -n "$module" ] || continue
  printf '%s' ",$MODULES," | grep -q ",$module," || continue
  [ "$profile" = "any" ] || [ "$profile" = "$PROFILE" ] || continue

  if [ "$module" != "$CURRENT_MODULE" ]; then
    head_ "$module — $(yq e -r ".modules.\"$module\".description" "$KIT/manifest.yaml")"
    CURRENT_MODULE="$module"
  fi

  dest="$(remap "$dest")"
  case "$mode" in
    tree)
      [ -d "$KIT/$src" ] || { err "missing kit directory: $src"; continue; }
      while IFS= read -r f; do
        rel="${f#"$KIT/$src"/}"
        place "$f" "$dest/$rel" 0
      done < <(find "$KIT/$src" -type f | sort)
      ;;
    copy) place "$KIT/$src" "$dest" 0 ;;
    exec) place "$KIT/$src" "$dest" 1 ;;
    create-if-absent)
      if [ -e "$TARGET/$dest" ]; then same "$dest (kept — create-if-absent)"
      elif [ "$DRY_RUN" = "1" ]; then plan "create $dest"; WROTE=$((WROTE + 1))
      else mkdir -p "$(dirname "$TARGET/$dest")"; cp "$KIT/$src" "$TARGET/$dest"; ok "$dest"; lock_file "$dest"; WROTE=$((WROTE + 1)); fi
      ;;
    json)  json_merge  "$KIT/$src" "$TARGET/$dest" || MERGE_FAILURES=$((MERGE_FAILURES + 1)) ;;
    block) block_merge "$KIT/$src" "$TARGET/$dest" || MERGE_FAILURES=$((MERGE_FAILURES + 1)) ;;
    *) err "unknown mode '$mode' for $src" ;;
  esac
done < <(yq e -r '.modules | to_entries | .[] | .key as $m | .value.entries[] | [$m, (.profile // "any"), .mode, .src, .dest] | join("|")' "$KIT/manifest.yaml")

lock_commit

# ── Report ──────────────────────────────────────────────────────────────────
head_ "Result"
if [ "$DRY_RUN" = "1" ]; then
  say "  Dry run. $WROTE file(s) would be written, $CONFLICTS conflict(s) would need a manual merge."
  say "  Nothing was written to $TARGET."
else
  say "  $WROTE file(s) written, $CONFLICTS conflict(s) left as .sdlc-ai-new for you to merge."
  say "  Recorded in $LOCK_REL."
fi

head_ "Next"
cat <<'MSG'
  1. Fill in the placeholders in CLAUDE.md — the verification block needs your real commands, and
     they are what let a session check its own work.
  2. Edit REVIEW.md: the "Do not report" list, and the nit cap. A review policy nobody has edited
     is one nobody has agreed to.
  3. Configure the guards you want, in .sdlc-ai/:
       protected-paths.txt   one glob per line — generated code, frozen packages, vendored trees
       format-command.txt    one line — your formatter, run after every edit
  4. Read sdlc/README.md, then run the chain on one real change: /intent → /spec → /plan.
  5. Commit it. The artifacts are the audit trail, and they only count once they are committed.

  Adapt the exemplars before relying on them: kit/claude/skills/secure-api-review is a worked
  example carrying someone else's rules, and evals/cases/ assumes things about your repo that are
  probably not true.
MSG
[ "$CONFLICTS" -gt 0 ] && say "" && warn "Search for *.sdlc-ai-new to finish the merge."
if [ "$MERGE_FAILURES" -gt 0 ]; then
  say ""; err "$MERGE_FAILURES in-place merge(s) failed — the install is incomplete. Fix the reported file and re-run."
  exit 1
fi
exit 0
