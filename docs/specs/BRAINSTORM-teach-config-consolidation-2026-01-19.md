# Brainstorm: Teaching Workflow Config File Strategy

**Created:** 2026-01-19
**Context:** Dashboard feature adding more config → need consolidation strategy
**Related:** SPEC-teach-dashboard-2026-01-18.md
**Status:** Brainstorm → Will inform v5.15.0+ config architecture

---

## Current State: Config File Inventory

### Existing Config Files (v5.14.0)

| File | Owner | Type | Purpose | Size | Created By |
|------|-------|------|---------|------|------------|
| `.flow/teach-config.yml` | Instructor | Source | Master course config | ~200 lines | `teach init` |
| `.flow/lesson-plans/week-N.yml` | Instructor | Source | Per-week Scholar context | ~50 lines each | Manual |
| `lesson-plan.yml` | Instructor | Source | Global Scholar context (legacy) | ~100 lines | Manual |
| `.flow/semester-data.json` | teach dashboard | Generated | Dashboard data export | ~5 KB | `teach dashboard generate` ★ NEW |
| `.flow/.validation-cache.json` | teach validator | Cache | Config validation cache | ~1 KB | `teach` commands |
| `lib/templates/teaching/teach-config.schema.json` | Developer | Schema | JSON Schema validation | ~300 lines | Repository |

### Related Quarto Files

| File | Purpose | Updated By |
|------|---------|------------|
| `_quarto.yml` | Site configuration | Manual |
| `index.qmd` | Homepage (dashboard container) | Manual |
| Various `*.qmd` | Content files | Manual + Scholar |

---

## Problem Analysis

### Issue 1: Fragmentation

**Current situation:**
- 3+ YAML files for course info
- Unclear precedence
- Duplication risk

**Example confusion:**
```
lesson-plan.yml:               # Global context
  course: "STAT 545"

.flow/teach-config.yml:        # Master config
  course:
    name: "STAT 545"

.flow/lesson-plans/week-5.yml: # Per-week
  course: "STAT 545"
```

**Which is authoritative?**

### Issue 2: Scholar Context Split

**Current:**
- Global: `lesson-plan.yml` (root)
- Per-week: `.flow/lesson-plans/week-N.yml`
- Config: `.flow/teach-config.yml`

**Scholar reads from:**
1. `lesson-plan.yml` first (if exists)
2. `.flow/lesson-plans/week-N.yml` (if --week specified)
3. `.flow/teach-config.yml` (for course metadata)

**Problem:** Multiple sources, merge logic unclear

### Issue 3: Dashboard Adds More Data

**v5.15.0 adds:**
```yaml
semester_info:
  weeks:
    - lecture:
        title: "..."
        url: "..."
      lab: {...}
      assignment: {...}

dashboard:
  show_labs: true
  announcements: [...]
```

**teach-config.yml grows to ~300+ lines** for comprehensive courses

---

## Design Principles for Config Architecture

### 1. Single Source of Truth (SSOT)

**Principle:** Each piece of data exists in exactly one authoritative location

**Applied:**
- Course metadata → `teach-config.yml`
- Semester dates → `teach-config.yml`
- Week topics → `teach-config.yml`
- Scholar context → **TBD** (see options below)

### 2. Separation of Concerns

**Principle:** Different types of data in different files

**Categories:**
1. **Structural data** - Course structure, schedule (teach-config.yml)
2. **Content context** - Pedagogical context for generation (Scholar files)
3. **Generated data** - Derived outputs (JSON, cache)
4. **Site configuration** - Quarto settings (_quarto.yml)

### 3. Minimal Duplication

**Principle:** Reference, don't duplicate

**Pattern:**
```yaml
# Good: Reference
weeks:
  - number: 5
    topic: "Factorial Designs"
    lecture_url: "lectures/week-05.qmd"

# Bad: Duplicate
weeks:
  - number: 5
    topic: "Factorial Designs"    # In teach-config.yml

lectures/week-05.qmd:
  title: "Factorial Designs"      # Same info!
```

### 4. Human-Readable & Editable

**Principle:** Instructors should edit config comfortably

**Requirements:**
- YAML (not JSON) for source files
- Comments and examples
- Clear structure
- Validation feedback

### 5. Generate, Don't Duplicate

**Principle:** Derived data should be generated, not manually maintained

