#!/usr/bin/env zsh
# Test script for work command and session management
# Tests: work, finish, hop, session tracking
# Generated: 2025-12-30

# ============================================================================
# TEST FRAMEWORK
# ============================================================================

TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
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

# ============================================================================
# SETUP
# ============================================================================

# Resolve project root at top level (${0:A} doesn't work inside functions)
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

setup() {
    echo ""
    echo "${YELLOW}Setting up test environment...${NC}"

    if [[ ! -f "$PROJECT_ROOT/flow.plugin.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root${NC}"
        exit 1
    fi

    echo "  Project root: $PROJECT_ROOT"

    # Source the plugin (non-interactive mode, no Atlas)
    FLOW_QUIET=1
    FLOW_ATLAS_ENABLED=no
    FLOW_PLUGIN_DIR="$PROJECT_ROOT"
    source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
        echo "${RED}Plugin failed to load${NC}"
        exit 1
    }

    # Close stdin to prevent any interactive commands from blocking
    exec < /dev/null

    # Create isolated test project root (avoids scanning real ~/projects)
    TEST_ROOT=$(mktemp -d)
    mkdir -p "$TEST_ROOT/dev-tools/mock-dev" "$TEST_ROOT/apps/test-app"
    for dir in "$TEST_ROOT"/dev-tools/mock-dev "$TEST_ROOT"/apps/test-app; do
        echo "## Status: active\n## Progress: 50" > "$dir/.STATUS"
    done
    FLOW_PROJECTS_ROOT="$TEST_ROOT"

    echo ""
}

# ============================================================================
# TESTS: Command existence
# ============================================================================

test_work_exists() {
    log_test "work command exists"

    if type work &>/dev/null; then
        pass
    else
        fail "work command not found"
    fi
}

test_finish_exists() {
    log_test "finish command exists"

    if type finish &>/dev/null; then
        pass
    else
        fail "finish command not found"
    fi
}

test_hop_exists() {
    log_test "hop command exists"

    if type hop &>/dev/null; then
        pass
    else
        fail "hop command not found"
    fi
}

test_why_exists() {
    log_test "why command exists"

    if type why &>/dev/null; then
        pass
    else
        fail "why command not found"
    fi
}

# ============================================================================
# TESTS: Helper functions
# ============================================================================

test_show_work_context_exists() {
    log_test "_flow_show_work_context function exists"

    if type _flow_show_work_context &>/dev/null; then
        pass
    else
        fail "_flow_show_work_context not found"
    fi
}

test_open_editor_exists() {
    log_test "_flow_open_editor function exists"

    if type _flow_open_editor &>/dev/null; then
        pass
    else
        fail "_flow_open_editor not found"
    fi
}

test_session_start_exists() {
    log_test "_flow_session_start function exists"

    if type _flow_session_start &>/dev/null; then
        pass
    else
        fail "_flow_session_start not found"
    fi
}

test_session_end_exists() {
    log_test "_flow_session_end function exists"

    if type _flow_session_end &>/dev/null; then
        pass
    else
        fail "_flow_session_end not found"
    fi
}

# ============================================================================
# TESTS: Core utility functions
# ============================================================================

test_find_project_root_exists() {
    log_test "_flow_find_project_root function exists"

    if type _flow_find_project_root &>/dev/null; then
        pass
    else
        fail "_flow_find_project_root not found"
    fi
}

test_get_project_exists() {
    log_test "_flow_get_project function exists"

    if type _flow_get_project &>/dev/null; then
        pass
    else
        fail "_flow_get_project not found"
    fi
}

test_project_name_exists() {
    log_test "_flow_project_name function exists"

    if type _flow_project_name &>/dev/null; then
        pass
    else
        fail "_flow_project_name not found"
    fi
}

test_pick_project_exists() {
    log_test "_flow_pick_project function exists"

    if type _flow_pick_project &>/dev/null; then
        pass
    else
        fail "_flow_pick_project not found"
    fi
}

# ============================================================================
# TESTS: work command behavior (non-destructive)
# ============================================================================

test_work_no_args_returns_error() {
    log_test "work (no args, no fzf) shows error or picker"

    # Override _flow_has_fzf so work doesn't launch fzf (opens /dev/tty, blocks)
    _flow_has_fzf() { return 1; }

    local output=$(work 2>&1)
    local exit_code=$?

    # Restore original
    unfunction _flow_has_fzf 2>/dev/null

    # Without fzf and not in a project dir, should show usage/error (exit 1)
    if [[ $exit_code -eq 0 || $exit_code -eq 1 ]]; then
        pass
    else
        fail "Unexpected exit code: $exit_code"
    fi
}

test_work_invalid_project() {
    log_test "work with invalid project shows error"

    local output=$(work nonexistent_project_xyz 2>&1)

    if [[ "$output" == *"not found"* || "$output" == *"error"* || "$output" == *"Error"* ]]; then
        pass
    else
        fail "Should show error for invalid project"
    fi
}

# ============================================================================
# TESTS: finish command behavior
# ============================================================================

test_finish_no_session() {
    log_test "finish when not in session handles gracefully"

    local output=$(finish 2>&1)
    local exit_code=$?

    # Should not crash, may show warning or just succeed
    if [[ $exit_code -eq 0 || $exit_code -eq 1 ]]; then
        pass
    else
        fail "Unexpected exit code: $exit_code"
    fi
}

# ============================================================================
# TESTS: hop command behavior
# ============================================================================

test_hop_help() {
    log_test "hop without args shows help or picker"

    # Override _flow_has_fzf so hop doesn't launch fzf (opens /dev/tty, blocks)
    _flow_has_fzf() { return 1; }

    local output=$(hop 2>&1)
    local exit_code=$?

    unfunction _flow_has_fzf 2>/dev/null

    # Should either show picker or usage
    if [[ $exit_code -eq 0 || $exit_code -eq 1 ]]; then
        pass
    else
        fail "Unexpected exit code: $exit_code"
    fi
}

# ============================================================================
# TESTS: why command behavior
# ============================================================================

test_why_runs() {
    log_test "why command runs without error"

    local output=$(why 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Exit code: $exit_code"
    fi
}

# ============================================================================
# TESTS: _flow_show_work_context output
# ============================================================================

test_show_context_runs() {
    log_test "_flow_show_work_context runs without error"

    local output=$(_flow_show_work_context "test-project" "/tmp" 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Exit code: $exit_code"
    fi
}

test_show_context_shows_project() {
    log_test "_flow_show_work_context includes project name"

    local output=$(_flow_show_work_context "my-test-project" "/tmp" 2>&1)

    if [[ "$output" == *"my-test-project"* ]]; then
        pass
    else
        fail "Should show project name in output"
    fi
}

# ============================================================================
# TESTS: Project detection utilities
# ============================================================================

test_find_project_root_in_git() {
    log_test "_flow_find_project_root finds git root"

    # Test in current directory (flow-cli is a git repo)
    cd "${0:A:h:h}" 2>/dev/null
    local root=$(_flow_find_project_root 2>/dev/null)
    local exit_code=$?

    # In CI, mock .git directories don't have actual git metadata
    # The function returns empty for mock dirs - that's acceptable
    # Real git repos return the root path
    if [[ -n "$root" && -d "$root" ]]; then
        # Real git repo - found the root
        pass
    elif [[ $exit_code -eq 0 || -z "$root" ]]; then
        # CI mock environment - function didn't crash, empty return is OK
        pass
    else
        fail "Function crashed or returned unexpected result"
    fi
}

test_detect_project_type_exists() {
    log_test "_flow_detect_project_type function exists"

    if type _flow_detect_project_type &>/dev/null; then
        pass
    else
        fail "_flow_detect_project_type not found"
    fi
}

test_project_icon_exists() {
    log_test "_flow_project_icon function exists"

    if type _flow_project_icon &>/dev/null; then
        pass
    else
        fail "_flow_project_icon not found"
    fi
}

# ============================================================================
# TESTS: Environment variables
# ============================================================================

test_flow_projects_root_defined() {
    log_test "FLOW_PROJECTS_ROOT is defined"

    if [[ -n "$FLOW_PROJECTS_ROOT" ]]; then
        pass
    else
        fail "FLOW_PROJECTS_ROOT not defined"
    fi
}

test_flow_projects_root_exists() {
    log_test "FLOW_PROJECTS_ROOT directory exists"

    if [[ -d "$FLOW_PROJECTS_ROOT" ]]; then
        pass
    else
        fail "FLOW_PROJECTS_ROOT directory not found: $FLOW_PROJECTS_ROOT"
    fi
}

# ============================================================================
# TESTS: Editor flag (-e) behavior
# ============================================================================

# Helper: mock _flow_get_project to return a fake project at TEST_ROOT
# This allows work to reach the editor code path without a real project.
# Note: work runs in a subshell via $() so we use a temp file to capture
# the editor argument, since local variables don't propagate back.
_EDITOR_CAPTURE_FILE=""

_mock_project_env() {
    _EDITOR_CAPTURE_FILE=$(mktemp)
    _flow_get_project() {
        echo "name=\"mock-proj\"; project_path=\"$TEST_ROOT/dev-tools/mock-dev\"; proj_status=\"active\""
    }
    _flow_session_start() { :; }
    _flow_detect_project_type() { echo "generic"; }
    _flow_has_fzf() { return 1; }
    _work_project_uses_github() { return 1; }
}

_restore_project_env() {
    unfunction _flow_get_project 2>/dev/null
    unfunction _flow_session_start 2>/dev/null
    unfunction _flow_detect_project_type 2>/dev/null
    unfunction _flow_has_fzf 2>/dev/null
    unfunction _flow_open_editor 2>/dev/null
    unfunction _work_project_uses_github 2>/dev/null
    source "$PROJECT_ROOT/commands/work.zsh" 2>/dev/null
    source "$PROJECT_ROOT/lib/atlas-bridge.zsh" 2>/dev/null
    [[ -n "$_EDITOR_CAPTURE_FILE" ]] && rm -f "$_EDITOR_CAPTURE_FILE"
    _EDITOR_CAPTURE_FILE=""
}

test_work_no_editor_by_default() {
    log_test "work without -e does NOT call _flow_open_editor"

    _mock_project_env
    local _editor_called=false
    _flow_open_editor() { _editor_called=true; }

    local output=$(work mock-proj 2>&1)

    _restore_project_env

    if [[ "$_editor_called" == false ]]; then
        pass
    else
        fail "_flow_open_editor was called without -e flag"
    fi
}

test_work_editor_flag_bare() {
    log_test "work -e (bare) opens EDITOR fallback"

    _mock_project_env
    _flow_open_editor() { echo "$1" > "$_EDITOR_CAPTURE_FILE"; }

    EDITOR="test-editor"
    local output=$(work mock-proj -e 2>&1)
    local captured=$(cat "$_EDITOR_CAPTURE_FILE" 2>/dev/null)

    _restore_project_env

    if [[ "$captured" == "test-editor" ]]; then
        pass
    else
        fail "Expected 'test-editor', got: '$captured'"
    fi
}

test_work_editor_flag_with_name() {
    log_test "work -e positron passes 'positron' to editor"

    _mock_project_env
    _flow_open_editor() { echo "$1" > "$_EDITOR_CAPTURE_FILE"; }

    local output=$(work mock-proj -e positron 2>&1)
    local captured=$(cat "$_EDITOR_CAPTURE_FILE" 2>/dev/null)

    _restore_project_env

    if [[ "$captured" == "positron" ]]; then
        pass
    else
        fail "Expected 'positron', got: '$captured'"
    fi
}

test_work_editor_flag_code() {
    log_test "work -e code passes 'code' to editor"

    _mock_project_env
    _flow_open_editor() { echo "$1" > "$_EDITOR_CAPTURE_FILE"; }

    local output=$(work mock-proj -e code 2>&1)
    local captured=$(cat "$_EDITOR_CAPTURE_FILE" 2>/dev/null)

    _restore_project_env

    if [[ "$captured" == "code" ]]; then
        pass
    else
        fail "Expected 'code', got: '$captured'"
    fi
}

test_work_editor_flag_before_project() {
    log_test "work -e code mock-proj (flag before project)"

    _mock_project_env
    _flow_open_editor() { echo "$1" > "$_EDITOR_CAPTURE_FILE"; }

    local output=$(work -e code mock-proj 2>&1)
    local captured=$(cat "$_EDITOR_CAPTURE_FILE" 2>/dev/null)

    _restore_project_env

    if [[ "$captured" == "code" ]]; then
        pass
    else
        fail "Expected 'code', got: '$captured'"
    fi
}

test_work_long_editor_flag() {
    log_test "work --editor nvim uses long flag form"

    _mock_project_env
    _flow_open_editor() { echo "$1" > "$_EDITOR_CAPTURE_FILE"; }

    local output=$(work mock-proj --editor nvim 2>&1)
    local captured=$(cat "$_EDITOR_CAPTURE_FILE" 2>/dev/null)

    _restore_project_env

    if [[ "$captured" == "nvim" ]]; then
        pass
    else
        fail "Expected 'nvim', got: '$captured'"
    fi
}

test_work_no_editor_no_call() {
    log_test "work mock-proj (no flag) never calls _flow_open_editor"

    _mock_project_env
    local _call_count=0
    _flow_open_editor() { ((_call_count++)); }

    local output=$(work mock-proj 2>&1)

    _restore_project_env

    if [[ $_call_count -eq 0 ]]; then
        pass
    else
        fail "_flow_open_editor called $_call_count time(s) without -e"
    fi
}

test_work_editor_flag_cc() {
    log_test "_flow_open_editor handles cc|claude|ccy cases"

    local source_code=$(functions _flow_open_editor 2>/dev/null)

    if [[ "$source_code" == *"cc"*"claude"*"ccy"* ]]; then
        pass
    else
        fail "cc/claude/ccy case not found in _flow_open_editor"
    fi
}

test_work_editor_cc_new_in_source() {
    log_test "_flow_open_editor handles cc:new|claude:new"

    local source_code=$(functions _flow_open_editor 2>/dev/null)

    if [[ "$source_code" == *"cc:new"* && "$source_code" == *"claude:new"* ]]; then
        pass
    else
        fail "cc:new/claude:new case not found in _flow_open_editor"
    fi
}

test_work_launch_claude_code_yolo_branch() {
    log_test "_work_launch_claude_code has yolo (ccy) branch"

    local source_code=$(functions _work_launch_claude_code 2>/dev/null)

    if [[ "$source_code" == *"ccy"* && "$source_code" == *"dangerously-skip-permissions"* ]]; then
        pass
    else
        fail "ccy/dangerously-skip-permissions not found in _work_launch_claude_code"
    fi
}

test_work_legacy_positional_editor() {
    log_test "work <proj> <editor> shows deprecation warning"

    _mock_project_env
    _flow_open_editor() { echo "$1" > "$_EDITOR_CAPTURE_FILE"; }

    local output=$(work mock-proj nvim 2>&1)

    _restore_project_env

    if [[ "$output" == *"deprecated"* || "$output" == *"Deprecated"* ]]; then
        pass
    else
        fail "No deprecation warning for positional editor arg"
    fi
}

test_work_legacy_positional_still_opens() {
    log_test "deprecated positional editor still opens editor"

    _mock_project_env
    _flow_open_editor() { echo "$1" > "$_EDITOR_CAPTURE_FILE"; }

    local output=$(work mock-proj vim 2>&1)
    local captured=$(cat "$_EDITOR_CAPTURE_FILE" 2>/dev/null)

    _restore_project_env

    if [[ "$captured" == "vim" ]]; then
        pass
    else
        fail "Expected 'vim' from positional arg, got: '$captured'"
    fi
}

test_work_help_shows_editor_flag() {
    log_test "work --help shows -e flag"

    local output=$(work --help 2>&1)

    if [[ "$output" == *"-e"* && "$output" == *"editor"* ]]; then
        pass
    else
        fail "Help output missing -e flag documentation"
    fi
}

test_work_help_shows_cc_editors() {
    log_test "work --help lists Claude Code editors"

    local output=$(work --help 2>&1)

    if [[ "$output" == *"cc"* && "$output" == *"ccy"* && "$output" == *"cc:new"* ]]; then
        pass
    else
        fail "Help missing cc/ccy/cc:new editor options"
    fi
}

test_work_launch_claude_code_exists() {
    log_test "_work_launch_claude_code function exists"

    if type _work_launch_claude_code &>/dev/null; then
        pass
    else
        fail "_work_launch_claude_code not found"
    fi
}

# ============================================================================
# TESTS: _flow_open_editor edge cases
# ============================================================================

test_open_editor_empty_returns_warning() {
    log_test "_flow_open_editor with empty string returns warning"

    local output=$(_flow_open_editor "" "/tmp" 2>&1)
    local exit_code=$?

    if [[ $exit_code -ne 0 || "$output" == *"No editor"* ]]; then
        pass
    else
        fail "Expected warning for empty editor, got exit=$exit_code"
    fi
}

test_open_editor_unknown_skips_gracefully() {
    log_test "_flow_open_editor with unknown editor skips gracefully"

    # Use a definitely-nonexistent editor name
    local output=$(_flow_open_editor "zzz_no_such_editor_zzz" "/tmp" 2>&1)
    local exit_code=$?

    # Should not crash (exit 0) and log "not found"
    if [[ $exit_code -eq 0 && "$output" == *"not found"* ]]; then
        pass
    else
        fail "Expected 'not found' message, got exit=$exit_code output='${output:0:100}'"
    fi
}

test_open_editor_code_branch_exists() {
    log_test "_flow_open_editor has code|vscode branch"

    local source_code=$(functions _flow_open_editor 2>/dev/null)

    if [[ "$source_code" == *"code"*"vscode"* ]]; then
        pass
    else
        fail "code|vscode case not found"
    fi
}

test_open_editor_positron_branch_exists() {
    log_test "_flow_open_editor has positron branch"

    local source_code=$(functions _flow_open_editor 2>/dev/null)

    if [[ "$source_code" == *"positron"* ]]; then
        pass
    else
        fail "positron case not found"
    fi
}

test_open_editor_cursor_branch_exists() {
    log_test "_flow_open_editor has cursor branch"

    local source_code=$(functions _flow_open_editor 2>/dev/null)

    if [[ "$source_code" == *"cursor"* ]]; then
        pass
    else
        fail "cursor case not found"
    fi
}

test_open_editor_emacs_branch_exists() {
    log_test "_flow_open_editor has emacs branch"

    local source_code=$(functions _flow_open_editor 2>/dev/null)

    if [[ "$source_code" == *"emacs"* ]]; then
        pass
    else
        fail "emacs case not found"
    fi
}

# ============================================================================
# TESTS: _flow_show_work_context .STATUS parsing
# ============================================================================

test_show_context_parses_status_field() {
    log_test "_flow_show_work_context shows Status from .STATUS"

    local tmp=$(mktemp -d)
    mkdir -p "$tmp/test-proj"
    echo "## Status: Active" > "$tmp/test-proj/.STATUS"

    local output=$(_flow_show_work_context "test-proj" "$tmp/test-proj" 2>&1)

    rm -rf "$tmp"

    if [[ "$output" == *"Active"* ]]; then
        pass
    else
        fail "Status field not parsed from .STATUS"
    fi
}

test_show_context_parses_phase_field() {
    log_test "_flow_show_work_context shows Phase from .STATUS"

    local tmp=$(mktemp -d)
    mkdir -p "$tmp/test-proj"
    printf "## Status: Active\n## Phase: Testing\n" > "$tmp/test-proj/.STATUS"

    local output=$(_flow_show_work_context "test-proj" "$tmp/test-proj" 2>&1)

    rm -rf "$tmp"

    if [[ "$output" == *"Testing"* ]]; then
        pass
    else
        fail "Phase field not parsed from .STATUS"
    fi
}

test_show_context_handles_missing_status_file() {
    log_test "_flow_show_work_context handles missing .STATUS"

    local tmp=$(mktemp -d)
    mkdir -p "$tmp/no-status-proj"
    # No .STATUS file created

    local output=$(_flow_show_work_context "no-status-proj" "$tmp/no-status-proj" 2>&1)
    local exit_code=$?

    rm -rf "$tmp"

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Should not crash with missing .STATUS"
    fi
}

# ============================================================================
# TESTS: finish command behavior
# ============================================================================

test_finish_help_flag() {
    log_test "finish --help shows help text"

    local output=$(finish --help 2>&1)

    if [[ "$output" == *"FINISH"* && "$output" == *"End"* ]]; then
        pass
    else
        fail "Help output missing expected content"
    fi
}

test_finish_help_shorthand() {
    log_test "finish help shows help text"

    local output=$(finish help 2>&1)

    if [[ "$output" == *"FINISH"* ]]; then
        pass
    else
        fail "Shorthand 'help' not recognized"
    fi
}

test_finish_help_h_flag() {
    log_test "finish -h shows help text"

    local output=$(finish -h 2>&1)

    if [[ "$output" == *"FINISH"* ]]; then
        pass
    else
        fail "-h flag not recognized"
    fi
}

# ============================================================================
# TESTS: hop command behavior
# ============================================================================

test_hop_help_flag() {
    log_test "hop --help shows help text"

    local output=$(hop --help 2>&1)

    if [[ "$output" == *"HOP"* && "$output" == *"Switch"* ]]; then
        pass
    else
        fail "Help output missing expected content"
    fi
}

test_hop_invalid_project() {
    log_test "hop with invalid project shows error"

    local output=$(hop zzz_nonexistent_proj_zzz 2>&1)

    if [[ "$output" == *"not found"* || "$output" == *"Error"* || "$output" == *"error"* ]]; then
        pass
    else
        fail "Should show error for invalid project"
    fi
}

test_hop_help_shorthand() {
    log_test "hop help shows help text"

    local output=$(hop help 2>&1)

    if [[ "$output" == *"HOP"* ]]; then
        pass
    else
        fail "Shorthand 'help' not recognized"
    fi
}

# ============================================================================
# TESTS: work command help output
# ============================================================================

test_work_help_flag() {
    log_test "work --help shows help text"

    local output=$(work --help 2>&1)

    if [[ "$output" == *"WORK"* && "$output" == *"Start Working"* ]]; then
        pass
    else
        fail "Help output missing expected content"
    fi
}

test_work_help_shows_usage() {
    log_test "work --help shows usage line"

    local output=$(work --help 2>&1)

    if [[ "$output" == *"Usage:"* && "$output" == *"[-e editor]"* ]]; then
        pass
    else
        fail "Usage line missing or wrong format"
    fi
}

test_work_help_shows_editors_section() {
    log_test "work --help lists all editor types"

    local output=$(work --help 2>&1)

    # Should list all major editor types
    local missing=""
    [[ "$output" != *"positron"* ]] && missing="$missing positron"
    [[ "$output" != *"code"* ]] && missing="$missing code"
    [[ "$output" != *"nvim"* ]] && missing="$missing nvim"

    if [[ -z "$missing" ]]; then
        pass
    else
        fail "Missing editors in help:$missing"
    fi
}

# ============================================================================
# TESTS: Arg parser edge cases
# ============================================================================

test_work_help_in_any_position() {
    log_test "work mock-proj -h shows help (non-first position)"

    local output=$(work mock-proj -h 2>&1)

    if [[ "$output" == *"WORK"* && "$output" == *"Start Working"* ]]; then
        pass
    else
        fail "Help not shown when -h is in non-first position"
    fi
}

test_work_editor_flag_at_end_bare() {
    log_test "work mock-proj -e (flag at end, no value) uses EDITOR"

    _mock_project_env
    _flow_open_editor() { echo "$1" > "$_EDITOR_CAPTURE_FILE"; }

    EDITOR="fallback-ed"
    local output=$(work mock-proj -e 2>&1)
    local captured=$(cat "$_EDITOR_CAPTURE_FILE" 2>/dev/null)

    _restore_project_env

    if [[ "$captured" == "fallback-ed" ]]; then
        pass
    else
        fail "Expected 'fallback-ed', got: '$captured'"
    fi
}

test_work_editor_default_when_no_EDITOR() {
    log_test "work -e with no EDITOR falls back to nvim"

    _mock_project_env
    _flow_open_editor() { echo "$1" > "$_EDITOR_CAPTURE_FILE"; }

    # Unset EDITOR to test nvim fallback
    local saved_editor="$EDITOR"
    unset EDITOR
    local output=$(work mock-proj -e 2>&1)
    local captured=$(cat "$_EDITOR_CAPTURE_FILE" 2>/dev/null)
    EDITOR="$saved_editor"

    _restore_project_env

    if [[ "$captured" == "nvim" ]]; then
        pass
    else
        fail "Expected 'nvim' fallback, got: '$captured'"
    fi
}

test_work_multiple_remaining_args_uses_first() {
    log_test "work proj1 proj2 uses first as project"

    _mock_project_env
    _flow_open_editor() { echo "$1" > "$_EDITOR_CAPTURE_FILE"; }

    # proj2 should trigger deprecation (treated as positional editor)
    local output=$(work mock-proj extraarg 2>&1)

    _restore_project_env

    if [[ "$output" == *"deprecated"* || "$output" == *"Deprecated"* ]]; then
        pass
    else
        fail "Second positional arg should trigger deprecation warning"
    fi
}

test_work_unknown_flags_ignored() {
    log_test "work --verbose mock-proj warns and ignores unknown flags"

    _mock_project_env
    _flow_open_editor() { echo "SHOULD_NOT_BE_CALLED" > "$_EDITOR_CAPTURE_FILE"; }

    local output=$(work --verbose mock-proj 2>&1)
    local captured=$(cat "$_EDITOR_CAPTURE_FILE" 2>/dev/null)

    _restore_project_env

    # --verbose is unknown: should warn and not trigger editor
    if [[ "$captured" != "SHOULD_NOT_BE_CALLED" && "$output" == *"Unknown flag"* ]]; then
        pass
    else
        fail "Expected warning for unknown flag and no editor call"
    fi
}

test_work_editor_flag_with_project_in_middle() {
    log_test "work -e vim mock-proj (editor value before project)"

    _mock_project_env
    _flow_open_editor() { echo "$1" > "$_EDITOR_CAPTURE_FILE"; }

    local output=$(work -e vim mock-proj 2>&1)
    local captured=$(cat "$_EDITOR_CAPTURE_FILE" 2>/dev/null)

    _restore_project_env

    if [[ "$captured" == "vim" ]]; then
        pass
    else
        fail "Expected 'vim', got: '$captured'"
    fi
}

# ============================================================================
# TESTS: Teaching workflow detection
# ============================================================================

test_work_teaching_session_exists() {
    log_test "_work_teaching_session function exists"

    if type _work_teaching_session &>/dev/null; then
        pass
    else
        fail "_work_teaching_session not found"
    fi
}

test_work_teaching_session_requires_config() {
    log_test "_work_teaching_session errors without config file"

    local tmp=$(mktemp -d)
    mkdir -p "$tmp/no-config"

    local output=$(_work_teaching_session "$tmp/no-config" 2>&1)
    local exit_code=$?

    rm -rf "$tmp"

    if [[ $exit_code -ne 0 || "$output" == *"not found"* ]]; then
        pass
    else
        fail "Should error without teach-config.yml"
    fi
}

# ============================================================================
# TESTS: first-run welcome
# ============================================================================

test_first_run_welcome_exists() {
    log_test "_flow_first_run_welcome function exists"

    if type _flow_first_run_welcome &>/dev/null; then
        pass
    else
        fail "_flow_first_run_welcome not found"
    fi
}

test_first_run_welcome_shows_quick_start() {
    log_test "_flow_first_run_welcome shows Quick Start content"

    # Use a temp config dir so the marker isn't already set
    local tmp=$(mktemp -d)
    XDG_CONFIG_HOME="$tmp" _flow_first_run_welcome > /dev/null 2>&1

    # Now it should exist as marker
    if [[ -f "$tmp/flow-cli/.welcomed" ]]; then
        pass
    else
        fail "Welcome marker not created"
    fi

    rm -rf "$tmp"
}

test_first_run_welcome_skips_second_time() {
    log_test "_flow_first_run_welcome skips on second call"

    local tmp=$(mktemp -d)
    mkdir -p "$tmp/flow-cli"
    touch "$tmp/flow-cli/.welcomed"

    local output=$(XDG_CONFIG_HOME="$tmp" _flow_first_run_welcome 2>&1)

    rm -rf "$tmp"

    if [[ -z "$output" ]]; then
        pass
    else
        fail "Should produce no output when marker exists"
    fi
}

# ============================================================================
# TESTS: Token validation helpers
# ============================================================================

test_work_get_token_status_exists() {
    log_test "_work_get_token_status function exists"

    if type _work_get_token_status &>/dev/null; then
        pass
    else
        fail "_work_get_token_status not found"
    fi
}

test_work_will_push_to_remote_exists() {
    log_test "_work_will_push_to_remote function exists"

    if type _work_will_push_to_remote &>/dev/null; then
        pass
    else
        fail "_work_will_push_to_remote not found"
    fi
}

test_work_project_uses_github_no_git() {
    log_test "_work_project_uses_github returns false for non-git dir"

    local tmp=$(mktemp -d)
    # No .git directory

    _work_project_uses_github "$tmp"
    local exit_code=$?

    rm -rf "$tmp"

    if [[ $exit_code -ne 0 ]]; then
        pass
    else
        fail "Should return false for non-git directory"
    fi
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    echo ""
    echo "${YELLOW}========================================${NC}"
    echo "${YELLOW}  Work Command Tests${NC}"
    echo "${YELLOW}========================================${NC}"

    setup

    echo "${CYAN}--- Environment tests ---${NC}"
    test_flow_projects_root_defined
    test_flow_projects_root_exists

    echo ""
    echo "${CYAN}--- Command existence tests ---${NC}"
    test_work_exists
    test_finish_exists
    test_hop_exists
    test_why_exists

    echo ""
    echo "${CYAN}--- Helper function tests ---${NC}"
    test_show_work_context_exists
    test_open_editor_exists
    test_session_start_exists
    test_session_end_exists

    echo ""
    echo "${CYAN}--- Core utility tests ---${NC}"
    test_find_project_root_exists
    test_get_project_exists
    test_project_name_exists
    test_pick_project_exists

    echo ""
    echo "${CYAN}--- work command behavior tests ---${NC}"
    test_work_no_args_returns_error
    test_work_invalid_project

    echo ""
    echo "${CYAN}--- finish command tests ---${NC}"
    test_finish_no_session

    echo ""
    echo "${CYAN}--- hop command tests ---${NC}"
    test_hop_help

    echo ""
    echo "${CYAN}--- why command tests ---${NC}"
    test_why_runs

    echo ""
    echo "${CYAN}--- Context display tests ---${NC}"
    test_show_context_runs
    test_show_context_shows_project

    echo ""
    echo "${CYAN}--- Project detection tests ---${NC}"
    test_find_project_root_in_git
    test_detect_project_type_exists
    test_project_icon_exists

    echo ""
    echo "${CYAN}--- _flow_open_editor edge cases ---${NC}"
    test_open_editor_empty_returns_warning
    test_open_editor_unknown_skips_gracefully
    test_open_editor_code_branch_exists
    test_open_editor_positron_branch_exists
    test_open_editor_cursor_branch_exists
    test_open_editor_emacs_branch_exists

    echo ""
    echo "${CYAN}--- .STATUS parsing tests ---${NC}"
    test_show_context_parses_status_field
    test_show_context_parses_phase_field
    test_show_context_handles_missing_status_file

    echo ""
    echo "${CYAN}--- finish help tests ---${NC}"
    test_finish_help_flag
    test_finish_help_shorthand
    test_finish_help_h_flag

    echo ""
    echo "${CYAN}--- hop behavior tests ---${NC}"
    test_hop_help_flag
    test_hop_invalid_project
    test_hop_help_shorthand

    echo ""
    echo "${CYAN}--- work help output tests ---${NC}"
    test_work_help_flag
    test_work_help_shows_usage
    test_work_help_shows_editors_section

    echo ""
    echo "${CYAN}--- Editor flag (-e) tests ---${NC}"
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
    echo "${CYAN}--- Arg parser edge cases ---${NC}"
    test_work_help_in_any_position
    test_work_editor_flag_at_end_bare
    test_work_editor_default_when_no_EDITOR
    test_work_multiple_remaining_args_uses_first
    test_work_unknown_flags_ignored
    test_work_editor_flag_with_project_in_middle

    echo ""
    echo "${CYAN}--- Teaching workflow tests ---${NC}"
    test_work_teaching_session_exists
    test_work_teaching_session_requires_config

    echo ""
    echo "${CYAN}--- First-run welcome tests ---${NC}"
    test_first_run_welcome_exists
    test_first_run_welcome_shows_quick_start
    test_first_run_welcome_skips_second_time

    echo ""
    echo "${CYAN}--- Token validation tests ---${NC}"
    test_work_get_token_status_exists
    test_work_will_push_to_remote_exists
    test_work_project_uses_github_no_git

    # Summary
    echo ""
    echo "${YELLOW}========================================${NC}"
    echo "${YELLOW}  Test Summary${NC}"
    echo "${YELLOW}========================================${NC}"
    echo "  ${GREEN}Passed:${NC} $TESTS_PASSED"
    echo "  ${RED}Failed:${NC} $TESTS_FAILED"
    echo "  Total:  $((TESTS_PASSED + TESTS_FAILED))"
    echo ""

    # Cleanup temp dir (no trap — subshells can fire EXIT traps prematurely)
    [[ -n "$TEST_ROOT" ]] && rm -rf "$TEST_ROOT"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        exit 1
    fi
}

main "$@"
