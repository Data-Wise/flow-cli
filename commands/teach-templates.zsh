# teach-templates.zsh - Template Management Commands
# teach templates list|new|validate|sync
#
# v5.20.0 - Template Support (#301)

# Guard against double-loading
[[ -n "$_FLOW_TEACH_TEMPLATES_LOADED" ]] && return 0
typeset -g _FLOW_TEACH_TEMPLATES_LOADED=1

# Source template helpers
local helpers_path="${0:A:h:h}/lib/template-helpers.zsh"
[[ -f "$helpers_path" ]] && source "$helpers_path"

# ============================================================================
# MAIN DISPATCHER
# ============================================================================

# teach templates [action] [options]
_teach_templates() {
    local action="${1:-list}"
    shift 2>/dev/null || true

    case "$action" in
        list|ls|l)
            _teach_templates_list "$@"
            ;;
        new|n|create)
            _teach_templates_new "$@"
            ;;
        validate|val|v)
            _teach_templates_validate "$@"
            ;;
        sync|s|update)
            _teach_templates_sync "$@"
            ;;
        help|--help|-h)
            _teach_templates_help
            ;;
        *)
            # If action looks like a template name, treat as 'new'
            if [[ -n "$action" && "$action" != -* ]]; then
                _teach_templates_new "$action" "$@"
            else
                _teach_templates_help
            fi
            ;;
    esac
}

# ============================================================================
# LIST COMMAND
# ============================================================================

_teach_templates_list() {
    local filter_type=""
    local filter_source="all"
    local output_json=0

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --type|-t) filter_type="$2"; shift 2 ;;
            --source|-s) filter_source="$2"; shift 2 ;;
            --json|-j) output_json=1; shift ;;
            --help|-h) _teach_templates_help; return 0 ;;
            *) shift ;;
        esac
    done

    # Validate source filter
    if [[ -n "$filter_source" && ! "$filter_source" =~ ^(all|project|plugin)$ ]]; then
        _flow_log_error "Invalid source: $filter_source (use: all, project, plugin)"
        return 1
    fi

    # Get all templates
    local templates
    templates=$(_teach_get_template_sources --type "$filter_type" --source "$filter_source")

    if [[ -z "$templates" ]]; then
        if [[ $output_json -eq 1 ]]; then
            echo "[]"
        else
            echo ""
            _flow_log_warn "No templates found"
            echo ""
            echo "To initialize templates:"
            echo "  teach init --with-templates"
            echo ""
            echo "Or sync from plugin defaults:"
            echo "  teach templates sync"
        fi
        return 0
    fi

    # JSON output
    if [[ $output_json -eq 1 ]]; then
        _teach_templates_list_json "$templates"
        return 0
    fi

    # Pretty output
    _teach_templates_list_pretty "$templates"
}

