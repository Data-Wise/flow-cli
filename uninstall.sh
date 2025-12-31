#!/bin/bash
set -euo pipefail

# flow-cli uninstaller
# Cleanly removes flow-cli from your system
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Data-Wise/flow-cli/main/uninstall.sh | bash
#
# Or run locally:
#   bash uninstall.sh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

info() { echo -e "${YELLOW}==>${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }

# Detect installation method
detect_installation() {
    local zshrc="${ZDOTDIR:-$HOME}/.zshrc"
    local plugins_file="${ZDOTDIR:-$HOME}/.zsh_plugins.txt"

    # Check antidote
    if [[ -f "$plugins_file" ]] && grep -q "flow-cli" "$plugins_file" 2>/dev/null; then
        echo "antidote"
        return
    fi

    # Check zinit
    if grep -q "zinit.*flow-cli" "$zshrc" 2>/dev/null; then
        echo "zinit"
        return
    fi

    # Check oh-my-zsh
    local omz_plugin="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/flow-cli"
    if [[ -d "$omz_plugin" ]]; then
        echo "omz"
        return
    fi

    # Check manual
    if [[ -d "$HOME/.flow-cli" ]]; then
        echo "manual"
        return
    fi

    echo "none"
}

# Remove from antidote
uninstall_antidote() {
    info "Removing from antidote..."
    local plugins_file="${ZDOTDIR:-$HOME}/.zsh_plugins.txt"

    if [[ -f "$plugins_file" ]]; then
        # Remove flow-cli lines (including comment)
        sed -i.bak '/flow-cli/d' "$plugins_file"
        rm -f "${plugins_file}.bak"
        success "Removed from $plugins_file"
    fi

    # Remove cached plugin
    local cache_dir="${ANTIDOTE_HOME:-$HOME/.cache/antidote}"
    if [[ -d "$cache_dir" ]]; then
        rm -rf "$cache_dir"/*flow-cli* 2>/dev/null || true
        success "Cleared antidote cache"
    fi

    warn "Run 'antidote update' to complete removal"
}

# Remove from zinit
uninstall_zinit() {
    info "Removing from zinit..."
    local zshrc="${ZDOTDIR:-$HOME}/.zshrc"

    if [[ -f "$zshrc" ]]; then
        # Remove zinit flow-cli lines
        sed -i.bak '/flow-cli/d' "$zshrc"
        rm -f "${zshrc}.bak"
        success "Removed from $zshrc"
    fi

    # Remove zinit plugin directory
    local zinit_plugins="${ZINIT_HOME:-$HOME/.zinit}/plugins"
    if [[ -d "$zinit_plugins" ]]; then
        rm -rf "$zinit_plugins"/*flow-cli* 2>/dev/null || true
        success "Removed zinit plugin files"
    fi
}

# Remove from oh-my-zsh
uninstall_omz() {
    info "Removing from oh-my-zsh..."
    local plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/flow-cli"

    if [[ -d "$plugin_dir" ]]; then
        rm -rf "$plugin_dir"
        success "Removed $plugin_dir"
    fi

    local zshrc="${ZDOTDIR:-$HOME}/.zshrc"
    warn "Remember to remove 'flow-cli' from plugins=(...) in $zshrc"
}

# Remove manual installation
uninstall_manual() {
    info "Removing manual installation..."
    local install_dir="$HOME/.flow-cli"
    local zshrc="${ZDOTDIR:-$HOME}/.zshrc"

    if [[ -d "$install_dir" ]]; then
        rm -rf "$install_dir"
        success "Removed $install_dir"
    fi

    if [[ -f "$zshrc" ]]; then
        # Remove source line
        sed -i.bak '/flow.plugin.zsh/d' "$zshrc"
        sed -i.bak '/flow-cli.*ZSH workflow/d' "$zshrc"
        rm -f "${zshrc}.bak"
        success "Removed from $zshrc"
    fi
}

# Main uninstall flow
main() {
    echo ""
    echo -e "${BOLD}flow-cli uninstaller${NC}"
    echo ""

    local method
    method=$(detect_installation)

    if [[ "$method" == "none" ]]; then
        warn "flow-cli installation not detected"
        echo ""
        echo "Checked locations:"
        echo "  - ~/.zsh_plugins.txt (antidote)"
        echo "  - ~/.zshrc (zinit)"
        echo "  - ~/.oh-my-zsh/custom/plugins/flow-cli"
        echo "  - ~/.flow-cli"
        exit 0
    fi

    info "Detected installation: ${BOLD}${method}${NC}"
    echo ""

    case "$method" in
        antidote) uninstall_antidote ;;
        zinit)    uninstall_zinit ;;
        omz)      uninstall_omz ;;
        manual)   uninstall_manual ;;
    esac

    echo ""
    success "flow-cli has been uninstalled"
    echo ""
    echo "Restart your shell or run:"
    echo "  source ~/.zshrc"
    echo ""
}

main "$@"
