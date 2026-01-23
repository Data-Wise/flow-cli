#!/usr/bin/env zsh

# =============================================================================
# lib/doctor-cache.zsh
# Cache manager for flow doctor token validation results
# =============================================================================
#
# Features:
#   - 5-minute TTL cache for token validation results
#   - Prevents GitHub API rate limiting
#   - Concurrent access safety with flock
#   - Performance target: < 10ms cache check
#   - Simple JSON format for token validation state
#
# Cache Directory Structure:
#   ~/.flow/
#   ├── cache/
#   │   └── doctor/
#   │       ├── token-github.cache      # GitHub token validation result
#   │       ├── token-npm.cache         # NPM token validation result
#   │       └── token-pypi.cache        # PyPI token validation result
#
# Cache File Format (JSON):
#   {
#     "token_name": "github-token",
#     "provider": "github",
#     "cached_at": "2026-01-23T12:30:00Z",
#     "expires_at": "2026-01-23T12:35:00Z",
#     "ttl_seconds": 300,
#     "status": "valid",
#     "days_remaining": 45,
#     "username": "your-username",
#     "metadata": {
#       "token_age_days": 100,
#       "token_type": "fine-grained",
#       "services": {
#         "gh_cli": "authenticated",
#         "claude_mcp": "configured",
#         "env_var": "missing"
#       }
#     }
#   }
#
# =============================================================================

# Load guard - prevent double-sourcing
if [[ -n "$_FLOW_DOCTOR_CACHE_LOADED" ]]; then
    return 0 2>/dev/null || true
fi
typeset -g _FLOW_DOCTOR_CACHE_LOADED=1

# Disable zsh options that cause variable assignments to print
unsetopt local_options 2>/dev/null
unsetopt print_exit_value 2>/dev/null
setopt NO_local_options 2>/dev/null

# Source core library if not already loaded
if ! typeset -f _flow_log_debug >/dev/null 2>&1; then
    source "${0:A:h}/core.zsh" 2>/dev/null || true
fi

# =============================================================================
# CONSTANTS
# =============================================================================

# Default TTL in seconds (5 minutes)
readonly DOCTOR_CACHE_DEFAULT_TTL=300

# Lock timeout in seconds
readonly DOCTOR_CACHE_LOCK_TIMEOUT=2

# Maximum age for cache cleanup (1 day)
readonly DOCTOR_CACHE_MAX_AGE_SECONDS=86400

# Cache directory (respect if already set, e.g., by tests)
if [[ -z "$DOCTOR_CACHE_DIR" ]]; then
    readonly DOCTOR_CACHE_DIR="${HOME}/.flow/cache/doctor"
fi

# =============================================================================
# INTERNAL HELPERS
# =============================================================================

# =============================================================================
# Function: _doctor_cache_get_cache_path
# Purpose: Get the cache file path for a token
# =============================================================================
# Arguments:
#   $1 - (required) Cache key (e.g., "token-github", "token-npm")
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Path to cache file
#
# Example:
#   cache_file=$(_doctor_cache_get_cache_path "token-github")
#   # Returns: ~/.flow/cache/doctor/token-github.cache
# =============================================================================
_doctor_cache_get_cache_path() {
    local key="$1"
    echo "${DOCTOR_CACHE_DIR}/${key}.cache"
}

# =============================================================================
# Function: _doctor_cache_get_lock_path
# Purpose: Get the lock file path for cache operations
# =============================================================================
# Arguments:
#   $1 - (required) Cache key
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Path to lock file
# =============================================================================
_doctor_cache_get_lock_path() {
    local key="$1"
    echo "${DOCTOR_CACHE_DIR}/.${key}.lock"
}

