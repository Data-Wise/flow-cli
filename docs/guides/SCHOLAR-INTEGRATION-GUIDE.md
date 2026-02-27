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

### Config injection not working

Check these in order:

1. **File exists?** — `ls .flow/teach-config.yml`
2. **Valid YAML?** — `yq '.' .flow/teach-config.yml`
3. **Doctor sees it?** — `teach doctor` (look for Scholar Config line)
4. **Function loaded?** — `which _teach_find_config` (should show function body)

---

## Config Layer Resolution

Scholar resolves configuration in 4 layers (later layers override earlier):

```text
Layer 1: Scholar built-in defaults
    ↓ overridden by
Layer 2: Project config (.flow/teach-config.yml)
    ↓ overridden by
Layer 3: User config (~/.config/scholar/config.yml)
    ↓ overridden by
Layer 4: CLI flags (--config, --style, --format)
```

### Viewing resolved config

```bash
# Show what Scholar actually sees (all 4 layers merged)
teach config show

# Output:
#   teaching_style:
#     approach: interactive     ← from project config
#     tone: conversational      ← from project config
#     examples: true            ← from Scholar defaults
#   exam:
#     format: pdf               ← from user config
#     difficulty: mixed         ← from Scholar defaults
```

### Comparing against defaults

```bash
# See what you've customized
teach config diff

# Output:
#   teaching_style.approach:
#     Default: "standard"
#     Yours:   "interactive"
#   teaching_style.tone:
#     Default: "formal"
#     Yours:   "conversational"
```

---

## Wrapper Commands Reference

All Scholar wrappers are thin `teach` subcommands that invoke Scholar skills:

| Command | Shortcut | What it generates |
|---------|----------|-------------------|
| `teach lecture <topic>` | `lec` | Lecture notes with examples |
| `teach slides <topic>` | `sl` | Slide deck (Quarto reveal.js) |
| `teach exam <topic>` | `e` | Exam with rubric and key |
| `teach quiz <topic>` | `q` | Quiz questions |
| `teach assignment <topic>` | `hw` | Homework with rubric |
| `teach syllabus` | `syl` | Full course syllabus |
| `teach rubric <topic>` | `rb` | Standalone grading rubric |
| `teach feedback <topic>` | `fb` | Student feedback template |
| `teach solution <topic>` | `sol` | Solution key (v7.6.0) |
| `teach demo` | — | Demo course scaffolding |

### New in v7.6.0

**`teach solution`** — Generates a standalone solution key for any topic:

```bash
teach solution "Bayesian inference"
teach sol "HW4 problems"
```

**`teach sync`** — Syncs local config edits to Scholar's expected format:

```bash
teach sync   # Run after editing .flow/teach-config.yml
```

**`teach validate-r`** — Validates R code chunks in `.qmd` files before deploy:

```bash
teach validate-r   # or: teach vr
# Checks: syntax errors, undefined vars, missing library() calls
```

---

## End-to-End Workflow

### New Course Setup

```bash
# 1. Initialize
teach init "STAT 440"

# 2. Customize config
teach config scaffold exam        # Copy exam prompt for editing
teach config edit                 # Customize in $EDITOR

# 3. Validate
teach config check
teach doctor

# 4. Generate content
teach syllabus
teach lecture "Introduction"
teach exam "Midterm 1"
teach solution "Midterm 1"

# 5. Validate and deploy
teach validate-r
teach deploy --direct
```

### Mid-Semester Content Update

```bash
# 1. Edit config if needed
teach config edit
teach sync

# 2. Generate new content
teach lecture "Week 8: ANOVA"
teach quiz "Chapter 8"

# 3. Check and deploy
teach validate-r
teach config check
teach deploy --direct
```

---

**See also:** [Scholar Wrappers Refcard](../reference/REFCARD-SCHOLAR-WRAPPERS.md) | [Teach Dispatcher](../reference/MASTER-DISPATCHER-GUIDE.md#teach-dispatcher) | [Config Schema](../reference/TEACH-CONFIG-SCHEMA.md)
