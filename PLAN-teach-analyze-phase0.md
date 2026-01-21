# Phase 0 Implementation Plan: teach analyze (Ultra-MVP)

**Feature:** `teach analyze` - Prerequisite validation for teaching content
**Branch:** `feature/teach-analyze` (to be created)
**Estimated Effort:** 4-5 hours
**Dependencies:** None (pure ZSH, no AI)
**Spec:** `SPEC-intelligent-content-analysis-2026-01-20.md`

---

## 🎯 Phase 0 Goal

**Prove the concept with minimal features:**

- Extract concepts from frontmatter
- Validate prerequisite ordering
- Report violations
- Zero AI dependency

**User Value:** Catch prerequisite ordering mistakes before deployment (e.g., Week 5 requires concept from Week 7).

---

## ✅ Success Criteria

- User can add `concepts:` field to lecture frontmatter
- `teach analyze lectures/week-05.qmd` validates prerequisites
- Warning displayed if prerequisite from future week
- < 2s analysis time (single lecture)
- 25 tests pass (20 unit + 5 integration)
- Help text with examples
- Zero breaking changes to existing commands

---

## 📦 Deliverables (5 files)

1. `lib/concept-extraction.zsh` (250 lines)
2. `lib/prerequisite-checker.zsh` (200 lines)
3. `commands/teach-analyze.zsh` (150 lines)
4. Integration updates (50 lines)
5. Test suite (600 lines)

**Total:** ~1,250 lines of code + tests

---

## 🏗️ Task Breakdown

### Wave 1: Core Library (2 hours)

#### Task 1.1: Create Concept Extraction Library (60 min)

**File:** `lib/concept-extraction.zsh` (~250 lines)

**Functions to implement:**

```zsh
# Extract concepts from frontmatter YAML
_extract_concepts_from_frontmatter() {
    local file="$1"
    # Use yq to parse concepts: field
    # Return JSON array of concepts
}

# Parse concepts.introduces array
_parse_introduced_concepts() {
    local yaml_content="$1"
    # Extract array of concept objects
    # Return: id, title, difficulty (optional)
}

# Parse concepts.requires array
_parse_required_concepts() {
    local yaml_content="$1"
    # Extract array of prerequisite concept IDs
}

# Build simple concept graph
_build_concept_graph() {
    local course_dir="$1"
    # Scan all .qmd files in lectures/, assignments/
    # Extract concepts from each
    # Build graph with introduced_in metadata
    # Save to .teach/concepts.json
}

# Load existing concept graph
_load_concept_graph() {
    local concepts_file=".teach/concepts.json"
    if [[ -f "$concepts_file" ]]; then
        cat "$concepts_file"
    else
        echo "{}"
    fi
}

# Save concept graph to file
_save_concept_graph() {
    local graph_json="$1"
    local concepts_file=".teach/concepts.json"

    # Create .teach/ directory if missing
    mkdir -p ".teach"

    # Atomic write (write to temp, then move)
    echo "$graph_json" > "${concepts_file}.tmp"
    mv "${concepts_file}.tmp" "$concepts_file"
}

# Get week number from file path
_get_week_from_file() {
    local file="$1"
    # Extract week number from filename or frontmatter
    # Return: week number or 0 if unknown
}

# Get line number where concept introduced
_get_concept_line_number() {
    local file="$1"
    local concept_id="$2"
    # Search for concept ID in frontmatter
    # Return line number (approximate)
}
```

**Data Structure (concepts.json):**

```json
{
  "version": "1.0",
  "schema_version": "concept-graph-v1",
  "metadata": {
    "last_updated": "2026-01-20T15:00:00Z",
    "course_hash": "",
    "total_concepts": 5,
    "weeks": 8,
    "extraction_method": "frontmatter"
  },
  "concepts": {
    "correlation": {
      "id": "correlation",
      "name": "Correlation",
      "prerequisites": [],
      "introduced_in": {
        "week": 3,
        "lecture": "lectures/week-03-lecture.qmd",
        "line_number": 5
      }
    },
    "regression-assumptions": {
      "id": "regression-assumptions",
      "name": "Regression Assumptions",
      "prerequisites": ["correlation", "variance"],
      "introduced_in": {
        "week": 5,
        "lecture": "lectures/week-05-lecture.qmd",
        "line_number": 8
      }
    }
  }
}
```

