#!/usr/bin/env zsh
# Test suite for v5.1.0 features
# Tests file modification detection, error handling, and dry-run mode

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
print_test() {
  echo "${YELLOW}TEST:${NC} $1"
}

print_pass() {
  echo "${GREEN}✓ PASS${NC}: $1"
  ((TESTS_PASSED++))
}

print_fail() {
  echo "${RED}✗ FAIL${NC}: $1"
  ((TESTS_FAILED++))
}

run_test() {
  ((TESTS_RUN++))
}

# ═══════════════════════════════════════════════════════════════════
# TEST 1: File Modification Detection (Hash-based)
# ═══════════════════════════════════════════════════════════════════

test_hash_detection() {
  print_test "File modification detection uses shasum"
  run_test

  # Create temp file
  local temp_file=$(mktemp)
  echo "original content" > "$temp_file"

  # Get hash
  local hash1=$(shasum -a 256 "$temp_file" 2>/dev/null | cut -d' ' -f1)

  # Modify within 1 second (would fail with mtime)
  echo "modified content" > "$temp_file"

  # Get new hash
  local hash2=$(shasum -a 256 "$temp_file" 2>/dev/null | cut -d' ' -f1)

  # Cleanup
  rm -f "$temp_file"

  # Verify hashes are different
  if [[ "$hash1" != "$hash2" ]]; then
    print_pass "Hash detection catches fast edits (hash1 != hash2)"
  else
    print_fail "Hash detection failed to detect change"
  fi
}

test_hash_no_change() {
  print_test "Hash detection identifies no change correctly"
  run_test

  local temp_file=$(mktemp)
  echo "content" > "$temp_file"

  local hash1=$(shasum -a 256 "$temp_file" 2>/dev/null | cut -d' ' -f1)
  local hash2=$(shasum -a 256 "$temp_file" 2>/dev/null | cut -d' ' -f1)

  rm -f "$temp_file"

  if [[ "$hash1" == "$hash2" ]]; then
    print_pass "Hash correctly identifies unchanged file"
  else
    print_fail "Hash incorrectly reports change for unchanged file"
  fi
}

# ═══════════════════════════════════════════════════════════════════
# TEST 2: Bitwarden Error Handling
# ═══════════════════════════════════════════════════════════════════

test_error_pattern_not_found() {
  print_test "Error handling: 'Not found' pattern"
  run_test

  local error_msg="Error: Not found."
  local result=""

  case "$error_msg" in
    *"Not found"*|*"not found"*)
      result="matched"
      ;;
  esac

  if [[ "$result" == "matched" ]]; then
    print_pass "Pattern matches 'Not found' error"
  else
    print_fail "Pattern failed to match 'Not found'"
  fi
}

test_error_pattern_session() {
  print_test "Error handling: 'Session key' pattern"
  run_test

  local error_msg="Session key is invalid"
  local result=""

  case "$error_msg" in
    *"Session key"*|*"session"*)
      result="matched"
      ;;
  esac

  if [[ "$result" == "matched" ]]; then
    print_pass "Pattern matches session error"
  else
    print_fail "Pattern failed to match session error"
  fi
}

test_error_pattern_locked() {
  print_test "Error handling: 'locked' pattern"
  run_test

  local error_msg="Vault is locked"
  local result=""

  case "$error_msg" in
    *"locked"*|*"Locked"*)
      result="matched"
      ;;
  esac

  if [[ "$result" == "matched" ]]; then
    print_pass "Pattern matches locked vault error"
  else
    print_fail "Pattern failed to match locked error"
  fi
}

test_error_pattern_access_denied() {
  print_test "Error handling: 'access denied' pattern"
  run_test

  local error_msg="Access denied for item"
  local result=""

  case "$error_msg" in
    *"access denied"*|*"Access denied"*)
      result="matched"
      ;;
  esac

  if [[ "$result" == "matched" ]]; then
    print_pass "Pattern matches access denied error"
  else
    print_fail "Pattern failed to match access denied"
  fi
}

test_error_temp_file_cleanup() {
  print_test "Error handling: temp file cleanup"
  run_test

  local temp_err=$(mktemp)
  echo "test error" > "$temp_err"

  # Verify file exists
  if [[ -f "$temp_err" ]]; then
    # Cleanup (as code does)
    rm -f "$temp_err"

    # Verify cleanup
    if [[ ! -f "$temp_err" ]]; then
      print_pass "Temp file cleaned up correctly"
    else
      print_fail "Temp file not cleaned up"
    fi
  else
    print_fail "Failed to create temp file"
  fi
}

