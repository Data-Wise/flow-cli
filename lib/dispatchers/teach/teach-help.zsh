# teach-help.zsh - Extracted from teach-dispatcher.zsh
# ============================================================================

_teach_validate_help() {
    if [[ -z "$_C_BOLD" ]]; then
        _C_BOLD='\033[1m'; _C_DIM='\033[2m'; _C_NC='\033[0m'
        _C_GREEN='\033[32m'; _C_YELLOW='\033[33m'; _C_BLUE='\033[34m'
        _C_MAGENTA='\033[35m'; _C_CYAN='\033[36m'
    fi

    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ teach validate - Validate Quarto Files       │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}teach validate --yaml${_C_NC}       Quick YAML frontmatter check
  ${_C_CYAN}teach validate --render${_C_NC}     Full render validation
  ${_C_CYAN}teach validate --watch${_C_NC}      Watch mode (auto-revalidate)
  ${_C_DIM}Alias: teach val${_C_NC}

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} teach validate --yaml lectures/week-05/  ${_C_DIM}# Quick YAML check${_C_NC}
  ${_C_DIM}\$${_C_NC} teach validate --render                   ${_C_DIM}# Full render${_C_NC}
  ${_C_DIM}\$${_C_NC} teach validate --deep                     ${_C_DIM}# Deep + concepts${_C_NC}
  ${_C_DIM}\$${_C_NC} teach validate --watch                    ${_C_DIM}# Watch for changes${_C_NC}
  ${_C_DIM}\$${_C_NC} teach validate --custom                   ${_C_DIM}# Custom validators${_C_NC}

${_C_BLUE}📋 VALIDATION MODES${_C_NC}:
  ${_C_CYAN}--yaml${_C_NC}             YAML frontmatter only (fast)
  ${_C_CYAN}--syntax${_C_NC}           YAML + syntax check
  ${_C_CYAN}--render${_C_NC}           Full render validation
  ${_C_CYAN}--custom${_C_NC}           Run custom validators
  ${_C_CYAN}--lint${_C_NC}             Quarto-aware lint rules
  ${_C_CYAN}--quick-checks${_C_NC}     Fast lint subset (Phase 1)
  ${_C_CYAN}--deep${_C_NC}             Full validation + concept analysis
  ${_C_CYAN}--concepts${_C_NC}         Concept prerequisite validation only

${_C_BLUE}📋 OPTIONS${_C_NC}:
  ${_C_CYAN}--validators <list>${_C_NC}  Comma-separated list (with --custom)
  ${_C_CYAN}--watch, -w${_C_NC}          Watch mode (fswatch)
  ${_C_CYAN}--stats${_C_NC}              Show validation statistics
  ${_C_CYAN}--quiet, -q${_C_NC}          Minimal output

${_C_BLUE}📋 EXIT CODES${_C_NC}:
  ${_C_GREEN}0${_C_NC} - All valid   ${_C_BOLD}1${_C_NC} - Warnings   ${_C_BOLD}2${_C_NC} - Errors

${_C_MAGENTA}💡 TIP${_C_NC}: Use ${_C_CYAN}--yaml${_C_NC} for fast iteration, ${_C_CYAN}--deep${_C_NC} before deploy.
  ${_C_DIM}Custom validators go in .teach/validators/${_C_NC}

${_C_DIM}📚 See also:${_C_NC}
  ${_C_CYAN}teach doctor${_C_NC} - Health checks
  ${_C_CYAN}teach cache${_C_NC} - Cache management
  ${_C_DIM}Guide: docs/guides/TEACHING-QUARTO-WORKFLOW-GUIDE.md${_C_NC}
"
}

# Help for teach cache command

_teach_cache_help() {
    if [[ -z "$_C_BOLD" ]]; then
        _C_BOLD='\033[1m'; _C_DIM='\033[2m'; _C_NC='\033[0m'
        _C_GREEN='\033[32m'; _C_YELLOW='\033[33m'; _C_BLUE='\033[34m'
        _C_MAGENTA='\033[35m'; _C_CYAN='\033[36m'
    fi

    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ teach cache - Cache Management               │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}teach cache status${_C_NC}       Show cache statistics
  ${_C_CYAN}teach cache clear${_C_NC}        Clear all cache
  ${_C_CYAN}teach cache rebuild${_C_NC}      Rebuild frozen content

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} teach cache status              ${_C_DIM}# Show stats${_C_NC}
  ${_C_DIM}\$${_C_NC} teach cache clear --lectures    ${_C_DIM}# Clear lectures only${_C_NC}
  ${_C_DIM}\$${_C_NC} teach cache rebuild             ${_C_DIM}# Rebuild frozen content${_C_NC}
  ${_C_DIM}\$${_C_NC} teach cache analyze             ${_C_DIM}# Analyze usage${_C_NC}
  ${_C_DIM}\$${_C_NC} teach cache clean --old 7       ${_C_DIM}# Clear entries > 7 days${_C_NC}

${_C_BLUE}📋 COMMANDS${_C_NC}:
  ${_C_CYAN}status${_C_NC}              Show cache statistics
  ${_C_CYAN}clear${_C_NC}               Clear all cache
  ${_C_CYAN}rebuild${_C_NC}             Rebuild frozen content
  ${_C_CYAN}analyze${_C_NC}             Analyze cache usage
  ${_C_CYAN}clean${_C_NC}               Clean stale entries

${_C_BLUE}📋 OPTIONS${_C_NC}:
  ${_C_CYAN}--lectures${_C_NC}          Target lectures only
  ${_C_CYAN}--assignments${_C_NC}       Target assignments only
  ${_C_CYAN}--old [days]${_C_NC}        Clear entries older than N days
  ${_C_CYAN}--unused${_C_NC}            Clear unused cache
  ${_C_CYAN}--json${_C_NC}              JSON output

${_C_MAGENTA}💡 TIP${_C_NC}: Cache is stored in ${_C_CYAN}_freeze/${_C_NC}. Use ${_C_CYAN}status${_C_NC} to diagnose,
  ${_C_DIM}clear before re-rendering from scratch.${_C_NC}

${_C_DIM}📚 See also:${_C_NC}
  ${_C_CYAN}teach clean${_C_NC} - Delete _freeze/ and _site/
  ${_C_CYAN}qu${_C_NC} - Quarto commands
"
}

# Help for teach profiles command

_teach_profiles_help() {
    if [[ -z "$_C_BOLD" ]]; then
        _C_BOLD='\033[1m'; _C_DIM='\033[2m'; _C_NC='\033[0m'
        _C_GREEN='\033[32m'; _C_YELLOW='\033[33m'; _C_BLUE='\033[34m'
        _C_MAGENTA='\033[35m'; _C_CYAN='\033[36m'
    fi

    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ teach profiles - Quarto Profile Management   │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}teach profiles list${_C_NC}          List available profiles
  ${_C_CYAN}teach profiles switch${_C_NC}        Activate a profile
  ${_C_CYAN}teach profiles create${_C_NC}        Create new profile

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} teach profiles list             ${_C_DIM}# List profiles${_C_NC}
  ${_C_DIM}\$${_C_NC} teach profiles switch draft     ${_C_DIM}# Switch to draft${_C_NC}
  ${_C_DIM}\$${_C_NC} teach profiles create my-config ${_C_DIM}# Create custom${_C_NC}

${_C_BLUE}📋 AVAILABLE PROFILES${_C_NC}:
  ${_C_CYAN}default${_C_NC}     Standard web output
  ${_C_CYAN}draft${_C_NC}       Draft mode (faster rendering)
  ${_C_CYAN}print${_C_NC}       Print-optimized
  ${_C_CYAN}slides${_C_NC}      Presentation mode

${_C_MAGENTA}💡 TIP${_C_NC}: Profiles are defined in ${_C_CYAN}_quarto.yml${_C_NC}. Draft renders ~2x faster.
  ${_C_DIM}Quarto profiles are separate from R package profiles.${_C_NC}

${_C_DIM}📚 See also:${_C_NC}
  ${_C_CYAN}qu${_C_NC} - Quarto commands
  ${_C_CYAN}teach cache${_C_NC} - Cache management
"
}

# Help for teach clean command

_teach_clean_help() {
    if [[ -z "$_C_BOLD" ]]; then
        _C_BOLD='\033[1m'; _C_DIM='\033[2m'; _C_NC='\033[0m'
        _C_GREEN='\033[32m'; _C_YELLOW='\033[33m'; _C_BLUE='\033[34m'
        _C_MAGENTA='\033[35m'; _C_CYAN='\033[36m'
    fi

    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ teach clean - Clean Build Artifacts          │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}teach clean${_C_NC}               Clear all build artifacts
  ${_C_CYAN}teach clean --freeze${_C_NC}      Clear _freeze/ only
  ${_C_CYAN}teach clean --dry-run${_C_NC}     Preview what gets deleted

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} teach clean                  ${_C_DIM}# Clear everything${_C_NC}
  ${_C_DIM}\$${_C_NC} teach clean --freeze         ${_C_DIM}# Clear cache only${_C_NC}
  ${_C_DIM}\$${_C_NC} teach clean --dry-run        ${_C_DIM}# Preview deletions${_C_NC}

