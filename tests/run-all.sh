#!/bin/bash
# Run all flow-cli tests locally
# Usage: ./tests/run-all.sh

set -e
cd "$(dirname "$0")/.."

echo "========================================="
echo "  flow-cli Local Test Suite"
echo "========================================="
echo ""

PASS=0
FAIL=0

run_test() {
    local test_file="$1"
    local name=$(basename "$test_file" .zsh)
    name=${name%.sh}

    echo -n "Running $name... "
    if zsh "$test_file" > /dev/null 2>&1 || bash "$test_file" > /dev/null 2>&1; then
        echo "✅"
        ((PASS++))
    else
        echo "❌"
        ((FAIL++))
    fi
}

echo "Dispatcher tests:"
run_test ./tests/test-pick-smart-defaults.zsh
run_test ./tests/test-cc-dispatcher.zsh
run_test ./tests/test-g-feature.zsh
run_test ./tests/test-wt-dispatcher.zsh
run_test ./tests/test-r-dispatcher.zsh
run_test ./tests/test-qu-dispatcher.zsh
run_test ./tests/test-mcp-dispatcher.zsh
run_test ./tests/test-obs-dispatcher.zsh

echo ""
echo "Core command tests:"
run_test ./tests/test-dash.zsh
run_test ./tests/test-work.zsh
run_test ./tests/test-doctor.zsh
run_test ./tests/test-capture.zsh
run_test ./tests/test-pick-wt.zsh
run_test ./tests/test-adhd.zsh
run_test ./tests/test-flow.zsh
run_test ./tests/test-timer.zsh

echo ""
echo "CLI tests:"
run_test ./tests/cli/automated-tests.sh
run_test ./tests/test-install.sh

echo ""
echo "========================================="
echo "  Results: $PASS passed, $FAIL failed"
echo "========================================="

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
