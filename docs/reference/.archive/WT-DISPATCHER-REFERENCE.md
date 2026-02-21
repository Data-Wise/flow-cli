# WT Dispatcher Reference

> **Git worktree management for parallel development with comprehensive cleanup**

**Location:** `lib/dispatchers/wt-dispatcher.zsh`

---

## Quick Start

```bash
wt                    # Formatted overview (status icons + session indicators)
wt flow               # Filter to show only flow-cli worktrees
wt list               # Raw git worktree list output
wt create feature/x   # Create worktree for branch
wt status             # Show health and disk usage
pick wt               # Interactive worktree picker with actions
```text

---

## Usage

```bash
wt [command] [args]
```diff

### Key Insight

- Worktrees let you work on multiple branches simultaneously
- Each worktree is a separate working directory
- All share the same git history (efficient disk usage)
- Organized under `~/.git-worktrees/<project>/`

---

## Core Commands

### Overview & Navigation

| Command | Description |
|---------|-------------|
| `wt` | **Formatted overview** with status icons and session indicators |
| `wt <project>` | **Filter overview** to show only matching worktrees |
| `wt list` | Raw git worktree list output |
| `wt status` | Detailed health, disk usage, and merge status |
| `pick wt` | **Interactive picker** with delete/refresh actions |

### Creation

| Command | Description |
|---------|-------------|
| `wt create <branch>` | Create worktree for existing or new branch |
| `wt move` | Move current branch to its own worktree |

### Cleanup

| Command | Description |
|---------|-------------|
| `wt remove <path>` | Remove a specific worktree |
| `wt clean` | Prune stale worktree references |
| `wt prune` | Comprehensive cleanup (merged branches) |

---

## Detailed Commands

### wt (default overview)

**NEW in v5.13.0** - Enhanced default behavior with formatted table display.

Show formatted overview of all worktrees:

```bash
wt
```diff

**Output includes:**
- **Status icons:**
  - ✅ **active** - Unmerged feature/bugfix/hotfix branches
  - 🧹 **merged** - Merged to dev/main
  - ⚠️ **stale** - Missing .git directory
  - 🏠 **main** - Main/master/dev/develop branches
- **Session indicators:**
  - 🟢 **active** - Claude session active (< 30 min)
  - 🟡 **recent** - Recent activity (< 24h)
  - ⚪ **none** - No session or old
- Formatted table with BRANCH | STATUS | SESSION | PATH columns
- Total worktree count
- Helpful tip footer

**Sample output:**

```text
🌳 Worktrees (4 total)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  BRANCH                              STATUS         SESSION   PATH
  ─────────────────────────────────── ────────────── ───────── ─────────────────────
  dev                                 🏠 main        🟡         ~/projects/dev-tools/flow-cli
  feature/wt-enhancement              ✅ active      🟢         ~/.git-worktrees/flow-cli/feature-wt-enhancement
  feature/teaching-flags              ✅ active      🟡         ~/.git-worktrees/flow-cli/feature/teaching-flags
  feature/teach-dates-automation      ✅ active      ⚪         ~/.git-worktrees/flow-cli/teach-dates-automation

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 Tip: wt <project> to filter | pick wt for interactive
```text

### wt <filter>

**NEW in v5.13.0** - Filter overview by project name.

Show only worktrees matching filter:

```bash
wt flow               # Show only flow-cli worktrees
wt scholar            # Show only scholar-related worktrees
wt feature            # Show worktrees with 'feature' in path
```sql

**Behavior:**
- Matches against project name (parent directory of worktree)
- Case-sensitive partial matching
- Same formatted output as `wt`
- Shows filtered count in header

### wt create

Create a worktree for a branch:

```bash
# For existing branch
wt create feature/auth
# → Creates ~/.git-worktrees/project/feature-auth/

# For new branch (auto-creates)
wt create feature/new-feature
# → Creates branch AND worktree
```diff

**Behavior:**
- If branch exists → creates worktree pointing to it
- If branch doesn't exist → creates new branch AND worktree
- Uses project name from git root
- Converts `/` to `-` in folder names

### wt move

Move current branch to its own worktree:

```bash
# On feature/auth branch
wt move
# → Creates worktree and shows path
```diff

**Restrictions:**
- Cannot move `main`, `master`, or `dev`
- Cannot move when in detached HEAD state

### wt status

Show comprehensive worktree health:

```bash
wt status
```diff

**Output includes:**
- Branch name for each worktree
- Status: 🏠 main, ✅ active, 🧹 merged, ⚠️ stale
- Disk usage per worktree
- Summary with counts
- Cleanup suggestions

**Sample output:**

