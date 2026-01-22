#!/usr/bin/env zsh
#
# Index Management Helpers for Quarto Teaching Workflow
# Version: 5.14.0
# Purpose: Manage index file links (ADD/UPDATE/REMOVE) for lectures, labs, exams
#
# Key Features:
# - Detect new/modified/deleted content files
# - Parse YAML frontmatter for titles
# - Auto-sort by week number
# - Cross-reference validation
# - Dependency tracking
#

# ============================================
# Dependency Tracking
# ============================================

# =============================================================================
# Function: _find_dependencies
# Purpose: Find all file dependencies for a Quarto document
# =============================================================================
# Arguments:
#   $1 - (required) Path to the Quarto file
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - List of dependent files, one per line (unique)
#
# Dependency Types:
#   - Sourced R/Python files: source("path/to/file.R")
#   - Cross-referenced sections: @sec-id → {#sec-id}
#   - Cross-referenced figures: @fig-id → {#fig-id}
#   - Cross-referenced tables: @tbl-id → {#tbl-id}
#
# Example:
#   deps=$(_find_dependencies "lectures/week-05.qmd")
#   echo "Dependencies: $deps"
#
# Notes:
#   - R source() paths resolved from project root and file directory
#   - Cross-references searched in all .qmd files
#   - Self-references excluded from output
# =============================================================================
_find_dependencies() {
    local file="$1"
    local deps=()

    if [[ ! -f "$file" ]]; then
        return 0
    fi

    # 1. Extract sourced R files: source("path/to/file.R")
    while IFS= read -r line; do
        # Match: source("file.R") or source('file.R')
        if [[ "$line" =~ 'source\("([^"]+)"\)' ]] || [[ "$line" =~ "source\('([^']+)'\)" ]]; then
            local sourced="${match[1]}"

            # R source() paths are relative to working directory (project root)
            # Try both: relative to project root and relative to file directory
            local abs_path=""

            # Option 1: Relative to project root (most common)
            if [[ -f "$sourced" ]]; then
                abs_path="$sourced"
            # Option 2: Relative to file's directory
            elif [[ -f "$(dirname "$file")/$sourced" ]]; then
                abs_path="$(dirname "$file")/$sourced"
            fi

            # Add if found
            if [[ -n "$abs_path" ]]; then
                deps+=("$abs_path")
            fi
        fi
    done < "$file"

    # 2. Extract cross-references: @sec-id, @fig-id, @tbl-id
    local cross_refs=($(grep -oE '@(sec|fig|tbl)-[a-z0-9_-]+' "$file" 2>/dev/null | sort -u))

    for ref in $cross_refs; do
        # ref is @sec-background, we need to search for {#sec-background}
        local ref_id="${ref#@}"  # Remove @ prefix

        # Find files containing this reference target
        # Look for: {#sec-id}, {#fig-id}, {#tbl-id}
        # Use find instead of glob to ensure portability
        local target_files=()
        if command -v find >/dev/null 2>&1; then
            while IFS= read -r target_file; do
                target_files+=("$target_file")
            done < <(find . -name "*.qmd" -type f -exec grep -l "{#${ref_id}}" {} \; 2>/dev/null)
        else
            # Fallback to glob (requires globstar)
            target_files=($(grep -l "{#${ref_id}}" **/*.qmd 2>/dev/null))
        fi

        for target_file in $target_files; do
            # Remove ./ prefix if present
            target_file="${target_file#./}"

            # Don't include self-reference
            if [[ "$target_file" != "$file" ]]; then
                deps+=("$target_file")
            fi
        done
    done

    # Return unique dependencies
    printf '%s\n' "${(u)deps[@]}"
}

# =============================================================================
# Function: _validate_cross_references
# Purpose: Validate that all cross-references have valid targets
# =============================================================================
# Arguments:
#   $@ - (required) One or more file paths to validate
#
# Returns:
#   0 - All references are valid
#   1 - One or more broken references found
#
# Output:
#   stdout - Error messages for broken references
#
# Example:
#   _validate_cross_references "lectures/week-01.qmd"
#   _validate_cross_references lectures/*.qmd
#
# Notes:
#   - Checks @sec-id, @fig-id, @tbl-id references
#   - Searches all .qmd files for target definitions
#   - Target format: {#sec-id}, {#fig-id}, {#tbl-id}
# =============================================================================
_validate_cross_references() {
    local files=("$@")
    local has_errors=0

    for file in "${files[@]}"; do
        if [[ ! -f "$file" ]]; then
            continue
        fi

        # Extract all cross-references
        local refs=($(grep -oE '@(sec|fig|tbl)-[a-z0-9_-]+' "$file" 2>/dev/null | sort -u))

        if [[ ${#refs[@]} -eq 0 ]]; then
            continue
        fi

        for full_ref in $refs; do
            # full_ref is @sec-background, search for {#sec-background}
            local ref_id="${full_ref#@}"  # Remove @ prefix

            # Check if reference exists in any .qmd file
            local found=$(grep -l "{#${ref_id}}" **/*.qmd 2>/dev/null | head -1)

            if [[ -z "$found" ]]; then
                echo "${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} Broken reference in ${FLOW_COLORS[bold]}$file${FLOW_COLORS[reset]}: $full_ref"
                has_errors=1
            fi
        done
    done

    return $has_errors
}

# ============================================
# Index Change Detection
# ============================================

# =============================================================================
# Function: _detect_index_changes
# Purpose: Detect what index file change is needed for a content file
# =============================================================================
# Arguments:
#   $1 - (required) Path to the content file
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Change type: "ADD", "UPDATE", "REMOVE", or "NONE"
#
# Example:
#   change=$(_detect_index_changes "lectures/week-05.qmd")
#   case "$change" in
#       ADD) echo "New file needs to be added to index" ;;
#       UPDATE) echo "Title changed, update index" ;;
#       REMOVE) echo "File deleted, remove from index" ;;
#       NONE) echo "No change needed" ;;
#   esac
#
# Notes:
#   - Determines content type from directory (lectures, labs, exams)
#   - Compares file title with existing index link title
#   - Returns NONE for unsupported directories
# =============================================================================
_detect_index_changes() {
    local file="$1"
    local basename="${file##*/}"
    local content_type=""

    # Determine content type from directory
    case "$file" in
        lectures/*) content_type="lectures" ;;
        labs/*)     content_type="labs" ;;
        exams/*)    content_type="exams" ;;
        *)          echo "NONE"; return 0 ;;
    esac

    # Find corresponding index file
    local index_file="home_${content_type}.qmd"
    if [[ ! -f "$index_file" ]]; then
        echo "NONE"
        return 0
    fi

    # Extract title from file's YAML frontmatter
    local new_title=$(_extract_title "$file")

    # Check if file is linked in index
    local existing_link=$(grep -F "$basename" "$index_file" 2>/dev/null || true)

    if [[ ! -f "$file" ]]; then
        # File deleted
        if [[ -n "$existing_link" ]]; then
            echo "REMOVE"
        else
            echo "NONE"
        fi
    elif [[ -z "$existing_link" ]]; then
        # New file (not in index)
        echo "ADD"
    else
        # File exists and in index - check if title changed
        local old_title=$(echo "$existing_link" | sed -n 's/.*\[\(.*\)\].*/\1/p')
        if [[ "$new_title" != "$old_title" ]]; then
            echo "UPDATE"
        else
            echo "NONE"
        fi
    fi
}

# =============================================================================
# Function: _extract_title
# Purpose: Extract title from YAML frontmatter of a Quarto file
# =============================================================================
# Arguments:
#   $1 - (required) Path to the file
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Title string (or empty if not found)
#
# Example:
#   title=$(_extract_title "lectures/week-01.qmd")
#   echo "Document title: $title"
#
# Dependencies:
#   - yq (preferred) or sed (fallback)
#
# Notes:
#   - Returns empty string if file doesn't exist or has no title
#   - Works with both quoted and unquoted YAML title values
# =============================================================================
_extract_title() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        return 0
    fi

    # Use yq if available, fallback to sed
    if command -v yq &>/dev/null; then
        yq '.title // ""' "$file" 2>/dev/null || echo ""
    else
        # Simple YAML parsing for title field
        sed -n '/^---$/,/^---$/p' "$file" | grep '^title:' | sed 's/title: *"\?\(.*\)"\?/\1/' 2>/dev/null || echo ""
    fi
}

