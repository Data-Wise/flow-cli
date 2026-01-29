#!/usr/bin/env zsh
# e2e-teach-plan.zsh - End-to-end tests for teach plan command
# v5.22.0 - Lesson Plan CRUD (#278)
#
# Tests complete user workflows: migration → plan management → content generation.
# Uses the demo course fixture for realistic scenarios.

# Get script directory and set up paths
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

# Source test helpers
source "$PROJECT_ROOT/tests/test-helpers.zsh" 2>/dev/null || {
    TEST_PASS=0
    TEST_FAIL=0

    test_pass() { ((TEST_PASS++)); echo "  ✅ $1"; }
    test_fail() { ((TEST_FAIL++)); echo "  ❌ $1: $2"; }
    test_summary() { echo ""; echo "Tests: $((TEST_PASS + TEST_FAIL)) | Pass: $TEST_PASS | Fail: $TEST_FAIL"; }
}

# Source libraries
unset _FLOW_TEACH_PLAN_LOADED
unset _FLOW_TEACH_MIGRATE_LOADED
source "$PROJECT_ROOT/lib/core.zsh" 2>/dev/null || true
source "$PROJECT_ROOT/commands/teach-plan.zsh" 2>/dev/null || true
source "$PROJECT_ROOT/commands/teach-migrate.zsh" 2>/dev/null || true

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  teach plan - End-to-End Tests                             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# SETUP
# ============================================================================

TEST_DIR=$(mktemp -d)
ORIGINAL_DIR=$(pwd)
DEMO_COURSE="$PROJECT_ROOT/tests/fixtures/demo-course"

