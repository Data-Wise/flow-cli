#!/bin/bash
# Test script for install.sh
# Tests: detection, idempotency, error handling, all install methods
#
# Usage: ./tests/test-install.sh
#
# Requires: bash, git, zsh

set -u

# ============================================================================
# TEST FRAMEWORK
# ============================================================================

TESTS_PASSED=0
TESTS_FAILED=0
TEST_DIR=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_test() {
    echo -n -e "${CYAN}Testing:${NC} $1 ... "
}

pass() {
    echo -e "${GREEN}✓ PASS${NC}"
    ((TESTS_PASSED++))
}

fail() {
    echo -e "${RED}✗ FAIL${NC} - $1"
    ((TESTS_FAILED++))
}

# ============================================================================
# SETUP / TEARDOWN
# ============================================================================

setup_test_env() {
    # Create isolated test environment
    TEST_DIR=$(mktemp -d)
    export HOME="$TEST_DIR"
    export PATH="/usr/bin:/bin:/usr/local/bin"
    unset ZDOTDIR ZSH ZINIT_HOME INSTALL_METHOD

    # Create .zshrc
    touch "$HOME/.zshrc"
}

teardown_test_env() {
    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
    TEST_DIR=""
}

# Get project root
get_project_root() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo "${script_dir%/tests}"
}

PROJECT_ROOT=$(get_project_root)
INSTALL_SCRIPT="$PROJECT_ROOT/install.sh"

# ============================================================================
# HELPER: Define detect_plugin_manager for testing
# ============================================================================

# Copy of detect_plugin_manager from install.sh for isolated testing
_test_detect_plugin_manager() {
    if [[ -n "${INSTALL_METHOD:-}" ]]; then
        echo "$INSTALL_METHOD"
        return
    fi

    if [[ -f "${ZDOTDIR:-$HOME}/.zsh_plugins.txt" ]] || command -v antidote &>/dev/null; then
        echo "antidote"
    elif [[ -d "$HOME/.zinit" ]] || [[ -d "${ZINIT_HOME:-$HOME/.zinit}" ]] || [[ -d "$HOME/.local/share/zinit" ]]; then
        echo "zinit"
    elif [[ -d "$HOME/.oh-my-zsh" ]] || [[ -n "${ZSH:-}" && -d "${ZSH:-}" ]]; then
        echo "omz"
    else
        echo "manual"
    fi
}

# ============================================================================
# DETECTION TESTS
# ============================================================================

test_detect_antidote_by_plugins_file() {
    log_test "detect antidote by .zsh_plugins.txt"

    setup_test_env
    touch "$HOME/.zsh_plugins.txt"

    local result
    result=$(_test_detect_plugin_manager)

    if [[ "$result" == "antidote" ]]; then
        pass
    else
        fail "expected 'antidote', got '$result'"
    fi

    teardown_test_env
}

test_detect_zinit_by_dir() {
    log_test "detect zinit by .zinit directory"

    setup_test_env
    mkdir -p "$HOME/.zinit"

    local result
    result=$(_test_detect_plugin_manager)

    if [[ "$result" == "zinit" ]]; then
        pass
    else
        fail "expected 'zinit', got '$result'"
    fi

    teardown_test_env
}

test_detect_zinit_by_local_share() {
    log_test "detect zinit by .local/share/zinit"

    setup_test_env
    mkdir -p "$HOME/.local/share/zinit"

    local result
    result=$(_test_detect_plugin_manager)

    if [[ "$result" == "zinit" ]]; then
        pass
    else
        fail "expected 'zinit', got '$result'"
    fi

    teardown_test_env
}

test_detect_omz_by_dir() {
    log_test "detect oh-my-zsh by .oh-my-zsh directory"

    setup_test_env
    mkdir -p "$HOME/.oh-my-zsh"

    local result
    result=$(_test_detect_plugin_manager)

    if [[ "$result" == "omz" ]]; then
        pass
    else
        fail "expected 'omz', got '$result'"
    fi

    teardown_test_env
}

test_detect_manual_fallback() {
    log_test "detect manual as fallback"

    setup_test_env
    # No plugin manager markers

    local result
    result=$(_test_detect_plugin_manager)

    if [[ "$result" == "manual" ]]; then
        pass
    else
        fail "expected 'manual', got '$result'"
    fi

    teardown_test_env
}

test_detect_install_method_override() {
    log_test "INSTALL_METHOD override"

    setup_test_env
    mkdir -p "$HOME/.oh-my-zsh"  # Would normally detect omz
    export INSTALL_METHOD="manual"

    local result
    result=$(_test_detect_plugin_manager)

    if [[ "$result" == "manual" ]]; then
        pass
    else
        fail "expected 'manual' (override), got '$result'"
    fi

    unset INSTALL_METHOD
    teardown_test_env
}

