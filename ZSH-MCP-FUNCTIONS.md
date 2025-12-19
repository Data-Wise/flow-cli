# ZSH MCP Dispatcher

**Version:** 2.0 (Dispatcher Pattern)
**Created:** 2025-12-19
**Updated:** 2025-12-19 (Migrated to dispatcher pattern)

Unified dispatcher for managing MCP (Model Context Protocol) servers following zsh-configuration standards.

---

## Quick Reference

**Pattern:** `mcp <action> [args]` (following `g`, `r`, `v` dispatcher pattern)

```bash
mcp                  # List all servers (default)
mcp list             # or: mcp ls, mcp l
mcp cd docling       # or: mcp goto docling, mcp g docling
mcp test shell       # or: mcp t shell
mcp pick             # or: mcp p (interactive picker)
mcp help             # or: mcp h
```

**Single Alias:**
```bash
mcpp                 # mcp pick (interactive picker)
```

---

## Overview

### What It Does

MCP dispatcher provides a unified interface for:
- **Listing** all MCP servers with configuration status
- **Navigating** to server directories
- **Testing** that servers run correctly
- **Editing** servers in $EDITOR
- **Viewing** server documentation (READMEs)
- **Checking** configuration status (Desktop/CLI, Browser)
- **Picking** servers interactively with fzf

### Why Dispatcher Pattern?

**Previous (v1.0):**
```bash
mcp-list
mcp-cd docling
mcp-test shell
```

**Current (v2.0):**
```bash
mcp list
mcp cd docling
mcp test shell
```

**Benefits:**
- ✅ Consistent with `g`, `r`, `v` dispatchers
- ✅ Single mental model (`cmd keyword`)
- ✅ Follows zsh-configuration standards
- ✅ Better ADHD experience (one pattern everywhere)
- ✅ Extensible (easy to add new actions)

---

## Installation

### Location

```bash
~/.config/zsh/functions/mcp-dispatcher.zsh
```

### Auto-loaded in .zshrc

```zsh
# MCP Server Management Dispatcher (2025-12-19)
if [[ -f ~/.config/zsh/functions/mcp-dispatcher.zsh ]]; then
    source ~/.config/zsh/functions/mcp-dispatcher.zsh
fi
```

### Apply Changes

```bash
# Reload shell
source ~/.config/zsh/.zshrc

# Or start new terminal session
```

---

## Usage

### Default Action (No Arguments)

```bash
$ mcp
# Lists all servers (same as: mcp list)
```

### Core Actions

#### list (ls, l)
**List all MCP servers with status**

```bash
$ mcp list
# or
$ mcp ls
$ mcp l

# Output:
● docling
  📁 /Users/dt/projects/dev-tools/mcp-servers/docling
  ✓ Desktop/CLI configured
  ○ Browser not configured
  📖 README available
...
```

#### cd (goto, g)
**Navigate to server directory**

```bash
$ mcp cd docling         # Go to specific server
$ mcp cd                 # Go to main mcp-servers directory

# Aliases: goto, g
$ mcp g statistical-research
```

#### test (t)
**Test server runs correctly**

```bash
$ mcp test docling       # Test docling server
$ mcp t shell            # Short form

# Tests:
# - Checks runtime available (node/bun/uv)
# - Starts server
# - Verifies it runs
# - Stops cleanly
```

#### edit (e)
**Edit server in $EDITOR**

```bash
$ mcp edit project-refactor
$ mcp e shell            # Short form

# Opens in: $EDITOR (defaults to 'code')
```

### Info Actions

#### status (s)
**Check configuration status**

```bash
$ mcp status
$ mcp s                  # Short form

# Shows:
# - Desktop/CLI config (~/.claude/settings.json)
# - Browser config (~/projects/dev-tools/claude-mcp/MCP_SERVER_CONFIG.json)
# - Configured servers in each
```

#### readme (r, doc)
**View server README**

```bash
$ mcp readme docling     # View specific server README
$ mcp readme             # View main README
$ mcp r shell            # Short form
$ mcp doc statistical-research  # Alias
```

#### pick (p)
**Interactive server picker (fzf)**

```bash
$ mcp pick
$ mcp p                  # Short form
$ mcpp                   # Alias

# Interactive menu:
# 1) Navigate to server (cd)
# 2) Edit in $EDITOR
# 3) View README
# 4) Test server
# 5) Show in Finder
```

### Help

```bash
$ mcp help
$ mcp h
$ mcp --help
$ mcp -h
```

---

## All Keywords & Aliases

| Action | Keywords | Description |
|--------|----------|-------------|
| **list** | `list`, `ls`, `l` | List all servers |
| **cd** | `cd`, `goto`, `g` | Navigate to server |
| **test** | `test`, `t` | Test server runs |
| **edit** | `edit`, `e` | Edit in $EDITOR |
| **status** | `status`, `s` | Check config status |
| **readme** | `readme`, `r`, `doc` | View README |
| **pick** | `pick`, `p` | Interactive picker |
| **help** | `help`, `h`, `--help`, `-h` | Show help |

**Shell Alias:**
- `mcpp` → `mcp pick` (interactive picker)

---

## Configuration

### Environment Variables

