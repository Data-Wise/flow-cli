#!/usr/bin/env zsh
# tests/test-teach-dispatcher-characterization.zsh
#
# Purpose: Capture the public command routing of `teach` before splitting
#          lib/dispatchers/teach-dispatcher.zsh into modules.
#
# Strategy: Source the full plugin, mock every action function, call `teach <cmd>`,
#           and assert the right mock was invoked. No external tools are run.
#
# NOTE: Do not use command substitution ($(...)) around `teach` calls when
#       checking mock call counts — zsh runs the command in a subshell, so
#       the global MOCK_CALLS counter in the parent shell is not updated.

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

export FLOW_QUIET=1
export FLOW_ATLAS_ENABLED=no
source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null

test_suite_start "teach dispatcher characterization"

# ── helpers ──────────────────────────────────────────────────────────────────

_mock_action_fns=(
    _teach_scholar_wrapper
    _teach_init
    _teach_deploy_enhanced
    _teach_archive_command
    _teach_config_edit
    _teach_config_view
    _teach_config_cat
    _teach_show_status
    _teach_show_week
    _teach_backup_command
    _teach_plan
    _teach_migrate_config
    _teach_doctor
    _teach_analyze
    _teach_profiles
    _install_git_hooks
    _upgrade_git_hooks
    _uninstall_git_hooks
    _check_all_hooks
    _teach_templates
    _teach_macros
    _teach_prompt
    _teach_style
    _teach_map
    teach-validate
    teach_cache
    teach_clean
)

_mock_help_fns=(
    _teach_dispatcher_help
    _teach_lecture_help
    _teach_slides_help
    _teach_exam_help
    _teach_quiz_help
    _teach_assignment_help
    _teach_syllabus_help
    _teach_rubric_help
    _teach_feedback_help
    _teach_init_help
    _teach_deploy_enhanced_help
    _teach_config_help
    _teach_status_help
    _teach_week_help
    _teach_backup_help
    _teach_plan_help
    _teach_migrate_help
    _teach_doctor_help
    _teach_validate_help
    _teach_analyze_help
    _teach_cache_help
    _teach_clean_help
    _teach_profiles_help
    _teach_hooks_help
    _teach_templates_help
    _teach_macros_help
    _teach_prompt_help
    _teach_style_help
    _teach_scholar_help
)

_TEACH_OUT=""

_setup_mocks() {
    create_mock "_teach_health_dot" "echo ''"
    for fn in "${_mock_action_fns[@]}"; do
        create_mock "$fn" "return 0"
    done
    for fn in "${_mock_help_fns[@]}"; do
        create_mock "$fn" "return 0"
    done
}

_capture_teach() {
    _TEACH_OUT="$(mktemp -t teach-char.XXXXXX)"
    "$@" >"$_TEACH_OUT" 2>&1
    local rc=$?
    return $rc
}

_read_teach_out() {
    [[ -f "$_TEACH_OUT" ]] && cat "$_TEACH_OUT"
}

_teardown_mocks() {
    reset_mocks
    [[ -f "$_TEACH_OUT" ]] && rm -f "$_TEACH_OUT"
    _TEACH_OUT=""
}

# ── tests ────────────────────────────────────────────────────────────────────

