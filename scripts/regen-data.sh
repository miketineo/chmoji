#!/usr/bin/env bash
# Regenerate autoload/chmoji/data.json from oh-my-zsh's $emoji array.
#
# Reads $emoji via an interactive zsh subshell (so the user's normal
# oh-my-zsh setup populates it), pipes name<TAB>glyph lines through jq
# into a sorted JSON object. Run from repo root or anywhere; output path
# is computed relative to this script.
#
# Requires: zsh with oh-my-zsh's `emoji` plugin loaded, jq.

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
out="$repo_root/autoload/chmoji/data.json"

if ! command -v jq >/dev/null 2>&1; then
  echo "regen-data.sh: jq not found. Install via 'brew install jq'." >&2
  exit 1
fi

if ! command -v zsh >/dev/null 2>&1; then
  echo "regen-data.sh: zsh not found." >&2
  exit 1
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

# Dump name<TAB>glyph for every entry in $emoji. -ic ensures the user's
# zshrc loads oh-my-zsh which populates $emoji. Errors from unrelated
# plugins (e.g. our own chmoji which can't enable ZLE in non-interactive
# context) are dropped on stderr.
zsh -ic 'if (( ! ${+emoji} )); then
           print -u2 "regen-data.sh: \$emoji not populated. Enable oh-my-zsh emoji plugin."
           exit 2
         fi
         for k in ${(ok)emoji}; do printf "%s\t%s\n" "$k" "${emoji[$k]}"; done' 2>/dev/null > "$tmp"

count="$(wc -l < "$tmp" | tr -d ' ')"
if [[ "$count" -lt 1000 ]]; then
  echo "regen-data.sh: only $count entries from \$emoji — bailing (expected ~4200)." >&2
  exit 3
fi

# Convert TSV -> sorted JSON object. `-R` reads each line as a JSON string,
# `-s` slurps into an array. `from_entries` turns [{key,value},...] into {k:v,...}.
jq -Rs '
  split("\n")
  | map(select(. != "") | split("\t") | {key: .[0], value: .[1]})
  | sort_by(.key)
  | from_entries
' "$tmp" > "$out"

final_count="$(jq 'length' "$out")"
echo "regen-data.sh: wrote $final_count shortcodes to $out"
