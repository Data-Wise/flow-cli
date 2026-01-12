#!/usr/bin/env zsh
# tests/test-teach-init.zsh - Test teaching workflow initialization

# Test setup
TEST_DIR="/tmp/flow-cli-test-teaching-$$"
TEST_NAME="test-teach-init"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

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
    echo -e "${RED}✗${NC} Missing: $pattern"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
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

# ============================================================================
# TESTS
# ============================================================================

test_detect_teaching_enhanced() {
  echo -e "\n${BLUE}Test: Enhanced teaching detection${NC}"

  setup_test_repo
  mkdir -p .flow
  cat > .flow/teach-config.yml <<EOF
course:
  name: "Test Course"
branches:
  draft: "draft"
  production: "production"
EOF

  local detected=$(_flow_detect_project_type .)
  assert_equals "teaching" "$detected"

  teardown_test_repo
}

test_validate_teaching_config_valid() {
  echo -e "\n${BLUE}Test: Validate valid teaching config${NC}"

  setup_test_repo
  mkdir -p .flow
  cat > .flow/teach-config.yml <<EOF
course:
  name: "Test Course"
branches:
  draft: "draft"
  production: "production"
EOF

  if command -v yq &>/dev/null; then
    _flow_validate_teaching_config ".flow/teach-config.yml"
    local result=$?
    assert_equals 0 "$result"
  else
    echo -e "${YELLOW}⊘${NC} Skipped: yq not installed"
  fi

  teardown_test_repo
}

test_validate_teaching_config_invalid() {
  echo -e "\n${BLUE}Test: Reject invalid teaching config${NC}"

  setup_test_repo
  mkdir -p .flow
  cat > .flow/teach-config.yml <<EOF
course:
  name: "Test Course"
# Missing branches section
EOF

  if command -v yq &>/dev/null; then
    _flow_validate_teaching_config ".flow/teach-config.yml" 2>/dev/null
    local result=$?
    assert_equals 1 "$result"
  else
    echo -e "${YELLOW}⊘${NC} Skipped: yq not installed"
  fi

  teardown_test_repo
}

test_template_files_exist() {
  echo -e "\n${BLUE}Test: Template files exist${NC}"

  assert_file_exists "$FLOW_PLUGIN_DIR/lib/templates/teaching/quick-deploy.sh"
  assert_file_exists "$FLOW_PLUGIN_DIR/lib/templates/teaching/semester-archive.sh"
  assert_file_exists "$FLOW_PLUGIN_DIR/lib/templates/teaching/exam-to-qti.sh"
  assert_file_exists "$FLOW_PLUGIN_DIR/lib/templates/teaching/deploy.yml.template"
  assert_file_exists "$FLOW_PLUGIN_DIR/lib/templates/teaching/teach-config.yml.template"
}

test_teach_init_command_exists() {
  echo -e "\n${BLUE}Test: teach-init command exists${NC}"

  TESTS_RUN=$((TESTS_RUN + 1))
  if command -v teach-init &>/dev/null; then
    echo -e "${GREEN}✓${NC} teach-init command available"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} teach-init command not found"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# ============================================================================
# RUN TESTS
# ============================================================================

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Teaching Workflow Test Suite                              ║"
echo "╚════════════════════════════════════════════════════════════╝"

test_template_files_exist
test_teach_init_command_exists
test_detect_teaching_enhanced
test_validate_teaching_config_valid
test_validate_teaching_config_invalid

# Summary
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Test Summary                                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "  Tests run:    $TESTS_RUN"
echo -e "  ${GREEN}Passed:${NC}       $TESTS_PASSED"
echo -e "  ${RED}Failed:${NC}       $TESTS_FAILED"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo -e "${GREEN}✓ All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}✗ Some tests failed${NC}"
  exit 1
fi
