# r-dispatcher.zsh - R Package Development Dispatcher
# Smart R package workflows for ADHD-optimized development
#
# NOTE: The ZSH builtin 'r' command (history repeat / fc -e -) is disabled
#       in flow.plugin.zsh to allow this dispatcher to work correctly.
#       Without 'disable r', the builtin shadows this function.

# ============================================================================
# R PACKAGE DISPATCHER
# ============================================================================

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
        help|h|--help|-h)
            _r_help
            ;;

        *)
            echo "Unknown action: $1"
            echo "Run: r help"
            return 1
            ;;
    esac
}

# ============================================================================
# HELP
# ============================================================================

_r_help() {
    # Colors (use flow-cli colors if available)
    local _C_BOLD="${_C_BOLD:-\033[1m}"
    local _C_NC="${_C_NC:-\033[0m}"
    local _C_GREEN="${_C_GREEN:-\033[0;32m}"
    local _C_CYAN="${_C_CYAN:-\033[0;36m}"
    local _C_BLUE="${_C_BLUE:-\033[0;34m}"
    local _C_YELLOW="${_C_YELLOW:-\033[0;33m}"
    local _C_MAGENTA="${_C_MAGENTA:-\033[0;35m}"
    local _C_DIM="${_C_DIM:-\033[2m}"

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

${_C_MAGENTA}💡 TIP${_C_NC}: Run ${_C_CYAN}r${_C_NC} with no arguments to launch R console

${_C_YELLOW}EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} r test              ${_C_DIM}# Run all package tests${_C_NC}
  ${_C_DIM}\$${_C_NC} r doc               ${_C_DIM}# Update documentation${_C_NC}
  ${_C_DIM}\$${_C_NC} r cycle             ${_C_DIM}# Full dev cycle: doc → test → check${_C_NC}
  ${_C_DIM}\$${_C_NC} r quick             ${_C_DIM}# Quick test: load → test${_C_NC}
  ${_C_DIM}\$${_C_NC} r cran              ${_C_DIM}# CRAN submission check${_C_NC}

${_C_DIM}📚 See also:${_C_NC}
  ${_C_CYAN}qu${_C_NC} - Quarto publishing (integrates with R)
  ${_C_CYAN}cc rpkg${_C_NC} - Launch Claude with R package context
  ${_C_CYAN}flow doctor${_C_NC} - Check R development tools
"
}
