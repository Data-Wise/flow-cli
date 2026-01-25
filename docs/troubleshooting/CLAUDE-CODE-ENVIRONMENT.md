# Claude Code Environment & flow-cli Integration

**Date:** 2026-01-24
**Version:** v5.18.0-dev
**Issue:** Bug fixes for tutorial auto-launch and Claude Code shell limitations

---

## Overview

This document explains how flow-cli behaves in Claude Code's shell environment and documents bug fixes related to plugin loading and tutorial execution.

---

## Bug Fixes (2026-01-24)

### 1. Tutorial Auto-Launch Bug

**Commit:** `e7d24e08`
**Files:** `commands/secret-tutorial.zsh`, `lib/dispatchers/dot-dispatcher.zsh`

#### Problem

The token management tutorial (`dot secret tutorial`) auto-launched every time flow-cli loaded, interrupting the user experience.

#### Root Causes

1. **Broken Source Detection:**
   ```zsh
   # BEFORE (incorrect)
   if [[ "${(%):-%x}" == "${0}" ]]; then
     _dot_secret_tutorial "$@"
   fi
   ```

   When a file is sourced, both `${(%):-%x}` and `${0}` equal the file path, causing the condition to match incorrectly.

2. **Incorrect Path Resolution:**
   ```zsh
   # BEFORE (incorrect)
   local tutorial_file="${0:A:h}/../../commands/secret-tutorial.zsh"
   # Resolved to: /Users/dt/projects/dev-tools/commands/secret-tutorial.zsh (wrong!)
   ```

#### Solution

1. **Fixed Source Detection:**
   ```zsh
   # AFTER (correct)
   if [[ "${ZSH_EVAL_CONTEXT}" == "toplevel" ]]; then
     _dot_secret_tutorial "$@"
   fi
   ```

   `ZSH_EVAL_CONTEXT` equals `"toplevel"` only when the script is executed directly, not when sourced by the plugin loader.

2. **Fixed Path Resolution:**
   ```zsh
   # AFTER (correct)
   local tutorial_file="${FLOW_PLUGIN_DIR}/commands/secret-tutorial.zsh"
   # Resolves to: /Users/dt/projects/dev-tools/flow-cli/commands/secret-tutorial.zsh (correct!)
   ```

   Using `$FLOW_PLUGIN_DIR` ensures reliable path resolution regardless of execution context.

#### Testing

| Test | Result |
|------|--------|
| Plugin loads silently (no auto-launch) | ✅ Pass |
| `dot secret tutorial` works when called | ✅ Pass |
| Tutorial detects non-interactive shells | ✅ Pass |

---

## Claude Code Shell Environment

### How Claude Code Works

Claude Code uses a **minimal shell snapshot** for tool execution:

1. **Snapshot File:** `~/.claude/shell-snapshots/snapshot-zsh-*.sh`
2. **Alias Handling:** Explicitly unsets all aliases (`unalias -a`)
3. **Environment:** Minimal PATH and environment variables
4. **Purpose:** Security isolation and consistent execution

### Shell Snapshot Contents

```zsh
# Snapshot file
# Unset all aliases to avoid conflicts with functions
unalias -a 2>/dev/null || true

# Check for rg availability
if ! (unalias rg 2>/dev/null; command -v rg) >/dev/null 2>&1; then
  alias rg='/opt/homebrew/Caskroom/claude-code/2.1.19/claude --ripgrep'
fi

export PATH=/Users/dt/.local/bin:/opt/homebrew/bin:...
```

### Why flow-cli Doesn't Load Automatically

**Snapshot Limitations:**
- ❌ Doesn't source `.zshrc`
- ❌ Doesn't load ZSH plugins
- ❌ Unsets all aliases
- ❌ Minimal environment

**By Design:**
- Security: Prevents untrusted code execution
- Consistency: Same environment across sessions
- Performance: Lightweight shell for tool execution

---

## flow-cli Behavior Comparison

### Normal ZSH Shell

```bash
# In iTerm/Terminal
$ source ~/.config/zsh/.zshrc
$ work          # ✅ Works
$ dash          # ✅ Works
$ ccy           # ✅ Works (alias: cc yolo)
$ dot secret    # ✅ Works
```

**Status:** ✅ All features work perfectly

### Claude Code Shell

```bash
# In Claude Code session
$ work          # ❌ command not found
$ dash          # ❌ /bin/dash (wrong command)
$ ccy           # ❌ clang error (alias not loaded)
$ dot           # ❌ /opt/homebrew/bin/dot (Graphviz, not flow-cli)
```

