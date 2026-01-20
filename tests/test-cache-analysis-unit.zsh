#!/usr/bin/env zsh
# tests/test-cache-analysis-unit.zsh - Unit tests for cache analysis (Wave 4)

# Test framework setup
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

# Colors
COLOR_RESET="\033[0m"
COLOR_GREEN="\033[32m"
COLOR_RED="\033[31m"
COLOR_YELLOW="\033[33m"
COLOR_BLUE="\033[34m"
COLOR_BOLD="\033[1m"

# Get script directory
TEST_DIR="${0:A:h}"
PLUGIN_ROOT="${TEST_DIR:h}"

# Source plugin
source "$PLUGIN_ROOT/flow.plugin.zsh"

# Test helpers
assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    if [[ "$expected" == "$actual" ]]; then
        ((TESTS_PASSED++))
        echo "${COLOR_GREEN}✓${COLOR_RESET} $test_name"
        return 0
    else
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$test_name")
        echo "${COLOR_RED}✗${COLOR_RESET} $test_name"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        return 1
    fi
}

assert_contains() {
    local needle="$1"
    local haystack="$2"
    local test_name="$3"

    if [[ "$haystack" =~ "$needle" ]]; then
        ((TESTS_PASSED++))
        echo "${COLOR_GREEN}✓${COLOR_RESET} $test_name"
        return 0
    else
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$test_name")
        echo "${COLOR_RED}✗${COLOR_RESET} $test_name"
        echo "  Expected to contain: $needle"
        echo "  Actual: $haystack"
        return 1
    fi
}

assert_success() {
    local result=$1
    local test_name="$2"

    if [[ $result -eq 0 ]]; then
        ((TESTS_PASSED++))
        echo "${COLOR_GREEN}✓${COLOR_RESET} $test_name"
        return 0
    else
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$test_name")
        echo "${COLOR_RED}✗${COLOR_RESET} $test_name"
        echo "  Command failed with exit code: $result"
        return 1
    fi
}

assert_failure() {
    local result=$1
    local test_name="$2"

    if [[ $result -ne 0 ]]; then
        ((TESTS_PASSED++))
        echo "${COLOR_GREEN}✓${COLOR_RESET} $test_name"
        return 0
    else
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$test_name")
        echo "${COLOR_RED}✗${COLOR_RESET} $test_name"
        echo "  Expected failure, but command succeeded"
        return 1
    fi
}

# Setup test environment
setup_test_cache() {
    local test_dir="$1"

    # Create cache structure
    mkdir -p "$test_dir/_freeze/site/lectures"
    mkdir -p "$test_dir/_freeze/site/assignments"
    mkdir -p "$test_dir/_freeze/site/slides"

    # Create test files with different sizes and ages
    # Lectures (10 files, various ages)
    for i in {1..10}; do
        dd if=/dev/zero of="$test_dir/_freeze/site/lectures/week-$i.json" bs=1024 count=$((100 * i)) 2>/dev/null
    done

    # Assignments (5 files)
    for i in {1..5}; do
        dd if=/dev/zero of="$test_dir/_freeze/site/assignments/hw-$i.json" bs=1024 count=$((50 * i)) 2>/dev/null
    done

    # Slides (3 files)
    for i in {1..3}; do
        dd if=/dev/zero of="$test_dir/_freeze/site/slides/deck-$i.json" bs=1024 count=$((20 * i)) 2>/dev/null
    done

    # Set modification times (some old, some recent)
    # Set 5 files to > 30 days old
    local thirty_one_days_ago=$(date -v-31d +%Y%m%d%H%M.%S 2>/dev/null || date -d "31 days ago" +%Y%m%d%H%M.%S)
    touch -t "$thirty_one_days_ago" "$test_dir/_freeze/site/lectures/week-1.json" 2>/dev/null
    touch -t "$thirty_one_days_ago" "$test_dir/_freeze/site/lectures/week-2.json" 2>/dev/null
    touch -t "$thirty_one_days_ago" "$test_dir/_freeze/site/assignments/hw-1.json" 2>/dev/null

    # Set 3 files to 7-30 days old
    local fifteen_days_ago=$(date -v-15d +%Y%m%d%H%M.%S 2>/dev/null || date -d "15 days ago" +%Y%m%d%H%M.%S)
    touch -t "$fifteen_days_ago" "$test_dir/_freeze/site/lectures/week-3.json" 2>/dev/null
    touch -t "$fifteen_days_ago" "$test_dir/_freeze/site/assignments/hw-2.json" 2>/dev/null

    # Rest are recent (< 7 days) - already created as recent
}

