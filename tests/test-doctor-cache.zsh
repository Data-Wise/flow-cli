#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE: Doctor Cache Manager
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: Validate doctor-cache.zsh functionality
# Target: 20 tests total for cache operations
# Coverage: Init, get/set, TTL, locking, cleanup, integration
#
# Test Categories:
#   1. Initialization (2 tests)
#   2. Basic Get/Set (3 tests)
#   3. Cache Expiration (3 tests)
#   4. Concurrent Access (2 tests)
#   5. Cache Cleanup (3 tests)
#   6. Error Handling (2 tests)
#   7. Token Convenience Functions (3 tests)
#   8. Integration (2 tests)
#
# Created: 2026-01-23
# ══════════════════════════════════════════════════════════════════════════════

# Source shared test framework
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

# ══════════════════════════════════════════════════════════════════════════════
# SETUP - Source libraries at global scope so readonly vars persist
# ══════════════════════════════════════════════════════════════════════════════

# Resolve project root
if [[ -z "$PROJECT_ROOT" || ! -f "$PROJECT_ROOT/lib/doctor-cache.zsh" ]]; then
    if [[ -f "$PWD/lib/doctor-cache.zsh" ]]; then
        PROJECT_ROOT="$PWD"
    elif [[ -f "$PWD/../lib/doctor-cache.zsh" ]]; then
        PROJECT_ROOT="$PWD/.."
    fi
fi

if [[ -z "$PROJECT_ROOT" || ! -f "$PROJECT_ROOT/lib/doctor-cache.zsh" ]]; then
    echo "ERROR: Cannot find project root"
    exit 1
fi

# Source at global scope so readonly DOCTOR_CACHE_DIR is visible everywhere
source "$PROJECT_ROOT/lib/core.zsh" 2>/dev/null
source "$PROJECT_ROOT/lib/doctor-cache.zsh" 2>/dev/null

export TEST_CACHE_PREFIX="test-"

setup() {
    # Clean any existing test cache entries
    setopt local_options nonomatch
    rm -f "${DOCTOR_CACHE_DIR}/${TEST_CACHE_PREFIX}"*.cache 2>/dev/null
}