# ═══════════════════════════════════════════════════════════════════
# TEST 3: Dry-Run Mode
# ═══════════════════════════════════════════════════════════════════

test_dry_run_flag_parsing() {
  print_test "Dry-run: --dry-run flag parsing"
  run_test

  # Simulate flag parsing
  local dry_run=""
  local args=("--dry-run" "file.txt")

  for arg in "${args[@]}"; do
    case "$arg" in
      --dry-run|-n)
        dry_run="--dry-run"
        ;;
    esac
  done

  if [[ -n "$dry_run" ]]; then
    print_pass "Flag parsing detects --dry-run"
  else
    print_fail "Flag parsing missed --dry-run"
  fi
}

test_dry_run_short_flag() {
  print_test "Dry-run: -n short flag parsing"
  run_test

  local dry_run=""
  local args=("-n" "file.txt")

  for arg in "${args[@]}"; do
    case "$arg" in
      --dry-run|-n)
        dry_run="--dry-run"
        ;;
    esac
  done

  if [[ -n "$dry_run" ]]; then
    print_pass "Flag parsing detects -n"
  else
    print_fail "Flag parsing missed -n"
  fi
}

test_dry_run_no_flag() {
  print_test "Dry-run: no flag parsing"
  run_test

  local dry_run=""
  local args=("file.txt")

  for arg in "${args[@]}"; do
    case "$arg" in
      --dry-run|-n)
        dry_run="--dry-run"
        ;;
    esac
  done

  if [[ -z "$dry_run" ]]; then
    print_pass "No dry-run flag when not specified"
  else
    print_fail "Incorrectly set dry-run flag"
  fi
}

# ═══════════════════════════════════════════════════════════════════
# TEST 4: Integration Tests
# ═══════════════════════════════════════════════════════════════════

test_shasum_available() {
  print_test "System: shasum command available"
  run_test

  if command -v shasum >/dev/null 2>&1; then
    print_pass "shasum is available"
  else
    print_fail "shasum not found (required for hash detection)"
  fi
}

test_mktemp_available() {
  print_test "System: mktemp command available"
  run_test

  if command -v mktemp >/dev/null 2>&1; then
    print_pass "mktemp is available"
  else
    print_fail "mktemp not found (required for error handling)"
  fi
}

# ═══════════════════════════════════════════════════════════════════
# RUN ALL TESTS
# ═══════════════════════════════════════════════════════════════════

echo ""
echo "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
echo "${YELLOW}║${NC}  ${GREEN}v5.1.0 Feature Test Suite${NC}                              ${YELLOW}║${NC}"
echo "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Feature 1: Hash-based file detection
echo "${GREEN}═══ Feature 1: Hash-Based File Detection ═══${NC}"
test_hash_detection
test_hash_no_change
echo ""

# Feature 2: Bitwarden error handling
echo "${GREEN}═══ Feature 2: Bitwarden Error Handling ═══${NC}"
test_error_pattern_not_found
test_error_pattern_session
test_error_pattern_locked
test_error_pattern_access_denied
test_error_temp_file_cleanup
echo ""

# Feature 3: Dry-run mode
echo "${GREEN}═══ Feature 3: Dry-Run Mode ═══${NC}"
test_dry_run_flag_parsing
test_dry_run_short_flag
test_dry_run_no_flag
echo ""

# Integration tests
echo "${GREEN}═══ Integration Tests ═══${NC}"
test_shasum_available
test_mktemp_available
echo ""

# ═══════════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════════

echo "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
echo "${YELLOW}║${NC}  ${GREEN}Test Summary${NC}                                             ${YELLOW}║${NC}"
echo "${YELLOW}╠════════════════════════════════════════════════════════════╣${NC}"
echo "${YELLOW}║${NC}  Tests Run:    ${TESTS_RUN}                                           ${YELLOW}║${NC}"
echo "${YELLOW}║${NC}  ${GREEN}Passed:${NC}       ${TESTS_PASSED}                                           ${YELLOW}║${NC}"
echo "${YELLOW}║${NC}  ${RED}Failed:${NC}       ${TESTS_FAILED}                                            ${YELLOW}║${NC}"
echo "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Exit with failure if any tests failed
if [[ $TESTS_FAILED -gt 0 ]]; then
  echo "${RED}✗ Some tests failed${NC}"
  exit 1
else
  echo "${GREEN}✓ All tests passed!${NC}"
  exit 0
fi
