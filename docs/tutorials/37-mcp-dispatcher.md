---
tags:
  - tutorial
  - dispatchers
  - mcp
---

# Tutorial: Managing MCP Servers with mcp

Discover, navigate, test, and inspect your MCP (Model Context Protocol) servers from the command line without remembering paths or config file locations.

**Time:** 15 minutes | **Level:** Intermediate | **Requires:** flow-cli, MCP servers in `~/projects/dev-tools/mcp-servers/`

## What You'll Learn

1. Listing MCP servers and their configuration status
2. Navigating to server directories
3. Testing servers
4. Editing server code
5. Using the interactive server picker
6. Viewing server status and documentation

---

## Step 1: List All Servers

Run `mcp` with no arguments (or `mcp list`) to see every server in your MCP directory:

```zsh
mcp
```

**What you see for each server:**

- Directory path on disk
- Desktop/CLI configuration status — whether the server appears in `~/.claude/settings.json`
- Browser configuration status — whether the server appears in `MCP_SERVER_CONFIG.json`
- Whether a README is available

**Status indicators:**

| Symbol | Meaning |
|--------|---------|
| `✓` (green) | Configured in that environment |
| `○` (yellow) | Not yet configured |

**Aliases:** `mcp ls`, `mcp l`

---

## Step 2: Navigate to a Server

Jump directly to a server's directory without typing the full path:

```zsh
mcp cd docling         # Navigate to a specific server
mcp cd                 # Navigate to the main mcp-servers directory
```

If the server does not exist, you see a list of available servers to choose from.

**Aliases:** `mcp goto <name>`, `mcp g <name>`

---

## Step 3: Test a Server

Verify a server starts up correctly without a full Claude session:

```zsh
mcp test shell
```

The dispatcher detects the server's runtime (Node.js, Bun, Python/uv), starts the server with a timeout, and reports whether it ran successfully or shows the error output.

**Aliases:** `mcp t <name>`

---

## Step 4: Edit Server Config

Open a server's directory in your `$EDITOR`:

```zsh
mcp edit shell
```

**Aliases:** `mcp e <name>`

---

## Step 5: Interactive Picker

Not sure which server you want? Use fzf to browse and act:

```zsh
mcp pick
```

**What happens:**

1. fzf opens with all server names listed
2. The right panel previews the server's README (if available)
3. Select a server and press Enter
4. A numbered menu appears with options: navigate, edit, view README, test, or show in Finder

**Aliases:** `mcp p`, `mcpp` (global alias)

**Requires:** `fzf`

---

## Step 6: Server Status

See a detailed summary of your MCP configuration across environments:

```zsh
mcp status
```

Shows which servers are configured in Desktop/CLI (`~/.claude/settings.json`) vs Browser (`MCP_SERVER_CONFIG.json`), with quick-copy commands to open each config file.

**Aliases:** `mcp s`

---

## Step 7: View a README

Read a server's documentation without leaving the terminal:

```zsh
mcp readme docling
```

Opens the server's `README.md` in your `$PAGER`.

**Aliases:** `mcp r <name>`, `mcp doc <name>`

---

## Configuration

Override these in `~/.zshrc` to point to non-standard locations:

```zsh
MCP_SERVERS_DIR="${HOME}/projects/dev-tools/mcp-servers"
MCP_DESKTOP_CONFIG="${HOME}/.claude/settings.json"
MCP_BROWSER_CONFIG="${HOME}/projects/dev-tools/claude-mcp/MCP_SERVER_CONFIG.json"
```

---

## Quick Reference

| Command | Short | What it does |
|---------|-------|-------------|
| `mcp` | `mcp l` | List all servers with status |
| `mcp cd <name>` | `mcp g <name>` | Navigate to server directory |
| `mcp test <name>` | `mcp t <name>` | Test server startup |
| `mcp edit <name>` | `mcp e <name>` | Open server in `$EDITOR` |
| `mcp pick` | `mcpp` | Interactive fzf picker |
| `mcp status` | `mcp s` | Configuration status |
| `mcp readme <name>` | `mcp r <name>` | View server README |
| `mcp help` | `mcp h` | Show help |

---

## FAQ

### What is MCP?

MCP (Model Context Protocol) is an open standard from Anthropic that lets AI assistants like Claude connect to external tools and data sources. Each MCP server exposes a set of tools — for example, a shell server might let Claude run commands, while a document server might let it read PDFs.

### Where do my MCP servers live?

By default, the dispatcher looks in `~/projects/dev-tools/mcp-servers/`. Each subdirectory is treated as one server. Override the path with `MCP_SERVERS_DIR`.

### How do I add a new server?

Create a subdirectory in `$MCP_SERVERS_DIR` with your server code, then register it in the appropriate config file: `~/.claude/settings.json` for Desktop/CLI, or `MCP_SERVER_CONFIG.json` for the browser extension.

### What do the status indicators mean?

- **Green `✓`** — server name found in the config file; it will be loaded
- **Yellow `○`** — server exists on disk but is not registered; it will not be loaded

A server can be configured for one environment but not the other.

---

## Next Steps

- **[MASTER-DISPATCHER-GUIDE](../reference/MASTER-DISPATCHER-GUIDE.md)** — Complete reference for all 15 dispatchers
- **[Model Context Protocol](https://modelcontextprotocol.io/)** — Official MCP documentation
