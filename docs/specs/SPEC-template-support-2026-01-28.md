# SPEC: .flow/templates/ Support (#301)

**Date:** 2026-01-28
**Issue:** https://github.com/Data-Wise/flow-cli/issues/301
**Status:** Ready for Implementation
**Effort:** ~10-12 hours (phased)
**Branch:** `feature/template-support`

---

## Executive Summary

Add support for project-local templates at `.flow/templates/` with discovery, copying, and Scholar plugin integration.

**What we're doing:**
- Add `teach templates` command with `list`, `new`, `validate`, `sync` subcommands
- Support 4 template types: content, prompts, metadata, checklists
- Implement project-overrides-plugin resolution order
- Auto-detect prompts in Scholar plugin
- Add `--with-templates` flag to `teach init`

**What we're NOT doing:**
- ❌ Remove existing `lib/templates/teaching/` structure
- ❌ Require templates for existing workflows
- ❌ Change existing `--template` flag semantics (output format)

---

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Resolution order | Project > Plugin | User customizations override defaults |
| Variable syntax | `{{VARIABLE}}` | Mustache-style, common in templates |
| Command pattern | `teach templates <action>` | Matches `teach backup <action>` pattern |
| Template init | `--with-templates` flag | Explicit opt-in, not mandatory |
| Scholar integration | Auto-detect prompts | Zero-config when templates exist |
| Metadata format | YAML frontmatter | Consistent with Quarto, no extra files |

---

## File Structure

### Project Templates (User-Customizable)

```
.flow/templates/
├── content/                    # Quarto .qmd starters
│   ├── lecture.qmd
│   ├── lab.qmd
│   ├── slides.qmd
│   └── assignment.qmd
├── prompts/                    # AI generation prompts (Scholar)
│   ├── lecture-notes.md
│   ├── revealjs-slides.md
│   └── derivations-appendix.md
├── metadata/                   # Canonical _metadata.yml templates
│   ├── labs.yml
│   ├── slides.yml
│   └── lectures.yml
└── checklists/                 # QA checklists
    ├── pre-publish.md
    └── new-content.md
```

### Plugin Templates (Defaults)

```
lib/templates/teaching/         # Already exists
├── claude-prompts/             # AI prompts (exists)
│   ├── lecture-notes.md
│   ├── revealjs-slides.md
│   └── derivations-appendix.md
├── teach-config.yml.template
├── lecture-with-concepts.qmd.template
└── ...
```

### Resolution Order

```
1. .flow/templates/<type>/<name>     # Project (highest priority)
2. lib/templates/teaching/<name>     # Plugin (fallback)
```

---

## Template Metadata Format

All templates include YAML frontmatter:

```yaml
---
template_version: "1.0"
template_type: "lecture"           # lecture|lab|slides|assignment|prompt|metadata|checklist
template_description: "Standard lecture template with concept frontmatter"
template_variables:
  - WEEK                           # Week number (auto-filled)
  - TOPIC                          # Topic name (from args or prompt)
  - COURSE                         # Course code (from teach-config.yml)
  - DATE                           # Current date (auto-filled)
  - INSTRUCTOR                     # Instructor name (from teach-config.yml)
---
```

### Variable Substitution

| Variable | Source | Example |
|----------|--------|---------|
| `{{WEEK}}` | Command argument or prompt | `05` |
| `{{TOPIC}}` | Command argument or prompt | `Linear Regression` |
| `{{COURSE}}` | `teach-config.yml` course.code | `STAT-545` |
| `{{DATE}}` | Current date | `2026-01-28` |
| `{{INSTRUCTOR}}` | `teach-config.yml` course.instructor | `Dr. Smith` |
| `{{SEMESTER}}` | `teach-config.yml` semester_info.name | `Spring 2026` |

---

## Implementation Tasks

### Phase 1: Core Commands (~6 hours)

#### Task 1: `teach templates list` (~1.5 hours)

**File:** `lib/dispatchers/teach-dispatcher.zsh`

