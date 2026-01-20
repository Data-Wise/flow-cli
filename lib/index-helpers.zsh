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

#
# Find all dependencies for a given file
# Dependencies include:
#   - Sourced R/Python files
#   - Cross-referenced sections (@sec-id)
#   - Cross-referenced figures (@fig-id)
#   - Cross-referenced tables (@tbl-id)
#
# Usage: _find_dependencies <file>
# Returns: List of dependent files (one per line)
#
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
        local target_files=($(grep -l "{#${ref_id}}" **/*.qmd 2>/dev/null))

        for target_file in $target_files; do
            # Don't include self-reference
            if [[ "$target_file" != "$file" ]]; then
                deps+=("$target_file")
            fi
        done
    done

    # Return unique dependencies
    printf '%s\n' "${(u)deps[@]}"
}

#
# Validate cross-references in files
# Checks if all @sec-id, @fig-id, @tbl-id references have valid targets
#
# Usage: _validate_cross_references <file1> [file2 ...]
# Returns: 0 if all valid, 1 if broken references found
#
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

#
# Detect changes to index files (ADD/UPDATE/REMOVE)
# Compares files against index files (home_lectures.qmd, home_labs.qmd, etc.)
#
# Usage: _detect_index_changes <file>
# Returns: ADD|UPDATE|REMOVE|NONE
#
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

#
# Extract title from YAML frontmatter
#
# Usage: _extract_title <file>
# Returns: Title string
#
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

#
# Parse week number from filename
# Supports: week-05.qmd, lecture-week05.qmd, 05-topic.qmd
#
# Usage: _parse_week_number <filename>
# Returns: Week number (integer) or 999 if not found
#
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

#
# Add or update a link in an index file
# Auto-sorts by week number
#
# Usage: _update_index_link <content_file> <index_file>
# Returns: 0 on success, 1 on failure
#
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

        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS sed: insert before line
            sed -i '' "${insert_line}i\\
$link_text
" "$index_file"
        else
            # GNU sed: insert before line
            sed -i "${insert_line}i $link_text" "$index_file"
        fi

        echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Added link to $index_file"
    fi

    return 0
}

#
# Find insertion point for new link based on week number
# Links are sorted by week number in ascending order
#
# Usage: _find_insertion_point <index_file> <week_num>
# Returns: Line number for insertion
#
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

    # If no insertion point found, append at end
    if [[ $insert_line -eq 0 ]]; then
        insert_line=$((line_num + 1))
    fi

    echo "$insert_line"
}

#
# Remove a link from an index file
#
# Usage: _remove_index_link <content_file> <index_file>
# Returns: 0 on success, 1 if not found
#
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

#
# Prompt user for index management action
# Used during deployment to manage index links
#
# Usage: _prompt_index_action <action> <file> <old_title> <new_title>
# Actions: ADD, UPDATE, REMOVE
# Returns: 0 if action confirmed, 1 if skipped
#
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

#
# Get index file for content type
#
# Usage: _get_index_file <content_file>
# Returns: Index file path or empty string
#
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

#
# Process index changes for deployment
# Detects changed files and prompts for index updates
#
# Usage: _process_index_changes <files...>
# Returns: 0 on success
#
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
