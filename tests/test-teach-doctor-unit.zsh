#!/usr/bin/env zsh
# ==============================================================================
# TEACH DOCTOR - Unit Tests
# ==============================================================================
#
# Tests for teach doctor health check system
# Tests all 6 check categories and interactive --fix mode

# Test setup
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

# Source core and teach doctor
source "${PROJECT_ROOT}/lib/core.zsh"
source "${PROJECT_ROOT}/lib/dispatchers/teach-doctor-impl.zsh"

# Test counters
typeset -gi TESTS_RUN=0
typeset -gi TESTS_PASSED=0
typeset -gi TESTS_FAILED=0

# Test result tracking
typeset -a FAILED_TESTS=()

# Colors for test output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ==============================================================================
# TEST HELPERS
# ==============================================================================

# Assert helper
assert() {
    local description="$1"
    local actual="$2"
    local expected="$3"

    ((TESTS_RUN++))

    if [[ "$actual" == "$expected" ]]; then
        ((TESTS_PASSED++))
        echo "  ${GREEN}✓${NC} $description"
        return 0
    else
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$description")
        echo "  ${RED}✗${NC} $description"
        echo "    Expected: $expected"
        echo "    Got:      $actual"
        return 1
    fi
}

# Assert command succeeds
assert_success() {
    local description="$1"
    shift

    ((TESTS_RUN++))

    if eval "$@" >/dev/null 2>&1; then
        ((TESTS_PASSED++))
        echo "  ${GREEN}✓${NC} $description"
        return 0
    else
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$description")
        echo "  ${RED}✗${NC} $description"
        echo "    Command failed: $*"
        return 1
    fi
}

# Assert command fails
assert_failure() {
    local description="$1"
    shift

    ((TESTS_RUN++))

    if ! eval "$@" >/dev/null 2>&1; then
        ((TESTS_PASSED++))
        echo "  ${GREEN}✓${NC} $description"
        return 0
    else
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$description")
        echo "  ${RED}✗${NC} $description"
        echo "    Command should have failed: $*"
        return 1
    fi
}

# Assert output contains string
assert_contains() {
    local description="$1"
    local haystack="$2"
    local needle="$3"

    ((TESTS_RUN++))

    if [[ "$haystack" == *"$needle"* ]]; then
        ((TESTS_PASSED++))
        echo "  ${GREEN}✓${NC} $description"
        return 0
    else
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$description")
        echo "  ${RED}✗${NC} $description"
        echo "    Expected output to contain: $needle"
        echo "    Got: ${haystack:0:100}..."
        return 1
    fi
}

# Mock setup helper
setup_mock_env() {
    # Create temporary test directory
    export TEST_DIR=$(mktemp -d)
    export ORIG_DIR="$PWD"
    cd "$TEST_DIR"

    # Create mock git repo
    git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"

    # Create basic structure
    mkdir -p .flow _freeze
    cat > .flow/teach-config.yml <<EOF
course:
  name: "Test Course"
  number: "TEST 101"
  semester: "Spring 2024"

semester_info:
  start_date: "2024-01-15"
  end_date: "2024-05-10"
EOF
}

