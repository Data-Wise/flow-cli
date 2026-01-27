# commands/teach-migrate.zsh - Migrate teach-config.yml to separate lesson plans
# Part of flow-cli - Pure ZSH plugin for ADHD-optimized workflow management
#
# Extracts semester_info.weeks[] from teach-config.yml into lesson-plans.yml
# for cleaner separation of concerns.
#
# Usage:
#   teach migrate-config [OPTIONS]
#
# Options:
#   --dry-run     Preview changes without modifying files
#   --force       Skip confirmation prompt
#   --no-backup   Don't create .bak backup file
#   --help, -h    Show help
#
# v5.20.0 - Lesson Plan Extraction (#298)

# Load guard - prevent double-sourcing
if [[ -n "$_FLOW_TEACH_MIGRATE_LOADED" ]]; then
    return 0 2>/dev/null || true
fi
typeset -g _FLOW_TEACH_MIGRATE_LOADED=1

# Source core utilities
if [[ -z "$_FLOW_CORE_LOADED" ]]; then
    local core_path="${0:A:h:h}/lib/core.zsh"
    [[ -f "$core_path" ]] && source "$core_path"
    typeset -g _FLOW_CORE_LOADED=1
fi

# ============================================================================
# CONSTANTS
# ============================================================================

typeset -g TEACH_CONFIG_FILE=".flow/teach-config.yml"
typeset -g LESSON_PLANS_FILE=".flow/lesson-plans.yml"
typeset -g CONFIG_BACKUP_FILE=".flow/teach-config.yml.bak"

# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

