#!/usr/bin/env zsh
# tests/test-custom-validators-unit.zsh
# Unit tests for custom validator plugin framework
# v4.6.0 - Wave 3: Custom Validators Framework
#
# TEST COVERAGE:
#   - Validator discovery
#   - API validation (missing functions, invalid return)
#   - Validator execution
#   - Error aggregation
#   - Multiple validators running
#   - Plugin isolation
#
# USAGE:
#   ./tests/test-custom-validators-unit.zsh

# Load test framework
script_dir="${0:A:h}"
source "$script_dir/../lib/core.zsh"
source "$script_dir/../lib/custom-validators.zsh"

# Test utilities
typeset -g TESTS_RUN=0
typeset -g TESTS_PASSED=0
typeset -g TESTS_FAILED=0

# ANSI colors for test output
typeset -g TEST_GREEN='\033[0;32m'
typeset -g TEST_RED='\033[0;31m'
typeset -g TEST_YELLOW='\033[1;33m'
typeset -g TEST_BLUE='\033[0;34m'
typeset -g TEST_RESET='\033[0m'

# Test assertion helpers
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Assertion failed}"

    ((TESTS_RUN++))

    if [[ "$expected" == "$actual" ]]; then
        ((TESTS_PASSED++))
        echo -e "${TEST_GREEN}✓${TEST_RESET} $message"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "${TEST_RED}✗${TEST_RESET} $message"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        return 1
    fi
}

assert_exit_code() {
    local expected_code="$1"
    local actual_code="$2"
    local message="${3:-Exit code assertion failed}"

    ((TESTS_RUN++))

    if [[ $expected_code -eq $actual_code ]]; then
        ((TESTS_PASSED++))
        echo -e "${TEST_GREEN}✓${TEST_RESET} $message"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "${TEST_RED}✗${TEST_RESET} $message"
        echo "  Expected code: $expected_code"
        echo "  Actual code:   $actual_code"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String contains assertion failed}"

    ((TESTS_RUN++))

    if echo "$haystack" | grep -qF "$needle"; then
        ((TESTS_PASSED++))
        echo -e "${TEST_GREEN}✓${TEST_RESET} $message"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "${TEST_RED}✗${TEST_RESET} $message"
        echo "  Haystack: $haystack"
        echo "  Needle:   $needle"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-File exists assertion failed}"

    ((TESTS_RUN++))

    if [[ -f "$file" ]]; then
        ((TESTS_PASSED++))
        echo -e "${TEST_GREEN}✓${TEST_RESET} $message"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "${TEST_RED}✗${TEST_RESET} $message"
        echo "  File: $file"
        return 1
    fi
}

# ============================================================================
# TEST SETUP
# ============================================================================

setup_test_env() {
    # Create temporary test directory
    export TEST_DIR=$(mktemp -d)
    mkdir -p "$TEST_DIR/.teach/validators"

    # Change to test directory
    cd "$TEST_DIR"
}

