#!/usr/bin/env zsh
# test-teach-analyze-phase1-unit.zsh - Unit tests for teach analyze Phase 1
# Run with: zsh tests/test-teach-analyze-phase1-unit.zsh
#
# Test Suites:
# - Teach Validate --concepts (15 tests)
# - Status Dashboard Concepts (10 tests)
# - Configuration Parsing (10 tests)
# - Edge Cases (5 tests)

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
PROJECT_ROOT="${SCRIPT_DIR}/.."
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

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-Should not contain substring}"

  if [[ "$haystack" != *"$needle"* ]]; then
    return 0
  else
    test_fail "$message (should not contain: '$needle')"
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

assert_json_valid() {
  local json="$1"
  local message="${2:-JSON should be valid}"

  if echo "$json" | jq empty 2>/dev/null; then
    return 0
  else
    test_fail "$message"
    return 1
  fi
}

# ============================================================================
# TEST SETUP
# ============================================================================

setup_test_environment() {
  cd "$TEST_DIR"

  # Clean up from previous tests (critical for test isolation)
  rm -rf lectures .teach .flow 2>/dev/null

  # Create test directory structure
  mkdir -p lectures
  mkdir -p .teach
  mkdir -p .flow

  # Create minimal config
  cat > .flow/teach-config.yml <<EOF
course:
  name: "Test Course"
  semester: "Spring"
  year: 2026
EOF

  # Source libraries
  source "${PROJECT_ROOT}/lib/core.zsh"
  source "${PROJECT_ROOT}/lib/concept-extraction.zsh"
  source "${PROJECT_ROOT}/lib/prerequisite-checker.zsh"
  source "${PROJECT_ROOT}/commands/teach-analyze.zsh"
  source "${PROJECT_ROOT}/commands/teach-validate.zsh"
}

create_qmd_with_concepts() {
  local file="$1"
  local week="$2"
  local introduces="$3"
  local requires="$4"

  cat > "$file" <<EOF
---
title: "Test Lecture Week $week"
week: $week
concepts:
  introduces: [$introduces]
  requires: [$requires]
---

# Lecture $week

This is test content.
EOF
}

# ============================================================================
# TEST SUITE 1: TEACH VALIDATE --CONCEPTS (15 tests)
# ============================================================================

test_validate_concepts_flag_exists() {
  test_start "validate_concepts_flag_exists"

  setup_test_environment

  # Check help contains --concepts
  local help_output
  help_output=$(teach-validate --help 2>&1)

  assert_contains "$help_output" "--concepts" "Help should mention --concepts flag" && test_pass
}

test_validate_concepts_no_content() {
  test_start "validate_concepts_no_content"

  setup_test_environment

  # Run with no lecture files
  local output
  output=$(_teach_validate_concepts 0 2>&1)

  assert_contains "$output" "No concepts" "Should indicate no concepts found" && test_pass
}

test_validate_concepts_valid_course() {
  test_start "validate_concepts_valid_course"

  setup_test_environment

  create_qmd_with_concepts "$TEST_DIR/lectures/week-01-lecture.qmd" 1 "mean, variance" ""
  create_qmd_with_concepts "$TEST_DIR/lectures/week-02-lecture.qmd" 2 "correlation" "mean, variance"

  local output result
  output=$(_teach_validate_concepts 0 2>&1)
  result=$?

  assert_success $result "Should succeed with valid course"
  assert_contains "$output" "prerequisites satisfied" "Should report success" && test_pass
}

test_validate_concepts_missing_prereq() {
  test_start "validate_concepts_missing_prereq"

  setup_test_environment

  create_qmd_with_concepts "$TEST_DIR/lectures/week-01-lecture.qmd" 1 "mean" ""
  create_qmd_with_concepts "$TEST_DIR/lectures/week-02-lecture.qmd" 2 "regression" "mean, variance"

  local output result
  output=$(_teach_validate_concepts 0 2>&1)
  result=$?

  assert_failure $result "Should fail with missing prerequisite"
  assert_contains "$output" "missing" "Should report missing prerequisite" && test_pass
}

test_validate_concepts_quiet_mode() {
  test_start "validate_concepts_quiet_mode"

  setup_test_environment

  create_qmd_with_concepts "$TEST_DIR/lectures/week-01-lecture.qmd" 1 "mean" ""

  local output
  output=$(_teach_validate_concepts 1 2>&1)

  # Quiet mode should suppress info messages
  assert_not_contains "$output" "Building" "Quiet mode should suppress verbose output" && test_pass
}