# =============================================================================
# Function: _parse_week_number
# Purpose: Parse week number from filename for sorting
# =============================================================================
# Arguments:
#   $1 - (required) Filename to parse
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Week number (integer), or 999 if not found
#
# Supported Patterns:
#   - week-05.qmd → 5
#   - lecture-week05.qmd → 5
#   - 05-topic.qmd → 5
#
# Example:
#   week=$(_parse_week_number "week-05-regression.qmd")  # → 5
#   week=$(_parse_week_number "introduction.qmd")        # → 999
#
# Notes:
#   - Returns 999 for files without week numbers (sorts to end)
#   - Strips leading zeros
# =============================================================================
_parse_week_number() {
    local filename="$1"
    local week_num

    # Try different patterns
    if [[ "$filename" =~ week-?0*([0-9]+) ]]; then
        week_num="${match[1]}"
    elif [[ "$filename" =~ ^0*([0-9]+)- ]]; then
        week_num="${match[1]}"
    else
        # No week number found - return high value for sorting
        echo "999"
        return 0
    fi

    echo "$((10#$week_num))"  # Convert to base-10 integer
}

# ============================================
# Index Link Management
# ============================================

# =============================================================================
# Function: _update_index_link
# Purpose: Add or update a link in an index file (auto-sorted by week)
# =============================================================================
# Arguments:
#   $1 - (required) Path to the content file
#   $2 - (required) Path to the index file
#
# Returns:
#   0 - Link added or updated successfully
#   1 - Failure
#
# Example:
#   _update_index_link "lectures/week-05.qmd" "home_lectures.qmd"
#
# Notes:
#   - Extracts title from content file's YAML frontmatter
#   - If link exists, updates title; otherwise inserts in week order
#   - Uses sed with macOS/GNU compatibility
#   - Falls back to filename (without .qmd) if no title found
# =============================================================================
_update_index_link() {
    local content_file="$1"
    local index_file="$2"
    local basename="${content_file##*/}"
    local title=$(_extract_title "$content_file")
    local week_num=$(_parse_week_number "$basename")

    if [[ -z "$title" ]]; then
        title="${basename%.qmd}"
    fi

    # Check if link already exists (search for basename in markdown link format)
    # Use fixed string search with -F for exact matching
    local existing_line=$(grep -n -F "($basename)" "$index_file" 2>/dev/null | cut -d: -f1)

    if [[ -n "$existing_line" ]]; then
        # Update existing link - escape special characters for sed
        local escaped_title=$(echo "$title" | sed 's/[&/\]/\\&/g')
        local escaped_basename=$(echo "$basename" | sed 's/[&/\]/\\&/g')
        local link_text="- [$escaped_title]($escaped_basename)"

        # Use sed to replace the line
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "${existing_line}s|.*|$link_text|" "$index_file"
        else
            sed -i "${existing_line}s|.*|$link_text|" "$index_file"
        fi

        echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Updated link in $index_file"
    else
        # Add new link (find insertion point based on week number)
        local insert_line=$(_find_insertion_point "$index_file" "$week_num")
        local link_text="- [$title]($basename)"

        # Get file line count to detect append case
        local file_lines=$(wc -l < "$index_file" | tr -d ' ')

        # If insert_line is 0 or > file_lines, append at end
        # (sed can't insert past EOF, so use echo >> instead)
        if [[ $insert_line -eq 0 || $insert_line -gt $file_lines ]]; then
            # Append to end of file
            echo "$link_text" >> "$index_file"
        else
            # Insert before the specified line
            if [[ "$OSTYPE" == "darwin"* ]]; then
                # macOS sed: insert before line
                sed -i '' "${insert_line}i\\
$link_text
" "$index_file"
            else
                # GNU sed: insert before line
                sed -i "${insert_line}i $link_text" "$index_file"
            fi
        fi

        echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Added link to $index_file"
    fi

    return 0
}

