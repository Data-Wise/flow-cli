# teach-main.zsh - Extracted from teach-dispatcher.zsh
# ============================================================================

_teach_error() {
    local message="$1"
    local recovery="$2"

    echo "❌ teach: $message" >&2
    [[ -n "$recovery" ]] && echo "   $recovery" >&2
    return 1
}


_teach_warn() {
    local message="$1"
    local note="$2"

    echo "⚠️  teach: $message" >&2
    [[ -n "$note" ]] && echo "   $note" >&2
}

# Preflight checks before Scholar invocation

_teach_preflight() {
    local config_file=".flow/teach-config.yml"

    # 1. Check config exists
    if [[ ! -f "$config_file" ]]; then
        _teach_error "No .flow/teach-config.yml found" \
            "Run 'teach init' first or create config manually"
        return 1
    fi

    # 2. Validate config structure (if validator available)
    if typeset -f _teach_validate_config >/dev/null 2>&1; then
        _teach_validate_config "$config_file" --quiet || {
            _teach_warn "Config has validation issues" \
                "Run 'teach status' for details"
        }
    fi

    # 3. Check Scholar section exists (warning only - Scholar will use defaults)
    if typeset -f _teach_has_scholar_config >/dev/null 2>&1; then
        if ! _teach_has_scholar_config "$config_file"; then
            _teach_warn "No 'scholar:' section in config" \
                "Scholar commands will use defaults"
        fi
    elif ! grep -q "^scholar:" "$config_file" 2>/dev/null; then
        _teach_warn "No 'scholar:' section in config" \
            "Scholar commands will use defaults"
    fi

    # 4. Stale config warning (#423)
    if _flow_config_changed 2>/dev/null; then
        _teach_warn "Config changed since last Scholar run" \
            "Run: teach config check"
    fi

    # 5. Legacy file deprecation warning (#423)
    local legacy_style="${FLOW_PROJECT_ROOT:-.}/.claude/teaching-style.local.md"
    if [[ -f "$legacy_style" ]]; then
        local config_path
        config_path=$(_teach_find_config 2>/dev/null)
        if [[ -n "$config_path" ]]; then
            _teach_warn "Deprecated: .claude/teaching-style.local.md" \
                "Scholar now reads from: .flow/teach-config.yml (teaching_style section takes precedence)"
        fi
    fi

    # 6. Check Claude Code available
    if ! command -v claude &>/dev/null; then
        _teach_error "Claude Code CLI not found" \
            "Install: https://claude.ai/code"
        return 1
    fi

    return 0
}

# Build Scholar command from subcommand and args

_teach_build_command() {
    local subcommand="$1"
    shift
    local -a args=("$@")

    # Map subcommand to Scholar command
    local scholar_cmd
    case "$subcommand" in
        lecture)    scholar_cmd="/teaching:lecture" ;;
        slides)     scholar_cmd="/teaching:slides" ;;
        exam)       scholar_cmd="/teaching:exam" ;;
        quiz)       scholar_cmd="/teaching:quiz" ;;
        assignment) scholar_cmd="/teaching:assignment" ;;
        syllabus)   scholar_cmd="/teaching:syllabus" ;;
        rubric)     scholar_cmd="/teaching:rubric" ;;
        feedback)   scholar_cmd="/teaching:feedback" ;;
        demo)       scholar_cmd="/teaching:demo" ;;
        config)     scholar_cmd="/teaching:config" ;;
        solution)   scholar_cmd="/teaching:solution" ;;
        sync)       scholar_cmd="/teaching:sync" ;;
        validate-r) scholar_cmd="/teaching:validate-r" ;;
        *)
            _teach_error "Unknown Scholar command: $subcommand"
            return 1
            ;;
    esac

    # Return the Scholar command with args
    echo "$scholar_cmd ${args[*]}"
}

# Execute Scholar command via Claude
# Usage: _teach_execute <scholar_cmd> [verbose] [subcommand] [topic] [full_command]

_teach_execute() {
    local scholar_cmd="$1"
    local verbose="${2:-false}"
    local subcommand="${3:-}"
    local topic="${4:-}"
    local full_command="${5:-}"

    if [[ "$verbose" == "true" ]]; then
        echo "🔧 Executing: claude --print \"$scholar_cmd\""
        echo ""
    fi

    # Estimate times for different commands
    local estimate=""
    case "$subcommand" in
        exam)       estimate="~30-60s" ;;
        syllabus)   estimate="~45-90s" ;;
        slides)     estimate="~20-40s" ;;
        quiz)       estimate="~15-30s" ;;
        assignment) estimate="~20-40s" ;;
        rubric)     estimate="~15-25s" ;;
        *)          estimate="~15-30s" ;;
    esac

    # Run with spinner if available
    local output
    local exit_code

    if typeset -f _flow_spinner_start >/dev/null 2>&1; then
        _flow_spinner_start "Generating ${subcommand:-content}..." "$estimate"
        output=$(claude --print "$scholar_cmd" 2>&1)
        exit_code=$?
        _flow_spinner_stop
    else
        # Fallback: no spinner
        output=$(claude --print "$scholar_cmd" 2>&1)
        exit_code=$?
    fi

    # Print output
    echo "$output"

    # Run post-generation hooks if successful
    if [[ $exit_code -eq 0 ]]; then
        _teach_post_generation_hooks "$subcommand" "$output" "$topic" "$full_command"
    fi

    return $exit_code
}

# ============================================================================
# POST-GENERATION HOOKS (Full Auto)
# ============================================================================

# Run after Scholar generates content
# - Auto-stage generated files
# - Update .STATUS file
# - Interactive commit workflow (Phase 1 - v5.11.0+)

