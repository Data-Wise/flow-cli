# SPEC: Lesson Plan Extraction (#298)

**Date:** 2026-01-27
**Issue:** https://github.com/Data-Wise/flow-cli/issues/298
**Status:** Ready for Implementation
**Effort:** ~4 hours
**Branch:** `feature/lesson-plan-extraction`

---

## Executive Summary

Extract embedded lesson plans from `teach-config.yml` into a separate `lesson-plans.yml` file for cleaner separation of concerns.

**What we're doing:**
- Extract `semester_info.weeks[]` → `.flow/lesson-plans.yml`
- Add reference pointer in `teach-config.yml`
- Create `teach migrate-config` command

**What we're NOT doing:**
- ❌ Rename teach-config.yml
- ❌ Teaching style integration
- ❌ Per-week file support

---

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Data model | Reference-only | Clean separation, pointer in config |
| Migration | Explicit command | User controls when to migrate |
| File structure | Single file | Simpler to maintain, full semester view |
| Backup | Create .bak | Safe rollback option |
| Errors | Clear + hint | "Run: teach migrate-config" actionable |

---

## File Structure

### Before Migration

```
.flow/
└── teach-config.yml    # 657 lines (course + 14 weeks embedded)
```

### After Migration

```
.flow/
├── teach-config.yml      # ~50 lines (course meta + reference)
├── teach-config.yml.bak  # Backup of original
└── lesson-plans.yml      # ~600 lines (all weeks extracted)
```

---

## Implementation Tasks

### Task 1: `teach migrate-config` Command (~1.5 hours)

**File:** `commands/teach-migrate.zsh` (new)

**Functions:**
- `_teach_migrate_config()` - Main migration logic
- `_teach_extract_weeks()` - Extract weeks array using yq
- `_teach_update_config()` - Remove weeks, add reference
- `_teach_migration_preview()` - Show what will change

**UX Flow:**
```bash
$ teach migrate-config

📦 Migrating teach-config.yml...

Found: 14 weeks in semester_info.weeks[]
Creating: .flow/lesson-plans.yml
Backup: .flow/teach-config.yml.bak

Preview:
  - Week 1: Introduction to Experimental Design
  - Week 2: CRD and One-Way ANOVA
  ... (12 more)

✓ Migration complete!
  Config: .flow/teach-config.yml (657 → 52 lines)
  Plans:  .flow/lesson-plans.yml (14 weeks)
  Backup: .flow/teach-config.yml.bak
```

**Flags:**
- `--dry-run` - Preview without changes
- `--force` - Skip confirmation
- `--no-backup` - Don't create .bak file

---

### Task 2: Update `_teach_load_lesson_plan()` (~1 hour)

**File:** `lib/dispatchers/teach-dispatcher.zsh` (line 491)

**Current:** Reads from `.flow/lesson-plans/week-N.yml` (per-week files)

**New:** Read from `.flow/lesson-plans.yml` (single file)

```zsh
_teach_load_lesson_plan() {
    local week="$1"
    local plans_file=".flow/lesson-plans.yml"

    # Check if lesson plans file exists
    if [[ ! -f "$plans_file" ]]; then
        # Check for embedded weeks (backward compat)
        if _teach_has_embedded_weeks; then
            _teach_warn "Using embedded weeks in teach-config.yml" \
                "Run: teach migrate-config"
            return $(_teach_load_embedded_week "$week")
        fi
        _teach_error "lesson-plans.yml not found" \
            "Run: teach migrate-config"
        return 1
    fi

    # Parse week from single file using yq
    local week_data
    week_data=$(yq ".weeks[] | select(.number == $week)" "$plans_file" 2>/dev/null)

    if [[ -z "$week_data" ]]; then
        _teach_error "Week $week not found in lesson-plans.yml"
        return 1
    fi

    # Extract fields
    TEACH_PLAN_TOPIC=$(echo "$week_data" | yq '.topic // ""')
    TEACH_PLAN_STYLE=$(echo "$week_data" | yq '.style // ""')
    TEACH_PLAN_OBJECTIVES=$(echo "$week_data" | yq '.objectives[]' 2>/dev/null | paste -sd '|' -)
    TEACH_PLAN_SUBTOPICS=$(echo "$week_data" | yq '.subtopics[]' 2>/dev/null | paste -sd '|' -)
    TEACH_PLAN_KEY_CONCEPTS=$(echo "$week_data" | yq '.key_concepts[]' 2>/dev/null | paste -sd '|' -)
    TEACH_PLAN_PREREQUISITES=$(echo "$week_data" | yq '.prerequisites[]' 2>/dev/null | paste -sd '|' -)

    return 0
}
```

**Helper Functions:**
- `_teach_has_embedded_weeks()` - Check if teach-config.yml has weeks[]
- `_teach_load_embedded_week()` - Backward compat loader

---

### Task 3: Error Handling Updates (~30 min)

**Files:** Various locations in `teach-dispatcher.zsh`

**Pattern:** When lesson plan data is needed:
1. Check for `.flow/lesson-plans.yml` first
2. Fall back to embedded weeks with warning
3. Clear error if neither exists

