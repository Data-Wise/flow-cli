# lib/cache-helpers.zsh - Quarto freeze cache management utilities
# Provides: cache status, clearing, rebuilding, analysis

# ============================================================================
# CACHE STATUS & INFORMATION
# ============================================================================

# =============================================================================
# Function: _cache_status
# Purpose: Get comprehensive freeze cache status information
# =============================================================================
# Arguments:
#   $1 - (optional) Project root directory [default: $PWD]
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Key=value pairs (one per line):
#     cache_status=none|exists
#     size=<bytes>
#     size_human=<human-readable>
#     file_count=<integer>
#     last_render=<time ago string>
#     last_render_timestamp=<unix timestamp>
#
# Example:
#   info=$(_cache_status)
#   eval "$info"
#   echo "Cache: $size_human ($file_count files), last render: $last_render"
#
# Dependencies:
#   - du (for size calculation)
#   - stat (for modification time)
#   - _cache_format_time_ago (internal)
#
# Notes:
#   - Returns "none" status if _freeze/ directory doesn't exist
#   - Output designed for eval to set shell variables
# =============================================================================
_cache_status() {
    local project_root="${1:-$PWD}"
    local freeze_dir="$project_root/_freeze"

    # Check if cache exists
    if [[ ! -d "$freeze_dir" ]]; then
        echo "cache_status=none"
        echo "size=0"
        echo "size_human=0B"
        echo "file_count=0"
        echo "last_render=never"
        return 0
    fi

    # Count files
    local file_count=$(find "$freeze_dir" -type f 2>/dev/null | wc -l | tr -d ' ')

    # Get size
    local size_bytes=0
    local size_human="0B"
    if command -v du &>/dev/null; then
        size_human=$(du -sh "$freeze_dir" 2>/dev/null | awk '{print $1}')
        # Get bytes for sorting/comparison
        size_bytes=$(du -sk "$freeze_dir" 2>/dev/null | awk '{print $1}')
        size_bytes=$((size_bytes * 1024))  # Convert KB to bytes
    fi

    # Get last modification time
    local last_render="never"
    local last_render_timestamp=0
    if [[ -d "$freeze_dir" ]]; then
        # Find most recently modified file in cache
        local newest_file=$(find "$freeze_dir" -type f -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null | head -1)
        if [[ -n "$newest_file" ]]; then
            last_render_timestamp=$(stat -f %m "$newest_file" 2>/dev/null || echo 0)
            if [[ $last_render_timestamp -gt 0 ]]; then
                last_render=$(_cache_format_time_ago $last_render_timestamp)
            fi
        fi
    fi

    # Return structured data
    echo "cache_status=exists"
    echo "size=$size_bytes"
    echo "size_human=$size_human"
    echo "file_count=$file_count"
    echo "last_render=$last_render"
    echo "last_render_timestamp=$last_render_timestamp"
}

# =============================================================================
# Function: _cache_format_time_ago
# Purpose: Format Unix timestamp as human-readable "time ago" string
# =============================================================================
# Arguments:
#   $1 - (required) Unix timestamp (seconds since epoch)
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Human-readable string (e.g., "just now", "5 minutes ago", "2 days ago")
#
# Example:
#   last_modified=$(stat -f %m "$file")
#   echo "Modified $(_cache_format_time_ago $last_modified)"
#
# Notes:
#   - Outputs: "just now", "X minute(s) ago", "X hour(s) ago",
#     "X day(s) ago", or "X week(s) ago"
#   - Handles plural/singular correctly
# =============================================================================
_cache_format_time_ago() {
    local timestamp="$1"
    local now=$(date +%s)
    local diff=$((now - timestamp))

    if [[ $diff -lt 60 ]]; then
        echo "just now"
    elif [[ $diff -lt 3600 ]]; then
        local mins=$((diff / 60))
        echo "$mins minute$([[ $mins -ne 1 ]] && echo s) ago"
    elif [[ $diff -lt 86400 ]]; then
        local hours=$((diff / 3600))
        echo "$hours hour$([[ $hours -ne 1 ]] && echo s) ago"
    elif [[ $diff -lt 604800 ]]; then
        local days=$((diff / 86400))
        echo "$days day$([[ $days -ne 1 ]] && echo s) ago"
    else
        local weeks=$((diff / 604800))
        echo "$weeks week$([[ $weeks -ne 1 ]] && echo s) ago"
    fi
}

