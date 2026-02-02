# 🧠 BRAINSTORM: Intelligent Content Analysis for Teaching Workflows

**Generated:** 2026-01-20
**Mode:** Deep + Feature + Agents
**Context:** flow-cli v5.15.0 + PR #280 (lecture-to-slides)

**User Decisions:**

- ✅ Primary Goal: Add intelligent content generation
- ✅ Integration: teach slides + teach validate
- ✅ Intelligence: Content analysis, learning objectives, prerequisites
- ✅ UX Pattern: New `teach analyze` command
- ✅ Timing: Pre-deployment review
- ✅ Slides Integration: Suggest slide breaks + identify key concepts
- ✅ Prerequisites: Hybrid (user-defined + AI-extracted)

---

## 🎯 Vision Statement

**Transform teach workflow from content creation to intelligent content engineering.**

Enable instructors to validate not just syntax (YAML, Quarto) but semantic quality:

- Are learning objectives actually covered?
- Are prerequisites introduced before use?
- Is content difficulty progressing appropriately?
- Are slides structured for maximum comprehension?

---

## ⚡ Quick Wins (< 30 min each)

### 1. teach analyze skeleton command

**Effort:** 20 min
**Value:** Foundation for all analysis features

Create basic dispatcher routing:

```zsh
# In teach-dispatcher.zsh
analyze|analysis)
    shift
    _teach_analyze_command "$@"
    ;;
```

Stub function that shows:

- ✓ Syntax validation passed (from teach validate)
- ⏳ Content analysis (coming soon)
- ⏳ Learning objective tracking (coming soon)
- ⏳ Prerequisite checking (coming soon)

**Why first:** Establishes the command pattern, unblocks parallel development

---

### 2. Add analysis section to lesson-plan.yml schema

**Effort:** 15 min
**Value:** Configuration foundation

```yaml
# lesson-plan.yml
analysis:
  enabled: true
  strictness: moderate # strict|moderate|relaxed
  checks:
    learning_objectives: true
    prerequisites: true
    readability: true
    concept_coverage: true

  prerequisites: # User-defined high-level concepts
    week_1: []
    week_2: [basic_statistics]
    week_3: [basic_statistics, hypothesis_testing]
    week_4: [regression_basics]
```

**Why important:** Separates config from code, enables per-course customization

---

### 3. teach status dashboard enhancement

**Effort:** 25 min
**Value:** Visibility into content quality

Add "Content Quality" section to teach status:

```
📊 Content Quality
  ✓ 8/10 lectures analyzed
  ⚠ 2 prerequisite violations (Week 3, Week 7)
  ℹ 3 readability suggestions
  ⏳ Analysis: 2 weeks pending

  Last analysis: 2h ago
  Run: teach analyze --all
```

**Why useful:** Surfaces quality issues without running full analysis

---

## 🔧 Medium Effort (2-4 hours each)

### 4. Learning objective tracker (Phase 1)

**Effort:** 3 hours
**Value:** Core semantic validation

Parse YAML frontmatter for learning objectives:

```yaml
---
title: 'Week 3: Hypothesis Testing'
objectives:
  - Understand Type I and Type II errors
  - Perform t-tests in R
  - Interpret p-values correctly
---
```

Validate lecture content covers objectives:

- Scan for keyword mentions (naive but fast)
- Count code examples matching objectives
- Flag if objective appears < 2 times

Output:

```
📋 Learning Objectives: Week 3

  ✓ Understand Type I and Type II errors
    ├─ Mentioned: 4 times
    └─ Examples: 2 code chunks

  ⚠ Perform t-tests in R
    ├─ Mentioned: 1 time (LOW)
    └─ Examples: 0 code chunks (NONE)

  ✓ Interpret p-values correctly
    ├─ Mentioned: 6 times
    └─ Examples: 3 code chunks

Recommendation: Add 1-2 code examples for t-tests
```

**Tech stack:** ZSH + yq for YAML, grep for content scanning

---

### 5. Prerequisite checker (Hybrid approach - Phase 1)

**Effort:** 4 hours
**Value:** Prevents concept usage before introduction

**User-defined prerequisites (lesson-plan.yml):**

