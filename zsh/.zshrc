# ============================================
# ANTIDOTE PLUGIN MANAGER
# ============================================

# Enable Powerlevel10k instant prompt (should stay at top)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Disable OMZ auto-title (we use iterm2-context-switcher instead)
DISABLE_AUTO_TITLE="true"

# Initialize antidote (installed via homebrew)
source $(brew --prefix)/opt/antidote/share/antidote/antidote.zsh

# Fix for OMZ async prompt regression
# See: https://github.com/ohmyzsh/ohmyzsh/issues/12328
zstyle ':omz:alpha:lib:git' async-prompt no

# Load plugins from .zsh_plugins.txt
# Note: use-omz + ohmyzsh/ohmyzsh path:lib handles compinit automatically
antidote load $ZDOTDIR/.zsh_plugins.txt

# ============================================
# POWERLEVEL10K CUSTOMIZATION
# ============================================

# Load p10k config if it exists
[[ ! -f $ZDOTDIR/.p10k.zsh ]] || source $ZDOTDIR/.p10k.zsh

# Add indicator when in R package directory
function prompt_r_package() {
    if [[ -f "DESCRIPTION" ]] && grep -q "^Package:" DESCRIPTION 2>/dev/null; then
        local pkg_name=$(grep "^Package:" DESCRIPTION | cut -d' ' -f2)
        p10k segment -f yellow -i '📦' -t "$pkg_name"
    fi
}

# ============================================
# ENVIRONMENT VARIABLES
# ============================================

# R Package Development
export R_PACKAGES_DIR="$HOME/R-packages"
export QUARTO_DIR="$HOME/quarto-projects"

# R Console
export R_PROFILE_USER="$HOME/.Rprofile"
export RADIAN_THEME="native"

# ============================================
# HISTORY CONFIGURATION
# ============================================

HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000

setopt EXTENDED_HISTORY          # Record timestamp
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicates first
setopt HIST_IGNORE_DUPS          # Don't record duplicates
setopt HIST_IGNORE_SPACE         # Ignore commands starting with space
setopt HIST_VERIFY               # Show before executing history
setopt SHARE_HISTORY             # Share history across terminals

# Enhanced history search (arrow keys)
bindkey "^[[A" history-beginning-search-backward
bindkey "^[[B" history-beginning-search-forward

# ============================================
# ZSH OPTIONS
# ============================================

# Directory navigation
setopt AUTO_CD                   # Just type directory name to cd
setopt AUTO_PUSHD               # Push directories onto stack
setopt PUSHD_IGNORE_DUPS        # Don't push duplicates
setopt PUSHD_SILENT             # Don't print directory stack

# Completion
setopt COMPLETE_IN_WORD         # Complete from both ends
setopt ALWAYS_TO_END            # Move cursor to end after completion

# ============================================
# COMPLETIONS
# ============================================
# Note: compinit is initialized earlier before loading antidote plugins

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Completion colors
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Partial completion
zstyle ':completion:*' list-suffixes
zstyle ':completion:*' expand prefix suffix

# Menu selection
zstyle ':completion:*' menu select

# Cache completions
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# ============================================
# DIRECTORY NAVIGATION
# ============================================

# Bookmark system (use cd ~bookmark)
hash -d rpkg="$R_PACKAGES_DIR"
hash -d quarto="$QUARTO_DIR"

# Directory aliases - REMOVED 2025-12-19: Use 'pick' or 'pp' instead
# alias cdrpkg='cd $R_PACKAGES_DIR'
# alias cdq='cd $QUARTO_DIR'

# Directory stack shortcut - REMOVED 2025-12-19: Use 'dirs' directly
# alias d='dirs -v | head -10'

# Quick directory creation and navigation
function mkcd() {
    mkdir -p "$1" && cd "$1"
}

# ============================================
# MODERN CLI TOOLS
# ============================================

# Better ls (check if eza is installed)
if command -v eza >/dev/null; then
    alias ls='eza --icons --git'
    alias ll='eza -lah --icons --git'
    alias la='eza -A --icons --git'
    alias l='eza -F --icons --git'
    alias tree='eza --tree --icons --git'
else
    alias ll='ls -lah'
    alias la='ls -A'
    alias l='ls -CF'
fi

# Better cat (you already use bat)
alias cat='bat'
# Note: peek is now a function in smart-dispatchers.zsh for smart file viewing

# Better find/grep - REMOVED 2025-12-19: Use fd and rg directly
# alias find='fd'
# alias grep='rg'

