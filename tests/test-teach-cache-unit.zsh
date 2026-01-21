#!/usr/bin/env zsh
# tests/test-teach-cache-unit.zsh - Unit tests for teach cache management
# Tests: cache status, clearing, rebuilding, analysis, clean command

# ============================================================================
# SETUP
# ============================================================================

# Get script directory
TEST_DIR="${0:A:h}"
FLOW_PLUGIN_DIR="${TEST_DIR:h}"

# Source the plugin
source "$FLOW_PLUGIN_DIR/flow.plugin.zsh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors
C_GREEN='\033[38;5;114m'
C_RED='\033[38;5;203m'
C_YELLOW='\033[38;5;221m'
C_BLUE='\033[38;5;117m'
C_RESET='\033[0m'

# ============================================================================
# TEST HELPERS
# ============================================================================

assert_equal() {
    local expected="$1"
    local actual="$2"
    local message="$3"

    ((TESTS_RUN++))

    if [[ "$actual" == "$expected" ]]; then
        ((TESTS_PASSED++))
        echo "${C_GREEN}✓${C_RESET} $message"
        return 0
    else
        ((TESTS_FAILED++))
        echo "${C_RED}✗${C_RESET} $message"
        echo "  Expected: $expected"
        echo "  Got:      $actual"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"

    ((TESTS_RUN++))

    if [[ "$haystack" == *"$needle"* ]]; then
        ((TESTS_PASSED++))
        echo "${C_GREEN}✓${C_RESET} $message"
        return 0
    else
        ((TESTS_FAILED++))
        echo "${C_RED}✗${C_RESET} $message"
        echo "  Expected to contain: $needle"
        echo "  Got:                 $haystack"
        return 1
    fi
}

assert_file_exists() {
    local filepath="$1"
    local message="$2"

    ((TESTS_RUN++))

    if [[ -f "$filepath" ]]; then
        ((TESTS_PASSED++))
        echo "${C_GREEN}✓${C_RESET} $message"
        return 0
    else
        ((TESTS_FAILED++))
        echo "${C_RED}✗${C_RESET} $message"
        echo "  File not found: $filepath"
        return 1
    fi
}

assert_dir_exists() {
    local dirpath="$1"
    local message="$2"

    ((TESTS_RUN++))

    if [[ -d "$dirpath" ]]; then
        ((TESTS_PASSED++))
        echo "${C_GREEN}✓${C_RESET} $message"
        return 0
    else
        ((TESTS_FAILED++))
        echo "${C_RED}✗${C_RESET} $message"
        echo "  Directory not found: $dirpath"
        return 1
    fi
}

assert_dir_not_exists() {
    local dirpath="$1"
    local message="$2"

    ((TESTS_RUN++))

    if [[ ! -d "$dirpath" ]]; then
        ((TESTS_PASSED++))
        echo "${C_GREEN}✓${C_RESET} $message"
        return 0
    else
        ((TESTS_FAILED++))
        echo "${C_RED}✗${C_RESET} $message"
        echo "  Directory should not exist: $dirpath"
        return 1
    fi
}

# ============================================================================
# MOCK ENVIRONMENT
# ============================================================================

setup_mock_project() {
    local test_dir="$1"

    # Create project structure
    mkdir -p "$test_dir"
    cd "$test_dir"

    # Create _quarto.yml
    cat > _quarto.yml <<'EOF'
project:
  type: website
  output-dir: _site

execute:
  freeze: auto
EOF

    # Create mock freeze cache
    mkdir -p _freeze/lectures/week1
    mkdir -p _freeze/lectures/week2
    mkdir -p _freeze/assignments/hw1

    # Create mock cache files
    echo "cache data 1" > _freeze/lectures/week1/cache.json
    echo "cache data 2" > _freeze/lectures/week2/cache.json
    echo "cache data 3" > _freeze/assignments/hw1/cache.json

    # Create additional files for size testing
    for i in {1..10}; do
        echo "Additional cache file $i" > "_freeze/lectures/week1/file$i.json"
    done

    # Create _site directory
    mkdir -p _site
    echo "<html>output</html>" > _site/index.html
}

cleanup_mock_project() {
    local test_dir="$1"
    rm -rf "$test_dir"
}

# ============================================================================
# TEST SUITE 1: Cache Status
# ============================================================================

test_cache_status_no_cache() {
    echo ""
    echo "${C_BLUE}TEST SUITE: Cache Status - No Cache${C_RESET}"
    echo ""

    local test_dir="/tmp/flow-test-cache-no-cache-$$"
    mkdir -p "$test_dir"
    cd "$test_dir"

    # Create minimal project (no _freeze/)
    echo "project: test" > _quarto.yml

    # Get status
    local status_output=$(_cache_status "$test_dir")
    eval "$status_output"

    # Assertions
    assert_equal "none" "$cache_status" "Status should be 'none'"
    assert_equal "0" "$file_count" "File count should be 0"
    assert_equal "never" "$last_render" "Last render should be 'never'"

    cleanup_mock_project "$test_dir"
}

