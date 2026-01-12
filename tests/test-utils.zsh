#!/usr/bin/env zsh
# tests/test-utils.zsh - Shared test utilities and assertion framework

# ============================================================================
# TEST FRAMEWORK GLOBALS
# ============================================================================

TEST_PASSED=0
TEST_FAILED=0
TEST_TOTAL=0
TEST_SUITE_NAME=""

# Test cache configuration
TEST_CACHE_FILE=""
TEST_PROJ_BASE=""

# Colors for output
C_GREEN="\033[0;32m"
C_RED="\033[0;31m"
C_YELLOW="\033[0;33m"
C_CYAN="\033[0;36m"
C_BOLD="\033[1m"
C_NC="\033[0m"

# ============================================================================
# TEST SUITE MANAGEMENT
# ============================================================================

test_suite_init() {
    TEST_SUITE_NAME="$1"
    TEST_PASSED=0
    TEST_FAILED=0
    TEST_TOTAL=0

    echo -e "${C_CYAN}╔══════════════════════════════════════════════════════════════╗${C_NC}"
    echo -e "${C_CYAN}║  ${TEST_SUITE_NAME}${C_NC}"
    echo -e "${C_CYAN}╚══════════════════════════════════════════════════════════════╝${C_NC}"
    echo ""
}

test_suite_summary() {
    echo ""
    echo -e "${C_CYAN}╔══════════════════════════════════════════════════════════════╗${C_NC}"
    echo -e "${C_CYAN}║  Test Results - ${TEST_SUITE_NAME}${C_NC}"
    echo -e "${C_CYAN}╚══════════════════════════════════════════════════════════════╝${C_NC}"
    echo ""
    echo -e "  Total:  $TEST_TOTAL"
    echo -e "  ${C_GREEN}Passed: $TEST_PASSED${C_NC}"
    echo -e "  ${C_RED}Failed: $TEST_FAILED${C_NC}"
    echo ""

    if (( TEST_FAILED == 0 )); then
        echo -e "${C_GREEN}✓ All tests passed!${C_NC}"
        exit 0
    else
        echo -e "${C_RED}✗ Some tests failed${C_NC}"
        exit 1
    fi
}

# ============================================================================
# TEST RUNNER
# ============================================================================

run_test() {
    local test_name="$1"
    local test_fn="$2"

    ((TEST_TOTAL++))

    echo -e "${C_CYAN}▶ Test $TEST_TOTAL: $test_name${C_NC}"

    # Run test and capture output
    local test_output
    test_output=$($test_fn 2>&1)
    local test_result=$?

    if [[ $test_result -eq 0 ]]; then
        echo -e "${C_GREEN}  ✓ PASS${C_NC}"
        ((TEST_PASSED++))
        return 0
    else
        echo -e "${C_RED}  ✗ FAIL${C_NC}"
        if [[ -n "$test_output" ]]; then
            echo "$test_output" | sed 's/^/    /'
        fi
        ((TEST_FAILED++))
        return 1
    fi
}

# ============================================================================
# SETUP/TEARDOWN HELPERS
# ============================================================================

setup_test_cache() {
    TEST_CACHE_FILE=$(mktemp)
    PROJ_CACHE_FILE="$TEST_CACHE_FILE"
    PROJ_CACHE_TTL=300
    FLOW_CACHE_ENABLED=1
}

setup_test_projects() {
    TEST_PROJ_BASE=$(mktemp -d)

    # Create fake project structure
    mkdir -p "$TEST_PROJ_BASE/dev-tools"
    mkdir -p "$TEST_PROJ_BASE/dev-tools/tool1/.git"
    mkdir -p "$TEST_PROJ_BASE/dev-tools/tool2/.git"
    mkdir -p "$TEST_PROJ_BASE/r-packages/active"
    mkdir -p "$TEST_PROJ_BASE/r-packages/active/pkg1/.git"

    # Override project categories for testing
    PROJ_CATEGORIES=(
        "dev-tools:dev:🔧"
        "r-packages/active:r:📦"
    )
    PROJ_BASE="$TEST_PROJ_BASE"
}

cleanup_test() {
    [[ -n "$TEST_CACHE_FILE" ]] && rm -f "$TEST_CACHE_FILE"
    [[ -n "$TEST_PROJ_BASE" ]] && rm -rf "$TEST_PROJ_BASE"
}

# Auto-cleanup on exit
trap cleanup_test EXIT

# ============================================================================
# ASSERTIONS
# ============================================================================

assert_true() {
    local cmd="$1"
    local msg="${2:-Assertion failed}"

    if eval "$cmd"; then
        return 0
    else
        echo "ASSERT_TRUE failed: $msg"
        echo "  Command: $cmd"
        return 1
    fi
}

assert_false() {
    local cmd="$1"
    local msg="${2:-Assertion failed}"

    if eval "$cmd"; then
        echo "ASSERT_FALSE failed: $msg"
        echo "  Command: $cmd"
        echo "  Expected: false, Got: true"
        return 1
    else
        return 0
    fi
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local msg="${3:-Values not equal}"

    if [[ "$expected" == "$actual" ]]; then
        return 0
    else
        echo "ASSERT_EQUALS failed: $msg"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        return 1
    fi
}

