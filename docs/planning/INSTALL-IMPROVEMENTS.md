# Installation Improvements Plan

**Created:** 2025-12-30
**Status:** Ready for Implementation
**Priority:** P1 - Immediate
**Effort:** ~2 hours total

---

## Overview

Improve flow-cli installation experience to match aiterm standards:

| Feature | Current | Target |
|---------|---------|--------|
| One-liner install | ❌ | `curl -fsSL .../install.sh \| bash` |
| Install methods table | ❌ | Comparison in README |
| Auto-detect plugin manager | ❌ | antidote → zinit → omz → manual |
| Post-install verification | ✅ `flow doctor` | Keep |

---

## Implementation Plan

### Task 1: Create install.sh (~45 min)

**File:** `install.sh` (project root)

**Features:**
1. Auto-detect ZSH plugin manager (antidote, zinit, oh-my-zsh)
2. Install using detected method
3. Fall back to manual git clone + source
4. Run `flow doctor` for verification
5. Show quick start commands

**Reference:** aiterm's install.sh pattern

```bash
#!/bin/bash
set -euo pipefail

# flow-cli installer
# ZSH workflow tools for ADHD brains
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Data-Wise/flow-cli/main/install.sh | bash

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
    # Check for antidote
    if [[ -f "$HOME/.zsh_plugins.txt" ]] || command -v antidote &>/dev/null; then
        echo "antidote"
    # Check for zinit
    elif [[ -d "$HOME/.zinit" ]] || [[ -d "${ZINIT_HOME:-}" ]]; then
        echo "zinit"
    # Check for oh-my-zsh
    elif [[ -d "$HOME/.oh-my-zsh" ]] || [[ -d "${ZSH:-}" ]]; then
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

    if ! grep -q "$REPO" "$plugins_file" 2>/dev/null; then
        echo "$REPO" >> "$plugins_file"
        success "Added to $plugins_file"
        warn "Run 'source ~/.zshrc' or restart shell to activate"
    else
        success "Already in $plugins_file"
    fi
}

# Install with zinit
install_zinit() {
    info "Installing with zinit..."
    local zshrc="${ZDOTDIR:-$HOME}/.zshrc"
    local zinit_line="zinit light $REPO"

    if ! grep -q "zinit.*$PLUGIN_NAME" "$zshrc" 2>/dev/null; then
        echo "" >> "$zshrc"
        echo "# flow-cli" >> "$zshrc"
        echo "$zinit_line" >> "$zshrc"
        success "Added to $zshrc"
        warn "Run 'source ~/.zshrc' or restart shell to activate"
    else
        success "Already in $zshrc"
    fi
}

# Install with oh-my-zsh
install_omz() {
    info "Installing with oh-my-zsh..."
    local custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    local plugin_dir="$custom_dir/$PLUGIN_NAME"

    mkdir -p "$custom_dir"

    if [[ -d "$plugin_dir" ]]; then
        info "Updating existing installation..."
        git -C "$plugin_dir" pull
    else
        git clone "https://github.com/$REPO.git" "$plugin_dir"
    fi

    success "Installed to $plugin_dir"
    warn "Add '$PLUGIN_NAME' to plugins=(...) in ~/.zshrc"
}

# Manual installation
install_manual() {
    info "Installing manually to $INSTALL_DIR..."

    if [[ -d "$INSTALL_DIR" ]]; then
        info "Updating existing installation..."
        git -C "$INSTALL_DIR" pull
    else
        git clone "https://github.com/$REPO.git" "$INSTALL_DIR"
    fi

    local zshrc="${ZDOTDIR:-$HOME}/.zshrc"
    local source_line="source $INSTALL_DIR/flow.plugin.zsh"

    if ! grep -q "flow.plugin.zsh" "$zshrc" 2>/dev/null; then
        echo "" >> "$zshrc"
        echo "# flow-cli" >> "$zshrc"
        echo "$source_line" >> "$zshrc"
        success "Added to $zshrc"
    else
        success "Already sourced in $zshrc"
    fi

    warn "Run 'source ~/.zshrc' or restart shell to activate"
}

# Verify installation
verify_install() {
    info "Verifying installation..."

    # Source the plugin to test
    if [[ -f "$INSTALL_DIR/flow.plugin.zsh" ]]; then
        source "$INSTALL_DIR/flow.plugin.zsh" 2>/dev/null || true
    fi

    echo ""
    success "flow-cli installed successfully!"
    echo ""
    info "Quick start:"
    echo "  source ~/.zshrc      # Reload shell"
    echo "  flow doctor          # Verify installation"
    echo "  work my-project      # Start working"
    echo "  win \"Did something\"  # Log a win"
    echo ""
    info "Documentation: https://data-wise.github.io/flow-cli/"
}

# Main installation flow
main() {
    echo ""
    echo -e "${BOLD}flow-cli installer${NC}"
    echo "ZSH workflow tools for ADHD brains"
    echo ""

    # Check for ZSH
    if [[ ! -x "$(command -v zsh)" ]]; then
        error "ZSH is required but not installed."
    fi

    # Check for git
    if [[ ! -x "$(command -v git)" ]]; then
        error "Git is required but not installed."
    fi

    local method
    method=$(detect_plugin_manager)

    info "Detected plugin manager: ${method}"
    echo ""

    case "$method" in
        antidote) install_antidote ;;
        zinit)    install_zinit ;;
        omz)      install_omz ;;
        manual)   install_manual ;;
        *)        error "Unknown install method: $method" ;;
    esac

    echo ""
    verify_install
}

main "$@"
```

