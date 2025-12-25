# ============================================
# BACKGROUND AGENT MANAGEMENT
# ============================================
# Manage Claude Code background agents
# Created: 2025-12-16

BG_AGENTS_DIR="$HOME/.claude/bg-agents"

# ============================================
# MAIN COMMANDS
# ============================================

# List all background agents
bg-list() {
    if [[ ! -d "$BG_AGENTS_DIR" ]] || [[ -z "$(ls -A "$BG_AGENTS_DIR" 2>/dev/null)" ]]; then
        echo "📭 No background agents found"
        return 0
    fi

    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║          📋 Claude Background Agents                       ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    local running=0
    local complete=0
    local failed=0

    for status_file in "$BG_AGENTS_DIR"/*.status; do
        if [[ ! -f "$status_file" ]]; then
            continue
        fi

        local agent_id=$(basename "$status_file" .status)
        local agent_status=$(head -1 "$status_file")
        local start_time=$(sed -n '2p' "$status_file")
        local title=$(sed -n '3p' "$status_file")
        local pid=$(tail -1 "$status_file")

        case "$agent_status" in
            running)
                ((running++))
                local duration=$(($(date +%s) - start_time))
                local running_indicator="🔄"

                # Check if process still running
                if ! kill -0 "$pid" 2>/dev/null; then
                    running_indicator="⚠️ "
                    title="$title (process died)"
                fi

                echo "$running_indicator RUNNING - $agent_id"
                echo "   Title: $title"
                echo "   PID: $pid"
                echo "   Duration: $(format_duration $duration)"
                echo ""
                ;;
            complete)
                ((complete++))
                local end_time=$(sed -n '2p' "$status_file" | tail -1)
                local output=$(sed -n '4p' "$status_file")
                local duration=$((end_time - start_time))

                echo "✅ COMPLETE - $agent_id"
                echo "   Title: $title"
                echo "   Duration: $(format_duration $duration)"
                echo "   Output: $output"
                echo ""
                ;;
            failed)
                ((failed++))
                local error=$(sed -n '4p' "$status_file")

                echo "❌ FAILED - $agent_id"
                echo "   Title: $title"
                echo "   Error: $error"
                echo ""
                ;;
        esac
    done

    echo "─────────────────────────────────────────────────────────────"
    echo "Summary: $running running, $complete complete, $failed failed"
}

# Show status of specific agent
bg-status() {
    local agent_id="${1:-}"

    if [[ -z "$agent_id" ]]; then
        echo "Usage: bg-status <agent-id>"
        echo ""
        echo "Available agents:"
        bg-list
        return 1
    fi

    local status_file="$BG_AGENTS_DIR/$agent_id.status"

    if [[ ! -f "$status_file" ]]; then
        echo "❌ Agent not found: $agent_id"
        return 1
    fi

    local agent_status=$(head -1 "$status_file")
    local start_time=$(sed -n '2p' "$status_file")
    local title=$(sed -n '3p' "$status_file")
    local workdir=$(sed -n '4p' "$status_file")
    local pid=$(tail -1 "$status_file")

    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║          📊 Background Agent Status                        ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "**Agent ID:** $agent_id"
    echo "**Title:** $title"
    echo "**Status:** $agent_status"
    echo "**Working Dir:** $workdir"
    echo ""

    case "$agent_status" in
        running)
            echo "**PID:** $pid"
            echo "**Started:** $(date -r "$start_time" "+%Y-%m-%d %H:%M:%S")"
            echo "**Duration:** $(format_duration $(($(date +%s) - start_time)))"
            echo ""

            # Check if process actually running
            if kill -0 "$pid" 2>/dev/null; then
                echo "✅ Process is running"
            else
                echo "⚠️  Process is not running (may have crashed)"
            fi
            ;;
        complete)
            local end_time=$(sed -n '2p' "$status_file" | tail -1)
            local output=$(sed -n '4p' "$status_file")
            echo "**Completed:** $(date -r "$end_time" "+%Y-%m-%d %H:%M:%S")"
            echo "**Duration:** $(format_duration $((end_time - start_time)))"
            echo "**Output:** $output"
            echo ""
            echo "💡 View results: glowopen $output"
            ;;
        failed)
            local error=$(sed -n '4p' "$status_file")
            echo "**Error:** $error"
            ;;
    esac
}

# Kill a background agent
bg-kill() {
    local identifier="${1:-}"

    if [[ -z "$identifier" ]]; then
        echo "Usage: bg-kill <agent-id|pid>"
        echo ""
        echo "Running agents:"
        bg-list | grep "RUNNING"
        return 1
    fi

    # Check if identifier is a PID or agent ID
    if [[ "$identifier" =~ ^[0-9]+$ ]]; then
        # It's a PID
        local pid="$identifier"

        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null && echo "✅ Killed process $pid" || echo "❌ Failed to kill $pid"
        else
            echo "❌ Process $pid not found"
            return 1
        fi
    else
        # It's an agent ID
        local status_file="$BG_AGENTS_DIR/$identifier.status"

        if [[ ! -f "$status_file" ]]; then
            echo "❌ Agent not found: $identifier"
            return 1
        fi

        local agent_status=$(head -1 "$status_file")
        local pid=$(tail -1 "$status_file")

        if [[ "$agent_status" != "running" ]]; then
            echo "⚠️  Agent is not running (status: $agent_status)"
            return 1
        fi

        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null && echo "✅ Killed agent $identifier (PID: $pid)" || echo "❌ Failed to kill"

            # Update status file
            echo "killed" > "$status_file"
            echo "$(date +%s)" >> "$status_file"
        else
            echo "⚠️  Process not running (PID: $pid)"
        fi
    fi
}

# Clean up completed/failed agents
bg-clean() {
    local keep="${1:-0}"  # 0 means delete all completed/failed

    if [[ ! -d "$BG_AGENTS_DIR" ]]; then
        echo "📭 No background agents directory"
        return 0
    fi

    local removed=0

    for status_file in "$BG_AGENTS_DIR"/*.status; do
        if [[ ! -f "$status_file" ]]; then
            continue
        fi

        local agent_status=$(head -1 "$status_file")

        if [[ "$agent_status" == "complete" ]] || [[ "$agent_status" == "failed" ]] || [[ "$agent_status" == "killed" ]]; then
            rm "$status_file"
            ((removed++))
        fi
    done

    if [[ $removed -gt 0 ]]; then
        echo "✅ Cleaned up $removed agent(s)"
    else
        echo "📭 No agents to clean"
    fi
}

# Show agent logs (tail the status file)
bg-logs() {
    local agent_id="${1:-}"

    if [[ -z "$agent_id" ]]; then
        echo "Usage: bg-logs <agent-id>"
        return 1
    fi

    local status_file="$BG_AGENTS_DIR/$agent_id.status"

    if [[ ! -f "$status_file" ]]; then
        echo "❌ Agent not found: $agent_id"
        return 1
    fi

    echo "📄 Agent status file: $status_file"
    echo ""
    cat "$status_file"
}

# ============================================
# HELPER FUNCTIONS
# ============================================

format_duration() {
    local seconds=$1
    local hours=$((seconds / 3600))
    local minutes=$(((seconds % 3600) / 60))
    local secs=$((seconds % 60))

    if [[ $hours -gt 0 ]]; then
        echo "${hours}h ${minutes}m ${secs}s"
    elif [[ $minutes -gt 0 ]]; then
        echo "${minutes}m ${secs}s"
    else
        echo "${secs}s"
    fi
}

# ============================================
# ALIASES
# ============================================

alias bgl='bg-list'
alias bgs='bg-status'
alias bgk='bg-kill'
alias bgc='bg-clean'
alias bglog='bg-logs'

# ============================================
# HELP
# ============================================

bg-help() {
    cat << 'EOF'
╔════════════════════════════════════════════════════════════╗
║        📋 Background Agent Management                      ║
╚════════════════════════════════════════════════════════════╝

COMMANDS:
  bg-list              List all background agents
  bg-status <id>       Show detailed status of agent
  bg-kill <id|pid>     Kill a running agent
  bg-clean             Remove completed/failed agents
  bg-logs <id>         Show agent status file

ALIASES:
  bgl                  bg-list
  bgs                  bg-status
  bgk                  bg-kill
  bgc                  bg-clean
  bglog                bg-logs

USAGE EXAMPLES:
  # List all agents
  bg-list

  # Check status of specific agent
  bg-status bg-20251216-105912-12345

  # Kill an agent by ID
  bg-kill bg-20251216-105912-12345

  # Kill an agent by PID
  bg-kill 12345

  # Clean up completed agents
  bg-clean

BACKGROUND MODES:
  [analyze:bg]         Deep codebase analysis
  [brainstorm:bg]      Comprehensive brainstorming
  [debug:bg]           Complex problem investigation

WORKFLOW:
  1. Launch background agent:
     [analyze:bg] the authentication system

  2. Continue working while agent runs

  3. Check status:
     bg-list

  4. View results when complete:
     glowopen latest

EOF
}

alias bghelp='bg-help'
