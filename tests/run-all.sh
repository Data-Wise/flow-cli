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
SKIP=0

# Exit code 77 = the suite (or its only meaningful cases) cleanly skipped
# because a required external tool/service is absent (atlas, ait/aiterm,
# himalaya, R, quarto, …). This is the standard automake "skip" code. A
# skipped suite is NOT a failure — it must never redden the gate — but it is
# surfaced distinctly so a skip is visible (and never silently masks a real
# pass that should have happened on a fully-provisioned runner).
readonly SKIP_RC=77

run_test() {
    local test_file="$1"
    local name=$(basename "$test_file" .zsh)
    name=${name%.sh}
    # Default 30s; callers can override via $2 for tests that legitimately
    # need more (e.g., test-doctor runs full `doctor` 3× through brew/atlas/
    # plugin checks).
    local timeout_seconds="${2:-30}"

    echo -n "Running $name... "

    # Try zsh first, then bash, with 30s timeout
    timeout "$timeout_seconds" zsh "$test_file" > /dev/null 2>&1
    local exit_code=$?

    if [[ $exit_code -eq 124 ]]; then
        # 124 = timeout
        echo "⏱️ (timeout after ${timeout_seconds}s)"
        ((TIMEOUT++))
    elif [[ $exit_code -eq $SKIP_RC ]]; then
        # 77 = clean skip (required tool/service absent)
        echo "⏭️  (skipped — required tool absent)"
        ((SKIP++))
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
        elif [[ $exit_code -eq $SKIP_RC ]]; then
            echo "⏭️  (skipped — required tool absent)"
            ((SKIP++))
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
run_test ./tests/test-dispatcher-binary-precedence.zsh
run_test ./tests/test-dot-chezmoi-safety.zsh
run_test ./tests/test-em-dispatcher.zsh
run_test ./tests/test-em-prompt-flag.zsh
run_test ./tests/test-em-help-guards.zsh
run_test ./tests/test-tok.zsh
run_test ./tests/test-tok-sync.zsh

echo ""
echo "Core command tests:"
# These tests source flow.plugin.zsh in non-interactive mode
# (FLOW_PLUGIN_DIR, FLOW_QUIET, FLOW_ATLAS_ENABLED=no, exec < /dev/null)
run_test ./tests/test-flow-claude.zsh
run_test ./tests/test-dash.zsh
run_test ./tests/test-schedule.zsh
run_test ./tests/test-agenda.zsh
run_test ./tests/test-cadence-agenda.zsh
run_test ./tests/test-work.zsh
run_test ./tests/test-doctor.zsh 45
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
run_test ./tests/test-readonly-scope-regression.zsh
run_test ./tests/test-terminal-hygiene-regression.zsh
run_test ./tests/test-manpage-version-sync.zsh

echo ""
echo "Dogfooding tests:"
run_test ./tests/automated-plugin-dogfood.zsh
run_test ./tests/dogfood-teach-doctor-v2.zsh
run_test ./tests/dogfood-em-dispatcher.zsh
run_test ./tests/dogfood-atlas-bridge.zsh
run_test ./tests/dogfood-scholar-config-sync.zsh
run_test ./tests/dogfood-agenda.zsh

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
run_test ./tests/e2e-atlas-bridge.zsh
run_test ./tests/e2e-scholar-config-sync.zsh
run_test ./tests/e2e-tok-sync.zsh
run_test ./tests/e2e-agenda.zsh

echo ""
echo "Atlas contract tests:"
run_test ./tests/test-atlas-contract.zsh
run_test ./tests/test-doctor-atlas-calls.zsh

echo ""
echo "Additional unit tests:"
run_test ./tests/test-status-fields.zsh
run_test ./tests/test-lint-e2e.zsh
run_test ./tests/test-teach-prompt-unit.zsh
run_test ./tests/test-scholar-config-sync.zsh

echo ""
echo "========================================="
echo "  Results: $PASS passed, $FAIL failed, $TIMEOUT timeout, $SKIP skipped"
echo "========================================="

if [[ $SKIP -gt 0 ]]; then
    echo ""
    echo "Note: $SKIP suite(s) skipped — a required external tool/service was"
    echo "absent (atlas, ait/aiterm, himalaya, R, quarto). Expected on a hosted"
    echo "CI runner; locally they run when the tool is installed."
fi

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi

if [[ $TIMEOUT -gt 0 ]]; then
    echo ""
    echo "Note: Timeout tests may require interactive/tmux context"
    exit 2
fi
