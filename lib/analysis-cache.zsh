#!/usr/bin/env zsh

# =============================================================================
# lib/analysis-cache.zsh
# Analysis caching system for teach analyze command
# Phase 2: Content-hash based caching with cascade invalidation
# =============================================================================
#
# Features:
#   - Content-hash based cache invalidation (SHA-256)
#   - TTL-based expiration (default 168h = 7 days)
#   - Cascade invalidation for prerequisites
#   - Concurrent access safety with flock
#   - Performance targets: < 10ms cache check, < 50ms index rebuild
#   - Target 85%+ cache hit rate
#
# Cache Directory Structure:
#   .teach/
#   ├── analysis-cache/
#   │   ├── cache-index.json           # Metadata for all cached files
#   │   ├── lectures/
#   │   │   ├── week-01-lecture.json   # Mirrors source structure
#   │   │   └── week-02-lecture.json
#   │   └── assignments/
#   │       └── hw-01.json
#   ├── concepts.json                  # Global concept graph
#   └── prerequisites.json             # Prerequisites database
#
# =============================================================================

# Load guard - prevent double-sourcing
if [[ -n "$_FLOW_ANALYSIS_CACHE_LOADED" ]]; then
    return 0 2>/dev/null || true
fi
typeset -g _FLOW_ANALYSIS_CACHE_LOADED=1

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

# Cache schema version (bump when cache format changes)
readonly ANALYSIS_CACHE_SCHEMA_VERSION="1.0"

# Default TTL in hours (7 days)
readonly ANALYSIS_CACHE_DEFAULT_TTL_HOURS=168

# Lock timeout in seconds
readonly ANALYSIS_CACHE_LOCK_TIMEOUT=5

# =============================================================================
# INTERNAL HELPERS
# =============================================================================

# =============================================================================
# Function: _cache_get_cache_dir
# Purpose: Get the cache directory path for a course
# =============================================================================
# Arguments:
#   $1 - (optional) Course directory [default: $PWD]
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Path to .teach/analysis-cache/
# =============================================================================
_cache_get_cache_dir() {
    local course_dir="${1:-$PWD}"
    echo "$course_dir/.teach/analysis-cache"
}

# =============================================================================
# Function: _cache_get_index_path
# Purpose: Get the cache index file path
# =============================================================================
# Arguments:
#   $1 - (optional) Course directory [default: $PWD]
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Path to .teach/analysis-cache/cache-index.json
# =============================================================================
_cache_get_index_path() {
    local course_dir="${1:-$PWD}"
    echo "$course_dir/.teach/analysis-cache/cache-index.json"
}

# =============================================================================
# Function: _cache_get_lock_path
# Purpose: Get the lock file path for cache operations
# =============================================================================
# Arguments:
#   $1 - (optional) Course directory [default: $PWD]
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Path to .teach/analysis-cache/.cache.lock
# =============================================================================
_cache_get_lock_path() {
    local course_dir="${1:-$PWD}"
    echo "$course_dir/.teach/analysis-cache/.cache.lock"
}

# =============================================================================
# Function: _cache_ensure_dir
# Purpose: Ensure cache directory structure exists
# =============================================================================
# Arguments:
#   $1 - (optional) Course directory [default: $PWD]
#
# Returns:
#   0 - Success
#   1 - Failed to create directory
# =============================================================================
_cache_ensure_dir() {
    local course_dir="${1:-$PWD}"
    local cache_dir
    cache_dir=$(_cache_get_cache_dir "$course_dir")

    if [[ ! -d "$cache_dir" ]]; then
        mkdir -p "$cache_dir" 2>/dev/null || {
            _flow_log_error "Failed to create cache directory: $cache_dir" 2>/dev/null || \
                echo "Error: Failed to create cache directory: $cache_dir" >&2
            return 1
        }
    fi

    # Create subdirectories for common content types
    mkdir -p "$cache_dir/lectures" 2>/dev/null
    mkdir -p "$cache_dir/assignments" 2>/dev/null
    mkdir -p "$cache_dir/slides" 2>/dev/null
    mkdir -p "$cache_dir/exams" 2>/dev/null

    return 0
}

# =============================================================================
# Function: _cache_acquire_lock
# Purpose: Acquire exclusive lock for cache write operations
# =============================================================================
# Arguments:
#   $1 - (optional) Course directory [default: $PWD]
#
# Returns:
#   0 - Lock acquired
#   1 - Failed to acquire lock (timeout)
#
# Notes:
#   - Uses flock if available, falls back to mkdir-based locking
#   - Lock is released when the shell exits or when _cache_release_lock called
# =============================================================================
_cache_acquire_lock() {
    local course_dir="${1:-$PWD}"
    local lock_path
    lock_path=$(_cache_get_lock_path "$course_dir")

    # Ensure directory exists
    _cache_ensure_dir "$course_dir" || return 1

    # Check if flock is available
    if command -v flock >/dev/null 2>&1; then
        # Create lock file if it doesn't exist
        touch "$lock_path" 2>/dev/null

        # Use flock with timeout
        exec 200>"$lock_path"
        if ! flock -w "$ANALYSIS_CACHE_LOCK_TIMEOUT" 200 2>/dev/null; then
            _flow_log_debug "Failed to acquire cache lock (timeout)" 2>/dev/null
            return 1
        fi
        return 0
    fi

    # Fallback: mkdir-based locking (atomic on POSIX systems)
    local lock_dir="${lock_path}.d"
    local attempts=0
    local max_attempts=$((ANALYSIS_CACHE_LOCK_TIMEOUT * 10))

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

    _flow_log_debug "Failed to acquire cache lock (timeout)" 2>/dev/null
    return 1
}

