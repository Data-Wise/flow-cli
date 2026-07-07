#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE: agy Output Cleaning & Validation
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: Validate _em_ai_agy_clean_output / _em_ai_agy_looks_valid.
# Context: agy (Antigravity CLI) has no clean-output flag and has been observed
#          to exit 0 with a canned "system operational" response on degenerate
#          input — these helpers strip its boilerplate and reject responses
#          that look like that canned fallback, since agy's exit code alone
#          cannot be trusted.
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
    exec < /dev/null  # Non-interactive
    source "$project_root/flow.plugin.zsh"
}

cleanup() {
    reset_mocks
}
trap cleanup EXIT

# ═══════════════════════════════════════════════════════════════
# Section 1: _em_ai_agy_clean_output strips the boilerplate block
# ═══════════════════════════════════════════════════════════════

test_clean_output_strips_emoji_block() {
    test_case "_em_ai_agy_clean_output strips the emoji status block"
    local raw="Fox jumps over lazy dog.

- **🟢 DONE:** Summarized the sentence.
- **⏭️ NEXT:** Await further instructions.
- **⚠️ WATCH OUT FOR:** None.
- **🔗 CONNECTED TO:** N/A."
    local cleaned
    cleaned=$(_em_ai_agy_clean_output "$raw")
    if [[ "$cleaned" == *"Fox jumps"* && "$cleaned" != *"DONE"* && "$cleaned" != *"CONNECTED TO"* ]]; then
        test_pass
    else
        test_fail "Expected boilerplate stripped, got: $cleaned"
    fi
}

test_clean_output_strips_separator_block() {
    test_case "_em_ai_agy_clean_output strips a --- separated block"
    local raw="Real answer here.

---

- **🟢 DONE:** something
"
    local cleaned
    cleaned=$(_em_ai_agy_clean_output "$raw")
    if [[ "$cleaned" == *"Real answer here"* && "$cleaned" != *"DONE"* ]]; then
        test_pass
    else
        test_fail "Expected content before separator kept, block removed, got: $cleaned"
    fi
}

test_clean_output_passes_through_plain_text() {
    test_case "_em_ai_agy_clean_output leaves plain text untouched"
    local raw="student"
    local cleaned
    cleaned=$(_em_ai_agy_clean_output "$raw")
    if [[ "$cleaned" == "student" ]]; then
        test_pass
    else
        test_fail "Expected 'student' unchanged, got: $cleaned"
    fi
}

# ═══════════════════════════════════════════════════════════════
# Section 2: _em_ai_agy_looks_valid rejects canned boilerplate
# ═══════════════════════════════════════════════════════════════

test_looks_valid_rejects_operational_boilerplate() {
    test_case "_em_ai_agy_looks_valid rejects 'system is operational' canned response"
    local canned="System is operational. Ready for causal inference research. What are we working on?"
    if _em_ai_agy_looks_valid "summarize" "$canned"; then
        test_fail "Expected canned boilerplate to be rejected"
    else
        test_pass
    fi
}

test_looks_valid_rejects_empty() {
    test_case "_em_ai_agy_looks_valid rejects empty output"
    if _em_ai_agy_looks_valid "classify" ""; then
        test_fail "Expected empty output to be rejected"
    else
        test_pass
    fi
}

test_looks_valid_rejects_long_classify_response() {
    test_case "_em_ai_agy_looks_valid rejects an overly long classify response"
    local long="this-is-a-suspiciously-long-classification-category-that-is-not-a-real-single-word-category"
    if _em_ai_agy_looks_valid "classify" "$long"; then
        test_fail "Expected long classify response to be rejected"
    else
        test_pass
    fi
}

test_looks_valid_accepts_short_classify_response() {
    test_case "_em_ai_agy_looks_valid accepts a real short classify response"
    if _em_ai_agy_looks_valid "classify" "student"; then
        test_pass
    else
        test_fail "Expected 'student' to be accepted as a valid classify response"
    fi
}

test_looks_valid_accepts_real_summary() {
    test_case "_em_ai_agy_looks_valid accepts a real one-line summary"
    local summary="Student Jane: absent Friday, requests notes"
    if _em_ai_agy_looks_valid "summarize" "$summary"; then
        test_pass
    else
        test_fail "Expected real summary to be accepted"
    fi
}

# ═══════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════

main() {
    test_suite_start "agy Output Cleaning & Validation"

    setup

    echo "${CYAN}Section 1: _em_ai_agy_clean_output${RESET}"
    test_clean_output_strips_emoji_block
    test_clean_output_strips_separator_block
    test_clean_output_passes_through_plain_text
    echo ""

    echo "${CYAN}Section 2: _em_ai_agy_looks_valid${RESET}"
    test_looks_valid_rejects_operational_boilerplate
    test_looks_valid_rejects_empty
    test_looks_valid_rejects_long_classify_response
    test_looks_valid_accepts_short_classify_response
    test_looks_valid_accepts_real_summary
    echo ""

    cleanup
    test_suite_end
    exit $?
}

main
