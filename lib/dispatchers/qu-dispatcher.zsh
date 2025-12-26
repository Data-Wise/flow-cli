# qu-dispatcher.zsh - Quarto Publishing System Dispatcher
# Smart Quarto workflows for ADHD-optimized development

# ============================================================================
# QUARTO DISPATCHER
# ============================================================================

qu() {
    # Help check FIRST (all three forms)
    if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
        _qu_help
        return 0
    fi

    local cmd="${1:-render-preview}"

    case "$cmd" in
        render-preview|"")
            # Smart default: render then preview
            echo "📝 Rendering Quarto document..."
            quarto render

            if [[ $? -eq 0 ]]; then
                echo "🔍 Opening preview..."
                quarto preview --no-browser &
                sleep 2
                open http://localhost:4200
            else
                echo "❌ Render failed - skipping preview" >&2
                return 1
            fi
            ;;

        # Core commands
        preview|p)
            quarto preview --no-browser &
            sleep 2
            open http://localhost:4200
            ;;

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

        # Publishing
        publish)     shift; quarto publish "$@" ;;

        # Project creation
        new|n)       shift; quarto create project default "$@" ;;
        article)     shift; quarto create project "$1" --type article ;;
        present|presentation)  shift; quarto create project "$1" --type presentation ;;
        serve|s)     shift; quarto preview "$@" ;;

        # Help
        help|h)
            _qu_help
            ;;

        *)
            echo "qu: unknown command '$cmd'" >&2
            echo "Run 'qu help' for usage" >&2
            return 1
            ;;
    esac
}

# ============================================================================
# HELP
# ============================================================================

_qu_help() {
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
${_C_BOLD}│ qu - Quarto Publishing                      │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}qu${_C_NC}                 Render → preview → auto-open browser
  ${_C_CYAN}qu preview${_C_NC}         Live preview document/project
  ${_C_CYAN}qu render${_C_NC}          Render to output format

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} qu                        ${_C_DIM}# Smart default workflow${_C_NC}
  ${_C_DIM}\$${_C_NC} qu preview                ${_C_DIM}# Preview with live reload${_C_NC}
  ${_C_DIM}\$${_C_NC} qu render                 ${_C_DIM}# Just render${_C_NC}
  ${_C_DIM}\$${_C_NC} qu publish                ${_C_DIM}# Publish to web${_C_NC}

${_C_BLUE}📋 CORE COMMANDS${_C_NC}:
  ${_C_CYAN}qu${_C_NC}                 Smart default: render → preview → open browser
  ${_C_CYAN}qu preview${_C_NC}         Start preview server & open browser
  ${_C_CYAN}qu render${_C_NC}          Render document/project
  ${_C_CYAN}qu check${_C_NC}           Check Quarto installation
  ${_C_CYAN}qu clean${_C_NC}           Remove _site, *_cache, *_files
  ${_C_CYAN}qu publish${_C_NC}         Publish to web

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

${_C_BLUE}ℹ️  SMART DEFAULT WORKFLOW${_C_NC}:
  ${_C_DIM}1. Renders current Quarto document${_C_NC}
  ${_C_DIM}2. Starts preview server (--no-browser)${_C_NC}
  ${_C_DIM}3. Auto-opens browser at http://localhost:4200${_C_NC}
  ${_C_DIM}4. Skips preview if render fails${_C_NC}

${_C_MAGENTA}💡 TIP${_C_NC}: Run ${_C_CYAN}qu${_C_NC} to see your work instantly!
"
}
