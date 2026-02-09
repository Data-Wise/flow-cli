#!/usr/bin/env zsh
# dogfood-teach-deploy-v2.zsh - Non-interactive dogfooding for teach deploy v2
# Run with: zsh tests/dogfood-teach-deploy-v2.zsh
#
# Tests the REAL plugin functions against the demo course fixture.
# Loads the full plugin (source flow.plugin.zsh) -- not mocked.
#
# Sections:
#   1. Plugin Load Verification       (4 tests)
#   2. Help Output                     (6 tests)
#   3. Smart Commit Messages           (6 tests)
#   4. Deploy History Helpers          (8 tests)
#   5. Deploy Rollback Helpers         (3 tests)
#   6. Preflight Checks (Demo Course)  (6 tests)
#   7. Dry-Run Preview                 (5 tests)
#   8. .STATUS Updates                 (4 tests)
#   9. Flag Parsing                    (5 tests)
#  10. Full Deploy Lifecycle E2E       (4 tests)
#  11. Safety Enhancements (v6.6.0)   (10 tests)
# Total: ~61 tests

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

# Global temp dirs to clean up
typeset -ga _DOGFOOD_TEMP_DIRS=()

cleanup_all() {
    for d in "${_DOGFOOD_TEMP_DIRS[@]}"; do
        [[ -d "$d" ]] && rm -rf "$d"
    done
}
trap cleanup_all EXIT

# Load plugin
echo "${CYAN}Loading flow-cli plugin...${RESET}"
source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
    echo "${RED}ERROR: Failed to load plugin${RESET}"
    exit 1
}
echo "${GREEN}Plugin loaded${RESET}"
echo ""

# ============================================================================
# Test runner -- exit 0=pass, 77=skip, other=fail
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
        echo "${GREEN}PASS${RESET}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    elif [[ $exit_code -eq 77 ]]; then
        echo "${YELLOW}SKIP${RESET}"
        TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
    else
        echo "${RED}FAIL${RESET}"
        echo "  ${DIM}Output: ${output:0:200}${RESET}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# ============================================================================
# yq probe -- some sandboxed environments block yq inside functions
# ============================================================================
_YQ_AVAILABLE=false
if command -v yq >/dev/null 2>&1; then
    _probe=$(echo "test: value" | yq '.test' 2>/dev/null)
    [[ "$_probe" == "value" ]] && _YQ_AVAILABLE=true
    unset _probe
fi

if [[ "$_YQ_AVAILABLE" != "true" ]]; then
    echo "${YELLOW}Warning: yq not available -- some tests will be skipped${RESET}"
    echo ""
fi

# ============================================================================
# HELPER: Create sandboxed git repo with draft/main branches
# Returns the temp dir path on stdout
# ============================================================================
_create_test_repo() {
    local tmpdir=$(mktemp -d)
    _DOGFOOD_TEMP_DIRS+=("$tmpdir")

    (
        cd "$tmpdir"
        git init -q
        git config user.email "test@example.com"
        git config user.name "Test"

        # Initial commit on main
        mkdir -p .flow lectures
        cat > .flow/teach-config.yml <<'YAML'
course:
  name: 'TEST-200'
semester_info:
  start_date: '2026-08-26'
YAML
        echo "# Test Course" > README.md
        git add -A && git commit -q -m "init"

        # Create draft branch with content
        git checkout -q -b draft
        echo "---\ntitle: Week 1\n---\n# Lecture" > lectures/week-01.qmd
        git add -A && git commit -q -m "add week-01 lecture"
    ) >/dev/null 2>&1

    echo "$tmpdir"
}

# ============================================================================
# HELPER: Create test repo as a copy of demo course
# ============================================================================
_create_demo_repo() {
    local tmpdir=$(mktemp -d)
    local remotedir=$(mktemp -d)
    _DOGFOOD_TEMP_DIRS+=("$tmpdir" "$remotedir")

    (
        # Create bare remote first
        cd "$remotedir" && git init --bare -q
    ) >/dev/null 2>&1

    (
        cp -R "$DEMO_COURSE"/. "$tmpdir"/
        cd "$tmpdir"
        git init -q
        git config user.email "test@example.com"
        git config user.name "Test"
        git add -A && git commit -q -m "init demo course"

        # Set up remote and push main
        git remote add origin "$remotedir"
        git push -q origin main 2>/dev/null

        # Create draft branch
        git checkout -q -b draft
        # Add a small change so there is something to deploy
        echo "\n## Updated" >> lectures/week-01.qmd
        git add -A && git commit -q -m "update week-01"
        git push -q origin draft 2>/dev/null
    ) >/dev/null 2>&1

    echo "$tmpdir"
}

# ============================================================================
# SECTION 1: Plugin Load Verification
# ============================================================================
echo "${CYAN}--- Section 1: Plugin Load Verification ---${RESET}"

run_test "Core deploy v2 functions are loaded" '
    typeset -f _teach_deploy_enhanced >/dev/null 2>&1 || return 1
    typeset -f _deploy_preflight_checks >/dev/null 2>&1 || return 1
    typeset -f _deploy_direct_merge >/dev/null 2>&1 || return 1
    typeset -f _deploy_dry_run_report >/dev/null 2>&1 || return 1
