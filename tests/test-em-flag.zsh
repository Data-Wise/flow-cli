#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE: Email Flag & Unflag (star management)
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: Validate _em_flag and _em_unflag functions (himalaya flag adapter)
# Tests: arg validation, flag add/remove, batch IDs, dispatcher alias routing
#
# Created: 2026-02-20
# ══════════════════════════════════════════════════════════════════════════════

# Source shared test framework
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

# ══════════════════════════════════════════════════════════════════════════════
# SETUP / CLEANUP
# ══════════════════════════════════════════════════════════════════════════════

# Save original function bodies for restoration
typeset -g _SAVED_HML_FLAGS=""
typeset -g _SAVED_REQUIRE_HML=""

# Capture args passed to mock _em_hml_flags
typeset -g MOCK_HML_FLAGS_ARGS=""

setup() {
    typeset -g project_root=""
    if [[ -n "${0:A}" ]]; then project_root="${0:A:h:h}"; fi
    if [[ -z "$project_root" || ! -f "$project_root/flow.plugin.zsh" ]]; then
        if [[ -f "$PWD/flow.plugin.zsh" ]]; then project_root="$PWD"
        elif [[ -f "$PWD/../flow.plugin.zsh" ]]; then project_root="$PWD/.."
        fi
    fi
    [[ -z "$project_root" || ! -f "$project_root/flow.plugin.zsh" ]] && { echo "ERROR: Cannot find project root"; exit 1; }

    FLOW_QUIET=1
    FLOW_ATLAS_ENABLED=no
    FLOW_PLUGIN_DIR="$project_root"
    exec < /dev/null  # Non-interactive
    source "$project_root/flow.plugin.zsh"

    # Save originals for restoration
    _SAVED_HML_FLAGS="$(whence -f _em_hml_flags 2>/dev/null)"
    _SAVED_REQUIRE_HML="$(whence -f _em_require_himalaya 2>/dev/null)"

    # Always let _em_require_himalaya pass in tests
    _em_require_himalaya() { return 0; }
}

_restore_functions() {
    [[ -n "$_SAVED_HML_FLAGS" ]] && eval "$_SAVED_HML_FLAGS"
    [[ -n "$_SAVED_REQUIRE_HML" ]] && eval "$_SAVED_REQUIRE_HML"
}

cleanup() {
    reset_mocks
    _restore_functions
    MOCK_HML_FLAGS_ARGS=""
}
trap cleanup EXIT

# ═══════════════════════════════════════════════════════════════
# Section 1: _em_flag Requires ID
# ═══════════════════════════════════════════════════════════════

test_flag_requires_id() {
    test_case "_em_flag with no args returns 1"
    local output
    output=$(_em_flag 2>&1)
    if [[ $? -eq 1 ]]; then
        test_pass
    else
        test_fail "Expected exit code 1 when no ID provided"
    fi
}

# ═══════════════════════════════════════════════════════════════
# Section 2: _em_flag Adds Flagged
# ═══════════════════════════════════════════════════════════════

test_flag_adds_flagged() {
    test_case "_em_flag calls _em_hml_flags with 'add <ID> Flagged'"

    # Use a temp file to capture args across subshell boundary
    typeset -g _FLAG_TEST_TMPFILE=$(mktemp)
    _em_hml_flags() {
        echo "$*" >> "$_FLAG_TEST_TMPFILE"
        return 0
    }

    _em_flag "42" &>/dev/null

    local captured_args=""
    [[ -f "$_FLAG_TEST_TMPFILE" ]] && captured_args=$(cat "$_FLAG_TEST_TMPFILE")
    rm -f "$_FLAG_TEST_TMPFILE" 2>/dev/null

    if [[ "$captured_args" == *"add 42 Flagged"* ]]; then
        test_pass
    else
        test_fail "Expected _em_hml_flags called with 'add 42 Flagged', got: '$captured_args'"
    fi

    _restore_functions
    _em_require_himalaya() { return 0; }
}

# ═══════════════════════════════════════════════════════════════
# Section 3: _em_flag Batch Processing
# ═══════════════════════════════════════════════════════════════

test_flag_batch() {
    test_case "_em_flag with multiple IDs flags each one"

    typeset -g _FLAG_BATCH_TMPFILE=$(mktemp)
    _em_hml_flags() {
        echo "$*" >> "$_FLAG_BATCH_TMPFILE"
        return 0
    }

    _em_flag "42" "43" &>/dev/null

    local captured_args=""
    [[ -f "$_FLAG_BATCH_TMPFILE" ]] && captured_args=$(cat "$_FLAG_BATCH_TMPFILE")
    rm -f "$_FLAG_BATCH_TMPFILE" 2>/dev/null

    if [[ "$captured_args" == *"add 42 Flagged"* && "$captured_args" == *"add 43 Flagged"* ]]; then
        test_pass
    else
        test_fail "Expected both IDs 42 and 43 flagged, got: '$captured_args'"
    fi

    _restore_functions
    _em_require_himalaya() { return 0; }
}

