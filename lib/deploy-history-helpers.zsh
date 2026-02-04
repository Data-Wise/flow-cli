#!/usr/bin/env zsh
# deploy-history-helpers.zsh - Append-only YAML deploy history tracking
#
# Provides functions for recording and querying deployment history
# stored at .flow/deploy-history.yml within a teaching course repo.
#
# Design decisions:
#   - Append-only writes (>>) for _deploy_history_append — never rewrites the file
#   - yq used only for READING (list, get, count)
#   - History file is git-tracked
#   - Timestamps in ISO 8601 with timezone
#   - Commit hashes truncated to 8 characters
#
# Functions:
#   _deploy_history_append  - Record a new deploy entry
#   _deploy_history_list    - Display recent deploys as a formatted table
#   _deploy_history_get     - Retrieve a specific entry by display index
#   _deploy_history_count   - Return total number of recorded deploys

# --- Append -----------------------------------------------------------

# Append deploy entry to history file
# Usage: _deploy_history_append <mode> <commit_hash> <commit_before> <branch_from> <branch_to> <file_count> <commit_message> [pr_number] [tag] [duration]
_deploy_history_append() {
    local mode="$1"
    local commit_hash="$2"
    local commit_before="$3"
    local branch_from="$4"
    local branch_to="$5"
    local file_count="${6:-0}"
    local commit_message="$7"
    local pr_number="${8:-null}"
    local tag="${9:-null}"
    local duration="${10:-0}"

    local history_file=".flow/deploy-history.yml"
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%S%z')
    local user
    user=$(whoami)

    # Initialise file with top-level key when it doesn't exist yet
    if [[ ! -f "$history_file" ]]; then
        mkdir -p .flow
        echo "deploys:" > "$history_file"
    fi

    # Escape single quotes in all string fields so YAML stays valid
    local safe_message="${commit_message//\'/\'\'}"
    local safe_mode="${mode//\'/\'\'}"
    local safe_branch_from="${branch_from//\'/\'\'}"
    local safe_branch_to="${branch_to//\'/\'\'}"
    local safe_user="${user//\'/\'\'}"

    # Append entry using heredoc — no yq rewrite
    cat >> "$history_file" << EOF
  - timestamp: '${timestamp}'
    mode: '${safe_mode}'
    commit_hash: '${commit_hash:0:8}'
    commit_before: '${commit_before:0:8}'
    branch_from: '${safe_branch_from}'
    branch_to: '${safe_branch_to}'
    file_count: ${file_count}
    commit_message: '${safe_message}'
    pr_number: ${pr_number}
    tag: ${tag}
    user: '${safe_user}'
    duration_seconds: ${duration}
EOF

    return 0
}

# --- List -------------------------------------------------------------

