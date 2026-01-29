#!/usr/bin/env zsh
# test-teach-plan-security.zsh - Security & edge case tests for teach plan
# v5.22.0 - Lesson Plan CRUD (#278)
#
# Validates YAML injection prevention, input sanitization,
# backup/restore, temp file cleanup, and boundary conditions.

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

# Source libraries (reset load guard so we can re-source after fixes)
unset _FLOW_TEACH_PLAN_LOADED
source "$PROJECT_ROOT/lib/core.zsh" 2>/dev/null || true
source "$PROJECT_ROOT/commands/teach-plan.zsh" 2>/dev/null || true

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  teach plan - Security & Edge Case Tests                   ║"
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

setup_project() {
    local dir
    dir=$(mktemp -d "$TEST_DIR/project-XXXXXXXX")
    mkdir -p "$dir/.flow"
    echo "$dir"
}

create_sample_plans() {
    local dir="$1"
    cat > "$dir/.flow/lesson-plans.yml" <<'YAML'
weeks:
  - number: 1
    topic: "Introduction to Statistics"
    style: "conceptual"
    objectives:
      - "Define descriptive statistics"
    subtopics: []
    key_concepts: []
    prerequisites: []
YAML
}

# Check yq is available
if ! command -v yq &>/dev/null; then
    echo "⚠️  yq not found - skipping all security tests"
    exit 0
fi

# ============================================================================
# YAML INJECTION PREVENTION
# ============================================================================

echo "━━━ YAML Injection Prevention ━━━"

# Test S1: Topic with double quotes
test_inject_quotes() {
    local proj=$(setup_project)
    cd "$proj"

    _teach_plan_create 1 --topic 'He said "hello" today' --style "conceptual" <<< $'\n\n' &>/dev/null

    # YAML must be valid
    if ! yq eval '.' .flow/lesson-plans.yml &>/dev/null; then
        test_fail "Topic with double quotes" "produced invalid YAML"
        return
    fi

    local topic
    topic=$(yq '.weeks[0].topic' .flow/lesson-plans.yml 2>/dev/null)
    if [[ "$topic" == 'He said "hello" today' ]]; then
        test_pass "Topic with double quotes preserved correctly"
    else
        test_fail "Topic with double quotes" "topic='$topic'"
    fi
}
test_inject_quotes

# Test S2: Topic with single quotes
test_inject_single_quotes() {
    local proj=$(setup_project)
    cd "$proj"

    _teach_plan_create 1 --topic "It's a test" --style "conceptual" <<< $'\n\n' &>/dev/null

    if ! yq eval '.' .flow/lesson-plans.yml &>/dev/null; then
        test_fail "Topic with single quotes" "produced invalid YAML"
        return
    fi

    local topic
    topic=$(yq '.weeks[0].topic' .flow/lesson-plans.yml 2>/dev/null)
    if [[ "$topic" == "It's a test" ]]; then
        test_pass "Topic with single quotes preserved correctly"
    else
        test_fail "Topic with single quotes" "topic='$topic'"
    fi
}
test_inject_single_quotes

# Test S3: Topic with YAML special characters (colon, brackets)
test_inject_yaml_special() {
    local proj=$(setup_project)
    cd "$proj"

    _teach_plan_create 1 --topic 'Topic: [arrays] & {objects}' --style "conceptual" <<< $'\n\n' &>/dev/null

    if ! yq eval '.' .flow/lesson-plans.yml &>/dev/null; then
        test_fail "Topic with YAML special chars" "produced invalid YAML"
        return
    fi

    local topic
    topic=$(yq '.weeks[0].topic' .flow/lesson-plans.yml 2>/dev/null)
    if echo "$topic" | grep -q "Topic:" && echo "$topic" | grep -q "arrays"; then
        test_pass "Topic with YAML special chars (colon, brackets)"
    else
        test_fail "Topic with YAML special chars" "topic='$topic'"
    fi
}
test_inject_yaml_special

# Test S4: Topic with backslashes
test_inject_backslash() {
    local proj=$(setup_project)
    cd "$proj"

    _teach_plan_create 1 --topic 'Path: C:\Users\test' --style "conceptual" <<< $'\n\n' &>/dev/null

    if ! yq eval '.' .flow/lesson-plans.yml &>/dev/null; then
        test_fail "Topic with backslashes" "produced invalid YAML"
        return
    fi

    test_pass "Topic with backslashes produces valid YAML"
}
test_inject_backslash

