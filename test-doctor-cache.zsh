#!/usr/bin/env zsh

# Test suite for doctor-cache.zsh
# Quick validation of Task 5: Cache Manager implementation

# Enable nullglob for safe glob patterns
setopt null_glob

# Clean up any previous test state
rm -rf ~/.flow/cache/doctor

# Source the cache manager
source lib/doctor-cache.zsh

# Test counter
tests_passed=0
tests_failed=0

# Helper function
test_assert() {
    local description="$1"
    local result=$2

    if [[ $result -eq 0 ]]; then
        echo "✓ $description"
        ((tests_passed++))
        return 0
    else
        echo "✗ $description"
        ((tests_failed++))
        return 1
    fi
}

echo "=== Doctor Cache Manager Test Suite ==="
echo ""

# Test 1: Initialization
echo "Test 1: Initialization"
_doctor_cache_init
test_assert "Cache directory created" $?

# Test 2: Set cache entry with default TTL
echo ""
echo "Test 2: Set cache with default TTL"
_doctor_cache_set "token-github" '{"status": "valid", "days_remaining": 45}'
test_assert "Cache entry set" $?

# Test 3: Get cache entry (hit)
echo ""
echo "Test 3: Get cache entry (should hit)"
cached=$(_doctor_cache_get "token-github" 2>/dev/null)
result=$?
test_assert "Cache hit" $result
if [[ $result -eq 0 ]]; then
    val=$(echo "$cached" | jq -r '.status' 2>/dev/null)
    test_assert "Cache data intact (status=valid)" $([[ "$val" == "valid" ]] && echo 0 || echo 1)
fi

# Test 4: Custom TTL
echo ""
echo "Test 4: Set cache with custom TTL (600s)"
_doctor_cache_set "token-npm" '{"status": "valid"}' 600
cached_npm=$(_doctor_cache_get "token-npm" 2>/dev/null)
result=$?
test_assert "Custom TTL cache works" $result
if [[ $result -eq 0 ]]; then
    ttl=$(echo "$cached_npm" | jq -r '.ttl_seconds' 2>/dev/null)
    test_assert "TTL is 600s" $([[ "$ttl" == "600" ]] && echo 0 || echo 1)
fi

# Test 5: Token convenience functions
echo ""
echo "Test 5: Token convenience functions"
_doctor_cache_token_set "pypi" '{"status": "expired"}'
_doctor_cache_token_get "pypi" >/dev/null 2>&1
test_assert "Token convenience wrappers work" $?

# Test 6: Cache miss for non-existent key
echo ""
echo "Test 6: Cache miss for non-existent key"
_doctor_cache_get "token-nonexistent" >/dev/null 2>&1
result=$?
test_assert "Cache miss returns error code" $([[ $result -ne 0 ]] && echo 0 || echo 1)

# Test 7: Clear specific cache entry
echo ""
echo "Test 7: Clear specific cache entry"
_doctor_cache_clear "token-github"
_doctor_cache_get "token-github" >/dev/null 2>&1
result=$?
test_assert "Cleared entry not found" $([[ $result -ne 0 ]] && echo 0 || echo 1)

# Test 8: Other entries unaffected by selective clear
echo ""
echo "Test 8: Selective clear doesn't affect other entries"
_doctor_cache_get "token-npm" >/dev/null 2>&1
test_assert "NPM token still cached" $?

# Test 9: Cache stats
echo ""
echo "Test 9: Cache stats"
stats_output=$(_doctor_cache_stats 2>/dev/null)
echo "$stats_output" | grep -q "Cache Statistics"
test_assert "Stats output generated" $?

# Test 10: Clear all
echo ""
echo "Test 10: Clear all cache"
_doctor_cache_clear
cache_files=(~/.flow/cache/doctor/*.cache)
count=${#cache_files[@]}
test_assert "All cache cleared" $([[ $count -eq 0 ]] && echo 0 || echo 1)

# Test 11: Clean old entries (edge case with no old entries)
echo ""
echo "Test 11: Clean old entries"
cleaned=$(_doctor_cache_clean_old 2>/dev/null)
test_assert "Clean old returns count" $([[ -n "$cleaned" ]] && echo 0 || echo 1)

# Summary
echo ""
echo "==================================="
echo "Test Results:"
echo "  Passed: $tests_passed"
echo "  Failed: $tests_failed"
echo "==================================="

if [[ $tests_failed -eq 0 ]]; then
    echo "✨ All tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi
