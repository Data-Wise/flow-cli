#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE: Email Move and Restore
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: Validate _em_move and _em_restore functions
# Tests: arg validation, adapter calls, --from flag, --to flag, batch IDs, aliases
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
typeset -g _SAVED_REQUIRE_HML=""
typeset -g _SAVED_HML_MOVE=""

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
    _SAVED_REQUIRE_HML="$(whence -f _em_require_himalaya 2>/dev/null)"
    _SAVED_HML_MOVE="$(whence -f _em_hml_move 2>/dev/null)"

    # Always let _em_require_himalaya pass in tests
    _em_require_himalaya() { return 0; }
}

_restore_functions() {
    [[ -n "$_SAVED_REQUIRE_HML" ]] && eval "$_SAVED_REQUIRE_HML"
    [[ -n "$_SAVED_HML_MOVE" ]] && eval "$_SAVED_HML_MOVE"
}

cleanup() {
    reset_mocks
    _restore_functions
    unset FLOW_EMAIL_FOLDER 2>/dev/null
    unset FLOW_EMAIL_TRASH_FOLDER 2>/dev/null
}
trap cleanup EXIT

# ═══════════════════════════════════════════════════════════════
# Section 1: _em_move Argument Validation
# ═══════════════════════════════════════════════════════════════

test_move_requires_args() {
    test_case "_em_move with no args returns 1"
    local output rc
    output=$(_em_move 2>&1)
    rc=$?
    if [[ $rc -eq 1 ]]; then
        test_pass
    else
        test_fail "Expected exit code 1 when no args provided, got: $rc"
    fi
}

# ═══════════════════════════════════════════════════════════════
# Section 2: _em_move Adapter Calls
# ═══════════════════════════════════════════════════════════════

test_move_calls_adapter() {
    test_case "_em_move Archive 42 calls _em_hml_move with correct source/target/ID"

    typeset -g MOCK_HML_MOVE_CALLED=false
    typeset -g MOCK_HML_MOVE_ARGS=""
    _em_hml_move() {
        MOCK_HML_MOVE_CALLED=true
        MOCK_HML_MOVE_ARGS="$*"
        return 0
    }

    # Default source folder is FLOW_EMAIL_FOLDER (INBOX)
    FLOW_EMAIL_FOLDER="INBOX"
    _em_move Archive 42 &>/dev/null

    # Expect: _em_hml_move INBOX Archive 42
    if [[ "$MOCK_HML_MOVE_CALLED" == true && \
          "$MOCK_HML_MOVE_ARGS" == *"Archive"* && \
          "$MOCK_HML_MOVE_ARGS" == *"42"* ]]; then
        test_pass
    else
        test_fail "Expected _em_hml_move called with Archive and ID 42, got: '$MOCK_HML_MOVE_ARGS'"
    fi

    _restore_functions
    _em_require_himalaya() { return 0; }
}

test_move_batch() {
    test_case "_em_move Archive 10 20 30 passes all IDs to _em_hml_move"

    typeset -g MOCK_HML_MOVE_CALLED=false
    typeset -g MOCK_HML_MOVE_ARGS=""
    _em_hml_move() {
        MOCK_HML_MOVE_CALLED=true
        MOCK_HML_MOVE_ARGS="$*"
        return 0
    }

    FLOW_EMAIL_FOLDER="INBOX"
    _em_move Archive 10 20 30 &>/dev/null

    if [[ "$MOCK_HML_MOVE_CALLED" == true && \
          "$MOCK_HML_MOVE_ARGS" == *"10"* && \
          "$MOCK_HML_MOVE_ARGS" == *"20"* && \
          "$MOCK_HML_MOVE_ARGS" == *"30"* ]]; then
        test_pass
    else
        test_fail "Expected all IDs in _em_hml_move args, got: '$MOCK_HML_MOVE_ARGS'"
    fi

    _restore_functions
    _em_require_himalaya() { return 0; }
}

test_move_from_flag() {
    test_case "_em_move --from Sent Archive 42 uses Sent as source folder"

    typeset -g MOCK_HML_MOVE_CALLED=false
    typeset -g MOCK_HML_MOVE_ARGS=""
    _em_hml_move() {
        MOCK_HML_MOVE_CALLED=true
        MOCK_HML_MOVE_ARGS="$*"
        return 0
    }

    _em_move --from Sent Archive 42 &>/dev/null

    # First arg to _em_hml_move should be the source folder "Sent"
    if [[ "$MOCK_HML_MOVE_CALLED" == true && \
          "$MOCK_HML_MOVE_ARGS" == "Sent"* && \
          "$MOCK_HML_MOVE_ARGS" == *"Archive"* && \
          "$MOCK_HML_MOVE_ARGS" == *"42"* ]]; then
        test_pass
    else
        test_fail "Expected source=Sent in _em_hml_move args, got: '$MOCK_HML_MOVE_ARGS'"
    fi

    _restore_functions
    _em_require_himalaya() { return 0; }
}

