# MCP Enhancement Roadmap

**Created:** 2025-12-19
**Status:** Ready to implement
**Goal:** Unified discovery and management of MCP servers + Claude Code plugins

---

## 📚 Documentation Index

This roadmap consolidates multiple brainstorming sessions:

1. **PROPOSAL-MCP-ADD-INSTALL.md** - Original MCP server installation proposal
2. **BRAINSTORM-MCP-PLUGIN-COMMAND-INTEGRATION.md** - Plugin/command integration exploration
3. **BRAINSTORM-UNIFIED-MCP-SEARCH.md** - **⭐ RECOMMENDED: Unified search proposal**

---

## 🎯 Final Recommendation: Unified MCP Dispatcher

After extensive research and brainstorming, the recommended approach is:

### **ONE interface for ALL Claude Code extensions**

```bash
# Discovery
mcp search <term>          # Search MCP servers + plugins
mcp browse                 # Interactive fzf (all extensions)

# Installation
mcp add <name>             # Smart install (auto-detects type)

# Management
mcp list                   # List all installed (categorized)
mcp enable <name>          # Enable (auto-detects type)
mcp disable <name>         # Disable (auto-detects type)
mcp remove <name>          # Remove (auto-detects type)

# Info
mcp status                 # Config status (already exists)
mcp help                   # Help (already exists)
```

**Why Unified?**
- ✅ Users don't care about technical distinction (server vs plugin)
- ✅ Reduces cognitive load (one command to remember)
- ✅ Better discovery (250+ extensions searchable)
- ✅ ADHD-friendly (visual categories, instant recognition)
- ✅ Natural extension of existing `mcp` pattern

---

## 🔍 What We Discovered

### Extension Ecosystem

Claude Code has THREE extension systems:

#### 1. MCP Servers (External Processes)
- **Count:** ~200+ servers
- **Source:** https://registry.modelcontextprotocol.io (REST API)
- **Examples:** filesystem, github, postgres, docling
- **Type:** Stdio/SSE/HTTP processes
- **Command:** `claude mcp add/remove/list`
- **Config:** `~/.claude/settings.json`

#### 2. Claude Code Plugins (Bundled Agents/Skills)
- **Count:** ~50+ plugins
- **Sources:** 5 marketplaces
  - `claude-plugins-official` (Anthropic)
  - `claude-code-plugins` (Anthropic)
  - `cc-marketplace` (Community)
  - `every-marketplace` (Every Inc)
  - `matsengrp-marketplace` (Community)
- **Examples:** pr-review-toolkit, commit-commands, feature-dev
- **Type:** Markdown files with agents/skills/commands
- **Command:** `claude plugin install/uninstall/enable/disable`
- **Cache:** `~/.claude/plugins/cache/`

#### 3. User Plugins (Local)
- **Count:** Custom (user-created)
- **Source:** Local directories
- **Command:** `--plugin-dir <path>`
- **Not relevant for search** (local only)

### Total Ecosystem: 250+ Extensions!

---

## 📋 Implementation Plan

### Phase 1: Unified Search (Week 1) - MVP ⭐⭐⭐

**Goal:** `mcp search` and `mcp browse` work for both servers + plugins

#### Day 1: Core Search Function
```bash
mcp search github
# Returns categorized results:
# 📦 MCP SERVERS (2)
# 🔌 PLUGINS (1)
```

**Tasks:**
- [ ] Create `_unified_search()` function
- [ ] Search MCP Registry API (`curl` + `jq`)
- [ ] Search plugin cache (local grep/jq)
- [ ] Merge and categorize results
- [ ] Display with icons and formatting

**Files:**
- `~/.config/zsh/functions/mcp-dispatcher.zsh` - Add `search|s` keyword
- `~/.config/zsh/functions/mcp-registry-api.zsh` - New: Registry API wrapper
- `~/.config/zsh/functions/mcp-plugin-search.zsh` - New: Plugin cache search

**Deliverable:** Working search that shows both types

---

#### Day 2: FZF Browse Interface
```bash
mcp browse
# Interactive fzf with rich preview pane
```

**Tasks:**
- [ ] Fetch all MCP servers from registry
- [ ] Fetch all plugins from marketplaces
- [ ] Create fzf list with category prefixes (📦/🔌)
- [ ] Build rich preview pane script
- [ ] Add preview showing:
  - Name, type, source
  - Description
  - Installation method
  - Requirements (secrets, etc.)
  - Official status

**Files:**
- `~/.config/zsh/functions/mcp-dispatcher.zsh` - Add `browse|b` keyword
- `~/.config/zsh/functions/mcp-preview.zsh` - New: Preview pane formatter

**Deliverable:** Beautiful interactive browser

---

