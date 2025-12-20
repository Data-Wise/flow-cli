#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# ADHD HELPERS - Core Commands
# ══════════════════════════════════════════════════════════════════════════════
#
# File:         ~/.config/zsh/functions/adhd-helpers.zsh
# Version:      1.0
# Date:         2025-12-13
# Part of:      Option B+ Multi-Editor Quadrant System
#
# Commands:     js (just-start), why, win, yay, wins
#
# ══════════════════════════════════════════════════════════════════════════════

# IMPORTANT: Ensure standard zsh parsing
# Note: emulate -L zsh already disables aliases during emulation
# We don't need explicit setopt NO_ALIASES as it prevents our own alias definitions
emulate -L zsh

# ═══════════════════════════════════════════════════════════════════
# 1. JUST-START - When you can't decide what to work on
# ═══════════════════════════════════════════════════════════════════

just-start() {
    # Help check FIRST (all three forms)
    if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
        cat <<'EOF'
Usage: just-start

ADHD-friendly workflow to eliminate decision paralysis and start working.

DESCRIPTION:
  Automated workflow that picks a project, starts session tracking,
  and opens work environment. No decisions required - just execute.

EXAMPLES:
  just-start                   # Let the system decide what to work on
  js                           # Alias for just-start

WORKFLOW:
  1. Picks highest priority project (P0, then P1, then any active)
  2. Starts session tracking
  3. Opens project in editor
  4. Shows .STATUS file with next actions

ALIASES:
  js                           # Shorthand

See also: why, work, startsession
EOF
        return 0
    fi

    echo "🎲 Finding your next task..."
    echo ""

    local project_dir=""
    local project_name=""
    local project_type=""
    local reason=""
    local next_action=""

    # Priority 1: Check for P0 active projects across ALL project types
    for status_file in $(find ~/projects -name ".STATUS" -type f 2>/dev/null); do
        if [[ -f "$status_file" ]]; then
            local status=$(grep -i "^status:" "$status_file" 2>/dev/null | cut -d: -f2- | sed 's/^[[:space:]]*//' | tr '[:upper:]' '[:lower:]')
            local priority=$(grep -i "^priority:" "$status_file" 2>/dev/null | cut -d: -f2- | sed 's/^[[:space:]]*//')

            if [[ "$status" == "active" ]] && [[ "$priority" == "P0" ]]; then
                project_dir=$(dirname "$status_file")
                project_name=$(basename "$project_dir")
                project_type=$(grep -i "^type:" "$status_file" 2>/dev/null | cut -d: -f2- | sed 's/^[[:space:]]*//')
                next_action=$(grep -i "^next:" "$status_file" 2>/dev/null | cut -d: -f2- | sed 's/^[[:space:]]*//')
                reason="P0 priority (critical)"
                break
            fi
        fi
    done

    # Priority 2: Check for P1 active projects
    if [[ -z "$project_dir" ]]; then
        for status_file in $(find ~/projects -name ".STATUS" -type f 2>/dev/null); do
            if [[ -f "$status_file" ]]; then
                local status=$(grep -i "^status:" "$status_file" 2>/dev/null | cut -d: -f2- | sed 's/^[[:space:]]*//' | tr '[:upper:]' '[:lower:]')
                local priority=$(grep -i "^priority:" "$status_file" 2>/dev/null | cut -d: -f2- | sed 's/^[[:space:]]*//')

                if [[ "$status" == "active" ]] && [[ "$priority" == "P1" ]]; then
                    project_dir=$(dirname "$status_file")
                    project_name=$(basename "$project_dir")
                    project_type=$(grep -i "^type:" "$status_file" 2>/dev/null | cut -d: -f2- | sed 's/^[[:space:]]*//')
                    next_action=$(grep -i "^next:" "$status_file" 2>/dev/null | cut -d: -f2- | sed 's/^[[:space:]]*//')
                    reason="P1 priority (high)"
                    break
                fi
            fi
        done
    fi

    # Priority 3: Any active project
    if [[ -z "$project_dir" ]]; then
        for status_file in $(find ~/projects -name ".STATUS" -type f 2>/dev/null); do
            if [[ -f "$status_file" ]]; then
                local status=$(grep -i "^status:" "$status_file" 2>/dev/null | cut -d: -f2- | sed 's/^[[:space:]]*//' | tr '[:upper:]' '[:lower:]')

                if [[ "$status" == "active" ]]; then
                    project_dir=$(dirname "$status_file")
                    project_name=$(basename "$project_dir")
                    project_type=$(grep -i "^type:" "$status_file" 2>/dev/null | cut -d: -f2- | sed 's/^[[:space:]]*//')
                    next_action=$(grep -i "^next:" "$status_file" 2>/dev/null | cut -d: -f2- | sed 's/^[[:space:]]*//')
                    reason="active project"
                    break
                fi
            fi
        done
    fi

    # Priority 4: Most recently modified .STATUS file
    if [[ -z "$project_dir" ]]; then
        local recent_status=$(find ~/projects -name ".STATUS" -type f -exec ls -t {} + 2>/dev/null | head -1)
        if [[ -f "$recent_status" ]]; then
            project_dir=$(dirname "$recent_status")
            project_name=$(basename "$project_dir")
            project_type=$(grep -i "^type:" "$recent_status" 2>/dev/null | cut -d: -f2- | sed 's/^[[:space:]]*//')
            next_action=$(grep -i "^next:" "$recent_status" 2>/dev/null | cut -d: -f2- | sed 's/^[[:space:]]*//')
            reason="most recent activity"
        fi
    fi

    if [[ -d "$project_dir" ]]; then
        # Determine icon based on type
        local icon="📦"
        case "$project_type" in
            *package*|rpkg) icon="📦" ;;
            *teach*|course) icon="📚" ;;
            *research*|manuscript) icon="📊" ;;
            *quarto*) icon="📝" ;;
            *dev*|tool) icon="🔧" ;;
        esac

        echo "┌─────────────────────────────────────────────────────────┐"
        echo "│ 🎯 DECISION MADE FOR YOU                                │"
        echo "├─────────────────────────────────────────────────────────┤"
        echo "│ Project: $icon $project_name"
        if [[ -n "$project_type" ]]; then
            echo "│ Type:    $project_type"
        fi
        echo "│ Reason:  $reason"
        if [[ -n "$next_action" ]]; then
            echo "│ Next:    $next_action"
        fi
        echo "└─────────────────────────────────────────────────────────┘"
        echo ""

        # Navigate and show context
        cd "$project_dir"

        # Show what to do
        if [[ -f .STATUS ]]; then
            echo "📋 Current status:"
            head -10 .STATUS
            echo ""
        fi

        echo "💡 Quick actions:"
        echo "   work .        = Start working (auto-detect editor)"
        echo "   status .      = Update status"
        echo "   dash          = See all projects"
        echo ""
        echo "🚀 You're in $project_name. Just start typing!"
    else
        echo "❌ No projects found with .STATUS files"
        echo ""
        echo "💡 Create .STATUS files with:"
        echo "   status <project> --create"
    fi
}

# Aliases for just-start - REMOVED 2025-12-19: Use 'just-start' directly
# alias js='just-start'
# alias idk='just-start'      # "I don't know what to work on"
# alias stuck='just-start'    # When you're stuck

# ═══════════════════════════════════════════════════════════════════
# 2. WHY - "Why am I here?" Context recovery
# ═══════════════════════════════════════════════════════════════════

why() {
    echo ""
    echo "┌─────────────────────────────────────────────────────────┐"
    echo "│ 🤔 WHY AM I HERE?                                       │"
    echo "└─────────────────────────────────────────────────────────┘"
    echo ""
    
    # Location
    echo "📍 LOCATION: $(pwd)"
    local project=$(basename "$PWD")
    echo "📦 PROJECT:  $project"
    echo ""
    
    # Git context
    if [[ -d .git ]]; then
        local branch=$(git branch --show-current 2>/dev/null)
        local last_commit=$(git log --oneline -1 2>/dev/null)
        local changes=$(git status --porcelain 2>/dev/null | wc -l | tr -d '[:space:]')
        
        echo "🌿 BRANCH: $branch"
        echo "📝 LAST COMMIT: $last_commit"
        echo "✏️  UNCOMMITTED: $changes files"
        echo ""
    fi
    
    # What you were doing (from .STATUS)
    if [[ -f .STATUS ]]; then
        echo "🎯 CURRENT GOAL:"
        echo "─────────────────────────────────────────────────────────"
        # Show key fields from .STATUS
        grep -E "^(next|blocked|status|priority):" .STATUS 2>/dev/null | head -5
        echo "─────────────────────────────────────────────────────────"
        echo ""
    fi
    
    # Recent activity
    echo "⏰ RECENT ACTIVITY:"
    git log --oneline --since="4 hours ago" 2>/dev/null | head -3
    if [[ $(git log --oneline --since="4 hours ago" 2>/dev/null | wc -l) -eq 0 ]]; then
        echo "   (no commits in last 4 hours)"
    fi
    echo ""
    
    # Breadcrumbs if any
    if [[ -f .breadcrumbs ]]; then
        echo "🍞 YOUR NOTES:"
        tail -3 .breadcrumbs
        echo ""
    fi
    
    # Suggestion
    echo "💡 SUGGESTED NEXT:"
    echo "   t   = run tests (see if things work)"
    echo "   lt  = load + test (quick check)"
    echo "   gs  = git status (see changes)"
}

# ═══════════════════════════════════════════════════════════════════
# 3. WIN - Log wins for dopamine + tracking
# ═══════════════════════════════════════════════════════════════════

win() {
    local description="$*"
    
    if [[ -z "$description" ]]; then
        echo "Usage: win 'what you accomplished'"
        echo "   or: w! 'what you accomplished'"
        return 1
    fi
    
    local timestamp=$(date "+%H:%M")
    local today=$(date +%Y-%m-%d)
    local project=$(basename "$PWD")
    local wins_dir="$HOME/.wins"
    local log_file="$wins_dir/$today.md"
    
    # Create wins directory if needed
    mkdir -p "$wins_dir"
    
    # Create today's file with header if new
    if [[ ! -f "$log_file" ]]; then
        echo "# 🏆 Wins for $today" > "$log_file"
        echo "" >> "$log_file"
    fi
    
    # Log the win
    echo "- [$timestamp] **$project**: $description" >> "$log_file"
    
    # Celebrate!
    echo ""
    echo "┌─────────────────────────────────────────────────────────┐"
    echo "│ 🏆 WIN LOGGED!                                          │"
    echo "├─────────────────────────────────────────────────────────┤"
    echo "│ $description"
    echo "└─────────────────────────────────────────────────────────┘"
    
    # Count today's wins
    local win_count=$(grep -c "^\-" "$log_file" 2>/dev/null || echo "0")
    
    # Escalating celebrations based on count
    if [[ $win_count -ge 10 ]]; then
        echo ""
        echo "🔥🔥🔥 $win_count WINS TODAY! YOU'RE ON FIRE! 🔥🔥🔥"
    elif [[ $win_count -ge 5 ]]; then
        echo ""
        echo "⭐ $win_count wins today! Great momentum!"
    elif [[ $win_count -ge 3 ]]; then
        echo ""
        echo "💪 $win_count wins! Keep it going!"
    else
        echo ""
        echo "✨ Win #$win_count today"
    fi
}

# Quick celebration without logging
yay() {
    local celebrations=(
        "✅ Nice!"
        "👍 Got it!"
        "💪 Progress!"
        "⚡ Quick win!"
        "🎯 Done!"
        "✨ Smooth!"
        "🚀 Shipped!"
    )
    echo "${celebrations[$RANDOM % ${#celebrations[@]}]}"
}

# See today's wins
wins() {
    local today=$(date +%Y-%m-%d)
    local log_file="$HOME/.wins/$today.md"
    
    echo ""
    if [[ -f "$log_file" ]]; then
        cat "$log_file"
        echo ""
        local count=$(grep -c "^\-" "$log_file" 2>/dev/null || echo "0")
        echo "─────────────────────────────────────────────────────────"
        echo "📊 Total: $count wins today!"
        
        # Encouragement based on count
        if [[ $count -eq 0 ]]; then
            echo "💡 Log your first win with: win 'what you did'"
        elif [[ $count -lt 3 ]]; then
            echo "💡 Keep going! Small wins add up."
        elif [[ $count -lt 5 ]]; then
            echo "🌟 Nice progress! You're building momentum."
        else
            echo "🔥 Incredible day! You're crushing it!"
        fi
    else
        echo "No wins logged today yet."
        echo ""
        echo "💡 Start with: win 'your first accomplishment'"
        echo "   Even small things count!"
        echo ""
        echo "   Examples:"
        echo "   win 'fixed failing test'"
        echo "   win 'added roxygen docs'"
        echo "   win 'figured out the bug'"
    fi
}

# See wins from a specific date or recent days
wins-history() {
    local days="${1:-7}"
    local wins_dir="$HOME/.wins"
    
    echo "📅 Wins from last $days days:"
    echo ""
    
    local total=0
    for i in $(seq 0 $((days-1))); do
        local date=$(date -v-${i}d +%Y-%m-%d)
        local file="$wins_dir/$date.md"
        if [[ -f "$file" ]]; then
            local count=$(grep -c "^\-" "$file" 2>/dev/null || echo "0")
            total=$((total + count))
            echo "$date: $count wins"
        fi; done
    
    echo ""
    echo "─────────────────────────────────────────────────────────"
    echo "📊 Total: $total wins in $days days"
}

# ═══════════════════════════════════════════════════════════════════
# ALIASES
# ═══════════════════════════════════════════════════════════════════

# REMOVED 2025-12-19: Use full commands instead
# alias w!='win'
# alias nice='yay'
# alias wh='wins-history'

# ═══════════════════════════════════════════════════════════════════
# 4. FOCUS TIMER - Combat time blindness
# ═══════════════════════════════════════════════════════════════════

