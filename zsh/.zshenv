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
# ESSENTIAL FUNCTIONS - MIGRATED TO PLUGIN 2025-12-23
# ============================================
# All functions now loaded via ~/.zsh/plugins/flow-cli/flow-cli.plugin.zsh
# This provides single source location and proper plugin architecture
#
# The plugin is loaded in .zshrc for interactive shells
# For non-interactive contexts (Claude Code, scripts), source the plugin:
#   source ~/.zsh/plugins/flow-cli/flow-cli.plugin.zsh
#
# IMPORTANT: Keep .zshenv lightweight - only essential env vars
# Functions should be in the plugin to avoid double-loading issues

# Load plugin in non-interactive contexts (Claude Code, scripts, etc.)
# This ensures commands like 'dash', 'work', 'status' work everywhere
[[ -f ~/.zsh/plugins/flow-cli/flow-cli.plugin.zsh ]] && \
    source ~/.zsh/plugins/flow-cli/flow-cli.plugin.zsh

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
