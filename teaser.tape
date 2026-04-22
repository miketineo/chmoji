# teaser.tape — regenerate with: vhs teaser.tape
#
# Short hero GIF: shows the silent `:tada:` → 🎉 expansion only.
# Sits at the top of the README above the fuller demo.gif.

Output teaser.gif

Set Shell "zsh"
Set FontSize 24
Set Width 1200
Set Height 280
Set Padding 24
Set TypingSpeed 90ms
Set Theme "Catppuccin Mocha"

Hide
Type `exec zsh -df`
Enter
Sleep 300ms
Type `setopt interactive_comments`
Enter
Type `PROMPT="%F{cyan}❯%f "`
Enter
Type `source ~/.oh-my-zsh/plugins/emoji/emoji.plugin.zsh`
Enter
Type `source ./chmoji.plugin.zsh`
Enter
Type `CHMOJI_AUTO_POPUP=0`
Enter
Type `clear`
Enter
Sleep 400ms
Show

Sleep 700ms
Type "echo :tada:"
Sleep 700ms
Enter
Sleep 1800ms
