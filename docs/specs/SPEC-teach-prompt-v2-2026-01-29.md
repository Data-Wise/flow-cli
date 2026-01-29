# SPEC: teach prompt Command v2

**Status:** approved
**Created:** 2026-01-29
**Supersedes:** SPEC-teach-prompt-command-2026-01-21.md
**Target Version:** v5.23.0
**From Brainstorm:** Session 2026-01-29 (`/brainstorm max feat save`)

---

## Overview

Add `teach prompt` subcommand to the teach dispatcher for managing AI teaching prompts with 3-tier resolution and Scholar plugin coordination. Prompts guide Scholar's content generation for lectures, exams, slides, etc.

---

## User Stories

### Primary: Manage Teaching Prompts

**As a** statistics instructor using flow-cli,
**I want to** manage and customize AI teaching prompts from the command line,
**So that** I can control how Scholar generates course content.

**Acceptance Criteria:**
- [ ] `teach prompt list` shows all prompts with tier indicators [C]/[U]/[P]
- [ ] `teach prompt show <name>` displays prompt in pager
- [ ] `teach prompt edit <name>` creates course override and opens editor
- [ ] `teach prompt validate` checks syntax and Scholar compatibility
- [ ] `teach prompt export <name>` renders variables from teach-config.yml
- [ ] `teach prompt help` shows formatted help
- [ ] Tab completion works for prompt names and subcommands

### Secondary: Auto-Resolve in Scholar Wrapper

**As a** instructor generating content,
**I want** prompts to automatically resolve for every Scholar call,
**So that** `teach lecture "ANOVA"` uses the right prompt without extra flags.

**Acceptance Criteria:**
- [ ] `_teach_scholar_wrapper()` auto-resolves matching prompt
- [ ] Course overrides take precedence over plugin defaults
- [ ] Missing prompts degrade gracefully (Scholar uses its own defaults)
- [ ] Existing workflows work unchanged

---

## Architecture

### 3-Tier Prompt Resolution

```
Priority 1 (highest): Course-specific
  .flow/templates/prompts/<name>.md

Priority 2: User defaults
  ~/.flow/prompts/<name>.md

Priority 3 (lowest): Plugin defaults
  lib/templates/teaching/claude-prompts/<name>.md
```

Resolution rule: First match wins.

### Integration with Scholar

```
teach lecture "ANOVA"
  -> _teach_scholar_wrapper("lecture", ...)
    -> _teach_resolve_prompt("lecture")
      -> Found: .flow/templates/prompts/lecture.md (or fallback)
    -> _teach_render_prompt(resolved_path)
      -> Substitute {{COURSE}}, {{TOPIC}}, {{MACROS}} from teach-config.yml
    -> scholar_cmd += --prompt "$rendered"
  -> Scholar merges with 4-layer style system
  -> Content generated
```

### Prompt File Format

```yaml
---
template_version: "1.0"
template_type: "prompt"
template_description: "AI prompt for generating comprehensive lecture notes"
scholar:
  command: "lecture"
  model: "claude-opus-4-5"
  temperature: 0.3
variables:
  required: [COURSE, TOPIC]
  optional: [WEEK, STYLE, MACROS, INSTRUCTOR, SEMESTER, DATE]
---

# Comprehensive Lecture Notes Generator

## Purpose
Generate instructor-facing lecture notes for {{COURSE}} ...

## Structure Requirements
...
```

---

## Command Interface

### MVP Subcommands (Phase 1)

| Command | Args | Flags | Description |
|---------|------|-------|-------------|
| `teach prompt list` | none | `--tier`, `--json`, `--verbose` | List prompts with tier indicators |
| `teach prompt show <name>` | prompt name | `--raw`, `--tier` | Display in $PAGER |
| `teach prompt edit <name>` | prompt name | `--global` | Open in $EDITOR (auto-creates override) |
| `teach prompt validate [name]` | optional | `--all`, `--strict` | Syntax + Scholar compatibility |
| `teach prompt export <name>` | prompt name | `--macros`, `--json` | Render with resolved variables |
| `teach prompt help` | none | none | Show formatted help |

