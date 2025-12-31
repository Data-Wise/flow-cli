# flow sync

**Unified sync orchestration for flow-cli v4.0.0**

Synchronize workflow data across all flow-cli components with a single command. Designed for ADHD-friendly operation with smart detection, clear feedback, and safe defaults.

---

## Quick Start

```bash
flow sync              # Smart sync - see what needs syncing
flow sync all          # Sync everything
flow sync --status     # View sync dashboard
```

---

## Synopsis

```bash
flow sync [target] [options]
```

### Targets

| Target    | Description                                 | Speed  |
| --------- | ------------------------------------------- | ------ |
| `session` | Persist current session data to worklog     | ~2ms   |
| `status`  | Update .STATUS timestamps and streaks       | ~120ms |
| `wins`    | Aggregate project wins to global wins.md    | ~15ms  |
| `goals`   | Recalculate daily goal progress             | ~5ms   |
| `git`     | Smart git push/pull with stash handling     | ~1.2s  |
| `remote`  | iCloud sync for multi-device access         | ~10ms  |
| `all`     | Run all targets in dependency order         | ~1.4s  |
| (none)    | Smart sync - auto-detect what needs syncing | ~50ms  |

### Options

| Option       | Short | Description                        |
| ------------ | ----- | ---------------------------------- |
| `--dry-run`  | `-n`  | Preview changes without executing  |
| `--verbose`  | `-v`  | Show detailed output               |
| `--quiet`    | `-q`  | Minimal output (for scripts)       |
| `--skip-git` |       | Skip git sync for quick local sync |
| `--status`   |       | Show sync dashboard                |
| `--help`     | `-h`  | Show help message                  |

---

## Examples

### Basic Usage

```bash
# See what needs syncing (smart detection)
flow sync

# Sync everything
flow sync all

# Preview what would happen
flow sync all --dry-run

# Quick local sync (skip git)
flow sync all --skip-git
```

### Individual Targets

```bash
# Update .STATUS files only
flow sync status

# Aggregate wins across projects
flow sync wins

# Recalculate goal progress
flow sync goals

# Sync git (fetch, rebase, push)
flow sync git
```

### Scripting

```bash
# Quiet mode for scripts
flow sync all --quiet

# Check sync status
flow sync --status
```

---

## What Each Target Does

### `flow sync session`

Persists the current work session to the worklog.

- **Reads:** `$FLOW_DATA_DIR/.current-session`
- **Writes:** `$FLOW_DATA_DIR/worklog`
- **Output:** Duration and project name (e.g., "45m on flow-cli")

Use this to capture session data without ending the session.

### `flow sync status`

Updates `.STATUS` files for recently active projects.

- **Scans:** `$FLOW_PROJECTS_ROOT/**/.STATUS`
- **Updates:** `last_active` timestamp
- **Triggers:** Streak updates (if configured)

Only updates files modified in the last hour (avoids touching inactive projects).

### `flow sync wins`

Aggregates project-level wins to a global wins file.

- **Scans:** `.STATUS` files with `wins:` field
- **Writes:** `$FLOW_DATA_DIR/wins.md`
- **Deduplicates:** Won't add the same win twice

Useful for seeing all accomplishments across projects in one place.

### `flow sync goals`

Recalculates daily goal progress based on wins.

- **Reads:** `$FLOW_DATA_DIR/wins.md`
- **Reads:** `$FLOW_DATA_DIR/goal.json` (for target)
- **Writes:** Updated `$FLOW_DATA_DIR/goal.json`
- **Output:** Progress (e.g., "5/3 (100%)")

### `flow sync remote`

iCloud sync for multi-device access (v4.7.0+).

```bash
flow sync remote              # Show sync status
flow sync remote init         # Set up iCloud sync
flow sync remote disable      # Revert to local storage
```

**Setup:**

1. Run `flow sync remote init` to migrate core data to iCloud
2. Add `source ~/.config/flow/remote.conf` to your `~/.zshrc`
3. Restart shell - Apple handles sync automatically

**Synced data:**

- `wins.md` - Daily accomplishments
- `goal.json` - Daily goal progress
- `sync-state.json` - Last sync metadata

**Multi-device:**

- Same iCloud account = automatic sync across devices
- Works offline (syncs when connected)
- No conflicts with local-only data (worklog, inbox)

**iCloud path:** `~/Library/Mobile Documents/com~apple~CloudDocs/flow-cli/`

