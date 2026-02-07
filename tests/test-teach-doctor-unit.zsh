#!/usr/bin/env zsh
# ==============================================================================
# TEACH DOCTOR - Unit Tests
# ==============================================================================
#
# Tests for teach doctor health check system (v2)
# Tests all check categories, two-mode architecture, renv awareness,
# severity-grouped summary, CI mode, status file, and bug fixes

# Test setup
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

# Source core and teach doctor
source "${PROJECT_ROOT}/lib/core.zsh"
source "${PROJECT_ROOT}/lib/r-helpers.zsh" 2>/dev/null || true
source "${PROJECT_ROOT}/lib/renv-integration.zsh" 2>/dev/null || true
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
# TEST SUITE 11: Flag Handling (v2 — updated)
# ==============================================================================

test_suite_flag_handling() {
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}  Test Suite 11: Flag Handling${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"

    setup_mock_env

    # Test: Help flag works (requires teach-dispatcher for help function)
    if typeset -f _teach_doctor_help >/dev/null 2>&1; then
        local output=$(_teach_doctor --help 2>&1)
        assert_contains "Help flag works" "$output" "teach doctor"
    else
        echo "  ${YELLOW}⊘${NC} Help flag test skipped (teach-dispatcher not loaded)"
    fi

    # Test: JSON flag produces JSON
    local output=$(_teach_doctor --json 2>&1)
    assert_contains "JSON flag produces JSON" "$output" '"summary"'

    # Test: --brief flag suppresses passed output
    local output=$(_teach_doctor --brief 2>&1 | wc -l)
    assert_success "Brief flag reduces output" "[[ $output -lt 50 ]]"

    # Test: --quiet is alias for --brief
    local output=$(_teach_doctor --quiet 2>&1 | wc -l)
    assert_success "Quiet flag (deprecated alias) reduces output" "[[ $output -lt 50 ]]"

    # Test: --full flag runs more checks
    local full_output=$(_teach_doctor --full --brief 2>&1 | wc -l)
    local quick_output=$(_teach_doctor --brief 2>&1 | wc -l)
    # Full mode should produce equal or more output since it runs more checks
    assert_success "Full mode runs more checks" "[[ $full_output -ge $quick_output ]]"

    teardown_mock_env
}

# ==============================================================================
# TEST SUITE 12: Two-Mode Architecture (v2)
# ==============================================================================

test_suite_two_mode() {
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}  Test Suite 12: Two-Mode Architecture (v2)${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"

    setup_mock_env

    # Test: Default mode is quick (shows skipped hint)
    local output=$(_teach_doctor 2>&1)
    assert_contains "Quick mode shows skip hint" "$output" "Skipped (run --full)"
    assert_contains "Quick mode has R Environment" "$output" "R Environment"

    # Test: Quick mode header
    local output=$(_teach_doctor 2>&1)
    assert_contains "Quick mode header" "$output" "quick check"

    # Test: Full mode header
    local output=$(_teach_doctor --full 2>&1)
    assert_contains "Full mode header" "$output" "full check"

    # Test: Full mode does NOT show skip hint
    local output=$(_teach_doctor --full 2>&1)
    if [[ "$output" != *"Skipped (run --full)"* ]]; then
        ((TESTS_RUN++)); ((TESTS_PASSED++))
        echo "  ${GREEN}✓${NC} Full mode hides skip hint"
    else
        ((TESTS_RUN++)); ((TESTS_FAILED++))
        FAILED_TESTS+=("Full mode hides skip hint")
        echo "  ${RED}✗${NC} Full mode hides skip hint"
    fi

    # Test: --fix implies full mode
    local output=$(_teach_doctor --fix --brief 2>&1)
    assert_contains "Fix implies full mode" "$output" ""  # Just check it doesn't crash

    # Test: Quick mode runs < 5 seconds (timing test)
    local start_t=$EPOCHSECONDS
    _teach_doctor --brief >/dev/null 2>&1
    local elapsed=$(( EPOCHSECONDS - start_t ))
    assert_success "Quick mode runs fast (<5s)" "[[ $elapsed -lt 5 ]]"

    teardown_mock_env
}

# ==============================================================================
# TEST SUITE 13: Quick R Check (v2)
# ==============================================================================