# Modern alternatives (if installed)
command -v dust >/dev/null && alias du='dust'
command -v duf >/dev/null && alias df='duf'
command -v btop >/dev/null && alias top='btop'

# Zoxide (modern replacement for 'z' - faster, Rust-based)
if command -v zoxide >/dev/null; then
    eval "$(zoxide init zsh)"
    # Optional: Keep 'z' as alias for zoxide (backward compatible)
    # Note: zoxide provides 'z', 'zi' (interactive), and 'za' (add) commands
fi

# Atuin (supercharged shell history - context-aware, searchable, synced)
# Installed: 2025-12-16
if command -v atuin >/dev/null; then
    eval "$(atuin init zsh)"
    # Keybindings:
    # - Ctrl+R: Interactive fuzzy search
    # - Up arrow: Still works for history search
    # Features: Search by directory, time, success/failure, sync across machines
fi

# Direnv (automatic per-project environment setup)
# Installed: 2025-12-16
if command -v direnv >/dev/null; then
    eval "$(direnv hook zsh)"
    # Usage: Create .envrc in project root with environment variables
    # Example: export R_LIBS_USER=~/R/project-libs
    # Auto-loads when you cd into directory (after 'direnv allow')
fi

# ============================================
# GIT ENHANCEMENTS
# ============================================
# Note: Use `g` dispatcher instead (g log, g status, g undo, etc.)
# Old aliases removed 2025-12-17

# R package specific - REMOVED 2025-12-19: Use rpkgcommit directly
# alias gpkgcommit='rpkgcommit'

# ============================================
# 📦 R PACKAGE DEVELOPMENT
# ============================================
# CONSOLIDATED 2025-12-26: Use 'r' dispatcher from flow-cli
# Run 'r help' to see all available commands:
#   r test, r doc, r check, r build, r cov, r cran, r patch, etc.

# R Console - radian as default
command -v radian >/dev/null && alias R='radian'

# ============================================
# 📝 QUARTO SHORTCUTS
# ============================================
# Note: qu dispatcher is now active in flow-cli (qu preview, qu render, qu check, qu clean)
# Old aliases removed 2025-12-17

# ============================================
# 🤖 CLAUDE CODE
# ============================================
# CONSOLIDATED 2025-12-26: Use 'cc' dispatcher from flow-cli
# Run 'cc help' to see all available commands:
#   cc, cc yolo, cc plan, cc ask, cc file, cc diff, cc resume, etc.

# Backward compatibility alias for YOLO mode
alias ccy='cc yolo'

# ============================================
# R PACKAGE DEVELOPMENT - FUNCTIONS
# ============================================

# File creation functions
function rnewfun() {
    if [ -z "$1" ]; then
        echo "Usage: rnewfun <function_name>"
        return 1
    fi
    Rscript -e "usethis::use_r('$1')"
}

function rnewtest() {
    if [ -z "$1" ]; then
        echo "Usage: rnewtest <function_name>"
        return 1
    fi
    Rscript -e "usethis::use_test('$1')"
}

function rnewvig() {
    if [ -z "$1" ]; then
        echo "Usage: rnewvig <vignette_name>"
        return 1
    fi
    Rscript -e "usethis::use_vignette('$1')"
}

function rnewdata() {
    if [ -z "$1" ]; then
        echo "Usage: rnewdata <data_name>"
        return 1
    fi
    Rscript -e "usethis::use_data_raw('$1')"
}

# Test-specific functions
function rtest1() {
    if [ -z "$1" ]; then
        echo "Usage: rtest1 <test_pattern>"
        return 1
    fi
    Rscript -e "devtools::test(filter = '$1')"
}

function rtestfile() {
    if [ -z "$1" ]; then
        echo "Usage: rtestfile <path_to_test_file>"
        return 1
    fi
    Rscript -e "testthat::test_file('$1')"
}

function rdepsexplain() {
    if [ -z "$1" ]; then
        echo "Usage: rdepsexplain <package_name>"
        return 1
    fi
    Rscript -e "pak::pkg_deps_explain('$1')"
}

