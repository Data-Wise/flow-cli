# VHS Demo: Backup System - Content Safety
# Part of flow-cli Teaching Workflow v3.0
# Tutorial: Automated backup system with retention policies

Output tutorial-backup-system.gif

Require echo

Set Shell zsh
Set FontSize 18
Set Width 1400
Set Height 900
Set TypingSpeed 50ms
Set PlaybackSpeed 0.8

Hide
# Source flow-cli to load latest version
Type "source ~/projects/dev-tools/flow-cli/flow.plugin.zsh" Enter
Sleep 1s
Type "cd ~/projects/teaching/scholar-demo-course" Enter
Sleep 500ms
Type "clear" Enter
Show

# Title
Type "# Teaching Workflow v3.0: Backup System" Enter
Sleep 1s
Type "# Automated Content Safety" Enter
Sleep 2s

# Show teach status with backup info
Type "# Enhanced status shows backup summary" Enter
Sleep 1s
Type "teach status" Enter
Sleep 4s

Type "" Enter
Sleep 1s

# Show retention policy configuration
Type "# Retention policies (archive vs semester)" Enter
Sleep 1s
Type "yq '.backups.retention' .flow/teach-config.yml" Enter
Sleep 3s

Type "" Enter
Sleep 1s

# Show existing backups
Type "# Check existing backups" Enter
Sleep 1s
Type "ls -la content/.backups/ 2>/dev/null | head -10 || echo 'Backups created automatically on content generation'" Enter
Sleep 3s

Type "" Enter
Sleep 1s

# Explain how backups work
Type "# Backups created automatically when:" Enter
Sleep 1s
Type "# - teach exam, quiz, homework, etc." Enter
Sleep 1s
Type "# - Content is modified" Enter
Sleep 1s
Type "# - teach delete (with confirmation)" Enter
Sleep 2s

Type "" Enter
Type "# ✓ Content protected with automated backups!" Enter
Sleep 3s
