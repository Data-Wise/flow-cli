#!/usr/bin/env zsh
# test-teach-plan.zsh - Tests for teach plan command
# v5.22.0 - Lesson Plan CRUD (#278)

# Get script directory and set up paths
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

# Source test helpers
source "$PROJECT_ROOT/tests/test-helpers.zsh" 2>/dev/null || {
    # Minimal test helpers if not found
    TEST_PASS=0
    TEST_FAIL=0

    test_pass() { ((TEST_PASS++)); echo "  ✅ $1"; }
    test_fail() { ((TEST_FAIL++)); echo "  ❌ $1: $2"; }
    test_summary() { echo ""; echo "Tests: $((TEST_PASS + TEST_FAIL)) | Pass: $TEST_PASS | Fail: $TEST_FAIL"; }
}

# Source libraries
source "$PROJECT_ROOT/lib/core.zsh" 2>/dev/null || true
source "$PROJECT_ROOT/commands/teach-plan.zsh" 2>/dev/null || true

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  teach plan - Unit & Integration Tests                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# SETUP
# ============================================================================

TEST_DIR=$(mktemp -d)
ORIGINAL_DIR=$(pwd)

cleanup() {
    cd "$ORIGINAL_DIR"
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Helper: create a test project directory with .flow
setup_project() {
    local dir="$TEST_DIR/project-$$-$RANDOM"
    mkdir -p "$dir/.flow"
    echo "$dir"
}

# Helper: create lesson-plans.yml with sample data
create_sample_plans() {
    local dir="$1"
    cat > "$dir/.flow/lesson-plans.yml" <<'YAML'
weeks:
  - number: 1
    topic: "Introduction to Statistics"
    style: "conceptual"
    objectives:
      - "Define descriptive statistics"
      - "Identify data types"
    subtopics:
      - "Measures of central tendency"
      - "Variability"
    key_concepts:
      - "descriptive-stats"
      - "data-types"
    prerequisites: []
  - number: 3
    topic: "Probability Foundations"
    style: "rigorous"
    objectives:
      - "Explain probability axioms"
    subtopics: []
    key_concepts:
      - "probability"
    prerequisites:
      - "descriptive-stats"
  - number: 5
    topic: "Sampling Distributions"
    style: "computational"
    objectives: []
    subtopics: []
    key_concepts: []
    prerequisites: []
YAML
}

# Helper: create teach-config.yml with embedded weeks
create_sample_config() {
    local dir="$1"
    cat > "$dir/.flow/teach-config.yml" <<'YAML'
course_info:
  name: "STAT 101"
semester_info:
  weeks:
    - number: 1
      topic: "Intro to Stats"
    - number: 2
      topic: "Data Visualization"
    - number: 3
      topic: "Probability"
YAML
}

# Check yq is available (required for tests)
if ! command -v yq &>/dev/null; then
    echo "⚠️  yq not found - skipping tests that require yq"
    HAS_YQ=0
else
    HAS_YQ=1
fi

# ============================================================================
# CREATE TESTS
# ============================================================================

echo "━━━ Create ━━━"

# Test 1: Create with all options (non-interactive)
test_create_full() {
    [[ $HAS_YQ -eq 0 ]] && { test_pass "SKIP: create with full options (no yq)"; return; }

    local proj=$(setup_project)
    cd "$proj"

    local output
    output=$(_teach_plan_create 1 --topic "Introduction" --style "conceptual" <<< $'\n\n' 2>&1)

    if [[ -f ".flow/lesson-plans.yml" ]]; then
        local topic
        topic=$(yq '.weeks[0].topic' .flow/lesson-plans.yml 2>/dev/null)
        if [[ "$topic" == "Introduction" ]]; then
            test_pass "Create with --topic and --style"
        else
            test_fail "Create with --topic" "topic=$topic"
        fi
    else
        test_fail "Create with full options" "lesson-plans.yml not created"
    fi
}
test_create_full

# Test 2: Create creates file if missing
test_create_new_file() {
    [[ $HAS_YQ -eq 0 ]] && { test_pass "SKIP: create new file (no yq)"; return; }

    local proj=$(setup_project)
    cd "$proj"

    # Ensure no plans file
    rm -f ".flow/lesson-plans.yml"

    _teach_plan_create 1 --topic "Test" --style "conceptual" <<< $'\n\n' &>/dev/null

    if [[ -f ".flow/lesson-plans.yml" ]]; then
        test_pass "Create auto-creates lesson-plans.yml"
    else
        test_fail "Create auto-creates file" "file not created"
    fi
}
test_create_new_file

# Test 3: Create fails without week number
test_create_no_week() {
    local proj=$(setup_project)
    cd "$proj"

    local output
    output=$(_teach_plan_create 2>&1)
    local rc=$?

    if [[ $rc -ne 0 ]]; then
        test_pass "Create fails without week number"
    else
        test_fail "Create no week" "should fail, got rc=$rc"
    fi
}
test_create_no_week

# Test 4: Create validates week range
test_create_invalid_week() {
    local proj=$(setup_project)
    cd "$proj"

    local output
    output=$(_teach_plan_create 25 2>&1)
    local rc=$?

    if [[ $rc -ne 0 ]]; then
        test_pass "Create rejects week > 20"
    else
        test_fail "Create invalid week" "should reject 25"
    fi
}
test_create_invalid_week

# Test 5: Create rejects zero week
test_create_zero_week() {
    local proj=$(setup_project)
    cd "$proj"

    local output
    output=$(_teach_plan_create 0 2>&1)
    local rc=$?

    if [[ $rc -ne 0 ]]; then
        test_pass "Create rejects week 0"
    else
        test_fail "Create zero week" "should reject 0"
    fi
}
test_create_zero_week

# Test 6: Create detects duplicate week
test_create_duplicate() {
    [[ $HAS_YQ -eq 0 ]] && { test_pass "SKIP: duplicate detection (no yq)"; return; }

    local proj=$(setup_project)
    cd "$proj"
    create_sample_plans "$proj"

    local output
    output=$(_teach_plan_create 1 --topic "Dup" --style "conceptual" 2>&1)
    local rc=$?

    if [[ $rc -ne 0 ]]; then
        test_pass "Create detects duplicate week"
    else
        test_fail "Create duplicate" "should fail for existing week 1"
    fi
}
test_create_duplicate

# Test 7: Create with --force overwrites duplicate
test_create_force() {
    [[ $HAS_YQ -eq 0 ]] && { test_pass "SKIP: force overwrite (no yq)"; return; }

    local proj=$(setup_project)
    cd "$proj"
    create_sample_plans "$proj"

    _teach_plan_create 1 --topic "Replaced" --style "applied" --force <<< $'\n\n' &>/dev/null

    local topic
    topic=$(yq '.weeks[] | select(.number == 1) | .topic' .flow/lesson-plans.yml 2>/dev/null)
    if [[ "$topic" == "Replaced" ]]; then
        test_pass "Create --force overwrites existing week"
    else
        test_fail "Create --force" "topic=$topic, expected Replaced"
    fi
}
test_create_force

# Test 8: Create auto-populates topic from config
test_create_auto_populate() {
    [[ $HAS_YQ -eq 0 ]] && { test_pass "SKIP: auto-populate (no yq)"; return; }

    local proj=$(setup_project)
    cd "$proj"
    create_sample_config "$proj"

    _teach_plan_create 2 --style "conceptual" <<< $'\n\n' &>/dev/null

    local topic
    topic=$(yq '.weeks[] | select(.number == 2) | .topic' .flow/lesson-plans.yml 2>/dev/null)
    if [[ "$topic" == "Data Visualization" ]]; then
        test_pass "Create auto-populates topic from config"
    else
        test_fail "Create auto-populate" "topic=$topic, expected 'Data Visualization'"
    fi
}
test_create_auto_populate

# Test 9: Create validates style
test_create_invalid_style() {
    local proj=$(setup_project)
    cd "$proj"

    local output
    output=$(_teach_plan_create 1 --topic "Test" --style "invalid" 2>&1)
    local rc=$?

    if [[ $rc -ne 0 ]]; then
        test_pass "Create rejects invalid style"
    else
        test_fail "Create invalid style" "should reject 'invalid'"
    fi
}
test_create_invalid_style

# Test 10: Create sorts weeks by number
test_create_sorted() {
    [[ $HAS_YQ -eq 0 ]] && { test_pass "SKIP: sort check (no yq)"; return; }

    local proj=$(setup_project)
    cd "$proj"
    create_sample_plans "$proj"

    # Add week 2 (between existing 1 and 3)
    _teach_plan_create 2 --topic "Data Viz" --style "computational" <<< $'\n\n' &>/dev/null

    local second_num
    second_num=$(yq '.weeks[1].number' .flow/lesson-plans.yml 2>/dev/null)
    if [[ "$second_num" == "2" ]]; then
        test_pass "Create maintains sorted order"
    else
        test_fail "Create sorted" "second entry number=$second_num, expected 2"
    fi
}
test_create_sorted

echo ""

# ============================================================================
# LIST TESTS
# ============================================================================

echo "━━━ List ━━━"

# Test 11: List with sample data
test_list_basic() {
    [[ $HAS_YQ -eq 0 ]] && { test_pass "SKIP: list basic (no yq)"; return; }

    local proj=$(setup_project)
    cd "$proj"
    create_sample_plans "$proj"

    local output
    output=$(_teach_plan_list 2>&1)

    if echo "$output" | grep -q "Introduction to Statistics"; then
        test_pass "List displays week topics"
    else
        test_fail "List basic" "output missing topic text"
    fi
}
test_list_basic

# Test 12: List empty state
test_list_empty() {
    local proj=$(setup_project)
    cd "$proj"

    # Ensure no plans file
    rm -f ".flow/lesson-plans.yml"

    local output
    output=$(_teach_plan_list 2>&1)

    if echo "$output" | grep -qi "no lesson plans"; then
        test_pass "List shows empty state message"
    else
        test_fail "List empty" "missing empty state message. output: $(echo $output | head -3)"
    fi
}
test_list_empty

# Test 13: List JSON output
test_list_json() {
    [[ $HAS_YQ -eq 0 ]] && { test_pass "SKIP: list JSON (no yq)"; return; }

    local proj=$(setup_project)
    cd "$proj"
    create_sample_plans "$proj"

    local output
    output=$(_teach_plan_list --json 2>&1)

    if echo "$output" | grep -q '"topic"'; then
        test_pass "List --json produces JSON output"
    else
        test_fail "List JSON" "output not valid JSON"
    fi
}
test_list_json

# Test 14: List detects gaps
test_list_gaps() {
    [[ $HAS_YQ -eq 0 ]] && { test_pass "SKIP: list gaps (no yq)"; return; }

    local proj=$(setup_project)
    cd "$proj"
    create_sample_plans "$proj"

    local output
    output=$(_teach_plan_list 2>&1)

    if echo "$output" | grep -q "Gaps"; then
        test_pass "List detects gaps in week sequence"
    else
        test_fail "List gaps" "should detect gaps (weeks 2, 4 missing)"
    fi
}
test_list_gaps

# Test 15: List shows week count
test_list_count() {
    [[ $HAS_YQ -eq 0 ]] && { test_pass "SKIP: list count (no yq)"; return; }

    local proj=$(setup_project)
    cd "$proj"
    create_sample_plans "$proj"

    local output
    output=$(_teach_plan_list 2>&1)

    if echo "$output" | grep -q "3 week"; then
        test_pass "List shows correct week count"
    else
        test_fail "List count" "should show 3 weeks"
    fi
}
test_list_count

echo ""

# ============================================================================
# SHOW TESTS
# ============================================================================

echo "━━━ Show ━━━"

# Test 16: Show existing week
test_show_basic() {
    [[ $HAS_YQ -eq 0 ]] && { test_pass "SKIP: show basic (no yq)"; return; }

    local proj=$(setup_project)
    cd "$proj"
    create_sample_plans "$proj"

    local output
    output=$(_teach_plan_show 1 2>&1)

    if echo "$output" | grep -q "Introduction to Statistics" && echo "$output" | grep -q "conceptual"; then
        test_pass "Show displays week details"
    else
        test_fail "Show basic" "missing topic or style"
    fi
}
test_show_basic

# Test 17: Show non-existent week
test_show_not_found() {
    [[ $HAS_YQ -eq 0 ]] && { test_pass "SKIP: show not found (no yq)"; return; }

    local proj=$(setup_project)
    cd "$proj"
    create_sample_plans "$proj"

    local output
    output=$(_teach_plan_show 99 2>&1)
    local rc=$?

    if [[ $rc -ne 0 ]]; then
        test_pass "Show returns error for non-existent week"
    else
        test_fail "Show not found" "should fail for week 99"
    fi
}
test_show_not_found

# Test 18: Show JSON output
test_show_json() {
    [[ $HAS_YQ -eq 0 ]] && { test_pass "SKIP: show JSON (no yq)"; return; }

    local proj=$(setup_project)
    cd "$proj"
    create_sample_plans "$proj"

    local output
    output=$(_teach_plan_show 1 --json 2>&1)

    if echo "$output" | grep -q '"topic"'; then
        test_pass "Show --json produces JSON"
    else
        test_fail "Show JSON" "output not JSON"
    fi
}
test_show_json

# Test 19: Show displays objectives
test_show_objectives() {
    [[ $HAS_YQ -eq 0 ]] && { test_pass "SKIP: show objectives (no yq)"; return; }

    local proj=$(setup_project)
    cd "$proj"
    create_sample_plans "$proj"

    local output
    output=$(_teach_plan_show 1 2>&1)

    if echo "$output" | grep -q "Define descriptive statistics"; then
        test_pass "Show displays objectives"
    else
        test_fail "Show objectives" "missing objectives content"
    fi
}
test_show_objectives

# Test 20: Show requires week number
test_show_no_week() {
    local proj=$(setup_project)
    cd "$proj"

    local output
    output=$(_teach_plan_show 2>&1)
    local rc=$?

    if [[ $rc -ne 0 ]]; then
        test_pass "Show fails without week number"
    else
        test_fail "Show no week" "should require week"
    fi
}
test_show_no_week

echo ""

# ============================================================================
# EDIT TESTS
# ============================================================================

echo "━━━ Edit ━━━"

# Test 21: Edit requires week number
test_edit_no_week() {
    local proj=$(setup_project)
    cd "$proj"

    local output
    output=$(_teach_plan_edit 2>&1)
    local rc=$?

    if [[ $rc -ne 0 ]]; then
        test_pass "Edit fails without week number"
    else
        test_fail "Edit no week" "should require week"
    fi
}
test_edit_no_week

# Test 22: Edit fails for missing file
test_edit_no_file() {
    local proj=$(setup_project)
    cd "$proj"

    # Ensure no plans file
    rm -f ".flow/lesson-plans.yml"

    local output
    output=$(_teach_plan_edit 1 2>&1)
    local rc=$?

    if [[ $rc -ne 0 ]] || echo "$output" | grep -qi "not found"; then
        test_pass "Edit fails when no lesson-plans.yml"
    else
        test_fail "Edit no file" "rc=$rc, output: $(echo $output | head -2)"
    fi
}
test_edit_no_file

# Test 23: Edit fails for non-existent week
test_edit_missing_week() {
    [[ $HAS_YQ -eq 0 ]] && { test_pass "SKIP: edit missing week (no yq)"; return; }

    local proj=$(setup_project)
    cd "$proj"
    create_sample_plans "$proj"

    local output
    output=$(_teach_plan_edit 99 2>&1)
    local rc=$?

    if [[ $rc -ne 0 ]]; then
        test_pass "Edit fails for non-existent week"
    else
        test_fail "Edit missing week" "should fail for week 99"
    fi
}
test_edit_missing_week

echo ""

# ============================================================================
# DELETE TESTS
# ============================================================================

echo "━━━ Delete ━━━"

# Test 24: Delete with --force
test_delete_force() {
    [[ $HAS_YQ -eq 0 ]] && { test_pass "SKIP: delete force (no yq)"; return; }

    local proj=$(setup_project)
    cd "$proj"
    create_sample_plans "$proj"

    _teach_plan_delete 1 --force &>/dev/null

    local exists
    exists=$(yq '.weeks[] | select(.number == 1) | .number' .flow/lesson-plans.yml 2>/dev/null)
    if [[ -z "$exists" ]]; then
        test_pass "Delete --force removes week entry"
    else
        test_fail "Delete force" "week 1 still exists"
    fi
}
test_delete_force

# Test 25: Delete non-existent week
test_delete_not_found() {
    [[ $HAS_YQ -eq 0 ]] && { test_pass "SKIP: delete not found (no yq)"; return; }

    local proj=$(setup_project)
    cd "$proj"
    create_sample_plans "$proj"

    local output
    output=$(_teach_plan_delete 99 --force 2>&1)
    local rc=$?

    if [[ $rc -ne 0 ]]; then
        test_pass "Delete returns error for non-existent week"
    else
        test_fail "Delete not found" "should fail for week 99"
    fi
}
test_delete_not_found

# Test 26: Delete requires week number
test_delete_no_week() {
    local proj=$(setup_project)
    cd "$proj"

    local output
    output=$(_teach_plan_delete 2>&1)
    local rc=$?

    if [[ $rc -ne 0 ]]; then
        test_pass "Delete fails without week number"
    else
        test_fail "Delete no week" "should require week"
    fi
}
test_delete_no_week

echo ""

# ============================================================================
# DISPATCHER TESTS
# ============================================================================

echo "━━━ Dispatcher ━━━"

# Test 27: Dispatcher routes to list by default
test_dispatch_default() {
    [[ $HAS_YQ -eq 0 ]] && { test_pass "SKIP: dispatch default (no yq)"; return; }

    local proj=$(setup_project)
    cd "$proj"
    create_sample_plans "$proj"

    local output
    output=$(_teach_plan 2>&1)

    if echo "$output" | grep -q "Introduction to Statistics"; then
        test_pass "Dispatcher defaults to list"
    else
        test_fail "Dispatch default" "should show list output"
    fi
}
test_dispatch_default

# Test 28: Dispatcher routes number to show
test_dispatch_number() {
    [[ $HAS_YQ -eq 0 ]] && { test_pass "SKIP: dispatch number (no yq)"; return; }

    local proj=$(setup_project)
    cd "$proj"
    create_sample_plans "$proj"

    local output
    output=$(_teach_plan 1 2>&1)

    if echo "$output" | grep -q "Week 1"; then
        test_pass "Dispatcher routes bare number to show"
    else
        test_fail "Dispatch number" "should show week 1 details"
    fi
}
test_dispatch_number

# Test 29: Dispatcher routes aliases
test_dispatch_aliases() {
    local proj=$(setup_project)
    cd "$proj"

    # Test that help alias works
    local output
    output=$(_teach_plan help 2>&1)

    if echo "$output" | grep -q "Lesson Plan Management"; then
        test_pass "Dispatcher routes 'help' alias"
    else
        test_fail "Dispatch aliases" "help alias not working"
    fi
}
test_dispatch_aliases

echo ""

# ============================================================================
# INTEGRATION TESTS
# ============================================================================

echo "━━━ Integration ━━━"

# Test 30: Create then load with _teach_load_lesson_plan
test_create_then_load() {
    [[ $HAS_YQ -eq 0 ]] && { test_pass "SKIP: create-load integration (no yq)"; return; }

    local proj=$(setup_project)
    cd "$proj"

    # Create a plan
    _teach_plan_create 7 --topic "Regression" --style "applied" <<< $'\n\n' &>/dev/null

    # Load it using the existing function
    if typeset -f _teach_load_lesson_plan &>/dev/null; then
        _teach_load_lesson_plan 7 &>/dev/null
        if [[ "$TEACH_PLAN_TOPIC" == "Regression" ]]; then
            test_pass "Created plan loads via _teach_load_lesson_plan"
        else
            test_fail "Create-load integration" "TEACH_PLAN_TOPIC=$TEACH_PLAN_TOPIC"
        fi
    else
        test_pass "SKIP: _teach_load_lesson_plan not available"
    fi
}
test_create_then_load

# Test 31: Create, list, delete cycle
test_crud_cycle() {
    [[ $HAS_YQ -eq 0 ]] && { test_pass "SKIP: CRUD cycle (no yq)"; return; }

    local proj=$(setup_project)
    cd "$proj"

    # Create
    _teach_plan_create 4 --topic "ANOVA" --style "computational" <<< $'\n\n' &>/dev/null

    # Verify in list
    local list_out
    list_out=$(_teach_plan_list 2>&1)
    local has_anova=0
    echo "$list_out" | grep -q "ANOVA" && has_anova=1

    # Delete
    _teach_plan_delete 4 --force &>/dev/null

    # Verify removed
    local exists_after
    exists_after=$(yq '.weeks[] | select(.number == 4) | .number' .flow/lesson-plans.yml 2>/dev/null)

    if [[ $has_anova -eq 1 && -z "$exists_after" ]]; then
        test_pass "Full CRUD cycle (create → list → delete)"
    else
        test_fail "CRUD cycle" "has_anova=$has_anova, exists_after=$exists_after"
    fi
}
test_crud_cycle

echo ""

# ============================================================================
# HELP TESTS
# ============================================================================

echo "━━━ Help ━━━"

# Test 32: Help output contains sections
test_help_content() {
    local output
    output=$(_teach_plan_help 2>&1)

    local has_usage=0 has_actions=0 has_examples=0
    echo "$output" | grep -q "USAGE" && has_usage=1
    echo "$output" | grep -q "ACTIONS" && has_actions=1
    echo "$output" | grep -q "EXAMPLES" && has_examples=1

    if [[ $has_usage -eq 1 && $has_actions -eq 1 && $has_examples -eq 1 ]]; then
        test_pass "Help contains USAGE, ACTIONS, EXAMPLES"
    else
        test_fail "Help content" "usage=$has_usage actions=$has_actions examples=$has_examples"
    fi
}
test_help_content

# ============================================================================
# SUMMARY
# ============================================================================

cd "$ORIGINAL_DIR"
echo ""
test_summary