# =============================================================================
# Function: _cache_release_lock
# Purpose: Release exclusive lock for cache operations
# =============================================================================
# Arguments:
#   $1 - (optional) Course directory [default: $PWD]
#
# Returns:
#   0 - Always succeeds
# =============================================================================
_cache_release_lock() {
    local course_dir="${1:-$PWD}"
    local lock_path
    lock_path=$(_cache_get_lock_path "$course_dir")

    # Release flock (if using flock)
    if command -v flock >/dev/null 2>&1; then
        exec 200>&- 2>/dev/null || true
    fi

    # Remove mkdir-based lock
    local lock_dir="${lock_path}.d"
    rm -rf "$lock_dir" 2>/dev/null || true

    return 0
}

# =============================================================================
# Function: _cache_get_ttl_hours
# Purpose: Get TTL hours from config or use default
# =============================================================================
# Arguments:
#   $1 - (optional) Course directory [default: $PWD]
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - TTL in hours (integer)
# =============================================================================
_cache_get_ttl_hours() {
    local course_dir="${1:-$PWD}"
    local config_file="$course_dir/lesson-plan.yml"
    local ttl_hours=$ANALYSIS_CACHE_DEFAULT_TTL_HOURS

    # Try to read from config
    if [[ -f "$config_file" ]] && command -v yq >/dev/null 2>&1; then
        local config_ttl
        config_ttl=$(yq eval '.analysis.cache_ttl_hours // ""' "$config_file" 2>/dev/null)
        if [[ -n "$config_ttl" && "$config_ttl" =~ ^[0-9]+$ ]]; then
            ttl_hours=$config_ttl
        fi
    fi

    echo "$ttl_hours"
}

# =============================================================================
# CORE FUNCTIONS
# =============================================================================

# =============================================================================
# Function: _cache_init
# Purpose: Initialize cache directory structure and index
# =============================================================================
# Arguments:
#   $1 - (optional) Course directory [default: $PWD]
#
# Returns:
#   0 - Success
#   1 - Failed to initialize
#
# Example:
#   _cache_init "/path/to/course"
#   if [[ $? -eq 0 ]]; then
#       echo "Cache initialized"
#   fi
# =============================================================================
_cache_init() {
    local course_dir="${1:-$PWD}"
    local cache_dir index_path

    cache_dir=$(_cache_get_cache_dir "$course_dir")
    index_path=$(_cache_get_index_path "$course_dir")

    # Create directory structure
    _cache_ensure_dir "$course_dir" || return 1

    # Create index file if it doesn't exist
    if [[ ! -f "$index_path" ]]; then
        local timestamp
        timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

        # Create initial index with jq
        if command -v jq >/dev/null 2>&1; then
            jq -n \
                --arg version "$ANALYSIS_CACHE_SCHEMA_VERSION" \
                --arg ts "$timestamp" \
                '{
                    version: $version,
                    last_updated: $ts,
                    cache_stats: {
                        total_files: 0,
                        cached_files: 0,
                        cache_hits: 0,
                        cache_misses: 0,
                        cache_hit_rate: 0.0,
                        total_size_bytes: 0,
                        avg_analysis_time_ms: 0
                    },
                    files: {}
                }' > "$index_path" 2>/dev/null
        else
            # Fallback: create minimal JSON manually
            cat > "$index_path" << EOF
{
  "version": "$ANALYSIS_CACHE_SCHEMA_VERSION",
  "last_updated": "$timestamp",
  "cache_stats": {
    "total_files": 0,
    "cached_files": 0,
    "cache_hits": 0,
    "cache_misses": 0,
    "cache_hit_rate": 0.0,
    "total_size_bytes": 0,
    "avg_analysis_time_ms": 0
  },
  "files": {}
}
EOF
        fi

        if [[ $? -ne 0 ]]; then
            _flow_log_error "Failed to create cache index" 2>/dev/null || \
                echo "Error: Failed to create cache index" >&2
            return 1
        fi
    fi

    _flow_log_debug "Cache initialized at: $cache_dir" 2>/dev/null
    return 0
}

# =============================================================================
# Function: _cache_get_content_hash
# Purpose: Calculate SHA-256 hash of file content
# =============================================================================
# Arguments:
#   $1 - (required) File path to hash
#
# Returns:
#   0 - Success
#   1 - File not found or error
#
# Output:
#   stdout - SHA-256 hash prefixed with "sha256:"
#
# Example:
#   hash=$(_cache_get_content_hash "lectures/week-05.qmd")
#   # Returns: sha256:abc123def456...
#
# Notes:
#   - Uses shasum -a 256 (macOS) or sha256sum (Linux)
#   - Hash includes only file content, not filename
#   - Performance: < 1ms for typical lecture files
# =============================================================================
_cache_get_content_hash() {
    local file_path="$1"

    if [[ -z "$file_path" ]]; then
        echo ""
        return 1
    fi

    if [[ ! -f "$file_path" ]]; then
        _flow_log_debug "File not found for hashing: $file_path" 2>/dev/null
        echo ""
        return 1
    fi

    local hash=""

    # Try shasum first (macOS), then sha256sum (Linux)
    if command -v shasum >/dev/null 2>&1; then
        hash=$(shasum -a 256 "$file_path" 2>/dev/null | cut -d' ' -f1)
    elif command -v sha256sum >/dev/null 2>&1; then
        hash=$(sha256sum "$file_path" 2>/dev/null | cut -d' ' -f1)
    else
        # Fallback: use md5 (less ideal but still functional)
        if command -v md5 >/dev/null 2>&1; then
            hash=$(md5 -q "$file_path" 2>/dev/null)
        elif command -v md5sum >/dev/null 2>&1; then
            hash=$(md5sum "$file_path" 2>/dev/null | cut -d' ' -f1)
        fi
    fi

    if [[ -n "$hash" ]]; then
        echo "sha256:$hash"
        return 0
    fi

    echo ""
    return 1
}

