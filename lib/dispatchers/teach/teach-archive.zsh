# teach-archive.zsh - Extracted from teach-dispatcher.zsh
# ============================================================================

_teach_archive_command() {
    local config_file=".flow/teach-config.yml"

    # Help check
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        _teach_archive_help
        return 0
    fi

    if [[ ! -f "$config_file" ]]; then
        _flow_log_error "Not a teaching project (no .flow/teach-config.yml)"
        return 1
    fi

    # Get semester name from config
    local semester year semester_name
    if command -v yq &>/dev/null; then
        semester=$(yq '.course.semester // ""' "$config_file" 2>/dev/null)
        year=$(yq '.course.year // ""' "$config_file" 2>/dev/null)

        if [[ -n "$semester" && -n "$year" ]]; then
            semester_name="${semester,,}-${year}"  # e.g., "spring-2026"
        else
            semester_name=$(date +%Y-%m)
        fi
    else
        semester_name=$(date +%Y-%m)
    fi

    # Allow override via argument
    if [[ -n "$1" ]]; then
        semester_name="$1"
    fi

    echo ""
    echo "${FLOW_COLORS[bold]}📦 Archiving Semester Backups${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
    echo ""
    echo "  Semester: $semester_name"
    echo ""

    _teach_archive_semester "$semester_name"
}

# Help for teach archive command (v5.14.0 - Task 5)

