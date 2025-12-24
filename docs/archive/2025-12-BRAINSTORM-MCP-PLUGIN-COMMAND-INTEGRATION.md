# Brainstorm: MCP Plugin/Command Integration

**Date:** 2025-12-19
**Context:** Exploring plugin functionality for MCP dispatcher
**Location:** flow-cli/zsh/tests
**Branch:** dev (10 uncommitted files)

---

## 🎯 Understanding the Question

**Interpreted Requirements:**

1. Add plugin discovery/management to `mcp` dispatcher
2. Support interactive sessions (like `/plugin` slash commands)
3. Decide: keyword vs separate command
4. Intelligent search (like `claude -p "prompt"`)

**Contexts to Consider:**

- Claude Code has native plugin support (MCP servers ARE plugins)
- ZSH dispatcher pattern (`mcp <keyword>`)
- Interactive vs non-interactive modes
- ADHD-friendly workflow

---

## 💡 BRAINSTORM: All Ideas (Quantity over Quality)

### Category 1: Command Structure Options

#### 1.1 Keyword in MCP Dispatcher ⭐

```bash
mcp plugin <action>           # Nested under mcp
mcp plugin list
mcp plugin search <term>
mcp plugin install <name>
mcp plugin enable <name>
mcp plugin disable <name>
```

**Pros:**

- Consistent with `mcp` pattern
- Centralizes all MCP-related commands
- Clear hierarchy: mcp → servers → plugins
- Short form: `mcp p` (conflicts with `mcp pick`)

**Cons:**

- `mcp p` conflicts with existing `mcp pick`
- Two-word commands (longer to type)
- Might confuse servers vs plugins

#### 1.2 Separate Top-Level Command

```bash
plugin <action>               # New top-level command
plugin list
plugin search <term>
plugin install <name>
plugin run <name>
```

**Pros:**

- Clear, dedicated namespace
- Shorter: `plugin search` vs `mcp plugin search`
- No conflicts with `mcp pick`
- Room for expansion

**Cons:**

