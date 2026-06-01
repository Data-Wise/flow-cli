# ORCHESTRATE: terminal-hygiene regression tests

**Branch:** `feature/terminal-hygiene-tests` (off `dev` @ 50558df4)
**Worktree:** `~/.git-worktrees/flow-cli/terminal-hygiene-tests`
**Created:** 2026-06-01
**Goal:** Add a regression guard for the two v7.7.1 terminal-handoff fixes so they can't silently regress.

> ⚠️ **This file is a working artifact** — delete it as part of the merge to `dev` (per global workflow rule).

---

## Why

v7.7.1 shipped two bug fixes with **no test coverage**:

1. **`pick` terminal handoff** (`commands/pick.zsh:1159-1167`, commit `d4ced8b5`) — after `fzf`, reset focus/mouse/paste modes + drain the input buffer before returning, so the next TUI (Claude Code via `cc`/`ccy`/`work`) gets a clean terminal.
2. **iTerm2 gating** (`zsh/.zshrc:1022,1061`, commit `92406b49`) — iTerm2 shell integration + context-switcher gated behind `TERM_PROGRAM == "iTerm.app"` so they don't leak OSC 1337 under Ghostty et al.

Both fixes are **invisible to behavioral testing** in `tests/run-all.sh`: the `pick` cleanup is guarded by `[[ -t 1 ]]` (false under a piped harness) and writes to `/dev/tty` (uncapturable by `$(...)`). So the correct strategy is a **source-scanning regression guard** — the same pattern as `tests/test-readonly-scope-regression.zsh` and `tests/test-local-path-regression.zsh`. It asserts the *invariant* (cleanup exists, complete, correctly placed; iTerm2 sources gated), not the runtime effect.

---

## Scope

**In scope**
- New file `tests/test-terminal-hygiene-regression.zsh` (source-scan regression guard).
- Wire it into `tests/run-all.sh` regression section.
- Update test-count references if the suite counts files (see Task 4).

