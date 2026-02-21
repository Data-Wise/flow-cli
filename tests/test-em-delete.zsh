#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE: Email Delete
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: Validate _em_delete function (single, batch, folder, query, purge)
# Tests: arg validation, adapter calls, confirmation flow, purge safety, aliases
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
typeset -g _SAVED_HML_DELETE=""
typeset -g _SAVED_HML_LIST=""
typeset -g _SAVED_HML_SEARCH=""
typeset -g _SAVED_HML_FLAGS=""
typeset -g _SAVED_HML_EXPUNGE=""

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
    exec < /dev/null  # Non-interactive — all `read` prompts see EOF, defaulting to empty (NO)
    source "$project_root/flow.plugin.zsh"

    # Save originals for restoration
    _SAVED_REQUIRE_HML="$(whence -f _em_require_himalaya 2>/dev/null)"
    _SAVED_HML_DELETE="$(whence -f _em_hml_delete 2>/dev/null)"
    _SAVED_HML_LIST="$(whence -f _em_hml_list 2>/dev/null)"
    _SAVED_HML_SEARCH="$(whence -f _em_hml_search 2>/dev/null)"
    _SAVED_HML_FLAGS="$(whence -f _em_hml_flags 2>/dev/null)"
    _SAVED_HML_EXPUNGE="$(whence -f _em_hml_expunge 2>/dev/null)"

    # Always let _em_require_himalaya pass in tests
    _em_require_himalaya() { return 0; }
}

_restore_functions() {
    [[ -n "$_SAVED_REQUIRE_HML" ]] && eval "$_SAVED_REQUIRE_HML"
    [[ -n "$_SAVED_HML_DELETE" ]] && eval "$_SAVED_HML_DELETE"
    [[ -n "$_SAVED_HML_LIST" ]] && eval "$_SAVED_HML_LIST"
    [[ -n "$_SAVED_HML_SEARCH" ]] && eval "$_SAVED_HML_SEARCH"
    [[ -n "$_SAVED_HML_FLAGS" ]] && eval "$_SAVED_HML_FLAGS"
    [[ -n "$_SAVED_HML_EXPUNGE" ]] && eval "$_SAVED_HML_EXPUNGE"
}

cleanup() {
    reset_mocks
    _restore_functions
    unset FLOW_EMAIL_FOLDER 2>/dev/null
    unset FLOW_EMAIL_TRASH_FOLDER 2>/dev/null
}
trap cleanup EXIT

# ═══════════════════════════════════════════════════════════════
# Section 1: Argument Validation
# ═══════════════════════════════════════════════════════════════

test_delete_requires_id() {
    test_case "_em_delete with no args returns 1"
    local output rc
    output=$(_em_delete 2>&1)
    rc=$?
    if [[ $rc -eq 1 ]]; then
        test_pass
    else
        test_fail "Expected exit code 1 when no args provided, got: $rc"
    fi
}

# ═══════════════════════════════════════════════════════════════
# Section 2: Single and Batch Delete by ID
# ═══════════════════════════════════════════════════════════════

test_delete_single() {
    test_case "_em_delete <ID> calls _em_hml_delete with the ID"

    typeset -g MOCK_HML_DELETE_CALLED=false
    typeset -g MOCK_HML_DELETE_ARGS=""
    _em_hml_delete() {
        MOCK_HML_DELETE_CALLED=true
        MOCK_HML_DELETE_ARGS="$*"
        return 0
    }

    # Pipe "y" to satisfy the [y/N] confirmation prompt
    echo "y" | _em_delete 42 &>/dev/null

    if [[ "$MOCK_HML_DELETE_CALLED" == true && "$MOCK_HML_DELETE_ARGS" == *"42"* ]]; then
        test_pass
    else
        test_fail "Expected _em_hml_delete called with ID 42, called=$MOCK_HML_DELETE_CALLED args='$MOCK_HML_DELETE_ARGS'"
    fi

    _restore_functions
    _em_require_himalaya() { return 0; }
}

