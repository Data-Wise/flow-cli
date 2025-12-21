#!/bin/zsh
# deploy-smart-functions.sh
# Created: 2025-12-14
# Purpose: Deploy smart function refactoring

echo "🚀 Smart Functions Deployment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if smart functions file exists
SMART_FUNCS="$HOME/.config/zsh/functions/smart-dispatchers.zsh"
if [[ ! -f "$SMART_FUNCS" ]]; then
    echo "❌ Error: Smart functions file not found"
    echo "   Expected: $SMART_FUNCS"
    exit 1
fi

echo "✅ Smart functions file found"
echo "   Size: $(wc -l < "$SMART_FUNCS") lines"
echo ""

# Check if already sourced
ZSHRC="$HOME/.config/zsh/.zshrc"
if grep -q "smart-dispatchers.zsh" "$ZSHRC"; then
    echo "⚠️  Smart functions already sourced in .zshrc"
    echo "   Skipping source line addition"
else
    echo "📝 Adding source line to .zshrc..."
    
    # Create backup first
    cp "$ZSHRC" "$ZSHRC.backup-$(date +%Y%m%d-%H%M%S)"
    
    # Add source line
    cat >> "$ZSHRC" << 'EOF'

# Smart Function Dispatchers (ADHD-Optimized) - Added 2025-12-14
[[ -f ~/.config/zsh/functions/smart-dispatchers.zsh ]] && \
    source ~/.config/zsh/functions/smart-dispatchers.zsh
EOF
    
    echo "✅ Source line added"
fi

echo ""
echo "🔄 Reloading shell configuration..."
source "$ZSHRC"

echo ""
echo "🧪 Testing smart functions..."
echo ""

# Test each function
test_count=0
pass_count=0

for func in r qu cc gm focus note obs workflow; do
    ((test_count++))
    if typeset -f $func >/dev/null 2>&1; then
        echo "  ✅ $func() loaded"
        ((pass_count++))
    else
        echo "  ❌ $func() NOT loaded"
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Results: $pass_count/$test_count functions loaded"
echo ""

if [[ $pass_count -eq $test_count ]]; then
    echo "✅ All smart functions deployed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "   1. Test help systems: r help, cc help, etc."
    echo "   2. Run: ./remove-obsolete-aliases.sh"
    echo "   3. Verify: alias | wc -l (should be ~112)"
else
    echo "❌ Some functions failed to load"
    echo "   Check for errors in smart-dispatchers.zsh"
    exit 1
fi
