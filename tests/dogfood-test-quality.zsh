#!/usr/bin/env zsh
# tests/dogfood-test-quality.zsh
# Smoke test that scans test files for common anti-patterns
# Part of the testing overhaul - "eat our own dogfood"

# ============================================================================
# SETUP
# ============================================================================

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

source "${SCRIPT_DIR}/test-framework.zsh"

# ============================================================================
# CONFIGURATION
# ============================================================================

# Collect test files to scan (exclude framework, dogfood, fixtures, e2e)
typeset -a SCAN_FILES
for f in "${SCRIPT_DIR}"/test-*.zsh; do
    local basename="${f:t}"
    # Skip exclusions
    [[ "$basename" == "test-framework.zsh" ]] && continue
    [[ "$basename" == dogfood-* ]] && continue
    # Skip fixtures and e2e subdirectories (shouldn't match glob, but be safe)
    [[ "$f" == */fixtures/* ]] && continue
    [[ "$f" == */e2e/* ]] && continue
    SCAN_FILES+=("$f")
done

# ============================================================================
# ANTI-PATTERN 1: Permissive exit codes
# Pattern: exit_code == 0 || exit_code == 1 (accepts both success AND failure)
# ============================================================================

check_permissive_exit_codes() {
    test_case "No permissive exit code checks (0 || 1 always passes)"

    local violations=0
    typeset -a violation_files
    local details=""

    local f fname hits count sample_line
    for f in "${SCAN_FILES[@]}"; do
        fname="${f:t}"
        # Match both styles:
        #   exit_code -eq 0 || $exit_code -eq 1
        #   exit_code == 0 || exit_code == 1
        #   exit_code -eq 0 ]] || [[ $exit_code -eq 1
        hits="$(grep -n 'exit_code.*0.*||.*exit_code.*1' "$f" 2>/dev/null)"
        if [[ -n "$hits" ]]; then
            count="$(echo "$hits" | wc -l | tr -d ' ')"
            violations=$((violations + count))
            violation_files+=("$fname")
            sample_line="$(echo "$hits" | head -1)"
            details+="  $fname: $count hit(s) (e.g. line ${sample_line%%:*})\n"
        fi
    done

    if (( violations > 0 )); then
        local unique_files=${#violation_files[@]}
        test_fail "$violations permissive exit code check(s) in $unique_files file(s):\n$details"
        return 1
    else
        test_pass
    fi
}

# ============================================================================
# ANTI-PATTERN 2: Existence-only tests
# Pattern: functions that only check `type X &>/dev/null` then pass
# with no behavioral assertion afterward
# ============================================================================

check_existence_only_tests() {
    test_case "No existence-only tests (type check without behavioral follow-up)"

    local violations=0
    typeset -a violation_files
    local details=""

    local f fname type_lines file_violations lineno line context
    for f in "${SCAN_FILES[@]}"; do
        fname="${f:t}"
        type_lines="$(grep -n 'type .* &>/dev/null' "$f" 2>/dev/null)"
        [[ -z "$type_lines" ]] && continue

        file_violations=0
        while IFS= read -r line; do
            lineno="${line%%:*}"
            # Extract ~15 lines after the type check to see the function body
            context="$(sed -n "${lineno},$((lineno + 15))p" "$f" 2>/dev/null)"
            # If context has pass/test_pass but no assert_ call, it's existence-only
            if echo "$context" | grep -q 'pass\|test_pass'; then
                if ! echo "$context" | grep -q 'assert_\|output.*=\|\$output'; then
                    file_violations=$((file_violations + 1))
                fi
            fi
        done <<< "$type_lines"

        if (( file_violations > 0 )); then
            violations=$((violations + file_violations))
            violation_files+=("$fname")
            details+="  $fname: $file_violations existence-only test(s)\n"
        fi
    done

    if (( violations > 0 )); then
        local unique_files=${#violation_files[@]}
        test_fail "$violations existence-only test(s) in $unique_files file(s):\n$details"
        return 1
    else
        test_pass
    fi
}

# ============================================================================
# ANTI-PATTERN 3: Captured output never used
# Pattern: local output=$(...) where $output is never referenced afterward
# ============================================================================

check_unused_output() {
    test_case "No captured output variables that are never checked"

    local violations=0
    typeset -a violation_files
    local details=""

    local f fname capture_lines file_violations lineno line after
    for f in "${SCAN_FILES[@]}"; do
        fname="${f:t}"
        capture_lines="$(grep -n 'local output=\$(' "$f" 2>/dev/null)"
        [[ -z "$capture_lines" ]] && continue

        file_violations=0
        while IFS= read -r line; do
            lineno="${line%%:*}"
            # Look at the next 20 lines for any use of $output
            after="$(sed -n "$((lineno + 1)),$((lineno + 20))p" "$f" 2>/dev/null)"
            if ! echo "$after" | grep -q '\$output\|"$output"\|${output'; then
                file_violations=$((file_violations + 1))
            fi
        done <<< "$capture_lines"

        if (( file_violations > 0 )); then
            violations=$((violations + file_violations))
            violation_files+=("$fname")
            details+="  $fname: $file_violations unused output capture(s)\n"
        fi
    done

    if (( violations > 0 )); then
        local unique_files=${#violation_files[@]}
        test_fail "$violations unused output capture(s) in $unique_files file(s):\n$details"
        return 1
    else
        test_pass
    fi
}

# ============================================================================
# ANTI-PATTERN 4: Inline test framework
# Pattern: Files defining their own pass(), fail(), or log_test() functions
# instead of sourcing test-framework.zsh
# ============================================================================

check_inline_framework() {
    test_case "No inline test frameworks (should use shared test-framework.zsh)"

    local violations=0
    typeset -a violation_files
    local details=""

    local f fname hits count
    for f in "${SCAN_FILES[@]}"; do
        fname="${f:t}"
        # Look for function definitions of pass, fail, or log_test
        hits="$(grep -n '^[[:space:]]*\(pass\|fail\|log_test\)()' "$f" 2>/dev/null)"
        if [[ -n "$hits" ]]; then
            count="$(echo "$hits" | wc -l | tr -d ' ')"
            violations=$((violations + count))
            violation_files+=("$fname")
            details+="  $fname: defines $count inline function(s)\n"
        fi
    done

    if (( violations > 0 )); then
        local unique_files=${#violation_files[@]}
        test_fail "$violations inline framework function(s) in $unique_files file(s):\n$details"
        return 1
    else
        test_pass
    fi
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    test_suite_start "Test Quality Dogfood Scanner"

    echo "  Scanning ${#SCAN_FILES[@]} test files for anti-patterns..."
    echo ""

    check_permissive_exit_codes
    check_existence_only_tests
    check_unused_output
    check_inline_framework

    echo ""
    print_summary

    if (( TESTS_FAILED > 0 )); then
        echo ""
        echo "${YELLOW}Found anti-patterns that should be fixed.${RESET}"
        echo "${YELLOW}See docs/specs/ for refactoring guidance.${RESET}"
        exit 1
    else
        echo ""
        echo "${GREEN}All test files are clean — no anti-patterns detected.${RESET}"
        exit 0
    fi
}

main "$@"
