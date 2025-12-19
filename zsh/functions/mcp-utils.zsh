#!/usr/bin/env zsh
# mcp-utils.zsh - MCP server management utilities
# Part of zsh-claude-workflow
# Created: 2025-12-19

# Source core utilities for print functions
# (Assumes core-utils.zsh is already sourced)

# === Configuration ===
MCP_SERVERS_DIR="${HOME}/projects/dev-tools/mcp-servers"
MCP_DESKTOP_CONFIG="${HOME}/.claude/settings.json"
MCP_BROWSER_CONFIG="${HOME}/projects/dev-tools/claude-mcp/MCP_SERVER_CONFIG.json"

# === Core Functions ===

# List all MCP servers with status
mcp-list() {
    if [[ ! -d "$MCP_SERVERS_DIR" ]]; then
        print_error "MCP servers directory not found: $MCP_SERVERS_DIR"
        return 1
    fi

    print_header "MCP Servers"

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
        print_warning "No MCP servers found in $MCP_SERVERS_DIR"
    else
        echo ""
        print_success "Total: $server_count server(s)"
    fi

    echo ""
    echo "${fg[blue]}ℹ${reset_color}  Quick access: ${fg[cyan]}cd ~/mcp-servers/<name>${reset_color}"
    echo "${fg[blue]}ℹ${reset_color}  Interactive:  ${fg[cyan]}mcp-pick${reset_color}"
}

# Navigate to MCP servers directory or specific server
mcp-cd() {
    local server="$1"

    if [[ -z "$server" ]]; then
        # No argument - go to main directory
        cd "$MCP_SERVERS_DIR" || {
            print_error "Cannot navigate to $MCP_SERVERS_DIR"
            return 1
        }
        print_success "In MCP servers directory"
        ls -1
    else
        # Navigate to specific server
        if [[ -d "$MCP_SERVERS_DIR/$server" ]]; then
            cd "$MCP_SERVERS_DIR/$server" || {
                print_error "Cannot navigate to $server"
                return 1
            }
            print_success "In $server"
        else
            print_error "Server not found: $server"
            print_info "Available servers:"
            ls -1 "$MCP_SERVERS_DIR" 2>/dev/null || echo "  (none)"
            return 1
        fi
    fi
}

# Edit MCP server in $EDITOR
mcp-edit() {
    local server="$1"

    if [[ -z "$server" ]]; then
        print_error "Usage: mcp-edit <server-name>"
        echo ""
        print_info "Available servers:"
        ls -1 "$MCP_SERVERS_DIR" 2>/dev/null || echo "  (none)"
        return 1
    fi

    if [[ ! -d "$MCP_SERVERS_DIR/$server" ]]; then
        print_error "Server not found: $server"
        return 1
    fi

    local editor="${EDITOR:-code}"
    print_info "Opening $server in $editor..."
    $editor "$MCP_SERVERS_DIR/$server"
}

# View MCP server README
mcp-readme() {
    local server="$1"
    local pager="${PAGER:-less}"

    if [[ -z "$server" ]]; then
        # Show main README if exists
        if [[ -f "$MCP_SERVERS_DIR/README.md" ]]; then
            $pager "$MCP_SERVERS_DIR/README.md"
        else
            print_error "Main README.md not found"
            print_info "Try: mcp-readme <server-name>"
        fi
    else
        # Show server README
        if [[ -f "$MCP_SERVERS_DIR/$server/README.md" ]]; then
            $pager "$MCP_SERVERS_DIR/$server/README.md"
        else
            print_error "README not found for: $server"
            print_info "Try: mcp-list"
        fi
    fi
}

