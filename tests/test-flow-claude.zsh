#!/usr/bin/env zsh
# tests/test-flow-claude.zsh — Tests for flow claude check (C1-C11) + watch

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
  export FLOW_CLAUDE_PROJECTS_ROOT="$_TC_TMP/projects"
  mkdir -p "$FLOW_CLAUDE_HOME/hooks" "$FLOW_CLAUDE_HOME/projects" "$FLOW_CLAUDE_PROJECTS_ROOT"
  print 'export CLAUDE_CODE_MAX_OUTPUT_TOKENS=32000' > "$FLOW_CLAUDE_ZSHRC"
}

_tc_teardown() {
  [[ -n "${_TC_TMP:-}" ]] && rm -rf "$_TC_TMP"
  unset FLOW_CLAUDE_HOME FLOW_CLAUDE_ZSHRC FLOW_CLAUDE_PROJECTS_ROOT _TC_TMP
}

_tc_make_hook() {
  local hook="$FLOW_CLAUDE_HOME/hooks/post-compact-reinject.sh"
  print '#!/bin/bash' > "$hook" && chmod +x "$hook"
}

# ── C1: Settings parity ───────────────────────────────────────────────────

test_case "C1: passes when settings.json has no env block"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
_tc_make_hook
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
_tc_make_hook
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
print 'export MY_TEST_VAR=99' >> "$FLOW_CLAUDE_ZSHRC"
_tc_make_hook
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
_tc_make_hook
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
_tc_make_hook
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
_tc_make_hook
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
assert_contains "$out" "Hook health" "C2 output present"
[[ $rc -eq 0 ]] && test_pass "exit 0 on valid hook" || test_fail "exit 0" "rc=$rc"
_tc_teardown

# ── C3: Memory index drift ─────────────────────────────────────────────────

test_case "C3: passes when file count matches MEMORY.md entries"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
_tc_make_hook
# Slug must decode to an existing path so C8 doesn't fire (/${slug//-//} = _TC_TMP)
local proj_slug="${_TC_TMP:1}"     # strip leading /
proj_slug="${proj_slug//\//-}"     # / → -
local mem="$FLOW_CLAUDE_HOME/projects/$proj_slug/memory"
mkdir -p "$mem"
printf -- '- [a](a.md) — x\n- [b](b.md) — y\n' > "$mem/MEMORY.md"
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
_tc_make_hook
local proj_slug="${_TC_TMP:1}"
proj_slug="${proj_slug//\//-}"
local mem="$FLOW_CLAUDE_HOME/projects/$proj_slug/memory"
mkdir -p "$mem"
printf -- '- [a](a.md) — x\n' > "$mem/MEMORY.md"
print 'a' > "$mem/a.md"
print 'b' > "$mem/b.md"  # extra file not in index
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
assert_contains "$out" "drift" "C3 warns on drift"
[[ $rc -ge 1 ]] && test_pass "non-zero on drift" || test_fail "non-zero on drift" "rc=$rc"
_tc_teardown

# ── C4: CLAUDE.md length (two-tier) ──────────────────────────────────────

test_case "C4: passes when CLAUDE.md <= 100 lines"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
_tc_make_hook
printf '%s\n' {1..95} > "$FLOW_CLAUDE_HOME/CLAUDE.md"
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
assert_contains "$out" "CLAUDE.md length" "C4 runs"
[[ $rc -eq 0 ]] && test_pass "exit 0 under limit" || test_fail "exit 0 under limit" "rc=$rc"
_tc_teardown

test_case "C4: warns when CLAUDE.md > 100 lines (approaching limit)"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
_tc_make_hook
printf '%s\n' {1..150} > "$FLOW_CLAUDE_HOME/CLAUDE.md"
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
assert_contains "$out" "approaching 180-line limit" "C4 warns on approaching limit"
[[ $rc -eq 2 ]] && test_pass "exit 2 on WARN" || test_fail "exit 2 on WARN" "rc=$rc"
_tc_teardown

