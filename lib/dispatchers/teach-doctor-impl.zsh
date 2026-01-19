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
    local quiet=false fix=false json=false
    local -i passed=0 warnings=0 failures=0
    local -a json_results=()

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --quiet|-q)
                quiet=true
                shift
                ;;
            --fix)
                fix=true
                shift
                ;;
            --json)
                json=true
                quiet=true  # JSON mode implies quiet
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
    if [[ "$json" == "false" ]]; then
        echo ""
    fi
    _teach_doctor_check_config
    if [[ "$json" == "false" ]]; then
        echo ""
    fi
    _teach_doctor_check_git
    if [[ "$json" == "false" ]]; then
        echo ""
    fi
    _teach_doctor_check_scholar

    # Output results
    if [[ "$json" == "true" ]]; then
        _teach_doctor_json_output
    else
        # Summary
        echo ""
        echo "────────────────────────────────────────────────────────────"
        echo "Summary: $passed passed, $warnings warnings, $failures failures"
        echo "────────────────────────────────────────────────────────────"
        echo ""
    fi

    [[ $failures -gt 0 ]] && return 1
    return 0
}

# Check required and optional dependencies
_teach_doctor_check_dependencies() {
    if [[ "$json" == "false" ]]; then
        echo "Dependencies:"
    fi

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

    if [[ "$json" == "false" ]]; then
        echo "Project Configuration:"
    fi

    # Check if config file exists
    if [[ -f "$config_file" ]]; then
        _teach_doctor_pass ".flow/teach-config.yml exists"
        json_results+=("{\"check\":\"config_exists\",\"status\":\"pass\",\"message\":\"exists\"}")

        # Validate config if validator is available
        if typeset -f _teach_validate_config >/dev/null 2>&1; then
            if _teach_validate_config "$config_file" --quiet 2>/dev/null; then
                _teach_doctor_pass "Config validates against schema"
                json_results+=("{\"check\":\"config_valid\",\"status\":\"pass\",\"message\":\"valid\"}")
            else
                _teach_doctor_warn "Config validation failed" "Check syntax with: yq eval '$config_file'"
                json_results+=("{\"check\":\"config_valid\",\"status\":\"warn\",\"message\":\"invalid\"}")
            fi
        fi

        # Check if yq is available for reading config
        if command -v yq &>/dev/null; then
            local course_name=$(yq '.course.name // ""' "$config_file" 2>/dev/null)
            local semester=$(yq '.course.semester // ""' "$config_file" 2>/dev/null)
            local start_date=$(yq '.semester_info.start_date // ""' "$config_file" 2>/dev/null)

            if [[ -n "$course_name" && "$course_name" != "null" ]]; then
                _teach_doctor_pass "Course name: $course_name"
                json_results+=("{\"check\":\"course_name\",\"status\":\"pass\",\"message\":\"$course_name\"}")
            else
                _teach_doctor_warn "Course name not set" "Edit: $config_file"
                json_results+=("{\"check\":\"course_name\",\"status\":\"warn\",\"message\":\"not set\"}")
            fi

            if [[ -n "$semester" && "$semester" != "null" ]]; then
                _teach_doctor_pass "Semester: $semester"
                json_results+=("{\"check\":\"semester\",\"status\":\"pass\",\"message\":\"$semester\"}")
            else
                _teach_doctor_warn "Semester not set" "Edit: $config_file"
                json_results+=("{\"check\":\"semester\",\"status\":\"warn\",\"message\":\"not set\"}")
            fi

            if [[ -n "$start_date" && "$start_date" != "null" ]]; then
                local end_date=$(yq '.semester_info.end_date // ""' "$config_file" 2>/dev/null)
                _teach_doctor_pass "Dates configured ($start_date - $end_date)"
                json_results+=("{\"check\":\"dates\",\"status\":\"pass\",\"message\":\"configured\"}")
            else
                _teach_doctor_warn "Semester dates not configured" "Run: teach dates"
                json_results+=("{\"check\":\"dates\",\"status\":\"warn\",\"message\":\"not configured\"}")
            fi
        fi
    else
        _teach_doctor_fail ".flow/teach-config.yml not found" "Run: teach init"
        json_results+=("{\"check\":\"config_exists\",\"status\":\"fail\",\"message\":\"not found\"}")
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
            json_results+=("{\"check\":\"dep_$cmd\",\"status\":\"pass\",\"message\":\"$version\"}")
        else
            _teach_doctor_pass "$name (installed)"
            json_results+=("{\"check\":\"dep_$cmd\",\"status\":\"pass\",\"message\":\"installed\"}")
        fi
    elif [[ "$required" == "true" ]]; then
        _teach_doctor_fail "$name (not found)" "Install: $fix_cmd"
        json_results+=("{\"check\":\"dep_$cmd\",\"status\":\"fail\",\"message\":\"not found\"}")
    else
        _teach_doctor_warn "$name (not found - optional)" "Install: $fix_cmd"
        json_results+=("{\"check\":\"dep_$cmd\",\"status\":\"warn\",\"message\":\"not found (optional)\"}")
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
    if [[ "$json" == "false" ]]; then
        echo "  ${FLOW_COLORS[warning]}⚠${FLOW_COLORS[reset]} $1"
        if [[ -n "${2:-}" ]]; then
            echo "    → $2"
        fi
    fi
}

