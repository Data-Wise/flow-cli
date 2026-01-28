# template-helpers.zsh - Template Management Core Library
# Support for .flow/templates/ with project > plugin resolution
#
# v5.20.0 - Template Support (#301)
#
# Template Types:
#   - content/     .qmd starters (lecture, lab, slides, assignment)
#   - prompts/     AI generation prompts (for Scholar)
#   - metadata/    _metadata.yml templates
#   - checklists/  QA checklists
#
# Resolution Order:
#   1. .flow/templates/<type>/<name>     (project - highest priority)
#   2. lib/templates/teaching/<name>     (plugin - fallback)

# Guard against double-loading
[[ -n "$_FLOW_TEMPLATE_HELPERS_LOADED" ]] && return 0
typeset -g _FLOW_TEMPLATE_HELPERS_LOADED=1

# ============================================================================
# CONSTANTS
# ============================================================================

# Template types and their directories
typeset -gA TEMPLATE_TYPE_DIRS=(
    [content]="content"
    [prompts]="prompts"
    [metadata]="metadata"
    [checklists]="checklists"
)

# Plugin template paths (relative mappings)
typeset -gA TEMPLATE_PLUGIN_PATHS=(
    [prompts]="claude-prompts"  # prompts/ maps to claude-prompts/ in plugin
)

# Destination patterns for new files
typeset -gA TEMPLATE_DESTINATIONS=(
    [lecture]="lectures/week-{{WEEK}}/lecture-{{WEEK}}-{{TOPIC_SLUG}}.qmd"
    [lab]="labs/week-{{WEEK}}/lab-{{WEEK}}-{{TOPIC_SLUG}}.qmd"
    [slides]="slides/week-{{WEEK}}/slides-{{WEEK}}-{{TOPIC_SLUG}}.qmd"
    [assignment]="assignments/{{TOPIC_SLUG}}.qmd"
)

# ============================================================================
# PATH UTILITIES
# ============================================================================

# Get project templates directory
# Returns: path to .flow/templates/ or empty if not in teaching project
_template_get_project_dir() {
    local root="${1:-$PWD}"

    # Find project root (has .flow/ or teach-config.yml)
    while [[ "$root" != "/" ]]; do
        if [[ -d "$root/.flow" ]] || [[ -f "$root/.flow/teach-config.yml" ]]; then
            echo "$root/.flow/templates"
            return 0
        fi
        root="${root:h}"
    done

    return 1
}

# Get plugin templates directory
# Returns: path to lib/templates/teaching/
_template_get_plugin_dir() {
    # Get the lib directory (one level up from where this file is sourced)
    local this_file="${(%):-%x}"
    local lib_dir="${this_file:A:h}"
    echo "$lib_dir/templates/teaching"
}

# ============================================================================
# TEMPLATE DISCOVERY
# ============================================================================