${_C_BLUE}📋 OPTIONS${_C_NC}:
  ${_C_CYAN}--freeze${_C_NC}       Clear _freeze/ only (cached render output)
  ${_C_CYAN}--site${_C_NC}         Clear _site/ only (generated website)
  ${_C_CYAN}--all${_C_NC}          Clear everything: _freeze/, _site/, .quarto/ (default)
  ${_C_CYAN}--dry-run${_C_NC}      Show what would be deleted

${_C_YELLOW}WARNING${_C_NC}: This action cannot be undone! Use ${_C_CYAN}--dry-run${_C_NC} first.

${_C_MAGENTA}💡 TIP${_C_NC}: Run ${_C_CYAN}teach clean${_C_NC} before full re-render.
  ${_C_DIM}Use teach cache rebuild for smarter selective clear.${_C_NC}

${_C_DIM}📚 See also:${_C_NC}
  ${_C_CYAN}teach cache${_C_NC} - Selective cache management
  ${_C_CYAN}qu${_C_NC} - Quarto commands
"
}

# ============================================================================
# SCHOLAR WRAPPER INFRASTRUCTURE
# ============================================================================

# Error formatting (consistent with flow-cli style)

_teach_archive_help() {
    if [[ -z "$_C_BOLD" ]]; then
        _C_BOLD='\033[1m'; _C_DIM='\033[2m'; _C_NC='\033[0m'
        _C_GREEN='\033[32m'; _C_YELLOW='\033[33m'; _C_BLUE='\033[34m'
        _C_MAGENTA='\033[35m'; _C_CYAN='\033[36m'
    fi
    echo -e "${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}"
    echo -e "${_C_BOLD}│${_C_NC}  ${_C_CYAN}teach archive${_C_NC} - Archive Semester Backups  ${_C_BOLD}│${_C_NC}"
    echo -e "${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}"
    echo ""
    echo -e "  ${_C_BOLD}USAGE${_C_NC}  teach archive [SEMESTER_NAME]"
    echo ""
    echo -e "  ${_C_BOLD}🔥 MOST COMMON${_C_NC}"
    echo -e "  ${_C_CYAN}teach archive${_C_NC}              Archive current semester"
    echo -e "  ${_C_CYAN}teach archive spring-2026${_C_NC}  Archive specific semester"
    echo ""
    echo -e "  ${_C_BOLD}💡 QUICK EXAMPLES${_C_NC}"
    echo -e "  ${_C_DIM}# Archive current semester${_C_NC}"
    echo -e "  teach archive"
    echo -e "  ${_C_DIM}# Archive specific semester${_C_NC}"
    echo -e "  teach archive spring-2026"
    echo -e "  ${_C_DIM}# Short alias${_C_NC}"
    echo -e "  teach a"
    echo ""
    echo -e "  ${_C_BOLD}📋 RETENTION POLICIES${_C_NC}"
    echo -e "  ${_C_CYAN}archive${_C_NC}    Assessments, syllabi, rubrics (keep forever)"
    echo -e "  ${_C_CYAN}semester${_C_NC}   Lectures & slides (delete at semester end)"
    echo -e "  ${_C_DIM}Archived backups → .flow/archives/<semester>/${_C_NC}"
    echo -e "  ${_C_DIM}Configure in .flow/teach-config.yml${_C_NC}"
    echo ""
    echo -e "  ${_C_BOLD}💡 TIP${_C_NC}  Run at end of semester to auto-sort by retention policy"
    echo ""
    echo -e "  ${_C_BOLD}📚 See also${_C_NC}"
    echo -e "  ${_C_CYAN}teach backup${_C_NC} - Backup management"
    echo -e "  ${_C_CYAN}teach clean${_C_NC} - Clean build artifacts"
}

# Help for teach status command (v5.14.0 - Task 3, upgraded to box style)

_teach_status_help() {
    if [[ -z "$_C_BOLD" ]]; then
        _C_BOLD='\033[1m'; _C_DIM='\033[2m'; _C_NC='\033[0m'
        _C_GREEN='\033[32m'; _C_YELLOW='\033[33m'; _C_BLUE='\033[34m'
        _C_MAGENTA='\033[35m'; _C_CYAN='\033[36m'
    fi
    echo -e "${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}"
    echo -e "${_C_BOLD}│${_C_NC}  ${_C_CYAN}teach status${_C_NC} - Teaching Project Status    ${_C_BOLD}│${_C_NC}"
    echo -e "${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}"
    echo ""
    echo -e "  ${_C_BOLD}USAGE${_C_NC}  teach status [options]"
    echo -e "  ${_C_BOLD}ALIAS${_C_NC}  ${_C_CYAN}s${_C_NC} → status"
    echo ""
    echo -e "  ${_C_BOLD}🔥 MOST COMMON${_C_NC}"
    echo -e "  ${_C_CYAN}teach status${_C_NC}                Show project overview"
    echo -e "  ${_C_CYAN}teach status --performance${_C_NC}  Performance dashboard"
    echo -e "  ${_C_CYAN}teach s${_C_NC}                     Short alias"
    echo ""
    echo -e "  ${_C_BOLD}💡 QUICK EXAMPLES${_C_NC}"
    echo -e "  ${_C_DIM}# Show full project status${_C_NC}"
    echo -e "  teach status"
    echo -e "  ${_C_DIM}# Performance dashboard${_C_NC}"
    echo -e "  teach status --performance"
    echo -e "  ${_C_DIM}# JSON output for CI${_C_NC}"
    echo -e "  teach status --json"
    echo ""
    echo -e "  ${_C_BOLD}📋 OPTIONS${_C_NC}"
    echo -e "  ${_C_CYAN}--performance${_C_NC}   Render times, cache hit rates, trend graphs"
    echo -e "  ${_C_CYAN}--full${_C_NC}          Detailed status view (legacy)"
    echo -e "  ${_C_CYAN}--json${_C_NC}          JSON output for scripting"
    echo ""
    echo -e "  ${_C_BOLD}📋 STATUS INCLUDES${_C_NC}"
    echo -e "  Course info, git status, config validation,"
    echo -e "  content inventory, deploy status, backup summary"
    echo ""
    echo -e "  ${_C_BOLD}💡 TIP${_C_NC}  Use ${_C_CYAN}--performance${_C_NC} to track render times;"
    echo -e "         add ${_C_CYAN}--json${_C_NC} for CI pipelines"
    echo ""
    echo -e "  ${_C_BOLD}📚 See also${_C_NC}"
    echo -e "  ${_C_CYAN}teach doctor${_C_NC} - Health checks"
    echo -e "  ${_C_CYAN}teach backup${_C_NC} - Backup management"
    echo -e "  ${_C_DIM}docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md${_C_NC}"
}

# Help for teach week command (v5.14.0 - Task 3, upgraded to box style)

_teach_week_help() {
    if [[ -z "$_C_BOLD" ]]; then
        _C_BOLD='\033[1m'; _C_DIM='\033[2m'; _C_NC='\033[0m'
        _C_GREEN='\033[32m'; _C_YELLOW='\033[33m'; _C_BLUE='\033[34m'
        _C_MAGENTA='\033[35m'; _C_CYAN='\033[36m'
    fi
    echo -e "${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}"
    echo -e "${_C_BOLD}│${_C_NC}  ${_C_CYAN}teach week${_C_NC} - Current Week Information     ${_C_BOLD}│${_C_NC}"
    echo -e "${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}"
    echo ""
    echo -e "  ${_C_BOLD}USAGE${_C_NC}  teach week [WEEK_NUMBER]"
    echo -e "  ${_C_BOLD}ALIAS${_C_NC}  ${_C_CYAN}w${_C_NC} → week"
    echo ""
    echo -e "  ${_C_BOLD}🔥 MOST COMMON${_C_NC}"
    echo -e "  ${_C_CYAN}teach week${_C_NC}       Show current week info"
    echo -e "  ${_C_CYAN}teach week 8${_C_NC}     Show specific week"
    echo -e "  ${_C_CYAN}teach w${_C_NC}          Short alias"
    echo ""
    echo -e "  ${_C_BOLD}💡 QUICK EXAMPLES${_C_NC}"
    echo -e "  ${_C_DIM}# Show current week${_C_NC}"
    echo -e "  teach week"
    echo -e "  ${_C_DIM}# Show week 8 info${_C_NC}"
    echo -e "  teach week 8"
    echo -e "  ${_C_DIM}# Extract from syllabus${_C_NC}"
    echo -e "  teach week --syllabus"
    echo ""
    echo -e "  ${_C_BOLD}📋 OPTIONS${_C_NC}"
    echo -e "  ${_C_CYAN}--current, -c${_C_NC}    Show current week (default)"
    echo -e "  ${_C_CYAN}--syllabus, -s${_C_NC}   Extract from syllabus dates"
    echo -e "  ${_C_CYAN}--json${_C_NC}           JSON output for scripting"
    echo ""
    echo -e "  ${_C_BOLD}💡 TIP${_C_NC}  Configure semester dates in ${_C_CYAN}.flow/teach-config.yml${_C_NC}"
    echo -e "         and lesson plans in ${_C_CYAN}.flow/lesson-plans/${_C_NC}"
    echo ""
    echo -e "  ${_C_BOLD}📚 See also${_C_NC}"
    echo -e "  ${_C_CYAN}teach status${_C_NC} - Full project status"
    echo -e "  ${_C_CYAN}teach dates${_C_NC} - Date management"
}

