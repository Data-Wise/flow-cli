# Phase 1 Implementation Plan: Intelligent Content Analysis

**Feature:** `teach analyze` - AI-powered semantic validation for teaching content
**Branch:** `feature/teach-analyze` (to be created)
**Estimated Effort:** 12-14 hours (Phase 1 only)
**Dependencies:** PR #280 (recommended to merge first)
**Related Spec:** `SPEC-intelligent-content-analysis-2026-01-20.md`

---

## Phase 1 Scope: MVP Foundation

**Goal:** Basic concept extraction and prerequisite checking without breaking existing workflows.

**What's Included:**

- Core concept extraction from `.qmd` files
- Basic prerequisite validation (user-defined only)
- File-based storage (`.teach/concepts.json`)
- Simple CLI output (non-interactive)
- Integration with existing `teach validate`

**What's Deferred to Phase 2:**

- AI-powered concept extraction (Scholar API)
- Interactive TUI interface
- Slide optimization suggestions
- Cache invalidation system
- Performance monitoring

---

## Implementation Tasks (12-14 hours)

### Wave 1: Core Library (3-4 hours)

#### Task 1.1: Create Concept Extraction Library (90 min)

**File:** `lib/concept-extraction.zsh` (~400 lines)

**Functions to implement:**

```zsh
_extract_concepts_simple()      # Extract from YAML frontmatter only
_parse_concept_metadata()       # Parse concept: field in frontmatter
_build_concept_graph()          # Build simple graph structure
_save_concept_graph()           # Save to .teach/concepts.json
_load_concept_graph()           # Load from .teach/concepts.json
```

**Key Data Structure:**

```json
{
  "version": "1.0",
  "schema_version": "concept-graph-v1",
  "last_updated": "2026-01-20T14:30:00Z",
  "concepts": {
    "regression-assumptions": {
      "id": "regression-assumptions",
      "title": "Regression Assumptions",
      "prerequisites": ["correlation", "variance"],
      "introduced_in": {
        "week": 3,
        "lecture": "lectures/week-03-lecture.qmd",
        "line_number": 12
      }
    }
  }
}
```

**Implementation Notes:**

- Use `yq` to extract YAML frontmatter
- Parse custom `concepts:` field from frontmatter
- Handle missing fields gracefully (empty arrays)
- Atomic file writes (write to temp, then move)

**Test Coverage:**

- Extract concepts from sample lecture
- Build graph with 5 concepts
- Save/load round-trip
- Handle malformed YAML

---

#### Task 1.2: Create Prerequisite Checker (90 min)

**File:** `lib/prerequisite-checker.zsh` (~300 lines)

**Functions to implement:**

```zsh
_check_prerequisites()          # Check if prereqs are met before concept
_find_missing_prerequisites()   # List missing prereqs
_validate_prerequisite_order()  # Check week ordering
_get_prerequisite_chain()       # Build dependency chain
_format_prerequisite_report()   # Human-readable output
```

**Validation Rules:**

- A concept's prerequisites must be introduced in earlier weeks
- Flag concepts with circular dependencies
- Flag concepts with prerequisites from future weeks
- Suggest optimal week ordering

**Test Coverage:**

- Detect missing prerequisites
- Detect circular dependencies
- Detect future-week prerequisites
- Generate correct recommendations

---

#### Task 1.3: Create teach analyze Command (60 min)

**File:** `commands/teach-analyze.zsh` (~250 lines)

**Command Structure:**

```bash
teach analyze [options]

Options:
  --file FILE           Analyze single file
  --week N              Analyze week N only
  --all                 Analyze all content (default)
  --format text|json    Output format (default: text)
  --quiet               Suppress warnings
```

**Output Format:**

