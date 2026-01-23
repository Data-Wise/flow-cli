# lib/r-helpers.zsh - R Package Detection and Installation
# Provides R package detection from multiple sources and auto-installation
#
# Functions:
#   _detect_r_packages()           - Extract R packages from teaching.yml
#   _detect_r_packages_from_description() - Extract from DESCRIPTION file
#   _parse_renv_lock()             - Parse renv.lock if exists
#   _check_r_package_installed()   - Verify R package installation
#   _install_r_packages()          - Install missing R packages
#   _get_r_package_version()       - Get installed package version
#   _list_r_packages_from_sources() - Get packages from all sources
#   _check_missing_r_packages()    - Check which packages are missing
#   _install_missing_r_packages()  - Auto-detect and install missing packages
#   _show_r_package_status()       - Show R package installation status

typeset -g _FLOW_R_HELPERS_LOADED=1

# ============================================================================
# R PACKAGE DETECTION
# ============================================================================

# =============================================================================
# Function: _detect_r_packages
# Purpose: Extract R package names from teaching.yml configuration file
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Packages found and output
#   1 - No teaching.yml found or yq not available
#   2 - No r_packages defined in teaching.yml
#
# Output:
#   stdout - Package names, one per line
#
# Example:
#   packages=$(_detect_r_packages)
#   echo "$packages" | wc -l  # Count packages
#
# Notes:
#   - Requires yq for YAML parsing
#   - Expects teaching.yml at .flow/teaching.yml
#   - YAML structure: r_packages: [list of package names]
# =============================================================================
_detect_r_packages() {
    local teaching_yml=".flow/teaching.yml"

    if [[ ! -f "$teaching_yml" ]]; then
        return 1
    fi

    # Check if yq is available
    if ! command -v yq &>/dev/null; then
        _flow_log_error "yq not found - required for package detection"
        return 1
    fi

    # Extract R packages from teaching.yml
    # Expected structure:
    #   r_packages:
    #     - ggplot2
    #     - dplyr
    local packages
    packages=$(yq eval '.r_packages[]' "$teaching_yml" 2>/dev/null)

    if [[ -z "$packages" ]]; then
        return 2
    fi

    echo "$packages"
    return 0
}

# =============================================================================
# Function: _detect_r_packages_from_description
# Purpose: Extract R package dependencies from DESCRIPTION file (R package projects)
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Packages found and output
#   1 - No DESCRIPTION file found
#   2 - No packages defined in Imports/Depends
#
# Output:
#   stdout - Package names from Imports and Depends fields, one per line
#
# Example:
#   deps=$(_detect_r_packages_from_description)
#   echo "Dependencies: $deps"
#
# Notes:
#   - Parses Imports and Depends sections from DESCRIPTION
#   - Excludes R itself from Depends
#   - Uses simplified AWK parser (production code may use R)
#   - Returns unique sorted list
# =============================================================================
_detect_r_packages_from_description() {
    local desc_file="DESCRIPTION"

    if [[ ! -f "$desc_file" ]]; then
        return 1
    fi

    # Extract packages from Imports and Depends fields
    # This is a simplified parser - production code might use R
    local packages=""

    # Get Imports section
    local imports
    imports=$(awk '/^Imports:/{flag=1;next}/^[A-Z]/{flag=0}flag' "$desc_file" | tr -d ' ' | tr ',' '\n' | grep -v '^$')

    # Get Depends section (excluding R itself)
    local depends
    depends=$(awk '/^Depends:/{flag=1;next}/^[A-Z]/{flag=0}flag' "$desc_file" | tr -d ' ' | tr ',' '\n' | grep -v '^$' | grep -v '^R(')

    packages=$(echo -e "${imports}\n${depends}" | sort -u)

    if [[ -z "$packages" ]]; then
        return 2
    fi

    echo "$packages"
    return 0
}

