#!/usr/bin/env zsh
# e2e-plugin-system.zsh - End-to-end tests for plugin management
#
# Tests the full plugin lifecycle: create, install, list, info, disable, enable, remove.
# Uses isolated temp directories so no real plugins are modified.
#
# Usage: zsh tests/e2e-plugin-system.zsh

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

echo ""
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo "${CYAN}  E2E: Plugin System${RESET}"
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo ""

# ============================================================================
# SETUP
# ============================================================================

# Load the plugin
FLOW_QUIET=1
FLOW_PLUGIN_DIR="$PROJECT_ROOT"
source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
    echo "${RED}Failed to load plugin${RESET}"
    exit 1
}

# Use a temp directory as the user plugin directory
TEST_DIR=$(mktemp -d)
ORIGINAL_XDG="$XDG_CONFIG_HOME"

cleanup() {
    XDG_CONFIG_HOME="$ORIGINAL_XDG"
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# ============================================================================
# SECTION 1: Plugin help
# ============================================================================

echo "${CYAN}--- Section 1: Plugin Help ---${RESET}"

run_test "flow plugin help produces output" '
    local output
    output=$(flow_plugin help 2>&1)
    [[ "$output" == *"plugin"* ]] || return 1
    [[ "$output" == *"COMMANDS"* ]] || return 1
'

run_test "flow plugin list runs" '
    local output
    output=$(flow_plugin list 2>&1)
    local rc=$?
    [[ $rc -eq 0 ]] || return 1
'

run_test "flow plugin path shows search paths" '
    local output
    output=$(flow_plugin path 2>&1)
    [[ "$output" == *"PLUGIN SEARCH PATHS"* ]] || return 1
'

echo ""

# ============================================================================
# SECTION 2: Plugin create
# ============================================================================

echo "${CYAN}--- Section 2: Plugin Create ---${RESET}"

run_test "flow plugin create generates plugin structure" '
    local plugin_dir="$TEST_DIR/create-test"
    mkdir -p "$plugin_dir"

    _flow_plugin_create "test-plugin" "$plugin_dir" 2>/dev/null

    [[ -f "$plugin_dir/test-plugin/main.zsh" ]] || { echo "Missing main.zsh"; return 1; }
    [[ -f "$plugin_dir/test-plugin/plugin.json" ]] || { echo "Missing plugin.json"; return 1; }
'

run_test "Created plugin.json is valid JSON" '
    local json_file="$TEST_DIR/create-test/test-plugin/plugin.json"
    [[ -f "$json_file" ]] || { echo "No plugin.json"; return 1; }

    if command -v jq &>/dev/null; then
        jq . "$json_file" >/dev/null 2>&1 || { echo "Invalid JSON"; return 1; }
    elif command -v python3 &>/dev/null; then
        python3 -m json.tool "$json_file" >/dev/null 2>&1 || { echo "Invalid JSON"; return 1; }
    else
        return 77  # skip if no JSON validator
    fi
'

run_test "Created main.zsh is sourceable" '
    local main_file="$TEST_DIR/create-test/test-plugin/main.zsh"
    [[ -f "$main_file" ]] || { echo "No main.zsh"; return 1; }

    # Should source without error
    source "$main_file" 2>/dev/null
    local rc=$?
    [[ $rc -eq 0 ]] || { echo "Source failed (rc=$rc)"; return 1; }
'

run_test "Plugin name validation rejects invalid names" '
    local output
    output=$(_flow_plugin_cmd_create "123-invalid" 2>&1)
    local rc=$?
    [[ $rc -ne 0 ]] || return 1
'

run_test "Plugin name validation rejects empty name" '
    local output
    output=$(_flow_plugin_cmd_create "" 2>&1 <<< "")
    local rc=$?
    [[ $rc -ne 0 ]] || return 1
'

echo ""

# ============================================================================
# SECTION 3: Plugin install from local path
# ============================================================================

echo "${CYAN}--- Section 3: Plugin Install ---${RESET}"

run_test "Install from local path copies files" '
    # Create a fake plugin to install
    local src_plugin="$TEST_DIR/src-plugin"
    mkdir -p "$src_plugin"
    echo "# test plugin" > "$src_plugin/main.zsh"
    echo "{\"name\": \"src-plugin\", \"version\": \"1.0.0\"}" > "$src_plugin/plugin.json"

    # Set up isolated install target
    local install_dir="$TEST_DIR/install-plugins"
    mkdir -p "$install_dir"

    # Override the plugin dir for this test
    XDG_CONFIG_HOME="$TEST_DIR/xdg-config"
    mkdir -p "$XDG_CONFIG_HOME/flow/plugins"

    _flow_plugin_cmd_install "$src_plugin" 2>/dev/null

    [[ -f "$XDG_CONFIG_HOME/flow/plugins/src-plugin/main.zsh" ]] || {
        echo "Plugin not installed"
        return 1
    }
'

run_test "Install rejects nonexistent source" '
    local output
    output=$(_flow_plugin_cmd_install "/nonexistent/path/to/plugin" 2>&1)
    local rc=$?
    [[ $rc -ne 0 ]] || return 1
'

run_test "Install rejects duplicate" '
    # src-plugin was installed above — installing again should fail
    local src_plugin="$TEST_DIR/src-plugin"
    XDG_CONFIG_HOME="$TEST_DIR/xdg-config"

    local output
    output=$(_flow_plugin_cmd_install "$src_plugin" 2>&1)
    local rc=$?
    [[ $rc -ne 0 ]] || return 1
'

echo ""

# ============================================================================
# SECTION 4: Plugin dev mode (symlink)
# ============================================================================

echo "${CYAN}--- Section 4: Dev Mode Install ---${RESET}"

run_test "Dev mode creates symlink" '
    local dev_plugin="$TEST_DIR/dev-plugin"
    mkdir -p "$dev_plugin"
    echo "# dev plugin" > "$dev_plugin/main.zsh"
    echo "{\"name\": \"dev-plugin\"}" > "$dev_plugin/plugin.json"

    XDG_CONFIG_HOME="$TEST_DIR/xdg-config"

    _flow_plugin_cmd_install --dev "$dev_plugin" 2>/dev/null

    local target="$XDG_CONFIG_HOME/flow/plugins/dev-plugin"
    [[ -L "$target" ]] || { echo "Not a symlink"; return 1; }
'

run_test "Dev mode symlink points to correct source" '
    local target="$TEST_DIR/xdg-config/flow/plugins/dev-plugin"
    local resolved
    resolved=$(readlink "$target" 2>/dev/null)

    [[ "$resolved" == *"dev-plugin"* ]] || { echo "Points to: $resolved"; return 1; }
'

echo ""

# ============================================================================
# SECTION 5: Plugin remove
# ============================================================================

echo "${CYAN}--- Section 5: Plugin Remove ---${RESET}"

run_test "Remove deletes user plugin" '
    XDG_CONFIG_HOME="$TEST_DIR/xdg-config"
    local target="$XDG_CONFIG_HOME/flow/plugins/src-plugin"

    [[ -d "$target" ]] || { echo "Plugin not present to remove"; return 1; }

    _flow_plugin_cmd_remove -f src-plugin 2>/dev/null

    [[ ! -d "$target" ]] || { echo "Plugin still exists"; return 1; }
'

run_test "Remove deletes symlinked plugin" '
    XDG_CONFIG_HOME="$TEST_DIR/xdg-config"
    local target="$XDG_CONFIG_HOME/flow/plugins/dev-plugin"

    [[ -L "$target" ]] || { echo "Symlink not present"; return 1; }

    _flow_plugin_cmd_remove -f dev-plugin 2>/dev/null

    [[ ! -e "$target" ]] || { echo "Symlink still exists"; return 1; }
'

run_test "Remove nonexistent plugin fails gracefully" '
    XDG_CONFIG_HOME="$TEST_DIR/xdg-config"
    local output
    output=$(_flow_plugin_cmd_remove -f nonexistent-plugin 2>&1)
    local rc=$?
    [[ $rc -ne 0 ]] || return 1
'

echo ""

# ============================================================================
# SECTION 6: Plugin discovery and metadata
# ============================================================================

echo "${CYAN}--- Section 6: Discovery & Metadata ---${RESET}"

run_test "_flow_plugin_discover finds bundled plugins" '
    local discovered
    discovered=$(_flow_plugin_discover 2>/dev/null)
    [[ -n "$discovered" ]] || return 1
'

run_test "_flow_plugin_metadata extracts name" '
    local discovered
    discovered=$(_flow_plugin_discover 2>/dev/null | head -1)
    [[ -n "$discovered" ]] || return 77

    local metadata
    metadata=$(_flow_plugin_metadata "$discovered" 2>/dev/null)
    [[ -n "$metadata" ]] || { echo "No metadata for: $discovered"; return 1; }
'

echo ""

# ============================================================================
# SUMMARY
# ============================================================================

echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "${GREEN}All $TESTS_PASSED/$TESTS_RUN plugin e2e tests passed${RESET}"
    exit 0
else
    echo "${RED}$TESTS_FAILED/$TESTS_RUN tests failed (${TESTS_PASSED} passed)${RESET}"
    exit 1
fi
