# Tutorial: Mastering the CC Dispatcher

> **What you'll learn:** Launch Claude Code efficiently with smart project selection and mode chaining
>
> **Time:** ~15 minutes | **Level:** Beginner to Intermediate
> **Version:** v5.8.0+

---

## Prerequisites

Before starting, you should:

- [ ] Have Claude Code CLI installed (`claude --version`)
- [ ] Completed: [Tutorial 1: Your First Flow Session](01-first-session.md)
- [ ] Have fzf installed (optional, for pickers)

**Verify your setup:**

```bash
# Check cc dispatcher is available
cc help

# Check Claude CLI
claude --version
```

---

## What You'll Learn

By the end of this tutorial, you will:

1. Launch Claude in different modes (acceptEdits, YOLO, plan)
2. Use direct jump for instant project access
3. Select models (Opus, Haiku) for different tasks
4. Resume and continue Claude sessions
5. Use quick actions (ask, diff, file)

---

## Part 1: Basic Launch Modes

### Step 1.1: Default Mode (acceptEdits)

The simplest way to start Claude:

```bash
# Launch Claude in current directory
cc

# Explicit HERE (same as above, more explicit)
cc .
```

**What happens:**
- Claude starts with `--permission-mode acceptEdits`
- You'll confirm file edits before they're applied
- Safe for everyday work

**Tip:** Use `cc .` when you want to be explicit about launching in the current directory.

### Step 1.2: YOLO Mode (Skip Permissions)

For trusted tasks where you want maximum speed:

```bash
# Launch with no confirmations
cc yolo
```

**What happens:**
- Claude starts with `--dangerously-skip-permissions`
- All edits apply immediately
- Use for familiar codebases and trusted operations

**Warning:** Only use YOLO mode when you trust the task!

### Step 1.3: Plan Mode

For exploration without code changes:

```bash
# Launch in planning mode
cc plan
```

**What happens:**
- Claude starts with `--permission-mode plan`
- Focus on analysis and planning
- No code execution

---

## Part 2: Project Selection

### Step 2.1: Pick a Project (Interactive)

```bash
# Open project picker, then launch Claude
cc pick
```

**What happens:**
1. fzf picker shows your projects
2. Select one → cd to project
3. Claude launches in that directory

### Step 2.2: Direct Jump (Instant)

Skip the picker entirely:

```bash
# Jump to flow-cli → launch Claude
cc flow

# Jump to mediationverse → launch Claude
cc med

# Jump to stat-440 → launch Claude
cc stat
```

**What happens:**
- Uses `pick`'s fuzzy matching
- Finds the project, cd's there
- Claude launches immediately

### Step 2.3: Mode + Project Combinations

Chain modes with project selection:

```bash
# YOLO mode + direct jump
cc yolo flow

# Plan mode + project picker
cc plan pick

# YOLO mode + project picker
cc yolo pick

# Plan mode + direct jump
cc plan med
```

**Pattern:** `cc [mode] [project|pick]`

### Step 2.4: Unified Grammar (Both Orders Work!)

As of v5.3.0, the CC dispatcher supports **unified grammar** - both mode-first AND target-first orders work identically:

```bash
# These are equivalent:
cc yolo pick     # mode-first
cc pick yolo     # target-first ✨

# These are equivalent:
cc plan pick     # mode-first
cc pick plan     # target-first ✨

# These are equivalent:
cc opus pick     # mode-first
cc pick opus     # target-first ✨
```

**Why this matters:**
- Type in whatever order feels natural
- No more remembering "does mode come first?"
- ADHD-friendly - reduce cognitive load

---

## Part 3: Model Selection

### Step 3.1: Use Opus for Complex Tasks

```bash
# Opus in current directory
cc opus

# Opus + direct jump
cc opus flow

# Opus + project picker
cc opus pick
```

**When to use Opus:**
- Complex architectural decisions
- Large refactoring tasks
- Deep code analysis

### Step 3.2: Use Haiku for Quick Tasks

```bash
# Haiku in current directory
cc haiku

# Haiku + direct jump
cc haiku flow

# Haiku + project picker
cc haiku pick
```

**When to use Haiku:**
- Quick questions
- Simple edits
- Fast feedback loops

---

## Part 4: Session Management

### Step 4.1: Resume a Previous Session

```bash
# Show Claude session picker
cc resume
```

**What happens:**
- Lists your recent Claude conversations
- Select one to resume where you left off
- Maintains full conversation context

### Step 4.2: Continue Most Recent

```bash
# Resume the most recent conversation
cc continue
```

**What happens:**
- Jumps directly to your last Claude session
- No picker needed
- Fastest way to get back to work

---

## Part 5: Quick Actions

### Step 5.1: Ask a Quick Question

```bash
# Get an answer without full session
cc ask "how do I handle missing data in R?"
```

**What happens:**
- Claude answers in print mode
- Non-interactive, one-shot response
- Perfect for quick lookups

### Step 5.2: Review Git Changes