```yaml
prerequisites:
  week_1: []
  week_2: [mean, median, variance]
  week_3: [mean, median, variance, distributions, hypothesis_testing]
```

**Validation logic:**

1. Extract concepts from each week's content (simple regex + keyword list)
2. Check if concepts used in Week N were introduced in Week < N
3. Report violations

**Example output:**

```
⚠ Prerequisite Violations: Week 3

  ❌ Concept "chi-square test" used but not in prerequisites
     └─ First use: lectures/week-03_anova.qmd:127
     └─ Suggestion: Add to week_3 prerequisites or introduce in Week 2

  ✓ All other concepts properly sequenced

  Concept graph:
    Week 1: [mean, median, variance]
    Week 2: [distributions, hypothesis_testing] (builds on Week 1)
    Week 3: [anova, t_tests] (builds on Week 2)
```

**Phase 2 (AI-extracted concepts):** Coming later with Claude API integration

---

### 6. teach slides --analyze flag (PR #280 enhancement)

**Effort:** 3 hours
**Value:** Smart slide structure suggestions

Enhance PR #280's lecture-to-slides conversion:

```bash
teach slides --week 3 --analyze
```

**Analysis provides:**

1. **Suggested slide breaks** (beyond just H2/H3)
   - Detect concept transitions (topic modeling)
   - Identify natural pause points (after examples)
   - Flag dense paragraphs that need splitting

2. **Key concept identification**
   - Extract statistical terms/formulas
   - Suggest which to emphasize (callout boxes)
   - Recommend animation order

**Example output:**

```
📊 Slide Structure Analysis: Week 3

Current structure: 12 slides generated

Suggestions:
  ⚡ Split slide 4 (too dense)
     Current: 8 bullet points, 450 words
     Suggest: Break into 2 slides at "Example: T-test in R"

  💡 Emphasize key concepts
     Slide 3: Add callout for "Type I error definition"
     Slide 7: Add callout for "P-value interpretation"

  📈 Estimated presentation time: 28 minutes
     Target: 25 minutes
     Suggestion: Condense slides 9-10 (review material)

Apply suggestions? [Y/n]
```

**Implementation:**

- Extend `_teach_slides_from_lecture()` with `--analyze` flag
- Add `_teach_analyze_slide_structure()` helper
- Use heuristics: word count, bullet count, concept density

---

### 7. Readability scorer

**Effort:** 2 hours
**Value:** Accessibility improvement

Integrate textstat library (or ZSH-native heuristics):

- Flesch Reading Ease
- Gunning Fog Index
- Average sentence length
- Technical term density

**Output:**

```
📖 Readability: Week 3 Lecture

  Reading level: 14.2 (college sophomore)
  Target: 12-14 (appropriate ✓)

  Sentence length: 18.3 words/sentence (good)
  Technical terms: 8.2% of content (moderate)

  ℹ Suggestions:
    - Paragraph 3: Long sentence (42 words) - consider splitting
    - Section "ANOVA Theory": High technical density (15%) - add examples
```

---

## 🚀 Long-term Features (5-10 hours each)

### 8. AI-powered concept extraction (Phase 2 prerequisites)

**Effort:** 8 hours
**Value:** Automatic concept graph generation

Replace manual prerequisite definition with AI extraction:

1. **Extract concepts from each lecture** (Claude API)
   - Send lecture content to Claude
   - Prompt: "Extract key statistical concepts introduced"
   - Parse JSON response: `{concepts: ["t-test", "p-value", ...]}`

2. **Build dependency graph**
   - Analyze which concepts depend on others
   - Generate Mermaid diagram
   - Validate sequential introduction

3. **Auto-suggest prerequisites**
   - Propose prerequisites for each week
   - Show in `teach analyze` output
   - Offer to update lesson-plan.yml

**Example:**

```bash
teach analyze --extract-concepts
```

Output:

````
🔍 Extracted Concepts (AI Analysis)

Week 1: mean, median, mode, variance, standard_deviation
Week 2: distributions, normal_distribution, z_scores
Week 3: hypothesis_testing, t_tests, p_values

Dependency graph:
  Week 2 depends on: variance, standard_deviation (Week 1) ✓
  Week 3 depends on: distributions (Week 2) ✓

