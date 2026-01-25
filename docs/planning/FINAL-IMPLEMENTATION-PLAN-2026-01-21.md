# 🚀 Final Implementation Plan: Teaching Prompts Enhancement

**Generated:** 2026-01-21
**Based on:** 30+ Q&A insights + architecture + UX design
**Status:** Complete plan, ready for execution
**Estimated Time:** Phase 1 (1-2 hours), Phase 2 (3-5 hours), Phase 3 (8-12 hours)

---

## 📋 Executive Summary

Transform PR #283's static prompts into an **intelligent, integrated teaching content system** with:

- **3-tier storage** (Global → User → Course)
- **Smart precedence** (Course overrides win)
- **Template rendering** from `_variables.yml`
- **Interactive workflows** (edit, enhance, promote)
- **Built-in catalog** for discovery
- **Named collections** for prompt libraries

**Key Decisions:**
- ✅ Global prompts (~/.flow/prompts/) ARE editable
- ✅ Local prompts (.claude/prompts/) committed to git
- ✅ Full copies per course (isolation, not symlinks)
- ✅ Auto-restore if ~/.flow/prompts/ deleted
- ✅ Named collections (~/.flow/libraries/)
- ✅ Template variables from `_variables.yml`

---

## 🏛️ Storage Architecture (Final Design)

### Three-Tier System

```
┌─────────────────────────────────────────────────────────────┐
│ Tier 1: Global Defaults (READ-ONLY)                        │
│ lib/templates/teaching/claude-prompts/                     │
│ - Shipped with flow-cli                                    │
│ - Updated via flow-cli releases                            │
│ - Source of truth for fresh installs                       │
└─────────────────────────────────────────────────────────────┘
                         ↓ (first install)
┌─────────────────────────────────────────────────────────────┐
│ Tier 2: User Library (EDITABLE)                            │
│ ~/.flow/prompts/                                           │
│ - User-wide customizations                                 │
│ - Survives flow-cli updates                                │
│ - Base for new courses                                     │
│ ~/.flow/libraries/                                         │
│ - Named collections (stats-101/, stats-advanced/)          │
│ - Organized by topic/level                                 │
└─────────────────────────────────────────────────────────────┘
                         ↓ (teach init)
┌─────────────────────────────────────────────────────────────┐
│ Tier 3: Course-Specific (VERSIONED)                        │
│ .claude/prompts/*.local.md                                 │
│ - Full copies (isolated per course)                        │
│ - Committed to git                                         │
│ - Shared with TAs/co-instructors                           │
└─────────────────────────────────────────────────────────────┘
```

---

## 📁 Directory Structure (Complete)

### Global Defaults (Tier 1)

```
lib/templates/teaching/claude-prompts/
├── README.md
├── CATALOG.yml                        # Prompt registry
├── lecture-notes.md                   # v1.0.0
├── revealjs-slides.md                 # v1.0.0
├── derivations-appendix.md            # v1.0.0
├── assignment.md                      # Phase 3
├── exam.md                            # Phase 3
├── syllabus.md                        # Phase 3
├── rubric.md                          # Phase 3
├── examples/                          # Sample outputs
│   ├── sample-lecture-anova.md
│   ├── sample-slides-regression.md
│   └── sample-appendix-ems.md
├── schemas/                           # Validation schemas
│   ├── lecture-checklist.yml
│   ├── slides-checklist.yml
│   └── appendix-checklist.yml
└── catalog/                           # Built-in registry
    ├── official/
    │   ├── lecture-machine-learning.md
    │   └── ...
    └── community/
        ├── lecture-bayesian-stats.md
        └── ...
```

---

### User Library (Tier 2)

```
~/.flow/
├── prompts/                           # User-wide defaults
│   ├── lecture-notes.md               # User's default lecture style
│   ├── revealjs-slides.md             # User's default slide style
│   ├── derivations-appendix.md        # User's default derivations
│   └── custom-lab-worksheet.md        # User-created prompt
│
├── libraries/                         # Named collections
│   ├── stats-101/                     # Intro stats prompts
│   │   ├── lecture-descriptive.md
│   │   ├── lecture-inference.md
│   │   └── assignment-simple.md
│   ├── stats-advanced/                # Advanced stats prompts
│   │   ├── lecture-glm.md
│   │   ├── lecture-mixed-models.md
│   │   └── exam-comprehensive.md
│   └── causal-inference/              # Causal methods prompts
│       ├── lecture-dags.md
│       ├── lecture-ivs.md
│       └── slides-rdd.md
│
└── config.yml                         # User preferences
    prompts:
      default_save_location: global
      always_confirm: true
      auto_promote: false
      default_library: stats-101
```

