#!/usr/bin/env zsh
# ═══════════════════════════════════════════════════════════════════════════
# ZSH Functions Reorganization Script
# ═══════════════════════════════════════════════════════════════════════════
#
# Purpose: Reorganize flat ZSH functions into modular directory structure
# Agent: Agent 4 (File Organizer)
# Date: 2025-12-19
#
# Usage:
#   ./scripts/reorganize-functions.sh [--dry-run] [--phase N]
#
# Options:
#   --dry-run     Show what would be done without making changes
#   --phase N     Execute only phase N (1-7)
#
# ═══════════════════════════════════════════════════════════════════════════

set -e  # Exit on error

# ═══════════════════════════════════════════════════════════════════════════
# Configuration
# ═══════════════════════════════════════════════════════════════════════════

FUNCTIONS_DIR="$HOME/.config/zsh/functions"
DISPATCHERS_DIR="$FUNCTIONS_DIR/dispatchers"
HELPERS_DIR="$FUNCTIONS_DIR/helpers"
BACKUP_DIR="$HOME/.config/zsh/functions_backup_$(date +%Y%m%d_%H%M%S)"

DRY_RUN=0
PHASE=""

# ═══════════════════════════════════════════════════════════════════════════
# Parse Arguments
# ═══════════════════════════════════════════════════════════════════════════

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --phase)
            PHASE="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# ═══════════════════════════════════════════════════════════════════════════
# Helper Functions
# ═══════════════════════════════════════════════════════════════════════════

log() {
    echo "[$(date +%H:%M:%S)] $*"
}

execute() {
    if [[ $DRY_RUN -eq 1 ]]; then
        echo "[DRY-RUN] $*"
    else
        log "$*"
        eval "$*"
    fi
}

should_run_phase() {
    local phase_num="$1"
    if [[ -z "$PHASE" ]] || [[ "$PHASE" == "$phase_num" ]]; then
        return 0
    fi
    return 1
}

# ═══════════════════════════════════════════════════════════════════════════
# Phase 1: Backup
# ═══════════════════════════════════════════════════════════════════════════

phase1_backup() {
    log "═══════════════════════════════════════════════════════════════"
    log "Phase 1: Creating backup"
    log "═══════════════════════════════════════════════════════════════"

    execute "mkdir -p '$BACKUP_DIR'"
    execute "cp -r '$FUNCTIONS_DIR'/* '$BACKUP_DIR/'

    log "✓ Backup created at: $BACKUP_DIR"
}

# ═══════════════════════════════════════════════════════════════════════════
# Phase 2: Create Directory Structure
# ═══════════════════════════════════════════════════════════════════════════

phase2_create_dirs() {
    log "═══════════════════════════════════════════════════════════════"
    log "Phase 2: Creating directory structure"
    log "═══════════════════════════════════════════════════════════════"

    execute "mkdir -p '$DISPATCHERS_DIR'"
    execute "mkdir -p '$HELPERS_DIR'"

    log "✓ Created $DISPATCHERS_DIR"
    log "✓ Created $HELPERS_DIR"
}

# ═══════════════════════════════════════════════════════════════════════════
# Phase 3: Create Color Definitions
# ═══════════════════════════════════════════════════════════════════════════

phase3_create_colors() {
    log "═══════════════════════════════════════════════════════════════"
    log "Phase 3: Creating shared color definitions"
    log "═══════════════════════════════════════════════════════════════"

    local colors_file="$DISPATCHERS_DIR/00-colors.zsh"

    if [[ $DRY_RUN -eq 1 ]]; then
        log "[DRY-RUN] Would create $colors_file"
        return
    fi

    cat > "$colors_file" << 'EOF'
# ═══════════════════════════════════════════════════════════════════════════
# Shared Color Definitions for All Dispatchers
# ═══════════════════════════════════════════════════════════════════════════
# Sourced first (00- prefix) to ensure colors are available to all dispatchers

# Respect NO_COLOR environment variable
if [[ -z "${NO_COLOR}" ]] && [[ -t 1 ]]; then
    # Section headers and emphasis
    _C_GREEN='\033[0;32m'      # Headers, success
    _C_CYAN='\033[0;36m'       # Commands, actions
    _C_YELLOW='\033[1;33m'     # Examples, warnings
    _C_MAGENTA='\033[0;35m'    # Related, references
    _C_BLUE='\033[0;34m'       # Info, notes
    _C_BOLD='\033[1m'          # Bold text
    _C_DIM='\033[2m'           # Dimmed text
    _C_NC='\033[0m'            # No color (reset)
else
    # No colors (respect NO_COLOR or non-TTY)
    _C_GREEN=''
    _C_CYAN=''
    _C_YELLOW=''
    _C_MAGENTA=''
    _C_BLUE=''
    _C_BOLD=''
    _C_DIM=''
    _C_NC=''
fi
EOF

    log "✓ Created $colors_file"
}

