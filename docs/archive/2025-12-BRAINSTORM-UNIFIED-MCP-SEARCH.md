# Brainstorm: Unified MCP Search (Servers + Plugins)

**Date:** 2025-12-19
**Context:** ONE search command that finds BOTH MCP servers AND Claude Code plugins
**Key Insight:** Users don't care about the distinction - they just want to add functionality!

---

## 🎯 The Vision

**Current Problem:**

```bash
# Two different commands, two different mental models
claude mcp add <server>       # For MCP servers
claude plugin install <name>  # For Claude Code plugins

# User has to know:
# - Is it a server or plugin?
# - Where is it hosted?
# - What registry/marketplace?
```

**Proposed Solution:**

```bash
# ONE command that searches EVERYTHING
mcp search github

# Results (categorized automatically):
╭─────────────────────────────────────────────╮
│ Search Results for "github"                │
╰─────────────────────────────────────────────╯

📦 MCP SERVERS (2 found):
  [1] mcp-github (Official ⭐)
      GitHub API integration via MCP
      npm | Requires: GITHUB_TOKEN

  [2] github-mcp-server (Community)
      GitHub operations for AI agents
      docker | No secrets required

🔌 CLAUDE CODE PLUGINS (1 found):
  [3] github (Official ⭐)
      GitHub workflow tools for Claude Code
      Skills: 5 commands | Agents: 2

Select (1-3, 'b' to browse all, 'c' to cancel): 1

Installing mcp-github...
✓ Done! Use with Claude Code now.
```

**User Experience:**

- ✅ Don't need to know if it's a server or plugin
- ✅ Don't need to know which marketplace/registry
- ✅ One search, categorized results
- ✅ Smart install (handles servers vs plugins automatically)

---

## 🔍 Discovery: What We Have

### Claude Code Has THREE Extension Systems!

#### 1. MCP Servers (External processes)

- **Command:** `claude mcp add/remove/list`
- **Registry:** https://registry.modelcontextprotocol.io
- **Count:** ~200+ servers
- **Examples:** filesystem, github, postgres, docling
- **Type:** Stdio/SSE/HTTP processes
- **Config:** `~/.claude/settings.json`

#### 2. Claude Code Plugins (Bundled agents/skills)

- **Command:** `claude plugin install/uninstall/enable/disable`
- **Marketplaces:**
  - `claude-plugins-official` (Anthropic)
  - `claude-code-plugins` (Anthropic)
  - `cc-marketplace` (Community)
  - `every-marketplace` (Every Inc)
  - `matsengrp-marketplace` (Community)
- **Count:** ~50+ plugins
- **Examples:** pr-review-toolkit, commit-commands, feature-dev
- **Type:** Markdown files with agents/skills/commands
- **Cache:** `~/.claude/plugins/cache/`

#### 3. User Plugins (Local)

- **Command:** `--plugin-dir <path>`
- **Location:** Any directory
- **Type:** Custom plugins you write
- **Not relevant for search** (local only)

### Key Insight: They're All "Extensions"

From a user perspective, they all:

- ✅ Add functionality to Claude Code
- ✅ Can be installed/removed
- ✅ Have names and descriptions
- ✅ May require configuration

**Users shouldn't care about the implementation!**

---

## 💡 UNIFIED SEARCH ARCHITECTURE

### Concept: Multi-Source Search

```bash
mcp search <term>             # Searches ALL sources
mcp browse                    # Browse ALL sources

# Behind the scenes:
# 1. Search MCP Registry (API)
# 2. Search plugin marketplaces (local cache)
# 3. Merge and categorize results
# 4. Present unified list
```

### Data Sources

#### Source 1: MCP Registry (Remote)

```bash
# API call:
curl "https://registry.modelcontextprotocol.io/v0.1/servers?search=github&version=latest"

# Returns:
{
  "servers": [{
    "server": {
      "name": "mcp-github",
      "description": "GitHub integration",
      "packages": [...],
      "repository": {...}
    },
    "_meta": {
      "status": "active",
      "isLatest": true
    }
  }]
}
```

