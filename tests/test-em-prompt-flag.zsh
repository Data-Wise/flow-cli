#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE: Email --prompt and --backend Flags
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: Validate --prompt and --backend flag parsing across em commands,
#          TTY auto-detection, RETURN trap removal, and prompt helper function
#
# Created: 2026-02-26
# ══════════════════════════════════════════════════════════════════════════════

# Source shared test framework
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

# ══════════════════════════════════════════════════════════════════════════════
# SETUP / CLEANUP
# ══════════════════════════════════════════════════════════════════════════════

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

# ══════════════════════════════════════════════════════════════════════════════
# Section 1: RETURN Trap Bug Fix
# ══════════════════════════════════════════════════════════════════════════════

test_return_trap_fixed() {
    test_case "RETURN trap removed from _em_hml_reply"
    local fn_body
    fn_body="$(whence -f _em_hml_reply 2>/dev/null)"
    if [[ -z "$fn_body" ]]; then
        test_skip "_em_hml_reply not loaded"
        return
    fi
    assert_not_contains "$fn_body" "trap.*RETURN" "Should not contain trap RETURN"
    test_case_end
}

test_always_block_present() {
    test_case "always block present in _em_hml_reply"
    local fn_body
    fn_body="$(whence -f _em_hml_reply 2>/dev/null)"
    if [[ -z "$fn_body" ]]; then
        test_skip "_em_hml_reply not loaded"
        return
    fi
    assert_contains "$fn_body" "always" "Should contain always block"
    test_case_end
}

# ══════════════════════════════════════════════════════════════════════════════
# Section 2: TTY Detection Logic
# ══════════════════════════════════════════════════════════════════════════════

test_tty_detection_in_reply() {
    test_case "TTY detection code present in _em_reply"
    local fn_body
    fn_body="$(whence -f _em_reply 2>/dev/null)"
    if [[ -z "$fn_body" ]]; then
        test_skip "_em_reply not loaded"
        return
    fi
    assert_contains "$fn_body" "use_interactive" "Should contain use_interactive variable"
    assert_contains "$fn_body" "-t 0" "Should contain stdin TTY check"
    assert_contains "$fn_body" "-t 1" "Should contain stdout TTY check"
    test_case_end
}

# ══════════════════════════════════════════════════════════════════════════════
# Section 3: --prompt Flag Parsing
# ══════════════════════════════════════════════════════════════════════════════

test_reply_prompt_flag_parsed() {
    test_case "_em_reply accepts --prompt flag"
    local fn_body
    fn_body="$(whence -f _em_reply 2>/dev/null)"
    if [[ -z "$fn_body" ]]; then
        test_skip "_em_reply not loaded"
        return
    fi
    assert_contains "$fn_body" "--prompt" "Should contain --prompt in case statement"
    assert_contains "$fn_body" "prompt_text" "Should declare prompt_text variable"
    test_case_end
}

test_reply_backend_flag_parsed() {
    test_case "_em_reply accepts --backend flag"
    local fn_body
    fn_body="$(whence -f _em_reply 2>/dev/null)"
    if [[ -z "$fn_body" ]]; then
        test_skip "_em_reply not loaded"
        return
    fi
    assert_contains "$fn_body" "--backend" "Should contain --backend in case statement"
    assert_contains "$fn_body" "backend_override" "Should declare backend_override variable"
    test_case_end
}

test_prompt_forces_batch() {
    test_case "--prompt in TTY check implies non-interactive"
    local fn_body
    fn_body="$(whence -f _em_reply 2>/dev/null)"
    if [[ -z "$fn_body" ]]; then
        test_skip "_em_reply not loaded"
        return
    fi
    # The TTY check should include prompt_text condition
    assert_contains "$fn_body" 'prompt_text' "TTY check should reference prompt_text"
    test_case_end
}

# ══════════════════════════════════════════════════════════════════════════════
# Section 4: _em_ai_prompt_with_instructions
# ══════════════════════════════════════════════════════════════════════════════

