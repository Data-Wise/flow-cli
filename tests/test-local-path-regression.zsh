#!/usr/bin/env zsh
# test-local-path-regression.zsh - Regression test for ZSH $path shadowing bug
#
# In ZSH, `$path` (lowercase array) is tied to `$PATH` (uppercase string).
# Using `local path="value"` inside a function replaces the command search path,
# silently breaking all subsequent external command calls (yq, sed, jq, etc.)
# within that scope. This test ensures no production code uses `local path=`.
#
# See: ca512027 (codebase-wide cleanup)
# Usage: zsh tests/test-local-path-regression.zsh

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

echo ""
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo "${CYAN}  Regression: local path= ZSH \$path Shadowing Bug${RESET}"
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo ""

# ============================================================================
# TEST 1: No `local path=` in lib/ files
# ============================================================================

run_test "No 'local path=' in lib/*.zsh" '
    local violations=""
    violations=$(grep -rn "local path=" "$PROJECT_ROOT/lib/" --include="*.zsh" 2>/dev/null | grep -v "# " | grep -v "local path_" | grep -v "local pathname" | grep -v "local pathspec")
    if [[ -n "$violations" ]]; then
        echo "Found local path= in lib/:"
        echo "$violations"
        return 1
    fi
'

# ============================================================================
# TEST 2: No `local path=` in commands/ files
# ============================================================================

run_test "No 'local path=' in commands/*.zsh" '
    local violations=""
    violations=$(grep -rn "local path=" "$PROJECT_ROOT/commands/" --include="*.zsh" 2>/dev/null | grep -v "# " | grep -v "local path_" | grep -v "local pathname" | grep -v "local pathspec")
    if [[ -n "$violations" ]]; then
        echo "Found local path= in commands/:"
        echo "$violations"
        return 1
    fi
'

# ============================================================================
# TEST 3: No `local path=` in setup/ files
# ============================================================================

run_test "No 'local path=' in setup/*.zsh" '
    local violations=""
    violations=$(grep -rn "local path=" "$PROJECT_ROOT/setup/" --include="*.zsh" 2>/dev/null | grep -v "# " | grep -v "local path_" | grep -v "local pathname" | grep -v "local pathspec")
    if [[ -n "$violations" ]]; then
        echo "Found local path= in setup/:"
        echo "$violations"
        return 1
    fi
'

# ============================================================================
# TEST 4: No `local path=` in hooks/ files
# ============================================================================

run_test "No 'local path=' in hooks/*.zsh" '
    local violations=""
    violations=$(grep -rn "local path=" "$PROJECT_ROOT/hooks/" --include="*.zsh" 2>/dev/null | grep -v "# " | grep -v "local path_" | grep -v "local pathname" | grep -v "local pathspec")
    if [[ -n "$violations" ]]; then
        echo "Found local path= in hooks/:"
        echo "$violations"
        return 1
    fi
'

# ============================================================================
# TEST 5: No `local path=` in completions/ files
# ============================================================================

run_test "No 'local path=' in completions/" '
    local violations=""
    violations=$(grep -rn "local path=" "$PROJECT_ROOT/completions/" --include="*.zsh" --include="_*" 2>/dev/null | grep -v "# " | grep -v "local path_" | grep -v "local pathname" | grep -v "local pathspec")
    if [[ -n "$violations" ]]; then
        echo "Found local path= in completions/:"
        echo "$violations"
        return 1
    fi
'

# ============================================================================
# TEST 6: No `local path ` (space before =) variant
# ============================================================================

run_test "No 'local path ' (space variant) in production code" '
    local violations=""
    violations=$(grep -rn "local path " "$PROJECT_ROOT/lib/" "$PROJECT_ROOT/commands/" --include="*.zsh" 2>/dev/null | grep -v "# " | grep -v "local path_" | grep -v "local pathname" | grep -v "local pathspec")
    if [[ -n "$violations" ]]; then
        echo "Found local path (space) variant:"
        echo "$violations"
        return 1
    fi
'

# ============================================================================
# TEST 7: No `for path in` loop variable in production code
# ============================================================================

run_test "No 'for path in' loop variable in production code" '
    local violations=""
    violations=$(grep -rn "for path in" "$PROJECT_ROOT/lib/" "$PROJECT_ROOT/commands/" --include="*.zsh" 2>/dev/null | grep -v "# " | grep -v "for path_")
    if [[ -n "$violations" ]]; then
        echo "Found for path in loop:"
        echo "$violations"
        return 1
    fi
'

# ============================================================================
# TEST 8: Verify the actual ZSH behavior (functional proof)
# ============================================================================

run_test "Verify: local path= actually breaks command lookup" '
    # This test proves the bug is real — if it passes, the guard is justified
    broken_func() {
        local path="/tmp/nothing"
        command -v ls 2>/dev/null
    }
    working_func() {
        local dir_path="/tmp/nothing"
        command -v ls 2>/dev/null
    }

    local broken_result working_result
    broken_result=$(broken_func)
    working_result=$(working_func)

    # broken_func should NOT find ls (path is shadowed)
    # working_func SHOULD find ls
    if [[ -z "$broken_result" && -n "$working_result" ]]; then
        return 0
    else
        echo "Bug not reproduced: broken='$broken_result' working='$working_result'"
        return 1
    fi
'

# ============================================================================
# TEST 9: No `local fpath=` which shadows ZSH $fpath (function autoloading)
# ============================================================================

run_test "No 'local fpath=' in production code (shadows \$fpath autoload)" '
    local violations=""
    violations=$(grep -rn "local fpath=" "$PROJECT_ROOT/lib/" "$PROJECT_ROOT/commands/" --include="*.zsh" 2>/dev/null | grep -v "# ")
    if [[ -n "$violations" ]]; then
        echo "Found local fpath= (shadows function autoloading):"
        echo "$violations"
        return 1
    fi
'

# ============================================================================
# TEST 10: No `local cdpath=` which shadows ZSH $cdpath
# ============================================================================

run_test "No 'local cdpath=' in production code (shadows \$cdpath)" '
    local violations=""
    violations=$(grep -rn "local cdpath=" "$PROJECT_ROOT/lib/" "$PROJECT_ROOT/commands/" --include="*.zsh" 2>/dev/null | grep -v "# ")
    if [[ -n "$violations" ]]; then
        echo "Found local cdpath= (shadows cd search path):"
        echo "$violations"
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
    echo "${YELLOW}Fix: Rename 'local path=' to 'local src_path=', 'file_path=', etc.${RESET}"
    exit 1
fi
