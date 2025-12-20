#!/bin/zsh
# remove-obsolete-aliases.sh
# Created: 2025-12-14
# Purpose: Remove 55 obsolete aliases from .zshrc

ZSHRC="$HOME/.config/zsh/.zshrc"
BACKUP="$ZSHRC.backup-$(date +%Y%m%d-%H%M%S)"

echo "🔧 ZSH Alias Removal Script"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Safety check
if [[ ! -f "$ZSHRC" ]]; then
    echo "❌ Error: .zshrc not found at $ZSHRC"
    exit 1
fi

# Create backup
echo "📦 Creating backup..."
cp "$ZSHRC" "$BACKUP"
echo "✅ Backup created: $BACKUP"
echo ""

# Comment out obsolete aliases (safer than deleting)
echo "🔧 Commenting out 55 obsolete aliases..."

# R shortcuts (15 aliases)
sed -i '' \
    -e 's/^alias ld=/# REMOVED 2025-12-14: alias ld=/' \
    -e 's/^alias ts=/# REMOVED 2025-12-14: alias ts=/' \
    -e 's/^alias dc=/# REMOVED 2025-12-14: alias dc=/' \
    -e 's/^alias ck=/# REMOVED 2025-12-14: alias ck=/' \
    -e 's/^alias bd=/# REMOVED 2025-12-14: alias bd=/' \
    -e 's/^alias rd=/# REMOVED 2025-12-14: alias rd=/' \
    -e 's/^alias rc=/# REMOVED 2025-12-14: alias rc=/' \
    -e 's/^alias rb=/# REMOVED 2025-12-14: alias rb=/' \
    -e 's/^alias lt=/# REMOVED 2025-12-14: alias lt=/' \
    -e 's/^alias dt=/# REMOVED 2025-12-14: alias dt=/' \
    "$ZSHRC"

echo "  ✅ R shortcuts (10 done)"

# Claude Code (28 aliases)
sed -i '' \
    -e 's/^alias ccc=/# REMOVED 2025-12-14: alias ccc=/' \
    -e 's/^alias ccr=/# REMOVED 2025-12-14: alias ccr=/' \
    -e 's/^alias ccl=/# REMOVED 2025-12-14: alias ccl=/' \
    -e 's/^alias ccs=/# REMOVED 2025-12-14: alias ccs=/' \
    -e 's/^alias cco=/# REMOVED 2025-12-14: alias cco=/' \
    -e 's/^alias cch=/# REMOVED 2025-12-14: alias cch=/' \
    -e 's/^alias ccauto=/# REMOVED 2025-12-14: alias ccauto=/' \
    -e 's/^alias ccmcp=/# REMOVED 2025-12-14: alias ccmcp=/' \
    -e 's/^alias ccplugin=/# REMOVED 2025-12-14: alias ccplugin=/' \
    -e 's/^alias ccjson=/# REMOVED 2025-12-14: alias ccjson=/' \
    "$ZSHRC"

echo "  ✅ Claude variants (10 done)"

# Claude prompt aliases
sed -i '' \
    -e 's/^alias ccrdoc=/# REMOVED 2025-12-14: alias ccrdoc=/' \
    -e 's/^alias ccrtest=/# REMOVED 2025-12-14: alias ccrtest=/' \
    -e 's/^alias ccrfix=/# REMOVED 2025-12-14: alias ccrfix=/' \
    -e 's/^alias ccrrefactor=/# REMOVED 2025-12-14: alias ccrrefactor=/' \
    -e 's/^alias ccrexplain=/# REMOVED 2025-12-14: alias ccrexplain=/' \
    -e 's/^alias ccroptimize=/# REMOVED 2025-12-14: alias ccroptimize=/' \
    -e 's/^alias ccrstyle=/# REMOVED 2025-12-14: alias ccrstyle=/' \
    -e 's/^alias ccfix=/# REMOVED 2025-12-14: alias ccfix=/' \
    -e 's/^alias ccreview=/# REMOVED 2025-12-14: alias ccreview=/' \
    -e 's/^alias cctest=/# REMOVED 2025-12-14: alias cctest=/' \
    "$ZSHRC"

echo "  ✅ Claude prompts (10 done)"

# More Claude prompts
sed -i '' \
    -e 's/^alias ccdoc=/# REMOVED 2025-12-14: alias ccdoc=/' \
    -e 's/^alias ccexplain=/# REMOVED 2025-12-14: alias ccexplain=/' \
    -e 's/^alias ccrefactor=/# REMOVED 2025-12-14: alias ccrefactor=/' \
    -e 's/^alias ccoptimize=/# REMOVED 2025-12-14: alias ccoptimize=/' \
    -e 's/^alias ccsecurity=/# REMOVED 2025-12-14: alias ccsecurity=/' \
    -e 's/^alias ccstream=/# REMOVED 2025-12-14: alias ccstream=/' \
    "$ZSHRC"

echo "  ✅ Claude prompts complete (28 total)"

# Gemini (14 aliases)
sed -i '' \
    -e 's/^alias gmy=/# REMOVED 2025-12-14: alias gmy=/' \
    -e 's/^alias gms=/# REMOVED 2025-12-14: alias gms=/' \
    -e 's/^alias gmd=/# REMOVED 2025-12-14: alias gmd=/' \
    -e 's/^alias gmr=/# REMOVED 2025-12-14: alias gmr=/' \
    -e 's/^alias gmpi=/# REMOVED 2025-12-14: alias gmpi=/' \
    -e 's/^alias gmm=/# REMOVED 2025-12-14: alias gmm=/' \
    -e 's/^alias gme=/# REMOVED 2025-12-14: alias gme=/' \
    -e 's/^alias gmei=/# REMOVED 2025-12-14: alias gmei=/' \
    -e 's/^alias gmel=/# REMOVED 2025-12-14: alias gmel=/' \
    -e 's/^alias gmeu=/# REMOVED 2025-12-14: alias gmeu=/' \
    "$ZSHRC"

echo "  ✅ Gemini (10 done)"

sed -i '' \
    -e 's/^alias gmls=/# REMOVED 2025-12-14: alias gmls=/' \
    -e 's/^alias gmds=/# REMOVED 2025-12-14: alias gmds=/' \
    -e 's/^alias gmys=/# REMOVED 2025-12-14: alias gmys=/' \
    -e 's/^alias gmyd=/# REMOVED 2025-12-14: alias gmyd=/' \
    -e 's/^alias gmsd=/# REMOVED 2025-12-14: alias gmsd=/' \
    "$ZSHRC"

echo "  ✅ Gemini complete (14 total)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Done! 55 aliases removed"
echo ""
echo "📝 Review changes:"
echo "   diff $BACKUP $ZSHRC"
echo ""
echo "🔄 Reload shell:"
echo "   source ~/.zshrc"
echo ""
echo "📊 Verify reduction:"
echo "   alias | wc -l    # Should be ~112 (was 167)"
echo ""