**Implementation Notes:**

- Use `yq` to parse YAML frontmatter (already available via teach doctor)
- Handle missing `concepts:` field gracefully (skip file)
- Handle malformed YAML (log warning, skip file)
- Extract week number from filename (e.g., week-05-lecture.qmd → 5)
- Fallback to frontmatter `week:` field if filename doesn't match

**Error Handling:**

- File not found → Return empty result, log error
- YAML parse error → Log warning, skip file
- Missing concepts field → Skip file (not an error)
- Invalid concept structure → Log warning, skip concept

---

#### Task 1.2: Create Prerequisite Checker (60 min)

**File:** `lib/prerequisite-checker.zsh` (~200 lines)

**Functions to implement:**

```zsh
# Check if prerequisites are satisfied
_check_prerequisites() {
    local concepts_json="$1"
    # For each concept, verify prerequisites are from earlier weeks
    # Return: array of violations
}

# Check single concept prerequisites
_check_concept_prerequisites() {
    local concept_id="$1"
    local concept_data="$2"
    local all_concepts="$3"
    # Verify each prerequisite exists and is from earlier week
}

# Find missing prerequisites
_find_missing_prerequisites() {
    local concept_id="$1"
    local required_prereqs="$2"
    local all_concepts="$3"
    # Return: array of prerequisite IDs that don't exist
}

# Find future-week prerequisites
_find_future_prerequisites() {
    local concept_id="$1"
    local concept_week="$2"
    local required_prereqs="$3"
    local all_concepts="$4"
    # Return: array of prerequisites introduced in future weeks
}

# Format prerequisite violation
_format_prerequisite_violation() {
    local concept_id="$1"
    local concept_week="$2"
    local violation_type="$3"  # "missing" or "future"
    local prereq_id="$4"
    local prereq_week="$5"
    # Return formatted error message with suggestion
}

# Get dependency chain
_get_dependency_chain() {
    local concept_id="$1"
    local all_concepts="$2"
    # Return: array of concept IDs in dependency order
    # Used for detecting circular dependencies (Phase 1+)
}
```

**Validation Rules:**

1. **Missing prerequisite:**
   - Concept requires prerequisite that doesn't exist anywhere
   - **Severity:** ERROR
   - **Suggestion:** "Add `correlation` concept to earlier week, or remove from requires list"

2. **Future prerequisite:**
   - Concept requires prerequisite from later week
   - **Severity:** WARNING
   - **Suggestion:** "Move `hypothesis-testing` from Week 7 to Week 4, or remove from requires list"

3. **Circular dependency (not in Phase 0):**
   - Concept A requires B, B requires A
   - Defer to Phase 1

**Output Format:**

```
🔗 PREREQUISITE VALIDATION

Week 5: regression-assumptions
  ✗ ERROR: Missing prerequisite: matrix-algebra
     Suggestion: Add matrix-algebra to earlier week

Week 7: interaction-effects
  ⚠ WARNING: Future prerequisite: factor-variables (Week 9)
     Suggestion: Move factor-variables to Week 6 or earlier
```

---

### Wave 2: Command Implementation (1 hour)

#### Task 2.1: Create teach analyze Command (60 min)

**File:** `commands/teach-analyze.zsh` (~150 lines)

**Main function:**

