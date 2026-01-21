# 🧠 BRAINSTORM: Teaching Prompts Enhancement Plan

**Generated:** 2026-01-21
**Context:** PR #283 - Teaching prompts enhancement
**Mode:** Deep + Feature + Architecture + Automation
**Duration Budget:** 15 minutes
**Implementation Target:** 1-2 hours (quick wins)

---

## 📋 Overview

PR #283 introduces excellent teaching prompts but has key gaps:
1. **Discovery problem:** Users don't know prompts exist
2. **Generic content:** Prompts need course-specific customization
3. **Manual workflow:** No integration with teach-dispatcher
4. **No validation:** Can't verify generated content quality

**Goal:** Transform static prompt files into an integrated, intelligent teaching content system with smart defaults and course-aware customization.

---

## 🎯 User Stories

### Primary User Story
**As a** statistics instructor using flow-cli
**I want** seamless prompt integration in teach-dispatcher commands
**So that** I can generate course content with one command instead of copy-pasting prompts

**Acceptance Criteria:**
- ✅ `teach lecture "Topic"` auto-uses lecture-notes.md prompt
- ✅ `teach slides "Topic"` auto-uses revealjs-slides.md prompt
- ✅ `teach appendix "Topic"` auto-uses derivations-appendix.md prompt
- ✅ Prompts auto-fill course-specific info (R packages, notation) from course.yml
- ✅ Generated content validates against prompt requirements

### Secondary User Stories

**As a** new flow-cli user
**I want** to discover available prompts easily
**So that** I know what content types I can generate

**As a** instructor with specific pedagogical preferences
**I want** to customize prompts for my course
**So that** generated content matches my teaching style

---

## ⚡ Quick Wins (< 30 min each)

### 1. Add Versioning to Prompts (5-10 min)
```markdown
<!-- Version: 1.0.0 -->
<!-- Last Updated: 2026-01-21 -->
<!-- Compatible with: Scholar v2.x, flow-cli v5.14+ -->
```

**Why:** Track prompt evolution, ensure compatibility
**Implementation:** Add header to each .md file

---

### 2. Create `teach prompt` Command (20-30 min)

**Commands:**
```bash
teach prompt list           # Show available prompts
teach prompt show lecture   # Display lecture-notes.md
teach prompt show slides    # Display revealjs-slides.md
teach prompt show appendix  # Display derivations-appendix.md
teach prompt path lecture   # Print file path (for scripting)
```

**Implementation:** Add to `lib/dispatchers/teach-dispatcher.zsh`

```zsh
_teach_prompt() {
    local action="${1:-list}"
    local prompt_dir="$FLOW_ROOT/lib/templates/teaching/claude-prompts"

    case "$action" in
        list)
            echo "📋 Available Teaching Prompts:"
            echo ""
            echo "  lecture   - Comprehensive lecture notes (20-40 pages)"
            echo "  slides    - RevealJS presentations (25+ slides)"
            echo "  appendix  - Mathematical derivations & proofs"
            echo ""
            echo "Usage: teach prompt show <type>"
            ;;
        show)
            local type="$2"
            case "$type" in
                lecture) cat "$prompt_dir/lecture-notes.md" ;;
                slides) cat "$prompt_dir/revealjs-slides.md" ;;
                appendix) cat "$prompt_dir/derivations-appendix.md" ;;
                *) echo "Unknown prompt type: $type" ;;
            esac
            ;;
        path)
            local type="$2"
            case "$type" in
                lecture) echo "$prompt_dir/lecture-notes.md" ;;
                slides) echo "$prompt_dir/revealjs-slides.md" ;;
                appendix) echo "$prompt_dir/derivations-appendix.md" ;;
            esac
            ;;
        help) _teach_prompt_help ;;
        *) _teach_prompt_help ;;
    esac
}
```

**Benefit:** Immediate discoverability, zero learning curve

---

### 3. Add Real-World Examples to README (15-20 min)

**Current:** README describes prompts abstractly
**Enhancement:** Add "Example Output" sections

