# lib/renv-integration.zsh - renv Lockfile Integration
# Provides renv.lock parsing and package extraction
#
# Functions:
#   _read_renv_lock()      - Parse renv.lock JSON structure
#   _get_renv_packages()   - Extract package list from renv.lock
#   _check_renv_sync()     - Check if installed packages match lockfile
#   _renv_restore()        - Wrapper for renv::restore()

typeset -g _FLOW_RENV_INTEGRATION_LOADED=1

# ============================================================================
# RENV LOCKFILE PARSING
# ============================================================================

# Read renv.lock and parse JSON structure
# Returns: Full JSON content
# Exit codes:
#   0 - Success
#   1 - File not found
#   2 - Invalid JSON
_read_renv_lock() {
    local lockfile="${1:-renv.lock}"

    if [[ ! -f "$lockfile" ]]; then
        return 1
    fi

    # Check if jq is available for JSON parsing
    if ! command -v jq &>/dev/null; then
        _flow_log_error "jq not found - required for renv.lock parsing"
        return 2
    fi

    # Validate JSON structure
    if ! jq empty "$lockfile" &>/dev/null; then
        _flow_log_error "Invalid JSON in $lockfile"
        return 2
    fi

    # Return full JSON
    cat "$lockfile"
    return 0
}

# Get package names from renv.lock
# Returns: Array of package names (one per line)
# Exit codes:
#   0 - Packages found
#   1 - No renv.lock found
#   2 - Invalid JSON or no packages
_get_renv_packages() {
    local lockfile="${1:-renv.lock}"

    if [[ ! -f "$lockfile" ]]; then
        return 1
    fi

    if ! command -v jq &>/dev/null; then
        _flow_log_error "jq not found - required for renv.lock parsing"
        return 2
    fi

    # Extract package names from renv.lock
    # Structure: {"Packages": {"pkg1": {...}, "pkg2": {...}}}
    local packages
    packages=$(jq -r '.Packages | keys[]' "$lockfile" 2>/dev/null)

    if [[ -z "$packages" ]]; then
        return 2
    fi

    echo "$packages"
    return 0
}

# Get detailed package information from renv.lock
# Args: $1 - Package name
# Returns: JSON object with package details
_get_renv_package_info() {
    local package_name="$1"
    local lockfile="${2:-renv.lock}"

    if [[ -z "$package_name" ]]; then
        return 1
    fi

    if [[ ! -f "$lockfile" ]]; then
        return 1
    fi

    if ! command -v jq &>/dev/null; then
        return 2
    fi

    # Extract package details
    local info
    info=$(jq -r ".Packages.${package_name}" "$lockfile" 2>/dev/null)

    if [[ "$info" == "null" ]]; then
        return 1
    fi

    echo "$info"
    return 0
}

# Get package version from renv.lock
# Args: $1 - Package name
# Returns: Version string
_get_renv_package_version() {
    local package_name="$1"
    local lockfile="${2:-renv.lock}"

    if [[ -z "$package_name" ]]; then
        return 1
    fi

    if [[ ! -f "$lockfile" ]]; then
        return 1
    fi

    if ! command -v jq &>/dev/null; then
        return 2
    fi

    # Extract version
    local version
    version=$(jq -r ".Packages.${package_name}.Version // empty" "$lockfile" 2>/dev/null)

    echo "$version"
}

# Get package source from renv.lock
# Args: $1 - Package name
# Returns: Source (Repository, CRAN, Bioconductor, GitHub, etc.)
_get_renv_package_source() {
    local package_name="$1"
    local lockfile="${2:-renv.lock}"

    if [[ -z "$package_name" ]]; then
        return 1
    fi

    if [[ ! -f "$lockfile" ]]; then
        return 1
    fi

    if ! command -v jq &>/dev/null; then
        return 2
    fi

    # Extract source
    local source
    source=$(jq -r ".Packages.${package_name}.Source // empty" "$lockfile" 2>/dev/null)

    echo "$source"
}

# ============================================================================
# RENV SYNCHRONIZATION CHECK
# ============================================================================

