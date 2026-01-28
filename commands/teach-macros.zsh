# commands/teach-macros.zsh - LaTeX macro management for teaching workflow
# Part of flow-cli - Pure ZSH plugin for ADHD-optimized workflow management
#
# Features:
#   - List macros in categorized table format
#   - Sync macros from source files to cache
#   - Export macros in multiple formats (JSON, MathJax, LaTeX, QMD)
#
# Performance Targets:
#   - list: < 100ms (cached)
#   - sync: < 500ms
#   - export: < 50ms

# Load guard - prevent double-sourcing
(( $+functions[_teach_macros_list] )) && return

# ============================================================================
# SOURCE DEPENDENCIES
# ============================================================================

# Source macro parser library
if [[ -z "$_FLOW_MACRO_PARSER_LOADED" ]]; then
    local parser_path="${0:A:h}/../lib/macro-parser.zsh"
    if [[ -f "$parser_path" ]]; then
        source "$parser_path"
    else
        _flow_log_error "Macro parser library not found: $parser_path"
        return 1
    fi
fi

# ============================================================================
# CONSTANTS
# ============================================================================

# Common LaTeX macro categories for visual grouping
typeset -gA MACRO_CATEGORY_PATTERNS=(
    [operators]='E|Var|Cov|Corr|MSE|Bias|argmax|argmin|plim|tr|diag|vec|rank'
    [symbols]='indep|dep|implies|iid|dist|approx|sim|propto'
    [distributions]='Normal|Binomial|Poisson|Exp|Uniform|Beta|Gamma|Chi'
    [matrices]='bm|mat|transpose|inv|det|norm'
    [derivatives]='dd|pd|grad|nabla|Hess'
    [probability]='Prob|Expect|prob|given'
)

# Category display order and icons
typeset -ga MACRO_CATEGORY_ORDER=(operators symbols distributions matrices derivatives probability other)
typeset -gA MACRO_CATEGORY_ICONS=(
    [operators]="📊"
    [symbols]="🔣"
    [distributions]="📈"
    [matrices]="🔢"
    [derivatives]="∂"
    [probability]="🎲"
    [other]="📝"
)

# ============================================================================
# CATEGORY DETECTION
# ============================================================================

# Detect category for a macro name
_macro_detect_category() {
    local name="$1"

    for category pattern in ${(kv)MACRO_CATEGORY_PATTERNS}; do
        if [[ "$name" =~ "^($pattern)$" ]]; then
            echo "$category"
            return 0
        fi
    done

    echo "other"
}

# ============================================================================
# TEACH MACROS LIST
# ============================================================================