# List recent deployments from history
# Usage: _deploy_history_list [count]
# Output: Formatted table of recent deploys
_deploy_history_list() {
    local count="${1:-5}"
    local history_file=".flow/deploy-history.yml"

    if [[ ! -f "$history_file" ]]; then
        echo "  No deployment history found."
        echo "  Deploy with 'teach deploy' to start tracking."
        return 1
    fi

    local total_deploys
    total_deploys=$(yq '.deploys | length' "$history_file" 2>/dev/null)

    if [[ -z "$total_deploys" || "$total_deploys" -eq 0 ]]; then
        echo "  No deployments recorded."
        return 1
    fi

    echo ""
    echo "  Recent deployments:"
    echo ""
    printf "  %-4s %-18s %-8s %-6s %s\n" "#" "When" "Mode" "Files" "Message"
    printf "  %-4s %-18s %-8s %-6s %s\n" "---" "------------------" "--------" "------" "-------"

    # Walk in reverse order (most recent first), capped at $count
    local start_idx=$(( total_deploys - 1 ))
    local end_idx=$(( total_deploys - count ))
    [[ $end_idx -lt 0 ]] && end_idx=0

    local display_num=1
    for (( i = start_idx; i >= end_idx; i-- )); do
        local ts mode files msg
        ts=$(yq ".deploys[$i].timestamp" "$history_file" 2>/dev/null)
        mode=$(yq ".deploys[$i].mode" "$history_file" 2>/dev/null)
        files=$(yq ".deploys[$i].file_count" "$history_file" 2>/dev/null)
        msg=$(yq ".deploys[$i].commit_message" "$history_file" 2>/dev/null)

        # Shorten timestamp: "2026-02-03T14:30" -> "2026-02-03 14:30"
        local short_ts="${ts:0:16}"
        short_ts="${short_ts//T/ }"

        # Truncate long messages
        [[ ${#msg} -gt 40 ]] && msg="${msg:0:37}..."

        printf "  %-4s %-18s %-8s %-6s %s\n" "$display_num" "$short_ts" "$mode" "$files" "$msg"
        (( display_num++ ))
    done

    echo ""
    return 0
}

# --- Get --------------------------------------------------------------

# Get deploy entry by display index (1 = most recent)
# Usage: _deploy_history_get <display_index>
# Output: Sets DEPLOY_HIST_* variables for the caller
_deploy_history_get() {
    local display_idx="$1"
    local history_file=".flow/deploy-history.yml"

    if [[ ! -f "$history_file" ]]; then
        return 1
    fi

    local total_deploys
    total_deploys=$(yq '.deploys | length' "$history_file" 2>/dev/null)

    if [[ -z "$total_deploys" || "$total_deploys" -eq 0 ]]; then
        return 1
    fi

    # Convert display index (1 = newest) to zero-based array index
    local array_idx=$(( total_deploys - display_idx ))

    if [[ $array_idx -lt 0 || $array_idx -ge $total_deploys ]]; then
        return 1
    fi

    # Export entry fields into caller's scope
    DEPLOY_HIST_TIMESTAMP=$(yq ".deploys[$array_idx].timestamp" "$history_file" 2>/dev/null)
    DEPLOY_HIST_MODE=$(yq ".deploys[$array_idx].mode" "$history_file" 2>/dev/null)
    DEPLOY_HIST_COMMIT=$(yq ".deploys[$array_idx].commit_hash" "$history_file" 2>/dev/null)
    DEPLOY_HIST_COMMIT_BEFORE=$(yq ".deploys[$array_idx].commit_before" "$history_file" 2>/dev/null)
    DEPLOY_HIST_BRANCH_FROM=$(yq ".deploys[$array_idx].branch_from" "$history_file" 2>/dev/null)
    DEPLOY_HIST_BRANCH_TO=$(yq ".deploys[$array_idx].branch_to" "$history_file" 2>/dev/null)
    DEPLOY_HIST_FILE_COUNT=$(yq ".deploys[$array_idx].file_count" "$history_file" 2>/dev/null)
    DEPLOY_HIST_MESSAGE=$(yq ".deploys[$array_idx].commit_message" "$history_file" 2>/dev/null)
    DEPLOY_HIST_PR=$(yq ".deploys[$array_idx].pr_number" "$history_file" 2>/dev/null)
    DEPLOY_HIST_TAG=$(yq ".deploys[$array_idx].tag" "$history_file" 2>/dev/null)
    DEPLOY_HIST_USER=$(yq ".deploys[$array_idx].user" "$history_file" 2>/dev/null)
    DEPLOY_HIST_DURATION=$(yq ".deploys[$array_idx].duration_seconds" "$history_file" 2>/dev/null)

    return 0
}

# --- Count ------------------------------------------------------------

# Get total deploy count
# Usage: _deploy_history_count
# Output: Prints the count to stdout
_deploy_history_count() {
    local history_file=".flow/deploy-history.yml"

    if [[ ! -f "$history_file" ]]; then
        echo "0"
        return
    fi

    yq '.deploys | length' "$history_file" 2>/dev/null || echo "0"
}