### Aliases

| Alias | Expands to |
|-------|------------|
| `teach pr` | `teach prompt` |
| `teach prompt ls` | `teach prompt list` |
| `teach prompt cat` | `teach prompt show` |
| `teach prompt ed` | `teach prompt edit` |
| `teach prompt val` | `teach prompt validate` |
| `teach prompt x` | `teach prompt export` |

### Deferred (Phase 2)

| Command | Description |
|---------|-------------|
| `teach prompt create <name>` | Create new prompt from scratch or template |
| `teach prompt diff <name>` | Compare override against default |
| `teach prompt promote <name>` | Copy course prompt to user tier |

---

## Output Formats

### `teach prompt list`

```
Available Teaching Prompts
─────────────────────────────────────────

  lecture-notes          [C*] Comprehensive Lecture Notes Generator
  revealjs-slides        [P]  RevealJS Presentation Generator
  derivations-appendix   [P]  Mathematical Derivations Appendix

Legend: [C] Course  [U] User  [P] Plugin  * = overrides lower tier

Usage: teach prompt show <name> to view
```

### `teach prompt show <name>` (error)

```
✗ Unknown prompt: foo

Available prompts:
  lecture-notes, revealjs-slides, derivations-appendix

Run 'teach prompt list' for details
```

### `teach prompt validate`

```
Validating teaching prompts...

  ✓ lecture-notes          Valid (course override)
  ✓ revealjs-slides        Valid (plugin default)
  ⚠ derivations-appendix   Warning: missing template_description
  ✗ custom-broken          Error: invalid YAML frontmatter

3 valid, 1 warning, 1 error
```

---

## Variable Substitution

| Variable | Source | Example |
|----------|--------|---------|
| `{{COURSE}}` | `course.name` in teach-config.yml | STAT 440 |
| `{{TOPIC}}` | `--topic` flag or lesson plan | ANOVA |
| `{{WEEK}}` | `--week` flag | 5 |
| `{{STYLE}}` | `--style` flag or lesson plan | rigorous |
| `{{MACROS}}` | LaTeX macros via `teach macros export` | `\newcommand{\E}...` |
| `{{INSTRUCTOR}}` | `course.instructor` | Dr. Smith |
| `{{SEMESTER}}` | `course.semester` | Spring 2026 |
| `{{DATE}}` | Auto-filled | 2026-01-29 |

---

## Validation Rules

### Errors (block usage)

1. File exists and is readable
2. YAML frontmatter present (between `---` delimiters)
3. `template_type` equals `"prompt"`
4. `template_version` present
5. All `{{VAR}}` patterns use uppercase + underscores only

### Warnings (informational)

1. `template_description` present and non-empty
2. `scholar.command` maps to known Scholar command
3. All body variables listed in `variables.required` or `variables.optional`
4. Prompt body has at least one `##` heading
5. Prompt body is at least 100 characters

---

## Implementation

### New Files

| File | Purpose | Lines |
|------|---------|-------|
| `lib/prompt-helpers.zsh` | 3-tier resolution, rendering, validation | ~300 |
| `commands/teach-prompt.zsh` | Command implementation (5 subcommands) | ~450 |
| `tests/test-teach-prompt-unit.zsh` | Unit tests | ~300 |
| `docs/reference/REFCARD-PROMPTS.md` | Quick reference | ~200 |
| `docs/tutorials/28-teach-prompt.md` | Tutorial | ~300 |

### Modified Files

| File | Change |
|------|--------|
| `lib/dispatchers/teach-dispatcher.zsh` | Source guard + `prompt\|pr)` case + help entry + Scholar wrapper auto-resolve |
| `completions/_teach` | Prompt subcommand completions |
| `CHANGELOG.md` | Release notes |
| `CLAUDE.md` | Version reference update |

### Function Signatures

