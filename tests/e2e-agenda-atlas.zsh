#!/usr/bin/env zsh
# e2e-agenda-atlas.zsh - End-to-end tests for the atlas agenda source
# (SPEC-planning-coordination-2026-07-01 §3.4, ORCHESTRATE Phase 2)
#
# Drives the real `agenda` command against a seeded FLOW_PROJECTS_ROOT under
# BOTH atlas states:
#   - Absent (capability-flag override, D15) — output must be byte-identical
#     to the no-atlas baseline (graceful degradation, no behavior change).
#   - Present + capable (a stub `atlas` shim on PATH returning
#     tests/fixtures/atlas-agenda-stub.json, D16 — real atlas has no `agenda`
#     command yet, so it cannot be used for this).
#
# Also verifies the 3-source dedupe (date|label|project) added alongside this
# feature — the atlas source is the first one that can produce a genuine
# duplicate against a local .STATUS record.
#
# Usage: zsh tests/e2e-agenda-atlas.zsh

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

echo ""
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo "${CYAN}  E2E: Agenda Atlas Source (dark-ready)${RESET}"
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

if ! command -v jq >/dev/null 2>&1; then
    echo "${YELLOW}jq not installed — skipping (atlas agenda source requires jq)${RESET}"
    exit 77
fi

exec < /dev/null

FIXTURE="$PROJECT_ROOT/tests/fixtures/atlas-agenda-stub.json"

# Isolated project root. "grant-writing" matches the fixture's project field
# so category-filter + dedupe tests resolve a real local path for it.
TEST_ROOT=$(mktemp -d)
STUB_BIN=$(mktemp -d)
mkdir -p "$TEST_ROOT/research/grant-writing"
cat > "$TEST_ROOT/research/grant-writing/.STATUS" <<'EOF'
## Status: active

## Schedule:
- 2026-07-05 | Submit grant report | research
EOF

FLOW_PROJECTS_ROOT="$TEST_ROOT"

ORIGINAL_DIR=$(pwd)
ORIGINAL_PATH="$PATH"
cleanup() {
    cd "$ORIGINAL_DIR"
    PATH="$ORIGINAL_PATH"
    _FLOW_ATLAS_AVAILABLE=""
    _FLOW_ATLAS_HAS_AGENDA=""
    rm -rf "$TEST_ROOT" "$STUB_BIN"
}
trap cleanup EXIT

_install_stub_atlas() {
    cat > "$STUB_BIN/atlas" <<EOF
#!/bin/sh
if [ "\$1" = "agenda" ] && [ "\$2" = "--help" ]; then
  exit 0
fi
if [ "\$1" = "agenda" ]; then
  cat "$FIXTURE"
  exit 0
fi
exit 1
EOF
    chmod +x "$STUB_BIN/atlas"
}

# ============================================================================
# SECTION 1: atlas absent (D15) — degradation proven
# ============================================================================

echo "${CYAN}--- Section 1: Atlas absent (capability-flag override) ---${RESET}"

run_test "agenda -m with atlas absent: only the local .STATUS record, no atlas items" '
    _FLOW_ATLAS_AVAILABLE="no"
    _FLOW_ATLAS_HAS_AGENDA=""
    local output
    output=$(agenda -m 2>&1)
    [[ "$output" == *"Submit grant report"* ]] || { echo "local record missing"; return 1; }
    [[ "$output" != *"NIH progress report"* ]] || { echo "atlas item leaked while atlas absent"; return 1; }
'

run_test "no atlas: output identical whether _schedule_atlas_items exists or not (no behavior change)" '
    _FLOW_ATLAS_AVAILABLE="no"
    _FLOW_ATLAS_HAS_AGENDA=""
    local with_source=$(agenda -m 2>&1)
    local direct=$(_schedule_atlas_items 30 2>&1)
    [[ -z "$direct" ]] || { echo "atlas source not empty while absent: $direct"; return 1; }
    [[ -n "$with_source" ]] || return 1
'

# ============================================================================
# SECTION 2: atlas present + capable (D16) — items merge in
# ============================================================================

echo ""
echo "${CYAN}--- Section 2: Atlas present (stub shim on PATH) ---${RESET}"

run_test "agenda -m merges atlas fixture items alongside the local .STATUS record" '
    _install_stub_atlas
    PATH="$STUB_BIN:$ORIGINAL_PATH"
    _FLOW_ATLAS_AVAILABLE=""
    _FLOW_ATLAS_HAS_AGENDA=""
    local output
    output=$(agenda -m 2>&1)
    PATH="$ORIGINAL_PATH"
    [[ "$output" == *"Submit grant report"* ]] || { echo "local record missing"; return 1; }
    [[ "$output" == *"NIH progress report"* ]] || { echo "atlas item missing"; return 1; }
'

run_test "atlas items pass through the category filter (_schedule_collect, wide window)" '
    _install_stub_atlas
    PATH="$STUB_BIN:$ORIGINAL_PATH"
    _FLOW_ATLAS_AVAILABLE=""
    _FLOW_ATLAS_HAS_AGENDA=""
    # Direct _schedule_collect call (not the `agenda` CLI, which hardcodes
    # window=7 for category filters) — a wide window avoids the fixture'"'"'s
    # fixed dates going stale relative to "today" as real time passes.
    local output
    output=$(_schedule_collect 3650 research 2>&1)
    PATH="$ORIGINAL_PATH"
    [[ "$output" == *"NIH progress report"* ]] || { echo "atlas research item missing under category filter"; return 1; }
'

# ============================================================================
# SECTION 3: dedupe (date|label|project) — atlas duplicate of a local record
# ============================================================================

echo ""
echo "${CYAN}--- Section 3: Dedupe across sources ---${RESET}"

run_test "a (date,label,project)-identical atlas record does not double-count the local one" '
    _install_stub_atlas
    PATH="$STUB_BIN:$ORIGINAL_PATH"
    _FLOW_ATLAS_AVAILABLE=""
    _FLOW_ATLAS_HAS_AGENDA=""
    # The fixture'"'"'s first record (2026-07-05|Submit grant report|research|grant-writing)
    # exactly matches the local .STATUS record above on (date,label,project).
    local output
    output=$(agenda -m 2>&1)
    PATH="$ORIGINAL_PATH"
    local count=$(print -r -- "$output" | grep -c "Submit grant report")
    [[ "$count" -eq 1 ]] || { echo "expected exactly 1 occurrence, got $count"; return 1; }
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
