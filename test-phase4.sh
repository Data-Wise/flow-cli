#!/usr/bin/env zsh
# Test Phase 4: Dashboard Integration

echo "Testing Phase 4: Dashboard Integration"
echo "========================================"
echo ""

# Load the plugin
source flow.plugin.zsh

echo "1. Testing _dot_has_chezmoi()..."
if _dot_has_chezmoi; then
  echo "   ✓ chezmoi is available"
else
  echo "   ⚠ chezmoi not available (status line will be skipped in dashboard)"
fi
echo ""

echo "2. Testing _dot_get_status_line()..."
status_line=$(_dot_get_status_line 2>&1)
if [[ $? -eq 0 ]] && [[ -n "$status_line" ]]; then
  echo "   ✓ Status line generated:"
  echo "$status_line"
else
  echo "   ⚠ No status line (chezmoi might not be initialized or not available)"
fi
echo ""

echo "3. Testing _dash_dotfiles() function..."
if typeset -f _dash_dotfiles >/dev/null 2>&1; then
  echo "   ✓ _dash_dotfiles() function exists"
  echo "   Running function:"
  _dash_dotfiles
else
  echo "   ✗ _dash_dotfiles() function not found!"
fi
echo ""

echo "4. Checking dash() call order..."
# Extract function call lines from dash()
calls=$(sed -n '/^dash()/,/^}/p' commands/dash.zsh | grep '^\s*_dash_' | tr -d ' ')
echo "   Function call order:"
echo "$calls" | nl -w2 -s'. '
echo ""

# Verify order
if echo "$calls" | grep -A1 '_dash_current' | grep -q '_dash_dotfiles'; then
  echo "   ✓ _dash_dotfiles is called after _dash_current"
else
  echo "   ✗ _dash_dotfiles is NOT in the correct position"
fi
echo ""

echo "5. Quick dashboard smoke test..."
echo "   Running: dash 2>&1 | head -30"
dash 2>&1 | head -30
echo ""

echo "Phase 4 testing complete!"
echo ""
echo "To test full dashboard: dash"
echo "To check dotfile status manually: dot status"
