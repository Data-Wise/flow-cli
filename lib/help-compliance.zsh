#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# Help Compliance Checker
# ══════════════════════════════════════════════════════════════════════════════
#
# Validates dispatcher help functions against docs/CONVENTIONS.md:173-199.
# Used by: tests/test-help-compliance.zsh, flow doctor --help-check
#
# 9 Rules:
#   1. Box header (╭─)
#   2. Box footer (╰─)
#   3. MOST COMMON section (🔥)
#   4. QUICK EXAMPLES section (💡.*QUICK EXAMPLES)
#   5. Categorized actions (📋)
#   6. TIP section (💡 TIP)
#   7. See Also section (📚|See also)
#   8. Color codes (_C_ or \033[)
#   9. Help function naming (_<cmd>_help)

# All 15 dispatchers to check
typeset -ga _FLOW_HELP_DISPATCHERS=(g r mcp qu wt v cc tm teach dots sec tok obs prompt em)

# Map dispatcher names to their help function names
typeset -gA _FLOW_HELP_FUNCTIONS=(
    [g]="_g_help"
    [r]="_r_help"
    [mcp]="_mcp_help"
    [qu]="_qu_help"
    [wt]="_wt_help"
    [v]="_v_help"
    [cc]="_cc_help"
    [tm]="_tm_help"
    [teach]="_teach_dispatcher_help"
    [dots]="_dots_help"
    [sec]="_sec_help"
    [tok]="_tok_help"
    [obs]="_obs_help"
    [prompt]="_prompt_help"
    [em]="_em_help"
)

# Check a single dispatcher's help output against all 9 rules.
# Usage: _flow_help_compliance_check <dispatcher_name>
# Returns: 0 if all pass, 1 if any fail
# Output: One line per rule: PASS/FAIL <rule_name>
_flow_help_compliance_check() {
    local dispatcher="$1"
    local verbose="${2:-false}"

    if [[ -z "$dispatcher" ]]; then
        echo "Usage: _flow_help_compliance_check <dispatcher>"
        return 1
    fi

    local help_fn="${_FLOW_HELP_FUNCTIONS[$dispatcher]}"
    if [[ -z "$help_fn" ]]; then
        echo "FAIL unknown_dispatcher: '$dispatcher' not in dispatcher list"
        return 1
    fi

    # Check if the help function exists
    if ! typeset -f "$help_fn" > /dev/null 2>&1; then
        echo "FAIL function_exists: $help_fn() not defined"
        return 1
    fi

    # Capture help output
    local output
    output="$($help_fn 2>&1)"

    local failures=0
    local total=9

    # Rule 1: Box header
    if echo "$output" | grep -q '╭─'; then
        [[ "$verbose" == "true" ]] && echo "  PASS  rule1_box_header"
    else
        echo "  FAIL  rule1_box_header: missing ╭─ box header"
        ((failures++))
    fi

    # Rule 2: Box footer
    if echo "$output" | grep -q '╰─'; then
        [[ "$verbose" == "true" ]] && echo "  PASS  rule2_box_footer"
    else
        echo "  FAIL  rule2_box_footer: missing ╰─ box footer"
        ((failures++))
    fi

    # Rule 3: MOST COMMON section
    if echo "$output" | grep -q '🔥.*MOST COMMON'; then
        [[ "$verbose" == "true" ]] && echo "  PASS  rule3_most_common"
    else
        echo "  FAIL  rule3_most_common: missing 🔥 MOST COMMON section"
        ((failures++))
    fi

    # Rule 4: QUICK EXAMPLES section
    if echo "$output" | grep -q '💡.*QUICK EXAMPLES'; then
        [[ "$verbose" == "true" ]] && echo "  PASS  rule4_quick_examples"
    else
        echo "  FAIL  rule4_quick_examples: missing 💡 QUICK EXAMPLES section"
        ((failures++))
    fi

    # Rule 5: Categorized actions (at least one 📋)
    if echo "$output" | grep -q '📋'; then
        [[ "$verbose" == "true" ]] && echo "  PASS  rule5_categorized_actions"
    else
        echo "  FAIL  rule5_categorized_actions: missing 📋 categorized section"
        ((failures++))
    fi

    # Rule 6: TIP section
    if echo "$output" | grep -q '💡 TIP'; then
        [[ "$verbose" == "true" ]] && echo "  PASS  rule6_tip_section"
    else
        echo "  FAIL  rule6_tip_section: missing 💡 TIP section"
        ((failures++))
    fi

    # Rule 7: See Also section
    if echo "$output" | grep -qE '📚|See also'; then
        [[ "$verbose" == "true" ]] && echo "  PASS  rule7_see_also"
    else
        echo "  FAIL  rule7_see_also: missing 📚 See also section"
        ((failures++))
    fi

    # Rule 8: Color codes present (ANSI escapes in rendered output)
    # echo -e renders \033[ into actual ESC (0x1b) characters
    if [[ "$output" == *$'\033['* ]] || [[ "$output" == *$'\x1b['* ]]; then
        [[ "$verbose" == "true" ]] && echo "  PASS  rule8_color_codes"
    else
        echo "  FAIL  rule8_color_codes: no ANSI color codes in output"
        ((failures++))
    fi

    # Rule 9: Help function naming convention (_<cmd>_help)
    local expected_pattern="_${dispatcher}_help"
    # Special case: teach uses _teach_dispatcher_help
    if [[ "$dispatcher" == "teach" ]]; then
        expected_pattern="_teach_dispatcher_help"
    fi
    if typeset -f "$expected_pattern" > /dev/null 2>&1; then
        [[ "$verbose" == "true" ]] && echo "  PASS  rule9_function_naming"
    else
        echo "  FAIL  rule9_function_naming: expected $expected_pattern()"
        ((failures++))
    fi

    # Summary
    local passed=$((total - failures))
    if [[ $failures -eq 0 ]]; then
        echo "  ✅ $dispatcher: $passed/$total rules passed"
        return 0
    else
        echo "  ❌ $dispatcher: $passed/$total rules passed ($failures failed)"
        return 1
    fi
}