create_performance_log() {
    local test_dir="$1"
    local log_file="$test_dir/.teach/performance-log.json"

    mkdir -p "$test_dir/.teach"

    # Calculate recent timestamps (current time - 1 day, current time)
    local now=$(date +%s)
    local yesterday=$((now - 86400))

    # Create sample performance log with recent timestamps
    cat > "$log_file" <<EOF
{
  "version": "1.0",
  "entries": [
    {
      "timestamp": $yesterday,
      "operation": "validate",
      "files": 12,
      "duration_sec": 45,
      "parallel": true,
      "workers": 8,
      "speedup": 3.5,
      "cache_hits": 8,
      "cache_misses": 4,
      "cache_hit_rate": 0.67,
      "avg_hit_time_sec": 0.3,
      "avg_miss_time_sec": 12.5
    },
    {
      "timestamp": $now,
      "operation": "validate",
      "files": 15,
      "duration_sec": 38,
      "parallel": true,
      "workers": 8,
      "speedup": 4.2,
      "cache_hits": 14,
      "cache_misses": 1,
      "cache_hit_rate": 0.93,
      "avg_hit_time_sec": 0.2,
      "avg_miss_time_sec": 11.8
    }
  ]
}
EOF
}

# ============================================================================
# TEST SUITE 1: Cache Size Analysis
# ============================================================================

echo ""
echo "${COLOR_BOLD}${COLOR_BLUE}Test Suite 1: Cache Size Analysis${COLOR_RESET}"
echo "${COLOR_BLUE}════════════════════════════════════════════════════${COLOR_RESET}"

# Test 1.1: Analyze empty cache
TEST_DIR=$(mktemp -d)
result=$(_analyze_cache_size "$TEST_DIR/_freeze/site" 2>&1)
exit_code=$?
assert_failure $exit_code "1.1: Analyze empty cache returns error"
assert_contains "0:0:0B" "$result" "1.1: Returns zero values for empty cache"
rm -rf "$TEST_DIR"

# Test 1.2: Analyze cache with files
TEST_DIR=$(mktemp -d)
setup_test_cache "$TEST_DIR"
result=$(_analyze_cache_size "$TEST_DIR/_freeze/site")
exit_code=$?
assert_success $exit_code "1.2: Analyze cache with files succeeds"

# Extract values
size_bytes=$(echo "$result" | cut -d: -f1)
file_count=$(echo "$result" | cut -d: -f2)
size_human=$(echo "$result" | cut -d: -f3)

assert_equals "18" "$file_count" "1.2: Correct file count (10+5+3)"
[[ $size_bytes -gt 0 ]] && assert_success 0 "1.2: Size bytes > 0" || assert_failure 1 "1.2: Size bytes > 0"
[[ -n "$size_human" ]] && assert_success 0 "1.2: Human size populated" || assert_failure 1 "1.2: Human size populated"

rm -rf "$TEST_DIR"

# ============================================================================
# TEST SUITE 2: Cache Breakdown by Directory
# ============================================================================

echo ""
echo "${COLOR_BOLD}${COLOR_BLUE}Test Suite 2: Cache Breakdown by Directory${COLOR_RESET}"
echo "${COLOR_BLUE}════════════════════════════════════════════════════${COLOR_RESET}"

# Test 2.1: Analyze by directory
TEST_DIR=$(mktemp -d)
setup_test_cache "$TEST_DIR"
result=$(_analyze_cache_by_directory "$TEST_DIR/_freeze/site")
exit_code=$?
assert_success $exit_code "2.1: Directory analysis succeeds"

# Count lines (should have 3: lectures, assignments, slides)
line_count=$(echo "$result" | wc -l | tr -d ' ')
assert_equals "3" "$line_count" "2.1: Three directory entries"

# Check for lectures entry
lectures_line=$(echo "$result" | grep "lectures:")
[[ -n "$lectures_line" ]] && assert_success 0 "2.1: Contains lectures entry" || assert_failure 1 "2.1: Contains lectures entry"

# Check for assignments entry
assignments_line=$(echo "$result" | grep "assignments:")
[[ -n "$assignments_line" ]] && assert_success 0 "2.1: Contains assignments entry" || assert_failure 1 "2.1: Contains assignments entry"

# Check for slides entry
slides_line=$(echo "$result" | grep "slides:")
[[ -n "$slides_line" ]] && assert_success 0 "2.1: Contains slides entry" || assert_failure 1 "2.1: Contains slides entry"

