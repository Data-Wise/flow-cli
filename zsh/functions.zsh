#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# ZSH WORKFLOW FUNCTIONS - ADHD-OPTIMIZED
# ══════════════════════════════════════════════════════════════════════════════
#
# File:         ~/.config/zsh/functions.zsh
# Version:      1.0
# Date:         2025-12-12
# Count:        21 workflow functions
#
# Usage:        Sourced by .zshrc
# Help:         helpworkflow
#
# ══════════════════════════════════════════════════════════════════════════════

# ============================================
# CATEGORY 1: CONTEXT AWARENESS
# ============================================

# Show current context with visual clarity
here() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📍 LOCATION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    pwd
    echo ""
    
    # If in R package
    if [[ -f "DESCRIPTION" ]]; then
        local pkg=$(grep "^Package:" DESCRIPTION | cut -d' ' -f2)
        echo "📦 R PACKAGE: $pkg"
        grep "^Version:" DESCRIPTION
        echo ""
    fi
    
    # If has .STATUS
    if [[ -f ".STATUS" ]]; then
        echo "📊 STATUS"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        head -5 .STATUS
        echo ""
    fi
    
    # If git repo
    if git rev-parse --git-dir > /dev/null 2>&1; then
        echo "🔧 GIT"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        git status -sb
    fi
    
    # Dashboard status
    if [[ -f "/tmp/project-status.json" ]]; then
        echo ""
        echo "📊 DASHBOARD"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        local last_scan=$(stat -f '%Sm' -t '%Y-%m-%d %H:%M' /tmp/project-status.json 2>/dev/null)
        echo "Last scan: $last_scan"
        echo "Run 'dash' to update → 'do' to update+open Claude"
    fi
}

# next() is defined in adhd-helpers.zsh (authoritative)
# That version scans all projects and provides suggestions
# This simpler version just shows .STATUS - renamed to next-local
next-local() {
    if [[ -f ".STATUS" ]]; then
        echo "🎯 NEXT ACTION:"
        # Extract next action section
        sed -n '/## 🎯 Next Action/,/##/p' .STATUS | head -10
    else
        echo "No .STATUS file in current directory"
    fi
}

# Show just progress bars from .STATUS
progress_check() {
    if [[ -f ".STATUS" ]]; then
        echo "📊 PROGRESS:"
        sed -n '/## 📊 Progress/,/##/p' .STATUS
    else
        echo "No .STATUS file"
    fi
}


# ============================================
# CATEGORY 2: SESSION MANAGEMENT
# ============================================

# Start work session on a project
startwork() {
    local project=$1
    if [[ -z "$project" ]]; then
        echo "Usage: startwork <project>"
        echo ""
        echo "📦 R Packages:"
        echo "  medfit, probmed, medsim, medrobust, medverse"
        echo ""
        echo "📁 Other:"
        echo "  planning, teaching, zsh, dev"
        return 1
    fi
    
    # Jump to project (direct cd, no @bookmarks)
    case "$project" in
        medfit|med)     cd ~/projects/r-packages/active/medfit ;;
        probmed|prob)   cd ~/projects/r-packages/active/probmed ;;
        medsim|sim)     cd ~/projects/r-packages/active/medsim ;;
        medrobust|robust) cd ~/projects/r-packages/active/medrobust ;;
        medverse|verse) cd ~/projects/r-packages/active/mediationverse ;;
        planning|plan)  cd ~/projects/research/mediation-planning ;;
        teaching|teach) cd ~/Dropbox/Teaching/stat-440-prac ;;
        zsh)            cd ~/.config/zsh ;;
        dev)            cd ~/projects/dev-tools ;;
        *) 
            echo "❌ Unknown project: $project"
            return 1
            ;;
    esac
    
    # Show context
    here
    
    # Start Emacs daemon if not running
    if ! pgrep -x "emacs" > /dev/null; then
        echo ""
        echo "🚀 Starting Emacs daemon..."
        emacs --daemon 2>/dev/null
    fi
}

# End work session
endwork() {
    echo "📝 Updating status..."
    if [[ -f ".STATUS" ]]; then
        estat
    else
        echo "No .STATUS file to update"
    fi
}

# Work session with timer
worktimer() {
    local minutes=${1:-25}
    local project=${2:-"current task"}
    
    echo "⏱️  Starting $minutes min session on: $project"
    echo "Started at: $(date '+%H:%M')"
    
    # Timer in background
    (sleep $((minutes * 60)) && \
     say "Work session complete" && \
     echo "🔔 $minutes minutes complete!" && \
     echo "Update your status!") &
    
    local timer_pid=$!
    echo "Timer PID: $timer_pid (kill $timer_pid to cancel)"
}


