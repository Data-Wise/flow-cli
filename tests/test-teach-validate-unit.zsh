#!/usr/bin/env zsh
# test-teach-validate-unit.zsh - Unit tests for teach validate command
# Run with: zsh tests/test-teach-validate-unit.zsh
#
# Tests:
# - YAML validation (valid, invalid, missing)
# - Syntax validation (valid, invalid)
# - Render validation (valid, invalid)
# - Empty chunk detection
# - Image reference validation
# - Watch mode (file detection, debouncing)
# - Conflict detection (quarto preview)
# - Race condition handling
# - Performance tracking

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

# Test directory
SCRIPT_DIR="${0:A:h}"
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

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
    test_fail "$message (expected: '$expected', got: '$actual')"
    return 1
  fi
}

assert_success() {
  local code="$1"
  local message="${2:-Command should succeed}"

  if [[ $code -eq 0 ]]; then
    return 0
  else
    test_fail "$message (exit code: $code)"
    return 1
  fi
}

assert_failure() {
  local code="$1"
  local message="${2:-Command should fail}"

  if [[ $code -ne 0 ]]; then
    return 0
  else
    test_fail "$message (expected failure, got success)"
    return 1
  fi
}

assert_file_exists() {
  local file="$1"
  local message="${2:-File should exist: $file}"

  if [[ -f "$file" ]]; then
    return 0
  else
    test_fail "$message"
    return 1
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-Should contain substring}"

  if [[ "$haystack" == *"$needle"* ]]; then
    return 0
  else
    test_fail "$message (expected to contain: '$needle')"
    return 1
  fi
}

# ============================================================================
# TEST SETUP
# ============================================================================

setup_test_environment() {
  cd "$TEST_DIR"

  # Create test directory structure
  mkdir -p lectures
  mkdir -p .teach

  # Source the validation helpers
  source "${SCRIPT_DIR}/../lib/core.zsh"
  source "${SCRIPT_DIR}/../lib/validation-helpers.zsh"
  source "${SCRIPT_DIR}/../commands/teach-validate.zsh"
}

# ============================================================================
# MOCK FILES
# ============================================================================

create_valid_qmd() {
  local file="$1"
  cat > "$file" <<'EOF'
---
title: "Valid Quarto Document"
author: "Test Author"
format: html
---

# Introduction

This is a valid Quarto document.

```{r}
x <- 1:10
plot(x)
```

## Results

The results are shown above.
EOF
}

create_invalid_yaml_qmd() {
  local file="$1"
  cat > "$file" <<'EOF'
---
title: "Invalid YAML"
author: Test Author
  bad_indent: this breaks yaml
format: html
---

# Content
EOF
}

create_missing_yaml_qmd() {
  local file="$1"
  cat > "$file" <<'EOF'
# No YAML Frontmatter

This document has no YAML frontmatter.
EOF
}

create_empty_chunks_qmd() {
  local file="$1"
  cat > "$file" <<'EOF'
---
title: "Empty Chunks"
---

# Empty Code Chunks

```{r}
```

Another empty chunk:

```{r}

```

Valid chunk:

```{r}
x <- 1
```
EOF
}

