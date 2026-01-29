# SPEC: Teach Dispatcher Scholar Enhancement

**Feature:** Comprehensive teach dispatcher enhancement with Scholar plugin integration
**Status:** Draft
**Created:** 2026-01-17
**From Brainstorm:** Deep interactive sessions (merged from 2 specs)
**Target Release:** flow-cli v5.13.0
**Estimated Effort:** 20-24 hours across 6 phases

---

## Metadata

| Field               | Value                                              |
| ------------------- | -------------------------------------------------- |
| **Status**          | Draft                                              |
| **Priority**        | High (enables 10x faster course material creation) |
| **Complexity**      | Medium-High (20-24 hours)                          |
| **Risk Level**      | Low (enhances existing teach dispatcher)           |
| **Dependencies**    | Claude Code CLI 2.1.12+, Scholar plugin, yq 4.0+   |
| **Target Users**    | Academic instructors (ADHD-friendly required)      |
| **Branch Strategy** | feature/teach-scholar-enhancement → dev → main     |

---

## Overview

Comprehensive enhancement of the `teach` dispatcher with:

1. **Smart Defaults** - Auto-detect week/topic from schedule
2. **Interactive Mode** (`-i`) - Step-by-step wizard for content generation
3. **Revision Workflow** (`--revise`) - Iterate on existing content
4. **Context Integration** (`--context`) - Include course materials as context
5. **Content Customization** - Style presets + individual content flags
6. **Topic/Week Selection** - Explicit `--topic` and `--week` flags with lesson plan support

The teach dispatcher already has solid infrastructure (config validation, post-generation hooks, git integration). This spec focuses on enhancing the AI generation experience.

---

## User Stories

### Primary Story: Minimal Friction Generation

**As an** academic instructor with ADHD
**I want to** generate teaching materials with minimal friction
**So that I** can focus on content quality rather than tooling

### Acceptance Criteria

- [ ] `teach slides -w 8` generates slides for week 8's topic
- [ ] `teach slides -i` provides step-by-step interactive wizard with style selection
- [ ] `teach slides --revise FILE` improves existing content
- [ ] `teach slides --style rigorous --no-proof` customizes content
- [ ] Progress indicators show elapsed time during generation
- [ ] Error messages provide actionable recovery steps

### Secondary Stories

**Story 2: Content Customization**

- As an instructor, I want to specify content style (conceptual, computational, rigorous, applied)
- So that generated materials match my teaching approach

**Story 3: Iterative Refinement**

- As an instructor reviewing content, I want to refine materials through revision
- So that I get content matching my teaching style

---

## Architecture

### Component Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ User: teach slides -w 8 --style computational --diagrams        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ teach-dispatcher.zsh                                            │
│ ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│ │ _teach_parse_   │  │ _teach_resolve_ │  │ _teach_inter_   │  │
│ │   args()        │→│   content()      │→│   active()      │  │
│ └─────────────────┘  └─────────────────┘  └─────────────────┘  │
│         │                    │                    │             │
│         ▼                    ▼                    ▼             │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ _teach_scholar_wrapper() [ENHANCED]                         │ │
│ │ - Flag validation (topic/week, style, content flags)        │ │
│ │ - Conflict detection                                        │ │
│ │ - Lesson plan loading                                       │ │
│ │ - Build Scholar command with content instructions           │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                              │                                  │
│                              ▼                                  │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ _teach_execute() [ENHANCED]                                 │ │
│ │ - Progress indicator with elapsed time                      │ │
│ │ - Timeout handling (120s default)                           │ │
│ │ - Structured error messages                                 │ │
│ └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ Claude Code CLI                                                 │
│ claude -p "/scholar:teaching:slides 'Regression' ..." \         │
│   --output-format text --max-budget-usd 0.50                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ Post-Generation Hooks [EXISTING]                                │
│ - Auto-stage files                                              │
│ - Update .STATUS                                                │
│ - Interactive commit workflow                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## API Design

### New Flags Summary

| Flag            | Short | Purpose                                  | Example                               |
| --------------- | ----- | ---------------------------------------- | ------------------------------------- |
| `--topic`       | `-t`  | Explicit topic (bypasses lesson plan)    | `teach slides --topic "Regression"`   |
| `--week`        | `-w`  | Week number (uses lesson plan if exists) | `teach slides -w 8`                   |
| `--style`       |       | Content style preset                     | `teach slides -w 8 --style rigorous`  |
| `--interactive` | `-i`  | Step-by-step wizard                      | `teach slides -i`                     |
| `--revise`      |       | Improve existing file                    | `teach slides --revise slides/w8.qmd` |
| `--context`     |       | Include course context                   | `teach exam "Midterm" --context`      |

### Content Flags (9 total)

