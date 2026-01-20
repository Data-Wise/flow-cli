#!/usr/bin/env zsh
# .teach/validators/check-links.zsh - Link Validator
# Validates internal and external links in Quarto files
# v1.0.0 - Custom Validator Plugin
#
# VALIDATES:
#   - Internal links (file existence)
#   - Image paths (file existence)
#   - External URLs (HTTP status codes)
#   - Reports broken links with line numbers
#
# FEATURES:
#   - Supports --skip-external flag (via VALIDATOR_SKIP_EXTERNAL env var)
#   - Timeout for external checks (5 seconds)
#   - Handles relative paths correctly
#
# DEPENDENCIES:
#   - curl (for external URL checking)

# ============================================================================
# VALIDATOR METADATA (Required)
# ============================================================================

VALIDATOR_NAME="Link Validator"
VALIDATOR_VERSION="1.0.0"
VALIDATOR_DESCRIPTION="Validates internal links, images, and external URLs"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Extract markdown links from file
# Returns: line_num:type:target (type = link|image)
_extract_links() {
    local file="$1"
    local links=()

    local line_num=0
    while IFS= read -r line; do
        ((line_num++))

        # Skip code blocks (lines starting with ``` or 4+ spaces)
        if echo "$line" | grep -qE '^(```|    )'; then
            continue
        fi

        # Extract markdown links: [text](url)
        local md_links
        md_links=$(echo "$line" | grep -oE '\[[^]]+\]\([^)]+\)')
        while IFS= read -r link; do
            if [[ -n "$link" ]]; then
                # Extract URL from [text](url)
                local url
                url=$(echo "$link" | sed 's/.*](\([^)]*\)).*/\1/')
                links+=("$line_num:link:$url")
            fi
        done <<< "$md_links"

        # Extract image links: ![alt](path)
        local img_links
        img_links=$(echo "$line" | grep -oE '!\[[^]]*\]\([^)]+\)')
        while IFS= read -r img; do
            if [[ -n "$img" ]]; then
                # Extract path from ![alt](path)
                local path
                path=$(echo "$img" | sed 's/.*](\([^)]*\)).*/\1/')
                links+=("$line_num:image:$path")
            fi
        done <<< "$img_links"

        # Extract HTML links: <a href="url">
        local html_links
        html_links=$(echo "$line" | grep -oE '<a[^>]+href="[^"]+"')
        while IFS= read -r html; do
            if [[ -n "$html" ]]; then
                local url
                url=$(echo "$html" | sed 's/.*href="\([^"]*\)".*/\1/')
                links+=("$line_num:link:$url")
            fi
        done <<< "$html_links"

        # Extract HTML images: <img src="path">
        local html_imgs
        html_imgs=$(echo "$line" | grep -oE '<img[^>]+src="[^"]+"')
        while IFS= read -r html; do
            if [[ -n "$html" ]]; then
                local path
                path=$(echo "$html" | sed 's/.*src="\([^"]*\)".*/\1/')
                links+=("$line_num:image:$path")
            fi
        done <<< "$html_imgs"
    done < "$file"

    # Return links
    printf '%s\n' "${links[@]}"
}

# Check if URL is external
_is_external_url() {
    local url="$1"

    # Check if URL starts with http:// or https://
    if echo "$url" | grep -qE '^https?://'; then
        return 0
    fi

    return 1
}

