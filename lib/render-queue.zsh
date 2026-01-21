#!/usr/bin/env zsh
# render-queue.zsh - Smart queue optimization for parallel rendering
# Part of flow-cli v5.14.0 - Wave 2: Parallel Rendering Infrastructure

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TIME ESTIMATION
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Estimate render time for a file based on history and heuristics
# Args:
#   $1 - File path
# Returns: Estimated time in seconds
# Strategy:
#   1. Check render history cache
#   2. Use file size heuristics
#   3. Use content complexity heuristics
#   4. Default estimate
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

# Record actual render time to history cache
# Args:
#   $1 - File path
#   $2 - Actual render time in seconds
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

# Optimize render queue for maximum parallelism
# Args:
#   $@ - List of file paths
# Returns: Optimized list of "file_path|estimated_time" lines
# Strategy: Order by estimated time (slowest first) for better load balancing
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

# Create job queue file with optimized ordering
# Args:
#   $1 - Queue file path
#   $@ - List of files to render
# Note: Writes optimized job list to queue file
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

# Atomically fetch next job from queue
# Args:
#   $1 - Queue file path
#   $2 - Lock file path
# Returns: Next job line ("file_path|estimated_time|job_id") or empty if queue is empty
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

# Atomically record job result
# Args:
#   $1 - Results file path
#   $2 - Lock file path
#   $3 - Result record (job_id|file|status|duration|start|end)
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

# Calculate optimal worker count for given file list
# Args:
#   $1 - Total number of files
#   $2 - Average estimated time per file (optional)
# Returns: Recommended worker count
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

# Categorize files by estimated render time
# Args:
#   $@ - List of file paths
# Returns: Three counts via stdout (fast|medium|slow)
# Categories:
#   - Fast: < 10s
#   - Medium: 10-30s
#   - Slow: > 30s
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

# Estimate total render time (serial execution)
# Args:
#   $@ - List of file paths
# Returns: Total estimated time in seconds
_estimate_total_time() {
    local -a files=("$@")
    local total_time=0

    for file in "${files[@]}"; do
        local estimated_time=$(_estimate_render_time "$file")
        ((total_time += estimated_time))
    done

    echo "$total_time"
}

# Estimate parallel render time
# Args:
#   $1 - Number of workers
#   $@ - List of file paths (remaining args)
# Returns: Estimated parallel time in seconds
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

# Calculate speedup factor
# Args:
#   $1 - Serial time
#   $2 - Parallel time
# Returns: Speedup as float (e.g., "3.5")
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
