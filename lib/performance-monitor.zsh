# lib/performance-monitor.zsh - Performance tracking and visualization
# Provides: Performance log management, metrics collection, trend analysis
# Used by: teach validate, teach status --performance
# Phase 2 Wave 5: Performance Monitoring System

# Source core utilities if not already loaded
if [[ -z "$_FLOW_CORE_LOADED" ]]; then
    local core_path="${0:A:h}/core.zsh"
    [[ -f "$core_path" ]] && source "$core_path"
    typeset -g _FLOW_CORE_LOADED=1
fi

typeset -g _FLOW_PERFORMANCE_MONITOR_LOADED=1

# ============================================================================
# CONSTANTS
# ============================================================================

typeset -g PERF_LOG_FILE=".teach/performance-log.json"
typeset -g PERF_LOG_VERSION="1.0"
typeset -g PERF_LOG_MAX_SIZE=$((10 * 1024 * 1024))  # 10MB
typeset -g PERF_LOG_MAX_ENTRIES=1000

# ============================================================================
# LOG INITIALIZATION
# ============================================================================

# =============================================================================
# Function: _init_performance_log
# Purpose: Initialize the performance log file with proper schema
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Success (log file exists or was created)
#   1 - Error (failed to create directory or file)
#
# Output:
#   None (creates file on disk)
#
# Example:
#   _init_performance_log
#   # Creates .teach/performance-log.json if not exists
#
# Notes:
#   - Creates .teach directory if it doesn't exist
#   - Creates log file with version and empty entries array
#   - Uses PERF_LOG_FILE constant for file path
#   - Uses PERF_LOG_VERSION constant for schema version
#   - Idempotent: safe to call multiple times
# =============================================================================
_init_performance_log() {
    local log_file="$PERF_LOG_FILE"

    # Create .teach directory if needed
    if [[ ! -d ".teach" ]]; then
        mkdir -p ".teach" || return 1
    fi

    # Create log file if it doesn't exist
    if [[ ! -f "$log_file" ]]; then
        cat > "$log_file" <<EOF
{
  "version": "$PERF_LOG_VERSION",
  "entries": []
}
EOF
        return $?
    fi

    return 0
}

# ============================================================================
# LOG ROTATION
# ============================================================================

