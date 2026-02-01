#!/usr/bin/env zsh
# .teach/validators/lint-shared.zsh - Quarto Lint: Shared Rules
# Structural lint checks for all .qmd files
# v1.0.0 - Custom Validator Plugin
#
# RULES:
#   1. LINT_CODE_LANG_TAG: Fenced code blocks must have language tags
#   2. LINT_DIV_BALANCE: Fenced divs (:::) must be balanced
#   3. LINT_CALLOUT_VALID: Only recognized callout types
#   4. LINT_HEADING_HIERARCHY: No skipped heading levels
#
# DEPENDENCIES:
#   - None (pure ZSH, grep -E for macOS)

# ============================================================================
# LOAD FLOW-CLI COLOR HELPERS
# ============================================================================

# Source flow-cli core utilities for ADHD-friendly color output
if [[ -z "$_FLOW_CORE_LOADED" ]]; then
    local core_path
    # Try to find core.zsh relative to this validator
    # Assume validators are at .teach/validators/ and core.zsh is at lib/core.zsh
    local validator_dir="${0:A:h}"
    local project_root="${validator_dir:h:h}"
    core_path="${project_root}/lib/core.zsh"

    if [[ -f "$core_path" ]]; then
        source "$core_path"
    else
        # Fallback: plain color codes if core.zsh not found
        typeset -gA FLOW_COLORS=(
            [reset]='\033[0m'
            [error]='\033[38;5;203m'
            [warning]='\033[38;5;221m'
            [info]='\033[38;5;117m'
        )
    fi
fi

# ============================================================================
# COLOR HELPERS (for lint errors without symbols)
# ============================================================================
# Note: The custom validators framework adds its own ✗ prefix,
# so we just apply colors without additional emoji symbols to avoid duplication

_lint_error() {
    echo -e "${FLOW_COLORS[error]}$*${FLOW_COLORS[reset]}"
}

_lint_warning() {
    echo -e "${FLOW_COLORS[warning]}$*${FLOW_COLORS[reset]}"
}

_lint_suggestion() {
    echo -e "${FLOW_COLORS[info]}Suggestion: $*${FLOW_COLORS[reset]}"
}

# ============================================================================
# VALIDATOR METADATA (Required)
# ============================================================================

VALIDATOR_NAME="Quarto Lint: Shared Rules"
VALIDATOR_VERSION="1.0.0"
VALIDATOR_DESCRIPTION="Structural lint checks for all .qmd files"

# ============================================================================
# VALID CALLOUT TYPES
# ============================================================================

typeset -ga VALID_CALLOUT_TYPES=(
    callout-note
    callout-tip
    callout-important
    callout-warning
    callout-caution
)

# ============================================================================
# RULE: LINT_CODE_LANG_TAG
# Fenced code blocks must have a language tag
# ============================================================================