# Main migration command - called via "teach migrate-config"
# Usage: _teach_migrate_config [--dry-run] [--force] [--no-backup]
_teach_migrate_config() {
    local dry_run=0
    local force=0
    local no_backup=0

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                dry_run=1
                shift
                ;;
            --force)
                force=1
                shift
                ;;
            --no-backup)
                no_backup=1
                shift
                ;;
            --help|-h)
                _teach_migrate_help
                return 0
                ;;
            *)
                _flow_log_error "Unknown option: $1"
                _teach_migrate_help
                return 1
                ;;
        esac
    done

    # Check yq is available
    if ! command -v yq &>/dev/null; then
        _flow_log_error "yq not found (required for YAML parsing)"
        _flow_log_info "Install: brew install yq"
        return 1
    fi

    # Check .flow directory exists
    if [[ ! -d ".flow" ]]; then
        _flow_log_error ".flow directory not found"
        _flow_log_info "Run this command from your teaching project root"
        return 1
    fi

    # Check teach-config.yml exists
    if [[ ! -f "$TEACH_CONFIG_FILE" ]]; then
        _flow_log_error "teach-config.yml not found at $TEACH_CONFIG_FILE"
        _flow_log_info "Initialize with: teach init"
        return 1
    fi

    # Check if already migrated (lesson-plans.yml exists)
    if [[ -f "$LESSON_PLANS_FILE" ]]; then
        if [[ $force -eq 0 ]]; then
            _flow_log_warning "lesson-plans.yml already exists"
            _flow_log_info "Use --force to overwrite existing file"
            return 1
        fi
        _flow_log_warning "Overwriting existing lesson-plans.yml (--force)"
    fi

    # Check if config has weeks to extract
    local week_count
    week_count=$(_teach_count_weeks "$TEACH_CONFIG_FILE")

    if [[ "$week_count" -eq 0 ]]; then
        _flow_log_error "No weeks found in semester_info.weeks[]"
        _flow_log_info "Nothing to migrate - config may already be migrated"
        return 1
    fi

    # Show header
    echo ""
    if [[ $dry_run -eq 1 ]]; then
        echo "${FLOW_COLORS[header]}${FLOW_COLORS[bold]}Migrating teach-config.yml (DRY RUN)${FLOW_COLORS[reset]}"
    else
        echo "${FLOW_COLORS[header]}${FLOW_COLORS[bold]}Migrating teach-config.yml...${FLOW_COLORS[reset]}"
    fi
    echo ""

    # Show migration preview
    _teach_migration_preview "$TEACH_CONFIG_FILE" "$week_count"

    # Ask for confirmation (unless --force or --dry-run)
    if [[ $dry_run -eq 0 && $force -eq 0 ]]; then
        echo ""
        if ! _flow_confirm "Continue with migration?" "y"; then
            _flow_log_info "Migration cancelled"
            return 0
        fi
    fi

    # Exit early if dry-run
    if [[ $dry_run -eq 1 ]]; then
        echo ""
        _flow_log_info "Dry run complete. No files were modified."
        return 0
    fi

    # Create backup (unless --no-backup)
    if [[ $no_backup -eq 0 ]]; then
        cp "$TEACH_CONFIG_FILE" "$CONFIG_BACKUP_FILE"
        _flow_log_success "Backup created: $CONFIG_BACKUP_FILE"
    fi

    # Extract weeks and create lesson-plans.yml
    local original_lines
    original_lines=$(wc -l < "$TEACH_CONFIG_FILE" | tr -d ' ')

    if ! _teach_extract_weeks "$TEACH_CONFIG_FILE" "$LESSON_PLANS_FILE"; then
        _flow_log_error "Failed to extract weeks"
        # Restore from backup if we created one
        if [[ $no_backup -eq 0 && -f "$CONFIG_BACKUP_FILE" ]]; then
            cp "$CONFIG_BACKUP_FILE" "$TEACH_CONFIG_FILE"
            _flow_log_info "Restored from backup"
        fi
        return 1
    fi

    # Update teach-config.yml to remove weeks, add reference
    if ! _teach_update_config "$TEACH_CONFIG_FILE"; then
        _flow_log_error "Failed to update teach-config.yml"
        # Restore from backup if we created one
        if [[ $no_backup -eq 0 && -f "$CONFIG_BACKUP_FILE" ]]; then
            cp "$CONFIG_BACKUP_FILE" "$TEACH_CONFIG_FILE"
            rm -f "$LESSON_PLANS_FILE"
            _flow_log_info "Restored from backup"
        fi
        return 1
    fi

    # Get final line counts
    local new_config_lines plans_lines
    new_config_lines=$(wc -l < "$TEACH_CONFIG_FILE" | tr -d ' ')
    plans_lines=$(wc -l < "$LESSON_PLANS_FILE" | tr -d ' ')

    # Show success summary
    echo ""
    _flow_log_success "Migration complete!"
    echo "  Config: $TEACH_CONFIG_FILE (${original_lines} -> ${new_config_lines} lines)"
    echo "  Plans:  $LESSON_PLANS_FILE (${week_count} weeks, ${plans_lines} lines)"
    if [[ $no_backup -eq 0 ]]; then
        echo "  Backup: $CONFIG_BACKUP_FILE"
    fi

    return 0
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Count weeks in teach-config.yml
# Usage: _teach_count_weeks <config_file>
# Returns: Number of weeks (0 if none found)
_teach_count_weeks() {
    local config_file="$1"

    local count
    count=$(yq eval '.semester_info.weeks | length' "$config_file" 2>/dev/null)

    # Return 0 if yq fails or returns null/empty
    if [[ -z "$count" || "$count" == "null" ]]; then
        echo "0"
    else
        echo "$count"
    fi
}