```markdown
## Example: Lecture Notes

**Input:**
```bash
teach lecture "Factorial ANOVA"
```

**Generated Output Structure:**
- 28 pages
- 6 learning objectives (Bloom's taxonomy)
- Motivating problem (agriculture experiment)
- 3 complete derivations (EMS for Factor A, B, AB)
- 5 R code examples with interpretation
- 8 practice problems with solutions
- Full diagnostic workflow with `performance::check_model()`

**Sample excerpt:** [Link to sample-lecture-factorial-anova.md]
```

**Why:** Users see concrete value immediately
**Implementation:** Create 3 sample outputs (one per prompt type)

---

### 4. Scholar Integration Hook (25-30 min)

**Problem:** Scholar's `/teaching:lecture` doesn't know about new prompts

**Solution:** Add prompt reference to Scholar skill invocation

```bash
# In teach-dispatcher.zsh
_teach_scholar_lecture() {
    local topic="$1"
    local prompt_path="$FLOW_ROOT/lib/templates/teaching/claude-prompts/lecture-notes.md"

    # Invoke Scholar with prompt reference
    claude skill teaching:lecture "$topic" --reference "$prompt_path"
}
```

**Benefit:** Zero-config Scholar integration
**Fallback:** If Scholar not installed, show prompt content + instructions

---

## 🔧 Medium Effort (1-2 hours each)

### 5. Course-Aware Prompt Rendering (1-2 hours)

**Problem:** Prompts are generic - no course-specific context

**Solution:** Template rendering from `course.yml`

**Template Syntax (in prompts):**
```markdown
**Package Loading:**
```r
pacman::p_load(
  {{course.r_packages}}  # Auto-filled from course.yml
)
```

**Example course.yml:**
```yaml
course:
  name: "STAT 440 - Regression Analysis"
  r_packages:
    - emmeans
    - lme4
    - car
    - performance
  notation:
    expectation: "E[X]"
    variance: "Var(X)"
  derivation_depth: "rigorous-with-intuition"
```

**Rendering Logic:**
```zsh
_teach_render_prompt() {
    local prompt_file="$1"
    local course_yml="$2"

    # Use yq to extract course config
    local packages=$(yq '.course.r_packages[]' "$course_yml" | paste -sd, -)

    # Render template
    sed "s/{{course.r_packages}}/$packages/g" "$prompt_file"
}
```

**Impact:** Prompts automatically adapt to course setup

---

### 6. Prompt Customization System (1.5-2 hours)

**Goal:** Let instructors create course-specific prompt overrides

**Commands:**
```bash
teach prompt customize lecture   # Interactive customization
teach prompt customize slides    # Interactive customization
teach prompt reset lecture       # Restore default
```

**Interactive Flow:**
```
teach prompt customize lecture

🎨 Customize Lecture Prompt for STAT 440

1. R packages (current: emmeans, lme4, car)
   → Add packages? [y/N]: y
   → Package names (comma-separated): DHARMa, broom

2. Derivation depth (current: rigorous-with-intuition)
   → Change? [y/N]: n

3. Notation style (current: LaTeX macros)
   → Change? [y/N]: n

✅ Customized prompt saved to:
   .claude/prompts/lecture-notes.local.md

Use: teach lecture "Topic" (will use customized version)
```

**Implementation:**
1. Copy default prompt to `.claude/prompts/lecture-notes.local.md`
2. Apply sed replacements based on user input
3. Modify `_teach_scholar_lecture()` to check for `.local.md` first

**Benefit:** One-time setup, all future lectures use customization

---

### 7. Content Validation Tool (1-2 hours)

**Command:**
```bash
teach validate lecture Week-3-ANOVA.qmd
```

**Checks:**
- ✅ Has learning objectives section
- ✅ Learning objectives use Bloom's taxonomy verbs
- ✅ Has motivating problem
- ✅ Code chunks are labeled (`#| label:`)
- ✅ Figures have captions (`#| fig-cap:`)
- ✅ Has practice problems section
- ✅ Derivations have step annotations
- ⚠️ Missing: Diagnostic workflow (`performance::check_model()`)
- ⚠️ Warning: Only 2 practice problems (prompt recommends 4-10)

