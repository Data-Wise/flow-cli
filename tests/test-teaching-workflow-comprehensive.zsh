#!/usr/bin/env zsh
# tests/test-teaching-workflow-comprehensive.zsh
# Comprehensive test suite for teaching workflow v2.0

# Test setup
TEST_DIR="/tmp/flow-cli-test-teaching-comprehensive-$$"
TEST_NAME="teaching-workflow-comprehensive"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Load flow-cli
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FLOW_PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
source "$FLOW_PLUGIN_DIR/flow.plugin.zsh"

# ============================================================================
# TEST HELPERS
# ============================================================================

assert_file_exists() {
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -f "$1" ]]; then
    echo -e "${GREEN}✓${NC} File exists: $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} File missing: $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_file_executable() {
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -x "$1" ]]; then
    echo -e "${GREEN}✓${NC} File executable: $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} File not executable: $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_directory_exists() {
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -d "$1" ]]; then
    echo -e "${GREEN}✓${NC} Directory exists: $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} Directory missing: $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_contains() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local text="$1"
  local pattern="$2"
  if echo "$text" | grep -q "$pattern"; then
    echo -e "${GREEN}✓${NC} Contains: $pattern"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} Missing pattern: $pattern"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_not_contains() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local text="$1"
  local pattern="$2"
  if echo "$text" | grep -q "$pattern"; then
    echo -e "${RED}✗${NC} Should not contain: $pattern"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  else
    echo -e "${GREEN}✓${NC} Correctly excludes: $pattern"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  fi
}

assert_equals() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local expected="$1"
  local actual="$2"
  if [[ "$expected" == "$actual" ]]; then
    echo -e "${GREEN}✓${NC} Equals: $expected"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} Expected: $expected, Got: $actual"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_not_equals() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local unexpected="$1"
  local actual="$2"
  if [[ "$unexpected" != "$actual" ]]; then
    echo -e "${GREEN}✓${NC} Not equal to: $unexpected"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} Should not equal: $unexpected"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

skip_test() {
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
  echo -e "${YELLOW}⊘${NC} Skipped: $1"
}

# ============================================================================
# SETUP/TEARDOWN
# ============================================================================

setup_test_repo() {
  rm -rf "$TEST_DIR"
  mkdir -p "$TEST_DIR"
  cd "$TEST_DIR"
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"
  git commit --allow-empty -m "Initial commit" -q
}

teardown_test_repo() {
  cd /tmp
  rm -rf "$TEST_DIR"
}

create_valid_teaching_config() {
  local config_file="${1:-.flow/teach-config.yml}"
  mkdir -p "$(dirname "$config_file")"
  cat > "$config_file" <<EOF
course:
  name: "Test Course"
  full_name: "Test Course Full Name"
  semester: "spring"
  year: 2026
  instructor: "Test Instructor"

branches:
  draft: "draft"
  production: "production"

deployment:
  web:
    type: "github-pages"
    branch: "production"
    url: "https://example.com"

automation:
  quick_deploy: "scripts/quick-deploy.sh"

shortcuts:
  test: "work test"
  testd: "./scripts/quick-deploy.sh"
EOF
}

create_minimal_teaching_config() {
  local config_file="${1:-.flow/teach-config.yml}"
  mkdir -p "$(dirname "$config_file")"
  cat > "$config_file" <<EOF
course:
  name: "Minimal Course"
branches:
  draft: "draft"
  production: "production"
EOF
}

# ============================================================================
# CATEGORY 1: PROJECT DETECTION
# ============================================================================

test_detect_teaching_via_syllabus() {
  echo -e "\n${BLUE}Test: Detect teaching via syllabus.qmd${NC}"
  setup_test_repo
  touch syllabus.qmd

  local detected=$(_flow_detect_project_type .)
  assert_equals "teaching" "$detected"

  teardown_test_repo
}

test_detect_teaching_via_lectures_dir() {
  echo -e "\n${BLUE}Test: Detect teaching via lectures/ directory${NC}"
  setup_test_repo
  mkdir -p lectures

  local detected=$(_flow_detect_project_type .)
  assert_equals "teaching" "$detected"

  teardown_test_repo
}

test_detect_teaching_via_config() {
  echo -e "\n${BLUE}Test: Detect teaching via .flow/teach-config.yml${NC}"
  setup_test_repo
  create_valid_teaching_config

  local detected=$(_flow_detect_project_type .)
  assert_equals "teaching" "$detected"

  teardown_test_repo
}