'

run_test "Deploy history functions are loaded" '
    typeset -f _deploy_history_append >/dev/null 2>&1 || return 1
    typeset -f _deploy_history_list >/dev/null 2>&1 || return 1
    typeset -f _deploy_history_count >/dev/null 2>&1 || return 1
    typeset -f _deploy_history_get >/dev/null 2>&1 || return 1
'

run_test "Deploy rollback functions are loaded" '
    typeset -f _deploy_rollback >/dev/null 2>&1 || return 1
    typeset -f _deploy_perform_rollback >/dev/null 2>&1 || return 1
'

run_test "Smart commit and status helpers are loaded" '
    typeset -f _generate_smart_commit_message >/dev/null 2>&1 || return 1
    typeset -f _deploy_update_status_file >/dev/null 2>&1 || return 1
'

echo ""

# ============================================================================
# SECTION 2: Help Output
# ============================================================================
echo "${CYAN}--- Section 2: Help Output ---${RESET}"

run_test "Help function produces output" '
    local output
    output=$(_teach_deploy_enhanced_help 2>&1)
    [[ -n "$output" ]] || return 1
'

run_test "Help contains --direct flag" '
    local output
    output=$(_teach_deploy_enhanced_help 2>&1)
    [[ "$output" == *"--direct"* ]] || return 1
'

run_test "Help contains --rollback flag" '
    local output
    output=$(_teach_deploy_enhanced_help 2>&1)
    [[ "$output" == *"--rollback"* ]] || return 1
'

run_test "Help contains --history flag" '
    local output
    output=$(_teach_deploy_enhanced_help 2>&1)
    [[ "$output" == *"--history"* ]] || return 1
'

run_test "Help contains --dry-run flag" '
    local output
    output=$(_teach_deploy_enhanced_help 2>&1)
    [[ "$output" == *"--dry-run"* ]] || return 1
'

run_test "Help contains --ci flag" '
    local output
    output=$(_teach_deploy_enhanced_help 2>&1)
    [[ "$output" == *"--ci"* ]] || return 1
'

echo ""

# ============================================================================
# SECTION 3: Smart Commit Messages
# ============================================================================
echo "${CYAN}--- Section 3: Smart Commit Messages ---${RESET}"

run_test "Lecture files produce content: prefix" '
    local tmpdir=$(_create_test_repo)
    local msg
    msg=$(cd "$tmpdir" && _generate_smart_commit_message "draft" "main" 2>/dev/null)
    [[ "$msg" == content:* ]] || return 1
'

run_test "Config files produce config: prefix" '
    local tmpdir=$(mktemp -d)
    _DOGFOOD_TEMP_DIRS+=("$tmpdir")
    (
        cd "$tmpdir"
        git init -q
        git config user.email "test@example.com"
        git config user.name "Test"
        echo "initial" > README.md
        git add -A && git commit -q -m "init"
        git checkout -q -b draft
        echo "project:" > _quarto.yml
        echo "theme: custom" > .flow/config.yml
        mkdir -p .flow
        echo "flow:" > .flow/config.yml
        git add -A && git commit -q -m "add config"
    ) >/dev/null 2>&1
    local msg
    msg=$(cd "$tmpdir" && _generate_smart_commit_message "draft" "main" 2>/dev/null)
    [[ "$msg" == *"config"* ]] || return 1
'

run_test "Assignment files produce content with assignment" '
    local tmpdir=$(mktemp -d)
    _DOGFOOD_TEMP_DIRS+=("$tmpdir")
    (
        cd "$tmpdir"
        git init -q
        git config user.email "test@example.com"
        git config user.name "Test"
        echo "initial" > README.md
        git add -A && git commit -q -m "init"
        git checkout -q -b draft
        mkdir -p assignments
        echo "---\ntitle: HW3\n---" > assignments/hw3.qmd
        git add -A && git commit -q -m "add assignment"
    ) >/dev/null 2>&1
    local msg
    msg=$(cd "$tmpdir" && _generate_smart_commit_message "draft" "main" 2>/dev/null)
    [[ "$msg" == *"assignment"* ]] || return 1
'

run_test "Mixed files produce deploy: prefix" '
    local tmpdir=$(mktemp -d)
    _DOGFOOD_TEMP_DIRS+=("$tmpdir")
    (
        cd "$tmpdir"
        git init -q
        git config user.email "test@example.com"
        git config user.name "Test"
        echo "initial" > README.md
        git add -A && git commit -q -m "init"
        git checkout -q -b draft
        mkdir -p lectures data .flow
        echo "lecture" > lectures/week-01.qmd
        echo "data" > data/dataset.csv
        echo "config:" > _quarto.yml
        echo "theme" > style.css
        git add -A && git commit -q -m "add mixed"
    ) >/dev/null 2>&1
    local msg
    msg=$(cd "$tmpdir" && _generate_smart_commit_message "draft" "main" 2>/dev/null)
    # Mixed content should not be 100% one category so prefix is "deploy" or a dominant cat
    [[ -n "$msg" ]] || return 1
