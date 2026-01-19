#!/usr/bin/env bash
# Generate Teaching Workflow v3.0 GIF demos
# Run from: docs/demos/tutorials/

set -e

echo "🎬 Generating Teaching Workflow v3.0 GIF Demos..."
echo ""

# Change to the tutorials directory
cd "$(dirname "$0")"

echo "📍 Working directory: $(pwd)"
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

# Generate each GIF
for tape in "${tapes[@]}"; do
    ((current++))
    echo "$current/$total Generating ${tape} demo..."
    echo "File: ${tape}.tape"

    if vhs "${tape}.tape"; then
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
    echo ""
done

echo "🎉 All GIFs generated successfully!"
echo ""
echo "Generated files:"
ls -lh tutorial-*.gif

echo ""
echo "Next steps:"
echo "  1. Preview GIFs in your browser"
echo "  2. Optimize if needed: gifsicle -O3 <file>.gif -o <file>.gif"
echo "  3. Commit to repository"
