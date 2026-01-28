#!/usr/bin/env zsh

# =============================================================================
# lib/macro-parser.zsh
# LaTeX macro parsing library for teach commands
# Part of flow-cli - Pure ZSH plugin for ADHD-optimized workflow management
# =============================================================================
#
# Features:
#   - Parse LaTeX macros from multiple source formats (QMD, MathJax, LaTeX)
#   - Merge macros from multiple sources with configurable priority
#   - Content-hash based cache invalidation
#   - Performance target: < 100ms per file parsing
#
# Supported Formats:
#   - QMD: Quarto documents with ```{=tex} blocks containing \newcommand
#   - MathJax: HTML/JS config files with MathJax.tex.macros = {...}
#   - LaTeX: Standard .tex files with \newcommand/\renewcommand
#
# Data Structures:
#   $_FLOW_MACROS      - Associative array: name -> expansion
#   $_FLOW_MACRO_META  - Associative array: name -> source:line:args
#
# =============================================================================

# Load guard - prevent double-sourcing
if [[ -n "$_FLOW_MACRO_PARSER_LOADED" ]]; then
    return 0 2>/dev/null || true
fi
typeset -g _FLOW_MACRO_PARSER_LOADED=1

# Disable zsh options that cause variable assignments to print
unsetopt local_options 2>/dev/null
unsetopt print_exit_value 2>/dev/null
setopt NO_local_options 2>/dev/null

# Source core library if not already loaded
if ! typeset -f _flow_log_debug >/dev/null 2>&1; then
    source "${0:A:h}/core.zsh" 2>/dev/null || true
fi

# =============================================================================
# GLOBAL DATA STRUCTURES
# =============================================================================

# Macro registry: name -> expansion
# Example: _FLOW_MACROS[E]="\\mathbb{E}"
typeset -gA _FLOW_MACROS

# Macro metadata: name -> source:line:arg_count
# Example: _FLOW_MACRO_META[E]="_macros.qmd:5:0"
typeset -gA _FLOW_MACRO_META

# =============================================================================
# CONSTANTS
# =============================================================================

# Supported macro source formats
readonly MACRO_FORMAT_QMD="qmd"
readonly MACRO_FORMAT_MATHJAX="mathjax"
readonly MACRO_FORMAT_LATEX="latex"

# Common macro file locations (for auto-discovery)
readonly -a MACRO_AUTO_DISCOVER_PATHS=(
    "_macros.qmd"
    "macros.qmd"
    "includes/_macros.qmd"
    "includes/mathjax-macros.html"
    "includes/mathjax.html"
    "tex/macros.tex"
    "includes/macros.tex"
    "_extensions/*/macros.tex"
)

# =============================================================================
# INTERNAL HELPERS
# =============================================================================

# =============================================================================
# Function: _macro_get_cache_dir
# Purpose: Get the cache directory for macro data
# =============================================================================
# Arguments:
#   $1 - (optional) Course directory [default: $PWD]
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Path to .flow/macros/ cache directory
# =============================================================================
_macro_get_cache_dir() {
    local course_dir="${1:-$PWD}"
    echo "$course_dir/.flow/macros"
}

# =============================================================================
# Function: _macro_ensure_cache_dir
# Purpose: Create cache directory if it doesn't exist
# =============================================================================
# Arguments:
#   $1 - (optional) Course directory [default: $PWD]
#
# Returns:
#   0 - Success
#   1 - Failed to create directory
# =============================================================================
_macro_ensure_cache_dir() {
    local course_dir="${1:-$PWD}"
    local cache_dir
    cache_dir=$(_macro_get_cache_dir "$course_dir")

    if [[ ! -d "$cache_dir" ]]; then
        mkdir -p "$cache_dir" 2>/dev/null || {
            _flow_log_error "Failed to create macro cache directory: $cache_dir"
            return 1
        }
    fi
    return 0
}

# =============================================================================
# Function: _macro_normalize_name
# Purpose: Normalize macro name by removing leading backslash
# =============================================================================
# Arguments:
#   $1 - (required) Macro name (with or without backslash)
#
# Output:
#   stdout - Normalized name without leading backslash
#
# Example:
#   _macro_normalize_name "\\E"     # Output: E
#   _macro_normalize_name "E"       # Output: E
# =============================================================================
_macro_normalize_name() {
    local name="$1"
    # Remove leading backslash if present
    echo "${name#\\}"
}

