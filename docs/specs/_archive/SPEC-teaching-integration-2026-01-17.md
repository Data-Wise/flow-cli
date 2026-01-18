# SPEC: Teaching Integration Enhancement

**Feature:** Enhanced teach dispatcher with Scholar plugin integration
**Status:** Draft
**Created:** 2026-01-17
**From Brainstorm:** Deep interactive session with expert agents
**Target Release:** flow-cli v5.13.0 (Phase 1 of plugin-dispatchers)

---

## Metadata

| Field               | Value                                              |
| ------------------- | -------------------------------------------------- |
| **Status**          | Draft                                              |
| **Priority**        | High (enables 10x faster course material creation) |
| **Complexity**      | Medium (12-16 hours)                               |
| **Risk Level**      | Low (enhances existing teach dispatcher)           |
| **Dependencies**    | Claude Code CLI 2.1.12+, Scholar plugin            |
| **Target Users**    | Academic instructors (ADHD-friendly required)      |
| **Branch Strategy** | feature/teaching-enhancement → dev → main          |

---

## Overview

Enhance the existing `teach` dispatcher to provide seamless Scholar plugin integration with smart defaults, interactive mode, and revision workflows. The teach dispatcher already has solid infrastructure (config validation, post-generation hooks, git integration) - this spec focuses on enhancing the AI generation experience.

---

## Primary User Story

**As an** academic instructor with ADHD
**I want to** generate teaching materials with minimal friction
**So that I** can focus on content quality rather than tooling

### Acceptance Criteria

- [ ] `teach slides` auto-detects current week's topic from schedule
- [ ] `teach slides -i` provides step-by-step interactive wizard
- [ ] `teach slides --revise FILE` improves existing content
- [ ] Progress indicators show elapsed time during generation
- [ ] Error messages provide actionable recovery steps
- [ ] All commands complete within 2 minutes or show progress

---

## Secondary User Stories

### Story 2: Iterative Refinement

**As an** instructor reviewing generated content
**I want to** refine materials through conversation
**So that** I get content that matches my teaching style

### Story 3: Course Context Integration

**As an** instructor with established course materials
**I want to** include past lectures/syllabus as context
**So that** generated content aligns with my curriculum

---

## Architecture

### Component Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│ User: teach slides "Regression" -i                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ teach-dispatcher.zsh                                            │
│ ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│ │ _teach_parse_   │  │ _teach_smart_   │  │ _teach_inter_   │  │
│ │   args()        │→│   defaults()     │→│   active()      │  │
│ └─────────────────┘  └─────────────────┘  └─────────────────┘  │
│                              │                                  │
│                              ▼                                  │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ _teach_scholar_wrapper() [EXISTING]                         │ │
│ │ - Flag validation                                           │ │
│ │ - Config preflight                                          │ │
│ │ - Build Scholar command                                     │ │
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
│ claude -p "/scholar:teaching:slides 'Regression'" \             │
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

### Config Schema (teach-config.yml)

```yaml
# Course Information
course:
  name: "STAT 440"
  title: "Regression Analysis"
  semester: "Spring"
  year: 2026

# Semester Schedule
semester:
  start_date: "2026-01-13"
  end_date: "2026-05-09"
  schedule_file: "_schedule.yml"  # Topic-to-week mapping

# Scholar Integration (NEW)
scholar:
  # Default formats per material type
  formats:
    slides: "quarto"      # qmd, md, latex
    lecture: "quarto"
    quiz: "quarto"
    exam: "quarto"
    assignment: "markdown"
    feedback: "markdown"

  # Output directories
  paths:
    slides: "slides/"
    lectures: "lectures/"
    quizzes: "quizzes/"
    exams: "exams/"
    assignments: "assignments/"
    feedback: "feedback/"

  # Context files for --context flag
  context:
    always_include:
      - "syllabus.qmd"
      - "_schedule.yml"
    slides_include:
      - "lectures/*.qmd"
    exam_include:
      - "lectures/*.qmd"
      - "quizzes/*.qmd"

  # Instructor preferences
  preferences:
    difficulty: "undergraduate"  # undergraduate, graduate, mixed
    style: "academic"           # academic, casual, technical
    include_examples: true
    include_practice: true

# Git Workflow [EXISTING]
git:
  draft_branch: "draft"
  production_branch: "main"
  auto_pr: true
  require_clean: true

# Workflow Mode [EXISTING]
workflow:
  teaching_mode: true
  auto_commit: false
  auto_push: false
```

---

## API Design

### New Flags

| Flag            | Short | Purpose                     | Example                               |
| --------------- | ----- | --------------------------- | ------------------------------------- |
| `--interactive` | `-i`  | Step-by-step wizard         | `teach slides -i`                     |
| `--revise`      |       | Improve existing file       | `teach slides --revise slides/w8.qmd` |
| `--context`     |       | Include full course context | `teach exam "Midterm" --context`      |
| `--week`        | `-w`  | Override week number        | `teach slides -w 8`                   |

### Command Syntax

```bash
# Basic (auto-detect topic)
teach slides                      # Uses current week's topic
teach quiz                        # Uses current week's topic

# With topic
teach slides "Regression Analysis"
teach exam "Midterm 1"

# Interactive mode
teach slides -i                   # Step-by-step wizard
teach exam -i                     # Guided exam creation

# Revision mode
teach slides --revise slides/week08.qmd
teach exam --revise exams/midterm.qmd

# With context
teach exam "Final" --context      # Include syllabus + past materials

# Override week
teach slides -w 10 "ANOVA"        # Force week 10
```

