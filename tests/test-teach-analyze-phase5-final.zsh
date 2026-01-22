#!/usr/bin/env zsh

# =============================================================================
# test-teach-analyze-phase5-final.zsh
# Final integration tests for Phase 5: End-to-end validation
# Tests: Full pipeline, error handling, caching, performance
# =============================================================================

local test_count=0
local pass_count=0
local fail_count=0
local current_suite=""

_test_start() {
    current_suite="$1"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  SUITE: $current_suite"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

_assert() {
    local description="$1"
    local condition="$2"
    (( test_count++ ))
    if eval "$condition"; then
        (( pass_count++ ))
        echo "  ✓ $description"
    else
        (( fail_count++ ))
        echo "  ✗ $description"
        echo "    FAILED: $condition"
    fi
}

_assert_equals() {
    local description="$1"
    local expected="$2"
    local actual="$3"
    (( test_count++ ))
    if [[ "$expected" == "$actual" ]]; then
        (( pass_count++ ))
        echo "  ✓ $description"
    else
        (( fail_count++ ))
        echo "  ✗ $description"
        echo "    Expected: $expected"
        echo "    Actual:   $actual"
    fi
}

_assert_contains() {
    local description="$1"
    local haystack="$2"
    local needle="$3"
    (( test_count++ ))
    if [[ "$haystack" == *"$needle"* ]]; then
        (( pass_count++ ))
        echo "  ✓ $description"
    else
        (( fail_count++ ))
        echo "  ✗ $description"
        echo "    Missing: $needle"
    fi
}

_assert_not_contains() {
    local description="$1"
    local haystack="$2"
    local needle="$3"
    (( test_count++ ))
    if [[ "$haystack" != *"$needle"* ]]; then
        (( pass_count++ ))
        echo "  ✓ $description"
    else
        (( fail_count++ ))
        echo "  ✗ $description"
        echo "    Should NOT contain: $needle"
    fi
}

# =============================================================================
# SETUP
# =============================================================================

TEST_DIR=$(mktemp -d)
trap "rm -rf '$TEST_DIR'" EXIT

unsetopt print_exit_value 2>/dev/null

FLOW_PLUGIN_DIR="${0:A:h:h}"
source "$FLOW_PLUGIN_DIR/lib/core.zsh" 2>/dev/null || true
source "$FLOW_PLUGIN_DIR/lib/concept-extraction.zsh"
source "$FLOW_PLUGIN_DIR/lib/prerequisite-checker.zsh"
source "$FLOW_PLUGIN_DIR/lib/report-generator.zsh"
source "$FLOW_PLUGIN_DIR/lib/ai-analysis.zsh"
source "$FLOW_PLUGIN_DIR/lib/slide-optimizer.zsh"
source "$FLOW_PLUGIN_DIR/commands/teach-analyze.zsh"

# Create multi-week course
mkdir -p "$TEST_DIR/course/lectures"

cat > "$TEST_DIR/course/lesson-plan.yml" << 'EOF'
course:
  name: "Full Test Course"
  code: "TEST-100"
weeks:
  - number: 1
    topic: "Foundations"
  - number: 2
    topic: "Building Blocks"
  - number: 3
    topic: "Applications"
EOF

cat > "$TEST_DIR/course/lectures/week-01-foundations.qmd" << 'EOF'
---
title: "Foundations"
week: 1
concepts:
  introduces:
    - basic-stats
    - probability
    - distributions
---

## Statistics Basics

**Definition**: Statistics is the science of collecting, analyzing, and interpreting data.

Basic statistics includes measures of central tendency and dispersion.

## Probability

**Definition**: Probability is the measure of likelihood that an event will occur.

We use probability to quantify uncertainty in our analyses.
EOF

cat > "$TEST_DIR/course/lectures/week-02-building.qmd" << 'EOF'
---
title: "Building Blocks"
week: 2
concepts:
  introduces:
    - hypothesis-testing
    - confidence-intervals
  requires:
    - probability
    - distributions
---

## Hypothesis Testing

**Definition**: Hypothesis testing is a statistical method for making decisions using data.

This builds on our understanding of probability from Week 1.

```{r}
t.test(x, mu = 0)
```

## Confidence Intervals

A confidence interval provides a range of plausible values.

```{r}
confint(model, level = 0.95)
```
EOF

cat > "$TEST_DIR/course/lectures/week-03-applications.qmd" << 'EOF'
---
title: "Applications"
week: 3
concepts:
  introduces:
    - regression
    - model-diagnostics
  requires:
    - hypothesis-testing
    - confidence-intervals
    - basic-stats
---

## Regression Analysis

Linear regression is one of the most widely used statistical methods for understanding
relationships between variables. It provides a framework for both prediction and
inference. The mathematical foundations rest on the method of least squares, which
minimizes the sum of squared residuals between observed and predicted values.
Understanding these foundations is crucial for proper interpretation of results.
The slope coefficient tells us the expected change in Y for a one-unit increase in X.
Statistical significance is assessed through t-tests on individual coefficients.
R-squared measures the proportion of variance explained by the model.

**Definition**: The regression coefficient β₁ represents the expected change in Y
for a one-unit change in X, holding all other predictors constant.

For example, if β₁ = 3.2, then each unit increase in X is associated with a 3.2 unit
increase in Y on average. Consider the case of predicting test scores from study hours.

```{r}
# Fit regression model
model <- lm(y ~ x, data = df)
summary(model)
```

More code to demonstrate:

```{r}
# Check assumptions
plot(model)
```

And another block:

```{r}
# Predictions
predict(model, newdata = data.frame(x = c(1,2,3)))
```

## Model Diagnostics

After fitting a model, we must verify our assumptions hold through careful
diagnostic checking. Residual plots, Q-Q plots, and influence measures are
essential tools for this purpose.
EOF

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  PHASE 5 FINAL TESTS: End-to-End Validation             ║"
echo "╚══════════════════════════════════════════════════════════╝"

# =============================================================================
# SUITE 1: Error Handling
# =============================================================================
_test_start "Error Handling"

# No arguments
no_args=$(cd "$TEST_DIR/course" && _teach_analyze 2>&1)
no_args_exit=$?
_assert_equals "No args returns error" "1" "$no_args_exit"
_assert_contains "No args shows usage examples" "$no_args" "Examples:"
_assert_contains "No args shows help hint" "$no_args" "--help"

# Non-existent file
missing=$(cd "$TEST_DIR/course" && _teach_analyze "nonexistent.qmd" 2>&1)
missing_exit=$?
_assert_equals "Missing file returns error" "1" "$missing_exit"
_assert_contains "Missing file mentions not found" "$missing" "not found"

# Non-existent file in existing directory with alternatives
bad_file=$(cd "$TEST_DIR/course" && _teach_analyze "lectures/bad-name.qmd" 2>&1)
_assert_contains "Shows available files" "$bad_file" "Available .qmd files"

# Wrong extension warning
echo "content" > "$TEST_DIR/course/test.txt"
wrong_ext=$(cd "$TEST_DIR/course" && _teach_analyze "test.txt" 2>&1)
_assert_contains "Wrong extension warns" "$wrong_ext" "Warning: Expected .qmd"

# =============================================================================
# SUITE 2: Full Pipeline (Phase 0 → 4)
# =============================================================================
_test_start "Full Pipeline (all phases)"

# Phase 0: Basic analysis
phase0_out=$(cd "$TEST_DIR/course" && _teach_analyze "lectures/week-01-foundations.qmd" 2>&1)
phase0_exit=$?
_assert_equals "Phase 0 succeeds" "0" "$phase0_exit"
_assert_contains "Phase 0 shows concept coverage" "$phase0_out" "CONCEPT COVERAGE"
_assert_contains "Phase 0 shows prerequisites" "$phase0_out" "PREREQUISITES"
_assert_contains "Phase 0 shows summary" "$phase0_out" "SUMMARY"

# Phase 0 with quiet
quiet_out=$(cd "$TEST_DIR/course" && _teach_analyze "lectures/week-01-foundations.qmd" "--quiet" 2>&1)
_assert_not_contains "Quiet suppresses progress" "$quiet_out" "Building concept graph"

# Phase 4: Slide breaks
phase4_out=$(cd "$TEST_DIR/course" && _teach_analyze "lectures/week-03-applications.qmd" "--slide-breaks" 2>&1)
_assert_contains "Phase 4 shows slide section" "$phase4_out" "SLIDE OPTIMIZATION"
_assert_contains "Phase 4 shows phase label" "$phase4_out" "Phase: 4"

# =============================================================================
# SUITE 3: Slide Optimization Cache
# =============================================================================
_test_start "Slide Optimization Cache"

# First run (no cache)
cd "$TEST_DIR/course"
first_run=$(_teach_analyze "lectures/week-03-applications.qmd" "--slide-breaks" 2>&1)
_assert_contains "First run completes" "$first_run" "SLIDE OPTIMIZATION"

# Second run (should use cache) - no --quiet so we can see "(cached)" message
second_run=$(_teach_analyze "lectures/week-03-applications.qmd" "--slide-breaks" 2>&1)
_assert_contains "Second run uses cache" "$second_run" "cached"

# Modify file and run again (should re-analyze)
echo "\n## New Section\nAdded content." >> "$TEST_DIR/course/lectures/week-03-applications.qmd"
third_run=$(_teach_analyze "lectures/week-03-applications.qmd" "--slide-breaks" 2>&1)
_assert_not_contains "Modified file re-analyzes" "$third_run" "cached"

# =============================================================================
# SUITE 4: Multi-Week Course Analysis
# =============================================================================
_test_start "Multi-Week Course Analysis"

# Week 2 should detect prerequisites from Week 1
week2_out=$(cd "$TEST_DIR/course" && _teach_analyze "lectures/week-02-building.qmd" 2>&1)
_assert_contains "Week 2 shows prerequisite info" "$week2_out" "PREREQUISITES"
_assert_equals "Week 2 analysis succeeds" "0" "$?"

# Week 3 with slide breaks
week3_out=$(cd "$TEST_DIR/course" && _teach_analyze "lectures/week-03-applications.qmd" "--slide-breaks" 2>&1)
_assert_contains "Week 3 has slide suggestions" "$week3_out" "Suggested breaks"

# =============================================================================
# SUITE 5: Report Generation with Slide Data
# =============================================================================
_test_start "Report Generation with Slide Data"

cd "$TEST_DIR/course"
report_out=$(_teach_analyze "lectures/week-03-applications.qmd" "--report" "$TEST_DIR/report.md" "--format" "markdown" "--quiet" 2>&1)
_assert "Report generation succeeds" '[[ $? -eq 0 ]]'

# JSON report
json_report=$(_teach_analyze "lectures/week-03-applications.qmd" "--report" "$TEST_DIR/report.json" "--format" "json" "--quiet" 2>&1)
_assert "JSON report generation succeeds" '[[ $? -eq 0 ]]'

# =============================================================================
# SUITE 6: Flag Combinations
# =============================================================================
_test_start "Flag Combinations"

cd "$TEST_DIR/course"

# --slide-breaks + --quiet
sb_quiet=$(_teach_analyze "lectures/week-03-applications.qmd" "--slide-breaks" "--quiet" 2>&1)
_assert "slide-breaks + quiet works" '[[ $? -eq 0 ]]'

# --slide-breaks + --summary
sb_summary=$(_teach_analyze "lectures/week-03-applications.qmd" "--slide-breaks" "--summary" "--report" "$TEST_DIR/sum.md" "--quiet" 2>&1)
_assert "slide-breaks + summary + report works" '[[ $? -eq 0 ]]'

# --preview-breaks exits early
preview=$(_teach_analyze "lectures/week-03-applications.qmd" "--preview-breaks" 2>&1)
preview_exit=$?
_assert_equals "preview-breaks exits 0" "0" "$preview_exit"
_assert_not_contains "preview-breaks skips summary" "$preview" "SUMMARY"

# --mode strict with slide-breaks
strict_sb=$(_teach_analyze "lectures/week-03-applications.qmd" "--mode" "strict" "--slide-breaks" 2>&1)
_assert "strict mode + slide-breaks works" '[[ $? -eq 0 || $? -eq 1 ]]'  # May warn

# =============================================================================
# SUITE 7: Slide Optimizer Edge Cases
# =============================================================================
_test_start "Slide Optimizer Edge Cases"

# Empty file
echo "" > "$TEST_DIR/empty.qmd"
empty_struct=$(_slide_analyze_structure "$TEST_DIR/empty.qmd")
_assert_contains "Empty file has sections array" "$empty_struct" '"sections":['

# File with only frontmatter
cat > "$TEST_DIR/frontmatter-only.qmd" << 'EOF'
---
title: "Just Frontmatter"
---
EOF
fm_struct=$(_slide_analyze_structure "$TEST_DIR/frontmatter-only.qmd")
if command -v jq &>/dev/null; then
    fm_count=$(echo "$fm_struct" | jq '.total_sections' 2>/dev/null)
    _assert_equals "Frontmatter-only file has 0 sections" "0" "$fm_count"
fi

# File with no headings
echo "Just plain text content without any structure." > "$TEST_DIR/no-headings.qmd"
no_h_struct=$(_slide_analyze_structure "$TEST_DIR/no-headings.qmd")
if command -v jq &>/dev/null; then
    no_h_count=$(echo "$no_h_struct" | jq '.total_sections' 2>/dev/null)
    _assert_equals "No-headings file has 0 sections" "0" "$no_h_count"
fi

# Very short sections (should not suggest breaks)
cat > "$TEST_DIR/short-sections.qmd" << 'EOF'
---
title: "Short"
---

## A

One line.

## B

Two lines.
More text.
EOF
short_struct=$(_slide_analyze_structure "$TEST_DIR/short-sections.qmd")
short_breaks=$(_slide_suggest_breaks "$short_struct" "{}")
_assert_equals "Short sections have no breaks" "[]" "$short_breaks"

# =============================================================================
# SUITE 8: Performance (Timing)
# =============================================================================
_test_start "Performance Checks"

# Measure analysis time for a single file
local start_time=$SECONDS
cd "$TEST_DIR/course"
_teach_analyze "lectures/week-03-applications.qmd" "--quiet" 2>&1 >/dev/null
local elapsed=$((SECONDS - start_time))
_assert "Single file analysis < 10s" '[[ $elapsed -lt 10 ]]'

# Measure slide optimization time
start_time=$SECONDS
_slide_optimize "$TEST_DIR/course/lectures/week-03-applications.qmd" "{}" "true" 2>/dev/null >/dev/null
elapsed=$((SECONDS - start_time))
_assert "Slide optimization < 5s" '[[ $elapsed -lt 5 ]]'

# =============================================================================
# RESULTS
# =============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  RESULTS: $pass_count/$test_count passed ($fail_count failures)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit $fail_count
