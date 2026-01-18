#!/bin/zsh
# Scholar Enhancement Demo 1: Help System

# Colors for output
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Source flow-cli to make teach available
source /Users/dt/.git-worktrees/flow-cli/feature/teaching-flags/flow.plugin.zsh 2>/dev/null

# Clear screen
clear

# Show prompt and command
echo -e "${BLUE}❯${NC} teach slides --help"
sleep 1

# Run command
teach slides --help

# Pause
sleep 2

# Show next command
echo
echo -e "${BLUE}❯${NC} teach quiz --help"
sleep 1

# Run command
teach quiz --help

# Pause
sleep 2

# Show next command
echo
echo -e "${BLUE}❯${NC} teach lecture --help"
sleep 1

# Run command
teach lecture --help

# Final pause
sleep 3