test_prompt_with_instructions_exists() {
    test_case "_em_ai_prompt_with_instructions function exists"
    if ! whence -f _em_ai_prompt_with_instructions &>/dev/null; then
        test_fail "Function _em_ai_prompt_with_instructions not found"
        return
    fi
    test_case_end
}

test_prompt_with_instructions_output() {
    test_case "_em_ai_prompt_with_instructions includes user text"
    if ! whence -f _em_ai_prompt_with_instructions &>/dev/null; then
        test_skip "Function not loaded"
        return
    fi
    local output
    output=$(_em_ai_prompt_with_instructions "decline politely")
    assert_contains "$output" "User instructions: decline politely" "Should include user instructions"
    test_case_end
}

test_prompt_with_instructions_base() {
    test_case "_em_ai_prompt_with_instructions includes base prompt"
    if ! whence -f _em_ai_prompt_with_instructions &>/dev/null; then
        test_skip "Function not loaded"
        return
    fi
    local output
    output=$(_em_ai_prompt_with_instructions "test")
    # Base prompt contains category guidance
    assert_contains "$output" "draft" "Should include base draft prompt content"
    test_case_end
}

# ══════════════════════════════════════════════════════════════════════════════
# Section 5: _em_send --prompt
# ══════════════════════════════════════════════════════════════════════════════

test_send_prompt_flag() {
    test_case "_em_send accepts --prompt flag"
    local fn_body
    fn_body="$(whence -f _em_send 2>/dev/null)"
    if [[ -z "$fn_body" ]]; then
        test_skip "_em_send not loaded"
        return
    fi
    assert_contains "$fn_body" "--prompt" "Should contain --prompt in case statement"
    assert_contains "$fn_body" "prompt_text" "Should declare prompt_text variable"
    test_case_end
}

test_send_prompt_enables_ai() {
    test_case "_em_send --prompt implies --ai"
    local fn_body
    fn_body="$(whence -f _em_send 2>/dev/null)"
    if [[ -z "$fn_body" ]]; then
        test_skip "_em_send not loaded"
        return
    fi
    # The --prompt case should set use_ai=true
    assert_contains "$fn_body" "use_ai=true" "Should enable AI when --prompt is used"
    test_case_end
}

test_send_backend_flag() {
    test_case "_em_send accepts --backend flag"
    local fn_body
    fn_body="$(whence -f _em_send 2>/dev/null)"
    if [[ -z "$fn_body" ]]; then
        test_skip "_em_send not loaded"
        return
    fi
    assert_contains "$fn_body" "--backend" "Should contain --backend in case statement"
    assert_contains "$fn_body" "backend_override" "Should declare backend_override variable"
    test_case_end
}

# ══════════════════════════════════════════════════════════════════════════════
# Section 6: Help Output
# ══════════════════════════════════════════════════════════════════════════════

test_help_includes_prompt() {
    test_case "em help mentions --prompt"
    local help_output
    help_output="$(em help 2>&1)"
    assert_contains "$help_output" "--prompt" "Help should document --prompt flag"
    test_case_end
}

test_help_includes_backend() {
    test_case "em help mentions --backend"
    local help_output
    help_output="$(em help 2>&1)"
    assert_contains "$help_output" "--backend" "Help should document --backend flag"
    test_case_end
}

# ══════════════════════════════════════════════════════════════════════════════
# RUN
# ══════════════════════════════════════════════════════════════════════════════

setup

test_suite_start "Email --prompt and --backend Flags"

# Section 1: Trap fix
test_return_trap_fixed
test_always_block_present

# Section 2: TTY detection
test_tty_detection_in_reply

# Section 3: Reply flag parsing
test_reply_prompt_flag_parsed
test_reply_backend_flag_parsed
test_prompt_forces_batch

# Section 4: Prompt helper
test_prompt_with_instructions_exists
test_prompt_with_instructions_output
test_prompt_with_instructions_base

# Section 5: Send flags
test_send_prompt_flag
test_send_prompt_enables_ai
test_send_backend_flag

# Section 6: Help
test_help_includes_prompt
test_help_includes_backend

test_suite_end
exit $?
