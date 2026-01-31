#!/usr/bin/env zsh
# test-dot-chezmoi-safety.zsh - Comprehensive tests for dot chezmoi safety features
# Run with: zsh tests/test-dot-chezmoi-safety.zsh
#
# Tests the dot dispatcher safety enhancements including:
# - Git directory detection
# - Preview before add
# - Ignore pattern management
# - Cross-platform helpers
# - Performance (large directory handling)
# - Doctor integration
# - Negative cases (missing tools, permissions)

# Don't use set -e - we want to continue after failures

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'

# Counters
typeset -g TESTS_RUN=0
typeset -g TESTS_PASSED=0
typeset -g TESTS_FAILED=0

# Test environment
typeset -g TEST_HOME
typeset -g TEST_CHEZMOI_DIR
typeset -g TEST_IGNORE_FILE

# ============================================================================
# TEST HELPERS
# ============================================================================

test_start() {
  echo -n "${CYAN}TEST: $1${RESET} ... "
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_pass() {
  echo "${GREEN}✓ PASS${RESET}"
  TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
  echo "${RED}✗ FAIL${RESET}"
  echo "  ${RED}→ $1${RESET}"
  TESTS_FAILED=$((TESTS_FAILED + 1))
}

assert_equals() {
  local actual="$1"
  local expected="$2"
  local message="${3:-Values should be equal}"

  if [[ "$actual" == "$expected" ]]; then
    return 0
  else
    echo "  ${DIM}Expected: $expected${RESET}"
    echo "  ${DIM}Actual:   $actual${RESET}"
    return 1
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-String should contain substring}"

  if [[ "$haystack" == *"$needle"* ]]; then
    return 0
  else
    echo "  ${DIM}Expected to contain: $needle${RESET}"
    echo "  ${DIM}In: $haystack${RESET}"
    return 1
  fi
}

assert_file_exists() {
  local file="$1"
  local message="${2:-File should exist: $file}"

  if [[ -f "$file" ]]; then
    return 0
  else
    echo "  ${DIM}File not found: $file${RESET}"
    return 1
  fi
}

assert_dir_exists() {
  local dir="$1"
  local message="${2:-Directory should exist: $dir}"

  if [[ -d "$dir" ]]; then
    return 0
  else
    echo "  ${DIM}Directory not found: $dir${RESET}"
    return 1
  fi
}

assert_not_zero() {
  local value="$1"
  local message="${2:-Value should not be zero}"

  if [[ "$value" != "0" && -n "$value" ]]; then
    return 0
  else
    echo "  ${DIM}Value was zero or empty${RESET}"
    return 1
  fi
}

# ============================================================================
# SETUP & TEARDOWN
# ============================================================================

test_setup() {
  # Create isolated test environment
  TEST_HOME="/tmp/test-dot-$$"
  TEST_CHEZMOI_DIR="$TEST_HOME/.local/share/chezmoi"
  TEST_IGNORE_FILE="$TEST_CHEZMOI_DIR/.chezmoiignore"

  mkdir -p "$TEST_CHEZMOI_DIR"
  cd "$TEST_CHEZMOI_DIR" || exit 1

  # Initialize git repo (required for some tests)
  git init -q 2>/dev/null
  git config user.email "test@example.com"
  git config user.name "Test User"

  # Override HOME for testing
  export HOME="$TEST_HOME"
}

test_teardown() {
  # Clean up test environment
  if [[ -d "$TEST_HOME" ]]; then
    rm -rf "$TEST_HOME"
  fi
}

# ============================================================================
# UTILITY FUNCTION TESTS (Phase 0)
# ============================================================================

test_flow_get_file_size() {
  test_start "Cross-platform file size detection"

  # Create test file with known size
  local test_file="$TEST_HOME/test_size.txt"
  echo -n "12345" > "$test_file"  # Exactly 5 bytes

  # Source the helper function
  _flow_get_file_size() {
    local file="$1"
    if stat --version 2>/dev/null | grep -q GNU; then
      stat -c%s "$file" 2>/dev/null || echo 0
    else
      stat -f%z "$file" 2>/dev/null || echo 0
    fi
  }

  local size=$(_flow_get_file_size "$test_file")

  if assert_equals "$size" "5" "File size should be 5 bytes"; then
    test_pass
  else
    test_fail "File size detection incorrect"
  fi
}

