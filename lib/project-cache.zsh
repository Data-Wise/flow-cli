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

# =============================================================================
# Function: _proj_cache_generate
# Purpose: Generate project cache from filesystem scan and write to cache file
# =============================================================================
# Arguments:
#   None (always generates complete unfiltered list)
#
# Returns:
#   0 - Cache successfully generated
#   1 - Error (failed to create directory or write file)
#
# Output:
#   Cache file written to $PROJ_CACHE_FILE with format:
#     Line 1: "# Generated: <unix_timestamp>"
#     Lines 2+: Project data from _proj_list_all_uncached
#
# Example:
#   _proj_cache_generate           # Regenerate cache
#   _proj_cache_generate && echo "Success"
#
# Notes:
#   - ALWAYS caches complete project list (no filters)
#   - Filters (category, recent) applied at read time by _proj_list_all_cached
#   - Creates cache directory if it doesn't exist (~/.cache/flow-cli/)
#   - Overwrites existing cache file
#   - Called automatically when cache is stale or missing
# =============================================================================
_proj_cache_generate() {
    local cache_dir=$(dirname "$PROJ_CACHE_FILE")
    mkdir -p "$cache_dir" 2>/dev/null || {
        _flow_log_error "Failed to create cache directory: $cache_dir"
        return 1
    }

    # Write cache with timestamp header
    # NOTE: No filters passed - always cache complete project list
    {
        echo "# Generated: $(date +%s)"
        _proj_list_all_uncached  # No "$@" - cache everything
    } > "$PROJ_CACHE_FILE" 2>/dev/null || {
        _flow_log_error "Failed to write cache file: $PROJ_CACHE_FILE"
        return 1
    }

    return 0
}

# ============================================================================
# CACHE VALIDATION
# ============================================================================

# =============================================================================
# Function: _proj_cache_is_valid
# Purpose: Check if project cache exists and is within TTL (not stale)
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Cache is valid (exists, has valid timestamp, within TTL)
#   1 - Cache is invalid (missing, corrupt timestamp, or stale)
#
# Output:
#   None
#
# Example:
#   if _proj_cache_is_valid; then
#       echo "Using cached data"
#   else
#       _proj_cache_generate
#   fi
#
# Notes:
#   - Reads $PROJ_CACHE_FILE and extracts timestamp from first line
#   - Validates timestamp is numeric (rejects corrupt cache)
#   - Compares age against $PROJ_CACHE_TTL (default: 300 seconds / 5 minutes)
#   - Called by _proj_list_all_cached before using cache
# =============================================================================
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

# =============================================================================
# Function: _proj_list_all_cached
# Purpose: Get project list from cache with optional filtering (main public API)
# =============================================================================
# Arguments:
#   $1 - (optional) Category filter (e.g., "dev", "r-package", "teaching")
#   $2 - (optional) "recent" to show only projects with active/recent sessions
#
# Returns:
#   0 - Always (falls back to uncached on errors)
#
# Output:
#   stdout - Pipe-delimited project list: name|type|icon|dir|session_status
#            Filtered by category and/or recent status if specified
#
# Example:
#   _proj_list_all_cached                    # All projects
#   _proj_list_all_cached "dev"              # Only dev-tools projects
#   _proj_list_all_cached "" "recent"        # Only recent sessions
#   _proj_list_all_cached "r-package" ""     # Only R packages
#
# Notes:
#   - Primary API for project listing (replaces _proj_list_all)
#   - Automatically regenerates cache if stale or missing
#   - Falls back to _proj_list_all_uncached on any error
#   - Respects FLOW_CACHE_ENABLED=0 to bypass caching
#   - Session status: 🟢 (recent), 🟡 (old), empty (no session)
# =============================================================================
_proj_list_all_cached() {
    local category="${1:-}"
    local recent_only="${2:-}"

    # If cache disabled, use direct scan
    if [[ "$FLOW_CACHE_ENABLED" != "1" ]]; then
        _proj_list_all_uncached "$@"
        return
    fi

    # Check if cache is valid
    if ! _proj_cache_is_valid; then
        _proj_cache_generate || {  # No filters - cache everything
            # Fallback to uncached if generation fails
            _proj_list_all_uncached "$@"
            return
        }
    fi

    # Read complete cached data (skip timestamp line)
    local cached_data=$(tail -n +2 "$PROJ_CACHE_FILE" 2>/dev/null) || {
        # Fallback to uncached if read fails
        _proj_list_all_uncached "$@"
        return
    }

    # Apply category filter if specified
    # Format: name|type|icon|dir|session_status
    if [[ -n "$category" ]]; then
        cached_data=$(echo "$cached_data" | grep "|${category}|")
    fi

    # Apply recent-only filter if specified
    # Session status: 🟢 (recent) or 🟡 (old) or empty (no session)
    if [[ "$recent_only" == "recent" ]]; then
        cached_data=$(echo "$cached_data" | grep -E '\|[🟢🟡]')
    fi

    echo "$cached_data"
}

