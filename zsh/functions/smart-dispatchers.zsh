# ============================================
# SMART FUNCTION DISPATCHERS
# ============================================
# Created: 2025-12-14
# Updated: 2025-12-14 (Phase 1: Enhanced Help System)
# Purpose: Unified command interfaces with full-word actions
# ADHD-Optimized: Self-documenting, discoverable, consistent

# ============================================
# COLOR SUPPORT (Terminal Safe)
# ============================================

# Respect NO_COLOR environment variable
if [[ -z "${NO_COLOR}" ]] && [[ -t 1 ]]; then
    # Section headers and emphasis
    _C_GREEN='\033[0;32m'      # Headers, success
    _C_CYAN='\033[0;36m'       # Commands, actions
    _C_YELLOW='\033[1;33m'     # Examples, warnings
    _C_MAGENTA='\033[0;35m'    # Related, references
    _C_BLUE='\033[0;34m'       # Info, notes
    _C_BOLD='\033[1m'          # Bold text
    _C_DIM='\033[2m'           # Dimmed text
    _C_NC='\033[0m'            # No color (reset)
else
    # No colors (respect NO_COLOR or non-TTY)
    _C_GREEN=''
    _C_CYAN=''
    _C_YELLOW=''
    _C_MAGENTA=''
    _C_BLUE=''
    _C_BOLD=''
    _C_DIM=''
    _C_NC=''
fi

# Unset conflicting aliases before defining functions
unalias r 2>/dev/null
unalias qu 2>/dev/null
unalias cc 2>/dev/null
unalias gm 2>/dev/null
unalias focus 2>/dev/null
unalias note 2>/dev/null
unalias obs 2>/dev/null
unalias workflow 2>/dev/null

# ============================================
# R PACKAGE DEVELOPMENT
# ============================================

r() {
    # No arguments → R console (preserves current behavior)
    if [[ $# -eq 0 ]]; then
        if command -v radian >/dev/null; then
            radian --quiet
        else
            R --quiet
        fi
        return
    fi

    case "$1" in
        # Core workflow
        load|l)      shift; Rscript -e "devtools::load_all()" "$@" ;;
        test|t)      shift; Rscript -e "devtools::test()" "$@" ;;
        doc|d)       shift; Rscript -e "devtools::document()" "$@" ;;
        check|c)     shift; Rscript -e "devtools::check()" "$@" ;;
        build|b)     shift; Rscript -e "devtools::build()" "$@" ;;
        install|i)   shift; Rscript -e "devtools::install()" "$@" ;;

        # Combined workflows
        cycle)       Rscript -e "devtools::document(); devtools::test(); devtools::check()" ;;
        quick|q)     Rscript -e "devtools::load_all(); devtools::test()" ;;

        # Quality
        cov)         Rscript -e "covr::package_coverage()" ;;
        spell)       Rscript -e "spelling::spell_check_package()" ;;

        # Documentation
        pkgdown|pd)  Rscript -e "pkgdown::build_site()" ;;
        preview|pv)  Rscript -e "pkgdown::preview_site()" ;;

        # CRAN checks
        cran)        Rscript -e "devtools::check(args = c('--as-cran'))" ;;
        fast)        Rscript -e "devtools::check(args = c('--no-examples', '--no-tests', '--no-vignettes'))" ;;
        win)         Rscript -e "devtools::check_win_devel()" ;;

        # Version bumps
        patch)       Rscript -e "usethis::use_version('patch')" ;;
        minor)       Rscript -e "usethis::use_version('minor')" ;;
        major)       Rscript -e "usethis::use_version('major')" ;;

        # Cleanup
        clean|cl)
            rm -f .Rhistory .RData
            echo "✓ Removed .Rhistory and .RData"
            ;;

        deep|deepclean)
            echo "⚠️  WARNING: This will remove man/, NAMESPACE, docs/"
            read "?Continue? (y/N) " response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                rm -rf man/ NAMESPACE docs/
                echo "✓ Deep clean complete"
            else
                echo "Cancelled"
            fi
            ;;

        tex|latex)
            rm -f *.aux *.log *.out *.toc *.bbl *.blg
            echo "✓ Removed LaTeX build files"
            ;;

        commit|save)
            shift
            Rscript -e "devtools::document()"
            Rscript -e "devtools::test()"
            git add -A
            git commit -m "${1:-Update package}"
            ;;

        # Info
        info)        rpkginfo ;;
        tree)        rpkgtree ;;

        # Help
        help|h)
            echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ r - R Package Development                   │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}r test${_C_NC}             Run all tests
  ${_C_CYAN}r cycle${_C_NC}            Full cycle: doc → test → check
  ${_C_CYAN}r load${_C_NC}             Load package into memory

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} r test                    ${_C_DIM}# Run all tests${_C_NC}
  ${_C_DIM}\$${_C_NC} r cycle                   ${_C_DIM}# Complete development cycle${_C_NC}
  ${_C_DIM}\$${_C_NC} r load && r test          ${_C_DIM}# Quick iteration loop${_C_NC}

${_C_BLUE}📋 CORE WORKFLOW${_C_NC}:
  ${_C_CYAN}r load${_C_NC}             Load package (devtools::load_all)
  ${_C_CYAN}r test${_C_NC}             Run tests (devtools::test)
  ${_C_CYAN}r doc${_C_NC}              Generate docs (devtools::document)
  ${_C_CYAN}r check${_C_NC}            R CMD check (devtools::check)
  ${_C_CYAN}r build${_C_NC}            Build package (devtools::build)
  ${_C_CYAN}r install${_C_NC}          Install package (devtools::install)

${_C_BLUE}🔀 COMBINED${_C_NC}:
  ${_C_CYAN}r cycle${_C_NC}            doc → test → check (full cycle)
  ${_C_CYAN}r quick${_C_NC}            load → test (quick iteration)

${_C_BLUE}📊 QUALITY${_C_NC}:
  ${_C_CYAN}r cov${_C_NC}              Coverage report (covr)
  ${_C_CYAN}r spell${_C_NC}            Spell check package

${_C_BLUE}📚 DOCUMENTATION${_C_NC}:
  ${_C_CYAN}r pkgdown${_C_NC}          Build pkgdown site
  ${_C_CYAN}r preview${_C_NC}          Preview pkgdown site

${_C_BLUE}✅ CRAN CHECKS${_C_NC}:
  ${_C_CYAN}r cran${_C_NC}             Check as CRAN (--as-cran)
  ${_C_CYAN}r fast${_C_NC}             Fast check (skip examples/tests/vignettes)
  ${_C_CYAN}r win${_C_NC}              Windows dev check

