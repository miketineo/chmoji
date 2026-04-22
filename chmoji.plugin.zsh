# chmoji 0.1.0 | https://github.com/miketineo/chmoji
# `:shortcode:` emoji expansion and auto-popup picker for zsh, Slack style.
#
# Triggers:
#   1. Type `:` (after whitespace/BOL): fzf emoji picker auto-opens.
#      Keep typing to filter live (Slack style). ESC dismisses, leaving the
#      `:` in place. Disable this mode with CHMOJI_AUTO_POPUP=0.
#   2. Type `:name:`: if the picker isn't open and `name` is a known
#      emoji, replaces in place on the closing colon. Silent no-op if
#      unknown.
#   3. Press ^Xe (Ctrl-X then e): open the picker manually anytime,
#      pre-filtered to whatever comes after the last `:` on the line.
#
# Depends on oh-my-zsh `emoji` plugin (populates $emoji) and fzf.
# Must be sourced BEFORE zsh-syntax-highlighting (which must stay last).

if (( ! ${+emoji} )); then
  print -u2 "chmoji: \$emoji array not found. Enable oh-my-zsh's 'emoji' plugin or define \$emoji manually."
  return 0
fi
if (( ! $+commands[fzf] )); then
  print -u2 "chmoji: fzf not found. Install via 'brew install fzf' (or your package manager)."
  return 0
fi

typeset -gA _chmoji_extra
: ${CHMOJI_AUTO_POPUP:=1}

_chmoji_self_insert() {
  zle .self-insert
  [[ $KEYS == ':' ]] || return 0

  # Auto-popup: `:` at a trigger position (whitespace/BOL before it).
  if [[ $CHMOJI_AUTO_POPUP == 1 && $LBUFFER =~ '(^|[[:space:]]):$' ]]; then
    zle _chmoji_picker
    return 0
  fi

  # Close-colon expand: `:name:` resolves to glyph.
  [[ $LBUFFER =~ '(^|[[:space:]]):([a-z0-9_+-]+):$' ]] || return 0
  local name=$match[2]
  local glyph=${emoji[$name]:-${_chmoji_extra[$name]:-}}
  [[ -n $glyph ]] || return 0
  LBUFFER=${LBUFFER%:${name}:}$glyph
}
zle -N self-insert _chmoji_self_insert

_chmoji_picker() {
  local query='' strip_len=0
  if [[ $LBUFFER =~ ':([a-z0-9_+-]*)$' ]]; then
    query=$match[1]
    strip_len=$(( ${#query} + 1 ))
  fi
  local pick
  pick=$(
    for k in ${(ok)emoji}; do
      printf '%s\t:%s:\n' "$emoji[$k]" "$k"
    done | fzf --height=40% --reverse \
               --delimiter=$'\t' --with-nth=1,2 \
               --prompt='emoji> ' --query="$query"
  )
  if [[ -n $pick ]]; then
    local glyph=${pick%%$'\t'*}
    LBUFFER=${LBUFFER:0:$((${#LBUFFER} - strip_len))}$glyph
  fi
  zle reset-prompt
}
zle -N _chmoji_picker
bindkey '^Xe' _chmoji_picker
