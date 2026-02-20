---
tags:
  - tutorial
  - dispatchers
  - obsidian
  - knowledge-base
  - ai
---

# Tutorial: Obsidian Vault Management with obs

Discover, analyze, and search your Obsidian vaults with AI-powered graph analysis — all from the command line.

**Time:** 15 minutes | **Level:** Intermediate | **Requires:** flow-cli, python3, jq

## What You'll Learn

1. Listing and discovering Obsidian vaults
2. Viewing vault statistics and graph metrics
3. Configuring AI providers for vault analysis
4. Using AI-powered search for similar and duplicate notes
5. Analyzing individual notes with AI

---

## Step 1: List Your Vaults

See all registered Obsidian vaults:

```zsh
obs
```

Or explicitly:

```zsh
obs vaults
```

Each vault shows its path and note count. Vault data is stored in `~/.config/obs/obsidian_vaults.db`.

---

## Step 2: Discover Vaults

Scan a directory to find all Obsidian vaults (identified by `.obsidian/` folders):

```zsh
obs discover ~/Documents
```

For iCloud-synced vaults:

```zsh
obs discover ~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents
```

Discovered vaults are automatically registered and appear in `obs vaults`.

---

## Step 3: Vault Statistics

Get detailed stats about any vault:

```zsh
obs stats my-vault
```

Shows: note count, link count, tag count, orphan notes, and average links per note.

---

## Step 4: Graph Analysis

Analyze vault structure and connectivity:

```zsh
obs analyze my-vault
```

Shows: network connectivity score, identified clusters, hub notes (most connected), density metrics, and linking recommendations.

---

## Step 5: AI Setup

Configure AI providers for advanced vault analysis:

```zsh
obs ai setup     # Interactive setup wizard
obs ai status    # Show current AI configuration
obs ai test      # Verify all providers work
```

---

## Step 6: AI-Powered Search

Find notes by meaning, not just keywords:

```zsh
obs ai similar "My Note Title"   # Find semantically similar notes
obs ai duplicates                # Find potential duplicate content
obs ai analyze "Note Title"      # AI analysis of a specific note
```

`obs ai analyze` returns key concepts, related topics, suggested links, and knowledge graph gaps.

---

## Step 7: Verbose Mode

Add `--verbose` to any command for detailed output:

```zsh
obs --verbose stats my-vault
```

Shows API calls, file scanning details, and performance timings.

---

## FAQ

### Where is vault data stored?

Vault registry is at `~/.config/obs/obsidian_vaults.db`. The last-used vault is tracked in `~/.config/obs/last_vault`.

### Does obs work with iCloud-synced vaults?

Yes. Use `obs discover` with the iCloud Obsidian path. They work like any other vault.

### What AI providers are supported?

OpenAI, Anthropic (Claude), local models via Ollama, and OpenAI-compatible APIs. Run `obs ai setup` to see options.

### Does analyzing a vault change my files?

No. All analysis is read-only. No notes are modified.

---

## Next Steps

- **[MASTER-DISPATCHER-GUIDE](../reference/MASTER-DISPATCHER-GUIDE.md)** — Complete reference for all 15 dispatchers
- **[Obsidian Documentation](https://help.obsidian.md/)** — Official Obsidian reference