# =============================================================================
# Function: _doctor_cache_acquire_lock
# Purpose: Acquire exclusive lock for cache write operations
# =============================================================================
# Arguments:
#   $1 - (required) Cache key
#
# Returns:
#   0 - Lock acquired
#   1 - Failed to acquire lock (timeout)
#
# Notes:
#   - Uses flock if available, falls back to mkdir-based locking
#   - Lock is released when the shell exits or when _doctor_cache_release_lock called
# =============================================================================
_doctor_cache_acquire_lock() {
    local key="$1"
    local lock_path
    lock_path=$(_doctor_cache_get_lock_path "$key")

    # Ensure directory exists
    mkdir -p "${DOCTOR_CACHE_DIR}" 2>/dev/null

    # Check if flock is available
    if command -v flock >/dev/null 2>&1; then
        # Create lock file if it doesn't exist
        touch "$lock_path" 2>/dev/null

        # Use flock with timeout
        # Use file descriptor 201 for doctor cache locks
        exec 201>"$lock_path"
        if ! flock -w "$DOCTOR_CACHE_LOCK_TIMEOUT" 201 2>/dev/null; then
            _flow_log_debug "Failed to acquire cache lock for $key (timeout)" 2>/dev/null
            return 1
        fi
        return 0
    fi

    # Fallback: mkdir-based locking (atomic on POSIX systems)
    local lock_dir="${lock_path}.d"
    local attempts=0
    local max_attempts=$((DOCTOR_CACHE_LOCK_TIMEOUT * 10))

    while (( attempts < max_attempts )); do
        if mkdir "$lock_dir" 2>/dev/null; then
            # Store PID for debugging
            echo $$ > "$lock_dir/pid"
            return 0
        fi

        # Check if lock is stale (holder process dead)
        if [[ -f "$lock_dir/pid" ]]; then
            local holder_pid
            holder_pid=$(cat "$lock_dir/pid" 2>/dev/null)
            if [[ -n "$holder_pid" ]] && ! kill -0 "$holder_pid" 2>/dev/null; then
                # Stale lock, remove it
                rm -rf "$lock_dir" 2>/dev/null
                continue
            fi
        fi

        # Wait 100ms before retry
        sleep 0.1
        ((attempts++))
    done

    _flow_log_debug "Failed to acquire cache lock for $key (timeout)" 2>/dev/null
    return 1
}

# =============================================================================
# Function: _doctor_cache_release_lock
# Purpose: Release exclusive lock for cache operations
# =============================================================================
# Arguments:
#   $1 - (required) Cache key
#
# Returns:
#   0 - Always succeeds
# =============================================================================
_doctor_cache_release_lock() {
    local key="$1"
    local lock_path
    lock_path=$(_doctor_cache_get_lock_path "$key")

    # Release flock (if using flock)
    if command -v flock >/dev/null 2>&1; then
        exec 201>&- 2>/dev/null || true
    fi

    # Remove mkdir-based lock
    local lock_dir="${lock_path}.d"
    rm -rf "$lock_dir" 2>/dev/null || true

    return 0
}

# =============================================================================
# CORE FUNCTIONS
# =============================================================================

# =============================================================================
# Function: _doctor_cache_init
# Purpose: Initialize cache directory structure
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Success
#   1 - Failed to initialize
#
# Example:
#   _doctor_cache_init
#   if [[ $? -eq 0 ]]; then
#       echo "Cache initialized"
#   fi
#
# Notes:
#   - Creates ~/.flow/cache/doctor/ directory
#   - Runs cleanup of old cache entries (> 1 day)
# =============================================================================
_doctor_cache_init() {
    # Create cache directory
    if [[ ! -d "$DOCTOR_CACHE_DIR" ]]; then
        mkdir -p "$DOCTOR_CACHE_DIR" 2>/dev/null || {
            _flow_log_error "Failed to create cache directory: $DOCTOR_CACHE_DIR" 2>/dev/null || \
                echo "Error: Failed to create cache directory: $DOCTOR_CACHE_DIR" >&2
            return 1
        }
    fi

    # Clean old cache entries (best-effort, don't fail if cleanup fails)
    _doctor_cache_clean_old >/dev/null 2>&1 || true

    _flow_log_debug "Doctor cache initialized at: $DOCTOR_CACHE_DIR" 2>/dev/null
    return 0
}