test_detect_teaching_priority_over_quarto() {
  echo -e "\n${BLUE}Test: Teaching detection has priority over generic quarto${NC}"
  setup_test_repo
  touch syllabus.qmd _quarto.yml

  local detected=$(_flow_detect_project_type .)
  assert_equals "teaching" "$detected"

  teardown_test_repo
}

# ============================================================================
# CATEGORY 2: CONFIG VALIDATION
# ============================================================================

test_validate_config_valid() {
  echo -e "\n${BLUE}Test: Valid config passes validation${NC}"
  setup_test_repo
  create_valid_teaching_config

  if command -v yq &>/dev/null; then
    _flow_validate_teaching_config ".flow/teach-config.yml"
    local result=$?
    assert_equals 0 "$result"
  else
    skip_test "yq not installed"
  fi

  teardown_test_repo
}

test_validate_config_minimal() {
  echo -e "\n${BLUE}Test: Minimal valid config passes${NC}"
  setup_test_repo
  create_minimal_teaching_config

  if command -v yq &>/dev/null; then
    _flow_validate_teaching_config ".flow/teach-config.yml"
    local result=$?
    assert_equals 0 "$result"
  else
    skip_test "yq not installed"
  fi

  teardown_test_repo
}

test_validate_config_missing_course_name() {
  echo -e "\n${BLUE}Test: Config missing course.name fails${NC}"
  setup_test_repo
  mkdir -p .flow
  cat > .flow/teach-config.yml <<EOF
branches:
  draft: "draft"
  production: "production"
EOF

  if command -v yq &>/dev/null; then
    _flow_validate_teaching_config ".flow/teach-config.yml" 2>/dev/null
    local result=$?
    assert_equals 1 "$result"
  else
    skip_test "yq not installed"
  fi

  teardown_test_repo
}

test_validate_config_missing_branches() {
  echo -e "\n${BLUE}Test: Config missing branches section fails${NC}"
  setup_test_repo
  mkdir -p .flow
  cat > .flow/teach-config.yml <<EOF
course:
  name: "Test Course"
EOF

  if command -v yq &>/dev/null; then
    _flow_validate_teaching_config ".flow/teach-config.yml" 2>/dev/null
    local result=$?
    assert_equals 1 "$result"
  else
    skip_test "yq not installed"
  fi

  teardown_test_repo
}

test_validate_config_malformed_yaml() {
  echo -e "\n${BLUE}Test: Malformed YAML fails validation${NC}"
  setup_test_repo
  mkdir -p .flow
  cat > .flow/teach-config.yml <<EOF
course:
  name: "Test Course
  missing_quote_here
branches:
  draft: "draft"
EOF

  if command -v yq &>/dev/null; then
    _flow_validate_teaching_config ".flow/teach-config.yml" 2>/dev/null
    local result=$?
    assert_equals 1 "$result"
  else
    skip_test "yq not installed"
  fi

  teardown_test_repo
}

test_validate_config_without_yq() {
  echo -e "\n${BLUE}Test: Validation gracefully handles missing yq${NC}"
  setup_test_repo
  create_valid_teaching_config

  # Mock yq not being available
  local orig_path="$PATH"
  PATH="/nonexistent"

  _flow_validate_teaching_config ".flow/teach-config.yml" 2>/dev/null
  local result=$?

  PATH="$orig_path"

  # Should return 0 (graceful degradation)
  assert_equals 0 "$result"

  teardown_test_repo
}

# ============================================================================
# CATEGORY 3: TEMPLATE FILES
# ============================================================================

test_template_quick_deploy_exists() {
  echo -e "\n${BLUE}Test: quick-deploy.sh template exists${NC}"
  assert_file_exists "$FLOW_PLUGIN_DIR/lib/templates/teaching/quick-deploy.sh"
}

test_template_semester_archive_exists() {
  echo -e "\n${BLUE}Test: semester-archive.sh template exists${NC}"
  assert_file_exists "$FLOW_PLUGIN_DIR/lib/templates/teaching/semester-archive.sh"
}

test_template_exam_converter_exists() {
  echo -e "\n${BLUE}Test: exam-to-qti.sh template exists${NC}"
  assert_file_exists "$FLOW_PLUGIN_DIR/lib/templates/teaching/exam-to-qti.sh"
}

test_template_github_actions_exists() {
  echo -e "\n${BLUE}Test: deploy.yml.template exists${NC}"
  assert_file_exists "$FLOW_PLUGIN_DIR/lib/templates/teaching/deploy.yml.template"
}

test_template_config_exists() {
  echo -e "\n${BLUE}Test: teach-config.yml.template exists${NC}"
  assert_file_exists "$FLOW_PLUGIN_DIR/lib/templates/teaching/teach-config.yml.template"
}

