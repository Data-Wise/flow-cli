#!/usr/bin/env zsh
# Test Suite: Teach Dates Dispatcher Unit Tests
# Tests user-facing commands in lib/dispatchers/teach-dates.zsh

# Test setup
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Load dependencies
source "$(dirname "$0")/../lib/core.zsh"
source "$(dirname "$0")/../lib/config-validator.zsh"
source "$(dirname "$0")/../lib/date-parser.zsh"
source "$(dirname "$0")/../lib/dispatchers/teach-dispatcher.zsh"
source "$(dirname "$0")/../lib/dispatchers/teach-dates.zsh"

# ============================================================================
# TEST HELPERS
# ============================================================================

assert_equals() {
  local expected="$1"
  local actual="$2"
  local message="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ "$actual" == "$expected" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} $message"
    return 0
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} $message"
    echo -e "  Expected: '$expected'"
    echo -e "  Got:      '$actual'"
    return 1
  fi
}

assert_success() {
  local command="$1"
  local message="$2"

  TESTS_RUN=$((TESTS_RUN + 1))

  if eval "$command" >/dev/null 2>&1; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} $message"
    return 0
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} $message"
    echo -e "  Command failed: $command"
    return 1
  fi
}

assert_failure() {
  local command="$1"
  local message="$2"

  TESTS_RUN=$((TESTS_RUN + 1))

  if eval "$command" >/dev/null 2>&1; then
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} $message"
    echo -e "  Expected failure but command succeeded"
    return 1
  else
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} $message"
    return 0
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ "$haystack" == *"$needle"* ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} $message"
    return 0
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} $message"
    echo -e "  Haystack: '$haystack'"
    echo -e "  Needle:   '$needle'"
    return 1
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ "$haystack" != *"$needle"* ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} $message"
    return 0
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} $message"
    echo -e "  Should not contain: '$needle'"
    return 1
  fi
}

create_mock_config() {
  local config_dir="$1"
  mkdir -p "$config_dir/.flow"

  cat > "$config_dir/.flow/teach-config.yml" <<'EOF'
course:
  name: "STAT 545"
  code: "STAT 545"
  semester: "Spring"
  year: 2025

semester_info:
  start_date: "2025-01-13"
  end_date: "2025-05-02"

  weeks:
    - number: 1
      start_date: "2025-01-13"
      topic: "Introduction"
    - number: 2
      start_date: "2025-01-20"
      topic: "DAGs"
    - number: 3
      start_date: "2025-01-27"
      topic: "Confounding"

  deadlines:
    hw1:
      week: 2
      offset_days: 2
    hw2:
      due_date: "2025-02-03"

  exams:
    - name: "Midterm 1"
      date: "2025-02-24"

  holidays:
    - name: "Spring Break"
      date: "2025-03-10"
EOF
}

create_mock_files() {
  local dir="$1"

  mkdir -p "$dir/assignments"
  mkdir -p "$dir/lectures"

  # Create assignment with dates
  cat > "$dir/assignments/hw1.qmd" <<'EOF'
---
title: "Homework 1"
due: "2025-01-20"
published: "2025-01-13"
---

This assignment is due on **January 20, 2025** at 11:59 PM.
EOF

  # Create lecture with dates
  cat > "$dir/lectures/week01.qmd" <<'EOF'
---
title: "Week 1: Introduction"
date: "2025-01-13"
---

Welcome to Week 1, starting January 13, 2025.
EOF

  # Create syllabus with multiple dates
  cat > "$dir/syllabus.qmd" <<'EOF'
---
title: "Course Syllabus"
semester_start: "2025-01-13"
semester_end: "2025-05-02"
---

Course runs from January 13, 2025 to May 2, 2025.
EOF
}

# ============================================================================
# TEST SUITE 1: Dependency Checks
# ============================================================================

test_dependency_checks() {
  echo ""
  echo "Test Suite 1: Dependency Checks"
  echo "================================"

  # Save current dir and create test environment
  local orig_dir="$PWD"
  local test_workspace="$TEST_DIR/workspace1"
  mkdir -p "$test_workspace"
  cd "$test_workspace"

  # Test 1: Missing config file
  local output
  output=$(_teach_dates_sync 2>&1)
  assert_contains "$output" "No .flow/teach-config.yml found" "Error when config missing"

  # Test 2: Config file exists
  create_mock_config "$test_workspace"
  assert_success "[[ -f .flow/teach-config.yml ]]" "Config file created"

  # Test 3: yq dependency (should exist in test environment)
  assert_success "command -v yq >/dev/null 2>&1" "yq command available"

  cd "$orig_dir"
}

