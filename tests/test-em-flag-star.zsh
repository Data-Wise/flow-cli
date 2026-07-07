#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE: em flag/star/unflag routing + dead-case-label regression guard
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: Regression guard for SPEC-em-ux-refactor-2026-07-07.md — a duplicate
#          `case` label (`star|flag)`) previously made `em flag` silently
#          unreachable to `_em_star`'s toggle logic; `em flag` always resolved
#          to `_em_flag` (one-way add) regardless. Confirms flag/star/unflag
#          each route to a distinct function, and that em star supports
#          multiple IDs like flag/unflag do.
#
# Created: 2026-07-07
# ══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

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
}

cleanup() {
    reset_mocks
}
trap cleanup EXIT

# ═══════════════════════════════════════════════════════════════
# Section 1: Dispatch routing — flag/star/unflag hit distinct functions
# ═══════════════════════════════════════════════════════════════

test_flag_routes_to_em_flag_only() {
    test_case "em flag routes to _em_flag, not _em_star"
    create_mock "_em_flag"
    create_mock "_em_star"
    em flag 42 &>/dev/null
    assert_mock_called "_em_flag" 1 && \
    assert_mock_not_called "_em_star" && \
    test_pass
    reset_mocks
}

test_star_routes_to_em_star_only() {
    test_case "em star routes to _em_star, not _em_flag"
    create_mock "_em_flag"
    create_mock "_em_star"
    em star 42 &>/dev/null
    assert_mock_called "_em_star" 1 && \
    assert_mock_not_called "_em_flag" && \
    test_pass
    reset_mocks
}

test_unflag_routes_to_em_unflag() {
    test_case "em unflag routes to _em_unflag"
    create_mock "_em_unflag"
    em unflag 42 &>/dev/null
    assert_mock_called "_em_unflag" 1 && test_pass
    reset_mocks
}

test_star_receives_multiple_ids() {
    test_case "em star 42 43 passes both IDs to _em_star"
    create_mock "_em_star"
    em star 42 43 &>/dev/null
    assert_mock_args "_em_star" "42 43" && test_pass
    reset_mocks
}

test_flag_receives_multiple_ids() {
    test_case "em flag 42 43 passes both IDs to _em_flag (unchanged behavior)"
    create_mock "_em_flag"
    em flag 42 43 &>/dev/null
    assert_mock_args "_em_flag" "42 43" && test_pass
    reset_mocks
}

# ═══════════════════════════════════════════════════════════════
# Section 2: No duplicate case labels in the em() dispatch block
# ═══════════════════════════════════════════════════════════════
# Guard against this exact bug class recurring for any future command.
# Detects the same label WORD bound to two DIFFERENT handler functions in
# two different case arms — not just any repeated word (legitimate aliases
# like `flag|fl)` binding one handler are valid and must not false-positive).

test_no_duplicate_case_labels_in_em_dispatch() {
    test_case "em() dispatch has no word bound to two different handlers"

    local dispatcher_file="$project_root/lib/dispatchers/email-dispatcher.zsh"
    local em_block
    # Extract the em() function body up to its closing brace at column 0.
    em_block=$(awk '/^em\(\) \{/{f=1} f{print} f && /^}/{exit}' "$dispatcher_file")

    # Collect "word) ... handler ;;" and "word|alias) ... handler ;;" arms,
    # split each arm's pipe-separated labels into individual words, and
    # track which handler function each word maps to.
    local -A word_to_handler
    local dup_found=""
    local line word_list handler w

    while IFS= read -r line; do
        [[ "$line" =~ '^[[:space:]]*([A-Za-z_|-]+)\)[[:space:]]+shift;[[:space:]]+([A-Za-z_]+)' ]] || continue
        word_list="${match[1]}"
        handler="${match[2]}"
        for w in ${(s:|:)word_list}; do
            if [[ -n "${word_to_handler[$w]:-}" && "${word_to_handler[$w]}" != "$handler" ]]; then
                dup_found="word '$w' bound to both '${word_to_handler[$w]}' and '$handler'"
            fi
            word_to_handler[$w]="$handler"
        done
    done <<< "$em_block"

    if [[ -n "$dup_found" ]]; then
        test_fail "$dup_found"
    else
        test_pass
    fi
}

# ═══════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════

main() {
    test_suite_start "em flag/star/unflag routing + dead-case-label guard"

    setup

    echo "${CYAN}Section 1: Dispatch routing${RESET}"
    test_flag_routes_to_em_flag_only
    test_star_routes_to_em_star_only
    test_unflag_routes_to_em_unflag
    test_star_receives_multiple_ids
    test_flag_receives_multiple_ids
    echo ""

    echo "${CYAN}Section 2: No duplicate case labels${RESET}"
    test_no_duplicate_case_labels_in_em_dispatch
    echo ""

    cleanup
    test_suite_end
    exit $?
}

main
