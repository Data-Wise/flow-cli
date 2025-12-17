# ══════════════════════════════════════════════════════════════════════════════
# ZSH-CLEAN - ADHD-Friendly Maintenance for ZSH Configuration
# ══════════════════════════════════════════════════════════════════════════════
#
# PHILOSOPHY: Simple. Git + Google Drive handle backups.
#
# Usage: zsh-clean [command]
#
# Commands:
#   (default)  Archive junk files + show status
#   sync       Commit and push to GitHub
#   undo       Discard uncommitted changes
#   status     Show health summary
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
    zsh-clean              # Archive junk + show status
    zsh-clean [command]    # Run specific command

COMMANDS:
    (no args)  Archive junk files + show status
    sync       Commit and push to GitHub
    undo       Discard uncommitted changes (git checkout)
    status     Show health summary only
    test       Run test suite
    help       Show this help

BACKUP STRATEGY:
    • GitHub: Full version history (zsh-clean sync)
    • Google Drive: Auto-syncs ~/projects/ in real-time
    • No local tarballs needed - two cloud backups are enough!

RECOVERY:
    zsh-clean undo         # Discard recent changes
    git log --oneline      # See history
    git checkout <hash>    # Restore specific version

EXAMPLES:
    zsh-clean              # Quick cleanup + status
    zsh-clean sync         # Push changes to GitHub
    zsh-clean sync "msg"   # Push with custom message
    zsh-clean undo         # Oops, revert changes
EOF
}

# ─────────────────────────────────────────────────────────────────────────────
# Archive junk files
# ─────────────────────────────────────────────────────────────────────────────
_zsh_clean_archive() {
    local quiet="${1:-false}"

    # Ensure archive directory exists
    [[ ! -d "$ZSH_ARCHIVE_DIR" ]] && mkdir -p "$ZSH_ARCHIVE_DIR"

    local count=0

    # Find and move junk files
    while IFS= read -r -d '' file; do
        local basename=$(basename "$file")

        # Handle name conflicts
        local target="$ZSH_ARCHIVE_DIR/$basename"
        if [[ -f "$target" ]]; then
            local ts=$(date +%Y%m%d-%H%M%S)
            target="$ZSH_ARCHIVE_DIR/${basename%.zsh*}-$ts${basename#*.zsh}"
        fi

        mv "$file" "$target" 2>/dev/null && ((count++))
    done < <(find "$ZSH_CONFIG_DIR" -maxdepth 2 -type f \( \
        -name "*.bak" -o \
        -name "*.bak[0-9]*" -o \
        -name "*.backup*" -o \
        -name "*.tmp" -o \
        -name "*.broken*" -o \
        -name "*-backup-*" \
    \) ! -path "*/.archive/*" -print0 2>/dev/null)

    if [[ "$quiet" != "true" ]]; then
        if [[ $count -gt 0 ]]; then
            echo -e "  ${_ZC_GREEN}✓${_ZC_NC} Archived $count junk file(s)"
        else
            echo -e "  ${_ZC_GREEN}✓${_ZC_NC} No junk to archive"
        fi
    fi

    return 0
}

