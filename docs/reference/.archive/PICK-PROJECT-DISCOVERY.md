# How Pick Discovers Projects

**Quick Answer:** `pick` scans predefined directory paths and shows all subdirectories with `.git` repositories. No caching, no manual registration needed.

---

## Overview

The `pick` command discovers projects by:

1. **Scanning predefined paths** (from `PROJ_CATEGORIES`)
2. **Checking for `.git`** (must be a git repository)
3. **Sorting by frecency** (most recently used first)
4. **Live scanning** (no caching - always current)

---

## Project Discovery Process

### 1. Scanned Directories

`pick` scans these directories automatically:

```bash
~/projects/r-packages/active/    # R packages (active)
~/projects/r-packages/stable/    # R packages (stable)
~/projects/dev-tools/            # Development tools
~/projects/teaching/             # Teaching courses
~/projects/research/             # Research projects
~/projects/quarto/manuscripts/   # Quarto manuscripts
~/projects/quarto/presentations/ # Quarto presentations
~/projects/apps/                 # Applications
~/.git-worktrees/                # Git worktrees (all projects)
```diff

**Location:** Defined in `PROJ_CATEGORIES` array at the top of `commands/pick.zsh`

---

### 2. Detection Requirements

For a project to appear in `pick`, it **must**:

✅ **Have a `.git` directory or file**
- Regular repos: `.git/` directory
- Worktrees: `.git` file pointing to parent repo

❌ **Not required:**
- `.STATUS` file (optional, improves display)
- `package.json`, `DESCRIPTION`, or other project files
- Specific folder structure

**Code reference:** `commands/pick.zsh:230`

```bash
[[ -d "$proj_dir/.git" ]] || continue
```diff

---

### 3. Real-Time Scanning (No Caching)

Every time you run `pick`, it:

1. Scans all category paths **fresh**
2. Checks for `.git` in each subdirectory
3. Reads Claude session metadata (for indicators)
4. Sorts by frecency (recent activity first)
5. Displays results in FZF

**Result:** Deleted projects disappear automatically on next run!

---

## Adding New Projects

### Automatic Discovery

Just create a git repository in one of the scanned directories:

```bash
# Create new project
mkdir ~/projects/dev-tools/my-new-tool
cd ~/projects/dev-tools/my-new-tool
git init

# It appears in pick immediately!
pick dev
# → Shows: my-new-tool 🔧
```bash

**No configuration needed** - `pick` finds it automatically.

---

### Adding New Scan Paths

To scan additional directories, edit `PROJ_CATEGORIES` in `commands/pick.zsh`:

```bash
# Location: commands/pick.zsh:9-18
PROJ_CATEGORIES=(
    "r-packages/active:r:📦"
    "r-packages/stable:r:📦"
    "dev-tools:dev:🔧"
    "teaching:teach:🎓"
    "research:rs:🔬"
    "quarto/manuscripts:q:📝"
    "quarto/presentations:q:📊"
    "apps:app:📱"
    # Add your own:
    # "my-custom-dir:custom:🎨"
)
```bash

**Format:** `"path/to/dir:category-code:icon"`

**Example - Add work projects:**

```bash
PROJ_CATEGORIES=(
    # ... existing entries ...
    "work/frontend:work:💻"
    "work/backend:work:⚙️"
)
```bash

Now `pick work` will show those projects!

---

## Deleting Projects

### How Deletion Works

**Scenario 1: Delete project directory**

```bash
rm -rf ~/projects/dev-tools/old-project
pick dev
# → old-project is gone (removed from list automatically)
```bash

**Scenario 2: Remove .git (make non-repo)**

```bash
cd ~/projects/dev-tools/not-a-project
rm -rf .git
pick dev
# → Project disappears from pick (no longer detected)
```text

**No cleanup needed** - `pick` scans fresh each time.

---

### Session Data Cleanup

When you delete a project, session files remain:

```bash
~/.current-project-session  # May reference deleted project
~/.git-worktrees/           # Stale worktree references
```bash

**To clean up:**

```bash
# Clear session file (if it references deleted project)
rm ~/.current-project-session

# Remove stale worktrees
git worktree prune
```text

---

## Project Organization Best Practices

### Recommended Structure

```text
~/projects/
├── r-packages/
│   ├── active/          # Under development
│   │   ├── pkg1/       # ✅ Has .git
│   │   └── pkg2/       # ✅ Has .git
│   └── stable/          # Released packages
│       └── rmediation/ # ✅ Has .git
│
├── dev-tools/
│   ├── flow-cli/       # ✅ Has .git
│   ├── aiterm/         # ✅ Has .git
│   └── drafts/         # ❌ No .git - not shown
│
└── teaching/
    ├── stat-440/       # ✅ Has .git
    └── temp-notes/     # ❌ No .git - not shown
```bash

