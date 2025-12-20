#!/usr/bin/env bash

# Quick ZSH Linter - checks for common anti-patterns
# Usage: ./quick-lint.sh [file or directory]

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

check_file() {
    local file="$1"
    local issues=0

    echo "Checking: $file"

    # Check for $(pick) command substitution
    if grep -n '\$(pick)' "$file" >/dev/null 2>&1; then
        echo -e "${RED}ERROR:${NC} Found \$(pick) command substitution:"
        grep -n '\$(pick)' "$file"
        ((ERRORS++))
        ((issues++))
    fi

    # Check for $(pickr), $(pickdev), etc.
    if grep -nE '\$(pick[a-z]+)' "$file" >/dev/null 2>&1; then
        echo -e "${RED}ERROR:${NC} Found interactive picker command substitution:"
        grep -nE '\$(pick[a-z]+)' "$file"
        ((ERRORS++))
        ((issues++))
    fi

    # Check for alias/function conflicts in same file
    local aliases=$(grep -E "^alias [a-zA-Z_]" "$file" 2>/dev/null | sed -E "s/^alias ([a-zA-Z_][a-zA-Z0-9_-]*)=.*/\1/" || true)
    local functions=$(grep -E "^[a-zA-Z_][a-zA-Z0-9_-]*\(\)" "$file" 2>/dev/null | sed -E "s/^([a-zA-Z_][a-zA-Z0-9_-]*)\(\).*/\1/" || true)

    for alias_name in $aliases; do
        if echo "$functions" | grep -q "^${alias_name}$"; then
            echo -e "${RED}ERROR:${NC} Alias/function conflict in $file: $alias_name"
            ((ERRORS++))
            ((issues++))
        fi
    done

    if [[ $issues -eq 0 ]]; then
        echo -e "  ${GREEN}✓${NC} No issues"
    fi
    echo ""
}

main() {
    local target="${1:-~/.config/zsh/functions}"

    echo ""
    echo "================================"
    echo "  ZSH Quick Lint"
    echo "================================"
    echo ""

    if [[ -f "$target" ]]; then
        check_file "$target"
    elif [[ -d "$target" ]]; then
        for file in "$target"/*.zsh; do
            if [[ -f "$file" ]]; then
                check_file "$file"
            fi
        done
    fi

    echo "================================"
    echo "Summary:"
    echo "  Errors: $ERRORS"
    echo "  Warnings: $WARNINGS"
    echo "================================"
    echo ""

    if [[ $ERRORS -gt 0 ]]; then
        echo -e "${RED}❌ Linting failed${NC}"
        exit 1
    else
        echo -e "${GREEN}✅ Linting passed${NC}"
        exit 0
    fi
}

main "$@"
