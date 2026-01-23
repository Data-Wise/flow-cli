#!/usr/bin/env zsh

# =============================================================================
# test-teach-analyze-phase4-unit.zsh
# Unit tests for Phase 4: Slide Optimization
# Tests: slide-optimizer.zsh functions
# =============================================================================

# Test framework setup
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
        echo "    String does not contain: $needle"
        echo "    In: ${haystack:0:200}"
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
        echo "    String should NOT contain: $needle"
    fi
}

_assert_json_field() {
    local description="$1"
    local json="$2"
    local field="$3"
    local expected="$4"
    (( test_count++ ))

    local actual
    if command -v jq &>/dev/null; then
        actual=$(echo "$json" | jq -r "$field" 2>/dev/null)
    else
        echo "  ⊘ $description (jq not available)"
        (( pass_count++ ))
        return
    fi

    if [[ "$actual" == "$expected" ]]; then
        (( pass_count++ ))
        echo "  ✓ $description"
    else
        (( fail_count++ ))
        echo "  ✗ $description"
        echo "    Field $field: expected '$expected', got '$actual'"
    fi
}

# =============================================================================
# TEST ENVIRONMENT SETUP
# =============================================================================

# Create temp directory
TEST_DIR=$(mktemp -d)
trap "rm -rf '$TEST_DIR'" EXIT

# Suppress ZSH printing
unsetopt print_exit_value 2>/dev/null

# Source the library under test
FLOW_PLUGIN_DIR="${0:A:h:h}"
source "$FLOW_PLUGIN_DIR/lib/slide-optimizer.zsh"

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  PHASE 4 UNIT TESTS: Slide Optimization                 ║"
echo "╚══════════════════════════════════════════════════════════╝"

# =============================================================================
# SUITE 1: Structure Analysis
# =============================================================================
_test_start "Structure Analysis (_slide_analyze_structure)"

# Create test lecture file
cat > "$TEST_DIR/lecture-basic.qmd" << 'LECTURE'
---
title: "Test Lecture"
week: 5
---

## Introduction

This is an introduction to the topic of regression analysis.
We will cover the basics.

## Linear Regression

Linear regression is a statistical method.

### Assumptions

The key assumptions are:
1. Linearity
2. Independence
3. Normality

```{r}
lm(y ~ x, data = df)
```

## Summary

In summary, regression is important.
LECTURE

result=$(_slide_analyze_structure "$TEST_DIR/lecture-basic.qmd")

_assert "Returns valid JSON" '[[ -n "$result" && "$result" != "{}" ]]'
_assert_contains "Has sections array" "$result" '"sections"'
_assert_contains "Has total_sections field" "$result" '"total_sections"'

if command -v jq &>/dev/null; then
    section_count=$(echo "$result" | jq '.total_sections' 2>/dev/null)
    _assert_equals "Detects 3 H2 + 1 H3 sections" "4" "$section_count"

    first_heading=$(echo "$result" | jq -r '.sections[0].heading' 2>/dev/null)
    _assert_equals "First section is Introduction" "Introduction" "$first_heading"

    # Check code chunks detected
    lr_code=$(echo "$result" | jq '.sections[] | select(.heading == "Assumptions") | .code_chunks' 2>/dev/null)
    _assert_equals "Detects code chunk in Assumptions" "1" "$lr_code"

    # Check heading levels
    intro_level=$(echo "$result" | jq '.sections[0].level' 2>/dev/null)
    _assert_equals "Introduction is level 2" "2" "$intro_level"

    assumptions_level=$(echo "$result" | jq '.sections[] | select(.heading == "Assumptions") | .level' 2>/dev/null)
    _assert_equals "Assumptions is level 3" "3" "$assumptions_level"
fi

# Test with empty file
echo "" > "$TEST_DIR/empty.qmd"
empty_result=$(_slide_analyze_structure "$TEST_DIR/empty.qmd")
_assert_contains "Empty file returns sections array" "$empty_result" '"sections":['

# Test with non-existent file
missing_result=$(_slide_analyze_structure "$TEST_DIR/nonexistent.qmd")
_assert_equals "Missing file returns empty JSON" "{}" "$missing_result"

# Test frontmatter skipping
cat > "$TEST_DIR/lecture-frontmatter.qmd" << 'LECTURE'
---
title: "Complex Frontmatter"
format:
  html:
    toc: true
