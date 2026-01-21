#!/usr/bin/env zsh
# run-wave-2-tests.sh - Run all Wave 2 parallel rendering tests
# Part of flow-cli v5.14.0 - Wave 2: Parallel Rendering Infrastructure

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test directory
TEST_DIR="${0:A:h}"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Wave 2: Parallel Rendering Infrastructure - Test Suite${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

total_passed=0
total_failed=0
total_tests=0

# Test 1: Render Queue Tests
echo -e "${YELLOW}Running: test-render-queue-unit.zsh${NC}"
echo "─────────────────────────────────────────────────────────────────────"
"$TEST_DIR/test-render-queue-unit.zsh" > /tmp/test-queue.log 2>&1
queue_exit=$?

queue_passed=$(sed 's/\[[0-9;]*m//g' /tmp/test-queue.log | grep "Passed:" | grep -o '[0-9]*' | head -1)
queue_failed=$(sed 's/\[[0-9;]*m//g' /tmp/test-queue.log | grep "Failed:" | grep -o '[0-9]*' | tail -1)
queue_total=$((queue_passed + queue_failed))

if [[ $queue_exit -eq 0 ]]; then
    echo -e "${GREEN}✓${NC} test-render-queue-unit.zsh"
else
    echo -e "${RED}✗${NC} test-render-queue-unit.zsh"
fi
echo "  Passed: ${queue_passed}/${queue_total}"
echo ""

total_passed=$((total_passed + queue_passed))
total_failed=$((total_failed + queue_failed))
total_tests=$((total_tests + queue_total))

# Test 2: Parallel Rendering Tests
echo -e "${YELLOW}Running: test-parallel-rendering-unit.zsh${NC}"
echo "─────────────────────────────────────────────────────────────────────"
"$TEST_DIR/test-parallel-rendering-unit.zsh" > /tmp/test-parallel.log 2>&1
parallel_exit=$?

parallel_passed=$(sed 's/\[[0-9;]*m//g' /tmp/test-parallel.log | grep "Passed:" | grep -o '[0-9]*' | head -1)
parallel_failed=$(sed 's/\[[0-9;]*m//g' /tmp/test-parallel.log | grep "Failed:" | grep -o '[0-9]*' | tail -1)
parallel_total=$((parallel_passed + parallel_failed))

if [[ $parallel_exit -eq 0 ]]; then
    echo -e "${GREEN}✓${NC} test-parallel-rendering-unit.zsh"
else
    echo -e "${RED}✗${NC} test-parallel-rendering-unit.zsh"
fi
echo "  Passed: ${parallel_passed}/${parallel_total}"
echo ""

total_passed=$((total_passed + parallel_passed))
total_failed=$((total_failed + parallel_failed))
total_tests=$((total_tests + parallel_total))

# Summary
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}OVERALL SUMMARY${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Total tests run:    ${total_tests}"
echo -e "${GREEN}Tests passed:       ${total_passed}${NC}"
if [[ $total_failed -gt 0 ]]; then
    echo -e "${RED}Tests failed:       ${total_failed}${NC}"
else
    echo -e "Tests failed:       ${total_failed}"
fi
echo ""

if [[ $total_failed -eq 0 ]]; then
    echo -e "${GREEN}All tests passed! ✓${NC}"
    echo ""
    echo "Wave 2 implementation is complete and ready for integration."
    exit 0
else
    echo -e "${RED}Some tests failed. ✗${NC}"
    echo ""
    echo "Check logs for details:"
    echo "  - /tmp/test-queue.log"
    echo "  - /tmp/test-parallel.log"
    exit 1
fi
