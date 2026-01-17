# Tutorial 20 Demo 3: teach dates sync (interactive)
# Shows interactive file-by-file sync with user prompts

Output docs/demos/tutorials/tutorial-20-dates-sync-interactive.gif

Require flow-cli

Set FontSize 16
Set Width 1200
Set Height 700
Set Theme "Catppuccin Mocha"
Set TypingSpeed 50ms

# Setup
Type "cd /tmp/demo-course"
Enter
Sleep 1s

Type "# Apply changes interactively"
Enter
Sleep 500ms

Type "teach dates sync"
Enter
Sleep 2s

# Show scanning
Sleep 1.5s

# Show first file prompt
Sleep 2s

# User chooses 'y' (yes)
Type "y"
Enter
Sleep 1.5s

# Show second file prompt
Sleep 1.5s

# User chooses 'd' (diff)
Type "d"
Enter
Sleep 2s

# Show diff output
Sleep 2.5s

# Prompt again after showing diff
Sleep 1s

# User chooses 'y' (yes)
Type "y"
Enter
Sleep 1.5s

# Show final success message
Sleep 2s

Type ""
Sleep 500ms
Type "# ✅ Date sync complete!"
Enter
Sleep 2s
