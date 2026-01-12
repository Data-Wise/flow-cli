#!/usr/bin/env zsh
# tests/unit/test-cache-validation.zsh
# Unit tests for cache validation and TTL logic

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h:h}"

source "$PROJECT_ROOT/tests/test-utils.zsh"
source "$PROJECT_ROOT/lib/core.zsh"
source "$PROJECT_ROOT/lib/project-detector.zsh"
source "$PROJECT_ROOT/lib/project-cache.zsh"
source "$PROJECT_ROOT/commands/pick.zsh"

test_suite_init "Cache Validation"

# ============================================================================
# VALIDITY TESTS - FRESH CACHE
# ============================================================================

test_fresh_cache_is_valid() {
    setup_test_cache

    _proj_cache_generate >/dev/null 2>&1

    assert_true "_proj_cache_is_valid" "Fresh cache should be valid"
}

test_just_created_cache_is_valid() {
    setup_test_cache

    echo "# Generated: $(date +%s)" > "$TEST_CACHE_FILE"
    echo "test|dev|🔧|/path|" >> "$TEST_CACHE_FILE"

    assert_true "_proj_cache_is_valid" "Just created cache should be valid"
}

# ============================================================================
# VALIDITY TESTS - STALE CACHE
# ============================================================================

test_stale_cache_is_invalid() {
    setup_test_cache

    # Create cache older than TTL
    local old_time=$(($(date +%s) - PROJ_CACHE_TTL - 10))
    echo "# Generated: $old_time" > "$TEST_CACHE_FILE"
    echo "test|dev|🔧|/path|" >> "$TEST_CACHE_FILE"

    assert_false "_proj_cache_is_valid" "Stale cache should be invalid"
}

test_cache_at_ttl_boundary_is_invalid() {
    setup_test_cache

    # Create cache exactly at TTL age
    local boundary_time=$(($(date +%s) - PROJ_CACHE_TTL))
    echo "# Generated: $boundary_time" > "$TEST_CACHE_FILE"
    echo "test|dev|🔧|/path|" >> "$TEST_CACHE_FILE"

    assert_false "_proj_cache_is_valid" "Cache at TTL boundary should be invalid"
}

test_cache_just_under_ttl_is_valid() {
    setup_test_cache

    # Create cache just under TTL (1 second before expiry)
    local almost_stale=$(($(date +%s) - PROJ_CACHE_TTL + 1))
    echo "# Generated: $almost_stale" > "$TEST_CACHE_FILE"
    echo "test|dev|🔧|/path|" >> "$TEST_CACHE_FILE"

    assert_true "_proj_cache_is_valid" "Cache just under TTL should be valid"
}

# ============================================================================
# VALIDITY TESTS - MISSING/CORRUPT
# ============================================================================

test_missing_cache_is_invalid() {
    setup_test_cache

    rm -f "$TEST_CACHE_FILE"

    assert_false "_proj_cache_is_valid" "Missing cache should be invalid"
}

test_empty_cache_is_invalid() {
    setup_test_cache

    touch "$TEST_CACHE_FILE"

    assert_false "_proj_cache_is_valid" "Empty cache should be invalid"
}

test_cache_without_timestamp_is_invalid() {
    setup_test_cache

    echo "test|dev|🔧|/path|" > "$TEST_CACHE_FILE"

    assert_false "_proj_cache_is_valid" "Cache without timestamp should be invalid"
}

test_cache_with_invalid_timestamp_is_invalid() {
    setup_test_cache

    echo "# Generated: not-a-number" > "$TEST_CACHE_FILE"
    echo "test|dev|🔧|/path|" >> "$TEST_CACHE_FILE"

    assert_false "_proj_cache_is_valid" "Cache with invalid timestamp should be invalid"
}

test_cache_with_negative_timestamp_is_invalid() {
    setup_test_cache

    echo "# Generated: -123" > "$TEST_CACHE_FILE"
    echo "test|dev|🔧|/path|" >> "$TEST_CACHE_FILE"

    assert_false "_proj_cache_is_valid" "Cache with negative timestamp should be invalid"
}

test_cache_with_future_timestamp_is_valid() {
    setup_test_cache

    # Future timestamp (shouldn't happen but handle gracefully)
    local future=$(($(date +%s) + 100))
    echo "# Generated: $future" > "$TEST_CACHE_FILE"
    echo "test|dev|🔧|/path|" >> "$TEST_CACHE_FILE"

    # Future timestamp gives negative age, which is < TTL, so valid
    assert_true "_proj_cache_is_valid" "Cache with future timestamp should be valid"
}