# Test 2.2: Verify file counts per directory
lectures_count=$(echo "$lectures_line" | cut -d: -f4)
assignments_count=$(echo "$assignments_line" | cut -d: -f4)
slides_count=$(echo "$slides_line" | cut -d: -f4)

assert_equals "10" "$lectures_count" "2.2: Lectures has 10 files"
assert_equals "5" "$assignments_count" "2.2: Assignments has 5 files"
assert_equals "3" "$slides_count" "2.2: Slides has 3 files"

# Test 2.3: Verify percentages sum to ~100%
lectures_pct=$(echo "$lectures_line" | cut -d: -f5)
assignments_pct=$(echo "$assignments_line" | cut -d: -f5)
slides_pct=$(echo "$slides_line" | cut -d: -f5)

total_pct=$((lectures_pct + assignments_pct + slides_pct))
[[ $total_pct -ge 95 && $total_pct -le 105 ]] && assert_success 0 "2.3: Percentages sum to ~100%" || assert_failure 1 "2.3: Percentages sum to ~100% (got $total_pct)"

rm -rf "$TEST_DIR"

# ============================================================================
# TEST SUITE 3: Cache Breakdown by Age
# ============================================================================

echo ""
echo "${COLOR_BOLD}${COLOR_BLUE}Test Suite 3: Cache Breakdown by Age${COLOR_RESET}"
echo "${COLOR_BLUE}════════════════════════════════════════════════════${COLOR_RESET}"

# Test 3.1: Analyze by age
TEST_DIR=$(mktemp -d)
setup_test_cache "$TEST_DIR"
result=$(_analyze_cache_by_age "$TEST_DIR/_freeze/site")
exit_code=$?
assert_success $exit_code "3.1: Age analysis succeeds"

# Should have 3 lines (< 7, 7-30, > 30)
line_count=$(echo "$result" | wc -l | tr -d ' ')
assert_equals "3" "$line_count" "3.1: Three age categories"

# Test 3.2: Verify age categories exist
recent=$(echo "$result" | grep "< 7 days:")
medium=$(echo "$result" | grep "7-30 days:")
old=$(echo "$result" | grep "> 30 days:")

[[ -n "$recent" ]] && assert_success 0 "3.2: Contains < 7 days category" || assert_failure 1 "3.2: Contains < 7 days category"
[[ -n "$medium" ]] && assert_success 0 "3.2: Contains 7-30 days category" || assert_failure 1 "3.2: Contains 7-30 days category"
[[ -n "$old" ]] && assert_success 0 "3.2: Contains > 30 days category" || assert_failure 1 "3.2: Contains > 30 days category"

# Test 3.3: Verify old files count
old_count=$(echo "$old" | cut -d: -f4)
[[ $old_count -eq 3 ]] && assert_success 0 "3.3: Old files count = 3" || assert_failure 1 "3.3: Old files count = 3 (got $old_count)"

# Test 3.4: Verify medium files count
medium_count=$(echo "$medium" | cut -d: -f4)
[[ $medium_count -eq 2 ]] && assert_success 0 "3.4: Medium age files = 2" || assert_failure 1 "3.4: Medium age files = 2 (got $medium_count)"

# Test 3.5: Verify recent files count
recent_count=$(echo "$recent" | cut -d: -f4)
[[ $recent_count -ge 13 ]] && assert_success 0 "3.5: Recent files >= 13" || assert_failure 1 "3.5: Recent files >= 13 (got $recent_count)"

rm -rf "$TEST_DIR"

# ============================================================================
# TEST SUITE 4: Cache Performance Analysis
# ============================================================================

echo ""
echo "${COLOR_BOLD}${COLOR_BLUE}Test Suite 4: Cache Performance Analysis${COLOR_RESET}"
echo "${COLOR_BLUE}════════════════════════════════════════════════════${COLOR_RESET}"

# Test 4.1: Missing performance log
TEST_DIR=$(mktemp -d)
result=$(_calculate_cache_hit_rate "$TEST_DIR/.teach/performance-log.json" 7)
exit_code=$?
assert_failure $exit_code "4.1: Returns error for missing log"
assert_contains "N/A" "$result" "4.1: Returns N/A for missing log"
rm -rf "$TEST_DIR"

# Test 4.2: Valid performance log
TEST_DIR=$(mktemp -d)
create_performance_log "$TEST_DIR"
result=$(_calculate_cache_hit_rate "$TEST_DIR/.teach/performance-log.json" 7)
exit_code=$?

