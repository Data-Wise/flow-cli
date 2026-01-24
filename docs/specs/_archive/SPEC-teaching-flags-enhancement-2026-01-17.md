# SPEC: Teaching Flags Enhancement

**Feature:** Content customization and topic/week flags for teach dispatcher
**Status:** Draft
**Created:** 2026-01-17
**From Brainstorm:** Deep interactive session (16 questions)
**Target Release:** flow-cli v5.13.0 (Phase 1.5 of plugin-dispatchers)
**Parent Spec:** [SPEC-teaching-integration-2026-01-17.md](SPEC-teaching-integration-2026-01-17.md)

---

## Metadata

| Field | Value |
|-------|-------|
| **Status** | Draft |
| **Priority** | High (enables granular content control) |
| **Complexity** | Medium (8-10 hours) |
| **Risk Level** | Low (additive to existing teach dispatcher) |
| **Dependencies** | teach-dispatcher.zsh, Scholar plugin |
| **Target Users** | Academic instructors |
| **Branch Strategy** | feature/teaching-flags → dev → main |

---

## Overview

Enhance the teach dispatcher with:
1. **Content customization flags** - 9 individual flags + 4 style presets
2. **Topic/Week flags** - Explicit topic selection with lesson plan integration
3. **Hybrid flag system** - Presets provide defaults, individual flags add/remove

---

## Design Decisions (From Brainstorm)

### Content Flag Structure

**Decision:** Hybrid approach - presets for common combos + individual flags for fine-tuning

### Available Presets

**Decision:** 4 presets (conceptual, computational, rigorous, applied)

### Override Behavior

**Decision:** Add and remove - `--style rigorous --no-proof` removes proof from rigorous preset

### Default Behavior

**Decision:** In `-i` mode prompt for style; otherwise use balanced default

### Topic/Week Relationship

**Decision:** Must specify either `--topic` or `--week` (no auto-detection)

### Lesson Plan Usage

**Decision:** Lesson plan provides defaults, flags override specific items

### Diagrams

**Decision:** Always opt-in - `--diagrams` flag required; never auto-included

### Conflict Handling

**Decision:** Conflicting flags cause validation error with helpful message

### Topic Override

**Decision:** Explicit `--topic` means don't use lesson plan at all

### Missing Lesson Plan

**Decision:** Prompt interactively - "No plan found. Continue with topic '[X]'? [Y/n]"

---

## Content Flags (9 Total)

### Individual Content Flags

| Flag | Short | Description | Example |
|------|-------|-------------|---------|
| `--explanation` | `-e` | Conceptual explanations | `teach slides -w 8 --explanation` |
| `--proof` | | Mathematical proofs | `teach slides -w 8 --proof` |
| `--math` | `-m` | Formal math notation/formulas | `teach slides -w 8 --math` |
| `--examples` | `-x` | Worked numerical examples | `teach slides -w 8 --examples` |
| `--code` | `-c` | Code demonstrations (R/Python) | `teach slides -w 8 --code` |
| `--diagrams` | `-d` | Visual diagrams/plots | `teach slides -w 8 --diagrams` |
| `--practice-problems` | `-p` | Practice exercises | `teach slides -w 8 --practice-problems` |
| `--definitions` | | Formal definitions | `teach slides -w 8 --definitions` |
| `--references` | `-r` | Citations/further reading | `teach slides -w 8 --references` |

### Negation Flags

Each content flag has a negation form:

```bash
--no-explanation
--no-proof
--no-math
--no-examples
--no-code
--no-diagrams
--no-practice-problems
--no-definitions
--no-references
```

---

## Style Presets (4 Total)

### Preset Definitions

| Preset | Includes | Use Case |
|--------|----------|----------|
| **conceptual** | explanation, definitions, examples | Intuition-focused, theory introduction |
| **computational** | explanation, examples, code, practice-problems | Hands-on, lab-style |
| **rigorous** | definitions, explanation, math, proof | Graduate level, formal treatment |
| **applied** | explanation, examples, code, practice-problems | Real-world applications |

**Note:** `diagrams` and `references` are always opt-in, never preset-included.

### Usage

```bash
# Use preset
teach slides -w 8 --style rigorous

# Preset + additions
teach slides -w 8 --style conceptual --code --diagrams

# Preset + removals
teach slides -w 8 --style rigorous --no-proof

# Preset + both
teach slides -w 8 --style computational --diagrams --no-practice-problems
```

---