```yaml
🌳 Worktree Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  BRANCH                              STATUS       SIZE     PATH
  ─────────────────────────────────── ──────────── ──────── ─────────────────
  main                                🏠 main      156M     ~/projects/flow-cli
  feature/add-tm-dispatcher           ✅ active    48M      ~/.git-worktrees/flow-cli/...
  feature/old-feature                 🧹 merged    32M      ~/.git-worktrees/flow-cli/...

Summary: 3 worktree(s) | 2 active | 1 merged | 0 stale

💡 Tip: Run wt prune to clean up merged worktrees
```text

### wt prune

Comprehensive worktree cleanup:

```bash
wt prune              # Clean merged worktrees (with confirmation)
wt prune --branches   # Also delete merged branches
wt prune --force      # Skip confirmation
wt prune --dry-run    # Preview only
```diff

**Options:**

| Option | Short | Description |
|--------|-------|-------------|
| `--branches` | `-b` | Also delete the merged branches |
| `--force` | `-f` | Skip confirmation prompts |
| `--dry-run` | `-n` | Preview without making changes |
| `--help` | `-h` | Show help |

**What it does:**
1. Prunes stale worktree references
2. Finds worktrees for merged feature branches
3. Removes those worktrees (with confirmation)
4. Optionally deletes the merged branches

**Safe by default:**
- Asks for confirmation before removing
- Only targets merged `feature/*`, `bugfix/*`, `hotfix/*`
- Never removes `main`, `master`, `dev`, `develop`
- Never removes current branch

### wt clean

Simple cleanup (prunes stale references only):

```bash
wt clean
# → Runs: git worktree prune
```text

Use this for quick cleanup. Use `wt prune` for comprehensive cleanup.

### wt remove

Remove a specific worktree:

```bash
wt remove ~/.git-worktrees/project/feature-x
```diff

Shows current worktrees if no path provided.

---

## Shortcuts

| Full | Short | Description |
|------|-------|-------------|
| `list` | `ls`, `l` | List worktrees |
| `create` | `add`, `c` | Create worktree |
| `move` | `mv` | Move current branch |
| `remove` | `rm` | Remove worktree |
| `status` | `st` | Show status |

---

## Passthrough

Unknown commands pass through to `git worktree`:

```bash
wt lock <path>     # → git worktree lock <path>
wt unlock <path>   # → git worktree unlock <path>
wt repair          # → git worktree repair
```bash

---

## Configuration

### Worktree Directory

Set custom worktree storage location:

```bash
# Default
export FLOW_WORKTREE_DIR="$HOME/.git-worktrees"

# Custom
export FLOW_WORKTREE_DIR="$HOME/worktrees"
```text

### Directory Structure

Worktrees are organized by project:

```text
~/.git-worktrees/
├── flow-cli/
│   ├── feature-auth/
│   ├── feature-new-ui/
│   └── bugfix-issue-42/
├── aiterm/
│   └── feature-ghostty/
└── mediationverse/
    └── hotfix-urgent/
```bash

---

## Examples

### Quick Overview Workflow (NEW)

```bash
# Check all worktrees with status
wt
# → Shows formatted table with status icons and sessions

# Filter to specific project
wt flow
# → Shows only flow-cli worktrees

# Interactive cleanup
pick wt
# → Use Tab to select old worktrees, Ctrl-X to delete
```bash

### Daily Workflow

```bash
# Check what's active
wt
# → See status icons: ✅ active, 🟢 session active

# Start feature in worktree
wt create feature/auth
cd ~/.git-worktrees/flow-cli/feature-auth

# Work on it...
# Check status again
wt
# → See your new worktree with 🟢 active session

# When done, clean up interactively
pick wt
# → Select merged worktrees, Ctrl-X to delete
```bash

### Parallel Development

```bash
# Create multiple worktrees
wt create feature/frontend
wt create feature/backend
wt create feature/tests

# Each in separate terminal
cd ~/.git-worktrees/project/feature-frontend
cd ~/.git-worktrees/project/feature-backend
cd ~/.git-worktrees/project/feature-tests
```bash

### Check Before Cleanup

```bash
# See what's there
wt status

# Preview cleanup
wt prune --dry-run

# Do the cleanup
wt prune --branches
```bash

### Move Existing Work

```bash
# On a feature branch in main repo
git checkout feature/something

# Move to worktree
wt move
# → Shows: cd ~/.git-worktrees/project/feature-something
```text

---

## Interactive Worktree Picker

**NEW in v5.13.0** - Enhanced `pick wt` with delete and refresh actions.

### pick wt

Launch interactive worktree picker with fzf:

```bash
pick wt
```sql

**Features:**
- Multi-select worktrees with **Tab** key
- **Ctrl-X** - Delete selected worktree(s)
- **Ctrl-R** - Refresh cache and show updated overview
- Session indicators (🟢🟡⚪) in selection list
- Enter to navigate to selected worktree

**Keybindings:**

| Key | Action | Description |
|-----|--------|-------------|
| `Tab` | **Multi-select** | Select multiple worktrees |
| `Ctrl-X` | **Delete** | Remove selected worktree(s) with confirmation |
| `Ctrl-R` | **Refresh** | Clear cache and show updated overview |
| `Enter` | **Navigate** | cd to selected worktree |
| `Esc` | **Cancel** | Exit without action |

### Delete Workflow (Ctrl-X)

When you press `Ctrl-X` on selected worktrees:

1. **Confirmation prompt** for each worktree

   ```text
   Delete worktree: ~/.git-worktrees/flow-cli/feature-old [feature/old]?
     [y] Yes, delete worktree
     [n] No, skip this one
     [a] Yes to all remaining
     [q] Quit (cancel all)
   ```

1. **Branch deletion prompt** after each removal

   ```text
   Also delete branch 'feature/old'? [y/N]:
   ```

2. **Cache invalidation** after completion

   ```text
   ✓ Removed 2 worktree(s)
   ```

**Safe by default:**
- Requires explicit confirmation for each worktree
- Separate prompt for branch deletion
- Can skip individual worktrees
- Can quit at any time

### Refresh Workflow (Ctrl-R)

When you press `Ctrl-R`:

1. **Cache cleared** message

   ```text
   ⟳ Refreshing worktree cache...
   ✓ Cache cleared
   ```

2. **Updated overview** displayed

   ```text
   🌳 Worktrees (4 total)
   [... formatted overview ...]
   ```

**Use cases:**
- After creating worktrees externally
- After cleaning up manually
- To see latest session indicators
- To refresh status icons

---

## Integration

### With Pick Command

The worktree picker integrates seamlessly with the pick command:

```bash
pick wt               # Interactive worktree picker
pick wt --help        # Show worktree-specific keybindings
```text

See [PICK-COMMAND-REFERENCE.md](PICK-COMMAND-REFERENCE.md) for full pick documentation.

### With CC Dispatcher

Launch Claude in a worktree:

```bash
cc wt feature/auth    # Claude in worktree
cc wt pick            # Pick worktree → Claude
cc wt yolo feature/x  # Worktree + YOLO mode
```bash

See [CC-DISPATCHER-REFERENCE.md](CC-DISPATCHER-REFERENCE.md) for details.

### With G Dispatcher

Clean branches after worktree cleanup:

```bash
# Clean worktrees
wt prune

# Or clean branches directly
g feature prune
```bash

---

## Troubleshooting

### "Not in a git repository"

Worktree commands must be run from within a git repository.

```bash
cd ~/projects/my-project
wt create feature/x
```text

### "Cannot move protected branch"

Main branches cannot be moved to worktrees:

```bash
wt move  # On main branch → Error
```bash

Switch to a feature branch first.

### Stale worktree references

If you manually deleted a worktree folder:

```bash
wt clean
# → Removes stale references
```bash

### Worktree path conflicts

If path already exists:

```bash
# Remove old worktree first
wt remove ~/.git-worktrees/project/feature-x

# Then create new
wt create feature/x
```

---

## See Also

- **Dispatcher:** [cc](CC-DISPATCHER-REFERENCE.md) - Launch Claude in worktrees
- **Dispatcher:** [g](G-DISPATCHER-REFERENCE.md) - Git feature workflow integration
- **Reference:** [Dispatcher Reference](DISPATCHER-REFERENCE.md) - All dispatchers
- **Tutorial:** [Worktrees Tutorial](../tutorials/09-worktrees.md) - Step-by-step guide
- **Guide:** [Worktree Workflow](../guides/WORKTREE-WORKFLOW.md) - Practical patterns

---

**Last Updated:** 2026-01-17
**Version:** v5.13.0
**Status:** ✅ Production ready with enhanced overview and interactive actions

**New in v5.13.0:**
- ✅ Enhanced `wt` default: Formatted overview with status icons
- ✅ Filter support: `wt <project>` to filter by project name
- ✅ Session indicators: 🟢 active, 🟡 recent, ⚪ none
- ✅ Interactive picker: `pick wt` with Ctrl-X delete and Ctrl-R refresh
- ✅ Multi-select support: Tab key to select multiple worktrees
- ✅ Safe deletion: Confirmation prompts and branch cleanup options