# ============================================================================
# CACHE INVALIDATION
# ============================================================================

# =============================================================================
# Function: _proj_cache_invalidate
# Purpose: Delete cache file to force regeneration on next access
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Cache invalidated (or didn't exist)
#   Non-zero - Failed to delete cache file
#
# Output:
#   None
#
# Example:
#   _proj_cache_invalidate                  # Clear cache
#   _proj_cache_invalidate && echo "Cleared"
#
# Notes:
#   - Simply deletes the cache file
#   - Next call to _proj_list_all_cached will trigger regeneration
#   - Safe to call even if cache doesn't exist
#   - Used by flow-cache-refresh and when project structure changes
# =============================================================================
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

# =============================================================================
# Function: _proj_cache_stats
# Purpose: Display detailed cache statistics and health status
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Cache exists and stats displayed
#   1 - Cache file doesn't exist or is corrupt
#
# Output:
#   stdout - Formatted cache status including:
#            - Status with icon (🟢 Valid / 🟡 Stale)
#            - Cache age in human-readable format
#            - Number of projects cached
#            - Cache file location
#
# Example:
#   _proj_cache_stats
#   # Output:
#   # Cache status: 🟢 Valid
#   # Cache age: 2m 30s (TTL: 300s)
#   # Projects cached: 47
#   # Location: ~/.cache/flow-cli/projects.cache
#
# Notes:
#   - Used by flow-cache-status command
#   - Shows "will regenerate" message if cache is stale
#   - Handles corrupt cache gracefully with error message
# =============================================================================
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

# =============================================================================
# Function: _proj_format_duration
# Purpose: Convert seconds to human-readable duration string
# =============================================================================
# Arguments:
#   $1 - (required) Duration in seconds
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Formatted duration string (e.g., "2m 30s" or "45s")
#
# Example:
#   _proj_format_duration 150    # Output: 2m 30s
#   _proj_format_duration 45     # Output: 45s
#   _proj_format_duration 0      # Output: 0s
#
# Notes:
#   - Only shows minutes if duration >= 60 seconds
#   - Used by _proj_cache_stats for cache age display
#   - Simple helper, no hours/days support (cache TTL is typically minutes)
# =============================================================================
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

# =============================================================================
# Function: flow-cache-refresh
# Purpose: Manually invalidate and regenerate the project cache
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Cache successfully refreshed
#   1 - Cache refresh failed
#
# Output:
#   stdout - Progress message and cache stats on success
#            Error message on failure
#
# Example:
#   flow-cache-refresh
#   # Output:
#   # Refreshing project cache...
#   # ✅ Cache refreshed
#   # Cache status: 🟢 Valid
#   # Cache age: 0s (TTL: 300s)
#   # Projects cached: 47
#
# Notes:
#   - Public command for manual cache management
#   - Useful after adding/removing projects outside normal workflow
#   - Calls _proj_cache_invalidate then _proj_cache_generate
#   - Shows cache stats after successful refresh
# =============================================================================
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

# =============================================================================
# Function: flow-cache-clear
# Purpose: Delete the project cache file without regenerating
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Confirmation message
#
# Example:
#   flow-cache-clear
#   # Output: ✅ Cache cleared
#
# Notes:
#   - Different from flow-cache-refresh: does NOT regenerate
#   - Next project list operation will trigger fresh scan
#   - Useful for debugging or when cache is suspected corrupt
#   - Safe to call even if cache doesn't exist
# =============================================================================
flow-cache-clear() {
    if [[ -f "$PROJ_CACHE_FILE" ]]; then
        rm -f "$PROJ_CACHE_FILE"
        echo "✅ Cache cleared"
    else
        echo "Cache already clear (no cache file)"
    fi
}

# =============================================================================
# Function: flow-cache-status
# Purpose: Display current cache status and statistics
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   Return value from _proj_cache_stats (0 if exists, 1 if not)
#
# Output:
#   stdout - Cache statistics (delegates to _proj_cache_stats)
#
# Example:
#   flow-cache-status
#   # Output:
#   # Cache status: 🟢 Valid
#   # Cache age: 2m 30s (TTL: 300s)
#   # Projects cached: 47
#   # Location: ~/.cache/flow-cli/projects.cache
#
# Notes:
#   - Public command wrapper around _proj_cache_stats
#   - Useful for debugging slow pick performance
#   - Shows whether cache will regenerate on next access
# =============================================================================
flow-cache-status() {
    _proj_cache_stats
}