# =============================================================================
# Function: _doctor_cache_get
# Purpose: Get cached token validation result if still valid
# =============================================================================
# Arguments:
#   $1 - (required) Cache key (e.g., "token-github")
#
# Returns:
#   0 - Cache hit (valid entry found)
#   1 - Cache miss (no entry, expired, or invalid)
#
# Output:
#   stdout - Cached JSON data (only on cache hit)
#
# Performance:
#   Target: < 10ms for cache check
#
# Example:
#   if cached_data=$(_doctor_cache_get "token-github"); then
#       echo "Cache hit!"
#       status=$(echo "$cached_data" | jq -r '.status')
#       days=$(echo "$cached_data" | jq -r '.days_remaining')
#   else
#       echo "Cache miss, need to validate token"
#   fi
# =============================================================================
_doctor_cache_get() {
    local key="$1"

    if [[ -z "$key" ]]; then
        _flow_log_debug "Cache get: empty key" 2>/dev/null
        return 1
    fi

    local cache_file
    cache_file=$(_doctor_cache_get_cache_path "$key")

    # Check if cache file exists
    if [[ ! -f "$cache_file" ]]; then
        _flow_log_debug "Cache miss: file not found for $key" 2>/dev/null
        return 1
    fi

    # Check if jq is available
    if ! command -v jq >/dev/null 2>&1; then
        _flow_log_debug "Cache miss: jq not available" 2>/dev/null
        return 1
    fi

    # Read cache file
    local cache_data
    cache_data=$(cat "$cache_file" 2>/dev/null)
    if [[ -z "$cache_data" ]]; then
        _flow_log_debug "Cache miss: empty cache file for $key" 2>/dev/null
        return 1
    fi

    # Validate JSON format
    if ! echo "$cache_data" | jq empty 2>/dev/null; then
        _flow_log_debug "Cache miss: invalid JSON for $key" 2>/dev/null
        return 1
    fi

    # Check expiration
    local expires_at current_epoch expires_epoch
    expires_at=$(echo "$cache_data" | jq -r '.expires_at // ""')

    if [[ -z "$expires_at" ]]; then
        _flow_log_debug "Cache miss: no expiration for $key" 2>/dev/null
        return 1
    fi

    # Convert ISO 8601 to epoch (macOS vs Linux compatible)
    if [[ "$(uname)" == "Darwin" ]]; then
        expires_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$expires_at" +%s 2>/dev/null || echo 0)
    else
        expires_epoch=$(date -d "$expires_at" +%s 2>/dev/null || echo 0)
    fi
    current_epoch=$(date +%s)

    if (( current_epoch >= expires_epoch )); then
        _flow_log_debug "Cache miss: expired for $key (current: $current_epoch, expires: $expires_epoch)" 2>/dev/null
        return 1
    fi

    # Cache hit!
    _flow_log_debug "Cache hit for $key (expires in $((expires_epoch - current_epoch))s)" 2>/dev/null
    echo "$cache_data"
    return 0
}

