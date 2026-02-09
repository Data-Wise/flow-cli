#!/usr/bin/env zsh
# dogfood-teach-doctor-v2.zsh - Dogfooding test for teach doctor v2
#
# Sources flow.plugin.zsh and verifies all teach doctor v2 functions
# loaded correctly: two-mode architecture, renv awareness, spinner,
# health indicator, CI mode, status file.
#
# Usage: zsh tests/dogfood-teach-doctor-v2.zsh

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

# Colors
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
echo "${CYAN}  Teach Doctor v2 - Dogfood Test${RESET}"
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo ""

# ============================================================================
# LOAD PLUGIN
# ============================================================================

echo "${CYAN}Loading flow.plugin.zsh...${RESET}"
FLOW_QUIET=1
FLOW_PLUGIN_DIR="$PROJECT_ROOT"
source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
    echo "${RED}Plugin failed to load${RESET}"
    exit 1
}
echo "${GREEN}Plugin loaded (v$FLOW_VERSION)${RESET}"
echo ""

# ============================================================================
# SECTION 1: Core Doctor Functions Exist
# ============================================================================

echo "${CYAN}--- Section 1: Core Doctor Functions ---${RESET}"

run_test "_teach_doctor exists" '
    typeset -f _teach_doctor >/dev/null 2>&1 || return 1
'

run_test "_teach_doctor_pass exists" '
    typeset -f _teach_doctor_pass >/dev/null 2>&1 || return 1
'

run_test "_teach_doctor_warn exists" '
    typeset -f _teach_doctor_warn >/dev/null 2>&1 || return 1
'

run_test "_teach_doctor_fail exists" '
    typeset -f _teach_doctor_fail >/dev/null 2>&1 || return 1
'

run_test "_teach_doctor_summary exists" '
    typeset -f _teach_doctor_summary >/dev/null 2>&1 || return 1
'

echo ""

# ============================================================================
# SECTION 2: Check Functions Exist (Quick Mode)
# ============================================================================

echo "${CYAN}--- Section 2: Quick Mode Check Functions ---${RESET}"

run_test "_teach_doctor_check_dependencies exists" '
    typeset -f _teach_doctor_check_dependencies >/dev/null 2>&1 || return 1
'

run_test "_teach_doctor_check_r_quick exists" '
    typeset -f _teach_doctor_check_r_quick >/dev/null 2>&1 || return 1
'

run_test "_teach_doctor_check_config exists" '
    typeset -f _teach_doctor_check_config >/dev/null 2>&1 || return 1
'

run_test "_teach_doctor_check_git exists" '
    typeset -f _teach_doctor_check_git >/dev/null 2>&1 || return 1
'

run_test "_teach_doctor_check_dep exists" '
    typeset -f _teach_doctor_check_dep >/dev/null 2>&1 || return 1
'

echo ""

# ============================================================================
# SECTION 3: Check Functions Exist (Full Mode)
# ============================================================================

echo "${CYAN}--- Section 3: Full Mode Check Functions ---${RESET}"

run_test "_teach_doctor_check_r_packages exists" '
    typeset -f _teach_doctor_check_r_packages >/dev/null 2>&1 || return 1
'

run_test "_teach_doctor_check_quarto_extensions exists" '
    typeset -f _teach_doctor_check_quarto_extensions >/dev/null 2>&1 || return 1
'

run_test "_teach_doctor_check_scholar exists" '
    typeset -f _teach_doctor_check_scholar >/dev/null 2>&1 || return 1
'

run_test "_teach_doctor_check_hooks exists" '
    typeset -f _teach_doctor_check_hooks >/dev/null 2>&1 || return 1
'

run_test "_teach_doctor_check_cache exists" '
    typeset -f _teach_doctor_check_cache >/dev/null 2>&1 || return 1
'

run_test "_teach_doctor_check_macros exists" '
    typeset -f _teach_doctor_check_macros >/dev/null 2>&1 || return 1
'

run_test "_teach_doctor_check_teaching_style exists" '
    typeset -f _teach_doctor_check_teaching_style >/dev/null 2>&1 || return 1
'

echo ""

# ============================================================================
# SECTION 4: Spinner Functions
# ============================================================================

echo "${CYAN}--- Section 4: Spinner Functions ---${RESET}"

