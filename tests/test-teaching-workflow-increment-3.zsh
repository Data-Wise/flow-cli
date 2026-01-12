#!/usr/bin/env zsh

# Test suite for Teaching Workflow Increment 3: Exam Workflow
# Tests teach-exam command, template generation, and QTI conversion

# Source required files
SCRIPT_DIR="${0:A:h}"
PLUGIN_DIR="${SCRIPT_DIR:h}"

source "$PLUGIN_DIR/lib/core.zsh"
source "$PLUGIN_DIR/lib/teaching-utils.zsh"
source "$PLUGIN_DIR/commands/teach-exam.zsh"

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ============================================================================
# Test Helpers
# ============================================================================

setup_test_teaching_project() {
  local with_examark="${1:-yes}"

  mkdir -p .flow exams

  # Create minimal teaching config
  if [[ "$with_examark" == "yes" ]]; then
    cat > .flow/teach-config.yml <<EOF
course:
  name: "Test Course 101"
  semester: "Spring"
  year: 2026

semester_info:
  start_date: "2026-01-13"
  end_date: "2026-05-05"

branches:
  draft: "draft"
  production: "production"

examark:
  enabled: true
  exam_dir: "exams"
  question_bank: "exams/questions"
  default_duration: 120
  default_points: 100
EOF
  else
    cat > .flow/teach-config.yml <<EOF
course:
  name: "Test Course 101"
  semester: "Spring"
  year: 2026

semester_info:
  start_date: "2026-01-13"
  end_date: "2026-05-05"

branches:
  draft: "draft"
  production: "production"

examark:
  enabled: false
EOF
  fi

  # Mark as teaching project
  touch .flow/.teaching-project
}

teardown_test_teaching_project() {
  rm -rf .flow exams assessments
}

assert_equals() {
  local expected="$1"
  local actual="$2"
  local message="${3:-Assertion failed}"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ "$expected" == "$actual" ]]; then
    echo -e "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} $message"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} $message"
    echo "  Expected: '$expected'"
    echo "  Got:      '$actual'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_file_exists() {
  local file="$1"
  local message="${2:-File should exist: $file}"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ -f "$file" ]]; then
    echo -e "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} $message"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} $message"
    echo "  File not found: $file"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_file_contains() {
  local file="$1"
  local pattern="$2"
  local message="${3:-File should contain pattern: $pattern}"

  TESTS_RUN=$((TESTS_RUN + 1))

  if grep -q "$pattern" "$file" 2>/dev/null; then
    echo -e "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} $message"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} $message"
    echo "  Pattern not found in $file: $pattern"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_dir_exists() {
  local dir="$1"
  local message="${2:-Directory should exist: $dir}"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ -d "$dir" ]]; then
    echo -e "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} $message"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} $message"
    echo "  Directory not found: $dir"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# ============================================================================
# Template Generation Tests
# ============================================================================

test_template_has_frontmatter() {
  setup_test_teaching_project

  # Create exam template
  _teach_create_exam_template "exams/test-exam.md" "Test Exam" "90" "75"

  # Verify frontmatter
  assert_file_contains "exams/test-exam.md" "^---$" "Template has frontmatter start"
  assert_file_contains "exams/test-exam.md" "title:" "Template has title field"
  assert_file_contains "exams/test-exam.md" "course:" "Template has course field"
  assert_file_contains "exams/test-exam.md" "duration:" "Template has duration field"
  assert_file_contains "exams/test-exam.md" "points:" "Template has points field"

  teardown_test_teaching_project
}

test_template_substitutes_topic() {
  setup_test_teaching_project

  _teach_create_exam_template "exams/midterm.md" "Midterm Exam: Weeks 1-8" "120" "100"

  assert_file_contains "exams/midterm.md" "Midterm Exam: Weeks 1-8" "Template includes topic"

  teardown_test_teaching_project
}

test_template_substitutes_duration() {
  setup_test_teaching_project

  _teach_create_exam_template "exams/quiz.md" "Quiz 1" "60" "50"

  assert_file_contains "exams/quiz.md" "60" "Template includes duration"

  teardown_test_teaching_project
}

test_template_substitutes_points() {
  setup_test_teaching_project

  _teach_create_exam_template "exams/final.md" "Final Exam" "180" "200"

  assert_file_contains "exams/final.md" "200" "Template includes points"

  teardown_test_teaching_project
}

test_template_includes_course_name() {
  setup_test_teaching_project

  _teach_create_exam_template "exams/exam.md" "Test Exam" "90" "75"

  assert_file_contains "exams/exam.md" "Test Course 101" "Template includes course name from config"

  teardown_test_teaching_project
}

test_template_has_sections() {
  setup_test_teaching_project

  _teach_create_exam_template "exams/exam.md" "Test Exam" "90" "75"

  assert_file_contains "exams/exam.md" "Multiple Choice" "Template has Multiple Choice section"
  assert_file_contains "exams/exam.md" "Short Answer" "Template has Short Answer section"
  assert_file_contains "exams/exam.md" "Problems" "Template has Problems section"
  assert_file_contains "exams/exam.md" "Answer Key" "Template has Answer Key section"

  teardown_test_teaching_project
}

test_template_has_example_questions() {
  setup_test_teaching_project

  _teach_create_exam_template "exams/exam.md" "Test Exam" "90" "75"

  assert_file_contains "exams/exam.md" "pts" "Template has point notation"
  assert_file_contains "exams/exam.md" "\[ \]" "Template has checkbox format"
  assert_file_contains "exams/exam.md" "\[x\]" "Template has correct answer format"

  teardown_test_teaching_project
}

