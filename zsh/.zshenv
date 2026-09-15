# ============================================
# .zshenv - DEAD FILE. zsh never reads this. (verified 2026-09-14)
# ============================================
#
# THIS FILE DOES NOT RUN. Nothing in it takes effect. Read this before
# adding anything to it, and before "fixing" something by moving it here.
#
# Why: zsh reads ${ZDOTDIR:-$HOME}/.zshenv EXACTLY ONCE, at a point where
# ZDOTDIR is still unset -- so it reads ~/.zshenv. That file is what sets
# ZDOTDIR to this directory, which redirects .zprofile, .zshrc and .zlogin.
# But the .zshenv read has already happened by then and is never repeated.
# A .zshenv inside ZDOTDIR is therefore unreachable by construction.
#
# ~/.zshenv states the first half of this correctly ("Setting ZDOTDIR
# anywhere else is too late"); the consequence for THIS file was missed.
#
# What it cost, found 2026-09-14: `claude` was not on PATH in any
# interactive shell -- nor were mkdocs, nlm, radian, aiterm, nexus and 12
# other ~/.local/bin binaries -- and EDITOR/VISUAL were unset, so git and
# less fell back to vi. It went unnoticed for weeks because LaunchAgents
# and Claude Code call those binaries by absolute path.
#
# Those two settings now live in ~/.zshenv, which does run. DO NOT move
# them back here. Everything else below is also set by .zshrc, which runs,
# so nothing else was lost -- and nothing else needs moving.
#
# Reproduce in one line (prints NO if this file is still dead):
#   env -i HOME="$HOME" /bin/zsh -c 'case ":$PATH:" in *":$HOME/.local/bin:"*) echo YES;; *) echo NO;; esac'
#
# The file is kept rather than deleted: it is the only record of what the
# config intended, and deleting it would invite someone to recreate it.
#
# --- everything below this line is inert ---
#
# What it was FOR, when it was believed to load on ALL zsh invocations:
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

# PATH
# uv installs tool shims here (radian, arxiv_latex_cleaner, ...). Set in
# .zshenv, not .zshrc, so non-interactive shells (scripts, Claude Code) can
# reach them too. Guarded: .zshenv is sourced for every zsh invocation, so an
# unconditional prepend would grow PATH once per nested shell.
[[ ":$PATH:" == *":$HOME/.local/bin:"* ]] || export PATH="$HOME/.local/bin:$PATH"

# R Package Development
export R_PACKAGES_DIR="$HOME/R-packages"
export QUARTO_DIR="$HOME/quarto-projects"

# R Console
export R_PROFILE_USER="$HOME/.Rprofile"
export RADIAN_THEME="native"

# Editor
export EDITOR="nvim"
export VISUAL="nvim"

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
# Path updated 2026-09-08: the old ~/.zsh/plugins/flow-cli/ location predates
# the Homebrew install and no longer exists (this guard was silently no-op'ing).
[[ -f /opt/homebrew/opt/flow-cli/flow.plugin.zsh ]] && \
    source /opt/homebrew/opt/flow-cli/flow.plugin.zsh

# ============================================
# OPTIONAL FUNCTIONS (lightweight only)
# ============================================
# Load these only if they don't have heavy dependencies

# Password generator
if [[ -f ~/.config/zsh/functions/genpass.zsh ]]; then
# MIGRATED TO PLUGIN:     source ~/.config/zsh/functions/genpass.zsh
fi

# Obsidian bridge (if used in scripts)
if [[ -f ~/.config/zsh/functions/obsidian-bridge.zsh ]]; then
# MIGRATED TO PLUGIN:     source ~/.config/zsh/functions/obsidian-bridge.zsh
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
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"