**Error Messages:**
```
❌ lesson-plans.yml not found
   Run: teach migrate-config

⚠️  Using embedded weeks in teach-config.yml
   Consider migrating: teach migrate-config
```

---

### Task 4: Demo Course Fixture (~30 min)

**File:** `tests/fixtures/demo-course/.flow/teach-config.yml` (new)

Create teach-config.yml with 5 embedded weeks matching existing lectures:

```yaml
course:
  name: "STAT-101"
  full_name: "STAT 101 - Introduction to Statistics"
  semester: "fall"
  year: 2026

semester_info:
  start_date: "2026-08-26"
  end_date: "2026-12-15"

  weeks:
    - number: 1
      topic: "Introduction to Statistics"
      style: "conceptual"
      objectives:
        - "Understand measures of central tendency"
        - "Distinguish between data types"
      key_concepts:
        - "descriptive-stats"
        - "data-types"
        - "distributions"

    - number: 2
      topic: "Probability and Inference"
      style: "computational"
      objectives:
        - "Apply probability rules"
        - "Understand sampling methods"
      prerequisites:
        - "Week 1: Introduction to Statistics"

    - number: 3
      topic: "Correlation and Regression"
      style: "rigorous"
      objectives:
        - "Calculate correlation coefficients"
        - "Fit linear regression models"
      prerequisites:
        - "Week 2: Probability and Inference"

    # Add 2 more for testing edge cases
    - number: 4
      topic: "Hypothesis Testing"
      style: "applied"

    - number: 5
      topic: "Course Review"
      style: "applied"
```

---

### Task 5: Tests (~1 hour)

**File:** `tests/test-lesson-plan-extraction.zsh` (new)

**Test Categories:**

1. **Migration Command Tests** (10 tests)
   - Extracts weeks correctly
   - Creates backup file
   - Adds reference to config
   - Handles missing config
   - Dry-run mode works
   - Force flag skips confirmation
   - Idempotent (re-running is safe)

2. **Loader Tests** (8 tests)
   - Loads from lesson-plans.yml
   - Handles missing file with error
   - Falls back to embedded weeks with warning
   - Parses all fields correctly
   - Handles missing week number

3. **Integration Tests** (5 tests)
   - Full workflow: migrate → load → verify
   - teach slides uses new loader
   - teach exam uses new loader

**Test Using Demo Course:**
```zsh
# Setup
cd tests/fixtures/demo-course
[[ -d .flow ]] || mkdir .flow

# Test migration
teach migrate-config --dry-run
teach migrate-config

# Verify
[[ -f .flow/lesson-plans.yml ]] || fail "lesson-plans.yml not created"
[[ -f .flow/teach-config.yml.bak ]] || fail "backup not created"

# Test loading
source ../../lib/dispatchers/teach-dispatcher.zsh
_teach_load_lesson_plan 1
[[ "$TEACH_PLAN_TOPIC" == "Introduction to Statistics" ]] || fail "Week 1 topic wrong"
```

---

## Orchestration Plan (Parallel Tasks)

```
┌────────────────────────────────────────────────────────────────┐
│                    PARALLEL IMPLEMENTATION                      │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  Agent 1: Migration Command          Agent 2: Loader Update    │
│  ─────────────────────────          ────────────────────────   │
│  • commands/teach-migrate.zsh       • Update _teach_load_...   │
│  • _teach_migrate_config()          • _teach_has_embedded...   │
│  • _teach_extract_weeks()           • Error handling           │
│  • Preview/dry-run                  • Backward compat          │
│                                                                │
│  Est: 1.5 hours                     Est: 1.5 hours             │
│                                                                │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  Agent 3: Fixtures + Tests                                     │
│  ────────────────────────                                      │
│  • Demo course teach-config.yml                                │
│  • test-lesson-plan-extraction.zsh                             │
│  • 23 tests total                                              │
│                                                                │
│  Est: 1 hour (depends on Agents 1 & 2)                         │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

**Dependency Graph:**
```
Agent 1 (migrate cmd) ──┐
                       ├──► Agent 3 (tests)
Agent 2 (loader)     ──┘
```

---

## Acceptance Criteria

- [ ] `teach migrate-config` extracts weeks to lesson-plans.yml
- [ ] `teach migrate-config --dry-run` shows preview without changes
- [ ] Backup file created (teach-config.yml.bak)
- [ ] Loader reads from lesson-plans.yml
- [ ] Loader falls back to embedded weeks with warning
- [ ] Clear error message when lesson-plans.yml missing
- [ ] Demo course fixture has teach-config.yml with 5 weeks
- [ ] 23+ tests passing
- [ ] Existing teach commands still work

---

## Files Changed

| File | Change |
|------|--------|
| `commands/teach-migrate.zsh` | NEW - Migration command |
| `lib/dispatchers/teach-dispatcher.zsh` | UPDATE - Loader, error handling |
| `tests/fixtures/demo-course/.flow/teach-config.yml` | NEW - Test fixture |
| `tests/test-lesson-plan-extraction.zsh` | NEW - 23 tests |

---

## Rollback Plan

If issues arise:
1. Remove lesson-plans.yml
2. Restore from teach-config.yml.bak
3. Code automatically falls back to embedded weeks

---

**Last Updated:** 2026-01-27
**Author:** Claude (with DT)
