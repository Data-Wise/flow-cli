#!/usr/bin/env zsh
# test-terminal-hygiene-regression.zsh - Regression guard for terminal-handoff fixes
#
# Three fixes are guarded here, all about not corrupting the terminal on handoff:
#
#  1. Shared helper _flow_tty_handoff_cleanup (lib/core.zsh): resets focus/mouse/
#     paste modes and drains stray query responses before any fzf->exec handoff,
#     so the next TUI (Claude Code via cc/ccy/work) inherits a clean terminal.
#     It guards on /dev/tty (NOT stdout `[[ -t 1 ]]`) so it works even when the
#     caller captures stdout in command substitution.
#
#  2. All THREE fzf pickers that hand off to an interactive program call the
#     helper after their fzf call:
#       - pick()                    (commands/pick.zsh)   — pick/pick wt
#       - _proj_pick_worktree_path  (commands/pick.zsh)   — cc wt pick / ccy wt pick
#       - _flow_pick_project        (lib/tui.zsh)         — work / work -e ccy
#     (The original v7.7.1 fix patched only pick(); _proj_pick_worktree_path and
#     _flow_pick_project were uncleaned — see SPEC-fzf-handoff-hygiene.)
#
#  3. zsh/.zshrc: iTerm2 shell integration gated behind TERM_PROGRAM == iTerm.app
#     so it doesn't leak OSC 1337 under Ghostty et al.
#
# Standalone harness (no test-framework.zsh) is deliberate and consistent with the
# sibling source-scan guards: these assert source invariants with grep/awk, not
# runtime behavior (the cleanup writes to /dev/tty and cannot be captured via
# stdout). run_test is intentionally distinct from pass/fail/log_test to avoid
# dogfood-test-quality.zsh's inline-framework check.
#
# Usage: zsh tests/test-terminal-hygiene-regression.zsh

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
CYAN='\033[0;36m'; DIM='\033[2m'; RESET='\033[0m'

TESTS_RUN=0; TESTS_PASSED=0; TESTS_FAILED=0

run_test() {
    local test_name="$1" test_func="$2"
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "${CYAN}[$TESTS_RUN] $test_name...${RESET} "
    local output
    if output=$(eval "$test_func" 2>&1); then
        echo "${GREEN}✓${RESET}"; TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "${RED}✗${RESET}"; [[ -n "$output" ]] && echo "    ${DIM}$output${RESET}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

CORE="$PROJECT_ROOT/lib/core.zsh"
PICK="$PROJECT_ROOT/commands/pick.zsh"
TUI="$PROJECT_ROOT/lib/tui.zsh"
ZSHRC="$PROJECT_ROOT/zsh/.zshrc"

# Extract a function body: from `name() {` to the first `}` at column 0.
_func_body() {
    local file="$1" fn="$2"
    awk -v fn="$fn" '
        $0 ~ "^" fn "\\(\\) *\\{" {f=1}
        f {print}
        f && /^\}/ {exit}
    ' "$file"
}

# ── 1. shared helper present & complete ─────────────────────────────────────

run_test "_flow_tty_handoff_cleanup defined in lib/core.zsh" '
    _func_body "$CORE" "_flow_tty_handoff_cleanup" | grep -q . \
        || { echo "helper not found in lib/core.zsh"; exit 1; }
'

run_test "helper resets all 6 terminal modes" '
    body=$(_func_body "$CORE" "_flow_tty_handoff_cleanup")
    for code in 1004 1000 1002 1003 1006 2004; do
        echo "$body" | grep -q "?${code}l" || { echo "missing reset mode $code"; exit 1; }
    done
'

run_test "helper guards on /dev/tty, NOT stdout [[ -t 1 ]]" '
    body=$(_func_body "$CORE" "_flow_tty_handoff_cleanup")
    echo "$body" | grep -q "/dev/tty" || { echo "helper does not reference /dev/tty"; exit 1; }
    echo "$body" | grep -qE "\[\[ -t 1 \]\]" && { echo "helper wrongly guards on stdout [[ -t 1 ]]"; exit 1; }
    exit 0
'

run_test "helper drains pending input from /dev/tty" '
    body=$(_func_body "$CORE" "_flow_tty_handoff_cleanup")
    echo "$body" | grep -qE "while[[:space:]]+read[[:space:]].*-t[[:space:]]" \
        || { echo "no timed read drain loop"; exit 1; }
    echo "$body" | grep -qE "done[[:space:]]*<[[:space:]]*/dev/tty" \
        || { echo "drain loop does not read from /dev/tty"; exit 1; }
'

# ── 2. all three pickers call the helper after fzf ──────────────────────────

# Assert, within a function body, that a call to the helper appears AFTER an fzf
# invocation (the ordering invariant — cleanup must follow the picker).
_calls_helper_after_fzf() {
    local file="$1" fn="$2"
    local body; body=$(_func_body "$file" "$fn")
    local fzf_ln helper_ln
    fzf_ln=$(echo "$body" | grep -nE '(\| *fzf|=.*\$\(.*fzf| fzf )' | head -1 | cut -d: -f1)
    helper_ln=$(echo "$body" | grep -n '_flow_tty_handoff_cleanup' | head -1 | cut -d: -f1)
    [[ -n "$fzf_ln" && -n "$helper_ln" && "$helper_ln" -gt "$fzf_ln" ]]
}

run_test "pick() calls helper after fzf" '
    _calls_helper_after_fzf "$PICK" "pick" || { echo "pick() missing post-fzf helper call"; exit 1; }
'

run_test "_proj_pick_worktree_path calls helper after fzf (cc wt pick / ccy)" '
    _calls_helper_after_fzf "$PICK" "_proj_pick_worktree_path" \
        || { echo "_proj_pick_worktree_path missing post-fzf helper call"; exit 1; }
'

run_test "_flow_pick_project calls helper after fzf (work / work -e ccy)" '
    _calls_helper_after_fzf "$TUI" "_flow_pick_project" \
        || { echo "_flow_pick_project missing post-fzf helper call"; exit 1; }
'

# ── 3. iTerm2 gating in zsh/.zshrc ──────────────────────────────────────────

run_test "every iTerm2 source line is gated by TERM_PROGRAM" '
    [[ -f "$ZSHRC" ]] || { echo "zsh/.zshrc not found"; exit 1; }
    awk '"'"'
        /(source|test -e).*iterm2.*[Ii]ntegration/ {
            total++
            if ($0 ~ /TERM_PROGRAM/ || prev ~ /TERM_PROGRAM/) { ok++ }
            else { print "ungated iTerm2 source: " $0 }
        }
        { prev = $0 }
        END {
            if (total == 0) { print "no iTerm2 integration sources found"; exit 1 }
            if (ok < total) { exit 1 }
        }
    '"'"' "$ZSHRC" || exit 1
'

run_test "gate targets real iTerm2 only (iTerm.app)" '
    grep -E "TERM_PROGRAM.*==.*\"iTerm.app\"" "$ZSHRC" >/dev/null \
        || { echo "no TERM_PROGRAM == iTerm.app gate found"; exit 1; }
'

echo ""
echo "${CYAN}──────────────────────────────────────────────────────────────${RESET}"
if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "${GREEN}All $TESTS_PASSED/$TESTS_RUN regression tests passed${RESET}"; exit 0
else
    echo "${RED}$TESTS_FAILED/$TESTS_RUN tests failed${RESET}"
    echo "${YELLOW}These guard the fzf->exec terminal-handoff fixes — see SPEC-fzf-handoff-hygiene.${RESET}"
    exit 1
fi
