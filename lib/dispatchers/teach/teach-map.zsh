# teach-map.zsh - Extracted from teach-dispatcher.zsh
# ============================================================================

_teach_map_detect_tools() {
    typeset -gA _TEACH_MAP_TOOLS

    # flow-cli is always available (we're running inside it)
    _TEACH_MAP_TOOLS[flow]=1

    # Scholar: Claude Code plugin
    if [[ -d "${HOME}/.claude/plugins/scholar" ]]; then
        _TEACH_MAP_TOOLS[scholar]=1
    else
        _TEACH_MAP_TOOLS[scholar]=0
    fi

    # Craft: Claude Code plugin
    if [[ -d "${HOME}/.claude/plugins/craft" ]]; then
        _TEACH_MAP_TOOLS[craft]=1
    else
        _TEACH_MAP_TOOLS[craft]=0
    fi
}

# teach map -- Unified ecosystem discovery (v6.6.0)

_teach_map() {
    # Color fallbacks
    if [[ -z "$_C_BOLD" ]]; then
        _C_BOLD='\033[1m'
        _C_DIM='\033[2m'
        _C_NC='\033[0m'
        _C_GREEN='\033[32m'
        _C_YELLOW='\033[33m'
        _C_BLUE='\033[34m'
        _C_MAGENTA='\033[35m'
        _C_CYAN='\033[36m'
    fi

    # Detect available tools
    _teach_map_detect_tools

    # Tool status badges
    local flow_badge="${_C_GREEN}[flow-cli]${_C_NC}"
    local scholar_badge craft_badge
    if [[ "${_TEACH_MAP_TOOLS[scholar]}" == "1" ]]; then
        scholar_badge="${_C_GREEN}[scholar]${_C_NC}"
    else
        scholar_badge="${_C_DIM}[scholar] (not installed)${_C_NC}"
    fi
    if [[ "${_TEACH_MAP_TOOLS[craft]}" == "1" ]]; then
        craft_badge="${_C_GREEN}[craft]${_C_NC}"
    else
        craft_badge="${_C_DIM}[craft] (not installed)${_C_NC}"
    fi

    # Tool header
    local scholar_status craft_status
    if [[ "${_TEACH_MAP_TOOLS[scholar]}" == "1" ]]; then
        scholar_status="${_C_GREEN}scholar${_C_NC}"
    else
        scholar_status="${_C_DIM}scholar (not installed)${_C_NC}"
    fi
    if [[ "${_TEACH_MAP_TOOLS[craft]}" == "1" ]]; then
        craft_status="${_C_GREEN}craft${_C_NC}"
    else
        craft_status="${_C_DIM}craft (not installed)${_C_NC}"
    fi

    # Scholar command color (dim if not installed)
    local sc="${_C_CYAN}"
    [[ "${_TEACH_MAP_TOOLS[scholar]}" != "1" ]] && sc="${_C_DIM}"

    # Craft command color (dim if not installed)
    local crc="${_C_CYAN}"
    [[ "${_TEACH_MAP_TOOLS[craft]}" != "1" ]] && crc="${_C_DIM}"

    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ teach map -- Teaching Ecosystem             │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

 Tools: ${_C_GREEN}flow-cli${_C_NC}  ${scholar_status}  ${craft_status}

${_C_BLUE} SETUP & CONFIGURATION${_C_NC}
  ${_C_CYAN}teach init${_C_NC} [name]           Initialize project          ${flow_badge}
  ${_C_CYAN}teach config${_C_NC}                Edit configuration          ${flow_badge}
  ${_C_CYAN}teach doctor${_C_NC} [--fix]        Health check                ${flow_badge}
  ${_C_CYAN}teach dates${_C_NC}                 Date management             ${flow_badge}
  ${_C_CYAN}teach hooks${_C_NC}                 Git hook management         ${flow_badge}
  ${_C_CYAN}teach plan${_C_NC}                  Lesson plan CRUD            ${flow_badge}
  ${_C_CYAN}teach templates${_C_NC}             Template management         ${flow_badge}
  ${_C_CYAN}teach macros${_C_NC}                LaTeX macros                ${flow_badge}
  ${_C_CYAN}teach prompt${_C_NC}                AI prompt management        ${flow_badge}
  ${_C_CYAN}teach style${_C_NC}                 Teaching style              ${flow_badge}

${_C_BLUE} CONTENT GENERATION${_C_NC}                              ${scholar_badge}
  ${sc}teach lecture${_C_NC} <topic>     Lecture notes
  ${sc}teach slides${_C_NC} <topic>      Presentation slides
  ${sc}teach exam${_C_NC} <topic>        Comprehensive exam
  ${sc}teach quiz${_C_NC} <topic>        Quiz questions
  ${sc}teach assignment${_C_NC} <topic>  Homework assignment
  ${sc}teach syllabus${_C_NC} <course>   Course syllabus
  ${sc}teach rubric${_C_NC} <assign>     Grading rubric
  ${sc}teach feedback${_C_NC} <work>     Student feedback
  ${sc}teach demo${_C_NC}               Demo course

${_C_BLUE} VALIDATION & QUALITY${_C_NC}
  ${_C_CYAN}teach validate${_C_NC} [files]      Validate .qmd files         ${flow_badge}
  ${_C_CYAN}teach analyze${_C_NC} <file>        Concept prerequisites       ${flow_badge}
  ${_C_CYAN}teach profiles${_C_NC}              Profile management          ${flow_badge}
  ${_C_CYAN}teach cache${_C_NC}                 Cache operations            ${flow_badge}
  ${_C_CYAN}teach clean${_C_NC}                 Delete _freeze/ + _site/    ${flow_badge}
  ${crc}/scholar:teaching:validate${_C_NC}  Schema validation           ${scholar_badge}
  ${crc}/craft:site:check${_C_NC}           Content + link check        ${craft_badge}

${_C_BLUE} DEPLOYMENT${_C_NC}
  ${_C_CYAN}teach deploy${_C_NC} [--preview]    Deploy course site          ${flow_badge}
  ${crc}/craft:site:publish${_C_NC}         Full publish workflow       ${craft_badge}
  ${crc}/craft:site:build${_C_NC}           Build site locally          ${craft_badge}
  ${crc}/craft:site:deploy${_C_NC}          Deploy to GitHub Pages      ${craft_badge}

${_C_BLUE} SEMESTER TRACKING${_C_NC}
  ${_C_CYAN}teach status${_C_NC}                Project dashboard           ${flow_badge}
  ${_C_CYAN}teach week${_C_NC}                  Current week info           ${flow_badge}
  ${_C_CYAN}teach backup${_C_NC}                Backup management           ${flow_badge}
  ${_C_CYAN}teach archive${_C_NC}               Archive semester            ${flow_badge}
  ${crc}/craft:site:progress${_C_NC}        Semester progress           ${craft_badge}

${_C_DIM} Slash commands (/craft:*, /scholar:*) run inside Claude Code${_C_NC}
${_C_DIM} For usage details: teach <command> --help${_C_NC}
"
}


