#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# ZSH SYSTEM HEALTH CHECK TEST SUITE
# ══════════════════════════════════════════════════════════════════════════════
#
# Comprehensive health checks for ZSH configuration:
# - Duplicate function definitions
# - Alias/function/binary conflicts
# - Stdout pollution in helpers
# - Symlink validation
# - Circular sourcing
# - Naming conventions
#
# Usage:
#   ./test-system-health.zsh                    # Run all tests
#   ./test-system-health.zsh --only=duplicates  # Run specific test
#   ./test-system-health.zsh -v                 # Verbose mode
#   ./test-system-health.zsh --ci               # CI mode (minimal output)
#
# ══════════════════════════════════════════════════════════════════════════════

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_WARNED=0

# Configuration
VERBOSE=false
CI_MODE=false
TEST_FILTER=""

# Paths - v3.0.0 architecture
PLUGIN_ROOT="${0:A:h:h:h}"
ZSH_FUNCTIONS_DIR="$PLUGIN_ROOT/lib"
COMMANDS_DIR="$PLUGIN_ROOT/commands"
DISPATCHERS_DIR="$PLUGIN_ROOT/lib/dispatchers"
ZSH_TESTS_DIR="$PLUGIN_ROOT/zsh/tests"
FIXTURES_DIR="$ZSH_TESTS_DIR/test-fixtures"
WHITELIST_DUPLICATES="$FIXTURES_DIR/expected-duplicates.txt"
WHITELIST_SHADOWS="$FIXTURES_DIR/intentional-shadows.txt"

# Global storage for function catalog
typeset -A FUNCTION_LOCATIONS  # func_name → "file1:line1,file2:line2,..."
typeset -A ALIAS_LOCATIONS     # alias_name → "file1:line1,file2:line2,..."

# ══════════════════════════════════════════════════════════════════════════════
# TEST FRAMEWORK HELPERS
# ══════════════════════════════════════════════════════════════════════════════

pass() {
    ((TESTS_PASSED++))
    [[ "$CI_MODE" == "true" ]] && return
    echo "${GREEN}✓ PASS${NC}: $1"
}

fail() {
    ((TESTS_FAILED++))
    [[ "$CI_MODE" == "true" ]] && return
    echo "${RED}✗ FAIL${NC}: $1"
    if [[ -n "$2" ]]; then
        echo "  ${DIM}$2${NC}"
    fi
}

warn() {
    ((TESTS_WARNED++))
    [[ "$CI_MODE" == "true" ]] && return
    echo "${YELLOW}⚠ INFO${NC}: $1"
}

run_test() {
    ((TESTS_RUN++))
    [[ "$CI_MODE" == "true" ]] && return
    echo ""
    echo "${YELLOW}━━━ Test $TESTS_RUN: $1 ━━━${NC}"
}

# ══════════════════════════════════════════════════════════════════════════════
# UTILITY FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

# Check if function is whitelisted
is_whitelisted() {
    local func_name="$1"
    local whitelist_file="$2"

    [[ ! -f "$whitelist_file" ]] && return 1

    grep -q "^${func_name}|" "$whitelist_file" 2>/dev/null
}

# Extract function name from grep match
extract_function_name() {
    local line="$1"

    # Remove leading whitespace
    line="${line#"${line%%[![:space:]]*}"}"

    # Handle "function name() {" or "function name {" or "name() {"
    if [[ "$line" =~ ^function[[:space:]]+([a-zA-Z_][a-zA-Z0-9_-]*) ]]; then
        echo "${match[1]}"
    elif [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_-]*)\(\) ]]; then
        echo "${match[1]}"
    fi
}

