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

# Title using echo
Type "echo 'Teaching Workflow v3.0: Backup System'" Enter
Sleep 1s
Type "echo 'Automated Content Safety'" Enter
Sleep 2s

Type "" Enter
Sleep 1s

# Show teach status with backup info
Type "echo 'Enhanced status shows backup summary:'" Enter
Sleep 1s
Type "teach status" Enter
Sleep 5s

Type "" Enter
Sleep 1s

# Explain backup configuration
Type "echo 'Backup retention policies configured in:'" Enter
Sleep 1s
Type "echo '.flow/teach-config.yml'" Enter
Sleep 2s

Type "" Enter
Sleep 1s

# Show example of where backups are stored
Type "echo 'Backups stored in:'" Enter
Sleep 1s
Type "echo 'content/.backups/<name>.<timestamp>/'" Enter
Sleep 2s

Type "" Enter
Sleep 1s

# Explain when backups are created
Type "echo 'Backups created automatically when:'" Enter
Sleep 1s
Type "echo '  - Generating exams, quizzes, homework'" Enter
Sleep 1s
Type "echo '  - Modifying existing content'" Enter
Sleep 1s
Type "echo '  - Before deleting files'" Enter
Sleep 2s

Type "" Enter
Type "echo '✓ Content protected with automated backups!'" Enter
Sleep 3s
