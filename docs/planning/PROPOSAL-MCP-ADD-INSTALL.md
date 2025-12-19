# MCP Add/Install Command Proposal

**Date:** 2025-12-19 (Updated: 2025-12-19 with unified search recommendation)
**Context:** Add intelligent MCP server discovery and installation to `mcp` dispatcher

---

## 🎯 UPDATED RECOMMENDATION: UNIFIED SEARCH

**Evolution:** After further research, we discovered Claude Code has BOTH:
- 📦 **MCP Servers** (~200+ in registry)
- 🔌 **Claude Code Plugins** (~50+ across 5 marketplaces)

**New Vision:** ONE search that finds EVERYTHING - users don't need to know the distinction!

See `BRAINSTORM-UNIFIED-MCP-SEARCH.md` for complete unified search proposal.

**Quick Summary:**
```bash
mcp search github          # Searches BOTH servers + plugins
mcp browse                 # Browse ALL with fzf + categories
mcp add <name>             # Smart install (auto-detects type)
```

**This document** focuses on the MCP Server aspects (original scope).
**Unified proposal** extends this to include plugin discovery too.

---

## Problem Statement

Currently, adding an MCP server requires:
1. Manually searching for servers (GitHub, documentation, word-of-mouth)
2. Understanding the installation method (npm, uv, docker, etc.)
3. Manually configuring `~/.claude/settings.json`
4. Testing the server works
5. No security review or duplicate detection

**User request:**
> "Add keyword 'add' or 'install' that would search for an mcp server, check if it's installed or similar one installed, then present a summary of what it does, check the security, offer advice, and then proceed to install and test or cancel"

---

## Research Findings

### Official MCP Registry (NEW!)

Anthropic launched the official MCP Registry in September 2025:
- **URL:** https://registry.modelcontextprotocol.io
- **API:** REST API with search, pagination, metadata
- **Status:** Preview (moving to general availability)
- **Community-driven:** Backed by Anthropic, GitHub, Microsoft, etc.

**API Endpoints:**
```bash
# Search servers
GET https://registry.modelcontextprotocol.io/v0.1/servers?search=<term>&version=latest

# Get server details
GET https://registry.modelcontextprotocol.io/v0.1/servers/<name>/versions/<version>

# List all
GET https://registry.modelcontextprotocol.io/v0.1/servers?limit=100
```

**Response includes:**
- Server name, description, version
- Installation packages (npm, uv/pypi, docker/oci)
- Repository URL and source
- Required environment variables (with `isSecret` flag)
- Transport type (stdio, sse, http)
- Official status and publication dates

### Claude Code Native Command

Claude Code already has `claude mcp add`:
```bash
claude mcp add <name> <commandOrUrl> [args...]

# Examples:
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp
claude mcp add --transport stdio airtable -- npx -y airtable-mcp-server

# Options:
--scope <local|user|project>
--transport <stdio|sse|http>
--env KEY=value
```

**Limitations:**
- No discovery (must know server name and command)
- No security review
- No duplicate detection
- Manual configuration needed

---

## Proposed Solutions

### Option A: Wrapper Around `claude mcp add` (Recommended)

**Concept:** `mcp add` becomes an intelligent wrapper that:
1. Searches MCP Registry
2. Shows server info and security analysis
3. Checks for duplicates/similar servers
4. Calls `claude mcp add` under the hood
5. Tests installation
6. Creates symlink and updates docs