# ============================================
# CATEGORY 3: R PACKAGE WORKFLOWS
# ============================================

# Complete check cycle: load → document → test → check
rcycle() {
    echo "🔄 Running full R package cycle..."
    echo ""
    
    echo "1️⃣ Loading package..."
    rload || return 1
    echo ""
    
    echo "2️⃣ Documenting..."
    rdoc || return 1
    echo ""
    
    echo "3️⃣ Running tests..."
    rtest || return 1
    echo ""
    
    echo "4️⃣ Checking package..."
    rcheck || return 1
    echo ""
    
    echo "✅ Full cycle complete!"
}

# Quick cycle (load + test only)
rquick() {
    echo "⚡ Quick check..."
    rload && rtest
}

# Jump to R package and show relevant info

# Show status of all R packages
rpkgstatus() {
    echo "📦 R PACKAGES STATUS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    for pkg in ~/projects/r-packages/active/*; do
        if [[ -d "$pkg" ]]; then
            local name=$(basename "$pkg")
            local version=$(grep "^Version:" "$pkg/DESCRIPTION" 2>/dev/null | cut -d' ' -f2)
            
            echo -n "$name ($version) - "
            
            if [[ -f "$pkg/.STATUS" ]]; then
                # Extract status emoji
                local status_emoji=$(grep "Status:" "$pkg/.STATUS" | grep -o '[🔴🟡🟢✅]' | head -1)
                echo "$status_emoji"
            else
                echo "❓"
            fi
        fi
    done
}


# ============================================
# CATEGORY 4: TEACHING WORKFLOWS
# ============================================

# Quick jump to teaching + show what's due
teach() {
    cd ~/Dropbox/Teaching/stat-440-prac
    
    echo "📚 STAT 440/540"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Show status
    if [[ -f ".STATUS" ]]; then
        next
    fi
    
    # Show recent Canvas updates (if you track in a file)
    if [[ -f "canvas-updates.md" ]]; then
        echo ""
        echo "Recent Canvas updates:"
        tail -5 canvas-updates.md
    fi
}

# Start grading session
grade() {
    cd ~/Dropbox/Teaching/stat-440-prac
    
    # Create grading log for today
    local today=$(date +%Y-%m-%d)
    local grading_log="grading-$today.md"
    
    if [[ ! -f "$grading_log" ]]; then
        cat > "$grading_log" << EOF
# Grading Log - $today

## Assignment:
## Students: X
## Started: $(date +%H:%M)

## Progress:
- [ ] 

## Notes:

EOF
    fi
    
    e "$grading_log"
}


# ============================================
# CATEGORY 5: FOCUS & DISTRACTION MANAGEMENT
# ============================================

# focus() is defined in adhd-helpers.zsh (authoritative)
# The adhd-helpers version has full timer support and better ADHD features
# DEPRECATED: This basic version - use focus() from adhd-helpers.zsh
#
# focus() {
#     echo "🎯 ENTERING FOCUS MODE"
#     ... (moved to adhd-helpers.zsh)
# }

# End focus mode
unfocus() {
    echo "🌅 Exiting focus mode..."
    
    # Turn on notifications
    osascript -e 'tell application "System Events" to keystroke "D" using {command down, shift down, option down, control down}' 2>/dev/null
    
    echo "✅ Notifications restored"
}

# Short break with return reminder
quickbreak() {
    local minutes=${1:-5}
    
    echo "☕ Taking $minutes min break"
    echo "Started: $(date '+%H:%M')"
    
    (sleep $((minutes * 60)) && \
     say "Break time over" && \
     echo "🔔 Break complete - back to work!") &
}


# ============================================
# CATEGORY 6: GIT WORKFLOWS
# ============================================

# Git status + show what changed
smartgit() {
    git status -sb
    echo ""
    echo "Recent commits:"
    git log --oneline -3
    echo ""
    echo "Changed files:"
    git diff --name-status
}

# Stage all + commit with message
qcommit() {
    if [[ -z "$1" ]]; then
        echo "Usage: qcommit 'commit message'"
        return 1
    fi
    
    git add -A
    git status -sb
    echo ""
    git commit -m "$1"
}

# Quick commit + push
qpush() {
    if [[ -z "$1" ]]; then
        echo "Usage: qpush 'commit message'"
        return 1
    fi
    
    qcommit "$1" && git push
}


