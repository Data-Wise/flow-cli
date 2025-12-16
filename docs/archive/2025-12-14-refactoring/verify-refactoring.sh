#!/bin/zsh
# verify-refactoring.sh
# Created: 2025-12-14
# Purpose: Verify smart function refactoring deployment

echo "🔍 Smart Functions Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

total_tests=0
passed_tests=0

# Test 1: Smart functions exist
echo "1️⃣ Smart functions exist..."
((total_tests++))
if [[ -f ~/.config/zsh/functions/smart-dispatchers.zsh ]]; then
    echo "   ✅ smart-dispatchers.zsh found"
    ((passed_tests++))
else
    echo "   ❌ smart-dispatchers.zsh NOT found"
fi

# Test 2: Functions loaded
echo ""
echo "2️⃣ Functions loaded in current shell..."
((total_tests++))
func_count=0
for func in r qu cc gm focus note obs workflow; do
    if typeset -f $func >/dev/null 2>&1; then
        ((func_count++))
    fi
done

if [[ $func_count -eq 8 ]]; then
    echo "   ✅ All 8 functions loaded ($func_count/8)"
    ((passed_tests++))
else
    echo "   ❌ Only $func_count/8 functions loaded"
fi

# Test 3: Help systems work
echo ""
echo "3️⃣ Help systems accessible..."
((total_tests++))
if r help >/dev/null 2>&1; then
    echo "   ✅ Help systems working (tested r help)"
    ((passed_tests++))
else
    echo "   ❌ Help systems not working"
fi

# Test 4: Alias count reduced
echo ""
echo "4️⃣ Alias count..."
((total_tests++))
alias_count=$(alias | wc -l | xargs)
if [[ $alias_count -le 120 && $alias_count -ge 100 ]]; then
    echo "   ✅ Alias count in range: $alias_count (target: 112)"
    ((passed_tests++))
else
    echo "   ⚠️  Alias count: $alias_count (expected ~112)"
    if [[ $alias_count -gt 150 ]]; then
        echo "      Hint: Run remove-obsolete-aliases.sh"
    fi
fi

# Test 5: Obsolete aliases removed
echo ""
echo "5️⃣ Obsolete aliases removed..."
((total_tests++))
removed_count=0
for a in ld ts dc ck bd ccc ccr gmy gms; do
    if ! alias $a 2>/dev/null; then
        ((removed_count++))
    fi
done

if [[ $removed_count -ge 7 ]]; then
    echo "   ✅ Obsolete aliases removed ($removed_count/9 checked)"
    ((passed_tests++))
else
    echo "   ❌ Only $removed_count/9 test aliases removed"
    echo "      Hint: Run remove-obsolete-aliases.sh"
fi

# Test 6: Preserved shortcuts still work
echo ""
echo "6️⃣ Preserved shortcuts..."
((total_tests++))
kept_count=0
for a in f15 f25 qp qr gs ns od wl; do
    if alias $a 2>/dev/null; then
        ((kept_count++))
    fi
done

if [[ $kept_count -eq 8 ]]; then
    echo "   ✅ Essential shortcuts preserved ($kept_count/8)"
    ((passed_tests++))
else
    echo "   ❌ Only $kept_count/8 shortcuts found"
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Results: $passed_tests/$total_tests checks passed"
echo ""

if [[ $passed_tests -eq $total_tests ]]; then
    echo "✅ VERIFICATION COMPLETE"
    echo ""
    echo "🎉 Smart function refactoring successfully deployed!"
    echo ""
    echo "📊 Statistics:"
    echo "   • Smart functions: 8"
    echo "   • Help systems: 8"
    echo "   • Total aliases: $alias_count"
    echo "   • Reduction: $(( 167 - alias_count )) aliases removed"
    echo ""
    echo "🎓 Try it:"
    echo "   r help      # R package development"
    echo "   cc help     # Claude Code"
    echo "   focus help  # Focus timer"
elif [[ $passed_tests -ge $(( total_tests - 1 )) ]]; then
    echo "⚠️  MOSTLY COMPLETE (minor issues)"
    echo ""
    echo "Review output above for details"
else
    echo "❌ VERIFICATION FAILED"
    echo ""
    echo "Issues detected - review output above"
    echo ""
    echo "🔄 Rollback if needed:"
    echo "   cp ~/.config/zsh/.zshrc.backup-* ~/.config/zsh/.zshrc"
    echo "   source ~/.zshrc"
fi
