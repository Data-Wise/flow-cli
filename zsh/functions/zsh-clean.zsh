# ══════════════════════════════════════════════════════════════════════════════
# ZSH-CLEAN - ADHD-Friendly Maintenance for ZSH Configuration
# ══════════════════════════════════════════════════════════════════════════════
#
# PHILOSOPHY: Just type `zsh-clean` and everything gets done safely.
#
# Usage: zsh-clean [command]
#
# Commands:
#   (default)  Run full maintenance: snapshot + archive junk + status
#   status     Show configuration health summary only
#   snapshot   Create a backup snapshot only
#   list       List available snapshots
#   restore    Restore from a snapshot
#   test       Run the test suite
#   help       Show this help
#
# ══════════════════════════════════════════════════════════════════════════════

ZSH_CONFIG_DIR="${ZSH_CONFIG_DIR:-$HOME/.config/zsh}"
ZSH_ARCHIVE_DIR="$ZSH_CONFIG_DIR/.archive"
ZSH_BACKUPS_DIR="$ZSH_CONFIG_DIR/.backups"
ZSH_BACKUP_KEEP=3

# Colors
_ZC_GREEN='\033[32m'
_ZC_YELLOW='\033[33m'
_ZC_BLUE='\033[34m'
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
    (no args)  Full maintenance: snapshot → archive junk → show status
    status     Show configuration health summary only
    snapshot   Create a backup snapshot only
    list       List available snapshots
    restore    Restore from a snapshot
    sync       Commit and push to git remote (cloud backup)
    test       Run the test suite
    help       Show this help

PHILOSOPHY:
    Just type `zsh-clean` and forget about it.
    - Creates safety snapshot first (auto-prunes to keep 3)
    - Archives any junk files (.bak, .tmp, etc.)
    - Shows you the health status
    - Zero decisions required

EXAMPLES:
    zsh-clean              # Just do this! Does everything safely
    zsh-clean sync         # Push changes to GitHub
    zsh-clean sync "msg"   # Push with custom commit message
    zsh-clean list         # See your snapshots
    zsh-clean restore      # Undo changes (interactive picker)
EOF
}

