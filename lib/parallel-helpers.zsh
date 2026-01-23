#!/usr/bin/env zsh
# parallel-helpers.zsh - Parallel rendering infrastructure for Quarto workflows
# Part of flow-cli v5.14.0 - Wave 2: Parallel Rendering Infrastructure

# Source dependencies
autoload -U colors && colors

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CPU DETECTION
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# =============================================================================
# Function: _detect_cpu_cores
# Purpose: Detect number of logical CPU cores on the current system
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Number of logical CPU cores (integer between 1 and 128)
#
# Example:
#   local cores=$(_detect_cpu_cores)
#   echo "System has $cores CPU cores"
#
# Notes:
#   - macOS: uses sysctl -n hw.ncpu
#   - Linux: uses nproc, falls back to /proc/cpuinfo
#   - Default fallback: 4 cores if detection fails
#   - Sanity check ensures result is between 1 and 128
# =============================================================================
_detect_cpu_cores() {
    local cores=4  # Default fallback

    if [[ "$OSTYPE" == darwin* ]]; then
        # macOS: use sysctl
        cores=$(sysctl -n hw.ncpu 2>/dev/null || echo 4)
    elif command -v nproc &>/dev/null; then
        # Linux: use nproc
        cores=$(nproc 2>/dev/null || echo 4)
    elif [[ -f /proc/cpuinfo ]]; then
        # Linux fallback: parse /proc/cpuinfo
        cores=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || echo 4)
    fi

    # Sanity check: cores should be between 1 and 128
    if [[ $cores -lt 1 || $cores -gt 128 ]]; then
        cores=4
    fi

    echo "$cores"
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# WORKER POOL MANAGEMENT
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# =============================================================================
# Function: _create_worker_pool
# Purpose: Create and start a pool of worker processes for parallel rendering
# =============================================================================
# Arguments:
#   $1 - (optional) Number of workers [default: CPU count]
#   $2 - (optional) Job queue file path [default: auto-generated temp file]
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Pool info string: "queue_file:result_file:worker_pids"
#            worker_pids is comma-separated list
#
# Example:
#   local pool=$(_create_worker_pool 8)
#   local queue="${pool%%:*}"
#   # Use pool...
#   _cleanup_workers "$pool" false
#
# Notes:
#   - Spawns worker processes in background using _worker_process
#   - Minimum 1 worker even if 0 is specified
#   - Each worker gets unique temp directory for Quarto isolation
#   - Workers automatically exit when queue is empty
#   - MUST call _cleanup_workers when done to prevent resource leaks
# =============================================================================
_create_worker_pool() {
    local num_workers="${1:-$(_detect_cpu_cores)}"
    local queue_file="${2:-$(mktemp /tmp/quarto-queue.XXXXXX)}"
    local result_file="$(mktemp /tmp/quarto-results.XXXXXX)"
    local worker_pids=()

    # Validate worker count
    if [[ $num_workers -lt 1 ]]; then
        num_workers=1
    fi

    # Start worker processes in background
    local script_dir="${0:A:h}"
    for i in {1..$num_workers}; do
        (_worker_process "$queue_file" "$result_file" "$i") &
        worker_pids+=($!)
    done

    # Return pool info as colon-separated string
    echo "${queue_file}:${result_file}:${(j:,:)worker_pids}"
}

