# YOLO Mode Workflow Tutorial

**Level:** Intermediate
**Time:** 10 minutes
**Goal:** Learn to use YOLO mode for rapid development with Claude Code

---

## What is YOLO Mode?

YOLO (You Only Live Once) mode is a Claude Code VS Code extension setting that **skips all permission prompts**, allowing Claude to:

- ✅ Read files instantly (no "Allow read?" prompts)
- ✅ Write files directly (no "Allow write?" prompts)
- ✅ Edit files automatically (no "Accept changes?" dialogs)
- ✅ Execute operations without interruption

**Trade-off:** Speed vs Safety
- **Pro:** Maximum development velocity, no interruptions
- **Con:** Claude can modify/delete files without confirmation

**Best for:** Trusted projects, rapid prototyping, refactoring sessions

---

## When to Use YOLO Mode

### ✅ Good Use Cases

- **Active development** - You're actively working and watching changes
- **Trusted projects** - Your own code you're comfortable with Claude modifying
- **Refactoring sessions** - Large-scale code changes across many files
- **Rapid prototyping** - Iterating quickly on features
- **Testing/experimentation** - Temporary code you can easily discard

### ❌ Avoid YOLO Mode When

- **Reviewing unfamiliar code** - First time seeing the codebase
- **Production deployments** - Critical code that needs careful review
- **Shared repositories** - Code with multiple contributors
- **Stepping away** - You won't be monitoring Claude's actions
- **Complex migrations** - High-risk operations you want to review carefully

---

## Setup: Enable YOLO Mode

### Method 1: Workspace Settings (Project-Specific) ⭐ Recommended

This keeps YOLO mode contained to specific trusted projects.

**Step 1:** Open your workspace file (e.g., `flow-cli.code-workspace`)

```json
{
    "folders": [{"path": "."}],
    "settings": {
        // Claude Code YOLO Configuration
        "claude-code.yoloMode": true,        // Skip permission prompts
        "claude-code.acceptEdits": true,     // Auto-accept edits

        // Optional enhancements
        "claude-code.autoSave": true,        // Auto-save after edits
        "claude-code.showTokenCount": true   // Show token usage
    }
}
```

**Step 2:** Open the workspace

```bash
# From terminal
code flow-cli.code-workspace

# Or double-click in Finder/Explorer
```

**Step 3:** Verify YOLO mode is active

VS Code title bar should show: `flow-cli (Workspace)`

### Method 2: Global Settings (All Projects)

⚠️ **Warning:** This enables YOLO mode for ALL projects in VS Code.

1. Open Settings: `Cmd+,` (Mac) or `Ctrl+,` (Windows/Linux)
2. Search: `claude code yolo`
3. Enable: `Claude Code: YOLO Mode`
4. Enable: `Claude Code: Accept Edits`

### Method 3: Command Palette (Temporary Toggle)

Quick enable/disable without changing settings:

1. Press: `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows/Linux)
2. Type: `Claude Code: Toggle YOLO Mode`
3. Press: Enter

---

## Workflow: YOLO Mode in Action

### Scenario 1: Quick Bug Fix

**Without YOLO Mode:**

1. You: "Fix the typo in README.md line 42"
2. Claude: "I'll read README.md first"
3. 🛑 **Prompt:** "Allow Claude to read README.md?"
4. You: Click "Allow"
5. Claude: Shows the fix
6. 🛑 **Prompt:** "Accept changes?"
7. You: Click "Accept"
8. **Total:** 4 interactions

**With YOLO Mode:**

1. You: "Fix the typo in README.md line 42"
2. Claude: Reads file → Fixes typo → Saves file
3. **Total:** 1 interaction ✅

### Scenario 2: Refactoring Session

**Task:** Rename function across 10 files

**Without YOLO Mode:**

- 10 "Allow read?" prompts
- 10 "Accept changes?" prompts
- **Total:** 20+ interruptions 😫

**With YOLO Mode:**

- Claude reads all files silently
- Claude makes all edits automatically
- You review the git diff when done
- **Total:** 0 interruptions ✅

### Scenario 3: New Feature Implementation

**Task:** Add authentication system

**YOLO Mode Workflow:**

```
1. You: "Add JWT authentication to the API"