run_test "_teach_doctor_spinner_start exists" '
    typeset -f _teach_doctor_spinner_start >/dev/null 2>&1 || return 1
'

run_test "_teach_doctor_spinner_stop exists" '
    typeset -f _teach_doctor_spinner_stop >/dev/null 2>&1 || return 1
'

run_test "_teach_doctor_section_gap exists" '
    typeset -f _teach_doctor_section_gap >/dev/null 2>&1 || return 1
'

echo ""

# ============================================================================
# SECTION 5: Health Indicator Functions
# ============================================================================

echo "${CYAN}--- Section 5: Health Indicator Functions ---${RESET}"

run_test "_teach_doctor_write_status exists" '
    typeset -f _teach_doctor_write_status >/dev/null 2>&1 || return 1
'

run_test "_teach_health_indicator exists" '
    typeset -f _teach_health_indicator >/dev/null 2>&1 || return 1
'

run_test "_teach_health_dot exists" '
    typeset -f _teach_health_dot >/dev/null 2>&1 || return 1
'

echo ""

# ============================================================================
# SECTION 6: Output Functions
# ============================================================================

echo "${CYAN}--- Section 6: Output Functions ---${RESET}"

run_test "_teach_doctor_json_output exists" '
    typeset -f _teach_doctor_json_output >/dev/null 2>&1 || return 1
'

run_test "_teach_doctor_interactive_fix exists" '
    typeset -f _teach_doctor_interactive_fix >/dev/null 2>&1 || return 1
'

echo ""

# ============================================================================
# SECTION 7: R Helpers Integration
# ============================================================================

echo "${CYAN}--- Section 7: R Helpers ---${RESET}"

run_test "_get_installed_r_packages exists" '
    typeset -f _get_installed_r_packages >/dev/null 2>&1 || return 1
'

echo ""

# ============================================================================
# SECTION 8: Behavioral Tests (Quick Smoke)
# ============================================================================

echo "${CYAN}--- Section 8: Behavioral Smoke Tests ---${RESET}"

# Test in a temp directory to avoid side effects
TEMP_TEST_DIR=$(mktemp -d)
ORIG_DIR=$(pwd)
mkdir -p "$TEMP_TEST_DIR/.flow" "$TEMP_TEST_DIR/.git"

cat > "$TEMP_TEST_DIR/.flow/teach-config.yml" <<'YAML'
course:
  name: "DOGFOOD-101"
  semester: "Spring 2026"
YAML

cd "$TEMP_TEST_DIR"

run_test "teach doctor --ci produces machine-readable output" '
    local output
    output=$(_teach_doctor --ci 2>&1)
    echo "$output" | grep -q "^doctor:status=" || return 1
    echo "$output" | grep -q "^doctor:passed=" || return 1
'

run_test "teach doctor --json contains version field" '
    local output
    output=$(_teach_doctor --json 2>&1)
    echo "$output" | grep -q "\"version\"" || return 1
'

run_test "teach doctor --brief suppresses header" '
    local output
    output=$(_teach_doctor --brief 2>&1)
    ! echo "$output" | grep -q "Teaching Environment" || return 1
'

run_test "teach doctor creates status file" '
    rm -f .flow/doctor-status.json
    _teach_doctor --brief >/dev/null 2>&1
    [[ -f .flow/doctor-status.json ]] || return 1
'

run_test "Health indicator reads status file" '
    _teach_doctor --brief >/dev/null 2>&1
    local ind
    ind=$(_teach_health_indicator)
    [[ "$ind" =~ ^(green|yellow|red)$ ]] || return 1
'

run_test "Health dot returns non-empty output" '
    _teach_doctor --brief >/dev/null 2>&1
    local dot
    dot=$(_teach_health_dot)
    [[ -n "$dot" ]] || return 1
'

run_test "teach doctor returns exit code 0 or 1 (no crash)" '
    _teach_doctor --brief >/dev/null 2>&1
    local rc=$?
    [[ $rc -eq 0 || $rc -eq 1 ]] || return 1
'

# Cleanup
cd "$ORIG_DIR"
rm -rf "$TEMP_TEST_DIR"

echo ""

# ============================================================================
# SECTION 9: Flag Parsing Verification
# ============================================================================

echo "${CYAN}--- Section 9: Flag Parsing ---${RESET}"

