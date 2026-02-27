#!/usr/bin/env zsh
# tests/test-em-help-guards.zsh - Verify all em subcommands respond to help flags

PROJECT_ROOT="${0:A:h:h}"
source "${0:A:h}/test-framework.zsh"

test_suite "Em Help Guard Tests"

# Mock dependencies so tests run without himalaya
_em_require_himalaya() { return 1; }
_em_validate_msg_id() { return 0; }
_em_validate_folder_name() { return 0; }
_flow_log_error() { :; }
_flow_log_success() { :; }
_flow_log_info() { :; }
_em_hml_list() { echo '[]'; }
_em_hml_folders() { :; }
_em_cache_prune() { :; }
_em_cache_stats() { :; }
_em_cache_clear() { :; }
_em_cache_warm() { :; }
_em_render_inbox_json() { :; }
_em_hml_unread_count() { echo "0"; }
_em_load_config() { :; }
_em_ai_status() { :; }
_em_ai_toggle() { :; }
_em_ai_switch() { :; }

# Source the dispatcher and AI module
source "${PROJECT_ROOT}/lib/dispatchers/email-dispatcher.zsh" 2>/dev/null
source "${PROJECT_ROOT}/lib/em-ai.zsh" 2>/dev/null

# Track help calls
HELP_CALLED=0
_em_help() { HELP_CALLED=1; }
_em_delete_help() { HELP_CALLED=1; }
_em_move_help() { HELP_CALLED=1; }
_em_restore_help() { HELP_CALLED=1; }
_em_respond_help() { HELP_CALLED=1; }

# All subcommands to test
typeset -a test_pairs
test_pairs=(
    "inbox:_em_inbox"
    "find:_em_find"
    "pick:_em_pick"
    "catch:_em_catch"
    "flag:_em_flag"
    "unflag:_em_unflag"
    "todo:_em_todo"
    "event:_em_event"
    "star:_em_star"
    "starred:_em_starred"
    "thread:_em_thread"
    "snooze:_em_snooze"
    "snoozed:_em_snoozed"
    "digest:_em_digest"
    "unread:_em_unread"
    "dash:_em_dash"
    "folders:_em_folders"
    "create-folder:_em_create_folder"
    "delete-folder:_em_delete_folder"
    "cache:_em_cache_cmd"
    "doctor:_em_doctor"
    "read:_em_read"
    "send:_em_send"
    "reply:_em_reply"
    "forward:_em_forward"
    "classify:_em_classify"
    "summarize:_em_summarize"
    "delete:_em_delete"
    "move:_em_move"
    "restore:_em_restore"
    "html:_em_html"
    "attach:_em_attach"
    "respond:_em_respond"
    "ai:_em_ai_cmd"
)

for pair in "${test_pairs[@]}"; do
    local subcmd="${pair%%:*}"
    local fn="${pair##*:}"

    for flag in "--help" "-h" "help"; do
        test_case "em $subcmd $flag shows help"
        HELP_CALLED=0
        $fn "$flag" 2>/dev/null
        if [[ $HELP_CALLED -eq 1 ]]; then
            test_pass
        else
            test_fail "em $subcmd $flag did not trigger help"
        fi
    done
done

test_suite_end
print_summary
exit $(( TESTS_FAILED > 0 ? 1 : 0 ))
