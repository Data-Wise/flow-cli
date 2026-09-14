#!/bin/bash
# Run all flow-cli tests locally
# Usage: ./tests/run-all.sh

cd "$(dirname "$0")/.."
REPO_ROOT="$PWD"

# Pre-run baseline (#526 review): a bare post-run `git status --short` would
# misattribute any unrelated pre-existing uncommitted change to test
# pollution. Snapshotting now lets the end-of-run guard report only what
# actually changed during this invocation.
BASELINE_STATUS="$(git status --short 2>/dev/null)"

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

# Sandboxed CWD a suite can opt into (#526, run_test's 3rd arg = "sandbox"):
# a scratch project directory so a command that resolves its target via
# $PWD instead of an explicit argument — e.g. `win`/`focus` walking up via
# _flow_find_project_root — writes into a throwaway .STATUS instead of this
# repo's own tracked one. Not the default for every suite: most suites here
# anchor themselves off $0 instead of $PWD (see comment on run_test below)
# and were never audited against an unfamiliar CWD, so blanket-sandboxing
# every suite trades one class of bug for another. Opt in per suite instead.
# Fields are non-empty so assertions on command output (e.g. `focus`
# printing "Focus: ...") still have something to find.
read -r -d '' SANDBOX_STATUS_TEMPLATE <<'EOF'
## Project: sandbox
## Type: test
## Status: active
## Focus: sandbox testing session
## Phase: Testing
## Priority: 2
## Progress: 0
EOF

# Tracks whichever sandbox dir is currently in use so an interrupt (Ctrl-C)
# mid-suite doesn't leak it (#526 review) — _run_sandboxed's own `rm -rf`
# never runs if run-all.sh itself is killed before that line.
CURRENT_SANDBOX=""
_cleanup_sandbox_on_interrupt() {
    [[ -n "$CURRENT_SANDBOX" ]] && rm -rf "$CURRENT_SANDBOX"
    exit 130
}
trap _cleanup_sandbox_on_interrupt INT TERM

# Run one attempt of $1 (absolute path) with $2 as its interpreter, cd'd into
# a fresh throwaway project directory. The cd happens in a subshell so it
# never leaks back into run-all.sh's own CWD — no manual restore needed.
_run_sandboxed() {
    local abs_test_file="$1"
    local interpreter="$2"
    local timeout_seconds="$3"

    local sandbox
    sandbox=$(mktemp -d "${TMPDIR:-/tmp}/flow-test-sandbox.XXXXXX")
    CURRENT_SANDBOX="$sandbox"
    printf '%s\n' "$SANDBOX_STATUS_TEMPLATE" > "$sandbox/.STATUS"

    ( cd "$sandbox" && exec timeout "$timeout_seconds" "$interpreter" "$abs_test_file" ) > /dev/null 2>&1
    local rc=$?

    rm -rf "$sandbox"
    CURRENT_SANDBOX=""
    return $rc
}

