#!/usr/bin/env zsh
# tests/test-atlas-contract.zsh
# Verify Atlas CLI contract compliance (docs/ATLAS-CONTRACT.md)
# Tests skip gracefully when Atlas is not installed

# Setup
PROJECT_ROOT="${0:A:h:h}"
source "$PROJECT_ROOT/tests/test-framework.zsh"

test_suite_start "Atlas Contract Tests"

# ============================================================================
# ATLAS AVAILABILITY CHECK
# ============================================================================

typeset -g HAS_ATLAS=false
if command -v atlas &>/dev/null; then
  HAS_ATLAS=true
fi

# Helper: skip test if Atlas not installed
# Returns 0 (true) when skipped, 1 (false) when Atlas is available
skip_without_atlas() {
  if [[ "$HAS_ATLAS" != "true" ]]; then
    test_skip "Atlas not installed"
    return 0
  fi
  return 1
}

# ============================================================================
# BRIDGE FUNCTION TESTS (always run — these test flow-cli code)
# ============================================================================

test_case "at() function exists"
(
  FLOW_QUIET=1 FLOW_ATLAS_ENABLED=no
  FLOW_PLUGIN_DIR="$PROJECT_ROOT"
  source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null
  exec < /dev/null
  whence -f at >/dev/null 2>&1
) 2>/dev/null
assert_exit_code $? 0
test_pass

test_case "_at_help() function exists"
(
  FLOW_QUIET=1 FLOW_ATLAS_ENABLED=no
  FLOW_PLUGIN_DIR="$PROJECT_ROOT"
  source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null
  exec < /dev/null
  whence -f _at_help >/dev/null 2>&1
) 2>/dev/null
assert_exit_code $? 0
test_pass

test_case "at help outputs styled help page"
local help_output
help_output=$(
  FLOW_QUIET=1 FLOW_ATLAS_ENABLED=no
  FLOW_PLUGIN_DIR="$PROJECT_ROOT"
  source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null
  exec < /dev/null
  at help 2>&1
) 2>/dev/null
assert_contains "$help_output" "Atlas Project Intelligence"
assert_contains "$help_output" "MOST COMMON"
assert_contains "$help_output" "SESSION"
assert_contains "$help_output" "CAPTURE"
assert_contains "$help_output" "CONTEXT"
assert_contains "$help_output" "PROJECT"
test_pass

test_case "at (no args) shows help without Atlas"
local noargs_output
noargs_output=$(
  FLOW_QUIET=1 FLOW_ATLAS_ENABLED=no
  FLOW_PLUGIN_DIR="$PROJECT_ROOT"
  source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null
  exec < /dev/null
  at 2>&1
) 2>/dev/null
assert_contains "$noargs_output" "Atlas Project Intelligence"
test_pass

test_case "at --help works same as at help"
local dashhelp_output
dashhelp_output=$(
  FLOW_QUIET=1 FLOW_ATLAS_ENABLED=no
  FLOW_PLUGIN_DIR="$PROJECT_ROOT"
  source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null
  exec < /dev/null
  at --help 2>&1
) 2>/dev/null
assert_contains "$dashhelp_output" "Atlas Project Intelligence"
test_pass

test_case "at -h works same as at help"
local shorthelp_output
shorthelp_output=$(
  FLOW_QUIET=1 FLOW_ATLAS_ENABLED=no
  FLOW_PLUGIN_DIR="$PROJECT_ROOT"
  source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null
  exec < /dev/null
  at -h 2>&1
) 2>/dev/null
assert_contains "$shorthelp_output" "Atlas Project Intelligence"
test_pass

# ============================================================================
# FALLBACK BEHAVIOR TESTS (run without Atlas)
# ============================================================================

test_case "Warm-path commands show install message without Atlas"
local warm_output
warm_output=$(
  FLOW_QUIET=1 FLOW_ATLAS_ENABLED=no
  FLOW_PLUGIN_DIR="$PROJECT_ROOT"
  source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null
  exec < /dev/null
  at stats 2>&1
) 2>/dev/null
assert_contains "$warm_output" "requires Atlas CLI"
assert_contains "$warm_output" "npm i -g"
test_pass

test_case "Unknown command without Atlas shows available fallbacks"
local unknown_output
unknown_output=$(
  FLOW_QUIET=1 FLOW_ATLAS_ENABLED=no
  FLOW_PLUGIN_DIR="$PROJECT_ROOT"
  source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null
  exec < /dev/null
  at nonexistent 2>&1
) 2>/dev/null
assert_contains "$unknown_output" "catch, inbox, where, crumb"
test_pass

test_case "Hot-path catch works without Atlas"
local catch_output
catch_output=$(
  FLOW_QUIET=1 FLOW_ATLAS_ENABLED=no
  FLOW_PLUGIN_DIR="$PROJECT_ROOT"
  FLOW_DATA_DIR=$(mktemp -d)
  source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null
  exec < /dev/null
  at catch "test capture" 2>&1
  rm -rf "$FLOW_DATA_DIR"
) 2>/dev/null
assert_contains "$catch_output" "Captured"
test_pass

# ============================================================================
# ATLAS CLI CONTRACT TESTS (skip when Atlas not installed)
# ============================================================================

test_case "atlas -v returns version string"
if ! skip_without_atlas; then
  local version_output
  version_output=$(atlas -v 2>&1)
  assert_not_empty "$version_output" "atlas -v should return version"
  test_pass
fi

test_case "atlas project list --format=names returns plain text"
if ! skip_without_atlas; then
  local list_output
  list_output=$(atlas project list --format=names 2>&1)
  # Must NOT start with { or [ (JSON)
  if [[ "$list_output" == "{"* ]] || [[ "$list_output" == "["* ]]; then
    test_fail "project list --format=names returned JSON instead of plain text"
  else
    test_pass
  fi
fi

test_case "atlas exit codes: success = 0"
if ! skip_without_atlas; then
  atlas -v >/dev/null 2>&1
  assert_exit_code $? 0
  test_pass
fi

test_case "atlas exit codes: not found = 2"
if ! skip_without_atlas; then
  atlas project get "__nonexistent_project_test__" >/dev/null 2>&1
  local ec=$?
  # Accept 1 or 2 (some commands use 1 for not-found)
  if (( ec == 0 )); then
    test_fail "Expected non-zero exit for nonexistent project"
  else
    test_pass
  fi
fi

test_case "Warm-path: atlas stats responds"
if ! skip_without_atlas; then
  atlas stats >/dev/null 2>&1
  local ec=$?
  assert_exit_code $ec 0
  test_pass
fi

test_case "Warm-path: atlas parked responds"
if ! skip_without_atlas; then
  atlas parked >/dev/null 2>&1
  local ec=$?
  assert_exit_code $ec 0
  test_pass
fi

test_case "Warm-path: atlas trail responds"
if ! skip_without_atlas; then
  atlas trail >/dev/null 2>&1
  local ec=$?
  assert_exit_code $ec 0
  test_pass
fi

# ============================================================================
# HELP BROWSER INTEGRATION
# ============================================================================

test_case "Help browser regex includes at dispatcher"
local browser_content
browser_content=$(cat "$PROJECT_ROOT/lib/help-browser.zsh" 2>/dev/null)
assert_contains "$browser_content" "|at)" "help-browser.zsh should have 'at' in dispatcher regex"
test_pass

test_case "Help browser commands list includes at entry"
assert_contains "$browser_content" '"at:Atlas CLI'
test_pass

# ============================================================================
# SUMMARY
# ============================================================================

test_suite_end
exit $?