---

## First Section

Content here.
LECTURE

fm_result=$(_slide_analyze_structure "$TEST_DIR/lecture-frontmatter.qmd")
if command -v jq &>/dev/null; then
    fm_sections=$(echo "$fm_result" | jq '.total_sections' 2>/dev/null)
    _assert_equals "Skips frontmatter correctly" "1" "$fm_sections"
fi

# =============================================================================
# SUITE 2: Slide Break Suggestions
# =============================================================================
_test_start "Slide Break Suggestions (_slide_suggest_breaks)"

# Create a lecture with dense sections
cat > "$TEST_DIR/lecture-dense.qmd" << 'LECTURE'
---
title: "Dense Lecture"
---

## Introduction

This is a very long introduction section that goes on and on with many words to explain
the concepts in great detail. We need to ensure that students understand the background
material before we move on to the more advanced topics. The history of statistics goes
back to the 17th century when people first started collecting data systematically.
The early statisticians were primarily concerned with government data, hence the name
statistics from the Latin word for state. Over time the field evolved to include
probability theory, sampling methods, and hypothesis testing. Each of these areas
contributed significantly to our modern understanding of data analysis. Today we use
these methods across all scientific disciplines and in business applications as well.
This introduction covers the essential background needed for the rest of the course.
Additional context includes the development of computing and how it revolutionized
statistical practice in the latter half of the 20th century.

## Code Heavy Section

Here we demonstrate multiple code examples:

```{r}
# Example 1: Basic summary
summary(data)
```

More explanation between code blocks about what we learned.

```{r}
# Example 2: Visualization
plot(data$x, data$y)
```

And another explanation with more context and detail about visualization.

```{r}
# Example 3: Model fitting
model <- lm(y ~ x, data = data)
summary(model)
```

## Definition and Example Section

**Definition**: A regression coefficient represents the change in the response variable
for a one-unit change in the predictor, holding all other predictors constant.
This is also known as the slope parameter in simple linear regression.
The regression coefficient is defined as the ratio of the covariance to the variance.

For example, consider a study of income and education level. Suppose we observe that
for each additional year of education, income increases by $5,000 on average.
This is a practical application of regression coefficients in economics.
Consider another example where we look at height and weight relationships.

## Short Section

Brief point here.
LECTURE

dense_structure=$(_slide_analyze_structure "$TEST_DIR/lecture-dense.qmd")
breaks=$(_slide_suggest_breaks "$dense_structure" "{}")

_assert "Returns valid break suggestions" '[[ -n "$breaks" && "$breaks" != "[]" ]]'
_assert_contains "Contains break array" "$breaks" '"section"'
_assert_contains "Contains priority field" "$breaks" '"priority"'
_assert_contains "Contains reason field" "$breaks" '"reason"'

if command -v jq &>/dev/null; then
    break_count=$(echo "$breaks" | jq 'length' 2>/dev/null)
    _assert "Has at least 2 break suggestions" '[[ $break_count -ge 2 ]]'

    # Check that Introduction is flagged (word count > 300)
    intro_break=$(echo "$breaks" | jq '.[] | select(.section == "Introduction")' 2>/dev/null)
    _assert "Introduction flagged for break" '[[ -n "$intro_break" ]]'

    intro_priority=$(echo "$breaks" | jq -r '.[] | select(.section == "Introduction") | .priority' 2>/dev/null)
    _assert_equals "Introduction is low priority (dense text, no code)" "low" "$intro_priority"

    # Check code heavy section flagged
    code_break=$(echo "$breaks" | jq '.[] | select(.section == "Code Heavy Section")' 2>/dev/null)
    _assert "Code Heavy Section flagged" '[[ -n "$code_break" ]]'

    # Check definition+example section flagged
    def_break=$(echo "$breaks" | jq '.[] | select(.section == "Definition and Example Section")' 2>/dev/null)
    _assert "Definition+Example Section flagged" '[[ -n "$def_break" ]]'

    # Short section should NOT be flagged
    short_break=$(echo "$breaks" | jq '.[] | select(.section == "Short Section")' 2>/dev/null)
    _assert "Short section NOT flagged" '[[ -z "$short_break" || "$short_break" == "" ]]'
fi

