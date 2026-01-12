#!/usr/bin/env zsh
# tests/run-unit-tests.zsh - Run all unit tests for project cache

setopt pipefail

SCRIPT_DIR="${0:A:h}"

# Colors
C_GREEN="\033[0;32m"
C_RED="\033[0;31m"
C_CYAN="\033[0;36m"
C_BOLD="\033[1m"
C_NC="\033[0m"

# Track results
SUITES_PASSED=0
SUITES_FAILED=0
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

echo -e "${C_BOLD}╔═══════════════════════════════════════════════════════════════╗${C_NC}"
echo -e "${C_BOLD}║  flow-cli Project Cache - Unit Test Suite Runner              ║${C_NC}"
echo -e "${C_BOLD}╚═══════════════════════════════════════════════════════════════╝${C_NC}"
echo ""

# Find all unit test files
test_files=("$SCRIPT_DIR/unit/"test-*.zsh(N))

if [[ ${#test_files[@]} -eq 0 ]]; then
    echo -e "${C_RED}No test files found in $SCRIPT_DIR/unit/${C_NC}"
    exit 1
fi

echo -e "Found ${#test_files[@]} test suites\n"

# Run each test suite
for test_file in "${test_files[@]}"; do
    suite_name=$(basename "$test_file" .zsh)
    echo -e "${C_CYAN}═══════════════════════════════════════════════════════${C_NC}"
    echo -e "${C_CYAN}Running: $suite_name${C_NC}"
    echo -e "${C_CYAN}═══════════════════════════════════════════════════════${C_NC}"
    echo ""

    # Run test and capture output
    if zsh "$test_file"; then
        ((SUITES_PASSED++))
        echo ""
    else
        ((SUITES_FAILED++))
        echo ""
    fi
done

# Final summary
echo -e "${C_BOLD}╔═══════════════════════════════════════════════════════════════╗${C_NC}"
echo -e "${C_BOLD}║  Final Test Summary                                           ║${C_NC}"
echo -e "${C_BOLD}╚═══════════════════════════════════════════════════════════════╝${C_NC}"
echo ""
echo -e "  Test Suites: ${#test_files[@]}"
echo -e "  ${C_GREEN}Passed: $SUITES_PASSED${C_NC}"
echo -e "  ${C_RED}Failed: $SUITES_FAILED${C_NC}"
echo ""

if [[ $SUITES_FAILED -eq 0 ]]; then
    echo -e "${C_GREEN}${C_BOLD}✅ ALL TEST SUITES PASSED${C_NC}"
    echo ""
    exit 0
else
    echo -e "${C_RED}${C_BOLD}❌ SOME TEST SUITES FAILED${C_NC}"
    echo ""
    exit 1
fi
