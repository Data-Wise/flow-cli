# teach-prompt.zsh - Teaching Prompt Management Commands
# teach prompt list|show|edit|validate|export
#
# v5.23.0 - teach prompt command
#
# Manages AI teaching prompts with 3-tier resolution:
#   1. Course:  .flow/templates/prompts/<name>.md
#   2. User:    ~/.flow/prompts/<name>.md
#   3. Plugin:  lib/templates/teaching/claude-prompts/<name>.md

# Guard against double-loading
[[ -n "$_FLOW_TEACH_PROMPT_LOADED" ]] && return 0
typeset -g _FLOW_TEACH_PROMPT_LOADED=1

# Source prompt helpers
local _tp_helpers_path="${0:A:h:h}/lib/prompt-helpers.zsh"
[[ -f "$_tp_helpers_path" ]] && source "$_tp_helpers_path"

# ============================================================================
# MAIN DISPATCHER
# ============================================================================

# teach prompt [action] [options]
_teach_prompt() {
    local action="${1:-list}"
    shift 2>/dev/null || true

    case "$action" in
        list|ls|l)
            _teach_prompt_list "$@"
            ;;
        show|cat|s)
            _teach_prompt_show "$@"
            ;;
        edit|ed)
            _teach_prompt_edit "$@"
            ;;
        validate|val|v)
            _teach_prompt_validate "$@"
            ;;
        export|x)
            _teach_prompt_export "$@"
            ;;
        help|--help|-h)
            _teach_prompt_help
            ;;
        *)
            # If action looks like a prompt name, treat as 'show'
            if [[ -n "$action" && "$action" != -* ]]; then
                _teach_prompt_show "$action" "$@"
            else
                _teach_prompt_help
            fi
            ;;
    esac
}

# ============================================================================
# LIST COMMAND
# ============================================================================

_teach_prompt_list() {
    local filter_tier=""
    local output_json=0
    local verbose=0

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --tier|-t)     filter_tier="$2"; shift 2 ;;
            --tier=*)      filter_tier="${1#*=}"; shift ;;
            --json|-j)     output_json=1; shift ;;
            --verbose|-v)  verbose=1; shift ;;
            --help|-h)     _teach_prompt_help; return 0 ;;
            *)             shift ;;
        esac
    done

    # Validate tier filter
    if [[ -n "$filter_tier" && ! "$filter_tier" =~ ^(course|user|plugin)$ ]]; then
        _flow_log_error "Invalid tier: $filter_tier (use: course, user, plugin)"
        return 1
    fi

    # Get all prompts
    local prompts
    prompts=$(_teach_get_all_prompts)

    # Apply tier filter
    if [[ -n "$filter_tier" ]]; then
        prompts=$(echo "$prompts" | grep "|${filter_tier}|" || true)
    fi

    if [[ -z "$prompts" ]]; then
        if [[ $output_json -eq 1 ]]; then
            echo "[]"
        else
            echo ""
            _flow_log_warning "No teaching prompts found"
            echo ""
            echo "  Plugin prompts should be at:"
            echo "    lib/templates/teaching/claude-prompts/"
            echo ""
            echo "  Create course overrides at:"
            echo "    .flow/templates/prompts/"
            echo ""
        fi
        return 0
    fi

    # JSON output
    if [[ $output_json -eq 1 ]]; then
        _teach_prompt_list_json "$prompts"
        return 0
    fi

    # Pretty output
    _teach_prompt_list_pretty "$prompts" "$verbose"
}

