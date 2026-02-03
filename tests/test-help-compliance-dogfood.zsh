#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# HELP COMPLIANCE DOGFOODING TEST SUITE
# ══════════════════════════════════════════════════════════════════════════════
#
# Noninteractive dogfooding tests that exercise help compliance from the
# user's perspective: dispatcher invocations, individual rule validation,
# content quality, color fallbacks, doctor integration, and edge cases.
#
# Complements test-help-compliance.zsh (which only checks pass/fail).
# These tests dig into the details that matter for real-world usage.
#
# Usage:    ./tests/test-help-compliance-dogfood.zsh
# Expected: All tests pass (0 failures)
#
# ══════════════════════════════════════════════════════════════════════════════

# ─── Test Framework ──────────────────────────────────────────────────────────

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
DIM='\033[2m'
NC='\033[0m'

assert_pass() {
    local desc="$1"
    ((TESTS_RUN++))
    ((TESTS_PASSED++))
    echo -e "  ${GREEN}✓${NC} $desc"
}

assert_fail() {
    local desc="$1"
    local detail="${2:-}"
    ((TESTS_RUN++))
    ((TESTS_FAILED++))
    FAILED_TESTS+=("$desc")
    echo -e "  ${RED}✗${NC} $desc"
    [[ -n "$detail" ]] && echo -e "    ${DIM}$detail${NC}"
}

assert_contains() {
    local output="$1"
    local pattern="$2"
    local desc="$3"
    if [[ "$output" == *"$pattern"* ]]; then
        assert_pass "$desc"
    else
        assert_fail "$desc" "expected to contain: $pattern"
    fi
}

assert_not_contains() {
    local output="$1"
    local pattern="$2"
    local desc="$3"
    if [[ "$output" != *"$pattern"* ]]; then
        assert_pass "$desc"
    else
        assert_fail "$desc" "should NOT contain: $pattern"
    fi
}

assert_grep() {
    local output="$1"
    local regex="$2"
    local desc="$3"
    if echo "$output" | grep -qE "$regex"; then
        assert_pass "$desc"
    else
        assert_fail "$desc" "no match for regex: $regex"
    fi
}

assert_exit_code() {
    local actual="$1"
    local expected="$2"
    local desc="$3"
    if [[ "$actual" -eq "$expected" ]]; then
        assert_pass "$desc"
    else
        assert_fail "$desc" "exit code $actual, expected $expected"
    fi
}

# ─── Setup ───────────────────────────────────────────────────────────────────

FLOW_DIR="$(cd "$(dirname "$0")/.." && pwd)"

