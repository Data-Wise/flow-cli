# teach-status.zsh - Extracted from teach-dispatcher.zsh
# ============================================================================

_teach_show_status() {
    # Help check
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        _teach_status_help
        return 0
    fi

    local config_file=".flow/teach-config.yml"

    if [[ ! -f "$config_file" ]]; then
        _flow_log_error "Not a teaching project (no .flow/teach-config.yml)"
        return 1
    fi

    # Check for --performance flag (Phase 2 Wave 5)
    if [[ "$1" == "--performance" ]]; then
        # Source performance monitor if not already loaded
        if [[ -z "$_FLOW_PERFORMANCE_MONITOR_LOADED" ]]; then
            local perf_path="${0:A:h}/../performance-monitor.zsh"
            [[ -f "$perf_path" ]] && source "$perf_path"
        fi

        if typeset -f _format_performance_dashboard >/dev/null 2>&1; then
            _format_performance_dashboard 7  # Default: 7 days
            return $?
        else
            _flow_log_error "Performance monitoring not available"
            return 1
        fi
    fi

    # Check for --full flag to show old detailed view
    if [[ "$1" == "--full" ]]; then
        _teach_show_status_full
        return 0
    fi

    # Use enhanced dashboard by default (Week 8)
    if typeset -f _teach_show_status_dashboard >/dev/null 2>&1; then
        _teach_show_status_dashboard
        return $?
    else
        # Fallback to basic status if dashboard not loaded
        _teach_show_status_full
        return $?
    fi
}

# Full status (detailed view - retained for --full flag)

