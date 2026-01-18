#!/bin/zsh
# ============================================================================
# TEST: teach deploy command
# ============================================================================
# Tests the teach deploy workflow including:
# - Config file detection (.flow/teach-config.yml)
# - Branch detection and switching
# - Config parsing (course name, branches)
# - Pre-flight checks
#
# Usage: ./tests/test-teach-deploy.zsh
# ============================================================================

setopt LOCAL_OPTIONS NO_NOTIFY NO_MONITOR

# ─────────────────────────────────────────────────────────────────────────────
# Test Framework
# ─────────────────────────────────────────────────────────────────────────────

typeset -i PASS=0 FAIL=0 SKIP=0
TEST_DIR=""
DEMO_COURSE="$HOME/projects/teaching/scholar-demo-course"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

test_pass() {
    echo "${GREEN}  ✓${RESET} $1"
    ((PASS++))
}

test_fail() {
    echo "${RED}  ✗${RESET} $1"
    [[ -n "$2" ]] && echo "    ${RED}→${RESET} $2"
    ((FAIL++))
}

test_skip() {
    echo "${YELLOW}  ⊘${RESET} $1 (skipped)"
    ((SKIP++))
}

section() {
    echo ""
    echo "${BLUE}━━━ $1 ━━━${RESET}"
}

# ─────────────────────────────────────────────────────────────────────────────
# Setup & Teardown
# ─────────────────────────────────────────────────────────────────────────────

setup() {
    # Source the plugin (handle both direct execution and sourcing)
    local script_dir="${0:A:h}"
    local plugin_file="$script_dir/../flow.plugin.zsh"

    if [[ ! -f "$plugin_file" ]]; then
        plugin_file="$HOME/projects/dev-tools/flow-cli/flow.plugin.zsh"
    fi

    source "$plugin_file" 2>/dev/null || {
        echo "${RED}ERROR: Failed to source flow.plugin.zsh${RESET}"
        echo "Tried: $plugin_file"
        exit 1
    }

    # Create temp test directory
    TEST_DIR=$(mktemp -d)
}