# ============================================================================
# CACHE CLEARING
# ============================================================================

# =============================================================================
# Function: _cache_clear
# Purpose: Clear the entire freeze cache with optional confirmation
# =============================================================================
# Arguments:
#   $1 - (optional) Project root directory [default: $PWD]
#   --force - Skip confirmation prompt
#
# Returns:
#   0 - Cache cleared successfully
#   1 - No cache found, deletion failed, or user cancelled
#
# Example:
#   _cache_clear                          # With confirmation
#   _cache_clear --force                  # Skip confirmation
#   _cache_clear "/path/to/project"       # Specific project
#
# Dependencies:
#   - _cache_status (internal)
#   - _flow_confirm, _flow_log_* (from core.zsh)
#
# Notes:
#   - Shows cache size and file count before confirmation
#   - Completely removes _freeze/ directory
# =============================================================================
_cache_clear() {
    local project_root="$PWD"
    local force=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force)
                force=true
                shift
                ;;
            *)
                project_root="$1"
                shift
                ;;
        esac
    done

    local freeze_dir="$project_root/_freeze"

    # Check if cache exists
    if [[ ! -d "$freeze_dir" ]]; then
        _flow_log_warning "No freeze cache found"
        return 1
    fi

    # Get cache info
    local cache_info=$(_cache_status "$project_root")
    eval "$cache_info"

    # Show what will be deleted
    echo ""
    echo "${FLOW_COLORS[header]}Cache to be deleted:${FLOW_COLORS[reset]}"
    echo "  Location:   $freeze_dir"
    echo "  Size:       $size_human"
    echo "  Files:      $file_count"
    echo ""

    # Confirmation unless --force
    if [[ "$force" != "true" ]]; then
        if ! _flow_confirm "Delete freeze cache?" "n"; then
            _flow_log_info "Cache deletion cancelled"
            return 1
        fi
    fi

    # Delete cache
    rm -rf "$freeze_dir"

    if [[ $? -eq 0 ]]; then
        _flow_log_success "Freeze cache cleared ($size_human freed)"
        return 0
    else
        _flow_log_error "Failed to clear cache"
        return 1
    fi
}