---

## Data Models

### Schedule File (_schedule.yml)

```yaml
weeks:
  - week: 1
    topic: "Introduction to Regression"
    dates: "Jan 13-17"
    readings: ["Ch 1"]

  - week: 8
    topic: "Multiple Regression"
    dates: "Mar 3-7"
    readings: ["Ch 8-9"]
    exam: "Midterm 1"

units:
  - name: "Simple Regression"
    weeks: [1, 2, 3, 4]

  - name: "Multiple Regression"
    weeks: [5, 6, 7, 8]
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

## UI/UX Specifications

### Progress Indicator

```
⠋ Generating slides (~30s)...  12s
⠙ Generating slides (~30s)...  13s
⠹ Generating slides (~30s)...  14s
```

**Implementation:**

- Braille spinner (⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏)fault?
- Elapsed time counter updates every second
- Estimated time shown from command type

### Success Message

```
✓ Created: slides/week08-regression.qmd

   File:     slides/week08-regression.qmd
   Slides:   24 slides (6 sections)
   Format:   Quarto RevealJS

Next steps:
  Review:   teach slides --revise slides/week08-regression.qmd
  Preview:  qu preview slides/week08-regression.qmd

Commit this content?  [1] Review  [2] Commit  [3] Skip: _
```

### Error Message

```
✗ teach: Topic not found in schedule

   Week 8 has no scheduled topic in _schedule.yml

Recovery:
   Specify topic explicitly:  teach slides "Regression Analysis"
   Edit schedule:             teach config

Retry?  [Y/n] _
```

### Interactive Mode Flow

```
🎓 Create Slides

Topic:
  [1] Week 8: Regression Analysis  (scheduled)
  [2] Week 9: Multiple Regression  (upcoming)
  [3] Enter custom topic

Your choice [1-3]: _
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

### Accessibility

- All output uses semantic colors from FLOW_COLORS
- Interactive prompts support keyboard-only navigation
- Error messages always include recovery commands
- Time estimates help with attention management

---

## Open Questions

1. **Context size limits:** How much context can Scholar handle before degrading?

   - Mitigation: Start with syllabus + current unit only
2. **Revision persistence:** Should revision instructions be saved for re-use?

   - Recommendation: Yes, save to `.flow/revisions/{file}.yml`

---

## Review Checklist

- [ ] Backward compatible with existing teach commands
- [ ] All new flags documented in help
- [ ] Progress indicators work in all terminal types
- [ ] Error messages tested for all failure modes
- [ ] Interactive mode keyboard navigation complete
- [ ] Config schema validated
- [ ] Tests added for new functions

---

## Implementation Notes

### Key Functions to Add/Modify

1. **`_teach_smart_defaults()`** - Auto-detect topic from schedule
2. **`_teach_interactive_wizard()`** - Step-by-step generation
3. **`_teach_revise_workflow()`** - Revision menu and prompts
4. **`_teach_build_context()`** - Gather files for --context flag
5. **`_teach_execute()` enhancement** - Add elapsed time counter

### Existing Infrastructure to Leverage

- `_teach_scholar_wrapper()` - Already handles command building
- `_teach_preflight()` - Config validation
- `_teach_validate_flags()` - Flag checking
- `_teach_post_generation_hooks()` - Git integration
- `_flow_spinner_start/stop()` - Progress indicators

### Testing Strategy

1. Unit tests for `_teach_smart_defaults()` with mock schedules
2. Integration tests for full command flow
3. Interactive tests with `tests/interactive-dog-feeding.zsh` pattern

---

## Implementation Phases

### Phase 1: Smart Defaults (4h)

- [ ] `_teach_smart_defaults()` - topic auto-detection
- [ ] `_teach_current_week()` - calculate from semester dates
- [ ] `_teach_lookup_topic()` - schedule YAML parsing
- [ ] Enhanced progress indicator with elapsed time

### Phase 2: Interactive Mode (6h)

- [ ] `-i` flag parsing in `_teach_scholar_wrapper()`
- [ ] `_teach_interactive_wizard()` with AskUserQuestion-style prompts
- [ ] Keyboard navigation (q, b, ?, Enter, numbers)
- [ ] Topic selection from schedule

### Phase 3: Revision Workflow (4h)

- [ ] `--revise` flag parsing
- [ ] `_teach_analyze_file()` - detect existing content
- [ ] `_teach_revise_workflow()` - revision menu
- [ ] Diff preview functionality

### Phase 4: Context Integration (2h)

- [ ] `--context` flag parsing
- [ ] `_teach_build_context()` - gather files
- [ ] Context caching with staleness detection

---

## History

| Date       | Change                       | Author      |
| ---------- | ---------------------------- | ----------- |
| 2026-01-17 | Initial spec from brainstorm | Claude + DT |

---

## Related Documents

- [Main Plugin Integration Spec](SPEC-claude-code-plugin-integration-2026-01-17.md)
- [Teach Dispatcher Reference](../reference/TEACH-DISPATCHER-REFERENCE.md)
- [Quick Reference Card](../reference/TEACH-GENERATION-QUICK-REFERENCE.md) (created by UX agent)
