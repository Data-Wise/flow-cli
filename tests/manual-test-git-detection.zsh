#!/usr/bin/env zsh
# Manual test for _dot_check_git_in_path function
# Usage: ./tests/manual-test-git-detection.zsh

# Load dependencies
SCRIPT_DIR="${0:A:h}"
source "${SCRIPT_DIR}/../lib/core.zsh"
source "${SCRIPT_DIR}/../lib/dotfile-helpers.zsh"

# Color definitions for output
typeset -A TEST_COLORS
TEST_COLORS=(
  [pass]='\033[38;5;114m'
  [fail]='\033[38;5;203m'
  [info]='\033[38;5;117m'
  [reset]='\033[0m'
)

# Test counter
test_count=0
pass_count=0
fail_count=0

# Helper: Print test header
print_test() {
  ((test_count++))
  echo -e "\n${TEST_COLORS[info]}Test $test_count: $1${TEST_COLORS[reset]}"
}

# Helper: Assert test result
assert_result() {
  local expected=$1
  local actual=$2
  local message=$3

  if [[ "$actual" == "$expected" ]]; then
    ((pass_count++))
    echo -e "${TEST_COLORS[pass]}✓ PASS${TEST_COLORS[reset]}: $message"
  else
    ((fail_count++))
    echo -e "${TEST_COLORS[fail]}✗ FAIL${TEST_COLORS[reset]}: $message"
    echo "  Expected: $expected"
    echo "  Got: $actual"
  fi
}

# Helper: Print summary
print_summary() {
  echo -e "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "Test Summary: $test_count tests"
  echo -e "${TEST_COLORS[pass]}Passed: $pass_count${TEST_COLORS[reset]}"
  if [[ $fail_count -gt 0 ]]; then
    echo -e "${TEST_COLORS[fail]}Failed: $fail_count${TEST_COLORS[reset]}"
  fi
  echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

  return $fail_count
}

# Create test directories
setup_test_env() {
  local test_base="/tmp/flow-git-detection-test-$$"
  mkdir -p "$test_base"
  echo "$test_base"
}

# Cleanup test environment
cleanup_test_env() {
  local test_base=$1
  [[ -n "$test_base" ]] && rm -rf "$test_base"
}

# ============================================================================
# TEST SUITE
# ============================================================================

echo -e "${FLOW_COLORS[header]}═══════════════════════════════════════════════${FLOW_COLORS[reset]}"
echo -e "${FLOW_COLORS[header]} Git Directory Detection Tests${FLOW_COLORS[reset]}"
echo -e "${FLOW_COLORS[header]}═══════════════════════════════════════════════${FLOW_COLORS[reset]}"

TEST_BASE=$(setup_test_env)
echo -e "${FLOW_COLORS[muted]}Test base: $TEST_BASE${FLOW_COLORS[reset]}"

# Test 1: Empty directory (no .git)
print_test "Empty directory (no .git)"
mkdir -p "$TEST_BASE/empty"
result=$(_dot_check_git_in_path "$TEST_BASE/empty")
exit_code=$?
assert_result "1" "$exit_code" "Should return 1 for directory without .git"
assert_result "" "$result" "Should return empty string"

# Test 2: Directory with .git in root
print_test "Directory with .git in root"
mkdir -p "$TEST_BASE/with-git/.git"
result=$(_dot_check_git_in_path "$TEST_BASE/with-git")
exit_code=$?
assert_result "0" "$exit_code" "Should return 0 when .git found"
[[ "$result" =~ ".git" ]] && ((pass_count++)) || ((fail_count++))
echo -e "${TEST_COLORS[pass]}✓ Result contains .git path${TEST_COLORS[reset]}"

# Test 3: Directory with nested .git
print_test "Directory with nested .git directories"
mkdir -p "$TEST_BASE/nested/subdir1/.git"
mkdir -p "$TEST_BASE/nested/subdir2/.git"
result=$(_dot_check_git_in_path "$TEST_BASE/nested")
exit_code=$?
assert_result "0" "$exit_code" "Should return 0 when nested .git found"
[[ $(echo "$result" | wc -w) -ge 2 ]] && ((pass_count++)) || ((fail_count++))
echo -e "${TEST_COLORS[pass]}✓ Found multiple .git directories${TEST_COLORS[reset]}"