```
╔═══════════════════════════════════════════════════════════╗
║  Content Analysis Report                                  ║
╚═══════════════════════════════════════════════════════════╝

Concepts Extracted: 18 total
  Week 1: 3 concepts (correlation, mean, variance)
  Week 2: 4 concepts (t-test, hypothesis, p-value, confidence-interval)
  Week 3: 5 concepts (regression, residuals, r-squared, ...)

Prerequisite Validation:
  ✓ 15 concepts have all prerequisites met
  ✗ 3 concepts have missing prerequisites:

    • regression-diagnostics (Week 5)
      Missing: heteroskedasticity (introduced Week 7)
      Recommendation: Move to Week 8 or earlier

    • interaction-effects (Week 6)
      Missing: factor-variables (not yet introduced)
      Recommendation: Add to Week 5 content

Concept Coverage:
  Total concepts: 18
  Concepts with prerequisites: 15
  Orphaned concepts: 3 (no prerequisites defined)
```

**Implementation:**

1. Load concept graph (or build if missing)
2. Run prerequisite validation
3. Format output (text or JSON)
4. Exit with status code (0 = success, 1 = warnings, 2 = errors)

**Test Coverage:**

- Analyze single file
- Analyze full course
- JSON output validation
- Exit code verification

---

### Wave 2: Integration (2-3 hours)

#### Task 2.1: Update teach validate (45 min)

**File:** `commands/teach-validate.zsh`

**Add new flag:**

```bash
teach validate --concepts    # Run concept prerequisite checks
```

**Integration:**

- Call `_check_prerequisites()` from teach validate
- Include in default validation suite
- Add to git pre-commit hook (optional flag)

**Changes:**

```zsh
# In _teach_validate()
if [[ $validate_concepts == true || $validate_all == true ]]; then
    _flow_log_section "Prerequisite Validation"
    if ! _check_prerequisites; then
        ((error_count++))
    fi
fi
```

---

#### Task 2.2: Update teach status (30 min)

**File:** `lib/status-dashboard.zsh`

**Add new section:**

```
Concept Analysis:
  Total concepts: 18
  Prerequisites validated: ✓
  Last analysis: 2 hours ago
  Run: teach analyze
```

**Implementation:**

- Check if `.teach/concepts.json` exists
- Display last modification time
- Show concept count
- Link to `teach analyze` command

---

#### Task 2.3: Update teach dispatcher (30 min)

**File:** `lib/dispatchers/teach-dispatcher.zsh`

**Add routing:**

```zsh
case "$1" in
    analyze|concept|concepts)
        shift
        _teach_analyze "$@"
        ;;
    # ... existing cases
esac
```

**Add help:**

```zsh
_teach_analyze_help() {
    cat <<EOF
╔═══════════════════════════════════════════════════════════╗
║  teach analyze - Intelligent Content Analysis             ║
╚═══════════════════════════════════════════════════════════╝

USAGE
  teach analyze [options]

QUICK START
  $ teach analyze                    # Analyze all content
  $ teach analyze --week 5           # Analyze Week 5 only
  $ teach analyze --format json      # JSON output

OPTIONS
  --file FILE           Analyze single file
  --week N              Analyze week N only
  --all                 Analyze all content (default)
  --format text|json    Output format
  --quiet               Suppress warnings

EXAMPLES
  Basic analysis:
    $ teach analyze
    # Shows: 18 concepts, 3 prerequisite warnings

  Week-specific:
    $ teach analyze --week 5
    # Only validate Week 5 prerequisites

  JSON for CI/CD:
    $ teach analyze --format json > analysis.json
    # Parseable output for automation

TIPS
  • Add concepts: field to lecture frontmatter
  • Use --concepts flag with teach validate
  • Run before deployment to catch ordering issues

SEE ALSO
  teach validate        Run all quality checks
  teach status          View analysis summary
  docs/guides/INTELLIGENT-CONTENT-ANALYSIS.md
EOF
}
```

---

#### Task 2.4: Update flow.plugin.zsh (15 min)

**Source new libraries:**

```zsh
# Teaching workflow libraries
source "$FLOW_PLUGIN_ROOT/lib/concept-extraction.zsh"
source "$FLOW_PLUGIN_ROOT/lib/prerequisite-checker.zsh"
source "$FLOW_PLUGIN_ROOT/commands/teach-analyze.zsh"
```

---

### Wave 3: Configuration (1-2 hours)

#### Task 3.1: Update lesson-plan.yml Schema (45 min)

