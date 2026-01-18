# Scholar Enhancement Tutorial Demo 3: Customize with Flags
# Shows adding and removing content with flags

Output docs/demos/tutorials/scholar-03-customize.gif

Set FontSize 16
Set Width 1200
Set Height 800
Set Theme "Catppuccin Mocha"
Set Padding 20

# Show adding diagrams
Type "teach slides \"ANOVA\" --style computational --diagrams"
Sleep 500ms
Enter
Sleep 2s

# Show removing content
Type "# Example: Remove practice problems"
Sleep 1s
Enter
Type "teach exam \"Regression\" --style rigorous --no-proof"
Sleep 500ms
Enter
Sleep 2s

# Show result
Type "# ✅ Content customized with flags"
Sleep 2s