test_template_quick_deploy_has_shebang() {
  echo -e "\n${BLUE}Test: quick-deploy.sh has proper shebang${NC}"
  local first_line=$(head -n 1 "$FLOW_PLUGIN_DIR/lib/templates/teaching/quick-deploy.sh")
  assert_contains "$first_line" "#!/usr/bin/env bash"
}

test_template_quick_deploy_has_branch_check() {
  echo -e "\n${BLUE}Test: quick-deploy.sh validates branch${NC}"
  local content=$(cat "$FLOW_PLUGIN_DIR/lib/templates/teaching/quick-deploy.sh")
  assert_contains "$content" "Must be on.*branch"
}

test_template_quick_deploy_has_timing() {
  echo -e "\n${BLUE}Test: quick-deploy.sh tracks deployment time${NC}"
  local content=$(cat "$FLOW_PLUGIN_DIR/lib/templates/teaching/quick-deploy.sh")
  assert_contains "$content" "START_TIME"
  assert_contains "$content" "END_TIME"
  assert_contains "$content" "DURATION"
}

# ============================================================================
# CATEGORY 4: TEACH-INIT COMMAND
# ============================================================================

test_teach_init_command_exists() {
  echo -e "\n${BLUE}Test: teach-init command is available${NC}"

  TESTS_RUN=$((TESTS_RUN + 1))
  if command -v teach-init &>/dev/null; then
    echo -e "${GREEN}✓${NC} teach-init command available"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} teach-init command not found"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_teach_init_requires_course_name() {
  echo -e "\n${BLUE}Test: teach-init requires course name argument${NC}"
  setup_test_repo

  local output=$(teach-init 2>&1)
  assert_contains "$output" "Usage:"

  teardown_test_repo
}

test_teach_init_checks_yq_dependency() {
  echo -e "\n${BLUE}Test: teach-init has yq dependency check logic${NC}"

  # Verify the teach-init function contains yq check
  # (We can't easily test the actual failure path without breaking the test environment)
  local func_content=$(declare -f teach-init)

  TESTS_RUN=$((TESTS_RUN + 1))
  if echo "$func_content" | grep -q "command -v yq"; then
    echo -e "${GREEN}✓${NC} teach-init checks for yq command"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} teach-init missing yq check"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  TESTS_RUN=$((TESTS_RUN + 1))
  if echo "$func_content" | grep -q "yq is required"; then
    echo -e "${GREEN}✓${NC} teach-init has yq error message"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} teach-init missing yq error message"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_teach_init_detects_no_git() {
  echo -e "\n${BLUE}Test: teach-init detects non-git directory${NC}"
  rm -rf "$TEST_DIR"
  mkdir -p "$TEST_DIR"
  cd "$TEST_DIR"

  if command -v yq &>/dev/null; then
    local output=$(teach-init "Test Course" 2>&1)
    assert_contains "$output" "No git repository detected"
  else
    skip_test "yq not installed"
  fi

  teardown_test_repo
}

# ============================================================================
# CATEGORY 5: WORK COMMAND INTEGRATION
# ============================================================================

test_work_teaching_session_requires_config() {
  echo -e "\n${BLUE}Test: _work_teaching_session requires config file${NC}"
  setup_test_repo

  _work_teaching_session "$TEST_DIR" 2>/dev/null
  local result=$?
  assert_equals 1 "$result"

  teardown_test_repo
}

test_work_teaching_session_graceful_without_yq() {
  echo -e "\n${BLUE}Test: _work_teaching_session graceful without yq${NC}"
  setup_test_repo
  create_valid_teaching_config

  # Mock yq not being available
  local orig_path="$PATH"
  PATH="/nonexistent"

  _work_teaching_session "$TEST_DIR" 2>/dev/null
  local result=$?

  PATH="$orig_path"

  # Should return 0 (graceful degradation)
  assert_equals 0 "$result"

  teardown_test_repo
}

# ============================================================================
# CATEGORY 6: EDGE CASES
# ============================================================================

test_config_with_special_characters() {
  echo -e "\n${BLUE}Test: Config handles course names with special chars${NC}"
  setup_test_repo
  mkdir -p .flow
  cat > .flow/teach-config.yml <<EOF
course:
  name: "STAT 545: Data & Analysis (Spring '26)"
branches:
  draft: "draft"
  production: "production"
EOF

  if command -v yq &>/dev/null; then
    _flow_validate_teaching_config ".flow/teach-config.yml"
    local result=$?
    assert_equals 0 "$result"
  else
    skip_test "yq not installed"
  fi

  teardown_test_repo
}

