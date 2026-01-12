#!/usr/bin/env zsh
# tests/test-project-cache.zsh - Comprehensive test suite for project caching
# Tests cache generation, validation, stats, and integration with pick command

# Test framework setup
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

# Load the plugin (which loads all dependencies)
source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
    echo "ERROR: Failed to load plugin from $PROJECT_ROOT/flow.plugin.zsh"
    echo "SCRIPT_DIR: $SCRIPT_DIR"
    echo "PROJECT_ROOT: $PROJECT_ROOT"
    exit 1
}

# Set pipefail for better error detection
setopt pipefail

# Test configuration
TEST_CACHE_FILE=$(mktemp)
TEST_PROJ_BASE=$(mktemp -d)
TEST_PASSED=0
TEST_FAILED=0
TEST_TOTAL=0

# Override cache location for testing
PROJ_CACHE_FILE="$TEST_CACHE_FILE"
PROJ_CACHE_TTL=300

# Colors for output
C_GREEN="\033[0;32m"
C_RED="\033[0;31m"
C_YELLOW="\033[0;33m"
C_CYAN="\033[0;36m"
C_NC="\033[0m"

# ============================================================================
# TEST FRAMEWORK
# ============================================================================

# Run a test and track results
run_test() {
    local test_name="$1"
    local test_fn="$2"

    ((TEST_TOTAL++))

    echo -e "${C_CYAN}▶ Test $TEST_TOTAL: $test_name${C_NC}"

    if $test_fn; then
        echo -e "${C_GREEN}  ✓ PASS${C_NC}"
        ((TEST_PASSED++))
        return 0
    else
        echo -e "${C_RED}  ✗ FAIL${C_NC}"
        ((TEST_FAILED++))
        return 1
    fi
}

# Assertions
assert_file_exists() {
    local file="$1"
    if [[ -f "$file" ]]; then
        return 0
    else
        echo "    Expected file to exist: $file"
        return 1
    fi
}

assert_file_not_exists() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        return 0
    else
        echo "    Expected file to not exist: $file"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    if [[ "$haystack" == *"$needle"* ]]; then
        return 0
    else
        echo "    Expected to find: '$needle'"
        echo "    In: '$haystack'"
        return 1
    fi
}

assert_true() {
    local cmd="$1"
    if eval "$cmd"; then
        return 0
    else
        echo "    Expected command to return true: $cmd"
        return 1
    fi
}

assert_false() {
    local cmd="$1"
    if ! eval "$cmd"; then
        return 0
    else
        echo "    Expected command to return false: $cmd"
        return 1
    fi
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    if [[ "$expected" == "$actual" ]]; then
        return 0
    else
        echo "    Expected: $expected"
        echo "    Actual:   $actual"
        return 1
    fi
}

# ============================================================================
# SETUP/TEARDOWN
# ============================================================================