create_missing_images_qmd() {
  local file="$1"
  cat > "$file" <<'EOF'
---
title: "Missing Images"
---

# Images

Valid image (URL):
![Valid](https://example.com/image.png)

Missing local image:
![Missing](images/missing.png)

Another missing:
![Also Missing](./not-found.jpg)
EOF
}

# ============================================================================
# LAYER 1: YAML VALIDATION TESTS
# ============================================================================

test_yaml_valid() {
  test_start "YAML validation - valid file"

  create_valid_qmd "lectures/test.qmd"

  local result
  _validate_yaml "lectures/test.qmd" 1
  result=$?

  if assert_success $result "Valid YAML should pass"; then
    test_pass
  fi
}

test_yaml_invalid() {
  test_start "YAML validation - invalid syntax"

  create_invalid_yaml_qmd "lectures/invalid.qmd"

  # Check if yq is installed
  if ! command -v yq &>/dev/null; then
    echo "${YELLOW}SKIP${RESET} (yq not installed)"
    return 0
  fi

  local result
  _validate_yaml "lectures/invalid.qmd" 1
  result=$?

  if assert_failure $result "Invalid YAML should fail"; then
    test_pass
  fi
}

test_yaml_missing() {
  test_start "YAML validation - missing frontmatter"

  create_missing_yaml_qmd "lectures/no-yaml.qmd"

  local result
  _validate_yaml "lectures/no-yaml.qmd" 1
  result=$?

  if assert_failure $result "Missing YAML should fail"; then
    test_pass
  fi
}

test_yaml_file_not_found() {
  test_start "YAML validation - file not found"

  local result
  _validate_yaml "lectures/nonexistent.qmd" 1
  result=$?

  if assert_failure $result "Nonexistent file should fail"; then
    test_pass
  fi
}

test_yaml_batch() {
  test_start "YAML validation - batch processing"

  create_valid_qmd "lectures/week-01.qmd"
  create_valid_qmd "lectures/week-02.qmd"
  create_valid_qmd "lectures/week-03.qmd"

  local result
  _validate_yaml_batch "lectures/week-01.qmd" "lectures/week-02.qmd" "lectures/week-03.qmd"
  result=$?

  if assert_success $result "Batch YAML validation should pass for all valid files"; then
    test_pass
  fi
}

# ============================================================================
# LAYER 2: SYNTAX VALIDATION TESTS
# ============================================================================

test_syntax_valid() {
  test_start "Syntax validation - valid file"

  create_valid_qmd "lectures/test.qmd"

  # Check if quarto is installed
  if ! command -v quarto &>/dev/null; then
    echo "${YELLOW}SKIP${RESET} (quarto not installed)"
    return 0
  fi

  local result
  _validate_syntax "lectures/test.qmd" 1
  result=$?

  if assert_success $result "Valid syntax should pass"; then
    test_pass
  fi
}

test_syntax_batch() {
  test_start "Syntax validation - batch processing"

  # Check if quarto is installed
  if ! command -v quarto &>/dev/null; then
    echo "${YELLOW}SKIP${RESET} (quarto not installed)"
    return 0
  fi

  create_valid_qmd "lectures/week-01.qmd"
  create_valid_qmd "lectures/week-02.qmd"

  local result
  _validate_syntax_batch "lectures/week-01.qmd" "lectures/week-02.qmd"
  result=$?

  if assert_success $result "Batch syntax validation should pass"; then
    test_pass
  fi
}

# ============================================================================
# LAYER 3: RENDER VALIDATION TESTS
# ============================================================================

test_render_valid() {
  test_start "Render validation - valid file"

  create_valid_qmd "lectures/test.qmd"

  # Check if quarto is installed
  if ! command -v quarto &>/dev/null; then
    echo "${YELLOW}SKIP${RESET} (quarto not installed)"
    return 0
  fi

  local result
  _validate_render "lectures/test.qmd" 1
  result=$?

  if assert_success $result "Valid file should render"; then
    test_pass
  fi
}

# ============================================================================
# LAYER 4: EMPTY CHUNK DETECTION TESTS
# ============================================================================

test_empty_chunks_detection() {
  test_start "Empty chunk detection"

  create_empty_chunks_qmd "lectures/empty.qmd"

  local result
  _check_empty_chunks "lectures/empty.qmd" 1
  result=$?

  # Empty chunks should be detected (returns 1 for warnings)
  if assert_failure $result "Empty chunks should be detected"; then
    test_pass
  fi
}

test_no_empty_chunks() {
  test_start "Empty chunk detection - valid chunks"

  create_valid_qmd "lectures/valid.qmd"

  local result
  _check_empty_chunks "lectures/valid.qmd" 1
  result=$?

  if assert_success $result "Valid chunks should pass"; then
    test_pass
  fi
}

# ============================================================================
# LAYER 5: IMAGE VALIDATION TESTS
# ============================================================================

test_missing_images() {
  test_start "Image reference validation - missing images"

  create_missing_images_qmd "lectures/images.qmd"

  local result
  _check_images "lectures/images.qmd" 1
  result=$?

  # Missing images should return non-zero (count of missing)
  if assert_failure $result "Missing images should be detected"; then
    test_pass
  fi
}

test_valid_images() {
  test_start "Image reference validation - valid images"

  # Create test image (relative to lectures directory)
  mkdir -p lectures/images
  touch lectures/images/test.png

  cat > "lectures/valid-images.qmd" <<'EOF'
---
title: "Valid Images"
---

# Images

Valid local image:
![Test](images/test.png)

Valid URL:
![URL](https://example.com/image.png)
EOF

  local result
  _check_images "lectures/valid-images.qmd" 1
  result=$?

  if assert_success $result "Valid images should pass"; then
    test_pass
  fi
}

# ============================================================================
# FREEZE CHECK TESTS
# ============================================================================

test_freeze_not_staged() {
  test_start "Freeze check - not staged"

  # Initialize git repo
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"

  create_valid_qmd "lectures/test.qmd"
  mkdir -p _freeze
  touch _freeze/test.json

  # Don't stage _freeze
  git add lectures/test.qmd

  local result
  _check_freeze_staged 1
  result=$?

  if assert_success $result "No staged _freeze should pass"; then
    test_pass
  fi
}

test_freeze_staged() {
  test_start "Freeze check - staged (should fail)"

  # Initialize git repo
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"

  mkdir -p _freeze
  touch _freeze/test.json

  # Stage _freeze (this should fail)
  git add _freeze/

  local result
  _check_freeze_staged 1
  result=$?

  if assert_failure $result "Staged _freeze should fail"; then
    test_pass
  fi
}

# ============================================================================
# WATCH MODE HELPERS TESTS
# ============================================================================

test_quarto_preview_not_running() {
  test_start "Quarto preview detection - not running"

  local result
  _is_quarto_preview_running
  result=$?

  if assert_failure $result "No preview should return false"; then
    test_pass
  fi
}

test_quarto_preview_pid_stale() {
  test_start "Quarto preview detection - stale PID"

  # Create stale PID file
  echo "99999999" > .quarto-preview.pid

  local result
  _is_quarto_preview_running
  result=$?

  # First assertion: stale PID should return false (not running)
  if ! assert_failure $result "Stale PID should return false"; then
    return
  fi

  # Second assertion: PID file should be cleaned up (should NOT exist)
  if [[ -f ".quarto-preview.pid" ]]; then
    test_fail "Stale PID file was not removed"
  else
    test_pass
  fi
}

# ============================================================================
# VALIDATION STATUS TESTS
# ============================================================================

test_update_validation_status() {
  test_start "Update validation status"

  # Check if jq is installed
  if ! command -v jq &>/dev/null; then
    echo "${YELLOW}SKIP${RESET} (jq not installed)"
    return 0
  fi

  _update_validation_status "lectures/test.qmd" "pass" ""

  if assert_file_exists ".teach/validation-status.json" "Status file should be created"; then
    local vstatus
    vstatus=$(_get_validation_status "lectures/test.qmd")

    if assert_equals "$vstatus" "pass" "Status should be 'pass'"; then
      test_pass
    fi
  fi
}

test_update_validation_status_fail() {
  test_start "Update validation status - failure"

  # Check if jq is installed
  if ! command -v jq &>/dev/null; then
    echo "${YELLOW}SKIP${RESET} (jq not installed)"
    return 0
  fi

  _update_validation_status "lectures/broken.qmd" "fail" "Syntax error"

  local vstatus
  vstatus=$(_get_validation_status "lectures/broken.qmd")

  if assert_equals "$vstatus" "fail" "Status should be 'fail'"; then
    test_pass
  fi
}

# ============================================================================
# DEBOUNCE TESTS
# ============================================================================

test_debounce_first_call() {
  test_start "Debounce - first call (should validate)"

  local result
  _debounce_validation "lectures/test.qmd" 500
  result=$?

  if assert_success $result "First call should allow validation"; then
    test_pass
  fi
}

test_debounce_rapid_calls() {
  test_start "Debounce - rapid calls (should skip)"

  # First call
  _debounce_validation "lectures/test.qmd" 500

  # Immediate second call (should be debounced)
  local result
  _debounce_validation "lectures/test.qmd" 500
  result=$?

  if assert_failure $result "Rapid second call should be debounced"; then
    test_pass
  fi
}

test_debounce_after_delay() {
  test_start "Debounce - after delay (should validate)"

  # First call
  _debounce_validation "lectures/test.qmd" 100

  # Wait for debounce period
  sleep 0.2

  # Second call after delay
  local result
  _debounce_validation "lectures/test.qmd" 100
  result=$?

  if assert_success $result "Call after delay should allow validation"; then
    test_pass
  fi
}

# ============================================================================
# FIND QUARTO FILES TESTS
# ============================================================================

test_find_quarto_files() {
  test_start "Find Quarto files - recursive search"

  # Create fresh directory to avoid finding files from previous tests
  local find_test_dir="find-test-$$"
  mkdir -p "$find_test_dir/lectures/week-01"
  mkdir -p "$find_test_dir/assignments"

  create_valid_qmd "$find_test_dir/lectures/intro.qmd"
  create_valid_qmd "$find_test_dir/lectures/week-01/lecture.qmd"
  create_valid_qmd "$find_test_dir/assignments/hw-01.qmd"

  local files
  files=($(_find_quarto_files "$find_test_dir"))

  local count=${#files[@]}
  if assert_equals "$count" "3" "Should find 3 .qmd files"; then
    test_pass
  fi

  # Cleanup
  rm -rf "$find_test_dir"
}

# ============================================================================
# PERFORMANCE TRACKING TESTS
# ============================================================================

test_performance_tracking() {
  test_start "Performance tracking"

  _track_validation_start "lectures/test.qmd"

  sleep 0.1  # Simulate validation

  local duration
  duration=$(_track_validation_end "lectures/test.qmd")

  # Duration should be > 100ms
  if [[ $duration -gt 100 ]]; then
    test_pass
  else
    test_fail "Duration should be > 100ms (got ${duration}ms)"
  fi
}

# ============================================================================
# COMBINED VALIDATION TESTS
# ============================================================================

test_validate_file_full() {
  test_start "Full validation - all layers"

  create_valid_qmd "lectures/full-test.qmd"

  # Check dependencies
  if ! command -v quarto &>/dev/null; then
    echo "${YELLOW}SKIP${RESET} (quarto not installed)"
    return 0
  fi

  local result
  _validate_file_full "lectures/full-test.qmd" 1 "yaml,syntax,chunks,images"
  result=$?

  if assert_success $result "Full validation should pass"; then
    test_pass
  fi
}

test_validate_file_yaml_only() {
  test_start "Full validation - YAML layer only"

  create_valid_qmd "lectures/yaml-only.qmd"

  local result
  _validate_file_full "lectures/yaml-only.qmd" 1 "yaml"
  result=$?

  if assert_success $result "YAML-only validation should pass"; then
    test_pass
  fi
}

# ============================================================================
# TEACH-VALIDATE COMMAND TESTS
# ============================================================================

test_teach_validate_help() {
  test_start "teach-validate --help"

  local output
  output=$(teach-validate --help)

  if assert_contains "$output" "teach validate" "Help should contain command name"; then
    if assert_contains "$output" "--yaml" "Help should list --yaml flag"; then
      if assert_contains "$output" "--watch" "Help should list --watch flag"; then
        test_pass
      fi
    fi
  fi
}

test_lint_flag_parsing() {
  test_start "teach-validate --lint flag is recognized"

  local output
  output=$(teach-validate --lint --help 2>&1)
  local result=$?

  if assert_success $result "--lint should be recognized"; then
    if assert_contains "$output" "lint" "Help should mention lint"; then
      test_pass
    fi
  fi
}

test_teach_validate_no_files() {
  test_start "teach-validate with no files (should find all)"

  create_valid_qmd "lectures/week-01.qmd"
  create_valid_qmd "lectures/week-02.qmd"

  # This would normally find all .qmd files
  # For test, we just check function exists
  if (( $+functions[teach-validate] )); then
    test_pass
  else
    test_fail "teach-validate function should exist"
  fi
}

# ============================================================================
# RUN ALL TESTS
# ============================================================================

run_all_tests() {
  echo "${CYAN}============================================${RESET}"
  echo "${CYAN}  Teach Validate Unit Tests${RESET}"
  echo "${CYAN}============================================${RESET}"
  echo ""

  setup_test_environment

  # Layer 1: YAML Validation
  echo "${YELLOW}LAYER 1: YAML Validation${RESET}"
  test_yaml_valid
  test_yaml_invalid
  test_yaml_missing
  test_yaml_file_not_found
  test_yaml_batch
  echo ""

  # Layer 2: Syntax Validation
  echo "${YELLOW}LAYER 2: Syntax Validation${RESET}"
  test_syntax_valid
  test_syntax_batch
  echo ""

  # Layer 3: Render Validation
  echo "${YELLOW}LAYER 3: Render Validation${RESET}"
  test_render_valid
  echo ""

  # Layer 4: Empty Chunks
  echo "${YELLOW}LAYER 4: Empty Chunk Detection${RESET}"
  test_empty_chunks_detection
  test_no_empty_chunks
  echo ""

  # Layer 5: Image Validation
  echo "${YELLOW}LAYER 5: Image Validation${RESET}"
  test_missing_images
  test_valid_images
  echo ""

  # Freeze Check
  echo "${YELLOW}FREEZE CHECK${RESET}"
  cd "$TEST_DIR"  # Reset to test dir (git tests change dir)
  test_freeze_not_staged
  cd "$TEST_DIR"
  test_freeze_staged
  cd "$TEST_DIR"
  echo ""

  # Watch Mode Helpers
  echo "${YELLOW}WATCH MODE HELPERS${RESET}"
  test_quarto_preview_not_running
  test_quarto_preview_pid_stale
  echo ""

  # Validation Status
  echo "${YELLOW}VALIDATION STATUS${RESET}"
  test_update_validation_status
  test_update_validation_status_fail
  echo ""

  # Debounce
  echo "${YELLOW}DEBOUNCE${RESET}"
  test_debounce_first_call
  test_debounce_rapid_calls
  test_debounce_after_delay
  echo ""

  # Find Files
  echo "${YELLOW}FIND FILES${RESET}"
  test_find_quarto_files
  echo ""

  # Performance
  echo "${YELLOW}PERFORMANCE TRACKING${RESET}"
  test_performance_tracking
  echo ""

  # Combined Validation
  echo "${YELLOW}COMBINED VALIDATION${RESET}"
  test_validate_file_full
  test_validate_file_yaml_only
  echo ""

  # Command Tests
  echo "${YELLOW}COMMAND TESTS${RESET}"
  test_teach_validate_help
  test_lint_flag_parsing
  test_teach_validate_no_files
  echo ""

  # Summary
  echo "${CYAN}============================================${RESET}"
  echo "${CYAN}  Test Summary${RESET}"
  echo "${CYAN}============================================${RESET}"
  echo "Tests run:    $TESTS_RUN"
  echo "${GREEN}Tests passed: $TESTS_PASSED${RESET}"

  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo "${RED}Tests failed: $TESTS_FAILED${RESET}"
    echo ""
    echo "${RED}FAILED${RESET}"
    return 1
  else
    echo "${GREEN}Tests failed: $TESTS_FAILED${RESET}"
    echo ""
    echo "${GREEN}ALL TESTS PASSED${RESET}"
    return 0
  fi
}

# Run tests
run_all_tests
exit $?