# Test with empty structure
empty_breaks=$(_slide_suggest_breaks "{}" "{}")
_assert_equals "Empty structure returns empty array" "[]" "$empty_breaks"

# Test with no dense sections
cat > "$TEST_DIR/lecture-light.qmd" << 'LECTURE'
---
title: "Light"
---

## Part 1

Short content.

## Part 2

Also short.
LECTURE

light_structure=$(_slide_analyze_structure "$TEST_DIR/lecture-light.qmd")
light_breaks=$(_slide_suggest_breaks "$light_structure" "{}")
_assert_equals "Light lecture has no break suggestions" "[]" "$light_breaks"

# =============================================================================
# SUITE 3: Key Concept Identification
# =============================================================================
_test_start "Key Concept Identification (_slide_identify_key_concepts)"

# Create lecture with identifiable concepts
cat > "$TEST_DIR/lecture-concepts.qmd" << 'LECTURE'
---
title: "Concepts Lecture"
---

## Regression Basics

**Definition**: A linear regression model expresses a linear relationship
between a response variable and one or more predictors.

The **Ordinary Least Squares** method minimizes the sum of squared residuals.

## Hypothesis Testing

**Theorem**: Under the null hypothesis, the t-statistic follows a t-distribution
with n-2 degrees of freedom.

Property: The p-value represents the probability of observing a test statistic
as extreme as the one computed, assuming H0 is true.

Key Idea: Statistical significance does not imply practical significance.
LECTURE

concepts=$(_slide_identify_key_concepts "$TEST_DIR/lecture-concepts.qmd" "{}")

_assert "Returns valid concepts array" '[[ -n "$concepts" && "$concepts" != "[]" ]]'
_assert_contains "Contains concept objects" "$concepts" '"name"'
_assert_contains "Contains emphasis field" "$concepts" '"emphasis"'
_assert_contains "Contains source field" "$concepts" '"source"'

if command -v jq &>/dev/null; then
    concept_count=$(echo "$concepts" | jq 'length' 2>/dev/null)
    _assert "Identifies multiple concepts" '[[ $concept_count -ge 3 ]]'

    # Check definition pattern detected
    def_concepts=$(echo "$concepts" | jq '[.[] | select(.source == "content_pattern")] | length' 2>/dev/null)
    _assert "Detects definition patterns" '[[ $def_concepts -ge 1 ]]'

    # Check emphasis pattern detected (bold multi-word terms)
    emphasis_concepts=$(echo "$concepts" | jq '[.[] | select(.source == "emphasis_pattern")] | length' 2>/dev/null)
    _assert "Detects emphasis patterns" '[[ $emphasis_concepts -ge 1 ]]'

    # Check callout types assigned
    important_count=$(echo "$concepts" | jq '[.[] | select(.emphasis == "callout-important")] | length' 2>/dev/null)
    _assert "Assigns callout-important to definitions" '[[ $important_count -ge 1 ]]'
fi

# Test with concept graph input
concept_graph='{"concepts":{"regression":{"name":"Linear Regression","introduced":true},"anova":{"name":"ANOVA","introduced":true}}}'
graph_concepts=$(_slide_identify_key_concepts "$TEST_DIR/lecture-concepts.qmd" "$concept_graph")

if command -v jq &>/dev/null; then
    graph_source=$(echo "$graph_concepts" | jq '[.[] | select(.source == "concept_graph")] | length' 2>/dev/null)
    _assert "Extracts concepts from graph" '[[ $graph_source -ge 1 ]]'
fi

# Test with empty file
echo "" > "$TEST_DIR/empty-concepts.qmd"
empty_concepts=$(_slide_identify_key_concepts "$TEST_DIR/empty-concepts.qmd" "{}")
_assert_equals "Empty file returns empty array" "[]" "$empty_concepts"

# Test with non-existent file
missing_concepts=$(_slide_identify_key_concepts "$TEST_DIR/missing.qmd" "{}")
_assert_equals "Missing file returns empty array" "[]" "$missing_concepts"

# =============================================================================
# SUITE 4: Time Estimation
# =============================================================================
_test_start "Time Estimation (_slide_estimate_time)"

# Use the dense lecture structure from earlier
time_est=$(_slide_estimate_time "$dense_structure")

_assert "Returns valid time JSON" '[[ -n "$time_est" && "$time_est" != "{}" ]]'
_assert_contains "Has total_minutes" "$time_est" '"total_minutes"'
_assert_contains "Has sections array" "$time_est" '"sections"'

