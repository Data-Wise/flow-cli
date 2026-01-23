#!/usr/bin/env zsh
# render-queue.zsh - Smart queue optimization for parallel rendering
# Part of flow-cli v5.14.0 - Wave 2: Parallel Rendering Infrastructure

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TIME ESTIMATION
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# =============================================================================
# Function: _estimate_render_time
# Purpose: Estimate render time for a Quarto file based on history and heuristics
# =============================================================================
# Arguments:
#   $1 - (required) File path to the Quarto document
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Estimated render time in seconds (integer)
#
# Example:
#   local time=$(_estimate_render_time "/path/to/document.qmd")
#   echo "Estimated: ${time}s"
#
# Notes:
#   - First checks ~/.cache/flow-cli/render-times.cache for historical data
#   - Falls back to file size heuristics (<10KB: 5s, 10-50KB: 10s, >50KB: 20s)
#   - Adjusts for content complexity (code chunks, R/Python, images)
#   - Each code chunk adds 2s, R chunks add 5s total, Python 4s, images 1s
#   - Maximum estimate capped at 120 seconds
#   - Platform-aware: uses stat -f%z on macOS, stat -c%s on Linux
# =============================================================================
_estimate_render_time() {
    local file_path="$1"
    local history_file="${HOME}/.cache/flow-cli/render-times.cache"

    # Create cache directory if needed
    mkdir -p "$(dirname "$history_file")"

    # Check history cache
    if [[ -f "$history_file" ]]; then
        local cached_time=$(grep "^${file_path}|" "$history_file" | tail -n 1 | cut -d'|' -f2)
        if [[ -n "$cached_time" && "$cached_time" =~ ^[0-9]+$ && $cached_time -gt 0 ]]; then
            echo "$cached_time"
            return 0
        fi
    fi

    # Heuristic estimation based on file characteristics
    local estimated_time=10  # Default 10 seconds

    # Get file size in KB
    local file_size=0
    if [[ -f "$file_path" ]]; then
        if [[ "$OSTYPE" == darwin* ]]; then
            file_size=$(stat -f%z "$file_path" 2>/dev/null || echo 0)
        else
            file_size=$(stat -c%s "$file_path" 2>/dev/null || echo 0)
        fi
        # Convert to KB, ensure it's a number
        [[ "$file_size" =~ ^[0-9]+$ ]] || file_size=0
        file_size=$((file_size / 1024))
    fi

    # Size-based estimation
    # Small files (<10KB): 5s
    # Medium files (10-50KB): 10s
    # Large files (>50KB): 20s
    if [[ $file_size -lt 10 ]]; then
        estimated_time=5
    elif [[ $file_size -lt 50 ]]; then
        estimated_time=10
    else
        estimated_time=20
    fi

    # Content complexity heuristics
    if [[ -f "$file_path" ]]; then
        # Count code chunks (default to 0 if grep fails)
        local code_chunks=$(grep -c '^```{' "$file_path" 2>/dev/null || echo 0)
        [[ "$code_chunks" =~ ^[0-9]+$ ]] || code_chunks=0

        local r_chunks=$(grep -c '^```{r' "$file_path" 2>/dev/null || echo 0)
        [[ "$r_chunks" =~ ^[0-9]+$ ]] || r_chunks=0

        local py_chunks=$(grep -c '^```{python' "$file_path" 2>/dev/null || echo 0)
        [[ "$py_chunks" =~ ^[0-9]+$ ]] || py_chunks=0

        local images=$(grep -c '!\[.*\](.*)' "$file_path" 2>/dev/null || echo 0)
        [[ "$images" =~ ^[0-9]+$ ]] || images=0

        # Adjust estimate based on complexity
        # Each code chunk adds 2s
        estimated_time=$((estimated_time + code_chunks * 2))
        # R chunks add extra 3s each (total 5s per R chunk)
        estimated_time=$((estimated_time + r_chunks * 3))
        # Python chunks add extra 2s each (total 4s per Python chunk)
        estimated_time=$((estimated_time + py_chunks * 2))
        # Images add 1s each
        estimated_time=$((estimated_time + images))

        # Cap at reasonable maximum
        if [[ $estimated_time -gt 120 ]]; then
            estimated_time=120
        fi
    fi

    echo "$estimated_time"
}

