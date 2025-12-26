# CC Dispatcher Reference

Claude Code workflows with smart project selection

**Location:** `lib/dispatchers/cc-dispatcher.zsh`

---

## Quick Start

```bash
cc                # Pick project → NEW Claude session (acceptEdits)
cc flow           # Direct jump to flow-cli → Claude
cc yolo           # Pick project → YOLO mode (skip all permissions)
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

| Command             | Description                                  |
| ------------------- | -------------------------------------------- |
| `cc`                | Pick project → NEW Claude (acceptEdits mode) |
| `cc <project>`      | Direct jump → NEW Claude                     |
| `cc yolo`           | Pick project → YOLO mode (skip permissions)  |
| `cc yolo <project>` | Direct jump → YOLO mode                      |
| `cc plan`           | Pick project → Plan mode                     |
| `cc now`            | Current directory → Claude (no picker)       |

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

| Command              | Description                            |
| -------------------- | -------------------------------------- |
| `cc opus`            | Pick project → Claude with Opus model  |
| `cc opus <project>`  | Direct jump → Opus                     |
| `cc haiku`           | Pick project → Claude with Haiku model |
| `cc haiku <project>` | Direct jump → Haiku                    |

**Shortcuts:** `cc o` = opus, `cc h` = haiku

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

| Full       | Short | Description             |
| ---------- | ----- | ----------------------- |
| `yolo`     | `y`   | YOLO mode               |
| `plan`     | `p`   | Plan mode               |
| `now`      | `n`   | Current dir (no picker) |
| `resume`   | `r`   | Resume session picker   |
| `continue` | `c`   | Continue most recent    |
| `ask`      | `a`   | Quick question          |
| `file`     | `f`   | Analyze file            |
| `diff`     | `d`   | Review git diff         |
| `opus`     | `o`   | Opus model              |
| `haiku`    | `h`   | Haiku model             |
| `print`    | `pr`  | Print mode              |

---

## Integration

- Uses `pick` for project selection (inherits direct jump, smart resume)
- Uses Claude CLI (`claude`) for all operations
- Works with `ccy` alias (shortcut for `cc yolo`)

---

## Related

- [PICK-COMMAND-REFERENCE.md](PICK-COMMAND-REFERENCE.md) - Project picker details
- [DISPATCHER-REFERENCE.md](DISPATCHER-REFERENCE.md) - All dispatchers

---

**Last Updated:** 2025-12-26
**Status:** ✅ Fully implemented