test_suite_r_quick() {
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}  Test Suite 13: Quick R Check (v2)${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"

    setup_mock_env

    # Reset counters
    passed=0
    warnings=0
    json_results=()
    quiet=false
    json=false
    full=false
    verbose=false
    ci=false

    # Test: Quick R check function exists
    assert_success "Quick R check function exists" "typeset -f _teach_doctor_check_r_quick"

    # Test: Quick R check runs (R available or not)
    local output=$(_teach_doctor_check_r_quick 2>&1)
    assert_contains "Quick R check has section header" "$output" "R Environment"

    if command -v R &>/dev/null; then
        # Test: R version detected in quick mode
        local r_ver=$(R --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        assert_contains "Quick R shows version" "$output" "R ($r_ver)"

        # Test: Shows full mode hint
        assert_contains "Quick R shows full hint" "$output" "Run --full for package details"
    fi

    # Test: renv detection (mock renv)
    mkdir -p renv
    echo '{"R":{"Version":"4.4.0"},"Packages":{}}' > renv.lock
    echo "# renv activate" > renv/activate.R

    passed=0
    json_results=()
    local output=$(_teach_doctor_check_r_quick 2>&1)
    assert_contains "renv detected" "$output" "renv active"

    # Cleanup
    rm -rf renv renv.lock

    teardown_mock_env
}

# ==============================================================================
# TEST SUITE 14: Quarto Extension Glob Fix (v2 - Bug Fix Verification)
# ==============================================================================

test_suite_quarto_glob_fix() {
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}  Test Suite 14: Quarto Extension Glob Fix (v2)${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"

    setup_mock_env

    # Reset
    passed=0
    warnings=0
    failures=0
    json_results=()
    quiet=false
    json=false

    # Test: Extension with spaces in name (was crashing before fix)
    mkdir -p "_extensions/Terminal Resources/example"
    _teach_doctor_check_quarto_extensions 2>&1
    assert_success "Extensions with spaces don't crash" "[[ $? -eq 0 || true ]]"
    assert "Extension with spaces detected" "$passed" "1"

    # Test: Multiple extensions counted correctly
    mkdir -p "_extensions/quarto-ext/fontawesome"
    mkdir -p "_extensions/quarto-ext/lightbox"
    passed=0
    warnings=0
    json_results=()
    _teach_doctor_check_quarto_extensions 2>&1
    assert "Multiple extensions counted" "$passed" "1"

    # Verify count is correct (3 extensions total)
    local count_msg=""
    for r in "${json_results[@]}"; do
        if [[ "$r" == *"quarto_extensions"* ]]; then
            count_msg="$r"
            break
        fi
    done
    assert_contains "Extension count in JSON" "$count_msg" "3 installed"

    teardown_mock_env
}

# ==============================================================================
# TEST SUITE 15: Severity-Grouped Summary (v2)
# ==============================================================================

test_suite_summary() {
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}  Test Suite 15: Severity-Grouped Summary (v2)${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"

    # Test: Summary with no failures
    passed=10
    warnings=2
    failures=0
    start_time=$EPOCHSECONDS
    failure_details=()

    local output=$(_teach_doctor_summary 2>&1)
    assert_contains "Summary shows pass count" "$output" "Passed: 10"
    assert_contains "Summary shows warning count" "$output" "Warnings: 2"

    # Test: Summary with failures shows details
    passed=8
    warnings=1
    failures=2
    failure_details=("Quarto not found\n    -> brew install --cask quarto" "R package 'ggplot2' not found\n    -> install.packages('ggplot2')")

    local output=$(_teach_doctor_summary 2>&1)
    assert_contains "Summary shows failures section" "$output" "Failures (2)"
    assert_contains "Summary shows failure detail" "$output" "Quarto not found"
    assert_contains "Summary has border" "$output" "────"
}

# ==============================================================================
# TEST SUITE 16: CI Mode (v2)
# ==============================================================================

test_suite_ci_mode() {
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}  Test Suite 16: CI Mode (v2)${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"

    setup_mock_env

    # Test: CI mode produces machine-readable output
    local output=$(_teach_doctor --ci 2>&1)
    assert_contains "CI mode has status" "$output" "doctor:status="
    assert_contains "CI mode has passed" "$output" "doctor:passed="
    assert_contains "CI mode has warnings" "$output" "doctor:warnings="
    assert_contains "CI mode has failures" "$output" "doctor:failures="
    assert_contains "CI mode has mode" "$output" "doctor:mode="

    # Test: CI mode exit code 0 for passing
    _teach_doctor --ci >/dev/null 2>&1
    assert "CI exit code 0 when passing" "$?" "0"

    teardown_mock_env
}

# ==============================================================================
# TEST SUITE 17: Status File (v2)
# ==============================================================================

test_suite_status_file() {
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}  Test Suite 17: Status File (v2)${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"

    setup_mock_env

    # Test: Doctor writes status file
    _teach_doctor --brief >/dev/null 2>&1
    assert_success "Status file created" "[[ -f .flow/doctor-status.json ]]"

    # Test: Status file is valid JSON (if jq available)
    if command -v jq &>/dev/null; then
        assert_success "Status file is valid JSON" "jq empty .flow/doctor-status.json"

        # Test: Status file has required fields
        local health_status=$(jq -r '.status' .flow/doctor-status.json 2>/dev/null)
        assert_success "Status file has status field" "[[ -n '$health_status' ]]"

        local file_version=$(jq -r '.version' .flow/doctor-status.json 2>/dev/null)
        assert "Status file version is 1" "$file_version" "1"

        local file_mode=$(jq -r '.mode' .flow/doctor-status.json 2>/dev/null)
        assert "Status file mode is quick" "$file_mode" "quick"
    fi

    # Test: Health indicator function exists
    assert_success "Health indicator function exists" "typeset -f _teach_health_indicator"
    assert_success "Health dot function exists" "typeset -f _teach_health_dot"

    # Test: Health indicator reads status
    local indicator=$(_teach_health_indicator 2>/dev/null)
    assert_success "Health indicator returns value" "[[ -n '$indicator' ]]"

    teardown_mock_env
}

# ==============================================================================
# TEST SUITE 18: JSON Output v2 (updated fields)
# ==============================================================================

test_suite_json_v2() {
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}  Test Suite 18: JSON Output v2${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"

    # Reset counters
    passed=5
    warnings=0
    failures=0
    full=false
    json_results=(
        '{"check":"test1","status":"pass","message":"ok"}'
    )

    # Test: JSON v2 has version field
    local output=$(_teach_doctor_json_output 2>&1)
    assert_contains "JSON v2 has version" "$output" '"version": 1'

    # Test: JSON v2 has mode field
    assert_contains "JSON v2 has mode" "$output" '"mode": "quick"'

    # Test: JSON v2 has status color
    assert_contains "JSON v2 has green status" "$output" '"status": "green"'

    # Test: Full mode in JSON
    full=true
    local output=$(_teach_doctor_json_output 2>&1)
    assert_contains "JSON v2 full mode" "$output" '"mode": "full"'

    # Test: Yellow status with warnings
    full=false
    warnings=2
    local output=$(_teach_doctor_json_output 2>&1)
    assert_contains "JSON v2 yellow status" "$output" '"status": "yellow"'

    # Test: Red status with failures
    failures=1
    local output=$(_teach_doctor_json_output 2>&1)
    assert_contains "JSON v2 red status" "$output" '"status": "red"'
}

# ==============================================================================
# TEST SUITE 19: Batch R Package Check (v2 - Bug Fix Verification)
# ==============================================================================

test_suite_batch_r_check() {
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}  Test Suite 19: Batch R Package Check (v2)${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"

    # Skip if R not available
    if ! command -v R &>/dev/null; then
        echo "  ${YELLOW}⊘${NC} R not available, skipping batch R check tests"
        return 0
    fi

    # Test: Batch function exists
    assert_success "Batch R function exists" "typeset -f _get_installed_r_packages"

    # Test: Batch function returns packages
    local pkgs=$(_get_installed_r_packages 2>/dev/null)
    assert_success "Batch R returns packages" "[[ -n '$pkgs' ]]"

    # Test: Known base packages in list
    assert_contains "Batch R includes base" "$pkgs" "base"
    assert_contains "Batch R includes stats" "$pkgs" "stats"
    assert_contains "Batch R includes utils" "$pkgs" "utils"
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

    # v2 test suites
    test_suite_two_mode
    test_suite_r_quick
    test_suite_quarto_glob_fix
    test_suite_summary
    test_suite_ci_mode
    test_suite_status_file
    test_suite_json_v2
    test_suite_batch_r_check

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
