#!/usr/bin/env zsh
# Test Suite: Date Parser Module
# Tests all 8 core functions in lib/date-parser.zsh

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
source "$(dirname "$0")/../lib/date-parser.zsh"

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

# ============================================================================
# TEST SUITE 1: Date Normalization
# ============================================================================

test_date_normalize() {
  echo ""
  echo "Test Suite 1: _date_normalize"
  echo "================================"

  # ISO format (already normalized)
  local result
  result=$(_date_normalize "2025-01-22")
  assert_equals "2025-01-22" "$result" "ISO format passes through"

  # US format: M/D/YYYY
  result=$(_date_normalize "1/22/2025")
  assert_equals "2025-01-22" "$result" "US format M/D/YYYY"

  result=$(_date_normalize "12/31/2025")
  assert_equals "2025-12-31" "$result" "US format MM/DD/YYYY"

  # Long month format
  result=$(_date_normalize "January 22, 2025")
  assert_equals "2025-01-22" "$result" "Long month format"

  result=$(_date_normalize "December 31, 2025")
  assert_equals "2025-12-31" "$result" "Long month December"

  # Abbreviated month format
  result=$(_date_normalize "Jan 22, 2025")
  assert_equals "2025-01-22" "$result" "Abbreviated month format"

  result=$(_date_normalize "Dec 31, 2025")
  assert_equals "2025-12-31" "$result" "Abbreviated month Dec"

  # Month without year (infers current year)
  local current_year=$(date +%Y)
  result=$(_date_normalize "Jan 22")
  assert_equals "${current_year}-01-22" "$result" "Month without year (infers current)"

  # Edge cases
  result=$(_date_normalize "Feb 29, 2024")
  assert_equals "2024-02-29" "$result" "Leap year date"

  result=$(_date_normalize "")
  assert_equals "" "$result" "Empty string returns empty"
}

# ============================================================================
# TEST SUITE 2: Date Arithmetic
# ============================================================================

test_date_add_days() {
  echo ""
  echo "Test Suite 2: _date_add_days"
  echo "============================="

  # Positive offsets
  local result
  result=$(_date_add_days "2025-01-20" 2)
  assert_equals "2025-01-22" "$result" "Add 2 days"

  result=$(_date_add_days "2025-01-31" 1)
  assert_equals "2025-02-01" "$result" "Add 1 day (month boundary)"

  result=$(_date_add_days "2025-12-31" 1)
  assert_equals "2026-01-01" "$result" "Add 1 day (year boundary)"

  # Negative offsets
  result=$(_date_add_days "2025-01-22" -2)
  assert_equals "2025-01-20" "$result" "Subtract 2 days"

  result=$(_date_add_days "2025-02-01" -1)
  assert_equals "2025-01-31" "$result" "Subtract 1 day (month boundary)"

  # Zero offset
  result=$(_date_add_days "2025-01-22" 0)
  assert_equals "2025-01-22" "$result" "Add 0 days (no change)"

  # Large offsets
  result=$(_date_add_days "2025-01-01" 365)
  assert_equals "2026-01-01" "$result" "Add 365 days (1 year)"
}

# ============================================================================
# TEST SUITE 3: YAML Frontmatter Parsing
# ============================================================================

test_yaml_parsing() {
  echo ""
  echo "Test Suite 3: _date_parse_quarto_yaml"
  echo "======================================"

  # Create test file with YAML frontmatter
  local test_file="$TEST_DIR/test.qmd"
  cat > "$test_file" <<'EOF'
---
title: "Test Assignment"
due: "2025-01-22"
published: "1/15/2025"
date-modified: last-modified
---

# Assignment Content
EOF

  # Test extracting ISO date
  local result
  result=$(_date_parse_quarto_yaml "$test_file" "due")
  assert_equals "2025-01-22" "$result" "Extract ISO date from YAML"

  # Test extracting US date (should normalize)
  result=$(_date_parse_quarto_yaml "$test_file" "published")
  assert_equals "2025-01-15" "$result" "Extract and normalize US date"

  # Test dynamic date (should return empty)
  result=$(_date_parse_quarto_yaml "$test_file" "date-modified")
  assert_equals "" "$result" "Skip dynamic date value"

  # Test non-existent field
  result=$(_date_parse_quarto_yaml "$test_file" "nonexistent")
  assert_equals "" "$result" "Non-existent field returns empty"

  # Test nested YAML
  cat > "$test_file" <<'EOF'
---
exam:
  date: "2025-02-24"
  time: "2:00 PM"
---
EOF

  result=$(_date_parse_quarto_yaml "$test_file" "exam.date")
  assert_equals "2025-02-24" "$result" "Extract nested YAML date"
}

# ============================================================================
# TEST SUITE 4: Markdown Inline Parsing
# ============================================================================

test_markdown_inline() {
  echo ""
  echo "Test Suite 4: _date_parse_markdown_inline"
  echo "=========================================="

  # Create test file with inline dates
  # NOTE: Line numbers count ALL lines including blanks
  local test_file="$TEST_DIR/test.md"
  cat > "$test_file" <<'EOF'
# Course Schedule

This assignment is due on **January 22, 2025** at 11:59 PM.

Week 2 starts on Aug 26, 2025 and covers DAGs.

The exam will be held on Feb 24, 2025.

Submit by Jan 15, 2025.
EOF

  # Test extracting inline dates
  local results
  results=$(_date_parse_markdown_inline "$test_file")

  # Actual line numbers: 3, 5, 7, 9 (NOT 2, 4, 6, 8 because of blank lines)
  assert_contains "$results" "3:2025-01-22" "Extract inline date from line 3"
  assert_contains "$results" "5:2025-08-26" "Extract abbreviated date from line 5"
  assert_contains "$results" "7:2025-02-24" "Extract date from line 7"
  assert_contains "$results" "9:2025-01-15" "Extract abbreviated date from line 9"

  # Count number of dates found
  local count=$(echo "$results" | grep "^[0-9]*:" | wc -l | tr -d ' ')
  assert_equals "4" "$count" "Found 4 inline dates"
}

