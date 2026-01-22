# lib/profile-helpers.zsh - Quarto Profile Management
# Provides profile detection, switching, validation, and creation
#
# Functions:
#   _detect_quarto_profiles()    - Parse _quarto.yml for profile definitions
#   _get_profile_description()   - Get description for a profile
#   _get_profile_config()        - Get YAML configuration for a profile
#   _list_profiles()             - List available profiles with descriptions
#   _get_current_profile()       - Detect active profile from environment
#   _switch_profile()            - Switch to a different profile
#   _validate_profile()          - Validate profile configuration
#   _create_profile()            - Create new profile from template
#   _show_profile_info()         - Show detailed information about a profile

typeset -g _FLOW_PROFILE_HELPERS_LOADED=1

# ============================================================================
# PROFILE DETECTION
# ============================================================================

# =============================================================================
# Function: _detect_quarto_profiles
# Purpose: Parse _quarto.yml to extract all defined Quarto profile names
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Profiles found and output
#   1 - No _quarto.yml found or yq not available
#   2 - No profiles defined in _quarto.yml
#
# Output:
#   stdout - Profile names, one per line
#
# Example:
#   profiles=$(_detect_quarto_profiles)
#   echo "Available: $profiles"
#
# Notes:
#   - Requires yq for YAML parsing
#   - Looks for profile: section in _quarto.yml
#   - Each key under profile: is a profile name
# =============================================================================
_detect_quarto_profiles() {
    local quarto_yml="_quarto.yml"

    if [[ ! -f "$quarto_yml" ]]; then
        return 1
    fi

    # Check if yq is available
    if ! command -v yq &>/dev/null; then
        _flow_log_error "yq not found - required for profile detection"
        return 1
    fi

    # Extract profile names from _quarto.yml
    # Profiles can be defined as:
    #   profile:
    #     default:
    #       ...
    #     draft:
    #       ...
    local profiles
    profiles=$(yq eval '.profile | keys | .[]' "$quarto_yml" 2>/dev/null)

    if [[ -z "$profiles" ]]; then
        return 2
    fi

    echo "$profiles"
    return 0
}

# =============================================================================
# Function: _get_profile_description
# Purpose: Retrieve the description or title for a specific Quarto profile
# =============================================================================
# Arguments:
#   $1 - (required) Profile name to query
#
# Returns:
#   0 - Success (even if description is empty)
#   1 - No _quarto.yml found
#
# Output:
#   stdout - Description string (or empty if none defined)
#
# Example:
#   desc=$(_get_profile_description "draft")
#   [[ -n "$desc" ]] && echo "Draft: $desc"
#
# Notes:
#   - Looks for .profile.<name>.description first
#   - Falls back to .profile.<name>.title if no description
#   - Returns empty string if neither exists
# =============================================================================
_get_profile_description() {
    local profile_name="$1"
    local quarto_yml="_quarto.yml"

    if [[ ! -f "$quarto_yml" ]]; then
        return 1
    fi

    # Try to extract description from profile metadata
    # Look for: profile.<name>.description or profile.<name>.title
    local desc
    desc=$(yq eval ".profile.${profile_name}.description // .profile.${profile_name}.title // \"\"" "$quarto_yml" 2>/dev/null)

    echo "$desc"
}

# =============================================================================
# Function: _get_profile_config
# Purpose: Retrieve the complete YAML configuration for a specific profile
# =============================================================================
# Arguments:
#   $1 - (required) Profile name to query
#
# Returns:
#   0 - Success
#   1 - No _quarto.yml found
#
# Output:
#   stdout - YAML structure of the profile configuration
#
# Example:
#   config=$(_get_profile_config "slides")
#   echo "$config"  # Shows format, theme, etc.
#
# Notes:
#   - Returns the entire profile subtree from _quarto.yml
#   - Output is valid YAML that can be piped to yq
#   - Returns null if profile doesn't exist
# =============================================================================
_get_profile_config() {
    local profile_name="$1"
    local quarto_yml="_quarto.yml"

    if [[ ! -f "$quarto_yml" ]]; then
        return 1
    fi

    yq eval ".profile.${profile_name}" "$quarto_yml" 2>/dev/null
}

# ============================================================================
# PROFILE LISTING
# ============================================================================

