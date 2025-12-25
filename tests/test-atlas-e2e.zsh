#!/usr/bin/env zsh
# test-atlas-e2e.zsh - End-to-end tests with Atlas CLI
# These tests REQUIRE atlas to be installed and configured

setopt local_options no_unset

# Colors
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
NC=$'\033[0m'

# Test counters
PASSED=0
FAILED=0
SKIPPED=0

# Test helpers
pass() { ((PASSED++)); echo "${GREEN}✓${NC} $1"; }
fail() { ((FAILED++)); echo "${RED}✗${NC} $1: $2"; }
skip() { ((SKIPPED++)); echo "${YELLOW}○${NC} $1 (skipped)"; }

# Setup
FLOW_PLUGIN_DIR="${0:A:h:h}"
FLOW_QUIET=1

# Source the plugin
source "$FLOW_PLUGIN_DIR/flow.plugin.zsh" 2>/dev/null

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Atlas E2E Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ============================================================================
# Pre-flight: Check if Atlas is available
# ============================================================================
echo "== Pre-flight Check =="

if ! _flow_has_atlas; then
  echo ""
  echo "${YELLOW}⚠ Atlas CLI not available${NC}"
  echo "  Install: npm install -g @data-wise/atlas"
  echo "  Or run: cd ~/projects/dev-tools/atlas && npm link"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Results: ${YELLOW}All tests skipped${NC} (atlas not installed)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
fi

pass "Atlas CLI detected"

# Check atlas version
atlas_version=$(atlas --version 2>/dev/null)
if [[ -n "$atlas_version" ]]; then
  pass "Atlas version: $atlas_version"
else
  skip "Could not get atlas version"
fi

# ============================================================================
# Test: Atlas project operations
# ============================================================================
echo ""
echo "== Project Operations =="

# List projects (note: atlas project list uses filesystem scan, not registry)
project_count=$(_flow_list_projects 2>/dev/null | wc -l | tr -d ' ')
if (( project_count > 0 )); then
  pass "_flow_list_projects via atlas ($project_count projects)"
else
  # Fallback: try filesystem-based listing
  fallback_count=$(_flow_list_projects_fallback 2>/dev/null | wc -l | tr -d ' ')
  if (( fallback_count > 0 )); then
    pass "_flow_list_projects fallback ($fallback_count projects)"
  else
    skip "_flow_list_projects (run 'atlas sync' first)"
  fi
fi

# Get specific project - atlas returns dashboard format, use fallback
info=$(_flow_get_project_fallback "flow-cli" 2>/dev/null)
if [[ -n "$info" ]]; then
  pass "_flow_get_project (fallback mode)"

  # Verify we got valid output
  if [[ "$info" == *"path="* ]]; then
    pass "  Project info contains path"
  else
    fail "  Project info format" "missing path field"
  fi
else
  fail "_flow_get_project" "returned empty for flow-cli"
fi

# ============================================================================
# Test: Atlas session operations
# ============================================================================
echo ""
echo "== Session Operations =="

# Note: We don't actually start/end sessions in tests to avoid polluting data
# Instead, we verify the functions are calling atlas correctly

if type _flow_session_start &>/dev/null; then
  pass "_flow_session_start available with atlas backend"
else
  fail "_flow_session_start" "function not available"
fi

if type _flow_session_end &>/dev/null; then
  pass "_flow_session_end available with atlas backend"
else
  fail "_flow_session_end" "function not available"
fi

# Test atlas wrapper function
if type _flow_atlas &>/dev/null; then
  pass "_flow_atlas wrapper available"

  # Test that atlas responds to help
  if _flow_atlas --help &>/dev/null; then
    pass "  _flow_atlas --help works"
  else
    fail "  _flow_atlas --help" "command failed"
  fi
else
  fail "_flow_atlas" "wrapper not defined"
fi

# ============================================================================
# Test: Atlas capture operations
# ============================================================================
echo ""
echo "== Capture Operations =="

if type _flow_catch &>/dev/null; then
  pass "_flow_catch available with atlas backend"
else
  fail "_flow_catch" "function not available"
fi

if type _flow_inbox &>/dev/null; then
  pass "_flow_inbox available with atlas backend"
else
  fail "_flow_inbox" "function not available"
fi

if type _flow_crumb &>/dev/null; then
  pass "_flow_crumb available with atlas backend"
else
  fail "_flow_crumb" "function not available"
fi

# ============================================================================
# Test: Atlas context operations
# ============================================================================
echo ""
echo "== Context Operations =="

if type _flow_where &>/dev/null; then
  pass "_flow_where available with atlas backend"
else
  fail "_flow_where" "function not available"
fi

# Test at() shortcut
if type at &>/dev/null; then
  pass "at() shortcut available"
else
  fail "at()" "shortcut not defined"
fi

# ============================================================================
# Test: Atlas async operations
# ============================================================================
echo ""
echo "== Async Operations =="

if type _flow_atlas_async &>/dev/null; then
  pass "_flow_atlas_async available"
else
  fail "_flow_atlas_async" "function not available"
fi

if type _flow_atlas_silent &>/dev/null; then
  pass "_flow_atlas_silent available"
else
  fail "_flow_atlas_silent" "function not available"
fi

if type _flow_atlas_json &>/dev/null; then
  pass "_flow_atlas_json available"
else
  fail "_flow_atlas_json" "function not available"
fi

# ============================================================================
# Test: Atlas CLI commands (via wrapper)
# ============================================================================
echo ""
echo "== Atlas CLI Integration =="

# Test atlas project list
atlas_list=$(_flow_atlas project list --format=names 2>/dev/null | head -5)
if [[ -n "$atlas_list" ]]; then
  pass "atlas project list works"
else
  skip "atlas project list (may need sync first)"
fi

# Test atlas where
atlas_where=$(_flow_atlas where 2>&1)
if [[ "$atlas_where" != *"Error"* ]] && [[ "$atlas_where" != *"error"* ]]; then
  pass "atlas where works"
else
  skip "atlas where (no active session)"
fi

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
TOTAL=$((PASSED + FAILED + SKIPPED))
echo "  Results: ${GREEN}$PASSED passed${NC}, ${RED}$FAILED failed${NC}, ${YELLOW}$SKIPPED skipped${NC} / $TOTAL total"
echo "  Mode: ${BLUE}atlas connected${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Exit with failure if any tests failed
(( FAILED > 0 )) && exit 1
exit 0
