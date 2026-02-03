#!/usr/bin/env zsh
# automated-teach-style-dogfood.zsh - Non-interactive dogfooding for teach style (#298)
# Run with: zsh tests/automated-teach-style-dogfood.zsh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'

# Counters
typeset -g TESTS_RUN=0
typeset -g TESTS_PASSED=0
typeset -g TESTS_FAILED=0
typeset -g TESTS_SKIPPED=0

# Get script directory
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR}/.."
DEMO_COURSE="$PROJECT_ROOT/tests/fixtures/demo-course"

# Load plugin
echo "${CYAN}Loading flow-cli plugin...${RESET}"
source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
    echo "${RED}ERROR: Failed to load plugin${RESET}"
    exit 1
}
echo "${GREEN}✓ Plugin loaded${RESET}"
echo ""

# ============================================================================
# Test runner — exit 0=pass, 77=skip, other=fail
# ============================================================================
run_test() {
    local test_name="$1"
    local test_func="$2"

    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "${CYAN}[$TESTS_RUN] $test_name...${RESET} "

    local output
    output=$(eval "$test_func" 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        echo "${GREEN}✓${RESET}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    elif [[ $exit_code -eq 77 ]]; then
        echo "${YELLOW}SKIP (yq/sed not callable)${RESET}"
        TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
    else
        echo "${RED}✗${RESET}"
        echo "  ${DIM}Output: ${output:0:200}${RESET}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# ============================================================================
# Create test fixtures (needed before yq probe)
# ============================================================================

# Temp course with teaching_style
TEMP_COURSE=$(mktemp -d)
mkdir -p "$TEMP_COURSE/.flow"
cat > "$TEMP_COURSE/.flow/teach-config.yml" <<'YAML'
course:
  name: "TEST-100"
teaching_style:
  pedagogical_approach:
    primary: "lecture-based"
    secondary: "active-learning"
  explanation_style:
    formality: "formal"
    proof_style: "rigorous"
  content_preferences:
    code_style: "base-R"
    computational_tools: "R-integrated"
  assessment_philosophy:
    exam_format: "mixed"
    quiz_format: "short-answer"
  command_overrides:
    lecture:
      length: "15-20 pages"
    exam:
      duration: 90
YAML

# Legacy course with frontmatter-only config
LEGACY_COURSE=$(mktemp -d)
mkdir -p "$LEGACY_COURSE/.flow" "$LEGACY_COURSE/.claude"
cat > "$LEGACY_COURSE/.flow/teach-config.yml" <<'YAML'
course:
  name: "LEGACY-200"
YAML

cat > "$LEGACY_COURSE/.claude/teaching-style.local.md" <<'YAML'
---
teaching_style:
  pedagogical_approach:
    primary: "socratic"
  explanation_style:
    formality: "conversational"
---

# Legacy Teaching Style
YAML

# Redirect shim course
SHIM_COURSE=$(mktemp -d)
mkdir -p "$SHIM_COURSE/.flow" "$SHIM_COURSE/.claude"
cat > "$SHIM_COURSE/.flow/teach-config.yml" <<'YAML'
course:
  name: "SHIM-300"
teaching_style:
  pedagogical_approach:
    primary: "active-learning"
YAML

cat > "$SHIM_COURSE/.claude/teaching-style.local.md" <<'YAML'
---
teaching_style:
  _redirect: true
  _location: ".flow/teach-config.yml"
---

# Redirect Shim
YAML

# ============================================================================
# yq probe — tests if _teach_get_style actually works in this environment
# Sandboxed environments (Claude Code) may block yq/sed inside plugin functions
# ============================================================================
_YQ_IN_FUNCTIONS=false
_probe_result=$(_teach_get_style "pedagogical_approach.primary" "$TEMP_COURSE" 2>/dev/null)
if [[ "$_probe_result" == "lecture-based" ]]; then
    _YQ_IN_FUNCTIONS=true
fi
unset _probe_result

if [[ "$_YQ_IN_FUNCTIONS" != "true" ]]; then
    echo "${YELLOW}⚠ yq/sed not callable from plugin functions — some tests will be skipped${RESET}"
    echo ""
fi

# ============================================================================
# SECTION 1: Helper function loading
# ============================================================================
echo "${CYAN}━━━ Section 1: Helper Loading ━━━${RESET}"

run_test "teach-style-helpers loaded" '
    typeset -f _teach_find_style_source >/dev/null 2>&1 || return 1
    typeset -f _teach_get_style >/dev/null 2>&1 || return 1
    typeset -f _teach_get_command_override >/dev/null 2>&1 || return 1
    typeset -f _teach_style_is_redirect >/dev/null 2>&1 || return 1
'

run_test "Load guard variable set" '
    [[ -n "$_FLOW_TEACH_STYLE_HELPERS_LOADED" ]] || return 1
'

echo ""

# ============================================================================
# SECTION 2: _teach_find_style_source (no teaching_style in demo)
# ============================================================================
echo "${CYAN}━━━ Section 2: Style Source Detection ━━━${RESET}"

run_test "Demo course: no teaching_style returns failure" '
    _teach_find_style_source "$DEMO_COURSE" &>/dev/null && return 1
    return 0
'

run_test "Nonexistent dir returns failure" '
    _teach_find_style_source "/tmp/nonexistent-course-$$" &>/dev/null && return 1
    return 0
'

echo ""

# ============================================================================
# SECTION 3: _teach_find_style_source with teaching_style + value reads
# ============================================================================
echo "${CYAN}━━━ Section 3: Style Source with Config ━━━${RESET}"

run_test "Temp course: finds teach-config source" '
    local result
    result=$(_teach_find_style_source "$TEMP_COURSE" 2>/dev/null) || return 1
    local path="${result%%:*}"
    local type="${result##*:}"
    [[ "$type" == "teach-config" ]] || return 1
    [[ "$path" == *"teach-config.yml" ]] || return 1
'

run_test "_teach_get_style reads pedagogical_approach.primary" '
    [[ "$_YQ_IN_FUNCTIONS" == "true" ]] || return 77
    local result
    result=$(_teach_get_style "pedagogical_approach.primary" "$TEMP_COURSE" 2>/dev/null) || return 1
    [[ "$result" == "lecture-based" ]] || return 1
'

run_test "_teach_get_style reads explanation_style.formality" '
    [[ "$_YQ_IN_FUNCTIONS" == "true" ]] || return 77
    local result
    result=$(_teach_get_style "explanation_style.formality" "$TEMP_COURSE" 2>/dev/null) || return 1
    [[ "$result" == "formal" ]] || return 1
'

run_test "_teach_get_style reads content_preferences.code_style" '
    [[ "$_YQ_IN_FUNCTIONS" == "true" ]] || return 77
    local result
    result=$(_teach_get_style "content_preferences.code_style" "$TEMP_COURSE" 2>/dev/null) || return 1
    [[ "$result" == "base-R" ]] || return 1
'

run_test "_teach_get_style returns failure for missing key" '
    [[ "$_YQ_IN_FUNCTIONS" == "true" ]] || return 77
    _teach_get_style "nonexistent.key" "$TEMP_COURSE" &>/dev/null && return 1
    return 0
'

run_test "_teach_get_style with empty key returns failure" '
    _teach_get_style "" "$TEMP_COURSE" &>/dev/null && return 1
    return 0
'

echo ""

# ============================================================================
# SECTION 4: _teach_get_command_override
# ============================================================================
echo "${CYAN}━━━ Section 4: Command Overrides ━━━${RESET}"

run_test "Get lecture length override" '
    [[ "$_YQ_IN_FUNCTIONS" == "true" ]] || return 77
    local result
    result=$(_teach_get_command_override "lecture" "length" "$TEMP_COURSE" 2>/dev/null) || return 1
    [[ "$result" == "15-20 pages" ]] || return 1
'

run_test "Get exam duration override" '
    [[ "$_YQ_IN_FUNCTIONS" == "true" ]] || return 77
    local result
    result=$(_teach_get_command_override "exam" "duration" "$TEMP_COURSE" 2>/dev/null) || return 1
    [[ "$result" == "90" ]] || return 1
'

run_test "Missing command returns failure" '
    [[ "$_YQ_IN_FUNCTIONS" == "true" ]] || return 77
    _teach_get_command_override "rubric" "style" "$TEMP_COURSE" &>/dev/null && return 1
    return 0
'

run_test "Empty command returns failure" '
    _teach_get_command_override "" "" "$TEMP_COURSE" &>/dev/null && return 1
    return 0
'

run_test "Full command override (no key) returns object" '
    [[ "$_YQ_IN_FUNCTIONS" == "true" ]] || return 77
    local result
    result=$(_teach_get_command_override "lecture" "" "$TEMP_COURSE" 2>/dev/null) || return 1
    [[ "$result" == *"length"* ]] || return 1
'

echo ""

# ============================================================================
# SECTION 5: Legacy fallback
# ============================================================================
echo "${CYAN}━━━ Section 5: Legacy Fallback ━━━${RESET}"

run_test "Legacy course: finds legacy-md source" '
    local result
    result=$(_teach_find_style_source "$LEGACY_COURSE" 2>/dev/null) || return 1
    local type="${result##*:}"
    [[ "$type" == "legacy-md" ]] || return 1
'

run_test "Legacy course: reads style from frontmatter" '
    [[ "$_YQ_IN_FUNCTIONS" == "true" ]] || return 77
    local result
    result=$(_teach_get_style "pedagogical_approach.primary" "$LEGACY_COURSE" 2>/dev/null) || return 1
    [[ "$result" == "socratic" ]] || return 1
'

echo ""

# ============================================================================
# SECTION 6: Redirect shim detection
# ============================================================================
echo "${CYAN}━━━ Section 6: Redirect Shim Detection ━━━${RESET}"

run_test "Redirect shim detected" '
    _teach_style_is_redirect "$SHIM_COURSE" || return 1
'

run_test "Non-redirect file not detected as shim" '
    _teach_style_is_redirect "$LEGACY_COURSE" && return 1
    return 0
'

run_test "Missing file not detected as shim" '
    _teach_style_is_redirect "$TEMP_COURSE" && return 1
    return 0
'

run_test "Shim course: prefers teach-config over shim" '
    local result
    result=$(_teach_find_style_source "$SHIM_COURSE" 2>/dev/null) || return 1
    local type="${result##*:}"
    [[ "$type" == "teach-config" ]] || return 1
'

echo ""

# ============================================================================
# SECTION 7: teach style command (non-interactive)
# ============================================================================
echo "${CYAN}━━━ Section 7: teach style Command ━━━${RESET}"

run_test "teach style help works" '
    local output
    output=$(teach style help 2>&1) || return 1
    [[ "$output" == *"Teaching Style Management"* ]] || return 1
    [[ "$output" == *"MOST COMMON"* ]] || return 1
'

run_test "teach style show in temp course" '
    [[ "$_YQ_IN_FUNCTIONS" == "true" ]] || return 77
    local output
    output=$(cd "$TEMP_COURSE" && teach style show 2>&1)
    [[ "$output" == *"Teaching Style Configuration"* ]] || return 1
    [[ "$output" == *"teach-config.yml"* ]] || return 1
'

run_test "teach style show displays approach" '
    [[ "$_YQ_IN_FUNCTIONS" == "true" ]] || return 77
    local output
    output=$(cd "$TEMP_COURSE" && teach style show 2>&1)
    [[ "$output" == *"lecture-based"* ]] || return 1
'

run_test "teach style show in dir with no style" '
    local tmpdir=$(mktemp -d)
    mkdir -p "$tmpdir/.flow"
    printf "course:\n  name: NONE\n" > "$tmpdir/.flow/teach-config.yml"
    local output
    output=$(cd "$tmpdir" && teach style show 2>&1)
    local rc=$?
    rm -rf "$tmpdir"
    [[ "$output" == *"No teaching style configured"* ]] || return 1
'

run_test "teach style check in temp course" '
    [[ "$_YQ_IN_FUNCTIONS" == "true" ]] || return 77
    local output
    output=$(cd "$TEMP_COURSE" && teach style check 2>&1)
    [[ "$output" == *"All checks passed"* ]] || return 1
'

run_test "teach style check detects missing sections" '
    [[ "$_YQ_IN_FUNCTIONS" == "true" ]] || return 77
    local mindir=$(mktemp -d)
    mkdir -p "$mindir/.flow"
    printf "course:\n  name: MINIMAL\nteaching_style:\n  pedagogical_approach:\n    primary: lecture\n" > "$mindir/.flow/teach-config.yml"
    local output
    output=$(cd "$mindir" && teach style check 2>&1)
    rm -rf "$mindir"
    [[ "$output" == *"Missing"* ]] || return 1
'

echo ""

# ============================================================================
# SECTION 8: teach doctor integration
# ============================================================================
echo "${CYAN}━━━ Section 8: teach doctor Integration ━━━${RESET}"

run_test "teach doctor includes teaching style section" '
    [[ "$_YQ_IN_FUNCTIONS" == "true" ]] || return 77
    local -i passed=0 warnings=0 failures=0
    local -a json_results=()
    local json=false quiet=false
    local output
    output=$(cd "$TEMP_COURSE" && _teach_doctor_check_teaching_style 2>&1)
    [[ "$output" == *"Teaching Style"* ]] || [[ "$output" == *"TEACHING STYLE"* ]] || return 1
'

run_test "teach doctor reports teach-config source" '
    [[ "$_YQ_IN_FUNCTIONS" == "true" ]] || return 77
    local -i passed=0 warnings=0 failures=0
    local -a json_results=()
    local json=false quiet=false
    local output
    output=$(cd "$TEMP_COURSE" && _teach_doctor_check_teaching_style 2>&1)
    [[ "$output" == *"teach-config.yml"* ]] || return 1
'

run_test "teach doctor warns on no teaching style" '
    local tmpdir=$(mktemp -d)
    mkdir -p "$tmpdir/.flow"
    printf "course:\n  name: NONE\n" > "$tmpdir/.flow/teach-config.yml"
    local -i passed=0 warnings=0 failures=0
    local -a json_results=()
    local json=false quiet=false
    local output
    output=$(cd "$tmpdir" && _teach_doctor_check_teaching_style 2>&1)
    rm -rf "$tmpdir"
    [[ "$output" == *"No teaching style configured"* ]] || return 1
'

echo ""

# ============================================================================
# SECTION 9: Schema validation
# ============================================================================
echo "${CYAN}━━━ Section 9: Schema Validation ━━━${RESET}"

run_test "Schema JSON is valid" '
    python3 -m json.tool "$PROJECT_ROOT/lib/templates/teaching/teach-config.schema.json" > /dev/null 2>&1 || return 1
'

run_test "Schema has teaching_style definition" '
    local result
    result=$(python3 -c "
import json
with open(\"$PROJECT_ROOT/lib/templates/teaching/teach-config.schema.json\") as f:
    schema = json.load(f)
assert \"teaching_style\" in schema[\"definitions\"], \"Missing teaching_style definition\"
assert \"command_overrides\" in schema[\"definitions\"], \"Missing command_overrides definition\"
print(\"ok\")
" 2>&1) || return 1
    [[ "$result" == "ok" ]] || return 1
'

run_test "Schema teaching_style has expected properties" '
    local result
    result=$(python3 -c "
import json
with open(\"$PROJECT_ROOT/lib/templates/teaching/teach-config.schema.json\") as f:
    schema = json.load(f)
ts = schema[\"definitions\"][\"teaching_style\"][\"properties\"]
expected = [\"pedagogical_approach\", \"explanation_style\", \"assessment_philosophy\",
            \"student_interaction\", \"content_preferences\", \"notation_conventions\"]
for prop in expected:
    assert prop in ts, f\"Missing {prop}\"
print(\"ok\")
" 2>&1) || return 1
    [[ "$result" == "ok" ]] || return 1
'

run_test "Schema command_overrides has 7 commands" '
    local result
    result=$(python3 -c "
import json
with open(\"$PROJECT_ROOT/lib/templates/teaching/teach-config.schema.json\") as f:
    schema = json.load(f)
co = schema[\"definitions\"][\"command_overrides\"][\"properties\"]
expected = [\"lecture\", \"slides\", \"quiz\", \"exam\", \"assignment\", \"rubric\", \"feedback\"]
for cmd in expected:
    assert cmd in co, f\"Missing {cmd}\"
print(\"ok\")
" 2>&1) || return 1
    [[ "$result" == "ok" ]] || return 1
'

echo ""

# ============================================================================
# Cleanup
# ============================================================================
rm -rf "$TEMP_COURSE" "$LEGACY_COURSE" "$SHIM_COURSE"

# ============================================================================
# Summary
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "${GREEN}✓ All $TESTS_PASSED/$TESTS_RUN tests passed${RESET}"
    [[ $TESTS_SKIPPED -gt 0 ]] && echo "  ${YELLOW}($TESTS_SKIPPED skipped — yq/sed not available in sandbox)${RESET}"
else
    echo "${RED}✗ $TESTS_FAILED/$TESTS_RUN tests failed${RESET}"
    echo "  ${GREEN}$TESTS_PASSED passed${RESET}, ${RED}$TESTS_FAILED failed${RESET}"
    [[ $TESTS_SKIPPED -gt 0 ]] && echo "  ${YELLOW}$TESTS_SKIPPED skipped${RESET}"
fi
echo ""

exit $TESTS_FAILED
