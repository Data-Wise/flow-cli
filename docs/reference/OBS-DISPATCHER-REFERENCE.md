# OBS Dispatcher Reference

Obsidian vault management with AI-powered graph analysis

**Location:** `lib/dispatchers/obs.zsh`

---

## Quick Start

```bash
obs                   # List registered vaults
obs stats <vault>     # Show vault statistics
obs discover <path>   # Find vaults in directory
obs analyze <vault>   # Analyze vault graph
```

---

## Usage

```bash
obs [command] [options]
```

### Key Insight

- `obs` with no arguments lists registered vaults
- Uses Python CLI for heavy lifting (graph analysis, AI features)
- Manages Obsidian vaults stored in iCloud by default
- AI features require API key configuration

---

## Core Commands

| Command | Description |
|---------|-------------|
| `obs` | List registered vaults |
| `obs stats [vault]` | Show vault statistics |
| `obs discover <path>` | Find vaults in directory |
| `obs vaults` | List all registered vaults |

### Examples

```bash
obs                           # Quick vault list
obs stats                     # Stats for all vaults
obs stats personal            # Stats for specific vault
obs discover ~/Documents      # Find new vaults
```

---

## Graph Analysis

| Command | Description |
|---------|-------------|
| `obs analyze <vault_id>` | Analyze vault graph metrics |

### Example

```bash
obs analyze personal
```

**Output includes:**
- Note count and link density
- Orphan notes (unlinked)
- Hub notes (highly connected)
- Cluster analysis
- Graph health score

---

## AI Features

AI-powered analysis requires API keys.

| Command | Description |
|---------|-------------|
| `obs ai status` | Show AI provider status |
| `obs ai setup` | Interactive AI setup wizard |
| `obs ai test` | Test all AI providers |
| `obs ai similar <note>` | Find similar notes |
| `obs ai analyze <note>` | Analyze note with AI |
| `obs ai duplicates <vault>` | Find duplicate notes |

### Examples

```bash
# Setup
obs ai status                 # Check API key status
obs ai setup                  # Configure AI providers
obs ai test                   # Verify providers work

# Usage
obs ai similar my-note        # Find related notes
obs ai analyze my-note        # AI analysis of note
obs ai duplicates personal    # Find duplicates in vault
```

---

## Vault Discovery

Find Obsidian vaults in a directory:

```bash
obs discover ~/Documents
obs discover ~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents
```

**With scan flag:**

```bash
obs discover ~/Documents --scan
```

Scans recursively for `.obsidian` folders.

---

## Configuration

| Setting | Default |
|---------|---------|
| iCloud path | `~/Library/Mobile Documents/iCloud~md~obsidian/Documents` |
| Database | `~/.config/obs/obsidian_vaults.db` |
| Last vault | `~/.config/obs/last_vault` |

---

## Verbose Mode

Enable detailed output:

```bash
obs --verbose stats personal
obs -v analyze personal
```

---

## Examples

### Daily Workflow

```bash
# Check your vaults
obs

# View specific vault stats
obs stats work

# Analyze graph health
obs analyze work
```

### Finding New Vaults

```bash
# Discover vaults in iCloud
obs discover

# Discover in custom location
obs discover ~/Documents/notes
```

### AI Analysis

```bash
# Setup AI first
obs ai setup

# Find similar notes
obs ai similar project-ideas

# Find duplicates
obs ai duplicates work
```

---

## Integration

### With CC Dispatcher

Work on Obsidian tooling:

```bash
cd ~/projects/dev-tools/obsidian-cli-ops
cc                    # Claude with obs context
```

---

## Troubleshooting

### "Python CLI not found"

The obs dispatcher requires the Python CLI:

```bash
# Check Python is available
which python3

# Verify CLI location
ls -la ~/projects/dev-tools/obsidian-cli-ops/src/python/
```

### "Vault ID required"

Get vault IDs first:

```bash
obs vaults            # List all vault IDs
obs stats <vault_id>  # Use the ID
```

### AI features not working

Check provider status:

```bash
obs ai status         # See API key status
obs ai setup          # Configure keys
obs ai test           # Verify connection
```

---

## Version

Current version: 3.0.0-dev

Check version:

```bash
obs version
```

---

## Related

- [DISPATCHER-REFERENCE.md](DISPATCHER-REFERENCE.md) - All dispatchers

## Full Documentation

The `obs` dispatcher is part of the **obsidian-cli-ops** project. For comprehensive documentation:

| Resource | URL |
|----------|-----|
| **User Guide** | [data-wise.github.io/obsidian-cli-ops](https://data-wise.github.io/obsidian-cli-ops/) |
| **AI Setup** | See `obs ai setup` for configuration wizard |
| **Graph Analysis** | Deep dive in obsidian-cli-ops docs |
| **Source Code** | [github.com/data-wise/obsidian-cli-ops](https://github.com/data-wise/obsidian-cli-ops) |

**Note:** This reference covers the flow-cli dispatcher integration. For advanced features, vault management strategies, and AI configuration, refer to the obsidian-cli-ops documentation.

---

**Last Updated:** 2025-12-30
**Version:** v4.4.0+
**Status:** Fully implemented
