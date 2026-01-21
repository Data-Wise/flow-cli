#!/usr/bin/env zsh
# .teach/validators/check-citations.zsh - Citation Validator
# Validates Pandoc citations against BibTeX files
# v1.0.0 - Custom Validator Plugin
#
# VALIDATES:
#   - Citations exist in .bib files ([@author2020])
#   - Citation format is valid Pandoc syntax
#   - Multiple citation support ([@a2020; @b2021])
#   - Reports missing citations with line numbers
#
# DEPENDENCIES:
#   - None (pure ZSH)

# ============================================================================
# VALIDATOR METADATA (Required)
# ============================================================================

VALIDATOR_NAME="Citation Validator"
VALIDATOR_VERSION="1.0.0"
VALIDATOR_DESCRIPTION="Validates Pandoc citations against BibTeX references"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Extract all citation keys from a .qmd file
# Returns: Array of citation keys (one per line)
_extract_citations() {
    local file="$1"
    local citations=()

    # Read file line by line to track line numbers
    local line_num=0
    while IFS= read -r line; do
        ((line_num++))

        # Extract citations from line
        # Pattern: [@key] or [@key; @key2; @key3]
        # Also handles: @key in text (without brackets)

        # Method 1: Bracketed citations [@key]
        local bracketed
        bracketed=$(echo "$line" | grep -oE '\[@[^]]+\]')
        if [[ -n "$bracketed" ]]; then
            # Extract individual keys from bracketed citation
            local keys
            keys=$(echo "$bracketed" | sed 's/\[@//g; s/\]//g; s/;//g' | tr ' ' '\n' | grep -E '^@')
            while IFS= read -r key; do
                [[ -n "$key" ]] && citations+=("$line_num:${key#@}")
            done <<< "$keys"
        fi

        # Method 2: Inline citations @key (but not in code blocks or URLs)
        # Skip if line is in code block (starts with ``` or has 4+ spaces)
        if ! echo "$line" | grep -qE '^(```|    )'; then
            # Extract standalone @key patterns (not in URLs)
            local inline
            inline=$(echo "$line" | grep -oE '(^|[^/])@[a-zA-Z][a-zA-Z0-9_:-]*' | grep -oE '@[a-zA-Z][a-zA-Z0-9_:-]*')
            while IFS= read -r key; do
                if [[ -n "$key" ]]; then
                    # Skip if it looks like a mention (e.g., @username)
                    # Valid citation keys typically have numbers or specific patterns
                    if echo "$key" | grep -qE '@[a-zA-Z]+[0-9]'; then
                        citations+=("$line_num:${key#@}")
                    fi
                fi
            done <<< "$inline"
        fi
    done < "$file"

    # Return unique citations with line numbers (using ZSH builtins)
    local unique_citations
    unique_citations=(${(u)citations})  # (u) = unique
    printf '%s\n' "${unique_citations[@]}"
}

# Find all .bib files in project
# Searches current directory and common locations
_find_bib_files() {
    local search_dir="${1:-.}"
    local bib_files=()

    # Search in common locations
    local search_paths=(
        "$search_dir"
        "$search_dir/references"
        "$search_dir/bib"
        "$search_dir/bibliography"
        "$search_dir/.."
    )

    for path in "${search_paths[@]}"; do
        if [[ -d "$path" ]]; then
            for bib in "$path"/*.bib(N); do
                [[ -f "$bib" ]] && bib_files+=("$bib")
            done
        fi
    done

    # Return unique .bib files (using ZSH builtins)
    local unique_bibs
    unique_bibs=(${(u)bib_files})  # (u) = unique
    printf '%s\n' "${unique_bibs[@]}"
}

# Extract all citation keys from .bib files
# Returns: Array of available citation keys
_extract_bib_keys() {
    local bib_files=("$@")
    local keys=()

    for bib in "${bib_files[@]}"; do
        # Extract @type{key, pattern from .bib files
        local bib_keys
        bib_keys=$(grep -E '^@[a-zA-Z]+\{' "$bib" | sed 's/@[a-zA-Z]*{//; s/,$//' | tr -d ' ')
        while IFS= read -r key; do
            [[ -n "$key" ]] && keys+=("$key")
        done <<< "$bib_keys"
    done

    # Return unique keys (using ZSH builtins)
    local unique_keys
    unique_keys=(${(u)keys})  # (u) = unique
    printf '%s\n' "${unique_keys[@]}"
}

# Check if citation key exists in available keys
_citation_exists() {
    local citation="$1"
    shift
    local available_keys=("$@")

    for key in "${available_keys[@]}"; do
        [[ "$key" == "$citation" ]] && return 0
    done

    return 1
}

# Validate citation format
# Valid formats:
#   - @author2020
#   - @author-etal2020
#   - @author_2020
#   - @author:2020
_validate_citation_format() {
    local citation="$1"

    # Valid citation key pattern (Pandoc/BibTeX compatible)
    if echo "$citation" | grep -qE '^[a-zA-Z][a-zA-Z0-9_:-]*$'; then
        return 0
    fi

    return 1
}

# ============================================================================
# MAIN VALIDATION FUNCTION (Required)
# ============================================================================

# Validate citations in a Quarto file
# Arguments: $1 = file path
# Returns: 0 if valid, 1 if errors found
# Prints: Error messages to stdout
_validate() {
    local file="$1"
    local errors=()

    # Check file exists
    if [[ ! -f "$file" ]]; then
        echo "File not found"
        return 1
    fi

    # Only validate .qmd files
    if [[ "$file" != *.qmd ]]; then
        # Not an error, just skip
        return 0
    fi

    # Extract citations from file
    local citations
    citations=($(_extract_citations "$file"))

    # If no citations, validation passes
    if [[ ${#citations[@]} -eq 0 ]]; then
        return 0
    fi

    # Find .bib files
    local file_dir
    file_dir=$(dirname "$file")
    local bib_files
    bib_files=($(_find_bib_files "$file_dir"))

    # Check if .bib files exist
    if [[ ${#bib_files[@]} -eq 0 ]]; then
        # No .bib files found, but citations exist
        for citation_with_line in "${citations[@]}"; do
            local line_num="${citation_with_line%%:*}"
            local citation="${citation_with_line#*:}"
            errors+=("Line $line_num: No .bib files found (citation: @$citation)")
        done
        printf '%s\n' "${errors[@]}"
        return 1
    fi

    # Extract available citation keys from .bib files
    local available_keys
    available_keys=($(_extract_bib_keys "${bib_files[@]}"))

    # Validate each citation
    for citation_with_line in "${citations[@]}"; do
        local line_num="${citation_with_line%%:*}"
        local citation="${citation_with_line#*:}"

        # Check citation format
        if ! _validate_citation_format "$citation"; then
            errors+=("Line $line_num: Invalid citation format: @$citation")
            continue
        fi

        # Check if citation exists in .bib files
        if ! _citation_exists "$citation" "${available_keys[@]}"; then
            errors+=("Line $line_num: Missing citation: @$citation")
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
# Check dependencies, setup environment
_validator_init() {
    # No dependencies needed for this validator
    return 0
}

# Cleanup after validation (optional)
_validator_cleanup() {
    # No cleanup needed
    return 0
}
