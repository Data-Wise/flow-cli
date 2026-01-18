# ==============================================================================
# TEACH DOCTOR - Environment Health Check (v5.14.0 - Task 2)
# ==============================================================================
#
# Basic implementation (Task 2): dependency checks + config validation
# Full implementation (Task 4): git checks, --fix, --json
#
# Usage:
#   teach doctor              # Check environment
#   teach doctor --quiet      # Only show warnings/failures (Task 4)
#   teach doctor --fix        # Auto-fix issues (Task 4)
#   teach doctor --json       # JSON output (Task 4)

_teach_doctor() {
    local quiet=false
    local -i passed=0 warnings=0 failures=0

    # Parse flags (basic for now, --fix and --json in Task 4)
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --quiet|-q)
                quiet=true
                shift
                ;;
            --help|-h)
                _teach_doctor_help
                return 0
                ;;
            *)
                shift
                ;;
        esac
    done

    # Header
    if [[ "$quiet" == "false" ]]; then
        echo ""
        echo "╭────────────────────────────────────────────────────────────╮"
        echo "│  📚 Teaching Environment Health Check                       │"
        echo "╰────────────────────────────────────────────────────────────╯"
        echo ""
    fi

    # Run checks
    _teach_doctor_check_dependencies
    echo ""
    _teach_doctor_check_config

    # Summary
    echo ""
    echo "────────────────────────────────────────────────────────────"
    echo "Summary: $passed passed, $warnings warnings, $failures failures"
    echo "────────────────────────────────────────────────────────────"
    echo ""

    [[ $failures -gt 0 ]] && return 1
    return 0
}

# Check required and optional dependencies
_teach_doctor_check_dependencies() {
    echo "Dependencies:"

    # Required dependencies
    _teach_doctor_check_dep "yq" "yq" "brew install yq" "true"
    _teach_doctor_check_dep "git" "git" "xcode-select --install" "true"
    _teach_doctor_check_dep "quarto" "quarto" "brew install --cask quarto" "true"
    _teach_doctor_check_dep "gh" "gh" "brew install gh" "true"

    # Optional dependencies
    _teach_doctor_check_dep "examark" "examark" "npm install -g examark" "false"
    _teach_doctor_check_dep "claude" "claude" "Follow: https://code.claude.com" "false"
}

# Check project configuration
_teach_doctor_check_config() {
    local config_file=".flow/teach-config.yml"

    echo "Project Configuration:"

    # Check if config file exists
    if [[ -f "$config_file" ]]; then
        _teach_doctor_pass ".flow/teach-config.yml exists"

        # Validate config if validator is available
        if typeset -f _teach_validate_config >/dev/null 2>&1; then
            if _teach_validate_config "$config_file" --quiet 2>/dev/null; then
                _teach_doctor_pass "Config validates against schema"
            else
                _teach_doctor_warn "Config validation failed" "Check syntax with: yq eval '$config_file'"
            fi
        fi

        # Check if yq is available for reading config
        if command -v yq &>/dev/null; then
            local course_name=$(yq '.course.name // ""' "$config_file" 2>/dev/null)
            local semester=$(yq '.course.semester // ""' "$config_file" 2>/dev/null)
            local start_date=$(yq '.semester_info.start_date // ""' "$config_file" 2>/dev/null)

            if [[ -n "$course_name" && "$course_name" != "null" ]]; then
                _teach_doctor_pass "Course name: $course_name"
            else
                _teach_doctor_warn "Course name not set" "Edit: $config_file"
            fi

            if [[ -n "$semester" && "$semester" != "null" ]]; then
                _teach_doctor_pass "Semester: $semester"
            else
                _teach_doctor_warn "Semester not set" "Edit: $config_file"
            fi

            if [[ -n "$start_date" && "$start_date" != "null" ]]; then
                local end_date=$(yq '.semester_info.end_date // ""' "$config_file" 2>/dev/null)
                _teach_doctor_pass "Dates configured ($start_date - $end_date)"
            else
                _teach_doctor_warn "Semester dates not configured" "Run: teach dates"
            fi
        fi
    else
        _teach_doctor_fail ".flow/teach-config.yml not found" "Run: teach init"
    fi
}

# Check single dependency
# Args: name, command, install_command, required(true/false)
_teach_doctor_check_dep() {
    local name="$1"
    local cmd="$2"
    local fix_cmd="$3"
    local required="${4:-true}"

    if command -v "$cmd" &>/dev/null; then
        local version=$($cmd --version 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
        if [[ -n "$version" ]]; then
            _teach_doctor_pass "$name ($version)"
        else
            _teach_doctor_pass "$name (installed)"
        fi
    elif [[ "$required" == "true" ]]; then
        _teach_doctor_fail "$name (not found)" "Install: $fix_cmd"
    else
        _teach_doctor_warn "$name (not found - optional)" "Install: $fix_cmd"
    fi
}

# Helper: Pass check
_teach_doctor_pass() {
    ((passed++))
    if [[ "$quiet" == "false" ]]; then
        echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} $1"
    fi
}

# Helper: Warning
_teach_doctor_warn() {
    ((warnings++))
    echo "  ${FLOW_COLORS[warning]}⚠${FLOW_COLORS[reset]} $1"
    if [[ -n "${2:-}" ]]; then
        echo "    → $2"
    fi
}

# Helper: Failure
_teach_doctor_fail() {
    ((failures++))
    echo "  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} $1"
    if [[ -n "${2:-}" ]]; then
        echo "    → $2"
    fi
}

# Help function for teach doctor
_teach_doctor_help() {
    echo "${FLOW_COLORS[bold]}teach doctor${FLOW_COLORS[reset]} - Validate teaching environment setup"
    echo ""
    echo "${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}"
    echo "  teach doctor [OPTIONS]"
    echo ""
    echo "${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}"
    echo "  -h, --help     Show this help message"
    echo "  -q, --quiet    Only show warnings and failures"
    echo ""
    echo "${FLOW_COLORS[bold]}DESCRIPTION${FLOW_COLORS[reset]}"
    echo "  Checks your teaching environment for:"
    echo "    • Required dependencies (yq, git, quarto, gh)"
    echo "    • Optional dependencies (examark, claude)"
    echo "    • Project configuration (.flow/teach-config.yml)"
    echo "    • Config validation and semester setup"
    echo ""
    echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
    echo "  teach doctor                # Full health check"
    echo "  teach doctor --quiet        # Only show problems"
    echo ""
    echo "${FLOW_COLORS[bold]}EXIT STATUS${FLOW_COLORS[reset]}"
    echo "  0    All checks passed (warnings OK)"
    echo "  1    One or more checks failed"
    echo ""
}
