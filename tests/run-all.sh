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
run_test ./tests/test-dot-chezmoi-safety.zsh
run_test ./tests/test-em-dispatcher.zsh

echo ""
echo "Core command tests:"
# These tests source flow.plugin.zsh in non-interactive mode
# (FLOW_PLUGIN_DIR, FLOW_QUIET, FLOW_ATLAS_ENABLED=no, exec < /dev/null)
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
echo "Teach command tests:"
run_test ./tests/test-teach-plan.zsh
run_test ./tests/test-teach-plan-security.zsh
run_test ./tests/automated-teach-style-dogfood.zsh
run_test ./tests/dogfood-teach-deploy-v2.zsh
run_test ./tests/test-teach-deploy-v2-unit.zsh
run_test ./tests/test-teach-deploy-v2-integration.zsh
run_test ./tests/test-production-conflict-detection.zsh

echo ""
echo "Help compliance tests:"
run_test ./tests/test-help-compliance.zsh
run_test ./tests/test-help-compliance-dogfood.zsh

echo ""
echo "Regression tests:"
run_test ./tests/test-local-path-regression.zsh

echo ""
echo "Dogfooding tests:"
run_test ./tests/automated-plugin-dogfood.zsh
run_test ./tests/dogfood-teach-doctor-v2.zsh
run_test ./tests/dogfood-em-dispatcher.zsh

echo ""
echo "E2E tests:"
run_test ./tests/e2e-teach-plan.zsh
run_test ./tests/e2e-teach-analyze.zsh
run_test ./tests/e2e-dot-safety.zsh
run_test ./tests/e2e-teach-deploy-v2.zsh
run_test ./tests/e2e-core-commands.zsh
run_test ./tests/e2e-plugin-system.zsh
run_test ./tests/e2e-teach-prompt.zsh
run_test ./tests/e2e-teach-doctor-v2.zsh
run_test ./tests/e2e-em-dispatcher.zsh

echo ""
echo "Additional unit tests:"
run_test ./tests/test-status-fields.zsh
run_test ./tests/test-lint-e2e.zsh
run_test ./tests/test-teach-prompt-unit.zsh

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
