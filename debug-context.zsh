#!/usr/bin/env zsh
# Debug script to test context-aware help

echo "=== Context Detection Debug ==="
echo ""

# Test in medfit
echo "Testing in: ~/projects/r-packages/active/medfit"
cd ~/projects/r-packages/active/medfit

echo "DESCRIPTION file exists: $([ -f DESCRIPTION ] && echo "YES" || echo "NO")"
if [ -f DESCRIPTION ]; then
    echo "Package field: $(grep "^Package:" DESCRIPTION)"
fi
echo ""

echo "Detected context: $(_flow_detect_context)"
echo ""

echo "=== Running 'flow help' ==="
flow help 2>&1 | head -30
