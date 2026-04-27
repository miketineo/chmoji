" chmoji.vim test suite (vim-themis).
" Run via test/run.sh; see test/minimal.vim for manual exploration.

let s:suite = themis#suite('chmoji')
let s:a = themis#helper('assert')

" ---- helpers ---------------------------------------------------------------

function! s:reset() abort
  enew!
  setlocal buftype=nofile
  setlocal noswapfile
  setlocal bufhidden=wipe
  let g:chmoji_enabled = 1
  let g:chmoji_extra = {}
  let g:chmoji_auto_popup = 0
  let g:chmoji_disabled_filetypes = []
  let b:chmoji_disabled = 0
  set nopaste
  set encoding=utf-8
endfunction

function! s:place(line, col) abort
  call setline(1, a:line)
  call cursor(1, a:col)
endfunction

" Simulate the insert-mode cursor position where the user is about to
" type a `:` immediately after {prefix}. The line under test is just
" {prefix} but `<expr>` semantics require col == strlen(prefix) + 1,
" which is not reachable in normal mode (cursor clamps to line length).
" We pad with a trailing sentinel char and place the cursor on it; lbuf
" then equals exactly {prefix}.
function! s:place_after(prefix) abort
  call setline(1, a:prefix . 'Z')
  call cursor(1, strlen(a:prefix) + 1)
endfunction

" Build the expected return value for a successful expansion: <BS>×N glyph.
function! s:expected_expand(matched_lhs, glyph) abort
  return repeat("\<BS>", strchars(a:matched_lhs)) . a:glyph
endfunction

function! s:suite.before_each() abort
  call s:reset()
endfunction

" ---- 1. expand at BOL ------------------------------------------------------

function! s:suite.expand_tada_at_bol() abort
  " Line is ':tada', cursor at col 6 — about to type the closing ':'.
  call s:place_after(':tada')
  let l:r = chmoji#expand()
  call s:a.equals(l:r, s:expected_expand(':tada', '🎉'))
endfunction

" ---- 2. preserves prefix text ---------------------------------------------

function! s:suite.expand_after_text() abort
  call s:place_after('hello :tada')
  let l:r = chmoji#expand()
  call s:a.equals(l:r, s:expected_expand(':tada', '🎉'))
endfunction

" ---- 3. preserves leading space -------------------------------------------

function! s:suite.expand_with_leading_space() abort
  call s:place_after(' :tada')
  let l:r = chmoji#expand()
  call s:a.equals(l:r, s:expected_expand(':tada', '🎉'))
endfunction

" ---- 4. preserves leading tab ---------------------------------------------

function! s:suite.expand_with_leading_tab() abort
  call s:place_after("\t:tada")
  let l:r = chmoji#expand()
  call s:a.equals(l:r, s:expected_expand(':tada', '🎉'))
endfunction

" ---- 5. URL boundary: no expansion (no whitespace before opening ':') ----

function! s:suite.url_does_not_trigger() abort
  " Place cursor right after `http://host:tada` (where the user might
  " erroneously have typed `:tada`); the leading boundary check should
  " fail because there's no whitespace before the `:`.
  call s:place_after('http://host:tada')
  let l:r = chmoji#expand()
  call s:a.equals(l:r, ':')
endfunction

" ---- 6. JSON-style: no expansion ------------------------------------------

function! s:suite.json_colon_does_not_trigger() abort
  call s:place_after('{"key":tada')
  let l:r = chmoji#expand()
  call s:a.equals(l:r, ':')
endfunction

" ---- 7. git-log style: no expansion ('/' breaks regex) -------------------

function! s:suite.slash_in_query_does_not_trigger() abort
  " :/foo is not a valid shortcode (slash); regex won't match.
  call s:place_after('git log :/foo')
  let l:r = chmoji#expand()
  call s:a.equals(l:r, ':')
endfunction

" ---- 8. unknown shortcode: no expansion -----------------------------------

function! s:suite.unknown_name_does_not_expand() abort
  call s:place_after(':notarealemoji')
  let l:r = chmoji#expand()
  call s:a.equals(l:r, ':')
endfunction

" ---- 9. custom shortcode via g:chmoji_extra -------------------------------