${_C_BLUE}🏷️  VERSION BUMPS${_C_NC}:
  ${_C_CYAN}r patch${_C_NC}            Bump patch version (0.0.X)
  ${_C_CYAN}r minor${_C_NC}            Bump minor version (0.X.0)
  ${_C_CYAN}r major${_C_NC}            Bump major version (X.0.0)

${_C_BLUE}🧹 CLEANUP${_C_NC}:
  ${_C_CYAN}r clean${_C_NC}            Remove .Rhistory and .RData
  ${_C_CYAN}r deep${_C_NC}             Deep clean (man/, NAMESPACE, docs/)
  ${_C_CYAN}r tex${_C_NC}              Remove LaTeX build files
  ${_C_CYAN}r commit${_C_NC}           Document, test, and commit changes

${_C_BLUE}ℹ️  INFO${_C_NC}:
  ${_C_CYAN}r info${_C_NC}             Package info summary
  ${_C_CYAN}r tree${_C_NC}             Package structure tree

${_C_MAGENTA}🔗 SHORTCUTS STILL WORK${_C_NC}:
  ${_C_DIM}rload, rtest, rdoc, rcheck, rbuild, rinstall${_C_NC}

${_C_MAGENTA}📚 MORE HELP${_C_NC} ${_C_DIM}(coming soon)${_C_NC}:
  ${_C_DIM}r help full                # Complete reference${_C_NC}
  ${_C_DIM}r help examples            # More examples${_C_NC}
  ${_C_DIM}r ?                        # Interactive picker${_C_NC}
"
            ;;

        *)
            echo "Unknown action: $1"
            echo "Run: r help"
            return 1
            ;;
    esac
}

# Helper for test suite - shows help
_r_help() {
    r help
}

# ============================================
# QUARTO
# ============================================

qu() {
    # No arguments → show help
    if [[ $# -eq 0 ]]; then
        qu help
        return
    fi

    case "$1" in
        # Core commands
        preview|p)   shift; quarto preview "$@" ;;
        render|r)    shift; quarto render "$@" ;;
        check|c)     shift; quarto check "$@" ;;
        clean)       rm -rf _site/ *_cache/ *_files/ ;;

        # Render to specific formats
        pdf)         shift; quarto render "$@" --to pdf ;;
        html)        shift; quarto render "$@" --to html ;;
        docx)        shift; quarto render "$@" --to docx ;;

        # Combined workflows
        commit)
            shift
            quarto render
            git add -A
            git commit -m "${1:-Update Quarto document}"
            ;;

        # Project creation
        new|n)       shift; quarto create project default "$@" ;;
        article)     shift; quarto create project "$1" --type article ;;
        present|presentation)  shift; quarto create project "$1" --type presentation ;;
        serve|s)     shift; quarto preview "$@" ;;

        # Help
        help|h)
            echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ qu - Quarto Publishing                      │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}qu preview${_C_NC}         Live preview document/project
  ${_C_CYAN}qu render${_C_NC}          Render to output format
  ${_C_CYAN}qu clean${_C_NC}           Remove generated files

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} qu preview                ${_C_DIM}# Preview with live reload${_C_NC}
  ${_C_DIM}\$${_C_NC} qu render                 ${_C_DIM}# Render current document${_C_NC}
  ${_C_DIM}\$${_C_NC} qu clean                  ${_C_DIM}# Clean build artifacts${_C_NC}

${_C_BLUE}📋 CORE COMMANDS${_C_NC}:
  ${_C_CYAN}qu preview${_C_NC}         Preview document/project (live)
  ${_C_CYAN}qu render${_C_NC}          Render document/project
  ${_C_CYAN}qu check${_C_NC}           Check Quarto installation
  ${_C_CYAN}qu clean${_C_NC}           Remove _site, *_cache, *_files

${_C_BLUE}📄 FORMAT-SPECIFIC RENDERING${_C_NC}:
  ${_C_CYAN}qu pdf${_C_NC}             Render to PDF
  ${_C_CYAN}qu html${_C_NC}            Render to HTML
  ${_C_CYAN}qu docx${_C_NC}            Render to Word document

${_C_BLUE}📁 PROJECT CREATION${_C_NC}:
  ${_C_CYAN}qu new <name>${_C_NC}      Create new Quarto project
  ${_C_CYAN}qu article <name>${_C_NC}  Create article project
  ${_C_CYAN}qu present <name>${_C_NC}  Create presentation project
  ${_C_CYAN}qu serve${_C_NC}           Serve project (alias for preview)

${_C_BLUE}🔀 COMBINED WORKFLOWS${_C_NC}:
  ${_C_CYAN}qu commit${_C_NC}          Render and commit changes

${_C_MAGENTA}🔗 SHORTCUTS STILL WORK${_C_NC}:
  ${_C_DIM}qp (preview), qr (render), qc (check), qclean${_C_NC}

${_C_MAGENTA}📚 MORE HELP${_C_NC} ${_C_DIM}(coming soon)${_C_NC}:
  ${_C_DIM}qu help full                # Complete reference${_C_NC}
  ${_C_DIM}qu help examples            # More examples${_C_NC}
  ${_C_DIM}qu ?                        # Interactive picker${_C_NC}
"
            ;;

        *)
            echo "Unknown action: $1"
            echo "Run: qu help"
            return 1
            ;;
    esac
}

# Helper for test suite - shows help
_qu_help() {
    qu help
}

# ============================================
# CLAUDE CODE
# ============================================

cc() {
    # No arguments → use pick to select project, then launch Claude
    if [[ $# -eq 0 ]]; then
        if command -v pick >/dev/null 2>&1; then
            # pick() changes directory interactively, so just run it then launch claude
            pick && claude
        else
            claude
        fi
        return
    fi

    case "$1" in
        # Prompt flag (short prompts)
        prompt|p)
            shift
            local prompt_text="$*"
            if [[ -z "$prompt_text" ]]; then
                echo "Usage: cc p <prompt text>"
                echo "Example: cc p 'analyze this code'"
                return 1
            fi
            claude -p "$prompt_text"
            ;;


        # Session modes
        continue|c)  claude -c ;;
        resume|r)    claude -r ;;
        latest|l)    claude --resume latest ;;

        # Models
        sonnet|s)    shift; claude --model sonnet "$@" ;;
        opus|o)      shift; claude --model opus "$@" ;;
        haiku|h)     shift; claude --model haiku "$@" ;;

        # Permission modes
        plan)        shift; claude --permission-mode plan "$@" ;;
        auto)        shift; claude --permission-mode acceptEdits "$@" ;;
        yolo)        shift; claude --permission-mode bypassPermissions "$@" ;;

        # Management
        mcp)         shift; claude mcp "$@" ;;
        plugin)      shift; claude plugin "$@" ;;

        # Output formats
        json)        shift; claude -p --output-format json "$@" ;;
        stream)      shift; claude -p --output-format stream-json "$@" ;;

        # Common tasks (direct prompts)
        project)     claude "Analyze this project structure and suggest improvements" ;;
        fix)         claude "Fix the bugs in this code" ;;
        review)      claude "Review this code for issues and improvements" ;;
        test)        claude "Generate comprehensive tests for this code" ;;
        doc)         claude "Generate documentation for this code" ;;
        explain)     claude -p "Explain this code clearly and concisely" ;;
        refactor)    claude "Refactor this code for better readability" ;;
        optimize)    claude "Optimize this code for performance" ;;
        security)    claude "Review this code for security vulnerabilities" ;;

        # Help
        help)
            echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ cc - Claude Code CLI                        │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}cc${_C_NC}                 Start interactive session
  ${_C_CYAN}cc continue${_C_NC}        Continue last conversation
  ${_C_CYAN}cc plan${_C_NC}            Plan mode (review actions first)

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} cc                        ${_C_DIM}# Interactive mode${_C_NC}
  ${_C_DIM}\$${_C_NC} cc continue               ${_C_DIM}# Pick up where you left off${_C_NC}
  ${_C_DIM}\$${_C_NC} cc plan \"add tests\"      ${_C_DIM}# Review before executing${_C_NC}

