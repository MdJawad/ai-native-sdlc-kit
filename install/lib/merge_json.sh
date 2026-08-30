#!/usr/bin/env bash
# Deep-merge a JSON fragment into a destination file.
#
#   json_merge <fragment> <dest>
#
# Objects merge recursively. Arrays union by value, so re-running never duplicates a hook entry and a
# hand-added entry is never dropped. Requires jq.

json_merge() {
  local fragment="$1" dest="$2" tmp
  command -v jq >/dev/null 2>&1 || { err "jq is required to merge $dest"; return 1; }

  if [ ! -f "$dest" ]; then
    if [ "${DRY_RUN:-0}" = "1" ]; then plan "create $(relp "$dest") (from $(basename "$fragment"))"; return 0; fi
    mkdir -p "$(dirname "$dest")"
    jq '.' "$fragment" > "$dest" || return 1
    ok "created $(relp "$dest")"
    return 0
  fi

  jq empty "$dest" 2>/dev/null || { err "$(relp "$dest") is not valid JSON — fix it, then re-run"; return 1; }

  tmp="$(mktemp)"
  # Recursive object merge. $a/$b are VALUE parameters — a plain `a`/`b` would be re-evaluated
  # against the reduce accumulator and index the wrong thing. Arrays are concatenated and
  # de-duplicated preserving first-seen order, so re-running never duplicates a hook entry and never
  # reorders one the user added.
  jq -s '
    def dedup: reduce .[] as $x ([]; if any(.[]; . == $x) then . else . + [$x] end);
    def deepmerge($a; $b):
      reduce ($b | keys_unsorted[]) as $k
        ($a;
         if ($a[$k] | type) == "object" and ($b[$k] | type) == "object"
           then .[$k] = deepmerge($a[$k]; $b[$k])
         elif ($a[$k] | type) == "array" and ($b[$k] | type) == "array"
           then .[$k] = (($a[$k] + $b[$k]) | dedup)
         else .[$k] = $b[$k] end);
    deepmerge(.[0]; .[1])
  ' "$dest" "$fragment" > "$tmp" || { rm -f "$tmp"; err "could not merge $(basename "$fragment") into $(relp "$dest")"; return 1; }

  if cmp -s "$tmp" "$dest"; then rm -f "$tmp"; same "$(relp "$dest")"; return 0; fi

  if [ "${DRY_RUN:-0}" = "1" ]; then
    plan "merge $(basename "$fragment") into $(relp "$dest")"
    printf '%s' "$C_DIM"; diff -u "$dest" "$tmp" | sed -n '4,20p' | sed 's/^/      /'; printf '%s' "$C_OFF"
    rm -f "$tmp"; return 0
  fi

  backup_once "$dest"
  mv "$tmp" "$dest"
  ok "merged $(basename "$fragment") into $(relp "$dest")"
}