# ============================================
# CATEGORY 7: SEARCH & FIND
# ============================================

# Find files across all projects
findproject() {
    local pattern=$1
    if [[ -z "$pattern" ]]; then
        echo "Usage: findproject <pattern>"
        return 1
    fi
    
    echo "🔍 Searching all projects for: $pattern"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    find ~/projects -name "*$pattern*" -type f | head -20
}

# Find recently modified files in projects
recent() {
    local days=${1:-1}
    
    echo "📁 Files modified in last $days day(s):"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    find ~/projects -type f -mtime -$days -not -path "*/\.*" | \
        grep -v ".Rcheck" | \
        grep -v "node_modules" | \
        head -30
}


# ============================================
# CATEGORY 8: STATUS MANAGEMENT
# ============================================

# Show all 🔴 blocked/critical items across projects
critical() {
    echo "🔴 CRITICAL ITEMS (ACROSS ALL PROJECTS)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    for status_file in $(find ~/projects -name ".STATUS" -type f); do
        if grep -q "🔴" "$status_file"; then
            local dir=$(dirname "$status_file")
            local project=$(basename "$dir")
            
            echo ""
            echo "📍 $project:"
            grep "🔴" "$status_file" | head -3
        fi
    done
}

# Show what's actively in progress
active() {
    echo "🟢 ACTIVE WORK (ACROSS ALL PROJECTS)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    for status_file in $(find ~/projects -name ".STATUS" -type f); do
        if grep -q "🟢" "$status_file"; then
            local dir=$(dirname "$status_file")
            local project=$(basename "$dir")
            
            echo "  ✓ $project"
        fi
    done
}

# ============================================
# CATEGORY 9: ALIAS DISCOVERY (ADHD-OPTIMIZED)
# ============================================

# Visual categorization of aliases - reduces cognitive load
aliashelp() {
    case "${1:-all}" in
        r|R)
            echo "📦 R PACKAGE DEVELOPMENT"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Load & Test:  rload ld | rtest ts | rdoc dc | rcheck ck"
            echo "Build:        rbuild bd | rinstall"
            echo "Advanced:     rcycle rquick rcov rspell"
            echo "Info:         rpkg rpkgstatus rpkgtree"
            echo "Clean:        rpkgclean rpkgdeep"
            echo "Versioning:   rbumppatch rbumpminor rbumpmajor"
            echo "Checks:       rcheckfast rcheckcran rcheckwin rcheckrhub"
            echo "View files:   peekr peekrd peekdesc peeknews"
            echo ""
            echo "💡 Ultra-fast: t (test) | c (claude) | q (quarto)"
            ;;
        claude|cc)
            echo "🤖 CLAUDE CODE"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Launch:       cc | ccc (continue) | ccl (latest)"
            echo "Models:       cch (haiku) | ccs (sonnet) | cco (opus)"
            echo "Modes:        ccauto | ccplan | ccyolo"
            echo "R-specific:   ccrdoc ccrtest ccrexplain ccrfix ccroptimize"
            echo "Code tasks:   ccfix ccoptimize ccrefactor ccreview ccsecurity"
            echo "Output:       ccp (prompt) | ccjson | ccstream"
            echo ""
            echo "💡 Ultra-fast: c (claude)"
            ;;
        git|g)
            echo "🔧 GIT SHORTCUTS"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Status:       gs | smartgit"
            echo "Log:          glog | gloga"
            echo "Quick:        qcommit qpush"
            echo "Undo:         gundo"
            ;;
        quarto|q)
            echo "📝 QUARTO"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Build:        qp (preview) | qr (render) | qc (check)"
            echo "Clean:        qclean"
            echo ""
            echo "💡 Ultra-fast: q (preview)"
            ;;
        files|f)
            echo "📁 FILE OPERATIONS"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Better tools: cat→bat | find→fd | grep→rg"
            echo "Quick view:   peek peekdesc peeknews peekr peekrd peekqmd"
            echo "List:         ll la l | d (dirs)"
            ;;
        workflow|w)
            echo "⚡ WORKFLOW FUNCTIONS"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Context:      here next progress_check"
            echo "Sessions:     startwork endwork worktimer"
            echo "Focus:        focus unfocus quickbreak"
            echo "Status:       critical active"
            echo "Search:       findproject recent"
            echo "Dashboard:    dash (update) | do (update+open Claude)"
            echo "ADHD:         wn (whatnow) | wins | wh (wins history)"
            ;;
        *)
            echo "💡 ALIAS HELP SYSTEM"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "Usage: aliashelp <category>  or  ah <category>"
            echo ""
            echo "Categories:"
            echo "  r          📦 R package development (35 aliases)"
            echo "  claude     🤖 Claude Code (25 aliases)"
            echo "  git        🔧 Git workflows (4 aliases)"
            echo "  quarto     📝 Quarto publishing (4 aliases)"
            echo "  files      📁 File operations (10 aliases)"
            echo "  workflow   ⚡ Custom functions (21 functions)"
            echo ""
            echo "🚀 Quick access: ah <category>"
            echo "💡 Ultra-fast: t (test) | c (claude) | q (quarto)"
            ;;
    esac
}