# Helper: Failure
_teach_doctor_fail() {
    ((failures++))
    if [[ "$json" == "false" ]]; then
        echo "  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} $1"
        if [[ -n "${2:-}" ]]; then
            echo "    → $2"
        fi
    fi
}

# Check git repository status (Task 4)
_teach_doctor_check_git() {
    if [[ "$json" == "false" ]]; then
        echo "Git Setup:"
    fi

    # Check if in git repo
    if [[ -d .git ]]; then
        _teach_doctor_pass "Git repository initialized"
        json_results+=("{\"check\":\"git_repo\",\"status\":\"pass\",\"message\":\"initialized\"}")

        # Check draft branch
        if git show-ref --verify --quiet refs/heads/draft; then
            _teach_doctor_pass "Draft branch exists"
            json_results+=("{\"check\":\"draft_branch\",\"status\":\"pass\",\"message\":\"exists\"}")
        else
            _teach_doctor_warn "Draft branch not found" "Create with: git checkout -b draft"
            json_results+=("{\"check\":\"draft_branch\",\"status\":\"warn\",\"message\":\"not found\"}")
        fi

        # Check production branch (main or production)
        if git show-ref --verify --quiet refs/heads/main; then
            _teach_doctor_pass "Production branch exists: main"
            json_results+=("{\"check\":\"prod_branch\",\"status\":\"pass\",\"message\":\"exists (main)\"}")
        elif git show-ref --verify --quiet refs/heads/production; then
            _teach_doctor_pass "Production branch exists: production"
            json_results+=("{\"check\":\"prod_branch\",\"status\":\"pass\",\"message\":\"exists (production)\"}")
        else
            _teach_doctor_warn "Production branch not found" "Create with: git checkout -b main"
            json_results+=("{\"check\":\"prod_branch\",\"status\":\"warn\",\"message\":\"not found\"}")
        fi

        # Check remote
        if git remote -v | grep -q origin; then
            local remote_url=$(git remote get-url origin 2>/dev/null)
            _teach_doctor_pass "Remote configured: origin"
            json_results+=("{\"check\":\"remote\",\"status\":\"pass\",\"message\":\"origin configured\"}")
        else
            _teach_doctor_warn "No remote configured" "Add with: git remote add origin <url>"
            json_results+=("{\"check\":\"remote\",\"status\":\"warn\",\"message\":\"not configured\"}")
        fi

        # Check working tree status
        if [[ -z "$(git status --porcelain 2>/dev/null)" ]]; then
            _teach_doctor_pass "Working tree clean"
            json_results+=("{\"check\":\"working_tree\",\"status\":\"pass\",\"message\":\"clean\"}")
        else
            local changes=$(git status --porcelain | wc -l | tr -d ' ')
            _teach_doctor_warn "$changes uncommitted changes"
            json_results+=("{\"check\":\"working_tree\",\"status\":\"warn\",\"message\":\"$changes uncommitted\"}")
        fi
    else
        _teach_doctor_fail "Not a git repository" "Run: git init"
        json_results+=("{\"check\":\"git_repo\",\"status\":\"fail\",\"message\":\"not initialized\"}")
    fi
}