```bash
# Review uncommitted changes
cc diff
```

**What happens:**
- Pipes `git diff` to Claude
- Gets code review feedback
- Great before committing

### Step 5.3: Analyze a File

```bash
# Analyze specific file
cc file R/myfunction.R

# With custom prompt
cc file R/myfunction.R "explain the algorithm"
```

**What happens:**
- Claude analyzes the file
- Provides explanation or feedback
- Useful for understanding unfamiliar code

### Step 5.4: R Package Helper

```bash
# In an R package directory
cc rpkg "add input validation"
```

**What happens:**
- Reads DESCRIPTION file
- Provides package context to Claude
- Claude knows the package name and structure

---

## Part 6: Worktree Integration

### Step 6.1: Launch Claude in a Worktree

```bash
# Create/use worktree → launch Claude
cc wt feature/auth
```

**What happens:**
1. Creates worktree if it doesn't exist
2. cd's to the worktree
3. Launches Claude there

### Step 6.2: Mode Chaining with Worktrees

```bash
# Worktree + YOLO
cc wt yolo feature/risky

# Worktree + Plan
cc wt plan feature/complex

# Worktree + Opus
cc wt opus feature/refactor
```

### Step 6.3: Pick from Existing Worktrees

```bash
# fzf picker for worktrees
cc wt pick
```

---

## Shortcuts Reference

### Single-Letter Shortcuts

| Full       | Short | Example          |
|------------|-------|------------------|
| `yolo`     | `y`   | `cc y`           |
| `plan`     | `p`   | `cc p`           |
| `resume`   | `r`   | `cc r`           |
| `continue` | `c`   | `cc c`           |
| `ask`      | `a`   | `cc a "question"`|
| `file`     | `f`   | `cc f myfile.R`  |
| `diff`     | `d`   | `cc d`           |
| `opus`     | `o`   | `cc o`           |
| `haiku`    | `h`   | `cc h`           |
| `wt`       | `w`   | `cc w feature/x` |

### Aliases

| Alias  | Expands To    | Use Case              |
|--------|---------------|-----------------------|
| `ccy`  | `cc yolo`     | Fast trusted work     |
| `ccp`  | `cc plan`     | Planning sessions     |
| `ccr`  | `cc resume`   | Resume conversations  |
| `ccc`  | `cc continue` | Continue recent       |
| `cco`  | `cc opus`     | Complex tasks         |
| `cch`  | `cc haiku`    | Quick tasks           |
| `ccw`  | `cc wt`       | Worktree mode         |
| `ccwy` | `cc wt yolo`  | Worktree + YOLO       |
| `ccwp` | `cc wt pick`  | Worktree picker       |

---

## Common Workflows

### Morning Start

```bash
# Option 1: Continue where you left off
cc continue

# Option 2: Start fresh on a project
cc flow
```

### Feature Development

```bash
# Start in plan mode to think through approach
cc plan pick

# Switch to YOLO for implementation
cc yolo
```

### Code Review

```bash
# Review your changes
cc diff

# Or analyze specific file
cc file src/complex-function.js "review for bugs"
```

### Quick Questions

```bash
# Get quick answers without full session
cc ask "what's the best way to mock API calls in jest?"
```

### Parallel Work with Worktrees

```bash
# Work on feature in isolated worktree
cc wt feature/auth

# Another terminal: quick fix in different worktree
ccwy hotfix/urgent
```

---

## Decision Guide

### Which Mode?

```
What's your task?
├─ Trusted, familiar codebase
│  └─ cc yolo (or ccy)
├─ Exploring, planning
│  └─ cc plan (or ccp)
└─ Normal development
   └─ cc (default acceptEdits)
```

### Which Model?

```
Task complexity?
├─ Complex architecture, large refactor
│  └─ cc opus (or cco)
├─ Quick fix, simple question
│  └─ cc haiku (or cch)
└─ Normal tasks
   └─ cc (default Sonnet)
```

### Resume vs New Session?

```
Do you need previous context?
├─ Yes, continue discussion
│  └─ cc resume or cc continue
└─ No, fresh start
   └─ cc [mode] [project]
```

---

## Troubleshooting

### "pick function not available"

```bash
# Verify flow-cli is loaded
source ~/.zshrc

# Or check pick command
pick help
```

### "claude: command not found"

```bash
# Install Claude CLI
# See: https://claude.ai/code
```

### "Not in a git repository" (for cc diff)

```bash
# Navigate to a git repo first
cd /path/to/your/repo
cc diff
```

---

## What's Next?

- **[Worktrees Tutorial](09-worktrees.md)** - Deep dive into parallel development
- **[CC Dispatcher Reference](../reference/.archive/CC-DISPATCHER-REFERENCE.md)** - Complete command reference
- **[Dispatcher Reference](../reference/MASTER-DISPATCHER-GUIDE.md)** - All flow-cli dispatchers

---

**Tip:** Start with `cc` for everyday work, `cc yolo` when you're confident, and `cc opus` for complex challenges!
