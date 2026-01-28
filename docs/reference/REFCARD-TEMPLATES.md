# Template Quick Reference Card

> Quick reference for `teach templates` command (v5.20.0+)

## Commands

| Command | Description |
|---------|-------------|
| `teach templates` | List all available templates |
| `teach templates list` | List with filtering options |
| `teach templates new <type> <dest>` | Create file from template |
| `teach templates validate` | Check template syntax |
| `teach templates sync` | Update from plugin defaults |
| `teach templates help` | Show help |

## Shortcuts

- `teach tmpl` → `teach templates`
- `teach tpl` → `teach templates`

## Template Types

| Type | Directory | Purpose |
|------|-----------|---------|
| `content` | `.flow/templates/content/` | .qmd starters |
| `prompts` | `.flow/templates/prompts/` | AI generation prompts |
| `metadata` | `.flow/templates/metadata/` | _metadata.yml files |
| `checklists` | `.flow/templates/checklists/` | QA checklists |

## Quick Examples

```bash
# List all templates
teach templates

# List only content templates
teach templates list --type content

# Create new lecture from template
teach templates new lecture week-05

# Create lab with topic
teach templates new lab week-03 --topic "ANOVA"

# Preview sync without changes
teach templates sync --dry-run

# Validate all project templates
teach templates validate
```

## Variable Substitution

Templates use `{{VARIABLE}}` syntax:

| Variable | Source | Example |
|----------|--------|---------|
| `{{WEEK}}` | CLI arg or prompt | `05` |
| `{{TOPIC}}` | CLI arg or prompt | `Linear Regression` |
| `{{COURSE}}` | teach-config.yml | `STAT-545` |
| `{{DATE}}` | Auto-generated | `2026-01-28` |
| `{{INSTRUCTOR}}` | teach-config.yml | `Dr. Smith` |
| `{{SEMESTER}}` | teach-config.yml | `Spring 2026` |

## Template Metadata

All templates include YAML frontmatter:

```yaml
---
template_version: "1.0"
template_type: "lecture"
template_description: "Standard lecture template"
template_variables: [WEEK, TOPIC, COURSE, DATE]
---
```

## Resolution Order

1. **Project** (`.flow/templates/`) - highest priority
2. **Plugin** (`lib/templates/teaching/`) - fallback

Project templates override plugin defaults.

## Initialization

```bash
# Create course with templates
teach init "STAT 545" --with-templates

# Add templates to existing course
teach templates sync
```

## Default Templates

### Content
- `lecture.qmd` - Standard lecture with concepts
- `lab.qmd` - R lab exercise with scaffolding
- `slides.qmd` - RevealJS presentations
- `assignment.qmd` - Homework template

### Prompts (for Scholar AI)
- `lecture-notes.md` - Lecture generation prompt
- `revealjs-slides.md` - Slides generation prompt
- `derivations-appendix.md` - Math appendix prompt

### Metadata
- `lectures.yml` - Lecture directory defaults
- `labs.yml` - Lab directory defaults
- `slides.yml` - Slides directory defaults

### Checklists
- `pre-publish.md` - Pre-deploy QA checklist
- `new-content.md` - New content creation checklist

## Flags Reference

| Flag | Commands | Description |
|------|----------|-------------|
| `--type TYPE` | list | Filter by template type |
| `--source SOURCE` | list | Filter: project, plugin, all |
| `--json` | list | Output as JSON |
| `--dry-run, -n` | new, sync | Preview without changes |
| `--force, -f` | new, sync | Overwrite existing |
| `--week N` | new | Pre-fill week variable |
| `--topic "..."` | new | Pre-fill topic variable |
| `--backup` | sync | Create .bak files (default) |
| `--no-backup` | sync | Skip backup creation |

## See Also

- `teach init --with-templates` - Initialize with templates
- `teach validate` - Validate .qmd files
- `teach doctor` - Health check