# Check if jq is available
if command -v jq &>/dev/null; then
    assert_success $exit_code "4.2: Succeeds with valid log"

    # Extract values
    hit_rate=$(echo "$result" | cut -d: -f1)
    hits=$(echo "$result" | cut -d: -f2)
    misses=$(echo "$result" | cut -d: -f3)

    # Verify calculations (8+14=22 hits, 4+1=5 misses, rate=22/27=81%)
    assert_equals "22" "$hits" "4.2: Correct total hits (8+14)"
    assert_equals "5" "$misses" "4.2: Correct total misses (4+1)"
    [[ $hit_rate -ge 80 && $hit_rate -le 82 ]] && assert_success 0 "4.2: Hit rate ~81%" || assert_failure 1 "4.2: Hit rate ~81% (got $hit_rate)"
else
    assert_contains "N/A" "$result" "4.2: Returns N/A without jq"
fi

rm -rf "$TEST_DIR"

# ============================================================================
# TEST SUITE 5: Selective Cache Clearing
# ============================================================================

echo ""
echo "${COLOR_BOLD}${COLOR_BLUE}Test Suite 5: Selective Cache Clearing${COLOR_RESET}"
echo "${COLOR_BLUE}════════════════════════════════════════════════════${COLOR_RESET}"

# Test 5.1: Clear lectures only
TEST_DIR=$(mktemp -d)
setup_test_cache "$TEST_DIR"

# Count files before
before_lectures=$(find "$TEST_DIR/_freeze/site/lectures" -type f 2>/dev/null | wc -l | tr -d ' ')
before_assignments=$(find "$TEST_DIR/_freeze/site/assignments" -type f 2>/dev/null | wc -l | tr -d ' ')

# Clear lectures (with --force to skip confirmation)
_clear_cache_selective "$TEST_DIR" --lectures --force >/dev/null 2>&1
exit_code=$?
assert_success $exit_code "5.1: Clear lectures succeeds"

# Count files after
after_lectures=$(find "$TEST_DIR/_freeze/site/lectures" -type f 2>/dev/null | wc -l | tr -d ' ')
after_assignments=$(find "$TEST_DIR/_freeze/site/assignments" -type f 2>/dev/null | wc -l | tr -d ' ')

assert_equals "0" "$after_lectures" "5.1: Lectures cleared (0 files)"
assert_equals "$before_assignments" "$after_assignments" "5.1: Assignments untouched"

rm -rf "$TEST_DIR"

# Test 5.2: Clear old files only
TEST_DIR=$(mktemp -d)
setup_test_cache "$TEST_DIR"

before_total=$(find "$TEST_DIR/_freeze/site" -type f 2>/dev/null | wc -l | tr -d ' ')

# Clear old files (> 30 days)
_clear_cache_selective "$TEST_DIR" --old --force >/dev/null 2>&1
exit_code=$?
assert_success $exit_code "5.2: Clear old files succeeds"

after_total=$(find "$TEST_DIR/_freeze/site" -type f 2>/dev/null | wc -l | tr -d ' ')

# Should have cleared 3 files
cleared=$((before_total - after_total))
assert_equals "3" "$cleared" "5.2: Cleared 3 old files"

rm -rf "$TEST_DIR"

# Test 5.3: Combine multiple flags (--lectures --old)
TEST_DIR=$(mktemp -d)
setup_test_cache "$TEST_DIR"

# Clear old lecture files
_clear_cache_selective "$TEST_DIR" --lectures --old --force >/dev/null 2>&1
exit_code=$?
assert_success $exit_code "5.3: Combined flags succeed"

# Should have cleared 2 old lecture files (week-1, week-2)
remaining_lectures=$(find "$TEST_DIR/_freeze/site/lectures" -type f 2>/dev/null | wc -l | tr -d ' ')
assert_equals "8" "$remaining_lectures" "5.3: Removed 2 old lectures (8 remaining)"

rm -rf "$TEST_DIR"

# Test 5.4: No files match criteria
TEST_DIR=$(mktemp -d)
mkdir -p "$TEST_DIR/_freeze/site"

result=$(_clear_cache_selective "$TEST_DIR" --lectures --force 2>&1)
exit_code=$?
assert_failure $exit_code "5.4: Returns error when no files match"
assert_contains "No files matched" "$result" "5.4: Shows 'no files matched' message"

rm -rf "$TEST_DIR"

# ============================================================================
# TEST SUITE 6: Cache Report Formatting
# ============================================================================

echo ""
echo "${COLOR_BOLD}${COLOR_BLUE}Test Suite 6: Cache Report Formatting${COLOR_RESET}"
echo "${COLOR_BLUE}════════════════════════════════════════════════════${COLOR_RESET}"