# Test MCP server (validate it runs)
mcp-test() {
    local server="$1"

    if [[ -z "$server" ]]; then
        print_error "Usage: mcp-test <server-name>"
        echo ""
        print_info "Available servers:"
        ls -1 "$MCP_SERVERS_DIR" 2>/dev/null || echo "  (none)"
        return 1
    fi

    if [[ ! -d "$MCP_SERVERS_DIR/$server" ]]; then
        print_error "Server not found: $server"
        return 1
    fi

    print_info "Testing MCP server: $server"

    local server_dir="$MCP_SERVERS_DIR/$server"
    local test_output=$(mktemp)

    # Different runtimes for different servers
    case "$server" in
        statistical-research)
            if ! command -v bun &>/dev/null; then
                print_error "Bun not installed (required for $server)"
                return 1
            fi
            print_info "Starting with bun..."
            (cd "$server_dir" && timeout 3 bun run src/index.ts 2>&1) > "$test_output" &
            ;;
        shell|project-refactor)
            if ! command -v node &>/dev/null; then
                print_error "Node.js not installed (required for $server)"
                return 1
            fi
            print_info "Starting with node..."
            (cd "$server_dir" && timeout 3 node index.js 2>&1) > "$test_output" &
            ;;
        *)
            print_warning "Unknown server type: $server"
            print_info "Attempting to detect entry point..."

            # Try common patterns
            if [[ -f "$server_dir/index.js" ]]; then
                (cd "$server_dir" && timeout 3 node index.js 2>&1) > "$test_output" &
            elif [[ -f "$server_dir/src/index.ts" ]]; then
                (cd "$server_dir" && timeout 3 bun run src/index.ts 2>&1) > "$test_output" &
            else
                print_error "Cannot determine how to run $server"
                rm -f "$test_output"
                return 1
            fi
            ;;
    esac

    local pid=$!
    sleep 2

    if kill -0 $pid 2>/dev/null; then
        print_success "Server running (PID: $pid)"
        print_info "Stopping test server..."
        kill $pid 2>/dev/null
        wait $pid 2>/dev/null

        # Check for errors in output
        if grep -i "error" "$test_output" &>/dev/null; then
            print_warning "Server started but errors detected:"
            head -5 "$test_output"
        fi
    else
        print_error "Server failed to start"
        echo ""
        print_info "Output:"
        cat "$test_output"
        rm -f "$test_output"
        return 1
    fi

    rm -f "$test_output"
}

