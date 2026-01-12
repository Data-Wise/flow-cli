# lib/project-cache.zsh - Project list caching layer
# Implements 5-minute TTL cache for project discovery to achieve sub-10ms pick response

# ============================================================================
# CACHE CONFIGURATION
# ============================================================================

# Cache file location (follows XDG standard)
PROJ_CACHE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/flow-cli/projects.cache"

# Cache TTL in seconds (default: 5 minutes)
PROJ_CACHE_TTL="${PROJ_CACHE_TTL:-300}"

# Feature flag (default: enabled)
FLOW_CACHE_ENABLED="${FLOW_CACHE_ENABLED:-1}"

# ============================================================================
# CACHE GENERATION
# ============================================================================

# Generate cache from filesystem scan
# Calls the uncached version of _proj_list_all and stores result with timestamp
_proj_cache_generate() {
    local cache_dir=$(dirname "$PROJ_CACHE_FILE")
    mkdir -p "$cache_dir" 2>/dev/null || {
        _flow_log_error "Failed to create cache directory: $cache_dir"
        return 1
    }

    # Write cache with timestamp header
    {
        echo "# Generated: $(date +%s)"
        _proj_list_all_uncached "$@"
    } > "$PROJ_CACHE_FILE" 2>/dev/null || {
        _flow_log_error "Failed to write cache file: $PROJ_CACHE_FILE"
        return 1
    }

    return 0
}

# ============================================================================
# CACHE VALIDATION
# ============================================================================

# Check if cache is valid (exists and within TTL)
# Returns: 0 if valid, 1 if invalid or stale
_proj_cache_is_valid() {
    [[ -f "$PROJ_CACHE_FILE" ]] || return 1

    local cache_time=$(head -1 "$PROJ_CACHE_FILE" 2>/dev/null | sed 's/# Generated: //')

    # Validate timestamp format
    [[ "$cache_time" =~ ^[0-9]+$ ]] || return 1

    local now=$(date +%s)
    local age=$((now - cache_time))

    [[ $age -lt $PROJ_CACHE_TTL ]]
}

# ============================================================================
# CACHE ACCESS
# ============================================================================

# Get cached project list (or regenerate if stale)
# This is the public API that replaces _proj_list_all
_proj_list_all_cached() {
    # If cache disabled, use direct scan
    if [[ "$FLOW_CACHE_ENABLED" != "1" ]]; then
        _proj_list_all_uncached "$@"
        return
    fi

    # Check if cache is valid
    if ! _proj_cache_is_valid; then
        _proj_cache_generate "$@" || {
            # Fallback to uncached if generation fails
            _proj_list_all_uncached "$@"
            return
        }
    fi

    # Return cached data (skip timestamp line)
    tail -n +2 "$PROJ_CACHE_FILE" 2>/dev/null || {
        # Fallback to uncached if read fails
        _proj_list_all_uncached "$@"
    }
}

# ============================================================================
# CACHE INVALIDATION
# ============================================================================

# Invalidate cache (force regeneration on next access)
_proj_cache_invalidate() {
    if [[ -f "$PROJ_CACHE_FILE" ]]; then
        rm -f "$PROJ_CACHE_FILE" 2>/dev/null
        return $?
    fi
    return 0
}

# ============================================================================
# CACHE STATISTICS
# ============================================================================

# Display cache statistics
_proj_cache_stats() {
    if [[ ! -f "$PROJ_CACHE_FILE" ]]; then
        echo "Cache status: No cache file exists"
        echo "Location: $PROJ_CACHE_FILE"
        return 1
    fi

    local cache_time=$(head -1 "$PROJ_CACHE_FILE" 2>/dev/null | sed 's/# Generated: //')

    if [[ ! "$cache_time" =~ ^[0-9]+$ ]]; then
        echo "Cache status: Invalid cache file (corrupt timestamp)"
        return 1
    fi

    local now=$(date +%s)
    local age=$((now - cache_time))
    local age_str=$(_proj_format_duration "$age")

    local count=$(tail -n +2 "$PROJ_CACHE_FILE" 2>/dev/null | wc -l | tr -d ' ')

    local status_icon
    local status_text
    if _proj_cache_is_valid; then
        status_icon="🟢"
        status_text="Valid"
    else
        status_icon="🟡"
        status_text="Stale (will regenerate)"
    fi

    echo "Cache status: ${status_icon} ${status_text}"
    echo "Cache age: ${age_str} (TTL: ${PROJ_CACHE_TTL}s)"
    echo "Projects cached: ${count}"
    echo "Location: $PROJ_CACHE_FILE"
}

# Format duration in human-readable form
_proj_format_duration() {
    local seconds=$1
    local mins=$((seconds / 60))
    local secs=$((seconds % 60))

    if [[ $mins -gt 0 ]]; then
        echo "${mins}m ${secs}s"
    else
        echo "${secs}s"
    fi
}

# ============================================================================
# PUBLIC COMMANDS
# ============================================================================

# flow cache refresh - Manually invalidate and regenerate cache
flow-cache-refresh() {
    echo "Refreshing project cache..."
    _proj_cache_invalidate

    if _proj_cache_generate; then
        echo "✅ Cache refreshed"
        _proj_cache_stats
    else
        echo "❌ Cache refresh failed"
        return 1
    fi
}

# flow cache clear - Delete cache file
flow-cache-clear() {
    if [[ -f "$PROJ_CACHE_FILE" ]]; then
        rm -f "$PROJ_CACHE_FILE"
        echo "✅ Cache cleared"
    else
        echo "Cache already clear (no cache file)"
    fi
}

# flow cache status - Show cache statistics
flow-cache-status() {
    _proj_cache_stats
}
