#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# V / VIBE - Workflow Automation Dispatcher
# ══════════════════════════════════════════════════════════════════════════════
#
# File:         ~/.config/zsh/functions/v-dispatcher.zsh
# Version:      1.0
# Date:         2025-12-15
# Part of:      Option B+ Multi-Editor Quadrant System
#
# Usage:        v <category> <keyword> [options]
#               vibe <category> <keyword> [options]
#
# Categories:
#   - test      Testing workflows (context-aware)
#   - coord     Ecosystem coordination
#   - plan      Sprint planning
#   - log       Activity logging (alias to workflow)
#   - (direct)  Direct commands (dash, status, health)
#
# Examples:
#   v test              # Run tests (context-aware)
#   v test watch        # Watch mode
#   v coord sync eco    # Sync ecosystem
#   v plan sprint       # Sprint management
#   v log               # Activity log (→ workflow)
#   v help              # Full help
#
# Full name:
#   vibe test           # Same as `v test`
#   vibe coord sync     # Same as `v coord sync`
#
# ══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════
# SOURCE UTILITIES
# ═══════════════════════════════════════════════════════════════════

# Source v-utils.zsh for shared helper functions
if [[ -f ~/.config/zsh/functions/v-utils.zsh ]]; then
    source ~/.config/zsh/functions/v-utils.zsh
fi

# ═══════════════════════════════════════════════════════════════════
# COLOR DEFINITIONS (matching smart-dispatchers.zsh)
# ═══════════════════════════════════════════════════════════════════

# Check if colors are already defined, if not define them
if [[ -z "$_C_BOLD" ]]; then
    _C_BOLD='\033[1m'
    _C_DIM='\033[2m'
    _C_NC='\033[0m'
    _C_RED='\033[31m'
    _C_GREEN='\033[32m'
    _C_YELLOW='\033[33m'
    _C_BLUE='\033[34m'
    _C_MAGENTA='\033[35m'
    _C_CYAN='\033[36m'
fi

# ═══════════════════════════════════════════════════════════════════
# MAIN V() DISPATCHER
# ═══════════════════════════════════════════════════════════════════

v() {
    # No arguments → show help hint
    if [[ $# -eq 0 ]]; then
        echo -e "${_C_BOLD}v / vibe${_C_NC} - Workflow Automation"
        echo ""
        echo "Try:"
        echo "  ${_C_CYAN}v test${_C_NC}          Run tests"
        echo "  ${_C_CYAN}v coord${_C_NC}         Show ecosystems"
        echo "  ${_C_CYAN}v plan${_C_NC}          Show current sprint"
        echo "  ${_C_CYAN}v help${_C_NC}          Full help"
        echo ""
        echo "Or use full name: ${_C_DIM}vibe test${_C_NC}"
        return 0
    fi

    case "$1" in
        # ─────────────────────────────────────────────────────────────
        # TESTING WORKFLOWS
        # ─────────────────────────────────────────────────────────────
        test|t)
            shift
            _v_test "$@"
            ;;

        # ─────────────────────────────────────────────────────────────
        # COORDINATION
        # ─────────────────────────────────────────────────────────────
        coord|c)
            shift
            _v_coord "$@"
            ;;

        # ─────────────────────────────────────────────────────────────
        # PLANNING
        # ─────────────────────────────────────────────────────────────
        plan|p)
            shift
            _v_plan "$@"
            ;;

        # ─────────────────────────────────────────────────────────────
        # ACTIVITY LOGGING (alias to workflow)
        # ─────────────────────────────────────────────────────────────
        log|l)
            shift
            # Delegate to existing workflow command
            if command -v workflow &>/dev/null; then
                workflow "$@"
            else
                echo "${_C_RED}Error:${_C_NC} workflow command not found"
                return 1
            fi
            ;;

        # ─────────────────────────────────────────────────────────────
        # DIRECT ALIASES
        # ─────────────────────────────────────────────────────────────
        dash|d)
            # Alias to existing dash command
            if command -v dash &>/dev/null; then
                dash
            else
                echo "${_C_RED}Error:${_C_NC} dash command not found"
                return 1
            fi
            ;;

        status|s)
            shift
            # Alias to existing status command
            if command -v status &>/dev/null; then
                status "$@"
            else
                echo "${_C_RED}Error:${_C_NC} status command not found"
                return 1
            fi
            ;;

        health)
            _v_health
            ;;

        # ─────────────────────────────────────────────────────────────
        # HELP
        # ─────────────────────────────────────────────────────────────
        help|h|--help|-h)
            _v_help
            ;;

        *)
            echo "${_C_RED}Unknown action:${_C_NC} $1"
            echo "Run: ${_C_CYAN}v help${_C_NC}"
            return 1
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════
# VIBE() - FULL NAME ALIAS
# ═══════════════════════════════════════════════════════════════════

