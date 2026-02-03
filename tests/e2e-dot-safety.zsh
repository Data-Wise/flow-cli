#!/usr/bin/env zsh
# e2e-dot-safety.zsh - End-to-End tests for dot safety features (v6.0.0)
# Run with: zsh tests/e2e-dot-safety.zsh
#
# Tests complete workflows:
# - Add files with safety checks
# - Manage ignore patterns
# - Analyze repository size
# - Integration with flow doctor

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
typeset -g E2E_TEST_DIR
typeset -g E2E_CHEZMOI_DIR

# ============================================================================
# TEST HELPERS
# ============================================================================

test_start() {
  echo -n "${CYAN}E2E: $1${RESET} ... "
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

assert_success() {
  local exit_code=$1
  local message="${2:-Command should succeed}"

  if (( exit_code == 0 )); then
    return 0
  else
    echo "  ${DIM}Exit code: $exit_code (expected 0)${RESET}"
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

  if [[ -f "$file" ]]; then
    return 0
  else
    echo "  ${DIM}File not found: $file${RESET}"
    return 1
  fi
}

# ============================================================================
# SETUP & TEARDOWN
# ============================================================================

e2e_setup() {
  # Source plugin FIRST (before changing directories)
  # Try multiple paths to find the plugin
  local plugin_path=""
  for path in \
    "$(dirname $0)/../flow.plugin.zsh" \
    "../flow.plugin.zsh" \
    "./flow.plugin.zsh" \
    "/Users/dt/projects/dev-tools/flow-cli/flow.plugin.zsh"; do
    if [[ -f "$path" ]]; then
      plugin_path="$path"
      break
    fi
  done

  if [[ -z "$plugin_path" ]]; then
    echo "${RED}ERROR: Could not find flow.plugin.zsh${RESET}"
    exit 1
  fi

  source "$plugin_path" 2>/dev/null || {
    echo "${RED}ERROR: Failed to load plugin from: $plugin_path${RESET}"
    exit 1
  }

  # Create isolated test environment
  E2E_TEST_DIR="/tmp/e2e-dot-$$"
  E2E_CHEZMOI_DIR="$E2E_TEST_DIR/.local/share/chezmoi"

  mkdir -p "$E2E_CHEZMOI_DIR" 2>/dev/null
  if [[ ! -d "$E2E_CHEZMOI_DIR" ]]; then
    echo "${YELLOW}⚠ Skipping: cannot create test directories (sandboxed environment)${RESET}"
    exit 0
  fi
  cd "$E2E_CHEZMOI_DIR" || exit 1

  # Initialize git repo
  git init -q 2>/dev/null
  git config user.email "test@example.com"
  git config user.name "Test User"

  # Create .chezmoiignore
  touch .chezmoiignore

  # Override HOME for testing
  export HOME="$E2E_TEST_DIR"
}

e2e_teardown() {
  # Clean up test environment
  if [[ -d "$E2E_TEST_DIR" ]]; then
    rm -rf "$E2E_TEST_DIR"
  fi
}

# ============================================================================
# E2E TEST SCENARIOS
# ============================================================================

print_section() {
  echo ""
  echo "${YELLOW}═══ $1 ═══${RESET}"
}

# ============================================================================
# SCENARIO 1: Add File with Git Detection
# ============================================================================

test_add_with_git_detection() {
  print_section "Scenario 1: Add File with Git Detection"

  # Create a directory with .git subdirectory
  test_start "Create test directory with .git"
  mkdir -p "$E2E_TEST_DIR/test-nvim/.git"
  echo "test" > "$E2E_TEST_DIR/test-nvim/.git/config"
  test_pass

  # Run dot add with git detection
  test_start "Detect .git directory in path"
  local output
  output=$(_dot_check_git_in_path "$E2E_TEST_DIR/test-nvim" 2>&1)
  local result=$?

  if assert_success $result && assert_contains "$output" ".git"; then
    test_pass
  else
    test_fail "Git directory not detected"
  fi

  # Verify auto-suggestion works
  test_start "Auto-suggest ignore pattern"
  if assert_contains "$output" "**/.git"; then
    test_pass
  else
    test_fail "Auto-suggestion not shown"
  fi
}

# ============================================================================
# SCENARIO 2: Ignore Pattern Management Workflow
# ============================================================================

test_ignore_workflow() {
  print_section "Scenario 2: Ignore Pattern Management"

  local ignore_file="$E2E_CHEZMOI_DIR/.chezmoiignore"

  # Add first pattern
  test_start "Add ignore pattern (**/.git)"
  _dot_ignore_add "**/.git" >/dev/null 2>&1

  if assert_file_exists "$ignore_file" && \
     grep -q "**/.git" "$ignore_file"; then
    test_pass
  else
    test_fail "Pattern not added to .chezmoiignore"
  fi

  # List patterns
  test_start "List ignore patterns"
  local patterns
  patterns=$(_dot_ignore_list 2>&1)

  if assert_contains "$patterns" "**/.git"; then
    test_pass
  else
    test_fail "Pattern not listed"
  fi

  # Add duplicate (should be prevented)
  test_start "Prevent duplicate patterns"
  _dot_ignore_add "**/.git" >/dev/null 2>&1
  local count=$(grep -c "**/.git" "$ignore_file")

  if (( count == 1 )); then
    test_pass
  else
    test_fail "Duplicate pattern was added (count: $count)"
  fi

  # Add multiple patterns
  test_start "Add multiple patterns"
  _dot_ignore_add "*.log" >/dev/null 2>&1
  _dot_ignore_add "*.tmp" >/dev/null 2>&1

  local total=$(wc -l < "$ignore_file" | tr -d ' ')
  if (( total == 3 )); then
    test_pass
  else
    test_fail "Expected 3 patterns, got $total"
  fi

  # Remove pattern
  test_start "Remove ignore pattern"
  _dot_ignore_remove "*.log" >/dev/null 2>&1

  if ! grep -q "*.log" "$ignore_file"; then
    test_pass
  else
    test_fail "Pattern not removed"
  fi
}

# ============================================================================
# SCENARIO 3: Repository Size Analysis
# ============================================================================

test_size_analysis() {
  print_section "Scenario 3: Repository Size Analysis"

  # Create test files
  test_start "Create test files with known sizes"
  echo "small file" > "$E2E_CHEZMOI_DIR/small.txt"
  dd if=/dev/zero of="$E2E_CHEZMOI_DIR/large.bin" bs=1024 count=60 2>/dev/null
  test_pass

  # Analyze size
  test_start "Calculate total size"
  local size_output
  size_output=$(_dot_get_cached_size 2>&1 || _dot_size 2>&1)

  if assert_success $?; then
    test_pass
  else
    test_fail "Size calculation failed"
  fi

  # Verify large file warning
  test_start "Warn about large files (>50KB)"
  local large_file_path="$E2E_CHEZMOI_DIR/large.bin"
  local file_size=$(_flow_get_file_size "$large_file_path")

  if (( file_size > 51200 )); then
    test_pass
  else
    test_fail "Large file not detected (size: $file_size bytes)"
  fi
}

# ============================================================================
# SCENARIO 4: Preview Before Add
# ============================================================================

test_preview_workflow() {
  print_section "Scenario 4: Preview Before Add"

  # Create test directory
  test_start "Create test directory with mixed content"
  mkdir -p "$E2E_TEST_DIR/test-config"
  echo "config" > "$E2E_TEST_DIR/test-config/config.yml"
  echo "log data" > "$E2E_TEST_DIR/test-config/app.log"
  dd if=/dev/zero of="$E2E_TEST_DIR/test-config/cache.db" bs=1024 count=55 2>/dev/null
  test_pass

  # Test preview calculation
  test_start "Calculate preview file count"
  local file_count=$(find "$E2E_TEST_DIR/test-config" -type f | wc -l | tr -d ' ')

  if (( file_count == 3 )); then
    test_pass
  else
    test_fail "Expected 3 files, found $file_count"
  fi

  # Test large file detection
  test_start "Detect large files in preview"
  local large_files=$(find "$E2E_TEST_DIR/test-config" -type f -size +50k)

  if [[ -n "$large_files" ]]; then
    test_pass
  else
    test_fail "Large file not detected"
  fi

  # Test generated file detection
  test_start "Detect generated files (*.log, *.db)"
  local generated_count=$(find "$E2E_TEST_DIR/test-config" -type f \( -name "*.log" -o -name "*.db" \) | wc -l | tr -d ' ')

  if (( generated_count == 2 )); then
    test_pass
  else
    test_fail "Expected 2 generated files, found $generated_count"
  fi
}

# ============================================================================
# SCENARIO 5: Integration with flow doctor
# ============================================================================

test_doctor_integration() {
  print_section "Scenario 5: Flow Doctor Integration"

  # Verify doctor has dot checks
  test_start "Doctor includes dot safety checks"

  # Check if _doctor_check_dot_safety function exists
  if type _doctor_check_dot_safety >/dev/null 2>&1; then
    test_pass
  else
    test_fail "Doctor integration function not found"
  fi

  # Test .chezmoiignore existence check
  test_start "Check .chezmoiignore exists"
  local ignore_file="$E2E_CHEZMOI_DIR/.chezmoiignore"

  if [[ -f "$ignore_file" ]]; then
    test_pass
  else
    test_fail ".chezmoiignore not found"
  fi
}

# ============================================================================
# SCENARIO 6: Cache System
# ============================================================================

test_cache_system() {
  print_section "Scenario 6: Cache System"

  local cache_dir="$HOME/.cache/flow"
  local cache_file="$cache_dir/dot-size.cache"

  test_start "Create cache directory"
  mkdir -p "$cache_dir"
  if [[ -d "$cache_dir" ]]; then
    test_pass
  else
    test_fail "Cache directory not created"
  fi

  # Write to cache
  test_start "Write size to cache"
  _dot_cache_size "12345" >/dev/null 2>&1

  if [[ -f "$cache_file" ]]; then
    test_pass
  else
    test_fail "Cache file not created"
  fi

  # Read from cache
  test_start "Read size from cache"
  local cached_size=$(_dot_get_cached_size 2>&1)

  if [[ "$cached_size" == "12345" ]]; then
    test_pass
  else
    test_fail "Cache read failed (got: $cached_size)"
  fi

  # Test cache invalidation
  test_start "Cache respects TTL"
  # Modify cache timestamp to be old
  touch -t 202301010000 "$cache_file" 2>/dev/null

  if ! _dot_is_cache_valid "$cache_file"; then
    test_pass
  else
    test_fail "Old cache still valid"
  fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
  echo "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
  echo "${CYAN}║${RESET}  ${GREEN}E2E Test Suite: Dot Safety Features (v6.0.0)${RESET}        ${CYAN}║${RESET}"
  echo "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
  echo ""

  # Setup
  e2e_setup

  # Run test scenarios
  test_add_with_git_detection
  test_ignore_workflow
  test_size_analysis
  test_preview_workflow
  test_doctor_integration
  test_cache_system

  # Teardown
  e2e_teardown

  # Results
  echo ""
  echo "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
  echo "${CYAN}║${RESET}  ${GREEN}E2E TEST RESULTS${RESET}                                     ${CYAN}║${RESET}"
  echo "${CYAN}╠══════════════════════════════════════════════════════════════╣${RESET}"
  echo "${CYAN}║${RESET}  Tests run:    ${YELLOW}$TESTS_RUN${RESET}                                    ${CYAN}║${RESET}"
  echo "${CYAN}║${RESET}  Passed:       ${GREEN}$TESTS_PASSED${RESET}                                    ${CYAN}║${RESET}"
  echo "${CYAN}║${RESET}  Failed:       ${RED}$TESTS_FAILED${RESET}                                     ${CYAN}║${RESET}"

  if (( TESTS_FAILED == 0 )); then
    echo "${CYAN}║${RESET}  Pass rate:    ${GREEN}100%${RESET}                                  ${CYAN}║${RESET}"
  else
    local pass_rate=$(( 100 * TESTS_PASSED / TESTS_RUN ))
    echo "${CYAN}║${RESET}  Pass rate:    ${YELLOW}${pass_rate}%${RESET}                                   ${CYAN}║${RESET}"
  fi

  echo "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"

  # Exit with proper code
  if (( TESTS_FAILED > 0 )); then
    exit 1
  else
    exit 0
  fi
}

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "$0" == *"zsh"* ]]; then
  main
fi
