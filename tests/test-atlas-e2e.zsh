#!/usr/bin/env zsh
# test-atlas-e2e.zsh - End-to-end tests with Atlas CLI
# These tests REQUIRE atlas to be installed and configured

setopt local_options no_unset

# ============================================================================
# Framework Bootstrap
# ============================================================================
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

# Setup
FLOW_PLUGIN_DIR="$PROJECT_ROOT"
FLOW_QUIET=1

# Source the plugin
source "$FLOW_PLUGIN_DIR/flow.plugin.zsh" 2>/dev/null

# ============================================================================
# Cleanup
# ============================================================================
cleanup() {
  reset_mocks
}
trap cleanup EXIT

# ============================================================================
# Pre-flight: Check if Atlas is available
# ============================================================================
preflight_check() {
  if ! _flow_has_atlas; then
    echo ""
    echo "  Atlas CLI not available"
    echo "  Install: npm install -g @data-wise/atlas"
    echo "  Or run: cd ~/projects/dev-tools/atlas && npm link"

    # Skip all tests
    test_case "Atlas CLI detected"
    test_skip "atlas not installed"

    test_case "Atlas version"
    test_skip "atlas not installed"

    test_case "_flow_list_projects via atlas"
    test_skip "atlas not installed"

    test_case "_flow_get_project (fallback mode)"
    test_skip "atlas not installed"

    test_case "Project info contains path"
    test_skip "atlas not installed"

    test_case "_flow_session_start available with atlas backend"
    test_skip "atlas not installed"

    test_case "_flow_session_end available with atlas backend"
    test_skip "atlas not installed"

    test_case "_flow_atlas wrapper available"
    test_skip "atlas not installed"

    test_case "_flow_atlas --help works"
    test_skip "atlas not installed"

    test_case "_flow_catch available with atlas backend"
    test_skip "atlas not installed"

    test_case "_flow_inbox available with atlas backend"
    test_skip "atlas not installed"

    test_case "_flow_crumb available with atlas backend"
    test_skip "atlas not installed"

    test_case "_flow_where available with atlas backend"
    test_skip "atlas not installed"

    test_case "at() shortcut available"
    test_skip "atlas not installed"

    test_case "_flow_atlas_async available"
    test_skip "atlas not installed"

    test_case "_flow_atlas_silent available"
    test_skip "atlas not installed"

    test_case "_flow_atlas_json available"
    test_skip "atlas not installed"

    test_case "atlas project list works"
    test_skip "atlas not installed"

    test_case "atlas where works"
    test_skip "atlas not installed"

    return 1
  fi
  return 0
}

# ============================================================================
# Test: Pre-flight checks
# ============================================================================
test_preflight() {
  test_case "Atlas CLI detected"
  assert_function_exists "_flow_has_atlas" && test_pass

  test_case "Atlas version"
  local atlas_version
  atlas_version=$(atlas --version 2>/dev/null)
  if [[ -n "$atlas_version" ]]; then
    test_pass
  else
    test_skip "Could not get atlas version"
  fi
}

# ============================================================================
# Test: Atlas project operations
# ============================================================================
test_project_operations() {
  test_case "_flow_list_projects via atlas"
  local project_count
  project_count=$(_flow_list_projects 2>/dev/null | wc -l | tr -d ' ')
  if (( project_count > 0 )); then
    test_pass
  else
    local fallback_count
    fallback_count=$(_flow_list_projects_fallback 2>/dev/null | wc -l | tr -d ' ')
    if (( fallback_count > 0 )); then
      test_pass
    else
      test_skip "run 'atlas sync' first"
    fi
  fi

  test_case "_flow_get_project (fallback mode)"
  local info
  info=$(_flow_get_project_fallback "flow-cli" 2>/dev/null)
  if [[ -n "$info" ]]; then
    test_pass

    test_case "Project info contains path"
    if [[ "$info" == *"path="* ]]; then
      test_pass
    else
      test_fail "missing path field"
    fi
  else
    test_fail "returned empty for flow-cli"

    test_case "Project info contains path"
    test_skip "no project info to check"
  fi
}

# ============================================================================
# Test: Atlas session operations
# ============================================================================
test_session_operations() {
  test_case "_flow_session_start available with atlas backend"
  assert_function_exists "_flow_session_start" && test_pass

  test_case "_flow_session_end available with atlas backend"
  assert_function_exists "_flow_session_end" && test_pass

  test_case "_flow_atlas wrapper available"
  assert_function_exists "_flow_atlas" && test_pass

  test_case "_flow_atlas --help works"
  if _flow_atlas --help &>/dev/null; then
    test_pass
  else
    test_fail "command failed"
  fi
}

# ============================================================================
# Test: Atlas capture operations
# ============================================================================
test_capture_operations() {
  test_case "_flow_catch available with atlas backend"
  assert_function_exists "_flow_catch" && test_pass

  test_case "_flow_inbox available with atlas backend"
  assert_function_exists "_flow_inbox" && test_pass

  test_case "_flow_crumb available with atlas backend"
  assert_function_exists "_flow_crumb" && test_pass
}

# ============================================================================
# Test: Atlas context operations
# ============================================================================
test_context_operations() {
  test_case "_flow_where available with atlas backend"
  assert_function_exists "_flow_where" && test_pass

  test_case "at() shortcut available"
  assert_function_exists "at" && test_pass
}

# ============================================================================
# Test: Atlas async operations
# ============================================================================
test_async_operations() {
  test_case "_flow_atlas_async available"
  assert_function_exists "_flow_atlas_async" && test_pass

  test_case "_flow_atlas_silent available"
  assert_function_exists "_flow_atlas_silent" && test_pass

  test_case "_flow_atlas_json available"
  assert_function_exists "_flow_atlas_json" && test_pass
}

# ============================================================================
# Test: Atlas CLI integration
# ============================================================================
test_cli_integration() {
  test_case "atlas project list works"
  local atlas_list
  atlas_list=$(_flow_atlas project list --format=names 2>/dev/null | head -5)
  if [[ -n "$atlas_list" ]]; then
    test_pass
  else
    test_skip "may need sync first"
  fi

  test_case "atlas where works"
  local atlas_where
  atlas_where=$(_flow_atlas where 2>&1)
  if [[ "$atlas_where" != *"Error"* ]] && [[ "$atlas_where" != *"error"* ]]; then
    test_pass
  else
    test_skip "no active session"
  fi
}

# ============================================================================
# Main
# ============================================================================
main() {
  test_suite_start "Atlas E2E Tests"

  if ! preflight_check; then
    cleanup
    test_suite_end
    exit $?
  fi

  test_preflight
  test_project_operations
  test_session_operations
  test_capture_operations
  test_context_operations
  test_async_operations
  test_cli_integration

  cleanup
  test_suite_end
  exit $?
}

main "$@"
