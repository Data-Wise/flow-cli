#!/usr/bin/env zsh
# Test script for em email dispatcher
# Tests: help, subcommand detection, function existence, module loading

TESTS_PASSED=0
TESTS_FAILED=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_test() { echo -n "${CYAN}Testing:${NC} $1 ... " }
pass() { echo "${GREEN}✓ PASS${NC}"; ((TESTS_PASSED++)) }
fail() { echo "${RED}✗ FAIL${NC} - $1"; ((TESTS_FAILED++)) }

# Setup function - source plugin in non-interactive mode
setup() {
    typeset -g project_root=""
    if [[ -n "${0:A}" ]]; then project_root="${0:A:h:h}"; fi
    if [[ -z "$project_root" || ! -f "$project_root/flow.plugin.zsh" ]]; then
        if [[ -f "$PWD/flow.plugin.zsh" ]]; then project_root="$PWD"
        elif [[ -f "$PWD/../flow.plugin.zsh" ]]; then project_root="$PWD/.."
        fi
    fi
    [[ -z "$project_root" || ! -f "$project_root/flow.plugin.zsh" ]] && { echo "${RED}ERROR: Cannot find project root${NC}"; exit 1; }

    FLOW_QUIET=1
    FLOW_ATLAS_ENABLED=no
    FLOW_PLUGIN_DIR="$project_root"
    exec < /dev/null  # Non-interactive
    source "$project_root/flow.plugin.zsh"
}

# ═══════════════════════════════════════════════════════════════
# Section 1: Dispatcher Function Existence
# ═══════════════════════════════════════════════════════════════

test_em_dispatcher_exists() {
    log_test "em dispatcher function exists"
    if (( ${+functions[em]} )); then
        pass
    else
        fail "em function not defined"
    fi
}

test_em_help_function_exists() {
    log_test "_em_help function exists"
    if (( ${+functions[_em_help]} )); then
        pass
    else
        fail "_em_help function not defined"
    fi
}

test_em_preview_message_exists() {
    log_test "_em_preview_message function exists"
    if (( ${+functions[_em_preview_message]} )); then
        pass
    else
        fail "_em_preview_message function not defined"
    fi
}

# ═══════════════════════════════════════════════════════════════
# Section 2: Help Output
# ═══════════════════════════════════════════════════════════════

test_em_help_output() {
    log_test "em help produces output"
    local output=$(em help 2>&1)
    if [[ -n "$output" && "$output" == *"Email Dispatcher"* ]]; then
        pass
    else
        fail "help output missing or incorrect"
    fi
}

test_em_help_flag() {
    log_test "em --help works"
    local output=$(em --help 2>&1)
    if [[ -n "$output" && "$output" == *"Email Dispatcher"* ]]; then
        pass
    else
        fail "--help flag not working"
    fi
}

test_em_help_short_flag() {
    log_test "em -h works"
    local output=$(em -h 2>&1)
    if [[ -n "$output" && "$output" == *"Email Dispatcher"* ]]; then
        pass
    else
        fail "-h flag not working"
    fi
}

