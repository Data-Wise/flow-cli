# `dash` - Master Project Dashboard

> **Unified project dashboard with smart categorization and .STATUS file sync**

**Command:** `dash [category]`
**Purpose:** Unified view of all active work across projects
**Type:** Display/Reporting

---

## Synopsis

```bash
dash [option|category]
dash -i          # Interactive fzf picker
dash -w          # Watch mode (auto-refresh every 5s)
dash -a          # Show all projects (flat list)
```bash

**Quick examples:**

```bash
# Summary dashboard (default)
dash

# Filter by category
dash dev
dash r
dash teaching

# Interactive mode with fzf
dash -i

# Watch mode (auto-refresh)
dash -w           # Refresh every 5s
dash -w 10        # Refresh every 10s

# Show all projects (flat list)
dash -a
```diff

---

## Options

| Option         | Short | Description                            |
| -------------- | ----- | -------------------------------------- |
| `--all`        | `-a`  | Show all projects (flat list)          |
| `-i`           | -     | Interactive mode with fzf picker       |
| `-w [sec]`     | -     | Watch mode — auto-refresh (default 5s) |
| `--full`       | `-f`  | Interactive TUI (requires atlas)       |
| `--help`       | `-h`  | Show help                              |

## Categories

| Category   | Path                   |
| ---------- | ---------------------- |
| `dev`      | `~/projects/dev-tools` |
| `r`        | `~/projects/r-packages`|
| `research` | `~/projects/research`  |
| `teach`    | `~/projects/teaching`  |
| `quarto`   | `~/projects/quarto`    |
| `apps`     | `~/projects/apps`      |

---

## 📸 Example Output

![Dashboard Example](../assets/dashboard-example.png)

*The flow-cli dashboard showing active session, quick access projects, and category breakdown*

---

## 🎯 Quick Summary

The `dash` command scans all `.STATUS` files across your projects, categorizes them by status (active/ready/paused/blocked), and displays a formatted dashboard. When run with "all" category, it also syncs status files to a central project-hub for coordination.

---

## 📊 Visual Flow

### Simple View

```mermaid
flowchart LR
    A([dash category]) --> B{Scan Projects}
    B --> C[Categorize]
    C --> D([Display Dashboard])

    style A fill:#4CAF50,stroke:#2E7D32,color:#fff
    style D fill:#2196F3,stroke:#1565C0,color:#fff
```text

**In plain words:** Input → Scan → Organize → Display

---

### Detailed Flow

<details>
<summary>Click to expand full procedure diagram</summary>