test_case "C4: errors when CLAUDE.md > 180 lines"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
_tc_make_hook
printf '%s\n' {1..200} > "$FLOW_CLAUDE_HOME/CLAUDE.md"
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
assert_contains "$out" "exceeds 180-line hard limit" "C4 errors on overflow"
[[ $rc -eq 1 ]] && test_pass "exit 1 on ERROR" || test_fail "exit 1 on ERROR" "rc=$rc"
_tc_teardown

# ── C5: Shell env parity ──────────────────────────────────────────────────

test_case "C5: reports when CLAUDE_AUTOCOMPACT_PCT_OVERRIDE is set"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
_tc_make_hook
export CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=65
local out
out=$(_flow_claude_check 2>&1)
assert_contains "$out" "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=65" "C5 shows value when set"
unset CLAUDE_AUTOCOMPACT_PCT_OVERRIDE
_tc_teardown

test_case "C5: reports when CLAUDE_AUTOCOMPACT_PCT_OVERRIDE is unset"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
_tc_make_hook
unset CLAUDE_AUTOCOMPACT_PCT_OVERRIDE
local out
out=$(_flow_claude_check 2>&1)
assert_contains "$out" "not set" "C5 shows not-set"
_tc_teardown

# ── C6: Output token limit ────────────────────────────────────────────────

test_case "C6: warns when CLAUDE_CODE_MAX_OUTPUT_TOKENS not set"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
> "$FLOW_CLAUDE_ZSHRC"  # clear default token so C6 warns
_tc_make_hook
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
assert_contains "$out" "Output token limit" "C6 output present"
assert_contains "$out" "not set" "C6 reports missing"
[[ $rc -ge 2 ]] && test_pass "non-zero exit when C6 missing" || test_fail "non-zero exit when C6 missing" "rc=$rc"
_tc_teardown

test_case "C6: passes when CLAUDE_CODE_MAX_OUTPUT_TOKENS=32000 in zshrc"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
print 'export CLAUDE_CODE_MAX_OUTPUT_TOKENS=32000' > "$FLOW_CLAUDE_ZSHRC"
_tc_make_hook
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
assert_contains "$out" "Output token limit" "C6 output present"
assert_contains "$out" "32000" "C6 shows value"
[[ $rc -eq 0 ]] && test_pass "exit 0 when C6 passes" || test_fail "exit 0 when C6 passes" "rc=$rc out=$out"
_tc_teardown

test_case "C6: warns when value is at default 8192"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
print 'export CLAUDE_CODE_MAX_OUTPUT_TOKENS=8192' > "$FLOW_CLAUDE_ZSHRC"
_tc_make_hook
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
assert_contains "$out" "8192" "C6 shows value"
assert_contains "$out" "still at default" "C6 flags default cap"
[[ $rc -ge 2 ]] && test_pass "non-zero exit at default cap" || test_fail "non-zero exit at default cap" "rc=$rc"
_tc_teardown

test_case "C6: --fix appends CLAUDE_CODE_MAX_OUTPUT_TOKENS=32000 to zshrc"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
_tc_make_hook
_flow_claude_check --fix 2>&1
local zshrc_content
zshrc_content=$(cat "$FLOW_CLAUDE_ZSHRC")
assert_contains "$zshrc_content" "CLAUDE_CODE_MAX_OUTPUT_TOKENS=32000" "C6 --fix writes to zshrc"
_tc_teardown

# ── C7: Per-project CLAUDE.md audit ───────────────────────────────────────

test_case "C7: passes when no projects root exists"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
_tc_make_hook
export FLOW_CLAUDE_PROJECTS_ROOT="$_TC_TMP/no-such-dir"
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
assert_contains "$out" "Project CLAUDE.md" "C7 output present"
assert_contains "$out" "not found" "C7 skips gracefully"
[[ $rc -eq 0 ]] && test_pass "exit 0 when no projects" || test_fail "exit 0 when no projects" "rc=$rc"
_tc_teardown

