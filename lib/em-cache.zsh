#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# Email Cache Manager — TTL-based AI result caching
# ══════════════════════════════════════════════════════════════════════════════
#
# File:         lib/em-cache.zsh
# Version:      0.1
# Date:         2026-02-10
#
# Used by:      lib/em-ai.zsh, lib/dispatchers/email-dispatcher.zsh
#
# Structure:
#   .flow/email-cache/          (project-local, gitignored)
#     summaries/<hash>.txt      1-line summary
#     classifications/<hash>.txt category name
#     drafts/<hash>.txt         draft response
#     schedules/<hash>.json     extracted dates
#
# ══════════════════════════════════════════════════════════════════════════════

# TTL values (seconds)
typeset -gA _EM_CACHE_TTL=(
    [summaries]=86400       # 24 hours — summaries don't change
    [classifications]=86400 # 24 hours — classification is stable
    [drafts]=3600           # 1 hour — drafts might need refreshing
    [schedules]=86400       # 24 hours
    [unread]=60             # 1 minute — unread count changes often
)

# ═══════════════════════════════════════════════════════════════════
# CACHE DIRECTORY
# ═══════════════════════════════════════════════════════════════════

_em_cache_dir() {
    # Get cache directory (project-local if in project, else global)
    local project_root=""
    if typeset -f _flow_find_project_root &>/dev/null; then
        project_root=$(_flow_find_project_root 2>/dev/null)
    fi

    if [[ -n "$project_root" && -d "$project_root/.flow" ]]; then
        echo "$project_root/.flow/email-cache"
    else
        echo "${FLOW_DATA_DIR}/email-cache"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# CACHE KEY GENERATION
# ═══════════════════════════════════════════════════════════════════

_em_cache_key() {
    # Generate filesystem-safe cache key from message ID
    # Uses md5 hash to avoid special characters
    local msg_id="$1"
    echo "$msg_id" | md5 -q 2>/dev/null || echo "$msg_id" | md5sum 2>/dev/null | cut -d' ' -f1
}

# ═══════════════════════════════════════════════════════════════════
# CACHE READ/WRITE
# ═══════════════════════════════════════════════════════════════════

_em_cache_get() {
    # Get cached result if fresh (within TTL)
    # Args: operation (summaries|classifications|drafts|schedules|unread), key
    # Returns: cached content on stdout, exit 0 if hit, 1 if miss
    local operation="$1" cache_id="$2"
    local cache_base="$(_em_cache_dir)/$operation"
    local key=$(_em_cache_key "$cache_id")
    local cache_file="$cache_base/$key.txt"

    [[ ! -f "$cache_file" ]] && return 1

    # Check TTL
    local ttl="${_EM_CACHE_TTL[$operation]:-3600}"
    local file_mod
    file_mod=$(stat -f %m "$cache_file" 2>/dev/null || echo 0)
    local now=$(date +%s)
    local file_age=$(( now - file_mod ))

    if (( file_age > ttl )); then
        rm -f "$cache_file"
        return 1
    fi

    cat "$cache_file"
    return 0
}

_em_cache_set() {
    # Write result to cache
    # Args: operation, key, content
    local operation="$1" cache_id="$2" content="$3"
    local cache_base="$(_em_cache_dir)/$operation"
    local key=$(_em_cache_key "$cache_id")

    [[ ! -d "$cache_base" ]] && mkdir -p "$cache_base"
    echo "$content" > "$cache_base/$key.txt"
}

# ═══════════════════════════════════════════════════════════════════
# CACHE INVALIDATION
# ═══════════════════════════════════════════════════════════════════

_em_cache_invalidate() {
    # Invalidate cache for a message (all operations)
    local cache_id="$1"
    local cache_base="$(_em_cache_dir)"
    local key=$(_em_cache_key "$cache_id")

    for op_dir in "$cache_base"/*(N/); do
        rm -f "$op_dir/$key.txt"
    done
}

_em_cache_clear() {
    # Clear entire cache
    local cache_base="$(_em_cache_dir)"
    if [[ -d "$cache_base" ]]; then
        local size
        size=$(du -sh "$cache_base" 2>/dev/null | awk '{print $1}')
        rm -rf "$cache_base"
        _flow_log_success "Email cache cleared ($size freed)"
    else
        _flow_log_info "No email cache to clear"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# CACHE STATS
# ═══════════════════════════════════════════════════════════════════

_em_cache_stats() {
    # Show cache statistics
    local cache_base="$(_em_cache_dir)"
    if [[ ! -d "$cache_base" ]]; then
        echo -e "  ${_C_DIM}No cache${_C_NC}"
        return
    fi

    echo -e "${_C_BOLD}Email Cache${_C_NC}"
    for op_dir in "$cache_base"/*(N/); do
        local op_name="${op_dir:t}"
        local count
        count=$(ls -1 "$op_dir" 2>/dev/null | wc -l | tr -d ' ')
        local size
        size=$(du -sh "$op_dir" 2>/dev/null | awk '{print $1}')
        printf "  %-18s %4s items  %s\n" "$op_name" "$count" "$size"
    done
    echo ""
}

# ═══════════════════════════════════════════════════════════════════
# CACHE WARMING (background)
# ═══════════════════════════════════════════════════════════════════

_em_cache_warm() {
    # Background-warm cache for latest N messages
    # Called by: em dash, em inbox (background)
    # Only warms if AI is available
    local count="${1:-10}"

    # Bail if no AI available
    typeset -f _em_ai_available &>/dev/null || return 0
    [[ -z "$(_em_ai_available)" ]] && return 0

    # Get latest message IDs
    local msg_ids
    msg_ids=($(_em_hml_list INBOX "$count" 2>/dev/null | jq -r '.[].id' 2>/dev/null))

    for msg_id in "${msg_ids[@]}"; do
        # Skip if already cached
        _em_cache_get "summaries" "$msg_id" &>/dev/null && continue

        # Background: classify + summarize
        {
            local content
            content=$(_em_hml_read "$msg_id" plain 2>/dev/null)
            [[ -z "$content" ]] && continue
            _em_ai_query "classify" "$(_em_ai_classify_prompt)" "$content" "" "$msg_id" &>/dev/null
            _em_ai_query "summarize" "$(_em_ai_summarize_prompt)" "$content" "" "$msg_id" &>/dev/null
        } &
    done
    # Don't wait — let it run in background
}