2. Claude (automatically):
   ✅ Reads current auth.js
   ✅ Creates new jwt-utils.js
   ✅ Updates routes.js
   ✅ Creates tests/auth.test.js
   ✅ Updates package.json

3. You: Review changes with git
   git diff --stat
   git diff auth.js

4. You: Test the implementation
   npm test

5. You: Commit or ask for adjustments
```

**Key:** You stay in "flow state" without permission interruptions.

---

## Safety Practices with YOLO Mode

### 1. Use Git as Your Safety Net

Always work in a git repository with YOLO mode:

```bash
# Before starting YOLO session
git status                    # Ensure clean working tree
git checkout -b feature-name  # Work on a branch

# During YOLO session
git diff                      # Review Claude's changes frequently
git diff --stat               # See which files changed

# After YOLO session
git add -p                    # Stage changes selectively
git commit -m "message"       # Commit reviewed changes

# If something goes wrong
git checkout -- file.js       # Discard changes to specific file
git reset --hard HEAD         # Nuclear option: discard ALL changes
```

### 2. Review Changes Frequently

Don't let Claude make 50 changes before checking. Review every 5-10 edits:

```bash
# Quick review workflow
git diff --stat               # See what files changed
git diff lib/core.js          # Review specific file
```

### 3. Start Small

First YOLO session? Start with low-risk tasks:

- ✅ Update documentation
- ✅ Add unit tests
- ✅ Refactor a single module
- ❌ Rewrite entire authentication system

### 4. Keep Backups

For critical changes:

```bash
# Create a backup branch
git checkout -b backup-before-yolo
git checkout feature-name

# Now safe to YOLO
```

### 5. Use Worktrees for Isolation

Keep main codebase safe while experimenting:

```bash
# Create worktree for YOLO experiments
wt create experiment-yolo

# Claude works in isolated directory
cd ~/projects/.git-worktrees/flow-cli-experiment-yolo

# If experiment fails, just delete the worktree
wt remove experiment-yolo
```

---

## Shell Integration: flow-cli Commands

If you have flow-cli installed, you can launch Claude in YOLO mode from the terminal:

### Quick YOLO Launch

```bash
# Launch Claude HERE in YOLO mode
cc yolo

# Alias (shorter)
ccy

# Pick project, then YOLO
cc yolo pick

# YOLO + Plan mode
cc yolo plan
```

### Worktree + YOLO Combo

Perfect for experimental features:

```bash
# Create worktree + launch Claude in YOLO mode
wt create feature-auth
cd ~/projects/.git-worktrees/flow-cli-feature-auth
cc yolo

# Or combined:
cc wt yolo feature-auth    # Create worktree + launch in YOLO
```

### Session Workflow

```bash
# 1. Start session
work flow-cli

# 2. Create feature branch
g feature start yolo-experiment

# 3. Launch Claude in YOLO
cc yolo

# 4. Work with Claude (no interruptions)
# ...

# 5. Review changes
git diff --stat

# 6. Commit if good
g commit -m "feat: add feature"

# 7. End session
finish "Added feature with YOLO mode"
```

---

## Advanced: YOLO Mode Settings Reference

### Workspace Settings (.code-workspace)

```json
{
    "folders": [{"path": "."}],
    "settings": {
        // Core YOLO settings
        "claude-code.yoloMode": true,
        "claude-code.acceptEdits": true,

        // Productivity enhancements
        "claude-code.autoSave": true,           // Save after each edit
        "claude-code.showTokenCount": true,     // Track token usage

        // Optional: Customize Claude behavior
        "claude-code.contextFiles": [           // Always include these files
            "README.md",
            "ARCHITECTURE.md"
        ],

        // Editor settings for YOLO sessions
        "files.autoSave": "afterDelay",         // Auto-save all files
        "files.autoSaveDelay": 1000,            // 1 second delay

        // Git integration
        "git.autofetch": true,                  // Keep git up to date
        "git.confirmSync": false                // Skip git sync confirmations
    }
}
```

### Global Settings (settings.json)

For YOLO mode across all projects:

```json
{
    // Claude Code
    "claude-code.yoloMode": true,
    "claude-code.acceptEdits": true,

    // Git safety
    "git.confirmSync": true,        // Keep this true for global!
    "git.autofetch": true
}
```

---

## Troubleshooting

### YOLO Mode Not Working?

**Check 1:** Verify settings are active

```bash
# Open workspace file
cat flow-cli.code-workspace | grep yoloMode

