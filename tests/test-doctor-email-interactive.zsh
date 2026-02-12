#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE: Doctor Email — Interactive Headless Tests
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: Test interactive code paths (--fix menu, guided setup wizard,
#          confirmation prompts) headlessly via stdin piping. No real
#          package installs — uses PATH manipulation + fake brew/pip.
#
# Differs from test-doctor-email-e2e.zsh by:
#   - Testing interactive stdin-driven paths (menu selection, confirmations)
#   - Faking brew/pip to avoid real installs
#   - Testing _doctor_email_setup wizard with piped input
#   - Testing _doctor_select_fix_category menu responses
#   - Testing _doctor_confirm yes/no branching
#   - Testing --fix -y auto-yes bypass
#
# Test Categories:
#   1. _doctor_confirm: Yes/No/Empty Branching (4 tests)
#   2. _doctor_select_fix_category: Menu Selection (5 tests)
#   3. _doctor_fix_email: Brew/Pip Install Simulation (3 tests)
#   4. _doctor_email_setup: Gmail Wizard (4 tests)
#   5. _doctor_email_setup: Custom Provider Wizard (2 tests)
#   6. _doctor_email_setup: Cancel/Edge Cases (3 tests)
#   7. --fix -y End-to-End (2 tests)
#
# Created: 2026-02-12
# ══════════════════════════════════════════════════════════════════════════════

TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

log_test() {
    echo -n "${CYAN}Testing:${NC} $1 ... "
}

pass() {
    echo "${GREEN}✓ PASS${NC}"
    ((TESTS_PASSED++))
}

fail() {
    echo "${RED}✗ FAIL${NC} - $1"
    ((TESTS_FAILED++))
}

skip() {
    echo "${DIM}○ SKIP${NC} - $1"
}

strip_ansi() {
    sed 's/\x1b\[[0-9;]*m//g'
}

# ══════════════════════════════════════════════════════════════════════════════
# SETUP
# ══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="${0:A:h}"
FLOW_ROOT="${SCRIPT_DIR:h}"

setup() {
    echo ""
    echo "${YELLOW}Setting up interactive headless test environment...${NC}"

    if [[ ! -f "$FLOW_ROOT/flow.plugin.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root at $FLOW_ROOT${NC}"
        exit 1
    fi

    echo "  Project root: $FLOW_ROOT"

    # Source the plugin
    FLOW_QUIET=1
    FLOW_ATLAS_ENABLED=no
    export FLOW_QUIET FLOW_ATLAS_ENABLED

    source "$FLOW_ROOT/flow.plugin.zsh" 2>/dev/null || {
        echo "${RED}Plugin failed to load${NC}"
        exit 1
    }

    # Create isolated test root
    TEST_ROOT=$(mktemp -d)
    mkdir -p "$TEST_ROOT/dev-tools/mock-dev"
    echo "## Status: active\n## Progress: 50" > "$TEST_ROOT/dev-tools/mock-dev/.STATUS"
    FLOW_PROJECTS_ROOT="$TEST_ROOT"

    # Create isolated XDG config for setup wizard tests (avoid touching real config)
    TEST_XDG=$(mktemp -d)
    export XDG_CONFIG_HOME="$TEST_XDG"

    # Save original PATH
    ORIGINAL_PATH="$PATH"

    # Create fake brew/pip scripts that log calls instead of installing
    FAKE_BIN=$(mktemp -d)
    cat > "$FAKE_BIN/brew" <<'SCRIPT'
#!/bin/sh
echo "FAKE_BREW_CALLED: $*" >&2
echo "fake-brew: $2 installed"
exit 0
SCRIPT
    chmod +x "$FAKE_BIN/brew"

    cat > "$FAKE_BIN/pip" <<'SCRIPT'
#!/bin/sh
echo "FAKE_PIP_CALLED: $*" >&2
echo "fake-pip: $2 installed"
exit 0
SCRIPT
    chmod +x "$FAKE_BIN/pip"

    # Initialize doctor tracking arrays (normally done inside doctor())
    # Must match exact types from commands/doctor.zsh lines 108-116
    typeset -ga _doctor_missing_brew=()
    typeset -ga _doctor_missing_npm=()
    typeset -ga _doctor_missing_pip=()
    typeset -gA _doctor_token_issues=()
    typeset -ga _doctor_alias_issues=()
    typeset -ga _doctor_missing_email_brew=()
    typeset -ga _doctor_missing_email_pip=()
    typeset -g _doctor_email_no_config=false

    # Cleanup on exit
    trap "rm -rf '$TEST_ROOT' '$TEST_XDG' '$FAKE_BIN'; PATH='$ORIGINAL_PATH'" EXIT

    echo "  Fake bin: $FAKE_BIN"
    echo "  Test XDG: $TEST_XDG"
    echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════════════════════════════

# Build a PATH that excludes a specific command by symlinking everything else
# Usage: local modified_path=$(build_path_without "himalaya" "glow")
build_path_without() {
    setopt local_options NULL_GLOB
    local -a exclude_cmds=("$@")
    local tmpbin=$(mktemp -d)

    for bin_dir in ${(s/:/)ORIGINAL_PATH}; do
        [[ -d "$bin_dir" ]] || continue
        for f in "$bin_dir"/*(.N); do
            local name="${f:t}"
            # Skip excluded commands
            local skip=false
            for exc in "${exclude_cmds[@]}"; do
                [[ "$name" == "$exc" ]] && { skip=true; break }
            done
            $skip && continue
            [[ -e "$tmpbin/$name" ]] && continue
            ln -sf "$f" "$tmpbin/$name" 2>/dev/null
        done
    done

    # Override brew and pip with fakes (if fake bin still exists)
    [[ -f "$FAKE_BIN/brew" ]] && cp "$FAKE_BIN/brew" "$tmpbin/brew" 2>/dev/null
    [[ -f "$FAKE_BIN/pip" ]] && cp "$FAKE_BIN/pip" "$tmpbin/pip" 2>/dev/null
    chmod +x "$tmpbin/brew" "$tmpbin/pip" 2>/dev/null

    echo "$tmpbin"
}

# Run doctor with em() loaded and piped stdin
# Usage: local output=$(doctor_interactive "stdin_input" [flags...])
doctor_interactive() {
    local stdin_data="$1"
    shift
    em() { : }
    local out
    out=$(echo "$stdin_data" | doctor "$@" 2>&1)
    unfunction em 2>/dev/null
    echo "$out"
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 1: _doctor_confirm Yes/No/Empty Branching (4 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_confirm_yes() {
    log_test "_doctor_confirm returns 0 (true) on 'y' input"

    local result
    echo "y" | _doctor_confirm "Test prompt?" >/dev/null 2>&1
    result=$?

    if [[ $result -eq 0 ]]; then
        pass
    else
        fail "Expected exit 0, got $result"
    fi
}

test_confirm_no() {
    log_test "_doctor_confirm returns 1 (false) on 'n' input"

    local result
    echo "n" | _doctor_confirm "Test prompt?" >/dev/null 2>&1
    result=$?

    if [[ $result -eq 1 ]]; then
        pass
    else
        fail "Expected exit 1, got $result"
    fi
}

test_confirm_empty_defaults_yes() {
    log_test "_doctor_confirm returns 0 (true) on empty input (default=Y)"

    local result
    echo "" | _doctor_confirm "Test prompt?" >/dev/null 2>&1
    result=$?

    if [[ $result -eq 0 ]]; then
        pass
    else
        fail "Expected exit 0 (default yes), got $result"
    fi
}

test_confirm_NO_uppercase() {
    log_test "_doctor_confirm returns 1 (false) on 'NO' input"

    local result
    echo "NO" | _doctor_confirm "Test prompt?" >/dev/null 2>&1
    result=$?

    if [[ $result -eq 1 ]]; then
        pass
    else
        fail "Expected exit 1, got $result"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 2: _doctor_select_fix_category Menu Selection (5 tests)
# ══════════════════════════════════════════════════════════════════════════════

_reset_doctor_arrays() {
    # Reset all tracking arrays to empty (preserving types)
    _doctor_missing_brew=()
    _doctor_missing_npm=()
    _doctor_missing_pip=()
    _doctor_token_issues=()
    _doctor_alias_issues=()
    _doctor_missing_email_brew=()
    _doctor_missing_email_pip=()
    _doctor_email_no_config=false
}

test_menu_auto_yes_selects_all() {
    log_test "_doctor_select_fix_category returns 'all' with auto_yes=true"

    _reset_doctor_arrays
    _doctor_missing_email_brew=(himalaya)
    _doctor_missing_email_pip=(email-oauth2-proxy)

    # auto_yes=true bypasses menu, returns "all" on stdout
    # Capture only the function's echo output (filter out log messages)
    local result
    result=$(_doctor_select_fix_category false true 2>/dev/null)
    local exit_code=$?

    _reset_doctor_arrays

    # The function echoes "all" to stdout — but _doctor_log_always also uses stdout
    # Extract just the last line (the category result)
    result=$(echo "$result" | tail -1)

    if [[ "$result" == "all" && $exit_code -eq 0 ]]; then
        pass
    else
        fail "Expected 'all' exit 0, got '$result' exit $exit_code"
    fi
}

test_menu_single_category_auto_selects() {
    log_test "_doctor_select_fix_category auto-selects when only 1 category"

    _reset_doctor_arrays
    _doctor_missing_email_brew=(glow)

    local result
    result=$(_doctor_select_fix_category false false 2>/dev/null)
    local exit_code=$?

    _reset_doctor_arrays

    result=$(echo "$result" | tail -1)

    if [[ "$result" == "email" && $exit_code -eq 0 ]]; then
        pass
    else
        fail "Expected 'email' exit 0, got '$result' exit $exit_code"
    fi
}

test_menu_no_issues_returns_2() {
    log_test "_doctor_select_fix_category returns exit 2 when no issues"

    _reset_doctor_arrays

    _doctor_select_fix_category false false >/dev/null 2>&1
    local exit_code=$?

    if [[ $exit_code -eq 2 ]]; then
        pass
    else
        fail "Expected exit 2 (no issues), got $exit_code"
    fi
}

test_menu_cancel_with_0() {
    log_test "_doctor_select_fix_category returns exit 1 on '0' input"

    _reset_doctor_arrays
    # Multiple categories so menu shows
    _doctor_missing_brew=(eza)
    _doctor_missing_email_brew=(glow)

    echo "0" | _doctor_select_fix_category false false >/dev/null 2>&1
    local exit_code=$?

    _reset_doctor_arrays

    if [[ $exit_code -eq 1 ]]; then
        pass
    else
        fail "Expected exit 1 (cancelled), got $exit_code"
    fi
}

test_menu_select_email_category() {
    log_test "_doctor_select_fix_category returns 'email' when selected by number"

    _reset_doctor_arrays
    # tools = category 1, email = category 2
    _doctor_missing_brew=(eza)
    _doctor_missing_email_brew=(glow)

    local result
    result=$(echo "2" | _doctor_select_fix_category false false 2>/dev/null)
    local exit_code=$?

    _reset_doctor_arrays

    # The function mixes menu display (via echo) with the category result (via echo)
    # The category name appears as the last word on the last line or as a standalone line
    local stripped=$(echo "$result" | strip_ansi)
    local found=false
    if echo "$stripped" | grep -qE '(^|\s)email(\s|$)'; then
        found=true
    fi

    if [[ "$found" == true && $exit_code -eq 0 ]]; then
        pass
    else
        fail "Expected 'email' exit 0, got exit $exit_code, output contains: $(echo "$stripped" | tail -3)"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 3: _doctor_fix_email Brew/Pip Install Simulation (3 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_fix_email_calls_fake_brew() {
    log_test "_doctor_fix_email calls brew install for missing brew packages"

    _reset_doctor_arrays
    _doctor_missing_email_brew=(glow)

    local saved_path="$PATH"
    PATH="$FAKE_BIN:$ORIGINAL_PATH"

    # auto_yes=true skips confirmation; 2>&1 merges stderr (where fake brew logs)
    local output=$(_doctor_fix_email true 2>&1)

    PATH="$saved_path"
    _reset_doctor_arrays

    local stripped=$(echo "$output" | strip_ansi)

    if echo "$output" | grep -q "FAKE_BREW_CALLED.*install.*glow"; then
        pass
    elif echo "$stripped" | grep -qi "glow installed\|Installing glow"; then
        pass
    else
        fail "Expected fake brew to be called for glow. Output: $(echo "$stripped" | head -5)"
    fi
}

test_fix_email_calls_fake_pip() {
    log_test "_doctor_fix_email calls pip install for missing pip packages"

    _reset_doctor_arrays
    _doctor_missing_email_pip=(email-oauth2-proxy)

    local saved_path="$PATH"
    PATH="$FAKE_BIN:$ORIGINAL_PATH"

    local output=$(_doctor_fix_email true 2>&1)

    PATH="$saved_path"
    _reset_doctor_arrays

    if echo "$output" | grep -q "FAKE_PIP_CALLED.*install.*email-oauth2-proxy"; then
        pass
    elif echo "$output" | grep -qi "Installing email-oauth2-proxy\|email-oauth2-proxy installed"; then
        pass
    else
        fail "Expected fake pip to be called for email-oauth2-proxy. Output: $(echo "$output" | strip_ansi | head -5)"
    fi
}

test_fix_email_confirm_no_skips_install() {
    log_test "_doctor_fix_email skips install when user says no"

    _reset_doctor_arrays
    _doctor_missing_email_brew=(glow)

    local saved_path="$PATH"
    PATH="$FAKE_BIN:$ORIGINAL_PATH"

    # Pipe "n" to decline the _doctor_confirm prompt
    local output=$(echo "n" | _doctor_fix_email false 2>&1)

    PATH="$saved_path"
    _reset_doctor_arrays

    if echo "$output" | grep -q "FAKE_BREW_CALLED"; then
        fail "brew should NOT have been called when user said no"
    else
        pass
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 4: _doctor_email_setup Gmail Wizard (4 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_setup_gmail_generates_config() {
    log_test "setup wizard generates config.toml for Gmail address"

    # Piped input: email, then accept defaults for IMAP/port/SMTP/port
    # Gmail auto-detects: imap.gmail.com, 993, smtp.gmail.com, 587, oauth2
    local input="user@gmail.com\n\n\n\n\n"

    local output=$(printf "$input" | _doctor_email_setup 2>&1)
    local config_file="$TEST_XDG/himalaya/config.toml"

    if [[ -f "$config_file" ]]; then
        local content=$(<"$config_file")
        if echo "$content" | grep -q 'email = "user@gmail.com"'; then
            pass
        else
            fail "Config file missing email address"
        fi
        # Clean up for next test
        rm -f "$config_file"
    else
        fail "Config file not created at $config_file"
    fi
}

test_setup_gmail_detects_provider() {
    log_test "setup wizard shows 'Detected Gmail' for @gmail.com"

    local input="user@gmail.com\n\n\n\n\n"

    local output=$(printf "$input" | _doctor_email_setup 2>&1)
    local stripped=$(echo "$output" | strip_ansi)

    rm -f "$TEST_XDG/himalaya/config.toml"

    if echo "$stripped" | grep -q "Detected Gmail"; then
        pass
    else
        fail "Expected 'Detected Gmail' in output"
    fi
}

test_setup_gmail_uses_oauth2() {
    log_test "Gmail config uses oauth2 auth type"

    local input="user@gmail.com\n\n\n\n\n"

    printf "$input" | _doctor_email_setup >/dev/null 2>&1
    local config_file="$TEST_XDG/himalaya/config.toml"

    if [[ -f "$config_file" ]]; then
        if grep -q 'auth.type = "oauth2"' "$config_file"; then
            pass
        else
            fail "Expected oauth2 auth type in config"
        fi
        rm -f "$config_file"
    else
        fail "Config file not created"
    fi
}

test_setup_gmail_shows_oauth2_guidance() {
    log_test "Gmail setup shows OAuth2 proxy guidance"

    local input="user@gmail.com\n\n\n\n\n"

    local output=$(printf "$input" | _doctor_email_setup 2>&1)
    local stripped=$(echo "$output" | strip_ansi)

    rm -f "$TEST_XDG/himalaya/config.toml"

    if echo "$stripped" | grep -q "OAuth2 setup"; then
        pass
    else
        fail "Expected OAuth2 guidance section"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 5: _doctor_email_setup Custom Provider Wizard (2 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_setup_custom_provider_prompts_servers() {
    log_test "custom provider requires IMAP/SMTP server input"

    # Custom domain: no auto-detect, provide servers, choose auth method 2 (password)
    local input="user@mycorp.com\nmail.mycorp.com\n993\nsmtp.mycorp.com\n587\n2\n"

    local output=$(printf "$input" | _doctor_email_setup 2>&1)
    local stripped=$(echo "$output" | strip_ansi)
    local config_file="$TEST_XDG/himalaya/config.toml"

    if [[ -f "$config_file" ]]; then
        if grep -q 'host = "mail.mycorp.com"' "$config_file"; then
            pass
        else
            fail "Custom IMAP host not in config"
        fi
        rm -f "$config_file"
    else
        fail "Config file not created for custom provider"
    fi
}

test_setup_custom_provider_password_auth() {
    log_test "custom provider with password auth uses keychain command"

    local input="user@mycorp.com\nmail.mycorp.com\n993\nsmtp.mycorp.com\n587\n2\n"

    printf "$input" | _doctor_email_setup >/dev/null 2>&1
    local config_file="$TEST_XDG/himalaya/config.toml"

    if [[ -f "$config_file" ]]; then
        if grep -q 'auth.type = "password"' "$config_file" && \
           grep -q 'security find-generic-password' "$config_file"; then
            pass
        else
            fail "Expected password auth with keychain command"
        fi
        rm -f "$config_file"
    else
        fail "Config file not created"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 6: _doctor_email_setup Cancel/Edge Cases (3 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_setup_empty_email_cancels() {
    log_test "empty email input cancels setup wizard"

    local output=$(echo "" | _doctor_email_setup 2>&1)
    local stripped=$(echo "$output" | strip_ansi)

    if echo "$stripped" | grep -q "Cancelled"; then
        pass
    else
        fail "Expected 'Cancelled' message for empty email"
    fi
}

test_setup_empty_imap_fails() {
    log_test "empty IMAP server for custom domain fails with error"

    # Custom domain (no auto-detect), then empty IMAP = fail
    local input="user@unknown.org\n\n"

    local output=$(printf "$input" | _doctor_email_setup 2>&1)
    local stripped=$(echo "$output" | strip_ansi)

    if echo "$stripped" | grep -q "IMAP server required"; then
        pass
    else
        fail "Expected 'IMAP server required' error"
    fi
}

test_setup_existing_config_decline_overwrite() {
    log_test "declining overwrite of existing config keeps original"

    local config_dir="$TEST_XDG/himalaya"
    mkdir -p "$config_dir"
    echo "# original config" > "$config_dir/config.toml"

    # "n" to decline overwrite
    local output=$(echo "n" | _doctor_email_setup 2>&1)
    local stripped=$(echo "$output" | strip_ansi)

    local content=$(<"$config_dir/config.toml")

    if [[ "$content" == "# original config" ]]; then
        pass
    else
        fail "Original config was overwritten despite declining"
    fi

    rm -f "$config_dir/config.toml"
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 7: --fix -y End-to-End (2 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_fix_y_auto_selects_all() {
    log_test "--fix -y auto-selects 'all' categories (no menu prompt)"
    setopt local_options NULL_GLOB

    # Build PATH without email-oauth2-proxy and glow to trigger missing deps
    local modified_path=$(build_path_without "email-oauth2-proxy")

    em() { : }
    PATH="$modified_path"
    local output=$(doctor --fix -y 2>&1)
    PATH="$ORIGINAL_PATH"
    unfunction em 2>/dev/null

    local stripped=$(echo "$output" | strip_ansi)

    # Should NOT show "Select" menu prompt (auto-yes bypasses it)
    if echo "$stripped" | grep -q "Select \["; then
        fail "Menu prompt shown despite -y flag"
    else
        pass
    fi

    rm -rf "$modified_path"
}

test_fix_y_attempts_email_installs() {
    log_test "--fix -y attempts to install missing email deps"
    setopt local_options NULL_GLOB

    # Build PATH without email-oauth2-proxy (pip), use fake pip
    local modified_path=$(build_path_without "email-oauth2-proxy")

    em() { : }
    PATH="$modified_path"
    local output=$(doctor --fix -y 2>&1)
    PATH="$ORIGINAL_PATH"
    unfunction em 2>/dev/null

    local stripped=$(echo "$output" | strip_ansi)

    # Should show email fix activity
    if echo "$stripped" | grep -qi "email\|Fixing email\|Installing"; then
        pass
    else
        fail "Expected email fix activity in output"
    fi

    rm -rf "$modified_path"
}

# ══════════════════════════════════════════════════════════════════════════════
# RUN ALL TESTS
# ══════════════════════════════════════════════════════════════════════════════

main() {
    echo ""
    echo "╭─────────────────────────────────────────────────────────╮"
    echo "│  ${BOLD}Doctor Email — Interactive Headless Suite${NC}              │"
    echo "╰─────────────────────────────────────────────────────────╯"

    setup

    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}CATEGORY 1: _doctor_confirm Branching (4 tests)${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_confirm_yes
    test_confirm_no
    test_confirm_empty_defaults_yes
    test_confirm_NO_uppercase

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}CATEGORY 2: _doctor_select_fix_category Menu (5 tests)${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_menu_auto_yes_selects_all
    test_menu_single_category_auto_selects
    test_menu_no_issues_returns_2
    test_menu_cancel_with_0
    test_menu_select_email_category

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}CATEGORY 3: _doctor_fix_email Install Simulation (3 tests)${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_fix_email_calls_fake_brew
    test_fix_email_calls_fake_pip
    test_fix_email_confirm_no_skips_install

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}CATEGORY 4: Gmail Setup Wizard (4 tests)${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_setup_gmail_generates_config
    test_setup_gmail_detects_provider
    test_setup_gmail_uses_oauth2
    test_setup_gmail_shows_oauth2_guidance

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}CATEGORY 5: Custom Provider Wizard (2 tests)${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_setup_custom_provider_prompts_servers
    test_setup_custom_provider_password_auth

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}CATEGORY 6: Setup Cancel/Edge Cases (3 tests)${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_setup_empty_email_cancels
    test_setup_empty_imap_fails
    test_setup_existing_config_decline_overwrite

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}CATEGORY 7: --fix -y End-to-End (2 tests)${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    test_fix_y_auto_selects_all
    test_fix_y_attempts_email_installs

    # Summary
    echo ""
    echo "╭─────────────────────────────────────────────────────────╮"
    echo "│  ${BOLD}Interactive Headless Test Summary${NC}                      │"
    echo "╰─────────────────────────────────────────────────────────╯"
    echo ""
    echo "  ${GREEN}Passed:${NC} $TESTS_PASSED"
    echo "  ${RED}Failed:${NC} $TESTS_FAILED"
    echo "  ${CYAN}Total:${NC}  $((TESTS_PASSED + TESTS_FAILED))"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "${GREEN}✓ All interactive headless tests passed!${NC}"
        echo ""
        return 0
    else
        echo "${RED}✗ Some interactive tests failed${NC}"
        echo ""
        return 1
    fi
}

main "$@"
