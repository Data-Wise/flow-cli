#!/usr/bin/env bash
# Validate dot dispatcher documentation
# Usage: ./scripts/validate-dot-docs.sh

set -e

echo "🔍 Validating Dot Dispatcher Documentation..."
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0

# Check required files exist
echo "📁 Checking files exist..."
FILES=(
  "docs/guides/DOTFILE-MANAGEMENT.md"
  "docs/reference/REFCARD-DOT.md"
  "docs/reference/DOT-DISPATCHER-REFERENCE.md"
  "docs/demos/dot-dispatcher.tape"
  "docs/SECRET-MANAGEMENT.md"
)

for file in "${FILES[@]}"; do
  if [[ -f "$file" ]]; then
    echo -e "${GREEN}✓${NC} $file"
  else
    echo -e "${RED}✗${NC} $file (missing)"
    ERRORS=$((ERRORS + 1))
  fi
done

echo ""

# Check mkdocs.yml entries
echo "📚 Checking mkdocs.yml navigation..."
ENTRIES=(
  "Dotfile Management: guides/DOTFILE-MANAGEMENT.md"
  "DOT Dispatcher: reference/DOT-DISPATCHER-REFERENCE.md"
  "DOT Quick Ref: reference/REFCARD-DOT.md"
)

for entry in "${ENTRIES[@]}"; do
  if grep -q "$entry" mkdocs.yml; then
    echo -e "${GREEN}✓${NC} $entry"
  else
    echo -e "${RED}✗${NC} $entry (missing from mkdocs.yml)"
    ERRORS=$((ERRORS + 1))
  fi
done

echo ""

# Check internal links
echo "🔗 Checking internal links..."
LINKS=(
  "docs/guides/DOTFILE-MANAGEMENT.md:DOT-DISPATCHER-REFERENCE.md"
  "docs/guides/DOTFILE-MANAGEMENT.md:SECRET-MANAGEMENT.md"
  "docs/reference/REFCARD-DOT.md:DOT-DISPATCHER-REFERENCE.md"
  "docs/reference/REFCARD-DOT.md:DOTFILE-MANAGEMENT.md"
  "docs/reference/REFCARD-DOT.md:SECRET-MANAGEMENT.md"
)

for link in "${LINKS[@]}"; do
  file="${link%%:*}"
  target="${link##*:}"
  if grep -q "$target" "$file"; then
    echo -e "${GREEN}✓${NC} $file links to $target"
  else
    echo -e "${RED}✗${NC} $file missing link to $target"
    ERRORS=$((ERRORS + 1))
  fi
done

echo ""

# Check README.md mentions dot
echo "📄 Checking README.md..."
if grep -q "dot.*dispatcher\|dot edit" README.md; then
  echo -e "${GREEN}✓${NC} README.md mentions dot dispatcher"
else
  echo -e "${RED}✗${NC} README.md missing dot dispatcher"
  ERRORS=$((ERRORS + 1))
fi

# Check CLAUDE.md mentions v5.0.0
if grep -q "v5.0.0.*Dot Dispatcher\|dot dispatcher" CLAUDE.md; then
  echo -e "${GREEN}✓${NC} CLAUDE.md mentions dot dispatcher"
else
  echo -e "${RED}✗${NC} CLAUDE.md missing dot dispatcher update"
  ERRORS=$((ERRORS + 1))
fi

# Check COMMAND-QUICK-REFERENCE.md
if grep -q "Dotfile Management: \`dot\`" docs/reference/COMMAND-QUICK-REFERENCE.md; then
  echo -e "${GREEN}✓${NC} COMMAND-QUICK-REFERENCE.md has dot section"
else
  echo -e "${RED}✗${NC} COMMAND-QUICK-REFERENCE.md missing dot section"
  ERRORS=$((ERRORS + 1))
fi

echo ""

# Check for broken markdown links
echo "🔍 Checking for broken markdown links..."
BROKEN_LINKS=$(find docs -name "*.md" -type f -exec grep -H '\[.*\](.*\.md)' {} \; | \
  grep -v "http" | \
  while IFS=: read -r file link; do
    # Extract relative path from markdown link
    path=$(echo "$link" | sed -n 's/.*(\([^)]*\.md\)).*/\1/p')
    if [[ -n "$path" ]]; then
      # Resolve relative path
      dir=$(dirname "$file")
      resolved=$(cd "$dir" && realpath -m "$path" 2>/dev/null || echo "")
      if [[ -n "$resolved" ]] && [[ ! -f "$resolved" ]]; then
        echo "$file: $path"
      fi
    fi
  done)

if [[ -z "$BROKEN_LINKS" ]]; then
  echo -e "${GREEN}✓${NC} No broken links found"
else
  echo -e "${YELLOW}⚠${NC}  Potential broken links:"
  echo "$BROKEN_LINKS"
fi

echo ""

# Summary
if [[ $ERRORS -eq 0 ]]; then
  echo -e "${GREEN}✅ All checks passed!${NC}"
  exit 0
else
  echo -e "${RED}❌ $ERRORS errors found${NC}"
  exit 1
fi