# =============================================================================
# Function: _find_insertion_point
# Purpose: Find the correct line number to insert a link (sorted by week)
# =============================================================================
# Arguments:
#   $1 - (required) Path to the index file
#   $2 - (required) Week number for the new link
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Line number for insertion
#
# Example:
#   line=$(_find_insertion_point "home_lectures.qmd" 5)
#   # Returns line number where week 5 should be inserted
#
# Notes:
#   - Maintains ascending week order
#   - Skips YAML frontmatter
#   - Returns line_count+1 if should append at end
# =============================================================================
_find_insertion_point() {
    local index_file="$1"
    local target_week="$2"
    local line_num=0
    local insert_line=0
    local found_content=0

    # Read index file line by line
    while IFS= read -r line; do
        ((line_num++))

        # Skip until we find the content section (after YAML frontmatter)
        if [[ "$line" =~ ^--- ]] && [[ $found_content -eq 0 ]]; then
            found_content=1
            continue
        fi

        if [[ $found_content -eq 0 ]]; then
            continue
        fi

        # Check if line is a link (- [text](file) or * [text](file))
        if [[ "$line" == *"]("*")"* || "$line" == *"]("*")" ]]; then
            # Extract filename using sed
            local linked_file=$(echo "$line" | sed -n 's/.*(\(.*\))/\1/p')

            if [[ -n "$linked_file" ]]; then
                local linked_week=$(_parse_week_number "$linked_file")

                if [[ $linked_week -gt $target_week ]]; then
                    # Found a week greater than target - insert before this line
                    insert_line=$line_num
                    break
                fi
            fi
        fi
    done < "$index_file"

    # If no insertion point found, return line count + 1 (append at end)
    # Note: _update_index_link will detect this and use echo >> instead of sed
    if [[ $insert_line -eq 0 ]]; then
        insert_line=$((line_num + 1))
    fi

    echo "$insert_line"
}

