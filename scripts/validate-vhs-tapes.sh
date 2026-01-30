#!/usr/bin/env zsh

# Validate VHS tape files for quality standards
# Usage: ./scripts/validate-vhs-tapes.sh [tape-file...]
# Exit codes: 0 = all passed, 1 = failures found

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL=0
PASSED=0
FAILED=0

# Validate a single VHS tape file
validate_tape() {
    local tape="$1"
    local issues=()

    TOTAL=$((TOTAL + 1))

    # Check 1: Font size
    local fontsize=$(grep -o 'Set FontSize [0-9]*' "$tape" | awk '{print $3}')
    if [[ -z "$fontsize" ]]; then
        issues+=("Missing FontSize setting")
    elif [[ "$tape" == *"tutorial"* ]] && [[ $fontsize -lt 18 ]]; then
        issues+=("Font too small ($fontsize < 18px) for tutorial")
    elif [[ $fontsize -lt 16 ]]; then
        issues+=("Font too small ($fontsize < 16px)")
    fi

    # Check 2: Problematic syntax - Type "# ..."
    local bad_syntax=$(grep -c 'Type "# ' "$tape" 2>/dev/null || true)
    if [[ $bad_syntax -gt 0 ]]; then
        issues+=("Found $bad_syntax lines with problematic 'Type \"#\"' syntax")
    fi

    # Check 3: Shell setting
    if ! grep -q 'Set Shell' "$tape"; then
        issues+=("Missing 'Set Shell' directive")
    fi

    # Check 4: Output setting
    if ! grep -q '^Output ' "$tape"; then
        issues+=("Missing Output directive")
    fi

    # Check 5: Width and Height
    if ! grep -q 'Set Width' "$tape"; then
        issues+=("Missing Width setting")
    fi
    if ! grep -q 'Set Height' "$tape"; then
        issues+=("Missing Height setting")
    fi

    # Report results
    if [[ ${#issues[@]} -eq 0 ]]; then
        echo "${GREEN}✓${NC} $tape"
        PASSED=$((PASSED + 1))
    else
        echo "${RED}✗${NC} $tape"
        for issue in "${issues[@]}"; do
            echo "  ${YELLOW}⚠${NC} $issue"
        done
        FAILED=$((FAILED + 1))
    fi
}

# Main execution
main() {
    local tapes=()

    # Determine which tapes to validate
    if [[ $# -eq 0 ]]; then
        # Validate all tapes in docs/demos/
        if [[ ! -d "docs/demos" ]]; then
            echo "${RED}Error: docs/demos directory not found${NC}"
            echo "Run this script from the repository root"
            exit 1
        fi
        tapes=(docs/demos/**/*.tape(N))
        if [[ ${#tapes[@]} -eq 0 ]]; then
            echo "${YELLOW}No .tape files found in docs/demos/${NC}"
            exit 0
        fi
    else
        tapes=("$@")
    fi

    echo "${BLUE}Validating ${#tapes[@]} VHS tape files...${NC}"
    echo

    # Validate each tape
    for tape in "${tapes[@]}"; do
        if [[ ! -f "$tape" ]]; then
            echo "${RED}✗${NC} $tape - File not found"
            TOTAL=$((TOTAL + 1))
            FAILED=$((FAILED + 1))
            continue
        fi
        validate_tape "$tape"
    done

    # Summary
    echo
    echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "${BLUE}Results:${NC} $PASSED/$TOTAL passed, $FAILED/$TOTAL failed"

    if [[ $FAILED -gt 0 ]]; then
        echo "${RED}Validation failed${NC}"
        exit 1
    else
        echo "${GREEN}All tapes passed validation!${NC}"
        exit 0
    fi
}

# Run main function
main "$@"
