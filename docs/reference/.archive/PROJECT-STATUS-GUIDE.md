# Project Status Detection & Updates

**Quick Answer:** flow-cli reads `.STATUS` files in project directories to determine project state. Updates are manual (you edit the file) or automatic (via `work`/`finish` commands).

---

## Overview

Project status in flow-cli comes from **`.STATUS` files** in your project root:

```yaml
# .STATUS file format
status: active           # Current state
progress: 75            # 0-100 completion
next: Implement auth    # Next action
target: v2.0.0          # Goal/milestone
```

**Where it's used:**
- `dash` - Shows status in project dashboard
- `work` - Reads current status when starting sessions
- `finish` - Can update status when ending sessions
- `pick` - Improves project detection (optional)

---

## How Status Detection Works

### 1. File Location

flow-cli looks for `.STATUS` in:

```bash
~/projects/dev-tools/flow-cli/.STATUS       # Project root
~/projects/research/mediation/.STATUS       # Project root
~/projects/teaching/stat-440/.STATUS        # Project root
```

**Not searched:**
- Subdirectories (`.STATUS` must be at project root)
- Parent directories (doesn't traverse up)
- Worktrees (each worktree can have its own `.STATUS`)

---

### 2. Status Field Values

The `status:` field determines the project state:

| Value | Icon | Meaning | Use When |
|-------|------|---------|----------|
| `active` or `ACTIVE` | 🟢 | Actively working | Current focus projects |
| `paused` or `PAUSED` | 🟡 | Temporarily on hold | Waiting for feedback/review |
| `blocked` or `BLOCKED` | 🔴 | Can't proceed | Missing deps/decisions |
| `archived` or `ARCHIVED` | ⚫ | No longer active | Completed/abandoned |
| `stalled` | 🟠 | Stuck, needs attention | Lost momentum |
| (missing) | ⚪ | Unknown | No .STATUS file |

**Code reference:** `lib/core.zsh:59-68` (`_flow_status_icon()`)

---

### 3. Reading Status

**Manual check:**

```bash
cat .STATUS
```

**Programmatic (in ZSH functions):**

```bash
# Find project root first
root=$(_flow_find_project_root)

# Read status field
if [[ -f "$root/.STATUS" ]]; then
    status=$(grep "^status:" "$root/.STATUS" | cut -d: -f2 | xargs)
    echo "Project status: $status"
fi
```

**Via dashboard:**

```bash
dash              # Shows all projects with status
dash research     # Filter by category
```

---

## Status File Format

### Basic Format

```yaml
status: active
progress: 60
next: Add tests for new API
target: v2.1.0
```

**Fields:**

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `status:` | ✅ | String | Project state (active/paused/blocked/archived) |
| `progress:` | ❌ | Number | 0-100 completion percentage |
| `next:` | ❌ | String | Next action item |
| `target:` | ❌ | String | Goal/milestone/deadline |

---

### Real Examples

**Active development:**

```yaml
status: active
progress: 75
next: Implement authentication middleware
target: v2.0.0 release
```

**Paused (waiting):**

```yaml
status: paused
progress: 40
next: Wait for API review feedback
target: Launch by Q2
```

**Blocked:**

```yaml
status: blocked
progress: 30
next: Need design approval from team
target: MVP
```

**Archived:**

```yaml
status: archived
progress: 100
next: N/A
target: Completed - migrated to new repo
```

---

### Extended Format (Optional)

You can add any extra fields for your own use:

```yaml
status: active
progress: 85
next: Write documentation
target: v1.5.0

# Custom fields
priority: high
team: backend
sprint: sprint-24
last-updated: 2026-01-10
notes: |
  Waiting for code review on PR #234.
  Database migration needs testing.
```

**Note:** flow-cli only reads `status`, `progress`, `next`, and `target`. Other fields are ignored but preserved.

---

## Creating .STATUS Files

### Manual Creation

```bash
# Create in project root
cd ~/projects/dev-tools/my-project
cat > .STATUS << 'EOF'
status: active
progress: 0
next: Initialize project structure
target: v0.1.0
EOF
```

---

### Template Script

Create a helper function in your `.zshrc`:

```bash
# Add to ~/.zshrc or ~/.config/zsh/.zshrc
new_status() {
    local status="${1:-active}"
    cat > .STATUS << EOF
status: $status
progress: 0
next: TODO
target: TBD
EOF
    echo "✅ Created .STATUS with status: $status"
}
```

**Usage:**

```bash
cd my-project
new_status active
# → Creates .STATUS file
```

---

### Via Work Command

The `work` command can create `.STATUS` if it doesn't exist:

```bash
cd ~/projects/dev-tools/new-project
work new-project

# If .STATUS doesn't exist, work prompts:
# "No .STATUS file found. Create one? [y/N]"
```

---

## Updating Status

### Manual Updates

**Quick edit with vim:**

```bash
vim .STATUS
```

**Quick edit with bat:**

```bash
bat .STATUS             # View
$EDITOR .STATUS         # Edit
```

**Inline update (status only):**

```bash
# Change status to paused
sed -i '' 's/^status:.*/status: paused/' .STATUS
```

---

### Via Commands

**Update when finishing work:**

```bash
finish "Completed authentication"

# Prompts:
# "Update status? [y/N]"
# "New status (active/paused/blocked/archived): paused"
# "Update progress (0-100): 75"
```

**Update via work command:**

```bash
work --status paused
# Updates .STATUS to paused before starting session
```

---

### Programmatic Updates (ZSH)

```bash
# Function to update status field
update_project_status() {
    local new_status="$1"
    local status_file=".STATUS"

    if [[ ! -f "$status_file" ]]; then
        echo "status: $new_status" > "$status_file"
    else
        sed -i '' "s/^status:.*/status: $new_status/" "$status_file"
    fi

    echo "✅ Status updated to: $new_status"
}

# Usage
update_project_status paused
```

---

## Dashboard Integration

### How Dash Uses .STATUS

The `dash` command scans all project directories and reads `.STATUS` files:

**Process:**
1. Scans `$FLOW_PROJECTS_ROOT` recursively
2. Finds `.STATUS` files
3. Parses `status:`, `progress:`, `next:`, `target:` fields
4. Displays in table format with icons

**Example output:**

```
┌─────────────────┬────────┬──────────┬─────────────────────┬───────────┐
│ Project         │ Status │ Progress │ Next                │ Target    │
├─────────────────┼────────┼──────────┼─────────────────────┼───────────┤
│ flow-cli        │ 🟢     │ 85%      │ Add tests           │ v5.0.0    │
│ aiterm          │ 🟢     │ 70%      │ CI optimization     │ v0.7.0    │
│ research-study  │ 🟡     │ 40%      │ Wait for IRB        │ Submit Q2 │
│ old-prototype   │ ⚫     │ 100%     │ Archived            │ Completed │
└─────────────────┴────────┴──────────┴─────────────────────┴───────────┘
```

**Filtering:**

```bash
dash                  # All projects
dash --active         # Only active (🟢)
dash --paused         # Only paused (🟡)
dash dev              # Category filter
```

---

### Inventory Mode

The `dash --inventory` command auto-generates tool inventory from `.STATUS` files:

```bash
dash --inventory
```

**Output:**

```markdown
# Tool Inventory - 2026-01-10

## Active Development (4)
- flow-cli - v5.0.0 (85%) - ZSH workflow system
- aiterm - v0.7.0 (70%) - Terminal context manager

## Paused (2)
- research-study - Submit Q2 (40%) - Causal inference study

## Archived (1)
- old-prototype - Completed (100%) - Legacy system
```

---

## Best Practices

### DO ✅

**1. Keep .STATUS files up to date**

```bash
# Update after major milestones
vim .STATUS
# Change: progress: 60 → 75
```

**2. Use descriptive "next" actions**

```yaml
# Good
next: Write unit tests for API endpoints

# Bad
next: TODO
```

**3. Set realistic targets**

```yaml
# Good
target: v2.0.0 release (March 2026)

# Bad
target: Soon
```

**4. Commit .STATUS to git**

```bash
git add .STATUS
git commit -m "docs: update project status to active"
```

---

### DON'T ❌

**1. Don't use inconsistent status values**

```yaml
# ❌ Bad - typos, won't match icon logic
status: activ
status: Active
status: in-progress

# ✅ Good - use standard values
status: active
status: paused
status: blocked
status: archived
```

**2. Don't leave status files stale**

```yaml
# ❌ Bad - outdated info
status: active
progress: 10
next: Start project
# (Project actually at 80% completion)

# ✅ Good - keep it current
status: active
progress: 80
next: Final code review
```

**3. Don't skip .STATUS files**
- Every project should have one
- Even "just starting" projects benefit from tracking

---

## Automation Examples

### Auto-create .STATUS on git init

Add to `.zshrc`:

```bash
# Hook: Create .STATUS when initializing git repos
git() {
    command git "$@"

    # After 'git init', create .STATUS
    if [[ "$1" == "init" ]]; then
        if [[ ! -f .STATUS ]]; then
            cat > .STATUS << 'EOF'
status: active
progress: 0
next: Initial setup
target: v0.1.0
EOF
            echo "✅ Created .STATUS file"
        fi
    fi
}
```

---

### Weekly status review script

```bash
# weekly-review.sh - Find projects that need status updates
#!/bin/zsh

echo "Projects needing review:\n"

for status_file in ~/projects/**/.STATUS; do
    dir=$(dirname "$status_file")
    project=$(basename "$dir")

    # Check last modified date
    if [[ $(find "$status_file" -mtime +7) ]]; then
        echo "⚠️  $project - .STATUS not updated in 7+ days"
        echo "   $status_file"
        echo ""
    fi
done
```

---

### Sync status to GitHub labels

```bash
# sync-status-to-github.sh
#!/bin/zsh

# Read .STATUS
status=$(grep "^status:" .STATUS | cut -d: -f2 | xargs)

# Update GitHub repo label
case "$status" in
    active)
        gh repo edit --add-topic active-development
        ;;
    paused)
        gh repo edit --add-topic on-hold
        ;;
    archived)
        gh repo archive
        ;;
esac
```

---

## Integration with Other Tools

### VS Code Extension

Create `.vscode/settings.json`:

```json
{
  "todo-tree.regex.regex": "((//|#|<!--|;|/\\*|^)\\s*($TAGS)|^\\s*- \\[ \\])",
  "files.associations": {
    ".STATUS": "yaml"
  },
  "yaml.schemas": {
    "./status-schema.json": "**/.STATUS"
  }
}
```

**Schema validation:** Create `status-schema.json`:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "status": {
      "type": "string",
      "enum": ["active", "paused", "blocked", "archived", "stalled"]
    },
    "progress": {
      "type": "integer",
      "minimum": 0,
      "maximum": 100
    },
    "next": { "type": "string" },
    "target": { "type": "string" }
  },
  "required": ["status"]
}
```

---

### Alfred Workflow

Create Alfred workflow to show project status:

**Script:**

```bash
#!/bin/zsh
cd ~/projects/dev-tools/flow-cli
status=$(grep "^status:" .STATUS | cut -d: -f2 | xargs)
progress=$(grep "^progress:" .STATUS | cut -d: -f2 | xargs)
echo "flow-cli: $status ($progress%)"
```

---

## Troubleshooting

### Issue: Status not showing in dash

**Symptom:** Project appears but status is ⚪ (unknown)

**Cause 1:** No `.STATUS` file

```bash
cd project-dir
ls -la .STATUS
# → No such file
```

**Solution:**

```bash
cat > .STATUS << 'EOF'
status: active
progress: 50
next: Continue development
target: v1.0.0
EOF
```

**Cause 2:** Invalid YAML syntax

```bash
cat .STATUS
# → status active  (missing colon)
```

**Solution:**

```bash
# Fix syntax
echo "status: active" > .STATUS
```

---

### Issue: Changes not reflected in dash

**Cause:** Dashboard might be cached (if using `--watch` mode)

**Solution:** Refresh dashboard

```bash
# Exit watch mode (Ctrl-C) and restart
dash --watch
```

---

### Issue: Multiple .STATUS files conflict

**Symptom:** Project root has `.STATUS`, worktree has another `.STATUS`

**Expected behavior:** Each worktree can have its own status

**Solution:** This is intentional - worktrees are independent. To sync:

```bash
# Copy main .STATUS to worktree
cp ~/projects/dev-tools/flow-cli/.STATUS \
   ~/.git-worktrees/flow-cli/feature-branch/.STATUS
```

---

## Related Commands

- **dash** - Display project dashboard with status
- **work** - Start work session (reads .STATUS)
- **finish** - End session (can update .STATUS)
- **pick** - Project picker (detects .STATUS for better display)

---

## Summary

**Key Points:**

1. ✅ `.STATUS` files track project state
2. ✅ Four main fields: `status`, `progress`, `next`, `target`
3. ✅ Manual editing or command updates (work/finish)
4. ✅ Used by `dash`, `work`, `pick` commands
5. ✅ Commit to git for team visibility

**Quick workflow:**

```bash
# Create project
mkdir my-project && cd my-project
git init

# Add status file
cat > .STATUS << 'EOF'
status: active
progress: 0
next: Initial setup
target: v0.1.0
EOF

# Track progress
vim .STATUS  # Update periodically

# View in dashboard
dash
```

---

**Last Updated:** 2026-01-10
**Version:** v5.0.0
**Related:** [dash.md](../commands/dash.md), [work.md](../commands/work.md), [PROJECT-MANAGEMENT-STANDARDS.md](../conventions/project/PROJECT-MANAGEMENT-STANDARDS.md)
