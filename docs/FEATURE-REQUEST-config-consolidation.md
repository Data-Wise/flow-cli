# Feature Request: Teaching Config Consolidation

**Date:** 2026-01-27
**Author:** Davood Tofighi, Ph.D.
**Priority:** Medium
**Effort:** Medium (~2-3 hours)
**Related:** [STAT 545 Proposal](file:///Users/dt/projects/teaching/stat-545/docs/PROPOSAL-config-consolidation.md)

---

## Executive Summary

Update flow-cli to support the new unified teaching config structure where:

1. `.flow/config-teach.yml` replaces `.flow/teach-config.yml` (merged with teaching style)
2. `.flow/lesson-plans.yml` contains all weeks in a single file (extracted from teach-config.yml)

This enables a single shared config read by both flow-cli and Scholar plugin.

---

## Current Behavior

```yaml
# .flow/teach-config.yml (657 lines)
course:
  name: "STAT 545"
semester_info:
  weeks:
    - number: 1
      topic: "intro"
      # ... 14 weeks embedded here
```

**Problem:** Lesson plans embedded in config, teaching style in separate `.claude/` file.

---

## Proposed Behavior

```yaml
# .flow/config-teach.yml (~200 lines)
course:
  name: "STAT 545"
lesson_plans: "lesson-plans.yml"  # Reference to separate file
teaching_style:
  pedagogical_approach:
    primary: "problem-based"
command_overrides:
  slides:
    style: "rigorous"
```

```yaml
# .flow/lesson-plans.yml (~450 lines)
weeks:
  - number: 1
    topic: "intro"
  - number: 2
    topic: "crd"
```

---

## Implementation

### Files to Modify

| File | Changes |
|------|---------|
| `lib/dispatchers/teach-dispatcher.zsh` | Update config paths, lesson plan loading |
| `lib/templates/teaching/teach-config.schema.json` | Add new schema properties |

### Specific Changes

#### 1. Update Config File Path (14 locations)

**Lines:** 539, 680, 1263, 1267, 1725, 2515, 2540, 2665, 2986, 3411, 3435, 3448, 3586, 3607, 4861, 4904

```zsh
# BEFORE
local config_file=".flow/teach-config.yml"

# AFTER
local config_file=".flow/config-teach.yml"
```

#### 2. Update `_teach_load_lesson_plan()` (Line 491)

```zsh
# BEFORE
local plan_file=".flow/lesson-plans/week-${week}.yml"

# AFTER - read from single file
_teach_load_lesson_plan() {
    local week="$1"
    local plans_file=".flow/lesson-plans.yml"

    if [[ ! -f "$plans_file" ]]; then
        return 1
    fi

    # Extract specific week from consolidated file
    local week_data=$(yq ".weeks[] | select(.number == $week)" "$plans_file" 2>/dev/null)
    if [[ -z "$week_data" ]]; then
        return 1
    fi

    # Parse week data
    LESSON_PLAN_TOPIC=$(echo "$week_data" | yq '.topic // ""')
    LESSON_PLAN_TITLE=$(echo "$week_data" | yq '.title // ""')
    LESSON_PLAN_STYLE=$(echo "$week_data" | yq '.style // ""')
}
```

#### 3. Add New Helper Functions

```zsh
# Read teaching style from unified config
_teach_get_style() {
    local key="$1"
    local config_file=".flow/config-teach.yml"
    yq ".teaching_style.$key" "$config_file" 2>/dev/null
}

# Read command-specific overrides
_teach_get_command_override() {
    local command="$1"
    local key="$2"
    local config_file=".flow/config-teach.yml"
    yq ".command_overrides.$command.$key" "$config_file" 2>/dev/null
}
```

#### 4. Update Schema

**File:** `lib/templates/teaching/teach-config.schema.json`

Add these properties:

```json
{
  "properties": {
    "lesson_plans": {
      "type": "string",
      "description": "Path to lesson plans file (relative to .flow/)"
    },
    "teaching_style": {
      "type": "object",
      "properties": {
        "pedagogical_approach": { "type": "object" },
        "explanation_style": { "type": "object" },
        "notation_conventions": { "type": "object" }
      }
    },
    "command_overrides": {
      "type": "object",
      "properties": {
        "lecture": { "type": "object" },
        "slides": { "type": "object" },
        "quiz": { "type": "object" },
        "exam": { "type": "object" }
      }
    }
  }
}
```

---

## Backwards Compatibility

Support both old and new config locations during transition:

```zsh
_teach_find_config() {
    # Priority 1: New unified config
    if [[ -f ".flow/config-teach.yml" ]]; then
        echo ".flow/config-teach.yml"
        return 0
    fi

    # Priority 2: Legacy config
    if [[ -f ".flow/teach-config.yml" ]]; then
        echo ".flow/teach-config.yml"
        return 0
    fi

    return 1
}
```

---

## Testing

```bash
# Verify config loading
flow teach status
flow teach doctor

# Verify lesson plan loading
flow teach slides "Test" --week 2 --dry-run

# Validate YAML
yq '.' .flow/config-teach.yml
yq '.weeks | length' .flow/lesson-plans.yml
```

---

## Benefits

- Single shared config with Scholar plugin
- Lesson plans in dedicated file (easier to edit)
- Teaching style in pure YAML (not markdown frontmatter)
- R packages deduplicated

---

## Related

- [Scholar Plugin Feature Request](file:///Users/dt/projects/dev-tools/flow-cli/docs/FEATURE-REQUEST-scholar-config-consolidation.md)
- [STAT 545 Full Proposal](file:///Users/dt/projects/teaching/stat-545/docs/PROPOSAL-config-consolidation.md)