_teach_post_generation_hooks() {
    local subcommand="$1"
    local output="$2"
    local topic="${3:-}"
    local full_command="${4:-}"

    # Extract generated file paths from output (if Scholar outputs them)
    local -a generated_files=()

    # Look for common patterns in output like:
    # "Created: exams/midterm.md" or "Saved to: quizzes/quiz-1.qmd"
    while IFS= read -r line; do
        if [[ "$line" =~ (Created|Saved|Generated|Wrote)[:\s]+(.+\.(md|qmd|yml|yaml))$ ]]; then
            generated_files+=("${match[2]}")
        fi
    done <<< "$output"

    # Auto-stage generated files
    if [[ ${#generated_files[@]} -gt 0 ]]; then
        for file in "${generated_files[@]}"; do
            if [[ -f "$file" ]]; then
                git add "$file" 2>/dev/null && \
                    echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Staged: $file"
            fi
        done
    fi

    # Update .STATUS if it exists
    local status_file=".STATUS"
    if [[ -f "$status_file" ]]; then
        local today=$(date +%Y-%m-%d)
        local update_line="# Last teach ${subcommand}: ${today}"

        # Append or update the last teach line
        if grep -q "^# Last teach" "$status_file" 2>/dev/null; then
            # Update existing line (macOS sed)
            sed -i '' "s/^# Last teach.*$/${update_line}/" "$status_file" 2>/dev/null || \
            sed -i "s/^# Last teach.*$/${update_line}/" "$status_file" 2>/dev/null
        else
            # Append new line
            echo "" >> "$status_file"
            echo "$update_line" >> "$status_file"
        fi
    fi

    # Show summary
    if [[ ${#generated_files[@]} -gt 0 ]]; then
        echo ""
        echo "${FLOW_COLORS[success]}📝 Generated ${#generated_files[@]} file(s)${FLOW_COLORS[reset]}"

        # Phase 4 (v5.11.0+): Check for teaching mode
        # If teaching mode is enabled, use streamlined auto-commit workflow
        # Otherwise, use Phase 1 interactive workflow
        if _git_in_repo && [[ ${#generated_files[@]} -gt 0 ]]; then
            # Read teaching mode config
            local teaching_mode auto_commit
            teaching_mode=$(yq '.workflow.teaching_mode // false' teach-config.yml 2>/dev/null)
            auto_commit=$(yq '.workflow.auto_commit // false' teach-config.yml 2>/dev/null)

            if [[ "$teaching_mode" == "true" && "$auto_commit" == "true" ]]; then
                # Teaching mode: Streamlined auto-commit workflow
                _teach_auto_commit_workflow "$subcommand" "$topic" "$full_command" "${generated_files[@]}"
            else
                # Standard mode: Interactive workflow (Phase 1)
                _teach_interactive_commit_workflow "$subcommand" "$topic" "$full_command" "${generated_files[@]}"
            fi
        else
            echo "  Next: Review and 'teach deploy' when ready"
        fi
    fi
}

# ============================================================================
# INTERACTIVE COMMIT WORKFLOW (Phase 1 - v5.11.0+)
# ============================================================================

# Interactive commit workflow after content generation
# Usage: _teach_interactive_commit_workflow <subcommand> <topic> <full_command> <file1> [file2...]

_teach_interactive_commit_workflow() {
    local subcommand="$1"
    local topic="$2"
    local full_command="$3"
    shift 3
    local -a files=("$@")

    # Get course info from teach-config.yml
    local course_name semester year
    course_name=$(yq '.course.name // ""' teach-config.yml 2>/dev/null)
    semester=$(yq '.course.semester // ""' teach-config.yml 2>/dev/null)
    year=$(yq '.course.year // ""' teach-config.yml 2>/dev/null)

    # Fallback if config doesn't exist or yq not available
    [[ -z "$course_name" ]] && course_name="Teaching Project"
    [[ -z "$semester" ]] && semester="N/A"
    [[ -z "$year" ]] && year=$(date +%Y)

    # Show next steps prompt
    echo ""
    echo "${FLOW_COLORS[info]}📝 Next steps:${FLOW_COLORS[reset]}"
    echo "   1. Review content (opens in \$EDITOR)"
    echo "   2. Commit to git"
    echo ""

    # Use AskUserQuestion for interactive prompt
    # Note: This is implemented using read for now, will be enhanced with proper AskUserQuestion integration
    echo "${FLOW_COLORS[prompt]}Review and commit this content?${FLOW_COLORS[reset]}"
    echo ""
    echo "  ${FLOW_COLORS[dim]}[1]${FLOW_COLORS[reset]} Review in editor first (Recommended)"
    echo "  ${FLOW_COLORS[dim]}[2]${FLOW_COLORS[reset]} Commit now with auto-generated message"
    echo "  ${FLOW_COLORS[dim]}[3]${FLOW_COLORS[reset]} Skip commit (I'll do it manually)"
    echo ""
    echo -n "${FLOW_COLORS[prompt]}Your choice [1-3]:${FLOW_COLORS[reset]} "

    read -r choice

    case "$choice" in
        1)
            # Review in editor workflow
            _teach_review_then_commit "$subcommand" "$topic" "$full_command" "$course_name" "$semester" "$year" "${files[@]}"
            ;;
        2)
            # Commit now workflow
            _teach_commit_now "$subcommand" "$topic" "$full_command" "$course_name" "$semester" "$year" "${files[@]}"
            ;;
        3|*)
            # Skip commit
            echo ""
            echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} File(s) staged. Commit manually when ready."
            echo "  ${FLOW_COLORS[dim]}Tip: Use 'g commit' or standard git commands${FLOW_COLORS[reset]}"
            ;;
    esac
}

# Review in editor then commit workflow

_teach_review_then_commit() {
    local subcommand="$1"
    local topic="$2"
    local full_command="$3"
    local course_name="$4"
    local semester="$5"
    local year="$6"
    shift 6
    local -a files=("$@")

    echo ""
    echo "${FLOW_COLORS[info]}Opening file(s) in editor...${FLOW_COLORS[reset]}"

    # Determine editor (respect $EDITOR, fallback to nvim/vim/nano)
    local editor="${EDITOR:-nvim}"
    command -v "$editor" &>/dev/null || editor="vim"
    command -v "$editor" &>/dev/null || editor="nano"

    # Open first file in editor (blocking)
    "$editor" "${files[1]}"

    # After editor closes, re-prompt for commit
    echo ""
    echo -n "${FLOW_COLORS[prompt]}Ready to commit? [Y/n]:${FLOW_COLORS[reset]} "
    read -r confirm

    case "$confirm" in
        n|N|no|No|NO)
            echo ""
            echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} File(s) staged. Commit manually when ready."
            ;;
        *)
            # Proceed with commit
            _teach_commit_now "$subcommand" "$topic" "$full_command" "$course_name" "$semester" "$year" "${files[@]}"
            ;;
    esac
}

# Commit now with auto-generated message workflow

_teach_commit_now() {
    local subcommand="$1"
    local topic="$2"
    local full_command="$3"
    local course_name="$4"
    local semester="$5"
    local year="$6"
    shift 6
    local -a files=("$@")

    # Generate commit message using git-helpers
    local commit_msg
    commit_msg=$(_git_teaching_commit_message "$subcommand" "$topic" "$full_command" "$course_name" "$semester" "$year")

    # Show commit message preview
    echo ""
    echo "${FLOW_COLORS[info]}Commit message:${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[dim]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"
    echo "$commit_msg"
    echo "${FLOW_COLORS[dim]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"
    echo ""

    # Commit the staged changes
    if _git_commit_teaching_content "$commit_msg"; then
        echo ""

        # Ask about pushing to remote
        echo -n "${FLOW_COLORS[prompt]}Push to remote? [y/N]:${FLOW_COLORS[reset]} "
        read -r push_confirm

        case "$push_confirm" in
            y|Y|yes|Yes|YES)
                echo ""
                if _git_push_current_branch; then
                    echo ""
                    echo "${FLOW_COLORS[success]}✅ Changes committed and pushed!${FLOW_COLORS[reset]}"
                else
                    echo ""
                    echo "${FLOW_COLORS[warn]}⚠️  Committed locally but push failed${FLOW_COLORS[reset]}"
                    echo "  ${FLOW_COLORS[dim]}Run 'g push' manually when ready${FLOW_COLORS[reset]}"
                fi
                ;;
            *)
                echo ""
                echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Committed locally"
                echo "  ${FLOW_COLORS[dim]}Run 'g push' to push to remote${FLOW_COLORS[reset]}"
                ;;
        esac
    else
        echo ""
        echo "${FLOW_COLORS[error]}✗ Failed to commit${FLOW_COLORS[reset]}"
        echo "  ${FLOW_COLORS[dim]}Check git status and try again${FLOW_COLORS[reset]}"
    fi
}

