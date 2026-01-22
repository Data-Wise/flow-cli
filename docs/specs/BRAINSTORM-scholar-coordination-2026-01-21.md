# Scholar Integration Coordination - Deep Brainstorm

**Generated:** 2026-01-21
**Context:** Coordinating teaching prompt enhancements (PR #283) with Scholar plugin v2.2.0
**Related Specs:**
- SPEC-teaching-prompts-enhancement-2026-01-21.md
- Scholar: BRAINSTORM-flow-cli-coordination-2026-01-14.md
- Scholar: BRAINSTORM-unified-architecture-2026-01-15.md

---

## Executive Summary

**Goal:** Seamlessly integrate new 3-tier prompt storage system with Scholar's teaching content generation while maintaining single unified config (teach-config.yml) and enabling bidirectional sync.

**Current State:**
- flow-cli v5.15.0 has teach-dispatcher (9 commands, 853 lines)
- Scholar v2.0.1 released (8 teaching commands)
- Scholar v2.1.0 in progress (/teaching:lecture command)
- Scholar v2.2.0 planned with --config flag support
- Shared config protocol (RFC-001) exists with ownership sections

**Coordination Challenge:**
- New prompt system adds 3-tier storage + template rendering + customization
- Scholar needs course config for content generation
- Both systems need to read/write teach-config.yml without conflicts
- Users want: "two-way sync, merge into single config, leverage all Scholar features"

---

## Architecture Overview

### Current Integration (v5.9.0 → v2.0.1)

```
┌─────────────────────────────────────────────────────────┐
│  User Command: teach lecture "ANOVA"                    │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│  teach-dispatcher.zsh (flow-cli)                        │
│  - Routes to _teach_lecture()                           │
│  - Validates teach-config.yml exists                    │
│  - Launches Scholar with args                           │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│  Scholar Plugin (via Claude Code)                       │
│  - Reads .flow/teach-config.yml                         │
│  - Uses scholar: section for style settings             │
│  - Generates content based on course: section           │
│  - Returns generated Quarto file                        │
└─────────────────────────────────────────────────────────┘
```

### Proposed Integration (v5.15.0 → v2.2.0)

```
┌─────────────────────────────────────────────────────────┐
│  User Command: teach lecture "ANOVA"                    │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│  teach-dispatcher.zsh (flow-cli) - ENHANCED             │
│  - Auto-detects prompt from teach-config.yml            │
│  - Resolves prompt via 3-tier system:                   │
│    1. .claude/prompts/lecture-notes.local.md (Course)   │
│    2. ~/.flow/prompts/lecture-notes.md (User)           │
│    3. lib/templates/.../lecture-notes.md (Global)       │
│  - Renders template variables from teach-config.yml     │
│  - Launches Scholar with --config + --prompt flags      │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│  Scholar Plugin v2.2.0 - ENHANCED                       │
│  - Receives --config .flow/teach-config.yml             │
│  - Receives --prompt .claude/prompts/lecture.local.md   │
│  - Merges prompt with Scholar's teaching style system   │
│  - Validates against schema (YAML DSL)                  │
│  - Generates content with full context                  │
│  - Writes back metadata to teach-config.yml (optional)  │
└─────────────────────────────────────────────────────────┘
```

---

## Coordination Points

### 1. Config File Unification

**Current State:**
- flow-cli uses: `.flow/teach-config.yml`
- Scholar reads: `.flow/teach-config.yml`
- RFC-001 defines ownership sections

**Enhancement:**
- Merge `scholar:` section into `teach-config.yml`
- Add `prompts:` section (new) for prompt metadata
- Add `templates:` section (new) for rendering variables

**Proposed Schema (teach-config.yml):**

```yaml
# === flow-cli OWNED SECTIONS ===
course:
  name: "STAT 440: Regression Analysis"
  code: "STAT 440"
  semester: "Spring 2025"
  institution: "Iowa State University"
  instructor: "Dr. Example"

  # NEW: R Package Configuration
  r_packages:
    core: [emmeans, lme4, car]
    diagnostics: [DHARMa, performance]
    reporting: [sjPlot, modelsummary]

  # NEW: LaTeX Notation Configuration
  notation:
    expectation: "\\mathbb{E}"
    variance: "\\text{Var}"
    probability: "\\mathbb{P}"
    style: "macros"  # macros | inline | mixed

  # NEW: Pedagogy Configuration
  pedagogy:
    derivation_depth: "rigorous-with-intuition"  # heuristic | rigorous-with-intuition | full-rigor
    practice_problems_count: [4, 10]
    include_diagnostic_workflow: true

semester_info:
  start_date: "2025-01-13"
  end_date: "2025-05-09"
  weeks: 16
  holidays: ["2025-03-17", "2025-03-19"]

branches:
  main: "main"
  draft: "draft"
  archive: "archive"

deployment:
  method: "github-pages"
  url: "https://example.github.io/stat-440/"
  auto_deploy: true

# === Scholar OWNED SECTIONS ===
scholar:
  course_info:
    level: "undergraduate"  # undergraduate | graduate | phd
    field: "statistics"
    prerequisites: ["STAT 301", "STAT 326"]

  style:
    tone: "formal"  # formal | conversational | technical
    notation: "statistical"  # mathematical | statistical | computational
    depth: "detailed"  # overview | detailed | comprehensive

  teaching_layers:
    layer_1_core: true
    layer_2_intuition: true
    layer_3_rigor: true
    layer_4_advanced: false

# === NEW: PROMPT SYSTEM SECTIONS ===
prompts:
  # Prompt metadata (managed by flow-cli)
  library: "default"  # default | custom-name
  version: "1.0.0"

  # Per-prompt customizations
  lecture:
    template: "lecture-notes.md"
    customized: true
    last_modified: "2026-01-15"

  assignment:
    template: "assignment.md"
    customized: false

  exam:
    template: "exam.md"
    customized: true
    last_modified: "2026-01-10"

templates:
  # Template rendering variables (used by both systems)
  packages_display: "emmeans, lme4, car, DHARMa"
  notation_summary: "Using \\mathbb{E} for expectation, \\text{Var} for variance"
  course_title_short: "Regression Analysis"
```

**Ownership Protocol:**

| Section | Owner | Can Read | Can Write |
|---------|-------|----------|-----------|
| `course:` | flow-cli | Both | flow-cli only |
| `semester_info:` | flow-cli | Both | flow-cli only |
| `branches:` | flow-cli | Both | flow-cli only |
| `deployment:` | flow-cli | Both | flow-cli only |
| `scholar:` | Scholar | Both | Scholar only |
| `prompts:` | flow-cli | Both | flow-cli only |
| `templates:` | flow-cli | Both | Both (read-only for Scholar) |

**Write Coordination:**
- flow-cli writes: `course:`, `semester_info:`, `prompts:`, `templates:`
- Scholar writes: `scholar:` only
- Both read entire file
- No conflicts because sections are isolated

---

### 2. Prompt System Integration

**Challenge:** Scholar generates content, flow-cli manages prompts. How do they coordinate?

#### Option A: Scholar-Aware Prompts (Recommended)

**Flow:**

1. User runs: `teach lecture "ANOVA"`
2. flow-cli resolves prompt via 3-tier system
3. flow-cli renders template variables from `teach-config.yml`
4. flow-cli passes **rendered prompt** to Scholar via `--prompt` flag
5. Scholar merges prompt with its teaching style layers
6. Scholar generates content using **combined context**

**Benefits:**
- Scholar gets full context (prompt + config)
- Prompts can reference Scholar features
- Users customize both systems independently
- Clear separation of concerns

**Example Prompt with Scholar Integration:**

```markdown
# Lecture Notes Generation - Scholar Integration

Generate comprehensive lecture notes for a {{course.level}} course in {{course.field}}.

## Course Context
- Course: {{course.name}} ({{course.code}})
- Instructor: {{course.instructor}}
- Level: {{scholar.course_info.level}}
- Field: {{scholar.course_info.field}}

## Teaching Style
Apply Scholar's {{scholar.teaching_layers.layer_2_intuition ? "intuition-focused" : "standard"}} approach with {{scholar.style.tone}} tone.

## Content Requirements

### 1. Core Concepts (Layer 1)
- {{pedagogy.derivation_depth == "heuristic" ? "Heuristic explanations" : "Formal derivations"}}
- Visual diagrams where appropriate
- Real-world examples from {{course.field}}

### 2. Statistical Implementation
- R code using: {{templates.packages_display}}
- Diagnostic workflow: {{pedagogy.include_diagnostic_workflow ? "Include DHARMa diagnostics" : "Basic diagnostics only"}}

### 3. Mathematical Notation
- Expectation: {{notation.expectation}}
- Variance: {{notation.variance}}
- Style: {{notation.style == "macros" ? "Use LaTeX macros" : "Inline notation"}}

### 4. Practice Problems
- Generate {{pedagogy.practice_problems_count[0]}}-{{pedagogy.practice_problems_count[1]}} problems
- Range from basic to challenging

## Scholar Layer Integration

{{#if scholar.teaching_layers.layer_2_intuition}}
**Layer 2 (Intuition):** Include conceptual explanations before formal definitions
{{/if}}

{{#if scholar.teaching_layers.layer_3_rigor}}
**Layer 3 (Rigor):** Provide formal proofs and theoretical foundations
{{/if}}

{{#if scholar.teaching_layers.layer_4_advanced}}
**Layer 4 (Advanced):** Add cutting-edge research connections
{{/if}}
```

**Implementation:**

```bash
# In teach-dispatcher.zsh
_teach_lecture() {
    local topic="$1"

    # 1. Resolve prompt via 3-tier system
    local prompt_file=$(_resolve_prompt "lecture-notes")

    # 2. Render template variables from teach-config.yml
    local rendered_prompt=$(_render_template "$prompt_file" "$PWD/.flow/teach-config.yml")

    # 3. Save rendered prompt to temp file
    local temp_prompt=$(mktemp)
    echo "$rendered_prompt" > "$temp_prompt"

    # 4. Launch Scholar with both flags
    claude --skill "scholar:manuscript:lecture" \
        --config "$PWD/.flow/teach-config.yml" \
        --prompt "$temp_prompt" \
        "$topic"

    # 5. Cleanup
    rm "$temp_prompt"
}
```

#### Option B: Scholar-Oblivious Prompts

**Flow:**
1. Scholar reads `teach-config.yml` directly
2. flow-cli prompts are completely separate
3. User manually ensures consistency

**Issues:**
- High chance of config drift
- Prompts can't reference Scholar features
- Poor user experience (two systems to maintain)

**Verdict:** ❌ Not recommended

---

### 3. Command Coordination

**Current Scholar Commands (v2.0.1):**
```
/teaching:lecture    - Generate lecture notes
/teaching:assignment - Generate homework
/teaching:exam       - Generate exams
/teaching:quiz       - Generate quizzes
/teaching:syllabus   - Generate syllabus
/teaching:rubric     - Generate grading rubrics
/teaching:feedback   - Generate student feedback
/teaching:slides     - Generate presentation slides
```

**Current teach-dispatcher Commands (v5.15.0):**
```
teach init          - Initialize teaching project
teach status        - Show project status
teach deploy        - Deploy to GitHub Pages
teach exam          - Wrapper for Scholar /teaching:exam
teach lecture       - Wrapper for Scholar /teaching:lecture
teach assignment    - Wrapper for Scholar /teaching:assignment
teach quiz          - Wrapper for Scholar /teaching:quiz
teach syllabus      - Wrapper for Scholar /teaching:syllabus
```

**New Prompt Commands (Proposed):**
```
teach prompt list           - Show available prompts
teach prompt show <type>    - Display prompt (paginated)
teach prompt info <type>    - Show metadata
teach prompt edit <type>    - Copy to .claude/, open in $EDITOR
teach prompt enhance <type> - Interactive wizard
teach prompt promote <type> - Copy .local.md → ~/.flow/
```

**Coordination Strategy:**

| User Action | flow-cli Command | Scholar Skill | Prompt Used |
|-------------|------------------|---------------|-------------|
| Generate lecture | `teach lecture "Topic"` | `/teaching:lecture` | Auto-resolved via 3-tier |
| Customize lecture prompt | `teach prompt edit lecture` | N/A | Opens lecture-notes.md |
| Generate with custom prompt | `teach lecture "Topic"` | `/teaching:lecture` | Uses .claude/prompts/lecture.local.md |
| View current prompt | `teach prompt show lecture` | N/A | Displays resolved prompt |
| Generate assignment | `teach assignment "HW1"` | `/teaching:assignment` | Auto-resolved |
| List all prompts | `teach prompt list` | N/A | Shows all available |

**Key Design Decision:**

**Content generation commands** (`teach lecture`, `teach exam`, etc.) **automatically use prompts** from 3-tier system. No extra flags needed.

**Prompt management commands** (`teach prompt *`) are **separate** and manage the prompt library.

**Benefits:**
- Zero friction for users (prompts "just work")
- Clear mental model (teach X generates, teach prompt manages)
- Backward compatible (existing commands work without prompts)

---

### 4. Template Variable Rendering

**Challenge:** Both systems need access to config variables for rendering.

#### Rendering Points

**Point 1: flow-cli renders prompts** (before Scholar sees them)
- Template: `lib/templates/teaching/claude-prompts/lecture-notes.md`
- Variables: `{{course.name}}`, `{{pedagogy.derivation_depth}}`, etc.
- Output: Fully rendered prompt passed to Scholar

**Point 2: Scholar renders content** (during generation)
- Template: Scholar's internal Quarto templates
- Variables: `{course.code}`, `{semester.start_date}`, etc.
- Output: Final Quarto file

**Coordination:**

```yaml
# teach-config.yml - Shared variables
templates:
  # Used by flow-cli prompt rendering
  packages_display: "emmeans, lme4, car"
  notation_summary: "Using \\mathbb{E} for expectation"

  # Used by Scholar content rendering
  course_header: "STAT 440: Regression Analysis"
  instructor_info: "Dr. Example | Spring 2025"
```

**Implementation:**

```bash
# flow-cli: Render prompt before Scholar
_render_template() {
    local template_file="$1"
    local config_file="$2"

    # Use yq + sed/awk for simple variable substitution
    local content=$(cat "$template_file")

    # Extract variables from config
    local course_name=$(yq '.course.name' "$config_file")
    local packages=$(yq '.templates.packages_display' "$config_file")

    # Simple substitution (Phase 1)
    content="${content//\{\{course.name\}\}/$course_name}"
    content="${content//\{\{templates.packages_display\}\}/$packages}"

    echo "$content"
}
```

**Future Enhancement (Phase 3):**
- Full template engine (Handlebars/Mustache syntax)
- Conditionals: `{{#if scholar.teaching_layers.layer_2_intuition}}`
- Loops: `{{#each course.r_packages.core}}`
- Filters: `{{course.name | uppercase}}`

---

### 5. Validation Coordination

**Challenge:** Who validates what?

#### Validation Responsibilities

| System | Validates | When | How |
|--------|-----------|------|-----|
| flow-cli | teach-config.yml schema | `teach init`, `teach doctor` | YAML schema + hash caching |
| flow-cli | Prompt metadata | `teach prompt edit`, `teach prompt enhance` | Frontmatter validation |
| flow-cli | Quarto rendering | `teach deploy` | `quarto render --quiet` |
| Scholar | Content quality | During generation | Internal LLM validation |
| Scholar | teach-config.yml (Scholar sections) | Skill invocation | Schema validation |

**Shared Validation:**

**teach-config.yml must be valid for BOTH systems**

**Solution: Unified Schema**

```yaml
# .flow/teach-config.schema.yml (new file)
$schema: "http://json-schema.org/draft-07/schema#"
title: "Teaching Configuration Schema"
description: "Unified schema for flow-cli + Scholar integration"

type: object
required: [course, scholar]

properties:
  # flow-cli sections
  course:
    type: object
    required: [name, code]
    properties:
      name: {type: string}
      code: {type: string}
      r_packages:
        type: object
        properties:
          core: {type: array, items: {type: string}}
          diagnostics: {type: array, items: {type: string}}
          reporting: {type: array, items: {type: string}}
      notation:
        type: object
        properties:
          expectation: {type: string}
          variance: {type: string}
          style: {enum: [macros, inline, mixed]}
      pedagogy:
        type: object
        properties:
          derivation_depth: {enum: [heuristic, rigorous-with-intuition, full-rigor]}
          practice_problems_count: {type: array, minItems: 2, maxItems: 2}
          include_diagnostic_workflow: {type: boolean}

  # Scholar sections
  scholar:
    type: object
    required: [course_info, style]
    properties:
      course_info:
        type: object
        properties:
          level: {enum: [undergraduate, graduate, phd]}
          field: {type: string}
      style:
        type: object
        properties:
          tone: {enum: [formal, conversational, technical]}
          notation: {enum: [mathematical, statistical, computational]}

  # Shared sections
  templates:
    type: object
    additionalProperties: {type: string}
```

**Validation Implementation:**

```bash
# teach-dispatcher.zsh
_validate_config() {
    local config_file="$1"

    # 1. Check YAML syntax
    yq eval "$config_file" > /dev/null 2>&1 || {
        _flow_log_error "Invalid YAML syntax"
        return 1
    }

    # 2. Validate against schema (using yq + custom validation)
    _validate_schema "$config_file" ".flow/teach-config.schema.yml"

    # 3. Scholar-specific validation (if Scholar is available)
    if command -v scholar-validate &> /dev/null; then
        scholar-validate "$config_file"
    fi
}
```

---

### 6. Migration Path

**Challenge:** Existing courses using Scholar need smooth upgrade path.

#### Current State (Pre-Enhancement)

**Existing course using Scholar:**
```
my-course/
├── .flow/
│   └── teach-config.yml        # Has course: + scholar: sections
├── lectures/
│   └── lecture-01.qmd
└── README.md
```

**Current workflow:**
1. `teach lecture "ANOVA"`
2. Scholar reads `.flow/teach-config.yml`
3. Scholar generates lecture
4. User edits output

#### Target State (Post-Enhancement)

```
my-course/
├── .flow/
│   ├── teach-config.yml        # ENHANCED with prompts: + templates:
│   └── teach-config.schema.yml # Validation schema
├── .claude/
│   └── prompts/
│       ├── lecture-notes.local.md   # Customized from global
│       └── assignment.local.md      # Customized
├── lectures/
│   └── lecture-01.qmd
└── README.md
```

**New workflow:**
1. `teach lecture "ANOVA"`
2. flow-cli resolves prompt (3-tier system)
3. flow-cli renders template variables
4. flow-cli passes rendered prompt to Scholar
5. Scholar generates with enhanced context
6. Better output, less editing needed

#### Migration Steps

**Automatic Migration (teach init):**

```bash
# Detect existing teach-config.yml
teach init

# Output:
# ✓ Found existing teach-config.yml
# ⚙ Migrating to v5.15.0 format...
#   + Added prompts: section
#   + Added templates: section
#   + Copied global prompts to ~/.flow/prompts/
# ✓ Migration complete
#
# Next steps:
#   1. Review changes: git diff .flow/teach-config.yml
#   2. Customize prompts: teach prompt edit lecture
#   3. Test generation: teach lecture "Test"
```

**Manual Migration (teach doctor):**

```bash
teach doctor

# Output:
# Teaching Project Health Check
# =============================
#
# Dependencies
#   ✓ yq          (4.30.0)
#   ✓ git         (2.39.0)
#   ✓ quarto      (1.3.450)
#   ✓ claude      (1.0.0)
#
# Configuration
#   ⚠ teach-config.yml missing prompts: section
#   ⚠ teach-config.yml missing templates: section
#   ⚠ Schema file not found
#
# Prompts
#   ⚠ Global prompts not initialized
#   ⚠ No course-specific customizations
#
# Recommendations:
#   1. Run: teach init --migrate
#   2. Or manually add sections (see docs)
```

**Migration Script:**

```bash
# lib/migration-helpers.zsh (new file)

_migrate_config_to_v5_15() {
    local config_file="$1"

    # Backup original
    cp "$config_file" "${config_file}.backup-$(date +%Y%m%d-%H%M%S)"

    # Add prompts: section if missing
    if ! yq eval '.prompts' "$config_file" &> /dev/null; then
        yq eval '.prompts = {"library": "default", "version": "1.0.0"}' -i "$config_file"
    fi

    # Add templates: section if missing
    if ! yq eval '.templates' "$config_file" &> /dev/null; then
        # Auto-generate from course: section
        local packages=$(yq eval '.course.r_packages.core | join(", ")' "$config_file")
        yq eval ".templates.packages_display = \"$packages\"" -i "$config_file"
    fi

    # Copy schema file
    cp "$FLOW_ROOT/lib/templates/teaching/teach-config.schema.yml" \
       "$PWD/.flow/teach-config.schema.yml"

    _flow_log_success "Migration complete"
}
```

---

## Implementation Roadmap

### Phase 1: Foundation (1-2 hours) - Quick Wins

**Goal:** Get basic integration working without breaking existing Scholar workflows.

**Tasks:**
1. **Add prompts: and templates: sections to teach-config.yml** (20 min)
   - Update teach-config.yml.template
   - Add default values
   - Document new sections

2. **Create unified schema file** (15 min)
   - `.flow/teach-config.schema.yml`
   - Validate both flow-cli + Scholar sections
   - Add to teach init

3. **Update teach-dispatcher with prompt resolution** (30 min)
   - Add `_resolve_prompt()` function
   - Integrate with existing Scholar wrappers
   - Backward compatible (works without prompts)

4. **Add basic template rendering** (20 min)
   - Simple `{{variable}}` substitution
   - Use yq to extract values
   - Pass rendered prompt to Scholar

5. **Documentation** (15 min)
   - Update teach-dispatcher help
   - Add examples to README
   - Migration guide for existing courses

**Deliverables:**
- ✅ teach-config.yml with new sections
- ✅ Schema validation
- ✅ Prompt auto-resolution (3-tier)
- ✅ Basic template rendering
- ✅ Backward compatible

**Testing:**
```bash
# Existing workflow (should still work)
teach lecture "ANOVA"

# New workflow (with prompts)
teach prompt list
teach prompt show lecture
teach lecture "ANOVA"  # Uses resolved prompt
```

### Phase 2: Enhancement (3-5 hours) - Power Features

**Goal:** Add prompt management commands + advanced rendering.

**Tasks:**
1. **Implement teach prompt commands** (2 hours)
   - `teach prompt list/show/info`
   - `teach prompt edit/enhance`
   - `teach prompt promote`

2. **Enhanced template rendering** (1 hour)
   - Conditionals: `{{#if ...}}`
   - Loops: `{{#each ...}}`
   - Filters: `{{... | filter}}`

3. **Scholar --config + --prompt flag support** (1 hour)
   - Update Scholar plugin to accept flags
   - Merge prompt with teaching style
   - Validate combined context

4. **Validation coordination** (1 hour)
   - `teach validate` command
   - Schema validation for both systems
   - Auto-fix common issues

**Deliverables:**
- ✅ Full prompt management
- ✅ Advanced template rendering
- ✅ Scholar flag support
- ✅ Unified validation

### Phase 3: Advanced Features (8-12 hours) - Future

**Goal:** Named collections, catalog, versioning.

**Tasks:**
1. **Named prompt collections** (2 hours)
   - `~/.flow/libraries/`
   - `teach prompt library create/use`
   - Library selection in teach init

2. **New Scholar-integrated prompts** (6 hours)
   - assignment.md
   - exam.md
   - syllabus.md
   - rubric.md
   - All with Scholar layer integration

3. **Prompt catalog system** (2 hours)
   - CATALOG.yml
   - `teach prompt browse/install`
   - Community prompts

4. **Version management** (2 hours)
   - Prompt versioning
   - Upgrade notifications
   - Migration guides

---

## Technical Decisions Summary

### ✅ Decided (From Planning Sessions)

1. **Storage:** 3-tier (Global → User → Course)
2. **Precedence:** Course → User → Global
3. **Config File:** Unified teach-config.yml (both systems)
4. **Ownership:** RFC-001 protocol (isolated sections)
5. **Template Rendering:** flow-cli renders prompts before Scholar
6. **Prompt Passing:** Via `--prompt` flag (temp file)
7. **Validation:** Shared schema, each system validates its sections
8. **Migration:** Auto-migration via `teach init --migrate`
9. **Backward Compatibility:** Existing workflows work without prompts

### 🤔 Open Questions

1. **Should Scholar write back to teach-config.yml?**
   - Scenario: Scholar generates metadata (e.g., topics covered)
   - Option A: Scholar writes to `scholar:` section (two-way sync)
   - Option B: Scholar read-only (one-way)
   - **Recommendation:** Option A (two-way sync) for metadata only

2. **How to handle prompt version conflicts?**
   - Scenario: Global prompt updated, user has old customized version
   - Option A: Auto-upgrade with migration
   - Option B: Notify user, manual upgrade
   - **Recommendation:** Option B (explicit user control)

3. **Should teach prompt edit create .claude/ if missing?**
   - Option A: Auto-create directory
   - Option B: Error + suggest `teach init`
   - **Recommendation:** Option A (better UX)

4. **Template engine choice?**
   - Option A: Custom ZSH implementation (lightweight)
   - Option B: External tool (Handlebars, Mustache)
   - **Recommendation:** Option A for Phase 1, Option B for Phase 3

5. **Should Scholar prompts be versioned separately?**
   - Option A: Scholar has its own prompt versions
   - Option B: flow-cli prompts are the source of truth
   - **Recommendation:** Option B (flow-cli manages all prompts)

---

## Coordination Protocol

### Two-Way Sync Rules

**flow-cli → Scholar (Always):**
- Reads entire teach-config.yml
- Renders prompts with template variables
- Passes rendered prompt via `--prompt` flag
- Passes config file via `--config` flag

**Scholar → flow-cli (Optional):**
- Writes metadata to `scholar:` section
- Updates `prompts.lecture.last_modified`
- Notifies flow-cli of changes (if desired)

**Example Sync Flow:**

```bash
# 1. User customizes prompt
teach prompt edit lecture
# -> Opens .claude/prompts/lecture-notes.local.md
# -> User adds custom section about diagnostics

# 2. User generates lecture
teach lecture "ANOVA"
# -> flow-cli resolves: .claude/prompts/lecture-notes.local.md
# -> flow-cli renders: {{course.r_packages.diagnostics}} → "DHARMa, performance"
# -> flow-cli passes to Scholar via --prompt flag
# -> Scholar generates lecture with custom diagnostics section
# -> Scholar writes metadata:
#    scholar:
#      last_generation:
#        command: "lecture"
#        topic: "ANOVA"
#        timestamp: "2026-01-21T10:30:00Z"
#        prompt_used: ".claude/prompts/lecture-notes.local.md"

# 3. User checks status
teach status
# -> Shows last generation info from scholar: section
```

---

## Next Steps

### Immediate (This Session)

1. **Review this brainstorm** with user
2. **Clarify open questions** (5 items above)
3. **Create formal SPEC** if approved
4. **Update SPEC-teaching-prompts-enhancement** with Scholar coordination

### Short-term (Next Session)

1. **Implement Phase 1** (1-2 hours)
   - Update teach-config.yml template
   - Add schema file
   - Implement prompt resolution
   - Basic template rendering

2. **Update Scholar plugin** (coordinate with Scholar development)
   - Add `--config` flag support
   - Add `--prompt` flag support
   - Merge prompt with teaching style

3. **Write integration tests**
   - Test config reading (both systems)
   - Test prompt resolution
   - Test template rendering
   - Test Scholar invocation with flags

### Long-term (Future Sprints)

1. **Phase 2 implementation** (3-5 hours)
2. **Phase 3 implementation** (8-12 hours)
3. **Community prompts catalog**
4. **Advanced validation**

---

## Benefits Summary

### For Users

**Before (Current State):**
- Manually copy-paste Claude prompts
- Maintain config in teach-config.yml
- Scholar generates content
- Limited customization options

**After (Enhanced State):**
- Zero-friction prompt usage (auto-detected)
- Single unified config file
- Customizable prompts (course-specific)
- Scholar integration (enhanced context)
- Shareable prompt libraries
- Version-controlled prompts
- Consistent content generation

### For Developers

**Before:**
- Two separate systems (flow-cli + Scholar)
- Manual coordination needed
- Risk of config drift

**After:**
- Unified architecture
- Clear ownership protocol (RFC-001)
- Shared schema validation
- Extensible prompt system
- Clean separation of concerns

---

## Risk Mitigation

### Risk 1: Breaking Existing Workflows

**Mitigation:**
- Backward compatibility (existing commands work without prompts)
- Graceful degradation (missing sections → defaults)
- Auto-migration (`teach init --migrate`)
- Comprehensive testing

### Risk 2: Config File Conflicts

**Mitigation:**
- Clear ownership protocol (RFC-001)
- Isolated sections (flow-cli vs Scholar)
- Schema validation prevents overwrites
- Git version control

### Risk 3: Scholar Integration Delays

**Mitigation:**
- Phase 1 works without Scholar changes (basic rendering)
- Phase 2 requires Scholar v2.2.0 (coordinate release)
- Fallback to Scholar-oblivious mode if needed

### Risk 4: Complexity Creep

**Mitigation:**
- Start simple (Phase 1: basic features)
- Add advanced features incrementally (Phase 2, 3)
- User testing at each phase
- Clear documentation

---

## Success Metrics

### Phase 1 Success

- [ ] Existing `teach lecture` command works unchanged
- [ ] New `teach prompt list` shows available prompts
- [ ] Config file validated by both systems
- [ ] Template variables render correctly
- [ ] Zero user-reported regressions

### Phase 2 Success

- [ ] Users can customize prompts easily
- [ ] Scholar receives enhanced context
- [ ] Generated content quality improves
- [ ] Prompt management commands intuitive
- [ ] < 5 min to customize first prompt

### Phase 3 Success

- [ ] Named collections used by power users
- [ ] Community prompts catalog active
- [ ] Prompt upgrades seamless
- [ ] Multiple courses share prompts via ~/.flow/

---

## Appendix: Example Workflows

### Workflow 1: New Course Setup

```bash
# 1. Initialize teaching project
teach init
# -> Creates .flow/teach-config.yml with all sections
# -> Creates .flow/teach-config.schema.yml
# -> Initializes ~/.flow/prompts/ if needed
# -> Prompts for Scholar integration (yes/no)

# 2. Customize config
$EDITOR .flow/teach-config.yml
# -> Add course name, packages, notation, pedagogy
# -> Add Scholar style preferences

# 3. Generate first lecture (uses default prompts)
teach lecture "Introduction to Regression"
# -> flow-cli resolves: lib/templates/.../lecture-notes.md
# -> flow-cli renders variables
# -> Scholar generates with config + prompt

# 4. Customize lecture prompt for this course
teach prompt edit lecture
# -> Copies global → .claude/prompts/lecture-notes.local.md
# -> Opens in $EDITOR
# -> User adds course-specific sections

# 5. Generate next lecture (uses customized prompt)
teach lecture "Simple Linear Regression"
# -> flow-cli resolves: .claude/prompts/lecture-notes.local.md
# -> Uses course-specific customizations
```

### Workflow 2: Multi-Course Instructor

```bash
# 1. Create named collection for undergraduate courses
teach prompt library create undergrad-stats
# -> Creates ~/.flow/libraries/undergrad-stats/
# -> Copies default prompts

# 2. Customize prompts in collection
cd ~/.flow/libraries/undergrad-stats/
$EDITOR lecture-notes.md
# -> Add undergrad-friendly language
# -> Reduce rigor, increase intuition

# 3. Use collection in Course A
cd ~/teaching/stat-226/
teach init --library undergrad-stats
# -> Uses prompts from collection

# 4. Use collection in Course B
cd ~/teaching/stat-301/
teach init --library undergrad-stats
# -> Same prompts, different config

# 5. Update collection (affects both courses)
cd ~/.flow/libraries/undergrad-stats/
$EDITOR lecture-notes.md
# -> Make improvements
teach lecture "Topic"  # Both courses get updates
```

### Workflow 3: Graduate Course with Advanced Prompts

```bash
# 1. Setup graduate course
teach init
$EDITOR .flow/teach-config.yml
# -> Set scholar.course_info.level: "graduate"
# -> Set pedagogy.derivation_depth: "full-rigor"

# 2. Customize lecture prompt for grad level
teach prompt edit lecture
# -> Opens .claude/prompts/lecture-notes.local.md
# -> Add sections:
#    - Advanced theoretical foundations
#    - Proof sketches
#    - Research connections
#    - Graduate-level references

# 3. Generate lecture
teach lecture "Advanced Mixed Models"
# -> flow-cli renders:
#    {{pedagogy.derivation_depth}} → "full-rigor"
#    {{scholar.course_info.level}} → "graduate"
# -> Scholar uses graduate teaching layers
# -> Output includes proofs, advanced theory
```

---

**End of Brainstorm**

**Next Actions:**
1. User reviews brainstorm
2. Clarify 5 open questions
3. Approve coordination strategy
4. Proceed to implementation (Phase 1)
