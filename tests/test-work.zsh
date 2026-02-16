#!/usr/bin/env zsh
# Test script for work command and session management
# Tests: work, finish, hop, session tracking, context display, project detection
# Rewritten: 2026-02-16 (behavioral assertions via test-framework.zsh)

# ============================================================================
# FRAMEWORK
# ============================================================================

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

source "$SCRIPT_DIR/test-framework.zsh" || {
    echo "ERROR: Cannot source test-framework.zsh"
    exit 1
}

# ============================================================================
# SETUP / CLEANUP
# ============================================================================

setup() {
    if [[ ! -f "$PROJECT_ROOT/flow.plugin.zsh" ]]; then
        echo "ERROR: Cannot find project root (expected flow.plugin.zsh at $PROJECT_ROOT)"
        exit 1
    fi

    # Source the plugin (non-interactive mode, no Atlas)
    FLOW_QUIET=1
    FLOW_ATLAS_ENABLED=no
    FLOW_PLUGIN_DIR="$PROJECT_ROOT"
    source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
        echo "ERROR: Plugin failed to load"
        exit 1
    }

    # Close stdin to prevent interactive commands from blocking
    exec < /dev/null

    # Create isolated test project root (avoids scanning real ~/projects)
    TEST_ROOT=$(mktemp -d)
    mkdir -p "$TEST_ROOT/dev-tools/mock-dev" "$TEST_ROOT/apps/test-app"
    for dir in "$TEST_ROOT"/dev-tools/mock-dev "$TEST_ROOT"/apps/test-app; do
        printf "## Status: active\n## Progress: 50\n" > "$dir/.STATUS"
    done
    FLOW_PROJECTS_ROOT="$TEST_ROOT"

    # Mock fzf availability (prevent interactive blocking)
    create_mock "_flow_has_fzf" "return 1"
    # Mock editor (prevent launching real editors)
    create_mock "_flow_open_editor" "return 0"
}