```zsh
_teach_analyze() {
    local file="$1"

    # Validate arguments
    if [[ -z "$file" ]]; then
        _flow_log_error "Usage: teach analyze <file>"
        return 1
    fi

    if [[ ! -f "$file" ]]; then
        _flow_log_error "File not found: $file"
        return 1
    fi

    # Show progress
    _flow_log_info "Analyzing: $file"

    # Build concept graph from all course files
    _flow_log_step "Building concept graph..."
    local concepts_json=$(_build_concept_graph ".")

    # Check prerequisites
    _flow_log_step "Checking prerequisites..."
    local violations=$(_check_prerequisites "$concepts_json")

    # Display results
    _display_analysis_results "$file" "$concepts_json" "$violations"

    # Exit code
    if [[ $(echo "$violations" | jq 'length') -gt 0 ]]; then
        return 1  # Has warnings/errors
    else
        return 0  # Clean
    fi
}

_display_analysis_results() {
    local file="$1"
    local concepts_json="$2"
    local violations="$3"

    # Header box
    echo "${FLOW_COLORS[header]}╭─────────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Content Analysis Report - $(basename "$file")  "
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Mode: moderate | Phase: 0 (heuristic-only)  "
    echo "${FLOW_COLORS[header]}╰─────────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
    echo

    # Concepts section
    _display_concepts_section "$file" "$concepts_json"
    echo

    # Prerequisites section
    _display_prerequisites_section "$file" "$concepts_json"
    echo

    # Violations section (if any)
    if [[ $(echo "$violations" | jq 'length') -gt 0 ]]; then
        _display_violations_section "$violations"
        echo
    fi

    # Summary
    _display_summary_section "$violations"
}

_display_concepts_section() {
    # Show concepts extracted from this file
}

_display_prerequisites_section() {
    # Show prerequisites and their status (satisfied/missing/future)
}

_display_violations_section() {
    # Show all prerequisite violations with suggestions
}

_display_summary_section() {
    # Show status: READY or WARNINGS
    # Show next steps
}
```

**CLI Output Example:**

```bash
$ teach analyze lectures/week-05-regression.qmd

Analyzing: lectures/week-05-regression.qmd
Building concept graph... ✓
Checking prerequisites... ✓

╭─────────────────────────────────────────────────────╮
│  Content Analysis Report - week-05-regression.qmd   │
│  Mode: moderate | Phase: 0 (heuristic-only)        │
╰─────────────────────────────────────────────────────╯

📊 CONCEPT COVERAGE
┌────────────────────────────────────────────────────┐
│ Concept                    | Status                │
├────────────────────────────┼───────────────────────┤
│ Simple Linear Regression   │ ✓ Introduced (Week 5) │
│ Residual Analysis          │ ✓ Introduced (Week 5) │
│ R-squared Interpretation   │ ✓ Introduced (Week 5) │
└────────────────────────────────────────────────────┘

🔗 PREREQUISITES
┌────────────────────────────────────────────────────┐
│ Prerequisite          | Status                     │
├───────────────────────┼────────────────────────────┤
│ correlation (Week 3)  │ ✓ Satisfied                │
│ variance (Week 1)     │ ✓ Satisfied                │
└────────────────────────────────────────────────────┘

╭─────────────────────────────────────────────────────╮
│                      SUMMARY                        │
╰─────────────────────────────────────────────────────╯

  Status: ✓ READY TO DEPLOY (0 errors, 0 warnings)

  ✓ All prerequisites satisfied
  ✓ All concepts properly defined

Next steps:
  1. Deploy content: teach deploy --preview
  2. Or continue editing: quarto preview lectures/week-05-regression.qmd
```

---

### Wave 3: Integration (30 min)

#### Task 3.1: Update flow.plugin.zsh (5 min)

**File:** `flow.plugin.zsh`

**Add source statements:**

```zsh
# Teaching workflow libraries
source "$FLOW_PLUGIN_ROOT/lib/concept-extraction.zsh"
source "$FLOW_PLUGIN_ROOT/lib/prerequisite-checker.zsh"
source "$FLOW_PLUGIN_ROOT/commands/teach-analyze.zsh"
```

---

#### Task 3.2: Update teach-dispatcher.zsh (20 min)

**File:** `lib/dispatchers/teach-dispatcher.zsh`

**Add routing (around line 2950):**

```zsh
case "$1" in
    analyze|concept|concepts)
        case "$2" in
            --help|-h|help)
                _teach_analyze_help
                return 0
                ;;
            *)
                shift
                _teach_analyze "$@"
                ;;
        esac
        ;;
    # ... existing cases
esac
```

**Add help function (around line 2700):**

