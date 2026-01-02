#!/bin/bash
# Skill Management Helper Functions
# Add to ~/.config/zsh/.zshrc or ~/.config/zsh/functions/skill-helpers.zsh

# ============================================================================
# SKILL MANAGEMENT FUNCTIONS
# ============================================================================

# Install a skill from Downloads or any path
skill-install() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: skill-install <path-to-skill.md>"
        echo "Example: skill-install ~/Downloads/my-skill.md"
        return 1
    fi
    
    local source="$1"
    local name="${source##*/}"
    local dest="$HOME/.claude/skills/$name"
    
    if [[ ! -f "$source" ]]; then
        echo "❌ Source file not found: $source"
        return 1
    fi
    
    cp "$source" "$dest"
    echo "✅ Installed: $name"
    echo "   Location: $dest"
}

# List all available skills
skill-list() {
    echo "📚 Available Skills:"
    echo ""
    echo "=== MCP Symlinks (Statistical) ==="
    find ~/.claude/skills -maxdepth 1 -type f ! -name "*.md" 2>/dev/null | \
        xargs -n1 basename | sort | nl -w2 -s'. '
    
    echo ""
    echo "=== Local Skills (.md files) ==="
    find ~/.claude/skills -maxdepth 1 -type f -name "*.md" 2>/dev/null | \
        xargs -n1 basename | sort | nl -w2 -s'. '
    
    echo ""
    echo "=== Anthropic Official (Subdirectories) ==="
    ls -d ~/.claude/skills/anthropic-official/skills/*/ 2>/dev/null | \
        xargs -n1 basename | sort | nl -w2 -s'. '
}

# List with categories (ADHD-friendly)
skill-ls() {
    local skills_dir="$HOME/.claude/skills"
    
    echo "📚 Claude Skills"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    echo "🔬 RESEARCH & WRITING:"
    echo "   research-writing-meta.md ⭐ (start here)"
    echo "   methods-paper-writer (MCP)"
    echo "   proof-architect (MCP)"
    echo "   simulation-architect (MCP)"
    echo ""
    
    echo "🎯 PROJECT & SPECS:"
    echo "   spec-interviewer.md ⭐"
    echo ""
    
    echo "📦 R DEVELOPMENT:"
    echo "   r-package-development.md"
    echo "   r-simulation-config.md"
    echo ""
    
    echo "📄 DOCUMENTS:"
    echo "   pdf/ (Anthropic)"
    echo "   docx/ (Anthropic)"
    echo "   xlsx/ (Anthropic)"
    echo "   pptx/ (Anthropic)"
    echo ""
    
    echo "🎓 TEACHING:"
    echo "   statistical-pedagogy-framework (MCP)"
    echo "   statistics-exam-generator.md"
    echo ""
    
    echo "💡 TIP: Full list → skill-list"
    echo "       Quick ref → cat ~/.claude/skills/SKILLS-QUICK-REFERENCE.md"
}

# View a skill
skill-view() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: skill-view <skill-name>"
        echo "Example: skill-view spec-interviewer"
        return 1
    fi
    
    local skill="$1"
    local file
    
    # Try with .md extension first
    if [[ -f "$HOME/.claude/skills/${skill}.md" ]]; then
        file="$HOME/.claude/skills/${skill}.md"
    # Try without extension (MCP symlinks)
    elif [[ -f "$HOME/.claude/skills/${skill}" ]]; then
        file="$HOME/.claude/skills/${skill}"
    # Try in anthropic-official
    elif [[ -d "$HOME/.claude/skills/anthropic-official/skills/${skill}" ]]; then
        file="$HOME/.claude/skills/anthropic-official/skills/${skill}/SKILL.md"
    else
        echo "❌ Skill not found: $skill"
        return 1
    fi
    
    # Use glow if available, otherwise cat
    if command -v glow &>/dev/null; then
        glow "$file"
    else
        cat "$file"
    fi
}

# Quick reference
skill-quick() {
    local quick_ref="$HOME/.claude/skills/SKILLS-QUICK-REFERENCE.md"
    
    if [[ -f "$quick_ref" ]]; then
        if command -v glow &>/dev/null; then
            glow "$quick_ref"
        else
            cat "$quick_ref"
        fi
    else
        echo "❌ Quick reference not found"
        echo "   Expected: $quick_ref"
    fi
}

# Search skills
skill-search() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: skill-search <keyword>"
        echo "Example: skill-search proof"
        return 1
    fi
    
    local query="$1"
    
    echo "🔍 Searching for: $query"
    echo ""
    
    # Search in skill names
    echo "📁 Skill names:"
    find ~/.claude/skills -type f -name "*.md" -o -type f ! -name ".*" | \
        grep -i "$query" | \
        xargs -n1 basename | \
        nl -w2 -s'. '
    
    echo ""
    
    # Search in skill content
    echo "📝 Skill content:"
    grep -r -i "$query" ~/.claude/skills/*.md 2>/dev/null | \
        head -5 | \
        sed 's/^/   /'
}

# Aliases for quick access
alias skills='skill-ls'
alias skl='skill-ls'
alias ski='skill-install'
alias skv='skill-view'
alias skq='skill-quick'
alias sks='skill-search'

# ============================================================================
# USAGE EXAMPLES
# ============================================================================
#
# skill-ls                          # List skills by category
# skill-list                        # Full list (all files)
# skill-install ~/Downloads/x.md    # Install new skill
# skill-view spec-interviewer       # View a skill
# skill-quick                       # View quick reference
# skill-search proof                # Search for "proof"
#
# Short aliases:
# skills     → skill-ls
# ski        → skill-install
# skv        → skill-view
# skq        → skill-quick
# sks        → skill-search