# ============================================================================
# TEACHING MODE AUTO-COMMIT WORKFLOW (Phase 4 - v5.11.0+)
# ============================================================================

# Auto-commit workflow for teaching mode (streamlined, no prompts)
# Usage: _teach_auto_commit_workflow <subcommand> <topic> <full_command> <file1> [file2...]

_teach_auto_commit_workflow() {
    local subcommand="$1"
    local topic="$2"
    local full_command="$3"
    shift 3
    local -a files=("$@")

    # Get course info from teach-config.yml
    local course_name semester year
    course_name=$(yq '.course.name // ""' teach-config.yml 2>/dev/null)
    semester=$(yq '.course.semester // ""' teach-config.yml 2>/dev/null)
    year=$(yq '.course.year // ""' teach-config.yml 2>/dev/null)

    # Fallback if config doesn't exist or yq not available
    [[ -z "$course_name" ]] && course_name="Teaching Project"
    [[ -z "$semester" ]] && semester="N/A"
    [[ -z "$year" ]] && year=$(date +%Y)

    # Generate commit message using git-helpers
    local commit_msg
    commit_msg=$(_git_teaching_commit_message "$subcommand" "$topic" "$full_command" "$course_name" "$semester" "$year")

    # Show teaching mode indicator
    echo ""
    echo "${FLOW_COLORS[success]}🎓 Teaching Mode: Auto-committing...${FLOW_COLORS[reset]}"

    # Commit the staged changes
    if _git_commit_teaching_content "$commit_msg"; then
        echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Committed: ${FLOW_COLORS[dim]}${subcommand} for ${topic}${FLOW_COLORS[reset]}"

        # Check auto_push setting
        local auto_push
        auto_push=$(yq '.workflow.auto_push // false' teach-config.yml 2>/dev/null)

        if [[ "$auto_push" == "true" ]]; then
            # Auto-push is enabled, but still ask for confirmation (safety)
            echo ""
            echo -n "${FLOW_COLORS[prompt]}Push to remote? [Y/n]:${FLOW_COLORS[reset]} "
            read -r push_confirm

            case "$push_confirm" in
                n|N|no|No|NO)
                    echo ""
                    echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Committed locally"
                    echo "  ${FLOW_COLORS[dim]}Run 'g push' to push to remote${FLOW_COLORS[reset]}"
                    ;;
                *)
                    if _git_push_current_branch; then
                        echo ""
                        echo "${FLOW_COLORS[success]}✅ Committed and pushed!${FLOW_COLORS[reset]}"
                    else
                        echo ""
                        echo "${FLOW_COLORS[warn]}⚠️  Committed locally but push failed${FLOW_COLORS[reset]}"
                    fi
                    ;;
            esac
        else
            # auto_push is false (default), don't ask
            echo "  ${FLOW_COLORS[dim]}Run 'teach deploy' when ready${FLOW_COLORS[reset]}"
        fi
    else
        echo ""
        echo "${FLOW_COLORS[error]}✗ Failed to auto-commit${FLOW_COLORS[reset]}"
        echo "  ${FLOW_COLORS[dim]}Falling back to manual workflow${FLOW_COLORS[reset]}"
    fi
}