```zsh
_teach_analyze_help() {
    cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach analyze${FLOW_COLORS[reset]} - Intelligent Content Analysis              ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach analyze${FLOW_COLORS[reset]} <file>

${FLOW_COLORS[success]}🔥 QUICK START${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} teach analyze lectures/week-05-regression.qmd
  ${FLOW_COLORS[dim]}# Validates concepts and prerequisites${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}WHAT IT DOES${FLOW_COLORS[reset]}
  1. Extracts concepts from frontmatter (concepts: field)
  2. Builds concept graph across all lectures
  3. Validates prerequisite ordering (earlier weeks only)
  4. Reports violations with suggestions

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[info]}Basic analysis:${FLOW_COLORS[reset]}
    ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} teach analyze lectures/week-05-regression.qmd
    ${FLOW_COLORS[dim]}# Checks prerequisites for Week 5${FLOW_COLORS[reset]}

  ${FLOW_COLORS[info]}What gets checked:${FLOW_COLORS[reset]}
    • Concepts are defined in frontmatter
    • Prerequisites exist in earlier weeks
    • No future-week dependencies

${FLOW_COLORS[info]}💡 TIPS${FLOW_COLORS[reset]}
  • Add ${FLOW_COLORS[cmd]}concepts:${FLOW_COLORS[reset]} field to lecture frontmatter
  • Use concept IDs consistently across lectures
  • Run before deployment to catch ordering issues

${FLOW_COLORS[bold]}FRONTMATTER EXAMPLE${FLOW_COLORS[reset]}
  ---
  title: "Linear Regression"
  week: 5
  concepts:
    introduces:
      - id: simple-regression
      - id: r-squared
    requires:
      - correlation  # From Week 3
      - variance     # From Week 1
  ---

${FLOW_COLORS[dim]}📚 See also:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach validate${FLOW_COLORS[reset]}   Run quality checks
  ${FLOW_COLORS[dim]}docs/guides/INTELLIGENT-CONTENT-ANALYSIS.md${FLOW_COLORS[reset]}
EOF
}
```

---

#### Task 3.3: Update main teach help (5 min)

**File:** `lib/dispatchers/teach-dispatcher.zsh`

**Add to help output (in `_teach_dispatcher_help()`):**

```zsh
${FLOW_COLORS[bold]}✅ VALIDATION & QUALITY${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach analyze${FLOW_COLORS[reset]}           Validate content prerequisites (NEW)
  ${FLOW_COLORS[cmd]}teach validate${FLOW_COLORS[reset]}          Validate content quality
  ${FLOW_COLORS[cmd]}teach cache${FLOW_COLORS[reset]}             Manage Quarto cache

  ${FLOW_COLORS[muted]}Example:${FLOW_COLORS[reset]}
    ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} teach analyze lectures/week-05.qmd  ${FLOW_COLORS[dim]}# Check prerequisites${FLOW_COLORS[reset]}
```

---

### Wave 4: Testing (1.5 hours)

#### Task 4.1: Unit Tests - Concept Extraction (30 min)

**File:** `tests/test-teach-analyze-phase0-unit.zsh`

**Test Suite 1: Concept Extraction (10 tests)**