# =============================================================================
# Function: _rotate_performance_log
# Purpose: Rotate the performance log when it exceeds size limits
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Success (no rotation needed or rotation completed)
#
# Output:
#   stdout - Info message via _flow_log_info when rotating
#
# Example:
#   _rotate_performance_log
#   # Archives old log and keeps last PERF_LOG_MAX_ENTRIES entries
#
# Notes:
#   - Checks file size against PERF_LOG_MAX_SIZE (10MB default)
#   - Archives old log to .teach/performance-log-TIMESTAMP.json
#   - If jq available, extracts last N entries to new log
#   - Without jq, creates fresh empty log
#   - Uses PERF_LOG_MAX_ENTRIES constant (1000 default)
#   - Cross-platform stat command for file size (BSD/GNU)
# =============================================================================
_rotate_performance_log() {
    local log_file="$PERF_LOG_FILE"

    [[ ! -f "$log_file" ]] && return 0

    # Check file size
    local size=$(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file" 2>/dev/null || echo 0)
    if [[ "$size" -lt "$PERF_LOG_MAX_SIZE" ]]; then
        return 0
    fi

    # Archive old log
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local archive_file=".teach/performance-log-${timestamp}.json"

    _flow_log_info "Rotating performance log (size: ${size} bytes)"
    mv "$log_file" "$archive_file"

    # If jq available, keep last N entries in new log
    if command -v jq &>/dev/null; then
        jq --arg version "$PERF_LOG_VERSION" \
           --argjson max "$PERF_LOG_MAX_ENTRIES" \
           '{version: $version, entries: .entries | .[-($max | tonumber):]}' \
           "$archive_file" > "$log_file"
    else
        # Without jq, just create empty log
        _init_performance_log
    fi

    return 0
}

# ============================================================================
# PERFORMANCE RECORDING
# ============================================================================

# =============================================================================
# Function: _record_performance
# Purpose: Record a performance entry with metrics to the log file
# =============================================================================
# Arguments:
#   $1 - (required) Operation type: "validate", "render", or "deploy"
#   $2 - (required) Number of files processed
#   $3 - (required) Duration in seconds (can be float, e.g., "12.5")
#   $4 - (required) Parallel mode: "true" or "false"
#   $5 - (optional) Worker count [default: 0]
#   $6 - (optional) Cache hits count [default: 0]
#   $7 - (optional) Cache misses count [default: 0]
#   $8 - (optional) Per-file stats as JSON array [default: []]
#
# Returns:
#   0 - Success (entry recorded)
#   1 - Error (failed to initialize log)
#
# Output:
#   None (writes to PERF_LOG_FILE)
#
# Example:
#   _record_performance "validate" 15 "45.2" "true" 4 10 5 '[{"file":"hw1.qmd","duration_sec":3.2}]'
#
# Notes:
#   - Automatically calculates derived metrics:
#     - cache_hit_rate (0.0-1.0)
#     - avg_render_time_sec (duration / files)
#     - speedup (parallel efficiency estimate)
#     - slowest_file and slowest_time_sec (from per_file_json)
#   - Uses jq for proper JSON construction if available
#   - Falls back to manual JSON construction without jq
#   - Initializes and rotates log as needed
#   - Timestamps are UTC ISO-8601 format
# =============================================================================
_record_performance() {
    local operation="$1"      # validate, render, deploy
    local files="$2"          # file count
    local duration="$3"       # seconds (can be float)
    local parallel="$4"       # true/false
    local workers="${5:-0}"   # worker count (0 if not parallel)
    local cache_hits="${6:-0}"
    local cache_misses="${7:-0}"
    local per_file_json="${8:-[]}"  # JSON array of per-file stats

    # Initialize log if needed
    _init_performance_log || return 1

    # Rotate if needed
    _rotate_performance_log

    local log_file="$PERF_LOG_FILE"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Calculate derived metrics
    local cache_hit_rate=0
    local total_cache=$(( cache_hits + cache_misses ))
    if [[ "$total_cache" -gt 0 ]]; then
        cache_hit_rate=$(printf "%.2f" $(echo "scale=4; $cache_hits / $total_cache" | bc))
    fi

    local avg_render_time=0
    if [[ "$files" -gt 0 ]]; then
        avg_render_time=$(printf "%.2f" $(echo "scale=4; $duration / $files" | bc))
    fi

    # Calculate speedup if parallel
    local speedup=1.0
    if [[ "$parallel" == "true" ]] && [[ "$workers" -gt 0 ]]; then
        # Estimate serial time (this is simplified - real calculation would need baseline)
        # For now, assume ideal speedup and calculate from actual
        speedup=$(printf "%.2f" $(echo "scale=4; $files / ($duration / $avg_render_time)" | bc 2>/dev/null || echo "1.0"))
    fi

    # Find slowest file from per_file_json
    local slowest_file=""
    local slowest_time=0
    if [[ "$per_file_json" != "[]" ]] && command -v jq &>/dev/null; then
        slowest_file=$(echo "$per_file_json" | jq -r 'max_by(.duration_sec) | .file')
        slowest_time=$(echo "$per_file_json" | jq -r 'max_by(.duration_sec) | .duration_sec')
    fi

    # Build entry JSON
    local entry
    if command -v jq &>/dev/null; then
        # With jq - proper JSON construction
        entry=$(jq -n \
            --arg timestamp "$timestamp" \
            --arg operation "$operation" \
            --argjson files "$files" \
            --arg duration "$duration" \
            --arg parallel "$parallel" \
            --argjson workers "$workers" \
            --arg speedup "$speedup" \
            --argjson cache_hits "$cache_hits" \
            --argjson cache_misses "$cache_misses" \
            --arg cache_hit_rate "$cache_hit_rate" \
            --arg avg_render_time_sec "$avg_render_time" \
            --arg slowest_file "$slowest_file" \
            --arg slowest_time_sec "$slowest_time" \
            --argjson per_file "$per_file_json" \
            '{
                timestamp: $timestamp,
                operation: $operation,
                files: $files,
                duration_sec: ($duration | tonumber),
                parallel: ($parallel == "true"),
                workers: $workers,
                speedup: ($speedup | tonumber),
                cache_hits: $cache_hits,
                cache_misses: $cache_misses,
                cache_hit_rate: ($cache_hit_rate | tonumber),
                avg_render_time_sec: ($avg_render_time_sec | tonumber),
                slowest_file: $slowest_file,
                slowest_time_sec: ($slowest_time_sec | tonumber),
                per_file: $per_file
            }')

        # Append to log
        jq --argjson entry "$entry" '.entries += [$entry]' "$log_file" > "${log_file}.tmp" && \
            mv "${log_file}.tmp" "$log_file"
    else
        # Without jq - manual JSON construction (fragile but functional)
        # Remove closing braces, add entry, re-close
        local entry_json="    {
      \"timestamp\": \"$timestamp\",
      \"operation\": \"$operation\",
      \"files\": $files,
      \"duration_sec\": $duration,
      \"parallel\": $([ "$parallel" = "true" ] && echo "true" || echo "false"),
      \"workers\": $workers,
      \"speedup\": $speedup,
      \"cache_hits\": $cache_hits,
      \"cache_misses\": $cache_misses,
      \"cache_hit_rate\": $cache_hit_rate,
      \"avg_render_time_sec\": $avg_render_time,
      \"slowest_file\": \"$slowest_file\",
      \"slowest_time_sec\": $slowest_time,
      \"per_file\": $per_file_json
    }"

        # Read current entries
        local entries=$(sed -n '/"entries":/,/\]/p' "$log_file" | sed '1d;$d')

        # Build new log
        cat > "${log_file}.tmp" <<EOF
{
  "version": "$PERF_LOG_VERSION",
  "entries": [
${entries:+$entries,}
$entry_json
  ]
}
EOF
        mv "${log_file}.tmp" "$log_file"
    fi

    return 0
}

