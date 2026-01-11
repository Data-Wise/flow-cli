# VHS tape for DOT quick edit workflow
# Generate: vhs docs/demos/dot/01-quick-edit.tape
# Output: docs/demos/dot/01-quick-edit.gif

# Settings
Output docs/demos/dot/01-quick-edit.gif
Set Shell "zsh"
Set FontSize 14
Set Width 1200
Set Height 600
Set Padding 20
Set Theme "Molokai"

# Title
Type "# DOT Quick Edit Workflow"
Sleep 1s
Enter
Sleep 500ms

# Step 1: Edit a dotfile
Type "dot edit .zshrc"
Sleep 500ms
Enter
Sleep 1s

# Simulate editor opening
Type@50ms "# (Editor opens...)"
Sleep 1s
Type@50ms "# Add: export DEMO_VAR=v5.1.0"
Sleep 1s
Type@50ms "# Save and exit"
Sleep 1s

# Step 2: Show detection
Enter
Type@50ms "✓ Changes detected!"
Sleep 500ms
Enter
Type@50ms "───────────────────────────────────────────"
Sleep 300ms
Enter
Type@50ms "Modified: ~/.zshrc"
Sleep 300ms
Enter
Type@50ms "+export DEMO_VAR=v5.1.0"
Sleep 500ms
Enter
Type@50ms "───────────────────────────────────────────"
Sleep 500ms
Enter

# Step 3: Apply prompt
Type@50ms "Apply changes? [Y/n/d] "
Sleep 1s
Type "Y"
Sleep 300ms
Enter
Sleep 500ms
Type@50ms "✓ Applied changes to ~/.zshrc"
Sleep 2s

# Clear for loop
Ctrl+C