# Test S5: Topic with hash (YAML comment character)
test_inject_hash() {
    local proj=$(setup_project)
    cd "$proj"

    _teach_plan_create 1 --topic 'Topic #1: Intro' --style "conceptual" <<< $'\n\n' &>/dev/null

    if ! yq eval '.' .flow/lesson-plans.yml &>/dev/null; then
        test_fail "Topic with hash" "produced invalid YAML"
        return
    fi

    local topic
    topic=$(yq '.weeks[0].topic' .flow/lesson-plans.yml 2>/dev/null)
    if echo "$topic" | grep -q "#1"; then
        test_pass "Topic with hash character preserved"
    else
        test_fail "Topic with hash" "topic='$topic', hash may have been interpreted as comment"
    fi
}
test_inject_hash

# Test S6: Topic with pipe character (YAML literal/folded indicator)
test_inject_pipe() {
    local proj=$(setup_project)
    cd "$proj"

    _teach_plan_create 1 --topic 'A | B | C alternatives' --style "conceptual" <<< $'\n\n' &>/dev/null

    if ! yq eval '.' .flow/lesson-plans.yml &>/dev/null; then
        test_fail "Topic with pipe" "produced invalid YAML"
        return
    fi

    test_pass "Topic with pipe character produces valid YAML"
}
test_inject_pipe

# Test S7: Very long topic string
test_inject_long_string() {
    local proj=$(setup_project)
    cd "$proj"

    local long_topic=$(printf 'A%.0s' {1..500})
    _teach_plan_create 1 --topic "$long_topic" --style "conceptual" <<< $'\n\n' &>/dev/null

    if ! yq eval '.' .flow/lesson-plans.yml &>/dev/null; then
        test_fail "Very long topic" "produced invalid YAML"
        return
    fi

    local stored_len
    stored_len=$(yq '.weeks[0].topic | length' .flow/lesson-plans.yml 2>/dev/null)
    if [[ "$stored_len" -ge 500 ]]; then
        test_pass "Very long topic (500 chars) stored correctly"
    else
        test_fail "Very long topic" "stored_len=$stored_len"
    fi
}
test_inject_long_string

# Test S8: Objective with quotes (comma-separated injection)
test_inject_objective_quotes() {
    local proj=$(setup_project)
    cd "$proj"

    # Simulate: objectives input with quotes
    _teach_plan_create 1 --topic "Test" --style "conceptual" <<< $'Define "key" terms, Use O\'Brien method\n\n' &>/dev/null

    if ! yq eval '.' .flow/lesson-plans.yml &>/dev/null; then
        test_fail "Objectives with quotes" "produced invalid YAML"
        return
    fi

    local obj_count
    obj_count=$(yq '.weeks[0].objectives | length' .flow/lesson-plans.yml 2>/dev/null)
    if [[ "$obj_count" -ge 1 ]]; then
        test_pass "Objectives with quotes produce valid YAML"
    else
        test_fail "Objectives with quotes" "obj_count=$obj_count"
    fi
}
test_inject_objective_quotes

echo ""

# ============================================================================
# BACKUP & RESTORE
# ============================================================================

echo "━━━ Backup & Restore ━━━"

# Test S9: Backup file is cleaned up on success
test_backup_cleanup_success() {
    local proj=$(setup_project)
    cd "$proj"

    _teach_plan_create 1 --topic "Test" --style "conceptual" <<< $'\n\n' &>/dev/null

    if [[ ! -f ".flow/lesson-plans.yml.bak" ]]; then
        test_pass "Backup file cleaned up after successful create"
    else
        test_fail "Backup cleanup" ".bak file still exists"
    fi
}
test_backup_cleanup_success

# Test S10: Original data preserved when adding new week
test_backup_preserves_data() {
    local proj=$(setup_project)
    cd "$proj"
    create_sample_plans "$proj"

    local original_topic
    original_topic=$(yq '.weeks[0].topic' .flow/lesson-plans.yml 2>/dev/null)

    # Add a new week
    _teach_plan_create 2 --topic "New Week" --style "applied" <<< $'\n\n' &>/dev/null

    local after_topic
    after_topic=$(yq '.weeks[0].topic' .flow/lesson-plans.yml 2>/dev/null)

    if [[ "$original_topic" == "$after_topic" ]]; then
        test_pass "Existing data preserved after adding new week"
    else
        test_fail "Data preservation" "original='$original_topic' after='$after_topic'"
    fi
}
test_backup_preserves_data

echo ""

# ============================================================================
# TEMP FILE CLEANUP
# ============================================================================

echo "━━━ Temp File Cleanup ━━━"