# ============================================================================
# LOG READING
# ============================================================================

# =============================================================================
# Function: _read_performance_log
# Purpose: Read performance log entries within a time window
# =============================================================================
# Arguments:
#   $1 - (optional) Number of days to look back [default: 0 = all entries]
#
# Returns:
#   0 - Success (entries returned)
#   1 - Error (log file not found)
#
# Output:
#   stdout - JSON array of matching log entries
#
# Example:
#   entries=$(_read_performance_log 7)   # Last 7 days
#   entries=$(_read_performance_log 30)  # Last 30 days
#   entries=$(_read_performance_log)     # All entries
#
# Notes:
#   - Returns "[]" if log file doesn't exist
#   - Uses jq for filtering by timestamp if available
#   - Cross-platform date calculation (BSD/GNU)
#   - Without jq, returns raw entries section from JSON
#   - Cutoff date is calculated in UTC
# =============================================================================
_read_performance_log() {
    local window_days="${1:-0}"  # 0 = all entries
    local log_file="$PERF_LOG_FILE"

    [[ ! -f "$log_file" ]] && echo "[]" && return 1

    # Calculate cutoff date
    local cutoff=""
    if [[ "$window_days" -gt 0 ]]; then
        cutoff=$(date -u -v-${window_days}d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || \
                 date -u -d "${window_days} days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
    fi

    if command -v jq &>/dev/null; then
        if [[ -n "$cutoff" ]]; then
            jq --arg cutoff "$cutoff" \
               '.entries | map(select(.timestamp >= $cutoff))' \
               "$log_file" 2>/dev/null || { echo "[]"; return 1; }
        else
            jq '.entries' "$log_file" 2>/dev/null || { echo "[]"; return 1; }
        fi
    else
        # Without jq - return all entries (parsing is complex)
        sed -n '/"entries":/,/\]/p' "$log_file"
    fi

    return 0
}

# ============================================================================
# METRIC CALCULATION
# ============================================================================

# =============================================================================
# Function: _calculate_moving_average
# Purpose: Calculate the moving average of a metric over a time window
# =============================================================================
# Arguments:
#   $1 - (required) Metric name: "avg_render_time_sec", "cache_hit_rate",
#                   "speedup", "duration_sec", etc.
#   $2 - (optional) Number of days for the window [default: 7]
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Average value as float (e.g., "3.45")
#            Returns "0" if no entries or jq unavailable
#
# Example:
#   avg=$(_calculate_moving_average "avg_render_time_sec" 7)
#   avg=$(_calculate_moving_average "cache_hit_rate" 30)
#
# Notes:
#   - Requires jq for calculation
#   - Returns "0" without jq
#   - Uses _read_performance_log() internally for filtering
#   - Handles empty arrays gracefully
# =============================================================================
_calculate_moving_average() {
    local metric="$1"       # avg_render_time_sec, cache_hit_rate, speedup, duration_sec
    local window_days="${2:-7}"

    local entries=$(_read_performance_log "$window_days")

    if command -v jq &>/dev/null; then
        echo "$entries" | jq -r --arg metric "$metric" \
            '[.[] | .[$metric]] | add / length' 2>/dev/null || echo "0"
    else
        # Without jq - return 0
        echo "0"
    fi
}

# =============================================================================
# Function: _get_latest_metric
# Purpose: Get the most recent value for a specific metric
# =============================================================================
# Arguments:
#   $1 - (required) Metric name: "avg_render_time_sec", "cache_hit_rate",
#                   "files", "parallel", "workers", "speedup", etc.
#
# Returns:
#   0 - Success
#   1 - Error (log file not found)
#
# Output:
#   stdout - Latest value for the metric (number or string)
#            Returns "0" if log empty or jq unavailable
#
# Example:
#   latest=$(_get_latest_metric "avg_render_time_sec")  # e.g., "2.45"
#   latest=$(_get_latest_metric "parallel")             # e.g., "true"
#
# Notes:
#   - Returns value from the most recent entry in the log
#   - Requires jq for extraction
#   - Returns "0" without jq or if metric not found
#   - Uses the "last" entry from the entries array
# =============================================================================
_get_latest_metric() {
    local metric="$1"
    local log_file="$PERF_LOG_FILE"

    [[ ! -f "$log_file" ]] && echo "0" && return 1

    if command -v jq &>/dev/null; then
        jq -r --arg metric "$metric" \
           '.entries | last | .[$metric] // 0' \
           "$log_file"
    else
        echo "0"
    fi
}

# ============================================================================
# ANALYSIS
# ============================================================================

# =============================================================================
# Function: _identify_slow_files
# Purpose: Identify the slowest files based on maximum render time
# =============================================================================
# Arguments:
#   $1 - (optional) Number of files to return [default: 5]
#   $2 - (optional) Number of days to look back [default: 7]
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Tab-separated values: "filename\tmax_duration"
#            One file per line, sorted by duration descending
#            Empty output if no data or jq unavailable
#
# Example:
#   _identify_slow_files 5 7
#   # Output:
#   # lectures/week10.qmd	15.2
#   # assignments/final.qmd	12.8
#   # exams/midterm.qmd	10.5
#
# Notes:
#   - Aggregates across all entries in the time window
#   - Uses maximum duration for each file (worst case)
#   - Groups by file path before sorting
#   - Requires jq for JSON processing
#   - Uses per_file arrays from log entries
# =============================================================================
_identify_slow_files() {
    local count="${1:-5}"
    local window_days="${2:-7}"

    local entries=$(_read_performance_log "$window_days")

    if command -v jq &>/dev/null; then
        echo "$entries" | jq -r \
            '[.[] | .per_file[]? | {file: .file, duration: .duration_sec}] |
             group_by(.file) |
             map({file: .[0].file, max_duration: (map(.duration) | max)}) |
             sort_by(.max_duration) | reverse |
             limit('$count'; .[]) |
             "\(.file)\t\(.max_duration)"'
    else
        echo ""
    fi
}

# =============================================================================
# Function: _calculate_trend
# Purpose: Calculate trend direction and percentage change from average
# =============================================================================
# Arguments:
#   $1 - (required) Current value (float)
#   $2 - (required) Average/baseline value (float)
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Trend indicator with percentage:
#            "↑ X%" - Value increased from average
#            "↓ X%" - Value decreased from average
#            "→ 0%" - No significant change
#
# Example:
#   _calculate_trend "3.5" "3.0"   # Output: ↑ 16.7%
#   _calculate_trend "2.5" "3.0"   # Output: ↓ 16.7%
#   _calculate_trend "3.0" "3.0"   # Output: → 0%
#
# Notes:
#   - Requires bc for floating point math
#   - Returns "→ 0%" if bc unavailable
#   - Uses 0.01 threshold for "no change" detection
#   - Percentage is absolute (no negative sign)
#   - Division by zero is handled by bc returning error
# =============================================================================
_calculate_trend() {
    local current="$1"
    local average="$2"

    if ! command -v bc &>/dev/null; then
        echo "→ 0%"
        return
    fi

    local diff=$(echo "scale=4; $current - $average" | bc)
    local pct=$(echo "scale=1; ($diff / $average) * 100" | bc 2>/dev/null || echo "0")

    # Determine direction
    if (( $(echo "$diff > 0.01" | bc -l) )); then
        echo "↑ ${pct#-}%"
    elif (( $(echo "$diff < -0.01" | bc -l) )); then
        echo "↓ ${pct#-}%"
    else
        echo "→ 0%"
    fi
}

# ============================================================================
# VISUALIZATION
# ============================================================================

# =============================================================================
# Function: _generate_ascii_graph
# Purpose: Generate an ASCII bar graph representing a value
# =============================================================================
# Arguments:
#   $1 - (required) Current value (float or integer)
#   $2 - (required) Maximum value for scale
#   $3 - (optional) Width in characters [default: 50]
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - ASCII bar using filled (█) and empty (░) characters
#
# Example:
#   _generate_ascii_graph 75 100 10
#   # Output: ████████░░ (7.5 rounded to 8 filled, 2 empty)
#
#   _generate_ascii_graph 50 100 20
#   # Output: ██████████░░░░░░░░░░
#
# Notes:
#   - Requires bc for floating point math
#   - Falls back to full bar if bc unavailable
#   - Clamps value to max (no overflow)
#   - Handles max=0 by treating as max=1
#   - Uses Unicode block characters for visual clarity
# =============================================================================
_generate_ascii_graph() {
    local value="$1"
    local max="$2"
    local width="${3:-50}"

    # Handle edge cases
    if ! command -v bc &>/dev/null; then
        printf '%s' "$(printf '█%.0s' {1..$width})"
        return
    fi

    [[ $(echo "$max == 0" | bc) -eq 1 ]] && max=1
    [[ $(echo "$value > $max" | bc) -eq 1 ]] && value="$max"

    # Calculate filled portion (round to nearest integer)
    local filled=$(printf "%.0f" $(echo "scale=2; ($value / $max) * $width" | bc))
    local empty=$(( width - filled ))

    # Clamp values
    [[ $filled -lt 0 ]] && filled=0
    [[ $filled -gt $width ]] && filled=$width
    [[ $empty -lt 0 ]] && empty=0

    # Generate bar
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done

    echo "$bar"
}

# ============================================================================
# PERFORMANCE DASHBOARD
# ============================================================================

# =============================================================================
# Function: _format_performance_dashboard
# Purpose: Display a formatted performance metrics dashboard
# =============================================================================
# Arguments:
#   $1 - (optional) Number of days for trend window [default: 7]
#
# Returns:
#   0 - Success (dashboard displayed)
#   1 - Error (no performance data available)
#
# Output:
#   stdout - Formatted dashboard with sections:
#            - Render Time (avg per file with trend)
#            - Total Validation Time (if parallel mode)
#            - Cache Hit Rate (with visual bar)
#            - Parallel Efficiency (workers, speedup)
#            - Top 5 Slowest Files
#
# Example:
#   _format_performance_dashboard 7     # Last 7 days trends
#   _format_performance_dashboard 30    # Last 30 days trends
#
# Notes:
#   - Uses FLOW_COLORS for styled output (bold, header, reset)
#   - Displays warning if no performance data exists
#   - Suggests running 'teach validate' to collect data
#   - Includes ASCII bar graphs for visual metrics
#   - Calculates serial time estimate for parallel runs
#   - Efficiency percentage assumes I/O bound workload
#   - Requires jq for full functionality
# =============================================================================
_format_performance_dashboard() {
    local window_days="${1:-7}"
    local log_file="$PERF_LOG_FILE"

    # Check if log exists
    if [[ ! -f "$log_file" ]]; then
        _flow_log_warning "No performance data available"
        echo "Run 'teach validate' to start collecting performance metrics"
        return 1
    fi

    # Check if log has any entries
    local entry_count=0
    if command -v jq &>/dev/null; then
        entry_count=$(jq -r '.entries | length' "$log_file" 2>/dev/null || echo "0")
    fi

    if [[ "$entry_count" -eq 0 ]]; then
        _flow_log_warning "No performance data available"
        echo "Run 'teach validate' to start collecting performance metrics"
        return 1
    fi

    # Get latest metrics
    local latest_avg_time=$(_get_latest_metric "avg_render_time_sec")
    local latest_duration=$(_get_latest_metric "duration_sec")
    local latest_files=$(_get_latest_metric "files")
    local latest_parallel=$(_get_latest_metric "parallel")
    local latest_workers=$(_get_latest_metric "workers")
    local latest_speedup=$(_get_latest_metric "speedup")
    local latest_cache_rate=$(_get_latest_metric "cache_hit_rate")

    # Calculate averages
    local avg_render_time=$(_calculate_moving_average "avg_render_time_sec" "$window_days")
    local avg_cache_rate=$(_calculate_moving_average "cache_hit_rate" "$window_days")
    local avg_speedup=$(_calculate_moving_average "speedup" "$window_days")

    # Calculate trends
    local render_trend=$(_calculate_trend "$latest_avg_time" "$avg_render_time")
    local cache_trend=$(_calculate_trend "$latest_cache_rate" "$avg_cache_rate")

    # Get slowest files
    local slow_files=$(_identify_slow_files 5 "$window_days")

    # Display dashboard
    echo ""
    echo "${FLOW_COLORS[bold]}Performance Trends (Last ${window_days} Days)${FLOW_COLORS[reset]}"
    echo "─────────────────────────────────────────────────────"
    echo ""

    # Render Time
    echo "${FLOW_COLORS[header]}Render Time (avg per file):${FLOW_COLORS[reset]}"
    local render_graph=$(_generate_ascii_graph "$latest_avg_time" "$(echo "$avg_render_time * 1.5" | bc 2>/dev/null || echo 10)" 10)
    echo "  Today:     ${latest_avg_time}s  $render_graph (vs ${avg_render_time}s week avg)"
    echo "  Trend:     $render_trend"
    echo ""

    # Total Validation Time
    if [[ "$latest_parallel" == "true" ]]; then
        echo "${FLOW_COLORS[header]}Total Validation Time:${FLOW_COLORS[reset]}"
        local serial_est=$(echo "$latest_avg_time * $latest_files" | bc 2>/dev/null || echo "0")
        echo "  Today:     ${latest_duration}s   (${latest_files} files, parallel)"
        echo "  Serial:    ${serial_est}s  (estimated)"
        echo "  Speedup:   ${latest_speedup}x"
        echo ""
    fi

    # Cache Hit Rate
    if [[ $(echo "$latest_cache_rate > 0" | bc 2>/dev/null || echo 0) -eq 1 ]]; then
        echo "${FLOW_COLORS[header]}Cache Hit Rate:${FLOW_COLORS[reset]}"
        local cache_pct=$(echo "$latest_cache_rate * 100" | bc 2>/dev/null || echo "0")
        local cache_graph=$(_generate_ascii_graph "$cache_pct" 100 10)
        echo "  Today:     ${cache_pct}%   $cache_graph"
        local avg_cache_pct=$(echo "$avg_cache_rate * 100" | bc 2>/dev/null || echo "0")
        echo "  Week avg:  ${avg_cache_pct}%"
        echo "  Trend:     $cache_trend"
        echo ""
    fi

    # Parallel Efficiency
    if [[ "$latest_parallel" == "true" ]] && [[ "$latest_workers" -gt 0 ]]; then
        echo "${FLOW_COLORS[header]}Parallel Efficiency:${FLOW_COLORS[reset]}"
        echo "  Workers:   ${latest_workers}"
        echo "  Speedup:   ${latest_speedup}x"
        local efficiency=$(echo "scale=0; ($latest_speedup / $latest_workers) * 100" | bc 2>/dev/null || echo "0")
        echo "  Efficiency: ${efficiency}%  (good for I/O bound)"
        echo ""
    fi

    # Slowest Files
    if [[ -n "$slow_files" ]]; then
        echo "${FLOW_COLORS[header]}Top 5 Slowest Files:${FLOW_COLORS[reset]}"
        local idx=1
        while IFS=$'\t' read -r file time; do
            echo "  ${idx}. ${file}    ${time}s"
            ((idx++))
        done <<< "$slow_files"
        echo ""
    fi

    return 0
}

# ============================================================================
# EXPORTS
# ============================================================================

# Mark module as loaded
typeset -g _FLOW_PERFORMANCE_MONITOR_LOADED=1