${_C_BLUE}📋 SESSION MANAGEMENT${_C_NC}:
  ${_C_CYAN}cc${_C_NC}                 Interactive mode
  ${_C_CYAN}cc continue${_C_NC}        Continue last conversation (-c)
  ${_C_CYAN}cc resume${_C_NC}          Resume with picker (-r)
  ${_C_CYAN}cc latest${_C_NC}          Resume latest session

${_C_BLUE}🤖 MODEL SELECTION${_C_NC}:
  ${_C_CYAN}cc sonnet${_C_NC}          Use Sonnet (default, balanced)
  ${_C_CYAN}cc opus${_C_NC}            Use Opus (most capable)
  ${_C_CYAN}cc haiku${_C_NC}           Use Haiku (fastest)

${_C_BLUE}🔐 PERMISSION MODES${_C_NC}:
  ${_C_CYAN}cc plan${_C_NC}            Plan mode (review before executing)
  ${_C_CYAN}cc auto${_C_NC}            Auto-accept edits only
  ${_C_CYAN}cc yolo${_C_NC}            Bypass all permissions ${_C_DIM}(⚠️  use with care)${_C_NC}

${_C_BLUE}⚙️  MANAGEMENT${_C_NC}:
  ${_C_CYAN}cc mcp${_C_NC}             MCP server management
  ${_C_CYAN}cc plugin${_C_NC}          Plugin management

${_C_BLUE}📤 OUTPUT FORMATS${_C_NC}:
  ${_C_CYAN}cc json${_C_NC}            JSON output
  ${_C_CYAN}cc stream${_C_NC}          Streaming JSON

${_C_BLUE}⚡ QUICK TASKS${_C_NC} ${_C_DIM}(instant prompts)${_C_NC}:
  ${_C_CYAN}cc project${_C_NC}         Analyze project structure
  ${_C_CYAN}cc fix${_C_NC}             Fix bugs in code
  ${_C_CYAN}cc review${_C_NC}          Review code for improvements
  ${_C_CYAN}cc test${_C_NC}            Generate comprehensive tests
  ${_C_CYAN}cc doc${_C_NC}             Generate documentation
  ${_C_CYAN}cc explain${_C_NC}         Explain code clearly
  ${_C_CYAN}cc refactor${_C_NC}        Refactor for readability
  ${_C_CYAN}cc optimize${_C_NC}        Optimize performance
  ${_C_CYAN}cc security${_C_NC}        Security vulnerability review

${_C_MAGENTA}🔗 SHORTCUTS STILL WORK${_C_NC}:
  ${_C_DIM}ccplan, ccauto, ccyolo${_C_NC}

${_C_MAGENTA}📚 MORE HELP${_C_NC} ${_C_DIM}(coming soon)${_C_NC}:
  ${_C_DIM}cc help full                # Complete reference${_C_NC}
  ${_C_DIM}cc help examples            # More examples${_C_NC}
  ${_C_DIM}cc ?                        # Interactive picker${_C_NC}
"
            ;;

        *)
            # Default: treat as a prompt
            claude "$@"
            ;;
    esac
}

# Helper for test suite - shows help
_cc_help() {
    cc help
}

# ============================================
# GEMINI
# ============================================

gm() {
    # No arguments → use pick to select project, then launch Gemini
    if [[ $# -eq 0 ]]; then
        if command -v pick >/dev/null 2>&1; then
            # pick() changes directory interactively, so just run it then launch gemini
            pick && gemini
        else
            gemini
        fi
        return
    fi

    case "$1" in
        # Prompt flag (short prompts)
        prompt|p)
            shift
            local prompt_text="$*"
            if [[ -z "$prompt_text" ]]; then
                echo "Usage: gm p <prompt text>"
                echo "Example: gm p 'explain this function'"
                return 1
            fi
            gemini -p "$prompt_text"
            ;;

        # Power modes
        yolo)        shift; gemini --yolo "$@" ;;
        sandbox|s)   shift; gemini --sandbox "$@" ;;
        debug|d)     shift; gemini --debug "$@" ;;

        # Session
        resume|r)    gemini --resume latest ;;
        list|ls)     gemini --list-sessions ;;
        delete|del)  shift; gemini --delete-session "$@" ;;

        # Management
        mcp)         shift; gemini mcp "$@" ;;
        ext)         shift; gemini extensions "$@" ;;
        install)     shift; gemini extensions install "$@" ;;
        update)      shift; gemini extensions update "$@" ;;

        # Web search
        web|w)       shift; gemini "Search the web for: $*" ;;
        search)      shift; gemini "Find and summarize information about: $*" ;;

        # Combined modes
        yolosafe)    shift; gemini --yolo --sandbox "$@" ;;
        yolodebug)   shift; gemini --yolo --debug "$@" ;;

        # Help
        help|h)
            echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ gm - Gemini CLI                             │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}gm${_C_NC}                 Use pick to select project, then start Gemini
  ${_C_CYAN}gm p${_C_NC}               Pass short prompt via -p flag
  ${_C_CYAN}gm web${_C_NC}             Search the web (with Gemini)
  ${_C_CYAN}gm yolo${_C_NC}            Auto-approve mode ${_C_DIM}(⚠️  use with care)${_C_NC}

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} gm                        ${_C_DIM}# Pick project, then interactive mode${_C_NC}
  ${_C_DIM}\$${_C_NC} gm p \"explain this\"      ${_C_DIM}# Short prompt via -p flag${_C_NC}
  ${_C_DIM}\$${_C_NC} gm web \"latest news\"     ${_C_DIM}# Search and summarize${_C_NC}
  ${_C_DIM}\$${_C_NC} gm yolo \"analyze logs\"   ${_C_DIM}# Auto-approve actions${_C_NC}