# =============================================================================
# Function: _teach_macros_list
# Purpose: Display all macros in categorized table format
# =============================================================================
# Arguments:
#   --all       Show all details including source file and line
#   --category  Filter by category
#   --json      Output as JSON instead of table
#
# Returns:
#   0 - Success
#   1 - No macros found or error
#
# Example:
#   _teach_macros_list
#   _teach_macros_list --all
#   _teach_macros_list --category operators
# =============================================================================
_teach_macros_list() {
    local show_all=false
    local filter_category=""
    local output_json=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all|-a)      show_all=true; shift ;;
            --category=*)  filter_category="${1#*=}"; shift ;;
            --category)    shift; filter_category="$1"; shift ;;
            --json|-j)     output_json=true; shift ;;
            --help|-h)     _teach_macros_list_help; return 0 ;;
            *)             shift ;;
        esac
    done

    # Load macros from config
    if ! _flow_load_macro_config; then
        _flow_log_warning "No macro sources configured"
        echo ""
        echo "  ${FLOW_COLORS[muted]}Configure macros in .flow/teach-config.yml:${FLOW_COLORS[reset]}"
        echo ""
        echo "  scholar:"
        echo "    latex_macros:"
        echo "      enabled: true"
        echo "      sources:"
        echo "        - path: \"_macros.qmd\""
        echo "          format: \"qmd\""
        echo ""
        return 1
    fi

    local count=$(_flow_macro_count)

    if (( count == 0 )); then
        _flow_log_info "No macros found in configured sources"
        return 1
    fi

    # JSON output mode
    if [[ "$output_json" == true ]]; then
        _flow_export_macros_json
        return 0
    fi

    # Group macros by category
    typeset -A category_macros
    for cat in "${MACRO_CATEGORY_ORDER[@]}"; do
        category_macros[$cat]=""
    done

    for name in ${(ko)_FLOW_MACROS}; do
        local category=$(_macro_detect_category "$name")

        # Apply category filter if specified
        if [[ -n "$filter_category" && "$category" != "$filter_category" ]]; then
            continue
        fi

        if [[ -n "${category_macros[$category]}" ]]; then
            category_macros[$category]="${category_macros[$category]} $name"
        else
            category_macros[$category]="$name"
        fi
    done

    # Display header
    echo ""
    echo "${FLOW_COLORS[header]}╭─────────────────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}LaTeX Macros${FLOW_COLORS[reset]} ($count available)                             ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}╰─────────────────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
    echo ""

    # Display each category
    local displayed=0
    for category in "${MACRO_CATEGORY_ORDER[@]}"; do
        local macros="${category_macros[$category]}"
        [[ -z "$macros" ]] && continue

        local icon="${MACRO_CATEGORY_ICONS[$category]:-📝}"
        local cat_upper="${(U)category}"

        echo "${FLOW_COLORS[bold]}$icon ${cat_upper}${FLOW_COLORS[reset]}"
        echo ""

        # Display each macro in this category
        for name in ${=macros}; do
            local expansion="${_FLOW_MACROS[$name]}"
            local meta="${_FLOW_MACRO_META[$name]}"
            local source="${meta%%:*}"
            local args="${meta##*:}"

            # Truncate expansion for display
            local display_exp="$expansion"
            (( ${#display_exp} > 30 )) && display_exp="${display_exp:0:27}..."

            # Format with or without details
            if [[ "$show_all" == true ]]; then
                printf "  ${FLOW_COLORS[accent]}\\%-14s${FLOW_COLORS[reset]} → ${FLOW_COLORS[muted]}%-30s${FLOW_COLORS[reset]} ${FLOW_COLORS[dim]}(%s)${FLOW_COLORS[reset]}\n" \
                    "$name" "$display_exp" "$source"
            else
                printf "  ${FLOW_COLORS[accent]}\\%-14s${FLOW_COLORS[reset]} → ${FLOW_COLORS[muted]}%s${FLOW_COLORS[reset]}\n" \
                    "$name" "$display_exp"
            fi

            ((displayed++))
        done
        echo ""
    done

    # Show source info
    local first_source=""
    for name in ${(k)_FLOW_MACRO_META}; do
        first_source="${_FLOW_MACRO_META[$name]%%:*}"
        break
    done

    if [[ -n "$first_source" ]]; then
        # Get file modification time
        local source_path
        if [[ -f "$first_source" ]]; then
            source_path="$first_source"
        elif [[ -f "./$first_source" ]]; then
            source_path="./$first_source"
        fi

        if [[ -n "$source_path" && -f "$source_path" ]]; then
            local mod_time=$(stat -f "%m" "$source_path" 2>/dev/null)
            if [[ -n "$mod_time" ]]; then
                local time_ago=$(_flow_time_ago "$mod_time")
                echo "${FLOW_COLORS[muted]}Source: $first_source (synced $time_ago)${FLOW_COLORS[reset]}"
            else
                echo "${FLOW_COLORS[muted]}Source: $first_source${FLOW_COLORS[reset]}"
            fi
        else
            echo "${FLOW_COLORS[muted]}Source: $first_source${FLOW_COLORS[reset]}"
        fi
    fi
    echo ""

    return 0
}

_teach_macros_list_help() {
    cat << 'EOF'

  teach macros list - Display LaTeX macros

  USAGE
    teach macros list [options]

  OPTIONS
    -a, --all            Show source file and line info
    --category NAME      Filter by category (operators, symbols, etc.)
    -j, --json           Output as JSON
    -h, --help           Show this help

  EXAMPLES
    teach macros list              # Show all macros
    teach macros list --all        # Show with source info
    teach macros list --category operators
    teach macros list --json       # JSON output

EOF
}

# ============================================================================
# TEACH MACROS SYNC
# ============================================================================

# =============================================================================
# Function: _teach_macros_sync
# Purpose: Extract macros from source files and update cache
# =============================================================================
# Arguments:
#   --force     Force re-sync even if cache is fresh
#   --verbose   Show detailed parsing output
#
# Returns:
#   0 - Success
#   1 - No sources found or error
#
# Performance: Target < 500ms
# =============================================================================
_teach_macros_sync() {
    local force=false
    local verbose=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force|-f)    force=true; shift ;;
            --verbose|-v)  verbose=true; shift ;;
            --help|-h)     _teach_macros_sync_help; return 0 ;;
            *)             shift ;;
        esac
    done

    local start_time=$EPOCHREALTIME

    # Check for config file
    local config_file=".flow/teach-config.yml"
    if [[ ! -f "$config_file" ]]; then
        _flow_log_error "teach-config.yml not found"
        echo "  Run 'teach init' to create configuration"
        return 1
    fi

    echo ""
    echo "${FLOW_COLORS[bold]}🔄 Syncing LaTeX Macros${FLOW_COLORS[reset]}"
    echo ""

    # Get previous macro count for diff
    local prev_count=0
    if [[ -f ".flow/macros/cache.yml" ]]; then
        prev_count=$(command grep -c "^  [a-zA-Z]" ".flow/macros/cache.yml" 2>/dev/null || echo "0")
    fi

    # Clear and reload macros
    _flow_clear_macros

    if ! _flow_load_macro_config; then
        _flow_log_error "Failed to load macro configuration"
        return 1
    fi

    local count=$(_flow_macro_count)

    # Ensure cache directory exists
    _macro_ensure_cache_dir || return 1

    # Write cache file
    local cache_file=".flow/macros/cache.yml"
    {
        echo "# LaTeX Macro Cache"
        echo "# Generated by: teach macros sync"
        echo "# Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        echo "macros:"

        for name in ${(ko)_FLOW_MACROS}; do
            local expansion="${_FLOW_MACROS[$name]}"
            local meta="${_FLOW_MACRO_META[$name]}"

            # Escape for YAML
            expansion="${expansion//\\/\\\\}"
            expansion="${expansion//\"/\\\"}"

            echo "  $name:"
            echo "    expansion: \"$expansion\""
            echo "    source: \"${meta%%:*}\""
            echo "    line: ${meta#*:}"
        done
    } > "$cache_file"

    # Calculate elapsed time
    local end_time=$EPOCHREALTIME
    local elapsed=$(printf "%.0f" $(( (end_time - start_time) * 1000 )))

    # Show results
    echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Parsed $count macros"

    # Show diff if there were previous macros
    if (( prev_count > 0 )); then
        local diff=$((count - prev_count))
        if (( diff > 0 )); then
            echo "  ${FLOW_COLORS[success]}+${diff}${FLOW_COLORS[reset]} new macros"
        elif (( diff < 0 )); then
            echo "  ${FLOW_COLORS[warning]}${diff}${FLOW_COLORS[reset]} macros removed"
        else
            echo "  ${FLOW_COLORS[muted]}No changes${FLOW_COLORS[reset]}"
        fi
    fi

    echo "  ${FLOW_COLORS[muted]}Cache: $cache_file${FLOW_COLORS[reset]}"
    echo "  ${FLOW_COLORS[muted]}Time: ${elapsed}ms${FLOW_COLORS[reset]}"
    echo ""

    # Verbose output
    if [[ "$verbose" == true ]]; then
        echo "${FLOW_COLORS[bold]}Sources parsed:${FLOW_COLORS[reset]}"
        local sources=$(yq eval '.scholar.latex_macros.sources[].path' "$config_file" 2>/dev/null)
        echo "$sources" | while read -r src; do
            [[ -n "$src" && "$src" != "null" ]] && echo "  • $src"
        done
        echo ""
    fi

    return 0
}