# Help for Scholar commands

_teach_scholar_help() {
    local cmd="$1"

    # Universal flags section (applies to all Scholar commands)
    _show_universal_flags() {
        echo ""
        echo "${FLOW_COLORS[bold]}Universal Flags (v5.13.0+):${FLOW_COLORS[reset]}"
        echo ""
        echo "${FLOW_COLORS[info]}Topic Selection:${FLOW_COLORS[reset]}"
        echo "  --topic TOPIC, -t    Explicit topic (bypasses lesson plan)"
        echo "  --week N, -w         Week number (uses lesson plan if exists)"
        echo ""
        echo "${FLOW_COLORS[info]}Content Style Presets:${FLOW_COLORS[reset]}"
        echo "  --style conceptual       Explanation + definitions + examples"
        echo "  --style computational    Explanation + examples + code + practice"
        echo "  --style rigorous         Definitions + explanation + math + proof"
        echo "  --style applied          Explanation + examples + code + practice"
        echo ""
        echo "${FLOW_COLORS[info]}Content Customization:${FLOW_COLORS[reset]}"
        echo "  --explanation, -e        Include conceptual explanations"
        echo "  --definitions            Include formal definitions"
        echo "  --proof                  Include mathematical proofs"
        echo "  --math, -m               Include mathematical notation"
        echo "  --examples, -x           Include numerical examples"
        echo "  --code, -c               Include code snippets"
        echo "  --diagrams, -d           Include diagrams/visualizations"
        echo "  --practice-problems, -p  Include practice problems"
        echo "  --references, -r         Include citations/references"
        echo ""
        echo "${FLOW_COLORS[dim]}  Negation: --no-explanation, --no-proof, etc.${FLOW_COLORS[reset]}"
        echo ""
        echo "${FLOW_COLORS[info]}Workflow Modes:${FLOW_COLORS[reset]}"
        echo "  --interactive, -i        Interactive wizard (step-by-step)"
        echo "  --revise FILE            Revision workflow (improve existing)"
        echo "  --context                Include course context from materials"
        echo ""
    }

    case "$cmd" in
        lecture)
            echo "teach lecture - Generate lecture content from topic"
            echo ""
            echo "Usage: teach lecture \"Topic\" [options]"
            _show_universal_flags
            echo "${FLOW_COLORS[info]}Lecture-Specific Options:${FLOW_COLORS[reset]}"
            echo "  --outline         Generate outline only (no full content)"
            echo "  --notes           Include speaker notes"
            echo "  --from-plan WEEK  Generate from lesson plan file"
            echo "  --format FORMAT   Output format (quarto, markdown)"
            echo "  --dry-run         Preview without saving"
            echo ""
            echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
            echo "  teach lecture \"Linear Regression\"              # Basic lecture"
            echo "  teach lecture \"ANOVA\" --week 8                 # From lesson plan week 8"
            echo "  teach lecture \"PCA\" --style computational      # Code-heavy style"
            echo "  teach lecture \"Hypothesis Testing\" --notes     # Include speaker notes"
            echo ""
            echo "${FLOW_COLORS[dim]}Note: /teaching:lecture awaiting Scholar implementation${FLOW_COLORS[reset]}"
            ;;
        slides)
            echo "teach slides - Generate presentation slides"
            echo ""
            echo "Usage: teach slides \"Topic\" [options]"
            echo "       teach slides --week N [options]      # Convert lecture to slides"
            echo "       teach slides --from-lecture FILE     # Convert specific file"
            _show_universal_flags
            echo "${FLOW_COLORS[info]}Slides-Specific Options:${FLOW_COLORS[reset]}"
            echo "  --theme NAME         Slide theme (default, academic, minimal)"
            echo "  --from-lecture FILE  Convert lecture .qmd to slides (preserves R code)"
            echo "  --week N, -w N       Auto-detect lecture file(s) from config"
            echo "  --format FORMAT      Output format (quarto, markdown)"
            echo "  --dry-run            Preview content analysis without generating"
            echo "  --verbose, -v        Show detailed progress"
            echo ""
            echo "${FLOW_COLORS[bold]}LECTURE CONVERSION (v5.15.0+)${FLOW_COLORS[reset]}"
            echo "  Converts existing lecture .qmd files to RevealJS slides."
            echo "  Preserves R code chunks, callouts, columns, and examples."
            echo "  Multi-part weeks (defined in teach-config.yml) generate separate slides."
            echo ""
            echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
            echo "  teach slides --week 1                     # Convert Week 1 lecture(s)"
            echo "  teach slides --week 1 --dry-run           # Preview what would be generated"
            echo "  teach slides --from-lecture lectures/week-01_intro.qmd  # Specific file"
            echo "  teach slides \"Multiple Regression\"        # Generate from topic (Scholar)"
            echo "  teach slides \"GLMs\" --theme minimal       # With theme"
            ;;
        exam)
            echo "teach exam - Generate exam questions"
            echo ""
            echo "Usage: teach exam \"Topic\" [options]"
            _show_universal_flags
            echo "${FLOW_COLORS[info]}Exam-Specific Options:${FLOW_COLORS[reset]}"
            echo "  --questions N     Number of questions (default: 20)"
            echo "  --duration MIN    Time limit in minutes (default: 120)"
            echo "  --types TYPES     Question types (mc,sa,essay,calc)"
            echo "  --format FORMAT   Output format (quarto, qti, markdown)"
            echo "  --dry-run         Preview without saving"
            echo ""
            echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
            echo "  teach exam \"Midterm 1\"                         # Standard exam"
            echo "  teach exam \"Final Exam\" --questions 30         # 30 questions"
            echo "  teach exam \"Quiz 3\" --week 6 --duration 30     # Short quiz from week 6"
            echo "  teach exam \"Comprehensive Final\" --format qti  # QTI format for LMS"
            ;;
        quiz)
            echo "teach quiz - Generate quiz questions"
            echo ""
            echo "Usage: teach quiz \"Topic\" [options]"
            _show_universal_flags
            echo "${FLOW_COLORS[info]}Quiz-Specific Options:${FLOW_COLORS[reset]}"
            echo "  --questions N      Number of questions (default: 10)"
            echo "  --time-limit MIN   Time limit in minutes (default: 15)"
            echo "  --format FORMAT    Output format (quarto, qti, markdown)"
            echo "  --dry-run          Preview without saving"
            echo ""
            echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
            echo "  teach quiz \"Week 3 Concepts\"                   # Basic quiz"
            echo "  teach quiz \"Correlation\" --questions 5         # Short 5-question quiz"
            echo "  teach quiz \"Regression\" --week 7               # From lesson plan week 7"
            echo "  teach quiz \"ANOVA\" --time-limit 20 --format qti # 20-min QTI quiz"
            ;;
        assignment)
            echo "teach assignment - Generate homework assignment"
            echo ""
            echo "Usage: teach assignment \"Topic\" [options]"
            _show_universal_flags
            echo "${FLOW_COLORS[info]}Assignment-Specific Options:${FLOW_COLORS[reset]}"
            echo "  --due-date DATE   Due date (YYYY-MM-DD)"
            echo "  --points N        Total points (default: 100)"
            echo "  --format FORMAT   Output format (quarto, markdown)"
            echo "  --dry-run         Preview without saving"
            echo ""
            echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
            echo "  teach assignment \"Homework 3\"                  # Basic assignment"
            echo "  teach assignment \"Problem Set 5\" --points 50   # 50-point assignment"
            echo "  teach assignment \"Data Analysis\" --week 9 -c   # Week 9, with code"
            echo "  teach assignment \"Project\" --due-date 2026-04-15 # Custom due date"
            ;;
        syllabus)
            echo "teach syllabus - Generate course syllabus"
            echo ""
            echo "Usage: teach syllabus [options]"
            _show_universal_flags
            echo "${FLOW_COLORS[info]}Syllabus-Specific Options:${FLOW_COLORS[reset]}"
            echo "  --format FORMAT   Output format (quarto, markdown, pdf)"
            echo "  --dry-run         Preview without saving"
            echo ""
            echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
            echo "  teach syllabus                                   # Generate from config"
            echo "  teach syllabus --format pdf                      # PDF output"
            echo "  teach syllabus --dry-run                         # Preview first"
            echo ""
            echo "${FLOW_COLORS[dim]}Note: Uses course info from .flow/teach-config.yml${FLOW_COLORS[reset]}"
            ;;
        rubric)
            echo "teach rubric - Generate grading rubric"
            echo ""
            echo "Usage: teach rubric \"Assignment Name\" [options]"
            _show_universal_flags
            echo "${FLOW_COLORS[info]}Rubric-Specific Options:${FLOW_COLORS[reset]}"
            echo "  --criteria N      Number of criteria"
            echo "  --format FORMAT   Output format (quarto, markdown)"
            echo "  --dry-run         Preview without saving"
            echo ""
            echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
            echo "  teach rubric \"Final Project\"                   # Project rubric"
            echo "  teach rubric \"Lab Report\" --criteria 4         # 4 criteria rubric"
            echo "  teach rubric \"Homework 5\" --week 10            # From lesson plan"
            ;;
        feedback)
            echo "teach feedback - Generate student feedback"
            echo ""
            echo "Usage: teach feedback \"Student Work\" [options]"
            _show_universal_flags
            echo "${FLOW_COLORS[info]}Feedback-Specific Options:${FLOW_COLORS[reset]}"
            echo "  --tone TONE       Feedback tone (supportive, direct, detailed)"
            echo "  --format FORMAT   Output format (markdown, text)"
            echo "  --dry-run         Preview without saving"
            echo ""
            echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
            echo "  teach feedback \"homework3-smith.pdf\"           # Review homework"
            echo "  teach feedback \"project.R\" --tone supportive   # Supportive tone"
            echo "  teach feedback \"essay.docx\" --tone detailed    # Detailed feedback"
            ;;
        demo)
            echo "teach demo - Create demo course materials"
            echo ""
            echo "Usage: teach demo [options]"
            _show_universal_flags
            echo "${FLOW_COLORS[info]}Demo-Specific Options:${FLOW_COLORS[reset]}"
            echo "  --course-name NAME  Course name (default: STAT-101)"
            echo "  --force             Overwrite existing demo files"
            ;;
        *)
            echo "Unknown command: $cmd"
            echo "Run 'teach help' for available commands"
            ;;
    esac
}

