#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# TEST-DUPLICATES - Check for duplicate alias/function definitions
# ══════════════════════════════════════════════════════════════════════════════
#
# Usage: ./test-duplicates.zsh
#
# Checks:
#   1. Duplicate alias names across all .zsh files
#   2. Duplicate function names across all .zsh files
#   3. Alias/function name conflicts
#
# ══════════════════════════════════════════════════════════════════════════════

# Colors
_RED='\033[31m'
_GREEN='\033[32m'
_YELLOW='\033[33m'
_NC='\033[0m'
_BOLD='\033[1m'

# Counters
PASS=0
FAIL=0
WARN=0

# Get list of actual .zsh files (exclude backups and p10k config)
ZSH_FILES=(
    ~/.config/zsh/.zshrc
    ~/.config/zsh/functions.zsh
)
# Add function files
for f in ~/.config/zsh/functions/*.zsh; do
    # Skip backup files
    [[ "$f" == *.bak* ]] && continue
    [[ "$f" == *.backup* ]] && continue
    [[ "$f" == *.tmp* ]] && continue
    [[ "$f" == *.broken* ]] && continue
    [[ -f "$f" ]] && ZSH_FILES+=("$f")
done

echo -e "${_BOLD}═══════════════════════════════════════════════════════════${_NC}"
echo -e "${_BOLD}  Duplicate Definition Check${_NC}"
echo -e "${_BOLD}═══════════════════════════════════════════════════════════${_NC}"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Test 1: Duplicate Aliases
# ─────────────────────────────────────────────────────────────────────────────

echo -e "${_BOLD}[1/3] Checking for duplicate aliases...${_NC}"

# Find all alias definitions and check for duplicates
duplicates=()
while IFS= read -r dup; do
    [[ -n "$dup" ]] && duplicates+=("$dup")
done < <(cat "${ZSH_FILES[@]}" 2>/dev/null | \
    grep "^alias [a-zA-Z_][a-zA-Z0-9_]*=" | \
    sed "s/alias \([^=]*\)=.*/\1/" | \
    sort | uniq -d)

if [[ ${#duplicates[@]} -eq 0 ]]; then
    echo -e "  ${_GREEN}✓${_NC} No duplicate aliases found"
    ((PASS++))
else
    echo -e "  ${_RED}✗${_NC} Duplicate aliases found:"
    for dup in "${duplicates[@]}"; do
        echo -e "    ${_RED}$dup${_NC} defined in:"
        for f in "${ZSH_FILES[@]}"; do
            result=$(grep -n "^alias $dup=" "$f" 2>/dev/null)
            [[ -n "$result" ]] && echo "      ${f}:${result}"
        done
    done
    ((FAIL++))
fi

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Test 2: Duplicate Functions
# ─────────────────────────────────────────────────────────────────────────────

echo -e "${_BOLD}[2/3] Checking for duplicate functions...${_NC}"

# Find all function definitions
func_duplicates=()
while IFS= read -r dup; do
    [[ -n "$dup" ]] && func_duplicates+=("$dup")
done < <(cat "${ZSH_FILES[@]}" 2>/dev/null | \
    grep -E "^[a-zA-Z_][a-zA-Z0-9_-]*\(\)|^function [a-zA-Z_][a-zA-Z0-9_-]+" | \
    sed -E 's/^function ([^ ]+).*/\1/; s/\(\).*//' | \
    sort | uniq -d)

if [[ ${#func_duplicates[@]} -eq 0 ]]; then
    echo -e "  ${_GREEN}✓${_NC} No duplicate functions found"
    ((PASS++))
else
    echo -e "  ${_RED}✗${_NC} Duplicate functions found:"
    for dup in "${func_duplicates[@]}"; do
        echo -e "    ${_RED}$dup${_NC} defined in:"
        for f in "${ZSH_FILES[@]}"; do
            result=$(grep -nE "^$dup\(\)|^function $dup" "$f" 2>/dev/null)
            [[ -n "$result" ]] && echo "      ${f}:${result}"
        done
    done
    ((FAIL++))
fi

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Test 3: Alias/Function Conflicts
# ─────────────────────────────────────────────────────────────────────────────

echo -e "${_BOLD}[3/3] Checking for alias/function name conflicts...${_NC}"

# Get all alias names
alias_names=()
while IFS= read -r name; do
    [[ -n "$name" ]] && alias_names+=("$name")
done < <(cat "${ZSH_FILES[@]}" 2>/dev/null | \
    grep "^alias [a-zA-Z_][a-zA-Z0-9_]*=" | \
    sed "s/alias \([^=]*\)=.*/\1/" | sort -u)

# Get all function names
func_names=()
while IFS= read -r name; do
    [[ -n "$name" ]] && func_names+=("$name")
done < <(cat "${ZSH_FILES[@]}" 2>/dev/null | \
    grep -E "^[a-zA-Z_][a-zA-Z0-9_-]*\(\)|^function [a-zA-Z_][a-zA-Z0-9_-]+" | \
    sed -E 's/^function ([^ ]+).*/\1/; s/\(\).*//' | sort -u)

# Find conflicts (names that are both alias and function)
conflicts=()
for alias_name in "${alias_names[@]}"; do
    for func_name in "${func_names[@]}"; do
        if [[ "$alias_name" == "$func_name" ]]; then
            conflicts+=("$alias_name")
            break
        fi
    done
done

if [[ ${#conflicts[@]} -eq 0 ]]; then
    echo -e "  ${_GREEN}✓${_NC} No alias/function conflicts"
    ((PASS++))
else
    echo -e "  ${_YELLOW}⚠${_NC} Potential conflicts (same name as alias and function):"
    for conflict in "${conflicts[@]}"; do
        echo -e "    ${_YELLOW}$conflict${_NC}"
    done
    ((WARN++))
fi

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────────

echo -e "${_BOLD}═══════════════════════════════════════════════════════════${_NC}"
echo -e "${_BOLD}  Summary${_NC}"
echo -e "${_BOLD}═══════════════════════════════════════════════════════════${_NC}"
echo ""
echo -e "  ${_GREEN}Passed:${_NC}   $PASS"
echo -e "  ${_RED}Failed:${_NC}   $FAIL"
echo -e "  ${_YELLOW}Warnings:${_NC} $WARN"
echo ""

if [[ $FAIL -gt 0 ]]; then
    echo -e "  ${_RED}${_BOLD}RESULT: FAIL${_NC}"
    exit 1
elif [[ $WARN -gt 0 ]]; then
    echo -e "  ${_YELLOW}${_BOLD}RESULT: PASS with warnings${_NC}"
    exit 0
else
    echo -e "  ${_GREEN}${_BOLD}RESULT: PASS${_NC}"
    exit 0
fi
