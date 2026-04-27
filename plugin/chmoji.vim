" chmoji.vim — :shortcode: emoji expansion for Vim and Neovim.
" https://github.com/miketineo/chmoji
" License: MIT

if exists('g:loaded_chmoji')
  finish
endif
let g:loaded_chmoji = 1

scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

" ---- defaults --------------------------------------------------------------

if !exists('g:chmoji_enabled')
  let g:chmoji_enabled = 1
endif

if !exists('g:chmoji_extra')
  let g:chmoji_extra = {}
endif

if !exists('g:chmoji_auto_popup')
  let g:chmoji_auto_popup = 1
endif

if !exists('g:chmoji_picker')
  " '' means auto-detect; explicit values: 'fzf-lua', 'snacks', 'telescope',
  " 'fzf-vim', 'inputlist'.
  let g:chmoji_picker = ''
endif

if !exists('g:chmoji_picker_key')
  let g:chmoji_picker_key = '<C-x>e'
endif

if !exists('g:chmoji_disabled_filetypes')
  let g:chmoji_disabled_filetypes =
        \ ['TelescopePrompt', 'fzf', 'snacks_picker_input', 'cmp_menu',
        \  'help', 'qf', 'NvimTree', 'neo-tree']
endif

" ---- encoding guard --------------------------------------------------------
" The plugin emits multibyte UTF-8 glyphs into the buffer. Refuse to install
" if the user's encoding can't represent them — mirrors the zsh plugin's
" graceful-warn pattern.
if &encoding !=# 'utf-8'
  echohl WarningMsg
  echomsg 'chmoji: requires &encoding=utf-8 (current: ' . &encoding . '). Plugin disabled.'
  echohl None
  let &cpo = s:save_cpo
  unlet s:save_cpo
  finish
endif

" ---- mapping install -------------------------------------------------------

function! s:install_for_buffer() abort
  if !g:chmoji_enabled
    return
  endif
  if get(b:, 'chmoji_disabled', 0)
    return
  endif
  if index(g:chmoji_disabled_filetypes, &filetype) >= 0
    return
  endif

  " <expr> mapping on `:`. Returns either ':' or a backspace-and-glyph
  " sequence. Vim splices the returned text via the normal insert path,
  " yielding a single-step undo and clean composition with autopairs etc.
  inoremap <silent><expr><buffer> : chmoji#expand()

  " Picker hotkey. Configurable via g:chmoji_picker_key.
  " <Cmd> avoids mode transitions (nvim / vim ≥ 8.2.1978); fall back to
  " <C-o> on older Vim where only the synchronous inputlist is used anyway.
  if has('nvim') || has('patch-8.2.1978')
    execute 'inoremap <silent><buffer> ' . g:chmoji_picker_key
          \ . ' <Cmd>call chmoji#picker#open()<CR>'
  else
    execute 'inoremap <silent><buffer> ' . g:chmoji_picker_key
          \ . ' <C-o>:call chmoji#picker#open()<CR>'
  endif
endfunction

augroup chmoji_install
  autocmd!
  autocmd BufEnter,FileType * call s:install_for_buffer()
augroup END

" ---- :Chmoji ex-command ----------------------------------------------------

function! s:complete_chmoji(arglead, cmdline, cursorpos) abort
  return chmoji#complete(a:arglead)
endfunction

command! -nargs=? -complete=customlist,s:complete_chmoji Chmoji
      \ call chmoji#cmd(<q-args>)

let &cpo = s:save_cpo
unlet s:save_cpo