## Topic/Week Flags

### Flag Definitions

| Flag | Short | Description | Example |
|------|-------|-------------|---------|
| `--topic` | `-t` | Explicit topic (bypasses lesson plan) | `teach slides --topic "Regression"` |
| `--week` | `-w` | Week number (uses lesson plan if exists) | `teach slides -w 8` |

### Interaction Rules

1. **Must specify one:** Either `--topic` or `--week` is required
2. **--topic takes precedence:** If both given, `--week` is ignored
3. **--topic bypasses lesson plan:** Explicit topic means no lesson plan lookup

### Week Flag Behavior

```
--week 8 given
    │
    ├── Lesson plan exists (.flow/lesson-plans/week-08.yml)
    │   └── Merge plan defaults with flags
    │
    └── No lesson plan
        └── Prompt: "No plan found. Continue with topic 'X'? [Y/n]"
            └── If Y: Use topic from semester_info.weeks
            └── If N: Abort
```

---

## Lesson Plan Schema

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

### Minimal Schema (From Config)

When no lesson plan file exists, fall back to `semester_info.weeks`:

```yaml
# In teach-config.yml
semester_info:
  weeks:
    - number: 8
      start_date: "2026-03-02"
      topic: "Multiple Regression"  # Used as fallback
```

---

## Flag Validation

### Conflict Detection

```bash
# These cause errors:
teach slides -w 8 --proof --no-proof
# Error: Conflicting flags: --proof and --no-proof

teach slides -w 8 --style rigorous --style conceptual
# Error: Multiple --style flags. Use one preset with individual overrides.

teach slides  # No --topic or --week
# Error: Must specify --topic or --week
```

### Validation Messages

```
Error: Conflicting flags detected

  You specified both --proof and --no-proof

Fix: Remove one of the conflicting flags

  teach slides -w 8 --style rigorous --no-proof  ✓
```

---

## Implementation

### Flag Parsing

```zsh
# Add to TEACH_SLIDES_FLAGS
typeset -gA TEACH_SLIDES_FLAGS=(
    # Existing flags...

    # Topic/Week (mutually preferred)
    [--topic]="string"
    [-t]="--topic"
    [--week]="integer"
    [-w]="--week"

    # Style preset
    [--style]="enum:conceptual,computational,rigorous,applied"

    # Content flags (boolean)
    [--explanation]="boolean"
    [-e]="--explanation"
    [--no-explanation]="boolean"
    [--proof]="boolean"
    [--no-proof]="boolean"
    [--math]="boolean"
    [-m]="--math"
    [--no-math]="boolean"
    [--examples]="boolean"
    [-x]="--examples"
    [--no-examples]="boolean"
    [--code]="boolean"
    [-c]="--code"
    [--no-code]="boolean"
    [--diagrams]="boolean"
    [-d]="--diagrams"
    [--no-diagrams]="boolean"
    [--practice-problems]="boolean"
    [-p]="--practice-problems"
    [--no-practice-problems]="boolean"
    [--definitions]="boolean"
    [--no-definitions]="boolean"
    [--references]="boolean"
    [-r]="--references"
    [--no-references]="boolean"
)
```

### Content Resolution Function

```zsh
# Resolve final content set from preset + flags
_teach_resolve_content() {
    local style="${1:-balanced}"
    shift
    local -a flags=("$@")

    # Start with preset
    local -A content
    case "$style" in
        conceptual)
            content=(
                [explanation]=1 [definitions]=1 [examples]=1
            ) ;;
        computational)
            content=(
                [explanation]=1 [examples]=1 [code]=1 [practice-problems]=1
            ) ;;
        rigorous)
            content=(
                [definitions]=1 [explanation]=1 [math]=1 [proof]=1
            ) ;;
        applied)
            content=(
                [explanation]=1 [examples]=1 [code]=1 [practice-problems]=1
            ) ;;
        balanced|*)
            content=(
                [explanation]=1 [examples]=1 [math]=1
            ) ;;
    esac

    # Apply flag overrides
    for flag in "${flags[@]}"; do
        case "$flag" in
            --no-*)
                local key="${flag#--no-}"
                unset "content[$key]"
                ;;
            --*)
                local key="${flag#--}"
                content[$key]=1
                ;;
        esac
    done

    # Return as comma-separated list
    print "${(kj:,:)content}"
}
```

### Lesson Plan Loading

