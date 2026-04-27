" Minimal runtime config for manual smoke testing chmoji.vim.
"
" Usage:
"   nvim -u test/minimal.vim
"   vim  -u test/minimal.vim
"
" Loads the plugin from the repo it lives in (no install required) with
" no other plugins on the runtimepath.

set nocompatible
let s:repo = expand('<sfile>:p:h:h')
let &runtimepath = s:repo . ',' . &runtimepath

filetype plugin indent on
syntax enable
set encoding=utf-8

runtime! plugin/chmoji.vim
silent! helptags ALL
