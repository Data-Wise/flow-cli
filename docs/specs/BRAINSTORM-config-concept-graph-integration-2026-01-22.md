# Config → Concept Graph Integration Brainstorm

**Generated:** 2026-01-22
**Context:** flow-cli teach analyze (Phase 0 → Phase 1 enhancement)
**Topic:** Auto-populate week numbers from `teach-config.yml` instead of requiring them in frontmatter

---

## Problem Statement

Currently, `teach analyze` Phase 0 resolves week numbers via:

1. **Filename parsing:** `week-05-lecture.qmd` → week 5
2. **Frontmatter field:** `week: 5` in YAML header
3. **Fallback:** Unknown (returns 0)

This creates **redundancy** — the instructor must maintain week numbers in two places:
- `teach-config.yml` → `structure.units[].weeks[]` (maps weeks to topics)
- Each `.qmd` file → `week:` frontmatter field

**Goal:** Make `teach-config.yml` the single source of truth for week assignments, with the concept graph auto-deriving week numbers from it.

---

## Current Data Sources

### teach-config.yml (authoritative schedule)

```yaml
structure:
  units:
    - name: 'Unit 1: Foundations'
      weeks: [1, 2, 3, 4]
      topics:
        - 'R basics & reproducible workflow'
        - 'Data visualization I'
        - 'Data wrangling'
        - 'Data visualization II'
```

**Key insight:** `weeks[i]` ↔ `topics[i]` is a positional mapping. Week 1 = topic[0], Week 2 = topic[1], etc.

### Lecture files (content)

```yaml
---
title: "Data Visualization I"
concepts:
  introduces:
    - id: ggplot2-basics
  requires:
    - r-environment
---
```

**Current:** Must add `week: 2` to frontmatter.
**Desired:** Derive week from config lookup.

---

## Options

### Option A: Topic-Title Matching (Fuzzy)

**Approach:** Match `.qmd` title to `structure.units[].topics[]` by string similarity.

**Resolution chain:**
1. Read `structure.units` from config
2. For each `.qmd` file, compare `title:` to all topics
3. Match → derive week number from positional index

**Pros:**
- Zero new frontmatter fields needed
- Works with existing config format
- No naming conventions required

**Cons:**
- Fuzzy matching is fragile (titles evolve, abbreviations differ)
- Ambiguity when topics are similar across weeks
- Performance cost of string comparison
- Hard to debug when matching fails silently

**Implementation complexity:** Medium (needs fuzzy matching logic)

---

### Option B: Explicit File→Week Mapping in Config (Recommended)

**Approach:** Add `files:` array to each unit's week definition.

**New config format:**

```yaml
structure:
  units:
    - name: 'Unit 1: Foundations'
      weeks:
        - number: 1
          topic: 'R basics & reproducible workflow'
          files: ['lectures/week-01-*.qmd']  # glob pattern
        - number: 2
          topic: 'Data visualization I'
          files: ['lectures/week-02-*.qmd']
```

**Resolution chain:**
1. Parse `structure.units[].weeks[].files[]` glob patterns
2. Match each `.qmd` file against patterns
3. Assign week number from matched entry

**Pros:**
- Explicit, no ambiguity
- Supports multiple files per week
- Glob patterns handle naming variations
- Easy to validate (unmatched files = warning)
- Single source of truth

**Cons:**
- Requires config schema change (breaking for existing configs)
- More verbose config (trade-off: clarity vs brevity)
- Instructor must maintain file list in config

**Implementation complexity:** Low (glob matching is straightforward in ZSH)

---

### Option C: Directory Convention (Zero-Config)

**Approach:** Derive week from directory structure.

**Expected layout:**

```
lectures/
├── week-01/
│   ├── lecture.qmd
│   └── lab.qmd
├── week-02/
│   └── lecture.qmd
```

**Resolution chain:**
1. Parse parent directory name for `week-NN` pattern
2. Fall back to filename pattern (`week-NN-*.qmd`)
3. Fall back to frontmatter `week:` field

**Pros:**
- Zero configuration needed
- Already partially implemented (filename parsing)
- Natural project organization

**Cons:**
- Forces specific directory structure
- Many courses use flat `lectures/` with named files
- Doesn't leverage config schedule data at all
- Doesn't solve the "SSOT" problem

**Implementation complexity:** Low (already mostly done)

---

### Option D: Hybrid — Config-Enriched Filename Convention

**Approach:** Keep filename-based resolution but validate/enrich with config data.

**How it works:**

1. **Primary:** Parse `week-NN` from filename (existing behavior)
2. **Enrich:** Cross-reference with `structure.units[].weeks[]` to get topic/unit context
3. **Validate:** Warn if file references a week not in config schedule
4. **Fallback:** If filename doesn't match, check `semester_info.weeks[]` array

**New config addition (optional):**

```yaml
semester_info:
  weeks:
    - number: 1
      start_date: '2026-01-12'
      topic: 'R basics'
    - number: 2
      start_date: '2026-01-19'
      topic: 'Visualization I'
```

This array already exists in the schema but is rarely populated in practice.