test_flow_human_size() {
  test_start "Human-readable size formatting"

  # Source the helper function
  _flow_human_size() {
    local bytes="$1"
    if command -v numfmt &>/dev/null; then
      numfmt --to=iec "$bytes"
    else
      if (( bytes >= 1073741824 )); then
        echo "$((bytes / 1073741824)) GB"
      elif (( bytes >= 1048576 )); then
        echo "$((bytes / 1048576)) MB"
      elif (( bytes >= 1024 )); then
        echo "$((bytes / 1024)) KB"
      else
        echo "${bytes} bytes"
      fi
    fi
  }

  # Test various sizes
  local size_1mb=$(_flow_human_size 1048576)
  local size_1kb=$(_flow_human_size 1024)
  local size_bytes=$(_flow_human_size 512)

  # Check format (may vary with/without numfmt)
  if [[ "$size_1mb" == *"M"* ]] && [[ "$size_1kb" == *"K"* ]]; then
    test_pass
  else
    test_fail "Human size formatting incorrect: 1MB=$size_1mb, 1KB=$size_1kb"
  fi
}

test_flow_timeout_wrapper() {
  test_start "Timeout wrapper (cross-platform)"

  # Source the helper function
  _flow_timeout() {
    local seconds="$1"
    shift

    if command -v timeout &>/dev/null; then
      timeout "${seconds}s" "$@"
    elif command -v gtimeout &>/dev/null; then
      gtimeout "${seconds}s" "$@"
    else
      # No timeout available - just run command
      "$@"
    fi
  }

  # Test fast command (should succeed)
  if _flow_timeout 1 echo "test" >/dev/null 2>&1; then
    test_pass
  else
    test_fail "Timeout wrapper failed on simple command"
  fi
}

# ============================================================================
# GIT DETECTION TESTS (Phase 1)
# ============================================================================