setup_test_projects() {
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

cleanup_test_projects() {
    rm -rf "$TEST_PROJ_BASE"
    rm -f "$TEST_CACHE_FILE"
}

# ============================================================================
# TEST CASES
# ============================================================================

test_cache_generation() {
    rm -f "$PROJ_CACHE_FILE"

    # Generate cache
    _proj_cache_generate || return 1

    # Verify cache file exists
    assert_file_exists "$PROJ_CACHE_FILE" || return 1

    # Verify timestamp header
    local first_line=$(head -1 "$PROJ_CACHE_FILE")
    assert_contains "$first_line" "# Generated:" || return 1

    # Verify timestamp is numeric
    local timestamp=$(echo "$first_line" | sed 's/# Generated: //')
    [[ "$timestamp" =~ ^[0-9]+$ ]] || {
        echo "    Timestamp not numeric: $timestamp"
        return 1
    }

    return 0
}

test_cache_validity_fresh() {
    rm -f "$PROJ_CACHE_FILE"

    # Generate fresh cache
    _proj_cache_generate || return 1

    # Should be valid immediately after generation
    assert_true "_proj_cache_is_valid" || return 1

    return 0
}

test_cache_validity_stale() {
    rm -f "$PROJ_CACHE_FILE"

    # Generate cache
    _proj_cache_generate || return 1

    # Artificially age cache beyond TTL
    local old_time=$(($(date +%s) - PROJ_CACHE_TTL - 10))

    # Update timestamp in cache file
    local temp_file=$(mktemp)
    {
        echo "# Generated: $old_time"
        tail -n +2 "$PROJ_CACHE_FILE"
    } > "$temp_file"
    mv "$temp_file" "$PROJ_CACHE_FILE"

    # Should be invalid (stale)
    assert_false "_proj_cache_is_valid" || return 1

    return 0
}

test_cache_validity_missing() {
    rm -f "$PROJ_CACHE_FILE"

    # Should be invalid when file doesn't exist
    assert_false "_proj_cache_is_valid" || return 1

    return 0
}

test_cache_validity_corrupt() {
    # Create corrupt cache file (invalid timestamp)
    echo "# Generated: not-a-number" > "$PROJ_CACHE_FILE"
    echo "dummy|data|here" >> "$PROJ_CACHE_FILE"

    # Should be invalid with corrupt timestamp
    assert_false "_proj_cache_is_valid" || return 1

    return 0
}

test_cache_invalidation() {
    rm -f "$PROJ_CACHE_FILE"

    # Generate cache
    _proj_cache_generate || return 1
    assert_file_exists "$PROJ_CACHE_FILE" || return 1

    # Invalidate
    _proj_cache_invalidate || return 1

    # Should be deleted
    assert_file_not_exists "$PROJ_CACHE_FILE" || return 1

    return 0
}

test_cache_stats_valid() {
    rm -f "$PROJ_CACHE_FILE"

    # Generate cache
    _proj_cache_generate || return 1

    # Get stats
    local output=$(_proj_cache_stats)

    # Verify output contains expected fields
    assert_contains "$output" "Cache status:" || return 1
    assert_contains "$output" "Cache age:" || return 1
    assert_contains "$output" "Projects cached:" || return 1
    assert_contains "$output" "Valid" || return 1

    return 0
}

test_cache_stats_missing() {
    rm -f "$PROJ_CACHE_FILE"

    # Get stats with no cache
    local output=$(_proj_cache_stats 2>&1)

    # Should report no cache
    assert_contains "$output" "No cache file exists" || return 1

    return 0
}

test_cache_stats_stale() {
    rm -f "$PROJ_CACHE_FILE"

    # Generate and age cache
    _proj_cache_generate || return 1
    local old_time=$(($(date +%s) - PROJ_CACHE_TTL - 10))

    local temp_file=$(mktemp)
    {
        echo "# Generated: $old_time"
        tail -n +2 "$PROJ_CACHE_FILE"
    } > "$temp_file"
    mv "$temp_file" "$PROJ_CACHE_FILE"

    # Get stats
    local output=$(_proj_cache_stats)

    # Should show stale
    assert_contains "$output" "Stale" || return 1

    return 0
}

test_cached_list_generates_on_missing() {
    rm -f "$PROJ_CACHE_FILE"

    # Enable cache
    FLOW_CACHE_ENABLED=1

    # Call cached list (should auto-generate)
    local output=$(_proj_list_all_cached)

    # Cache should now exist
    assert_file_exists "$PROJ_CACHE_FILE" || return 1

    return 0
}

test_cached_list_uses_valid_cache() {
    rm -f "$PROJ_CACHE_FILE"

    # Generate cache with known content
    {
        echo "# Generated: $(date +%s)"
        echo "test-project|dev|🔧|/path/to/test|"
    } > "$PROJ_CACHE_FILE"

    # Enable cache
    FLOW_CACHE_ENABLED=1

    # Should return cached content
    local output=$(_proj_list_all_cached)
    assert_contains "$output" "test-project" || return 1

    return 0
}

test_cached_list_regenerates_stale() {
    # Create stale cache
    local old_time=$(($(date +%s) - PROJ_CACHE_TTL - 10))
    {
        echo "# Generated: $old_time"
        echo "old-content|dev|🔧|/path|"
    } > "$PROJ_CACHE_FILE"

    # Enable cache
    FLOW_CACHE_ENABLED=1

    # Call cached list (should regenerate)
    local output=$(_proj_list_all_cached)

    # Cache should be fresh now
    assert_true "_proj_cache_is_valid" || return 1

    return 0
}

test_cache_disabled_skips_cache() {
    rm -f "$PROJ_CACHE_FILE"

    # Disable cache
    FLOW_CACHE_ENABLED=0

    # Call cached list
    local output=$(_proj_list_all_cached)

    # Cache should NOT be created
    assert_file_not_exists "$PROJ_CACHE_FILE" || return 1

    return 0
}

test_format_duration() {
    local result

    # Test seconds only
    result=$(_proj_format_duration 45)
    assert_equals "45s" "$result" || return 1

    # Test minutes and seconds
    result=$(_proj_format_duration 125)
    assert_equals "2m 5s" "$result" || return 1

    # Test exact minute
    result=$(_proj_format_duration 120)
    assert_equals "2m 0s" "$result" || return 1

    return 0
}

test_flow_cache_refresh() {
    rm -f "$PROJ_CACHE_FILE"

    # Run refresh command
    local output=$(flow-cache-refresh 2>&1)

    # Should report success
    assert_contains "$output" "✅ Cache refreshed" || return 1

    # Cache should exist and be valid
    assert_file_exists "$PROJ_CACHE_FILE" || return 1
    assert_true "_proj_cache_is_valid" || return 1

    return 0
}

test_flow_cache_clear() {
    rm -f "$PROJ_CACHE_FILE"

    # Generate cache
    _proj_cache_generate || return 1
    assert_file_exists "$PROJ_CACHE_FILE" || return 1

    # Run clear command
    local output=$(flow-cache-clear 2>&1)

    # Should report success
    assert_contains "$output" "✅ Cache cleared" || return 1

    # Cache should be deleted
    assert_file_not_exists "$PROJ_CACHE_FILE" || return 1

    return 0
}

test_flow_cache_status() {
    rm -f "$PROJ_CACHE_FILE"

    # Generate cache
    _proj_cache_generate || return 1

    # Run status command
    local output=$(flow-cache-status 2>&1)

    # Should show stats
    assert_contains "$output" "Cache status:" || return 1
    assert_contains "$output" "Valid" || return 1

    return 0
}

# ============================================================================
# TEST RUNNER
# ============================================================================

main() {
    echo -e "${C_CYAN}╔══════════════════════════════════════════════════════════════╗${C_NC}"
    echo -e "${C_CYAN}║  flow-cli Project Cache Test Suite                         ║${C_NC}"
    echo -e "${C_CYAN}╚══════════════════════════════════════════════════════════════╝${C_NC}"
    echo ""

    # Setup
    setup_test_projects

    # Core cache functionality
    run_test "Cache generation creates file with timestamp" test_cache_generation
    run_test "Fresh cache is valid" test_cache_validity_fresh
    run_test "Stale cache is invalid" test_cache_validity_stale
    run_test "Missing cache is invalid" test_cache_validity_missing
    run_test "Corrupt cache is invalid" test_cache_validity_corrupt
    run_test "Cache invalidation deletes file" test_cache_invalidation

    # Cache stats
    run_test "Stats show valid cache info" test_cache_stats_valid
    run_test "Stats report missing cache" test_cache_stats_missing
    run_test "Stats detect stale cache" test_cache_stats_stale

    # Cached list access
    run_test "Cached list auto-generates on missing cache" test_cached_list_generates_on_missing
    run_test "Cached list uses valid cache" test_cached_list_uses_valid_cache
    run_test "Cached list regenerates stale cache" test_cached_list_regenerates_stale
    run_test "Cache disabled skips caching" test_cache_disabled_skips_cache

    # Helper functions
    run_test "Format duration works correctly" test_format_duration

    # User commands
    run_test "flow cache refresh works" test_flow_cache_refresh
    run_test "flow cache clear works" test_flow_cache_clear
    run_test "flow cache status works" test_flow_cache_status

    # Cleanup
    cleanup_test_projects

    # Summary
    echo ""
    echo -e "${C_CYAN}╔══════════════════════════════════════════════════════════════╗${C_NC}"
    echo -e "${C_CYAN}║  Test Results                                               ║${C_NC}"
    echo -e "${C_CYAN}╚══════════════════════════════════════════════════════════════╝${C_NC}"
    echo ""
    echo -e "  Total:  $TEST_TOTAL"
    echo -e "  ${C_GREEN}Passed: $TEST_PASSED${C_NC}"
    echo -e "  ${C_RED}Failed: $TEST_FAILED${C_NC}"
    echo ""

    if (( TEST_FAILED == 0 )); then
        echo -e "${C_GREEN}✓ All tests passed!${C_NC}"
        return 0
    else
        echo -e "${C_RED}✗ Some tests failed${C_NC}"
        return 1
    fi
}

# Run tests
main "$@"