**Pros:**
- Non-breaking (filename parsing still works)
- Progressive enhancement (config adds context, doesn't replace)
- Validates consistency between filenames and config
- Catches drift (file says week 5, config has no week 5 topic)
- Reuses existing `semester_info.weeks[]` schema

**Cons:**
- Still requires `week-NN` in filenames as primary source
- Two sources exist (filename + config) even if config is "enrichment"
- Doesn't fully eliminate frontmatter `week:` field

**Implementation complexity:** Low-Medium

---

## Recommended Path

### Phase 0 (Current): Keep filename + frontmatter (no change)

Already planned and in progress. Ship the MVP without config integration.

### Phase 1 Enhancement: Option D (Hybrid Enrichment)

Add config cross-referencing as a **validation layer**, not a replacement:

```zsh
_get_week_from_file() {
    local file="$1"
    local config_file="$2"  # NEW: optional config path

    # 1. Primary: filename pattern
    local week=$(_parse_week_from_filename "$file")

    # 2. Fallback: frontmatter field
    [[ -z "$week" ]] && week=$(_parse_week_from_frontmatter "$file")

    # 3. NEW: Validate against config (if available)
    if [[ -n "$config_file" && -n "$week" ]]; then
        _validate_week_in_config "$week" "$config_file"
    fi

    # 4. NEW: Last resort - match title to config topics
    if [[ -z "$week" && -n "$config_file" ]]; then
        week=$(_resolve_week_from_config_topic "$file" "$config_file")
    fi

    echo "${week:-0}"
}
```

### Phase 2 (Future): Option B (Explicit Mapping)

Once the concept graph is proven useful, add the full `files:` mapping to config for courses that want zero-ambiguity week resolution.

---

## Integration Points

### Existing Infrastructure to Leverage

| Component | Location | What It Provides |
|-----------|----------|-----------------|
| `_calculate_current_week()` | `lib/teaching-utils.zsh` | Week-from-date math |
| `semester_info.weeks[]` | Schema | Per-week topic+date array |
| `structure.units[]` | Config | Week→topic positional map |
| `_parse_week_number()` | `lib/index-helpers.zsh` | Filename week extraction |
| Config validator | `lib/config-validator.zsh` | Schema validation |

### New Functions Needed (Phase 1)

```zsh
# Resolve week number using config as authority
_resolve_week_from_config() {
    local file="$1"
    local config="$2"
    # Try: filename → frontmatter → config topic match
}

# Validate week assignment against config schedule
_validate_week_in_config() {
    local week="$1"
    local config="$2"
    # Check: does config have this week? Is it a break week?
}

# Match file title to config topic (fuzzy-ish)
_resolve_week_from_config_topic() {
    local file="$1"
    local config="$2"
    # Extract title, compare to structure.units[].topics[]
}
```

### Schema Addition (for Phase 2)

```json
"structure": {
  "properties": {
    "units": {
      "items": {
        "properties": {
          "weeks": {
            "oneOf": [
              { "type": "array", "items": { "type": "integer" } },
              { "type": "array", "items": {
                "type": "object",
                "properties": {
                  "number": { "type": "integer" },
                  "topic": { "type": "string" },
                  "files": { "type": "array", "items": { "type": "string" } }
                }
              }}
            ]
          }
        }
      }
    }
  }
}
```

---

## Validation Rules (New)

When config integration is active, `teach analyze` gains these checks:

| Rule | Severity | Description |
|------|----------|-------------|
| `week-not-in-config` | WARNING | File claims week N but config has no week N |
| `break-week-content` | WARNING | Content assigned to a break week |
| `orphan-week` | INFO | Config week has no matching content files |
| `topic-mismatch` | INFO | File topic differs significantly from config topic |

---

## Decision Matrix

| Criterion | Option A (Fuzzy) | Option B (Explicit) | Option C (Dir) | Option D (Hybrid) |
|-----------|-----------------|--------------------|----|---------|
| Breaking changes | None | Schema change | None | None |
| Accuracy | Low | High | Medium | High |
| Config effort | None | Medium | None | Low |
| SSOT achieved | Partial | Full | No | Partial → Full |
| Phase 0 compatible | Yes | No | Yes | Yes |
| Validation value | Low | High | Low | High |

---

## Quick Wins (Immediate)

1. **Populate `semester_info.weeks[]`** in the config template — currently empty in template but defined in schema
2. **Add topic field** to `semester_info.weeks[]` items (already in schema)
3. **Cross-reference in `_build_concept_graph()`** — add config awareness during graph construction

## Next Steps

1. [ ] Finish Phase 0 implementation (current priority)
2. [ ] Add `_validate_week_in_config()` to Phase 1 plan
3. [ ] Update schema examples to show populated `semester_info.weeks[]`
4. [ ] Design `teach analyze --validate-schedule` flag for config↔content consistency
5. [ ] Consider whether `structure.units` should be canonical or `semester_info.weeks`

---

**Recommended:** Start with Option D in Phase 1 (non-breaking enrichment), graduate to Option B in Phase 2 if the concept graph proves its value. This avoids premature config schema changes while still delivering validation feedback.