# Create new R package with best practices
function rnewpkg() {
    if [ -z "$1" ]; then
        echo "Usage: rnewpkg <packagename>"
        return 1
    fi

    local pkgname="$1"

    echo "📦 Creating R package: $pkgname"
    echo ""

    # Create in R-packages directory
    mkdir -p "$R_PACKAGES_DIR"
    cd "$R_PACKAGES_DIR"

    # Create package
    Rscript -e "usethis::create_package('$pkgname', open = FALSE)"
    cd "$pkgname"

    # Set up infrastructure
    echo "🔧 Setting up infrastructure..."
    Rscript -e "usethis::use_git()"
    Rscript -e "usethis::use_mit_license()"
    Rscript -e "usethis::use_roxygen_md()"
    Rscript -e "usethis::use_testthat()"
    Rscript -e "usethis::use_package_doc()"
    Rscript -e "usethis::use_pipe()"

    # Create basic README
    Rscript -e "usethis::use_readme_rmd()"
    Rscript -e "usethis::use_news_md()"

    echo ""
    echo "✅ Package created!"
    rpkgtree
    echo ""
    echo "Next: Edit DESCRIPTION, then start coding!"
}

# Full development cycle
function rpkgcycle() {
    echo "🔄 Full package development cycle..."
    echo ""
    echo "📝 Step 1/3: Documentation..."
    rdoc || { echo "❌ Failed"; return 1; }
    echo "✅ Documentation complete"
    echo ""
    echo "🧪 Step 2/3: Tests..."
    rtest || { echo "❌ Failed"; return 1; }
    echo "✅ Tests passed"
    echo ""
    echo "✅ Step 3/3: R CMD check..."
    rcheck || { echo "❌ Failed"; return 1; }
    echo ""
    echo "🎉 All checks passed!"
}

# Commit with checks
function rpkgcommit() {
    if [ -z "$1" ]; then
        echo "Usage: rpkgcommit 'commit message'"
        return 1
    fi

    echo "🔍 Running pre-commit checks..."

    echo "  📝 Documenting..."
    rdoc || { echo "❌ Failed"; return 1; }

    echo "  🧪 Testing..."
    rtest || { echo "❌ Failed"; return 1; }

    # Style code if styler available
    if Rscript -e "requireNamespace('styler', quietly = TRUE)" 2>/dev/null; then
        echo "  💅 Styling..."
        Rscript -e "styler::style_pkg(quiet = TRUE)"
    fi

    echo "  📦 Committing..."
    git add .
    git commit -m "$1"

    echo ""
    echo "✅ Committed! Push with: git push"
}

# Package info
function rpkginfo() {
    local pkgname=$(basename "$PWD")

    echo "📦 Package: $pkgname"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Version
    if [ -f "DESCRIPTION" ]; then
        echo "📌 Version:"
        Rscript -e "cat('  ', as.character(desc::desc_get_version()), '\n')" 2>/dev/null || echo "  (unable to read)"
        echo ""
    fi

    # Functions
    echo "🔧 R Scripts: $(ls -1 R/*.R 2>/dev/null | wc -l | xargs)"
    echo "🧪 Tests: $(ls -1 tests/testthat/test-*.R 2>/dev/null | wc -l | xargs)"
    echo "📖 Rd files: $(ls -1 man/*.Rd 2>/dev/null | wc -l | xargs)"
    echo ""

    # Git
    echo "🔀 Git:"
    git branch --show-current 2>/dev/null | xargs echo "  Branch:" || echo "  Not a git repo"
    echo ""

    # Structure
    rpkgtree
}

# Interactive file creator
function rpkgnew() {
    local type="${1:-function}"

    case $type in
        function|fun|f)
            read "name?Function name: "
            rnewfun "$name"
            rnewtest "$name"
            echo "✅ Created R/$name.R and tests/testthat/test-$name.R"
            ;;
        test|t)
            read "name?Test name: "
            rnewtest "$name"
            ;;
        vignette|vig|v)
            read "name?Vignette name: "
            rnewvig "$name"
            ;;
        data|d)
            read "name?Data name: "
            rnewdata "$name"
            ;;
        *)
            echo "Usage: rpkgnew [function|test|vignette|data]"
            ;;
    esac
}

# Search R package code
function rpkgfind() {
    if [ -z "$1" ]; then
        echo "Usage: rpkgfind <pattern>"
        return 1
    fi

    echo "🔍 Searching for: $1"
    echo ""
    echo "In R/:"
    rg "$1" R/ --heading --line-number 2>/dev/null || echo "  (no matches)"
    echo ""
    echo "In tests/:"
    rg "$1" tests/ --heading --line-number 2>/dev/null || echo "  (no matches)"
}

# Auto-activate renv notification
function auto_renv() {
    if [[ -f "renv.lock" ]] && [[ "$RENV_ACTIVE" != "TRUE" ]]; then
        echo "📦 renv detected - activate with: Rscript -e 'renv::activate()'"
    fi
}

# Run on directory change
chpwd_functions+=(auto_renv)

# ============================================
# QUARTO FUNCTIONS
# ============================================

