# ============================================
# .zshenv - ALWAYS loaded (interactive + non-interactive)
# ============================================
#
# This file is sourced for ALL ZSH invocations:
# - Interactive shells (terminal sessions)
# - Non-interactive shells (scripts, Claude Code, command substitution)
# - Login and non-login shells
#
# Use this for:
# - Essential PATH modifications
# - Core environment variables
# - Lightweight function definitions needed everywhere
#
# Keep heavy/interactive features in .zshrc instead:
# - Prompt customization (Powerlevel10k)
# - Plugins (antidote, OMZ)
# - Completion system
# - Interactive aliases and bindings
# ============================================

# ============================================
# ENVIRONMENT VARIABLES (from .zshrc)
# ============================================

# R Package Development
export R_PACKAGES_DIR="$HOME/R-packages"
export QUARTO_DIR="$HOME/quarto-projects"

# R Console
export R_PROFILE_USER="$HOME/.Rprofile"
export RADIAN_THEME="native"

# Editor
export EDITOR="emacsclient -t"
export VISUAL="emacsclient -c"

# ============================================
# ESSENTIAL FUNCTIONS
# ============================================
# Load functions needed in non-interactive contexts
# These work in: scripts, Claude Code, command substitution, etc.

# Core utilities (used by other functions)
if [[ -f ~/.config/zsh/functions/core-utils.zsh ]]; then
    source ~/.config/zsh/functions/core-utils.zsh
fi

# Project detection (used by work, dash, status)
if [[ -f ~/.config/zsh/functions/project-detector.zsh ]]; then
    source ~/.config/zsh/functions/project-detector.zsh
fi

# Dashboard (frequently used in Claude Code)
if [[ -f ~/.config/zsh/functions/dash.zsh ]]; then
    source ~/.config/zsh/functions/dash.zsh
fi

# Status management (frequently used in Claude Code)
if [[ -f ~/.config/zsh/functions/status.zsh ]]; then
    source ~/.config/zsh/functions/status.zsh
fi

# Work command (session management)
if [[ -f ~/.config/zsh/functions/work.zsh ]]; then
    source ~/.config/zsh/functions/work.zsh
fi

# ADHD helpers (js, why, win, focus, etc.)
if [[ -f ~/.config/zsh/functions/adhd-helpers.zsh ]]; then
    source ~/.config/zsh/functions/adhd-helpers.zsh
fi

# Claude workflows (cc, ccc, ccplan, etc.)
if [[ -f ~/.config/zsh/functions/claude-workflows.zsh ]]; then
    source ~/.config/zsh/functions/claude-workflows.zsh
fi

# MCP dispatcher (ml, mc, mcps, etc.)
if [[ -f ~/.config/zsh/functions/mcp-dispatcher.zsh ]]; then
    source ~/.config/zsh/functions/mcp-dispatcher.zsh
fi

# Smart dispatchers (context-aware commands)
if [[ -f ~/.config/zsh/functions/smart-dispatchers.zsh ]]; then
    source ~/.config/zsh/functions/smart-dispatchers.zsh
fi

# v-dispatcher (version management)
if [[ -f ~/.config/zsh/functions/v-dispatcher.zsh ]]; then
    source ~/.config/zsh/functions/v-dispatcher.zsh
fi

# g-dispatcher (git workflows)
if [[ -f ~/.config/zsh/functions/g-dispatcher.zsh ]]; then
    source ~/.config/zsh/functions/g-dispatcher.zsh
fi

# ============================================
# OPTIONAL FUNCTIONS (lightweight only)
# ============================================
# Load these only if they don't have heavy dependencies

# Password generator
if [[ -f ~/.config/zsh/functions/genpass.zsh ]]; then
    source ~/.config/zsh/functions/genpass.zsh
fi

# Obsidian bridge (if used in scripts)
if [[ -f ~/.config/zsh/functions/obsidian-bridge.zsh ]]; then
    source ~/.config/zsh/functions/obsidian-bridge.zsh
fi

# ============================================
# NOTE: Interactive-only functions
# ============================================
# These are loaded in .zshrc instead (require interactivity):
# - fzf-helpers.zsh (requires terminal interaction)
# - claude-response-viewer.zsh (uses glow, requires display)
# - bg-agents.zsh (background job management)
#
# They will still be available in interactive shells via .zshrc
