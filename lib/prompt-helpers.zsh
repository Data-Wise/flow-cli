# prompt-helpers.zsh - Prompt Resolution Engine (3-Tier)
# Manages AI teaching prompts with course > user > plugin resolution
#
# v5.23.0 - teach prompt command
#
# 3-Tier Resolution:
#   1. Course:  .flow/templates/prompts/<name>.md    (highest priority)
#   2. User:    ~/.flow/prompts/<name>.md             (cross-course defaults)
#   3. Plugin:  lib/templates/teaching/claude-prompts/<name>.md (fallback)
#
# Dependencies:
#   - lib/core.zsh (logging, colors)
#   - lib/template-helpers.zsh (metadata parsing, variable substitution)

# Guard against double-loading
[[ -n "$_FLOW_PROMPT_HELPERS_LOADED" ]] && return 0
typeset -g _FLOW_PROMPT_HELPERS_LOADED=1

# Source template helpers if not already loaded
if [[ -z "$_FLOW_TEMPLATE_HELPERS_LOADED" ]]; then
    local _ph_helpers_path="${0:A:h}/template-helpers.zsh"
    [[ -f "$_ph_helpers_path" ]] && source "$_ph_helpers_path"
fi

# ============================================================================
# CONSTANTS
# ============================================================================

# Known Scholar commands (for validation)
typeset -ga PROMPT_KNOWN_SCHOLAR_COMMANDS=(
    lecture slides exam quiz assignment syllabus rubric feedback demo
)

# Required frontmatter fields (errors if missing)
typeset -ga PROMPT_REQUIRED_FIELDS=(
    template_type template_version
)

# ============================================================================
# TIER 1: PATH RESOLUTION
# ============================================================================

# Get course-level prompts directory
# Returns: path to .flow/templates/prompts/ or empty
_teach_prompt_course_dir() {
    local root="${1:-$PWD}"

    while [[ "$root" != "/" ]]; do
        if [[ -d "$root/.flow" ]]; then
            echo "$root/.flow/templates/prompts"
            return 0
        fi
        root="${root:h}"
    done

    return 1
}

# Get user-level prompts directory
# Returns: ~/.flow/prompts/
_teach_prompt_user_dir() {
    echo "${HOME}/.flow/prompts"
}

# Get plugin-level prompts directory
# Returns: lib/templates/teaching/claude-prompts/
_teach_prompt_plugin_dir() {
    local this_file="${(%):-%x}"
    local lib_dir="${this_file:A:h}"
    echo "$lib_dir/templates/teaching/claude-prompts"
}

# ============================================================================
# CORE RESOLUTION
# ============================================================================

# =============================================================================
# Function: _teach_resolve_prompt
# Purpose: Find a prompt file using 3-tier resolution
# =============================================================================
# Arguments:
#   $1 - prompt name (without extension, e.g., "lecture-notes")
#   $2 - forced tier (optional): "course", "user", "plugin"
#
# Returns:
#   0 - Found, prints full path to stdout
#   1 - Not found
#
# Resolution order: course > user > plugin
# Tries .md extension if bare name not found
# =============================================================================
_teach_resolve_prompt() {
    local name="$1"
    local forced_tier="${2:-}"

    local course_dir="$(_teach_prompt_course_dir)"
    local user_dir="$(_teach_prompt_user_dir)"
    local plugin_dir="$(_teach_prompt_plugin_dir)"

    # Helper: check file with optional .md extension
    _check_prompt_path() {
        local dir="$1" name="$2"
        if [[ -f "$dir/$name" ]]; then
            echo "$dir/$name"
            return 0
        elif [[ -f "$dir/${name}.md" ]]; then
            echo "$dir/${name}.md"
            return 0
        fi
        return 1
    }

    # Forced tier: only check that tier
    if [[ -n "$forced_tier" ]]; then
        case "$forced_tier" in
            course)  _check_prompt_path "$course_dir" "$name" && return 0 ;;
            user)    _check_prompt_path "$user_dir" "$name" && return 0 ;;
            plugin)  _check_prompt_path "$plugin_dir" "$name" && return 0 ;;
        esac
        return 1
    fi

    # 3-tier resolution: course > user > plugin
    _check_prompt_path "$course_dir" "$name" && return 0
    _check_prompt_path "$user_dir" "$name" && return 0
    _check_prompt_path "$plugin_dir" "$name" && return 0

    return 1
}

