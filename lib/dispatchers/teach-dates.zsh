# lib/dispatchers/teach-dates.zsh - Date Management Subcommands for Teaching
# Part of flow-cli v5.11.0 teaching dates automation feature
#
# Provides commands to:
# - sync: Synchronize dates from config to teaching files
# - status: Show date consistency status
# - init: Initialize date configuration
# - validate: Validate date config
# - semester: Semester rollover command

# Load date parser module if not already loaded
if [[ -z "$_FLOW_DATE_PARSER_LOADED" ]]; then
    local parser_path="${0:A:h:h}/date-parser.zsh"
    [[ -f "$parser_path" ]] && source "$parser_path"
fi

# ============================================================================
# teach dates sync - Main Sync Command
# ============================================================================

_teach_dates_sync() {
    local dry_run=false
    local filter=""
    local force=false
    local verbose=false

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                dry_run=true
                shift
                ;;
            --force)
                force=true
                shift
                ;;
            --verbose|-v)
                verbose=true
                shift
                ;;
            --assignments)
                filter="assignments"
                shift
                ;;
            --lectures)
                filter="lectures"
                shift
                ;;
            --syllabus)
                filter="syllabus"
                shift
                ;;
            --file)
                filter="file:$2"
                shift 2
                ;;
            --help|-h|help)
                _teach_dates_sync_help
                return 0
                ;;
            *)
                _teach_error "Unknown flag: $1" "Run 'teach dates sync --help' for usage"
                return 1
                ;;
        esac
    done

    # Check prerequ isites
    if [[ ! -f ".flow/teach-config.yml" ]]; then
        _teach_error "No .flow/teach-config.yml found" "Run 'teach init' first"
        return 1
    fi

    if ! command -v yq >/dev/null 2>&1; then
        _teach_error "yq required for date syncing" "Install: brew install yq"
        return 1
    fi

    # Step 1: Find all teaching files
    echo ""
    echo "${FLOW_COLORS[bold]}🔍 Scanning for teaching files...${FLOW_COLORS[reset]}"

    local -a all_files
    if [[ "$filter" == file:* ]]; then
        # Single file mode
        all_files=("${filter#file:}")
    else
        while IFS= read -r file; do
            all_files+=("$file")
        done < <(_date_find_teaching_files .)
    fi

    # Apply filter
    local -a files=()
    for file in "${all_files[@]}"; do
        case "$filter" in
            assignments)
                [[ "$file" == *"/assignments/"* ]] && files+=("$file")
                ;;
            lectures)
                [[ "$file" == *"/lectures/"* ]] && files+=("$file")
                ;;
            syllabus)
                [[ "$file" == *"syllabus"* || "$file" == *"schedule"* ]] && files+=("$file")
                ;;
            ""|file:*)
                files+=("$file")
                ;;
        esac
    done

    if [[ ${#files[@]} -eq 0 ]]; then
        _flow_log_warning "No teaching files found"
        return 0
    fi

    echo "Found ${#files[@]} files"
    [[ -n "$filter" && "$filter" != file:* ]] && echo "  Filter: $filter"
    echo ""

    # Step 2: Load config dates
    $verbose && echo "${FLOW_COLORS[muted]}Loading dates from config...${FLOW_COLORS[reset]}"

    local -A CONFIG_DATES
    eval "$(_date_load_config .flow/teach-config.yml 2>/dev/null)"

    if [[ ${#CONFIG_DATES[@]} -eq 0 ]]; then
        _flow_log_warning "No dates found in config" "Add semester_info section to .flow/teach-config.yml"
        return 0
    fi

    $verbose && echo "Loaded ${#CONFIG_DATES[@]} dates from config"

    # Step 3: Analyze files and find mismatches
    echo "${FLOW_COLORS[bold]}📊 Analyzing dates...${FLOW_COLORS[reset]}"

    local -A file_mismatches
    local total_mismatches=0

    for file in "${files[@]}"; do
        local -A file_dates=()
        local -a mismatches=()

        # Extract dates from YAML frontmatter
        local due_date
        due_date=$(_date_parse_quarto_yaml "$file" "due" 2>/dev/null)
        [[ -n "$due_date" ]] && file_dates[due]="$due_date"

        # TODO: Match file dates to config dates (implement heuristic)
        # For now, assume filename pattern like hw1.qmd → deadline_hw1

        # Extract assignment ID from filename
        local filename=$(basename "$file" .qmd)
        filename=$(basename "$filename" .md)

        # Try to find matching config date
        local config_key
        for key in "${(@k)CONFIG_DATES}"; do
            # Match deadline_hw1 with hw1.qmd
            if [[ "$key" == deadline_* && "$filename" == "${key#deadline_}" ]]; then
                config_key="$key"
                break
            fi
        done

        if [[ -n "$config_key" && -n "${file_dates[due]}" ]]; then
            local config_date="${CONFIG_DATES[$config_key]}"
            if [[ "${file_dates[due]}" != "$config_date" ]]; then
                mismatches+=("due:${file_dates[due]}:$config_date")
                ((total_mismatches++))
            fi
        fi

        # Store mismatches for this file
        if [[ ${#mismatches[@]} -gt 0 ]]; then
            file_mismatches[$file]="${mismatches[*]}"
        fi
    done

    # Step 4: Show summary
    if [[ $total_mismatches -eq 0 ]]; then
        echo ""
        _flow_log_success "All dates are in sync! No changes needed."
        return 0
    fi

    echo ""
    echo "${FLOW_COLORS[warning]}⚠️  Date Mismatches Found${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
    echo ""
    echo "${#file_mismatches[@]} files have dates that differ from config:"
    echo ""

    local file_num=1
    for file in "${(@k)file_mismatches}"; do
        local count=$(echo "${file_mismatches[$file]}" | wc -w | tr -d ' ')
        printf "  %d. %s (%d mismatch)\n" "$file_num" "$file" "$count"
        ((file_num++))
    done

    echo ""
    echo "Total: $total_mismatches date differences"
    echo ""

    # Step 5: Apply changes (if not dry-run)
    if $dry_run; then
        echo "${FLOW_COLORS[info]}ℹ  Dry-run mode: No changes made${FLOW_COLORS[reset]}"
        echo "  Run without --dry-run to apply changes"
        return 0
    fi

    # Interactive prompts (unless --force)
    local applied=0
    local skipped=0

    for file in "${(@k)file_mismatches}"; do
        local changes=(${(s: :)file_mismatches[$file]})

        echo "${FLOW_COLORS[bold]}File: $file${FLOW_COLORS[reset]}"
        echo "${FLOW_COLORS[header]}├─────────────────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"

        for change in "${changes[@]}"; do
            local field="${change%%:*}"
            local rest="${change#*:}"
            local old_date="${rest%%:*}"
            local new_date="${rest#*:}"

            echo "│ YAML Frontmatter:"
            echo "│   $field: $old_date → $new_date"
        done

        echo "${FLOW_COLORS[header]}├─────────────────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"

        # Prompt user (unless --force)
        local apply=false
        if $force; then
            apply=true
        else
            echo -n "Apply changes? [y/n/d/q] "
            read -r response

            case "$response" in
                y|Y)
                    apply=true
                    ;;
                d|D)
                    # Show diff
                    echo ""
                    echo "Diff preview:"
                    for change in "${changes[@]}"; do
                        echo "  - ${change//:/ → }"
                    done
                    echo ""
                    echo -n "Apply changes? [y/n] "
                    read -r response2
                    [[ "$response2" == "y" || "$response2" == "Y" ]] && apply=true
                    ;;
                q|Q)
                    echo ""
                    _flow_log_info "Quit requested. Applied $applied, skipped $skipped"
                    return 0
                    ;;
                *)
                    apply=false
                    ;;
            esac
        fi

        if $apply; then
            if _date_apply_to_file "$file" "${changes[@]}" 2>/dev/null; then
                ((applied++))
            else
                _flow_log_warning "Failed to update: $file"
                ((skipped++))
            fi
        else
            ((skipped++))
            echo "${FLOW_COLORS[muted]}  Skipped${FLOW_COLORS[reset]}"
        fi

        echo ""
    done

    # Final summary
    echo "${FLOW_COLORS[success]}✅ Date Sync Complete${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
    echo ""
    echo "Summary:"
    echo "  Applied: $applied files"
    echo "  Skipped: $skipped files"
    echo ""

    if [[ $applied -gt 0 ]]; then
        echo "Next Steps:"
        echo "  1. Review changes: git diff"
        echo "  2. Commit: git add -A && git commit -m 'chore: sync dates'"
        echo ""

        # Show modified files
        echo "Modified Files:"
        git status --short 2>/dev/null | head -10
    fi
}

# ============================================================================
# teach dates status - Show Date Consistency
# ============================================================================

_teach_dates_status() {
    echo ""
    echo "${FLOW_COLORS[bold]}📅 Date Status${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"

    # Load config dates
    local -A CONFIG_DATES
    eval "$(_date_load_config .flow/teach-config.yml 2>/dev/null)"

    echo ""
    echo "Config Dates Loaded: ${#CONFIG_DATES[@]}"

    # Count files
    local -a files
    while IFS= read -r file; do
        files+=("$file")
    done < <(_date_find_teaching_files .)

    echo "Teaching Files Found: ${#files[@]}"

    # TODO: Show upcoming deadlines (next 7 days)
    # TODO: Show validation errors

    echo ""
}

# ============================================================================
# teach dates init - Initialize Date Configuration
# ============================================================================

_teach_dates_init() {
    echo ""
    echo "${FLOW_COLORS[bold]}📅 Initialize Date Configuration${FLOW_COLORS[reset]}"
    echo ""

    # Check if semester_info exists
    if yq eval '.semester_info.weeks | length' .flow/teach-config.yml >/dev/null 2>&1; then
        _flow_log_warning "semester_info already exists in config"
        echo -n "Overwrite? [y/N] "
        read -r response
        [[ "$response" != "y" && "$response" != "Y" ]] && return 0
    fi

    # Prompt for start date
    echo -n "Semester start date (YYYY-MM-DD): "
    read -r start_date

    # Validate date format
    if ! _date_normalize "$start_date" >/dev/null 2>&1; then
        _teach_error "Invalid date format: $start_date"
        return 1
    fi

    # Generate 15 weeks
    echo ""
    echo "Generating 15 weeks starting from $start_date..."

    # Calculate end date (15 weeks = 105 days)
    local end_date
    end_date=$(_date_add_days "$start_date" 105)

    # Add to config using yq
    yq eval ".semester_info.start_date = \"$start_date\"" -i .flow/teach-config.yml
    yq eval ".semester_info.end_date = \"$end_date\"" -i .flow/teach-config.yml

    # Generate weeks array
    for ((i=1; i<=15; i++)); do
        local week_start
        week_start=$(_date_add_days "$start_date" $(( (i-1) * 7 )))

        yq eval ".semester_info.weeks[$((i-1))].number = $i" -i .flow/teach-config.yml
        yq eval ".semester_info.weeks[$((i-1))].start_date = \"$week_start\"" -i .flow/teach-config.yml
        yq eval ".semester_info.weeks[$((i-1))].topic = \"Week $i\"" -i .flow/teach-config.yml
    done

    echo ""
    _flow_log_success "Date configuration initialized!"
    echo "  Start: $start_date"
    echo "  End:   $end_date"
    echo "  Weeks: 15"
    echo ""
    echo "Next: Edit .flow/teach-config.yml to add:"
    echo "  - Week topics"
    echo "  - Holidays"
    echo "  - Assignment deadlines"
    echo "  - Exam dates"
}

# ============================================================================
# teach dates validate - Validate Date Configuration
# ============================================================================

_teach_dates_validate() {
    echo ""
    echo "${FLOW_COLORS[bold]}✓ Validating Date Configuration${FLOW_COLORS[reset]}"
    echo ""

    # Check if config exists
    if [[ ! -f ".flow/teach-config.yml" ]]; then
        _teach_error "No .flow/teach-config.yml found"
        return 1
    fi

    # Use existing validator if available
    if typeset -f _teach_validate_config >/dev/null 2>&1; then
        _teach_validate_config ".flow/teach-config.yml"
    else
        _flow_log_success "Config file exists"
    fi
}

# ============================================================================
# Help Functions
# ============================================================================

_teach_dates_sync_help() {
    echo ""
    echo "${FLOW_COLORS[bold]}teach dates sync - Synchronize Dates from Config to Files${FLOW_COLORS[reset]}"
    echo ""
    echo "Usage: teach dates sync [options]"
    echo ""
    echo "Options:"
    echo "  --dry-run           Preview changes without modifying files"
    echo "  --force             Skip prompts, apply all changes automatically"
    echo "  --verbose, -v       Show detailed progress"
    echo "  --assignments       Sync only assignment files"
    echo "  --lectures          Sync only lecture files"
    echo "  --syllabus          Sync only syllabus/schedule files"
    echo "  --file <path>       Sync a specific file"
    echo ""
    echo "Examples:"
    echo "  teach dates sync --dry-run     # Preview changes"
    echo "  teach dates sync               # Interactive sync"
    echo "  teach dates sync --force       # Auto-apply all"
    echo "  teach dates sync --assignments # Sync assignments only"
    echo ""
}

_teach_dates_help() {
    echo ""
    echo "${FLOW_COLORS[bold]}teach dates - Date Management for Teaching Workflows${FLOW_COLORS[reset]}"
    echo ""
    echo "Commands:"
    echo "  sync              Synchronize dates from config to files"
    echo "  status            Show date consistency status"
    echo "  init              Initialize date configuration wizard"
    echo "  validate          Validate date configuration"
    echo ""
    echo "Usage:"
    echo "  teach dates sync [--dry-run] [--force]"
    echo "  teach dates status"
    echo "  teach dates init"
    echo "  teach dates validate"
    echo ""
    echo "Get command help:"
    echo "  teach dates sync --help"
    echo ""
}

# ============================================================================
# Main Dispatcher for 'teach dates'
# ============================================================================

_teach_dates_dispatcher() {
    if [[ -z "$1" || "$1" == "help" || "$1" == "--help" || "$1" == "-h" ]]; then
        _teach_dates_help
        return 0
    fi

    local subcmd="$1"
    shift

    case "$subcmd" in
        sync|s)
            _teach_dates_sync "$@"
            ;;
        status|st)
            _teach_dates_status "$@"
            ;;
        init|i)
            _teach_dates_init "$@"
            ;;
        validate|v)
            _teach_dates_validate "$@"
            ;;
        *)
            _teach_error "Unknown dates subcommand: $subcmd"
            echo ""
            _teach_dates_help
            return 1
            ;;
    esac
}