# =============================================================================
# Function: _list_r_packages_from_sources
# Purpose: Aggregate R packages from all available configuration sources
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Packages found from at least one source
#   1 - No packages found in any source
#
# Output:
#   stdout - Unique sorted list of package names, one per line
#
# Example:
#   all_pkgs=$(_list_r_packages_from_sources)
#   echo "Total packages: $(echo "$all_pkgs" | wc -l)"
#
# Notes:
#   - Aggregates from: teaching.yml, renv.lock, DESCRIPTION
#   - Returns deduplicated, sorted list
#   - Silently skips unavailable sources
# =============================================================================
_list_r_packages_from_sources() {
    local all_packages=""

    # Source 1: teaching.yml
    local yml_packages
    yml_packages=$(_detect_r_packages 2>/dev/null)
    [[ -n "$yml_packages" ]] && all_packages="$yml_packages"

    # Source 2: renv.lock
    if [[ -f "renv.lock" ]]; then
        local renv_packages
        renv_packages=$(_get_renv_packages 2>/dev/null)
        [[ -n "$renv_packages" ]] && all_packages="${all_packages}${all_packages:+\n}${renv_packages}"
    fi

    # Source 3: DESCRIPTION file
    local desc_packages
    desc_packages=$(_detect_r_packages_from_description 2>/dev/null)
    [[ -n "$desc_packages" ]] && all_packages="${all_packages}${all_packages:+\n}${desc_packages}"

    if [[ -z "$all_packages" ]]; then
        return 1
    fi

    # Return unique sorted list
    echo -e "$all_packages" | sort -u
    return 0
}

# ============================================================================
# R PACKAGE INSTALLATION CHECK
# ============================================================================

# =============================================================================
# Function: _check_r_package_installed
# Purpose: Verify if a specific R package is installed in the R environment
# =============================================================================
# Arguments:
#   $1 - (required) Package name to check
#
# Returns:
#   0 - Package is installed
#   1 - Package is not installed or name is empty
#   2 - R is not available on the system
#
# Output:
#   None (exit code only)
#
# Example:
#   if _check_r_package_installed "ggplot2"; then
#       echo "ggplot2 is installed"
#   fi
#
# Notes:
#   - Uses R --quiet --slave to suppress output
#   - Attempts to load package with require()
#   - Fast check suitable for iterating over many packages
# =============================================================================
_check_r_package_installed() {
    local package_name="$1"

    if [[ -z "$package_name" ]]; then
        return 1
    fi

    # Check if R is available
    if ! command -v R &>/dev/null; then
        return 2
    fi

    # Use R to check if package is installed
    # Suppress output and only check exit code
    R --quiet --slave -e "if (!require('$package_name', quietly = TRUE, character.only = TRUE)) quit(status = 1)" &>/dev/null

    return $?
}

# =============================================================================
# Function: _get_r_package_version
# Purpose: Retrieve the installed version of a specific R package
# =============================================================================
# Arguments:
#   $1 - (required) Package name to query
#
# Returns:
#   0 - Version retrieved successfully
#   1 - Package name is empty
#   2 - R is not available on the system
#
# Output:
#   stdout - Version string (e.g., "3.4.0") or empty if not installed
#
# Example:
#   version=$(_get_r_package_version "dplyr")
#   echo "dplyr version: $version"
#
# Notes:
#   - Returns empty string if package not installed
#   - Uses packageVersion() R function
#   - Errors are suppressed (stderr redirected to /dev/null)
# =============================================================================
_get_r_package_version() {
    local package_name="$1"

    if [[ -z "$package_name" ]]; then
        return 1
    fi

    if ! command -v R &>/dev/null; then
        return 2
    fi

    # Get package version using R
    local version
    version=$(R --quiet --slave -e "cat(as.character(packageVersion('$package_name')))" 2>/dev/null)

    echo "$version"
}

