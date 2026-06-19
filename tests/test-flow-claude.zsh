#!/usr/bin/env zsh
# tests/test-flow-claude.zsh — Tests for flow claude check (C1-C5)

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh"

# Source plugin once — injectable paths are per-test env vars, not per-source
export FLOW_QUIET=1
source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null

test_suite_start "flow claude check"

# ── Helpers ───────────────────────────────────────────────────────────────

typeset -g _TC_TMP

_tc_setup() {
  _TC_TMP=$(mktemp -d)
  export FLOW_CLAUDE_HOME="$_TC_TMP/claude"
  export FLOW_CLAUDE_ZSHRC="$_TC_TMP/zshrc"
  mkdir -p "$FLOW_CLAUDE_HOME/hooks"
  touch "$FLOW_CLAUDE_ZSHRC"
}

_tc_teardown() {
  [[ -n "${_TC_TMP:-}" ]] && rm -rf "$_TC_TMP"
  unset FLOW_CLAUDE_HOME FLOW_CLAUDE_ZSHRC _TC_TMP
}

# ── C1: Settings parity ───────────────────────────────────────────────────

test_case "C1: passes when settings.json has no env block"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
if command -v jq &>/dev/null; then
  assert_contains "$out" "Settings parity" "C1 check runs"
  [[ $rc -eq 0 ]] && test_pass "exit 0 on clean state" || test_fail "exit 0 on clean state" "rc=$rc out=$out"
else
  test_skip "jq not installed"
fi
_tc_teardown

test_case "C1: warns when key missing from zshrc"
_tc_setup
print '{"env":{"MY_TEST_VAR":"99"}}' > "$FLOW_CLAUDE_HOME/settings.json"
local hook="$FLOW_CLAUDE_HOME/hooks/post-compact-reinject.sh"
print '#!/bin/bash\necho ok' > "$hook" && chmod +x "$hook"
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
if command -v jq &>/dev/null; then
  assert_contains "$out" "MY_TEST_VAR" "C1 names missing key"
  [[ $rc -ge 1 ]] && test_pass "non-zero exit on mismatch" || test_fail "non-zero exit on mismatch" "rc=$rc"
else
  test_skip "jq not installed"
fi
_tc_teardown

test_case "C1: passes when key matches zshrc"
_tc_setup
print '{"env":{"MY_TEST_VAR":"99"}}' > "$FLOW_CLAUDE_HOME/settings.json"
print 'export MY_TEST_VAR=99' > "$FLOW_CLAUDE_ZSHRC"
local hook="$FLOW_CLAUDE_HOME/hooks/post-compact-reinject.sh"
print '#!/bin/bash\necho ok' > "$hook" && chmod +x "$hook"
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
if command -v jq &>/dev/null; then
  assert_contains "$out" "Settings parity" "C1 check runs"
  [[ $rc -eq 0 ]] && test_pass "exit 0 on match" || test_fail "exit 0 on match" "rc=$rc"
else
  test_skip "jq not installed"
fi
_tc_teardown

test_case "C1: --fix appends missing key to zshrc"
_tc_setup
print '{"env":{"FIX_VAR":"42"}}' > "$FLOW_CLAUDE_HOME/settings.json"
local hook="$FLOW_CLAUDE_HOME/hooks/post-compact-reinject.sh"
print '#!/bin/bash\necho ok' > "$hook" && chmod +x "$hook"
_flow_claude_check --fix 2>&1
if command -v jq &>/dev/null; then
  assert_contains "$(cat "$FLOW_CLAUDE_ZSHRC")" "FIX_VAR=42" "--fix appended key"
else
  test_skip "jq not installed"
fi
_tc_teardown

test_case "C1: --fix updates existing mismatched value"
_tc_setup
print '{"env":{"FIX_VAR":"new"}}' > "$FLOW_CLAUDE_HOME/settings.json"
print 'export FIX_VAR=old' > "$FLOW_CLAUDE_ZSHRC"
local hook="$FLOW_CLAUDE_HOME/hooks/post-compact-reinject.sh"
print '#!/bin/bash\necho ok' > "$hook" && chmod +x "$hook"
_flow_claude_check --fix 2>&1
if command -v jq &>/dev/null; then
  assert_contains "$(cat "$FLOW_CLAUDE_ZSHRC")" "FIX_VAR=new" "--fix updated value"
else
  test_skip "jq not installed"
fi
_tc_teardown

# ── C2: Hook health ────────────────────────────────────────────────────────

test_case "C2: errors when hook file missing"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
assert_contains "$out" "not found" "C2 reports missing hook"
[[ $rc -eq 1 ]] && test_pass "exit 1 on ERROR" || test_fail "exit 1 on ERROR" "rc=$rc"
_tc_teardown

test_case "C2: errors when hook not executable"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
local hook="$FLOW_CLAUDE_HOME/hooks/post-compact-reinject.sh"
print '#!/bin/bash\necho ok' > "$hook"
chmod 0644 "$hook"
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
assert_contains "$out" "not executable" "C2 reports not-executable"
[[ $rc -eq 1 ]] && test_pass "exit 1 on not-executable" || test_fail "exit 1" "rc=$rc"
_tc_teardown

test_case "C2: passes when hook exists and is executable"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
local hook="$FLOW_CLAUDE_HOME/hooks/post-compact-reinject.sh"
print '#!/bin/bash\necho ok' > "$hook" && chmod +x "$hook"
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
assert_contains "$out" "Hook health" "C2 output present"
[[ $rc -eq 0 ]] && test_pass "exit 0 on valid hook" || test_fail "exit 0" "rc=$rc"
_tc_teardown