**Output:**
```
📊 Validation Report: Week-3-ANOVA.qmd

Prompt: lecture-notes.md (v1.0.0)
Status: ⚠️ PASS WITH WARNINGS (7/9 checks passed)

✅ Required Elements
  ✓ Learning objectives (6 found)
  ✓ Bloom's taxonomy verbs used
  ✓ Motivating problem present
  ✓ Code chunks labeled (12/12)
  ✓ Figures captioned (8/8)
  ✓ Practice problems section

⚠️ Warnings
  ⚠ Only 2 practice problems (recommended: 4-10)
  ⚠ Missing diagnostic workflow section

❌ Errors
  ✗ Derivation steps not annotated (line 245-280)

💡 Suggestions:
  - Add performance::check_model() in Section 4.2
  - Add step annotations to EMS derivation (see prompt line 45-60)
  - Consider adding 2-3 more practice problems
```

**Implementation:**
- Parse `.qmd` with `yq` (YAML) + `grep` (content patterns)
- Compare against prompt checklist
- Generate actionable report

---

## 🏗️ Long-Term (Future Sprints)

### 8. Additional Prompt Templates

Create 4 new prompt types:

| Prompt | Purpose | Output |
|--------|---------|--------|
| `assignment.md` | Homework/project assignments | Problem sets with rubrics |
| `exam.md` | Exam generation | Multiple formats (MC, short answer, problems) |
| `syllabus.md` | Course syllabus | Complete syllabus with policies |
| `rubric.md` | Grading rubrics | Detailed rubrics for assignments/exams |

**Priority:** assignment > exam > syllabus > rubric

**Time:** 2-3 hours per prompt (research + writing + testing)

---

### 9. AI Recipe Integration

**Goal:** Trigger prompts via natural language

**Example:**
```
[teach-lecture] Create lecture notes for "Interaction Effects"
[teach-slides] Generate 30 slides on "Random Effects"
[teach-appendix] Derive the expected mean squares for three-way ANOVA
```

**Implementation:**
1. Create `.claude/recipes/teaching-recipes.md`
2. Add trigger patterns + prompt references
3. Document in README

**Time:** 1-2 hours

---

### 10. Version Management System

**Commands:**
```bash
teach prompt versions lecture   # Show version history
teach prompt upgrade lecture    # Upgrade to latest version
teach prompt diff 1.0.0 1.1.0   # Compare versions
```

**Implementation:**
- Git-based versioning (tags for releases)
- Migration guides for breaking changes
- Backward compatibility warnings

**Time:** 2-3 hours

---

## 🏛️ Architecture

### Current Structure
```
lib/templates/teaching/claude-prompts/
├── README.md                    # Documentation
├── lecture-notes.md             # Prompt (static)
├── revealjs-slides.md           # Prompt (static)
└── derivations-appendix.md      # Prompt (static)
```

### Enhanced Structure (Phase 1)
```
lib/templates/teaching/claude-prompts/
├── README.md                    # Enhanced with examples
├── lecture-notes.md             # v1.0.0 with versioning
├── revealjs-slides.md           # v1.0.0 with versioning
├── derivations-appendix.md      # v1.0.0 with versioning
├── examples/                    # NEW: Sample outputs
│   ├── sample-lecture-anova.md
│   ├── sample-slides-regression.md
│   └── sample-appendix-ems.md
└── schemas/                     # NEW: Validation schemas
    ├── lecture-checklist.yml
    ├── slides-checklist.yml
    └── appendix-checklist.yml

lib/dispatchers/teach-dispatcher.zsh
└── (enhanced with teach prompt commands)

.claude/prompts/                 # NEW: Course overrides
├── lecture-notes.local.md       # (user-customized)
└── revealjs-slides.local.md     # (user-customized)
```

### Enhanced Structure (Phase 2 - Future)
```
lib/templates/teaching/claude-prompts/
├── ...
├── assignment.md                # NEW: Assignment prompt
├── exam.md                      # NEW: Exam prompt
├── syllabus.md                  # NEW: Syllabus prompt
└── rubric.md                    # NEW: Rubric prompt

lib/validators/
└── teaching-content-validator.zsh  # NEW: Validation engine

.claude/recipes/
└── teaching-recipes.md          # NEW: AI recipe triggers
```

