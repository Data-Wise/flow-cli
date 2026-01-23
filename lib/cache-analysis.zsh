# lib/cache-analysis.zsh - Advanced cache analysis and recommendations
# Provides: Cache breakdown, hit rate analysis, optimization recommendations

# ============================================================================
# CACHE SIZE ANALYSIS
# ============================================================================

# =============================================================================
# Function: _analyze_cache_size
# Purpose: Analyze total cache size and file count for a directory
# =============================================================================
# Arguments:
#   $1 - (optional) Cache directory path [default: "_freeze/site"]
#
# Returns:
#   0 - Analysis successful
#   1 - Cache directory doesn't exist
#
# Output:
#   stdout - Colon-separated string: "size_bytes:file_count:size_human"
#
# Example:
#   info=$(_analyze_cache_size "_freeze/site")
#   size_bytes=$(echo "$info" | cut -d: -f1)
#   file_count=$(echo "$info" | cut -d: -f2)
#   size_human=$(echo "$info" | cut -d: -f3)
#
# Notes:
#   - Returns "0:0:0B" if cache doesn't exist
#   - Uses du -sk for portable size calculation
#   - Requires _cache_format_bytes helper
# =============================================================================
_analyze_cache_size() {
    local cache_dir="${1:-_freeze/site}"

    # Check if cache exists
    if [[ ! -d "$cache_dir" ]]; then
        echo "0:0:0B"
        return 1
    fi

    # Count files
    local file_count=$(find "$cache_dir" -type f 2>/dev/null | wc -l | tr -d ' ')

    # Get size in bytes (portable: use du -sk for KB, then convert)
    local size_kb=0
    if command -v du &>/dev/null; then
        size_kb=$(du -sk "$cache_dir" 2>/dev/null | awk '{print $1}')
    fi

    local size_bytes=$((size_kb * 1024))
    local size_human=$(_cache_format_bytes "$size_bytes")

    echo "$size_bytes:$file_count:$size_human"
}

# =============================================================================
# Function: _analyze_cache_by_directory
# Purpose: Break down cache size by subdirectory (lectures/, assignments/, etc.)
# =============================================================================
# Arguments:
#   $1 - (optional) Cache directory path [default: "_freeze/site"]
#
# Returns:
#   0 - Analysis successful (or no subdirs)
#   1 - Cache directory doesn't exist
#
# Output:
#   stdout - Multi-line, colon-separated:
#            "dir_name:size_bytes:size_human:file_count:percentage"
#
# Example:
#   _analyze_cache_by_directory "_freeze/site" | while IFS=: read -r name bytes human count pct; do
#       echo "$name: $human ($pct%)"
#   done
#
# Notes:
#   - Only analyzes first-level subdirectories
#   - Percentage is relative to total cache size
# =============================================================================
_analyze_cache_by_directory() {
    local cache_dir="${1:-_freeze/site}"

    # Check if cache exists
    if [[ ! -d "$cache_dir" ]]; then
        return 1
    fi

    # Get total size for percentage calculation
    local total_info=$(_analyze_cache_size "$cache_dir")
    local total_bytes=$(echo "$total_info" | cut -d: -f1)
    local total_files=$(echo "$total_info" | cut -d: -f2)

    # Find subdirectories (lectures/, assignments/, etc.)
    local subdirs=$(find "$cache_dir" -type d -mindepth 1 -maxdepth 1 2>/dev/null | sort)

    # Return empty if no subdirs
    if [[ -z "$subdirs" ]]; then
        return 0
    fi

    # Analyze each subdirectory
    while IFS= read -r subdir; do
        local dir_name=$(basename "$subdir")

        # Get size in KB
        local dir_size_kb=$(du -sk "$subdir" 2>/dev/null | awk '{print $1}')
        local dir_size_bytes=$((dir_size_kb * 1024))
        local dir_size_human=$(_cache_format_bytes "$dir_size_bytes")

        # Count files
        local dir_files=$(find "$subdir" -type f 2>/dev/null | wc -l | tr -d ' ')

        # Calculate percentage
        local percentage=0
        if [[ $total_bytes -gt 0 ]]; then
            percentage=$(( (dir_size_bytes * 100) / total_bytes ))
        fi

        # Output: dir_name:size_bytes:size_human:file_count:percentage
        echo "$dir_name:$dir_size_bytes:$dir_size_human:$dir_files:$percentage"
    done <<< "$subdirs"
}