_teach_prompt_list_pretty() {
    local prompts="$1"
    local verbose="${2:-0}"

    echo ""
    echo "${FLOW_COLORS[header]}+---------------------------------------------------------+${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}|${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}Available Teaching Prompts${FLOW_COLORS[reset]}                            ${FLOW_COLORS[header]}|${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}+---------------------------------------------------------+${FLOW_COLORS[reset]}"
    echo ""

    while IFS='|' read -r name tier path desc; do
        [[ -z "$name" ]] && continue

        # Build tier indicator
        local tier_badge=""
        local has_override=""
        case "$tier" in
            course)
                tier_badge="${FLOW_COLORS[success]}[C]${FLOW_COLORS[reset]}"
                # Check if overriding a lower tier
                if _teach_resolve_prompt "$name" "plugin" >/dev/null 2>&1 || \
                   _teach_resolve_prompt "$name" "user" >/dev/null 2>&1; then
                    has_override="*"
                fi
                ;;
            user)
                tier_badge="${FLOW_COLORS[accent]}[U]${FLOW_COLORS[reset]}"
                if _teach_resolve_prompt "$name" "plugin" >/dev/null 2>&1; then
                    has_override="*"
                fi
                ;;
            plugin)
                tier_badge="${FLOW_COLORS[muted]}[P]${FLOW_COLORS[reset]}"
                ;;
        esac

        # Truncate description
        if [[ ${#desc} -gt 45 ]]; then
            desc="${desc:0:42}..."
        fi

        printf "  %-24s %b%-1s %-45s\n" "$name" "$tier_badge" "$has_override" "$desc"

        # Verbose: show path
        if [[ "$verbose" -eq 1 ]]; then
            printf "  ${FLOW_COLORS[muted]}%-24s %s${FLOW_COLORS[reset]}\n" "" "$path"
        fi

    done <<< "$prompts"

    echo ""
    printf "  ${FLOW_COLORS[muted]}Legend: [C] Course  [U] User  [P] Plugin  * = overrides lower tier${FLOW_COLORS[reset]}\n"
    echo ""
    printf "  ${FLOW_COLORS[muted]}Usage: teach prompt show <name> to view${FLOW_COLORS[reset]}\n"
    echo ""
}

_teach_prompt_list_json() {
    local prompts="$1"
    local first=1

    echo "["

    while IFS='|' read -r name tier path desc; do
        [[ -z "$name" ]] && continue

        local has_override="false"
        _teach_prompt_has_override "$name" && has_override="true"

        [[ $first -eq 0 ]] && echo ","
        first=0

        cat <<JSONEOF
  {
    "name": "$name",
    "tier": "$tier",
    "path": "$path",
    "description": "$desc",
    "has_override": $has_override
  }
JSONEOF
    done <<< "$prompts"

    echo ""
    echo "]"
}

# ============================================================================
# SHOW COMMAND
# ============================================================================

_teach_prompt_show() {
    local name=""
    local raw=0
    local forced_tier=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --raw|-r)      raw=1; shift ;;
            --tier|-t)     forced_tier="$2"; shift 2 ;;
            --tier=*)      forced_tier="${1#*=}"; shift ;;
            --help|-h)     _teach_prompt_help; return 0 ;;
            -*)            shift ;;
            *)             [[ -z "$name" ]] && name="$1"; shift ;;
        esac
    done

    if [[ -z "$name" ]]; then
        _flow_log_error "Prompt name required"
        echo ""
        echo "  Usage: teach prompt show <name>"
        echo ""
        echo "  Available prompts:"
        _teach_get_all_prompts | while IFS='|' read -r n t p d; do
            echo "    $n"
        done
        echo ""
        return 1
    fi

    # Resolve prompt
    local prompt_path
    prompt_path=$(_teach_resolve_prompt "$name" "$forced_tier")

    if [[ -z "$prompt_path" || ! -f "$prompt_path" ]]; then
        _flow_log_error "Unknown prompt: $name"
        echo ""
        echo "  Available prompts:"
        _teach_get_all_prompts | while IFS='|' read -r n t p d; do
            echo "    $n"
        done
        echo ""
        echo "  Run 'teach prompt list' for details"
        return 1
    fi

    local tier
    tier=$(_teach_prompt_tier "$prompt_path")

    if [[ $raw -eq 1 ]]; then
        # Raw output (no pager, no header)
        cat "$prompt_path"
    else
        # Display with header, use pager
        {
            echo "# Prompt: $name [$tier]"
            echo "# Path: $prompt_path"
            echo "# ─────────────────────────────────────────"
            echo ""
            cat "$prompt_path"
        } | ${PAGER:-less}
    fi
}

