# VHS tape for DOT improved error handling (v5.1.0)
# Generate: vhs docs/demos/dot/06-error-handling.tape
# Output: docs/demos/dot/06-error-handling.gif

# Settings
Output docs/demos/dot/06-error-handling.gif
Set Shell "zsh"
Set FontSize 14
Set Width 1200
Set Height 600
Set Padding 20
Set Theme "Molokai"

# Title
Type "# DOT Error Handling (v5.1.0)"
Sleep 1s
Enter
Sleep 500ms

# Scenario 1: Secret not found
Type "# Try to get non-existent secret"
Sleep 500ms
Enter
Type "dot secret wrong-name"
Sleep 500ms
Enter
Sleep 1s
Type@50ms "✗ Secret not found: wrong-name"
Sleep 500ms
Enter
Type@50ms "Tip: Use 'dot secret list' to see available items"
Sleep 2s

# Scenario 2: Session expired
Enter
Enter
Type "# Session expired scenario"
Sleep 500ms
Enter
Type "dot secret github-token"
Sleep 500ms
Enter
Sleep 1s
Type@50ms "✗ Session expired"
Sleep 500ms
Enter
Type@50ms "Run: dot unlock"
Sleep 2s

# Scenario 3: Vault locked
Enter
Enter
Type "# Vault locked scenario"
Sleep 500ms
Enter
Type "dot secret api-key"
Sleep 500ms
Enter
Sleep 1s
Type@50ms "✗ Vault is locked"
Sleep 500ms
Enter
Type@50ms "Run: dot unlock"
Sleep 2s

# Show the fix
Enter
Enter
Type "# Follow the guidance"
Sleep 500ms
Enter
Type "dot unlock"
Sleep 500ms
Enter
Sleep 1s
Type@50ms "✓ Vault unlocked successfully"
Sleep 2s