**Workflow:**
```bash
$ mcp add filesystem

🔍 Searching MCP Registry...

Found 3 matches:

1. @modelcontextprotocol/server-filesystem (Official Anthropic)
   ⭐ Official | 📦 npm | 🔒 Requires: allowed-directories
   Description: Secure local filesystem access with path restrictions

2. @ai-capabilities-suite/mcp-filesystem (Digital-Defiance)
   📦 npm, docker | 🔒 No secrets
   Description: Advanced filesystem with batch ops, watching, search

3. @agent-infra/mcp-server-filesystem (ByteDance)
   📦 npm | 🔒 Requires: allowed-directories
   Description: Filesystem access for UI-TARS

Select server (1-3, or 'c' to cancel): 1

╭─────────────────────────────────────────────╮
│ Server Summary                              │
╰─────────────────────────────────────────────╯

Name:        @modelcontextprotocol/server-filesystem
Version:     latest
Repository:  https://github.com/modelcontextprotocol/servers
Transport:   stdio
Runtime:     npx (Node.js)

🔒 Security Review:

  ✅ Official Anthropic server
  ✅ Open source (GitHub)
  ⚠️  Requires file system access
  ⚠️  Must specify allowed-directories

  This server can read/write files in specified directories.
  Only grant access to necessary paths.

📋 Checking installed servers...

  ⚠️  Similar server found: 'shell' (can access filesystem via shell commands)

  Continue installation? (y/n): y

📦 Installing...

  → Adding to ~/.claude/settings.json (scope: user)
  → Running: claude mcp add filesystem --scope user -- npx -y @modelcontextprotocol/server-filesystem /Users/dt
  ✓ Added to configuration

  → Testing connection...
  ✓ Server responds

  → Creating symlink ~/mcp-servers/filesystem...
  ✓ Created

  → Updating documentation...
  ✓ Updated ~/projects/dev-tools/_MCP_SERVERS.md

✅ Installation complete!

Next steps:
  $ mcp test filesystem    # Test the server
  $ mcp cd filesystem      # Navigate to server
  $ mcp help               # See all commands
```

**Implementation:**
```zsh
_mcp_add() {
    local search_term="$1"

    # 1. Search registry
    local results=$(curl -s "https://registry.modelcontextprotocol.io/v0.1/servers?search=$search_term&version=latest")

    # 2. Parse and display results (using jq or python)
    _mcp_display_search_results "$results"

    # 3. User selection
    read -r "selection?Select server (1-N, 'c' to cancel): "

    # 4. Show detailed info and security analysis
    _mcp_analyze_security "$selected_server"

    # 5. Check for duplicates
    _mcp_check_duplicates "$selected_server"

    # 6. Confirm installation
    read -r "confirm?Continue installation? (y/n): "

    # 7. Call claude mcp add
    claude mcp add --scope user "$server_name" -- "$install_command"

    # 8. Test
    _mcp_test "$server_name"

    # 9. Create symlink
    ln -s "$MCP_SERVERS_DIR/$server_name" ~/mcp-servers/

    # 10. Update docs
    _mcp_update_docs "$server_name"
}
```

**Pros:**
- Uses official registry (authoritative source)
- Leverages Claude Code's native installation
- Intelligent guidance and security review
- Minimal maintenance (registry is maintained by Anthropic)
- Works with all transport types (stdio, sse, http)

**Cons:**
- Requires internet connection
- Depends on registry API availability
- Not all servers may be in registry yet

---

### Option B: Manual Database + Installation Scripts

**Concept:** Maintain local database of known servers with custom installation scripts

**Workflow:**
```bash
$ mcp add postgres

📚 Checking local database...

Found: @modelcontextprotocol/server-postgres

[similar UI as Option A, but uses local data]
```

**Implementation:**
```bash
# Database: ~/.config/zsh/mcp-servers-db.json
{
  "servers": [
    {
      "name": "postgres",
      "package": "@modelcontextprotocol/server-postgres",
      "runtime": "npx",
      "official": true,
      "install_script": "install_postgres.sh"
    }
  ]
}
```

**Pros:**
- Works offline
- Full control over installation process
- Can add custom servers

**Cons:**
- Manual maintenance required
- Database gets outdated
- Limited to known servers
- Duplication of effort (registry already exists)

---

### Option C: Hybrid Approach

**Concept:** Try registry first, fallback to local database

**Workflow:**
1. Search official registry (if online)
2. If not found, search local database
3. If still not found, offer to add custom server
4. Same intelligent installation flow

**Pros:**
- Best of both worlds
- Offline capability
- Extensible to custom servers

**Cons:**
- More complex implementation
- Two systems to maintain

---

## Security Analysis Features

All options should include:

### 1. Official Status Check
```bash
✅ Official Anthropic server
⚠️  Community server (not officially vetted)
```

### 2. Secret Detection
```bash
🔒 Required Environment Variables:
  - AIRTABLE_API_KEY (secret) ⚠️
  - DATABASE_URL (connection string) ⚠️
```

### 3. Permission Analysis
```bash
📋 Permissions Required:
  ⚠️  Filesystem access (read/write)
  ⚠️  Network access (external APIs)
  ⚠️  Shell command execution
  ✅ Read-only file access
```