test_delete_batch() {
    test_case "_em_delete <ID1> <ID2> <ID3> passes all IDs to _em_hml_delete"

    typeset -g MOCK_HML_DELETE_CALLED=false
    typeset -g MOCK_HML_DELETE_ARGS=""
    _em_hml_delete() {
        MOCK_HML_DELETE_CALLED=true
        MOCK_HML_DELETE_ARGS="$*"
        return 0
    }

    echo "y" | _em_delete 10 20 30 &>/dev/null

    if [[ "$MOCK_HML_DELETE_CALLED" == true && \
          "$MOCK_HML_DELETE_ARGS" == *"10"* && \
          "$MOCK_HML_DELETE_ARGS" == *"20"* && \
          "$MOCK_HML_DELETE_ARGS" == *"30"* ]]; then
        test_pass
    else
        test_fail "Expected all IDs in _em_hml_delete args, got: '$MOCK_HML_DELETE_ARGS'"
    fi

    _restore_functions
    _em_require_himalaya() { return 0; }
}

# ═══════════════════════════════════════════════════════════════
# Section 3: Folder Delete (Confirm / Decline)
# ═══════════════════════════════════════════════════════════════

test_delete_folder_confirm() {
    test_case "_em_delete --folder Spam fetches emails and shows subjects in prompt"

    # _em_hml_list runs inside a command substitution (subshell), so we use a
    # temp file to record the call — typeset -g flags set in subshells do not
    # propagate back to the parent shell.
    local _list_call_file
    _list_call_file=$(mktemp)
    _em_hml_list() {
        echo "called" > "$_list_call_file"
        echo '[{"id":"1","subject":"Spam email A"},{"id":"2","subject":"Spam email B"}]'
    }
    typeset -g MOCK_HML_DELETE_CALLED=false
    _em_hml_delete() { MOCK_HML_DELETE_CALLED=true; return 0; }

    # Non-interactive (exec < /dev/null) — read gets EOF, response="", defaults to NO
    local output
    output=$(_em_delete --folder Spam 2>&1)
    local list_was_called
    list_was_called=$(cat "$_list_call_file" 2>/dev/null)
    rm -f "$_list_call_file"

    if [[ "$list_was_called" == "called" && "$output" == *"Spam email A"* ]]; then
        test_pass
    else
        test_fail "Expected _em_hml_list called and subjects shown. called='$list_was_called' output='$output'"
    fi

    _restore_functions
    _em_require_himalaya() { return 0; }
}

test_delete_folder_decline() {
    test_case "_em_delete --folder with default NO does not call _em_hml_delete"

    _em_hml_list() {
        echo '[{"id":"1","subject":"Spam email A"},{"id":"2","subject":"Spam email B"}]'
    }
    typeset -g MOCK_HML_DELETE_CALLED=false
    _em_hml_delete() { MOCK_HML_DELETE_CALLED=true; return 0; }

    # Non-interactive EOF → read gets "" → does not match [Yy] → decline
    _em_delete --folder Spam &>/dev/null

    if [[ "$MOCK_HML_DELETE_CALLED" == false ]]; then
        test_pass
    else
        test_fail "_em_hml_delete was called despite default NO confirmation"
    fi

    _restore_functions
    _em_require_himalaya() { return 0; }
}

# ═══════════════════════════════════════════════════════════════
# Section 4: Query Delete (Confirm / Decline)
# ═══════════════════════════════════════════════════════════════

test_delete_query_confirm() {
    test_case "_em_delete --query calls _em_hml_search and shows subjects in prompt"

    # Same subshell propagation issue as --folder: use a temp file to detect
    # whether _em_hml_search was invoked from inside the command substitution.
    local _search_call_file
    _search_call_file=$(mktemp)
    _em_hml_search() {
        echo "called" > "$_search_call_file"
        echo '[{"id":"5","subject":"Newsletter #1"},{"id":"6","subject":"Newsletter #2"}]'
    }
    typeset -g MOCK_HML_DELETE_CALLED=false
    _em_hml_delete() { MOCK_HML_DELETE_CALLED=true; return 0; }

    # Non-interactive EOF — search fires, confirmation defaults to NO
    local output
    output=$(_em_delete --query "newsletter" 2>&1)
    local search_was_called
    search_was_called=$(cat "$_search_call_file" 2>/dev/null)
    rm -f "$_search_call_file"

    if [[ "$search_was_called" == "called" && "$output" == *"Newsletter"* ]]; then
        test_pass
    else
        test_fail "Expected _em_hml_search called and subjects shown. called='$search_was_called' output='$output'"
    fi

    _restore_functions
    _em_require_himalaya() { return 0; }
}

