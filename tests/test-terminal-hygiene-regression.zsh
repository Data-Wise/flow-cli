#!/usr/bin/env zsh
# test-terminal-hygiene-regression.zsh - Regression guard for v7.7.1 terminal-handoff fixes
#
# Two fixes ship in v7.7.1, both about not corrupting the terminal on handoff:
#
#  1. pick (commands/pick.zsh): after fzf, reset focus/mouse/paste modes and drain
#     stray query responses before returning, so the next TUI (Claude Code via
#     cc/ccy/work) inherits a clean terminal. The cleanup is TTY-guarded and writes
#     to /dev/tty — so it CANNOT be tested by capturing stdout. We assert the
#     source-level invariant instead (the cleanup exists, complete, correctly placed).
#
#  2. zsh/.zshrc: iTerm2 shell integration + context-switcher are gated behind
#     TERM_PROGRAM == "iTerm.app" so they don't leak OSC 1337 under Ghostty et al.
#
# See: d4ced8b5 (pick fix), 92406b49 (iTerm2 gating), CHANGELOG [7.7.1].
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

PICK="$PROJECT_ROOT/commands/pick.zsh"
ZSHRC="$PROJECT_ROOT/zsh/.zshrc"

# Isolate just the post-fzf cleanup region (lines after the last fzf call).
_cleanup_block() {
    awk '/Clean terminal handoff after fzf/{f=1} f{print} /rm -f "\$tmpfile"/{if(f)exit}' "$PICK"
}

# ── 1. pick cleanup present & correct ───────────────────────────────────────

run_test "all 6 terminal reset modes present" '
    block=$(_cleanup_block)
    for code in 1004 1000 1002 1003 1006 2004; do
        echo "$block" | grep -q "?${code}l" || { echo "missing reset mode $code"; exit 1; }
    done
'

run_test "cleanup is TTY-guarded (never fires into a pipe)" '
    _cleanup_block | grep -qE "\[\[ -t 1 \]\]" || { echo "cleanup not guarded by [[ -t 1 ]]"; exit 1; }
'

run_test "reset is written to /dev/tty, not stdout" '
    _cleanup_block | grep -q "printf .*> */dev/tty" || { echo "reset not directed to /dev/tty"; exit 1; }
'

# Task 2 — assert the input-drain loop is present and reads from /dev/tty.
# Real line: while read -t 0.05 -k 1 _flow_discard 2>/dev/null; do : ; done < /dev/tty
# Match the INVARIANT (timed read loop draining from /dev/tty), not the exact
# timeout value — a hard-match on -t 0.05 would false-alarm on a harmless tune,
# while a bare `grep read` would let a regression that drops `< /dev/tty` slip by.
run_test "input-drain loop reads from /dev/tty" '
    block=$(_cleanup_block)
    echo "$block" | grep -qE "while[[:space:]]+read[[:space:]].*-t[[:space:]]" \
        || { echo "no timed read loop found"; exit 1; }
    echo "$block" | grep -qE "done[[:space:]]*<[[:space:]]*/dev/tty" \
        || { echo "drain loop does not read from /dev/tty"; exit 1; }
'

run_test "cleanup appears AFTER the fzf call (ordering invariant)" '
    fzf_line=$(grep -n "fzf_exit=\$?" "$PICK" | head -1 | cut -d: -f1)
    clean_line=$(grep -n "Clean terminal handoff after fzf" "$PICK" | head -1 | cut -d: -f1)
    [[ -n "$fzf_line" && -n "$clean_line" && "$clean_line" -gt "$fzf_line" ]] \
        || { echo "cleanup ($clean_line) not after fzf ($fzf_line)"; exit 1; }
'

# ── 2. iTerm2 gating in zsh/.zshrc ──────────────────────────────────────────

run_test "every iTerm2 source line is gated by TERM_PROGRAM" '
    [[ -f "$ZSHRC" ]] || { echo "zsh/.zshrc not found"; exit 1; }
    # A source/test-e of an iTerm2 integration file is gated if TERM_PROGRAM
    # appears either on that line OR on the immediately preceding line (the
    # codebase uses both an inline gate and a [[ ... ]] && \ continuation gate).
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
    echo "${YELLOW}These guard the v7.7.1 terminal-handoff fixes — see CHANGELOG [7.7.1].${RESET}"
    exit 1
fi