# ═══════════════════════════════════════════════════════════════
# Section 3: _em_restore Behaviour
# ═══════════════════════════════════════════════════════════════

test_restore_defaults_inbox() {
    test_case "_em_restore 42 moves from Trash to INBOX by default"

    typeset -g MOCK_HML_MOVE_CALLED=false
    typeset -g MOCK_HML_MOVE_ARGS=""
    _em_hml_move() {
        MOCK_HML_MOVE_CALLED=true
        MOCK_HML_MOVE_ARGS="$*"
        return 0
    }

    FLOW_EMAIL_TRASH_FOLDER="Trash"
    _em_restore 42 &>/dev/null

    # Expect: _em_hml_move Trash INBOX 42
    if [[ "$MOCK_HML_MOVE_CALLED" == true && \
          "$MOCK_HML_MOVE_ARGS" == "Trash INBOX"* && \
          "$MOCK_HML_MOVE_ARGS" == *"42"* ]]; then
        test_pass
    else
        test_fail "Expected _em_hml_move Trash INBOX 42, got: '$MOCK_HML_MOVE_ARGS'"
    fi

    _restore_functions
    _em_require_himalaya() { return 0; }
}

test_restore_to_flag() {
    test_case "_em_restore 42 --to Archive moves from Trash to Archive"

    typeset -g MOCK_HML_MOVE_CALLED=false
    typeset -g MOCK_HML_MOVE_ARGS=""
    _em_hml_move() {
        MOCK_HML_MOVE_CALLED=true
        MOCK_HML_MOVE_ARGS="$*"
        return 0
    }

    FLOW_EMAIL_TRASH_FOLDER="Trash"
    _em_restore 42 --to Archive &>/dev/null

    # Expect: _em_hml_move Trash Archive 42
    if [[ "$MOCK_HML_MOVE_CALLED" == true && \
          "$MOCK_HML_MOVE_ARGS" == "Trash Archive"* && \
          "$MOCK_HML_MOVE_ARGS" == *"42"* ]]; then
        test_pass
    else
        test_fail "Expected _em_hml_move Trash Archive 42, got: '$MOCK_HML_MOVE_ARGS'"
    fi

    _restore_functions
    _em_require_himalaya() { return 0; }
}

test_restore_batch() {
    test_case "_em_restore 10 20 30 passes all IDs to _em_hml_move"

    typeset -g MOCK_HML_MOVE_CALLED=false
    typeset -g MOCK_HML_MOVE_ARGS=""
    _em_hml_move() {
        MOCK_HML_MOVE_CALLED=true
        MOCK_HML_MOVE_ARGS="$*"
        return 0
    }

    FLOW_EMAIL_TRASH_FOLDER="Trash"
    _em_restore 10 20 30 &>/dev/null

    if [[ "$MOCK_HML_MOVE_CALLED" == true && \
          "$MOCK_HML_MOVE_ARGS" == *"10"* && \
          "$MOCK_HML_MOVE_ARGS" == *"20"* && \
          "$MOCK_HML_MOVE_ARGS" == *"30"* ]]; then
        test_pass
    else
        test_fail "Expected all IDs in _em_hml_move args, got: '$MOCK_HML_MOVE_ARGS'"
    fi

    _restore_functions
    _em_require_himalaya() { return 0; }
}

# ═══════════════════════════════════════════════════════════════
# Section 4: Aliases
# ═══════════════════════════════════════════════════════════════

test_move_aliases() {
    test_case "'em mv' routes to _em_move via the em() case statement"

    typeset -g MOCK_EM_MOVE_CALL_COUNT=0
    _em_move() { (( MOCK_EM_MOVE_CALL_COUNT++ )); return 0; }

    em mv Archive 99 &>/dev/null

    if [[ "$MOCK_EM_MOVE_CALL_COUNT" -eq 1 ]]; then
        test_pass
    else
        test_fail "Expected _em_move called once via 'em mv', got: $MOCK_EM_MOVE_CALL_COUNT"
    fi

    _restore_functions
    _em_require_himalaya() { return 0; }
}

# ═══════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════

main() {
    test_suite_start "Email Move and Restore (_em_move / _em_restore)"

    setup

    echo "${CYAN}Section 1: _em_move Argument Validation${RESET}"
    test_move_requires_args
    echo ""

    echo "${CYAN}Section 2: _em_move Adapter Calls${RESET}"
    test_move_calls_adapter
    test_move_batch
    test_move_from_flag
    echo ""

    echo "${CYAN}Section 3: _em_restore Behaviour${RESET}"
    test_restore_defaults_inbox
    test_restore_to_flag
    test_restore_batch
    echo ""

    echo "${CYAN}Section 4: Aliases${RESET}"
    test_move_aliases
    echo ""

    cleanup
    test_suite_end
    exit $?
}

# Run tests
main
