# MCP Dispatcher Reference

MCP (Model Context Protocol) server management

**Location:** `lib/dispatchers/mcp-dispatcher.zsh`

---

## Quick Start

```bash
mcp                   # List all servers with status
mcp cd shell          # Navigate to server directory
mcp test docling      # Test server runs
mcp pick              # Interactive server picker
```

---

## Usage

```bash
mcp [command] [args]
```

### Key Insight

- `mcp` with no arguments lists all servers with configuration status
- Shows both Desktop/CLI and Browser extension configuration
- Interactive picker (`mcp pick`) for quick navigation
- Test command validates servers actually run

---

## Core Commands

| Command | Shortcut | Description |
|---------|----------|-------------|
| `mcp` | `mcp list`, `mcp ls`, `mcp l` | List all servers with status |
| `mcp cd <name>` | `mcp goto`, `mcp g` | Navigate to server directory |
| `mcp test <name>` | `mcp t` | Test server runs |
| `mcp edit <name>` | `mcp e` | Edit in $EDITOR |
| `mcp pick` | `mcp p` | Interactive picker (fzf) |

### Examples

```bash
mcp                   # List all servers
mcp cd shell          # Navigate to shell server
mcp test docling      # Test docling server
mcp edit shell        # Open in VS Code
mcp pick              # Interactive selection
```

---

## Info Commands

| Command | Shortcut | Description |
|---------|----------|-------------|
| `mcp status` | `mcp s` | Show configuration status |
| `mcp readme <name>` | `mcp r`, `mcp doc` | View server README |
| `mcp help` | `mcp h` | Show help |

### Examples

```bash
mcp status            # Show Desktop/Browser config status
mcp readme docling    # View docling README
mcp help              # Show all commands
```

---

## Server List Output

Running `mcp` shows each server with:

```
● statistical-research
  📁 ~/projects/dev-tools/mcp-servers/statistical-research
  ✓ Desktop/CLI configured
  ✓ Browser configured
  📖 README available

● shell
  📁 ~/projects/dev-tools/mcp-servers/shell
  ✓ Desktop/CLI configured
  ○ Browser not configured

Total: 3 server(s)

ℹ  Quick access: cd ~/mcp-servers/<name>
ℹ  Interactive:  mcp pick
```

---

## Configuration Status

Running `mcp status` shows:

```
MCP Configuration Status

Desktop/CLI:
  ✓ ~/.claude/settings.json
  Configured servers:
    • filesystem
    • statistical-research
    • shell

Browser Extension:
  ✓ ~/projects/dev-tools/claude-mcp/MCP_SERVER_CONFIG.json
  Configured servers:
    • filesystem
    • statistical-research
```

---

## Interactive Picker

`mcp pick` (alias: `mcpp`) provides:

1. fzf selection with README preview
2. Action menu after selection:
   - Navigate to server (cd)
   - Edit in $EDITOR
   - View README
   - Test server
   - Show in Finder

### Example

```bash
mcpp                  # Quick picker alias
```

---

## Testing Servers

The test command validates a server can start:

```bash
mcp test statistical-research
```

**Behavior:**
- Detects runtime (bun, node, uv)
- Starts server with 3-second timeout
- Reports success/failure
- Shows any error output

**Supported runtimes:**
- `statistical-research` → bun
- `shell`, `project-refactor` → node
- `docling` → uv (Python)

---

## Configuration Locations

| Config | Path |
|--------|------|
| Servers | `~/projects/dev-tools/mcp-servers/` |
| Symlinks | `~/mcp-servers/<name>` |
| Desktop/CLI | `~/.claude/settings.json` |
| Browser | `~/projects/dev-tools/claude-mcp/MCP_SERVER_CONFIG.json` |

---

## Shortcuts Summary

| Full | Short | Description |
|------|-------|-------------|
| `list` | `ls`, `l` | List servers |
| `cd` | `goto`, `g` | Navigate |
| `test` | `t` | Test server |
| `edit` | `e` | Edit server |
| `status` | `s` | Config status |
| `readme` | `r`, `doc` | View README |
| `pick` | `p` | Interactive picker |
| `help` | `h` | Show help |

**Alias:** `mcpp` = `mcp pick`

---

## Examples

### Daily Workflow

```bash
# Check what's configured
mcp status

# Navigate to work on a server
mcp cd statistical-research

# Test after changes
mcp test statistical-research
```

### Quick Navigation

```bash
# Interactive selection
mcpp

# Or direct navigation
mcp cd shell
```

### Troubleshooting

```bash
# Check server runs
mcp test docling

# View documentation
mcp readme docling

# Edit configuration
mcp edit docling
```

---

## Integration

### With CC Dispatcher

Launch Claude with MCP context:

```bash
mcp cd statistical-research
cc                    # Claude in MCP server dir
```

### With aiterm

For richer output:

```bash
ait mcp list          # Rich table output
ait mcp validate      # Detailed config validation
```

---

## Troubleshooting

### "MCP servers directory not found"

Set the directory:

```bash
export MCP_SERVERS_DIR="$HOME/projects/dev-tools/mcp-servers"
```

### "fzf not installed"

Install fzf for interactive picker:

```bash
brew install fzf
```

### "Server failed to start"

Check requirements:
- `statistical-research` needs bun
- `shell` needs node
- `docling` needs uv (Python)

```bash
# Install runtimes
brew install node
brew install bun
brew install uv
```

---

## Related

- [DISPATCHER-REFERENCE.md](DISPATCHER-REFERENCE.md) - All dispatchers
- [CC-DISPATCHER-REFERENCE.md](CC-DISPATCHER-REFERENCE.md) - Claude Code launcher

---

**Last Updated:** 2025-12-30
**Version:** v4.4.0+
**Status:** Fully implemented
