# VHS tape for DOT sync workflow
# Generate: vhs docs/demos/dot/03-sync.tape
# Output: docs/demos/dot/03-sync.gif

# Settings
Output docs/demos/dot/03-sync.gif
Set Shell "zsh"
Set FontSize 14
Set Width 1200
Set Height 600
Set Padding 20
Set Theme "Molokai"

# Title
Type "# DOT Sync Workflow"
Sleep 1s
Enter
Sleep 500ms

# Step 1: Pull from remote
Type "# Pull changes from remote repository"
Sleep 500ms
Enter
Type "dot sync"
Sleep 500ms
Enter
Sleep 1s

# Sync output
Type@50ms "Fetching from remote..."
Sleep 1s
Enter
Enter
Type@50ms "Changes from remote:"
Sleep 500ms
Enter
Type@50ms "M .zshrc          # Updated aliases"
Sleep 300ms
Enter
Type@50ms "M .gitconfig      # New git settings"
Sleep 500ms
Enter
Enter
Type@50ms "Apply updates? [Y/n/d] "
Sleep 1s
Type "Y"
Sleep 300ms
Enter
Sleep 500ms
Type@50ms "✓ Applied 2 files from remote"
Sleep 2s

# Step 2: Push local changes
Enter
Type "# Push your changes to remote"
Sleep 500ms
Enter
Type "dot push"
Sleep 500ms
Enter
Sleep 1s
Type@50ms "Commit message: Add new project aliases"
Sleep 500ms
Enter
Sleep 1s
Type@50ms "✓ Pushed to remote"
Sleep 2s
