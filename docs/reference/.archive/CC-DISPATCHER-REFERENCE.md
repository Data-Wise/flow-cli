# CC Dispatcher Reference

> **Claude Code workflows with smart project selection and unified grammar**

**Location:** `lib/dispatchers/cc-dispatcher.zsh`

---

## Quick Start

```bash
cc                # Launch Claude HERE (current dir, acceptEdits)
cc .              # Explicit HERE (NEW v4.8.0!)
cc pick           # Pick project → Claude
cc flow           # Direct jump to flow-cli → Claude
cc yolo           # Launch HERE in YOLO mode (skip all permissions)
cc yolo pick      # Pick project → YOLO mode
cc pick yolo      # Pick → YOLO mode (both orders work!)
cc resume         # Resume previous Claude conversation
```

**✨ NEW in v4.8.0:** Unified grammar supports both mode-first (`cc yolo pick`) AND target-first (`cc pick yolo`) patterns! Use whichever feels natural.

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

## Unified Grammar (v4.8.0+)

**Both command orders work identically!**

```bash
cc [mode] [target]    # Mode-first (unified pattern)
cc [target] [mode]    # Target-first (natural reading)
```

### Modes (HOW to launch)

- `yolo`, `y` - Skip all permissions
- `plan`, `p` - Planning mode
- `opus`, `o` - Opus model
- `haiku`, `h` - Haiku model

### Targets (WHERE to launch)

- *(empty)* - HERE (current directory)
- `.`, `here` - Explicit HERE
- `pick` - Project picker (fzf)
- `<project>` - Direct jump to project
- `wt <branch>` - Worktree

### Examples (Both Orders Work!)

| Mode-First (Unified Pattern) | Target-First (Natural Reading) | Result |
|------------------------------|--------------------------------|--------|
| `cc opus pick` | `cc pick opus` | Pick project → Opus model |
| `cc yolo flow` | `cc flow yolo` | Jump to flow → YOLO mode |
| `cc plan .` | `cc . plan` | HERE → Plan mode |
| `cc haiku wt feat` | - | Worktree → Haiku (mode-first only for 3+ args) |

**Note:** For 3+ arguments (e.g., `cc yolo wt <branch>`), mode-first is required.

---

## Launch Modes

| Command | Also Works As | Description |
|---------|---------------|-------------|
| `cc` | - | Launch Claude HERE (current dir, acceptEdits) |
| `cc .` | `cc here` | Explicit HERE (NEW v4.8.0!) |
| `cc pick` | - | Pick project → Claude |
| `cc <project>` | - | Direct jump → Claude |
| **YOLO Mode** |||
| `cc yolo` | - | Launch HERE in YOLO mode (skip permissions) |
| `cc yolo pick` | `cc pick yolo` ✨ | Pick project → YOLO mode |
| `cc yolo <project>` | `cc <project> yolo` ✨ | Direct jump → YOLO mode |
| **Plan Mode** |||
| `cc plan` | - | Launch HERE in Plan mode |
| `cc plan pick` | `cc pick plan` ✨ | Pick project → Plan mode |
| `cc plan <project>` | `cc <project> plan` ✨ | Direct jump → Plan mode |

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

| Command | Also Works As | Description |
|---------|---------------|-------------|
| **Opus Model** |||
| `cc opus` | - | Launch HERE with Opus model |
| `cc opus pick` | `cc pick opus` ✨ | Pick project → Opus model |
| `cc opus <project>` | `cc <project> opus` ✨ | Direct jump → Opus |
| `cc opus .` | `cc . opus` ✨ | Explicit HERE → Opus |
| **Haiku Model** |||
| `cc haiku` | - | Launch HERE with Haiku model |
| `cc haiku pick` | `cc pick haiku` ✨ | Pick project → Haiku model |
| `cc haiku <project>` | `cc <project> haiku` ✨ | Direct jump → Haiku |
| `cc haiku .` | `cc . haiku` ✨ | Explicit HERE → Haiku |

**Shortcuts:** `cc o` = opus, `cc h` = haiku
**✨ NEW in v4.8.0:** Both mode-first and target-first orders work!

---

## Worktree Integration

Launch Claude in isolated git worktrees for parallel development.

### Unified Grammar (v4.8.0+)

**Pattern:** `cc [mode] [target]` - Mode-first required for 3+ arguments