# ============================================================================
# TEACH INIT - Initialize teaching project (v5.14.0 - Task 10)
# ============================================================================

# Initialize teaching project with optional external config and GitHub repo
# Usage: _teach_init [course_name] [--config FILE] [--github]

_teach_config_help() {
    if [[ -z "$_C_BOLD" ]]; then
        _C_BOLD='\033[1m'; _C_DIM='\033[2m'; _C_NC='\033[0m'
        _C_GREEN='\033[32m'; _C_YELLOW='\033[33m'; _C_BLUE='\033[34m'
        _C_MAGENTA='\033[35m'; _C_CYAN='\033[36m'
    fi

    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ teach config - Edit Course Configuration     │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}teach config${_C_NC}             Open config in editor
  ${_C_CYAN}teach config --view${_C_NC}      View without editing
  ${_C_CYAN}teach config --cat${_C_NC}       Print to stdout
  ${_C_DIM}Alias: teach c${_C_NC}

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} teach config              ${_C_DIM}# Edit in default editor${_C_NC}
  ${_C_DIM}\$${_C_NC} teach config --view       ${_C_DIM}# View without editing${_C_NC}
  ${_C_DIM}\$${_C_NC} teach config --cat        ${_C_DIM}# Print to terminal${_C_NC}

${_C_BLUE}📋 CONFIG SECTIONS${_C_NC} ${_C_DIM}(.flow/teach-config.yml)${_C_NC}:
  ${_C_CYAN}course${_C_NC}         Course name, semester, year
  ${_C_CYAN}git${_C_NC}            Branch names, auto-commit settings
  ${_C_CYAN}scholar${_C_NC}        Default Scholar settings
  ${_C_CYAN}backup${_C_NC}         Retention policies
  ${_C_CYAN}deploy${_C_NC}         Deployment settings

${_C_MAGENTA}💡 TIP${_C_NC}: Set ${_C_CYAN}EDITOR${_C_NC} env var for your preferred editor.
  ${_C_DIM}Run teach doctor after editing to validate config.${_C_NC}

${_C_DIM}📚 See also:${_C_NC}
  ${_C_CYAN}teach init${_C_NC} - Initialize teaching project
  ${_C_CYAN}teach doctor${_C_NC} - Health checks
  ${_C_DIM}Guide: docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md${_C_NC}
"
}


_teach_init_help() {
    if [[ -z "$_C_BOLD" ]]; then
        _C_BOLD='\033[1m'; _C_DIM='\033[2m'; _C_NC='\033[0m'
        _C_GREEN='\033[32m'; _C_YELLOW='\033[33m'; _C_BLUE='\033[34m'
        _C_MAGENTA='\033[35m'; _C_CYAN='\033[36m'
    fi

    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ teach init - Initialize Teaching Project     │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_BOLD}Usage:${_C_NC} teach init [course_name] [options]
${_C_BOLD}Alias:${_C_NC} ${_C_CYAN}i${_C_NC} → init

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}teach init${_C_NC}                  Interactive setup (prompts all settings)
  ${_C_CYAN}teach init \"STAT 545\"${_C_NC}       Pre-fill course name, prompt rest
  ${_C_CYAN}teach init --with-templates${_C_NC}  Initialize with template directories

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} teach init                              ${_C_DIM}# Interactive setup${_C_NC}
  ${_C_DIM}\$${_C_NC} teach init \"STAT 545\"                    ${_C_DIM}# Pre-fill course name${_C_NC}
  ${_C_DIM}\$${_C_NC} teach init --config ./my-config.yml      ${_C_DIM}# Load external config${_C_NC}
  ${_C_DIM}\$${_C_NC} teach init \"STAT 545\" --github           ${_C_DIM}# Also create GitHub repo${_C_NC}
  ${_C_DIM}\$${_C_NC} teach init \"STAT 545\" --with-templates   ${_C_DIM}# Include .flow/templates/${_C_NC}

${_C_BLUE}📋 OPTIONS${_C_NC}:
  ${_C_CYAN}--config FILE${_C_NC}        Load configuration from external file
  ${_C_CYAN}--github${_C_NC}             Create GitHub repository (requires gh CLI)
  ${_C_CYAN}--with-templates${_C_NC}     Initialize .flow/templates/ with defaults
  ${_C_CYAN}--help, -h${_C_NC}           Show this help message

${_C_BLUE}📋 CREATES${_C_NC}:
  ${_C_CYAN}.flow/teach-config.yml${_C_NC}  Course metadata, git workflow, teaching mode
  ${_C_CYAN}.teach/lesson-plan.yml${_C_NC}  Content preferences (optional)
  ${_C_CYAN}.flow/templates/${_C_NC}        Template directories (with --with-templates)

${_C_MAGENTA}💡 TIP${_C_NC}: Run ${_C_CYAN}teach doctor${_C_NC} after init to verify setup.
  ${_C_DIM}Use teach config to edit settings later.${_C_NC}
  ${_C_DIM}Configure .teach/lesson-plan.yml for customized Scholar output.${_C_NC}

${_C_DIM}📚 See also:${_C_NC}
  ${_C_CYAN}teach config${_C_NC} - Edit course configuration
  ${_C_CYAN}teach doctor${_C_NC} - Health checks
  ${_C_DIM}docs/tutorials/TEACHING-QUICK-START.md${_C_NC}
  ${_C_DIM}docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md${_C_NC}
"
}

# ============================================================================
# HELP FOR TEACH ANALYZE COMMAND
# ============================================================================


_teach_analyze_help() {
    # Color fallbacks for standalone use
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

    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ teach analyze - Content Analysis             │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_BOLD}Usage:${_C_NC} teach analyze <file> [options]

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}teach analyze <file>${_C_NC}         Validate concepts & prerequisites
  ${_C_CYAN}teach analyze --ai <file>${_C_NC}    AI-powered deep analysis
  ${_C_CYAN}teach analyze -i <file>${_C_NC}      Guided interactive mode

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} teach analyze lectures/week-05.qmd           ${_C_DIM}# Check prerequisites${_C_NC}
  ${_C_DIM}\$${_C_NC} teach analyze --ai lectures/week-05.qmd      ${_C_DIM}# AI: bloom, load, relations${_C_NC}
  ${_C_DIM}\$${_C_NC} teach analyze --slide-breaks lectures/w05.qmd ${_C_DIM}# Slide structure${_C_NC}
  ${_C_DIM}\$${_C_NC} teach analyze --report out.md lectures/w05.qmd ${_C_DIM}# Save report${_C_NC}