_teach_macros_sync_help() {
    cat << 'EOF'

  teach macros sync - Extract macros from sources

  USAGE
    teach macros sync [options]

  OPTIONS
    -f, --force          Force re-sync even if cache is fresh
    -v, --verbose        Show detailed parsing output
    -h, --help           Show this help

  WHAT IT DOES
    1. Reads latex_macros config from teach-config.yml
    2. Parses all configured source files
    3. Writes merged macros to .flow/macros/cache.yml
    4. Shows diff from previous sync

  PERFORMANCE
    Target: < 500ms for typical course (~20 macros)

  EXAMPLES
    teach macros sync              # Sync macros
    teach macros sync --verbose    # Show parsing details
    teach macros sync --force      # Force refresh

EOF
}

# ============================================================================
# TEACH MACROS EXPORT
# ============================================================================

# =============================================================================
# Function: _teach_macros_export
# Purpose: Export macros for Scholar or other tools
# =============================================================================
# Arguments:
#   --format FORMAT    Output format: json (default), mathjax, latex, qmd
#
# Returns:
#   0 - Success
#   1 - No macros or error
#
# Performance: Target < 50ms
# =============================================================================
_teach_macros_export() {
    local format="json"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --format=*)    format="${1#*=}"; shift ;;
            --format|-f)   shift; format="$1"; shift ;;
            --json|-j)     format="json"; shift ;;
            --mathjax|-m)  format="mathjax"; shift ;;
            --latex|-l)    format="latex"; shift ;;
            --qmd|-q)      format="qmd"; shift ;;
            --help|-h)     _teach_macros_export_help; return 0 ;;
            *)             shift ;;
        esac
    done

    # Load macros if not already loaded
    if (( ${#_FLOW_MACROS} == 0 )); then
        if ! _flow_load_macro_config; then
            _flow_log_error "No macros configured" >&2
            return 1
        fi
    fi

    local count=$(_flow_macro_count)
    if (( count == 0 )); then
        _flow_log_error "No macros to export" >&2
        return 1
    fi

    # Export in requested format
    case "$format" in
        json)
            _flow_export_macros_json
            ;;
        mathjax)
            _flow_export_macros_mathjax
            ;;
        latex)
            _flow_export_macros_latex
            ;;
        qmd)
            _flow_export_macros_qmd
            ;;
        *)
            _flow_log_error "Unknown format: $format" >&2
            echo "  Supported: json, mathjax, latex, qmd" >&2
            return 1
            ;;
    esac

    return 0
}