---

## 🔗 Integration Points

### 1. teach-dispatcher Integration (Phase 1)

**Commands Added:**
```bash
teach prompt list              # List available prompts
teach prompt show <type>       # Display prompt content
teach prompt path <type>       # Get file path
teach prompt customize <type>  # Interactive customization
teach prompt reset <type>      # Restore defaults

teach lecture "Topic"          # Auto-uses lecture prompt
teach slides "Topic" [count]   # Auto-uses slides prompt
teach appendix "Topic"         # Auto-uses appendix prompt

teach validate <file>          # Validate against prompt checklist
```

**Routing Changes:**
```zsh
# In teach-dispatcher.zsh
case "$1" in
    prompt) shift; _teach_prompt "$@" ;;
    lecture) shift; _teach_lecture "$@" ;;  # NEW
    slides) shift; _teach_slides "$@" ;;    # NEW
    appendix) shift; _teach_appendix "$@" ;; # NEW
    validate) shift; _teach_validate "$@" ;; # NEW
    # ... existing commands
esac
```

---

### 2. Scholar Plugin Integration (Phase 1)

**Option A: Implicit (Recommended for Quick Win)**
```bash
# teach lecture calls Scholar with prompt reference
teach lecture "ANOVA" → scholar teaching:lecture "ANOVA" --prompt lecture-notes.md
```

**Option B: Explicit (Phase 2)**
```bash
# Scholar skills auto-detect prompts
/teaching:lecture "ANOVA"  # Scholar checks for lib/templates/.../lecture-notes.md
                           # If found, uses it automatically
```

**Implementation:** Modify Scholar skill to check for prompt files in known locations

---

### 3. AI Recipes Integration (Phase 2)

**File:** `.claude/recipes/teaching-recipes.md`

```markdown
# Teaching Content Recipes

## [teach-lecture]
**Trigger:** [teach-lecture] <topic>
**Prompt:** lib/templates/teaching/claude-prompts/lecture-notes.md
**Action:** Generate comprehensive lecture notes

## [teach-slides]
**Trigger:** [teach-slides] <topic> [slide_count]
**Prompt:** lib/templates/teaching/claude-prompts/revealjs-slides.md
**Action:** Generate RevealJS presentation
```

**Integration:** Hook into prompt-dispatcher or create new recipe handler

---

### 4. course.yml Integration (Phase 1)

**Template Variables:**
```yaml
# course.yml
course:
  name: "STAT 440"
  r_packages: [emmeans, lme4, car, performance]
  notation:
    expectation: "\\E{X}"
    variance: "\\Var{X}"
  derivation_depth: "rigorous-with-intuition"
  prompt_overrides:
    lecture:
      practice_problems_count: 6
      include_diagnostic_workflow: true
```

**Prompt Rendering:**
```markdown
<!-- In lecture-notes.md -->
pacman::p_load({{course.r_packages}})  # → pacman::p_load(emmeans, lme4, car, performance)
```

**Implementation:** `yq` for YAML parsing + `envsubst` or custom `sed` replacements

---

## 📊 Dependencies

### Required
- ✅ `yq` - YAML parsing (course.yml, checklist schemas)
- ✅ `git` - Version tracking
- ✅ ZSH - teach-dispatcher implementation

### Optional
- ⚠️ Scholar plugin v2.x - Enhanced `/teaching:*` integration
- ⚠️ Claude Code - AI recipe triggers
- ⚠️ `pandoc` - Markdown validation (for teach validate)

### New Files/Libraries
- `lib/validators/teaching-content-validator.zsh` (Phase 2)
- `lib/templates/teaching/claude-prompts/schemas/*.yml` (Phase 1)
- `lib/templates/teaching/claude-prompts/examples/*.md` (Phase 1)

---

## 📝 Implementation Roadmap

### Phase 1: Quick Wins (1-2 hours total)

