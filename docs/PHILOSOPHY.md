---
tags:
  - adhd
---

# Flow CLI Philosophy

> **One pattern, one command per domain, always discoverable.**

---

## Core Principles

### 1. Dispatcher Pattern

Every domain gets ONE command that handles all related operations.

```bash
# Pattern: command + keyword + options
r test              # R package: run tests
g push              # Git: push to remote
qu preview          # Quarto: preview document
mcp status          # MCP: server status
obs daily           # Obsidian: daily note
```

**Rules:**

- Single letter for high-frequency domains: `r`, `g`
- Two letters for medium-frequency: `qu`, `mcp`, `obs`
- Full words for low-frequency: `work`, `dash`, `pick`

**Note (2025-12-25):** `v`/`vibe` dispatcher was deprecated. Use `flow` command directly for workflow operations.

**Benefits:**

- Consistent mental model
- Self-documenting via `<cmd> help`
- Passthrough for advanced usage

### 2. ADHD-Friendly Design

Every command should be:

| Property         | Implementation              |
| ---------------- | --------------------------- |
| **Discoverable** | Built-in help: `<cmd> help` |
| **Consistent**   | Same pattern everywhere     |
| **Memorable**    | Short, mnemonic names       |
| **Forgiving**    | Typo tolerance aliases      |

**Example:**

```bash
g                   # No args → status (most common)
g help              # Forgot command? Help is there
r test              # Run tests (R package)
qu preview          # Preview Quarto doc
```

### 3. Modular Architecture

```
~/projects/dev-tools/flow-cli/
├── flow.plugin.zsh         # Plugin entry point
├── lib/
│   └── dispatchers/
│       ├── g-dispatcher.zsh    # git
│       ├── mcp-dispatcher.zsh  # MCP servers
│       ├── obs.zsh             # Obsidian
│       ├── qu-dispatcher.zsh   # Quarto
│       └── r-dispatcher.zsh    # R packages
└── commands/
    ├── work.zsh            # Session management
    ├── dash.zsh            # Dashboard
    └── adhd.zsh            # ADHD helpers
```

**Rules:**

- Each domain has its own file
- Functions > Aliases (for complex logic)
- Aliases only for simple shortcuts
- **No duplicates across files**

**Note (2025-12-25):** Migrated from ~/.config/zsh to flow-cli plugin structure. `v-dispatcher.zsh` removed.

### 4. Performance First

**Target:** Shell startup < 200ms

**Strategies:**

- Lazy loading for heavy operations
- Minimal plugins (use antidote, not oh-my-zsh)
- No blocking operations at startup
- Conditional loading: `command -v X && ...`

### 5. Self-Documenting

Every dispatcher MUST have:

- `_<cmd>_help()` function
- Most common commands shown first
- Examples with expected output
- Consistent color scheme

**Help Structure:**

```
╭─────────────────────────────────────────────╮
│ <cmd> - Domain Description                  │
╰─────────────────────────────────────────────╯

🔥 MOST COMMON (80% of use):
  <cmd> action1     Description
  <cmd> action2     Description

💡 QUICK EXAMPLES:
  $ <cmd> action1   # Comment
  $ <cmd> action2   # Comment

📋 ALL COMMANDS:
  [grouped by category]
```

### 6. Graceful Degradation

```bash
# Always check if tool exists
if command -v eza &>/dev/null; then
    alias ls='eza --icons'
else
    alias ls='ls -G'
fi
```

---

## Anti-Patterns

### Don't Do This

```bash
# ❌ Multiple files defining same alias
# ~/.zshrc:           alias gst='git status'
# ~/workflow/aliases: alias gst='git status -sb'

# ❌ Aliases for complex logic
alias deploy='git push && ssh server "cd /app && git pull && restart"'

# ❌ Cryptic names without help
alias xyzzy='complex-internal-function'

# ❌ Blocking operations at startup
$(curl -s api.example.com/motd)  # Don't do this in .zshrc
```

### Do This Instead

```bash
# ✅ Single source of truth
# g-dispatcher.zsh: g status → git status -sb

# ✅ Functions for complex logic
deploy() {
    git push && ssh server "cd /app && git pull && restart"
}

# ✅ Discoverable with help
# r help → shows all R package commands
# qu help → shows all Quarto commands

# ✅ Lazy loading
motd() { curl -s api.example.com/motd; }  # Only runs when called
```

---

## Command Hierarchy

```
TIER 1: Daily Drivers (muscle memory)
├── g       Git operations
├── r       R package development
└── qu      Quarto publishing

TIER 2: Frequent (weekly)
├── mcp     MCP server management
├── obs     Obsidian notes
├── work    Start session
├── dash    Dashboard
└── pick    FZF picker

TIER 3: Contextual (project-specific)
├── pb      Project build
├── pv      Project view
├── pt      Project test
└── finish  End session

TIER 4: Utilities (as needed)
├── ..      Navigate up
├── ll      List files
└── reload  Refresh shell

DEPRECATED (2025-12-25):
├── v       Use 'flow' command directly
├── cc      Use 'ccy' function in .zshrc
└── gm      Use 'gem*' aliases in .zshrc
```

---

## Testing Philosophy

Every change should be:

1. **Lint-checked:** ShellCheck passes
2. **Duplicate-free:** No conflicts with existing
3. **Documented:** Help updated if applicable
4. **Tested:** Basic functionality verified

```bash
# Before committing:
shellcheck ~/.config/zsh/functions/*.zsh
./test-duplicates.zsh
./test-dispatchers.zsh
```

---

## Evolution

This configuration evolves through:

1. **Session summaries** - Document what changed and why
2. **Decision log** - Record trade-offs made
3. **Feedback loop** - What works? What's friction?
4. **Regular cleanup** - Remove unused, update stale

---

*Last Updated: 2025-12-17*