### 4. Repository Check
```bash
📦 Source Code:
  ✅ GitHub repository: https://github.com/org/repo
  ✅ Open source (MIT license)
  ⚠️  Closed source / No repository
```

### 5. Similar Server Detection
```bash
📋 Checking installed servers...

  ⚠️  Similar functionality found:
      - 'shell' (can access filesystem via shell)
      - 'statistical-research' (can execute R code)

  These servers may overlap in functionality.
  Consider if you need both.
```

---

## Duplicate Detection Logic

```zsh
_mcp_check_duplicates() {
    local new_server="$1"
    local new_capabilities="$2"  # e.g., "filesystem,shell"

    # Get list of installed servers
    local installed=$(ls "$MCP_SERVERS_DIR")

    # Check for exact name match
    if [[ -d "$MCP_SERVERS_DIR/$new_server" ]]; then
        echo "❌ Server '$new_server' is already installed"
        return 1
    fi

    # Check for capability overlap
    for server in $installed; do
        local capabilities=$(_mcp_get_capabilities "$server")

        # Compare capabilities
        local overlap=$(_compare_capabilities "$new_capabilities" "$capabilities")

        if [[ -n "$overlap" ]]; then
            echo "⚠️  Similar server found: '$server' (overlapping: $overlap)"
        fi
    done
}

_mcp_get_capabilities() {
    # Parse server README or package.json for capabilities
    # Return comma-separated list: "filesystem,shell,network"
}
```

---

## Installation Methods by Runtime

### NPM (Node.js)
```bash
# Using npx (no install needed)
claude mcp add server-name -- npx -y @scope/package

# Or install locally
cd ~/projects/dev-tools/mcp-servers/server-name
npm init -y
npm install @scope/package
```

### UV/Python
```bash
cd ~/projects/dev-tools/mcp-servers/server-name
uv init --name server-name --no-readme
uv add package-name
```

### Docker/OCI
```bash
claude mcp add server-name --transport stdio -- docker run -i package:tag
```

### HTTP/SSE (Remote)
```bash
claude mcp add server-name --transport http https://server.com/mcp
```

---

## Implementation Plan

### Phase 1: Basic Search & Install (Week 1)
- [ ] Implement `mcp add <search>` command
- [ ] Search MCP Registry API
- [ ] Display search results (formatted)
- [ ] User selection interface
- [ ] Call `claude mcp add` with proper args
- [ ] Basic testing after install

### Phase 2: Security & Intelligence (Week 2)
- [ ] Security analysis display
- [ ] Environment variable detection
- [ ] Permission warnings
- [ ] Official status indicators
- [ ] Duplicate detection logic
- [ ] Similar server warnings

### Phase 3: Documentation & Symlinks (Week 3)
- [ ] Auto-create symlinks in ~/mcp-servers/
- [ ] Update _MCP_SERVERS.md
- [ ] Update mcp-servers/README.md
- [ ] Generate server-specific README
- [ ] Add to quick reference

### Phase 4: Advanced Features (Week 4)
- [ ] Local server database (fallback)
- [ ] Custom server addition
- [ ] Uninstall command (`mcp remove`)
- [ ] Update command (`mcp update <server>`)
- [ ] Upgrade all command (`mcp upgrade`)

---

## Command Reference

### New Commands (Option A)

```bash
# Search and install
mcp add <search>          # Search registry and install
mcp install <search>      # Alias for add

# Management (future)
mcp remove <name>         # Uninstall server
mcp update <name>         # Update to latest version
mcp upgrade               # Update all servers

# Already exist
mcp list                  # List installed servers
mcp test <name>           # Test server
mcp status                # Show config status
```

### Short Forms

```bash
mcp a <search>            # add
mcp i <search>            # install
```

---

## Recommendation

**Choose Option A: Registry Wrapper**

**Reasons:**
1. **Authoritative source** - Official MCP Registry maintained by Anthropic
2. **Low maintenance** - No manual database to update
3. **Complete coverage** - Access to all public servers
4. **Leverages existing** - Uses `claude mcp add` under the hood
5. **Future-proof** - Registry will grow and improve
6. **Security metadata** - Registry includes security info
7. **Community-driven** - Benefits from entire ecosystem