#### Day 3: Smart Install (Type Detection)
```bash
mcp add mcp-github         # Auto-detects: MCP server
mcp add pr-review-toolkit  # Auto-detects: Plugin
```

**Tasks:**
- [ ] Create type detection logic
  - Check MCP Registry first
  - Check plugin marketplaces
  - Return: "mcp" or "plugin"
- [ ] Smart install dispatcher
  - If MCP server → `claude mcp add ...`
  - If plugin → `claude plugin install ...`
- [ ] Security warnings (for MCP servers)
  - Official status
  - Required secrets
  - Repository check
- [ ] Duplicate detection
  - Check installed servers
  - Check installed plugins
  - Warn about similar functionality
- [ ] Success confirmation & testing

**Files:**
- `~/.config/zsh/functions/mcp-dispatcher.zsh` - Update `add|a|install|i` keyword
- `~/.config/zsh/functions/mcp-security.zsh` - New: Security analysis

**Deliverable:** Smart install that handles both types seamlessly

---

### Phase 2: Unified Management (Week 2) ⭐⭐

**Goal:** Manage all extensions with one interface

#### Day 4: Unified List
```bash
mcp list
# Shows:
# 📦 MCP SERVERS (4)
# 🔌 PLUGINS (3)
```

**Tasks:**
- [ ] List MCP servers (`claude mcp list` or parse settings.json)
- [ ] List plugins (`claude plugin` or parse cache)
- [ ] Merge and categorize
- [ ] Format with status indicators (🟢 enabled, ⚪ disabled)
- [ ] Show versions

**Files:**
- `~/.config/zsh/functions/mcp-dispatcher.zsh` - Update `list|l` keyword

**Deliverable:** Unified list showing all installed extensions

---

#### Day 5: Smart Management Commands
```bash
mcp enable <name>          # Auto-detect type
mcp disable <name>         # Auto-detect type
mcp remove <name>          # Auto-detect type
```

**Tasks:**
- [ ] Type detection from installed list
- [ ] Enable dispatcher
  - MCP server → Edit settings.json (uncomment)
  - Plugin → `claude plugin enable`
- [ ] Disable dispatcher
  - MCP server → Edit settings.json (comment)
  - Plugin → `claude plugin disable`
- [ ] Remove dispatcher
  - MCP server → `claude mcp remove`
  - Plugin → `claude plugin uninstall`
- [ ] Confirmation prompts
- [ ] Success/error handling

**Files:**
- `~/.config/zsh/functions/mcp-dispatcher.zsh` - Add `enable|disable|remove` keywords

**Deliverable:** Complete management of all extensions

---

### Phase 3: Polish & Documentation (Week 2-3) ⭐

#### Day 6: Testing & Quality
**Tasks:**
- [ ] Write test suite
  - Search tests (API + cache)
  - Browse tests (fzf + preview)
  - Install tests (both types)
  - Management tests
- [ ] Error handling
  - Network errors (registry down)
  - Missing dependencies (jq, fzf)
  - Invalid names
- [ ] Performance optimization
  - Cache registry results
  - Parallel searches

**Files:**
- `~/.config/zsh/tests/test-mcp-unified-search.zsh` - New: Test suite

---

#### Day 7: Documentation
**Tasks:**
- [ ] Update `mcp help` with new commands
- [ ] Update quick-reference.md
- [ ] Update CONVENTIONS.md
- [ ] Update MCP-DISPATCHER-DOCUMENTATION-UPDATE.md
- [ ] Create user guide with examples
- [ ] Update README files

**Files:**
- `~/.config/zsh/functions/mcp-dispatcher.zsh` - Update `_mcp_help()`
- `~/projects/dev-tools/zsh-configuration/zsh/help/quick-reference.md`
- `~/projects/dev-tools/zsh-configuration/docs/CONVENTIONS.md`

---

### Phase 4: Advanced Features (Week 3+) - Optional ⭐

#### Optional Feature 1: Natural Language Search
```bash
mcp search "I need to work with PDFs"
# Semantic search using fuzzy matching or Claude
```

#### Optional Feature 2: Recommendations
```bash
mcp recommend
# Based on installed servers, suggest related extensions
```

#### Optional Feature 3: Update Management
```bash
mcp update <name>          # Update specific extension
mcp update                 # Update all extensions
```

#### Optional Feature 4: Bundles
```bash
mcp add github-bundle
# Installs related servers + plugins together
```

---

## 🎨 UI Examples

### Example 1: Unified Search