---

### Course-Specific (Tier 3)

```
course-project/
├── .claude/
│   ├── prompts/                       # Course overrides (FULL COPIES)
│   │   ├── lecture-notes.local.md     # Customized for this course
│   │   ├── revealjs-slides.local.md   # Customized for this course
│   │   └── .gitkeep                   # Preserve directory
│   ├── schemas/                       # Course-specific validation (Phase 2)
│   │   └── lecture-checklist.local.yml
│   └── teaching-style.local.md        # Scholar integration
│
├── _variables.yml                     # Course metadata (for template rendering)
├── _quarto.yml                        # Quarto config
├── .STATUS                            # Project status
└── .gitignore                         # DO NOT ignore .claude/prompts/
```

---

## 🔧 Template Rendering System

### Config File Strategy

**Analysis of Existing Files:**

| File | Purpose | Suitable for Prompts? | Priority |
|------|---------|----------------------|----------|
| `_variables.yml` | Author, email, affiliations, course URL | ⚠️ Too minimal | Low |
| `_quarto.yml` | Quarto build settings | ❌ Not course-specific | No |
| `.STATUS` | Project status, progress tracking | ❌ Too high-level | No |
| **PROPOSED:** `teach-config.yml` | **Course metadata, packages, notation** | ✅ **Perfect fit** | **High** |

**Decision: Create `teach-config.yml` for Teaching Courses**

### teach-config.yml Schema

```yaml
# teach-config.yml
course:
  name: "STAT 440 - Regression Analysis"
  code: "STAT 440"
  semester: "Fall 2025"
  url: "https://Data-Wise.github.io/regression"

  # R package ecosystem
  r_packages:
    core: [emmeans, lme4, car, ggplot2, dplyr, tidyr]
    diagnostics: [performance, DHARMa, broom]
    reporting: [modelsummary, gtsummary]
    optional: [nlme, glmmTMB, mgcv]

  # Notation conventions
  notation:
    expectation: "\\E{X}"
    variance: "\\Var{X}"
    covariance: "\\Cov{X,Y}"
    probability: "\\Prob{A}"
    vector: "\\vect{y}"
    style: "macros"  # macros | inline | mixed

  # Pedagogy preferences
  pedagogy:
    derivation_depth: "rigorous-with-intuition"  # heuristic | rigorous-with-intuition | full-rigor
    practice_problems_count: [6, 8]  # min, max
    include_diagnostic_workflow: true
    proof_style: "annotated"  # annotated | formal | mixed

  # Content preferences
  content:
    examples_per_concept: 2
    include_hand_calculations: true
    code_style: "tidyverse"  # tidyverse | base | mixed
    datasets: "textbook"  # textbook | real-world | mixed

# Prompt customizations (optional overrides)
prompts:
  lecture:
    length: [25, 35]  # pages
  slides:
    count: [30, 40]  # slides
  assignment:
    problems: [8, 12]
```

---

### Template Variable Syntax

**In Prompts:**

```markdown
# Lecture Notes Generator (lecture-notes.md)

**Package Loading:**
```r
pacman::p_load(
  {{course.r_packages.core}},       # emmeans, lme4, car, ...
  {{course.r_packages.diagnostics}} # performance, DHARMa, ...
)
```

**Notation:**
Use standardized macros:
- Expectation: `{{course.notation.expectation}}`  # \E{X}
- Variance: `{{course.notation.variance}}`        # \Var{X}

**Derivation Depth:**
{{#if course.pedagogy.derivation_depth == "rigorous-with-intuition"}}
For each derivation:
1. State the result
2. Intuitive explanation
3. Full step-by-step proof
{{/if}}

**Practice Problems:**
Include {{course.pedagogy.practice_problems_count[0]}}-{{course.pedagogy.practice_problems_count[1]}} problems.

```

