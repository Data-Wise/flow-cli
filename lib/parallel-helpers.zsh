#!/usr/bin/env zsh
# parallel-helpers.zsh - Parallel rendering infrastructure for Quarto workflows
# Part of flow-cli v5.14.0 - Wave 2: Parallel Rendering Infrastructure

# Source dependencies
autoload -U colors && colors

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CPU DETECTION
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Detect number of CPU cores
# Returns: Number of logical CPU cores
# Platform: macOS (sysctl), Linux (nproc), fallback (4)
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

# Create worker pool for parallel rendering
# Args:
#   $1 - Number of workers (optional, defaults to CPU count)
#   $2 - Job queue file (optional, will create temp if not provided)
# Returns: "queue_file:result_file:worker_pids"
# Example: pool=$(_create_worker_pool 8)
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

# Worker process main loop
# Args:
#   $1 - Queue file path
#   $2 - Results file path
#   $3 - Worker ID
# Note: Runs in background, fetches jobs until queue is empty
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

# Distribute jobs to queue
# Args:
#   $1 - Queue file path
#   $@ - List of file paths to render
# Note: Optimizes job order for better parallelism
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

# Wait for all workers to complete
# Args:
#   $1 - Comma-separated list of worker PIDs
#   $2 - Timeout in seconds (optional, default 3600)
# Returns: 0 if all workers completed, 1 if timeout
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

# Aggregate results from all workers
# Args:
#   $1 - Results file path
# Returns: JSON array of result objects
# Format: [{"file":"path","status":0,"duration":5,"start":123,"end":128}...]
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

# Cleanup worker pool and temporary files
# Args:
#   $1 - Pool info string (from _create_worker_pool)
#   $2 - Force kill workers (optional, default: false)
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

# Main parallel rendering orchestrator
# Args:
#   --workers N     - Number of workers (default: CPU count)
#   --timeout N     - Timeout in seconds (default: 3600)
#   --progress      - Show progress bar (default: true)
#   --quiet         - Suppress output (default: false)
#   --              - Separator before file list
#   files...        - List of files to render
# Returns: 0 if all renders succeeded, 1 otherwise
# Example: _parallel_render --workers 8 --progress -- *.qmd
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

# Monitor progress in real-time
# Args:
#   $1 - Results file path
#   $2 - Total number of files
# Note: Runs in background, updates every 500ms
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

# Display final results
# Args:
#   $1 - Results JSON array
#   $2 - Total file count
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