${_C_BLUE}📋 ANALYSIS MODES${_C_NC}:
  ${_C_CYAN}teach analyze <file>${_C_NC}                  Basic prerequisite validation
  ${_C_CYAN}teach analyze --ai <file>${_C_NC}             AI-powered (bloom, cognitive load)
  ${_C_CYAN}teach analyze --slide-breaks <file>${_C_NC}   Slide structure analysis
  ${_C_CYAN}teach analyze --preview-breaks <file>${_C_NC} Preview slide breaks (no changes)
  ${_C_CYAN}teach analyze -i <file>${_C_NC}               Guided interactive walkthrough

${_C_BLUE}📋 OPTIONS${_C_NC}:
  ${_C_CYAN}--mode${_C_NC} strict|moderate|relaxed   Strictness level
  ${_C_CYAN}--report${_C_NC} [FILE]                  Generate report file
  ${_C_CYAN}--format${_C_NC} markdown|json            Report format
  ${_C_CYAN}--interactive, -i${_C_NC}                 Guided interactive mode
  ${_C_CYAN}--ai${_C_NC}                             AI-powered analysis (Claude)
  ${_C_CYAN}--costs${_C_NC}                          Show AI usage costs
  ${_C_CYAN}--slide-breaks${_C_NC}                   Analyze slide structure
  ${_C_CYAN}--preview-breaks${_C_NC}                 Preview slide breaks (then exit)

${_C_BLUE}📋 WHAT IT CHECKS${_C_NC}:
  1. Concepts defined in frontmatter (${_C_CYAN}concepts:${_C_NC} field)
  2. Prerequisite ordering (earlier weeks only)
  3. No future-week dependencies
  4. ${_C_DIM}(--ai)${_C_NC} Bloom levels, cognitive load, relationships

${_C_MAGENTA}💡 TIP${_C_NC}: Add ${_C_CYAN}concepts:${_C_NC} to lecture frontmatter for analysis.
  ${_C_DIM}Run before 'teach deploy' to catch ordering issues.${_C_NC}
  ${_C_DIM}Use --ai for deeper insights (requires Claude CLI).${_C_NC}

${_C_DIM}📚 See also:${_C_NC}
  ${_C_CYAN}teach validate${_C_NC} - Run quality checks
  ${_C_CYAN}teach deploy --check-prereqs${_C_NC} - Validate before deploy
  ${_C_DIM}docs/guides/INTELLIGENT-CONTENT-ANALYSIS.md${_C_NC}
"
}

# ============================================================================
# DISPATCHER HELP
# ============================================================================


_teach_lecture_help() {
    if [[ -z "$_C_BOLD" ]]; then
        _C_BOLD='\033[1m'; _C_DIM='\033[2m'; _C_NC='\033[0m'
        _C_GREEN='\033[32m'; _C_YELLOW='\033[33m'; _C_BLUE='\033[34m'
        _C_MAGENTA='\033[35m'; _C_CYAN='\033[36m'
    fi

    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ teach lecture - Generate Lecture Notes        │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_BOLD}Usage:${_C_NC} teach lecture <topic> [options]
${_C_BOLD}Alias:${_C_NC} ${_C_CYAN}lec${_C_NC} → lecture

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}teach lecture \"Topic\" --week N${_C_NC}             Generate for specific week
  ${_C_CYAN}teach lecture \"Topic\" --template quarto${_C_NC}    Quarto format (recommended)
  ${_C_CYAN}teach lecture \"Topic\" --math --code${_C_NC}        With math + code examples

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} teach lecture \"Linear Regression\" --week 5          ${_C_DIM}# Week-based${_C_NC}
  ${_C_DIM}\$${_C_NC} teach lecture \"ANOVA\" --template quarto --week 6    ${_C_DIM}# Quarto format${_C_NC}
  ${_C_DIM}\$${_C_NC} teach lecture \"Neural Nets\" -w 10 --difficulty hard  ${_C_DIM}# Advanced${_C_NC}
  ${_C_DIM}\$${_C_NC} teach lecture \"ML Intro\" --math --code --examples 5  ${_C_DIM}# Full-featured${_C_NC}

${_C_BLUE}📋 TOPIC & STYLE${_C_NC}:
  ${_C_CYAN}<topic>${_C_NC}                   Lecture topic or title
  ${_C_CYAN}--week N, -w N${_C_NC}            Week number (for file naming)
  ${_C_CYAN}--topic \"text\", -t${_C_NC}        Override topic in prompts
  ${_C_CYAN}--template FORMAT${_C_NC}         markdown | quarto | typst | pdf | docx
  ${_C_CYAN}--style formal|casual${_C_NC}     Writing tone
  ${_C_CYAN}--length N${_C_NC}                Target page count (20-40)
  ${_C_CYAN}--difficulty easy|medium|hard${_C_NC}  Content depth

${_C_BLUE}📋 CONTENT FLAGS${_C_NC}:
  ${_C_CYAN}--explanation, -e${_C_NC}          Include detailed explanations
  ${_C_CYAN}--no-explanation${_C_NC}            Skip explanations
  ${_C_CYAN}--proof, -p${_C_NC}                Include mathematical proofs
  ${_C_CYAN}--math, -m${_C_NC}                 Include math notation
  ${_C_CYAN}--code, -c${_C_NC}                 Include code examples
  ${_C_CYAN}--diagrams, -d${_C_NC}             Include diagrams
  ${_C_CYAN}--practice-problems, -pp${_C_NC}   Add practice problems
  ${_C_CYAN}--examples N, -e N${_C_NC}         Number of examples

${_C_BLUE}📋 TROUBLESHOOTING${_C_NC}:
  ${_C_BOLD}\"YAML parse error\"${_C_NC}     → ${_C_CYAN}teach validate --yaml <file>${_C_NC}
  ${_C_BOLD}\"Scholar API timeout\"${_C_NC}   → ${_C_CYAN}teach doctor --check scholar${_C_NC}
  ${_C_BOLD}\"File not staged\"${_C_NC}       → ${_C_CYAN}git add lectures/week-NN/${_C_NC}

${_C_MAGENTA}💡 TIP${_C_NC}: Create ${_C_CYAN}.teach/lesson-plan.yml${_C_NC} first for customized output.
  ${_C_DIM}Use --week for consistent file naming. Preview with quarto preview.${_C_NC}
  ${_C_DIM}Requires .flow/teach-config.yml — run teach doctor to verify.${_C_NC}

${_C_DIM}📚 See also:${_C_NC}
  ${_C_CYAN}teach slides${_C_NC} - Presentation slides
  ${_C_CYAN}teach exam${_C_NC} - Generate assessments
  ${_C_DIM}docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md${_C_NC}
"
}


_teach_doctor_help() {
    if [[ -z "$_C_BOLD" ]]; then
        _C_BOLD='\033[1m'; _C_DIM='\033[2m'; _C_NC='\033[0m'
        _C_GREEN='\033[32m'; _C_YELLOW='\033[33m'; _C_BLUE='\033[34m'
        _C_MAGENTA='\033[35m'; _C_CYAN='\033[36m'
    fi

    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ teach doctor - Health Checks & Diagnostics   │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_BOLD}Usage:${_C_NC} teach doctor [options]
${_C_BOLD}Alias:${_C_NC} ${_C_CYAN}doc${_C_NC} → doctor

${_C_GREEN}MODES${_C_NC}:
  ${_C_CYAN}teach doctor${_C_NC}              Quick check (< 3s, default)
  ${_C_CYAN}teach doctor --full${_C_NC}       Full comprehensive check

${_C_YELLOW}QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} teach doctor                     ${_C_DIM}# Quick: deps, R, config, git${_C_NC}
  ${_C_DIM}\$${_C_NC} teach doctor --full               ${_C_DIM}# Full: all checks${_C_NC}
  ${_C_DIM}\$${_C_NC} teach doctor --fix                ${_C_DIM}# Fix issues (implies --full)${_C_NC}
  ${_C_DIM}\$${_C_NC} teach doctor --ci                 ${_C_DIM}# CI mode (no color, exit code)${_C_NC}
  ${_C_DIM}\$${_C_NC} teach doctor --json               ${_C_DIM}# Machine-readable JSON${_C_NC}
  ${_C_DIM}\$${_C_NC} teach doctor --brief              ${_C_DIM}# Failures and warnings only${_C_NC}

${_C_BLUE}QUICK MODE CHECKS${_C_NC} (default, < 3s):
  1. ${_C_CYAN}Dependencies${_C_NC}      yq, git, quarto, gh, examark, claude
  2. ${_C_CYAN}R Environment${_C_NC}     R available, renv status
  3. ${_C_CYAN}Configuration${_C_NC}     .flow/teach-config.yml
  4. ${_C_CYAN}Git Setup${_C_NC}         branches, remote, working tree

${_C_BLUE}FULL MODE CHECKS${_C_NC} (--full, adds):
  5. ${_C_CYAN}R Packages${_C_NC}        Per-package install check (batch)
  6. ${_C_CYAN}Quarto Extensions${_C_NC} Installed extensions
  7. ${_C_CYAN}Scholar${_C_NC}           Claude Code, scholar skills
  8. ${_C_CYAN}Hooks${_C_NC}             pre-commit, pre-push
  9. ${_C_CYAN}Cache${_C_NC}             _freeze/ freshness
 10. ${_C_CYAN}Macros${_C_NC}            LaTeX macro sources and usage
 11. ${_C_CYAN}Teaching Style${_C_NC}    Style config location

