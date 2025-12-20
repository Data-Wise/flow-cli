#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# CLAUDE CODE WORKFLOWS - Enhanced AI-Assisted Development
# ══════════════════════════════════════════════════════════════════════════════
#
# File:         ~/.config/zsh/functions/claude-workflows.zsh
# Version:      1.0
# Date:         2025-12-13
# Part of:      Option B+ Multi-Editor Quadrant System
#
# Usage:        ccp, ccf, cci, ccft, ccpc, cccycle
# Help:         cchelp
#
# ══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════
# PROJECT-AWARE CLAUDE CODE
# ═══════════════════════════════════════════════════════════════════

# Start Claude Code with project context
cc-project() {
    local project="${1:-$(basename $PWD)}"
    
    # Gather context
    local context=""
    
    if [[ -f CLAUDE.md ]]; then
        context+="=== CLAUDE.md ===\n"
        context+="$(head -50 CLAUDE.md)\n\n"
    fi
    
    if [[ -f .STATUS ]]; then
        context+="=== Current Status ===\n"
        context+="$(cat .STATUS)\n\n"
    fi
    
    if [[ -f DESCRIPTION ]]; then
        context+="=== R Package ===\n"
        context+="Package: $(grep '^Package:' DESCRIPTION | cut -d' ' -f2)\n"
        context+="Version: $(grep '^Version:' DESCRIPTION | cut -d' ' -f2)\n\n"
    fi
    
    if [[ -n "$context" ]]; then
        echo "📋 Loading project context..."
        echo "$context" | claude -p "You're helping with project: $project. Context:" --continue
    else
        echo "💡 No CLAUDE.md or .STATUS found - starting fresh"
        claude
    fi
}

# ═══════════════════════════════════════════════════════════════════
# FILE-SPECIFIC HELP
# ═══════════════════════════════════════════════════════════════════