# =============================================================================
# Function: _worker_process
# Purpose: Worker process main loop - fetches and executes render jobs
# =============================================================================
# Arguments:
#   $1 - (required) Queue file path to fetch jobs from
#   $2 - (required) Results file path to write results to
#   $3 - (required) Worker ID (for temp directory isolation)
#
# Returns:
#   0 - Exits when queue is empty
#
# Output:
#   Writes results to results file via _record_job_result
#   Error logs saved to /tmp/quarto-error-{job_id}.log on failure
#
# Example:
#   # Called internally by _create_worker_pool
#   (_worker_process "$queue" "$results" 1) &
#
# Notes:
#   - Runs in background, continuously fetches jobs until queue empty
#   - Uses atomic job fetching to prevent race conditions
#   - Each worker has isolated TMPDIR: /tmp/quarto-worker-{id}
#   - Records timing: start_time, end_time, duration
#   - Preserves error output for failed renders
#   - Cleans up temp directory on exit
# =============================================================================
_worker_process() {
    local queue_file="$1"
    local results_file="$2"
    local worker_id="$3"
    local lock_dir="${queue_file}.lock"
    local results_lock_dir="${results_file}.lock"

    # Set worker-specific temp directory for quarto
    export TMPDIR="/tmp/quarto-worker-${worker_id}"
    mkdir -p "$TMPDIR"

    # Source render-queue for atomic fetch function
    local script_dir="${0:A:h}"
    source "${script_dir}/render-queue.zsh" 2>/dev/null

    while true; do
        # Atomically fetch next job from queue
        local job=$(_fetch_job_atomic "$queue_file" "$lock_dir")

        # Exit if queue is empty
        [[ -z "$job" ]] && break

        # Parse job: format is "file_path|estimated_time|job_id"
        local file_path="${job%%|*}"
        local remaining="${job#*|}"
        local estimated_time="${remaining%%|*}"
        local job_id="${remaining#*|}"

        # Execute render with timing
        local start_time=$(date +%s)
        local render_output=$(mktemp /tmp/render-output.XXXXXX)
        local render_status=0

        # Run quarto render with output capture
        if quarto render "$file_path" > "$render_output" 2>&1; then
            render_status=0
        else
            render_status=$?
        fi

        local end_time=$(date +%s)
        local duration=$((end_time - start_time))

        # Prepare result record
        local result_record="${job_id}|${file_path}|${render_status}|${duration}|${start_time}|${end_time}"

        # Atomically write result using _record_job_result
        _record_job_result "$results_file" "$results_lock_dir" "$result_record"

        # Store output for error reporting
        if [[ $render_status -ne 0 ]]; then
            local error_file="/tmp/quarto-error-${job_id}.log"
            cp "$render_output" "$error_file"
        fi

        # Cleanup
        rm -f "$render_output"
    done

    # Cleanup worker temp directory
    rm -rf "$TMPDIR"
}

# =============================================================================
# Function: _distribute_jobs
# Purpose: Distribute render jobs to queue with optimized ordering
# =============================================================================
# Arguments:
#   $1 - (required) Queue file path to write jobs to
#   $@ - (required) List of file paths to render (remaining arguments)
#
# Returns:
#   0 - Success
#
# Output:
#   Writes optimized job list to queue file
#
# Example:
#   _distribute_jobs "/tmp/queue.txt" lecture1.qmd lecture2.qmd homework1.qmd
#
# Notes:
#   - Sources render-queue.zsh for optimization functions
#   - Uses _create_job_queue which orders slowest files first
#   - This ordering improves load balancing in parallel execution
#   - Must be called after _create_worker_pool, before workers start
# =============================================================================
_distribute_jobs() {
    local queue_file="$1"
    shift
    local -a files=("$@")

    # Source render-queue functions
    local script_dir="${0:A:h}"
    source "${script_dir}/render-queue.zsh" 2>/dev/null

    # Use _create_job_queue from render-queue.zsh
    _create_job_queue "$queue_file" "${files[@]}"
}

