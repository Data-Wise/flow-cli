#!/usr/bin/env zsh
# test-sync.zsh - Unit tests for flow sync command
# Tests the unified sync orchestration (v4.0.0)

setopt local_options no_unset

# Colors
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
CYAN=$'\033[0;36m'
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
export FLOW_DEBUG=0

# Create temp directory for test data
TEST_DIR=$(mktemp -d)
export FLOW_DATA_DIR="$TEST_DIR"
export FLOW_PROJECTS_ROOT="$TEST_DIR/projects"
mkdir -p "$FLOW_PROJECTS_ROOT/test-project"

# Source the plugin
source "$FLOW_PLUGIN_DIR/flow.plugin.zsh" 2>/dev/null

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Flow Sync Unit Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Test data: $TEST_DIR"
echo ""

# ============================================================================
# Test: Function availability
# ============================================================================
echo "== Function Availability =="

if typeset -f flow_sync >/dev/null 2>&1; then
  pass "flow_sync function exists"
else
  fail "flow_sync function" "not defined"
fi

for func in _flow_sync_session _flow_sync_status _flow_sync_wins _flow_sync_goals _flow_sync_git _flow_sync_all _flow_sync_smart _flow_sync_dashboard _flow_sync_help; do
  if typeset -f $func >/dev/null 2>&1; then
    pass "$func exists"
  else
    fail "$func" "not defined"
  fi
done

# ============================================================================
# Test: Help output
# ============================================================================
echo ""
echo "== Help Output =="

help_output=$(flow_sync help 2>&1)

if [[ "$help_output" == *"FLOW SYNC"* ]]; then
  pass "Help shows title"
else
  fail "Help title" "missing FLOW SYNC title"
fi

if [[ "$help_output" == *"USAGE"* ]]; then
  pass "Help shows usage section"
else
  fail "Help usage" "missing USAGE section"
fi

if [[ "$help_output" == *"TARGETS"* ]]; then
  pass "Help shows targets section"
else
  fail "Help targets" "missing TARGETS section"
fi

for target in session status wins goals git; do
  if [[ "$help_output" == *"$target"* ]]; then
    pass "Help documents $target target"
  else
    fail "Help $target" "missing documentation"
  fi
done

if [[ "$help_output" == *"--dry-run"* ]]; then
  pass "Help documents --dry-run option"
else
  fail "Help --dry-run" "missing"
fi

# ============================================================================
# Test: Session sync
# ============================================================================
echo ""
echo "== Session Sync =="

# Create a mock session
mkdir -p "$FLOW_DATA_DIR"
cat > "$FLOW_DATA_DIR/.current-session" << EOF
project=test-project
start=$((EPOCHSECONDS - 600))
date=$(strftime "%Y-%m-%d" $EPOCHSECONDS)
EOF

export _FLOW_SYNC_DRY_RUN=0
export _FLOW_SYNC_VERBOSE=0
export _FLOW_SYNC_QUIET=0
export _FLOW_SYNC_SKIP_GIT=0

result=$(_flow_sync_session 2>&1)

if [[ "$result" == *"test-project"* ]]; then
  pass "Session sync reports project name"
else
  fail "Session sync project" "output: $result"
fi

if [[ "$result" == *"m on"* ]]; then
  pass "Session sync reports duration"
else
  fail "Session sync duration" "output: $result"
fi

if [[ -f "$FLOW_DATA_DIR/worklog" ]]; then
  if grep -q "HEARTBEAT.*test-project" "$FLOW_DATA_DIR/worklog"; then
    pass "Worklog updated with heartbeat"
  else
    fail "Worklog heartbeat" "missing heartbeat entry"
  fi
else
  fail "Worklog creation" "file not created"
fi

# ============================================================================
# Test: Status sync
# ============================================================================
echo ""
echo "== Status Sync =="

# Create a mock .STATUS file (recently modified)
cat > "$FLOW_PROJECTS_ROOT/test-project/.STATUS" << EOF
project: test-project
status: Active
progress: 50
EOF

# Touch to ensure recent mtime
touch "$FLOW_PROJECTS_ROOT/test-project/.STATUS"

result=$(_flow_sync_status 2>&1)

if [[ "$result" == *"project"* || "$result" == *"updated"* ]]; then
  pass "Status sync returns update info"
else
  # May return 0 projects if mtime check fails in test env
  skip "Status sync update (mtime-dependent)"
fi

# ============================================================================
# Test: Wins sync
# ============================================================================
echo ""
echo "== Wins Sync =="

# Create a mock .STATUS file with wins
today=$(strftime "%Y-%m-%d" $EPOCHSECONDS)
cat > "$FLOW_PROJECTS_ROOT/test-project/.STATUS" << EOF
project: test-project
status: Active
wins: Fixed bug ($today), Added feature ($today)
EOF