test_cache_status_with_cache() {
    echo ""
    echo "${C_BLUE}TEST SUITE: Cache Status - With Cache${C_RESET}"
    echo ""

    local test_dir="/tmp/flow-test-cache-with-cache-$$"
    setup_mock_project "$test_dir"

    # Get status
    local status_output=$(_cache_status "$test_dir")
    eval "$status_output"

    # Assertions
    assert_equal "exists" "$cache_status" "Status should be 'exists'"
    assert_contains "$file_count" "13" "File count should be 13" # 3 + 10 files

    cleanup_mock_project "$test_dir"
}

# ============================================================================
# TEST SUITE 2: Cache Clearing
# ============================================================================

test_cache_clear_with_force() {
    echo ""
    echo "${C_BLUE}TEST SUITE: Cache Clearing - Force Mode${C_RESET}"
    echo ""

    local test_dir="/tmp/flow-test-cache-clear-$$"
    setup_mock_project "$test_dir"

    # Verify cache exists
    assert_dir_exists "$test_dir/_freeze" "Cache directory should exist before clear"

    # Clear cache with --force
    _cache_clear "$test_dir" --force >/dev/null 2>&1

    # Verify cache deleted
    assert_dir_not_exists "$test_dir/_freeze" "Cache directory should be deleted"

    cleanup_mock_project "$test_dir"
}

test_cache_clear_no_cache() {
    echo ""
    echo "${C_BLUE}TEST SUITE: Cache Clearing - No Cache${C_RESET}"
    echo ""

    local test_dir="/tmp/flow-test-cache-clear-none-$$"
    mkdir -p "$test_dir"
    cd "$test_dir"
    echo "project: test" > _quarto.yml

    # Try to clear (should warn)
    local output=$(_cache_clear "$test_dir" --force 2>&1)

    assert_contains "$output" "No freeze cache found" "Should warn when no cache exists"

    cleanup_mock_project "$test_dir"
}

# ============================================================================
# TEST SUITE 3: Cache Analysis
# ============================================================================

test_cache_analyze_structure() {
    echo ""
    echo "${C_BLUE}TEST SUITE: Cache Analysis${C_RESET}"
    echo ""

    local test_dir="/tmp/flow-test-cache-analyze-$$"
    setup_mock_project "$test_dir"

    # Run analysis
    local output=$(_cache_analyze "$test_dir" 2>&1)

    # Check for expected sections
    assert_contains "$output" "Freeze Cache Analysis" "Should show analysis header"
    assert_contains "$output" "Overall:" "Should show overall section"
    assert_contains "$output" "By Content Directory:" "Should show directory breakdown"
    assert_contains "$output" "By Age:" "Should show age breakdown"

    # Check for subdirectories
    assert_contains "$output" "lectures" "Should list lectures directory"
    assert_contains "$output" "assignments" "Should list assignments directory"

    cleanup_mock_project "$test_dir"
}

# ============================================================================
# TEST SUITE 4: Clean Command
# ============================================================================

test_clean_both_directories() {
    echo ""
    echo "${C_BLUE}TEST SUITE: Clean Command - Both Directories${C_RESET}"
    echo ""

    local test_dir="/tmp/flow-test-clean-$$"
    setup_mock_project "$test_dir"

    # Verify both exist
    assert_dir_exists "$test_dir/_freeze" "_freeze should exist before clean"
    assert_dir_exists "$test_dir/_site" "_site should exist before clean"

    # Clean with --force
    _cache_clean "$test_dir" --force >/dev/null 2>&1

    # Verify both deleted
    assert_dir_not_exists "$test_dir/_freeze" "_freeze should be deleted"
    assert_dir_not_exists "$test_dir/_site" "_site should be deleted"

    cleanup_mock_project "$test_dir"
}

test_clean_only_freeze() {
    echo ""
    echo "${C_BLUE}TEST SUITE: Clean Command - Only Freeze${C_RESET}"
    echo ""

    local test_dir="/tmp/flow-test-clean-freeze-$$"
    mkdir -p "$test_dir/_freeze"
    cd "$test_dir"
    echo "project: test" > _quarto.yml

    # No _site directory

    # Clean with --force
    _cache_clean "$test_dir" --force >/dev/null 2>&1

    # Verify _freeze deleted
    assert_dir_not_exists "$test_dir/_freeze" "_freeze should be deleted"

    cleanup_mock_project "$test_dir"
}

test_clean_nothing_to_clean() {
    echo ""
    echo "${C_BLUE}TEST SUITE: Clean Command - Nothing to Clean${C_RESET}"
    echo ""

    local test_dir="/tmp/flow-test-clean-nothing-$$"
    mkdir -p "$test_dir"
    cd "$test_dir"
    echo "project: test" > _quarto.yml

    # No _freeze or _site

    # Try to clean (should warn)
    local output=$(_cache_clean "$test_dir" --force 2>&1)

    assert_contains "$output" "Nothing to clean" "Should warn when nothing to clean"

    cleanup_mock_project "$test_dir"
}

