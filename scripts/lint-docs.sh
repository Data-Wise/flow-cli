#!/usr/bin/env bash
# Lint all markdown documentation
# Usage: ./scripts/lint-docs.sh [--fix]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if markdownlint-cli2 is installed
if ! command -v markdownlint-cli2 &> /dev/null; then
    echo -e "${YELLOW}markdownlint-cli2 not found. Installing...${NC}"
    npm install -g markdownlint-cli2
fi

# Parse arguments
FIX_MODE=false
if [[ "${1:-}" == "--fix" ]]; then
    FIX_MODE=true
fi

cd "$PROJECT_ROOT"

echo -e "${BLUE}=== Markdown Linting ===${NC}"
echo "Project: $PROJECT_ROOT"
echo "Config: .markdownlint.yaml"
echo ""

# Find all markdown files
MARKDOWN_FILES=$(find docs -name "*.md" -type f | sort)
FILE_COUNT=$(echo "$MARKDOWN_FILES" | wc -l | tr -d ' ')

echo -e "${BLUE}Found $FILE_COUNT markdown files to lint${NC}"
echo ""

# Lint or fix based on mode
if $FIX_MODE; then
    echo -e "${YELLOW}Running in FIX mode - will auto-fix issues${NC}"
    echo ""

    # markdownlint-cli2 with --fix flag
    if markdownlint-cli2 --fix "docs/**/*.md" 2>&1; then
        echo ""
        echo -e "${GREEN}✓ Auto-fix completed${NC}"
        echo -e "${YELLOW}Please review changes with: git diff${NC}"
    else
        echo ""
        echo -e "${YELLOW}⚠ Some issues were fixed, but others remain${NC}"
        echo -e "${BLUE}Run without --fix to see remaining issues${NC}"
    fi
else
    echo -e "${BLUE}Running in CHECK mode - will report issues${NC}"
    echo ""

    # Lint all files
    if markdownlint-cli2 "docs/**/*.md"; then
        echo ""
        echo -e "${GREEN}✓ All markdown files passed linting!${NC}"
        exit 0
    else
        echo ""
        echo -e "${RED}✗ Markdown linting failed${NC}"
        echo -e "${YELLOW}Run with --fix to auto-fix issues: ./scripts/lint-docs.sh --fix${NC}"
        exit 1
    fi
fi
