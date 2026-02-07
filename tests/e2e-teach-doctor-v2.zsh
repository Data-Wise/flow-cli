#!/usr/bin/env zsh
# e2e-teach-doctor-v2.zsh - End-to-end tests for teach doctor v2
# v6.5.0 - Two-mode architecture, renv awareness, CI mode, health indicator
#
# Tests complete user workflows in realistic teaching project scenarios.
# Uses the demo course fixture and temp directories for isolation.

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
source "$PROJECT_ROOT/lib/core.zsh" 2>/dev/null || true
source "$PROJECT_ROOT/lib/r-helpers.zsh" 2>/dev/null || true
source "$PROJECT_ROOT/lib/renv-integration.zsh" 2>/dev/null || true
source "$PROJECT_ROOT/lib/dispatchers/teach-doctor-impl.zsh" 2>/dev/null || true

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  teach doctor v2 - End-to-End Tests                        ║"
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

# Helper: create a minimal teaching project in temp dir
setup_teaching_project() {
    local dir
    dir=$(mktemp -d "$TEST_DIR/teach-XXXXXXXX")
    mkdir -p "$dir/.flow"
    git init "$dir" >/dev/null 2>&1  # real git repo for git checks

    cat > "$dir/.flow/teach-config.yml" <<'YAML'
course:
  name: "STAT-101"
  semester: "Spring 2026"
semester_info:
  start_date: "2026-01-12"
  end_date: "2026-05-01"
  total_weeks: 15
YAML

    echo "$dir"
}

# Helper: create project with renv setup
setup_renv_project() {
    local dir
    dir=$(setup_teaching_project)

    # Create renv.lock with some packages
    cat > "$dir/renv.lock" <<'JSON'
{
  "R": {"Version": "4.4.2"},
  "Packages": {
    "ggplot2": {"Package": "ggplot2", "Version": "3.5.1"},
    "dplyr": {"Package": "dplyr", "Version": "1.1.4"},
    "tidyr": {"Package": "tidyr", "Version": "1.3.1"}
  }
}
JSON

    mkdir -p "$dir/renv"
    echo '# renv activate' > "$dir/renv/activate.R"

    echo "$dir"
}

# Helper: create project with Quarto extensions
setup_quarto_project() {
    local dir
    dir=$(setup_teaching_project)

    # Create extension directories (org/ext-name pattern)
    mkdir -p "$dir/_extensions/quarto-ext/fontawesome"
    mkdir -p "$dir/_extensions/quarto-ext/include-code-files"
    mkdir -p "$dir/_extensions/shafayetShafee/line-highlight"

    echo "$dir"
}

# ============================================================================
# E2E WORKFLOW 1: Quick Mode (Default)
# ============================================================================

echo "━━━ E2E 1: Quick Mode (Default) ━━━"

# Test E1: Quick mode runs and produces output
test_e2e_quick_mode_output() {
    local proj=$(setup_teaching_project)
    cd "$proj"

    local output
    output=$(_teach_doctor 2>&1)
    local rc=$?

    local has_header=0 has_deps=0 has_config=0
    echo "$output" | grep -q "quick check" && has_header=1
    echo "$output" | grep -q "Dependencies:" && has_deps=1
    echo "$output" | grep -q "Configuration:" && has_config=1

    if [[ $has_header -eq 1 && $has_deps -eq 1 ]]; then
        test_pass "Quick mode: produces header and dependency output"
    else
        test_fail "Quick mode output" "header=$has_header deps=$has_deps config=$has_config"
    fi
}
test_e2e_quick_mode_output

# Test E2: Quick mode shows skip hint
test_e2e_quick_mode_skip_hint() {
    local proj=$(setup_teaching_project)
    cd "$proj"

    local output
    output=$(_teach_doctor 2>&1)

    if echo "$output" | grep -q "run --full"; then
        test_pass "Quick mode: shows --full skip hint"
    else
        test_fail "Quick mode skip hint" "missing --full hint"
    fi
}
test_e2e_quick_mode_skip_hint