focus() {
    # Help check FIRST (all three forms)
    if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
        cat <<'EOF'
Usage: focus [duration] [task]

Start a focused work timer (Pomodoro technique).

ARGUMENTS:
  duration    Timer duration in minutes (default: 25)
  task        What you're focusing on (default: current project)

EXAMPLES:
  focus                        # 25-minute pomodoro
  focus 50                     # 50-minute deep work
  focus 25 "write tests"       # 25 min on specific task

ALIASES:
  f25                          # 25-minute pomodoro
  f50                          # 50-minute deep work

See also: timer, win, just-start
EOF
        return 0
    fi

    local duration="${1:-25}"
    local task="${2:-$(basename $PWD)}"

    # Kill any existing timer
    [[ -f /tmp/focus-timer-pid ]] && kill $(cat /tmp/focus-timer-pid) 2>/dev/null
    
    # Clean up old files first
    rm -f /tmp/focus-timer-pid /tmp/focus-session-start /tmp/focus-session-task
    
    # Save session start FIRST (before background process)
    echo "$(date +%s)" > /tmp/focus-session-start
    echo "$task" > /tmp/focus-session-task
    
    echo ""
    echo "┌─────────────────────────────────────────────────────────┐"
    echo "│ 🎯 FOCUS SESSION STARTED                                │"
    echo "├─────────────────────────────────────────────────────────┤"
    echo "│ ⏱️  Duration: $duration minutes"
    echo "│ 📂 Task: $task"
    echo "│ 🕐 Until: $(date -v+${duration}M '+%H:%M')"
    echo "└─────────────────────────────────────────────────────────┘"
    echo ""
    
    # Start background timer using nohup to ensure it survives
    # This creates a detached process that works in subshells too
    nohup zsh -c "
        sleep $((duration * 60))
        osascript -e 'display notification \"$duration minutes done! Take a break.\" with title \"Focus Complete\" sound name \"Glass\"' 2>/dev/null
        say 'Focus session complete. Take a break.' 2>/dev/null
        echo -e '\a'
        echo \"\$(date): Completed $duration min focus on $task\" >> ~/.focus-log
        rm -f /tmp/focus-timer-pid /tmp/focus-session-start /tmp/focus-session-task
    " >/dev/null 2>&1 &
    
    # Save PID immediately
    echo "$!" > /tmp/focus-timer-pid
    
    echo "💡 Commands:"
    echo "   tc    = check elapsed time"
    echo "   fs    = stop timer early"
    echo "   why   = remember what you're doing"
    echo ""
    echo "🚀 GO! You have $duration minutes."
}

# Stop focus timer early
focus-stop() {
    if [[ -f /tmp/focus-timer-pid ]]; then
        kill $(cat /tmp/focus-timer-pid) 2>/dev/null
        
        # Calculate how long we worked
        if [[ -f /tmp/focus-session-start ]]; then
            local start=$(cat /tmp/focus-session-start)
            local now=$(date +%s)
            local elapsed=$(( (now - start) / 60 ))
            local task=$(cat /tmp/focus-session-task 2>/dev/null || echo "focus session")
            
            echo ""
            echo "⏹️  Focus stopped after $elapsed minutes"
            echo "📝 Task: $task"
            
            # Log it
            echo "$(date): Stopped early after $elapsed min on $task" >> ~/.focus-log
            
            # Prompt for win if worked more than 5 min
            if [[ $elapsed -ge 5 ]]; then
                echo ""
                echo "💡 Log this as a win? (y/n)"
                read -q answer
                echo ""
                if [[ "$answer" == "y" ]]; then
                    win "$elapsed min focused work on $task"
                fi
            fi
        fi
        
        rm -f /tmp/focus-timer-pid /tmp/focus-session-start /tmp/focus-session-task
    else
        echo "No active focus session"
    fi
}

# Check elapsed time
time-check() {
    if [[ -f /tmp/focus-session-start ]]; then
        local start=$(cat /tmp/focus-session-start)
        local now=$(date +%s)
        local elapsed=$(( (now - start) / 60 ))
        local task=$(cat /tmp/focus-session-task 2>/dev/null || echo "unknown")
        
        echo ""
        echo "┌─────────────────────────────────────────────────────────┐"
        echo "│ ⏱️  TIME CHECK                                          │"
        echo "├─────────────────────────────────────────────────────────┤"
        echo "│ Elapsed: $elapsed minutes"
        echo "│ Task: $task"
        echo "└─────────────────────────────────────────────────────────┘"
        
        # Gentle reminders based on time
        if [[ $elapsed -ge 90 ]]; then
            echo ""
            echo "⚠️  Over 90 minutes! You should:"
            echo "   • Take a real break (10+ min)"
            echo "   • Eat something if you haven't"
            echo "   • Stand up and stretch"
        elif [[ $elapsed -ge 60 ]]; then
            echo ""
            echo "💡 Over an hour. Consider a short break."
        elif [[ $elapsed -ge 25 ]]; then
            echo ""
            echo "✨ Good focus! Break coming soon."
        fi
    else
        echo "No active focus session."
        echo "Start one with: f25 or focus <minutes>"
    fi
}

# Preset durations - KEEP ONLY HIGH-FREQUENCY (f25, f50)
# alias f15='focus 15'    # REMOVED 2025-12-19
alias f25='focus 25'
alias f50='focus 50'
# alias f90='focus 90'    # REMOVED 2025-12-19
# alias fst='focus-stop'  # REMOVED 2025-12-19: Use 'focus-stop' directly
# alias tc='time-check'   # REMOVED 2025-12-19: Use 'time-check' directly

# Timer dispatcher with smart defaults
_timer_help() {
    cat <<'EOF'
Usage: timer [COMMAND] [DURATION] [TASK]

Smart focus timer with auto-win logging.

COMMANDS:
    (none)          Start 25-min focus session (default)
    focus [MIN]     Start focus session (default: 25 min)
    break [MIN]     Start break timer (default: 5 min)
    status          Show current timer status
    help            Show this help message

EXAMPLES:
    timer                    # 25-min focus + auto-log win
    timer focus              # Same as no args
    timer focus 50           # 50-min focus session
    timer break              # 5-min break
    timer break 10           # 10-min break

ALIASES:
    tc                       # Check elapsed time (time-check)
    fs                       # Stop timer early (focus-stop)

NOTES:
    - Completed focus sessions automatically log as wins
    - Use 'tc' to check elapsed time during session
    - Use 'fs' to stop early (prompts to log as win if >5 min)

EOF
}

timer() {
    # Help check FIRST (all three forms)
    if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
        _timer_help
        return 0
    fi

    local cmd="${1:-focus}"
    local duration="${2:-25}"
    local task="${3:-$(basename $PWD)}"

    case "$cmd" in
        focus|"")
            # Smart default: 25-min pomodoro with auto-win logging
            # Delegate to existing focus() function
            focus "$duration" "$task"
            local focus_result=$?

            # Auto-log win on successful completion
            # The focus() function runs in background, so we can't directly detect completion
            # Instead, we'll monitor the PID file and log when it disappears
            if [[ $focus_result -eq 0 && -f /tmp/focus-timer-pid ]]; then
                # Launch background watcher to auto-log win on completion
                (
                    local pid=$(cat /tmp/focus-timer-pid 2>/dev/null)
                    if [[ -n "$pid" ]]; then
                        # Wait for the timer to complete (PID file removed by focus())
                        while [[ -f /tmp/focus-timer-pid ]]; do
                            sleep 5
                        done
                        # Check if we completed (not stopped early)
                        # If focus completed, the cleanup happens automatically
                        # We'll only log if the session wasn't stopped via focus-stop
                        if ! ps -p $pid >/dev/null 2>&1; then
                            # Timer completed naturally - auto-log win
                            if command -v win >/dev/null 2>&1; then
                                win "Completed ${duration}-min focus on $task" >/dev/null 2>&1
                            fi
                        fi
                    fi
                ) &!  # Run in background, disowned
            fi
            ;;

        break)
            # Break timer (default 5 min)
            duration="${2:-5}"
            echo ""
            echo "☕ Break timer: ${duration} minutes"
            echo "Time to recharge!"
            echo ""

            # Use a simple sleep + notification (no background complexity)
            (
                sleep $((duration * 60))
                osascript -e "display notification \"Break's over! Ready to focus?\" with title \"Break Complete\" sound name \"Glass\"" 2>/dev/null
                say "Break time is over. Ready to get back to work?" 2>/dev/null
                echo -e '\a'
            ) &!

            echo "🔔 Break timer started. Will notify in ${duration} minutes."
            ;;

        status)
            # Show current timer status (delegate to time-check)
            if command -v time-check >/dev/null 2>&1; then
                time-check
            else
                echo "No timer status available"
            fi
            ;;

        *)
            echo "timer: unknown command '$cmd'" >&2
            echo "Run 'timer help' for usage" >&2
            return 1
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════
# 5. MORNING - Daily kickstart routine
# ═══════════════════════════════════════════════════════════════════

