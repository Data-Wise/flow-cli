# ============================================================================
# Enhanced Status Dashboard for Quarto Workflow (Week 8)
# ============================================================================
# Provides a comprehensive project overview with boxed layout
#
# Features:
# - Cache status (freeze directory info)
# - Hook status (pre-commit, pre-push with versions)
# - Deployment status (last deploy, open PRs)
# - Index health (linked lectures/assignments)
# - Backup summary (count, size, last backup)
# - Performance metrics (render times)
#
# Dependencies:
# - lib/cache-helpers.zsh (_cache_status)
# - lib/backup-helpers.zsh (_teach_count_backups)
# - git, yq, gh CLI (optional)
# ============================================================================

# Format time ago from timestamp
_status_time_ago() {
    local timestamp="$1"
    local now=$(date +%s)
    local diff=$((now - timestamp))

    if [[ $diff -lt 60 ]]; then
        echo "${diff}s ago"
    elif [[ $diff -lt 3600 ]]; then
        local mins=$((diff / 60))
        echo "${mins}m ago"
    elif [[ $diff -lt 86400 ]]; then
        local hours=$((diff / 3600))
        echo "${hours}h ago"
    else
        local days=$((diff / 86400))
        echo "${days}d ago"
    fi
}

# Format box line with proper padding
_status_box_line() {
    local icon="$1"
    local label="$2"
    local value="$3"
    local max_width=65

    # Strip ANSI codes for length calculation
    local value_clean=$(echo "$value" | sed 's/\x1b\[[0-9;]*m//g')
    local label_len=$((${#icon} + ${#label} + 2))  # icon + space + label + colon + space
    local value_len=${#value_clean}
    local padding=$((max_width - label_len - value_len))

    # Ensure minimum padding
    if [[ $padding -lt 1 ]]; then
        padding=1
    fi

    printf "│  %s %s %s%*s│\n" "$icon" "$label:" "$value" "$padding" ""
}

# Enhanced status dashboard
_teach_show_status_dashboard() {
    local config_file=".flow/teach-config.yml"

    if [[ ! -f "$config_file" ]]; then
        _flow_log_error "Not a teaching project (no .flow/teach-config.yml)"
        return 1
    fi

    # ============================================
    # GATHER STATUS DATA
    # ============================================

    # Course info
    local course="Unknown"
    local semester="Unknown"
    local year=""
    if command -v yq >/dev/null 2>&1; then
        course=$(yq '.course.name // "Unknown"' "$config_file" 2>/dev/null)
        semester=$(yq '.course.semester // "Unknown"' "$config_file" 2>/dev/null)
        year=$(yq '.course.year // ""' "$config_file" 2>/dev/null)
    fi

    # Project path
    local project_path="${PWD/#$HOME/~}"

    # Cache status
    local cache_label="No freeze cache"
    if typeset -f _cache_status >/dev/null 2>&1; then
        local -A cache_info
        while IFS='=' read -r key value; do
            cache_info[$key]="$value"
        done < <(_cache_status "$PWD" 2>/dev/null)

        if [[ "${cache_info[status]}" == "exists" ]]; then
            cache_label="Freeze ✓ (${cache_info[size_human]}, ${cache_info[file_count]} files)"
        fi
    fi

    # Hook status
    local hook_label="Not installed (run 'teach hooks install')"
    if [[ -f ".git/hooks/pre-commit" ]]; then
        local hook_version=""
        if grep -q "# Version:" ".git/hooks/pre-commit" 2>/dev/null; then
            hook_version=$(grep "# Version:" ".git/hooks/pre-commit" | head -1 | awk '{print $3}')
            hook_label="Pre-commit ✓ (v${hook_version})"
        else
            hook_label="Pre-commit ✓"
        fi

        # Check for pre-push hook
        if [[ -f ".git/hooks/pre-push" ]]; then
            if grep -q "# Version:" ".git/hooks/pre-push" 2>/dev/null; then
                local push_version=$(grep "# Version:" ".git/hooks/pre-push" | head -1 | awk '{print $3}')
                hook_label="${hook_label}, Pre-push ✓ (v${push_version})"
            else
                hook_label="${hook_label}, Pre-push ✓"
            fi
        fi
    fi

    # Deployment status
    local deploy_label="No deployments found"
    if _git_in_repo; then
        # Check for deployment tags first
        local last_deploy_tag=$(git tag -l "deploy-*" --sort=-version:refname 2>/dev/null | head -1)
        if [[ -n "$last_deploy_tag" ]]; then
            local deploy_time=$(git log -1 --format=%ct "$last_deploy_tag" 2>/dev/null)
            if [[ -n "$deploy_time" && "$deploy_time" -gt 0 ]]; then
                local time_ago=$(_status_time_ago $deploy_time)
                deploy_label="Last $time_ago ($last_deploy_tag)"
            else
                deploy_label="Last: $last_deploy_tag"
            fi
        else
            # Fallback to commit message search
            local last_deploy_commit=$(git log --all --grep="deploy" --grep="Publish" -i --format="%ct" --max-count=1 2>/dev/null)
            if [[ -n "$last_deploy_commit" && "$last_deploy_commit" -gt 0 ]]; then
                local time_ago=$(_status_time_ago $last_deploy_commit)
                deploy_label="Last $time_ago"
            fi
        fi
    fi

    # Index health (content count)
    local lecture_count=0
    local assignment_count=0
    [[ -d "lectures" ]] && lecture_count=$(find lectures -maxdepth 2 \( -name "*.md" -o -name "*.qmd" \) 2>/dev/null | wc -l | tr -d ' ')
    [[ -d "assignments" ]] && assignment_count=$(find assignments -maxdepth 2 \( -name "*.md" -o -name "*.qmd" \) 2>/dev/null | wc -l | tr -d ' ')

    local index_label="No content indexed yet"
    if [[ $lecture_count -gt 0 || $assignment_count -gt 0 ]]; then
        index_label="${lecture_count} lectures, ${assignment_count} assignments linked"
    fi

    # Backup summary
    local backup_label="No backups yet"
    if typeset -f _teach_count_backups >/dev/null 2>&1; then
        local total_backups=0
        local total_size=0

        for dir in exams lectures slides assignments quizzes syllabi rubrics; do
            if [[ -d "$dir" ]]; then
                for content_dir in "$dir"/*(/N); do
                    if [[ -d "$content_dir" ]]; then
                        local count=$(_teach_count_backups "$content_dir" 2>/dev/null)
                        ((total_backups += count))

                        if [[ -d "$content_dir/.backups" ]]; then
                            local backup_size=$(du -sk "$content_dir/.backups" 2>/dev/null | awk '{print $1}')
                            ((total_size += backup_size))
                        fi
                    fi
                done
            fi
        done

        if [[ $total_backups -gt 0 ]]; then
            local size_mb=$((total_size / 1024))
            backup_label="${total_backups} backups (${size_mb}MB)"
        fi
    fi

    # Performance metrics
    local perf_label=""
    local perf_log=".teach/performance-log.json"
    if [[ -f "$perf_log" ]] && command -v jq >/dev/null 2>&1; then
        local last_render=$(jq -r '.last_render.duration // 0' "$perf_log" 2>/dev/null)
        local avg_render=$(jq -r '.average_render.duration // 0' "$perf_log" 2>/dev/null)

        if [[ "$last_render" != "0" && "$avg_render" != "0" ]]; then
            perf_label="Last render ${last_render}s (avg ${avg_render}s)"
        fi
    elif typeset -f _cache_status >/dev/null 2>&1; then
        # Fallback: show last render time from cache
        local -A cache_info
        while IFS='=' read -r key value; do
            cache_info[$key]="$value"
        done < <(_cache_status "$PWD" 2>/dev/null)

        if [[ "${cache_info[last_render]}" != "never" ]]; then
            perf_label="Last render ${cache_info[last_render]}"
        fi
    fi

    # ============================================
    # DISPLAY DASHBOARD
    # ============================================

    echo ""
    echo "┌─────────────────────────────────────────────────────────────────┐"

    # Header with course info
    if [[ -n "$year" && "$year" != "null" ]]; then
        local header_text="$course - $semester $year"
    else
        local header_text="$course - $semester"
    fi
    # Center-align header
    local header_len=$((${#header_text} + 4))  # Add 4 for bold ANSI codes
    local header_padding=$(((65 - ${#header_text}) / 2))
    printf "│%*s${FLOW_COLORS[bold]}%s${FLOW_COLORS[reset]}%*s│\n" "$header_padding" "" "$header_text" "$((65 - header_padding - ${#header_text}))" ""

    echo "├─────────────────────────────────────────────────────────────────┤"

    # Status lines
    _status_box_line "📁" "Project" "$project_path"
    _status_box_line "🔧" "Quarto" "$cache_label"
    _status_box_line "🎣" "Hooks" "$hook_label"
    _status_box_line "🚀" "Deployments" "$deploy_label"
    _status_box_line "📚" "Index" "$index_label"
    _status_box_line "💾" "Backups" "$backup_label"

    # Performance (optional)
    if [[ -n "$perf_label" ]]; then
        _status_box_line "⏱️ " "Performance" "$perf_label"
    fi

    # Concept analysis status (Phase 1)
    local concept_label="Not analyzed (run 'teach analyze')"
    local concepts_file=".teach/concepts.json"
    if [[ -f "$concepts_file" ]] && command -v jq >/dev/null 2>&1; then
        local concept_count=$(jq '.metadata.total_concepts // 0' "$concepts_file" 2>/dev/null)
        local week_count=$(jq '.metadata.weeks // 0' "$concepts_file" 2>/dev/null)
        local last_updated=$(jq -r '.metadata.last_updated // ""' "$concepts_file" 2>/dev/null)

        if [[ "$concept_count" -gt 0 ]]; then
            # Calculate time since last analysis
            local analysis_label=""
            if [[ -n "$last_updated" && "$last_updated" != "null" ]]; then
                local analysis_ts=$(date -jf "%Y-%m-%dT%H:%M:%SZ" "$last_updated" +%s 2>/dev/null || \
                                   date -d "$last_updated" +%s 2>/dev/null)
                if [[ -n "$analysis_ts" && "$analysis_ts" -gt 0 ]]; then
                    analysis_label=" ($(_status_time_ago $analysis_ts))"
                fi
            fi
            concept_label="${concept_count} concepts, ${week_count} weeks${analysis_label}"
        fi
    fi
    _status_box_line "📊" "Concepts" "$concept_label"

    echo "└─────────────────────────────────────────────────────────────────┘"
    echo ""

    # ============================================
    # ADDITIONAL STATUS SECTIONS (Condensed)
    # ============================================

    # Branch status
    local branch=$(git branch --show-current 2>/dev/null)
    if [[ -n "$branch" ]]; then
        echo "${FLOW_COLORS[bold]}Current Branch:${FLOW_COLORS[reset]} $branch"
        if [[ "$branch" == "draft" ]]; then
            echo "  ${FLOW_COLORS[success]}✓ Safe to edit (draft branch)${FLOW_COLORS[reset]}"
        elif [[ "$branch" == "production" ]]; then
            echo "  ${FLOW_COLORS[warning]}⚠ On production - changes are live!${FLOW_COLORS[reset]}"
        fi
        echo ""
    fi

    # Quick health check
    local has_issues=false
    if typeset -f _teach_validate_config >/dev/null 2>&1; then
        if ! _teach_validate_config "$config_file" --quiet 2>/dev/null; then
            echo "${FLOW_COLORS[warning]}⚠ Config validation issues detected${FLOW_COLORS[reset]}"
            echo "  Run ${FLOW_COLORS[bold]}teach doctor${FLOW_COLORS[reset]} for details"
            echo ""
            has_issues=true
        fi
    fi

    # Git uncommitted changes (teaching content only)
    if _git_in_repo && typeset -f _git_teaching_files >/dev/null 2>&1; then
        local -a teaching_files=()
        while IFS= read -r file; do
            [[ -n "$file" ]] && teaching_files+=("$file")
        done < <(_git_teaching_files 2>/dev/null)

        if [[ ${#teaching_files[@]} -gt 0 ]]; then
            echo "${FLOW_COLORS[warning]}⚠ Uncommitted changes:${FLOW_COLORS[reset]} ${#teaching_files[@]} teaching files"
            echo "  Run ${FLOW_COLORS[bold]}g status${FLOW_COLORS[reset]} to review"
            echo ""
            has_issues=true
        fi
    fi

    # Show next steps if no issues
    if ! $has_issues; then
        echo "${FLOW_COLORS[success]}✓ Project health: Good${FLOW_COLORS[reset]}"
        echo ""
    fi
}