# =============================================================================
# Function: _remove_index_link
# Purpose: Remove a link from an index file
# =============================================================================
# Arguments:
#   $1 - (required) Path to the content file (or its basename)
#   $2 - (required) Path to the index file
#
# Returns:
#   0 - Link removed successfully
#   1 - Link not found
#
# Example:
#   _remove_index_link "lectures/week-05.qmd" "home_lectures.qmd"
#
# Notes:
#   - Searches for both full path and basename matches
#   - Uses sed with macOS/GNU compatibility
# =============================================================================
_remove_index_link() {
    local content_file="$1"
    local index_file="$2"
    local basename="${content_file##*/}"

    # Find line number containing the link (match markdown link format)
    # Try full path first, then basename only (to handle both formats)
    local line_num=$(grep -n -F "($content_file)" "$index_file" 2>/dev/null | cut -d: -f1)

    if [[ -z "$line_num" ]]; then
        # Try basename only
        line_num=$(grep -n -F "($basename)" "$index_file" 2>/dev/null | cut -d: -f1)
    fi

    if [[ -z "$line_num" ]]; then
        echo "${FLOW_COLORS[warn]}⚠${FLOW_COLORS[reset]} Link not found in $index_file"
        return 1
    fi

    # Remove the line
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "${line_num}d" "$index_file"
    else
        sed -i "${line_num}d" "$index_file"
    fi

    echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Removed link from $index_file"
    return 0
}

# ============================================
# Interactive Index Management
# ============================================

# =============================================================================
# Function: _prompt_index_action
# Purpose: Interactive prompt for index management actions during deployment
# =============================================================================
# Arguments:
#   $1 - (required) Action: "ADD", "UPDATE", or "REMOVE"
#   $2 - (required) Path to the file
#   $3 - (optional) Old title (for UPDATE action)
#   $4 - (optional) New title (for ADD/UPDATE actions)
#
# Returns:
#   0 - User confirmed the action
#   1 - User skipped/cancelled
#
# Example:
#   if _prompt_index_action "ADD" "lectures/week-05.qmd" "" "Week 5: Regression"; then
#       _update_index_link "$file" "$index"
#   fi
#
# Notes:
#   - ADD: Default yes, shows new content detected
#   - UPDATE: Default no, shows old vs new title
#   - REMOVE: Default yes, shows deleted content warning
# =============================================================================
_prompt_index_action() {
    local action="$1"
    local file="$2"
    local old_title="$3"
    local new_title="$4"
    local basename="${file##*/}"

    case "$action" in
        ADD)
            echo ""
            echo "${FLOW_COLORS[info]}📄 New content detected:${FLOW_COLORS[reset]}"
            echo "  ${FLOW_COLORS[bold]}$basename${FLOW_COLORS[reset]}: $new_title"
            echo ""
            echo -n "${FLOW_COLORS[prompt]}Add to index file? [Y/n]:${FLOW_COLORS[reset]} "
            read -r confirm
            case "$confirm" in
                n|N|no|No|NO) return 1 ;;
                *) return 0 ;;
            esac
            ;;

        UPDATE)
            echo ""
            echo "${FLOW_COLORS[warn]}📝 Title changed:${FLOW_COLORS[reset]}"
            echo "  ${FLOW_COLORS[dim]}Old:${FLOW_COLORS[reset]} $old_title"
            echo "  ${FLOW_COLORS[bold]}New:${FLOW_COLORS[reset]} $new_title"
            echo ""
            echo -n "${FLOW_COLORS[prompt]}Update index link? [y/N]:${FLOW_COLORS[reset]} "
            read -r confirm
            case "$confirm" in
                y|Y|yes|Yes|YES) return 0 ;;
                *) return 1 ;;
            esac
            ;;

        REMOVE)
            echo ""
            echo "${FLOW_COLORS[error]}🗑  Content deleted:${FLOW_COLORS[reset]}"
            echo "  ${FLOW_COLORS[bold]}$basename${FLOW_COLORS[reset]}"
            echo ""
            echo -n "${FLOW_COLORS[prompt]}Remove from index? [Y/n]:${FLOW_COLORS[reset]} "
            read -r confirm
            case "$confirm" in
                n|N|no|No|NO) return 1 ;;
                *) return 0 ;;
            esac
            ;;
    esac
}

