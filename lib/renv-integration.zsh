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

# =============================================================================
# Function: _read_renv_lock
# Purpose: Read and parse renv.lock JSON structure for R package management
# =============================================================================
# Arguments:
#   $1 - (optional) Path to renv.lock file [default: "renv.lock"]
#
# Returns:
#   0 - Success, valid JSON parsed
#   1 - File not found at specified path
#   2 - Invalid JSON structure or jq not available
#
# Output:
#   stdout - Full JSON content of the renv.lock file
#
# Example:
#   json=$(_read_renv_lock)
#   json=$(_read_renv_lock "/path/to/project/renv.lock")
#
# Notes:
#   - Requires jq for JSON parsing (logs error if missing)
#   - Validates JSON structure before returning content
#   - Used as foundation for other renv functions
# =============================================================================
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

# =============================================================================
# Function: _get_renv_packages
# Purpose: Extract list of package names from renv.lock file
# =============================================================================
# Arguments:
#   $1 - (optional) Path to renv.lock file [default: "renv.lock"]
#
# Returns:
#   0 - Packages found and extracted successfully
#   1 - renv.lock file not found
#   2 - Invalid JSON, jq not available, or no packages in lockfile
#
# Output:
#   stdout - Package names, one per line (can be captured as array)
#
# Example:
#   packages=$(_get_renv_packages)
#   packages=($(_get_renv_packages "/path/to/renv.lock"))
#   while IFS= read -r pkg; do echo "$pkg"; done <<< "$(_get_renv_packages)"
#
# Notes:
#   - Parses renv.lock structure: {"Packages": {"pkg1": {...}, "pkg2": {...}}}
#   - Requires jq for JSON parsing
#   - Returns empty and exit 2 if Packages section is missing or empty
# =============================================================================
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

# =============================================================================
# Function: _get_renv_package_info
# Purpose: Retrieve detailed JSON metadata for a specific package from renv.lock
# =============================================================================
# Arguments:
#   $1 - (required) Package name to look up
#   $2 - (optional) Path to renv.lock file [default: "renv.lock"]
#
# Returns:
#   0 - Package found and info extracted
#   1 - Package name not provided, file not found, or package not in lockfile
#   2 - jq not available for JSON parsing
#
# Output:
#   stdout - JSON object containing package details (Version, Source, Repository, etc.)
#
# Example:
#   info=$(_get_renv_package_info "dplyr")
#   info=$(_get_renv_package_info "ggplot2" "project/renv.lock")
#   version=$(echo "$info" | jq -r '.Version')
#
# Notes:
#   - Returns full package JSON object including Version, Source, Repository, Hash
#   - Returns "null" string (and exit 1) if package not found in lockfile
#   - Requires jq for JSON parsing
# =============================================================================
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

# =============================================================================
# Function: _get_renv_package_version
# Purpose: Extract version string for a specific package from renv.lock
# =============================================================================
# Arguments:
#   $1 - (required) Package name to look up
#   $2 - (optional) Path to renv.lock file [default: "renv.lock"]
#
# Returns:
#   0 - Version extracted (may be empty if Version field missing)
#   1 - Package name not provided or file not found
#   2 - jq not available for JSON parsing
#
# Output:
#   stdout - Version string (e.g., "1.1.4", "2.0.0")
#
# Example:
#   version=$(_get_renv_package_version "dplyr")
#   version=$(_get_renv_package_version "tidyr" "project/renv.lock")
#
# Notes:
#   - Returns empty string if package exists but has no Version field
#   - Used by _check_renv_sync to compare installed vs lockfile versions
#   - Requires jq for JSON parsing
# =============================================================================
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

