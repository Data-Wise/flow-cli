# CC Dispatcher Reference

Claude Code workflows with smart project selection

**Location:** `lib/dispatchers/cc-dispatcher.zsh`

---

## Quick Start

```bash
cc                # Launch Claude HERE (current dir, acceptEdits)
cc pick           # Pick project → Claude
cc flow           # Direct jump to flow-cli → Claude
cc yolo           # Launch HERE in YOLO mode (skip all permissions)
cc yolo pick      # Pick project → YOLO mode
cc resume         # Resume previous Claude conversation
```

---

## Usage

```bash
cc [subcommand|project-name] [options]
```

### Key Insight

- `cc` always starts a **NEW** Claude session
- Use `cc resume` to continue a previous Claude conversation
- Project selection inherits `pick`'s smart behaviors (direct jump, resume)

---

## Launch Modes

| Command                  | Description                                   |
| ------------------------ | --------------------------------------------- |
| `cc`                     | Launch Claude HERE (current dir, acceptEdits) |
| `cc pick`                | Pick project → Claude                         |
| `cc <project>`           | Direct jump → Claude                          |
| `cc pick <project>`      | Direct jump via pick → Claude                 |
| `cc yolo`                | Launch HERE in YOLO mode (skip permissions)   |
| `cc yolo pick`           | Pick project → YOLO mode                      |
| `cc yolo <project>`      | Direct jump → YOLO mode                       |
| `cc yolo pick <project>` | Direct jump via pick → YOLO                   |
| `cc plan`                | Launch HERE in Plan mode                      |
| `cc plan pick`           | Pick project → Plan mode                      |
| `cc plan <project>`      | Direct jump → Plan mode                       |
| `cc plan pick <project>` | Direct jump via pick → Plan                   |

### Permission Modes

| Mode            | Flag                             | Use Case                |
| --------------- | -------------------------------- | ----------------------- |
| **acceptEdits** | `--permission-mode acceptEdits`  | Default, confirms edits |
| **YOLO**        | `--dangerously-skip-permissions` | No confirmations        |
| **plan**        | `--permission-mode plan`         | Planning mode           |

---

## Session Management

| Command       | Description                                 |
| ------------- | ------------------------------------------- |
| `cc resume`   | Show Claude session picker, resume selected |
| `cc continue` | Resume most recent Claude conversation      |

**Shortcuts:** `cc r` = resume, `cc c` = continue

---

## Quick Actions

| Command             | Description                                  |
| ------------------- | -------------------------------------------- |
| `cc ask <question>` | Quick question (print mode, non-interactive) |
| `cc file <file>`    | Analyze a file with Claude                   |
| `cc diff`           | Review uncommitted git changes               |
| `cc rpkg`           | R package context helper (reads DESCRIPTION) |
| `cc print <prompt>` | Print mode (non-interactive output)          |

**Shortcuts:** `cc a` = ask, `cc f` = file, `cc d` = diff, `cc pr` = print

---

## Model Selection

| Command                   | Description                  |
| ------------------------- | ---------------------------- |
| `cc opus`                 | Launch HERE with Opus model  |
| `cc opus pick`            | Pick project → Opus model    |
| `cc opus <project>`       | Direct jump → Opus           |
| `cc opus pick <project>`  | Direct jump via pick → Opus  |
| `cc haiku`                | Launch HERE with Haiku model |
| `cc haiku pick`           | Pick project → Haiku model   |
| `cc haiku <project>`      | Direct jump → Haiku          |
| `cc haiku pick <project>` | Direct jump via pick → Haiku |

**Shortcuts:** `cc o` = opus, `cc h` = haiku

---

## Worktree Integration

Launch Claude in isolated git worktrees for parallel development.

| Command                     | Description                             |
| --------------------------- | --------------------------------------- |
| `cc wt`                     | List current worktrees                  |
| `cc wt <branch>`            | Launch Claude in worktree for branch    |
| `cc wt pick`                | Pick worktree → Claude (fzf)            |
| `cc wt yolo <branch>`       | Worktree → YOLO mode                    |
| `cc wt plan <branch>`       | Worktree → Plan mode                    |
| `cc wt opus <branch>`       | Worktree → Opus model                   |
| `cc wt haiku <branch>`      | Worktree → Haiku model                  |

**Shortcuts:** `cc w` = wt, `cc worktree` = wt