# =============================================================================
# Function: _macro_count_args
# Purpose: Count the number of arguments in a LaTeX macro definition
# =============================================================================
# Arguments:
#   $1 - (required) Full \newcommand definition line
#
# Output:
#   stdout - Number of arguments (0-9)
#
# Example:
#   _macro_count_args "\\newcommand{\\Cov}[2]{\\text{Cov}(#1, #2)}"
#   # Output: 2
# =============================================================================
_macro_count_args() {
    local definition="$1"

    # Look for [n] pattern after macro name
    if [[ "$definition" =~ '\[([0-9])\]' ]]; then
        echo "${match[1]}"
    else
        echo "0"
    fi
}

# =============================================================================
# Function: _macro_extract_expansion
# Purpose: Extract the expansion (body) from a \newcommand definition
# =============================================================================
# Arguments:
#   $1 - (required) Full \newcommand definition line
#
# Output:
#   stdout - The macro expansion (content of the last {} block)
#
# Example:
#   _macro_extract_expansion "\\newcommand{\\E}{\\mathbb{E}}"
#   # Output: \mathbb{E}
# =============================================================================
_macro_extract_expansion() {
    local definition="$1"
    local remaining="$definition"
    local expansion=""

    # Strategy: Find the last balanced {} block
    # We need to handle nested braces properly

    # Handle different command types:
    # \newcommand{\name}{body}
    # \newcommand{\name}[n]{body}
    # \DeclareMathOperator{\name}{body}

    # Check for DeclareMathOperator first (doesn't end in "command")
    if [[ "$remaining" =~ '\\DeclareMathOperator\*?' ]]; then
        remaining="${remaining#*DeclareMathOperator}"
        remaining="${remaining#\*}"  # Handle starred version
    elif [[ "$remaining" =~ '\\(new|renew)command\*?' ]]; then
        remaining="${remaining#*command}"
        remaining="${remaining#\*}"  # Handle starred version
    fi

    # Skip past {\name}
    if [[ "$remaining" =~ '^\{\\[a-zA-Z@]+\}' ]]; then
        remaining="${remaining#*\}}"
    elif [[ "$remaining" =~ '^\\[a-zA-Z@]+' ]]; then
        # Handle \newcommand\name{body} format (no braces around name)
        remaining="${remaining#\\}"
        remaining="${remaining#[a-zA-Z@]##}"
    fi

    # Skip optional argument spec [n]
    if [[ "$remaining" =~ '^\[[0-9]\]' ]]; then
        remaining="${remaining#\[[0-9]\]}"
    fi

    # Skip optional default argument [default]
    if [[ "$remaining" =~ '^\[[^\]]*\]' ]]; then
        remaining="${remaining#\[*\]}"
    fi

    # Now remaining should start with {body}
    # Extract content between first { and matching }
    if [[ "$remaining" =~ '^\{' ]]; then
        remaining="${remaining#\{}"
        # Find matching closing brace
        local depth=1
        local i=0
        local len=${#remaining}

        while (( i < len && depth > 0 )); do
            local char="${remaining:$i:1}"
            if [[ "$char" == "{" ]]; then
                ((depth++))
            elif [[ "$char" == "}" ]]; then
                ((depth--))
            fi
            if (( depth > 0 )); then
                expansion="${expansion}${char}"
            fi
            ((i++))
        done
    fi

    # Use printf %s to avoid interpreting escape sequences like \t
    printf '%s' "$expansion"
}

# =============================================================================
# Function: _macro_extract_name
# Purpose: Extract macro name from a \newcommand definition
# =============================================================================
# Arguments:
#   $1 - (required) Full \newcommand definition line
#
# Output:
#   stdout - Macro name without backslash
#
# Example:
#   _macro_extract_name "\\newcommand{\\E}{\\mathbb{E}}"
#   # Output: E
# =============================================================================
_macro_extract_name() {
    local definition="$1"
    local name=""

    # Pattern: \newcommand{\name} or \newcommand*{\name} or \renewcommand{\name}
    if [[ "$definition" =~ '\\(new|renew)command\*?\{\\([a-zA-Z@]+)\}' ]]; then
        name="${match[2]}"
    # Alternative pattern: \newcommand\name (without braces around name)
    elif [[ "$definition" =~ '\\(new|renew)command\*?\\([a-zA-Z@]+)' ]]; then
        name="${match[2]}"
    # DeclareMathOperator pattern
    elif [[ "$definition" =~ '\\DeclareMathOperator\*?\{\\([a-zA-Z@]+)\}' ]]; then
        name="${match[1]}"
    fi

    echo "$name"
}

# =============================================================================
# CORE PARSER FUNCTIONS
# =============================================================================

# =============================================================================
# Function: _flow_parse_macros
# Purpose: Format dispatcher that routes to specific parsers
# =============================================================================
# Arguments:
#   $1 - (required) Source file path
#   $2 - (optional) Format: "qmd" | "mathjax" | "latex" | "auto" [default: auto]
#
# Returns:
#   0 - Success (macros added to $_FLOW_MACROS)
#   1 - File not found or parse error
#
# Output:
#   Populates global arrays $_FLOW_MACROS and $_FLOW_MACRO_META
#
# Example:
#   _flow_parse_macros "_macros.qmd" "qmd"
#   _flow_parse_macros "macros.tex"  # Auto-detects format
# =============================================================================
_flow_parse_macros() {
    local source_file="$1"
    local format="${2:-auto}"

    # Validate file exists
    if [[ ! -f "$source_file" ]]; then
        _flow_log_error "Macro source file not found: $source_file"
        return 1
    fi

    # Auto-detect format from extension if not specified
    if [[ "$format" == "auto" ]]; then
        case "${source_file:e}" in
            qmd)  format="$MACRO_FORMAT_QMD" ;;
            html) format="$MACRO_FORMAT_MATHJAX" ;;
            tex)  format="$MACRO_FORMAT_LATEX" ;;
            js)   format="$MACRO_FORMAT_MATHJAX" ;;
            *)
                # Try to detect from content
                if command grep -q 'MathJax' "$source_file" 2>/dev/null; then
                    format="$MACRO_FORMAT_MATHJAX"
                elif command grep -q '```{=tex}' "$source_file" 2>/dev/null; then
                    format="$MACRO_FORMAT_QMD"
                else
                    format="$MACRO_FORMAT_LATEX"  # Default fallback
                fi
                ;;
        esac
    fi

    _flow_log_debug "Parsing macros from $source_file (format: $format)"

    # Dispatch to format-specific parser
    case "$format" in
        "$MACRO_FORMAT_QMD")
            _flow_parse_qmd_macros "$source_file"
            ;;
        "$MACRO_FORMAT_MATHJAX")
            _flow_parse_mathjax_macros "$source_file"
            ;;
        "$MACRO_FORMAT_LATEX")
            _flow_parse_latex_macros "$source_file"
            ;;
        *)
            _flow_log_error "Unknown macro format: $format"
            return 1
            ;;
    esac
}

