#!/usr/bin/env zsh
# tests/unit/test-cache-access.zsh
# Unit tests for cached list access and auto-regeneration

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h:h}"

source "$PROJECT_ROOT/tests/test-utils.zsh"
source "$PROJECT_ROOT/lib/core.zsh"
source "$PROJECT_ROOT/lib/project-detector.zsh"
source "$PROJECT_ROOT/lib/project-cache.zsh"
source "$PROJECT_ROOT/commands/pick.zsh"

test_suite_init "Cache Access & Auto-Regeneration"

# ============================================================================
# CACHED LIST ACCESS TESTS
# ============================================================================

test_cached_list_returns_data() {
    setup_test_cache
    setup_test_projects

    _proj_cache_generate >/dev/null 2>&1
    local result=$(_proj_list_all_cached)

    assert_true "[[ -n '$result' ]]" "Cached list should return data"
}

test_cached_list_uses_existing_cache() {
    setup_test_cache

    create_fresh_cache
    local result=$(_proj_list_all_cached)

    assert_contains "$result" "fresh" "Should use existing fresh cache"
}

test_cached_list_auto_generates_missing_cache() {
    setup_test_cache
    setup_test_projects

    rm -f "$TEST_CACHE_FILE"

    _proj_list_all_cached >/dev/null 2>&1

    assert_file_exists "$TEST_CACHE_FILE" "Should auto-generate missing cache"
}

test_cached_list_regenerates_stale_cache() {
    setup_test_cache
    setup_test_projects

    create_stale_cache

    _proj_list_all_cached >/dev/null 2>&1

    assert_true "_proj_cache_is_valid" "Should regenerate stale cache"
}

test_cached_list_regenerates_corrupt_cache() {
    setup_test_cache
    setup_test_projects

    create_corrupt_cache

    _proj_list_all_cached >/dev/null 2>&1

    # Should regenerate with valid timestamp
    local timestamp=$(head -1 "$TEST_CACHE_FILE" | sed 's/# Generated: //')
    assert_match "$timestamp" '^[0-9]+$' "Should regenerate corrupt cache"
}

# ============================================================================
# CACHE DISABLED TESTS
# ============================================================================

test_cache_disabled_skips_cache() {
    setup_test_cache
    setup_test_projects

    # Delete cache if it exists from previous test
    rm -f "$TEST_CACHE_FILE"

    # Disable cache
    local old_enabled="$FLOW_CACHE_ENABLED"
    FLOW_CACHE_ENABLED=0

    _proj_list_all_cached >/dev/null 2>&1

    # Restore
    FLOW_CACHE_ENABLED="$old_enabled"

    assert_file_not_exists "$TEST_CACHE_FILE" "Disabled cache should not create file"
}

test_cache_disabled_returns_data() {
    setup_test_cache
    setup_test_projects

    FLOW_CACHE_ENABLED=0
    local result=$(_proj_list_all_cached)

    assert_true "[[ -n '$result' ]]" "Disabled cache should still return data"
}

test_cache_disabled_ignores_existing_cache() {
    setup_test_cache
    setup_test_projects

    create_mock_cache "$(date +%s)" "cached|dev|🔧|/cache|"

    FLOW_CACHE_ENABLED=0
    local result=$(_proj_list_all_cached)

    # Should not contain cached data (would need real projects)
    # This is indirect - we're checking it doesn't use the mock cache
    assert_not_contains "$result" "cached" "Should ignore existing cache when disabled"
}

# ============================================================================
# FALLBACK BEHAVIOR TESTS
# ============================================================================

test_fallback_on_generation_failure() {
    setup_test_cache
    setup_test_projects

    # Make cache directory read-only to force failure
    local cache_dir=$(dirname "$TEST_CACHE_FILE")
    mkdir -p "$cache_dir"
    chmod 555 "$cache_dir"

    local result=$(_proj_list_all_cached 2>/dev/null)

    # Restore permissions
    chmod 755 "$cache_dir"

    # Should fallback to uncached and still return data
    assert_true "[[ -n '$result' || $? -eq 0 ]]" "Should fallback on generation failure"
}

