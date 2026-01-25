# hop

> **Quick project switch with tmux session management and interactive picker**

The `hop` command provides fast project switching, especially powerful when using tmux. It creates or switches to project-specific tmux sessions.

---

## Synopsis

```bash
hop [project]
```

**Quick examples:**

```bash
# Switch to a project
hop flow-cli

# Interactive picker
hop

# With tmux (creates/switches session)
hop my-project
# ✓ Hopped to: my-project
```

---

## Usage

```bash
hop [project]
```

## Arguments

| Argument  | Description               | Default                  |
| --------- | ------------------------- | ------------------------ |
| `project` | Project name to switch to | Interactive picker (fzf) |

---

## What It Does

1. **Without tmux** - Simple `cd` to project directory
2. **With tmux** - Creates or switches to a named tmux session for the project

### Tmux Behavior

When running inside tmux:

- **Session exists** - Switches to the existing session
- **Session doesn't exist** - Creates new session in project directory
- **Session naming** - Uses sanitized project name (replaces special chars with `_`)

---

## Examples

### Basic Switch

```bash
# Switch to a project
hop flow-cli

# Interactive picker (if no project specified)
hop
```

### With Tmux

```bash
# Creates/switches to 'flow_cli' tmux session
hop flow-cli

# View all tmux sessions
tmux list-sessions
```

### Without Tmux

```bash
# Simply changes to project directory
hop my-project
# Changed to: my-project (start tmux for session management)
```

---

## Output

With tmux:

```
✓ Hopped to: flow-cli
```

Without tmux:

```
ℹ Changed to: my-project (start tmux for session management)
```

---

## hop vs work

| Feature          | `hop`                   | `work`                  |
| ---------------- | ----------------------- | ----------------------- |
| Session tracking | No                      | Yes (atlas)             |
| Editor launch    | No                      | Yes                     |
| Context display  | No                      | Yes (.STATUS shown)     |
| Tmux integration | Full (creates sessions) | No                      |
| Speed            | Instant                 | Slightly slower (setup) |
| Use case         | Quick context switches  | Starting focused work   |

**Rule of thumb:**

- Use `work` when starting a focused work block
- Use `hop` when quickly checking something in another project

---

## Tmux Tips

!!! tip "View All Sessions"

```bash # List all tmux sessions
tmux ls

    # Kill a specific session
    tmux kill-session -t session_name
    ```

!!! tip "Detach and Return"
`bash
    # Detach from current session: Ctrl-b d
    # Then hop to another project
    hop other-project
    `

---

## Related Commands

| Command           | Description                         |
| ----------------- | ----------------------------------- |
| [`work`](work.md) | Start focused session (with editor) |
| [`pick`](pick.md) | Interactive project picker          |
| [`dash`](dash.md) | View all projects dashboard         |

---

## See Also

- **Command:** [work](work.md) - Start a full work session with editor
- **Command:** [pick](pick.md) - Interactive project picker with categories
- **Command:** [finish](finish.md) - End session cleanly
- **Reference:** [Workflow Quick Reference](../help/WORKFLOWS.md) - Common workflows

---

**Last Updated:** 2026-01-07
**Command Version:** v4.8.0
**Status:** ✅ Production ready with tmux integration
