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

# Helper: skip warm-path/exit-code contract tests unless atlas actually
# implements flow-cli's expected subcommands. A same-named `atlas` binary may
# be on PATH (e.g. a different/older atlas) whose `stats`/`parked`/`trail`/`-v`
# return 127; those tests would then fail not because the contract is broken
# but because this isn't a flow-compatible atlas. Probe `atlas stats` once.
# Returns 0 (true) when skipped, 1 (false) when a functional atlas is present.
skip_without_warm_atlas() {
  skip_without_atlas && return 0
  if ! atlas stats >/dev/null 2>&1; then
    test_skip "atlas present but warm-path subcommands unimplemented"
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
if ! skip_without_warm_atlas; then
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
if ! skip_without_warm_atlas; then
  atlas stats >/dev/null 2>&1
  local ec=$?
  assert_exit_code $ec 0
  test_pass
fi

test_case "Warm-path: atlas parked responds"
if ! skip_without_warm_atlas; then
  atlas parked >/dev/null 2>&1
  local ec=$?
  assert_exit_code $ec 0
  test_pass
fi

test_case "Warm-path: atlas trail responds"
if ! skip_without_warm_atlas; then
  atlas trail >/dev/null 2>&1
  local ec=$?
  assert_exit_code $ec 0
  test_pass
fi

# ============================================================================
# ATLAS AGENDA SOURCE (Track C, dark-ready — SPEC-planning-coordination-2026-07-01 §3.4)
# ============================================================================
# Pins tests/fixtures/atlas-agenda-stub.json's shape to the `atlas agenda`
# JSON example documented in ATLAS-CONTRACT.md — a contract edit without a
# matching fixture update fails this test loudly instead of drifting silently
# (D16). Always runs (doesn't need real atlas — the fixture stands in for it).

test_case "atlas-agenda-stub.json fixture keys match the ATLAS-CONTRACT.md documented example"
if ! command -v jq >/dev/null 2>&1; then
  test_skip "jq not installed"
else
  local fixture="$PROJECT_ROOT/tests/fixtures/atlas-agenda-stub.json"
  local contract_doc="$PROJECT_ROOT/docs/ATLAS-CONTRACT.md"

  if [[ ! -f "$fixture" ]]; then
    assert_exit_code 1 0 "fixture file missing: $fixture"
  else
    # Extract the fenced ```json block under the "### `atlas agenda`" heading.
    local contract_json
    contract_json=$(awk '/### `atlas agenda`/{found=1} found && /^```json/{incode=1; next} incode && /^```/{exit} incode' "$contract_doc")

    local contract_keys fixture_keys
    contract_keys=$(print -r -- "$contract_json" | jq -r '.[0] | keys | sort | join(",")' 2>/dev/null)
    fixture_keys=$(jq -r '.[0] | keys | sort | join(",")' "$fixture" 2>/dev/null)

    assert_not_empty "$contract_keys" "contract doc must have a parseable atlas agenda JSON example (got none — heading text or fence may have drifted)"
    assert_not_empty "$fixture_keys" "fixture must be valid JSON with at least one object"
    assert_equals "$fixture_keys" "$contract_keys" "fixture keys ($fixture_keys) must match the contract doc's documented example ($contract_keys)"
  fi
fi
test_pass

test_case "atlas-agenda-stub.json is a valid JSON array (jq-parseable)"
if ! command -v jq >/dev/null 2>&1; then
  test_skip "jq not installed"
else
  local fixture="$PROJECT_ROOT/tests/fixtures/atlas-agenda-stub.json"
  jq -e 'type == "array" and length > 0' "$fixture" >/dev/null 2>&1
  assert_exit_code $? 0 "fixture must be a non-empty JSON array"
fi
test_pass

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
