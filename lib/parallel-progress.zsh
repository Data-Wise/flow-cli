#!/usr/bin/env zsh
# parallel-progress.zsh - Real-time progress tracking for parallel rendering
# Part of flow-cli v5.14.0 - Wave 2: Parallel Rendering Infrastructure

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PROGRESS BAR DISPLAY
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Global state for progress tracking
typeset -g PROGRESS_TOTAL_FILES=0
typeset -g PROGRESS_START_TIME=0
typeset -g PROGRESS_LAST_UPDATE=0

# Initialize progress bar
# Args:
#   $1 - Total number of files
_init_progress_bar() {
    local total_files="$1"
    PROGRESS_TOTAL_FILES=$total_files
    PROGRESS_START_TIME=$(date +%s)
    PROGRESS_LAST_UPDATE=0

    # Clear line and show initial progress
    echo ""
    echo "Progress:"
}

# Update progress bar display
# Args:
#   $1 - Completed count
#   $2 - Total count
#   $3 - Elapsed seconds
_update_progress() {
    local completed="$1"
    local total="$2"
    local elapsed="$3"

    # Throttle updates (max once per 500ms)
    local now=$(date +%s)
    if [[ $((now - PROGRESS_LAST_UPDATE)) -lt 1 && $completed -lt $total ]]; then
        return 0
    fi
    PROGRESS_LAST_UPDATE=$now

    # Calculate percentage
    local percent=0
    if [[ $total -gt 0 ]]; then
        percent=$((completed * 100 / total))
    fi

    # Build progress bar (40 chars wide)
    local bar_width=40
    local filled=$((percent * bar_width / 100))
    local empty=$((bar_width - filled))

    local bar=""
    for ((i=0; i<filled; i++)); do
        bar+="█"
    done
    for ((i=0; i<empty; i++)); do
        bar+="░"
    done

    # Calculate ETA
    local eta=$(_calculate_eta "$completed" "$total" "$elapsed")

    # Format elapsed time
    local elapsed_str=$(_format_duration "$elapsed")

    # Format ETA
    local eta_str=""
    if [[ $eta -gt 0 ]]; then
        eta_str=$(_format_duration "$eta")
    else
        eta_str="--"
    fi

    # Clear previous line and print progress
    # Use \r to return to start of line
    printf "\r[%s] %3d%% (%d/%d) - %s elapsed, ~%s remaining" \
        "$bar" "$percent" "$completed" "$total" "$elapsed_str" "$eta_str"

    # Add newline if complete
    if [[ $completed -ge $total ]]; then
        echo ""
    fi
}

# Calculate estimated time to completion
# Args:
#   $1 - Completed count
#   $2 - Total count
#   $3 - Elapsed seconds
# Returns: Estimated seconds remaining
_calculate_eta() {
    local completed="$1"
    local total="$2"
    local elapsed="$3"

    # Avoid division by zero
    if [[ $completed -eq 0 ]]; then
        echo 0
        return 0
    fi

    # Calculate average time per file
    local avg_time=$((elapsed / completed))

    # Calculate remaining files
    local remaining=$((total - completed))

    # Estimate remaining time
    local eta=$((remaining * avg_time))

    echo "$eta"
}