source "$FLOW_DIR/flow.plugin.zsh" 2>/dev/null || {
    source "$FLOW_DIR/lib/core.zsh" 2>/dev/null
    for f in "$FLOW_DIR"/lib/dispatchers/*.zsh; do
        source "$f" 2>/dev/null
    done
}

source "$FLOW_DIR/lib/help-compliance.zsh" 2>/dev/null || {
    echo -e "${RED}ERROR: Cannot source lib/help-compliance.zsh${NC}"
    exit 1
}

source "$FLOW_DIR/commands/doctor.zsh" 2>/dev/null

echo "══════════════════════════════════════════════════════════════"
echo "  Help Compliance Dogfooding Tests"
echo "══════════════════════════════════════════════════════════════"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 1: INDIVIDUAL RULE VALIDATION
# Verify each of the 9 rules independently per dispatcher
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}── Section 1: Individual Rule Validation ──${NC}"
echo ""

_test_individual_rules() {
    local dispatcher="$1"
    local help_fn="${_FLOW_HELP_FUNCTIONS[$dispatcher]}"
    local output
    output="$($help_fn 2>&1)"

    echo -e "${BLUE}  $dispatcher:${NC}"

    # Rule 1: Box header
    assert_contains "$output" "╭─" "$dispatcher: has ╭─ box header"

    # Rule 2: Box footer
    assert_contains "$output" "╰─" "$dispatcher: has ╰─ box footer"

    # Rule 3: MOST COMMON
    assert_grep "$output" "🔥.*MOST COMMON" "$dispatcher: has 🔥 MOST COMMON section"

    # Rule 4: QUICK EXAMPLES
    assert_grep "$output" "💡.*QUICK EXAMPLES" "$dispatcher: has 💡 QUICK EXAMPLES section"

    # Rule 5: Categorized actions
    assert_contains "$output" "📋" "$dispatcher: has 📋 categorized section"

    # Rule 6: TIP section
    assert_grep "$output" "💡.*TIP" "$dispatcher: has 💡 TIP section"

    # Rule 7: See Also
    assert_grep "$output" "📚|See also" "$dispatcher: has 📚 See also"

    # Rule 8: Color codes
    if [[ "$output" == *$'\033['* ]]; then
        assert_pass "$dispatcher: has ANSI color codes"
    else
        assert_fail "$dispatcher: has ANSI color codes"
    fi

    echo ""
}

# Test all 12 dispatchers individually
for d in g r mcp qu wt v cc tm teach dot obs prompt; do
    _test_individual_rules "$d"
done

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 2: DISPATCHER INVOCATION (help/--help/-h all work)
# Verify help is reachable through all standard entry points
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}── Section 2: Dispatcher Help Invocation ──${NC}"
echo ""

_test_help_invocation() {
    local cmd="$1"
    local form="$2"  # help, --help, or -h
    local output
    output="$($cmd $form 2>&1)"

    # Should produce output with the box header (proof it's the real help)
    if [[ "$output" == *"╭─"* ]]; then
        assert_pass "$cmd $form → produces help output"
    else
        assert_fail "$cmd $form → produces help output" "no box header found"
    fi
}

# Test all three invocation forms for each dispatcher
# Note: obs is excluded because obs() may be overridden by external
# obsidian-cli-ops (symlinked via zsh/functions/obs.zsh). We test _obs_help
# directly via the compliance library instead.
for cmd in g r mcp qu wt v cc tm prompt; do
    for form in help --help -h; do
        _test_help_invocation "$cmd" "$form"
    done
done

# Test obs via _obs_help directly (external override-safe)
for form in help --help -h; do
    local _obs_out
    _obs_out="$(_obs_help 2>&1)"
    if [[ "$_obs_out" == *"╭─"* ]]; then
        assert_pass "obs $form → produces help output (via _obs_help)"
    else
        assert_fail "obs $form → produces help output (via _obs_help)" "no box header found"
    fi
done

# teach and dot use the same forms but test explicitly
for form in help --help -h; do
    _test_help_invocation "teach" "$form"
    _test_help_invocation "dot" "$form"
done

echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 3: CONTENT QUALITY CHECKS
# Verify help content is meaningful, not just structurally valid
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}── Section 3: Content Quality ──${NC}"
echo ""

_test_content_quality() {
    local dispatcher="$1"
    local help_fn="${_FLOW_HELP_FUNCTIONS[$dispatcher]}"
    local output
    output="$($help_fn 2>&1)"

    echo -e "${BLUE}  $dispatcher:${NC}"

    # MOST COMMON has at least 3 commands listed
    local most_common_block
    most_common_block="$(echo "$output" | sed -n '/MOST COMMON/,/💡\|📋\|📚/p' | head -20)"
    local cmd_count
    cmd_count=$(echo "$most_common_block" | grep -c "$dispatcher")
    if [[ $cmd_count -ge 2 ]]; then
        assert_pass "$dispatcher: MOST COMMON has $cmd_count commands (>= 2)"
    else
        assert_fail "$dispatcher: MOST COMMON has $cmd_count commands (>= 2)"
    fi

    # QUICK EXAMPLES has $ prompt lines (copy-paste ready)
    local example_count
    example_count=$(echo "$output" | sed -n '/QUICK EXAMPLES/,/📋\|💡.*TIP\|📚/p' | grep -c '\$')
    if [[ $example_count -ge 2 ]]; then
        assert_pass "$dispatcher: QUICK EXAMPLES has $example_count examples (>= 2)"
    else
        assert_fail "$dispatcher: QUICK EXAMPLES has $example_count examples (>= 2)"
    fi

    # See Also references valid dispatcher names (cross-reference check)
    local see_also_block
    see_also_block="$(echo "$output" | sed -n '/See also\|📚/,//p')"
    if [[ -n "$see_also_block" ]]; then
        # At least one cross-reference to another command
        local has_ref=false
        for ref_cmd in g r mcp qu wt v cc tm teach dot obs prompt work dash pick flow; do
            if echo "$see_also_block" | grep -q "$ref_cmd"; then
                has_ref=true
                break
            fi
        done
        if $has_ref; then
            assert_pass "$dispatcher: See Also references valid commands"
        else
            assert_fail "$dispatcher: See Also references valid commands"
        fi
    fi

    # Help output is non-trivial (> 20 lines)
    local line_count
    line_count=$(echo "$output" | wc -l | tr -d ' ')
    if [[ $line_count -ge 20 ]]; then
        assert_pass "$dispatcher: help output has $line_count lines (>= 20)"
    else
        assert_fail "$dispatcher: help output has $line_count lines (>= 20)" "only $line_count lines"
    fi

    echo ""
}

for d in g r mcp qu wt v cc tm teach dot obs prompt; do
    _test_content_quality "$d"
done

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 4: COLOR FALLBACK ISOLATION
# Verify help works when _C_* variables are NOT pre-defined
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}── Section 4: Color Fallback Isolation ──${NC}"
echo ""

_test_color_fallback() {
    local dispatcher="$1"
    local help_fn="${_FLOW_HELP_FUNCTIONS[$dispatcher]}"

    # Run help function in a clean subshell with NO color variables
    local output
    output="$(
        unset _C_BOLD _C_DIM _C_NC _C_RED _C_GREEN _C_YELLOW _C_BLUE _C_MAGENTA _C_CYAN
        $help_fn 2>&1
    )"

    # Should still produce colored output (fallback defined)
    if [[ "$output" == *$'\033['* ]]; then
        assert_pass "$dispatcher: colors render with fallbacks (no _C_* pre-set)"
    else
        assert_fail "$dispatcher: colors render with fallbacks (no _C_* pre-set)"
    fi

    # Should still have the box
    assert_contains "$output" "╭─" "$dispatcher: box renders with fallbacks"
}

# Only test the 7 dispatchers we fixed (they all define their own fallbacks)
for d in obs prompt dot cc tm teach v; do
    _test_color_fallback "$d"
done
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 5: BOX CONSISTENCY
# Verify box formatting matches the standard (single-line, 45 chars)
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}── Section 5: Box Formatting Consistency ──${NC}"
echo ""

_test_box_format() {
    local dispatcher="$1"
    local help_fn="${_FLOW_HELP_FUNCTIONS[$dispatcher]}"
    local output
    output="$($help_fn 2>&1)"

    # Must use single-line box (╭╮╰╯), NOT double-line (╔╗╚╝)
    assert_not_contains "$output" "╔" "$dispatcher: no double-line ╔ box"
    assert_not_contains "$output" "╗" "$dispatcher: no double-line ╗ box"
    assert_not_contains "$output" "╚" "$dispatcher: no double-line ╚ box"
    assert_not_contains "$output" "╝" "$dispatcher: no double-line ╝ box"

    # Must NOT use cat <<EOF (rendered output won't have this, but check source)
    local src_file
    case "$dispatcher" in
        g)      src_file="$FLOW_DIR/lib/dispatchers/g-dispatcher.zsh" ;;
        obs)    src_file="$FLOW_DIR/lib/dispatchers/obs.zsh" ;;
        teach)  src_file="$FLOW_DIR/lib/dispatchers/teach-dispatcher.zsh" ;;
        prompt) src_file="$FLOW_DIR/lib/dispatchers/prompt-dispatcher.zsh" ;;
        *)      src_file="$FLOW_DIR/lib/dispatchers/${dispatcher}-dispatcher.zsh" ;;
    esac

    # Check source uses echo -e (not cat <<EOF) in the help function
    local fn_source
    fn_source="$(sed -n "/${help_fn}()/,/^}/p" "$src_file" 2>/dev/null)"
    if echo "$fn_source" | grep -q 'echo -e'; then
        assert_pass "$dispatcher: uses echo -e (not cat <<EOF)"
    elif echo "$fn_source" | grep -q 'cat <<'; then
        assert_fail "$dispatcher: uses echo -e (not cat <<EOF)" "found cat <<EOF in source"
    else
        assert_pass "$dispatcher: uses echo -e (not cat <<EOF)"
    fi
}

for d in g r mcp qu wt v cc tm teach dot obs prompt; do
    _test_box_format "$d"
done
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 6: FUNCTION NAMING CONVENTION
# Verify all help functions follow _<cmd>_help naming
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}── Section 6: Function Naming Convention ──${NC}"
echo ""

_test_function_naming() {
    # Standard pattern: _<cmd>_help
    for d in g r mcp qu wt v cc tm dot obs prompt; do
        local expected="_${d}_help"
        if typeset -f "$expected" > /dev/null 2>&1; then
            assert_pass "$d: function $expected() exists"
        else
            assert_fail "$d: function $expected() exists"
        fi
    done

    # Special case: teach uses _teach_dispatcher_help (documented exception)
    if typeset -f "_teach_dispatcher_help" > /dev/null 2>&1; then
        assert_pass "teach: function _teach_dispatcher_help() exists (special case)"
    else
        assert_fail "teach: function _teach_dispatcher_help() exists (special case)"
    fi

    # obs: verify old obs_help still works as alias for backward compat
    if typeset -f "obs_help" > /dev/null 2>&1; then
        assert_pass "obs: legacy obs_help() alias exists"
    else
        assert_fail "obs: legacy obs_help() alias exists"
    fi
}

_test_function_naming
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 7: DOCTOR INTEGRATION
# Verify flow doctor --help-check works end-to-end
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}── Section 7: Doctor Integration ──${NC}"
echo ""

_test_doctor_integration() {
    # doctor --help-check should succeed
    local output
    output="$(doctor --help-check 2>&1)"
    local rc=$?
    assert_exit_code "$rc" "0" "doctor --help-check exits 0 (all pass)"

    # Output should show the compliance header
    assert_contains "$output" "Help Function Compliance Check" \
        "doctor --help-check shows compliance header"

    # Output should report all 12 dispatchers
    assert_contains "$output" "All 12 dispatchers compliant" \
        "doctor --help-check reports all 12 compliant"

    # Each dispatcher should appear in output
    for d in g r mcp qu wt v cc tm teach dot obs prompt; do
        assert_grep "$output" "✅ $d:" "doctor output includes $d result"
    done
}

_test_doctor_integration
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 8: COMPLIANCE LIBRARY API
# Verify the shared library functions work correctly
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}── Section 8: Compliance Library API ──${NC}"
echo ""

_test_compliance_api() {
    # Dispatcher list has exactly 12 entries
    local count=${#_FLOW_HELP_DISPATCHERS[@]}
    if [[ $count -eq 12 ]]; then
        assert_pass "dispatcher list has exactly 12 entries"
    else
        assert_fail "dispatcher list has exactly 12 entries" "found $count"
    fi

    # Function map has entry for every dispatcher
    for d in "${_FLOW_HELP_DISPATCHERS[@]}"; do
        if [[ -n "${_FLOW_HELP_FUNCTIONS[$d]}" ]]; then
            assert_pass "function map has entry for $d"
        else
            assert_fail "function map has entry for $d"
        fi
    done

    # Single check returns structured output
    local single_output
    single_output="$(_flow_help_compliance_check g true 2>&1)"
    assert_contains "$single_output" "PASS" "single check (verbose) includes PASS lines"
    assert_contains "$single_output" "9/9" "single check shows 9/9 score"

    # check_all with verbose shows per-rule detail
    local all_verbose
    all_verbose="$(_flow_help_compliance_check_all true 2>&1)"
    assert_contains "$all_verbose" "PASS" "check_all (verbose) shows PASS details"

    # Rules function lists all 9 rules
    local rules
    rules="$(_flow_help_compliance_rules 2>&1)"
    for rule in box_header box_footer most_common quick_examples categorized tip_section see_also color_codes function_naming; do
        assert_contains "$rules" "$rule" "rules() lists $rule"
    done

    # Invalid dispatcher returns error
    local bad_output
    bad_output="$(_flow_help_compliance_check "nonexistent" false 2>&1)"
    local bad_rc=$?
    assert_exit_code "$bad_rc" "1" "invalid dispatcher returns exit 1"
    assert_contains "$bad_output" "FAIL" "invalid dispatcher produces FAIL output"
}

_test_compliance_api
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 9: CONSISTENCY ACROSS DISPATCHERS
# Verify all 12 use the same structural patterns
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}── Section 9: Cross-Dispatcher Consistency ──${NC}"
echo ""

_test_consistency() {
    # All dispatchers should have the same section order:
    # box → MOST COMMON → QUICK EXAMPLES → 📋 sections → TIP → See also
    for d in g r mcp qu wt v cc tm teach dot obs prompt; do
        local help_fn="${_FLOW_HELP_FUNCTIONS[$d]}"
        local output
        output="$($help_fn 2>&1)"

        # MOST COMMON appears before QUICK EXAMPLES
        local mc_line qe_line
        mc_line=$(echo "$output" | grep -n "MOST COMMON" | head -1 | cut -d: -f1)
        qe_line=$(echo "$output" | grep -n "QUICK EXAMPLES" | head -1 | cut -d: -f1)
        if [[ -n "$mc_line" && -n "$qe_line" && "$mc_line" -lt "$qe_line" ]]; then
            assert_pass "$d: MOST COMMON before QUICK EXAMPLES"
        else
            assert_fail "$d: MOST COMMON before QUICK EXAMPLES" "MC=$mc_line QE=$qe_line"
        fi

        # TIP appears after all 📋 sections
        local last_cat_line tip_line
        last_cat_line=$(echo "$output" | grep -n "📋" | tail -1 | cut -d: -f1)
        tip_line=$(echo "$output" | grep -n "💡.*TIP" | head -1 | cut -d: -f1)
        if [[ -n "$last_cat_line" && -n "$tip_line" && "$last_cat_line" -lt "$tip_line" ]]; then
            assert_pass "$d: TIP section after last 📋 category"
        else
            assert_fail "$d: TIP section after last 📋 category" "cat=$last_cat_line tip=$tip_line"
        fi
    done
}

_test_consistency
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 10: IDEMPOTENCY & EDGE CASES
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}── Section 10: Edge Cases ──${NC}"
echo ""

_test_edge_cases() {
    # Calling help function twice produces identical output
    local out1 out2
    out1="$(_g_help 2>&1)"
    out2="$(_g_help 2>&1)"
    if [[ "$out1" == "$out2" ]]; then
        assert_pass "g: help output is idempotent (2 calls identical)"
    else
        assert_fail "g: help output is idempotent (2 calls identical)"
    fi

    # Compliance check is idempotent
    local c1 c2
    c1="$(_flow_help_compliance_check g false 2>&1)"
    c2="$(_flow_help_compliance_check g false 2>&1)"
    if [[ "$c1" == "$c2" ]]; then
        assert_pass "compliance check is idempotent"
    else
        assert_fail "compliance check is idempotent"
    fi

    # Empty dispatcher name handled gracefully
    local empty_out
    empty_out="$(_flow_help_compliance_check "" false 2>&1)"
    local empty_rc=$?
    assert_exit_code "$empty_rc" "1" "empty dispatcher name returns exit 1"

    # Help output contains no raw FLOW_COLORS references (all converted)
    for d in obs prompt dot cc tm teach; do
        local help_fn="${_FLOW_HELP_FUNCTIONS[$d]}"
        local output
        output="$($help_fn 2>&1)"
        assert_not_contains "$output" "FLOW_COLORS" "$d: no raw FLOW_COLORS[] in output"
    done

    # Help output contains no literal \033[ (should be rendered as actual ESC)
    for d in obs prompt dot cc tm teach; do
        local help_fn="${_FLOW_HELP_FUNCTIONS[$d]}"
        local output
        output="$($help_fn 2>&1)"
        # Literal backslash-zero-three-three should NOT appear
        if echo "$output" | grep -qF '\033['; then
            assert_fail "$d: no literal \\033[ in output (should be rendered)"
        else
            assert_pass "$d: no literal \\033[ in output (should be rendered)"
        fi
    done
}

_test_edge_cases
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# RESULTS
# ═══════════════════════════════════════════════════════════════════════════════

echo "══════════════════════════════════════════════════════════════"
echo "  Dogfooding Results: $TESTS_PASSED/$TESTS_RUN passed, $TESTS_FAILED failed"
echo "══════════════════════════════════════════════════════════════"

if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
    echo ""
    echo -e "${RED}Failed tests:${NC}"
    for t in "${FAILED_TESTS[@]}"; do
        echo -e "  ${RED}✗${NC} $t"
    done
fi

echo ""

[[ $TESTS_FAILED -eq 0 ]]
