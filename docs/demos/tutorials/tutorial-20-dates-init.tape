# Tutorial 20 Demo 1: teach dates init
# Shows the interactive wizard for initializing date configuration

Output docs/demos/tutorials/tutorial-20-dates-init.gif

Require flow-cli

Set FontSize 16
Set Width 1000
Set Height 600
Set Theme "Catppuccin Mocha"
Set TypingSpeed 50ms

# Setup: Navigate to example course directory
Type "cd /tmp/demo-course"
Enter
Sleep 1s

Type "# Initialize date configuration"
Enter
Sleep 500ms

Type "teach dates init"
Enter
Sleep 1.5s

# Wizard prompt
Type "2025-01-13"
Enter
Sleep 2s

# Show success message
Sleep 1s

Type "# Verify config was created"
Enter
Sleep 500ms

Type "cat .flow/teach-config.yml | head -20"
Enter
Sleep 3s

# Cleanup note
Type ""
Sleep 500ms
Type "# ✅ Date configuration initialized!"
Enter
Sleep 2s
