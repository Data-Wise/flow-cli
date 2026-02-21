# pick

> **Interactive project picker with FZF interface for quick navigation**

---

## Synopsis

```bash
pick [CATEGORY] [OPTIONS]
pick [PROJECT-NAME]
```bash

**Quick examples:**

```bash
# Show all projects
pick

# Filter by category
pick dev

# Jump directly to project
pick flow
```diff

---

## Description

The `pick` command provides an interactive, ADHD-friendly way to select and navigate to projects using FZF. It scans your project directories, detects project types, and presents them in a searchable list with smart filtering and session resume capabilities.

**Use cases:**
- Quick navigation between projects
- Discovering forgotten projects
- Filtering projects by category (R, dev, quarto, etc.)
- Resuming recent work sessions

**What it does:**
- Scans `$FLOW_PROJECTS_ROOT` for projects
- Detects project types (.STATUS files, DESCRIPTION, package.json)
- Displays icon-decorated project list
- Filters by category if specified
- Changes directory on selection
- Tracks recent sessions for quick resume

---

### Optional Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `[category]` | `all` | Filter by category: `r`, `dev`, `q`, `teach`, `rs`, `app` |
| `[project-name]` | none | Fuzzy match for direct jump to project |

### Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--fast` | none | Skip git status checks (faster loading) |
| `--all` | `-a` | Force full picker (skip direct jump) |
| `--recent` | `-r` | Show only projects with Claude sessions |
| `--help` | `-h` | Show help message |

### Category Shortcuts

| Category | Code | Icon | Projects |
|----------|------|------|----------|
| R Packages | `r`, `R`, `rpkg` | 📦 | r-packages/active, r-packages/stable |
| Dev Tools | `dev`, `DEV` | 🔧 | dev-tools/ |
| Quarto | `q`, `qu`, `quarto` | 📝 | quarto/manuscripts, quarto/presentations |
| Teaching | `teach`, `teaching` | 🎓 | teaching/ courses |
| Research | `rs`, `research` | 🔬 | research/ projects |
| Applications | `app`, `apps` | 📱 | apps/ |
| Worktrees | `wt` | 🌳 | All git worktrees from ~/.git-worktrees/ |

---

## Usage Examples

### Basic Usage

**Scenario:** Navigate to any project interactively

```bash
# Open picker with all projects
pick
```text

**Output:**

```text
📦 rmediation
📦 medfit
🔧 flow-cli
🔧 atlas
📝 product-of-three
> _
```bash

### Intermediate Usage

**Scenario:** Filter to specific category before picking

```bash
# Show only dev-tools projects
pick dev
```text

**Output:**

```text
🔧 flow-cli
🔧 atlas
🔧 aiterm
🔧 nexus-cli
> _
```bash

### Advanced Usage

**Scenario:** Jump directly to a project without picker

```bash
# Direct jump (no FZF interface)
pick flow
```text

**Output:**

```text
📁 /Users/dt/projects/dev-tools/flow-cli
```bash

---

## Common Patterns

### Pattern 1: Daily Project Rotation

**Use when:** Switching between active projects during day

```bash
# Morning: Research
pick rs

# Afternoon: Dev work
pick dev

# Evening: Teaching prep
pick teach
```bash

### Pattern 2: Category Aliases

**Use when:** Frequent category filtering

```bash
# Shortcut aliases
pickr            # pick r
pickdev          # pick dev
pickq            # pick q
pickteach        # pick teach
pickrs           # pick rs
```bash

### Pattern 3: Recent Projects Only

**Use when:** Resuming work from recent sessions

```bash
# Show only projects with Claude sessions
pick --recent
# or
pick -r
```bash

---

## Combining with Other Commands

### With Claude Code Launcher

```bash
# Pick project, then launch Claude
pick && cc

# Or use CC dispatcher's built-in pick
cc pick
```bash

### With Work Command

```bash
# Pick project, then start work session
pick && work
```text

---

## Interactive Features

### Keybindings

| Key | Action |
|-----|--------|
| `Enter` | Navigate to selected project |
| `Ctrl-C` | Cancel (stay in current directory) |
| `Ctrl-O` | cd to project + launch Claude |
| `Ctrl-Y` | cd to project + launch Claude YOLO mode |
| `Ctrl-S` | View project .STATUS file |
| `Ctrl-L` | View project git log |