```bash
$ mcp search github

╭─────────────────────────────────────────────────────────────────────╮
│ Search Results: "github" (5 found)                                  │
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
│ [3] github-actions-mcp      Community | 📦 npm                     │
│     Run GitHub Actions workflows                                    │
│                                                                      │
│ 🔌 CLAUDE CODE PLUGINS                                              │
│ ─────────────────────────────────────────────────────────────────── │
│ [4] github                  ⭐ Official | 💻 Skills: 5             │
│     GitHub workflow tools & automation                              │
│                                                                      │
│ [5] gh-cli-helper           Community | 💻 Skills: 3              │
│     GitHub CLI wrapper utilities                                    │
│                                                                      │
╰─────────────────────────────────────────────────────────────────────╯

Select number (1-5), 'b' to browse all, 'c' to cancel: _
```

---

### Example 2: FZF Browse

```bash
$ mcp browse

# FZF interface with preview:
> github

📦 mcp-github (Official ⭐)
📦 github-mcp-server
📦 github-actions-mcp
🔌 github (Official ⭐)
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

---

### Example 3: Unified List

```bash
$ mcp list

╭─────────────────────────────────────────────╮
│ Installed Extensions                        │
╰─────────────────────────────────────────────╯

📦 MCP SERVERS (4):
  ✓ docling              v0.1.0  🟢 enabled
  ✓ statistical-research v1.0.0  🟢 enabled
  ✓ shell                v1.0.0  🟢 enabled
  ✓ project-refactor     v1.0.0  🟢 enabled

🔌 CLAUDE CODE PLUGINS (3):
  ✓ pr-review-toolkit    v1.0.0  🟢 enabled
  ✓ commit-commands      v1.0.0  🟢 enabled
  ✓ feature-dev          v1.0.0  ⚪ disabled

Total: 7 extensions (6 enabled, 1 disabled)
```

---

## 📊 Success Metrics

### Week 1 MVP
- [x] MCP v2.0 migration complete (dispatcher pattern)
- [x] Documentation updated
- [x] Tests passing (12/12)
- [ ] Unified search working (servers + plugins)
- [ ] FZF browse with rich preview
- [ ] Smart install (type detection)

### Week 2 Complete
- [ ] Unified list showing all extensions
- [ ] Enable/disable working for both types
- [ ] Remove working for both types
- [ ] Full test coverage
- [ ] Documentation complete

### Long-term Goals
- [ ] Natural language search
- [ ] Recommendation engine
- [ ] Update management
- [ ] Bundle support

---

## 🛠️ Technical Stack

### Required Tools
- ✅ `curl` - API requests (installed)
- ✅ `jq` - JSON parsing (installed)
- ✅ `fzf` - Interactive selection (installed)
- ✅ `claude` - Claude Code CLI (installed)
- ✅ ZSH - Shell environment

### File Structure
```
~/.config/zsh/functions/
├── mcp-dispatcher.zsh         # Main dispatcher (exists, will extend)
├── mcp-registry-api.zsh       # New: MCP Registry API wrapper
├── mcp-plugin-search.zsh      # New: Plugin cache search
├── mcp-security.zsh           # New: Security analysis
└── mcp-preview.zsh            # New: FZF preview pane

~/.config/zsh/tests/
├── test-mcp-dispatcher.zsh    # Exists (12/12 passing)
└── test-mcp-unified-search.zsh # New: Unified search tests
```

---

## 🔗 Related Documentation

### Created During This Session
1. `PROPOSAL-MCP-ADD-INSTALL.md` - MCP server installation (original)
2. `BRAINSTORM-MCP-PLUGIN-COMMAND-INTEGRATION.md` - Plugin integration (exploration)
3. `BRAINSTORM-UNIFIED-MCP-SEARCH.md` - **⭐ Unified search (recommended)**
4. `MCP-V2-MIGRATION-COMPLETE.md` - v2.0 migration summary
5. `MCP-DISPATCHER-DOCUMENTATION-UPDATE.md` - Documentation update log
6. `PROPOSAL-MCP-DISPATCHER-STANDARDS.md` - Standards analysis

### Existing Documentation
- `~/projects/dev-tools/zsh-configuration/ZSH-MCP-FUNCTIONS.md`
- `~/projects/dev-tools/zsh-configuration/docs/CONVENTIONS.md`
- `~/projects/dev-tools/_MCP_SERVERS.md`
- `~/projects/dev-tools/mcp-servers/README.md`

---

## ✅ Next Steps

### Immediate (Before Implementation)
1. [x] Create roadmap document (this file)
2. [ ] Update planning docs with recommendation
3. [ ] Commit and push all proposals
4. [ ] Review and approve approach

### Week 1 Implementation
1. [ ] Day 1: Core search function
2. [ ] Day 2: FZF browse
3. [ ] Day 3: Smart install

---

**Status:** Ready to implement
**Estimated Total:** 2-3 weeks for complete implementation
**MVP Ready:** End of Week 1
**Next Action:** Commit proposals, then begin Day 1 implementation

---

**Created:** 2025-12-19
**Last Updated:** 2025-12-19
**Ready for:** Implementation! 🚀
