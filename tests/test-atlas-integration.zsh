#!/usr/bin/env zsh
# test-atlas-integration.zsh - Tests for atlas-bridge.zsh
# Tests both fallback mode (no atlas) and atlas mode (when available)

setopt local_options no_unset

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh"

# Setup
FLOW_PLUGIN_DIR="$PROJECT_ROOT"
FLOW_QUIET=1

# Source the plugin
source "$FLOW_PLUGIN_DIR/flow.plugin.zsh" 2>/dev/null

test_suite_start "Atlas Integration Tests"

# ============================================================================
# Test: Plugin loads correctly
# ============================================================================
echo "== Plugin Loading =="

test_case "Plugin loaded (FLOW_PLUGIN_LOADED=1)"
if [[ "$FLOW_PLUGIN_LOADED" == "1" ]]; then
  test_pass
else
  test_fail "FLOW_PLUGIN_LOADED=$FLOW_PLUGIN_LOADED"
fi

# ============================================================================
# Test: Atlas detection
# ============================================================================
echo ""
echo "== Atlas Detection =="

test_case "Atlas detection"
if _flow_has_atlas; then
  test_pass
  ATLAS_MODE="connected"
else
  test_pass
  ATLAS_MODE="fallback"
fi

echo "  Mode: $ATLAS_MODE"

# ============================================================================
# Test: Core functions exist
# ============================================================================
echo ""
echo "== Core Functions =="

for fn in _flow_get_project _flow_list_projects _flow_session_start \
          _flow_session_end _flow_catch _flow_crumb _flow_timestamp; do
  test_case "$fn exists and is callable"
  if type $fn &>/dev/null; then
    local output=$($fn --help 2>&1 || $fn 2>&1 || true)
    assert_not_contains "$output" "command not found" && test_pass
  else
    test_fail "function not defined"
  fi
done

# ============================================================================
# Test: Timestamp function (zsh/datetime)
# ============================================================================
echo ""
echo "== Timestamp (zsh/datetime) =="

test_case "_flow_timestamp returns valid format"
ts=$(_flow_timestamp 2>/dev/null)
if [[ "$ts" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
  test_pass
else
  test_fail "got: $ts"
fi

test_case "_flow_timestamp_short returns valid format"
ts_short=$(_flow_timestamp_short 2>/dev/null)
if [[ "$ts_short" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}$ ]]; then
  test_pass
else
  test_fail "got: $ts_short"
fi

# ============================================================================
# Test: Project discovery (fallback)
# ============================================================================
echo ""
echo "== Project Discovery (Fallback) =="

test_case "_flow_get_project finds flow-cli"
info=$(_flow_get_project "flow-cli" 2>/dev/null)
if [[ -n "$info" ]]; then
  test_pass

  # Parse and verify
  eval "$info"
  test_case "  name=flow-cli"
  if [[ "$name" == "flow-cli" ]]; then
    test_pass
  else
    test_fail "expected flow-cli, got $name"
  fi

  test_case "  path exists ($path)"
  if [[ -d "$path" ]]; then
    test_pass
  else
    test_fail "$path"
  fi
else
  test_fail "returned empty for flow-cli"
fi

# ============================================================================
# Test: Project listing
# ============================================================================
echo ""
echo "== Project Listing =="

test_case "_flow_list_projects returns projects"
projects=("${(@f)$(_flow_list_projects 2>/dev/null)}")
count=${#projects[@]}

if (( count > 0 )); then
  test_pass
else
  test_fail "returned no projects"
fi

# ============================================================================
# Test: Session operations (function availability)
# ============================================================================
echo ""
echo "== Session Operations =="

test_case "_flow_session_start function available"
if type _flow_session_start &>/dev/null; then
  local output=$(_flow_session_start 2>&1 || true)
  assert_not_contains "$output" "command not found" && test_pass
else
  test_fail "function not defined"
fi

test_case "_flow_session_end function available"
if type _flow_session_end &>/dev/null; then
  local output=$(_flow_session_end 2>&1 || true)
  assert_not_contains "$output" "command not found" && test_pass
else
  test_fail "function not defined"
fi

# ============================================================================
# Test: Capture operations (function availability)
# ============================================================================
echo ""
echo "== Capture Operations =="

test_case "_flow_catch function available"
if type _flow_catch &>/dev/null; then
  local output=$(_flow_catch "test" 2>&1 || true)
  assert_not_contains "$output" "command not found" && test_pass
else
  test_fail "function not defined"
fi

test_case "_flow_crumb function available"
if type _flow_crumb &>/dev/null; then
  local output=$(_flow_crumb "test" 2>&1 || true)
  assert_not_contains "$output" "command not found" && test_pass
else
  test_fail "function not defined"
fi

# ============================================================================
# Test: User-facing commands
# ============================================================================
echo ""
echo "== User Commands =="

for cmd in work dash catch js hop finish why; do
  test_case "$cmd command available and callable"
  if type $cmd &>/dev/null; then
    local output=$($cmd --help 2>&1 || $cmd 2>&1 || true)
    assert_not_contains "$output" "command not found" && test_pass
  else
    test_fail "not defined"
  fi
done

# ============================================================================
# Summary
# ============================================================================

test_suite_end
exit $?
