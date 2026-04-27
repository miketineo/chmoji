" chmoji.vim core: <expr> callback + lookup + data load.
" See plugin/chmoji.vim for bootstrap and doc/chmoji.txt for usage.

scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

" Cached JSON dict; loaded on first lookup.
let s:data = v:null
let s:data_load_failed = 0

" Resolved at script load (top-level), so :h gives the autoload dir
" regardless of which function calls s:data_path() later.
let s:autoload_dir = fnamemodify(expand('<sfile>:p'), ':h')
let s:data_file = s:autoload_dir . '/chmoji/data.json'

function! s:data_path() abort
  return s:data_file
endfunction

" Lazy-load the bundled data dict. Returns {} on any failure (and caches
" the failure so we don't spam the user with errors on every keystroke).
function! chmoji#data() abort
  if !empty(s:data)
    return s:data
  endif
  if s:data_load_failed
    return {}
  endif
  let l:path = s:data_path()
  if !filereadable(l:path)
    let s:data_load_failed = 1
    echohl WarningMsg
    echomsg 'chmoji: data file missing at ' . l:path
    echohl None
    return {}
  endif
  try
    let s:data = json_decode(join(readfile(l:path), ''))
  catch
    let s:data_load_failed = 1
    echohl WarningMsg
    echomsg 'chmoji: failed to decode ' . l:path . ': ' . v:exception
    echohl None
    return {}
  endtry
  if type(s:data) != type({})
    let s:data_load_failed = 1
    let s:data = v:null
    return {}
  endif
  return s:data
endfunction

" Resolve a name to a glyph. g:chmoji_extra wins over the bundled data.
" Returns '' if unknown.
function! chmoji#lookup(name) abort
  if has_key(g:chmoji_extra, a:name)
    return g:chmoji_extra[a:name]
  endif
  let l:data = chmoji#data()
  return get(l:data, a:name, '')
endfunction

" The <expr> insert-mode mapping callback for `:`.
"
" When the user types `:` after `(^|\s):name`, replace `:name` with the
" glyph (the `:` we'd be inserting is not emitted because we return the
" replacement text instead).
"
" When the user types `:` at a word boundary with no preceding `:name`,
" optionally trigger the picker via timer_start (auto-popup mode).
"
" Otherwise return ':' to insert normally.
function! chmoji#expand() abort
  if !g:chmoji_enabled
    return ':'
  endif
  if &paste
    return ':'
  endif
  if get(b:, 'chmoji_disabled', 0)
    return ':'
  endif
  if index(g:chmoji_disabled_filetypes, &filetype) >= 0
    return ':'
  endif

  let l:line = getline('.')
  let l:col = col('.')
  " Bytes to the left of the cursor on the current line.
  let l:lbuf = strpart(l:line, 0, l:col - 1)

  " Close-colon expansion: lbuf ends with `(^|\s):name` and `name` is known.
  let l:m = matchlist(l:lbuf, '\v(^|\s):([a-z0-9_+-]+)$')
  if !empty(l:m)
    let l:name = l:m[2]
    let l:glyph = chmoji#lookup(l:name)
    if !empty(l:glyph)
      " Delete the `:name` we already inserted, emit the glyph in place
      " of the closing `:` we were about to insert. One <BS> per char.
      let l:bs = repeat("\<BS>", strchars(':' . l:name))
      return l:bs . l:glyph
    endif
  endif

  " Auto-popup: `:` typed at a word boundary, no abbreviation match.
  if g:chmoji_auto_popup && (l:col == 1 || l:lbuf =~# '\v\s$' || empty(l:lbuf))
    " Schedule the picker on the next tick so the `:` we're about to insert
    " is on screen first; the picker will strip it on commit.
    call timer_start(0, {-> chmoji#picker#open()})
  endif

  return ':'
endfunction

" Dispatch for :Chmoji [subcommand|query].
" Subcommands: enable, disable, toggle.  Anything else is a picker query.
function! chmoji#cmd(args) abort
  let l:arg = trim(a:args)
  if l:arg ==# 'disable'
    let g:chmoji_enabled = 0
    echomsg 'chmoji: disabled'
  elseif l:arg ==# 'enable'
    let g:chmoji_enabled = 1
    echomsg 'chmoji: enabled'
  elseif l:arg ==# 'toggle'
    let g:chmoji_enabled = !g:chmoji_enabled
    echomsg 'chmoji: ' . (g:chmoji_enabled ? 'enabled' : 'disabled')
  else
    call chmoji#picker#open(l:arg)
  endif
endfunction

let s:subcommands = ['disable', 'enable', 'toggle']

" Custom-list completion for :Chmoji <Tab>. Returns subcommands and shortcode
" names matching the arglead. Strips a leading `:` so `:Chmoji :tad<Tab>`
" and `:Chmoji tad<Tab>` both work.
function! chmoji#complete(arglead) abort
  let l:lead = a:arglead
  if l:lead =~# '^:'
    let l:lead = l:lead[1:]
  endif
  let l:names = s:subcommands + keys(g:chmoji_extra) + keys(chmoji#data())
  let l:names = sort(uniq(sort(l:names)))
  if empty(l:lead)
    return l:names
  endif
  return filter(l:names, 'v:val =~# "^" . l:lead')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