```mermaid
flowchart TD
    Start([User: dash category]) --> CheckCategory{Category<br/>specified?}

    CheckCategory -->|all| SyncSection[📦 SYNC SECTION]
    CheckCategory -->|teaching/research/etc| FilterPath[Set filter path]

    subgraph SyncSection[" "]
        SyncStart[🔄 Start sync process]
        FindAllStatus[Find all .STATUS files<br/>in ~/projects]
        ExcludeHub[Exclude /project-hub]
        IterateFiles[For each .STATUS file:]
        ExtractInfo[Extract:<br/>• project name<br/>• category<br/>• file path]
        CreateDir[Create category dir<br/>in project-hub]
        CopyFile[Copy .STATUS<br/>to hub location]
        CountSync[Count synced files]
        UpdateTime[Update coordination<br/>timestamp]

        SyncStart --> FindAllStatus
        FindAllStatus --> ExcludeHub
        ExcludeHub --> IterateFiles
        IterateFiles --> ExtractInfo
        ExtractInfo --> CreateDir
        CreateDir --> CopyFile
        CopyFile --> CountSync
        CountSync --> UpdateTime
    end

    SyncSection --> FilterPath

    FilterPath --> ScanFiles[Scan .STATUS files<br/>in filter path]

    ScanFiles --> ParseLoop[For each file:]
    ParseLoop --> ParseFields[Parse fields:<br/>• status<br/>• priority<br/>• progress<br/>• next action<br/>• type]

    ParseFields --> GetIcon{Determine icon}
    GetIcon -->|r package| IconR[📦]
    GetIcon -->|teaching| IconTeach[📚]
    GetIcon -->|research| IconRes[📊]
    GetIcon -->|quarto| IconQ[📝]
    GetIcon -->|dev tool| IconDev[🔧]
    GetIcon -->|obsidian| IconObs[📓]

    IconR --> Categorize
    IconTeach --> Categorize
    IconRes --> Categorize
    IconQ --> Categorize
    IconDev --> Categorize
    IconObs --> Categorize

    Categorize{Status?}

    Categorize -->|active/working| ActiveList[🔥 Active Projects<br/>Store in array]
    Categorize -->|ready/todo| ReadyList[📋 Ready Projects<br/>Store in array]
    Categorize -->|paused/hold| PausedList[⏸️ Paused Projects<br/>Store in array]
    Categorize -->|blocked| BlockedList[🚫 Blocked Projects<br/>Store in array]

    ActiveList --> HasActive{Any active?}
    ReadyList --> HasReady{Any ready?}
    PausedList --> HasPaused{Any paused?}
    BlockedList --> HasBlocked{Any blocked?}

    HasActive -->|yes| DisplayActive[Display Active Section<br/>with priority colors]
    HasActive -->|no| CheckNext1
    DisplayActive --> CheckNext1[Check next category]

    HasReady -->|yes| DisplayReady[Display Ready Section]
    HasReady -->|no| CheckNext2
    DisplayReady --> CheckNext2[Check next category]

    HasPaused -->|yes| DisplayPaused[Display Paused Section]
    HasPaused -->|no| CheckNext3
    DisplayPaused --> CheckNext3[Check next category]

    HasBlocked -->|yes| DisplayBlocked[Display Blocked Section]
    HasBlocked -->|no| ShowSummary
    DisplayBlocked --> ShowSummary

    CheckNext1 --> HasReady
    CheckNext2 --> HasPaused
    CheckNext3 --> HasBlocked

    ShowSummary[Calculate total count]
    ShowSummary --> AnyProjects{Projects > 0?}

    AnyProjects -->|yes| ShowActions[Display quick actions:<br/>• work name<br/>• status name<br/>• dash category]
    AnyProjects -->|no| ShowHelp[Show help:<br/>• No projects found<br/>• Tip: create .STATUS]

    ShowActions --> End([Done])
    ShowHelp --> End

    style Start fill:#4CAF50,stroke:#2E7D32,color:#fff
    style SyncSection fill:#E3F2FD,stroke:#1976D2
    style DisplayActive fill:#FFEBEE,stroke:#C62828
    style DisplayReady fill:#E8F5E9,stroke:#2E7D32
    style DisplayPaused fill:#FFF9C4,stroke:#F57F17
    style DisplayBlocked fill:#FFCDD2,stroke:#C62828
    style End fill:#4CAF50,stroke:#2E7D32,color:#fff
```diff

</details>

---

## 📝 Step-by-Step Procedure

For accessibility and text-based reference:

### Phase 1: Category Parsing

1. Parse the category argument (default: "all")
2. Validate category is one of: all, teaching, research, packages, dev, quarto

### Phase 2: Sync (Only for "all" category)

1. Find all `.STATUS` files in `~/projects` (excluding `/project-hub`)
2. For each `.STATUS` file:
   - Extract project name, category, and path
   - Create category directory in `~/projects/project-hub/` if needed
   - Copy `.STATUS` file to `project-hub/category/name.STATUS`
   - Increment sync counter
3. Display sync completion message with count
4. Update coordination timestamp in `PROJECT-HUB.md`

### Phase 3: Filter Setup

1. Set filter path based on category:
   - `teaching` → `~/projects/teaching`
   - `research` → `~/projects/research`
   - `packages` → `~/projects/r-packages`
   - `dev` → `~/projects/dev-tools`
   - `quarto` → `~/projects/quarto`
   - `all` → `~/projects`

### Phase 4: Scan & Parse

1. Find all `.STATUS` files in filter path
2. For each `.STATUS` file:
   - Parse fields: `status`, `priority`, `progress`, `next`, `type`
   - Assign default values if fields missing
   - Determine project icon based on type
   - Create entry: `icon name | priority | progress | next`

### Phase 5: Categorization

1. Categorize each entry by status:
    - `active/working/in progress` → Active Projects array
    - `ready/todo/planned` → Ready Projects array
    - `paused/hold/waiting` → Paused Projects array
    - `blocked` → Blocked Projects array

### Phase 6: Display

1. Display header with category name
2. If Active Projects array not empty:
    - Display "🔥 ACTIVE NOW" section
    - For each project: show name, priority (colored), progress %, next action
3. If Ready Projects array not empty:
    - Display "📋 READY TO START" section
    - For each project: show name, priority (colored), next action