# ============================================================================
# EDIT COMMAND
# ============================================================================

_teach_prompt_edit() {
    local name=""
    local global=0

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --global|-g)   global=1; shift ;;
            --help|-h)     _teach_prompt_help; return 0 ;;
            -*)            shift ;;
            *)             [[ -z "$name" ]] && name="$1"; shift ;;
        esac
    done

    if [[ -z "$name" ]]; then
        _flow_log_error "Prompt name required"
        echo "  Usage: teach prompt edit <name>"
        return 1
    fi

    # Determine target directory
    local target_dir
    if [[ $global -eq 1 ]]; then
        target_dir="$(_teach_prompt_user_dir)"
    else
        target_dir="$(_teach_prompt_course_dir)"
        if [[ -z "$target_dir" ]]; then
            _flow_log_error "Not in a teaching project (no .flow/ directory)"
            echo "  Use --global to edit user-level prompts"
            return 1
        fi
    fi

    local target_path="$target_dir/${name}.md"

    # If file doesn't exist yet, copy from resolved source
    if [[ ! -f "$target_path" ]]; then
        local source_path
        source_path=$(_teach_resolve_prompt "$name")

        if [[ -n "$source_path" && -f "$source_path" ]]; then
            # Create directory if needed
            mkdir -p "$target_dir"
            cp "$source_path" "$target_path"

            local source_tier
            source_tier=$(_teach_prompt_tier "$source_path")
            local target_tier="course"
            [[ $global -eq 1 ]] && target_tier="user"

            echo ""
            _flow_log_success "Created $target_tier override from $source_tier default"
            echo "  Source: $source_path"
            echo "  Target: $target_path"
            echo ""
        else
            # Create new empty prompt from skeleton
            mkdir -p "$target_dir"
            cat > "$target_path" <<'SKELETON'
---
template_version: "1.0"
template_type: "prompt"
template_description: ""
scholar:
  command: ""
  model: "claude-opus-4-5"
  temperature: 0.3
variables:
  required: [COURSE, TOPIC]
  optional: [WEEK, STYLE, MACROS, INSTRUCTOR, SEMESTER, DATE]
---

# Prompt Title

## Purpose

Describe the prompt's purpose here.

## Requirements

- Requirement 1
- Requirement 2

## Structure

### Section 1
...
SKELETON
            echo ""
            _flow_log_success "Created new prompt skeleton"
            echo "  Path: $target_path"
            echo ""
        fi
    fi

    # Open in editor
    ${EDITOR:-vi} "$target_path"
}

# ============================================================================
# VALIDATE COMMAND
# ============================================================================