# ============================================================================
# GIT CLEANUP WORKFLOW (Phase 3 - v5.11.0+)
# ============================================================================

# Interactive cleanup prompt for uncommitted teaching files
# Usage: _teach_git_cleanup_prompt <file1> [file2...]

_teach_git_cleanup_prompt() {
    local -a files=("$@")

    echo "${FLOW_COLORS[prompt]}Clean up uncommitted changes?${FLOW_COLORS[reset]}"
    echo ""
    echo "  ${FLOW_COLORS[dim]}[1]${FLOW_COLORS[reset]} Commit teaching files (Recommended)"
    echo "  ${FLOW_COLORS[dim]}[2]${FLOW_COLORS[reset]} Stash teaching files"
    echo "  ${FLOW_COLORS[dim]}[3]${FLOW_COLORS[reset]} View diff first"
    echo "  ${FLOW_COLORS[dim]}[4]${FLOW_COLORS[reset]} Leave as-is"
    echo ""
    echo -n "${FLOW_COLORS[prompt]}Your choice [1-4]:${FLOW_COLORS[reset]} "

    read -r choice

    case "$choice" in
        1)
            # Commit teaching files
            _teach_git_commit_files "${files[@]}"
            ;;
        2)
            # Stash teaching files
            _teach_git_stash_files "${files[@]}"
            ;;
        3)
            # View diff then re-prompt
            _teach_git_view_diff "${files[@]}"
            echo ""
            _teach_git_cleanup_prompt "${files[@]}"
            ;;
        4|*)
            # Leave as-is
            echo ""
            echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Files left uncommitted"
            echo "  ${FLOW_COLORS[dim]}Commit manually when ready${FLOW_COLORS[reset]}"
            ;;
    esac
}

# Commit teaching files with auto-generated message

_teach_git_commit_files() {
    local -a files=("$@")

    # Get course info
    local course_name semester year
    course_name=$(yq '.course.name // "Teaching Project"' teach-config.yml 2>/dev/null)
    semester=$(yq '.course.semester // ""' teach-config.yml 2>/dev/null)
    year=$(yq '.course.year // ""' teach-config.yml 2>/dev/null)
    [[ -z "$year" || "$year" == "null" ]] && year=$(date +%Y)

    # Stage files
    for file in "${files[@]}"; do
        git add "$file" 2>/dev/null
    done

    # Generate commit message
    local file_list=$(printf ", %s" "${files[@]}")
    file_list=${file_list:2}  # Remove leading ", "

    local commit_msg="teach: update teaching content

Modified files: $file_list
Course: $course_name ($semester $year)

Generated via: teach status cleanup"

    # Show commit message
    echo ""
    echo "${FLOW_COLORS[info]}Commit message:${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[dim]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"
    echo "$commit_msg"
    echo "${FLOW_COLORS[dim]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"
    echo ""

    # Commit
    if git commit -m "$commit_msg" 2>/dev/null; then
        echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Committed ${#files[@]} file(s)"

        # Offer to push
        echo ""
        echo -n "${FLOW_COLORS[prompt]}Push to remote? [y/N]:${FLOW_COLORS[reset]} "
        read -r push_confirm

        case "$push_confirm" in
            y|Y|yes|Yes|YES)
                if _git_push_current_branch; then
                    echo ""
                    echo "${FLOW_COLORS[success]}✅ Changes committed and pushed!${FLOW_COLORS[reset]}"
                else
                    echo ""
                    echo "${FLOW_COLORS[warn]}⚠️  Committed locally but push failed${FLOW_COLORS[reset]}"
                fi
                ;;
            *)
                echo ""
                echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Committed locally"
                echo "  ${FLOW_COLORS[dim]}Run 'g push' to push to remote${FLOW_COLORS[reset]}"
                ;;
        esac
    else
        echo ""
        echo "${FLOW_COLORS[error]}✗ Failed to commit${FLOW_COLORS[reset]}"
    fi
}

# Stash teaching files

_teach_git_stash_files() {
    local -a files=("$@")

    local stash_msg="Teaching WIP: $(date +%Y-%m-%d)"

    echo ""
    echo "${FLOW_COLORS[info]}Stashing ${#files[@]} file(s)...${FLOW_COLORS[reset]}"

    # Use git stash push with specific files
    if git stash push -m "$stash_msg" -- "${files[@]}" 2>&1; then
        echo ""
        echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Files stashed: $stash_msg"
        echo "  ${FLOW_COLORS[dim]}Restore with: git stash pop${FLOW_COLORS[reset]}"
    else
        echo ""
        echo "${FLOW_COLORS[error]}✗ Failed to stash files${FLOW_COLORS[reset]}"
    fi
}

# View diff for teaching files

_teach_git_view_diff() {
    local -a files=("$@")

    echo ""
    echo "${FLOW_COLORS[info]}Diff for teaching files:${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[dim]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"

    git diff -- "${files[@]}"

    echo "${FLOW_COLORS[dim]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"
}

# Main Scholar wrapper function

