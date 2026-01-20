#!/usr/bin/env zsh
#
# Unit Tests for Index Management (v5.14.0 - Quarto Workflow)
# Tests: ADD/UPDATE/REMOVE, sorting, cross-reference validation
#

# Get flow root before changing directories
FLOW_ROOT="${(%):-%x}"
FLOW_ROOT="${FLOW_ROOT:A:h:h}"

# Setup test environment
setup_test_env() {
    export TEST_DIR=$(mktemp -d)

    # Source required files BEFORE changing directory
    source "$FLOW_ROOT/lib/core.zsh"
    source "$FLOW_ROOT/lib/index-helpers.zsh"

    # Now change to test directory
    cd "$TEST_DIR"

    # Create test files
    mkdir -p lectures labs exams

    # Create test lecture files
    cat > lectures/week-01.qmd <<'EOF'
---
title: "Week 1: Introduction"
---

# Introduction

This is week 1 content.
EOF

    cat > lectures/week-05.qmd <<'EOF'
---
title: "Week 5: Factorial ANOVA"
---

# Factorial ANOVA

Content with cross-references.
See @sec-introduction for background.
EOF

    cat > lectures/week-10.qmd <<'EOF'
---
title: "Week 10: Advanced Topics"
---

# Advanced Topics

Refers to @fig-plot1 and @tbl-results.
EOF

    # Create index file
    cat > home_lectures.qmd <<'EOF'
---
title: "Lectures"
---

- [Week 1: Introduction](lectures/week-01.qmd)
- [Week 10: Advanced Topics](lectures/week-10.qmd)
EOF

    # Create a file with section anchors
    cat > lectures/background.qmd <<'EOF'
---
title: "Background"
---

# Introduction {#sec-introduction}

Background material.

# Plots {#fig-plot1}

![Plot 1](plot.png)

# Results {#tbl-results}

| A | B |
|---|---|
| 1 | 2 |
EOF
}

cleanup_test_env() {
    cd /
    rm -rf "$TEST_DIR"
}

# Test counter
TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0

# Test helpers
test_start() {
    ((TEST_COUNT++))
    echo ""
    echo "${FLOW_COLORS[info]}Test $TEST_COUNT: $1${FLOW_COLORS[reset]}"
}

test_pass() {
    ((PASS_COUNT++))
    echo "${FLOW_COLORS[success]}  ✓ PASS${FLOW_COLORS[reset]}"
}

test_fail() {
    ((FAIL_COUNT++))
    echo "${FLOW_COLORS[error]}  ✗ FAIL: $1${FLOW_COLORS[reset]}"
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local msg="$3"

    if [[ "$expected" == "$actual" ]]; then
        test_pass
    else
        test_fail "$msg (expected: '$expected', got: '$actual')"
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local msg="$3"

    if [[ "$haystack" == *"$needle"* ]]; then
        test_pass
    else
        test_fail "$msg (expected to contain: '$needle')"
    fi
}

# ============================================
# TEST SUITE
# ============================================

echo "${FLOW_COLORS[bold]}=====================================${FLOW_COLORS[reset]}"
echo "${FLOW_COLORS[bold]}Index Management Unit Tests${FLOW_COLORS[reset]}"
echo "${FLOW_COLORS[bold]}=====================================${FLOW_COLORS[reset]}"

setup_test_env

# Test 1: Parse week number
test_start "Parse week number from filename"
result=$(_parse_week_number "week-05.qmd")
assert_equals "5" "$result" "Should extract 5 from week-05.qmd"

# Test 2: Parse week number with leading zero
test_start "Parse week number with leading zero"
result=$(_parse_week_number "week-01.qmd")
assert_equals "1" "$result" "Should extract 1 from week-01.qmd"

# Test 3: Parse week number - alternative format
test_start "Parse week number from alternative format"
result=$(_parse_week_number "05-topic.qmd")
assert_equals "5" "$result" "Should extract 5 from 05-topic.qmd"

# Test 4: Parse week number - no match
test_start "Parse week number when not found"
result=$(_parse_week_number "introduction.qmd")
assert_equals "999" "$result" "Should return 999 when no week number found"

# Test 5: Extract title from YAML frontmatter
test_start "Extract title from YAML frontmatter"
result=$(_extract_title "lectures/week-05.qmd")
assert_equals "Week 5: Factorial ANOVA" "$result" "Should extract title"

