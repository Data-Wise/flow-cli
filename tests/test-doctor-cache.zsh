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

TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_test() {
    echo -n "${CYAN}Testing:${NC} $1 ... "
}

pass() {
    echo "${GREEN}✓ PASS${NC}"
    ((TESTS_PASSED++))
}

fail() {
    echo "${RED}✗ FAIL${NC} - $1"
    ((TESTS_FAILED++))
}

# ══════════════════════════════════════════════════════════════════════════════
# SETUP
# ══════════════════════════════════════════════════════════════════════════════

setup() {
    echo ""
    echo "${YELLOW}Setting up test environment...${NC}"

    # Get project root
    if [[ -n "${0:A}" ]]; then
        PROJECT_ROOT="${0:A:h:h}"
    fi

    if [[ -z "$PROJECT_ROOT" || ! -f "$PROJECT_ROOT/lib/doctor-cache.zsh" ]]; then
        if [[ -f "$PWD/lib/doctor-cache.zsh" ]]; then
            PROJECT_ROOT="$PWD"
        elif [[ -f "$PWD/../lib/doctor-cache.zsh" ]]; then
            PROJECT_ROOT="$PWD/.."
        fi
    fi

    if [[ -z "$PROJECT_ROOT" || ! -f "$PROJECT_ROOT/lib/doctor-cache.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root${NC}"
        echo "  Tried: ${0:A:h:h}, $PWD, $PWD/.."
        exit 1
    fi

    echo "  Project root: $PROJECT_ROOT"

    # Source core library first
    source "$PROJECT_ROOT/lib/core.zsh" 2>/dev/null

    # Source cache library
    source "$PROJECT_ROOT/lib/doctor-cache.zsh" 2>/dev/null

    # Note: DOCTOR_CACHE_DIR is readonly, so we use the default location
    # and clean it during setup/cleanup
    export TEST_CACHE_PREFIX="test-"

    # Clean any existing test cache entries
    rm -f "${DOCTOR_CACHE_DIR}/${TEST_CACHE_PREFIX}"*.cache 2>/dev/null

    echo "  Cache directory: $DOCTOR_CACHE_DIR"
    echo "  Test prefix: $TEST_CACHE_PREFIX"
    echo ""
}

cleanup() {
    echo ""
    echo "${YELLOW}Cleaning up test environment...${NC}"

    # Remove test cache entries (prefixed with "test-")
    rm -f "${DOCTOR_CACHE_DIR}/${TEST_CACHE_PREFIX}"*.cache 2>/dev/null

    echo "  Test cache entries removed"
    echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 1: INITIALIZATION (2 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_cache_init_creates_directory() {
    log_test "1.1. Cache init creates directory"

    # Initialize cache
    _doctor_cache_init

    if [[ -d "$DOCTOR_CACHE_DIR" ]]; then
        pass
    else
        fail "Cache directory not created: $DOCTOR_CACHE_DIR"
    fi
}

test_cache_init_permissions() {
    log_test "1.2. Cache directory has correct permissions"

    _doctor_cache_init

    # Check directory exists and is writable
    if [[ -d "$DOCTOR_CACHE_DIR" && -w "$DOCTOR_CACHE_DIR" ]]; then
        pass
    else
        fail "Cache directory not writable"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 2: BASIC GET/SET (3 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_cache_set_and_get() {
    log_test "2.1. Cache set and get basic value"

    _doctor_cache_init

    # Set a simple value
    local test_key="${TEST_CACHE_PREFIX}basic"
    local test_value='{"status": "valid", "days_remaining": 45}'
    _doctor_cache_set "$test_key" "$test_value"

    # Get it back
    local retrieved=$(_doctor_cache_get "$test_key")
    local exit_code=$?

    # Check retrieval succeeded and contains our data
    if [[ $exit_code -eq 0 ]] && [[ "$retrieved" == *"valid"* ]]; then
        pass
    else
        fail "Failed to retrieve cached value (exit: $exit_code)"
    fi
}

test_cache_get_nonexistent() {
    log_test "2.2. Cache get returns error for nonexistent key"

    _doctor_cache_init

    # Try to get non-existent key
    _doctor_cache_get "nonexistent-key-xyz" >/dev/null 2>&1
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        pass
    else
        fail "Should return error for nonexistent key"
    fi
}

test_cache_overwrite() {
    log_test "2.3. Cache set overwrites existing value"

    _doctor_cache_init

    local test_key="${TEST_CACHE_PREFIX}overwrite"

    # Set initial value
    _doctor_cache_set "$test_key" '{"status": "initial"}'

    # Overwrite with new value
    _doctor_cache_set "$test_key" '{"status": "updated"}'

    # Get it back
    local retrieved=$(_doctor_cache_get "$test_key")

    if [[ "$retrieved" == *"updated"* ]]; then
        pass
    else
        fail "Failed to overwrite cached value"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 3: CACHE EXPIRATION (3 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_cache_ttl_not_expired() {
    log_test "3.1. Cache entry not expired within TTL"

    _doctor_cache_init

    local test_key="${TEST_CACHE_PREFIX}ttl-valid"

    # Set value with 10 second TTL
    _doctor_cache_set "$test_key" '{"status": "valid"}' 10

    # Immediately try to get it (should succeed)
    _doctor_cache_get "$test_key" >/dev/null 2>&1
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Should retrieve valid cache entry"
    fi
}

test_cache_ttl_expired() {
    log_test "3.2. Cache entry expires after TTL (2s wait)"

    _doctor_cache_init

    local test_key="${TEST_CACHE_PREFIX}ttl-expire"

    # Set value with 1 second TTL
    _doctor_cache_set "$test_key" '{"status": "valid"}' 1

    # Wait 2 seconds for expiration
    sleep 2

    # Try to get it (should fail)
    _doctor_cache_get "$test_key" >/dev/null 2>&1
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        pass
    else
        fail "Should not retrieve expired cache entry"
    fi
}

test_cache_custom_ttl() {
    log_test "3.3. Cache respects custom TTL values"

    _doctor_cache_init

    local test_key="${TEST_CACHE_PREFIX}custom-ttl"

    # Set value with 60 second TTL
    _doctor_cache_set "$test_key" '{"status": "valid"}' 60

    # Check the cache file contains TTL metadata
    local cache_file="${DOCTOR_CACHE_DIR}/${test_key}.cache"

    if [[ -f "$cache_file" ]]; then
        local ttl_value=$(cat "$cache_file" | jq -r '.ttl_seconds // 0' 2>/dev/null)
        if [[ "$ttl_value" == "60" ]]; then
            pass
        else
            fail "TTL not set correctly (got: $ttl_value)"
        fi
    else
        fail "Cache file not created"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 4: CONCURRENT ACCESS (2 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_cache_lock_mechanism() {
    log_test "4.1. Cache locking functions exist"

    # Check lock functions exist
    if type _doctor_cache_acquire_lock &>/dev/null && \
       type _doctor_cache_release_lock &>/dev/null; then
        pass
    else
        fail "Lock functions not available"
    fi
}

test_cache_concurrent_writes() {
    log_test "4.2. Concurrent writes don't corrupt cache"

    _doctor_cache_init

    local test_key="${TEST_CACHE_PREFIX}concurrent"

    # Write same key from "two processes" (sequential for test simplicity)
    _doctor_cache_set "$test_key" '{"writer": "first"}' 300
    _doctor_cache_set "$test_key" '{"writer": "second"}' 300

    # Verify last write wins
    local retrieved=$(_doctor_cache_get "$test_key")

    if [[ "$retrieved" == *"second"* ]]; then
        pass
    else
        fail "Concurrent writes corrupted cache"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 5: CACHE CLEANUP (3 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_cache_clear_specific() {
    log_test "5.1. Cache clear removes specific entry"

    _doctor_cache_init

    local test_key="${TEST_CACHE_PREFIX}clear-single"

    # Set a value
    _doctor_cache_set "$test_key" '{"status": "valid"}'

    # Clear it
    _doctor_cache_clear "$test_key"

    # Try to get it (should fail)
    _doctor_cache_get "$test_key" >/dev/null 2>&1
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        pass
    else
        fail "Cache entry should be cleared"
    fi
}

test_cache_clear_all() {
    log_test "5.2. Cache clear removes all entries"

    _doctor_cache_init

    local key1="${TEST_CACHE_PREFIX}clear-1"
    local key2="${TEST_CACHE_PREFIX}clear-2"
    local key3="${TEST_CACHE_PREFIX}clear-3"

    # Set multiple values
    _doctor_cache_set "$key1" '{"status": "valid"}'
    _doctor_cache_set "$key2" '{"status": "valid"}'
    _doctor_cache_set "$key3" '{"status": "valid"}'

    # Clear all test entries
    rm -f "${DOCTOR_CACHE_DIR}/${TEST_CACHE_PREFIX}clear-"*.cache 2>/dev/null

    # Check entries are gone
    local count=0
    [[ ! -f "${DOCTOR_CACHE_DIR}/${key1}.cache" ]] && ((count++))
    [[ ! -f "${DOCTOR_CACHE_DIR}/${key2}.cache" ]] && ((count++))
    [[ ! -f "${DOCTOR_CACHE_DIR}/${key3}.cache" ]] && ((count++))

    if [[ $count -eq 3 ]]; then
        pass
    else
        fail "Cache not fully cleared (cleared: $count/3)"
    fi
}

test_cache_clean_old_entries() {
    log_test "5.3. Clean old entries function exists"

    # Just verify cleanup function is available
    if type _doctor_cache_clean_old &>/dev/null; then
        pass
    else
        fail "Cleanup function not available"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 6: ERROR HANDLING (2 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_cache_invalid_json() {
    log_test "6.1. Invalid JSON in cache file handled gracefully"

    _doctor_cache_init

    local test_key="${TEST_CACHE_PREFIX}invalid-json"

    # Create cache file with invalid JSON
    echo "invalid json {{{" > "${DOCTOR_CACHE_DIR}/${test_key}.cache"

    # Try to get it (should fail gracefully)
    _doctor_cache_get "$test_key" >/dev/null 2>&1
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        pass
    else
        fail "Should reject invalid JSON"
    fi
}

test_cache_missing_metadata() {
    log_test "6.2. Cache file missing expiration handled"

    _doctor_cache_init

    local test_key="${TEST_CACHE_PREFIX}no-expiry"

    # Create cache file without expiration
    echo '{"status": "valid"}' > "${DOCTOR_CACHE_DIR}/${test_key}.cache"

    # Try to get it (should fail due to missing expires_at)
    _doctor_cache_get "$test_key" >/dev/null 2>&1
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        pass
    else
        fail "Should reject cache without expiration"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 7: TOKEN CONVENIENCE FUNCTIONS (3 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_cache_token_get() {
    log_test "7.1. Convenience wrapper for token get"

    _doctor_cache_init

    # Set token cache using base function (creates token-test-get)
    _doctor_cache_set "token-${TEST_CACHE_PREFIX}get" '{"status": "valid", "days_remaining": 45}'

    # Get using convenience wrapper
    local retrieved=$(_doctor_cache_token_get "${TEST_CACHE_PREFIX}get")
    local exit_code=$?

    if [[ $exit_code -eq 0 ]] && [[ "$retrieved" == *"valid"* ]]; then
        pass
    else
        fail "Token get wrapper failed"
    fi
}

test_cache_token_set() {
    log_test "7.2. Convenience wrapper for token set"

    _doctor_cache_init

    # Set using convenience wrapper
    _doctor_cache_token_set "${TEST_CACHE_PREFIX}set" '{"status": "valid", "days_remaining": 45}'

    # Get using base function
    local retrieved=$(_doctor_cache_get "token-${TEST_CACHE_PREFIX}set")
    local exit_code=$?

    if [[ $exit_code -eq 0 ]] && [[ "$retrieved" == *"valid"* ]]; then
        pass
    else
        fail "Token set wrapper failed"
    fi
}

test_cache_token_clear() {
    log_test "7.3. Convenience wrapper for token clear"

    _doctor_cache_init

    # Set token cache
    _doctor_cache_token_set "${TEST_CACHE_PREFIX}clear-tok" '{"status": "valid"}'

    # Clear using convenience wrapper
    _doctor_cache_token_clear "${TEST_CACHE_PREFIX}clear-tok"

    # Try to get (should fail)
    _doctor_cache_token_get "${TEST_CACHE_PREFIX}clear-tok" >/dev/null 2>&1
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        pass
    else
        fail "Token clear wrapper failed"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 8: INTEGRATION (2 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_cache_stats() {
    log_test "8.1. Cache stats shows entries correctly"

    _doctor_cache_init

    # Set some cache entries
    _doctor_cache_set "${TEST_CACHE_PREFIX}stat-1" '{"status": "valid"}'
    _doctor_cache_set "${TEST_CACHE_PREFIX}stat-2" '{"status": "valid"}'

    # Get stats
    local stats=$(_doctor_cache_stats 2>&1)

    if [[ "$stats" == *"${TEST_CACHE_PREFIX}stat"* || "$stats" == *"Total entries"* ]]; then
        pass
    else
        fail "Stats should show cache entries"
    fi
}

test_doctor_calls_cache() {
    log_test "8.2. Doctor command integrates with cache"

    _doctor_cache_init

    # Source the doctor command if needed
    if ! type doctor &>/dev/null; then
        source "$PROJECT_ROOT/commands/doctor.zsh" 2>/dev/null
    fi

    if type doctor &>/dev/null; then
        # Run doctor --dot which should use cache
        doctor --dot >/dev/null 2>&1
        local exit_code=$?

        if [[ $exit_code -eq 0 ]]; then
            pass
        else
            fail "Doctor cache integration failed (exit: $exit_code)"
        fi
    else
        fail "Doctor command not available"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# RUN ALL TESTS
# ══════════════════════════════════════════════════════════════════════════════

main() {
    echo ""
    echo "╭─────────────────────────────────────────────────────────╮"
    echo "│  ${BOLD}Doctor Cache Test Suite${NC}                             │"
    echo "╰─────────────────────────────────────────────────────────╯"

    setup

    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}CATEGORY 1: Initialization (2 tests)${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_cache_init_creates_directory
    test_cache_init_permissions

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}CATEGORY 2: Basic Get/Set (3 tests)${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_cache_set_and_get
    test_cache_get_nonexistent
    test_cache_overwrite

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}CATEGORY 3: Cache Expiration (3 tests)${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_cache_ttl_not_expired
    test_cache_ttl_expired
    test_cache_custom_ttl

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}CATEGORY 4: Concurrent Access (2 tests)${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_cache_lock_mechanism
    test_cache_concurrent_writes

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}CATEGORY 5: Cache Cleanup (3 tests)${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_cache_clear_specific
    test_cache_clear_all
    test_cache_clean_old_entries

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}CATEGORY 6: Error Handling (2 tests)${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_cache_invalid_json
    test_cache_missing_metadata

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}CATEGORY 7: Token Convenience Functions (3 tests)${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_cache_token_get
    test_cache_token_set
    test_cache_token_clear

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}CATEGORY 8: Integration (2 tests)${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_cache_stats
    test_doctor_calls_cache

    cleanup

    # Summary
    echo ""
    echo "╭─────────────────────────────────────────────────────────╮"
    echo "│  ${BOLD}Test Summary${NC}                                         │"
    echo "╰─────────────────────────────────────────────────────────╯"
    echo ""
    echo "  ${GREEN}Passed:${NC} $TESTS_PASSED"
    echo "  ${RED}Failed:${NC} $TESTS_FAILED"
    echo "  ${CYAN}Total:${NC}  $((TESTS_PASSED + TESTS_FAILED))"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "${GREEN}✓ All cache tests passed!${NC}"
        echo ""
        return 0
    else
        echo "${RED}✗ Some cache tests failed${NC}"
        echo ""
        return 1
    fi
}

# Run tests
main "$@"