# Extract weeks array using yq
# Usage: _teach_extract_weeks <config_file> <output_file>
# Creates lesson-plans.yml with extracted weeks
_teach_extract_weeks() {
    local config_file="$1"
    local output_file="$2"

    # Generate header comment
    local header_comment
    header_comment="# Lesson Plans - Extracted from teach-config.yml
# Generated by: teach migrate-config
# Date: $(date '+%Y-%m-%d')
"

    # Extract weeks using yq and wrap in weeks: key
    local weeks_yaml
    weeks_yaml=$(yq eval '.semester_info.weeks' "$config_file" 2>/dev/null)

    if [[ -z "$weeks_yaml" || "$weeks_yaml" == "null" ]]; then
        _flow_log_error "Failed to extract weeks from config"
        return 1
    fi

    # Write to output file
    {
        echo "$header_comment"
        echo "weeks:"
        # Indent weeks content properly (add 2 spaces to each line)
        echo "$weeks_yaml" | sed 's/^/  /'
    } > "$output_file"

    # Verify the file was created and is valid YAML
    if [[ ! -f "$output_file" ]]; then
        _flow_log_error "Failed to create $output_file"
        return 1
    fi

    # Validate the created YAML
    if ! yq eval '.' "$output_file" &>/dev/null; then
        _flow_log_error "Generated invalid YAML in $output_file"
        rm -f "$output_file"
        return 1
    fi

    _flow_log_success "Created: $output_file"
    return 0
}

# Remove weeks from config and add reference
# Usage: _teach_update_config <config_file>
# Updates teach-config.yml to remove weeks and add lesson_plans reference
_teach_update_config() {
    local config_file="$1"

    # Create temp file for atomic update
    local temp_file
    temp_file=$(mktemp)

    # Use yq to:
    # 1. Delete .semester_info.weeks
    # 2. Add .semester_info.lesson_plans = "lesson-plans.yml"
    yq eval '
        del(.semester_info.weeks) |
        .semester_info.lesson_plans = "lesson-plans.yml"
    ' "$config_file" > "$temp_file" 2>/dev/null

    if [[ $? -ne 0 ]]; then
        rm -f "$temp_file"
        return 1
    fi

    # Validate the modified YAML
    if ! yq eval '.' "$temp_file" &>/dev/null; then
        _flow_log_error "Generated invalid YAML"
        rm -f "$temp_file"
        return 1
    fi

    # Replace original with modified
    mv "$temp_file" "$config_file"

    _flow_log_success "Updated: $config_file"
    return 0
}

# Show preview of what will change
# Usage: _teach_migration_preview <config_file> <week_count>
_teach_migration_preview() {
    local config_file="$1"
    local week_count="$2"

    echo "${FLOW_COLORS[info]}Found:${FLOW_COLORS[reset]} ${week_count} weeks in semester_info.weeks[]"
    echo "${FLOW_COLORS[info]}Creating:${FLOW_COLORS[reset]} $LESSON_PLANS_FILE"
    echo "${FLOW_COLORS[info]}Backup:${FLOW_COLORS[reset]} $CONFIG_BACKUP_FILE"

    echo ""
    echo "${FLOW_COLORS[bold]}Preview:${FLOW_COLORS[reset]}"

    # Get week topics for preview (limit to first 5 + "... (N more)")
    local week_topics
    week_topics=$(yq eval '.semester_info.weeks[] | "  - Week " + (.number | tostring) + ": " + .topic' "$config_file" 2>/dev/null)

    if [[ -n "$week_topics" ]]; then
        local line_count=0
        local max_preview=5

        while IFS= read -r line; do
            ((line_count++))
            if [[ $line_count -le $max_preview ]]; then
                echo "$line"
            fi
        done <<< "$week_topics"

        if [[ $line_count -gt $max_preview ]]; then
            local remaining=$((line_count - max_preview))
            echo "${FLOW_COLORS[muted]}  ... ($remaining more)${FLOW_COLORS[reset]}"
        fi
    else
        echo "${FLOW_COLORS[muted]}  (No week topics found)${FLOW_COLORS[reset]}"
    fi
}

# ============================================================================
# BACKWARD COMPATIBILITY HELPERS
# ============================================================================

# Check if teach-config.yml has embedded weeks
# Usage: _teach_has_embedded_weeks
# Returns: 0 if embedded weeks exist, 1 otherwise
_teach_has_embedded_weeks() {
    local config_file="${1:-$TEACH_CONFIG_FILE}"

    if [[ ! -f "$config_file" ]]; then
        return 1
    fi

    local week_count
    week_count=$(_teach_count_weeks "$config_file")

    [[ "$week_count" -gt 0 ]]
}

