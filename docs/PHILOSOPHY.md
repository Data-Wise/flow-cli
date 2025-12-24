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
v dash              # Workflow: open dashboard
```

**Rules:**

- Single letter for high-frequency domains: `r`, `g`, `v`
- Two letters for medium-frequency: `qu`, `cc`, `gm`
- Full words for low-frequency: `work`, `dash`, `pick`

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
gti push            # Typo? Still works (alias to g)
```

### 3. Modular Architecture

```
~/.config/zsh/
├── .zshrc                  # Loader + environment
└── functions/
    ├── smart-dispatchers.zsh   # r, qu, cc, gm
    ├── g-dispatcher.zsh        # git
    ├── v-dispatcher.zsh        # vibe/workflow
    └── adhd-helpers.zsh        # work, dash, pb, pv
```

**Rules:**

- Each domain has its own file
- Functions > Aliases (for complex logic)
- Aliases only for simple shortcuts
- **No duplicates across files**

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
# v help → shows all vibe commands

# ✅ Lazy loading
motd() { curl -s api.example.com/motd; }  # Only runs when called
```

---

## Command Hierarchy

```
TIER 1: Daily Drivers (muscle memory)
├── g       Git operations
├── r       R package development
├── cc      Claude Code
└── v       Workflow automation

TIER 2: Frequent (weekly)
├── qu      Quarto publishing
├── gm      Gemini
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

_Last Updated: 2025-12-17_