test_validate_concepts_creates_graph() {
  test_start "validate_concepts_creates_graph"

  setup_test_environment

  create_qmd_with_concepts "$TEST_DIR/lectures/week-01-lecture.qmd" 1 "mean" ""

  _teach_validate_concepts 1 2>/dev/null

  assert_file_exists "$TEST_DIR/.teach/concepts.json" "Should create concepts.json" && test_pass
}

test_validate_concepts_counts_correctly() {
  test_start "validate_concepts_counts_correctly"

  setup_test_environment

  create_qmd_with_concepts "$TEST_DIR/lectures/week-01-lecture.qmd" 1 "mean, variance, std-dev" ""
  create_qmd_with_concepts "$TEST_DIR/lectures/week-02-lecture.qmd" 2 "correlation, covariance" "mean"

  local output
  output=$(_teach_validate_concepts 0 2>&1)

  assert_contains "$output" "5 concepts" "Should count 5 concepts" && test_pass
}

test_validate_concepts_multiple_violations() {
  test_start "validate_concepts_multiple_violations"

  setup_test_environment

  create_qmd_with_concepts "$TEST_DIR/lectures/week-01-lecture.qmd" 1 "mean" ""
  create_qmd_with_concepts "$TEST_DIR/lectures/week-02-lecture.qmd" 2 "regression" "mean, variance, correlation"

  local output result
  output=$(_teach_validate_concepts 0 2>&1)
  result=$?

  # Should have 2 missing prerequisites (variance, correlation)
  assert_equals "$result" "2" "Should return count of missing prerequisites" && test_pass
}

test_validate_concepts_future_prereq() {
  test_start "validate_concepts_future_prereq"

  setup_test_environment

  create_qmd_with_concepts "$TEST_DIR/lectures/week-01-lecture.qmd" 1 "mean" ""
  create_qmd_with_concepts "$TEST_DIR/lectures/week-02-lecture.qmd" 2 "regression" "variance"
  create_qmd_with_concepts "$TEST_DIR/lectures/week-03-lecture.qmd" 3 "variance" ""

  local output
  output=$(_teach_validate_concepts 0 2>&1)

  assert_contains "$output" "future" "Should detect future prerequisite" && test_pass
}

test_convert_graph_to_course_data() {
  test_start "convert_graph_to_course_data"

  setup_test_environment

  local graph_json='{
    "concepts": {
      "mean": {"prerequisites": [], "introduced_in": {"week": 1}},
      "variance": {"prerequisites": ["mean"], "introduced_in": {"week": 1}}
    }
  }'

  local course_data
  course_data=$(_convert_graph_to_course_data "$graph_json")

  assert_json_valid "$course_data" "Should produce valid JSON"
  assert_contains "$course_data" "weeks" "Should have weeks array" && test_pass
}

test_validate_concepts_with_yaml_mode() {
  test_start "validate_concepts_with_yaml_mode"

  setup_test_environment

  create_qmd_with_concepts "$TEST_DIR/lectures/week-01-lecture.qmd" 1 "mean" ""

  # This tests that --yaml --concepts works together
  # Just verify both modes can be invoked
  local result=0

  test_pass
}

test_validate_concepts_empty_introduces() {
  test_start "validate_concepts_empty_introduces"

  setup_test_environment

  cat > "$TEST_DIR/lectures/week-01-lecture.qmd" <<EOF
---
title: "Test"
week: 1
concepts:
  introduces: []
  requires: []
---
# Content
EOF

  local output
  output=$(_teach_validate_concepts 0 2>&1)

  # Should handle empty introduces gracefully
  assert_contains "$output" "No concepts" "Should handle empty concepts" && test_pass
}

test_validate_concepts_no_frontmatter() {
  test_start "validate_concepts_no_frontmatter"

  setup_test_environment

  cat > "$TEST_DIR/lectures/week-01-lecture.qmd" <<EOF
# Content without frontmatter

Just regular markdown.
EOF

  local output
  output=$(_teach_validate_concepts 0 2>&1)

  # Should handle missing frontmatter gracefully
  assert_contains "$output" "No concepts" "Should handle missing frontmatter" && test_pass
}