TEMP_TEST_DIR=$(mktemp -d)
mkdir -p "$TEMP_TEST_DIR/.flow" "$TEMP_TEST_DIR/.git"
cat > "$TEMP_TEST_DIR/.flow/teach-config.yml" <<'YAML'
course:
  name: "FLAG-TEST"
  semester: "Spring 2026"
YAML
cd "$TEMP_TEST_DIR"

run_test "--fix implies full mode (CI output check)" '
    local output
    output=$(_teach_doctor --ci --fix 2>&1 < /dev/null)
    echo "$output" | grep -q "doctor:mode=full" || return 1
'

run_test "--verbose implies full mode" '
    local output
    output=$(_teach_doctor --verbose 2>&1)
    echo "$output" | grep -q "full check" || return 1
'

run_test "--quiet is deprecated alias for --brief" '
    local output
    output=$(_teach_doctor -q 2>&1)
    ! echo "$output" | grep -q "Teaching Environment" || return 1
'

run_test "--ci mode does not show fix hint" '
    local output
    output=$(_teach_doctor --ci 2>&1)
    ! echo "$output" | grep -q "teach doctor --fix" || return 1
'

run_test "--json does not show fix hint" '
    local output
    output=$(_teach_doctor --json 2>&1)
    ! echo "$output" | grep -q "teach doctor --fix" || return 1
'

cd "$ORIG_DIR"
rm -rf "$TEMP_TEST_DIR"

echo ""

# ============================================================================
# SECTION 10: Verbose Mode Behavior
# ============================================================================

echo "${CYAN}--- Section 10: Verbose Mode ---${RESET}"

TEMP_TEST_DIR=$(mktemp -d)
mkdir -p "$TEMP_TEST_DIR/.flow" "$TEMP_TEST_DIR/.git"
cat > "$TEMP_TEST_DIR/.flow/teach-config.yml" <<'YAML'
course:
  name: "VERBOSE-TEST"
  semester: "Spring 2026"
YAML
cd "$TEMP_TEST_DIR"

run_test "--verbose shows full check header" '
    local output
    output=$(_teach_doctor --verbose 2>&1)
    echo "$output" | grep -q "full check" || return 1
'

run_test "--verbose shows renv.lock age detail (if renv present)" '
    # Create minimal renv setup
    echo "{\"R\":{\"Version\":\"4.4.2\"},\"Packages\":{}}" > renv.lock
    mkdir -p renv
    echo "# activate" > renv/activate.R
    local output
    output=$(_teach_doctor --verbose 2>&1)
    echo "$output" | grep -q "renv.lock updated" || return 1
    rm -f renv.lock renv/activate.R
    rmdir renv 2>/dev/null
'

cd "$ORIG_DIR"
rm -rf "$TEMP_TEST_DIR"

echo ""

# ============================================================================
# SECTION 11: Fix Hint in Summary
# ============================================================================

echo "${CYAN}--- Section 11: Fix Hint Behavior ---${RESET}"

TEMP_TEST_DIR=$(mktemp -d)
mkdir -p "$TEMP_TEST_DIR/.flow" "$TEMP_TEST_DIR/.git"
cat > "$TEMP_TEST_DIR/.flow/teach-config.yml" <<'YAML'
course:
  name: "FIXHINT-TEST"
  semester: "Spring 2026"
YAML
cd "$TEMP_TEST_DIR"

run_test "Summary shows fix hint when warnings exist" '
    local output
    output=$(_teach_doctor 2>&1)
    echo "$output" | grep -q "teach doctor --fix" || return 1
'

run_test "Fix hint not shown with --fix flag" '
    local output
    output=$(_teach_doctor --fix 2>&1 < /dev/null)
    ! echo "$output" | grep -q "teach doctor --fix" || return 1
'

run_test "Fix hint shown even in --brief mode (summary always shows)" '
    local output
    output=$(_teach_doctor --brief 2>&1)
    echo "$output" | grep -q "teach doctor --fix" || return 1
'

cd "$ORIG_DIR"
rm -rf "$TEMP_TEST_DIR"

echo ""

# ============================================================================
# SUMMARY
# ============================================================================

echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "${GREEN}All $TESTS_PASSED/$TESTS_RUN dogfood tests passed${RESET}"
    exit 0
else
    echo "${RED}$TESTS_FAILED/$TESTS_RUN tests failed (${TESTS_PASSED} passed)${RESET}"
    exit 1
fi
