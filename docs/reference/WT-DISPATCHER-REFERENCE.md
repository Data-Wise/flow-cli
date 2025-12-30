# WT Dispatcher Reference

Git worktree management for parallel development

**Location:** `lib/dispatchers/wt-dispatcher.zsh`

---

## Quick Start

```bash
wt                    # Navigate to worktrees folder
wt list               # List all worktrees
wt create feature/x   # Create worktree for branch
wt status             # Show health and disk usage
```

---

## Usage

```bash
wt [command] [args]
```

### Key Insight

- Worktrees let you work on multiple branches simultaneously
- Each worktree is a separate working directory
- All share the same git history (efficient disk usage)
- Organized under `~/.git-worktrees/<project>/`

---

## Core Commands

### Navigation

| Command | Description |
|---------|-------------|
| `wt` | Navigate to worktrees folder (`~/.git-worktrees`) |
| `wt list` | List all worktrees with their branches |
| `wt status` | Show health, disk usage, and merge status |

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

### wt create

Create a worktree for a branch:

```bash
# For existing branch
wt create feature/auth
# → Creates ~/.git-worktrees/project/feature-auth/

# For new branch (auto-creates)
wt create feature/new-feature
# → Creates branch AND worktree
```

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
```

**Restrictions:**
- Cannot move `main`, `master`, or `dev`
- Cannot move when in detached HEAD state

### wt status

Show comprehensive worktree health:

```bash
wt status
```

**Output includes:**
- Branch name for each worktree
- Status: 🏠 main, ✅ active, 🧹 merged, ⚠️ stale
- Disk usage per worktree
- Summary with counts
- Cleanup suggestions

**Sample output:**
```
🌳 Worktree Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  BRANCH                              STATUS       SIZE     PATH
  ─────────────────────────────────── ──────────── ──────── ─────────────────
  main                                🏠 main      156M     ~/projects/flow-cli
  feature/add-tm-dispatcher           ✅ active    48M      ~/.git-worktrees/flow-cli/...
  feature/old-feature                 🧹 merged    32M      ~/.git-worktrees/flow-cli/...

Summary: 3 worktree(s) | 2 active | 1 merged | 0 stale

💡 Tip: Run wt prune to clean up merged worktrees
```

### wt prune

Comprehensive worktree cleanup:

```bash
wt prune              # Clean merged worktrees (with confirmation)
wt prune --branches   # Also delete merged branches
wt prune --force      # Skip confirmation
wt prune --dry-run    # Preview only
```

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
```

Use this for quick cleanup. Use `wt prune` for comprehensive cleanup.

### wt remove

Remove a specific worktree:

```bash
wt remove ~/.git-worktrees/project/feature-x
```

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
```

---

## Configuration

### Worktree Directory

Set custom worktree storage location:

```bash
# Default
export FLOW_WORKTREE_DIR="$HOME/.git-worktrees"

# Custom
export FLOW_WORKTREE_DIR="$HOME/worktrees"
```

### Directory Structure

Worktrees are organized by project:

```
~/.git-worktrees/
├── flow-cli/
│   ├── feature-auth/
│   ├── feature-new-ui/
│   └── bugfix-issue-42/
├── aiterm/
│   └── feature-ghostty/
└── mediationverse/
    └── hotfix-urgent/
```

---

## Examples

### Daily Workflow

```bash
# Start feature in worktree
wt create feature/auth
cd ~/.git-worktrees/flow-cli/feature-auth

# Work on it...
# When done, clean up
wt prune
```

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
```

### Check Before Cleanup

```bash
# See what's there
wt status

# Preview cleanup
wt prune --dry-run

# Do the cleanup
wt prune --branches
```

### Move Existing Work

```bash
# On a feature branch in main repo
git checkout feature/something

# Move to worktree
wt move
# → Shows: cd ~/.git-worktrees/project/feature-something
```

---

## Integration

### With CC Dispatcher

Launch Claude in a worktree:

```bash
cc wt feature/auth    # Claude in worktree
cc wt pick            # Pick worktree → Claude
cc wt yolo feature/x  # Worktree + YOLO mode
```

See [CC-DISPATCHER-REFERENCE.md](CC-DISPATCHER-REFERENCE.md) for details.

### With G Dispatcher

Clean branches after worktree cleanup:

```bash
# Clean worktrees
wt prune

# Or clean branches directly
g feature prune
```

---

## Troubleshooting

### "Not in a git repository"

Worktree commands must be run from within a git repository.

```bash
cd ~/projects/my-project
wt create feature/x
```

### "Cannot move protected branch"

Main branches cannot be moved to worktrees:

```bash
wt move  # On main branch → Error
```

Switch to a feature branch first.

### Stale worktree references

If you manually deleted a worktree folder:

```bash
wt clean
# → Removes stale references
```

### Worktree path conflicts

If path already exists:

```bash
# Remove old worktree first
wt remove ~/.git-worktrees/project/feature-x

# Then create new
wt create feature/x
```

---

## Related

- [DISPATCHER-REFERENCE.md](DISPATCHER-REFERENCE.md) - All dispatchers
- [CC-DISPATCHER-REFERENCE.md](CC-DISPATCHER-REFERENCE.md) - Claude + worktrees
- [Tutorial: Worktrees](../tutorials/09-worktrees.md) - Step-by-step guide

---

**Last Updated:** 2025-12-30
**Version:** v4.3.0+
**Status:** ✅ Fully implemented