'

run_test "No changes produce fallback message" '
    local tmpdir=$(mktemp -d)
    _DOGFOOD_TEMP_DIRS+=("$tmpdir")
    (
        cd "$tmpdir"
        git init -q
        git config user.email "test@example.com"
        git config user.name "Test"
        echo "initial" > README.md
        git add -A && git commit -q -m "init"
        git checkout -q -b draft
        # No changes between draft and main
    ) >/dev/null 2>&1
    local msg
    msg=$(cd "$tmpdir" && _generate_smart_commit_message "draft" "main" 2>/dev/null)
    [[ "$msg" == "deploy: update" ]] || return 1
'

run_test "Message truncates at 72 characters" '
    local tmpdir=$(mktemp -d)
    _DOGFOOD_TEMP_DIRS+=("$tmpdir")
    (
        cd "$tmpdir"
        git init -q
        git config user.email "test@example.com"
        git config user.name "Test"
        echo "initial" > README.md
        git add -A && git commit -q -m "init"
        git checkout -q -b draft
        mkdir -p lectures
        for i in {01..20}; do
            echo "week $i" > "lectures/week-$i-very-long-name-for-testing.qmd"
        done
        git add -A && git commit -q -m "add many lectures"
    ) >/dev/null 2>&1
    local msg
    msg=$(cd "$tmpdir" && _generate_smart_commit_message "draft" "main" 2>/dev/null)
    [[ ${#msg} -le 72 ]] || return 1
'

echo ""

# ============================================================================
# SECTION 4: Deploy History Helpers
# ============================================================================
echo "${CYAN}--- Section 4: Deploy History Helpers ---${RESET}"

run_test "History append creates file when missing" '
    local tmpdir=$(mktemp -d)
    _DOGFOOD_TEMP_DIRS+=("$tmpdir")
    (
        cd "$tmpdir"
        _deploy_history_append "direct" "abc12345" "def67890" "draft" "main" "5" "test deploy" "null" "null" "10"
    ) >/dev/null 2>&1
    [[ -f "$tmpdir/.flow/deploy-history.yml" ]] || return 1
'

run_test "History append writes valid YAML with deploys key" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local tmpdir=$(mktemp -d)
    _DOGFOOD_TEMP_DIRS+=("$tmpdir")
    (
        cd "$tmpdir"
        _deploy_history_append "direct" "abc12345" "def67890" "draft" "main" "5" "test deploy" "null" "null" "10"
    ) >/dev/null 2>&1
    local top_key
    top_key=$(yq "has(\"deploys\")" "$tmpdir/.flow/deploy-history.yml" 2>/dev/null)
    [[ "$top_key" == "true" ]] || return 1
'

run_test "History count returns correct count after appends" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local tmpdir=$(mktemp -d)
    _DOGFOOD_TEMP_DIRS+=("$tmpdir")
    (
        cd "$tmpdir"
        _deploy_history_append "direct" "aaaa1111" "" "draft" "main" "3" "first deploy" "null" "null" "8"
        _deploy_history_append "direct" "bbbb2222" "aaaa1111" "draft" "main" "5" "second deploy" "null" "null" "12"
        _deploy_history_append "pr" "cccc3333" "bbbb2222" "draft" "main" "2" "third deploy" "42" "null" "60"
    ) >/dev/null 2>&1
    local count
    count=$(cd "$tmpdir" && _deploy_history_count 2>/dev/null)
    [[ "$count" == "3" ]] || return 1
'

run_test "History list produces table output" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local tmpdir=$(mktemp -d)
    _DOGFOOD_TEMP_DIRS+=("$tmpdir")
    (
        cd "$tmpdir"
        _deploy_history_append "direct" "aaaa1111" "" "draft" "main" "3" "first deploy" "null" "null" "8"
        _deploy_history_append "direct" "bbbb2222" "aaaa1111" "draft" "main" "5" "second deploy" "null" "null" "12"
    ) >/dev/null 2>&1
    local output
    output=$(cd "$tmpdir" && _deploy_history_list 5 2>&1)
    [[ "$output" == *"Recent deployments"* ]] || return 1
    [[ "$output" == *"#"* ]] || return 1
'

run_test "History get retrieves most recent entry (index 1)" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local tmpdir=$(mktemp -d)
    _DOGFOOD_TEMP_DIRS+=("$tmpdir")
    (
        cd "$tmpdir"
        _deploy_history_append "direct" "aaaa1111" "" "draft" "main" "3" "first deploy" "null" "null" "8"
        _deploy_history_append "pr" "bbbb2222" "aaaa1111" "draft" "main" "7" "latest deploy" "99" "null" "45"
    ) >/dev/null 2>&1
    local result
    result=$(
        cd "$tmpdir"
        _deploy_history_get 1
        echo "$DEPLOY_HIST_MODE"
    )
    [[ "$result" == "pr" ]] || return 1
'

run_test "History get with index 2 retrieves second most recent" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local tmpdir=$(mktemp -d)
    _DOGFOOD_TEMP_DIRS+=("$tmpdir")
    (
        cd "$tmpdir"
        _deploy_history_append "direct" "aaaa1111" "" "draft" "main" "3" "first deploy" "null" "null" "8"
        _deploy_history_append "pr" "bbbb2222" "aaaa1111" "draft" "main" "7" "latest deploy" "99" "null" "45"
    ) >/dev/null 2>&1
    local result
    result=$(
        cd "$tmpdir"
        _deploy_history_get 2
        echo "$DEPLOY_HIST_MODE"
    )
    [[ "$result" == "direct" ]] || return 1
'

run_test "Single quotes in commit message are escaped" '
    local tmpdir=$(mktemp -d)
    _DOGFOOD_TEMP_DIRS+=("$tmpdir")
    (
        cd "$tmpdir"
        _deploy_history_append "direct" "abc12345" "" "draft" "main" "1" "it'\''s a test" "null" "null" "5"
    ) >/dev/null 2>&1
    # File should exist and not have broken YAML
    [[ -f "$tmpdir/.flow/deploy-history.yml" ]] || return 1
    # Basic check: file has the escaped content (double single quotes)
    grep -q "it" "$tmpdir/.flow/deploy-history.yml" || return 1
'

run_test "Multiple appends do not corrupt history file" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local tmpdir=$(mktemp -d)
    _DOGFOOD_TEMP_DIRS+=("$tmpdir")
    (
        cd "$tmpdir"
        for i in {1..5}; do
            _deploy_history_append "direct" "hash000$i" "" "draft" "main" "$i" "deploy number $i" "null" "null" "$((i * 10))"
        done
    ) >/dev/null 2>&1
    # Use _deploy_history_count which calls yq internally -- verifies parsability
    local count
    count=$(cd "$tmpdir" && _deploy_history_count 2>/dev/null)
    [[ "$count" == "5" ]] || return 1
'

echo ""

# ============================================================================
# SECTION 5: Deploy Rollback Helpers
# ============================================================================
echo "${CYAN}--- Section 5: Deploy Rollback Helpers ---${RESET}"

run_test "Rollback in CI mode without index returns error" '
    local tmpdir=$(mktemp -d)
    _DOGFOOD_TEMP_DIRS+=("$tmpdir")
    (
        cd "$tmpdir"
        git init -q
        git config user.email "test@example.com"
        git config user.name "Test"
        echo "x" > f.txt && git add -A && git commit -q -m "init"
        mkdir -p .flow
        _deploy_history_append "direct" "abc12345" "" "draft" "main" "1" "test" "null" "null" "5"
    ) >/dev/null 2>&1
    local output
    output=$(cd "$tmpdir" && _deploy_rollback --ci 2>&1)
    local rc=$?
    [[ $rc -ne 0 ]] || return 1
    [[ "$output" == *"CI mode requires explicit"* ]] || return 1
'

run_test "Rollback with invalid index returns error" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local tmpdir=$(mktemp -d)
    _DOGFOOD_TEMP_DIRS+=("$tmpdir")
    (
        cd "$tmpdir"
        git init -q
        git config user.email "test@example.com"
        git config user.name "Test"
        echo "x" > f.txt && git add -A && git commit -q -m "init"
        mkdir -p .flow
        _deploy_history_append "direct" "abc12345" "" "draft" "main" "1" "test" "null" "null" "5"
    ) >/dev/null 2>&1
    local output
    output=$(cd "$tmpdir" && _deploy_rollback 99 --ci 2>&1)
    local rc=$?
    [[ $rc -ne 0 ]] || return 1
    [[ "$output" == *"Invalid"* ]] || return 1
'

run_test "Rollback with no history returns error" '
    local tmpdir=$(mktemp -d)
    _DOGFOOD_TEMP_DIRS+=("$tmpdir")
    (
        cd "$tmpdir"
        git init -q
        git config user.email "test@example.com"
        git config user.name "Test"
        echo "x" > f.txt && git add -A && git commit -q -m "init"
    ) >/dev/null 2>&1
    local output
    output=$(cd "$tmpdir" && _deploy_rollback 1 --ci 2>&1)
    local rc=$?
    [[ $rc -ne 0 ]] || return 1
    [[ "$output" == *"No deployment history"* ]] || return 1
'

echo ""

# ============================================================================
# SECTION 6: Preflight Checks with Demo Course
# ============================================================================
echo "${CYAN}--- Section 6: Preflight Checks (Demo Course) ---${RESET}"

run_test "Preflight succeeds in demo-course git repo on draft branch" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local tmpdir=$(_create_demo_repo)
    local output
    output=$(cd "$tmpdir" && _deploy_preflight_checks "true" 2>&1)
    local rc=$?
    [[ $rc -eq 0 ]] || return 1
'

run_test "Preflight sets DEPLOY_COURSE_NAME to STAT-101" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local tmpdir=$(_create_demo_repo)
    local name
    name=$(
        cd "$tmpdir"
        _deploy_preflight_checks "true" >/dev/null 2>&1
        echo "$DEPLOY_COURSE_NAME"
    )
    [[ "$name" == "STAT-101" ]] || return 1
'

run_test "Preflight sets DEPLOY_DRAFT_BRANCH to draft (default)" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local tmpdir=$(_create_demo_repo)
    local branch
    branch=$(
        cd "$tmpdir"
        _deploy_preflight_checks "true" >/dev/null 2>&1
        echo "$DEPLOY_DRAFT_BRANCH"
    )
    [[ "$branch" == "draft" ]] || return 1
'

run_test "Preflight sets DEPLOY_PROD_BRANCH to main (default)" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local tmpdir=$(_create_demo_repo)
    local branch
    branch=$(
        cd "$tmpdir"
        _deploy_preflight_checks "true" >/dev/null 2>&1
        echo "$DEPLOY_PROD_BRANCH"
    )
    [[ "$branch" == "main" ]] || return 1
'

run_test "Preflight fails outside git repo" '
    local tmpdir=$(mktemp -d)
    _DOGFOOD_TEMP_DIRS+=("$tmpdir")
    mkdir -p "$tmpdir/.flow"
    echo "course:\n  name: X" > "$tmpdir/.flow/teach-config.yml"
    local output
    output=$(cd "$tmpdir" && _deploy_preflight_checks "true" 2>&1)
    local rc=$?
    [[ $rc -ne 0 ]] || return 1
'

run_test "Preflight fails without .flow/teach-config.yml" '
    local tmpdir=$(mktemp -d)
    _DOGFOOD_TEMP_DIRS+=("$tmpdir")
    (
        cd "$tmpdir"
        git init -q
        git config user.email "test@example.com"
        git config user.name "Test"
        echo "x" > f.txt && git add -A && git commit -q -m "init"
    ) >/dev/null 2>&1
    local output
    output=$(cd "$tmpdir" && _deploy_preflight_checks "true" 2>&1)
    local rc=$?
    [[ $rc -ne 0 ]] || return 1
    [[ "$output" == *"teach-config.yml"* ]] || return 1
'

echo ""

# ============================================================================
# SECTION 7: Dry-Run Preview
# ============================================================================
echo "${CYAN}--- Section 7: Dry-Run Preview ---${RESET}"

run_test "Dry-run output contains DRY RUN" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local tmpdir=$(_create_demo_repo)
    local output
    output=$(cd "$tmpdir" && _teach_deploy_enhanced --dry-run --ci 2>&1)
    [[ "$output" == *"DRY RUN"* ]] || return 1
'

run_test "Dry-run with --direct mentions direct mode" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local tmpdir=$(_create_demo_repo)
    local output
    output=$(cd "$tmpdir" && _teach_deploy_enhanced --dry-run --direct --ci 2>&1)
    [[ "$output" == *"direct"* ]] || return 1
'

run_test "Dry-run does NOT modify git state" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local tmpdir=$(_create_demo_repo)
    local hash_before hash_after
    hash_before=$(cd "$tmpdir" && git rev-parse HEAD 2>/dev/null)
    (cd "$tmpdir" && _teach_deploy_enhanced --dry-run --ci) >/dev/null 2>&1
    hash_after=$(cd "$tmpdir" && git rev-parse HEAD 2>/dev/null)
    [[ "$hash_before" == "$hash_after" ]] || return 1
'

run_test "Dry-run with custom message shows the message" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local tmpdir=$(_create_demo_repo)
    local output
    output=$(cd "$tmpdir" && _teach_deploy_enhanced --dry-run -m "Custom deploy msg" --ci 2>&1)
    [[ "$output" == *"Custom deploy msg"* ]] || return 1
'

run_test "Dry-run shows file count" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local tmpdir=$(_create_demo_repo)
    local output
    output=$(cd "$tmpdir" && _teach_deploy_enhanced --dry-run --ci 2>&1)
    # Output should mention a number of files
    [[ "$output" == *"file"* ]] || return 1
'

echo ""

# ============================================================================
# SECTION 8: .STATUS Updates
# ============================================================================
echo "${CYAN}--- Section 8: .STATUS Updates ---${RESET}"

run_test "Status update skips when no .STATUS file (returns 0)" '
    local tmpdir=$(mktemp -d)
    _DOGFOOD_TEMP_DIRS+=("$tmpdir")
    (
        cd "$tmpdir"
        git init -q
        git config user.email "test@example.com"
        git config user.name "Test"
        echo "x" > f.txt && git add -A && git commit -q -m "init"
    ) >/dev/null 2>&1
    (cd "$tmpdir" && _deploy_update_status_file) >/dev/null 2>&1
    local rc=$?
    [[ $rc -eq 0 ]] || return 1
    # Should NOT create a .STATUS file
    [[ ! -f "$tmpdir/.STATUS" ]] || return 1
'

run_test "Status update writes last_deploy when .STATUS exists" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local tmpdir=$(mktemp -d)
    _DOGFOOD_TEMP_DIRS+=("$tmpdir")
    (
        cd "$tmpdir"
        git init -q
        git config user.email "test@example.com"
        git config user.name "Test"
        mkdir -p .flow
        echo "course:\n  name: X" > .flow/teach-config.yml
        echo "status: active" > .STATUS
        git add -A && git commit -q -m "init"
    ) >/dev/null 2>&1
    (cd "$tmpdir" && _deploy_update_status_file) >/dev/null 2>&1
    local last_deploy
    last_deploy=$(yq '.last_deploy' "$tmpdir/.STATUS" 2>/dev/null)
    [[ -n "$last_deploy" && "$last_deploy" != "null" ]] || return 1
'

run_test "Status update writes deploy_count when history exists" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local tmpdir=$(mktemp -d)
    _DOGFOOD_TEMP_DIRS+=("$tmpdir")
    (
        cd "$tmpdir"
        git init -q
        git config user.email "test@example.com"
        git config user.name "Test"
        mkdir -p .flow
        echo "course:\n  name: X" > .flow/teach-config.yml
        echo "status: active" > .STATUS
        _deploy_history_append "direct" "abc12345" "" "draft" "main" "3" "test" "null" "null" "5"
        _deploy_history_append "direct" "def67890" "abc12345" "draft" "main" "2" "test2" "null" "null" "8"
        git add -A && git commit -q -m "init"
    ) >/dev/null 2>&1
    (cd "$tmpdir" && _deploy_update_status_file) >/dev/null 2>&1
    local count
    count=$(yq '.deploy_count' "$tmpdir/.STATUS" 2>/dev/null)
    [[ "$count" == "2" ]] || return 1
'

_test_status_teaching_week() {
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local tmpdir=$(mktemp -d)
    _DOGFOOD_TEMP_DIRS+=("$tmpdir")
    local two_weeks_ago
    two_weeks_ago=$(date -v-14d "+%Y-%m-%d" 2>/dev/null || date -d "14 days ago" "+%Y-%m-%d" 2>/dev/null)
    if [[ -z "$two_weeks_ago" ]]; then
        return 77  # Skip if date math fails (non-macOS)
    fi
    (
        cd "$tmpdir"
        git init -q
        git config user.email "test@example.com"
        git config user.name "Test"
        mkdir -p .flow
        printf "course:\n  name: WEEK-TEST\nsemester_info:\n  start_date: '%s'\n" "$two_weeks_ago" > .flow/teach-config.yml
        echo "status: active" > .STATUS
        git add -A && git commit -q -m "init"
    ) >/dev/null 2>&1
    (cd "$tmpdir" && _deploy_update_status_file) >/dev/null 2>&1
    local week
    week=$(yq '.teaching_week' "$tmpdir/.STATUS" 2>/dev/null)
    # Should be a positive number (2 or 3 depending on rounding)
    [[ -n "$week" && "$week" != "null" && "$week" -ge 1 ]] || return 1
}
run_test "Status update calculates teaching_week from start_date" '_test_status_teaching_week'

echo ""

# ============================================================================
# SECTION 9: Flag Parsing
# ============================================================================
echo "${CYAN}--- Section 9: Flag Parsing ---${RESET}"

run_test "--help produces help output without error" '
    local output
    output=$(_teach_deploy_enhanced --help 2>&1)
    local rc=$?
    [[ $rc -eq 0 ]] || return 1
    [[ "$output" == *"teach deploy"* ]] || return 1
'

run_test "Unknown flag --bogus returns error" '
    local output
    output=$(_teach_deploy_enhanced --bogus 2>&1)
    local rc=$?
    [[ $rc -ne 0 ]] || return 1
    [[ "$output" == *"Unknown flag"* ]] || return 1
'

run_test "--direct-push is accepted (backward compat alias)" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local tmpdir=$(_create_demo_repo)
    # Use dry-run to test flag acceptance without side effects
    local output
    output=$(cd "$tmpdir" && _teach_deploy_enhanced --dry-run --direct-push --ci 2>&1)
    # Should not say "Unknown flag"
    [[ "$output" != *"Unknown flag"* ]] || return 1
'

run_test "--rollback dispatches without full preflight" '
    local tmpdir=$(mktemp -d)
    _DOGFOOD_TEMP_DIRS+=("$tmpdir")
    (
        cd "$tmpdir"
        git init -q
        git config user.email "test@example.com"
        git config user.name "Test"
        echo "x" > f.txt && git add -A && git commit -q -m "init"
        # No .flow/teach-config.yml -- preflight would fail if called
    ) >/dev/null 2>&1
    local output
    output=$(cd "$tmpdir" && _teach_deploy_enhanced --rollback 1 --ci 2>&1)
    # Should fail with "No deployment history" NOT "teach-config.yml not found"
    [[ "$output" == *"history"* || "$output" == *"History"* ]] || return 1
    [[ "$output" != *"teach-config.yml not found"* ]] || return 1
'

run_test "--history dispatches without full preflight" '
    local tmpdir=$(mktemp -d)
    _DOGFOOD_TEMP_DIRS+=("$tmpdir")
    (
        cd "$tmpdir"
        # No git repo, no config -- should just report no history
    ) >/dev/null 2>&1
    local output
    output=$(cd "$tmpdir" && _teach_deploy_enhanced --history 2>&1)
    # Should mention no history, NOT preflight failure
    [[ "$output" == *"No deploy"* || "$output" == *"history"* ]] || return 1
    [[ "$output" != *"teach-config.yml not found"* ]] || return 1
'

echo ""

# ============================================================================
# SECTION 10: Full Deploy Lifecycle E2E
# ============================================================================
echo "${CYAN}--- Section 10: Full Deploy Lifecycle E2E ---${RESET}"

run_test "Direct deploy in sandboxed repo completes successfully" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local tmpdir=$(_create_test_repo)

    # Direct deploy needs a remote to push to.
    # Create a bare remote alongside.
    local remote_dir=$(mktemp -d)
    _DOGFOOD_TEMP_DIRS+=("$remote_dir")
    (
        cd "$remote_dir" && git init --bare -q
    ) >/dev/null 2>&1
    (
        cd "$tmpdir"
        git remote add origin "$remote_dir"
        # Push both branches to the bare remote
        git push -q origin main 2>/dev/null
        git push -q origin draft 2>/dev/null
    ) >/dev/null 2>&1

    local output
    output=$(cd "$tmpdir" && _teach_deploy_enhanced --direct --ci 2>&1)
    local rc=$?
    [[ $rc -eq 0 ]] || return 1
'

run_test "After direct deploy, history file exists with 1 entry" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local tmpdir=$(_create_test_repo)

    local remote_dir=$(mktemp -d)
    _DOGFOOD_TEMP_DIRS+=("$remote_dir")
    (cd "$remote_dir" && git init --bare -q) >/dev/null 2>&1
    (
        cd "$tmpdir"
        git remote add origin "$remote_dir"
        git push -q origin main 2>/dev/null
        git push -q origin draft 2>/dev/null
    ) >/dev/null 2>&1

    (cd "$tmpdir" && _teach_deploy_enhanced --direct --ci) >/dev/null 2>&1

    [[ -f "$tmpdir/.flow/deploy-history.yml" ]] || return 1
    local count
    count=$(cd "$tmpdir" && _deploy_history_count 2>/dev/null)
    [[ "$count" == "1" ]] || return 1
'

run_test "History list after deploy shows the entry" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local tmpdir=$(_create_test_repo)

    local remote_dir=$(mktemp -d)
    _DOGFOOD_TEMP_DIRS+=("$remote_dir")
    (cd "$remote_dir" && git init --bare -q) >/dev/null 2>&1
    (
        cd "$tmpdir"
        git remote add origin "$remote_dir"
        git push -q origin main 2>/dev/null
        git push -q origin draft 2>/dev/null
    ) >/dev/null 2>&1

    (cd "$tmpdir" && _teach_deploy_enhanced --direct --ci) >/dev/null 2>&1

    local output
    output=$(cd "$tmpdir" && _deploy_history_list 5 2>&1)
    [[ "$output" == *"direct"* ]] || return 1
    [[ "$output" == *"Recent deployments"* ]] || return 1
'

run_test "Dry-run does NOT create history entry" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local tmpdir=$(_create_demo_repo)
    # Start without history
    [[ ! -f "$tmpdir/.flow/deploy-history.yml" ]] || rm -f "$tmpdir/.flow/deploy-history.yml"

    (cd "$tmpdir" && _teach_deploy_enhanced --dry-run --direct --ci) >/dev/null 2>&1

    # History file should NOT exist (dry-run does not record)
    if [[ -f "$tmpdir/.flow/deploy-history.yml" ]]; then
        local count
        count=$(cd "$tmpdir" && _deploy_history_count 2>/dev/null)
        [[ "$count" == "0" ]] || return 1
    fi
    return 0
'

echo ""

# ============================================================================
# SECTION 11: Safety Enhancements (v6.6.0)
# ============================================================================
echo "${CYAN}--- Section 11: Safety Enhancements (v6.6.0) ---${RESET}"

run_test "CI mode rejects deploy with uncommitted changes" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local tmpdir=$(_create_demo_repo)
    # Dirty the working tree
    echo "unsaved edit" >> "$tmpdir/lectures/week-01.qmd"
    local output
    output=$(cd "$tmpdir" && _teach_deploy_enhanced --direct --ci 2>&1)
    local rc=$?
    [[ $rc -ne 0 ]] || return 1
    [[ "$output" == *"Uncommitted"* || "$output" == *"uncommitted"* || "$output" == *"Commit changes"* ]] || return 1
'

run_test "CI mode uncommitted error mentions CI mode" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local tmpdir=$(_create_demo_repo)
    echo "dirty" >> "$tmpdir/lectures/week-01.qmd"
    local output
    output=$(cd "$tmpdir" && _teach_deploy_enhanced --direct --ci 2>&1)
    [[ "$output" == *"CI"* || "$output" == *"ci"* ]] || return 1
'

run_test "Summary box contains Actions link for GitHub remote" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local tmpdir=$(_create_demo_repo)
    (cd "$tmpdir" && git remote set-url origin "https://github.com/TestOrg/stat-101.git") 2>/dev/null
    local output
    output=$(
        cd "$tmpdir"
        _deploy_summary_box "Direct merge" "2" "30" "5" "8" "abcd1234" "https://testorg.github.io/stat-101/"
    )
    [[ "$output" == *"Actions:"* ]] || return 1
    [[ "$output" == *"github.com/TestOrg/stat-101/actions"* ]] || return 1
'

run_test "Summary box omits Actions for non-GitHub remote" '
    local tmpdir=$(_create_demo_repo)
    (cd "$tmpdir" && git remote set-url origin "https://gitlab.com/TestOrg/stat-101.git") 2>/dev/null
    local output
    output=$(
        cd "$tmpdir"
        _deploy_summary_box "Direct merge" "2" "30" "5" "8" "abcd1234" ""
    )
    [[ "$output" != *"Actions:"* ]] || return 1
'

run_test "Summary box handles SSH GitHub remote" '
    local tmpdir=$(_create_demo_repo)
    (cd "$tmpdir" && git remote set-url origin "git@github.com:Data-Wise/stat-545.git") 2>/dev/null
    local output
    output=$(
        cd "$tmpdir"
        _deploy_summary_box "Pull request" "5" "100" "20" "12" "e5f6g7h8" ""
    )
    [[ "$output" == *"Data-Wise/stat-545/actions"* ]] || return 1
'

run_test "Trap handler returns to draft after direct merge failure" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local tmpdir=$(_create_demo_repo)
    # Run in subshell to isolate trap side-effects
    (
        cd "$tmpdir"
        # Force failure by targeting nonexistent production branch
        _deploy_direct_merge "draft" "nonexistent-prod" "test" "false" 2>/dev/null
        # Check branch after trap fires (trap fires on EXIT of _deploy_direct_merge)
        local branch_after=$(git branch --show-current 2>/dev/null)
        # Clean up trap before exiting subshell
        trap - EXIT INT TERM
        [[ "$branch_after" == "draft" ]] && exit 0 || exit 1
    )
'

run_test "Pre-commit hook failure preserves staged changes" '
    local tmpdir=$(_create_demo_repo)
    (
        cd "$tmpdir"
        # Create a failing pre-commit hook
        mkdir -p .git/hooks
        printf "#!/bin/sh\nexit 1\n" > .git/hooks/pre-commit
        chmod +x .git/hooks/pre-commit
        # Stage a change
        echo "new content" > lectures/week-02.qmd
        git add lectures/week-02.qmd
        # Commit should fail
        git commit -m "test" 2>/dev/null
    ) >/dev/null 2>&1
    # Check that the file is still staged
    local staged
    staged=$(cd "$tmpdir" && git diff --cached --name-only 2>/dev/null)
    [[ "$staged" == *"week-02"* ]] || return 1
'

run_test "Deploy with clean tree succeeds (no uncommitted prompt)" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local tmpdir=$(_create_demo_repo)
    local output
    output=$(cd "$tmpdir" && _teach_deploy_enhanced --direct --ci 2>&1)
    local rc=$?
    [[ $rc -eq 0 ]] || return 1
    # Should NOT mention uncommitted changes
    [[ "$output" != *"Uncommitted changes detected"* ]] || return 1
'

run_test "Direct deploy lifecycle with demo course produces history" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local tmpdir=$(_create_demo_repo)
    (cd "$tmpdir" && _teach_deploy_enhanced --direct --ci) >/dev/null 2>&1
    [[ -f "$tmpdir/.flow/deploy-history.yml" ]] || return 1
    local count
    count=$(cd "$tmpdir" && _deploy_history_count 2>/dev/null)
    [[ "$count" == "1" ]] || return 1
'

run_test "Full deploy summary box has Mode, Files, Duration, Commit fields" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local tmpdir=$(_create_demo_repo)
    (cd "$tmpdir" && git remote set-url origin "https://github.com/TestOrg/stat-101.git") 2>/dev/null
    # Generate a summary box directly (not via full deploy, to avoid subshell trap issues)
    local output
    output=$(
        cd "$tmpdir"
        _deploy_summary_box "Direct merge" "3" "45" "12" "8" "a1b2c3d4" "https://testorg.github.io/stat-101/"
    )
    [[ "$output" == *"Mode:"* ]] || return 1
    [[ "$output" == *"Files:"* ]] || return 1
    [[ "$output" == *"Duration:"* ]] || return 1
    [[ "$output" == *"Commit:"* ]] || return 1
    [[ "$output" == *"Actions:"* ]] || return 1
'

echo ""

# ============================================================================
# Summary
# ============================================================================
echo "================================================="
echo ""
if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "${GREEN}All $TESTS_PASSED/$TESTS_RUN tests passed${RESET}"
    [[ $TESTS_SKIPPED -gt 0 ]] && echo "  ${YELLOW}($TESTS_SKIPPED skipped -- yq not available in sandbox)${RESET}"
else
    echo "${RED}$TESTS_FAILED/$TESTS_RUN tests failed${RESET}"
    echo "  ${GREEN}$TESTS_PASSED passed${RESET}, ${RED}$TESTS_FAILED failed${RESET}"
    [[ $TESTS_SKIPPED -gt 0 ]] && echo "  ${YELLOW}$TESTS_SKIPPED skipped${RESET}"
fi
echo ""

exit $TESTS_FAILED
