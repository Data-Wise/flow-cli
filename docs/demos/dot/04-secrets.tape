# VHS tape for DOT secret management
# Generate: vhs docs/demos/dot/04-secrets.tape
# Output: docs/demos/dot/04-secrets.gif

# Settings
Output docs/demos/dot/04-secrets.gif
Set Shell "zsh"
Set FontSize 14
Set Width 1200
Set Height 600
Set Padding 20
Set Theme "Molokai"

# Title
Type "# DOT Secret Management"
Sleep 1s
Enter
Sleep 500ms

# Step 1: Unlock vault
Type "# Unlock Bitwarden vault"
Sleep 500ms
Enter
Type "dot unlock"
Sleep 500ms
Enter
Sleep 1s
Type@50ms "ℹ Enter your Bitwarden master password:"
Sleep 1s
Enter
Type@50ms "[password hidden]"
Sleep 1s
Enter
Enter
Type@50ms "✓ Vault unlocked successfully"
Sleep 1s
Enter
Enter
Type@50ms "  Session active in this shell only"
Sleep 500ms
Enter
Type@50ms "ℹ Use 'dot secret <name>' to retrieve secrets"
Sleep 2s

# Step 2: List secrets
Enter
Type "# List available secrets"
Sleep 500ms
Enter
Type "dot secret list"
Sleep 500ms
Enter
Sleep 1s
Type@50ms "ℹ Retrieving items from vault..."
Sleep 500ms
Enter
Enter
Type@50ms "🔑 github-token (Work/GitHub)"
Sleep 300ms
Enter
Type@50ms "🔑 npm-token (Work/Node)"
Sleep 300ms
Enter
Type@50ms "🔑 anthropic-api-key (AI/Keys)"
Sleep 500ms
Enter
Enter
Type@50ms "ℹ Usage: dot secret <name>"
Sleep 2s

# Step 3: Retrieve secret
Enter
Type "# Retrieve secret (no echo)"
Sleep 500ms
Enter
Type "TOKEN=$(dot secret github-token)"
Sleep 500ms
Enter
Sleep 500ms
Type "echo Retrieved (hidden)"
Sleep 500ms
Enter
Type@50ms "Retrieved (hidden)"
Sleep 2s