**Status:** ⚠️ Limited by snapshot design

---

## Workarounds

### Option 1: Use Full Commands (Recommended)

Instead of flow-cli commands, use standard git/shell commands in Claude Code:

| flow-cli | Claude Code Alternative |
|----------|------------------------|
| `ccy` | `cc yolo` (full command) |
| `work` | Regular git/shell workflow |
| `dot secret` | Direct Keychain access (`security` command) |
| `g push` | `git push` |

### Option 2: Manual Plugin Load (Per-Session)

Source flow-cli manually in each Claude Code session:

```bash
source ~/.zsh/plugins/flow-cli/flow.plugin.zsh 2>/dev/null
```

**Caveat:** Tutorial will launch once (now auto-cancels in non-interactive shells)

### Option 3: Use Real Terminal

For full flow-cli functionality, use a real terminal (iTerm, Terminal.app):

```bash
# Open iTerm
open -a iTerm

# Or use Terminal
open -a Terminal
```

---

## Diagnostic Commands

### Check flow-cli Status in Current Shell

```bash
# Check if commands are loaded
type work dash pick dot cc

# Check if plugin is loaded
echo $FLOW_PLUGIN_LOADED
echo $FLOW_VERSION

# List all flow-cli functions
typeset -f | grep '^_flow_' | head -20
```

### Test flow-cli in Fresh ZSH Shell

```bash
# Test in subshell
zsh -c 'source ~/.zsh/plugins/flow-cli/flow.plugin.zsh 2>/dev/null && type work'

# Expected output:
# work is a shell function from /Users/dt/projects/dev-tools/flow-cli/commands/work.zsh
```

### Check Alias Definitions

```bash
# In normal ZSH
alias ccy
# Expected: ccy='cc yolo'

# In Claude Code
alias ccy
# Expected: (exit code 1, alias not found)
```

---

## Technical Details

### ZSH Source Detection Methods

| Method | Purpose | Behavior |
|--------|---------|----------|
| `${0}` | Script name | Equals file path when sourced or executed |
| `${(%):-%x}` | Current file | Equals file path when sourced or executed |
| `${ZSH_EVAL_CONTEXT}` | Execution context | `"toplevel"` = direct execution, `"file"` = sourced |

**Correct Pattern for "Execute Only":**

```zsh
# Only run when executed directly
if [[ "${ZSH_EVAL_CONTEXT}" == "toplevel" ]]; then
  main "$@"
fi
```

### Path Resolution Best Practices

**❌ Don't use relative paths:**
```zsh
local file="${0:A:h}/../../commands/something.zsh"
# Fragile - breaks if execution context changes
```

**✅ Use plugin directory variable:**
```zsh
local file="${FLOW_PLUGIN_DIR}/commands/something.zsh"
# Reliable - set once during plugin load
```

---

## Testing Checklist

When modifying plugin loading or command execution:

- [ ] Test in normal ZSH shell (iTerm/Terminal)
- [ ] Test in Claude Code session
- [ ] Test with `source flow.plugin.zsh`
- [ ] Test with direct execution (`./script.zsh`)
- [ ] Test in fresh ZSH subshell (`zsh -c '...'`)
- [ ] Test in non-interactive context
- [ ] Check tutorial doesn't auto-launch
- [ ] Verify path resolution works

---

## Related Files

| File | Purpose |
|------|---------|
| `flow.plugin.zsh` | Plugin entry point |
| `commands/secret-tutorial.zsh` | Interactive token tutorial |
| `lib/dispatchers/dot-dispatcher.zsh` | DOT dispatcher (secrets, dotfiles) |
| `~/.config/zsh/.zshrc` | User ZSH configuration |
| `~/.zsh/plugins/flow-cli/` | Symlink to flow-cli plugin |
| `~/.claude/shell-snapshots/` | Claude Code shell snapshots |

---

## Commit History

| Commit | Date | Description |
|--------|------|-------------|
| `e7d24e08` | 2026-01-24 | Fix tutorial auto-launch and path resolution |

---

## See Also

- [Testing Guide](../guides/TESTING.md) - Test suite documentation
- [Developer Guide](../guides/DEVELOPER-GUIDE.md) - Plugin development
- [Troubleshooting](../getting-started/troubleshooting.md) - Common issues

---

**Last Updated:** 2026-01-24
**Status:** Production-ready (v5.18.0-dev)
