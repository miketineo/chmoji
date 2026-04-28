" chmoji picker dispatch.
"
" Detection chain (first match wins):
"   1. fzf-lua          (nvim, ibhagwan/fzf-lua)
"   2. snacks.nvim      (nvim, folke/snacks.nvim)
"   3. telescope.nvim   (nvim, nvim-telescope/telescope.nvim)
"   4. fzf.vim          (junegunn/fzf.vim, works in vim + nvim)
"   5. inputlist()      (Vim built-in, always available)
"
" g:chmoji_picker overrides detection. Set it to one of:
"   'fzf-lua' | 'snacks' | 'telescope' | 'fzf-vim' | 'inputlist'

scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

function! s:has_lua_module(name) abort
  if !has('nvim')
    return 0
  endif
  return luaeval('(pcall(require, _A)) == true', a:name)
endfunction

" Return the picker identifier we'll use, given current state.
function! chmoji#picker#detect() abort
  if !empty(g:chmoji_picker)
    return g:chmoji_picker
  endif
  if s:has_lua_module('fzf-lua')
    return 'fzf-lua'
  endif
  if s:has_lua_module('snacks.picker') || s:has_lua_module('snacks')
    return 'snacks'
  endif
  if s:has_lua_module('telescope')
    return 'telescope'
  endif
  if exists('*fzf#run')
    return 'fzf-vim'
  endif
  return 'inputlist'
endfunction