cleanup() {
    reset_mocks
    [[ -n "$TEST_ROOT" ]] && rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

# ============================================================================
# TESTS: Environment
# ============================================================================

test_flow_projects_root_defined() {
    test_case "FLOW_PROJECTS_ROOT is defined"
    assert_not_empty "$FLOW_PROJECTS_ROOT" "FLOW_PROJECTS_ROOT should be set" && test_pass
}

test_flow_projects_root_exists() {
    test_case "FLOW_PROJECTS_ROOT directory exists"
    assert_dir_exists "$FLOW_PROJECTS_ROOT" && test_pass
}

# ============================================================================
# TESTS: Command existence
# ============================================================================

test_work_exists() {
    test_case "work command exists"
    assert_function_exists "work" && test_pass
}

test_finish_exists() {
    test_case "finish command exists"
    assert_function_exists "finish" && test_pass
}

test_hop_exists() {
    test_case "hop command exists"
    assert_function_exists "hop" && test_pass
}

test_why_exists() {
    test_case "why command exists"
    assert_function_exists "why" && test_pass
}

# ============================================================================
# TESTS: Helper functions
# ============================================================================

test_show_work_context_exists() {
    test_case "_flow_show_work_context function exists"
    assert_function_exists "_flow_show_work_context" && test_pass
}

test_open_editor_exists() {
    test_case "_flow_open_editor function exists"
    assert_function_exists "_flow_open_editor" && test_pass
}

test_session_start_exists() {
    test_case "_flow_session_start function exists"
    assert_function_exists "_flow_session_start" && test_pass
}

test_session_end_exists() {
    test_case "_flow_session_end function exists"
    assert_function_exists "_flow_session_end" && test_pass
}

# ============================================================================
# TESTS: Core utility functions
# ============================================================================

test_find_project_root_exists() {
    test_case "_flow_find_project_root function exists"
    assert_function_exists "_flow_find_project_root" && test_pass
}

test_get_project_exists() {
    test_case "_flow_get_project function exists"
    assert_function_exists "_flow_get_project" && test_pass
}

test_project_name_exists() {
    test_case "_flow_project_name function exists"
    assert_function_exists "_flow_project_name" && test_pass
}

test_pick_project_exists() {
    test_case "_flow_pick_project function exists"
    assert_function_exists "_flow_pick_project" && test_pass
}

test_detect_project_type_exists() {
    test_case "_flow_detect_project_type function exists"
    assert_function_exists "_flow_detect_project_type" && test_pass
}

test_project_icon_exists() {
    test_case "_flow_project_icon function exists"
    assert_function_exists "_flow_project_icon" && test_pass
}

# ============================================================================
# TESTS: work command behavior
# ============================================================================

test_work_no_args_shows_error() {
    test_case "work (no args, no fzf) exits with error"

    local output
    output=$(work 2>&1)
    local exit_code=$?

    # Without fzf and not in a project dir, should fail with exit 1
    assert_exit_code "$exit_code" 1 "work with no args and no fzf should exit 1" && test_pass
}

test_work_invalid_project() {
    test_case "work with invalid project shows 'not found' error"

    local output
    output=$(work nonexistent_project_xyz 2>&1)
    local exit_code=$?

    assert_exit_code "$exit_code" 1 "work with invalid project should exit 1" || return
    assert_contains "$output" "not found" "Should mention project not found" && test_pass
}

# ============================================================================
# TESTS: finish command behavior
# ============================================================================

test_finish_no_session_exits_cleanly() {
    test_case "finish when not in session exits cleanly"

    local output
    output=$(finish 2>&1)
    local exit_code=$?

    # finish outside a session should exit 0 (no-op) and not produce error output
    assert_exit_code "$exit_code" 0 "finish outside session should exit 0" || return
    assert_not_contains "$output" "command not found" "Should not show 'command not found'" && \
    assert_not_contains "$output" "syntax error" "Should not show syntax errors" && test_pass
}

# ============================================================================
# TESTS: hop command behavior
# ============================================================================

test_hop_no_args_shows_usage() {
    test_case "hop without args shows usage or exits with error"

    local output
    output=$(hop 2>&1)
    local exit_code=$?

    # Without fzf, hop should exit 1 (usage/error)
    assert_exit_code "$exit_code" 1 "hop with no args and no fzf should exit 1" && test_pass
}

# ============================================================================
# TESTS: why command behavior
# ============================================================================

test_why_exits_zero() {
    test_case "why command exits with code 0"

    local output
    output=$(why 2>&1)
    local exit_code=$?

    assert_exit_code "$exit_code" 0 "why should exit 0" && test_pass
}

# ============================================================================
# TESTS: Context display
# ============================================================================

test_show_context_exits_zero() {
    test_case "_flow_show_work_context exits with code 0"

    local output
    output=$(_flow_show_work_context "test-project" "/tmp" 2>&1)
    local exit_code=$?

    assert_exit_code "$exit_code" 0 "_flow_show_work_context should exit 0" && test_pass
}

test_show_context_includes_project_name() {
    test_case "_flow_show_work_context includes project name in output"

    local output
    output=$(_flow_show_work_context "my-test-project" "/tmp" 2>&1)

    assert_contains "$output" "my-test-project" "Output should contain the project name" && test_pass
}

# ============================================================================
# TESTS: Project detection
# ============================================================================

test_find_project_root_in_git() {
    test_case "_flow_find_project_root finds git root in a real repo"

    # flow-cli itself is a git repo
    cd "$PROJECT_ROOT" 2>/dev/null
    local root
    root=$(_flow_find_project_root 2>/dev/null)

    assert_not_empty "$root" "Should return a project root path" || return
    assert_dir_exists "$root" "Returned root should be an existing directory" && test_pass
}

# ============================================================================
# TESTS: Editor flag (-e)
# ============================================================================

# Helper: set up mock project env for editor tests
_mock_project_env() {
    _EDITOR_CAPTURE_FILE=$(mktemp)
    mkdir -p "$TEST_ROOT/dev-tools/mock-proj"
    printf "## Status: active\n## Progress: 50\n" > "$TEST_ROOT/dev-tools/mock-proj/.STATUS"
    # Reset the editor mock to capture what editor name is passed
    create_mock "_flow_open_editor" 'echo "$1" > "'"$_EDITOR_CAPTURE_FILE"'"'
}

_restore_project_env() {
    [[ -n "$_EDITOR_CAPTURE_FILE" ]] && rm -f "$_EDITOR_CAPTURE_FILE"
}

test_work_no_editor_by_default() {
    test_case "work without -e does NOT call _flow_open_editor"
    _mock_project_env
    create_mock "_flow_open_editor" "return 0"
    work mock-proj &>/dev/null
    assert_mock_called "_flow_open_editor" 0 "_flow_open_editor should not be called without -e" && test_pass
    _restore_project_env
}

test_work_no_editor_no_call() {
    test_case "work mock-proj (no flag) never calls _flow_open_editor"
    _mock_project_env
    create_mock "_flow_open_editor" "return 0"
    work mock-proj &>/dev/null
    assert_mock_not_called "_flow_open_editor" && test_pass
    _restore_project_env
}

test_work_editor_flag_bare() {
    test_case "work -e (bare) opens EDITOR fallback"
    _mock_project_env
    EDITOR="test-editor"
    work mock-proj -e &>/dev/null
    local captured=$(cat "$_EDITOR_CAPTURE_FILE" 2>/dev/null)
    assert_equals "$captured" "test-editor" && test_pass
    _restore_project_env
}

test_work_editor_flag_with_name() {
    test_case "work -e positron passes 'positron' to editor"
    _mock_project_env
    work mock-proj -e positron &>/dev/null
    local captured=$(cat "$_EDITOR_CAPTURE_FILE" 2>/dev/null)
    assert_equals "$captured" "positron" && test_pass
    _restore_project_env
}

test_work_editor_flag_code() {
    test_case "work -e code passes 'code' to editor"
    _mock_project_env
    work mock-proj -e code &>/dev/null
    local captured=$(cat "$_EDITOR_CAPTURE_FILE" 2>/dev/null)
    assert_equals "$captured" "code" && test_pass
    _restore_project_env
}

test_work_editor_flag_before_project() {
    test_case "work -e code mock-proj (flag before project)"
    _mock_project_env
    work -e code mock-proj &>/dev/null
    local captured=$(cat "$_EDITOR_CAPTURE_FILE" 2>/dev/null)
    assert_equals "$captured" "code" && test_pass
    _restore_project_env
}

test_work_long_editor_flag() {
    test_case "work --editor nvim uses long flag form"
    _mock_project_env
    work mock-proj --editor nvim &>/dev/null
    local captured=$(cat "$_EDITOR_CAPTURE_FILE" 2>/dev/null)
    assert_equals "$captured" "nvim" && test_pass
    _restore_project_env
}

test_work_editor_flag_cc() {
    test_case "_flow_open_editor handles cc|claude|ccy cases"
    # Read source from the original file, not the mocked function
    local source_code=$(grep -c 'cc\|claude\|ccy' "$PROJECT_ROOT/commands/work.zsh" 2>/dev/null)
    if (( source_code > 0 )); then test_pass; else test_fail "cc/claude/ccy not found in work.zsh"; fi
}

test_work_editor_cc_new_in_source() {
    test_case "_flow_open_editor handles cc:new|claude:new"
    local source_file="$PROJECT_ROOT/commands/work.zsh"
    assert_file_exists "$source_file" || return
    local content=$(< "$source_file")
    assert_contains "$content" "cc:new" "Should contain cc:new" || return
    assert_contains "$content" "claude:new" "Should contain claude:new" && test_pass
}

test_work_launch_claude_code_yolo_branch() {
    test_case "_work_launch_claude_code has yolo (ccy) branch"
    local source_code=$(functions _work_launch_claude_code 2>/dev/null)
    assert_contains "$source_code" "dangerously-skip-permissions" && test_pass
}

test_work_legacy_positional_editor() {
    test_case "work <proj> <editor> shows deprecation warning"
    _mock_project_env
    local output=$(work mock-proj nvim 2>&1)
    assert_contains "$output" "eprecated" "Should show deprecation warning" && test_pass
    _restore_project_env
}

test_work_legacy_positional_still_opens() {
    test_case "deprecated positional editor still opens editor"
    _mock_project_env
    local output=$(work mock-proj vim 2>&1)
    local captured=$(cat "$_EDITOR_CAPTURE_FILE" 2>/dev/null)
    assert_equals "$captured" "vim" && test_pass
    _restore_project_env
}

test_work_help_shows_editor_flag() {
    test_case "work --help shows -e flag"
    local output=$(work --help 2>&1)
    assert_contains "$output" "-e" "Help should mention -e flag" && test_pass
}

test_work_help_shows_cc_editors() {
    test_case "work --help lists Claude Code editors"
    local output=$(work --help 2>&1)
    assert_contains "$output" "cc" "Should list cc editor" || return
    assert_contains "$output" "cc:new" "Should list cc:new editor" && test_pass
}

test_work_launch_claude_code_exists() {
    test_case "_work_launch_claude_code function exists"
    assert_function_exists "_work_launch_claude_code" && test_pass
}

# ============================================================================
# TESTS: _flow_open_editor edge cases
# ============================================================================

test_open_editor_empty_returns_warning() {
    test_case "_flow_open_editor with empty string returns warning"
    # Restore the real function for behavioral tests
    reset_mocks
    source "$PROJECT_ROOT/commands/work.zsh" 2>/dev/null
    local output=$(_flow_open_editor "" "/tmp" 2>&1)
    local exit_code=$?
    # Re-apply mock for subsequent tests
    create_mock "_flow_open_editor" "return 0"
    if [[ $exit_code -ne 0 || "$output" == *"No editor"* ]]; then
        test_pass
    else
        test_fail "Expected warning for empty editor, got exit=$exit_code"
    fi
}

test_open_editor_unknown_skips_gracefully() {
    test_case "_flow_open_editor with unknown editor skips gracefully"
    reset_mocks
    source "$PROJECT_ROOT/commands/work.zsh" 2>/dev/null
    local output=$(_flow_open_editor "zzz_no_such_editor_zzz" "/tmp" 2>&1)
    local exit_code=$?
    create_mock "_flow_open_editor" "return 0"
    assert_exit_code "$exit_code" 0 "Should not crash" || return
    assert_contains "$output" "not found" "Should say editor not found" && test_pass
}

test_open_editor_code_branch_exists() {
    test_case "_flow_open_editor has code|vscode branch"
    local content=$(< "$PROJECT_ROOT/commands/work.zsh")
    assert_contains "$content" "code" "Should contain code case" && test_pass
}

test_open_editor_positron_branch_exists() {
    test_case "_flow_open_editor has positron branch"
    local content=$(< "$PROJECT_ROOT/commands/work.zsh")
    assert_contains "$content" "positron" && test_pass
}

test_open_editor_cursor_branch_exists() {
    test_case "_flow_open_editor has cursor branch"
    local content=$(< "$PROJECT_ROOT/commands/work.zsh")
    assert_contains "$content" "cursor" && test_pass
}

test_open_editor_emacs_branch_exists() {
    test_case "_flow_open_editor has emacs branch"
    local content=$(< "$PROJECT_ROOT/commands/work.zsh")
    assert_contains "$content" "emacs" && test_pass
}

# ============================================================================
# TESTS: .STATUS parsing
# ============================================================================

test_show_context_parses_status_field() {
    test_case "_flow_show_work_context shows Status from .STATUS"
    local tmp=$(mktemp -d)
    mkdir -p "$tmp/test-proj"
    echo "## Status: Active" > "$tmp/test-proj/.STATUS"
    local output=$(_flow_show_work_context "test-proj" "$tmp/test-proj" 2>&1)
    rm -rf "$tmp"
    assert_contains "$output" "Active" "Should parse Status field" && test_pass
}

test_show_context_parses_phase_field() {
    test_case "_flow_show_work_context shows Phase from .STATUS"
    local tmp=$(mktemp -d)
    mkdir -p "$tmp/test-proj"
    printf "## Status: Active\n## Phase: Testing\n" > "$tmp/test-proj/.STATUS"
    local output=$(_flow_show_work_context "test-proj" "$tmp/test-proj" 2>&1)
    rm -rf "$tmp"
    assert_contains "$output" "Testing" "Should parse Phase field" && test_pass
}

test_show_context_handles_missing_status_file() {
    test_case "_flow_show_work_context handles missing .STATUS"
    local tmp=$(mktemp -d)
    mkdir -p "$tmp/no-status-proj"
    local output=$(_flow_show_work_context "no-status-proj" "$tmp/no-status-proj" 2>&1)
    local exit_code=$?
    rm -rf "$tmp"
    assert_exit_code "$exit_code" 0 "Should not crash with missing .STATUS" && test_pass
}

# ============================================================================
# TESTS: finish help
# ============================================================================

test_finish_help_flag() {
    test_case "finish --help shows help text"
    local output=$(finish --help 2>&1)
    assert_contains "$output" "FINISH" "Should show FINISH header" && test_pass
}

test_finish_help_shorthand() {
    test_case "finish help shows help text"
    local output=$(finish help 2>&1)
    assert_contains "$output" "FINISH" && test_pass
}

test_finish_help_h_flag() {
    test_case "finish -h shows help text"
    local output=$(finish -h 2>&1)
    assert_contains "$output" "FINISH" && test_pass
}

# ============================================================================
# TESTS: hop behavior
# ============================================================================

test_hop_help_flag() {
    test_case "hop --help shows help text"
    local output=$(hop --help 2>&1)
    assert_contains "$output" "HOP" "Should show HOP header" && test_pass
}

test_hop_invalid_project() {
    test_case "hop with invalid project shows error"
    local output=$(hop zzz_nonexistent_proj_zzz 2>&1)
    if [[ "$output" == *"not found"* || "$output" == *"rror"* ]]; then
        test_pass
    else
        test_fail "Should show error for invalid project"
    fi
}

test_hop_help_shorthand() {
    test_case "hop help shows help text"
    local output=$(hop help 2>&1)
    assert_contains "$output" "HOP" && test_pass
}

# ============================================================================
# TESTS: work help output
# ============================================================================

test_work_help_flag() {
    test_case "work --help shows help text"
    local output=$(work --help 2>&1)
    assert_contains "$output" "WORK" "Should show WORK header" && test_pass
}

test_work_help_shows_usage() {
    test_case "work --help shows usage line"
    local output=$(work --help 2>&1)
    assert_contains "$output" "Usage:" "Should contain Usage:" || return
    assert_contains "$output" "-e" "Should mention -e flag" && test_pass
}

test_work_help_shows_editors_section() {
    test_case "work --help lists all editor types"
    local output=$(work --help 2>&1)
    assert_contains "$output" "positron" "Should list positron" || return
    assert_contains "$output" "code" "Should list code" || return
    assert_contains "$output" "nvim" "Should list nvim" && test_pass
}

# ============================================================================
# TESTS: Arg parser edge cases
# ============================================================================

test_work_help_in_any_position() {
    test_case "work mock-proj -h shows help (non-first position)"
    local output=$(work mock-proj -h 2>&1)
    assert_contains "$output" "WORK" "Should show help from any position" && test_pass
}

test_work_editor_flag_at_end_bare() {
    test_case "work mock-proj -e (flag at end, no value) uses EDITOR"
    _mock_project_env
    EDITOR="fallback-ed"
    work mock-proj -e &>/dev/null
    local captured=$(cat "$_EDITOR_CAPTURE_FILE" 2>/dev/null)
    assert_equals "$captured" "fallback-ed" && test_pass
    _restore_project_env
}

test_work_editor_default_when_no_EDITOR() {
    test_case "work -e with no EDITOR falls back to nvim"
    _mock_project_env
    local saved_editor="$EDITOR"
    unset EDITOR
    work mock-proj -e &>/dev/null
    local captured=$(cat "$_EDITOR_CAPTURE_FILE" 2>/dev/null)
    EDITOR="$saved_editor"
    assert_equals "$captured" "nvim" "Should fall back to nvim" && test_pass
    _restore_project_env
}

test_work_multiple_remaining_args_uses_first() {
    test_case "work proj1 proj2 triggers deprecation warning"
    _mock_project_env
    local output=$(work mock-proj extraarg 2>&1)
    assert_contains "$output" "eprecated" "Should show deprecation warning" && test_pass
    _restore_project_env
}

test_work_unknown_flags_ignored() {
    test_case "work --verbose mock-proj warns about unknown flag"
    _mock_project_env
    local output=$(work --verbose mock-proj 2>&1)
    assert_contains "$output" "Unknown flag" "Should warn about unknown flag" && test_pass
    _restore_project_env
}

test_work_editor_flag_with_project_in_middle() {
    test_case "work -e vim mock-proj (editor value before project)"
    _mock_project_env
    work -e vim mock-proj &>/dev/null
    local captured=$(cat "$_EDITOR_CAPTURE_FILE" 2>/dev/null)
    assert_equals "$captured" "vim" && test_pass
    _restore_project_env
}

# ============================================================================
# TESTS: Teaching workflow
# ============================================================================

test_work_teaching_session_exists() {
    test_case "_work_teaching_session function exists"
    assert_function_exists "_work_teaching_session" && test_pass
}

test_work_teaching_session_requires_config() {
    test_case "_work_teaching_session errors without config file"
    local tmp=$(mktemp -d)
    mkdir -p "$tmp/no-config"
    local output=$(_work_teaching_session "$tmp/no-config" 2>&1)
    local exit_code=$?
    rm -rf "$tmp"
    if [[ $exit_code -ne 0 || "$output" == *"not found"* ]]; then
        test_pass
    else
        test_fail "Should error without teach-config.yml"
    fi
}

# ============================================================================
# TESTS: First-run welcome
# ============================================================================

test_first_run_welcome_exists() {
    test_case "_flow_first_run_welcome function exists"
    assert_function_exists "_flow_first_run_welcome" && test_pass
}

test_first_run_welcome_shows_quick_start() {
    test_case "_flow_first_run_welcome creates marker file"
    local tmp=$(mktemp -d)
    XDG_CONFIG_HOME="$tmp" _flow_first_run_welcome > /dev/null 2>&1
    assert_file_exists "$tmp/flow-cli/.welcomed" "Welcome marker should be created" && test_pass
    rm -rf "$tmp"
}

test_first_run_welcome_skips_second_time() {
    test_case "_flow_first_run_welcome skips on second call"
    local tmp=$(mktemp -d)
    mkdir -p "$tmp/flow-cli"
    touch "$tmp/flow-cli/.welcomed"
    local output=$(XDG_CONFIG_HOME="$tmp" _flow_first_run_welcome 2>&1)
    rm -rf "$tmp"
    assert_empty "$output" "Should produce no output when marker exists" && test_pass
}

# ============================================================================
# TESTS: Token validation helpers
# ============================================================================

test_work_get_token_status_exists() {
    test_case "_work_get_token_status function exists"
    assert_function_exists "_work_get_token_status" && test_pass
}

test_work_will_push_to_remote_exists() {
    test_case "_work_will_push_to_remote function exists"
    assert_function_exists "_work_will_push_to_remote" && test_pass
}

test_work_project_uses_github_no_git() {
    test_case "_work_project_uses_github returns false for non-git dir"
    local tmp=$(mktemp -d)
    _work_project_uses_github "$tmp"
    local exit_code=$?
    rm -rf "$tmp"
    assert_exit_code "$exit_code" 1 "Should return false for non-git directory" && test_pass
}

# ============================================================================
# RUN ALL TESTS
# ============================================================================

main() {
    test_suite_start "Work Command Tests"

    setup

    echo "${CYAN}--- Environment ---${RESET}"
    test_flow_projects_root_defined
    test_flow_projects_root_exists

    echo ""
    echo "${CYAN}--- Command existence ---${RESET}"
    test_work_exists
    test_finish_exists
    test_hop_exists
    test_why_exists

    echo ""
    echo "${CYAN}--- Helper functions ---${RESET}"
    test_show_work_context_exists
    test_open_editor_exists
    test_session_start_exists
    test_session_end_exists

    echo ""
    echo "${CYAN}--- Core utility functions ---${RESET}"
    test_find_project_root_exists
    test_get_project_exists
    test_project_name_exists
    test_pick_project_exists
    test_detect_project_type_exists
    test_project_icon_exists

    echo ""
    echo "${CYAN}--- work command behavior ---${RESET}"
    test_work_no_args_shows_error
    test_work_invalid_project

    echo ""
    echo "${CYAN}--- finish command ---${RESET}"
    test_finish_no_session_exits_cleanly

    echo ""
    echo "${CYAN}--- hop command ---${RESET}"
    test_hop_no_args_shows_usage

    echo ""
    echo "${CYAN}--- why command ---${RESET}"
    test_why_exits_zero

    echo ""
    echo "${CYAN}--- Context display ---${RESET}"
    test_show_context_exits_zero
    test_show_context_includes_project_name

    echo ""
    echo "${CYAN}--- Project detection ---${RESET}"
    test_find_project_root_in_git

    echo ""
    echo "${CYAN}--- Editor flag (-e) ---${RESET}"
    test_work_no_editor_by_default
    test_work_no_editor_no_call
    test_work_editor_flag_bare
    test_work_editor_flag_with_name
    test_work_editor_flag_code
    test_work_editor_flag_before_project
    test_work_long_editor_flag
    test_work_editor_flag_cc
    test_work_editor_cc_new_in_source
    test_work_launch_claude_code_yolo_branch
    test_work_legacy_positional_editor
    test_work_legacy_positional_still_opens
    test_work_help_shows_editor_flag
    test_work_help_shows_cc_editors
    test_work_launch_claude_code_exists

    echo ""
    echo "${CYAN}--- _flow_open_editor edge cases ---${RESET}"
    test_open_editor_empty_returns_warning
    test_open_editor_unknown_skips_gracefully
    test_open_editor_code_branch_exists
    test_open_editor_positron_branch_exists
    test_open_editor_cursor_branch_exists
    test_open_editor_emacs_branch_exists

    echo ""
    echo "${CYAN}--- .STATUS parsing ---${RESET}"
    test_show_context_parses_status_field
    test_show_context_parses_phase_field
    test_show_context_handles_missing_status_file

    echo ""
    echo "${CYAN}--- finish help ---${RESET}"
    test_finish_help_flag
    test_finish_help_shorthand
    test_finish_help_h_flag

    echo ""
    echo "${CYAN}--- hop behavior ---${RESET}"
    test_hop_help_flag
    test_hop_invalid_project
    test_hop_help_shorthand

    echo ""
    echo "${CYAN}--- work help output ---${RESET}"
    test_work_help_flag
    test_work_help_shows_usage
    test_work_help_shows_editors_section

    echo ""
    echo "${CYAN}--- Arg parser edge cases ---${RESET}"
    test_work_help_in_any_position
    test_work_editor_flag_at_end_bare
    test_work_editor_default_when_no_EDITOR
    test_work_multiple_remaining_args_uses_first
    test_work_unknown_flags_ignored
    test_work_editor_flag_with_project_in_middle

    echo ""
    echo "${CYAN}--- Teaching workflow ---${RESET}"
    test_work_teaching_session_exists
    test_work_teaching_session_requires_config

    echo ""
    echo "${CYAN}--- First-run welcome ---${RESET}"
    test_first_run_welcome_exists
    test_first_run_welcome_shows_quick_start
    test_first_run_welcome_skips_second_time

    echo ""
    echo "${CYAN}--- Token validation ---${RESET}"
    test_work_get_token_status_exists
    test_work_will_push_to_remote_exists
    test_work_project_uses_github_no_git

    # Cleanup
    cleanup

    # Summary (from framework)
    test_suite_end
    exit $?
}

main "$@"