---

### Rendering Engine

```zsh
_render_prompt_template() {
    local prompt_file="$1"
    local config_file="${2:-teach-config.yml}"

    # Check if config exists
    if [[ ! -f "$config_file" ]]; then
        # Fallback: Use prompt as-is (no rendering)
        cat "$prompt_file"
        return 0
    fi

    # Extract variables from teach-config.yml
    local r_packages_core=$(yq '.course.r_packages.core[]' "$config_file" | paste -sd, -)
    local r_packages_diagnostics=$(yq '.course.r_packages.diagnostics[]' "$config_file" | paste -sd, -)
    local notation_expectation=$(yq '.course.notation.expectation' "$config_file")
    local derivation_depth=$(yq '.course.pedagogy.derivation_depth' "$config_file")
    local problems_min=$(yq '.course.pedagogy.practice_problems_count[0]' "$config_file")
    local problems_max=$(yq '.course.pedagogy.practice_problems_count[1]' "$config_file")

    # Render template (simple sed for Phase 1, templating engine for Phase 2)
    cat "$prompt_file" \
        | sed "s|{{course.r_packages.core}}|$r_packages_core|g" \
        | sed "s|{{course.r_packages.diagnostics}}|$r_packages_diagnostics|g" \
        | sed "s|{{course.notation.expectation}}|$notation_expectation|g" \
        | sed "s|{{course.pedagogy.practice_problems_count\[0\]}}|$problems_min|g" \
        | sed "s|{{course.pedagogy.practice_problems_count\[1\]}}|$problems_max|g"

    # TODO Phase 2: Use proper templating engine (mustache, jinja2, etc.)
}
```

---

### Integration with teach-dispatcher

```zsh
_teach_lecture() {
    local topic="$1"

    # Resolve prompt (Course → User → Global)
    local prompt_file=$(_resolve_prompt "lecture-notes")

    # Render template with teach-config.yml
    local rendered_prompt=$(_render_prompt_template "$prompt_file" "teach-config.yml")

    # Invoke Scholar with rendered prompt
    if command -v scholar &>/dev/null; then
        echo "$rendered_prompt" | scholar teaching:lecture "$topic"
    else
        # Fallback: Show prompt + instructions
        echo "📋 Prompt Template:"
        echo "$rendered_prompt" | less
        echo ""
        echo "💡 Tip: Install Scholar plugin for automated generation"
    fi
}
```

---

## 🎯 Phase 1 Implementation (1-2 hours)

### Wave 1: Foundation (20 min)

**Tasks:**
1. Add versioning headers to 3 prompts (5 min)

   ```markdown
   <!--
   Version: 1.0.0
   Last Modified: 2026-01-21
   Author: flow-cli team
   Compatible with: flow-cli 5.14.0+, Scholar 2.x
   Tags: lecture, statistics, quarto
   -->
   ```

2. Create 3 sample outputs (15 min)
   - `examples/sample-lecture-anova.md` (excerpt from real lecture)
   - `examples/sample-slides-regression.md` (first 10 slides)
   - `examples/sample-appendix-ems.md` (EMS derivation)

**Deliverable:** Versioned prompts + examples

---

### Wave 2: teach-dispatcher Integration (30 min)

**Tasks:**
1. Add `teach prompt list` command (10 min)

   ```zsh
   _teach_prompt_list() {
       echo "📋 Available Teaching Prompts:"
       echo ""
       echo "Official (3):"
       echo "  lecture   - Comprehensive lecture notes (20-40 pages)"
       echo "  slides    - RevealJS presentations (25+ slides)"
       echo "  appendix  - Mathematical derivations & proofs"
       echo ""
       echo "Commands:"
       echo "  teach prompt show <type>    # Display prompt"
       echo "  teach prompt edit <type>    # Customize for course"
   }
   ```

2. Add `teach prompt show <type>` command (10 min)

   ```zsh
   _teach_prompt_show() {
       local type="$1"
       local prompt_file=$(_resolve_prompt "$type")
       cat "$prompt_file" | less -R
       echo ""
       echo "📍 Location: $prompt_file"
   }
   ```

