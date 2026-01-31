#!/usr/bin/env bash
# Generate Teaching Workflow v3.0 GIF demos
# Enhanced with validation and optimization (v5.23.0+)
# Run from: docs/demos/tutorials/

set -e

echo "🎬 Generating Teaching Workflow v3.0 GIF Demos (Enhanced)"
echo ""

# Change to the tutorials directory
cd "$(dirname "$0")"

echo "📍 Working directory: $(pwd)"
echo ""

# Step 1: Validate VHS tapes
echo "Step 1: Validating VHS tapes..."
if [ -x "../../../scripts/validate-vhs-tapes.sh" ]; then
    if ../../../scripts/validate-vhs-tapes.sh tutorial-*.tape; then
        echo "✅ All tapes passed validation"
    else
        echo "❌ Validation failed. Fix issues before generating."
        exit 1
    fi
else
    echo "⚠️  Validation script not found, skipping..."
fi
echo ""

# Array of VHS tapes to generate
tapes=(
    "tutorial-teach-doctor"
    "tutorial-backup-system"
    "tutorial-teach-init"
    "tutorial-teach-deploy"
    "tutorial-teach-status"
    "tutorial-scholar-integration"
)

total=${#tapes[@]}
current=0
total_before=0
total_after=0

# Step 2: Generate GIFs
echo "Step 2: Generating GIFs..."
for tape in "${tapes[@]}"; do
    ((current++))
    echo "$current/$total Generating ${tape} demo..."
    echo "  File: ${tape}.tape"

    if vhs "${tape}.tape" >/dev/null 2>&1; then
        if [ -f "${tape}.gif" ]; then
            size=$(du -h "${tape}.gif" | awk '{print $1}')
            echo "  ✅ ${tape}.gif ($size)"
        else
            echo "  ❌ Failed to create ${tape}.gif"
            exit 1
        fi
    else
        echo "  ❌ VHS failed for ${tape}.tape"
        exit 1
    fi
done
echo ""

# Step 3: Optimize GIFs
echo "Step 3: Optimizing GIFs with gifsicle..."
if command -v gifsicle >/dev/null 2>&1; then
    for tape in "${tapes[@]}"; do
        gif="${tape}.gif"
        if [ -f "$gif" ]; then
            before=$(stat -f%z "$gif" 2>/dev/null || stat -c%s "$gif")
            total_before=$((total_before + before))

            gifsicle -O3 "$gif" -o "${gif}.tmp" 2>/dev/null && mv "${gif}.tmp" "$gif"

            after=$(stat -f%z "$gif" 2>/dev/null || stat -c%s "$gif")
            total_after=$((total_after + after))
            reduction=$(( (before - after) * 100 / before ))

            echo "  $(basename $gif): $before → $after bytes ($reduction% reduction)"
        fi
    done

    overall_reduction=$(( (total_before - total_after) * 100 / total_before ))
    echo ""
    echo "  Total: $total_before → $total_after bytes ($overall_reduction% reduction)"
else
    echo "⚠️  gifsicle not found. Install with: brew install gifsicle"
fi
echo ""

# Summary
echo "🎉 All GIFs generated and optimized successfully!"
echo ""
echo "Generated files:"
ls -lh tutorial-*.gif

echo ""
echo "Next steps:"
echo "  1. Preview GIFs in your browser"
echo "  2. Commit to repository: git add *.gif && git commit -m 'feat(gifs): ...'"