# =============================================================================
# Function: _analyze_cache_by_age
# Purpose: Break down cache by file age (< 7 days, 7-30 days, > 30 days)
# =============================================================================
# Arguments:
#   $1 - (optional) Cache directory path [default: "_freeze/site"]
#
# Returns:
#   0 - Analysis successful
#   1 - Cache directory doesn't exist
#
# Output:
#   stdout - Multi-line, colon-separated:
#            "label:size_bytes:size_human:count:percentage"
#
# Example:
#   _analyze_cache_by_age "_freeze/site"
#   # Output:
#   # < 7 days:1234567:1.2MB:45:60
#   # 7-30 days:567890:554KB:20:30
#   # > 30 days:123456:121KB:10:10
#
# Notes:
#   - Uses file modification time (mtime)
#   - macOS stat command compatible
# =============================================================================
_analyze_cache_by_age() {
    local cache_dir="${1:-_freeze/site}"

    # Check if cache exists
    if [[ ! -d "$cache_dir" ]]; then
        return 1
    fi

    local now=$(date +%s)
    local seven_days_ago=$((now - 604800))   # 7 days
    local thirty_days_ago=$((now - 2592000)) # 30 days

    # Initialize counters
    local count_0_7=0
    local size_0_7=0
    local count_7_30=0
    local size_7_30=0
    local count_30_plus=0
    local size_30_plus=0

    # Iterate through all files
    while IFS= read -r file; do
        # Get modification time
        local mtime=$(stat -f %m "$file" 2>/dev/null || echo 0)

        # Get file size (in bytes, using stat)
        local file_size=$(stat -f %z "$file" 2>/dev/null || echo 0)

        # Categorize by age
        if [[ $mtime -ge $seven_days_ago ]]; then
            ((count_0_7++))
            size_0_7=$((size_0_7 + file_size))
        elif [[ $mtime -ge $thirty_days_ago ]]; then
            ((count_7_30++))
            size_7_30=$((size_7_30 + file_size))
        else
            ((count_30_plus++))
            size_30_plus=$((size_30_plus + file_size))
        fi
    done < <(find "$cache_dir" -type f 2>/dev/null)

    # Format sizes
    local size_0_7_human=$(_cache_format_bytes "$size_0_7")
    local size_7_30_human=$(_cache_format_bytes "$size_7_30")
    local size_30_plus_human=$(_cache_format_bytes "$size_30_plus")

    # Calculate total
    local total_bytes=$((size_0_7 + size_7_30 + size_30_plus))

    # Calculate percentages
    local pct_0_7=0
    local pct_7_30=0
    local pct_30_plus=0
    if [[ $total_bytes -gt 0 ]]; then
        pct_0_7=$(( (size_0_7 * 100) / total_bytes ))
        pct_7_30=$(( (size_7_30 * 100) / total_bytes ))
        pct_30_plus=$(( (size_30_plus * 100) / total_bytes ))
    fi

    # Output: label:size_bytes:size_human:count:percentage
    echo "< 7 days:$size_0_7:$size_0_7_human:$count_0_7:$pct_0_7"
    echo "7-30 days:$size_7_30:$size_7_30_human:$count_7_30:$pct_7_30"
    echo "> 30 days:$size_30_plus:$size_30_plus_human:$count_30_plus:$pct_30_plus"
}

# ============================================================================
# CACHE PERFORMANCE ANALYSIS
# ============================================================================

