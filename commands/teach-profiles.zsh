# commands/teach-profiles.zsh - Profile Management Command
# Quarto profile management for teaching workflow
#
# Commands:
#   teach profiles list              - List available profiles
#   teach profiles show <name>       - Show profile details
#   teach profiles set <name>        - Switch to a profile
#   teach profiles create <name>     - Create new profile from template

# Source profile helpers if not already loaded
if [[ -z "$_FLOW_PROFILE_HELPERS_LOADED" ]]; then
    local helpers_path="${0:A:h:h}/lib/profile-helpers.zsh"
    [[ -f "$helpers_path" ]] && source "$helpers_path"
    typeset -g _FLOW_PROFILE_HELPERS_LOADED=1
fi

# ============================================================================
# MAIN COMMAND DISPATCHER
# ============================================================================

_teach_profiles() {
    local cmd="${1:-list}"
    shift

    case "$cmd" in
        list|ls|l)
            _teach_profiles_list "$@"
            ;;
        show|info|i)
            _teach_profiles_show "$@"
            ;;
        set|switch|use)
            _teach_profiles_set "$@"
            ;;
        create|new|add)
            _teach_profiles_create "$@"
            ;;
        current)
            _teach_profiles_current "$@"
            ;;
        help|--help|-h)
            _teach_profiles_help
            ;;
        *)
            _flow_log_error "Unknown profiles command: $cmd"
            echo ""
            _teach_profiles_help
            return 1
            ;;
    esac
}

# ============================================================================
# COMMAND IMPLEMENTATIONS
# ============================================================================

# List all available profiles
_teach_profiles_list() {
    local json=0
    local quiet=0

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                _teach_profiles_list_help
                return 0
                ;;
            --json)
                json=1
                shift
                ;;
            --quiet|-q)
                quiet=1
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    local args=()
    [[ $json -eq 1 ]] && args+=(--json)
    [[ $quiet -eq 1 ]] && args+=(--quiet)

    _list_profiles "${args[@]}"
}

# Show details for a specific profile
_teach_profiles_show() {
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        _teach_profiles_show_help
        return 0
    fi

    local profile_name="$1"

    if [[ -z "$profile_name" ]]; then
        _flow_log_error "Profile name required"
        echo ""
        echo -e "${FLOW_COLORS[muted]}Usage: ${FLOW_COLORS[cmd]}teach profiles show <name>${FLOW_COLORS[reset]}"
        return 1
    fi

    _show_profile_info "$profile_name"
}

# Set (switch to) a profile
_teach_profiles_set() {
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        _teach_profiles_set_help
        return 0
    fi

    local profile_name="$1"

    if [[ -z "$profile_name" ]]; then
        _flow_log_error "Profile name required"
        echo ""
        echo -e "${FLOW_COLORS[muted]}Usage: ${FLOW_COLORS[cmd]}teach profiles set <name>${FLOW_COLORS[reset]}"
        return 1
    fi

    _switch_profile "$profile_name"
}

# Create a new profile
_teach_profiles_create() {
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        _teach_profiles_create_help
        return 0
    fi

    local profile_name="$1"
    local template="${2:-default}"

    if [[ -z "$profile_name" ]]; then
        _flow_log_error "Profile name required"
        echo ""
        echo -e "${FLOW_COLORS[muted]}Usage: ${FLOW_COLORS[cmd]}teach profiles create <name> [template]${FLOW_COLORS[reset]}"
        echo -e "${FLOW_COLORS[muted]}Templates: default, draft, print, slides${FLOW_COLORS[reset]}"
        return 1
    fi

    _create_profile "$profile_name" "$template"
}

# Show current profile
_teach_profiles_current() {
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        echo -e "${FLOW_COLORS[header]}teach profiles current${FLOW_COLORS[reset]}"
        echo ""
        echo "Show the currently active Quarto profile."
        echo ""
        echo -e "${FLOW_COLORS[muted]}USAGE:${FLOW_COLORS[reset]}"
        echo -e "  ${FLOW_COLORS[cmd]}teach profiles current${FLOW_COLORS[reset]}"
        return 0
    fi

    local current
    current=$(_get_current_profile)

    echo -e "${FLOW_COLORS[header]}Current Profile:${FLOW_COLORS[reset]} ${FLOW_COLORS[success]}$current${FLOW_COLORS[reset]}"

    # Check if profile is explicitly set
    if [[ -n "$QUARTO_PROFILE" ]]; then
        echo -e "${FLOW_COLORS[muted]}Source: QUARTO_PROFILE environment variable${FLOW_COLORS[reset]}"
    elif [[ -f ".flow/teaching.yml" ]]; then
        local yml_profile
        yml_profile=$(yq eval '.quarto.profile // ""' ".flow/teaching.yml" 2>/dev/null)
        if [[ -n "$yml_profile" ]]; then
            echo -e "${FLOW_COLORS[muted]}Source: .flow/teaching.yml${FLOW_COLORS[reset]}"
        else
            echo -e "${FLOW_COLORS[muted]}Source: default (not explicitly set)${FLOW_COLORS[reset]}"
        fi
    else
        echo -e "${FLOW_COLORS[muted]}Source: default (not explicitly set)${FLOW_COLORS[reset]}"
    fi
}