```zsh
# Load lesson plan for week
_teach_load_lesson_plan() {
    local week="$1"
    local plan_file=".flow/lesson-plans/week-$(printf '%02d' $week).yml"

    if [[ -f "$plan_file" ]]; then
        # Parse YAML (requires yq)
        local topic=$(yq '.topic' "$plan_file")
        local style=$(yq '.style // "balanced"' "$plan_file")
        local objectives=$(yq '.objectives | join("; ")' "$plan_file")

        # Return as associative array
        typeset -gA LESSON_PLAN=(
            [topic]="$topic"
            [style]="$style"
            [objectives]="$objectives"
            [file]="$plan_file"
        )
        return 0
    fi

    return 1  # No plan found
}
```

---

## UI/UX

### Interactive Style Selection

When `-i` mode and no `--style` flag:

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

---

## Command Examples

### Basic Usage

```bash
# Explicit topic (no lesson plan)
teach slides --topic "Linear Regression" --style conceptual

# Week with lesson plan
teach slides -w 8  # Uses week 8 plan defaults

# Week with style override
teach slides -w 8 --style rigorous
```

### Content Customization

```bash
# Add to preset
teach slides -w 8 --style conceptual --code --diagrams

# Remove from preset
teach slides -w 8 --style rigorous --no-proof

# Full custom (no preset)
teach slides -w 8 --explanation --examples --code

# Kitchen sink
teach slides -w 8 --style computational --diagrams --definitions --no-practice-problems
```

### Interactive Mode

```bash
# Full interactive (prompts for style)
teach slides -i -w 8

# Interactive with preset (skips style prompt)
teach slides -i -w 8 --style applied
```

---

## Testing

### Unit Tests

```bash
# Flag parsing
test_teach_parse_flags()
test_teach_validate_flags()
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
```

---

## Implementation Phases

### Phase 1: Flag Infrastructure (3h)

- [ ] Add flags to TEACH_*_FLAGS
- [ ] Implement `_teach_validate_content_flags()`
- [ ] Implement conflict detection
- [ ] Add tests for flag parsing

### Phase 2: Preset System (2h)

- [ ] Define preset content maps
- [ ] Implement `_teach_resolve_content()`
- [ ] Add interactive style selection
- [ ] Add tests for preset resolution

### Phase 3: Lesson Plan Integration (2h)

- [ ] Implement `_teach_load_lesson_plan()`
- [ ] Create lesson plan schema validation
- [ ] Add missing plan prompt
- [ ] Add tests for lesson plan loading

### Phase 4: Scholar Integration (2h)

- [ ] Pass resolved content to Scholar command
- [ ] Update `_teach_scholar_wrapper()` with content flags
- [ ] End-to-end testing
- [ ] Documentation updates

---

## Related Documents

- [Teaching Integration Spec](SPEC-teaching-integration-2026-01-17.md) - Parent spec
- [Main Plugin Integration Spec](../SPEC-claude-code-plugin-integration-2026-01-17.md) - Overview
- [Teach Dispatcher Reference](../../reference/TEACH-DISPATCHER-REFERENCE.md) - Current implementation

---

## History

| Date | Change | Author |
|------|--------|--------|
| 2026-01-17 | Initial spec from 16-question brainstorm | Claude + DT |

---

## Appendix: Complete Flag Reference

### Topic/Week Flags

| Flag | Type | Required | Description |
|------|------|----------|-------------|
| `--topic`, `-t` | string | One of these | Explicit topic (bypasses lesson plan) |
| `--week`, `-w` | integer | required | Week number (uses lesson plan if exists) |

### Style Preset

| Flag | Type | Values | Default |
|------|------|--------|---------|
| `--style` | enum | conceptual, computational, rigorous, applied | balanced (implicit) |

### Content Flags

| Flag | Short | Negation | In Presets |
|------|-------|----------|------------|
| `--explanation` | `-e` | `--no-explanation` | conceptual, computational, rigorous, applied |
| `--proof` | | `--no-proof` | rigorous |
| `--math` | `-m` | `--no-math` | rigorous |
| `--examples` | `-x` | `--no-examples` | conceptual, computational, applied |
| `--code` | `-c` | `--no-code` | computational, applied |
| `--diagrams` | `-d` | `--no-diagrams` | (always opt-in) |
| `--practice-problems` | `-p` | `--no-practice-problems` | computational, applied |
| `--definitions` | | `--no-definitions` | conceptual, rigorous |
| `--references` | `-r` | `--no-references` | (always opt-in) |