${_C_BLUE}OPTIONS${_C_NC}:
  ${_C_CYAN}--full${_C_NC}               Run all checks (comprehensive)
  ${_C_CYAN}--brief${_C_NC}              Show only failures and warnings
  ${_C_CYAN}--fix${_C_NC}               Interactive fix mode (implies --full)
  ${_C_CYAN}--json${_C_NC}               JSON output (machine-readable)
  ${_C_CYAN}--ci${_C_NC}                CI mode (no color, no spinner, exit 1 on fail)
  ${_C_CYAN}--verbose${_C_NC}            Expanded detail (implies --full)
  ${_C_CYAN}--quiet, -q${_C_NC}          ${_C_DIM}Deprecated alias for --brief${_C_NC}

${_C_BLUE}EXIT CODES${_C_NC}:
  ${_C_GREEN}0${_C_NC} - All checks pass (no failures)
  ${_C_BOLD}1${_C_NC} - One or more failures found

${_C_MAGENTA}TIP${_C_NC}: Quick mode runs by default for fast feedback.
  ${_C_DIM}Use --full when setting up or troubleshooting.${_C_NC}
  ${_C_DIM}Add to CI: teach doctor --ci --full${_C_NC}

${_C_DIM}See also:${_C_NC}
  ${_C_CYAN}teach hooks${_C_NC} - Hook management
  ${_C_CYAN}teach cache${_C_NC} - Cache operations
  ${_C_CYAN}teach config${_C_NC} - Project config
"
}


_teach_slides_help() {
    if [[ -z "$_C_BOLD" ]]; then
        _C_BOLD='\033[1m'; _C_DIM='\033[2m'; _C_NC='\033[0m'
        _C_GREEN='\033[32m'; _C_YELLOW='\033[33m'; _C_BLUE='\033[34m'
        _C_MAGENTA='\033[35m'; _C_CYAN='\033[36m'
    fi

    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ teach slides - Generate Presentation Slides  │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_BOLD}Usage:${_C_NC} teach slides <topic> [options]
${_C_BOLD}Alias:${_C_NC} ${_C_CYAN}sl${_C_NC} → slides

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}teach slides \"Topic\" --week N${_C_NC}              Generate for specific week
  ${_C_CYAN}teach slides \"Topic\" --template quarto${_C_NC}     Quarto revealjs (recommended)
  ${_C_CYAN}teach slides --from-lecture FILE${_C_NC}            Convert lecture to slides

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} teach slides \"Linear Regression\" --week 5            ${_C_DIM}# Week-based${_C_NC}
  ${_C_DIM}\$${_C_NC} teach slides \"ANOVA\" --template quarto --week 6      ${_C_DIM}# Quarto revealjs${_C_NC}
  ${_C_DIM}\$${_C_NC} teach slides --from-lecture week-05.qmd --optimize    ${_C_DIM}# From lecture${_C_NC}
  ${_C_DIM}\$${_C_NC} teach slides \"ML\" --theme academic --math --code     ${_C_DIM}# Themed + code${_C_NC}

${_C_BLUE}📋 TOPIC & TEMPLATE${_C_NC}:
  ${_C_CYAN}<topic>${_C_NC}                   Slides topic or title
  ${_C_CYAN}--week N, -w N${_C_NC}            Week number (for file naming)
  ${_C_CYAN}--topic \"text\", -t${_C_NC}        Override topic in prompts
  ${_C_CYAN}--template FORMAT${_C_NC}         markdown | quarto
  ${_C_CYAN}--theme NAME${_C_NC}              default | academic | minimal

${_C_BLUE}📋 CONTENT FLAGS${_C_NC}:
  ${_C_CYAN}--explanation, -e${_C_NC}          Include detailed explanations
  ${_C_CYAN}--no-explanation${_C_NC}            Skip explanations
  ${_C_CYAN}--math, -m${_C_NC}                 Include math notation
  ${_C_CYAN}--code, -c${_C_NC}                 Include code examples
  ${_C_CYAN}--diagrams, -d${_C_NC}             Include diagrams

${_C_BLUE}📋 OPTIMIZATION (from lecture)${_C_NC}:
  ${_C_CYAN}--from-lecture FILE${_C_NC}        Convert lecture .qmd to slides
  ${_C_CYAN}--optimize${_C_NC}                AI-powered slide structure analysis
  ${_C_CYAN}--preview-breaks${_C_NC}          Show suggested breaks before generating
  ${_C_CYAN}--apply-suggestions${_C_NC}       Auto-apply slide break suggestions
  ${_C_CYAN}--key-concepts${_C_NC}            Emphasize key concepts with callouts

${_C_MAGENTA}💡 TIP${_C_NC}: Use ${_C_CYAN}--template quarto${_C_NC} for revealjs slides.
  ${_C_DIM}Use --theme academic for professional look.${_C_NC}
  ${_C_DIM}Use --optimize for AI-powered slide structure.${_C_NC}

${_C_DIM}📚 See also:${_C_NC}
  ${_C_CYAN}teach lecture${_C_NC} - Lecture notes
  ${_C_CYAN}teach analyze --slide-breaks${_C_NC} - Slide optimization analysis
  ${_C_CYAN}teach quiz${_C_NC} - Quiz questions
  ${_C_DIM}docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md${_C_NC}
"
}


_teach_exam_help() {
    if [[ -z "$_C_BOLD" ]]; then
        _C_BOLD='\033[1m'; _C_DIM='\033[2m'; _C_NC='\033[0m'
        _C_GREEN='\033[32m'; _C_YELLOW='\033[33m'; _C_BLUE='\033[34m'
        _C_MAGENTA='\033[35m'; _C_CYAN='\033[36m'
    fi

    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ teach exam - Generate Exam Questions         │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_BOLD}Usage:${_C_NC} teach exam <topic> [options]
${_C_BOLD}Alias:${_C_NC} ${_C_CYAN}e${_C_NC} → exam

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}teach exam \"Topic\"${_C_NC}                        Generate exam on topic
  ${_C_CYAN}teach exam \"Topic\" --questions 10${_C_NC}          Set question count
  ${_C_CYAN}teach exam \"Topic\" --explanation --math${_C_NC}    With solutions + math

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} teach exam \"Linear Regression\"                           ${_C_DIM}# Basic exam${_C_NC}
  ${_C_DIM}\$${_C_NC} teach exam \"Hypothesis Testing\" --questions 10           ${_C_DIM}# 10 questions${_C_NC}
  ${_C_DIM}\$${_C_NC} teach exam \"ANOVA\" -q 8 --duration 60 --types \"short:5,problem:3\"  ${_C_DIM}# Timed${_C_NC}
  ${_C_DIM}\$${_C_NC} teach exam \"Basics Review\" --questions 20 --format qti   ${_C_DIM}# QTI format${_C_NC}

${_C_BLUE}📋 OPTIONS${_C_NC}:
  ${_C_CYAN}--questions N${_C_NC}             Number of questions (default: 5)
  ${_C_CYAN}--duration N${_C_NC}              Duration in minutes
  ${_C_CYAN}--types TYPES${_C_NC}             Question type breakdown
  ${_C_CYAN}--format FORMAT${_C_NC}           quarto | qti | markdown
  ${_C_CYAN}--difficulty easy|medium|hard${_C_NC}  Content depth

${_C_BLUE}📋 CONTENT FLAGS${_C_NC}:
  ${_C_CYAN}--explanation, -e${_C_NC}          Include answer explanations
  ${_C_CYAN}--math, -m${_C_NC}                 Include math notation
  ${_C_CYAN}--code, -c${_C_NC}                 Include code problems

${_C_MAGENTA}💡 TIP${_C_NC}: Use ${_C_CYAN}--types${_C_NC} to control question mix.
  ${_C_DIM}Preview with --format markdown first.${_C_NC}
  ${_C_DIM}Output: exams/exam-<topic>-YYYY-MM-DD. Auto-staged for git.${_C_NC}

${_C_DIM}📚 See also:${_C_NC}
  ${_C_CYAN}teach quiz${_C_NC} - Quiz questions
  ${_C_CYAN}teach rubric${_C_NC} - Grading rubric
  ${_C_DIM}docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md${_C_NC}
"
}


