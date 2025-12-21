#!/usr/bin/env zsh
# Test script for dispatcher enhancements
# Tests new keywords added to r, qu, v, cc, and pick dispatchers

echo "Testing Dispatcher Enhancements"
echo "================================"
echo ""

# Source the dispatcher files
source /Users/dt/.config/zsh/functions/smart-dispatchers.zsh
source /Users/dt/.config/zsh/functions/v-dispatcher.zsh

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

test_dispatcher_keyword() {
    local dispatcher="$1"
    local keyword="$2"
    local expected_pattern="$3"

    echo -n "Testing: $dispatcher $keyword ... "

    # Run the dispatcher with help to see if keyword is listed
    local output=$($dispatcher help 2>&1)

    if echo "$output" | grep -q "$expected_pattern"; then
        echo "✓ PASS"
        ((TESTS_PASSED++))
    else
        echo "✗ FAIL (keyword not found in help)"
        ((TESTS_FAILED++))
    fi
}

echo "Task 2.1: r dispatcher new keywords"
echo "------------------------------------"
test_dispatcher_keyword "r" "clean" "r clean"
test_dispatcher_keyword "r" "deep" "r deep"
test_dispatcher_keyword "r" "tex" "r tex"
test_dispatcher_keyword "r" "commit" "r commit"
echo ""

echo "Task 2.2: qu dispatcher new keywords"
echo "-------------------------------------"
test_dispatcher_keyword "qu" "pdf" "qu pdf"
test_dispatcher_keyword "qu" "html" "qu html"
test_dispatcher_keyword "qu" "docx" "qu docx"
test_dispatcher_keyword "qu" "commit" "qu commit"
test_dispatcher_keyword "qu" "article" "qu article"
test_dispatcher_keyword "qu" "present" "qu present"
echo ""

echo "Task 2.3: v dispatcher new keywords"
echo "------------------------------------"
test_dispatcher_keyword "v" "start" "v start"
test_dispatcher_keyword "v" "end" "v end"
test_dispatcher_keyword "v" "morning" "v morning"
test_dispatcher_keyword "v" "night" "v night"
test_dispatcher_keyword "v" "progress" "v progress"
echo ""

echo "Task 2.5: cc dispatcher verification"
echo "-------------------------------------"
test_dispatcher_keyword "cc" "latest" "cc latest"
test_dispatcher_keyword "cc" "haiku" "cc haiku"
test_dispatcher_keyword "cc" "sonnet" "cc sonnet"
test_dispatcher_keyword "cc" "opus" "cc opus"
test_dispatcher_keyword "cc" "plan" "cc plan"
test_dispatcher_keyword "cc" "auto" "cc auto"
test_dispatcher_keyword "cc" "yolo" "cc yolo"
echo ""

echo "Summary"
echo "-------"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "✓ All tests passed!"
    exit 0
else
    echo "✗ Some tests failed"
    exit 1
fi