# Claude Code for specific file
cc-file() {
    local file="$1"
    
    if [[ -z "$file" ]]; then
        echo "Usage: ccf <file>"
        echo "Opens Claude Code with file in context"
        return 1
    fi
    
    if [[ -f "$file" ]]; then
        claude -p "Help me with this file: $file" --add "$file"
    else
        echo "❌ File not found: $file"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════
# IMPLEMENTATION HELPER
# ═══════════════════════════════════════════════════════════════════

# Claude Code to implement a feature
cc-implement() {
    # Help check FIRST (all three forms)
    if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
        cat <<'EOF'
Usage: cc-implement 'description of feature'
       cci 'description of feature'

Ask Claude Code to implement a feature with tidyverse standards.

ARGUMENTS:
  description    What feature to implement (required)

EXAMPLES:
  cc-implement 'add plot method for foo class'
  cc-implement 'create validation function for inputs'
  cc-implement 'refactor helper functions with better naming'

STANDARDS APPLIED:
  - Tidyverse style guide
  - Roxygen2 documentation
  - testthat tests
  - Native pipe |>
  - Concise and efficient code

SEE ALSO:
  cc-project        Load project context before implementing
  cc-fix-tests      Fix failing tests
  cc-cycle          Full development cycle (implement → test → fix)
  cc-pre-commit     Review changes before commit
EOF
        return 0
    fi

    local feature="$*"

    if [[ -z "$feature" ]]; then
        echo "cc-implement: missing required argument <description>" >&2
        echo "Run 'cc-implement help' for usage" >&2
        return 1
    fi

    local pkg_info=""
    if [[ -f DESCRIPTION ]]; then
        pkg_info="This is R package: $(grep '^Package:' DESCRIPTION | cut -d' ' -f2)"
    fi

    claude -p "Implement this feature: $feature

$pkg_info

Requirements:
- Follow tidyverse style guide
- Add roxygen2 documentation
- Create testthat tests
- Use native pipe |>
- Be concise and efficient"
}

# ═══════════════════════════════════════════════════════════════════
# TEST FIXING
# ═══════════════════════════════════════════════════════════════════

# Claude Code to fix failing tests
cc-fix-tests() {
    # Help check FIRST (all three forms)
    if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
        cat <<'EOF'
Usage: cc-fix-tests

Run R package tests and ask Claude to fix failures.

EXAMPLES:
  cc-fix-tests                 # Run tests, ask Claude to fix if failing

WORKFLOW:
  1. Runs devtools::test()
  2. If tests fail, sends output to Claude
  3. Claude suggests specific fixes

See also: cc-implement, cc-cycle
EOF
        return 0
    fi

    echo "🧪 Running tests..."

    # Run tests and capture output
    local test_output=$(Rscript -e "devtools::test()" 2>&1)
    local exit_code=$?

    if echo "$test_output" | grep -qE "(FAIL|Error)"; then
        echo "❌ Tests failing - asking Claude for help..."
        echo ""
        echo "$test_output" | tail -50 | claude -p "These R package tests are failing. Help me fix them. Be specific about which test and what change to make:"
    elif [[ $exit_code -ne 0 ]]; then
        echo "❌ Test run had errors:"
        echo "$test_output" | tail -20
        echo ""
        echo "$test_output" | claude -p "This R test run had errors. Help me fix:"
    else
        echo "✅ All tests passing!"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# CODE REVIEW
# ═══════════════════════════════════════════════════════════════════

# Claude Code review before commit
cc-pre-commit() {
    # Help check FIRST (all three forms)
    if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
        cat <<'EOF'
Usage: cc-pre-commit

Review staged/unstaged changes with Claude before committing.

EXAMPLES:
  cc-pre-commit                # Review current changes

REVIEW CHECKS:
  - Bugs or logic errors
  - R package best practices
  - Missing/incorrect documentation
  - Style issues (tidyverse)
  - Unhandled edge cases

OUTPUT FORMAT:
  🔴 ISSUES (must fix)
  🟡 SUGGESTIONS (nice to have)
  ✅ GOOD (what's done well)

See also: cc-cycle, cc-fix-tests
EOF
        return 0
    fi

    local diff=$(git diff --cached 2>/dev/null)

    if [[ -z "$diff" ]]; then
        diff=$(git diff 2>/dev/null)
    fi
    
    if [[ -z "$diff" ]]; then
        echo "⚠️  No changes to review"
        return 1
    fi
    
    echo "📝 Reviewing changes..."
    echo ""
    
    echo "$diff" | claude -p "Review this code before I commit. Check for:

1. Bugs or logic errors
2. R package best practices
3. Missing or incorrect documentation
4. Style issues (tidyverse conventions)
5. Edge cases not handled

Be concise. Format as:
🔴 ISSUES: (must fix)
🟡 SUGGESTIONS: (nice to have)
✅ GOOD: (what's done well)"
}

# ═══════════════════════════════════════════════════════════════════
# FULL DEVELOPMENT CYCLE
# ═══════════════════════════════════════════════════════════════════

# Agentic development cycle
cc-cycle() {
    # Help check FIRST (all three forms)
    if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
        cat <<'EOF'
Usage: cc-cycle 'description of task'

Full agentic development cycle: implement → load → test → fix.

ARGUMENTS:
  description    What to implement (required)

EXAMPLES:
  cc-cycle 'add summary method for foo class'
  cc-cycle 'fix edge case in validation'

WORKFLOW:
  1. Claude implements feature
  2. Load package (devtools::load_all)
  3. Run tests (devtools::test)
  4. If tests fail, Claude fixes them

See also: cc-implement, cc-fix-tests, cc-pre-commit
EOF
        return 0
    fi

    local task="$*"

    if [[ -z "$task" ]]; then
        echo "cc-cycle: missing required argument <description>" >&2
        echo "Run 'cc-cycle help' for usage" >&2
        return 1
    fi
    
    echo "┌─────────────────────────────────────────────────────────┐"
    echo "│           🤖 Claude Code Development Cycle              │"
    echo "└─────────────────────────────────────────────────────────┘"
    echo ""
    
    # 1. Let Claude implement
    echo "📝 Step 1: Claude implementing..."
    echo "   Task: $task"
    echo ""
    claude -p "$task" --dangerously-skip-permissions
    
    echo ""
    echo "📦 Step 2: Loading package..."
    Rscript -e "devtools::load_all()" 2>&1 | tail -5
    
    echo ""
    echo "🧪 Step 3: Running tests..."
    local test_result=$(Rscript -e "devtools::test()" 2>&1)
    
    if echo "$test_result" | grep -qE "(FAIL|Error)"; then
        echo "❌ Tests failing"
        echo ""
        echo "🔧 Step 4: Asking Claude to fix..."
        echo "$test_result" | tail -30 | claude -p "Tests failed after implementing. Fix these issues:"
    else
        echo "✅ Tests passing!"
        echo ""
        echo "🎉 Cycle complete!"
        # Celebration
        local celebrations=("Great job!" "Nailed it!" "Ship it!" "Progress!" "💪")
        echo "${celebrations[$RANDOM % ${#celebrations[@]}]}"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# EXPLANATION & LEARNING
# ═══════════════════════════════════════════════════════════════════

# Explain code in current file or selection
cc-explain() {
    # Help check FIRST (all three forms)
    if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
        cat <<'EOF'
Usage: cc-explain <file>
       cat file.R | cc-explain

Explain code clearly and concisely with Claude.

ARGUMENTS:
  file    Path to file to explain (optional if piping)

EXAMPLES:
  cc-explain R/utils.R         # Explain utils.R
  cat R/foo.R | cc-explain     # Explain piped code

EXPLAINS:
  - What the code does
  - Key parts and structure
  - Potential issues

ALIASES:
  cce              Shorthand for cc-explain

See also: cc-project, cc-file
EOF
        return 0
    fi

    local file="$1"

    if [[ -n "$file" && -f "$file" ]]; then
        cat "$file" | claude -p "Explain this code clearly and concisely. What does it do? What are the key parts? Any potential issues?"
    else
        # Check if there's piped input
        if [[ ! -t 0 ]]; then
            claude -p "Explain this code clearly and concisely:"
        else
            echo "cc-explain: missing required argument <file>" >&2
            echo "Run 'cc-explain help' for usage" >&2
            return 1
        fi
    fi
}

# ═══════════════════════════════════════════════════════════════════
# QUICK DOCUMENTATION
# ═══════════════════════════════════════════════════════════════════

# Generate roxygen docs for current file
cc-roxygen() {
    # Help check FIRST (all three forms)
    if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
        cat <<'EOF'
Usage: cc-roxygen [file.R]

Generate roxygen2 documentation for R functions.

ARGUMENTS:
  file    R file to document (optional - auto-finds undocumented)

EXAMPLES:
  cc-roxygen                   # Auto-find undocumented file
  cc-roxygen R/utils.R         # Document specific file

GENERATES:
  - @title
  - @description
  - @param (for each parameter)
  - @return
  - @export (if public)
  - @examples

See also: cc-implement, cc-cycle
EOF
        return 0
    fi

    local file="${1:-}"

    if [[ -z "$file" ]]; then
        # Try to find R files without docs
        file=$(grep -L "^#'" R/*.R 2>/dev/null | head -1)
        if [[ -z "$file" ]]; then
            echo "cc-roxygen: no undocumented R files found" >&2
            echo "Run 'cc-roxygen help' for usage" >&2
            return 1
        fi
        echo "📄 Found undocumented: $file"
    fi

    if [[ -f "$file" ]]; then
        cat "$file" | claude -p "Add roxygen2 documentation to all functions in this R file. Include:
- @title
- @description
- @param for each parameter
- @return
- @export (if public)
- @examples

Output the complete file with documentation added."
    else
        echo "cc-roxygen: file not found: $file" >&2
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════
# HELP
# ═══════════════════════════════════════════════════════════════════

cc-help() {
    cat << 'EOF'
┌─────────────────────────────────────────────────────────────────┐
│              CLAUDE CODE WORKFLOWS v1.0                         │
│            AI-Assisted R Development                            │
└─────────────────────────────────────────────────────────────────┘

PROJECT CONTEXT:
    ccp              Start Claude with project context
    ccp <name>       Start with specific project context

FILE HELP:
    ccf <file>       Open Claude with file in context
    cce <file>       Explain code in file

IMPLEMENTATION:
    cci "task"       Implement a feature with AI
    cccycle "task"   Full cycle: implement → test → fix

TESTING & REVIEW:
    ccft             Fix failing tests
    ccpc             Pre-commit review

DOCUMENTATION:
    ccrdoc <file>    Generate roxygen docs

EXISTING ALIASES (from zsh-claude-workflow):
    cc               Interactive Claude
    ccc              Continue conversation
    ccs/cco/cch      Sonnet/Opus/Haiku
    ccrdoc           R documentation
    ccrtest          R tests
    ccrfix           Fix R CMD check

TIPS:
    • ccp loads CLAUDE.md and .STATUS automatically
    • ccft runs tests and asks Claude to fix failures
    • cccycle is great for quick implementation tasks
    • ccpc catches issues before you commit
EOF
}

# ═══════════════════════════════════════════════════════════════════
# ALIASES
# ═══════════════════════════════════════════════════════════════════

# ccp is defined in .zshrc as 'claude -p' (print mode)
# Use ccproj for cc-project instead
alias ccproj='cc-project'
alias ccf='cc-file'
alias cci='cc-implement'
alias ccft='cc-fix-tests'
alias ccpc='cc-pre-commit'
alias cccycle='cc-cycle'
alias cce='cc-explain'
alias ccrdoc='cc-roxygen'
alias cchelp='cc-help'