# ── C3: Memory index drift ─────────────────────────────────────────────────

test_case "C3: passes when file count matches MEMORY.md entries"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
local hook="$FLOW_CLAUDE_HOME/hooks/post-compact-reinject.sh"
print '#!/bin/bash' > "$hook" && chmod +x "$hook"
local mem="$FLOW_CLAUDE_HOME/projects/testproj/memory"
mkdir -p "$mem"
print '- [a](a.md) — x\n- [b](b.md) — y' > "$mem/MEMORY.md"
print 'a' > "$mem/a.md"
print 'b' > "$mem/b.md"
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
assert_contains "$out" "Memory index" "C3 runs"
[[ $rc -eq 0 ]] && test_pass "exit 0 on sync" || test_fail "exit 0 on sync" "rc=$rc"
_tc_teardown

test_case "C3: warns when file count exceeds MEMORY.md entries"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
local hook="$FLOW_CLAUDE_HOME/hooks/post-compact-reinject.sh"
print '#!/bin/bash' > "$hook" && chmod +x "$hook"
local mem="$FLOW_CLAUDE_HOME/projects/testproj/memory"
mkdir -p "$mem"
print '- [a](a.md) — x' > "$mem/MEMORY.md"
print 'a' > "$mem/a.md"
print 'b' > "$mem/b.md"  # extra file not in index
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
assert_contains "$out" "drift" "C3 warns on drift"
[[ $rc -ge 1 ]] && test_pass "non-zero on drift" || test_fail "non-zero on drift" "rc=$rc"
_tc_teardown

# ── C4: CLAUDE.md length ──────────────────────────────────────────────────

test_case "C4: passes when CLAUDE.md <= 100 lines"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
local hook="$FLOW_CLAUDE_HOME/hooks/post-compact-reinject.sh"
print '#!/bin/bash' > "$hook" && chmod +x "$hook"
printf '%s\n' {1..50} > "$FLOW_CLAUDE_HOME/CLAUDE.md"
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
assert_contains "$out" "CLAUDE.md length" "C4 runs"
[[ $rc -eq 0 ]] && test_pass "exit 0 under limit" || test_fail "exit 0 under limit" "rc=$rc"
_tc_teardown

test_case "C4: warns when CLAUDE.md > 100 lines"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
local hook="$FLOW_CLAUDE_HOME/hooks/post-compact-reinject.sh"
print '#!/bin/bash' > "$hook" && chmod +x "$hook"
printf '%s\n' {1..101} > "$FLOW_CLAUDE_HOME/CLAUDE.md"
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
assert_contains "$out" "exceeds 100-line rule" "C4 warns on overflow"
[[ $rc -ge 1 ]] && test_pass "non-zero on overflow" || test_fail "non-zero on overflow" "rc=$rc"
_tc_teardown

# ── C5: Shell env parity ──────────────────────────────────────────────────

test_case "C5: reports when CLAUDE_AUTOCOMPACT_PCT_OVERRIDE is set"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
local hook="$FLOW_CLAUDE_HOME/hooks/post-compact-reinject.sh"
print '#!/bin/bash' > "$hook" && chmod +x "$hook"
export CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=65
local out
out=$(_flow_claude_check 2>&1)
assert_contains "$out" "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=65" "C5 shows value when set"
unset CLAUDE_AUTOCOMPACT_PCT_OVERRIDE
_tc_teardown

test_case "C5: reports when CLAUDE_AUTOCOMPACT_PCT_OVERRIDE is unset"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
local hook="$FLOW_CLAUDE_HOME/hooks/post-compact-reinject.sh"
print '#!/bin/bash' > "$hook" && chmod +x "$hook"
unset CLAUDE_AUTOCOMPACT_PCT_OVERRIDE
local out
out=$(_flow_claude_check 2>&1)
assert_contains "$out" "not set" "C5 shows not-set"
_tc_teardown

# ── Exit codes ─────────────────────────────────────────────────────────────

test_case "exit 1: ERROR wins over WARN"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
# No hook → ERROR; long CLAUDE.md → WARN
printf '%s\n' {1..150} > "$FLOW_CLAUDE_HOME/CLAUDE.md"
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
[[ $rc -eq 1 ]] && test_pass "exit 1 when ERROR present" || test_fail "exit 1 when ERROR present" "rc=$rc"
_tc_teardown

test_case "exit 2: WARN only"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
local hook="$FLOW_CLAUDE_HOME/hooks/post-compact-reinject.sh"
print '#!/bin/bash' > "$hook" && chmod +x "$hook"
printf '%s\n' {1..150} > "$FLOW_CLAUDE_HOME/CLAUDE.md"
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
[[ $rc -eq 2 ]] && test_pass "exit 2 on WARN only" || test_fail "exit 2 on WARN only" "rc=$rc"
_tc_teardown

# ── Graceful degradation ───────────────────────────────────────────────────

test_case "C1: degrades gracefully when jq not installed"
_tc_setup
print '{"env":{"FOO":"bar"}}' > "$FLOW_CLAUDE_HOME/settings.json"
local hook="$FLOW_CLAUDE_HOME/hooks/post-compact-reinject.sh"
print '#!/bin/bash' > "$hook" && chmod +x "$hook"
# Hide jq via PATH override in subshell
local orig_path="$PATH"
export PATH="/usr/bin:/bin"
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
export PATH="$orig_path"
assert_contains "$out" "Settings parity" "C1 output present without jq"
_tc_teardown

test_suite_end