4. If Paused Projects array not empty:
    - Display "⏸️ PAUSED" section
    - For each project: show name, next action (dimmed)
5. If Blocked Projects array not empty:
    - Display "🚫 BLOCKED" section
    - For each project: show name, next action (dimmed)

### Phase 7: Summary & Actions

1. Calculate total project count
2. If total = 0:
    - Show "No projects found" message
    - Display tip about creating `.STATUS` files
3. If total > 0:
    - Display separator line
    - Show quick actions menu:
      - `work <name>` - Start working on a project
      - `status <name>` - Update project status
      - `dash [category]` - Filter by category or show all

---

## 🆕 New in v3.5.0

### Watch Mode

Auto-refresh the dashboard:

```bash
dash --watch        # Refresh every 5 seconds
dash --watch 10     # Custom interval (seconds)
```text

### Interactive TUI

Enhanced keyboard shortcuts in `dash -i`:

| Key      | Action            |
| -------- | ----------------- |
| `Enter`  | Open project      |
| `Ctrl-E` | Edit .STATUS file |
| `Ctrl-S` | Show status       |
| `Ctrl-W` | Log a win         |
| `?`      | Show help         |

### Wins Section

The dashboard now shows recent wins and streak:

```text
┌─ 🎉 Recent Wins ─────────────────────────────────────────────┐
│ 🎯 Daily Goal: ██████░░░░ 2/3                                │
│                                                              │
│ 💻 Implemented auth service              14:20               │
│ 🔧 Fixed login redirect bug              11:45               │
└──────────────────────────────────────────────────────────────┘
```text

See [Dopamine Features Guide](../guides/DOPAMINE-FEATURES-GUIDE.md) for details.

---

## 💡 Usage Examples

### Example 1: View All Projects

```bash
$ dash
```text

**Output:**

```text
🔄 Updating project coordination...
  ✓ Synced 12 .STATUS files to project-hub
  ✓ Updated coordination timestamp: 2025-12-22 15:30:45

✅ Coordination complete

╭─────────────────────────────────────────────╮
│ 🎯 YOUR WORK DASHBOARD                      │
╰─────────────────────────────────────────────╯

🔥 ACTIVE NOW (3):
  📦 medfit [P0] 45% - Implement GLM
  📚 STAT-579 [P1] 60% - Grade assignments
  🔧 flow-cli [P2] 80% - Add diagrams to docs

📋 READY TO START (2):
  📊 collider [P1] - Respond to reviewers
  📦 medsim [P2] - Add simulation examples

⏸️ PAUSED (1):
  📊 sensitivity [P2] - Waiting for data

────────────────────────────────────────────────

💡 Quick actions:
   work <name>         Start working on a project
   status <name>       Update project status
   dash teaching       Filter by category
```text

---

### Example 2: Filter by Category

```bash
$ dash teaching
```text

**Output:**

```text
╭─────────────────────────────────────────────╮
│ 🎯 TEACHING DASHBOARD                       │
╰─────────────────────────────────────────────╯

🔥 ACTIVE NOW (1):
  📚 STAT-579 [P1] 60% - Grade assignments

📋 READY TO START (1):
  📚 STAT-440 [P2] - Prepare Week 15 lecture

────────────────────────────────────────────────

💡 Quick actions:
   work <name>         Start working on a project
   status <name>       Update project status
   dash                Show all projects
```text

---

### Example 3: No Projects Found

```bash
$ dash dev
```text

**Output:**

```text
╭─────────────────────────────────────────────╮
│ 🎯 DEV-TOOLS DASHBOARD                      │
╰─────────────────────────────────────────────╯

No projects found with .STATUS files

💡 Tip: Create .STATUS files with:
   status <project> --create
```yaml

---

## 🎨 Priority Color Coding

When displaying projects, priorities are color-coded:

| Priority | Color     | Use Case             |
| -------- | --------- | -------------------- |
| **P0**   | 🔴 Red    | Critical/Urgent work |
| **P1**   | 🟡 Yellow | High priority        |
| **P2**   | 🔵 Blue   | Medium priority      |
| **--**   | ⚪ Gray   | No priority set      |

---

## ⚡ Quick Wins Section (v3.4.0+)

The dashboard now includes a **Quick Wins** section showing tasks that can be completed in under 30 minutes. This is designed for ADHD-friendly productivity - easy wins to build momentum.

### Triggering Quick Wins

Projects appear in Quick Wins when their `.STATUS` file contains:

```yaml
# Option 1: Mark as quick win directly
quick_win: yes

# Option 2: Set estimate under 30 minutes
estimate: 15m
estimate: 20min
```text

### Display

```text
  ⚡ QUICK WINS (< 30 min)
  ├─ ⚡ flow-cli      Fix typo in docs          ~15m
  ├─ 🔥 medfit       Update version number     ~10m
  └─ ⏰ stat-440     Post grades               ~20m
```yaml

---

## 🔥 Urgency Indicators (v3.4.0+)

Projects can show urgency indicators in the Quick Access and Quick Wins sections:

| Icon | Urgency | Trigger                                        |
| ---- | ------- | ---------------------------------------------- |
| 🔥   | High    | `urgency: high`, `deadline: today`, or overdue |
| ⏰   | Medium  | `urgency: medium` or deadline within 3 days    |
| ⚡   | Low     | Quick win or `priority: low`                   |

### Setting Urgency in .STATUS

```yaml
# Direct urgency setting
urgency: high

# Or via deadline (YYYY-MM-DD format)
deadline: 2025-12-27

# Or via priority
priority: 1 # Maps to high urgency
```yaml

---

## 📂 File Dependencies

### Required Files

- `.STATUS` files in project directories
- Format: Key-value pairs with fields

  ```yaml
  status: active
  priority: P0
  progress: 45
  next: Implement GLM
  type: r
  ```

### Optional Directories

- `~/projects/project-hub/` - Central coordination hub
- `~/projects/project-hub/PROJECT-HUB.md` - Coordination file

---

## ⚙️ Configuration

### Category Paths

The command maps category arguments to filesystem paths:

```zsh
teaching  → ~/projects/teaching
research  → ~/projects/research
packages  → ~/projects/r-packages
dev       → ~/projects/dev-tools
quarto    → ~/projects/quarto
all       → ~/projects (root)
```text

### Status Mapping

The command recognizes these status values (case-insensitive):

```text
Active:  active, working, in progress
Ready:   ready, todo, planned
Paused:  paused, hold, waiting
Blocked: blocked
```diff

---

## 🔗 Related Commands

| Command         | Purpose                         |
| --------------- | ------------------------------- |
| `work <name>`   | Start working on a project      |
| `status <name>` | Update project status           |
| `pick`          | Interactive project picker      |
| `js`            | Just start (auto-picks project) |
| `finish`        | End session and commit          |

---

## 🎯 Design Philosophy

The `dash` command follows these ADHD-friendly principles:

1. **Visual Hierarchy** - Color-coded sections, emoji icons
2. **Quick Scan** - Key info visible at a glance
3. **Action-Oriented** - Shows next steps, not just status
4. **Low Friction** - One command to see everything
5. **Coordination** - Auto-syncs for multi-project awareness

---

## 🐛 Troubleshooting

### Issue: No projects shown

**Cause:** Missing `.STATUS` files

**Solution:**

```bash
# Create .STATUS file in project directory
cd ~/projects/my-project
status . --create
```bash

---

### Issue: Sync failed

**Cause:** project-hub directory doesn't exist

**Solution:**

```bash
# Create project-hub manually
mkdir -p ~/projects/project-hub
```bash

---

### Issue: Wrong category displayed

**Cause:** Project in unexpected directory structure

**Solution:**

```bash
# Check project location
pwd
# Should be under ~/projects/category/project-name
```

---

## 📚 Source Code

**File:** `~/.config/zsh/functions/dash.zsh`
**Lines:** 22-326 (main function)
**Dependencies:**

- `find` command
- `grep` command
- `.STATUS` file format

**Key Functions:**

- `dash()` - Main entry point (line 22)
- `_dash_help()` - Help display (line 282)

---

## ✅ Best Practices

1. **Keep .STATUS files updated** - Run `status` regularly
2. **Use consistent priorities** - P0 for critical, P1 for high, P2 for normal
3. **Write clear "next" actions** - Specific, actionable items
4. **Set project types** - Helps with icon display
5. **Run `dash` daily** - Morning check-in habit

---

## 🎓 See Also

- [Status Command Reference](status.md) - Update project status
- [Project Detection Guide](../reference/MASTER-DISPATCHER-GUIDE.md#dispatcher-comparison-table) - How types are detected
- [Workflow Quick Reference](../help/WORKFLOWS.md) - Common workflows

---

**Last Updated:** 2026-01-07
**Command Version:** v4.8.0
**Status:** ✅ Production ready with interactive TUI