# Test E3: Quick mode returns 0 when dependencies are met
test_e2e_quick_mode_exit_code() {
    local proj=$(setup_teaching_project)
    cd "$proj"

    _teach_doctor >/dev/null 2>&1
    local rc=$?

    # Should pass if yq, git, quarto, gh are installed
    if command -v yq &>/dev/null && command -v git &>/dev/null && command -v quarto &>/dev/null && command -v gh &>/dev/null; then
        if [[ $rc -eq 0 ]]; then
            test_pass "Quick mode: exit code 0 when deps met"
        else
            test_fail "Quick mode exit code" "rc=$rc, expected 0"
        fi
    else
        # Some deps missing, just skip
        test_pass "Quick mode: exit code test skipped (deps not all installed)"
    fi
}
test_e2e_quick_mode_exit_code

echo ""

# ============================================================================
# E2E WORKFLOW 2: Full Mode
# ============================================================================

echo "━━━ E2E 2: Full Mode ━━━"

# Test E4: Full mode runs additional checks
test_e2e_full_mode_output() {
    local proj=$(setup_teaching_project)
    cd "$proj"

    local output
    output=$(_teach_doctor --full 2>&1)

    local has_full=0 no_skip_hint=1
    echo "$output" | grep -q "full check" && has_full=1
    echo "$output" | grep -q "run --full" && no_skip_hint=0

    if [[ $has_full -eq 1 && $no_skip_hint -eq 1 ]]; then
        test_pass "Full mode: shows full header, no skip hint"
    else
        test_fail "Full mode output" "has_full=$has_full no_skip_hint=$no_skip_hint"
    fi
}
test_e2e_full_mode_output

# Test E5: Full mode with Quarto extensions
test_e2e_full_quarto_extensions() {
    local proj=$(setup_quarto_project)
    cd "$proj"

    local output
    output=$(_teach_doctor --full 2>&1)

    if echo "$output" | grep -q "3 Quarto extensions"; then
        test_pass "Full mode: counts 3 Quarto extensions correctly"
    else
        test_fail "Full Quarto ext" "missing '3 Quarto extensions' in output"
    fi
}
test_e2e_full_quarto_extensions

echo ""

# ============================================================================
# E2E WORKFLOW 3: CI Mode
# ============================================================================

echo "━━━ E2E 3: CI Mode ━━━"

# Test E6: CI mode outputs machine-readable key=value pairs
test_e2e_ci_mode_format() {
    local proj=$(setup_teaching_project)
    cd "$proj"

    local output
    output=$(_teach_doctor --ci 2>&1)

    local has_status=0 has_passed=0 has_mode=0 has_elapsed=0
    echo "$output" | grep -q "^doctor:status=" && has_status=1
    echo "$output" | grep -q "^doctor:passed=" && has_passed=1
    echo "$output" | grep -q "^doctor:mode=" && has_mode=1
    echo "$output" | grep -q "^doctor:elapsed=" && has_elapsed=1

    if [[ $has_status -eq 1 && $has_passed -eq 1 && $has_mode -eq 1 && $has_elapsed -eq 1 ]]; then
        test_pass "CI mode: key=value output format correct"
    else
        test_fail "CI mode format" "status=$has_status passed=$has_passed mode=$has_mode elapsed=$has_elapsed"
    fi
}
test_e2e_ci_mode_format

# Test E7: CI mode reports correct mode
test_e2e_ci_mode_quick_label() {
    local proj=$(setup_teaching_project)
    cd "$proj"

    local output
    output=$(_teach_doctor --ci 2>&1)

    if echo "$output" | grep -q "doctor:mode=quick"; then
        test_pass "CI mode: reports quick mode correctly"
    else
        test_fail "CI mode label" "expected doctor:mode=quick"
    fi
}
test_e2e_ci_mode_quick_label

# Test E8: CI mode with --full reports full
test_e2e_ci_mode_full_label() {
    local proj=$(setup_teaching_project)
    cd "$proj"

    local output
    output=$(_teach_doctor --ci --full 2>&1)

    if echo "$output" | grep -q "doctor:mode=full"; then
        test_pass "CI mode --full: reports full mode correctly"
    else
        test_fail "CI full mode label" "expected doctor:mode=full"
    fi
}
test_e2e_ci_mode_full_label

echo ""

# ============================================================================
# E2E WORKFLOW 4: JSON Output
# ============================================================================

echo "━━━ E2E 4: JSON Output ━━━"