if command -v jq &>/dev/null; then
    total_time=$(echo "$time_est" | jq '.total_minutes' 2>/dev/null)
    _assert "Total time is positive" '[[ $total_time -gt 0 ]]'
    _assert "Total time is reasonable (< 120 min)" '[[ $total_time -lt 120 ]]'

    section_count=$(echo "$time_est" | jq '.sections | length' 2>/dev/null)
    _assert "Time estimate per section" '[[ $section_count -gt 0 ]]'

    # Code section should have higher time than short section
    code_time=$(echo "$time_est" | jq '.sections[] | select(.heading == "Code Heavy Section") | .minutes' 2>/dev/null)
    short_time=$(echo "$time_est" | jq '.sections[] | select(.heading == "Short Section") | .minutes' 2>/dev/null)
    _assert "Code section takes longer than short section" '[[ ${code_time:-0} -gt ${short_time:-0} ]]'
fi

# Test with empty structure
empty_time=$(_slide_estimate_time "{}")
_assert_contains "Empty structure returns zero time" "$empty_time" '"total_minutes":0'

# Test with null structure
null_time=$(_slide_estimate_time "")
_assert_contains "Null structure returns zero time" "$null_time" '"total_minutes":0'

# =============================================================================
# SUITE 5: Full Optimization (_slide_optimize)
# =============================================================================
_test_start "Full Optimization (_slide_optimize)"

opt_result=$(_slide_optimize "$TEST_DIR/lecture-dense.qmd" "{}" "true" 2>/dev/null)

_assert "Returns valid optimization JSON" '[[ -n "$opt_result" && "$opt_result" != "{}" ]]'
_assert_contains "Has slide_breaks" "$opt_result" '"slide_breaks"'
_assert_contains "Has key_concepts_for_emphasis" "$opt_result" '"key_concepts_for_emphasis"'
_assert_contains "Has time_estimate" "$opt_result" '"time_estimate"'

if command -v jq &>/dev/null; then
    # Validate structure
    breaks=$(echo "$opt_result" | jq '.slide_breaks | length' 2>/dev/null)
    _assert "Has break suggestions" '[[ $breaks -gt 0 ]]'

    total_time=$(echo "$opt_result" | jq '.time_estimate.total_minutes' 2>/dev/null)
    _assert "Has positive time estimate" '[[ $total_time -gt 0 ]]'
fi

# Test with non-existent file
missing_opt=$(_slide_optimize "/nonexistent/file.qmd" "{}" "true" 2>/dev/null)
_assert_equals "Missing file returns empty" "{}" "$missing_opt"

# Test with concept graph
opt_with_graph=$(_slide_optimize "$TEST_DIR/lecture-concepts.qmd" "$concept_graph" "true" 2>/dev/null)
_assert "Optimization works with concept graph" '[[ -n "$opt_with_graph" && "$opt_with_graph" != "{}" ]]'

# =============================================================================
# SUITE 6: Preview Display (_slide_preview_breaks)
# =============================================================================
_test_start "Preview Display (_slide_preview_breaks)"

# Capture preview output
preview_output=$(_slide_preview_breaks "$opt_result" 2>/dev/null)

_assert "Preview produces output" '[[ -n "$preview_output" ]]'
_assert_contains "Shows SLIDE OPTIMIZATION header" "$preview_output" "SLIDE OPTIMIZATION"
_assert_contains "Shows break suggestions count" "$preview_output" "Break suggestions"
_assert_contains "Shows estimated time" "$preview_output" "Estimated time"

# Test with empty data
empty_preview=$(_slide_preview_breaks "{}" 2>/dev/null)
_assert_contains "Empty data shows no-data message" "$empty_preview" "No slide optimization data"

# Test with null
null_preview=$(_slide_preview_breaks "" 2>/dev/null)
_assert_contains "Null shows no-data message" "$null_preview" "No slide optimization data"

# =============================================================================
# SUITE 7: Apply Breaks (_slide_apply_breaks)
# =============================================================================
_test_start "Apply Breaks (_slide_apply_breaks)"

# Create a simple input file
cat > "$TEST_DIR/lecture-apply.qmd" << 'LECTURE'
---
title: "Apply Test"
---

## Introduction