# ============================================================================
# TEST SUITE 2: Flag Parsing
# ============================================================================

test_flag_parsing() {
  echo ""
  echo "Test Suite 2: Flag Parsing"
  echo "=========================="

  local orig_dir="$PWD"
  local test_workspace="$TEST_DIR/workspace2"
  mkdir -p "$test_workspace"
  cd "$test_workspace"
  create_mock_config "$test_workspace"
  create_mock_files "$test_workspace"

  # Test --dry-run flag
  local output
  output=$(_teach_dates_sync --dry-run 2>&1)
  assert_contains "$output" "Dry-run mode" "Dry-run flag recognized"

  # Test --help flag
  output=$(_teach_dates_sync --help 2>&1)
  assert_contains "$output" "sync" "Help displays sync command"

  # Test invalid flag
  output=$(_teach_dates_sync --invalid-flag 2>&1)
  assert_contains "$output" "Unknown flag" "Invalid flag rejected"

  cd "$orig_dir"
}

# ============================================================================
# TEST SUITE 3: File Filtering
# ============================================================================

test_file_filtering() {
  echo ""
  echo "Test Suite 3: File Filtering"
  echo "============================="

  local orig_dir="$PWD"
  local test_workspace="$TEST_DIR/workspace3"
  mkdir -p "$test_workspace"
  cd "$test_workspace"
  create_mock_config "$test_workspace"
  create_mock_files "$test_workspace"

  # Test --assignments filter
  local output
  output=$(_teach_dates_sync --assignments --dry-run 2>&1)
  assert_contains "$output" "hw1.qmd" "Assignments filter includes assignments"
  assert_not_contains "$output" "week01.qmd" "Assignments filter excludes lectures"

  # Test --lectures filter
  output=$(_teach_dates_sync --lectures --dry-run 2>&1)
  assert_contains "$output" "Found 1 files" "Lectures filter finds 1 file"
  assert_contains "$output" "Filter: lectures" "Lectures filter applied"

  # Test --syllabus filter
  output=$(_teach_dates_sync --syllabus --dry-run 2>&1)
  assert_contains "$output" "Found 1 files" "Syllabus filter finds 1 file"
  assert_contains "$output" "Filter: syllabus" "Syllabus filter applied"

  # Test no filter (all files)
  output=$(_teach_dates_sync --dry-run 2>&1)
  assert_contains "$output" "Found 3 files" "No filter finds all 3 files"

  cd "$orig_dir"
}

# ============================================================================
# TEST SUITE 4: Dry-Run Mode
# ============================================================================

test_dry_run_mode() {
  echo ""
  echo "Test Suite 4: Dry-Run Mode"
  echo "=========================="

  local orig_dir="$PWD"
  local test_workspace="$TEST_DIR/workspace4"
  mkdir -p "$test_workspace"
  cd "$test_workspace"
  create_mock_config "$test_workspace"
  create_mock_files "$test_workspace"

  # Save original file content
  local original_hw1=$(cat assignments/hw1.qmd)

  # Run sync in dry-run mode
  local output
  output=$(_teach_dates_sync --dry-run 2>&1)

  # Verify no changes made
  local current_hw1=$(cat assignments/hw1.qmd)
  assert_equals "$original_hw1" "$current_hw1" "Dry-run does not modify files"

  # Verify preview shown
  assert_contains "$output" "Dry-run mode" "Dry-run mode message shown"
  assert_contains "$output" "No changes made" "No changes message shown"

  cd "$orig_dir"
}

# ============================================================================
# TEST SUITE 5: Force Mode
# ============================================================================

test_force_mode() {
  echo ""
  echo "Test Suite 5: Force Mode"
  echo "========================"

  local orig_dir="$PWD"
  local test_workspace="$TEST_DIR/workspace5"
  mkdir -p "$test_workspace"
  cd "$test_workspace"
  create_mock_config "$test_workspace"
  create_mock_files "$test_workspace"

  # Run sync with --force (no prompts)
  local output
  output=$(_teach_dates_sync --force 2>&1 <<< "")

  # Verify files updated (hw1 due date should change from 2025-01-20 to 2025-01-22)
  local updated_due
  updated_due=$(yq eval '.due' assignments/hw1.qmd 2>/dev/null)
  assert_equals "2025-01-22" "$updated_due" "Force mode applies changes without prompts"

  cd "$orig_dir"
}

# ============================================================================
# TEST SUITE 6: Status Command
# ============================================================================