3. Add routing to teach-dispatcher (5 min)

   ```zsh
   case "$1" in
       prompt) shift; _teach_prompt "$@" ;;
       # ... existing commands
   esac
   ```

4. Update help text (5 min)

**Deliverable:** `teach prompt list`, `teach prompt show`

---

### Wave 3: User Library Initialization (15 min)

**Tasks:**
1. Create ~/.flow/prompts/ on first use (10 min)

   ```zsh
   _initialize_user_prompts() {
       if [[ ! -d "$HOME/.flow/prompts" ]]; then
           mkdir -p "$HOME/.flow/prompts"
           cp -r "$FLOW_ROOT/lib/templates/teaching/claude-prompts/"*.md \
                 "$HOME/.flow/prompts/"
           echo "✅ User prompts initialized in ~/.flow/prompts/"
       fi
   }
   ```

2. Add recovery if deleted (5 min)

   ```zsh
   # Detect missing ~/.flow/prompts/ and prompt restore
   if [[ ! -d "$HOME/.flow/prompts" ]]; then
       echo "⚠️  User prompts missing: ~/.flow/prompts/"
       echo "Restore from global? [Y/n]:"
       read -r response
       if [[ "$response" =~ ^[Yy]$ ]]; then
           _initialize_user_prompts
       fi
   fi
   ```

**Deliverable:** Auto-restore mechanism

---

### Wave 4: Documentation Updates (15 min)

**Tasks:**
1. Enhance README with example outputs (10 min)
   - Add "Example Outputs" section
   - Link to sample-*.md files
   - Show before/after screenshots (optional)

2. Add Quick Start guide (5 min)

   ```markdown
   ## Quick Start

   1. View available prompts:
      ```bash
      teach prompt list
      ```

   1. Display a prompt:

      ```bash
      teach prompt show lecture
      ```

   2. Generate content:

      ```bash
      teach lecture "Topic Name"
      ```

   ```

**Deliverable:** Updated README

---

## 🚀 Phase 2 Implementation (3-5 hours)

### Wave 1: Edit & Promote Commands (1 hour)