${_C_BLUE}📋 CORE${_C_NC}:
  ${_C_CYAN}gm${_C_NC}                 Use pick to select project
  ${_C_CYAN}gm p <text>${_C_NC}        Pass prompt via -p flag

${_C_BLUE}⚡ POWER MODES${_C_NC}:
  ${_C_CYAN}gm yolo${_C_NC}            Auto-approve all actions ${_C_DIM}(⚠️  YOLO mode)${_C_NC}
  ${_C_CYAN}gm sandbox${_C_NC}         Run in sandbox (safe mode)
  ${_C_CYAN}gm debug${_C_NC}           Debug mode with verbose output

${_C_BLUE}📂 SESSION MANAGEMENT${_C_NC}:
  ${_C_CYAN}gm resume${_C_NC}          Resume latest session
  ${_C_CYAN}gm list${_C_NC}            List all available sessions
  ${_C_CYAN}gm delete <N>${_C_NC}      Delete session by index

${_C_BLUE}⚙️  MANAGEMENT${_C_NC}:
  ${_C_CYAN}gm mcp${_C_NC}             MCP server management
  ${_C_CYAN}gm ext${_C_NC}             Extension management
  ${_C_CYAN}gm install${_C_NC}         Install extension
  ${_C_CYAN}gm update${_C_NC}          Update all extensions

${_C_BLUE}🌐 WEB SEARCH${_C_NC}:
  ${_C_CYAN}gm web <query>${_C_NC}     Search the web
  ${_C_CYAN}gm search <query>${_C_NC}  Find and summarize information

${_C_BLUE}🔀 COMBINED MODES${_C_NC}:
  ${_C_CYAN}gm yolosafe${_C_NC}        YOLO mode in sandbox
  ${_C_CYAN}gm yolodebug${_C_NC}       YOLO with debug output

${_C_MAGENTA}🔗 SHORTCUTS STILL WORK${_C_NC}:
  ${_C_DIM}gmyolo${_C_NC}

${_C_MAGENTA}📚 MORE HELP${_C_NC} ${_C_DIM}(coming soon)${_C_NC}:
  ${_C_DIM}gm help full                # Complete reference${_C_NC}
  ${_C_DIM}gm help examples            # More examples${_C_NC}
  ${_C_DIM}gm ?                        # Interactive picker${_C_NC}
"
            ;;

        *)
            # Default: treat as a prompt
            gemini "$@"
            ;;
    esac
}

# Helper for test suite - shows help
_gm_help() {
    gm help
}

# ============================================
# FOCUS TIMER - DEPRECATED
# ============================================
# focus() is defined in adhd-helpers.zsh (authoritative)
# That version has the actual timer implementation
# This dispatcher version called focus-timer which doesn't exist
#
# focus() {
#     ... moved to adhd-helpers.zsh
# }
#
# To restore dispatcher pattern, create _focus_help() and have
# adhd-helpers.zsh focus() handle the help subcommand

# COMMENTED OUT - keeping for reference
: '
focus_DISABLED() {
    # No arguments → default 25 min timer
    if [[ $# -eq 0 ]]; then
        focus-timer 25
        return
    fi

    case "$1" in
        # Time presets (match existing f15, f25, etc.)
        15)  focus-timer 15 ;;
        25)  focus-timer 25 ;;
        50)  focus-timer 50 ;;
        90)  focus-timer 90 ;;

        # Explicit duration
        [0-9]*)  focus-timer "$1" ;;

        # Management
        check|c)     time-check ;;
        stop|s)      focus-stop ;;
        status)      time-check ;;

        # Help
        help|h)
            echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ focus - Pomodoro Focus Timer                │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}focus${_C_NC}              Start 25 min timer (default)
  ${_C_CYAN}focus 50${_C_NC}           Deep work session (50 min)
  ${_C_CYAN}focus check${_C_NC}        Check timer status

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} focus                     ${_C_DIM}# 25 min Pomodoro${_C_NC}
  ${_C_DIM}\$${_C_NC} focus 50                  ${_C_DIM}# Deep work session${_C_NC}
  ${_C_DIM}\$${_C_NC} focus check               ${_C_DIM}# Time remaining${_C_NC}

${_C_BLUE}⏱️  START TIMER${_C_NC}:
  ${_C_CYAN}focus${_C_NC}              25 min timer (default Pomodoro)
  ${_C_CYAN}focus 15${_C_NC}           15 minute timer (quick task)
  ${_C_CYAN}focus 25${_C_NC}           25 minute timer (Pomodoro)
  ${_C_CYAN}focus 50${_C_NC}           50 minute timer (deep work)
  ${_C_CYAN}focus 90${_C_NC}           90 minute timer (flow state)
  ${_C_CYAN}focus <N>${_C_NC}          Custom N minute timer

${_C_BLUE}⚙️  MANAGE TIMER${_C_NC}:
  ${_C_CYAN}focus check${_C_NC}        Check current timer status
  ${_C_CYAN}focus stop${_C_NC}         Stop current timer
  ${_C_CYAN}focus status${_C_NC}       Timer status (same as check)

${_C_MAGENTA}🔗 SHORTCUTS STILL WORK${_C_NC}:
  ${_C_DIM}f15, f25, f50, f90 (direct presets)${_C_NC}
  ${_C_DIM}tc → focus check, fs → focus stop${_C_NC}

${_C_MAGENTA}📚 MORE HELP${_C_NC} ${_C_DIM}(coming soon)${_C_NC}:
  ${_C_DIM}focus help full             # Complete reference${_C_NC}
  ${_C_DIM}focus ?                     # Interactive picker${_C_NC}
"
            ;;

        *)
            echo "Unknown action: $1"
            echo "Run: focus help"
            return 1
            ;;
    esac
}
'

# ============================================
# NOTE SYNC
# ============================================

note() {
    # No arguments → show status
    if [[ $# -eq 0 ]]; then
        note help
        return
    fi

    case "$1" in
        # Core operations
        sync|s)      nsync ;;
        view|v)      nsyncview ;;
        clip|c)      nsyncclip ;;
        export|e)    nsyncexport ;;

        # Status
        status)      pstat ;;
        show)        pstatshow ;;
        list|l)      pstatlist ;;
        count)       pstatcount ;;

        # Help
        help|h)
            echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ note - Apple Notes Sync                     │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}note sync${_C_NC}          Sync dashboard to Apple Notes
  ${_C_CYAN}note status${_C_NC}        Update project status
  ${_C_CYAN}note view${_C_NC}          View dashboard content

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} note sync                 ${_C_DIM}# Push to Apple Notes${_C_NC}
  ${_C_DIM}\$${_C_NC} note status               ${_C_DIM}# Update .STATUS files${_C_NC}
  ${_C_DIM}\$${_C_NC} note list                 ${_C_DIM}# Show all projects${_C_NC}