test_status_command() {
  echo ""
  echo "Test Suite 6: Status Command"
  echo "============================="

  local orig_dir="$PWD"
  local test_workspace="$TEST_DIR/workspace6"
  mkdir -p "$test_workspace"
  cd "$test_workspace"
  create_mock_config "$test_workspace"
  create_mock_files "$test_workspace"

  # Test status shows summary
  local output
  output=$(_teach_dates_status 2>&1)
  assert_contains "$output" "Date Status" "Status command shows header"
  assert_contains "$output" "Teaching Files Found" "Status shows file count"
  assert_contains "$output" "Config Dates Loaded" "Status shows config dates count"

  cd "$orig_dir"
}

# ============================================================================
# TEST SUITE 7: Validate Command
# ============================================================================

test_validate_command() {
  echo ""
  echo "Test Suite 7: Validate Command"
  echo "==============================="

  local orig_dir="$PWD"
  local test_workspace="$TEST_DIR/workspace7"
  mkdir -p "$test_workspace"
  cd "$test_workspace"
  create_mock_config "$test_workspace"

  # Test validate with valid config
  local output
  output=$(_teach_dates_validate 2>&1)
  assert_contains "$output" "valid" "Validate confirms valid config"

  # Test validate with invalid config
  echo "invalid: yaml: content:" > .flow/teach-config.yml
  output=$(_teach_dates_validate 2>&1)
  assert_contains "$output" "failed" "Validate detects invalid config"

  cd "$orig_dir"
}

# ============================================================================
# TEST SUITE 8: Error Handling
# ============================================================================

test_error_handling() {
  echo ""
  echo "Test Suite 8: Error Handling"
  echo "============================="

  local orig_dir="$PWD"
  local test_workspace="$TEST_DIR/workspace8"
  mkdir -p "$test_workspace"
  cd "$test_workspace"

  # Test 1: Missing config directory
  local output
  output=$(_teach_dates_sync 2>&1)
  assert_contains "$output" "No .flow/teach-config.yml found" "Error message for missing config"

  # Test 2: Unreadable file
  create_mock_config "$test_workspace"
  create_mock_files "$test_workspace"
  chmod 000 assignments/hw1.qmd
  output=$(_teach_dates_sync --force 2>&1)
  # May fail to update unreadable file
  chmod 644 assignments/hw1.qmd

  cd "$orig_dir"
}

# ============================================================================
# TEST SUITE 9: Interactive Prompts (Simulated)
# ============================================================================

test_interactive_prompts() {
  echo ""
  echo "Test Suite 9: Interactive Prompts"
  echo "=================================="

  local orig_dir="$PWD"
  local test_workspace="$TEST_DIR/workspace9"
  mkdir -p "$test_workspace"
  cd "$test_workspace"
  create_mock_config "$test_workspace"
  create_mock_files "$test_workspace"

  # Simulate 'n' (skip)
  local output
  output=$(_teach_dates_sync 2>&1 <<< "n")
  assert_contains "$output" "Skipped" "Interactive prompt 'n' skips changes"

  # Simulate 'y' (apply)
  create_mock_files "$test_workspace"  # Reset files
  output=$(_teach_dates_sync 2>&1 <<< "y")
  local updated_due
  updated_due=$(yq eval '.due' assignments/hw1.qmd 2>/dev/null)
  assert_equals "2025-01-22" "$updated_due" "Interactive prompt 'y' applies changes"

  cd "$orig_dir"
}

# ============================================================================
# TEST SUITE 10: Help System
# ============================================================================

test_help_system() {
  echo ""
  echo "Test Suite 10: Help System"
  echo "=========================="

  # Test sync help
  local output
  output=$(_teach_dates_sync --help 2>&1)
  assert_contains "$output" "teach dates sync" "Sync help shows command"
  assert_contains "$output" "--dry-run" "Sync help shows --dry-run flag"
  assert_contains "$output" "--force" "Sync help shows --force flag"

  # Test main help
  output=$(_teach_dates_help 2>&1)
  assert_contains "$output" "teach dates" "Main help shows commands"
  assert_contains "$output" "sync" "Main help lists sync"
  assert_contains "$output" "status" "Main help lists status"
  assert_contains "$output" "init" "Main help lists init"
  assert_contains "$output" "validate" "Main help lists validate"
}

# ============================================================================
# RUN ALL TESTS
# ============================================================================

echo ""
echo "========================================="
echo "Teach Dates Dispatcher Unit Tests"
echo "========================================="

test_dependency_checks
test_flag_parsing
test_file_filtering
test_dry_run_mode
test_force_mode
test_status_command
test_validate_command
test_error_handling
test_interactive_prompts
test_help_system

# Print summary
echo ""
echo "========================================="
echo "Test Summary"
echo "========================================="
echo -e "Tests run:    $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo -e "${GREEN}✓ All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}✗ Some tests failed${NC}"
  exit 1
fi