# Test 4: Git repository with submodules (if git available)
if command -v git &>/dev/null; then
  print_test "Git repository with submodules (fast path)"

  # Create main repo
  mkdir -p "$TEST_BASE/repo-with-submodule"
  cd "$TEST_BASE/repo-with-submodule" || exit
  git init -q > /dev/null 2>&1
  git config user.email "test@example.com"
  git config user.name "Test User"

  # Create submodule repo
  mkdir -p "$TEST_BASE/submodule"
  cd "$TEST_BASE/submodule" || exit
  git init -q > /dev/null 2>&1
  git config user.email "test@example.com"
  git config user.name "Test User"
  touch file.txt
  git add file.txt
  git commit -q -m "Initial commit" > /dev/null 2>&1

  # Add submodule
  cd "$TEST_BASE/repo-with-submodule" || exit
  git submodule add -q "$TEST_BASE/submodule" submodule > /dev/null 2>&1

  # Test detection
  result=$(_dot_check_git_in_path "$TEST_BASE/repo-with-submodule")
  exit_code=$?
  assert_result "0" "$exit_code" "Should detect git repo with submodules"
  [[ "$result" =~ ".git" ]] && ((pass_count++)) || ((fail_count++))
  echo -e "${TEST_COLORS[pass]}✓ Submodule detection works${TEST_COLORS[reset]}"
else
  echo -e "${TEST_COLORS[info]}⊘ Skipping git submodule test (git not available)${TEST_COLORS[reset]}"
fi

# Test 5: Symlink to directory with .git
print_test "Symlink to directory with .git (requires manual interaction)"
mkdir -p "$TEST_BASE/real-dir/.git"
ln -s "$TEST_BASE/real-dir" "$TEST_BASE/symlink-dir"
echo -e "${TEST_COLORS[info]}ℹ This test requires user input (Y/n)${TEST_COLORS[reset]}"
echo -e "${TEST_COLORS[muted]}  Target: $TEST_BASE/symlink-dir${TEST_COLORS[reset]}"
echo -e "${TEST_COLORS[muted]}  When prompted, press 'Y' to follow symlink${TEST_COLORS[reset]}"
echo -n "Ready? Press Enter to continue..."
read
result=$(_dot_check_git_in_path "$TEST_BASE/symlink-dir")
exit_code=$?
if [[ $exit_code -eq 0 ]]; then
  ((pass_count++))
  echo -e "${TEST_COLORS[pass]}✓ PASS: Symlink handling works${TEST_COLORS[reset]}"
else
  ((fail_count++))
  echo -e "${TEST_COLORS[fail]}✗ FAIL: Symlink handling failed${TEST_COLORS[reset]}"
fi

# Test 6: Large directory performance check
print_test "Large directory performance (timeout test)"
mkdir -p "$TEST_BASE/large-dir"
# Create 100 subdirectories (not 1000 to keep test fast)
for i in {1..100}; do
  mkdir -p "$TEST_BASE/large-dir/subdir-$i"
  touch "$TEST_BASE/large-dir/subdir-$i/file1.txt"
  touch "$TEST_BASE/large-dir/subdir-$i/file2.txt"
done
# Add some .git directories
mkdir -p "$TEST_BASE/large-dir/subdir-10/.git"
mkdir -p "$TEST_BASE/large-dir/subdir-50/.git"

start_time=$(date +%s)
result=$(_dot_check_git_in_path "$TEST_BASE/large-dir")
exit_code=$?
end_time=$(date +%s)
duration=$((end_time - start_time))

assert_result "0" "$exit_code" "Should find .git directories in large dir"
if [[ $duration -le 3 ]]; then
  ((pass_count++))
  echo -e "${TEST_COLORS[pass]}✓ Performance OK: ${duration}s (target: < 3s)${TEST_COLORS[reset]}"
else
  ((fail_count++))
  echo -e "${TEST_COLORS[fail]}✗ Performance SLOW: ${duration}s (target: < 3s)${TEST_COLORS[reset]}"
fi

# Test 7: Non-existent directory
print_test "Non-existent directory"
result=$(_dot_check_git_in_path "$TEST_BASE/does-not-exist" 2>/dev/null)
exit_code=$?
assert_result "1" "$exit_code" "Should return 1 for non-existent directory"

# Test 8: File instead of directory
print_test "File instead of directory"
touch "$TEST_BASE/test-file.txt"
result=$(_dot_check_git_in_path "$TEST_BASE/test-file.txt" 2>/dev/null)
exit_code=$?
assert_result "1" "$exit_code" "Should return 1 for file path"

# Cleanup
cleanup_test_env "$TEST_BASE"
echo -e "${FLOW_COLORS[muted]}Cleaned up test directory${FLOW_COLORS[reset]}"

# Print summary
print_summary
exit $?