# Check if installed packages match renv.lock
# Returns:
#   0 - All packages synced
#   1 - Some packages missing or version mismatch
#   2 - renv.lock not found
_check_renv_sync() {
    local lockfile="${1:-renv.lock}"
    local verbose="${2:-0}"

    if [[ ! -f "$lockfile" ]]; then
        [[ $verbose -eq 1 ]] && _flow_log_error "renv.lock not found"
        return 2
    fi

    # Get packages from lockfile
    local packages
    packages=$(_get_renv_packages "$lockfile")

    if [[ -z "$packages" ]]; then
        [[ $verbose -eq 1 ]] && _flow_log_error "No packages found in renv.lock"
        return 2
    fi

    local out_of_sync=0
    local missing=()
    local version_mismatch=()

    while IFS= read -r pkg; do
        [[ -z "$pkg" ]] && continue

        # Check if package is installed
        if ! _check_r_package_installed "$pkg"; then
            missing+=("$pkg")
            out_of_sync=1
            continue
        fi

        # Check version match
        local installed_version
        installed_version=$(_get_r_package_version "$pkg")

        local lockfile_version
        lockfile_version=$(_get_renv_package_version "$pkg" "$lockfile")

        if [[ "$installed_version" != "$lockfile_version" ]]; then
            version_mismatch+=("$pkg: installed=$installed_version, lockfile=$lockfile_version")
            out_of_sync=1
        fi
    done <<< "$packages"

    if [[ $verbose -eq 1 ]]; then
        if [[ $out_of_sync -eq 0 ]]; then
            _flow_log_success "All packages synced with renv.lock"
        else
            if [[ ${#missing[@]} -gt 0 ]]; then
                _flow_log_warning "Missing packages:"
                printf '  - %s\n' "${missing[@]}"
            fi

            if [[ ${#version_mismatch[@]} -gt 0 ]]; then
                _flow_log_warning "Version mismatches:"
                printf '  - %s\n' "${version_mismatch[@]}"
            fi
        fi
    fi

    return $out_of_sync
}

# ============================================================================
# RENV RESTORE WRAPPER
# ============================================================================

# Restore packages from renv.lock using renv::restore()
# Args:
#   --prompt - Prompt before restoring (default: yes)
#   --clean - Clean (remove) packages not in lockfile
#   --rebuild - Rebuild packages from source
# Returns:
#   0 - Success
#   1 - Failed
#   2 - R or renv not available
_renv_restore() {
    local prompt=1
    local clean=0
    local rebuild=0

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --prompt) prompt=1; shift ;;
            --no-prompt) prompt=0; shift ;;
            --clean) clean=1; shift ;;
            --rebuild) rebuild=1; shift ;;
            *) shift ;;
        esac
    done

    # Check if R is available
    if ! command -v R &>/dev/null; then
        _flow_log_error "R not found - please install R first"
        return 2
    fi

    # Check if renv.lock exists
    if [[ ! -f "renv.lock" ]]; then
        _flow_log_error "renv.lock not found in current directory"
        return 1
    fi

    # Check if renv package is available
    if ! _check_r_package_installed "renv"; then
        _flow_log_error "renv package not installed"
        echo ""
        echo -e "${FLOW_COLORS[muted]}Install renv with:${FLOW_COLORS[reset]}"
        echo -e "${FLOW_COLORS[cmd]}  R -e 'install.packages(\"renv\")'${FLOW_COLORS[reset]}"
        return 2
    fi

    # Prompt for confirmation if enabled
    if [[ $prompt -eq 1 ]]; then
        _flow_log_warning "Restore packages from renv.lock?"
        echo -e "${FLOW_COLORS[muted]}This will install/update packages to match the lockfile${FLOW_COLORS[reset]}"
        read -r response

        response=${response:-y}

        if [[ ! "$response" =~ ^[Yy] ]]; then
            _flow_log_info "Restore cancelled"
            return 0
        fi
    fi

    _flow_log_info "Restoring packages from renv.lock..."

    # Build R command
    local r_cmd="renv::restore("

    # Add options
    [[ $prompt -eq 0 ]] && r_cmd+="prompt = FALSE, "
    [[ $clean -eq 1 ]] && r_cmd+="clean = TRUE, "
    [[ $rebuild -eq 1 ]] && r_cmd+="rebuild = TRUE, "

    # Remove trailing comma and close
    r_cmd="${r_cmd%, })"

    # Execute restore
    if R --quiet --slave -e "$r_cmd"; then
        _flow_log_success "Packages restored successfully"
        return 0
    else
        _flow_log_error "Failed to restore packages"
        return 1
    fi
}

# ============================================================================
# RENV STATUS
# ============================================================================

# Show renv status (packages in lockfile vs installed)
# Args:
#   --json - Output as JSON
# Returns: Formatted status report
_show_renv_status() {
    local output_json=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json) output_json=1; shift ;;
            *) shift ;;
        esac
    done

    if [[ ! -f "renv.lock" ]]; then
        if [[ $output_json -eq 1 ]]; then
            echo '{"error": "renv.lock not found"}'
        else
            _flow_log_error "renv.lock not found in current directory"
        fi
        return 1
    fi

    # Get packages from lockfile
    local packages
    packages=$(_get_renv_packages)

    if [[ -z "$packages" ]]; then
        if [[ $output_json -eq 1 ]]; then
            echo '{"packages": []}'
        else
            _flow_log_warning "No packages found in renv.lock"
        fi
        return 0
    fi

    # Check status for each package
    local synced=()
    local missing=()
    local version_mismatch=()

    while IFS= read -r pkg; do
        [[ -z "$pkg" ]] && continue

        local lockfile_version
        lockfile_version=$(_get_renv_package_version "$pkg")

        if ! _check_r_package_installed "$pkg"; then
            missing+=("$pkg|$lockfile_version")
            continue
        fi

        local installed_version
        installed_version=$(_get_r_package_version "$pkg")

        if [[ "$installed_version" == "$lockfile_version" ]]; then
            synced+=("$pkg|$installed_version")
        else
            version_mismatch+=("$pkg|$installed_version|$lockfile_version")
        fi
    done <<< "$packages"

    if [[ $output_json -eq 1 ]]; then
        # JSON output
        echo "{"
        echo '  "synced": ['
        local first=1
        for item in "${synced[@]}"; do
            local pkg="${item%%|*}"
            local ver="${item##*|}"
            [[ $first -eq 0 ]] && echo ","
            first=0
            echo -n "    {\"name\": \"$pkg\", \"version\": \"$ver\"}"
        done
        echo ""
        echo "  ],"
        echo '  "missing": ['
        first=1
        for item in "${missing[@]}"; do
            local pkg="${item%%|*}"
            local ver="${item##*|}"
            [[ $first -eq 0 ]] && echo ","
            first=0
            echo -n "    {\"name\": \"$pkg\", \"lockfile_version\": \"$ver\"}"
        done
        echo ""
        echo "  ],"
        echo '  "version_mismatch": ['
        first=1
        for item in "${version_mismatch[@]}"; do
            IFS='|' read -r pkg installed lockfile <<< "$item"
            [[ $first -eq 0 ]] && echo ","
            first=0
            echo -n "    {\"name\": \"$pkg\", \"installed\": \"$installed\", \"lockfile\": \"$lockfile\"}"
        done
        echo ""
        echo "  ]"
        echo "}"
    else
        # Human-readable output
        echo -e "${FLOW_COLORS[header]}renv Status:${FLOW_COLORS[reset]}"
        echo ""

        if [[ ${#synced[@]} -gt 0 ]]; then
            echo -e "${FLOW_COLORS[success]}Synced (${#synced[@]}):${FLOW_COLORS[reset]}"
            for item in "${synced[@]}"; do
                local pkg="${item%%|*}"
                local ver="${item##*|}"
                printf "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} %-20s %s\n" "$pkg" "${FLOW_COLORS[muted]}$ver${FLOW_COLORS[reset]}"
            done
            echo ""
        fi

        if [[ ${#missing[@]} -gt 0 ]]; then
            echo -e "${FLOW_COLORS[warning]}Missing (${#missing[@]}):${FLOW_COLORS[reset]}"
            for item in "${missing[@]}"; do
                local pkg="${item%%|*}"
                local ver="${item##*|}"
                printf "  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} %-20s %s\n" "$pkg" "${FLOW_COLORS[muted]}(expected: $ver)${FLOW_COLORS[reset]}"
            done
            echo ""
        fi

        if [[ ${#version_mismatch[@]} -gt 0 ]]; then
            echo -e "${FLOW_COLORS[warning]}Version Mismatch (${#version_mismatch[@]}):${FLOW_COLORS[reset]}"
            for item in "${version_mismatch[@]}"; do
                IFS='|' read -r pkg installed lockfile <<< "$item"
                printf "  ${FLOW_COLORS[warning]}⚠${FLOW_COLORS[reset]} %-20s ${FLOW_COLORS[muted]}installed: $installed, lockfile: $lockfile${FLOW_COLORS[reset]}\n" "$pkg"
            done
            echo ""
        fi

        if [[ ${#missing[@]} -gt 0 || ${#version_mismatch[@]} -gt 0 ]]; then
            echo -e "${FLOW_COLORS[muted]}Run ${FLOW_COLORS[cmd]}teach doctor --fix${FLOW_COLORS[muted]} to restore packages${FLOW_COLORS[reset]}"
        fi
    fi

    return 0
}