vibe() {
    v "$@"
}

# ═══════════════════════════════════════════════════════════════════
# HELP SYSTEM
# ═══════════════════════════════════════════════════════════════════

_v_help() {
    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ v / vibe - Workflow Automation              │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}v test${_C_NC}           Run tests (auto-detect)
  ${_C_CYAN}v dash${_C_NC}           Dashboard view
  ${_C_CYAN}v status${_C_NC}         Project status

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} v test                  ${_C_DIM}# Run tests${_C_NC}
  ${_C_DIM}\$${_C_NC} v test watch            ${_C_DIM}# Watch mode${_C_NC}
  ${_C_DIM}\$${_C_NC} v coord sync eco        ${_C_DIM}# Sync ecosystem${_C_NC}
  ${_C_DIM}\$${_C_NC} vibe test               ${_C_DIM}# Full name works too${_C_NC}

${_C_BLUE}📋 TESTING${_C_NC}:
  ${_C_CYAN}v test${_C_NC}           Run tests
  ${_C_CYAN}v test watch${_C_NC}     Watch mode
  ${_C_CYAN}v test cov${_C_NC}       Coverage report
  ${_C_CYAN}v test scaffold${_C_NC}  Generate test template
  ${_C_CYAN}v test file${_C_NC}      Run specific test file
  ${_C_CYAN}v test docs${_C_NC}      Generate test documentation

${_C_BLUE}🔗 COORDINATION${_C_NC}:
  ${_C_CYAN}v coord${_C_NC}          Show ecosystems
  ${_C_CYAN}v coord sync${_C_NC}     Sync ecosystem
  ${_C_CYAN}v coord status${_C_NC}   Ecosystem dashboard
  ${_C_CYAN}v coord deps${_C_NC}     Dependency graph
  ${_C_CYAN}v coord release${_C_NC}  Coordinate release

${_C_BLUE}📅 PLANNING${_C_NC}:
  ${_C_CYAN}v plan${_C_NC}           Current sprint
  ${_C_CYAN}v plan sprint${_C_NC}    Sprint management
  ${_C_CYAN}v plan roadmap${_C_NC}   View roadmap
  ${_C_CYAN}v plan add${_C_NC}       Add task
  ${_C_CYAN}v plan backlog${_C_NC}   View backlog

${_C_BLUE}📝 ACTIVITY LOGGING${_C_NC} ${_C_DIM}(alias to workflow)${_C_NC}:
  ${_C_CYAN}v log${_C_NC}            Recent activity (→ workflow)
  ${_C_CYAN}v log today${_C_NC}      Today's log (→ workflow today)
  ${_C_CYAN}v log started${_C_NC}    Log session start (→ workflow started)

${_C_BLUE}🎯 DIRECT COMMANDS${_C_NC}:
  ${_C_CYAN}v dash${_C_NC}           Dashboard (→ dash)
  ${_C_CYAN}v status${_C_NC}         Project status (→ status)
  ${_C_CYAN}v health${_C_NC}         Combined health check