**Examples:**
- semester-data.json ← generate from teach-config.yml ✅
- Week URLs ← could generate from conventions ✅
- Assignment due dates ← calculate from week + offset ✅

---

## Integration Options

### Option A: Monolithic teach-config.yml (Current Direction)

**Strategy:** Everything in `.flow/teach-config.yml`

```yaml
# .flow/teach-config.yml (400+ lines)

course:
  name: "STAT 545"
  semester: "Spring 2026"
  # ... course metadata

semester_info:
  start_date: "2026-01-19"
  weeks:
    - number: 1
      topic: "..."
      lecture: {...}
      lab: {...}
  # ... schedule data

dashboard:
  show_labs: true
  # ... dashboard config

scholar_context:          # NEW: Merge lesson-plan.yml here
  learning_objectives: [...]
  pedagogical_approach: "..."
  course_philosophy: "..."
  assessment_strategy: {...}

  # Per-week context
  weeks:
    1:
      focus: "..."
      prerequisites: [...]
      learning_goals: [...]
```

**Pros:**
- ✅ True SSOT
- ✅ One file to backup
- ✅ Easy to version control
- ✅ Clear precedence

**Cons:**
- ❌ Large file (400+ lines)
- ❌ Hard to navigate
- ❌ Merge conflicts likely
- ❌ Mixing structure + content

**Verdict:** 🟡 Works but unwieldy for large courses

---

### Option B: Hierarchical Config Files (Recommended)

**Strategy:** Split by concern, clear hierarchy

```
.flow/
├── teach-config.yml                 # Course structure (200 lines)
│   ├── course metadata
│   ├── semester_info (dates, weeks, breaks)
│   └── dashboard config
│
├── scholar-context.yml              # Scholar context (150 lines)
│   ├── Global context
│   ├── learning_objectives
│   ├── pedagogical_approach
│   └── assessment_strategy
│
├── lesson-plans/
│   ├── week-01.yml                  # Per-week context (50 lines each)
│   ├── week-02.yml
│   └── ...
│
└── semester-data.json               # Generated (5 KB)
```

**teach-config.yml** - Structure only:
```yaml
course:
  name: "STAT 545"
  semester: "Spring 2026"

semester_info:
  start_date: "2026-01-19"
  weeks:
    - number: 1
      topic: "Experimental Design"
      lecture_url: "lectures/week-01.qmd"

dashboard:
  show_labs: true

# Reference to Scholar context
scholar_context_file: ".flow/scholar-context.yml"
```

**scholar-context.yml** - Pedagogy only:
```yaml
# Global pedagogical context for Scholar

course_philosophy: |
  This course emphasizes hands-on experimental design...

learning_objectives:
  - "Design randomized experiments"
  - "Analyze factorial designs"

pedagogical_approach: "active learning"

assessment_strategy:
  formative: ["quizzes", "labs"]
  summative: ["exams", "project"]

common_misconceptions:
  - "Students often confuse..."
```

**lesson-plans/week-01.yml** - Week-specific context:
```yaml
# Week 1 specific context

focus: "Introduction to experimental design principles"

prerequisites:
  - "Basic statistics"
  - "R programming"

learning_goals:
  - "Understand randomization"
  - "Apply blocking techniques"

key_concepts:
  - "Experimental units"
  - "Treatment factors"

examples:
  - "Agricultural field trials"
  - "Clinical trials"
```

**Pros:**
- ✅ Manageable file sizes
- ✅ Clear separation of concerns
- ✅ Easy to navigate
- ✅ Fewer merge conflicts
- ✅ Can edit context without touching structure

**Cons:**
- ⚠️ Multiple files to manage
- ⚠️ Need merge logic for Scholar
- ⚠️ Slightly more complex

**Verdict:** 🟢 Best balance for large courses

---

### Option C: Database-Style (Overkill)

**Strategy:** SQLite database for all config

**Verdict:** 🔴 Overengineered, loses human-readability

---

## Recommended Integration Strategy

### Phase 1: v5.15.0 (Dashboard Feature)

**Keep current structure, add dashboard section**

```yaml
# .flow/teach-config.yml

# Existing sections unchanged
course: {...}
semester_info: {...}

# NEW: Add dashboard section
dashboard:
  show_labs: true
  show_assignments: true
  show_readings: false
  card_style: "detailed"
  hero_style: "banner"
  enable_announcements: true
  max_announcements: 5
  fallback_message: "Check Syllabus..."
  announcements: []
```