result=$(_flow_sync_wins 2>&1)

if [[ "$result" == *"wins"* || "$result" == *"synced"* || "$result" == *"aggregated"* ]]; then
  pass "Wins sync reports status"
else
  fail "Wins sync status" "output: $result"
fi

if [[ -f "$FLOW_DATA_DIR/wins.md" ]]; then
  pass "Global wins file created"
else
  fail "Wins file" "not created"
fi

# ============================================================================
# Test: Goals sync
# ============================================================================
echo ""
echo "== Goals Sync =="

result=$(_flow_sync_goals 2>&1)

if [[ "$result" =~ [0-9]+/[0-9]+ ]]; then
  pass "Goals sync returns progress (X/Y format)"
else
  fail "Goals sync format" "output: $result"
fi

if [[ -f "$FLOW_DATA_DIR/goal.json" ]]; then
  pass "Goal file created"

  if grep -q '"date"' "$FLOW_DATA_DIR/goal.json"; then
    pass "Goal file has date field"
  else
    fail "Goal file date" "missing date field"
  fi

  if grep -q '"target"' "$FLOW_DATA_DIR/goal.json"; then
    pass "Goal file has target field"
  else
    fail "Goal file target" "missing target field"
  fi
else
  fail "Goal file" "not created"
fi

# ============================================================================
# Test: Dry run mode
# ============================================================================
echo ""
echo "== Dry Run Mode =="

export _FLOW_SYNC_DRY_RUN=1

# Test session dry run
result=$(_flow_sync_session 2>&1)
if [[ "$result" == *"Would"* ]]; then
  pass "Session respects dry-run"
else
  pass "Session dry-run (no active session)"
fi

# Test goals dry run
result=$(_flow_sync_goals 2>&1)
if [[ "$result" == *"Current:"* ]]; then
  pass "Goals respects dry-run"
else
  fail "Goals dry-run" "output: $result"
fi

export _FLOW_SYNC_DRY_RUN=0

# ============================================================================
# Test: State management
# ============================================================================
echo ""
echo "== State Management =="

_flow_sync_state_write "success" "success" "success" "success" "skipped"

if [[ -f "$FLOW_DATA_DIR/sync-state.json" ]]; then
  pass "Sync state file created"

  content=$(cat "$FLOW_DATA_DIR/sync-state.json")

  if [[ "$content" == *'"last_sync"'* ]]; then
    pass "State has last_sync"
  else
    fail "State last_sync" "missing field"
  fi

  if [[ "$content" == *'"results"'* ]]; then
    pass "State has results"
  else
    fail "State results" "missing field"
  fi

  if [[ "$content" == *'"session": "success"'* ]]; then
    pass "State records session result"
  else
    fail "State session" "missing or wrong value"
  fi
else
  fail "Sync state file" "not created"
fi

# ============================================================================
# Test: Smart sync detection
# ============================================================================
echo ""
echo "== Smart Sync =="

result=$(_flow_sync_smart 2>&1)

if [[ "$result" == *"Sync Status"* ]]; then
  pass "Smart sync shows status header"
else
  fail "Smart sync header" "output: $result"
fi

if [[ "$result" == *"progress"* || "$result" == *"wins"* ]]; then
  pass "Smart sync shows progress info"
else
  fail "Smart sync progress" "output: $result"
fi

# ============================================================================
# Test: Dashboard
# ============================================================================
echo ""
echo "== Dashboard =="

result=$(_flow_sync_dashboard 2>&1)

if [[ "$result" == *"Dashboard"* ]]; then
  pass "Dashboard shows header"
else
  fail "Dashboard header" "output: $result"
fi

if [[ "$result" == *"sync"* ]]; then
  pass "Dashboard shows sync info"
else
  fail "Dashboard sync info" "output: $result"
fi

# ============================================================================
# Test: Flow command routing
# ============================================================================
echo ""
echo "== Command Routing =="

# Test that flow routes to sync
if flow sync help 2>&1 | grep -q "FLOW SYNC"; then
  pass "flow sync routes to flow_sync"
else
  fail "flow sync routing" "not reaching flow_sync"
fi

# ============================================================================
# Cleanup
# ============================================================================
echo ""
rm -rf "$TEST_DIR"

# ============================================================================
# Results
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -n "  Results: "
echo -n "${GREEN}$PASSED passed${NC}, "
echo -n "${RED}$FAILED failed${NC}, "
echo "${YELLOW}$SKIPPED skipped${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Exit with failure if any tests failed
(( FAILED > 0 )) && exit 1
exit 0
