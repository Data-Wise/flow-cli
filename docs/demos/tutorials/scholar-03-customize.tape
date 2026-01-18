# Scholar Enhancement Tutorial Demo 3: Customize with Flags
# Shows adding and removing content with flags

Output scholar-03-customize.gif

Set FontSize 14
Set Width 1000
Set Height 600
Set Theme "Catppuccin Mocha"
Set Padding 20
Set TypingSpeed 40ms

# Example 1: Add diagrams
Type "teach slides \"ANOVA\" --style computational --diagrams"
Sleep 500ms
Enter
Sleep 1s
Type@500ms "✅ Content: explanation, examples, code, practice, diagrams"
Enter
Sleep 2s

# Show prompt again
Type ""
Enter
Type "$ "
Sleep 500ms

# Example 2: Remove proofs
Type "teach exam \"Regression\" --style rigorous --no-proof"
Sleep 500ms
Enter
Sleep 1s
Type@500ms "✅ Content: definitions, explanation, math (no proof)"
Enter
Sleep 2s