${_C_BLUE}📱 SYNC OPERATIONS${_C_NC}:
  ${_C_CYAN}note sync${_C_NC}          Sync dashboard to Apple Notes
  ${_C_CYAN}note view${_C_NC}          View dashboard content
  ${_C_CYAN}note clip${_C_NC}          Copy dashboard to clipboard
  ${_C_CYAN}note export${_C_NC}        Export dashboard to file

${_C_BLUE}📊 STATUS MANAGEMENT${_C_NC}:
  ${_C_CYAN}note status${_C_NC}        Update project status
  ${_C_CYAN}note show${_C_NC}          Show status JSON
  ${_C_CYAN}note list${_C_NC}          List all .STATUS files
  ${_C_CYAN}note count${_C_NC}         Count projects by status

${_C_MAGENTA}🔗 SHORTCUTS STILL WORK${_C_NC}:
  ${_C_DIM}ns, nsv, nsc, nse (sync operations)${_C_NC}
  ${_C_DIM}pstat, psv, psl, psc (status commands)${_C_NC}

${_C_MAGENTA}📚 MORE HELP${_C_NC} ${_C_DIM}(coming soon)${_C_NC}:
  ${_C_DIM}note help full              # Complete reference${_C_NC}
  ${_C_DIM}note ?                      # Interactive picker${_C_NC}
"
            ;;

        *)
            echo "Unknown action: $1"
            echo "Run: note help"
            return 1
            ;;
    esac
}

# ============================================
# OBSIDIAN - DEPRECATED
# ============================================
# obs() is defined in obs.zsh (authoritative)
# That version has the full implementation with graph, sync, etc.
# This was a simpler wrapper - commented out to avoid duplicate
#
# COMMENTED OUT - keeping for reference
: '
obs_DISABLED() {
    # No arguments → show help
    if [[ $# -eq 0 ]]; then
        obs help
        return
    fi

    local subcommand="$1"
    shift

    case "$subcommand" in
        # ============================================
        # GRAPH ANALYSIS (obsidian-cli-ops)
        # ============================================
        graph|g)
            local graph_cmd="${1:-help}"
            shift

            case "$graph_cmd" in
                discover|d)
                    # Call obsidian-cli-ops discover command
                    /Users/dt/projects/dev-tools/obsidian-cli-ops/src/obs.zsh discover "$@"
                    ;;
                scan|sc)
                    /Users/dt/projects/dev-tools/obsidian-cli-ops/src/obs.zsh scan "$@"
                    ;;
                tui|t)
                    /Users/dt/projects/dev-tools/obsidian-cli-ops/src/obs.zsh tui "$@"
                    ;;
                stats|st)
                    /Users/dt/projects/dev-tools/obsidian-cli-ops/src/obs.zsh stats "$@"
                    ;;
                analyze|a)
                    /Users/dt/projects/dev-tools/obsidian-cli-ops/src/obs.zsh analyze "$@"
                    ;;
                vaults|v)
                    /Users/dt/projects/dev-tools/obsidian-cli-ops/src/obs.zsh vaults "$@"
                    ;;
                help|h|*)
                    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ obs graph - Knowledge Graph Analysis       │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}📊 GRAPH COMMANDS${_C_NC}:
  ${_C_CYAN}obs graph discover${_C_NC}     Find Obsidian vaults
  ${_C_CYAN}obs graph scan${_C_NC}         Scan vault for notes/links
  ${_C_CYAN}obs graph tui${_C_NC}          Launch interactive TUI
  ${_C_CYAN}obs graph stats${_C_NC}        Show vault statistics
  ${_C_CYAN}obs graph analyze${_C_NC}      Analyze knowledge graph
  ${_C_CYAN}obs graph vaults${_C_NC}       List all vaults

${_C_YELLOW}💡 EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} obs graph tui              ${_C_DIM}# Launch TUI${_C_NC}
  ${_C_DIM}\$${_C_NC} obs graph discover ~/Docs  ${_C_DIM}# Find vaults${_C_NC}
  ${_C_DIM}\$${_C_NC} obs graph stats vault_id   ${_C_DIM}# Show stats${_C_NC}
"
                    ;;
            esac
            ;;

        # ============================================
        # VAULT NAVIGATION (obsidian-bridge)
        # ============================================
        open|o)
            local open_cmd="${1:-help}"
            shift

            case "$open_cmd" in
                research|r)   obs-research "$@" ;;
                knowledge|k)  obs-knowledge "$@" ;;
                life|l)       obs-life "$@" ;;
                dashboard|d)  obs-dashboard ;;
                quick|q)      obs-quick-note "$@" ;;
                help|h|*)
                    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ obs open - Vault Navigation                │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}📂 OPEN COMMANDS${_C_NC}:
  ${_C_CYAN}obs open research${_C_NC}      Open Research_Lab vault
  ${_C_CYAN}obs open knowledge${_C_NC}     Open Knowledge_Base vault
  ${_C_CYAN}obs open life${_C_NC}          Open Life_Admin vault
  ${_C_CYAN}obs open dashboard${_C_NC}     Open MediationVerse dashboard
  ${_C_CYAN}obs open quick${_C_NC} <title>  Create quick note

${_C_YELLOW}💡 EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} obs open research         ${_C_DIM}# Open vault${_C_NC}
  ${_C_DIM}\$${_C_NC} obs open quick \"My idea\"  ${_C_DIM}# Quick note${_C_NC}
  ${_C_DIM}\$${_C_NC} obs open dashboard        ${_C_DIM}# Open dashboard${_C_NC}

${_C_MAGENTA}🔗 SHORTCUTS${_C_NC}: ${_C_DIM}or, ok, ol, od, oqn${_C_NC}
"
                    ;;
            esac
            ;;

        # ============================================
        # SYNC OPERATIONS
        # ============================================
        sync|s)
            local sync_cmd="${1:-help}"
            shift

            case "$sync_cmd" in
                project|p)  obs-project-sync "$@" ;;
                all|a)      obs-sync-all ;;
                help|h|*)
                    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ obs sync - Project & Vault Sync             │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔄 SYNC COMMANDS${_C_NC}:
  ${_C_CYAN}obs sync project${_C_NC}       Sync .STATUS to dashboard
  ${_C_CYAN}obs sync all${_C_NC}           Sync settings across vaults

${_C_YELLOW}💡 EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} obs sync project -a       ${_C_DIM}# Auto-update${_C_NC}
  ${_C_DIM}\$${_C_NC} obs sync all              ${_C_DIM}# Sync all vaults${_C_NC}

