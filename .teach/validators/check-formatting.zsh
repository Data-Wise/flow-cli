#!/usr/bin/env zsh
# .teach/validators/check-formatting.zsh - Formatting Validator
# Validates Quarto file formatting and structure
# v1.0.0 - Custom Validator Plugin
#
# VALIDATES:
#   - Heading hierarchy (no skipped levels)
#   - Code chunk options (valid Quarto options)
#   - Quote consistency (mixed " and ')
#   - Common formatting issues
#
# CHECKS:
#   1. Heading hierarchy: # → ## → ### (no skips like # → ###)
#   2. Code chunk options: Valid Quarto chunk options only
#   3. Quote consistency: Prefer one style per file
#
# DEPENDENCIES:
#   - None (pure ZSH)

# ============================================================================
# VALIDATOR METADATA (Required)
# ============================================================================

VALIDATOR_NAME="Formatting Validator"
VALIDATOR_VERSION="1.0.0"
VALIDATOR_DESCRIPTION="Validates Quarto formatting and structure"

# ============================================================================
# VALID QUARTO CHUNK OPTIONS
# ============================================================================

# Common valid Quarto chunk options
# Source: https://quarto.org/docs/reference/cells/cells-knitr.html
typeset -ga VALID_CHUNK_OPTIONS=(
    # Evaluation
    eval
    error
    include

    # Output
    echo
    output
    warning
    message

    # Code display
    code-fold
    code-summary
    code-overflow
    code-line-numbers

    # Figures
    fig-cap
    fig-alt
    fig-width
    fig-height
    fig-align
    fig-format
    fig-dpi

    # Tables
    tbl-cap
    tbl-colwidths

    # Layout
    layout
    layout-ncol
    layout-nrow
    layout-valign

    # Execution
    cache
    freeze
    dependson

    # File paths
    file
    code-file

    # Labels
    label
    id

    # Classes and attributes
    classes
    class
    attr

    # Engine specific
    engine
    comment
    collapse
)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Extract headings from file with line numbers
# Returns: line_num:level:heading_text
_extract_headings() {
    local file="$1"
    local headings=()

    local line_num=0
    local in_code_block=0

    while IFS= read -r line; do
        ((line_num++))

        # Track code blocks
        if [[ "$line" == '```'* ]]; then
            ((in_code_block = 1 - in_code_block))
            continue
        fi

        # Skip if in code block
        [[ $in_code_block -eq 1 ]] && continue

        # Extract headings (lines starting with #)
        if [[ "$line" == '#'* ]]; then
            # Count number of # symbols
            local level
            level=$(echo "$line" | grep -o '^#*' | wc -c)
            ((level--))  # Adjust for trailing newline

            # Extract heading text
            local text
            text=$(echo "$line" | sed 's/^#* *//')

            headings+=("$line_num:$level:$text")
        fi
    done < "$file"

    printf '%s\n' "${headings[@]}"
}

# Check heading hierarchy for skipped levels
# Returns: Errors if hierarchy is violated
_check_heading_hierarchy() {
    local headings=("$@")
    local errors=()
    local previous_level=0

    for heading in "${headings[@]}"; do
        local line_num="${heading%%:*}"
        local rest="${heading#*:}"
        local level="${rest%%:*}"

        # Check if level skip occurred (e.g., # → ###)
        if [[ $level -gt $((previous_level + 1)) ]]; then
            local skipped=$((level - previous_level))
            errors+=("Line $line_num: Heading hierarchy skip (h$previous_level → h$level, skipped $skipped levels)")
        fi

        previous_level=$level
    done

    printf '%s\n' "${errors[@]}"
}

