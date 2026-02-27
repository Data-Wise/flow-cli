---
tags:
  - reference
  - teaching
  - scholar
---

# Quick Reference: Scholar Wrapper Commands

**Purpose:** Reference card for Scholar-powered `teach` subcommands
**Version:** v7.6.0+
**Last Updated:** 2026-02-27

---

## Content Generation Wrappers

All wrappers invoke the Scholar plugin via `claude /teaching:<command>`. Config is auto-injected from `.flow/teach-config.yml` when present.

| Command | Shortcut | Scholar Skill | Description |
|---------|----------|---------------|-------------|
| `teach lecture` | `lec` | `/teaching:lecture` | Generate lecture notes |
| `teach slides` | `sl` | `/teaching:slides` | Generate slide deck |
| `teach exam` | `e` | `/teaching:exam` | Generate exam with rubric |
| `teach quiz` | `q` | `/teaching:quiz` | Generate quiz questions |
| `teach assignment` | `hw` | `/teaching:assignment` | Generate homework |
| `teach syllabus` | `syl` | `/teaching:syllabus` | Generate course syllabus |
| `teach rubric` | `rb` | `/teaching:rubric` | Generate grading rubric |
| `teach feedback` | `fb` | `/teaching:feedback` | Generate student feedback |
| `teach solution` | `sol` | `/teaching:solution` | Generate solution key |
| `teach demo` | — | `/teaching:demo` | Create demo course |

---

## New in v7.6.0

### `teach solution <topic>`

Generate a standalone solution key for any topic.

```bash
# Generate solution key
teach solution "Bayesian inference"
teach sol "Chapter 5 problems"

# With config override
teach solution "Linear regression" --config custom.yml
```

**How it works:** Invokes Scholar's `/teaching:solution` skill with the topic argument. Config is auto-injected. Output goes to the course's solutions directory.

### `teach sync`

Sync local config to Scholar's expected format.

```bash
# Sync config
teach sync

# Check what would change first
teach config diff
teach sync
```

**When to use:** After manually editing `.flow/teach-config.yml`, run `teach sync` to ensure Scholar sees your changes in the right format.

### `teach validate-r`

Validate R code chunks in `.qmd` files.

```bash
# Validate all .qmd files
teach validate-r
teach vr              # shortcut

# Output:
# ✅ lectures/week-01.qmd — 3 R chunks, all valid
# ⚠️ lectures/week-05.qmd — chunk 2: undefined variable 'dat'
# ✅ assignments/hw3.qmd — 5 R chunks, all valid
```

**What it checks:**

- R syntax errors in code chunks
- Undefined variables (basic scope analysis)
- Missing library() calls
- Common R pitfalls (= vs <-, T/F vs TRUE/FALSE)

---

## Config Auto-Injection

All wrapper commands automatically append `--config <path>` when `.flow/teach-config.yml` exists:

```
teach exam "Midterm"
  ↓ internally becomes:
claude /teaching:exam "Midterm" --config "/path/to/.flow/teach-config.yml"
```

### Config Management

| Command | Description |
|---------|-------------|
| `teach config check` | Validate config strictly |
| `teach config diff` | Compare your prompts vs Scholar defaults |
| `teach config show` | Show resolved 4-layer config |
| `teach config scaffold` | Copy default prompts for customization |

### Config Resolution Order

1. **Scholar defaults** — Built-in prompt templates
2. **Project config** — `.flow/teach-config.yml`
3. **User config** — `~/.config/scholar/config.yml`
4. **CLI overrides** — `--config`, `--style` flags

---

## Doctor Integration

`teach doctor` (quick mode) checks Scholar config as the 5th category:

```
✅ Scholar Config  Auto-injection enabled, config current
```

Checks:

- Config file exists at `.flow/teach-config.yml`
- `teaching_style:` or `scholar:` section present
- Config not stale (no changes since last Scholar run)
- No legacy `.claude/teaching-style.local.md` conflict

---

## Common Workflows

### First-Time Setup

```bash
teach init "STAT 440"        # Creates .flow/teach-config.yml
teach config scaffold        # Copy default prompts
teach config check           # Validate
teach doctor                 # Verify 5/5 green
```

### Generate Exam with Custom Style

```bash
teach config edit            # Customize prompts
teach config check           # Validate changes
teach sync                   # Ensure Scholar sees updates
teach exam "Midterm 1"       # Generate with custom config
```

### Validate Before Deploy

```bash
teach validate-r             # Check R code
teach validate               # Check .qmd structure
teach config check           # Check config
teach deploy --direct        # Deploy to gh-pages
```

---

**See also:** [Scholar Integration Guide](../guides/SCHOLAR-INTEGRATION-GUIDE.md) | [Teach Dispatcher Guide](MASTER-DISPATCHER-GUIDE.md#teaching-teach) | [Config Schema](TEACH-CONFIG-SCHEMA.md)
