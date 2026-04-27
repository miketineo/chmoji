# chmoji

> `chmod` meets emoji. `:shortcode:` emoji for your zsh prompt, Vim, and Neovim — without the noise.

[![ci](https://github.com/miketineo/chmoji/actions/workflows/ci.yml/badge.svg)](https://github.com/miketineo/chmoji/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)
[![Shell: zsh](https://img.shields.io/badge/shell-zsh-4A90E2.svg)](https://www.zsh.org/)
[![Editor: Vim/Neovim](https://img.shields.io/badge/editor-vim%20%2F%20neovim-019733.svg)](https://www.vim.org/)

## Hi, I'm Claude 👋

[@miketineo](https://github.com/miketineo) pinged me one evening wanting Ghostty and tmux to be nicer to each other. Three requests in, almost as an afterthought, he added: *"also, I want `:tada:` shortcodes to work at the terminal. Could be a cool tmux plugin."*

It's not a tmux plugin (tmux doesn't see keystrokes on the command line; zsh does), but yes, it is cool. So we built it — first for the prompt, then for Vim and Neovim once @miketineo missed `:tada:` inside his editor too. @miketineo brought the idea, the taste, and the dogfooding. I wrote the zsh widget, the Vim plugin, the regex, the picker glue, and this README. If anything breaks, that's on me. If it feels right while you type, that's him.

## Demo

<p align="center">
  <img src="./demo.gif" alt="chmoji demo: auto-popup picker, silent :name: expansion, and the ^Xe hotkey" width="820">
</p>

```
$ echo :                       ← picker opens the instant you type `:`
  emoji>
  🎉  :tada:
  🚀  :rocket:
  ✨  :sparkles:
  ⋮

$ echo :tad                    ← keep typing, fzf filters live
  emoji> tad
  🎉  :tada:
  🤩  :star_struck:

$ echo 🎉                       ← Enter inserts the glyph; the leading `:` is stripped
```

Prefer zero UI? Set `CHMOJI_AUTO_POPUP=0` and type the whole shortcode:

```
$ echo :tada:                  ← expands on the closing `:`
$ echo 🎉
```

## What it does

I add two behaviors, in zsh and in Vim/Neovim, with the same data file and the same word-boundary semantics:

1. **Close colon expansion.** Type `:tada:` and it becomes 🎉 on the closing `:`. No UI, no flicker.
2. **Picker.** Open fzf (or your editor's fuzzy picker) over the full emoji catalog. Keep typing to filter. Enter inserts, ESC dismisses.

In both zsh and the editor the picker auto-opens the instant you type `:` at a word boundary (`CHMOJI_AUTO_POPUP=1` / `g:chmoji_auto_popup=1`, on by default). Use `<C-x>e` or `:Chmoji` to open it manually, and `:Chmoji disable` to turn auto-popup off for the session.

Both ecosystems share `oh-my-zsh`'s ~4200-shortcode `$emoji` table as the data source and reuse the same word-boundary regex, so a shortcode that triggers on the prompt also triggers in your editor.

## Why this exists

Most zsh emoji plugins land in one of two shapes:

1. **Data only**, like oh-my-zsh's `emoji` plugin. Populates `$emoji[tada]` but gives you no interactive way to reach for it.
2. **Hotkey picker**, like [b4b4r07/emoji-cli](https://github.com/b4b4r07/emoji-cli). Bind a key, press it, fzf opens. Great, but you have to remember the key, and it doesn't react to `:`.

chmoji sits between the two. Type `:` the way you already do when writing `:tada:` in GitHub, Discord, or any markdown editor, and you get the same behavior at your prompt. No hotkey to memorise. Combined with silent `:name:` expansion, it's the shortest distance between your muscle memory and a 🎉.

## Install

### Homebrew (macOS / Linux)

```zsh
brew install miketineo/tap/chmoji
```

Then add the source line to your `~/.zshrc`, after oh-my-zsh's `emoji` plugin and before `zsh-syntax-highlighting` if you use it:

```zsh
source "$(brew --prefix chmoji)/share/chmoji/chmoji.plugin.zsh"
```

### oh-my-zsh (custom plugin)

```zsh
git clone https://github.com/miketineo/chmoji ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/chmoji
```

Add `chmoji` to your `plugins=(...)` in `~/.zshrc`. Make sure `emoji` is also listed. If you use `zsh-syntax-highlighting`, keep it **last** as always:

```zsh
plugins=(emoji fzf chmoji zsh-syntax-highlighting)
```

### zinit

```zsh
zinit load miketineo/chmoji
```

Load oh-my-zsh's `emoji` plugin (or define `$emoji` yourself) and `fzf` first.

### antidote

```zsh
# ~/.zsh_plugins.txt
ohmyzsh/ohmyzsh path:plugins/emoji
junegunn/fzf
miketineo/chmoji
zsh-users/zsh-syntax-highlighting   # must be last
```

### Manual

```zsh
git clone https://github.com/miketineo/chmoji ~/.zsh/plugins/chmoji
# add this to ~/.zshrc, BEFORE zsh-syntax-highlighting:
source ~/.zsh/plugins/chmoji/chmoji.plugin.zsh
```

## Vim & Neovim

The same repo also ships as a Vim/Neovim plugin. It uses an `<expr>` mapping on `:` (not `iabbrev` — see [Why not `iabbrev`?](#why-not-iabbrev)) and the same `:name:` data file as the zsh side, so behavior matches.

### Install

**[vim-plug](https://github.com/junegunn/vim-plug):**

```vim
Plug 'miketineo/chmoji'
```

**[packer.nvim](https://github.com/wbthomason/packer.nvim):**

```lua
use 'miketineo/chmoji'
```

**[lazy.nvim](https://github.com/folke/lazy.nvim):**

```lua
{ 'miketineo/chmoji' }
```

**Vim 8 native packages:**

```sh
git clone https://github.com/miketineo/chmoji ~/.vim/pack/miketineo/start/chmoji
vim -u NONE -c "helptags ~/.vim/pack/miketineo/start/chmoji/doc | quit"
```

**Neovim native (`runtimepath`):**

```sh
git clone https://github.com/miketineo/chmoji ~/.local/share/nvim/site/pack/miketineo/start/chmoji
```

**Manual:**

```sh
git clone https://github.com/miketineo/chmoji ~/.vim/plugged/chmoji
# add to your vimrc/init.vim:
set runtimepath+=~/.vim/plugged/chmoji
```

**Already have it via `brew install miketineo/tap/chmoji`?** Add the runtime path to your editor config:

```vim
set runtimepath+=$(brew --prefix chmoji)/share/chmoji-vim
silent! helptags ALL
```

### Usage

In insert mode:

| Action | Behavior |
|---|---|
| Type `:tada:` after whitespace or BOL | Silent expansion to 🎉 on the closing `:`. |
| Type `<C-x>e` | Open the picker. If on a `:partial`, that partial pre-fills the query. |
| `:Chmoji [query]` (normal mode) | Open the picker; insert the chosen glyph at cursor. Tab-completes shortcode names. |
| `:Chmoji disable` / `enable` / `toggle` | Turn chmoji off/on/flip without touching your config. |

The picker auto-detects the available backend in this order: `fzf-lua` → `snacks.nvim` → `telescope.nvim` → `fzf.vim` → `inputlist()` (built-in fallback). Force a specific one with `let g:chmoji_picker = 'fzf-vim'` etc.

### Configuration

```vim
let g:chmoji_extra = {'shipit': '🚢', 'lgtm': '👍'}    " custom shortcodes
let g:chmoji_enabled = 1                              " master switch
let g:chmoji_auto_popup = 1                           " open picker on bare `:` (on by default — set 0 to disable)
let g:chmoji_picker_key = '<C-x>e'                    " rebind picker hotkey
let g:chmoji_disabled_filetypes = ['fzf', 'TelescopePrompt', 'cmp_menu']
let b:chmoji_disabled = 1                             " buffer-local opt-out
```

Full reference: `:help chmoji`.

### Why not `iabbrev`?

The obvious recipe — `iabbrev :tada: 🎉` for every shortcode — does not work, and chmoji ships a real plugin for two empirically-verified reasons:

- Vim's `iabbrev` LHS is hard-capped at 50 bytes (`MAXMAPLEN`); ~280 of the 4200 oh-my-zsh shortcodes exceed it.
- "non-id" abbreviations (LHS that ends in non-keyword char like `:tada:`) only trigger on `<Esc>`/`<CR>`/`<C-]>`. Space, period, comma do **not** fire them — so `:tada: <space>` produces literal `:tada: `, not 🎉.

The chmoji plugin uses a buffer-local insert-mode `<expr>` mapping on `:` instead, which composes cleanly with autopairs/snippets/completion popups, produces a single undo step, and works in every typing context.

## Usage

| Action | Behavior |
|---|---|
| Type `:` after whitespace or BOL | fzf picker auto opens. Keep typing to filter live. |
| Enter inside picker | Inserts the selected glyph. Strips the leading `:` and any partial query you typed. |
| ESC inside picker | Dismisses. The `:` and whatever you typed remain as literal text. |
| Type `:name:` (picker off or after ESC) | Silent in place expansion if `name` is known. No op if not. |
| `^Xe` (Ctrl-X then e) | Opens the picker manually from anywhere on the line. Pre filters to whatever follows the last `:`. |
| `^_` / `^/` after an expansion | Undoes it as a single step (stock zsh undo). |

### Quiet mode

Set `CHMOJI_AUTO_POPUP=0` before sourcing chmoji to disable the auto popup. Silent `:name:` expansion and the `^Xe` hotkey still work:

```zsh
export CHMOJI_AUTO_POPUP=0
# ... plugin load ...
```

### Custom shortcodes

Add mappings that take precedence over oh-my-zsh's `$emoji` for the same name:

```zsh
_chmoji_extra[shipit]='🚢'
_chmoji_extra[lgtm]='👍'
```

### Change the picker hotkey

```zsh
bindkey -r '^Xe'
bindkey '^[e' _chmoji_picker   # Alt+e, or whatever you prefer
```

## Requirements

- **zsh** (tested on 5.9+)
- **[oh-my-zsh's `emoji` plugin](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/emoji)** for the `$emoji` associative array (~4200 GitHub style shortcodes). chmoji reuses this rather than shipping its own list.
- **[fzf](https://github.com/junegunn/fzf)** to power the picker.

If either is missing, chmoji prints a one line warning to stderr on load and gracefully does nothing. No silent breakage.

## How it works

### zsh half

chmoji is about 60 lines of zsh doing exactly three things:

1. I wrap the ZLE `self-insert` widget so I can see every keystroke. When that keystroke is `:` at a whitespace anchored position, I either launch the picker (auto popup mode) or check whether the buffer just completed a known `:name:` pattern and swap it for the glyph.
2. The picker streams `$emoji` entries into fzf over a tab delimited `glyph\t:name:` format. fzf does the matching. I read the selection and splice it back into the buffer.
3. I bind `^Xe` to the picker so you can always open it on demand.

### Vim/Neovim half

The editor plugin is about 200 lines of vimscript with a small Lua bridge for nvim-native pickers. It does the same three things:

1. A buffer-local `inoremap <silent><expr> :` calls `chmoji#expand()` on every typed `:`. The function reads the line buffer to the left of the cursor, matches the same `(^|\s):name$` regex, and returns either `:` (literal) or a `<BS>×N + glyph` string that Vim splices via the normal insertion path. Single-step undo, composes with autopairs/snippets/completion popups.
2. The picker auto-detects an available backend (fzf-lua → snacks → telescope → fzf.vim → `inputlist()`) and on commit splices the chosen glyph at cursor, stripping any pending `:partial`.
3. `<C-x>e` and `:Chmoji [query]` open the picker manually.

Both halves share `autoload/chmoji/data.json` (generated from oh-my-zsh's `$emoji`) so a shortcode that resolves on the prompt also resolves in the editor.

The whitespace anchor is what keeps this usable. `http://host:8080/`, `git log :/foo`, `{"key":"value"}`: none of them trigger anything, because the `:` isn't preceded by whitespace.

## Limitations

The zsh half is a ZLE widget — it intercepts keystrokes at zsh's prompt and nowhere else. So chmoji-zsh works at your shell prompt, but **not** inside:

- TUI apps that draw their own input box: tmux's command line, htop search, Claude Code's input.
- Browser textareas, GUI apps.
- Other shells (bash, fish — though chmoji is zsh-only by design).

For Vim and Neovim, [chmoji.vim](#vim--neovim) covers that gap. For everything else, you're at the mercy of each app's own abbreviation/snippet mechanism.

## Prior art and credits

chmoji is glue. It stands on other people's work:

- **[oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh)** and its `emoji` plugin. The `$emoji` associative array is my data source. Thank you to everyone who has maintained that list.
- **[fzf](https://github.com/junegunn/fzf)**. The picker you see is fzf. I just pipe emoji into it.
- **[b4b4r07/emoji-cli](https://github.com/b4b4r07/emoji-cli)**. Prior art for "fzf plus emoji, triggered by a hotkey." Different design from mine, but the seed came from there.

If any of these projects change their API or move, chmoji's dep guards print a clear message and stop loading. No silent failure.

## Star history

<a href="https://star-history.com/#miketineo/chmoji&Date">
  <img src="https://api.star-history.com/svg?repos=miketineo/chmoji&type=Date" alt="Star history chart" width="640">
</a>

If chmoji made your prompt a little more fun, a star helps other people find it.

## License

MIT. See [LICENSE](./LICENSE).

## Contributing

@miketineo maintains this repo. Issues and PRs welcome. Things I'd merge with enthusiasm:

- A vendored fallback emoji list so chmoji works without oh-my-zsh loaded.
- Install snippets for plugin managers not listed above (zsh or Vim/Neovim).
- Keybinding presets for common layouts (Alt+e for macOS friendly, Ctrl+K for emacs leaning, etc).
- Polish on the Lua picker bridges (`lua/chmoji_picker.lua`) — fzf-lua, snacks, telescope APIs evolve and the wrappers need to age gracefully.
- vim9script port of `autoload/chmoji.vim` if benchmarks ever justify it.

Tests run via [vim-themis](https://github.com/thinca/vim-themis), bundled as a submodule under `test/vendor/themis`. Run `./test/run.sh` (auto-detects nvim or `/usr/bin/vim`); pass `--all` to run against both. Add cases to `test/chmoji_test.vim` and they run on every push.

Keep each half tight. The zsh widget is bounded at ~100 lines; the Vim plugin's main file at ~200. If a change pushes either past those, it probably doesn't belong here.

## Why "chmoji"?

Portmanteau of `chmod` plus emoji. Your shell already lets you `chmod +x script.sh`. chmoji lets you `chmod +feelings prompt`. @miketineo picked it from a list of 20 candidates I brainstormed. Pronounced "ch moh jee" (like "chummy" with a "gee" on the end).

## Credits

- **Idea, taste, maintainer**: [@miketineo](https://github.com/miketineo)
- **Implementation**: Claude (Anthropic), pair programming with @miketineo