**Impact:** Adds ~30 lines to teach-config.yml

**Rationale:**
- Minimal disruption
- Dashboard config is structural (like semester_info)
- Not urgent to refactor yet

---

### Phase 2: v5.16.0 (Scholar Context Consolidation)

**Consolidate Scholar context files**

**Migration path:**
```bash
teach scholar migrate
# Combines lesson-plan.yml + per-week files into scholar-context.yml
```

**New structure:**
```
.flow/
├── teach-config.yml          # Course structure
├── scholar-context.yml       # NEW: Consolidated Scholar context
└── semester-data.json        # Generated
```

**Deprecate:**
- `lesson-plan.yml` (root) - Move to `.flow/scholar-context.yml`
- `.flow/lesson-plans/week-N.yml` - Merge into scholar-context.yml

---

### Phase 3: v5.17.0+ (Per-Week Modularization)

**For very large courses, allow per-week override**

```
.flow/
├── teach-config.yml
├── scholar-context.yml       # Global defaults
└── scholar-overrides/
    ├── week-01.yml          # Optional overrides
    └── week-12.yml
```

**Merge logic:**
1. Load global `scholar-context.yml`
2. If `scholar-overrides/week-N.yml` exists, deep merge
3. Pass combined context to Scholar

---

## File Precedence Rules

### Current (v5.14.0)

```
Scholar context loading order:
1. lesson-plan.yml (root) - if exists
2. .flow/lesson-plans/week-N.yml - if --week specified
3. .flow/teach-config.yml - course metadata
```

**Problem:** Unclear merge behavior

---

### Proposed (v5.16.0+)

```
Configuration precedence (highest to lowest):
1. CLI flags (--topic "...")
2. Per-week override (.flow/scholar-overrides/week-N.yml)
3. Global Scholar context (.flow/scholar-context.yml)
4. Course structure (.flow/teach-config.yml)
5. Defaults (built-in)
```

**Merge strategy:**
- Objects: Deep merge (lodash-style)
- Arrays: Override (not merge)
- Primitives: Override

**Example:**
```yaml
# scholar-context.yml
learning_objectives:
  - "Objective A"
  - "Objective B"

# scholar-overrides/week-05.yml
learning_objectives:
  - "Week 5 specific objective"  # Replaces global

# Result for week 5:
learning_objectives:
  - "Week 5 specific objective"
```

---

## Config Validation Strategy

### Schema Hierarchy

```
teach-config.schema.json         # Master schema
├── course.schema.json          # Course metadata
├── semester_info.schema.json   # Semester schedule
└── dashboard.schema.json       # Dashboard config (NEW)

scholar-context.schema.json      # Scholar context (v5.16.0)
```

### Validation Workflow

```zsh
teach validate
# Validates all config files against schemas
# Caches results in .flow/.validation-cache.json

teach validate --fix
# Auto-fix common issues (formatting, types)

teach validate --strict
# Enforce all optional fields
```

---

## Migration Paths

### v5.14.0 → v5.15.0 (Dashboard)

**Manual migration:**
```yaml
# Add to existing .flow/teach-config.yml

dashboard:
  show_labs: true
  show_assignments: true
  enable_announcements: true
  fallback_message: "Check Syllabus..."
```

**Auto-migration:** Not needed, dashboard section is optional

---

### v5.15.0 → v5.16.0 (Scholar Consolidation)

**Auto-migration command:**
```bash
teach scholar migrate

📦 Migrating Scholar Context
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Found:
  • lesson-plan.yml (root)
  • .flow/lesson-plans/week-01.yml
  • .flow/lesson-plans/week-02.yml
  ... (12 more)

Creating: .flow/scholar-context.yml
  ✓ Merged global context
  ✓ Merged 14 week-specific contexts
  ✓ Validated schema

Backup created: .flow/.scholar-context-backup-2026-01-19.tar.gz

Next steps:
  1. Review: .flow/scholar-context.yml
  2. Test: teach lecture "Test" --week 1
  3. Delete old files: teach scholar migrate --cleanup
```

---

## Best Practices

### 1. Always Use teach-config.yml as SSOT

```yaml
# ✅ Good: Reference teach-config.yml
semester_info:
  weeks:
    - number: 5
      topic: "Factorial Designs"

# ❌ Bad: Duplicate in multiple files
```

### 2. Keep Generated Files in .flow/