# Show MCP configuration status
mcp-status() {
    print_header "MCP Configuration Status"

    # Desktop/CLI configuration
    echo "${fg[cyan]}Desktop/CLI:${reset_color}"
    if [[ -f "$MCP_DESKTOP_CONFIG" ]]; then
        print_success "$MCP_DESKTOP_CONFIG"

        # Count configured servers
        local desktop_servers=($(jq -r '.mcpServers | keys[]' "$MCP_DESKTOP_CONFIG" 2>/dev/null))
        if [[ ${#desktop_servers[@]} -gt 0 ]]; then
            echo "  ${fg[green]}Configured servers:${reset_color}"
            for srv in "${desktop_servers[@]}"; do
                echo "    • $srv"
            done
        else
            print_warning "  No servers configured"
        fi
    else
        print_error "$MCP_DESKTOP_CONFIG not found"
    fi

    echo ""

    # Browser Extension configuration
    echo "${fg[cyan]}Browser Extension:${reset_color}"
    if [[ -f "$MCP_BROWSER_CONFIG" ]]; then
        print_success "$MCP_BROWSER_CONFIG"

        # Count configured servers
        local browser_servers=($(jq -r '.servers | keys[]' "$MCP_BROWSER_CONFIG" 2>/dev/null))
        if [[ ${#browser_servers[@]} -gt 0 ]]; then
            echo "  ${fg[green]}Configured servers:${reset_color}"
            for srv in "${browser_servers[@]}"; do
                echo "    • $srv"
            done
        else
            print_warning "  No servers configured"
        fi
    else
        print_error "$MCP_BROWSER_CONFIG not found"
    fi

    echo ""

    # Quick links
    echo "${fg[blue]}ℹ${reset_color}  Edit configs:"
    echo "  Desktop/CLI: ${fg[cyan]}code $MCP_DESKTOP_CONFIG${reset_color}"
    echo "  Browser:     ${fg[cyan]}code $MCP_BROWSER_CONFIG${reset_color}"
}

# Interactive MCP server picker (using fzf)
mcp-pick() {
    if ! command -v fzf &>/dev/null; then
        print_error "fzf not installed"
        print_info "Install with: brew install fzf"
        return 1
    fi

    if [[ ! -d "$MCP_SERVERS_DIR" ]]; then
        print_error "MCP servers directory not found: $MCP_SERVERS_DIR"
        return 1
    fi

    local servers=("${(@f)$(ls -1 "$MCP_SERVERS_DIR" 2>/dev/null)}")

    if [[ ${#servers[@]} -eq 0 ]]; then
        print_error "No MCP servers found"
        return 1
    fi

    local server=$(printf '%s\n' "${servers[@]}" | fzf \
        --prompt="Select MCP server: " \
        --height=40% \
        --border \
        --preview="cat $MCP_SERVERS_DIR/{}/README.md 2>/dev/null || echo 'No README available'" \
        --preview-window=right:60%:wrap)

    if [[ -z "$server" ]]; then
        print_info "No server selected"
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
        1) mcp-cd "$server" ;;
        2) mcp-edit "$server" ;;
        3) mcp-readme "$server" ;;
        4) mcp-test "$server" ;;
        5) open "$MCP_SERVERS_DIR/$server" ;;
        *) print_error "Invalid choice" ;;
    esac
}

# Show help for MCP utilities
mcp-help() {
    print_header "MCP Server Management"

    echo "${fg[cyan]}Commands:${reset_color}"
    echo ""
    echo "  ${fg[green]}mcp-list${reset_color}        List all MCP servers with status"
    echo "  ${fg[green]}mcp-cd${reset_color} <name>   Navigate to server directory"
    echo "  ${fg[green]}mcp-edit${reset_color} <name> Edit server in \$EDITOR"
    echo "  ${fg[green]}mcp-readme${reset_color} <name> View server README"
    echo "  ${fg[green]}mcp-test${reset_color} <name> Test server runs"
    echo "  ${fg[green]}mcp-status${reset_color}      Show configuration status"
    echo "  ${fg[green]}mcp-pick${reset_color}        Interactive server picker (fzf)"
    echo "  ${fg[green]}mcp-help${reset_color}        Show this help"
    echo ""

    echo "${fg[cyan]}Aliases:${reset_color}"
    echo ""
    echo "  ${fg[yellow]}Short forms:${reset_color}"
    echo "    ml, mcpl  → mcp-list"
    echo "    mc, mcpc  → mcp-cd"
    echo "    mcpe      → mcp-edit"
    echo "    mcpr      → mcp-readme"
    echo "    mcpt      → mcp-test"
    echo "    mcps      → mcp-status"
    echo "    mcpp      → mcp-pick"
    echo "    mcph      → mcp-help"
    echo ""

    echo "${fg[cyan]}Examples:${reset_color}"
    echo ""
    echo "  ${fg[blue]}#${reset_color} List all servers"
    echo "  ${fg[yellow]}\$${reset_color} mcp-list"
    echo ""
    echo "  ${fg[blue]}#${reset_color} Navigate to shell server"
    echo "  ${fg[yellow]}\$${reset_color} mcp-cd shell"
    echo ""
    echo "  ${fg[blue]}#${reset_color} Test statistical-research server"
    echo "  ${fg[yellow]}\$${reset_color} mcp-test statistical-research"
    echo ""
    echo "  ${fg[blue]}#${reset_color} Interactive selection"
    echo "  ${fg[yellow]}\$${reset_color} mcp-pick"
    echo ""

    echo "${fg[cyan]}Quick Access:${reset_color}"
    echo "  ${fg[blue]}Symlinks:${reset_color} ~/mcp-servers/<name>"
    echo "  ${fg[blue]}Index:${reset_color}    ~/projects/dev-tools/_MCP_SERVERS.md"
    echo ""

    echo "${fg[blue]}ℹ${reset_color}  Integration: Use ${fg[cyan]}cc mcp${reset_color} or ${fg[cyan]}gm mcp${reset_color} for CLI management"
}

# === Aliases ===

# Short aliases (ADHD-friendly)
alias mcpl='mcp-list'           # List servers
alias mcpc='mcp-cd'             # Navigate to server
alias mcpe='mcp-edit'           # Edit server
alias mcpt='mcp-test'           # Test server
alias mcps='mcp-status'         # Show config status
alias mcpr='mcp-readme'         # View README
alias mcpp='mcp-pick'           # Interactive picker
alias mcph='mcp-help'           # Show help

# Ultra-short for frequent use
alias ml='mcp-list'             # Most common: list servers
alias mc='mcp-cd'               # Most common: navigate

# Help system integration
alias mcp='mcp-help'            # Default: show help

# === Completion ===
# TODO: Add completion for server names
# compdef _mcp_servers mcp-cd mcp-edit mcp-readme mcp-test
