#!/usr/bin/env zsh
# test-teach-templates.zsh - Tests for teach templates command
# v5.20.0 - Template Support (#301)

# Get script directory and set up paths
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

# Source test helpers
source "$PROJECT_ROOT/tests/test-helpers.zsh" 2>/dev/null || {
    # Minimal test helpers if not found
    TEST_PASS=0
    TEST_FAIL=0

    test_pass() { ((TEST_PASS++)); echo "✅ $1"; }
    test_fail() { ((TEST_FAIL++)); echo "❌ $1: $2"; }
    test_summary() { echo ""; echo "Tests: $((TEST_PASS + TEST_FAIL)) | Pass: $TEST_PASS | Fail: $TEST_FAIL"; }
}

# Source the libraries being tested
source "$PROJECT_ROOT/lib/core.zsh" 2>/dev/null || true
source "$PROJECT_ROOT/lib/template-helpers.zsh"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  teach templates - Unit Tests                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# SETUP
# ============================================================================

TEST_DIR=$(mktemp -d)
PLUGIN_DIR="$PROJECT_ROOT/lib/templates/teaching"

cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# ============================================================================
# PATH UTILITIES TESTS
# ============================================================================

echo "━━━ Path Utilities ━━━"

# Test _template_get_plugin_dir
test_plugin_dir() {
    local result
    result=$(_template_get_plugin_dir 2>/dev/null)

    if [[ -d "$result" ]]; then
        test_pass "_template_get_plugin_dir returns existing directory"
    else
        test_fail "_template_get_plugin_dir" "returned non-existent path: $result"
    fi
}
test_plugin_dir

# Test _template_get_project_dir (no .flow)
test_project_dir_missing() {
    local result
    result=$(_template_get_project_dir "$TEST_DIR" 2>/dev/null)

    if [[ -z "$result" ]]; then
        test_pass "_template_get_project_dir returns empty when no .flow"
    else
        test_fail "_template_get_project_dir" "should return empty, got: $result"
    fi
}
test_project_dir_missing

# Test _template_get_project_dir (with .flow)
test_project_dir_exists() {
    mkdir -p "$TEST_DIR/.flow"

    local result
    result=$(_template_get_project_dir "$TEST_DIR" 2>/dev/null)

    if [[ "$result" == "$TEST_DIR/.flow/templates" ]]; then
        test_pass "_template_get_project_dir returns correct path"
    else
        test_fail "_template_get_project_dir" "expected $TEST_DIR/.flow/templates, got: $result"
    fi
}
test_project_dir_exists

echo ""

# ============================================================================
# METADATA PARSING TESTS
# ============================================================================

echo "━━━ Metadata Parsing ━━━"

# Create test template
cat > "$TEST_DIR/test-template.md" << 'EOF'
---
template_version: "1.0"
template_type: "lecture"
template_description: "Test template"
template_variables: [WEEK, TOPIC]
---

# Test Content

This is {{WEEK}} and {{TOPIC}}.
EOF

# Test metadata extraction
test_parse_metadata() {
    typeset -A meta
    _teach_parse_template_metadata "$TEST_DIR/test-template.md" meta

    if [[ "${meta[template_version]}" == "1.0" ]]; then
        test_pass "Parse template_version"
    else
        test_fail "Parse template_version" "got: ${meta[template_version]}"
    fi

    if [[ "${meta[template_type]}" == "lecture" ]]; then
        test_pass "Parse template_type"
    else
        test_fail "Parse template_type" "got: ${meta[template_type]}"
    fi
}
test_parse_metadata

# Test single field extraction
test_get_field() {
    local version
    version=$(_teach_get_template_field "$TEST_DIR/test-template.md" "template_version")

    if [[ "$version" == "1.0" ]]; then
        test_pass "_teach_get_template_field extracts single field"
    else
        test_fail "_teach_get_template_field" "expected 1.0, got: $version"
    fi
}
test_get_field

echo ""

# ============================================================================
# VARIABLE EXTRACTION TESTS
# ============================================================================

echo "━━━ Variable Extraction ━━━"