**Wave 1: Foundation (20 min)**
- [ ] Add versioning headers to 3 prompts (5 min)
- [ ] Create 3 example outputs (sample-lecture, sample-slides, sample-appendix) (15 min)

**Wave 2: teach-dispatcher Integration (30 min)**
- [ ] Add `teach prompt list` command (10 min)
- [ ] Add `teach prompt show <type>` command (10 min)
- [ ] Add `teach prompt path <type>` command (5 min)
- [ ] Update teach-dispatcher help (5 min)

**Wave 3: Documentation (15 min)**
- [ ] Enhance README with example outputs section (10 min)
- [ ] Add "Quick Start" guide to README (5 min)

**Wave 4: Scholar Integration (15 min)**
- [ ] Add `teach lecture` command (uses Scholar + prompt) (10 min)
- [ ] Add fallback for no-Scholar case (5 min)

**Phase 1 Deliverables:**
- ✅ 4 new teach-dispatcher commands
- ✅ Versioned prompts
- ✅ Example outputs
- ✅ Enhanced documentation
- ✅ Basic Scholar integration

**Total Time:** ~80 minutes (within 1-2 hour budget)

---

### Phase 2: Medium Effort (3-5 hours)

**Prerequisites:** Phase 1 complete + tested

**Wave 1: Course-Aware Rendering (1.5 hours)**
- [ ] Implement template variable syntax
- [ ] Add `yq`-based rendering engine
- [ ] Test with sample course.yml
- [ ] Document template syntax

**Wave 2: Validation System (1.5 hours)**
- [ ] Create validation schemas (3 YAML files)
- [ ] Implement `teach validate` command
- [ ] Add validation report formatter
- [ ] Test with sample generated content

**Wave 3: Customization System (1.5 hours)**
- [ ] Implement `teach prompt customize`
- [ ] Add `.claude/prompts/` override logic
- [ ] Create reset command
- [ ] Test customization workflow

**Phase 2 Deliverables:**
- ✅ Course-aware prompt rendering
- ✅ Content validation tool
- ✅ Prompt customization system

**Total Time:** ~4.5 hours

---

### Phase 3: Long-Term (8-12 hours)

**Wave 1: New Prompts (6 hours)**
- [ ] Research + create `assignment.md` (2 hours)
- [ ] Research + create `exam.md` (2 hours)
- [ ] Research + create `syllabus.md` (1 hour)
- [ ] Research + create `rubric.md` (1 hour)

**Wave 2: AI Recipes (2 hours)**
- [ ] Create teaching-recipes.md
- [ ] Test recipe triggers
- [ ] Document recipe usage

**Wave 3: Version Management (2 hours)**
- [ ] Implement version commands
- [ ] Create migration system
- [ ] Document versioning

**Phase 3 Deliverables:**
- ✅ 4 new prompt types
- ✅ AI recipe integration
- ✅ Version management

**Total Time:** ~10 hours

---

## 🧪 Testing Strategy

### Phase 1 Testing (Manual)

**Prompt Discovery:**
```bash
# Test: Can users find prompts?
teach prompt list              # → Should show 3 prompts
teach prompt show lecture      # → Should display lecture-notes.md
```

**Scholar Integration:**
```bash
# Test: Does Scholar integration work?
teach lecture "Test Topic"     # → Should invoke Scholar or show fallback
```

**Documentation:**
```bash
# Test: Are examples clear?
cat lib/templates/teaching/claude-prompts/examples/sample-lecture-anova.md
# → Should show realistic lecture output
```

---

### Phase 2 Testing (Unit + Integration)

**Template Rendering:**
```bash
# Test: Does course.yml integration work?
teach lecture "Test" --course course.yml
# → Generated content should use course-specific packages
```

**Validation:**
```bash
# Test: Does validation catch issues?
teach validate test-lecture.qmd
# → Should report missing elements
```

**Customization:**
```bash
# Test: Does customization persist?
teach prompt customize lecture  # → Interactive flow
teach lecture "Test"            # → Should use customized prompt
```

---

### Phase 3 Testing (Comprehensive)