**Implementation effort:** ~2-3 days
- Day 1: Search and selection interface
- Day 2: Security analysis and duplicate detection
- Day 3: Installation flow and testing

---

## Example Use Cases

### Use Case 1: Installing Official Server
```bash
$ mcp add github

🔍 Searching...
Found: @modelcontextprotocol/server-github
✅ Official Anthropic server
🔒 Requires: GITHUB_TOKEN

Install? (y/n): y
✓ Installed successfully!
```

### Use Case 2: Finding Similar Servers
```bash
$ mcp add database

🔍 Searching...
Found 5 matches: postgres, mysql, sqlite, mongodb, redis

1. postgres (Official)
2. mysql (Community)
3. sqlite (Official)
...

Select (1-5): 1

⚠️  Similar server found: 'postgres-local' already installed
Continue? (y/n): n

Cancelled.
```

### Use Case 3: Security Warning
```bash
$ mcp add untrusted-server

🔍 Searching...
Found: untrusted-server
⚠️  Community server (not officially vetted)
⚠️  No GitHub repository
⚠️  Requires shell command execution

🔴 Security concerns detected!

Recommended: Only install from trusted sources.

Continue anyway? (y/n): n
```

---

## Testing Strategy

### Unit Tests
```bash
test_search_registry()      # Test API search
test_parse_results()        # Test JSON parsing
test_detect_duplicates()    # Test duplicate logic
test_security_analysis()    # Test security checks
```

### Integration Tests
```bash
test_full_install_flow()    # End-to-end installation
test_error_handling()       # Network errors, bad input
test_duplicate_warning()    # Duplicate detection works
```

### Manual Tests
```bash
# Install from registry
mcp add filesystem

# Search with no results
mcp add nonexistent-server

# Cancel installation
mcp add postgres  # then press 'n'

# Install with duplicate
mcp add shell  # when shell already installed
```

---

## Files to Create/Modify

### New Files
```
~/.config/zsh/functions/
├── mcp-registry-api.zsh      # Registry API wrapper
└── mcp-security.zsh          # Security analysis functions

~/.config/zsh/tests/
└── test-mcp-add.zsh          # Test suite
```

### Modified Files
```
~/.config/zsh/functions/
└── mcp-dispatcher.zsh         # Add 'add|install|a|i' keywords

~/.config/zsh/tests/
└── test-mcp-dispatcher.zsh    # Update test count
```

---

## Dependencies

### Required
- `curl` - API requests (already available)
- `jq` or Python - JSON parsing (already available)
- `fzf` - Interactive selection (already used in mcp pick)
- `claude` - Claude Code CLI (already installed)

### Optional
- `bat` - Pretty display (already available)
- `glow` - Markdown rendering (if installed)

---

## Future Enhancements

### Version 1 (MVP)
- Search and install from registry
- Basic security warnings
- Duplicate detection

### Version 2
- Custom server addition (not in registry)
- Local database fallback
- Uninstall command

### Version 3
- Update/upgrade commands
- Server health monitoring
- Usage statistics

### Version 4
- Server recommendations (based on usage)
- Dependency resolution
- Conflict detection

---

## Success Criteria

### Must Have (MVP)
- [x] Search MCP Registry by keyword
- [ ] Display formatted search results
- [ ] Show security analysis
- [ ] Detect duplicate servers
- [ ] Install via `claude mcp add`
- [ ] Test installed server
- [ ] Update documentation

### Nice to Have (V2+)
- [ ] Offline fallback database
- [ ] Custom server installation
- [ ] Uninstall command
- [ ] Update/upgrade commands
- [ ] Interactive TUI

---

## Sources

- [Introducing the MCP Registry](https://blog.modelcontextprotocol.io/posts/2025-09-08-mcp-registry-preview/)
- [MCP Registry GitHub](https://github.com/modelcontextprotocol/registry)
- [MCP Roadmap](https://modelcontextprotocol.io/development/roadmap)
- [Donating the MCP to AAIF](https://www.anthropic.com/news/donating-the-model-context-protocol-and-establishing-of-the-agentic-ai-foundation)

---

**Next Steps:**
1. Review proposal
2. Choose option (recommend Option A)
3. Create implementation plan
4. Start with Phase 1 (basic search & install)

**Estimated Implementation:** 2-3 days for MVP