Suggested prerequisites for lesson-plan.yml:
```yaml
prerequisites:
  week_2: [variance, standard_deviation]
  week_3: [distributions, normal_distribution]
````

Apply suggestions to lesson-plan.yml? [Y/n]

````

---

### 9. Content gap analyzer
**Effort:** 6 hours
**Value:** Comprehensive course coverage

Compare course content against standard curriculum:

1. **Load reference syllabus** (from config or built-in)
   - Standard stats course topics
   - Bloom's taxonomy levels

2. **Analyze coverage**
   - Which topics are covered?
   - Which depth levels? (remember, apply, analyze)
   - Missing standard topics?

3. **Report gaps**

**Example:**
```bash
teach analyze --check-coverage
````

Output:

```
📚 Content Coverage Analysis

Standard Statistics Curriculum:
  ✓ Descriptive Statistics (100%)
  ✓ Probability Distributions (90%)
  ⚠ Hypothesis Testing (70%)
  ❌ ANOVA (40% - missing post-hoc tests)
  ❌ Non-parametric Tests (0% - not covered)

Bloom's Taxonomy Depth:
  Remember (definitions): ✓ Strong
  Understand (explanations): ✓ Strong
  Apply (R examples): ⚠ Moderate (add 3 more examples)
  Analyze (interpretation): ⚠ Moderate

Missing standard topics:
  - Bonferroni correction
  - Effect size measures
  - Wilcoxon rank-sum test

Recommendation: Add Week 12 covering non-parametric methods
```

---

### 10. teach analyze --interactive mode

**Effort:** 5 hours
**Value:** Guided improvement workflow

Step through findings one-by-one with actions:

```bash
teach analyze --interactive
```

**Flow:**

```
🔍 Analyzing Week 3 content... [################] 100%

Found 8 findings (3 errors, 3 warnings, 2 info)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Finding 1/8: Learning Objective Not Met
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Objective: "Perform t-tests in R"
Issue: Only 1 mention, 0 code examples
Severity: ERROR

Suggestion: Add 1-2 code examples demonstrating t.test() function

Options:
  [A] Add to my TODO list
  [S] Skip this finding
  [F] Fix now (open editor)
  [I] Mark as false positive
  [Q] Quit interactive mode

Your choice: _
```

**State management:**

- Save progress to `.teach/analysis-state.json`
- Resume with `teach analyze --interactive --resume`
- Track which findings were addressed

---

## 🏗️ Integration Architecture

### Command Flow

```
teach lecture "Topic" --week N
  ↓
teach validate                    # Syntax + YAML + render
  ↓
teach analyze [--week N|--all]   # ← NEW: Semantic validation
  ↓
teach deploy                      # Publish to GitHub Pages
```

### Data Flow

```
lesson-plan.yml (config)
  ├─ prerequisites: {...}
  ├─ learning_objectives: {...}
  └─ analysis: {...}
       ↓
lectures/*.qmd (content)
  ├─ YAML frontmatter
  ├─ Markdown content
  └─ R code chunks
       ↓
teach analyze
  ├─ Parse YAML with yq
  ├─ Extract text with Quarto
  ├─ Scan for concepts (regex + keywords)
  ├─ Validate against prerequisites
  └─ Generate report
       ↓
.teach/analysis-cache/
  ├─ week-01.json
  ├─ week-02.json
  └─ analysis-summary.json
       ↓
teach status (display summary)
```

---

## 🔗 Integration with PR #280 (teach slides)

PR #280 adds lecture-to-slides conversion. Integration points:

### 1. Enhance conversion with analysis

```bash
# Current (PR #280)
teach slides --week 3

# Enhanced (with analysis)
teach slides --week 3 --analyze
```

**What --analyze adds:**

- Pre-conversion analysis of lecture structure
- Suggested slide breaks (beyond H2/H3)
- Key concept identification for callouts
- Estimated presentation time
- Optional: Apply suggestions automatically

### 2. Share conversion logic

**Current PR #280 code:**

- `_teach_slides_from_lecture()` - main conversion
- `_teach_convert_lecture_to_slides()` - single file conversion
- `_teach_lecture_to_slides_preview()` - dry-run preview

**Proposed refactor for analysis integration:**