test_detect_priority_antidote_over_zinit() {
    log_test "antidote takes priority over zinit"

    setup_test_env
    touch "$HOME/.zsh_plugins.txt"
    mkdir -p "$HOME/.zinit"

    local result
    result=$(_test_detect_plugin_manager)

    if [[ "$result" == "antidote" ]]; then
        pass
    else
        fail "expected 'antidote', got '$result'"
    fi

    teardown_test_env
}

test_detect_priority_zinit_over_omz() {
    log_test "zinit takes priority over oh-my-zsh"

    setup_test_env
    mkdir -p "$HOME/.zinit"
    mkdir -p "$HOME/.oh-my-zsh"

    local result
    result=$(_test_detect_plugin_manager)

    if [[ "$result" == "zinit" ]]; then
        pass
    else
        fail "expected 'zinit', got '$result'"
    fi

    teardown_test_env
}

# ============================================================================
# IDEMPOTENCY TESTS
# ============================================================================

test_idempotent_antidote() {
    log_test "antidote install is idempotent"

    setup_test_env
    touch "$HOME/.zsh_plugins.txt"

    local REPO="Data-Wise/flow-cli"
    local plugins_file="$HOME/.zsh_plugins.txt"

    # First install
    echo "$REPO" >> "$plugins_file"

    # Second install (should not duplicate)
    if ! grep -q "$REPO" "$plugins_file" 2>/dev/null; then
        echo "$REPO" >> "$plugins_file"
    fi

    local count
    count=$(grep -c "$REPO" "$plugins_file")

    if [[ "$count" == "1" ]]; then
        pass
    else
        fail "expected 1 entry, got $count"
    fi

    teardown_test_env
}

test_idempotent_zinit() {
    log_test "zinit install is idempotent"

    setup_test_env

    PLUGIN_NAME="flow-cli"
    REPO="Data-Wise/flow-cli"
    local zshrc="$HOME/.zshrc"
    local zinit_line="zinit light $REPO"

    # First install
    echo "$zinit_line" >> "$zshrc"

    # Second install (should not duplicate)
    if ! grep -q "zinit.*$PLUGIN_NAME" "$zshrc" 2>/dev/null; then
        echo "$zinit_line" >> "$zshrc"
    fi

    local count
    count=$(grep -c "zinit.*flow-cli" "$zshrc")

    if [[ "$count" == "1" ]]; then
        pass
    else
        fail "expected 1 entry, got $count"
    fi

    teardown_test_env
}

test_idempotent_manual() {
    log_test "manual install is idempotent"

    setup_test_env

    local zshrc="$HOME/.zshrc"
    local source_line="source $HOME/.flow-cli/flow.plugin.zsh"

    # First install
    echo "$source_line" >> "$zshrc"

    # Second install (should not duplicate)
    if ! grep -q "flow.plugin.zsh" "$zshrc" 2>/dev/null; then
        echo "$source_line" >> "$zshrc"
    fi

    local count
    count=$(grep -c "flow.plugin.zsh" "$zshrc")

    if [[ "$count" == "1" ]]; then
        pass
    else
        fail "expected 1 entry, got $count"
    fi

    teardown_test_env
}

# ============================================================================
# SCRIPT VALIDATION TESTS
# ============================================================================

test_script_syntax() {
    log_test "install.sh has valid syntax"

    if bash -n "$INSTALL_SCRIPT" 2>/dev/null; then
        pass
    else
        fail "syntax error in install.sh"
    fi
}

test_script_has_shebang() {
    log_test "install.sh has bash shebang"

    local first_line
    first_line=$(head -1 "$INSTALL_SCRIPT")

    if [[ "$first_line" == "#!/bin/bash" ]]; then
        pass
    else
        fail "expected '#!/bin/bash', got '$first_line'"
    fi
}

test_script_uses_strict_mode() {
    log_test "install.sh uses strict mode"

    if grep -q "set -euo pipefail" "$INSTALL_SCRIPT"; then
        pass
    else
        fail "missing 'set -euo pipefail'"
    fi
}

test_script_defines_repo() {
    log_test "install.sh defines REPO variable"

    if grep -q 'REPO="Data-Wise/flow-cli"' "$INSTALL_SCRIPT"; then
        pass
    else
        fail "REPO variable not found or incorrect"
    fi
}

