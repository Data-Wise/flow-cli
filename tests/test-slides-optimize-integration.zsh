#!/usr/bin/env zsh

# =============================================================================
# test-slides-optimize-integration.zsh
# Integration tests for teach slides --optimize pipeline
# Tests: auto-analyze, --key-concepts, --apply-suggestions, course_dir resolution
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

# Provide stubs for dispatcher functions needed by _teach_slides_optimized
_teach_error() { echo "Error: $1" >&2; [[ -n "$2" ]] && echo "  $2" >&2; }
_teach_warn() { echo "Warning: $1" >&2; }

# Stub for _teach_convert_lecture_to_slides (generates a minimal slide file)
_teach_convert_lecture_to_slides() {
    local input="$1" output="$2"
    [[ -f "$input" ]] || return 1
    mkdir -p "${output:h}"
    echo "---" > "$output"
    echo "format: revealjs" >> "$output"
    echo "---" >> "$output"
    echo "" >> "$output"
    echo "## Slide 1" >> "$output"
    echo "Content from ${input:t}" >> "$output"
    return 0
}

# Source the dispatcher function (extract just _teach_slides_optimized)
source "$FLOW_PLUGIN_DIR/lib/dispatchers/teach-dispatcher.zsh" 2>/dev/null

# Create test course
mkdir -p "$TEST_DIR/course/lectures"

cat > "$TEST_DIR/course/lesson-plan.yml" << 'EOF'
course:
  name: "Slides Integration Test"
  code: "TEST-200"
weeks:
  - number: 1
    topic: "Foundations"
  - number: 5
    topic: "Regression"
EOF

cat > "$TEST_DIR/course/lectures/week-01-foundations.qmd" << 'EOF'
---
title: "Foundations"
week: 1
concepts:
  introduces:
    - basic-stats
    - probability
---

## Statistics Basics

**Definition**: Statistics is the science of collecting and analyzing data.

Basic statistics includes measures of central tendency.
EOF

cat > "$TEST_DIR/course/lectures/week-05-regression.qmd" << 'EOF'
---
title: "Regression Analysis"
week: 5
concepts:
  introduces:
    - simple-regression
    - residuals
    - r-squared
  requires:
    - basic-stats
    - probability
---

## Introduction to Regression

Linear regression is one of the most widely used statistical methods for understanding
relationships between variables. It provides a framework for both prediction and
inference. The mathematical foundations rest on the method of least squares, which
minimizes the sum of squared residuals between observed and predicted values.
Understanding these foundations is crucial for proper interpretation of results.
The slope coefficient tells us the expected change in Y for a one-unit increase in X.
Statistical significance is assessed through t-tests on individual coefficients.
R-squared measures the proportion of variance explained by the model.
We also consider adjusted R-squared and other goodness-of-fit measures.
Additional considerations include multicollinearity and heteroscedasticity.

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

**Definition**: A residual is the difference between the observed and predicted value.

```{r}
# Residual analysis
residuals(model)
plot(residuals(model))
```
EOF

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  SLIDES OPTIMIZE INTEGRATION TESTS                      ║"
echo "╚══════════════════════════════════════════════════════════╝"

# =============================================================================
# SUITE 1: Auto-Analyze (No Concept Graph)
# =============================================================================
_test_start "Auto-Analyze (No Concept Graph)"

cd "$TEST_DIR/course"

# Ensure no concept graph exists
_assert "No concepts.json initially" '[[ ! -f ".teach/concepts.json" && ! -f "lectures/.teach/concepts.json" ]]'

# Run _teach_slides_optimized which should auto-analyze
out=$(_teach_slides_optimized "lectures/week-05-regression.qmd" "" "false" "false" "false" 2>&1)
out_exit=$?
_assert_equals "Slides optimized succeeds" "0" "$out_exit"
_assert_contains "Shows optimizing header" "$out" "Optimizing"

# After auto-analyze, concept graph should exist
_assert "Concept graph created by auto-analyze" '[[ -f "lectures/.teach/concepts.json" || -f ".teach/concepts.json" ]]'

# =============================================================================
# SUITE 2: --key-concepts Display Only
# =============================================================================
_test_start "--key-concepts Display Only"

cd "$TEST_DIR/course"

# Run with key_concepts=true, apply=false
kc_out=$(_teach_slides_optimized "lectures/week-05-regression.qmd" "" "false" "false" "true" 2>&1)
kc_exit=$?
_assert_equals "Key concepts mode succeeds" "0" "$kc_exit"
_assert_contains "Shows Key Concepts header" "$kc_out" "Key Concepts for Callout Boxes"

# Should NOT generate slides
_assert_not_contains "No slides generated in key-concepts mode" "$kc_out" "Generated"

# Should show concept count
_assert_contains "Shows concept count" "$kc_out" "concept(s) identified"

# Should show timing estimate (file is long enough)
_assert_contains "Shows timing estimate" "$kc_out" "Estimated presentation time"

# Should show next steps
_assert_contains "Shows next steps" "$kc_out" "To generate slides"

# =============================================================================
# SUITE 3: --key-concepts with --apply-suggestions
# =============================================================================
_test_start "--key-concepts + --apply-suggestions"