# Get whitelist reason
get_whitelist_reason() {
    local func_name="$1"
    local whitelist_file="$2"

    [[ ! -f "$whitelist_file" ]] && return 1

    local line=$(grep "^${func_name}|" "$whitelist_file" 2>/dev/null)
    if [[ -n "$line" ]]; then
        echo "$line" | cut -d'|' -f3
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# FUNCTION CATALOG BUILDER
# ══════════════════════════════════════════════════════════════════════════════

build_function_catalog() {
    [[ "$VERBOSE" == "true" ]] && echo "${DIM}Building function catalog...${NC}"

    # Clear existing catalog
    FUNCTION_LOCATIONS=()

    # Scan all .zsh files in functions directory
    for file in "$ZSH_FUNCTIONS_DIR"/*.zsh(N); do
        # Skip symlinks
        [[ -L "$file" ]] && continue

        local basename=$(basename "$file")
        [[ "$VERBOSE" == "true" ]] && echo "${DIM}  Scanning $basename...${NC}"

        # Find function definitions
        # Pattern matches: function name() {, function name {, name() {
        while IFS=: read -r line_num line_content; do
            local func_name=$(extract_function_name "$line_content")

            if [[ -n "$func_name" ]]; then
                if [[ -n "${FUNCTION_LOCATIONS[$func_name]}" ]]; then
                    # Duplicate found - append location
                    FUNCTION_LOCATIONS[$func_name]+=",${basename}:${line_num}"
                else
                    # First occurrence
                    FUNCTION_LOCATIONS[$func_name]="${basename}:${line_num}"
                fi
            fi
        done < <(grep -En "^(function )?[a-zA-Z_][a-zA-Z0-9_-]*(\(\))? *\{" "$file" 2>/dev/null)
    done

    local func_count=${#FUNCTION_LOCATIONS[@]}
    [[ "$VERBOSE" == "true" ]] && echo "${DIM}Found $func_count unique function names${NC}"
}

# ══════════════════════════════════════════════════════════════════════════════
# ALIAS CATALOG BUILDER
# ══════════════════════════════════════════════════════════════════════════════

build_alias_catalog() {
    [[ "$VERBOSE" == "true" ]] && echo "${DIM}Building alias catalog...${NC}"

    # Clear existing catalog
    ALIAS_LOCATIONS=()

    # Scan .zshrc for aliases
    while IFS=: read -r line_num line_content; do
        if [[ "$line_content" =~ ^alias[[:space:]]+([a-zA-Z_][a-zA-Z0-9_-]*)= ]]; then
            local alias_name="${match[1]}"
            ALIAS_LOCATIONS[$alias_name]=".zshrc:${line_num}"
        fi
    done < <(grep -En "^alias " "$ZSH_ZSHRC" 2>/dev/null)

    # Scan function files for aliases
    for file in "$ZSH_FUNCTIONS_DIR"/*.zsh(N); do
        [[ -L "$file" ]] && continue

        local basename=$(basename "$file")
        [[ "$VERBOSE" == "true" ]] && echo "${DIM}  Scanning $basename for aliases...${NC}"

        while IFS=: read -r line_num line_content; do
            if [[ "$line_content" =~ ^alias[[:space:]]+([a-zA-Z_][a-zA-Z0-9_-]*)= ]]; then
                local alias_name="${match[1]}"
                if [[ -n "${ALIAS_LOCATIONS[$alias_name]}" ]]; then
                    # Duplicate alias - append location
                    ALIAS_LOCATIONS[$alias_name]+=",${basename}:${line_num}"
                else
                    # First occurrence
                    ALIAS_LOCATIONS[$alias_name]="${basename}:${line_num}"
                fi
            fi
        done < <(grep -En "^alias " "$file" 2>/dev/null)
    done

    local alias_count=${#ALIAS_LOCATIONS[@]}
    [[ "$VERBOSE" == "true" ]] && echo "${DIM}Found $alias_count unique alias names${NC}"
}

# ══════════════════════════════════════════════════════════════════════════════
# TEST 1: DUPLICATE FUNCTION DETECTION
# ══════════════════════════════════════════════════════════════════════════════

test_duplicate_functions() {
    run_test "Duplicate Function Detection"

    local total_funcs=${#FUNCTION_LOCATIONS[@]}
    [[ "$CI_MODE" == "false" ]] && echo "${DIM}Scanning 9 function files...${NC}"
    [[ "$CI_MODE" == "false" ]] && echo "${DIM}Found $total_funcs unique functions${NC}"
    [[ "$CI_MODE" == "false" ]] && echo ""

    local unexpected_duplicates=0
    local whitelisted_duplicates=0

    # Check each function for duplicates
    for func_name in "${(@k)FUNCTION_LOCATIONS}"; do
        local locations="${FUNCTION_LOCATIONS[$func_name]}"
        local count=$(echo "$locations" | tr ',' '\n' | wc -l | tr -d ' ')

        if [[ $count -gt 1 ]]; then
            # Duplicate found
            if is_whitelisted "$func_name" "$WHITELIST_DUPLICATES"; then
                # Expected duplicate
                ((whitelisted_duplicates++))
                local reason=$(get_whitelist_reason "$func_name" "$WHITELIST_DUPLICATES")
                pass "Expected override: ${func_name}() (whitelisted)"

                if [[ "$VERBOSE" == "true" ]] || [[ "$CI_MODE" == "false" ]]; then
                    echo "$locations" | tr ',' '\n' | while read loc; do
                        echo "  ${DIM}→ $loc${NC}"
                    done
                    [[ -n "$reason" ]] && echo "  ${DIM}Reason: $reason${NC}"
                fi
            else
                # Unexpected duplicate
                ((unexpected_duplicates++))
                fail "Unexpected duplicate: ${func_name}()" "Found in $count files:"
                echo "$locations" | tr ',' '\n' | while read loc; do
                    echo "  ${RED}→ $loc${NC}"
                done
                echo ""
                echo "  ${CYAN}🔧 FIX:${NC} Remove duplicate definitions or add to whitelist"
                echo "  ${DIM}Whitelist: $WHITELIST_DUPLICATES${NC}"
            fi
        fi
    done

    # Summary
    if [[ $unexpected_duplicates -eq 0 ]]; then
        pass "No unexpected duplicates found"
    fi

    [[ "$CI_MODE" == "false" ]] && echo ""
    [[ "$CI_MODE" == "false" ]] && echo "${DIM}Summary: $whitelisted_duplicates whitelisted, $unexpected_duplicates unexpected${NC}"
}

# ══════════════════════════════════════════════════════════════════════════════
# TEST 2: ALIAS-FUNCTION CONFLICTS
# ══════════════════════════════════════════════════════════════════════════════

test_alias_conflicts() {
    run_test "Alias-Function Conflict Detection"

    local total_aliases=${#ALIAS_LOCATIONS[@]}
    [[ "$CI_MODE" == "false" ]] && echo "${DIM}Found $total_aliases aliases${NC}"
    [[ "$CI_MODE" == "false" ]] && echo ""

    local conflicts_found=0
    local intentional_overrides=0

    # Check each function to see if it conflicts with an alias
    for func_name in "${(@k)FUNCTION_LOCATIONS}"; do
        if [[ -n "${ALIAS_LOCATIONS[$func_name]}" ]]; then
            # Conflict found
            local func_loc="${FUNCTION_LOCATIONS[$func_name]}"
            local alias_loc="${ALIAS_LOCATIONS[$func_name]}"

            # Check if this is an intentional override (unalias pattern)
            local func_file=$(echo "$func_loc" | cut -d: -f1)
            local has_unalias=$(grep -q "^unalias $func_name" "$ZSH_FUNCTIONS_DIR/$func_file" 2>/dev/null && echo "yes" || echo "no")

            if [[ "$has_unalias" == "yes" ]]; then
                ((intentional_overrides++))
                pass "Intentional override: ${func_name} (function replaces alias)"
                if [[ "$VERBOSE" == "true" ]] || [[ "$CI_MODE" == "false" ]]; then
                    echo "  ${DIM}Alias:    $alias_loc${NC}"
                    echo "  ${DIM}Function: $func_loc${NC}"
                    echo "  ${DIM}Pattern:  unalias before function definition${NC}"
                fi
            else
                ((conflicts_found++))
                warn "Potential conflict: ${func_name}"
                echo "  Alias:    $alias_loc"
                echo "  Function: $func_loc"
                echo ""
                echo "  ${CYAN}💡 SOLUTIONS:${NC}"
                echo "  ${DIM}1. Add 'unalias $func_name 2>/dev/null' before function definition (recommended)${NC}"
                echo "  ${DIM}2. Rename alias or function to avoid conflict${NC}"
                echo "  ${DIM}3. Remove alias if function provides better behavior${NC}"
            fi
        fi
    done

    if [[ $conflicts_found -eq 0 ]]; then
        pass "No unexpected alias-function conflicts"
    fi

    [[ "$CI_MODE" == "false" ]] && echo ""
    [[ "$CI_MODE" == "false" ]] && echo "${DIM}Summary: $intentional_overrides intentional, $conflicts_found to review${NC}"
}

# ══════════════════════════════════════════════════════════════════════════════
# TEST 3: BINARY-FUNCTION CONFLICTS
# ══════════════════════════════════════════════════════════════════════════════

test_binary_conflicts() {
    run_test "Binary-Function Conflict Detection"

    # Load whitelist
    typeset -A WHITELISTED_SHADOWS
    if [[ -f "$WHITELIST_SHADOWS" ]]; then
        while IFS='|' read -r func_name binary_path reason; do
            [[ "$func_name" =~ ^# ]] && continue  # Skip comments
            [[ -z "$func_name" ]] && continue
            WHITELISTED_SHADOWS[$func_name]="$binary_path|$reason"
        done < "$WHITELIST_SHADOWS"
    fi

    local whitelisted_count=0
    local new_shadows=0

    # Check each function for binary shadowing
    for func_name in "${(@k)FUNCTION_LOCATIONS}"; do
        # Check if this shadows a binary/builtin
        local which_output=$(which -a "$func_name" 2>/dev/null | grep -v "shell function" | grep -v "not found")

        if [[ -n "$which_output" ]]; then
            # Function shadows a binary/builtin
            local func_loc="${FUNCTION_LOCATIONS[$func_name]}"

            if [[ -n "${WHITELISTED_SHADOWS[$func_name]}" ]]; then
                # Intentional shadow
                ((whitelisted_count++))
                local reason=$(echo "${WHITELISTED_SHADOWS[$func_name]}" | cut -d'|' -f2)
                pass "Intentional override: ${func_name}() shadows binary (whitelisted)"

                if [[ "$VERBOSE" == "true" ]] || [[ "$CI_MODE" == "false" ]]; then
                    echo "  ${DIM}Function:  $func_loc${NC}"
                    echo "  ${DIM}Binary:    $which_output${NC}"
                    echo "  ${DIM}Reason:    $reason${NC}"
                    echo "  ${DIM}Access original: command $func_name${NC}"
                fi
            else
                # New shadow - propose making it official
                ((new_shadows++))
                warn "Function shadows binary: ${func_name}"
                echo "  Function:  $func_loc"
                echo "  Binary:    $which_output"
                echo ""
                echo "  ${CYAN}💡 SOLUTIONS:${NC}"
                echo "  ${DIM}1. Add to whitelist if intentional (RECOMMENDED for workflow optimization):${NC}"
                echo "     ${DIM}echo '$func_name|$(echo $which_output | head -1)|Your workflow reason' >> $WHITELIST_SHADOWS${NC}"
                echo "  ${DIM}2. Rename function to avoid shadowing${NC}"
                echo "  ${DIM}3. Access original binary: command $func_name${NC}"
                echo ""
                echo "  ${GREEN}✨ TIP: Shadowing binaries is GOOD for creating optimized workflows!${NC}"
            fi
        fi
    done

    if [[ $new_shadows -eq 0 ]]; then
        pass "All binary shadows are intentional and documented"
    fi

    [[ "$CI_MODE" == "false" ]] && echo ""
    [[ "$CI_MODE" == "false" ]] && echo "${DIM}Summary: $whitelisted_count intentional shadows, $new_shadows to review${NC}"
}

# ══════════════════════════════════════════════════════════════════════════════
# TEST 4: STDOUT POLLUTION DETECTION
# ══════════════════════════════════════════════════════════════════════════════

test_stdout_pollution() {
    run_test "Stdout Pollution Detection"

    # Whitelist of functions that SHOULD output (reporting/UI functions)
    local -a REPORTING_FUNCTIONS=(
        dash just-start status system-status obs-status
        here what-next win gm od ops medcheck
        ah tweek tst rst help
    )

    local pollution_count=0
    local clean_count=0

    # Check each function for output statements
    for func_name in "${(@k)FUNCTION_LOCATIONS}"; do
        local locations="${FUNCTION_LOCATIONS[$func_name]}"
        local first_loc=$(echo "$locations" | cut -d',' -f1)
        local file=$(echo "$first_loc" | cut -d':' -f1)
        local line_num=$(echo "$first_loc" | cut -d':' -f2)

        # Count echo/print/printf statements in function body
        local output_lines=$(awk -v start="$line_num" '
            NR >= start && /^[[:space:]]*(echo|print|printf)/ { print NR }
            NR > start && /^}[[:space:]]*$/ { exit }
        ' "$ZSH_FUNCTIONS_DIR/$file" 2>/dev/null)

        local output_count=0
        if [[ -n "$output_lines" ]]; then
            output_count=$(echo "$output_lines" | grep -c .)
        fi

        if [[ $output_count -gt 0 ]]; then
            # Function has output - check if it's a reporting function
            if [[ " ${REPORTING_FUNCTIONS[@]} " =~ " ${func_name} " ]]; then
                # Expected output
                ((clean_count++))
                if [[ "$VERBOSE" == "true" ]]; then
                    pass "Reporting function: ${func_name}() ($output_count output statements - expected)"
                fi
            else
                # Unexpected output - potential pollution
                ((pollution_count++))
                warn "Potential stdout pollution: ${func_name}()"
                echo "  Location: $first_loc"
                echo "  Output statements: $output_count"
                echo "  Lines: $(echo $output_lines | tr '\n' ',' | sed 's/,$//')"
                echo ""
                echo "  ${CYAN}💡 SOLUTIONS:${NC}"
                echo "  ${DIM}1. If this is a reporting function, add to whitelist:${NC}"
                echo "     ${DIM}REPORTING_FUNCTIONS+=($func_name)${NC}"
                echo "  ${DIM}2. Redirect output to stderr: echo \"...\" >&2${NC}"
                echo "  ${DIM}3. Remove unnecessary output for cleaner piping${NC}"
            fi
        fi
    done

    if [[ $pollution_count -eq 0 ]]; then
        pass "No unexpected stdout pollution detected"
    fi

    [[ "$CI_MODE" == "false" ]] && echo ""
    [[ "$CI_MODE" == "false" ]] && echo "${DIM}Summary: $clean_count reporting functions, $pollution_count to review${NC}"
}

# ══════════════════════════════════════════════════════════════════════════════
# PARSE ARGUMENTS
# ══════════════════════════════════════════════════════════════════════════════

while [[ $# -gt 0 ]]; do
    case "$1" in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        --ci)
            CI_MODE=true
            shift
            ;;
        --only=*)
            TEST_FILTER="${1#*=}"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -v, --verbose       Verbose output"
            echo "  --ci                CI mode (minimal output)"
            echo "  --only=TEST         Run specific test (duplicates, conflicts, pollution)"
            echo "  -h, --help          Show this help"
            echo ""
            echo "Available Tests:"
            echo "  duplicates          Duplicate function definitions"
            echo "  conflicts           Alias-function & binary-function conflicts"
            echo "  pollution           Stdout pollution detection"
            echo ""
            echo "Examples:"
            echo "  $0                  Run all tests"
            echo "  $0 --only=duplicates"
            echo "  $0 --only=conflicts"
            echo "  $0 -v"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# ══════════════════════════════════════════════════════════════════════════════
# MAIN EXECUTION
# ══════════════════════════════════════════════════════════════════════════════

# Print header
if [[ "$CI_MODE" == "false" ]]; then
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  ${BOLD}ZSH SYSTEM HEALTH CHECK${NC}                                   ║"
    echo "║  ${DIM}$HOME/.config/zsh${NC}                                     ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "${DIM}[$(date '+%Y-%m-%d %H:%M:%S')] Starting health check...${NC}"
fi

# Build catalogs (needed for multiple tests)
build_function_catalog
build_alias_catalog

# Run tests
if [[ -z "$TEST_FILTER" ]] || [[ "$TEST_FILTER" == *"duplicates"* ]]; then
    test_duplicate_functions
fi

if [[ -z "$TEST_FILTER" ]] || [[ "$TEST_FILTER" == *"conflicts"* ]]; then
    test_alias_conflicts
    test_binary_conflicts
fi

if [[ -z "$TEST_FILTER" ]] || [[ "$TEST_FILTER" == *"pollution"* ]]; then
    test_stdout_pollution
fi

# TODO: Add more tests here (Test 5-7)
# if [[ -z "$TEST_FILTER" ]] || [[ "$TEST_FILTER" == *"symlinks"* ]]; then
#     test_symlink_validation
# fi
#
# if [[ -z "$TEST_FILTER" ]] || [[ "$TEST_FILTER" == *"sourcing"* ]]; then
#     test_circular_sourcing
# fi
#
# if [[ -z "$TEST_FILTER" ]] || [[ "$TEST_FILTER" == *"naming"* ]]; then
#     test_naming_conventions
# fi

# ══════════════════════════════════════════════════════════════════════════════
# RESULTS
# ══════════════════════════════════════════════════════════════════════════════

if [[ "$CI_MODE" == "false" ]]; then
    echo ""
    echo "══════════════════════════════════════════════════════════════════"
    echo "  ${BOLD}TEST RESULTS${NC}"
    echo "══════════════════════════════════════════════════════════════════"
    echo ""
    echo "  Tests run:    $TESTS_RUN"
    echo "  ${GREEN}Passed:       $TESTS_PASSED${NC}"
    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo "  ${RED}Failed:       $TESTS_FAILED${NC}"
    else
        echo "  Failed:       $TESTS_FAILED"
    fi
    if [[ $TESTS_WARNED -gt 0 ]]; then
        echo "  ${YELLOW}Warnings:     $TESTS_WARNED${NC}"
    fi
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "  Status:       ${GREEN}✅ HEALTHY${NC}"
    else
        echo "  Status:       ${RED}❌ UNHEALTHY${NC} - Issues detected"
    fi
    echo "══════════════════════════════════════════════════════════════════"
    echo ""
fi

# Exit with appropriate code
if [[ $TESTS_FAILED -gt 0 ]]; then
    exit 1
else
    exit 0
fi
