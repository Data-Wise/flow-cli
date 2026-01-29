# BRAINSTORM: teach prompt Command v2 - Scholar Coordination

**Generated:** 2026-01-29
**Mode:** max feat save
**Context:** flow-cli v5.22.0 + Scholar v2.1.0

---

## Executive Summary

Design `teach prompt` command for managing AI teaching prompts with 3-tier resolution (Course > User > Plugin) and auto-resolve integration with Scholar's content generation pipeline. Extends the original draft spec with 5 MVP subcommands and Scholar wrapper auto-resolve.

---

## Exploration Findings

### Agent 1: Teach Dispatcher Analysis

- 30+ subcommands in teach dispatcher (5,873 lines)
- No `teach prompt` routing exists yet
- Scholar wrapper at `teach-dispatcher.zsh:2279` (`_teach_scholar_wrapper()`)
  - Parses `--style`, `--template`, `--context` flags
  - Builds Scholar command via `_teach_build_command()`
  - Extension points: `--instructions`, `--context`, `--template` flags
  - Adding `--prompt` follows same pattern
- Template system already wires `prompts` type:
  - `TEMPLATE_TYPE_DIRS[prompts]="prompts"` (template-helpers.zsh)
  - `TEMPLATE_PLUGIN_PATHS[prompts]="claude-prompts"` (maps to plugin dir)
- 3 existing prompt files: `lecture-notes.md`, `revealjs-slides.md`, `derivations-appendix.md`
- Existing functions to reuse:
  - `_teach_parse_template_metadata()` - YAML frontmatter parsing
  - `_teach_substitute_variables()` - `{{VAR}}` substitution
  - `_teach_extract_variables()` - Find variables in template body
  - `_teach_load_config_variables()` - Load from teach-config.yml

### Agent 2: Scholar Plugin Format

- Scholar v2.1.0 installed at `/opt/homebrew/opt/scholar/libexec/`
- **Prompt format:** YAML frontmatter + Markdown body (Handlebars-style syntax)
- **Frontmatter fields:** `prompt_version`, `prompt_type`, `prompt_description`, `target_template`, `variables.required[]`, `variables.optional[]`
- **Variable syntax:** `{{variable}}`, `{{#if condition}}...{{/if}}`, `{{#if x == "val"}}...{{/if}}`
- **4-layer style system:** Global (`~/.claude/CLAUDE.md`) > Course (`.claude/teaching-style.local.md`) > Command > Lesson Plan
- **Override location:** Scholar already checks `.flow/templates/prompts/{type}.md`
- **11 prompt types:** lecture-notes, lecture-outline, section-content, exam, quiz, slides, revealjs-slides, assignment, syllabus, rubric, feedback
- **Version checking:** Scholar validates `prompt_version` compatibility
- **PromptBuilder class:** Handles rendering with error on missing required vars

### Agent 3: Architecture Design

- Recommended 3-tier: `.flow/templates/prompts/` > `~/.flow/prompts/` > `lib/templates/teaching/claude-prompts/`
- New files: `lib/prompt-helpers.zsh` (~300 lines), `commands/teach-prompt.zsh` (~450 lines)
- Pattern follows `teach-templates.zsh` and `teach-macros.zsh` (separate command file + helper library)
- Reuse template-helpers functions where possible
- Scholar integration: render on flow-cli side, pass via `--prompt` flag

---

## Design Decisions

### Decision 1: Override Directory

**Options explored:**
- A: `.flow/templates/prompts/` - Reuses existing template dir (teach init --with-templates creates it)
- B: `.flow/prompts/` - Dedicated prompt dir (new directory creation logic)
- C: `.claude/prompts/` - In Claude Code's namespace

**Choice: A** - `.flow/templates/prompts/` reuses existing infrastructure. The template system already maps this path via `TEMPLATE_TYPE_DIRS`. Less new code, consistent with existing template management.

### Decision 2: MVP Scope

