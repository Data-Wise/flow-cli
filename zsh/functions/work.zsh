#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# WORK COMMAND v2 - Multi-Editor Intent Router
# ══════════════════════════════════════════════════════════════════════════════
#
# File:         ~/.config/zsh/functions/work.zsh
# Version:      2.0
# Date:         2025-12-13
# Part of:      Option B+ Multi-Editor Quadrant System
#
# Usage:        work <project> [--editor=EDITOR] [--mode=MODE]
# Help:         work --help
#
# ══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════
# MAIN WORK COMMAND
# ═══════════════════════════════════════════════════════════════════

work() {
    local project=""
    local editor="auto"
    local mode="auto"
    
    # ─────────────────────────────────────────────────────────────
    # Parse arguments
    # ─────────────────────────────────────────────────────────────
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --editor=*) editor="${1#*=}"; shift ;;
            --mode=*) mode="${1#*=}"; shift ;;
            -e|--emacs) editor="emacs"; shift ;;
            -c|--code) editor="code"; shift ;;
            -p|--positron) editor="positron"; shift ;;
            -a|--ai|--claude) editor="claude"; shift ;;
            -t|--terminal) editor="terminal"; shift ;;
            --help|-h)
                _work_help
                return 0
                ;;
            *) project="$1"; shift ;;
        esac
    done
    
    # Show help if no project
    if [[ -z "$project" ]]; then
        _work_help
        return 1
    fi
    
    # ─────────────────────────────────────────────────────────────
    # Find project directory
    # ─────────────────────────────────────────────────────────────
    local project_dir=""
    local search_paths=(
        "$HOME/projects/r-packages/active"
        "$HOME/projects/r-packages/stable"
        "$HOME/projects/mediationverse"
        "$HOME/projects/dev-tools"
        "$HOME/projects/quarto"
        "$HOME/projects/research"
        "$HOME/projects/teaching"
        "$HOME/projects"
    )
    
    # Direct match first
    for base in "${search_paths[@]}"; do
        if [[ -d "$base/$project" ]]; then
            project_dir="$base/$project"
            break
        fi
    done
    
    # Fuzzy match if not found
    if [[ -z "$project_dir" ]]; then
        project_dir=$(find ~/projects -maxdepth 3 -type d -name "*$project*" 2>/dev/null | head -1)
    fi
    
    if [[ -z "$project_dir" ]]; then
        echo "❌ Project not found: $project"
        echo ""
        echo "Available projects:"
        _work_list_projects
        return 1
    fi
    
    # ─────────────────────────────────────────────────────────────
    # Detect project type (uses shared detector if available)
    # ─────────────────────────────────────────────────────────────
    local project_type="generic"
    local detector="$HOME/.config/zsh/functions/project-detector.zsh"

    if [[ -f "$detector" ]]; then
        # Use shared project-detector (unified detection)
        source "$detector" 2>/dev/null
        project_type=$(cd "$project_dir" && get_project_type 2>/dev/null || echo "generic")
    else
        # Fallback detection
        if [[ -f "$project_dir/DESCRIPTION" ]]; then
            project_type="rpkg"
        elif [[ -f "$project_dir/_quarto.yml" ]]; then
            if grep -q "type: manuscript" "$project_dir/_quarto.yml" 2>/dev/null; then
                project_type="manuscript"
            elif grep -q "type: website" "$project_dir/_quarto.yml" 2>/dev/null; then
                project_type="website"
            else
                project_type="quarto"
            fi
        elif [[ -d "$project_dir/.obsidian" ]]; then
            project_type="obsidian"
        elif [[ -f "$project_dir/package.json" ]]; then
            project_type="node"
        fi
    fi
    
    # ─────────────────────────────────────────────────────────────
    # Determine editor based on mode/type/preference
    # ─────────────────────────────────────────────────────────────
    if [[ "$editor" == "auto" ]]; then
        case "$mode" in
            focus)   editor="emacs" ;;
            explore) editor="positron" ;;
            collab)  editor="code" ;;
            ai)      editor="claude" ;;
            quick)   editor="terminal" ;;
            *)
                # Auto based on project type
                case "$project_type" in
                    rpkg)       editor="emacs" ;;     # Default for R packages
                    quarto)     editor="code" ;;      # Good Quarto support
                    website)    editor="code" ;;
                    manuscript) editor="code" ;;
                    *)          editor="terminal" ;;  # Fallback
                esac
                ;;
        esac
    fi
    
    # ─────────────────────────────────────────────────────────────
    # Navigate to project
    # ─────────────────────────────────────────────────────────────
    cd "$project_dir" || return 1
    
    # ─────────────────────────────────────────────────────────────
    # Show context (ADHD: immediate feedback)
    # ─────────────────────────────────────────────────────────────
    echo ""
    echo "┌─────────────────────────────────────────────────────────┐"
    echo "│ 📂 $(basename "$project_dir")"
    echo "│ 📍 $project_dir"
    echo "│ 🏷️  Type: $project_type"
    echo "│ 🔧 Editor: $editor"
    
    # Show git status
    if [[ -d .git ]]; then
        local branch=$(git branch --show-current 2>/dev/null)
        local changes=$(git status --porcelain 2>/dev/null | wc -l | tr -d '[:space:]')
        echo "│ 🌿 Branch: $branch ($changes uncommitted)"
    fi
    
    # Show .STATUS if exists
    if [[ -f .STATUS ]]; then
        local next_line=$(grep -E "^(NEXT|TODO|BLOCKED|🎯):" .STATUS 2>/dev/null | head -1)
        [[ -n "$next_line" ]] && echo "│ 📋 $next_line"
    fi
    
    echo "└─────────────────────────────────────────────────────────┘"
    echo ""
    
    # ─────────────────────────────────────────────────────────────
    # Launch editor
    # ─────────────────────────────────────────────────────────────
    case "$editor" in
        emacs)
            echo "🚀 Opening in Emacs (ESS + LSP + Vim)..."
            _work_launch_emacs "$project_dir"
            ;;
        code)
            echo "🚀 Opening in VS Code..."
            _work_launch_vscode "$project_dir"
            ;;
        positron)
            echo "🚀 Opening in Positron (R-native IDE)..."
            _work_launch_positron "$project_dir"
            ;;
        claude)
            echo "🚀 Starting Claude Code session..."
            _work_launch_claude "$project_dir"
            ;;
        terminal)
            echo "💻 Ready in terminal."
            echo ""
            echo "Quick aliases: t=test lt=load+test cc=claude ck=check"
            ;;
        *)
            echo "⚠️  Unknown editor: $editor"
            ;;
    esac
    
    # ─────────────────────────────────────────────────────────────
    # Set up bookmarks (ADHD: quick navigation)
    # ─────────────────────────────────────────────────────────────
    _work_set_bookmarks "$project_type"

    # ─────────────────────────────────────────────────────────────
    # Integrations: workflow logging + context suggestions
    # ─────────────────────────────────────────────────────────────

    # Log project switch if worklog is available
    if type worklog &>/dev/null; then
        worklog "switched" "$(basename $project_dir) ($project_type)"
    fi

    # Show whatnext suggestions if available (ADHD: immediate direction)
    if type whatnext &>/dev/null && [[ "$editor" == "terminal" ]]; then
        echo ""
        whatnext
    fi
}

