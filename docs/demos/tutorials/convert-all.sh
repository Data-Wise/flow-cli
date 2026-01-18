#!/bin/bash

# Scholar Enhancement GIF Batch Converter
# Converts all .cast files to optimized GIFs

set -e

cd "$(dirname "$0")"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🎬 Scholar Enhancement GIF Converter"
echo "======================================"
echo

# Check prerequisites
for cmd in agg gifsicle; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "❌ Error: $cmd not installed"
        echo "   Install with: brew install $cmd"
        exit 1
    fi
done

# Count .cast files
cast_count=$(ls -1 scholar-*.cast 2>/dev/null | wc -l | xargs)

if [ "$cast_count" -eq 0 ]; then
    echo "⚠️  No .cast files found"
    echo "   Record with: asciinema rec scholar-XX-name.cast"
    exit 0
fi

echo "Found $cast_count recording(s)"
echo

# Convert all .cast files
for cast in scholar-*.cast; do
    gif="${cast%.cast}.gif"

    echo -e "${BLUE}Converting${NC} $cast → $gif"

    # Convert with agg
    agg \
      --cols 100 \
      --rows 30 \
      --font-size 16 \
      --theme dracula \
      --fps-cap 10 \
      "$cast" "$gif" 2>/dev/null

    # Optimize with gifsicle
    gifsicle -O3 --colors 128 --lossy=80 \
      "$gif" -o "$gif" 2>/dev/null

    # Show result
    size=$(ls -lh "$gif" | awk '{print $5}')
    echo -e "${GREEN}✓${NC} Generated: $gif ($size)"
    echo
done

echo "======================================"
echo "✅ All GIFs generated successfully"
echo
echo "Total:"
ls -lh scholar-*.gif | awk '{print "  " $9 " - " $5}'
echo
echo "View: open scholar-01-help.gif"
