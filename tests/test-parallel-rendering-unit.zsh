#!/usr/bin/env zsh
# test-parallel-rendering-unit.zsh - Unit tests for parallel rendering infrastructure
# Part of flow-cli v5.14.0 - Wave 2: Parallel Rendering Infrastructure

# Test framework setup
TESTS_PASSED=0
TESTS_FAILED=0
CURRENT_TEST=""

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test helpers
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"

    if [[ "$expected" == "$actual" ]]; then
        ((TESTS_PASSED++))
        echo -e "${GREEN}✓${NC} ${CURRENT_TEST}: ${message}"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "${RED}✗${NC} ${CURRENT_TEST}: ${message}"
        echo -e "  Expected: ${expected}"
        echo -e "  Actual:   ${actual}"
        return 1
    fi
}

assert_true() {
    local condition="$1"
    local message="${2:-}"

    if [[ $condition -eq 0 ]]; then
        ((TESTS_PASSED++))
        echo -e "${GREEN}✓${NC} ${CURRENT_TEST}: ${message}"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "${RED}✗${NC} ${CURRENT_TEST}: ${message}"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-File should exist}"

    if [[ -f "$file" ]]; then
        ((TESTS_PASSED++))
        echo -e "${GREEN}✓${NC} ${CURRENT_TEST}: ${message}"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "${RED}✗${NC} ${CURRENT_TEST}: ${message} (${file})"
        return 1
    fi
}

assert_not_empty() {
    local value="$1"
    local message="${2:-Value should not be empty}"

    if [[ -n "$value" ]]; then
        ((TESTS_PASSED++))
        echo -e "${GREEN}✓${NC} ${CURRENT_TEST}: ${message}"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "${RED}✗${NC} ${CURRENT_TEST}: ${message}"
        return 1
    fi
}

assert_gt() {
    local value="$1"
    local threshold="$2"
    local message="${3:-Value should be greater than threshold}"

    if [[ $value -gt $threshold ]]; then
        ((TESTS_PASSED++))
        echo -e "${GREEN}✓${NC} ${CURRENT_TEST}: ${message}"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "${RED}✗${NC} ${CURRENT_TEST}: ${message}"
        echo -e "  Value: ${value}, Threshold: ${threshold}"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String should contain substring}"

    if [[ "$haystack" == *"$needle"* ]]; then
        ((TESTS_PASSED++))
        echo -e "${GREEN}✓${NC} ${CURRENT_TEST}: ${message}"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "${RED}✗${NC} ${CURRENT_TEST}: ${message}"
        echo -e "  Haystack: ${haystack}"
        echo -e "  Needle:   ${needle}"
        return 1
    fi
}

# Load modules
SCRIPT_DIR="${0:A:h}"
source "${SCRIPT_DIR}/../lib/parallel-helpers.zsh"
source "${SCRIPT_DIR}/../lib/render-queue.zsh"
source "${SCRIPT_DIR}/../lib/parallel-progress.zsh"

# Test suite
echo -e "${YELLOW}Running Parallel Rendering Unit Tests${NC}"
echo ""

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TEST GROUP: CPU Detection
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo -e "${YELLOW}Test Group: CPU Detection${NC}"

CURRENT_TEST="detect_cpu_cores"
cores=$(_detect_cpu_cores)
assert_gt "$cores" 0 "Should detect at least 1 CPU core"

CURRENT_TEST="detect_cpu_cores_range"
if [[ $cores -ge 1 && $cores -le 128 ]]; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} ${CURRENT_TEST}: CPU count within valid range (${cores})"
else
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} ${CURRENT_TEST}: CPU count out of range (${cores})"
fi

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TEST GROUP: Worker Pool Creation
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo -e "${YELLOW}Test Group: Worker Pool Creation${NC}"

# Test pool creation
CURRENT_TEST="create_worker_pool"
pool_info=$(_create_worker_pool 2)
assert_not_empty "$pool_info" "Pool info should not be empty"

# Parse pool info
queue_file="${pool_info%%:*}"
remaining="${pool_info#*:}"
result_file="${remaining%%:*}"
worker_pids_str="${remaining#*:}"

CURRENT_TEST="pool_queue_file"
assert_file_exists "$queue_file" "Queue file should exist"

CURRENT_TEST="pool_result_file"
assert_file_exists "$result_file" "Result file should exist"

CURRENT_TEST="pool_worker_pids"
assert_not_empty "$worker_pids_str" "Worker PIDs should not be empty"

# Count worker PIDs
IFS=',' read -rA worker_pids <<< "$worker_pids_str"
CURRENT_TEST="pool_worker_count"
assert_equals "2" "${#worker_pids[@]}" "Should create 2 workers"

# Cleanup pool
_cleanup_workers "$pool_info" true
sleep 1

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TEST GROUP: Job Queue Operations
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo -e "${YELLOW}Test Group: Job Queue Operations${NC}"

# Create test files
test_queue=$(mktemp /tmp/test-queue.XXXXXX)
test_lock="/tmp/test-lock-dir"