${_C_MAGENTA}🔗 SHORTCUTS${_C_NC}: ${_C_DIM}ops, osa${_C_NC}
"
                    ;;
            esac
            ;;

        # ============================================
        # MAIN HELP
        # ============================================
        help|h)
            echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ obs - Unified Obsidian Management           │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC}:
  ${_C_CYAN}obs graph tui${_C_NC}          Launch interactive TUI
  ${_C_CYAN}obs open research${_C_NC}      Open research vault
  ${_C_CYAN}obs open dashboard${_C_NC}     Open dashboard
  ${_C_CYAN}obs sync project${_C_NC}       Sync project status

${_C_BLUE}📊 GRAPH ANALYSIS${_C_NC}:
  ${_C_CYAN}obs graph${_C_NC} ...          Knowledge graph operations
  ${_C_DIM}Run 'obs graph help' for details${_C_NC}

${_C_BLUE}📂 VAULT NAVIGATION${_C_NC}:
  ${_C_CYAN}obs open${_C_NC} ...           Open vaults & notes
  ${_C_DIM}Run 'obs open help' for details${_C_NC}

${_C_BLUE}🔄 SYNC OPERATIONS${_C_NC}:
  ${_C_CYAN}obs sync${_C_NC} ...           Sync projects & settings
  ${_C_DIM}Run 'obs sync help' for details${_C_NC}

${_C_MAGENTA}🔗 SHORTCUTS STILL WORK${_C_NC}:
  ${_C_DIM}or (research), ok (knowledge), od (dashboard)${_C_NC}
  ${_C_DIM}ops (project sync), osa (sync all)${_C_NC}
  ${_C_DIM}oqn (quick note)${_C_NC}

${_C_YELLOW}💡 TIP${_C_NC}: Use shortcuts for quick access!
"
            ;;

        *)
            echo "❌ Unknown command: $subcommand"
            echo "Run: obs help"
            return 1
            ;;
    esac
}
'

# ============================================
# WORKFLOW LOGGING
# ============================================

workflow() {
    # No arguments → show recent
    if [[ $# -eq 0 ]]; then
        worklog
        return
    fi

    case "$1" in
        # View logs
        show|s)      worklog ;;
        recent|r)    worklog ;;
        today|t)     worklog-today ;;
        yesterday|y) worklog-yesterday ;;
        week|w)      worklog-week ;;

        # Session management
        started)     shift; worklog-started "$@" ;;
        finished|f)  shift; worklog-finished "$@" ;;
        break|b)     shift; worklog-break "$@" ;;
        paused|p)    shift; worklog-paused "$@" ;;

        # Help
        help|h)
            echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ workflow - Activity Logging                 │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}workflow${_C_NC}           Show recent activity log
  ${_C_CYAN}workflow today${_C_NC}     Today's activity
  ${_C_CYAN}workflow started${_C_NC}   Log session start

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} workflow                  ${_C_DIM}# Recent activity${_C_NC}
  ${_C_DIM}\$${_C_NC} workflow today            ${_C_DIM}# Today's log${_C_NC}
  ${_C_DIM}\$${_C_NC} workflow started \"coding\" ${_C_DIM}# Log start${_C_NC}

${_C_BLUE}👁️  VIEW LOGS${_C_NC}:
  ${_C_CYAN}workflow${_C_NC}           Show recent logs (default)
  ${_C_CYAN}workflow today${_C_NC}     Show today's entries
  ${_C_CYAN}workflow yesterday${_C_NC} Show yesterday's entries
  ${_C_CYAN}workflow week${_C_NC}      Show this week's activity

${_C_BLUE}📝 SESSION LOGGING${_C_NC}:
  ${_C_CYAN}workflow started <task>${_C_NC}   Log session start
  ${_C_CYAN}workflow finished <task>${_C_NC}  Log session completion
  ${_C_CYAN}workflow break${_C_NC}            Log break time
  ${_C_CYAN}workflow paused <reason>${_C_NC}  Log pause with reason

${_C_MAGENTA}🔗 SHORTCUTS STILL WORK${_C_NC}:
  ${_C_DIM}wl (show recent), wls (started)${_C_NC}
  ${_C_DIM}wlf (finished), wlb (break), wlp (paused)${_C_NC}

${_C_MAGENTA}📚 MORE HELP${_C_NC} ${_C_DIM}(coming soon)${_C_NC}:
  ${_C_DIM}workflow help full          # Complete reference${_C_NC}
  ${_C_DIM}workflow ?                  # Interactive picker${_C_NC}
"
            ;;

        *)
            echo "Unknown action: $1"
            echo "Run: workflow help"
            return 1
            ;;
    esac
}

# ============================================
# TIMER - FOCUS & BREAK MANAGEMENT
# ============================================

timer() {
    # No arguments → show help
    if [[ $# -eq 0 ]]; then
        _timer_help
        return
    fi

    case "$1" in
        # Focus sessions
        focus|f)
            shift
            local duration="${1:-25}"
            _timer_focus "$duration"
            ;;
        deep|d)
            shift
            local duration="${1:-90}"
            _timer_focus "$duration"
            ;;

        # Break sessions
        break|b)
            shift
            local duration="${1:-5}"
            _timer_break "$duration"
            ;;
        long|l)
            shift
            local duration="${1:-15}"
            _timer_break "$duration"
            ;;

        # Timer control
        stop|end|x)
            _timer_stop
            ;;
        status|st)
            _timer_status
            ;;

        # Pomodoro cycle
        pom|pomodoro)
            _timer_pomodoro_cycle
            ;;

        # Help
        help|h)
            _timer_help
            ;;

        *)
            echo "Unknown action: $1"
            echo "Run: timer help"
            return 1
            ;;
    esac
}

# Helper: Start focus timer
_timer_focus() {
    local duration="${1:-25}"
    local timer_file="/tmp/focus_timer_$$"

    echo "🎯 Focus session: ${duration} minutes"
    echo "⏱️  Timer started at $(date '+%H:%M')"

    # Store timer info
    echo "FOCUS|$duration|$(date +%s)" > "$timer_file"

    # Run timer in background
    (
        sleep $((duration * 60))
        osascript -e "display notification \"Focus session complete! Time for a break.\" with title \"⏰ Timer Complete\" sound name \"Glass\""
        rm -f "$timer_file"
    ) &

    echo "💡 Use 'timer status' to check remaining time"
    echo "💡 Use 'timer stop' to cancel"
}

