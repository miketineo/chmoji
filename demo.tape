# demo.tape — regenerate with: vhs demo.tape
#
# Loads chmoji + oh-my-zsh's $emoji data + a clean prompt into a no-rc
# zsh, so the demo is reproducible without depending on the user's
# ~/.zshrc. Setup runs in a Hide block.

Output demo.gif

Set Shell "zsh"
Set FontSize 20
Set Width 1200
Set Height 600
Set Padding 20
Set TypingSpeed 75ms
Set Theme "Catppuccin Mocha"

Hide
Type `exec zsh -df`
Enter
Sleep 400ms
Type `setopt interactive_comments`
Enter
Type `PROMPT="%F{cyan}❯%f "`
Enter
Type `source ~/.oh-my-zsh/plugins/emoji/emoji.plugin.zsh`
Enter
Type `source ./chmoji.plugin.zsh`
Enter
Type `clear`
Enter
Sleep 400ms
Show

Sleep 800ms

# 1. Auto-popup on colon
Type "# auto-popup: picker opens the instant you type a colon"
Enter
Sleep 400ms
Type "echo "
Sleep 300ms
Type ":"
Sleep 1200ms
Type "tad"
Sleep 1500ms
Enter
Sleep 600ms
Enter
Sleep 1200ms

# 2. Silent close-colon expansion (flip auto-popup off)
Hide
Type "CHMOJI_AUTO_POPUP=0"
Enter
Type "clear"
Enter
Show
Sleep 500ms
Type "# silent :name: expansion on the closing colon (no popup)"
Enter
Sleep 400ms
Type "echo :rocket:"
Sleep 1500ms
Enter
Sleep 1500ms

# 3. Manual picker via Ctrl-X e (works regardless of auto-popup setting)
Type "# Ctrl-X e summons the picker anywhere on the line"
Enter
Sleep 400ms
Type "echo "
Sleep 300ms
Ctrl+X
Type "e"
Sleep 1s
Type "fire"
Sleep 1500ms
Enter
Sleep 600ms
Enter
Sleep 2s
