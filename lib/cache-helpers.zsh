# lib/cache-helpers.zsh - Quarto freeze cache management utilities
# Provides: cache status, clearing, rebuilding, analysis

# ============================================================================
# CACHE STATUS & INFORMATION
# ============================================================================

# Get freeze cache status
# Usage: _cache_status [project_root]
# Returns: Multi-line status with size, file count, last render
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

# Format time ago (human-readable)
# Usage: _cache_format_time_ago <timestamp>
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

# Clear freeze cache with confirmation
# Usage: _cache_clear [project_root] [--force]
# Returns: 0 on success, 1 on error or user cancellation
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

# ============================================================================
# CACHE REBUILDING
# ============================================================================

# Rebuild cache (clear + render)
# Usage: _cache_rebuild [project_root]
# Returns: 0 on success, 1 on error
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

# Analyze cache in detail
# Usage: _cache_analyze [project_root]
# Returns: Detailed breakdown by directory and age
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

# Clean both cache and site output
# Usage: _cache_clean [project_root] [--force]
# Returns: 0 on success, 1 on error
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

# Format bytes to human-readable size
# Usage: _cache_format_bytes <bytes>
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

# Check if project has freeze enabled
# Usage: _cache_is_freeze_enabled [project_root]
# Returns: 0 if freeze is enabled, 1 otherwise
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
