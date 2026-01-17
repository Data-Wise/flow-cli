#!/usr/bin/env zsh
# Simplified Integration Test for Teaching-Git Integration
# Tests critical functionality without complex test harness

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
PASSED=0
FAILED=0

test_pass() {
    echo "${GREEN}✓${NC} $1"
    ((PASSED++))
}

test_fail() {
    echo "${RED}✗${NC} $1"
    ((FAILED++))
}

echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "${BLUE}Teaching-Git Integration: Simple Tests${NC}"
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Setup
FLOW_ROOT="/Users/dt/.git-worktrees/flow-cli/teaching-git-integration"
TEST_ROOT=$(mktemp -d)
echo "\n${BLUE}Test environment:${NC} $TEST_ROOT\n"

# Source flow-cli
export FLOW_QUIET=1
cd /tmp  # Start in neutral location
source "$FLOW_ROOT/flow.plugin.zsh" >/dev/null 2>&1 || {
    echo "${RED}Failed to source flow.plugin.zsh${NC}"
    exit 1
}

# ============================================================================
# TEST 1: Git Helper Functions Exist
# ============================================================================
echo "${BLUE}TEST 1: Git Helper Functions${NC}"

if type _git_teaching_commit_message >/dev/null 2>&1; then
    test_pass "Function _git_teaching_commit_message exists"
else
    test_fail "Function _git_teaching_commit_message missing"
fi

if type _git_teaching_files >/dev/null 2>&1; then
    test_pass "Function _git_teaching_files exists"
else
    test_fail "Function _git_teaching_files missing"
fi

if type _git_create_deploy_pr >/dev/null 2>&1; then
    test_pass "Function _git_create_deploy_pr exists"
else
    test_fail "Function _git_create_deploy_pr missing"
fi

# ============================================================================
# TEST 2: teach-init --no-git Flag
# ============================================================================
echo "\n${BLUE}TEST 2: teach-init --no-git${NC}"

TEST_DIR="$TEST_ROOT/test-no-git"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

OUTPUT=$(teach-init --no-git -y "TEST 101" 2>&1)

if echo "$OUTPUT" | grep -q "Skipping git initialization"; then
    test_pass "teach-init --no-git skips git"
else
    test_fail "teach-init --no-git should skip git"
fi

if [[ ! -d .git ]]; then
    test_pass "No .git directory created"
else
    test_fail ".git should not exist with --no-git"
fi

if [[ -f .flow/teach-config.yml ]]; then
    test_pass "teach-config.yml created"
else
    test_fail "teach-config.yml not created"
fi

# ============================================================================
# TEST 3: .gitignore Template
# ============================================================================
echo "\n${BLUE}TEST 3: .gitignore Template${NC}"

GITIGNORE_TEMPLATE="$FLOW_ROOT/lib/templates/teaching/teaching.gitignore"

if [[ -f "$GITIGNORE_TEMPLATE" ]]; then
    test_pass ".gitignore template exists"

    # Check for key patterns
    if grep -q "/.quarto/" "$GITIGNORE_TEMPLATE" && \
       grep -q "**/solutions/" "$GITIGNORE_TEMPLATE" && \
       grep -q ".DS_Store" "$GITIGNORE_TEMPLATE"; then
        test_pass ".gitignore has key patterns"
    else
        test_fail ".gitignore missing key patterns"
    fi
else
    test_fail ".gitignore template not found"
fi

# ============================================================================
# TEST 4: Commit Message Generation
# ============================================================================
echo "\n${BLUE}TEST 4: Commit Message Generation${NC}"

# Source git helpers directly
source "$FLOW_ROOT/lib/git-helpers.zsh"

COMMIT_MSG=$(_git_teaching_commit_message "exam" "Midterm" "teach exam Midterm" "STAT 545" "Fall" "2024")

if echo "$COMMIT_MSG" | grep -q "teach: add exam for Midterm"; then
    test_pass "Commit message has correct format"
else
    test_fail "Commit message format incorrect"
fi

if echo "$COMMIT_MSG" | grep -q "STAT 545 (Fall 2024)"; then
    test_pass "Commit message has course context"
else
    test_fail "Commit message missing course context"
fi

if echo "$COMMIT_MSG" | grep -q "Co-Authored-By: Scholar"; then
    test_pass "Commit message has Scholar co-authorship"
else
    test_fail "Commit message missing Scholar co-authorship"
fi

# ============================================================================
# TEST 5: Teaching File Detection
# ============================================================================
echo "\n${BLUE}TEST 5: Teaching File Detection${NC}"

TEST_REPO="$TEST_ROOT/test-files"
mkdir -p "$TEST_REPO"/{exams,slides,assignments}
cd "$TEST_REPO"

git init -q
git config user.name "Test"
git config user.email "test@test.com"

# Create teaching files
echo "exam content" > exams/exam01.qmd
echo "slides content" > slides/week03.qmd
echo "assignment content" > assignments/hw01.qmd
echo "random content" > random.txt

# Test filtering
TEACHING_FILES=$(_git_teaching_files)

if echo "$TEACHING_FILES" | grep -q "exams/exam01.qmd"; then
    test_pass "Detects exam files"
else
    test_fail "Failed to detect exam files"
fi

if echo "$TEACHING_FILES" | grep -q "slides/week03.qmd"; then
    test_pass "Detects slide files"
else
    test_fail "Failed to detect slide files"
fi

if ! echo "$TEACHING_FILES" | grep -q "random.txt"; then
    test_pass "Filters non-teaching files"
else
    test_fail "Should not include random.txt"
fi

# ============================================================================
# TEST 6: Teaching Mode Configuration
# ============================================================================
echo "\n${BLUE}TEST 6: Teaching Mode Config${NC}"

TEST_CONFIG="$TEST_ROOT/test-config"
mkdir -p "$TEST_CONFIG/.flow"
cd "$TEST_CONFIG"

cat > .flow/teach-config.yml <<'EOF'
course:
  name: "TEST 103"
workflow:
  teaching_mode: true
  auto_commit: true
  auto_push: false
EOF

if command -v yq >/dev/null 2>&1; then
    TEACHING_MODE=$(yq '.workflow.teaching_mode // false' .flow/teach-config.yml)
    AUTO_COMMIT=$(yq '.workflow.auto_commit // false' .flow/teach-config.yml)

    if [[ "$TEACHING_MODE" == "true" ]]; then
        test_pass "Teaching mode reads correctly"
    else
        test_fail "Teaching mode should be true"
    fi

    if [[ "$AUTO_COMMIT" == "true" ]]; then
        test_pass "Auto-commit reads correctly"
    else
        test_fail "Auto-commit should be true"
    fi
else
    echo "${BLUE}⚠${NC} yq not installed - skipping config tests"
fi

# ============================================================================
# SUMMARY
# ============================================================================
echo "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "${BLUE}TEST SUMMARY${NC}"
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "\nPassed: ${GREEN}$PASSED${NC}"
echo "Failed: ${RED}$FAILED${NC}"

# Cleanup
cd /tmp
rm -rf "$TEST_ROOT"
echo "\n${BLUE}Test environment cleaned up${NC}\n"

if [[ $FAILED -gt 0 ]]; then
    exit 1
else
    exit 0
fi