cleanup() {
    cd "$ORIGINAL_DIR"
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Check yq is available
if ! command -v yq &>/dev/null; then
    echo "⚠️  yq not found - skipping E2E tests"
    exit 0
fi

# Helper: copy demo course to temp dir
setup_demo_course() {
    local dir
    dir=$(mktemp -d "$TEST_DIR/e2e-XXXXXXXX")
    if [[ -d "$DEMO_COURSE" ]]; then
        cp -r "$DEMO_COURSE" "$dir"
    else
        mkdir -p "$dir/.flow"
    fi
    echo "$dir"
}

# Helper: create a realistic course from scratch
setup_fresh_course() {
    local dir
    dir=$(mktemp -d "$TEST_DIR/fresh-XXXXXXXX")
    mkdir -p "$dir/.flow"

    cat > "$dir/.flow/teach-config.yml" <<'YAML'
course_info:
  name: "STAT 440"
  title: "Regression Analysis"
  semester: "Spring 2026"
  instructor: "Dr. Test"
semester_info:
  total_weeks: 15
  weeks:
    - number: 1
      topic: "Simple Linear Regression"
    - number: 2
      topic: "Multiple Regression"
    - number: 3
      topic: "Model Diagnostics"
    - number: 4
      topic: "Transformations"
    - number: 5
      topic: "Polynomial Regression"
    - number: 6
      topic: "Indicator Variables"
    - number: 7
      topic: "Multicollinearity"
    - number: 8
      topic: "Model Selection"
    - number: 9
      topic: "Ridge & Lasso"
    - number: 10
      topic: "Logistic Regression"
    - number: 11
      topic: "Poisson Regression"
    - number: 12
      topic: "Mixed Effects Models"
    - number: 13
      topic: "Time Series Basics"
    - number: 14
      topic: "Bayesian Regression"
    - number: 15
      topic: "Review & Synthesis"
YAML

    echo "$dir"
}

# ============================================================================
# E2E WORKFLOW 1: Fresh Course Setup
# ============================================================================

echo "━━━ E2E 1: Fresh Course Setup ━━━"

# Test E1: Create plans from scratch for a new course
test_e2e_fresh_course() {
    local proj=$(setup_fresh_course)
    cd "$proj"

    # Create first 3 weeks manually
    _teach_plan_create 1 --topic "Simple Linear Regression" --style "conceptual" <<< $'\n\n' &>/dev/null
    _teach_plan_create 2 --topic "Multiple Regression" --style "computational" <<< $'\n\n' &>/dev/null
    _teach_plan_create 3 --topic "Model Diagnostics" --style "applied" <<< $'\n\n' &>/dev/null

    # Verify file is valid
    if ! yq eval '.' .flow/lesson-plans.yml &>/dev/null; then
        test_fail "E2E fresh course" "invalid YAML after 3 creates"
        return
    fi

    # Verify count
    local count
    count=$(yq '.weeks | length' .flow/lesson-plans.yml 2>/dev/null)
    if [[ "$count" == "3" ]]; then
        test_pass "Fresh course: 3 weeks created successfully"
    else
        test_fail "Fresh course create" "count=$count"
    fi
}
test_e2e_fresh_course

# Test E2: Auto-populate topics from config
test_e2e_auto_populate() {
    local proj=$(setup_fresh_course)
    cd "$proj"

    # Create week without --topic — should auto-populate from config
    _teach_plan_create 5 --style "computational" <<< $'\n\n' &>/dev/null

    local topic
    topic=$(yq '.weeks[] | select(.number == 5) | .topic' .flow/lesson-plans.yml 2>/dev/null)
    if [[ "$topic" == "Polynomial Regression" ]]; then
        test_pass "Auto-populate: week 5 topic from config"
    else
        test_fail "Auto-populate" "topic='$topic', expected 'Polynomial Regression'"
    fi
}
test_e2e_auto_populate

# Test E3: List shows created weeks with gap detection
test_e2e_list_with_gaps() {
    local proj=$(setup_fresh_course)
    cd "$proj"

    # Create non-consecutive weeks
    _teach_plan_create 1 --topic "SLR" --style "conceptual" <<< $'\n\n' &>/dev/null
    _teach_plan_create 3 --topic "Diagnostics" --style "applied" <<< $'\n\n' &>/dev/null
    _teach_plan_create 5 --style "computational" <<< $'\n\n' &>/dev/null

    local output
    output=$(_teach_plan_list 2>&1)

    local has_gaps=0 has_count=0
    echo "$output" | grep -q "Gaps" && has_gaps=1
    echo "$output" | grep -q "3 week" && has_count=1  # matches "3 week(s)"

    if [[ $has_gaps -eq 1 && $has_count -eq 1 ]]; then
        test_pass "List shows gaps and count for non-consecutive weeks"
    else
        test_fail "List with gaps" "has_gaps=$has_gaps has_count=$has_count"
    fi
}
test_e2e_list_with_gaps

echo ""

# ============================================================================
# E2E WORKFLOW 2: Full CRUD Lifecycle
# ============================================================================

echo "━━━ E2E 2: Full CRUD Lifecycle ━━━"

# Test E4: Complete lifecycle: create → show → list → delete → verify
test_e2e_full_lifecycle() {
    local proj=$(setup_fresh_course)
    cd "$proj"

    # Step 1: Create
    _teach_plan_create 7 --topic "Multicollinearity" --style "rigorous" <<< $'\n\n' &>/dev/null
    local create_ok=0
    yq '.weeks[] | select(.number == 7) | .topic' .flow/lesson-plans.yml 2>/dev/null | grep -q "Multicollinearity" && create_ok=1

    # Step 2: Show
    local show_output
    show_output=$(_teach_plan_show 7 2>&1)
    local show_ok=0
    echo "$show_output" | grep -q "Multicollinearity" && show_ok=1

    # Step 3: List
    local list_output
    list_output=$(_teach_plan_list 2>&1)
    local list_ok=0
    echo "$list_output" | grep -q "Multicollinearity" && list_ok=1

    # Step 4: Delete
    _teach_plan_delete 7 --force &>/dev/null
    local delete_ok=0
    local remaining
    remaining=$(yq '.weeks[] | select(.number == 7) | .number' .flow/lesson-plans.yml 2>/dev/null)
    [[ -z "$remaining" ]] && delete_ok=1

    # Step 5: Verify file still valid
    local valid_ok=0
    yq eval '.' .flow/lesson-plans.yml &>/dev/null && valid_ok=1

    if [[ $create_ok -eq 1 && $show_ok -eq 1 && $list_ok -eq 1 && $delete_ok -eq 1 && $valid_ok -eq 1 ]]; then
        test_pass "Full CRUD lifecycle (create → show → list → delete → verify)"
    else
        test_fail "Full lifecycle" "create=$create_ok show=$show_ok list=$list_ok delete=$delete_ok valid=$valid_ok"
    fi
}
test_e2e_full_lifecycle

# Test E5: Force overwrite cycle
test_e2e_force_overwrite() {
    local proj=$(setup_fresh_course)
    cd "$proj"

    # Create initial
    _teach_plan_create 4 --topic "Original Topic" --style "conceptual" <<< $'\n\n' &>/dev/null

    # Verify duplicate blocked
    local dup_output
    dup_output=$(_teach_plan_create 4 --topic "Duplicate" --style "conceptual" 2>&1)
    local dup_rc=$?
    local blocked=0
    [[ $dup_rc -ne 0 ]] && blocked=1

    # Force overwrite
    _teach_plan_create 4 --topic "Replaced Topic" --style "applied" --force <<< $'\n\n' &>/dev/null

    local new_topic
    new_topic=$(yq '.weeks[] | select(.number == 4) | .topic' .flow/lesson-plans.yml 2>/dev/null)
    local new_style
    new_style=$(yq '.weeks[] | select(.number == 4) | .style' .flow/lesson-plans.yml 2>/dev/null)

    if [[ $blocked -eq 1 && "$new_topic" == "Replaced Topic" && "$new_style" == "applied" ]]; then
        test_pass "Force overwrite: blocked without flag, replaced with flag"
    else
        test_fail "Force overwrite" "blocked=$blocked topic='$new_topic' style='$new_style'"
    fi
}
test_e2e_force_overwrite

echo ""

# ============================================================================
# E2E WORKFLOW 3: Bulk Week Creation
# ============================================================================

echo "━━━ E2E 3: Bulk Week Creation ━━━"

# Test E6: Create all 15 weeks for a full semester
test_e2e_full_semester() {
    local proj=$(setup_fresh_course)
    cd "$proj"

    local styles=("conceptual" "computational" "applied" "rigorous")
    local failed=0

    for ((w=1; w<=15; w++)); do
        local style_idx=$(( (w - 1) % 4 + 1 ))
        local style="${styles[$style_idx]}"
        _teach_plan_create "$w" --style "$style" <<< $'\n\n' &>/dev/null
        if [[ $? -ne 0 ]]; then
            ((failed++))
        fi
    done

    if ! yq eval '.' .flow/lesson-plans.yml &>/dev/null; then
        test_fail "Full semester" "YAML corrupted after 15 creates"
        return
    fi

    local count
    count=$(yq '.weeks | length' .flow/lesson-plans.yml 2>/dev/null)
    if [[ "$count" == "15" && $failed -eq 0 ]]; then
        test_pass "Full semester: 15 weeks created with auto-populated topics"
    else
        test_fail "Full semester" "count=$count failed=$failed"
    fi
}
test_e2e_full_semester

# Test E7: Weeks are sorted after bulk creation
test_e2e_sorted_after_bulk() {
    local proj=$(setup_fresh_course)
    cd "$proj"

    # Create in reverse order
    for w in 5 3 1 4 2; do
        _teach_plan_create "$w" --style "conceptual" <<< $'\n\n' &>/dev/null
    done

    # Check ordering
    local sorted_ok=1
    local prev=0
    for ((i=0; i<5; i++)); do
        local num
        num=$(yq ".weeks[$i].number" .flow/lesson-plans.yml 2>/dev/null)
        if [[ "$num" -le "$prev" ]]; then
            sorted_ok=0
            break
        fi
        prev="$num"
    done

    if [[ $sorted_ok -eq 1 ]]; then
        test_pass "Weeks sorted correctly after out-of-order creation"
    else
        test_fail "Sort order" "weeks not in ascending order"
    fi
}
test_e2e_sorted_after_bulk

echo ""

# ============================================================================
# E2E WORKFLOW 4: JSON Output Integration
# ============================================================================

echo "━━━ E2E 4: JSON Output ━━━"

# Test E8: List JSON is valid and parseable
test_e2e_list_json_valid() {
    local proj=$(setup_fresh_course)
    cd "$proj"

    _teach_plan_create 1 --topic "Regression" --style "conceptual" <<< $'\n\n' &>/dev/null
    _teach_plan_create 2 --topic "Diagnostics" --style "applied" <<< $'\n\n' &>/dev/null

    local json_output
    json_output=$(_teach_plan_list --json 2>&1)

    # Validate it's parseable JSON
    if echo "$json_output" | yq -o=json '.' &>/dev/null; then
        local json_count
        json_count=$(echo "$json_output" | yq '. | length' 2>/dev/null)
        if [[ "$json_count" == "2" ]]; then
            test_pass "List --json produces valid JSON with correct count"
        else
            test_fail "List JSON count" "count=$json_count, expected 2"
        fi
    else
        test_fail "List JSON" "output is not valid JSON"
    fi
}
test_e2e_list_json_valid

# Test E9: Show JSON contains all fields
test_e2e_show_json_fields() {
    local proj=$(setup_fresh_course)
    cd "$proj"

    _teach_plan_create 3 --topic "Model Diagnostics" --style "rigorous" <<< $'Residual analysis, Influence measures\nCooks distance, Leverage\n' &>/dev/null

    local json_output
    json_output=$(_teach_plan_show 3 --json 2>&1)

    local has_number=0 has_topic=0 has_style=0 has_objectives=0
    echo "$json_output" | grep -q '"number"' && has_number=1
    echo "$json_output" | grep -q '"topic"' && has_topic=1
    echo "$json_output" | grep -q '"style"' && has_style=1
    echo "$json_output" | grep -q '"objectives"' && has_objectives=1

    if [[ $has_number -eq 1 && $has_topic -eq 1 && $has_style -eq 1 && $has_objectives -eq 1 ]]; then
        test_pass "Show --json contains all expected fields"
    else
        test_fail "Show JSON fields" "number=$has_number topic=$has_topic style=$has_style obj=$has_objectives"
    fi
}
test_e2e_show_json_fields

# Test E10: Empty list JSON returns empty array
test_e2e_empty_json() {
    local proj=$(setup_fresh_course)
    cd "$proj"

    # Create empty plans file
    echo "weeks: []" > .flow/lesson-plans.yml

    local json_output
    json_output=$(_teach_plan_list --json 2>&1)

    if [[ "$json_output" == "[]" ]]; then
        test_pass "Empty list --json returns []"
    else
        test_fail "Empty JSON" "output='$json_output'"
    fi
}
test_e2e_empty_json

echo ""

# ============================================================================
# E2E WORKFLOW 5: Delete Patterns
# ============================================================================

echo "━━━ E2E 5: Delete Patterns ━━━"

# Test E11: Delete middle week keeps others intact
test_e2e_delete_middle() {
    local proj=$(setup_fresh_course)
    cd "$proj"

    _teach_plan_create 1 --topic "Week One" --style "conceptual" <<< $'\n\n' &>/dev/null
    _teach_plan_create 2 --topic "Week Two" --style "applied" <<< $'\n\n' &>/dev/null
    _teach_plan_create 3 --topic "Week Three" --style "rigorous" <<< $'\n\n' &>/dev/null

    # Delete middle
    _teach_plan_delete 2 --force &>/dev/null

    local count
    count=$(yq '.weeks | length' .flow/lesson-plans.yml 2>/dev/null)
    local w1_ok=0 w3_ok=0
    yq '.weeks[] | select(.number == 1) | .topic' .flow/lesson-plans.yml 2>/dev/null | grep -q "Week One" && w1_ok=1
    yq '.weeks[] | select(.number == 3) | .topic' .flow/lesson-plans.yml 2>/dev/null | grep -q "Week Three" && w3_ok=1

    if [[ "$count" == "2" && $w1_ok -eq 1 && $w3_ok -eq 1 ]]; then
        test_pass "Delete middle week preserves others"
    else
        test_fail "Delete middle" "count=$count w1=$w1_ok w3=$w3_ok"
    fi
}
test_e2e_delete_middle

# Test E12: Delete all weeks leaves valid empty file
test_e2e_delete_all() {
    local proj=$(setup_fresh_course)
    cd "$proj"

    _teach_plan_create 1 --topic "Only Week" --style "conceptual" <<< $'\n\n' &>/dev/null
    _teach_plan_delete 1 --force &>/dev/null

    if ! yq eval '.' .flow/lesson-plans.yml &>/dev/null; then
        test_fail "Delete all" "file corrupted after deleting all weeks"
        return
    fi

    local count
    count=$(yq '.weeks | length' .flow/lesson-plans.yml 2>/dev/null)
    if [[ "$count" == "0" ]]; then
        test_pass "Delete all weeks leaves valid empty file"
    else
        test_fail "Delete all" "count=$count, expected 0"
    fi
}
test_e2e_delete_all

echo ""

# ============================================================================
# E2E WORKFLOW 6: Dispatcher Integration
# ============================================================================

echo "━━━ E2E 6: Dispatcher Integration ━━━"

# Test E13: Bare number shows week details
test_e2e_bare_number() {
    local proj=$(setup_fresh_course)
    cd "$proj"

    _teach_plan_create 8 --topic "Model Selection" --style "computational" <<< $'\n\n' &>/dev/null

    local output
    output=$(_teach_plan 8 2>&1)

    if echo "$output" | grep -q "Model Selection" && echo "$output" | grep -q "Week 8"; then
        test_pass "Bare number dispatches to show"
    else
        test_fail "Bare number" "missing expected content"
    fi
}
test_e2e_bare_number

# Test E14: All action aliases work
test_e2e_aliases() {
    local proj=$(setup_fresh_course)
    cd "$proj"

    _teach_plan_create 1 --topic "Test" --style "conceptual" <<< $'\n\n' &>/dev/null

    local ls_ok=0 s_ok=0 l_ok=0
    _teach_plan ls 2>&1 | grep -q "Test" && ls_ok=1
    _teach_plan s 1 2>&1 | grep -q "Week 1" && s_ok=1
    _teach_plan l 2>&1 | grep -q "1 week" && l_ok=1

    if [[ $ls_ok -eq 1 && $s_ok -eq 1 && $l_ok -eq 1 ]]; then
        test_pass "Action aliases: ls, s, l all work"
    else
        test_fail "Aliases" "ls=$ls_ok s=$s_ok l=$l_ok"
    fi
}
test_e2e_aliases

# Test E15: Unknown action shows error
test_e2e_unknown_action() {
    local proj=$(setup_fresh_course)
    cd "$proj"

    local output
    output=$(_teach_plan foobar 2>&1)
    local rc=$?

    if [[ $rc -ne 0 ]]; then
        test_pass "Unknown action returns error"
    else
        test_fail "Unknown action" "should fail for 'foobar'"
    fi
}
test_e2e_unknown_action

echo ""

# ============================================================================
# SUMMARY
# ============================================================================

cd "$ORIGINAL_DIR"
echo ""
test_summary