```zsh
#!/usr/bin/env zsh

# Test 1: Extract concepts from valid frontmatter
test_extract_concepts_valid() {
    # Setup: Create temp .qmd file with concepts
    # Execute: _extract_concepts_from_frontmatter
    # Assert: Concepts extracted correctly
}

# Test 2: Handle missing concepts field
test_extract_concepts_missing() {
    # Setup: Create .qmd file without concepts field
    # Execute: _extract_concepts_from_frontmatter
    # Assert: Returns empty array, no error
}

# Test 3: Handle malformed YAML
test_extract_concepts_malformed_yaml() {
    # Setup: Create .qmd with invalid YAML
    # Execute: _extract_concepts_from_frontmatter
    # Assert: Returns empty array, logs warning
}

# Test 4: Extract week number from filename
test_get_week_from_filename() {
    # Execute: _get_week_from_file "week-05-regression.qmd"
    # Assert: Returns 5
}

# Test 5: Extract week number from frontmatter
test_get_week_from_frontmatter() {
    # Setup: File without week in name, but in frontmatter
    # Execute: _get_week_from_file
    # Assert: Returns correct week from YAML
}

# Test 6: Build concept graph from multiple files
test_build_concept_graph() {
    # Setup: Create 3 .qmd files with concepts
    # Execute: _build_concept_graph
    # Assert: Graph has 3 concepts with correct metadata
}

# Test 7: Save concept graph to file
test_save_concept_graph() {
    # Execute: _save_concept_graph
    # Assert: .teach/concepts.json created with correct structure
}

# Test 8: Load concept graph from file
test_load_concept_graph() {
    # Setup: Create .teach/concepts.json
    # Execute: _load_concept_graph
    # Assert: Returns parsed JSON
}

# Test 9: Parse introduced concepts array
test_parse_introduced_concepts() {
    # Setup: YAML with concepts.introduces
    # Execute: _parse_introduced_concepts
    # Assert: Returns array of concept objects
}

# Test 10: Parse required concepts array
test_parse_required_concepts() {
    # Setup: YAML with concepts.requires
    # Execute: _parse_required_concepts
    # Assert: Returns array of concept IDs
}
```

---

#### Task 4.2: Unit Tests - Prerequisite Checking (40 min)

**Test Suite 2: Prerequisite Checking (10 tests)**

```zsh
# Test 11: Check prerequisites all satisfied
test_check_prerequisites_satisfied() {
    # Setup: Graph with 3 concepts, all prereqs satisfied
    # Execute: _check_prerequisites
    # Assert: Returns empty violations array
}

# Test 12: Detect missing prerequisite
test_detect_missing_prerequisite() {
    # Setup: Concept requires "matrix-algebra" which doesn't exist
    # Execute: _check_prerequisites
    # Assert: Returns violation with type "missing"
}

# Test 13: Detect future-week prerequisite
test_detect_future_prerequisite() {
    # Setup: Week 5 requires concept from Week 7
    # Execute: _check_prerequisites
    # Assert: Returns violation with type "future"
}

# Test 14: Find missing prerequisites
test_find_missing_prerequisites() {
    # Setup: Concept requires 2 prereqs, 1 missing
    # Execute: _find_missing_prerequisites
    # Assert: Returns array with 1 missing prereq ID
}

# Test 15: Find future prerequisites
test_find_future_prerequisites() {
    # Setup: Week 3 requires prereq from Week 5
    # Execute: _find_future_prerequisites
    # Assert: Returns array with future prereq ID
}

# Test 16: Format prerequisite violation (missing)
test_format_violation_missing() {
    # Execute: _format_prerequisite_violation "missing"
    # Assert: Returns formatted error with suggestion
}

# Test 17: Format prerequisite violation (future)
test_format_violation_future() {
    # Execute: _format_prerequisite_violation "future"
    # Assert: Returns formatted warning with suggestion
}

# Test 18: Check concept with no prerequisites
test_check_concept_no_prerequisites() {
    # Setup: Concept with empty requires array
    # Execute: _check_concept_prerequisites
    # Assert: No violations
}

# Test 19: Check multiple prerequisites
test_check_multiple_prerequisites() {
    # Setup: Concept with 3 prerequisites, all satisfied
    # Execute: _check_concept_prerequisites
    # Assert: No violations
}

# Test 20: Get dependency chain
test_get_dependency_chain() {
    # Setup: Concept A → B → C
    # Execute: _get_dependency_chain "A"
    # Assert: Returns [C, B, A] in order
}
```

---

#### Task 4.3: Integration Tests (20 min)

**File:** `tests/test-teach-analyze-phase0-integration.zsh`

**Test Suite 3: Full Workflow (5 tests)**

