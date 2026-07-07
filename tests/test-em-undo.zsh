#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE: em undo + recent-folders (Phase 3, SPEC-em-ux-refactor-2026-07-07.md)
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: Validate the single-step undo cache (_em_undo_record/get/clear),
#          _em_undo's reversal logic per action type, and the recent-folders
#          quick-list (_em_recent_folders_add/get) used by `em move --recent`.
#
# Isolation: _em_cache_dir is mocked to a mktemp directory so these tests never
# touch the real ~/.flow or project-local .flow/email-cache.
#
# Created: 2026-07-07
# ══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

typeset -g TEST_CACHE_DIR=""

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
    exec < /dev/null
    source "$project_root/flow.plugin.zsh"

    TEST_CACHE_DIR=$(mktemp -d)
    _em_cache_dir() { echo "$TEST_CACHE_DIR"; }
    _em_require_himalaya() { return 0; }
}

cleanup() {
    reset_mocks
    [[ -n "$TEST_CACHE_DIR" && -d "$TEST_CACHE_DIR" ]] && rm -rf "$TEST_CACHE_DIR"
}
trap cleanup EXIT

# ═══════════════════════════════════════════════════════════════
# Section 1: Undo-state cache round trip
# ═══════════════════════════════════════════════════════════════

test_undo_record_get_roundtrip() {
    test_case "_em_undo_record then _em_undo_get returns the same payload"
    _em_undo_record "star" "42 43"
    local got
    got=$(_em_undo_get)
    if [[ "$got" == "star|42 43" ]]; then test_pass; else test_fail "got: '$got'"; fi
}

test_undo_record_overwrites_no_stack() {
    test_case "second _em_undo_record overwrites the first (single-step, no stack)"
    _em_undo_record "flag" "1"
    _em_undo_record "unflag" "2"
    local got
    got=$(_em_undo_get)
    if [[ "$got" == "unflag|2" ]]; then test_pass; else test_fail "got: '$got'"; fi
}

test_undo_clear_empties_state() {
    test_case "_em_undo_clear removes the recorded state"
    _em_undo_record "star" "1"
    _em_undo_clear
    local got
    got=$(_em_undo_get)
    if [[ -z "$got" ]]; then test_pass; else test_fail "expected empty, got: '$got'"; fi
}

# ═══════════════════════════════════════════════════════════════
# Section 2: _em_undo with nothing recorded
# ═══════════════════════════════════════════════════════════════

test_undo_nothing_to_undo() {
    test_case "_em_undo with no recorded state returns 1"
    local output
    output=$(_em_undo 2>&1)
    local rc=$?
    if [[ $rc -eq 1 ]]; then test_pass; else test_fail "expected rc=1, got rc=$rc, output: $output"; fi
}

# ═══════════════════════════════════════════════════════════════
# Section 3: _em_undo reversal per action type
# ═══════════════════════════════════════════════════════════════

test_undo_star_retoggles_same_ids() {
    test_case "_em_undo of a star action re-calls _em_star with the same ids"
    create_mock "_em_star"
    _em_undo_record "star" "42 43"
    _em_undo &>/dev/null
    assert_mock_called "_em_star" 1 && assert_mock_args "_em_star" "42 43" && test_pass
    reset_mocks
}

test_undo_flag_unflags_same_ids() {
    test_case "_em_undo of a flag action unflags the same ids via _em_hml_flags"
    create_mock "_em_hml_flags"
    _em_undo_record "flag" "10 20"
    _em_undo &>/dev/null
    assert_mock_called "_em_hml_flags" 2 && test_pass
    reset_mocks
}

test_undo_unflag_flags_same_ids() {
    test_case "_em_undo of an unflag action re-flags the same ids via _em_hml_flags"
    create_mock "_em_hml_flags"
    _em_undo_record "unflag" "10 20"
    _em_undo &>/dev/null
    assert_mock_called "_em_hml_flags" 2 && test_pass
    reset_mocks
}

test_undo_move_swaps_src_dst() {
    test_case "_em_undo of a move action calls _em_hml_move with src/dst swapped"
    create_mock "_em_hml_move" 'return 0'
    _em_undo_record "move" "INBOX" "Archive" "42 43"
    _em_undo &>/dev/null
    assert_mock_called "_em_hml_move" 1 && assert_mock_args "_em_hml_move" "Archive INBOX 42 43" && test_pass
    reset_mocks
}

test_undo_clears_state_after_running() {
    test_case "_em_undo clears the recorded state after a successful undo (one-step only)"
    create_mock "_em_star"
    _em_undo_record "star" "1"
    _em_undo &>/dev/null
    local got
    got=$(_em_undo_get)
    if [[ -z "$got" ]]; then test_pass; else test_fail "expected state cleared, got: '$got'"; fi
}

