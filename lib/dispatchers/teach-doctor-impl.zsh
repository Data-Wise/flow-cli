# ==============================================================================
# TEACH DOCTOR - Environment Health Check (v6.5.0)
# ==============================================================================
#
# Two-mode architecture:
#   Quick (default): CLI deps, R available, config, git — target < 3s
#   Full (--full):   Everything above + per-package R, quarto ext, scholar,
#                    hooks, cache, macros, teaching style
#
# Usage:
#   teach doctor              # Quick check (default, < 3s)
#   teach doctor --full       # Full comprehensive check
#   teach doctor --brief      # Only show warnings/failures
#   teach doctor --fix        # Auto-fix issues
#   teach doctor --json       # JSON output
#   teach doctor --ci         # CI mode (no color, exit 1 on failure)
#   teach doctor --verbose    # Expanded detail for every check

_teach_doctor() {
    local quiet=false fix=false json=false
    local full=false brief=false ci=false verbose=false
    local -i passed=0 warnings=0 failures=0
    local -a json_results=()
    local -a failure_details=()
    local start_time=$EPOCHSECONDS

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --full)
                full=true
                shift
                ;;
            --brief)
                brief=true
                quiet=true
                shift
                ;;
            --quiet|-q)
                # Deprecated alias for --brief
                brief=true
                quiet=true
                shift
                ;;
            --fix)
                fix=true
                full=true  # --fix implies full mode
                shift
                ;;
            --json)
                json=true
                quiet=true
                shift
                ;;
            --ci)
                ci=true
                json=false
                quiet=true
                shift
                ;;
            --verbose)
                verbose=true
                full=true  # --verbose implies full mode
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

    # CI mode: disable colors
    if [[ "$ci" == "true" ]]; then
        local -A FLOW_COLORS=([reset]="" [bold]="" [dim]="" [success]="" [warning]="" [error]="" [info]="" [muted]="")
    fi

    # Determine mode label
    local mode_label="quick check"
    [[ "$full" == "true" ]] && mode_label="full check"

    # Header
    if [[ "$quiet" == "false" ]]; then
        echo ""
        echo "╭────────────────────────────────────────────────────────────╮"
        echo "│  Teaching Environment ($mode_label)                        │"
        echo "╰────────────────────────────────────────────────────────────╯"
        echo ""
    fi

    # ── Quick mode checks (always run) ──────────────────────────────────
    _teach_doctor_section_gap
    _teach_doctor_check_dependencies
    _teach_doctor_section_gap

    # R quick check: is R available? (quick mode = summary only)
    _teach_doctor_check_r_quick
    _teach_doctor_section_gap

    _teach_doctor_check_config
    _teach_doctor_section_gap

    _teach_doctor_check_git

    # ── Full mode checks (--full only) ──────────────────────────────────
    if [[ "$full" == "true" ]]; then
        _teach_doctor_section_gap

        _teach_doctor_spinner_start "Checking R packages..."
        _teach_doctor_check_r_packages
        _teach_doctor_spinner_stop
        _teach_doctor_section_gap

        _teach_doctor_spinner_start "Checking Quarto extensions..."
        _teach_doctor_check_quarto_extensions
        _teach_doctor_spinner_stop
        _teach_doctor_section_gap

        _teach_doctor_check_scholar
        _teach_doctor_section_gap

        _teach_doctor_check_hooks
        _teach_doctor_section_gap

        _teach_doctor_spinner_start "Checking cache..."
        _teach_doctor_check_cache
        _teach_doctor_spinner_stop
        _teach_doctor_section_gap

        _teach_doctor_spinner_start "Checking macros..."
        _teach_doctor_check_macros
        _teach_doctor_spinner_stop
        _teach_doctor_section_gap

        _teach_doctor_check_teaching_style
    fi

    # Skipped sections hint (quick mode only)
    if [[ "$full" == "false" && "$quiet" == "false" && "$json" == "false" ]]; then
        echo ""
        echo "  ${FLOW_COLORS[muted]}Skipped (run --full): R packages, quarto extensions, hooks, cache, macros, style${FLOW_COLORS[reset]}"
    fi

    # Elapsed time
    local elapsed=$(( EPOCHSECONDS - start_time ))

    # Output results
    if [[ "$json" == "true" ]]; then
        _teach_doctor_json_output
    elif [[ "$ci" == "true" ]]; then
        # CI mode: machine-readable summary
        echo "doctor:status=$([ $failures -eq 0 ] && echo 'pass' || echo 'fail')"
        echo "doctor:passed=$passed"
        echo "doctor:warnings=$warnings"
        echo "doctor:failures=$failures"
        echo "doctor:mode=$([[ "$full" == "true" ]] && echo 'full' || echo 'quick')"
        echo "doctor:elapsed=${elapsed}s"
    else
        # Summary
        _teach_doctor_summary
    fi

    # Write status file for health indicator
    _teach_doctor_write_status

    [[ $failures -gt 0 ]] && return 1
    return 0
}

