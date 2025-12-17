#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# DASH - Master Dashboard
# ══════════════════════════════════════════════════════════════════════════════
#
# File:         ~/.config/zsh/functions/dash.zsh
# Version:      1.0
# Date:         2025-12-14
# Purpose:      Unified view of all active work across projects
#
# Usage:        dash [category]
# Examples:     dash, dash teaching, dash research, dash packages
#
# ══════════════════════════════════════════════════════════════════════════════

emulate -L zsh

# ═══════════════════════════════════════════════════════════════════
# MAIN DASHBOARD COMMAND
# ═══════════════════════════════════════════════════════════════════

dash() {
    local category="${1:-all}"
    local filter_path=""

    # Color setup
    local GREEN='\033[0;32m'
    local CYAN='\033[0;36m'
    local YELLOW='\033[1;33m'
    local MAGENTA='\033[0;35m'
    local RED='\033[0;31m'
    local BLUE='\033[0;34m'
    local BOLD='\033[1m'
    local DIM='\033[2m'
    local NC='\033[0m'

    # Determine filter path based on category
    case "$category" in
        teaching|teach)
            filter_path="$HOME/projects/teaching"
            category="teaching"
            ;;
        research|res)
            filter_path="$HOME/projects/research"
            category="research"
            ;;
        packages|pkg|r)
            filter_path="$HOME/projects/r-packages"
            category="R packages"
            ;;
        dev|tools)
            filter_path="$HOME/projects/dev-tools"
            category="dev-tools"
            ;;
        quarto|qmd)
            filter_path="$HOME/projects/quarto"
            category="quarto"
            ;;
        all|"")
            filter_path="$HOME/projects"
            category="all"
            ;;
        --help|-h)
            _dash_help
            return 0
            ;;
        *)
            echo "${RED}❌ Unknown category: $category${NC}"
            echo ""
            echo "Available categories:"
            echo "  ${CYAN}all${NC}       - All projects (default)"
            echo "  ${CYAN}teaching${NC}  - Teaching courses"
            echo "  ${CYAN}research${NC}  - Research projects"
            echo "  ${CYAN}packages${NC}  - R packages"
            echo "  ${CYAN}dev${NC}       - Dev tools"
            echo "  ${CYAN}quarto${NC}    - Quarto projects"
            return 1
            ;;
    esac

    # Header
    echo ""
    echo -e "${BOLD}╭─────────────────────────────────────────────╮${NC}"
    if [[ "$category" == "all" ]]; then
        echo -e "${BOLD}│ 🎯 YOUR WORK DASHBOARD                      │${NC}"
    else
        printf "${BOLD}│ 🎯 %-40s │${NC}\n" "$(echo $category | tr '[:lower:]' '[:upper:]') DASHBOARD"
    fi
    echo -e "${BOLD}╰─────────────────────────────────────────────╯${NC}"
    echo ""

    # Find and categorize projects
    local -a active_projects=()
    local -a ready_projects=()
    local -a paused_projects=()
    local -a blocked_projects=()

    # Scan all .STATUS files
    for status_file in $(find "$filter_path" -name ".STATUS" -type f 2>/dev/null | sort); do
        if [[ ! -f "$status_file" ]]; then
            continue
        fi

        local dir=$(dirname "$status_file")
        local name=$(basename "$dir")
        local status=$(grep -i "^status:" "$status_file" 2>/dev/null | cut -d: -f2- | sed 's/^[[:space:]]*//' | tr '[:upper:]' '[:lower:]')
        local priority=$(grep -i "^priority:" "$status_file" 2>/dev/null | cut -d: -f2- | sed 's/^[[:space:]]*//')
        local progress=$(grep -i "^progress:" "$status_file" 2>/dev/null | cut -d: -f2- | sed 's/^[[:space:]]*//')
        local next=$(grep -i "^next:" "$status_file" 2>/dev/null | cut -d: -f2- | sed 's/^[[:space:]]*//')
        local project_type=$(grep -i "^type:" "$status_file" 2>/dev/null | cut -d: -f2- | sed 's/^[[:space:]]*//')

        # Default values
        [[ -z "$status" ]] && status="unknown"
        [[ -z "$priority" ]] && priority="--"
        [[ -z "$progress" ]] && progress="--"
        [[ -z "$next" ]] && next="No next action defined"
        [[ -z "$project_type" ]] && project_type="project"

        # Get icon based on type
        local icon="📦"
        case "$project_type" in
            *package*|rpkg) icon="📦" ;;
            *teach*|course) icon="📚" ;;
            *research*|manuscript) icon="📊" ;;
            *quarto*|website) icon="📝" ;;
            *dev*|tool) icon="🔧" ;;
            *obsidian*) icon="📓" ;;
        esac

        # Categorize by status
        local entry="${icon} ${name}|${priority}|${progress}|${next}"

        case "$status" in
            active|working|in*progress)
                active_projects+=("$entry")
                ;;
            ready|todo|planned)
                ready_projects+=("$entry")
                ;;
            paused|hold|waiting)
                paused_projects+=("$entry")
                ;;
            blocked)
                blocked_projects+=("$entry")
                ;;
        esac
    done

    # Display active projects
    if [[ ${#active_projects[@]} -gt 0 ]]; then
        echo -e "${GREEN}🔥 ACTIVE NOW${NC} ${DIM}(${#active_projects[@]})${NC}:"
        for project in "${active_projects[@]}"; do
            local name=$(echo "$project" | cut -d'|' -f1)
            local priority=$(echo "$project" | cut -d'|' -f2)
            local progress=$(echo "$project" | cut -d'|' -f3)
            local next=$(echo "$project" | cut -d'|' -f4)

            # Priority color
            local pri_color="$NC"
            case "$priority" in
                P0) pri_color="$RED" ;;
                P1) pri_color="$YELLOW" ;;
                P2) pri_color="$BLUE" ;;
            esac

            echo -e "  ${name} ${pri_color}[$priority]${NC} ${DIM}$progress%${NC} - $next"
        done
        echo ""
    fi

    # Display ready projects
    if [[ ${#ready_projects[@]} -gt 0 ]]; then
        echo -e "${CYAN}📋 READY TO START${NC} ${DIM}(${#ready_projects[@]})${NC}:"
        for project in "${ready_projects[@]}"; do
            local name=$(echo "$project" | cut -d'|' -f1)
            local priority=$(echo "$project" | cut -d'|' -f2)
            local next=$(echo "$project" | cut -d'|' -f4)

            local pri_color="$NC"
            case "$priority" in
                P0) pri_color="$RED" ;;
                P1) pri_color="$YELLOW" ;;
                P2) pri_color="$BLUE" ;;
            esac

            echo -e "  ${name} ${pri_color}[$priority]${NC} - $next"
        done
        echo ""
    fi

    # Display paused projects
    if [[ ${#paused_projects[@]} -gt 0 ]]; then
        echo -e "${YELLOW}⏸️  PAUSED${NC} ${DIM}(${#paused_projects[@]})${NC}:"
        for project in "${paused_projects[@]}"; do
            local name=$(echo "$project" | cut -d'|' -f1)
            local next=$(echo "$project" | cut -d'|' -f4)
            echo -e "  ${name} ${DIM}- $next${NC}"
        done
        echo ""
    fi

    # Display blocked projects
    if [[ ${#blocked_projects[@]} -gt 0 ]]; then
        echo -e "${RED}🚫 BLOCKED${NC} ${DIM}(${#blocked_projects[@]})${NC}:"
        for project in "${blocked_projects[@]}"; do
            local name=$(echo "$project" | cut -d'|' -f1)
            local next=$(echo "$project" | cut -d'|' -f4)
            echo -e "  ${name} ${DIM}- $next${NC}"
        done
        echo ""
    fi

    # Summary
    local total=$((${#active_projects[@]} + ${#ready_projects[@]} + ${#paused_projects[@]} + ${#blocked_projects[@]}))

    if [[ $total -eq 0 ]]; then
        echo -e "${DIM}No projects found with .STATUS files${NC}"
        echo ""
        echo -e "${YELLOW}💡 Tip:${NC} Create .STATUS files with:"
        echo -e "   ${CYAN}status <project> --create${NC}"
        echo ""
    else
        echo -e "${DIM}────────────────────────────────────────────────${NC}"
        echo ""
        echo -e "${MAGENTA}💡 Quick actions:${NC}"
        echo -e "   ${CYAN}work <name>${NC}         Start working on a project"
        echo -e "   ${CYAN}status <name>${NC}       Update project status"
        if [[ "$category" == "all" ]]; then
            echo -e "   ${CYAN}dash teaching${NC}      Filter by category"
        else
            echo -e "   ${CYAN}dash${NC}               Show all projects"
        fi
        echo ""
    fi
}

# ═══════════════════════════════════════════════════════════════════
# HELP
# ═══════════════════════════════════════════════════════════════════

_dash_help() {
    local GREEN='\033[0;32m'
    local CYAN='\033[0;36m'
    local YELLOW='\033[1;33m'
    local MAGENTA='\033[0;35m'
    local BOLD='\033[1m'
    local DIM='\033[2m'
    local NC='\033[0m'

    echo ""
    echo -e "${BOLD}╭─────────────────────────────────────────────╮${NC}"
    echo -e "${BOLD}│ dash - Master Dashboard                     │${NC}"
    echo -e "${BOLD}╰─────────────────────────────────────────────╯${NC}"
    echo ""
    echo -e "${GREEN}🔥 USAGE${NC}:"
    echo -e "  ${CYAN}dash${NC}              Show all projects"
    echo -e "  ${CYAN}dash teaching${NC}     Teaching projects only"
    echo -e "  ${CYAN}dash research${NC}     Research projects only"
    echo -e "  ${CYAN}dash packages${NC}     R packages only"
    echo -e "  ${CYAN}dash dev${NC}          Dev tools only"
    echo -e "  ${CYAN}dash quarto${NC}       Quarto projects only"
    echo ""
    echo -e "${YELLOW}💡 CATEGORIES${NC}:"
    echo -e "  ${DIM}all${NC}       - All projects (default)"
    echo -e "  ${DIM}teaching${NC}  - ~/projects/teaching"
    echo -e "  ${DIM}research${NC}  - ~/projects/research"
    echo -e "  ${DIM}packages${NC}  - ~/projects/r-packages"
    echo -e "  ${DIM}dev${NC}       - ~/projects/dev-tools"
    echo -e "  ${DIM}quarto${NC}    - ~/projects/quarto"
    echo ""
    echo -e "${MAGENTA}📋 WHAT IT SHOWS${NC}:"
    echo -e "  • ${GREEN}Active${NC} projects (currently working)"
    echo -e "  • ${CYAN}Ready${NC} projects (planned)"
    echo -e "  • ${YELLOW}Paused${NC} projects (on hold)"
    echo -e "  • ${DIM}Blocked${NC} projects (waiting)"
    echo ""
    echo -e "${MAGENTA}🔗 RELATED COMMANDS${NC}:"
    echo -e "  ${CYAN}work <name>${NC}       Start working on a project"
    echo -e "  ${CYAN}status <name>${NC}     Update project status"
    echo -e "  ${CYAN}js${NC}                Just start (picks for you)"
    echo ""
}