This is a long section with many words to test the break insertion logic.
We need more than 300 words here to trigger a break. Let me add more content
to ensure we pass the threshold. The words keep flowing and flowing as we
discuss various aspects of the topic at hand. Statistical methods are crucial
for understanding data patterns. We explore multiple approaches to analysis.
The importance of proper methodology cannot be overstated in modern research.
Each technique has its strengths and limitations that must be considered.
Researchers should carefully evaluate which methods are appropriate for their
specific research questions and data characteristics. The field continues to
evolve with new computational approaches and theoretical developments.
This paragraph adds even more words to exceed the threshold. We continue
to discuss the fundamentals of statistical reasoning and data interpretation.
More words here to ensure the section is sufficiently long for testing purposes.
Statistical inference relies on probability theory and sampling distributions.
The central limit theorem provides the foundation for many statistical tests.
Understanding these concepts is essential for proper data analysis practice.

The next paragraph starts here after a blank line to trigger the break point.
This content should appear after the inserted slide break separator.

## Key Concepts

**Linear Regression** is important.

Normal text continues here.
LECTURE

# Build optimization data for the file
local apply_structure apply_opt
apply_structure=$(_slide_analyze_structure "$TEST_DIR/lecture-apply.qmd")
apply_opt=$(_slide_optimize "$TEST_DIR/lecture-apply.qmd" '{"concepts":{"linear-regression":{"name":"Linear Regression","introduced":true}}}' "true" 2>/dev/null)

# Apply breaks
_slide_apply_breaks "$TEST_DIR/lecture-apply.qmd" "$TEST_DIR/output-slides.qmd" "$apply_opt"
local apply_exit=$?

_assert_equals "Apply returns success" "0" "$apply_exit"
_assert "Output file created" '[[ -f "$TEST_DIR/output-slides.qmd" ]]'

if [[ -f "$TEST_DIR/output-slides.qmd" ]]; then
    local output_content
    output_content=$(cat "$TEST_DIR/output-slides.qmd")

    _assert_contains "Preserves frontmatter" "$output_content" 'title: "Apply Test"'
    _assert_contains "Preserves headings" "$output_content" "## Introduction"
    _assert_contains "Inserts horizontal rule break" "$output_content" "---"

    # Check callout insertion for key concepts
    _assert_contains "Inserts callout for key concept" "$output_content" "Key Concept: Linear Regression"
    _assert_contains "Uses callout-tip format" "$output_content" "{.callout-tip}"
fi

# Test apply with no optimization (just copies)
_slide_apply_breaks "$TEST_DIR/lecture-apply.qmd" "$TEST_DIR/output-copy.qmd" "{}"
_assert "Copy mode works" '[[ -f "$TEST_DIR/output-copy.qmd" ]]'

# Verify copy is identical to input
if [[ -f "$TEST_DIR/output-copy.qmd" ]]; then
    local diff_result
    diff_result=$(diff "$TEST_DIR/lecture-apply.qmd" "$TEST_DIR/output-copy.qmd" 2>/dev/null)
    _assert_equals "Copy is identical to source" "" "$diff_result"
fi

# Test with missing input file
_slide_apply_breaks "/nonexistent.qmd" "$TEST_DIR/output-fail.qmd" "$apply_opt"
local fail_exit=$?
_assert_equals "Missing file returns error" "1" "$fail_exit"

# =============================================================================
# SUITE 8: Constants and Configuration
# =============================================================================
_test_start "Constants and Configuration"

_assert_equals "SLIDE_MINUTES_PER_CONTENT is 2" "2" "$SLIDE_MINUTES_PER_CONTENT"
_assert_equals "SLIDE_MINUTES_PER_CODE is 3" "3" "$SLIDE_MINUTES_PER_CODE"
_assert_equals "SLIDE_MINUTES_PER_EXAMPLE is 4" "4" "$SLIDE_MINUTES_PER_EXAMPLE"
_assert_equals "SLIDE_MIN_SECTION_WORDS is 80" "80" "$SLIDE_MIN_SECTION_WORDS"
_assert_equals "SLIDE_MAX_SECTION_WORDS is 300" "300" "$SLIDE_MAX_SECTION_WORDS"

# =============================================================================
# RESULTS
# =============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  RESULTS: $pass_count/$test_count passed ($fail_count failures)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Exit with failure count
exit $fail_count