**Add concepts section:**

```yaml
# Optional: Define high-level concepts for automatic validation
concepts:
  # Week-level concepts
  weeks:
    1:
      introduces: [correlation, mean, variance]
      requires: [] # Week 1 has no prerequisites

    2:
      introduces: [t-test, hypothesis-testing, p-value]
      requires: [mean, variance] # From Week 1

    3:
      introduces: [simple-regression, residuals, r-squared]
      requires: [correlation, hypothesis-testing]

  # Global prerequisites (always checked)
  global_prerequisites:
    - concept: matrix-algebra
      required_for: [multiple-regression, ridge-regression]
      introduced: 'external' # Not in this course

  # Analysis settings
  analysis:
    auto_extract: true # Extract concepts from frontmatter
    strict_ordering: true # Enforce week-based ordering
    warn_orphans: true # Warn about concepts with no prereqs
```

**Implementation:**

- Schema validation for concepts section
- Merge with frontmatter-extracted concepts
- Use as primary source if present

---

#### Task 3.2: Update Lecture Frontmatter (30 min)

**Add concepts field:**

```yaml
---
title: 'Linear Regression Assumptions'
week: 3
date: 2026-02-03
concepts:
  introduces:
    - regression-assumptions
    - normality-test
    - homoskedasticity
  requires:
    - simple-regression
    - residuals
---
```

**Documentation:**

- Add to teaching workflow guide
- Provide examples for all content types
- Document optional vs required fields

---

#### Task 3.3: Create Sample Content (45 min)

**Files to create:**

1. `.teach/concepts.json.example` - Example concept graph
2. `lectures/example-with-concepts.qmd` - Sample lecture with concepts
3. `lesson-plan-with-concepts.yml` - Example configuration

**Purpose:**

- Provide copy-paste templates
- Show best practices
- Enable quick testing

---

### Wave 4: Testing (3-4 hours)

#### Task 4.1: Unit Tests (2 hours)

**File:** `tests/test-teach-analyze-unit.zsh`

**Test Suites:**

1. Concept extraction (15 tests)
   - Extract from frontmatter
   - Handle missing concepts field
   - Parse introduces/requires arrays
   - Build concept graph

2. Prerequisite checking (20 tests)
   - Detect missing prerequisites
   - Detect circular dependencies
   - Detect future-week prerequisites
   - Validate week ordering
   - Build dependency chains

3. teach analyze command (15 tests)
   - Single file analysis
   - Week-specific analysis
   - Full course analysis
   - JSON output format
   - Exit codes

4. Configuration parsing (10 tests)
   - Parse lesson-plan.yml concepts
   - Merge with frontmatter
   - Validate schema
   - Handle malformed config

**Target:** 60 tests, 95%+ pass rate

---

#### Task 4.2: Integration Tests (1-2 hours)

**File:** `tests/test-teach-analyze-integration.zsh`

**Test Scenarios:**

1. Full workflow test (8 steps)
   - Initialize course
   - Add concepts to 3 lectures
   - Run teach analyze
   - Verify warnings for missing prereqs
   - Fix prerequisites
   - Re-run analysis
   - Verify clean result
   - Check integration with teach validate

2. teach validate integration
   - Run with --concepts flag
   - Verify prerequisite checks included
   - Check exit codes

3. teach status integration
   - Verify concept section appears
   - Check concept count accuracy
   - Verify last analysis timestamp

4. JSON output validation
   - Parse JSON output
   - Verify schema compliance
   - Test CI/CD usage pattern

**Target:** 20 integration tests

---

### Wave 5: Documentation (2-3 hours)

#### Task 5.1: User Guide (90 min)

**File:** `docs/guides/INTELLIGENT-CONTENT-ANALYSIS.md`

**Structure:**

1. Overview (what is concept analysis?)
2. Quick Start (5-minute tutorial)
3. Configuration (lesson-plan.yml + frontmatter)
4. Commands (teach analyze, teach validate --concepts)
5. Best Practices (when to define concepts, granularity)
6. Troubleshooting (common warnings, how to fix)
7. Integration (with existing workflow)

**Length:** ~1,500 lines