```
.flow/
├── teach-config.yml        # Source
├── scholar-context.yml     # Source
├── semester-data.json      # Generated ← here
└── .validation-cache.json  # Generated ← here
```

**Rationale:** Clear separation, easy to .gitignore

### 3. Version Control Strategy

```gitignore
# .gitignore

# Never commit generated files
.flow/semester-data.json
.flow/.validation-cache.json

# Always commit source config
!.flow/teach-config.yml
!.flow/scholar-context.yml
```

### 4. Backup Before Migration

```bash
# Automatic backup on migration
teach scholar migrate
# Creates: .flow/.scholar-context-backup-YYYY-MM-DD.tar.gz

# Manual backup
teach backup create --scope config
```

### 5. Use Validation Hooks

```zsh
# Git pre-commit hook
.git/hooks/pre-commit:
#!/bin/bash
teach validate || {
    echo "❌ Config validation failed"
    exit 1
}
```

---

## Performance Implications

### Current (v5.14.0)

```
teach lecture "Topic" --week 5
│
├─ Load lesson-plan.yml (10ms)
├─ Load .flow/lesson-plans/week-05.yml (10ms)
├─ Load .flow/teach-config.yml (15ms)
└─ Merge contexts (5ms)
   Total: ~40ms
```

### Proposed (v5.16.0)

```
teach lecture "Topic" --week 5
│
├─ Load .flow/teach-config.yml (15ms)
├─ Load .flow/scholar-context.yml (20ms)
├─ Check .flow/scholar-overrides/week-05.yml (5ms, not found)
└─ Merge contexts (5ms)
   Total: ~45ms
```

**Impact:** Negligible (~5ms slower)

---

## Open Questions

### 1. Should dashboard announcements live in YAML or only JSON?

**Option A:** YAML (source), sync to JSON
```yaml
dashboard:
  announcements:
    - title: "Welcome"
      expires: "2026-01-26"
```

**Option B:** JSON only (generated)
```bash
teach dashboard announce "Welcome" --expires 2026-01-26
# Only updates .flow/semester-data.json
```

**Recommendation:** Option B (JSON only) for simplicity
- CLI announcements are ephemeral
- YAML would need sync logic
- Easier to manage programmatically

---

### 2. Where should per-week URLs be stored?

**Option A:** In teach-config.yml (structural)
```yaml
weeks:
  - number: 5
    lecture_url: "lectures/week-05.qmd"
```

**Option B:** Generated from conventions
```bash
# Convention: lectures/week-{NN}_{topic-slug}.qmd
teach dashboard generate --infer-urls
```

**Recommendation:** Option A (explicit) for v5.15.0, Option B (inferred) for v5.16.0+

---

### 3. Should Scholar auto-update teach-config.yml?

**Current:** Manual (Scholar creates file, user adds URL to config)

**Proposed:** Auto-update
```bash
teach lecture "Topic" --week 5
# Creates: lectures/week-05_topic.qmd
# Updates: teach-config.yml weeks[5].lecture_url
# Regenerates: semester-data.json
```

**Recommendation:** v5.16.0+ feature (not v5.15.0)

---

## Summary & Recommendations

### For v5.15.0 (Dashboard Feature)

| Decision | Recommendation |
|----------|----------------|
| **Config location** | Add `dashboard:` section to teach-config.yml |
| **File count** | Keep current file structure (no consolidation yet) |
| **Dashboard data** | Generated JSON only (no YAML source for announcements) |
| **Scholar integration** | Passive (no auto-update) |

**Impact:** +30 lines to teach-config.yml, 1 new generated file

---

### For v5.16.0+ (Future Consolidation)

| Area | Strategy |
|------|----------|
| **Scholar context** | Consolidate to `.flow/scholar-context.yml` |
| **Per-week overrides** | Optional `.flow/scholar-overrides/week-N.yml` |
| **Migration** | Auto-migration command: `teach scholar migrate` |
| **Validation** | Separate schemas, unified validation command |

**Benefits:**
- Clearer file organization
- Easier to navigate
- Better separation of concerns
- Reduced duplication

---

### Guiding Principles

1. **Start simple** - Don't over-engineer for v5.15.0
2. **Iterate thoughtfully** - Consolidate in v5.16.0 when patterns are clear
3. **Respect user edits** - Never lose manually-edited content
4. **Generate, don't duplicate** - Prefer derived data
5. **Validate early** - Catch config errors before generation

---

**End of Brainstorm**