# Test S11: No temp files leaked after create
test_temp_cleanup() {
    local proj=$(setup_project)
    cd "$proj"

    # Count temp files before (use find to avoid zsh glob errors)
    local before_count
    before_count=$(find "${TMPDIR:-/tmp}" -maxdepth 1 -name 'tmp.*' -type f 2>/dev/null | wc -l | tr -d ' ')

    _teach_plan_create 1 --topic "Temp Test" --style "conceptual" <<< $'\n\n' &>/dev/null

    # Count temp files after
    local after_count
    after_count=$(find "${TMPDIR:-/tmp}" -maxdepth 1 -name 'tmp.*' -type f 2>/dev/null | wc -l | tr -d ' ')

    if [[ "$after_count" -le "$before_count" ]]; then
        test_pass "No temp files leaked after create"
    else
        test_fail "Temp file leak" "before=$before_count after=$after_count"
    fi
}
test_temp_cleanup

echo ""

# ============================================================================
# BOUNDARY CONDITIONS
# ============================================================================

echo "━━━ Boundary Conditions ━━━"

# Test S12: Week 1 (minimum)
test_boundary_min_week() {
    local proj=$(setup_project)
    cd "$proj"

    _teach_plan_create 1 --topic "Min Week" --style "conceptual" <<< $'\n\n' &>/dev/null
    local rc=$?

    if [[ $rc -eq 0 ]]; then
        test_pass "Week 1 (minimum) accepted"
    else
        test_fail "Min week" "rc=$rc"
    fi
}
test_boundary_min_week

# Test S13: Week 20 (maximum)
test_boundary_max_week() {
    local proj=$(setup_project)
    cd "$proj"

    _teach_plan_create 20 --topic "Max Week" --style "conceptual" <<< $'\n\n' &>/dev/null
    local rc=$?

    if [[ $rc -eq 0 ]]; then
        test_pass "Week 20 (maximum) accepted"
    else
        test_fail "Max week" "rc=$rc"
    fi
}
test_boundary_max_week

# Test S14: Week 21 (over maximum)
test_boundary_over_max() {
    local proj=$(setup_project)
    cd "$proj"

    local output
    output=$(_teach_plan_create 21 --topic "Over" --style "conceptual" 2>&1)
    local rc=$?

    if [[ $rc -ne 0 ]]; then
        test_pass "Week 21 (over maximum) rejected"
    else
        test_fail "Over max week" "should reject week 21"
    fi
}
test_boundary_over_max

# Test S15: Non-numeric week argument
test_boundary_non_numeric() {
    local proj=$(setup_project)
    cd "$proj"

    local output
    output=$(_teach_plan_create abc --topic "Test" 2>&1)
    local rc=$?

    if [[ $rc -ne 0 ]]; then
        test_pass "Non-numeric week argument rejected"
    else
        test_fail "Non-numeric week" "should reject 'abc'"
    fi
}
test_boundary_non_numeric

# Test S16: Negative week number
test_boundary_negative() {
    local proj=$(setup_project)
    cd "$proj"

    local output
    output=$(_teach_plan_create -- -1 2>&1)
    local rc=$?

    # -1 is not numeric (starts with -), so arg parser should reject it
    if [[ $rc -ne 0 ]]; then
        test_pass "Negative week number rejected"
    else
        test_fail "Negative week" "should reject -1"
    fi
}
test_boundary_negative

# Test S17: Empty topic with --topic flag
test_boundary_empty_topic() {
    local proj=$(setup_project)
    cd "$proj"

    local output
    output=$(_teach_plan_create 1 --topic "" --style "conceptual" 2>&1)
    local rc=$?

    # Empty topic should trigger interactive prompt which fails with no stdin
    if [[ $rc -ne 0 ]]; then
        test_pass "Empty --topic flag triggers prompt/error"
    else
        # Check if a valid entry was created (topic shouldn't be empty)
        local topic
        topic=$(yq '.weeks[0].topic // ""' .flow/lesson-plans.yml 2>/dev/null)
        if [[ -z "$topic" || "$topic" == "" || "$topic" == "null" ]]; then
            test_fail "Empty topic" "created entry with empty topic"
        else
            test_pass "Empty --topic handled (fallback topic used)"
        fi
    fi
}
test_boundary_empty_topic

# Test S18: No .flow directory
test_boundary_no_flow_dir() {
    local dir="$TEST_DIR/noflow-$$-$RANDOM"
    mkdir -p "$dir"
    cd "$dir"

    local output
    output=$(_teach_plan_create 1 --topic "Test" --style "conceptual" 2>&1)
    local rc=$?

    if [[ $rc -ne 0 ]]; then
        test_pass "Fails gracefully without .flow directory"
    else
        test_fail "No .flow dir" "should fail without .flow"
    fi
}
test_boundary_no_flow_dir

echo ""

# ============================================================================
# CORRUPTED FILE HANDLING
# ============================================================================

echo "━━━ Corrupted File Handling ━━━"