_teach_macros_export_help() {
    cat << 'EOF'

  teach macros export - Export macros for tools

  USAGE
    teach macros export [--format FORMAT]

  FORMATS
    json       JSON object (default) - for Scholar integration
    mathjax    MathJax config block - for HTML/web
    latex      \newcommand definitions - for .tex files
    qmd        Quarto ```{=tex} block - for .qmd files

  OPTIONS
    -f, --format FORMAT  Output format
    -j, --json           Shortcut for --format json
    -m, --mathjax        Shortcut for --format mathjax
    -l, --latex          Shortcut for --format latex
    -q, --qmd            Shortcut for --format qmd
    -h, --help           Show this help

  EXAMPLES
    teach macros export                    # JSON to stdout
    teach macros export --mathjax          # MathJax config
    teach macros export --latex > macros.tex
    teach macros export -q >> document.qmd

  PERFORMANCE
    Target: < 50ms

EOF
}

# ============================================================================
# TEACH MACROS MAIN DISPATCHER
# ============================================================================

# =============================================================================
# Function: _teach_macros
# Purpose: Main entry point for teach macros subcommand
# =============================================================================
_teach_macros() {
    local cmd="${1:-list}"
    shift 2>/dev/null || true

    case "$cmd" in
        list|ls|l)
            _teach_macros_list "$@"
            ;;
        sync|s)
            _teach_macros_sync "$@"
            ;;
        export|e|x)
            _teach_macros_export "$@"
            ;;
        help|--help|-h)
            _teach_macros_help
            ;;
        *)
            _flow_log_error "Unknown macros command: $cmd"
            echo ""
            _teach_macros_help
            return 1
            ;;
    esac
}

# ============================================================================
# HELP
# ============================================================================

_teach_macros_help() {
    cat << EOF

${FLOW_COLORS[header]}╭─────────────────────────────────────────────────────────────╮${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}teach macros${FLOW_COLORS[reset]} - LaTeX Macro Management                  ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╰─────────────────────────────────────────────────────────────╯${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  teach macros <command> [options]

${FLOW_COLORS[bold]}COMMANDS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}list${FLOW_COLORS[reset]}    Display macros in categorized table
  ${FLOW_COLORS[accent]}sync${FLOW_COLORS[reset]}    Extract macros from sources to cache
  ${FLOW_COLORS[accent]}export${FLOW_COLORS[reset]}  Export macros (json, mathjax, latex, qmd)

${FLOW_COLORS[bold]}QUICK EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} teach macros               ${FLOW_COLORS[dim]}# List all macros${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} teach macros list --all    ${FLOW_COLORS[dim]}# Show source info${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} teach macros sync          ${FLOW_COLORS[dim]}# Refresh cache${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} teach macros export --json ${FLOW_COLORS[dim]}# For Scholar${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}CONFIGURATION${FLOW_COLORS[reset]}
  Add to .flow/teach-config.yml:

  scholar:
    latex_macros:
      enabled: true
      sources:
        - path: "_macros.qmd"
          format: "qmd"
      auto_discover: true   ${FLOW_COLORS[dim]}# Find common locations${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}SUPPORTED FORMATS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}qmd${FLOW_COLORS[reset]}      Quarto documents with \`\`\`{=tex} blocks
  ${FLOW_COLORS[accent]}mathjax${FLOW_COLORS[reset]}  MathJax config files (HTML/JS)
  ${FLOW_COLORS[accent]}latex${FLOW_COLORS[reset]}    Standard .tex files

${FLOW_COLORS[muted]}Run 'teach macros <cmd> --help' for command details${FLOW_COLORS[reset]}

EOF
}