_teach_prompt_validate() {
    local target=""
    local all=0
    local strict=0

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all|-a)      all=1; shift ;;
            --strict|-s)   strict=1; shift ;;
            --help|-h)     _teach_prompt_help; return 0 ;;
            -*)            shift ;;
            *)             target="$1"; shift ;;
        esac
    done

    echo ""
    echo "${FLOW_COLORS[header]}+---------------------------------------------------------+${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}|${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}Validating Teaching Prompts${FLOW_COLORS[reset]}                          ${FLOW_COLORS[header]}|${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}+---------------------------------------------------------+${FLOW_COLORS[reset]}"
    echo ""

    local total=0
    local valid=0
    local warn_count=0
    local error_count=0

    # Determine what to validate
    local prompts_to_check=""
    if [[ -n "$target" ]]; then
        local path
        path=$(_teach_resolve_prompt "$target")
        if [[ -z "$path" ]]; then
            _flow_log_error "Prompt not found: $target"
            return 1
        fi
        prompts_to_check="${target}|$(_teach_prompt_tier "$path")|${path}|"
    else
        prompts_to_check=$(_teach_get_all_prompts)
    fi

    while IFS='|' read -r name tier path desc; do
        [[ -z "$name" ]] && continue
        ((total++))

        local tier_label=""
        case "$tier" in
            course) tier_label="course override" ;;
            user)   tier_label="user default" ;;
            plugin) tier_label="plugin default" ;;
        esac

        # Capture validation output
        local val_output
        val_output=$(_teach_validate_prompt_file "$path" "$strict" 2>&1)
        local val_result=$?

        if [[ $val_result -eq 0 ]]; then
            printf "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} %-24s Valid (%s)\n" "$name" "$tier_label"
            ((valid++))
        else
            # Count errors vs warnings in output
            local file_errors file_warnings
            file_errors=$(echo "$val_output" | grep -c "^  error:" || true)
            file_warnings=$(echo "$val_output" | grep -c "^  warning:" || true)

            if [[ $file_errors -gt 0 ]]; then
                printf "  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} %-24s Errors found (%s)\n" "$name" "$tier_label"
                ((error_count += file_errors))
            elif [[ $file_warnings -gt 0 ]]; then
                printf "  ${FLOW_COLORS[warning]}⚠${FLOW_COLORS[reset]} %-24s Warnings (%s)\n" "$name" "$tier_label"
                ((warn_count += file_warnings))
                ((valid++))  # warnings don't count as invalid in non-strict
            fi

            # Show details
            echo "$val_output" | while read -r line; do
                [[ -n "$line" ]] && echo "    $line"
            done
        fi

    done <<< "$prompts_to_check"

    echo ""

    # Summary
    local status_color="${FLOW_COLORS[success]}"
    [[ $error_count -gt 0 ]] && status_color="${FLOW_COLORS[error]}"
    [[ $warn_count -gt 0 && $error_count -eq 0 ]] && status_color="${FLOW_COLORS[warning]}"

    printf "  %b%d valid, %d warnings, %d errors%b\n" \
           "$status_color" "$valid" "$warn_count" "$error_count" "${FLOW_COLORS[reset]}"
    echo ""

    (( error_count == 0 ))
}

# ============================================================================
# EXPORT COMMAND
# ============================================================================

_teach_prompt_export() {
    local name=""
    local include_macros=0
    local output_json=0

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --macros|-m)   include_macros=1; shift ;;
            --json|-j)     output_json=1; shift ;;
            --help|-h)     _teach_prompt_help; return 0 ;;
            -*)            shift ;;
            *)             [[ -z "$name" ]] && name="$1"; shift ;;
        esac
    done

    if [[ -z "$name" ]]; then
        _flow_log_error "Prompt name required"
        echo "  Usage: teach prompt export <name>"
        return 1
    fi

    local prompt_path
    prompt_path=$(_teach_resolve_prompt "$name")

    if [[ -z "$prompt_path" || ! -f "$prompt_path" ]]; then
        _flow_log_error "Unknown prompt: $name"
        return 1
    fi

    # Build extra vars
    typeset -A extra_vars
    if [[ $include_macros -eq 1 ]]; then
        if typeset -f _teach_macros_export >/dev/null 2>&1; then
            extra_vars[MACROS]=$(_teach_macros_export --latex 2>/dev/null)
        fi
    fi

    if [[ $output_json -eq 1 ]]; then
        # JSON output with metadata
        local tier
        tier=$(_teach_prompt_tier "$prompt_path")
        local rendered
        rendered=$(_teach_render_prompt "$prompt_path" extra_vars)

        # Escape for JSON
        rendered="${rendered//\\/\\\\}"
        rendered="${rendered//\"/\\\"}"
        rendered="${rendered//$'\n'/\\n}"

        cat <<JSONEOF
{
  "name": "$name",
  "tier": "$tier",
  "path": "$prompt_path",
  "rendered": "$rendered"
}
JSONEOF
    else
        # Plain rendered output
        _teach_render_prompt "$prompt_path" extra_vars
    fi
}

