#!/usr/bin/env zsh
# dogfood-em-dispatcher.zsh — Full plugin dogfooding for em email dispatcher
#
# Validates that the em dispatcher and all supporting modules load correctly
# after sourcing flow.plugin.zsh. Tests function existence, help output,
# configuration, and module integration.
#
# Usage: zsh tests/dogfood-em-dispatcher.zsh
#
# No network access required. No himalaya needed. Pure in-process validation.

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local test_name="$1"
    local test_func="$2"

    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "  ${CYAN}[$TESTS_RUN] $test_name...${RESET} "

    local output
    output=$(eval "$test_func" 2>&1)
    local rc=$?

    if [[ $rc -eq 0 ]]; then
        echo "${GREEN}PASS${RESET}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    elif [[ $rc -eq 77 ]]; then
        echo "${YELLOW}SKIP${RESET}"
    else
        echo "${RED}FAIL${RESET}"
        [[ -n "$output" ]] && echo "    ${DIM}${output:0:200}${RESET}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

echo ""
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo "${CYAN}  EM Email Dispatcher — Dogfood Test${RESET}"
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo ""

# ============================================================================
# LOAD PLUGIN
# ============================================================================

echo "${CYAN}Loading flow.plugin.zsh...${RESET}"
FLOW_QUIET=1
FLOW_ATLAS_ENABLED=no
FLOW_PLUGIN_DIR="$PROJECT_ROOT"
exec < /dev/null  # Non-interactive
source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
    echo "${RED}Plugin failed to load${RESET}"
    exit 1
}
echo "${GREEN}Plugin loaded (v$FLOW_VERSION)${RESET}"
echo ""

# ============================================================================
# SECTION 1: Dispatcher loaded
# ============================================================================

echo "${CYAN}--- Section 1: Dispatcher Core ---${RESET}"

run_test "em() function is defined" '
    typeset -f em >/dev/null 2>&1 || return 1
'

run_test "_em_help() function is defined" '
    typeset -f _em_help >/dev/null 2>&1 || return 1
'

run_test "em dispatches unknown command to error" '
    local output
    output=$(em __nonexistent__ 2>&1)
    [[ $? -ne 0 ]] || return 1
    [[ "$output" == *"Unknown command"* ]] || return 1
'

echo ""

# ============================================================================
# SECTION 2: Help output
# ============================================================================

echo "${CYAN}--- Section 2: Help Output ---${RESET}"

run_test "em help produces output" '
    local output
    output=$(em help 2>&1)
    [[ -n "$output" ]] || return 1
    local lines=$(echo "$output" | wc -l | tr -d " ")
    (( lines >= 10 )) || { echo "Only $lines lines"; return 1; }
'

run_test "em --help works (same as help)" '
    local output
    output=$(em --help 2>&1)
    [[ "$output" == *"Email Dispatcher"* ]] || return 1
'

run_test "em -h works (same as help)" '
    local output
    output=$(em -h 2>&1)
    [[ "$output" == *"Email Dispatcher"* ]] || return 1
'

