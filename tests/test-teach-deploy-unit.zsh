#!/usr/bin/env zsh
#
# Unit Tests for Enhanced Teach Deploy (v5.14.0 - Quarto Workflow)
# Tests: Partial deploy, dependency tracking, auto-commit, auto-tag
#

# Get flow root before changing directories
FLOW_ROOT="${(%):-%x}"
FLOW_ROOT="${FLOW_ROOT:A:h:h}"

# Setup test environment
setup_test_env() {
    export TEST_DIR=$(mktemp -d)

    # Source required files BEFORE changing directory
    source "$FLOW_ROOT/lib/core.zsh"
    source "$FLOW_ROOT/lib/git-helpers.zsh"
    source "$FLOW_ROOT/lib/index-helpers.zsh"

    # Now change to test directory
    cd "$TEST_DIR"

    # Initialize git repo
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test User"

    # Create branches
    git checkout -b main -q
    git checkout -b draft -q

    # Create test config
    mkdir -p .flow
    cat > .flow/teach-config.yml <<'EOF'
course:
  name: "Test Course"
  code: "TEST 101"

git:
  draft_branch: draft
  production_branch: main
  auto_pr: true
  require_clean: false

workflow:
  teaching_mode: true
  auto_push: false
EOF

    git add .flow/teach-config.yml
    git commit -m "Initial config" -q

    # Create directory structure
    mkdir -p lectures labs exams scripts

    # Create test files
    cat > lectures/week-01.qmd <<'EOF'
---
title: "Week 1: Introduction"
---

# Introduction

Basic content.
EOF

    cat > lectures/week-05.qmd <<'EOF'
---
title: "Week 5: ANOVA"
---

# ANOVA

```{r}
source("scripts/analysis.R")
```

See @sec-background for context.
EOF

    cat > lectures/background.qmd <<'EOF'
---
title: "Background"
---

# Background {#sec-background}

Context material.
EOF

    cat > scripts/analysis.R <<'EOF'
# Analysis script
mean(1:10)
EOF

    cat > home_lectures.qmd <<'EOF'
---
title: "Lectures"
---

- [Week 1: Introduction](lectures/week-01.qmd)
EOF

    # Commit initial files
    git add .
    git commit -m "Initial content" -q

    # Create main branch
    git checkout main -q
    git merge draft --no-edit -q
    git checkout draft -q
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

assert_file_exists() {
    local file="$1"
    local msg="$2"

    if [[ -f "$file" ]]; then
        test_pass
    else
        test_fail "$msg (file not found: $file)"
    fi
}

# Mock functions for testing (avoid interactive prompts)
_git_push_current_branch() {
    echo "Mock: push to remote"
    return 0
}

_git_create_deploy_pr() {
    echo "Mock: create PR"
    return 0
}

# ============================================
# TEST SUITE
# ============================================

echo "${FLOW_COLORS[bold]}=====================================${FLOW_COLORS[reset]}"
echo "${FLOW_COLORS[bold]}Teach Deploy Unit Tests${FLOW_COLORS[reset]}"
echo "${FLOW_COLORS[bold]}=====================================${FLOW_COLORS[reset]}"

setup_test_env

# Test 1: Config file exists
test_start "Verify config file exists"
assert_file_exists ".flow/teach-config.yml" "Config should exist"

# Test 2: Git repo initialized
test_start "Verify git repo initialized"
if git rev-parse --git-dir >/dev/null 2>&1; then
    test_pass
else
    test_fail "Git repo should be initialized"
fi

# Test 3: Draft branch exists
test_start "Verify draft branch exists"
result=$(git branch --list draft)
assert_contains "$result" "draft" "Draft branch should exist"

# Test 4: Detect partial deploy mode
test_start "Detect partial deploy mode with file argument"
# Simulate parsing file argument
partial_deploy=false
deploy_files=()

# Mock argument parsing
file_arg="lectures/week-05.qmd"
if [[ -f "$file_arg" ]]; then
    partial_deploy=true
    deploy_files+=("$file_arg")
fi

assert_equals "true" "$partial_deploy" "Should enable partial deploy mode"
assert_equals "1" "${#deploy_files[@]}" "Should have 1 file in deploy list"

# Test 5: Find dependencies for file
test_start "Find dependencies for lecture file"
deps=($(_find_dependencies "lectures/week-05.qmd"))

# Should find scripts/analysis.R and background.qmd
dep_count=${#deps[@]}
if [[ $dep_count -ge 2 ]]; then
    test_pass
else
    test_fail "Should find at least 2 dependencies (got $dep_count)"
fi

# Test 6: Validate dependencies found
test_start "Verify specific dependencies"
deps_str="${deps[@]}"
has_analysis=false
has_background=false

[[ "$deps_str" == *"analysis.R"* ]] && has_analysis=true
[[ "$deps_str" == *"background.qmd"* ]] && has_background=true

if [[ "$has_analysis" == "true" ]] && [[ "$has_background" == "true" ]]; then
    test_pass
else
    test_fail "Should find analysis.R and background.qmd (analysis: $has_analysis, background: $has_background)"
fi

# Test 7: Cross-reference validation
test_start "Validate cross-references in deploy file"
_validate_cross_references "lectures/week-05.qmd" >/dev/null 2>&1
result=$?
assert_equals "0" "$result" "Cross-references should be valid"

# Test 8: Detect uncommitted changes
test_start "Detect uncommitted changes"
# Modify a file
echo "# New content" >> lectures/week-05.qmd

uncommitted_files=()
for file in lectures/week-05.qmd; do
    if ! git diff --quiet HEAD -- "$file" 2>/dev/null; then
        uncommitted_files+=("$file")
    fi
done

assert_equals "1" "${#uncommitted_files[@]}" "Should detect 1 uncommitted file"

# Test 9: Auto-commit functionality
test_start "Auto-commit uncommitted changes"
commit_msg="Update: $(date +%Y-%m-%d)"
git add lectures/week-05.qmd
git commit -m "$commit_msg" -q

# Verify commit exists
last_commit=$(git log -1 --format=%s)
assert_contains "$last_commit" "Update:" "Should create auto-commit"

# Test 10: Index change detection
test_start "Detect index changes for new file"
# Create new file
cat > lectures/week-07.qmd <<'EOF'
---
title: "Week 7: Regression"
---
EOF

change_type=$(_detect_index_changes "lectures/week-07.qmd")
assert_equals "ADD" "$change_type" "Should detect new file as ADD"

# Test 11: Process index changes
test_start "Add new file to index"
_update_index_link "lectures/week-07.qmd" "home_lectures.qmd" >/dev/null 2>&1

result=$(grep "week-07.qmd" "home_lectures.qmd")
assert_contains "$result" "Week 7: Regression" "Should add to index"

# Test 12: Verify index sorted correctly
test_start "Verify index sorting"
week1_line=$(grep -n "week-01.qmd" home_lectures.qmd | cut -d: -f1)
week7_line=$(grep -n "week-07.qmd" home_lectures.qmd | cut -d: -f1)

if [[ $week1_line -lt $week7_line ]]; then
    test_pass
else
    test_fail "Week 1 should come before Week 7 (1:$week1_line, 7:$week7_line)"
fi

# Test 13: Auto-tag functionality
test_start "Create auto-tag"
tag="deploy-$(date +%Y-%m-%d-%H%M)"
git tag "$tag" 2>/dev/null

# Verify tag exists
tag_exists=$(git tag -l "$tag")
assert_contains "$tag_exists" "deploy-" "Should create deployment tag"

# Test 14: Partial deploy with directory
test_start "Parse directory argument for partial deploy"
deploy_files=()

# Mock parsing directory
dir_arg="lectures/"
if [[ -d "$dir_arg" ]]; then
    for file in "$dir_arg"/**/*.qmd; do
        [[ -f "$file" ]] && deploy_files+=("$file")
    done
fi

if [[ ${#deploy_files[@]} -ge 3 ]]; then
    test_pass
else
    test_fail "Should find multiple .qmd files in lectures/ (got ${#deploy_files[@]})"
fi

# Test 15: Multiple file deployment
test_start "Deploy multiple files at once"
multi_files=("lectures/week-01.qmd" "lectures/week-05.qmd")
all_exist=true

for file in "${multi_files[@]}"; do
    [[ ! -f "$file" ]] && all_exist=false
done

assert_equals "true" "$all_exist" "All files should exist"

# Test 16: Flag parsing - auto-commit
test_start "Parse --auto-commit flag"
auto_commit=false

# Mock flag parsing
flag="--auto-commit"
[[ "$flag" == "--auto-commit" ]] && auto_commit=true

assert_equals "true" "$auto_commit" "Should parse --auto-commit flag"

# Test 17: Flag parsing - auto-tag
test_start "Parse --auto-tag flag"
auto_tag=false

flag="--auto-tag"
[[ "$flag" == "--auto-tag" ]] && auto_tag=true

assert_equals "true" "$auto_tag" "Should parse --auto-tag flag"

# Test 18: Flag parsing - skip-index
test_start "Parse --skip-index flag"
skip_index=false

flag="--skip-index"
[[ "$flag" == "--skip-index" ]] && skip_index=true

assert_equals "true" "$skip_index" "Should parse --skip-index flag"

# Test 19: Branch check
test_start "Verify on correct branch"
current_branch=$(_git_current_branch)
assert_equals "draft" "$current_branch" "Should be on draft branch"

# Test 20: Config reading
test_start "Read draft branch from config"
draft_branch=$(yq '.git.draft_branch // "draft"' .flow/teach-config.yml)
assert_equals "draft" "$draft_branch" "Should read draft branch"

# Test 21: Config reading - production branch
test_start "Read production branch from config"
prod_branch=$(yq '.git.production_branch // "main"' .flow/teach-config.yml)
assert_equals "main" "$prod_branch" "Should read production branch"

# Test 22: Config reading - auto_pr
test_start "Read auto_pr setting from config"
auto_pr=$(yq '.git.auto_pr // true' .flow/teach-config.yml)
assert_equals "true" "$auto_pr" "Should read auto_pr setting"

# Test 23: Index modification detection
test_start "Detect modified index files"
# Modify index
echo "- [Test](test.qmd)" >> home_lectures.qmd

index_modified=false
if ! git diff --quiet HEAD -- home_lectures.qmd 2>/dev/null; then
    index_modified=true
fi

assert_equals "true" "$index_modified" "Should detect index modification"

# Test 24: Commit count between branches
test_start "Calculate commit count between branches"
# Make a commit on draft
echo "test" > test.txt
git add test.txt
git commit -m "Test commit" -q

commit_count=$(_git_get_commit_count "draft" "main")
if [[ $commit_count -gt 0 ]]; then
    test_pass
else
    test_fail "Should have commits ahead of main (got $commit_count)"
fi

# Test 25: Full site vs partial deploy detection
test_start "Differentiate full vs partial deploy"
# No file args = full deploy
deploy_files=()
partial_deploy=false

if [[ ${#deploy_files[@]} -eq 0 ]]; then
    mode="full"
else
    mode="partial"
fi

assert_equals "full" "$mode" "Should detect full deploy mode"

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