# Write .flow/doctor-status.json for health indicator on teach startup
_teach_doctor_write_status() {
    local status_dir=".flow"
    local status_file="$status_dir/doctor-status.json"

    # Only write if .flow directory exists (we're in a teaching project)
    [[ ! -d "$status_dir" ]] && return

    local status_color="green"
    [[ $warnings -gt 0 ]] && status_color="yellow"
    [[ $failures -gt 0 ]] && status_color="red"

    local mode_str="quick"
    [[ "$full" == "true" ]] && mode_str="full"

    local timestamp
    timestamp=$(date -u "+%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date "+%Y-%m-%dT%H:%M:%S")

    cat > "$status_file" <<STATUSEOF
{
    "version": 1,
    "timestamp": "$timestamp",
    "mode": "$mode_str",
    "totals": {"passed": $passed, "warnings": $warnings, "failures": $failures},
    "status": "$status_color"
}
STATUSEOF
}

# Read health indicator from last doctor run
# Returns: "green", "yellow", "red", or empty string
_teach_health_indicator() {
    local status_file=".flow/doctor-status.json"

    # No status file = no indicator
    [[ ! -f "$status_file" ]] && return

    # Check freshness (stale if > 1 hour)
    local file_mtime
    file_mtime=$(stat -f %m "$status_file" 2>/dev/null || stat -c %Y "$status_file" 2>/dev/null)

    if [[ -n "$file_mtime" ]]; then
        local age=$(( EPOCHSECONDS - file_mtime ))
        if (( age > 3600 )); then
            # Stale: run quick doctor silently to refresh
            _teach_doctor --brief >/dev/null 2>&1
        fi
    fi

    # Read status from file
    if command -v jq &>/dev/null; then
        jq -r '.status // empty' "$status_file" 2>/dev/null
    else
        # Fallback: grep for status field
        grep -o '"status": *"[^"]*"' "$status_file" 2>/dev/null | head -1 | grep -o '"[^"]*"$' | tr -d '"'
    fi
}

# Format health dot for display
_teach_health_dot() {
    local status
    status=$(_teach_health_indicator)

    case "$status" in
        green)  echo -e "\033[32m●\033[0m" ;;
        yellow) echo -e "\033[33m●\033[0m" ;;
        red)    echo -e "\033[31m●\033[0m" ;;
        *)      echo "" ;;
    esac
}

# Helper: emit section gap (respects json mode)
_teach_doctor_section_gap() {
    [[ "$json" == "false" ]] && echo ""
}

# ── Spinner UX ──────────────────────────────────────────────────
# Background spinner with elapsed time (shown after 5s threshold)
# Uses temp file as stop signal for cross-process communication.

typeset -g _DOCTOR_SPINNER_PID=0
typeset -g _DOCTOR_SPINNER_STOP=""

_teach_doctor_spinner_start() {
    local label="$1"

    # Skip spinners in quiet/json/ci modes
    [[ "$quiet" == "true" || "$json" == "true" || "$ci" == "true" ]] && return

    # Create stop signal file
    _DOCTOR_SPINNER_STOP=$(mktemp -t doctor-spin.XXXXXX 2>/dev/null || echo "/tmp/doctor-spin.$$")
    rm -f "$_DOCTOR_SPINNER_STOP"  # File absence = keep spinning

    # Start background spinner
    (
        local chars=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
        local i=0
        local start=$EPOCHSECONDS
        local elapsed=0

        while [[ ! -f "$_DOCTOR_SPINNER_STOP" ]]; do
            elapsed=$(( EPOCHSECONDS - start ))
            local time_str=""
            (( elapsed >= 5 )) && time_str=" (${elapsed}s)"

            printf "\r  ${chars[$((i % ${#chars[@]}))]} %s%s" "$label" "$time_str" > /dev/tty 2>/dev/null
            ((i++))
            sleep 0.1
        done

        # Clear spinner line
        printf "\r\033[K" > /dev/tty 2>/dev/null
    ) &
    _DOCTOR_SPINNER_PID=$!
}

_teach_doctor_spinner_stop() {
    # Signal spinner to stop
    if [[ -n "$_DOCTOR_SPINNER_STOP" ]]; then
        touch "$_DOCTOR_SPINNER_STOP" 2>/dev/null
        # Wait briefly for spinner to clear
        if [[ $_DOCTOR_SPINNER_PID -gt 0 ]]; then
            sleep 0.15
            kill $_DOCTOR_SPINNER_PID 2>/dev/null
            wait $_DOCTOR_SPINNER_PID 2>/dev/null
        fi
        rm -f "$_DOCTOR_SPINNER_STOP" 2>/dev/null
        _DOCTOR_SPINNER_PID=0
        _DOCTOR_SPINNER_STOP=""
    fi
}