# Check all 15 dispatchers.
# Returns: 0 if all pass, 1 if any fail
_flow_help_compliance_check_all() {
    local verbose="${1:-false}"
    local failures=0
    local total=${#_FLOW_HELP_DISPATCHERS[@]}

    echo "Help Compliance Check (9 rules × $total dispatchers)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    for dispatcher in "${_FLOW_HELP_DISPATCHERS[@]}"; do
        if ! _flow_help_compliance_check "$dispatcher" "$verbose"; then
            ((failures++))
        fi
        echo ""
    done

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    local passed=$((total - failures))
    if [[ $failures -eq 0 ]]; then
        echo "✅ All $total dispatchers compliant"
        return 0
    else
        echo "❌ $passed/$total dispatchers compliant ($failures non-compliant)"
        return 1
    fi
}

# Return rule definitions (for documentation/reporting).
_flow_help_compliance_rules() {
    echo "Help Function Compliance Rules (from CONVENTIONS.md:173-199)"
    echo ""
    echo "  1. box_header         ╭─ single-line box header"
    echo "  2. box_footer         ╰─ single-line box footer"
    echo "  3. most_common        🔥 MOST COMMON section (green)"
    echo "  4. quick_examples     💡 QUICK EXAMPLES section (yellow)"
    echo "  5. categorized        📋 categorized action section(s) (blue)"
    echo "  6. tip_section        💡 TIP section exact match (magenta)"
    echo "  7. see_also           📚 See also cross-references (dim)"
    echo "  8. color_codes        ANSI color codes present in output"
    echo "  9. function_naming    _<cmd>_help() naming convention"
}
