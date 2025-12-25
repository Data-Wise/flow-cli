# ══════════════════════════════════════════════════════════════════════════════
# ZSH-CLEAN - ADHD-Friendly Maintenance for ZSH Configuration
# ══════════════════════════════════════════════════════════════════════════════
#
# PHILOSOPHY: Just type `zsh-clean` and everything gets done. Zero decisions.
#
# Usage: zsh-clean [command]
#
# Commands:
#   (default)  Do everything: archive junk + sync to GitHub
#   status     Show health summary only
#   undo       Discard uncommitted changes
#   test       Run test suite
#   help       Show this help
#
# ══════════════════════════════════════════════════════════════════════════════

ZSH_CONFIG_DIR="${ZSH_CONFIG_DIR:-$HOME/.config/zsh}"
ZSH_ARCHIVE_DIR="$ZSH_CONFIG_DIR/.archive"

# Colors
_ZC_GREEN='\033[32m'
_ZC_YELLOW='\033[33m'
_ZC_BLUE='\033[34m'
_ZC_RED='\033[31m'
_ZC_BOLD='\033[1m'
_ZC_DIM='\033[2m'
_ZC_NC='\033[0m'

_zsh_clean_help() {
    cat <<'EOF'
zsh-clean - ADHD-Friendly Maintenance for ZSH Configuration

USAGE:
    zsh-clean              # Do everything (recommended)
    zsh-clean [command]    # Run specific command

COMMANDS:
    (no args)  Do everything: archive junk → sync to GitHub
    status     Show health summary only
    undo       Discard uncommitted changes
    test       Run test suite
    help       Show this help

PHILOSOPHY:
    Just type `zsh-clean` and forget about it.
    - Archives any junk files (.bak, .tmp, etc.)
    - Commits and pushes to GitHub automatically
    - Zero decisions required

BACKUP STRATEGY:
    • GitHub: Full version history (automatic on zsh-clean)
    • Google Drive: Auto-syncs ~/projects/ in real-time

RECOVERY:
    zsh-clean undo         # Discard recent changes
    git log --oneline      # See history
    git checkout <hash>    # Restore specific version

EXAMPLES:
    zsh-clean              # Just do this! Does everything
    zsh-clean undo         # Oops, revert changes
    zsh-clean status       # Quick health check
EOF
}

