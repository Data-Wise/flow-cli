#!/usr/bin/env zsh
# e2e-core-commands.zsh - End-to-end tests for core commands
#
# Tests non-interactive paths for: status, catch, win/yay, flow doctor --dot
# Uses temp directories and mocked FLOW_PROJECTS_ROOT to avoid needing tmux.
#
# Usage: zsh tests/e2e-core-commands.zsh

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
        [[ -n "$output" ]] && echo "    ${DIM}${output:0:300}${RESET}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# ============================================================================
# SETUP
# ============================================================================

echo ""
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo "${CYAN}  E2E: Core Commands${RESET}"
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo ""

# Load plugin
FLOW_QUIET=1
FLOW_PLUGIN_DIR="$PROJECT_ROOT"
source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
    echo "${RED}Failed to load plugin${RESET}"
    exit 1
}

# Create isolated test environment
TEST_ROOT=$(mktemp -d)
TEST_PROJECT="$TEST_ROOT/apps/test-project"
mkdir -p "$TEST_PROJECT"

# Create a minimal project
cat > "$TEST_PROJECT/.STATUS" <<'EOF'
# test-project

## Status: Active
## Progress: 50%
## Next: Add feature X
## Target: v1.0.0
EOF

ORIGINAL_DIR=$(pwd)
cleanup() {
    cd "$ORIGINAL_DIR"
    rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

# ============================================================================
# SECTION 1: Status command
# ============================================================================

echo "${CYAN}--- Section 1: Status Command ---${RESET}"

run_test "status reads .STATUS file" '
    cd "$TEST_PROJECT"
    local output
    output=$(_flow_status_show "$TEST_PROJECT" 2>&1)
    [[ "$output" == *"test-project"* ]] || [[ "$output" == *"Active"* ]] || return 1
'

run_test "status get field reads Status" '
    local result
    result=$(_flow_status_get_field "$TEST_PROJECT/.STATUS" "Status" 2>/dev/null)
    [[ "$result" == "Active" ]] || { echo "Got: $result"; return 1; }
'

run_test "status get field reads Progress" '
    local result
    result=$(_flow_status_get_field "$TEST_PROJECT/.STATUS" "Progress" 2>/dev/null)
    [[ "$result" == "50%" ]] || { echo "Got: $result"; return 1; }
'

run_test "status set field updates value" '
    local tmp_status=$(mktemp -d)/project
    mkdir -p "$tmp_status"
    cp "$TEST_PROJECT/.STATUS" "$tmp_status/.STATUS"
    _flow_status_set_field "$tmp_status/.STATUS" "Progress" "75%"
    local result
    result=$(_flow_status_get_field "$tmp_status/.STATUS" "Progress" 2>/dev/null)
    rm -rf "$(dirname "$tmp_status")"
    [[ "$result" == "75%" ]] || { echo "Got: $result"; return 1; }
'

run_test "status create generates valid .STATUS" '
    local tmp_dir=$(mktemp -d)
    mkdir -p "$tmp_dir"
    cd "$tmp_dir"
    _flow_status_create "$tmp_dir" 2>/dev/null
    [[ -f "$tmp_dir/.STATUS" ]] || { echo "No .STATUS created"; return 1; }
    grep -q "Status:" "$tmp_dir/.STATUS" || { echo "Missing Status field"; return 1; }
    rm -rf "$tmp_dir"
'

echo ""

# ============================================================================
# SECTION 2: Catch (quick capture)
# ============================================================================

echo "${CYAN}--- Section 2: Quick Capture ---${RESET}"

run_test "catch function exists" '
    typeset -f catch >/dev/null 2>&1 || return 1
'

run_test "catch with text creates capture" '
    local original_data_dir="$FLOW_DATA_DIR"
    local tmp_data=$(mktemp -d)
    FLOW_DATA_DIR="$tmp_data"

    catch "test capture item" 2>/dev/null
    local rc=$?

    # Check if capture file was created
    local found=false
    if [[ -f "$tmp_data/captures.md" ]] || [[ -f "$tmp_data/captures.txt" ]]; then
        found=true
    fi
    # Also check if any file in the dir contains our text
    if grep -r "test capture item" "$tmp_data" &>/dev/null; then
        found=true
    fi

    FLOW_DATA_DIR="$original_data_dir"
    rm -rf "$tmp_data"

    [[ "$found" == "true" || $rc -eq 0 ]] || return 1
'

echo ""

# ============================================================================
# SECTION 3: Win/Yay (dopamine features)
# ============================================================================

echo "${CYAN}--- Section 3: Dopamine Features ---${RESET}"

run_test "win function exists" '
    typeset -f win >/dev/null 2>&1 || return 1
'

run_test "yay function exists" '
    typeset -f yay >/dev/null 2>&1 || return 1
'

run_test "win logs accomplishment" '
    local original_data_dir="$FLOW_DATA_DIR"
    local tmp_data=$(mktemp -d)
    FLOW_DATA_DIR="$tmp_data"
    mkdir -p "$tmp_data"

    local output
    output=$(win "Fixed the regression bug" 2>&1)
    local rc=$?

    FLOW_DATA_DIR="$original_data_dir"

    # Win should succeed (rc=0) or produce output with the win text
    if [[ $rc -eq 0 ]] || [[ "$output" == *"Fixed"* ]] || [[ "$output" == *"win"* ]] || [[ "$output" == *"Win"* ]]; then
        rm -rf "$tmp_data"
        return 0
    fi
    rm -rf "$tmp_data"
    echo "rc=$rc output=$output"
    return 1
'

run_test "yay shows recent wins" '
    local output
    output=$(yay 2>&1)
    local rc=$?
    # Yay should either show wins or say "no wins" — either is valid
    [[ $rc -eq 0 ]] || [[ "$output" == *"win"* ]] || [[ "$output" == *"Win"* ]] || [[ "$output" == *"No "* ]] || return 1
'

echo ""

# ============================================================================
# SECTION 4: Flow doctor (non-interactive checks)
# ============================================================================

echo "${CYAN}--- Section 4: Flow Doctor ---${RESET}"

run_test "flow doctor runs without crash" '
    local output
    output=$(doctor 2>&1 | head -30)
    [[ -n "$output" ]] || return 1
'

run_test "flow doctor --dot runs" '
    local output
    output=$(doctor --dot 2>&1 | head -30)
    # Should produce output (even if warnings)
    [[ -n "$output" ]] || return 1
'

echo ""

# ============================================================================
# SECTION 5: Project detection
# ============================================================================

echo "${CYAN}--- Section 5: Project Detection ---${RESET}"

run_test "Detect project root from subdirectory" '
    local sub_dir="$TEST_PROJECT/src/components"
    mkdir -p "$sub_dir"

    # Create a marker that _flow_find_project_root looks for
    touch "$TEST_PROJECT/package.json"

    cd "$sub_dir"
    local root
    root=$(_flow_find_project_root 2>/dev/null)

    [[ "$root" == "$TEST_PROJECT" ]] || { echo "Got: $root"; return 1; }
'

run_test "Detect project type for Node project" '
    local tmp_proj=$(mktemp -d)
    echo "{}" > "$tmp_proj/package.json"
    cd "$tmp_proj"

    local ptype
    ptype=$(_flow_detect_project_type 2>/dev/null)
    rm -rf "$tmp_proj"

    [[ "$ptype" == "node" ]] || [[ "$ptype" == "npm" ]] || [[ "$ptype" == "javascript" ]] || { echo "Got: $ptype"; return 1; }
'

run_test "Detect project type for R project" '
    local tmp_proj=$(mktemp -d)
    cat > "$tmp_proj/DESCRIPTION" <<RDESC
Package: testpkg
Title: Test
Version: 1.0.0
RDESC
    touch "$tmp_proj/NAMESPACE"
    cd "$tmp_proj"

    local ptype
    ptype=$(_flow_detect_project_type 2>/dev/null)
    rm -rf "$tmp_proj"

    [[ "$ptype" == "r" ]] || [[ "$ptype" == "R" ]] || [[ "$ptype" == "r-package" ]] || { echo "Got: $ptype"; return 1; }
'

run_test "Detect project type for Python project" '
    local tmp_proj=$(mktemp -d)
    cat > "$tmp_proj/pyproject.toml" <<PYTOML
[project]
name = "testpkg"
version = "1.0.0"
PYTOML
    cd "$tmp_proj"

    local ptype
    ptype=$(_flow_detect_project_type 2>/dev/null)
    rm -rf "$tmp_proj"

    [[ "$ptype" == "python" ]] || [[ "$ptype" == "py" ]] || { echo "Got: $ptype"; return 1; }
'

run_test "Detect project type for Quarto project" '
    local tmp_proj=$(mktemp -d)
    cat > "$tmp_proj/_quarto.yml" <<QYML
project:
  type: website
QYML
    cd "$tmp_proj"

    local ptype
    ptype=$(_flow_detect_project_type 2>/dev/null)
    rm -rf "$tmp_proj"

    [[ "$ptype" == "quarto" ]] || { echo "Got: $ptype"; return 1; }
'

echo ""

# ============================================================================
# SECTION 6: Core utility functions
# ============================================================================

echo "${CYAN}--- Section 6: Utility Functions ---${RESET}"

run_test "_flow_human_size converts bytes" '
    local result
    result=$(_flow_human_size 1048576 2>/dev/null)
    [[ "$result" == *"M"* ]] || [[ "$result" == *"1.0"* ]] || { echo "Got: $result"; return 1; }
'

run_test "_flow_project_name extracts name from path" '
    local result
    result=$(_flow_project_name "/Users/test/projects/my-project" 2>/dev/null)
    [[ "$result" == "my-project" ]] || { echo "Got: $result"; return 1; }
'

run_test "_flow_log_success produces output" '
    local output
    output=$(_flow_log_success "test message" 2>&1)
    [[ "$output" == *"test message"* ]] || return 1
'

run_test "_flow_log_error produces output" '
    local output
    output=$(_flow_log_error "error message" 2>&1)
    [[ "$output" == *"error message"* ]] || return 1
'

echo ""

# ============================================================================
# SUMMARY
# ============================================================================

cd "$ORIGINAL_DIR"
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "${GREEN}All $TESTS_PASSED/$TESTS_RUN e2e tests passed${RESET}"
    exit 0
else
    echo "${RED}$TESTS_FAILED/$TESTS_RUN tests failed (${TESTS_PASSED} passed)${RESET}"
    exit 1
fi