**Tip:** If a directory doesn't need version control, it won't clutter your `pick` list!

---

## Customization Examples

### Example 1: Add Client Projects

```bash
# Edit commands/pick.zsh
PROJ_CATEGORIES=(
    # ... existing ...
    "clients/active:client:👥"
    "clients/archive:client:📦"
)
```text

Usage:

```bash
pick client  # Show all client projects
```bash

---

### Example 2: Separate Personal/Work

```bash
PROJ_CATEGORIES=(
    # Work projects
    "work/dev:work:💼"
    "work/design:work:🎨"

    # Personal projects
    "personal/hobbies:personal:🎮"
    "personal/learning:personal:📚"
)
```text

Usage:

```bash
pick work      # Work projects only
pick personal  # Personal projects only
```bash

---

### Example 3: Multiple Project Roots

If your projects are spread across different base directories:

**Current limitation:** `FLOW_PROJECTS_ROOT` is a single path.

**Workaround:** Use symlinks

```bash
# Create links in main projects dir
ln -s ~/work ~/projects/work
ln -s ~/archive ~/projects/archive

# Add to PROJ_CATEGORIES
PROJ_CATEGORIES=(
    # ... existing ...
    "work:work:💼"
    "archive:archive:📦"
)
```bash

---

## Troubleshooting

### Issue: Project doesn't show up

**Check 1: Has .git?**

```bash
cd ~/projects/dev-tools/my-project
ls -la .git
# Should show: drwxr-xr-x  .git/
```bash

**Check 2: In scanned directory?**

```bash
# Project must be in a PROJ_CATEGORIES path
# Example: ~/projects/dev-tools/my-project ✅
#          ~/random/location/my-project ❌
```bash

**Check 3: Permissions?**

```bash
# Ensure directory is readable
chmod +r ~/projects/dev-tools/my-project
```text

---

### Issue: Deleted project still appears

**Cause:** You ran `pick` before deleting, terminal output is old

**Solution:** Run `pick` again - it rescans fresh

```bash
pick dev  # Fresh scan, deleted projects gone
```text

---

### Issue: Too many projects

**Solution 1: Use category filters**

```bash
pick dev    # Only dev-tools
pick r      # Only R packages
```text

**Solution 2: Use --recent flag**

```bash
pick --recent  # Only projects with Claude sessions
pick -r        # Short form
```bash

**Solution 3: Move inactive projects**

```bash
# Move to archive (won't show in pick if not in PROJ_CATEGORIES)
mv ~/projects/dev-tools/old-project ~/archive/
```diff

---

## Performance

### Scan Speed

**Typical performance:**
- 10 projects: ~10ms
- 50 projects: ~30ms
- 100 projects: ~60ms
- 200 projects: ~100ms

**Bottlenecks:**
1. Checking `.git` existence (~1ms per project)
2. Reading Claude session files (~2ms per project)
3. Git status (only in worktree mode, ~10ms per worktree)

### Fast Mode

Skip git status checks:

```bash
pick --fast dev
```bash

**Savings:** ~10ms per worktree (doesn't affect regular projects)

---

## Implementation Details

### Code Flow

```bash
pick
  ↓
_proj_list_all()
  ↓
for each PROJ_CATEGORIES entry:
  ├─ Check if directory exists
  ├─ Scan subdirectories (*/. pattern)
  ├─ Filter: Has .git?
  ├─ Get session metadata
  └─ Add to project_data array
  ↓
Sort by frecency (recent first)
  ↓
Display in FZF
```

**Files:**
- `commands/pick.zsh:206-251` - `_proj_list_all()` function
- `commands/pick.zsh:9-18` - `PROJ_CATEGORIES` array
- `commands/pick.zsh:280-322` - `_proj_list_worktrees()` function

---

## Summary

**Key Points:**

1. ✅ **Automatic discovery** - Just create git repos in scanned directories
2. ✅ **No registration** - No config files to maintain
3. ✅ **Real-time** - Always shows current state
4. ✅ **Simple deletion** - Remove project, it's gone from pick
5. ✅ **Customizable** - Edit `PROJ_CATEGORIES` to add paths

**Requirements:**

- Project must have `.git` directory/file
- Project must be in a `PROJ_CATEGORIES` path
- Directory must be readable

**No caching, no state files, no manual sync needed!**

---

**Last Updated:** 2026-01-10
**Version:** v5.0.0
**Related:** [pick.md](../commands/pick.md), [PICK-COMMAND-REFERENCE.md](./PICK-COMMAND-REFERENCE.md)