# =============================================================================
# Function: _flow_parse_qmd_macros
# Purpose: Parse LaTeX macros from Quarto documents
# =============================================================================
# Arguments:
#   $1 - (required) Path to .qmd file
#
# Returns:
#   0 - Success
#   1 - File not found or parse error
#
# Output:
#   Populates $_FLOW_MACROS and $_FLOW_MACRO_META
#
# Notes:
#   Parses macros from ```{=tex} blocks containing \newcommand definitions
#
# Example QMD format:
#   ```{=tex}
#   \newcommand{\E}{\mathbb{E}}
#   \newcommand{\Var}{\text{Var}}
#   ```
# =============================================================================
_flow_parse_qmd_macros() {
    local file="$1"
    local basename="${file:t}"

    if [[ ! -f "$file" ]]; then
        _flow_log_error "QMD file not found: $file"
        return 1
    fi

    local in_tex_block=0
    local line_num=0
    local macros_found=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_num++))

        # Check for tex block start
        if [[ "$line" =~ '```\{=tex\}' ]]; then
            in_tex_block=1
            continue
        fi

        # Check for tex block end
        if [[ "$in_tex_block" -eq 1 && "$line" =~ '```' ]]; then
            in_tex_block=0
            continue
        fi

        # Parse macros inside tex blocks
        if [[ "$in_tex_block" -eq 1 ]]; then
            # Look for \newcommand or \renewcommand or \DeclareMathOperator
            if [[ "$line" =~ '\\(new|renew)command' ]] || [[ "$line" =~ '\\DeclareMathOperator' ]]; then
                # NOTE: Combine local+assignment to avoid zsh output bug with separate statements
                local name=$(_macro_extract_name "$line")

                if [[ -n "$name" ]]; then
                    local expansion=$(_macro_extract_expansion "$line")
                    local arg_count=$(_macro_count_args "$line")

                    # Store in global arrays
                    _FLOW_MACROS[$name]="$expansion"
                    _FLOW_MACRO_META[$name]="$basename:$line_num:$arg_count"
                    ((macros_found++))

                    _flow_log_debug "Found macro: \\$name -> $expansion (args: $arg_count)"
                fi
            fi
        fi
    done < "$file"

    _flow_log_debug "Parsed $macros_found macros from $file"
    return 0
}