### `flow sync git`

Smart git synchronization with safety features.

**Workflow:**

1. Stash uncommitted changes (if any)
2. Fetch from remote
3. Rebase if behind remote
4. Push if ahead
5. Pop stash

**Safety:**

- Auto-aborts on rebase conflicts
- Restores stash on any failure
- Reports ahead/behind status

---

## Execution Order

When running `flow sync all`, targets execute in dependency order:

```
session → status → wins → goals → git
   ↓         ↓        ↓       ↓      ↓
 (2ms)    (120ms)  (15ms)  (5ms)  (1.2s)
```

- **Session** must run first (captures current state)
- **Status** updates timestamps before win aggregation
- **Wins** aggregates before goal calculation
- **Goals** calculates progress from wins
- **Git** runs last (longest operation, optional)

---

## Output Format

### Standard Output

```
🔄 Syncing flow-cli
━━━━━━━━━━━━━━━━━━━━
  [1/5] session... done (45m on flow-cli)
  [2/5] status... done (2 projects updated)
  [3/5] wins... done (3 new wins aggregated)
  [4/5] goals... done (5/3 (100%))
  [5/5] git... done (pushed 2 commits)

✓ Sync complete (1.4s)
```

### Quiet Output

With `--quiet`, only errors are shown.

### Dry Run Output

```
🔍 Dry run - no changes will be made

  [1/5] session... Would log: 45m on flow-cli
  [2/5] status... Would update: 2 projects
  ...

Run without --dry-run to execute
```

---

## State File

Sync state is stored in `$FLOW_DATA_DIR/sync-state.json`:

```json
{
  "last_sync": {
    "all": "2025-12-27T14:07:57Z"
  },
  "results": {
    "session": "success",
    "status": "success",
    "wins": "success",
    "goals": "success",
    "git": "skipped"
  }
}
```

View with `flow sync --status`.

---

## Error Handling

| Scenario                    | Behavior                            |
| --------------------------- | ----------------------------------- |
| Network timeout             | Log warning, continue               |
| Missing directory           | Log error, abort                    |
| Git merge conflict          | Abort, restore stash, provide steps |
| Optional dependency missing | Skip silently                       |

### Recovery

If git sync fails with a conflict:

```bash
# View conflict
git status

# Option 1: Abort and sync again later
git rebase --abort

# Option 2: Resolve and continue
git add <resolved-files>
git rebase --continue
git push
```

---

## Integration

### With `finish` Command

The `finish` command can optionally sync before ending a session:

```bash
finish "Completed feature"  # Commits and optionally syncs
```

### With `dash` Command

The dashboard shows sync status:

```bash
dash          # Shows last sync time
dash --watch  # Auto-refreshes with sync status
```

### With CI/CD

```bash
# In a pre-push hook
flow sync all --quiet || exit 1
```

---

## Environment Variables

| Variable             | Default               | Description               |
| -------------------- | --------------------- | ------------------------- |
| `FLOW_DATA_DIR`      | `~/.local/share/flow` | Data storage location     |
| `FLOW_PROJECTS_ROOT` | `~/projects`          | Root for project scanning |

---

## Related Commands

- [`flow goal`](../guides/DOPAMINE-FEATURES-GUIDE.md) - Manage daily goals
- [`win`](../guides/DOPAMINE-FEATURES-GUIDE.md) - Log accomplishments
- [`dash`](dashboard.md) - Project dashboard
- [`finish`](../reference/WORKFLOW-QUICK-REFERENCE.md) - End work session

---

## Scheduled Sync

Enable automatic background sync using macOS launchd:

```bash
flow sync schedule                 # Show status
flow sync schedule enable          # Every 30 minutes
flow sync schedule enable 15       # Every 15 minutes
flow sync schedule disable         # Stop scheduled sync
flow sync schedule logs            # View logs
```

**What runs:** session, status, wins, goals (git is skipped - requires user interaction)

---

## Version History

| Version | Changes                                        |
| ------- | ---------------------------------------------- |
| v4.0.0  | Initial release with 5 sync targets            |
| v4.0.1  | Added `schedule` for automated background sync |
| v4.7.0  | Added `remote` for iCloud multi-device sync    |

---

**See also:** [Dopamine Features Guide](../guides/DOPAMINE-FEATURES-GUIDE.md) for win tracking and goals.