| Flag                  | Short | Negation                 | Description                           |
| --------------------- | ----- | ------------------------ | ------------------------------------- |
| `--explanation`       | `-e`  | `--no-explanation`       | Conceptual explanations               |
| `--proof`             |       | `--no-proof`             | Mathematical proofs                   |
| `--math`              | `-m`  | `--no-math`              | Formal math notation                  |
| `--examples`          | `-x`  | `--no-examples`          | Worked numerical examples             |
| `--code`              | `-c`  | `--no-code`              | Code demonstrations (R/Python)        |
| `--diagrams`          | `-d`  | `--no-diagrams`          | Visual diagrams/plots (always opt-in) |
| `--practice-problems` | `-p`  | `--no-practice-problems` | Practice exercises                    |
| `--definitions`       |       | `--no-definitions`       | Formal definitions                    |
| `--references`        | `-r`  | `--no-references`        | Citations (always opt-in)             |

### Style Presets (4 total)

| Preset            | Includes                                       | Use Case                               |
| ----------------- | ---------------------------------------------- | -------------------------------------- |
| **conceptual**    | explanation, definitions, examples             | Intuition-focused, theory introduction |
| **computational** | explanation, examples, code, practice-problems | Hands-on, lab-style                    |
| **rigorous**      | definitions, explanation, math, proof          | Graduate level, formal treatment       |
| **applied**       | explanation, examples, code, practice-problems | Real-world applications                |

**Notes:**

- `diagrams` and `references` are always opt-in (never preset-included)
- Use `--no-*` to remove from preset: `--style rigorous --no-proof`

### Command Syntax Examples

```bash
# Topic/Week selection (must specify one)
teach slides --topic "Linear Regression"
teach slides -w 8

# Style presets
teach slides -w 8 --style computational
teach slides -w 8 --style rigorous --no-proof

# Individual content flags
teach slides -w 8 --explanation --examples --code
teach slides -w 8 --style conceptual --diagrams  # Add to preset

# Interactive mode
teach slides -i -w 8                    # Prompts for style
teach slides -i -w 8 --style applied    # Skips style prompt

# Revision mode
teach slides --revise slides/week08.qmd

# Context mode
teach exam "Final" --context
```

---

## Lesson Plan Integration

### Location

`.flow/lesson-plans/week-{NN}.yml`

### Schema (Standard)

```yaml
# .flow/lesson-plans/week-08.yml
week: 8
topic: "Multiple Regression"
style: computational  # Default preset for this week

# Learning objectives (required)
objectives:
  - "Understand multiple regression model assumptions"
  - "Interpret regression coefficients correctly"
  - "Perform model diagnostics in R"

# Subtopics (required)
subtopics:
  - "Model specification"
  - "Coefficient interpretation"
  - "Multicollinearity"
  - "Model diagnostics"

# Key concepts (required)
key_concepts:
  - "Partial regression coefficients"
  - "Adjusted R-squared"
  - "VIF (Variance Inflation Factor)"

# Prerequisites (optional)
prerequisites:
  - "Simple linear regression (Week 6)"
  - "Matrix notation basics (Week 7)"
```

### Fallback (From Config)

When no lesson plan file exists, fall back to `semester_info.weeks`:

```yaml
# In teach-config.yml
semester_info:
  weeks:
    - number: 8
      start_date: "2026-03-02"
      topic: "Multiple Regression"  # Used as fallback
```

### Flag Interaction Rules

1. **Must specify one:** Either `--topic` or `--week` is required
2. **--topic takes precedence:** If both given, `--week` is ignored
3. **--topic bypasses lesson plan:** Explicit topic means no lesson plan lookup
4. **--week with lesson plan:** Merges plan defaults with command flags
5. **--week without plan:** Prompts interactively "Continue with topic 'X'? [Y/n]"

---

## UI/UX Specifications

### Progress Indicator

```
⠋ Generating slides (~30s)...  12s
⠙ Generating slides (~30s)...  13s
```

### Interactive Style Selection (in `-i` mode)

```
📚 Content Style

What style should this content use?

  [1] conceptual    Explanation + definitions + examples
  [2] computational Explanation + examples + code + practice
  [3] rigorous      Definitions + explanation + math + proofs
  [4] applied       Explanation + examples + code + practice

Your choice [1-4]: _
```

### Missing Lesson Plan Prompt

```
⚠️  No lesson plan found for Week 8

Topic from config: "Multiple Regression"

Continue with this topic? [Y/n]: _

Hint: Create a lesson plan with: teach plan create 8
```

### Flag Conflict Error

```
✗ teach: Conflicting flags

  Both --proof and --no-proof specified

  These flags are mutually exclusive.

Fix:
  teach slides -w 8 --style rigorous --no-proof
                                     ^^^^^^^^^ keep one
```

### Revision Menu