# Test E9: JSON output is parseable
test_e2e_json_parseable() {
    local proj=$(setup_teaching_project)
    cd "$proj"

    local output
    output=$(_teach_doctor --json 2>/dev/null)

    # Try jq first, then basic structure check
    if command -v jq &>/dev/null; then
        if echo "$output" | jq . &>/dev/null; then
            test_pass "JSON output: valid JSON (jq verified)"
        else
            test_fail "JSON output" "jq parse failed"
        fi
    else
        # Fallback: check for JSON structure markers
        if echo "$output" | grep -q '"version"' && echo "$output" | grep -q '"summary"'; then
            test_pass "JSON output: has expected structure (jq not available)"
        else
            test_fail "JSON output" "missing version/summary fields"
        fi
    fi
}
test_e2e_json_parseable

# Test E10: JSON contains v1 version and mode field
test_e2e_json_fields() {
    local proj=$(setup_teaching_project)
    cd "$proj"

    local output
    output=$(_teach_doctor --json 2>/dev/null)

    if command -v jq &>/dev/null; then
        local version mode
        version=$(echo "$output" | jq -r '.version' 2>/dev/null)
        mode=$(echo "$output" | jq -r '.mode' 2>/dev/null)

        if [[ "$version" == "1" && "$mode" == "quick" ]]; then
            test_pass "JSON fields: version=1, mode=quick"
        else
            test_fail "JSON fields" "version=$version mode=$mode"
        fi
    else
        test_pass "JSON fields: skipped (jq not available)"
    fi
}
test_e2e_json_fields

# Test E11: JSON --full mode reports full
test_e2e_json_full_mode() {
    local proj=$(setup_teaching_project)
    cd "$proj"

    local output
    output=$(_teach_doctor --json --full 2>/dev/null)

    if command -v jq &>/dev/null; then
        local mode
        mode=$(echo "$output" | jq -r '.mode' 2>/dev/null)

        if [[ "$mode" == "full" ]]; then
            test_pass "JSON --full: mode=full"
        else
            test_fail "JSON full mode" "mode=$mode"
        fi
    else
        test_pass "JSON full: skipped (jq not available)"
    fi
}
test_e2e_json_full_mode

echo ""

# ============================================================================
# E2E WORKFLOW 5: Status File & Health Indicator
# ============================================================================

echo "━━━ E2E 5: Status File & Health Indicator ━━━"

# Test E12: Doctor writes status file
test_e2e_status_file_created() {
    local proj=$(setup_teaching_project)
    cd "$proj"

    _teach_doctor --brief >/dev/null 2>&1

    if [[ -f ".flow/doctor-status.json" ]]; then
        test_pass "Status file: .flow/doctor-status.json created"
    else
        test_fail "Status file" "not created after doctor run"
    fi
}
test_e2e_status_file_created

# Test E13: Status file has valid JSON
test_e2e_status_file_valid() {
    local proj=$(setup_teaching_project)
    cd "$proj"

    _teach_doctor --brief >/dev/null 2>&1

    if command -v jq &>/dev/null; then
        if jq . .flow/doctor-status.json &>/dev/null; then
            local health_status
            health_status=$(jq -r '.status' .flow/doctor-status.json 2>/dev/null)
            if [[ "$health_status" =~ ^(green|yellow|red)$ ]]; then
                test_pass "Status file: valid JSON with status=$health_status"
            else
                test_fail "Status file status" "status='$health_status', expected green/yellow/red"
            fi
        else
            test_fail "Status file JSON" "not valid JSON"
        fi
    else
        test_pass "Status file JSON: skipped (jq not available)"
    fi
}
test_e2e_status_file_valid

# Test E14: Health indicator reads status from file
test_e2e_health_indicator() {
    local proj=$(setup_teaching_project)
    cd "$proj"

    # Run doctor first to create status file
    _teach_doctor --brief >/dev/null 2>&1

    local indicator
    indicator=$(_teach_health_indicator)

    if [[ "$indicator" =~ ^(green|yellow|red)$ ]]; then
        test_pass "Health indicator: returns $indicator"
    else
        test_fail "Health indicator" "got '$indicator', expected green/yellow/red"
    fi
}
test_e2e_health_indicator