**Functions:**
- `_teach_templates()` - Main dispatcher
- `_teach_templates_list()` - List templates from both sources
- `_teach_get_template_sources()` - Find project + plugin templates
- `_teach_parse_template_metadata()` - Extract YAML frontmatter

**Command:**
```bash
teach templates                    # Alias for 'teach templates list'
teach templates list               # List all templates
teach templates list --type content   # Filter by type
teach templates list --source project # Show only project templates
```

**Output:**
```
┌──────────────────────────────────────────────────────────────┐
│ 📁 Teaching Templates                                        │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│ CONTENT (.flow/templates/content/)                           │
│   lecture.qmd      v1.0  Standard lecture with concepts      │
│   lab.qmd          v1.0  R lab exercise template         [P] │
│   slides.qmd       v1.0  RevealJS slides template            │
│                                                              │
│ PROMPTS (.flow/templates/prompts/)                           │
│   lecture-notes.md    v1.0  AI lecture notes generator       │
│   revealjs-slides.md  v1.0  AI slides generator          [D] │
│                                                              │
│ Legend: [P] = Project, [D] = Default (plugin)                │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

**Flags:**
- `--type TYPE` - Filter by type: content, prompts, metadata, checklists
- `--source SOURCE` - Filter by source: project, plugin, all (default)
- `--json` - Output as JSON for scripting

---

#### Task 2: `teach templates new` (~2 hours)

**Functions:**
- `_teach_templates_new()` - Copy template with variable substitution
- `_teach_resolve_template()` - Find template (project > plugin)
- `_teach_substitute_variables()` - Replace `{{VAR}}` placeholders
- `_teach_prompt_for_variables()` - Interactive prompt for missing vars

**Command:**
```bash
teach templates new lecture week-05              # → lectures/week-05/lecture.qmd
teach templates new lab week-03                  # → labs/week-03/lab.qmd
teach templates new slides "ANOVA" --week 6      # → slides/week-06/slides-anova.qmd
teach templates new assignment "Homework 1"      # → assignments/homework-1.qmd
```

**UX Flow:**
```bash
$ teach templates new lecture week-05

📄 Creating lecture from template...

Template: lecture.qmd (v1.0)
Source:   .flow/templates/content/lecture.qmd

Variables:
  {{WEEK}}    → 05 (from argument)
  {{TOPIC}}   → [Enter topic]: Linear Regression
  {{COURSE}}  → STAT-545 (from config)
  {{DATE}}    → 2026-01-28

Preview:
  lectures/week-05/lecture-05-linear-regression.qmd

✓ Created: lectures/week-05/lecture-05-linear-regression.qmd
```

**Flags:**
- `--dry-run` - Preview without creating file
- `--force` - Overwrite existing file
- `--topic "Topic"` - Pre-fill topic variable
- `--week N` - Pre-fill week variable

**Destination Mapping:**

| Template Type | Default Destination |
|---------------|---------------------|
| `lecture` | `lectures/week-{{WEEK}}/lecture-{{WEEK}}-{{TOPIC_SLUG}}.qmd` |
| `lab` | `labs/week-{{WEEK}}/lab-{{WEEK}}-{{TOPIC_SLUG}}.qmd` |
| `slides` | `slides/week-{{WEEK}}/slides-{{WEEK}}-{{TOPIC_SLUG}}.qmd` |
| `assignment` | `assignments/{{TOPIC_SLUG}}.qmd` |

---

#### Task 3: `teach templates validate` (~1 hour)

**Functions:**
- `_teach_templates_validate()` - Check all templates
- `_teach_validate_template_metadata()` - Verify frontmatter
- `_teach_validate_template_variables()` - Check variable syntax

**Command:**
```bash
teach templates validate                 # Validate all project templates
teach templates validate lecture.qmd     # Validate specific template
```

**Output:**
```
┌──────────────────────────────────────────────────────────────┐
│ 🔍 Template Validation                                       │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│ content/lecture.qmd                                          │
│   ✓ Valid YAML frontmatter                                   │
│   ✓ template_version present (1.0)                           │
│   ✓ template_type matches directory (lecture)                │
│   ✓ Variables documented: WEEK, TOPIC, COURSE, DATE          │
│                                                              │
│ content/lab.qmd                                              │
│   ✓ Valid YAML frontmatter                                   │
│   ⚠ Undocumented variable: {{DIFFICULTY}}                    │
│                                                              │
│ Summary: 4 templates, 3 valid, 1 warning                     │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

