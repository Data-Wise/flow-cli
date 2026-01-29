# Implementation Spec: teach plan Command (v2 - Revised for Centralized Format)

**Status:** draft
**Created:** 2026-01-29
**Supersedes:** SPEC-teach-plan-create-2026-01-27.md (outdated per-file format)
**From Issue:** #278
**Priority:** High (fixes broken UX)
**Effort Estimate:** 3-4 hours (reduced from original — infrastructure already exists)

---

## Critical Change from v1 Spec

The original spec (2026-01-27) assumed **per-file format** (`.flow/lesson-plans/week-N.yml`).
Since then, v5.20.0 shipped with **centralized format** (`.flow/lesson-plans.yml` with `weeks:` array).

**This spec targets the centralized format exclusively.**

### Format Comparison

| Aspect | v1 Spec (Outdated) | v2 Spec (This) |
|--------|--------------------|--------------------|
| Target | `.flow/lesson-plans/week-N.yml` | `.flow/lesson-plans.yml` |
| Structure | Individual files per week | Single file, `weeks:` array |
| Create | Write new file | Append to `weeks:` array (sorted) |
| Edit | Open file in `$EDITOR` | Extract week → temp file → merge back |
| Delete | Remove file | Remove entry from `weeks:` array |
| Compatible with | `_teach_lecture_from_plan()` (dead code) | `_teach_load_lesson_plan()` (primary) |

---

## Overview

Add `teach plan` subcommand to manage lesson plans in `.flow/lesson-plans.yml`. This fixes a broken UX where error messages reference `teach plan create` but the command doesn't exist (line 677 of teach-dispatcher.zsh).

**Key Value:** Completes the lesson plan workflow:
- `teach migrate-config` — extracts plans from config (v5.20.0, exists)
- `teach plan` — CRUD management of individual weeks (NEW)
- `_teach_load_lesson_plan()` — loads plans for Scholar (v5.13.0+, exists)

---

## Primary User Story

**As an instructor using `teach slides --week N`,**
**I want** to create and manage lesson plan entries for individual weeks,
**So that** I can provide detailed content context for AI-generated materials.

**Acceptance Criteria:**
1. `teach plan create <week>` adds a new week entry to `lesson-plans.yml`
2. `teach plan list` shows all week entries with topic and style
3. `teach plan show <week>` displays full lesson plan details
4. `teach plan edit <week>` opens week entry in `$EDITOR`
5. `teach plan delete <week>` removes a week entry (with confirmation)
6. Existing hint at line 677 (`teach plan create $week`) now works

---

## Technical Requirements

### Existing Infrastructure (Already Implemented)

| Function | Purpose | Location |
|----------|---------|----------|
| `_teach_load_lesson_plan()` | Parse YAML, set TEACH_PLAN_* vars | teach-dispatcher.zsh:513 |
| `_teach_has_embedded_weeks()` | Check for legacy format | teach-dispatcher.zsh:576 |
| `_teach_load_embedded_week()` | Backward compat loader | teach-dispatcher.zsh:595 |
| `_teach_lookup_topic()` | Fallback topic lookup | teach-dispatcher.zsh:627 |
| `_teach_prompt_missing_plan()` | Hint message (references this command) | teach-dispatcher.zsh:651 |
| `_teach_integrate_lesson_plan()` | Scholar integration | teach-dispatcher.zsh:688 |
| `_teach_migrate_config()` | Creates lesson-plans.yml | commands/teach-migrate.zsh |

### New Commands

```bash
teach plan create <week> [--topic "Topic"] [--style conceptual|computational|rigorous|applied]
teach plan list [--json]
teach plan show <week> [--json]
teach plan edit <week>
teach plan delete <week> [--force]
teach plan help
```

**Shortcuts:** `teach pl`, `teach plan c`, `teach plan ls`, `teach plan s`

### YAML Schema (Centralized Format)

```yaml
# .flow/lesson-plans.yml
weeks:
  - number: 1
    topic: "Introduction to Statistics"
    style: "conceptual"
    objectives:
      - "Define descriptive statistics"
      - "Identify data types"
    subtopics:
      - "Measures of central tendency"
      - "Variability"
    key_concepts:
      - "descriptive-stats"
      - "data-types"
    prerequisites: []

  - number: 2
    topic: "Probability Foundations"
    style: "rigorous"
    # ...
```

---

## Architecture

### File: `commands/teach-plan.zsh` (NEW, ~350-400 lines)

**Pattern:** Follows `teach-templates.zsh` and `teach-macros.zsh` (external command file).

**Structure:**

```
Load guard + source deps
  └─ _teach_plan()           # Main dispatcher (create/list/show/edit/delete/help)
     ├─ _teach_plan_create() # Add week to weeks[] array
     ├─ _teach_plan_list()   # Display table of all weeks
     ├─ _teach_plan_show()   # Display single week details
     ├─ _teach_plan_edit()   # Extract → $EDITOR → merge back
     ├─ _teach_plan_delete() # Remove from weeks[] array
     └─ _teach_plan_help()   # Standard help output
```

### Dispatch Integration

**Insert after `migrate-config` block (line ~4917):**

```zsh
# Lesson plan management (v5.22.0 - Issue #278)
plan|pl)
    case "$1" in
        --help|-h|help) _teach_plan_help; return 0 ;;
        *) _teach_plan "$@" ;;
    esac
    ;;
```