# Extract code chunks with options
# Returns: line_num:option_name
_extract_code_chunks() {
    local file="$1"
    local chunks=()

    local line_num=0
    local in_chunk=0
    local chunk_start=0

    while IFS= read -r line; do
        ((line_num++))

        # Detect code chunk start (```{lang} or ```{r})
        if [[ "$line" == '```{'* ]]; then
            in_chunk=1
            chunk_start=$line_num

            # Extract chunk options from header line
            # Format: ```{r, option1=value1, option2=value2}
            local chunk_header
            chunk_header=$(echo "$line" | sed 's/```{[^,}]*//' | sed 's/}$//')

            # Split by comma and extract option names
            local options
            options=$(echo "$chunk_header" | tr ',' '\n')

            while IFS= read -r option; do
                # Trim whitespace
                option=$(echo "$option" | sed 's/^ *//; s/ *$//')

                # Skip empty options
                [[ -z "$option" ]] && continue

                # Extract option name (before = sign)
                local option_name
                if echo "$option" | grep -q '='; then
                    option_name=$(echo "$option" | cut -d'=' -f1 | sed 's/ *$//')
                else
                    option_name="$option"
                fi

                # Skip label/id (these are valid)
                [[ "$option_name" == "label" || "$option_name" == "#"* ]] && continue

                chunks+=("$chunk_start:$option_name")
            done <<< "$options"
        fi

        # Detect code chunk end
        if [[ $in_chunk -eq 1 && "$line" == '```' ]]; then
            in_chunk=0
        fi
    done < "$file"

    printf '%s\n' "${chunks[@]}"
}

# Validate chunk options against known valid options
_check_chunk_options() {
    local chunks=("$@")
    local errors=()

    for chunk in "${chunks[@]}"; do
        local line_num="${chunk%%:*}"
        local option="${chunk#*:}"

        # Skip empty options
        [[ -z "$option" ]] && continue

        # Check if option is valid
        local is_valid=0
        for valid_option in "${VALID_CHUNK_OPTIONS[@]}"; do
            if [[ "$option" == "$valid_option" ]]; then
                is_valid=1
                break
            fi
        done

        # Check for common option prefixes (e.g., fig-*, tbl-*)
        if [[ $is_valid -eq 0 ]]; then
            if echo "$option" | grep -qE '^(fig|tbl|layout|code)-'; then
                is_valid=1
            fi
        fi

        if [[ $is_valid -eq 0 ]]; then
            errors+=("Line $line_num: Unknown chunk option: $option")
        fi
    done

    printf '%s\n' "${errors[@]}"
}

# Check quote consistency
# Returns: Warnings if mixed quotes are used
_check_quote_consistency() {
    local file="$1"
    local errors=()

    local line_num=0
    local double_quotes=0
    local single_quotes=0

    while IFS= read -r line; do
        ((line_num++))

        # Count quote types (excluding code blocks and inline code)
        # This is a simplified check - might have false positives

        # Count double quotes
        local doubles
        doubles=$(echo "$line" | grep -o '"' | wc -l)
        ((double_quotes += doubles))

        # Count single quotes
        local singles
        singles=$(echo "$line" | grep -o "'" | wc -l)
        ((single_quotes += singles))
    done < "$file"

    # Check if both quote types are used significantly
    # Use threshold: if both are > 5, suggest consistency
    if [[ $double_quotes -gt 5 && $single_quotes -gt 5 ]]; then
        errors+=("Mixed quote styles detected ($double_quotes double, $single_quotes single) - consider using one style consistently")
    fi

    printf '%s\n' "${errors[@]}"
}

# ============================================================================
# MAIN VALIDATION FUNCTION (Required)
# ============================================================================

# Validate formatting in a Quarto file
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
        return 0
    fi

    # Check 1: Heading hierarchy
    local headings
    headings=($(_extract_headings "$file"))

    if [[ ${#headings[@]} -gt 0 ]]; then
        local hierarchy_errors
        hierarchy_errors=($(_check_heading_hierarchy "${headings[@]}"))
        if [[ ${#hierarchy_errors[@]} -gt 0 ]]; then
            errors+=("${hierarchy_errors[@]}")
        fi
    fi

    # Check 2: Code chunk options
    local chunks
    chunks=($(_extract_code_chunks "$file"))

    if [[ ${#chunks[@]} -gt 0 ]]; then
        local chunk_errors
        chunk_errors=($(_check_chunk_options "${chunks[@]}"))
        if [[ ${#chunk_errors[@]} -gt 0 ]]; then
            errors+=("${chunk_errors[@]}")
        fi
    fi

    # Check 3: Quote consistency (warning only)
    local quote_warnings
    quote_warnings=($(_check_quote_consistency "$file"))
    if [[ ${#quote_warnings[@]} -gt 0 ]]; then
        # These are warnings, not errors, so we don't fail validation
        # But we still report them
        for warning in "${quote_warnings[@]}"; do
            echo "WARNING: $warning" >&2
        done
    fi

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
    # No initialization needed
    return 0
}

# Cleanup after validation (optional)
_validator_cleanup() {
    # No cleanup needed
    return 0
}
