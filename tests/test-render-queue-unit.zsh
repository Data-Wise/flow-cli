#!/usr/bin/env zsh
# test-render-queue-unit.zsh - Unit tests for render queue optimization
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

assert_lt() {
    local value="$1"
    local threshold="$2"
    local message="${3:-Value should be less than threshold}"

    if [[ $value -lt $threshold ]]; then
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

# Load modules
SCRIPT_DIR="${0:A:h}"
source "${SCRIPT_DIR}/../lib/render-queue.zsh"
source "${SCRIPT_DIR}/../lib/parallel-helpers.zsh"

# Test suite
echo -e "${YELLOW}Running Render Queue Unit Tests${NC}"
echo ""

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TEST GROUP: Time Estimation - Basic
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo -e "${YELLOW}Test Group: Time Estimation - Basic${NC}"

# Create test file
test_file=$(mktemp /tmp/test-estimate.qmd.XXXXXX)
cat > "$test_file" <<'EOF'
---
title: "Test"
---

Simple file.
EOF

CURRENT_TEST="estimate_simple_file"
time=$(_estimate_render_time "$test_file")
assert_gt "$time" 0 "Estimated time should be positive"

CURRENT_TEST="estimate_simple_file_range"
if [[ $time -ge 5 && $time -le 20 ]]; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} ${CURRENT_TEST}: Simple file estimate in expected range (${time}s)"
else
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} ${CURRENT_TEST}: Simple file estimate out of range (${time}s)"
fi

rm -f "$test_file"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TEST GROUP: Time Estimation - Complexity
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo -e "${YELLOW}Test Group: Time Estimation - Complexity${NC}"

# Create file with R chunks
test_file=$(mktemp /tmp/test-r-chunks.qmd.XXXXXX)
cat > "$test_file" <<'EOF'
---
title: "R Analysis"
---

```{r}
x <- 1:100
```

```{r}
plot(x)
```
EOF

CURRENT_TEST="estimate_r_chunks"
time_r=$(_estimate_render_time "$test_file")
rm -f "$test_file"

# Create file without chunks
test_file=$(mktemp /tmp/test-no-chunks.qmd.XXXXXX)
cat > "$test_file" <<'EOF'
---
title: "Plain"
---

Just text.
EOF

time_plain=$(_estimate_render_time "$test_file")
rm -f "$test_file"

CURRENT_TEST="r_chunks_slower"
if [[ $time_r -gt $time_plain ]]; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} ${CURRENT_TEST}: R chunks should increase estimate"
else
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} ${CURRENT_TEST}: R chunks should increase estimate (R: ${time_r}, plain: ${time_plain})"
fi

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TEST GROUP: Time Estimation - File Size
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo -e "${YELLOW}Test Group: Time Estimation - File Size${NC}"

# Small file
test_file_small=$(mktemp /tmp/test-small.qmd.XXXXXX)
echo "Small" > "$test_file_small"

time_small=$(_estimate_render_time "$test_file_small")

# Large file
test_file_large=$(mktemp /tmp/test-large.qmd.XXXXXX)
printf 'Large %.0s' {1..2000} > "$test_file_large"

time_large=$(_estimate_render_time "$test_file_large")

CURRENT_TEST="large_file_slower"
if [[ $time_large -ge $time_small ]]; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} ${CURRENT_TEST}: Large files should have higher estimates"
else
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} ${CURRENT_TEST}: Large files should have higher estimates (large: ${time_large}, small: ${time_small})"
fi

rm -f "$test_file_small" "$test_file_large"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TEST GROUP: Render Time Recording
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo -e "${YELLOW}Test Group: Render Time Recording${NC}"

test_file=$(mktemp /tmp/test-record.qmd.XXXXXX)
echo "Test" > "$test_file"

CURRENT_TEST="record_render_time"
_record_render_time "$test_file" 12

history_file="${HOME}/.cache/flow-cli/render-times.cache"
assert_file_exists "$history_file" "History cache should be created"

CURRENT_TEST="record_in_cache"
if grep -q "$test_file" "$history_file"; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} ${CURRENT_TEST}: File recorded in cache"
else
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} ${CURRENT_TEST}: File not found in cache"
fi

CURRENT_TEST="record_correct_time"
cached_time=$(grep "$test_file" "$history_file" | tail -n1 | cut -d'|' -f2)
assert_equals "12" "$cached_time" "Cached time should match recorded time"

# Test that estimation uses cached time
CURRENT_TEST="estimate_uses_cache"
estimated=$(_estimate_render_time "$test_file")
assert_equals "12" "$estimated" "Estimation should use cached time"

rm -f "$test_file"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TEST GROUP: Queue Optimization
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo -e "${YELLOW}Test Group: Queue Optimization${NC}"

# Create test directory with files of different sizes
test_dir=$(mktemp -d /tmp/test-queue-opt.XXXXXX)