# Load week from embedded weeks in teach-config.yml (backward compat)
# Usage: _teach_load_embedded_week <week_number>
# Sets: TEACH_PLAN_TOPIC, TEACH_PLAN_STYLE, etc.
_teach_load_embedded_week() {
    local week="$1"
    local config_file="${2:-$TEACH_CONFIG_FILE}"

    if [[ ! -f "$config_file" ]]; then
        _flow_log_error "Config file not found: $config_file"
        return 1
    fi

    # Extract week data using yq
    local week_data
    week_data=$(yq eval ".semester_info.weeks[] | select(.number == $week)" "$config_file" 2>/dev/null)

    if [[ -z "$week_data" || "$week_data" == "null" ]]; then
        _flow_log_error "Week $week not found in embedded weeks"
        return 1
    fi

    # Extract fields
    TEACH_PLAN_TOPIC=$(echo "$week_data" | yq eval '.topic // ""' - 2>/dev/null)
    TEACH_PLAN_STYLE=$(echo "$week_data" | yq eval '.style // ""' - 2>/dev/null)
    TEACH_PLAN_OBJECTIVES=$(echo "$week_data" | yq eval '.objectives // [] | .[]' - 2>/dev/null | paste -sd '|' -)
    TEACH_PLAN_SUBTOPICS=$(echo "$week_data" | yq eval '.subtopics // [] | .[]' - 2>/dev/null | paste -sd '|' -)
    TEACH_PLAN_KEY_CONCEPTS=$(echo "$week_data" | yq eval '.key_concepts // [] | .[]' - 2>/dev/null | paste -sd '|' -)
    TEACH_PLAN_PREREQUISITES=$(echo "$week_data" | yq eval '.prerequisites // [] | .[]' - 2>/dev/null | paste -sd '|' -)

    return 0
}

# ============================================================================
# HELP
# ============================================================================

_teach_migrate_help() {
    cat <<'EOF'
teach migrate-config - Extract lesson plans from teach-config.yml

USAGE:
  teach migrate-config [OPTIONS]

OPTIONS:
  --dry-run     Preview changes without modifying files
  --force       Skip confirmation prompt, overwrite existing lesson-plans.yml
  --no-backup   Don't create .bak backup file
  --help, -h    Show this help

DESCRIPTION:
  Migrates the semester_info.weeks[] array from teach-config.yml into a
  separate lesson-plans.yml file for cleaner separation of concerns.

  After migration:
    - teach-config.yml contains course metadata only
    - lesson-plans.yml contains all week definitions
    - teach-config.yml.bak contains the original file

BEFORE MIGRATION:
  .flow/
  └── teach-config.yml    # 657 lines (course + 14 weeks embedded)

AFTER MIGRATION:
  .flow/
  ├── teach-config.yml      # ~50 lines (course meta + reference)
  ├── teach-config.yml.bak  # Backup of original
  └── lesson-plans.yml      # ~600 lines (all weeks extracted)

EXAMPLES:
  # Preview migration (no changes)
  teach migrate-config --dry-run

  # Run migration with confirmation
  teach migrate-config

  # Run migration without confirmation
  teach migrate-config --force

  # Run migration without backup
  teach migrate-config --no-backup

ROLLBACK:
  If something goes wrong:
    cp .flow/teach-config.yml.bak .flow/teach-config.yml
    rm .flow/lesson-plans.yml

REQUIREMENTS:
  - yq (YAML processor): brew install yq
  - .flow/teach-config.yml must exist with semester_info.weeks[]

SEE ALSO:
  teach init      - Initialize teaching project
  teach status    - Show project status
  teach doctor    - Check project health
EOF
}

# ============================================================================
# ALIAS FOR DISPATCHER
# ============================================================================

# Allow calling as teach-migrate-config directly
teach-migrate-config() {
    _teach_migrate_config "$@"
}