_teach_quiz_help() {
    if [[ -z "$_C_BOLD" ]]; then
        _C_BOLD='\033[1m'; _C_DIM='\033[2m'; _C_NC='\033[0m'
        _C_GREEN='\033[32m'; _C_YELLOW='\033[33m'; _C_BLUE='\033[34m'
        _C_CYAN='\033[36m'
    fi

    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ teach quiz - Generate Quiz Questions          │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC}:
  ${_C_CYAN}teach quiz${_C_NC} <topic>        Generate quiz on topic
  ${_C_CYAN}teach q${_C_NC} <topic>            Alias for quiz

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} teach quiz \"Linear Regression\"             ${_C_DIM}# Basic quiz${_C_NC}
  ${_C_DIM}\$${_C_NC} teach quiz \"ANOVA\" --questions 10           ${_C_DIM}# 10 questions${_C_NC}
  ${_C_DIM}\$${_C_NC} teach quiz \"ANOVA\" -q 5 --time-limit 15     ${_C_DIM}# Timed quiz${_C_NC}
  ${_C_DIM}\$${_C_NC} teach quiz \"ANOVA\" --explanation --math      ${_C_DIM}# With solutions${_C_NC}

${_C_BLUE}📋 OPTIONS${_C_NC}:
  ${_C_CYAN}--questions N${_C_NC}            Number of questions (default: 5)
  ${_C_CYAN}--time-limit N${_C_NC}           Time limit in minutes
  ${_C_CYAN}--format FORMAT${_C_NC}          quarto | qti | markdown
  ${_C_CYAN}--difficulty LEVEL${_C_NC}       easy | medium | hard

${_C_BLUE}📋 CONTENT FLAGS${_C_NC}:
  ${_C_CYAN}--explanation, -e${_C_NC}        Include answer explanations
  ${_C_CYAN}--math, -m${_C_NC}              Include math notation
  ${_C_CYAN}--code, -c${_C_NC}              Include code questions

${_C_BOLD}OUTPUT${_C_NC}: quizzes/quiz-<topic>-YYYY-MM-DD.*
  Auto-backs up existing files before overwriting

${_C_YELLOW}💡 TIP${_C_NC}: Preview with ${_C_CYAN}--format markdown${_C_NC} before generating final format.

${_C_DIM}📚 See also: teach exam, teach assignment${_C_NC}
"
}


_teach_assignment_help() {
    if [[ -z "$_C_BOLD" ]]; then
        _C_BOLD='\033[1m'; _C_DIM='\033[2m'; _C_NC='\033[0m'
        _C_GREEN='\033[32m'; _C_YELLOW='\033[33m'; _C_BLUE='\033[34m'
        _C_CYAN='\033[36m'
    fi

    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ teach assignment - Generate Homework          │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC}:
  ${_C_CYAN}teach assignment${_C_NC} <topic>  Generate assignment
  ${_C_CYAN}teach hw${_C_NC} <topic>           Alias for assignment

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} teach hw \"Linear Regression\"                      ${_C_DIM}# Basic${_C_NC}
  ${_C_DIM}\$${_C_NC} teach hw \"ANOVA\" --due-date \"2024-02-15\" --points 100  ${_C_DIM}# With due date${_C_NC}
  ${_C_DIM}\$${_C_NC} teach hw \"Data Wrangling\" --code --practice-problems    ${_C_DIM}# Code-focused${_C_NC}

${_C_BLUE}📋 OPTIONS${_C_NC}:
  ${_C_CYAN}--due-date DATE${_C_NC}          Due date (YYYY-MM-DD or \"Week N\")
  ${_C_CYAN}--points N${_C_NC}               Total points
  ${_C_CYAN}--format FORMAT${_C_NC}          quarto | markdown
  ${_C_CYAN}--difficulty LEVEL${_C_NC}       easy | medium | hard

${_C_BLUE}📋 CONTENT FLAGS${_C_NC}:
  ${_C_CYAN}--explanation, -e${_C_NC}        Include solution explanations
  ${_C_CYAN}--math, -m${_C_NC}              Include math problems
  ${_C_CYAN}--code, -c${_C_NC}              Include programming problems
  ${_C_CYAN}--practice-problems, -p${_C_NC} Include practice problems

${_C_BOLD}OUTPUT${_C_NC}: assignments/assignment-<topic>-YYYY-MM-DD.*
  Auto-backs up existing files before overwriting

${_C_YELLOW}💡 TIP${_C_NC}: Use ${_C_CYAN}--due-date${_C_NC} for semester planning and ${_C_CYAN}--format markdown${_C_NC} to preview.

${_C_DIM}📚 See also: teach rubric, teach feedback${_C_NC}
"
}


_teach_syllabus_help() {
    if [[ -z "$_C_BOLD" ]]; then
        _C_BOLD='\033[1m'; _C_DIM='\033[2m'; _C_NC='\033[0m'
        _C_GREEN='\033[32m'; _C_YELLOW='\033[33m'; _C_BLUE='\033[34m'
        _C_CYAN='\033[36m'
    fi

    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ teach syllabus - Generate Course Syllabus     │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC}:
  ${_C_CYAN}teach syllabus${_C_NC}            Generate from config
  ${_C_CYAN}teach syl${_C_NC}                 Alias for syllabus

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} teach syllabus                   ${_C_DIM}# From config${_C_NC}
  ${_C_DIM}\$${_C_NC} teach syllabus \"STAT 440\"        ${_C_DIM}# Specific course${_C_NC}
  ${_C_DIM}\$${_C_NC} teach syllabus --format pdf       ${_C_DIM}# PDF for printing${_C_NC}

${_C_BLUE}📋 OPTIONS${_C_NC}:
  ${_C_CYAN}--format FORMAT${_C_NC}          quarto | markdown | pdf
  ${_C_CYAN}--template TYPE${_C_NC}          default | detailed

${_C_BOLD}OUTPUT${_C_NC}: syllabus.md or syllabus.pdf

${_C_YELLOW}💡 TIP${_C_NC}: Run ${_C_CYAN}teach init${_C_NC} first to set up course config, then
  preview with ${_C_CYAN}quarto preview syllabus.*${_C_NC}.

${_C_DIM}📚 See also: teach config, teach dates${_C_NC}
"
}


_teach_rubric_help() {
    if [[ -z "$_C_BOLD" ]]; then
        _C_BOLD='\033[1m'; _C_DIM='\033[2m'; _C_NC='\033[0m'
        _C_GREEN='\033[32m'; _C_YELLOW='\033[33m'; _C_BLUE='\033[34m'
        _C_CYAN='\033[36m'
    fi

    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ teach rubric - Generate Grading Rubric        │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC}:
  ${_C_CYAN}teach rubric${_C_NC} <name>       Generate rubric for assignment
  ${_C_CYAN}teach rb${_C_NC} <name>            Alias for rubric

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} teach rubric \"Final Project\"                ${_C_DIM}# Basic rubric${_C_NC}
  ${_C_DIM}\$${_C_NC} teach rubric \"Lab Report\" --criteria 5      ${_C_DIM}# 5 criteria${_C_NC}
  ${_C_DIM}\$${_C_NC} teach rubric \"Homework 5\" --week 10         ${_C_DIM}# Week-based${_C_NC}
  ${_C_DIM}\$${_C_NC} teach rubric \"Paper\" --criteria 6 -e        ${_C_DIM}# With explanations${_C_NC}

${_C_BLUE}📋 OPTIONS${_C_NC}:
  ${_C_CYAN}--criteria N${_C_NC}             Number of criteria (default: 4)
  ${_C_CYAN}--format FORMAT${_C_NC}          quarto | markdown
  ${_C_CYAN}--week N${_C_NC}                 Week number (for lesson plan)
  ${_C_CYAN}--explanation, -e${_C_NC}        Include grading explanations

${_C_BOLD}OUTPUT${_C_NC}: rubrics/rubric-<name>-YYYY-MM-DD.*
  Auto-backs up existing files before overwriting

${_C_YELLOW}💡 TIP${_C_NC}: Use ${_C_CYAN}--criteria${_C_NC} to control rubric detail level.

${_C_DIM}📚 See also: teach assignment, teach feedback${_C_NC}
"
}


_teach_feedback_help() {
    if [[ -z "$_C_BOLD" ]]; then
        _C_BOLD='\033[1m'; _C_DIM='\033[2m'; _C_NC='\033[0m'
        _C_GREEN='\033[32m'; _C_YELLOW='\033[33m'; _C_BLUE='\033[34m'
        _C_CYAN='\033[36m'
    fi

    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ teach feedback - Generate Student Feedback    │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC}:
  ${_C_CYAN}teach feedback${_C_NC} <file>     Generate feedback on student work
  ${_C_CYAN}teach fb${_C_NC} <file>            Alias for feedback

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} teach fb \"homework3-smith.pdf\"               ${_C_DIM}# Basic feedback${_C_NC}
  ${_C_DIM}\$${_C_NC} teach fb \"project.R\" --tone supportive       ${_C_DIM}# Supportive tone${_C_NC}
  ${_C_DIM}\$${_C_NC} teach fb \"essay.docx\" --tone detailed        ${_C_DIM}# Detailed review${_C_NC}

${_C_BLUE}📋 OPTIONS${_C_NC}:
  ${_C_CYAN}--tone TONE${_C_NC}              supportive | direct | detailed
  ${_C_CYAN}--format FORMAT${_C_NC}          markdown | text

