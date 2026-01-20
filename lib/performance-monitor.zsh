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

# Initialize performance log file if it doesn't exist
# Creates .teach directory and empty log with schema
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

# Rotate log if it exceeds max size or max entries
# Keeps last N entries, archives older ones
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

# Record a performance entry to the log
# Args: operation files duration parallel workers cache_hits cache_misses per_file_json
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

# Read performance log entries within a time window
# Args: window_days (7, 30, or empty for all)
# Returns: JSON array of entries (via stdout)
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

# Calculate moving average for a metric
# Args: metric window_days
# Returns: average value (float)
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

# Get most recent entry for a metric
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

# Identify slowest files across recent operations
# Args: count window_days
# Returns: TSV of file and time
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

# Calculate trend direction and percentage change
# Args: current_value average_value
# Returns: "↑ X%" or "↓ X%" or "→ 0%"
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

# Generate ASCII bar graph
# Args: value max width
# Returns: bar string (e.g., "████████░░")
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

# Format and display performance dashboard
# Args: window_days (7, 30)
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
