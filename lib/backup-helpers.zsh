#!/usr/bin/env zsh
# backup-helpers.zsh - Teaching content backup and retention system
# Part of flow-cli v5.14.0 - Teaching Workflow v3.0 (Task 5)
#
# Features:
# - Timestamped backups in .backups/ folders
# - Retention policies (archive, semester)
# - Archive management for semester-end
# - Interactive delete confirmation

# ==============================================================================
# BACKUP FUNCTIONS (Task 5)
# ==============================================================================

# Create timestamped backup of content folder
# Usage: _teach_backup_content <content_path>
# Returns: Path to backup folder
_teach_backup_content() {
    local content_path="$1"

    if [[ ! -d "$content_path" ]]; then
        _flow_log_error "Content path not found: $content_path"
        return 1
    fi

    local content_name="$(basename "$content_path")"
    local backup_dir="$content_path/.backups"
    local timestamp=$(date +%Y-%m-%d-%H%M)
    local backup_path="$backup_dir/${content_name}.${timestamp}"

    # Create backup directory
    mkdir -p "$backup_dir"

    # Copy content to backup (exclude .backups itself)
    if command -v rsync &>/dev/null; then
        rsync -a --exclude='.backups' "$content_path/" "$backup_path/" 2>/dev/null
    else
        # Fallback to cp if rsync not available
        cp -R "$content_path" "$backup_path.tmp" 2>/dev/null
        rm -rf "$backup_path.tmp/.backups" 2>/dev/null
        mv "$backup_path.tmp" "$backup_path" 2>/dev/null
    fi

    if [[ -d "$backup_path" ]]; then
        echo "$backup_path"
        return 0
    else
        _flow_log_error "Failed to create backup"
        return 1
    fi
}

# Get retention policy for content type
# Usage: _teach_get_retention_policy <content_type>
# Returns: "archive" or "semester"
_teach_get_retention_policy() {
    local content_type="$1"
    local config_file=".flow/teach-config.yml"

    # Default policies if config not available
    if [[ ! -f "$config_file" ]]; then
        case "$content_type" in
            exam|quiz|assignment)
                echo "archive"
                ;;
            syllabus|rubric)
                echo "archive"
                ;;
            lecture|slides)
                echo "semester"
                ;;
            *)
                echo "archive"  # Default to safe retention
                ;;
        esac
        return 0
    fi

    # Read from config if yq available
    if command -v yq &>/dev/null; then
        case "$content_type" in
            exam|quiz|assignment)
                yq '.backups.retention.assessments // "archive"' "$config_file" 2>/dev/null || echo "archive"
                ;;
            syllabus|rubric)
                yq '.backups.retention.syllabi // "archive"' "$config_file" 2>/dev/null || echo "archive"
                ;;
            lecture|slides)
                yq '.backups.retention.lectures // "semester"' "$config_file" 2>/dev/null || echo "semester"
                ;;
            *)
                echo "archive"
                ;;
        esac
    else
        # Fallback if yq not available
        echo "archive"
    fi
}

# List all backups for a content folder
# Usage: _teach_list_backups <content_path>
# Returns: List of backup timestamps (newest first)
_teach_list_backups() {
    local content_path="$1"
    local backup_dir="$content_path/.backups"

    if [[ ! -d "$backup_dir" ]]; then
        return 0
    fi

    # List backups, newest first
    find "$backup_dir" -maxdepth 1 -type d -name "*.20*" 2>/dev/null | sort -r
}

# Count backups for a content folder
# Usage: _teach_count_backups <content_path>
# Returns: Number of backups
_teach_count_backups() {
    local content_path="$1"
    local backup_dir="$content_path/.backups"

    if [[ ! -d "$backup_dir" ]]; then
        echo "0"
        return 0
    fi

    find "$backup_dir" -maxdepth 1 -type d -name "*.20*" 2>/dev/null | wc -l | tr -d ' '
}

# Get size of all backups for a content folder
# Usage: _teach_backup_size <content_path>
# Returns: Human-readable size (e.g., "12M")
_teach_backup_size() {
    local content_path="$1"
    local backup_dir="$content_path/.backups"

    if [[ ! -d "$backup_dir" ]]; then
        echo "0"
        return 0
    fi

    du -sh "$backup_dir" 2>/dev/null | awk '{print $1}'
}

# Delete specific backup
# Usage: _teach_delete_backup <backup_path> [--force]
# Returns: 0 on success, 1 on failure
_teach_delete_backup() {
    local backup_path="$1"
    local force=false

    if [[ "$2" == "--force" ]]; then
        force=true
    fi

    if [[ ! -d "$backup_path" ]]; then
        _flow_log_error "Backup not found: $backup_path"
        return 1
    fi

    # Task 6: Prompt before delete (unless --force)
    if [[ "$force" == "false" ]]; then
        _teach_confirm_delete "$backup_path" || return 1
    fi

    rm -rf "$backup_path"

    if [[ ! -d "$backup_path" ]]; then
        return 0
    else
        _flow_log_error "Failed to delete backup"
        return 1
    fi
}