# ─────────────────────────────────────────────────────────────────────────────
# Archive junk files (internal)
# ─────────────────────────────────────────────────────────────────────────────
_zsh_clean_archive() {
    [[ ! -d "$ZSH_ARCHIVE_DIR" ]] && mkdir -p "$ZSH_ARCHIVE_DIR"

    local count=0

    while IFS= read -r -d '' file; do
        local base=$(basename "$file")
        local target="$ZSH_ARCHIVE_DIR/$base"
        [[ -f "$target" ]] && target="$ZSH_ARCHIVE_DIR/${base}-$(date +%Y%m%d-%H%M%S)"
        mv "$file" "$target" 2>/dev/null && ((count++))
    done < <(find "$ZSH_CONFIG_DIR" -maxdepth 2 -type f \( \
        -name "*.bak" -o -name "*.bak[0-9]*" -o -name "*.backup*" -o \
        -name "*.tmp" -o -name "*.broken*" -o -name "*-backup-*" \
    \) ! -path "*/.archive/*" -print0 2>/dev/null)

    if [[ $count -gt 0 ]]; then
        echo -e "  ${_ZC_GREEN}✓${_ZC_NC} Archived $count junk file(s)"
    else
        echo -e "  ${_ZC_GREEN}✓${_ZC_NC} No junk to archive"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Sync to GitHub (internal)
# ─────────────────────────────────────────────────────────────────────────────
_zsh_clean_sync_internal() {
    local real_dir=$(readlink -f "$ZSH_CONFIG_DIR" 2>/dev/null || echo "$ZSH_CONFIG_DIR")
    local git_dir=$(cd "$real_dir" && git rev-parse --show-toplevel 2>/dev/null)

    if [[ -z "$git_dir" ]]; then
        echo -e "  ${_ZC_DIM}(not a git repo - skipping sync)${_ZC_NC}"
        return 0
    fi

    cd "$git_dir" || return 1

    # Check for changes
    if git diff --quiet && git diff --cached --quiet && [[ -z $(git ls-files --others --exclude-standard zsh/) ]]; then
        echo -e "  ${_ZC_GREEN}✓${_ZC_NC} Git already up to date"
        cd - > /dev/null
        return 0
    fi

    # Stage zsh/ changes
    git add zsh/ 2>/dev/null

    # Commit with auto-generated message
    local msg="zsh config update $(date +%Y-%m-%d)"
    if git commit -m "$msg

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>" &>/dev/null; then
        echo -e "  ${_ZC_GREEN}✓${_ZC_NC} Committed changes"
    fi

    # Push
    if git push &>/dev/null; then
        echo -e "  ${_ZC_GREEN}✓${_ZC_NC} Pushed to GitHub"
    else
        echo -e "  ${_ZC_YELLOW}⚠${_ZC_NC} Push failed (check remote)"
    fi

    cd - > /dev/null
}

# ─────────────────────────────────────────────────────────────────────────────
# Status display
# ─────────────────────────────────────────────────────────────────────────────
_zsh_clean_status() {
    echo ""
    echo -e "${_ZC_BOLD}═══════════════════════════════════════════════════════════${_ZC_NC}"
    echo -e "${_ZC_BOLD}  🩺 ZSH Configuration Health${_ZC_NC}"
    echo -e "${_ZC_BOLD}═══════════════════════════════════════════════════════════${_ZC_NC}"
    echo ""

    local junk_count=$(find "$ZSH_CONFIG_DIR" -maxdepth 2 -type f \( \
        -name "*.bak" -o -name "*.bak[0-9]*" -o -name "*.backup*" -o \
        -name "*.tmp" -o -name "*.broken*" -o -name "*-backup-*" \
    \) ! -path "*/.archive/*" 2>/dev/null | wc -l | tr -d ' ')

    local func_count=$(ls "$ZSH_CONFIG_DIR/functions/"*.zsh 2>/dev/null | wc -l | tr -d ' ')
    local config_size=$(du -sh "$ZSH_CONFIG_DIR" 2>/dev/null | cut -f1)

    # Git status
    local real_dir=$(readlink -f "$ZSH_CONFIG_DIR" 2>/dev/null || echo "$ZSH_CONFIG_DIR")
    local git_status="not a repo"
    if cd "$real_dir" && git rev-parse --git-dir &>/dev/null; then
        if git diff --quiet && git diff --cached --quiet && [[ -z $(git ls-files --others --exclude-standard) ]]; then
            git_status="${_ZC_GREEN}synced${_ZC_NC}"
        else
            git_status="${_ZC_YELLOW}uncommitted${_ZC_NC}"
        fi
    fi
    cd - > /dev/null 2>&1

    echo -e "  📁 Config: $ZSH_CONFIG_DIR ($config_size)"
    echo -e "  📦 Functions: $func_count files"
    echo -e "  ☁️  Git: $git_status"

    if [[ $junk_count -eq 0 ]]; then
        echo -e "  🧹 Junk: ${_ZC_GREEN}none${_ZC_NC}"
    else
        echo -e "  🧹 Junk: ${_ZC_YELLOW}$junk_count file(s)${_ZC_NC}"
    fi

    echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# Default: Do everything (ADHD-friendly - just run it!)
# ─────────────────────────────────────────────────────────────────────────────
_zsh_clean_full() {
    echo ""
    echo -e "${_ZC_BOLD}═══════════════════════════════════════════════════════════${_ZC_NC}"
    echo -e "${_ZC_BOLD}  🧹 ZSH Config Maintenance${_ZC_NC}"
    echo -e "${_ZC_BOLD}═══════════════════════════════════════════════════════════${_ZC_NC}"
    echo ""

    echo -e "  ${_ZC_BLUE}1.${_ZC_NC} Cleaning up..."
    _zsh_clean_archive

    echo -e "  ${_ZC_BLUE}2.${_ZC_NC} Syncing to GitHub..."
    _zsh_clean_sync_internal

    echo ""
    echo -e "───────────────────────────────────────────────────────────"
    echo -e "  ${_ZC_GREEN}✓ Done!${_ZC_NC} Config is clean and backed up."
    echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# Undo: Discard uncommitted changes
# ─────────────────────────────────────────────────────────────────────────────
_zsh_clean_undo() {
    echo ""
    echo -e "${_ZC_BOLD}═══════════════════════════════════════════════════════════${_ZC_NC}"
    echo -e "${_ZC_BOLD}  ⏪ Undo Changes${_ZC_NC}"
    echo -e "${_ZC_BOLD}═══════════════════════════════════════════════════════════${_ZC_NC}"
    echo ""

    local real_dir=$(readlink -f "$ZSH_CONFIG_DIR" 2>/dev/null || echo "$ZSH_CONFIG_DIR")
    local git_dir=$(cd "$real_dir" && git rev-parse --show-toplevel 2>/dev/null)

    if [[ -z "$git_dir" ]]; then
        echo -e "  ${_ZC_YELLOW}✗${_ZC_NC} Not a git repository"
        return 1
    fi

    cd "$git_dir" || return 1

    if git diff --quiet zsh/ && git diff --cached --quiet zsh/; then
        echo -e "  ${_ZC_GREEN}✓${_ZC_NC} No uncommitted changes to undo"
        cd - > /dev/null
        return 0
    fi

    echo -e "  ${_ZC_YELLOW}Changes to discard:${_ZC_NC}"
    git status --short zsh/ | head -10 | while read line; do
        echo "    $line"
    done
    echo ""

    echo -n -e "  ${_ZC_RED}⚠${_ZC_NC}  Discard these changes? [y/N] "
    read -r confirm

    if [[ "$confirm" != [yY] ]]; then
        echo "  Cancelled."
        cd - > /dev/null
        return 0
    fi

    git checkout -- zsh/ 2>/dev/null
    git clean -fd zsh/ 2>/dev/null

    echo -e "  ${_ZC_GREEN}✓${_ZC_NC} Changes discarded"
    echo ""
    echo -e "  ${_ZC_DIM}Run 'source ~/.config/zsh/.zshrc' to reload${_ZC_NC}"

    cd - > /dev/null
    echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# Test: Run test suite
# ─────────────────────────────────────────────────────────────────────────────
_zsh_clean_test() {
    echo ""
    echo -e "${_ZC_BOLD}═══════════════════════════════════════════════════════════${_ZC_NC}"
    echo -e "${_ZC_BOLD}  🧪 Running Test Suite${_ZC_NC}"
    echo -e "${_ZC_BOLD}═══════════════════════════════════════════════════════════${_ZC_NC}"
    echo ""

    if [[ -f "$ZSH_CONFIG_DIR/tests/run-all-tests.zsh" ]]; then
        "$ZSH_CONFIG_DIR/tests/run-all-tests.zsh" --quick
    else
        echo -e "  ${_ZC_YELLOW}✗${_ZC_NC} Test suite not found"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN DISPATCHER
# ═══════════════════════════════════════════════════════════════════════════════

zsh-clean() {
    local cmd="${1:-}"
    shift 2>/dev/null

    # No args = do everything (ADHD-friendly)
    if [[ -z "$cmd" ]]; then
        _zsh_clean_full
        return
    fi

    case "$cmd" in
        status|s)
            _zsh_clean_status
            ;;
        undo|u)
            _zsh_clean_undo
            ;;
        test|t)
            _zsh_clean_test
            ;;
        help|-h|--help|h)
            _zsh_clean_help
            ;;
        *)
            echo "Unknown: $cmd"
            echo "Run 'zsh-clean help'"
            return 1
            ;;
    esac
}
