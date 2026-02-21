# RFC: Scholar `--config` Flag for Bidirectional Config Integration

**Status:** Draft
**Target:** Scholar v2.2.0
**Date:** 2026-01-15
**Author:** flow-cli maintainers
**Related:** flow-cli v5.9.0 config validation

---

## Summary

Propose adding a `--config` flag to all Scholar teaching commands to enable bidirectional configuration sync with flow-cli. This allows Scholar to read course context from `teach-config.yml` and validate it using a shared JSON Schema.

---

## Motivation

### Current State (v5.9.0)

flow-cli wraps Scholar commands and passes individual flags:

```bash
# flow-cli → Scholar (current)
teach exam "Hypothesis Testing" --format quarto --output exams/

# Translates to:
claude --print "/teaching:exam 'Hypothesis Testing' --format quarto --output exams/"
```diff

**Limitations:**
- ❌ Scholar has no access to full course context (name, semester, grading, etc.)
- ❌ No shared validation of config structure
- ❌ Flags duplicated across flow-cli and Scholar
- ❌ Scholar generates content without course-specific context

### Desired State (v2.2.0)

Scholar reads shared config and generates contextually aware content:

```bash
# flow-cli → Scholar (proposed)
teach exam "Hypothesis Testing"

# Translates to:
claude --print "/teaching:exam 'Hypothesis Testing' --config teach-config.yml"
```diff

**Benefits:**
- ✅ Scholar reads course name, semester, grading policy, style preferences
- ✅ Shared JSON Schema validation on both sides
- ✅ Single source of truth for course configuration
- ✅ Contextually aware content generation
- ✅ Cleaner command interface (fewer flags)

---

## Proposed Changes

### 1. Add `--config` Flag to All Teaching Commands

All Scholar teaching skills accept an optional `--config` flag:

```javascript
// In Scholar skill frontmatter
{
  "arguments": [
    {
      "name": "topic",
      "type": "string",
      "required": true,
      "description": "Exam topic or title"
    },
    {
      "name": "config",
      "type": "string",
      "required": false,
      "description": "Path to teach-config.yml (optional)"
    }
  ]
}
```diff

**Affected Commands:**
- `/teaching:exam`
- `/teaching:quiz`
- `/teaching:slides`
- `/teaching:assignment`
- `/teaching:syllabus`
- `/teaching:rubric`
- `/teaching:feedback`
- `/teaching:lecture` (when implemented)
- `/teaching:demo`

### 2. JSON Schema Validation in Scholar

Scholar should validate the config using the shared schema:

**Schema Location:** `https://github.com/Data-Wise/flow-cli/blob/main/lib/templates/teaching/teach-config.schema.json`

**Validation Logic:**

```python
# Pseudocode for Scholar
def validate_config(config_path):
    """Validate teach-config.yml against JSON Schema"""
    schema = load_schema_from_url(SCHEMA_URL)
    config = yaml.safe_load(config_path)

    # Validate full config
    jsonschema.validate(config, schema)

    # Additional Scholar-specific checks
    if 'scholar' in config:
        validate_scholar_section(config['scholar'])

    return config
```diff

**Error Handling:**
- Invalid config → Show clear error with field name and expected format
- Missing config → Use sensible defaults, warn user
- Partial config → Validate what exists, use defaults for missing fields

### 3. Config Ownership Protocol

The schema defines clear ownership boundaries:

| Section | Owner | Scholar Can Read? | Scholar Can Write? |
|---------|-------|-------------------|-------------------|
| `course` | flow-cli | ✅ Yes (read-only) | ❌ No |
| `semester_info` | flow-cli | ✅ Yes (read-only) | ❌ No |
| `branches` | flow-cli | ❌ No | ❌ No |
| `deployment` | flow-cli | ❌ No | ❌ No |
| `automation` | flow-cli | ❌ No | ❌ No |
| **`scholar`** | **Scholar** | ✅ Yes | ✅ Yes (owns it) |
| `examark` | examark | ✅ Yes (read-only) | ❌ No |

**Scholar Section Structure:**

```yaml
scholar:
  course_info:
    level: "graduate"              # undergraduate | graduate | both
    field: "Statistics"
    difficulty: "intermediate"     # beginner | intermediate | advanced
    credits: 3

  style:
    tone: "formal"                 # formal | conversational
    notation: "statistical"        # statistical | mathematical | standard
    examples: true                 # Include worked examples

  topics:                          # Course topics for content scope
    - "Hypothesis Testing"
    - "Regression Analysis"
    - "ANOVA"

  grading:                         # Grade distribution (must sum to 100)
    exams: 40
    homework: 30
    project: 20
    participation: 10
```diff

**Protocol:**
- Scholar can READ `course.*` for context (course name, semester, instructor)
- Scholar OWNS `scholar.*` section (can read/write)
- Scholar can SUGGEST changes to `course.*` but cannot modify
- flow-cli validates entire config on save

### 4. Enhanced Content Generation

With config access, Scholar generates more contextually aware content:

**Example 1: Exam Generation**

```bash
teach exam "Hypothesis Testing"
```bash

Scholar reads config and generates:

```markdown
# STAT 440 - Regression Analysis
## Midterm Exam: Hypothesis Testing
**Semester:** Fall 2024
**Instructor:** Dr. Smith
**Duration:** 120 minutes
**Points:** 100

[Exam follows course grading policy: 40% exams]
[Notation style: Statistical (as configured)]
[Difficulty: Intermediate (as configured)]
```text

**Example 2: Syllabus Generation**

```bash
teach syllabus
```diff

