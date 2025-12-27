# pick

> Interactive project picker with fzf

The `pick` command provides an interactive, ADHD-friendly way to select and navigate to projects. It supports category filtering, fuzzy matching, and smart session resume.

---

## Usage

```bash
pick [options] [category|project-name]
```

## Arguments

| Argument       | Description                          |
| -------------- | ------------------------------------ |
| `category`     | Filter by category (r, dev, q, etc.) |
| `project-name` | Fuzzy match for direct jump          |

## Options

| Flag        | Description                             |
| ----------- | --------------------------------------- |
| `--fast`    | Skip git status checks (faster loading) |
| `-a, --all` | Force full picker (skip direct jump)    |

---

## Categories

| Shortcut            | Category          | Icon |
| ------------------- | ----------------- | ---- |
| `r`, `R`, `rpkg`    | R packages        | 📦   |
| `dev`, `DEV`        | Development tools | 🔧   |
| `q`, `qu`, `quarto` | Quarto projects   | 📝   |
| `teach`, `teaching` | Teaching courses  | 🎓   |
| `rs`, `research`    | Research projects | 🔬   |
| `app`, `apps`       | Applications      | 📱   |

---

## Examples

### Interactive Picker

```bash
# Show all projects
pick

# Filter by category
pick dev         # Development tools only
pick r           # R packages only
pick teach       # Teaching courses only
```

### Direct Jump

```bash
# Jump directly to matching project
pick flow        # → cd to flow-cli (if unique match)
pick med         # → cd to mediationverse

# If multiple matches, shows filtered picker
pick stat        # Shows all projects containing "stat"
```

### Category Aliases

```bash
pickr            # pick r
pickdev          # pick dev
pickq            # pick q
```

---

## Smart Resume

When you run `pick` without arguments and have a recent session (< 24 hours), you'll see:

```
╔════════════════════════════════════════════════════════════╗
║  🔍 PROJECT PICKER                                          ║
╚════════════════════════════════════════════════════════════╝

  💡 Last: flow-cli (2h ago)
  [Enter] Resume  │  [Space] Browse all  │  Type to search...
```

| Key   | Action                          |
| ----- | ------------------------------- |
| Enter | Resume last project             |
| Space | Bypass resume, show full picker |
| Type  | Search/filter projects          |

---

## Interactive Keys

While in the fzf picker:

| Key    | Action                  |
| ------ | ----------------------- |
| Enter  | Go to project directory |
| Ctrl-S | View .STATUS file       |
| Ctrl-L | View git log            |
| Ctrl-C | Exit without action     |

---

## Output

When selecting a project:

```
  📂 /Users/dt/projects/dev-tools/flow-cli
```

When viewing .STATUS (Ctrl-S):

```
  📊 .STATUS file for: flow-cli

  ## Status: Active
  ## Phase: v4.0.1 Released
  ## Focus: Documentation enhancement
```

---

## Configuration

Projects are discovered from `$FLOW_PROJECTS_ROOT` (default: `~/projects`). Categories are defined in:

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
```

---

## Tips

!!! tip "Direct Jump for Speed"
If you know your project name, use direct jump: `pick flow` is faster than browsing the full picker.

!!! tip "Category Filtering"
When you have many projects, filter by category first: `pick dev` shows only dev tools.

!!! tip "Resume Your Session"
Just press Enter when the resume hint appears to continue where you left off.

---

## Related Commands

| Command           | Description                   |
| ----------------- | ----------------------------- |
| [`work`](work.md) | Start session (includes pick) |
| [`hop`](hop.md)   | Quick switch (tmux)           |
| [`dash`](dash.md) | View all projects dashboard   |

---

## See Also

- [`work`](work.md) - Start a full work session
- [`hop`](hop.md) - Quick project switch with tmux
- [Workflow Quick Reference](../reference/WORKFLOW-QUICK-REFERENCE.md)