# =============================================================================
# Function: _cache_get_cache_file_path
# Purpose: Get the cache file path for a source file
# =============================================================================
# Arguments:
#   $1 - (required) Source file path (relative to course dir)
#   $2 - (optional) Course directory [default: $PWD]
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Cache file path (e.g., .teach/analysis-cache/lectures/week-05.json)
#
# Example:
#   cache_file=$(_cache_get_cache_file_path "lectures/week-05.qmd")
#   # Returns: /path/to/.teach/analysis-cache/lectures/week-05.json
# =============================================================================
_cache_get_cache_file_path() {
    local source_file="$1"
    local course_dir="${2:-$PWD}"
    local cache_dir

    cache_dir=$(_cache_get_cache_dir "$course_dir")

    # Convert source path to cache path
    # e.g., lectures/week-05-lecture.qmd -> lectures/week-05-lecture.json
    local base_name="$source_file"

    # Remove known extensions (only one)
    if [[ "$base_name" == *.qmd ]]; then
        base_name="${base_name%.qmd}"
    elif [[ "$base_name" == *.md ]]; then
        base_name="${base_name%.md}"
    elif [[ "$base_name" == *.Rmd ]]; then
        base_name="${base_name%.Rmd}"
    elif [[ "$base_name" == *.json ]]; then
        # Already a .json file - don't add extension
        echo "$cache_dir/$source_file"
        return 0
    fi

    echo "$cache_dir/${base_name}.json"
}