# =============================================================================
# Function: _check_missing_r_packages
# Purpose: Identify which packages from a list are not installed
# =============================================================================
# Arguments:
#   $@ - (optional) Package names as arguments
#        If no arguments, reads package names from stdin (one per line)
#
# Returns:
#   0 - At least one missing package found
#   1 - All packages are installed (or empty input)
#
# Output:
#   stdout - Missing package names, one per line
#
# Example:
#   # From arguments
#   missing=$(_check_missing_r_packages ggplot2 dplyr tidyr)
#
#   # From stdin
#   echo -e "ggplot2\ndplyr" | _check_missing_r_packages
#
# Notes:
#   - Calls _check_r_package_installed for each package
#   - Accepts input from arguments or stdin (pipe-friendly)
#   - Empty lines in input are ignored
# =============================================================================
_check_missing_r_packages() {
    local packages=("$@")

    # If no arguments, read from stdin
    if [[ ${#packages[@]} -eq 0 ]]; then
        while IFS= read -r pkg; do
            [[ -z "$pkg" ]] && continue
            packages+=("$pkg")
        done
    fi

    local missing=()

    for pkg in "${packages[@]}"; do
        if ! _check_r_package_installed "$pkg"; then
            missing+=("$pkg")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        printf '%s\n' "${missing[@]}"
        return 0
    fi

    return 1
}

# ============================================================================
# R PACKAGE INSTALLATION
# ============================================================================

# =============================================================================
# Function: _install_r_packages
# Purpose: Install specified R packages from CRAN
# =============================================================================
# Arguments:
#   $@ - Package names to install (mixed with optional flags)
#   --quiet, -q  - (optional) Suppress output messages
#   --yes, -y    - (optional) Skip confirmation prompt
#
# Returns:
#   0 - All packages installed successfully
#   1 - Some packages failed to install or no packages specified
#   2 - R is not available on the system
#
# Output:
#   stdout - Progress messages and installation status (unless --quiet)
#
# Example:
#   # Interactive installation
#   _install_r_packages ggplot2 dplyr
#
#   # Silent automatic installation
#   _install_r_packages --quiet --yes ggplot2 dplyr
#
# Notes:
#   - Uses cloud.r-project.org as CRAN mirror
#   - Installs packages one at a time for better error tracking
#   - Prompts for confirmation unless --yes is specified
#   - Reports which packages failed at the end
# =============================================================================
_install_r_packages() {
    local packages=()
    local quiet=0
    local skip_confirm=0

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --quiet|-q) quiet=1; shift ;;
            --yes|-y) skip_confirm=1; shift ;;
            *) packages+=("$1"); shift ;;
        esac
    done

    if [[ ${#packages[@]} -eq 0 ]]; then
        [[ $quiet -eq 0 ]] && _flow_log_error "No packages specified"
        return 1
    fi

    # Check if R is available
    if ! command -v R &>/dev/null; then
        [[ $quiet -eq 0 ]] && _flow_log_error "R not found - please install R first"
        return 2
    fi

    # Prompt for confirmation unless --yes flag is set
    if [[ $skip_confirm -eq 0 && $quiet -eq 0 ]]; then
        echo -e "${FLOW_COLORS[warning]}Install missing R packages? [Y/n]${FLOW_COLORS[reset]}"
        echo -e "${FLOW_COLORS[muted]}Packages: ${packages[*]}${FLOW_COLORS[reset]}"
        read -r response

        # Default to yes if empty response
        response=${response:-y}

        if [[ ! "$response" =~ ^[Yy] ]]; then
            _flow_log_info "Installation cancelled"
            return 0
        fi
    fi

    # Install packages one by one
    local failed=()

    for pkg in "${packages[@]}"; do
        [[ $quiet -eq 0 ]] && _flow_log_info "Installing $pkg..."

        # Use Rscript for installation
        if Rscript -e "install.packages('$pkg', repos='https://cloud.r-project.org', quiet=TRUE)" &>/dev/null; then
            [[ $quiet -eq 0 ]] && _flow_log_success "$pkg installed"
        else
            [[ $quiet -eq 0 ]] && _flow_log_error "$pkg failed to install"
            failed+=("$pkg")
        fi
    done

    if [[ ${#failed[@]} -gt 0 ]]; then
        [[ $quiet -eq 0 ]] && _flow_log_error "Failed to install: ${failed[*]}"
        return 1
    fi

    [[ $quiet -eq 0 ]] && _flow_log_success "All R packages installed successfully"
    return 0
}

# =============================================================================
# Function: _install_missing_r_packages
# Purpose: Auto-detect required packages from project sources and install missing ones
# =============================================================================
# Arguments:
#   --quiet, -q      - (optional) Suppress output messages
#   --yes, -y        - (optional) Skip confirmation prompt
#   --source <file>  - (optional) Specific source to use:
#                      teaching.yml|teaching, renv.lock|renv, DESCRIPTION|description
#
# Returns:
#   0 - All packages installed or already present
#   1 - Some packages failed to install or unknown source
#   2 - No packages found in configuration
#
# Output:
#   stdout - Progress messages and installation status (unless --quiet)
#
# Example:
#   # From all sources, interactive
#   _install_missing_r_packages
#
#   # From specific source, silent
#   _install_missing_r_packages --source renv.lock --quiet --yes
#
# Notes:
#   - Without --source, checks all sources (teaching.yml, renv.lock, DESCRIPTION)
#   - Only installs packages that are not already installed
#   - Delegates actual installation to _install_r_packages
# =============================================================================
_install_missing_r_packages() {
    local quiet=0
    local skip_confirm=0
    local source=""

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --quiet|-q) quiet=1; shift ;;
            --yes|-y) skip_confirm=1; shift ;;
            --source) source="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    # Get packages from source(s)
    local packages

    if [[ -n "$source" ]]; then
        case "$source" in
            teaching.yml|teaching)
                packages=$(_detect_r_packages)
                ;;
            renv.lock|renv)
                packages=$(_get_renv_packages)
                ;;
            DESCRIPTION|description)
                packages=$(_detect_r_packages_from_description)
                ;;
            *)
                [[ $quiet -eq 0 ]] && _flow_log_error "Unknown source: $source"
                return 1
                ;;
        esac
    else
        # Get from all sources
        packages=$(_list_r_packages_from_sources)
    fi

    if [[ -z "$packages" ]]; then
        [[ $quiet -eq 0 ]] && _flow_log_warning "No R packages found in configuration"
        return 2
    fi

    # Check which packages are missing
    local missing
    missing=$(_check_missing_r_packages <<< "$packages")

    if [[ -z "$missing" ]]; then
        [[ $quiet -eq 0 ]] && _flow_log_success "All R packages already installed"
        return 0
    fi

    # Convert to array for installation
    local missing_array=()
    while IFS= read -r pkg; do
        [[ -z "$pkg" ]] && continue
        missing_array+=("$pkg")
    done <<< "$missing"

    # Install missing packages
    local install_args=(${missing_array[@]})
    [[ $quiet -eq 1 ]] && install_args+=(--quiet)
    [[ $skip_confirm -eq 1 ]] && install_args+=(--yes)

    _install_r_packages "${install_args[@]}"
    return $?
}

