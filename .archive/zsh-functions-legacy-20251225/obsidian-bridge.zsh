#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# OBSIDIAN BRIDGE - Cross-Editor Handoffs & Project Sync
# ══════════════════════════════════════════════════════════════════════════════
#
# File:         ~/.config/zsh/functions/obsidian-bridge.zsh
# Version:      1.0
# Date:         2025-12-14
# Part of:      Option B+ Multi-Editor Quadrant System (Week 3)
#
# Usage:        obs-sync, obs-open, obs-project-sync
#
# ══════════════════════════════════════════════════════════════════════════════

# Configuration
OBS_ROOT="${OBS_ROOT:-/Users/dt/Library/Mobile Documents/iCloud~md~obsidian/Documents}"
RESEARCH_LAB="$OBS_ROOT/Research_Lab"
KNOWLEDGE_BASE="$OBS_ROOT/Knowledge_Base"
LIFE_ADMIN="$OBS_ROOT/Life_Admin"

# ═══════════════════════════════════════════════════════════════════
# 1. VAULT NAVIGATION
# ═══════════════════════════════════════════════════════════════════

# Open Obsidian to a specific vault
obs-open() {
    local vault="${1:-Research_Lab}"
    local note="$2"
    
    case "$vault" in
        research|Research_Lab|rl)
            vault="Research_Lab"
            ;;
        knowledge|Knowledge_Base|kb)
            vault="Knowledge_Base"
            ;;
        life|Life_Admin|la)
            vault="Life_Admin"
            ;;
    esac
    
    if [[ -n "$note" ]]; then
        # Open specific note
        local note_path="$OBS_ROOT/$vault/$note"
        if [[ -f "$note_path" ]] || [[ -f "${note_path}.md" ]]; then
            open "obsidian://open?vault=$vault&file=$note"
        else
            echo "❌ Note not found: $note_path"
            return 1
        fi
    else
        # Just open vault
        open "obsidian://open?vault=$vault"
    fi
    
    echo "📓 Opened Obsidian: $vault${note:+ → $note}"
}

# Quick vault shortcuts
obs-research() { obs-open Research_Lab "$1"; }
obs-knowledge() { obs-open Knowledge_Base "$1"; }
obs-life() { obs-open Life_Admin "$1"; }

# ═══════════════════════════════════════════════════════════════════
# 2. PROJECT SYNC - Terminal → Obsidian
# ═══════════════════════════════════════════════════════════════════

