# Feature Request: Scholar Plugin Config Consolidation

**Date:** 2026-01-27
**Author:** Davood Tofighi, Ph.D.
**Priority:** Medium
**Effort:** Medium (~2-3 hours)
**Target:** Scholar Plugin (Homebrew: `/opt/homebrew/opt/scholar/`)
**Related:** [STAT 545 Proposal](file:///Users/dt/projects/teaching/stat-545/docs/PROPOSAL-config-consolidation.md)

---

## Executive Summary

Update Scholar plugin to read teaching style from the new unified config location:

- **Primary:** `.flow/config-teach.yml` (pure YAML)
- **Fallback:** `.claude/teaching-style.local.md` (legacy, markdown frontmatter)

This enables a single shared config read by both flow-cli and Scholar plugin.

---

## Current Behavior

Scholar reads teaching style from markdown with YAML frontmatter:

```markdown
<!-- .claude/teaching-style.local.md -->
---
teaching_style:
  pedagogical_approach:
    primary: "problem-based"
command_overrides:
  slides:
    style: "rigorous"
---

# Teaching Style Guide
...
```

---

## Proposed Behavior

Scholar first checks for pure YAML config, then falls back to legacy:

```yaml
# .flow/config-teach.yml (Priority 1)
teaching_style:
  pedagogical_approach:
    primary: "problem-based"
command_overrides:
  slides:
    style: "rigorous"
```

---

## Implementation

### Files to Modify

| File | Location | Changes |
|------|----------|---------|
| `style-loader.js` | `src/teaching/config/` | Read from `.flow/config-teach.yml` |
| `lesson-plan-loader.js` | `src/teaching/utils/` | Support single-file lesson plans |

### Specific Changes

#### 1. Update `loadCourseStyle()` in `style-loader.js`

**Current (lines 150-155):**

```javascript
export function loadCourseStyle(courseRoot) {
  if (!courseRoot) return null;
  const coursePath = join(courseRoot, '.claude', 'teaching-style.local.md');
  return readTeachingStyleFile(coursePath);
}
```

**Proposed:**

```javascript
export function loadCourseStyle(courseRoot) {
  if (!courseRoot) return null;

  // Priority 1: New unified config location (pure YAML)
  const unifiedPath = join(courseRoot, '.flow', 'config-teach.yml');
  if (existsSync(unifiedPath)) {
    const config = readYamlFile(unifiedPath);
    return config?.teaching_style || null;
  }

  // Priority 2: Legacy location (markdown frontmatter)
  const legacyPath = join(courseRoot, '.claude', 'teaching-style.local.md');
  if (existsSync(legacyPath)) {
    return readTeachingStyleFile(legacyPath);
  }

  return null;
}
```

#### 2. Add `readYamlFile()` Helper

```javascript
import { readFileSync, existsSync } from 'fs';
import { parse as parseYaml } from 'yaml';

function readYamlFile(filePath) {
  try {
    const content = readFileSync(filePath, 'utf8');
    return parseYaml(content);
  } catch (error) {
    console.error(`[StyleLoader] Error reading YAML: ${filePath}`, error.message);
    return null;
  }
}
```

#### 3. Update `extractCommandOverrides()`

**Current (lines 163-169):**

```javascript
export function extractCommandOverrides(courseStyle, command) {
  return courseStyle?.command_overrides?.[command] || null;
}
```

**Proposed:**

```javascript
export function extractCommandOverrides(courseStyle, command, courseRoot = null) {
  // First try courseStyle (from teaching_style section)
  if (courseStyle?.command_overrides?.[command]) {
    return courseStyle.command_overrides[command];
  }

  // Try top-level command_overrides from unified config
  if (courseRoot) {
    const unifiedPath = join(courseRoot, '.flow', 'config-teach.yml');
    if (existsSync(unifiedPath)) {
      const config = readYamlFile(unifiedPath);
      return config?.command_overrides?.[command] || null;
    }
  }

  return null;
}
```

#### 4. Update Lesson Plan Loader for Single File

**File:** `src/teaching/utils/lesson-plan-loader.js`

**Add single-file support:**

```javascript
// Add to LESSON_PLAN_LOCATIONS (lines 33-44)
const LESSON_PLAN_LOCATIONS = [
  // Single file format (new)
  { type: 'file', path: '.flow/lesson-plans.yml' },
  // Directory formats (legacy)
  { type: 'dir', path: 'content/lesson-plans' },
  { type: 'dir', path: '.flow/lesson-plans' },
  { type: 'dir', path: 'lesson-plans' }
];

export function findLessonPlanSource(courseRoot) {
  for (const location of LESSON_PLAN_LOCATIONS) {
    const fullPath = join(courseRoot, location.path);
    if (location.type === 'file' && existsSync(fullPath)) {
      return { type: 'file', path: fullPath };
    }
    if (location.type === 'dir' && existsSync(fullPath) && statSync(fullPath).isDirectory()) {
      return { type: 'dir', path: fullPath };
    }
  }
  return null;
}

// New function for single-file loading
export function loadLessonPlanFromFile(filePath, weekId) {
  const content = readFileSync(filePath, 'utf8');
  const data = parseYaml(content);

  const weekNum = parseWeekId(weekId);
  const weekPlan = data?.weeks?.find(w => w.number === weekNum);

  if (!weekPlan) {
    return null;
  }

  return {
    ...weekPlan,
    _source: filePath,
    _format: 'single-file'
  };
}

// Update main loader
export function loadLessonPlan(weekId, courseRoot = process.cwd()) {
  const source = findLessonPlanSource(courseRoot);

  if (!source) return null;

  if (source.type === 'file') {
    return loadLessonPlanFromFile(source.path, weekId);
  }

  // Existing directory-based loading
  return loadLessonPlanFile(findLessonPlanFile(source.path, weekId));
}
```

---

## 4-Layer System Compatibility

The 4-layer teaching style system remains unchanged:

| Layer | Source | Priority |
|-------|--------|----------|
| 1 (Global) | `~/.claude/CLAUDE.md` | Lowest |
| 2 (Course) | `.flow/config-teach.yml` OR `.claude/teaching-style.local.md` | Medium |
| 3 (Command) | `command_overrides` in Layer 2 file | High |
| 4 (Lesson) | `teaching_style_overrides` in lesson plan | Highest |

Only Layer 2 location changes; the merge logic in `mergeTeachingStyles()` remains the same.

---

## Testing

```bash
# In Claude Code session
/teach:lecture "Test Topic" --week 2 --dry-run
/teach:slides "Test Topic" --week 2 --dry-run

# Verify style loading
# (Check console output for "[StyleLoader] Loading from: .flow/config-teach.yml")
```

---

## Backwards Compatibility

- Legacy `.claude/teaching-style.local.md` still works (fallback)
- Existing courses continue to function without changes
- New courses can use unified config

---

## Benefits

- Single source of truth for teaching config
- Pure YAML (no markdown parsing needed)
- Shared config with flow-cli
- Cleaner file structure

---

## Related

- [flow-cli Feature Request](./FEATURE-REQUEST-config-consolidation.md)
- [STAT 545 Full Proposal](file:///Users/dt/projects/teaching/stat-545/docs/PROPOSAL-config-consolidation.md)

---

## Source Code References

**Scholar Plugin Location:** `/opt/homebrew/opt/scholar/libexec/`

| File | Key Functions |
|------|---------------|
| `src/teaching/config/style-loader.js` | `loadCourseStyle()` (L150), `extractCommandOverrides()` (L163), `mergeTeachingStyles()` (L227) |
| `src/teaching/utils/lesson-plan-loader.js` | `findLessonPlansDir()` (L33), `loadLessonPlan()` (L329) |
| `src/teaching/generators/lecture-notes.js` | `loadTeachingStyle()` (L695) - main consumer |