```
📝 Revise: slides/week08.qmd

What would you like to improve?

  [1] Expand content        Add more detail
  [2] Add examples          Include practical examples
  [3] Simplify language     Make more accessible
  [4] Add visuals           Suggest images/diagrams
  [5] Custom instructions   Enter specific feedback
  [6] Full regenerate       Start fresh

Your choice [1-6]: _
```

### Success Message

```
✓ Created: slides/week08-regression.qmd

   File:     slides/week08-regression.qmd
   Slides:   24 slides (6 sections)
   Style:    computational
   Format:   Quarto RevealJS

Next steps:
  Review:   teach slides --revise slides/week08-regression.qmd
  Preview:  qu preview slides/week08-regression.qmd

Commit this content?  [1] Review  [2] Commit  [3] Skip: _
```

---

## Implementation Plan

### Phase 1: Flag Infrastructure (3h)

- [ ] Add new flags to `TEACH_*_FLAGS` arrays
- [ ] Implement `_teach_validate_content_flags()` with conflict detection
- [ ] Implement `_teach_parse_topic_week()` for topic/week extraction
- [ ] Add tests for flag parsing and validation

### Phase 2: Preset System (2h)

- [ ] Define preset content maps (conceptual, computational, rigorous, applied)
- [ ] Implement `_teach_resolve_content()` - merge preset + overrides
- [ ] Add `--style` flag handling in `_teach_scholar_wrapper()`
- [ ] Tests for content resolution

### Phase 3: Lesson Plan Integration (3h)

- [ ] Implement `_teach_load_lesson_plan()` - load and parse YAML
- [ ] Create lesson plan schema validation
- [ ] Implement missing plan prompt workflow
- [ ] Implement `_teach_lookup_topic()` from semester_info.weeks
- [ ] Tests for lesson plan loading

### Phase 4: Interactive Mode (4h)

- [ ] Implement `-i` flag parsing
- [ ] Implement `_teach_interactive_wizard()` with style selection
- [ ] Keyboard navigation (q, b, ?, Enter, numbers)
- [ ] Topic selection from schedule (when no --topic/--week given)
- [ ] Interactive tests

### Phase 5: Revision Workflow (4h)

- [ ] Implement `--revise` flag parsing
- [ ] Implement `_teach_analyze_file()` - detect existing content type
- [ ] Implement `_teach_revise_workflow()` - revision menu
- [ ] Diff preview functionality
- [ ] Tests for revision workflow

### Phase 6: Context & Polish (4h)

- [ ] Implement `--context` flag parsing
- [ ] Implement `_teach_build_context()` - gather context files
- [ ] Enhanced progress indicator with elapsed time
- [ ] Update help system with all new flags
- [ ] Integration tests for full workflows
- [ ] Documentation updates

---

## Testing Strategy

### Unit Tests

```bash
# Flag parsing
test_teach_parse_topic_week()
test_teach_validate_content_flags()
test_teach_detect_conflicts()

# Content resolution
test_teach_resolve_content_conceptual()
test_teach_resolve_content_with_additions()
test_teach_resolve_content_with_removals()

# Lesson plan
test_teach_load_lesson_plan()
test_teach_missing_lesson_plan()
test_teach_week_topic_override()
```

### Integration Tests

```bash
# End-to-end
test_teach_slides_with_week()
test_teach_slides_with_topic()
test_teach_slides_style_override()
test_teach_slides_conflict_error()
test_teach_slides_interactive_mode()
test_teach_slides_revision_workflow()
```

---

## Dependencies

| Dependency      | Version  | Purpose                       |
| --------------- | -------- | ----------------------------- |
| Claude Code CLI | 2.1.12+  | AI generation via `claude -p` |
| Scholar plugin  | 2.3.0+   | Teaching commands             |
| yq              | 4.0+     | YAML parsing                  |
| fzf             | Optional | Interactive selection         |

---

## Review Checklist

- [ ] Backward compatible with existing teach commands
- [ ] All new flags documented in help
- [ ] Progress indicators work in all terminal types
- [ ] Error messages tested for all failure modes
- [ ] Interactive mode keyboard navigation complete
- [ ] Config schema validated
- [ ] Tests added for new functions
- [ ] Documentation updated

---

## Supersedes

This spec supersedes and merges:

- `SPEC-teaching-integration-2026-01-17.md`
- `SPEC-teaching-flags-enhancement-2026-01-17.md`

These files should be archived after this spec is approved.

---

## History

| Date       | Change                                                  | Author      |
| ---------- | ------------------------------------------------------- | ----------- |
| 2026-01-17 | Merged from teaching-integration + teaching-flags specs | Claude + DT |

---

## Related Documents

- [Main Plugin Integration Spec](SPEC-claude-code-plugin-integration-2026-01-17.md)
- [Teach Dispatcher Reference](../reference/MASTER-DISPATCHER-GUIDE.md#teach-dispatcher)
- [Teach Config Dates Schema](../reference/MASTER-API-REFERENCE.md#config-validation)