```zsh
MCP_SERVERS_DIR="${HOME}/projects/dev-tools/mcp-servers"
MCP_DESKTOP_CONFIG="${HOME}/.claude/settings.json"
MCP_BROWSER_CONFIG="${HOME}/projects/dev-tools/claude-mcp/MCP_SERVER_CONFIG.json"
```

### Locations

- **Servers:** `~/projects/dev-tools/mcp-servers/`
- **Symlinks:** `~/mcp-servers/` (quick access)
- **Desktop/CLI:** `~/.claude/settings.json`
- **Browser:** `~/projects/dev-tools/claude-mcp/MCP_SERVER_CONFIG.json`

---

## Examples

### Daily Workflow

```bash
# Check what servers you have
$ mcp
# or
$ mcp list

# Work on a specific server
$ mcp cd docling
$ mcp test docling

# Edit server code
$ mcp edit docling

# View documentation
$ mcp readme docling

# Check configuration
$ mcp status
```

### Interactive Selection

```bash
# Use fzf picker for quick selection
$ mcpp
# or
$ mcp pick
# or
$ mcp p

# Select server → Choose action
```

### Testing New Server

```bash
# After adding new server to configs:
$ mcp list              # Verify it appears
$ mcp test my-server    # Test it runs
$ mcp cd my-server      # Navigate to it
```

---

## Testing

### Run Test Suite

```bash
$ cd ~/.config/zsh/tests
$ zsh test-mcp-dispatcher.zsh
```

### Test Coverage

12 tests:
1. MCP_SERVERS_DIR variable
2. mcp() dispatcher function
3-10. Internal functions (_mcp_list, _mcp_cd, etc.)
11. mcpp alias
12. Old mcp-* functions removed

**Current:** 12/12 passing ✓

---

## Technical Details

### File Structure

```zsh
# Main dispatcher
mcp() {
    case "$1" in
        list|ls|l) _mcp_list ;;
        cd|goto|g) _mcp_cd ;;
        test|t) _mcp_test ;;
        ...
    esac
}

# Internal functions (not directly callable)
_mcp_list() { ... }
_mcp_cd() { ... }
_mcp_test() { ... }
...
```

### Standards Compliance

✅ **Follows zsh-configuration conventions:**
- Dispatcher pattern (`cmd + keyword`)
- Internal functions (`_cmd_action`)
- Help structure with categories
- Color conventions
- No duplicates (removed old `mcp-*` functions)

✅ **Consistent with other dispatchers:**
- `g status` (git)
- `r test` (R)
- `v build` (vibe)
- `mcp list` (MCP) ← Same pattern!

---

## Migration from v1.0

### Breaking Changes

**Old (v1.0):**
```bash
mcp-list
mcp-cd docling
mcp-test shell

# Aliases:
ml, mc, mcpl, mcpc, mcpe, mcpt, mcps, mcpr, mcpp, mcph
```

**New (v2.0):**
```bash
mcp list
mcp cd docling
mcp test shell

# Single alias:
mcpp  # (mcp pick - most useful)
```

### Migration Path

**No action required!** The old functions have been removed and replaced with the dispatcher. Just reload your shell:

```bash
source ~/.config/zsh/.zshrc
```

**New usage:**
```bash
mcp              # List servers (default)
mcp cd <name>    # Navigate
mcp test <name>  # Test
mcpp             # Interactive picker
```

---

## Design Principles

### 1. ADHD-Friendly

- **Single pattern:** `mcp <keyword>` everywhere
- **Short keywords:** `l`, `t`, `e`, `p`, `s`
- **Interactive picker:** `mcpp` for when you can't remember names
- **Helpful errors:** Shows available servers when command fails

### 2. Discoverable

- **Default action:** `mcp` lists everything (most common use)
- **Help built-in:** `mcp help` shows all options
- **Consistent:** Same pattern as `g`, `r`, `v`

### 3. Extensible

Adding new actions is simple:

```zsh
# In mcp()
my-action|m)
    shift
    _mcp_my_action "$@"
    ;;

# Add function
_mcp_my_action() {
    # Implementation
}
```

---

## Troubleshooting

### Command not found: mcp

**Solution:** Reload shell
```bash
source ~/.config/zsh/.zshrc
```

### Tests failing

**Check:**
1. File exists: `~/.config/zsh/functions/mcp-dispatcher.zsh`
2. Sourced in: `~/.config/zsh/.zshrc`
3. Run tests: `zsh ~/.config/zsh/tests/test-mcp-dispatcher.zsh`

### Old mcp-* commands not working

**Expected!** Old functions removed in v2.0. Use new dispatcher:
- `mcp-list` → `mcp list`
- `mcp-cd` → `mcp cd`
- `mcp-test` → `mcp test`

---

## Related Documentation

- **Main Index:** `~/projects/dev-tools/_MCP_SERVERS.md`
- **Server README:** `~/projects/dev-tools/mcp-servers/README.md`
- **Standards:** `~/projects/dev-tools/zsh-configuration/docs/CONVENTIONS.md`
- **Test Results:** `~/.config/zsh/tests/test-mcp-dispatcher.zsh`

---

**Created:** 2025-12-19
**Version:** 2.0 (Dispatcher Pattern)
**Test Status:** 12/12 passing ✓