# Should show: "claude-code.yoloMode": true
```

**Check 2:** Reload VS Code window

1. `Cmd+Shift+P` → "Reload Window"
2. Or restart VS Code

**Check 3:** Ensure using workspace file

VS Code title bar should show: `project-name (Workspace)`

If it just shows `project-name`, you're in folder mode, not workspace mode.

**Fix:**

```bash
# Open with workspace file explicitly
code flow-cli.code-workspace
```

### Claude Still Asking for Permissions?

**Possible causes:**

1. **Wrong setting name** - Check spelling: `claude-code.yoloMode` (not `claudeCode.yoloMode`)
2. **JSON syntax error** - Validate JSON in workspace file
3. **Extension not installed** - Install "Claude Code" extension
4. **Extension disabled** - Enable in Extensions panel

### Changes Not Auto-Saving?

Add to workspace settings:

```json
{
    "settings": {
        "claude-code.autoSave": true,
        "files.autoSave": "afterDelay",
        "files.autoSaveDelay": 1000
    }
}
```

---

## Best Practices Summary

### ✅ DO

- ✅ Use git branches for YOLO sessions
- ✅ Review changes frequently (`git diff`)
- ✅ Start with small, low-risk tasks
- ✅ Keep workspace file in version control
- ✅ Test changes before committing
- ✅ Use worktrees for experiments

### ❌ DON'T

- ❌ Enable YOLO globally without understanding risks
- ❌ Walk away during YOLO session
- ❌ Skip reviewing changes before commit
- ❌ Use YOLO on production branches
- ❌ Disable git confirmations globally
- ❌ Work without git (YOLO needs safety net)

---

## Example Session: Start to Finish

### Complete YOLO Workflow

```bash
# 1. Preparation
cd ~/projects/flow-cli
git checkout -b feature-yolo-demo
git status                          # Ensure clean

# 2. Open workspace with YOLO enabled
code flow-cli.code-workspace

# 3. Start Claude Code chat
# Ask: "Refactor commands/work.zsh to use modern ZSH patterns"

# 4. Monitor progress (in separate terminal)
watch -n 2 'git diff --stat'        # Auto-refresh every 2 seconds

# 5. After Claude finishes
git diff --stat                     # Review what changed
git diff commands/work.zsh          # Detailed review

# 6. Test changes
source flow.plugin.zsh
work test-project                   # Test the refactored command

# 7. Commit if good
git add commands/work.zsh
git commit -m "refactor: modernize work command patterns"

# 8. Or revert if bad
git checkout -- commands/work.zsh

# 9. Continue iterating or finish
g push                              # Push to remote
finish "Refactored work command"    # End session
```

---

## Keyboard Shortcuts

Speed up your YOLO workflow with these shortcuts:

| Action | Mac | Windows/Linux |
|--------|-----|---------------|
| Toggle YOLO Mode | `Cmd+Shift+P` → "Toggle YOLO" | `Ctrl+Shift+P` → "Toggle YOLO" |
| Show Git Changes | `Ctrl+Shift+G` | `Ctrl+Shift+G` |
| Quick Git Diff | `Cmd+K Cmd+D` | `Ctrl+K Ctrl+D` |
| Reload Window | `Cmd+Shift+P` → "Reload" | `Ctrl+Shift+P` → "Reload" |
| Source Control | `Ctrl+Shift+G` | `Ctrl+Shift+G` |

---

## Next Steps

1. **Try it:** Create a workspace file with YOLO settings
2. **Test safely:** Use a git branch for first YOLO session
3. **Build habit:** Review changes frequently with `git diff`
4. **Optimize:** Add YOLO to your daily development workflow
5. **Share:** Add workspace file to project for team members

---

## Related Documentation

- [CC Dispatcher Reference](../reference/CC-DISPATCHER-REFERENCE.md) - Claude Code launcher commands
- [Worktree Workflows](WORKTREE-WORKFLOWS.md) - Isolated development environments
- [Git Feature Workflow](GIT-FEATURE-WORKFLOW.md) - Branch management

---

**Last Updated:** 2026-01-01
**Flow-CLI Version:** v4.7.0+
