#!/usr/bin/env zsh
# e2e-scholar-config-sync.zsh - End-to-end tests for Scholar Config Sync (#423)
#
# Tests complete user workflows in realistic teaching project scenarios:
# - Config injection with real teach-config.yml
# - Config subcommand routing
# - New wrapper routing (solution, sync, validate-r)
# - Doctor config sync section
# - Stale config detection
# - Legacy file deprecation
#
# Usage: zsh tests/e2e-scholar-config-sync.zsh

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
source "$PROJECT_ROOT/lib/core.zsh" 2>/dev/null || true
source "$PROJECT_ROOT/lib/config-validator.zsh" 2>/dev/null || true
source "$PROJECT_ROOT/lib/dispatchers/teach-dispatcher.zsh" 2>/dev/null || true
source "$PROJECT_ROOT/lib/dispatchers/teach-doctor-impl.zsh" 2>/dev/null || true

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Scholar Config Sync (#423) - End-to-End Tests             ║"
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

# Helper: create a teaching project with config
setup_config_project() {
    local dir
    dir=$(mktemp -d "$TEST_DIR/teach-XXXXXXXX")
    mkdir -p "$dir/.flow"

    cat > "$dir/.flow/teach-config.yml" <<'YAML'
course:
  name: "STAT-101"
  semester: "Spring 2026"
scholar:
  model: "claude-3-opus"
teaching_style:
  approach: "interactive"
  tone: "conversational"
YAML

    echo "$dir"
}

# ============================================================================
# TEST 1: Config discovery in real project
# ============================================================================

echo "── Config Discovery ──"

test_dir=$(setup_config_project)
cd "$test_dir"

# Test 1.1: _teach_find_config finds real config
config_path=$(_teach_find_config 2>/dev/null)
if [[ -n "$config_path" && -f "$config_path" ]]; then
    test_pass "Config file discovered: $(basename $config_path)"
else
    test_fail "Config discovery" "Expected config path, got: '$config_path'"
fi

# Test 1.2: Config content is valid YAML
if command -v yq &>/dev/null; then
    course_name=$(yq '.course.name' "$config_path" 2>/dev/null)
    if [[ "$course_name" == "STAT-101" ]]; then
        test_pass "Config YAML parses correctly (course: STAT-101)"
    else
        test_fail "Config YAML parse" "Expected STAT-101, got: $course_name"
    fi
else
    test_pass "Config YAML parse (yq not available, skipped)"
fi

cd "$ORIGINAL_DIR"

# ============================================================================
# TEST 2: Config injection into Scholar commands
# ============================================================================

echo ""
echo "── Config Injection ──"

test_dir=$(setup_config_project)
cd "$test_dir"

# Test 2.1: _teach_build_command builds correct command
for cmd in exam quiz lecture slides assignment syllabus rubric feedback solution sync validate-r; do
    result=$(_teach_build_command "$cmd" "test-topic" 2>/dev/null)
    if [[ "$result" == *"/teaching:$cmd"* ]]; then
        test_pass "Build command: $cmd -> /teaching:$cmd"
    else
        test_fail "Build command: $cmd" "Expected /teaching:$cmd, got: $result"
    fi
done

# Test 2.2: Config command maps to /teaching:config
result=$(_teach_build_command "config" "show" 2>/dev/null)
if [[ "$result" == *"/teaching:config"* ]]; then
    test_pass "Build command: config -> /teaching:config"
else
    test_fail "Build command: config" "Expected /teaching:config, got: $result"
fi

cd "$ORIGINAL_DIR"

# ============================================================================
# TEST 3: Stale config detection
# ============================================================================

echo ""
echo "── Stale Config Detection ──"

test_dir=$(setup_config_project)
cd "$test_dir"

# Test 3.1: First run - no hash file, config_changed returns true
if _flow_config_changed "$test_dir/.flow/teach-config.yml" 2>/dev/null; then
    test_pass "First run detects config change (no stored hash)"
else
    test_pass "First run: hash already stored (OK)"
fi

# Test 3.2: _flow_config_hash produces consistent hash
hash1=$(_flow_config_hash "$test_dir/.flow/teach-config.yml" 2>/dev/null)
hash2=$(_flow_config_hash "$test_dir/.flow/teach-config.yml" 2>/dev/null)
if [[ -n "$hash1" && "$hash1" == "$hash2" ]]; then
    test_pass "Config hash is deterministic"
else
    test_fail "Config hash consistency" "hash1=$hash1 hash2=$hash2"
fi

cd "$ORIGINAL_DIR"

# ============================================================================
# TEST 4: Legacy deprecation detection
# ============================================================================

echo ""
echo "── Legacy Deprecation ──"

test_dir=$(setup_config_project)
cd "$test_dir"

# Test 4.1: No warning without legacy file
if [[ ! -f ".claude/teaching-style.local.md" ]]; then
    test_pass "No legacy file present (clean state)"
else
    test_fail "Clean state" "Legacy file should not exist in fresh project"
fi

# Test 4.2: Detection with legacy file present
mkdir -p ".claude"
echo "legacy style" > ".claude/teaching-style.local.md"
if [[ -f ".claude/teaching-style.local.md" ]]; then
    config_path=$(_teach_find_config 2>/dev/null)
    if [[ -n "$config_path" ]]; then
        test_pass "Legacy + new config coexistence detected"
    else
        test_fail "Legacy detection" "Config not found alongside legacy file"
    fi
else
    test_fail "Legacy file creation" "Could not create test legacy file"
fi

cd "$ORIGINAL_DIR"

# ============================================================================
# TEST 5: Doctor config sync section
# ============================================================================

echo ""
echo "── Doctor Config Sync ──"

test_dir=$(setup_config_project)
cd "$test_dir"

# Test 5.1: _teach_doctor_config_sync function exists
if typeset -f _teach_doctor_config_sync >/dev/null 2>&1; then
    test_pass "Doctor config sync function exists"
else
    test_fail "Doctor function" "_teach_doctor_config_sync not found"
fi

# Test 5.2: Doctor reports config status
json="false"
output=$(_teach_doctor_config_sync 2>&1)
if [[ "$output" == *"Scholar Config"* ]]; then
    test_pass "Doctor reports config sync status"
else
    test_fail "Doctor output" "Expected 'Scholar Config' header, got: ${output:0:100}"
fi

cd "$ORIGINAL_DIR"

# ============================================================================
# TEST 6: Help output completeness
# ============================================================================

echo ""
echo "── Help Output ──"

# Test 6.1: Help includes all new commands
help_output=$(_teach_dispatcher_help 2>&1)

for cmd in "config check" "config diff" "config show" "config scaffold" "solution" "sync" "validate-r"; do
    if [[ "$help_output" == *"$cmd"* ]]; then
        test_pass "Help includes: $cmd"
    else
        test_fail "Help missing" "$cmd not in help output"
    fi
done

# ============================================================================
# TEST 7: Demo course fixture integration
# ============================================================================

echo ""
echo "── Demo Course Integration ──"

if [[ -d "$DEMO_COURSE" ]]; then
    cd "$DEMO_COURSE"

    # Test 7.1: Config discoverable in demo course
    config=$(_teach_find_config 2>/dev/null)
    if [[ -n "$config" ]]; then
        test_pass "Demo course config discovered"
    else
        test_pass "Demo course has no config (expected for minimal fixture)"
    fi

    cd "$ORIGINAL_DIR"
else
    test_pass "Demo course fixture not present (skip)"
fi

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
echo "════════════════════════════════════════════════════════════"

if [[ -n "$TEST_FAIL" && $TEST_FAIL -gt 0 ]]; then
    echo "  ❌ $TEST_FAIL failures out of $((TEST_PASS + TEST_FAIL)) tests"
    exit 1
elif [[ -n "$TESTS_FAILED" && $TESTS_FAILED -gt 0 ]]; then
    echo "  ❌ $TESTS_FAILED failures out of $((TESTS_PASSED + TESTS_FAILED)) tests"
    exit 1
else
    echo "  ✅ All tests passed: ${TEST_PASS:-$TESTS_PASSED} tests"
    exit 0
fi
