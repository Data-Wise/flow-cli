#!/usr/bin/env zsh
# Test script for pick command formatting

echo "Testing pick command formatting..."
echo ""

# Simulate formatted output
_test_format() {
    local name icon type changes branch status_display

    # Test case 1: Clean repo
    name="zsh-configuration"
    icon="🔧"
    type="dev"
    changes="0"
    branch="main"

    if [[ "$changes" =~ ^[0-9]+$ ]] && [[ "$changes" -gt 0 ]]; then
        status_display=$(printf '\033[33m⚠️ %-3s\033[0m' "($changes)")
    else
        status_display=$(printf '\033[32m✅     \033[0m')
    fi

    printf "%-20s %s %-5s %s [%s]\n" "$name" "$icon" "$type" "$status_display" "$branch"

    # Test case 2: Dirty repo with changes
    name="mediationverse"
    icon="📦"
    type="r"
    changes="3"
    branch="main"

    if [[ "$changes" =~ ^[0-9]+$ ]] && [[ "$changes" -gt 0 ]]; then
        status_display=$(printf '\033[33m⚠️ %-3s\033[0m' "($changes)")
    else
        status_display=$(printf '\033[32m✅     \033[0m')
    fi

    printf "%-20s %s %-5s %s [%s]\n" "$name" "$icon" "$type" "$status_display" "$branch"

    # Test case 3: Clean repo with long branch
    name="medrobust"
    icon="📦"
    type="r"
    changes="0"
    branch="claude/check-meas..."

    if [[ "$changes" =~ ^[0-9]+$ ]] && [[ "$changes" -gt 0 ]]; then
        status_display=$(printf '\033[33m⚠️ %-3s\033[0m' "($changes)")
    else
        status_display=$(printf '\033[32m✅     \033[0m')
    fi

    printf "%-20s %s %-5s %s [%s]\n" "$name" "$icon" "$type" "$status_display" "$branch"

    # Test case 4: Dirty repo with long branch
    name="causal-inference"
    icon="📚"
    type="teach"
    changes="12"
    branch="feature/new-lesson..."

    if [[ "$changes" =~ ^[0-9]+$ ]] && [[ "$changes" -gt 0 ]]; then
        status_display=$(printf '\033[33m⚠️ %-3s\033[0m' "($changes)")
    else
        status_display=$(printf '\033[32m✅     \033[0m')
    fi

    printf "%-20s %s %-5s %s [%s]\n" "$name" "$icon" "$type" "$status_display" "$branch"
}

echo "Expected output (with colors):"
echo "────────────────────────────────────────────────────────────────"
_test_format
echo "────────────────────────────────────────────────────────────────"
echo ""
echo "Key:"
echo "  ✅ (green)  = Clean repo (no changes)"
echo "  ⚠️  (yellow) = Dirty repo (with change count)"
echo ""
echo "To test with fzf:"
echo "  source ~/.config/zsh/functions/adhd-helpers.zsh"
echo "  pick r    # Test with R packages"
echo "  pick dev  # Test with dev tools"