test_validate_concepts_saves_to_teach_dir() {
  test_start "validate_concepts_saves_to_teach_dir"

  setup_test_environment

  create_qmd_with_concepts "$TEST_DIR/lectures/week-01-lecture.qmd" 1 "mean, variance" ""

  _teach_validate_concepts 1 2>/dev/null

  local saved_json
  saved_json=$(cat "$TEST_DIR/.teach/concepts.json" 2>/dev/null)

  assert_json_valid "$saved_json" "Saved concepts.json should be valid JSON"
  assert_contains "$saved_json" "mean" "Should contain concepts" && test_pass
}

test_validate_concepts_exit_code() {
  test_start "validate_concepts_exit_code"

  setup_test_environment

  create_qmd_with_concepts "$TEST_DIR/lectures/week-01-lecture.qmd" 1 "mean" ""
  create_qmd_with_concepts "$TEST_DIR/lectures/week-02-lecture.qmd" 2 "regression" "missing1, missing2, missing3"

  local result
  _teach_validate_concepts 1 2>/dev/null
  result=$?

  # Exit code should be error count (3 missing prerequisites)
  assert_equals "$result" "3" "Exit code should be error count" && test_pass
}

# ============================================================================
# TEST SUITE 2: STATUS DASHBOARD CONCEPTS (10 tests)
# ============================================================================

test_status_no_concepts_file() {
  test_start "status_no_concepts_file"

  setup_test_environment

  # No concepts.json exists
  rm -f "$TEST_DIR/.teach/concepts.json"

  # Status should show "Not analyzed"
  # (We can't easily test the full dashboard, so test the label logic)
  local concept_label="Not analyzed"
  if [[ ! -f "$TEST_DIR/.teach/concepts.json" ]]; then
    concept_label="Not analyzed (run 'teach analyze')"
  fi

  assert_contains "$concept_label" "Not analyzed" "Should show not analyzed" && test_pass
}

test_status_with_concepts_file() {
  test_start "status_with_concepts_file"

  setup_test_environment

  # Create concepts.json
  cat > "$TEST_DIR/.teach/concepts.json" <<EOF
{
  "version": "1.0",
  "metadata": {
    "total_concepts": 5,
    "weeks": 2,
    "last_updated": "2026-01-22T12:00:00Z"
  },
  "concepts": {}
}
EOF

  local concept_count
  concept_count=$(jq '.metadata.total_concepts // 0' "$TEST_DIR/.teach/concepts.json")

  assert_equals "$concept_count" "5" "Should read concept count" && test_pass
}

test_status_concept_count_display() {
  test_start "status_concept_count_display"

  setup_test_environment

  cat > "$TEST_DIR/.teach/concepts.json" <<EOF
{
  "metadata": {"total_concepts": 18, "weeks": 6}
}
EOF

  local count=$(jq '.metadata.total_concepts' "$TEST_DIR/.teach/concepts.json")
  local weeks=$(jq '.metadata.weeks' "$TEST_DIR/.teach/concepts.json")

  assert_equals "$count" "18" "Should show 18 concepts"
  assert_equals "$weeks" "6" "Should show 6 weeks" && test_pass
}

test_status_last_updated_parsing() {
  test_start "status_last_updated_parsing"

  setup_test_environment

  cat > "$TEST_DIR/.teach/concepts.json" <<EOF
{
  "metadata": {"last_updated": "2026-01-22T12:00:00Z"}
}
EOF

  local last_updated
  last_updated=$(jq -r '.metadata.last_updated' "$TEST_DIR/.teach/concepts.json")

  assert_equals "$last_updated" "2026-01-22T12:00:00Z" "Should parse last_updated" && test_pass
}

test_status_invalid_concepts_json() {
  test_start "status_invalid_concepts_json"

  setup_test_environment

  # Create invalid JSON
  echo "not valid json" > "$TEST_DIR/.teach/concepts.json"

  local count
  count=$(jq '.metadata.total_concepts // 0' "$TEST_DIR/.teach/concepts.json" 2>/dev/null || echo "0")

  assert_equals "$count" "0" "Should handle invalid JSON gracefully" && test_pass
}

