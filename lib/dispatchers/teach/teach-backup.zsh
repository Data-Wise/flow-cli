# teach-backup.zsh - Extracted from teach-dispatcher.zsh
# ============================================================================

_teach_backup_command() {
    local subcmd="${1:-list}"
    shift 2>/dev/null || true

    case "$subcmd" in
        create|c)
            _teach_backup_create "$@"
            ;;
        list|ls|l)
            _teach_backup_list "$@"
            ;;
        restore|r)
            _teach_backup_restore "$@"
            ;;
        delete|del|rm)
            _teach_backup_delete "$@"
            ;;
        archive|a)
            _teach_backup_archive "$@"
            ;;
        help|-h|--help)
            _teach_backup_help
            ;;
        *)
            _flow_log_error "Unknown backup subcommand: $subcmd"
            echo ""
            _teach_backup_help
            return 1
            ;;
    esac
}

# Create backup - Main backup interface

_teach_backup_create() {
    local content_path="$1"
    local backup_name="${2:-}"

    # Help check
    if [[ "$content_path" == "--help" || "$content_path" == "-h" ]]; then
        cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach backup create${FLOW_COLORS[reset]} - Create Timestamped Backup         ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach backup create${FLOW_COLORS[reset]} [content_path] [name]

${FLOW_COLORS[bold]}DESCRIPTION${FLOW_COLORS[reset]}
  Creates timestamped snapshots of teaching content for recovery.
  Backups are stored in ${FLOW_COLORS[accent]}.backups/${FLOW_COLORS[reset]} with metadata tracking.

${FLOW_COLORS[bold]}ARGUMENTS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}content_path${FLOW_COLORS[reset]}     Path to content (default: current directory)
  ${FLOW_COLORS[cmd]}name${FLOW_COLORS[reset]}             Optional name (auto-timestamped if omitted)

${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--json${FLOW_COLORS[reset]}           JSON output for scripting
  ${FLOW_COLORS[cmd]}--quiet, -q${FLOW_COLORS[reset]}      Minimal output

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Backup current directory (auto timestamp)${FLOW_COLORS[reset]}
  $ teach backup create .

  ${FLOW_COLORS[muted]}# Backup specific lecture${FLOW_COLORS[reset]}
  $ teach backup create lectures/week-01

  ${FLOW_COLORS[muted]}# Backup with custom name${FLOW_COLORS[reset]}
  $ teach backup create . "Before Midterm"

  ${FLOW_COLORS[muted]}# Backup exam folder${FLOW_COLORS[reset]}
  $ teach backup create exams/midterm

${FLOW_COLORS[bold]}OUTPUT${FLOW_COLORS[reset]}
  Creates: ${FLOW_COLORS[accent]}.backups/<path>.<timestamp>/${FLOW_COLORS[reset]}
  Updates: ${FLOW_COLORS[accent]}.backups/.metadata${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}TIPS${FLOW_COLORS[reset]}
  • Use ${FLOW_COLORS[accent]}teach backup list${FLOW_COLORS[reset]} to see all backups
  • Run ${FLOW_COLORS[accent]}teach doctor${FLOW_COLORS[reset]} to verify backup system
  • Backups are incremental (efficient storage)

${FLOW_COLORS[bold]}LEARN MORE${FLOW_COLORS[reset]}
  Guide: docs/guides/BACKUP-SYSTEM-GUIDE.md

${FLOW_COLORS[muted]}SEE ALSO:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach backup list${FLOW_COLORS[reset]} - List backups
  ${FLOW_COLORS[cmd]}teach backup restore${FLOW_COLORS[reset]} - Restore from backup
  ${FLOW_COLORS[cmd]}teach backup delete${FLOW_COLORS[reset]} - Delete backup

EOF
        return 0
    fi

    # Default to current directory
    if [[ -z "$content_path" ]]; then
        content_path="."
    fi

    if [[ ! -d "$content_path" ]]; then
        _flow_log_error "Path not found: $content_path"
        return 1
    fi

    # Create backup
    local backup_path=$(_teach_backup_content "$content_path")

    if [[ $? -eq 0 && -n "$backup_path" ]]; then
        _flow_log_success "Backup created: $(basename "$backup_path")"

        # Update metadata
        _teach_backup_update_metadata "$content_path" "$backup_path"

        return 0
    else
        _flow_log_error "Failed to create backup"
        return 1
    fi
}