# Quick R check: is R available, renv status summary, package count hint
_teach_doctor_check_r_quick() {
    if [[ "$json" == "false" ]]; then
        echo "R Environment:"
    fi

    if ! command -v R &>/dev/null; then
        _teach_doctor_warn "R not found" "Install R: brew install --cask r"
        json_results+=("{\"check\":\"r_available\",\"status\":\"warn\",\"message\":\"not found\"}")
        return
    fi

    # R version
    local r_version
    r_version=$(R --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)

    # renv detection
    local renv_active=false
    local renv_summary=""

    if [[ -f "renv.lock" && -f "renv/activate.R" ]]; then
        renv_active=true

        # Quick sync check: count packages in renv.lock
        if command -v jq &>/dev/null; then
            local lock_count
            lock_count=$(jq -r '.Packages | length' renv.lock 2>/dev/null)
            renv_summary=" | renv active | ${lock_count} packages locked"
        else
            renv_summary=" | renv active"
        fi
    elif [[ -f "renv.lock" ]]; then
        renv_summary=" | renv.lock found (not activated)"
    fi

    # Single summary line: "R (4.4.2) | renv active | 27 packages locked"
    _teach_doctor_pass "R ($r_version)${renv_summary}"
    json_results+=("{\"check\":\"r_available\",\"status\":\"pass\",\"message\":\"$r_version\"}")

    if [[ "$renv_active" == "true" ]]; then
        json_results+=("{\"check\":\"renv_status\",\"status\":\"pass\",\"message\":\"active\"}")

        # renv.lock freshness
        if [[ "$verbose" == "true" && "$quiet" == "false" && "$json" == "false" ]]; then
            local lock_mtime
            lock_mtime=$(stat -f %m renv.lock 2>/dev/null || stat -c %Y renv.lock 2>/dev/null)
            if [[ -n "$lock_mtime" ]]; then
                local age_days=$(( (EPOCHSECONDS - lock_mtime) / 86400 ))
                if [[ $age_days -eq 0 ]]; then
                    echo "    ${FLOW_COLORS[muted]}renv.lock updated today${FLOW_COLORS[reset]}"
                else
                    echo "    ${FLOW_COLORS[muted]}renv.lock updated $age_days days ago${FLOW_COLORS[reset]}"
                fi
            fi
        fi
    elif [[ -f "renv.lock" ]]; then
        json_results+=("{\"check\":\"renv_status\",\"status\":\"warn\",\"message\":\"lock without activate\"}")
    fi

    # Inline hint for full mode
    if [[ "$full" == "false" && "$quiet" == "false" && "$json" == "false" ]]; then
        echo "     ${FLOW_COLORS[muted]}-> Run --full for package details${FLOW_COLORS[reset]}"
    fi
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

        # Interactive fix mode
        if [[ "$fix" == "true" ]]; then
            _teach_doctor_interactive_fix "$name" "$fix_cmd"
        fi
    else
        _teach_doctor_warn "$name (not found - optional)" "Install: $fix_cmd"
        json_results+=("{\"check\":\"dep_$cmd\",\"status\":\"warn\",\"message\":\"not found (optional)\"}")

        # Interactive fix mode (optional deps)
        if [[ "$fix" == "true" ]]; then
            _teach_doctor_interactive_fix "$name" "$fix_cmd" "optional"
        fi
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
    # Record for severity-grouped summary
    if [[ -n "${2:-}" ]]; then
        failure_details+=("$1\n    -> $2")
    else
        failure_details+=("$1")
    fi
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

# Output results as JSON
_teach_doctor_json_output() {
    local mode_str="quick"
    [[ "$full" == "true" ]] && mode_str="full"

    echo "{"
    echo "  \"version\": 1,"
    echo "  \"mode\": \"$mode_str\","
    echo "  \"summary\": {"
    echo "    \"passed\": $passed,"
    echo "    \"warnings\": $warnings,"
    echo "    \"failures\": $failures,"
    echo "    \"status\": \"$([ $failures -eq 0 ] && [ $warnings -eq 0 ] && echo 'green' || [ $failures -eq 0 ] && echo 'yellow' || echo 'red')\""
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

# Severity-grouped summary output
_teach_doctor_summary() {
    echo ""
    echo "────────────────────────────────────────────────────────────"

    # Failures with fix commands (shown first, most important)
    if [[ $failures -gt 0 ]]; then
        echo -e "${FLOW_COLORS[error]}Failures ($failures):${FLOW_COLORS[reset]}"
        for detail in "${failure_details[@]}"; do
            echo -e "  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} $detail"
        done
        echo ""
    fi

    # Compact summary line
    local summary_parts=()
    if [[ $failures -gt 0 ]]; then
        summary_parts+=("${FLOW_COLORS[error]}$failures failed${FLOW_COLORS[reset]}")
    fi
    if [[ $warnings -gt 0 ]]; then
        summary_parts+=("${FLOW_COLORS[warning]}Warnings: $warnings${FLOW_COLORS[reset]}")
    fi
    summary_parts+=("${FLOW_COLORS[success]}Passed: $passed${FLOW_COLORS[reset]}")

    local elapsed=$(( EPOCHSECONDS - start_time ))
    local time_display=""
    (( elapsed > 0 )) && time_display="  [${elapsed}s]"

    echo -e "${(j: | :)summary_parts}${time_display}"
    echo "────────────────────────────────────────────────────────────"
    echo ""
}

# Interactive fix helper
# Args: name, install_command, [optional]
_teach_doctor_interactive_fix() {
    local name="$1"
    local install_cmd="$2"
    local optional="${3:-}"

    # Prompt user
    if [[ -n "$optional" ]]; then
        echo -n "  ${FLOW_COLORS[info]}→${FLOW_COLORS[reset]} Install $name (optional)? [y/N] "
    else
        echo -n "  ${FLOW_COLORS[info]}→${FLOW_COLORS[reset]} Install $name? [Y/n] "
    fi

    read -r response
    response=${response:-$([ -n "$optional" ] && echo "n" || echo "y")}

    if [[ "$response" =~ ^[Yy] ]]; then
        echo "  ${FLOW_COLORS[muted]}→ $install_cmd${FLOW_COLORS[reset]}"

        # Execute install command
        if eval "$install_cmd" >/dev/null 2>&1; then
            echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} $name installed"
        else
            echo "  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} Failed to install $name"
            echo "  ${FLOW_COLORS[muted]}→ Try manually: $install_cmd${FLOW_COLORS[reset]}"
        fi
    fi
}

# Check R packages (full mode only — per-package batch check with renv details)
_teach_doctor_check_r_packages() {
    if [[ "$json" == "false" ]]; then
        echo "R Packages:"
    fi

    # Check if R is available first
    if ! command -v R &>/dev/null; then
        _teach_doctor_warn "R not found" "Install R to use R packages"
        json_results+=("{\"check\":\"r_packages\",\"status\":\"warn\",\"message\":\"R not installed\"}")
        return
    fi

    # renv detailed status (full mode)
    local renv_active=false
    if [[ -f "renv.lock" && -f "renv/activate.R" ]]; then
        renv_active=true

        # Library path
        local renv_lib=""
        local -a lib_dirs=(renv/library/*/R-*/*(/N))
        if [[ ${#lib_dirs} -gt 0 ]]; then
            renv_lib="${lib_dirs[1]}"
        fi
        if [[ -n "$renv_lib" ]]; then
            _teach_doctor_pass "renv active ($renv_lib)"
            json_results+=("{\"check\":\"renv_library\",\"status\":\"pass\",\"message\":\"$renv_lib\"}")
        else
            _teach_doctor_pass "renv active"
            json_results+=("{\"check\":\"renv_library\",\"status\":\"pass\",\"message\":\"active\"}")
        fi

        # Lock file freshness
        local lock_mtime
        lock_mtime=$(stat -f %m renv.lock 2>/dev/null || stat -c %Y renv.lock 2>/dev/null)
        if [[ -n "$lock_mtime" ]]; then
            local age_days=$(( (EPOCHSECONDS - lock_mtime) / 86400 ))
            if [[ $age_days -eq 0 ]]; then
                _teach_doctor_pass "renv.lock updated today"
            elif [[ $age_days -lt 30 ]]; then
                _teach_doctor_pass "renv.lock updated $age_days days ago"
            else
                _teach_doctor_warn "renv.lock is $age_days days old" "Consider: renv::snapshot()"
            fi
            json_results+=("{\"check\":\"renv_lock_age\",\"status\":\"pass\",\"message\":\"${age_days} days\"}")
        fi
    elif [[ -f "renv.lock" ]]; then
        _teach_doctor_warn "renv.lock exists but renv not activated" "Run: renv::activate()"
        json_results+=("{\"check\":\"renv_status\",\"status\":\"warn\",\"message\":\"not activated\"}")
    fi

    # Get packages from all sources (teaching.yml, renv.lock, DESCRIPTION)
    local packages
    packages=$(_list_r_packages_from_sources 2>/dev/null)

    if [[ -z "$packages" ]]; then
        # Fall back to common teaching packages if no config found
        packages="ggplot2
dplyr
tidyr
knitr
rmarkdown"
        if [[ "$json" == "false" ]]; then
            echo -e "  ${FLOW_COLORS[muted]}No R packages defined in teaching.yml or renv.lock${FLOW_COLORS[reset]}"
            echo -e "  ${FLOW_COLORS[muted]}Checking common teaching packages...${FLOW_COLORS[reset]}"
        fi
    fi

    # Batch check: single R invocation for ALL packages (fast, renv-safe)
    local installed_list
    installed_list=$(_get_installed_r_packages 2>/dev/null)

    if [[ -z "$installed_list" ]]; then
        _teach_doctor_warn "Could not query installed R packages"
        json_results+=("{\"check\":\"r_packages\",\"status\":\"warn\",\"message\":\"query failed\"}")
        return
    fi

    # Build lookup set from installed packages
    local -A installed_set=()
    local pkg_name
    while IFS= read -r pkg_name; do
        [[ -n "$pkg_name" ]] && installed_set[$pkg_name]=1
    done <<< "$installed_list"

    # Compare expected vs installed
    local missing_packages=()
    local installed_count=0
    local total_count=0

    while IFS= read -r pkg; do
        [[ -z "$pkg" ]] && continue
        ((total_count++))

        if (( ${+installed_set[$pkg]} )); then
            ((installed_count++))
            _teach_doctor_pass "R package: $pkg"
            json_results+=("{\"check\":\"r_pkg_$pkg\",\"status\":\"pass\",\"message\":\"installed\"}")
        else
            _teach_doctor_warn "R package '$pkg' not found"
            json_results+=("{\"check\":\"r_pkg_$pkg\",\"status\":\"warn\",\"message\":\"not installed\"}")
            missing_packages+=("$pkg")
        fi
    done <<< "$packages"

    # Summary line: "R: 25/27 installed | Missing: pkgA, pkgB"
    if [[ "$json" == "false" && $total_count -gt 0 ]]; then
        if [[ ${#missing_packages[@]} -gt 0 ]]; then
            echo "  ${FLOW_COLORS[warning]}R: ${installed_count}/${total_count} installed${FLOW_COLORS[reset]} | Missing: ${missing_packages[*]}"
        else
            echo "  ${FLOW_COLORS[success]}R: ${installed_count}/${total_count} installed${FLOW_COLORS[reset]}"
        fi
    fi

    # Interactive fix for missing packages (renv-aware)
    if [[ "$fix" == "true" && ${#missing_packages[@]} -gt 0 ]]; then
        echo ""
        echo -e "${FLOW_COLORS[warning]}Missing R packages: ${missing_packages[*]}${FLOW_COLORS[reset]}"

        if [[ "$renv_active" == "true" ]]; then
            # Offer renv vs system install choice
            echo "  Install via renv or system?"
            echo "    r) renv::install() — project-local"
            echo "    s) install.packages() — system-wide"
            echo -n "  ${FLOW_COLORS[info]}→${FLOW_COLORS[reset]} [r/s] "
            read -r response
            response=${response:-r}

            local pkg_str=$(printf "'%s', " "${missing_packages[@]}")
            pkg_str="${pkg_str%, }"  # Remove trailing comma

            if [[ "$response" =~ ^[Rr] ]]; then
                _flow_log_info "Installing via renv..."
                R --quiet --slave -e "renv::install(c(${pkg_str}))" 2>&1
            else
                _flow_log_info "Installing system-wide..."
                R --quiet --slave -e "install.packages(c(${pkg_str}), repos='https://cloud.r-project.org')" 2>&1
            fi
        else
            # Standard install
            echo -n "  ${FLOW_COLORS[info]}→${FLOW_COLORS[reset]} Install all missing packages? [Y/n] "
            read -r response
            response=${response:-y}

            if [[ "$response" =~ ^[Yy] ]]; then
                _flow_log_info "Installing missing R packages..."
                _install_r_packages --yes "${missing_packages[@]}"

                if [[ $? -eq 0 ]]; then
                    _flow_log_success "All R packages installed successfully"
                else
                    _flow_log_error "Some packages failed to install"
                fi
            fi
        fi
    fi
}

# Check Quarto extensions (full mode only)
_teach_doctor_check_quarto_extensions() {
    if [[ ! -d "_extensions" ]]; then
        return 0  # No extensions directory, skip check
    fi

    if [[ "$json" == "false" ]]; then
        echo "Quarto Extensions:"
    fi

    # Count installed extensions using pure ZSH glob (avoids find|wc arithmetic bug)
    local -a ext_dirs=(_extensions/*/*(/N))
    local ext_count=${#ext_dirs}

    if [[ "$ext_count" -gt 0 ]]; then
        _teach_doctor_pass "$ext_count Quarto extensions installed"
        json_results+=("{\"check\":\"quarto_extensions\",\"status\":\"pass\",\"message\":\"$ext_count installed\"}")

        # List extensions
        if [[ "$json" == "false" && "$quiet" == "false" ]]; then
            local ext_dir
            for ext_dir in "${ext_dirs[@]}"; do
                local ext_name="${ext_dir:h:t}/${ext_dir:t}"
                echo "    ${FLOW_COLORS[muted]}→ $ext_name${FLOW_COLORS[reset]}"
            done
        fi
    else
        _teach_doctor_warn "No Quarto extensions found" "Install with: quarto add <extension>"
        json_results+=("{\"check\":\"quarto_extensions\",\"status\":\"warn\",\"message\":\"none found\"}")
    fi
}

# Check hook status (full mode only)
_teach_doctor_check_hooks() {
    if [[ "$json" == "false" ]]; then
        echo "Git Hooks:"
    fi

    local -a hooks=("pre-commit" "pre-push" "prepare-commit-msg")
    local installed_count=0

    for hook in "${hooks[@]}"; do
        local hook_file=".git/hooks/$hook"

        if [[ -x "$hook_file" ]]; then
            ((installed_count++))

            # Check if it's a flow-cli managed hook
            if grep -q "auto-generated by teach hooks install" "$hook_file" 2>/dev/null; then
                _teach_doctor_pass "Hook installed: $hook (flow-cli managed)"
                json_results+=("{\"check\":\"hook_$hook\",\"status\":\"pass\",\"message\":\"installed (managed)\"}")
            else
                _teach_doctor_pass "Hook installed: $hook (custom)"
                json_results+=("{\"check\":\"hook_$hook\",\"status\":\"pass\",\"message\":\"installed (custom)\"}")
            fi
        else
            _teach_doctor_warn "Hook not installed: $hook" "Install with: teach hooks install"
            json_results+=("{\"check\":\"hook_$hook\",\"status\":\"warn\",\"message\":\"not installed\"}")

            # Interactive fix
            if [[ "$fix" == "true" ]]; then
                echo -n "  ${FLOW_COLORS[info]}→${FLOW_COLORS[reset]} Install $hook hook? [Y/n] "
                read -r response
                response=${response:-y}

                if [[ "$response" =~ ^[Yy] ]]; then
                    echo "  ${FLOW_COLORS[muted]}→ teach hooks install${FLOW_COLORS[reset]}"
                    echo "  ${FLOW_COLORS[warning]}⚠${FLOW_COLORS[reset]} Run 'teach hooks install' to install all hooks"
                fi
            fi
        fi
    done
}

# Check cache health (full mode only)
_teach_doctor_check_cache() {
    if [[ "$json" == "false" ]]; then
        echo "Cache Health:"
    fi

    # Check if _freeze directory exists
    if [[ -d "_freeze" ]]; then
        # Calculate cache size
        local cache_size=$(du -sh _freeze 2>/dev/null | cut -f1)
        _teach_doctor_pass "Freeze cache exists ($cache_size)"
        json_results+=("{\"check\":\"cache_exists\",\"status\":\"pass\",\"message\":\"$cache_size\"}")

        # Find last render time
        local last_render=$(find _freeze -type f -name "*.json" -exec stat -f "%m %N" {} \; 2>/dev/null | sort -rn | head -1 | cut -d' ' -f1)

        if [[ -n "$last_render" ]]; then
            local current_time=$(date +%s)
            local age_seconds=$((current_time - last_render))
            local age_days=$((age_seconds / 86400))

            if [[ $age_days -eq 0 ]]; then
                _teach_doctor_pass "Cache is fresh (rendered today)"
                json_results+=("{\"check\":\"cache_freshness\",\"status\":\"pass\",\"message\":\"fresh (today)\"}")
            elif [[ $age_days -lt 7 ]]; then
                _teach_doctor_pass "Cache is recent ($age_days days old)"
                json_results+=("{\"check\":\"cache_freshness\",\"status\":\"pass\",\"message\":\"$age_days days old\"}")
            elif [[ $age_days -lt 30 ]]; then
                _teach_doctor_warn "Cache is aging ($age_days days old)" "Consider re-rendering"
                json_results+=("{\"check\":\"cache_freshness\",\"status\":\"warn\",\"message\":\"$age_days days old\"}")
            else
                _teach_doctor_warn "Cache is stale ($age_days days old)" "Run: quarto render"
                json_results+=("{\"check\":\"cache_freshness\",\"status\":\"warn\",\"message\":\"$age_days days old (stale)\"}")

                # Interactive fix
                if [[ "$fix" == "true" ]]; then
                    echo -n "  ${FLOW_COLORS[info]}→${FLOW_COLORS[reset]} Clear stale cache? [y/N] "
                    read -r response
                    response=${response:-n}

                    if [[ "$response" =~ ^[Yy] ]]; then
                        echo "  ${FLOW_COLORS[muted]}→ rm -rf _freeze${FLOW_COLORS[reset]}"
                        rm -rf _freeze
                        echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Cache cleared"
                    fi
                fi
            fi
        fi

        # Check cache file count
        local cache_files=$(find _freeze -type f 2>/dev/null | wc -l | tr -d ' ')
        if [[ "$json" == "false" && "$quiet" == "false" ]]; then
            echo "    ${FLOW_COLORS[muted]}→ $cache_files cached files${FLOW_COLORS[reset]}"
        fi
    else
        _teach_doctor_warn "No freeze cache found" "Will be created on first render"
        json_results+=("{\"check\":\"cache_exists\",\"status\":\"warn\",\"message\":\"not found\"}")
    fi
}

# Check LaTeX macro health (full mode only)
_teach_doctor_check_macros() {
    if [[ "$json" == "false" ]]; then
        echo "LaTeX Macros:"
    fi

    # Check if macro parser library is available
    if ! typeset -f _flow_discover_macro_sources >/dev/null 2>&1; then
        # Try to source it
        local lib_dir="${0:A:h}"
        if [[ -f "$lib_dir/../macro-parser.zsh" ]]; then
            source "$lib_dir/../macro-parser.zsh" 2>/dev/null
        fi
    fi

    # Check if macro parser functions are available
    if ! typeset -f _flow_discover_macro_sources >/dev/null 2>&1; then
        _teach_doctor_warn "Macro parser library not loaded"
        json_results+=("{\"check\":\"macro_parser\",\"status\":\"warn\",\"message\":\"library not loaded\"}")
        return 0
    fi

    # 1. Check for source files
    local -a sources
    sources=($(cd "$PWD" && _flow_discover_macro_sources 2>/dev/null))

    if (( ${#sources} == 0 )); then
        _teach_doctor_warn "No macro source files found" "Create _macros.qmd or configure in teach-config.yml"
        json_results+=("{\"check\":\"macro_sources\",\"status\":\"warn\",\"message\":\"no sources found\"}")
    else
        local source_names=""
        for src in "${sources[@]}"; do
            [[ -n "$source_names" ]] && source_names+=", "
            source_names+="${src:t}"
        done
        _teach_doctor_pass "Source file(s): $source_names"
        json_results+=("{\"check\":\"macro_sources\",\"status\":\"pass\",\"message\":\"${#sources} source(s) found\"}")
    fi

    # 2. Check config sync (.flow/macros.yml cache)
    local cache_dir=".flow/macros"
    local cache_file="$cache_dir/macros.yml"

    if [[ -f "$cache_file" ]]; then
        # Check if cache is up to date by comparing mtime with source files
        local cache_mtime=0
        if [[ -f "$cache_file" ]]; then
            cache_mtime=$(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null || echo 0)
        fi

        local stale=0
        for src in "${sources[@]}"; do
            if [[ -f "$src" ]]; then
                local src_mtime
                src_mtime=$(stat -f %m "$src" 2>/dev/null || stat -c %Y "$src" 2>/dev/null || echo 0)
                if (( src_mtime > cache_mtime )); then
                    stale=1
                    break
                fi
            fi
        done

        if (( stale )); then
            _teach_doctor_warn "Config cache out of date" "Run: teach macros sync"
            json_results+=("{\"check\":\"macro_cache\",\"status\":\"warn\",\"message\":\"out of date\"}")
        else
            _teach_doctor_pass "Config cache up to date"
            json_results+=("{\"check\":\"macro_cache\",\"status\":\"pass\",\"message\":\"up to date\"}")
        fi
    else
        if (( ${#sources} > 0 )); then
            _teach_doctor_warn "No macro cache found" "Run: teach macros sync"
            json_results+=("{\"check\":\"macro_cache\",\"status\":\"warn\",\"message\":\"not found\"}")
        fi
    fi

    # 3. Check CLAUDE.md for macro documentation
    if [[ -f "CLAUDE.md" ]]; then
        if command grep -qi 'latex.*macro\|macro.*latex\|math.*notation\|notation.*math' CLAUDE.md 2>/dev/null; then
            _teach_doctor_pass "CLAUDE.md has macro documentation"
            json_results+=("{\"check\":\"claudemd_macros\",\"status\":\"pass\",\"message\":\"documented\"}")
        else
            _teach_doctor_warn "CLAUDE.md missing macro section" "Add LaTeX macro documentation for AI assistance"
            json_results+=("{\"check\":\"claudemd_macros\",\"status\":\"warn\",\"message\":\"no macro section\"}")
        fi
    else
        _teach_doctor_warn "CLAUDE.md not found" "Create CLAUDE.md with macro documentation"
        json_results+=("{\"check\":\"claudemd_macros\",\"status\":\"warn\",\"message\":\"file not found\"}")
    fi

    # 4. Check for unused macros (optional warning)
    if (( ${#sources} > 0 )); then
        # Load macros first
        _flow_clear_macros 2>/dev/null
        for src in "${sources[@]}"; do
            _flow_parse_macros "$src" 2>/dev/null
        done

        local macro_count=$(_flow_macro_count 2>/dev/null)

        if (( macro_count > 0 )); then
            local unused
            unused=$(_flow_find_unused_macros "$PWD" 2>/dev/null)
            local unused_count
            unused_count=$(echo "$unused" | grep -c '^' 2>/dev/null || echo 0)
            # Filter out empty lines
            if [[ -z "$unused" ]]; then
                unused_count=0
            fi

            if (( unused_count > 0 )); then
                _teach_doctor_warn "$unused_count macro(s) unused in content"
                json_results+=("{\"check\":\"macro_usage\",\"status\":\"warn\",\"message\":\"$unused_count unused\"}")

                # Show unused macros in verbose mode
                if [[ "$quiet" == "false" ]]; then
                    echo "    ${FLOW_COLORS[muted]}→ Unused: $(echo "$unused" | tr '\n' ' ' | sed 's/ $//')${FLOW_COLORS[reset]}"
                fi
            else
                _teach_doctor_pass "All $macro_count macros in use"
                json_results+=("{\"check\":\"macro_usage\",\"status\":\"pass\",\"message\":\"all $macro_count used\"}")
            fi
        else
            if [[ "$quiet" == "false" ]]; then
                echo "    ${FLOW_COLORS[muted]}→ No macros parsed from sources${FLOW_COLORS[reset]}"
            fi
        fi
    fi
}

# Check teaching style configuration (v6.3.0 - Teaching Style Consolidation)
_teach_doctor_check_teaching_style() {
    if [[ "$json" == "false" ]]; then
        echo "Teaching Style:"
    fi

    # Ensure helpers are loaded
    if ! typeset -f _teach_find_style_source >/dev/null 2>&1; then
        _teach_doctor_warn "Teaching style helpers not loaded"
        json_results+=("{\"check\":\"teaching_style\",\"status\":\"warn\",\"message\":\"helpers not loaded\"}")
        return 0
    fi

    local source
    source=$(_teach_find_style_source "." 2>/dev/null)

    if [[ -z "$source" ]]; then
        _teach_doctor_warn "No teaching style configured" "Add teaching_style section to .flow/teach-config.yml"
        json_results+=("{\"check\":\"teaching_style\",\"status\":\"warn\",\"message\":\"not configured\"}")
        return 0
    fi

    # Do NOT use "local path" — shadows ZSH's $path array (tied to $PATH)
    local src_path="${source%%:*}"
    local src_type="${source##*:}"

    case "$src_type" in
        teach-config)
            _teach_doctor_pass "Teaching style in .flow/teach-config.yml"
            json_results+=("{\"check\":\"teaching_style_source\",\"status\":\"pass\",\"message\":\"teach-config.yml\"}")

            # Check key sub-sections
            local approach
            approach=$(_teach_get_style "pedagogical_approach.primary" "." 2>/dev/null)
            if [[ -n "$approach" && "$approach" != "null" ]]; then
                _teach_doctor_pass "Pedagogical approach: $approach"
                json_results+=("{\"check\":\"teaching_style_approach\",\"status\":\"pass\",\"message\":\"$approach\"}")
            fi

            # Check for command overrides
            local overrides
            overrides=$(yq '.teaching_style.command_overrides // ""' ".flow/teach-config.yml" 2>/dev/null)
            if [[ -n "$overrides" && "$overrides" != "null" && "$overrides" != "" ]]; then
                local override_count
                override_count=$(yq '.teaching_style.command_overrides | keys | length' ".flow/teach-config.yml" 2>/dev/null)
                _teach_doctor_pass "Command overrides: $override_count command(s)"
                json_results+=("{\"check\":\"command_overrides\",\"status\":\"pass\",\"message\":\"$override_count commands\"}")
            fi

            # Check if legacy redirect shim exists
            if _teach_style_is_redirect "."; then
                _teach_doctor_pass "Legacy shim detected (redirect active)"
                json_results+=("{\"check\":\"teaching_style_shim\",\"status\":\"pass\",\"message\":\"redirect active\"}")
            elif [[ -f ".claude/teaching-style.local.md" ]]; then
                _teach_doctor_warn "Legacy .claude/teaching-style.local.md exists without redirect" \
                    "Consider migrating to .flow/teach-config.yml or adding _redirect: true"
                json_results+=("{\"check\":\"teaching_style_shim\",\"status\":\"warn\",\"message\":\"no redirect\"}")
            fi
            ;;
        legacy-md)
            # Check if it's a redirect shim
            if _teach_style_is_redirect "."; then
                _teach_doctor_warn "Using redirect shim but .flow/teach-config.yml has no teaching_style" \
                    "Add teaching_style section to .flow/teach-config.yml"
                json_results+=("{\"check\":\"teaching_style_source\",\"status\":\"warn\",\"message\":\"shim without target\"}")
            else
                _teach_doctor_warn "Using legacy .claude/teaching-style.local.md" \
                    "Migrate to .flow/teach-config.yml for unified config"
                json_results+=("{\"check\":\"teaching_style_source\",\"status\":\"warn\",\"message\":\"legacy location\"}")
            fi
            ;;
    esac
}

# Help function for teach doctor
# MOVED to lib/dispatchers/teach-dispatcher.zsh (comprehensive-help branch)