teardown() {
    # Cleanup temp directory
    [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

create_test_repo() {
    local dir="$1"
    mkdir -p "$dir"
    cd "$dir"
    git init > /dev/null 2>&1
    git config user.email "test@test.com"
    git config user.name "Test User"
    touch README.md
    git add README.md
    git commit -m "Initial commit" > /dev/null 2>&1
}

create_test_config() {
    local dir="$1"
    local draft_branch="${2:-draft}"
    local prod_branch="${3:-main}"

    mkdir -p "$dir/.flow"
    cat > "$dir/.flow/teach-config.yml" << YAML
course:
  name: "Test Course"
  semester: Spring
  year: 2026

branches:
  draft: $draft_branch
  production: $prod_branch

git:
  require_clean: true
  auto_pr: true

workflow:
  teaching_mode: false
  auto_push: false
YAML
}

# ─────────────────────────────────────────────────────────────────────────────
# Test Cases
# ─────────────────────────────────────────────────────────────────────────────

test_missing_config() {
    section "Scenario 1: Missing Config File"

    local test_repo="$TEST_DIR/no-config"
    create_test_repo "$test_repo"
    cd "$test_repo"

    # Test: Should detect missing config
    local output=$(teach deploy 2>&1)

    if echo "$output" | grep -q ".flow/teach-config.yml not found"; then
        test_pass "Detects missing .flow/teach-config.yml"
    else
        test_fail "Missing config detection" "Output: $output"
    fi

    if echo "$output" | grep -q "teach init"; then
        test_pass "Provides helpful hint (teach init)"
    else
        test_fail "Helpful hint missing" "Output: $output"
    fi

    # Verify no git fatal error
    if echo "$output" | grep -q "fatal: empty string"; then
        test_fail "Git fatal error should not appear"
    else
        test_pass "No git fatal error (regression check)"
    fi
}

test_config_in_flow_directory() {
    section "Scenario 2: Config in .flow/ Directory"

    local test_repo="$TEST_DIR/with-config"
    create_test_repo "$test_repo"
    create_test_config "$test_repo" "draft" "main"
    cd "$test_repo"

    # Create draft branch
    git checkout -b draft > /dev/null 2>&1

    # Test: Should find config and show pre-flight checks
    local output=$(echo "3" | teach deploy 2>&1)

    if echo "$output" | grep -q "Pre-flight Checks"; then
        test_pass "Config found in .flow/teach-config.yml"
    else
        test_fail "Config not found" "Output: $output"
    fi
}

test_branch_detection_correct() {
    section "Scenario 3: Branch Detection (Correct Branch)"

    local test_repo="$TEST_DIR/branch-test"
    create_test_repo "$test_repo"
    create_test_config "$test_repo" "draft" "main"
    cd "$test_repo"

    # Create and checkout draft branch
    git checkout -b draft > /dev/null 2>&1

    # Test: Should detect we're on draft branch
    local output=$(echo "3" | teach deploy 2>&1)

    if echo "$output" | grep -q "On draft branch"; then
        test_pass "Correctly identifies draft branch"
    else
        test_fail "Branch detection failed" "Output: $output"
    fi
}

test_branch_detection_wrong() {
    section "Scenario 4: Branch Detection (Wrong Branch)"

    local test_repo="$TEST_DIR/wrong-branch"
    create_test_repo "$test_repo"
    create_test_config "$test_repo" "draft" "main"
    cd "$test_repo"

    # Create draft but stay on main
    git checkout -b draft > /dev/null 2>&1
    git checkout main > /dev/null 2>&1

    # Test: Should detect wrong branch
    local output=$(echo "n" | teach deploy 2>&1 | head -15)

    if echo "$output" | grep -q "Not on draft branch"; then
        test_pass "Detects wrong branch"
    else
        test_fail "Wrong branch detection failed" "Output: $output"
    fi
}

test_config_parsing() {
    section "Scenario 5: Config Parsing"

    local test_repo="$TEST_DIR/config-parse"
    create_test_repo "$test_repo"
    create_test_config "$test_repo" "my-draft" "production"
    cd "$test_repo"

    # Test: Course name parsing
    local course_name=$(yq '.course.name' .flow/teach-config.yml 2>/dev/null)
    if [[ "$course_name" == "Test Course" ]]; then
        test_pass "Course name parsed: $course_name"
    else
        test_fail "Course name parsing" "Got: $course_name"
    fi

    # Test: Draft branch parsing (uses .branches.draft)
    local draft=$(yq '.branches.draft // .git.draft_branch // "draft"' .flow/teach-config.yml 2>/dev/null)
    if [[ "$draft" == "my-draft" ]]; then
        test_pass "Draft branch parsed: $draft"
    else
        test_fail "Draft branch parsing" "Got: $draft"
    fi

    # Test: Production branch parsing
    local prod=$(yq '.branches.production // .git.production_branch // "main"' .flow/teach-config.yml 2>/dev/null)
    if [[ "$prod" == "production" ]]; then
        test_pass "Production branch parsed: $prod"
    else
        test_fail "Production branch parsing" "Got: $prod"
    fi
}

test_not_git_repo() {
    section "Scenario 6: Not a Git Repository"

    local test_dir="$TEST_DIR/not-git"
    mkdir -p "$test_dir"
    cd "$test_dir"

    # Test: Should detect not in git repo
    local output=$(teach deploy 2>&1)

    if echo "$output" | grep -q "Not in a git repository"; then
        test_pass "Detects non-git directory"
    else
        test_fail "Git repo detection" "Output: $output"
    fi
}

test_demo_course_integration() {
    section "Scenario 7: Demo Course Integration"

    if [[ ! -d "$DEMO_COURSE/.git" ]]; then
        test_skip "Demo course not initialized as git repo"
        return
    fi

    if [[ ! -f "$DEMO_COURSE/.flow/teach-config.yml" ]]; then
        test_skip "Demo course missing .flow/teach-config.yml"
        return
    fi

    cd "$DEMO_COURSE"

    # Test: Config exists
    test_pass "Demo course has .flow/teach-config.yml"

    # Test: Course name
    local course=$(yq '.course.name' .flow/teach-config.yml 2>/dev/null)
    if [[ -n "$course" ]]; then
        test_pass "Demo course name: $course"
    else
        test_fail "Demo course name parsing"
    fi

    # Test: Branches config
    local draft=$(yq '.branches.draft // "draft"' .flow/teach-config.yml 2>/dev/null)
    local prod=$(yq '.branches.production // "main"' .flow/teach-config.yml 2>/dev/null)
    if [[ -n "$draft" && -n "$prod" ]]; then
        test_pass "Demo course branches: draft=$draft, prod=$prod"
    else
        test_fail "Demo course branch parsing"
    fi
}

test_fallback_defaults() {
    section "Scenario 8: Fallback Defaults"

    local test_repo="$TEST_DIR/minimal-config"
    create_test_repo "$test_repo"
    cd "$test_repo"

    # Create minimal config without branch settings
    mkdir -p .flow
    cat > .flow/teach-config.yml << 'YAML'
course:
  name: "Minimal Course"
YAML

    git checkout -b draft > /dev/null 2>&1

    # Test: Should use default "draft" branch
    local output=$(echo "3" | teach deploy 2>&1)

    if echo "$output" | grep -q "On draft branch"; then
        test_pass "Uses default draft branch when not specified"
    else
        test_fail "Default branch fallback" "Output: $output"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────

main() {
    echo "═══════════════════════════════════════════════════════════"
    echo " TEACH DEPLOY - TEST SUITE"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "Testing: _teach_deploy() function"
    echo "Config location: .flow/teach-config.yml"
    echo ""

    setup

    # Run test cases
    test_missing_config
    test_config_in_flow_directory
    test_branch_detection_correct
    test_branch_detection_wrong
    test_config_parsing
    test_not_git_repo
    test_demo_course_integration
    test_fallback_defaults

    teardown

    # Summary
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo " RESULTS"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "  ${GREEN}Passed:${RESET}  $PASS"
    echo "  ${RED}Failed:${RESET}  $FAIL"
    echo "  ${YELLOW}Skipped:${RESET} $SKIP"
    echo ""

    if [[ $FAIL -eq 0 ]]; then
        echo "${GREEN}✅ All tests passed!${RESET}"
        return 0
    else
        echo "${RED}❌ Some tests failed${RESET}"
        return 1
    fi
}

# Run if executed directly
if [[ "${(%):-%N}" == "$0" || "${0:A}" == "${(%):-%x:A}" ]]; then
    main "$@"
fi
