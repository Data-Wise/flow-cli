# VHS tape for dot dispatcher demo
# Generate GIF: vhs dot-dispatcher.tape
# Output: dot-dispatcher.gif

# Settings
Output dot-dispatcher.gif
Set Shell "zsh"
Set FontSize 18
Set Width 1200
Set Height 600
Set Padding 20
Set Theme "Monokai"

# Title card
Type "# Dot Dispatcher Demo - Dotfile Management"
Sleep 2s
Enter
Sleep 500ms

# Scene 1: Check status
Type "# Check dotfile status"
Sleep 500ms
Enter
Type "dot"
Sleep 500ms
Enter
Sleep 2s

# Scene 2: Edit a dotfile
Type@100ms "# Edit a dotfile (with preview)"
Sleep 500ms
Enter
Type "dot edit .zshrc"
Sleep 500ms
Enter
Sleep 1s
Type@50ms "# (Editor opens, make a change, save)"
Sleep 2s
Type@50ms "# Preview shows: Modified: ~/.zshrc"
Sleep 1s
Type@50ms "# Apply? [Y/n/d] → y"
Sleep 2s

# Scene 3: Unlock Bitwarden
Ctrl+C
Enter
Type@100ms "# Unlock Bitwarden vault"
Sleep 500ms
Enter
Type "dot unlock"
Sleep 500ms
Enter
Sleep 1s
Type@50ms "# (Enter master password)"
Sleep 1s
Type@50ms "# ✓ Vault unlocked successfully"
Sleep 2s

# Scene 4: List secrets
Type@100ms "# List available secrets"
Sleep 500ms
Enter
Type "dot secret list"
Sleep 500ms
Enter
Sleep 2s

# Scene 5: Retrieve secret
Type@100ms "# Retrieve a secret (no echo)"
Sleep 500ms
Enter
Type "TOKEN=$(dot secret github-token)"
Sleep 500ms
Enter
Sleep 1s
Type "echo \"Token retrieved: ${TOKEN:0:10}...\""
Sleep 500ms
Enter
Sleep 2s

# Scene 6: Sync from remote
Type@100ms "# Sync from remote repository"
Sleep 500ms
Enter
Type "dot sync"
Sleep 500ms
Enter
Sleep 2s

# Scene 7: Show help
Type@100ms "# Get help anytime"
Sleep 500ms
Enter
Type "dot help"
Sleep 500ms
Enter
Sleep 3s

# Final card
Ctrl+C
Enter
Sleep 500ms
Type "# Dotfile management made easy!"
Sleep 2s
