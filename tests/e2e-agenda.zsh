#!/usr/bin/env zsh
# e2e-agenda.zsh - End-to-end tests for the forward-looking schedule layer
#
# Drives the real user-facing commands (agenda / dash / morning / today / week)
# against a seeded multi-project FLOW_PROJECTS_ROOT and asserts the rendered
# output. Covers windows, overdue, type/category filters, holiday hide/--all,
# recurring expansion, pipe-in-label sanitization, the dash UPCOMING section,
# cadence enrichment, the empty state, and atlas-disabled operation.
#
# Pure .STATUS-driven (no yq needed); the teaching path is exercised only when
# yq is present (skips otherwise).
#
# Usage: zsh tests/e2e-agenda.zsh

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local test_name="$1"
    local test_func="$2"

    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "  ${CYAN}[$TESTS_RUN] $test_name...${RESET} "

    local output
    output=$(eval "$test_func" 2>&1)
    local rc=$?

    if [[ $rc -eq 0 ]]; then
        echo "${GREEN}PASS${RESET}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    elif [[ $rc -eq 77 ]]; then
        echo "${YELLOW}SKIP${RESET}"
    else
        echo "${RED}FAIL${RESET}"
        [[ -n "$output" ]] && echo "    ${DIM}${output:0:300}${RESET}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# ============================================================================
# SETUP
# ============================================================================

echo ""
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo "${CYAN}  E2E: Agenda / Schedule Layer${RESET}"
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo ""

FLOW_QUIET=1
FLOW_ATLAS_ENABLED=no
FLOW_SCHEDULE_NO_CACHE=1
FLOW_PLUGIN_DIR="$PROJECT_ROOT"
source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
    echo "${RED}Failed to load plugin${RESET}"
    exit 1
}

exec < /dev/null
zmodload zsh/datetime 2>/dev/null

# Date anchors relative to "today" so the suite never goes stale
TODAY=$(strftime '%Y-%m-%d' $EPOCHSECONDS)
PAST=$(_date_add_days "$TODAY" -2)      # overdue
SOON=$(_date_add_days "$TODAY" 3)       # this week
FAR=$(_date_add_days "$TODAY" 20)       # later (outside 7d)
HOL=$(_date_add_days "$TODAY" 2)        # holiday in-window

# Isolated project root with a research project and a dev-category project
TEST_ROOT=$(mktemp -d)
EMPTY_ROOT=$(mktemp -d)
mkdir -p "$TEST_ROOT/research/paper-x" "$TEST_ROOT/webapp"

cat > "$TEST_ROOT/research/paper-x/.STATUS" <<EOF
## Status: active

## Schedule:
- $PAST | Overdue reviewer response | research
- $TODAY | Submit revision today | research
- $SOON | Beta milestone | general
- $FAR | Grant LOI deadline | research
- weekly:mon | Advisor meeting | research
EOF

# webapp is detected as a 'dev' project but carries a research-typed item plus
# a holiday and a label that contains a pipe.
cat > "$TEST_ROOT/webapp/.STATUS" <<EOF
## Status: active

## Schedule:
- $SOON | Ship v2 | general
- $SOON | Fix bug | crash | research
- $HOL | Fall Break | holiday
EOF

FLOW_PROJECTS_ROOT="$TEST_ROOT"

ORIGINAL_DIR=$(pwd)
cleanup() {
    cd "$ORIGINAL_DIR"
    rm -rf "$TEST_ROOT" "$EMPTY_ROOT"
}
trap cleanup EXIT

# ============================================================================
# SECTION 1: agenda windows
# ============================================================================

echo "${CYAN}--- Section 1: Windows ---${RESET}"

run_test "agenda -h exits 0 and shows usage" '
    local output rc
    output=$(agenda -h 2>&1); rc=$?
    [[ $rc -eq 0 ]] || { echo "rc=$rc"; return 1; }
    [[ "$output" == *"AGENDA"* ]] || return 1
'

run_test "agenda (default) shows buckets + in-window items, hides far item" '
    local output
    output=$(agenda 2>&1)
    [[ "$output" == *"OVERDUE"* ]] || { echo "no OVERDUE"; return 1; }
    [[ "$output" == *"Submit revision today"* ]] || { echo "no today item"; return 1; }
    [[ "$output" == *"Beta milestone"* ]] || { echo "no soon item"; return 1; }
    [[ "$output" != *"Grant LOI deadline"* ]] || { echo "far item leaked at 7d"; return 1; }
'

run_test "agenda --overdue shows only overdue" '
    local output
    output=$(agenda --overdue 2>&1)
    [[ "$output" == *"Overdue reviewer response"* ]] || return 1
    [[ "$output" != *"Beta milestone"* ]] || { echo "soon item leaked"; return 1; }
'

run_test "agenda today shows today + overdue, hides future" '
    local output
    output=$(agenda today 2>&1)
    [[ "$output" == *"Submit revision today"* ]] || return 1
    [[ "$output" == *"Overdue reviewer response"* ]] || return 1
    [[ "$output" != *"Beta milestone"* ]] || { echo "future leaked"; return 1; }
'

run_test "agenda -m includes the LATER far item" '
    local output
    output=$(agenda -m 2>&1)
    [[ "$output" == *"Grant LOI deadline"* ]] || return 1
    [[ "$output" == *"LATER"* ]] || return 1
'

# ============================================================================
# SECTION 2: filters (type + category)
# ============================================================================

