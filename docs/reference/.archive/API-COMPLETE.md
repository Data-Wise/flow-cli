# flow-cli Complete API Reference

**Version:** 5.10.0
**Last Updated:** 2026-01-15
**Status:** Production

---

## Table of Contents

- [Core Functions](#core-functions)
- [Dispatcher APIs](#dispatcher-apis)
- [Command APIs](#command-apis)
- [Utility Functions](#utility-functions)
- [Configuration](#configuration)
- [Type Definitions](#type-definitions)

---

## Core Functions

### Logging & Output

#### `_flow_log(level, message)`

**Description:** Core logging function with color-coded output

**Parameters:**
- `level` (string): Log level - one of: `success`, `warning`, `error`, `info`, `muted`
- `message` (string): Message to log

**Returns:** None (outputs to stdout)

**Example:**

```zsh
_flow_log success "Task completed"
_flow_log error "Operation failed"
```

**Related:**
- `_flow_log_success(message)` - Shorthand for success messages
- `_flow_log_warning(message)` - Shorthand for warning messages
- `_flow_log_error(message)` - Shorthand for error messages
- `_flow_log_info(message)` - Shorthand for info messages

---

#### `_flow_log_success(message)`

**Description:** Log a success message with ✓ icon

**Parameters:**
- `message` (string): Success message

**Example:**

```zsh
_flow_log_success "Worktree created successfully"
```

**Output:**

```
✓ Worktree created successfully
```

---

### Project Detection

#### `_flow_find_project_root([path])`

**Description:** Find the root directory of a project by searching for markers

**Parameters:**
- `path` (string, optional): Starting directory (default: current directory)

**Returns:**
- String: Absolute path to project root
- Exit code: 0 if found, 1 if not found

**Detection Markers:**
- `.git/`
- `package.json`
- `pyproject.toml`
- `Cargo.toml`
- `go.mod`
- `DESCRIPTION` (R packages)

**Example:**

```zsh
root=$(_flow_find_project_root)
if [[ $? -eq 0 ]]; then
    echo "Project root: $root"
fi
```

---

#### `_flow_detect_project_type(path)`

**Description:** Detect project type based on files and structure

**Parameters:**
- `path` (string): Project directory path

**Returns:**
- String: Project type identifier

**Supported Types:**
- `r-package` - R package (has DESCRIPTION file)
- `quarto` - Quarto project (has _quarto.yml)
- `python` - Python project (has pyproject.toml, setup.py)
- `node` - Node.js project (has package.json)
- `rust` - Rust project (has Cargo.toml)
- `go` - Go project (has go.mod)
- `teaching` - Teaching course (has teach-config.yml)
- `unknown` - Unidentified project type

**Example:**

```zsh
type=$(_flow_detect_project_type "$PWD")
case "$type" in
    r-package) echo "R package detected" ;;
    python) echo "Python project detected" ;;
esac
```

---

### Cache Management

#### `_proj_cache_invalidate()`

**Description:** Invalidate project cache to force rescan

**Parameters:** None

**Returns:** None

**Side Effects:**
- Removes cache file at `$FLOW_CACHE_DIR/projects.cache`
- Next project scan will rebuild cache

**Example:**

```zsh
# After creating new worktree, invalidate cache
git worktree add ~/.git-worktrees/project-feature -b feature/new
_proj_cache_invalidate
```

**Used By:**
- `wt create` - After successful worktree creation
- `wt remove` - After successful worktree removal

---

## Dispatcher APIs

### Git Dispatcher (`g`)

#### `g(subcommand, ...args)`

**Description:** Git workflow dispatcher with common operations

**Subcommands:**

##### `g status`

**Description:** Show git status with enhanced formatting
**Example:** `g status`

##### `g push [remote] [branch]`

**Description:** Push to remote repository
**Parameters:**
- `remote` (string, optional): Remote name (default: origin)
- `branch` (string, optional): Branch name (default: current branch)
**Example:** `g push origin main`

##### `g commit [message]`

**Description:** Create git commit with message
**Parameters:**
- `message` (string, optional): Commit message (prompts if not provided)
**Example:** `g commit "feat: add new feature"`

##### `g feature start <name>`

**Description:** Start new feature branch
**Parameters:**
- `name` (string, required): Feature branch name
**Example:** `g feature start user-authentication`

##### `g feature prune`

**Description:** Clean up merged feature branches
**Example:** `g feature prune`

**Exit Codes:**
- `0` - Success
- `1` - Git operation failed
- `2` - Invalid subcommand

---

### Worktree Dispatcher (`wt`)

#### `wt(subcommand, ...args)`

**Description:** Git worktree management dispatcher

**Subcommands:**

##### `wt create <branch>`

**Description:** Create new worktree
**Parameters:**
- `branch` (string, required): Branch name
**Side Effects:** Invalidates project cache
**Example:** `wt create feature/new-ui`

**Behavior:**
- Creates worktree at `~/.git-worktrees/<project>-<branch>/`
- Supports both flat and hierarchical naming
- Automatically invalidates cache for immediate visibility

##### `wt list`

**Description:** List all worktrees
**Example:** `wt list`

**Output Format:**

```
🌳 project (branch-name) - /path/to/worktree
🟢 project (recent-branch) - /path/to/worktree  [< 24h]
🟡 project (old-branch) - /path/to/worktree     [> 24h]
```

##### `wt remove <name>`

**Description:** Remove worktree
**Parameters:**
- `name` (string, required): Worktree name or path
**Side Effects:** Invalidates project cache
**Example:** `wt remove feature/old-branch`

##### `wt prune`

**Description:** Prune deleted worktrees
**Example:** `wt prune`

---

### Claude Code Dispatcher (`cc`)

#### `cc([mode], [target])`

**Description:** Launch Claude Code with mode and target selection

**Unified Grammar:** Both mode-first and target-first orders work

**Modes:**
- `yolo` - Skip all permission prompts
- `plan` - Enter planning mode
- `opus` - Use Opus model
- `haiku` - Use Haiku model

**Targets:**
- (empty) - Launch in current directory
- `.` - Explicit current directory
- `pick` - Interactive project picker
- `<project-name>` - Direct project jump

**Examples:**

```zsh
cc                  # Launch HERE with default settings
cc yolo             # Launch HERE in YOLO mode
cc pick             # Pick project → launch
cc yolo pick        # Mode-first: pick → YOLO
cc pick yolo        # Target-first: pick → YOLO (same result)
cc opus pick        # Pick → Opus model
cc flow             # Direct jump to flow-cli project
```

**Exit Codes:**
- `0` - Claude launched successfully
- `1` - Claude not found or launch failed
- `2` - Invalid mode/target combination

---

### MCP Dispatcher (`mcp`)

#### `mcp(subcommand, ...args)`

**Description:** MCP server management dispatcher

**Subcommands:**

##### `mcp status`

**Description:** Show all MCP servers status
**Example:** `mcp status`

**Output:**

```
✓ github - Running (npx)
✓ statistical-research - Running (Bun)
✗ docling - Stopped
```

##### `mcp test <server>`

**Description:** Test MCP server connection
**Parameters:**
- `server` (string, required): Server name
**Example:** `mcp test github`

##### `mcp logs <server>`

**Description:** Show MCP server logs
**Parameters:**
- `server` (string, required): Server name
**Example:** `mcp logs statistical-research`

##### `mcp restart <server>`

**Description:** Restart MCP server
**Parameters:**
- `server` (string, required): Server name
**Example:** `mcp restart docling`

---

### Teaching Dispatcher (`teach`)

#### `teach(subcommand, ...args)`

**Description:** Teaching workflow and Scholar integration dispatcher

**Subcommands:**

##### `teach init <course-name> [-y]`

**Description:** Initialize teaching workflow
**Parameters:**
- `course-name` (string, required): Course name (e.g., "STAT 440")
- `-y, --yes` (flag, optional): Non-interactive mode
**Example:** `teach init "STAT 440" -y`

**Creates:**
- `teach-config.yml` - Course configuration
- Directory structure (lectures/, exams/, etc.)
- Git branches (draft, production)

##### `teach status`

**Description:** Show teaching project status
**Example:** `teach status`

**Output:**

```
Course:   STAT 440 - Regression Analysis
Semester: Fall 2024
Config:   ✓ Valid (last modified: 2024-01-15)
Scholar:  ✓ Configured
```

##### `teach exam <topic> [--format <format>]`

**Description:** Generate exam via Scholar
**Parameters:**
- `topic` (string, required): Exam topic
- `--format` (string, optional): Output format (quarto|markdown|latex)
**Example:** `teach exam "Hypothesis Testing" --format quarto`

**Requires:**
- Valid `teach-config.yml`
- Claude CLI installed
- Scholar plugin available

##### `teach deploy`

**Description:** Deploy draft → production
**Example:** `teach deploy`

**Behavior:**
- Merges draft branch to production
- Triggers GitHub Pages deployment
- Updates live course site

---

### Terminal Manager Dispatcher (`tm`)

#### `tm(subcommand, ...args)`

**Description:** Terminal configuration and management

**Subcommands:**

##### `tm title <text>`

**Description:** Set terminal tab/window title
**Parameters:**
- `text` (string, required): Title text
**Example:** `tm title "flow-cli development"`

**Alias:** `tmt <text>`

##### `tm profile <name>`

**Description:** Switch iTerm2 profile
**Parameters:**
- `name` (string, required): Profile name
**Example:** `tm profile "Solarized Dark"`

**Alias:** `tmp <name>`

##### `tm ghost`

**Description:** Show Ghostty terminal status
**Example:** `tm ghost`

**Delegates to:** `aiterm ghost`

##### `tm detect`

**Description:** Detect project context
**Example:** `tm detect`

**Delegates to:** `aiterm detect`

---

## Command APIs

### Project Picker (`pick`)

#### `pick([category], [filter])`

**Description:** Interactive project picker with fzf

**Parameters:**
- `category` (string, optional): Project category filter
- `filter` (string, optional): Additional filter text

**Categories:**
- `r` - R packages
- `dev` - Dev tools
- `q` - Quarto projects
- `teach` - Teaching courses
- `rs` - Research projects
- `wt` - Worktrees
- (empty) - All projects

**Interactive Keys:**
- `Enter` - Change to project directory
- `Ctrl-O` - Open in Claude Code
- `Ctrl-Y` - Open in Claude Code (YOLO mode)
- `Ctrl-S` - Show git status
- `Ctrl-L` - Show git log

**Examples:**

```zsh
pick                # Pick from all projects
pick r              # Pick from R packages only
pick wt             # Pick from worktrees only
pick wt scholar     # Filter worktrees containing "scholar"
pick flow           # Direct jump to flow-cli
```

**Session Indicators:**
- 🟢 - Recent session (< 24h ago)
- 🟡 - Old session (> 24h ago)
- (none) - No recent session

**Output Format:**

```
🌳 scholar (github-actions) - /Users/dt/.git-worktrees/scholar-github-actions
📦 rmediation - /Users/dt/projects/r-packages/active/rmediation
🟢 flow-cli - /Users/dt/projects/dev-tools/flow-cli
```

---

### Dashboard (`dash`)

#### `dash([category])`

**Description:** Project dashboard with status overview

**Parameters:**
- `category` (string, optional): Filter by category

**Categories:**
- `teach` - Teaching courses
- `rs` - Research projects
- `r` - R packages
- `dev` - Dev tools
- (empty) - All projects

**Flags:**
- `-i, --interactive` - Interactive TUI mode
- `--watch` - Live refresh mode
- `--inventory` - Show tool inventory

**Examples:**

```zsh
dash                # Show all projects
dash teach          # Teaching courses only
dash -i             # Interactive mode
dash --watch        # Live refresh
```

**Output:**

```
┌─────────────────────────────────────────┐
│ TEACHING COURSES                        │
├─────────────────────────────────────────┤
│ STAT 440          Active    Progress: 75%│
│ Causal Inference  Draft     Progress: 30%│
└─────────────────────────────────────────┘
```

---

### Session Management

#### `work <project>`

**Description:** Start work session on project

**Parameters:**
- `project` (string, required): Project name or path

**Side Effects:**
- Changes to project directory
- Updates session timestamp
- Logs session start

**Example:**

```zsh
work flow-cli
work ~/projects/dev-tools/flow-cli
```

---

#### `finish [message]`

**Description:** End work session with optional commit

**Parameters:**
- `message` (string, optional): Commit message

**Behavior:**
- Prompts for commit if changes exist
- Updates session log
- Shows session duration

**Example:**

```zsh
finish "feat: add new dispatcher"
finish  # Interactive mode
```

---

#### `hop <project>`

**Description:** Quick switch to project in new tmux window

**Parameters:**
- `project` (string, required): Project name

**Requires:** tmux

**Example:**

```zsh
hop flow-cli
```

---

### Configuration Validation

#### `_teach_validate_config(config_file)`

**Description:** Validate teach-config.yml against JSON Schema

**Parameters:**
- `config_file` (string): Path to config file

**Returns:**
- Exit code: 0 if valid, 1 if invalid

**Validation Rules:**
- Required field: `course.name`
- Enum validation: `course.semester` ∈ {Spring, Summer, Fall, Winter}
- Range validation: `course.year` ∈ [2020, 2100]
- Date format: YYYY-MM-DD
- Grading sum: Must equal 100%

**Example:**

```zsh
if _teach_validate_config "teach-config.yml"; then
    echo "✓ Config valid"
else
    echo "✗ Config invalid"
fi
```

---

## Utility Functions

### Project List Functions

#### `_proj_list_worktrees()`

**Description:** List all git worktrees (hybrid scanner)

**Returns:** Array of worktree data

**Detection:**
1. **Level-1 (Flat):** Check for `.git` FILE
   - Parse `gitdir:` line
   - Extract project name from path
2. **Level-2 (Hierarchical):** Check for subdirectories
   - Scan `project/branch/` structure

**Output Format:**

```zsh
# Array elements:
"project-name (branch-name)|/path/to/worktree|session-age"
```

**Example:**

```zsh
worktrees=$(_proj_list_worktrees)
for wt in "${(@f)worktrees}"; do
    IFS='|' read -r name path age <<< "$wt"
    echo "$name - $path"
done
```

---

#### `_proj_find_worktree(query)`

**Description:** Find worktree by name or partial match

**Parameters:**
- `query` (string): Search query

**Returns:**
- String: Worktree path
- Exit code: 0 if found, 1 if not found

**Example:**

```zsh
path=$(_proj_find_worktree "scholar-github")
if [[ $? -eq 0 ]]; then
    cd "$path"
fi
```

---

### Hash Functions

#### `_teach_config_hash(config_file)`

**Description:** Calculate SHA-256 hash of config file

**Parameters:**
- `config_file` (string): Path to config file

**Returns:** String - SHA-256 hash (64 hex characters)

**Example:**

```zsh
hash=$(_teach_config_hash "teach-config.yml")
echo "Config hash: $hash"
```

**Use Cases:**
- Change detection
- Cache invalidation
- Version tracking

---

## Configuration

### Environment Variables

#### `FLOW_PROJECTS_ROOT`

**Type:** String (path)
**Default:** `$HOME/projects`
**Description:** Root directory for all projects

#### `FLOW_WORKTREE_DIR`

**Type:** String (path)
**Default:** `$HOME/.git-worktrees`
**Description:** Directory for git worktrees

#### `FLOW_CACHE_DIR`

**Type:** String (path)
**Default:** `$HOME/.cache/flow-cli`
**Description:** Cache directory for project data

#### `FLOW_ATLAS_ENABLED`

**Type:** String (enum)
**Values:** `auto` | `yes` | `no`
**Default:** `auto`
**Description:** Atlas integration mode

#### `FLOW_QUIET`

**Type:** Boolean (0/1)
**Default:** `0`
**Description:** Suppress welcome messages

#### `FLOW_DEBUG`

**Type:** Boolean (0/1)
**Default:** `0`
**Description:** Enable debug logging

---

### Color Scheme

#### `FLOW_COLORS` (Associative Array)

**Available Colors:**

```zsh
FLOW_COLORS[reset]    # Reset all formatting
FLOW_COLORS[bold]     # Bold text
FLOW_COLORS[dim]      # Dimmed text

# Status colors
FLOW_COLORS[success]  # Soft green
FLOW_COLORS[warning]  # Warm yellow
FLOW_COLORS[error]    # Soft red
FLOW_COLORS[info]     # Calm blue

# Project status
FLOW_COLORS[active]   # Green
FLOW_COLORS[paused]   # Yellow
FLOW_COLORS[blocked]  # Red
FLOW_COLORS[archived] # Gray

# UI elements
FLOW_COLORS[header]   # Soft purple
FLOW_COLORS[accent]   # Soft orange
FLOW_COLORS[muted]    # Gray
FLOW_COLORS[cmd]      # Calm blue
```

**Usage:**

```zsh
echo -e "${FLOW_COLORS[success]}✓ Success${FLOW_COLORS[reset]}"
```

---

## Type Definitions

### Project Type

```typescript
type ProjectType =
  | "r-package"
  | "quarto"
  | "python"
  | "node"
  | "rust"
  | "go"
  | "teaching"
  | "unknown"
```

---

### Worktree Structure

**Flat Naming:**

```
~/.git-worktrees/
└── project-branch/          # Level 1
    └── .git                 # FILE (contains gitdir:)
```

**Hierarchical Naming:**

```
~/.git-worktrees/
└── project/                 # Level 1
    └── branch/              # Level 2
        └── .git             # FILE
```

---

### Session Age

```typescript
type SessionAge =
  | "recent"   // < 24 hours
  | "old"      // > 24 hours
  | "none"     // No session found
```

---

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error (operation failed) |
| 2 | Invalid argument or subcommand |
| 3 | Dependency missing (e.g., fzf, git) |
| 4 | Configuration error |
| 5 | Permission denied |

---

## Performance Characteristics

### Core Commands

- `work`, `finish`, `hop`: < 10ms
- `pick`: ~50ms (with cache)
- `dash`: ~100ms (full scan)

### Cache TTL

- Project cache: 5 minutes
- Worktree cache: Invalidated on create/remove

### Cache Files

- `$FLOW_CACHE_DIR/projects.cache` - Project list
- `$FLOW_CACHE_DIR/worktrees.cache` - Worktree list (unused, invalidated instead)

---

## Migration Notes

### v5.9.0 → v5.10.0

**Breaking Changes:** None

**New Features:**
- Flat worktree detection
- Automatic cache invalidation on worktree operations

**Deprecated:** None

---

## See Also

- [ARCHITECTURE.md](./ARCHITECTURE.md) - System architecture
- [DISPATCHER-REFERENCE.md](./DISPATCHER-REFERENCE.md) - Dispatcher documentation
- [COMMAND-QUICK-REFERENCE.md](./COMMAND-QUICK-REFERENCE.md) - Quick command reference
- [WORKFLOW-QUICK-REFERENCE.md](./WORKFLOW-QUICK-REFERENCE.md) - Common workflows

---

**Last Updated:** 2026-01-15
**Version:** 5.10.0
**Maintainer:** Data-Wise