# =============================================================================
# Function: _clear_cache_selective
# Purpose: Clear cache selectively by directory type or age
# =============================================================================
# Arguments:
#   $1 - (optional) Project root directory [default: $PWD]
#   --lectures    - Clear only lectures/ cache
#   --assignments - Clear only assignments/ cache
#   --slides      - Clear only slides/ cache
#   --old         - Clear files older than 30 days
#   --unused      - Clear files with 0 cache hits (placeholder)
#   --force       - Skip confirmation prompt
#
# Returns:
#   0 - Files cleared successfully
#   1 - No files matched, or user cancelled
#
# Example:
#   _clear_cache_selective --lectures                # Clear lecture cache
#   _clear_cache_selective --old --force             # Clear old files
#   _clear_cache_selective --lectures --assignments  # Multiple types
#
# Dependencies:
#   - _cache_format_bytes (internal)
#   - _flow_confirm (from core.zsh)
#
# Notes:
#   - Flags can be combined for precise selection
#   - --unused is a placeholder for future hit tracking
#   - Removes empty directories after clearing
# =============================================================================
_clear_cache_selective() {
    local project_root="$PWD"
    local force=false
    local clear_lectures=false
    local clear_assignments=false
    local clear_slides=false
    local clear_old=false
    local clear_unused=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force)
                force=true
                shift
                ;;
            --lectures)
                clear_lectures=true
                shift
                ;;
            --assignments)
                clear_assignments=true
                shift
                ;;
            --slides)
                clear_slides=true
                shift
                ;;
            --old)
                clear_old=true
                shift
                ;;
            --unused)
                clear_unused=true
                shift
                ;;
            *)
                project_root="$1"
                shift
                ;;
        esac
    done

    local freeze_dir="$project_root/_freeze/site"

    # Check if cache exists
    if [[ ! -d "$freeze_dir" ]]; then
        _flow_log_warning "No freeze cache found"
        return 1
    fi

    # Collect files to delete
    local files_to_delete=()
    local candidate_files=()

    # Build list of candidate files based on directory filters
    local has_dir_filter=false
    if [[ "$clear_lectures" == "true" || "$clear_assignments" == "true" || "$clear_slides" == "true" ]]; then
        has_dir_filter=true

        if [[ "$clear_lectures" == "true" && -d "$freeze_dir/lectures" ]]; then
            while IFS= read -r file; do
                candidate_files+=("$file")
            done < <(find "$freeze_dir/lectures" -type f 2>/dev/null)
        fi

        if [[ "$clear_assignments" == "true" && -d "$freeze_dir/assignments" ]]; then
            while IFS= read -r file; do
                candidate_files+=("$file")
            done < <(find "$freeze_dir/assignments" -type f 2>/dev/null)
        fi

        if [[ "$clear_slides" == "true" && -d "$freeze_dir/slides" ]]; then
            while IFS= read -r file; do
                candidate_files+=("$file")
            done < <(find "$freeze_dir/slides" -type f 2>/dev/null)
        fi
    else
        # No directory filter - use all files in cache
        while IFS= read -r file; do
            candidate_files+=("$file")
        done < <(find "$freeze_dir" -type f 2>/dev/null)
    fi

    # Apply age filter if requested
    if [[ "$clear_old" == "true" ]]; then
        local now=$(date +%s)
        local thirty_days_ago=$((now - 2592000))

        # Filter candidates by age
        for file in "${candidate_files[@]}"; do
            local mtime=$(stat -f %m "$file" 2>/dev/null || echo 0)

            if [[ $mtime -lt $thirty_days_ago ]]; then
                files_to_delete+=("$file")
            fi
        done
    else
        # No age filter - use all candidates
        files_to_delete=("${candidate_files[@]}")
    fi

    # Clear unused files (files with 0 cache hits)
    # This requires performance log with per-file hit tracking
    # For now, we skip this feature (placeholder for future)
    if [[ "$clear_unused" == "true" ]]; then
        _flow_log_warning "--unused flag not yet implemented (requires per-file hit tracking)"
        # Would need to:
        # 1. Read performance log
        # 2. Build set of "used" files
        # 3. Find files not in that set
    fi

    # Deduplicate files
    local unique_files=()
    local seen_files=()
    for file in "${files_to_delete[@]}"; do
        if [[ ! " ${seen_files[@]} " =~ " $file " ]]; then
            unique_files+=("$file")
            seen_files+=("$file")
        fi
    done

    # Check if any files to delete
    if [[ ${#unique_files[@]} -eq 0 ]]; then
        _flow_log_warning "No files matched the selection criteria"
        return 1
    fi

    # Calculate total size
    local total_size_bytes=0
    for file in "${unique_files[@]}"; do
        local file_size=$(stat -f %z "$file" 2>/dev/null || echo 0)
        total_size_bytes=$((total_size_bytes + file_size))
    done

    local total_size_human=$(_cache_format_bytes "$total_size_bytes")
    local file_count=${#unique_files[@]}

    # Show what will be deleted
    echo ""
    echo "${FLOW_COLORS[header]}Files to be deleted:${FLOW_COLORS[reset]}"
    echo "  Count:      $file_count files"
    echo "  Total size: $total_size_human"

    # Show breakdown by category
    if [[ "$clear_lectures" == "true" ]]; then
        echo "  Includes:   lectures/"
    fi
    if [[ "$clear_assignments" == "true" ]]; then
        echo "  Includes:   assignments/"
    fi
    if [[ "$clear_slides" == "true" ]]; then
        echo "  Includes:   slides/"
    fi
    if [[ "$clear_old" == "true" ]]; then
        echo "  Includes:   files > 30 days old"
    fi

    echo ""

    # Confirmation unless --force
    if [[ "$force" != "true" ]]; then
        if ! _flow_confirm "Delete these cache files?" "n"; then
            _flow_log_info "Cache deletion cancelled"
            return 1
        fi
    fi

    # Delete files
    local deleted_count=0
    local failed_count=0

    for file in "${unique_files[@]}"; do
        if rm -f "$file" 2>/dev/null; then
            ((deleted_count++))
        else
            ((failed_count++))
        fi
    done

    # Clean up empty directories
    find "$freeze_dir" -type d -empty -delete 2>/dev/null

    # Report results
    if [[ $deleted_count -gt 0 ]]; then
        _flow_log_success "Cleared $total_size_human ($deleted_count files)"
    fi

    if [[ $failed_count -gt 0 ]]; then
        _flow_log_warning "Failed to delete $failed_count files"
    fi

    return 0
}

# ============================================================================
# CACHE REBUILDING
# ============================================================================

# =============================================================================
# Function: _cache_rebuild
# Purpose: Rebuild freeze cache by clearing and re-rendering
# =============================================================================
# Arguments:
#   $1 - (optional) Project root directory [default: $PWD]
#
# Returns:
#   0 - Cache rebuilt successfully
#   1 - Clear or render failed
#
# Example:
#   _cache_rebuild
#   _cache_rebuild "/path/to/project"
#
# Dependencies:
#   - quarto
#   - _cache_clear (internal)
#   - _cache_status (internal)
#   - _flow_with_spinner (from tui.zsh)
#
# Notes:
#   - Forces clearing without confirmation
#   - Uses quarto render with --execute-daemon restart
#   - Shows new cache status after rebuild
#   - Can take 30-60+ seconds for large projects
# =============================================================================
_cache_rebuild() {
    local project_root="${1:-$PWD}"

    _flow_log_info "Rebuilding freeze cache..."
    echo ""

    # Step 1: Clear cache
    if ! _cache_clear "$project_root" --force; then
        _flow_log_error "Failed to clear cache"
        return 1
    fi

    echo ""

    # Step 2: Render (force re-execution)
    _flow_log_info "Re-rendering all content..."

    # Check if quarto is available
    if ! command -v quarto &>/dev/null; then
        _flow_log_error "Quarto not installed"
        return 1
    fi

    # Run quarto render with spinner
    if _flow_with_spinner "Rendering Quarto project" "~30-60s" \
        quarto render "$project_root" --execute-daemon restart; then
        _flow_log_success "Cache rebuilt successfully"

        # Show new cache status
        echo ""
        local new_cache_info=$(_cache_status "$project_root")
        eval "$new_cache_info"
        echo "${FLOW_COLORS[info]}New cache:${FLOW_COLORS[reset]} $size_human ($file_count files)"
        return 0
    else
        _flow_log_error "Render failed"
        return 1
    fi
}

# ============================================================================
# CACHE ANALYSIS
# ============================================================================

# =============================================================================
# Function: _cache_analyze
# Purpose: Analyze freeze cache with detailed breakdown by directory and age
# =============================================================================
# Arguments:
#   $1 - (optional) Project root directory [default: $PWD]
#
# Returns:
#   0 - Always (displays analysis)
#   1 - No cache found
#
# Output:
#   stdout - Formatted analysis with:
#     - Overall status (size, file count, last render)
#     - Breakdown by content directory
#     - Breakdown by file age
#
# Example:
#   _cache_analyze
#   _cache_analyze "/path/to/project"
#
# Dependencies:
#   - _cache_status (internal)
#   - du, find, stat
#
# Notes:
#   - Displays in ADHD-friendly box format
#   - Age buckets: last hour, last day, last week, older
#   - Shows subdirectory sizes for targeted cleanup
# =============================================================================
_cache_analyze() {
    local project_root="${1:-$PWD}"
    local freeze_dir="$project_root/_freeze"

    # Check if cache exists
    if [[ ! -d "$freeze_dir" ]]; then
        _flow_log_warning "No freeze cache found"
        return 1
    fi

    echo ""
    echo "${FLOW_COLORS[header]}╭─ Freeze Cache Analysis ────────────────────────────╮${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"

    # Overall status
    local cache_info=$(_cache_status "$project_root")
    eval "$cache_info"

    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]} ${FLOW_COLORS[bold]}Overall:${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}   Total size:  $size_human"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}   Files:       $file_count"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}   Last render: $last_render"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"

    # Breakdown by subdirectory
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]} ${FLOW_COLORS[bold]}By Content Directory:${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"

    if command -v du &>/dev/null; then
        # List subdirectories with sizes
        local subdirs=$(find "$freeze_dir" -type d -mindepth 1 -maxdepth 1 2>/dev/null)

        if [[ -n "$subdirs" ]]; then
            while IFS= read -r subdir; do
                local subdir_name=$(basename "$subdir")
                local subdir_size=$(du -sh "$subdir" 2>/dev/null | awk '{print $1}')
                local subdir_files=$(find "$subdir" -type f 2>/dev/null | wc -l | tr -d ' ')

                printf "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}   %-30s %8s  (%s files)\n" \
                    "$subdir_name" "$subdir_size" "$subdir_files"
            done <<< "$subdirs"
        else
            echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}   ${FLOW_COLORS[muted]}No subdirectories${FLOW_COLORS[reset]}"
        fi
    fi

    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"

    # Age breakdown (files by modification time)
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]} ${FLOW_COLORS[bold]}By Age:${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"

    local now=$(date +%s)
    local hour_ago=$((now - 3600))
    local day_ago=$((now - 86400))
    local week_ago=$((now - 604800))

    local count_1h=0
    local count_1d=0
    local count_1w=0
    local count_older=0

    # Count files by age
    while IFS= read -r file; do
        local mtime=$(stat -f %m "$file" 2>/dev/null || echo 0)

        if [[ $mtime -ge $hour_ago ]]; then
            ((count_1h++))
        elif [[ $mtime -ge $day_ago ]]; then
            ((count_1d++))
        elif [[ $mtime -ge $week_ago ]]; then
            ((count_1w++))
        else
            ((count_older++))
        fi
    done < <(find "$freeze_dir" -type f 2>/dev/null)

    printf "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}   Last hour:    %5d files\n" "$count_1h"
    printf "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}   Last day:     %5d files\n" "$count_1d"
    printf "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}   Last week:    %5d files\n" "$count_1w"
    printf "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}   Older:        %5d files\n" "$count_older"

    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}╰────────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
    echo ""
}