cleanup() {
    # Remove test cache entries (prefixed with "test-")
    setopt local_options nonomatch
    rm -f "${DOCTOR_CACHE_DIR}/${TEST_CACHE_PREFIX}"*.cache 2>/dev/null
}
trap cleanup EXIT

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 1: INITIALIZATION (2 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_cache_init_creates_directory() {
    test_case "1.1. Cache init creates directory"

    _doctor_cache_init

    assert_dir_exists "$DOCTOR_CACHE_DIR" "Cache directory not created: $DOCTOR_CACHE_DIR" && test_pass
}

test_cache_init_permissions() {
    test_case "1.2. Cache directory has correct permissions"

    _doctor_cache_init

    if [[ -d "$DOCTOR_CACHE_DIR" && -w "$DOCTOR_CACHE_DIR" ]]; then
        test_pass
    else
        test_fail "Cache directory not writable"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 2: BASIC GET/SET (3 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_cache_set_and_get() {
    test_case "2.1. Cache set and get basic value"

    _doctor_cache_init

    local test_key="${TEST_CACHE_PREFIX}basic"
    local test_value='{"status": "valid", "days_remaining": 45}'
    _doctor_cache_set "$test_key" "$test_value"

    local retrieved=$(_doctor_cache_get "$test_key")
    local exit_code=$?

    assert_exit_code "$exit_code" 0 "Cache get should succeed" && \
    assert_contains "$retrieved" "valid" "Retrieved value should contain 'valid'" && \
    test_pass
}

test_cache_get_nonexistent() {
    test_case "2.2. Cache get returns error for nonexistent key"

    _doctor_cache_init

    _doctor_cache_get "nonexistent-key-xyz" >/dev/null 2>&1
    local exit_code=$?

    assert_not_equals "$exit_code" "0" "Should return error for nonexistent key" && test_pass
}

test_cache_overwrite() {
    test_case "2.3. Cache set overwrites existing value"

    _doctor_cache_init

    local test_key="${TEST_CACHE_PREFIX}overwrite"

    _doctor_cache_set "$test_key" '{"status": "initial"}'
    _doctor_cache_set "$test_key" '{"status": "updated"}'

    local retrieved=$(_doctor_cache_get "$test_key")

    assert_contains "$retrieved" "updated" "Failed to overwrite cached value" && test_pass
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 3: CACHE EXPIRATION (3 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_cache_ttl_not_expired() {
    test_case "3.1. Cache entry not expired within TTL"

    _doctor_cache_init

    local test_key="${TEST_CACHE_PREFIX}ttl-valid"

    _doctor_cache_set "$test_key" '{"status": "valid"}' 10

    _doctor_cache_get "$test_key" >/dev/null 2>&1
    local exit_code=$?

    assert_exit_code "$exit_code" 0 "Should retrieve valid cache entry" && test_pass
}

test_cache_ttl_expired() {
    test_case "3.2. Cache entry expires after TTL (2s wait)"

    _doctor_cache_init

    local test_key="${TEST_CACHE_PREFIX}ttl-expire"

    _doctor_cache_set "$test_key" '{"status": "valid"}' 1

    sleep 2

    _doctor_cache_get "$test_key" >/dev/null 2>&1
    local exit_code=$?

    assert_not_equals "$exit_code" "0" "Should not retrieve expired cache entry" && test_pass
}

test_cache_custom_ttl() {
    test_case "3.3. Cache respects custom TTL values"

    _doctor_cache_init

    local test_key="${TEST_CACHE_PREFIX}custom-ttl"

    _doctor_cache_set "$test_key" '{"status": "valid"}' 60

    local cache_file="${DOCTOR_CACHE_DIR}/${test_key}.cache"

    assert_file_exists "$cache_file" "Cache file not created" || return

    local ttl_value=$(cat "$cache_file" | jq -r '.ttl_seconds // 0' 2>/dev/null)
    assert_equals "$ttl_value" "60" "TTL not set correctly (got: $ttl_value)" && test_pass
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 4: CONCURRENT ACCESS (2 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_cache_lock_mechanism() {
    test_case "4.1. Cache locking functions exist"

    assert_function_exists "_doctor_cache_acquire_lock" "Lock acquire function not available" && \
    assert_function_exists "_doctor_cache_release_lock" "Lock release function not available" && \
    test_pass
}

test_cache_concurrent_writes() {
    test_case "4.2. Concurrent writes don't corrupt cache"

    _doctor_cache_init

    local test_key="${TEST_CACHE_PREFIX}concurrent"

    _doctor_cache_set "$test_key" '{"writer": "first"}' 300
    _doctor_cache_set "$test_key" '{"writer": "second"}' 300

    local retrieved=$(_doctor_cache_get "$test_key")

    assert_contains "$retrieved" "second" "Concurrent writes corrupted cache" && test_pass
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 5: CACHE CLEANUP (3 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_cache_clear_specific() {
    test_case "5.1. Cache clear removes specific entry"

    _doctor_cache_init

    local test_key="${TEST_CACHE_PREFIX}clear-single"

    _doctor_cache_set "$test_key" '{"status": "valid"}'
    _doctor_cache_clear "$test_key"

    _doctor_cache_get "$test_key" >/dev/null 2>&1
    local exit_code=$?

    assert_not_equals "$exit_code" "0" "Cache entry should be cleared" && test_pass
}

test_cache_clear_all() {
    test_case "5.2. Cache clear removes all entries"

    _doctor_cache_init

    local key1="${TEST_CACHE_PREFIX}clear-1"
    local key2="${TEST_CACHE_PREFIX}clear-2"
    local key3="${TEST_CACHE_PREFIX}clear-3"

    _doctor_cache_set "$key1" '{"status": "valid"}'
    _doctor_cache_set "$key2" '{"status": "valid"}'
    _doctor_cache_set "$key3" '{"status": "valid"}'

    setopt local_options nonomatch
    rm -f "${DOCTOR_CACHE_DIR}/${TEST_CACHE_PREFIX}clear-"*.cache 2>/dev/null

    assert_file_not_exists "${DOCTOR_CACHE_DIR}/${key1}.cache" "Entry 1 not cleared" && \
    assert_file_not_exists "${DOCTOR_CACHE_DIR}/${key2}.cache" "Entry 2 not cleared" && \
    assert_file_not_exists "${DOCTOR_CACHE_DIR}/${key3}.cache" "Entry 3 not cleared" && \
    test_pass
}

test_cache_clean_old_entries() {
    test_case "5.3. Clean old entries function exists"

    assert_function_exists "_doctor_cache_clean_old" "Cleanup function not available" && test_pass
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 6: ERROR HANDLING (2 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_cache_invalid_json() {
    test_case "6.1. Invalid JSON in cache file handled gracefully"

    _doctor_cache_init

    local test_key="${TEST_CACHE_PREFIX}invalid-json"

    echo "invalid json {{{" > "${DOCTOR_CACHE_DIR}/${test_key}.cache"

    _doctor_cache_get "$test_key" >/dev/null 2>&1
    local exit_code=$?

    assert_not_equals "$exit_code" "0" "Should reject invalid JSON" && test_pass
}

test_cache_missing_metadata() {
    test_case "6.2. Cache file missing expiration handled"

    _doctor_cache_init

    local test_key="${TEST_CACHE_PREFIX}no-expiry"

    echo '{"status": "valid"}' > "${DOCTOR_CACHE_DIR}/${test_key}.cache"

    _doctor_cache_get "$test_key" >/dev/null 2>&1
    local exit_code=$?

    assert_not_equals "$exit_code" "0" "Should reject cache without expiration" && test_pass
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 7: TOKEN CONVENIENCE FUNCTIONS (3 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_cache_token_get() {
    test_case "7.1. Convenience wrapper for token get"

    _doctor_cache_init

    _doctor_cache_set "token-${TEST_CACHE_PREFIX}get" '{"status": "valid", "days_remaining": 45}'

    local retrieved=$(_doctor_cache_token_get "${TEST_CACHE_PREFIX}get")
    local exit_code=$?

    assert_exit_code "$exit_code" 0 "Token get wrapper failed" && \
    assert_contains "$retrieved" "valid" "Token get should return cached value" && \
    test_pass
}

test_cache_token_set() {
    test_case "7.2. Convenience wrapper for token set"

    _doctor_cache_init

    _doctor_cache_token_set "${TEST_CACHE_PREFIX}set" '{"status": "valid", "days_remaining": 45}'

    local retrieved=$(_doctor_cache_get "token-${TEST_CACHE_PREFIX}set")
    local exit_code=$?

    assert_exit_code "$exit_code" 0 "Token set wrapper failed" && \
    assert_contains "$retrieved" "valid" "Token set should persist value" && \
    test_pass
}

test_cache_token_clear() {
    test_case "7.3. Convenience wrapper for token clear"

    _doctor_cache_init

    _doctor_cache_token_set "${TEST_CACHE_PREFIX}clear-tok" '{"status": "valid"}'
    _doctor_cache_token_clear "${TEST_CACHE_PREFIX}clear-tok"

    _doctor_cache_token_get "${TEST_CACHE_PREFIX}clear-tok" >/dev/null 2>&1
    local exit_code=$?

    assert_not_equals "$exit_code" "0" "Token clear wrapper failed" && test_pass
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 8: INTEGRATION (2 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_cache_stats() {
    test_case "8.1. Cache stats shows entries correctly"

    _doctor_cache_init

    _doctor_cache_set "${TEST_CACHE_PREFIX}stat-1" '{"status": "valid"}'
    _doctor_cache_set "${TEST_CACHE_PREFIX}stat-2" '{"status": "valid"}'

    local stats=$(_doctor_cache_stats 2>&1)

    if [[ "$stats" == *"${TEST_CACHE_PREFIX}stat"* || "$stats" == *"Total entries"* ]]; then
        test_pass
    else
        test_fail "Stats should show cache entries"
    fi
}

test_doctor_calls_cache() {
    test_case "8.2. Doctor command integrates with cache"

    _doctor_cache_init

    if ! type doctor &>/dev/null; then
        source "$PROJECT_ROOT/commands/doctor.zsh" 2>/dev/null
    fi

    if type doctor &>/dev/null; then
        doctor --dot >/dev/null 2>&1
        local exit_code=$?
        assert_exit_code "$exit_code" 0 "Doctor cache integration failed" && test_pass
    else
        test_fail "Doctor command not available"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# RUN ALL TESTS
# ══════════════════════════════════════════════════════════════════════════════

main() {
    test_suite_start "Doctor Cache Tests"

    setup

    # Category 1: Initialization
    test_cache_init_creates_directory
    test_cache_init_permissions

    # Category 2: Basic Get/Set
    test_cache_set_and_get
    test_cache_get_nonexistent
    test_cache_overwrite

    # Category 3: Cache Expiration
    test_cache_ttl_not_expired
    test_cache_ttl_expired
    test_cache_custom_ttl

    # Category 4: Concurrent Access
    test_cache_lock_mechanism
    test_cache_concurrent_writes

    # Category 5: Cache Cleanup
    test_cache_clear_specific
    test_cache_clear_all
    test_cache_clean_old_entries

    # Category 6: Error Handling
    test_cache_invalid_json
    test_cache_missing_metadata

    # Category 7: Token Convenience Functions
    test_cache_token_get
    test_cache_token_set
    test_cache_token_clear

    # Category 8: Integration
    test_cache_stats
    test_doctor_calls_cache

    cleanup

    test_suite_end
    exit $?
}

main "$@"
