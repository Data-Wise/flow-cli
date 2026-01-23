#!/bin/bash
# Run all flow-cli tests locally
# Usage: ./tests/run-all.sh

cd "$(dirname "$0")/.."

echo "========================================="
echo "  flow-cli Local Test Suite"
echo "========================================="
echo ""

PASS=0
FAIL=0
TIMEOUT=0

run_test() {
    local test_file="$1"
    local name=$(basename "$test_file" .zsh)
    name=${name%.sh}
    local timeout_seconds=30

    echo -n "Running $name... "

    # Try zsh first, then bash, with 30s timeout
    timeout "$timeout_seconds" zsh "$test_file" > /dev/null 2>&1
    local exit_code=$?

    if [[ $exit_code -eq 124 ]]; then
        # 124 = timeout
        echo "⏱️ (timeout after ${timeout_seconds}s)"
        ((TIMEOUT++))
    elif [[ $exit_code -eq 0 ]]; then
        echo "✅"
        ((PASS++))
    else
        # Try bash as fallback
        timeout "$timeout_seconds" bash "$test_file" > /dev/null 2>&1
        exit_code=$?

        if [[ $exit_code -eq 124 ]]; then
            echo "⏱️ (timeout after ${timeout_seconds}s)"
            ((TIMEOUT++))
        elif [[ $exit_code -eq 0 ]]; then
            echo "✅"
            ((PASS++))
        else
            echo "❌"
            ((FAIL++))
        fi
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
# Note: test-dash, test-work, test-doctor, test-adhd, test-flow may timeout
# These source flow.plugin.zsh which requires interactive/tmux context
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
echo "Optimization tests (v5.16.0):"
run_test ./tests/test-plugin-optimization.zsh

echo ""
echo "========================================="
echo "  Results: $PASS passed, $FAIL failed, $TIMEOUT timeout"
echo "========================================="

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi

if [[ $TIMEOUT -gt 0 ]]; then
    echo ""
    echo "Note: Timeout tests may require interactive/tmux context"
    exit 2
fi