```zsh
# Test 21: Full workflow - clean course
test_full_workflow_clean() {
    # Setup: Create 3 lectures with proper prerequisites
    # Execute: teach analyze lectures/week-03.qmd
    # Assert: Exit code 0, "READY TO DEPLOY" message
}

# Test 22: Full workflow - missing prerequisite
test_full_workflow_missing_prereq() {
    # Setup: Week 5 requires non-existent prereq
    # Execute: teach analyze lectures/week-05.qmd
    # Assert: Exit code 1, ERROR message shown
}

# Test 23: Full workflow - future prerequisite
test_full_workflow_future_prereq() {
    # Setup: Week 3 requires concept from Week 5
    # Execute: teach analyze lectures/week-03.qmd
    # Assert: Exit code 1, WARNING message shown
}

# Test 24: Help text displays correctly
test_help_text() {
    # Execute: teach analyze --help
    # Assert: Help text contains usage, examples, frontmatter example
}

# Test 25: Invalid file argument
test_invalid_file() {
    # Execute: teach analyze non-existent.qmd
    # Assert: Error message, exit code 1
}
```

---

## 📂 File Structure (After Phase 0)

**New Files:**

```
lib/
  concept-extraction.zsh           # 250 lines
  prerequisite-checker.zsh         # 200 lines

commands/
  teach-analyze.zsh                # 150 lines

tests/
  test-teach-analyze-phase0-unit.zsh         # 500 lines (20 tests)
  test-teach-analyze-phase0-integration.zsh  # 100 lines (5 tests)

.teach/
  concepts.json                    # Generated at runtime
```

**Modified Files:**

```
flow.plugin.zsh                    # +10 lines (source statements)
lib/dispatchers/teach-dispatcher.zsh  # +100 lines (routing + help)
```

**Total:**

- Production code: ~750 lines
- Tests: ~600 lines
- **Total: ~1,350 lines**

---

## 📋 Implementation Checklist

### Prerequisites

- [ ] On `dev` branch
- [ ] All existing tests passing
- [ ] `yq` available (check with `teach doctor`)

### Wave 1: Core Library (2 hours)

- [ ] Create `lib/concept-extraction.zsh`
- [ ] Implement `_extract_concepts_from_frontmatter()`
- [ ] Implement `_parse_introduced_concepts()`
- [ ] Implement `_parse_required_concepts()`
- [ ] Implement `_build_concept_graph()`
- [ ] Implement `_load_concept_graph()`
- [ ] Implement `_save_concept_graph()`
- [ ] Implement `_get_week_from_file()`
- [ ] Create `lib/prerequisite-checker.zsh`
- [ ] Implement `_check_prerequisites()`
- [ ] Implement `_find_missing_prerequisites()`
- [ ] Implement `_find_future_prerequisites()`
- [ ] Implement `_format_prerequisite_violation()`

### Wave 2: Command Implementation (1 hour)

- [ ] Create `commands/teach-analyze.zsh`
- [ ] Implement `_teach_analyze()` main function
- [ ] Implement `_display_analysis_results()`
- [ ] Implement `_display_concepts_section()`
- [ ] Implement `_display_prerequisites_section()`
- [ ] Implement `_display_violations_section()`
- [ ] Implement `_display_summary_section()`
- [ ] Test command manually

### Wave 3: Integration (30 min)

- [ ] Update `flow.plugin.zsh` (source new libraries)
- [ ] Update `teach-dispatcher.zsh` (add routing)
- [ ] Add `_teach_analyze_help()` function
- [ ] Update main teach help output
- [ ] Test help text: `teach analyze --help`
- [ ] Test routing: `teach analyze lectures/week-05.qmd`

### Wave 4: Testing (1.5 hours)

- [ ] Create `tests/test-teach-analyze-phase0-unit.zsh`
- [ ] Write 10 concept extraction tests
- [ ] Write 10 prerequisite checking tests
- [ ] Run unit tests: `./tests/test-teach-analyze-phase0-unit.zsh`
- [ ] Create `tests/test-teach-analyze-phase0-integration.zsh`
- [ ] Write 5 full workflow tests
- [ ] Run integration tests
- [ ] Run full test suite: `./tests/run-all.sh`
- [ ] Fix any failing tests

### Final Verification

- [ ] Manual testing with real course content
- [ ] Test with missing concepts field
- [ ] Test with malformed YAML
- [ ] Test with missing prerequisites
- [ ] Test with future prerequisites
- [ ] Verify error messages are helpful
- [ ] Verify performance < 2s for single lecture
- [ ] All 25 tests passing

---

## 🧪 Testing Commands

