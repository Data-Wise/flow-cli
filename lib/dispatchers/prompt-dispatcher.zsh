#!/bin/zsh
# prompt-dispatcher.zsh - Prompt Engine Manager
# Unified control over Powerlevel10k, Starship, and OhMyPosh
#
# Usage: prompt [subcommand]
#   status   - Show current engine and alternatives
#   toggle   - Switch to another engine (interactive)
#   starship - Force switch to Starship
#   p10k     - Force switch to Powerlevel10k
#   ohmyposh - Force switch to Oh My Posh
#   list     - List all available engines
#   help     - Display help
#
# Environment: FLOW_PROMPT_ENGINE (set to current engine name)

# ============================================================================
# Engine Registry - Data Structure
# ============================================================================
# Format: name:display_name:binary_path:config_file:description

# Register all available prompt engines
declare -gA PROMPT_ENGINES=(
    [powerlevel10k_name]="powerlevel10k"
    [powerlevel10k_display]="Powerlevel10k"
    [powerlevel10k_binary]="(antidote)"
    [powerlevel10k_config]="$HOME/.config/zsh/.p10k.zsh"
    [powerlevel10k_description]="Feature-rich, highly customizable"

    [starship_name]="starship"
    [starship_display]="Starship"
    [starship_binary]="starship"
    [starship_config]="$HOME/.config/starship.toml"
    [starship_description]="Minimal, fast Rust-based"

    [ohmyposh_name]="ohmyposh"
    [ohmyposh_display]="Oh My Posh"
    [ohmyposh_binary]="oh-my-posh"
    [ohmyposh_config]="$HOME/.config/ohmyposh/config.json"
    [ohmyposh_description]="Modular with extensive themes"
)

# List of all engine names (in order)
declare -ga PROMPT_ENGINE_NAMES=(powerlevel10k starship ohmyposh)

# ============================================================================
# Main Dispatcher
# ============================================================================

prompt() {
    case "${1:-help}" in
        status)
            _prompt_status
            ;;
        toggle)
            _prompt_toggle
            ;;
        starship)
            _prompt_switch "starship"
            ;;
        p10k)
            _prompt_switch "powerlevel10k"
            ;;
        ohmyposh)
            _prompt_switch "ohmyposh"
            ;;
        list)
            _prompt_list
            ;;
        setup-ohmyposh)
            _prompt_setup_ohmyposh
            ;;
        help|--help|-h)
            _prompt_help
            ;;
        *)
            _flow_log_error "Unknown command: $1"
            _prompt_help
            return 1
            ;;
    esac
}

# ============================================================================
# Core Functions
# ============================================================================

# _prompt_status - Display current engine and alternatives
_prompt_status() {
    local current=$(_prompt_get_current)

    _flow_log_info "Prompt Engines:"
    echo

    local engine
    for engine in "${PROMPT_ENGINE_NAMES[@]}"; do
        local display="${PROMPT_ENGINES[${engine}_display]}"
        local config="${PROMPT_ENGINES[${engine}_config]}"
        local desc="${PROMPT_ENGINES[${engine}_description]}"

        if [[ "$engine" == "$current" ]]; then
            echo "  ● ${display} (current)"
        else
            echo "  ○ ${display}"
        fi
        echo "    ${desc}"
        echo "    Config: ${config}"
        echo
    done

    echo "To switch: prompt toggle"
}

# _prompt_list - Show all engines with details
_prompt_list() {
    local current=$(_prompt_get_current)

    _flow_log_info "Available Prompt Engines:"
    echo

    # Header
    printf "%-18s %-10s %s\n" "name" "active" "config file"
    echo "─────────────────────────────────────────────────────────────"

    # Rows
    local engine
    for engine in "${PROMPT_ENGINE_NAMES[@]}"; do
        local display="${PROMPT_ENGINES[${engine}_display]}"
        local config="${PROMPT_ENGINES[${engine}_config]}"
        local engine_status="○"

        if [[ "$engine" == "$current" ]]; then
            engine_status="●"
        fi

        printf "%-18s %-10s %s\n" "$display" "$engine_status" "$config"
    done

    echo
    echo "Legend: ● = current, ○ = available"
}

# _prompt_help - Display help text
_prompt_help() {
    cat <<EOF
🎨 PROMPT DISPATCHER v5.7.0
   Manage multiple prompt engines: Powerlevel10k, Starship, OhMyPosh

USAGE:
   prompt [subcommand]

SUBCOMMANDS:
   status              Show current engine and alternatives
   toggle              Switch to another engine (interactive menu)
   starship            Force switch to Starship
   p10k                Force switch to Powerlevel10k
   ohmyposh            Force switch to Oh My Posh
   list                List all available engines with details
   help                Show this help

SETUP & CONFIGURATION:
   setup-ohmyposh      Interactive wizard for Oh My Posh configuration

EXAMPLES:
   prompt status               # See what's active
   prompt toggle               # Choose engine from menu
   prompt starship             # Go straight to Starship
   prompt list                 # See all engines
   prompt setup-ohmyposh       # Configure Oh My Posh

For more info:
   https://data-wise.github.io/flow-cli/dispatchers/prompt/

EOF
}

# ============================================================================
# Helper Functions
# ============================================================================

# _prompt_get_current - Get the currently active prompt engine
_prompt_get_current() {
    # Use FLOW_PROMPT_ENGINE environment variable
    local current="${FLOW_PROMPT_ENGINE:-powerlevel10k}"

    # Validate it's one of our engines
    if [[ ! " ${PROMPT_ENGINE_NAMES[@]} " =~ " ${current} " ]]; then
        echo "powerlevel10k"  # Default to p10k if invalid
    else
        echo "$current"
    fi
}

# _prompt_get_alternatives - Get list of non-current engines
_prompt_get_alternatives() {
    local current=$(_prompt_get_current)
    local engine

    for engine in "${PROMPT_ENGINE_NAMES[@]}"; do
        if [[ "$engine" != "$current" ]]; then
            echo "$engine"
        fi
    done
}

# _prompt_validate - Check if engine is installed and configured
_prompt_validate() {
    local engine="$1"

    case "$engine" in
        powerlevel10k)
            _prompt_validate_p10k
            ;;
        starship)
            _prompt_validate_starship
            ;;
        ohmyposh)
            _prompt_validate_ohmyposh
            ;;
        *)
            _flow_log_error "Unknown engine: $engine"
            return 1
            ;;
    esac
}

# _prompt_validate_p10k - Check Powerlevel10k installation
_prompt_validate_p10k() {
    # Check if plugin is in .zsh_plugins.txt
    if [[ ! -f "$HOME/.config/zsh/.zsh_plugins.txt" ]]; then
        _flow_log_error "Powerlevel10k plugin file not found"
        return 1
    fi

    if ! grep -q "romkatv/powerlevel10k" "$HOME/.config/zsh/.zsh_plugins.txt"; then
        _flow_log_error "Powerlevel10k plugin not installed"
        echo "Add to ~/.config/zsh/.zsh_plugins.txt:"
        echo "  romkatv/powerlevel10k"
        return 1
    fi

    # Check if config file exists
    if [[ ! -f "$HOME/.config/zsh/.p10k.zsh" ]]; then
        _flow_log_warn "P10k config missing at ~/.config/zsh/.p10k.zsh"
        return 1
    fi

    return 0
}

# _prompt_validate_starship - Check Starship installation
_prompt_validate_starship() {
    # Check if binary exists
    if ! command -v starship &>/dev/null; then
        _flow_log_error "Starship not found in PATH"
        echo "Install with: brew install starship"
        return 1
    fi

    # Check if config file exists
    if [[ ! -f "$HOME/.config/starship.toml" ]]; then
        _flow_log_warn "Starship config missing at ~/.config/starship.toml"
        return 1
    fi

    return 0
}

# _prompt_validate_ohmyposh - Check Oh My Posh installation
_prompt_validate_ohmyposh() {
    # Check if binary exists
    if ! command -v oh-my-posh &>/dev/null; then
        _flow_log_error "Oh My Posh not found in PATH"
        echo "Install with: brew install oh-my-posh"
        return 1
    fi

    # Check if config file exists
    if [[ ! -f "$HOME/.config/ohmyposh/config.json" ]]; then
        _flow_log_warn "OhMyPosh config missing at ~/.config/ohmyposh/config.json"
        return 1
    fi

    return 0
}

# _prompt_switch - Switch to a specific engine
_prompt_switch() {
    local target_engine="$1"

    if [[ -z "$target_engine" ]]; then
        _flow_log_error "No engine specified"
        return 1
    fi

    # Validate the target engine
    if ! _prompt_validate "$target_engine"; then
        return 1
    fi

    # Update the environment variable
    export FLOW_PROMPT_ENGINE="$target_engine"

    # Get display name
    local display_name="${PROMPT_ENGINES[${target_engine}_display]}"

    _flow_log_success "Switched to ${display_name}"

    # Note: In interactive shell, this would exec zsh -i
    # But for testing/non-interactive, we just set the variable
    # The .zshenv/.zshrc will pick it up on next shell

    # If in interactive shell, reload it
    if [[ -o interactive ]]; then
        echo "Reloading shell..."
        exec zsh -i
    fi
}

# _prompt_setup_ohmyposh - Interactive setup wizard for Oh My Posh
_prompt_setup_ohmyposh() {
    _flow_log_info "Oh My Posh Configuration Wizard"
    echo

    # Check if Oh My Posh is installed
    if ! command -v oh-my-posh &>/dev/null; then
        _flow_log_error "Oh My Posh not found in PATH"
        echo "Install with: brew install oh-my-posh"
        return 1
    fi

    # Create config directory
    local config_dir="$HOME/.config/ohmyposh"
    if [[ ! -d "$config_dir" ]]; then
        mkdir -p "$config_dir"
        _flow_log_success "Created $config_dir"
    fi

    local config_file="$config_dir/config.json"

    # Check if config already exists
    if [[ -f "$config_file" ]]; then
        _flow_log_warn "Configuration already exists at $config_file"
        echo "Would you like to overwrite it? (y/n)"
        read -r response
        if [[ "$response" != "y" ]]; then
            echo "Keeping existing configuration"
            return 0
        fi
    fi

    # Create default configuration
    cat > "$config_file" <<'EOF'
{
  "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
  "version": 3,
  "terminal_background": "#0B1022",
  "accent_color": "#FFB86C",
  "profiles": [
    {
      "name": "default",
      "template": " {{ if .Code }}{{ else }}{{ end }}{{ .Shell }} ",
      "segments": [
        {
          "type": "session",
          "style": "diamond",
          "leading_diamond": "\ue0b6",
          "trailing_diamond": "\ue0b0",
          "template": " {{ .UserName }} ",
          "background": "#0077be",
          "foreground": "#ffffff"
        },
        {
          "type": "path",
          "style": "diamond",
          "leading_diamond": "\ue0b0",
          "trailing_diamond": "\ue0b0",
          "template": " {{ path .Path .Location }} ",
          "background": "#00a4ef",
          "foreground": "#ffffff",
          "properties": {
            "style": "folder"
          }
        },
        {
          "type": "git",
          "style": "diamond",
          "leading_diamond": "\ue0b0",
          "trailing_diamond": "\ue0b0",
          "template": " {{ .Branch }} ",
          "background": "#009900",
          "foreground": "#ffffff"
        }
      ]
    }
  ]
}
EOF

    _flow_log_success "Configuration created at $config_file"
    echo
    echo "Next steps:"
    echo "  1. Customize your config: nano $config_file"
    echo "  2. Validate: oh-my-posh config"
    echo "  3. Switch to OhMyPosh: prompt ohmyposh"
}

# _prompt_toggle - Interactive menu to switch engines
_prompt_toggle() {
    local current=$(_prompt_get_current)
    local alternatives=($(_prompt_get_alternatives))

    # If no alternatives, can't toggle
    if [[ ${#alternatives[@]} -eq 0 ]]; then
        _flow_log_error "No alternative engines available"
        return 1
    fi

    # Show interactive menu
    echo "Which prompt engine would you like to use?"
    echo

    local choice
    local REPLY

    # Use select for interactive menu
    select choice in "${alternatives[@]}"; do
        # Check if user provided valid selection
        if [[ -n "$choice" ]]; then
            # Validate the selected engine before switching
            if _prompt_validate "$choice" 2>/dev/null; then
                _prompt_switch "$choice"
                return 0
            else
                # Engine validation failed, but still try to switch
                # (might be config missing which is recoverable)
                _flow_log_warn "Engine may not be fully configured"
                _prompt_switch "$choice"
                return 0
            fi
        else
            _flow_log_error "Invalid selection"
            return 1
        fi
    done
}

# ============================================================================
# End of prompt-dispatcher.zsh
# ============================================================================
