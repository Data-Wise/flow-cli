# lib/teach-style-helpers.zsh - Teaching Style Configuration Helpers
# Reads teaching style from .flow/teach-config.yml or legacy .claude/teaching-style.local.md
#
# v6.3.0 - Teaching Style Consolidation (#298)
#
# Resolution order:
#   1. .flow/teach-config.yml → teaching_style section (preferred)
#   2. .claude/teaching-style.local.md → YAML frontmatter (legacy fallback)
#
# Requires: yq (already a dependency for teach commands)

# Guard against double-loading
[[ -n "$_FLOW_TEACH_STYLE_HELPERS_LOADED" ]] && return 0

# =============================================================================
# Function: _teach_find_style_source
# Purpose: Locate the active teaching style configuration source
# =============================================================================
# Arguments: none (uses current directory context)
#
# Returns:
#   0 - Source found (outputs path and type to stdout as "path:type")
#   1 - No teaching style configured
#
# Output format: "<path>:<type>"
#   type is "teach-config" or "legacy-md"
#
# Example:
#   local source=$(_teach_find_style_source)
#   local path="${source%%:*}"
#   local type="${source##*:}"
# =============================================================================
_teach_find_style_source() {
    local project_root="${1:-.}"

    # Priority 1: .flow/teach-config.yml with teaching_style section
    local config_file="$project_root/.flow/teach-config.yml"
    if [[ -f "$config_file" ]]; then
        if command -v yq &>/dev/null; then
            local has_style
            has_style=$(yq '.teaching_style // ""' "$config_file" 2>/dev/null)
            if [[ -n "$has_style" && "$has_style" != "null" && "$has_style" != "" ]]; then
                echo "$config_file:teach-config"
                return 0
            fi
        fi
    fi

    # Priority 2: Legacy .claude/teaching-style.local.md
    local legacy_file="$project_root/.claude/teaching-style.local.md"
    if [[ -f "$legacy_file" ]]; then
        echo "$legacy_file:legacy-md"
        return 0
    fi

    return 1
}

# =============================================================================
# Function: _teach_get_style
# Purpose: Read a teaching_style value by dotpath key
# =============================================================================
# Arguments:
#   $1 - (required) Dotpath key (e.g., "pedagogical_approach.primary")
#   $2 - (optional) Project root [default: .]
#
# Returns:
#   0 - Value found (outputs value to stdout)
#   1 - Key not found or no teaching style configured
#
# Example:
#   _teach_get_style "pedagogical_approach.primary"
#   # → "problem-based"
#
#   _teach_get_style "content_preferences.code_style"
#   # → "tidyverse-primary"
# =============================================================================
_teach_get_style() {
    local key="$1"
    local project_root="${2:-.}"

    [[ -z "$key" ]] && return 1

    if ! command -v yq &>/dev/null; then
        echo "error: yq required" >&2
        return 1
    fi

    local source
    source=$(_teach_find_style_source "$project_root") || return 1

    local path="${source%%:*}"
    local type="${source##*:}"

    case "$type" in
        teach-config)
            local value
            value=$(yq ".teaching_style.$key" "$path" 2>/dev/null)
            if [[ -n "$value" && "$value" != "null" ]]; then
                echo "$value"
                return 0
            fi
            ;;
        legacy-md)
            # Extract YAML frontmatter and query it
            local frontmatter
            frontmatter=$(sed -n '/^---$/,/^---$/p' "$path" 2>/dev/null | sed '1d;$d')
            if [[ -n "$frontmatter" ]]; then
                local value
                value=$(echo "$frontmatter" | yq ".teaching_style.$key" 2>/dev/null)
                if [[ -n "$value" && "$value" != "null" ]]; then
                    echo "$value"
                    return 0
                fi
            fi
            ;;
    esac

    return 1
}

# =============================================================================
# Function: _teach_get_command_override
# Purpose: Read a command override value from teaching style config
# =============================================================================
# Arguments:
#   $1 - (required) Command name (e.g., "lecture", "exam", "slides")
#   $2 - (optional) Specific key within the command override (e.g., "length")
#   $3 - (optional) Project root [default: .]
#
# Returns:
#   0 - Value found (outputs value to stdout)
#   1 - Not found or no config
#
# Example:
#   _teach_get_command_override "lecture" "length"
#   # → "20-40 pages"
#
#   _teach_get_command_override "slides" "format"
#   # → "revealjs"
#
#   _teach_get_command_override "lecture"
#   # → (full lecture override object as YAML)
# =============================================================================
_teach_get_command_override() {
    local cmd="$1"
    local key="$2"
    local project_root="${3:-.}"

    [[ -z "$cmd" ]] && return 1

    if ! command -v yq &>/dev/null; then
        echo "error: yq required" >&2
        return 1
    fi

    local source
    source=$(_teach_find_style_source "$project_root") || return 1

    local path="${source%%:*}"
    local type="${source##*:}"

    local yq_path
    if [[ -n "$key" ]]; then
        yq_path=".teaching_style.command_overrides.$cmd.$key"
    else
        yq_path=".teaching_style.command_overrides.$cmd"
    fi

    case "$type" in
        teach-config)
            local value
            value=$(yq "$yq_path" "$path" 2>/dev/null)
            if [[ -n "$value" && "$value" != "null" ]]; then
                echo "$value"
                return 0
            fi
            ;;
        legacy-md)
            local frontmatter
            frontmatter=$(sed -n '/^---$/,/^---$/p' "$path" 2>/dev/null | sed '1d;$d')
            if [[ -n "$frontmatter" ]]; then
                local value
                value=$(echo "$frontmatter" | yq "$yq_path" 2>/dev/null)
                if [[ -n "$value" && "$value" != "null" ]]; then
                    echo "$value"
                    return 0
                fi
            fi
            ;;
    esac

    return 1
}

# =============================================================================
# Function: _teach_style_is_redirect
# Purpose: Check if a teaching-style.local.md is a redirect shim
# =============================================================================
# Arguments:
#   $1 - (optional) Project root [default: .]
#
# Returns:
#   0 - Is a redirect shim (_redirect: true found)
#   1 - Not a redirect shim or file doesn't exist
# =============================================================================
_teach_style_is_redirect() {
    local project_root="${1:-.}"
    local legacy_file="$project_root/.claude/teaching-style.local.md"

    [[ ! -f "$legacy_file" ]] && return 1

    if command -v yq &>/dev/null; then
        local frontmatter
        frontmatter=$(sed -n '/^---$/,/^---$/p' "$legacy_file" 2>/dev/null | sed '1d;$d')
        if [[ -n "$frontmatter" ]]; then
            local redirect
            redirect=$(echo "$frontmatter" | yq '.teaching_style._redirect // false' 2>/dev/null)
            [[ "$redirect" == "true" ]] && return 0
        fi
    fi

    return 1
}

typeset -g _FLOW_TEACH_STYLE_HELPERS_LOADED=1