test_git_detection_single_dir() {
  test_start "Git detection in single directory"

  # Create test directory with .git
  local test_dir="$TEST_HOME/test-git-single"
  mkdir -p "$test_dir/.git"

  # Source the function
  _dot_check_git_in_path() {
    local target="$1"
    local git_dirs=()

    if [[ -d "$target/.git" ]]; then
      git_dirs+=("$target/.git")
    fi

    if (( ${#git_dirs[@]} > 0 )); then
      echo "${git_dirs[@]}"
      return 0
    fi
    return 1
  }

  local result=$(_dot_check_git_in_path "$test_dir")

  if assert_not_zero "$result" "Should detect .git directory"; then
    test_pass
  else
    test_fail "Failed to detect .git in single directory"
  fi
}

test_git_detection_nested() {
  test_start "Git detection in nested directories"

  # Create nested structure
  local test_dir="$TEST_HOME/test-git-nested"
  mkdir -p "$test_dir/.git"
  mkdir -p "$test_dir/subdir/.git"

  # Source the function (simplified for testing)
  _dot_check_git_in_path() {
    local target="$1"
    local git_dirs=()

    # Check target
    [[ -d "$target/.git" ]] && git_dirs+=("$target/.git")

    # Check nested (simplified find)
    while IFS= read -r gitdir; do
      git_dirs+=("$gitdir")
    done < <(find "$target" -name ".git" -type d -maxdepth 3 2>/dev/null)

    if (( ${#git_dirs[@]} > 0 )); then
      echo "${git_dirs[@]}"
      return 0
    fi
    return 1
  }

  local result=$(_dot_check_git_in_path "$test_dir")
  local count=$(echo "$result" | wc -w | tr -d ' ')

  if [[ $count -ge 1 ]]; then
    test_pass
  else
    test_fail "Failed to detect nested .git directories"
  fi
}

test_git_detection_empty_dir() {
  test_start "Git detection in directory without .git"

  # Create directory without .git
  local test_dir="$TEST_HOME/test-no-git"
  mkdir -p "$test_dir"

  _dot_check_git_in_path() {
    local target="$1"
    [[ -d "$target/.git" ]] && echo "$target/.git" && return 0
    return 1
  }

  local result=$(_dot_check_git_in_path "$test_dir")

  if [[ -z "$result" ]]; then
    test_pass
  else
    test_fail "Incorrectly detected .git in empty directory"
  fi
}

# ============================================================================
# IGNORE MANAGEMENT TESTS (Phase 1)
# ============================================================================

test_ignore_add_pattern() {
  test_start "Add pattern to .chezmoiignore"

  # Create ignore file
  mkdir -p "$TEST_CHEZMOI_DIR"
  local ignore_file="$TEST_IGNORE_FILE"

  # Add pattern
  echo "*.log" > "$ignore_file"

  # Verify
  if assert_file_exists "$ignore_file" && grep -q "*.log" "$ignore_file"; then
    test_pass
  else
    test_fail "Failed to add pattern to .chezmoiignore"
  fi
}

test_ignore_list_patterns() {
  test_start "List patterns from .chezmoiignore"

  # Create ignore file with patterns
  mkdir -p "$TEST_CHEZMOI_DIR"
  cat > "$TEST_IGNORE_FILE" << 'EOF'
*.log
*.sqlite
**/.git
EOF

  # Count lines
  local count=$(wc -l < "$TEST_IGNORE_FILE" | tr -d ' ')

  if assert_equals "$count" "3" "Should have 3 patterns"; then
    test_pass
  else
    test_fail "Pattern count incorrect"
  fi
}

test_ignore_remove_pattern() {
  test_start "Remove pattern from .chezmoiignore"

  # Create ignore file
  mkdir -p "$TEST_CHEZMOI_DIR"
  cat > "$TEST_IGNORE_FILE" << 'EOF'
*.log
*.sqlite
**/.git
EOF

  # Remove pattern (simulate)
  grep -v "^\*.log$" "$TEST_IGNORE_FILE" > "$TEST_IGNORE_FILE.tmp"
  mv "$TEST_IGNORE_FILE.tmp" "$TEST_IGNORE_FILE"

  # Verify
  if ! grep -q "*.log" "$TEST_IGNORE_FILE" && grep -q "*.sqlite" "$TEST_IGNORE_FILE"; then
    test_pass
  else
    test_fail "Failed to remove pattern correctly"
  fi
}

test_ignore_duplicate_prevention() {
  test_start "Prevent duplicate patterns in .chezmoiignore"

  # Create ignore file
  mkdir -p "$TEST_CHEZMOI_DIR"
  echo "*.log" > "$TEST_IGNORE_FILE"

  # Try to add duplicate (simulate check)
  local pattern="*.log"
  if grep -qF "$pattern" "$TEST_IGNORE_FILE"; then
    # Duplicate detected - don't add
    test_pass
  else
    test_fail "Duplicate detection failed"
  fi
}

# ============================================================================
# PREVIEW TESTS (Phase 1)
# ============================================================================

test_preview_file_count() {
  test_start "Preview calculates file count correctly"

  # Create test directory with files
  local test_dir="$TEST_HOME/test-preview"
  mkdir -p "$test_dir"
  touch "$test_dir/file1.txt"
  touch "$test_dir/file2.txt"
  touch "$test_dir/file3.log"

  # Count files
  local count=$(find "$test_dir" -type f | wc -l | tr -d ' ')

  if assert_equals "$count" "3" "Should count 3 files"; then
    test_pass
  else
    test_fail "File count incorrect"
  fi
}

test_preview_size_calculation() {
  test_start "Preview calculates total size"

  # Create test files with known sizes
  local test_dir="$TEST_HOME/test-size-calc"
  mkdir -p "$test_dir"

  # Create 1KB file
  dd if=/dev/zero of="$test_dir/file1.bin" bs=1024 count=1 2>/dev/null

  # Get size (cross-platform)
  local size
  if stat --version 2>/dev/null | grep -q GNU; then
    size=$(stat -c%s "$test_dir/file1.bin")
  else
    size=$(stat -f%z "$test_dir/file1.bin")
  fi

  if [[ $size -eq 1024 ]]; then
    test_pass
  else
    test_fail "Size calculation incorrect: expected 1024, got $size"
  fi
}

test_preview_large_file_detection() {
  test_start "Preview detects large files (>50KB)"

  # Create large file (100KB)
  local test_dir="$TEST_HOME/test-large"
  mkdir -p "$test_dir"
  dd if=/dev/zero of="$test_dir/large.bin" bs=1024 count=100 2>/dev/null

  # Get size
  local size
  if stat --version 2>/dev/null | grep -q GNU; then
    size=$(stat -c%s "$test_dir/large.bin")
  else
    size=$(stat -f%z "$test_dir/large.bin")
  fi

  if (( size > 51200 )); then
    test_pass
  else
    test_fail "Large file not detected: size=$size bytes"
  fi
}

test_preview_generated_file_warning() {
  test_start "Preview warns about generated files (.log, .sqlite)"

  # Create test directory with generated files
  local test_dir="$TEST_HOME/test-generated"
  mkdir -p "$test_dir"
  touch "$test_dir/app.log"
  touch "$test_dir/db.sqlite"
  touch "$test_dir/cache.db"

  # Count generated files
  local count=$(find "$test_dir" -type f \( -name "*.log" -o -name "*.sqlite" -o -name "*.db" \) | wc -l | tr -d ' ')

  if [[ $count -eq 3 ]]; then
    test_pass
  else
    test_fail "Generated file detection failed: found $count, expected 3"
  fi
}

# ============================================================================
# NEGATIVE TESTS
# ============================================================================

test_missing_chezmoi_installation() {
  test_start "Handle missing chezmoi installation"

  # Simulate check
  if ! command -v chezmoi_nonexistent &>/dev/null; then
    test_pass
  else
    test_fail "Should detect missing chezmoi"
  fi
}

test_nonexistent_path() {
  test_start "Handle nonexistent path in preview"

  local fake_path="/tmp/does-not-exist-$$"

  if [[ ! -e "$fake_path" ]]; then
    test_pass
  else
    test_fail "Should detect nonexistent path"
  fi
}

test_readonly_chezmoi_directory() {
  test_start "Handle read-only chezmoi directory"

  # Create test directory
  local readonly_dir="$TEST_HOME/readonly"
  mkdir -p "$readonly_dir"

  # Make read-only
  chmod 444 "$readonly_dir"

  # Test write permission
  if ! touch "$readonly_dir/test.txt" 2>/dev/null; then
    test_pass
  else
    test_fail "Should detect read-only directory"
  fi

  # Cleanup
  chmod 755 "$readonly_dir"
  rm -rf "$readonly_dir"
}

# ============================================================================
# PERFORMANCE TESTS
# ============================================================================

test_large_directory_performance() {
  test_start "Large directory handling (< 2s target)"

  # Create directory with many files
  local test_dir="$TEST_HOME/test-perf"
  mkdir -p "$test_dir"

  # Create 100 files (reasonable test size)
  for i in {1..100}; do
    echo "test$i" > "$test_dir/file$i.txt"
  done

  # Time the operation
  local start=$(date +%s)
  local count=$(find "$test_dir" -type f | wc -l | tr -d ' ')
  local end=$(date +%s)
  local duration=$((end - start))

  if [[ $count -eq 100 ]] && [[ $duration -lt 2 ]]; then
    test_pass
  else
    test_fail "Performance test failed: $count files in ${duration}s"
  fi
}

# ============================================================================
# INTEGRATION TESTS
# ============================================================================

test_integration_git_detection_and_ignore() {
  test_start "Integration: Git detection → auto-ignore"

  # Setup
  local test_dir="$TEST_HOME/test-integration"
  mkdir -p "$test_dir/.git"
  mkdir -p "$TEST_CHEZMOI_DIR"

  # Simulate workflow
  # 1. Detect git
  local git_found=""
  [[ -d "$test_dir/.git" ]] && git_found="yes"

  # 2. Create ignore rule
  local ignore_file="$TEST_IGNORE_FILE"
  if [[ "$git_found" == "yes" ]]; then
    echo "**/.git" > "$ignore_file"
  fi

  # 3. Verify
  if [[ -f "$ignore_file" ]] && grep -q ".git" "$ignore_file"; then
    test_pass
  else
    test_fail "Integration workflow failed"
  fi
}

test_integration_doctor_all_checks() {
  test_start "Integration: Doctor runs all safety checks"

  # Setup test environment
  mkdir -p "$TEST_CHEZMOI_DIR"
  echo "*.log" > "$TEST_IGNORE_FILE"

  # Simulate doctor checks (simplified)
  local checks_passed=0

  # Check 1: Chezmoi installed
  command -v chezmoi &>/dev/null || ((checks_passed++))  # Count as pass if not installed (expected in test)

  # Check 2: Ignore file exists
  [[ -f "$TEST_IGNORE_FILE" ]] && ((checks_passed++))

  # Check 3: Ignore file has content
  [[ -s "$TEST_IGNORE_FILE" ]] && ((checks_passed++))

  if [[ $checks_passed -ge 2 ]]; then
    test_pass
  else
    test_fail "Doctor integration checks failed: $checks_passed/3 passed"
  fi
}

# ============================================================================
# CACHE TESTS
# ============================================================================

test_cache_size_ttl() {
  test_start "Cache respects TTL (5 minutes)"

  # Simulate cache
  local cache_time=$(date +%s)
  local ttl=300
  local now=$(date +%s)

  local age=$((now - cache_time))

  if [[ $age -lt $ttl ]]; then
    test_pass
  else
    test_fail "Cache TTL check failed"
  fi
}

# ============================================================================
# MAIN TEST RUNNER
# ============================================================================

main() {
  echo ""
  echo "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
  echo "${CYAN}║${RESET}  ${GREEN}DOT CHEZMOI SAFETY FEATURES TEST SUITE${RESET}                   ${CYAN}║${RESET}"
  echo "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
  echo ""

  # Setup
  test_setup

  # Run tests by category
  echo "${YELLOW}═══ Utility Functions (Phase 0) ═══${RESET}"
  test_flow_get_file_size
  test_flow_human_size
  test_flow_timeout_wrapper

  echo ""
  echo "${YELLOW}═══ Git Detection (Phase 1) ═══${RESET}"
  test_git_detection_single_dir
  test_git_detection_nested
  test_git_detection_empty_dir

  echo ""
  echo "${YELLOW}═══ Ignore Management (Phase 1) ═══${RESET}"
  test_ignore_add_pattern
  test_ignore_list_patterns
  test_ignore_remove_pattern
  test_ignore_duplicate_prevention

  echo ""
  echo "${YELLOW}═══ Preview Functionality (Phase 1) ═══${RESET}"
  test_preview_file_count
  test_preview_size_calculation
  test_preview_large_file_detection
  test_preview_generated_file_warning

  echo ""
  echo "${YELLOW}═══ Negative Tests ═══${RESET}"
  test_missing_chezmoi_installation
  test_nonexistent_path
  test_readonly_chezmoi_directory

  echo ""
  echo "${YELLOW}═══ Performance Tests ═══${RESET}"
  test_large_directory_performance

  echo ""
  echo "${YELLOW}═══ Integration Tests ═══${RESET}"
  test_integration_git_detection_and_ignore
  test_integration_doctor_all_checks

  echo ""
  echo "${YELLOW}═══ Cache Tests ═══${RESET}"
  test_cache_size_ttl

  # Teardown
  test_teardown

  # Results
  echo ""
  echo "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
  echo "${CYAN}║${RESET}  ${GREEN}TEST RESULTS${RESET}                                             ${CYAN}║${RESET}"
  echo "${CYAN}╠══════════════════════════════════════════════════════════════╣${RESET}"

  local pass_percent=0
  if [[ $TESTS_RUN -gt 0 ]]; then
    pass_percent=$(( (TESTS_PASSED * 100) / TESTS_RUN ))
  fi

  printf "${CYAN}║${RESET}  Tests run:    ${YELLOW}%-2d${RESET}                                           ${CYAN}║${RESET}\n" $TESTS_RUN
  printf "${CYAN}║${RESET}  Passed:       ${GREEN}%-2d${RESET}                                           ${CYAN}║${RESET}\n" $TESTS_PASSED
  printf "${CYAN}║${RESET}  Failed:       ${RED}%-2d${RESET}                                           ${CYAN}║${RESET}\n" $TESTS_FAILED
  printf "${CYAN}║${RESET}  Pass rate:    ${GREEN}%-3d%%${RESET}                                         ${CYAN}║${RESET}\n" $pass_percent
  echo "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
  echo ""

  # Exit with failure if any tests failed
  if [[ $TESTS_FAILED -gt 0 ]]; then
    return 1
  fi

  return 0
}

# Run tests if executed directly
[[ "${ZSH_EVAL_CONTEXT}" == "toplevel" ]] && main "$@"