### Aliases

| Alias  | Expands To    | Description           |
| ------ | ------------- | --------------------- |
| `ccw`  | `cc wt`       | Quick worktree access |
| `ccwy` | `cc wt yolo`  | Worktree + YOLO mode  |
| `ccwp` | `cc wt pick`  | Worktree picker       |

### Examples

```bash
# Create/use worktree and launch Claude
cc wt feature/auth       # Creates worktree if needed, launches Claude

# Use fzf to pick existing worktree
cc wt pick               # Interactive selection

# Worktree with YOLO mode
cc wt yolo bugfix/issue-42

# Worktree with specific model
cc wt opus feature/refactor
```

### How It Works

1. If worktree exists for branch → cd to it → launch Claude
2. If no worktree → create one using `wt create` → launch Claude
3. Mode flags (yolo, plan, opus, haiku) apply to the Claude session

---

## Smart Project Selection

The `cc` dispatcher inherits all of `pick`'s smart behaviors:

### Direct Jump

```bash
cc flow           # → cd to flow-cli → NEW Claude session
cc med            # → cd to mediationverse → NEW Claude session
```

### Smart Resume (via pick)

When you run `cc` with no args:

1. `pick` shows the resume prompt (if recent session exists)
2. Press Enter to resume last project, Space to browse
3. After selection, Claude launches in NEW session

### Explicit Claude Resume

```bash
cc resume         # Resume previous Claude conversation (with picker)
cc continue       # Resume most recent Claude conversation
```

---

## Examples

### Daily Workflow

```bash
# Start fresh session in a project
cc flow           # Direct jump → Claude

# Continue where you left off (Claude conversation)
cc resume         # Pick previous conversation

# Quick question without full session
cc ask "how do I handle NA values in R?"

# Review changes before committing
cc diff
```

### Different Modes

```bash
# Careful mode (default)
cc                # acceptEdits - confirms changes

# YOLO mode for trusted tasks
cc yolo           # Skip all confirmations

# Planning mode
cc plan           # No code execution
```

### Model Selection

```bash
# Use Opus for complex tasks
cc opus flow      # flow-cli + Opus model

# Use Haiku for quick tasks
cc haiku          # Pick project + Haiku model
```

---

## Shortcuts Summary

| Full       | Short | Description           |
| ---------- | ----- | --------------------- |
| `yolo`     | `y`   | YOLO mode             |
| `plan`     | `p`   | Plan mode             |
| `resume`   | `r`   | Resume session picker |
| `continue` | `c`   | Continue most recent  |
| `ask`      | `a`   | Quick question        |
| `file`     | `f`   | Analyze file          |
| `diff`     | `d`   | Review git diff       |
| `opus`     | `o`   | Opus model            |
| `haiku`    | `h`   | Haiku model           |
| `print`    | `pr`  | Print mode            |
| `wt`       | `w`   | Worktree mode         |

> **Note:** `cc now` is deprecated. Just use `cc` (default is current dir).

---

## Integration

- Uses `pick` for project selection (inherits direct jump, smart resume)
- Uses Claude CLI (`claude`) for all operations
- Works with `wt` dispatcher for worktree management

### Aliases

| Alias  | Command       | Description          |
| ------ | ------------- | -------------------- |
| `ccy`  | `cc yolo`     | YOLO mode            |
| `ccp`  | `cc plan`     | Plan mode            |
| `ccr`  | `cc resume`   | Resume picker        |
| `ccc`  | `cc continue` | Continue recent      |
| `cca`  | `cc ask`      | Quick question       |
| `ccf`  | `cc file`     | Analyze file         |
| `ccd`  | `cc diff`     | Review changes       |
| `cco`  | `cc opus`     | Opus model           |
| `cch`  | `cc haiku`    | Haiku model          |
| `ccw`  | `cc wt`       | Worktree mode        |
| `ccwy` | `cc wt yolo`  | Worktree + YOLO      |
| `ccwp` | `cc wt pick`  | Worktree picker      |

---

## Related

- [PICK-COMMAND-REFERENCE.md](PICK-COMMAND-REFERENCE.md) - Project picker details
- [DISPATCHER-REFERENCE.md](DISPATCHER-REFERENCE.md) - All dispatchers

---

**Last Updated:** 2025-12-29
**Version:** v4.2.0
**Status:** ✅ Fully implemented
