# VHS Demo: teach status - Enhanced Status Display
# Part of flow-cli Teaching Workflow v3.0
# Tutorial: Enhanced status with deployment info, backup summary, and week info

Output tutorial-teach-status.gif

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
Type "echo 'Teaching Workflow v3.0: Enhanced Status'" Enter
Sleep 1s
Type "echo 'Comprehensive Project Overview'" Enter
Sleep 2s

Type "" Enter
Sleep 1s

# Show enhanced status
Type "echo 'Full status with all information:'" Enter
Sleep 1s
Type "teach status" Enter
Sleep 6s

Type "" Enter
Sleep 1s

# Explain what's shown
Type "echo 'Enhanced status includes:'" Enter
Sleep 1s
Type "echo '  • Course configuration and dates'" Enter
Sleep 1s
Type "echo '  • Current week and schedule'" Enter
Sleep 1s
Type "echo '  • Git branch and deployment status'" Enter
Sleep 1s
Type "echo '  • Backup summary and retention'" Enter
Sleep 2s

Type "" Enter
Type "echo '✓ Complete project overview at a glance!'" Enter
Sleep 2s