# List all backups

_teach_backup_list() {
    local content_path="${1:-.}"

    # Help check
    if [[ "$content_path" == "--help" || "$content_path" == "-h" ]]; then
        cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach backup list${FLOW_COLORS[reset]} - List All Backups                 ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach backup list${FLOW_COLORS[reset]} [content_path]

${FLOW_COLORS[bold]}DESCRIPTION${FLOW_COLORS[reset]}
  Displays all backups for a content directory with size, file count,
  and timestamp information.

${FLOW_COLORS[bold]}ARGUMENTS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}content_path${FLOW_COLORS[reset]}    Path to content (default: current directory)

${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--json${FLOW_COLORS[reset]}          JSON output for scripting
  ${FLOW_COLORS[cmd]}--short${FLOW_COLORS[reset]}         Compact output (names only)

${FLOW_COLORS[bold]}SORTING${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}Default${FLOW_COLORS[reset]}       Newest first (by timestamp)
  ${FLOW_COLORS[accent]}--oldest${FLOW_COLORS[reset]}      Oldest first
  ${FLOW_COLORS[accent]}--size${FLOW_COLORS[reset]}        Largest first

${FLOW_COLORS[bold]}FILTERING${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--recent N${FLOW_COLORS[reset]}      Show N most recent backups
  ${FLOW_COLORS[cmd]}--pattern "glob"${FLOW_COLORS[reset]} Filter by name pattern

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# List all backups (current directory)${FLOW_COLORS[reset]}
  $ teach backup list

  ${FLOW_COLORS[muted]}# List backups for specific content${FLOW_COLORS[reset]}
  $ teach backup list lectures/week-01

  ${FLOW_COLORS[muted]}# Show compact output${FLOW_COLORS[reset]}
  $ teach backup list --short

  ${FLOW_COLORS[muted]}# Show only 5 most recent${FLOW_COLORS[reset]}
  $ teach backup list --recent 5

${FLOW_COLORS[bold]}OUTPUT COLUMNS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}Name${FLOW_COLORS[reset]}       Backup identifier with timestamp
  ${FLOW_COLORS[accent]}Size${FLOW_COLORS[reset]}       Total size on disk
  ${FLOW_COLORS[accent]}Files${FLOW_COLORS[reset]}      Number of files in backup
  ${FLOW_COLORS[accent]}Date${FLOW_COLORS[reset]}       Creation timestamp

${FLOW_COLORS[bold]}TIPS${FLOW_COLORS[reset]}
  • Use ${FLOW_COLORS[accent]}teach backup restore <name>${FLOW_COLORS[reset]} to restore
  • Backup names include timestamps for easy identification
  • Combine with ${FLOW_COLORS[accent]}--json${FLOW_COLORS[reset]} for scripting

${FLOW_COLORS[muted]}SEE ALSO:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach backup create${FLOW_COLORS[reset]} - Create backup
  ${FLOW_COLORS[cmd]}teach backup restore${FLOW_COLORS[reset]} - Restore from backup

EOF
        return 0
    fi

    local backup_dir="$content_path/.backups"

    if [[ ! -d "$backup_dir" ]]; then
        echo ""
        echo "${FLOW_COLORS[muted]}No backups found for: $content_path${FLOW_COLORS[reset]}"
        echo ""
        return 0
    fi

    local backups=$(_teach_list_backups "$content_path")

    if [[ -z "$backups" ]]; then
        echo ""
        echo "${FLOW_COLORS[muted]}No backups found${FLOW_COLORS[reset]}"
        echo ""
        return 0
    fi

    echo ""
    echo "${FLOW_COLORS[bold]}Backups for: $(basename "$content_path")${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[dim]}────────────────────────────────────────────────${FLOW_COLORS[reset]}"
    echo ""

    local count=0
    while IFS= read -r backup; do
        local backup_name=$(basename "$backup")
        local size=$(du -sh "$backup" 2>/dev/null | awk '{print $1}')
        local file_count=$(find "$backup" -type f 2>/dev/null | wc -l | tr -d ' ')

        # Extract timestamp from backup name
        local timestamp=$(echo "$backup_name" | grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-[0-9]\{4\}' || echo "")

        echo "  ${FLOW_COLORS[accent]}${backup_name}${FLOW_COLORS[reset]}"
        echo "    Size: ${size}  Files: ${file_count}"

        if [[ -n "$timestamp" ]]; then
            # Convert timestamp to human-readable
            local year="${timestamp:0:4}"
            local month="${timestamp:5:2}"
            local day="${timestamp:8:2}"
            local time="${timestamp:11:2}:${timestamp:13:2}"
            echo "    Date: ${year}-${month}-${day} ${time}"
        fi

        echo ""
        ((count++))
    done <<< "$backups"

    echo "${FLOW_COLORS[success]}Total backups: $count${FLOW_COLORS[reset]}"
    echo ""
}

# Restore from backup

_teach_backup_restore() {
    local backup_name="$1"

    # Help check
    if [[ "$backup_name" == "--help" || "$backup_name" == "-h" || -z "$backup_name" ]]; then
        cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach backup restore${FLOW_COLORS[reset]} - Restore From Backup             ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach backup restore${FLOW_COLORS[reset]} <backup_name>

${FLOW_COLORS[bold]}DESCRIPTION${FLOW_COLORS[reset]}
  Restores content from a backup snapshot. Requires confirmation
  before overwriting current content.

${FLOW_COLORS[bold]}ARGUMENTS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}backup_name${FLOW_COLORS[reset]}    Name or partial name of backup to restore
                          (use ${FLOW_COLORS[accent]}teach backup list${FLOW_COLORS[reset]} to see available backups)

${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--force${FLOW_COLORS[reset]}        Skip confirmation prompt
  ${FLOW_COLORS[cmd]}--dry-run${FLOW_COLORS[reset]}      Show what would be restored (no changes)

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# First, list available backups${FLOW_COLORS[reset]}
  $ teach backup list

  ${FLOW_COLORS[muted]}# Restore specific backup (with confirmation)${FLOW_COLORS[reset]}
  $ teach backup restore lectures.2026-01-20-1430

  ${FLOW_COLORS[muted]}# Restore without confirmation${FLOW_COLORS[reset]}
  $ teach backup restore lectures.2026-01-20-1430 --force

  ${FLOW_COLORS[muted]}# Preview restore (no changes)${FLOW_COLORS[reset]}
  $ teach backup restore lectures.2026-01-20-1430 --dry-run

${FLOW_COLORS[bold]}WARNING${FLOW_COLORS[reset]}
  ${FLOW_COLORS[error]}⚠ This will OVERWRITE current content!${FLOW_COLORS[reset]}

  Before restoring:
  • Ensure you have a current backup (${FLOW_COLORS[accent]}teach backup create${FLOW_COLORS[reset]})
  • Check what changed (${FLOW_COLORS[accent]}git diff${FLOW_COLORS[reset]})
  • Consider using ${FLOW_COLORS[accent]}--dry-run${FLOW_COLORS[reset]} first

${FLOW_COLORS[bold]}EXIT CODES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}0${FLOW_COLORS[reset]}   Success - backup restored
  ${FLOW_COLORS[accent]}1${FLOW_COLORS[reset]}   Error - backup not found or restore failed
  ${FLOW_COLORS[accent]}2${FLOW_COLORS[reset]}   Cancelled - user declined confirmation

${FLOW_COLORS[bold]}TIPS${FLOW_COLORS[reset]}
  • Use ${FLOW_COLORS[accent]}teach backup list${FLOW_COLORS[reset]} to find exact backup name
  • Partial names work (e.g., "lectures.2026-01-20")
  • Backups are in ${FLOW_COLORS[accent]}.backups/<path>.<timestamp>/${FLOW_COLORS[reset]}

${FLOW_COLORS[muted]}SEE ALSO:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach backup list${FLOW_COLORS[reset]} - List available backups
  ${FLOW_COLORS[cmd]}teach backup create${FLOW_COLORS[reset]} - Create new backup

EOF
        return 0
    fi

    # Use smart path resolution (PR #277 Task 3)
    local found_backup=$(_resolve_backup_path "$backup_name")

    if [[ $? -ne 0 || -z "$found_backup" ]]; then
        echo ""
        echo "Use ${FLOW_COLORS[cmd]}teach backup list${FLOW_COLORS[reset]} to see available backups"
        echo ""
        return 1
    fi

    # Get content path (parent of .backups)
    local content_path=$(dirname "$(dirname "$found_backup")")

    # Confirm restore
    echo ""
    echo "${FLOW_COLORS[warning]}⚠ Restore Backup?${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[dim]}────────────────────────────────────────────────${FLOW_COLORS[reset]}"
    echo ""
    echo "  From:     $backup_name"
    echo "  To:       $content_path"
    echo ""
    echo "${FLOW_COLORS[error]}⚠ This will overwrite current content!${FLOW_COLORS[reset]}"
    echo ""

    read -q "REPLY?Proceed with restore? [y/N] "
    local response="$REPLY"
    echo ""

    if [[ ! "$response" =~ ^[yY]$ ]]; then
        echo ""
        echo "${FLOW_COLORS[info]}Cancelled - no changes made${FLOW_COLORS[reset]}"
        echo ""
        return 1
    fi

    # Perform restore
    if command -v rsync &>/dev/null; then
        rsync -a --delete "$found_backup/" "$content_path/" 2>/dev/null
    else
        rm -rf "$content_path"/* 2>/dev/null
        cp -R "$found_backup"/* "$content_path/" 2>/dev/null
    fi

    if [[ $? -eq 0 ]]; then
        _flow_log_success "Restored from backup: $backup_name"
        return 0
    else
        _flow_log_error "Failed to restore backup"
        return 1
    fi
}

# Delete backup

_teach_backup_delete() {
    local backup_name="$1"
    local force=false

    if [[ "$2" == "--force" ]]; then
        force=true
    fi

    # Help check
    if [[ "$backup_name" == "--help" || "$backup_name" == "-h" || -z "$backup_name" ]]; then
        cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach backup delete${FLOW_COLORS[reset]} - Delete Backup                  ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach backup delete${FLOW_COLORS[reset]} <backup_name> [options]

${FLOW_COLORS[bold]}DESCRIPTION${FLOW_COLORS[reset]}
  Permanently deletes a backup. Use with caution - deleted backups
  cannot be recovered.

${FLOW_COLORS[bold]}ARGUMENTS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}backup_name${FLOW_COLORS[reset]}    Name of backup to delete
                          (use ${FLOW_COLORS[accent]}teach backup list${FLOW_COLORS[reset]} to see backups)

${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--force, -f${FLOW_COLORS[reset]}    Skip confirmation prompt
  ${FLOW_COLORS[cmd]}--dry-run${FLOW_COLORS[reset]}      Show what would be deleted (no changes)

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Delete with confirmation (recommended)${FLOW_COLORS[reset]}
  $ teach backup delete lectures.2026-01-20-1430

  ${FLOW_COLORS[muted]}# Force delete (no confirmation)${FLOW_COLORS[reset]}
  $ teach backup delete old-backup --force

  ${FLOW_COLORS[muted]}# Preview deletion${FLOW_COLORS[reset]}
  $ teach backup delete lectures.2026-01-20-1430 --dry-run

${FLOW_COLORS[bold]}CONFIRMATION${FLOW_COLORS[reset]}
  Without ${FLOW_COLORS[cmd]}--force${FLOW_COLORS[reset]}, you will be prompted:

    Delete backup? [y/N]

  Type ${FLOW_COLORS[accent]}y${FLOW_COLORS[reset]} to confirm, ${FLOW_COLORS[accent]}N${FLOW_COLORS[reset]} or ${FLOW_COLORS[accent]}Enter${FLOW_COLORS[reset]} to cancel.

${FLOW_COLORS[bold]}WARNING${FLOW_COLORS[reset]}
  ${FLOW_COLORS[error]}⚠ Deletions are permanent!${FLOW_COLORS[reset]}

  Before deleting:
  • Verify you have other backups or the content is no longer needed
  • Use ${FLOW_COLORS[accent]}--dry-run${FLOW_COLORS[reset]} to preview
  • Consider ${FLOW_COLORS[accent]}teach backup archive${FLOW_COLORS[reset]} for semester-end cleanup

${FLOW_COLORS[bold]}TIPS${FLOW_COLORS[reset]}
  • Partial names work (e.g., "lectures.2026-01")
  • Combine with ${FLOW_COLORS[accent]}teach backup list --recent${FLOW_COLORS[reset]} to find old backups
  • Run ${FLOW_COLORS[accent]}teach doctor${FLOW_COLORS[reset]} to check backup system health

${FLOW_COLORS[muted]}SEE ALSO:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach backup list${FLOW_COLORS[reset]} - List backups
  ${FLOW_COLORS[cmd]}teach backup archive${FLOW_COLORS[reset]} - Archive semester backups

EOF
        return 0
    fi

    # Use smart path resolution (PR #277 Task 3)
    local found_backup=$(_resolve_backup_path "$backup_name")

    if [[ $? -ne 0 || -z "$found_backup" ]]; then
        return 1
    fi

    # Delete with confirmation (unless --force)
    if [[ "$force" == "false" ]]; then
        _teach_delete_backup "$found_backup"
    else
        _teach_delete_backup "$found_backup" --force
    fi

    if [[ $? -eq 0 ]]; then
        _flow_log_success "Deleted backup: $backup_name"
        return 0
    else
        return 1
    fi
}

# Archive semester backups

_teach_backup_archive() {
    local semester_name="${1:-}"

    # Help check
    if [[ "$semester_name" == "--help" || "$semester_name" == "-h" ]]; then
        cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach backup archive${FLOW_COLORS[reset]} - Archive Semester Backups        ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach backup archive${FLOW_COLORS[reset]} <semester_name> [options]

${FLOW_COLORS[bold]}DESCRIPTION${FLOW_COLORS[reset]}
  Archives backups at the end of a semester based on retention policies.
  Reduces storage while preserving important backups.

${FLOW_COLORS[bold]}ARGUMENTS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}semester_name${FLOW_COLORS[reset]}    Semester identifier (e.g., spring-2026, fall-2025)

${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--dry-run${FLOW_COLORS[reset]}        Preview actions without making changes
  ${FLOW_COLORS[cmd]}--force${FLOW_COLORS[reset]}          Skip confirmation prompt
  ${FLOW_COLORS[cmd]}--compress${FLOW_COLORS[reset]}       Create compressed archive (.tar.gz)

${FLOW_COLORS[bold]}RETENTION POLICIES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}archive${FLOW_COLORS[reset]}       Keep forever - exams, syllabi, rubrics
  ${FLOW_COLORS[accent]}semester${FLOW_COLORS[reset]}      Delete at semester end - lectures, slides

  Backups are processed according to their retention policy setting.

${FLOW_COLORS[bold]}SEMESTER NAMING${FLOW_COLORS[reset]}
  Use standard semester identifiers:

  ${FLOW_COLORS[cmd]}spring-YYYY${FLOW_COLORS[reset]}      Spring semester (Jan - May)
  ${FLOW_COLORS[cmd]}summer-YYYY${FLOW_COLORS[reset]}      Summer session (May - Aug)
  ${FLOW_COLORS[cmd]}fall-YYYY${FLOW_COLORS[reset]}        Fall semester (Aug - Dec)

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Archive spring 2026 semester (with confirmation)${FLOW_COLORS[reset]}
  $ teach backup archive spring-2026

  ${FLOW_COLORS[muted]}# Preview archive actions${FLOW_COLORS[reset]}
  $ teach backup archive spring-2026 --dry-run

  ${FLOW_COLORS[muted]}# Force archive (no confirmation)${FLOW_COLORS[reset]}
  $ teach backup archive spring-2026 --force

  ${FLOW_COLORS[muted]}# Create compressed archive${FLOW_COLORS[reset]}
  $ teach backup archive spring-2026 --compress

${FLOW_COLORS[bold]}OUTPUT${FLOW_COLORS[reset]}
  Creates: ${FLOW_COLORS[accent]}.backups/.archive/${FLOW_COLORS[reset]}
  • Compressed archives (.tar.gz) for long-term storage
  • Metadata updated with archive status
  • Original backups removed after archiving

${FLOW_COLORS[bold]}WARNING${FLOW_COLORS[reset]}
  ${FLOW_COLORS[warning]}⚠ Run after semester ends${FLOW_COLORS[reset]}

  Best practices:
  • Archive AFTER final grades are submitted
  • Keep exams and syllabi (archive policy)
  • Remove lectures and slides (semester policy)
  • Use ${FLOW_COLORS[accent]}--dry-run${FLOW_COLORS[reset]} first to preview

${FLOW_COLORS[bold]}TIPS${FLOW_COLORS[reset]}
  • Combine with ${FLOW_COLORS[accent]}teach doctor --fix${FLOW_COLORS[reset]} for storage optimization
  • Compressed archives save significant space
  • Keep archives off-site for disaster recovery

${FLOW_COLORS[muted]}SEE ALSO:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach backup list${FLOW_COLORS[reset]} - List all backups
  ${FLOW_COLORS[cmd]}teach backup delete${FLOW_COLORS[reset]} - Delete individual backups
  ${FLOW_COLORS[cmd]}teach doctor${FLOW_COLORS[reset]} - Check backup system health

EOF
        return 0
    fi

    if [[ -z "$semester_name" ]]; then
        _flow_log_error "Semester name required"
        echo ""
        echo "Usage: teach backup archive <semester_name>"
        echo "Example: teach backup archive spring-2026"
        echo ""
        return 1
    fi

    # Call the archive function from backup-helpers
    _teach_archive_semester "$semester_name"
}

# Backup help (upgraded to FLOW_COLORS)

_teach_backup_update_metadata() {
    local content_path="$1"
    local backup_path="$2"
    local metadata_file="$content_path/.backups/metadata.json"

    # Create metadata directory if needed
    mkdir -p "$(dirname "$metadata_file")"

    # Initialize metadata file if it doesn't exist
    if [[ ! -f "$metadata_file" ]]; then
        echo "{\"backups\":[]}" > "$metadata_file"
    fi

    # Get backup info
    local backup_name=$(basename "$backup_path")
    local timestamp=$(date +%s)
    local size=$(du -sh "$backup_path" 2>/dev/null | awk '{print $1}')
    local file_count=$(find "$backup_path" -type f 2>/dev/null | wc -l | tr -d ' ')

    # Add to metadata (simplified - full JSON manipulation would need jq)
    # For now, just append a simple entry
    if command -v jq &>/dev/null; then
        local tmp_file=$(mktemp)
        jq --arg name "$backup_name" \
           --arg ts "$timestamp" \
           --arg size "$size" \
           --arg files "$file_count" \
           '.backups += [{name: $name, timestamp: ($ts|tonumber), size: $size, files: ($files|tonumber)}]' \
           "$metadata_file" > "$tmp_file" && mv "$tmp_file" "$metadata_file"
    fi
}