# ============================================================================
# TEST SUITE 5: Helper Functions
# ============================================================================

test_format_time_ago() {
    echo ""
    echo "${C_BLUE}TEST SUITE: Time Formatting${C_RESET}"
    echo ""

    local now=$(date +%s)

    # Just now
    local result=$(_cache_format_time_ago $now)
    assert_equal "just now" "$result" "Should format recent time as 'just now'"

    # Minutes ago
    local mins_ago=$((now - 120))
    result=$(_cache_format_time_ago $mins_ago)
    assert_equal "2 minutes ago" "$result" "Should format minutes correctly"

    # Hours ago
    local hours_ago=$((now - 7200))
    result=$(_cache_format_time_ago $hours_ago)
    assert_equal "2 hours ago" "$result" "Should format hours correctly"

    # Days ago
    local days_ago=$((now - 172800))
    result=$(_cache_format_time_ago $days_ago)
    assert_equal "2 days ago" "$result" "Should format days correctly"
}

test_format_bytes() {
    echo ""
    echo "${C_BLUE}TEST SUITE: Byte Formatting${C_RESET}"
    echo ""

    assert_equal "512B" "$(_cache_format_bytes 512)" "Should format bytes"
    assert_equal "2KB" "$(_cache_format_bytes 2048)" "Should format KB"
    assert_equal "5MB" "$(_cache_format_bytes 5242880)" "Should format MB"
    assert_equal "1GB" "$(_cache_format_bytes 1073741824)" "Should format GB"
}

# ============================================================================
# TEST SUITE 6: Integration Tests
# ============================================================================

test_teach_cache_command_integration() {
    echo ""
    echo "${C_BLUE}TEST SUITE: teach cache Integration${C_RESET}"
    echo ""

    local test_dir="/tmp/flow-test-integration-$$"
    setup_mock_project "$test_dir"

    # Test status command
    local status_output=$(teach_cache_status 2>&1)
    assert_contains "$status_output" "Freeze Cache Status" "teach cache status should work"

    # Test clear command (with --force)
    teach_cache_clear --force >/dev/null 2>&1
    assert_dir_not_exists "$test_dir/_freeze" "teach cache clear should delete cache"

    cleanup_mock_project "$test_dir"
}

test_teach_clean_command_integration() {
    echo ""
    echo "${C_BLUE}TEST SUITE: teach clean Integration${C_RESET}"
    echo ""

    local test_dir="/tmp/flow-test-clean-integration-$$"
    setup_mock_project "$test_dir"

    # Test clean command (with --force)
    teach_clean --force >/dev/null 2>&1

    assert_dir_not_exists "$test_dir/_freeze" "teach clean should delete _freeze"
    assert_dir_not_exists "$test_dir/_site" "teach clean should delete _site"

    cleanup_mock_project "$test_dir"
}

# ============================================================================
# RUN ALL TESTS
# ============================================================================

run_all_tests() {
    echo ""
    echo "${C_BLUE}═══════════════════════════════════════════════════════════${C_RESET}"
    echo "${C_BLUE}  TEACH CACHE MANAGEMENT - UNIT TESTS${C_RESET}"
    echo "${C_BLUE}═══════════════════════════════════════════════════════════${C_RESET}"

    # Suite 1: Cache Status
    test_cache_status_no_cache
    test_cache_status_with_cache

    # Suite 2: Cache Clearing
    test_cache_clear_with_force
    test_cache_clear_no_cache

    # Suite 3: Cache Analysis
    test_cache_analyze_structure

    # Suite 4: Clean Command
    test_clean_both_directories
    test_clean_only_freeze
    test_clean_nothing_to_clean

    # Suite 5: Helper Functions
    test_format_time_ago
    test_format_bytes

    # Suite 6: Integration Tests
    test_teach_cache_command_integration
    test_teach_clean_command_integration

    # Summary
    echo ""
    echo "${C_BLUE}═══════════════════════════════════════════════════════════${C_RESET}"
    echo "${C_BLUE}  TEST SUMMARY${C_RESET}"
    echo "${C_BLUE}═══════════════════════════════════════════════════════════${C_RESET}"
    echo ""
    echo "  Total tests:  $TESTS_RUN"
    echo "  ${C_GREEN}Passed:       $TESTS_PASSED${C_RESET}"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo "  ${C_RED}Failed:       $TESTS_FAILED${C_RESET}"
        echo ""
        echo "${C_RED}TESTS FAILED${C_RESET}"
        return 1
    else
        echo ""
        echo "${C_GREEN}ALL TESTS PASSED ✓${C_RESET}"
        return 0
    fi
}

# Run tests
run_all_tests
exit $?