test_case "teach with no args shows dispatcher help"
_setup_mocks
teach >/dev/null 2>&1
assert_mock_called "_teach_dispatcher_help" 1 || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach help shows dispatcher help"
_setup_mocks
teach help >/dev/null 2>&1
assert_mock_called "_teach_dispatcher_help" 1 || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach lecture routes to scholar wrapper"
_setup_mocks
teach lecture "Topic" >/dev/null 2>&1
assert_mock_called "_teach_scholar_wrapper" 1 || { _teardown_mocks; return; }
assert_mock_args "_teach_scholar_wrapper" "lecture Topic" || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach slides routes to scholar wrapper"
_setup_mocks
teach slides "Week 1" >/dev/null 2>&1
assert_mock_called "_teach_scholar_wrapper" 1 || { _teardown_mocks; return; }
assert_mock_args "_teach_scholar_wrapper" "slides Week 1" || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach exam routes to scholar wrapper"
_setup_mocks
teach exam "Midterm" >/dev/null 2>&1
assert_mock_called "_teach_scholar_wrapper" 1 || { _teardown_mocks; return; }
assert_mock_args "_teach_scholar_wrapper" "exam Midterm" || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach quiz routes to scholar wrapper"
_setup_mocks
teach quiz "Q1" >/dev/null 2>&1
assert_mock_called "_teach_scholar_wrapper" 1 || { _teardown_mocks; return; }
assert_mock_args "_teach_scholar_wrapper" "quiz Q1" || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach assignment routes to scholar wrapper"
_setup_mocks
teach assignment "HW1" >/dev/null 2>&1
assert_mock_called "_teach_scholar_wrapper" 1 || { _teardown_mocks; return; }
assert_mock_args "_teach_scholar_wrapper" "assignment HW1" || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach syllabus routes to scholar wrapper"
_setup_mocks
teach syllabus "STAT-101" >/dev/null 2>&1
assert_mock_called "_teach_scholar_wrapper" 1 || { _teardown_mocks; return; }
assert_mock_args "_teach_scholar_wrapper" "syllabus STAT-101" || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach rubric routes to scholar wrapper"
_setup_mocks
teach rubric "Project" >/dev/null 2>&1
assert_mock_called "_teach_scholar_wrapper" 1 || { _teardown_mocks; return; }
assert_mock_args "_teach_scholar_wrapper" "rubric Project" || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach feedback routes to scholar wrapper"
_setup_mocks
teach feedback "Draft" >/dev/null 2>&1
assert_mock_called "_teach_scholar_wrapper" 1 || { _teardown_mocks; return; }
assert_mock_args "_teach_scholar_wrapper" "feedback Draft" || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach demo routes to scholar wrapper"
_setup_mocks
teach demo "Demo" >/dev/null 2>&1
assert_mock_called "_teach_scholar_wrapper" 1 || { _teardown_mocks; return; }
assert_mock_args "_teach_scholar_wrapper" "demo Demo" || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach solution routes to scholar wrapper"
_setup_mocks
teach solution "HW1" >/dev/null 2>&1
assert_mock_called "_teach_scholar_wrapper" 1 || { _teardown_mocks; return; }
assert_mock_args "_teach_scholar_wrapper" "solution HW1" || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach sync routes to scholar wrapper"
_setup_mocks
teach sync >/dev/null 2>&1
assert_mock_called "_teach_scholar_wrapper" 1 || { _teardown_mocks; return; }
assert_mock_args "_teach_scholar_wrapper" "sync" || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach validate-r routes to scholar wrapper"
_setup_mocks
teach validate-r >/dev/null 2>&1
assert_mock_called "_teach_scholar_wrapper" 1 || { _teardown_mocks; return; }
assert_mock_args "_teach_scholar_wrapper" "validate-r" || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach init routes to _teach_init"
_setup_mocks
teach init >/dev/null 2>&1
assert_mock_called "_teach_init" 1 || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach deploy routes to _teach_deploy_enhanced"
_setup_mocks
teach deploy --direct >/dev/null 2>&1
assert_mock_called "_teach_deploy_enhanced" 1 || { _teardown_mocks; return; }
assert_mock_args "_teach_deploy_enhanced" "--direct" || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach archive routes to _teach_archive_command"
_setup_mocks
teach archive >/dev/null 2>&1
assert_mock_called "_teach_archive_command" 1 || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach config check routes to scholar wrapper"
_setup_mocks
teach config check >/dev/null 2>&1
assert_mock_called "_teach_scholar_wrapper" 1 || { _teardown_mocks; return; }
assert_mock_args "_teach_scholar_wrapper" "config validate --strict" || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach status routes to _teach_show_status"
_setup_mocks
teach status >/dev/null 2>&1
assert_mock_called "_teach_show_status" 1 || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach backup routes to _teach_backup_command"
_setup_mocks
teach backup list >/dev/null 2>&1
assert_mock_called "_teach_backup_command" 1 || { _teardown_mocks; return; }
assert_mock_args "_teach_backup_command" "list" || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach plan routes to _teach_plan"
_setup_mocks
teach plan "Topic" >/dev/null 2>&1
assert_mock_called "_teach_plan" 1 || { _teardown_mocks; return; }
assert_mock_args "_teach_plan" "Topic" || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach migrate routes to _teach_migrate_config"
_setup_mocks
teach migrate >/dev/null 2>&1
assert_mock_called "_teach_migrate_config" 1 || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach doctor routes to _teach_doctor"
_setup_mocks
teach doctor >/dev/null 2>&1
assert_mock_called "_teach_doctor" 1 || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach validate routes to teach-validate"
_setup_mocks
teach validate >/dev/null 2>&1
assert_mock_called "teach-validate" 1 || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach analyze routes to _teach_analyze"
_setup_mocks
teach analyze "file.qmd" >/dev/null 2>&1
assert_mock_called "_teach_analyze" 1 || { _teardown_mocks; return; }
assert_mock_args "_teach_analyze" "file.qmd" || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach cache routes to teach_cache"
_setup_mocks
teach cache list >/dev/null 2>&1
assert_mock_called "teach_cache" 1 || { _teardown_mocks; return; }
assert_mock_args "teach_cache" "list" || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach clean routes to teach_clean"
_setup_mocks
teach clean >/dev/null 2>&1
assert_mock_called "teach_clean" 1 || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach profiles routes to _teach_profiles"
_setup_mocks
teach profiles list >/dev/null 2>&1
assert_mock_called "_teach_profiles" 1 || { _teardown_mocks; return; }
assert_mock_args "_teach_profiles" "list" || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach hooks install routes to _install_git_hooks"
_setup_mocks
teach hooks install >/dev/null 2>&1
assert_mock_called "_install_git_hooks" 1 || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach templates routes to _teach_templates"
_setup_mocks
teach templates list >/dev/null 2>&1
assert_mock_called "_teach_templates" 1 || { _teardown_mocks; return; }
assert_mock_args "_teach_templates" "list" || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach macros routes to _teach_macros"
_setup_mocks
teach macros list >/dev/null 2>&1
assert_mock_called "_teach_macros" 1 || { _teardown_mocks; return; }
assert_mock_args "_teach_macros" "list" || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach prompt routes to _teach_prompt"
_setup_mocks
teach prompt list >/dev/null 2>&1
assert_mock_called "_teach_prompt" 1 || { _teardown_mocks; return; }
assert_mock_args "_teach_prompt" "list" || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach style routes to _teach_style"
_setup_mocks
teach style show >/dev/null 2>&1
assert_mock_called "_teach_style" 1 || { _teardown_mocks; return; }
assert_mock_args "_teach_style" "show" || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach map routes to _teach_map"
_setup_mocks
teach map >/dev/null 2>&1
assert_mock_called "_teach_map" 1 || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_case "teach unknown command errors and shows help"
_setup_mocks
local rc
_capture_teach teach boguscmd
rc=$?
assert_equals "$rc" "1" "unknown command should exit 1" || { _teardown_mocks; return; }
assert_mock_called "_teach_dispatcher_help" 1 || { _teardown_mocks; return; }
_teardown_mocks
test_pass

test_suite_end