# ═══════════════════════════════════════════════════════════════════════════
# Phase 4: Extract Dispatchers from smart-dispatchers.zsh
# ═══════════════════════════════════════════════════════════════════════════

phase4_extract_dispatchers() {
    log "═══════════════════════════════════════════════════════════════"
    log "Phase 4: Extracting dispatchers from smart-dispatchers.zsh"
    log "═══════════════════════════════════════════════════════════════"

    local source_file="$FUNCTIONS_DIR/smart-dispatchers.zsh"

    # Extract r dispatcher (lines 37-168)
    extract_to_file "$source_file" 37 168 "$DISPATCHERS_DIR/r-dispatcher.zsh" "r()"

    # Extract qu dispatcher (lines 170-240)
    extract_to_file "$source_file" 170 240 "$DISPATCHERS_DIR/quarto-dispatcher.zsh" "qu()"

    # Extract cc dispatcher (lines 242-360)
    extract_to_file "$source_file" 242 360 "$DISPATCHERS_DIR/claude-dispatcher.zsh" "cc()"

    # Extract gm dispatcher (lines 362-462)
    extract_to_file "$source_file" 362 462 "$DISPATCHERS_DIR/gemini-dispatcher.zsh" "gm()"

    # Extract note dispatcher (lines 551-620)
    extract_to_file "$source_file" 551 620 "$DISPATCHERS_DIR/note-dispatcher.zsh" "note()"

    # Extract workflow dispatcher (lines 807-874)
    extract_to_file "$source_file" 807 874 "$DISPATCHERS_DIR/workflow-dispatcher.zsh" "workflow()"
}

extract_to_file() {
    local source="$1"
    local start="$2"
    local end="$3"
    local target="$4"
    local func_name="$5"

    log "  Extracting $func_name (lines $start-$end) → $target"

    if [[ $DRY_RUN -eq 1 ]]; then
        return
    fi

    # Add header
    cat > "$target" << EOF
# ═══════════════════════════════════════════════════════════════════════════
# $(basename "$target" .zsh | tr '[:lower:]' '[:upper:]') - Extracted from smart-dispatchers.zsh
# ═══════════════════════════════════════════════════════════════════════════
# Generated: $(date +%Y-%m-%d)
# Function: $func_name

EOF

    # Extract lines
    sed -n "${start},${end}p" "$source" >> "$target"

    log "    ✓ Created $target"
}

# ═══════════════════════════════════════════════════════════════════════════
# Phase 5: Move Existing Dispatchers
# ═══════════════════════════════════════════════════════════════════════════

