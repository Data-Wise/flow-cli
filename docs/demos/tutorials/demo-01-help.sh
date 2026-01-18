#!/bin/zsh
# Scholar Enhancement Demo 1: Help System

# Source flow-cli to make teach available
source /Users/dt/.git-worktrees/flow-cli/feature/teaching-flags/flow.plugin.zsh 2>/dev/null

# Clear screen
clear
sleep 1

# Show command with prompt
echo "❯ teach slides --help"
sleep 1.5

# Run command
teach slides --help

# Pause to read
sleep 4

# Clear and next command
clear
sleep 0.5

echo "❯ teach quiz --help"
sleep 1.5

# Run command
teach quiz --help

# Pause to read
sleep 4

# Clear and next command
clear
sleep 0.5

echo "❯ teach lecture --help"
sleep 1.5

# Run command
teach lecture --help

# Final pause
sleep 5
