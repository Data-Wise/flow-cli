# Pick Command Reference

Interactive project picker with fuzzy search, smart resume, and direct jump

**Location:** `commands/pick.zsh`

---

## Quick Start

```bash
pick              # Smart resume or browse all projects
pick flow         # Direct jump to flow-cli (no picker)
pick r            # Show only R packages
pick -a           # Force full picker (bypass resume)
```

---

## Usage

```bash
pick [options] [category|project-name]
```

### Arguments

| Argument       | Description                             |
| -------------- | --------------------------------------- |
| `project-name` | Direct jump to matching project (fuzzy) |
| `category`     | Filter by category (r, dev, q, etc.)    |
| `-a, --all`    | Force full picker (skip direct jump)    |
| `--fast`       | Skip git status checks (faster loading) |

---

## Smart Behaviors (NEW)

### Direct Jump

Jump directly to a project without the picker:

```bash
pick flow         # → cd to flow-cli (exact match)
pick med          # → cd to mediationverse
pick stat         # → Multiple matches? Shows filtered picker
```

### Session-Aware Resume

When you run `pick` with no args and have a recent session:

```
╔════════════════════════════════════════════════════════════╗
║  🔍 PROJECT PICKER                                         ║
╚════════════════════════════════════════════════════════════╝

  💡 Last: flow-cli (2h ago)
  [Enter] Resume  │  [Space] Browse all  │  Type to search...
```

| Key       | Action                            |
| --------- | --------------------------------- |
| **Enter** | Resume last project               |
| **Space** | Force full picker (bypass resume) |
| **Type**  | Filter projects as before         |

Sessions expire after 24 hours.

### Worktree Integration (v4.6.1+)

By default, `pick` shows **both projects AND worktrees**:

```text
flow-cli             🔧 dev
mediationverse       📦 r
medrobust            📦 r
flow-cli (feature-x) 🌳 wt   🟢 2h
scholar (gh-actions) 🌳 wt   🟡 old
```

**Key features:**

- **🌳 icon** indicates a git worktree
- **Session indicators** show Claude Code activity:
  - 🟢 Recent session (within 24h) with time since last activity
  - 🟡 Old session (>24h ago)
- **Sorted by recency** - most recently used worktrees appear first

**Worktree-only view:**

```bash
pick wt              # Show only worktrees
pick wt flow         # Filter worktrees for "flow" project
pick wt scholar      # Filter worktrees for "scholar" project
```

**Supported Structures (v5.9.1+):**

Pick detects **both** worktree naming conventions:

| Structure | Path Example | Display Name |
|-----------|--------------|--------------|
| **Hierarchical** | `~/.git-worktrees/flow-cli/feature-x/` | `flow-cli (feature-x)` |
| **Flat** | `~/.git-worktrees/scholar-gh-actions/` | `scholar (gh-actions)` |

```
~/.git-worktrees/
├── flow-cli/                      # HIERARCHICAL: project directory
│   ├── feature-x/                 # └─ branch worktree (has .git file)
│   └── bugfix/                    # └─ branch worktree (has .git file)
├── scholar-gh-actions/            # FLAT: worktree at level-1 (has .git file)
└── aiterm/
    └── develop/                   # HIERARCHICAL: branch worktree
```

**How detection works:**

1. **Flat worktrees** have a `.git` FILE at level-1 containing `gitdir: /path/to/PROJECT/.git/worktrees/BRANCH`
2. **Hierarchical worktrees** have a `.git` file/directory at level-2

The project and branch names are parsed from the `gitdir:` path for flat worktrees, ensuring correct display names regardless of the directory naming.

To create a worktree:

```bash
# Hierarchical (recommended)
wt create <branch>
git worktree add ~/.git-worktrees/<project>/<branch> <branch>

# Flat (also supported)
git worktree add ~/.git-worktrees/<any-name> <branch>
```

### Categories

All category names are case-insensitive and support multiple aliases:

| Category  | Aliases                              | Description       |
| --------- | ------------------------------------ | ----------------- |
| **r**     | `r`, `R`, `rpack`, `rpkg`            | R packages        |
| **dev**   | `dev`, `Dev`, `DEV`, `tool`, `tools` | Development tools |
| **q**     | `q`, `Q`, `qu`, `quarto`             | Quarto projects   |
| **teach** | `teach`, `teaching`                  | Teaching courses  |
| **rs**    | `rs`, `research`, `res`              | Research projects |
| **app**   | `app`, `apps`                        | Applications      |
| **wt**    | `wt`, `worktree`, `worktrees`        | Git worktrees     |

---

## Interactive Keys

### General Keys

| Key        | Action | Description                              |
| ---------- | ------ | ---------------------------------------- |
| **Enter**  | cd     | Change to selected project (or resume)   |
| **Space**  | browse | Force full picker (bypass resume prompt) |
| **Ctrl-S** | status | View .STATUS file (with bat/cat)         |
| **Ctrl-L** | log    | View git log (with tig/git)              |
| **Ctrl-C** | cancel | Exit without action                      |