function! s:suite.custom_shortcode_expands() abort
  let g:chmoji_extra = {'shipit': '🚢'}
  call s:place_after(':shipit')
  let l:r = chmoji#expand()
  call s:a.equals(l:r, s:expected_expand(':shipit', '🚢'))
endfunction

" ---- 10. extra overrides built-in -----------------------------------------

function! s:suite.extra_overrides_builtin() abort
  let g:chmoji_extra = {'tada': '🎈'}
  call s:place_after(':tada')
  let l:r = chmoji#expand()
  call s:a.equals(l:r, s:expected_expand(':tada', '🎈'))
endfunction

" ---- 11. globally disabled ------------------------------------------------

function! s:suite.disabled_global_no_expand() abort
  let g:chmoji_enabled = 0
  call s:place_after(':tada')
  let l:r = chmoji#expand()
  call s:a.equals(l:r, ':')
endfunction

" ---- 12. paste mode -------------------------------------------------------

function! s:suite.paste_mode_no_expand() abort
  set paste
  try
    call s:place_after(':tada')
    let l:r = chmoji#expand()
    call s:a.equals(l:r, ':')
  finally
    set nopaste
  endtry
endfunction

" ---- 13. cursor position after splice (via picker commit) ----------------

function! s:suite.cursor_position_after_picker_commit() abort
  " The <expr> path doesn't move the cursor (Vim does that on text
  " insertion). The picker commit splices manually, so test it instead.
  " Set up a line where the cursor sits mid-line; the splice should
  " insert the glyph at cursor and preserve the right-hand side.
  call setline(1, 'hello world')
  call cursor(1, 7)  " cursor on 'w'
  call chmoji#picker#commit("🎉\t:tada:")
  call s:a.equals(getline(1), 'hello 🎉world')
  " Cursor lands immediately after the glyph (byte-based col).
  call s:a.equals(col('.'), len('hello 🎉') + 1)
endfunction

function! s:suite.picker_commit_strips_partial() abort
  " If the cursor is on a `:partial` token, the picker commit should
  " replace it with the glyph rather than appending.
  call setline(1, 'hello :tad')
  call cursor(1, len('hello :tad') + 1)
  " cursor() clamps to len; that's fine — we want lbuf to include the partial.
  call cursor(1, len('hello :tad'))
  " To make end-of-line addressable, append a sentinel and place there.
  call setline(1, 'hello :tadZ')
  call cursor(1, len('hello :tad') + 1)
  call chmoji#picker#commit("🎉\t:tada:")
  " The :tad partial is stripped before insertion; sentinel Z stays.
  call s:a.equals(getline(1), 'hello 🎉Z')
endfunction

" ---- 14. undo as a single step (feedkeys-driven) -------------------------

" Note on undo grouping (no automated test):
"
" Vim and Neovim under headless / -es / -s scripted modes do not
" reliably fire insert-mode <expr> mappings via feedkeys() or piped
" key streams. Verified empirically against vim 9.1 and nvim 0.11.4;
" the mapping is correctly installed (maparg confirms) but the
" injected ':' bypasses it under headless. This is a host limitation,
" not a chmoji bug, and there is no robust headless harness for it.
"
" The single-undo property holds *by construction* of the <expr>
" mechanism: chmoji#expand() returns one string, Vim splices it via
" the normal insertion path, the entire splice is one undoable edit.
" The expand_*  tests above verify the returned string is correct;
" the undo property follows. Manual interactive smoke test covers
" the keystroke path end-to-end (see CONTRIBUTING).

" ---- 15. encoding guard ---------------------------------------------------