# =============================================================================
# Function: _record_render_time
# Purpose: Record actual render time to history cache for future estimates
# =============================================================================
# Arguments:
#   $1 - (required) File path that was rendered
#   $2 - (required) Actual render time in seconds
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   None (writes to cache file)
#
# Example:
#   _record_render_time "/path/to/document.qmd" 15
#
# Notes:
#   - Appends to ~/.cache/flow-cli/render-times.cache
#   - Format: file_path|render_time|timestamp
#   - Automatically prunes cache to last 1000 entries to prevent unbounded growth
#   - Creates cache directory if it doesn't exist
# =============================================================================
_record_render_time() {
    local file_path="$1"
    local render_time="$2"
    local history_file="${HOME}/.cache/flow-cli/render-times.cache"

    # Create cache directory if needed
    mkdir -p "$(dirname "$history_file")"

    # Append to history (file|time|timestamp)
    local timestamp=$(date +%s)
    echo "${file_path}|${render_time}|${timestamp}" >> "$history_file"

    # Prune old entries (keep last 1000)
    if [[ -f "$history_file" ]] && [[ $(wc -l < "$history_file") -gt 1000 ]]; then
        tail -n 1000 "$history_file" > "${history_file}.tmp"
        mv "${history_file}.tmp" "$history_file"
    fi
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# QUEUE OPTIMIZATION
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# =============================================================================
# Function: _optimize_render_queue
# Purpose: Optimize render queue ordering for maximum parallelism efficiency
# =============================================================================
# Arguments:
#   $@ - (required) List of file paths to optimize
#
# Returns:
#   0 - Success (including empty input)
#
# Output:
#   stdout - Optimized list of "file_path|estimated_time" lines (one per line)
#
# Example:
#   local -a optimized=($(_optimize_render_queue file1.qmd file2.qmd file3.qmd))
#   for job in "${optimized[@]}"; do echo "$job"; done
#
# Notes:
#   - Orders files by estimated time in DESCENDING order (slowest first)
#   - This ensures long-running files start early and don't block completion
#   - Uses _estimate_render_time for time predictions
#   - Returns empty output for empty input (no error)
#   - Critical for load balancing in parallel rendering
# =============================================================================
_optimize_render_queue() {
    local -a files=("$@")
    local -a categorized_files=()

    # Return empty if no files
    if [[ ${#files[@]} -eq 0 ]]; then
        return 0
    fi

    # Estimate time for each file and categorize
    for file in "${files[@]}"; do
        local estimated_time=$(_estimate_render_time "$file")
        categorized_files+=("${estimated_time}|${file}")
    done

    # Sort by estimated time (descending - slowest first)
    # This ensures long-running files start early and don't block completion
    printf '%s\n' "${categorized_files[@]}" | sort -t'|' -k1 -rn | while IFS='|' read -r time file; do
        echo "${file}|${time}"
    done
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# JOB QUEUE OPERATIONS
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# =============================================================================
# Function: _create_job_queue
# Purpose: Create job queue file with optimized ordering and job IDs
# =============================================================================
# Arguments:
#   $1 - (required) Queue file path to write
#   $@ - (required) List of files to render (remaining arguments)
#
# Returns:
#   0 - Success
#
# Output:
#   Writes to queue file with format: file_path|estimated_time|job_id
#
# Example:
#   _create_job_queue "/tmp/render-queue.txt" file1.qmd file2.qmd file3.qmd
#   # Queue file will contain optimized job list with sequential IDs
#
# Notes:
#   - Truncates existing queue file before writing
#   - Uses _optimize_render_queue for optimal ordering
#   - Assigns sequential job IDs starting from 1
#   - Job IDs used for tracking results and error logs
# =============================================================================
_create_job_queue() {
    local queue_file="$1"
    shift
    local -a files=("$@")

    # Optimize file order
    local -a optimized_jobs=($(_optimize_render_queue "${files[@]}"))

    # Write to queue file with job IDs
    > "$queue_file"  # Truncate
    local job_id=1
    for job_line in "${optimized_jobs[@]}"; do
        echo "${job_line}|${job_id}" >> "$queue_file"
        ((job_id++))
    done
}

# =============================================================================
# Function: _fetch_job_atomic
# Purpose: Atomically fetch and remove next job from queue (thread-safe)
# =============================================================================
# Arguments:
#   $1 - (required) Queue file path
#   $2 - (required) Lock directory path (used as mutex)
#
# Returns:
#   0 - Always succeeds (empty output means queue is empty)
#
# Output:
#   stdout - Next job line "file_path|estimated_time|job_id" or empty string
#
# Example:
#   local job=$(_fetch_job_atomic "/tmp/queue.txt" "/tmp/queue.lock")
#   if [[ -n "$job" ]]; then
#       local file="${job%%|*}"
#       # Process file...
#   fi
#
# Notes:
#   - Uses mkdir-based locking for atomicity (portable across platforms)
#   - Retries up to 10 times with 100ms delay if lock is held
#   - Removes fetched job from queue file using sed
#   - Platform-aware sed: uses -i '' on macOS, -i on Linux
#   - Critical for preventing race conditions in parallel workers
# =============================================================================
_fetch_job_atomic() {
    local queue_file="$1"
    local lock_file="$2"
    local job=""

    # Simple atomic operation using lockfile
    # Try to acquire lock
    local max_tries=10
    local tries=0
    while [[ $tries -lt $max_tries ]]; do
        if mkdir "$lock_file" 2>/dev/null; then
            # Got lock - do the fetch
            job=$(head -n 1 "$queue_file" 2>/dev/null || echo "")

            # Remove first line if job exists
            if [[ -n "$job" ]]; then
                if [[ "$OSTYPE" == darwin* ]]; then
                    sed -i '' '1d' "$queue_file"
                else
                    sed -i '1d' "$queue_file"
                fi
            fi

            # Release lock
            rmdir "$lock_file" 2>/dev/null
            break
        fi

        # Didn't get lock, wait and retry
        sleep 0.1
        ((tries++))
    done

    echo "$job"
}

# =============================================================================
# Function: _record_job_result
# Purpose: Atomically record job result to results file (thread-safe)
# =============================================================================
# Arguments:
#   $1 - (required) Results file path
#   $2 - (required) Lock directory path (used as mutex)
#   $3 - (required) Result record: "job_id|file|status|duration|start|end"
#
# Returns:
#   0 - Always succeeds (retries on lock contention)
#
# Output:
#   Appends result record to results file
#
# Example:
#   local record="1|/path/file.qmd|0|15|1642000000|1642000015"
#   _record_job_result "/tmp/results.txt" "/tmp/results.lock" "$record"
#
# Notes:
#   - Uses mkdir-based locking for atomicity (portable across platforms)
#   - Retries up to 10 times with 100ms delay if lock is held
#   - Each worker calls this after completing a render job
#   - Results used by progress monitor and final aggregation
# =============================================================================
_record_job_result() {
    local results_file="$1"
    local lock_file="$2"
    local result_record="$3"

    # Simple atomic operation using lockfile
    local max_tries=10
    local tries=0
    while [[ $tries -lt $max_tries ]]; do
        if mkdir "$lock_file" 2>/dev/null; then
            echo "$result_record" >> "$results_file"
            rmdir "$lock_file" 2>/dev/null
            break
        fi
        sleep 0.1
        ((tries++))
    done
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# LOAD BALANCING
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# =============================================================================
# Function: _calculate_optimal_workers
# Purpose: Calculate optimal worker count for given workload
# =============================================================================
# Arguments:
#   $1 - (required) Total number of files to render
#   $2 - (optional) Average estimated time per file [default: 10]
#
# Returns:
#   0 - Success
#   1 - Error (parallel-helpers.zsh not found)
#
# Output:
#   stdout - Recommended worker count (integer)
#
# Example:
#   local workers=$(_calculate_optimal_workers 20)
#   echo "Using $workers workers"
#
# Notes:
#   - Never exceeds CPU core count
#   - Ensures at least 2 files per worker for efficiency
#   - Minimum 1 worker, maximum = CPU count
#   - Sources parallel-helpers.zsh if _detect_cpu_cores not available
#   - Formula: min(cores, files/2), bounded [1, cores]
# =============================================================================
_calculate_optimal_workers() {
    local file_count="$1"
    local avg_time="${2:-10}"

    # Source parallel-helpers if not already loaded
    if ! typeset -f _detect_cpu_cores > /dev/null 2>&1; then
        local script_dir="${0:A:h}"
        source "${script_dir}/parallel-helpers.zsh" 2>/dev/null || return 1
    fi

    local max_cores=$(_detect_cpu_cores)

    # Rules:
    # 1. Never exceed CPU count
    # 2. At least 2 files per worker for efficiency
    # 3. Minimum 1 worker, maximum CPU count

    local optimal_workers=$max_cores

    # Reduce if files < 2*cores
    if [[ $file_count -lt $((max_cores * 2)) ]]; then
        optimal_workers=$((file_count / 2))
    fi

    # Bounds checking
    if [[ $optimal_workers -lt 1 ]]; then
        optimal_workers=1
    elif [[ $optimal_workers -gt $max_cores ]]; then
        optimal_workers=$max_cores
    fi

    echo "$optimal_workers"
}

# =============================================================================
# Function: _categorize_files_by_time
# Purpose: Categorize files by estimated render time into fast/medium/slow
# =============================================================================
# Arguments:
#   $@ - (required) List of file paths to categorize
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Pipe-separated counts: "fast_count|medium_count|slow_count"
#
# Example:
#   local result=$(_categorize_files_by_time *.qmd)
#   local fast="${result%%|*}"
#   echo "Fast files: $fast"
#
# Notes:
#   - Fast: < 10 seconds estimated
#   - Medium: 10-30 seconds estimated
#   - Slow: > 30 seconds estimated
#   - Useful for workload analysis and progress estimation
#   - Uses _estimate_render_time for predictions
# =============================================================================
_categorize_files_by_time() {
    local -a files=("$@")
    local fast_count=0
    local medium_count=0
    local slow_count=0

    for file in "${files[@]}"; do
        local estimated_time=$(_estimate_render_time "$file")

        if [[ $estimated_time -lt 10 ]]; then
            ((fast_count++))
        elif [[ $estimated_time -lt 30 ]]; then
            ((medium_count++))
        else
            ((slow_count++))
        fi
    done

    # Output format: fast_count|medium_count|slow_count
    echo "${fast_count}|${medium_count}|${slow_count}"
}

# =============================================================================
# Function: _estimate_total_time
# Purpose: Estimate total render time if files were processed serially
# =============================================================================
# Arguments:
#   $@ - (required) List of file paths to estimate
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Total estimated time in seconds (integer)
#
# Example:
#   local total=$(_estimate_total_time *.qmd)
#   echo "Serial execution would take ${total}s"
#
# Notes:
#   - Simply sums individual file estimates
#   - Used as baseline for speedup calculations
#   - Compare with _estimate_parallel_time for parallelism benefits
# =============================================================================
_estimate_total_time() {
    local -a files=("$@")
    local total_time=0

    for file in "${files[@]}"; do
        local estimated_time=$(_estimate_render_time "$file")
        ((total_time += estimated_time))
    done

    echo "$total_time"
}

# =============================================================================
# Function: _estimate_parallel_time
# Purpose: Estimate render time with parallel execution simulation
# =============================================================================
# Arguments:
#   $1 - (required) Number of workers
#   $@ - (required) List of file paths (remaining arguments)
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Estimated parallel time in seconds (integer)
#
# Example:
#   local parallel_time=$(_estimate_parallel_time 4 *.qmd)
#   local serial_time=$(_estimate_total_time *.qmd)
#   echo "Speedup: $(( serial_time / parallel_time ))x"
#
# Notes:
#   - Simulates parallel execution with greedy job assignment
#   - Each job assigned to worker that will be free soonest
#   - Files sorted by estimated time (descending) for optimal scheduling
#   - Returns time when last worker finishes
#   - Used for ETA calculations and speedup predictions
# =============================================================================
_estimate_parallel_time() {
    local num_workers="$1"
    shift
    local -a files=("$@")

    # Get estimated times for all files
    local -a times=()
    for file in "${files[@]}"; do
        times+=($(_estimate_render_time "$file"))
    done

    # Sort times (descending)
    times=(${(On)times})

    # Simulate parallel execution
    # Workers array tracks when each worker will be free
    local -a worker_free_times=()
    for ((i=1; i<=num_workers; i++)); do
        worker_free_times+=(0)
    done

    # Assign each job to the worker that will be free soonest
    for time in "${times[@]}"; do
        # Find worker with minimum free time
        local min_time=${worker_free_times[1]}
        local min_idx=1
        for ((i=2; i<=num_workers; i++)); do
            if [[ ${worker_free_times[$i]} -lt $min_time ]]; then
                min_time=${worker_free_times[$i]}
                min_idx=$i
            fi
        done

        # Assign job to this worker
        worker_free_times[$min_idx]=$((min_time + time))
    done

    # Total time is when last worker finishes
    local max_time=${worker_free_times[1]}
    for time in "${worker_free_times[@]}"; do
        if [[ $time -gt $max_time ]]; then
            max_time=$time
        fi
    done

    echo "$max_time"
}

# =============================================================================
# Function: _calculate_speedup
# Purpose: Calculate speedup factor from serial vs parallel execution times
# =============================================================================
# Arguments:
#   $1 - (required) Serial execution time in seconds
#   $2 - (required) Parallel execution time in seconds
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Speedup factor as float (e.g., "3.5") or integer if bc unavailable
#
# Example:
#   local speedup=$(_calculate_speedup 120 30)
#   echo "Achieved ${speedup}x speedup"
#
# Notes:
#   - Returns "1.0" if parallel_time is 0 (avoids division by zero)
#   - Uses bc for floating point if available (scale=1)
#   - Falls back to integer division if bc not installed
#   - Formula: serial_time / parallel_time
# =============================================================================
_calculate_speedup() {
    local serial_time="$1"
    local parallel_time="$2"

    # Avoid division by zero
    if [[ $parallel_time -eq 0 ]]; then
        echo "1.0"
        return 0
    fi

    # Calculate speedup (use bc for floating point)
    if command -v bc &>/dev/null; then
        echo "scale=1; ${serial_time} / ${parallel_time}" | bc
    else
        # Fallback: integer division
        echo "$((serial_time / parallel_time))"
    fi
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# EXPORTS
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

typeset -gA RENDER_QUEUE_LOADED
RENDER_QUEUE_LOADED[version]="5.14.0"
RENDER_QUEUE_LOADED[loaded]=true