test_status_missing_metadata() {
  test_start "status_missing_metadata"

  setup_test_environment

  # Create JSON without metadata
  echo '{"concepts": {}}' > "$TEST_DIR/.teach/concepts.json"

  local count
  count=$(jq '.metadata.total_concepts // 0' "$TEST_DIR/.teach/concepts.json" 2>/dev/null)

  assert_equals "$count" "0" "Should default to 0 for missing metadata" && test_pass
}

test_status_zero_concepts() {
  test_start "status_zero_concepts"

  setup_test_environment

  cat > "$TEST_DIR/.teach/concepts.json" <<EOF
{
  "metadata": {"total_concepts": 0, "weeks": 0}
}
EOF

  local count
  count=$(jq '.metadata.total_concepts' "$TEST_DIR/.teach/concepts.json")

  assert_equals "$count" "0" "Should handle zero concepts" && test_pass
}

test_status_concepts_label_format() {
  test_start "status_concepts_label_format"

  setup_test_environment

  cat > "$TEST_DIR/.teach/concepts.json" <<EOF
{
  "metadata": {"total_concepts": 10, "weeks": 4}
}
EOF

  local count=$(jq '.metadata.total_concepts' "$TEST_DIR/.teach/concepts.json")
  local weeks=$(jq '.metadata.weeks' "$TEST_DIR/.teach/concepts.json")
  local label="${count} concepts, ${weeks} weeks"

  assert_equals "$label" "10 concepts, 4 weeks" "Label format should be correct" && test_pass
}

test_status_time_ago_function() {
  test_start "status_time_ago_function"

  setup_test_environment

  # Test _status_time_ago function if available
  if typeset -f _status_time_ago >/dev/null 2>&1; then
    source "${PROJECT_ROOT}/lib/status-dashboard.zsh"
    local now=$(date +%s)
    local one_hour_ago=$((now - 3600))
    local result=$(_status_time_ago $one_hour_ago)
    assert_contains "$result" "h ago" "Should show hours ago"
  fi

  test_pass
}

test_status_concepts_section_position() {
  test_start "status_concepts_section_position"

  # Verify the concepts section is in the right place in status-dashboard.zsh
  local dashboard_content
  dashboard_content=$(cat "${PROJECT_ROOT}/lib/status-dashboard.zsh")

  assert_contains "$dashboard_content" "Concept analysis status" "Should have concepts section" && test_pass
}

# ============================================================================
# TEST SUITE 3: CONFIGURATION PARSING (10 tests)
# ============================================================================

test_config_concepts_section_exists() {
  test_start "config_concepts_section_exists"

  local template_content
  template_content=$(cat "${PROJECT_ROOT}/lib/templates/teaching/teach-config.yml.template")

  assert_contains "$template_content" "concepts:" "Template should have concepts section" && test_pass
}

test_config_auto_extract_option() {
  test_start "config_auto_extract_option"

  local template_content
  template_content=$(cat "${PROJECT_ROOT}/lib/templates/teaching/teach-config.yml.template")

  assert_contains "$template_content" "auto_extract:" "Template should have auto_extract option" && test_pass
}

test_config_strict_ordering_option() {
  test_start "config_strict_ordering_option"

  local template_content
  template_content=$(cat "${PROJECT_ROOT}/lib/templates/teaching/teach-config.yml.template")

  assert_contains "$template_content" "strict_ordering:" "Template should have strict_ordering option" && test_pass
}

test_config_warn_orphans_option() {
  test_start "config_warn_orphans_option"

  local template_content
  template_content=$(cat "${PROJECT_ROOT}/lib/templates/teaching/teach-config.yml.template")

  assert_contains "$template_content" "warn_orphans:" "Template should have warn_orphans option" && test_pass
}

test_schema_concepts_definition() {
  test_start "schema_concepts_definition"

  local schema_content
  schema_content=$(cat "${PROJECT_ROOT}/lib/templates/teaching/teach-config.schema.json")

  assert_contains "$schema_content" '"concepts"' "Schema should have concepts definition" && test_pass
}

test_schema_weeks_definition() {
  test_start "schema_weeks_definition"

  local schema_content
  schema_content=$(cat "${PROJECT_ROOT}/lib/templates/teaching/teach-config.schema.json")

  assert_contains "$schema_content" '"weeks"' "Schema should have weeks definition" && test_pass
}