---

### Task 2: Update README.md (~15 min)

Add installation methods comparison table after the 10-Second Start section:

```markdown
## Installation Methods

| Method | Command | Best For |
|--------|---------|----------|
| **Quick Install** | `curl -fsSL .../install.sh \| bash` | New users |
| **Antidote** | `antidote install data-wise/flow-cli` | Antidote users |
| **Zinit** | `zinit light data-wise/flow-cli` | Zinit users |
| **Oh-My-Zsh** | Clone to `$ZSH_CUSTOM/plugins/` | OMZ users |
| **Manual** | `git clone` + source | Full control |

### Quick Install (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/Data-Wise/flow-cli/main/install.sh | bash
```

Auto-detects: antidote → zinit → oh-my-zsh → manual
```

---

### Task 3: Update docs/getting-started/installation.md (~30 min)

Restructure to match aiterm's GETTING-STARTED.md style:

1. Add time estimates ("~5 minutes")
2. Add checkpoints after each step
3. Add tabbed install methods (MkDocs Material tabs)
4. Update verification section

---

### Task 4: Test Installation (~30 min)

Test scenarios:
1. Fresh macOS with antidote
2. System with zinit
3. System with oh-my-zsh
4. Manual installation (no plugin manager)

---

## Success Criteria

- [ ] `curl -fsSL .../install.sh | bash` works on fresh system
- [ ] Auto-detects antidote/zinit/omz correctly
- [ ] `flow doctor` passes after install
- [ ] README has clear comparison table
- [ ] installation.md matches aiterm quality

---

## Files to Create/Modify

| File | Action | Priority |
|------|--------|----------|
| `install.sh` | Create | P1 |
| `README.md` | Update (add table) | P1 |
| `docs/getting-started/installation.md` | Rewrite | P2 |
| `CLAUDE.md` | Add install.sh reference | P2 |
| `.STATUS` | Update with task | P3 |

---

## Reference

- **aiterm install.sh:** `/Users/dt/projects/dev-tools/aiterm/install.sh`
- **aiterm GETTING-STARTED.md:** `/Users/dt/projects/dev-tools/aiterm/docs/GETTING-STARTED.md`

---

**Ready to implement.** Start with Task 1 (install.sh).