# =============================================================================
# Function: _list_profiles
# Purpose: Display all available Quarto profiles with descriptions and status
# =============================================================================
# Arguments:
#   --json    - (optional) Output as JSON instead of human-readable format
#   --quiet, -q - (optional) Output only profile names, one per line
#
# Returns:
#   0 - Success
#   1 - No _quarto.yml found
#   2 - No profiles defined
#
# Output:
#   stdout - Formatted profile list:
#            Human-readable: Colored list with current profile indicator
#            Quiet: Plain profile names
#            JSON: Object with profiles array and current profile
#
# Example:
#   # Interactive display
#   _list_profiles
#
#   # Get just names for scripting
#   _list_profiles --quiet
#
#   # JSON for automation
#   _list_profiles --json | jq '.current'
#
# Notes:
#   - Highlights currently active profile with arrow indicator
#   - Shows description if available
#   - Uses FLOW_COLORS for terminal output
# =============================================================================
_list_profiles() {
    local output_json=0
    local quiet=0

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json) output_json=1; shift ;;
            --quiet|-q) quiet=1; shift ;;
            *) shift ;;
        esac
    done

    local profiles
    profiles=$(_detect_quarto_profiles)
    local ret=$?

    if [[ $ret -eq 1 ]]; then
        [[ $quiet -eq 0 ]] && _flow_log_error "No _quarto.yml found in current directory"
        return 1
    elif [[ $ret -eq 2 ]]; then
        [[ $quiet -eq 0 ]] && _flow_log_warning "No profiles defined in _quarto.yml"
        return 2
    fi

    if [[ $quiet -eq 1 ]]; then
        echo "$profiles"
        return 0
    fi

    local current_profile
    current_profile=$(_get_current_profile)

    if [[ $output_json -eq 1 ]]; then
        # JSON output
        echo "{"
        echo '  "profiles": ['
        local first=1
        while IFS= read -r profile; do
            [[ -z "$profile" ]] && continue
            local desc
            desc=$(_get_profile_description "$profile")
            local is_current=false
            [[ "$profile" == "$current_profile" ]] && is_current=true

            [[ $first -eq 0 ]] && echo ","
            first=0

            echo -n "    {\"name\": \"$profile\", \"description\": \"$desc\", \"current\": $is_current}"
            echo -n "}"
        done <<< "$profiles"
        echo ""
        echo "  ],"
        echo "  \"current\": \"$current_profile\""
        echo "}"
    else
        # Human-readable output
        echo -e "${FLOW_COLORS[header]}Available Quarto Profiles:${FLOW_COLORS[reset]}"

        while IFS= read -r profile; do
            [[ -z "$profile" ]] && continue

            local desc
            desc=$(_get_profile_description "$profile")

            local marker="  •"
            if [[ "$profile" == "$current_profile" ]]; then
                marker="${FLOW_COLORS[success]}  ▸${FLOW_COLORS[reset]}"
            fi

            if [[ -n "$desc" ]]; then
                printf "%b %-15s %s\n" "$marker" "$profile" "${FLOW_COLORS[muted]}$desc${FLOW_COLORS[reset]}"
            else
                printf "%b %s\n" "$marker" "$profile"
            fi
        done <<< "$profiles"

        if [[ -n "$current_profile" ]]; then
            echo ""
            echo -e "${FLOW_COLORS[muted]}Current Profile: ${FLOW_COLORS[success]}$current_profile${FLOW_COLORS[reset]}"
        fi
    fi
}

# ============================================================================
# CURRENT PROFILE DETECTION
# ============================================================================

# =============================================================================
# Function: _get_current_profile
# Purpose: Determine the currently active Quarto profile
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Current profile name (defaults to "default" if none set)
#
# Example:
#   current=$(_get_current_profile)
#   echo "Using profile: $current"
#
# Notes:
#   - Priority order: QUARTO_PROFILE env var > teaching.yml setting > "default"
#   - teaching.yml is checked at .flow/teaching.yml
#   - Always returns a value (never empty)
# =============================================================================
_get_current_profile() {
    # Check environment variable first
    if [[ -n "$QUARTO_PROFILE" ]]; then
        echo "$QUARTO_PROFILE"
        return 0
    fi

    # Check teaching.yml for profile setting
    if [[ -f ".flow/teaching.yml" ]]; then
        local profile
        profile=$(yq eval '.quarto.profile // ""' ".flow/teaching.yml" 2>/dev/null)
        if [[ -n "$profile" ]]; then
            echo "$profile"
            return 0
        fi
    fi

    # Default to "default"
    echo "default"
}

# ============================================================================
# PROFILE SWITCHING
# ============================================================================

