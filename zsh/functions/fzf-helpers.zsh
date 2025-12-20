# ============================================
# FZF HELPER FUNCTIONS
# ============================================
# Enhanced fzf integration for R development, git, and project management
# Created: 2025-12-16
# Requires: fzf, fd, bat, git

# Unalias conflicting OMZ git plugin aliases
# (Our functions provide enhanced versions with fzf)
unalias gb ga 2>/dev/null

# ============================================
# R PACKAGE HELPERS
# ============================================

# re - Fuzzy find and edit R package files
# Usage: re [pattern]
re() {
    if [ ! -d "R" ] && [ ! -d "tests" ]; then
        echo "❌ Not in an R package directory (no R/ or tests/ directory)"
        return 1
    fi

    local file
    file=$(fd -e R -e r . R/ tests/ 2>/dev/null | fzf \
        --prompt="R files > " \
        --preview 'bat --color=always --style=numbers --line-range :100 {}' \
        --preview-window right:60% \
        --height 80% \
        --border \
        --header "Select R file to edit")

    [[ -n "$file" ]] && ${EDITOR:-vim} "$file"
}

# rt - Fuzzy find and run specific test file
# Usage: rt
rt() {
    if [ ! -d "tests/testthat" ]; then
        echo "❌ Not in an R package directory (no tests/testthat/ directory)"
        return 1
    fi

    local file
    file=$(fd -e R . tests/testthat/ | grep "^tests/testthat/test-" | fzf \
        --prompt="Test files > " \
        --preview 'bat --color=always --style=numbers --line-range :50 {}' \
        --preview-window right:60% \
        --height 80% \
        --border \
        --header "Select test file to run")

    if [[ -n "$file" ]]; then
        echo "🧪 Running test: $file"
        Rscript -e "testthat::test_file('$file')"
    fi
}

# rv - Fuzzy find and view R package vignettes
# Usage: rv
rv() {
    if [ ! -d "vignettes" ]; then
        echo "❌ No vignettes directory found"
        return 1
    fi

    local file
    file=$(fd -e Rmd -e qmd . vignettes/ 2>/dev/null | fzf \
        --prompt="Vignettes > " \
        --preview 'bat --color=always --style=numbers --line-range :100 {}' \
        --preview-window right:60% \
        --height 80% \
        --border \
        --header "Select vignette to edit")

    [[ -n "$file" ]] && ${EDITOR:-vim} "$file"
}

# ============================================
# PROJECT STATUS HELPERS
# ============================================

# fs - Fuzzy find and edit .STATUS files
# Usage: fs
fs() {
    local file
    file=$(fd -t f '^\.STATUS$' ~/projects 2>/dev/null | fzf \
        --prompt=".STATUS files > " \
        --preview 'bat --color=always {}' \
        --preview-window right:60% \
        --height 80% \
        --border \
        --header "Select .STATUS file to edit")

    [[ -n "$file" ]] && ${EDITOR:-vim} "$file"
}

# fh - Fuzzy find and view PROJECT-HUB.md files
# Usage: fh
fh() {
    # Help check FIRST (all three forms)
    if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
        cat <<'EOF'
Usage: fh

Browse and view PROJECT-HUB.md files across all projects with fzf.

DESCRIPTION:
  Searches for PROJECT-HUB.md files in ~/projects and displays them
  in fzf with a bat-powered preview. Select a hub to view it in full.

EXAMPLES:
  fh                           # Select and view PROJECT-HUB files

See also: fs, fp
EOF
        return 0
    fi

    local file
    file=$(fd -t f 'PROJECT-HUB.md' ~/projects 2>/dev/null | fzf \
        --prompt="PROJECT-HUB > " \
        --preview 'bat --color=always {}' \
        --preview-window right:60% \
        --height 80% \
        --border \
        --header "Select PROJECT-HUB to view")

    if [[ -n "$file" ]]; then
        bat "$file"
    fi
}

# ============================================
# GIT HELPERS
# ============================================

# gb - Fuzzy git branch checkout
# Usage: gb
gb() {
    unalias gb 2>/dev/null  # Keep existing unalias

    # Help check FIRST (all three forms)
    if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
        cat <<'EOF'
Usage: gb

Browse and checkout git branches with fzf preview.

EXAMPLES:
  gb                           # Select and checkout branch

See also: gdf, gshow, ga
EOF
        return 0
    fi

    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "❌ Not in a git repository"
        return 1
    fi

    local branch
    branch=$(git branch --all | grep -v HEAD | \
        sed 's/^[* ]*//' | sed 's/remotes\/origin\///' | sort -u | \
        fzf --prompt="Git branches > " \
            --preview 'git log --oneline --graph --color=always --date=short --pretty="format:%C(auto)%cd %h%d %s" $(echo {} | sed "s/^remotes\/origin\///") | head -50' \
            --preview-window right:60% \
            --height 80% \
            --border \
            --header "Select branch to checkout")

    if [[ -n "$branch" ]]; then
        git checkout "$branch"
    fi
}

