# Claude Code Rapid Development Workflow

**Level:** Intermediate
**Time:** 10 minutes
**Goal:** Minimize permission prompts for faster development with Claude Code

---

## What This Guide Covers

This guide explains how to reduce interruptions when working with Claude Code, including:

- ✅ **Auto-Accept Edits** in VS Code (Shift+Tab method)
- ✅ **CLI YOLO Mode** with `--dangerously-skip-permissions`
- ✅ **Safety practices** with git
- ✅ **flow-cli integration** for rapid workflows

**Important:** There is **no "YOLO mode" setting** in the VS Code extension. The methods here are the actual working approaches.

---

## The Reality: Two Different Permission Models

### VS Code Extension: Limited Auto-Accept

The VS Code Claude Code extension has its **own permission system**:

- ✅ Can auto-accept **file edits** (Shift+Tab toggle)
- ❌ Still prompts for **read permissions**
- ❌ Still prompts for **execute permissions**
- ❌ Still prompts for **tool usage**

### CLI: True YOLO Mode

The Claude Code CLI has **full permission bypass**:

- ✅ Bypasses **all permissions** (read, write, execute)
- ✅ Uses `--dangerously-skip-permissions` flag
- ⚠️ **Only available via command line**, not VS Code extension

---

## Method 1: Auto-Accept Edits in VS Code

### How to Enable

The VS Code extension has a built-in mode toggle:

**Step 1:** Open Claude Code chat in VS Code

**Step 2:** Press `Shift+Tab` to cycle through modes:
- Normal mode
- **Auto-accept edits** ← Stop here
- Plan mode

**Step 3:** Verify mode indicator shows "Auto-accept edits: ON"

### What It Does

| Permission Type | Auto-Accepted? |
|----------------|----------------|
| File edits | ✅ Yes |
| File reads | ❌ No - still prompts |
| File writes (new) | ❌ No - still prompts |
| Execute commands | ❌ No - still prompts |
| Tool usage | ❌ No - still prompts |

### When to Use

**Good for:**
- ✅ Refactoring existing files
- ✅ Code cleanup across multiple files
- ✅ Iterative development where you review frequently

**Not good for:**
- ❌ Reading many files (still prompts)
- ❌ Running tests/commands (still prompts)
- ❌ Truly unattended workflows (use CLI instead)

### Example Workflow

```
1. Open VS Code with your project
2. Start Claude Code chat
3. Press Shift+Tab until "Auto-accept edits: ON"
4. Ask: "Refactor commands/work.zsh to use modern ZSH patterns"
5. Claude edits files automatically (no confirmation per edit)
6. Review changes with: git diff
7. Commit or revert as needed
```

---

## Method 2: CLI YOLO Mode (True Bypass)

### How to Enable

The **real** YOLO mode only exists in the command-line interface:

```bash
# This bypasses ALL permissions
claude --dangerously-skip-permissions
```

### What It Does

| Permission Type | Bypassed? |
|----------------|-----------|
| File edits | ✅ Yes |
| File reads | ✅ Yes |
| File writes | ✅ Yes |
| Execute commands | ✅ Yes |
| Tool usage | ✅ Yes |

**This is the closest to "YOLO mode"** - Claude can do anything without asking.

### Safety Requirements

⚠️ **CRITICAL:** Only use in isolated environments

**Required safeguards:**
1. Git repository (for rollback)
2. Clean working tree (can discard changes)
3. Separate branch (not main/production)
4. OR: Dev container/VM (isolated environment)

### Example Workflow

```bash
# 1. Ensure clean git state
git status
git checkout -b experiment-refactor

# 2. Launch Claude Code CLI with YOLO mode
claude --dangerously-skip-permissions

# 3. Give instructions
> Refactor the entire commands/ directory to use modern ZSH patterns

# 4. Monitor with watch command (separate terminal)
watch -n 2 'git diff --stat'

# 5. Review when done
git diff --stat
git diff commands/

# 6. Commit or discard
git add -A && git commit -m "refactor: modernize commands"
# OR
git reset --hard HEAD  # Discard everything
```

---

## Method 3: Dev Container Setup (Advanced)

For **truly unattended** Claude Code in VS Code:

### Setup Steps

1. **Create .devcontainer** configuration
2. **Disable firewall** (remove postCreateCommand)
3. **Enable passwordless sudo** (optional)
4. **Reopen in container**
5. **Run CLI** with `--dangerously-skip-permissions`

**Why containers?** Isolates Claude's actions from your main system.