# =============================================================================
# Function: _get_index_file
# Purpose: Get the corresponding index file for a content file
# =============================================================================
# Arguments:
#   $1 - (required) Path to the content file
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Index file path or empty string if not supported
#
# Mapping:
#   lectures/* → home_lectures.qmd
#   labs/*     → home_labs.qmd
#   exams/*    → home_exams.qmd
#
# Example:
#   index=$(_get_index_file "lectures/week-05.qmd")
#   echo "$index"  # → home_lectures.qmd
# =============================================================================
_get_index_file() {
    local content_file="$1"

    case "$content_file" in
        lectures/*) echo "home_lectures.qmd" ;;
        labs/*)     echo "home_labs.qmd" ;;
        exams/*)    echo "home_exams.qmd" ;;
        *)          echo "" ;;
    esac
}

# ============================================
# Deployment Integration
# ============================================

# =============================================================================
# Function: _process_index_changes
# Purpose: Process all index changes for a set of files during deployment
# =============================================================================
# Arguments:
#   $@ - (required) List of file paths that changed
#
# Returns:
#   0 - Always
#
# Example:
#   # During deployment, process changed files
#   changed_files=($(git diff --name-only HEAD~1))
#   _process_index_changes "${changed_files[@]}"
#
# Dependencies:
#   - _detect_index_changes (internal)
#   - _get_index_file (internal)
#   - _prompt_index_action (internal)
#   - _update_index_link, _remove_index_link (internal)
#
# Notes:
#   - Interactively prompts for each ADD/UPDATE/REMOVE
#   - Skips files that don't need index changes
#   - Reports "No index changes needed" if nothing to do
# =============================================================================
_process_index_changes() {
    local files=("$@")
    local changes_made=0

    echo ""
    echo "${FLOW_COLORS[info]}🔍 Checking index files...${FLOW_COLORS[reset]}"

    for file in "${files[@]}"; do
        local change_type=$(_detect_index_changes "$file")

        if [[ "$change_type" == "NONE" ]]; then
            continue
        fi

        local index_file=$(_get_index_file "$file")
        if [[ -z "$index_file" ]] || [[ ! -f "$index_file" ]]; then
            continue
        fi

        local new_title=$(_extract_title "$file")
        local old_title=""

        if [[ "$change_type" == "UPDATE" ]]; then
            # Extract old title from existing link
            old_title=$(grep -F "${file##*/}" "$index_file" | sed -n 's/.*\[\(.*\)\].*/\1/p')
        fi

        # Prompt user
        if _prompt_index_action "$change_type" "$file" "$old_title" "$new_title"; then
            case "$change_type" in
                ADD|UPDATE)
                    _update_index_link "$file" "$index_file"
                    changes_made=1
                    ;;
                REMOVE)
                    _remove_index_link "$file" "$index_file"
                    changes_made=1
                    ;;
            esac
        fi
    done

    if [[ $changes_made -eq 0 ]]; then
        echo "${FLOW_COLORS[muted]}  No index changes needed${FLOW_COLORS[reset]}"
    fi

    return 0
}

# ============================================
# Export Functions
# ============================================

# All functions are already exported via function definition
# ZSH will make them available to calling scripts