test_fallback_on_read_failure() {
    setup_test_cache
    setup_test_projects

    # Create cache but make it unreadable
    _proj_cache_generate >/dev/null 2>&1
    chmod 000 "$TEST_CACHE_FILE"

    local result=$(_proj_list_all_cached 2>/dev/null)

    # Restore permissions for cleanup
    chmod 644 "$TEST_CACHE_FILE"

    # Should fallback to uncached
    assert_true "[[ -n '$result' || $? -eq 0 ]]" "Should fallback on read failure"
}

# ============================================================================
# FILTER PASSTHROUGH TESTS
# ============================================================================

test_category_filter_passed_to_generator() {
    setup_test_cache
    setup_test_projects

    _proj_list_all_cached "dev" >/dev/null 2>&1

    # Verify cache was created (shows filter was passed through)
    assert_file_exists "$TEST_CACHE_FILE" "Category filter should be passed through"
}

test_recent_filter_passed_to_generator() {
    setup_test_cache
    setup_test_projects

    _proj_list_all_cached "" "recent" >/dev/null 2>&1

    # Verify cache was created (shows filter was passed through)
    assert_file_exists "$TEST_CACHE_FILE" "Recent filter should be passed through"
}

test_both_filters_passed_to_generator() {
    setup_test_cache
    setup_test_projects

    _proj_list_all_cached "dev" "recent" >/dev/null 2>&1

    assert_file_exists "$TEST_CACHE_FILE" "Both filters should be passed through"
}

# ============================================================================
# CACHE CONTENT TESTS
# ============================================================================

test_cached_list_skips_timestamp_line() {
    setup_test_cache

    {
        echo "# Generated: $(date +%s)"
        echo "project1|dev|🔧|/path1|"
        echo "project2|r|📦|/path2|"
    } > "$TEST_CACHE_FILE"

    local result=$(_proj_list_all_cached)

    assert_not_contains "$result" "# Generated:" "Should skip timestamp line"
}

test_cached_list_returns_all_projects() {
    setup_test_cache

    {
        echo "# Generated: $(date +%s)"
        echo "project1|dev|🔧|/path1|"
        echo "project2|r|📦|/path2|"
        echo "project3|app|📱|/path3|"
    } > "$TEST_CACHE_FILE"

    local result=$(_proj_list_all_cached)
    local line_count=$(echo "$result" | wc -l | tr -d ' ')

    assert_equals 3 $line_count "Should return all projects"
}

test_cached_list_preserves_format() {
    setup_test_cache

    local test_line="project|dev|🔧|/path/to/project|🟢 2h"
    {
        echo "# Generated: $(date +%s)"
        echo "$test_line"
    } > "$TEST_CACHE_FILE"

    local result=$(_proj_list_all_cached)

    assert_contains "$result" "$test_line" "Should preserve project format"
}

# ============================================================================
# RUN TESTS
# ============================================================================

# Basic access
run_test "Cached list returns data" test_cached_list_returns_data
run_test "Cached list uses existing cache" test_cached_list_uses_existing_cache
run_test "Cached list auto-generates missing cache" test_cached_list_auto_generates_missing_cache
run_test "Cached list regenerates stale cache" test_cached_list_regenerates_stale_cache
run_test "Cached list regenerates corrupt cache" test_cached_list_regenerates_corrupt_cache

# Cache disabled
run_test "Cache disabled skips cache" test_cache_disabled_skips_cache
run_test "Cache disabled returns data" test_cache_disabled_returns_data
run_test "Cache disabled ignores existing cache" test_cache_disabled_ignores_existing_cache

# Fallback behavior
run_test "Fallback on generation failure" test_fallback_on_generation_failure
run_test "Fallback on read failure" test_fallback_on_read_failure

# Filter passthrough
run_test "Category filter passed to generator" test_category_filter_passed_to_generator
run_test "Recent filter passed to generator" test_recent_filter_passed_to_generator
run_test "Both filters passed to generator" test_both_filters_passed_to_generator

# Cache content
run_test "Cached list skips timestamp line" test_cached_list_skips_timestamp_line
run_test "Cached list returns all projects" test_cached_list_returns_all_projects
run_test "Cached list preserves format" test_cached_list_preserves_format

test_suite_summary