# Test 6.1: Generate basic report
TEST_DIR=$(mktemp -d)
setup_test_cache "$TEST_DIR"

result=$(_format_cache_report "$TEST_DIR/_freeze/site" "$TEST_DIR/.teach/performance-log.json" 2>&1)
exit_code=$?
assert_success $exit_code "6.1: Generate basic report succeeds"

assert_contains "Cache Analysis Report" "$result" "6.1: Contains report header"
assert_contains "Total:" "$result" "6.1: Contains total section"
assert_contains "By Directory:" "$result" "6.1: Contains directory breakdown"
assert_contains "By Age:" "$result" "6.1: Contains age breakdown"

rm -rf "$TEST_DIR"

# Test 6.2: Generate report with recommendations
TEST_DIR=$(mktemp -d)
setup_test_cache "$TEST_DIR"
create_performance_log "$TEST_DIR"

result=$(_format_cache_report "$TEST_DIR/_freeze/site" "$TEST_DIR/.teach/performance-log.json" --recommend 2>&1)
exit_code=$?
assert_success $exit_code "6.2: Generate report with recommendations succeeds"

assert_contains "Recommendations:" "$result" "6.2: Contains recommendations section"

rm -rf "$TEST_DIR"

# Test 6.3: Report on empty cache
TEST_DIR=$(mktemp -d)

result=$(_format_cache_report "$TEST_DIR/_freeze/site" "$TEST_DIR/.teach/performance-log.json" 2>&1)
exit_code=$?
assert_failure $exit_code "6.3: Returns error for empty cache"
assert_contains "No cache found" "$result" "6.3: Shows 'no cache found' message"

rm -rf "$TEST_DIR"

# ============================================================================
# TEST SUITE 7: Optimization Recommendations
# ============================================================================

echo ""
echo "${COLOR_BOLD}${COLOR_BLUE}Test Suite 7: Optimization Recommendations${COLOR_RESET}"
echo "${COLOR_BLUE}════════════════════════════════════════════════════${COLOR_RESET}"

# Test 7.1: Recommend clearing old files (> 30%)
TEST_DIR=$(mktemp -d)
setup_test_cache "$TEST_DIR"

# Manually adjust to make > 30% old
for i in {4..10}; do
    local thirty_one_days_ago=$(date -v-31d +%Y%m%d%H%M.%S 2>/dev/null || date -d "31 days ago" +%Y%m%d%H%M.%S)
    touch -t "$thirty_one_days_ago" "$TEST_DIR/_freeze/site/lectures/week-$i.json" 2>/dev/null
done

result=$(_generate_cache_recommendations "$TEST_DIR/_freeze/site" "$TEST_DIR/.teach/performance-log.json")
exit_code=$?

# Should recommend clearing old files
assert_contains "Clear > 30 days" "$result" "7.1: Recommends clearing old files when > 30%"

rm -rf "$TEST_DIR"

# Test 7.2: No recommendations for optimized cache
TEST_DIR=$(mktemp -d)
setup_test_cache "$TEST_DIR"

# All files recent (< 7 days) - don't touch modification times
result=$(_generate_cache_recommendations "$TEST_DIR/_freeze/site" "$TEST_DIR/.teach/performance-log.json")

# Should have "no recommendations" or "optimized"
[[ "$result" =~ "optimized" || "$result" =~ "no recommendations" ]] && assert_success 0 "7.2: No recommendations for optimized cache" || assert_failure 1 "7.2: No recommendations for optimized cache"

rm -rf "$TEST_DIR"

# ============================================================================
# TEST RESULTS
# ============================================================================

echo ""
echo "${COLOR_BOLD}${COLOR_BLUE}════════════════════════════════════════════════════${COLOR_RESET}"
echo "${COLOR_BOLD}Test Results${COLOR_RESET}"
echo "${COLOR_BOLD}${COLOR_BLUE}════════════════════════════════════════════════════${COLOR_RESET}"
echo ""
echo "Passed: ${COLOR_GREEN}$TESTS_PASSED${COLOR_RESET}"
echo "Failed: ${COLOR_RED}$TESTS_FAILED${COLOR_RESET}"
echo "Total:  $((TESTS_PASSED + TESTS_FAILED))"
echo ""

if [[ $TESTS_FAILED -gt 0 ]]; then
    echo "${COLOR_RED}Failed tests:${COLOR_RESET}"
    for test in "${FAILED_TESTS[@]}"; do
        echo "  - $test"
    done
    echo ""
    exit 1
else
    echo "${COLOR_GREEN}${COLOR_BOLD}All tests passed!${COLOR_RESET}"
    echo ""
    exit 0
fi