# ============================================================================
# CLEAN COMMAND (cache + site)
# ============================================================================

# =============================================================================
# Function: _cache_clean
# Purpose: Clean both _freeze/ cache and _site/ output directories
# =============================================================================
# Arguments:
#   $1 - (optional) Project root directory [default: $PWD]
#   --force - Skip confirmation prompt
#
# Returns:
#   0 - Directories cleaned successfully
#   1 - Nothing to clean, or user cancelled
#
# Example:
#   _cache_clean                    # With confirmation
#   _cache_clean --force            # Skip confirmation
#   _cache_clean "/path/to/project" # Specific project
#
# Dependencies:
#   - _cache_status (internal)
#   - _flow_confirm, _flow_log_success (from core.zsh)
#
# Notes:
#   - Removes both _freeze/ and _site/ directories
#   - Shows size of each directory before confirmation
#   - Useful for complete project cleanup
# =============================================================================
_cache_clean() {
    local project_root="$PWD"
    local force=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force)
                force=true
                shift
                ;;
            *)
                project_root="$1"
                shift
                ;;
        esac
    done

    local freeze_dir="$project_root/_freeze"
    local site_dir="$project_root/_site"

    # Calculate total to delete
    local total_size="0B"
    local total_files=0
    local dirs_to_delete=()

    if [[ -d "$freeze_dir" ]]; then
        dirs_to_delete+=("_freeze")
        local freeze_info=$(_cache_status "$project_root")
        eval "$freeze_info"
        total_files=$((total_files + file_count))
    fi

    if [[ -d "$site_dir" ]]; then
        dirs_to_delete+=("_site")
        if command -v du &>/dev/null; then
            local site_size=$(du -sh "$site_dir" 2>/dev/null | awk '{print $1}')
            local site_files=$(find "$site_dir" -type f 2>/dev/null | wc -l | tr -d ' ')
            total_files=$((total_files + site_files))
        fi
    fi

    # Check if anything to delete
    if [[ ${#dirs_to_delete[@]} -eq 0 ]]; then
        _flow_log_warning "Nothing to clean (no _freeze/ or _site/ directories)"
        return 1
    fi

    # Show what will be deleted
    echo ""
    echo "${FLOW_COLORS[header]}Directories to be deleted:${FLOW_COLORS[reset]}"

    for dir in "${dirs_to_delete[@]}"; do
        local full_path="$project_root/$dir"
        local dir_size="unknown"
        if command -v du &>/dev/null; then
            dir_size=$(du -sh "$full_path" 2>/dev/null | awk '{print $1}')
        fi
        echo "  $dir/ ($dir_size)"
    done

    echo ""
    echo "  Total files: $total_files"
    echo ""

    # Confirmation unless --force
    if [[ "$force" != "true" ]]; then
        if ! _flow_confirm "Delete all build artifacts?" "n"; then
            _flow_log_info "Clean cancelled"
            return 1
        fi
    fi

    # Delete directories
    local deleted_count=0
    for dir in "${dirs_to_delete[@]}"; do
        local full_path="$project_root/$dir"
        rm -rf "$full_path"
        if [[ $? -eq 0 ]]; then
            ((deleted_count++))
            _flow_log_success "Deleted $dir/"
        else
            _flow_log_error "Failed to delete $dir/"
        fi
    done

    echo ""
    _flow_log_success "Clean complete ($deleted_count directories deleted)"
    return 0
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# =============================================================================
# Function: _cache_format_bytes
# Purpose: Format byte count to human-readable size
# =============================================================================
# Arguments:
#   $1 - (required) Size in bytes
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Human-readable size (e.g., "256B", "12KB", "5MB", "2GB")
#
# Example:
#   _cache_format_bytes 1024       # → "1KB"
#   _cache_format_bytes 5242880    # → "5MB"
# =============================================================================
_cache_format_bytes() {
    local bytes="$1"

    if [[ $bytes -lt 1024 ]]; then
        echo "${bytes}B"
    elif [[ $bytes -lt 1048576 ]]; then
        echo "$((bytes / 1024))KB"
    elif [[ $bytes -lt 1073741824 ]]; then
        echo "$((bytes / 1048576))MB"
    else
        echo "$((bytes / 1073741824))GB"
    fi
}

# =============================================================================
# Function: _cache_is_freeze_enabled
# Purpose: Check if Quarto project has freeze caching enabled
# =============================================================================
# Arguments:
#   $1 - (optional) Project root directory [default: $PWD]
#
# Returns:
#   0 - Freeze is enabled (auto or true)
#   1 - Freeze not enabled or no _quarto.yml found
#
# Example:
#   if _cache_is_freeze_enabled; then
#       echo "Project uses freeze cache"
#   fi
#
# Notes:
#   - Checks _quarto.yml for "freeze: auto" or "freeze: true"
#   - Returns 1 if config file doesn't exist
# =============================================================================
_cache_is_freeze_enabled() {
    local project_root="${1:-$PWD}"
    local config_file="$project_root/_quarto.yml"

    if [[ ! -f "$config_file" ]]; then
        return 1
    fi

    # Check for freeze: auto or freeze: true
    if grep -q "freeze:\s*\(auto\|true\)" "$config_file" 2>/dev/null; then
        return 0
    fi

    return 1
}