# Helper: Start break timer
_timer_break() {
    local duration="${1:-5}"
    local timer_file="/tmp/focus_timer_$$"

    echo "☕ Break time: ${duration} minutes"
    echo "⏱️  Timer started at $(date '+%H:%M')"

    # Store timer info
    echo "BREAK|$duration|$(date +%s)" > "$timer_file"

    # Run timer in background
    (
        sleep $((duration * 60))
        osascript -e "display notification \"Break time over! Ready to focus?\" with title \"⏰ Timer Complete\" sound name \"Glass\""
        rm -f "$timer_file"
    ) &

    echo "💡 Use 'timer status' to check remaining time"
}

# Helper: Stop current timer
_timer_stop() {
    setopt local_options null_glob
    local timer_files=(/tmp/focus_timer_*)
    local timer_file="${timer_files[1]}"

    if [[ -z "$timer_file" ]]; then
        echo "❌ No active timer found"
        return 1
    fi

    # Kill background sleep processes
    pkill -f "sleep.*60" 2>/dev/null
    rm -f "$timer_file"

    echo "⏹️  Timer stopped"
}

# Helper: Show timer status
_timer_status() {
    setopt local_options null_glob
    local timer_files=(/tmp/focus_timer_*)
    local timer_file="${timer_files[1]}"

    if [[ -z "$timer_file" ]]; then
        echo "💤 No active timer"
        return 0
    fi

    # Read timer info
    local timer_info=$(cat "$timer_file")
    local timer_type=$(echo "$timer_info" | cut -d'|' -f1)
    local duration=$(echo "$timer_info" | cut -d'|' -f2)
    local start_time=$(echo "$timer_info" | cut -d'|' -f3)

    # Calculate remaining time
    local now=$(date +%s)
    local elapsed=$(( (now - start_time) / 60 ))
    local remaining=$((duration - elapsed))

    if [[ $remaining -le 0 ]]; then
        echo "⏰ Timer completed (waiting for notification)"
        return 0
    fi

    # Display status
    local icon="🎯"
    [[ "$timer_type" == "BREAK" ]] && icon="☕"

    echo "$icon Active timer: $timer_type"
    echo "⏱️  Duration: ${duration} minutes"
    echo "⌛ Remaining: ${remaining} minutes"
}

# Helper: Pomodoro cycle (25 min work, 5 min break, repeat)
_timer_pomodoro_cycle() {
    echo "🍅 Starting Pomodoro cycle:"
    echo "   1. Focus: 25 minutes"
    echo "   2. Break: 5 minutes"
    echo ""
    echo "Starting first focus session..."
    _timer_focus 25

    echo ""
    echo "💡 After the focus timer completes, run: timer break"
    echo "💡 Or run 'timer pom' again to start a new cycle"
}

# Helper: Show help
_timer_help() {
    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ timer - Focus & Break Management            │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}timer focus${_C_NC}        25 min focus session (default)
  ${_C_CYAN}timer break${_C_NC}        5 min break (default)
  ${_C_CYAN}timer status${_C_NC}       Check timer status

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} timer focus              ${_C_DIM}# 25 min Pomodoro${_C_NC}
  ${_C_DIM}\$${_C_NC} timer focus 45           ${_C_DIM}# 45 min custom session${_C_NC}
  ${_C_DIM}\$${_C_NC} timer deep               ${_C_DIM}# 90 min deep work${_C_NC}
  ${_C_DIM}\$${_C_NC} timer break              ${_C_DIM}# 5 min break${_C_NC}
  ${_C_DIM}\$${_C_NC} timer status             ${_C_DIM}# Check time remaining${_C_NC}

${_C_BLUE}🎯 FOCUS SESSIONS${_C_NC}:
  ${_C_CYAN}timer focus${_C_NC}        25 min focus (Pomodoro default)
  ${_C_CYAN}timer focus <N>${_C_NC}    Custom N-minute focus session
  ${_C_CYAN}timer deep${_C_NC}         90 min deep work session
  ${_C_CYAN}timer deep <N>${_C_NC}     Custom deep work duration

${_C_BLUE}☕ BREAK SESSIONS${_C_NC}:
  ${_C_CYAN}timer break${_C_NC}        5 min short break (default)
  ${_C_CYAN}timer break <N>${_C_NC}    Custom N-minute break
  ${_C_CYAN}timer long${_C_NC}         15 min long break
  ${_C_CYAN}timer long <N>${_C_NC}     Custom long break duration

${_C_BLUE}⚙️  TIMER CONTROL${_C_NC}:
  ${_C_CYAN}timer status${_C_NC}       Show active timer & remaining time
  ${_C_CYAN}timer stop${_C_NC}         Stop/cancel current timer

${_C_BLUE}🍅 POMODORO${_C_NC}:
  ${_C_CYAN}timer pom${_C_NC}          Start Pomodoro cycle (25 min + instructions)
  ${_C_CYAN}timer pomodoro${_C_NC}     Same as 'pom'

${_C_MAGENTA}💡 WORKFLOW TIP${_C_NC}:
  1. ${_C_CYAN}timer focus${_C_NC}    ${_C_DIM}→ Work focused for 25 min${_C_NC}
  2. ${_C_CYAN}timer break${_C_NC}    ${_C_DIM}→ Take a 5 min break${_C_NC}
  3. Repeat 4x, then ${_C_CYAN}timer long${_C_NC} ${_C_DIM}→ 15 min break${_C_NC}

${_C_BLUE}ℹ️  NOTIFICATIONS${_C_NC}:
  ${_C_DIM}• macOS notifications appear when timer completes${_C_NC}
  ${_C_DIM}• Check 'timer status' anytime to see remaining time${_C_NC}
  ${_C_DIM}• Use 'timer stop' to cancel if plans change${_C_NC}
"
}

# ============================================
# PEEK - UNIFIED FILE VIEWER
# ============================================