# Test E15: Health dot produces colored output
test_e2e_health_dot() {
    local proj=$(setup_teaching_project)
    cd "$proj"

    # Run doctor first
    _teach_doctor --brief >/dev/null 2>&1

    local dot
    dot=$(_teach_health_dot)

    # Should contain the bullet character
    if [[ -n "$dot" ]]; then
        test_pass "Health dot: non-empty output"
    else
        test_fail "Health dot" "empty output"
    fi
}
test_e2e_health_dot

# Test E16: No status file = no indicator
test_e2e_no_status_no_indicator() {
    local proj=$(setup_teaching_project)
    cd "$proj"

    # Ensure no status file
    rm -f ".flow/doctor-status.json"

    local indicator
    indicator=$(_teach_health_indicator)

    if [[ -z "$indicator" ]]; then
        test_pass "No status file: health indicator returns empty"
    else
        test_fail "No status indicator" "expected empty, got '$indicator'"
    fi
}
test_e2e_no_status_no_indicator

echo ""

# ============================================================================
# E2E WORKFLOW 6: Brief Mode
# ============================================================================

echo "━━━ E2E 6: Brief Mode ━━━"

# Test E17: Brief mode suppresses passing checks
test_e2e_brief_mode() {
    local proj=$(setup_teaching_project)
    cd "$proj"

    local output
    output=$(_teach_doctor --brief 2>&1)

    # Brief mode should NOT show the full header
    local has_header=0
    echo "$output" | grep -q "Teaching Environment" && has_header=1

    if [[ $has_header -eq 0 ]]; then
        test_pass "Brief mode: suppresses header/passing checks"
    else
        test_fail "Brief mode" "header still showing"
    fi
}
test_e2e_brief_mode

echo ""

# ============================================================================
# E2E WORKFLOW 7: renv-Aware R Checks
# ============================================================================

echo "━━━ E2E 7: renv Detection ━━━"

# Test E18: renv project detected correctly
test_e2e_renv_detection() {
    local proj=$(setup_renv_project)
    cd "$proj"

    local output
    output=$(_teach_doctor 2>&1)

    if echo "$output" | grep -qi "renv"; then
        test_pass "renv detection: mentioned in doctor output"
    else
        test_fail "renv detection" "no renv mention in output"
    fi
}
test_e2e_renv_detection

# Test E19: renv package count shown if jq available
test_e2e_renv_package_count() {
    local proj=$(setup_renv_project)
    cd "$proj"

    local output
    output=$(_teach_doctor 2>&1)

    if command -v jq &>/dev/null; then
        if echo "$output" | grep -q "3 packages locked"; then
            test_pass "renv count: shows 3 packages locked"
        else
            test_fail "renv count" "missing '3 packages locked'"
        fi
    else
        test_pass "renv count: skipped (jq not available)"
    fi
}
test_e2e_renv_package_count

echo ""

# ============================================================================
# E2E WORKFLOW 8: Quarto Extensions Glob Fix
# ============================================================================

echo "━━━ E2E 8: Quarto Extensions ━━━"

# Test E20: Extensions with spaces in names counted correctly
test_e2e_quarto_ext_with_spaces() {
    local proj=$(setup_teaching_project)
    cd "$proj"

    # Create extensions with spaces in directory names
    mkdir -p "$proj/_extensions/my org/my extension"
    mkdir -p "$proj/_extensions/my org/another ext"

    local output
    output=$(_teach_doctor --full 2>&1)

    if echo "$output" | grep -q "2 Quarto extensions"; then
        test_pass "Quarto ext: counts 2 extensions with spaces in names"
    else
        test_fail "Quarto ext spaces" "missing '2 Quarto extensions'"
    fi
}
test_e2e_quarto_ext_with_spaces

# Test E21: No _extensions directory = skip gracefully
test_e2e_quarto_no_extensions_dir() {
    local proj=$(setup_teaching_project)
    cd "$proj"

    local output
    output=$(_teach_doctor --full 2>&1)

    # Should NOT mention "Quarto Extensions:" if dir doesn't exist
    local has_section=0
    echo "$output" | grep -q "Quarto Extensions:" && has_section=1

    if [[ $has_section -eq 0 ]]; then
        test_pass "No _extensions: skips Quarto section gracefully"
    else
        test_fail "No extensions skip" "section still shown"
    fi
}
test_e2e_quarto_no_extensions_dir

