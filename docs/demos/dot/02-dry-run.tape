# VHS tape for DOT dry-run mode (v5.1.0)
# Generate: vhs docs/demos/dot/02-dry-run.tape
# Output: docs/demos/dot/02-dry-run.gif

# Settings
Output docs/demos/dot/02-dry-run.gif
Set Shell "zsh"
Set FontSize 14
Set Width 1200
Set Height 600
Set Padding 20
Set Theme "Molokai"

# Title
Type "# DOT Dry-Run Mode (v5.1.0)"
Sleep 1s
Enter
Sleep 500ms

# Step 1: Show pending changes
Type "# Preview changes without applying"
Sleep 500ms
Enter
Type "dot apply --dry-run"
Sleep 500ms
Enter
Sleep 1s

# Dry-run output
Type@50ms "DRY-RUN MODE - No changes will be applied"
Sleep 500ms
Enter
Enter
Type@50ms "Showing what would change (dry-run)..."
Sleep 500ms
Enter
Enter
Type@50ms "Files to update: 2"
Sleep 500ms
Enter
Enter
Type@50ms "M .zshrc"
Sleep 300ms
Enter
Type@50ms "M .gitconfig"
Sleep 500ms
Enter
Enter
Type@50ms "[Shows verbose diff...]"
Sleep 1s
Enter
Enter
Type@50ms "✓ Dry-run complete - no changes applied"
Sleep 2s

# Step 2: Now apply for real
Enter
Type "# Safe to apply now"
Sleep 500ms
Enter
Type "dot apply"
Sleep 500ms
Enter
Sleep 500ms
Type@50ms "✓ Applied 2 files"
Sleep 2s