Scholar reads ENTIRE config (course, semester_info, grading) and generates complete syllabus with correct dates, grading breakdown, course info.

---

## Implementation Plan

### Phase 1: Schema Support (Week 1)

- [ ] Add JSON Schema file to Scholar repository
- [ ] Implement YAML → JSON Schema validation
- [ ] Add `--config` flag to `/teaching:exam` (pilot)
- [ ] Test with flow-cli v5.9.0+

### Phase 2: Full Command Support (Week 2)

- [ ] Add `--config` to all teaching commands
- [ ] Update skill frontmatter with config argument
- [ ] Implement config ownership checks (warn on Scholar section edits)

### Phase 3: Enhanced Content Generation (Week 3-4)

- [ ] Update content templates to use config context
- [ ] Implement course-aware defaults
- [ ] Add grading policy integration
- [ ] Test with real course configs

### Phase 4: Documentation & Release (Week 4)

- [ ] Document `--config` flag usage
- [ ] Create migration guide for existing users
- [ ] Update API reference
- [ ] Release Scholar v2.2.0

---

## Acceptance Criteria

- [ ] All teaching commands accept `--config` flag
- [ ] Config validation uses shared JSON Schema
- [ ] Invalid config shows clear error messages
- [ ] Scholar respects config ownership (read-only vs read-write)
- [ ] Generated content includes course context (name, semester, etc.)
- [ ] Grading policy from config appears in generated syllabi/rubrics
- [ ] Style preferences (tone, notation) affect content generation
- [ ] Backward compatible (works without `--config` flag)
- [ ] flow-cli v5.9.0+ integration tested

---

## Migration Path

### For Existing Users

**Before (no config):**

```bash
claude --print "/teaching:exam 'Topic' --format quarto --difficulty intermediate"
```bash

**After (with config):**

```bash
# Create teach-config.yml once
teach init "STAT 440"

# Scholar reads course context automatically
teach exam "Topic"
```diff

**Backward Compatibility:**
- Commands work without `--config` flag (use defaults)
- Flags override config values when both provided
- No breaking changes to existing workflows

---

## Technical Details

### Config Resolution Order

When both config and flags provided:
1. Load defaults (Scholar built-in)
2. Merge config file values (if `--config` provided)
3. Override with command-line flags (highest priority)

Example:

```bash
# Config has: tone: "formal"
teach exam "Topic" --config teach-config.yml --tone conversational

# Result: Uses "conversational" (flag overrides config)
```text

### Error Messages

**Invalid Schema:**

```text
❌ Config validation failed: teach-config.yml

  • scholar.grading must sum to 100 (currently 95)
  • course.semester must be one of: Spring, Summer, Fall, Winter (got: "spring")

Fix the config file and try again.
```text

**Missing Scholar Section:**

```text
⚠️  No 'scholar' section in teach-config.yml
Using default settings. Add a 'scholar:' section to customize content generation.
```

### Hash-Based Change Detection

flow-cli tracks config changes via SHA-256 hash. Scholar can:
1. Read the hash from config metadata
2. Regenerate content when hash changes
3. Cache generated content by config hash

---

## Open Questions

1. **Config Sync:** Should Scholar write back to `scholar:` section? Or should flow-cli own all edits?
   - **Proposal:** flow-cli owns all edits, Scholar reads only (safer)

2. **Schema Versioning:** How to handle schema updates?
   - **Proposal:** Use `$schema` version field, Scholar validates against correct version

3. **Partial Configs:** How much of `scholar:` section is required?
   - **Proposal:** All fields optional, Scholar uses sensible defaults

4. **Multi-Course Support:** How to handle multiple courses in one repo?
   - **Proposal:** Out of scope for v2.2.0, each course = separate directory with own config

---

## Benefits Summary

### For Users

- ✅ Single configuration file (no duplicated settings)
- ✅ More contextually aware content generation
- ✅ Validation catches errors early (before generation)
- ✅ Consistent course branding across all materials

### For flow-cli

- ✅ Delegates Scholar-specific config to Scholar
- ✅ Shared validation reduces maintenance burden
- ✅ Cleaner command interface (fewer flags to pass)

### For Scholar

- ✅ Access to rich course context for better generation
- ✅ Standardized config format across tools
- ✅ Validation infrastructure (JSON Schema)
- ✅ Future extensibility (add new Scholar-specific fields)

---

## Related Work

- **flow-cli v5.9.0:** Config validation + hash-based change detection
- **JSON Schema:** Shared schema at `flow-cli/lib/templates/teaching/teach-config.schema.json`
- **Scholar v2.1.0:** Current teaching command implementation

---

## References

- [flow-cli Scholar Integration Guide](https://github.com/Data-Wise/flow-cli/blob/main/docs/guides/SCHOLAR-INTEGRATION.md)
- [teach-config.yml Schema](https://github.com/Data-Wise/flow-cli/blob/main/lib/templates/teaching/teach-config.schema.json)
- [flow-cli API Reference](https://github.com/Data-Wise/flow-cli/blob/main/docs/reference/API-REFERENCE.md)
- [Scholar Teaching System Architecture](https://github.com/Data-Wise/flow-cli/blob/main/TEACHING-SYSTEM-ARCHITECTURE.md)

---

## Next Steps

1. **Review this RFC** with Scholar team
2. **Discuss implementation approach** (Python vs Node.js schema validation)
3. **Create GitHub issue** in Scholar repository
4. **Prototype `--config` flag** in one command (exam or quiz)
5. **Iterate based on feedback**

---

**Questions? Feedback?**
Please comment on the issue or reach out to flow-cli maintainers.
