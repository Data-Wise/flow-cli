#!/usr/bin/env zsh
# test-lint-integration.zsh - Integration test against real stat-545 files
# Run with: zsh tests/test-lint-integration.zsh

SCRIPT_DIR="${0:A:h}"
STAT545_DIR="$HOME/projects/teaching/stat-545"

if [[ ! -d "$STAT545_DIR" ]]; then
    echo "SKIP: stat-545 not found at $STAT545_DIR"
    exit 0
fi

# Source the validator
source "${SCRIPT_DIR}/../.teach/validators/lint-shared.zsh"

echo "=== Integration test: lint-shared.zsh on stat-545 ==="

# Run on a few real files
total_warnings=0
files_checked=0

for file in "$STAT545_DIR"/slides/week-02*.qmd "$STAT545_DIR"/lectures/week-02*.qmd; do
    [[ -f "$file" ]] || continue
    ((files_checked++))
    local output
    output=$(_validate "$file" 2>&1)
    if [[ -n "$output" ]]; then
        echo "  ${file##*/}:"
        echo "$output" | while IFS= read -r line; do
            echo "    ⚠ $line"
            ((total_warnings++))
        done
    else
        echo "  ${file##*/}: ✓"
    fi
done

echo ""
echo "Files checked: $files_checked"
echo "Warnings: $total_warnings"
echo "(Warnings are informational — this test always passes)"
