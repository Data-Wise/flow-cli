# Quick Reference: teach prompt

> AI Teaching Prompt Management with 3-Tier Resolution

## Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `teach prompt list` | `teach pr ls` | List prompts with tier indicators |
| `teach prompt show <name>` | `teach pr cat <name>` | Display in pager |
| `teach prompt edit <name>` | `teach pr ed <name>` | Create override + open editor |
| `teach prompt validate` | `teach pr val` | Check syntax & compatibility |
| `teach prompt export <name>` | `teach pr x <name>` | Render with variables |
| `teach prompt help` | `teach pr help` | Show help |

## 3-Tier Resolution

```
Priority 1 (highest): Course
  .flow/templates/prompts/<name>.md

Priority 2: User
  ~/.flow/prompts/<name>.md

Priority 3 (lowest): Plugin
  lib/templates/teaching/claude-prompts/<name>.md
```

First match wins. Course overrides User overrides Plugin.

## List Output

```
Available Teaching Prompts
─────────────────────────────────────────

  lecture-notes          [C*] Custom lecture notes for STAT 440
  revealjs-slides        [P]  RevealJS Presentation Generator
  derivations-appendix   [P]  Mathematical Derivations Appendix

Legend: [C] Course  [U] User  [P] Plugin  * = overrides lower tier
```

## Flags

### list

| Flag | Description |
|------|-------------|
| `--tier TIER` | Filter by tier (course, user, plugin) |
| `--json`, `-j` | Output as JSON |
| `--verbose`, `-v` | Show file paths |

### show

| Flag | Description |
|------|-------------|
| `--raw`, `-r` | Output without pager |
| `--tier TIER` | Force specific tier |

### edit

| Flag | Description |
|------|-------------|
| `--global`, `-g` | Edit user-level (~/.flow/prompts/) |

### validate

| Flag | Description |
|------|-------------|
| `--all`, `-a` | Validate all prompts |
| `--strict`, `-s` | Treat warnings as errors |

### export

| Flag | Description |
|------|-------------|
| `--macros`, `-m` | Include LaTeX macros |
| `--json`, `-j` | Output as JSON with metadata |

## Prompt File Format

```yaml
---
template_version: "1.0"
template_type: "prompt"
template_description: "AI prompt for generating lecture notes"
scholar:
  command: "lecture"
  model: "claude-opus-4-5"
  temperature: 0.3
variables:
  required: [COURSE, TOPIC]
  optional: [WEEK, STYLE, MACROS, INSTRUCTOR, SEMESTER, DATE]
---

# Prompt Title

## Purpose
Generate content for {{COURSE}} on {{TOPIC}}...
```

## Variables

| Variable | Source | Example |
|----------|--------|---------|
| `{{COURSE}}` | teach-config.yml | STAT 440 |
| `{{TOPIC}}` | `--topic` flag | ANOVA |
| `{{WEEK}}` | `--week` flag | 5 |
| `{{STYLE}}` | `--style` flag | rigorous |
| `{{MACROS}}` | `teach macros export` | `\newcommand{\E}...` |
| `{{INSTRUCTOR}}` | teach-config.yml | Dr. Smith |
| `{{SEMESTER}}` | teach-config.yml | Spring 2026 |
| `{{DATE}}` | Auto-filled | 2026-01-29 |

## Validation Rules

### Errors (block usage)

1. File exists and is readable
2. YAML frontmatter present (`---` delimiters)
3. `template_type` equals `"prompt"`
4. `template_version` present
5. Variable patterns use `UPPERCASE_UNDERSCORE` only

### Warnings (informational)

1. `template_description` present and non-empty
2. `scholar.command` maps to known Scholar command
3. Body has at least one `##` heading
4. Body is at least 100 characters

## Workflows

### Create a course override

```bash
teach prompt edit lecture-notes
# Creates .flow/templates/prompts/lecture-notes.md from plugin default
# Opens in $EDITOR
```

### Validate all prompts

```bash
teach prompt validate
# Checks all prompts across all tiers
```

### Export rendered prompt

```bash
teach prompt export lecture-notes --macros
# Renders with variables from teach-config.yml + LaTeX macros
```

### Scholar auto-resolve

```bash
teach lecture "ANOVA"
# Automatically resolves lecture-notes prompt
# Renders with topic, course, macros
# Passes to Scholar as --prompt flag
```

## Related

- `teach macros` - LaTeX macro management
- `teach templates` - Content template management
- `teach plan` - Lesson plan management
- Scholar plugin - AI content generation

---

*v5.23.0 - teach prompt command*