**Options explored:**
- A: Full 7 (list, show, edit, create, validate, diff, export)
- B: Core 5 (list, show, edit, validate, export) - defer create, diff
- C: Minimal 3 (list, show, help) - original spec scope

**Choice: B** - Core 5 gives usable prompt management. `create` is a convenience (can just copy files manually). `diff` is nice-to-have. All are feasible to add later.

### Decision 3: Scholar Auto-Resolve

**Options explored:**
- A: Auto-resolve every Scholar call - zero friction
- B: Explicit `--prompt` flag - more control
- C: Auto with `--no-prompt` opt-out

**Choice: A** - Auto-resolve. The whole point of the prompt system is to enhance Scholar output transparently. Missing prompts degrade gracefully. No behavioral change for users who don't customize prompts.

### Decision 4: Prompt Format

**Choice:** Keep existing format (YAML frontmatter + Markdown body). Add optional `scholar:` and `variables:` blocks to frontmatter. Backward-compatible with existing 3 prompt files.

### Decision 5: Variable Syntax

**Choice:** `{{UPPERCASE}}` for flow-cli variables (matches template-helpers convention). Scholar uses `{{lowercase}}` internally. No collision because flow-cli renders first, then passes to Scholar.

---

## Feature MVP

### User Story Map

```
teach prompt
├── list       [MVP] Browse available prompts with tier indicators
├── show       [MVP] Read prompt content in pager
├── edit       [MVP] Customize prompt (auto-creates course override)
├── validate   [MVP] Check syntax, variables, Scholar compatibility
├── export     [MVP] Render with resolved variables for debugging
├── create     [Phase 2] Create new prompt from scratch/template
├── diff       [Phase 2] Compare override against default
└── promote    [Phase 2] Copy course prompt to user tier
```

### Zero-Friction Scholar Integration

```
Before (current): teach lecture "ANOVA"
  -> Scholar uses its own defaults

After (with teach prompt): teach lecture "ANOVA"
  -> Auto-resolves matching prompt
  -> Renders variables from teach-config.yml
  -> Injects LaTeX macros if configured
  -> Passes enhanced prompt to Scholar
  -> Better, more consistent output
```

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Breaking existing Scholar calls | Graceful degradation: missing prompt = Scholar uses defaults |
| Namespace collision with `prompt` dispatcher | No collision: `prompt` = prompt-dispatcher, `teach prompt` = teach subcommand |
| Performance (filesystem scan per Scholar call) | Simple stat-based caching per session |
| Scholar prompt format changes | Version checking in frontmatter |
| teach-dispatcher.zsh is too large | Separate command file + helper library (pattern from templates/macros) |

---

## Implementation Estimate

| Phase | Scope | Files |
|-------|-------|-------|
| Phase 1: Core | Resolution + 5 subcommands + dispatcher routing | 4 files, ~800 lines |
| Phase 2: Scholar | Auto-resolve in wrapper + macro injection | +45 lines in dispatcher |
| Phase 3: Tests | Unit + integration tests | 1 file, ~300 lines |
| Phase 4: Docs | Refcard + tutorial + changelog | 3 files, ~700 lines |
| **Total** | | **~1,800 lines** |

---

## Next Steps

1. **Approve plan** -> Create worktree `feature/teach-prompt` from dev
2. **Implement** Phase 1-4 in worktree
3. **Test** with `source flow.plugin.zsh && teach prompt help`
4. **PR** to dev
5. **Release** as v5.23.0

---

## Related Specs

- [SPEC-teach-prompt-command-2026-01-21.md](SPEC-teach-prompt-command-2026-01-21.md) - Original draft (superseded)
- [BRAINSTORM-scholar-coordination-2026-01-21.md](BRAINSTORM-scholar-coordination-2026-01-21.md) - Scholar coordination strategy
- [SPEC-teach-prompt-v2-2026-01-29.md](SPEC-teach-prompt-v2-2026-01-29.md) - Implementation spec (this brainstorm's output)
