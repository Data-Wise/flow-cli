#!/usr/bin/env zsh
# Test Phase 4: Teaching Mode Auto-Commit Workflow
# Tests configuration reading and workflow selection logic

# Setup test environment
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR" || exit 1

# Initialize git repo
git init -q
git config user.name "Test User"
git config user.email "test@example.com"

# Source the required files
source_files() {
    local flow_root="/Users/dt/.git-worktrees/flow-cli/teaching-git-integration"

    # Source core helpers
    source "$flow_root/lib/core.zsh" 2>/dev/null || {
        echo "❌ Failed to source lib/core.zsh"
        return 1
    }

    # Source git helpers
    source "$flow_root/lib/git-helpers.zsh" 2>/dev/null || {
        echo "❌ Failed to source lib/git-helpers.zsh"
        return 1
    }

    return 0
}

# Test 1: Workflow configuration reading
test_config_reading() {
    echo "\n📝 Test 1: Configuration Reading"
    echo "─────────────────────────────────"

    # Create test config with teaching mode enabled
    cat > teach-config.yml <<EOF
course:
  name: "TEST 101"
  semester: "Fall"
  year: 2024

git:
  draft_branch: "draft"
  production_branch: "main"
  auto_pr: true
  require_clean: true

workflow:
  teaching_mode: true
  auto_commit: true
  auto_push: false
EOF

    # Test reading configuration
    local teaching_mode=$(yq '.workflow.teaching_mode // false' teach-config.yml 2>/dev/null)
    local auto_commit=$(yq '.workflow.auto_commit // false' teach-config.yml 2>/dev/null)
    local auto_push=$(yq '.workflow.auto_push // false' teach-config.yml 2>/dev/null)

    if [[ "$teaching_mode" == "true" && "$auto_commit" == "true" && "$auto_push" == "false" ]]; then
        echo "✅ Configuration reading works correctly"
        echo "   teaching_mode=$teaching_mode, auto_commit=$auto_commit, auto_push=$auto_push"
        return 0
    else
        echo "❌ Configuration reading failed"
        echo "   teaching_mode=$teaching_mode, auto_commit=$auto_commit, auto_push=$auto_push"
        return 1
    fi
}

# Test 2: Default values when config is missing
test_default_values() {
    echo "\n📝 Test 2: Default Values"
    echo "─────────────────────────────────"

    # Create minimal config without workflow section
    cat > teach-config.yml <<EOF
course:
  name: "TEST 101"
EOF

    # Test default values
    local teaching_mode=$(yq '.workflow.teaching_mode // false' teach-config.yml 2>/dev/null)
    local auto_commit=$(yq '.workflow.auto_commit // false' teach-config.yml 2>/dev/null)
    local auto_push=$(yq '.workflow.auto_push // false' teach-config.yml 2>/dev/null)

    if [[ "$teaching_mode" == "false" && "$auto_commit" == "false" && "$auto_push" == "false" ]]; then
        echo "✅ Default values work correctly (all false)"
        return 0
    else
        echo "❌ Default values incorrect"
        echo "   teaching_mode=$teaching_mode, auto_commit=$auto_commit, auto_push=$auto_push"
        return 1
    fi
}

# Test 3: Teaching mode disabled
test_teaching_mode_disabled() {
    echo "\n📝 Test 3: Teaching Mode Disabled"
    echo "─────────────────────────────────"

    # Create config with teaching mode disabled
    cat > teach-config.yml <<EOF
course:
  name: "TEST 101"

workflow:
  teaching_mode: false
  auto_commit: false
  auto_push: false
EOF

    local teaching_mode=$(yq '.workflow.teaching_mode // false' teach-config.yml 2>/dev/null)

    if [[ "$teaching_mode" == "false" ]]; then
        echo "✅ Teaching mode correctly disabled"
        return 0
    else
        echo "❌ Teaching mode should be disabled"
        return 1
    fi
}

# Test 4: Git helper functions availability
test_git_helpers() {
    echo "\n📝 Test 4: Git Helper Functions"
    echo "─────────────────────────────────"

    local missing_functions=()

    # Check for required functions
    local required_functions=(
        "_git_in_repo"
        "_git_current_branch"
        "_git_is_clean"
        "_git_has_unpushed_commits"
        "_git_teaching_commit_message"
        "_git_commit_teaching_content"
        "_git_push_current_branch"
    )

    for func in "${required_functions[@]}"; do
        if ! typeset -f "$func" >/dev/null 2>&1; then
            missing_functions+=("$func")
        fi
    done

    if [[ ${#missing_functions[@]} -eq 0 ]]; then
        echo "✅ All git helper functions are defined"
        return 0
    else
        echo "❌ Missing functions: ${missing_functions[*]}"
        return 1
    fi
}

# Test 5: Commit message generation
test_commit_message() {
    echo "\n📝 Test 5: Commit Message Generation"
    echo "─────────────────────────────────"

    local message=$(_git_teaching_commit_message "exam" "Test Topic" "teach exam \"Test Topic\"" "TEST 101" "Fall" "2024")

    # Check for key components using grep (works better with multi-line strings)
    if echo "$message" | grep -q "teach: add exam for Test Topic" && \
       echo "$message" | grep -q "TEST 101 (Fall 2024)" && \
       echo "$message" | grep -q "Co-Authored-By: Scholar"; then
        echo "✅ Commit message generation works correctly"
        return 0
    else
        echo "❌ Commit message generation failed"
        echo "Generated message:"
        echo "$message"
        return 1
    fi
}

# Main test runner
main() {
    echo "\n🧪 Phase 4 Teaching Mode Tests"
    echo "═══════════════════════════════════════════════"

    # Check dependencies
    if ! command -v yq >/dev/null 2>&1; then
        echo "❌ yq not found - install with: brew install yq"
        exit 1
    fi

    # Source required files
    if ! source_files; then
        echo "❌ Failed to source required files"
        exit 1
    fi

    # Run tests
    local failed=0

    test_config_reading || ((failed++))
    test_default_values || ((failed++))
    test_teaching_mode_disabled || ((failed++))
    test_git_helpers || ((failed++))
    test_commit_message || ((failed++))

    # Summary
    echo "\n═══════════════════════════════════════════════"
    if [[ $failed -eq 0 ]]; then
        echo "✅ All tests passed!"
        echo "\n✨ Phase 4 is ready for integration testing"
    else
        echo "❌ $failed test(s) failed"
        echo "\n⚠️  Fix failing tests before proceeding"
    fi
    echo "═══════════════════════════════════════════════\n"

    # Cleanup
    cd /tmp || exit 1
    rm -rf "$TEST_DIR"

    return $failed
}

# Run tests
main
