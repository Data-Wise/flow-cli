# Implementation Spec: teach plan create Command

**Status:** draft
**Created:** 2026-01-27
**From Issue:** #278
**Priority:** High (fixes broken UX)
**Effort Estimate:** 2-3 hours

---

## Overview

Add `teach plan` subcommand to create and manage lesson plan YAML files. This fixes a UX bug where error messages reference `teach plan create` but the command doesn't exist.

**Key Value:** Completes existing lesson plan infrastructure (v5.13.0+) that already has consumers but no creator.

---

## Primary User Story

**As an instructor using `teach slides --week N`,**
**I want** to create a lesson plan file when prompted,
**So that** I can provide detailed content context beyond what's in `teach-config.yml`.

**Acceptance Criteria:**
1. `teach plan create <week>` creates `.flow/lesson-plans/week-N.yml` with template
2. `teach plan list` shows existing lesson plans
3. `teach plan show <week>` displays lesson plan content
4. Help text updated to include `plan` subcommand
5. Existing hint message (line 587) now works

---

## Technical Requirements

### Existing Infrastructure (Already Implemented)

| Function | Purpose | Location |
|----------|---------|----------|
| `_teach_load_lesson_plan()` | Parse YAML lesson plan | teach-dispatcher.zsh:491 |
| `_teach_integrate_lesson_plan()` | Apply plan to Scholar | teach-dispatcher.zsh:598 |
| `_teach_prompt_missing_plan()` | User prompt when missing | teach-dispatcher.zsh:558 |
| `_teach_lookup_topic()` | Fallback topic lookup | teach-dispatcher.zsh:534 |

### New Commands

```bash
teach plan create <week>     # Create YAML template
teach plan list              # List existing plans
teach plan show <week>       # Display plan content
teach plan help              # Show help
```

### YAML Template (Existing Schema)

```yaml
# Week N Lesson Plan
# Created: YYYY-MM-DD
# Edit this file to customize Scholar output for this week

topic: ""                    # Required: Main topic for the week
style: "conceptual"          # Options: conceptual | computational | rigorous | applied

objectives:
  - "Objective 1"
  - "Objective 2"

subtopics:
  - "Subtopic 1"
  - "Subtopic 2"

key_concepts:
  - "Concept 1"
  - "Concept 2"

prerequisites:
  - "Prerequisite 1"

# Optional: readings, activities, assignment
readings:
  - "Reading 1"

activities:
  lecture: ""
  lab: ""

assignment:
  name: ""
  due: ""
```

### File Structure

```
.flow/
└── lesson-plans/
    ├── week-1.yml
    ├── week-2.yml
    └── ...
```

---

## Implementation Plan

### Phase 1: Core Commands (2-3 hours)

1. **Add dispatcher case** (teach-dispatcher.zsh ~line 4844)
   ```zsh
   plan|pl)
       case "$1" in
           create|c) shift; _teach_plan_create "$@" ;;
           list|ls|l) _teach_plan_list ;;
           show|s) shift; _teach_plan_show "$@" ;;
           help|--help|-h) _teach_plan_help ;;
           *) _teach_plan_help ;;
       esac
       ;;
   ```

2. **Implement `_teach_plan_create()`**
   - Validate week number (1-16 range)
   - Create `.flow/lesson-plans/` if needed
   - Check if file exists (warn, offer --force)
   - Write YAML template with comments
   - Show success message with edit hint

3. **Implement `_teach_plan_list()`**
   - List files in `.flow/lesson-plans/`
   - Show week number and topic for each
   - Handle empty state

4. **Implement `_teach_plan_show()`**
   - Display lesson plan content
   - Format with colors
   - Handle missing file

5. **Add `_teach_plan_help()`**
   - Document all subcommands
   - Show examples

### Phase 2: Testing (30 min)

- Unit tests for plan creation
- E2E test: create → load → integrate flow

### Phase 3: Documentation (30 min)

- Update dispatcher reference
- Add to help system

---

## Deferred (Future Enhancement)

| Feature | Reason to Defer |
|---------|-----------------|
| `--interactive` mode | Basic template sufficient for MVP |
| `--from-markdown FILE` | Complex parsing, unclear format |
| `teach plan convert` | Same as above |
| Validation of plan content | yq handles basic YAML validation |

---

## Dependencies

- None (uses existing ZSH, mkdir, cat)
- yq recommended but not required for creation

---

## Open Questions

1. Should `teach plan create` auto-populate topic from `teach-config.yml`?
   - **Recommendation:** Yes, if available

2. Should we validate week number against `semester_info.weeks`?
   - **Recommendation:** Warn if week not in config, but allow creation

---

## Review Checklist

- [ ] Code follows project conventions
- [ ] Help text comprehensive
- [ ] Error messages helpful
- [ ] Tests cover happy path and edge cases
- [ ] Documentation updated

---

## History

| Date | Change |
|------|--------|
| 2026-01-27 | Initial spec from brainstorm session |