# =============================================================================
# Function: _wait_for_workers
# Purpose: Wait for all worker processes to complete with timeout
# =============================================================================
# Arguments:
#   $1 - (required) Comma-separated list of worker PIDs
#   $2 - (optional) Timeout in seconds [default: 3600 (1 hour)]
#
# Returns:
#   0 - All workers completed successfully
#   1 - Timeout reached (remaining workers are killed)
#
# Output:
#   None
#
# Example:
#   if ! _wait_for_workers "1234,1235,1236" 600; then
#       echo "Rendering timed out after 10 minutes"
#   fi
#
# Notes:
#   - Polls worker processes every 500ms using kill -0
#   - On timeout, sends SIGTERM to all remaining workers
#   - Checks timeout after each worker completes and every 10 seconds during wait
#   - Used by _parallel_render orchestrator
# =============================================================================
_wait_for_workers() {
    local worker_pids_str="$1"
    local timeout="${2:-3600}"
    local start_time=$(date +%s)

    # Parse PIDs
    local -a worker_pids
    IFS=',' read -rA worker_pids <<< "$worker_pids_str"

    # Wait for each worker with timeout
    for pid in "${worker_pids[@]}"; do
        local elapsed=$(($(date +%s) - start_time))
        if [[ $elapsed -ge $timeout ]]; then
            # Timeout: kill remaining workers
            for remaining_pid in "${worker_pids[@]}"; do
                kill -TERM "$remaining_pid" 2>/dev/null || true
            done
            return 1
        fi

        # Wait for this worker (with timeout check)
        local wait_start=$(date +%s)
        while kill -0 "$pid" 2>/dev/null; do
            sleep 0.5
            if [[ $(($(date +%s) - wait_start)) -ge 10 ]]; then
                # Check timeout again
                if [[ $(($(date +%s) - start_time)) -ge $timeout ]]; then
                    kill -TERM "$pid" 2>/dev/null || true
                    return 1
                fi
            fi
        done
    done

    return 0
}

# =============================================================================
# Function: _aggregate_results
# Purpose: Aggregate render results from all workers into JSON format
# =============================================================================
# Arguments:
#   $1 - (required) Results file path to read
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - JSON array of result objects
#            Format: [{"job_id":1,"file":"path","status":0,"duration":5,"start":123,"end":128},...]
#
# Example:
#   local results=$(_aggregate_results "/tmp/results.txt")
#   local failed=$(echo "$results" | grep -c '"status":[^0]')
#
# Notes:
#   - Returns "[]" if results file doesn't exist
#   - Parses pipe-delimited format: job_id|file_path|status|duration|start|end
#   - Builds JSON without jq dependency (simple string construction)
#   - Used for final summary display and error reporting
# =============================================================================
_aggregate_results() {
    local results_file="$1"
    local -a results=()

    # Read results file
    if [[ ! -f "$results_file" ]]; then
        echo "[]"
        return 0
    fi

    # Parse each result line
    while IFS="|" read -r job_id file_path render_status duration start_time end_time; do
        # Build JSON object
        local result_json="{\"job_id\":${job_id},\"file\":\"${file_path}\",\"status\":${status},\"duration\":${duration},\"start\":${start_time},\"end\":${end_time}}"
        results+=("$result_json")
    done < "$results_file"

    # Return JSON array
    echo "[${(j:,:)results}]"
}