# ============================================================================
# R PACKAGE STATUS
# ============================================================================

# =============================================================================
# Function: _show_r_package_status
# Purpose: Display a formatted report of R package installation status
# =============================================================================
# Arguments:
#   --json  - (optional) Output as JSON instead of human-readable format
#
# Returns:
#   0 - Always succeeds (even with no packages)
#
# Output:
#   stdout - Formatted status report:
#            Human-readable: Colored list with checkmarks and version info
#            JSON: Object with packages array, installed_count, missing_count
#
# Example:
#   # Human-readable output
#   _show_r_package_status
#
#   # JSON output for scripting
#   _show_r_package_status --json | jq '.missing_count'
#
# Notes:
#   - Aggregates packages from all sources via _list_r_packages_from_sources
#   - Shows version number for installed packages
#   - Uses FLOW_COLORS for terminal output
#   - JSON output includes: name, version (if installed), installed (boolean)
# =============================================================================
_show_r_package_status() {
    local output_json=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json) output_json=1; shift ;;
            *) shift ;;
        esac
    done

    # Get packages from all sources
    local packages
    packages=$(_list_r_packages_from_sources)

    if [[ -z "$packages" ]]; then
        if [[ $output_json -eq 1 ]]; then
            echo '{"packages": [], "missing": [], "installed": []}'
        else
            _flow_log_warning "No R packages found in configuration"
        fi
        return 0
    fi

    # Check installation status
    local installed=()
    local missing=()

    while IFS= read -r pkg; do
        [[ -z "$pkg" ]] && continue

        if _check_r_package_installed "$pkg"; then
            local version
            version=$(_get_r_package_version "$pkg")
            installed+=("$pkg|$version")
        else
            missing+=("$pkg")
        fi
    done <<< "$packages"

    if [[ $output_json -eq 1 ]]; then
        # JSON output
        echo "{"
        echo '  "packages": ['
        local first=1
        for item in "${installed[@]}"; do
            local pkg="${item%%|*}"
            local ver="${item##*|}"
            [[ $first -eq 0 ]] && echo ","
            first=0
            echo -n "    {\"name\": \"$pkg\", \"version\": \"$ver\", \"installed\": true}"
        done
        for pkg in "${missing[@]}"; do
            [[ $first -eq 0 ]] && echo ","
            first=0
            echo -n "    {\"name\": \"$pkg\", \"installed\": false}"
        done
        echo ""
        echo "  ],"
        echo "  \"installed_count\": ${#installed[@]},"
        echo "  \"missing_count\": ${#missing[@]}"
        echo "}"
    else
        # Human-readable output
        echo -e "${FLOW_COLORS[header]}R Package Status:${FLOW_COLORS[reset]}"
        echo ""

        if [[ ${#installed[@]} -gt 0 ]]; then
            echo -e "${FLOW_COLORS[success]}Installed:${FLOW_COLORS[reset]}"
            for item in "${installed[@]}"; do
                local pkg="${item%%|*}"
                local ver="${item##*|}"
                printf "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} %-20s %s\n" "$pkg" "${FLOW_COLORS[muted]}$ver${FLOW_COLORS[reset]}"
            done
            echo ""
        fi

        if [[ ${#missing[@]} -gt 0 ]]; then
            echo -e "${FLOW_COLORS[warning]}Missing:${FLOW_COLORS[reset]}"
            for pkg in "${missing[@]}"; do
                echo "  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} $pkg"
            done
        fi
    fi

    return 0
}
