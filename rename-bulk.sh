#!/bin/bash
# Bulk rename script for zsh-configuration → flow-cli
# Generated: 2025-12-21

set -e  # Exit on error

PROJECT_ROOT="/Users/dt/projects/dev-tools/zsh-configuration"
cd "$PROJECT_ROOT"

echo "🔄 Starting bulk rename: zsh-configuration → flow-cli"
echo "Working directory: $PWD"
echo ""

# Backup counter
FILES_CHANGED=0

# Function to safely replace in file
replace_in_file() {
    local file="$1"
    local pattern="$2"
    local replacement="$3"

    # Skip if file doesn't exist or is in excluded directories
    if [[ ! -f "$file" ]] || \
       [[ "$file" == *"/node_modules/"* ]] || \
       [[ "$file" == *"/.git/"* ]] || \
       [[ "$file" == *"/site/"* ]]; then
        return
    fi

    # Check if file contains pattern
    if grep -q "$pattern" "$file" 2>/dev/null; then
        # Create backup
        cp "$file" "$file.bak"

        # Perform replacement (macOS compatible sed)
        sed -i '' "s|$pattern|$replacement|g" "$file"

        FILES_CHANGED=$((FILES_CHANGED + 1))
        echo "  ✓ Updated: $file"
    fi
}

echo "📝 Phase 1: Updating project name references..."
# Find all markdown and text files, excluding generated/vendor directories
find docs -type f \( -name "*.md" -o -name "*.txt" \) ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/site/*" | while read file; do
    replace_in_file "$file" "zsh-configuration" "flow-cli"
done

echo ""
echo "📝 Phase 2: Updating GitHub URLs..."
find docs -type f \( -name "*.md" -o -name "*.txt" \) ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/site/*" | while read file; do
    replace_in_file "$file" "Data-Wise/zsh-configuration" "Data-Wise/flow-cli"
    replace_in_file "$file" "data-wise/zsh-configuration" "data-wise/flow-cli"
    replace_in_file "$file" "Data-Wise\.github\.io/zsh-configuration" "Data-Wise.github.io/flow-cli"
    replace_in_file "$file" "data-wise\.github\.io/zsh-configuration" "data-wise.github.io/flow-cli"
done

echo ""
echo "📝 Phase 3: Updating root-level documentation files..."
find . -maxdepth 1 -type f \( -name "*.md" -o -name "*.txt" \) ! -name "rename-bulk.sh" ! -name "RENAME-PREVIEW-*" | while read file; do
    replace_in_file "$file" "zsh-configuration" "flow-cli"
    replace_in_file "$file" "Data-Wise/zsh-configuration" "Data-Wise/flow-cli"
    replace_in_file "$file" "data-wise/zsh-configuration" "data-wise/flow-cli"
    replace_in_file "$file" "github\.io/zsh-configuration" "github.io/flow-cli"
done

echo ""
echo "📝 Phase 4: Updating ZSH function files..."
if [ -d "zsh/functions" ]; then
    find zsh/functions -type f -name "*.zsh" | while read file; do
        replace_in_file "$file" "zsh-configuration" "flow-cli"
    done
fi

echo ""
echo "📝 Phase 5: Updating test files..."
if [ -d "tests" ]; then
    find tests -type f \( -name "*.zsh" -o -name "*.sh" \) | while read file; do
        replace_in_file "$file" "zsh-configuration" "flow-cli"
    done
fi

echo ""
echo "📝 Phase 6: Updating standards files..."
if [ -d "standards" ]; then
    find standards -type f -name "*.md" | while read file; do
        replace_in_file "$file" "zsh-configuration" "flow-cli"
        replace_in_file "$file" "Data-Wise/zsh-configuration" "Data-Wise/flow-cli"
    done
fi

echo ""
echo "📝 Phase 7: Updating CLI code files..."
if [ -d "cli" ]; then
    find cli -type f \( -name "*.js" -o -name "*.md" \) ! -path "*/node_modules/*" | while read file; do
        replace_in_file "$file" "zsh-configuration" "flow-cli"
    done
fi

echo ""
echo "✨ Bulk rename complete!"
echo "📊 Files changed: $FILES_CHANGED"
echo ""
echo "🧹 Cleaning up backup files..."
find . -type f -name "*.bak" -delete
echo "✓ Backup files removed"
echo ""
echo "Next steps:"
echo "  1. Review changes with: git diff"
echo "  2. Test build: npm install && npm test"
echo "  3. Rebuild docs: mkdocs build"
echo "  4. Commit changes if all looks good"