# ─────────────────────────────────────────────────────────────────────────────
# Internal: Create snapshot (quiet mode available)
# ─────────────────────────────────────────────────────────────────────────────
_zsh_clean_snapshot_internal() {
    local quiet="${1:-false}"

    # Ensure backups directory exists
    [[ ! -d "$ZSH_BACKUPS_DIR" ]] && mkdir -p "$ZSH_BACKUPS_DIR"

    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_file="$ZSH_BACKUPS_DIR/zsh-$timestamp.tar.gz"

    # Create tarball excluding .archive, .backups, and cache files
    if tar -czf "$backup_file" \
        --exclude='.archive' \
        --exclude='.backups' \
        --exclude='.zcompdump*' \
        --exclude='.zsh_history' \
        --exclude='.zsh_sessions' \
        -C "$(dirname "$ZSH_CONFIG_DIR")" \
        "$(basename "$ZSH_CONFIG_DIR")" 2>/dev/null; then

        local size=$(du -h "$backup_file" | cut -f1)

        # Update latest symlink
        rm -f "$ZSH_BACKUPS_DIR/latest.tar.gz"
        ln -s "zsh-$timestamp.tar.gz" "$ZSH_BACKUPS_DIR/latest.tar.gz"

        # Prune old backups (keep last N)
        local backups=($(ls -t "$ZSH_BACKUPS_DIR"/zsh-*.tar.gz 2>/dev/null))
        local to_delete=$((${#backups[@]} - ZSH_BACKUP_KEEP))
        local pruned=0

        if [[ $to_delete -gt 0 ]]; then
            for ((i=${#backups[@]}-1; i>=${#backups[@]}-to_delete; i--)); do
                rm -f "${backups[$i]}"
                ((pruned++))
            done
        fi

        if [[ "$quiet" != "true" ]]; then
            echo -e "  ${_ZC_GREEN}✓${_ZC_NC} Snapshot: zsh-$timestamp.tar.gz ($size)"
            [[ $pruned -gt 0 ]] && echo -e "    ${_ZC_DIM}(pruned $pruned old snapshots)${_ZC_NC}"
        fi
        return 0
    else
        [[ "$quiet" != "true" ]] && echo -e "  ${_ZC_YELLOW}⚠${_ZC_NC} Failed to create snapshot"
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Internal: Archive junk files (quiet mode available)
# ─────────────────────────────────────────────────────────────────────────────
_zsh_clean_archive_internal() {
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
    \) ! -path "*/.archive/*" ! -path "*/.backups/*" -print0 2>/dev/null)

    if [[ "$quiet" != "true" ]]; then
        if [[ $count -gt 0 ]]; then
            echo -e "  ${_ZC_GREEN}✓${_ZC_NC} Archived: $count junk file(s)"
        else
            echo -e "  ${_ZC_GREEN}✓${_ZC_NC} No junk to archive"
        fi
    fi

    return 0
}

# ─────────────────────────────────────────────────────────────────────────────
# Internal: Compact status display
# ─────────────────────────────────────────────────────────────────────────────
_zsh_clean_status_compact() {
    # Count things
    local func_count=$(ls "$ZSH_CONFIG_DIR/functions/"*.zsh 2>/dev/null | wc -l | tr -d ' ')
    local snapshot_count=$(ls "$ZSH_BACKUPS_DIR"/zsh-*.tar.gz 2>/dev/null | wc -l | tr -d ' ')
    local archive_count=$(ls "$ZSH_ARCHIVE_DIR" 2>/dev/null | wc -l | tr -d ' ')
    local config_size=$(du -sh "$ZSH_CONFIG_DIR" 2>/dev/null | cut -f1)

    # Check junk
    local junk_count=$(find "$ZSH_CONFIG_DIR" -maxdepth 2 -type f \( \
        -name "*.bak" -o -name "*.bak[0-9]*" -o -name "*.backup*" -o \
        -name "*.tmp" -o -name "*.broken*" -o -name "*-backup-*" \
    \) ! -path "*/.archive/*" ! -path "*/.backups/*" 2>/dev/null | wc -l | tr -d ' ')

    echo ""
    echo -e "  ${_ZC_BOLD}Status:${_ZC_NC} $func_count functions │ $snapshot_count snapshots │ $archive_count archived │ $config_size"

    if [[ $junk_count -eq 0 ]]; then
        echo -e "  ${_ZC_GREEN}✓ Config is clean${_ZC_NC}"
    else
        echo -e "  ${_ZC_YELLOW}⚠ $junk_count junk file(s) remain${_ZC_NC}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# PUBLIC COMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

# ─────────────────────────────────────────────────────────────────────────────
# Default: Full maintenance (ADHD-friendly - just run it!)
# ─────────────────────────────────────────────────────────────────────────────
_zsh_clean_full() {
    echo ""
    echo -e "${_ZC_BOLD}═══════════════════════════════════════════════════════════${_ZC_NC}"
    echo -e "${_ZC_BOLD}  🧹 ZSH Config Maintenance${_ZC_NC}"
    echo -e "${_ZC_BOLD}═══════════════════════════════════════════════════════════${_ZC_NC}"
    echo ""

    # Step 1: Snapshot
    echo -e "  ${_ZC_BLUE}1.${_ZC_NC} Creating safety snapshot..."
    _zsh_clean_snapshot_internal false

    # Step 2: Archive junk
    echo -e "  ${_ZC_BLUE}2.${_ZC_NC} Archiving junk files..."
    _zsh_clean_archive_internal false

    # Step 3: Status
    echo -e "  ${_ZC_BLUE}3.${_ZC_NC} Checking health..."
    _zsh_clean_status_compact

    echo ""
    echo -e "───────────────────────────────────────────────────────────"
    echo -e "  ${_ZC_DIM}Done! Run 'zsh-clean list' to see snapshots${_ZC_NC}"
    echo -e "  ${_ZC_DIM}     or 'zsh-clean restore' to undo changes${_ZC_NC}"
    echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# Snapshot: Create backup only
# ─────────────────────────────────────────────────────────────────────────────
_zsh_clean_snapshot() {
    echo ""
    echo -e "${_ZC_BOLD}═══════════════════════════════════════════════════════════${_ZC_NC}"
    echo -e "${_ZC_BOLD}  📸 Creating Snapshot${_ZC_NC}"
    echo -e "${_ZC_BOLD}═══════════════════════════════════════════════════════════${_ZC_NC}"
    echo ""

    _zsh_clean_snapshot_internal false

    echo ""
    local total=$(ls "$ZSH_BACKUPS_DIR"/zsh-*.tar.gz 2>/dev/null | wc -l | tr -d ' ')
    local total_size=$(du -sh "$ZSH_BACKUPS_DIR" 2>/dev/null | cut -f1)
    echo -e "  Total: $total snapshots ($total_size)"
    echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# List: Show available snapshots
# ─────────────────────────────────────────────────────────────────────────────
_zsh_clean_list() {
    echo ""
    echo -e "${_ZC_BOLD}═══════════════════════════════════════════════════════════${_ZC_NC}"
    echo -e "${_ZC_BOLD}  📋 Available Snapshots${_ZC_NC}"
    echo -e "${_ZC_BOLD}═══════════════════════════════════════════════════════════${_ZC_NC}"
    echo ""

    if [[ ! -d "$ZSH_BACKUPS_DIR" ]]; then
        echo "  No snapshots yet. Run 'zsh-clean' to create one."
        echo ""
        return 0
    fi

    local backups=($(ls -t "$ZSH_BACKUPS_DIR"/zsh-*.tar.gz 2>/dev/null))

    if [[ ${#backups[@]} -eq 0 ]]; then
        echo "  No snapshots yet. Run 'zsh-clean' to create one."
        echo ""
        return 0
    fi

    local latest_target=""
    [[ -L "$ZSH_BACKUPS_DIR/latest.tar.gz" ]] && latest_target=$(readlink "$ZSH_BACKUPS_DIR/latest.tar.gz")

    for backup in "${backups[@]}"; do
        local name=$(basename "$backup")
        local size=$(du -h "$backup" | cut -f1)
        local date_part=${name#zsh-}
        date_part=${date_part%.tar.gz}

        # Parse timestamp
        local year=${date_part:0:4}
        local month=${date_part:4:2}
        local day=${date_part:6:2}
        local hour=${date_part:9:2}
        local min=${date_part:11:2}

        if [[ "$name" == "$latest_target" ]]; then
            echo -e "  ${_ZC_GREEN}●${_ZC_NC} $name ($size) ${_ZC_GREEN}← latest${_ZC_NC}"
        else
            echo -e "  ${_ZC_DIM}○${_ZC_NC} $name ($size)"
        fi
        echo -e "    ${_ZC_DIM}$year-$month-$day $hour:$min${_ZC_NC}"
    done

    echo ""
    echo -e "───────────────────────────────────────────────────────────"
    echo -e "  ${_ZC_DIM}Run 'zsh-clean restore' to restore${_ZC_NC}"
    echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# Restore: Restore from snapshot
# ─────────────────────────────────────────────────────────────────────────────
_zsh_clean_restore() {
    local target="${1:-}"

    echo ""
    echo -e "${_ZC_BOLD}═══════════════════════════════════════════════════════════${_ZC_NC}"
    echo -e "${_ZC_BOLD}  ⏪ Restore from Snapshot${_ZC_NC}"
    echo -e "${_ZC_BOLD}═══════════════════════════════════════════════════════════${_ZC_NC}"
    echo ""

    if [[ ! -d "$ZSH_BACKUPS_DIR" ]]; then
        echo -e "  ${_ZC_YELLOW}✗${_ZC_NC} No snapshots available"
        return 1
    fi

    local backup_file=""

    if [[ -z "$target" ]]; then
        # Interactive selection with fzf if available
        if command -v fzf &>/dev/null; then
            local selected=$(ls -t "$ZSH_BACKUPS_DIR"/zsh-*.tar.gz 2>/dev/null | xargs -n1 basename | fzf --prompt="  Select snapshot: " --height=10 --reverse)
            [[ -z "$selected" ]] && echo "  Cancelled." && return 0
            backup_file="$ZSH_BACKUPS_DIR/$selected"
        else
            # Fall back to latest
            if [[ -L "$ZSH_BACKUPS_DIR/latest.tar.gz" ]]; then
                backup_file="$ZSH_BACKUPS_DIR/$(readlink "$ZSH_BACKUPS_DIR/latest.tar.gz")"
                echo -e "  ${_ZC_DIM}Using latest (install fzf for picker)${_ZC_NC}"
                echo ""
            else
                echo -e "  ${_ZC_YELLOW}✗${_ZC_NC} No latest snapshot. Specify name."
                return 1
            fi
        fi
    elif [[ "$target" == "latest" ]]; then
        if [[ -L "$ZSH_BACKUPS_DIR/latest.tar.gz" ]]; then
            backup_file="$ZSH_BACKUPS_DIR/$(readlink "$ZSH_BACKUPS_DIR/latest.tar.gz")"
        else
            echo -e "  ${_ZC_YELLOW}✗${_ZC_NC} No latest snapshot"
            return 1
        fi
    else
        if [[ -f "$ZSH_BACKUPS_DIR/$target" ]]; then
            backup_file="$ZSH_BACKUPS_DIR/$target"
        elif [[ -f "$ZSH_BACKUPS_DIR/zsh-$target.tar.gz" ]]; then
            backup_file="$ZSH_BACKUPS_DIR/zsh-$target.tar.gz"
        else
            echo -e "  ${_ZC_YELLOW}✗${_ZC_NC} Not found: $target"
            return 1
        fi
    fi

    echo -e "  Selected: ${_ZC_BOLD}$(basename "$backup_file")${_ZC_NC}"
    echo ""
    echo -n -e "  ${_ZC_YELLOW}⚠${_ZC_NC}  Overwrite current config? [y/N] "
    read -r confirm

    if [[ "$confirm" != [yY] ]]; then
        echo "  Cancelled."
        return 0
    fi

    echo ""

    # Safety snapshot first
    echo -e "  Creating safety snapshot..."
    _zsh_clean_snapshot_internal true
    echo -e "  ${_ZC_GREEN}✓${_ZC_NC} Safety snapshot created"

    # Extract and restore
    local temp_dir=$(mktemp -d)
    if tar -xzf "$backup_file" -C "$temp_dir" 2>/dev/null; then
        rsync -a --exclude='.archive' --exclude='.backups' \
            "$temp_dir/zsh/" "$ZSH_CONFIG_DIR/"
        rm -rf "$temp_dir"
        echo -e "  ${_ZC_GREEN}✓${_ZC_NC} Restored from: $(basename "$backup_file")"
        echo ""
        echo -e "  ${_ZC_BOLD}Run:${_ZC_NC} source ~/.config/zsh/.zshrc"
    else
        rm -rf "$temp_dir"
        echo -e "  ${_ZC_YELLOW}✗${_ZC_NC} Failed to extract"
        return 1
    fi

    echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# Status: Health check only
# ─────────────────────────────────────────────────────────────────────────────
_zsh_clean_status() {
    echo ""
    echo -e "${_ZC_BOLD}═══════════════════════════════════════════════════════════${_ZC_NC}"
    echo -e "${_ZC_BOLD}  🩺 ZSH Configuration Health${_ZC_NC}"
    echo -e "${_ZC_BOLD}═══════════════════════════════════════════════════════════${_ZC_NC}"
    echo ""

    # Count junk files
    local junk_count=$(find "$ZSH_CONFIG_DIR" -maxdepth 2 -type f \( \
        -name "*.bak" -o -name "*.bak[0-9]*" -o -name "*.backup*" -o \
        -name "*.tmp" -o -name "*.broken*" -o -name "*-backup-*" \
    \) ! -path "*/.archive/*" ! -path "*/.backups/*" 2>/dev/null | wc -l | tr -d ' ')

    local func_count=$(ls "$ZSH_CONFIG_DIR/functions/"*.zsh 2>/dev/null | wc -l | tr -d ' ')

    local snapshot_count=0 snapshot_size="0K"
    if [[ -d "$ZSH_BACKUPS_DIR" ]]; then
        snapshot_count=$(ls "$ZSH_BACKUPS_DIR"/zsh-*.tar.gz 2>/dev/null | wc -l | tr -d ' ')
        snapshot_size=$(du -sh "$ZSH_BACKUPS_DIR" 2>/dev/null | cut -f1)
    fi

    local archive_count=0 archive_size="0K"
    if [[ -d "$ZSH_ARCHIVE_DIR" ]]; then
        archive_count=$(ls "$ZSH_ARCHIVE_DIR" 2>/dev/null | wc -l | tr -d ' ')
        archive_size=$(du -sh "$ZSH_ARCHIVE_DIR" 2>/dev/null | cut -f1)
    fi

    local config_size=$(du -sh "$ZSH_CONFIG_DIR" 2>/dev/null | cut -f1)

    echo -e "  📁 ${_ZC_DIM}Config:${_ZC_NC} $ZSH_CONFIG_DIR ($config_size)"
    echo ""
    echo -e "  ├─ Functions:  $func_count files"
    echo -e "  ├─ Snapshots:  $snapshot_count ($snapshot_size)"
    echo -e "  ├─ Archived:   $archive_count ($archive_size)"

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

# ─────────────────────────────────────────────────────────────────────────────
# Sync: Commit and push to git remote
# ─────────────────────────────────────────────────────────────────────────────
_zsh_clean_sync() {
    local msg="${1:-zsh config update}"

    echo ""
    echo -e "${_ZC_BOLD}═══════════════════════════════════════════════════════════${_ZC_NC}"
    echo -e "${_ZC_BOLD}  ☁️  Sync to Remote${_ZC_NC}"
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
        echo -e "  ${_ZC_GREEN}✓${_ZC_NC} Pushed to remote"
    else
        echo -e "  ${_ZC_YELLOW}⚠${_ZC_NC} Push failed (check remote)"
    fi

    cd - > /dev/null
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN DISPATCHER
# ═══════════════════════════════════════════════════════════════════════════════

zsh-clean() {
    local cmd="${1:-}"
    shift 2>/dev/null

    # No args = full maintenance (ADHD-friendly default)
    if [[ -z "$cmd" ]]; then
        _zsh_clean_full
        return
    fi

    case "$cmd" in
        status|health|s)
            _zsh_clean_status
            ;;
        snapshot|snap|backup)
            _zsh_clean_snapshot
            ;;
        list|ls|l)
            _zsh_clean_list
            ;;
        restore|r)
            _zsh_clean_restore "$@"
            ;;
        sync|push|p)
            _zsh_clean_sync "$@"
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