# =============================================================================
# Function: _doctor_cache_set
# Purpose: Store token validation result in cache
# =============================================================================
# Arguments:
#   $1 - (required) Cache key (e.g., "token-github")
#   $2 - (required) Value to cache (JSON string or plain text)
#   $3 - (optional) TTL in seconds [default: 300 = 5 minutes]
#
# Returns:
#   0 - Success
#   1 - Failed to write cache
#
# Example:
#   # Cache token validation result
#   validation_json='{"status": "valid", "days_remaining": 45, "username": "user"}'
#   _doctor_cache_set "token-github" "$validation_json"
#
#   # Cache with custom TTL (10 minutes)
#   _doctor_cache_set "token-npm" "$validation_json" 600
#
# Notes:
#   - Uses atomic write (temp file + mv)
#   - Uses flock for concurrent access safety
#   - Stores value with metadata (timestamps, TTL)
#   - If value is not valid JSON, wraps it in a JSON object
# =============================================================================
_doctor_cache_set() {
    local key="$1"
    local value="$2"
    local ttl="${3:-$DOCTOR_CACHE_DEFAULT_TTL}"

    if [[ -z "$key" || -z "$value" ]]; then
        _flow_log_error "Cache set: missing key or value" 2>/dev/null
        return 1
    fi

    # Ensure cache is initialized
    _doctor_cache_init || return 1

    local cache_file
    cache_file=$(_doctor_cache_get_cache_path "$key")

    # Calculate timestamps
    local cached_at expires_at
    cached_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    if [[ "$(uname)" == "Darwin" ]]; then
        expires_at=$(date -u -v+"${ttl}S" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
    else
        expires_at=$(date -u -d "+${ttl} seconds" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
    fi

    # Acquire lock for writing
    if ! _doctor_cache_acquire_lock "$key"; then
        _flow_log_error "Failed to acquire cache lock for writing: $key" 2>/dev/null
        return 1
    fi

    local write_success=0

    # Check if jq is available
    if command -v jq >/dev/null 2>&1; then
        local temp_cache="${cache_file}.tmp.$$"

        # Check if value is already valid JSON with required fields
        local is_complete_json=0
        if echo "$value" | jq -e '.cached_at and .expires_at and .ttl_seconds' >/dev/null 2>&1; then
            is_complete_json=1
        fi

        if [[ $is_complete_json -eq 1 ]]; then
            # Value is already a complete cache entry, just write it
            echo "$value" > "$temp_cache" 2>/dev/null
        else
            # Check if value is valid JSON
            if echo "$value" | jq empty 2>/dev/null; then
                # Value is valid JSON but incomplete - wrap it with metadata
                jq -n \
                    --arg cached_at "$cached_at" \
                    --arg expires_at "$expires_at" \
                    --argjson ttl_seconds "$ttl" \
                    --argjson data "$value" \
                    '{
                        cached_at: $cached_at,
                        expires_at: $expires_at,
                        ttl_seconds: $ttl_seconds
                    } + $data' > "$temp_cache" 2>/dev/null
            else
                # Value is plain text - wrap in JSON
                jq -n \
                    --arg cached_at "$cached_at" \
                    --arg expires_at "$expires_at" \
                    --argjson ttl_seconds "$ttl" \
                    --arg value "$value" \
                    '{
                        cached_at: $cached_at,
                        expires_at: $expires_at,
                        ttl_seconds: $ttl_seconds,
                        value: $value
                    }' > "$temp_cache" 2>/dev/null
            fi
        fi

        if [[ $? -eq 0 && -f "$temp_cache" ]]; then
            mv "$temp_cache" "$cache_file" 2>/dev/null && write_success=1
        fi
        rm -f "$temp_cache" 2>/dev/null
    else
        # Fallback without jq - simple format
        cat > "$cache_file" << EOF
# Cache entry: $key
TIMESTAMP=$(date +%s)
TTL=$ttl
EXPIRES=$(($(date +%s) + ttl))
VALUE=$value
EOF
        write_success=$?
    fi

    _doctor_cache_release_lock "$key"

    if [[ $write_success -eq 1 ]]; then
        _flow_log_debug "Cache written for: $key (TTL: ${ttl}s)" 2>/dev/null
        return 0
    else
        _flow_log_error "Failed to write cache for: $key" 2>/dev/null
        return 1
    fi
}