# =============================================================================
# Function: _cleanup_workers
# Purpose: Cleanup worker pool and all temporary files
# =============================================================================
# Arguments:
#   $1 - (required) Pool info string from _create_worker_pool
#   $2 - (optional) Force kill workers: "true" or "false" [default: "false"]
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   None
#
# Example:
#   # Normal cleanup after workers finish
#   _cleanup_workers "$pool" false
#
#   # Force cleanup on interrupt/error
#   trap "_cleanup_workers '$pool' true" INT TERM EXIT
#
# Notes:
#   - If force_kill=true: sends SIGTERM, waits 1s, then SIGKILL
#   - Removes queue file and its lock directory
#   - Removes results file and its lock directory
#   - Removes all /tmp/quarto-worker-* directories
#   - Removes all /tmp/quarto-error-*.log files
#   - MUST be called to prevent resource leaks
# =============================================================================
_cleanup_workers() {
    local pool_info="$1"
    local force_kill="${2:-false}"

    # Parse pool info
    local queue_file="${pool_info%%:*}"
    local remaining="${pool_info#*:}"
    local result_file="${remaining%%:*}"
    local worker_pids_str="${remaining#*:}"

    # Kill workers if requested
    if [[ "$force_kill" == "true" ]]; then
        local -a worker_pids
        IFS=',' read -rA worker_pids <<< "$worker_pids_str"

        for pid in "${worker_pids[@]}"; do
            kill -TERM "$pid" 2>/dev/null || true
        done

        # Wait a moment for graceful shutdown
        sleep 1

        # Force kill if still running
        for pid in "${worker_pids[@]}"; do
            kill -KILL "$pid" 2>/dev/null || true
        done
    fi

    # Cleanup temporary files
    rm -f "$queue_file"
    rm -rf "${queue_file}.lock"
    rm -f "$result_file"
    rm -rf "${result_file}.lock"

    # Cleanup worker temp directories
    rm -rf /tmp/quarto-worker-*

    # Cleanup error logs
    rm -f /tmp/quarto-error-*.log
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# MAIN PARALLEL RENDERING ORCHESTRATOR
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# =============================================================================
# Function: _parallel_render
# Purpose: Main orchestrator for parallel Quarto rendering
# =============================================================================
# Arguments:
#   --workers N    - (optional) Number of workers [default: CPU count]
#   --timeout N    - (optional) Timeout in seconds [default: 3600]
#   --progress     - (optional) Show progress bar [default: true]
#   --no-progress  - (optional) Hide progress bar
#   --quiet        - (optional) Suppress all output (implies --no-progress)
#   --             - (optional) Separator before file list
#   files...       - (required) List of Quarto files to render
#
# Returns:
#   0 - All renders succeeded
#   1 - One or more renders failed or timeout occurred
#
# Output:
#   stdout - Progress bar, results summary, statistics (unless --quiet)
#   stderr - Error messages
#
# Example:
#   # Render all .qmd files with 8 workers
#   _parallel_render --workers 8 --progress -- *.qmd
#
#   # Quiet mode for scripts
#   _parallel_render --quiet lectures/*.qmd
#
# Notes:
#   - Creates worker pool, distributes jobs, monitors progress
#   - Sets up cleanup trap for INT/TERM signals
#   - Uses optimized job ordering (slowest first)
#   - Progress bar shows completion %, ETA, elapsed time
#   - Final display shows per-file results and aggregate statistics
# =============================================================================
_parallel_render() {
    local num_workers=$(_detect_cpu_cores)
    local timeout=3600
    local show_progress=true
    local quiet=false
    local -a files=()

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --workers)
                num_workers="$2"
                shift 2
                ;;
            --timeout)
                timeout="$2"
                shift 2
                ;;
            --progress)
                show_progress=true
                shift
                ;;
            --no-progress)
                show_progress=false
                shift
                ;;
            --quiet)
                quiet=true
                show_progress=false
                shift
                ;;
            --)
                shift
                files=("$@")
                break
                ;;
            *)
                files+=("$1")
                shift
                ;;
        esac
    done

    # Validate inputs
    if [[ ${#files[@]} -eq 0 ]]; then
        echo "Error: No files provided" >&2
        return 1
    fi

    # Create worker pool
    [[ "$quiet" == "false" ]] && echo "→ Detected $(_detect_cpu_cores) cores"
    [[ "$quiet" == "false" ]] && echo "→ Rendering ${#files[@]} files in parallel (${num_workers} workers)"

    local pool_info=$(_create_worker_pool "$num_workers")
    local queue_file="${pool_info%%:*}"
    local remaining="${pool_info#*:}"
    local result_file="${remaining%%:*}"

    # Setup cleanup trap
    trap "_cleanup_workers '$pool_info' true" INT TERM EXIT

    # Distribute jobs to queue
    _distribute_jobs "$queue_file" "${files[@]}"

    # Show progress if requested
    if [[ "$show_progress" == "true" ]]; then
        _monitor_progress "$result_file" "${#files[@]}" &
        local monitor_pid=$!
    fi

    # Wait for workers to complete
    local worker_pids_str="${remaining#*:}"
    if ! _wait_for_workers "$worker_pids_str" "$timeout"; then
        echo "Error: Rendering timed out after ${timeout}s" >&2
        _cleanup_workers "$pool_info" true
        return 1
    fi

    # Stop progress monitor
    if [[ "$show_progress" == "true" ]]; then
        kill "$monitor_pid" 2>/dev/null || true
        wait "$monitor_pid" 2>/dev/null || true
    fi

    # Aggregate results
    local results_json=$(_aggregate_results "$result_file")

    # Display results
    if [[ "$quiet" == "false" ]]; then
        _display_results "$results_json" "${#files[@]}"
    fi

    # Check for failures
    local failed_count=$(echo "$results_json" | grep -o '"status":[^0]' | wc -l | tr -d ' ')

    # Cleanup
    trap - INT TERM EXIT
    _cleanup_workers "$pool_info" false

    # Return exit code
    if [[ $failed_count -gt 0 ]]; then
        return 1
    else
        return 0
    fi
}

# =============================================================================
# Function: _monitor_progress
# Purpose: Monitor and display real-time rendering progress
# =============================================================================
# Arguments:
#   $1 - (required) Results file path to monitor
#   $2 - (required) Total number of files being rendered
#
# Returns:
#   0 - Exits when all files complete
#
# Output:
#   stdout - Real-time progress bar updates via parallel-progress.zsh
#
# Example:
#   # Called internally by _parallel_render
#   _monitor_progress "$result_file" "${#files[@]}" &
#   local monitor_pid=$!
#
# Notes:
#   - Designed to run in background
#   - Polls results file every 500ms for completion count
#   - Sources parallel-progress.zsh for display functions
#   - Exits automatically when completed count >= total
#   - Kill with monitor_pid when done or on error
# =============================================================================
_monitor_progress() {
    local results_file="$1"
    local total_files="$2"
    local start_time=$(date +%s)

    # Source progress helpers
    local script_dir="${0:A:h}"
    source "${script_dir}/parallel-progress.zsh" 2>/dev/null || return 0

    _init_progress_bar "$total_files"

    while true; do
        # Count completed jobs
        local completed=0
        if [[ -f "$results_file" ]]; then
            completed=$(wc -l < "$results_file" | tr -d ' ')
        fi

        # Update progress
        local elapsed=$(($(date +%s) - start_time))
        _update_progress "$completed" "$total_files" "$elapsed"

        # Exit if all done
        [[ $completed -ge $total_files ]] && break

        sleep 0.5
    done
}

# =============================================================================
# Function: _display_results
# Purpose: Display final rendering results with per-file status and statistics
# =============================================================================
# Arguments:
#   $1 - (required) Results JSON array from _aggregate_results
#   $2 - (required) Total file count
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Formatted results table showing:
#            - Per-file status (checkmark or X) with duration
#            - Total files, succeeded, failed counts
#            - Total and average time statistics
#
# Example:
#   local results=$(_aggregate_results "$result_file")
#   _display_results "$results" 10
#
# Notes:
#   - Uses simple JSON parsing (grep-based, no jq dependency)
#   - Shows checkmark for success, X for failure
#   - Extracts basename for cleaner display
#   - Calculates aggregate statistics from individual results
# =============================================================================
_display_results() {
    local results_json="$1"
    local total_files="$2"

    echo ""
    echo "Results:"

    # Parse and display each result
    # Note: This is a simple parser, would use jq in production
    local success_count=0
    local total_duration=0

    echo "$results_json" | grep -o '{[^}]*}' | while read -r result; do
        # Extract fields (simple parsing without jq)
        local file=$(echo "$result" | grep -o '"file":"[^"]*"' | cut -d'"' -f4)
        local status=$(echo "$result" | grep -o '"status":[0-9]*' | cut -d':' -f2)
        local duration=$(echo "$result" | grep -o '"duration":[0-9]*' | cut -d':' -f2)

        if [[ $status -eq 0 ]]; then
            echo "✓ $(basename "$file") (${duration}s)"
            ((success_count++))
        else
            echo "✗ $(basename "$file") (failed)"
        fi

        ((total_duration += duration))
    done

    # Calculate statistics
    local failed_count=$((total_files - success_count))
    local avg_duration=0
    if [[ $total_files -gt 0 ]]; then
        avg_duration=$((total_duration / total_files))
    fi

    echo ""
    echo "Statistics:"
    echo "  Total files: $total_files"
    echo "  Succeeded: $success_count"
    echo "  Failed: $failed_count"
    echo "  Total time: ${total_duration}s"
    echo "  Avg time: ${avg_duration}s per file"
}

# Export functions
typeset -gA PARALLEL_HELPERS_LOADED
PARALLEL_HELPERS_LOADED[version]="5.14.0"
PARALLEL_HELPERS_LOADED[loaded]=true