# Verify all documented subcommands appear in help
for subcmd in inbox read send reply find pick respond classify summarize unread dash folders html attach cache doctor; do
    run_test "help mentions '$subcmd'" "
        local output
        output=\$(em help 2>&1)
        [[ \"\$output\" == *\"$subcmd\"* ]] || return 1
    "
done

echo ""

# ============================================================================
# SECTION 3: Himalaya Adapter Module (em-himalaya.zsh)
# ============================================================================

echo "${CYAN}--- Section 3: Himalaya Adapter Layer ---${RESET}"

adapter_fns=(
    _em_hml_check
    _em_hml_list
    _em_hml_read
    _em_hml_send
    _em_hml_reply
    _em_hml_template_reply
    _em_hml_template_write
    _em_hml_template_send
    _em_hml_search
    _em_hml_folders
    _em_hml_unread_count
    _em_hml_attachments
    _em_hml_flags
    _em_hml_idle
    _em_mml_inject_body
)

for fn in "${adapter_fns[@]}"; do
    run_test "Adapter function '$fn' exists" "
        typeset -f $fn >/dev/null 2>&1 || return 1
    "
done

echo ""

# ============================================================================
# SECTION 4: AI Module (em-ai.zsh)
# ============================================================================

echo "${CYAN}--- Section 4: AI Abstraction Layer ---${RESET}"

ai_fns=(
    _em_ai_query
    _em_ai_execute
    _em_ai_backend_for_op
    _em_ai_timeout_for_op
    _em_ai_fallback_chain
    _em_ai_available
    _em_ai_classify_prompt
    _em_ai_summarize_prompt
    _em_ai_draft_prompt
    _em_ai_schedule_prompt
    _em_category_icon
)

for fn in "${ai_fns[@]}"; do
    run_test "AI function '$fn' exists" "
        typeset -f $fn >/dev/null 2>&1 || return 1
    "
done

run_test "AI backends config exists" '
    [[ "${(t)_EM_AI_BACKENDS}" == *association* ]] || return 1
    [[ -n "${_EM_AI_BACKENDS[default]}" ]] || return 1
'

run_test "AI op timeouts config exists" '
    [[ "${(t)_EM_AI_OP_TIMEOUT}" == *association* ]] || return 1
    [[ "${_EM_AI_OP_TIMEOUT[classify]}" == "10" ]] || return 1
    [[ "${_EM_AI_OP_TIMEOUT[draft]}" == "30" ]] || return 1
'

run_test "Classify prompt returns content" '
    local prompt=$(_em_ai_classify_prompt)
    [[ "$prompt" == *"Classify"* ]] || return 1
    [[ "$prompt" == *"student-question"* ]] || return 1
'

run_test "Summarize prompt returns content" '
    local prompt=$(_em_ai_summarize_prompt)
    [[ "$prompt" == *"Summarize"* ]] || return 1
'

run_test "Schedule prompt returns content" '
    local prompt=$(_em_ai_schedule_prompt)
    [[ "$prompt" == *"JSON"* ]] || return 1
'

run_test "Category icons return non-empty" '
    for cat in student-question admin-important scheduling newsletter personal automated urgent; do
        local icon=$(_em_category_icon "$cat")
        [[ -n "$icon" ]] || { echo "No icon for $cat"; return 1; }
    done
'

echo ""

# ============================================================================
# SECTION 5: Cache Module (em-cache.zsh)
# ============================================================================

echo "${CYAN}--- Section 5: Cache System ---${RESET}"

cache_fns=(
    _em_cache_dir
    _em_cache_key
    _em_cache_get
    _em_cache_set
    _em_cache_invalidate
    _em_cache_clear
    _em_cache_stats
    _em_cache_warm
)

for fn in "${cache_fns[@]}"; do
    run_test "Cache function '$fn' exists" "
        typeset -f $fn >/dev/null 2>&1 || return 1
    "
done

run_test "Cache TTL config exists" '
    [[ "${(t)_EM_CACHE_TTL}" == *association* ]] || return 1
    [[ "${_EM_CACHE_TTL[summaries]}" == "86400" ]] || return 1
    [[ "${_EM_CACHE_TTL[drafts]}" == "3600" ]] || return 1
    [[ "${_EM_CACHE_TTL[unread]}" == "60" ]] || return 1
'

run_test "Cache key generates 32-char hash" '
    local key=$(_em_cache_key "test-message-123")
    [[ ${#key} -eq 32 ]] || { echo "Key length: ${#key}"; return 1; }
    [[ "$key" =~ ^[0-9a-f]+$ ]] || { echo "Not hex: $key"; return 1; }
'

run_test "Cache set/get round-trip" '
    local test_dir=$(mktemp -d)
    local orig_fn=$(typeset -f _em_cache_dir)
    _em_cache_dir() { echo "$test_dir"; }
    _em_cache_set "summaries" "dogfood-test-1" "dogfood test summary"
    local result=$(_em_cache_get "summaries" "dogfood-test-1")
    eval "$orig_fn"  # Restore
    [[ "$result" == "dogfood test summary" ]] || { echo "Got: $result"; rm -rf "$test_dir"; return 1; }
    rm -rf "$test_dir"
'

run_test "Cache invalidate removes entries" '
    local test_dir=$(mktemp -d)
    local orig_fn=$(typeset -f _em_cache_dir)
    _em_cache_dir() { echo "$test_dir"; }
    _em_cache_set "summaries" "dogfood-test-2" "should disappear"
    _em_cache_invalidate "dogfood-test-2"
    local result=$(_em_cache_get "summaries" "dogfood-test-2" 2>/dev/null)
    eval "$orig_fn"  # Restore
    [[ -z "$result" ]] || { echo "Still got: $result"; rm -rf "$test_dir"; return 1; }
    rm -rf "$test_dir"
'

echo ""

# ============================================================================
# SECTION 6: Render Module (em-render.zsh)
# ============================================================================

echo "${CYAN}--- Section 6: Render Pipeline ---${RESET}"

render_fns=(
    _em_render
    _em_render_with
    _em_smart_render
    _em_pager
    _em_render_inbox
    _em_render_inbox_json
)

for fn in "${render_fns[@]}"; do
    run_test "Render function '$fn' exists" "
        typeset -f $fn >/dev/null 2>&1 || return 1
    "
done

run_test "HTML content detected correctly" '
    local detected=""
    local orig_fn=$(typeset -f _em_render_with)
    _em_render_with() { detected="$1"; }
    _em_render "<html><body><p>Hello</p></body></html>"
    eval "$orig_fn"
    [[ "$detected" == "html" ]] || { echo "Got: $detected"; return 1; }
'

run_test "Markdown content detected correctly" '
    local detected=""
    local orig_fn=$(typeset -f _em_render_with)
    _em_render_with() { detected="$1"; }
    _em_render "# Heading"
    eval "$orig_fn"
    [[ "$detected" == "markdown" ]] || { echo "Got: $detected"; return 1; }
'

run_test "Plain text falls through to plain" '
    local detected=""
    local orig_fn=$(typeset -f _em_render_with)
    _em_render_with() { detected="$1"; }
    _em_render "Just a normal sentence without special formatting."
    eval "$orig_fn"
    [[ "$detected" == "plain" ]] || { echo "Got: $detected"; return 1; }
'

echo ""

# ============================================================================
# SECTION 7: Dispatcher Internal Functions
# ============================================================================

echo "${CYAN}--- Section 7: Dispatcher Subcommands ---${RESET}"

dispatcher_fns=(
    _em_inbox
    _em_read
    _em_send
    _em_reply
    _em_find
    _em_pick
    _em_preview_message
    _em_unread
    _em_dash
    _em_folders
    _em_html
    _em_attach
    _em_doctor
    _em_respond
    _em_classify
    _em_summarize
    _em_cache_cmd
    _em_confirm_send
)

for fn in "${dispatcher_fns[@]}"; do
    run_test "Dispatcher function '$fn' exists" "
        typeset -f $fn >/dev/null 2>&1 || return 1
    "
done

echo ""

# ============================================================================
# SECTION 8: Configuration Defaults
# ============================================================================

echo "${CYAN}--- Section 8: Configuration ---${RESET}"

run_test "FLOW_EMAIL_AI default is set" '
    [[ -n "$FLOW_EMAIL_AI" ]] || return 1
'

run_test "FLOW_EMAIL_PAGE_SIZE default is set" '
    [[ -n "$FLOW_EMAIL_PAGE_SIZE" ]] || return 1
    (( FLOW_EMAIL_PAGE_SIZE > 0 )) || return 1
'

run_test "FLOW_EMAIL_FOLDER default is INBOX" '
    [[ "$FLOW_EMAIL_FOLDER" == "INBOX" ]] || return 1
'

run_test "FLOW_EMAIL_AI_TIMEOUT default is set" '
    [[ -n "$FLOW_EMAIL_AI_TIMEOUT" ]] || return 1
    (( FLOW_EMAIL_AI_TIMEOUT > 0 )) || return 1
'

echo ""

# ============================================================================
# SECTION 9: MML Inject Body (template helper)
# ============================================================================

echo "${CYAN}--- Section 9: MML Template Helpers ---${RESET}"

run_test "MML body injection works" '
    local mml="From: test@example.com
To: user@example.com
Subject: Test

"
    local result=$(_em_mml_inject_body "$mml" "Hello, this is the injected body.")
    [[ "$result" == *"Hello, this is the injected body."* ]] || { echo "Body not found in result"; return 1; }
    [[ "$result" == *"From: test@example.com"* ]] || { echo "Headers lost"; return 1; }
'

run_test "MML injection preserves headers" '
    local mml="From: a@b.com
To: c@d.com
Subject: Test
Content-Type: text/plain

Original body here"
    local result=$(_em_mml_inject_body "$mml" "New body")
    [[ "$result" == *"Subject: Test"* ]] || return 1
    [[ "$result" == *"New body"* ]] || return 1
'

echo ""

# ============================================================================
# SECTION 10: em in plugin dogfood (dispatcher loaded with others)
# ============================================================================

echo "${CYAN}--- Section 10: Integration ---${RESET}"

run_test "em coexists with other dispatchers" '
    # Verify em did not clobber other dispatchers
    for disp in g cc v; do
        typeset -f $disp >/dev/null 2>&1 || { echo "$disp missing after em load"; return 1; }
    done
'

run_test "em doctor runs without crash" '
    local output
    output=$(_em_doctor 2>&1)
    # Just verify it returns and has output
    [[ -n "$output" ]] || return 1
'

run_test "em cache stats runs without crash" '
    local output
    output=$(_em_cache_cmd stats 2>&1)
    # Accept any output (including "no cache")
    true
'

echo ""

# ============================================================================
# SECTION 11: Email Noise Cleanup Patterns
# ============================================================================

echo "${CYAN}--- Section 11: Noise Cleanup ---${RESET}"

# Helper: identical sed pipeline used in em-render.zsh and em pick preview
_df_cleanup() {
    echo "$1" | sed \
        -e 's/\[cid:[^]]*\]//g' \
        -e 's|(https://nam[0-9]*\.safelinks\.protection\.outlook\.com[^)]*)||g' \
        -e '/<#part/d' \
        -e '/<#\/part>/d' \
        -e 's/<http[^>]*>//g' \
        -e 's/(mailto:[^)]*)//g'
}

run_test "CID image ref stripped" '
    local r=$(_df_cleanup "Logo [cid:image001.png@01DC9787.E32DC900] here")
    [[ "$r" == "Logo  here" ]] || { echo "Got: $r"; return 1; }
'

run_test "Multiple CID refs stripped" '
    local r=$(_df_cleanup "[cid:a.png@X] and [cid:b.gif@Y]")
    [[ "$r" == " and " ]] || { echo "Got: $r"; return 1; }
'

run_test "Microsoft Safe Links stripped (nam02)" '
    local r=$(_df_cleanup "UNM(https://nam02.safelinks.protection.outlook.com/?url=https%3A%2F%2Funm.edu&data=05)")
    [[ "$r" == "UNM" ]] || { echo "Got: $r"; return 1; }
'

run_test "Microsoft Safe Links stripped (nam04)" '
    local r=$(_df_cleanup "Link(https://nam04.safelinks.protection.outlook.com/?url=x&data=y)")
    [[ "$r" == "Link" ]] || { echo "Got: $r"; return 1; }
'

run_test "MIME <#part> marker line removed" '
    local r=$(_df_cleanup "$(printf "before\n<#part type=text/html>\nafter")")
    [[ "$r" == "$(printf "before\nafter")" ]] || { echo "Got: $r"; return 1; }
'

run_test "MIME <#/part> marker line removed" '
    local r=$(_df_cleanup "$(printf "content\n<#/part>\nmore")")
    [[ "$r" == "$(printf "content\nmore")" ]] || { echo "Got: $r"; return 1; }
'

run_test "Angle-bracket HTTPS URL stripped" '
    local r=$(_df_cleanup "Visit <https://artsci.unm.edu/math> now")
    [[ "$r" == "Visit  now" ]] || { echo "Got: $r"; return 1; }
'

run_test "Angle-bracket HTTP URL stripped" '
    local r=$(_df_cleanup "Old <http://example.com> link")
    [[ "$r" == "Old  link" ]] || { echo "Got: $r"; return 1; }
'

run_test "Mailto inline ref stripped" '
    local r=$(_df_cleanup "Jane(mailto:jane@unm.edu) said hi")
    [[ "$r" == "Jane said hi" ]] || { echo "Got: $r"; return 1; }
'

run_test "Plain text preserved unchanged" '
    local input="Dear team, please review the budget report."
    local r=$(_df_cleanup "$input")
    [[ "$r" == "$input" ]] || { echo "Got: $r"; return 1; }
'

run_test "Quoted replies preserved" '
    local input="> On Mon, Alice wrote:"
    local r=$(_df_cleanup "$input")
    [[ "$r" == "$input" ]] || { echo "Got: $r"; return 1; }
'

run_test "Combined noise cleanup" '
    local input="$(printf "Hi [cid:x@A] team\n<#part type=text/html>\nVisit <https://unm.edu>\n<#/part>")"
    local r=$(_df_cleanup "$input")
    local expected="$(printf "Hi  team\nVisit ")"
    [[ "$r" == "$expected" ]] || { echo "Got: $r"; return 1; }
'

run_test "_em_render_email_body strips CID noise" '
    local r=$(echo "Hi [cid:img@X] there" | _em_render_email_body 2>/dev/null)
    [[ "$r" != *"[cid:"* ]] || { echo "CID ref leaked through"; return 1; }
    [[ "$r" == *"Hi"* ]] || { echo "Content lost"; return 1; }
'

run_test "_em_render_email_body strips Safe Links" '
    local r=$(echo "Click(https://nam02.safelinks.protection.outlook.com/?url=x)" | _em_render_email_body 2>/dev/null)
    [[ "$r" != *"safelinks"* ]] || { echo "Safe Link leaked through"; return 1; }
    [[ "$r" == *"Click"* ]] || { echo "Link text lost"; return 1; }
'

run_test "_em_render_email_body strips angle URLs" '
    local r=$(echo "See <https://example.com/doc> here" | _em_render_email_body 2>/dev/null)
    [[ "$r" != *"<http"* ]] || { echo "Angle URL leaked through"; return 1; }
    [[ "$r" == *"See"* ]] || { echo "Content lost"; return 1; }
'

run_test "_em_render_email_body strips mailto" '
    local r=$(echo "Ask Bob(mailto:bob@unm.edu) about it" | _em_render_email_body 2>/dev/null)
    [[ "$r" != *"mailto:"* ]] || { echo "Mailto leaked through"; return 1; }
    [[ "$r" == *"Bob"* ]] || { echo "Name lost"; return 1; }
'

echo ""

# ============================================================================
# SUMMARY
# ============================================================================

echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "${GREEN}All $TESTS_PASSED/$TESTS_RUN dogfood tests passed${RESET}"
    exit 0
else
    echo "${RED}$TESTS_FAILED/$TESTS_RUN tests failed (${TESTS_PASSED} passed)${RESET}"
    exit 1
fi
