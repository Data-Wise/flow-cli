#!/usr/bin/env zsh
# test-readonly-scope-regression.zsh - Regression test for ZSH readonly function-scope bug
#
# In ZSH, `readonly FOO=bar` is `typeset -r FOO=bar` and obeys function-local scoping.
# When a lib is sourced from inside a function (e.g., a test harness `setup()`),
# its `readonly` constants vanish when the calling function returns. The lib's
# load-guard pattern (`typeset -g _LIB_LOADED=1`) survives because of `-g`, but
# suppresses re-sourcing — leaving the constants permanently undefined. Symptom:
# arithmetic like `$((CONST * 10))` evaluates to `0`, downstream logic fails silently.
#
# Always use `typeset -gr` (or `typeset -gar` for arrays) for module-level
# constants in sourced libraries.
#
# See: f1939070 (doctor-cache fix), 9db49db9 (preventive fix in analysis-cache + macro-parser)
# Usage: zsh tests/test-readonly-scope-regression.zsh

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local test_name="$1"
    local test_func="$2"

    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "${CYAN}[$TESTS_RUN] $test_name...${RESET} "

    local output
    output=$(eval "$test_func" 2>&1)
    local rc=$?

    if [[ $rc -eq 0 ]]; then
        echo "${GREEN}PASS${RESET}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "${RED}FAIL${RESET}"
        echo "  ${DIM}$output${RESET}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Grep for module-level `readonly` declarations. Excludes:
# - lines inside comments (anywhere `# readonly` appears)
# - the typeset -gr / typeset -gar replacement (which is what we want)
_scan_for_bare_readonly() {
    local dir="$1"
    [[ -d "$dir" ]] || return 0
    grep -rEn '^[[:space:]]*readonly([[:space:]]|$)' "$dir" --include="*.zsh" 2>/dev/null \
        | grep -v ':[[:space:]]*#' \
        || true
}

echo ""
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo "${CYAN}  Regression: bare \`readonly\` at module scope (ZSH function-local trap)${RESET}"
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo ""

# ============================================================================
# TEST 1: No bare `readonly` in lib/
# ============================================================================

run_test "No bare 'readonly' in lib/*.zsh (use typeset -gr)" '
    violations=$(_scan_for_bare_readonly "$PROJECT_ROOT/lib")
    if [[ -n "$violations" ]]; then
        echo "Found bare readonly declarations in lib/ — replace with typeset -gr:"
        echo "$violations"
        return 1
    fi
'

# ============================================================================
# TEST 2: No bare `readonly` in commands/
# ============================================================================

run_test "No bare 'readonly' in commands/*.zsh (use typeset -gr)" '
    violations=$(_scan_for_bare_readonly "$PROJECT_ROOT/commands")
    if [[ -n "$violations" ]]; then
        echo "Found bare readonly declarations in commands/ — replace with typeset -gr:"
        echo "$violations"
        return 1
    fi
'

# ============================================================================
# TEST 3: No bare `readonly` in setup/ and hooks/
# ============================================================================

run_test "No bare 'readonly' in setup/ and hooks/ (use typeset -gr)" '
    violations="$(_scan_for_bare_readonly "$PROJECT_ROOT/setup")$(_scan_for_bare_readonly "$PROJECT_ROOT/hooks")"
    if [[ -n "$violations" ]]; then
        echo "Found bare readonly declarations — replace with typeset -gr:"
        echo "$violations"
        return 1
    fi
'

# ============================================================================
# TEST 4: Verify the actual ZSH behavior (functional proof)
# ============================================================================
# Demonstrates that `readonly` inside a function context produces a function-local
# variable that vanishes on return, while `typeset -gr` survives.

run_test "Verify: readonly inside function vanishes; typeset -gr survives" '
    proof_setup() {
        readonly _PROOF_LOCAL=42
        typeset -gr _PROOF_GLOBAL=42
    }
    proof_setup

    if [[ -n "$_PROOF_LOCAL" ]]; then
        echo "Bug not reproduced: readonly _PROOF_LOCAL survived as $_PROOF_LOCAL — ZSH semantics may have changed"
        return 1
    fi
    if [[ "$_PROOF_GLOBAL" != "42" ]]; then
        echo "typeset -gr did not persist: _PROOF_GLOBAL=\"$_PROOF_GLOBAL\""
        return 1
    fi
'

# ============================================================================
# TEST 5: Functional proof using a real fixture lib pattern
# ============================================================================
# Mirrors the actual bug scenario: sourcing a lib (with load-guard + readonly
# constants) from inside a function, then calling a lib function from outside
# the original sourcing context.

run_test "Verify: lib pattern with bare readonly fails after function returns" '
    fixture=$(mktemp -t lib-readonly-fixture.XXXXXX)
    # Single-quoted heredoc — body is verbatim, $((...)) is NOT expanded here.
    cat > "$fixture" <<'\''EOF'\''
[[ -n "$_FIXTURE_LOADED" ]] && return 0
typeset -g _FIXTURE_LOADED=1
readonly FIXTURE_BARE=2
typeset -gr FIXTURE_GLOBAL=2

fixture_compute() {
    print "$((FIXTURE_BARE * 10))/$((FIXTURE_GLOBAL * 10))"
}
EOF

    fixture_setup() {
        source "$fixture"
    }
    fixture_setup

    result=$(fixture_compute)
    rm -f "$fixture"

    # Expected (buggy) behavior: bare readonly is empty after setup() returns,
    # so its arithmetic evaluates to 0. typeset -gr survives, evaluates to 20.
    if [[ "$result" != "0/20" ]]; then
        echo "Bug not reproduced: expected \"0/20\" got \"$result\" — ZSH semantics may have changed"
        return 1
    fi
'

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
echo "${CYAN}──────────────────────────────────────────────────────────────${RESET}"
if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "${GREEN}All $TESTS_PASSED/$TESTS_RUN regression tests passed${RESET}"
    exit 0
else
    echo "${RED}$TESTS_FAILED/$TESTS_RUN tests failed${RESET}"
    echo "${YELLOW}Fix: Replace 'readonly FOO=bar' with 'typeset -gr FOO=bar' (or 'typeset -gar' for arrays).${RESET}"
    exit 1
fi