**New Prompts:**
```bash
# Test: Do new prompts generate valid content?
teach assignment "Homework 3"
teach exam "Midterm"
teach validate hw3.qmd          # → Validates against assignment.md checklist
```

**Recipes:**
```bash
# Test: Do recipes work?
[teach-lecture] Generate lecture for "GLMs"
# → Should trigger lecture prompt
```

---

## 🎯 Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Discovery** | 100% users know prompts exist | Survey after 2 weeks |
| **Usage** | 5+ prompts used per week | Git commits with prompt-generated content |
| **Customization** | 50% courses have .local.md overrides | Count .claude/prompts/*.local.md files |
| **Quality** | 90% validation pass rate | teach validate results |
| **Time Savings** | 30 min → 5 min to create lecture | Time tracking before/after |

---

## ⚠️ Open Questions

1. **Scholar Dependency:** Should teach-dispatcher require Scholar plugin, or provide fallback?
   - **Recommendation:** Fallback (show prompt + instructions if Scholar not found)

2. **Validation Strictness:** Should `teach validate` block deployment if checks fail?
   - **Recommendation:** Warnings only for Phase 1, blocking in Phase 2 (opt-in)

3. **Prompt Versioning:** How to handle breaking changes in prompts?
   - **Recommendation:** Semantic versioning (1.0.0 → 1.1.0 = backward compatible, 2.0.0 = breaking)

4. **Course.yml Location:** Where should course.yml live?
   - **Recommendation:** Project root (same as .STATUS, course.yml.template)

5. **Override Precedence:** What if both .local.md and course.yml exist?
   - **Recommendation:** .local.md wins (explicit > implicit)

---

## 🔑 Key Decisions

### Decision 1: teach-dispatcher as Primary Interface
**Rationale:** Users already familiar with teach commands, minimal learning curve

### Decision 2: Course-Specific Customization via .local.md
**Rationale:** Follows flow-cli convention (.claude/*.local.md pattern)

### Decision 3: Validation as Opt-In (Phase 1)
**Rationale:** Avoid breaking existing workflows, introduce gradually

### Decision 4: Examples Over Abstractions
**Rationale:** Users learn faster from concrete examples than descriptions

### Decision 5: Phased Rollout (3 phases)
**Rationale:** Quick wins build momentum, validate direction before heavy investment

---

## 📚 Documentation Plan

### Phase 1 Documentation

**Updates:**
1. **README.md** - Add "Quick Start", "Example Outputs", "Integration" sections
2. **IMPLEMENTATION.md** - Add Phase 1 implementation guide
3. **teach-dispatcher help** - Add new commands to help text

**New Files:**
1. `examples/sample-lecture-anova.md` - Full lecture example
2. `examples/sample-slides-regression.md` - Full slides example
3. `examples/sample-appendix-ems.md` - Derivation example

---

### Phase 2 Documentation

**New Guides:**
1. `docs/guides/TEACHING-PROMPTS-GUIDE.md` - Comprehensive user guide
2. `docs/guides/PROMPT-CUSTOMIZATION.md` - Customization tutorial
3. `docs/reference/TEACH-PROMPT-REFERENCE.md` - Command reference

**Updates:**
1. **course.yml.template** - Add prompt-related fields
2. **teach-dispatcher help** - Add validation, customization commands

---

### Phase 3 Documentation

**New Guides:**
1. `docs/guides/PROMPT-DEVELOPMENT.md` - Creating new prompts
2. `docs/guides/AI-RECIPES-TEACHING.md` - Recipe usage

**Updates:**
1. **README.md** - Add all 7 prompt types
2. **Changelog** - Document version history

---

## 💡 Next Steps

### Immediate (Today)

1. **Review this brainstorm** - Validate approach, identify any gaps
2. **Approve Phase 1 scope** - Confirm 1-2 hour quick wins are sufficient
3. **Create implementation branch** - `feature/teaching-prompts-integration`
4. **Start Wave 1** - Add versioning + examples (20 min)

### This Week

1. **Complete Phase 1** - All 4 waves (1-2 hours total)
2. **Test with real course** - STAT 440 or similar
3. **Document Phase 1 results** - Update README, IMPLEMENTATION.md
4. **Create PR** - Merge Phase 1 to dev

### Next Sprint

1. **Phase 2 planning** - Detailed spec for validation + customization
2. **Gather user feedback** - What's working, what's missing
3. **Prioritize Phase 2 features** - Based on actual usage patterns

---

## 🎨 Visual Workflows

### Current Workflow (Before Enhancement)
```
User wants lecture notes
  ↓
Open browser → claude.ai
  ↓
Copy prompt from GitHub
  ↓
Paste into Claude
  ↓
Type topic
  ↓
Generate (wait 5 min)
  ↓
Copy output to .qmd
  ↓
Manual validation
  ↓
Done (30 min total)
```

### Enhanced Workflow (After Phase 1)
```
User wants lecture notes
  ↓
teach lecture "Topic"
  ↓
Scholar invoked with prompt
  ↓
Generated content saved
  ↓
Done (5 min total)

Savings: 25 minutes (83% reduction)
```

### Enhanced Workflow (After Phase 2)
```
User wants customized lecture
  ↓
teach prompt customize lecture  (one-time setup)
  ↓
teach lecture "Topic"
  ↓
Generated (course-aware)
  ↓
teach validate output.qmd
  ↓
Fix warnings (if any)
  ↓
Done (8 min total, 100% validated)

Savings: 22 minutes (73% reduction) + quality guarantee
```

---

## 🚀 Recommended Implementation Path

### For 1-2 Hour Session (Quick Wins)

**Priority Order:**
1. ⚡ **Wave 1: Foundation** (20 min) - Versioning + examples
2. ⚡ **Wave 2: teach-dispatcher** (30 min) - `teach prompt` commands
3. ⚡ **Wave 4: Scholar Integration** (15 min) - `teach lecture` command
4. ⚡ **Wave 3: Documentation** (15 min) - README updates

**Total:** 80 minutes

**Why this order:**
- Versioning is foundation for everything else
- Examples demonstrate value immediately
- teach-dispatcher integration is most requested feature
- Scholar integration adds immediate automation
- Documentation last (captures what we built)

**Defer to Phase 2:**
- Course-aware rendering (needs more testing)
- Validation system (needs schema design)
- Customization (complex UX, needs iteration)

---

## 🔄 Iteration Plan

### After Phase 1 (Week 1)
- Gather user feedback on teach prompt commands
- Measure usage: Are prompts being discovered?
- Identify pain points with current workflow
- Decide: Proceed to Phase 2 or iterate on Phase 1?

### After Phase 2 (Week 4)
- Gather feedback on validation accuracy
- Measure customization adoption
- Identify missing features
- Decide: Proceed to Phase 3 or add Phase 2.5?

### After Phase 3 (Week 8)
- Measure comprehensive system usage
- Identify next generation features
- Consider: Prompt marketplace, community templates?

---

## 📋 Review Checklist

Before starting implementation:

- [ ] Brainstorm reviewed and approved
- [ ] Phase 1 scope confirmed (1-2 hours)
- [ ] Wave order agreed upon
- [ ] Examples identified (which topics?)
- [ ] Scholar integration approach confirmed
- [ ] Branch created: feature/teaching-prompts-integration
- [ ] Tests planned (what to validate?)
- [ ] Documentation updates scoped

---

## 🎯 Success Criteria

**Phase 1 is successful if:**
- ✅ Users can discover prompts via `teach prompt list`
- ✅ Users can generate content via `teach lecture "Topic"`
- ✅ Examples demonstrate realistic output quality
- ✅ README clearly explains usage
- ✅ Implementation completed in 1-2 hours

**Phase 2 is successful if:**
- ✅ Course-specific rendering works (packages auto-filled)
- ✅ Validation catches 90% of quality issues
- ✅ Customization reduces setup time by 50%

**Phase 3 is successful if:**
- ✅ All 7 prompt types available
- ✅ AI recipes work seamlessly
- ✅ Version management prevents breakage

---

**Generated in:** 14 minutes
**Status:** ✅ Ready for implementation
**Next:** Review → Approve Phase 1 → Create branch → Start Wave 1