#### Task 4: `teach templates sync` (~1.5 hours)

**Functions:**
- `_teach_templates_sync()` - Sync from plugin defaults
- `_teach_compare_template_versions()` - Check for updates
- `_teach_sync_template()` - Copy with backup

**Command:**
```bash
teach templates sync                     # Sync all from plugin
teach templates sync --dry-run           # Preview what would change
teach templates sync lecture.qmd         # Sync specific template
```

**UX Flow:**
```bash
$ teach templates sync --dry-run

📥 Template Sync Preview

Would update:
  content/lecture.qmd     v1.0 → v1.1 (plugin has newer)
  prompts/revealjs.md     (new in plugin)

Would skip:
  content/lab.qmd         v1.0 = v1.0 (same version)
  content/slides.qmd      v1.2 > v1.0 (project is newer)

Run without --dry-run to apply changes.
```

**Flags:**
- `--dry-run` - Preview without changes
- `--force` - Overwrite even if project version is newer
- `--backup` - Create .bak files before overwriting (default: true)

---

### Phase 2: Integration (~4-6 hours)

#### Task 5: Update `teach init --with-templates` (~1.5 hours)

**File:** `lib/dispatchers/teach-dispatcher.zsh` (modify `_teach_init`)

**Changes:**
- Add `--with-templates` flag
- Create `.flow/templates/` directory structure
- Copy default templates from plugin
- Show summary of created templates

**Command:**
```bash
teach init "STAT 545" --with-templates    # Create course with templates
teach init --with-templates               # Add templates to existing course
```

**UX Flow:**
```bash
$ teach init "STAT 545" --with-templates

📦 Initializing teaching course...

Course: STAT 545
  ✓ Created .flow/teach-config.yml

Templates:
  ✓ Created .flow/templates/content/ (4 templates)
  ✓ Created .flow/templates/prompts/ (3 templates)
  ✓ Created .flow/templates/metadata/ (3 templates)
  ✓ Created .flow/templates/checklists/ (2 templates)

✓ Initialization complete!

Next steps:
  teach templates list              # View available templates
  teach templates new lecture week-01   # Create first lecture
```

---

#### Task 6: Scholar Plugin Auto-Detection (~2 hours)

**File:** Scholar plugin (external - document interface only)

**Interface Specification:**

Scholar should check for local prompts before using defaults:

```python
def get_prompt(prompt_type: str, course_dir: str) -> str:
    """
    Resolution order:
    1. .flow/templates/prompts/{prompt_type}.md
    2. Plugin default prompts
    """
    local_prompt = Path(course_dir) / ".flow/templates/prompts" / f"{prompt_type}.md"
    if local_prompt.exists():
        return local_prompt.read_text()
    return get_default_prompt(prompt_type)
```

**Prompt Types:**
- `lecture-notes` → `lecture-notes.md`
- `revealjs-slides` → `revealjs-slides.md`
- `derivations-appendix` → `derivations-appendix.md`

**Documentation:** Update Scholar README with local prompt support.

---

#### Task 7: Help System Update (~1 hour)

**Functions:**
- `_teach_templates_help()` - Main help for templates command
- Update `_teach_main_help()` to include templates