# ============================================================================
# HELP
# ============================================================================

_teach_prompt_help() {
    cat << EOF

${FLOW_COLORS[header]}+---------------------------------------------------------+${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}|${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}teach prompt${FLOW_COLORS[reset]} - AI Teaching Prompt Management           ${FLOW_COLORS[header]}|${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}+---------------------------------------------------------+${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  teach prompt <command> [options]

${FLOW_COLORS[bold]}COMMANDS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}list${FLOW_COLORS[reset]}     List prompts with tier indicators [C]/[U]/[P]
  ${FLOW_COLORS[accent]}show${FLOW_COLORS[reset]}     Display prompt in pager
  ${FLOW_COLORS[accent]}edit${FLOW_COLORS[reset]}     Create course override and open editor
  ${FLOW_COLORS[accent]}validate${FLOW_COLORS[reset]} Check syntax and Scholar compatibility
  ${FLOW_COLORS[accent]}export${FLOW_COLORS[reset]}   Render with resolved variables

${FLOW_COLORS[bold]}ALIASES${FLOW_COLORS[reset]}
  teach pr              teach prompt
  teach prompt ls       teach prompt list
  teach prompt cat      teach prompt show
  teach prompt ed       teach prompt edit
  teach prompt val      teach prompt validate
  teach prompt x        teach prompt export

${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}list:${FLOW_COLORS[reset]}
    --tier TIER         Filter by tier (course, user, plugin)
    --json, -j          Output as JSON
    --verbose, -v       Show file paths

  ${FLOW_COLORS[accent]}show:${FLOW_COLORS[reset]}
    --raw, -r           Output without pager
    --tier TIER         Force specific tier

  ${FLOW_COLORS[accent]}edit:${FLOW_COLORS[reset]}
    --global, -g        Edit user-level (~/.flow/prompts/)

  ${FLOW_COLORS[accent]}validate:${FLOW_COLORS[reset]}
    --all, -a           Validate all prompts
    --strict, -s        Treat warnings as errors

  ${FLOW_COLORS[accent]}export:${FLOW_COLORS[reset]}
    --macros, -m        Include LaTeX macros
    --json, -j          Output as JSON with metadata

${FLOW_COLORS[bold]}QUICK EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} teach prompt list              ${FLOW_COLORS[dim]}# List all prompts${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} teach prompt show lecture-notes ${FLOW_COLORS[dim]}# View in pager${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} teach prompt edit lecture-notes ${FLOW_COLORS[dim]}# Create course override${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} teach prompt validate           ${FLOW_COLORS[dim]}# Check all prompts${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} teach prompt export lecture-notes ${FLOW_COLORS[dim]}# Rendered output${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}3-TIER RESOLUTION${FLOW_COLORS[reset]}
  Priority 1: ${FLOW_COLORS[success]}Course${FLOW_COLORS[reset]}  .flow/templates/prompts/<name>.md
  Priority 2: ${FLOW_COLORS[accent]}User${FLOW_COLORS[reset]}    ~/.flow/prompts/<name>.md
  Priority 3: ${FLOW_COLORS[muted]}Plugin${FLOW_COLORS[reset]}  lib/templates/teaching/claude-prompts/<name>.md

  First match wins. Course overrides User overrides Plugin.

${FLOW_COLORS[bold]}VARIABLES${FLOW_COLORS[reset]}
  {{COURSE}}      Course name (from teach-config.yml)
  {{TOPIC}}       Topic (from --topic flag)
  {{WEEK}}        Week number (from --week flag)
  {{STYLE}}       Content style (conceptual, rigorous, etc.)
  {{MACROS}}      LaTeX macros (from teach macros export)
  {{INSTRUCTOR}}  Instructor name (from config)
  {{SEMESTER}}    Semester name (from config)
  {{DATE}}        Current date (auto-filled)

${FLOW_COLORS[muted]}Run 'teach prompt <cmd> --help' for command details${FLOW_COLORS[reset]}

EOF
}