test_undo_move_failure_does_not_clear_state() {
    test_case "_em_undo of a move that fails does NOT clear state (nothing to retry-undo)"
    create_mock "_em_hml_move" 'return 1'
    _em_undo_record "move" "INBOX" "Archive" "42"
    _em_undo &>/dev/null
    local got
    got=$(_em_undo_get)
    if [[ "$got" == "move|INBOX|Archive|42" ]]; then test_pass; else test_fail "expected state preserved, got: '$got'"; fi
}

# ═══════════════════════════════════════════════════════════════
# Section 4: Recent folders quick-list
# ═══════════════════════════════════════════════════════════════

test_recent_folders_add_get_roundtrip() {
    test_case "_em_recent_folders_add then _em_recent_folders_get returns it"
    _em_recent_folders_add "Archive"
    local got
    got=$(_em_recent_folders_get)
    if [[ "$got" == "Archive" ]]; then test_pass; else test_fail "got: '$got'"; fi
}

test_recent_folders_most_recent_first() {
    test_case "_em_recent_folders_add puts the newest folder first"
    _em_recent_folders_add "Archive"
    _em_recent_folders_add "Projects"
    local got
    got=$(_em_recent_folders_get)
    local -a arr
    arr=("${(@f)got}")
    if [[ "${arr[1]}" == "Projects" && "${arr[2]}" == "Archive" ]]; then
        test_pass
    else
        test_fail "got: ${arr[*]}"
    fi
}

test_recent_folders_dedup() {
    test_case "_em_recent_folders_add dedups a repeated folder instead of listing it twice"
    _em_recent_folders_add "Archive"
    _em_recent_folders_add "Projects"
    _em_recent_folders_add "Archive"
    local got
    got=$(_em_recent_folders_get)
    local -a arr
    arr=("${(@f)got}")
    if [[ ${#arr[@]} -eq 2 && "${arr[1]}" == "Archive" && "${arr[2]}" == "Projects" ]]; then
        test_pass
    else
        test_fail "got: ${arr[*]}"
    fi
}

test_recent_folders_capped_at_3() {
    test_case "_em_recent_folders_add caps the list at 3 entries"
    _em_recent_folders_add "A"
    _em_recent_folders_add "B"
    _em_recent_folders_add "C"
    _em_recent_folders_add "D"
    local got
    got=$(_em_recent_folders_get)
    local -a arr
    arr=("${(@f)got}")
    if [[ ${#arr[@]} -eq 3 && "${arr[1]}" == "D" && "${arr[2]}" == "C" && "${arr[3]}" == "B" ]]; then
        test_pass
    else
        test_fail "got: ${arr[*]}"
    fi
}

# ═══════════════════════════════════════════════════════════════
# Section 5: em move --recent
# ═══════════════════════════════════════════════════════════════

test_move_recent_no_history_errors() {
    test_case "em move --recent with no recent-folders history errors out"
    rm -rf "$TEST_CACHE_DIR/recent_folders"
    local output rc
    output=$(_em_move --recent 42 2>&1)
    rc=$?
    if [[ $rc -eq 1 ]]; then test_pass; else test_fail "expected rc=1, output: $output"; fi
}

test_move_recent_picks_from_list() {
    test_case "em move --recent lets the user pick a numbered recent folder"
    _em_recent_folders_add "Archive"
    _em_recent_folders_add "Projects"
    create_mock "_em_hml_move" 'return 0'
    echo "1" | _em_move --recent 42 &>/dev/null
    assert_mock_called "_em_hml_move" 1 && assert_mock_args "_em_hml_move" "INBOX Projects 42" && test_pass
    reset_mocks
}

# ═══════════════════════════════════════════════════════════════
# RUN
# ═══════════════════════════════════════════════════════════════

test_suite_start "em undo + recent-folders (Phase 3)"
setup

echo "${CYAN}Section 1: Undo-state cache round trip${RESET}"
test_undo_record_get_roundtrip
test_undo_record_overwrites_no_stack
test_undo_clear_empties_state

echo "${CYAN}Section 2: _em_undo with nothing recorded${RESET}"
test_undo_nothing_to_undo

echo "${CYAN}Section 3: _em_undo reversal per action type${RESET}"
test_undo_star_retoggles_same_ids
test_undo_flag_unflags_same_ids
test_undo_unflag_flags_same_ids
test_undo_move_swaps_src_dst
test_undo_clears_state_after_running
test_undo_move_failure_does_not_clear_state

echo "${CYAN}Section 4: Recent folders quick-list${RESET}"
test_recent_folders_add_get_roundtrip
test_recent_folders_most_recent_first
test_recent_folders_dedup
test_recent_folders_capped_at_3

echo "${CYAN}Section 5: em move --recent${RESET}"
test_move_recent_no_history_errors
test_move_recent_picks_from_list

test_suite_end