```zsh
# New shared helper
_teach_analyze_lecture_structure() {
    local lecture_file="$1"
    local mode="${2:-full}"  # full|slides|validate

    # Extract structure
    # - Count H2/H3 sections
    # - Identify code chunks
    # - Detect callouts
    # - Measure content density

    # Return JSON structure for use by:
    # - teach analyze
    # - teach slides --analyze
    # - teach validate --deep
}
```

**Benefits:**

- Single source of truth for lecture analysis
- teach slides can leverage teach analyze logic
- Consistent output format

### 3. teach slides recommendations integration

After conversion, show analysis:

```bash
teach slides --week 3

📄 Generated: slides/week-03_slides.qmd

💡 Slide Quality Analysis:
  ✓ Good: Balanced slide count (12 slides)
  ⚠ Dense: Slide 4 (8 bullets) - consider splitting
  ℹ Missing: No concept callouts - add for key definitions

  Estimated presentation time: 28 minutes

Run teach analyze slides/week-03_slides.qmd for detailed report
```

---

## 📦 Implementation Phases

### Phase 1: Foundation (Week 1-2, ~12 hours)

**Goal:** Basic analysis infrastructure

- ✅ teach analyze skeleton command (Quick Win #1)
- ✅ lesson-plan.yml schema for analysis config (Quick Win #2)
- ✅ teach status dashboard enhancement (Quick Win #3)
- ✅ Learning objective tracker - basic (Medium #4)
- ✅ Prerequisite checker - user-defined only (Medium #5)

**Deliverable:** `teach analyze --week N` shows basic report

---

### Phase 2: Slides Integration (Week 3, ~6 hours)

**Goal:** Enhance PR #280 with analysis

- ✅ teach slides --analyze flag (Medium #6)
- ✅ Shared lecture structure analyzer
- ✅ Readability scorer (Medium #7)

**Deliverable:** `teach slides --week N --analyze` provides smart suggestions

---

### Phase 3: AI-Powered Analysis (Week 4-5, ~14 hours)

**Goal:** Intelligent concept extraction

- ✅ AI-powered concept extraction (Long-term #8)
- ✅ Content gap analyzer (Long-term #9)
- ✅ Interactive analysis mode (Long-term #10)

**Deliverable:** `teach analyze --extract-concepts` auto-generates prerequisites

---

### Phase 4: Polish & Documentation (Week 6, ~6 hours)

**Goal:** Production-ready

- ✅ Comprehensive help text (`teach analyze --help`)
- ✅ Documentation in TEACHING-WORKFLOW-V3-GUIDE.md
- ✅ Test suite for analysis functions
- ✅ Quick reference card updates
- ✅ Example lesson-plan.yml with analysis config

**Deliverable:** Complete feature with docs and tests

---

## 🎯 Success Criteria

### User-facing

- ✅ `teach analyze` completes in < 30s for single week
- ✅ Provides actionable suggestions (not just problems)
- ✅ Integrates seamlessly with teach validate → deploy workflow
- ✅ Configurable strictness (don't overwhelm with warnings)
- ✅ Visual progress indicators (not silent processing)

### Technical

- ✅ Cached analysis results (invalidate on file changes)
- ✅ Shared code between teach analyze and teach slides
- ✅ No external dependencies beyond existing (yq, quarto)
- ✅ Graceful degradation if AI features unavailable
- ✅ Test coverage > 80% for analysis functions

### Integration

- ✅ teach validate still works standalone (no breaking changes)
- ✅ teach slides --analyze is optional (backward compatible with PR #280)
- ✅ teach status shows analysis summary
- ✅ teach deploy can optionally block if analysis fails

---

## ⚠️ Open Questions

### 1. AI Service Integration

**Question:** Use Claude API directly or Scholar service?
**Options:**

- A) Claude API (more flexible, requires API key management)
- B) Scholar service (existing integration, limited to teaching content)
- C) Hybrid (Scholar for content generation, Claude for analysis)

**Recommendation:** Start with B (Scholar), migrate to C if limitations found

---

### 2. Analysis Caching Strategy

**Question:** Where and how to cache analysis results?
**Options:**

- A) `.teach/analysis-cache/*.json` (local files)
- B) In-memory only (no persistence)
- C) SQLite database (`.teach/analysis.db`)

**Recommendation:** A (JSON files) - simple, git-ignorable, inspectable

---

### 3. teach validate integration

**Question:** Should teach validate auto-run teach analyze?
**Options:**

- A) Separate commands (explicit)
- B) teach validate --deep includes analysis
- C) teach validate --analyze flag

**Recommendation:** B (`--deep` flag) - progressive enhancement

---

### 4. Performance vs Accuracy Trade-off

**Question:** Fast heuristics or slow AI analysis?
**Options:**

- A) Fast heuristics only (< 5s)
- B) AI analysis only (30-60s)
- C) Hybrid: heuristics first, AI on demand (`--ai`)