# =============================================================================
# Function: _get_renv_package_source
# Purpose: Extract installation source for a package from renv.lock
# =============================================================================
# Arguments:
#   $1 - (required) Package name to look up
#   $2 - (optional) Path to renv.lock file [default: "renv.lock"]
#
# Returns:
#   0 - Source extracted (may be empty if Source field missing)
#   1 - Package name not provided or file not found
#   2 - jq not available for JSON parsing
#
# Output:
#   stdout - Source string (e.g., "Repository", "CRAN", "Bioconductor", "GitHub")
#
# Example:
#   source=$(_get_renv_package_source "dplyr")
#   source=$(_get_renv_package_source "devtools" "project/renv.lock")
#
# Notes:
#   - Common sources: "Repository" (CRAN), "Bioconductor", "GitHub", "GitLab"
#   - Useful for determining how to install/update a package
#   - Requires jq for JSON parsing
# =============================================================================
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

# =============================================================================
# Function: _check_renv_sync
# Purpose: Verify installed R packages match versions specified in renv.lock
# =============================================================================
# Arguments:
#   $1 - (optional) Path to renv.lock file [default: "renv.lock"]
#   $2 - (optional) Verbose mode flag (0=quiet, 1=verbose) [default: 0]
#
# Returns:
#   0 - All packages synced (installed versions match lockfile)
#   1 - Sync issues found (missing packages or version mismatches)
#   2 - renv.lock not found or no packages in lockfile
#
# Output:
#   stdout - When verbose=1, lists missing packages and version mismatches
#
# Example:
#   _check_renv_sync && echo "All synced"
#   _check_renv_sync "renv.lock" 1  # Verbose output
#   if ! _check_renv_sync; then echo "Packages need restore"; fi
#
# Notes:
#   - Depends on _check_r_package_installed and _get_r_package_version from r-helpers.zsh
#   - Compares each package's installed version against lockfile version
#   - Collects all discrepancies before reporting (not fail-fast)
#   - Use _renv_restore to fix sync issues
# =============================================================================
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

# =============================================================================
# Function: _renv_restore
# Purpose: Restore R packages from renv.lock using renv::restore()
# =============================================================================
# Arguments:
#   --prompt    - (optional) Prompt before restoring [default: enabled]
#   --no-prompt - (optional) Skip confirmation prompt
#   --clean     - (optional) Remove packages not in lockfile
#   --rebuild   - (optional) Rebuild packages from source
#
# Returns:
#   0 - Packages restored successfully
#   1 - Restore failed or renv.lock not found
#   2 - R not installed or renv package not available
#
# Output:
#   stdout - Progress messages and R output during restore
#
# Example:
#   _renv_restore                      # Interactive restore with prompt
#   _renv_restore --no-prompt          # Non-interactive restore
#   _renv_restore --clean --rebuild    # Full clean rebuild
#
# Notes:
#   - Requires R and renv package to be installed
#   - Must be run from directory containing renv.lock
#   - Uses renv::restore() R function with passed options
#   - Prompts user for confirmation by default (use --no-prompt to skip)
#   - --clean removes packages not listed in lockfile
#   - --rebuild forces source compilation (slower but more reliable)
# =============================================================================
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

# =============================================================================
# Function: _show_renv_status
# Purpose: Display comprehensive status of renv packages (synced, missing, mismatched)
# =============================================================================
# Arguments:
#   --json - (optional) Output as JSON instead of human-readable format
#
# Returns:
#   0 - Status displayed successfully
#   1 - renv.lock not found in current directory
#
# Output:
#   stdout - Formatted status report showing:
#            - Synced packages (installed version matches lockfile)
#            - Missing packages (in lockfile but not installed)
#            - Version mismatches (different version installed)
#   stdout (--json) - JSON object with synced, missing, version_mismatch arrays
#
# Example:
#   _show_renv_status                  # Human-readable output
#   _show_renv_status --json           # JSON output for scripting
#   _show_renv_status --json | jq '.missing'  # Get missing packages
#
# Notes:
#   - Must be run from directory containing renv.lock
#   - Human-readable output uses color coding (green=synced, red=missing, yellow=mismatch)
#   - Suggests running 'teach doctor --fix' when issues found
#   - JSON output includes package names and versions for all categories
# =============================================================================
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