phase5_move_dispatchers() {
    log "═══════════════════════════════════════════════════════════════"
    log "Phase 5: Moving existing dispatcher files"
    log "═══════════════════════════════════════════════════════════════"

    # Move git dispatcher
    if [[ -f "$FUNCTIONS_DIR/g-dispatcher.zsh" ]]; then
        execute "mv '$FUNCTIONS_DIR/g-dispatcher.zsh' '$DISPATCHERS_DIR/git-dispatcher.zsh'"
        log "  ✓ Moved g-dispatcher.zsh → git-dispatcher.zsh"
    fi

    # Move vibe dispatcher
    if [[ -f "$FUNCTIONS_DIR/v-dispatcher.zsh" ]]; then
        execute "mv '$FUNCTIONS_DIR/v-dispatcher.zsh' '$DISPATCHERS_DIR/vibe-dispatcher.zsh'"
        log "  ✓ Moved v-dispatcher.zsh → vibe-dispatcher.zsh"
    fi

    # Move MCP dispatcher
    if [[ -f "$FUNCTIONS_DIR/mcp-dispatcher.zsh" ]]; then
        execute "mv '$FUNCTIONS_DIR/mcp-dispatcher.zsh' '$DISPATCHERS_DIR/mcp-dispatcher.zsh'"
        log "  ✓ Moved mcp-dispatcher.zsh"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# Phase 6: Extract pick() from adhd-helpers.zsh
# ═══════════════════════════════════════════════════════════════════════════

phase6_extract_pick() {
    log "═══════════════════════════════════════════════════════════════"
    log "Phase 6: Extracting pick() dispatcher from adhd-helpers.zsh"
    log "═══════════════════════════════════════════════════════════════"

    local source_file="$FUNCTIONS_DIR/adhd-helpers.zsh"
    local target_file="$DISPATCHERS_DIR/pick-dispatcher.zsh"

    log "  WARNING: pick() depends on project detection helpers"
    log "  Make sure helpers/project-detection.zsh is sourced first"

    extract_to_file "$source_file" 1875 2073 "$target_file" "pick()"
}

# ═══════════════════════════════════════════════════════════════════════════
# Phase 7: Create dispatchers README
# ═══════════════════════════════════════════════════════════════════════════

phase7_create_readme() {
    log "═══════════════════════════════════════════════════════════════"
    log "Phase 7: Creating dispatchers README"
    log "═══════════════════════════════════════════════════════════════"

    local readme="$DISPATCHERS_DIR/README.md"

    if [[ $DRY_RUN -eq 1 ]]; then
        log "[DRY-RUN] Would create $readme"
        return
    fi

    cat > "$readme" << 'EOF'
# ZSH Function Dispatchers

This directory contains all ZSH function dispatchers - single-letter or short commands that dispatch to various sub-commands.

## Dispatcher Index

### Development Tools

| Command | File | Description | Common Keywords |
|---------|------|-------------|-----------------|
| `r` | r-dispatcher.zsh | R package development | load, test, doc, check, cycle |
| `qu` | quarto-dispatcher.zsh | Quarto publishing | preview, render, clean |
| `cc` | claude-dispatcher.zsh | Claude Code CLI | continue, plan, auto, yolo |
| `gm` | gemini-dispatcher.zsh | Gemini CLI | yolo, web, resume |

### Project Management

| Command | File | Description | Common Keywords |
|---------|------|-------------|-----------------|
| `pick` | pick-dispatcher.zsh | Interactive project picker | r, dev, q, teach, rs, app |
| `g` | git-dispatcher.zsh | Git operations | status, commit, push, pull |

### Workflow & Energy

| Command | File | Description | Common Keywords |
|---------|------|-------------|-----------------|
| `v` | vibe-dispatcher.zsh | Energy & vibe management | check, log, boost |
| `timer` | timer-dispatcher.zsh | Focus timer | 15, 25, 50, 90, check, stop |

### Integrations

| Command | File | Description | Common Keywords |
|---------|------|-------------|-----------------|
| `mcp` | mcp-dispatcher.zsh | MCP server management | list, status, restart |
| `note` | note-dispatcher.zsh | Apple Notes sync | sync, view, status |
| `workflow` | workflow-dispatcher.zsh | Activity logging | today, week, started, finished |

## Usage Pattern

All dispatchers follow a consistent pattern:

```bash
command [action] [args]
```

**Examples:**
```bash
r test              # Run R package tests
qu preview          # Preview Quarto document
cc plan "task"      # Claude Code in plan mode
pick r              # Pick from R packages
g status            # Git status (enhanced)
```

## Help System

Every dispatcher supports `help`:

```bash
r help
qu help
cc help
pick --help
```

## Color Support

All dispatchers use shared color definitions from `00-colors.zsh`.

---

Generated: $(date +%Y-%m-%d)
EOF

    log "✓ Created $readme"
}

# ═══════════════════════════════════════════════════════════════════════════
# Main Execution
# ═══════════════════════════════════════════════════════════════════════════

main() {
    log "═══════════════════════════════════════════════════════════════"
    log "ZSH Functions Reorganization"
    log "═══════════════════════════════════════════════════════════════"

    if [[ $DRY_RUN -eq 1 ]]; then
        log "DRY-RUN MODE: No changes will be made"
    fi

    if [[ -n "$PHASE" ]]; then
        log "Running only Phase $PHASE"
    fi

    # Execute phases
    should_run_phase 1 && phase1_backup
    should_run_phase 2 && phase2_create_dirs
    should_run_phase 3 && phase3_create_colors
    should_run_phase 4 && phase4_extract_dispatchers
    should_run_phase 5 && phase5_move_dispatchers
    should_run_phase 6 && phase6_extract_pick
    should_run_phase 7 && phase7_create_readme

    log "═══════════════════════════════════════════════════════════════"
    log "✓ Reorganization complete!"
    log "═══════════════════════════════════════════════════════════════"

    if [[ $DRY_RUN -eq 0 ]]; then
        log ""
        log "Next steps:"
        log "  1. Update ~/.config/zsh/.zshrc to source new structure"
        log "  2. Test in new shell: zsh"
        log "  3. Verify functions: r help, qu help, pick --help"
        log "  4. If issues, restore from: $BACKUP_DIR"
        log ""
        log "NOTE: Helper extraction (Phase 8+) requires manual work"
        log "See: ADHD-HELPERS-FUNCTION-MAP.md for details"
    fi
}

main