# Sync .STATUS files to Obsidian dashboard
obs-project-sync() {
    echo ""
    echo "┌─────────────────────────────────────────────────────────┐"
    echo "│ 📓 OBSIDIAN PROJECT SYNC                               │"
    echo "└─────────────────────────────────────────────────────────┘"
    echo ""
    
    local dashboard="$RESEARCH_LAB/MediationVerse_Dashboard.md"
    local auto_update="${1:-no}"  # Pass 'auto' to auto-update
    
    # Collect status from all packages
    echo "🔍 Scanning .STATUS files..."
    echo ""
    
    local status_table="| Package | Priority | Status | Progress | Next Action |\n|---------|----------|--------|----------|-------------|\n"
    
    for status_file in ~/projects/r-packages/active/*/.STATUS; do
        if [[ -f "$status_file" ]]; then
            local pkg_dir=$(dirname "$status_file")
            local pkg_name=$(basename "$pkg_dir")
            local priority=$(grep "^priority:" "$status_file" 2>/dev/null | cut -d: -f2 | tr -d ' ')
            local pkg_status=$(grep "^status:" "$status_file" 2>/dev/null | cut -d: -f2 | tr -d ' ')
            local progress=$(grep "^progress:" "$status_file" 2>/dev/null | cut -d: -f2 | tr -d ' ')
            local next=$(grep "^next:" "$status_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' | head -c 40)
            
            # Priority emoji
            local p_emoji="🔵"
            case "$priority" in
                P0) p_emoji="🔴" ;;
                P1) p_emoji="🟡" ;;
                P2) p_emoji="🟢" ;;
            esac
            
            status_table+="| [[$pkg_name]] | $p_emoji $priority | $pkg_status | ${progress}% | $next |\n"
            echo "   ✓ $pkg_name: $priority/$pkg_status (${progress}%)"
        fi
    done
    
    # Add RMediation (stable)
    status_table+="| [[RMediation]] | ✅ | CRAN | 100% | Stable v1.4.0 |\n"
    
    echo ""
    echo "📝 Status table generated"
    echo ""
    
    # Update dashboard if it exists
    if [[ -f "$dashboard" ]]; then
        if [[ "$auto_update" == "auto" ]] || [[ "$auto_update" == "-a" ]]; then
            # Auto-update the dashboard
            echo "🔄 Auto-updating dashboard..."
            
            # Write table to temp file first (avoids awk newline issues)
            local table_file="/tmp/obs-table-$.md"
            local temp_file="/tmp/obs-dashboard-$.md"
            echo -e "$status_table" > "$table_file"
            
            # Process: copy header, skip old table, insert new table
            local in_table=0
            local table_inserted=0
            while IFS= read -r line; do
                if [[ "$line" == "## 🎯 Quick Status" ]]; then
                    echo "$line"
                    echo ""
                    cat "$table_file"
                    in_table=1
                    table_inserted=1
                elif [[ $in_table -eq 1 ]]; then
                    # Skip old table lines (start with |)
                    if [[ "$line" != "|"* && -n "$line" ]]; then
                        in_table=0
                        echo ""
                        echo "$line"
                    fi
                else
                    echo "$line"
                fi
            done < "$dashboard" > "$temp_file"
            
            # Update timestamp
            sed -i '' "s/^\*Last updated:.*/\*Last updated: $(date +%Y-%m-%d)\*/" "$temp_file"
            
            mv "$temp_file" "$dashboard"
            rm -f "$table_file"
            echo "✅ Dashboard updated!"
        else
            echo "📓 Dashboard location: $dashboard"
            echo ""
            echo "💡 To auto-update, run: ops -a"
            echo ""
            echo "Or manually replace the Quick Status table with:"
            echo ""
            echo -e "$status_table"
        fi
    else
        echo "⚠️  Dashboard not found at: $dashboard"
        echo "   Create it with: obs-create-dashboard"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# 3. CROSS-EDITOR HANDOFFS
# ═══════════════════════════════════════════════════════════════════

# From Obsidian → Terminal (open project)
obs-to-terminal() {
    local project="$1"
    
    if [[ -z "$project" ]]; then
        echo "Usage: obs-to-terminal <project>"
        echo "Opens project in terminal with context"
        return 1
    fi
    
    # Find project
    local project_dir=""
    for base in ~/projects/r-packages/active ~/projects/dev-tools ~/projects/research; do
        if [[ -d "$base/$project" ]]; then
            project_dir="$base/$project"
            break
        fi
    done
    
    if [[ -z "$project_dir" ]]; then
        echo "❌ Project not found: $project"
        return 1
    fi
    
    cd "$project_dir"
    echo "📂 Changed to: $project_dir"
    
    # Show context
    why
}

# From Terminal → Obsidian (open related notes)
obs-from-project() {
    local project="${1:-$(basename $PWD)}"
    
    # Check for project note in Research_Lab
    local note_path="$RESEARCH_LAB/${project}/${project}.md"
    local alt_path="$RESEARCH_LAB/${project}.md"
    
    if [[ -f "$note_path" ]]; then
        obs-open Research_Lab "${project}/${project}.md"
    elif [[ -f "$alt_path" ]]; then
        obs-open Research_Lab "${project}.md"
    else
        echo "📓 No Obsidian note found for: $project"
        echo "   Creating quick note..."
        
        # Create a simple project note
        cat > "$RESEARCH_LAB/${project}.md" << EOF
---
tags: [project, r-package]
status: active
created: $(date +%Y-%m-%d)
---

# $project

## Overview

R package in mediationverse ecosystem.

## Links

- Location: \`~/projects/r-packages/active/$project/\`
- GitHub: [Data-Wise/$project](https://github.com/Data-Wise/$project)

## Status

See \`.STATUS\` file in project directory.

## Notes

EOF
        
        echo "   ✅ Created: $RESEARCH_LAB/${project}.md"
        obs-open Research_Lab "${project}.md"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# 4. SYNC ALL VAULTS
# ═══════════════════════════════════════════════════════════════════

# Sync themes/settings across all vaults
obs-sync-all() {
    echo ""
    echo "┌─────────────────────────────────────────────────────────┐"
    echo "│ 🔄 OBSIDIAN SYNC ALL                                   │"
    echo "└─────────────────────────────────────────────────────────┘"
    echo ""
    
    local vaults=("Research_Lab" "Knowledge_Base" "Life_Admin")
    local source_vault="Research_Lab"  # Master vault
    
    echo "📦 Source vault: $source_vault"
    echo "🎯 Target vaults: ${vaults[*]}"
    echo ""
    
    # Check if obs command exists
    if command -v obs &>/dev/null; then
        echo "Using obs CLI for sync..."
        obs sync
    else
        echo "Manual sync mode..."
        
        # Sync appearance settings
        local source_appearance="$OBS_ROOT/$source_vault/.obsidian/appearance.json"
        
        if [[ -f "$source_appearance" ]]; then
            for vault in "${vaults[@]}"; do
                if [[ "$vault" != "$source_vault" ]]; then
                    local target="$OBS_ROOT/$vault/.obsidian/appearance.json"
                    if [[ -d "$OBS_ROOT/$vault/.obsidian" ]]; then
                        cp "$source_appearance" "$target"
                        echo "   ✓ Synced appearance → $vault"
                    fi
                fi
            done
        fi
        
        # Sync hotkeys
        local source_hotkeys="$OBS_ROOT/$source_vault/.obsidian/hotkeys.json"
        
        if [[ -f "$source_hotkeys" ]]; then
            for vault in "${vaults[@]}"; do
                if [[ "$vault" != "$source_vault" ]]; then
                    local target="$OBS_ROOT/$vault/.obsidian/hotkeys.json"
                    if [[ -d "$OBS_ROOT/$vault/.obsidian" ]]; then
                        cp "$source_hotkeys" "$target"
                        echo "   ✓ Synced hotkeys → $vault"
                    fi
                fi
            done
        fi
    fi
    
    echo ""
    echo "✅ Sync complete!"
}

# ═══════════════════════════════════════════════════════════════════
# 5. QUICK NOTES
# ═══════════════════════════════════════════════════════════════════

# Create a quick note in Research_Lab
obs-quick-note() {
    local title="$*"
    
    if [[ -z "$title" ]]; then
        echo "Usage: obs-quick-note <title>"
        return 1
    fi
    
    local filename=$(echo "$title" | tr ' ' '_' | tr -cd '[:alnum:]_-')
    local filepath="$RESEARCH_LAB/00_Incubator/${filename}.md"
    
    cat > "$filepath" << EOF
---
tags: [idea, quick-note]
status: incubating
created: $(date +%Y-%m-%d)
---

# $title

## Idea



## Next Steps

- [ ] 

## Related

- 
EOF
    
    echo "✅ Created: $filepath"
    obs-open Research_Lab "00_Incubator/${filename}.md"
}

# ═══════════════════════════════════════════════════════════════════
# 6. DASHBOARD OPENER
# ═══════════════════════════════════════════════════════════════════

# Open the mediationverse dashboard
obs-dashboard() {
    obs-open Research_Lab "MediationVerse_Dashboard.md"
}
# ═══════════════════════════════════════════════════════════════════
# 7. FULL SYSTEM STATUS
# ═══════════════════════════════════════════════════════════════════

# Show unified status across all systems
system-status() {
    echo ""
    echo "╔═════════════════════════════════════════════════════════╗"
    echo "║ 📊 FULL SYSTEM STATUS                                  ║"
    echo "╚═════════════════════════════════════════════════════════╝"
    echo ""
    
    # ── R Packages ───────────────────────────────────────────────
    echo "📦 R PACKAGES:"
    echo "─────────────────────────────────────────────────────────"
    for status_file in ~/projects/r-packages/active/*/.STATUS; do
        if [[ -f "$status_file" ]]; then
            local pkg_name=$(basename $(dirname "$status_file"))
            local priority=$(grep "^priority:" "$status_file" 2>/dev/null | cut -d: -f2 | tr -d ' ')
            local pkg_status=$(grep "^status:" "$status_file" 2>/dev/null | cut -d: -f2 | tr -d ' ')
            local progress=$(grep "^progress:" "$status_file" 2>/dev/null | cut -d: -f2 | tr -d ' ')
            
            local icon="🔵"
            case "$priority" in
                P0) icon="🔴" ;;
                P1) icon="🟡" ;;
                P2) icon="🟢" ;;
            esac
            
            printf "   %s %-15s %s/%-8s %3s%%\n" "$icon" "$pkg_name" "$priority" "$pkg_status" "$progress"
        fi
    done
    echo ""
    
    # ── Dev Tools ────────────────────────────────────────────────
    echo "🛠️  DEV TOOLS:"
    echo "─────────────────────────────────────────────────────────"
    for status_file in ~/projects/dev-tools/*/.STATUS; do
        if [[ -f "$status_file" ]]; then
            local tool_name=$(basename $(dirname "$status_file"))
            local headline=$(head -5 "$status_file" | grep -E "^(##|\*\*|status:|Active)" | head -1 | sed 's/[#*]//g' | head -c 40)
            printf "   💻 %-20s %s\n" "$tool_name" "$headline"
        fi
    done
    echo ""
    
    # ── Today's Wins ─────────────────────────────────────────────
    local today=$(date +%Y-%m-%d)
    local wins_file="$HOME/.wins/$today.md"
    if [[ -f "$wins_file" ]]; then
        local win_count=$(grep -c "^\-" "$wins_file" 2>/dev/null || echo "0")
        echo "🏆 TODAY'S WINS: $win_count"
        echo "─────────────────────────────────────────────────────────"
        grep "^\-" "$wins_file" | tail -3 | sed 's/^/   /'
    else
        echo "🏆 TODAY'S WINS: 0"
        echo "─────────────────────────────────────────────────────────"
        echo "   (none yet - log with: win 'did something')"
    fi
    echo ""
    
    # ── Active Focus Session ────────────────────────────────────
    if [[ -f /tmp/focus-session-start ]]; then
        local start_time=$(cat /tmp/focus-session-start)
        local task=$(cat /tmp/focus-session-task 2>/dev/null || echo "focus")
        local now=$(date +%s)
        local elapsed=$(( (now - start_time) / 60 ))
        echo "⏱️  ACTIVE FOCUS: ${elapsed}min on '$task'"
    else
        echo "⏱️  No active focus session (start with: f25)"
    fi
    echo ""
    
    # ── Quick Actions ───────────────────────────────────────────
    echo "💡 QUICK ACTIONS:"
    echo "   js     = pick priority task"
    echo "   od     = open Obsidian dashboard"
    echo "   ops    = sync to Obsidian"
    echo "   medcheck = ecosystem health"
    echo ""
}

alias ss='system-status'

# ═══════════════════════════════════════════════════════════════════
# ALIASES
# ═══════════════════════════════════════════════════════════════════

alias oo='obs-open'
alias or='obs-research'
alias ok='obs-knowledge'
alias ol='obs-life'
alias od='obs-dashboard'
alias ops='obs-project-sync'
alias osa='obs-sync-all'
alias ofp='obs-from-project'
alias otp='obs-to-terminal'
alias oqn='obs-quick-note'