_check_code_lang_tag() {
    local file="$1"
    local errors=()
    local line_num=0
    local in_code_block=0
    local in_yaml=0

    while IFS= read -r line; do
        ((line_num++))

        # Track YAML frontmatter (skip it)
        if [[ $line_num -eq 1 && "$line" == "---" ]]; then
            in_yaml=1
            continue
        fi
        if [[ $in_yaml -eq 1 && "$line" == "---" ]]; then
            in_yaml=0
            continue
        fi
        [[ $in_yaml -eq 1 ]] && continue

        # Track code block boundaries
        if [[ "$line" =~ ^\`\`\` ]]; then
            if [[ $in_code_block -eq 0 ]]; then
                # Opening fence — check for language tag
                in_code_block=1
                # Valid: ```{r}, ```{python}, ```text, ```r, etc.
                # Invalid: bare ``` with nothing after
                local after_backticks="${line#\`\`\`}"
                after_backticks="${after_backticks##[[:space:]]}"  # trim leading whitespace (spaces, tabs)
                if [[ -z "$after_backticks" ]]; then
                    # Error with color and emoji
                    errors+=("$(_lint_error "Line $line_num: LINT_CODE_LANG_TAG: Fenced code block without language tag")")
                    # Helpful suggestion
                    errors+=("$(_lint_suggestion "Add language tag, e.g., \`\`\`{r} or \`\`\`text or \`\`\`bash")")
                fi
            else
                # Closing fence
                in_code_block=0
            fi
        fi
    done < "$file"

    printf '%s\n' "${errors[@]}"
}

# ============================================================================
# RULE: LINT_DIV_BALANCE
# Fenced divs (:::) must be balanced
# ============================================================================

_check_div_balance() {
    local file="$1"
    local errors=()
    local line_num=0
    local in_code_block=0
    local in_yaml=0
    local div_depth=0
    local -a div_stack=()  # line numbers of openers

    while IFS= read -r line; do
        ((line_num++))

        # Skip YAML
        if [[ $line_num -eq 1 && "$line" == "---" ]]; then in_yaml=1; continue; fi
        if [[ $in_yaml -eq 1 && "$line" == "---" ]]; then in_yaml=0; continue; fi
        [[ $in_yaml -eq 1 ]] && continue

        # Skip code blocks
        if [[ "$line" =~ ^\`\`\` ]]; then
            ((in_code_block = 1 - in_code_block))
            continue
        fi
        [[ $in_code_block -eq 1 ]] && continue

        # Detect div openers: ::: {.something} or ::: something
        if [[ "$line" =~ ^:::+[[:space:]] || "$line" =~ ^:::+\{ ]]; then
            ((div_depth++))
            div_stack+=($line_num)
        # Detect div closers: bare ::: (with optional trailing whitespace)
        elif [[ "$line" =~ ^:::+[[:space:]]*$ ]]; then
            if [[ $div_depth -gt 0 ]]; then
                ((div_depth--))
                # Pop stack
                div_stack=(${div_stack[@]:0:$((${#div_stack[@]}-1))})
            else
                # Error: closing without opener
                errors+=("$(_lint_error "Line $line_num: LINT_DIV_BALANCE: Closing ::: without matching opener")")
                errors+=("$(_lint_suggestion "Remove extra closing ::: or add opening ::: {.class}")")
            fi
        fi
    done < "$file"

    # Report unclosed divs
    for opener_line in "${div_stack[@]}"; do
        errors+=("$(_lint_error "Line $opener_line: LINT_DIV_BALANCE: Unclosed fenced div (:::)")")
        errors+=("$(_lint_suggestion "Add closing ::: after the div content")")
    done

    printf '%s\n' "${errors[@]}"
}

# ============================================================================
# RULE: LINT_CALLOUT_VALID
# Only recognized callout types
# ============================================================================

_check_callout_valid() {
    local file="$1"
    local errors=()
    local line_num=0
    local in_code_block=0
    local in_yaml=0

    while IFS= read -r line; do
        ((line_num++))

        # Skip YAML
        if [[ $line_num -eq 1 && "$line" == "---" ]]; then in_yaml=1; continue; fi
        if [[ $in_yaml -eq 1 && "$line" == "---" ]]; then in_yaml=0; continue; fi
        [[ $in_yaml -eq 1 ]] && continue

        # Skip code blocks
        if [[ "$line" =~ ^\`\`\` ]]; then
            ((in_code_block = 1 - in_code_block))
            continue
        fi
        [[ $in_code_block -eq 1 ]] && continue

        # Check for callout divs: ::: {.callout-*}
        if [[ "$line" =~ \.callout- ]]; then
            # Extract callout type
            local callout_type=$(echo "$line" | grep -oE 'callout-[a-z]+')
            if [[ -n "$callout_type" ]]; then
                local is_valid=0
                for valid_type in "${VALID_CALLOUT_TYPES[@]}"; do
                    if [[ "$callout_type" == "$valid_type" ]]; then
                        is_valid=1
                        break
                    fi
                done
                if [[ $is_valid -eq 0 ]]; then
                    # Warning: invalid callout type
                    errors+=("$(_lint_warning "Line $line_num: LINT_CALLOUT_VALID: Unknown callout type '.${callout_type}'")")
                    errors+=("$(_lint_suggestion "Valid types: note, tip, important, warning, caution")")
                fi
            fi
        fi
    done < "$file"

    printf '%s\n' "${errors[@]}"
}

# ============================================================================
# RULE: LINT_HEADING_HIERARCHY
# No skipped heading levels
# ============================================================================

_check_heading_hierarchy() {
    local file="$1"
    local errors=()
    local line_num=0
    local in_code_block=0
    local in_yaml=0
    local prev_level=0

    while IFS= read -r line; do
        ((line_num++))

        # Skip YAML
        if [[ $line_num -eq 1 && "$line" == "---" ]]; then in_yaml=1; continue; fi
        if [[ $in_yaml -eq 1 && "$line" == "---" ]]; then in_yaml=0; continue; fi
        [[ $in_yaml -eq 1 ]] && continue

        # Skip code blocks
        if [[ "$line" =~ ^\`\`\` ]]; then
            ((in_code_block = 1 - in_code_block))
            continue
        fi
        [[ $in_code_block -eq 1 ]] && continue

        # Detect headings
        if [[ "$line" =~ ^#{1,6}\  ]]; then
            local hashes="${line%%[^#]*}"
            local level=${#hashes}

            # Only warn on deeper jumps (h1 -> h3 = skip)
            # Resets (h3 -> h1) are fine
            if [[ $prev_level -gt 0 && $level -gt $((prev_level + 1)) ]]; then
                # Warning: heading level skip
                errors+=("$(_lint_warning "Line $line_num: LINT_HEADING_HIERARCHY: Heading level skip (h${prev_level} → h${level})")")
                errors+=("$(_lint_suggestion "Use h$((prev_level + 1)) instead, or add intermediate heading levels")")
            fi
            prev_level=$level
        fi
    done < "$file"

    printf '%s\n' "${errors[@]}"
}

# ============================================================================
# MAIN VALIDATION FUNCTION (Required)
# ============================================================================

_validate() {
    local file="$1"
    local all_errors=()

    # Skip non-.qmd files
    [[ "$file" != *.qmd ]] && return 0

    # Skip if file doesn't exist
    [[ ! -f "$file" ]] && return 0

    # Run all checks
    local output

    output=$(_check_code_lang_tag "$file")
    [[ -n "$output" ]] && while IFS= read -r e; do all_errors+=("$e"); done <<< "$output"

    output=$(_check_div_balance "$file")
    [[ -n "$output" ]] && while IFS= read -r e; do all_errors+=("$e"); done <<< "$output"

    output=$(_check_callout_valid "$file")
    [[ -n "$output" ]] && while IFS= read -r e; do all_errors+=("$e"); done <<< "$output"

    output=$(_check_heading_hierarchy "$file")
    [[ -n "$output" ]] && while IFS= read -r e; do all_errors+=("$e"); done <<< "$output"

    if [[ ${#all_errors[@]} -gt 0 ]]; then
        printf '%s\n' "${all_errors[@]}"
        return 1
    fi
    return 0
}