```bash
# Load plugin
source flow.plugin.zsh

# Test help text
teach analyze --help
teach --help | grep analyze

# Test with sample files
# Create test lecture:
cat > lectures/test.qmd <<'EOF'
---
title: "Test Lecture"
week: 5
concepts:
  introduces:
    - id: test-concept
  requires:
    - prerequisite-concept
---
EOF

# Run analysis
teach analyze lectures/test.qmd

# Run unit tests
./tests/test-teach-analyze-phase0-unit.zsh

# Run integration tests
./tests/test-teach-analyze-phase0-integration.zsh

# Run all tests
./tests/run-all.sh
```

---

## 🚀 Next Steps After Phase 0

**Option A: Ship Phase 0 Standalone**

- Create PR to dev
- Document in CHANGELOG
- Release as v5.15.0-beta
- Gather user feedback
- Decide: Continue to Phase 1 or iterate on Phase 0?

**Option B: Continue to Phase 1**

- Implement caching (content-hash based)
- Add `--all` and `--week N` flags
- Add JSON output format
- Add teach status integration
- Estimated: +6-8 hours

**Option C: Pause and Work on Comprehensive Help**

- Switch to `feature/comprehensive-help` worktree
- Implement comprehensive help system (3-4 hours)
- Ship help improvements first
- Return to Phase 1 later

---

## 📊 Estimated Timeline

| Wave      | Tasks                                                     | Duration    |
| --------- | --------------------------------------------------------- | ----------- |
| Wave 1    | Core library (concept extraction + prerequisite checking) | 2 hours     |
| Wave 2    | Command implementation (teach analyze)                    | 1 hour      |
| Wave 3    | Integration (flow.plugin.zsh + dispatcher)                | 30 min      |
| Wave 4    | Testing (20 unit + 5 integration tests)                   | 1.5 hours   |
| **Total** | **All waves**                                             | **5 hours** |

**Buffer:** Allow 5-6 hours total (includes debugging, iterations)

---

## 📝 Implementation Notes

### Using FLOW_COLORS

All output should use FLOW_COLORS for consistency:

```zsh
${FLOW_COLORS[success]}  # Green
${FLOW_COLORS[warning]}  # Yellow
${FLOW_COLORS[error]}    # Red
${FLOW_COLORS[info]}     # Blue
${FLOW_COLORS[muted]}    # Gray
${FLOW_COLORS[bold]}     # Bold
${FLOW_COLORS[dim]}      # Dim
${FLOW_COLORS[cmd]}      # Command highlight
${FLOW_COLORS[header]}   # Box header
${FLOW_COLORS[reset]}    # Reset
```

### Error Handling Pattern

```zsh
if ! command; then
    _flow_log_error "Error message with context"
    return 1
fi
```

### File Operations

```zsh
# Atomic writes
echo "$content" > "${file}.tmp"
mv "${file}.tmp" "$file"

# Create directories safely
mkdir -p ".teach"

# Check file existence
[[ -f "$file" ]] || { echo "Not found"; return 1; }
```

### JSON Parsing

```zsh
# Extract field with jq
local value=$(echo "$json" | jq -r '.field.subfield')

# Check array length
local count=$(echo "$json" | jq 'length')

# Iterate array
echo "$json" | jq -c '.[]' | while read -r item; do
    # Process $item
done
```

---

## 🎯 Success Metrics (Phase 0)

**Functional:**

- ✅ `teach analyze` command works
- ✅ Extracts concepts from frontmatter
- ✅ Detects missing prerequisites
- ✅ Detects future-week prerequisites
- ✅ Displays helpful error messages

**Performance:**

- ✅ < 2s analysis time for single lecture
- ✅ < 5s for full course (15 lectures)

**Quality:**

- ✅ 25/25 tests passing
- ✅ Zero regressions in existing tests
- ✅ Help text comprehensive

**User Experience:**

- ✅ Clear output with suggestions
- ✅ ADHD-friendly colors and layout
- ✅ No cryptic error messages
- ✅ Obvious next steps

---

**Ready to Implement:** ✅

**Next Action:** Create feature branch and start Wave 1.
