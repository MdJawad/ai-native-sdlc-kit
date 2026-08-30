#!/usr/bin/env bash
# The target-side lock file: what we installed, so upgrade and uninstall are exact rather than guesswork.
#
#   .sdlc-ai/manifest.lock
#     meta   kit_version=0.1.0 profile=trunk-local modules=skills,hooks installed_at=...
#     file   <sha256>  <path>      a file we created — uninstall removes it if unmodified
#     patch  <path>                a file we modified in place — uninstall restores from backup

LOCK_REL=".sdlc-ai/manifest.lock"
BACKUP_REL=".sdlc-ai/backups"

lock_path()   { printf '%s/%s' "$TARGET" "$LOCK_REL"; }
backup_dir()  { printf '%s/%s' "$TARGET" "$BACKUP_REL"; }

lock_init() {
  [ "${DRY_RUN:-0}" = "1" ] && return 0
  mkdir -p "$(dirname "$(lock_path)")"
  : > "$(lock_path).new"
  # Carry forward the record of files we patched in place. A re-install often re-merges nothing
  # (everything already matches), so these would otherwise be lost from the lock and uninstall
  # would have no idea it must restore CLAUDE.md and settings.json from their backups.
  [ -f "$(lock_path)" ] && grep '^patch ' "$(lock_path)" >> "$(lock_path).new" 2>/dev/null
  return 0
}

lock_meta() {
  [ "${DRY_RUN:-0}" = "1" ] && return 0
  printf 'meta kit_version=%s profile=%s modules=%s\n' "$KIT_VERSION" "$PROFILE" "$MODULES" >> "$(lock_path).new"
}

lock_file()  { [ "${DRY_RUN:-0}" = "1" ] && return 0; printf 'file %s %s\n'  "$(sha_of "$TARGET/$1")" "$1" >> "$(lock_path).new"; }
lock_patch() { [ "${DRY_RUN:-0}" = "1" ] && return 0; grep -q "^patch $1\$" "$(lock_path).new" 2>/dev/null || printf 'patch %s\n' "$1" >> "$(lock_path).new"; }

lock_commit() {
  [ "${DRY_RUN:-0}" = "1" ] && return 0
  mv "$(lock_path).new" "$(lock_path)"
}

# Was <relpath> installed by a previous run, and is it still exactly as we left it?
lock_owns_unmodified() {
  local rel="$1" recorded
  [ -f "$(lock_path)" ] || return 1
  recorded="$(awk -v p="$rel" '$1=="file" && $3==p {print $2}' "$(lock_path)" | head -1)"
  [ -n "$recorded" ] || return 1
  [ "$recorded" = "$(sha_of "$TARGET/$rel")" ]
}

# Back a file up once per install run, before we modify it in place.
backup_once() {
  local abs="$1" rel bdir
  [ "${DRY_RUN:-0}" = "1" ] && return 0
  rel="${abs#"$TARGET"/}"
  bdir="$(backup_dir)"
  # Record the patch every time; the lock is rebuilt on each run. Back the file up only once, so a
  # re-install never overwrites the pristine original with our own earlier output.
  lock_patch "$rel"
  [ -f "$bdir/$rel" ] && return 0
  mkdir -p "$bdir/$(dirname "$rel")"
  cp "$abs" "$bdir/$rel"
}