# Check Scholar integration (Task 4)
_teach_doctor_check_scholar() {
    if [[ "$json" == "false" ]]; then
        echo "Scholar Integration:"
    fi

    # Check if claude command is available
    if command -v claude &>/dev/null; then
        _teach_doctor_pass "Claude Code available"
        json_results+=("{\"check\":\"claude_code\",\"status\":\"pass\",\"message\":\"available\"}")

        # Check if scholar skills are accessible (check for scholar: prefix)
        if claude --list-skills 2>/dev/null | grep -q "scholar:"; then
            _teach_doctor_pass "Scholar skills accessible"
            json_results+=("{\"check\":\"scholar_skills\",\"status\":\"pass\",\"message\":\"accessible\"}")
        else
            _teach_doctor_warn "Scholar skills not detected" "Install Scholar plugin"
            json_results+=("{\"check\":\"scholar_skills\",\"status\":\"warn\",\"message\":\"not detected\"}")
        fi
    else
        _teach_doctor_warn "Claude Code not found" "Install: https://code.claude.com"
        json_results+=("{\"check\":\"claude_code\",\"status\":\"warn\",\"message\":\"not found\"}")
    fi

    # Check for lesson plan file
    if [[ -f "lesson-plan.yml" ]]; then
        _teach_doctor_pass "Lesson plan found: lesson-plan.yml"
        json_results+=("{\"check\":\"lesson_plan\",\"status\":\"pass\",\"message\":\"found\"}")
    else
        _teach_doctor_warn "No lesson-plan.yml found (optional)" "Create for better context"
        json_results+=("{\"check\":\"lesson_plan\",\"status\":\"warn\",\"message\":\"not found (optional)\"}")
    fi
}

# Output results as JSON (Task 4)
_teach_doctor_json_output() {
    echo "{"
    echo "  \"summary\": {"
    echo "    \"passed\": $passed,"
    echo "    \"warnings\": $warnings,"
    echo "    \"failures\": $failures,"
    echo "    \"status\": \"$([ $failures -eq 0 ] && echo 'healthy' || echo 'unhealthy')\""
    echo "  },"
    echo "  \"checks\": ["

    local first=true
    for result in "${json_results[@]}"; do
        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo ","
        fi
        echo "    $result"
    done

    echo ""
    echo "  ]"
    echo "}"
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
    echo "  --fix          Auto-fix issues where possible (interactive)"
    echo "  --json         Output results as JSON"
    echo ""
    echo "${FLOW_COLORS[bold]}DESCRIPTION${FLOW_COLORS[reset]}"
    echo "  Checks your teaching environment for:"
    echo "    • Required dependencies (yq, git, quarto, gh)"
    echo "    • Optional dependencies (examark, claude)"
    echo "    • Project configuration (.flow/teach-config.yml)"
    echo "    • Git repository status (branches, remote, clean state)"
    echo "    • Scholar integration (Claude Code, skills, lesson plan)"
    echo ""
    echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
    echo "  teach doctor                # Full health check"
    echo "  teach doctor --quiet        # Only show problems"
    echo "  teach doctor --fix          # Interactive fix mode"
    echo "  teach doctor --json         # JSON output for scripts"
    echo ""
    echo "${FLOW_COLORS[bold]}EXIT STATUS${FLOW_COLORS[reset]}"
    echo "  0    All checks passed (warnings OK)"
    echo "  1    One or more checks failed"
    echo ""
}