# Test queue creation
CURRENT_TEST="create_job_queue"
test_files=("file1.qmd" "file2.qmd" "file3.qmd")
_create_job_queue "$test_queue" "${test_files[@]}"
queue_lines=$(wc -l < "$test_queue" | tr -d ' ')
assert_equals "3" "$queue_lines" "Queue should have 3 jobs"

# Test atomic fetch
CURRENT_TEST="fetch_job_atomic_first"
job1=$(_fetch_job_atomic "$test_queue" "$test_lock")
assert_not_empty "$job1" "Should fetch first job"

CURRENT_TEST="fetch_job_atomic_second"
job2=$(_fetch_job_atomic "$test_queue" "$test_lock")
assert_not_empty "$job2" "Should fetch second job"

CURRENT_TEST="fetch_job_atomic_third"
job3=$(_fetch_job_atomic "$test_queue" "$test_lock")
assert_not_empty "$job3" "Should fetch third job"

CURRENT_TEST="fetch_job_atomic_empty"
job4=$(_fetch_job_atomic "$test_queue" "$test_lock")
assert_equals "" "$job4" "Should return empty when queue is empty"

# Cleanup
rm -f "$test_queue"
rm -rf "$test_lock"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TEST GROUP: Time Estimation
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo -e "${YELLOW}Test Group: Time Estimation${NC}"

# Create test file for estimation
test_file=$(mktemp /tmp/test-file.qmd.XXXXXX)
cat > "$test_file" <<'EOF'
---
title: "Test Document"
---

# Introduction

Some content here.

```{r}
# R code chunk
x <- 1:10
```

More content.
EOF

CURRENT_TEST="estimate_render_time"
estimated=$(_estimate_render_time "$test_file")
assert_gt "$estimated" 0 "Estimated time should be greater than 0"

CURRENT_TEST="estimate_render_time_range"
if [[ $estimated -ge 5 && $estimated -le 120 ]]; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} ${CURRENT_TEST}: Estimated time in valid range (${estimated}s)"
else
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} ${CURRENT_TEST}: Estimated time out of range (${estimated}s)"
fi

# Test record render time
CURRENT_TEST="record_render_time"
_record_render_time "$test_file" 15
history_file="${HOME}/.cache/flow-cli/render-times.cache"
if grep -q "$test_file" "$history_file" 2>/dev/null; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} ${CURRENT_TEST}: Time recorded in cache"
else
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} ${CURRENT_TEST}: Time not recorded in cache"
fi

rm -f "$test_file"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TEST GROUP: Queue Optimization
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo -e "${YELLOW}Test Group: Queue Optimization${NC}"

# Create test files with different sizes
test_dir=$(mktemp -d /tmp/test-optimize.XXXXXX)
echo "Small file" > "$test_dir/small.qmd"
printf 'Medium file %.0s' {1..100} > "$test_dir/medium.qmd"
printf 'Large file %.0s' {1..1000} > "$test_dir/large.qmd"