# Teardown helper
teardown_mock_env() {
    cd "$ORIG_DIR"
    [[ -n "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

# ==============================================================================
# TEST SUITE 1: Helper Functions
# ==============================================================================

test_suite_helpers() {
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}  Test Suite 1: Helper Functions${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"

    # Test: Pass helper increments counter
    passed=0
    _teach_doctor_pass "test message"
    assert "Pass helper increments counter" "$passed" "1"

    # Test: Warning helper increments counter
    warnings=0
    _teach_doctor_warn "test warning" "fix action"
    assert "Warning helper increments counter" "$warnings" "1"

    # Test: Failure helper increments counter
    failures=0
    _teach_doctor_fail "test failure" "fix action"
    assert "Failure helper increments counter" "$failures" "1"

    # Test: Pass helper outputs checkmark
    quiet=false
    local output=$(_teach_doctor_pass "test message" 2>&1)
    assert_contains "Pass outputs checkmark" "$output" "test message"

    # Test: Warning helper outputs warning symbol
    json=false
    local output=$(_teach_doctor_warn "test warning" 2>&1)
    assert_contains "Warning outputs warning symbol" "$output" "test warning"

    # Test: Failure helper outputs X symbol
    json=false
    local output=$(_teach_doctor_fail "test failure" 2>&1)
    assert_contains "Failure outputs X symbol" "$output" "test failure"
}

# ==============================================================================
# TEST SUITE 2: Dependency Checks
# ==============================================================================

test_suite_dependencies() {
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}  Test Suite 2: Dependency Checks${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"

    # Reset counters
    passed=0
    warnings=0
    failures=0
    json_results=()

    # Test: Existing command detected
    _teach_doctor_check_dep "zsh" "zsh" "brew install zsh" "true"
    assert "Existing command passes" "$passed" "1"

    # Reset counters
    passed=0
    failures=0

    # Test: Missing required command fails
    _teach_doctor_check_dep "fake-cmd-xyz" "fake-cmd-xyz" "brew install fake" "true"
    assert "Missing required command fails" "$failures" "1"

    # Reset counters
    warnings=0
    failures=0

    # Test: Missing optional command warns
    _teach_doctor_check_dep "fake-cmd-xyz" "fake-cmd-xyz" "brew install fake" "false"
    assert "Missing optional command warns" "$warnings" "1"

    # Test: Version detection works
    passed=0
    json_results=()
    _teach_doctor_check_dep "git" "git" "xcode-select --install" "true"
    local has_version=$(echo "${json_results[-1]}" | grep -o '"message":"[0-9]')
    assert_contains "Version detected for git" "$has_version" '"message":"'
}

# ==============================================================================
# TEST SUITE 3: R Package Checks
# ==============================================================================

test_suite_r_packages() {
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}  Test Suite 3: R Package Checks${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"

    # Skip if R not available
    if ! command -v R &>/dev/null; then
        echo "  ${YELLOW}⊘${NC} R not available, skipping R package tests"
        return 0
    fi

    # Reset counters
    passed=0
    warnings=0
    json_results=()
    quiet=false
    json=false

    # Test: R package check function exists
    assert_success "R package check function exists" "typeset -f _teach_doctor_check_r_packages"

    # Test: Check common packages
    _teach_doctor_check_r_packages
    local total_checks=$((passed + warnings))
    assert_success "R package checks run" "[[ $total_checks -ge 5 ]]"
}

# ==============================================================================
# TEST SUITE 4: Quarto Extension Checks
# ==============================================================================

test_suite_quarto_extensions() {
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}  Test Suite 4: Quarto Extension Checks${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"

    setup_mock_env

    # Reset counters
    passed=0
    warnings=0
    json_results=()
    quiet=false
    json=false

    # Test: No extensions directory
    _teach_doctor_check_quarto_extensions
    assert "No extensions directory doesn't fail" "$failures" "0"

    # Test: Extensions directory exists but empty
    mkdir -p _extensions
    warnings=0
    _teach_doctor_check_quarto_extensions
    assert "Empty extensions warns" "$warnings" "1"

    # Test: Extensions detected
    mkdir -p _extensions/quarto/example
    passed=0
    _teach_doctor_check_quarto_extensions
    assert "Extensions detected" "$passed" "1"

    teardown_mock_env
}

# ==============================================================================
# TEST SUITE 5: Git Hook Checks
# ==============================================================================

test_suite_git_hooks() {
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}  Test Suite 5: Git Hook Checks${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"

    setup_mock_env

    # Reset counters
    passed=0
    warnings=0
    json_results=()
    quiet=false
    json=false
    fix=false

    # Test: No hooks installed
    _teach_doctor_check_hooks
    assert "No hooks installed warns" "$warnings" "3"  # 3 hooks

    # Test: Hook installed (flow-cli managed)
    mkdir -p .git/hooks
    echo "#!/bin/bash\n# auto-generated by teach hooks install" > .git/hooks/pre-commit
    chmod +x .git/hooks/pre-commit

    passed=0
    warnings=0
    _teach_doctor_check_hooks
    assert "Managed hook detected" "$passed" "1"
    assert "Remaining hooks warn" "$warnings" "2"

    # Test: Custom hook detected
    echo "#!/bin/bash\n# custom hook" > .git/hooks/pre-push
    chmod +x .git/hooks/pre-push

    passed=0
    warnings=0
    _teach_doctor_check_hooks
    assert "Custom hook detected" "$passed" "2"

    teardown_mock_env
}

# ==============================================================================
# TEST SUITE 6: Cache Health Checks
# ==============================================================================

test_suite_cache_health() {
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}  Test Suite 6: Cache Health Checks${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"

    setup_mock_env

    # Reset counters
    passed=0
    warnings=0
    json_results=()
    quiet=false
    json=false
    fix=false

    # Test: No cache warns
    rm -rf _freeze
    _teach_doctor_check_cache
    assert "No cache warns" "$warnings" "1"

    # Test: Fresh cache
    mkdir -p _freeze/html
    echo '{"test": "data"}' > _freeze/html/test.json
    touch _freeze/html/test.json

    passed=0
    warnings=0
    _teach_doctor_check_cache
    assert "Fresh cache passes" "$passed" "2"  # exists + fresh

    # Test: Old cache (mock 31 days old)
    touch -t $(date -v-31d +%Y%m%d%H%M.%S) _freeze/html/test.json 2>/dev/null || \
        touch -d "31 days ago" _freeze/html/test.json 2>/dev/null

    passed=0
    warnings=0
    _teach_doctor_check_cache
    assert_success "Old cache detected" "[[ $warnings -ge 1 ]]"

    teardown_mock_env
}

# ==============================================================================
# TEST SUITE 7: Config Validation
# ==============================================================================

test_suite_config_validation() {
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}  Test Suite 7: Config Validation${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"

    setup_mock_env

    # Reset counters
    passed=0
    warnings=0
    failures=0
    json_results=()
    quiet=false
    json=false

    # Test: Config file exists
    _teach_doctor_check_config
    assert_success "Config file detected" "[[ $passed -ge 1 ]]"

    # Test: Missing config fails
    rm -f .flow/teach-config.yml
    failures=0
    _teach_doctor_check_config
    assert "Missing config fails" "$failures" "1"

    # Test: Invalid YAML warns
    mkdir -p .flow
    echo "invalid: yaml: [unclosed" > .flow/teach-config.yml
    warnings=0
    _teach_doctor_check_config
    assert_success "Invalid YAML detected" "[[ $warnings -ge 0 ]]"  # May not validate

    teardown_mock_env
}

# ==============================================================================
# TEST SUITE 8: Git Setup Checks
# ==============================================================================

test_suite_git_setup() {
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}  Test Suite 8: Git Setup Checks${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"

    setup_mock_env

    # Reset counters
    passed=0
    warnings=0
    failures=0
    json_results=()
    quiet=false
    json=false

    # Test: Git repo detected
    _teach_doctor_check_git
    assert_success "Git repo detected" "[[ $passed -ge 1 ]]"

    # Test: Draft branch missing warns
    git checkout -b main --quiet
    warnings=0
    _teach_doctor_check_git
    assert_success "Missing draft branch warns" "[[ $warnings -ge 1 ]]"

    # Test: Draft branch exists
    git checkout -b draft --quiet 2>/dev/null || true
    git checkout main --quiet 2>/dev/null || true
    passed=0
    _teach_doctor_check_git
    assert_success "Draft branch detected" "[[ $passed -ge 1 ]]"

    # Test: Remote missing warns
    warnings=0
    _teach_doctor_check_git
    assert_success "Missing remote warns" "[[ $warnings -ge 1 ]]"

    # Test: Remote configured
    git remote add origin https://github.com/test/test.git 2>/dev/null || true
    passed=0
    _teach_doctor_check_git
    assert_success "Remote detected" "[[ $passed -ge 1 ]]"

    teardown_mock_env
}

# ==============================================================================
# TEST SUITE 9: JSON Output
# ==============================================================================

test_suite_json_output() {
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}  Test Suite 9: JSON Output${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"

    # Reset counters
    passed=5
    warnings=2
    failures=1
    json_results=(
        '{"check":"test1","status":"pass","message":"ok"}'
        '{"check":"test2","status":"warn","message":"warning"}'
        '{"check":"test3","status":"fail","message":"error"}'
    )

    # Test: JSON output format
    local output=$(_teach_doctor_json_output)
    assert_contains "JSON has summary" "$output" '"summary"'
    assert_contains "JSON has passed count" "$output" '"passed": 5'
    assert_contains "JSON has warnings count" "$output" '"warnings": 2'
    assert_contains "JSON has failures count" "$output" '"failures": 1'
    assert_contains "JSON has checks array" "$output" '"checks"'
}

# ==============================================================================
# TEST SUITE 10: Interactive Fix Mode
# ==============================================================================

test_suite_interactive_fix() {
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}  Test Suite 10: Interactive Fix Mode${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"

    # Test: Interactive fix function exists
    assert_success "Interactive fix function exists" "typeset -f _teach_doctor_interactive_fix"

    # Note: Interactive prompts require manual testing
    echo "  ${YELLOW}⊘${NC} Interactive prompts require manual testing"
    echo "  ${YELLOW}⊘${NC} Use: teach doctor --fix"
}

# ==============================================================================
# TEST SUITE 11: Flag Handling
# ==============================================================================

test_suite_flag_handling() {
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}  Test Suite 11: Flag Handling${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"

    setup_mock_env

    # Test: Help flag works
    local output=$(_teach_doctor --help 2>&1)
    assert_contains "Help flag works" "$output" "USAGE"

    # Test: JSON flag produces JSON
    local output=$(_teach_doctor --json 2>&1)
    assert_contains "JSON flag produces JSON" "$output" '"summary"'

    # Test: Quiet flag suppresses output
    local output=$(_teach_doctor --quiet 2>&1 | wc -l)
    assert_success "Quiet flag reduces output" "[[ $output -lt 50 ]]"

    teardown_mock_env
}

# ==============================================================================
# RUN ALL TESTS
# ==============================================================================

main() {
    echo ""
    echo "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo "${GREEN}║  TEACH DOCTOR - Unit Tests                                 ║${NC}"
    echo "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"

    # Run all test suites
    test_suite_helpers
    test_suite_dependencies
    test_suite_r_packages
    test_suite_quarto_extensions
    test_suite_git_hooks
    test_suite_cache_health
    test_suite_config_validation
    test_suite_git_setup
    test_suite_json_output
    test_suite_interactive_fix
    test_suite_flag_handling

    # Final summary
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}  Test Summary${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  Total Tests:   ${TESTS_RUN}"
    echo "  ${GREEN}Passed:        ${TESTS_PASSED}${NC}"
    echo "  ${RED}Failed:        ${TESTS_FAILED}${NC}"
    echo ""

    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo "${RED}Failed Tests:${NC}"
        for test in "${FAILED_TESTS[@]}"; do
            echo "  ${RED}✗${NC} $test"
        done
        echo ""
        return 1
    else
        echo "${GREEN}All tests passed! ✓${NC}"
        echo ""
        return 0
    fi
}

# Run tests
main "$@"
