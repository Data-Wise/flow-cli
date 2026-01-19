# VHS Demo: teach init - Project Initialization
# Part of flow-cli Teaching Workflow v3.0
# Tutorial: Initialize teaching project with enhanced features

Output tutorial-teach-init.gif

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
Type "cd /tmp && mkdir -p teach-demo && cd teach-demo" Enter
Sleep 500ms
Type "clear" Enter
Show

# Title
Type "echo 'Teaching Workflow v3.0: teach init'" Enter
Sleep 1s
Type "echo 'Enhanced Project Initialization'" Enter
Sleep 2s

Type "" Enter
Sleep 1s

# Show help
Type "echo 'Available options:'" Enter
Sleep 1s
Type "teach init --help | head -20" Enter
Sleep 4s

Type "" Enter
Type "clear" Enter
Sleep 1s

# Basic init
Type "echo 'Initialize new teaching project:'" Enter
Sleep 1s
Type "teach init" Enter
Sleep 3s

Type "" Enter
Sleep 1s

# Show what was created
Type "echo 'Files created:'" Enter
Sleep 1s
Type "ls -la .flow/" Enter
Sleep 2s

Type "" Enter
Sleep 1s

# Show config
Type "echo 'Generated configuration:'" Enter
Sleep 1s
Type "yq '.course' .flow/teach-config.yml" Enter
Sleep 3s

Type "" Enter
Type "echo '✓ Teaching project initialized!'" Enter
Sleep 2s