${_C_BOLD}OUTPUT${_C_NC}: feedback/feedback-<file>-YYYY-MM-DD.*
  Supports PDF, DOCX, R, MD input files

${_C_YELLOW}💡 TIP${_C_NC}: Use ${_C_CYAN}--tone${_C_NC} to match feedback style to context
  (supportive for struggling students, detailed for advanced).

${_C_DIM}📚 See also: teach rubric, teach assignment${_C_NC}
"
}

# Help for hooks command (v5.14.0 - PR #277 Task 2)

_teach_hooks_help() {
    if [[ -z "$_C_BOLD" ]]; then
        _C_BOLD='\033[1m'; _C_DIM='\033[2m'; _C_NC='\033[0m'
        _C_GREEN='\033[32m'; _C_YELLOW='\033[33m'; _C_BLUE='\033[34m'
        _C_MAGENTA='\033[35m'; _C_CYAN='\033[36m'
    fi
    echo -e "${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}"
    echo -e "${_C_BOLD}│${_C_NC}  ${_C_CYAN}teach hooks${_C_NC} - Git Hook Management        ${_C_BOLD}│${_C_NC}"
    echo -e "${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}"
    echo ""
    echo -e "  ${_C_BOLD}USAGE${_C_NC}  teach hooks <command> [options]"
    echo ""
    echo -e "  ${_C_BOLD}🔥 MOST COMMON${_C_NC}"
    echo -e "  ${_C_CYAN}install${_C_NC}              Install git hooks for teaching workflow"
    echo -e "  ${_C_CYAN}status${_C_NC}               Check hook installation status"
    echo -e "  ${_C_CYAN}upgrade${_C_NC}              Upgrade hooks to latest version"
    echo ""
    echo -e "  ${_C_BOLD}💡 QUICK EXAMPLES${_C_NC}"
    echo -e "  ${_C_DIM}# Install hooks in current project${_C_NC}"
    echo -e "  teach hooks install"
    echo -e "  ${_C_DIM}# Check hook status${_C_NC}"
    echo -e "  teach hooks status"
    echo -e "  ${_C_DIM}# Force reinstall${_C_NC}"
    echo -e "  teach hooks install --force"
    echo ""
    echo -e "  ${_C_BOLD}📋 COMMANDS${_C_NC}"
    echo -e "  ${_C_CYAN}install${_C_NC}              Install git hooks"
    echo -e "    ${_C_DIM}--force, -f${_C_NC}       Force reinstall (overwrite existing)"
    echo -e "  ${_C_CYAN}upgrade${_C_NC}              Upgrade to latest version"
    echo -e "    ${_C_DIM}--force, -f${_C_NC}       Force upgrade even if newer"
    echo -e "  ${_C_CYAN}status${_C_NC}               Check installation status"
    echo -e "  ${_C_CYAN}uninstall${_C_NC}            Remove teaching workflow hooks"
    echo ""
    echo -e "  ${_C_BOLD}📋 HOOKS INSTALLED${_C_NC}"
    echo -e "  ${_C_CYAN}pre-commit${_C_NC}           Validate YAML, check dependencies"
    echo -e "  ${_C_CYAN}pre-push${_C_NC}             Check for uncommitted changes"
    echo -e "  ${_C_CYAN}prepare-commit-msg${_C_NC}   Auto-format commit messages"
    echo ""
    echo -e "  ${_C_BOLD}📋 SHORTCUTS${_C_NC}"
    echo -e "  ${_C_CYAN}i${_C_NC} → install      ${_C_CYAN}up, u${_C_NC} → upgrade"
    echo -e "  ${_C_CYAN}s${_C_NC} → status       ${_C_CYAN}rm${_C_NC} → uninstall"
    echo ""
    echo -e "  ${_C_BOLD}💡 TIP${_C_NC}  Run ${_C_CYAN}teach doctor${_C_NC} to verify hook health"
    echo ""
    echo -e "  ${_C_BOLD}📚 See also${_C_NC}"
    echo -e "  ${_C_CYAN}teach doctor${_C_NC} - Health checks (includes hook checks)"
    echo -e "  ${_C_DIM}docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md${_C_NC}"
}

# =============================================================================
# TEACHING STYLE COMMANDS (v6.3.0 - Teaching Style Consolidation)
# =============================================================================


_teach_style_help() {
    # Color fallbacks
    if [[ -z "$_C_BOLD" ]]; then
        _C_BOLD='\033[1m'
        _C_DIM='\033[2m'
        _C_NC='\033[0m'
        _C_GREEN='\033[32m'
        _C_YELLOW='\033[33m'
        _C_CYAN='\033[36m'
    fi

    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ teach style - Teaching Style Management       │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC}:
  ${_C_CYAN}teach style${_C_NC}              Show current teaching style
  ${_C_CYAN}teach style check${_C_NC}        Validate configuration

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} teach style             ${_C_DIM}# Display settings${_C_NC}
  ${_C_DIM}\$${_C_NC} teach style show        ${_C_DIM}# Same as above${_C_NC}
  ${_C_DIM}\$${_C_NC} teach style check       ${_C_DIM}# Validate config${_C_NC}

${_C_BOLD}SUBCOMMANDS${_C_NC}:
  ${_C_CYAN}show${_C_NC} (default)  Display current style source and key settings
  ${_C_CYAN}check${_C_NC}          Validate teaching style configuration

${_C_BOLD}RESOLUTION ORDER${_C_NC}:
  1. .flow/teach-config.yml → teaching_style section (preferred)
  2. .claude/teaching-style.local.md → YAML frontmatter (legacy)

${_C_YELLOW}💡 TIP${_C_NC}: Consolidate your teaching style into .flow/teach-config.yml
  for a single source of truth.

${_C_DIM}📚 See also: teach config, teach doctor${_C_NC}
"
}


_teach_backup_help() {
    if [[ -z "$_C_BOLD" ]]; then
        _C_BOLD='\033[1m'; _C_DIM='\033[2m'; _C_NC='\033[0m'
        _C_GREEN='\033[32m'; _C_YELLOW='\033[33m'; _C_BLUE='\033[34m'
        _C_MAGENTA='\033[35m'; _C_CYAN='\033[36m'
    fi
    echo -e "${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}"
    echo -e "${_C_BOLD}│${_C_NC}  ${_C_CYAN}teach backup${_C_NC} - Content Backup System      ${_C_BOLD}│${_C_NC}"
    echo -e "${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}"
    echo ""
    echo -e "  ${_C_BOLD}USAGE${_C_NC}  teach backup <subcommand> [args]"
    echo ""
    echo -e "  ${_C_BOLD}🔥 MOST COMMON${_C_NC}"
    echo -e "  ${_C_CYAN}create [path]${_C_NC}          Create timestamped backup"
    echo -e "  ${_C_CYAN}list [path]${_C_NC}            List all backups"
    echo -e "  ${_C_CYAN}restore <name>${_C_NC}         Restore from backup"
    echo ""
    echo -e "  ${_C_BOLD}💡 QUICK EXAMPLES${_C_NC}"
    echo -e "  ${_C_DIM}# Create backup${_C_NC}"
    echo -e "  teach backup create lectures/week-01"
    echo -e "  ${_C_DIM}# List all backups${_C_NC}"
    echo -e "  teach backup list"
    echo -e "  ${_C_DIM}# Restore from backup${_C_NC}"
    echo -e "  teach backup restore lectures.2026-01-20-1430"
    echo ""
    echo -e "  ${_C_BOLD}📋 SUBCOMMANDS${_C_NC}"
    echo -e "  ${_C_CYAN}create [path]${_C_NC}          Create timestamped backup"
    echo -e "  ${_C_CYAN}list [path]${_C_NC}            List all backups"
    echo -e "  ${_C_CYAN}restore <name>${_C_NC}         Restore from backup"
    echo -e "  ${_C_CYAN}delete <name>${_C_NC}          Delete backup (with confirmation)"
    echo -e "  ${_C_CYAN}archive <semester>${_C_NC}     Archive semester backups"
    echo ""
    echo -e "  ${_C_BOLD}📋 RETENTION POLICIES${_C_NC}"
    echo -e "  ${_C_CYAN}archive${_C_NC}    Keep forever (exams, syllabi)"
    echo -e "  ${_C_CYAN}semester${_C_NC}   Delete at semester end (lectures)"
    echo -e "  ${_C_DIM}Structure: .backups/<name>.<timestamp>/${_C_NC}"
    echo ""
    echo -e "  ${_C_BOLD}💡 TIP${_C_NC}  Use ${_C_CYAN}teach backup <subcommand> --help${_C_NC} for details"
    echo ""
    echo -e "  ${_C_BOLD}📚 See also${_C_NC}"
    echo -e "  ${_C_CYAN}teach clean${_C_NC} - Clean build artifacts"
    echo -e "  ${_C_CYAN}teach deploy${_C_NC} - Deploy course website"
    echo -e "  ${_C_CYAN}teach archive${_C_NC} - Archive semester backups"
}

# Update backup metadata