peek() {
    # Check if bat is available (for syntax highlighting)
    local viewer_cmd
    if command -v bat >/dev/null 2>&1; then
        viewer_cmd=(bat --style=plain --paging=never)
    else
        viewer_cmd=(cat)
    fi

    # No arguments → show help
    if [[ $# -eq 0 ]]; then
        _peek_help
        return
    fi

    case "$1" in
        # File type viewers
        r)
            shift
            if [[ -z "$1" ]]; then
                echo "❌ Usage: peek r <file.R>"
                return 1
            fi
            if [[ ! -f "$1" ]]; then
                echo "❌ File not found: $1"
                return 1
            fi
            echo -e "${_C_BOLD}📄 R File: $1${_C_NC}\n"
            "${viewer_cmd[@]}" "$1"
            ;;

        rd)
            shift
            if [[ -z "$1" ]]; then
                echo "❌ Usage: peek rd <file.Rd>"
                return 1
            fi
            if [[ ! -f "$1" ]]; then
                echo "❌ File not found: $1"
                return 1
            fi
            echo -e "${_C_BOLD}📄 R Documentation: $1${_C_NC}\n"
            "${viewer_cmd[@]}" "$1"
            ;;

        qu)
            shift
            if [[ -z "$1" ]]; then
                echo "❌ Usage: peek qu <file.qmd>"
                return 1
            fi
            if [[ ! -f "$1" ]]; then
                echo "❌ File not found: $1"
                return 1
            fi
            echo -e "${_C_BOLD}📄 Quarto File: $1${_C_NC}\n"
            "${viewer_cmd[@]}" "$1"
            ;;

        md)
            shift
            if [[ -z "$1" ]]; then
                echo "❌ Usage: peek md <file.md>"
                return 1
            fi
            if [[ ! -f "$1" ]]; then
                echo "❌ File not found: $1"
                return 1
            fi
            echo -e "${_C_BOLD}📄 Markdown: $1${_C_NC}\n"
            "${viewer_cmd[@]}" "$1"
            ;;

        # Special files
        desc)
            if [[ ! -f "DESCRIPTION" ]]; then
                echo "❌ DESCRIPTION file not found in current directory"
                return 1
            fi
            echo -e "${_C_BOLD}📦 DESCRIPTION${_C_NC}\n"
            "${viewer_cmd[@]}" "DESCRIPTION"
            ;;

        news)
            if [[ ! -f "NEWS.md" ]]; then
                echo "❌ NEWS.md not found in current directory"
                return 1
            fi
            echo -e "${_C_BOLD}📰 NEWS.md${_C_NC}\n"
            "${viewer_cmd[@]}" "NEWS.md"
            ;;

        status|st)
            if [[ ! -f ".STATUS" ]]; then
                echo "❌ .STATUS file not found in current directory"
                return 1
            fi
            echo -e "${_C_BOLD}📊 .STATUS${_C_NC}\n"
            "${viewer_cmd[@]}" ".STATUS"
            ;;

        log)
            local log_file="$HOME/.workflow.log"
            if [[ ! -f "$log_file" ]]; then
                echo "❌ Workflow log not found at: $log_file"
                return 1
            fi
            echo -e "${_C_BOLD}📝 Workflow Log (last 50 lines)${_C_NC}\n"
            tail -n 50 "$log_file" | "${viewer_cmd[@]}"
            ;;

        # Help
        help|h)
            _peek_help
            ;;

        # Auto-detect file type
        *)
            local file="$1"
            if [[ ! -f "$file" ]]; then
                echo "❌ File not found: $file"
                echo "Run: peek help"
                return 1
            fi
            _peek_auto "$file"
            ;;
    esac
}

# Helper: Auto-detect file type and view
_peek_auto() {
    local file="$1"
    local viewer_cmd
    if command -v bat >/dev/null 2>&1; then
        viewer_cmd=(bat --style=plain --paging=never)
    else
        viewer_cmd=(cat)
    fi

    # Detect file type by extension
    case "$file" in
        *.R)
            echo -e "${_C_BOLD}📄 R File: $file${_C_NC}\n"
            "${viewer_cmd[@]}" "$file"
            ;;
        *.Rd)
            echo -e "${_C_BOLD}📄 R Documentation: $file${_C_NC}\n"
            "${viewer_cmd[@]}" "$file"
            ;;
        *.qmd)
            echo -e "${_C_BOLD}📄 Quarto File: $file${_C_NC}\n"
            "${viewer_cmd[@]}" "$file"
            ;;
        *.md)
            echo -e "${_C_BOLD}📄 Markdown: $file${_C_NC}\n"
            "${viewer_cmd[@]}" "$file"
            ;;
        *)
            echo -e "${_C_BOLD}📄 File: $file${_C_NC}\n"
            "${viewer_cmd[@]}" "$file"
            ;;
    esac
}

# Helper: Show help
_peek_help() {
    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ peek - Unified File Viewer                  │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}peek <file>${_C_NC}        Auto-detect and view any file
  ${_C_CYAN}peek desc${_C_NC}          View DESCRIPTION file
  ${_C_CYAN}peek status${_C_NC}        View .STATUS file

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} peek file.R              ${_C_DIM}# View R file${_C_NC}
  ${_C_DIM}\$${_C_NC} peek desc                ${_C_DIM}# View DESCRIPTION${_C_NC}
  ${_C_DIM}\$${_C_NC} peek qu file.qmd         ${_C_DIM}# View Quarto file${_C_NC}
  ${_C_DIM}\$${_C_NC} peek log                 ${_C_DIM}# View workflow log${_C_NC}

${_C_BLUE}📄 FILE TYPE VIEWERS${_C_NC}:
  ${_C_CYAN}peek r <file>${_C_NC}      View R file (.R)
  ${_C_CYAN}peek rd <file>${_C_NC}     View R documentation (.Rd)
  ${_C_CYAN}peek qu <file>${_C_NC}     View Quarto file (.qmd)
  ${_C_CYAN}peek md <file>${_C_NC}     View Markdown file (.md)

${_C_BLUE}📋 SPECIAL FILES${_C_NC}:
  ${_C_CYAN}peek desc${_C_NC}          View DESCRIPTION (R package)
  ${_C_CYAN}peek news${_C_NC}          View NEWS.md (changelog)
  ${_C_CYAN}peek status${_C_NC}        View .STATUS file
  ${_C_CYAN}peek log${_C_NC}           View workflow log (last 50 lines)

${_C_BLUE}🔍 AUTO-DETECT${_C_NC}:
  ${_C_CYAN}peek <file>${_C_NC}        Auto-detect file type and view
  ${_C_DIM}• Supports: .R, .Rd, .qmd, .md, and more${_C_NC}
  ${_C_DIM}• Uses bat for syntax highlighting (if available)${_C_NC}
  ${_C_DIM}• Falls back to cat if bat not installed${_C_NC}

${_C_MAGENTA}🔗 SHORTCUTS REPLACED${_C_NC}:
  ${_C_DIM}peekr → peek r${_C_NC}
  ${_C_DIM}peekrd → peek rd${_C_NC}
  ${_C_DIM}peekqu → peek qu${_C_NC}
  ${_C_DIM}peekmd → peek md${_C_NC}
  ${_C_DIM}peekdesc → peek desc${_C_NC}
  ${_C_DIM}peeknews → peek news${_C_NC}

${_C_BLUE}ℹ️  FEATURES${_C_NC}:
  ${_C_DIM}• Syntax highlighting with bat (when available)${_C_NC}
  ${_C_DIM}• Graceful error messages for missing files${_C_NC}
  ${_C_DIM}• Consistent interface across file types${_C_NC}
  ${_C_DIM}• Smart auto-detection by file extension${_C_NC}
"
}

# ============================================
# COMPLETION
# ============================================
# Note: ZSH completion support can be added here in the future