---

#### Task 5.2: Quick Reference Card (45 min)

**File:** `docs/reference/REFCARD-CONTENT-ANALYSIS.md`

**Contents:**

- Command syntax (teach analyze)
- Flag reference (--week, --file, --format)
- Frontmatter schema (concepts field)
- lesson-plan.yml schema (concepts section)
- Common validation errors and fixes

**Length:** ~400 lines

---

#### Task 5.3: Update Existing Docs (45 min)

**Files to update:**

1. `docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md`
   - Add teach analyze to workflow steps
   - Add prerequisite validation to quality checks

2. `docs/reference/TEACH-DISPATCHER-REFERENCE.md`
   - Add teach analyze command reference

3. `README.md`
   - Add to features list
   - Update examples

4. `CHANGELOG.md`
   - Add v5.15.0 entry for Phase 1

---

### Wave 6: Polish & Release Prep (1-2 hours)

#### Task 6.1: Error Handling (45 min)

**Robustness checks:**

- Handle missing `.teach/` directory (create)
- Handle corrupted concepts.json (rebuild)
- Handle missing lesson-plan.yml (optional)
- Handle invalid YAML in frontmatter
- Provide helpful error messages

---

#### Task 6.2: Performance Optimization (30 min)

**Optimizations:**

- Cache concept graph in memory during analysis
- Batch file parsing (don't re-read same file)
- Skip non-.qmd files
- Use parallel file scanning (if > 20 files)

**Target:** < 2s for 20 lectures

---

#### Task 6.3: Final Testing & Validation (45 min)

**Checklist:**

- [ ] All unit tests pass (60 tests)
- [ ] All integration tests pass (20 tests)
- [ ] Manual walkthrough of Quick Start guide
- [ ] teach analyze --help displays correctly
- [ ] teach validate --concepts works
- [ ] teach status shows concept section
- [ ] JSON output validates against schema
- [ ] Documentation renders in mkdocs
- [ ] No breaking changes to existing commands

---

## File Structure

**New Files (10):**

```
lib/
  concept-extraction.zsh           # 400 lines
  prerequisite-checker.zsh         # 300 lines

commands/
  teach-analyze.zsh                # 250 lines

tests/
  test-teach-analyze-unit.zsh      # 800 lines (60 tests)
  test-teach-analyze-integration.zsh  # 600 lines (20 tests)

docs/
  guides/INTELLIGENT-CONTENT-ANALYSIS.md     # 1,500 lines
  reference/REFCARD-CONTENT-ANALYSIS.md      # 400 lines

.teach/
  concepts.json.example            # 200 lines

lectures/
  example-with-concepts.qmd        # 150 lines
```

**Modified Files (7):**

```
lib/dispatchers/teach-dispatcher.zsh    # +150 lines (routing + help)
commands/teach-validate.zsh             # +50 lines (--concepts flag)
lib/status-dashboard.zsh                # +40 lines (concept section)
flow.plugin.zsh                         # +10 lines (source libraries)
docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md  # +300 lines
docs/reference/TEACH-DISPATCHER-REFERENCE.md  # +200 lines
README.md                               # +50 lines
CHANGELOG.md                            # +100 lines
```

**Total:**

- Production code: ~1,850 lines
- Tests: ~1,400 lines
- Documentation: ~2,650 lines
- **Total: ~5,900 lines**

---

## Dependencies

### External Tools (already available):

- `yq` (YAML parsing) ✅ Available via teach doctor
- `jq` (JSON parsing) ✅ Available via teach doctor
- ZSH 5.8+ ✅ Already required

### Internal Dependencies:

- `lib/core.zsh` (logging, colors)
- `lib/validation-helpers.zsh` (YAML validation)
- `lib/status-dashboard.zsh` (status integration)

### Optional Dependencies:

- PR #280 (teach slides) - Recommended to merge first for better integration

---

## Testing Strategy

### Unit Testing:

- Test each function in isolation
- Use mock data for file parsing
- 60 unit tests targeting 95%+ coverage

### Integration Testing:

- Full workflow tests (8-step scenarios)
- Command integration (validate, status)
- 20 integration tests for real-world usage

### Manual Testing:

- Follow Quick Start guide step-by-step
- Test with real course content
- Verify documentation accuracy

---

## Success Criteria

**Phase 1 Complete when:**

- ✅ `teach analyze` command works with all flags
- ✅ Concept extraction from frontmatter functional
- ✅ Prerequisite validation detects ordering issues
- ✅ Integration with teach validate works
- ✅ teach status shows concept summary
- ✅ 80 tests pass (60 unit + 20 integration)
- ✅ Documentation complete and accurate
- ✅ Zero breaking changes to existing commands
- ✅ User guide walkthrough succeeds

**Performance Targets:**

- < 2s to analyze 20 lectures
- < 5s to analyze 50 lectures
- < 100ms to load cached concept graph

**Quality Targets:**

- 95%+ test pass rate
- Zero regressions in existing tests
- All help text follows FLOW_COLORS standards
- Documentation renders correctly in mkdocs

---

## Risk Mitigation

### Risk 1: YAML Parsing Complexity

**Mitigation:** Use established `yq` library, add robust error handling

### Risk 2: Concept Graph Complexity

**Mitigation:** Keep Phase 1 simple (user-defined only), defer AI extraction to Phase 2

### Risk 3: Performance with Large Courses

**Mitigation:** Implement caching early, test with 50+ lectures

### Risk 4: Integration Breakage

**Mitigation:** Comprehensive integration tests, manual testing of existing commands

---

## Timeline Estimate

| Wave      | Tasks                   | Effort          | Duration   |
| --------- | ----------------------- | --------------- | ---------- |
| Wave 1    | Core library (3 tasks)  | 4 hours         | Day 1      |
| Wave 2    | Integration (4 tasks)   | 2.5 hours       | Day 1-2    |
| Wave 3    | Configuration (3 tasks) | 2 hours         | Day 2      |
| Wave 4    | Testing (2 tasks)       | 3.5 hours       | Day 2-3    |
| Wave 5    | Documentation (3 tasks) | 3 hours         | Day 3      |
| Wave 6    | Polish (3 tasks)        | 2 hours         | Day 3      |
| **Total** | **18 tasks**            | **12-14 hours** | **3 days** |

**Note:** This is orchestrated development time with parallel tasks where possible.

---

## Implementation Commands

### 1. Create Feature Branch

```bash
cd ~/projects/dev-tools/flow-cli
git checkout dev
git pull origin dev
git worktree add ~/.git-worktrees/flow-cli/teach-analyze -b feature/teach-analyze dev
```

### 2. Start Implementation

```bash
cd ~/.git-worktrees/flow-cli/teach-analyze
claude  # Start NEW session

# Follow task order: Wave 1 → Wave 2 → ... → Wave 6
```

### 3. Testing During Development

```bash
# Run unit tests after each wave
./tests/test-teach-analyze-unit.zsh

# Run integration tests after Wave 4
./tests/test-teach-analyze-integration.zsh

# Run full test suite before PR
./tests/run-all.sh
```

### 4. Create PR

```bash
# After Wave 6 complete
git add -A
git commit -m "feat: add teach analyze (Phase 1 - concept extraction)"
git push origin feature/teach-analyze
gh pr create --base dev --title "feat: Intelligent Content Analysis (Phase 1)"
```

---

## Notes

- **PR #280 Integration:** If PR #280 is merged first, teach analyze can reference slide structure in future phases
- **Backward Compatibility:** All features are opt-in (--concepts flag), zero breaking changes
- **Phase 2 Readiness:** Phase 1 architecture designed to support AI enhancement in Phase 2
- **ADHD-Friendly:** Simple commands, clear output, minimal configuration required

---

## Related Documents

- `SPEC-intelligent-content-analysis-2026-01-20.md` - Complete specification (all phases)
- `BRAINSTORM-intelligent-content-analysis-2026-01-20.md` - Initial brainstorm
- `docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md` - Main teaching workflow guide

---

**Created:** 2026-01-20
**Status:** Ready for Implementation
**Target Version:** v5.15.0
