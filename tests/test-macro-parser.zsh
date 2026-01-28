#!/usr/bin/env zsh
# test-macro-parser.zsh - Automated tests for LaTeX macro parser library
# Run with: zsh tests/test-macro-parser.zsh
#
# Tests the macro parser library's functionality including:
# - Helper functions (normalize, count args, extract name/expansion)
# - QMD parsing (```{=tex} blocks)
# - LaTeX parsing (\newcommand, \renewcommand, \DeclareMathOperator)
# - MathJax parsing (macros: { ... } config)
# - Merge and priority resolution
# - Export functions (JSON, MathJax, LaTeX, QMD)

# Don't use set -e - we want to continue after failures

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'

# Counters
typeset -g TESTS_RUN=0
typeset -g TESTS_PASSED=0
typeset -g TESTS_FAILED=0

# Test fixture directory
TEST_FIXTURE_DIR="/tmp/flow-macro-test-$$"

# ============================================================================
# TEST HELPERS
# ============================================================================

test_start() {
    echo -n "${CYAN}TEST: $1${RESET} ... "
    TESTS_RUN=$((TESTS_RUN + 1))
}

test_pass() {
    echo "${GREEN}PASS${RESET}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
    echo "${RED}FAIL${RESET}"
    echo "  ${RED}-> $1${RESET}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

assert_equals() {
    local actual="$1"
    local expected="$2"
    local message="${3:-Values should be equal}"

    if [[ "$actual" == "$expected" ]]; then
        return 0
    else
        # Use printf %q to safely print strings with backslashes
        echo "${RED}FAIL${RESET}"
        printf "  ${RED}-> %s${RESET}\n" "$message" >&2
        printf "  ${RED}   expected: %q${RESET}\n" "$expected" >&2
        printf "  ${RED}   got:      %q${RESET}\n" "$actual" >&2
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-Should contain substring}"

    if [[ "$haystack" == *"$needle"* ]]; then
        return 0
    else
        test_fail "$message (expected to contain: '$needle')"
        return 1
    fi
}