# =============================================================================
# Function: _switch_profile
# Purpose: Switch the active Quarto profile for the current project
# =============================================================================
# Arguments:
#   $1 - (required) Profile name to switch to
#
# Returns:
#   0 - Successfully switched
#   1 - Invalid profile name or profile doesn't exist
#   2 - Validation failed
#
# Output:
#   stdout - Success message and persistence instructions
#
# Example:
#   _switch_profile "draft"
#   # Output: Switched to profile: draft
#   # Also sets QUARTO_PROFILE environment variable
#
# Notes:
#   - Updates .flow/teaching.yml if it exists
#   - Sets QUARTO_PROFILE environment variable for current session
#   - Provides instructions for persisting across sessions
#   - Validates profile exists before switching
# =============================================================================
_switch_profile() {
    local profile_name="$1"

    if [[ -z "$profile_name" ]]; then
        _flow_log_error "Profile name required"
        return 1
    fi

    # Validate profile exists
    if ! _validate_profile "$profile_name" --quiet; then
        _flow_log_error "Invalid profile: $profile_name"
        return 1
    fi

    # Update teaching.yml if it exists
    if [[ -f ".flow/teaching.yml" ]]; then
        # Use yq to update the profile setting
        yq eval ".quarto.profile = \"$profile_name\"" -i ".flow/teaching.yml" 2>/dev/null
        _flow_log_success "Updated .flow/teaching.yml"
    fi

    # Set environment variable for current session
    export QUARTO_PROFILE="$profile_name"

    _flow_log_success "Switched to profile: $profile_name"
    echo ""
    echo -e "${FLOW_COLORS[muted]}To persist for new sessions, add to your shell config:${FLOW_COLORS[reset]}"
    echo -e "${FLOW_COLORS[cmd]}  export QUARTO_PROFILE=\"$profile_name\"${FLOW_COLORS[reset]}"

    return 0
}

# ============================================================================
# PROFILE VALIDATION
# ============================================================================

# =============================================================================
# Function: _validate_profile
# Purpose: Verify that a profile exists in the project's _quarto.yml
# =============================================================================
# Arguments:
#   $1 - (required) Profile name to validate
#   --quiet, -q - (optional) Suppress output messages
#
# Returns:
#   0 - Profile is valid (exists in _quarto.yml)
#   1 - Profile is invalid (doesn't exist or name empty)
#
# Output:
#   stdout - Success/error message (unless --quiet)
#
# Example:
#   if _validate_profile "slides" --quiet; then
#       echo "slides profile exists"
#   fi
#
# Notes:
#   - Checks against profiles defined in _quarto.yml
#   - Case-sensitive matching
#   - Use --quiet for conditional checks
# =============================================================================
_validate_profile() {
    local profile_name="$1"
    local quiet=0

    shift
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --quiet|-q) quiet=1; shift ;;
            *) shift ;;
        esac
    done

    if [[ -z "$profile_name" ]]; then
        [[ $quiet -eq 0 ]] && _flow_log_error "Profile name required"
        return 1
    fi

    # Check if profile exists in _quarto.yml
    local profiles
    profiles=$(_detect_quarto_profiles)

    if ! echo "$profiles" | grep -q "^${profile_name}$"; then
        [[ $quiet -eq 0 ]] && _flow_log_error "Profile '$profile_name' not found in _quarto.yml"
        return 1
    fi

    # Profile exists
    [[ $quiet -eq 0 ]] && _flow_log_success "Profile '$profile_name' is valid"
    return 0
}

# ============================================================================
# PROFILE CREATION
# ============================================================================

# =============================================================================
# Function: _create_profile
# Purpose: Create a new Quarto profile from a predefined template
# =============================================================================
# Arguments:
#   $1 - (required) Profile name to create
#   $2 - (optional) Template name [default: default]
#        Available templates: default, draft, print, slides
#
# Returns:
#   0 - Profile created successfully
#   1 - Error (no name, no _quarto.yml, profile exists, unknown template)
#
# Output:
#   stdout - Success message and usage instructions
#
# Example:
#   # Create with default template
#   _create_profile "review"
#
#   # Create slides profile
#   _create_profile "presentation" "slides"
#
# Notes:
#   - Templates define format and common settings:
#     - default: HTML with cosmo theme and TOC
#     - draft: HTML with freeze disabled, echo off
#     - print: PDF with article class and margins
#     - slides: RevealJS with simple theme and transitions
#   - Modifies _quarto.yml in place using yq
#   - Creates profile: section if it doesn't exist
# =============================================================================
_create_profile() {
    local profile_name="$1"
    local template="${2:-default}"

    if [[ -z "$profile_name" ]]; then
        _flow_log_error "Profile name required"
        return 1
    fi

    if [[ ! -f "_quarto.yml" ]]; then
        _flow_log_error "No _quarto.yml found in current directory"
        return 1
    fi

    # Check if profile already exists
    if _validate_profile "$profile_name" --quiet 2>/dev/null; then
        _flow_log_error "Profile '$profile_name' already exists"
        return 1
    fi

    # Define template configurations
    local template_yaml
    case "$template" in
        default)
            template_yaml="format:
  html:
    theme: cosmo
    toc: true"
            ;;
        draft)
            template_yaml="format:
  html:
    theme: cosmo
    toc: true