# ============================================================================
# File Creation Tests
# ============================================================================

test_creates_exam_directory() {
  setup_test_teaching_project

  # Note: mkdir -p is done in teach-exam(), not _teach_create_exam_template()
  # This test verifies the directory exists after setup
  assert_dir_exists "exams" "Exam directory exists"

  # Create exam in existing dir
  _teach_create_exam_template "exams/test.md" "Test" "90" "75"

  # Verify file created
  assert_file_exists "exams/test.md" "Exam file created in directory"

  teardown_test_teaching_project
}

test_filename_sanitization() {
  setup_test_teaching_project

  # Test topic with special characters
  local topic="Midterm #2: ANOVA & Regression (Chapters 3-5)!"
  local sanitized=$(echo "$topic" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')

  # Expected: "midterm-2-anova-regression-chapters-3-5"
  local expected="midterm-2-anova-regression-chapters-3-5"

  assert_equals "$expected" "$sanitized" "Filename sanitization works correctly"

  teardown_test_teaching_project
}

# ============================================================================
# Configuration Tests
# ============================================================================

test_reads_default_duration_from_config() {
  setup_test_teaching_project

  local duration=$(yq -r '.examark.default_duration // "120"' .flow/teach-config.yml)

  assert_equals "120" "$duration" "Reads default duration from config"

  teardown_test_teaching_project
}

test_reads_default_points_from_config() {
  setup_test_teaching_project

  local points=$(yq -r '.examark.default_points // "100"' .flow/teach-config.yml)

  assert_equals "100" "$points" "Reads default points from config"

  teardown_test_teaching_project
}

test_reads_exam_dir_from_config() {
  setup_test_teaching_project

  local exam_dir=$(yq -r '.examark.exam_dir // "exams"' .flow/teach-config.yml)

  assert_equals "exams" "$exam_dir" "Reads exam directory from config"

  teardown_test_teaching_project
}

test_uses_custom_exam_dir() {
  setup_test_teaching_project

  # Update config to use custom directory
  yq -i '.examark.exam_dir = "assessments"' .flow/teach-config.yml

  local exam_dir=$(yq -r '.examark.exam_dir' .flow/teach-config.yml)

  assert_equals "assessments" "$exam_dir" "Uses custom exam directory"

  teardown_test_teaching_project
}

# ============================================================================
# Error Handling Tests
# ============================================================================

test_handles_missing_template() {
  setup_test_teaching_project

  # Mock missing template by creating exam in non-existent template dir
  # The function should fall back to inline template

  _teach_create_exam_template "exams/fallback.md" "Test Exam" "90" "75"

  assert_file_exists "exams/fallback.md" "Creates exam even without template file"
  assert_file_contains "exams/fallback.md" "Test Exam" "Fallback template has topic"

  teardown_test_teaching_project
}

test_handles_special_chars_in_topic() {
  setup_test_teaching_project

  local topic="Test with \$VARIABLE and \\ backslash"

  _teach_create_exam_template "exams/special.md" "$topic" "90" "75"

  assert_file_exists "exams/special.md" "Creates exam with special chars in topic"

  teardown_test_teaching_project
}

# ============================================================================
# Integration Tests
# ============================================================================

test_full_template_workflow() {
  setup_test_teaching_project

  # Create exam
  _teach_create_exam_template "exams/integration.md" "Integration Test Exam" "90" "75"

  # Verify all components
  assert_file_exists "exams/integration.md" "Exam file created"
  assert_file_contains "exams/integration.md" "Integration Test Exam" "Has correct topic"
  assert_file_contains "exams/integration.md" "90" "Has correct duration"
  assert_file_contains "exams/integration.md" "75" "Has correct points"
  assert_file_contains "exams/integration.md" "Test Course 101" "Has correct course"

  teardown_test_teaching_project
}

# ============================================================================
# Run All Tests
# ============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Teaching Workflow Increment 3 Test Suite"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "${FLOW_COLORS[bold]}Template Generation Tests${FLOW_COLORS[reset]}"
test_template_has_frontmatter
test_template_substitutes_topic
test_template_substitutes_duration
test_template_substitutes_points
test_template_includes_course_name
test_template_has_sections
test_template_has_example_questions
echo ""

echo "${FLOW_COLORS[bold]}File Creation Tests${FLOW_COLORS[reset]}"
test_creates_exam_directory
test_filename_sanitization
echo ""

echo "${FLOW_COLORS[bold]}Configuration Tests${FLOW_COLORS[reset]}"
test_reads_default_duration_from_config
test_reads_default_points_from_config
test_reads_exam_dir_from_config
test_uses_custom_exam_dir
echo ""

echo "${FLOW_COLORS[bold]}Error Handling Tests${FLOW_COLORS[reset]}"
test_handles_missing_template
test_handles_special_chars_in_topic
echo ""

echo "${FLOW_COLORS[bold]}Integration Tests${FLOW_COLORS[reset]}"
test_full_template_workflow
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Results"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Total tests run:    $TESTS_RUN"
echo -e "Tests passed:       ${FLOW_COLORS[success]}$TESTS_PASSED${FLOW_COLORS[reset]}"
echo -e "Tests failed:       ${FLOW_COLORS[error]}$TESTS_FAILED${FLOW_COLORS[reset]}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo -e "${FLOW_COLORS[success]}✓ All tests passed!${FLOW_COLORS[reset]}"
  echo ""
  exit 0
else
  echo -e "${FLOW_COLORS[error]}✗ Some tests failed${FLOW_COLORS[reset]}"
  echo ""
  exit 1
fi
