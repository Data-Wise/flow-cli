#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════
# Convert .STATUS Files to dash-Compatible Format
# ══════════════════════════════════════════════════════════════════════════════
#
# This script adds key:value format headers to .STATUS files while preserving
# all existing content. It extracts values from various formats in the files.
#
# Usage: ./convert-status-files.sh [--dry-run]
#
# ══════════════════════════════════════════════════════════════════════════════

DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "🔍 DRY RUN MODE - No files will be modified"
    echo ""
fi

CONVERTED=0
SKIPPED=0
ERRORS=0

# Find all .STATUS files (excluding project-hub)
while IFS= read -r status_file; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📄 Processing: $status_file"

    # Check if file already has the correct format
    if grep -q "^status:" "$status_file" && \
       grep -q "^priority:" "$status_file" && \
       grep -q "^progress:" "$status_file"; then
        echo "   ✓ Already has correct format - skipping"
        ((SKIPPED++))
        continue
    fi

    # Extract project info
    project_dir=$(dirname "$status_file")
    project_name=$(basename "$project_dir")

    # Try to extract values from various formats in the file

    # Status (look for: "Status: active", "status: active", or "📋 Current status: active")
    status=$(grep -i "status:" "$status_file" | head -1 | sed 's/.*[Ss]tatus:[[:space:]]*//' | tr '[:upper:]' '[:lower:]' | tr -d '\r\n' | xargs)
    [[ -z "$status" ]] && status="active"  # Default to active

    # Priority (look for: "Priority: P1", "priority: P1")
    priority=$(grep -i "priority:" "$status_file" | head -1 | sed 's/.*[Pp]riority:[[:space:]]*//' | tr -d '\r\n' | xargs)
    [[ -z "$priority" ]] && priority="--"

    # Progress (look for: "Progress: 100", "progress: 100")
    progress=$(grep -i "progress:" "$status_file" | head -1 | sed 's/.*[Pp]rogress:[[:space:]]*//' | tr -d '\r\n' | xargs)
    [[ -z "$progress" ]] && progress="--"

    # Next action (look for: "Next:", "next:", "🎯 Next Action:")
    next=$(grep -i "next:" "$status_file" | head -1 | sed 's/.*[Nn]ext:[[:space:]]*//' | tr -d '\r\n')
    if [[ -z "$next" ]]; then
        # Try "Next Action:"
        next=$(grep -i "next action:" "$status_file" | head -1 | sed 's/.*[Nn]ext [Aa]ction:[[:space:]]*//' | tr -d '\r\n')
    fi
    [[ -z "$next" ]] && next="No next action defined"

    # Type (infer from project path)
    type="project"
    if [[ "$project_dir" == *"/r-packages/"* ]]; then
        type="r"
    elif [[ "$project_dir" == *"/teaching/"* ]]; then
        type="teaching"
    elif [[ "$project_dir" == *"/research/"* ]]; then
        type="research"
    elif [[ "$project_dir" == *"/dev-tools/"* ]]; then
        type="dev"
    elif [[ "$project_dir" == *"/quarto/"* ]]; then
        type="quarto"
    fi

    echo "   📋 Extracted values:"
    echo "      status: $status"
    echo "      priority: $priority"
    echo "      progress: $progress"
    echo "      next: $next"
    echo "      type: $type"

    if [[ "$DRY_RUN" == true ]]; then
        echo "   🔍 Would prepend key:value headers to file"
        ((CONVERTED++))
    else
        # Create backup
        cp "$status_file" "${status_file}.backup"

        # Create new file with headers + original content
        {
            echo "status: $status"
            echo "priority: $priority"
            echo "progress: $progress"
            echo "next: $next"
            echo "type: $type"
            echo ""
            echo "# ═══════════════════════════════════════════════════════════════════"
            echo "# Below is the original .STATUS content (preserved for reference)"
            echo "# ═══════════════════════════════════════════════════════════════════"
            echo ""
            cat "$status_file"
        } > "${status_file}.new"

        # Replace original with new file
        mv "${status_file}.new" "$status_file"

        echo "   ✅ Converted successfully (backup: ${status_file}.backup)"
        ((CONVERTED++))
    fi

done < <(find ~/projects -name ".STATUS" -type f 2>/dev/null | grep -v "/project-hub/")

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Summary:"
echo "   ✅ Converted: $CONVERTED"
echo "   ⏭️  Skipped:   $SKIPPED (already correct format)"
echo "   ❌ Errors:    $ERRORS"
echo ""

if [[ "$DRY_RUN" == true ]]; then
    echo "🔍 This was a dry run. Run without --dry-run to apply changes."
else
    echo "✅ Conversion complete!"
    echo ""
    echo "💡 Next steps:"
    echo "   1. Test: dash"
    echo "   2. If everything looks good, delete backups: rm ~/projects/**/.STATUS.backup"
    echo "   3. If something went wrong, restore: for f in ~/projects/**/.STATUS.backup; do mv \"\$f\" \"\${f%.backup}\"; done"
fi
