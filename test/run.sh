#!/usr/bin/env bash
# Run the chmoji.vim test suite via vim-themis against $VIM_BIN
# (or, if unset: nvim if available, else /usr/bin/vim).
#
# Examples:
#   ./test/run.sh                          # auto-pick host
#   VIM_BIN=/usr/bin/vim ./test/run.sh     # force classic vim
#   VIM_BIN=nvim ./test/run.sh             # force neovim
#   ./test/run.sh --all                    # run against nvim + /usr/bin/vim

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"

themis_home="$repo_root/test/vendor/themis"
if [[ ! -x "$themis_home/bin/themis" ]]; then
  echo "run.sh: vim-themis missing at $themis_home. Run: git submodule update --init --recursive" >&2
  exit 1
fi

run_one() {
  local bin="$1"
  if [[ -z "$bin" ]]; then
    return 0
  fi
  echo "==> chmoji tests: $bin"
  THEMIS_HOME="$themis_home" \
    THEMIS_VIM="$bin" \
    THEMIS_PROFILE='default' \
    "$themis_home/bin/themis" --runtimepath "$repo_root" "$script_dir"
}

if [[ "${1:-}" == "--all" ]]; then
  rc=0
  if command -v nvim >/dev/null 2>&1; then
    run_one "$(command -v nvim)" || rc=$?
  fi
  if [[ -x /usr/bin/vim ]]; then
    run_one /usr/bin/vim || rc=$?
  fi
  exit "$rc"
fi

if [[ -n "${VIM_BIN:-}" ]]; then
  run_one "$VIM_BIN"
elif command -v nvim >/dev/null 2>&1; then
  run_one "$(command -v nvim)"
elif [[ -x /usr/bin/vim ]]; then
  run_one /usr/bin/vim
else
  echo "run.sh: no nvim or /usr/bin/vim found. Set VIM_BIN explicitly." >&2
  exit 1
fi
