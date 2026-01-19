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

# Generate teach doctor GIF
echo "1/2 Generating teach doctor demo..."
if vhs tutorial-teach-doctor.tape; then
    if [ -f "tutorial-teach-doctor.gif" ]; then
        size=$(du -h tutorial-teach-doctor.gif | awk '{print $1}')
        echo "  ✅ tutorial-teach-doctor.gif ($size)"
    else
        echo "  ❌ Failed to create tutorial-teach-doctor.gif"
        exit 1
    fi
else
    echo "  ❌ VHS failed for tutorial-teach-doctor.tape"
    exit 1
fi

echo ""

# Generate backup system GIF
echo "2/2 Generating backup system demo..."
if vhs tutorial-backup-system.tape; then
    if [ -f "tutorial-backup-system.gif" ]; then
        size=$(du -h tutorial-backup-system.gif | awk '{print $1}')
        echo "  ✅ tutorial-backup-system.gif ($size)"
    else
        echo "  ❌ Failed to create tutorial-backup-system.gif"
        exit 1
    fi
else
    echo "  ❌ VHS failed for tutorial-backup-system.tape"
    exit 1
fi

echo ""
echo "🎉 All GIFs generated successfully!"
echo ""
echo "Generated files:"
ls -lh tutorial-teach-doctor.gif tutorial-backup-system.gif

echo ""
echo "Next steps:"
echo "  1. Preview GIFs in your browser"
echo "  2. Optimize if needed: gifsicle -O3 <file>.gif -o <file>.gif"
echo "  3. Commit to repository"