**Tasks:**
1. Implement `teach prompt edit <type>` (30 min)
   - Copy to .claude/prompts/*.local.md
   - Open in $EDITOR
   - Show next steps

2. Implement `teach prompt promote <type>` (20 min)
   - Copy .local.md → ~/.flow/prompts/
   - Backup option
   - Show impact

3. Implement conflict resolution (10 min)
   - Detect global + local duplicates
   - Show diff
   - User chooses version

**Deliverable:** Full edit/promote workflow

---

### Wave 2: Template Rendering (1.5 hours)

**Tasks:**
1. Create teach-config.yml.template (20 min)
   - Schema documentation
   - Example values
   - Ship with flow-cli

2. Implement `_render_prompt_template()` (40 min)
   - yq-based variable extraction
   - sed-based substitution
   - Handle missing teach-config.yml gracefully

3. Add template variables to prompts (30 min)
   - Update lecture-notes.md with {{course.*}}
   - Update revealjs-slides.md
   - Update derivations-appendix.md

**Deliverable:** Course-aware rendering

---

### Wave 3: Enhancement Wizard (1.5 hours)

**Tasks:**
1. Design wizard flow (20 min)
   - Step-by-step prompts
   - Interactive questions
   - Save location decision

2. Implement wizard (60 min)
   - Section-by-section enhancement
   - Apply changes to prompt
   - Save enhanced version

3. Test with real course (10 min)

**Deliverable:** `teach prompt enhance <type>`

---

### Wave 4: Validation System (1 hour)

**Tasks:**
1. Create validation schemas (20 min)
   - lecture-checklist.yml
   - slides-checklist.yml
   - appendix-checklist.yml

2. Implement `teach validate <file>` (30 min)
   - Parse .qmd file
   - Check against schema
   - Generate report

3. Add course-specific schemas (10 min)
   - .claude/schemas/ support
   - Precedence: course → global

**Deliverable:** Content validation tool

---

## 🏗️ Phase 3 Implementation (8-12 hours)

### Wave 1: Named Collections (2 hours)

**Tasks:**
1. Create ~/.flow/libraries/ structure (15 min)
2. Implement `teach prompt library` commands (60 min)
   - `teach prompt library list`
   - `teach prompt library create <name>`
   - `teach prompt library add <name> <prompt>`
   - `teach prompt library use <name>`

3. Add library selection to teach init (30 min)
4. Documentation (15 min)

**Deliverable:** Prompt libraries

---

### Wave 2: New Prompt Templates (6 hours)

**Tasks:**
1. Research + create assignment.md (2 hours)
2. Research + create exam.md (2 hours)
3. Research + create syllabus.md (1 hour)
4. Research + create rubric.md (1 hour)

**Deliverable:** 4 new prompt types

---

### Wave 3: Built-in Catalog (2 hours)

**Tasks:**
1. Create CATALOG.yml schema (20 min)
2. Implement `teach prompt browse` (40 min)
3. Implement `teach prompt install <name>` (40 min)
4. Curate initial community prompts (20 min)

**Deliverable:** Prompt discovery system

---

### Wave 4: Version Management (2 hours)

**Tasks:**
1. Implement `teach prompt versions <type>` (30 min)
2. Implement `teach prompt upgrade <type>` (40 min)
3. Implement `teach prompt diff <v1> <v2>` (30 min)
4. Create migration guide template (20 min)

**Deliverable:** Version control system

---

## 📊 Testing Strategy

### Phase 1 Tests (Manual)

```bash
# Test 1: Prompt discovery
teach prompt list              # Should show 3 prompts

# Test 2: Viewing
teach prompt show lecture      # Should paginate with less

# Test 3: User library initialization
rm -rf ~/.flow/prompts/
teach prompt list              # Should prompt to restore

# Test 4: Documentation
cat lib/templates/teaching/claude-prompts/README.md
# Should have example outputs section
```

---

### Phase 2 Tests (Manual + Automated)

```bash
# Test 1: Edit workflow
cd test-course/
teach prompt edit lecture
# Should copy to .claude/prompts/lecture-notes.local.md
# Should open in $EDITOR

# Test 2: Template rendering
echo "course:
  r_packages:
    core: [test1, test2]" > teach-config.yml
teach prompt show lecture
# Should show test1, test2 in package list

# Test 3: Promotion
teach prompt promote lecture
# Should copy .local.md → ~/.flow/prompts/
# Should offer backup option

# Test 4: Conflict resolution
# Create global + local versions
teach lecture "Test"
# Should detect conflict, show diff
```

---

### Phase 3 Tests (Comprehensive)

```bash
# Test 1: Named collections
teach prompt library create stats-101
teach prompt library add stats-101 lecture-notes
teach prompt library use stats-101
teach prompt list  # Should show from stats-101 library

# Test 2: Catalog
teach prompt browse
teach prompt install lecture-bayesian-stats
teach prompt show lecture-bayesian-stats

# Test 3: Versioning
teach prompt versions lecture
teach prompt upgrade lecture  # v1.0.0 → v1.1.0
teach prompt diff 1.0.0 1.1.0
```

---

## 🎯 Success Metrics

| Metric | Target | Phase |
|--------|--------|-------|
| **Discovery** | 100% users know prompts exist | Phase 1 |
| **Usage** | 5+ prompts/week | Phase 1 |
| **Customization** | 50% courses have .local.md | Phase 2 |
| **Template Rendering** | 80% use teach-config.yml | Phase 2 |
| **Validation** | 90% validation pass rate | Phase 2 |
| **Collections** | 3+ libraries created | Phase 3 |
| **Catalog** | 10+ community prompts | Phase 3 |

---

## 🔄 Migration Path

### For Existing Courses

```bash
# After PR #283 merge + Phase 1 implementation

cd ~/projects/teaching/stat-440

# Initialize prompts
teach init --prompts-only
# Creates .claude/prompts/
# Copies from ~/.flow/prompts/

# Create teach-config.yml
teach config init
# Interactive: fill course metadata, packages, notation

# Test rendering
teach lecture "Test Topic" --dry-run
# Should show rendered prompt with course-specific packages

# Commit to repo
git add .claude/prompts/ teach-config.yml
git commit -m "docs: initialize teaching prompts system"
```

---

## 📋 Complete Command Reference

### Viewing & Discovery

| Command | Description | Phase |
|---------|-------------|-------|
| `teach prompt list` | Show available prompts | 1 |
| `teach prompt show <type>` | Display prompt (paginated) | 1 |
| `teach prompt info <type>` | Show metadata | 1 |
| `teach prompt browse` | Browse catalog | 3 |
| `teach prompt search <query>` | Search prompts | 3 |

### Editing & Customization

| Command | Description | Phase |
|---------|-------------|-------|
| `teach prompt edit <type>` | Copy to course & edit | 2 |
| `teach prompt enhance <type>` | Interactive wizard | 2 |
| `teach prompt add <name>` | Create new prompt | 2 |
| `teach prompt customize <type>` | Alias for enhance | 2 |

### Management

| Command | Description | Phase |
|---------|-------------|-------|
| `teach prompt promote <type>` | Local → Global | 2 |
| `teach prompt diff <type>` | Compare global vs local | 2 |
| `teach prompt merge <type>` | Interactive merge | 2 |
| `teach prompt restore <backup>` | Restore from backup | 2 |
| `teach prompt reset <type>` | Restore to original | 2 |

### Libraries

| Command | Description | Phase |
|---------|-------------|-------|
| `teach prompt library list` | List libraries | 3 |
| `teach prompt library create <name>` | Create library | 3 |
| `teach prompt library add <name> <prompt>` | Add to library | 3 |
| `teach prompt library use <name>` | Switch library | 3 |

### Catalog

| Command | Description | Phase |
|---------|-------------|-------|
| `teach prompt catalog update` | Update catalog | 3 |
| `teach prompt catalog install <name>` | Install from catalog | 3 |

### Versioning

| Command | Description | Phase |
|---------|-------------|-------|
| `teach prompt versions <type>` | Show version history | 3 |
| `teach prompt upgrade <type>` | Upgrade to latest | 3 |
| `teach prompt diff <v1> <v2>` | Compare versions | 3 |

---

## 🔑 Key Design Decisions (Final)

### Decision 1: teach-config.yml for Course Metadata

**Rationale:** `_variables.yml` too minimal, `.STATUS` too high-level. New file gives clean separation.

### Decision 2: Editable Global Prompts

**Rationale:** Power users want to customize defaults. Isolation via full copies prevents cross-course pollution.

### Decision 3: Full Copies (Not Symlinks)

**Rationale:** Each course independent. Safe for git. No shared state issues.

### Decision 4: Commit .claude/prompts/ to Git

**Rationale:** Share teaching style with TAs. Version control customizations.

### Decision 5: Auto-Restore with Prompt

**Rationale:** Safety + visibility. User confirms restore vs manual fix.

### Decision 6: Named Collections

**Rationale:** Organize prompts by level/topic. Stats-101 vs Stats-Advanced.

### Decision 7: Template Rendering from teach-config.yml

**Rationale:** Course-aware generation. DRY principle. Single source of truth.

---

## 🚀 Recommended Next Steps

### Today (1-2 hours)

1. **Review this plan** - Validate approach, confirm scope
2. **Approve Phase 1 tasks** - 4 waves, ~80 minutes total
3. **Create implementation branch** - `feature/teaching-prompts-integration`
4. **Start Wave 1** - Versioning + examples (20 min)
5. **Complete Phase 1** - All 4 waves (1-2 hours)

### This Week

1. **Test Phase 1** - Real course (STAT 440)
2. **Document results** - Update README, IMPLEMENTATION.md
3. **Create PR** - Merge Phase 1 to dev
4. **Plan Phase 2** - Detailed spec for edit/promote/rendering

### Next Sprint

1. **Phase 2 implementation** - Edit, enhance, render (3-5 hours)
2. **Gather feedback** - What's working, what's missing
3. **Prioritize Phase 3** - Based on usage patterns

---

**Generated:** 2026-01-21
**Status:** ✅ Complete implementation plan
**Total Q&A:** 30+ questions answered
**Next:** Execute Phase 1 (1-2 hours)

