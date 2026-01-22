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

# =============================================================================
# Function: _resolve_backup_path
# Purpose: Resolve backup names to full paths using multiple strategies
# =============================================================================
# Arguments:
#   $1 - (required) Backup identifier (name, partial path, or full path)
#
# Returns:
#   0 - Success (path found)
#   1 - Not found or ambiguous match
#
# Output:
#   stdout - Full path to backup directory
#   stderr - Error messages and available backups (on failure)
#
# Example:
#   path=$(_resolve_backup_path "week-01.2026-01-15-1430")
#   path=$(_resolve_backup_path "lectures/week-01/.backups/week-01.2026-01-15")
#   path=$(_resolve_backup_path "2026-01-15")  # Fuzzy match
#
# Notes:
#   - Pattern 1: Full absolute path
#   - Pattern 2: Relative path
#   - Pattern 3: Search common content directories
#   - Lists available backups if not found
#   - Errors on multiple matches (ambiguous)
# =============================================================================
_resolve_backup_path() {
    local input="$1"

    if [[ -z "$input" ]]; then
        _flow_log_error "No backup name provided"
        return 1
    fi

    # Pattern 1: Full absolute path provided
    if [[ -d "$input" ]]; then
        echo "$input"
        return 0
    fi

    # Pattern 2: Relative path (e.g., "lectures/week-01/.backups/backup-name")
    if [[ -d "$input" ]]; then
        echo "$input"
        return 0
    fi

    # Pattern 3: Search in common content directories with .backups folders
    # Enable null_glob FIRST for patterns that might not match
    setopt local_options null_glob

    local content_dirs=(lectures/* exams/* assignments/* quizzes/* slides/* syllabi/* rubrics/* .)

    local exact_matches=()
    local fuzzy_matches=()

    for dir in "${content_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            continue
        fi

        local backup_dir="$dir/.backups"
        if [[ ! -d "$backup_dir" ]]; then
            continue
        fi

        # Check for exact match
        if [[ -d "$backup_dir/$input" ]]; then
            exact_matches+=("$backup_dir/$input")
            continue
        fi

        # Check for fuzzy match (contains input)
        for backup in "$backup_dir"/*; do
            if [[ -d "$backup" ]]; then
                local backup_name=$(basename "$backup")
                if [[ "$backup_name" == *"$input"* ]]; then
                    fuzzy_matches+=("$backup")
                fi
            fi
        done
    done

    # Return exact match if found (prefer first exact match)
    if [[ ${#exact_matches[@]} -eq 1 ]]; then
        echo "${exact_matches[1]}"
        return 0
    elif [[ ${#exact_matches[@]} -gt 1 ]]; then
        _flow_log_error "Multiple exact matches for '$input':"
        for match in "${exact_matches[@]}"; do
            echo "  ${FLOW_COLORS[accent]}$match${FLOW_COLORS[reset]}" >&2
        done
        echo "" >&2
        echo "Please use a more specific path" >&2
        return 1
    fi

    # Return fuzzy match if exactly one found
    if [[ ${#fuzzy_matches[@]} -eq 1 ]]; then
        echo "${fuzzy_matches[1]}"
        return 0
    elif [[ ${#fuzzy_matches[@]} -gt 1 ]]; then
        _flow_log_error "Multiple backups match '$input':"
        for match in "${fuzzy_matches[@]}"; do
            echo "  ${FLOW_COLORS[accent]}$(basename "$match")${FLOW_COLORS[reset]}" >&2
        done
        echo "" >&2
        echo "Please use a more specific name" >&2
        return 1
    fi

    # No matches found - list available backups
    _flow_log_error "Backup not found: $input"
    echo "" >&2
    echo "${FLOW_COLORS[muted]}Available backups:${FLOW_COLORS[reset]}" >&2

    local found_any=false
    for dir in "${content_dirs[@]}"; do
        local backup_dir="$dir/.backups"
        if [[ -d "$backup_dir" ]]; then
            for backup in "$backup_dir"/*; do
                if [[ -d "$backup" ]]; then
                    echo "  ${FLOW_COLORS[accent]}$(basename "$backup")${FLOW_COLORS[reset]} (in $(dirname "$backup_dir"))" >&2
                    found_any=true
                fi
            done
        fi
    done

    if [[ "$found_any" == "false" ]]; then
        echo "  ${FLOW_COLORS[muted]}No backups found${FLOW_COLORS[reset]}" >&2
    fi

    echo "" >&2
    return 1
}

# =============================================================================
# Function: _teach_backup_content
# Purpose: Create timestamped backup of a teaching content folder
# =============================================================================
# Arguments:
#   $1 - (required) Path to the content folder to backup
#
# Returns:
#   0 - Success
#   1 - Content path not found or backup failed
#
# Output:
#   stdout - Full path to created backup folder
#
# Example:
#   backup_path=$(_teach_backup_content "lectures/week-01")
#   echo "Backup created at: $backup_path"
#   # Output: lectures/week-01/.backups/week-01.2026-01-22-1430
#
# Dependencies:
#   - rsync (preferred) or cp (fallback)
#   - _flow_log_error (from core.zsh)
#
# Notes:
#   - Backups stored in <content>/.backups/ directory
#   - Timestamp format: YYYY-MM-DD-HHMM
#   - Excludes .backups directory itself from backup
#   - Uses rsync for efficiency if available
# =============================================================================
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

# =============================================================================
# Function: _teach_get_retention_policy
# Purpose: Get backup retention policy for a content type
# =============================================================================
# Arguments:
#   $1 - (required) Content type: exam, quiz, assignment, syllabus, rubric, lecture, slides
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Policy name: "archive" or "semester"
#
# Example:
#   policy=$(_teach_get_retention_policy "exam")      # → "archive"
#   policy=$(_teach_get_retention_policy "lecture")   # → "semester"
#
# Dependencies:
#   - yq (optional, uses defaults if not installed)
#
# Notes:
#   - Reads from .flow/teach-config.yml if exists
#   - Default policies:
#     * archive: exams, quizzes, assignments, syllabi, rubrics
#     * semester: lectures, slides (deleted at semester end)
# =============================================================================
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

# =============================================================================
# Function: _teach_list_backups
# Purpose: List all backups for a content folder (newest first)
# =============================================================================
# Arguments:
#   $1 - (required) Path to the content folder
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Full paths to backups, one per line, newest first
#
# Example:
#   backups=$(_teach_list_backups "lectures/week-01")
#   echo "$backups" | head -1  # Most recent backup
#
# Notes:
#   - Looks in <content_path>/.backups/
#   - Matches backup naming pattern (*.20*)
#   - Returns empty if no backups exist
# =============================================================================
_teach_list_backups() {
    local content_path="$1"
    local backup_dir="$content_path/.backups"

    if [[ ! -d "$backup_dir" ]]; then
        return 0
    fi

    # List backups, newest first
    find "$backup_dir" -maxdepth 1 -type d -name "*.20*" 2>/dev/null | sort -r
}

# =============================================================================
# Function: _teach_count_backups
# Purpose: Count the number of backups for a content folder
# =============================================================================
# Arguments:
#   $1 - (required) Path to the content folder
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Number of backups (integer)
#
# Example:
#   count=$(_teach_count_backups "lectures/week-01")
#   echo "Found $count backups"
# =============================================================================
_teach_count_backups() {
    local content_path="$1"
    local backup_dir="$content_path/.backups"

    if [[ ! -d "$backup_dir" ]]; then
        echo "0"
        return 0
    fi

    find "$backup_dir" -maxdepth 1 -type d -name "*.20*" 2>/dev/null | wc -l | tr -d ' '
}

# =============================================================================
# Function: _teach_backup_size
# Purpose: Get total size of all backups for a content folder
# =============================================================================
# Arguments:
#   $1 - (required) Path to the content folder
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Human-readable size (e.g., "12M", "256K")
#
# Example:
#   size=$(_teach_backup_size "exams/midterm")
#   echo "Backups using $size of disk space"
# =============================================================================
_teach_backup_size() {
    local content_path="$1"
    local backup_dir="$content_path/.backups"

    if [[ ! -d "$backup_dir" ]]; then
        echo "0"
        return 0
    fi

    du -sh "$backup_dir" 2>/dev/null | awk '{print $1}'
}

# =============================================================================
# Function: _teach_delete_backup
# Purpose: Delete a specific backup with optional confirmation
# =============================================================================
# Arguments:
#   $1 - (required) Full path to the backup directory
#   $2 - (optional) "--force" to skip confirmation prompt
#
# Returns:
#   0 - Backup deleted successfully
#   1 - Backup not found, deletion failed, or user cancelled
#
# Example:
#   _teach_delete_backup "lectures/week-01/.backups/week-01.2026-01-15"
#   _teach_delete_backup "$backup_path" --force  # No confirmation
#
# Dependencies:
#   - _teach_confirm_delete (internal)
#   - _flow_log_error (from core.zsh)
#
# Notes:
#   - Shows confirmation prompt by default (Task 6)
#   - Use --force for scripted/batch operations
# =============================================================================
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

# =============================================================================
# Function: _teach_cleanup_backups
# Purpose: Clean up old backups based on retention policy
# =============================================================================
# Arguments:
#   $1 - (required) Path to the content folder
#   $2 - (required) Content type (exam, lecture, etc.)
#
# Returns:
#   0 - Always (cleanup is advisory)
#
# Example:
#   _teach_cleanup_backups "lectures/week-01" "lecture"
#
# Dependencies:
#   - _teach_get_retention_policy (internal)
#
# Notes:
#   - archive policy: Keep all backups forever
#   - semester policy: Backups cleaned during "teach archive"
#   - Currently a no-op; actual cleanup happens via teach archive
# =============================================================================
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

# =============================================================================
# Function: _teach_archive_semester
# Purpose: Archive all backups for semester-end cleanup
# =============================================================================
# Arguments:
#   $1 - (required) Semester name (e.g., "fall-2026", "spring-2026")
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Summary of archived and deleted content
#
# Example:
#   _teach_archive_semester "fall-2026"
#   # Creates: .flow/archives/fall-2026/
#
# Dependencies:
#   - yq (optional, for config reading)
#   - _teach_get_retention_policy (internal)
#
# Notes:
#   - archive policy: Moves backups to .flow/archives/<semester>/
#   - semester policy: Deletes backups permanently
#   - Processes: exams, lectures, slides, assignments, quizzes, syllabi, rubrics
# =============================================================================
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

# =============================================================================
# Function: _teach_confirm_delete
# Purpose: Display interactive confirmation prompt before deleting backup
# =============================================================================
# Arguments:
#   $1 - (required) Full path to the backup directory
#
# Returns:
#   0 - User confirmed deletion
#   1 - User cancelled
#
# Output:
#   stdout - Interactive prompt with backup details (path, name, size, file count)
#
# Example:
#   if _teach_confirm_delete "$backup_path"; then
#       rm -rf "$backup_path"
#   fi
#
# Notes:
#   - Shows warning about irreversible action
#   - Uses read -q for single-character response
#   - ADHD-friendly design with clear visual hierarchy
# =============================================================================
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

# =============================================================================
# Function: _teach_preview_cleanup
# Purpose: Preview what would be cleaned up based on retention policy
# =============================================================================
# Arguments:
#   $1 - (required) Path to the content folder
#   $2 - (required) Content type (exam, lecture, etc.)
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Preview of backup cleanup plan (no changes made)
#
# Example:
#   _teach_preview_cleanup "lectures/week-01" "lecture"
#   # Shows: Policy, backup count, and what would happen
#
# Dependencies:
#   - _teach_get_retention_policy (internal)
#   - _teach_list_backups (internal)
#
# Notes:
#   - Dry-run only - makes no changes
#   - Useful for understanding cleanup impact before running
# =============================================================================
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