### FZF Search

| Input | Behavior |
|-------|----------|
| `flow` | Filter to projects matching "flow" |
| `^flow` | Match beginning: projects starting with "flow" |
| `flow$` | Match end: projects ending with "flow" |
| `!test` | Exclude: all projects except "test" |

### Smart Resume

When you run `pick` without arguments and have a recent session (< 24 hours):

```bash
💡 Last: flow-cli (2h ago)
[Enter] Resume  │  [Space] Browse all  │  Type to search...
```bash

| Key | Action |
|-----|--------|
| Enter | Resume last project |
| Space | Bypass resume, show full picker |
| Type | Search/filter projects |

---

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `FLOW_PROJECTS_ROOT` | `$HOME/projects` | Root directory to scan for projects |
| `FZF_DEFAULT_OPTS` | (various) | Custom FZF options |

**Example:**

```bash
export FLOW_PROJECTS_ROOT="$HOME/work"
pick
```text

### Project Categories

Categories are defined in `PROJ_CATEGORIES`:

```bash
PROJ_CATEGORIES=(
    "r-packages/active:r:📦"
    "r-packages/stable:r:📦"
    "dev-tools:dev:🔧"
    "teaching:teach:🎓"
    "research:rs:🔬"
    "quarto/manuscripts:q:📝"
    "quarto/presentations:q:📊"
    "apps:app:📱"
)
```diff

---

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success (project selected) |
| `1` | No project selected (Ctrl-C) |
| `130` | Interrupted (Ctrl-C) |

---

## Troubleshooting

### Issue 1: "No projects found"

**Symptoms:**
- Empty FZF picker
- Message: "No projects found in /Users/dt/projects"

**Cause:** `FLOW_PROJECTS_ROOT` not set or points to wrong directory

**Solution:**

```bash
# Check current setting
echo $FLOW_PROJECTS_ROOT

# Set in .zshrc
export FLOW_PROJECTS_ROOT="$HOME/projects"
```diff

### Issue 2: Projects missing from list

**Symptoms:**
- Some projects don't appear in picker
- Expected 10 projects, only see 5

**Cause:** Projects lack detection markers (.STATUS, DESCRIPTION, package.json, etc.)

**Solution:**

```bash
# Add .STATUS file to project
cd missing-project
echo "status: active" > .STATUS
```diff

### Issue 3: Keybindings don't work

**Symptoms:**
- Ctrl-O, Ctrl-Y don't launch Claude
- Ctrl-S doesn't show .STATUS

**Cause:** FZF version too old or custom FZF_DEFAULT_OPTS conflict

**Solution:**

```bash
# Update FZF
brew upgrade fzf

# Check for conflicting options
echo $FZF_DEFAULT_OPTS
```

---

## Best Practices

**Do:**
- ✅ Use category filters for faster navigation (`pick dev`)
- ✅ Add .STATUS files to all projects (improves detection)
- ✅ Use `pick --recent` to resume work quickly
- ✅ Learn keybindings (Ctrl-O for quick Claude launch)

**Don't:**
- ❌ Type full project names when `pick` is faster
- ❌ Navigate manually with `cd` between known projects
- ❌ Ignore session indicators (🟢/🟡) on worktrees
- ❌ Use `ls` when `pick` provides better UX

---

## Related Commands

- **hop** — Quick switch to last project
- **work** — Start work session (can use pick for project selection)
- **dash** — Project dashboard (shows all projects in table)
- **cc pick** — Launch Claude with project picker (combines both)

---

## See Also

- **Tutorial:** [Tutorial 2: Multiple Projects](../tutorials/02-multiple-projects.md)
- **Reference:** [Pick Command Reference](../reference/MASTER-DISPATCHER-GUIDE.md)
- **Guide:** [Project Detection Guide](../reference/MASTER-DISPATCHER-GUIDE.md#dispatcher-comparison-table)

---

**Last Updated:** 2026-01-07
**Command Version:** v4.8.0 (worktree-aware)
**Status:** ✅ Production ready with FZF interface, worktree support, session indicators