# Create small, medium, large files
echo "Small content" > "$test_dir/small.qmd"
printf 'Medium content %.0s' {1..100} > "$test_dir/medium.qmd"
printf 'Large content %.0s' {1..1000} > "$test_dir/large.qmd"

CURRENT_TEST="optimize_multiple_files"
optimized=$(_optimize_render_queue "$test_dir"/*.qmd)
assert_not_empty "$optimized" "Optimized queue should not be empty"

CURRENT_TEST="optimize_correct_count"
count=$(echo "$optimized" | wc -l | tr -d ' ')
assert_equals "3" "$count" "Should have 3 optimized entries"

CURRENT_TEST="optimize_format"
first_line=$(echo "$optimized" | head -n1)
if [[ "$first_line" == *"|"* ]]; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} ${CURRENT_TEST}: Output format is correct (file|time)"
else
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} ${CURRENT_TEST}: Output format incorrect: ${first_line}"
fi

# Check ordering (largest should be first)
CURRENT_TEST="optimize_largest_first"
first_file=$(echo "$optimized" | head -n1 | cut -d'|' -f1)
if [[ "$first_file" == *"large.qmd" ]]; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} ${CURRENT_TEST}: Largest file scheduled first"
else
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} ${CURRENT_TEST}: Largest file should be first (got: $(basename "$first_file"))"
fi

rm -rf "$test_dir"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TEST GROUP: Job Queue Creation
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo -e "${YELLOW}Test Group: Job Queue Creation${NC}"

test_queue=$(mktemp /tmp/test-create-queue.XXXXXX)
test_files=("file1.qmd" "file2.qmd" "file3.qmd")

CURRENT_TEST="create_job_queue"
_create_job_queue "$test_queue" "${test_files[@]}"
assert_file_exists "$test_queue" "Queue file should exist"

CURRENT_TEST="queue_has_jobs"
line_count=$(wc -l < "$test_queue" | tr -d ' ')
assert_equals "3" "$line_count" "Queue should have 3 lines"

CURRENT_TEST="queue_has_job_ids"
if grep -q '|[0-9]*$' "$test_queue"; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} ${CURRENT_TEST}: Queue entries have job IDs"
else
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} ${CURRENT_TEST}: Queue entries missing job IDs"
fi

rm -f "$test_queue"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TEST GROUP: Atomic Job Fetch
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo -e "${YELLOW}Test Group: Atomic Job Fetch${NC}"

test_queue=$(mktemp /tmp/test-fetch.XXXXXX)
test_lock="/tmp/test-fetch-lock-dir"

# Populate queue
cat > "$test_queue" <<'EOF'
file1.qmd|10|1
file2.qmd|15|2
file3.qmd|20|3
EOF

CURRENT_TEST="fetch_first_job"
job1=$(_fetch_job_atomic "$test_queue" "$test_lock")
assert_not_empty "$job1" "Should fetch first job"

CURRENT_TEST="fetch_removes_from_queue"
remaining=$(wc -l < "$test_queue" | tr -d ' ')
assert_equals "2" "$remaining" "Queue should have 2 jobs remaining"

CURRENT_TEST="fetch_second_job"
job2=$(_fetch_job_atomic "$test_queue" "$test_lock")
assert_not_empty "$job2" "Should fetch second job"

CURRENT_TEST="fetch_third_job"
job3=$(_fetch_job_atomic "$test_queue" "$test_lock")
assert_not_empty "$job3" "Should fetch third job"

CURRENT_TEST="fetch_from_empty"
job4=$(_fetch_job_atomic "$test_queue" "$test_lock")
if [[ -z "$job4" ]]; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} ${CURRENT_TEST}: Empty queue returns empty string"
else
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} ${CURRENT_TEST}: Empty queue should return empty (got: ${job4})"
fi

rm -f "$test_queue"
rm -rf "$test_lock"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TEST GROUP: Optimal Worker Calculation
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo -e "${YELLOW}Test Group: Optimal Worker Calculation${NC}"

max_cores=$(_detect_cpu_cores)

CURRENT_TEST="optimal_workers_small_job"
optimal=$(_calculate_optimal_workers 2)
assert_equals "1" "$optimal" "2 files should use 1 worker"

CURRENT_TEST="optimal_workers_medium_job"
optimal=$(_calculate_optimal_workers 16)
if [[ $optimal -ge 2 && $optimal -le $max_cores ]]; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} ${CURRENT_TEST}: 16 files use reasonable worker count (${optimal})"
else
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} ${CURRENT_TEST}: Worker count out of range (${optimal})"
fi

CURRENT_TEST="optimal_workers_large_job"
optimal=$(_calculate_optimal_workers 100)
assert_equals "$max_cores" "$optimal" "100 files should use all cores"

CURRENT_TEST="optimal_workers_never_exceed_cores"
optimal=$(_calculate_optimal_workers 1000)
if [[ $optimal -le $max_cores ]]; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} ${CURRENT_TEST}: Worker count never exceeds cores"
else
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} ${CURRENT_TEST}: Worker count exceeds cores (${optimal} > ${max_cores})"
fi

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TEST GROUP: File Categorization
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo -e "${YELLOW}Test Group: File Categorization${NC}"

test_dir=$(mktemp -d /tmp/test-categorize.XXXXXX)

# Create files that will be categorized as fast/medium/slow
echo "Fast" > "$test_dir/fast.qmd"
printf 'Medium %.0s' {1..100} > "$test_dir/medium.qmd"
printf 'Slow %.0s' {1..1000} > "$test_dir/slow.qmd"

CURRENT_TEST="categorize_files"
categories=$(_categorize_files_by_time "$test_dir"/*.qmd)
assert_not_empty "$categories" "Categories should not be empty"

CURRENT_TEST="categories_format"
if [[ "$categories" == *"|"*"|"* ]]; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} ${CURRENT_TEST}: Categories format is correct (fast|medium|slow)"
else
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} ${CURRENT_TEST}: Categories format incorrect: ${categories}"
fi

rm -rf "$test_dir"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TEST GROUP: Total Time Estimation
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo -e "${YELLOW}Test Group: Total Time Estimation${NC}"

test_dir=$(mktemp -d /tmp/test-total-time.XXXXXX)

# Create 5 test files
for i in {1..5}; do
    echo "File $i" > "$test_dir/file${i}.qmd"
done

CURRENT_TEST="estimate_total_time"
total_time=$(_estimate_total_time "$test_dir"/*.qmd)
assert_gt "$total_time" 0 "Total time should be positive"

CURRENT_TEST="total_time_sum"
# Total should be approximately 5 * avg_estimate
# With our heuristics, small files are ~5s
expected_min=$((5 * 5))  # 5 files * 5s
expected_max=$((5 * 20))  # 5 files * 20s
if [[ $total_time -ge $expected_min && $total_time -le $expected_max ]]; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} ${CURRENT_TEST}: Total time in expected range (${total_time}s)"
else
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} ${CURRENT_TEST}: Total time out of range (${total_time}s, expected ${expected_min}-${expected_max})"
fi

rm -rf "$test_dir"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TEST GROUP: Parallel Time Estimation
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo -e "${YELLOW}Test Group: Parallel Time Estimation${NC}"

test_dir=$(mktemp -d /tmp/test-parallel-time.XXXXXX)

# Create 8 test files
for i in {1..8}; do
    echo "File $i" > "$test_dir/file${i}.qmd"
done

CURRENT_TEST="estimate_parallel_time"
parallel_time=$(_estimate_parallel_time 4 "$test_dir"/*.qmd)
assert_gt "$parallel_time" 0 "Parallel time should be positive"

CURRENT_TEST="parallel_faster_than_serial"
total_time=$(_estimate_total_time "$test_dir"/*.qmd)
if [[ $parallel_time -lt $total_time ]]; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} ${CURRENT_TEST}: Parallel should be faster (serial: ${total_time}s, parallel: ${parallel_time}s)"
else
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} ${CURRENT_TEST}: Parallel should be faster"
fi

CURRENT_TEST="parallel_speedup_reasonable"
# With 4 workers and 8 files, speedup should be between 2x and 4x
speedup=$(_calculate_speedup "$total_time" "$parallel_time")
# Extract integer part
speedup_int=${speedup%.*}
if [[ $speedup_int -ge 2 ]]; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} ${CURRENT_TEST}: Speedup is reasonable (${speedup}x)"
else
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} ${CURRENT_TEST}: Speedup too low (${speedup}x)"
fi

rm -rf "$test_dir"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TEST GROUP: Speedup Calculation
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo -e "${YELLOW}Test Group: Speedup Calculation${NC}"

CURRENT_TEST="speedup_2x"
speedup=$(_calculate_speedup 100 50)
if command -v bc &>/dev/null; then
    assert_equals "2.0" "$speedup" "100/50 should be 2.0x"
else
    assert_equals "2" "$speedup" "100/50 should be 2x"
fi

CURRENT_TEST="speedup_4x"
speedup=$(_calculate_speedup 120 30)
if command -v bc &>/dev/null; then
    assert_equals "4.0" "$speedup" "120/30 should be 4.0x"
else
    assert_equals "4" "$speedup" "120/30 should be 4x"
fi

CURRENT_TEST="speedup_fractional"
speedup=$(_calculate_speedup 100 30)
if command -v bc &>/dev/null; then
    assert_equals "3.3" "$speedup" "100/30 should be 3.3x"
else
    assert_equals "3" "$speedup" "100/30 should be 3x"
fi

CURRENT_TEST="speedup_zero_parallel"
speedup=$(_calculate_speedup 100 0)
assert_equals "1.0" "$speedup" "Division by zero should return 1.0"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# FINAL REPORT
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
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