# ============================================================================
# TEST SUITE 5: File Discovery
# ============================================================================

test_file_discovery() {
  echo ""
  echo "Test Suite 5: _date_find_teaching_files"
  echo "========================================"

  # Create mock teaching directory structure
  mkdir -p "$TEST_DIR/assignments"
  mkdir -p "$TEST_DIR/lectures"
  mkdir -p "$TEST_DIR/exams"

  touch "$TEST_DIR/assignments/hw1.qmd"
  touch "$TEST_DIR/assignments/hw2.qmd"
  touch "$TEST_DIR/lectures/week01.qmd"
  touch "$TEST_DIR/exams/midterm.md"
  touch "$TEST_DIR/syllabus.qmd"
  touch "$TEST_DIR/README.md"

  # Test file discovery
  local results
  results=$(_date_find_teaching_files "$TEST_DIR")

  assert_contains "$results" "hw1.qmd" "Found assignment file"
  assert_contains "$results" "hw2.qmd" "Found assignment file"
  assert_contains "$results" "week01.qmd" "Found lecture file"
  assert_contains "$results" "midterm.md" "Found exam file"
  assert_contains "$results" "syllabus.qmd" "Found syllabus file"

  # Count files
  local count=$(echo "$results" | wc -l | tr -d ' ')
  assert_equals "6" "$count" "Found 6 teaching files"
}

# ============================================================================
# TEST SUITE 6: Config Loading
# ============================================================================

test_config_loading() {
  echo ""
  echo "Test Suite 6: _date_load_config"
  echo "================================"

  # Create mock config file
  local config_file="$TEST_DIR/teach-config.yml"
  cat > "$config_file" <<'EOF'
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

  # Load config
  local -A CONFIG_DATES
  eval "$(_date_load_config "$config_file")"

  # Test week dates
  assert_equals "2025-01-13" "${CONFIG_DATES[week_1]}" "Load week 1 date"
  assert_equals "2025-01-20" "${CONFIG_DATES[week_2]}" "Load week 2 date"

  # Test deadline (relative - should compute)
  assert_equals "2025-01-22" "${CONFIG_DATES[deadline_hw1]}" "Compute relative deadline"

  # Test deadline (absolute)
  assert_equals "2025-02-03" "${CONFIG_DATES[deadline_hw2]}" "Load absolute deadline"

  # Test exam date
  assert_equals "2025-02-24" "${CONFIG_DATES[exam_midterm_1]}" "Load exam date"

  # Test holiday date
  assert_equals "2025-03-10" "${CONFIG_DATES[holiday_spring_break]}" "Load holiday date"
}

# ============================================================================
# TEST SUITE 7: Week + Offset Computation
# ============================================================================

test_week_computation() {
  echo ""
  echo "Test Suite 7: _date_compute_from_week"
  echo "======================================"

  # Create mock config (reuse from previous test)
  local config_file="$TEST_DIR/teach-config.yml"

  # Test computing date from week + offset
  local result
  result=$(_date_compute_from_week 2 2 "$config_file")
  assert_equals "2025-01-22" "$result" "Compute week 2 + 2 days"

  result=$(_date_compute_from_week 1 0 "$config_file")
  assert_equals "2025-01-13" "$result" "Compute week 1 + 0 days"

  result=$(_date_compute_from_week 2 -1 "$config_file")
  assert_equals "2025-01-19" "$result" "Compute week 2 - 1 day"

  result=$(_date_compute_from_week 1 7 "$config_file")
  assert_equals "2025-01-20" "$result" "Compute week 1 + 7 days (next week)"
}

# ============================================================================
# TEST SUITE 8: File Modification
# ============================================================================

test_file_modification() {
  echo ""
  echo "Test Suite 8: _date_apply_to_file"
  echo "=================================="

  # Create test file
  local test_file="$TEST_DIR/hw1.qmd"
  cat > "$test_file" <<'EOF'
---
title: "Homework 1"
due: "2025-01-20"
---

This assignment is due on January 20, 2025.
EOF

  # Apply date changes
  local -a changes=(
    "due:2025-01-20:2025-01-22"
  )

  _date_apply_to_file "$test_file" "${changes[@]}"

  # Verify changes
  local new_yaml_date
  new_yaml_date=$(yq eval '.due' "$test_file" 2>/dev/null)
  assert_equals "2025-01-22" "$new_yaml_date" "YAML date updated"

  # Verify inline date was also updated
  assert_success "grep -q 'January 22, 2025' '$test_file'" "Inline date updated (approx check)"
}

# ============================================================================
# RUN ALL TESTS
# ============================================================================

echo ""
echo "========================================="
echo "Date Parser Module Test Suite"
echo "========================================="

test_date_normalize
test_date_add_days
test_yaml_parsing
test_markdown_inline
test_file_discovery
test_config_loading
test_week_computation
test_file_modification

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