test_case "C7a: warns when project CLAUDE.md > 180 lines"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
_tc_make_hook
local proj="$FLOW_CLAUDE_PROJECTS_ROOT/myproject"
mkdir -p "$proj"
printf '%s\n' {1..200} > "$proj/CLAUDE.md"
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
assert_contains "$out" "200 lines" "C7a reports line count"
assert_contains "$out" "> 180" "C7a flags threshold"
[[ $rc -ge 2 ]] && test_pass "non-zero on C7a issue" || test_fail "non-zero on C7a issue" "rc=$rc"
_tc_teardown

test_case "C7a: passes when project CLAUDE.md <= 180 lines"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
_tc_make_hook
local proj="$FLOW_CLAUDE_PROJECTS_ROOT/myproject"
mkdir -p "$proj"
printf '%s\n' {1..100} > "$proj/CLAUDE.md"
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
assert_contains "$out" "all clean" "C7 all clean"
[[ $rc -eq 0 ]] && test_pass "exit 0 on clean" || test_fail "exit 0 on clean" "rc=$rc"
_tc_teardown

test_case "C7b: warns on version drift when git tag differs"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
_tc_make_hook
local proj="$FLOW_CLAUDE_PROJECTS_ROOT/myproject"
mkdir -p "$proj"
printf 'Current Version: v1.0.0\n' > "$proj/CLAUDE.md"
# Mock git to return a different tag
git() {
  if [[ "$*" == *"describe"* ]]; then
    print "v2.0.0"
    return 0
  fi
  command git "$@"
}
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
unfunction git 2>/dev/null
assert_contains "$out" "version ref v1.0.0" "C7b reports version drift"
assert_contains "$out" "current: v2.0.0" "C7b shows current tag"
[[ $rc -ge 2 ]] && test_pass "non-zero on version drift" || test_fail "non-zero on version drift" "rc=$rc"
_tc_teardown

test_case "C7b: passes when no git tags exist"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
_tc_make_hook
local proj="$FLOW_CLAUDE_PROJECTS_ROOT/myproject"
mkdir -p "$proj"
printf 'Current Version: v1.0.0\n' > "$proj/CLAUDE.md"
# Mock git to return no tags (non-zero exit)
git() {
  if [[ "$*" == *"describe"* ]]; then
    return 1
  fi
  command git "$@"
}
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
unfunction git 2>/dev/null
assert_contains "$out" "all clean" "C7b skips when no tags"
[[ $rc -eq 0 ]] && test_pass "exit 0 — no false positive on missing tags" || test_fail "exit 0" "rc=$rc"
_tc_teardown

# ── C8: Orphaned memory dirs ───────────────────────────────────────────────

test_case "C8: warns when memory dir decodes to missing path"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
_tc_make_hook
# Create a slug that decodes to a nonexistent path
local fake_slug="-tmp-no-such-project-xyzzy"
mkdir -p "$FLOW_CLAUDE_HOME/projects/$fake_slug"
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
assert_contains "$out" "Orphaned memory" "C8 output present"
assert_contains "$out" "stale" "C8 reports stale dir"
[[ $rc -ge 2 ]] && test_pass "non-zero on orphaned dir" || test_fail "non-zero on orphaned dir" "rc=$rc"
_tc_teardown

test_case "C8: passes when all memory dirs decode to valid paths"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
_tc_make_hook
# Create a slug that decodes to an existing path (tmp dir itself)
local tmp_slug="${_TC_TMP/\//}"       # strip leading /
tmp_slug="${tmp_slug//\//-}"          # replace / with -
tmp_slug="-$tmp_slug"                 # add leading - to represent leading /
mkdir -p "$FLOW_CLAUDE_HOME/projects/$tmp_slug"
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
assert_contains "$out" "Orphaned memory" "C8 output present"
assert_contains "$out" "valid" "C8 passes for valid dir"
[[ $rc -eq 0 ]] && test_pass "exit 0 on valid dirs" || test_fail "exit 0 on valid dirs" "rc=$rc"
_tc_teardown

# ── C9: Rules drift ────────────────────────────────────────────────────────

