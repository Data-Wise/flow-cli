#!/usr/bin/env zsh
# dogfood-agenda.zsh - Structural dogfood tests for the agenda / schedule layer
#
# Verifies the feature is properly WIRED (not behavior — see e2e-agenda.zsh):
# - engine + command + alias functions are defined after a clean plugin load
# - the engine is sourced after date-parser/atlas-bridge in flow.plugin.zsh
# - dash/morning/today/week call into the shared engine
# - holiday filtering goes through the helper (no raw grep -v '|holiday|' left)
# - no ZSH footguns (local path= / local status=) in the engine
# - packaging is present: man pages, completion, docs references
#
# Usage: zsh tests/dogfood-agenda.zsh

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
        [[ -n "$output" ]] && echo "    ${DIM}${output:0:200}${RESET}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

echo ""
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo "${CYAN}  Agenda / Schedule Layer - Dogfood Test${RESET}"
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo ""

FLOW_QUIET=1
FLOW_ATLAS_ENABLED=no
FLOW_PLUGIN_DIR="$PROJECT_ROOT"
source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
    echo "${RED}Failed to load plugin${RESET}"
    exit 1
}

# ============================================================================
# SECTION 1: command + alias functions wired
# ============================================================================

echo "${CYAN}--- Section 1: Command surface ---${RESET}"

run_test "agenda command is defined" '
    typeset -f agenda >/dev/null 2>&1 || return 1
'

run_test "agt/agw/agm aliases are defined and delegate to agenda" '
    for a in agt agw agm; do
        typeset -f "$a" >/dev/null 2>&1 || { echo "missing $a"; return 1; }
        typeset -f "$a" | grep -q "agenda" || { echo "$a does not call agenda"; return 1; }
    done
'

run_test "_agenda_help is defined" '
    typeset -f _agenda_help >/dev/null 2>&1 || return 1
'

# ============================================================================
# SECTION 2: engine functions wired
# ============================================================================

echo ""
echo "${CYAN}--- Section 2: Engine functions ---${RESET}"

run_test "all schedule engine functions are defined" '
    local fns=(
        _schedule_classify _schedule_relative_days _schedule_parse_status
        _schedule_teach_items _schedule_expand_recurring _schedule_collect
        _schedule_filter_window _schedule_sort _schedule_render_line
        _schedule_category_match _schedule_drop_holidays
        _schedule_json_escape _schedule_records_to_json _flow_schedule_to_atlas
    )
    local missing=""
    for f in "${fns[@]}"; do
        typeset -f "$f" >/dev/null 2>&1 || missing+="$f "
    done
    [[ -z "$missing" ]] || { echo "missing: $missing"; return 1; }
'

run_test "module guard _FLOW_SCHEDULE_LOADED is set" '
    [[ "$_FLOW_SCHEDULE_LOADED" == "1" ]] || return 1
'

run_test "engine is sourced after date-parser in flow.plugin.zsh" '
    local f="$PROJECT_ROOT/flow.plugin.zsh"
    local dp=$(grep -n "date-parser.zsh" "$f" | head -1 | cut -d: -f1)
    local sc=$(grep -n "schedule.zsh" "$f" | grep -v date | head -1 | cut -d: -f1)
    [[ -n "$dp" && -n "$sc" ]] || { echo "dp=$dp sc=$sc"; return 1; }
    (( dp < sc )) || { echo "date-parser ($dp) must precede schedule ($sc)"; return 1; }
'

# ============================================================================
# SECTION 3: surface integration (dash / cadence)
# ============================================================================

echo ""
echo "${CYAN}--- Section 3: Surface integration ---${RESET}"

run_test "dash() calls _dash_upcoming" '
    typeset -f dash | grep -q "_dash_upcoming" || return 1
'

run_test "morning/today/week call the schedule helpers" '
    typeset -f morning | grep -q "_flow_morning_agenda" || { echo "morning"; return 1; }
    typeset -f today   | grep -q "_flow_today_agenda"   || { echo "today"; return 1; }
    typeset -f week    | grep -q "_flow_week_agenda"    || { echo "week"; return 1; }
'

run_test "holiday filtering goes through _schedule_drop_holidays (no raw grep left)" '
    local hits
    hits=$(grep -rn "grep -v .|holiday|." "$PROJECT_ROOT/commands" 2>/dev/null)
    [[ -z "$hits" ]] || { echo "raw holiday grep remains: $hits"; return 1; }
'

# ============================================================================
# SECTION 4: robustness / footguns
# ============================================================================

echo ""
echo "${CYAN}--- Section 4: Robustness ---${RESET}"

run_test "engine has no local path= / local status= footguns" '
    local hits
    hits=$(grep -nE "local +(path|status)=" "$PROJECT_ROOT/lib/schedule.zsh" "$PROJECT_ROOT/commands/agenda.zsh" 2>/dev/null)
    [[ -z "$hits" ]] || { echo "$hits"; return 1; }
'

run_test "agenda runs without leaking engine vars into the shell" '
    local before after
    agenda -h >/dev/null 2>&1
    for v in rtype cat rec proj_cat out b_overdue b_today b_week b_later; do
        typeset -p "$v" >/dev/null 2>&1 && { echo "leaked: $v"; return 1; }
    done
    return 0
'

# ============================================================================
# SECTION 5: packaging (man / completion / docs)
# ============================================================================

echo ""
echo "${CYAN}--- Section 5: Packaging ---${RESET}"

run_test "man pages exist for agenda + cadence commands" '
    for p in agenda dash morning today week; do
        [[ -f "$PROJECT_ROOT/man/man1/$p.1" ]] || { echo "missing man/man1/$p.1"; return 1; }
    done
'

run_test "agenda man page .TH matches FLOW_VERSION" '
    local want=$(grep -oE "FLOW_VERSION=\"?[0-9]+\.[0-9]+\.[0-9]+" "$PROJECT_ROOT/flow.plugin.zsh" | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" | head -1)
    grep -q "flow-cli $want" "$PROJECT_ROOT/man/man1/agenda.1" || { echo "expected flow-cli $want"; return 1; }
'

run_test "completion file _agenda exists" '
    [[ -f "$PROJECT_ROOT/completions/_agenda" ]] || return 1
'

run_test "docs reference the agenda command" '
    grep -q "agenda" "$PROJECT_ROOT/docs/help/QUICK-REFERENCE.md" || { echo "QUICK-REFERENCE"; return 1; }
    [[ -f "$PROJECT_ROOT/docs/guides/AGENDA-SCHEDULE-GUIDE.md" ]] || { echo "guide missing"; return 1; }
'

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "${GREEN}All $TESTS_PASSED/$TESTS_RUN dogfood tests passed${RESET}"
    exit 0
else
    echo "${RED}$TESTS_FAILED/$TESTS_RUN tests failed (${TESTS_PASSED} passed)${RESET}"
    exit 1
fi