# ═══════════════════════════════════════════════════════════════
# Section 4: _em_unflag Removes Flagged
# ═══════════════════════════════════════════════════════════════

test_unflag_removes_flagged() {
    test_case "_em_unflag calls _em_hml_flags with 'remove <ID> Flagged'"

    typeset -g _UNFLAG_TEST_TMPFILE=$(mktemp)
    _em_hml_flags() {
        echo "$*" >> "$_UNFLAG_TEST_TMPFILE"
        return 0
    }

    _em_unflag "42" &>/dev/null

    local captured_args=""
    [[ -f "$_UNFLAG_TEST_TMPFILE" ]] && captured_args=$(cat "$_UNFLAG_TEST_TMPFILE")
    rm -f "$_UNFLAG_TEST_TMPFILE" 2>/dev/null

    if [[ "$captured_args" == *"remove 42 Flagged"* ]]; then
        test_pass
    else
        test_fail "Expected _em_hml_flags called with 'remove 42 Flagged', got: '$captured_args'"
    fi

    _restore_functions
    _em_require_himalaya() { return 0; }
}

# ═══════════════════════════════════════════════════════════════
# Section 5: _em_unflag Batch Processing
# ═══════════════════════════════════════════════════════════════

test_unflag_batch() {
    test_case "_em_unflag with multiple IDs removes flag from each one"

    typeset -g _UNFLAG_BATCH_TMPFILE=$(mktemp)
    _em_hml_flags() {
        echo "$*" >> "$_UNFLAG_BATCH_TMPFILE"
        return 0
    }

    _em_unflag "55" "66" &>/dev/null

    local captured_args=""
    [[ -f "$_UNFLAG_BATCH_TMPFILE" ]] && captured_args=$(cat "$_UNFLAG_BATCH_TMPFILE")
    rm -f "$_UNFLAG_BATCH_TMPFILE" 2>/dev/null

    if [[ "$captured_args" == *"remove 55 Flagged"* && "$captured_args" == *"remove 66 Flagged"* ]]; then
        test_pass
    else
        test_fail "Expected both IDs 55 and 66 unflagged, got: '$captured_args'"
    fi

    _restore_functions
    _em_require_himalaya() { return 0; }
}

# ═══════════════════════════════════════════════════════════════
# Section 6: Dispatcher Alias Routing
# ═══════════════════════════════════════════════════════════════

test_flag_aliases() {
    test_case "'em fl <ID>' routes to _em_flag"

    typeset -g _FLAG_ALIAS_TMPFILE=$(mktemp)
    _em_hml_flags() {
        echo "$*" >> "$_FLAG_ALIAS_TMPFILE"
        return 0
    }

    em fl "42" &>/dev/null

    local captured_args=""
    [[ -f "$_FLAG_ALIAS_TMPFILE" ]] && captured_args=$(cat "$_FLAG_ALIAS_TMPFILE")
    rm -f "$_FLAG_ALIAS_TMPFILE" 2>/dev/null

    if [[ "$captured_args" == *"add 42 Flagged"* ]]; then
        test_pass
    else
        test_fail "Expected 'em fl 42' to route to _em_flag with 'add 42 Flagged', got: '$captured_args'"
    fi

    _restore_functions
    _em_require_himalaya() { return 0; }
}

# ═══════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════

main() {
    test_suite_start "Email Flag & Unflag (star management)"

    setup

    echo "${CYAN}Section 1: _em_flag Requires ID${RESET}"
    test_flag_requires_id
    echo ""

    echo "${CYAN}Section 2: _em_flag Adds Flagged${RESET}"
    test_flag_adds_flagged
    echo ""

    echo "${CYAN}Section 3: _em_flag Batch Processing${RESET}"
    test_flag_batch
    echo ""

    echo "${CYAN}Section 4: _em_unflag Removes Flagged${RESET}"
    test_unflag_removes_flagged
    echo ""

    echo "${CYAN}Section 5: _em_unflag Batch Processing${RESET}"
    test_unflag_batch
    echo ""

    echo "${CYAN}Section 6: Dispatcher Alias Routing${RESET}"
    test_flag_aliases
    echo ""

    cleanup
    test_suite_end
    exit $?
}

# Run tests
main