execute:
  freeze: false
  echo: false"
            ;;
        print)
            template_yaml="format:
  pdf:
    documentclass: article
    margin-left: 1in
    margin-right: 1in"
            ;;
        slides)
            template_yaml="format:
  revealjs:
    theme: simple
    slide-number: true
    transition: fade"
            ;;
        *)
            _flow_log_error "Unknown template: $template"
            echo "Available templates: default, draft, print, slides"
            return 1
            ;;
    esac

    # Create profile in _quarto.yml
    # We'll add the profile to the existing file
    _flow_log_info "Creating profile '$profile_name' from template '$template'..."

    # Check if profile: section exists
    if ! yq eval '.profile' "_quarto.yml" &>/dev/null; then
        # Add profile section
        yq eval ".profile = {}" -i "_quarto.yml"
    fi

    # Add the new profile
    # Create a temporary file with the template
    local temp_file
    temp_file=$(mktemp)
    echo "$template_yaml" > "$temp_file"

    # Merge into _quarto.yml
    yq eval ".profile.${profile_name} = load(\"$temp_file\")" -i "_quarto.yml"
    rm "$temp_file"

    _flow_log_success "Created profile: $profile_name"
    echo ""
    echo -e "${FLOW_COLORS[muted]}To use this profile:${FLOW_COLORS[reset]}"
    echo -e "${FLOW_COLORS[cmd]}  teach profiles set $profile_name${FLOW_COLORS[reset]}"

    return 0
}

# ============================================================================
# PROFILE INFORMATION
# ============================================================================

# =============================================================================
# Function: _show_profile_info
# Purpose: Display detailed information about a specific Quarto profile
# =============================================================================
# Arguments:
#   $1 - (required) Profile name to display
#
# Returns:
#   0 - Profile info displayed successfully
#   1 - Profile name missing or profile doesn't exist
#
# Output:
#   stdout - Formatted profile information including:
#            - Profile name with active indicator
#            - Description (if available)
#            - Full YAML configuration (indented)
#
# Example:
#   _show_profile_info "slides"
#   # Output:
#   # Profile: slides (active)
#   # Description: Presentation format
#   #
#   # Configuration:
#   #   format:
#   #     revealjs:
#   #       theme: simple
#
# Notes:
#   - Shows "(active)" indicator if profile is currently selected
#   - Configuration is pretty-printed with 2-space indent
#   - Uses FLOW_COLORS for terminal output
# =============================================================================
_show_profile_info() {
    local profile_name="$1"

    if [[ -z "$profile_name" ]]; then
        _flow_log_error "Profile name required"
        return 1
    fi

    if ! _validate_profile "$profile_name" --quiet; then
        return 1
    fi

    local desc
    desc=$(_get_profile_description "$profile_name")

    local current_profile
    current_profile=$(_get_current_profile)

    local is_current=""
    [[ "$profile_name" == "$current_profile" ]] && is_current=" ${FLOW_COLORS[success]}(active)${FLOW_COLORS[reset]}"

    echo -e "${FLOW_COLORS[header]}Profile: ${FLOW_COLORS[cmd]}$profile_name${is_current}${FLOW_COLORS[reset]}"

    if [[ -n "$desc" ]]; then
        echo -e "${FLOW_COLORS[muted]}Description: $desc${FLOW_COLORS[reset]}"
    fi

    echo ""
    echo -e "${FLOW_COLORS[header]}Configuration:${FLOW_COLORS[reset]}"

    # Get and format configuration
    local config
    config=$(_get_profile_config "$profile_name")

    # Pretty print the YAML
    echo "$config" | sed 's/^/  /'

    return 0
}