### Worktree Actions (v5.13.0+)

**NEW in v5.13.0** - When using `pick wt`, additional keybindings are available:

| Key        | Action   | Description                                    |
| ---------- | -------- | ---------------------------------------------- |
| **Tab**    | multi-select | Select multiple worktrees for batch operations |
| **Ctrl-X** | delete   | Delete selected worktree(s) with confirmation  |
| **Ctrl-R** | refresh  | Clear cache and show updated overview          |

**Delete Workflow (Ctrl-X):**
1. Confirmation prompt for each worktree ([y/n/a/q])
2. Optional branch deletion after worktree removal
3. Cache invalidation
4. Summary of deleted worktrees

**Refresh Workflow (Ctrl-R):**
1. Cache cleared message
2. Updated overview with current status icons and sessions
3. Immediate feedback

See [WT-DISPATCHER-REFERENCE.md](WT-DISPATCHER-REFERENCE.md) for complete worktree action documentation.

---

## Display Format

```text
project-name         icon type
────────────────────────────────
flow-cli    🔧 dev
mediationverse       📦 r
medrobust            📦 r
apple-notes-sync     🔧 dev
```

**Note:** Git status display was removed for simplicity and reliability. A `--git` flag may be added in future versions to optionally show branch and status information.

### Icons by Category

- 📦 - R packages (`r`)
- 🔧 - Dev tools (`dev`)
- 📝 - Quarto projects (`q`)
- 📚 - Teaching courses (`teach`)
- 🔬 - Research projects (`rs`)
- 📱 - Applications (`app`)
- 🌳 - Git worktrees (`wt`)

---

## Examples

### Direct Jump (NEW)

```bash
# Jump to project by name (fuzzy match)
pick flow         # → flow-cli
pick med          # → mediationverse
pick stat         # → Multiple matches? Shows filtered picker

# Force full picker even with name
pick -a flow      # Shows picker, pre-filtered to "flow"
```

### Smart Resume (NEW)

```bash
# If you were recently in flow-cli:
pick              # Shows: "💡 Last: flow-cli (2h ago)"
                  # Press Enter to resume, Space to browse
```

### Category Filtering

```bash
# Filter by category
pick r            # R packages only
pick dev          # Dev tools only
pick DEV          # Case-insensitive

# Fast mode with filter
pick --fast r
```

### Interactive Actions

```bash
# In the picker:
#   - Type to filter projects
#   - Press Enter to cd (or resume last)
#   - Press Space to bypass resume and browse all
#   - Press Ctrl-S to view .STATUS file
#   - Press Ctrl-L to view git log
```

---

## Aliases

Shortcuts available for common categories:

```bash
pickr             # Expands to: pick r
pickdev           # Expands to: pick dev
pickq             # Expands to: pick q
```

---

## Features

### ADHD-Friendly Design

- **Color-coded status** - Pre-attentive processing (see status before reading)
- **Forgiving input** - Multiple aliases, case-insensitive
- **Visual hierarchy** - Icons, colors, clear sections
- **Fast mode** - Skip git checks when you need speed
- **Dynamic headers** - Always know what you're filtering

### Technical Features

- Process substitution (no subshell pollution)
- Branch name truncation (20 chars max)
- ANSI color support with fzf `--ansi` flag
- Comprehensive error handling
- Git status caching potential

---

## Integration

Works with:

- **`cc` dispatcher** - `cc` uses `pick` for project selection, then launches Claude
- **`cc <project>`** - Direct jump to project + Claude (inherits pick's direct jump)
- `work` command - Start work session in selected project
- `bat` - Syntax-highlighted .STATUS viewing
- `tig` - Interactive git log browser

---

## Next Phase Enhancements

Planned features for future releases:

- **P6A:** Preview pane showing .STATUS, README, git info
- **P6B:** Frecency sorting (frequency + recency)
- **P6C:** Multi-select batch operations
- **P6D:** Advanced actions (PR creation, deployment)
- **P6E:** Smart filters (by git status, .STATUS progress)
- **P6F:** Performance optimization (parallel git, caching)

---

## Troubleshooting

### Colors not showing?

Make sure your terminal supports ANSI colors and fzf has the `--ansi` flag.

### Parse error at line 49?

Reload the function:

```bash
source ~/.config/zsh/functions/adhd-helpers.zsh
```

### Formatting broken?

Check that ANSI escape codes use **double quotes** in printf:

```zsh
# Correct:
printf "\033[32m✅\033[0m"

# Incorrect:
printf '\033[32m✅\033[0m'  # Single quotes don't interpret escapes
```

---

**Last Updated:** 2026-01-15
**Status:** ✅ Fully implemented (v5.9.1 - flat worktree detection)
