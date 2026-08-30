#!/usr/bin/env bash
# Merge a marker-delimited block into a markdown file, never rewriting the rest of it.
#
#   block_merge <fragment> <dest>
#
# The fragment must contain <!-- sdlc-ai:begin NAME --> … <!-- sdlc-ai:end NAME -->.
# If the destination already has that block, it is replaced in place; otherwise the whole fragment is
# appended. Everything the user wrote is left exactly as it was.

block_merge() {
  local fragment="$1" dest="$2" name tmp
  name="$(grep -o 'sdlc-ai:begin [a-z-]*' "$fragment" | head -1 | awk '{print $2}')"
  [ -n "$name" ] || { err "$fragment has no sdlc-ai:begin marker"; return 1; }

  if [ ! -f "$dest" ]; then
    if [ "${DRY_RUN:-0}" = "1" ]; then plan "create $(relp "$dest") with block '$name'"; return 0; fi
    mkdir -p "$(dirname "$dest")"
    cat "$fragment" > "$dest"
    ok "created $(relp "$dest") with block '$name'"
    return 0
  fi

  tmp="$(mktemp)"
  if grep -q "sdlc-ai:begin $name" "$dest"; then
    # Replace between the markers, keeping the marker lines themselves.
    awk -v name="$name" -v frag="$fragment" '
      $0 ~ ("sdlc-ai:begin " name) { print; inblock=1
        while ((getline line < frag) > 0) { if (started) { if (line ~ ("sdlc-ai:end " name)) break; print line }
                                            if (line ~ ("sdlc-ai:begin " name)) started=1 }
        close(frag); next }
      $0 ~ ("sdlc-ai:end " name) { inblock=0; print; next }
      !inblock { print }
    ' "$dest" > "$tmp"
  else
    cat "$dest" > "$tmp"
    printf '\n' >> "$tmp"
    cat "$fragment" >> "$tmp"
  fi

  if cmp -s "$tmp" "$dest"; then rm -f "$tmp"; same "$(relp "$dest") (block '$name')"; return 0; fi

  if [ "${DRY_RUN:-0}" = "1" ]; then
    if grep -q "sdlc-ai:begin $name" "$dest"; then plan "update block '$name' in $(relp "$dest")"
    else plan "append block '$name' to $(relp "$dest") ($(wc -l < "$dest" | tr -d ' ') existing lines untouched)"; fi
    rm -f "$tmp"; return 0
  fi

  backup_once "$dest"
  mv "$tmp" "$dest"
  ok "block '$name' → $(relp "$dest")"
}