# =============================================================================
# Function: _doctor_cache_clear
# Purpose: Clear specific cache entry or entire cache
# =============================================================================
# Arguments:
#   $1 - (optional) Cache key to clear [default: clear all]
#
# Returns:
#   0 - Success
#   1 - Failed to clear
#
# Example:
#   # Clear specific token cache
#   _doctor_cache_clear "token-github"
#
#   # Clear all doctor cache entries
#   _doctor_cache_clear
#
# Notes:
#   - Used when token is rotated to invalidate cached validation
#   - Safe to call even if cache doesn't exist
# =============================================================================
_doctor_cache_clear() {
    local key="$1"

    if [[ -z "$key" ]]; then
        # Clear entire cache
        if [[ -d "$DOCTOR_CACHE_DIR" ]]; then
            rm -f "${DOCTOR_CACHE_DIR}"/*.cache 2>/dev/null
            _flow_log_debug "Cleared all doctor cache entries" 2>/dev/null
        fi
        return 0
    fi

    # Clear specific entry
    local cache_file
    cache_file=$(_doctor_cache_get_cache_path "$key")

    if [[ -f "$cache_file" ]]; then
        rm -f "$cache_file" 2>/dev/null
        _flow_log_debug "Cleared cache for: $key" 2>/dev/null
    fi

    return 0
}

# =============================================================================
# Function: _doctor_cache_stats
# Purpose: Show cache statistics and list cached entries
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Success
#   1 - No cache found
#
# Output:
#   stdout - Cache statistics (formatted text)
#
# Example:
#   _doctor_cache_stats
#   # Output:
#   # Doctor Cache Statistics
#   # =======================
#   # Cache directory: ~/.flow/cache/doctor
#   # Total entries: 3
#   # Total size: 12 KB
#   #
#   # Cached Entries:
#   #   token-github    (valid, expires in 4m 23s)
#   #   token-npm       (valid, expires in 2m 15s)
#   #   token-pypi      (expired)
# =============================================================================
_doctor_cache_stats() {
    if [[ ! -d "$DOCTOR_CACHE_DIR" ]]; then
        echo "No doctor cache found"
        return 1
    fi

    # Count entries
    local cache_files
    cache_files=("${DOCTOR_CACHE_DIR}"/*.cache(N))
    local entry_count=${#cache_files[@]}

    # Calculate total size
    local total_size=0
    if [[ $entry_count -gt 0 ]]; then
        for file in "${cache_files[@]}"; do
            if [[ -f "$file" ]]; then
                local size
                size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
                total_size=$((total_size + size))
            fi
        done
    fi

    # Display statistics
    echo "Doctor Cache Statistics"
    echo "======================="
    echo "Cache directory: $DOCTOR_CACHE_DIR"
    echo "Total entries: $entry_count"
    echo "Total size: $((total_size / 1024)) KB"
    echo ""

    if [[ $entry_count -eq 0 ]]; then
        echo "No cached entries"
        return 0
    fi

    echo "Cached Entries:"

    local current_epoch
    current_epoch=$(date +%s)

    for cache_file in "${cache_files[@]}"; do
        [[ ! -f "$cache_file" ]] && continue

        local key="${cache_file:t:r}"

        if command -v jq >/dev/null 2>&1; then
            local expires_at token_status
            expires_at=$(jq -r '.expires_at // ""' "$cache_file" 2>/dev/null)
            token_status=$(jq -r '.status // "unknown"' "$cache_file" 2>/dev/null)

            if [[ -n "$expires_at" ]]; then
                local expires_epoch
                if [[ "$(uname)" == "Darwin" ]]; then
                    expires_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$expires_at" +%s 2>/dev/null || echo 0)
                else
                    expires_epoch=$(date -d "$expires_at" +%s 2>/dev/null || echo 0)
                fi

                local remaining=$((expires_epoch - current_epoch))

                if (( remaining > 0 )); then
                    local mins=$((remaining / 60))
                    local secs=$((remaining % 60))
                    echo "  $key    ($token_status, expires in ${mins}m ${secs}s)"
                else
                    echo "  $key    (expired)"
                fi
            else
                echo "  $key    ($token_status, no expiration)"
            fi
        else
            echo "  $key"
        fi
    done

    return 0
}

# =============================================================================
# Function: _doctor_cache_clean_old
# Purpose: Clean up cache entries older than 1 day
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Success
#   1 - Failed to clean
#
# Output:
#   stdout - Number of entries cleaned
#
# Example:
#   cleaned=$(_doctor_cache_clean_old)
#   echo "Cleaned $cleaned old entries"
#
# Notes:
#   - Automatically called during cache init
#   - Removes entries > DOCTOR_CACHE_MAX_AGE_SECONDS old
#   - Safe to run multiple times
# =============================================================================
_doctor_cache_clean_old() {
    if [[ ! -d "$DOCTOR_CACHE_DIR" ]]; then
        echo "0"
        return 0
    fi

    local cleaned_count=0
    local current_epoch
    current_epoch=$(date +%s)
    local cutoff_epoch=$((current_epoch - DOCTOR_CACHE_MAX_AGE_SECONDS))

    # Find and clean old cache files
    local cache_files
    cache_files=("${DOCTOR_CACHE_DIR}"/*.cache(N))

    for cache_file in "${cache_files[@]}"; do
        [[ ! -f "$cache_file" ]] && continue

        # Get file modification time
        local file_mtime
        if [[ "$(uname)" == "Darwin" ]]; then
            file_mtime=$(stat -f%m "$cache_file" 2>/dev/null || echo 0)
        else
            file_mtime=$(stat -c%Y "$cache_file" 2>/dev/null || echo 0)
        fi

        # Remove if older than cutoff
        if (( file_mtime < cutoff_epoch )); then
            rm -f "$cache_file" 2>/dev/null && ((cleaned_count++))
            _flow_log_debug "Cleaned old cache file: ${cache_file:t}" 2>/dev/null
        fi
    done

    # Also clean old lock files
    local lock_files
    lock_files=("${DOCTOR_CACHE_DIR}"/.*.lock(N) "${DOCTOR_CACHE_DIR}"/.*.lock.d(N))
    for lock_file in "${lock_files[@]}"; do
        [[ ! -e "$lock_file" ]] && continue

        local lock_mtime
        if [[ "$(uname)" == "Darwin" ]]; then
            lock_mtime=$(stat -f%m "$lock_file" 2>/dev/null || echo 0)
        else
            lock_mtime=$(stat -c%Y "$lock_file" 2>/dev/null || echo 0)
        fi

        if (( lock_mtime < cutoff_epoch )); then
            rm -rf "$lock_file" 2>/dev/null
        fi
    done

    _flow_log_debug "Cleaned $cleaned_count old cache entries" 2>/dev/null
    echo "$cleaned_count"
    return 0
}

# =============================================================================
# CONVENIENCE FUNCTIONS
# =============================================================================

# =============================================================================
# Function: _doctor_cache_token_get
# Purpose: Convenience wrapper to get token validation cache
# =============================================================================
# Arguments:
#   $1 - (required) Provider name (github, npm, pypi)
#
# Returns:
#   0 - Cache hit
#   1 - Cache miss
#
# Output:
#   stdout - Cached token validation JSON
#
# Example:
#   if cached=$(_doctor_cache_token_get "github"); then
#       status=$(echo "$cached" | jq -r '.status')
#   fi
# =============================================================================
_doctor_cache_token_get() {
    local provider="$1"
    [[ -z "$provider" ]] && return 1
    _doctor_cache_get "token-${provider}"
}

# =============================================================================
# Function: _doctor_cache_token_set
# Purpose: Convenience wrapper to cache token validation result
# =============================================================================
# Arguments:
#   $1 - (required) Provider name (github, npm, pypi)
#   $2 - (required) Validation result JSON
#   $3 - (optional) TTL in seconds [default: 300]
#
# Returns:
#   0 - Success
#   1 - Failed
#
# Example:
#   result='{"status": "valid", "days_remaining": 45}'
#   _doctor_cache_token_set "github" "$result"
# =============================================================================
_doctor_cache_token_set() {
    local provider="$1"
    local value="$2"
    local ttl="${3:-$DOCTOR_CACHE_DEFAULT_TTL}"

    [[ -z "$provider" || -z "$value" ]] && return 1
    _doctor_cache_set "token-${provider}" "$value" "$ttl"
}

# =============================================================================
# Function: _doctor_cache_token_clear
# Purpose: Convenience wrapper to invalidate token validation cache
# =============================================================================
# Arguments:
#   $1 - (required) Provider name (github, npm, pypi)
#
# Returns:
#   0 - Success
#
# Example:
#   # After rotating GitHub token, invalidate cache
#   _doctor_cache_token_clear "github"
# =============================================================================
_doctor_cache_token_clear() {
    local provider="$1"
    [[ -z "$provider" ]] && return 1
    _doctor_cache_clear "token-${provider}"
}

# =============================================================================
# EXPORT FUNCTIONS
# =============================================================================

# Mark as loaded
typeset -g _FLOW_DOCTOR_CACHE_LOADED=1

# End of lib/doctor-cache.zsh