${_C_MAGENTA}💡 TIP${_C_NC}: Use \"vibe\" for full command name
  ${_C_DIM}vibe test        Same as \`v test\`${_C_NC}
  ${_C_DIM}vibe coord sync  Same as \`v coord sync\`${_C_NC}

${_C_MAGENTA}🔗 EXISTING COMMANDS${_C_NC} ${_C_DIM}(still work)${_C_NC}:
  ${_C_DIM}workflow, dash, status, work, r, qu, cc${_C_NC}
"
}

# ═══════════════════════════════════════════════════════════════════
# TEST WORKFLOWS
# ═══════════════════════════════════════════════════════════════════

_v_test() {
    # No arguments → run tests (context-aware)
    if [[ $# -eq 0 ]]; then
        _v_test_run
        return $?
    fi

    case "$1" in
        watch|w)
            shift
            _v_test_watch "$@"
            ;;

        cov|coverage|c)
            shift
            _v_test_coverage "$@"
            ;;

        scaffold|s)
            shift
            _v_test_scaffold "$@"
            ;;

        file|f)
            shift
            _v_test_file "$@"
            ;;

        docs|d)
            shift
            _v_test_docs "$@"
            ;;

        help|h)
            _v_test_help
            ;;

        *)
            echo "${_C_RED}Unknown test action:${_C_NC} $1"
            echo "Run: ${_C_CYAN}v test help${_C_NC}"
            return 1
            ;;
    esac
}

_v_test_run() {
    echo "${_C_CYAN}Running tests...${_C_NC}"
    echo ""

    # Delegate to existing pt command if available
    if command -v pt &>/dev/null; then
        pt
    else
        echo "${_C_YELLOW}Note:${_C_NC} pt command not found. Implement context-aware test detection."
        return 1
    fi
}

_v_test_watch() {
    echo "${_C_CYAN}Starting test watch mode...${_C_NC}"
    echo "${_C_DIM}(Implementation coming soon)${_C_NC}"
    # TODO: Implement watch mode
}

_v_test_coverage() {
    echo "${_C_CYAN}Running tests with coverage...${_C_NC}"
    echo "${_C_DIM}(Implementation coming soon)${_C_NC}"
    # TODO: Implement coverage
}

_v_test_scaffold() {
    echo "${_C_CYAN}Generating test template...${_C_NC}"
    echo "${_C_DIM}(Implementation coming soon)${_C_NC}"
    # TODO: Implement scaffold
}

_v_test_file() {
    local file="$1"
    if [[ -z "$file" ]]; then
        echo "${_C_RED}Error:${_C_NC} No file specified"
        echo "Usage: ${_C_CYAN}v test file <path>${_C_NC}"
        return 1
    fi

    echo "${_C_CYAN}Running tests for: ${_C_NC}$file"
    echo "${_C_DIM}(Implementation coming soon)${_C_NC}"
    # TODO: Implement file-specific tests
}

_v_test_docs() {
    echo "${_C_CYAN}Generating test documentation...${_C_NC}"
    echo "${_C_DIM}(Implementation coming soon)${_C_NC}"
    # TODO: Implement test documentation generation
}

_v_test_help() {
    echo -e "
${_C_BOLD}v test - Testing Workflows${_C_NC}

${_C_GREEN}Usage:${_C_NC}
  ${_C_CYAN}v test${_C_NC}           Run tests (auto-detect framework)
  ${_C_CYAN}v test watch${_C_NC}     Watch mode
  ${_C_CYAN}v test cov${_C_NC}       Coverage report
  ${_C_CYAN}v test scaffold${_C_NC}  Generate test template
  ${_C_CYAN}v test file <path>${_C_NC}  Run specific test file
  ${_C_CYAN}v test docs${_C_NC}      Generate test documentation
"
}

# ═══════════════════════════════════════════════════════════════════
# COORDINATION (placeholders)
# ═══════════════════════════════════════════════════════════════════

_v_coord() {
    echo "${_C_CYAN}Coordination workflows${_C_NC}"
    echo "${_C_DIM}(Implementation coming in Phase 3)${_C_NC}"
    # TODO: Implement coordination workflows
}

# ═══════════════════════════════════════════════════════════════════
# PLANNING (placeholders)
# ═══════════════════════════════════════════════════════════════════

_v_plan() {
    echo "${_C_CYAN}Planning workflows${_C_NC}"
    echo "${_C_DIM}(Implementation coming in Phase 4)${_C_NC}"
    # TODO: Implement planning workflows
}

# ═══════════════════════════════════════════════════════════════════
# HEALTH CHECK
# ═══════════════════════════════════════════════════════════════════

_v_health() {
    echo "${_C_CYAN}System health check${_C_NC}"
    echo "${_C_DIM}(Implementation coming in Phase 5)${_C_NC}"
    # TODO: Implement health check
}