test_delete_query_decline() {
    test_case "_em_delete --query with default NO does not delete"

    _em_hml_search() {
        echo '[{"id":"5","subject":"Newsletter #1"},{"id":"6","subject":"Newsletter #2"}]'
    }
    typeset -g MOCK_HML_DELETE_CALLED=false
    _em_hml_delete() { MOCK_HML_DELETE_CALLED=true; return 0; }

    # Non-interactive EOF → decline by default
    _em_delete --query "newsletter" &>/dev/null

    if [[ "$MOCK_HML_DELETE_CALLED" == false ]]; then
        test_pass
    else
        test_fail "_em_hml_delete was called despite default NO confirmation for --query"
    fi

    _restore_functions
    _em_require_himalaya() { return 0; }
}

# ═══════════════════════════════════════════════════════════════
# Section 5: Purge Mode
# ═══════════════════════════════════════════════════════════════

test_delete_purge_requires_yes() {
    test_case "_em_delete --purge <ID> with 'y' input does NOT purge (requires full 'yes')"

    typeset -g MOCK_HML_EXPUNGE_CALLED=false
    _em_hml_expunge() { MOCK_HML_EXPUNGE_CALLED=true; return 0; }
    typeset -g MOCK_HML_FLAGS_CALLED=false
    _em_hml_flags() { MOCK_HML_FLAGS_CALLED=true; return 0; }

    # "y" is NOT enough — purge requires the literal string "yes"
    echo "y" | _em_delete --purge 42 &>/dev/null

    if [[ "$MOCK_HML_EXPUNGE_CALLED" == false ]]; then
        test_pass
    else
        test_fail "_em_hml_expunge was called even though only 'y' was provided (requires 'yes')"
    fi

    _restore_functions
    _em_require_himalaya() { return 0; }
}

test_delete_purge_full_yes() {
    test_case "_em_delete --purge <ID> with 'yes' triggers _em_hml_flags + _em_hml_expunge"

    typeset -g MOCK_HML_FLAGS_CALLED=false
    typeset -g MOCK_HML_FLAGS_ARGS=""
    _em_hml_flags() {
        MOCK_HML_FLAGS_CALLED=true
        MOCK_HML_FLAGS_ARGS="$*"
        return 0
    }
    typeset -g MOCK_HML_EXPUNGE_CALLED=false
    _em_hml_expunge() { MOCK_HML_EXPUNGE_CALLED=true; return 0; }

    echo "yes" | _em_delete --purge 42 &>/dev/null

    if [[ "$MOCK_HML_FLAGS_CALLED" == true && "$MOCK_HML_EXPUNGE_CALLED" == true ]]; then
        test_pass
    else
        test_fail "Expected both _em_hml_flags and _em_hml_expunge called. flags=$MOCK_HML_FLAGS_CALLED expunge=$MOCK_HML_EXPUNGE_CALLED"
    fi

    _restore_functions
    _em_require_himalaya() { return 0; }
}