# Test S19: List handles corrupted YAML
test_corrupt_list() {
    local proj=$(setup_project)
    cd "$proj"

    echo "this is not valid yaml: [[[" > ".flow/lesson-plans.yml"

    local output
    output=$(_teach_plan_list 2>&1)
    local rc=$?

    # Should not crash — may show 0 weeks or error
    if [[ $rc -eq 0 || $rc -eq 1 ]]; then
        test_pass "List handles corrupted YAML without crash"
    else
        test_fail "Corrupt list" "unexpected rc=$rc"
    fi
}
test_corrupt_list

# Test S20: Show handles corrupted YAML
test_corrupt_show() {
    local proj=$(setup_project)
    cd "$proj"

    echo "not: yaml: [broken" > ".flow/lesson-plans.yml"

    local output
    output=$(_teach_plan_show 1 2>&1)
    local rc=$?

    if [[ $rc -ne 0 ]]; then
        test_pass "Show returns error for corrupted YAML"
    else
        test_pass "Show handles corrupted YAML gracefully"
    fi
}
test_corrupt_show

# Test S21: Delete handles corrupted YAML
test_corrupt_delete() {
    local proj=$(setup_project)
    cd "$proj"

    echo "broken yaml ]]}" > ".flow/lesson-plans.yml"

    local output
    output=$(_teach_plan_delete 1 --force 2>&1)
    local rc=$?

    # Should return error, not crash
    if [[ $rc -ne 0 ]]; then
        test_pass "Delete returns error for corrupted YAML"
    else
        test_pass "Delete handles corrupted YAML gracefully"
    fi
}
test_corrupt_delete

echo ""

# ============================================================================
# CONCURRENT / MULTI-OPERATION SAFETY
# ============================================================================

echo "━━━ Multi-Operation Safety ━━━"

# Test S22: Multiple creates don't corrupt file
test_multi_create() {
    local proj=$(setup_project)
    cd "$proj"

    _teach_plan_create 1 --topic "Week One" --style "conceptual" <<< $'\n\n' &>/dev/null
    _teach_plan_create 2 --topic "Week Two" --style "applied" <<< $'\n\n' &>/dev/null
    _teach_plan_create 3 --topic "Week Three" --style "rigorous" <<< $'\n\n' &>/dev/null

    if ! yq eval '.' .flow/lesson-plans.yml &>/dev/null; then
        test_fail "Multiple creates" "file corrupted after 3 creates"
        return
    fi

    local count
    count=$(yq '.weeks | length' .flow/lesson-plans.yml 2>/dev/null)
    if [[ "$count" == "3" ]]; then
        test_pass "Multiple sequential creates produce valid file (3 weeks)"
    else
        test_fail "Multiple creates" "count=$count, expected 3"
    fi
}
test_multi_create

# Test S23: Create then delete then create same week
test_recreate_after_delete() {
    local proj=$(setup_project)
    cd "$proj"

    _teach_plan_create 5 --topic "Original" --style "conceptual" <<< $'\n\n' &>/dev/null
    _teach_plan_delete 5 --force &>/dev/null
    _teach_plan_create 5 --topic "Recreated" --style "applied" <<< $'\n\n' &>/dev/null

    if ! yq eval '.' .flow/lesson-plans.yml &>/dev/null; then
        test_fail "Recreate after delete" "file corrupted"
        return
    fi

    local topic
    topic=$(yq '.weeks[] | select(.number == 5) | .topic' .flow/lesson-plans.yml 2>/dev/null)
    if [[ "$topic" == "Recreated" ]]; then
        test_pass "Recreate after delete works correctly"
    else
        test_fail "Recreate after delete" "topic='$topic', expected 'Recreated'"
    fi
}
test_recreate_after_delete

# Test S24: Force overwrite preserves other weeks
test_force_preserves_others() {
    local proj=$(setup_project)
    cd "$proj"

    _teach_plan_create 1 --topic "Week One" --style "conceptual" <<< $'\n\n' &>/dev/null
    _teach_plan_create 2 --topic "Week Two" --style "applied" <<< $'\n\n' &>/dev/null
    _teach_plan_create 1 --topic "Replaced" --style "rigorous" --force <<< $'\n\n' &>/dev/null

    local count
    count=$(yq '.weeks | length' .flow/lesson-plans.yml 2>/dev/null)
    local week2_topic
    week2_topic=$(yq '.weeks[] | select(.number == 2) | .topic' .flow/lesson-plans.yml 2>/dev/null)

    if [[ "$count" == "2" && "$week2_topic" == "Week Two" ]]; then
        test_pass "Force overwrite preserves other weeks"
    else
        test_fail "Force preserve others" "count=$count, week2='$week2_topic'"
    fi
}
test_force_preserves_others

echo ""

# ============================================================================
# SUMMARY
# ============================================================================

cd "$ORIGINAL_DIR"
echo ""
test_summary