**Recommendation:** C (hybrid approach) - fast by default, thorough when needed

---

### 5. teach slides --analyze output format

**Question:** How to present slide suggestions?
**Options:**

- A) Inline annotations in generated slides (comments)
- B) Separate report file (`week-03_slides-analysis.md`)
- C) Interactive terminal output only

**Recommendation:** C (terminal) + optional B with `--save-report`

---

## 🔄 Backward Compatibility

### No Breaking Changes

- ✅ teach validate works exactly as before
- ✅ teach slides (PR #280) works without --analyze flag
- ✅ lesson-plan.yml analysis section is optional
- ✅ All existing teach commands unchanged

### Opt-in Features

- teach analyze is new command (no conflicts)
- teach slides --analyze is new flag (optional)
- teach status shows analysis summary only if cache exists

### Configuration

- lesson-plan.yml analysis section has defaults
- Missing config doesn't break commands
- Warnings if analysis config is incomplete (not errors)

---

## 💡 Recommended Implementation Path

### Start Here (Phase 1 - Week 1)

1. ✅ Create teach analyze skeleton (Quick Win #1) - 20 min
2. ✅ Add lesson-plan.yml analysis schema (Quick Win #2) - 15 min
3. ✅ Enhance teach status (Quick Win #3) - 25 min

**Why:** Establishes foundation, enables parallel development

### Then (Phase 1 - Week 2)

4. ✅ Learning objective tracker (Medium #4) - 3 hours
5. ✅ Prerequisite checker basic (Medium #5) - 4 hours

**Why:** Core semantic validation, high user value

### Next (Phase 2 - Week 3)

6. ✅ teach slides --analyze (Medium #6) - 3 hours
7. ✅ Readability scorer (Medium #7) - 2 hours

**Why:** Enhances PR #280, delivers slide intelligence

### Future (Phase 3 - Later)

8. AI-powered features when ready
9. Interactive mode for power users
10. Content gap analysis for curriculum planning

---

## 📚 Related Work

### Existing Features to Build On

- teach validate (syntax validation)
- teach hooks (pre-commit checks)
- teach doctor (dependency verification)
- PR #280 teach slides (lecture conversion)
- lesson-plan.yml (structured semester data)

### Similar Tools (Inspiration)

- Grammarly (real-time content suggestions)
- Vale (prose linter for docs)
- markdownlint (markdown quality checks)
- textstat (readability analysis)
- Bloom's taxonomy validators (academic)

---

## 🏁 Next Steps

### Immediate (After Brainstorm)

1. **Review with comprehensive help plan**
   - Does teach analyze need dedicated help function?
   - Update teach --help with analysis workflow
   - Add to Quick Start tutorial (Phase 2 enhancement)

2. **Review PR #280 integration**
   - Can --analyze flag coexist with current implementation?
   - Any conflicts with help text updates?
   - Coordinate with PR #280 author

3. **Create SPEC document**
   - Capture this brainstorm as formal spec
   - Technical requirements section
   - API design for analysis functions

### This Week

1. Create feature branch `feature/teach-analyze`
2. Implement Quick Wins #1-3 (foundation)
3. Begin Medium #4 (learning objectives)

### This Month

1. Complete Phase 1 (foundation + basic analysis)
2. Complete Phase 2 (slides integration)
3. Update documentation and tests

---

**Status:** 🎨 Brainstorm Complete - Awaiting Agent Synthesis
**Duration:** ~15 minutes (initial ideas)
**Next:** Synthesize with backend architect + UX designer findings
