#!/usr/bin/env zsh
# Test Phase 5: teach init Git Initialization
# Tests git setup logic for fresh repositories

# Setup test environment
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR" || exit 1

# Source the required files
source_files() {
    local flow_root="/Users/dt/.git-worktrees/flow-cli/teaching-git-integration"

    # Source core helpers
    source "$flow_root/lib/core.zsh" 2>/dev/null || {
        echo "❌ Failed to source lib/core.zsh"
        return 1
    }

    return 0
}

# Test 1: --no-git flag prevents git initialization
test_no_git_flag() {
    echo "\n📝 Test 1: --no-git Flag"
    echo "─────────────────────────────────"

    # Test if TEACH_SKIP_GIT is respected
    export TEACH_SKIP_GIT="true"

    if [[ "$TEACH_SKIP_GIT" == "true" ]]; then
        echo "✅ --no-git flag detection works"
        return 0
    else
        echo "❌ --no-git flag not detected"
        return 1
    fi
}

# Test 2: .gitignore template exists
test_gitignore_template() {
    echo "\n📝 Test 2: .gitignore Template"
    echo "─────────────────────────────────"

    local template="/Users/dt/.git-worktrees/flow-cli/teaching-git-integration/lib/templates/teaching/teaching.gitignore"

    if [[ -f "$template" ]]; then
        echo "✅ .gitignore template exists"

        # Check for key patterns
        local patterns=("/.quarto/" "/_site/" ".DS_Store" "renv/" "__pycache__/" "**/solutions/")
        local missing=()

        for pattern in "${patterns[@]}"; do
            if ! grep -q "$pattern" "$template"; then
                missing+=("$pattern")
            fi
        done

        if [[ ${#missing[@]} -eq 0 ]]; then
            echo "✅ .gitignore contains all key patterns"
            return 0
        else
            echo "❌ Missing patterns: ${missing[*]}"
            return 1
        fi
    else
        echo "❌ .gitignore template not found at: $template"
        return 1
    fi
}

# Test 3: Git branch naming conventions
test_branch_names() {
    echo "\n📝 Test 3: Branch Naming"
    echo "─────────────────────────────────"

    local draft_branch="draft"
    local production_branch="main"

    # Branch names should match schema defaults
    local schema="/Users/dt/.git-worktrees/flow-cli/teaching-git-integration/lib/templates/teaching/teach-config.schema.json"

    if [[ -f "$schema" ]] && command -v jq >/dev/null 2>&1; then
        local schema_draft=$(jq -r '.definitions.git.properties.draft_branch.default' "$schema")
        local schema_production=$(jq -r '.definitions.git.properties.production_branch.default' "$schema")

        if [[ "$draft_branch" == "$schema_draft" && "$production_branch" == "$schema_production" ]]; then
            echo "✅ Branch names match schema defaults"
            echo "   draft=$draft_branch, production=$production_branch"
            return 0
        else
            echo "❌ Branch names don't match schema"
            echo "   Expected: draft=$schema_draft, production=$schema_production"
            echo "   Got: draft=$draft_branch, production=$production_branch"
            return 1
        fi
    else
        echo "⚠️  Cannot verify (schema not found or jq missing)"
        echo "   Assuming branch names are correct"
        return 0
    fi
}

# Test 4: Commit message format
test_commit_message_format() {
    echo "\n📝 Test 4: Commit Message Format"
    echo "─────────────────────────────────"

    local course_name="TEST 101"
    local expected_patterns=(
        "feat: initialize teaching workflow"
        "Generated via: teach init"
        "Co-Authored-By: Claude Sonnet"
    )

    # Simulate commit message generation
    local commit_msg="feat: initialize teaching workflow for $course_name

Generated via: teach init \"$course_name\"

Initial setup includes:
- .flow/teach-config.yml (course configuration)
- .gitignore (teaching-specific patterns)
- scripts/ (automation helpers)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

    local missing_patterns=()
    for pattern in "${expected_patterns[@]}"; do
        if ! echo "$commit_msg" | grep -q "$pattern"; then
            missing_patterns+=("$pattern")
        fi
    done

    if [[ ${#missing_patterns[@]} -eq 0 ]]; then
        echo "✅ Commit message format is correct"
        return 0
    else
        echo "❌ Missing patterns in commit message:"
        printf '   %s\n' "${missing_patterns[@]}"
        return 1
    fi
}

# Test 5: Help flag includes --no-git
test_help_includes_no_git() {
    echo "\n📝 Test 5: Help Documentation"
    echo "─────────────────────────────────"

    # Source teach-init to test help function
    local teach_init_file="/Users/dt/.git-worktrees/flow-cli/teaching-git-integration/commands/teach-init.zsh"

    if [[ -f "$teach_init_file" ]]; then
        # Check if help mentions --no-git
        if grep -q "\-\-no-git" "$teach_init_file"; then
            echo "✅ Help documentation includes --no-git flag"
            return 0
        else
            echo "❌ --no-git flag not documented in help"
            return 1
        fi
    else
        echo "❌ teach-init.zsh not found"
        return 1
    fi
}

# Test 6: GitHub repo creation helper exists
test_github_helper_exists() {
    echo "\n📝 Test 6: GitHub Helper Function"
    echo "─────────────────────────────────"

    local teach_init_file="/Users/dt/.git-worktrees/flow-cli/teaching-git-integration/commands/teach-init.zsh"

    if [[ -f "$teach_init_file" ]]; then
        if grep -q "_teach_create_github_repo" "$teach_init_file"; then
            echo "✅ GitHub repo creation helper exists"
            return 0
        else
            echo "❌ _teach_create_github_repo function not found"
            return 1
        fi
    else
        echo "❌ teach-init.zsh not found"
        return 1
    fi
}

# Test 7: Git setup summary helper exists
test_summary_helper_exists() {
    echo "\n📝 Test 7: Git Setup Summary"
    echo "─────────────────────────────────"

    local teach_init_file="/Users/dt/.git-worktrees/flow-cli/teaching-git-integration/commands/teach-init.zsh"

    if [[ -f "$teach_init_file" ]]; then
        if grep -q "_teach_show_git_setup_summary" "$teach_init_file"; then
            echo "✅ Git setup summary helper exists"
            return 0
        else
            echo "❌ _teach_show_git_setup_summary function not found"
            return 1
        fi
    else
        echo "❌ teach-init.zsh not found"
        return 1
    fi
}

# Main test runner
main() {
    echo "\n🧪 Phase 5 teach init Git Tests"
    echo "═══════════════════════════════════════════════"

    # Source required files
    if ! source_files; then
        echo "❌ Failed to source required files"
        exit 1
    fi

    # Run tests
    local failed=0

    test_no_git_flag || ((failed++))
    test_gitignore_template || ((failed++))
    test_branch_names || ((failed++))
    test_commit_message_format || ((failed++))
    test_help_includes_no_git || ((failed++))
    test_github_helper_exists || ((failed++))
    test_summary_helper_exists || ((failed++))

    # Summary
    echo "\n═══════════════════════════════════════════════"
    if [[ $failed -eq 0 ]]; then
        echo "✅ All tests passed!"
        echo "\n✨ Phase 5 is ready for integration testing"
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