echo ""
echo "${CYAN}--- Section 2: Filters ---${RESET}"

run_test "agenda research matches a research item in a dev-category project" '
    local output
    output=$(agenda research 2>&1)
    [[ "$output" == *"Fix bug"* ]] || { echo "cross-category research item missing"; return 1; }
    [[ "$output" != *"Ship v2"* ]] || { echo "general item leaked into research"; return 1; }
'

run_test "agenda general is accepted (not unknown) and filters by type" '
    local output
    output=$(agenda general 2>&1)
    [[ "$output" != *"Unknown"* ]] || { echo "general rejected"; return 1; }
    [[ "$output" == *"Beta milestone"* ]] || return 1
    [[ "$output" != *"Overdue reviewer response"* ]] || { echo "research leaked into general"; return 1; }
'

# ============================================================================
# SECTION 3: holidays + recurring + pipe-in-label
# ============================================================================

echo ""
echo "${CYAN}--- Section 3: Holidays / recurring / pipe label ---${RESET}"

run_test "agenda (default) hides holiday-typed items" '
    local output
    output=$(agenda -m 2>&1)
    [[ "$output" != *"Fall Break"* ]] || { echo "holiday shown without --all"; return 1; }
'

run_test "agenda --all reveals holiday-typed items" '
    local output
    output=$(agenda --all 2>&1)
    [[ "$output" == *"Fall Break"* ]] || { echo "holiday hidden under --all"; return 1; }
'

run_test "recurring weekly:mon expands into a concrete dated occurrence" '
    local output
    output=$(agenda -m 2>&1)
    [[ "$output" == *"Advisor meeting"* ]] || return 1
'

run_test "label containing a pipe renders sanitized, type intact" '
    local output
    output=$(agenda research 2>&1)
    [[ "$output" == *"Fix bug / crash"* ]] || { echo "pipe not sanitized: $output"; return 1; }
'

# ============================================================================
# SECTION 4: empty state + atlas-disabled
# ============================================================================

echo ""
echo "${CYAN}--- Section 4: Empty state ---${RESET}"

run_test "agenda shows a calm empty state when nothing is scheduled" '
    local output
    output=$(FLOW_PROJECTS_ROOT="$EMPTY_ROOT" agenda 2>&1)
    [[ "$output" == *"Nothing scheduled"* ]] || return 1
'

run_test "agenda emits no error markers (atlas disabled)" '
    local output
    output=$(agenda 2>&1)
    [[ "$output" != *"command not found"* ]] || return 1
    [[ "$output" != *"no such"* ]] || return 1
    [[ "$output" != *"parse error"* ]] || return 1
'

# ============================================================================
# SECTION 5: dash + cadence integration
# ============================================================================

echo ""
echo "${CYAN}--- Section 5: dash + cadence surfaces ---${RESET}"

run_test "dash includes an UPCOMING section fed by the engine" '
    local output
    output=$(dash 2>&1)
    [[ "$output" == *"UPCOMING"* ]] || { echo "no UPCOMING in dash"; return 1; }
    [[ "$output" == *"Submit revision today"* ]] || return 1
'

run_test "dash UPCOMING self-suppresses with no schedule data" '
    local output
    output=$(FLOW_PROJECTS_ROOT="$EMPTY_ROOT" dash 2>&1)
    [[ "$output" != *"UPCOMING"* ]] || { echo "empty UPCOMING header leaked"; return 1; }
'

run_test "today shows a Due today block" '
    local output
    output=$(today 2>&1)
    [[ "$output" == *"Due today"* ]] || return 1
    [[ "$output" == *"Submit revision today"* ]] || return 1
'

run_test "week shows This week deadlines grouped by weekday" '
    local output
    output=$(week 2>&1)
    [[ "$output" == *"This week"*"deadlines"* ]] || return 1
    [[ "$output" == *"Beta milestone"* ]] || return 1
'

run_test "morning includes the upcoming block without error" '
    local output
    output=$(morning 2>&1)
    [[ "$output" != *"command not found"* ]] || return 1
    [[ "$output" == *"Beta milestone"* ]] || { echo "morning missing upcoming item"; return 1; }
'

# ============================================================================
# SECTION 6: teaching path (yq-gated)
# ============================================================================

echo ""
echo "${CYAN}--- Section 6: Teaching config (yq-gated) ---${RESET}"

run_test "teach-config items surface in agenda when yq present" '
    command -v yq >/dev/null 2>&1 || return 77
    local fixture="$PROJECT_ROOT/tests/fixtures/teach-config-scheduled.yml"
    [[ -f "$fixture" ]] || return 77
    mkdir -p "$TEST_ROOT/teaching/stat-202/.flow"
    cp "$fixture" "$TEST_ROOT/teaching/stat-202/.flow/teach-config.yml"
    # A project is discovered via its .STATUS file (real teach projects have one)
    printf "## Status: active\n" > "$TEST_ROOT/teaching/stat-202/.STATUS"
    local output
    output=$(agenda --all 2>&1)
    rm -rf "$TEST_ROOT/teaching"
    [[ "$output" == *"Week"* ]] || { echo "no teaching week records"; return 1; }
'

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
cd "$ORIGINAL_DIR"
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "${GREEN}All $TESTS_PASSED/$TESTS_RUN e2e tests passed${RESET}"
    exit 0
else
    echo "${RED}$TESTS_FAILED/$TESTS_RUN tests failed (${TESTS_PASSED} passed)${RESET}"
    exit 1
fi