```zsh
# lib/prompt-helpers.zsh
_teach_resolve_prompt()          # $1=name, $2=tier(optional) -> path
_teach_get_all_prompts()         # -> "name|tier|path|description" lines
_teach_prompt_tier()             # $1=path -> "course"|"user"|"plugin"
_teach_prompt_has_override()     # $1=name -> 0|1
_teach_render_prompt()           # $1=path -> rendered content
_teach_validate_prompt_file()    # $1=path -> 0|1 with messages

# commands/teach-prompt.zsh
_teach_prompt()                  # Main dispatcher
_teach_prompt_list()             # List with tier indicators
_teach_prompt_show()             # $1=name -> display in pager
_teach_prompt_edit()             # $1=name -> create override, open editor
_teach_prompt_validate()         # [name] -> validation report
_teach_prompt_export()           # $1=name -> rendered output
_teach_prompt_help()             # Help text
```

### Implementation Order

1. `lib/prompt-helpers.zsh` - Resolution engine
2. `commands/teach-prompt.zsh` - Command layer
3. `teach-dispatcher.zsh` - Routing + Scholar integration
4. `completions/_teach` - Tab completion
5. `tests/test-teach-prompt-unit.zsh` - Tests
6. Documentation files

---

## Dependencies

| Dependency | Type | Purpose |
|------------|------|---------|
| `lib/core.zsh` | Internal | Logging, colors, FLOW_COLORS |
| `lib/template-helpers.zsh` | Internal | Metadata parsing, variable substitution |
| `lib/macro-parser.zsh` | Internal | LaTeX macro export (for {{MACROS}}) |
| `$PAGER` / `less` | External | Display prompt content |
| `$EDITOR` / `vi` | External | Edit prompt files |
| `yq` (optional) | External | YAML parsing for teach-config.yml |

---

## Testing

### Unit Tests (~40 tests)

| Category | Tests | Description |
|----------|-------|-------------|
| Resolution | 10 | 3-tier precedence, missing prompts, forced tier |
| Rendering | 8 | Variable substitution, macro injection, missing vars |
| Validation | 10 | Valid/invalid frontmatter, unknown vars, warnings |
| List/Show | 6 | Output format, tier indicators, error handling |
| Edit | 4 | Override creation, directory creation, editor launch |
| Export | 4 | Rendered output, JSON mode, macro inclusion |

### Verification Steps

1. `source flow.plugin.zsh && teach prompt help`
2. `teach prompt list` shows 3 existing [P] prompts
3. `teach prompt show lecture-notes` opens in pager
4. `teach prompt edit lecture-notes` creates course override
5. `teach prompt list` shows [C*] after edit
6. `teach prompt validate` reports all valid
7. `teach prompt export lecture-notes` renders variables
8. `teach lecture "ANOVA"` auto-resolves prompt
9. `./tests/test-teach-prompt-unit.zsh` all pass

---

## Backward Compatibility

- Existing `teach lecture/exam/quiz/...` commands work unchanged
- Missing prompts degrade gracefully (Scholar uses its own defaults)
- Existing 3 prompt files in `lib/templates/teaching/claude-prompts/` work as-is
- No changes to teach-config.yml format required

---

## Open Questions (Resolved)

| Question | Decision | Rationale |
|----------|----------|-----------|
| Override directory? | `.flow/templates/prompts/` | Reuses existing template infrastructure |
| MVP scope? | 5 subcommands | list, show, edit, validate, export |
| Scholar integration? | Auto-resolve | Zero friction, prompts "just work" |
| Spec approach? | New versioned spec | Preserves original for reference |

---

## History

| Date | Change |
|------|--------|
| 2026-01-21 | Original spec (draft, list/show/help only) |
| 2026-01-21 | Scholar coordination brainstorm |
| 2026-01-29 | v2 spec: 3-tier resolution, 5 subcommands, auto-resolve, Scholar integration |

---

## Related

- **Original spec:** `docs/specs/SPEC-teach-prompt-command-2026-01-21.md`
- **Scholar coordination:** `docs/specs/BRAINSTORM-scholar-coordination-2026-01-21.md`
- **Template system:** `commands/teach-templates.zsh`
- **Macro system:** `commands/teach-macros.zsh`
- **Scholar plugin:** `/opt/homebrew/opt/scholar/libexec/`