# Get all template sources (project + plugin)
# Args: [--type TYPE] [--source project|plugin|all]
# Output: Lines of "source|type|name|path"
_teach_get_template_sources() {
    local filter_type=""
    local filter_source="all"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --type) filter_type="$2"; shift 2 ;;
            --source) filter_source="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    local project_dir="$(_template_get_project_dir)"
    local plugin_dir="$(_template_get_plugin_dir)"

    # Track seen templates for deduplication (project overrides plugin)
    typeset -A seen_templates

    # Project templates (highest priority)
    if [[ "$filter_source" == "all" || "$filter_source" == "project" ]]; then
        if [[ -d "$project_dir" ]]; then
            for type_name type_dir in ${(kv)TEMPLATE_TYPE_DIRS}; do
                [[ -n "$filter_type" && "$filter_type" != "$type_name" ]] && continue

                local type_path="$project_dir/$type_dir"
                [[ -d "$type_path" ]] || continue

                for template in "$type_path"/*(.N); do
                    local name="${template:t}"
                    echo "project|$type_name|$name|$template"
                    seen_templates["$type_name:$name"]=1
                done
            done
        fi
    fi

    # Plugin templates (fallback)
    if [[ "$filter_source" == "all" || "$filter_source" == "plugin" ]]; then
        if [[ -d "$plugin_dir" ]]; then
            # Handle prompts -> claude-prompts mapping
            for type_name type_dir in ${(kv)TEMPLATE_TYPE_DIRS}; do
                [[ -n "$filter_type" && "$filter_type" != "$type_name" ]] && continue

                # Get actual plugin path (may differ from project path)
                local actual_dir="${TEMPLATE_PLUGIN_PATHS[$type_name]:-$type_dir}"
                local type_path="$plugin_dir/$actual_dir"
                [[ -d "$type_path" ]] || continue

                for template in "$type_path"/*(.N); do
                    local name="${template:t}"

                    # Skip if already seen from project (project overrides)
                    [[ -n "${seen_templates[$type_name:$name]}" ]] && continue

                    echo "plugin|$type_name|$name|$template"
                done
            done

            # Also check for .template files in root (legacy)
            for template in "$plugin_dir"/*.template(.N); do
                local name="${template:t}"
                local type_name="content"  # Assume content type for legacy

                [[ -n "$filter_type" && "$filter_type" != "$type_name" ]] && continue
                [[ -n "${seen_templates[$type_name:$name]}" ]] && continue

                echo "plugin|$type_name|$name|$template"
            done
        fi
    fi
}

# ============================================================================
# METADATA PARSING
# ============================================================================

# Parse YAML frontmatter from template
# Args: template_path array_name
# Output: Populates named associative array
_teach_parse_template_metadata() {
    local template_path="$1"
    local array_name="${2:-TEMPLATE_METADATA}"

    [[ -f "$template_path" ]] || return 1

    # Extract YAML frontmatter (between first --- and second ---)
    local in_frontmatter=0
    local frontmatter=""

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == "---" ]]; then
            if ((in_frontmatter)); then
                break  # End of frontmatter
            else
                in_frontmatter=1
                continue
            fi
        fi

        if ((in_frontmatter)); then
            frontmatter+="$line"$'\n'
        fi
    done < "$template_path"

    [[ -z "$frontmatter" ]] && return 1

    # Parse key-value pairs (simple YAML parsing)
    local key value
    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" == \#* ]] && continue

        # Match key: value or key: "value"
        if [[ "$line" =~ ^([a-z_]+):\ *(.*)$ ]]; then
            key="${match[1]}"
            value="${match[2]}"

            # Strip quotes
            value="${value#\"}"
            value="${value%\"}"
            value="${value#\'}"
            value="${value%\'}"

            # Set in named array using eval
            eval "${array_name}[\$key]=\"\$value\""
        fi
    done <<< "$frontmatter"

    return 0
}

# Get single metadata field from template
# Args: template_path field_name
_teach_get_template_field() {
    local template_path="$1"
    local field="$2"

    typeset -A metadata
    _teach_parse_template_metadata "$template_path" metadata || return 1

    echo "${metadata[$field]}"
}

# ============================================================================
# TEMPLATE RESOLUTION
# ============================================================================

# Find template by name (project > plugin resolution)
# Args: template_name [type]
# Output: Full path to template
_teach_resolve_template() {
    local name="$1"
    local type="${2:-}"

    local project_dir="$(_template_get_project_dir)"
    local plugin_dir="$(_template_get_plugin_dir)"

    # If type specified, look in that directory
    if [[ -n "$type" ]]; then
        local type_dir="${TEMPLATE_TYPE_DIRS[$type]}"

        # Project first
        if [[ -f "$project_dir/$type_dir/$name" ]]; then
            echo "$project_dir/$type_dir/$name"
            return 0
        fi
        if [[ -f "$project_dir/$type_dir/$name.qmd" ]]; then
            echo "$project_dir/$type_dir/$name.qmd"
            return 0
        fi
        if [[ -f "$project_dir/$type_dir/$name.md" ]]; then
            echo "$project_dir/$type_dir/$name.md"
            return 0
        fi

        # Plugin fallback
        local plugin_type_dir="${TEMPLATE_PLUGIN_PATHS[$type]:-$type_dir}"
        if [[ -f "$plugin_dir/$plugin_type_dir/$name" ]]; then
            echo "$plugin_dir/$plugin_type_dir/$name"
            return 0
        fi
        if [[ -f "$plugin_dir/$plugin_type_dir/$name.qmd" ]]; then
            echo "$plugin_dir/$plugin_type_dir/$name.qmd"
            return 0
        fi
        if [[ -f "$plugin_dir/$plugin_type_dir/$name.md" ]]; then
            echo "$plugin_dir/$plugin_type_dir/$name.md"
            return 0
        fi
    fi

    # Search all types if not found
    for type_name type_dir in ${(kv)TEMPLATE_TYPE_DIRS}; do
        # Project
        if [[ -f "$project_dir/$type_dir/$name" ]]; then
            echo "$project_dir/$type_dir/$name"
            return 0
        fi
        if [[ -f "$project_dir/$type_dir/$name.qmd" ]]; then
            echo "$project_dir/$type_dir/$name.qmd"
            return 0
        fi

        # Plugin
        local plugin_type_dir="${TEMPLATE_PLUGIN_PATHS[$type_name]:-$type_dir}"
        if [[ -f "$plugin_dir/$plugin_type_dir/$name" ]]; then
            echo "$plugin_dir/$plugin_type_dir/$name"
            return 0
        fi
        if [[ -f "$plugin_dir/$plugin_type_dir/$name.qmd" ]]; then
            echo "$plugin_dir/$plugin_type_dir/$name.qmd"
            return 0
        fi
    done

    # Check legacy .template files
    if [[ -f "$plugin_dir/$name.template" ]]; then
        echo "$plugin_dir/$name.template"
        return 0
    fi

    return 1
}

# ============================================================================
# VARIABLE SUBSTITUTION
# ============================================================================

# Extract variables from template content
# Args: template_path
# Output: List of variable names (one per line)
_teach_extract_variables() {
    local template_path="$1"

    [[ -f "$template_path" ]] || return 1

    # Find all {{VARIABLE}} patterns
    grep -oE '\{\{[A-Z_]+\}\}' "$template_path" 2>/dev/null \
        | sed 's/{{//g; s/}}//g' \
        | sort -u
}

# Get variable values from config and environment
# Args: array_name (reads from teach-config.yml)
# Output: Populates named associative array
_teach_load_config_variables() {
    local array_name="${1:-TEMPLATE_VARS}"

    # Auto-fill DATE
    eval "${array_name}[DATE]=\"\$(date +%Y-%m-%d)\""

    # Load from teach-config.yml if available
    local config_file
    for try in ".flow/teach-config.yml" "teach-config.yml" ".teach/config.yml"; do
        if [[ -f "$try" ]]; then
            config_file="$try"
            break
        fi
    done

    if [[ -f "$config_file" ]]; then
        # Extract course code
        local course_code
        course_code=$(grep -E '^  code:' "$config_file" 2>/dev/null | head -1 | sed 's/.*code:[ ]*//' | tr -d '"'"'")
        [[ -n "$course_code" ]] && eval "${array_name}[COURSE]=\"\$course_code\""

        # Extract instructor
        local instructor
        instructor=$(grep -E '^  instructor:' "$config_file" 2>/dev/null | head -1 | sed 's/.*instructor:[ ]*//' | tr -d '"'"'")
        [[ -n "$instructor" ]] && eval "${array_name}[INSTRUCTOR]=\"\$instructor\""

        # Extract semester
        local semester
        semester=$(grep -E '^  name:' "$config_file" 2>/dev/null | head -1 | sed 's/.*name:[ ]*//' | tr -d '"'"'")
        [[ -n "$semester" ]] && eval "${array_name}[SEMESTER]=\"\$semester\""
    fi
}