# ═══════════════════════════════════════════════════════════════════
# EDITOR LAUNCHERS
# ═══════════════════════════════════════════════════════════════════

_work_launch_emacs() {
    local dir="$1"
    
    # Start daemon if needed
    if ! emacsclient -e '(+ 1 1)' &>/dev/null; then
        echo "   Starting Emacs daemon..."
        emacs --daemon 2>/dev/null
        sleep 2
    fi
    
    emacsclient -n "$dir" 2>/dev/null
    
    # Focus Emacs window (macOS)
    osascript -e 'tell application "Emacs" to activate' 2>/dev/null
}

_work_launch_vscode() {
    local dir="$1"
    
    # Check for workspace file
    local workspace=$(find "$dir" -maxdepth 1 -name "*.code-workspace" 2>/dev/null | head -1)
    
    if [[ -n "$workspace" ]]; then
        code "$workspace"
    else
        code "$dir"
    fi
}

_work_launch_positron() {
    local dir="$1"
    
    # Check if Positron is installed
    if [[ -d "/Applications/Positron.app" ]]; then
        open -a "Positron" "$dir"
    elif command -v positron &>/dev/null; then
        positron "$dir"
    else
        echo "   ⚠️  Positron not found"
        echo "   📥 Download from: https://positron.posit.co"
        echo "   🔄 Falling back to VS Code..."
        code "$dir"
    fi
}

