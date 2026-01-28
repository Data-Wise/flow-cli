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
# INTEGRATION: teach templates new
# ============================================================================

echo "━━━ Integration: teach templates new ━━━"

# Source command file for integration tests
source "$PROJECT_ROOT/commands/teach-templates.zsh" 2>/dev/null || true

# Create a mock project for integration testing
INTEGRATION_DIR="$TEST_DIR/integration-project"
mkdir -p "$INTEGRATION_DIR/.flow/templates/content"
cd "$INTEGRATION_DIR"

# Test 1: new command requires template type
test_new_requires_type() {
    local output
    output=$(_teach_templates new 2>&1)

    if [[ "$output" == *"Usage"* || "$output" == *"template type"* ]]; then
        test_pass "new command shows usage when missing type"
    else
        test_fail "new requires type" "should show usage"
    fi
}
test_new_requires_type

# Test 2: new command errors on unknown template
test_new_unknown_template() {
    local output
    output=$(_teach_templates new nonexistent destination 2>&1)

    if [[ "$output" == *"not found"* || "$output" == *"Unknown"* || "$output" == *"error"* ]]; then
        test_pass "new command errors on unknown template"
    else
        test_fail "new unknown template" "should show error, got: $output"
    fi
}
test_new_unknown_template

# Test 3: new --dry-run shows preview
test_new_dry_run() {
    local output
    output=$(_teach_templates new lecture week-01 --dry-run 2>&1)

    if [[ "$output" == *"preview"* || "$output" == *"Would create"* || "$output" == *"dry"* ]]; then
        test_pass "new --dry-run shows preview"
    else
        test_fail "new --dry-run" "should show preview, got: $output"
    fi
}
test_new_dry_run

# Test 4: new creates file from template
test_new_creates_file() {
    # Note: when providing full path, file is created without additional extension
    local dest_file="$INTEGRATION_DIR/lectures/week-02"
    mkdir -p "$INTEGRATION_DIR/lectures"

    # Run new command
    _teach_templates new lecture "$dest_file" --week 02 --topic "Intro" 2>/dev/null

    if [[ -f "$dest_file" ]]; then
        test_pass "new command creates file"
    else
        test_fail "new creates file" "file not created: $dest_file"
    fi
}
test_new_creates_file

# Test 5: new substitutes variables
test_new_substitutes_vars() {
    # Note: when providing full path, file is created without additional extension
    local dest_file="$INTEGRATION_DIR/lectures/week-03"
    mkdir -p "$INTEGRATION_DIR/lectures"

    _teach_templates new lecture "$dest_file" --week 03 --topic "Regression" 2>/dev/null

    if [[ -f "$dest_file" ]]; then
        local content
        content=$(cat "$dest_file")
        if [[ "$content" == *"03"* || "$content" == *"Regression"* ]]; then
            test_pass "new substitutes variables"
        else
            test_fail "new substitutes vars" "variables not substituted"
        fi
    else
        test_fail "new substitutes vars" "file not created"
    fi
}
test_new_substitutes_vars

# Test 6: new preserves template metadata structure
test_new_preserves_frontmatter() {
    # Note: when providing full path, file is created without additional extension
    local dest_file="$INTEGRATION_DIR/lectures/week-04"
    mkdir -p "$INTEGRATION_DIR/lectures"

    _teach_templates new lecture "$dest_file" --week 04 2>/dev/null

    if [[ -f "$dest_file" ]]; then
        local first_line
        first_line=$(head -1 "$dest_file")
        if [[ "$first_line" == "---" ]]; then
            test_pass "new preserves YAML frontmatter"
        else
            test_fail "new preserves frontmatter" "first line should be ---, got: $first_line"
        fi
    else
        test_fail "new preserves frontmatter" "file not created"
    fi
}
test_new_preserves_frontmatter

# Test 7: new refuses to overwrite without --force
test_new_no_overwrite() {
    local dest_file="$INTEGRATION_DIR/lectures/existing.qmd"
    mkdir -p "$INTEGRATION_DIR/lectures"
    echo "existing content" > "$dest_file"

    local output
    output=$(_teach_templates new lecture "$INTEGRATION_DIR/lectures/existing" 2>&1)

    local content
    content=$(cat "$dest_file")
    if [[ "$content" == "existing content" ]]; then
        test_pass "new refuses to overwrite without --force"
    else
        test_fail "new no overwrite" "file was overwritten"
    fi
}
test_new_no_overwrite

# Test 8: new --force overwrites
test_new_force_overwrite() {
    # Note: file path used in new must match the existing file
    local dest_file="$INTEGRATION_DIR/lectures/overwrite-test"
    mkdir -p "$INTEGRATION_DIR/lectures"
    echo "old content" > "$dest_file"

    _teach_templates new lecture "$dest_file" --force 2>/dev/null

    local content
    content=$(cat "$dest_file")
    if [[ "$content" != "old content" ]]; then
        test_pass "new --force overwrites file"
    else
        test_fail "new --force" "file was not overwritten"
    fi
}
test_new_force_overwrite

cd "$ORIGINAL_PWD" 2>/dev/null || cd "$PROJECT_ROOT"

echo ""

# ============================================================================
# INTEGRATION: teach init --with-templates
# ============================================================================

echo "━━━ Integration: teach init --with-templates ━━━"

# Source teach dispatcher for init command
source "$PROJECT_ROOT/lib/dispatchers/teach-dispatcher.zsh" 2>/dev/null || true

# Test 1: init --with-templates creates template directories
test_init_with_templates() {
    local init_dir="$TEST_DIR/init-test"
    mkdir -p "$init_dir"
    cd "$init_dir"

    # Run init with templates (suppress interactive prompts)
    _teach_init "TEST-101" --with-templates 2>/dev/null

    local all_dirs=1
    for type in content prompts metadata checklists; do
        if [[ ! -d "$init_dir/.flow/templates/$type" ]]; then
            all_dirs=0
        fi
    done

    if [[ $all_dirs -eq 1 ]]; then
        test_pass "init --with-templates creates template directories"
    else
        test_fail "init --with-templates" "not all template directories created"
    fi

    cd "$PROJECT_ROOT"
}
test_init_with_templates

# Test 2: init --with-templates syncs prompts
test_init_syncs_prompts() {
    local init_dir="$TEST_DIR/init-prompts-test"
    mkdir -p "$init_dir"
    cd "$init_dir"

    _teach_init "TEST-102" --with-templates 2>/dev/null

    local prompts_dir="$init_dir/.flow/templates/prompts"
    if [[ -d "$prompts_dir" ]]; then
        local count=$(ls -1 "$prompts_dir" 2>/dev/null | wc -l | tr -d ' ')
        if [[ $count -gt 0 ]]; then
            test_pass "init --with-templates syncs $count prompt templates"
        else
            test_fail "init syncs prompts" "no prompts synced"
        fi
    else
        test_fail "init syncs prompts" "prompts directory not created"
    fi

    cd "$PROJECT_ROOT"
}
test_init_syncs_prompts

echo ""

# ============================================================================
# SUMMARY
# ============================================================================

test_summary