# Test 6: Detect change type - ADD
test_start "Detect ADD change (new file not in index)"
result=$(_detect_index_changes "lectures/week-05.qmd")
assert_equals "ADD" "$result" "Should detect new file as ADD"

# Test 7: Detect change type - NONE (existing file)
test_start "Detect NONE change (existing file in index)"
result=$(_detect_index_changes "lectures/week-01.qmd")
assert_equals "NONE" "$result" "Should detect existing file as NONE"

# Test 8: Detect change type - UPDATE (title changed)
test_start "Detect UPDATE change (title changed)"
# Modify title in week-01
cat > lectures/week-01.qmd <<'EOF'
---
title: "Week 1: Introduction to Statistics"
---
EOF
result=$(_detect_index_changes "lectures/week-01.qmd")
assert_equals "UPDATE" "$result" "Should detect title change as UPDATE"

# Test 9: Get index file for lectures
test_start "Get index file for lectures directory"
result=$(_get_index_file "lectures/week-01.qmd")
assert_equals "home_lectures.qmd" "$result" "Should return home_lectures.qmd"

# Test 10: Get index file for labs
test_start "Get index file for labs directory"
result=$(_get_index_file "labs/lab-01.qmd")
assert_equals "home_labs.qmd" "$result" "Should return home_labs.qmd"

# Test 11: Get index file for exams
test_start "Get index file for exams directory"
result=$(_get_index_file "exams/midterm.qmd")
assert_equals "home_exams.qmd" "$result" "Should return home_exams.qmd"

# Test 12: Update index link (add new)
test_start "Add new link to index"
_update_index_link "lectures/week-05.qmd" "home_lectures.qmd" >/dev/null 2>&1
result=$(grep "week-05.qmd" "home_lectures.qmd")
assert_contains "$result" "Week 5: Factorial ANOVA" "Should add link to index"

# Test 13: Verify auto-sorting
test_start "Verify links are sorted by week number"
content=$(cat home_lectures.qmd)
# Week 1 should come before Week 5, Week 5 before Week 10
week1_line=$(grep -n "week-01.qmd" home_lectures.qmd | cut -d: -f1)
week5_line=$(grep -n "week-05.qmd" home_lectures.qmd | cut -d: -f1)
week10_line=$(grep -n "week-10.qmd" home_lectures.qmd | cut -d: -f1)

if [[ $week1_line -lt $week5_line ]] && [[ $week5_line -lt $week10_line ]]; then
    test_pass
else
    test_fail "Links not properly sorted (1:$week1_line, 5:$week5_line, 10:$week10_line)"
fi

# Test 14: Update existing link
test_start "Update existing link in index"
# Change title
cat > lectures/week-05.qmd <<'EOF'
---
title: "Week 5: Factorial ANOVA and Contrasts"
---
EOF
_update_index_link "lectures/week-05.qmd" "home_lectures.qmd" >/dev/null 2>&1
result=$(grep "week-05.qmd" "home_lectures.qmd")
assert_contains "$result" "Factorial ANOVA and Contrasts" "Should update link title"

# Test 15: Remove link from index
test_start "Remove link from index"
_remove_index_link "lectures/week-10.qmd" "home_lectures.qmd" >/dev/null 2>&1
result=$(grep "week-10.qmd" "home_lectures.qmd" || echo "NOT_FOUND")
assert_equals "NOT_FOUND" "$result" "Should remove link from index"

# Test 16: Find dependencies - sourced files
test_start "Find dependencies (sourced files)"
cat > lectures/analysis.qmd <<'EOF'
---
title: "Analysis"
---

```{r}
source("scripts/helper.R")
source("scripts/plot.R")
```
EOF

mkdir -p scripts
touch scripts/helper.R scripts/plot.R

deps=$(_find_dependencies "lectures/analysis.qmd")
assert_contains "$deps" "helper.R" "Should find sourced R file"

# Test 17: Find dependencies - cross-references
test_start "Find dependencies (cross-references)"
# Recreate week-05 with cross-reference (Test 14 overwrote it)
cat > lectures/week-05.qmd <<'EOF'
---
title: "Week 5: Factorial ANOVA"
---

# Factorial ANOVA

Content with cross-references.
See @sec-introduction for background.
EOF

deps=$(_find_dependencies "lectures/week-05.qmd")
assert_contains "$deps" "background.qmd" "Should find file with @sec-introduction"