# ─────────────────────────────────────────────────────────────────────────────
# Status display
# ─────────────────────────────────────────────────────────────────────────────
_zsh_clean_status() {
    local compact="${1:-false}"

    if [[ "$compact" != "true" ]]; then
        echo ""
        echo -e "${_ZC_BOLD}═══════════════════════════════════════════════════════════${_ZC_NC}"
        echo -e "${_ZC_BOLD}  🩺 ZSH Configuration Health${_ZC_NC}"
        echo -e "${_ZC_BOLD}═══════════════════════════════════════════════════════════${_ZC_NC}"
        echo ""
    fi

    # Count junk files
    local junk_count=$(find "$ZSH_CONFIG_DIR" -maxdepth 2 -type f \( \
        -name "*.bak" -o -name "*.bak[0-9]*" -o -name "*.backup*" -o \
        -name "*.tmp" -o -name "*.broken*" -o -name "*-backup-*" \
    \) ! -path "*/.archive/*" 2>/dev/null | wc -l | tr -d ' ')

    local func_count=$(ls "$ZSH_CONFIG_DIR/functions/"*.zsh 2>/dev/null | wc -l | tr -d ' ')

    local archive_count=0 archive_size="0K"
    if [[ -d "$ZSH_ARCHIVE_DIR" ]]; then
        archive_count=$(ls "$ZSH_ARCHIVE_DIR" 2>/dev/null | wc -l | tr -d ' ')
        archive_size=$(du -sh "$ZSH_ARCHIVE_DIR" 2>/dev/null | cut -f1)
    fi

    local config_size=$(du -sh "$ZSH_CONFIG_DIR" 2>/dev/null | cut -f1)

    # Check git status
    local real_dir=$(readlink -f "$ZSH_CONFIG_DIR" 2>/dev/null || echo "$ZSH_CONFIG_DIR")
    local git_status="not a repo"
    local git_dirty=""
    if cd "$real_dir" && git rev-parse --git-dir &>/dev/null; then
        if git diff --quiet && git diff --cached --quiet && [[ -z $(git ls-files --others --exclude-standard) ]]; then
            git_status="${_ZC_GREEN}clean${_ZC_NC}"
        else
            git_status="${_ZC_YELLOW}uncommitted changes${_ZC_NC}"
            git_dirty="true"
        fi
    fi
    cd - > /dev/null 2>&1

    if [[ "$compact" == "true" ]]; then
        echo ""
        echo -e "  ${_ZC_BOLD}Status:${_ZC_NC} $func_count functions │ $archive_count archived │ $config_size"
        if [[ $junk_count -eq 0 ]]; then
            echo -e "  ${_ZC_GREEN}✓ Clean${_ZC_NC} │ Git: $git_status"
        else
            echo -e "  ${_ZC_YELLOW}⚠ $junk_count junk file(s)${_ZC_NC} │ Git: $git_status"
        fi
    else
        echo -e "  📁 ${_ZC_DIM}Config:${_ZC_NC} $ZSH_CONFIG_DIR ($config_size)"
        echo ""
        echo -e "  ├─ Functions:  $func_count files"
        echo -e "  ├─ Archived:   $archive_count ($archive_size)"
        echo -e "  ├─ Git:        $git_status"

        if [[ $junk_count -eq 0 ]]; then
            echo -e "  └─ Junk:       ${_ZC_GREEN}✓ None${_ZC_NC}"
        else
            echo -e "  └─ Junk:       ${_ZC_YELLOW}⚠ $junk_count file(s)${_ZC_NC}"
        fi

        echo ""
        echo -e "  ${_ZC_BOLD}Dispatchers:${_ZC_NC}"
        local disp_line="  "
        for cmd in r g qu v cc gm; do
            if type "$cmd" &>/dev/null; then
                disp_line+="${_ZC_GREEN}$cmd${_ZC_NC} "
            else
                disp_line+="${_ZC_DIM}$cmd${_ZC_NC} "
            fi
        done
        echo -e "$disp_line"

        if [[ -n "$git_dirty" ]]; then
            echo ""
            echo -e "  ${_ZC_DIM}Tip: Run 'zsh-clean sync' to push changes${_ZC_NC}"
        fi
    fi

    echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# Default: Archive + Status (ADHD-friendly)
# ─────────────────────────────────────────────────────────────────────────────
_zsh_clean_full() {
    echo ""
    echo -e "${_ZC_BOLD}═══════════════════════════════════════════════════════════${_ZC_NC}"
    echo -e "${_ZC_BOLD}  🧹 ZSH Config Maintenance${_ZC_NC}"
    echo -e "${_ZC_BOLD}═══════════════════════════════════════════════════════════${_ZC_NC}"
    echo ""

    # Step 1: Archive junk
    echo -e "  ${_ZC_BLUE}1.${_ZC_NC} Archiving junk files..."
    _zsh_clean_archive false

    # Step 2: Status
    echo -e "  ${_ZC_BLUE}2.${_ZC_NC} Checking health..."
    _zsh_clean_status true

    echo -e "───────────────────────────────────────────────────────────"
    echo -e "  ${_ZC_DIM}Run 'zsh-clean sync' to push to GitHub${_ZC_NC}"
    echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# Sync: Commit and push to git remote
# ─────────────────────────────────────────────────────────────────────────────
_zsh_clean_sync() {
    local msg="${1:-zsh config update}"

    echo ""
    echo -e "${_ZC_BOLD}═══════════════════════════════════════════════════════════${_ZC_NC}"
    echo -e "${_ZC_BOLD}  ☁️  Sync to GitHub${_ZC_NC}"
    echo -e "${_ZC_BOLD}═══════════════════════════════════════════════════════════${_ZC_NC}"
    echo ""

    # Check if we're in a git repo (follow symlink)
    local real_dir=$(readlink -f "$ZSH_CONFIG_DIR" 2>/dev/null || echo "$ZSH_CONFIG_DIR")
    local git_dir=$(cd "$real_dir" && git rev-parse --show-toplevel 2>/dev/null)

    if [[ -z "$git_dir" ]]; then
        echo -e "  ${_ZC_YELLOW}✗${_ZC_NC} Not a git repository"
        echo -e "  ${_ZC_DIM}Config dir: $real_dir${_ZC_NC}"
        return 1
    fi

    echo -e "  ${_ZC_DIM}Repo: $git_dir${_ZC_NC}"
    echo ""

    # Change to git root
    cd "$git_dir" || return 1

    # Check for changes
    if git diff --quiet && git diff --cached --quiet && [[ -z $(git ls-files --others --exclude-standard) ]]; then
        echo -e "  ${_ZC_GREEN}✓${_ZC_NC} Already up to date - nothing to sync"
        cd - > /dev/null
        return 0
    fi

    # Show what will be committed
    echo -e "  ${_ZC_BLUE}Changes:${_ZC_NC}"
    git status --short | head -10 | while read line; do
        echo "    $line"
    done
    local total=$(git status --short | wc -l | tr -d ' ')
    [[ $total -gt 10 ]] && echo -e "    ${_ZC_DIM}... and $((total - 10)) more${_ZC_NC}"
    echo ""

    # Stage all changes in zsh/ directory
    git add zsh/

    # Commit
    if git commit -m "$msg

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>" 2>/dev/null; then
        echo -e "  ${_ZC_GREEN}✓${_ZC_NC} Committed: $msg"
    else
        echo -e "  ${_ZC_YELLOW}⚠${_ZC_NC} Nothing to commit"
    fi

    # Push
    echo -e "  ${_ZC_DIM}Pushing to remote...${_ZC_NC}"
    if git push 2>/dev/null; then
        echo -e "  ${_ZC_GREEN}✓${_ZC_NC} Pushed to GitHub"
    else
        echo -e "  ${_ZC_YELLOW}⚠${_ZC_NC} Push failed (check remote)"
    fi

    cd - > /dev/null
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

    # Check if there are changes
    if git diff --quiet && git diff --cached --quiet; then
        echo -e "  ${_ZC_GREEN}✓${_ZC_NC} No uncommitted changes to undo"
        cd - > /dev/null
        return 0
    fi

    # Show what will be undone
    echo -e "  ${_ZC_YELLOW}Changes to discard:${_ZC_NC}"
    git status --short zsh/ | head -10 | while read line; do
        echo "    $line"
    done
    echo ""

    # Confirm
    echo -n -e "  ${_ZC_RED}⚠${_ZC_NC}  Discard these changes? [y/N] "
    read -r confirm

    if [[ "$confirm" != [yY] ]]; then
        echo "  Cancelled."
        cd - > /dev/null
        return 0
    fi

    # Undo changes
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

    # No args = archive + status (ADHD-friendly default)
    if [[ -z "$cmd" ]]; then
        _zsh_clean_full
        return
    fi

    case "$cmd" in
        status|health|s)
            _zsh_clean_status
            ;;
        sync|push|p)
            _zsh_clean_sync "$@"
            ;;
        undo|revert|u)
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

# Backward compatibility
alias zsh-cleanup='zsh-clean'