# =============================================================================
# Function: _calculate_cache_hit_rate
# Purpose: Calculate cache hit rate from performance log data
# =============================================================================
# Arguments:
#   $1 - (optional) Performance log path [default: ".teach/performance-log.json"]
#   $2 - (optional) Number of days to analyze [default: 7]
#
# Returns:
#   0 - Calculation successful
#   1 - Log doesn't exist or jq not available
#
# Output:
#   stdout - Colon-separated: "hit_rate:hits:misses:avg_hit_time:avg_miss_time"
#
# Example:
#   data=$(_calculate_cache_hit_rate ".teach/performance-log.json" 30)
#   hit_rate=$(echo "$data" | cut -d: -f1)
#   echo "Cache hit rate: $hit_rate%"
#
# Dependencies:
#   - jq (for JSON parsing)
#
# Notes:
#   - Returns "N/A:0:0:0:0" if no data available
#   - Times are in seconds
# =============================================================================
_calculate_cache_hit_rate() {
    local perf_log="${1:-.teach/performance-log.json}"
    local days="${2:-7}"  # Default: last 7 days

    # Check if performance log exists
    if [[ ! -f "$perf_log" ]]; then
        echo "N/A:0:0:0:0"
        return 1
    fi

    # Check if jq is available
    if ! command -v jq &>/dev/null; then
        echo "N/A:0:0:0:0"
        return 1
    fi

    # Calculate cutoff timestamp (N days ago)
    local cutoff_timestamp=$(date -v-${days}d +%s 2>/dev/null || date -d "${days} days ago" +%s 2>/dev/null || echo 0)

    # Extract data from performance log (last N days)
    local stats=$(jq -r --arg cutoff "$cutoff_timestamp" '
        .entries[]
        | select(.timestamp >= ($cutoff | tonumber))
        | "\(.cache_hits // 0):\(.cache_misses // 0):\(.avg_hit_time_sec // 0):\(.avg_miss_time_sec // 0)"
    ' "$perf_log" 2>/dev/null)

    if [[ -z "$stats" ]]; then
        echo "N/A:0:0:0:0"
        return 1
    fi

    # Aggregate stats
    local total_hits=0
    local total_misses=0
    local sum_hit_time=0
    local sum_miss_time=0
    local hit_count=0
    local miss_count=0

    while IFS=: read -r hits misses hit_time miss_time; do
        total_hits=$((total_hits + hits))
        total_misses=$((total_misses + misses))

        # Accumulate times (only if non-zero)
        # Convert float to integer by multiplying by 10 (0.3 → 3)
        local hit_time_int=$(echo "$hit_time" | awk '{printf "%.0f", $1 * 10}')
        local miss_time_int=$(echo "$miss_time" | awk '{printf "%.0f", $1 * 10}')

        if [[ $hit_time_int -gt 0 ]]; then
            sum_hit_time=$((sum_hit_time + hit_time_int))
            ((hit_count++))
        fi

        if [[ $miss_time_int -gt 0 ]]; then
            sum_miss_time=$((sum_miss_time + miss_time_int))
            ((miss_count++))
        fi
    done <<< "$stats"

    # Calculate hit rate
    local total=$((total_hits + total_misses))
    local hit_rate=0
    if [[ $total -gt 0 ]]; then
        hit_rate=$(( (total_hits * 100) / total ))
    fi

    # Calculate average times (convert back to float by dividing by 10)
    local avg_hit_time="0.0"
    local avg_miss_time="0.0"

    if [[ $hit_count -gt 0 ]]; then
        local avg_int=$((sum_hit_time / hit_count))
        avg_hit_time=$(awk -v val=$avg_int 'BEGIN {printf "%.1f", val / 10}')
    fi

    if [[ $miss_count -gt 0 ]]; then
        local avg_int=$((sum_miss_time / miss_count))
        avg_miss_time=$(awk -v val=$avg_int 'BEGIN {printf "%.1f", val / 10}')
    fi

    echo "$hit_rate:$total_hits:$total_misses:$avg_hit_time:$avg_miss_time"
}

# ============================================================================
# OPTIMIZATION RECOMMENDATIONS
# ============================================================================

# =============================================================================
# Function: _generate_cache_recommendations
# Purpose: Generate actionable cache optimization recommendations
# =============================================================================
# Arguments:
#   $1 - (optional) Cache directory path [default: "_freeze/site"]
#   $2 - (optional) Performance log path [default: ".teach/performance-log.json"]
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Bulleted list of recommendations (or "optimized" message)
#
# Example:
#   echo "Recommendations:"
#   _generate_cache_recommendations "_freeze/site"
#
# Notes:
#   - Recommends clearing > 30 days old files if > 30% of cache
#   - Suggests cache rebuild if hit rate < 80%
#   - Returns "optimized" message if no recommendations
# =============================================================================
_generate_cache_recommendations() {
    local cache_dir="${1:-_freeze/site}"
    local perf_log="${2:-.teach/performance-log.json}"

    local recommendations=()

    # Analyze age distribution
    local age_data=$(_analyze_cache_by_age "$cache_dir")

    if [[ -n "$age_data" ]]; then
        # Extract > 30 days stats
        local old_line=$(echo "$age_data" | grep "> 30 days")
        if [[ -n "$old_line" ]]; then
            local old_size=$(echo "$old_line" | cut -d: -f3)
            local old_count=$(echo "$old_line" | cut -d: -f4)
            local old_pct=$(echo "$old_line" | cut -d: -f5)

            # Recommend clearing old files if > 30%
            if [[ $old_pct -gt 30 ]]; then
                recommendations+=("Clear > 30 days: Save $old_size ($old_count files)")
            fi
        fi
    fi

    # Analyze cache hit rate
    if [[ -f "$perf_log" ]]; then
        local hit_rate_data=$(_calculate_cache_hit_rate "$perf_log" 7)
        local hit_rate=$(echo "$hit_rate_data" | cut -d: -f1)

        if [[ "$hit_rate" != "N/A" && $hit_rate -lt 80 ]]; then
            recommendations+=("Hit rate < 80%: Consider cache rebuild")
        fi
    fi

    # Analyze unused files (files with 0 hits in log)
    # This is a placeholder - would need actual unused file detection
    # For now, we skip this recommendation

    # Get total size
    local total_info=$(_analyze_cache_size "$cache_dir")
    local total_size=$(echo "$total_info" | cut -d: -f3)
    local total_files=$(echo "$total_info" | cut -d: -f2)

    # Recommend keeping recent files
    if [[ ${#recommendations[@]} -gt 0 ]]; then
        # Extract < 30 days data
        local recent_lines=$(echo "$age_data" | grep -v "> 30 days")
        local recent_pct=0

        while IFS=: read -r label size_bytes size_human count pct; do
            recent_pct=$((recent_pct + pct))
        done <<< "$recent_lines"

        if [[ $recent_pct -gt 0 && -f "$perf_log" ]]; then
            local hit_rate_data=$(_calculate_cache_hit_rate "$perf_log" 7)
            local hit_rate=$(echo "$hit_rate_data" | cut -d: -f1)

            if [[ "$hit_rate" != "N/A" ]]; then
                recommendations+=("Keep < 30 days: Preserve ${hit_rate}% hit rate")
            fi
        fi
    fi

    # Output recommendations
    if [[ ${#recommendations[@]} -gt 0 ]]; then
        for rec in "${recommendations[@]}"; do
            echo "  • $rec"
        done
    else
        echo "  • Cache is optimized (no recommendations)"
    fi
}

# ============================================================================
# FORMATTED CACHE REPORT
# ============================================================================

# =============================================================================
# Function: _format_cache_report
# Purpose: Generate and display a formatted cache analysis report
# =============================================================================
# Arguments:
#   $1 - (optional) Cache directory path [default: "_freeze/site"]
#   $2 - (optional) Performance log path [default: ".teach/performance-log.json"]
#   --recommend - Include optimization recommendations
#
# Returns:
#   0 - Report generated successfully
#   1 - Cache doesn't exist
#
# Output:
#   stdout - Formatted report with sections:
#            - Total stats
#            - By Directory breakdown
#            - By Age breakdown
#            - Cache Performance (if log exists)
#            - Recommendations (if --recommend flag)
#
# Example:
#   _format_cache_report "_freeze/site" ".teach/performance-log.json" --recommend
#
# Notes:
#   - Uses FLOW_COLORS for consistent theming
#   - Performance section requires jq and valid log file
# =============================================================================
_format_cache_report() {
    local cache_dir="${1:-_freeze/site}"
    local perf_log="${2:-.teach/performance-log.json}"
    local show_recommend=false

    # Parse flags
    shift 2
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --recommend)
                show_recommend=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    # Check if cache exists
    if [[ ! -d "$cache_dir" ]]; then
        _flow_log_warning "No cache found at $cache_dir"
        return 1
    fi

    echo ""
    echo "${FLOW_COLORS[header]}Cache Analysis Report${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[muted]}─────────────────────────────────────────────────────${FLOW_COLORS[reset]}"

    # Total stats
    local total_info=$(_analyze_cache_size "$cache_dir")
    local total_size=$(echo "$total_info" | cut -d: -f3)
    local total_files=$(echo "$total_info" | cut -d: -f2)

    echo "Total: $total_size ($total_files files)"
    echo ""

    # By Directory
    echo "${FLOW_COLORS[bold]}By Directory:${FLOW_COLORS[reset]}"
    local dir_data=$(_analyze_cache_by_directory "$cache_dir")

    if [[ -n "$dir_data" ]]; then
        while IFS=: read -r dir_name size_bytes size_human file_count pct; do
            printf "  %-15s %8s  (%3s files)  %3d%%\n" \
                "$dir_name" "$size_human" "$file_count" "$pct"
        done <<< "$dir_data"
    else
        echo "  ${FLOW_COLORS[muted]}No subdirectories${FLOW_COLORS[reset]}"
    fi

    echo ""

    # By Age
    echo "${FLOW_COLORS[bold]}By Age:${FLOW_COLORS[reset]}"
    local age_data=$(_analyze_cache_by_age "$cache_dir")

    if [[ -n "$age_data" ]]; then
        while IFS=: read -r label size_bytes size_human count pct; do
            printf "  %-12s %8s  (%3s files)  %3d%%\n" \
                "$label" "$size_human" "$count" "$pct"
        done <<< "$age_data"
    fi

    echo ""

    # Cache Performance (if log exists)
    if [[ -f "$perf_log" ]]; then
        echo "${FLOW_COLORS[bold]}Cache Performance:${FLOW_COLORS[reset]}"
        local hit_rate_data=$(_calculate_cache_hit_rate "$perf_log" 7)
        local hit_rate=$(echo "$hit_rate_data" | cut -d: -f1)
        local hits=$(echo "$hit_rate_data" | cut -d: -f2)
        local misses=$(echo "$hit_rate_data" | cut -d: -f3)
        local avg_hit=$(echo "$hit_rate_data" | cut -d: -f4)
        local avg_miss=$(echo "$hit_rate_data" | cut -d: -f5)

        if [[ "$hit_rate" != "N/A" ]]; then
            printf "  Hit rate:      %3d%% (last 7 days)\n" "$hit_rate"
            printf "  Miss rate:     %3d%%\n" "$((100 - hit_rate))"
            printf "  Avg hit time:  %ss\n" "$avg_hit"
            printf "  Avg miss time: %ss\n" "$avg_miss"
        else
            echo "  ${FLOW_COLORS[muted]}No performance data available${FLOW_COLORS[reset]}"
        fi

        echo ""
    fi

    # Recommendations (if requested)
    if [[ "$show_recommend" == "true" ]]; then
        echo "${FLOW_COLORS[bold]}Recommendations:${FLOW_COLORS[reset]}"
        _generate_cache_recommendations "$cache_dir" "$perf_log"
        echo ""
    fi
}