### Source Loading (teach-dispatcher.zsh header)

```zsh
# Source teach-plan command (v5.22.0 - Lesson Plan Management #278)
if [[ -z "$_FLOW_TEACH_PLAN_LOADED" ]]; then
    local plan_path="${0:A:h:h}/../commands/teach-plan.zsh"
    [[ -f "$plan_path" ]] && source "$plan_path"
fi
```

---

## Implementation Plan

### Phase 1: Core Command (~2.5 hours)

**Task 1.1:** Create `commands/teach-plan.zsh` with:

- **`_teach_plan_create()`** (~80 lines)
  - Validate week number (1-20)
  - Create `lesson-plans.yml` if doesn't exist (empty `weeks: []`)
  - Check duplicate week (error unless `--force`)
  - Interactive prompts: topic (required), style (optional, default: conceptual)
  - Optional: objectives, subtopics (skip with Enter)
  - Auto-populate topic from `teach-config.yml` if available
  - Insert into `weeks:` array sorted by number (yq)
  - Success message with edit/show hints

- **`_teach_plan_list()`** (~40 lines)
  - Parse `weeks:` array
  - Table: Week | Topic | Style | Objectives (count)
  - Detect gaps in sequence
  - Empty state: "No lesson plans. Run: teach plan create 1"
  - Optional: `--json` for machine-readable output

- **`_teach_plan_show()`** (~40 lines)
  - Reuse `_teach_load_lesson_plan()` for loading
  - Formatted display with colors and sections
  - Optional: `--json` output

- **`_teach_plan_edit()`** (~30 lines)
  - Find line number of `- number: N` in `lesson-plans.yml` (grep)
  - Print hint: "Week N starts at line X"
  - Open `lesson-plans.yml` in `$EDITOR` (fallback: `vi`)
  - Validate YAML after edit with `yq eval '.' file > /dev/null`
  - If invalid, warn and offer to re-edit

- **`_teach_plan_delete()`** (~30 lines)
  - Confirm unless `--force`
  - Remove entry with `yq 'del(.weeks[] | select(.number == N))'`
  - Success message

- **`_teach_plan_help()`** (~40 lines)
  - Standard help format (box header, sections, examples)

**Task 1.2:** Integrate into `teach-dispatcher.zsh` (~15 lines)
- Add source loading in header
- Add dispatch case after `migrate-config`

### Phase 2: Testing (~1 hour)

**File:** `tests/test-teach-plan.zsh` (~300 lines, ~25 tests)

| Section | Tests | Coverage |
|---------|-------|----------|
| Create | 8 | Happy path, duplicate, force, auto-populate, validation |
| List | 4 | All weeks, empty, gaps, JSON output |
| Show | 4 | Single week, not found, JSON, colors |
| Edit | 3 | Edit flow, validation, cancel |
| Delete | 3 | Confirm, force, not found |
| Integration | 3 | Create → load → Scholar, migrate → plan |

### Phase 3: Documentation & Cleanup (~30 min)

- Update help text in `teach-dispatcher.zsh` main help
- Add `plan` to shortcuts table (`pl` → plan)
- Update CHANGELOG.md

### Cleanup: Dead Code Removal

Remove/update during implementation:
- **`_teach_lecture_from_plan()`** (lines 2553-2591) — dead code referencing per-file format
- **Error hint at line 677** — already correct (`teach plan create $week`), will now work

---

## Dependencies

| Dependency | Purpose | Required? |
|------------|---------|-----------|
| `yq` | YAML manipulation | Yes |
| `.flow/lesson-plans.yml` | Target file | Created if missing |
| `$EDITOR` | Edit command | Optional (vi fallback) |

---

## Design Decisions (Resolved 2026-01-29)

| Question | Decision | Rationale |
|----------|----------|-----------|
| Auto-populate topic? | Yes, pre-fill from config | If `teach-config.yml` has topic for week N, use as default. User can override at prompt. |
| Dead code cleanup? | Remove in this PR | `_teach_lecture_from_plan()` (38 lines) removed alongside feature. Keeps PR tidy. |
| MVP scope? | Full CRUD | All 5 subcommands: create, list, show, edit, delete. ~350-400 lines. |
| Edit UX? | Open full file + line hint | Open `lesson-plans.yml` in `$EDITOR`, print line number to jump to. Simpler than extract/merge. |
| Week range? | 1-20 | Warn if week not in config schedule but allow creation. |
| Batch mode? | No | Single-week only. Batch is `teach migrate-config`. |

---

## Review Checklist

- [ ] `teach plan create 5` creates week entry in lesson-plans.yml
- [ ] `teach plan list` shows table of all weeks
- [ ] `teach plan show 5` displays formatted week details
- [ ] `teach plan edit 5` opens in $EDITOR and merges back
- [ ] `teach plan delete 5` removes with confirmation
- [ ] Existing `_teach_load_lesson_plan()` works with created entries
- [ ] `teach slides --week 5` picks up plan data after creation
- [ ] Help text comprehensive with examples
- [ ] Tests pass (25+ tests)
- [ ] Dead code removed (`_teach_lecture_from_plan`)
- [ ] Error hint at line 677 now resolves to working command

---

## History

| Date | Change |
|------|--------|
| 2026-01-27 | v1 spec (per-file format, shelved) |
| 2026-01-29 | v2 spec (centralized format, agent-reviewed, decisions finalized) |