**Out of scope (note, don't do)**
- A `zpty`-based behavioral test (heavier, fragile, needs a stubbed `fzf`). Record as a possible follow-up; do **not** build it here unless explicitly requested.
- Any change to `commands/pick.zsh` or `zsh/.zshrc` themselves — this branch is **tests only**.

---

## Tasks

### Task 1 — Create the test file
Create `tests/test-terminal-hygiene-regression.zsh` with the content in **Appendix A** below. Self-contained (own `run_test`/colors/summary), modeled on `test-readonly-scope-regression.zsh`. `chmod +x` to match siblings.

### Task 2 — Fill the one open assertion (the deliberate decision point)
The `input-drain loop reads from /dev/tty` test is left as a `TODO(you)`. Implement its body (3-5 lines).

**Design decision — matching strictness:**
- Too strict (hard-match `-t 0.05`) → false alarm when someone tunes the timeout.
- Too loose (just `grep read`) → a regression dropping `< /dev/tty` or the loop slips through.
- **Invariant that matters:** a timed `read` loop that pulls from `/dev/tty`.

Suggested shape (adjust to taste):
```zsh
run_test "input-drain loop reads from /dev/tty" '
    block=$(_cleanup_block)
    echo "$block" | grep -qE "while[[:space:]]+read[[:space:]].*-t[[:space:]]" \
        || { echo "no timed read loop found"; exit 1; }
    echo "$block" | grep -qE "done[[:space:]]*<[[:space:]]*/dev/tty" \
        || { echo "drain loop does not read from /dev/tty"; exit 1; }
'
```

### Task 3 — Verify the file passes against current (fixed) source
```bash
cd ~/.git-worktrees/flow-cli/terminal-hygiene-tests
zsh tests/test-terminal-hygiene-regression.zsh   # expect: All 8/8 regression tests passed
```
**Prove it actually guards** (mutation test — must FAIL when the fix is removed):
```bash
# temporarily break the guard, confirm the test catches it, then restore
cp commands/pick.zsh /tmp/pick.bak
sed -i '' 's/\[\[ -t 1 \]\]/[[ -t 99 ]]/' commands/pick.zsh   # neuter one invariant
zsh tests/test-terminal-hygiene-regression.zsh ; echo "exit=$?"  # expect non-zero
cp /tmp/pick.bak commands/pick.zsh                              # RESTORE — leave source untouched
```
Do the same one-line mutation for an iTerm2 gate line in `zsh/.zshrc`. **Always restore** — this branch must not modify `pick.zsh`/`.zshrc`.

### Task 4 — Wire into the runner
Add to the **Regression tests** section of `tests/run-all.sh` (next to `test-readonly-scope-regression` / `test-local-path-regression`):
```
Running test-terminal-hygiene-regression... <result>
```
Confirm the runner picks it up: `./tests/run-all.sh 2>&1 | grep terminal-hygiene`.
If any doc states the regression-test count (e.g. "2 regression tests"), bump it. Grep: `grep -rn "regression test" docs/ CLAUDE.md`.

### Task 5 — CHANGELOG
Add under a fresh `## [Unreleased]` (above `## [7.7.1]`) in **both** `CHANGELOG.md` and `docs/CHANGELOG.md` (they must mirror):
```
### Added
- **Regression guard `tests/test-terminal-hygiene-regression.zsh`** — source-scan
  test locking in the v7.7.1 terminal-handoff fixes (pick post-fzf cleanup + iTerm2
  TERM_PROGRAM gating) so they can't silently regress.
```

### Task 6 — Commit, integrate, clean up
- Conventional commit: `test(pick): add terminal-hygiene regression guard for v7.7.1 fixes`
- **Delete this `ORCHESTRATE-*.md`** before opening the PR.
- `./tests/run-all.sh` green (modulo known IMAP timeout), `source flow.plugin.zsh` clean.
- `gh pr create --base dev` (do NOT target main; tests don't need a release).
- After merge: `git worktree remove ~/.git-worktrees/flow-cli/terminal-hygiene-tests`, delete branch, update `.STATUS` worktree note.

---

## Verification checklist
- [ ] `zsh tests/test-terminal-hygiene-regression.zsh` → 8/8 pass against fixed source
- [ ] Mutation test: each invariant FAILS when its fix is removed (then source restored)
- [ ] `pick.zsh` and `zsh/.zshrc` are **unmodified** on this branch (`git diff --stat` shows only the test + runner + changelog)
- [ ] Wired into `run-all.sh`; appears in output
- [ ] CHANGELOGs mirror; counts updated if referenced
- [ ] ORCHESTRATE file deleted before PR

---

## Files touched
| File | Action |
|------|--------|
| `tests/test-terminal-hygiene-regression.zsh` | **new** |
| `tests/run-all.sh` | edit (add to regression section) |
| `CHANGELOG.md` + `docs/CHANGELOG.md` | edit (new Unreleased entry) |
| docs with regression-test counts | edit (only if a count is stated) |

---

## Appendix A — full test file

```zsh
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

# TODO(you) — Task 2. Assert the input-drain loop is present and reads from /dev/tty.
# Real line: while read -t 0.05 -k 1 _flow_discard 2>/dev/null; do : ; done < /dev/tty
# Match the INVARIANT (timed read loop from /dev/tty), not the exact timeout value.
run_test "input-drain loop reads from /dev/tty" '
    block=$(_cleanup_block)
    # TODO: your assertion here — exit 1 with a message on failure
    echo "not yet implemented"; exit 1
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
    while IFS= read -r line; do
        echo "$line" | grep -q "TERM_PROGRAM" \
            || { echo "ungated iTerm2 source: $line"; exit 1; }
    done < <(grep -nE "(source|test -e).*iterm2" "$ZSHRC" | grep -iE "integration")
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
```