- Breaks the "everything MCP under mcp" pattern
- Another top-level command to remember
- Might be confusing (what's the difference between mcp server and plugin?)

#### 1.3 Hybrid: Short Alias + Long Form

```bash
mcp plugin <action>           # Long form
plg <action>                  # Short alias (3 chars)
pg <action>                   # Ultra-short (2 chars) ⚠️ might conflict
```

**Example:**

```bash
plg search github             # Quick search
plg install mcp-github        # Quick install
mcp plugin list               # Documentation uses long form
```

**Pros:**

- Best of both worlds
- Short for daily use, clear for docs
- ADHD-friendly (fewer keystrokes)
- Follows existing pattern (g→git, r→R, v→vibe)

**Cons:**

- Two ways to do the same thing
- Need to document both

#### 1.4 Extend Existing Keywords ⭐⭐

```bash
mcp add <search>              # Search registry & install (already planned!)
mcp search <term>             # Search registry
mcp browse                    # Interactive browser
mcp enable <name>             # Enable installed server
mcp disable <name>            # Disable without removing
```

**Pros:**

- Leverages work we're already doing (`mcp add`)
- No new top-level commands
- Natural extension of mcp
- Fits the "plugin" concept (servers = plugins)

**Cons:**

- Could get crowded with keywords
- Might blur server vs plugin distinction

#### 1.5 Interactive Menu System

```bash
mcp plugins                   # Opens interactive TUI
# Or
mcp menu                      # General interactive menu
```

**TUI would show:**

```
╭─────────────────────────────────────────────╮
│ MCP Plugin Manager                          │
╰─────────────────────────────────────────────╯

[1] Browse Registry (200+ plugins)
[2] Installed Plugins (4)
[3] Search for Plugin
[4] Add New Plugin
[5] Manage Installed

> _
```

**Pros:**

- ADHD-friendly (visual, discoverable)
- No need to remember keywords
- Can show rich info (descriptions, stats)
- Similar to `fzf` pattern already used

**Cons:**

- Requires interactive terminal
- Harder to script
- More complex to implement

### Category 2: Interactive Session Features

#### 2.1 Slash Commands in MCP Context

```bash
# Start interactive MCP session
mcp interactive               # or: mcp i

# Inside session:
/plugin search github         # Search plugins
/plugin install mcp-github    # Install plugin
/server list                  # List servers
/server test docling          # Test server
/help                         # Show commands
/exit                         # Exit session
```

**Pros:**

- Familiar pattern (Discord, Slack, Obsidian)
- Keeps complex workflows organized
- Can maintain state across commands
- Natural for exploration

**Cons:**

- Another mode to maintain
- Might be overkill for simple tasks
- Adds complexity

#### 2.2 REPL-Style Interface

```bash
mcp shell                     # Start MCP shell

mcp> search github
mcp> install mcp-github
mcp> test mcp-github
mcp> enable mcp-github
mcp> exit
```

**Pros:**

- Clear context (you're "in" mcp)
- Can have persistent state
- Tab completion possible
- Good for multi-step workflows

**Cons:**

- Yet another shell to learn
- Maintenance burden
- Might confuse users

#### 2.3 Prompt-Based Interface (Claude CLI Style) ⭐⭐

```bash
mcp -p "find a github plugin and install it"
# Claude interprets, searches, shows options, installs

mcp -p "what servers do I have installed?"
# Lists servers with descriptions

mcp -p "test all my servers"
# Runs test on each server

mcp --prompt "add a postgres database plugin"
# Searches, presents options, installs
```

**Pros:**

- Natural language (very ADHD-friendly!)
- Leverages Claude's intelligence
- Flexible, handles edge cases
- Can combine multiple actions

**Cons:**

- Requires Claude API access
- Might be slow for simple tasks
- Unpredictable behavior
- Cost concerns (API calls)

#### 2.4 Hybrid: Both Direct + Intelligent

```bash
# Direct commands (fast, predictable)
mcp search github
mcp install mcp-github

# Intelligent mode (flexible, exploratory)
mcp -p "help me find a plugin for database access"
mcp --ask "which of my servers are for R development?"
```

**Pros:**

- Power users get speed
- Newcomers get guidance
- Best of both worlds
- Graceful learning curve

**Cons:**

- Two systems to maintain
- Might fragment user base

### Category 3: Search & Discovery

#### 3.1 Fuzzy Search with FZF ⭐⭐⭐

```bash
mcp browse                    # Opens fzf with all registry servers

# Preview pane shows:
# - Description
# - Installation method
# - Security info
# - Similar servers
```

**Pros:**

- Already have fzf in mcp (mcp pick)
- Visual, interactive
- Fast fuzzy search
- Preview pane = rich info
- ADHD-friendly (don't need to know exact name)

**Cons:**

- Limited to terminal width
- Can't show complex layouts

#### 3.2 Tags/Category System

```bash
mcp search --tag database     # All database plugins
mcp search --tag ai           # All AI plugins
mcp search --category dev     # Development tools

# Or combined:
mcp browse database           # Filter by category in fzf
```

**Pros:**

- Organized discovery
- Easier to find relevant plugins
- Can combine with fzf

**Cons:**

- Registry needs tag metadata
- Manual categorization needed

#### 3.3 Recommendation Engine

```bash
mcp recommend                 # Based on installed servers

# Output:
# Based on your installed servers (statistical-research, shell),
# you might like:
#   1. mcp-r-repl (R development)
#   2. mcp-python-repl (Similar to shell)
#   3. mcp-jupyter (Data science)
```

**Pros:**

- Helps discovery
- Personalized
- Reduces decision paralysis (ADHD win!)

**Cons:**

- Complex algorithm
- Needs usage tracking
- Privacy concerns

#### 3.4 Natural Language Search ⭐

```bash
mcp search "something that can read PDFs"
# Uses semantic search or Claude to find docling

mcp search "I need to query databases"
# Finds postgres, mysql, sqlite plugins
```

**Pros:**

- Very natural
- No need to know exact terms
- Handles synonyms

**Cons:**

- Requires NLP or Claude API
- Might return unexpected results
- Slower than direct search

### Category 4: Plugin vs Server Terminology

#### 4.1 Keep "Server" Terminology

```bash
mcp add <name>                # Add server
mcp list                      # List servers
mcp search                    # Search servers
```

**Rationale:** MCP servers ARE the plugins. No need for separate concept.

**Pros:**

- Consistent with MCP spec
- Less confusing
- Matches Claude Code terminology

**Cons:**

- "Server" sounds heavyweight
- Might confuse non-technical users

#### 4.2 Use "Plugin" Terminology

```bash
mcp plugin add
mcp plugin list
```

**Rationale:** More familiar to users, sounds lighter

**Pros:**

- Familiar concept (VS Code plugins, browser plugins)
- Feels more approachable
- Less technical jargon

**Cons:**

- Conflicts with MCP spec terminology
- Might confuse with Claude Code's actual plugins

#### 4.3 Hybrid: Context-Aware

```bash
# For users:
mcp plugins                   # Friendlier term

# For developers:
mcp servers                   # Technical term

# Both work, map to same thing
```

#### 4.4 Avoid the Term Entirely ⭐⭐

```bash
mcp add <name>                # Just "add"
mcp search <term>             # Just "search"
mcp list                      # Just "list"
```

**Rationale:** Let the context be implicit. We're in `mcp`, so it's obvious we're talking about MCP things.

**Pros:**

- Shorter commands
- Less cognitive load
- More Unix-like

**Cons:**

- Might be ambiguous in docs

### Category 5: Enable/Disable vs Install/Remove

#### 5.1 Install/Remove Only (Current)

```bash
mcp add <name>                # Install
mcp remove <name>             # Remove completely
```

**Pros:**

- Simple, clear
- Binary state (installed or not)
- Easy to understand

**Cons:**

- No way to temporarily disable
- Removing might lose config

#### 5.2 Add Enable/Disable ⭐⭐

```bash
mcp add <name>                # Install
mcp enable <name>             # Enable (if disabled)
mcp disable <name>            # Disable (but keep installed)
mcp remove <name>             # Remove completely
```

**Pros:**

- Temporary disable for testing
- Keep config when disabled
- Useful for troubleshooting

**Cons:**

- More state to track
- More commands to remember

#### 5.3 Toggle Command

```bash
mcp toggle <name>             # Enable if disabled, disable if enabled
mcp add <name>                # Install
mcp remove <name>             # Remove
```

**Pros:**

- Quick switching
- One command to remember

**Cons:**

- Not always clear what state you're in
- Might be confusing

### Category 6: Integration with Claude Code

#### 6.1 Wrapper Around Native Commands ⭐

```bash
# Our mcp dispatcher calls:
claude mcp add <args>         # Under the hood
claude mcp remove <args>
claude mcp list
```

**Pros:**

- Leverages official tools
- Always compatible
- Less maintenance

**Cons:**

- Limited by Claude Code's interface
- Can't add features Claude doesn't have

#### 6.2 Direct Config Management

```bash
# Our mcp dispatcher directly edits:
~/.claude/settings.json       # User scope
.claude/settings.local.json   # Project scope
```

**Pros:**

- Full control
- Can add custom features
- No dependency on Claude Code

**Cons:**

- Breaks if Claude Code changes config format
- Might conflict with native tools

#### 6.3 Hybrid ⭐⭐

```bash
# Use native for CRUD:
claude mcp add/remove/list    # Delegate to official

# Add intelligence on top:
mcp search                    # Our feature (registry search)
mcp browse                    # Our feature (fzf)
mcp recommend                 # Our feature (recommendations)
```

**Pros:**

- Best of both worlds
- Official tool handles config
- We add value on top

**Cons:**

- Two systems to coordinate

---

## 🎨 PERSPECTIVE ANALYSIS

### Technical Perspective

**Constraints:**

- Must work with `~/.claude/settings.json` format
- Registry API has rate limits (100 req/min)
- FZF is already a dependency
- ZSH function limits (can't be too complex)

**Opportunities:**

- Registry API is stable and documented
- Can use jq for JSON parsing
- Already have `mcp pick` as fzf template
- Can leverage existing Claude Code CLI

**Recommended:**

- Extend `mcp` dispatcher with new keywords
- Use registry API for search
- Leverage fzf for interactive browsing
- Wrap `claude mcp add` for installation

### UX Perspective

**Pain Points:**

- Finding relevant plugins is hard
- Not knowing what's available
- Fear of installing wrong thing
- Managing many plugins

**Solutions:**

- Intelligent search (fuzzy, semantic)
- Interactive browsing (fzf with preview)
- Security warnings (before install)
- Enable/disable (instead of remove)

**Recommended:**

- `mcp browse` - interactive discovery
- `mcp search <term>` - quick search
- `mcp add <name>` - guided install
- Preview pane shows security info

### ADHD-Friendly Perspective

**Principles:**

- Minimize decisions
- Fast feedback
- Visual > text
- Discoverable (don't require docs)
- Forgiving (undo mistakes)

**Anti-patterns:**

- Long command names
- Too many options
- Hidden features
- Irreversible actions

**Recommended:**

- Single command for common tasks: `mcp browse`
- Visual interface: fzf with rich preview
- Quick wins: `mcp add github` just works
- Safety: `mcp disable` instead of remove
- Smart defaults: auto-select if one match

### Maintenance Perspective

**Keep It Simple:**

- Fewer keywords = less to maintain
- Leverage existing tools (fzf, jq, curl)
- Delegate to Claude Code where possible
- Don't reinvent registry (use official API)

**Avoid:**

- Custom REPL (complex state management)
- Local database (gets outdated)
- Complex recommendation engine
- Multiple aliases for same thing

**Recommended:**

- 5-7 new keywords max
- Reuse `mcp pick` pattern for browse
- Wrap `claude mcp` for install/remove
- Use registry API (no local cache)

### Future Scalability

**Growth Areas:**

- More plugins in registry (currently ~200)
- Plugin dependencies
- Plugin updates
- Plugin marketplace
- Plugin ratings/reviews

**Prepare For:**

- Pagination (registry will grow)
- Filtering (by category, tag, language)
- Versioning (plugin updates)
- Conflict resolution (similar plugins)

**Don't Over-Engineer:**

- Start simple, add features based on usage
- Don't build complex features speculatively
- Follow 80/20 rule (most common use cases)

---

## 🏆 TOP IDEAS (Organized by Promise)

### ⭐⭐⭐ MUST HAVE (MVP)

#### 1. Extend MCP Dispatcher with Search Keywords

```bash
mcp search <term>             # Search registry
mcp browse                    # Interactive fzf browser
mcp add <name>                # Smart install (already planned)
```

**Why:**

- Natural extension of existing pattern
- Leverages `mcp add` work already planned
- Minimal new concepts
- ADHD-friendly (few keywords)

**Implementation:**

- Add `search|s` keyword to mcp dispatcher
- Add `browse|b` keyword
- Reuse fzf pattern from `mcp pick`
- Call registry API

**Effort:** 1-2 days

---

#### 2. Rich FZF Preview for Browse

```bash
mcp browse

# FZF shows:
# > mcp-github (Official ⭐)
#   mcp-postgres
#   docling-mcp-server
#
# Preview pane:
# ╭─────────────────────────────────╮
# │ mcp-github                      │
# ├─────────────────────────────────┤
# │ GitHub integration for MCP      │
# │                                 │
# │ 📦 npm | 🔒 Requires: token    │
# │ ⭐ Official Anthropic          │
# │ 🔗 github.com/mcp/github       │
# │                                 │
# │ Features:                       │
# │ - Repository management         │
# │ - Issue tracking                │
# │ - PR operations                 │
# ╰─────────────────────────────────╯
```

**Why:**

- Visual, discoverable
- Shows all info needed to decide
- Familiar pattern (already use fzf)
- Reduces decision paralysis

**Implementation:**

- Fetch registry data
- Format for fzf
- Create preview script
- Pipe to fzf with --preview

**Effort:** 1 day

---

#### 3. Security Warnings in Add Flow

```bash
mcp add suspicious-plugin

⚠️  Security Review:
  ❌ Not official
  ⚠️  No repository
  🔒 Requires: API_KEY, DATABASE_URL

Continue? (y/n): _
```

**Why:**

- Prevents security mistakes
- Builds trust in system
- Educational (users learn what to look for)

**Implementation:**

- Parse registry metadata
- Check for official status
- List required secrets
- Prompt for confirmation

**Effort:** 0.5 days

---

### ⭐⭐ SHOULD HAVE (V2)

#### 4. Enable/Disable Commands

```bash
mcp enable <name>             # Enable disabled server
mcp disable <name>            # Disable without removing
```

**Why:**

- Temporary testing
- Troubleshooting
- Keep config when disabled

**Implementation:**

- Comment out in settings.json
- Track disabled state
- Easy to re-enable

**Effort:** 0.5 days

---

#### 5. Natural Language Search

```bash
mcp search "read PDFs"        # Finds docling
mcp search "database"         # Finds postgres, mysql, etc.
```

**Why:**

- Don't need exact names
- Handles synonyms
- More forgiving

**Implementation:**

- Search registry description field
- Use fuzzy matching
- Maybe call Claude for semantic search

**Effort:** 1 day

---

#### 6. Similar Server Detection

```bash
mcp add filesystem

⚠️  Similar servers found:
  - shell (can access filesystem via commands)
  - docling (can read files)

Continue? (y/n): _
```

**Why:**

- Prevents duplicates
- Suggests alternatives
- Educational

**Implementation:**

- Tag-based similarity
- Description matching
- Capability overlap detection

**Effort:** 1 day

---

### ⭐ NICE TO HAVE (V3+)

#### 7. Recommendations

```bash
mcp recommend

Based on your R development work:
  1. mcp-r-repl
  2. mcp-rstudio-connect
  3. mcp-quarto
```

**Why:**

- Helps discovery
- Personalized
- Reduces choice paralysis

**Implementation:**

- Analyze installed servers
- Match to registry tags
- Show related plugins

**Effort:** 2 days

---

#### 8. Prompt-Based Interface

```bash
mcp -p "find me a github plugin"
# Uses Claude to search, present, install
```

**Why:**

- Very natural
- Handles complex queries
- Flexible

**Implementation:**

- Pass prompt to Claude
- Claude calls mcp tools
- Interactive conversation

**Effort:** 3-4 days (requires Claude integration)

---

#### 9. Interactive Session Mode

```bash
mcp shell

mcp> search github
mcp> install mcp-github
mcp> test mcp-github
```

**Why:**

- Multi-step workflows
- Persistent state
- Tab completion

**Implementation:**

- Custom REPL
- Command parser
- State management

**Effort:** 5-7 days (complex)

---

## 🔄 COMBINATIONS THAT WORK WELL TOGETHER

### Combo A: Search + Browse + Add (MVP) ⭐⭐⭐

```bash
# Quick search
mcp search github

# Visual browse
mcp browse

# Smart install
mcp add mcp-github
```

**Why:** Covers 80% of use cases, minimal complexity

---

### Combo B: Add Natural Language (V2) ⭐⭐

```bash
mcp search "github integration"   # Natural language
mcp browse                         # If unsure, browse visually
mcp add mcp-github                 # Install what you find
```

**Why:** More forgiving, better for exploration

---

### Combo C: Add Prompt Interface (V3) ⭐

```bash
mcp -p "I need GitHub integration"
# Claude handles search, shows options, installs
```

**Why:** Ultimate ease, but requires Claude API

---

## ⚠️ TRADE-OFFS & CONSTRAINTS

### Trade-off 1: Command Structure

| Option                | Brevity      | Clarity    | Conflicts  |
| --------------------- | ------------ | ---------- | ---------- |
| `mcp plugin <action>` | ❌ Long      | ✅ Clear   | ⚠️ `mcp p` |
| `plugin <action>`     | ✅ Medium    | ✅ Clear   | ✅ None    |
| `plg <action>`        | ✅✅ Short   | ❌ Cryptic | ✅ None    |
| `mcp <action>`        | ✅✅✅ Short | ✅ Clear   | ⚠️ Crowded |

**Recommendation:** `mcp <action>` (extend dispatcher)

**Rationale:**

- Already doing `mcp add` (planned)
- Keeps MCP stuff together
- Short commands
- Can use short forms: `mcp s` (search), `mcp b` (browse)

---

### Trade-off 2: Interactive vs Direct

| Feature       | Interactive (fzf, REPL) | Direct (commands)       |
| ------------- | ----------------------- | ----------------------- |
| Speed         | Slower (navigate UI)    | Faster (direct)         |
| Discovery     | ✅ Better               | ❌ Need to know command |
| Scriptable    | ❌ Hard                 | ✅ Easy                 |
| ADHD-friendly | ✅ Visual               | ⚠️ Requires memory      |

**Recommendation:** Hybrid

- Interactive for discovery: `mcp browse`
- Direct for automation: `mcp add <name>`

---

### Trade-off 3: Natural Language Cost

| Approach        | Cost         | Speed | Accuracy  |
| --------------- | ------------ | ----- | --------- |
| Exact match     | Free         | Fast  | ❌ Low    |
| Fuzzy match     | Free         | Fast  | ⚠️ Medium |
| Claude semantic | 💰 API costs | Slow  | ✅ High   |

**Recommendation:** Start with fuzzy, add Claude later

- V1: Fuzzy search (free, fast)
- V2: Optional Claude mode with `mcp -p`

---

## 🎯 QUICK WINS VS LONG-TERM

### ⚡ Quick Wins (< 1 day each)

1. **`mcp search <term>`** - Simple registry API call

   ```bash
   curl "https://registry.modelcontextprotocol.io/v0.1/servers?search=$term" | jq
   ```

2. **`mcp browse`** - Reuse fzf pattern

   ```bash
   # Fetch all servers, pipe to fzf
   _mcp_browse() {
       curl -s "https://registry.modelcontextprotocol.io/v0.1/servers?limit=1000" \
           | jq -r '.servers[] | .server.name + " - " + .server.description' \
           | fzf
   }
   ```

3. **Security warnings** - Parse JSON metadata
   ```bash
   # Check for official status
   if [[ "$official_status" != "active" ]]; then
       echo "⚠️  Not officially vetted"
   fi
   ```

### 🏗️ Long-Term Projects (> 3 days)

1. **Recommendation engine** - Requires analysis of installed servers, tagging system, scoring algorithm

2. **Interactive REPL** - Custom shell, state management, tab completion

3. **Claude integration** - API setup, prompt engineering, cost management

4. **Plugin marketplace UI** - Web interface, ratings, reviews (out of scope for CLI)

---

## 📋 CONCRETE NEXT STEPS FOR TOP 3

### #1: Extend MCP Dispatcher with Search/Browse ⭐⭐⭐

**First Steps:**

1. Add keywords to `mcp-dispatcher.zsh`:

   ```zsh
   search|s) shift; _mcp_search "$@" ;;
   browse|b) shift; _mcp_browse "$@" ;;
   ```

2. Implement `_mcp_search()`:

   ```zsh
   _mcp_search() {
       local term="$1"
       curl -s "https://registry.modelcontextprotocol.io/v0.1/servers?search=$term&version=latest" \
           | jq -r '.servers[] | "\(.server.name) - \(.server.description)"'
   }
   ```

3. Implement `_mcp_browse()`:

   ```zsh
   _mcp_browse() {
       local servers=$(curl -s "https://registry.modelcontextprotocol.io/v0.1/servers?limit=200&version=latest")

       echo "$servers" \
           | jq -r '.servers[] | .server.name' \
           | fzf --preview "_mcp_preview_server {}"
   }
   ```

4. Test:
   ```bash
   mcp search github
   mcp browse
   ```

**Effort:** 4-6 hours
**Dependencies:** curl, jq, fzf (all available)

---

### #2: Rich FZF Preview ⭐⭐

**First Steps:**

1. Create preview script `_mcp_preview_server()`:

   ```zsh
   _mcp_preview_server() {
       local name="$1"
       local data=$(curl -s "https://registry.modelcontextprotocol.io/v0.1/servers?search=$name&version=latest" | jq '.servers[0]')

       # Format output
       echo "╭─────────────────────────────────╮"
       echo "│ $(echo $data | jq -r '.server.name') "
       echo "├─────────────────────────────────┤"
       echo "│ $(echo $data | jq -r '.server.description') "
       # ... more formatting
   }
   ```

2. Update `_mcp_browse()` to use preview:

   ```zsh
   fzf --preview "_mcp_preview_server {}" \
       --preview-window right:50%
   ```

3. Add color coding:
   - ⭐ Official servers
   - 🔒 Requires secrets
   - 📦 Installation method

**Effort:** 3-4 hours
**Dependencies:** jq for JSON parsing

---

### #3: Security Warnings in Add ⭐⭐

**First Steps:**

1. Update `_mcp_add()` to fetch server metadata:

   ```zsh
   _mcp_add() {
       local name="$1"
       local data=$(curl -s "https://registry.modelcontextprotocol.io/v0.1/servers/$name")

       # Check official status
       local status=$(echo $data | jq -r '._meta."io.modelcontextprotocol.registry/official".status')

       if [[ "$status" != "active" ]]; then
           echo "⚠️  Not officially vetted"
       fi
   }
   ```

2. Check for secrets:

   ```zsh
   local secrets=$(echo $data | jq -r '.server.packages[].environmentVariables[] | select(.isSecret==true) | .name')

   if [[ -n "$secrets" ]]; then
       echo "🔒 Requires secrets:"
       echo "$secrets" | while read secret; do
           echo "  - $secret"
       done
   fi
   ```

3. Prompt for confirmation:
   ```zsh
   read -r "confirm?Continue installation? (y/n): "
   if [[ "$confirm" != "y" ]]; then
       return 1
   fi
   ```

**Effort:** 2-3 hours
**Dependencies:** jq

---

## 🎬 RECOMMENDED IMPLEMENTATION SEQUENCE

### Phase 1: MVP (Week 1) - Core Search & Browse

```bash
mcp search <term>             # Simple search
mcp browse                    # Basic fzf (no preview)
mcp add <name>                # Already planned
```

**Effort:** 1 day
**Goal:** Basic discovery works

---

### Phase 2: Enhanced Discovery (Week 2) - Rich UI

```bash
mcp browse                    # With rich preview pane
mcp search <term>             # With security indicators
mcp add <name>                # With security warnings
```

**Effort:** 2 days
**Goal:** Beautiful, informative interface

---

### Phase 3: Intelligence (Week 3) - Smart Features

```bash
mcp search "natural language" # Semantic search
mcp add <name>                # Duplicate detection
mcp enable/disable            # Toggle servers
```

**Effort:** 2-3 days
**Goal:** Intelligent guidance

---

### Phase 4: Advanced (Week 4+) - Optional

```bash
mcp recommend                 # Recommendations
mcp -p "prompt"               # Claude integration
mcp update                    # Update servers
```

**Effort:** 3-5 days
**Goal:** Power user features

---

## 📊 DECISION MATRIX

| Feature             | ADHD Score | Effort    | Value | Priority |
| ------------------- | ---------- | --------- | ----- | -------- |
| `mcp search`        | ⭐⭐⭐     | Low       | High  | 🔥 MVP   |
| `mcp browse` (fzf)  | ⭐⭐⭐     | Low       | High  | 🔥 MVP   |
| Rich preview        | ⭐⭐⭐     | Med       | High  | 🔥 MVP   |
| Security warnings   | ⭐⭐       | Low       | High  | 🔥 MVP   |
| Enable/disable      | ⭐⭐       | Low       | Med   | ⭐ V2    |
| Natural lang search | ⭐⭐⭐     | Med       | Med   | ⭐ V2    |
| Duplicate detection | ⭐⭐       | Med       | Med   | ⭐ V2    |
| Recommendations     | ⭐⭐       | High      | Low   | ⚪ V3    |
| Claude integration  | ⭐⭐⭐     | High      | Med   | ⚪ V3    |
| Interactive REPL    | ⭐         | Very High | Low   | ❌ Skip  |

**ADHD Score:** How well does it reduce cognitive load?
**Effort:** Implementation time
**Value:** Impact on user workflow
**Priority:** 🔥 MVP, ⭐ V2, ⚪ V3, ❌ Skip

---

## 💡 FINAL RECOMMENDATION

### Start With: Option A - Extended MCP Dispatcher ⭐⭐⭐

**Commands:**

```bash
mcp search <term>             # Search registry (new)
mcp browse                    # Interactive fzf (new)
mcp add <name>                # Smart install (already planned)
mcp list                      # List installed (exists)
mcp test <name>               # Test server (exists)
mcp remove <name>             # Remove server (new)
```

**Short forms:**

```bash
mcp s <term>                  # search
mcp b                         # browse
mcp a <name>                  # add
```

**Why This Is Best:**

1. ✅ Natural extension of existing pattern
2. ✅ Leverages work already planned (`mcp add`)
3. ✅ ADHD-friendly (visual, discoverable)
4. ✅ Low maintenance (uses official registry)
5. ✅ Scalable (can add features incrementally)
6. ✅ Fast to implement (MVP in 1-2 days)

**Implementation Order:**

1. Day 1: `mcp search` + basic `mcp browse`
2. Day 2: Rich preview pane + security warnings
3. Day 3: Polish + documentation + tests

---

## 📝 OPEN QUESTIONS

1. **Terminology:** Should we say "plugin" or "server" in UI?
   - **Recommendation:** Use "server" (matches MCP spec)
   - But be flexible in search (accept "plugin" as synonym)

2. **Scope:** Should `mcp add` default to --scope user or --scope local?
   - **Recommendation:** User scope (global, works everywhere)
   - Let user specify `--scope local` if needed

3. **Updates:** How to handle server updates?
   - **Recommendation:** Add `mcp update <name>` in V2
   - Check registry for newer versions

4. **Conflicts:** What if two servers provide same functionality?
   - **Recommendation:** Warn user, let them decide
   - Show in duplicate detection

---

**Created:** 2025-12-19
**Next Step:** Review and choose implementation approach
**Estimated MVP:** 1-2 days for basic search + browse + enhanced add