assert_not_empty() {
    local value="$1"
    local message="${2:-Value should not be empty}"

    if [[ -n "$value" ]]; then
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

assert_empty() {
    local value="$1"
    local message="${2:-Value should be empty}"

    if [[ -z "$value" ]]; then
        return 0
    else
        test_fail "$message (got: '$value')"
        return 1
    fi
}

assert_function_exists() {
    local func_name="$1"

    if (( $+functions[$func_name] )); then
        return 0
    else
        test_fail "Function '$func_name' should exist"
        return 1
    fi
}

# ============================================================================
# SETUP
# ============================================================================

echo ""
echo "==========================================================================="
echo "  MACRO PARSER TEST SUITE"
echo "==========================================================================="
echo ""

# Create fixture directory
mkdir -p "$TEST_FIXTURE_DIR"

# Cleanup on exit
cleanup() {
    rm -rf "$TEST_FIXTURE_DIR" 2>/dev/null
}
trap cleanup EXIT

# Source the library under test (avoid sourcing entire plugin)
SCRIPT_DIR="${0:h}"
LIB_FILE="${SCRIPT_DIR}/../lib/macro-parser.zsh"

# Need to mock _flow_log functions if not available
if ! typeset -f _flow_log_debug >/dev/null 2>&1; then
    _flow_log_debug() { :; }
    _flow_log_error() { echo "ERROR: $1" >&2; }
    _flow_log_warning() { :; }
fi

if ! typeset -f _flow_array_contains >/dev/null 2>&1; then
    _flow_array_contains() {
        local needle="$1"
        shift
        for item in "$@"; do
            [[ "$item" == "$needle" ]] && return 0
        done
        return 1
    }
fi

# Reset load guard to allow re-sourcing
unset _FLOW_MACRO_PARSER_LOADED

test_start "Macro parser library loads without errors"
if source "$LIB_FILE" 2>/dev/null; then
    test_pass
else
    test_fail "Library failed to load"
    exit 1
fi

# ============================================================================
# FUNCTION EXISTENCE TESTS
# ============================================================================

echo ""
echo "-- Function Existence --"

test_start "_macro_normalize_name function exists"
if assert_function_exists "_macro_normalize_name"; then
    test_pass
fi

test_start "_macro_count_args function exists"
if assert_function_exists "_macro_count_args"; then
    test_pass
fi

test_start "_macro_extract_name function exists"
if assert_function_exists "_macro_extract_name"; then
    test_pass
fi

test_start "_macro_extract_expansion function exists"
if assert_function_exists "_macro_extract_expansion"; then
    test_pass
fi

test_start "_flow_parse_qmd_macros function exists"
if assert_function_exists "_flow_parse_qmd_macros"; then
    test_pass
fi

test_start "_flow_parse_latex_macros function exists"
if assert_function_exists "_flow_parse_latex_macros"; then
    test_pass
fi

test_start "_flow_parse_mathjax_macros function exists"
if assert_function_exists "_flow_parse_mathjax_macros"; then
    test_pass
fi

# ============================================================================
# HELPER FUNCTION TESTS
# ============================================================================

echo ""
echo "-- Helper Functions --"

# _macro_normalize_name tests
test_start "_macro_normalize_name removes leading backslash"
result=$(_macro_normalize_name "\\E")
if assert_equals "$result" "E"; then
    test_pass
fi

test_start "_macro_normalize_name keeps name without backslash"
result=$(_macro_normalize_name "Var")
if assert_equals "$result" "Var"; then
    test_pass
fi

test_start "_macro_normalize_name handles multi-char names"
result=$(_macro_normalize_name "\\argmax")
if assert_equals "$result" "argmax"; then
    test_pass
fi

# _macro_count_args tests
test_start "_macro_count_args returns 0 for no args"
result=$(_macro_count_args "\\newcommand{\\E}{\\mathbb{E}}")
if assert_equals "$result" "0"; then
    test_pass
fi

test_start "_macro_count_args returns 1 for single arg"
result=$(_macro_count_args "\\newcommand{\\Prob}[1]{P(#1)}")
if assert_equals "$result" "1"; then
    test_pass
fi

test_start "_macro_count_args returns 2 for two args"
result=$(_macro_count_args "\\newcommand{\\Cov}[2]{\\text{Cov}(#1, #2)}")
if assert_equals "$result" "2"; then
    test_pass
fi

# _macro_extract_name tests
test_start "_macro_extract_name extracts from newcommand"
result=$(_macro_extract_name "\\newcommand{\\E}{\\mathbb{E}}")
if assert_equals "$result" "E"; then
    test_pass
fi

test_start "_macro_extract_name extracts from renewcommand"
result=$(_macro_extract_name "\\renewcommand{\\Var}{\\text{Var}}")
if assert_equals "$result" "Var"; then
    test_pass
fi

test_start "_macro_extract_name extracts from DeclareMathOperator"
result=$(_macro_extract_name "\\DeclareMathOperator{\\argmax}{arg\\,max}")
if assert_equals "$result" "argmax"; then
    test_pass
fi

test_start "_macro_extract_name extracts starred DeclareMathOperator"
result=$(_macro_extract_name "\\DeclareMathOperator*{\\argmin}{arg\\,min}")
if assert_equals "$result" "argmin"; then
    test_pass
fi

# _macro_extract_expansion tests
test_start "_macro_extract_expansion extracts simple expansion"
result=$(_macro_extract_expansion "\\newcommand{\\E}{\\mathbb{E}}")
if assert_equals "$result" "\\mathbb{E}"; then
    test_pass
fi

test_start "_macro_extract_expansion extracts complex expansion"
result=$(_macro_extract_expansion "\\newcommand{\\Cov}[2]{\\text{Cov}(#1, #2)}")
if assert_equals "$result" "\\text{Cov}(#1, #2)"; then
    test_pass
fi

test_start "_macro_extract_expansion handles nested braces"
result=$(_macro_extract_expansion "\\newcommand{\\inner}[2]{\\langle #1, #2 \\rangle}")
if assert_equals "$result" "\\langle #1, #2 \\rangle"; then
    test_pass
fi

# ============================================================================
# QMD PARSING TESTS
# ============================================================================

echo ""
echo "-- QMD Parsing --"

# Create QMD fixture with tex block
cat > "$TEST_FIXTURE_DIR/macros.qmd" << 'EOF'
---
title: Test Document
---

Some text here.

```{=tex}
\newcommand{\E}{\mathbb{E}}
\newcommand{\Var}{\text{Var}}
\newcommand{\Cov}[2]{\text{Cov}(#1, #2)}
```

More content.
EOF

test_start "_flow_parse_qmd_macros parses tex blocks"
_flow_clear_macros
_flow_parse_qmd_macros "$TEST_FIXTURE_DIR/macros.qmd"
result="${_FLOW_MACROS[E]}"
if assert_equals "$result" "\\mathbb{E}"; then
    test_pass
fi

test_start "_flow_parse_qmd_macros handles multiple macros"
count=$(_flow_macro_count)
if [[ "$count" -ge 3 ]]; then
    test_pass
else
    test_fail "Expected at least 3 macros, got: $count"
fi

test_start "_flow_parse_qmd_macros captures arg count in metadata"
meta="${_FLOW_MACRO_META[Cov]}"
args="${meta##*:}"
if assert_equals "$args" "2"; then
    test_pass
fi

# Create QMD with no macros
cat > "$TEST_FIXTURE_DIR/empty.qmd" << 'EOF'
---
title: Empty
---

No macros here.

```python
print("hello")
```
EOF

test_start "_flow_parse_qmd_macros handles file with no macros"
_flow_clear_macros
_flow_parse_qmd_macros "$TEST_FIXTURE_DIR/empty.qmd"
count=$(_flow_macro_count)
if assert_equals "$count" "0"; then
    test_pass
fi

# Empty file test
touch "$TEST_FIXTURE_DIR/truly-empty.qmd"

test_start "_flow_parse_qmd_macros handles empty file"
_flow_clear_macros
_flow_parse_qmd_macros "$TEST_FIXTURE_DIR/truly-empty.qmd"
count=$(_flow_macro_count)
if assert_equals "$count" "0"; then
    test_pass
fi

# ============================================================================
# LATEX PARSING TESTS
# ============================================================================

echo ""
echo "-- LaTeX Parsing --"

# Create LaTeX fixture
cat > "$TEST_FIXTURE_DIR/macros.tex" << 'EOF'
% Macro definitions for course
\newcommand{\E}{\mathbb{E}}
\renewcommand{\P}{\mathbb{P}}
\DeclareMathOperator{\argmax}{arg\,max}
% Multi-line definition
\newcommand{\conditional}[2]{%
    #1 \mid #2%
}
EOF

test_start "_flow_parse_latex_macros parses newcommand"
_flow_clear_macros
_flow_parse_latex_macros "$TEST_FIXTURE_DIR/macros.tex"
result="${_FLOW_MACROS[E]}"
if assert_equals "$result" "\\mathbb{E}"; then
    test_pass
fi

test_start "_flow_parse_latex_macros parses renewcommand"
result="${_FLOW_MACROS[P]}"
if assert_equals "$result" "\\mathbb{P}"; then
    test_pass
fi

test_start "_flow_parse_latex_macros parses DeclareMathOperator"
result="${_FLOW_MACROS[argmax]}"
if assert_equals "$result" "arg\\,max"; then
    test_pass
fi

test_start "_flow_parse_latex_macros handles multi-line definitions"
result="${_FLOW_MACROS[conditional]}"
if assert_contains "$result" "#1"; then
    if assert_contains "$result" "#2"; then
        test_pass
    fi
fi

test_start "_flow_parse_latex_macros skips comment-only lines"
# Count total macros - should be 4 (E, P, argmax, conditional)
count=$(_flow_macro_count)
if [[ "$count" -eq 4 ]]; then
    test_pass
else
    test_fail "Expected 4 macros, got: $count"
fi

# ============================================================================
# MATHJAX PARSING TESTS
# ============================================================================

echo ""
echo "-- MathJax Parsing --"

# Create MathJax config fixture
cat > "$TEST_FIXTURE_DIR/mathjax.html" << 'EOF'
<script>
MathJax = {
  tex: {
    macros: {
      E: "\\mathbb{E}",
      Var: "\\text{Var}",
      Cov: ["\\text{Cov}(#1, #2)", 2],
      Prob: ["P(#1)", 1]
    }
  }
};
</script>
EOF

test_start "_flow_parse_mathjax_macros parses simple macro"
_flow_clear_macros
_flow_parse_mathjax_macros "$TEST_FIXTURE_DIR/mathjax.html"
result="${_FLOW_MACROS[E]}"
# MathJax stores double-backslash from HTML escaping
if assert_contains "$result" "mathbb"; then
    if assert_contains "$result" "E"; then
        test_pass
    fi
fi

test_start "_flow_parse_mathjax_macros parses macro with args"
result="${_FLOW_MACROS[Cov]}"
# Check for key parts (backslash escaping varies)
if assert_contains "$result" "text"; then
    if assert_contains "$result" "Cov"; then
        test_pass
    fi
fi

test_start "_flow_parse_mathjax_macros captures arg count"
meta="${_FLOW_MACRO_META[Cov]}"
args="${meta##*:}"
if assert_equals "$args" "2"; then
    test_pass
fi

# MathJax with extra whitespace
cat > "$TEST_FIXTURE_DIR/mathjax-whitespace.html" << 'EOF'
<script>
MathJax = {
  tex: {
    macros: {
      Norm  :   "\\|\\cdot\\|"   ,
      Inner :   ["\\langle #1, #2 \\rangle"  ,  2]
    }
  }
};
</script>
EOF

test_start "_flow_parse_mathjax_macros handles extra whitespace"
_flow_clear_macros
_flow_parse_mathjax_macros "$TEST_FIXTURE_DIR/mathjax-whitespace.html"
count=$(_flow_macro_count)
if [[ "$count" -ge 1 ]]; then
    test_pass
else
    test_fail "Expected at least 1 macro, got: $count"
fi

# MathJax with JavaScript comments
cat > "$TEST_FIXTURE_DIR/mathjax-comments.js" << 'EOF'
// MathJax configuration
MathJax = {
  tex: {
    macros: {
      // Expected value
      E: "\\mathbb{E}",
      /* Variance */
      Var: "\\text{Var}"
    }
  }
};
EOF

test_start "_flow_parse_mathjax_macros handles JS with comments"
_flow_clear_macros
_flow_parse_mathjax_macros "$TEST_FIXTURE_DIR/mathjax-comments.js"
# Should still parse macros (comments on separate lines)
if [[ -n "${_FLOW_MACROS[E]}" ]]; then
    test_pass
else
    test_fail "Should parse E macro despite comments"
fi

# ============================================================================
# MERGE AND PRIORITY TESTS
# ============================================================================

echo ""
echo "-- Merge and Priority --"

# Create two macro files with overlapping definitions
cat > "$TEST_FIXTURE_DIR/base.qmd" << 'EOF'
```{=tex}
\newcommand{\E}{\mathbb{E}}
\newcommand{\Original}{\text{base}}
```
EOF

cat > "$TEST_FIXTURE_DIR/override.qmd" << 'EOF'
```{=tex}
\newcommand{\E}{E_{\text{override}}}
\newcommand{\Extra}{\text{extra}}
```
EOF

test_start "_flow_merge_macros combines multiple sources"
_flow_merge_macros "$TEST_FIXTURE_DIR/base.qmd" "$TEST_FIXTURE_DIR/override.qmd"
# Should have Original, E (overridden), and Extra
if [[ -n "${_FLOW_MACROS[Original]}" && -n "${_FLOW_MACROS[Extra]}" ]]; then
    test_pass
else
    test_fail "Should have macros from both sources"
fi

test_start "_flow_merge_macros later source overrides earlier"
result="${_FLOW_MACROS[E]}"
if assert_contains "$result" "override"; then
    test_pass
fi

test_start "_flow_merge_macros clears existing before merge"
# Add a macro manually
_FLOW_MACROS[ManualAdd]="test"
_flow_merge_macros "$TEST_FIXTURE_DIR/base.qmd"
if [[ -z "${_FLOW_MACROS[ManualAdd]}" ]]; then
    test_pass
else
    test_fail "Manual macro should be cleared on merge"
fi

test_start "_flow_merge_macros returns error for no valid sources"
if ! _flow_merge_macros "/nonexistent/file.qmd" 2>/dev/null; then
    test_pass
else
    test_fail "Should return error for no valid sources"
fi

# ============================================================================
# EXPORT FUNCTION TESTS
# ============================================================================

echo ""
echo "-- Export Functions --"

# Setup known macros for export tests
_flow_clear_macros
_FLOW_MACROS[E]="\\mathbb{E}"
_FLOW_MACROS[Cov]="\\text{Cov}(#1, #2)"
_FLOW_MACRO_META[E]="test.qmd:1:0"
_FLOW_MACRO_META[Cov]="test.qmd:2:2"

test_start "_flow_export_macros_json produces valid JSON structure"
result=$(_flow_export_macros_json)
if assert_contains "$result" '"E"'; then
    if assert_contains "$result" '"expansion"'; then
        if assert_contains "$result" '"args"'; then
            test_pass
        fi
    fi
fi

test_start "_flow_export_macros_mathjax produces macros block"
result=$(_flow_export_macros_mathjax)
if assert_contains "$result" "macros: {"; then
    if assert_contains "$result" "E:"; then
        test_pass
    fi
fi

test_start "_flow_export_macros_latex produces newcommand definitions"
result=$(_flow_export_macros_latex)
if assert_contains "$result" "\\newcommand"; then
    if assert_contains "$result" "{\\E}"; then
        test_pass
    fi
fi

test_start "_flow_export_macros_qmd wraps in tex block"
result=$(_flow_export_macros_qmd)
if assert_contains "$result" '```{=tex}'; then
    if assert_contains "$result" '```'; then
        test_pass
    fi
fi

# ============================================================================
# REGISTRY FUNCTION TESTS
# ============================================================================

echo ""
echo "-- Registry Functions --"

test_start "_flow_get_macro retrieves existing macro"
_flow_clear_macros
_FLOW_MACROS[TestMacro]="\\test"
result=$(_flow_get_macro "TestMacro")
if assert_equals "$result" "\\test"; then
    test_pass
fi

test_start "_flow_get_macro returns error for missing macro"
if ! _flow_get_macro "NonExistent" 2>/dev/null; then
    test_pass
else
    test_fail "Should return error for missing macro"
fi

test_start "_flow_get_macro handles backslash prefix"
result=$(_flow_get_macro "\\TestMacro")
if assert_equals "$result" "\\test"; then
    test_pass
fi

test_start "_flow_list_macros lists all macro names"
_flow_clear_macros
_FLOW_MACROS[Alpha]="a"
_FLOW_MACROS[Beta]="b"
_FLOW_MACROS[Gamma]="c"
result=$(_flow_list_macros)
if assert_contains "$result" "Alpha"; then
    if assert_contains "$result" "Beta"; then
        if assert_contains "$result" "Gamma"; then
            test_pass
        fi
    fi
fi

test_start "_flow_macro_count returns correct count"
count=$(_flow_macro_count)
if assert_equals "$count" "3"; then
    test_pass
fi

test_start "_flow_clear_macros empties registry"
_flow_clear_macros
count=$(_flow_macro_count)
if assert_equals "$count" "0"; then
    test_pass
fi

# ============================================================================
# EDGE CASES
# ============================================================================

echo ""
echo "-- Edge Cases --"

test_start "Handles file not found gracefully"
if ! _flow_parse_macros "/nonexistent/path/file.qmd" 2>/dev/null; then
    test_pass
else
    test_fail "Should return error for missing file"
fi

test_start "Auto-detects format from .tex extension"
_flow_clear_macros
cat > "$TEST_FIXTURE_DIR/auto.tex" << 'EOF'
\newcommand{\Auto}{\text{auto}}
EOF
_flow_parse_macros "$TEST_FIXTURE_DIR/auto.tex"
if [[ -n "${_FLOW_MACROS[Auto]}" ]]; then
    test_pass
else
    test_fail "Should auto-detect .tex format"
fi

test_start "Auto-detects format from .qmd extension"
_flow_clear_macros
cat > "$TEST_FIXTURE_DIR/auto.qmd" << 'EOF'
```{=tex}
\newcommand{\AutoQmd}{\text{qmd}}
```
EOF
_flow_parse_macros "$TEST_FIXTURE_DIR/auto.qmd"
if [[ -n "${_FLOW_MACROS[AutoQmd]}" ]]; then
    test_pass
else
    test_fail "Should auto-detect .qmd format"
fi

test_start "Auto-detects MathJax from content"
_flow_clear_macros
cat > "$TEST_FIXTURE_DIR/auto-detect.txt" << 'EOF'
MathJax = {
  tex: {
    macros: {
      DetectedMJ: "\\text{mj}"
    }
  }
};
EOF
_flow_parse_macros "$TEST_FIXTURE_DIR/auto-detect.txt"
if [[ -n "${_FLOW_MACROS[DetectedMJ]}" ]]; then
    test_pass
else
    test_fail "Should detect MathJax from content"
fi

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
echo "==========================================================================="
echo "  TEST SUMMARY"
echo "==========================================================================="
echo ""
echo "  Total:  $TESTS_RUN"
echo "  ${GREEN}Passed: $TESTS_PASSED${RESET}"
echo "  ${RED}Failed: $TESTS_FAILED${RESET}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "${GREEN}ALL TESTS PASSED${RESET}"
    echo ""
    exit 0
else
    echo "${RED}SOME TESTS FAILED${RESET}"
    echo ""
    exit 1
fi