# Clean up old backups based on retention policy
# Usage: _teach_cleanup_backups <content_path> <content_type>
_teach_cleanup_backups() {
    local content_path="$1"
    local content_type="$2"
    local policy=$(_teach_get_retention_policy "$content_type")

    local backup_dir="$content_path/.backups"

    if [[ ! -d "$backup_dir" ]]; then
        return 0
    fi

    case "$policy" in
        archive)
            # Keep all backups (archive policy)
            return 0
            ;;
        semester)
            # For semester policy, keep only backups from current semester
            # This would be called by 'teach archive' at semester end
            # For now, just return (actual cleanup happens via teach archive)
            return 0
            ;;
        *)
            return 0
            ;;
    esac
}

# Archive backups for semester-end
# Usage: _teach_archive_semester <semester_name>
_teach_archive_semester() {
    local semester_name="$1"
    local config_file=".flow/teach-config.yml"

    # Get archive directory from config or use default
    local archive_dir=".flow/archives"
    if [[ -f "$config_file" ]] && command -v yq &>/dev/null; then
        archive_dir=$(yq '.backups.archive_dir // ".flow/archives"' "$config_file" 2>/dev/null) || archive_dir=".flow/archives"
    fi

    local semester_archive="$archive_dir/$semester_name"
    mkdir -p "$semester_archive"

    local archived_count=0
    local deleted_count=0

    # Enable null_glob for patterns that might not match
    setopt local_options null_glob

    # Find all .backups folders
    local dirs=(exams/* lectures/* slides/* assignments/* quizzes/* syllabi/* rubrics/*)
    for content_dir in "${dirs[@]}"; do
        if [[ ! -d "$content_dir" ]] || [[ ! -d "$content_dir/.backups" ]]; then
            continue
        fi

        # Determine content type from path
        local content_type=$(dirname "$content_dir" | xargs basename)
        local policy=$(_teach_get_retention_policy "$content_type")

        case "$policy" in
            archive)
                # Move to archive
                local dest="$semester_archive/$(basename "$content_dir")-backups"
                mv "$content_dir/.backups" "$dest" 2>/dev/null
                ((archived_count++))
                ;;
            semester)
                # Delete backups
                rm -rf "$content_dir/.backups"
                ((deleted_count++))
                ;;
        esac
    done

    echo ""
    echo "${FLOW_COLORS[success]}✓ Archive complete: $semester_archive${FLOW_COLORS[reset]}"
    echo ""
    echo "  Archived: $archived_count content folders"
    echo "  Deleted:  $deleted_count content folders (semester retention)"
    echo ""
}

# ==============================================================================
# DELETE CONFIRMATION (Task 6)
# ==============================================================================

# Confirm before deleting backup
# Usage: _teach_confirm_delete <backup_path>
# Returns: 0 if confirmed, 1 if cancelled
_teach_confirm_delete() {
    local backup_path="$1"
    local backup_name=$(basename "$backup_path")

    echo ""
    echo "${FLOW_COLORS[warning]}⚠ Delete Backup?${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[dim]}────────────────────────────────────────────────${FLOW_COLORS[reset]}"
    echo ""
    echo "  Path:     $backup_path"
    echo "  Name:     $backup_name"

    # Show size if possible
    if command -v du &>/dev/null; then
        local size=$(du -sh "$backup_path" 2>/dev/null | awk '{print $1}')
        echo "  Size:     $size"
    fi

    # Count files
    local file_count=$(find "$backup_path" -type f 2>/dev/null | wc -l | tr -d ' ')
    echo "  Files:    $file_count"

    echo ""
    echo "${FLOW_COLORS[error]}⚠ This action cannot be undone!${FLOW_COLORS[reset]}"
    echo ""

    # Prompt for confirmation
    read -q "REPLY?Delete this backup? [y/N] "
    local response="$REPLY"
    echo ""  # Newline after read -q

    case "$response" in
        [yY]|[yY][eE][sS])
            return 0
            ;;
        *)
            echo ""
            echo "${FLOW_COLORS[info]}Cancelled - backup preserved${FLOW_COLORS[reset]}"
            echo ""
            return 1
            ;;
    esac
}

# Preview what would be deleted
# Usage: _teach_preview_cleanup <content_path> <content_type>
_teach_preview_cleanup() {
    local content_path="$1"
    local content_type="$2"
    local policy=$(_teach_get_retention_policy "$content_type")

    echo ""
    echo "${FLOW_COLORS[bold]}Cleanup Preview${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[dim]}────────────────────────────────────────────────${FLOW_COLORS[reset]}"
    echo ""
    echo "  Content:   $(basename "$content_path")"
    echo "  Type:      $content_type"
    echo "  Policy:    $policy"
    echo ""

    local backups=$(_teach_list_backups "$content_path")
    local backup_count=$(echo "$backups" | wc -l | tr -d ' ')

    if [[ "$backup_count" -eq 0 ]]; then
        echo "  ${FLOW_COLORS[dim]}No backups to clean${FLOW_COLORS[reset]}"
        return 0
    fi

    case "$policy" in
        archive)
            echo "  ${FLOW_COLORS[success]}All $backup_count backups will be archived${FLOW_COLORS[reset]}"
            ;;
        semester)
            echo "  ${FLOW_COLORS[warning]}All $backup_count backups will be deleted at semester end${FLOW_COLORS[reset]}"
            ;;
    esac

    echo ""
}