# Short alias for aliashelp
alias ah='aliashelp'

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 10: ADHD DECISION HELPERS
# ══════════════════════════════════════════════════════════════════════════════

# What should I do now? - ADHD decision helper
whatnow() {
    echo "🧠 WHAT SHOULD I DO NOW?"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Check for blockers first (current dir)
    if [[ -f ".STATUS" ]]; then
        local blocked=$(grep "^blocked:" .STATUS 2>/dev/null | cut -d':' -f2-)
        if [[ -n "$blocked" && "$blocked" != " " ]]; then
            echo "⛔ BLOCKED HERE:"
            echo "  $blocked"
            echo ""
        fi
        
        # Show next action
        local next_action=$(grep "^next:" .STATUS 2>/dev/null | cut -d':' -f2-)
        if [[ -n "$next_action" ]]; then
            echo "🎯 NEXT ACTION (this project):"
            echo "  $next_action"
            echo ""
        fi
    fi
    
    # Show critical items across all projects
    echo "🔴 CRITICAL (all projects):"
    local found_critical=0
    for status_file in ~/projects/r-packages/active/*/.STATUS; do
        if [[ -f "$status_file" ]]; then
            local priority=$(grep "^priority:" "$status_file" 2>/dev/null | cut -d' ' -f2)
            local proj_status=$(grep "^status:" "$status_file" 2>/dev/null | cut -d' ' -f2)
            if [[ "$priority" == "P0" ]] || [[ "$proj_status" == "blocked" ]]; then
                local proj=$(basename $(dirname "$status_file"))
                local blocked=$(grep "^blocked:" "$status_file" 2>/dev/null | cut -d':' -f2-)
                echo "  📍 $proj: $blocked"
                found_critical=1
            fi
        fi
    done
    [[ $found_critical -eq 0 ]] && echo "  ✅ None! All clear."
    echo ""
    
    # Suggest based on time of day
    local hour=$(date +%H)
    echo "💡 SUGGESTION:"
    if [[ $hour -lt 10 ]]; then
        echo "  ☀️ Morning = Deep work. Tackle P0 blockers."
    elif [[ $hour -lt 12 ]]; then
        echo "  🌤️ Late morning = Peak focus. Complex coding."
    elif [[ $hour -lt 14 ]]; then
        echo "  🍽️ After lunch = Lighter tasks. Reviews, docs."
    elif [[ $hour -lt 17 ]]; then
        echo "  🌅 Afternoon = Admin, email, planning."
    else
        echo "  🌙 Evening = Light tasks only. Don't start new things."
    fi
    echo ""
    echo "📊 Run 'dash' to update dashboard | 'wins' to log progress"
}
# wn alias defined in adhd-helpers.zsh as 'what-next' (authoritative)
# alias wn='whatnow'  # DEPRECATED - use what-next from adhd-helpers

# wins() is defined in adhd-helpers.zsh (authoritative)
# That version uses win() to add and wins() to display
# DEPRECATED: This combined version - use win/wins from adhd-helpers.zsh
#
# wins() {
#     ... (moved to adhd-helpers.zsh)
# }

# Show wins from previous days
winshistory() {
    local days=${1:-7}
    echo "📜 WIN HISTORY (last $days days)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    for file in $(ls -r ~/.wins/*.md 2>/dev/null | head -$days); do
        local date=$(basename "$file" .md)
        local count=$(grep -c "^-" "$file" 2>/dev/null || echo 0)
        echo "$date: $count wins"
    done
}
# wh alias defined in adhd-helpers.zsh as 'wins-history' (authoritative)
# alias wh='winshistory'  # DEPRECATED - use wins-history from adhd-helpers

# ══════════════════════════════════════════════════════════════════════════════
# END WORKFLOW FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════
