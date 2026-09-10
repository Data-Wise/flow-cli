#!/usr/bin/env zsh
# test-teach-check.zsh - Unit tests for `teach check` (issue #359)
#
# Tests:
# - Valid config, no Scholar/Craft -> flow-cli layers PASS, optional layers SKIP, exit 0
# - Invalid YAML -> syntax FAIL, schema FAIL, exit 1
# - Missing config file -> clear error, exit 1
# - --help shows usage

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

source "${PROJECT_ROOT}/lib/core.zsh"
source "${PROJECT_ROOT}/lib/config-validator.zsh"
source "${PROJECT_ROOT}/commands/teach-validate.zsh"
source "${PROJECT_ROOT}/lib/dispatchers/teach-check.zsh"
source "${PROJECT_ROOT}/lib/dispatchers/teach/teach-help.zsh"

typeset -gi TESTS_RUN=0
typeset -gi TESTS_PASSED=0
typeset -gi TESTS_FAILED=0
typeset -ga FAILED_TESTS=()

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

assert_contains() {
    local description="$1" haystack="$2" needle="$3"
    ((TESTS_RUN++))
    if [[ "$haystack" == *"$needle"* ]]; then
        ((TESTS_PASSED++))
        echo "  ${GREEN}✓${NC} $description"
    else
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$description")
        echo "  ${RED}✗${NC} $description"
        echo "    Expected to find: $needle"
    fi
}

assert_equals() {
    local description="$1" actual="$2" expected="$3"
    ((TESTS_RUN++))
    if [[ "$actual" == "$expected" ]]; then
        ((TESTS_PASSED++))
        echo "  ${GREEN}✓${NC} $description"
    else
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$description")
        echo "  ${RED}✗${NC} $description"
        echo "    Expected: $expected"
        echo "    Got:      $actual"
    fi
}

setup_mock_env() {
    export TEST_DIR=$(mktemp -d)
    export ORIG_DIR="$PWD"
    cd "$TEST_DIR"
    mkdir -p .flow
}

teardown_mock_env() {
    cd "$ORIG_DIR"
    [[ -n "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

write_valid_config() {
    cat > .flow/teach-config.yml <<'EOF'
course:
  name: "Test Course"
  semester: "Fall"
  year: 2026

semester_info:
  start_date: "2026-08-24"
  end_date: "2026-12-12"
EOF
}

# ==============================================================================
# TEST SUITE 1: Valid config, no Scholar/Craft
# ==============================================================================

test_suite_valid_config() {
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}  Suite 1: Valid config, no Scholar/Craft${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"

    setup_mock_env
    write_valid_config

    local output
    output=$(_teach_check 2>&1)
    local exit_code=$?

    assert_equals "Exit code 0 on valid config" "$exit_code" "0"
    assert_contains "Config syntax reported" "$output" "Config syntax"
    assert_contains "Schema layer reported" "$output" "Schema"
    assert_contains "R code layer skipped" "$output" "SKIP"
    assert_contains "Craft content layer skipped (not installed)" "$output" "not installed"
    assert_contains "Summary line present" "$output" "checks passed"

    teardown_mock_env
}

# ==============================================================================
# TEST SUITE 2: Invalid YAML
# ==============================================================================

test_suite_invalid_yaml() {
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}  Suite 2: Invalid YAML${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"

    setup_mock_env
    echo "invalid: yaml: [unclosed" > .flow/teach-config.yml

    local output
    output=$(_teach_check 2>&1)
    local exit_code=$?

    assert_equals "Exit code 1 on invalid YAML" "$exit_code" "1"
    if command -v yq >/dev/null 2>&1; then
        assert_contains "Config syntax FAIL reported" "$output" "FAIL"
    else
        echo "  ${BLUE}⊘${NC} yq not installed, syntax layer would SKIP not FAIL — skipping this assertion"
    fi

    teardown_mock_env
}

# ==============================================================================
# TEST SUITE 3: Missing config file
# ==============================================================================

test_suite_missing_config() {
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}  Suite 3: Missing config file${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"

    setup_mock_env
    rm -f .flow/teach-config.yml

    local output
    output=$(_teach_check 2>&1)
    local exit_code=$?

    assert_equals "Exit code 1 when config missing" "$exit_code" "1"
    assert_contains "Clear error message shown" "$output" "No .flow/teach-config.yml found"

    teardown_mock_env
}

# ==============================================================================
# TEST SUITE 4: --help
# ==============================================================================

test_suite_help() {
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}  Suite 4: --help${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"

    local output
    output=$(_teach_check_help 2>&1)

    assert_contains "Usage line shown" "$output" "Usage:"
    assert_contains "Alias shown" "$output" "chk"
    assert_contains "Layers listed" "$output" "Config syntax"
    assert_contains "Exit codes documented" "$output" "EXIT CODES"
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    echo "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo "${GREEN}║  TEACH CHECK - Unit Tests                                  ║${NC}"
    echo "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"

    test_suite_valid_config
    test_suite_invalid_yaml
    test_suite_missing_config
    test_suite_help

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

main "$@"
