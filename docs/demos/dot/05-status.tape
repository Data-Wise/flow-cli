# VHS tape for DOT status and dashboard
# Generate: vhs docs/demos/dot/05-status.tape
# Output: docs/demos/dot/05-status.gif

# Settings
Output docs/demos/dot/05-status.gif
Set Shell "zsh"
Set FontSize 14
Set Width 1200
Set Height 600
Set Padding 20
Set Theme "Molokai"

# Title
Type "# DOT Status & Dashboard"
Sleep 1s
Enter
Sleep 500ms

# Step 1: Quick status
Type "# Check dotfile status"
Sleep 500ms
Enter
Type "dot"
Sleep 500ms
Enter
Sleep 1s

# Status output
Type@50ms "Dotfile Status: 🟢 Synced"
Sleep 500ms
Enter
Enter
Type@50ms "Last sync:     2 hours ago"
Sleep 300ms
Enter
Type@50ms "Tracked files: 12"
Sleep 300ms
Enter
Type@50ms "Remote:        git@github.com:user/dotfiles.git"
Sleep 300ms
Enter
Type@50ms "Modified:      0 files pending"
Sleep 500ms
Enter
Enter
Type@50ms "Run 'dot help' for commands"
Sleep 2s

# Step 2: Dashboard integration
Enter
Type "# View in dashboard"
Sleep 500ms
Enter
Type "dash"
Sleep 500ms
Enter
Sleep 1s

# Dashboard output (simplified)
Type@50ms "╭──────────────────────────────────────────────╮"
Sleep 300ms
Enter
Type@50ms "│  🌊 FLOW DASHBOARD ✓      Jan 10 🕐 14:30   │"
Sleep 300ms
Enter
Type@50ms "╰──────────────────────────────────────────────╯"
Sleep 500ms
Enter
Enter
Type@50ms "  📝 Dotfiles: 🟢 Synced (2h ago) · 12 files"
Sleep 500ms
Enter
Enter
Type@50ms "  ... (other status)"
Sleep 2s