_work_launch_claude() {
    local dir="$1"
    
    echo ""
    echo "💡 Claude Code Tips:"
    echo "   /help     - Show commands"
    echo "   /status   - Project info"
    echo "   /add      - Add file to context"
    echo ""
    
    # Start Claude Code
    cd "$dir" && claude
}

# ═══════════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════════

_work_set_bookmarks() {
    local type="$1"
    
    # Clear previous bookmarks (using valid names without @)
    unhash -d pkgr pkgtest pkgman pkgvig pkgdata pkgdocs pkgposts pkgassets pkgsite pkgsec pkgfig pkgref 2>/dev/null
    
    case "$type" in
        rpkg)
            [[ -d R ]] && hash -d pkgr="$PWD/R"
            [[ -d tests/testthat ]] && hash -d pkgtest="$PWD/tests/testthat"
            [[ -d man ]] && hash -d pkgman="$PWD/man"
            [[ -d vignettes ]] && hash -d pkgvig="$PWD/vignettes"
            [[ -d data-raw ]] && hash -d pkgdata="$PWD/data-raw"
            echo "📌 Bookmarks: ~pkgr ~pkgtest ~pkgman ~pkgvig ~pkgdata"
            ;;
        quarto|website)
            [[ -d docs ]] && hash -d pkgdocs="$PWD/docs"
            [[ -d posts ]] && hash -d pkgposts="$PWD/posts"
            [[ -d assets ]] && hash -d pkgassets="$PWD/assets"
            [[ -d _site ]] && hash -d pkgsite="$PWD/_site"
            echo "📌 Bookmarks: ~pkgdocs ~pkgposts ~pkgassets ~pkgsite"
            ;;
        manuscript)
            [[ -d sections ]] && hash -d pkgsec="$PWD/sections"
            [[ -d figures ]] && hash -d pkgfig="$PWD/figures"
            [[ -d references ]] && hash -d pkgref="$PWD/references"
            echo "📌 Bookmarks: ~pkgsec ~pkgfig ~pkgref"
            ;;
    esac
}

_work_list_projects() {
    echo ""
    echo "📦 R Packages (active):"
    ls -1 ~/projects/r-packages/active 2>/dev/null | sed 's/^/   /'
    echo ""
    echo "🛠️  Dev Tools:"
    ls -1 ~/projects/dev-tools 2>/dev/null | sed 's/^/   /'
    echo ""
}

_work_help() {
    cat << 'EOF'
┌─────────────────────────────────────────────────────────────────┐
│                    WORK COMMAND v2.0                            │
│              Multi-Editor Intent Router                         │
└─────────────────────────────────────────────────────────────────┘

USAGE:
    work <project> [OPTIONS]

OPTIONS:
    -e, --emacs      Open in Emacs (ESS + LSP + Vim)
    -c, --code       Open in VS Code
    -p, --positron   Open in Positron (R-native IDE)
    -a, --ai         Open in Claude Code (AI-assisted)
    -t, --terminal   Stay in terminal

    --editor=NAME    Specify editor explicitly
    --mode=MODE      Set work mode (affects auto-selection)

MODES:
    focus     → Emacs (deep work, vim flow)
    explore   → Positron (see data while coding)
    collab    → VS Code (familiar, shareable)
    ai        → Claude Code (AI-assisted)
    quick     → Terminal (fast commands)

EXAMPLES:
    work medfit              # Auto-detect best editor
    work medfit -e           # Force Emacs
    work medfit -p           # Force Positron
    work medfit --mode=ai    # AI-assisted session

QUICK ALIASES:
    we <project>    Emacs
    wc <project>    VS Code
    wp <project>    Positron
    wa <project>    Claude Code (AI)
    wt <project>    Terminal
EOF
}

# ═══════════════════════════════════════════════════════════════════
# QUICK ALIASES
# ═══════════════════════════════════════════════════════════════════

alias w='work'
alias we='work --editor=emacs'
alias wc='work --editor=code'
alias wp='work --editor=positron'
alias wa='work --editor=claude'
alias wt='work --editor=terminal'

# Mode shortcuts
alias wf='work --mode=focus'
alias wx='work --mode=explore'
alias wai='work --mode=ai'
alias wq='work --mode=quick'