test_delete_purge_folder() {
    test_case "_em_delete --folder Trash --purge triggers _em_hml_expunge after 'y' then 'yes'"

    # The active _em_delete implementation for --folder --purge requires two
    # separate reads: first a [y/N] from _em_delete_confirm, then "yes" from
    # _em_purge_confirm. We pipe both answers in sequence.
    _em_hml_list() {
        echo '[{"id":"1","subject":"Old email A"},{"id":"2","subject":"Old email B"}]'
    }
    _em_hml_flags() { return 0; }

    # _em_hml_expunge runs in the parent shell (not in a command substitution),
    # so MOCK_HML_EXPUNGE_CALLED propagates back correctly here.
    typeset -g MOCK_HML_EXPUNGE_CALLED=false
    _em_hml_expunge() { MOCK_HML_EXPUNGE_CALLED=true; return 0; }

    # Feed: "y" for the first [y/N] confirm, then "yes" for the purge confirm
    printf "y\nyes\n" | _em_delete --folder Trash --purge &>/dev/null

    if [[ "$MOCK_HML_EXPUNGE_CALLED" == true ]]; then
        test_pass
    else
        test_fail "_em_hml_expunge was not called — check two-step confirmation flow for --folder --purge"
    fi

    _restore_functions
    _em_require_himalaya() { return 0; }
}

# ═══════════════════════════════════════════════════════════════
# Section 6: Pick Mode (fzf)
# ═══════════════════════════════════════════════════════════════

test_delete_pick_requires_fzf() {
    test_case "_em_delete --pick returns error when fzf is not available"

    # Temporarily shadow fzf with a function that is not found
    local orig_path="$PATH"
    # Override command lookup for fzf by defining a function that returns non-zero
    # We use a subshell with a PATH that excludes fzf
    local output rc
    output=$(
        # Remove fzf from PATH for this subshell
        export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v fzf | tr '\n' ':' | sed 's/:$//')
        # Reload just enough to get _em_delete available
        FLOW_QUIET=1 FLOW_ATLAS_ENABLED=no source "$project_root/flow.plugin.zsh" 2>/dev/null
        _em_require_himalaya() { return 0; }
        _em_delete --pick 2>&1
    )
    rc=$?

    if [[ $rc -eq 1 || "$output" == *"fzf"* || "$output" == *"required"* ]]; then
        test_pass
    else
        test_fail "Expected fzf-not-found error for --pick mode, got rc=$rc output='$output'"
    fi
}

# ═══════════════════════════════════════════════════════════════
# Section 7: Aliases
# ═══════════════════════════════════════════════════════════════

test_delete_aliases() {
    test_case "'em del' and 'em rm' route to _em_delete via the em() case statement"

    # Verify the dispatcher case statement handles both aliases.
    # We intercept _em_delete to confirm it is invoked.
    typeset -g MOCK_EM_DELETE_CALL_COUNT=0
    _em_delete() { (( MOCK_EM_DELETE_CALL_COUNT++ )); return 0; }

    em del 99 &>/dev/null
    em rm 99 &>/dev/null

    if [[ "$MOCK_EM_DELETE_CALL_COUNT" -eq 2 ]]; then
        test_pass
    else
        test_fail "Expected _em_delete called twice (del + rm), got: $MOCK_EM_DELETE_CALL_COUNT"
    fi

    _restore_functions
    _em_require_himalaya() { return 0; }
}

# ═══════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════

main() {
    test_suite_start "Email Delete (_em_delete)"

    setup

    echo "${CYAN}Section 1: Argument Validation${RESET}"
    test_delete_requires_id
    echo ""

    echo "${CYAN}Section 2: Single and Batch Delete by ID${RESET}"
    test_delete_single
    test_delete_batch
    echo ""

    echo "${CYAN}Section 3: Folder Delete (Confirm / Decline)${RESET}"
    test_delete_folder_confirm
    test_delete_folder_decline
    echo ""

    echo "${CYAN}Section 4: Query Delete (Confirm / Decline)${RESET}"
    test_delete_query_confirm
    test_delete_query_decline
    echo ""

    echo "${CYAN}Section 5: Purge Mode${RESET}"
    test_delete_purge_requires_yes
    test_delete_purge_full_yes
    test_delete_purge_folder
    echo ""

    echo "${CYAN}Section 6: Pick Mode (fzf)${RESET}"
    test_delete_pick_requires_fzf
    echo ""

    echo "${CYAN}Section 7: Aliases${RESET}"
    test_delete_aliases
    echo ""

    cleanup
    test_suite_end
    exit $?
}

# Run tests
main
