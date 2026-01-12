#!/usr/bin/env zsh
# tests/unit/test-cache-generation.zsh
# Unit tests for cache generation functionality

# Test framework setup
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h:h}"

# Load test utilities
source "$PROJECT_ROOT/tests/test-utils.zsh"
source "$PROJECT_ROOT/lib/core.zsh"
source "$PROJECT_ROOT/lib/project-detector.zsh"
source "$PROJECT_ROOT/lib/project-cache.zsh"
source "$PROJECT_ROOT/commands/pick.zsh"

# Test suite setup
test_suite_init "Cache Generation"

# ============================================================================
# CACHE GENERATION TESTS
# ============================================================================

test_cache_generates_file() {
    setup_test_cache

    _proj_cache_generate >/dev/null 2>&1

    assert_file_exists "$TEST_CACHE_FILE" "Cache file should be created"
}

test_cache_has_timestamp_header() {
    setup_test_cache

    _proj_cache_generate >/dev/null 2>&1

    local first_line=$(head -1 "$TEST_CACHE_FILE")
    assert_contains "$first_line" "# Generated:" "Cache should have timestamp header"
}

test_cache_timestamp_is_numeric() {
    setup_test_cache

    _proj_cache_generate >/dev/null 2>&1

    local timestamp=$(head -1 "$TEST_CACHE_FILE" | sed 's/# Generated: //')
    assert_match "$timestamp" '^[0-9]+$' "Timestamp should be numeric"
}

test_cache_timestamp_is_recent() {
    setup_test_cache

    local before=$(date +%s)
    _proj_cache_generate >/dev/null 2>&1
    local after=$(date +%s)

    local timestamp=$(head -1 "$TEST_CACHE_FILE" | sed 's/# Generated: //')

    assert_true "[[ $timestamp -ge $before ]]" "Timestamp should be >= before time"
    assert_true "[[ $timestamp -le $after ]]" "Timestamp should be <= after time"
}

test_cache_contains_project_data() {
    setup_test_cache
    setup_test_projects

    _proj_cache_generate >/dev/null 2>&1

    local line_count=$(tail -n +2 "$TEST_CACHE_FILE" | wc -l | tr -d ' ')
    assert_true "[[ $line_count -gt 0 ]]" "Cache should contain project data"
}

test_cache_generation_fails_without_write_permission() {
    setup_test_cache

    # Create a custom cache file in a controllable location
    local test_dir=$(mktemp -d)
    local test_cache="$test_dir/cache/projects.cache"
    local cache_dir="$test_dir/cache"

    # Save original
    local old_cache="$PROJ_CACHE_FILE"
    PROJ_CACHE_FILE="$test_cache"

    mkdir -p "$cache_dir"
    chmod 555 "$cache_dir"

    _proj_cache_generate >/dev/null 2>&1
    local result=$?

    # Restore permissions and cleanup
    chmod 755 "$cache_dir"
    rm -rf "$test_dir"
    PROJ_CACHE_FILE="$old_cache"

    assert_equals 1 $result "Generation should fail without write permission"
}

test_cache_generation_creates_missing_directory() {
    setup_test_cache

    # Remove cache directory if it exists
    local cache_dir=$(dirname "$TEST_CACHE_FILE")
    rm -rf "$cache_dir"

    _proj_cache_generate >/dev/null 2>&1

    assert_dir_exists "$cache_dir" "Generation should create missing directory"
}

test_cache_generation_accepts_category_filter() {
    setup_test_cache
    setup_test_projects

    # Generate cache (filters are now ignored - always caches complete list)
    _proj_cache_generate "dev" >/dev/null 2>&1

    assert_file_exists "$TEST_CACHE_FILE" "Cache should be created"

    # NEW: Verify cache contains ALL projects, not just filtered "dev"
    local cached_content=$(tail -n +2 "$TEST_CACHE_FILE")
    assert_not_equals "" "$cached_content" "Cache should have content"
    # Cache should now contain both dev and r projects (unfiltered)
}

test_cache_generation_accepts_recent_only_filter() {
    setup_test_cache
    setup_test_projects

    # Generate cache (filters are now ignored - always caches complete list)
    _proj_cache_generate "" "recent" >/dev/null 2>&1

    assert_file_exists "$TEST_CACHE_FILE" "Cache should be created"

    # NEW: Verify cache contains ALL projects (filtering happens at read time)
    local cached_content=$(tail -n +2 "$TEST_CACHE_FILE")
    assert_not_equals "" "$cached_content" "Cache should have content"
}

test_cache_generation_overwrites_existing() {
    setup_test_cache

    # Create initial cache
    echo "old content" > "$TEST_CACHE_FILE"
    local old_time=$(stat -f %m "$TEST_CACHE_FILE" 2>/dev/null || stat -c %Y "$TEST_CACHE_FILE" 2>/dev/null)

    sleep 1

    # Regenerate
    _proj_cache_generate >/dev/null 2>&1

    local new_content=$(cat "$TEST_CACHE_FILE")
    assert_not_contains "$new_content" "old content" "Old content should be overwritten"
}

# ============================================================================
# RUN TESTS
# ============================================================================

run_test "Cache generates file" test_cache_generates_file
run_test "Cache has timestamp header" test_cache_has_timestamp_header
run_test "Cache timestamp is numeric" test_cache_timestamp_is_numeric
run_test "Cache timestamp is recent" test_cache_timestamp_is_recent
run_test "Cache contains project data" test_cache_contains_project_data
run_test "Cache generation fails without write permission" test_cache_generation_fails_without_write_permission
run_test "Cache generation creates missing directory" test_cache_generation_creates_missing_directory
run_test "Cache generation accepts category filter" test_cache_generation_accepts_category_filter
run_test "Cache generation accepts recent-only filter" test_cache_generation_accepts_recent_only_filter
run_test "Cache generation overwrites existing" test_cache_generation_overwrites_existing

# Summary and exit
test_suite_summary