# gdf - Interactive git diff with fzf
# Usage: gdf
gdf() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "❌ Not in a git repository"
        return 1
    fi

    local file
    file=$(git diff --name-only | fzf \
        --prompt="Changed files > " \
        --preview 'git diff --color=always {}' \
        --preview-window right:60% \
        --height 80% \
        --border \
        --header "Select file to view diff (Enter to see full diff)")

    if [[ -n "$file" ]]; then
        git diff "$file" | less -R
    fi
}

# gshow - Fuzzy git log with preview
# Usage: gshow
gshow() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "❌ Not in a git repository"
        return 1
    fi

    local commit
    commit=$(git log --oneline --color=always --decorate | fzf \
        --ansi \
        --prompt="Git log > " \
        --preview 'git show --color=always {1}' \
        --preview-window right:60% \
        --height 80% \
        --border \
        --header "Select commit to view (Enter to see full diff)")

    if [[ -n "$commit" ]]; then
        local hash=$(echo "$commit" | awk '{print $1}')
        git show "$hash" | less -R
    fi
}

# ga - Interactive git add (stage files)
# Usage: ga
ga() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "❌ Not in a git repository"
        return 1
    fi

    local files
    files=$(git status --short | fzf -m \
        --prompt="Stage files > " \
        --preview 'git diff --color=always {2}' \
        --preview-window right:60% \
        --height 80% \
        --border \
        --header "Select files to stage (Tab to select multiple, Enter to add)")

    if [[ -n "$files" ]]; then
        echo "$files" | awk '{print $2}' | xargs git add
        echo "✅ Staged files:"
        echo "$files" | awk '{print "  " $2}'
    fi
}

# gundo - Interactive git reset (unstage files)
# Usage: gundo
gundostage() {
    # Help check FIRST (all three forms)
    if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
        cat <<'EOF'
Usage: gundostage

Unstage files with fzf multi-select preview.

EXAMPLES:
  gundostage                   # Select and unstage files

See also: ga, gdf
EOF
        return 0
    fi

    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "❌ Not in a git repository"
        return 1
    fi

    local files
    files=$(git diff --cached --name-only | fzf -m \
        --prompt="Unstage files > " \
        --preview 'git diff --cached --color=always {}' \
        --preview-window right:60% \
        --height 80% \
        --border \
        --header "Select files to unstage (Tab for multiple, Enter to unstage)")

    if [[ -n "$files" ]]; then
        echo "$files" | xargs git reset HEAD --
        echo "✅ Unstaged files:"
        echo "$files" | awk '{print "  " $0}'
    fi
}

# ============================================
# PROJECT NAVIGATION
# ============================================

# fp - Fuzzy find projects
# Usage: fp
fp() {
    local project
    project=$(fd -t d -d 3 . ~/projects 2>/dev/null | fzf \
        --prompt="Projects > " \
        --preview 'ls -la {} && echo && if [ -f {}/.STATUS ]; then bat --color=always {}/.STATUS; fi' \
        --preview-window right:60% \
        --height 80% \
        --border \
        --header "Select project to cd into")

    if [[ -n "$project" ]]; then
        cd "$project"
        # Show context if available
        [ -f ".STATUS" ] && bat .STATUS
    fi
}

# fr - Fuzzy find R packages
# Usage: fr
fr() {
    # Help check FIRST (all three forms)
    if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
        cat <<'EOF'
Usage: fr

Browse and select R packages from ~/projects/r-packages/active with fzf preview.

Shows DESCRIPTION file preview and allows quick navigation to package directory.
After selection, displays package info using rpkginfo if available.

EXAMPLES:
  fr                           # Select R package and cd into it

See also: re, rt, rv
EOF
        return 0
    fi

    local pkg
    pkg=$(fd -t d -d 1 . ~/projects/r-packages/active 2>/dev/null | fzf \
        --prompt="R packages > " \
        --preview 'ls -la {} && echo && if [ -f {}/DESCRIPTION ]; then bat --color=always {}/DESCRIPTION; fi' \
        --preview-window right:60% \
        --height 80% \
        --border \
        --header "Select R package to cd into")

    if [[ -n "$pkg" ]]; then
        cd "$pkg"
        # Show package info
        rpkginfo 2>/dev/null || ls -la
    fi
}

# ============================================
# USAGE TIPS
# ============================================

# fzf-help - Show all fzf helper functions
fzf-help() {
    cat << 'EOF'
╔════════════════════════════════════════════════════════════╗
║              🔍 FZF HELPER FUNCTIONS                       ║
╚════════════════════════════════════════════════════════════╝

📦 R PACKAGE HELPERS
  re     Fuzzy find & edit R files
  rt     Fuzzy find & run test file
  rv     Fuzzy find & view vignettes

📊 PROJECT STATUS
  fs     Fuzzy find & edit .STATUS files
  fh     Fuzzy find & view PROJECT-HUB.md

🔀 GIT HELPERS
  gb     Fuzzy checkout git branch
  gdf    Interactive git diff
  gshow  Fuzzy git log with preview
  ga     Interactive git add (stage)
  gundostage  Interactive git unstage

🗂️  PROJECT NAVIGATION
  fp     Fuzzy find projects
  fr     Fuzzy find R packages

💡 TIPS
  - Tab: Select multiple items
  - Ctrl+/: Toggle preview
  - Ctrl+N/P: Navigate preview
  - Esc: Cancel

📖 See: help/fzf-helpers.md for more details
EOF
}