# =============================================================================
# Function: _flow_parse_mathjax_macros
# Purpose: Parse macros from MathJax configuration files
# =============================================================================
# Arguments:
#   $1 - (required) Path to HTML/JS file with MathJax config
#
# Returns:
#   0 - Success
#   1 - File not found or parse error
#
# Output:
#   Populates $_FLOW_MACROS and $_FLOW_MACRO_META
#
# Notes:
#   Parses MathJax = { tex: { macros: { ... } } } format
#   Also supports Macros: { ... } in older MathJax 2.x format
#
# Example MathJax format:
#   MathJax = {
#     tex: {
#       macros: {
#         E: "\\mathbb{E}",
#         Var: "\\text{Var}",
#         Cov: ["\\text{Cov}(#1, #2)", 2]
#       }
#     }
#   }
# =============================================================================
_flow_parse_mathjax_macros() {
    local file="$1"
    local basename="${file:t}"

    if [[ ! -f "$file" ]]; then
        _flow_log_error "MathJax config file not found: $file"
        return 1
    fi

    local content
    content=$(cat "$file")

    local macros_found=0
    local in_macros_block=0
    local brace_depth=0
    local line_num=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_num++))

        # Detect start of macros block (MathJax 3.x or 2.x)
        if [[ "$line" =~ 'macros[[:space:]]*:[[:space:]]*\{' ]] || \
           [[ "$line" =~ 'Macros[[:space:]]*:[[:space:]]*\{' ]]; then
            in_macros_block=1
            brace_depth=1
            continue
        fi

        # Track brace depth
        if [[ "$in_macros_block" -eq 1 ]]; then
            # Count opening braces
            local open_braces="${line//[^\{]/}"
            local close_braces="${line//[^\}]/}"
            ((brace_depth += ${#open_braces}))
            ((brace_depth -= ${#close_braces}))

            # Check if we've exited the macros block
            if (( brace_depth <= 0 )); then
                in_macros_block=0
                continue
            fi

            # Parse macro definitions
            # Pattern 1: name: "expansion"
            # Pattern 2: name: ["expansion", argcount]
            if [[ "$line" =~ '([a-zA-Z][a-zA-Z0-9]*)[[:space:]]*:[[:space:]]*"([^"]*)"' ]]; then
                local name="${match[1]}"
                local expansion="${match[2]}"

                _FLOW_MACROS[$name]="$expansion"
                _FLOW_MACRO_META[$name]="$basename:$line_num:0"
                ((macros_found++))

                _flow_log_debug "Found MathJax macro: \\$name -> $expansion"

            elif [[ "$line" =~ '([a-zA-Z][a-zA-Z0-9]*)[[:space:]]*:[[:space:]]*\["([^"]*)"[[:space:]]*,[[:space:]]*([0-9]+)\]' ]]; then
                local name="${match[1]}"
                local expansion="${match[2]}"
                local arg_count="${match[3]}"

                _FLOW_MACROS[$name]="$expansion"
                _FLOW_MACRO_META[$name]="$basename:$line_num:$arg_count"
                ((macros_found++))

                _flow_log_debug "Found MathJax macro: \\$name -> $expansion (args: $arg_count)"
            fi
        fi
    done < "$file"

    _flow_log_debug "Parsed $macros_found macros from $file"
    return 0
}

# =============================================================================
# Function: _flow_parse_latex_macros
# Purpose: Parse macros from standard LaTeX .tex files
# =============================================================================
# Arguments:
#   $1 - (required) Path to .tex file
#
# Returns:
#   0 - Success
#   1 - File not found or parse error
#
# Output:
#   Populates $_FLOW_MACROS and $_FLOW_MACRO_META
#
# Notes:
#   Parses \newcommand, \renewcommand, \DeclareMathOperator definitions
#   Handles multi-line definitions
#
# Example LaTeX format:
#   \newcommand{\E}{\mathbb{E}}
#   \newcommand{\Cov}[2]{\text{Cov}(#1, #2)}
#   \DeclareMathOperator{\argmax}{arg\,max}
# =============================================================================
_flow_parse_latex_macros() {
    local file="$1"
    local basename="${file:t}"

    if [[ ! -f "$file" ]]; then
        _flow_log_error "LaTeX file not found: $file"
        return 1
    fi

    local macros_found=0
    local line_num=0
    local buffer=""
    local buffer_start_line=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_num++))

        # Skip comments
        [[ "$line" =~ ^[[:space:]]*% ]] && continue

        # Remove inline comments
        line="${line%%\%*}"

        # Look for command definitions
        if [[ "$line" =~ '\\(new|renew)command' ]] || \
           [[ "$line" =~ '\\DeclareMathOperator' ]] || \
           [[ -n "$buffer" ]]; then

            # Start or continue building buffer
            if [[ -z "$buffer" ]]; then
                buffer="$line"
                buffer_start_line=$line_num
            else
                buffer="$buffer $line"
            fi

            # Check if definition is complete (balanced braces)
            local open_count="${buffer//[^\{]/}"
            local close_count="${buffer//[^\}]/}"

            if (( ${#open_count} == ${#close_count} && ${#open_count} > 0 )); then
                # Definition is complete, parse it
                # NOTE: Combine local+assignment to avoid zsh output bug
                local name=$(_macro_extract_name "$buffer")

                if [[ -n "$name" ]]; then
                    local expansion=$(_macro_extract_expansion "$buffer")
                    local arg_count=$(_macro_count_args "$buffer")

                    _FLOW_MACROS[$name]="$expansion"
                    _FLOW_MACRO_META[$name]="$basename:$buffer_start_line:$arg_count"
                    ((macros_found++))

                    _flow_log_debug "Found LaTeX macro: \\$name -> $expansion (args: $arg_count)"
                fi

                buffer=""
                buffer_start_line=0
            fi
        fi
    done < "$file"

    _flow_log_debug "Parsed $macros_found macros from $file"
    return 0
}

# =============================================================================
# MERGE AND REGISTRY FUNCTIONS
# =============================================================================

# =============================================================================
# Function: _flow_merge_macros
# Purpose: Merge macros from multiple sources with priority resolution
# =============================================================================
# Arguments:
#   $@ - (required) List of source files in priority order (later wins)
#
# Returns:
#   0 - Success
#   1 - No valid sources found
#
# Output:
#   Populates $_FLOW_MACROS and $_FLOW_MACRO_META with merged results
#
# Notes:
#   Files are processed in order; later definitions override earlier ones.
#   If warn_conflicts is enabled in config, warnings are logged.
#
# Example:
#   _flow_merge_macros "_macros.qmd" "includes/extra.tex" "local.qmd"
# =============================================================================
_flow_merge_macros() {
    local -a sources=("$@")
    local parsed_any=0

    # Clear existing registries
    _FLOW_MACROS=()
    _FLOW_MACRO_META=()

    if (( ${#sources} == 0 )); then
        _flow_log_error "No macro sources provided"
        return 1
    fi

    for source_file in "${sources[@]}"; do
        if [[ -f "$source_file" ]]; then
            # Track existing macros to detect conflicts
            local -A prev_macros
            for key in ${(k)_FLOW_MACROS}; do
                prev_macros[$key]="${_FLOW_MACROS[$key]}"
            done

            # Parse this source
            if _flow_parse_macros "$source_file"; then
                parsed_any=1

                # Log conflicts if we're in debug mode
                if [[ -n "$FLOW_DEBUG" ]]; then
                    for key in ${(k)_FLOW_MACROS}; do
                        if [[ -n "${prev_macros[$key]}" && "${prev_macros[$key]}" != "${_FLOW_MACROS[$key]}" ]]; then
                            _flow_log_debug "Macro conflict for \\$key: '${prev_macros[$key]}' overwritten by '${_FLOW_MACROS[$key]}'"
                        fi
                    done
                fi
            fi
        else
            _flow_log_debug "Macro source not found (skipping): $source_file"
        fi
    done

    if (( parsed_any == 0 )); then
        _flow_log_warning "No valid macro sources found"
        return 1
    fi

    _flow_log_debug "Merged ${#_FLOW_MACROS} macros from ${#sources} sources"
    return 0
}

# =============================================================================
# Function: _flow_clear_macros
# Purpose: Clear all macros from the global registry
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
# =============================================================================
_flow_clear_macros() {
    _FLOW_MACROS=()
    _FLOW_MACRO_META=()
    _flow_log_debug "Cleared macro registry"
}

# =============================================================================
# Function: _flow_get_macro
# Purpose: Get a single macro expansion by name
# =============================================================================
# Arguments:
#   $1 - (required) Macro name (with or without backslash)
#
# Returns:
#   0 - Macro found
#   1 - Macro not found
#
# Output:
#   stdout - Macro expansion
#
# Example:
#   expansion=$(_flow_get_macro "E")
#   expansion=$(_flow_get_macro "\\E")  # Also works
# =============================================================================
_flow_get_macro() {
    local name=$(_macro_normalize_name "$1")

    if [[ -n "${_FLOW_MACROS[$name]}" ]]; then
        # Use printf %s to avoid interpreting escape sequences
        printf '%s' "${_FLOW_MACROS[$name]}"
        return 0
    fi
    return 1
}

# =============================================================================
# Function: _flow_get_macro_meta
# Purpose: Get metadata for a macro (source, line, args)
# =============================================================================
# Arguments:
#   $1 - (required) Macro name (with or without backslash)
#
# Returns:
#   0 - Macro found
#   1 - Macro not found
#
# Output:
#   stdout - Metadata string "source:line:args"
#
# Example:
#   meta=$(_flow_get_macro_meta "E")
#   # Output: _macros.qmd:5:0
# =============================================================================
_flow_get_macro_meta() {
    local name=$(_macro_normalize_name "$1")

    if [[ -n "${_FLOW_MACRO_META[$name]}" ]]; then
        printf '%s' "${_FLOW_MACRO_META[$name]}"
        return 0
    fi
    return 1
}

# =============================================================================
# Function: _flow_list_macros
# Purpose: List all macros in the registry
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Sorted list of macro names (one per line)
# =============================================================================
_flow_list_macros() {
    for name in ${(ko)_FLOW_MACROS}; do
        echo "$name"
    done
}

# =============================================================================
# Function: _flow_macro_count
# Purpose: Get the number of macros in the registry
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Count of macros
# =============================================================================
_flow_macro_count() {
    echo "${#_FLOW_MACROS}"
}

# =============================================================================
# CONFIG LOADING FUNCTIONS
# =============================================================================

# =============================================================================
# Function: _flow_load_macro_config
# Purpose: Load latex_macros configuration from teach-config.yml
# =============================================================================
# Arguments:
#   $1 - (optional) Course directory [default: $PWD]
#
# Returns:
#   0 - Success (macros loaded)
#   1 - Config not found or macros disabled
#
# Output:
#   Populates $_FLOW_MACROS and $_FLOW_MACRO_META from configured sources
#
# Notes:
#   Reads scholar.latex_macros section from teach-config.yml
#   Supports auto_discover mode for common macro file locations
#
# Example config (teach-config.yml):
#   scholar:
#     latex_macros:
#       enabled: true
#       sources:
#         - path: "_macros.qmd"
#           format: "qmd"
#       auto_discover: true
# =============================================================================
_flow_load_macro_config() {
    local course_dir="${1:-$PWD}"
    local config_file="$course_dir/.flow/teach-config.yml"

    # Check for config file
    if [[ ! -f "$config_file" ]]; then
        _flow_log_debug "teach-config.yml not found: $config_file"
        return 1
    fi

    # Check if yq is available
    if ! command -v yq &>/dev/null; then
        _flow_log_error "yq not found. Run: teach doctor --fix"
        return 1
    fi

    # Check if macros are enabled
    local enabled
    enabled=$(yq eval '.scholar.latex_macros.enabled // true' "$config_file" 2>/dev/null)
    if [[ "$enabled" == "false" ]]; then
        _flow_log_debug "LaTeX macros disabled in config"
        return 1
    fi

    # Clear existing macros
    _flow_clear_macros

    # Collect source files
    local -a source_files=()

    # Read configured sources
    local sources_count
    sources_count=$(yq eval '.scholar.latex_macros.sources | length // 0' "$config_file" 2>/dev/null)

    if (( sources_count > 0 )); then
        local i=0
        while (( i < sources_count )); do
            local src_path src_format
            src_path=$(yq eval ".scholar.latex_macros.sources[$i].path" "$config_file" 2>/dev/null)
            src_format=$(yq eval ".scholar.latex_macros.sources[$i].format // \"auto\"" "$config_file" 2>/dev/null)

            if [[ -n "$src_path" && "$src_path" != "null" ]]; then
                # Convert relative path to absolute
                if [[ "${src_path:0:1}" != "/" ]]; then
                    src_path="$course_dir/$src_path"
                fi

                if [[ -f "$src_path" ]]; then
                    source_files+=("$src_path")
                    _flow_log_debug "Adding configured source: $src_path (format: $src_format)"
                fi
            fi
            ((i++))
        done
    fi

    # Auto-discover additional sources if enabled
    local auto_discover
    auto_discover=$(yq eval '.scholar.latex_macros.auto_discover // true' "$config_file" 2>/dev/null)

    if [[ "$auto_discover" == "true" ]]; then
        for pattern in "${MACRO_AUTO_DISCOVER_PATHS[@]}"; do
            local full_pattern="$course_dir/$pattern"

            # Handle glob patterns
            local -a matches=()
            matches=($~full_pattern(N))

            for match in "${matches[@]}"; do
                # Skip if already in source list
                if ! _flow_array_contains "$match" "${source_files[@]}"; then
                    source_files+=("$match")
                    _flow_log_debug "Auto-discovered: $match"
                fi
            done
        done
    fi

    # Parse all sources
    if (( ${#source_files} > 0 )); then
        _flow_merge_macros "${source_files[@]}"
        return $?
    else
        _flow_log_warning "No macro sources found"
        return 1
    fi
}

# =============================================================================
# Function: _flow_discover_macro_sources
# Purpose: Find macro source files in standard locations
# =============================================================================
# Arguments:
#   $1 - (optional) Course directory [default: $PWD]
#
# Returns:
#   0 - At least one source found
#   1 - No sources found
#
# Output:
#   stdout - List of found source files (one per line)
# =============================================================================
_flow_discover_macro_sources() {
    local course_dir="${1:-$PWD}"
    local found=0

    for pattern in "${MACRO_AUTO_DISCOVER_PATHS[@]}"; do
        local full_pattern="$course_dir/$pattern"

        # Handle glob patterns
        local -a matches=()
        matches=($~full_pattern(N))

        for match in "${matches[@]}"; do
            echo "$match"
            found=1
        done
    done

    (( found )) && return 0 || return 1
}

# =============================================================================
# EXPORT FUNCTIONS
# =============================================================================

# =============================================================================
# Function: _flow_export_macros_json
# Purpose: Export macros as JSON for Scholar integration
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - JSON object with macro definitions
#
# Example output:
#   {
#     "E": {"expansion": "\\mathbb{E}", "args": 0, "source": "_macros.qmd:5"},
#     "Var": {"expansion": "\\text{Var}", "args": 0, "source": "_macros.qmd:6"}
#   }
# =============================================================================
_flow_export_macros_json() {
    local json="{"
    local first=1

    for name in ${(ko)_FLOW_MACROS}; do
        local expansion="${_FLOW_MACROS[$name]}"
        local meta="${_FLOW_MACRO_META[$name]}"
        local source="${meta%:*}"      # Remove last :field (args)
        local args="${meta##*:}"       # Get last field (args)

        # Escape special JSON characters in expansion
        expansion="${expansion//\\/\\\\}"  # Escape backslashes
        expansion="${expansion//\"/\\\"}"  # Escape quotes

        if (( first )); then
            first=0
        else
            json="$json,"
        fi

        json="$json\"$name\":{\"expansion\":\"$expansion\",\"args\":$args,\"source\":\"$source\"}"
    done

    json="$json}"
    echo "$json"
}

# =============================================================================
# Function: _flow_export_macros_mathjax
# Purpose: Export macros as MathJax configuration
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - MathJax macros configuration block
#
# Example output:
#   macros: {
#     E: "\\mathbb{E}",
#     Var: "\\text{Var}"
#   }
# =============================================================================
_flow_export_macros_mathjax() {
    echo "macros: {"
    local first=1

    for name in ${(ko)_FLOW_MACROS}; do
        local expansion="${_FLOW_MACROS[$name]}"
        local meta="${_FLOW_MACRO_META[$name]}"
        local args="${meta##*:}"

        if (( first )); then
            first=0
        else
            echo ","
        fi

        # Format with or without arg count
        if (( args > 0 )); then
            printf '  %s: ["%s", %d]' "$name" "$expansion" "$args"
        else
            printf '  %s: "%s"' "$name" "$expansion"
        fi
    done

    echo ""
    echo "}"
}

# =============================================================================
# Function: _flow_export_macros_latex
# Purpose: Export macros as LaTeX \newcommand definitions
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - LaTeX newcommand definitions
#
# Example output:
#   \newcommand{\E}{\mathbb{E}}
#   \newcommand{\Var}{\text{Var}}
# =============================================================================
_flow_export_macros_latex() {
    for name in ${(ko)_FLOW_MACROS}; do
        local expansion="${_FLOW_MACROS[$name]}"
        local meta="${_FLOW_MACRO_META[$name]}"
        local args="${meta##*:}"

        if (( args > 0 )); then
            printf '%s\n' "\\newcommand{\\$name}[$args]{$expansion}"
        else
            printf '%s\n' "\\newcommand{\\$name}{$expansion}"
        fi
    done
}

# =============================================================================
# Function: _flow_export_macros_qmd
# Purpose: Export macros as Quarto tex block
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Quarto ```{=tex} block with macro definitions
# =============================================================================
_flow_export_macros_qmd() {
    echo '```{=tex}'
    _flow_export_macros_latex
    echo '```'
}

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

# =============================================================================
# Function: _flow_validate_macro_usage
# Purpose: Check for undefined macros used in content
# =============================================================================
# Arguments:
#   $1 - (required) Path to content file to validate
#
# Returns:
#   0 - All macros defined
#   1 - Undefined macros found
#
# Output:
#   stdout - List of undefined macro names (if any)
# =============================================================================
_flow_validate_macro_usage() {
    local file="$1"
    local undefined_count=0

    if [[ ! -f "$file" ]]; then
        _flow_log_error "File not found: $file"
        return 1
    fi

    # Extract macro-like patterns from content (ignoring common LaTeX commands)
    local content
    content=$(cat "$file")

    # Find all \word patterns that look like custom macros
    local -a used_macros=()
    while [[ "$content" =~ '\\([A-Z][a-zA-Z]*)' ]]; do
        local macro_name="${match[1]}"
        used_macros+=("$macro_name")
        # Remove first occurrence to continue searching
        content="${content#*\\$macro_name}"
    done

    # Check each used macro against registry
    for macro in "${(u)used_macros[@]}"; do
        if [[ -z "${_FLOW_MACROS[$macro]}" ]]; then
            echo "$macro"
            ((undefined_count++))
        fi
    done

    (( undefined_count == 0 ))
}

# =============================================================================
# Function: _flow_find_unused_macros
# Purpose: Find macros defined but not used in course content
# =============================================================================
# Arguments:
#   $1 - (optional) Course directory [default: $PWD]
#
# Returns:
#   0 - All macros used
#   1 - Unused macros found
#
# Output:
#   stdout - List of unused macro names (if any)
# =============================================================================
_flow_find_unused_macros() {
    local course_dir="${1:-$PWD}"
    local unused_count=0

    # Collect all content from .qmd files
    local all_content=""
    local qmd_files
    qmd_files=($(find "$course_dir" -name "*.qmd" -type f 2>/dev/null))

    for file in "${qmd_files[@]}"; do
        all_content="$all_content$(cat "$file")"
    done

    # Check each defined macro
    for name in ${(k)_FLOW_MACROS}; do
        # Search for \name pattern
        if ! echo "$all_content" | command grep -q "\\\\$name" 2>/dev/null; then
            echo "$name"
            ((unused_count++))
        fi
    done

    (( unused_count == 0 ))
}