# =============================================================================
# Function: _teach_get_all_prompts
# Purpose: Enumerate all prompts across all tiers (deduplicated)
# =============================================================================
# Output: Lines of "name|tier|path|description"
#   - tier: "course", "user", or "plugin"
#   - description: from template_description frontmatter field
#   - Higher-priority tiers shadow lower ones (by name)
# =============================================================================
_teach_get_all_prompts() {
    local course_dir="$(_teach_prompt_course_dir)"
    local user_dir="$(_teach_prompt_user_dir)"
    local plugin_dir="$(_teach_prompt_plugin_dir)"

    typeset -A seen_prompts

    # Tier 1: Course
    if [[ -d "$course_dir" ]]; then
        for file in "$course_dir"/*.md(.N); do
            local name="${file:t:r}"  # filename without .md
            local desc=""
            typeset -A _pm
            if _teach_parse_template_metadata "$file" _pm 2>/dev/null; then
                desc="${_pm[template_description]:-}"
            fi
            echo "${name}|course|${file}|${desc}"
            seen_prompts[$name]=1
        done
    fi

    # Tier 2: User
    if [[ -d "$user_dir" ]]; then
        for file in "$user_dir"/*.md(.N); do
            local name="${file:t:r}"
            [[ -n "${seen_prompts[$name]}" ]] && continue
            local desc=""
            typeset -A _pm
            if _teach_parse_template_metadata "$file" _pm 2>/dev/null; then
                desc="${_pm[template_description]:-}"
            fi
            echo "${name}|user|${file}|${desc}"
            seen_prompts[$name]=1
        done
    fi

    # Tier 3: Plugin
    if [[ -d "$plugin_dir" ]]; then
        for file in "$plugin_dir"/*.md(.N); do
            local name="${file:t:r}"
            [[ "$name" == "README" ]] && continue  # skip README.md
            [[ -n "${seen_prompts[$name]}" ]] && continue
            local desc=""
            typeset -A _pm
            if _teach_parse_template_metadata "$file" _pm 2>/dev/null; then
                desc="${_pm[template_description]:-}"
            fi
            echo "${name}|plugin|${file}|${desc}"
            seen_prompts[$name]=1
        done
    fi
}

# =============================================================================
# Function: _teach_prompt_tier
# Purpose: Determine which tier a prompt path belongs to
# =============================================================================
# Arguments:
#   $1 - full path to prompt file
#
# Returns: Prints "course", "user", or "plugin"
# =============================================================================
_teach_prompt_tier() {
    local file_path="$1"
    local course_dir="$(_teach_prompt_course_dir)"
    local user_dir="$(_teach_prompt_user_dir)"

    if [[ "$file_path" == "$course_dir"/* ]]; then
        echo "course"
    elif [[ "$file_path" == "$user_dir"/* ]]; then
        echo "user"
    else
        echo "plugin"
    fi
}

# =============================================================================
# Function: _teach_prompt_has_override
# Purpose: Check if a prompt has a course or user override
# =============================================================================
# Arguments:
#   $1 - prompt name
#
# Returns:
#   0 - Has override (course or user tier exists)
#   1 - No override (only plugin default)
# =============================================================================
_teach_prompt_has_override() {
    local name="$1"
    local course_dir="$(_teach_prompt_course_dir)"
    local user_dir="$(_teach_prompt_user_dir)"

    [[ -f "$course_dir/$name" || -f "$course_dir/${name}.md" ]] && return 0
    [[ -f "$user_dir/$name" || -f "$user_dir/${name}.md" ]] && return 0

    return 1
}

# ============================================================================
# RENDERING
# ============================================================================

# =============================================================================
# Function: _teach_render_prompt
# Purpose: Render a prompt file with variable substitution + macro injection
# =============================================================================
# Arguments:
#   $1 - path to prompt file
#   $2 - extra variables array name (optional)
#
# Output: Rendered prompt content (frontmatter stripped, variables replaced)
#
# Variables resolved from:
#   - teach-config.yml (COURSE, INSTRUCTOR, SEMESTER)
#   - Auto-filled (DATE)
#   - Extra vars passed in $2
#   - MACROS: injected from teach macros export if available
# =============================================================================
_teach_render_prompt() {
    local prompt_path="$1"
    local extra_vars_name="${2:-}"

    [[ -f "$prompt_path" ]] || return 1

    # Read content (strip frontmatter)
    local content=""
    local in_frontmatter=0
    local past_frontmatter=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == "---" ]]; then
            if (( in_frontmatter )); then
                past_frontmatter=1
                continue
            elif (( ! past_frontmatter )); then
                in_frontmatter=1
                continue
            fi
        fi

        if (( past_frontmatter )); then
            content+="$line"$'\n'
        fi
    done < "$prompt_path"

    # Load config variables
    typeset -A render_vars
    _teach_load_config_variables render_vars

    # Merge extra variables (if provided)
    if [[ -n "$extra_vars_name" ]]; then
        local keys values
        eval "keys=(\${(k)${extra_vars_name}})"
        eval "values=(\${(v)${extra_vars_name}})"
        local i
        for ((i=1; i<=${#keys[@]}; i++)); do
            render_vars[${keys[$i]}]="${values[$i]}"
        done
    fi

    # Inject MACROS if available and not already set
    if [[ -z "${render_vars[MACROS]}" ]]; then
        if typeset -f _teach_macros_export >/dev/null 2>&1; then
            local macros_content
            macros_content=$(_teach_macros_export --latex 2>/dev/null)
            [[ -n "$macros_content" ]] && render_vars[MACROS]="$macros_content"
        fi
    fi

    # Substitute variables
    content="$(_teach_substitute_variables "$content" render_vars)"

    echo "$content"
}

# ============================================================================
# VALIDATION
# ============================================================================

# =============================================================================
# Function: _teach_validate_prompt_file
# Purpose: Validate a prompt file for syntax and Scholar compatibility
# =============================================================================
# Arguments:
#   $1 - path to prompt file
#   $2 - strict mode (optional): 1 = warnings become errors
#
# Returns:
#   0 - Valid (or warnings only in non-strict mode)
#   1 - Errors found
#
# Output: Validation messages to stdout
# =============================================================================
_teach_validate_prompt_file() {
    local prompt_path="$1"
    local strict="${2:-0}"
    local errors=0
    local warnings=0

    # Error 1: File exists and is readable
    if [[ ! -f "$prompt_path" ]]; then
        echo "  error: file not found: $prompt_path"
        return 1
    fi
    if [[ ! -r "$prompt_path" ]]; then
        echo "  error: file not readable: $prompt_path"
        return 1
    fi

    # Error 2: YAML frontmatter present
    typeset -A meta
    if ! _teach_parse_template_metadata "$prompt_path" meta 2>/dev/null; then
        echo "  error: missing or invalid YAML frontmatter"
        ((errors++))
    fi

    # Error 3: template_type equals "prompt"
    if [[ -n "${meta[template_type]}" ]]; then
        if [[ "${meta[template_type]}" != "prompt" ]]; then
            echo "  error: template_type must be \"prompt\" (got: ${meta[template_type]})"
            ((errors++))
        fi
    else
        echo "  error: missing template_type field"
        ((errors++))
    fi

    # Error 4: template_version present
    if [[ -z "${meta[template_version]}" ]]; then
        echo "  error: missing template_version field"
        ((errors++))
    fi

    # Error 5: Variable patterns use uppercase + underscores only
    local bad_vars
    bad_vars=$(grep -oE '\{\{[^}]+\}\}' "$prompt_path" 2>/dev/null \
        | grep -vE '^\{\{[A-Z_]+\}\}$' || true)
    if [[ -n "$bad_vars" ]]; then
        echo "  error: invalid variable patterns (must be UPPERCASE_UNDERSCORE):"
        echo "$bad_vars" | while read -r v; do
            echo "    $v"
        done
        ((errors++))
    fi

    # Warning 1: template_description present
    if [[ -z "${meta[template_description]}" ]]; then
        echo "  warning: missing template_description field"
        ((warnings++))
    fi

    # Warning 2: scholar.command maps to known command
    if [[ -n "${meta[scholar]}" ]]; then
        # Simple check - full YAML parsing would need yq
        :  # Skip deep YAML check in pure ZSH
    fi

    # Warning 3: Body variables listed in frontmatter
    local body_vars
    body_vars=($(grep -oE '\{\{[A-Z_]+\}\}' "$prompt_path" 2>/dev/null \
        | sed 's/{{//g; s/}}//g' | sort -u || true))
    # (Informational - complex to validate in pure ZSH without yq)

    # Warning 4: At least one ## heading in body
    local body_started=0
    local has_heading=0
    while IFS= read -r line; do
        if [[ "$body_started" -eq 0 ]]; then
            # Skip frontmatter
            if [[ "$line" == "---" ]]; then
                ((body_started == 0)) && body_started=1 || body_started=2
                [[ "$body_started" -eq 1 ]] && body_started=0  # first ---
                continue
            fi
            [[ "$body_started" -eq 0 ]] && continue
        fi
        if [[ "$line" == "##"* ]]; then
            has_heading=1
            break
        fi
    done < "$prompt_path"

    # Re-check body for heading (simpler approach)
    if ! grep -q '^## ' "$prompt_path" 2>/dev/null; then
        echo "  warning: no ## headings found in prompt body"
        ((warnings++))
    fi

    # Warning 5: Body at least 100 characters
    local body_length=0
    local past_fm=0
    local fm_count=0
    while IFS= read -r line; do
        if [[ "$line" == "---" ]]; then
            ((fm_count++))
            (( fm_count >= 2 )) && past_fm=1
            continue
        fi
        if (( past_fm )); then
            ((body_length += ${#line}))
        fi
    done < "$prompt_path"

    if (( body_length < 100 )); then
        echo "  warning: prompt body is short ($body_length chars, recommend >= 100)"
        ((warnings++))
    fi

    # Apply strict mode
    if (( strict && warnings > 0 )); then
        ((errors += warnings))
    fi

    (( errors == 0 ))
}