cleanup_validators() {
    # Clean up validators between tests
    rm -f "$TEST_DIR/.teach/validators"/*.zsh 2>/dev/null
    rm -f "$TEST_DIR"/*.zsh 2>/dev/null
    rm -f "$TEST_DIR"/*.qmd 2>/dev/null
}

teardown_test_env() {
    # Clean up test directory
    cd /tmp
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

# ============================================================================
# VALIDATOR DISCOVERY TESTS
# ============================================================================

test_discover_validators_empty() {
    echo -e "\n${TEST_BLUE}Testing validator discovery (empty)${TEST_RESET}"

    local validators
    validators=($(_discover_validators "$TEST_DIR"))

    assert_equals "0" "${#validators[@]}" "No validators in empty directory"
}

test_discover_validators_single() {
    echo -e "\n${TEST_BLUE}Testing validator discovery (single)${TEST_RESET}"

    # Create a test validator
    cat > "$TEST_DIR/.teach/validators/test-validator.zsh" <<'EOF'
VALIDATOR_NAME="Test"
VALIDATOR_VERSION="1.0.0"
VALIDATOR_DESCRIPTION="Test validator"
_validate() { return 0; }
EOF

    local validators
    validators=($(_discover_validators "$TEST_DIR"))

    assert_equals "1" "${#validators[@]}" "One validator found"
    assert_contains "${validators[1]}" "test-validator.zsh" "Correct validator file"
}

test_discover_validators_multiple() {
    echo -e "\n${TEST_BLUE}Testing validator discovery (multiple)${TEST_RESET}"

    cleanup_validators

    # Create multiple validators
    for name in validator-a validator-b validator-c; do
        cat > "$TEST_DIR/.teach/validators/$name.zsh" <<'EOF'
VALIDATOR_NAME="Test"
VALIDATOR_VERSION="1.0.0"
VALIDATOR_DESCRIPTION="Test"
_validate() { return 0; }
EOF
    done

    local validators
    validators=($(_discover_validators "$TEST_DIR"))

    assert_equals "3" "${#validators[@]}" "Three validators found"
}

test_get_validator_name_from_path() {
    echo -e "\n${TEST_BLUE}Testing validator name extraction${TEST_RESET}"

    local name
    name=$(_get_validator_name_from_path "/path/to/check-citations.zsh")

    assert_equals "check-citations" "$name" "Extract validator name from path"
}

# ============================================================================
# API VALIDATION TESTS
# ============================================================================

test_validate_api_complete() {
    echo -e "\n${TEST_BLUE}Testing API validation (complete)${TEST_RESET}"

    # Create valid validator
    cat > "$TEST_DIR/valid-validator.zsh" <<'EOF'
VALIDATOR_NAME="Valid Validator"
VALIDATOR_VERSION="1.0.0"
VALIDATOR_DESCRIPTION="A valid validator"
_validate() {
    local file="$1"
    return 0
}
EOF

    local result
    result=$(_validate_validator_api "$TEST_DIR/valid-validator.zsh")
    local exit_code=$?

    assert_exit_code 0 $exit_code "Valid API passes validation"
}

test_validate_api_missing_name() {
    echo -e "\n${TEST_BLUE}Testing API validation (missing name)${TEST_RESET}"

    cat > "$TEST_DIR/missing-name.zsh" <<'EOF'
VALIDATOR_VERSION="1.0.0"
VALIDATOR_DESCRIPTION="Missing name"
_validate() { return 0; }
EOF

    local result
    result=$(_validate_validator_api "$TEST_DIR/missing-name.zsh")
    local exit_code=$?

    assert_exit_code 1 $exit_code "Missing VALIDATOR_NAME fails validation"
    assert_contains "$result" "Missing VALIDATOR_NAME" "Error message mentions missing name"
}

test_validate_api_missing_version() {
    echo -e "\n${TEST_BLUE}Testing API validation (missing version)${TEST_RESET}"

    cat > "$TEST_DIR/missing-version.zsh" <<'EOF'
VALIDATOR_NAME="Test"
VALIDATOR_DESCRIPTION="Missing version"
_validate() { return 0; }
EOF

    local result
    result=$(_validate_validator_api "$TEST_DIR/missing-version.zsh")
    local exit_code=$?

    assert_exit_code 1 $exit_code "Missing VALIDATOR_VERSION fails validation"
    assert_contains "$result" "Missing VALIDATOR_VERSION" "Error message mentions missing version"
}

test_validate_api_missing_description() {
    echo -e "\n${TEST_BLUE}Testing API validation (missing description)${TEST_RESET}"

    cat > "$TEST_DIR/missing-desc.zsh" <<'EOF'
VALIDATOR_NAME="Test"
VALIDATOR_VERSION="1.0.0"
_validate() { return 0; }
EOF

    local result
    result=$(_validate_validator_api "$TEST_DIR/missing-desc.zsh")
    local exit_code=$?

    assert_exit_code 1 $exit_code "Missing VALIDATOR_DESCRIPTION fails validation"
    assert_contains "$result" "Missing VALIDATOR_DESCRIPTION" "Error message mentions missing description"
}

test_validate_api_missing_function() {
    echo -e "\n${TEST_BLUE}Testing API validation (missing function)${TEST_RESET}"

    cat > "$TEST_DIR/missing-func.zsh" <<'EOF'
VALIDATOR_NAME="Test"
VALIDATOR_VERSION="1.0.0"
VALIDATOR_DESCRIPTION="Missing function"
EOF

    local result
    result=$(_validate_validator_api "$TEST_DIR/missing-func.zsh")
    local exit_code=$?

    assert_exit_code 1 $exit_code "Missing _validate() fails validation"
    assert_contains "$result" "Missing _validate() function" "Error message mentions missing function"
}

# ============================================================================
# METADATA LOADING TESTS
# ============================================================================

test_load_validator_metadata() {
    echo -e "\n${TEST_BLUE}Testing metadata loading${TEST_RESET}"

    cat > "$TEST_DIR/test-meta.zsh" <<'EOF'
VALIDATOR_NAME="Citation Validator"
VALIDATOR_VERSION="1.2.3"
VALIDATOR_DESCRIPTION="Validates citations"
_validate() { return 0; }
EOF

    local metadata
    metadata=$(_load_validator_metadata "$TEST_DIR/test-meta.zsh")

    assert_contains "$metadata" '"name": "Citation Validator"' "Metadata includes name"
    assert_contains "$metadata" '"version": "1.2.3"' "Metadata includes version"
    assert_contains "$metadata" '"description": "Validates citations"' "Metadata includes description"
}

# ============================================================================
# VALIDATOR EXECUTION TESTS
# ============================================================================

test_execute_validator_pass() {
    echo -e "\n${TEST_BLUE}Testing validator execution (pass)${TEST_RESET}"

    # Create passing validator
    cat > "$TEST_DIR/pass-validator.zsh" <<'EOF'
VALIDATOR_NAME="Pass Validator"
VALIDATOR_VERSION="1.0.0"
VALIDATOR_DESCRIPTION="Always passes"
_validate() {
    local file="$1"
    return 0
}
EOF

    # Create test file
    echo "test content" > "$TEST_DIR/test.qmd"

    local result
    result=$(_execute_validator "$TEST_DIR/pass-validator.zsh" "$TEST_DIR/test.qmd")
    local exit_code=$?

    assert_exit_code 0 $exit_code "Passing validator returns 0"
}

test_execute_validator_fail() {
    echo -e "\n${TEST_BLUE}Testing validator execution (fail)${TEST_RESET}"

    # Create failing validator
    cat > "$TEST_DIR/fail-validator.zsh" <<'EOF'
VALIDATOR_NAME="Fail Validator"
VALIDATOR_VERSION="1.0.0"
VALIDATOR_DESCRIPTION="Always fails"
_validate() {
    local file="$1"
    echo "Error: Something is wrong"
    return 1
}
EOF

    echo "test content" > "$TEST_DIR/test.qmd"

    local result
    result=$(_execute_validator "$TEST_DIR/fail-validator.zsh" "$TEST_DIR/test.qmd")
    local exit_code=$?

    assert_exit_code 1 $exit_code "Failing validator returns 1"
    assert_contains "$result" "Error: Something is wrong" "Error message is captured"
}

test_execute_validator_crash() {
    echo -e "\n${TEST_BLUE}Testing validator execution (crash)${TEST_RESET}"

    # Create crashing validator
    cat > "$TEST_DIR/crash-validator.zsh" <<'EOF'
VALIDATOR_NAME="Crash Validator"
VALIDATOR_VERSION="1.0.0"
VALIDATOR_DESCRIPTION="Crashes"
_validate() {
    # This will cause a crash
    nonexistent_command_xyz
    return 0
}
EOF

    echo "test content" > "$TEST_DIR/test.qmd"

    local result
    result=$(_execute_validator "$TEST_DIR/crash-validator.zsh" "$TEST_DIR/test.qmd" 2>&1)
    local exit_code=$?

    # Should handle crash gracefully
    assert_exit_code 2 $exit_code "Crashed validator returns exit code 2"
}

# ============================================================================
# MAIN ORCHESTRATOR TESTS
# ============================================================================

test_run_custom_validators_no_files() {
    echo -e "\n${TEST_BLUE}Testing orchestrator (no files)${TEST_RESET}"

    local result
    result=$(_run_custom_validators 2>&1)
    local exit_code=$?

    assert_exit_code 1 $exit_code "No files specified returns error"
    assert_contains "$result" "No files specified" "Error message about missing files"
}

test_run_custom_validators_no_validators() {
    echo -e "\n${TEST_BLUE}Testing orchestrator (no validators)${TEST_RESET}"

    # Remove all validators
    rm -rf "$TEST_DIR/.teach/validators"/*.zsh

    echo "test" > "$TEST_DIR/test.qmd"

    local result
    result=$(_run_custom_validators --project-root "$TEST_DIR" "$TEST_DIR/test.qmd" 2>&1)
    local exit_code=$?

    assert_exit_code 0 $exit_code "No validators returns success (warning)"
    assert_contains "$result" "No custom validators found" "Warning about missing validators"
}

test_run_custom_validators_single() {
    echo -e "\n${TEST_BLUE}Testing orchestrator (single validator)${TEST_RESET}"

    # Create validator
    cat > "$TEST_DIR/.teach/validators/test.zsh" <<'EOF'
VALIDATOR_NAME="Test Validator"
VALIDATOR_VERSION="1.0.0"
VALIDATOR_DESCRIPTION="Test"
_validate() {
    return 0
}
EOF

    echo "test" > "$TEST_DIR/test.qmd"

    local result
    result=$(_run_custom_validators --project-root "$TEST_DIR" "$TEST_DIR/test.qmd" 2>&1)
    local exit_code=$?

    assert_exit_code 0 $exit_code "Single passing validator succeeds"
    assert_contains "$result" "Test Validator" "Validator name in output"
    assert_contains "$result" "All validators passed" "Success summary"
}

test_run_custom_validators_select_specific() {
    echo -e "\n${TEST_BLUE}Testing orchestrator (select specific validators)${TEST_RESET}"

    # Create multiple validators
    cat > "$TEST_DIR/.teach/validators/validator-a.zsh" <<'EOF'
VALIDATOR_NAME="Validator A"
VALIDATOR_VERSION="1.0.0"
VALIDATOR_DESCRIPTION="Validator A"
_validate() { return 0; }
EOF

    cat > "$TEST_DIR/.teach/validators/validator-b.zsh" <<'EOF'
VALIDATOR_NAME="Validator B"
VALIDATOR_VERSION="1.0.0"
VALIDATOR_DESCRIPTION="Validator B"
_validate() { return 0; }
EOF

    echo "test" > "$TEST_DIR/test.qmd"

    local result
    result=$(_run_custom_validators --project-root "$TEST_DIR" --validators "validator-a" "$TEST_DIR/test.qmd" 2>&1)
    local exit_code=$?

    assert_exit_code 0 $exit_code "Selected validator runs"
    assert_contains "$result" "Validator A" "Selected validator A runs"
    # Should NOT contain Validator B
    if echo "$result" | grep -q "Validator B"; then
        ((TESTS_RUN++))
        ((TESTS_FAILED++))
        echo -e "${TEST_RED}✗${TEST_RESET} Validator B should not run"
    else
        ((TESTS_RUN++))
        ((TESTS_PASSED++))
        echo -e "${TEST_GREEN}✓${TEST_RESET} Validator B correctly excluded"
    fi
}

# ============================================================================
# TEST RUNNER
# ============================================================================

run_all_tests() {
    echo -e "${TEST_YELLOW}═══════════════════════════════════════════════════${TEST_RESET}"
    echo -e "${TEST_YELLOW}  Custom Validator Framework Unit Tests${TEST_RESET}"
    echo -e "${TEST_YELLOW}═══════════════════════════════════════════════════${TEST_RESET}"

    # Setup
    setup_test_env

    # Discovery tests
    test_discover_validators_empty
    test_discover_validators_single
    test_discover_validators_multiple
    test_get_validator_name_from_path

    # API validation tests
    test_validate_api_complete
    test_validate_api_missing_name
    test_validate_api_missing_version
    test_validate_api_missing_description
    test_validate_api_missing_function

    # Metadata tests
    test_load_validator_metadata

    # Execution tests
    test_execute_validator_pass
    test_execute_validator_fail
    test_execute_validator_crash

    # Orchestrator tests
    test_run_custom_validators_no_files
    test_run_custom_validators_no_validators
    test_run_custom_validators_single
    test_run_custom_validators_select_specific

    # Teardown
    teardown_test_env

    # Summary
    echo -e "\n${TEST_YELLOW}═══════════════════════════════════════════════════${TEST_RESET}"
    echo -e "${TEST_YELLOW}  Test Summary${TEST_RESET}"
    echo -e "${TEST_YELLOW}═══════════════════════════════════════════════════${TEST_RESET}"
    echo -e "Total tests:  $TESTS_RUN"
    echo -e "${TEST_GREEN}Passed:       $TESTS_PASSED${TEST_RESET}"
    echo -e "${TEST_RED}Failed:       $TESTS_FAILED${TEST_RESET}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n${TEST_GREEN}✓ All tests passed!${TEST_RESET}"
        return 0
    else
        echo -e "\n${TEST_RED}✗ Some tests failed${TEST_RESET}"
        return 1
    fi
}

# Run tests
run_all_tests