_teach_templates_list_pretty() {
    local templates="$1"
    local current_type=""
    local type_upper=""
    local header_path=""
    local version=""
    local desc=""
    local source_badge=""
    typeset -A metadata

    echo ""
    printf "\033[1;36m%s\033[0m\n" "+---------------------------------------------------------+"
    printf "\033[1;36m%s\033[0m\n" "|  Teaching Templates                                    |"
    printf "\033[1;36m%s\033[0m\n" "+---------------------------------------------------------+"
    echo ""

    while IFS='|' read -r source type name path; do
        [[ -z "$source" ]] && continue

        # Print type header when type changes
        if [[ "$type" != "$current_type" ]]; then
            [[ -n "$current_type" ]] && echo ""
            current_type="$type"

            type_upper="${(U)type}"
            if [[ "$source" == "project" ]]; then
                header_path=".flow/templates/$type/"
            else
                header_path="lib/templates/teaching/"
            fi

            printf "  \033[1;33m%s\033[0m (%s)\n" "$type_upper" "$header_path"
        fi

        # Get metadata (suppress all output)
        metadata=()
        _teach_parse_template_metadata "$path" metadata >/dev/null 2>&1

        version="${metadata[template_version]:-?}"
        desc="${metadata[template_description]:-}"

        # Truncate description
        if [[ ${#desc} -gt 40 ]]; then
            desc="${desc:0:37}..."
        fi

        # Source indicator
        if [[ "$source" == "project" ]]; then
            source_badge="\033[32m[P]\033[0m"
        else
            source_badge="\033[90m[D]\033[0m"
        fi

        printf "    %-20s v%-4s %-40s %b\n" "$name" "$version" "$desc" "$source_badge"

    done <<< "$templates"

    echo ""
    printf "  \033[90mLegend: [P] = Project, [D] = Default (plugin)\033[0m\n"
    echo ""
}

_teach_templates_list_json() {
    local templates="$1"

    echo "["
    local first=1

    while IFS='|' read -r source type name path; do
        [[ -z "$source" ]] && continue

        typeset -A metadata
        _teach_parse_template_metadata "$path" metadata 2>/dev/null

        [[ $first -eq 0 ]] && echo ","
        first=0

        cat <<EOF
  {
    "source": "$source",
    "type": "$type",
    "name": "$name",
    "path": "$path",
    "version": "${metadata[template_version]:-}",
    "description": "${metadata[template_description]:-}"
  }
EOF
    done <<< "$templates"

    echo ""
    echo "]"
}

# ============================================================================
# NEW COMMAND
# ============================================================================

_teach_templates_new() {
    local template_type=""
    local destination=""
    local week=""
    local topic=""
    local dry_run=0
    local force=0

    # First positional is template type, second is destination hint
    if [[ $# -gt 0 && "$1" != -* ]]; then
        template_type="$1"
        shift
    fi

    if [[ $# -gt 0 && "$1" != -* ]]; then
        destination="$1"
        shift
    fi

    # Parse remaining arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --week|-w) week="$2"; shift 2 ;;
            --topic|-t) topic="$2"; shift 2 ;;
            --dry-run|-n) dry_run=1; shift ;;
            --force|-f) force=1; shift ;;
            --help|-h) _teach_templates_help; return 0 ;;
            *) shift ;;
        esac
    done

    # Validate template type
    if [[ -z "$template_type" ]]; then
        _flow_log_error "Template type required"
        echo ""
        echo "Usage: teach templates new <type> [destination] [options]"
        echo ""
        echo "Types: lecture, lab, slides, assignment"
        return 1
    fi

    # Find template
    local template_path
    template_path=$(_teach_resolve_template "$template_type" "content")

    if [[ -z "$template_path" || ! -f "$template_path" ]]; then
        _flow_log_error "Template not found: $template_type"
        echo ""
        echo "Available templates:"
        _teach_get_template_sources --type "content" | while IFS='|' read -r s t n p; do
            echo "  - ${n%.qmd}"
        done
        return 1
    fi

    # Load config variables
    typeset -A vars
    _teach_load_config_variables vars

    # Parse week from destination if not provided
    if [[ -z "$week" && "$destination" =~ week-([0-9]+) ]]; then
        week="${match[1]}"
    fi

    # Set provided values
    [[ -n "$week" ]] && vars[WEEK]="$week"
    [[ -n "$topic" ]] && vars[TOPIC]="$topic"

    echo ""
    printf "\033[1;34m  Creating %s from template...\033[0m\n" "$template_type"
    echo ""

    # Show template info
    typeset -A metadata
    _teach_parse_template_metadata "$template_path" metadata 2>/dev/null

    printf "  Template: %s (v%s)\n" "${template_path:t}" "${metadata[template_version]:-?}"
    printf "  Source:   %s\n" "$template_path"
    echo ""

    # Prompt for missing variables
    echo "  Variables:"
    local needed_vars
    needed_vars=($(_teach_extract_variables "$template_path"))

    for var_name in $needed_vars; do
        if [[ -n "${vars[$var_name]}" ]]; then
            printf "    \033[32m{{%s}}\033[0m → %s (from %s)\n" "$var_name" "${vars[$var_name]}" \
                   "$(if [[ "$var_name" == "DATE" ]]; then echo "auto"; else echo "config"; fi)"
        else
            printf "    \033[33m{{%s}}\033[0m → " "$var_name"
            local value
            read -r "value?[Enter value]: "
            vars[$var_name]="$value"
        fi
    done

    # Generate TOPIC_SLUG
    if [[ -n "${vars[TOPIC]}" ]]; then
        vars[TOPIC_SLUG]="$(_teach_slugify "${vars[TOPIC]}")"
    fi

    # Build destination path
    local dest_path
    if [[ -n "$destination" && "$destination" == */* ]]; then
        # User provided full path
        dest_path="$destination"
    else
        # Use destination pattern
        local pattern="${TEMPLATE_DESTINATIONS[$template_type]}"
        if [[ -n "$pattern" ]]; then
            dest_path="$(_teach_substitute_variables "$pattern" vars)"
        else
            dest_path="${destination:-output}.qmd"
        fi
    fi

    echo ""
    printf "  Preview:\n"
    printf "    \033[1m%s\033[0m\n" "$dest_path"
    echo ""

    # Dry run check
    if [[ $dry_run -eq 1 ]]; then
        printf "  \033[33m(dry-run mode - no file created)\033[0m\n"
        echo ""
        return 0
    fi

    # Check if file exists
    if [[ -f "$dest_path" && $force -eq 0 ]]; then
        _flow_log_error "File already exists: $dest_path"
        echo "  Use --force to overwrite"
        return 1
    fi

    # Read template content
    local content
    content=$(<"$template_path")

    # Substitute variables
    content="$(_teach_substitute_variables "$content" vars)"

    # Create parent directories
    _teach_ensure_parent_dir "$dest_path"

    # Write file
    echo "$content" > "$dest_path"

    printf "  \033[32m  Created: %s\033[0m\n" "$dest_path"
    echo ""
}

# ============================================================================
# VALIDATE COMMAND
# ============================================================================

_teach_templates_validate() {
    local target="${1:-}"
    local verbose=0

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose|-v) verbose=1; shift ;;
            --help|-h) _teach_templates_help; return 0 ;;
            -*) shift ;;
            *) target="$1"; shift ;;
        esac
    done

    local project_dir="$(_template_get_project_dir)"

    if [[ ! -d "$project_dir" ]]; then
        _flow_log_warn "No project templates directory found"
        echo "  Expected: .flow/templates/"
        echo ""
        echo "  Create with: teach init --with-templates"
        return 0
    fi

    echo ""
    printf "\033[1;36m%s\033[0m\n" "+---------------------------------------------------------+"
    printf "\033[1;36m%s\033[0m\n" "|  Template Validation                                   |"
    printf "\033[1;36m%s\033[0m\n" "+---------------------------------------------------------+"
    echo ""

    local total=0
    local valid=0
    local warnings=0
    local errors=0

    # Get templates to validate
    local templates
    if [[ -n "$target" ]]; then
        # Validate specific template
        local path="$(_teach_resolve_template "$target")"
        if [[ -n "$path" ]]; then
            templates="project|content|${target}|${path}"
        else
            _flow_log_error "Template not found: $target"
            return 1
        fi
    else
        # Validate all project templates
        templates=$(_teach_get_template_sources --source project)
    fi

    while IFS='|' read -r source type name path; do
        [[ -z "$source" ]] && continue

        ((total++))

        local template_valid=1
        local template_warnings=0

        printf "  \033[1m%s/%s\033[0m\n" "$type" "$name"

        # Check YAML frontmatter exists
        typeset -A metadata
        if _teach_parse_template_metadata "$path" metadata; then
            printf "    \033[32m  Valid YAML frontmatter\033[0m\n"
        else
            printf "    \033[31m  Missing or invalid YAML frontmatter\033[0m\n"
            template_valid=0
            ((errors++))
        fi

        # Check template_version
        if [[ -n "${metadata[template_version]}" ]]; then
            printf "    \033[32m  template_version present (%s)\033[0m\n" "${metadata[template_version]}"
        else
            printf "    \033[33m  template_version missing\033[0m\n"
            ((template_warnings++))
        fi

        # Check template_type matches directory
        if [[ -n "${metadata[template_type]}" ]]; then
            local expected_type="$type"
            [[ "$type" == "prompts" ]] && expected_type="prompt"

            if [[ "${metadata[template_type]}" == "$expected_type" || "${metadata[template_type]}" == "$type" ]]; then
                printf "    \033[32m  template_type matches directory (%s)\033[0m\n" "${metadata[template_type]}"
            else
                printf "    \033[33m  template_type mismatch (got: %s, expected: %s)\033[0m\n" \
                       "${metadata[template_type]}" "$expected_type"
                ((template_warnings++))
            fi
        fi

        # Check for undocumented variables
        local used_vars
        used_vars=($(_teach_extract_variables "$path"))

        if [[ ${#used_vars[@]} -gt 0 ]]; then
            local documented_vars="${metadata[template_variables]:-}"

            for var in $used_vars; do
                if [[ "$documented_vars" == *"$var"* ]]; then
                    [[ $verbose -eq 1 ]] && printf "    \033[32m  Variable documented: {{%s}}\033[0m\n" "$var"
                else
                    printf "    \033[33m  Undocumented variable: {{%s}}\033[0m\n" "$var"
                    ((template_warnings++))
                fi
            done
        fi

        if [[ $template_valid -eq 1 ]]; then
            ((valid++))
        fi
        ((warnings += template_warnings))

        echo ""

    done <<< "$templates"

    # Summary
    local status_color="\033[32m"
    [[ $errors -gt 0 ]] && status_color="\033[31m"
    [[ $warnings -gt 0 && $errors -eq 0 ]] && status_color="\033[33m"

    printf "  %bSummary: %d templates, %d valid, %d warnings, %d errors\033[0m\n" \
           "$status_color" "$total" "$valid" "$warnings" "$errors"
    echo ""

    [[ $errors -eq 0 ]]
}

# ============================================================================
# SYNC COMMAND
# ============================================================================

_teach_templates_sync() {
    local dry_run=0
    local force=0
    local create_backup=1
    local target=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run|-n) dry_run=1; shift ;;
            --force|-f) force=1; shift ;;
            --no-backup) create_backup=0; shift ;;
            --backup) create_backup=1; shift ;;
            --help|-h) _teach_templates_help; return 0 ;;
            -*) shift ;;
            *) target="$1"; shift ;;
        esac
    done

    local project_dir="$(_template_get_project_dir)"
    local plugin_dir="$(_template_get_plugin_dir)"

    echo ""
    if [[ $dry_run -eq 1 ]]; then
        printf "\033[1;33m  Template Sync Preview\033[0m\n"
    else
        printf "\033[1;34m  Template Sync\033[0m\n"
    fi
    echo ""

    # Create project templates directory if needed
    if [[ ! -d "$project_dir" ]]; then
        if [[ $dry_run -eq 1 ]]; then
            echo "  Would create: .flow/templates/"
        else
            _teach_create_template_dirs
            printf "  \033[32m  Created: .flow/templates/\033[0m\n"
        fi
    fi

    local would_update=()
    local would_skip=()
    local would_add=()

    # Get plugin templates
    local plugin_templates
    plugin_templates=$(_teach_get_template_sources --source plugin)

    while IFS='|' read -r source type name path; do
        [[ -z "$source" ]] && continue
        [[ -n "$target" && "$name" != "$target"* ]] && continue

        local type_dir="${TEMPLATE_TYPE_DIRS[$type]}"
        local project_path="$project_dir/$type_dir/$name"

        # Get versions
        typeset -A plugin_meta project_meta
        _teach_parse_template_metadata "$path" plugin_meta 2>/dev/null
        local plugin_version="${plugin_meta[template_version]:-1.0}"

        if [[ -f "$project_path" ]]; then
            _teach_parse_template_metadata "$project_path" project_meta 2>/dev/null
            local project_version="${project_meta[template_version]:-1.0}"

            _teach_compare_versions "$project_version" "$plugin_version"
            local cmp=$?

            if [[ $cmp -eq 0 ]]; then
                # Same version - skip
                would_skip+=("$type_dir/$name|v$project_version = v$plugin_version (same version)")
            elif [[ $cmp -eq 1 ]]; then
                # Project is newer - skip unless force
                if [[ $force -eq 1 ]]; then
                    would_update+=("$type_dir/$name|v$project_version -> v$plugin_version (forced)")
                else
                    would_skip+=("$type_dir/$name|v$project_version > v$plugin_version (project is newer)")
                fi
            else
                # Plugin is newer - update
                would_update+=("$type_dir/$name|v$project_version -> v$plugin_version (plugin has newer)")
            fi
        else
            # New template
            would_add+=("$type_dir/$name|v$plugin_version (new in plugin)")
        fi

    done <<< "$plugin_templates"

    # Display results
    if [[ ${#would_update[@]} -gt 0 || ${#would_add[@]} -gt 0 ]]; then
        if [[ $dry_run -eq 1 ]]; then
            echo "  Would update:"
        else
            echo "  Updating:"
        fi

        for item in "${would_update[@]}"; do
            local file="${item%%|*}"
            local reason="${item#*|}"
            printf "    \033[33m%s\033[0m  %s\n" "$file" "$reason"
        done

        for item in "${would_add[@]}"; do
            local file="${item%%|*}"
            local reason="${item#*|}"
            printf "    \033[32m%s\033[0m  %s\n" "$file" "$reason"
        done
    fi

    if [[ ${#would_skip[@]} -gt 0 ]]; then
        echo ""
        if [[ $dry_run -eq 1 ]]; then
            echo "  Would skip:"
        else
            echo "  Skipped:"
        fi

        for item in "${would_skip[@]}"; do
            local file="${item%%|*}"
            local reason="${item#*|}"
            printf "    \033[90m%s\033[0m  %s\n" "$file" "$reason"
        done
    fi

    echo ""

    # Dry run - stop here
    if [[ $dry_run -eq 1 ]]; then
        echo "  Run without --dry-run to apply changes."
        echo ""
        return 0
    fi

    # Apply changes
    if [[ ${#would_update[@]} -eq 0 && ${#would_add[@]} -eq 0 ]]; then
        printf "  \033[32m  All templates up to date!\033[0m\n"
        echo ""
        return 0
    fi

    # Process updates and additions
    local synced=0

    for item in "${would_update[@]}" "${would_add[@]}"; do
        local file="${item%%|*}"
        local type_dir="${file%%/*}"
        local name="${file#*/}"

        # Find source in plugin
        local source_path
        for check_type check_dir in ${(kv)TEMPLATE_TYPE_DIRS}; do
            [[ "$check_dir" != "$type_dir" ]] && continue

            local plugin_type_dir="${TEMPLATE_PLUGIN_PATHS[$check_type]:-$check_dir}"
            if [[ -f "$plugin_dir/$plugin_type_dir/$name" ]]; then
                source_path="$plugin_dir/$plugin_type_dir/$name"
                break
            fi
        done

        [[ -z "$source_path" ]] && continue

        local dest_path="$project_dir/$file"

        # Create backup if file exists
        if [[ -f "$dest_path" && $create_backup -eq 1 ]]; then
            cp "$dest_path" "${dest_path}.bak"
        fi

        # Create parent directory
        mkdir -p "${dest_path:h}"

        # Copy file
        cp "$source_path" "$dest_path"
        ((synced++))
    done

    printf "  \033[32m  Synced %d templates\033[0m\n" "$synced"
    echo ""
}

# ============================================================================
# HELP
# ============================================================================

_teach_templates_help() {
    cat <<'EOF'

+---------------------------------------------------------+
|  teach templates - Template Management                  |
+---------------------------------------------------------+

USAGE
  teach templates [action] [options]

ACTIONS
  list [--type TYPE]        List available templates
  new <type> <dest>         Create file from template
  validate [file]           Check template syntax
  sync [--dry-run]          Update from plugin defaults
  help                      Show this help

TEMPLATE TYPES
  content     .qmd starters (lecture, lab, slides, assignment)
  prompts     AI generation prompts (for Scholar)
  metadata    _metadata.yml templates
  checklists  QA checklists

OPTIONS
  --type TYPE       Filter by type (content, prompts, metadata, checklists)
  --source SOURCE   Filter by source (project, plugin, all)
  --json            Output as JSON
  --dry-run, -n     Preview without changes
  --force, -f       Overwrite existing files
  --week N          Pre-fill week variable
  --topic "Topic"   Pre-fill topic variable

EXAMPLES
  teach templates                      # List all
  teach templates list --type content  # List content only
  teach templates new lecture week-05  # Create lecture
  teach templates new lab week-03 --topic "ANOVA"
  teach templates validate             # Check all
  teach templates sync --dry-run       # Preview sync

FILES
  .flow/templates/          Project templates (priority)
  lib/templates/teaching/   Plugin defaults (fallback)

RESOLUTION ORDER
  1. Project templates (.flow/templates/)
  2. Plugin templates (lib/templates/teaching/)

VARIABLES
  {{WEEK}}       Week number (from args or prompt)
  {{TOPIC}}      Topic name (from args or prompt)
  {{COURSE}}     Course code (from teach-config.yml)
  {{DATE}}       Current date (auto-filled)
  {{INSTRUCTOR}} Instructor name (from config)
  {{SEMESTER}}   Semester name (from config)

EOF
}