# ============================================================================
# HELP FUNCTIONS
# ============================================================================

_teach_profiles_help() {
    cat << 'EOF'
╭──────────────────────────────────────────────────────────────────────────╮
│                      TEACH PROFILES - Quarto Profiles                    │
╰──────────────────────────────────────────────────────────────────────────╯

Manage Quarto profiles for different rendering contexts and outputs.

COMMANDS:
  list              List all available profiles
  show <name>       Show detailed info for a profile
  set <name>        Switch to a different profile
  create <name>     Create a new profile from template
  current           Show currently active profile

USAGE:
  teach profiles list [--json] [--quiet]
  teach profiles show <name>
  teach profiles set <name>
  teach profiles create <name> [template]
  teach profiles current

TEMPLATES:
  default           Standard course website (HTML)
  draft             Draft content (unpublished, freeze disabled)
  print             PDF handout generation
  slides            Reveal.js presentations

EXAMPLES:
  # List all profiles
  teach profiles list

  # Show details for draft profile
  teach profiles show draft

  # Switch to draft profile
  teach profiles set draft

  # Create a custom profile for slides
  teach profiles create lecture-slides slides

  # Check current profile
  teach profiles current

PROFILE STRUCTURE:
  Profiles are defined in _quarto.yml under the 'profile:' key:

  profile:
    default:
      format:
        html:
          theme: cosmo
    draft:
      execute:
        freeze: false

ENVIRONMENT VARIABLE:
  Set QUARTO_PROFILE to activate a profile:
    export QUARTO_PROFILE="draft"

  This can be added to .zshrc or set per-session.

SEE ALSO:
  teach doctor       Check project health including profile validation
  teach init         Initialize teaching project with profile setup

EOF
}

_teach_profiles_list_help() {
    cat << 'EOF'
teach profiles list - List Available Profiles

USAGE:
  teach profiles list [--json] [--quiet]

FLAGS:
  --json        Output as JSON
  --quiet, -q   Only profile names (no descriptions)

DESCRIPTION:
  Lists all Quarto profiles defined in _quarto.yml with descriptions
  and indicates which profile is currently active.

EXAMPLES:
  # Human-readable list
  teach profiles list

  # JSON output for scripting
  teach profiles list --json

  # Just the names
  teach profiles list --quiet

OUTPUT FORMAT:
  Available Quarto Profiles:
    ▸ default          Standard course website
    • draft            Draft content (unpublished)
    • print            PDF handout generation

  Current Profile: default

EOF
}

_teach_profiles_show_help() {
    cat << 'EOF'
teach profiles show - Show Profile Details

USAGE:
  teach profiles show <name>

ARGUMENTS:
  <name>        Name of profile to show

DESCRIPTION:
  Displays detailed configuration for a specific Quarto profile,
  including format settings, execution options, and output configuration.

EXAMPLES:
  # Show draft profile configuration
  teach profiles show draft

  # Show custom profile
  teach profiles show lecture-slides

OUTPUT FORMAT:
  Profile: draft (active)
  Description: Draft content (unpublished)

  Configuration:
    format:
      html:
        theme: cosmo
    execute:
      freeze: false

EOF
}

_teach_profiles_set_help() {
    cat << 'EOF'
teach profiles set - Switch to a Profile

USAGE:
  teach profiles set <name>

ARGUMENTS:
  <name>        Name of profile to activate

DESCRIPTION:
  Switches to a different Quarto profile by:
    1. Updating .flow/teaching.yml (if exists)
    2. Setting QUARTO_PROFILE environment variable for current session
    3. Validating profile exists in _quarto.yml

  To persist across sessions, add to shell configuration:
    export QUARTO_PROFILE="<name>"

EXAMPLES:
  # Switch to draft mode
  teach profiles set draft

  # Switch to print mode for handouts
  teach profiles set print

  # Switch back to default
  teach profiles set default

EFFECTS:
  - Quarto commands will use the specified profile
  - Different formats/themes/settings will be applied
  - teach deploy will respect the active profile

EOF
}

_teach_profiles_create_help() {
    cat << 'EOF'
teach profiles create - Create New Profile

USAGE:
  teach profiles create <name> [template]

ARGUMENTS:
  <name>        Name for the new profile
  [template]    Base template (default: default)

TEMPLATES:
  default       Standard HTML website
  draft         Draft mode (freeze disabled, hidden content)
  print         PDF generation for handouts
  slides        Reveal.js presentation format

DESCRIPTION:
  Creates a new Quarto profile in _quarto.yml based on a template.
  The new profile can then be customized by editing _quarto.yml.

EXAMPLES:
  # Create profile from default template
  teach profiles create midterm-review

  # Create profile for slides
  teach profiles create lecture-slides slides

  # Create profile for print handouts
  teach profiles create handouts print

WORKFLOW:
  1. Create profile: teach profiles create <name> <template>
  2. Edit _quarto.yml to customize the profile
  3. Activate profile: teach profiles set <name>
  4. Render with profile: quarto render

EOF
}