**Reference:** [Dev Container YOLO Setup](https://x.com/bantg/status/1932765435109290079)

---

## flow-cli Integration

### Current: Auto-Accept Edits

The `cc` dispatcher can launch Claude in VS Code:

```bash
# Launch Claude HERE (current directory)
cc

# Launch Claude with project picker
cc pick

# Aliases
ccy         # Short for: cc yolo (currently same as cc)
```

**Note:** These currently launch the VS Code extension. You'll still need to press `Shift+Tab` manually to enable auto-accept edits.

### Proposed: CLI Integration

We could update flow-cli to support CLI-based YOLO mode:

```bash
# Proposed new behavior
cc yolo           # Launches: claude --dangerously-skip-permissions
cc yolo pick      # Pick project, then CLI YOLO
```

**Status:** Not yet implemented. Would you like this feature?

---

## Safety Practices

### 1. Git is Your Safety Net

**Always work in a git repository:**

```bash
# Before YOLO session
git status                    # Ensure clean
git checkout -b yolo-test     # Separate branch

# During YOLO session
watch -n 2 'git diff --stat'  # Monitor changes

# After YOLO session
git diff                      # Review all changes
git add -p                    # Stage selectively
git commit                    # Save good changes

# If things go wrong
git reset --hard HEAD         # Nuclear option
```

### 2. Use Worktrees for Isolation

Keep main codebase safe:

```bash
# Create isolated worktree
wt create yolo-experiment

# Claude works here
cd ~/projects/.git-worktrees/flow-cli-yolo-experiment
claude --dangerously-skip-permissions

# Experiment fails? Just delete
cd ~/projects/flow-cli
wt remove yolo-experiment
```

### 3. Start Small

First YOLO session? Start with low-risk tasks:

✅ **Good first tasks:**
- Update documentation
- Add unit tests
- Refactor a single module
- Format code

❌ **Avoid initially:**
- Rewrite authentication
- Change database schema
- Modify deployment configs

### 4. Review Frequently

Don't let Claude make 100 changes unchecked:

```bash
# Review every 5-10 operations
git diff --stat               # See what changed
git diff lib/core.zsh         # Review specific file
```

### 5. Backup Critical State

Before risky changes:

```bash
# Create backup branch
git checkout -b backup-$(date +%Y%m%d)
git checkout main

# Or stash current state
git stash save "pre-yolo-$(date +%Y%m%d-%H%M)"
```

---

## What Doesn't Work (Myths Debunked)

### ❌ Myth: VS Code Settings for YOLO Mode

These settings **do not exist** in the official extension:

```json
{
  "claude-code.yoloMode": true,          // ❌ Fake
  "claude-code.acceptEdits": true,       // ❌ Fake
  "claude-code.autoSave": true,          // ❌ Fake
  "claude-code.showTokenCount": true     // ❌ Fake
}
```

**Why the confusion?** These were incorrectly documented earlier. The VS Code extension doesn't have these settings.

### ❌ Myth: Workspace Files Enable YOLO

Creating a `.code-workspace` file with fake settings **does nothing**:

```json
{
  "folders": [{"path": "."}],
  "settings": {
    "claude-code.yoloMode": true  // ❌ Has no effect
  }
}
```

**Reality:** The VS Code extension ignores these settings.

### ❌ Myth: --dangerously-skip-permissions Works in VS Code

The CLI flag **does not work** when using the VS Code extension:

```bash
# This only works in CLI, not VS Code extension
claude --dangerously-skip-permissions
```

**Why?** The VS Code extension has its own separate permission system.

---

## Comparison: VS Code vs CLI

| Feature | VS Code Extension | CLI |
|---------|-------------------|-----|
| **Auto-accept edits** | ✅ Shift+Tab | ✅ --dangerously-skip-permissions |
| **Auto-accept reads** | ❌ No | ✅ Yes |
| **Auto-accept writes** | ❌ No | ✅ Yes |
| **Auto-accept execute** | ❌ No | ✅ Yes |
| **GUI integration** | ✅ Native VS Code | ❌ Terminal only |
| **Safety model** | Built-in prompts | User responsibility |
| **Best for** | Interactive development | Automated workflows |

---

## Complete Example Session

### Scenario: Refactor Project Structure

**Setup:**
```bash
cd ~/projects/flow-cli
git status                    # Clean working tree
git checkout -b refactor-cmds
```

**Option A: VS Code (Auto-Accept Edits)**
```bash
# 1. Open in VS Code
code .

# 2. Start Claude Code chat

# 3. Enable auto-accept
Press Shift+Tab → "Auto-accept edits: ON"

# 4. Give instructions
Ask: "Refactor commands/*.zsh to use consistent error handling"

# 5. Review as it works
Open Source Control panel
Watch files change in real-time

# 6. Commit
git add -A
git commit -m "refactor: consistent error handling"
```

**Option B: CLI (True YOLO)**
```bash
# 1. Terminal 1: Launch Claude
claude --dangerously-skip-permissions

Ask: "Refactor commands/*.zsh to use consistent error handling"

# 2. Terminal 2: Monitor
watch -n 2 'git diff --stat'

# 3. Review when done
git diff

# 4. Commit or discard
git add -A && git commit -m "refactor: error handling"
# OR
git reset --hard HEAD
```

---

## Troubleshooting

### Auto-Accept Not Working in VS Code?

**Check 1:** Are you using Claude Code extension?
```
Extensions → Search "Claude Code" → Should be installed
```

**Check 2:** Is mode actually toggled?
```
Look for indicator: "Auto-accept edits: ON" in chat
Try pressing Shift+Tab again
```

**Check 3:** Are you asking for edits?
```
Auto-accept only works for file edits
Reads/writes/executes still prompt
```

### CLI Mode Not Bypassing Permissions?

**Check 1:** Using correct flag?
```bash
# Correct
claude --dangerously-skip-permissions

# Wrong
claude --yolo               # ❌ Not a real flag
claude --skip-permissions   # ❌ Missing "dangerously"
```

**Check 2:** Using CLI, not extension?
```bash
# Run from terminal
claude --dangerously-skip-permissions

# Not from VS Code
"Claude Code" extension panel ❌
```

### Still Getting Prompts?

**VS Code Extension:** This is normal
- Only edits are auto-accepted
- Reads, writes, executes still prompt
- This is by design for safety

**CLI:** Check environment
- Are you in a container?
- Are permissions locked down?
- Try in a fresh directory

---

## Best Practices Summary

### ✅ DO

- ✅ Use git repositories (required safety net)
- ✅ Work on separate branches
- ✅ Review changes frequently (`git diff`)
- ✅ Start with small, low-risk tasks
- ✅ Use worktrees for experiments
- ✅ Keep backups before risky changes
- ✅ Test changes before committing

### ❌ DON'T

- ❌ Use on production branches
- ❌ Walk away during YOLO sessions
- ❌ Skip reviewing changes
- ❌ Work without git
- ❌ Trust fake VS Code settings
- ❌ Expect full YOLO in VS Code extension
- ❌ Use YOLO mode with untrusted code

---

## Summary

**What Actually Works:**

1. **VS Code: Shift+Tab** → Auto-accept edits only
2. **CLI: --dangerously-skip-permissions** → True YOLO mode
3. **Dev Container + CLI** → Isolated YOLO environment

**What Doesn't Work:**

1. ❌ `claude-code.yoloMode` setting (doesn't exist)
2. ❌ Workspace file settings (no effect)
3. ❌ `--dangerously-skip-permissions` in VS Code extension

**Recommended Approach:**

- **Interactive work:** Use VS Code with `Shift+Tab`
- **Automated work:** Use CLI with `--dangerously-skip-permissions`
- **Experiments:** Use worktrees + CLI for safety

---

## Next Steps

1. **Try Shift+Tab** in VS Code (safe, limited)
2. **Experiment with CLI** in a test branch (more powerful)
3. **Set up worktrees** for isolated experiments
4. **Build habits** around git safety practices

---

## Related Documentation

- [CC Dispatcher Reference](../reference/CC-DISPATCHER-REFERENCE.md) - Claude Code launcher
- [Git Feature Workflow](../tutorials/08-git-feature-workflow.md) - Branch management
- [Worktree Guide](../tutorials/09-worktrees.md) - Isolated development

---

## Sources

This guide is based on official documentation and community research:

- [Claude Code VS Code Docs](https://code.claude.com/docs/en/vs-code)
- [YOLO Mode Guide](https://apidog.com/blog/claude-code-gemini-yolo-mode/)
- [Permission Model](https://skywork.ai/blog/permission-model-claude-code-vs-code-jetbrains-cli/)
- [VS Code Extension Issue #8539](https://github.com/anthropics/claude-code/issues/8539)
- [Auto Approval Guide](https://smartscope.blog/en/generative-ai/claude/claude-code-auto-permission-guide/)

---

**Last Updated:** 2026-01-01 (Corrected)
**Flow-CLI Version:** v4.7.0+