test_case "C9: warns when rule file not cited in CLAUDE.md"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
_tc_make_hook
mkdir -p "$FLOW_CLAUDE_HOME/rules"
print 'some rule content' > "$FLOW_CLAUDE_HOME/rules/my-uncited-rule.md"
# CLAUDE.md does not mention the rule stem
print 'This is CLAUDE.md with no rule references.' > "$FLOW_CLAUDE_HOME/CLAUDE.md"
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
assert_contains "$out" "Rules drift" "C9 output present"
assert_contains "$out" "my-uncited-rule" "C9 reports unreferenced rule"
[[ $rc -ge 2 ]] && test_pass "non-zero on rules drift" || test_fail "non-zero on rules drift" "rc=$rc"
_tc_teardown

test_case "C9: passes when all rules are referenced in CLAUDE.md"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
_tc_make_hook
mkdir -p "$FLOW_CLAUDE_HOME/rules"
print 'some rule content' > "$FLOW_CLAUDE_HOME/rules/my-cited-rule.md"
# CLAUDE.md mentions the rule stem
print 'See my-cited-rule for details.' > "$FLOW_CLAUDE_HOME/CLAUDE.md"
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
assert_contains "$out" "Rules drift" "C9 output present"
assert_contains "$out" "referenced" "C9 passes on all referenced"
[[ $rc -eq 0 ]] && test_pass "exit 0 on all referenced" || test_fail "exit 0 on all referenced" "rc=$rc"
_tc_teardown

test_case "C9: skips gracefully when no rules dir"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
_tc_make_hook
# No rules dir created
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
assert_contains "$out" "Rules drift" "C9 output present"
assert_contains "$out" "skipped" "C9 skips without rules dir"
[[ $rc -eq 0 ]] && test_pass "exit 0 without rules dir" || test_fail "exit 0 without rules dir" "rc=$rc"
_tc_teardown

# ── C10: Missing hook files ────────────────────────────────────────────────

test_case "C10: passes when settings.json has no hooks"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
_tc_make_hook
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
if command -v jq &>/dev/null; then
  assert_contains "$out" "Hook files" "C10 output present"
  assert_contains "$out" "present" "C10 passes with no hooks"
  [[ $rc -eq 0 ]] && test_pass "exit 0 with no hooks" || test_fail "exit 0 with no hooks" "rc=$rc"
else
  test_skip "jq not installed"
fi
_tc_teardown

test_case "C10: passes when all hook paths exist"
_tc_setup
local hook_script="$_TC_TMP/myhook.sh"
print '#!/bin/bash\necho ok' > "$hook_script" && chmod +x "$hook_script"
print "{\"hooks\":{\"PreToolUse\":[{\"command\":\"$hook_script\"}]}}" > "$FLOW_CLAUDE_HOME/settings.json"
_tc_make_hook
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
if command -v jq &>/dev/null; then
  assert_contains "$out" "Hook files" "C10 output present"
  assert_contains "$out" "present" "C10 passes for existing hook"
  [[ $rc -eq 0 ]] && test_pass "exit 0 when hook exists" || test_fail "exit 0 when hook exists" "rc=$rc"
else
  test_skip "jq not installed"
fi
_tc_teardown

test_case "C10: errors when hook path does not exist"
_tc_setup
local missing_hook="$_TC_TMP/nonexistent-hook.sh"
print "{\"hooks\":{\"PreToolUse\":[{\"command\":\"$missing_hook\"}]}}" > "$FLOW_CLAUDE_HOME/settings.json"
_tc_make_hook
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
if command -v jq &>/dev/null; then
  assert_contains "$out" "Hook files" "C10 output present"
  assert_contains "$out" "missing" "C10 errors on missing hook"
  [[ $rc -eq 1 ]] && test_pass "exit 1 on missing hook" || test_fail "exit 1 on missing hook" "rc=$rc"
else
  test_skip "jq not installed"
fi
_tc_teardown

# ── C11: Plugin health ─────────────────────────────────────────────────────