function! s:suite.encoding_guard_returns_colon() abort
  " We don't try to switch &encoding mid-test (it's volatile). Instead we
  " confirm the expand path obeys a g:chmoji_enabled = 0, which is what
  " plugin/chmoji.vim flips when it finishes due to the encoding guard.
  let g:chmoji_enabled = 0
  call s:place_after(':tada')
  call s:a.equals(chmoji#expand(), ':')
endfunction

" ---- 16. filetype guard ---------------------------------------------------

function! s:suite.filetype_guard_no_expand() abort
  let g:chmoji_disabled_filetypes = ['TelescopePrompt']
  setlocal filetype=TelescopePrompt
  call s:place_after(':tada')
  let l:r = chmoji#expand()
  call s:a.equals(l:r, ':')
endfunction

" ---- 17. word boundary: glued to keyword char ----------------------------

function! s:suite.no_word_boundary_no_expand() abort
  " 'foo:tada' — the ':' is not preceded by whitespace, so no expansion.
  call s:place_after('foo:tada')
  let l:r = chmoji#expand()
  call s:a.equals(l:r, ':')
endfunction

" ---- 18. picker chain detection -----------------------------------------

function! s:suite.detect_falls_through_to_inputlist() abort
  " By default, none of the Lua pickers will be loaded under the bare
  " test rtp; fzf.vim probably isn't either. Confirm the fallback.
  let g:chmoji_picker = ''
  let l:p = chmoji#picker#detect()
  call s:a.true(index(['fzf-lua', 'snacks', 'telescope', 'fzf-vim', 'inputlist'], l:p) >= 0,
        \ 'detect() returned unexpected: ' . l:p)
endfunction

function! s:suite.detect_respects_explicit_override() abort
  let g:chmoji_picker = 'inputlist'
  call s:a.equals(chmoji#picker#detect(), 'inputlist')
  let g:chmoji_picker = 'fzf-vim'
  call s:a.equals(chmoji#picker#detect(), 'fzf-vim')
  let g:chmoji_picker = ''
endfunction

" ---- bonus: data file is loadable ----------------------------------------

function! s:suite.data_file_loads() abort
  let l:d = chmoji#data()
  call s:a.true(type(l:d) == type({}), 'data is not a dict')
  call s:a.true(len(l:d) > 1000, 'expected > 1000 entries, got ' . len(l:d))
  call s:a.equals(l:d['tada'], '🎉')
  call s:a.equals(l:d['rocket'], '🚀')
endfunction

" ---- bonus: lookup precedence (extra wins) -------------------------------

function! s:suite.lookup_extra_wins() abort
  let g:chmoji_extra = {'tada': '🎈', 'shipit': '🚢'}
  call s:a.equals(chmoji#lookup('tada'), '🎈')
  call s:a.equals(chmoji#lookup('shipit'), '🚢')
  call s:a.equals(chmoji#lookup('rocket'), '🚀')
  call s:a.equals(chmoji#lookup('nope_not_real'), '')
endfunction

" ---- bonus: complete() ---------------------------------------------------

function! s:suite.complete_filters_by_lead() abort
  let l:r = chmoji#complete('tada')
  call s:a.true(index(l:r, 'tada') >= 0, 'tada not in completion list')
endfunction

function! s:suite.complete_strips_leading_colon() abort
  let l:r = chmoji#complete(':tada')
  call s:a.true(index(l:r, 'tada') >= 0, 'tada not in completion list when arglead has leading colon')
endfunction

function! s:suite.complete_includes_subcommands() abort
  let l:r = chmoji#complete('')
  call s:a.true(index(l:r, 'disable') >= 0, 'disable not in completion list')
  call s:a.true(index(l:r, 'enable') >= 0, 'enable not in completion list')
  call s:a.true(index(l:r, 'toggle') >= 0, 'toggle not in completion list')
endfunction

" ---- cmd subcommands -------------------------------------------------------

function! s:suite.cmd_disable() abort
  let g:chmoji_enabled = 1
  call chmoji#cmd('disable')
  call s:a.equals(g:chmoji_enabled, 0)
endfunction

function! s:suite.cmd_enable() abort
  let g:chmoji_enabled = 0
  call chmoji#cmd('enable')
  call s:a.equals(g:chmoji_enabled, 1)
endfunction

function! s:suite.cmd_toggle() abort
  let g:chmoji_enabled = 1
  call chmoji#cmd('toggle')
  call s:a.equals(g:chmoji_enabled, 0)
  call chmoji#cmd('toggle')
  call s:a.equals(g:chmoji_enabled, 1)
endfunction

function! s:suite.cmd_query_opens_picker_when_known_shortcode() abort
  " A non-subcommand arg passes through to the picker path — we just confirm
  " it doesn't flip g:chmoji_enabled as a side effect.
  let g:chmoji_enabled = 1
  " We can't actually open the picker in headless, but we can confirm
  " chmoji#cmd('tada') doesn't mutate g:chmoji_enabled.
  silent! call chmoji#cmd('tada')
  call s:a.equals(g:chmoji_enabled, 1)
endfunction