echo ""

# ============================================================================
# E2E WORKFLOW 9: Flag Combinations
# ============================================================================

echo "━━━ E2E 9: Flag Combinations ━━━"

# Test E22: --fix implies --full
test_e2e_fix_implies_full() {
    local proj=$(setup_teaching_project)
    cd "$proj"

    local output
    # Use --ci to avoid interactive prompt in --fix mode
    output=$(_teach_doctor --ci --fix 2>&1 < /dev/null)

    if echo "$output" | grep -q "doctor:mode=full"; then
        test_pass "--fix implies --full mode"
    else
        test_fail "--fix implies full" "mode not set to full"
    fi
}
test_e2e_fix_implies_full

# Test E23: --verbose implies --full
test_e2e_verbose_implies_full() {
    local proj=$(setup_teaching_project)
    cd "$proj"

    local output
    output=$(_teach_doctor --verbose 2>&1)

    if echo "$output" | grep -q "full check"; then
        test_pass "--verbose implies --full mode"
    else
        test_fail "--verbose implies full" "missing 'full check' header"
    fi
}
test_e2e_verbose_implies_full

echo ""

# ============================================================================
# E2E WORKFLOW 10: Demo Course Fixture
# ============================================================================

echo "━━━ E2E 10: Demo Course Fixture ━━━"

# Test E24: Doctor runs on demo-course fixture without errors
test_e2e_demo_course() {
    if [[ ! -d "$DEMO_COURSE" ]]; then
        test_pass "Demo course: skipped (fixture not found)"
        return
    fi

    local proj
    proj=$(mktemp -d "$TEST_DIR/demo-XXXXXXXX")
    cp -r "$DEMO_COURSE/." "$proj/"
    git init "$proj" >/dev/null 2>&1
    cd "$proj"

    local output
    output=$(_teach_doctor 2>&1)
    local rc=$?

    # Should not crash - rc can be 0 or 1 depending on deps
    if [[ -n "$output" ]]; then
        test_pass "Demo course: doctor runs without crash"
    else
        test_fail "Demo course" "empty output"
    fi
}
test_e2e_demo_course

# Test E25: Demo course with --json produces valid JSON
test_e2e_demo_course_json() {
    if [[ ! -d "$DEMO_COURSE" ]]; then
        test_pass "Demo course JSON: skipped (fixture not found)"
        return
    fi

    local proj
    proj=$(mktemp -d "$TEST_DIR/demo-json-XXXXXXXX")
    cp -r "$DEMO_COURSE/." "$proj/"
    git init "$proj" >/dev/null 2>&1
    cd "$proj"

    local output
    output=$(_teach_doctor --json 2>/dev/null)

    if command -v jq &>/dev/null; then
        if echo "$output" | jq . &>/dev/null; then
            test_pass "Demo course: JSON output valid"
        else
            test_fail "Demo course JSON" "not parseable"
        fi
    else
        test_pass "Demo course JSON: skipped (jq not available)"
    fi
}
test_e2e_demo_course_json

echo ""

# ============================================================================
# E2E WORKFLOW 11: Severity-Grouped Summary
# ============================================================================

echo "━━━ E2E 11: Summary Output ━━━"

# Test E26: Summary shows pass count
test_e2e_summary_pass_count() {
    local proj=$(setup_teaching_project)
    cd "$proj"

    local output
    output=$(_teach_doctor 2>&1)

    if echo "$output" | grep -q "Passed:"; then
        test_pass "Summary: shows Passed count"
    else
        test_fail "Summary pass count" "missing 'Passed:' in output"
    fi
}
test_e2e_summary_pass_count

# Test E27: Summary line separator
test_e2e_summary_separator() {
    local proj=$(setup_teaching_project)
    cd "$proj"

    local output
    output=$(_teach_doctor 2>&1)

    if echo "$output" | grep -q "──────────"; then
        test_pass "Summary: has separator line"
    else
        test_fail "Summary separator" "missing separator"
    fi
}
test_e2e_summary_separator

echo ""

# ============================================================================
# SUMMARY
# ============================================================================

cd "$ORIGINAL_DIR"
echo ""
test_summary