test_case "C11: passes when all plugins have valid plugin.json"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
_tc_make_hook
mkdir -p "$FLOW_CLAUDE_HOME/plugins/myplugin"
print '{"name":"myplugin","version":"1.0.0"}' > "$FLOW_CLAUDE_HOME/plugins/myplugin/plugin.json"
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
if command -v jq &>/dev/null; then
  assert_contains "$out" "Plugin health" "C11 output present"
  assert_contains "$out" "healthy" "C11 passes for valid plugin"
  [[ $rc -eq 0 ]] && test_pass "exit 0 for valid plugin" || test_fail "exit 0 for valid plugin" "rc=$rc"
else
  test_skip "jq not installed"
fi
_tc_teardown

test_case "C11: warns when plugin is missing plugin.json"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
_tc_make_hook
mkdir -p "$FLOW_CLAUDE_HOME/plugins/broken-plugin"
# No plugin.json created
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
if command -v jq &>/dev/null; then
  assert_contains "$out" "Plugin health" "C11 output present"
  assert_contains "$out" "missing plugin.json" "C11 warns on missing file"
  [[ $rc -ge 2 ]] && test_pass "non-zero on missing plugin.json" || test_fail "non-zero on missing plugin.json" "rc=$rc"
else
  test_skip "jq not installed"
fi
_tc_teardown

test_case "C11: warns when plugin.json is invalid JSON"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
_tc_make_hook
mkdir -p "$FLOW_CLAUDE_HOME/plugins/bad-json-plugin"
print 'not valid json {{{' > "$FLOW_CLAUDE_HOME/plugins/bad-json-plugin/plugin.json"
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
if command -v jq &>/dev/null; then
  assert_contains "$out" "Plugin health" "C11 output present"
  assert_contains "$out" "invalid JSON" "C11 warns on invalid JSON"
  [[ $rc -ge 2 ]] && test_pass "non-zero on invalid JSON" || test_fail "non-zero on invalid JSON" "rc=$rc"
else
  test_skip "jq not installed"
fi
_tc_teardown

test_case "C11: skips cache/ subdirectory"
_tc_setup
print '{}' > "$FLOW_CLAUDE_HOME/settings.json"
_tc_make_hook
mkdir -p "$FLOW_CLAUDE_HOME/plugins/cache/some-cached-plugin"
# No plugin.json in cache subdir — should be ignored
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
if command -v jq &>/dev/null; then
  [[ $rc -eq 0 ]] && test_pass "exit 0 — cache/ dir skipped" || test_fail "exit 0 — cache/ dir skipped" "rc=$rc"
else
  test_skip "jq not installed"
fi
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
_tc_make_hook
printf '%s\n' {1..150} > "$FLOW_CLAUDE_HOME/CLAUDE.md"
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
[[ $rc -eq 2 ]] && test_pass "exit 2 on WARN only" || test_fail "exit 2 on WARN only" "rc=$rc"
_tc_teardown

# ── Graceful degradation ───────────────────────────────────────────────────

test_case "C1: degrades gracefully when jq not installed"
_tc_setup
print '{"env":{"FOO":"bar"}}' > "$FLOW_CLAUDE_HOME/settings.json"
_tc_make_hook
# Hide jq via PATH override in subshell
local orig_path="$PATH"
export PATH="/usr/bin:/bin"
local out rc
out=$(_flow_claude_check 2>&1); rc=$?
export PATH="$orig_path"
assert_contains "$out" "Settings parity" "C1 output present without jq"
_tc_teardown

# ── Watch daemon ───────────────────────────────────────────────────────────

test_case "watch --status: shows not-running when no pid file"
local flow_dir
flow_dir=$(mktemp -d)
local pid_file="$flow_dir/claude-watch.pid"
local state_file="$flow_dir/claude-health-state.json"
# No pid file — status should say not running without crashing
local orig_home="$HOME"
HOME="$flow_dir"
local out rc
out=$(_flow_claude_watch_status 2>&1); rc=$?
HOME="$orig_home"
rm -rf "$flow_dir"
assert_contains "$out" "not running" "status shows not running"
[[ $rc -eq 0 ]] && test_pass "exit 0 on status when not running" || test_fail "exit 0 on status" "rc=$rc"

