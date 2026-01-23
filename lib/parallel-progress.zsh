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

# =============================================================================
# Function: _init_progress_bar
# Purpose: Initialize progress bar state and display header
# =============================================================================
# Arguments:
#   $1 - (required) Total number of files to track
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Empty line and "Progress:" header
#   Sets global variables: PROGRESS_TOTAL_FILES, PROGRESS_START_TIME, PROGRESS_LAST_UPDATE
#
# Example:
#   _init_progress_bar 20
#   # Then call _update_progress repeatedly
#
# Notes:
#   - Must be called before _update_progress
#   - Initializes PROGRESS_START_TIME to current timestamp
#   - Resets PROGRESS_LAST_UPDATE to 0 for throttling
# =============================================================================
_init_progress_bar() {
    local total_files="$1"
    PROGRESS_TOTAL_FILES=$total_files
    PROGRESS_START_TIME=$(date +%s)
    PROGRESS_LAST_UPDATE=0

    # Clear line and show initial progress
    echo ""
    echo "Progress:"
}

# =============================================================================
# Function: _update_progress
# Purpose: Update progress bar display with current status
# =============================================================================
# Arguments:
#   $1 - (required) Number of completed files
#   $2 - (required) Total number of files
#   $3 - (required) Elapsed time in seconds
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Progress bar: [████████░░░░] 67% (8/12) - 1m 30s elapsed, ~45s remaining
#
# Example:
#   _update_progress 8 12 90
#
# Notes:
#   - Throttled to max once per second (prevents flicker)
#   - Uses carriage return (\r) to update in place
#   - Bar width: 40 characters using Unicode blocks
#   - Shows percentage, count, elapsed time, and ETA
#   - Adds newline when complete (completed >= total)
# =============================================================================
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

# =============================================================================
# Function: _calculate_eta
# Purpose: Calculate estimated time remaining based on current progress
# =============================================================================
# Arguments:
#   $1 - (required) Number of completed files
#   $2 - (required) Total number of files
#   $3 - (required) Elapsed time in seconds
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Estimated seconds remaining (integer), 0 if no work done yet
#
# Example:
#   local eta=$(_calculate_eta 5 20 60)  # 5 of 20 done in 60s
#   echo "ETA: ${eta}s"  # Output: ETA: 180s
#
# Notes:
#   - Returns 0 if completed count is 0 (avoids division by zero)
#   - Uses linear extrapolation: (remaining files) * (avg time per file)
#   - Average time = elapsed / completed
#   - Does not account for slowest-first ordering optimization
# =============================================================================
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

# =============================================================================
# Function: _format_duration
# Purpose: Format duration in seconds as human-readable string
# =============================================================================
# Arguments:
#   $1 - (required) Duration in seconds (integer)
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Formatted string: "45s", "1m 30s", or "2h 15m"
#
# Example:
#   _format_duration 45     # Output: 45s
#   _format_duration 90     # Output: 1m 30s
#   _format_duration 7500   # Output: 2h 5m
#
# Notes:
#   - < 60 seconds: shows seconds only
#   - < 3600 seconds: shows minutes and seconds
#   - >= 3600 seconds: shows hours and minutes (no seconds)
# =============================================================================
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

# =============================================================================
# Function: _show_worker_status
# Purpose: Display current worker status showing queue and completion state
# =============================================================================
# Arguments:
#   $1 - (required) Results file path
#   $2 - (required) Queue file path
#   $3 - (required) Number of workers
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Worker status summary:
#            Worker Status:
#              Active workers: 4
#              Completed: 8
#              Remaining: 12
#
# Example:
#   _show_worker_status "/tmp/results.txt" "/tmp/queue.txt" 4
#
# Notes:
#   - Counts completed jobs from results file (line count)
#   - Counts remaining jobs from queue file (line count)
#   - Simplified version - does not track individual worker assignments
#   - Can be called periodically for live status updates
# =============================================================================
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

# =============================================================================
# Function: _format_stats
# Purpose: Format final statistics after parallel render completion
# =============================================================================
# Arguments:
#   $1 - (required) Results JSON array from _aggregate_results
#   $2 - (required) Total file count
#   $3 - (required) Number of workers used
#   $4 - (required) Total elapsed wall-clock time in seconds
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Formatted statistics block:
#            Statistics:
#              Total time: 2m 30s
#              Serial estimate: 8m 45s
#              Speedup: 3.5x
#              Workers: 4
#              Files: 20
#              Succeeded: 18
#              Failed: 2
#              Avg time: 26s per file
#
# Example:
#   _format_stats "$results_json" 20 4 150
#
# Notes:
#   - Calculates speedup as total_cpu_time / wall_time
#   - Uses bc for floating point if available, falls back to integer
#   - Parses JSON with grep (no jq dependency)
#   - Shows both wall time and estimated serial time for comparison
# =============================================================================
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

# =============================================================================
# Function: _display_file_results
# Purpose: Display per-file results with success/failure indicators
# =============================================================================
# Arguments:
#   $1 - (required) Results JSON array from _aggregate_results
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Results list:
#            Results:
#              checkmark lecture-01.qmd (12s)
#              checkmark lecture-02.qmd (8s)
#              X homework-01.qmd (failed)
#
# Example:
#   _display_file_results "$results_json"
#
# Notes:
#   - Shows checkmark for status=0, X for non-zero status
#   - Displays basename only (not full path) for readability
#   - Shows duration in seconds for successful renders
#   - Uses simple grep-based JSON parsing (no jq dependency)
# =============================================================================
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

# =============================================================================
# Function: _display_error_details
# Purpose: Display detailed error information for failed renders
# =============================================================================
# Arguments:
#   $1 - (required) Results JSON array from _aggregate_results
#
# Returns:
#   0 - Always succeeds (even if no failures)
#
# Output:
#   stdout - Error details for each failed file:
#            Error Details:
#
#              File: /path/to/homework-01.qmd
#              Exit code: 1
#              Error output:
#                [last 10 lines of error log]
#
# Example:
#   _display_error_details "$results_json"
#
# Notes:
#   - Returns immediately if no failures detected
#   - Looks for error logs at /tmp/quarto-error-{job_id}.log
#   - Shows last 10 lines of error output (tail -n 10)
#   - Indents error output for readability
#   - Uses grep-based JSON parsing (no jq dependency)
# =============================================================================
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

# =============================================================================
# Function: _show_compact_progress
# Purpose: Show minimal one-line progress indicator (alternative to full bar)
# =============================================================================
# Arguments:
#   $1 - (required) Number of completed files
#   $2 - (required) Total number of files
#   $3 - (required) Elapsed time in seconds
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Compact progress: "Rendering: 8/12 (67%) - ETA: 45s"
#
# Example:
#   _show_compact_progress 8 12 90
#
# Notes:
#   - Uses carriage return (\r) to update in place
#   - More compact than _update_progress (no visual bar)
#   - Good for scripts or narrow terminals
#   - Adds newline when complete (completed >= total)
#   - Uses _calculate_eta and _format_duration for time display
# =============================================================================
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