**Pros:**

- Always up-to-date
- Large selection (~200+)
- Official registry

**Cons:**

- Requires internet
- Rate limited (100 req/min)

#### Source 2: Plugin Marketplaces (Local Cache)

```bash
# Local cache:
~/.claude/plugins/cache/
├── claude-plugins-official/
│   ├── pr-review-toolkit/
│   │   └── plugin.json
│   ├── commit-commands/
│   │   └── plugin.json
│   └── ...
├── cc-marketplace/
└── every-marketplace/

# Each plugin.json:
{
  "name": "pr-review-toolkit",
  "description": "Comprehensive PR review agents",
  "author": {...}
}
```

**Pros:**

- Fast (local search)
- Works offline
- Multiple marketplaces

**Cons:**

- Needs periodic update
- Smaller selection (~50)

### Search Algorithm

```zsh
_unified_search() {
    local term="$1"
    local results=()

    # 1. Search MCP Registry
    local mcp_results=$(curl -s "https://registry.modelcontextprotocol.io/v0.1/servers?search=$term&version=latest")

    # 2. Search plugin cache (all marketplaces)
    local plugin_results=$(grep -ri "$term" ~/.claude/plugins/cache/*/*/plugin.json)

    # 3. Parse and categorize
    local mcp_servers=()
    local plugins=()

    # Parse MCP results
    echo "$mcp_results" | jq -r '.servers[] | {
        type: "mcp",
        name: .server.name,
        desc: .server.description,
        official: (._meta."io.modelcontextprotocol.registry/official".status == "active")
    }'

    # Parse plugin results
    # ... similar parsing

    # 4. Display categorized results
    _display_categorized_results "$mcp_servers" "$plugins"
}
```

---

## 🎨 UI DESIGN: Categorized Results

### Option A: List Format (Simple) ⭐⭐

```bash
$ mcp search github

╭─────────────────────────────────────────────╮
│ Search Results for "github"                │
╰─────────────────────────────────────────────╯

📦 MCP SERVERS (2):
  [1] mcp-github (Official ⭐)
      GitHub API integration

  [2] github-mcp-server
      GitHub operations

🔌 PLUGINS (1):
  [3] github (Official ⭐)
      GitHub workflow tools

Select (1-3, 'b' for browse, 'c' to cancel): _
```

**Pros:**

- Clear categories
- Easy to scan
- Simple to implement

**Cons:**

- Limited info shown
- No visual separation

---

### Option B: Table Format (Organized) ⭐⭐⭐

```bash
$ mcp search github

╭─────────────────────────────────────────────────────────────────────╮
│ Search Results: "github" (3 found)                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│ 📦 MCP SERVERS                                                      │
│ ─────────────────────────────────────────────────────────────────── │
│ [1] mcp-github              ⭐ Official | 📦 npm | 🔒 Token        │
│     GitHub API integration for MCP                                  │
│                                                                      │
│ [2] github-mcp-server       Community | 🐳 docker                  │
│     GitHub operations for AI agents                                 │
│                                                                      │
│ 🔌 CLAUDE CODE PLUGINS                                              │
│ ─────────────────────────────────────────────────────────────────── │
│ [3] github                  ⭐ Official | 💻 Skills: 5             │
│     GitHub workflow tools & automation                              │
│                                                                      │
╰─────────────────────────────────────────────────────────────────────╯

Select number (1-3), 'b' to browse all, 'c' to cancel: _
```

**Pros:**

- Rich information
- Visual hierarchy
- Professional look

**Cons:**

- Wider terminal needed
- More complex formatting

---

### Option C: Interactive FZF (Visual) ⭐⭐⭐