**Help Output:**
```
┌──────────────────────────────────────────────────────────────┐
│ teach templates - Template Management                        │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│ USAGE                                                        │
│   teach templates [action] [options]                         │
│                                                              │
│ ACTIONS                                                      │
│   list [--type TYPE]        List available templates         │
│   new <type> <dest>         Create file from template        │
│   validate [file]           Check template syntax            │
│   sync [--dry-run]          Update from plugin defaults      │
│   help                      Show this help                   │
│                                                              │
│ TEMPLATE TYPES                                               │
│   content     .qmd starters (lecture, lab, slides, assignment)│
│   prompts     AI generation prompts (for Scholar)            │
│   metadata    _metadata.yml templates                        │
│   checklists  QA checklists                                  │
│                                                              │
│ EXAMPLES                                                     │
│   teach templates                      # List all            │
│   teach templates new lecture week-05  # Create lecture      │
│   teach templates sync --dry-run       # Preview sync        │
│                                                              │
│ FILES                                                        │
│   .flow/templates/          Project templates (priority)     │
│   lib/templates/teaching/   Plugin defaults (fallback)       │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## Testing Plan

### Unit Tests (~30 tests)

**File:** `tests/test-teach-templates.zsh`

```bash
# Template discovery
test_templates_list_empty_project
test_templates_list_project_only
test_templates_list_plugin_fallback
test_templates_list_project_overrides_plugin
test_templates_list_filter_by_type

# Template creation
test_templates_new_creates_file
test_templates_new_substitutes_variables
test_templates_new_prompts_for_missing_vars
test_templates_new_dry_run
test_templates_new_respects_destination_mapping

# Template validation
test_templates_validate_valid_template
test_templates_validate_missing_metadata
test_templates_validate_undocumented_variable

# Template sync
test_templates_sync_creates_directory
test_templates_sync_dry_run
test_templates_sync_skips_newer_project
test_templates_sync_creates_backup
```

### Integration Tests

```bash
# Full workflow
test_init_with_templates_creates_structure
test_new_lecture_then_edit_workflow
test_scholar_uses_local_prompt
```

---

## Migration Path

### Existing Courses

No changes required. Templates are opt-in:

```bash
# Add templates to existing course
teach init --with-templates

# Or manually create structure
mkdir -p .flow/templates/{content,prompts,metadata,checklists}
teach templates sync
```

### stat-545 Course

The stat-545 course already has `.flow/templates/`. This spec formalizes that structure:

1. Verify existing templates match spec format
2. Add `template_version` metadata if missing
3. Test `teach templates list` shows existing templates

---

## Future Enhancements (Out of Scope)

- Template inheritance (extend base templates)
- Template variables from environment
- Custom destination patterns in config
- Template marketplace (share templates)
- Version migration scripts

---

## Related Issues

- #298 - Lesson plan extraction (uses same `.flow/` directory)
- Scholar plugin - Prompt integration (external dependency)

---

## Appendix: Default Templates

### content/lecture.qmd

```yaml
---
template_version: "1.0"
template_type: "lecture"
template_description: "Standard lecture template with concept frontmatter"
template_variables: [WEEK, TOPIC, COURSE, DATE, INSTRUCTOR]
---
---
title: "Week {{WEEK}}: {{TOPIC}}"
subtitle: "{{COURSE}} - {{SEMESTER}}"
author: "{{INSTRUCTOR}}"
date: "{{DATE}}"
format:
  html:
    toc: true
    code-fold: true
concepts:
  - id: ""
    name: ""
    prerequisites: []
---

## Learning Objectives

By the end of this lecture, students will be able to:

1.
2.
3.

## Introduction

## Main Content

## Summary

## Next Steps
```

### prompts/lecture-notes.md

```yaml
---
template_version: "1.0"
template_type: "prompt"
template_description: "AI prompt for generating lecture notes"
---

You are an expert instructor creating lecture notes for {{COURSE}}.

Topic: {{TOPIC}}
Week: {{WEEK}}
Level: {{DIFFICULTY}}

Generate comprehensive lecture notes that:
1. Start with clear learning objectives
2. Include mathematical derivations where appropriate
3. Provide R code examples
4. End with practice problems

Use Quarto markdown format with proper YAML frontmatter.
```

---

## Change Log

| Date | Author | Change |
|------|--------|--------|
| 2026-01-28 | Claude | Initial spec from brainstorm |