" Build the picker source: a list of "<glyph>\t:<name>:" lines, one per
" merged shortcode. g:chmoji_extra entries appear first so user-defined
" shortcodes float to the top of the picker.
function! s:source_lines() abort
  let l:items = []
  let l:seen = {}
  for [l:name, l:glyph] in items(g:chmoji_extra)
    call add(l:items, l:glyph . "\t:" . l:name . ':')
    let l:seen[l:name] = 1
  endfor
  for [l:name, l:glyph] in items(chmoji#data())
    if !has_key(l:seen, l:name)
      call add(l:items, l:glyph . "\t:" . l:name . ':')
    endif
  endfor
  return l:items
endfunction

" Splice {glyph} into the current line at the cursor. If the line ends in
" `:partial` (i.e. the user invoked the picker mid-word with `:partial`
" pending), strip that partial first so the glyph replaces it cleanly.
" After the splice the cursor sits immediately after the inserted glyph.
function! s:insert_glyph(glyph) abort
  if empty(a:glyph)
    return
  endif
  let l:line = getline('.')
  let l:col = col('.')
  let l:lbuf = strpart(l:line, 0, l:col - 1)
  let l:rbuf = strpart(l:line, l:col - 1)

  " Strip a trailing `:partial` from lbuf so the picker query is replaced
  " by the chosen glyph (matches chmoji-zsh's strip_len behavior).
  let l:m = matchlist(l:lbuf, '\v:([a-z0-9_+-]*)$')
  if !empty(l:m)
    let l:lbuf = strpart(l:lbuf, 0, len(l:lbuf) - len(l:m[0]))
  endif

  call setline('.', l:lbuf . a:glyph . l:rbuf)
  call cursor(line('.'), len(l:lbuf . a:glyph) + 1)
endfunction

" Extract a glyph from a "<glyph>\t:<name>:" picker selection.
function! s:glyph_from_selection(sel) abort
  if empty(a:sel)
    return ''
  endif
  let l:tab = stridx(a:sel, "\t")
  if l:tab < 0
    return a:sel
  endif
  return strpart(a:sel, 0, l:tab)
endfunction

" Public: open the picker. Optional {query} pre-fills the filter input.
" If the cursor is on a `:partial` token, that token is used as the query
" and gets stripped on commit.
function! chmoji#picker#open(...) abort
  let l:explicit_query = a:0 > 0 ? a:1 : ''
  let l:query = l:explicit_query
  if empty(l:query)
    let l:lbuf = strpart(getline('.'), 0, col('.') - 1)
    let l:m = matchlist(l:lbuf, '\v:([a-z0-9_+-]*)$')
    if !empty(l:m)
      let l:query = l:m[1]
    endif
  endif

  let l:picker = chmoji#picker#detect()
  let l:items = s:source_lines()

  if l:picker ==# 'fzf-lua'
    return s:open_fzf_lua(l:items, l:query)
  elseif l:picker ==# 'snacks'
    return s:open_snacks(l:items, l:query)
  elseif l:picker ==# 'telescope'
    return s:open_telescope(l:items, l:query)
  elseif l:picker ==# 'fzf-vim'
    return s:open_fzf_vim(l:items, l:query)
  else
    return s:open_inputlist(l:items, l:query)
  endif
endfunction

" Internal: dispatched picker openers. Each must call s:on_pick(selection)
" with the raw "<glyph>\t:<name>:" line (or '') when the user commits.

function! s:on_pick(sel) abort
  call s:insert_glyph(s:glyph_from_selection(a:sel))
endfunction

function! s:open_inputlist(items, query) abort
  " inputlist() is interactive; it hangs in headless nvim (--headless has no
  " TTY so there is no stdin to read from). Return silently in that case.
  if has('nvim') && !has('ttyin')
    return
  endif
  " Fallback: numeric prompt. Filter by query if provided.
  let l:filtered = a:items
  if !empty(a:query)
    let l:pat = '\V' . escape(a:query, '\')
    let l:filtered = filter(copy(a:items), 'v:val =~ l:pat')
  endif
  if empty(l:filtered)
    echohl WarningMsg | echomsg 'chmoji: no shortcodes match ' . string(a:query) | echohl None
    return
  endif
  " Truncate to a humane length — inputlist isn't great with thousands.
  let l:max = 40
  let l:show = l:filtered[: l:max - 1]
  let l:prompt = ['Pick an emoji' . (empty(a:query) ? '' : ' (filter: ' . a:query . ')') . ':']
  let l:i = 1
  for l:item in l:show
    call add(l:prompt, l:i . '. ' . l:item)
    let l:i += 1
  endfor
  if len(l:filtered) > l:max
    call add(l:prompt, '... (' . (len(l:filtered) - l:max) . ' more — narrow your filter)')
  endif
  let l:choice = inputlist(l:prompt)
  if l:choice >= 1 && l:choice <= len(l:show)
    call s:on_pick(l:show[l:choice - 1])
  endif
endfunction

function! s:open_fzf_vim(items, query) abort
  call fzf#run(fzf#wrap({
        \ 'source': a:items,
        \ 'sink': function('s:on_pick'),
        \ 'options': ['--prompt', 'emoji> ',
        \             '--query', a:query,
        \             '--delimiter', "\t",
        \             '--with-nth', '1,2',
        \             '--height', '40%',
        \             '--reverse'],
        \ }))
endfunction

" The Lua-backed pickers use a small inline lua bridge. We push the items
" and the on_pick vimscript callback name across the FFI boundary.
function! s:open_fzf_lua(items, query) abort
  if !has('nvim')
    return s:open_inputlist(a:items, a:query)
  endif
  call luaeval('require("chmoji_picker").fzf_lua(_A[1], _A[2])',
        \ [a:items, a:query])
endfunction

function! s:open_snacks(items, query) abort
  if !has('nvim')
    return s:open_inputlist(a:items, a:query)
  endif
  call luaeval('require("chmoji_picker").snacks(_A[1], _A[2])',
        \ [a:items, a:query])
endfunction

function! s:open_telescope(items, query) abort
  if !has('nvim')
    return s:open_inputlist(a:items, a:query)
  endif
  call luaeval('require("chmoji_picker").telescope(_A[1], _A[2])',
        \ [a:items, a:query])
endfunction

" Public commit entry point. Lua-backed pickers and the themis suite call
" this with the raw "<glyph>\t:<name>:" line on user selection.
function! chmoji#picker#commit(sel) abort
  call s:on_pick(a:sel)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