test_extract_variables() {
    local vars
    vars=($(_teach_extract_variables "$TEST_DIR/test-template.md"))

    local expected_count=2
    if [[ ${#vars[@]} -eq $expected_count ]]; then
        test_pass "Extract correct number of variables"
    else
        test_fail "Variable count" "expected $expected_count, got ${#vars[@]}"
    fi

    if [[ "${vars[@]}" == *"WEEK"* ]]; then
        test_pass "Extract WEEK variable"
    else
        test_fail "Extract WEEK" "not found in: ${vars[@]}"
    fi

    if [[ "${vars[@]}" == *"TOPIC"* ]]; then
        test_pass "Extract TOPIC variable"
    else
        test_fail "Extract TOPIC" "not found in: ${vars[@]}"
    fi
}
test_extract_variables

echo ""

# ============================================================================
# VARIABLE SUBSTITUTION TESTS
# ============================================================================

echo "━━━ Variable Substitution ━━━"

test_substitute_variables() {
    typeset -A vars
    vars[WEEK]="05"
    vars[TOPIC]="ANOVA"

    local content="Week {{WEEK}}: {{TOPIC}}"
    local result
    result=$(_teach_substitute_variables "$content" vars)

    if [[ "$result" == "Week 05: ANOVA" ]]; then
        test_pass "Variable substitution works"
    else
        test_fail "Variable substitution" "expected 'Week 05: ANOVA', got: $result"
    fi
}
test_substitute_variables

echo ""

# ============================================================================
# SLUG GENERATION TESTS
# ============================================================================

echo "━━━ Slug Generation ━━━"

test_slugify() {
    # Test cases: input|expected
    local tests=(
        "Linear Regression|linear-regression"
        "ANOVA (One-Way)|anova-one-way"
        "Mixed Effects Models|mixed-effects-models"
        "Week 5 Intro|week-5-intro"
    )

    local all_pass=1
    for test in $tests; do
        local input="${test%%|*}"
        local expected="${test#*|}"
        local result
        result=$(_teach_slugify "$input")

        if [[ "$result" == "$expected" ]]; then
            test_pass "Slugify: '$input' → '$result'"
        else
            test_fail "Slugify: '$input'" "expected '$expected', got '$result'"
            all_pass=0
        fi
    done
}
test_slugify

echo ""

# ============================================================================
# VERSION COMPARISON TESTS
# ============================================================================

echo "━━━ Version Comparison ━━━"

test_version_compare() {
    # Equal versions
    _teach_compare_versions "1.0" "1.0"
    if [[ $? -eq 0 ]]; then
        test_pass "1.0 = 1.0"
    else
        test_fail "1.0 = 1.0" "should return 0"
    fi

    # v1 > v2
    _teach_compare_versions "1.1" "1.0"
    if [[ $? -eq 1 ]]; then
        test_pass "1.1 > 1.0"
    else
        test_fail "1.1 > 1.0" "should return 1"
    fi

    # v1 < v2
    _teach_compare_versions "1.0" "1.1"
    if [[ $? -eq 2 ]]; then
        test_pass "1.0 < 1.1"
    else
        test_fail "1.0 < 1.1" "should return 2"
    fi

    # Multi-part versions
    _teach_compare_versions "1.2.3" "1.2.4"
    if [[ $? -eq 2 ]]; then
        test_pass "1.2.3 < 1.2.4"
    else
        test_fail "1.2.3 < 1.2.4" "should return 2"
    fi
}
test_version_compare

echo ""

# ============================================================================
# DIRECTORY CREATION TESTS
# ============================================================================

echo "━━━ Directory Creation ━━━"

test_create_template_dirs() {
    local result_dir
    result_dir=$(_teach_create_template_dirs "$TEST_DIR/new-project")

    local all_exist=1
    for type in content prompts metadata checklists; do
        if [[ ! -d "$result_dir/$type" ]]; then
            test_fail "Create directory" "$type not created"
            all_exist=0
        fi
    done

    if [[ $all_exist -eq 1 ]]; then
        test_pass "All template directories created"
    fi
}
test_create_template_dirs

echo ""

# ============================================================================
# TEMPLATE DISCOVERY TESTS
# ============================================================================

echo "━━━ Template Discovery ━━━"

test_plugin_templates_exist() {
    local templates
    templates=$(_teach_get_template_sources --source plugin 2>/dev/null)

    if [[ -n "$templates" ]]; then
        local count=$(echo "$templates" | wc -l | tr -d ' ')
        test_pass "Found $count plugin templates"
    else
        test_fail "Plugin templates" "no templates found"
    fi
}
test_plugin_templates_exist

test_template_resolution() {
    local path
    path=$(_teach_resolve_template "lecture-notes" "prompts")

    if [[ -f "$path" ]]; then
        test_pass "Resolve lecture-notes prompt template"
    else
        test_fail "Resolve template" "lecture-notes not found"
    fi
}
test_template_resolution

echo ""

# ============================================================================
# SUMMARY
# ============================================================================

test_summary