test_em_help_subcommands() {
    log_test "help shows key subcommands"
    local output=$(em help 2>&1)
    local missing=()

    [[ "$output" != *"inbox"* ]] && missing+=("inbox")
    [[ "$output" != *"read"* ]] && missing+=("read")
    [[ "$output" != *"send"* ]] && missing+=("send")
    [[ "$output" != *"reply"* ]] && missing+=("reply")
    [[ "$output" != *"find"* ]] && missing+=("find")
    [[ "$output" != *"pick"* ]] && missing+=("pick")
    [[ "$output" != *"respond"* ]] && missing+=("respond")
    [[ "$output" != *"classify"* ]] && missing+=("classify")
    [[ "$output" != *"summarize"* ]] && missing+=("summarize")
    [[ "$output" != *"cache"* ]] && missing+=("cache")
    [[ "$output" != *"doctor"* ]] && missing+=("doctor")

    if [[ ${#missing[@]} -eq 0 ]]; then
        pass
    else
        fail "missing subcommands: ${missing[*]}"
    fi
}

# ═══════════════════════════════════════════════════════════════
# Section 3: Himalaya Adapter Functions
# ═══════════════════════════════════════════════════════════════

test_em_himalaya_check_exists() {
    log_test "_em_hml_check exists"
    if (( ${+functions[_em_hml_check]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_himalaya_list_exists() {
    log_test "_em_hml_list exists"
    if (( ${+functions[_em_hml_list]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_himalaya_read_exists() {
    log_test "_em_hml_read exists"
    if (( ${+functions[_em_hml_read]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_himalaya_send_exists() {
    log_test "_em_hml_send exists"
    if (( ${+functions[_em_hml_send]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_himalaya_reply_exists() {
    log_test "_em_hml_reply exists"
    if (( ${+functions[_em_hml_reply]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_himalaya_template_reply_exists() {
    log_test "_em_hml_template_reply exists"
    if (( ${+functions[_em_hml_template_reply]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_himalaya_template_write_exists() {
    log_test "_em_hml_template_write exists"
    if (( ${+functions[_em_hml_template_write]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_himalaya_template_send_exists() {
    log_test "_em_hml_template_send exists"
    if (( ${+functions[_em_hml_template_send]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_himalaya_search_exists() {
    log_test "_em_hml_search exists"
    if (( ${+functions[_em_hml_search]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_himalaya_folders_exists() {
    log_test "_em_hml_folders exists"
    if (( ${+functions[_em_hml_folders]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_himalaya_unread_count_exists() {
    log_test "_em_hml_unread_count exists"
    if (( ${+functions[_em_hml_unread_count]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_himalaya_attachments_exists() {
    log_test "_em_hml_attachments exists"
    if (( ${+functions[_em_hml_attachments]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_himalaya_flags_exists() {
    log_test "_em_hml_flags exists"
    if (( ${+functions[_em_hml_flags]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_himalaya_idle_exists() {
    log_test "_em_hml_idle exists"
    if (( ${+functions[_em_hml_idle]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_mml_inject_body_exists() {
    log_test "_em_mml_inject_body exists"
    if (( ${+functions[_em_mml_inject_body]} )); then
        pass
    else
        fail "function not defined"
    fi
}

# ═══════════════════════════════════════════════════════════════
# Section 4: AI Layer Functions
# ═══════════════════════════════════════════════════════════════

test_em_ai_query_exists() {
    log_test "_em_ai_query exists"
    if (( ${+functions[_em_ai_query]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_ai_execute_exists() {
    log_test "_em_ai_execute exists"
    if (( ${+functions[_em_ai_execute]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_ai_backend_for_op_exists() {
    log_test "_em_ai_backend_for_op exists"
    if (( ${+functions[_em_ai_backend_for_op]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_ai_timeout_for_op_exists() {
    log_test "_em_ai_timeout_for_op exists"
    if (( ${+functions[_em_ai_timeout_for_op]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_ai_fallback_chain_exists() {
    log_test "_em_ai_fallback_chain exists"
    if (( ${+functions[_em_ai_fallback_chain]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_ai_available_exists() {
    log_test "_em_ai_available exists"
    if (( ${+functions[_em_ai_available]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_ai_classify_prompt_exists() {
    log_test "_em_ai_classify_prompt exists"
    if (( ${+functions[_em_ai_classify_prompt]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_ai_summarize_prompt_exists() {
    log_test "_em_ai_summarize_prompt exists"
    if (( ${+functions[_em_ai_summarize_prompt]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_ai_draft_prompt_exists() {
    log_test "_em_ai_draft_prompt exists"
    if (( ${+functions[_em_ai_draft_prompt]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_ai_schedule_prompt_exists() {
    log_test "_em_ai_schedule_prompt exists"
    if (( ${+functions[_em_ai_schedule_prompt]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_category_icon_exists() {
    log_test "_em_category_icon exists"
    if (( ${+functions[_em_category_icon]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_ai_classify_prompt_content() {
    log_test "_em_ai_classify_prompt returns classification text"
    local output=$(_em_ai_classify_prompt 2>&1)
    if [[ "$output" == *"Classify"* ]]; then
        pass
    else
        fail "prompt does not contain 'Classify'"
    fi
}

test_em_ai_summarize_prompt_content() {
    log_test "_em_ai_summarize_prompt returns summary text"
    local output=$(_em_ai_summarize_prompt 2>&1)
    if [[ "$output" == *"Summarize"* ]]; then
        pass
    else
        fail "prompt does not contain 'Summarize'"
    fi
}

test_em_ai_timeout_classify() {
    log_test "_em_ai_timeout_for_op classify returns number"
    local timeout=$(_em_ai_timeout_for_op classify 2>&1)
    if [[ "$timeout" =~ ^[0-9]+$ && "$timeout" -eq 10 ]]; then
        pass
    else
        fail "expected 10, got '$timeout'"
    fi
}

test_em_ai_timeout_draft() {
    log_test "_em_ai_timeout_for_op draft returns number"
    local timeout=$(_em_ai_timeout_for_op draft 2>&1)
    if [[ "$timeout" =~ ^[0-9]+$ && "$timeout" -eq 30 ]]; then
        pass
    else
        fail "expected 30, got '$timeout'"
    fi
}

test_em_category_icon_student() {
    log_test "_em_category_icon student-question returns icon"
    local icon=$(_em_category_icon student-question 2>&1)
    if [[ -n "$icon" ]]; then
        pass
    else
        fail "no icon returned"
    fi
}

test_em_category_icon_urgent() {
    log_test "_em_category_icon urgent returns icon"
    local icon=$(_em_category_icon urgent 2>&1)
    if [[ -n "$icon" ]]; then
        pass
    else
        fail "no icon returned"
    fi
}

# ═══════════════════════════════════════════════════════════════
# Section 5: Cache Functions
# ═══════════════════════════════════════════════════════════════

test_em_cache_dir_exists() {
    log_test "_em_cache_dir exists"
    if (( ${+functions[_em_cache_dir]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_cache_key_exists() {
    log_test "_em_cache_key exists"
    if (( ${+functions[_em_cache_key]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_cache_get_exists() {
    log_test "_em_cache_get exists"
    if (( ${+functions[_em_cache_get]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_cache_set_exists() {
    log_test "_em_cache_set exists"
    if (( ${+functions[_em_cache_set]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_cache_invalidate_exists() {
    log_test "_em_cache_invalidate exists"
    if (( ${+functions[_em_cache_invalidate]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_cache_clear_exists() {
    log_test "_em_cache_clear exists"
    if (( ${+functions[_em_cache_clear]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_cache_stats_exists() {
    log_test "_em_cache_stats exists"
    if (( ${+functions[_em_cache_stats]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_cache_warm_exists() {
    log_test "_em_cache_warm exists"
    if (( ${+functions[_em_cache_warm]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_cache_key_format() {
    log_test "_em_cache_key returns 32-char hex hash"
    local key=$(_em_cache_key "test-id" 2>&1)
    if [[ "$key" =~ ^[a-f0-9]{32}$ ]]; then
        pass
    else
        fail "expected 32-char hex, got '$key'"
    fi
}

test_em_cache_round_trip() {
    log_test "cache set/get round-trip"
    local test_dir=$(mktemp -d)

    # Override cache dir temporarily
    local original_func=$(typeset -f _em_cache_dir)
    _em_cache_dir() { echo "$test_dir"; }

    _em_cache_set "summaries" "test-msg-1" "test summary" 2>/dev/null
    local result=$(_em_cache_get "summaries" "test-msg-1" 2>/dev/null)

    # Restore original function
    eval "$original_func"
    rm -rf "$test_dir"

    if [[ "$result" == "test summary" ]]; then
        pass
    else
        fail "expected 'test summary', got '$result'"
    fi
}

test_em_cache_ttl_expiry() {
    log_test "cache TTL expiry works"
    local test_dir=$(mktemp -d)

    # Override cache dir temporarily
    local original_func=$(typeset -f _em_cache_dir)
    _em_cache_dir() { echo "$test_dir"; }

    _em_cache_set "unread" "test-id" "5" 2>/dev/null

    # Touch file to be 120 seconds old (TTL for unread is 60s)
    local key=$(_em_cache_key "test-id")
    if [[ "$OSTYPE" == "darwin"* ]]; then
        touch -t $(date -v-120S "+%Y%m%d%H%M.%S") "$test_dir/unread/$key.txt" 2>/dev/null
    else
        touch -d "120 seconds ago" "$test_dir/unread/$key.txt" 2>/dev/null
    fi

    local result=$(_em_cache_get "unread" "test-id" 2>/dev/null)

    # Restore original function
    eval "$original_func"
    rm -rf "$test_dir"

    if [[ -z "$result" ]]; then
        pass
    else
        fail "cache should have expired, got '$result'"
    fi
}

test_em_cache_invalidate_removes() {
    log_test "_em_cache_invalidate removes entries"
    local test_dir=$(mktemp -d)

    # Override cache dir temporarily
    local original_func=$(typeset -f _em_cache_dir)
    _em_cache_dir() { echo "$test_dir"; }

    _em_cache_set "summaries" "test-msg-2" "another summary" 2>/dev/null
    _em_cache_invalidate "test-msg-2" 2>/dev/null
    local result=$(_em_cache_get "summaries" "test-msg-2" 2>/dev/null)

    # Restore original function
    eval "$original_func"
    rm -rf "$test_dir"

    if [[ -z "$result" ]]; then
        pass
    else
        fail "cache entry should be removed"
    fi
}

test_em_cache_prune_exists() {
    log_test "_em_cache_prune exists"
    if (( ${+functions[_em_cache_prune]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_cache_enforce_cap_exists() {
    log_test "_em_cache_enforce_cap exists"
    if (( ${+functions[_em_cache_enforce_cap]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_cache_prune_removes_expired() {
    log_test "_em_cache_prune removes expired entries"
    local test_dir=$(mktemp -d)

    # Override cache dir temporarily
    local original_func=$(typeset -f _em_cache_dir)
    _em_cache_dir() { echo "$test_dir"; }

    # Create fresh and expired entries
    _em_cache_set "unread" "fresh-msg" "3" 2>/dev/null
    _em_cache_set "unread" "old-msg" "7" 2>/dev/null

    # Age old-msg past unread TTL (60s)
    local key=$(_em_cache_key "old-msg")
    if [[ "$OSTYPE" == "darwin"* ]]; then
        touch -t $(date -v-120S "+%Y%m%d%H%M.%S") "$test_dir/unread/$key.txt" 2>/dev/null
    else
        touch -d "120 seconds ago" "$test_dir/unread/$key.txt" 2>/dev/null
    fi

    local pruned=$(_em_cache_prune 2>/dev/null)

    # Fresh entry should survive
    local fresh=$(_em_cache_get "unread" "fresh-msg" 2>/dev/null)

    # Restore original function
    eval "$original_func"
    rm -rf "$test_dir"

    if [[ "$pruned" == "1" && "$fresh" == "3" ]]; then
        pass
    else
        fail "expected pruned=1 fresh=3, got pruned=$pruned fresh=$fresh"
    fi
}

test_em_cache_prune_no_expired() {
    log_test "_em_cache_prune returns 0 when nothing expired"
    local test_dir=$(mktemp -d)

    local original_func=$(typeset -f _em_cache_dir)
    _em_cache_dir() { echo "$test_dir"; }

    # Create only fresh entries (summaries TTL=24h)
    _em_cache_set "summaries" "msg-1" "summary text" 2>/dev/null

    local pruned=$(_em_cache_prune 2>/dev/null)

    eval "$original_func"
    rm -rf "$test_dir"

    if [[ "$pruned" == "0" ]]; then
        pass
    else
        fail "expected 0 pruned, got $pruned"
    fi
}

test_em_cache_enforce_cap_no_eviction() {
    log_test "_em_cache_enforce_cap skips when under limit"
    local test_dir=$(mktemp -d)

    local original_func=$(typeset -f _em_cache_dir)
    _em_cache_dir() { echo "$test_dir"; }

    # Create a small entry (well under 50MB)
    _em_cache_set "summaries" "tiny-msg" "hello" 2>/dev/null

    # Should not evict anything
    _em_cache_enforce_cap 2>/dev/null

    local result=$(_em_cache_get "summaries" "tiny-msg" 2>/dev/null)

    eval "$original_func"
    rm -rf "$test_dir"

    if [[ "$result" == "hello" ]]; then
        pass
    else
        fail "entry should survive under cap, got '$result'"
    fi
}

test_em_cache_enforce_cap_disabled() {
    log_test "_em_cache_enforce_cap respects disabled (0)"
    local test_dir=$(mktemp -d)

    local original_func=$(typeset -f _em_cache_dir)
    _em_cache_dir() { echo "$test_dir"; }
    local original_max="$FLOW_EMAIL_CACHE_MAX_MB"
    FLOW_EMAIL_CACHE_MAX_MB=0

    _em_cache_set "summaries" "keep-msg" "keep me" 2>/dev/null
    _em_cache_enforce_cap 2>/dev/null

    local result=$(_em_cache_get "summaries" "keep-msg" 2>/dev/null)

    FLOW_EMAIL_CACHE_MAX_MB="$original_max"
    eval "$original_func"
    rm -rf "$test_dir"

    if [[ "$result" == "keep me" ]]; then
        pass
    else
        fail "cap=0 should disable eviction, got '$result'"
    fi
}

# ═══════════════════════════════════════════════════════════════
# Section 6: Render Functions
# ═══════════════════════════════════════════════════════════════

test_em_render_exists() {
    log_test "_em_render exists"
    if (( ${+functions[_em_render]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_render_with_exists() {
    log_test "_em_render_with exists"
    if (( ${+functions[_em_render_with]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_smart_render_exists() {
    log_test "_em_smart_render exists"
    if (( ${+functions[_em_smart_render]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_pager_exists() {
    log_test "_em_pager exists"
    if (( ${+functions[_em_pager]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_render_inbox_exists() {
    log_test "_em_render_inbox exists"
    if (( ${+functions[_em_render_inbox]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_render_inbox_json_exists() {
    log_test "_em_render_inbox_json exists"
    if (( ${+functions[_em_render_inbox_json]} )); then
        pass
    else
        fail "function not defined"
    fi
}

test_em_render_html_detection() {
    log_test "HTML content detection"
    local detected=""

    # Mock _em_render_with
    local original_func=$(typeset -f _em_render_with 2>/dev/null)
    _em_render_with() { detected="$1"; }

    _em_render "<html><body>Hello</body></html>" 2>/dev/null

    # Restore if it existed
    if [[ -n "$original_func" ]]; then
        eval "$original_func"
    fi

    if [[ "$detected" == "html" ]]; then
        pass
    else
        fail "expected 'html', got '$detected'"
    fi
}

test_em_render_markdown_detection() {
    log_test "Markdown content detection"
    local detected=""

    # Mock _em_render_with
    local original_func=$(typeset -f _em_render_with 2>/dev/null)
    _em_render_with() { detected="$1"; }

    _em_render "# Heading\n\n**bold** text" 2>/dev/null

    # Restore if it existed
    if [[ -n "$original_func" ]]; then
        eval "$original_func"
    fi

    if [[ "$detected" == "markdown" ]]; then
        pass
    else
        fail "expected 'markdown', got '$detected'"
    fi
}

test_em_render_plain_fallback() {
    log_test "Plain text fallback"
    local detected=""

    # Mock _em_render_with
    local original_func=$(typeset -f _em_render_with 2>/dev/null)
    _em_render_with() { detected="$1"; }

    _em_render "Just plain text here" 2>/dev/null

    # Restore if it existed
    if [[ -n "$original_func" ]]; then
        eval "$original_func"
    fi

    if [[ "$detected" == "plain" ]]; then
        pass
    else
        fail "expected 'plain', got '$detected'"
    fi
}

# ═══════════════════════════════════════════════════════════════
# Section 7: Email Noise Cleanup Patterns
# ═══════════════════════════════════════════════════════════════

# Helper: run the same sed cleanup pipeline used in em-render.zsh / em pick
_test_cleanup() {
    echo "$1" | sed \
        -e 's/\[cid:[^]]*\]//g' \
        -e 's|(https://nam[0-9]*\.safelinks\.protection\.outlook\.com[^)]*)||g' \
        -e '/<#part/d' \
        -e '/<#\/part>/d' \
        -e 's/<http[^>]*>//g' \
        -e 's/(mailto:[^)]*)//g'
}

test_cleanup_cid_image_ref() {
    log_test "strips [cid:...] image references"
    local input="See attached [cid:image001.png@01DC9787.E32DC900] schedule"
    local result=$(_test_cleanup "$input")
    if [[ "$result" == "See attached  schedule" ]]; then
        pass
    else
        fail "got: '$result'"
    fi
}

test_cleanup_cid_multiple() {
    log_test "strips multiple CID refs in one line"
    local input="Logo [cid:logo.png@ABC] and icon [cid:icon.gif@DEF] here"
    local result=$(_test_cleanup "$input")
    if [[ "$result" == "Logo  and icon  here" ]]; then
        pass
    else
        fail "got: '$result'"
    fi
}

test_cleanup_safe_links() {
    log_test "strips Microsoft Safe Links URLs"
    local input="Visit UNM(https://nam02.safelinks.protection.outlook.com/?url=https%3A%2F%2Funm.edu&data=05%7C02&reserved=0)"
    local result=$(_test_cleanup "$input")
    if [[ "$result" == "Visit UNM" ]]; then
        pass
    else
        fail "got: '$result'"
    fi
}

test_cleanup_safe_links_nam_variants() {
    log_test "strips Safe Links with different NAM regions"
    local input="Link(https://nam04.safelinks.protection.outlook.com/?url=test&data=x)"
    local result=$(_test_cleanup "$input")
    if [[ "$result" == "Link" ]]; then
        pass
    else
        fail "got: '$result'"
    fi
}

test_cleanup_mime_part_open() {
    log_test "removes <#part ...> MIME marker lines"
    local input=$'Line before\n<#part type=text/html>\nLine after'
    local result=$(_test_cleanup "$input")
    local expected=$'Line before\nLine after'
    if [[ "$result" == "$expected" ]]; then
        pass
    else
        fail "got: '$result'"
    fi
}

test_cleanup_mime_part_close() {
    log_test "removes <#/part> MIME marker lines"
    local input=$'Content here\n<#/part>\nMore content'
    local result=$(_test_cleanup "$input")
    local expected=$'Content here\nMore content'
    if [[ "$result" == "$expected" ]]; then
        pass
    else
        fail "got: '$result'"
    fi
}

test_cleanup_angle_bracket_url() {
    log_test "strips <https://...> angle-bracket URLs"
    local input="Visit our site <https://artsci.unm.edu/departments/math> today"
    local result=$(_test_cleanup "$input")
    if [[ "$result" == "Visit our site  today" ]]; then
        pass
    else
        fail "got: '$result'"
    fi
}

test_cleanup_angle_bracket_http() {
    log_test "strips <http://...> angle-bracket URLs (no TLS)"
    local input="Old link <http://example.com/page> here"
    local result=$(_test_cleanup "$input")
    if [[ "$result" == "Old link  here" ]]; then
        pass
    else
        fail "got: '$result'"
    fi
}

test_cleanup_mailto() {
    log_test "strips (mailto:...) inline references"
    local input="Contact John Smith(mailto:john@example.com) for details"
    local result=$(_test_cleanup "$input")
    if [[ "$result" == "Contact John Smith for details" ]]; then
        pass
    else
        fail "got: '$result'"
    fi
}

test_cleanup_preserves_plain_text() {
    log_test "preserves normal plain text unchanged"
    local input="Hello, this is a regular email with no noise."
    local result=$(_test_cleanup "$input")
    if [[ "$result" == "$input" ]]; then
        pass
    else
        fail "got: '$result'"
    fi
}

test_cleanup_preserves_quoted_replies() {
    log_test "preserves quoted reply lines (>)"
    local input=$'> On Monday, John wrote:\n> Please review the document.'
    local result=$(_test_cleanup "$input")
    if [[ "$result" == "$input" ]]; then
        pass
    else
        fail "got: '$result'"
    fi
}

test_cleanup_combined_noise() {
    log_test "handles multiple noise types in one email"
    local input=$'Hello team,\nSee [cid:img.png@ABC] the link(https://nam02.safelinks.protection.outlook.com/?url=test)\n<#part type=text/html>\nContact me(mailto:a@b.com) or visit <https://example.com>\n<#/part>'
    local result=$(_test_cleanup "$input")
    local expected=$'Hello team,\nSee  the link\nContact me or visit '
    if [[ "$result" == "$expected" ]]; then
        pass
    else
        fail "got: '$result'"
    fi
}

test_cleanup_render_email_body_strips_noise() {
    log_test "_em_render_email_body strips CID refs"
    local result=$(echo "Hi [cid:image001.png@X] there" | _em_render_email_body 2>/dev/null)
    # Output should contain "Hi" and "there" but not "[cid:"
    if [[ "$result" == *"Hi"* && "$result" != *"[cid:"* ]]; then
        pass
    else
        fail "CID ref not stripped in render pipeline"
    fi
}

test_cleanup_render_email_body_strips_safe_links() {
    log_test "_em_render_email_body strips Safe Links"
    local result=$(echo "Click here(https://nam02.safelinks.protection.outlook.com/?url=x&data=y)" | _em_render_email_body 2>/dev/null)
    if [[ "$result" == *"Click here"* && "$result" != *"safelinks"* ]]; then
        pass
    else
        fail "Safe Links not stripped in render pipeline"
    fi
}

# ═══════════════════════════════════════════════════════════════
# Section 8: Dispatcher Routing (was 7)
# ═══════════════════════════════════════════════════════════════

test_em_doctor_runs() {
    log_test "em doctor runs without error"
    local output=$(em doctor 2>&1)
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "exit code $exit_code"
    fi
}

test_em_cache_stats_runs() {
    log_test "em cache stats runs without error"
    local output=$(em cache stats 2>&1)
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "exit code $exit_code"
    fi
}

# ═══════════════════════════════════════════════════════════════
# Section 9: AI Backend Configuration
# ═══════════════════════════════════════════════════════════════

test_em_ai_backends_exists() {
    log_test "_EM_AI_BACKENDS array exists"
    if [[ -n "${_EM_AI_BACKENDS}" ]]; then
        pass
    else
        fail "array not defined"
    fi
}

test_em_ai_backends_has_default() {
    log_test "_EM_AI_BACKENDS has 'default' key"
    if [[ -n "${_EM_AI_BACKENDS[default]}" ]]; then
        pass
    else
        fail "'default' key not found"
    fi
}

test_em_ai_op_timeout_exists() {
    log_test "_EM_AI_OP_TIMEOUT array exists"
    if [[ -n "${_EM_AI_OP_TIMEOUT}" ]]; then
        pass
    else
        fail "array not defined"
    fi
}

test_em_ai_op_timeout_classify() {
    log_test "_EM_AI_OP_TIMEOUT[classify] equals 10"
    if [[ "${_EM_AI_OP_TIMEOUT[classify]}" -eq 10 ]]; then
        pass
    else
        fail "expected 10, got '${_EM_AI_OP_TIMEOUT[classify]}'"
    fi
}

test_em_ai_op_timeout_summarize() {
    log_test "_EM_AI_OP_TIMEOUT[summarize] equals 15"
    if [[ "${_EM_AI_OP_TIMEOUT[summarize]}" -eq 15 ]]; then
        pass
    else
        fail "expected 15, got '${_EM_AI_OP_TIMEOUT[summarize]}'"
    fi
}

test_em_ai_op_timeout_draft() {
    log_test "_EM_AI_OP_TIMEOUT[draft] equals 30"
    if [[ "${_EM_AI_OP_TIMEOUT[draft]}" -eq 30 ]]; then
        pass
    else
        fail "expected 30, got '${_EM_AI_OP_TIMEOUT[draft]}'"
    fi
}

# ═══════════════════════════════════════════════════════════════
# Section 10: Cache TTL Configuration
# ═══════════════════════════════════════════════════════════════

test_em_cache_ttl_exists() {
    log_test "_EM_CACHE_TTL array exists"
    if [[ -n "${_EM_CACHE_TTL}" ]]; then
        pass
    else
        fail "array not defined"
    fi
}

test_em_cache_ttl_summaries() {
    log_test "_EM_CACHE_TTL[summaries] equals 86400"
    if [[ "${_EM_CACHE_TTL[summaries]}" -eq 86400 ]]; then
        pass
    else
        fail "expected 86400, got '${_EM_CACHE_TTL[summaries]}'"
    fi
}

test_em_cache_ttl_drafts() {
    log_test "_EM_CACHE_TTL[drafts] equals 3600"
    if [[ "${_EM_CACHE_TTL[drafts]}" -eq 3600 ]]; then
        pass
    else
        fail "expected 3600, got '${_EM_CACHE_TTL[drafts]}'"
    fi
}

test_em_cache_ttl_unread() {
    log_test "_EM_CACHE_TTL[unread] equals 60"
    if [[ "${_EM_CACHE_TTL[unread]}" -eq 60 ]]; then
        pass
    else
        fail "expected 60, got '${_EM_CACHE_TTL[unread]}'"
    fi
}

# ═══════════════════════════════════════════════════════════════
# Main Test Runner
# ═══════════════════════════════════════════════════════════════

main() {
    echo "${CYAN}════════════════════════════════════════${NC}"
    echo "${CYAN}  Email Dispatcher Test Suite${NC}"
    echo "${CYAN}════════════════════════════════════════${NC}"
    echo ""

    setup

    echo "${YELLOW}Section 1: Dispatcher Function Existence${NC}"
    test_em_dispatcher_exists
    test_em_help_function_exists
    test_em_preview_message_exists
    echo ""

    echo "${YELLOW}Section 2: Help Output${NC}"
    test_em_help_output
    test_em_help_flag
    test_em_help_short_flag
    test_em_help_subcommands
    echo ""

    echo "${YELLOW}Section 3: Himalaya Adapter Functions${NC}"
    test_em_himalaya_check_exists
    test_em_himalaya_list_exists
    test_em_himalaya_read_exists
    test_em_himalaya_send_exists
    test_em_himalaya_reply_exists
    test_em_himalaya_template_reply_exists
    test_em_himalaya_template_write_exists
    test_em_himalaya_template_send_exists
    test_em_himalaya_search_exists
    test_em_himalaya_folders_exists
    test_em_himalaya_unread_count_exists
    test_em_himalaya_attachments_exists
    test_em_himalaya_flags_exists
    test_em_himalaya_idle_exists
    test_em_mml_inject_body_exists
    echo ""

    echo "${YELLOW}Section 4: AI Layer Functions${NC}"
    test_em_ai_query_exists
    test_em_ai_execute_exists
    test_em_ai_backend_for_op_exists
    test_em_ai_timeout_for_op_exists
    test_em_ai_fallback_chain_exists
    test_em_ai_available_exists
    test_em_ai_classify_prompt_exists
    test_em_ai_summarize_prompt_exists
    test_em_ai_draft_prompt_exists
    test_em_ai_schedule_prompt_exists
    test_em_category_icon_exists
    test_em_ai_classify_prompt_content
    test_em_ai_summarize_prompt_content
    test_em_ai_timeout_classify
    test_em_ai_timeout_draft
    test_em_category_icon_student
    test_em_category_icon_urgent
    echo ""

    echo "${YELLOW}Section 5: Cache Functions${NC}"
    test_em_cache_dir_exists
    test_em_cache_key_exists
    test_em_cache_get_exists
    test_em_cache_set_exists
    test_em_cache_invalidate_exists
    test_em_cache_clear_exists
    test_em_cache_stats_exists
    test_em_cache_warm_exists
    test_em_cache_key_format
    test_em_cache_round_trip
    test_em_cache_ttl_expiry
    test_em_cache_invalidate_removes
    test_em_cache_prune_exists
    test_em_cache_enforce_cap_exists
    test_em_cache_prune_removes_expired
    test_em_cache_prune_no_expired
    test_em_cache_enforce_cap_no_eviction
    test_em_cache_enforce_cap_disabled
    echo ""

    echo "${YELLOW}Section 6: Render Functions${NC}"
    test_em_render_exists
    test_em_render_with_exists
    test_em_smart_render_exists
    test_em_pager_exists
    test_em_render_inbox_exists
    test_em_render_inbox_json_exists
    test_em_render_html_detection
    test_em_render_markdown_detection
    test_em_render_plain_fallback
    echo ""

    echo "${YELLOW}Section 7: Email Noise Cleanup Patterns${NC}"
    test_cleanup_cid_image_ref
    test_cleanup_cid_multiple
    test_cleanup_safe_links
    test_cleanup_safe_links_nam_variants
    test_cleanup_mime_part_open
    test_cleanup_mime_part_close
    test_cleanup_angle_bracket_url
    test_cleanup_angle_bracket_http
    test_cleanup_mailto
    test_cleanup_preserves_plain_text
    test_cleanup_preserves_quoted_replies
    test_cleanup_combined_noise
    test_cleanup_render_email_body_strips_noise
    test_cleanup_render_email_body_strips_safe_links
    echo ""

    echo "${YELLOW}Section 8: Dispatcher Routing${NC}"
    test_em_doctor_runs
    test_em_cache_stats_runs
    echo ""

    echo "${YELLOW}Section 9: AI Backend Configuration${NC}"
    test_em_ai_backends_exists
    test_em_ai_backends_has_default
    test_em_ai_op_timeout_exists
    test_em_ai_op_timeout_classify
    test_em_ai_op_timeout_summarize
    test_em_ai_op_timeout_draft
    echo ""

    echo "${YELLOW}Section 10: Cache TTL Configuration${NC}"
    test_em_cache_ttl_exists
    test_em_cache_ttl_summaries
    test_em_cache_ttl_drafts
    test_em_cache_ttl_unread
    echo ""

    echo "${CYAN}════════════════════════════════════════${NC}"
    echo "  Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo "  Failed: ${RED}$TESTS_FAILED${NC}"
    echo "${CYAN}════════════════════════════════════════${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "${GREEN}✓ All tests passed!${NC}"
        exit 0
    else
        echo "${RED}✗ Some tests failed${NC}"
        exit 1
    fi
}

# Run tests
main