CURRENT_TEST="optimize_render_queue"
optimized=$(_optimize_render_queue "$test_dir"/*.qmd)
assert_not_empty "$optimized" "Optimized queue should not be empty"

CURRENT_TEST="optimize_render_queue_count"
optimized_count=$(echo "$optimized" | wc -l | tr -d ' ')
assert_equals "3" "$optimized_count" "Should optimize 3 files"

# Check that large file comes first (slowest first strategy)
CURRENT_TEST="optimize_render_queue_order"
first_file=$(echo "$optimized" | head -n1 | cut -d'|' -f1)
if [[ "$first_file" == *"large.qmd" ]]; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} ${CURRENT_TEST}: Large file should be first"
else
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} ${CURRENT_TEST}: Large file should be first (got: $(basename "$first_file"))"
fi

rm -rf "$test_dir"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TEST GROUP: Load Balancing
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo -e "${YELLOW}Test Group: Load Balancing${NC}"

CURRENT_TEST="calculate_optimal_workers_small"
optimal=$(_calculate_optimal_workers 4)
if [[ $optimal -ge 1 && $optimal -le $(_detect_cpu_cores) ]]; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} ${CURRENT_TEST}: Optimal workers in valid range (${optimal})"
else
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} ${CURRENT_TEST}: Optimal workers out of range (${optimal})"
fi

CURRENT_TEST="calculate_optimal_workers_large"
optimal=$(_calculate_optimal_workers 100)
max_cores=$(_detect_cpu_cores)
if [[ $optimal -eq $max_cores ]]; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} ${CURRENT_TEST}: Optimal workers equals CPU count for large job"
else
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} ${CURRENT_TEST}: Optimal workers should equal CPU count (${optimal} != ${max_cores})"
fi

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TEST GROUP: Progress Tracking
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo -e "${YELLOW}Test Group: Progress Tracking${NC}"

CURRENT_TEST="init_progress_bar"
_init_progress_bar 10
assert_equals "10" "$PROGRESS_TOTAL_FILES" "Progress total should be set"

CURRENT_TEST="calculate_eta"
eta=$(_calculate_eta 5 10 50)
assert_equals "50" "$eta" "ETA should be 50s (5 files done in 50s, 5 remaining)"

CURRENT_TEST="format_duration_seconds"
formatted=$(_format_duration 45)
assert_equals "45s" "$formatted" "Should format seconds"

CURRENT_TEST="format_duration_minutes"
formatted=$(_format_duration 90)
assert_equals "1m 30s" "$formatted" "Should format minutes and seconds"

CURRENT_TEST="format_duration_hours"
formatted=$(_format_duration 3661)
assert_equals "1h 1m" "$formatted" "Should format hours and minutes"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TEST GROUP: Result Aggregation
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo -e "${YELLOW}Test Group: Result Aggregation${NC}"

# Create test results file
test_results=$(mktemp /tmp/test-results.XXXXXX)
cat > "$test_results" <<'EOF'
1|/path/to/file1.qmd|0|5|1000|1005
2|/path/to/file2.qmd|0|10|1005|1015
3|/path/to/file3.qmd|1|15|1015|1030
EOF

CURRENT_TEST="aggregate_results"
results_json=$(_aggregate_results "$test_results")
assert_not_empty "$results_json" "Results JSON should not be empty"

CURRENT_TEST="aggregate_results_format"
assert_contains "$results_json" '"file":' "Results should contain file field"
assert_contains "$results_json" '"status":' "Results should contain status field"
assert_contains "$results_json" '"duration":' "Results should contain duration field"

rm -f "$test_results"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TEST GROUP: Speedup Calculations
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo -e "${YELLOW}Test Group: Speedup Calculations${NC}"

CURRENT_TEST="calculate_speedup"
speedup=$(_calculate_speedup 100 25)
if command -v bc &>/dev/null; then
    assert_equals "4.0" "$speedup" "Speedup should be 4.0x"
else
    assert_equals "4" "$speedup" "Speedup should be 4x (integer)"
fi

CURRENT_TEST="calculate_speedup_zero"
speedup=$(_calculate_speedup 100 0)
assert_equals "1.0" "$speedup" "Speedup should be 1.0 when parallel time is 0"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TEST GROUP: File Categorization
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo -e "${YELLOW}Test Group: File Categorization${NC}"

# Create test files
test_dir=$(mktemp -d /tmp/test-categorize.XXXXXX)
echo "Small" > "$test_dir/small.qmd"
printf 'Medium %.0s' {1..100} > "$test_dir/medium.qmd"
printf 'Large %.0s' {1..1000} > "$test_dir/large.qmd"

CURRENT_TEST="categorize_files_by_time"
categories=$(_categorize_files_by_time "$test_dir"/*.qmd)
assert_not_empty "$categories" "Categories should not be empty"

CURRENT_TEST="categorize_files_format"
assert_contains "$categories" "|" "Categories should be pipe-separated"

rm -rf "$test_dir"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TEST GROUP: Parallel Time Estimation
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo -e "${YELLOW}Test Group: Parallel Time Estimation${NC}"

# Create test files
test_dir=$(mktemp -d /tmp/test-parallel-est.XXXXXX)
for i in {1..8}; do
    echo "File $i" > "$test_dir/file${i}.qmd"
done

CURRENT_TEST="estimate_total_time"
total_time=$(_estimate_total_time "$test_dir"/*.qmd)
assert_gt "$total_time" 0 "Total time should be greater than 0"

CURRENT_TEST="estimate_parallel_time"
parallel_time=$(_estimate_parallel_time 4 "$test_dir"/*.qmd)
assert_gt "$parallel_time" 0 "Parallel time should be greater than 0"

CURRENT_TEST="parallel_faster_than_serial"
if [[ $parallel_time -lt $total_time ]]; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} ${CURRENT_TEST}: Parallel should be faster than serial"
else
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} ${CURRENT_TEST}: Parallel should be faster (serial: ${total_time}, parallel: ${parallel_time})"
fi

rm -rf "$test_dir"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TEST GROUP: Edge Cases
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo -e "${YELLOW}Test Group: Edge Cases${NC}"

CURRENT_TEST="empty_file_list"
optimized=$(_optimize_render_queue)
if [[ -z "$optimized" ]]; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} ${CURRENT_TEST}: Should handle empty file list"
else
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} ${CURRENT_TEST}: Should return empty for empty file list"
fi

CURRENT_TEST="single_file"
test_file=$(mktemp /tmp/single.qmd.XXXXXX)
echo "Single file" > "$test_file"
optimized=$(_optimize_render_queue "$test_file")
optimized_count=$(echo "$optimized" | wc -l | tr -d ' ')
assert_equals "1" "$optimized_count" "Should handle single file"
rm -f "$test_file"

CURRENT_TEST="optimal_workers_zero_files"
optimal=$(_calculate_optimal_workers 0)
assert_equals "1" "$optimal" "Should return 1 worker for zero files"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# FINAL REPORT
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Total tests: $((TESTS_PASSED + TESTS_FAILED))"
echo -e "${GREEN}Passed: ${TESTS_PASSED}${NC}"
echo -e "${RED}Failed: ${TESTS_FAILED}${NC}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi
