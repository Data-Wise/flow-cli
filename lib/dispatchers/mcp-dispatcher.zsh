#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# MCP Server Management Dispatcher
# ══════════════════════════════════════════════════════════════════════════════
#
# File:         ~/.config/zsh/functions/mcp-dispatcher.zsh
# Version:      2.0 (Dispatcher Pattern)
# Date:         2025-12-19
# Pattern:      mcp + keyword + options
#
# Usage:        mcp <action> [args]
#
# Examples:
#   mcp                  # List all servers (default)
#   mcp list             # or: mcp ls, mcp l
#   mcp cd docling       # or: mcp goto docling, mcp g docling
#   mcp test shell       # or: mcp t shell
#   mcp pick             # or: mcp p (interactive picker)
#   mcp help             # or: mcp h
#
# ══════════════════════════════════════════════════════════════════════════════

# === Configuration ===
MCP_SERVERS_DIR="${HOME}/projects/dev-tools/mcp-servers"
MCP_DESKTOP_CONFIG="${HOME}/.claude/settings.json"
MCP_BROWSER_CONFIG="${HOME}/projects/dev-tools/claude-mcp/MCP_SERVER_CONFIG.json"

# === Color Definitions ===
_C_BOLD='\033[1m'
_C_DIM='\033[2m'
_C_NC='\033[0m'
_C_GREEN='\033[32m'
_C_YELLOW='\033[33m'
_C_BLUE='\033[34m'
_C_CYAN='\033[36m'
_C_MAGENTA='\033[35m'
_C_RED='\033[31m'

# === Internal Functions ===

# List all MCP servers with status
_mcp_list() {
    if [[ ! -d "$MCP_SERVERS_DIR" ]]; then
        echo "mcp: MCP servers directory not found: $MCP_SERVERS_DIR" >&2
        echo "Run 'mcp help' for usage" >&2
        return 1
    fi

    local server_count=0
    for server in "$MCP_SERVERS_DIR"/*(/N); do
        local name=$(basename "$server")
        ((server_count++))

        echo ""
        echo "${fg[cyan]}● $name${reset_color}"

        # Show location
        echo "  ${fg[blue]}📁${reset_color} $server"

        # Check Desktop/CLI configuration
        if [[ -f "$MCP_DESKTOP_CONFIG" ]] && grep -q "\"$name\"" "$MCP_DESKTOP_CONFIG" 2>/dev/null; then
            echo "  ${fg[green]}✓${reset_color} Desktop/CLI configured"
        else
            echo "  ${fg[yellow]}○${reset_color} Desktop/CLI not configured"
        fi

        # Check Browser configuration
        if [[ -f "$MCP_BROWSER_CONFIG" ]] && grep -q "\"$name\"" "$MCP_BROWSER_CONFIG" 2>/dev/null; then
            echo "  ${fg[green]}✓${reset_color} Browser configured"
        else
            echo "  ${fg[yellow]}○${reset_color} Browser not configured"
        fi

        # Show README if exists
        if [[ -f "$server/README.md" ]]; then
            echo "  ${fg[blue]}📖${reset_color} README available"
        fi
    done

    if [[ $server_count -eq 0 ]]; then
        echo "mcp: no MCP servers found in $MCP_SERVERS_DIR" >&2
    else
        echo ""
        echo "Total: $server_count server(s)"
    fi

    echo ""
    echo "${fg[blue]}ℹ${reset_color}  Quick access: ${fg[cyan]}cd ~/mcp-servers/<name>${reset_color}"
    echo "${fg[blue]}ℹ${reset_color}  Interactive:  ${fg[cyan]}mcp pick${reset_color}"
}

# Navigate to MCP servers directory or specific server
_mcp_cd() {
    local server="$1"

    if [[ -z "$server" ]]; then
        # No argument - go to main directory
        cd "$MCP_SERVERS_DIR" || {
            echo "mcp: cannot navigate to $MCP_SERVERS_DIR" >&2
            echo "Run 'mcp help' for usage" >&2
            return 1
        }
        echo "In MCP servers directory"
        ls -1
    else
        # Navigate to specific server
        if [[ -d "$MCP_SERVERS_DIR/$server" ]]; then
            cd "$MCP_SERVERS_DIR/$server" || {
                echo "mcp: cannot navigate to $server" >&2
                echo "Run 'mcp help' for usage" >&2
                return 1
            }
            echo "In $server"
        else
            echo "mcp: server not found: $server" >&2
            echo ""
            echo "Available servers:" >&2
            ls -1 "$MCP_SERVERS_DIR" 2>/dev/null || echo "  (none)" >&2
            return 1
        fi
    fi
}

# Edit MCP server in $EDITOR
_mcp_edit() {
    local server="$1"

    if [[ -z "$server" ]]; then
        echo "mcp edit <server-name>" >&2
        echo ""
        echo "Available servers:" >&2
        ls -1 "$MCP_SERVERS_DIR" 2>/dev/null || echo "  (none)" >&2
        return 1
    fi

    if [[ ! -d "$MCP_SERVERS_DIR/$server" ]]; then
        echo "mcp: server not found: $server" >&2
        echo "Run 'mcp help' for usage" >&2
        return 1
    fi

    local editor="${EDITOR:-code}"
    echo "Opening $server in $editor..."
    $editor "$MCP_SERVERS_DIR/$server"
}

# View MCP server README
_mcp_readme() {
    local server="$1"
    local pager="${PAGER:-less}"

    if [[ -z "$server" ]]; then
        # Show main README if exists
        if [[ -f "$MCP_SERVERS_DIR/README.md" ]]; then
            $pager "$MCP_SERVERS_DIR/README.md"
        else
            echo "mcp: main README.md not found" >&2
            echo "Try: mcp readme <server-name>" >&2
        fi
    else
        # Show server README
        if [[ -f "$MCP_SERVERS_DIR/$server/README.md" ]]; then
            $pager "$MCP_SERVERS_DIR/$server/README.md"
        else
            echo "mcp: README not found for: $server" >&2
            echo "Try: mcp list" >&2
        fi
    fi
}

# Test MCP server (validate it runs)
_mcp_test() {
    local server="$1"

    if [[ -z "$server" ]]; then
        echo "mcp test <server-name>" >&2
        echo ""
        echo "Available servers:" >&2
        ls -1 "$MCP_SERVERS_DIR" 2>/dev/null || echo "  (none)" >&2
        return 1
    fi

    if [[ ! -d "$MCP_SERVERS_DIR/$server" ]]; then
        echo "mcp: server not found: $server" >&2
        echo "Run 'mcp help' for usage" >&2
        return 1
    fi

    echo "Testing MCP server: $server"

    local server_dir="$MCP_SERVERS_DIR/$server"
    local test_output=$(mktemp)

    # Different runtimes for different servers
    case "$server" in
        statistical-research)
            if ! command -v bun &>/dev/null; then
                echo "mcp: bun not installed (required for $server)" >&2
                echo "Run 'mcp help' for usage" >&2
                return 1
            fi
            echo "Starting with bun..."
            (cd "$server_dir" && timeout 3 bun run src/index.ts 2>&1) > "$test_output" &
            ;;
        shell|project-refactor)
            if ! command -v node &>/dev/null; then
                echo "mcp: Node.js not installed (required for $server)" >&2
                echo "Run 'mcp help' for usage" >&2
                return 1
            fi
            echo "Starting with node..."
            (cd "$server_dir" && timeout 3 node index.js 2>&1) > "$test_output" &
            ;;
        docling)
            if ! command -v uv &>/dev/null; then
                echo "mcp: uv not installed (required for $server)" >&2
                echo "Run 'mcp help' for usage" >&2
                return 1
            fi
            echo "Starting with uv..."
            (cd "$server_dir" && timeout 3 uv run docling-mcp-server 2>&1) > "$test_output" &
            ;;
        *)
            echo "mcp: unknown server type: $server" >&2
            echo "Attempting to detect entry point..." >&2

            # Try common patterns
            if [[ -f "$server_dir/index.js" ]]; then
                (cd "$server_dir" && timeout 3 node index.js 2>&1) > "$test_output" &
            elif [[ -f "$server_dir/src/index.ts" ]]; then
                (cd "$server_dir" && timeout 3 bun run src/index.ts 2>&1) > "$test_output" &
            else
                echo "mcp: cannot determine how to run $server" >&2
                echo "Run 'mcp help' for usage" >&2
                rm -f "$test_output"
                return 1
            fi
            ;;
    esac

    local pid=$!
    sleep 2

    if kill -0 $pid 2>/dev/null; then
        echo "Server running (PID: $pid)"
        echo "Stopping test server..."
        kill $pid 2>/dev/null
        wait $pid 2>/dev/null

        # Check for errors in output
        if grep -i "error" "$test_output" &>/dev/null; then
            echo "mcp: server started but errors detected:" >&2
            head -5 "$test_output" >&2
        fi
    else
        echo "mcp: server failed to start" >&2
        echo ""
        echo "Output:" >&2
        cat "$test_output" >&2
        rm -f "$test_output"
        return 1
    fi

    rm -f "$test_output"
}

# Show MCP configuration status
_mcp_status() {
    echo -e "${_C_BOLD}MCP Configuration Status${_C_NC}"
    echo ""

    # Desktop/CLI configuration
    echo "${fg[cyan]}Desktop/CLI:${reset_color}"
    if [[ -f "$MCP_DESKTOP_CONFIG" ]]; then
        echo -e "  ${_C_GREEN}✓${_C_NC} $MCP_DESKTOP_CONFIG"

        # Count configured servers
        local desktop_servers=($(jq -r '.mcpServers | keys[]' "$MCP_DESKTOP_CONFIG" 2>/dev/null))
        if [[ ${#desktop_servers[@]} -gt 0 ]]; then
            echo "  ${fg[green]}Configured servers:${reset_color}"
            for srv in "${desktop_servers[@]}"; do
                echo "    • $srv"
            done
        else
            echo -e "  ${_C_YELLOW}No servers configured${_C_NC}"
        fi
    else
        echo -e "  ${_C_RED}✗${_C_NC} $MCP_DESKTOP_CONFIG not found"
    fi

    echo ""

    # Browser Extension configuration
    echo "${fg[cyan]}Browser Extension:${reset_color}"
    if [[ -f "$MCP_BROWSER_CONFIG" ]]; then
        echo -e "  ${_C_GREEN}✓${_C_NC} $MCP_BROWSER_CONFIG"

        # Count configured servers
        local browser_servers=($(jq -r '.servers | keys[]' "$MCP_BROWSER_CONFIG" 2>/dev/null))
        if [[ ${#browser_servers[@]} -gt 0 ]]; then
            echo "  ${fg[green]}Configured servers:${reset_color}"
            for srv in "${browser_servers[@]}"; do
                echo "    • $srv"
            done
        else
            echo -e "  ${_C_YELLOW}No servers configured${_C_NC}"
        fi
    else
        echo -e "  ${_C_RED}✗${_C_NC} $MCP_BROWSER_CONFIG not found"
    fi

    echo ""

    # Quick links
    echo "${fg[blue]}ℹ${reset_color}  Edit configs:"
    echo "  Desktop/CLI: ${fg[cyan]}code $MCP_DESKTOP_CONFIG${reset_color}"
    echo "  Browser:     ${fg[cyan]}code $MCP_BROWSER_CONFIG${reset_color}"
}

# Interactive MCP server picker (using fzf)
_mcp_pick() {
    if ! command -v fzf &>/dev/null; then
        echo "mcp: fzf not installed" >&2
        echo "Install with: brew install fzf" >&2
        return 1
    fi

    if [[ ! -d "$MCP_SERVERS_DIR" ]]; then
        echo "mcp: MCP servers directory not found: $MCP_SERVERS_DIR" >&2
        echo "Run 'mcp help' for usage" >&2
        return 1
    fi

    local servers=("${(@f)$(ls -1 "$MCP_SERVERS_DIR" 2>/dev/null)}")

    if [[ ${#servers[@]} -eq 0 ]]; then
        echo "mcp: no MCP servers found" >&2
        echo "Run 'mcp help' for usage" >&2
        return 1
    fi

    local server=$(printf '%s\n' "${servers[@]}" | fzf \
        --prompt="Select MCP server: " \
        --height=40% \
        --border \
        --preview="cat $MCP_SERVERS_DIR/{}/README.md 2>/dev/null || echo 'No README available'" \
        --preview-window=right:60%:wrap)

    if [[ -z "$server" ]]; then
        echo "No server selected"
        return 0
    fi

    echo ""
    echo "${fg[cyan]}Selected:${reset_color} $server"
    echo ""
    echo "What would you like to do?"
    echo "  ${fg[green]}1)${reset_color} Navigate to server (cd)"
    echo "  ${fg[green]}2)${reset_color} Edit in $EDITOR"
    echo "  ${fg[green]}3)${reset_color} View README"
    echo "  ${fg[green]}4)${reset_color} Test server"
    echo "  ${fg[green]}5)${reset_color} Show in Finder"
    echo ""
    read "choice?Choice (1-5): "

    case "$choice" in
        1) _mcp_cd "$server" ;;
        2) _mcp_edit "$server" ;;
        3) _mcp_readme "$server" ;;
        4) _mcp_test "$server" ;;
        5) open "$MCP_SERVERS_DIR/$server" ;;
        *) echo "mcp: invalid choice" >&2 ;;
    esac
}

# Show help for MCP dispatcher
_mcp_help() {
    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ mcp - MCP Server Management                 │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}mcp${_C_NC}               List all servers
  ${_C_CYAN}mcp test NAME${_C_NC}     Test server runs
  ${_C_CYAN}mcp cd NAME${_C_NC}       Navigate to server
  ${_C_CYAN}mcp pick${_C_NC}          Interactive picker

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} mcp                    ${_C_DIM}# List all${_C_NC}
  ${_C_DIM}\$${_C_NC} mcp t docling          ${_C_DIM}# Test${_C_NC}
  ${_C_DIM}\$${_C_NC} mcp cd shell           ${_C_DIM}# Navigate${_C_NC}
  ${_C_DIM}\$${_C_NC} mcpp                   ${_C_DIM}# Picker${_C_NC}

${_C_BLUE}📋 CORE ACTIONS${_C_NC}:
  ${_C_CYAN}mcp${_C_NC} / ${_C_CYAN}mcp list${_C_NC}      List servers
  ${_C_CYAN}mcp cd <name>${_C_NC}       Navigate to server
  ${_C_CYAN}mcp test <name>${_C_NC}     Test server runs
  ${_C_CYAN}mcp edit <name>${_C_NC}     Edit in \$EDITOR
  ${_C_CYAN}mcp pick${_C_NC}            Interactive picker (fzf)

${_C_BLUE}📖 INFO & STATUS${_C_NC}:
  ${_C_CYAN}mcp status${_C_NC}          Config status
  ${_C_CYAN}mcp readme <name>${_C_NC}   View README
  ${_C_CYAN}mcp help${_C_NC}            This help

${_C_BLUE}✨ SHORT FORMS${_C_NC}:
  ${_C_CYAN}mcp l${_C_NC} / ${_C_CYAN}ls${_C_NC}          list
  ${_C_CYAN}mcp g${_C_NC} / ${_C_CYAN}goto${_C_NC}        cd
  ${_C_CYAN}mcp t${_C_NC}               test
  ${_C_CYAN}mcp e${_C_NC}               edit
  ${_C_CYAN}mcp s${_C_NC}               status
  ${_C_CYAN}mcp r${_C_NC} / ${_C_CYAN}doc${_C_NC}         readme
  ${_C_CYAN}mcp p${_C_NC}               pick
  ${_C_CYAN}mcp h${_C_NC}               help

${_C_MAGENTA}💡 TIP${_C_NC}: Use ${_C_CYAN}mcpp${_C_NC} for quick interactive selection

${_C_BLUE}📍 LOCATIONS${_C_NC}:
  Servers:  ${_C_DIM}~/projects/dev-tools/mcp-servers/${_C_NC}
  Symlinks: ${_C_DIM}~/mcp-servers/<name>${_C_NC}
  Desktop:  ${_C_DIM}~/.claude/settings.json${_C_NC}
  Browser:  ${_C_DIM}~/projects/dev-tools/claude-mcp/MCP_SERVER_CONFIG.json${_C_NC}

${_C_CYAN}🔗 See also${_C_NC}: ${_C_DIM}ait mcp list${_C_NC} for rich table output
            ${_C_DIM}ait mcp validate${_C_NC} for detailed config validation
"
}

# === Main Dispatcher ===

mcp() {
    # No arguments → default action (list)
    if [[ $# -eq 0 ]]; then
        _mcp_list
        return
    fi

    case "$1" in
        # ─────────────────────────────────────────────────────────────
        # CORE ACTIONS
        # ─────────────────────────────────────────────────────────────
        list|ls|l)
            shift
            _mcp_list "$@"
            ;;

        cd|goto|g)
            shift
            _mcp_cd "$@"
            ;;

        test|t)
            shift
            _mcp_test "$@"
            ;;

        edit|e)
            shift
            _mcp_edit "$@"
            ;;

        # ─────────────────────────────────────────────────────────────
        # INFO
        # ─────────────────────────────────────────────────────────────
        status|s)
            shift
            _mcp_status "$@"
            ;;

        readme|r|doc)
            shift
            _mcp_readme "$@"
            ;;

        pick|p)
            shift
            _mcp_pick "$@"
            ;;

        # ─────────────────────────────────────────────────────────────
        # HELP
        # ─────────────────────────────────────────────────────────────
        help|h|--help|-h)
            _mcp_help
            ;;

        *)
            echo "mcp: unknown action: $1" >&2
            echo "Run 'mcp help' for available commands" >&2
            return 1
            ;;
    esac
}

# === Single Alias ===

# Interactive picker (most useful shortcut)
alias mcpp='mcp pick'