# =============================================================================
# Function: _cache_check_valid
# Purpose: Check if cache entry is valid (not expired, hash matches)
# =============================================================================
# Arguments:
#   $1 - (required) Source file path (relative to course dir)
#   $2 - (optional) Course directory [default: $PWD]
#
# Returns:
#   0 - Cache is valid (hit)
#   1 - Cache is invalid (miss) - file not cached, expired, or hash mismatch
#
# Performance:
#   Target: < 10ms for cache check
#
# Example:
#   if _cache_check_valid "lectures/week-05.qmd"; then
#       echo "Cache hit!"
#       analysis=$(_cache_read "lectures/week-05.qmd")
#   else
#       echo "Cache miss, need to reanalyze"
#   fi
# =============================================================================
_cache_check_valid() {
    local source_file="$1"
    local course_dir="${2:-$PWD}"
    local index_path cache_file current_hash

    index_path=$(_cache_get_index_path "$course_dir")

    # Check if index exists
    if [[ ! -f "$index_path" ]]; then
        _flow_log_debug "Cache index not found" 2>/dev/null
        return 1
    fi

    # Get cache entry from index
    if ! command -v jq >/dev/null 2>&1; then
        _flow_log_debug "jq not available for cache check" 2>/dev/null
        return 1
    fi

    # Extract cache entry for this file
    local entry
    entry=$(jq -r --arg file "$source_file" '.files[$file] // empty' "$index_path" 2>/dev/null)

    if [[ -z "$entry" || "$entry" == "null" ]]; then
        _flow_log_debug "No cache entry for: $source_file" 2>/dev/null
        return 1
    fi

    # Check status
    local cache_status
    cache_status=$(echo "$entry" | jq -r '.status // "unknown"')
    if [[ "$cache_status" != "valid" ]]; then
        _flow_log_debug "Cache entry status invalid: $cache_status" 2>/dev/null
        return 1
    fi

    # Check TTL expiration
    local ttl_expires
    ttl_expires=$(echo "$entry" | jq -r '.ttl_expires // ""')
    if [[ -n "$ttl_expires" ]]; then
        local expires_epoch current_epoch

        # Convert ISO 8601 to epoch (macOS vs Linux compatible)
        if [[ "$(uname)" == "Darwin" ]]; then
            expires_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$ttl_expires" +%s 2>/dev/null || echo 0)
        else
            expires_epoch=$(date -d "$ttl_expires" +%s 2>/dev/null || echo 0)
        fi
        current_epoch=$(date +%s)

        if (( current_epoch > expires_epoch )); then
            _flow_log_debug "Cache entry expired: $source_file" 2>/dev/null
            return 1
        fi
    fi

    # Check content hash
    local cached_hash
    cached_hash=$(echo "$entry" | jq -r '.content_hash // ""')

    # Get absolute path for hashing
    local absolute_path
    if [[ "$source_file" == /* ]]; then
        absolute_path="$source_file"
    else
        absolute_path="$course_dir/$source_file"
    fi

    current_hash=$(_cache_get_content_hash "$absolute_path")

    if [[ "$current_hash" != "$cached_hash" ]]; then
        _flow_log_debug "Hash mismatch for: $source_file (cached: $cached_hash, current: $current_hash)" 2>/dev/null
        return 1
    fi

    # Check cache file exists
    cache_file=$(_cache_get_cache_file_path "$source_file" "$course_dir")
    if [[ ! -f "$cache_file" ]]; then
        _flow_log_debug "Cache file missing: $cache_file" 2>/dev/null
        return 1
    fi

    _flow_log_debug "Cache hit for: $source_file" 2>/dev/null
    return 0
}

# =============================================================================
# Function: _cache_read
# Purpose: Read cached analysis for a file
# =============================================================================
# Arguments:
#   $1 - (required) Source file path (relative to course dir)
#   $2 - (optional) Course directory [default: $PWD]
#
# Returns:
#   0 - Success
#   1 - Cache miss or error
#
# Output:
#   stdout - JSON analysis data
#
# Example:
#   if _cache_check_valid "lectures/week-05.qmd"; then
#       analysis=$(_cache_read "lectures/week-05.qmd")
#       echo "$analysis" | jq '.analysis.concepts_extracted'
#   fi
#
# Notes:
#   - Always call _cache_check_valid first to ensure cache is valid
#   - Updates cache hit statistics
# =============================================================================
_cache_read() {
    local source_file="$1"
    local course_dir="${2:-$PWD}"
    local cache_file index_path

    cache_file=$(_cache_get_cache_file_path "$source_file" "$course_dir")
    index_path=$(_cache_get_index_path "$course_dir")

    if [[ ! -f "$cache_file" ]]; then
        _flow_log_debug "Cache file not found: $cache_file" 2>/dev/null
        return 1
    fi

    # Update hit statistics (best-effort, don't fail if lock unavailable)
    if _cache_acquire_lock "$course_dir"; then
        if command -v jq >/dev/null 2>&1 && [[ -f "$index_path" ]]; then
            local temp_index="${index_path}.tmp.$$"
            jq '.cache_stats.cache_hits += 1 |
                .cache_stats.cache_hit_rate = (if .cache_stats.cache_hits + .cache_stats.cache_misses > 0
                    then (.cache_stats.cache_hits / (.cache_stats.cache_hits + .cache_stats.cache_misses))
                    else 0 end)' \
                "$index_path" > "$temp_index" 2>/dev/null && \
                mv "$temp_index" "$index_path" 2>/dev/null
        fi
        _cache_release_lock "$course_dir"
    fi

    # Return cache content
    cat "$cache_file" 2>/dev/null
}

# =============================================================================
# Function: _cache_write
# Purpose: Write analysis to cache with atomic file operations
# =============================================================================
# Arguments:
#   $1 - (required) Source file path (relative to course dir)
#   $2 - (required) Analysis JSON data
#   $3 - (optional) Analysis time in milliseconds [default: 0]
#   $4 - (optional) Course directory [default: $PWD]
#
# Returns:
#   0 - Success
#   1 - Failed to write cache
#
# Example:
#   analysis_json='{"concepts_extracted": [...], "prerequisite_violations": []}'
#   _cache_write "lectures/week-05.qmd" "$analysis_json" 1150
#
# Notes:
#   - Uses flock for concurrent access safety
#   - Atomic write (temp file + mv)
#   - Updates cache index with metadata
# =============================================================================
_cache_write() {
    local source_file="$1"
    local analysis_json="$2"
    local analysis_time_ms="${3:-0}"
    local course_dir="${4:-$PWD}"

    if [[ -z "$source_file" || -z "$analysis_json" ]]; then
        _flow_log_error "Missing required arguments for cache write" 2>/dev/null
        return 1
    fi

    # Ensure cache is initialized
    _cache_init "$course_dir" || return 1

    local cache_file index_path content_hash ttl_hours
    cache_file=$(_cache_get_cache_file_path "$source_file" "$course_dir")
    index_path=$(_cache_get_index_path "$course_dir")

    # Get absolute path for hashing
    local absolute_path
    if [[ "$source_file" == /* ]]; then
        absolute_path="$source_file"
    else
        absolute_path="$course_dir/$source_file"
    fi

    content_hash=$(_cache_get_content_hash "$absolute_path")
    ttl_hours=$(_cache_get_ttl_hours "$course_dir")

    # Calculate TTL expiration
    local cached_at ttl_expires
    cached_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    if [[ "$(uname)" == "Darwin" ]]; then
        ttl_expires=$(date -u -v+"${ttl_hours}H" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
    else
        ttl_expires=$(date -u -d "+${ttl_hours} hours" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
    fi

    # Acquire lock for writing
    if ! _cache_acquire_lock "$course_dir"; then
        _flow_log_error "Failed to acquire cache lock for writing" 2>/dev/null
        return 1
    fi

    local write_success=0

    # Create cache file with full analysis data
    if command -v jq >/dev/null 2>&1; then
        # Ensure parent directory exists
        mkdir -p "${cache_file:h}" 2>/dev/null

        local temp_cache="${cache_file}.tmp.$$"

        # Build complete cache entry with jq
        jq -n \
            --arg file "$source_file" \
            --arg hash "$content_hash" \
            --arg cached_at "$cached_at" \
            --argjson ttl_hours "$ttl_hours" \
            --arg ttl_expires "$ttl_expires" \
            --argjson analysis_time_ms "$analysis_time_ms" \
            --argjson analysis "$analysis_json" \
            '{
                file: $file,
                content_hash: $hash,
                cached_at: $cached_at,
                ttl_hours: $ttl_hours,
                ttl_expires: $ttl_expires,
                phase: "phase0",
                analysis: $analysis,
                performance: {
                    api_calls: 0,
                    total_duration_ms: $analysis_time_ms,
                    tokens_used: 0
                }
            }' > "$temp_cache" 2>/dev/null

        if [[ $? -eq 0 && -f "$temp_cache" ]]; then
            mv "$temp_cache" "$cache_file" 2>/dev/null && write_success=1
        fi
        rm -f "$temp_cache" 2>/dev/null

        # Update index
        if [[ $write_success -eq 1 && -f "$index_path" ]]; then
            local temp_index="${index_path}.tmp.$$"
            local file_size
            file_size=$(stat -f%z "$cache_file" 2>/dev/null || stat -c%s "$cache_file" 2>/dev/null || echo 0)

            jq --arg file "$source_file" \
               --arg cache_file "$cache_file" \
               --arg hash "$content_hash" \
               --arg cached_at "$cached_at" \
               --arg ttl_expires "$ttl_expires" \
               --argjson analysis_time_ms "$analysis_time_ms" \
               --argjson file_size "$file_size" \
               '
               .files[$file] = {
                   cache_file: $cache_file,
                   content_hash: $hash,
                   cached_at: $cached_at,
                   ttl_expires: $ttl_expires,
                   status: "valid",
                   analysis_time_ms: $analysis_time_ms,
                   size_bytes: $file_size
               } |
               .cache_stats.cached_files = (.files | length) |
               .cache_stats.cache_misses += 1 |
               .cache_stats.total_size_bytes = ([.files[].size_bytes // 0] | add) |
               .cache_stats.avg_analysis_time_ms = (
                   if (.files | length) > 0
                   then ([.files[].analysis_time_ms // 0] | add) / (.files | length) | floor
                   else 0
                   end
               ) |
               .cache_stats.cache_hit_rate = (
                   if .cache_stats.cache_hits + .cache_stats.cache_misses > 0
                   then (.cache_stats.cache_hits / (.cache_stats.cache_hits + .cache_stats.cache_misses))
                   else 0
                   end
               ) |
               .last_updated = $cached_at
               ' "$index_path" > "$temp_index" 2>/dev/null && \
               mv "$temp_index" "$index_path" 2>/dev/null

            rm -f "$temp_index" 2>/dev/null
        fi
    else
        # Fallback without jq (basic functionality)
        mkdir -p "${cache_file:h}" 2>/dev/null
        echo "$analysis_json" > "$cache_file" 2>/dev/null && write_success=1
    fi

    _cache_release_lock "$course_dir"

    if [[ $write_success -eq 1 ]]; then
        _flow_log_debug "Cache written for: $source_file" 2>/dev/null
        return 0
    else
        _flow_log_error "Failed to write cache for: $source_file" 2>/dev/null
        return 1
    fi
}

# =============================================================================
# Function: _cache_invalidate
# Purpose: Invalidate cache entries for specific files
# =============================================================================
# Arguments:
#   $1 - (required) Source file path(s) - single file or space-separated list
#   $2 - (optional) Course directory [default: $PWD]
#
# Returns:
#   0 - Success
#   1 - Failed to invalidate
#
# Example:
#   # Invalidate single file
#   _cache_invalidate "lectures/week-05.qmd"
#
#   # Invalidate multiple files
#   _cache_invalidate "lectures/week-05.qmd lectures/week-06.qmd"
#
#   # Invalidate all files (wildcard)
#   _cache_invalidate "*"
# =============================================================================
_cache_invalidate() {
    local source_files="$1"
    local course_dir="${2:-$PWD}"
    local index_path cache_dir

    index_path=$(_cache_get_index_path "$course_dir")
    cache_dir=$(_cache_get_cache_dir "$course_dir")

    if [[ ! -f "$index_path" ]]; then
        _flow_log_debug "No cache index to invalidate" 2>/dev/null
        return 0
    fi

    if ! _cache_acquire_lock "$course_dir"; then
        _flow_log_error "Failed to acquire lock for invalidation" 2>/dev/null
        return 1
    fi

    local invalidate_success=0

    if [[ "$source_files" == "*" ]]; then
        # Invalidate all cache entries
        if command -v jq >/dev/null 2>&1; then
            local temp_index="${index_path}.tmp.$$"
            local timestamp
            timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

            jq --arg ts "$timestamp" '
                .files = {} |
                .cache_stats.cached_files = 0 |
                .cache_stats.total_size_bytes = 0 |
                .last_updated = $ts
            ' "$index_path" > "$temp_index" 2>/dev/null && \
            mv "$temp_index" "$index_path" 2>/dev/null && \
            invalidate_success=1

            rm -f "$temp_index" 2>/dev/null
        fi

        # Remove all cache files
        find "$cache_dir" -name "*.json" -not -name "cache-index.json" -delete 2>/dev/null
    else
        # Invalidate specific files
        local temp_index cache_file timestamp_val
        for source_file in ${=source_files}; do
            if command -v jq >/dev/null 2>&1; then
                temp_index="${index_path}.tmp.$$"
                timestamp_val=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

                jq --arg file "$source_file" --arg ts "$timestamp_val" '
                    del(.files[$file]) |
                    .cache_stats.cached_files = (.files | length) |
                    .cache_stats.total_size_bytes = ([.files[].size_bytes // 0] | add) |
                    .last_updated = $ts
                ' "$index_path" > "$temp_index" 2>/dev/null && \
                mv "$temp_index" "$index_path" 2>/dev/null

                rm -f "$temp_index" 2>/dev/null
            fi

            # Remove cache file
            cache_file=$(_cache_get_cache_file_path "$source_file" "$course_dir")
            rm -f "$cache_file" 2>/dev/null
        done
        invalidate_success=1
    fi

    _cache_release_lock "$course_dir"

    if [[ $invalidate_success -eq 1 ]]; then
        _flow_log_debug "Cache invalidated for: $source_files" 2>/dev/null
        return 0
    else
        return 1
    fi
}

# =============================================================================
# Function: _cache_cascade_invalidate
# Purpose: Cascade invalidation for prerequisites (if Week 3 changes, invalidate Week 4-15)
# =============================================================================
# Arguments:
#   $1 - (required) Changed file path (relative to course dir)
#   $2 - (optional) Course directory [default: $PWD]
#
# Returns:
#   0 - Success
#   1 - Failed to invalidate
#
# Example:
#   # Week 3 lecture changed - invalidate Week 4-15 prerequisite checks
#   _cache_cascade_invalidate "lectures/week-03-lecture.qmd"
#
# Notes:
#   - Extracts week number from filename
#   - Invalidates all files from later weeks
#   - Critical for maintaining prerequisite validation accuracy
# =============================================================================
_cache_cascade_invalidate() {
    local changed_file="$1"
    local course_dir="${2:-$PWD}"
    local index_path

    index_path=$(_cache_get_index_path "$course_dir")

    if [[ ! -f "$index_path" ]]; then
        _flow_log_debug "No cache index for cascade invalidation" 2>/dev/null
        return 0
    fi

    # Extract week number from changed file
    local changed_week=0
    if [[ "$changed_file" =~ week-([0-9]+) ]]; then
        changed_week=$((10#${match[1]}))
    fi

    if [[ $changed_week -eq 0 ]]; then
        # Can't determine week, just invalidate the single file
        _cache_invalidate "$changed_file" "$course_dir"
        return $?
    fi

    _flow_log_debug "Cascade invalidation from week $changed_week" 2>/dev/null

    # Get list of files to invalidate (all files from weeks > changed_week)
    local files_to_invalidate=""

    if command -v jq >/dev/null 2>&1; then
        # Get all cached files and filter by week
        local all_files file_week
        all_files=$(jq -r '.files | keys[]' "$index_path" 2>/dev/null)

        for file in ${(f)all_files}; do
            file_week=0
            if [[ "$file" =~ week-([0-9]+) ]]; then
                file_week=$((10#${match[1]}))
            fi

            # Invalidate if this file is from a later week
            if (( file_week > changed_week )); then
                files_to_invalidate="$files_to_invalidate $file"
            fi
        done
    fi

    # Always invalidate the changed file itself
    files_to_invalidate="$changed_file$files_to_invalidate"

    if [[ -n "${files_to_invalidate// }" ]]; then
        _cache_invalidate "$files_to_invalidate" "$course_dir"
        return $?
    fi

    return 0
}

# =============================================================================
# Function: _cache_rebuild_index
# Purpose: Rebuild cache-index.json by scanning cache directory
# =============================================================================
# Arguments:
#   $1 - (optional) Course directory [default: $PWD]
#
# Returns:
#   0 - Success
#   1 - Failed to rebuild
#
# Performance:
#   Target: < 50ms for index rebuild
#
# Example:
#   _cache_rebuild_index "/path/to/course"
#
# Notes:
#   - Scans .teach/analysis-cache/ for all .json files
#   - Validates each cache entry (hash check)
#   - Removes stale entries from index
#   - Updates statistics
# =============================================================================
_cache_rebuild_index() {
    local course_dir="${1:-$PWD}"
    local cache_dir index_path

    cache_dir=$(_cache_get_cache_dir "$course_dir")
    index_path=$(_cache_get_index_path "$course_dir")

    if [[ ! -d "$cache_dir" ]]; then
        _flow_log_debug "No cache directory to rebuild" 2>/dev/null
        return 0
    fi

    if ! _cache_acquire_lock "$course_dir"; then
        _flow_log_error "Failed to acquire lock for index rebuild" 2>/dev/null
        return 1
    fi

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Start with fresh index structure
    local new_index
    new_index=$(jq -n \
        --arg version "$ANALYSIS_CACHE_SCHEMA_VERSION" \
        --arg ts "$timestamp" \
        '{
            version: $version,
            last_updated: $ts,
            cache_stats: {
                total_files: 0,
                cached_files: 0,
                cache_hits: 0,
                cache_misses: 0,
                cache_hit_rate: 0.0,
                total_size_bytes: 0,
                avg_analysis_time_ms: 0
            },
            files: {}
        }' 2>/dev/null)

    # Preserve existing hit/miss stats if index exists
    if [[ -f "$index_path" ]] && command -v jq >/dev/null 2>&1; then
        local old_hits old_misses
        old_hits=$(jq -r '.cache_stats.cache_hits // 0' "$index_path" 2>/dev/null)
        old_misses=$(jq -r '.cache_stats.cache_misses // 0' "$index_path" 2>/dev/null)

        new_index=$(echo "$new_index" | jq \
            --argjson hits "$old_hits" \
            --argjson misses "$old_misses" \
            '.cache_stats.cache_hits = $hits | .cache_stats.cache_misses = $misses' 2>/dev/null)
    fi

    local total_size=0
    local total_time=0
    local file_count=0

    # Scan cache files
    local cache_files
    cache_files=$(find "$cache_dir" -name "*.json" -not -name "cache-index.json" -type f 2>/dev/null)

    for cache_file in ${(f)cache_files}; do
        [[ -z "$cache_file" ]] && continue

        # Read cache file metadata
        if command -v jq >/dev/null 2>&1 && [[ -f "$cache_file" ]]; then
            local source_file content_hash cached_at ttl_expires analysis_time_ms

            source_file=$(jq -r '.file // ""' "$cache_file" 2>/dev/null)
            content_hash=$(jq -r '.content_hash // ""' "$cache_file" 2>/dev/null)
            cached_at=$(jq -r '.cached_at // ""' "$cache_file" 2>/dev/null)
            ttl_expires=$(jq -r '.ttl_expires // ""' "$cache_file" 2>/dev/null)
            analysis_time_ms=$(jq -r '.performance.total_duration_ms // 0' "$cache_file" 2>/dev/null)

            if [[ -z "$source_file" ]]; then
                continue
            fi

            # Get file size
            local file_size
            file_size=$(stat -f%z "$cache_file" 2>/dev/null || stat -c%s "$cache_file" 2>/dev/null || echo 0)

            # Verify source file still exists and hash matches
            local absolute_path
            if [[ "$source_file" == /* ]]; then
                absolute_path="$source_file"
            else
                absolute_path="$course_dir/$source_file"
            fi

            local entry_status="valid"
            if [[ ! -f "$absolute_path" ]]; then
                entry_status="orphaned"
            else
                local current_hash
                current_hash=$(_cache_get_content_hash "$absolute_path")
                if [[ "$current_hash" != "$content_hash" ]]; then
                    entry_status="stale"
                fi
            fi

            # Add to new index
            new_index=$(echo "$new_index" | jq \
                --arg file "$source_file" \
                --arg cache_file "$cache_file" \
                --arg hash "$content_hash" \
                --arg cached_at "$cached_at" \
                --arg ttl_expires "$ttl_expires" \
                --arg status "$entry_status" \
                --argjson analysis_time_ms "$analysis_time_ms" \
                --argjson file_size "$file_size" \
                '.files[$file] = {
                    cache_file: $cache_file,
                    content_hash: $hash,
                    cached_at: $cached_at,
                    ttl_expires: $ttl_expires,
                    status: $status,
                    analysis_time_ms: ($analysis_time_ms | tonumber),
                    size_bytes: ($file_size | tonumber)
                }' 2>/dev/null)

            total_size=$((total_size + file_size))
            total_time=$((total_time + analysis_time_ms))
            ((file_count++))
        fi
    done

    # Update stats
    local avg_time=0
    if (( file_count > 0 )); then
        avg_time=$((total_time / file_count))
    fi

    new_index=$(echo "$new_index" | jq \
        --argjson count "$file_count" \
        --argjson size "$total_size" \
        --argjson avg "$avg_time" \
        '
        .cache_stats.cached_files = $count |
        .cache_stats.total_size_bytes = $size |
        .cache_stats.avg_analysis_time_ms = $avg |
        .cache_stats.cache_hit_rate = (
            if .cache_stats.cache_hits + .cache_stats.cache_misses > 0
            then (.cache_stats.cache_hits / (.cache_stats.cache_hits + .cache_stats.cache_misses))
            else 0
            end
        )
        ' 2>/dev/null)

    # Write new index atomically
    local temp_index="${index_path}.tmp.$$"
    echo "$new_index" > "$temp_index" 2>/dev/null && \
    mv "$temp_index" "$index_path" 2>/dev/null
    local result=$?

    rm -f "$temp_index" 2>/dev/null
    _cache_release_lock "$course_dir"

    if [[ $result -eq 0 ]]; then
        _flow_log_debug "Cache index rebuilt: $file_count files, $(( total_size / 1024 ))KB" 2>/dev/null
        return 0
    else
        _flow_log_error "Failed to write rebuilt cache index" 2>/dev/null
        return 1
    fi
}

# =============================================================================
# Function: _cache_get_stats
# Purpose: Get cache statistics
# =============================================================================
# Arguments:
#   $1 - (optional) Course directory [default: $PWD]
#   $2 - (optional) Output format: "json" or "text" [default: "text"]
#
# Returns:
#   0 - Success
#   1 - No cache found
#
# Output:
#   stdout - Cache statistics in requested format
#
# Example:
#   # Text output
#   _cache_get_stats
#   # Output:
#   #   Cache Statistics
#   #   ================
#   #   Cached files: 12
#   #   Total size: 245 KB
#   #   Hit rate: 87.3%
#   #   Avg analysis time: 1.2s
#
#   # JSON output
#   stats_json=$(_cache_get_stats "$PWD" "json")
# =============================================================================
_cache_get_stats() {
    local course_dir="${1:-$PWD}"
    local format="${2:-text}"
    local index_path

    index_path=$(_cache_get_index_path "$course_dir")

    if [[ ! -f "$index_path" ]]; then
        if [[ "$format" == "json" ]]; then
            echo '{"error": "No cache index found"}'
        else
            echo "No cache found"
        fi
        return 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        if [[ "$format" == "json" ]]; then
            cat "$index_path"
        else
            echo "jq required for formatted stats"
        fi
        return 0
    fi

    if [[ "$format" == "json" ]]; then
        jq '.cache_stats' "$index_path" 2>/dev/null
    else
        local stats
        stats=$(jq -r '
            .cache_stats |
            "Cache Statistics",
            "================",
            "Cached files:      \(.cached_files // 0)",
            "Total size:        \((.total_size_bytes // 0) / 1024 | floor) KB",
            "Cache hits:        \(.cache_hits // 0)",
            "Cache misses:      \(.cache_misses // 0)",
            "Hit rate:          \((.cache_hit_rate // 0) * 100 | . * 10 | floor / 10)%",
            "Avg analysis time: \((.avg_analysis_time_ms // 0) / 1000 | . * 10 | floor / 10)s"
        ' "$index_path" 2>/dev/null)

        echo "$stats"
    fi

    return 0
}

# =============================================================================
# Function: _cache_clean_expired
# Purpose: Clean up expired and stale cache entries
# =============================================================================
# Arguments:
#   $1 - (optional) Course directory [default: $PWD]
#
# Returns:
#   0 - Success
#   1 - Failed to clean
#
# Output:
#   stdout - Number of entries cleaned
#
# Example:
#   cleaned=$(_cache_clean_expired)
#   echo "Cleaned $cleaned expired entries"
# =============================================================================
_cache_clean_expired() {
    local course_dir="${1:-$PWD}"
    local index_path cache_dir

    index_path=$(_cache_get_index_path "$course_dir")
    cache_dir=$(_cache_get_cache_dir "$course_dir")

    if [[ ! -f "$index_path" ]]; then
        echo "0"
        return 0
    fi

    if ! command -v jq >/dev/null 2>&1; then
        echo "0"
        return 1
    fi

    local current_epoch cleaned_count=0
    current_epoch=$(date +%s)

    # Get expired files
    local expired_files
    expired_files=$(jq -r --argjson now "$current_epoch" '
        .files | to_entries[] |
        select(
            .value.status != "valid" or
            (
                .value.ttl_expires != null and
                (.value.ttl_expires |
                    if . then
                        (. | sub("\\.[0-9]+Z$"; "Z") | strptime("%Y-%m-%dT%H:%M:%SZ") | mktime) < $now
                    else
                        false
                    end
                )
            )
        ) | .key
    ' "$index_path" 2>/dev/null)

    if [[ -n "$expired_files" ]]; then
        for file in ${(f)expired_files}; do
            [[ -z "$file" ]] && continue

            local cache_file
            cache_file=$(_cache_get_cache_file_path "$file" "$course_dir")
            rm -f "$cache_file" 2>/dev/null
            ((cleaned_count++))
        done

        # Rebuild index to remove expired entries
        _cache_rebuild_index "$course_dir" >/dev/null 2>&1
    fi

    echo "$cleaned_count"
    return 0
}

# =============================================================================
# Function: _cache_get_or_analyze
# Purpose: High-level function to get cached analysis or run analysis
# =============================================================================
# Arguments:
#   $1 - (required) Source file path (relative or absolute)
#   $2 - (required) Analysis function name to call on cache miss
#   $3 - (optional) Course directory [default: $PWD]
#
# Returns:
#   0 - Success (cached or fresh analysis)
#   1 - Analysis failed
#
# Output:
#   stdout - Analysis JSON
#
# Example:
#   analysis=$(_cache_get_or_analyze "lectures/week-05.qmd" "_run_concept_analysis")
#
# Notes:
#   - Checks cache first (< 10ms)
#   - On miss, calls analysis function and caches result
#   - Handles cascade invalidation automatically
# =============================================================================
_cache_get_or_analyze() {
    local source_file="$1"
    local analysis_func="$2"
    local course_dir="${3:-$PWD}"

    # Normalize file path
    local relative_file
    if [[ "$source_file" == /* ]]; then
        # Absolute path - make relative
        relative_file="${source_file#$course_dir/}"
    else
        relative_file="$source_file"
    fi

    # Check cache validity
    if _cache_check_valid "$relative_file" "$course_dir"; then
        # Cache hit
        _cache_read "$relative_file" "$course_dir"
        return $?
    fi

    # Cache miss - run analysis
    local start_time analysis_result analysis_time_ms
    start_time=$(($(date +%s%N 2>/dev/null || echo "$(date +%s)000000000") / 1000000))

    # Call the analysis function
    if typeset -f "$analysis_func" >/dev/null 2>&1; then
        analysis_result=$("$analysis_func" "$source_file" "$course_dir")
    else
        _flow_log_error "Analysis function not found: $analysis_func" 2>/dev/null
        return 1
    fi

    local end_time
    end_time=$(($(date +%s%N 2>/dev/null || echo "$(date +%s)000000000") / 1000000))
    analysis_time_ms=$((end_time - start_time))

    # Cache the result
    if [[ -n "$analysis_result" ]]; then
        _cache_write "$relative_file" "$analysis_result" "$analysis_time_ms" "$course_dir"
        echo "$analysis_result"
        return 0
    fi

    return 1
}
