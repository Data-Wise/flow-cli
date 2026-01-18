#!/bin/zsh
# Scholar Enhancement Demo 1: Help System

# Change to flow-cli directory and source plugin
cd /Users/dt/.git-worktrees/flow-cli/feature/teaching-flags
source flow.plugin.zsh 2>/dev/null

# Change back to demos directory
cd docs/demos/tutorials

# Clear screen
clear
sleep 1

# Show command with prompt
echo "❯ teach slides --help"
sleep 1.5

# Run actual command
teach slides --help

# Pause to read
sleep 4

# Clear and next command
clear
sleep 0.5

echo "❯ teach quiz --help"
sleep 1.5

# Run actual command
teach quiz --help

# Pause to read
sleep 4

# Clear and next command
clear
sleep 0.5

echo "❯ teach lecture --help"
sleep 1.5

# Run actual command
teach lecture --help

# Final pause
sleep 5