# Create new Quarto project
function qnew() {
    if [ -z "$1" ]; then
        echo "Usage: qnew <projectname>"
        return 1
    fi

    mkdir -p "$QUARTO_DIR"
    cd "$QUARTO_DIR"
    quarto create project default "$1"
    cd "$1"
    echo "✅ Quarto project created: $1"
}

# Start Quarto preview in background
function qprev() {
    local file="${1:-index.qmd}"
    echo "👁️  Starting Quarto preview for $file..."
    quarto preview "$file" > /dev/null 2>&1 &
    echo "Preview running (PID: $!)"
}

# Quick Quarto workflow
function qwork() {
    local file="${1:-index.qmd}"

    # Open in editor
    code "$file" 2>/dev/null || open "$file"

    # Start preview
    qprev "$file"

    echo ""
    echo "✅ Workflow ready!"
    echo "   📝 Editor opened"
    echo "   👁️  Preview running"
    echo "   💬 Run 'ccc' for Claude"
}

# ============================================
# GENERAL R FUNCTIONS
# ============================================

# Create new R project
function rnew() {
    if [ -z "$1" ]; then
        echo "Usage: rnew <projectname>"
        return 1
    fi

    mkdir -p "$1"
    cd "$1"
    git init

    # Create structure
    mkdir -p R data output scripts docs
    touch README.md .gitignore

    # .gitignore
    cat > .gitignore << 'EOF'
.Rproj.user
.Rhistory
.RData
.Ruserdata
*.Rproj
.DS_Store
output/*
EOF

    # README
    echo "# $1" > README.md
    echo "" >> README.md
    echo "Created: $(date +%Y-%m-%d)" >> README.md

    echo "✅ R project created: $1"
    tree -L 1 2>/dev/null || ls -la
}

# ============================================
# FZF INTEGRATION (if installed)
# ============================================

if [ -f ~/.fzf.zsh ]; then
    source ~/.fzf.zsh

    # Use fd for fzf
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

    # R package file finder
    rfzf() {
        local file
        file=$(fd --type f . R tests man | fzf --preview 'bat --color=always {}')
        [[ -n "$file" ]] && ${EDITOR:-vim} "$file"
    }
fi

# ============================================
# SECURE TOKEN MANAGEMENT
# ============================================

# Load GitHub token from macOS Keychain (if stored)
if command -v security >/dev/null 2>&1; then
    # Disabled to allow gh CLI to use its own valid keyring auth
    # export GITHUB_TOKEN=$(security find-generic-password -a "$USER" -s github_token -w 2>/dev/null)
    
    # Load token specifically for Gemini extensions (uses the 'github_token' keychain item)
    export GITHUB_MCP_PAT=$(security find-generic-password -a "$USER" -s github_token -w 2>/dev/null)
    
    export DC_API_KEY="1lwAVbNQrOq3m71Ff3BPqxQBQRPuWBdZ9o7b89VAadANreAE"
fi

# To store token securely (run once):
# security add-generic-password -a "$USER" -s github_token -w "your_token_here"

# ============================================
# SSH AGENT CONFIGURATION
# ============================================
# Start ssh-agent if not running
if [ -z "$SSH_AUTH_SOCK" ]; then
   eval "$(ssh-agent -s)" > /dev/null
   ssh-add --apple-use-keychain ~/.ssh/id_ed25519 2>/dev/null
fi

# ============================================
# LAZY LOADING (Performance optimization)
# ============================================

# Lazy load pyenv if installed
if command -v pyenv 1>/dev/null 2>&1; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)"
fi

# ============================================
# CUSTOM FUNCTIONS
# ============================================

# Source custom functions
# MOVED TO .zshenv 2025-12-23 - Loaded universally for Claude Code support
# if [[ -f ~/.config/zsh/functions/genpass.zsh ]]; then
#     source ~/.config/zsh/functions/genpass.zsh
# fi

# Option B+ Multi-Editor Quadrant System (2025-12-13)
# MOVED TO .zshenv 2025-12-23 - Loaded universally for Claude Code support
# if [[ -f ~/.config/zsh/functions/work.zsh ]]; then
#     source ~/.config/zsh/functions/work.zsh
# fi

# MOVED TO .zshenv 2025-12-23
# if [[ -f ~/.config/zsh/functions/claude-workflows.zsh ]]; then
#     source ~/.config/zsh/functions/claude-workflows.zsh
# fi

# MOVED TO .zshenv 2025-12-23
# if [[ -f ~/.config/zsh/functions/adhd-helpers.zsh ]]; then
#     source ~/.config/zsh/functions/adhd-helpers.zsh
# fi

# MOVED TO .zshenv 2025-12-23
# if [[ -f ~/.config/zsh/functions/dash.zsh ]]; then
#     source ~/.config/zsh/functions/dash.zsh
# fi

# MOVED TO .zshenv 2025-12-23
# if [[ -f ~/.config/zsh/functions/status.zsh ]]; then
#     source ~/.config/zsh/functions/status.zsh
# fi

# MOVED TO .zshenv 2025-12-23
# if [[ -f ~/.config/zsh/functions/obsidian-bridge.zsh ]]; then
#     source ~/.config/zsh/functions/obsidian-bridge.zsh
# fi

if [[ -f ~/.config/zsh/functions/fzf-helpers.zsh ]]; then
    source ~/.config/zsh/functions/fzf-helpers.zsh
fi

# Claude Response Viewer with Glow (2025-12-16)
if [[ -f ~/.config/zsh/functions/claude-response-viewer.zsh ]]; then
    source ~/.config/zsh/functions/claude-response-viewer.zsh
fi

# Background Agent Management (2025-12-16)
if [[ -f ~/.config/zsh/functions/bg-agents.zsh ]]; then
    source ~/.config/zsh/functions/bg-agents.zsh
fi

# Scribe CLI - Terminal-based note access (2025-12-27, Sprint 20)
if [[ -f ~/.config/zsh/functions/scribe.zsh ]]; then
    source ~/.config/zsh/functions/scribe.zsh
fi

# MCP Server Management Dispatcher (2025-12-19)
# MOVED TO .zshenv 2025-12-23
# if [[ -f ~/.config/zsh/functions/mcp-dispatcher.zsh ]]; then
#     source ~/.config/zsh/functions/mcp-dispatcher.zsh
# fi

# ============================================
# LOCAL CUSTOMIZATIONS
# ============================================

# Source local config if it exists (for machine-specific settings)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# ============================================
# ZSH-CLAUDE WORKFLOW
# ============================================

# Add zsh-claude-workflow commands to PATH
export PATH="$HOME/projects/dev-tools/zsh-claude-workflow/commands:$PATH"

# Aliases for quick access - REMOVED 2025-12-19: Use full commands instead
# alias ptype='proj-type'
# alias pinfo='proj-info'
# alias cctx='claude-ctx'
# alias cinit='claude-init'
# alias cshow='claude-show'
# alias pclaude='proj-claude'

# ============================================
# 📊 PROJECT STATUS (Local Operations)
# ============================================
# Note: dashupdate() function defined at line 962
# REMOVED 2025-12-19: Use full commands instead

# alias pstat='~/projects/dev-tools/apple-notes-sync/scanner.sh'
# alias pstatshow='pstat && jq -C . /tmp/project-status.json | less -R'
# alias pstatview='pstat && cat /tmp/project-status.json | jq -r ".projects[] | \"\(.priority) \(.name) [\(.progress)%] - \(.next)\""'
# alias pstatlist='command find ~/projects/r-packages/active -name ".STATUS" -exec echo {} \;'
# alias pstatcount='pstat && jq -r "\"Total: \(.projects|length) | Blocked: \([.projects[]|select(.status==\"blocked\")]|length) | Active: \([.projects[]|select(.status==\"active\")]|length)\"" /tmp/project-status.json'

# ============================================
# 📝 NOTES SYNC (Apple Notes Operations)
# ============================================
# REMOVED 2025-12-19: Use full commands instead

# alias nsync='pstat && ~/projects/dev-tools/apple-notes-sync/dashboard-applescript.sh'
# alias nsyncview='osascript -e "tell application \"Notes\" to return body of (first note of account \"iCloud\" whose name is \"📊 Project Dashboard\")" | sed "s/<[^>]*>//g" | sed "s/&nbsp;/ /g"'
# alias nsyncclip='~/projects/dev-tools/apple-notes-sync/dashboard-clipboard.sh'
# alias nsyncexport='~/projects/dev-tools/apple-notes-sync/dashboard-export.sh'

# ============================================
# ⚡ ULTRA-SHORT ALIASES (Power Users)
# ============================================

# Project Status (ps conflicts with Unix command, use carefully) - REMOVED 2025-12-19
# alias psv='pstatview'
# alias psl='pstatlist'
# alias psc='pstatcount'
# alias pss='pstatshow'

# Notes Sync - REMOVED 2025-12-19: Use full commands instead
# alias ns='nsync'
# alias nsv='nsyncview'
# alias nsc='nsyncclip'
# alias nse='nsyncexport'

# ============================================
# 🔄 DEPRECATED (Backward Compatibility)
# ============================================
# Use new aliases: pstat*, nsync* instead
# Note: dashupdate() function exists at line 998 (no alias needed)

# REPLACED 2025-12-19: dashsync is now a function in adhd-helpers.zsh
# REMOVED 2025-12-19: alias dashclip, alias dashexport (deprecated)

# ============================================
# 🔧 TYPO TOLERANCE (ADHD-Friendly Recovery)
# ============================================
# Common typos auto-correct to correct command

# Claude typos - REMOVED 2025-12-19: Type correctly
# alias claue='claude'
# alias cluade='claude'
# alias clade='claude'
# alias calue='claude'
# alias claudee='claude'

# R package typos - REMOVED 2025-12-19: Type correctly
# alias rlaod='rload'
# alias rlod='rload'
# alias rtets='rtest'
# alias rtset='rtest'
# alias rdco='rdoc'
# alias rchekc='rcheck'
# alias rchck='rcheck'
# alias rcylce='rcycle'

# Git typos - REMOVED 2025-12-19: Git plugin now provides all git aliases
# alias gti='g'
# alias tgi='g'
# alias gis='g'
# alias gitstatus='g status'

# Common command typos - REMOVED 2025-12-19: Type correctly
# alias clera='clear'
# alias claer='clear'
# alias sl='ls'
# alias pdw='pwd'

# Quarto typos - REMOVED 2025-12-19: Type correctly
# alias qurto='quarto'
# alias qaurt='quarto'

# ============================================
# 💎 GEMINI CLI ALIASES (v0.22.2) - Updated 2025-12-25
# ============================================
# Note: 'gm' conflicts with GraphicsMagick, using 'gem' prefix instead
# Note: -p flag deprecated, use positional prompts: gemini "query"

# Main shortcut
alias gem='gemini'

# Web search functions (updated to remove deprecated -p flag)
gemw() {
    if [ -z "$*" ]; then
        echo "Usage: gemw <search query>"
        echo "Example: gemw latest AI news"
        return 1
    fi
    gemini "Search the web for: $*"
}

gemws() {
    if [ -z "$*" ]; then
        echo "Usage: gemws <search query>"
        echo "Example: gemws Python best practices 2025"
        return 1
    fi
    gemini "Find and summarize information about: $*"
}

# Quick interactive with common options
alias gemi='gemini -i'                    # Interactive mode
alias gemy='gemini -y'                    # YOLO mode (auto-approve)
alias gems='gemini -s'                    # Sandbox mode
alias gemr='gemini -r latest'             # Resume latest session

# Model selection shortcuts
alias gemf='gemini -m gemini-2.5-flash'   # Fast model
alias gemp='gemini -m gemini-2.5-pro'     # Pro model

# Output formats
alias gemj='gemini -o json'               # JSON output
alias gemsj='gemini -o stream-json'       # Streaming JSON

# Common workflows
gemc() {
    # Code review current changes
    gemini "Review my git changes and suggest improvements"
}

geme() {
    # Explain current codebase
    gemini "Explain the architecture of this codebase"
}

gemd() {
    # Debug help
    gemini "Help me debug this issue: $*"
}

# ============================================
# 🔷 OPENCODE ALIAS - Added 2025-12-25
# ============================================
alias oc='opencode'

# emacs-plus@30 (Homebrew) — make emacs-plus the default Emacs and set editor vars
# Adjust the path to match the installed version if different.
export PATH="/opt/homebrew/opt/emacs-plus@30/bin:$PATH"

# Use emacsclient as the default editor (starts a frame with the daemon if available)
export EDITOR="/opt/homebrew/opt/emacs-plus@30/bin/emacsclient"
export VISUAL="/opt/homebrew/opt/emacs-plus@30/bin/emacsclient"

# Convenience alias to open a new GUI frame (falls back to starting Emacs if no daemon)
# REMOVED 2025-12-19: Use 'emacs' or 'emacsclient' directly
# alias e="/opt/homebrew/opt/emacs-plus@30/bin/emacsclient -c -a ''"
# alias ec="/opt/homebrew/opt/emacs-plus@30/bin/emacsclient -c -a ''"

# The emacs-plus formula injects your shell PATH into Finder-launched Emacs.app by default.
# To disable that behavior (not usually recommended), uncomment the following line:
# export EMACS_PLUS_NO_PATH_INJECTION=1

# Optional: start emacs daemon on login via brew services (uncomment to enable)
# brew services start d12frosted/emacs-plus/emacs-plus@30 >/dev/null 2>&1 || true
export PATH="/opt/homebrew/bin:$PATH"

# ============================================
# CUSTOM WORKFLOW FUNCTIONS
# ============================================
# Source custom workflow functions
if [[ -f ~/.config/zsh/functions.zsh ]]; then
    source ~/.config/zsh/functions.zsh
fi

# ============================================
# 🔍 ALIAS DISCOVERY HELPER (ADHD-Optimized)
# ============================================

# Main discovery function - shows categorized aliases
aliases() {
  local category="${1:-all}"
  
  case "$category" in
    all|"")
      echo "╔════════════════════════════════════════════════════════════╗"
      echo "║              📋 ZSH ALIAS QUICK REFERENCE                  ║"
      echo "╚════════════════════════════════════════════════════════════╝"
      echo ""
      echo "🤖 CLAUDE CODE (31 aliases)"
      alias | grep "^cc" | head -5
      echo "   ... (run 'aliases claude' for all)"
      echo ""
      echo "📦 R PACKAGE DEV (27 aliases)"
      alias | grep "^r" | grep -v "^run-help" | head -5
      echo "   ... (run 'aliases r' for all)"
      echo ""
      echo "⚡ ULTRA-SHORT (5 aliases)"
      echo "   ld → rload  |  ts → rtest  |  dc → rdoc  |  ck → rcheck  |  bd → rbuild"
      echo ""
      echo "💎 GEMINI CLI (13 aliases - v0.22.2)"
      alias | grep "^gem" | head -5
      echo "   ... (run 'aliases gemini' for all)"
      echo ""
      echo "📝 QUARTO (4 aliases)"
      alias | grep "^q[a-z]" 
      echo ""
      echo "🔀 GIT (6 aliases)"
      alias | grep "^g" | grep -v "^gem"
      echo ""
      echo "📂 FILE VIEWING (9 aliases)"
      alias | grep "^peek\|^cat=\|^find=\|^grep="
      echo ""
      echo "Run: aliases <category> for details (claude, r, gemini, quarto, git, files)"
      ;;
    
    claude|cc)
      echo "🤖 CLAUDE CODE ALIASES (31 total)"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      alias | grep "^cc"
      ;;
    
    r|rpkg|rpackage)
      echo "📦 R PACKAGE DEVELOPMENT ALIASES (27 total)"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      alias | grep "^r" | grep -v "^run-help"
      ;;
    
    gemini|gem)
      echo "💎 GEMINI CLI ALIASES (v0.22.2)"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "Main: gem, gemi, gemy, gems, gemr"
      echo "Models: gemf (flash), gemp (pro)"
      echo "Output: gemj (json), gemsj (stream-json)"
      echo "Web: gemw, gemws"
      echo "Workflows: gemc (code review), geme (explain), gemd (debug)"
      echo ""
      echo "Full list:"
      alias | grep "^gem" | sort
      ;;
    
    quarto|q)
      echo "📝 QUARTO ALIASES (4 total)"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      alias | grep "^q[a-z]"
      ;;
    
    git|g)
      echo "🔀 GIT ALIASES (6 total)"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      alias | grep "^g" | grep -v "^gem"
      ;;
    
    files|file|peek)
      echo "📂 FILE VIEWING ALIASES (9 total)"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      alias | grep "^peek\|^cat=\|^find=\|^grep="
      ;;
    
    short|ultra|fast)
      echo "⚡ ULTRA-SHORT ALIASES (5 total)"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "ld  → rload   (Load R package)"
      echo "ts  → rtest   (Test R package)"
      echo "dc  → rdoc    (Document R package)"
      echo "ck  → rcheck  (Check R package)"
      echo "bd  → rbuild  (Build R package)"
      ;;
    
    *)
      echo "❌ Unknown category: $category"
      echo "Available: all, claude, r, gemini, quarto, git, files, short"
      return 1
      ;;
  esac
}

# Category-specific shortcuts - REMOVED 2025-12-19: Use 'aliases <category>' directly
# alias aliases-claude='aliases claude'
# alias aliases-r='aliases r'
# alias aliases-gemini='aliases gemini'
# alias aliases-quarto='aliases quarto'
# alias aliases-git='aliases git'
# alias aliases-files='aliases files'
# alias aliases-short='aliases short'



# ════════════════════════════════════════════════════════════════════
# DASHBOARD UPDATE FUNCTION
# ════════════════════════════════════════════════════════════════════
# Part of apple-notes-sync project
# Added: 2025-12-13

# Dashboard update function - scans .STATUS files and prepares for Claude
# DEPRECATED: Use 'pstat' instead
dashupdate() {
    echo "⚠️  DEPRECATED: Use 'pstat' instead of 'dashupdate'"
    echo ""

    local projects_dir="${1:-$HOME/projects/r-packages/active}"
    local output_file="/tmp/project-status.json"
    local scanner="$HOME/projects/dev-tools/apple-notes-sync/scanner.sh"

    echo "📊 Scanning project status..."
    echo ""
    
    # Run scanner
    if [[ -x "$scanner" ]]; then
        "$scanner" "$projects_dir" "$output_file"
    else
        echo "❌ Scanner not found: $scanner"
        return 1
    fi
    
    # Show summary
    echo ""
    echo "📋 Status JSON ready at: $output_file"
    echo ""
    echo "┌─────────────────────────────────────────────────┐"
    echo "│ Next: Open Claude Desktop and say:             │"
    echo "│                                                 │"
    echo "│   [Dashboard] Update from project-status.json  │"
    echo "│                                                 │"
    echo "└─────────────────────────────────────────────────┘"
    echo ""
    
    # Copy path to clipboard
    echo "$output_file" | pbcopy
    echo "📎 Path copied to clipboard"
}

# Alias for quick access
# REPLACED 2025-12-19: alias dash='dashupdate' → Now a function in dash.zsh
# REMOVED 2025-12-19: alias dashopen='dashupdate && open -a "Claude"'
# REMOVED: alias do='dashopen'
# Reason: 'do' is a ZSH reserved word (for loops: for x do ... done)
# Aliasing it breaks parsing of any subsequent 'for' loops, causing:
# "parse error near `unset'" in Positron's shell integration script
# Use 'dashopen' or 'dash' directly instead

# ─── iTerm2 Smart Context Switching ───────────────────────────────────────────
[[ -f ~/projects/dev-tools/iterm2-context-switcher/zsh/iterm2-integration.zsh ]] && \
  source ~/projects/dev-tools/iterm2-context-switcher/zsh/iterm2-integration.zsh
export PATH="/opt/homebrew/opt/imagemagick@6/bin:$PATH"

# Smart Function Dispatchers (ADHD-Optimized)
# NOTE 2025-12-25: Dispatchers in flow-cli plugin (loaded via flow.plugin.zsh)
#
# Active dispatchers in ~/projects/dev-tools/flow-cli/lib/dispatchers/:
#   g      - Git workflows
#   mcp    - MCP server management
#   obs    - Obsidian integration
#   qu     - Quarto publishing (restored 2025-12-25)
#   r      - R package development (restored 2025-12-25)
#
# Removed: v, vibe (deprecated - use 'flow' command instead)
#
# Not restored (personal shortcuts in .zshrc work better):
#   cc/gem - Use ccy, gem* aliases below instead
#   note   - Use obs dispatcher
#   timer  - Use flow timer command

# Terminal Management System (tmux + project launcher) - Added 2025-12-21
[[ -f ~/.local/share/terminal-aliases.sh ]] && \
    source ~/.local/share/terminal-aliases.sh

# ============================================
# FLOW CLI PLUGIN - Added 2025-12-23
# ============================================
# Modern ZSH plugin architecture with single source location
# Replaces old ~/.config/zsh/functions/ and .zshenv loading
[[ -f ~/.zsh/plugins/flow-cli/flow.plugin.zsh ]] && \
    source ~/.zsh/plugins/flow-cli/flow.plugin.zsh

# obs CLI completion
fpath=(~/.zsh/completions $fpath)

## Shell Command Integration
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Nexus Desktop - Quick Launcher
alias nexus='cd ~/projects/dev-tools/nexus/nexus-desktop && npm start'

# ============================================
# GIT WORKTREE ALIASES
# ============================================
alias wt='cd ~/.git-worktrees'
alias wtl='git worktree list'

# Scribe project worktrees
alias scribe-hud='cd ~/.git-worktrees/scribe/mission-control-hud'
alias scribe-alt='cd ~/.git-worktrees/scribe/wonderful-wilson'

# aiterm project worktrees
alias aiterm-ghost='cd ~/.git-worktrees/aiterm/feature-ghostty-support'

# ============================================
# CLAUDE SKILLS MANAGEMENT - Added 2025-01-02
# ============================================
[[ -f ~/.config/zsh/functions/skill-helpers.zsh ]] && \
    source ~/.config/zsh/functions/skill-helpers.zsh