test_config_with_unicode() {
  echo -e "\n${BLUE}Test: Config handles unicode characters${NC}"
  setup_test_repo
  mkdir -p .flow
  cat > .flow/teach-config.yml <<EOF
course:
  name: "统计学 545"
  instructor: "José García"
branches:
  draft: "draft"
  production: "production"
EOF

  if command -v yq &>/dev/null; then
    _flow_validate_teaching_config ".flow/teach-config.yml"
    local result=$?
    assert_equals 0 "$result"
  else
    skip_test "yq not installed"
  fi

  teardown_test_repo
}

test_empty_config_file() {
  echo -e "\n${BLUE}Test: Empty config file fails validation${NC}"
  setup_test_repo
  mkdir -p .flow
  touch .flow/teach-config.yml

  if command -v yq &>/dev/null; then
    _flow_validate_teaching_config ".flow/teach-config.yml" 2>/dev/null
    local result=$?
    assert_equals 1 "$result"
  else
    skip_test "yq not installed"
  fi

  teardown_test_repo
}

# ============================================================================
# CATEGORY 7: REGRESSION TESTS
# ============================================================================

test_teaching_detection_does_not_break_other_types() {
  echo -e "\n${BLUE}Test: Teaching detection doesn't interfere with R packages${NC}"
  setup_test_repo

  # Create R package markers
  cat > DESCRIPTION <<EOF
Package: testpkg
Version: 1.0.0
EOF
  touch NAMESPACE

  local detected=$(_flow_detect_project_type .)
  assert_equals "r-package" "$detected"

  teardown_test_repo
}

test_teaching_detection_does_not_break_python() {
  echo -e "\n${BLUE}Test: Teaching detection doesn't interfere with Python${NC}"
  setup_test_repo
  touch pyproject.toml

  local detected=$(_flow_detect_project_type .)
  assert_equals "python" "$detected"

  teardown_test_repo
}

# ============================================================================
# RUN ALL TESTS
# ============================================================================

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Teaching Workflow - Comprehensive Test Suite             ║"
echo "╚════════════════════════════════════════════════════════════╝"

echo -e "\n${CYAN}━━━ Category 1: Project Detection ━━━${NC}"
test_detect_teaching_via_syllabus
test_detect_teaching_via_lectures_dir
test_detect_teaching_via_config
test_detect_teaching_priority_over_quarto

echo -e "\n${CYAN}━━━ Category 2: Config Validation ━━━${NC}"
test_validate_config_valid
test_validate_config_minimal
test_validate_config_missing_course_name
test_validate_config_missing_branches
test_validate_config_malformed_yaml
test_validate_config_without_yq

echo -e "\n${CYAN}━━━ Category 3: Template Files ━━━${NC}"
test_template_quick_deploy_exists
test_template_semester_archive_exists
test_template_exam_converter_exists
test_template_github_actions_exists
test_template_config_exists
test_template_quick_deploy_has_shebang
test_template_quick_deploy_has_branch_check
test_template_quick_deploy_has_timing

echo -e "\n${CYAN}━━━ Category 4: teach-init Command ━━━${NC}"
test_teach_init_command_exists
test_teach_init_requires_course_name
test_teach_init_checks_yq_dependency
test_teach_init_detects_no_git

echo -e "\n${CYAN}━━━ Category 5: Work Command Integration ━━━${NC}"
test_work_teaching_session_requires_config
test_work_teaching_session_graceful_without_yq

echo -e "\n${CYAN}━━━ Category 6: Edge Cases ━━━${NC}"
test_config_with_special_characters
test_config_with_unicode
test_empty_config_file

echo -e "\n${CYAN}━━━ Category 7: Regression Tests ━━━${NC}"
test_teaching_detection_does_not_break_other_types
test_teaching_detection_does_not_break_python

# Summary
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Test Summary                                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "  Tests run:    $TESTS_RUN"
echo -e "  ${GREEN}Passed:${NC}       $TESTS_PASSED"
echo -e "  ${RED}Failed:${NC}       $TESTS_FAILED"
echo -e "  ${YELLOW}Skipped:${NC}      $TESTS_SKIPPED"
echo ""

# Calculate coverage percentage
if [[ $TESTS_RUN -gt 0 ]]; then
  local coverage=$(( (TESTS_PASSED * 100) / TESTS_RUN ))
  echo -e "  Coverage:     ${coverage}%"
  echo ""
fi

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo -e "${GREEN}✓ All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}✗ Some tests failed${NC}"
  exit 1
fi