cd "$TEST_DIR/course"
rm -rf slides/  # Clean slate

# Run with both key_concepts=true and apply=true
ka_out=$(_teach_slides_optimized "lectures/week-05-regression.qmd" "" "false" "true" "true" 2>&1)
ka_exit=$?
_assert_equals "Key concepts + apply succeeds" "0" "$ka_exit"

# Should generate slides AND show concepts
_assert_contains "Generates optimized slides" "$ka_out" "Generated (optimized)"
_assert_contains "Shows callout concepts inline" "$ka_out" "Callout concepts"

# Output file should exist
_assert "Slides file created" '[[ -f "slides/week-05-regression_slides.qmd" ]]'

# =============================================================================
# SUITE 4: --preview-breaks (existing behavior)
# =============================================================================
_test_start "--preview-breaks Mode"

cd "$TEST_DIR/course"

# Run with preview=true
prev_out=$(_teach_slides_optimized "lectures/week-05-regression.qmd" "" "true" "false" "false" 2>&1)
prev_exit=$?
_assert_equals "Preview mode succeeds" "0" "$prev_exit"

# Should show break suggestions but not generate
_assert_not_contains "No slides generated in preview" "$prev_out" "Generated"

# =============================================================================
# SUITE 5: Course Dir Resolution
# =============================================================================
_test_start "Course Dir Resolution"

cd "$TEST_DIR/course"

# Relative path: lectures/week-05.qmd → course_dir should resolve correctly
_assert "Course dir resolves for relative path" '[[ -d "lectures" ]]'

# Test with absolute path
abs_out=$(_teach_slides_optimized "$TEST_DIR/course/lectures/week-05-regression.qmd" "" "false" "false" "false" 2>&1)
_assert_equals "Absolute path succeeds" "0" "$?"
_assert_contains "Absolute path shows optimizing" "$abs_out" "Optimizing"

# =============================================================================
# SUITE 6: Cache Behavior
# =============================================================================
_test_start "Optimization Cache"

cd "$TEST_DIR/course"

# Ensure .teach dir exists (course_dir resolves to "." for relative paths)
mkdir -p ".teach"

# Run optimization
_teach_slides_optimized "lectures/week-05-regression.qmd" "" "false" "false" "false" >/dev/null 2>&1

# Check cache file exists (course_dir resolves to "." for relative paths)
_assert "Cache file created" '[[ -f ".teach/slide-optimization-week-05-regression.json" ]]'

# Cache should contain valid JSON
if command -v jq &>/dev/null; then
    local cache_valid
    cache_valid=$(jq '.' ".teach/slide-optimization-week-05-regression.json" 2>/dev/null && echo "valid" || echo "invalid")
    _assert_contains "Cache contains valid JSON" "$cache_valid" "valid"

    # Cache should have slide_breaks array
    local has_breaks
    has_breaks=$(jq 'has("slide_breaks")' ".teach/slide-optimization-week-05-regression.json" 2>/dev/null)
    _assert_equals "Cache has slide_breaks" "true" "$has_breaks"
fi

# =============================================================================
# SUITE 7: No Optimization Needed (Short File)
# =============================================================================
_test_start "No Optimization (Short File)"

cd "$TEST_DIR/course"

# Week 1 is too short for any optimization suggestions (0 breaks found)
short_out=$(_teach_slides_optimized "lectures/week-01-foundations.qmd" "" "false" "false" "false" 2>&1)
_assert_contains "Short file shows 0 suggestions" "$short_out" "0 optimization suggestions"

# =============================================================================
# SUITE 8: Missing File Handling
# =============================================================================
_test_start "Error Handling"

cd "$TEST_DIR/course"

# Non-existent file
missing_out=$(_teach_slides_optimized "lectures/nonexistent.qmd" "" "false" "false" "false" 2>&1)
missing_exit=$?
_assert_equals "Missing file returns error" "1" "$missing_exit"

# No args at all
no_args_out=$(_teach_slides_optimized "" "" "false" "false" "false" 2>&1)
no_args_exit=$?
_assert_equals "No args returns error" "1" "$no_args_exit"
_assert_contains "Shows error message" "$no_args_out" "No lecture files found"

# =============================================================================
# SUITE 9: Summary Output
# =============================================================================
_test_start "Summary Output"

cd "$TEST_DIR/course"
rm -rf slides/  # Clean slate

# Generate slides normally (no --apply)
gen_out=$(_teach_slides_optimized "lectures/week-05-regression.qmd" "" "false" "false" "false" 2>&1)
_assert_contains "Shows optimization suggestions count" "$gen_out" "optimization suggestions available"
_assert_contains "Shows summary header" "$gen_out" "Generated"

# Apply mode shows different summary
rm -rf slides/
apply_out=$(_teach_slides_optimized "lectures/week-05-regression.qmd" "" "false" "true" "false" 2>&1)
_assert_contains "Apply mode shows optimized" "$apply_out" "Generated (optimized)"

# =============================================================================
# RESULTS
# =============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  RESULTS: $pass_count/$test_count passed ($fail_count failures)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit $fail_count