_teach_show_status_full() {
    local config_file=".flow/teach-config.yml"

    # ============================================
    # GIT STATUS (Phase 3 - v5.11.0+)
    # ============================================
    if _git_in_repo; then
        echo ""
        echo "${FLOW_COLORS[bold]}🔧 Git Status${FLOW_COLORS[reset]}"
        echo "${FLOW_COLORS[header]}────────────────────────────────────────────────────${FLOW_COLORS[reset]}"

        # Get teaching-related uncommitted files
        local -a teaching_files=()
        while IFS= read -r file; do
            [[ -n "$file" ]] && teaching_files+=("$file")
        done < <(_git_teaching_files)

        if [[ ${#teaching_files[@]} -gt 0 ]]; then
            echo "  ${FLOW_COLORS[warn]}⚠️  ${teaching_files[@]} uncommitted changes (teaching content)${FLOW_COLORS[reset]}"
            echo ""
            for file in "${teaching_files[@]}"; do
                # Get file status (M/A/D etc)
                local file_status=$(git status --porcelain "$file" 2>/dev/null | awk '{print $1}')
                local status_label
                case "$file_status" in
                    M) status_label="${FLOW_COLORS[warn]}M${FLOW_COLORS[reset]}" ;;
                    A) status_label="${FLOW_COLORS[success]}A${FLOW_COLORS[reset]}" ;;
                    D) status_label="${FLOW_COLORS[error]}D${FLOW_COLORS[reset]}" ;;
                    ??) status_label="${FLOW_COLORS[muted]}??${FLOW_COLORS[reset]}" ;;
                    *) status_label="$file_status" ;;
                esac
                printf "    %s  %s\n" "$status_label" "$file"
            done

            # Offer interactive cleanup
            echo ""
            _teach_git_cleanup_prompt "${teaching_files[@]}"
        else
            if _git_is_clean; then
                echo "  ${FLOW_COLORS[success]}✓ No uncommitted changes${FLOW_COLORS[reset]}"
            else
                echo "  ${FLOW_COLORS[muted]}No teaching content changes${FLOW_COLORS[reset]}"
                echo "  ${FLOW_COLORS[dim]}(Other files modified - use 'g status' to see all)${FLOW_COLORS[reset]}"
            fi
        fi
    fi

    # ============================================
    # DEPLOYMENT STATUS (v5.14.0 - Task 7)
    # ============================================
    echo ""
    echo "${FLOW_COLORS[bold]}🚀 Deployment Status${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}────────────────────────────────────────────────────${FLOW_COLORS[reset]}"

    # Check for last deployment commit
    if _git_in_repo; then
        local last_deploy=$(git log --all --grep="deploy" --grep="Publish" -i --format="%h %s (%cr)" --max-count=1 2>/dev/null)
        if [[ -n "$last_deploy" ]]; then
            echo "  Last Deploy:  $last_deploy"
        else
            echo "  Last Deploy:  ${FLOW_COLORS[muted]}No deployments found${FLOW_COLORS[reset]}"
        fi

        # Check for open PRs (requires gh CLI)
        if command -v gh >/dev/null 2>&1; then
            local pr_count=$(gh pr list --state open 2>/dev/null | wc -l | tr -d ' ')
            if [[ "$pr_count" -gt 0 ]]; then
                echo "  Open PRs:     ${FLOW_COLORS[warning]}$pr_count pending${FLOW_COLORS[reset]}"
                # Show first PR details
                local pr_info=$(gh pr list --state open --limit 1 --json number,title,headRefName 2>/dev/null | \
                    command -v jq >/dev/null 2>&1 && jq -r '.[0] | "#\(.number): \(.title) (\(.headRefName))"' 2>/dev/null || echo "")
                [[ -n "$pr_info" ]] && echo "                $pr_info"
            else
                echo "  Open PRs:     ${FLOW_COLORS[success]}None${FLOW_COLORS[reset]}"
            fi
        fi
    fi

    # ============================================
    # BACKUP SUMMARY (v5.14.0 - Task 7)
    # ============================================
    echo ""
    echo "${FLOW_COLORS[bold]}💾 Backup Summary${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}────────────────────────────────────────────────────${FLOW_COLORS[reset]}"

    local -A backup_counts=()
    local total_backups=0
    local latest_backup=""
    local latest_backup_time=0

    # Count backups for each content type
    for dir in exams lectures slides assignments quizzes syllabi rubrics; do
        if [[ -d "$dir" ]]; then
            # Find all content folders in this directory
            for content_dir in "$dir"/*(/N); do
                if [[ -d "$content_dir" ]]; then
                    local count=$(_teach_count_backups "$content_dir")
                    if [[ "$count" -gt 0 ]]; then
                        backup_counts[$dir]=$((${backup_counts[$dir]:-0} + count))
                        ((total_backups += count))

                        # Find most recent backup
                        local recent=$(_teach_list_backups "$content_dir" | head -1)
                        if [[ -n "$recent" ]]; then
                            local backup_time=$(stat -c %Y "$recent" 2>/dev/null || stat -f %m "$recent" 2>/dev/null)
                            if [[ "$backup_time" -gt "$latest_backup_time" ]]; then
                                latest_backup_time=$backup_time
                                latest_backup=$(basename "$recent")
                            fi
                        fi
                    fi
                fi
            done
        fi
    done

    # Display summary
    if [[ $total_backups -gt 0 ]]; then
        echo "  Total Backups:  $total_backups"

        # Show last backup time
        if [[ -n "$latest_backup" && "$latest_backup_time" -gt 0 ]]; then
            # Convert timestamp to readable date (macOS/Linux compatible)
            local time_ago
            time_ago=$(date -r "$latest_backup_time" '+%Y-%m-%d %H:%M' 2>/dev/null || \
                       date -d "@$latest_backup_time" '+%Y-%m-%d %H:%M' 2>/dev/null || \
                       echo "$latest_backup")
            echo "  Last Backup:    $time_ago"
        fi

        # Breakdown by type
        if [[ ${#backup_counts[@]} -gt 0 ]]; then
            echo ""
            echo "  ${FLOW_COLORS[dim]}By Content Type:${FLOW_COLORS[reset]}"
            for dir in exams lectures slides assignments quizzes syllabi rubrics; do
                if [[ -n "${backup_counts[$dir]}" && "${backup_counts[$dir]}" -gt 0 ]]; then
                    printf "    %-15s %s backups\n" "$dir:" "${backup_counts[$dir]}"
                fi
            done
        fi
    else
        echo "  ${FLOW_COLORS[muted]}No backups yet${FLOW_COLORS[reset]}"
        echo "  ${FLOW_COLORS[dim]}Backups are created automatically when regenerating content${FLOW_COLORS[reset]}"
    fi

    # ============================================
    # CONTENT INVENTORY (Full)
    # ============================================
    echo ""
    echo "${FLOW_COLORS[bold]}📝 Generated Content${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}────────────────────────────────────────────────────${FLOW_COLORS[reset]}"

    local -A content_dirs=(
        [exams]="📄 Exams"
        [quizzes]="❓ Quizzes"
        [assignments]="📋 Assignments"
        [lectures]="🎓 Lectures"
        [slides]="📊 Slides"
        [rubrics]="📏 Rubrics"
    )

    local found_content=false
    for dir label in "${(@kv)content_dirs}"; do
        if [[ -d "$dir" ]]; then
            local count=$(find "$dir" -maxdepth 2 -name "*.md" -o -name "*.qmd" 2>/dev/null | wc -l | tr -d ' ')
            if [[ "$count" -gt 0 ]]; then
                printf "  %-20s %s files\n" "$label:" "$count"
                found_content=true
            fi
        fi
    done

    if ! $found_content; then
        echo "  ${FLOW_COLORS[muted]}No generated content yet${FLOW_COLORS[reset]}"
        echo "  ${FLOW_COLORS[muted]}Run 'teach exam \"Topic\"' to get started${FLOW_COLORS[reset]}"
    fi

    # ============================================
    # RECENT ACTIVITY
    # ============================================
    echo ""
    echo "${FLOW_COLORS[bold]}🕐 Recent Activity${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}────────────────────────────────────────────────────${FLOW_COLORS[reset]}"

    # Find recent .md/.qmd files
    local -a recent_files=()
    while IFS= read -r file; do
        [[ -n "$file" ]] && recent_files+=("$file")
    done < <(find . -maxdepth 3 \( -name "*.md" -o -name "*.qmd" \) -newer "$config_file" -type f 2>/dev/null | head -5)

    if [[ ${#recent_files[@]} -gt 0 ]]; then
        for file in "${recent_files[@]}"; do
            local basename=$(basename "$file")
            local mtime=$(stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$file" 2>/dev/null || stat -c '%y' "$file" 2>/dev/null | cut -d. -f1)
            printf "  %-30s %s\n" "$basename" "${FLOW_COLORS[muted]}$mtime${FLOW_COLORS[reset]}"
        done
    else
        echo "  ${FLOW_COLORS[muted]}No recent changes${FLOW_COLORS[reset]}"
    fi

    # Show last teach command from .STATUS
    if [[ -f ".STATUS" ]] && grep -q "^# Last teach" ".STATUS" 2>/dev/null; then
        local last_teach=$(grep "^# Last teach" ".STATUS" | tail -1)
        echo ""
        echo "  ${FLOW_COLORS[muted]}${last_teach#\# }${FLOW_COLORS[reset]}"
    fi

    echo ""
}

# ==============================================================================
# BACKUP COMMAND (v5.14.0 - Task 5)
# ==============================================================================

# Backup command dispatcher
# Usage: teach backup <subcommand> [args]