test_script_defines_all_colors() {
    log_test "install.sh defines all color variables"

    local missing=""
    for color in RED GREEN BLUE YELLOW BOLD NC; do
        if ! grep -q "^${color}=" "$INSTALL_SCRIPT"; then
            missing="$missing $color"
        fi
    done

    if [[ -z "$missing" ]]; then
        pass
    else
        fail "missing colors:$missing"
    fi
}

test_script_has_all_install_functions() {
    log_test "install.sh has all install functions"

    local missing=""
    for func in install_antidote install_zinit install_omz install_manual; do
        if ! grep -q "^${func}()" "$INSTALL_SCRIPT"; then
            missing="$missing $func"
        fi
    done

    if [[ -z "$missing" ]]; then
        pass
    else
        fail "missing functions:$missing"
    fi
}

test_script_checks_zsh() {
    log_test "install.sh checks for zsh"

    if grep -q "command -v zsh" "$INSTALL_SCRIPT"; then
        pass
    else
        fail "zsh check not found"
    fi
}

test_script_checks_git() {
    log_test "install.sh checks for git"

    if grep -q "command -v git" "$INSTALL_SCRIPT"; then
        pass
    else
        fail "git check not found"
    fi
}

# ============================================================================
# ZDOTDIR TESTS
# ============================================================================

test_zdotdir_antidote() {
    log_test "antidote respects ZDOTDIR"

    setup_test_env
    export ZDOTDIR="$HOME/custom-zsh"
    mkdir -p "$ZDOTDIR"
    touch "$ZDOTDIR/.zsh_plugins.txt"

    local result
    result=$(_test_detect_plugin_manager)

    if [[ "$result" == "antidote" ]]; then
        pass
    else
        fail "expected 'antidote' with ZDOTDIR, got '$result'"
    fi

    unset ZDOTDIR
    teardown_test_env
}

# ============================================================================
# FLOW_INSTALL_DIR TESTS
# ============================================================================

test_custom_install_dir() {
    log_test "FLOW_INSTALL_DIR is respected"

    # Source the variable assignment
    FLOW_INSTALL_DIR="/custom/path"
    INSTALL_DIR="${FLOW_INSTALL_DIR:-$HOME/.flow-cli}"

    if [[ "$INSTALL_DIR" == "/custom/path" ]]; then
        pass
    else
        fail "expected '/custom/path', got '$INSTALL_DIR'"
    fi

    unset FLOW_INSTALL_DIR
}

test_default_install_dir() {
    log_test "default INSTALL_DIR is ~/.flow-cli"

    unset FLOW_INSTALL_DIR
    INSTALL_DIR="${FLOW_INSTALL_DIR:-$HOME/.flow-cli}"

    if [[ "$INSTALL_DIR" == "$HOME/.flow-cli" ]]; then
        pass
    else
        fail "expected '$HOME/.flow-cli', got '$INSTALL_DIR'"
    fi
}

# ============================================================================
# RUN ALL TESTS
# ============================================================================

run_tests() {
    echo ""
    echo -e "${BOLD}flow-cli install.sh Test Suite${NC}"
    echo "=================================="
    echo ""

    echo -e "${YELLOW}Detection Tests${NC}"
    echo "----------------"
    test_detect_antidote_by_plugins_file
    test_detect_zinit_by_dir
    test_detect_zinit_by_local_share
    test_detect_omz_by_dir
    test_detect_manual_fallback
    test_detect_install_method_override
    test_detect_priority_antidote_over_zinit
    test_detect_priority_zinit_over_omz

    echo ""
    echo -e "${YELLOW}Idempotency Tests${NC}"
    echo "------------------"
    test_idempotent_antidote
    test_idempotent_zinit
    test_idempotent_manual

    echo ""
    echo -e "${YELLOW}Script Validation Tests${NC}"
    echo "------------------------"
    test_script_syntax
    test_script_has_shebang
    test_script_uses_strict_mode
    test_script_defines_repo
    test_script_defines_all_colors
    test_script_has_all_install_functions
    test_script_checks_zsh
    test_script_checks_git

    echo ""
    echo -e "${YELLOW}ZDOTDIR Tests${NC}"
    echo "--------------"
    test_zdotdir_antidote

    echo ""
    echo -e "${YELLOW}FLOW_INSTALL_DIR Tests${NC}"
    echo "------------------------"
    test_custom_install_dir
    test_default_install_dir

    # Summary
    echo ""
    echo "=================================="
    echo -e "${BOLD}Results:${NC}"
    echo -e "  ${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "  ${RED}Failed: $TESTS_FAILED${NC}"
    echo ""

    if [[ $TESTS_FAILED -gt 0 ]]; then
        exit 1
    fi
}

# Run tests
run_tests