_teach_scholar_wrapper() {
    local subcommand="$1"
    shift
    local -a args=()
    local verbose=false
    local topic=""
    local style=""
    local template=""      # v5.14.0 - Task 9: Template selection

    # Parse wrapper-specific flags vs Scholar flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose|-v)
                verbose=true
                shift
                ;;
            --help|-h|help)
                # Show Scholar command help
                _teach_scholar_help "$subcommand"
                return 0
                ;;
            --style)
                # Extract style preset
                shift
                style="$1"
                shift
                ;;
            --style=*)
                # Extract style preset (--style=computational)
                style="${1#*=}"
                shift
                ;;
            --template)
                # Extract template selection (v5.14.0 - Task 9)
                shift
                template="$1"
                shift
                ;;
            --template=*)
                # Extract template selection (--template=detailed)
                template="${1#*=}"
                shift
                ;;
            *)
                # First non-flag arg is typically the topic
                if [[ -z "$topic" && ! "$1" =~ ^-- ]]; then
                    topic="$1"
                fi
                args+=("$1")
                shift
                ;;
        esac
    done

    # Special case: slides --from-lecture (v5.15.0+)
    # Converts lecture .qmd files to RevealJS slides
    if [[ "$subcommand" == "slides" ]]; then
        local from_lecture=""
        local week_num=""
        local optimize=false
        local preview_breaks=false
        local apply_suggestions=false
        local key_concepts=false
        for ((i=1; i<=${#args[@]}; i++)); do
            if [[ "${args[$i]}" == "--from-lecture" ]]; then
                from_lecture="${args[$((i+1))]}"
            elif [[ "${args[$i]}" =~ ^--from-lecture= ]]; then
                from_lecture="${args[$i]#*=}"
            elif [[ "${args[$i]}" == "--week" || "${args[$i]}" == "-w" ]]; then
                week_num="${args[$((i+1))]}"
            elif [[ "${args[$i]}" =~ ^--week= ]]; then
                week_num="${args[$i]#*=}"
            elif [[ "${args[$i]}" =~ ^-w= ]]; then
                week_num="${args[$i]#*=}"
            elif [[ "${args[$i]}" == "--optimize" ]]; then
                optimize=true
            elif [[ "${args[$i]}" == "--preview-breaks" ]]; then
                preview_breaks=true
                optimize=true
            elif [[ "${args[$i]}" == "--apply-suggestions" ]]; then
                apply_suggestions=true
                optimize=true
            elif [[ "${args[$i]}" == "--key-concepts" ]]; then
                key_concepts=true
                optimize=true
            fi
        done

        # If --from-lecture provided OR --week provided (auto-detect lecture files)
        if [[ -n "$from_lecture" ]] || [[ -n "$week_num" ]]; then
            # If --optimize: run slide analysis, optionally preview, then generate
            if [[ "$optimize" == "true" ]]; then
                _teach_slides_optimized "$from_lecture" "$week_num" "$preview_breaks" "$apply_suggestions" "$key_concepts" "${args[@]}"
            else
                _teach_slides_from_lecture "$from_lecture" "$week_num" "${args[@]}"
            fi
            return $?
        fi
    fi

    # ==================================================================
    # PHASE 5: Revision Workflow (v5.13.0+)
    # ==================================================================

    # Check for --revise flag
    local revise_file=""
    for ((i=1; i<=${#args[@]}; i++)); do
        if [[ "${args[$i]}" == "--revise" ]]; then
            revise_file="${args[$((i+1))]}"
            break
        elif [[ "${args[$i]}" =~ ^--revise= ]]; then
            revise_file="${args[$i]#*=}"
            break
        fi
    done

    # If revise mode, run revision workflow
    if [[ -n "$revise_file" ]]; then
        _teach_revise_workflow "$revise_file" || return 1

        # Revision workflow sets TEACH_REVISE_MODE, TEACH_REVISE_FILE, TEACH_REVISE_INSTRUCTIONS
        # These will be used when building the Scholar command
    fi

    # ==================================================================
    # END PHASE 5
    # ==================================================================

    # ==================================================================
    # PHASE 6: Context Integration (v5.13.0+ / v5.14.0 Task 9)
    # ==================================================================

    # Check for --context flag
    local use_context=false
    for arg in "${args[@]}"; do
        if [[ "$arg" == "--context" ]]; then
            use_context=true
            break
        fi
    done

    # Auto-load context if lesson-plan.yml exists (v5.14.0 - Task 9)
    if [[ -f "lesson-plan.yml" ]]; then
        use_context=true
    fi

    # Build context if requested or if lesson-plan.yml exists
    local course_context=""
    if [[ "$use_context" == "true" ]]; then
        course_context=$(_teach_build_context)
    fi

    # ==================================================================
    # END PHASE 6
    # ==================================================================

    # ==================================================================
    # PHASE 1-2: Enhanced Flag Processing (v5.13.0+)
    # ==================================================================

    # 1. Validate content flags for conflicts
    _teach_validate_content_flags "${args[@]}" || return 1

    # 2. Parse topic and week selection flags
    _teach_parse_topic_week "${args[@]}" || return 1

    # ==================================================================
    # PHASE 4: Interactive Mode (v5.13.0+)
    # ==================================================================

    # Check if interactive mode was requested
    local interactive=false
    for arg in "${args[@]}"; do
        if [[ "$arg" == "--interactive" || "$arg" == "-i" ]]; then
            interactive=true
            break
        fi
    done

    # Run interactive wizard if requested
    if [[ "$interactive" == "true" ]]; then
        # Run wizard (it will set TEACH_WEEK and return style)
        local wizard_style
        wizard_style=$(_teach_interactive_wizard "$subcommand" "$topic" "$style") || return 1

        # Use wizard result
        if [[ -z "$style" ]]; then
            style="$wizard_style"
        fi
    fi

    # ==================================================================
    # END PHASE 4
    # ==================================================================

    # ==================================================================
    # PHASE 3: Lesson Plan Integration (v5.13.0+)
    # ==================================================================

    # If week was specified, integrate lesson plan
    if [[ -n "$TEACH_WEEK" ]]; then
        _teach_integrate_lesson_plan "$TEACH_WEEK" "$style" || return 1

        # Use resolved style from lesson plan
        style="$TEACH_RESOLVED_STYLE"

        # topic is already set in TEACH_TOPIC by integrate function
        # but we also want to update the local variable
        topic="$TEACH_TOPIC"
    fi

    # ==================================================================
    # END PHASE 3
    # ==================================================================

    # 3. Resolve content from style preset + overrides
    _teach_resolve_content "$style" "${args[@]}" || return 1

    # 4. Build content instructions for Scholar prompt
    local content_instructions=$(_teach_build_content_instructions)

    # ==================================================================
    # END PHASE 1-2
    # ==================================================================

    # Validate flags BEFORE preflight (fail fast with helpful message)
    _teach_validate_flags "$subcommand" "${args[@]}" || return 1

    # Run preflight checks (includes config validation)
    _teach_preflight || return 1

    # Build and execute Scholar command
    local scholar_cmd
    scholar_cmd=$(_teach_build_command "$subcommand" "${args[@]}") || return 1

    # Append content instructions to Scholar command if present
    if [[ -n "$content_instructions" ]]; then
        # Add content instructions as additional context
        scholar_cmd="$scholar_cmd --instructions \"$content_instructions\""
    fi

    # Append revision instructions (Phase 5)
    if [[ -n "$TEACH_REVISE_INSTRUCTIONS" ]]; then
        scholar_cmd="$scholar_cmd --revise-instructions \"$TEACH_REVISE_INSTRUCTIONS\""
        scholar_cmd="$scholar_cmd --revise-file \"$TEACH_REVISE_FILE\""
    fi

    # Append course context (Phase 6)
    if [[ -n "$course_context" ]]; then
        scholar_cmd="$scholar_cmd --context \"$course_context\""
    fi

    # Append template selection (v5.14.0 - Task 9)
    if [[ -n "$template" ]]; then
        scholar_cmd="$scholar_cmd --template \"$template\""
    fi

    # Auto-resolve teaching prompt (v5.23.0 - Prompt Management)
    if typeset -f _teach_resolve_prompt >/dev/null 2>&1; then
        local prompt_path
        prompt_path=$(_teach_resolve_prompt "$subcommand" 2>/dev/null)
        if [[ -n "$prompt_path" && -f "$prompt_path" ]]; then
            # Build extra vars from current context
            typeset -A _scholar_prompt_vars
            [[ -n "$topic" ]] && _scholar_prompt_vars[TOPIC]="$topic"
            [[ -n "$TEACH_WEEK" ]] && _scholar_prompt_vars[WEEK]="$TEACH_WEEK"
            [[ -n "$style" ]] && _scholar_prompt_vars[STYLE]="$style"

            local rendered_prompt
            rendered_prompt=$(_teach_render_prompt "$prompt_path" _scholar_prompt_vars 2>/dev/null)
            if [[ -n "$rendered_prompt" ]]; then
                scholar_cmd="$scholar_cmd --prompt \"$rendered_prompt\""
            fi
        fi
    fi

    # Config injection (Scholar Config Sync, #423)
    local config_path
    config_path=$(_teach_find_config 2>/dev/null)
    if [[ -n "$config_path" ]]; then
        scholar_cmd="$scholar_cmd --config \"$config_path\""
    fi

    # Build full command string for commit message (v5.11.0+)
    local full_command="teach $subcommand ${args[*]}"

    # Execute with subcommand for spinner message
    _teach_execute "$scholar_cmd" "$verbose" "$subcommand" "$topic" "$full_command"
}

# ============================================================================
# SLIDES FROM LECTURE (v5.15.0+)
# Converts lecture .qmd files to RevealJS slides
# ============================================================================

# Generate slides from lecture .qmd files
# Usage: _teach_slides_from_lecture [lecture_file] [week_num] [extra_args...]

_teach_dispatcher_help() {
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

    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ teach - Teaching Workflow Commands            │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}teach lecture${_C_NC} <topic>     Generate lecture notes
  ${_C_CYAN}teach deploy${_C_NC}              Deploy course website
  ${_C_CYAN}teach validate${_C_NC} --render   Full validation
  ${_C_CYAN}teach status${_C_NC}              Project dashboard
  ${_C_CYAN}teach doctor${_C_NC} --fix        Fix dependency issues

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} teach init \"STAT 440\"           ${_C_DIM}# Initialize project${_C_NC}
  ${_C_DIM}\$${_C_NC} teach lecture \"Intro\" --week 1  ${_C_DIM}# Create lecture${_C_NC}
  ${_C_DIM}\$${_C_NC} teach validate --render           ${_C_DIM}# Full validation${_C_NC}
  ${_C_DIM}\$${_C_NC} teach deploy --preview            ${_C_DIM}# Preview deploy${_C_NC}

  ${_C_DIM}── Workflows ──${_C_NC}
  ${_C_DIM}Setup:${_C_NC}   teach init → teach config → teach analyze → teach deploy
  ${_C_DIM}Content:${_C_NC} teach exam \"Regression\" → teach rubric → teach feedback
  ${_C_DIM}Weekly:${_C_NC}  teach week → teach lec \"ANOVA\" --week 5 → teach sl 5

${_C_BLUE}📋 SETUP & CONFIGURATION${_C_NC}:
  ${_C_CYAN}teach init${_C_NC} [name]         Initialize teaching project
  ${_C_CYAN}teach config${_C_NC}              Edit configuration
  ${_C_CYAN}teach config check${_C_NC}        Validate config (pre-flight)
  ${_C_CYAN}teach config diff${_C_NC}         Compare prompts vs defaults
  ${_C_CYAN}teach config show${_C_NC}         Show resolved 4-layer config
  ${_C_CYAN}teach config scaffold${_C_NC}     Copy default prompts for customization
  ${_C_CYAN}teach doctor${_C_NC}              Health checks (--fix to auto-fix)
  ${_C_CYAN}teach hooks${_C_NC}               Git hook management
  ${_C_CYAN}teach dates${_C_NC}               Date management
  ${_C_CYAN}teach plan${_C_NC}                Lesson plan CRUD
  ${_C_CYAN}teach templates${_C_NC}           Template management
  ${_C_CYAN}teach macros${_C_NC}              LaTeX macro management
  ${_C_CYAN}teach prompt${_C_NC}              AI prompt management
  ${_C_CYAN}teach style${_C_NC}               Teaching style management
  ${_C_CYAN}teach migrate-config${_C_NC}      Extract lesson plans
  ${_C_CYAN}teach sync${_C_NC}                Sync config to Scholar format

${_C_BLUE}📋 CONTENT CREATION${_C_NC} ${_C_DIM}(Scholar AI)${_C_NC}:
  ${_C_CYAN}teach lecture${_C_NC} <topic>     Generate lecture notes
  ${_C_CYAN}teach slides${_C_NC} <topic>      Presentation slides
  ${_C_CYAN}teach exam${_C_NC} <topic>        Comprehensive exam
  ${_C_CYAN}teach quiz${_C_NC} <topic>        Quiz questions
  ${_C_CYAN}teach assignment${_C_NC} <topic>  Homework assignment
  ${_C_CYAN}teach syllabus${_C_NC} <course>   Course syllabus
  ${_C_CYAN}teach rubric${_C_NC} <assign>     Grading rubric
  ${_C_CYAN}teach feedback${_C_NC} <work>     Student feedback
  ${_C_CYAN}teach solution${_C_NC} <topic>    Generate solution key

${_C_BLUE}📋 VALIDATION & QUALITY${_C_NC}:
  ${_C_CYAN}teach analyze${_C_NC} <file>      Validate prerequisites
  ${_C_CYAN}teach validate${_C_NC} [files]    Validate .qmd files
  ${_C_CYAN}teach validate-r${_C_NC}          Validate R code in .qmd files
  ${_C_CYAN}teach profiles${_C_NC}            Profile management
  ${_C_CYAN}teach cache${_C_NC}               Cache operations
  ${_C_CYAN}teach clean${_C_NC}               Delete _freeze/ + _site/

${_C_BLUE}📋 DEPLOYMENT & MANAGEMENT${_C_NC}:
  ${_C_CYAN}teach deploy${_C_NC} [files]      Deploy course website
  ${_C_CYAN}teach status${_C_NC}              Project dashboard
  ${_C_CYAN}teach week${_C_NC}                Current week info
  ${_C_CYAN}teach backup${_C_NC}              Backup management
  ${_C_CYAN}teach archive${_C_NC}             Archive semester

${_C_MAGENTA}💡 TIP${_C_NC}: Content generation requires Scholar plugin
  ${_C_DIM}teach lecture → scholar:teaching:lecture (AI-powered)${_C_NC}

  ${_C_BOLD}Shortcuts${_C_NC} ${_C_DIM}(type shorter aliases for any command)${_C_NC}:
  ${_C_DIM}  Setup:    i=init  c=config  doc=doctor  hook=hooks${_C_NC}
  ${_C_DIM}  Content:  lec=lecture  sl=slides  e=exam  q=quiz  sol=solution${_C_NC}
  ${_C_DIM}            hw=assignment  syl=syllabus  rb=rubric  fb=feedback${_C_NC}
  ${_C_DIM}  Quality:  val=validate  vr=validate-r  concept=analyze  prof=profiles  cl=clean${_C_NC}
  ${_C_DIM}  Manage:   d=deploy  s=status  w=week  bk=backup  a=archive${_C_NC}
  ${_C_DIM}  Tools:    pl=plan  tmpl=templates  m=macros  pr=prompt  st=style  migrate=migrate-config${_C_NC}

${_C_DIM}📚 See also:${_C_NC}
  ${_C_CYAN}teach map${_C_NC} - Full ecosystem map (flow-cli + Scholar + Craft)
  ${_C_CYAN}qu${_C_NC} - Quarto commands (qu preview, qu render)
  ${_C_CYAN}g${_C_NC} - Git commands (g status, g push)
  ${_C_CYAN}work${_C_NC} - Session management
"
}

# Detect teaching ecosystem tool availability (v6.6.0)

teach() {
    # Help check FIRST (all three forms)
    if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" || -z "$1" ]]; then
        _teach_dispatcher_help
        return 0
    fi

    local cmd="$1"
    shift

    # Health indicator dot (from last doctor run)
    local _health_dot
    _health_dot=$(_teach_health_dot 2>/dev/null)
    if [[ -n "$_health_dot" ]]; then
        echo -e "${_health_dot} teach ${cmd}" >&2
    fi

    case "$cmd" in
        # ============================================
        # SCHOLAR WRAPPERS (invoke Claude + Scholar)
        # ============================================
        lecture|lec)
            case "$1" in
                --help|-h|help) _teach_lecture_help; return 0 ;;
                *) _teach_scholar_wrapper "lecture" "$@" ;;
            esac
            ;;

        slides|sl)
            case "$1" in
                --help|-h|help) _teach_slides_help; return 0 ;;
                *) _teach_scholar_wrapper "slides" "$@" ;;
            esac
            ;;

        exam|e)
            case "$1" in
                --help|-h|help) _teach_exam_help; return 0 ;;
                *) _teach_scholar_wrapper "exam" "$@" ;;
            esac
            ;;

        quiz|q)
            case "$1" in
                --help|-h|help) _teach_quiz_help; return 0 ;;
                *) _teach_scholar_wrapper "quiz" "$@" ;;
            esac
            ;;

        assignment|hw)
            case "$1" in
                --help|-h|help) _teach_assignment_help; return 0 ;;
                *) _teach_scholar_wrapper "assignment" "$@" ;;
            esac
            ;;

        syllabus|syl)
            case "$1" in
                --help|-h|help) _teach_syllabus_help; return 0 ;;
                *) _teach_scholar_wrapper "syllabus" "$@" ;;
            esac
            ;;

        rubric|rb)
            case "$1" in
                --help|-h|help) _teach_rubric_help; return 0 ;;
                *) _teach_scholar_wrapper "rubric" "$@" ;;
            esac
            ;;

        feedback|fb)
            case "$1" in
                --help|-h|help) _teach_feedback_help; return 0 ;;
                *) _teach_scholar_wrapper "feedback" "$@" ;;
            esac
            ;;

        demo)
            _teach_scholar_wrapper "demo" "$@"
            ;;

        solution|sol)
            _teach_scholar_wrapper "solution" "$@"
            ;;

        sync)
            _teach_scholar_wrapper "sync" "$@"
            ;;

        validate-r|vr)
            _teach_scholar_wrapper "validate-r" "$@"
            ;;

        # ============================================
        # LOCAL COMMANDS (no Claude needed)
        # ============================================
        init|i)
            case "$1" in
                --help|-h|help) _teach_init_help; return 0 ;;
                *) _teach_init "$@" ;;
            esac
            ;;

        # Shortcuts for common operations
        deploy|d)
            case "$1" in
                --help|-h|help) _teach_deploy_enhanced_help; return 0 ;;
                *) _teach_deploy_enhanced "$@" ;;
            esac
            ;;

        archive|a)
            # v5.14.0 (Task 5): Use new backup system
            _teach_archive_command "$@"
            ;;

        # Config management
        config|c)
            case "$1" in
                --help|-h|help) _teach_config_help; return 0 ;;
                check)     _teach_scholar_wrapper "config" "validate" "--strict" ;;
                diff)      _teach_scholar_wrapper "config" "diff" "${@:2}" ;;
                show)      _teach_scholar_wrapper "config" "show" "${@:2}" ;;
                scaffold)  _teach_scholar_wrapper "config" "scaffold" "${@:2}" ;;
                --view) _teach_config_view "$@" ;;
                --cat) _teach_config_cat "$@" ;;
                *) _teach_config_edit "$@" ;;
            esac
            ;;

        # Status/info
        status|s)
            _teach_show_status "$@"
            ;;

        week|w)
            _teach_show_week "$@"
            ;;

        # Date management
        dates)
            _teach_dates_dispatcher "$@"
            ;;

        # Backup management (v5.14.0 - Task 5)
        backup|bk)
            _teach_backup_command "$@"
            ;;

        # Lesson plan management (v5.22.0 - Issue #278)
        plan|pl)
            case "$1" in
                --help|-h|help) _teach_plan_help; return 0 ;;
                *) _teach_plan "$@" ;;
            esac
            ;;

        # Migration (v5.20.0 - Lesson Plan Extraction #298)
        migrate-config|migrate)
            case "$1" in
                --help|-h|help) _teach_migrate_help; return 0 ;;
                *) _teach_migrate_config "$@" ;;
            esac
            ;;

        # Health check (v5.14.0 - Task 2)
        doctor|doc)
            case "$1" in
                --help|-h|help) _teach_doctor_help; return 0 ;;
                *) _teach_doctor "$@" ;;
            esac
            ;;

        # Validation (Week 2-3: Validation Commands)
        validate|val|v)
            case "$1" in
                --help|-h|help) _teach_validate_help; return 0 ;;
                *) teach-validate "$@" ;;
            esac
            ;;

        # Concept analysis (Phase 0: teach analyze)
        analyze|concept|concepts)
            case "$1" in
                --help|-h|help)
                    _teach_analyze_help
                    return 0
                    ;;
                *)
                    _teach_analyze "$@"
                    ;;
            esac
            ;;

        # Cache management (Week 3-4: Cache Management)
        cache|c)
            case "$1" in
                --help|-h|help) _teach_cache_help; return 0 ;;
                *) teach_cache "$@" ;;
            esac
            ;;

        # Clean command (delete _freeze/ + _site/)
        clean|cl)
            case "$1" in
                --help|-h|help) _teach_clean_help; return 0 ;;
                *) teach_clean "$@" ;;
            esac
            ;;

        # Profile management (Phase 2 - Wave 1: Profile Management)
        profiles|profile|prof)
            case "$1" in
                --help|-h|help) _teach_profiles_help; return 0 ;;
                *) _teach_profiles "$@" ;;
            esac
            ;;

        # Git hooks management (v5.14.0 - PR #277 Task 2)
        hooks|hook)
            local subcmd="$1"
            shift

            case "$subcmd" in
                install|i)
                    _install_git_hooks "$@"
                    ;;
                upgrade|up|u)
                    _upgrade_git_hooks "$@"
                    ;;
                uninstall|remove|rm)
                    _uninstall_git_hooks "$@"
                    ;;
                status|check|s)
                    _check_all_hooks "$@"
                    ;;
                help|--help|-h)
                    _teach_hooks_help
                    ;;
                *)
                    _teach_error "Unknown hooks command: $subcmd"
                    echo ""
                    _teach_hooks_help
                    return 1
                    ;;
            esac
            ;;

        # Template management (v5.20.0 - Template Support #301)
        templates|tmpl|tpl)
            case "$1" in
                --help|-h|help) _teach_templates_help; return 0 ;;
                *) _teach_templates "$@" ;;
            esac
            ;;

        # LaTeX macro management (v5.21.0 - LaTeX Macro Support)
        macros|macro|m)
            case "$1" in
                --help|-h|help) _teach_macros_help; return 0 ;;
                *) _teach_macros "$@" ;;
            esac
            ;;

        # AI prompt management (v5.23.0 - Prompt Management)
        prompt|pr)
            case "$1" in
                --help|-h|help) _teach_prompt_help; return 0 ;;
                *) _teach_prompt "$@" ;;
            esac
            ;;

        # Teaching style management (v6.3.0 - Teaching Style Consolidation)
        style|st)
            case "$1" in
                --help|-h|help) _teach_style_help; return 0 ;;
                *) _teach_style "$@" ;;
            esac
            ;;

        # Ecosystem map (v6.6.0 - Unified Discovery)
        map)
            _teach_map "$@"
            ;;

        *)
            _teach_error "Unknown command: $cmd"
            echo ""
            _teach_dispatcher_help
            return 1
            ;;
    esac
}

# Show teaching project status (Enhanced Dashboard - Week 8)