```bash
$ mcp browse

# FZF interface:
> github

📦 mcp-github (Official ⭐)
📦 github-mcp-server
🔌 github (Official ⭐)
🔌 github-actions
🔌 gh-cli-helper

# Preview pane (right side):
╭─────────────────────────────────╮
│ 📦 mcp-github                   │
├─────────────────────────────────┤
│ Type: MCP Server                │
│ Source: Official Registry       │
│ Status: ⭐ Official Anthropic   │
│                                 │
│ Description:                    │
│ GitHub API integration via MCP  │
│ protocol for AI agents          │
│                                 │
│ Installation:                   │
│ 📦 npm (npx)                    │
│ 🔒 Requires: GITHUB_TOKEN       │
│                                 │
│ Features:                       │
│ - Repository management         │
│ - Issue tracking                │
│ - Pull request operations       │
│                                 │
│ [Enter] Install | [Esc] Cancel  │
╰─────────────────────────────────╯
```

**Pros:**

- Most visual
- Rich preview
- Familiar interface (already use fzf)
- Natural categorization (icon prefix)

**Cons:**

- Requires fzf
- Terminal-only

---

## 🔧 IMPLEMENTATION OPTIONS

### Option 1: Smart `mcp` Dispatcher (Recommended) ⭐⭐⭐

**Commands:**

```bash
mcp search <term>             # Search both servers + plugins
mcp browse                    # Browse all with fzf
mcp add <name>                # Smart install (detects type)
```

**How it works:**

1. `mcp search github` → searches both sources
2. Shows categorized results
3. User selects by number
4. `mcp add` detects type and calls appropriate command:
   - MCP server → `claude mcp add ...`
   - Plugin → `claude plugin install ...`

**Example:**

```bash
$ mcp add mcp-github

🔍 Detecting type...
   Type: MCP Server
   Source: Official Registry

📦 Installing MCP server...
   Running: claude mcp add mcp-github --scope user -- npx -y @modelcontextprotocol/server-github

✓ Installed!

$ mcp add pr-review-toolkit

🔍 Detecting type...
   Type: Claude Code Plugin
   Marketplace: claude-plugins-official

🔌 Installing plugin...
   Running: claude plugin install pr-review-toolkit --scope user

✓ Installed!
```

**Pros:**

- ONE interface for everything
- User doesn't think about types
- Natural extension of existing `mcp` dispatcher
- Consistent with current pattern

**Cons:**

- Might confuse plugins with MCP servers (naming)
- Slightly blurs the technical distinction

---

### Option 2: Separate Commands, Unified Search

**Commands:**

```bash
search <term>                 # Top-level search (both)
mcp add <server>              # MCP servers only
plugin add <plugin>           # Plugins only
```

**How it works:**

1. `search github` → unified search
2. Results show type clearly
3. User uses appropriate install command:
   - `mcp add mcp-github` for servers
   - `plugin add github` for plugins

**Pros:**

- Clear distinction maintained
- Separate install paths
- Technically accurate

**Cons:**

- Need to remember which command
- Not as seamless
- User still thinks about types

---

### Option 3: New Top-Level `extend` Command

**Commands:**

```bash
extend search <term>          # Search everything
extend add <name>             # Smart install (detects type)
extend browse                 # Browse all
extend list                   # List installed (both)
```