# Check if URL is an anchor link
_is_anchor_link() {
    local url="$1"

    # Anchor links start with #
    if [[ "$url" == \#* ]]; then
        return 0
    fi

    return 1
}

# Resolve relative path from file location
_resolve_path() {
    local file="$1"
    local target="$2"

    local file_dir
    file_dir=$(dirname "$file")

    # If target is absolute, return as-is
    if [[ "$target" == /* ]]; then
        echo "$target"
        return
    fi

    # Resolve relative path
    local resolved
    resolved=$(cd "$file_dir" 2>/dev/null && realpath "$target" 2>/dev/null)

    if [[ -n "$resolved" ]]; then
        echo "$resolved"
    else
        # Fallback: simple path join
        echo "$file_dir/$target"
    fi
}

# Check external URL with curl
# Returns: 0 if reachable, 1 if broken
_check_external_url() {
    local url="$1"
    local timeout="${2:-5}"  # Default 5 second timeout

    # Check if curl is available
    if ! command -v curl &>/dev/null; then
        return 0  # Skip check if curl not available
    fi

    # Use curl to check HTTP status
    # -s: silent, -f: fail on error, -I: HEAD request only, --max-time: timeout
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" -I --max-time "$timeout" "$url" 2>/dev/null)

    # Check if curl succeeded and got 2xx or 3xx status
    if [[ "$http_code" =~ ^[23][0-9][0-9]$ ]]; then
        return 0
    fi

    # Return failure with status code
    echo "$http_code"
    return 1
}

# Check if file exists (for internal links and images)
_check_file_exists() {
    local file="$1"
    local target="$2"

    # Resolve relative path
    local resolved
    resolved=$(_resolve_path "$file" "$target")

    # Check if file exists
    if [[ -f "$resolved" || -d "$resolved" ]]; then
        return 0
    fi

    return 1
}

# ============================================================================
# MAIN VALIDATION FUNCTION (Required)
# ============================================================================

# Validate links in a Quarto file
# Arguments: $1 = file path
# Returns: 0 if valid, 1 if errors found
# Prints: Error messages to stdout
_validate() {
    local file="$1"
    local errors=()
    local skip_external="${VALIDATOR_SKIP_EXTERNAL:-0}"

    # Check file exists
    if [[ ! -f "$file" ]]; then
        echo "File not found"
        return 1
    fi

    # Only validate .qmd and .md files
    if [[ "$file" != *.qmd && "$file" != *.md ]]; then
        return 0
    fi

    # Extract links from file
    local links
    links=($(_extract_links "$file"))

    # If no links, validation passes
    if [[ ${#links[@]} -eq 0 ]]; then
        return 0
    fi

    # Validate each link
    for link_entry in "${links[@]}"; do
        # Parse link entry: line_num:type:target
        local line_num="${link_entry%%:*}"
        local rest="${link_entry#*:}"
        local link_type="${rest%%:*}"
        local target="${rest#*:}"

        # Skip empty targets
        [[ -z "$target" ]] && continue

        # Skip anchor links (always valid)
        if _is_anchor_link "$target"; then
            continue
        fi

        # Handle external URLs
        if _is_external_url "$target"; then
            # Skip external checks if flag set
            if [[ $skip_external -eq 1 ]]; then
                continue
            fi

            # Check external URL
            local status
            status=$(_check_external_url "$target")
            if [[ $? -ne 0 ]]; then
                if [[ -n "$status" && "$status" != "000" ]]; then
                    errors+=("Line $line_num: Broken external $link_type: $target (HTTP $status)")
                else
                    errors+=("Line $line_num: Unreachable external $link_type: $target (timeout or network error)")
                fi
            fi
        else
            # Internal link or image - check file existence
            if ! _check_file_exists "$file" "$target"; then
                errors+=("Line $line_num: Broken internal $link_type: $target (file not found)")
            fi
        fi
    done

    # Print errors
    if [[ ${#errors[@]} -gt 0 ]]; then
        printf '%s\n' "${errors[@]}"
        return 1
    fi

    return 0
}

# ============================================================================
# OPTIONAL FUNCTIONS
# ============================================================================

# Initialize validator (optional)
_validator_init() {
    # Check if curl is available for external URL checking
    if ! command -v curl &>/dev/null; then
        echo "WARNING: curl not found - external URL checking disabled" >&2
    fi
    return 0
}

# Cleanup after validation (optional)
_validator_cleanup() {
    # No cleanup needed
    return 0
}