run_test() {
    local test_file="$1"
    local name=$(basename "$test_file" .zsh)
    name=${name%.sh}
    # Default 30s; callers can override via $2 for tests that legitimately
    # need more (e.g., test-doctor runs full `doctor` 3× through brew/atlas/
    # plugin checks).
    local timeout_seconds="${2:-30}"
    # Pass "sandbox" as $3 to cd into a scratch project dir first (#526).
    local sandbox_mode="${3:-}"

    echo -n "Running $name... "

    # Resolve to an absolute path — needed unconditionally so a sandboxed
    # suite's own $0-based path resolution (many use `${0:A:h}` to find
    # fixtures or the plugin itself) still lands on the real repo rather
    # than wherever the sandbox happens to live.
    local abs_test_file="$REPO_ROOT/${test_file#./}"

    # Try zsh first, then bash, with 30s timeout
    if [[ "$sandbox_mode" == "sandbox" ]]; then
        _run_sandboxed "$abs_test_file" zsh "$timeout_seconds"
    else
        timeout "$timeout_seconds" zsh "$abs_test_file" > /dev/null 2>&1
    fi
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
        if [[ "$sandbox_mode" == "sandbox" ]]; then
            _run_sandboxed "$abs_test_file" bash "$timeout_seconds"
        else
            timeout "$timeout_seconds" bash "$abs_test_file" > /dev/null 2>&1
        fi
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
run_test ./tests/test-em-flag-star.zsh
run_test ./tests/test-em-ai-switch.zsh
run_test ./tests/test-em-ai-agy.zsh
run_test ./tests/test-em-move-restore.zsh
run_test ./tests/test-em-undo.zsh
run_test ./tests/test-tok.zsh
run_test ./tests/test-tok-sync.zsh

echo ""
echo "Core command tests:"
# These tests source flow.plugin.zsh in non-interactive mode
# (FLOW_PLUGIN_DIR, FLOW_QUIET, FLOW_ATLAS_ENABLED=no, exec < /dev/null)
run_test ./tests/test-flow-claude.zsh
run_test ./tests/test-dash.zsh
run_test ./tests/test-schedule.zsh
run_test ./tests/test-schedule-atlas-source.zsh
run_test ./tests/test-agenda.zsh
run_test ./tests/test-cadence-agenda.zsh
run_test ./tests/test-work.zsh
run_test ./tests/test-doctor.zsh 45
run_test ./tests/test-capture.zsh "" sandbox
run_test ./tests/test-pick-wt.zsh
run_test ./tests/test-adhd.zsh "" sandbox
run_test ./tests/test-path-bug-fix.zsh
run_test ./tests/test-status-field-parity.zsh
run_test ./tests/test-status-field-accessor.zsh
run_test ./tests/test-project-path-resolver.zsh
run_test ./tests/test-suggest-project.zsh
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
run_test ./tests/test-teach-dispatcher-definedness.zsh
run_test ./tests/test-teach-plan.zsh
run_test ./tests/test-teach-plan-security.zsh
run_test ./tests/test-teach-check.zsh
run_test ./tests/test-teach-dashboard.zsh
run_test ./tests/automated-teach-style-dogfood.zsh
run_test ./tests/dogfood-teach-deploy-v2.zsh
run_test ./tests/test-teach-deploy-v2-unit.zsh
run_test ./tests/test-teach-deploy-v2-integration.zsh
run_test ./tests/test-teach-deploy-dryrun-readonly.zsh
run_test ./tests/test-teach-deploy-merge-topology.zsh
run_test ./tests/test-changelog-parity.zsh
run_test ./tests/test-alias-shadowing.zsh
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
# Not tagged "sandbox": this suite's write target ($DEMO_COURSE/.teach/
# concepts.json) is $0-anchored, never $PWD-derived, so CWD-sandboxing
# would be a no-op here — it protects the fixture with its own
# backup_concepts/restore_concepts trap instead (#526 review).
run_test ./tests/e2e-teach-analyze.zsh
run_test ./tests/e2e-dot-safety.zsh
run_test ./tests/e2e-teach-deploy-v2.zsh
run_test ./tests/e2e-core-commands.zsh "" sandbox
run_test ./tests/e2e-plugin-system.zsh
run_test ./tests/e2e-teach-prompt.zsh
run_test ./tests/e2e-teach-doctor-v2.zsh
run_test ./tests/e2e-em-dispatcher.zsh
run_test ./tests/e2e-atlas-bridge.zsh
run_test ./tests/e2e-scholar-config-sync.zsh
run_test ./tests/e2e-tok-sync.zsh
run_test ./tests/e2e-agenda.zsh
run_test ./tests/e2e-agenda-atlas.zsh
run_test ./tests/e2e-doctor-install.zsh

echo ""
echo "Atlas contract tests:"
run_test ./tests/test-atlas-contract.zsh
run_test ./tests/test-doctor-atlas-calls.zsh

echo ""
echo "Additional unit tests:"
run_test ./tests/test-status-fields.zsh
run_test ./tests/test-status-schema.zsh
run_test ./tests/test-lint-e2e.zsh
run_test ./tests/test-teach-prompt-unit.zsh
run_test ./tests/test-scholar-config-sync.zsh

echo ""

# Regression guard (#526): a full run must never leave the working tree
# dirty. Sandboxing each suite's CWD (above) stops the known writers, but
# this is the systemic gate — it catches any future suite that resolves a
# write target via $PWD/an unsandboxed fixture path instead of an explicit
# scratch dir, whether or not it's one we already know about.
#
# Diffed against BASELINE_STATUS (captured before any suite ran), not a
# bare post-run snapshot — otherwise an unrelated pre-existing uncommitted
# change in the developer's own tree would be misattributed to test
# pollution. Computed and counted into FAIL *before* the "Results:" line
# below is printed, so that line always reflects the true outcome instead
# of reporting "0 failed" alongside a separate, uncounted dirty-tree error.
CURRENT_STATUS="$(cd "$REPO_ROOT" && git status --short 2>/dev/null)"
if [[ "$CURRENT_STATUS" != "$BASELINE_STATUS" ]]; then
    NEW_DIRT="$(comm -13 <(sort <<<"$BASELINE_STATUS") <(sort <<<"$CURRENT_STATUS"))"
    if [[ -n "$NEW_DIRT" ]]; then
        echo "❌ Working tree changed during the test run — a suite wrote to a"
        echo "   tracked file instead of a sandboxed scratch path:"
        echo "$NEW_DIRT" | sed 's/^/   /'
        echo ""
        ((FAIL++))
    fi
fi

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