# Substitute variables in template content
# Args: content array_name
# Output: Content with {{VAR}} replaced
_teach_substitute_variables() {
    local content="$1"
    local array_name="${2:-TEMPLATE_VARS}"

    # Get keys and values from named array
    local keys values
    eval "keys=(\${(k)${array_name}})"
    eval "values=(\${(v)${array_name}})"

    # Replace each variable
    local i
    for ((i=1; i<=${#keys[@]}; i++)); do
        local var_name="${keys[$i]}"
        local var_value="${values[$i]}"
        content="${content//\{\{$var_name\}\}/$var_value}"
    done

    echo "$content"
}

# Interactive prompt for missing variables
# Args: variable_name [description]
# Output: User-provided value
_teach_prompt_for_variable() {
    local var_name="$1"
    local description="${2:-Enter value for $var_name}"

    local value
    printf "  \033[33m{{%s}}\033[0m → " "$var_name" >&2
    read -r "value?$description: "

    echo "$value"
}

# Prompt for all missing variables
# Args: template_path array_name
# Modifies: named array with user input
_teach_prompt_for_missing_variables() {
    local template_path="$1"
    local array_name="${2:-TEMPLATE_VARS}"

    local needed_vars
    needed_vars=($(_teach_extract_variables "$template_path"))

    for var_name in $needed_vars; do
        # Skip if already have value
        local existing_value
        eval "existing_value=\"\${${array_name}[\$var_name]}\""
        [[ -n "$existing_value" ]] && continue

        # Interactive prompt
        local value
        value=$(_teach_prompt_for_variable "$var_name")
        eval "${array_name}[\$var_name]=\"\$value\""
    done
}

# ============================================================================
# SLUG GENERATION
# ============================================================================

# Convert topic to URL-friendly slug
# Args: topic_name
# Output: lowercase-hyphenated-slug
_teach_slugify() {
    local input="$1"

    echo "$input" \
        | tr '[:upper:]' '[:lower:]' \
        | tr -cs '[:alnum:]' '-' \
        | sed 's/^-//; s/-$//'
}

# ============================================================================
# VERSION COMPARISON
# ============================================================================

# Compare template versions
# Args: version1 version2
# Returns: 0 if equal, 1 if v1 > v2, 2 if v1 < v2
_teach_compare_versions() {
    local v1="$1"
    local v2="$2"

    # Normalize (remove 'v' prefix if present)
    v1="${v1#v}"
    v2="${v2#v}"

    if [[ "$v1" == "$v2" ]]; then
        return 0
    fi

    # Split by dots and compare numerically (ZSH arrays are 1-indexed)
    local -a parts1 parts2
    parts1=(${(s:.:)v1})
    parts2=(${(s:.:)v2})

    local max_len=${#parts1[@]}
    (( ${#parts2[@]} > max_len )) && max_len=${#parts2[@]}

    local i
    for ((i = 1; i <= max_len; i++)); do
        local p1="${parts1[$i]:-0}"
        local p2="${parts2[$i]:-0}"

        if (( p1 > p2 )); then
            return 1  # v1 > v2
        elif (( p1 < p2 )); then
            return 2  # v1 < v2
        fi
    done

    return 0  # equal
}

# ============================================================================
# DIRECTORY CREATION
# ============================================================================

# Ensure directory exists for file path
# Args: file_path
_teach_ensure_parent_dir() {
    local file_path="$1"
    local parent_dir="${file_path:h}"

    if [[ ! -d "$parent_dir" ]]; then
        mkdir -p "$parent_dir"
    fi
}

# Create project templates directory structure
# Args: [project_root]
_teach_create_template_dirs() {
    local root="${1:-$PWD}"
    local template_dir="$root/.flow/templates"

    for type_name type_dir in ${(kv)TEMPLATE_TYPE_DIRS}; do
        mkdir -p "$template_dir/$type_dir"
    done

    echo "$template_dir"
}