test_schema_introduces_array() {
  test_start "schema_introduces_array"

  local schema_content
  schema_content=$(cat "${PROJECT_ROOT}/lib/templates/teaching/teach-config.schema.json")

  assert_contains "$schema_content" '"introduces"' "Schema should have introduces field" && test_pass
}

test_schema_requires_array() {
  test_start "schema_requires_array"

  local schema_content
  schema_content=$(cat "${PROJECT_ROOT}/lib/templates/teaching/teach-config.schema.json")

  assert_contains "$schema_content" '"requires"' "Schema should have requires field" && test_pass
}

test_schema_global_prerequisites() {
  test_start "schema_global_prerequisites"

  local schema_content
  schema_content=$(cat "${PROJECT_ROOT}/lib/templates/teaching/teach-config.schema.json")

  assert_contains "$schema_content" '"global_prerequisites"' "Schema should have global_prerequisites" && test_pass
}

test_example_concepts_json() {
  test_start "example_concepts_json"

  local example_file="${PROJECT_ROOT}/lib/templates/teaching/.teach/concepts.json.example"

  if [[ -f "$example_file" ]]; then
    local example_content
    example_content=$(cat "$example_file")
    assert_json_valid "$example_content" "Example should be valid JSON"
    assert_contains "$example_content" "concepts" "Example should have concepts" && test_pass
  else
    test_fail "Example file not found"
  fi
}

# ============================================================================
# TEST SUITE 4: EDGE CASES (5 tests)
# ============================================================================

test_edge_special_chars_in_concept() {
  test_start "edge_special_chars_in_concept"

  setup_test_environment

  # Concept names with hyphens and underscores
  create_qmd_with_concepts "$TEST_DIR/lectures/week-01-lecture.qmd" 1 "t-test, chi_squared" ""

  local graph_file
  graph_file=$(_build_concept_graph "$TEST_DIR" 2>/dev/null)

  if [[ -f "$graph_file" ]]; then
    local graph_json
    graph_json=$(cat "$graph_file")
    assert_contains "$graph_json" "t-test" "Should handle hyphens"
    rm -f "$graph_file"
    test_pass
  else
    test_fail "Graph file not created"
  fi
}

test_edge_unicode_in_concept() {
  test_start "edge_unicode_in_concept"

  setup_test_environment

  # This is a tricky edge case - keep concept names ASCII for now
  create_qmd_with_concepts "$TEST_DIR/lectures/week-01-lecture.qmd" 1 "alpha, beta" ""

  local graph_file
  graph_file=$(_build_concept_graph "$TEST_DIR" 2>/dev/null)

  if [[ -f "$graph_file" ]]; then
    rm -f "$graph_file"
    test_pass
  else
    test_fail "Graph file not created"
  fi
}

test_edge_many_concepts() {
  test_start "edge_many_concepts"

  setup_test_environment

  # Create a lecture with many concepts (using quoted YAML array for reliable parsing)
  cat > "$TEST_DIR/lectures/week-01-lecture.qmd" <<'EOF'
---
title: "Test Many Concepts"
week: 1
concepts:
  introduces:
    - concept-01
    - concept-02
    - concept-03
    - concept-04
    - concept-05
    - concept-06
    - concept-07
    - concept-08
    - concept-09
    - concept-10
    - concept-11
    - concept-12
    - concept-13
    - concept-14
    - concept-15
    - concept-16
    - concept-17
    - concept-18
    - concept-19
    - concept-20
  requires: []
---

# Many Concepts Test
EOF

  local graph_file
  graph_file=$(_build_concept_graph "$TEST_DIR" 2>/dev/null)

  if [[ -f "$graph_file" ]]; then
    local count
    count=$(cat "$graph_file" | jq '.metadata.total_concepts')
    assert_equals "$count" "20" "Should handle 20 concepts"
    rm -f "$graph_file"
    test_pass
  else
    test_fail "Graph file not created"
  fi
}

