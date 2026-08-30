#!/usr/bin/env bash
#
# sdlc-ai — remove the kit from a repository, using the lock file so the removal is exact.
#
#   uninstall.sh --target <repo> [--dry-run] [--force]
#
# Files we created and you have not modified are removed. Files we modified in place (CLAUDE.md,
# .claude/settings.json) are restored from the backup taken at install time. Anything you edited is
# LEFT ALONE and reported — this script will not destroy your work to tidy up.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lib/log.sh"
. "$HERE/lib/manifest.sh"

TARGET=""; DRY_RUN=0; FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --force) FORCE=1; shift ;;
    -h|--help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

[ -n "$TARGET" ] || die "--target is required"
TARGET="$(cd "$TARGET" 2>/dev/null && pwd)" || die "target directory does not exist"
LOCK="$(lock_path)"
[ -f "$LOCK" ] || die "no $LOCK_REL in $TARGET — nothing recorded to remove"

head_ "sdlc-ai uninstall → $TARGET"
grep '^meta ' "$LOCK" | sed 's/^meta /  /'
[ "$DRY_RUN" = "1" ] && say "  ${C_YEL}DRY RUN — nothing will be changed${C_OFF}"

REMOVED=0; KEPT=0; RESTORED=0

head_ "Files we created"
while read -r _ recorded rel; do
  abs="$TARGET/$rel"
  [ -e "$abs" ] || continue
  if [ "$(sha_of "$abs")" != "$recorded" ]; then
    warn "$rel — you edited this; keeping it"
    KEPT=$((KEPT + 1)); continue
  fi
  if [ "$DRY_RUN" = "1" ]; then plan "remove $rel"; else rm -f "$abs"; ok "removed $rel"; fi
  REMOVED=$((REMOVED + 1))
done < <(grep '^file ' "$LOCK")

head_ "Files we modified in place"
while read -r _ rel; do
  backup="$(backup_dir)/$rel"
  abs="$TARGET/$rel"
  if [ ! -f "$backup" ]; then warn "$rel — no backup recorded; leaving it alone"; KEPT=$((KEPT + 1)); continue; fi
  if [ "$DRY_RUN" = "1" ]; then plan "restore $rel from backup"; else cp "$backup" "$abs"; ok "restored $rel"; fi
  RESTORED=$((RESTORED + 1))
done < <(grep '^patch ' "$LOCK")

if [ "$DRY_RUN" != "1" ]; then
  # Prune directories we emptied, then the kit's own state — but only if nothing was kept.
  find "$TARGET/.claude" "$TARGET/sdlc" "$TARGET/evals" "$TARGET/scripts/sdlc" -type d -empty -delete 2>/dev/null
  if [ "$KEPT" = "0" ] || [ "$FORCE" = "1" ]; then
    rm -rf "$TARGET/.sdlc-ai"
    ok "removed .sdlc-ai/"
  else
    warn ".sdlc-ai/ kept — it holds the backups for the $KEPT file(s) left in place"
  fi
fi

head_ "Result"
say "  $REMOVED removed · $RESTORED restored · $KEPT kept because you had edited them"
[ "$KEPT" -gt 0 ] && say "  Review the kept files by hand; nothing you wrote was discarded."
exit 0