# ============================================================================
# TTL CONFIGURATION TESTS
# ============================================================================

test_custom_ttl_respected() {
    setup_test_cache

    # Set custom short TTL
    PROJ_CACHE_TTL=5

    # Create cache 10 seconds old (beyond custom TTL)
    local old_time=$(($(date +%s) - 10))
    echo "# Generated: $old_time" > "$TEST_CACHE_FILE"
    echo "test|dev|🔧|/path|" >> "$TEST_CACHE_FILE"

    assert_false "_proj_cache_is_valid" "Cache should respect custom TTL"

    # Restore default
    PROJ_CACHE_TTL=300
}

test_zero_ttl_makes_all_caches_invalid() {
    setup_test_cache

    PROJ_CACHE_TTL=0

    echo "# Generated: $(date +%s)" > "$TEST_CACHE_FILE"
    echo "test|dev|🔧|/path|" >> "$TEST_CACHE_FILE"

    assert_false "_proj_cache_is_valid" "With TTL=0, even fresh cache is invalid"

    # Restore default
    PROJ_CACHE_TTL=300
}

test_very_long_ttl_keeps_old_cache_valid() {
    setup_test_cache

    PROJ_CACHE_TTL=86400  # 1 day

    # Create cache 1 hour old
    local old_time=$(($(date +%s) - 3600))
    echo "# Generated: $old_time" > "$TEST_CACHE_FILE"
    echo "test|dev|🔧|/path|" >> "$TEST_CACHE_FILE"

    assert_true "_proj_cache_is_valid" "Long TTL should keep old cache valid"

    # Restore default
    PROJ_CACHE_TTL=300
}

# ============================================================================
# EDGE CASES
# ============================================================================

test_cache_with_extra_whitespace_in_timestamp() {
    setup_test_cache

    echo "#  Generated:   $(date +%s)  " > "$TEST_CACHE_FILE"
    echo "test|dev|🔧|/path|" >> "$TEST_CACHE_FILE"

    # Should handle extra whitespace gracefully (may be valid or invalid depending on sed behavior)
    # Main thing is it shouldn't crash
    _proj_cache_is_valid 2>/dev/null
    local result=$?

    # Either valid (0) or invalid (1) is acceptable - just shouldn't crash (return > 1)
    assert_true "[[ $result -le 1 ]]" "Should handle whitespace without crashing"
}

test_cache_with_multiline_content() {
    setup_test_cache

    {
        echo "# Generated: $(date +%s)"
        echo "project1|dev|🔧|/path1|"
        echo "project2|r|📦|/path2|"
        echo "project3|app|📱|/path3|"
    } > "$TEST_CACHE_FILE"

    assert_true "_proj_cache_is_valid" "Multiline cache should be valid"
}

# ============================================================================
# RUN TESTS
# ============================================================================

# Fresh cache
run_test "Fresh cache is valid" test_fresh_cache_is_valid
run_test "Just created cache is valid" test_just_created_cache_is_valid

# Stale cache
run_test "Stale cache is invalid" test_stale_cache_is_invalid
run_test "Cache at TTL boundary is invalid" test_cache_at_ttl_boundary_is_invalid
run_test "Cache just under TTL is valid" test_cache_just_under_ttl_is_valid

# Missing/corrupt
run_test "Missing cache is invalid" test_missing_cache_is_invalid
run_test "Empty cache is invalid" test_empty_cache_is_invalid
run_test "Cache without timestamp is invalid" test_cache_without_timestamp_is_invalid
run_test "Cache with invalid timestamp is invalid" test_cache_with_invalid_timestamp_is_invalid
run_test "Cache with negative timestamp is invalid" test_cache_with_negative_timestamp_is_invalid
run_test "Cache with future timestamp is valid" test_cache_with_future_timestamp_is_valid

# TTL configuration
run_test "Custom TTL respected" test_custom_ttl_respected
run_test "Zero TTL makes all caches invalid" test_zero_ttl_makes_all_caches_invalid
run_test "Very long TTL keeps old cache valid" test_very_long_ttl_keeps_old_cache_valid

# Edge cases
run_test "Cache with extra whitespace in timestamp" test_cache_with_extra_whitespace_in_timestamp
run_test "Cache with multiline content" test_cache_with_multiline_content

test_suite_summary