assert_not_equals() {
    local not_expected="$1"
    local actual="$2"
    local msg="${3:-Values should not be equal}"

    if [[ "$not_expected" != "$actual" ]]; then
        return 0
    else
        echo "ASSERT_NOT_EQUALS failed: $msg"
        echo "  Not Expected: $not_expected"
        echo "  Actual:       $actual"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local msg="${3:-String not found}"

    if [[ "$haystack" == *"$needle"* ]]; then
        return 0
    else
        echo "ASSERT_CONTAINS failed: $msg"
        echo "  Expected to find: '$needle'"
        echo "  In: '$haystack'"
        return 1
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local msg="${3:-String should not be found}"

    if [[ "$haystack" != *"$needle"* ]]; then
        return 0
    else
        echo "ASSERT_NOT_CONTAINS failed: $msg"
        echo "  Should not find: '$needle'"
        echo "  In: '$haystack'"
        return 1
    fi
}

assert_match() {
    local string="$1"
    local pattern="$2"
    local msg="${3:-String does not match pattern}"

    if [[ "$string" =~ $pattern ]]; then
        return 0
    else
        echo "ASSERT_MATCH failed: $msg"
        echo "  String:  $string"
        echo "  Pattern: $pattern"
        return 1
    fi
}

assert_not_match() {
    local string="$1"
    local pattern="$2"
    local msg="${3:-String should not match pattern}"

    if [[ ! "$string" =~ $pattern ]]; then
        return 0
    else
        echo "ASSERT_NOT_MATCH failed: $msg"
        echo "  String:  $string"
        echo "  Pattern: $pattern"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local msg="${2:-File does not exist}"

    if [[ -f "$file" ]]; then
        return 0
    else
        echo "ASSERT_FILE_EXISTS failed: $msg"
        echo "  File: $file"
        return 1
    fi
}

assert_file_not_exists() {
    local file="$1"
    local msg="${2:-File should not exist}"

    if [[ ! -f "$file" ]]; then
        return 0
    else
        echo "ASSERT_FILE_NOT_EXISTS failed: $msg"
        echo "  File: $file"
        return 1
    fi
}

assert_dir_exists() {
    local dir="$1"
    local msg="${2:-Directory does not exist}"

    if [[ -d "$dir" ]]; then
        return 0
    else
        echo "ASSERT_DIR_EXISTS failed: $msg"
        echo "  Directory: $dir"
        return 1
    fi
}

assert_dir_not_exists() {
    local dir="$1"
    local msg="${2:-Directory should not exist}"

    if [[ ! -d "$dir" ]]; then
        return 0
    else
        echo "ASSERT_DIR_NOT_EXISTS failed: $msg"
        echo "  Directory: $dir"
        return 1
    fi
}

assert_exit_code() {
    local expected_code="$1"
    local actual_code="$2"
    local msg="${3:-Exit code mismatch}"

    if [[ $expected_code -eq $actual_code ]]; then
        return 0
    else
        echo "ASSERT_EXIT_CODE failed: $msg"
        echo "  Expected: $expected_code"
        echo "  Actual:   $actual_code"
        return 1
    fi
}

assert_greater_than() {
    local value="$1"
    local threshold="$2"
    local msg="${3:-Value not greater than threshold}"

    if [[ $value -gt $threshold ]]; then
        return 0
    else
        echo "ASSERT_GREATER_THAN failed: $msg"
        echo "  Value:     $value"
        echo "  Threshold: $threshold"
        return 1
    fi
}

assert_less_than() {
    local value="$1"
    local threshold="$2"
    local msg="${3:-Value not less than threshold}"

    if [[ $value -lt $threshold ]]; then
        return 0
    else
        echo "ASSERT_LESS_THAN failed: $msg"
        echo "  Value:     $value"
        echo "  Threshold: $threshold"
        return 1
    fi
}

# ============================================================================
# TEST DATA HELPERS
# ============================================================================

create_mock_cache() {
    local timestamp="${1:-$(date +%s)}"
    local content="${2:-test|dev|🔧|/path|}"

    echo "# Generated: $timestamp" > "$TEST_CACHE_FILE"
    echo "$content" >> "$TEST_CACHE_FILE"
}

create_stale_cache() {
    local age="${1:-400}"  # Default: 400 seconds old (beyond 300s TTL)
    local old_time=$(($(date +%s) - age))

    create_mock_cache "$old_time" "stale|dev|🔧|/path|"
}

create_fresh_cache() {
    create_mock_cache "$(date +%s)" "fresh|dev|🔧|/path|"
}

create_corrupt_cache() {
    echo "# Generated: NOT_A_NUMBER" > "$TEST_CACHE_FILE"
    echo "corrupt|dev|🔧|/path|" >> "$TEST_CACHE_FILE"
}

# ============================================================================
# PERFORMANCE HELPERS
# ============================================================================

time_command() {
    local cmd="$1"
    local start=$(date +%s%N)
    eval "$cmd" >/dev/null 2>&1
    local end=$(date +%s%N)
    local duration=$(( (end - start) / 1000000 ))  # Convert to milliseconds
    echo "$duration"
}

assert_performance() {
    local cmd="$1"
    local max_ms="$2"
    local msg="${3:-Command too slow}"

    local duration=$(time_command "$cmd")

    if [[ $duration -le $max_ms ]]; then
        return 0
    else
        echo "ASSERT_PERFORMANCE failed: $msg"
        echo "  Command:  $cmd"
        echo "  Duration: ${duration}ms"
        echo "  Max:      ${max_ms}ms"
        return 1
    fi
}