**Note:** For worktree commands with branches (3+ arguments), mode-first order is required.

| Command | Description |
|---------|-------------|
| `cc wt` | List current worktrees |
| `cc wt <branch>` | Launch Claude in worktree for branch |
| `cc wt pick` | Pick worktree → Claude (fzf) |
| `cc yolo wt <branch>` | YOLO mode in worktree (mode-first) |
| `cc yolo wt pick` | YOLO with picker (mode-first) |
| `cc plan wt <branch>` | Plan mode in worktree (mode-first) |
| `cc plan wt pick` | Plan with picker (mode-first) |
| `cc opus wt <branch>` | Opus model in worktree (mode-first) |
| `cc haiku wt <branch>` | Haiku model in worktree (mode-first) |

**For 2-argument commands,** both orders work:
- `cc wt pick` and `cc pick wt` ✅ (not recommended - use wt first)

**Shortcuts:** `cc w` = wt, `cc worktree` = wt

### Aliases

| Alias  | Expands To    | Description           |
| ------ | ------------- | --------------------- |
| `ccw`  | `cc wt`       | Quick worktree access |
| `ccwy` | `cc wt yolo`  | Worktree + YOLO mode  |
| `ccwp` | `cc wt pick`  | Worktree picker       |
| `ccy`  | `cc yolo`     | YOLO mode (v4.8.0+)   |

### Examples

```bash
# Create/use worktree and launch Claude
cc wt feature/auth       # Creates worktree if needed, launches Claude

# Use fzf to pick existing worktree
cc wt pick               # Interactive selection

# With modes (mode-first required for 3+ args)
cc yolo wt bugfix/issue-42       # YOLO mode in worktree
cc plan wt feature/refactor      # Plan mode in worktree
cc opus wt experiment/new-ui     # Opus model in worktree
cc yolo wt pick                  # Pick worktree → YOLO

# 2-argument: both orders work
cc wt pick               # Recommended
cc pick wt               # Also works (target-first)
```

### How It Works

1. If worktree exists for branch → cd to it → launch Claude
2. If no worktree → create one using `wt create` → launch Claude
3. Mode flags (yolo, plan, opus, haiku) apply to the Claude session
4. **v4.8.0:** Mode-first required for 3+ argument commands (e.g., `cc yolo wt <branch>`)

### Worktree Picker (v5.5.0)

`cc wt pick` shows **all** worktrees from `~/.git-worktrees/` with session indicators:

```
┌─────────────────────────────────────────────────────┐
│ 🌳 Select worktree (Enter=select, Esc=cancel)       │
├─────────────────────────────────────────────────────┤
│ scribe (quarto-v115)             🟡  ~/.git-worktrees/scribe/quarto-v115    │
│ scribe (latex-v2)                🟡  ~/.git-worktrees/scribe/latex-v2       │
│ rmediation (condescending-shamir) 🟢  ~/.git-worktrees/rmediation/...       │
│ medfit (hardcore-cerf)           ⚪  ~/.git-worktrees/medfit/hardcore-cerf  │
└─────────────────────────────────────────────────────┘
```

**Session indicators:**
- 🟢 Recent session (< 24h)
- 🟡 Older session
- ⚪ No Claude session

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

| Alias  | Command       | Description                     |
| ------ | ------------- | ------------------------------- |
| `ccy`  | `cc yolo`     | YOLO mode (v4.8.0+)             |
| `ccw`  | `cc wt`       | Worktree mode                   |
| `ccwy` | `cc wt yolo`  | Worktree + YOLO                 |
| `ccwp` | `cc wt pick`  | Worktree picker                 |

**Note:** Only these 4 aliases are defined. Previous aliases (`ccp`, `ccr`, `ccc`, etc.) were removed for simplicity.

---

## See Also

- **Command:** [work](../commands/work.md) - Start work sessions
- **Command:** [pick](../commands/pick.md) - Project picker details
- **Reference:** [Dispatcher Reference](DISPATCHER-REFERENCE.md) - All dispatchers
- **Tutorial:** [CC Dispatcher Tutorial](../tutorials/10-cc-dispatcher.md) - Learn by doing

---

**Last Updated:** 2026-01-07
**Version:** v5.5.0
**Status:** ✅ Production ready with unified grammar