# Test 18: Validate cross-references - valid
test_start "Validate cross-references (valid)"
_validate_cross_references "lectures/week-05.qmd" >/dev/null 2>&1
result=$?
assert_equals "0" "$result" "Should pass validation for valid references"

# Test 19: Validate cross-references - invalid
test_start "Validate cross-references (invalid)"
cat > lectures/broken.qmd <<'EOF'
---
title: "Broken"
---

See @sec-nonexistent for details.
EOF

_validate_cross_references "lectures/broken.qmd" >/dev/null 2>&1
result=$?
assert_equals "1" "$result" "Should fail validation for broken references"

# Test 20: Find insertion point - beginning
test_start "Find insertion point for week earlier than all"
cat > lectures/week-00.qmd <<'EOF'
---
title: "Week 0: Setup"
---
EOF

line=$(_find_insertion_point "home_lectures.qmd" 0)
# Should insert before week-01
week1_line=$(grep -n "week-01.qmd" home_lectures.qmd | cut -d: -f1)
if [[ $line -le $week1_line ]]; then
    test_pass
else
    test_fail "Should insert before week 1 (got line $line, week 1 at $week1_line)"
fi

# Test 21: Find insertion point - end
test_start "Find insertion point for week later than all"
line=$(_find_insertion_point "home_lectures.qmd" 99)
total_lines=$(wc -l < home_lectures.qmd)
if [[ $line -gt $total_lines ]] || [[ $line -eq $total_lines ]]; then
    test_pass
else
    test_fail "Should insert at end (got line $line, total $total_lines)"
fi

# Test 22: Detect REMOVE change
test_start "Detect REMOVE change (file deleted)"
rm lectures/week-01.qmd
result=$(_detect_index_changes "lectures/week-01.qmd")
assert_equals "REMOVE" "$result" "Should detect deleted file as REMOVE"

# Test 23: Extract title - fallback to filename
test_start "Extract title with fallback to filename"
result=$(_extract_title "lectures/nonexistent.qmd")
assert_equals "" "$result" "Should return empty for nonexistent file"

# Test 24: Process index changes - multiple files
test_start "Process index changes for multiple files"
# Create new files
cat > lectures/week-03.qmd <<'EOF'
---
title: "Week 3: T-Tests"
---
EOF

cat > lectures/week-07.qmd <<'EOF'
---
title: "Week 7: Regression"
---
EOF

# This would normally prompt, but we'll test the detection
change1=$(_detect_index_changes "lectures/week-03.qmd")
change2=$(_detect_index_changes "lectures/week-07.qmd")

if [[ "$change1" == "ADD" ]] && [[ "$change2" == "ADD" ]]; then
    test_pass
else
    test_fail "Should detect both as ADD (got: $change1, $change2)"
fi

# Test 25: Cross-reference validation - multiple references
test_start "Validate multiple cross-references"
cat > lectures/multi-ref.qmd <<'EOF'
---
title: "Multiple References"
---

See @sec-introduction and @fig-plot1 and @tbl-results.
EOF

_validate_cross_references "lectures/multi-ref.qmd" >/dev/null 2>&1
result=$?
assert_equals "0" "$result" "Should validate multiple references"

# ============================================
# TEST SUMMARY
# ============================================

echo ""
echo "${FLOW_COLORS[bold]}=====================================${FLOW_COLORS[reset]}"
echo "${FLOW_COLORS[bold]}Test Summary${FLOW_COLORS[reset]}"
echo "${FLOW_COLORS[bold]}=====================================${FLOW_COLORS[reset]}"
echo ""
echo "Total tests:  $TEST_COUNT"
echo "${FLOW_COLORS[success]}Passed:       $PASS_COUNT${FLOW_COLORS[reset]}"

if [[ $FAIL_COUNT -gt 0 ]]; then
    echo "${FLOW_COLORS[error]}Failed:       $FAIL_COUNT${FLOW_COLORS[reset]}"
else
    echo "Failed:       $FAIL_COUNT"
fi

echo ""

if [[ $FAIL_COUNT -eq 0 ]]; then
    echo "${FLOW_COLORS[success]}✅ All tests passed!${FLOW_COLORS[reset]}"
    cleanup_test_env
    exit 0
else
    echo "${FLOW_COLORS[error]}❌ Some tests failed${FLOW_COLORS[reset]}"
    cleanup_test_env
    exit 1
fi