**Rationale:** "extend" is neutral (doesn't say server or plugin)

**Pros:**

- Clear purpose (extend Claude Code)
- Neutral terminology
- Clean namespace

**Cons:**

- Yet another top-level command
- Breaks `mcp` pattern we've established
- Need to learn new command

---

## 📊 CATEGORIZATION STRATEGY

### Visual Indicators

```bash
# Prefix icons for instant recognition:
📦  MCP Server (external process)
🔌  Plugin (bundled skill/agent)
⭐  Official (Anthropic)
👥  Community
🔒  Requires secrets
🐳  Docker/OCI
📦  npm/npx
🐍  Python/uv
🟢  Installed
⚪  Available
```

### Grouping

```bash
# Group by type first, then by source:
📦 MCP SERVERS
   Official (2)
   Community (3)

🔌 CLAUDE CODE PLUGINS
   Official (1)
   Community (2)
```

### Sorting

**Within each category:**

1. Official first (⭐)
2. Alphabetical
3. Relevance score (if using fuzzy search)

---

## 🚀 IMPLEMENTATION PLAN

### Phase 1: Unified Search (Week 1) ⭐⭐⭐

**Goal:** `mcp search` returns both servers and plugins

**Tasks:**

1. Create `_unified_search()` function
   - Search MCP Registry API
   - Search local plugin cache
   - Merge results
   - Categorize by type

2. Display categorized results
   - Format with icons
   - Show key info (official, requirements)
   - Number results

3. Test with real searches
   ```bash
   mcp search github
   mcp search database
   mcp search pdf
   ```

**Effort:** 1-2 days
**Deliverable:** Working search that shows both types

---

### Phase 2: Unified Browse (Week 1-2) ⭐⭐⭐

**Goal:** `mcp browse` shows everything in fzf

**Tasks:**

1. Fetch all sources
   - MCP Registry (all servers)
   - All plugin marketplaces

2. Create fzf list with prefixes
   - `📦 mcp-github`
   - `🔌 pr-review-toolkit`

3. Rich preview pane
   - Show type, source, description
   - Show installation method
   - Show requirements

4. Test interactive browsing

**Effort:** 1 day
**Deliverable:** Beautiful fzf browser for all extensions

---

### Phase 3: Smart Install (Week 2) ⭐⭐⭐

**Goal:** `mcp add <name>` detects type and installs correctly

**Tasks:**

1. Type detection logic

   ```zsh
   _detect_type() {
       # Check MCP Registry first
       # Check plugin marketplaces
       # Return: "mcp" or "plugin"
   }
   ```

2. Smart install dispatch

   ```zsh
   _smart_install() {
       case "$type" in
           mcp) claude mcp add "$name" ... ;;
           plugin) claude plugin install "$name" ... ;;
       esac
   }
   ```

3. Unified feedback
   - Show what's being installed
   - Show progress
   - Confirm success

**Effort:** 1 day
**Deliverable:** `mcp add` works for both types seamlessly

---

### Phase 4: Management Commands (Week 3) ⭐⭐

**Goal:** Manage installed servers and plugins together

**Commands:**

```bash
mcp list                      # List ALL installed (servers + plugins)
mcp enable <name>             # Enable (auto-detect type)
mcp disable <name>            # Disable (auto-detect type)
mcp remove <name>             # Remove (auto-detect type)
mcp update <name>             # Update (auto-detect type)
```

**Tasks:**

1. Unified list
   - Show installed MCP servers
   - Show installed plugins
   - Categorize and format

2. Smart enable/disable/remove
   - Detect type from installed list
   - Call appropriate command

**Effort:** 1-2 days
**Deliverable:** Complete management of all extensions

---

## 💎 EXAMPLES: Real World Usage

### Example 1: Discover GitHub Integration

```bash
$ mcp search github

╭─────────────────────────────────────────────╮
│ Search Results: "github" (5 found)          │
╰─────────────────────────────────────────────╯

📦 MCP SERVERS (3):
  [1] mcp-github ⭐
      Official GitHub API integration

  [2] github-mcp-server
      Community GitHub operations

  [3] github-actions-mcp
      Run GitHub Actions workflows

🔌 PLUGINS (2):
  [4] github ⭐
      GitHub workflow automation

  [5] gh-cli-helper
      GitHub CLI wrapper tools

Select (1-5): 1

╭─────────────────────────────────────────────╮
│ Installing: mcp-github                      │
╰─────────────────────────────────────────────╯

🔍 Type: MCP Server
📦 Method: npm (npx)
🔒 Requires: GITHUB_TOKEN

Continue? (y/n): y

✓ Added to ~/.claude/settings.json
✓ Ready to use!

Next steps:
  1. Set GITHUB_TOKEN in environment
  2. Restart Claude Code
  3. Test: Use GitHub tools in conversation
```

---

### Example 2: Browse All Available

```bash
$ mcp browse

# FZF shows ALL extensions (categorized by icon):
>

📦 @modelcontextprotocol/server-filesystem ⭐
📦 mcp-github ⭐
📦 postgres-mcp
📦 docling-mcp-server
🔌 pr-review-toolkit ⭐
🔌 commit-commands ⭐
🔌 feature-dev ⭐
🔌 github ⭐
🔌 code-review

# Preview pane shows context-aware details
# [Enter] to install selected item
```

---

### Example 3: List All Installed

```bash
$ mcp list

╭─────────────────────────────────────────────╮
│ Installed Extensions                        │
╰─────────────────────────────────────────────╯

📦 MCP SERVERS (4):
  ✓ docling           v0.1.0  🟢 enabled
  ✓ statistical-research  v1.0.0  🟢 enabled
  ✓ shell             v1.0.0  🟢 enabled
  ✓ project-refactor  v1.0.0  🟢 enabled

🔌 PLUGINS (3):
  ✓ pr-review-toolkit  v1.0.0  🟢 enabled
  ✓ commit-commands    v1.0.0  🟢 enabled
  ✓ feature-dev        v1.0.0  ⚪ disabled

Total: 7 extensions (6 enabled)
```

---

### Example 4: Quick Add by Name

```bash
$ mcp add postgres

🔍 Searching for "postgres"...

Found multiple matches:
  [1] 📦 postgres-mcp (MCP Server)
  [2] 🔌 postgres-helper (Plugin)

Select (1-2): 1

Installing postgres-mcp (MCP Server)...
✓ Done!
```

---

## ✨ ADVANCED FEATURES (V2+)

### Smart Recommendations

```bash
$ mcp recommend

Based on your R development workflow, you might like:

📦 MCP SERVERS:
  • r-repl-mcp - R interactive sessions
  • rstudio-mcp - RStudio integration

🔌 PLUGINS:
  • r-package-dev - R package development tools
  • quarto-toolkit - Quarto document workflows

Interested? Try: mcp browse r
```

---

### Natural Language Search

```bash
$ mcp search "I need to work with PDFs"

🧠 Interpreting query...

Found PDF-related extensions:

📦 MCP SERVERS:
  [1] docling-mcp-server ⭐
      Advanced PDF processing (OCR, tables, conversion)

🔌 PLUGINS:
  [2] pdf-tools
      PDF manipulation utilities

Best match: [1] docling-mcp-server
```

---

### Update All

```bash
$ mcp update

Checking for updates...

📦 MCP SERVERS:
  ✓ docling: 0.1.0 → 0.2.0 (update available)
  ✓ shell: 1.0.0 (up to date)

🔌 PLUGINS:
  ✓ pr-review-toolkit: 1.0.0 (up to date)

Update docling? (y/n): y
✓ Updated!
```

---

## 🎯 RECOMMENDED APPROACH

### Use Option 1: Smart MCP Dispatcher ⭐⭐⭐

**Why:**

1. ✅ **Least cognitive load** - ONE command for everything
2. ✅ **Natural extension** - Builds on existing `mcp` pattern
3. ✅ **ADHD-friendly** - Don't need to remember types
4. ✅ **Future-proof** - Can add more sources later
5. ✅ **Consistent** - Matches g/r/v dispatcher pattern

**Commands:**

```bash
mcp search <term>             # Unified search
mcp browse                    # Unified browse (fzf)
mcp add <name>                # Smart install (auto-detect)
mcp list                      # List all installed
mcp remove <name>             # Smart remove (auto-detect)
mcp enable/disable <name>     # Smart toggle (auto-detect)
```

**Implementation Priority:**

1. **Week 1:** Unified search + browse
2. **Week 2:** Smart install (auto-detect type)
3. **Week 3:** Unified list + management

---

## 🧪 TESTING STRATEGY

### Unit Tests

```bash
test_search_mcp_registry()      # API search works
test_search_plugin_cache()      # Local search works
test_merge_results()            # Merging works correctly
test_categorize_results()       # Categorization correct
test_detect_type()              # Type detection accurate
```

### Integration Tests

```bash
test_unified_search()           # End-to-end search
test_unified_browse()           # FZF browse works
test_smart_install_mcp()        # Install MCP server
test_smart_install_plugin()     # Install plugin
test_unified_list()             # List shows both types
```

### Manual Tests

```bash
# Search tests
mcp search github               # Should show both
mcp search database             # Multiple results
mcp search nonexistent          # No results

# Browse test
mcp browse                      # Shows all, nice preview

# Install tests
mcp add mcp-github              # MCP server
mcp add pr-review-toolkit       # Plugin
mcp add ambiguous-name          # Disambiguation

# List test
mcp list                        # Shows all installed
```

---

## 📈 SUCCESS METRICS

### MVP (Week 2)

- [ ] Unified search returns both types
- [ ] Browse shows all extensions with categories
- [ ] Install auto-detects type and works
- [ ] User doesn't need to know the distinction

### V2 (Week 4)

- [ ] List shows all installed extensions
- [ ] Enable/disable works for both
- [ ] Update checks both sources
- [ ] Recommendations based on workflow

### Long-term

- [ ] Natural language search
- [ ] Smart conflict detection
- [ ] Usage analytics
- [ ] Community marketplace integration

---

## 🔮 FUTURE POSSIBILITIES

### Plugin + MCP Server Bundles

```bash
$ mcp add github-bundle

This bundle includes:
  📦 mcp-github (Server)
  🔌 github (Plugin)
  🔌 gh-cli-helper (Plugin)

Install all 3? (y/n): y
```

### Dependency Management

```bash
$ mcp add advanced-feature

⚠️  Requires:
  📦 postgres-mcp (not installed)
  🔌 database-tools (not installed)

Install dependencies? (y/n): y
```

### Conflict Detection

```bash
$ mcp add duplicate-feature

⚠️  Similar functionality detected:
  📦 existing-server (installed)
  Provides: Database access

Continue? (y/n): n
```

---

## 💬 OPEN QUESTIONS

1. **Terminology in UI:**
   - Show "MCP Server" or just "Server"?
   - Show "Claude Code Plugin" or just "Plugin"?
   - **Recommendation:** Full names initially, can abbreviate in compact views

2. **Default scope for install:**
   - User scope (global) or Project scope (local)?
   - **Recommendation:** User scope (works everywhere)

3. **Offline mode:**
   - How to handle when registry API is down?
   - **Recommendation:** Cache last search results, show warning

4. **Disambiguation:**
   - If name matches both server and plugin, which to prefer?
   - **Recommendation:** Show both, let user choose

5. **Update strategy:**
   - Auto-update marketplaces on search?
   - **Recommendation:** Update weekly in background, manual `mcp update-sources`

---

## 🎬 IMPLEMENTATION SEQUENCE

### Day 1: Unified Search Core

- [ ] `_unified_search()` function
- [ ] MCP Registry API search
- [ ] Plugin cache search
- [ ] Merge and categorize
- [ ] Display formatted results

### Day 2: FZF Browse

- [ ] Fetch all sources
- [ ] Create fzf list with icons
- [ ] Rich preview pane
- [ ] Test interactive selection

### Day 3: Smart Install

- [ ] Type detection logic
- [ ] Install dispatch (mcp vs plugin)
- [ ] Success confirmation
- [ ] Error handling

### Day 4: Unified List

- [ ] List MCP servers
- [ ] List plugins
- [ ] Merge and format
- [ ] Status indicators (enabled/disabled)

### Day 5: Polish & Documentation

- [ ] Help text (`mcp help`)
- [ ] Update quick reference
- [ ] Write tests
- [ ] User guide

---

**Created:** 2025-12-19
**Next Step:** Implement unified search (Day 1)
**Estimated MVP:** 3-5 days for full unified experience
**Impact:** 🎯 Game-changer for discoverability!