morning() {
    local today=$(date +%Y-%m-%d)
    local yesterday=$(date -v-1d +%Y-%m-%d)
    local day_name=$(date +%A)
    
    echo ""
    echo "╔═════════════════════════════════════════════════════════╗"
    echo "║ ☕ GOOD MORNING! $day_name                             ║"
    echo "╚═════════════════════════════════════════════════════════╝"
    echo ""
    
    # ── Yesterday's Wins ──────────────────────────────────────────
    local yesterday_wins="$HOME/.wins/$yesterday.md"
    if [[ -f "$yesterday_wins" ]]; then
        local win_count=$(grep -c "^\-" "$yesterday_wins" 2>/dev/null || echo "0")
        echo "🏆 YESTERDAY'S WINS ($win_count):"
        echo "─────────────────────────────────────────────────────────"
        grep "^\-" "$yesterday_wins" | tail -5 | sed 's/^/   /'
        if [[ $win_count -gt 5 ]]; then
            echo "   ... and $((win_count - 5)) more"
        fi
        echo ""
    else
        echo "💭 No wins logged yesterday (that's okay!)"
        echo ""
    fi
    
    # ── Recent Git Activity ──────────────────────────────────────
    echo "💻 RECENT WORK (last 24h):"
    echo "─────────────────────────────────────────────────────────"
    local found_commits=false
    for pkg_dir in ~/projects/r-packages/active/*/; do
        if [[ -d "$pkg_dir/.git" ]]; then
            local pkg_name=$(basename "$pkg_dir")
            local commits=$(git -C "$pkg_dir" log --oneline --since="24 hours ago" 2>/dev/null | head -3)
            if [[ -n "$commits" ]]; then
                found_commits=true
                echo "   📦 $pkg_name:"
                echo "$commits" | sed 's/^/      /'
            fi
        fi; done
    if [[ "$found_commits" == false ]]; then
        echo "   (no commits in last 24h)"
    fi
    echo ""
    
    # ── Project Statuses ─────────────────────────────────────────
    echo "🎯 PROJECT STATUS:"
    echo "─────────────────────────────────────────────────────────"
    local p0_found=""
    local suggested_project=""
    local suggested_task=""
    
    for status_file in ~/projects/r-packages/active/*/.STATUS; do
        if [[ -f "$status_file" ]]; then
            local pkg_dir=$(dirname "$status_file")
            local pkg_name=$(basename "$pkg_dir")
            local priority=$(grep "^priority:" "$status_file" 2>/dev/null | cut -d: -f2 | tr -d ' ')
            local pkg_status=$(grep "^status:" "$status_file" 2>/dev/null | cut -d: -f2 | tr -d ' ')
            local next_action=$(grep "^next:" "$status_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//')
            
            # Color code by priority
            local icon="•"
            case "$priority" in
                P0) icon="🔴"; p0_found="$pkg_name"; suggested_project="$pkg_name"; suggested_task="$next_action" ;;
                P1) icon="🟡"; [[ -z "$suggested_project" ]] && suggested_project="$pkg_name" && suggested_task="$next_action" ;;
                P2) icon="🟢" ;;
                *)  icon="🔵" ;;
            esac
            
            echo "   $icon $pkg_name ($priority/$pkg_status)"
            [[ -n "$next_action" ]] && echo "      → $next_action"
        fi; done
    echo ""
    
    # ── Suggested First Task ─────────────────────────────────────
    echo "╔═════════════════════════════════════════════════════════╗"
    echo "║ 🚀 SUGGESTED FIRST TASK                               ║"
    echo "╠═════════════════════════════════════════════════════════╣"
    
    if [[ -n "$suggested_project" ]]; then
        echo "║ Project: $suggested_project"
        if [[ -n "$suggested_task" ]]; then
            # Truncate long tasks
            if [[ ${#suggested_task} -gt 50 ]]; then
                suggested_task="${suggested_task:0:47}..."
            fi
            echo "║ Task: $suggested_task"
        fi
        echo "║"
        echo "║ Quick start:"
        echo "║   js              # Jump to it"
        echo "║   work $suggested_project   # Open in preferred editor"
    else
        echo "║ No .STATUS files found with next actions."
        echo "║ Try: js (picks most recent project)"
    fi
    echo "╚═════════════════════════════════════════════════════════╝"
    echo ""
    
    # ── Quick Actions ────────────────────────────────────────────
    echo "💡 QUICK ACTIONS:"
    echo "   js      = jump to suggested project"
    echo "   f25     = start 25-min focus session"
    echo "   wins    = see today's wins so far"
    echo ""
}

# Aliases for morning - REMOVED 2025-12-19: Use 'morning' directly
# alias am='morning'
# alias goodmorning='morning'

# ═══════════════════════════════════════════════════════════════════
# 6. BREADCRUMBS - Working memory aid
# ═══════════════════════════════════════════════════════════════════

# Leave a breadcrumb note (saved to .breadcrumbs in current dir)
breadcrumb() {
    local note="$*"
    
    if [[ -z "$note" ]]; then
        echo "Usage: bc 'your note here'"
        echo "       bc investigating why tests fail"
        echo "       bc left off at line 45"
        return 1
    fi
    
    local timestamp=$(date "+%Y-%m-%d %H:%M")
    local crumbs_file=".breadcrumbs"
    
    # Create file with header if new
    if [[ ! -f "$crumbs_file" ]]; then
        echo "# 🍞 Breadcrumbs for $(basename $PWD)" > "$crumbs_file"
        echo "# Leave notes to your future self" >> "$crumbs_file"
        echo "" >> "$crumbs_file"
    fi
    
    # Add the breadcrumb
    echo "[$timestamp] $note" >> "$crumbs_file"
    
    echo "🍞 Breadcrumb dropped: $note"
}

# View recent breadcrumbs
crumbs() {
    local count="${1:-10}"
    local crumbs_file=".breadcrumbs"
    
    echo ""
    if [[ -f "$crumbs_file" ]]; then
        echo "┌─────────────────────────────────────────────────────────┐"
        echo "│ 🍞 BREADCRUMBS ($(basename $PWD))                         │"
        echo "└─────────────────────────────────────────────────────────┘"
        echo ""
        # Show last N entries (skip header lines)
        grep "^\[" "$crumbs_file" | tail -$count
        echo ""
        
        local total=$(grep -c "^\[" "$crumbs_file" 2>/dev/null || echo "0")
        if [[ $total -gt $count ]]; then
            echo "📝 $total total breadcrumbs (showing last $count)"
            echo "   Use: bcs 20  # to see more"
        fi
    else
        echo "No breadcrumbs in this directory yet."
        echo ""
        echo "💡 Drop one with: bc 'your note'"
        echo "   Examples:"
        echo "   bc 'investigating test failure'"
        echo "   bc 'left off at line 45'"
        echo "   bc 'need to ask about API design'"
    fi
}

# Clear breadcrumbs (with confirmation)
crumbs-clear() {
    local crumbs_file=".breadcrumbs"
    
    if [[ -f "$crumbs_file" ]]; then
        local count=$(grep -c "^\[" "$crumbs_file" 2>/dev/null || echo "0")
        echo "⚠️  About to delete $count breadcrumbs in $(basename $PWD)"
        echo "   Continue? (y/n)"
        read -q answer
        echo ""
        if [[ "$answer" == "y" ]]; then
            rm "$crumbs_file"
            echo "✅ Breadcrumbs cleared"
        else
            echo "Cancelled"
        fi
    else
        echo "No breadcrumbs file to clear"
    fi
}

# Aliases for breadcrumbs - REMOVED 2025-12-19: Use full commands instead
# alias bc='breadcrumb'
# alias bcs='crumbs'
# alias bclear='crumbs-clear'

# ═══════════════════════════════════════════════════════════════════
# 7. WHAT-NEXT - AI-powered task suggestion
# ═══════════════════════════════════════════════════════════════════

what-next() {
    local energy="${1:-normal}"  # low, normal, high
    local time_available="${2:-60}"  # minutes
    
    echo ""
    echo "┌─────────────────────────────────────────────────────────┐"
    echo "│ 🤔 WHAT SHOULD I WORK ON?                              │"
    echo "├─────────────────────────────────────────────────────────┤"
    echo "│ Energy: $energy | Time: ${time_available}min"
    echo "└─────────────────────────────────────────────────────────┘"
    echo ""
    echo "🔍 Scanning projects..."
    echo ""
    
    # Collect all .STATUS info
    local status_info=""
    local project_count=0
    
    for status_file in ~/projects/r-packages/active/*/.STATUS; do
        if [[ -f "$status_file" ]]; then
            local pkg_dir=$(dirname "$status_file")
            local pkg_name=$(basename "$pkg_dir")
            local content=$(cat "$status_file")
            status_info+="\n=== $pkg_name ===\n$content\n"
            ((project_count++))
        fi; done
    
    if [[ $project_count -eq 0 ]]; then
        echo "❌ No .STATUS files found in ~/projects/r-packages/active/"
        return 1
    fi
    
    echo "📦 Found $project_count projects with .STATUS files"
    echo ""
    
    # Check if claude CLI is available
    if ! command -v claude &> /dev/null; then
        echo "⚠️  Claude CLI not found. Falling back to priority-based suggestion..."
        echo ""
        # Simple fallback: find P0 or most recent
        just-start
        return 0
    fi
    
    echo "🤖 Asking Claude for recommendation..."
    echo ""
    
    # Create prompt
    local prompt="Based on these project statuses, suggest ONE specific task I should work on right now.

My context:
- Energy level: $energy
- Time available: $time_available minutes
- Preference: Pick the highest-impact task that matches my energy

Project statuses:
$status_info

Respond with ONLY:
1. Project name
2. Specific task (one sentence)
3. Why this task (one sentence)
4. Estimated time

Be direct and actionable. No fluff."

    # Call Claude CLI
    local suggestion=$(echo "$prompt" | claude --print 2>/dev/null)
    
    if [[ -n "$suggestion" ]]; then
        echo "╔═════════════════════════════════════════════════════════╗"
        echo "║ 🎯 AI RECOMMENDATION                                    ║"
        echo "╠═════════════════════════════════════════════════════════╣"
        echo "$suggestion" | sed 's/^/║ /'
        echo "╚═════════════════════════════════════════════════════════╝"
        echo ""
        echo "💡 Quick start:"
        echo "   js    = jump to highest priority project"
        echo "   f25   = start 25-min focus session"
    else
        echo "⚠️  Could not get AI suggestion. Using fallback..."
        echo ""
        just-start
    fi
}

# Energy-based shortcuts - REMOVED 2025-12-19: Use 'what-next' directly
# alias wn='what-next'
# alias wnl='what-next low 30'      # Low energy, 30 min
# alias wnh='what-next high 90'     # High energy, 90 min
# alias wnq='what-next normal 15'   # Quick task

# ═══════════════════════════════════════════════════════════════════
# 8. WHATNEXT - Fast context-aware suggestions (no AI, instant)
# ═══════════════════════════════════════════════════════════════════

whatnext() {
    echo "🔍 Analyzing current context..."
    echo ""

    local suggestions=()
    local context_type="unknown"
    local pkg_name=""

    # ─── Detect Context (uses shared project-detector) ────────────

    # Source shared detector if available
    local detector="$HOME/.config/zsh/functions/project-detector.zsh"
    if [[ -f "$detector" ]]; then
        source "$detector" 2>/dev/null

        context_type=$(get_project_type 2>/dev/null || echo "unknown")
        pkg_name=$(get_project_name 2>/dev/null || basename "$PWD")
        local icon=$(get_project_icon "$context_type" 2>/dev/null || echo "📁")

        echo "$icon ${pkg_name}"
    else
        # Fallback detection if shared detector not available
        if [[ -f "DESCRIPTION" ]]; then
            context_type="rpkg"
            pkg_name=$(grep "^Package:" DESCRIPTION 2>/dev/null | cut -d' ' -f2)
            echo "📦 R Package: $pkg_name"
        elif [[ -f "_quarto.yml" ]]; then
            context_type="quarto"
            echo "📄 Quarto Project"
        elif [[ -d ".git" ]]; then
            context_type="project"
            echo "📁 Git Repository"
        else
            echo "📁 Directory: $(basename $PWD)"
        fi
    fi

    echo ""

    # ─── Git Status Check ─────────────────────────────────────────

    if [[ -d ".git" ]] || git rev-parse --git-dir &>/dev/null 2>&1; then
        local git_status=$(git status --porcelain 2>/dev/null)
        local git_ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
        local git_behind=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo "0")

        if [[ -n "$git_status" ]]; then
            local modified=$(echo "$git_status" | grep -c "^ M\|^M " || true)
            local untracked=$(echo "$git_status" | grep -c "^??" || true)
            local staged=$(echo "$git_status" | grep -c "^[MADRC]" || true)

            echo "📊 Git Status:"
            [[ $modified -gt 0 ]] && echo "   • $modified modified files"
            [[ $untracked -gt 0 ]] && echo "   • $untracked untracked files"
            [[ $staged -gt 0 ]] && echo "   • $staged staged for commit"
            [[ $git_ahead -gt 0 ]] && echo "   • $git_ahead commits ahead (need push)"
            [[ $git_behind -gt 0 ]] && echo "   • $git_behind commits behind (need pull)"
            echo ""
        fi
    fi

    # ─── Context-Specific Suggestions ─────────────────────────────

    echo "💡 Suggested Actions:"
    echo ""

    case "$context_type" in
        rpkg)
            # R Package - check state and suggest actions
            local has_changes=$(git status --porcelain 2>/dev/null | head -1)

            if [[ -n "$has_changes" ]]; then
                # Has uncommitted changes
                if [[ -d "tests/testthat" ]]; then
                    echo "   1. 🧪 Run tests first:     t  (or rtest)"
                    suggestions+=("t")
                fi
                echo "   2. 📝 Document changes:    dt (doc + test)"
                echo "   3. 🔄 Full check:          rcycle"
                echo "   4. 💾 Quick commit:        qcommit 'message'"
            else
                # Clean state
                echo "   1. ▶️  Start coding - you're all clean!"
                echo "   2. 📋 Check project status: rpkg"
                echo "   3. 🔍 Review TODO items:    grep -r TODO R/"
            fi

            # Check for common issues
            if [[ ! -f "NEWS.md" ]]; then
                echo ""
                echo "   ⚠️  Missing NEWS.md - consider adding changelog"
            fi
            if [[ ! -f "README.md" ]] && [[ ! -f "README.Rmd" ]]; then
                echo "   ⚠️  Missing README - consider adding documentation"
            fi
            ;;

        quarto|quarto-ext)
            echo "   1. 👁️  Preview:    qp (quarto preview)"
            echo "   2. 🔨 Render:     qr (quarto render)"
            echo "   3. ✅ Check:      qc (quarto check)"
            ;;

        research)
            echo "   1. 📝 Edit manuscript: open main.tex / manuscript.tex"
            echo "   2. 📚 Review literature: ls literature/"
            echo "   3. 🔗 Check references: bibtex references.bib"
            ;;

        project)
            local has_changes=$(git status --porcelain 2>/dev/null | head -1)
            if [[ -n "$has_changes" ]]; then
                echo "   1. 👀 Review changes:   git diff"
                echo "   2. 💾 Stage all:        git add ."
                echo "   3. 📝 Commit:           qcommit 'message'"
            else
                echo "   1. ▶️  Start coding - repo is clean!"
                echo "   2. 🔄 Pull latest:      git pull"
            fi
            ;;

        *)
            echo "   1. 📂 List files:    ls -la"
            echo "   2. 🔍 Find project:  cd ~/projects"
            echo "   3. 🎲 Pick a task:   js (just-start)"
            ;;
    esac

    # ─── .STATUS File Check ───────────────────────────────────────

    if [[ -f ".STATUS" ]]; then
        echo ""
        echo "📋 From .STATUS:"
        # Extract NEXT ACTIONS or similar
        local next_action=$(grep -A2 "NEXT\|Next\|TODO" .STATUS 2>/dev/null | head -3)
        if [[ -n "$next_action" ]]; then
            echo "$next_action" | sed 's/^/   /'
        fi
    fi

    echo ""
    echo "─────────────────────────────────────────────"
    echo "💡 Quick: wn = AI suggestions | js = jump to project"
}

# Alias - REMOVED 2025-12-19: Use 'whatnext' directly
# alias wnow='whatnext'

# ═══════════════════════════════════════════════════════════════════
# 9. WORKFLOW STATE TRACKING - Log actions, view history
# ═══════════════════════════════════════════════════════════════════

# Configuration
WORKFLOW_LOG="${WORKFLOW_LOG:-$HOME/.workflow-log}"
WORKFLOW_SESSION_FILE="${WORKFLOW_SESSION_FILE:-$HOME/.workflow-session}"

# Log a workflow action
worklog() {
    local action="$1"
    local details="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local project=$(basename "$PWD")
    local session_id=$(cat "$WORKFLOW_SESSION_FILE" 2>/dev/null || echo "none")

    if [[ -z "$action" ]]; then
        echo "Usage: worklog <action> [details]"
        echo "Examples:"
        echo "  worklog 'started coding' 'implementing new feature'"
        echo "  worklog 'ran tests' 'all passing'"
        echo "  worklog 'commit' 'fixed bug in parser'"
        return 1
    fi

    # Log format: timestamp | session | project | action | details
    echo "$timestamp | $session_id | $project | $action | $details" >> "$WORKFLOW_LOG"
    echo "📝 Logged: $action"
}

# Aliases for quick logging - REMOVED 2025-12-19: Use 'worklog' directly
# alias wl='worklog'
# alias wls='worklog "started"'
# alias wld='worklog "done"'
# alias wlb='worklog "blocked"'
# alias wlp='worklog "paused"'

# Show recent workflow activity
showflow() {
    local lines="${1:-20}"
    local filter="$2"

    if [[ ! -f "$WORKFLOW_LOG" ]]; then
        echo "📋 No workflow log found yet."
        echo "   Start logging with: worklog 'action' 'details'"
        return 0
    fi

    echo "📊 Recent Workflow Activity"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""

    if [[ -n "$filter" ]]; then
        echo "🔍 Filtered by: $filter"
        echo ""
        tail -n 100 "$WORKFLOW_LOG" | grep -i "$filter" | tail -n "$lines" | while IFS='|' read -r ts session proj action details; do
            # Format: time | project | action
            local time_only=$(echo "$ts" | awk '{print $2}')
            printf "  %s │ %-15s │ %s\n" "$time_only" "$(echo $proj | xargs)" "$(echo $action | xargs)"
            [[ -n "$(echo $details | xargs)" ]] && printf "         │                 │ └─ %s\n" "$(echo $details | xargs)"; done
    else
        tail -n "$lines" "$WORKFLOW_LOG" | while IFS='|' read -r ts session proj action details; do
            local time_only=$(echo "$ts" | awk '{print $2}')
            printf "  %s │ %-15s │ %s\n" "$time_only" "$(echo $proj | xargs)" "$(echo $action | xargs)"
            [[ -n "$(echo $details | xargs)" ]] && printf "         │                 │ └─ %s\n" "$(echo $details | xargs)"; done
    fi

    echo ""
    echo "═══════════════════════════════════════════════════════════════"

    # Show summary stats
    local today=$(date "+%Y-%m-%d")
    local today_count=$(grep -c "^$today" "$WORKFLOW_LOG" 2>/dev/null || echo "0")
    local total_count=$(wc -l < "$WORKFLOW_LOG" 2>/dev/null | xargs)

    echo "📈 Today: $today_count actions | Total: $total_count actions"
    echo ""
    echo "💡 Commands: showflow [n] [filter] | worklog 'action' 'details'"
}

# Aliases - REMOVED 2025-12-19: Use 'showflow' directly
# alias sf='showflow'
# alias sft='showflow 50'           # Show more
# alias sfd='showflow 20 "$(date +%Y-%m-%d)"'  # Today only

# Start a workflow session
startsession() {
    local session_name="${1:-$(date +%H%M)}"
    local session_id="${session_name}-$$"

    echo "$session_id" > "$WORKFLOW_SESSION_FILE"
    worklog "session-start" "$session_name"

    # Integrate with iTerm2 if available
    if type iterm_session_start &>/dev/null; then
        iterm_session_start "$session_name"
    fi

    echo "🚀 Session started: $session_id"
    echo "   All workflow logs will be tagged with this session"
    echo ""
    echo "💡 End with: endsession"
}

# End a workflow session
endsession() {
    if [[ ! -f "$WORKFLOW_SESSION_FILE" ]]; then
        echo "⚠️  No active session"
        return 1
    fi

    local session_id=$(cat "$WORKFLOW_SESSION_FILE")
    local session_start=$(grep "$session_id.*session-start" "$WORKFLOW_LOG" 2>/dev/null | head -1 | cut -d'|' -f1)

    worklog "session-end" "completed"

    # Calculate session duration if we can find the start
    if [[ -n "$session_start" ]]; then
        local start_ts=$(date -j -f "%Y-%m-%d %H:%M:%S" "$(echo $session_start | xargs)" "+%s" 2>/dev/null)
        local end_ts=$(date "+%s")
        if [[ -n "$start_ts" ]]; then
            local duration=$(( (end_ts - start_ts) / 60 ))
            echo "⏱️  Session duration: ${duration} minutes"
        fi
    fi

    # Count actions in this session
    local action_count=$(grep -c "$session_id" "$WORKFLOW_LOG" 2>/dev/null || echo "0")

    rm -f "$WORKFLOW_SESSION_FILE"

    # Integrate with iTerm2 if available
    if type iterm_session_end &>/dev/null; then
        iterm_session_end
    fi

    echo "✅ Session ended: $session_id"
    echo "   Actions logged: $action_count"
}

# Show current session info
sessioninfo() {
    if [[ -f "$WORKFLOW_SESSION_FILE" ]]; then
        local session_id=$(cat "$WORKFLOW_SESSION_FILE")
        local action_count=$(grep -c "$session_id" "$WORKFLOW_LOG" 2>/dev/null || echo "0")
        echo "📋 Active session: $session_id"
        echo "   Actions logged: $action_count"
    else
        echo "📋 No active session"
        echo "   Start one with: startsession [name]"
    fi
}

# Auto-log wrapper for common commands
# Usage: logged <command> [args...]
logged() {
    local cmd="$1"
    shift

    worklog "$cmd" "$*"
    "$cmd" "$@"
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        worklog "$cmd-done" "success"
    else
        worklog "$cmd-failed" "exit code: $exit_code"
    fi

    return $exit_code
}

# Quick stats for today
flowstats() {
    local today=$(date "+%Y-%m-%d")

    echo "📊 Today's Workflow Stats ($today)"
    echo "═══════════════════════════════════════"

    if [[ ! -f "$WORKFLOW_LOG" ]]; then
        echo "No logs yet. Start with: worklog 'action'"
        return 0
    fi

    local today_logs=$(grep "^$today" "$WORKFLOW_LOG" 2>/dev/null)

    if [[ -z "$today_logs" ]]; then
        echo "No activity logged today yet."
        return 0
    fi

    # Count by project
    echo ""
    echo "By Project:"
    echo "$today_logs" | cut -d'|' -f3 | sort | uniq -c | sort -rn | head -5 | while read count proj; do
        printf "   %-20s %d actions\n" "$(echo $proj | xargs)" "$count"; done

    # Count by action type
    echo ""
    echo "By Action:"
    echo "$today_logs" | cut -d'|' -f4 | sort | uniq -c | sort -rn | head -5 | while read count action; do
        printf "   %-20s %d times\n" "$(echo $action | xargs)" "$count"; done

    # Time span
    local first_time=$(echo "$today_logs" | head -1 | cut -d'|' -f1 | awk '{print $2}')
    local last_time=$(echo "$today_logs" | tail -1 | cut -d'|' -f1 | awk '{print $2}')
    local total_actions=$(echo "$today_logs" | wc -l | xargs)

    echo ""
    echo "═══════════════════════════════════════"
    echo "⏰ First: $first_time | Last: $last_time"
    echo "📝 Total actions: $total_actions"
}

# REMOVED 2025-12-19: Use 'flowstats' directly
# alias fls='flowstats'

# ═══════════════════════════════════════════════════════════════════
# 10. DASHBOARD INTEGRATION - Sync with Apple Notes
# ═══════════════════════════════════════════════════════════════════

# Quick dashboard sync (uses apple-notes-sync project)
dashsync() {
    local apple_notes_dir="$HOME/projects/dev-tools/apple-notes-sync"

    if [[ ! -d "$apple_notes_dir" ]]; then
        echo "⚠️  apple-notes-sync not found at $apple_notes_dir"
        return 1
    fi

    echo "📊 Syncing dashboard to Apple Notes..."
    worklog "dashboard-sync" "updating Apple Notes"

    # Run scanner then AppleScript update
    (
        cd "$apple_notes_dir"
        ./scanner.sh && ./dashboard-applescript.sh
    )
}

# Alias - REMOVED 2025-12-19: Use 'dashsync' directly
# alias ds='dashsync'

# ═══════════════════════════════════════════════════════════════════
# WEEKLY SYNC - Multi-Project Review Ritual
# ═══════════════════════════════════════════════════════════════════

weeklysync() {
    local JSON_FILE="/tmp/project-status.json"
    local SCANNER="$HOME/projects/dev-tools/apple-notes-sync/scanner.sh"

    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  📊 WEEKLY PROJECT SYNC                                    ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    # Run scanner first
    if [[ -f "$SCANNER" ]]; then
        "$SCANNER" >/dev/null 2>&1
    fi

    if [[ ! -f "$JSON_FILE" ]] || ! command -v jq &>/dev/null; then
        echo "❌ Need scanner output and jq installed"
        return 1
    fi

    local today=$(date "+%Y-%m-%d")
    local week_ago=$(date -v-7d "+%Y-%m-%d" 2>/dev/null || date -d "7 days ago" "+%Y-%m-%d")
    local two_weeks_ago=$(date -v-14d "+%Y-%m-%d" 2>/dev/null || date -d "14 days ago" "+%Y-%m-%d")

    # Count stats
    local total=$(jq -r '.projects | length' "$JSON_FILE")
    local p0_count=$(jq -r '[.projects[] | select(.priority == "P0")] | length' "$JSON_FILE")
    local p1_count=$(jq -r '[.projects[] | select(.priority == "P1")] | length' "$JSON_FILE")
    local blocked=$(jq -r '[.projects[] | select(.blocked != "" and .blocked != "None")] | length' "$JSON_FILE")

    echo "📈 Overview: $total projects | 🔴 P0: $p0_count | 🟡 P1: $p1_count | ⛔ Blocked: $blocked"
    echo ""

    # Show P0 first (needs attention)
    if [[ $p0_count -gt 0 ]]; then
        echo "🔴 P0 - PRIORITY (needs attention)"
        echo "────────────────────────────────────────"
        jq -r '.projects[] | select(.priority == "P0") | "  \(.name) [\(.progress)%] → \(.next)"' "$JSON_FILE"
        echo ""
    fi

    # Show blocked projects
    if [[ $blocked -gt 0 ]]; then
        echo "⛔ BLOCKED"
        echo "────────────────────────────────────────"
        jq -r '.projects[] | select(.blocked != "" and .blocked != "None") | "  \(.name): \(.blocked)"' "$JSON_FILE"
        echo ""
    fi

    # Show P1 projects
    if [[ $p1_count -gt 0 ]]; then
        echo "🟡 P1 - ACTIVE"
        echo "────────────────────────────────────────"
        jq -r '.projects[] | select(.priority == "P1") | "  \(.name) [\(.progress)%] → \(.next)"' "$JSON_FILE"
        echo ""
    fi

    # Show P2 projects (compact view)
    local p2_count=$(jq -r '[.projects[] | select(.priority == "P2")] | length' "$JSON_FILE")
    if [[ $p2_count -gt 0 ]]; then
        echo "🟢 P2 - QUEUED ($p2_count projects)"
        echo "────────────────────────────────────────"
        jq -r '.projects[] | select(.priority == "P2") | "  \(.name) [\(.progress)%]"' "$JSON_FILE" | paste - - - 2>/dev/null || \
        jq -r '.projects[] | select(.priority == "P2") | "  \(.name) [\(.progress)%]"' "$JSON_FILE"
        echo ""
    fi

    # Stale project detection (not updated in 14+ days)
    local stale_projects=$(jq -r --arg cutoff "$two_weeks_ago" \
        '.projects[] | select(.updated < $cutoff) | .name' "$JSON_FILE" 2>/dev/null)
    if [[ -n "$stale_projects" ]]; then
        local stale_count=$(echo "$stale_projects" | wc -l | xargs)
        echo "⚠️  STALE ($stale_count not updated in 14+ days)"
        echo "────────────────────────────────────────"
        while read -r name; do
            local updated=$(jq -r --arg n "$name" '.projects[] | select(.name == $n) | .updated' "$JSON_FILE")
            echo "  $name (last: $updated)"
        done <<< "$stale_projects"
        echo ""
    fi

    # Quick actions menu
    echo "────────────────────────────────────────"
    echo "⚡ Quick Actions:"
    echo "   sp <proj> <%%>   Quick progress update"
    echo "   su <project>     Interactive .STATUS update"
    echo "   work <project>   Switch to project"
    echo "   ds               Sync to Apple Notes"
    echo ""

    # Log the weekly sync
    if type worklog &>/dev/null; then
        worklog "weekly-sync" "reviewed $total projects"
    fi
}

# Quick status update for a project
statusupdate() {
    local project="${1:-}"
    local status_file=""

    # Find project .STATUS file
    if [[ -z "$project" ]]; then
        # Use current directory
        if [[ -f ".STATUS" ]]; then
            status_file=".STATUS"
            project=$(basename "$PWD")
        else
            echo "Usage: statusupdate <project-name>"
            echo "   or: cd to project and run 'su'"
            return 1
        fi
    else
        # Search for project
        for base in "$HOME/projects/r-packages/active" "$HOME/projects/dev-tools"; do
            if [[ -f "$base/$project/.STATUS" ]]; then
                status_file="$base/$project/.STATUS"
                break
            fi; done
    fi

    if [[ -z "$status_file" || ! -f "$status_file" ]]; then
        echo "❌ No .STATUS file found for: $project"
        return 1
    fi

    echo ""
    echo "📝 Updating: $project"
    echo "   File: $status_file"
    echo "────────────────────────────────────────"

    # Show current values
    local cur_priority=$(grep -i "^Priority:" "$status_file" 2>/dev/null | cut -d: -f2 | xargs || echo "P2")
    local cur_progress=$(grep -i "^Progress:" "$status_file" 2>/dev/null | cut -d: -f2 | xargs || echo "0")
    local cur_next=$(grep -i "^Next:" "$status_file" 2>/dev/null | cut -d: -f2- | xargs || echo "")

    echo "Current: Priority=$cur_priority Progress=$cur_progress%"
    echo "Next: $cur_next"
    echo ""

    # Interactive update
    echo -n "New progress (0-100) [$cur_progress]: "
    read -r new_progress
    [[ -z "$new_progress" ]] && new_progress="$cur_progress"

    echo -n "New priority (P0/P1/P2) [$cur_priority]: "
    read -r new_priority
    [[ -z "$new_priority" ]] && new_priority="$cur_priority"

    echo -n "Next action [$cur_next]: "
    read -r new_next
    [[ -z "$new_next" ]] && new_next="$cur_next"

    # Update the file
    local today=$(date "+%Y-%m-%d")

    # Use sed to update in place
    sed -i '' "s/^Priority:.*/Priority: $new_priority/" "$status_file" 2>/dev/null
    sed -i '' "s/^Progress:.*/Progress: $new_progress/" "$status_file" 2>/dev/null
    sed -i '' "s/^Next:.*/Next: $new_next/" "$status_file" 2>/dev/null

    # Update the LAST UPDATED timestamp
    if grep -q "^⏰ LAST UPDATED" "$status_file"; then
        # Find the line after "LAST UPDATED" and update the date
        sed -i '' "/^⏰ LAST UPDATED/,/^$/{s/^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].*/$today/;}" "$status_file" 2>/dev/null
    fi

    echo ""
    echo "✅ Updated $project"
    echo "   Priority: $new_priority | Progress: $new_progress% | Next: $new_next"

    # Log the update
    if type worklog &>/dev/null; then
        worklog "status-update" "$project → $new_progress% $new_priority"
    fi
}

# Quick progress update (non-interactive)
# Usage: sp <project> <progress> [priority]
setprogress() {
    local project="${1:-}"
    local progress="${2:-}"
    local priority="${3:-}"

    if [[ -z "$project" || -z "$progress" ]]; then
        echo "Usage: sp <project> <progress> [priority]"
        echo "Example: sp medrobust 75"
        echo "Example: sp medrobust 75 P0"
        return 1
    fi

    # Find project .STATUS file
    local status_file=""
    for base in "$HOME/projects/r-packages/active" "$HOME/projects/dev-tools"; do
        if [[ -f "$base/$project/.STATUS" ]]; then
            status_file="$base/$project/.STATUS"
            break
        fi; done

    if [[ -z "$status_file" ]]; then
        echo "❌ No .STATUS file found for: $project"
        return 1
    fi

    local today=$(date "+%Y-%m-%d")

    # Update progress
    sed -i '' "s/^Progress:.*/Progress: $progress/" "$status_file" 2>/dev/null

    # Update priority if provided
    if [[ -n "$priority" ]]; then
        sed -i '' "s/^Priority:.*/Priority: $priority/" "$status_file" 2>/dev/null
    fi

    # Update timestamp
    if grep -q "^⏰ LAST UPDATED" "$status_file"; then
        sed -i '' "/^⏰ LAST UPDATED/,/^$/{s/^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].*/$today/;}" "$status_file" 2>/dev/null
    fi

    # Show result
    if [[ -n "$priority" ]]; then
        echo "✅ $project → $progress% ($priority)"
    else
        echo "✅ $project → $progress%"
    fi

    # Log
    if type worklog &>/dev/null; then
        worklog "progress" "$project → $progress%"
    fi
}

# Project notes sync to Apple Notes folder
projectnotes() {
    local script="$HOME/projects/dev-tools/apple-notes-sync/project-notes.sh"

    if [[ ! -f "$script" ]]; then
        echo "❌ project-notes.sh not found"
        return 1
    fi

    if [[ -z "${1:-}" ]]; then
        # Sync all
        "$script" --all
    else
        # Sync specific project
        "$script" "$1"
    fi

    # Log
    if type worklog &>/dev/null; then
        worklog "notes-sync" "${1:-all projects}"
    fi
}

# Mediationverse ecosystem report
mediationverse_report() {
    local script="$HOME/projects/dev-tools/apple-notes-sync/mediationverse-report.sh"

    if [[ ! -f "$script" ]]; then
        echo "❌ mediationverse-report.sh not found"
        return 1
    fi

    "$script" "$@"

    # Log
    if type worklog &>/dev/null; then
        worklog "mediationverse-report" "ecosystem status check"
    fi
}

# Mediationverse sync to Apple Notes
mediationverse_sync() {
    local script="$HOME/projects/dev-tools/apple-notes-sync/mediationverse-report.sh"

    if [[ ! -f "$script" ]]; then
        echo "❌ mediationverse-report.sh not found"
        return 1
    fi

    "$script" --sync

    # Log
    if type worklog &>/dev/null; then
        worklog "mediationverse-sync" "synced to Apple Notes"
    fi
}

# Aliases - REMOVED 2025-12-19: Use full commands instead
# alias ws='weeklysync'
# alias su='statusupdate'
# alias sp='setprogress'
# alias pn='projectnotes'
# alias mvr='mediationverse_report'
# alias mvs='mediationverse_sync'

# ─────────────────────────────────────────────────────────────
# Mediationverse Git Workflow Aliases
# ─────────────────────────────────────────────────────────────
MV_PACKAGES=(medfit mediationverse medrobust medsim probmed)
MV_DIR="$HOME/projects/r-packages/active"

# mvcd PKG - cd to package directory
mvcd() {
    local pkg="$1"
    if [[ -z "$pkg" ]]; then
        echo "Usage: mvcd <package>"; return 1
    fi
    cd "$MV_DIR/$pkg"
}

# mvst [PKG] - git status for mediationverse packages
# Shows: uncommitted changes, branch info, ahead/behind status
mvst() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  📊 MEDIATIONVERSE STATUS                                  ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    local packages=("${MV_PACKAGES[@]}")
    [[ -n "$1" ]] && packages=("$1")

    local total_changes=0
    local clean_count=0

    for p in "${packages[@]}"; do
        local dir="$MV_DIR/$p"
        [[ ! -d "$dir/.git" ]] && continue

        # Use subshell to avoid changing cwd
        local info=$(cd "$dir" && {
            local branch=$(git branch --show-current 2>/dev/null || echo "?")
            local changes=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
            local staged=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
            local unstaged=$(git diff --numstat 2>/dev/null | wc -l | tr -d ' ')
            local untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
            local ahead=0 behind=0
            if git rev-parse --verify main &>/dev/null && git rev-parse --verify dev &>/dev/null; then
                ahead=$(git rev-list --count main..dev 2>/dev/null || echo 0)
                behind=$(git rev-list --count dev..main 2>/dev/null || echo 0)
            fi
            local files=$(git status --porcelain 2>/dev/null | head -5)
            echo "$branch|$changes|$staged|$unstaged|$untracked|$ahead|$behind|$files"
        })

        IFS='|' read -r branch changes staged unstaged untracked ahead behind files <<< "$info"

        # Status icon
        local icon="✅"
        if [[ $changes -gt 0 ]]; then
            icon="⚠️"
            ((total_changes += changes))
        else
            ((clean_count++))
        fi

        # Package header
        printf "  %-15s %s [%s]" "$p" "$icon" "$branch"

        # Branch status
        if [[ $ahead -gt 0 ]]; then
            printf " 🔶 dev +%d ahead" "$ahead"
        fi
        if [[ $behind -gt 0 ]]; then
            printf " 🔄 dev %d behind" "$behind"
        fi
        echo ""

        # Show details if changes exist
        if [[ $changes -gt 0 ]]; then
            [[ $staged -gt 0 ]] && echo "                    📦 $staged staged"
            [[ $unstaged -gt 0 ]] && echo "                    ✏️  $unstaged modified"
            [[ $untracked -gt 0 ]] && echo "                    ❓ $untracked untracked"
            # Show actual files
            echo "$files" | while read -r line; do
                [[ -n "$line" ]] && echo "                       $line"; done
            local more=$((changes - 5))
            [[ $more -gt 0 ]] && echo "                       ... +$more more"
        fi; done

    # Summary
    echo ""
    echo "────────────────────────────────────────"
    if [[ $total_changes -eq 0 ]]; then
        echo "  ✅ All ${clean_count} packages clean!"
    else
        echo "  📝 $total_changes total changes across $((${#packages[@]} - clean_count)) package(s)"
    fi
    echo ""
}

# mvci PKG [MSG] - git add & commit
mvci() {
    local pkg="$1" msg="${2:-WIP}"
    if [[ -z "$pkg" ]]; then
        echo "Usage: mvci <package> [message]"; return 1
    fi
    (cd "$MV_DIR/$pkg" && git add -A && git commit -m "$msg")
}

# mvpush PKG - git push
mvpush() {
    local pkg="$1"
    if [[ -z "$pkg" ]]; then
        echo "Usage: mvpush <package>"; return 1
    fi
    (cd "$MV_DIR/$pkg" && git push)
}

# mvpull [PKG] - git pull (one or all)
mvpull() {
    if [[ -n "$1" ]]; then
        (cd "$MV_DIR/$1" && git pull)
    else
        for p in "${MV_PACKAGES[@]}"; do
            echo "=== $p ==="
            (cd "$MV_DIR/$p" && git pull); done
    fi
}

# mvmerge PKG - merge dev to main
mvmerge() {
    local pkg="$1"
    if [[ -z "$pkg" ]]; then
        echo "Usage: mvmerge <package>"; return 1
    fi
    (cd "$MV_DIR/$pkg" && git checkout main && git merge dev && echo "✅ Merged dev → main")
}

# mvrebase PKG - rebase dev on main (update stale dev)
mvrebase() {
    local pkg="$1"
    if [[ -z "$pkg" ]]; then
        echo "Usage: mvrebase <package>"; return 1
    fi
    (cd "$MV_DIR/$pkg" && git checkout dev && git rebase main && echo "✅ Rebased dev on main")
}

# mvdev PKG - checkout or create dev branch
mvdev() {
    local pkg="$1"
    if [[ -z "$pkg" ]]; then
        echo "Usage: mvdev <package>"; return 1
    fi
    (cd "$MV_DIR/$pkg" && git checkout dev 2>/dev/null || git checkout -b dev)
}

# ═══════════════════════════════════════════════════════════════════════════════
# UNIVERSAL PROJECT WORKFLOW (Option D + E Hybrid)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Session Commands:    work, done, now, next
# Navigation:          pp (picker), pcd
# Context-Aware:       pt (test), pb (build), pc (commit)
# Dashboards:          dash, dash r, dash dt
#
# ═══════════════════════════════════════════════════════════════════════════════

# ─────────────────────────────────────────────────────────────
# Project Configuration
# ─────────────────────────────────────────────────────────────
PROJ_BASE="$HOME/projects"
PROJ_CATEGORIES=(
    "r-packages/active:r:📦"
    "r-packages/stable:r:📦"
    "dev-tools:dev:🔧"
    "teaching:teach:🎓"
    "research:rs:🔬"
    "quarto/manuscripts:q:📝"
    "quarto/presentations:q:📊"
    "apps:app:📱"
)

# Session state file
PROJ_SESSION_FILE="$HOME/.current-project-session"

# ─────────────────────────────────────────────────────────────
# Project Detection Helpers
# ─────────────────────────────────────────────────────────────

# Detect project type from directory
_proj_detect_type() {
    local dir="${1:-$(pwd)}"

    # Check path-based detection first (teaching/research folders)
    if [[ "$dir" == */projects/teaching/* ]]; then
        echo "teaching"
    elif [[ "$dir" == */projects/research/* ]]; then
        # Research with LaTeX
        if [[ -f "$dir/main.tex" ]]; then
            echo "research-tex"
        # Research with Quarto
        elif [[ -f "$dir/_quarto.yml" ]]; then
            echo "research-qmd"
        else
            echo "research"
        fi
    # File-based detection
    elif [[ -f "$dir/DESCRIPTION" ]]; then
        echo "r"
    elif [[ -f "$dir/package.json" ]]; then
        echo "node"
    elif [[ -f "$dir/_quarto.yml" || -f "$dir/index.qmd" ]]; then
        echo "quarto"
    elif [[ -f "$dir/Makefile" ]]; then
        echo "make"
    elif [[ -f "$dir/setup.py" || -f "$dir/pyproject.toml" ]]; then
        echo "python"
    elif [[ -f "$dir/.Rproj" ]]; then
        echo "r"
    else
        echo "generic"
    fi
}

# Get project name from path
_proj_name_from_path() {
    local path="$1"
    echo "${path:t}"  # zsh parameter expansion for basename
}

# Find project by fuzzy name
_proj_find() {
    local query="$1"
    local category="${2:-}"

    local results=()

    for cat_info in "${PROJ_CATEGORIES[@]}"; do
        local cat_path="${cat_info%%:*}"
        local cat_type="${cat_info#*:}"
        cat_type="${cat_type%%:*}"
        local full_path="$PROJ_BASE/$cat_path"

        # Skip if category filter doesn't match
        if [[ -n "$category" && "$cat_type" != "$category" ]]; then
            continue
        fi

        if [[ -d "$full_path" ]]; then
            # Use nullglob to handle empty directories
            setopt local_options nullglob
            for proj_dir in "$full_path"/*/; do
                [[ -d "$proj_dir" ]] || continue
                local proj_name=$(basename "$proj_dir")

                # Fuzzy match
                if [[ "$proj_name" == *"$query"* ]]; then
                    echo "$proj_dir"
                    return 0
                fi; done
        fi; done

    return 1
}

# List all projects
_proj_list_all() {
    local category="${1:-}"

    for cat_info in "${PROJ_CATEGORIES[@]}"; do
        local cat_path="${cat_info%%:*}"
        local cat_type="${cat_info#*:}"
        cat_type="${cat_type%%:*}"
        local cat_icon="${cat_info##*:}"
        local full_path="$PROJ_BASE/$cat_path"

        # Skip if category filter doesn't match
        if [[ -n "$category" && "$cat_type" != "$category" ]]; then
            continue
        fi

        if [[ -d "$full_path" ]]; then
            # Use nullglob to handle empty directories
            setopt local_options nullglob
            for proj_dir in "$full_path"/*/; do
                [[ -d "$proj_dir/.git" ]] || continue
                local proj_name=$(basename "$proj_dir")
                echo "$proj_name|$cat_type|$cat_icon|$proj_dir"; done
        fi; done
}

# Get project status (git info)
_proj_git_status() {
    local dir="$1"

    if [[ ! -d "$dir/.git" ]]; then
        echo "no-git|0|0|0"
        return
    fi

    # Use git -C to avoid triggering chpwd hooks (iTerm2 integration, etc.)
    local branch=$(git -C "$dir" branch --show-current 2>/dev/null || echo "?")
    local changes=$(git -C "$dir" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    local ahead=0 behind=0

    if git -C "$dir" rev-parse --verify main &>/dev/null; then
        if git -C "$dir" rev-parse --verify dev &>/dev/null; then
            ahead=$(git -C "$dir" rev-list --count main..dev 2>/dev/null || echo 0)
            behind=$(git -C "$dir" rev-list --count dev..main 2>/dev/null || echo 0)
        fi
    fi

    echo "$branch|$changes|$ahead|$behind"
}

# ─────────────────────────────────────────────────────────────
# Domain Context Helpers (for smart work command)
# ─────────────────────────────────────────────────────────────

# Show teaching-specific context
_show_teaching_context() {
    local dir="${1:-$(pwd)}"

    echo "  🎓 TEACHING CONTEXT"
    echo "  ─────────────────────────────────"

    # Calculate current week (assuming fall semester starts late August)
    local week_num=$(( ($(date +%W) - 34 + 52) % 52 ))
    [[ $week_num -lt 1 ]] && week_num=1
    [[ $week_num -gt 16 ]] && week_num=16
    echo "  📅 Week: $week_num of 16"

    # Show .STATUS next action if available
    if [[ -f "$dir/.STATUS" ]]; then
        local next=$(grep -i "^next:" "$dir/.STATUS" 2>/dev/null | cut -d: -f2- | xargs)
        [[ -n "$next" ]] && echo "  📋 Next: $next"
    fi

    # Show recent lecture/slide files
    local recent_file=$(find "$dir" -name "*.qmd" -type f -mtime -7 2>/dev/null | head -1)
    if [[ -n "$recent_file" ]]; then
        echo "  📝 Recent: ${recent_file:t}"
    fi
    echo ""
}

# Show research-specific context
_show_research_context() {
    local dir="${1:-$(pwd)}"
    local proj_type="${2:-research}"

    echo "  🔬 RESEARCH CONTEXT"
    echo "  ─────────────────────────────────"

    # Show manuscript type
    if [[ "$proj_type" == "research-tex" ]]; then
        echo "  📄 Type: LaTeX manuscript"
        # Show main.tex word count estimate
        if [[ -f "$dir/main.tex" ]]; then
            local words=$(cat "$dir/main.tex" 2>/dev/null | wc -w | tr -d ' ')
            echo "  📊 ~$words words"
        fi
    elif [[ "$proj_type" == "research-qmd" ]]; then
        echo "  📄 Type: Quarto manuscript"
    fi

    # Show .STATUS info
    if [[ -f "$dir/.STATUS" ]]; then
        local proj_status=$(grep -i "^status:" "$dir/.STATUS" 2>/dev/null | cut -d: -f2- | xargs)
        local next_action=$(grep -i "^next:" "$dir/.STATUS" 2>/dev/null | cut -d: -f2- | xargs)
        local target_journal=$(grep -i "^target:" "$dir/.STATUS" 2>/dev/null | cut -d: -f2- | xargs)
        [[ -n "$proj_status" ]] && echo "  📌 Status: $proj_status"
        [[ -n "$target_journal" ]] && echo "  🎯 Target: $target_journal"
        [[ -n "$next_action" ]] && echo "  📋 Next: $next_action"
    fi

    # Check for simulation files
    if [[ -d "$dir/simulations" ]] || [[ -d "$dir/sims" ]] || [[ -n "$(find "$dir" -maxdepth 1 -name '*.R' 2>/dev/null | xargs grep -li sim 2>/dev/null)" ]]; then
        echo "  🧪 Has simulations"
    fi
    echo ""
}

# ─────────────────────────────────────────────────────────────
# pick - Project Picker (fzf)
# ─────────────────────────────────────────────────────────────

# Helper: Truncate long branch names
_truncate_branch() {
    local branch="$1"
    local max_len=20
    if [[ ${#branch} -gt $max_len ]]; then
        echo "${branch:0:17}..."
    else
        printf "%-20s" "$branch"
    fi
}

pick() {
    local category="${1:-}"
    local fast_mode=0

    # Show help if requested
    if [[ "$1" == "help" || "$1" == "--help" || "$1" == "-h" ]]; then
        cat << 'EOF'
╔════════════════════════════════════════════════════════════╗
║  🔍 PICK - Interactive Project Picker                      ║
╚════════════════════════════════════════════════════════════╝

USAGE:
  pick [--fast] [category]

ARGUMENTS:
  category     Optional filter (r, dev, q, teach, rs, app)
  --fast       Skip git status checks (faster loading)

CATEGORIES (case-insensitive, multiple aliases):
  r            R packages (r, R, rpack, rpkg)
  dev          Development tools (dev, DEV, tool, tools)
  q            Quarto projects (q, Q, qu, quarto)
  teach        Teaching courses (teach, teaching)
  rs           Research projects (rs, research, res)
  app          Applications (app, apps)

INTERACTIVE KEYS:
  Enter        cd to project directory
  Ctrl-S       View .STATUS file (bat/cat)
  Ctrl-L       View git log (tig/git)
  Ctrl-C       Exit without action

DISPLAY FORMAT:
  project-name         icon type
  zsh-configuration    🔧 dev
  mediationverse       📦 r

EXAMPLES:
  pick              # Show all projects
  pick r            # Show only R packages
  pick --fast dev   # Fast mode, dev tools only
  pickr             # Alias for: pick r

ALIASES:
  pickr            pick r
  pickdev          pick dev
  pickq            pick q

DOCUMENTATION:
  See: docs/user/PICK-COMMAND-REFERENCE.md
EOF
        return 0
    fi

    # Parse arguments
    # Support: pick, pick r, pick dev, pick --fast, pick --fast r
    if [[ "$1" == "--fast" ]]; then
        fast_mode=1
        category="${2:-}"
    fi

    # Normalize category shortcuts
    case "$category" in
        r|R|rpack|rpkg) category="r" ;;
        dev|Dev|DEV|tool|tools) category="dev" ;;
        q|Q|qu|quarto) category="q" ;;
        teach|teaching) category="teach" ;;
        rs|research|res) category="rs" ;;
        app|apps) category="app" ;;
    esac

    # Check for fzf
    if ! command -v fzf &>/dev/null; then
        echo "❌ fzf required. Install: brew install fzf" >&2
        return 1
    fi

    # Show header with category filter if applicable
    local header_text="🔍 PROJECT PICKER"
    if [[ -n "$category" ]]; then
        case "$category" in
            r) header_text="🔍 PROJECT PICKER - R Packages" ;;
            dev) header_text="🔍 PROJECT PICKER - Dev Tools" ;;
            q) header_text="🔍 PROJECT PICKER - Quarto Projects" ;;
            teach) header_text="🔍 PROJECT PICKER - Teaching" ;;
            rs) header_text="🔍 PROJECT PICKER - Research" ;;
            app) header_text="🔍 PROJECT PICKER - Apps" ;;
        esac
    fi

    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    printf "║  %-57s║\n" "$header_text"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    # Build project list with status - FIX: use process substitution to avoid subshell
    local tmpfile=$(mktemp)
    local action_file=$(mktemp)

    while IFS='|' read -r name type icon dir; do
        # Simple format: name, icon, type (always, no colors)
        # Git info optional with --git flag in future
        printf "%-20s %s %-4s\n" "$name" "$icon" "$type"
    done < <(_proj_list_all "$category") > "$tmpfile"

    # Check if we have any projects
    if [[ ! -s "$tmpfile" ]]; then
        echo "❌ No projects found${category:+ in category '$category'}" >&2
        rm -f "$tmpfile" "$action_file"
        return 1
    fi

    # fzf with key bindings and help
    local selection=$(cat "$tmpfile" | fzf \
        --height=50% \
        --reverse \
        --header="Enter=cd | ^S=status | ^L=log | ^C=cancel" \
        --bind="ctrl-s:execute-silent(echo status > $action_file)+accept" \
        --bind="ctrl-l:execute-silent(echo log > $action_file)+accept")

    rm -f "$tmpfile"

    # Handle cancellation
    if [[ -z "$selection" ]]; then
        rm -f "$action_file"
        return 0
    fi

    # Extract project name (first field - simple now that we have no colors)
    local proj_name=$(echo "$selection" | awk '{print $1}')
    local proj_dir=$(_proj_find "$proj_name")

    if [[ -z "$proj_dir" || ! -d "$proj_dir" ]]; then
        echo "❌ Project directory not found: $proj_name" >&2
        rm -f "$action_file"
        return 1
    fi

    # Execute action
    local action="cd"
    if [[ -f "$action_file" ]]; then
        action=$(cat "$action_file")
        rm -f "$action_file"
    fi

    case "$action" in
        status)
            cd "$proj_dir"
            echo ""
            if [[ -f .STATUS ]]; then
                echo "  📊 .STATUS file for: $proj_name"
                echo ""
                if command -v bat &>/dev/null; then
                    bat .STATUS
                else
                    cat .STATUS
                fi
            else
                echo "  ⚠️  No .STATUS file found in: $proj_name"
            fi
            echo ""
            ;;
        log)
            cd "$proj_dir"
            echo ""
            echo "  📜 Git log for: $proj_name"
            echo ""
            if command -v tig &>/dev/null; then
                tig
            else
                git log --oneline --graph --decorate -20
            fi
            ;;
        *)
            cd "$proj_dir"
            echo ""
            echo "  📂 Changed to: $proj_dir"
            echo ""
            ;;
    esac
}

# Category-specific aliases


# ─────────────────────────────────────────────────────────────
# finish [MSG] - End work session (alias: wdone, fin)
# ─────────────────────────────────────────────────────────────
finish() {
    # Help check FIRST (all three forms)
    if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
        cat <<'EOF'
Usage: finish [commit_message]

End work session with commit workflow.

ARGUMENTS:
  commit_message    Optional commit message (default: "WIP")

EXAMPLES:
  finish                       # Interactive commit with "WIP"
  finish "Add new feature"     # Quick commit with message

WORKFLOW:
  1. Reviews changes (git diff)
  2. Commits with message (git add -A && git commit)
  3. Offers to merge dev → main if ahead
  4. Ends session tracking (removes session file)
  5. Logs work completed (worklog)
  6. Shows next steps suggestions

BRANCH WORKFLOW:
  If on 'dev' branch and ahead of 'main':
    [1] Keep on dev (default)
    [2] Merge to main
    [3] Merge to main and push

See also: work, win, startsession, endsession, pp, now, next
EOF
        return 0
    fi

    local msg="${1:-WIP}"

    # Check if in a git repo
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        echo "❌ Not in a git repository"
        return 1
    fi

    local proj_name=$(_proj_name_from_path "$(pwd)")
    local changes=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')

    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  ✅ FINISHING SESSION: $proj_name"
    printf "║  %-58s║\n" ""
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    if [[ "$changes" -eq 0 ]]; then
        echo "  📊 No changes to commit"
    else
        echo "  📊 Committing $changes changes..."
        echo ""
        git add -A
        git commit -m "$msg"
        echo ""
        echo "  ✅ Committed: \"$msg\""
    fi

    # Check branch status
    local branch=$(git branch --show-current 2>/dev/null)
    local ahead=0

    if [[ "$branch" == "dev" ]] && git rev-parse --verify main &>/dev/null; then
        ahead=$(git rev-list --count main..dev 2>/dev/null || echo 0)

        if [[ "$ahead" -gt 0 ]]; then
            echo ""
            echo "  🔶 dev is $ahead commits ahead of main"
            echo ""
            echo "  ❓ What next?"
            echo "     [1] Keep on dev (default)"
            echo "     [2] Merge to main"
            echo "     [3] Merge to main and push"
            echo ""
            printf "  Choice [1]: "
            read -r choice

            case "$choice" in
                2)
                    git checkout main && git merge dev
                    echo "  ✅ Merged dev → main"
                    ;;
                3)
                    git checkout main && git merge dev && git push
                    echo "  ✅ Merged and pushed"
                    ;;
                *)
                    echo "  📌 Staying on dev"
                    ;;
            esac
        fi
    fi

    # Calculate session duration if session file exists
    if [[ -f "$PROJ_SESSION_FILE" ]]; then
        local session_info=$(cat "$PROJ_SESSION_FILE")
        local start_time=$(echo "$session_info" | cut -d'|' -f4)
        if [[ -n "$start_time" ]]; then
            local duration=$(( ($(date +%s) - start_time) / 60 ))
            echo ""
            echo "  ⏱️  Session duration: ${duration} minutes"
        fi
        rm -f "$PROJ_SESSION_FILE"
    fi

    # Log to worklog
    if typeset -f worklog &>/dev/null; then
        worklog "$proj_name" "finished"
    fi

    echo ""
    echo "────────────────────────────────────────"
    echo "  💡 What's next?"
    echo "     now          Check current status"
    echo "     next         See suggestions"
    echo "     work NAME    Start another project"
    echo ""
}

# Aliases - REMOVED 2025-12-19: Use 'finish' directly
# alias wdone='finish'
# alias fin='finish'

# ─────────────────────────────────────────────────────────────
# now - What am I working on?
# ─────────────────────────────────────────────────────────────
now() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  📍 CURRENT STATUS                                         ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    # Check for active session
    if [[ -f "$PROJ_SESSION_FILE" ]]; then
        local session_info=$(cat "$PROJ_SESSION_FILE")
        IFS='|' read -r sess_name sess_dir sess_type sess_start <<< "$session_info"

        local duration=$(( ($(date +%s) - sess_start) / 60 ))

        echo "  🔧 Active Session: $sess_name"
        echo "     Started: ${duration} minutes ago"
        echo "     Type: $sess_type"
        echo "     Dir: $sess_dir"
        echo ""
    else
        echo "  💤 No active session"
        echo ""
    fi

    # Show current directory info
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        local proj_name=$(_proj_name_from_path "$(pwd)")
        local branch=$(git branch --show-current 2>/dev/null || echo "?")
        local changes=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
        local proj_type=$(_proj_detect_type "$(pwd)")

        echo "  📂 Current Directory:"
        echo "     Project: $proj_name"
        echo "     Branch: $branch"
        echo "     Type: $proj_type"
        echo "     Changes: $changes"

        if [[ "$changes" -gt 0 ]]; then
            echo ""
            git status --porcelain 2>/dev/null | head -5 | while read -r line; do
                echo "       $line"; done
        fi
    else
        echo "  📂 Current: $(pwd)"
        echo "     (not a git repository)"
    fi

    echo ""

    # Show recent worklog
    local today=$(date "+%Y-%m-%d")
    if [[ -f "$HOME/.workflow-log" ]]; then
        local today_entries=$(grep "^$today" "$HOME/.workflow-log" 2>/dev/null | tail -5)
        if [[ -n "$today_entries" ]]; then
            echo "  📋 Today's Activity:"
            echo "$today_entries" | while IFS='|' read -r ts session proj action details; do
                local time_only=$(echo "$ts" | awk '{print $2}' | cut -d: -f1,2)
                printf "     %s  %-15s %s\n" "$time_only" "$proj" "$action"; done
            echo ""
        fi
    fi
}

# ─────────────────────────────────────────────────────────────
# next - What should I work on next?
# ─────────────────────────────────────────────────────────────
next() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  💡 SUGGESTED NEXT ACTIONS                                 ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    local suggestions=()
    local idx=1

    # Check for uncommitted changes across projects
    echo "  🔍 Scanning projects..."
    echo ""

    _proj_list_all | while IFS='|' read -r name type icon dir; do
        [[ -d "$dir/.git" ]] || continue

        local git_info=$(_proj_git_status "$dir")
        IFS='|' read -r branch changes ahead behind <<< "$git_info"

        # Priority 1: Uncommitted changes
        if [[ "$changes" -gt 0 ]]; then
            echo "  [$idx] ⚠️  $name has $changes uncommitted changes"
            echo "       → work $name"
            ((idx++))
        fi

        # Priority 2: Dev ahead of main (ready to merge)
        if [[ "$ahead" -gt 0 && "$ahead" != "0" ]]; then
            echo "  [$idx] 🔶 $name: dev +$ahead ahead (ready to merge)"
            echo "       → work $name && finish"
            ((idx++))
        fi

        # Priority 3: Dev behind main (stale)
        if [[ "$behind" -gt 3 && "$behind" != "0" ]]; then
            echo "  [$idx] 🔄 $name: dev $behind behind (needs rebase)"
            echo "       → work $name && git rebase main"
            ((idx++))
        fi; done

    if [[ $idx -eq 1 ]]; then
        echo "  ✅ All projects are clean!"
        echo ""
        echo "  💡 Consider:"
        echo "     • Review your .STATUS files (sp PKG NN)"
        echo "     • Update Apple Notes (dash sync)"
        echo "     • Start something new (pp)"
    fi

    echo ""
}

# ─────────────────────────────────────────────────────────────
# dash - Master Dashboard (Standardized)
# ─────────────────────────────────────────────────────────────
# Uses standardized template from:
#   ~/projects/dev-tools/apple-notes-sync/templates/dashboard-templates.zsh
#
# Usage:
#   dash          - Show all projects
#   dash r        - R packages only
#   dash dt       - Dev-tools only
#   dash sync     - Sync to Apple Notes
#   dash html     - Generate HTML output
# ─────────────────────────────────────────────────────────────

# Source templates if available (provides _dash_terminal, _dash_html, _dash_sync)
[[ -f "$HOME/projects/dev-tools/apple-notes-sync/templates/dashboard-templates.zsh" ]] && \
    source "$HOME/projects/dev-tools/apple-notes-sync/templates/dashboard-templates.zsh"


# Internal display function (standardized format)
_dash_display() {
    local category="${1:-}"

    # Header
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  📊 PROJECT DASHBOARD                                      ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "  Updated: $(date '+%Y-%m-%d %H:%M')"
    echo ""

    local current_cat=""

    _proj_list_all "$category" | sort -t'|' -k2 | while IFS='|' read -r name type icon dir; do
        # Category header
        if [[ "$type" != "$current_cat" ]]; then
            [[ -n "$current_cat" ]] && echo ""

            case "$type" in
                r)     echo "  📦 R PACKAGES" ;;
                dt)    echo "  🔧 DEV-TOOLS" ;;
                teach) echo "  🎓 TEACHING" ;;
                rs)    echo "  🔬 RESEARCH" ;;
                q)     echo "  📝 QUARTO" ;;
                app)   echo "  📱 APPS" ;;
            esac
            echo "  ────────────────────────────────────────"
            current_cat="$type"
        fi

        # Get git status
        local git_info=$(_proj_git_status "$dir")
        IFS='|' read -r branch changes ahead behind <<< "$git_info"

        # Determine status icon and message
        local status_icon="✅"
        local status_msg=""

        if [[ "$changes" -gt 0 ]]; then
            status_icon="⚠️"
            status_msg="$changes uncommitted"
        elif [[ "$ahead" -gt 0 && "$ahead" != "0" ]]; then
            status_icon="🔶"
            status_msg="dev +$ahead ahead"
        elif [[ "$behind" -gt 3 && "$behind" != "0" ]]; then
            status_icon="🔄"
            status_msg="dev $behind behind"
        fi

        # Get progress from .STATUS
        local progress=""
        if [[ -f "$dir/.STATUS" ]]; then
            progress=$(grep -i "^progress:" "$dir/.STATUS" 2>/dev/null | cut -d: -f2 | xargs)
            [[ -n "$progress" && "$progress" != "0" ]] && progress="${progress}%"
        fi

        # Print row (standardized widths)
        printf "  %-18s %s [%-6s] %-14s %s\n" "$name" "$status_icon" "$branch" "$status_msg" "$progress"; done

    # Footer
    echo ""
    echo "────────────────────────────────────────────────────────────"
    echo "  💡 Commands: work NAME | pp | next | dash sync"
    echo ""
}

# Category-specific dashboards removed 2025-12-19
# Use: dash r, dash dt, dash q directly

# ─────────────────────────────────────────────────────────────
# Context-Aware Operations
# ─────────────────────────────────────────────────────────────

# pt - Project Test (context-aware)
pt() {
    local proj_type=$(_proj_detect_type)

    echo "  🧪 Running tests..."
    echo ""

    case "$proj_type" in
        r)
            Rscript -e 'devtools::test()'
            ;;
        node)
            npm test
            ;;
        python)
            pytest
            ;;
        make)
            make test
            ;;
        teaching|quarto)
            quarto check
            ;;
        research-qmd)
            quarto check
            ;;
        research-tex)
            # Check LaTeX syntax
            if [[ -f "main.tex" ]]; then
                echo "  Checking LaTeX syntax..."
                lacheck main.tex 2>&1 | head -20
            else
                echo "  No main.tex found"
            fi
            ;;
        *)
            echo "❌ No test command for project type: $proj_type"
            return 1
            ;;
    esac
}

# pb - Project Build (context-aware)
pb() {
    local proj_type=$(_proj_detect_type)

    echo "  🔨 Building..."
    echo ""

    case "$proj_type" in
        r)
            Rscript -e 'devtools::build()'
            ;;
        node)
            npm run build
            ;;
        python)
            python -m build
            ;;
        make)
            make build
            ;;
        quarto|teaching|research-qmd)
            quarto render
            ;;
        research-tex)
            if [[ -f "main.tex" ]]; then
                echo "  Building PDF with latexmk..."
                latexmk -pdf main.tex
            elif [[ -f "manuscript.tex" ]]; then
                latexmk -pdf manuscript.tex
            else
                # Find any .tex file
                local tex_file=$(ls *.tex 2>/dev/null | head -1)
                if [[ -n "$tex_file" ]]; then
                    latexmk -pdf "$tex_file"
                else
                    echo "❌ No .tex file found"
                    return 1
                fi
            fi
            ;;
        research)
            echo "❌ Unknown research format. Use research-tex or research-qmd."
            return 1
            ;;
        *)
            echo "❌ No build command for project type: $proj_type"
            return 1
            ;;
    esac
}

# pc - Project Commit (quick commit)
pc() {
    local msg="${1:-WIP}"

    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        echo "❌ Not in a git repository"
        return 1
    fi

    local changes=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')

    if [[ "$changes" -eq 0 ]]; then
        echo "  ✅ Nothing to commit"
        return 0
    fi

    echo "  📦 Committing $changes changes..."
    git add -A
    git commit -m "$msg"
    echo "  ✅ Committed: \"$msg\""
}

# pr - Project Run/Render (context-aware)
pr() {
    local proj_type=$(_proj_detect_type)

    case "$proj_type" in
        quarto|teaching|research-qmd)
            echo "  📝 Rendering..."
            quarto render
            ;;
        research-tex)
            echo "  📝 Building PDF..."
            pb  # Call pb for LaTeX
            ;;
        node)
            npm start
            ;;
        python)
            python main.py
            ;;
        *)
            echo "❌ No run command for project type: $proj_type"
            return 1
            ;;
    esac
}

# pv - Project Preview/View (context-aware)
pv() {
    # Help check FIRST (all three forms)
    if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
        cat <<'EOF'
Usage: pv

Preview project output (context-aware).

DESCRIPTION:
  Automatically detects project type and opens appropriate preview.
  Supports Quarto, R Markdown, LaTeX PDF, and more.

EXAMPLES:
  pv                           # Preview current project

PROJECT TYPES:
  - Quarto: Opens preview server
  - R Markdown: Renders and opens HTML
  - LaTeX: Opens compiled PDF
  - Slides: Opens presentation

See also: pb (build), pt (test)
EOF
        return 0
    fi

    local proj_type=$(_proj_detect_type)

    case "$proj_type" in
        quarto|teaching|research-qmd)
            quarto preview
            ;;
        research-tex)
            # Open the PDF
            local pdf_file=""
            if [[ -f "main.pdf" ]]; then
                pdf_file="main.pdf"
            elif [[ -f "manuscript.pdf" ]]; then
                pdf_file="manuscript.pdf"
            else
                pdf_file=$(ls *.pdf 2>/dev/null | head -1)
            fi
            if [[ -n "$pdf_file" ]]; then
                echo "  📄 Opening $pdf_file..."
                open "$pdf_file"
            else
                echo "  ❌ No PDF found. Run 'pb' first to build."
                return 1
            fi
            ;;
        *)
            echo "❌ Preview not available for project type: $proj_type"
            return 1
            ;;
    esac
}

# pcd - Project cd (with fuzzy finding)
pcd() {
    local query="$1"

    if [[ -z "$query" ]]; then
        pp  # Use picker
        return
    fi

    local proj_dir=$(_proj_find "$query")

    if [[ -n "$proj_dir" && -d "$proj_dir" ]]; then
        cd "$proj_dir"
        echo "  📂 $proj_dir"
    else
        echo "❌ Project not found: $query"
    fi
}

# ─────────────────────────────────────────────────────────────
# phelp - Quick reference for project commands
# ─────────────────────────────────────────────────────────────
phelp() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  📚 PROJECT WORKFLOW COMMANDS                              ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "  🎯 SESSION WORKFLOW"
    echo "  ────────────────────────────────────────"
    echo "    work NAME       Start session (cd + branch + status)"
    echo "    finish [MSG]    End session (commit + merge prompt)"
    echo "    now             What am I working on?"
    echo "    next            What should I work on next?"
    echo ""
    echo "  🔍 NAVIGATION"
    echo "  ────────────────────────────────────────"
    echo "    pick            Project picker (fzf)"
    echo "    pickr           R packages only"
    echo "    pickdev         Dev tools only"
    echo "    pickq           Quarto only"
    echo "    pcd NAME        Quick cd to project"
    echo ""
    echo "  ⚡ CONTEXT-AWARE (auto-detects project type)"
    echo "  ────────────────────────────────────────"
    echo "    pt              Test    (R→devtools, Node→npm, Python→pytest)"
    echo "    pb              Build   (R→devtools, Node→npm, Quarto→render)"
    echo "    pc MSG          Commit  (git add -A && commit)"
    echo "    pr              Run     (Quarto→render, Node→start)"
    echo "    pv              Preview (Quarto only)"
    echo ""
    echo "  📊 DASHBOARDS"
    echo "  ────────────────────────────────────────"
    echo "    dash            Master dashboard (all projects)"
    echo "    dash r          R packages only"
    echo "    dash dt         Dev tools only"
    echo "    dash sync       Sync to Apple Notes"
    echo ""
    echo "  📦 R PACKAGE EXTRAS"
    echo "  ────────────────────────────────────────"
    echo "    mvst            Mediationverse status"
    echo "    mvr             Mediationverse report"
    echo "    mvs             Sync mediationverse to Notes"
    echo ""
    echo "  💡 EXAMPLES"
    echo "  ────────────────────────────────────────"
    echo "    work medfit           # Start working on medfit"
    echo "    pt                    # Run tests"
    echo "    pc \"Add feature\"      # Commit with message"
    echo "    finish \"Done for now\" # End session"
    echo "    next                  # See what needs attention"
    echo ""
}

# ─────────────────────────────────────────────────────────────
# R Package Specific Commands
# ─────────────────────────────────────────────────────────────

# pcheck - R CMD check
pcheck() {
    local proj_type=$(_proj_detect_type)

    if [[ "$proj_type" != "r" ]]; then
        echo "❌ Not an R package (no DESCRIPTION file)"
        return 1
    fi

    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  🔍 R CMD CHECK                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    Rscript -e 'devtools::check()'
}

# pdoc - devtools::document
pdoc() {
    local proj_type=$(_proj_detect_type)

    if [[ "$proj_type" != "r" ]]; then
        echo "❌ Not an R package (no DESCRIPTION file)"
        return 1
    fi

    echo "  📝 Documenting package..."
    Rscript -e 'devtools::document()'
    echo "  ✅ Documentation updated"
}

# pinstall - devtools::install
pinstall() {
    local proj_type=$(_proj_detect_type)

    if [[ "$proj_type" != "r" ]]; then
        echo "❌ Not an R package (no DESCRIPTION file)"
        return 1
    fi

    echo "  📦 Installing package..."
    Rscript -e 'devtools::install()'
    echo "  ✅ Package installed"
}

# pload - devtools::load_all
pload() {
    local proj_type=$(_proj_detect_type)

    if [[ "$proj_type" != "r" ]]; then
        echo "❌ Not an R package (no DESCRIPTION file)"
        return 1
    fi

    echo "  📦 Loading package..."
    Rscript -e 'devtools::load_all()'
}

# ─────────────────────────────────────────────────────────────
# plog - Show recent commits
# ─────────────────────────────────────────────────────────────
plog() {
    local count="${1:-10}"

    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        echo "❌ Not in a git repository"
        return 1
    fi

    local proj_name=$(_proj_name_from_path "$(pwd)")

    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  📜 RECENT COMMITS: $proj_name"
    printf "║  %-58s║\n" ""
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    git log --oneline --decorate -n "$count" | while read -r line; do
        echo "  $line"; done

    echo ""

    # Show branch comparison if dev and main exist
    if git rev-parse --verify main &>/dev/null && git rev-parse --verify dev &>/dev/null; then
        local ahead=$(git rev-list --count main..dev 2>/dev/null || echo 0)
        local behind=$(git rev-list --count dev..main 2>/dev/null || echo 0)

        if [[ "$ahead" -gt 0 || "$behind" -gt 0 ]]; then
            echo "  ────────────────────────────────────────"
            [[ "$ahead" -gt 0 ]] && echo "  🔶 dev is $ahead commits ahead of main"
            [[ "$behind" -gt 0 ]] && echo "  🔄 dev is $behind commits behind main"
            echo ""
        fi
    fi
}

# ─────────────────────────────────────────────────────────────
# pmorning - Morning routine (pull all + dashboard)
# ─────────────────────────────────────────────────────────────
pmorning() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  ☀️  GOOD MORNING! Let's sync your projects...             ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    echo "  📥 Pulling updates from all projects..."
    echo "  ────────────────────────────────────────"

    local updated=0
    local failed=0

    _proj_list_all | while IFS='|' read -r name type icon dir; do
        [[ -d "$dir/.git" ]] || continue

        printf "  %-20s " "$name"

        local result=$(cd "$dir" && git pull 2>&1)

        if [[ "$result" == *"Already up to date"* ]]; then
            echo "✅ up to date"
        elif [[ "$result" == *"Fast-forward"* || "$result" == *"Updating"* ]]; then
            echo "📥 updated"
            ((updated++))
        elif [[ "$result" == *"error"* || "$result" == *"fatal"* ]]; then
            echo "❌ failed"
            ((failed++))
        else
            echo "✅"
        fi; done

    echo ""
    echo "  ────────────────────────────────────────"
    echo "  📊 Sync complete!"
    echo ""

    # Show dashboard
    echo "  Now let's see what needs attention..."
    echo ""
    sleep 1

    _dash_display

    # Show suggestions
    echo ""
    echo "  💡 Quick actions:"
    echo "     next          See detailed suggestions"
    echo "     work NAME     Start working on a project"
    echo "     pp            Pick a project"
    echo ""
}

# Aliases
# Note: Both morning() and pmorning() are separate functions with different purposes
# - morning()  = Show yesterday's wins and recent git activity
# - pmorning() = Pull all projects and show dashboard ("project morning")
# REMOVED 2025-12-19: Use 'pmorning' directly
# alias gmorning='pmorning'

# ═══════════════════════════════════════════════════════════════════
# TEACHING-SPECIFIC COMMANDS (Unique helpers only)
# ═══════════════════════════════════════════════════════════════════
# Note: Use 'work <course>' to start a teaching session
#       Use 'pv' to preview, 'pb' to build (context-aware)

# ─────────────────────────────────────────────────────────────
# tweek - Show current week info
# ─────────────────────────────────────────────────────────────
tweek() {
    # Calculate current week (semester typically starts week 34-35)
    local week_num=$(( ($(date +%W) - 34 + 52) % 52 ))
    [[ $week_num -lt 1 ]] && week_num=1
    [[ $week_num -gt 16 ]] && week_num=16

    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  📅 TEACHING WEEK: $week_num of 16                             ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    # Show content for this week if in a course directory
    if [[ -d "lectures" ]]; then
        echo "  📚 This week's lectures:"
        ls lectures/*week*${week_num}*.qmd 2>/dev/null | while read -r f; do
            echo "     ${f:t}"
        done
        ls lectures/*${week_num}*.qmd 2>/dev/null | while read -r f; do
            echo "     ${f:t}"
        done
    fi

    if [[ -d "slides" ]]; then
        echo "  📊 This week's slides:"
        ls slides/*week*${week_num}*.qmd 2>/dev/null | while read -r f; do
            echo "     ${f:t}"
        done
    fi

    # Show .STATUS next if available
    if [[ -f ".STATUS" ]]; then
        local next=$(grep -i "^next:" .STATUS 2>/dev/null | cut -d: -f2- | xargs)
        [[ -n "$next" ]] && echo "  📋 Next: $next"
    fi
    echo ""
}

# ─────────────────────────────────────────────────────────────
# tlec - Open or create lecture file
# ─────────────────────────────────────────────────────────────
tlec() {
    local week="${1:-}"

    if [[ ! -d "lectures" ]]; then
        echo "❌ No lectures/ directory found"
        echo "   Are you in a course directory?"
        return 1
    fi

    if [[ -z "$week" ]]; then
        # Show available lectures
        echo ""
        echo "  📚 Available lectures:"
        ls -1 lectures/*.qmd 2>/dev/null | while read -r f; do
            echo "     ${f:t}"; done
        echo ""
        echo "  Usage: tlec <week-number> or tlec <filename>"
        return 0
    fi

    # Find or create lecture file
    local file=""
    if [[ -f "lectures/$week" ]]; then
        file="lectures/$week"
    elif [[ -f "lectures/$week.qmd" ]]; then
        file="lectures/$week.qmd"
    else
        # Try to find by week number
        file=$(ls lectures/*week*${week}*.qmd 2>/dev/null | head -1)
        [[ -z "$file" ]] && file=$(ls lectures/*${week}*.qmd 2>/dev/null | head -1)
    fi

    if [[ -n "$file" && -f "$file" ]]; then
        echo "  📝 Opening: $file"
        ${EDITOR:-code} "$file"
    else
        echo "❌ Lecture not found for: $week"
        echo "   Available files:"
        ls lectures/*.qmd 2>/dev/null | head -5
    fi
}

# ─────────────────────────────────────────────────────────────
# tslide - Open or create slides file
# ─────────────────────────────────────────────────────────────
tslide() {
    local week="${1:-}"

    if [[ ! -d "slides" ]]; then
        echo "❌ No slides/ directory found"
        return 1
    fi

    if [[ -z "$week" ]]; then
        echo ""
        echo "  📊 Available slides:"
        ls -1 slides/*.qmd 2>/dev/null | while read -r f; do
            echo "     ${f:t}"; done
        echo ""
        echo "  Usage: tslide <week-number>"
        return 0
    fi

    local file=$(ls slides/*${week}*.qmd 2>/dev/null | head -1)

    if [[ -n "$file" && -f "$file" ]]; then
        echo "  📊 Opening: $file"
        ${EDITOR:-code} "$file"
    else
        echo "❌ Slides not found for: $week"
    fi
}

# ─────────────────────────────────────────────────────────────
# tpublish - Deploy course website (unique - GitHub Pages)
# ─────────────────────────────────────────────────────────────
tpublish() {
    if [[ ! -f "_quarto.yml" ]]; then
        echo "❌ No _quarto.yml found"
        return 1
    fi

    echo "  📤 Publishing to GitHub Pages..."
    quarto publish gh-pages --no-prompt
}

# ─────────────────────────────────────────────────────────────
# tst - Teaching status dashboard
# ─────────────────────────────────────────────────────────────
tst() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  🎓 TEACHING DASHBOARD                                     ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "  Updated: $(date '+%Y-%m-%d %H:%M')"
    echo ""

    echo "  📚 COURSES"
    echo "  ────────────────────────────────────────"

    for dir in ~/projects/teaching/*/; do
        [[ -d "$dir" ]] || continue
        local name="${dir:t}"
        [[ -z "$name" || "$name" == "*" ]] && continue

        local status_icon="🟢"
        local status_msg=""

        # Check git status
        if [[ -d "$dir/.git" ]]; then
            local changes=$(cd "$dir" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
            if [[ "$changes" -gt 0 ]]; then
                status_icon="⚠️"
                status_msg="$changes uncommitted"
            fi
        fi

        # Check for latest lecture
        local latest=""
        if [[ -d "$dir/lectures" ]]; then
            latest=$(ls -t "$dir/lectures"/*.qmd 2>/dev/null | head -1)
            [[ -n "$latest" ]] && latest=" (${latest:t:r})"
        fi

        printf "  %-20s %s %s%s\n" "$name" "$status_icon" "$status_msg" "$latest"; done

    echo ""
    echo "────────────────────────────────────────────────────────────"
    echo "  💡 Commands: work COURSE | pb | pv | tlec | tpublish"
    echo ""
}

# Teaching aliases removed 2025-12-19
# Use: dash teach directly

# ═══════════════════════════════════════════════════════════════════
# RESEARCH-SPECIFIC COMMANDS (Unique helpers only)
# ═══════════════════════════════════════════════════════════════════
# Note: Use 'work <project>' to start a research session
#       Use 'pb' to build PDF, 'pv' to view (context-aware)

# ─────────────────────────────────────────────────────────────
# rms - Open manuscript file (unique helper)
# ─────────────────────────────────────────────────────────────
rms() {
    # Find main manuscript file
    local ms=""

    if [[ -f "main.tex" ]]; then
        ms="main.tex"
    elif [[ -f "manuscript.tex" ]]; then
        ms="manuscript.tex"
    elif [[ -f "paper.tex" ]]; then
        ms="paper.tex"
    else
        # Look for .qmd files
        ms=$(ls *.qmd 2>/dev/null | grep -iE "manuscript|paper|main" | head -1)
        [[ -z "$ms" ]] && ms=$(ls *.qmd 2>/dev/null | head -1)
        # Fall back to .tex
        [[ -z "$ms" ]] && ms=$(ls *.tex 2>/dev/null | head -1)
    fi

    if [[ -n "$ms" && -f "$ms" ]]; then
        echo "  📜 Opening: $ms"
        ${EDITOR:-code} "$ms"
    else
        echo "❌ No manuscript file found"
        echo "   Looking for: main.tex, manuscript.tex, *.qmd"
    fi
}

# ─────────────────────────────────────────────────────────────
# rsim - Run simulation
# ─────────────────────────────────────────────────────────────
rsim() {
    local mode="${1:-test}"

    # Look for simulation scripts
    local sim_script=""

    if [[ -f "code/R/run_simulation.R" ]]; then
        sim_script="code/R/run_simulation.R"
    elif [[ -f "code/R/complete_workflow.R" ]]; then
        sim_script="code/R/complete_workflow.R"
    elif [[ -f "run_simulation.R" ]]; then
        sim_script="run_simulation.R"
    elif [[ -f "simulation.R" ]]; then
        sim_script="simulation.R"
    fi

    if [[ -z "$sim_script" ]]; then
        echo "❌ No simulation script found"
        echo "   Looking for: code/R/run_simulation.R, simulation.R"
        return 1
    fi

    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  🔬 RUNNING SIMULATION: $mode mode"
    printf "║  %-58s║\n" ""
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "  📜 Script: $sim_script"
    echo "  ⏱️  Started: $(date '+%H:%M:%S')"
    echo ""

    # Run with mode if config supports it
    if grep -q "SIM_MODE\|sim_mode\|mode" "$sim_script" 2>/dev/null; then
        SIM_MODE="$mode" Rscript "$sim_script"
    else
        Rscript "$sim_script"
    fi

    echo ""
    echo "  ✅ Completed: $(date '+%H:%M:%S')"
}

# ─────────────────────────────────────────────────────────────
# rlit - Search literature (unique - placeholder for MCP integration)
# ─────────────────────────────────────────────────────────────
rlit() {
    local query="${1:-}"

    if [[ -z "$query" ]]; then
        # Show local literature if exists
        if [[ -d "literature" ]]; then
            echo ""
            echo "  📚 Local literature:"
            ls -1 literature/*.pdf 2>/dev/null | while read -r f; do
                echo "     ${f:t}"; done
        elif [[ -d "03_Literature" ]]; then
            echo ""
            echo "  📚 Local literature:"
            ls -1 03_Literature/*.pdf 2>/dev/null | while read -r f; do
                echo "     ${f:t}"; done
        else
            echo "  Usage: rlit <search-query>"
            echo "  No local literature/ directory found"
        fi
        return 0
    fi

    echo "  🔍 Searching for: $query"
    echo "  (Literature search via MCP/Zotero - implement as needed)"
}

# ─────────────────────────────────────────────────────────────
# rst - Research status dashboard
# ─────────────────────────────────────────────────────────────
rst() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  🔬 RESEARCH DASHBOARD                                     ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "  Updated: $(date '+%Y-%m-%d %H:%M')"
    echo ""

    echo "  📝 MANUSCRIPTS & PROJECTS"
    echo "  ────────────────────────────────────────"

    for dir in ~/projects/research/*/; do
        [[ -d "$dir" ]] || continue
        local name="${dir:t}"
        [[ -z "$name" || "$name" == "*" ]] && continue

        local status_icon="🟢"
        local type_info=""

        # Detect project type
        if [[ -f "$dir/main.tex" ]]; then
            type_info="LaTeX"
        elif [[ -f "$dir/_quarto.yml" ]] || [[ -n "$(find "$dir" -maxdepth 1 -name '*.qmd' -print -quit 2>/dev/null)" ]]; then
            type_info="Quarto"
        elif [[ -d "$dir/literature" ]] || [[ -d "$dir/03_Literature" ]]; then
            type_info="Archive"
            status_icon="📚"
        fi

        # Check git status
        if [[ -d "$dir/.git" ]]; then
            local changes=$(cd "$dir" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
            if [[ "$changes" -gt 0 ]]; then
                status_icon="⚠️"
                type_info="$type_info, $changes changes"
            fi
        fi

        # Check .STATUS for next action
        local next_action=""
        if [[ -f "$dir/.STATUS" ]]; then
            next_action=$(grep -i "^next:" "$dir/.STATUS" 2>/dev/null | cut -d: -f2- | xargs | head -c 30)
        fi

        printf "  %-20s %s %s\n" "$name" "$status_icon" "$type_info"
        [[ -n "$next_action" ]] && printf "                       └─ %s\n" "$next_action"; done

    echo ""
    echo "────────────────────────────────────────────────────────────"
    echo "  💡 Commands: work PROJECT | pb | pv | rms | rsim"
    echo ""
}

# Research aliases removed 2025-12-19
# Use: dash rs directly

# ─────────────────────────────────────────────────────────────
# Quick help for teaching/research
# ─────────────────────────────────────────────────────────────
thelp() {
    echo ""
    echo "🎓 TEACHING COMMANDS (Option D - Smart work)"
    echo "────────────────────────────────────────"
    echo "  work COURSE    Start teaching session (smart context)"
    echo "  pb             Build/render site"
    echo "  pv             Preview site"
    echo "  tlec [WEEK]    Open lecture file"
    echo "  tslide [WEEK]  Open slides"
    echo "  tpublish       Deploy to GitHub Pages"
    echo "  tweek          Current week info"
    echo "  tst            Teaching dashboard"
    echo "  pickteach      Pick teaching project"
    echo ""
}

rhelp() {
    echo ""
    echo "🔬 RESEARCH COMMANDS (Option D - Smart work)"
    echo "────────────────────────────────────────"
    echo "  work PROJECT   Start research session (smart context)"
    echo "  pb             Build PDF (LaTeX or Quarto)"
    echo "  pv             View PDF / Preview"
    echo "  rms            Open manuscript"
    echo "  rsim [MODE]    Run simulation (test/local/cluster)"
    echo "  rlit [QUERY]   Search literature"
    echo "  rst            Research dashboard"
    echo "  pickrs         Pick research project"
    echo ""
}
