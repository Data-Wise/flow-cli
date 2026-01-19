# VHS Demo: teach doctor - Environment Health Check
# Part of flow-cli Teaching Workflow v3.0
# Tutorial: Using teach doctor to validate teaching environment

Output tutorial-teach-doctor.gif

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
Type "echo 'Teaching Workflow v3.0: teach doctor'" Enter
Sleep 1s
Type "echo 'Environment Health Check'" Enter
Sleep 2s

# Show the help first
Type "teach doctor --help" Enter
Sleep 4s

Type "clear" Enter
Sleep 1s

# Basic health check
Type "echo 'Run basic health check'" Enter
Sleep 1s
Type "teach doctor" Enter
Sleep 5s

Type "" Enter
Sleep 1s

# Quiet mode
Type "echo 'Quiet mode - only warnings/failures'" Enter
Sleep 1s
Type "teach doctor --quiet" Enter
Sleep 2s

Type "" Enter
Sleep 1s

# Show completion
Type "echo '✓ Environment validated!'" Enter
Sleep 2s
