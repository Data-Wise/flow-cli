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
    if [[ "$json" == "false" ]]; then
        echo ""
    fi
    _teach_doctor_check_hooks
    if [[ "$json" == "false" ]]; then
        echo ""
    fi
    _teach_doctor_check_cache

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

    # R packages (if R is available)
    if command -v R &>/dev/null; then
        _teach_doctor_check_r_packages
    fi

    # Quarto extensions
    _teach_doctor_check_quarto_extensions
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

# Check R packages
_teach_doctor_check_r_packages() {
    if [[ "$json" == "false" ]]; then
        echo ""
        echo "R Packages:"
    fi

    # Common teaching packages
    local -a packages=(
        "ggplot2"
        "dplyr"
        "tidyr"
        "knitr"
        "rmarkdown"
    )

    for pkg in "${packages[@]}"; do
        if R --slave --quiet -e "if (!require('$pkg', quietly=TRUE)) quit(status=1)" &>/dev/null; then
            _teach_doctor_pass "R package: $pkg"
            json_results+=("{\"check\":\"r_pkg_$pkg\",\"status\":\"pass\",\"message\":\"installed\"}")
        else
            _teach_doctor_warn "R package '$pkg' not found (optional)" "Install: install.packages('$pkg')"
            json_results+=("{\"check\":\"r_pkg_$pkg\",\"status\":\"warn\",\"message\":\"not found\"}")

            # Interactive fix
            if [[ "$fix" == "true" ]]; then
                echo -n "  ${FLOW_COLORS[info]}→${FLOW_COLORS[reset]} Install R package '$pkg'? [y/N] "
                read -r response
                response=${response:-n}

                if [[ "$response" =~ ^[Yy] ]]; then
                    echo "  ${FLOW_COLORS[muted]}→ Rscript -e \"install.packages('$pkg')\"${FLOW_COLORS[reset]}"
                    if Rscript -e "install.packages('$pkg', repos='https://cran.rstudio.com/')" >/dev/null 2>&1; then
                        echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} $pkg installed"
                    else
                        echo "  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} Failed to install $pkg"
                    fi
                fi
            fi
        fi
    done
}

# Check Quarto extensions
_teach_doctor_check_quarto_extensions() {
    if [[ ! -d "_extensions" ]]; then
        return 0  # No extensions directory, skip check
    fi

    if [[ "$json" == "false" ]]; then
        echo ""
        echo "Quarto Extensions:"
    fi

    # Count installed extensions
    local ext_count=$(find _extensions -mindepth 2 -maxdepth 2 -type d 2>/dev/null | wc -l | tr -d ' ')

    if [[ "$ext_count" -gt 0 ]]; then
        _teach_doctor_pass "$ext_count Quarto extensions installed"
        json_results+=("{\"check\":\"quarto_extensions\",\"status\":\"pass\",\"message\":\"$ext_count installed\"}")

        # List extensions
        if [[ "$json" == "false" && "$quiet" == "false" ]]; then
            find _extensions -mindepth 2 -maxdepth 2 -type d 2>/dev/null | while read ext_dir; do
                local ext_name=$(basename "$(dirname "$ext_dir")")/$(basename "$ext_dir")
                echo "    ${FLOW_COLORS[muted]}→ $ext_name${FLOW_COLORS[reset]}"
            done
        fi
    else
        _teach_doctor_warn "No Quarto extensions found" "Install with: quarto add <extension>"
        json_results+=("{\"check\":\"quarto_extensions\",\"status\":\"warn\",\"message\":\"none found\"}")
    fi
}

# Check hook status
_teach_doctor_check_hooks() {
    if [[ "$json" == "false" ]]; then
        echo ""
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

# Check cache health
_teach_doctor_check_cache() {
    if [[ "$json" == "false" ]]; then
        echo ""
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
    echo "  Comprehensive health check for teaching environment:"
    echo ""
    echo "  ${FLOW_COLORS[header]}1. Dependencies${FLOW_COLORS[reset]}"
    echo "    • Required: yq, git, quarto, gh"
    echo "    • Optional: examark, claude"
    echo "    • R packages: ggplot2, dplyr, tidyr, knitr, rmarkdown"
    echo "    • Quarto extensions"
    echo ""
    echo "  ${FLOW_COLORS[header]}2. Project Configuration${FLOW_COLORS[reset]}"
    echo "    • .flow/teach-config.yml exists and validates"
    echo "    • Course name, semester, dates configured"
    echo ""
    echo "  ${FLOW_COLORS[header]}3. Git Setup${FLOW_COLORS[reset]}"
    echo "    • Repository initialized"
    echo "    • Draft and production branches exist"
    echo "    • Remote configured"
    echo "    • Working tree clean"
    echo ""
    echo "  ${FLOW_COLORS[header]}4. Scholar Integration${FLOW_COLORS[reset]}"
    echo "    • Claude Code available"
    echo "    • Scholar skills accessible"
    echo "    • Lesson plan file (optional)"
    echo ""
    echo "  ${FLOW_COLORS[header]}5. Git Hooks${FLOW_COLORS[reset]}"
    echo "    • pre-commit, pre-push, prepare-commit-msg"
    echo "    • Hook version tracking"
    echo ""
    echo "  ${FLOW_COLORS[header]}6. Cache Health${FLOW_COLORS[reset]}"
    echo "    • _freeze/ directory size"
    echo "    • Last render time"
    echo "    • Cache file count"
    echo ""
    echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
    echo "  teach doctor                # Full health check"
    echo "  teach doctor --quiet        # Only show problems"
    echo "  teach doctor --fix          # Interactive fix mode"
    echo "  teach doctor --json         # JSON output for CI/CD"
    echo ""
    echo "${FLOW_COLORS[bold]}EXIT STATUS${FLOW_COLORS[reset]}"
    echo "  0    All checks passed (warnings OK)"
    echo "  1    One or more checks failed"
    echo ""
}
