#!/usr/bin/env bash

# ============================================================================
# ZSH Configuration Linter
# ============================================================================
# Purpose: Static analysis to catch common anti-patterns before they cause bugs
# Created: 2025-12-19
# Location: ~/.config/zsh/scripts/lint-zsh.sh
#
# Usage:
#   ./lint-zsh.sh                    # Lint all files
#   ./lint-zsh.sh path/to/file.zsh   # Lint specific file
#   ./lint-zsh.sh --fix              # Auto-fix some issues (future)
#
# Exit codes:
#   0 - No issues found
#   1 - Issues found
#   2 - Critical issues found (will cause shell errors)
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Counters
ERRORS=0
WARNINGS=0
FILES_CHECKED=0

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${BOLD}  ZSH Configuration Linter                              ${NC}${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

error() {
    local file="$1"
    local line="$2"
    local message="$3"
    ((ERRORS++))
    echo -e "${RED}✗ ERROR${NC} ${file}:${line}"
    echo -e "  ${RED}→${NC} $message"
}

warning() {
    local file="$1"
    local line="$2"
    local message="$3"
    ((WARNINGS++))
    echo -e "${YELLOW}⚠ WARNING${NC} ${file}:${line}"
    echo -e "  ${YELLOW}→${NC} $message"
}

print_summary() {
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "  Files Checked: ${FILES_CHECKED}"

    if [[ $ERRORS -gt 0 ]]; then
        echo -e "  ${RED}Errors: $ERRORS${NC}"
    else
        echo -e "  ${GREEN}Errors: 0${NC}"
    fi

    if [[ $WARNINGS -gt 0 ]]; then
        echo -e "  ${YELLOW}Warnings: $WARNINGS${NC}"
    else
        echo -e "  ${GREEN}Warnings: 0${NC}"
    fi

    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo ""

    if [[ $ERRORS -gt 0 ]]; then
        echo -e "${RED}❌ Linting failed - please fix errors${NC}"
        return 2
    elif [[ $WARNINGS -gt 0 ]]; then
        echo -e "${YELLOW}⚠️  Linting passed with warnings${NC}"
        return 1
    else
        echo -e "${GREEN}✅ Linting passed - no issues found${NC}"
        return 0
    fi
}

# ============================================================================
# Lint Rules
# ============================================================================

# Rule 1: No command substitution of interactive functions
lint_interactive_function_capture() {
    local file="$1"
    local line_num=0

    # List of interactive functions that should never be captured
    local interactive_funcs=(
        "pick"
        "pickr"
        "pickdev"
        "pickq"
    )

    while IFS= read -r line; do
        ((line_num++))

        for func in "${interactive_funcs[@]}"; do
            # Check for $(<function>) pattern
            if echo "$line" | grep -qE "\\\$\($func\)"; then
                error "$file" "$line_num" "Command substitution of interactive function: \$($func)"
                echo -e "    ${RED}Suggestion:${NC} Use '$func && next_command' instead"
                echo -e "    ${RED}Line:${NC} $line"
            fi

            # Check for local var=$(function) pattern
            if echo "$line" | grep -qE "local.*=\\\$\($func"; then
                error "$file" "$line_num" "Capturing interactive function in variable: $func"
                echo -e "    ${RED}Suggestion:${NC} Interactive functions should not return values"
                echo -e "    ${RED}Line:${NC} $line"
            fi
        done
    done < "$file"
}

# Rule 2: Programmatic functions should redirect UI to stderr
lint_stdout_pollution() {
    local file="$1"
    local line_num=0
    local in_programmatic_func=false
    local func_name=""

    # Functions that are commonly captured (return values via stdout)
    local programmatic_funcs=(
        "_proj_find"
        "_proj_name_from_path"
        "_proj_detect_type"
        "_get_"
    )

    while IFS= read -r line; do
        ((line_num++))

        # Detect function start
        for func in "${programmatic_funcs[@]}"; do
            if echo "$line" | grep -qE "^${func}.*\(\)"; then
                in_programmatic_func=true
                func_name="$func"
                break
            fi
        done

        # Check for UI output without stderr redirect
        if [[ "$in_programmatic_func" == true ]]; then
            # Check for closing brace (end of function)
            if echo "$line" | grep -qE "^}"; then
                in_programmatic_func=false
            fi

            # Check for echo without >&2
            if echo "$line" | grep -qE "echo.*[\"'].*[╔║✓❌⚠]" && ! echo "$line" | grep -q ">&2"; then
                warning "$file" "$line_num" "UI output in programmatic function '$func_name' should go to stderr"
                echo -e "    ${YELLOW}Suggestion:${NC} Add '>&2' to echo command"
                echo -e "    ${YELLOW}Line:${NC} $line"
            fi
        fi
    done < "$file"
}

# Rule 3: Check for unquoted variables in critical locations
lint_unquoted_variables() {
    local file="$1"
    local line_num=0

    while IFS= read -r line; do
        ((line_num++))

        # Check for unquoted variables in cd commands
        if echo "$line" | grep -qE "cd \\\$[a-zA-Z_]" && ! echo "$line" | grep -q 'cd "'; then
            warning "$file" "$line_num" "Potentially unquoted variable in cd command"
            echo -e "    ${YELLOW}Suggestion:${NC} Use 'cd \"\$var\"' instead of 'cd \$var'"
            echo -e "    ${YELLOW}Line:${NC} $line"
        fi

        # Check for unquoted variables in [ ] tests
        if echo "$line" | grep -qE "\[ \\\$[a-zA-Z_].*=" && ! echo "$line" | grep -q '"\$'; then
            warning "$file" "$line_num" "Potentially unquoted variable in test"
            echo -e "    ${YELLOW}Suggestion:${NC} Use '[ \"\$var\" = ... ]' instead of '[ \$var = ... ]'"
            echo -e "    ${YELLOW}Line:${NC} $line"
        fi
    done < "$file"
}

# Rule 4: Functions should use local for variables
lint_missing_local() {
    local file="$1"
    local line_num=0
    local in_function=false
    local func_name=""
    local indent_level=0

    while IFS= read -r line; do
        ((line_num++))

        # Detect function start
        if echo "$line" | grep -qE "^[a-zA-Z_][a-zA-Z0-9_-]*\(\)"; then
            in_function=true
            func_name=$(echo "$line" | sed -E "s/^([a-zA-Z_][a-zA-Z0-9_-]*)\(\).*/\1/")
            indent_level=0
        fi

        if [[ "$in_function" == true ]]; then
            # Track braces for nesting
            if echo "$line" | grep -q "{"; then
                ((indent_level++))
            fi
            if echo "$line" | grep -qE "^}"; then
                ((indent_level--))
                if [[ $indent_level -eq 0 ]]; then
                    in_function=false
                fi
            fi

            # Check for variable assignment without local/export/readonly
            # Skip: arrays, command substitutions, arithmetic
            if echo "$line" | grep -qE "^[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*=" && \
               ! echo "$line" | grep -qE "(local|export|readonly|declare)" && \
               ! echo "$line" | grep -qE "=\\\$\(" && \
               ! echo "$line" | grep -qE "=\(" && \
               ! echo "$line" | grep -qE "=\\\$\\\{" && \
               $indent_level -eq 1; then

                local var_name=$(echo "$line" | sed -E "s/^[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/")

                # Skip common global variables
                if [[ ! "$var_name" =~ ^(PATH|HOME|USER|SHELL|IFS)$ ]]; then
                    warning "$file" "$line_num" "Variable assignment without 'local' in function '$func_name'"
                    echo -e "    ${YELLOW}Suggestion:${NC} Use 'local $var_name=...' to avoid polluting global scope"
                    echo -e "    ${YELLOW}Line:${NC} $line"
                fi
            fi
        fi
    done < "$file"
}

# Rule 5: Check for alias/function name conflicts
lint_alias_function_conflicts() {
    local file="$1"

    # Extract aliases from this file
    local aliases=$(grep -E "^alias [a-zA-Z_]" "$file" 2>/dev/null | \
                   sed -E "s/^alias ([a-zA-Z_][a-zA-Z0-9_-]*)=.*/\1/" || true)

    # Extract functions from this file
    local functions=$(grep -E "^[a-zA-Z_][a-zA-Z0-9_-]*\(\)" "$file" 2>/dev/null | \
                     sed -E "s/^([a-zA-Z_][a-zA-Z0-9_-]*)\(\).*/\1/" || true)

    # Check for conflicts
    for alias_name in $aliases; do
        if echo "$functions" | grep -q "^${alias_name}$"; then
            local alias_line=$(grep -n "^alias ${alias_name}=" "$file" | cut -d: -f1)
            local func_line=$(grep -n "^${alias_name}()" "$file" | cut -d: -f1)

            error "$file" "$func_line" "Function '$alias_name' conflicts with alias at line $alias_line"
            echo -e "    ${RED}Suggestion:${NC} Remove the alias or rename the function"
        fi
    done
}

# ============================================================================
# Main Linter
# ============================================================================

lint_file() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        echo -e "${RED}Error: File not found: $file${NC}"
        return 1
    fi

    ((FILES_CHECKED++))

    echo -e "${BLUE}Checking:${NC} $file"

    # Run all lint rules
    lint_interactive_function_capture "$file"
    lint_stdout_pollution "$file"
    lint_unquoted_variables "$file"
    lint_missing_local "$file"
    lint_alias_function_conflicts "$file"
}

main() {
    print_header

    local target="${1:-}"

    if [[ -z "$target" ]]; then
        # Lint all ZSH files in functions directory
        echo -e "${BLUE}Linting all ZSH configuration files...${NC}"
        echo ""

        for file in ~/.config/zsh/functions/*.zsh; do
            if [[ -f "$file" ]]; then
                lint_file "$file"
            fi
        done

        # Also lint .zshrc
        if [[ -f ~/.config/zsh/.zshrc ]]; then
            lint_file ~/.config/zsh/.zshrc
        fi

    elif [[ -f "$target" ]]; then
        # Lint specific file
        lint_file "$target"
    else
        echo -e "${RED}Error: Invalid target: $target${NC}"
        echo "Usage: $0 [file.zsh]"
        return 1
    fi

    print_summary
}

# Run main
main "$@"
