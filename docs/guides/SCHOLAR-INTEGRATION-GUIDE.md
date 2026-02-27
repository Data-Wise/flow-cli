# Scholar Integration Guide

How flow-cli integrates with the Scholar teaching plugin for AI-powered content generation.

## Prerequisites

- flow-cli v7.6.0+
- Scholar plugin installed (`~/.claude/plugins/scholar/`)
- Claude Code CLI (`claude` command available)
- Course initialized with `teach init`

## How Config Sync Works

When you run any Scholar-powered `teach` command (e.g., `teach exam`, `teach lecture`), flow-cli:

1. **Discovers config** via `_teach_find_config()` — looks for `.flow/teach-config.yml`
2. **Checks for changes** via `_flow_config_changed()` — warns if config changed since last run
3. **Injects `--config`** — appends `--config "/path/to/config"` to the Scholar command
4. **Checks for legacy files** — warns if deprecated `.claude/teaching-style.local.md` exists

This is transparent — no flags needed. If config exists, it's injected automatically.

## Setting Up Config Sync

```bash
# 1. Initialize project (creates .flow/teach-config.yml)
teach init "STAT 440"

# 2. Verify config is detected
teach doctor

# Look for:
#   Scholar Config:
#     ✅ Config file: .flow/teach-config.yml
#     ✅ Scholar section: present
#     ✅ Auto-injection: enabled
```

## Config Management Commands

| Command | Description |
|---------|-------------|
| `teach config check` | Validate config strictly (pre-flight check) |
| `teach config diff` | Compare your prompts vs Scholar defaults |
| `teach config show` | Show resolved 4-layer config (defaults + project + user + overrides) |
| `teach config scaffold` | Copy default prompts into your project for customization |
| `teach config edit` | Open config in `$EDITOR` (existing) |

### Examples

```bash
# Validate before a big generation run
teach config check

# See what you've customized vs defaults
teach config diff

# Copy exam prompt template for customization
teach config scaffold exam
```

## New Generation Commands

| Command | Description |
|---------|-------------|
| `teach solution <topic>` | Generate a standalone solution key |
| `teach sync` | Sync local config to Scholar's expected format |
| `teach validate-r` | Validate R code chunks in .qmd files |

### Examples

```bash
# Generate solution key for an exam topic
teach solution "Bayesian inference"

# Sync config after manual edits
teach sync

# Check R code before deploying
teach validate-r
```

## Troubleshooting

### "Config changed since last Scholar run"

Your `.flow/teach-config.yml` was modified after the last Scholar command. Run `teach config check` to validate, then re-run your command.

### "Deprecated: .claude/teaching-style.local.md"

You have both the old-style `.claude/teaching-style.local.md` and the new `.flow/teach-config.yml`. The new config's `teaching_style` section takes precedence. Remove the legacy file when ready.

### Config not detected

Ensure `.flow/teach-config.yml` exists in your project root. Run `teach init` to create it, or `teach doctor` to diagnose.

### Scholar section missing

Add a `teaching_style:` or `scholar:` section to your `.flow/teach-config.yml`:

```yaml
teaching_style:
  approach: "interactive"
  tone: "conversational"
  examples: true
```