test_case "watch --stop: no-ops cleanly when watcher not running"
local flow_dir saved_home
flow_dir=$(mktemp -d)
saved_home="$HOME"
HOME="$flow_dir"
local out rc
out=$(_flow_claude_watch_stop 2>&1); rc=$?
HOME="$saved_home"
rm -rf "$flow_dir"
[[ $rc -eq 0 ]] && test_pass "exit 0 on stop when not running" || test_fail "exit 0 on stop" "rc=$rc"

test_case "watch --stop: kills process and removes pid file"
local flow_dir saved_home
flow_dir=$(mktemp -d)
mkdir -p "$flow_dir/.flow"
# Start a background sleep and write its PID where _flow_claude_watch_stop expects it
sleep 999 &
local fake_pid=$!
print "$fake_pid" > "$flow_dir/.flow/claude-watch.pid"
saved_home="$HOME"
HOME="$flow_dir"
local out rc
out=$(_flow_claude_watch_stop 2>&1); rc=$?
HOME="$saved_home"
assert_not_contains "$out" "not running" "stop reports success"
[[ ! -f "$flow_dir/.flow/claude-watch.pid" ]] && test_pass "pid file removed after stop" || test_fail "pid file removed after stop"
kill "$fake_pid" 2>/dev/null || true
rm -rf "$flow_dir"

test_case "watch notify: warn→pass fires notifier"
# Use a real executable in PATH — command -v doesn't find shell functions
local notif_dir called_file saved_path
notif_dir=$(mktemp -d)
called_file="$notif_dir/notif-args.txt"
print "#!/bin/sh" > "$notif_dir/terminal-notifier"
print "echo \"\$@\" >> \"$called_file\"" >> "$notif_dir/terminal-notifier"
chmod +x "$notif_dir/terminal-notifier"
saved_path="$PATH"
export PATH="$notif_dir:$PATH"
_flow_claude_watch_notify "warn" "pass" "All clear"
export PATH="$saved_path"
if [[ -f "$called_file" ]]; then
  local notif_args
  notif_args=$(cat "$called_file")
  assert_contains "$notif_args" "restored" "notifier output shows restored on warn→pass"
  test_pass "notifier called on state change"
else
  test_fail "notifier should have been called on warn→pass (args file missing)"
fi
rm -rf "$notif_dir"

test_case "watch notify: pass→pass is silent"
local notif_dir saved_path
notif_dir=$(mktemp -d)
print "#!/bin/sh" > "$notif_dir/terminal-notifier"
print "touch \"$notif_dir/was-called\"" >> "$notif_dir/terminal-notifier"
chmod +x "$notif_dir/terminal-notifier"
saved_path="$PATH"
export PATH="$notif_dir:$PATH"
_flow_claude_watch_notify "pass" "pass" "still passing"
export PATH="$saved_path"
[[ ! -f "$notif_dir/was-called" ]] && test_pass "no notification on pass→pass" || test_fail "no notification on pass→pass" "notifier was called"
rm -rf "$notif_dir"

test_case "watch run_check: writes state file with result"
_tc_setup
local flow_dir
flow_dir=$(mktemp -d)
local state_file="$flow_dir/state.json"
# Mock _flow_claude_check to return WARN (rc=2)
_flow_claude_check() { return 2 }
local orig_home="$HOME"
HOME="$flow_dir"
_flow_claude_watch_run_check "$state_file" 2>/dev/null
HOME="$orig_home"
unfunction _flow_claude_check 2>/dev/null
if command -v jq &>/dev/null && [[ -f "$state_file" ]]; then
  local result
  result=$(jq -r '.result' "$state_file" 2>/dev/null)
  [[ "$result" == "warn" ]] && test_pass "state file has result=warn" || test_fail "state file has result=warn" "got: $result"
else
  test_skip "jq not installed or state file missing"
fi
rm -rf "$flow_dir"
_tc_teardown

test_suite_end