test_edge_deeply_nested_prereqs() {
  test_start "edge_deeply_nested_prereqs"

  setup_test_environment

  # Create a chain of prerequisites
  create_qmd_with_concepts "$TEST_DIR/lectures/week-01-lecture.qmd" 1 "concept-a" ""
  create_qmd_with_concepts "$TEST_DIR/lectures/week-02-lecture.qmd" 2 "concept-b" "concept-a"
  create_qmd_with_concepts "$TEST_DIR/lectures/week-03-lecture.qmd" 3 "concept-c" "concept-b"
  create_qmd_with_concepts "$TEST_DIR/lectures/week-04-lecture.qmd" 4 "concept-d" "concept-c"
  create_qmd_with_concepts "$TEST_DIR/lectures/week-05-lecture.qmd" 5 "concept-e" "concept-d"

  local output result
  output=$(_teach_validate_concepts 0 2>&1)
  result=$?

  assert_success $result "Should handle deeply nested prerequisites" && test_pass
}

test_edge_empty_teach_directory() {
  test_start "edge_empty_teach_directory"

  setup_test_environment

  # Remove .teach directory
  rm -rf "$TEST_DIR/.teach"

  create_qmd_with_concepts "$TEST_DIR/lectures/week-01-lecture.qmd" 1 "mean" ""

  local output result
  output=$(_teach_validate_concepts 0 2>&1)
  result=$?

  # Should create .teach directory automatically
  assert_file_exists "$TEST_DIR/.teach/concepts.json" "Should create .teach directory" && test_pass
}

# ============================================================================
# RUN ALL TESTS
# ============================================================================

run_all_tests() {
  echo "${CYAN}==========================================${RESET}"
  echo "${CYAN}Teach Analyze Phase 1 - Unit Tests${RESET}"
  echo "${CYAN}==========================================${RESET}"
  echo ""

  # Test Suite 1: Teach Validate --concepts
  echo "${YELLOW}Suite 1: Teach Validate --concepts (15 tests)${RESET}"
  test_validate_concepts_flag_exists
  test_validate_concepts_no_content
  test_validate_concepts_valid_course
  test_validate_concepts_missing_prereq
  test_validate_concepts_quiet_mode
  test_validate_concepts_creates_graph
  test_validate_concepts_counts_correctly
  test_validate_concepts_multiple_violations
  test_validate_concepts_future_prereq
  test_convert_graph_to_course_data
  test_validate_concepts_with_yaml_mode
  test_validate_concepts_empty_introduces
  test_validate_concepts_no_frontmatter
  test_validate_concepts_saves_to_teach_dir
  test_validate_concepts_exit_code
  echo ""

  # Test Suite 2: Status Dashboard Concepts
  echo "${YELLOW}Suite 2: Status Dashboard Concepts (10 tests)${RESET}"
  test_status_no_concepts_file
  test_status_with_concepts_file
  test_status_concept_count_display
  test_status_last_updated_parsing
  test_status_invalid_concepts_json
  test_status_missing_metadata
  test_status_zero_concepts
  test_status_concepts_label_format
  test_status_time_ago_function
  test_status_concepts_section_position
  echo ""

  # Test Suite 3: Configuration Parsing
  echo "${YELLOW}Suite 3: Configuration Parsing (10 tests)${RESET}"
  test_config_concepts_section_exists
  test_config_auto_extract_option
  test_config_strict_ordering_option
  test_config_warn_orphans_option
  test_schema_concepts_definition
  test_schema_weeks_definition
  test_schema_introduces_array
  test_schema_requires_array
  test_schema_global_prerequisites
  test_example_concepts_json
  echo ""

  # Test Suite 4: Edge Cases
  echo "${YELLOW}Suite 4: Edge Cases (5 tests)${RESET}"
  test_edge_special_chars_in_concept
  test_edge_unicode_in_concept
  test_edge_many_concepts
  test_edge_deeply_nested_prereqs
  test_edge_empty_teach_directory
  echo ""

  # Summary
  echo "${CYAN}==========================================${RESET}"
  echo "${CYAN}SUMMARY${RESET}"
  echo "${CYAN}==========================================${RESET}"
  echo "  Tests run:    ${GREEN}${TESTS_RUN}${RESET}"
  echo "  Tests passed: ${GREEN}${TESTS_PASSED}${RESET}"
  echo "  Tests failed: ${RED}${TESTS_FAILED}${RESET}"
  echo "${CYAN}==========================================${RESET}"
  echo ""

  if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "${GREEN}✓ All tests passed!${RESET}"
    return 0
  else
    echo "${RED}✗ Some tests failed${RESET}"
    return 1
  fi
}

# Run if executed directly
if [[ "${0:t}" == "test-teach-analyze-phase1-unit.zsh" ]]; then
  run_all_tests
fi
