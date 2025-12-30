#!/bin/bash
set -euo pipefail

# flow-cli installer
# ZSH workflow tools for ADHD brains
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Data-Wise/flow-cli/main/install.sh | bash
#
# Options:
#   INSTALL_METHOD=antidote|zinit|omz|manual  (default: auto-detect)
#   FLOW_INSTALL_DIR=/custom/path             (default: ~/.flow-cli)

REPO="Data-Wise/flow-cli"
PLUGIN_NAME="flow-cli"
INSTALL_DIR="${FLOW_INSTALL_DIR:-$HOME/.flow-cli}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

info() { echo -e "${BLUE}==>${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1" >&2; exit 1; }

# Detect ZSH plugin manager
detect_plugin_manager() {
    if [[ -n "${INSTALL_METHOD:-}" ]]; then
        echo "$INSTALL_METHOD"
        return
    fi

    # Check for antidote (look for plugins file or command)
    if [[ -f "${ZDOTDIR:-$HOME}/.zsh_plugins.txt" ]] || command -v antidote &>/dev/null; then
        echo "antidote"
    # Check for zinit
    elif [[ -d "$HOME/.zinit" ]] || [[ -d "${ZINIT_HOME:-$HOME/.zinit}" ]] || [[ -d "$HOME/.local/share/zinit" ]]; then
        echo "zinit"
    # Check for oh-my-zsh
    elif [[ -d "$HOME/.oh-my-zsh" ]] || [[ -n "${ZSH:-}" && -d "${ZSH:-}" ]]; then
        echo "omz"
    # Fall back to manual
    else
        echo "manual"
    fi
}

# Install with antidote
install_antidote() {
    info "Installing with antidote..."
    local plugins_file="${ZDOTDIR:-$HOME}/.zsh_plugins.txt"

    # Create plugins file if it doesn't exist
    if [[ ! -f "$plugins_file" ]]; then
        warn "Creating $plugins_file"
        touch "$plugins_file"
    fi

    if ! grep -q "$REPO" "$plugins_file" 2>/dev/null; then
        echo "" >> "$plugins_file"
        echo "# flow-cli - ZSH workflow tools" >> "$plugins_file"
        echo "$REPO" >> "$plugins_file"
        success "Added $REPO to $plugins_file"
    else
        success "Already in $plugins_file"
    fi

    warn "Run 'antidote update' and restart your shell to activate"
}

# Install with zinit
install_zinit() {
    info "Installing with zinit..."
    local zshrc="${ZDOTDIR:-$HOME}/.zshrc"
    local zinit_line="zinit light $REPO"

    if ! grep -q "zinit.*$PLUGIN_NAME" "$zshrc" 2>/dev/null; then
        echo "" >> "$zshrc"
        echo "# flow-cli - ZSH workflow tools" >> "$zshrc"
        echo "$zinit_line" >> "$zshrc"
        success "Added zinit configuration to $zshrc"
    else
        success "Already configured in $zshrc"
    fi

    warn "Restart your shell to activate"
}

# Install with oh-my-zsh
install_omz() {
    info "Installing with oh-my-zsh..."
    local custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    local plugin_dir="$custom_dir/$PLUGIN_NAME"

    mkdir -p "$custom_dir"

    if [[ -d "$plugin_dir" ]]; then
        info "Updating existing installation..."
        git -C "$plugin_dir" pull --quiet
        success "Updated $plugin_dir"
    else
        info "Cloning repository..."
        git clone --quiet "https://github.com/$REPO.git" "$plugin_dir"
        success "Installed to $plugin_dir"
    fi

    # Check if plugin is in plugins list
    local zshrc="${ZDOTDIR:-$HOME}/.zshrc"
    if grep -q "plugins=.*$PLUGIN_NAME" "$zshrc" 2>/dev/null; then
        success "Plugin already in plugins list"
    else
        warn "Add '$PLUGIN_NAME' to plugins=(...) in $zshrc"
        echo ""
        echo "  Example:"
        echo "    plugins=(git $PLUGIN_NAME)"
    fi
}

# Manual installation (fallback)
install_manual() {
    info "Installing manually to $INSTALL_DIR..."

    if [[ -d "$INSTALL_DIR" ]]; then
        info "Updating existing installation..."
        git -C "$INSTALL_DIR" pull --quiet
        success "Updated $INSTALL_DIR"
    else
        info "Cloning repository..."
        git clone --quiet "https://github.com/$REPO.git" "$INSTALL_DIR"
        success "Installed to $INSTALL_DIR"
    fi

    local zshrc="${ZDOTDIR:-$HOME}/.zshrc"
    local source_line="source $INSTALL_DIR/flow.plugin.zsh"

    if ! grep -q "flow.plugin.zsh" "$zshrc" 2>/dev/null; then
        echo "" >> "$zshrc"
        echo "# flow-cli - ZSH workflow tools" >> "$zshrc"
        echo "$source_line" >> "$zshrc"
        success "Added source line to $zshrc"
    else
        success "Already sourced in $zshrc"
    fi

    warn "Restart your shell to activate"
}

# Print quick start guide
print_quickstart() {
    echo ""
    echo -e "${BOLD}Quick Start${NC}"
    echo ""
    echo "  1. Restart your shell or run:"
    echo "     source ~/.zshrc"
    echo ""
    echo "  2. Verify installation:"
    echo "     flow doctor"
    echo ""
    echo "  3. Start working:"
    echo "     work my-project      # Start session"
    echo "     win \"Did something\"  # Log a win"
    echo "     finish               # End session"
    echo ""
    echo -e "${BLUE}Documentation:${NC} https://data-wise.github.io/flow-cli/"
    echo ""
}

# Main installation flow
main() {
    echo ""
    echo -e "${BOLD}flow-cli installer${NC}"
    echo "ZSH workflow tools for ADHD brains"
    echo ""

    # Check for ZSH
    if ! command -v zsh &>/dev/null; then
        error "ZSH is required but not installed. Install ZSH first."
    fi

    # Check for git
    if ! command -v git &>/dev/null; then
        error "Git is required but not installed. Install Git first."
    fi

    local method
    method=$(detect_plugin_manager)

    info "Detected plugin manager: ${BOLD}${method}${NC}"
    echo ""

    case "$method" in
        antidote) install_antidote ;;
        zinit)    install_zinit ;;
        omz)      install_omz ;;
        manual)   install_manual ;;
        *)        error "Unknown install method: $method" ;;
    esac

    echo ""
    success "flow-cli installation complete!"
    print_quickstart
}

main "$@"