# Format duration as human-readable string
# Args:
#   $1 - Duration in seconds
# Returns: Formatted string (e.g., "1m 30s", "45s")
_format_duration() {
    local seconds="$1"

    if [[ $seconds -lt 60 ]]; then
        echo "${seconds}s"
    elif [[ $seconds -lt 3600 ]]; then
        local minutes=$((seconds / 60))
        local secs=$((seconds % 60))
        echo "${minutes}m ${secs}s"
    else
        local hours=$((seconds / 3600))
        local mins=$(((seconds % 3600) / 60))
        echo "${hours}h ${mins}m"
    fi
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# WORKER STATUS DISPLAY
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Show worker status (which files each worker is processing)
# Args:
#   $1 - Results file path
#   $2 - Queue file path
#   $3 - Number of workers
# Note: This is called periodically to show live status
_show_worker_status() {
    local results_file="$1"
    local queue_file="$2"
    local num_workers="$3"

    echo ""
    echo "Worker Status:"

    # This is a simplified version - in production would track worker states
    # For now, just show queue status
    local remaining=0
    if [[ -f "$queue_file" ]]; then
        remaining=$(wc -l < "$queue_file" | tr -d ' ')
    fi

    local completed=0
    if [[ -f "$results_file" ]]; then
        completed=$(wc -l < "$results_file" | tr -d ' ')
    fi

    echo "  Active workers: ${num_workers}"
    echo "  Completed: ${completed}"
    echo "  Remaining: ${remaining}"
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STATISTICS FORMATTING
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Format final statistics after render completion
# Args:
#   $1 - Results JSON array
#   $2 - Total file count
#   $3 - Number of workers
#   $4 - Total elapsed time
# Returns: Formatted statistics string
_format_stats() {
    local results_json="$1"
    local total_files="$2"
    local num_workers="$3"
    local total_time="$4"

    # Parse results to count successes/failures
    local success_count=0
    local failed_count=0
    local total_cpu_time=0

    # Simple JSON parsing (would use jq in production)
    echo "$results_json" | grep -o '"status":[0-9]*' | while read -r status_line; do
        local status=$(echo "$status_line" | cut -d':' -f2)
        if [[ $status -eq 0 ]]; then
            ((success_count++))
        else
            ((failed_count++))
        fi
    done

    # Extract durations
    echo "$results_json" | grep -o '"duration":[0-9]*' | while read -r duration_line; do
        local duration=$(echo "$duration_line" | cut -d':' -f2)
        ((total_cpu_time += duration))
    done

    # Calculate average time
    local avg_time=0
    if [[ $total_files -gt 0 ]]; then
        avg_time=$((total_cpu_time / total_files))
    fi

    # Calculate speedup
    local speedup="0.0"
    if [[ $total_time -gt 0 ]]; then
        if command -v bc &>/dev/null; then
            speedup=$(echo "scale=1; ${total_cpu_time} / ${total_time}" | bc)
        else
            speedup=$((total_cpu_time / total_time))
        fi
    fi

    # Build output
    cat <<EOF

Statistics:
  Total time: $(_format_duration "$total_time")
  Serial estimate: $(_format_duration "$total_cpu_time")
  Speedup: ${speedup}x
  Workers: ${num_workers}
  Files: ${total_files}
  Succeeded: ${success_count}
  Failed: ${failed_count}
  Avg time: ${avg_time}s per file
EOF
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# RESULT DISPLAY
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Display individual file results with status indicators
# Args:
#   $1 - Results JSON array
_display_file_results() {
    local results_json="$1"

    echo ""
    echo "Results:"

    # Parse and display each result
    # Format: ✓ file.qmd (5s) or ✗ file.qmd (failed)
    echo "$results_json" | grep -o '{[^}]*}' | while read -r result; do
        # Extract fields
        local file=$(echo "$result" | grep -o '"file":"[^"]*"' | cut -d'"' -f4)
        local status=$(echo "$result" | grep -o '"status":[0-9]*' | cut -d':' -f2)
        local duration=$(echo "$result" | grep -o '"duration":[0-9]*' | cut -d':' -f2)

        # Get basename for display
        local basename=$(basename "$file")

        # Format output with status indicator
        if [[ $status -eq 0 ]]; then
            echo "  ✓ ${basename} (${duration}s)"
        else
            echo "  ✗ ${basename} (failed)"
        fi
    done
}

# Display error details for failed renders
# Args:
#   $1 - Results JSON array
_display_error_details() {
    local results_json="$1"

    # Count failures
    local failed_count=$(echo "$results_json" | grep -o '"status":[^0]' | wc -l | tr -d ' ')

    if [[ $failed_count -eq 0 ]]; then
        return 0
    fi

    echo ""
    echo "Error Details:"

    # Find failed jobs and show error logs
    echo "$results_json" | grep -o '{[^}]*}' | while read -r result; do
        local job_id=$(echo "$result" | grep -o '"job_id":[0-9]*' | cut -d':' -f2)
        local file=$(echo "$result" | grep -o '"file":"[^"]*"' | cut -d'"' -f4)
        local status=$(echo "$result" | grep -o '"status":[0-9]*' | cut -d':' -f2)

        if [[ $status -ne 0 ]]; then
            echo ""
            echo "  File: $file"
            echo "  Exit code: $status"

            # Show error log if available
            local error_log="/tmp/quarto-error-${job_id}.log"
            if [[ -f "$error_log" ]]; then
                echo "  Error output:"
                tail -n 10 "$error_log" | sed 's/^/    /'
            fi
        fi
    done
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# COMPACT DISPLAY MODE
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Show compact progress (one line, updates in place)
# Args:
#   $1 - Completed count
#   $2 - Total count
#   $3 - Elapsed seconds
_show_compact_progress() {
    local completed="$1"
    local total="$2"
    local elapsed="$3"

    # Calculate percentage
    local percent=0
    if [[ $total -gt 0 ]]; then
        percent=$((completed * 100 / total))
    fi

    # Calculate ETA
    local eta=$(_calculate_eta "$completed" "$total" "$elapsed")
    local eta_str=$(_format_duration "$eta")

    # Show compact format
    printf "\rRendering: %d/%d (%d%%) - ETA: %s" \
        "$completed" "$total" "$percent" "$eta_str"

    # Newline when complete
    if [[ $completed -ge $total ]]; then
        echo ""
    fi
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# EXPORTS
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

typeset -gA PARALLEL_PROGRESS_LOADED
PARALLEL_PROGRESS_LOADED[version]="5.14.0"
PARALLEL_PROGRESS_LOADED[loaded]=true
