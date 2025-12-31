# commands/pick.zsh - Interactive project picker
# fzf-based project selection with category filtering

# ============================================================================
# PROJECT CATEGORIES CONFIGURATION
# ============================================================================

PROJ_BASE="${FLOW_PROJECTS_ROOT:-$HOME/projects}"
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
PROJ_SESSION_MAX_AGE=86400  # 24 hours in seconds

# Worktree directory (special category)
PROJ_WORKTREE_DIR="${FLOW_WORKTREE_DIR:-$HOME/.git-worktrees}"

# ============================================================================
# SESSION MANAGEMENT
# ============================================================================

# Save current project to session file
_proj_save_session() {
    local proj_dir="$1"
    local proj_name=$(basename "$proj_dir")
    local timestamp=$(date +%s)

    echo "${proj_name}|${proj_dir}|${timestamp}" > "$PROJ_SESSION_FILE"
}

# Get last session info (returns: name|dir|age_hours or empty if invalid/old)
_proj_get_session() {
    [[ -f "$PROJ_SESSION_FILE" ]] || return 1

    local session_data=$(cat "$PROJ_SESSION_FILE")
    local proj_name="${session_data%%|*}"
    local rest="${session_data#*|}"
    local proj_dir="${rest%%|*}"
    local timestamp="${rest##*|}"

    # Validate directory exists
    [[ -d "$proj_dir" ]] || return 1

    # Check age
    local now=$(date +%s)
    local age=$((now - timestamp))

    # Reject if too old
    [[ $age -gt $PROJ_SESSION_MAX_AGE ]] && return 1

    # Calculate human-readable age
    local age_hours=$((age / 3600))
    local age_mins=$(((age % 3600) / 60))
    local age_str
    if [[ $age_hours -gt 0 ]]; then
        age_str="${age_hours}h ago"
    elif [[ $age_mins -gt 0 ]]; then
        age_str="${age_mins}m ago"
    else
        age_str="just now"
    fi

    echo "${proj_name}|${proj_dir}|${age_str}"
    return 0
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Find project by fuzzy name (returns first match)
_proj_find() {
    local query="$1"
    local category="${2:-}"

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
            setopt local_options nullglob
            for proj_dir in "$full_path"/*/; do
                [[ -d "$proj_dir/.git" ]] || continue
                local proj_name=$(basename "$proj_dir")

                # Fuzzy match
                if [[ "$proj_name" == *"$query"* ]]; then
                    echo "$proj_dir"
                    return 0
                fi
            done
        fi
    done

    return 1
}

# Find ALL projects matching fuzzy name (for direct jump)
_proj_find_all() {
    local query="$1"
    local category="${2:-}"
    local -a matches=()

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
            setopt local_options nullglob
            for proj_dir in "$full_path"/*/; do
                [[ -d "$proj_dir/.git" ]] || continue
                local proj_name=$(basename "$proj_dir")

                # Fuzzy match (case-insensitive)
                if [[ "${proj_name:l}" == *"${query:l}"* ]]; then
                    matches+=("$proj_name|$cat_type|$proj_dir")
                fi
            done
        fi
    done

    # Return matches (one per line)
    printf '%s\n' "${matches[@]}"
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
            setopt local_options nullglob
            for proj_dir in "$full_path"/*/; do
                [[ -d "$proj_dir/.git" ]] || continue
                local proj_name=$(basename "$proj_dir")
                echo "$proj_name|$cat_type|$cat_icon|$proj_dir"
            done
        fi
    done
}

# ============================================================================
# WORKTREE HELPERS
# ============================================================================

# List all worktrees from PROJ_WORKTREE_DIR
# Format: display_name|wt|🌳|path|session_status
# Display name format: project (branch)
_proj_list_worktrees() {
    local project_filter="${1:-}"

    [[ -d "$PROJ_WORKTREE_DIR" ]] || return

    setopt local_options nullglob

    # Scan project directories (first level under PROJ_WORKTREE_DIR)
    for project_dir in "$PROJ_WORKTREE_DIR"/*/; do
        [[ -d "$project_dir" ]] || continue
        local project_name=$(basename "$project_dir")

        # Skip if project filter doesn't match (case-insensitive fuzzy)
        if [[ -n "$project_filter" && "${project_name:l}" != *"${project_filter:l}"* ]]; then
            continue
        fi

        # Scan worktree directories (second level)
        for wt_dir in "${project_dir%/}"/*/; do
            [[ -d "$wt_dir" ]] || continue

            # Verify it's a valid worktree (has .git file or directory)
            [[ -e "$wt_dir/.git" ]] || continue

            local branch_name=$(basename "$wt_dir")
            local display_name="$project_name ($branch_name)"
            local session_status=$(_proj_get_claude_session_status "${wt_dir%/}")

            echo "$display_name|wt|🌳|${wt_dir%/}|${session_status}"
        done
    done
}

# Find worktree by display name (project (branch) format)
# Returns the worktree path
_proj_find_worktree() {
    local query="$1"

    [[ -d "$PROJ_WORKTREE_DIR" ]] || return 1

    setopt local_options nullglob

    for project_dir in "$PROJ_WORKTREE_DIR"/*/; do
        [[ -d "$project_dir" ]] || continue
        local project_name=$(basename "$project_dir")

        for wt_dir in "${project_dir%/}"/*/; do
            [[ -d "$wt_dir" ]] || continue
            [[ -e "$wt_dir/.git" ]] || continue

            local branch_name=$(basename "$wt_dir")
            local display_name="$project_name ($branch_name)"

            # Match on display name or just project name
            if [[ "$display_name" == "$query"* || "$project_name" == "$query"* ]]; then
                echo "${wt_dir%/}"
                return 0
            fi
        done
    done

    return 1
}

# Show git status summary for a directory
_proj_show_git_status() {
    local dir="$1"
    [[ -d "$dir/.git" || -f "$dir/.git" ]] || return

    local branch=$(git -C "$dir" branch --show-current 2>/dev/null)
    local modified=$(git -C "$dir" diff --name-only 2>/dev/null | wc -l | tr -d ' ')
    local untracked=$(git -C "$dir" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

    echo ""
    echo "  🌿 Branch: $branch"
    if [[ $modified -gt 0 || $untracked -gt 0 ]]; then
        echo "  📊 Status: ${modified} modified, ${untracked} untracked"
    else
        echo "  ✅ Status: Clean"
    fi
}

# Get Claude session status for a directory
# Returns: "🟢 Xh" (recent), "🟡 old" (old session), or "" (no session)
_proj_get_claude_session_status() {
    local dir="$1"
    local claude_dir="$dir/.claude"

    # Check if .claude directory exists
    [[ -d "$claude_dir" ]] || return

    # Find most recent file in .claude directory
    local newest_file=$(find "$claude_dir" -type f -name "*.json" 2>/dev/null | head -1)
    [[ -n "$newest_file" ]] || return

    # Get file modification time
    local file_mtime=$(stat -f %m "$newest_file" 2>/dev/null)
    [[ -n "$file_mtime" ]] || return

    local now=$(date +%s)
    local age=$((now - file_mtime))
    local age_hours=$((age / 3600))

    if [[ $age -lt 86400 ]]; then
        # Less than 24 hours old
        if [[ $age_hours -gt 0 ]]; then
            echo "🟢 ${age_hours}h"
        else
            local age_mins=$((age / 60))
            if [[ $age_mins -gt 0 ]]; then
                echo "🟢 ${age_mins}m"
            else
                echo "🟢 now"
            fi
        fi
    else
        # Older session
        echo "🟡 old"
    fi
}

# ============================================================================
# PICK - Interactive Project Picker
# ============================================================================

pick() {
    local category="${1:-}"
    local fast_mode=0
    local force_picker=0
    local no_claude_keys=0

    # Parse --no-claude flag (used by cc dispatcher to prevent double-launch)
    if [[ "$1" == "--no-claude" ]]; then
        no_claude_keys=1
        shift
        category="${1:-}"
    fi

    # Show help if requested
    if [[ "$1" == "help" || "$1" == "--help" || "$1" == "-h" ]]; then
        cat << 'EOF'
╔════════════════════════════════════════════════════════════╗
║  🔍 PICK - Interactive Project Picker                      ║
╚════════════════════════════════════════════════════════════╝

USAGE:
  pick [options] [category|project-name]

ARGUMENTS:
  category       Filter by category (r, dev, q, teach, rs, app)
  project-name   Direct jump to matching project (fuzzy)

OPTIONS:
  --fast         Skip git status checks (faster loading)
  -a, --all      Force full picker (skip direct jump)

CATEGORIES (case-insensitive, multiple aliases):
  r              R packages (r, R, rpack, rpkg)
  dev            Development tools (dev, DEV, tool, tools)
  q              Quarto projects (q, Q, qu, quarto)
  teach          Teaching courses (teach, teaching)
  rs             Research projects (rs, research, res)
  app            Applications (app, apps)
  wt             Git worktrees (wt, worktree, worktrees)

DIRECT JUMP:
  pick flow      → Direct cd to flow-cli (no picker)
  pick med       → Direct cd to mediationverse
  pick stat      → If multiple matches, shows filtered picker

SMART RESUME (no args):
  pick           → Shows resume prompt if recent session exists
  Enter          → Resume last project (if shown)
  Space          → Force full picker (bypass resume)

INTERACTIVE KEYS:
  Enter          cd to project directory
  Space          Force full picker (bypass resume prompt)
  Ctrl-O         cd + launch Claude (cc mode)
  Ctrl-Y         cd + launch Claude YOLO (ccy mode)
  Ctrl-S         View .STATUS file (bat/cat)
  Ctrl-L         View git log (tig/git)
  Ctrl-C         Exit without action

SESSION INDICATORS (worktree mode):
  🟢 Xh/m        Recent Claude session (< 24h)
  🟡 old         Older Claude session (> 24h)
  (none)         No Claude session

EXAMPLES:
  pick              # Show all projects
  pick flow         # Direct jump to flow-cli
  pick r            # Show only R packages
  pick --fast dev   # Fast mode, dev tools only
  pick -a flow      # Force picker, pre-filter "flow"

WORKTREE EXAMPLES:
  pick wt           # Show all worktrees from ~/.git-worktrees
  pick wt scribe    # Show only scribe's worktrees
  pickwt            # Alias for pick wt

ALIASES:
  pickr            pick r
  pickdev          pick dev
  pickq            pick q
  pickwt           pick wt
EOF
        return 0
    fi

    # Parse arguments
    if [[ "$1" == "--fast" ]]; then
        fast_mode=1
        shift
        category="${1:-}"
    fi

    if [[ "$1" == "-a" || "$1" == "--all" ]]; then
        force_picker=1
        shift
        category="${1:-}"
    fi

    # Check if argument is a category or a project name
    local is_category=0
    case "$1" in
        r|R|rpack|rpkg|dev|Dev|DEV|tool|tools|q|Q|qu|quarto|teach|teaching|rs|research|res|app|apps|wt|worktree|worktrees)
            is_category=1
            ;;
    esac

    # DIRECT JUMP: If arg provided and not a category, try direct jump
    if [[ -n "$1" && $is_category -eq 0 && $force_picker -eq 0 ]]; then
        local query="$1"
        local -a matches
        matches=("${(@f)$(_proj_find_all "$query")}")

        # Filter out empty entries
        matches=("${(@)matches:#}")

        local match_count=${#matches[@]}

        if [[ $match_count -eq 0 ]]; then
            # No matches
            echo "❌ No project matching: $query" >&2
            echo "💡 Try: pick (to see all projects)" >&2
            return 1
        elif [[ $match_count -eq 1 ]]; then
            # Exactly one match - direct jump!
            local match="${matches[1]}"
            local proj_name="${match%%|*}"
            local proj_dir="${match##*|}"

            cd "$proj_dir"
            _proj_save_session "$proj_dir"
            echo "  📂 $proj_dir"
            return 0
        else
            # Multiple matches - show filtered picker
            echo ""
            echo "  💡 Multiple matches for '$query' - showing picker..."
            echo ""

            local tmpfile=$(mktemp)
            for match in "${matches[@]}"; do
                local name="${match%%|*}"
                local rest="${match#*|}"
                local type="${rest%%|*}"
                local icon=""
                case "$type" in
                    r) icon="📦" ;;
                    dev) icon="🔧" ;;
                    q) icon="📝" ;;
                    teach) icon="🎓" ;;
                    rs) icon="🔬" ;;
                    app) icon="📱" ;;
                esac
                printf "%-20s %s %-4s\n" "$name" "$icon" "$type"
            done > "$tmpfile"

            local selection=$(cat "$tmpfile" | fzf \
                --height=50% \
                --reverse \
                --header="Enter=cd | ^C=cancel")

            rm -f "$tmpfile"

            if [[ -z "$selection" ]]; then
                return 1
            fi

            local proj_name=$(echo "$selection" | awk '{print $1}')
            local proj_dir=$(_proj_find "$proj_name")

            if [[ -n "$proj_dir" ]]; then
                cd "$proj_dir"
                _proj_save_session "$proj_dir"
                echo "  📂 $proj_dir"
                return 0
            fi
            return 1
        fi
    fi

    # Normalize category shortcuts
    category="${1:-}"
    local wt_project_filter=""
    case "$category" in
        r|R|rpack|rpkg) category="r" ;;
        dev|Dev|DEV|tool|tools) category="dev" ;;
        q|Q|qu|quarto) category="q" ;;
        teach|teaching) category="teach" ;;
        rs|research|res) category="rs" ;;
        app|apps) category="app" ;;
        wt|worktree|worktrees)
            category="wt"
            # Optional second arg is project filter (e.g., pick wt scribe)
            wt_project_filter="${2:-}"
            ;;
    esac

    # Check for fzf
    if ! command -v fzf &>/dev/null; then
        echo "❌ fzf required. Install: brew install fzf" >&2
        return 1
    fi

    # =========================================================================
    # SESSION-AWARE RESUME (Phase 2)
    # =========================================================================

    # Check for recent session (only when no category filter)
    local session_info=""
    local show_resume=0
    local last_name="" last_dir="" last_age=""

    if [[ -z "$category" ]]; then
        session_info=$(_proj_get_session)
        if [[ -n "$session_info" ]]; then
            show_resume=1
            last_name="${session_info%%|*}"
            local rest="${session_info#*|}"
            last_dir="${rest%%|*}"
            last_age="${rest##*|}"
        fi
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
            wt)
                if [[ -n "$wt_project_filter" ]]; then
                    header_text="🌳 WORKTREE PICKER - $wt_project_filter"
                else
                    header_text="🌳 WORKTREE PICKER"
                fi
                ;;
        esac
    fi

    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    printf "║  %-57s║\n" "$header_text"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    # Show resume hint if available
    if [[ $show_resume -eq 1 ]]; then
        echo "  💡 Last: $last_name ($last_age)"
        echo "  [Enter] Resume  │  [Space] Browse all  │  Type to search..."
        echo ""
    fi

    # Build project list
    local tmpfile=$(mktemp)
    local action_file=$(mktemp)
    local is_worktree_mode=0

    if [[ "$category" == "wt" ]]; then
        is_worktree_mode=1
        # Worktrees: wider format for "project (branch)" names + session status
        while IFS='|' read -r name type icon dir session; do
            if [[ -n "$session" ]]; then
                printf "%-30s %s %-4s  %s\n" "$name" "$icon" "$type" "$session"
            else
                printf "%-30s %s %-4s\n" "$name" "$icon" "$type"
            fi
        done < <(_proj_list_worktrees "$wt_project_filter") > "$tmpfile"
    else
        # Regular projects
        while IFS='|' read -r name type icon dir; do
            printf "%-20s %s %-4s\n" "$name" "$icon" "$type"
        done < <(_proj_list_all "$category") > "$tmpfile"
    fi

    # Check if we have any projects/worktrees
    if [[ ! -s "$tmpfile" ]]; then
        if [[ "$category" == "wt" ]]; then
            if [[ -n "$wt_project_filter" ]]; then
                echo "❌ No worktrees found for project '$wt_project_filter'" >&2
            else
                echo "❌ No worktrees found in $PROJ_WORKTREE_DIR" >&2
            fi
            echo "💡 Create worktrees with: wt create <branch>" >&2
        else
            echo "❌ No projects found${category:+ in category '$category'}" >&2
        fi
        rm -f "$tmpfile" "$action_file"
        return 1
    fi

    # fzf with key bindings (including space for escape hatch)
    local fzf_header
    if [[ $no_claude_keys -eq 1 ]]; then
        # Called from cc dispatcher - no Claude keybindings
        fzf_header="Enter=cd | ^S=status | ^L=log | ^C=cancel"
        if [[ $show_resume -eq 1 ]]; then
            fzf_header="Enter=resume | Space=browse | ^S=status | ^L=log"
        fi
    else
        # Normal mode - include Claude keybindings
        fzf_header="Enter=cd | ^O=cc | ^Y=ccy | ^S=status | ^L=log"
        if [[ $show_resume -eq 1 ]]; then
            fzf_header="Enter=resume | Space=browse | ^O=cc | ^Y=ccy"
        fi
    fi

    # Build fzf command with conditional Claude keybindings
    local fzf_output
    if [[ $no_claude_keys -eq 1 ]]; then
        fzf_output=$(cat "$tmpfile" | fzf \
            --height=50% \
            --reverse \
            --print-query \
            --expect=space \
            --header="$fzf_header" \
            --bind="ctrl-s:execute-silent(echo status > $action_file)+accept" \
            --bind="ctrl-l:execute-silent(echo log > $action_file)+accept")
    else
        fzf_output=$(cat "$tmpfile" | fzf \
            --height=50% \
            --reverse \
            --print-query \
            --expect=space \
            --header="$fzf_header" \
            --bind="ctrl-s:execute-silent(echo status > $action_file)+accept" \
            --bind="ctrl-l:execute-silent(echo log > $action_file)+accept" \
            --bind="ctrl-o:execute-silent(echo cc > $action_file)+accept" \
            --bind="ctrl-y:execute-silent(echo ccy > $action_file)+accept")
    fi

    local fzf_exit=$?
    rm -f "$tmpfile"

    # Parse fzf output (3 lines: query, key, selection)
    local query=$(echo "$fzf_output" | sed -n '1p')
    local key=$(echo "$fzf_output" | sed -n '2p')
    local selection=$(echo "$fzf_output" | sed -n '3p')

    # Handle Space key - force full picker (bypass resume)
    if [[ "$key" == "space" ]]; then
        rm -f "$action_file"
        # Re-run without resume prompt
        pick -a
        return $?
    fi

    # Handle Enter with empty query = resume last project
    if [[ $show_resume -eq 1 && -z "$query" && -z "$selection" && $fzf_exit -eq 0 ]]; then
        rm -f "$action_file"
        cd "$last_dir"
        _proj_save_session "$last_dir"
        echo "  📂 Resumed: $last_dir"
        return 0
    fi

    # Handle cancellation (Ctrl-C or Esc)
    if [[ -z "$selection" && $fzf_exit -ne 0 ]]; then
        rm -f "$action_file"
        return 1
    fi

    # If no selection but we have a query, it might be a partial match - treat as cancel
    if [[ -z "$selection" ]]; then
        rm -f "$action_file"
        return 1
    fi

    # Extract project/worktree name from selection and find directory
    local proj_name proj_dir

    if [[ $is_worktree_mode -eq 1 ]]; then
        # For worktrees: extract "project (branch)" format
        # The selection looks like: "project (branch)    🌳 wt"
        proj_name=$(echo "$selection" | sed 's/[[:space:]]*🌳.*//' | xargs)
        proj_dir=$(_proj_find_worktree "$proj_name")
    else
        # For regular projects: just the first word
        proj_name=$(echo "$selection" | awk '{print $1}')
        proj_dir=$(_proj_find "$proj_name")
    fi

    if [[ -z "$proj_dir" || ! -d "$proj_dir" ]]; then
        echo "❌ Directory not found: $proj_name" >&2
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
            _proj_save_session "$proj_dir"
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
            _proj_save_session "$proj_dir"
            echo ""
            echo "  📜 Git log for: $proj_name"
            echo ""
            if command -v tig &>/dev/null; then
                tig
            else
                git log --oneline --graph --decorate -20
            fi
            ;;
        cc)
            # Launch Claude Code in acceptEdits mode
            cd "$proj_dir"
            _proj_save_session "$proj_dir"
            echo ""
            echo "  📂 Changed to: $proj_dir"
            if [[ $is_worktree_mode -eq 1 ]]; then
                _proj_show_git_status "$proj_dir"
            fi
            echo ""
            echo "  🤖 Launching Claude Code..."
            claude --permission-mode acceptEdits
            ;;
        ccy)
            # Launch Claude Code in YOLO mode
            cd "$proj_dir"
            _proj_save_session "$proj_dir"
            echo ""
            echo "  📂 Changed to: $proj_dir"
            if [[ $is_worktree_mode -eq 1 ]]; then
                _proj_show_git_status "$proj_dir"
            fi
            echo ""
            echo "  🚀 Launching Claude Code (YOLO mode)..."
            claude --dangerously-skip-permissions
            ;;
        *)
            cd "$proj_dir"
            _proj_save_session "$proj_dir"
            echo ""
            echo "  📂 Changed to: $proj_dir"
            # Show git status for worktrees (extra context helpful)
            if [[ $is_worktree_mode -eq 1 ]]; then
                _proj_show_git_status "$proj_dir"
            fi
            echo ""
            ;;
    esac
}

# ============================================================================
# CATEGORY ALIASES
# ============================================================================

alias pickr='pick r'
alias pickdev='pick dev'
alias pickq='pick q'
alias pickteach='pick teach'
alias pickrs='pick rs'
alias pickapp='pick app'
alias pickwt='pick wt'

# Removed 'pp' alias - conflicts with /usr/bin/pp (use full 'pick' command)
