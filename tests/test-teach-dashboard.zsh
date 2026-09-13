#!/usr/bin/env zsh
# test-teach-dashboard.zsh - Unit tests for `teach dashboard` (issue #275)
#
# Tests:
# - generate on a full config -> valid .teach/semester-data.json
# - generate twice without --force -> refuses, exit 1; --force overwrites
# - preview --week N (lesson-plan data) and --week inside a configured break
# - announce (positional) and wizard mode -> both append a well-formed entry
# - status with an expired announcement -> flags it
# - --help shows usage

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

source "${PROJECT_ROOT}/lib/core.zsh"
source "${PROJECT_ROOT}/lib/teaching-utils.zsh"
source "${PROJECT_ROOT}/lib/template-helpers.zsh"
source "${PROJECT_ROOT}/lib/dispatchers/teach-dashboard.zsh"
source "${PROJECT_ROOT}/lib/dispatchers/teach/teach-help.zsh"

typeset -gi TESTS_RUN=0
typeset -gi TESTS_PASSED=0
typeset -gi TESTS_FAILED=0
typeset -ga FAILED_TESTS=()

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

assert_contains() {
    local description="$1" haystack="$2" needle="$3"
    ((TESTS_RUN++))
    if [[ "$haystack" == *"$needle"* ]]; then
        ((TESTS_PASSED++))
        echo "  ${GREEN}✓${NC} $description"
    else
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$description")
        echo "  ${RED}✗${NC} $description"
        echo "    Expected to find: $needle"
    fi
}

assert_equals() {
    local description="$1" actual="$2" expected="$3"
    ((TESTS_RUN++))
    if [[ "$actual" == "$expected" ]]; then
        ((TESTS_PASSED++))
        echo "  ${GREEN}✓${NC} $description"
    else
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$description")
        echo "  ${RED}✗${NC} $description"
        echo "    Expected: $expected"
        echo "    Got:      $actual"
    fi
}

setup_mock_env() {
    export TEST_DIR=$(mktemp -d)
    export ORIG_DIR="$PWD"
    cd "$TEST_DIR"
    mkdir -p .flow
}

teardown_mock_env() {
    cd "$ORIG_DIR"
    [[ -n "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

write_full_config() {
    cat > .flow/teach-config.yml <<'EOF'
course:
  name: "Test Course"
  semester: "Fall"
  year: 2026

semester_info:
  start_date: "2026-08-24"
  end_date: "2026-12-12"
  timezone: "America/Denver"
  breaks:
    - name: "Test Break"
      start: "2026-10-12"
      end: "2026-10-16"

dashboard:
  fallback_message: "Check back soon!"
EOF
    mkdir -p .flow
    cat > .flow/lesson-plans.yml <<'EOF'
weeks:
  - number: 1
    topic: "Introduction"
    focus: "Descriptive stats"
    lecture: "Mon/Wed 10am"
    lab: "Fri 2pm"
    assignment: "HW1 due Friday"
EOF
}

# ==============================================================================
# TEST SUITE 1: generate - full config
# ==============================================================================

test_suite_generate() {
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}  Suite 1: generate - full config${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"

    setup_mock_env
    write_full_config

    local output
    output=$(_teach_dashboard_generate 2>&1)
    local exit_code=$?

    assert_equals "Exit code 0 on first generate" "$exit_code" "0"
    assert_contains "Success message shown" "$output" "Generated"
    ((TESTS_RUN++))
    if [[ -f .teach/semester-data.json ]]; then
        ((TESTS_PASSED++))
        echo "  ${GREEN}✓${NC} .teach/semester-data.json created"
    else
        ((TESTS_FAILED++))
        FAILED_TESTS+=(".teach/semester-data.json created")
        echo "  ${RED}✗${NC} .teach/semester-data.json created"
    fi

    if command -v jq >/dev/null 2>&1 && [[ -f .teach/semester-data.json ]]; then
        ((TESTS_RUN++))
        if jq . .teach/semester-data.json >/dev/null 2>&1; then
            ((TESTS_PASSED++))
            echo "  ${GREEN}✓${NC} Output is valid JSON"
        else
            ((TESTS_FAILED++))
            FAILED_TESTS+=("Output is valid JSON")
            echo "  ${RED}✗${NC} Output is valid JSON"
        fi

        local course_name week1_focus breaks_count
        course_name=$(jq -r '.course.name' .teach/semester-data.json)
        week1_focus=$(jq -r '.weeks[] | select(.number == 1) | .focus' .teach/semester-data.json)
        breaks_count=$(jq '.breaks | length' .teach/semester-data.json)

        assert_equals "course.name populated" "$course_name" "Test Course"
        assert_equals "weeks[] carries new focus field" "$week1_focus" "Descriptive stats"
        assert_equals "breaks[] passed through" "$breaks_count" "1"
    fi

    teardown_mock_env
}

# ==============================================================================
# TEST SUITE 2: generate - overwrite guard
# ==============================================================================

test_suite_generate_force() {
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}  Suite 2: generate - overwrite guard${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"

    setup_mock_env
    write_full_config

    _teach_dashboard_generate >/dev/null 2>&1

    local output exit_code
    output=$(_teach_dashboard_generate 2>&1)
    exit_code=$?

    assert_equals "Exit code 1 without --force" "$exit_code" "1"
    assert_contains "Refusal message shown" "$output" "already exists"

    output=$(_teach_dashboard_generate --force 2>&1)
    exit_code=$?

    assert_equals "Exit code 0 with --force" "$exit_code" "0"

    teardown_mock_env
}

# ==============================================================================
# TEST SUITE 3: preview
# ==============================================================================

test_suite_preview() {
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}  Suite 3: preview${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"

    setup_mock_env
    write_full_config

    local output
    output=$(_teach_dashboard_preview --week 1 2>&1)
    assert_contains "Week 1 topic shown" "$output" "Introduction"
    assert_contains "Week 1 focus shown" "$output" "Descriptive stats"

    # 2026-10-12 through 2026-10-16 falls in week 8 relative to start_date 2026-08-24
    output=$(_teach_dashboard_preview --week 8 2>&1)
    assert_contains "Break week flagged" "$output" "Test Break"

    output=$(_teach_dashboard_preview --week abc 2>&1)
    local exit_code=$?
    assert_equals "Invalid week number rejected" "$exit_code" "1"

    teardown_mock_env
}

# ==============================================================================
# TEST SUITE 4: announce (positional + wizard)
# ==============================================================================

test_suite_announce() {
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}  Suite 4: announce${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"

    setup_mock_env
    write_full_config

    local output exit_code
    output=$(_teach_dashboard_announce "Midterm moved" "Now on Oct 20" --expires 2026-10-21 2>&1)
    exit_code=$?

    assert_equals "Exit code 0 on positional announce" "$exit_code" "0"
    ((TESTS_RUN++))
    if [[ -f .teach/announcements.json ]]; then
        ((TESTS_PASSED++))
        echo "  ${GREEN}✓${NC} .teach/announcements.json created"
    else
        ((TESTS_FAILED++))
        FAILED_TESTS+=(".teach/announcements.json created")
        echo "  ${RED}✗${NC} .teach/announcements.json created"
    fi

    if command -v jq >/dev/null 2>&1 && [[ -f .teach/announcements.json ]]; then
        local title expires
        title=$(jq -r '.announcements[0].title' .teach/announcements.json)
        expires=$(jq -r '.announcements[0].expires' .teach/announcements.json)
        assert_equals "Positional title stored" "$title" "Midterm moved"
        assert_equals "Positional expires stored" "$expires" "2026-10-21"
    fi

    # Interactive wizard mode: title, message, expires (blank), type
    output=$(printf 'Wizard Announcement\nHello from the wizard\n\nnote\n' | _teach_dashboard_announce 2>&1)
    exit_code=$?
    assert_equals "Exit code 0 on wizard announce" "$exit_code" "0"

    if command -v jq >/dev/null 2>&1; then
        local count second_title
        count=$(jq '.announcements | length' .teach/announcements.json)
        second_title=$(jq -r '.announcements[1].title' .teach/announcements.json)
        assert_equals "Both announcements present after wizard" "$count" "2"
        assert_equals "Wizard title stored" "$second_title" "Wizard Announcement"
    fi

    teardown_mock_env
}

# ==============================================================================
# TEST SUITE 5: status - expired announcement flagged
# ==============================================================================

test_suite_status() {
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}  Suite 5: status${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"

    setup_mock_env
    write_full_config

    mkdir -p .teach
    cat > .teach/announcements.json <<'EOF'
{
  "announcements": [
    {"id": "old-notice", "title": "Old", "message": "Stale", "expires": "2020-01-01", "type": "note", "created_at": "2020-01-01T00:00:00Z"}
  ]
}
EOF

    local output
    output=$(_teach_dashboard_status 2>&1)

    assert_contains "dashboard section detected" "$output" "dashboard: section configured"
    assert_contains "Announcement count shown" "$output" "1 total"
    assert_contains "Expired announcement flagged" "$output" "expired"

    teardown_mock_env
}

# ==============================================================================
# TEST SUITE 6: --help
# ==============================================================================

test_suite_help() {
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}  Suite 6: --help${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"

    local output
    output=$(_teach_dashboard_help 2>&1)

    assert_contains "Usage line shown" "$output" "Usage:"
    assert_contains "Alias shown" "$output" "dash"
    assert_contains "Subcommands listed" "$output" "generate"
    assert_contains "Exit codes documented" "$output" "EXIT CODES"

    output=$(_teach_dashboard_dispatcher --help 2>&1)
    assert_contains "Dispatcher --help routes to help" "$output" "Usage:"
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    echo "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo "${GREEN}║  TEACH DASHBOARD - Unit Tests                              ║${NC}"
    echo "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"

    test_suite_generate
    test_suite_generate_force
    test_suite_preview
    test_suite_announce
    test_suite_status
    test_suite_help

    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}  Test Summary${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  Total Tests:   ${TESTS_RUN}"
    echo "  ${GREEN}Passed:        ${TESTS_PASSED}${NC}"
    echo "  ${RED}Failed:        ${TESTS_FAILED}${NC}"
    echo ""

    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo "${RED}Failed Tests:${NC}"
        for test in "${FAILED_TESTS[@]}"; do
            echo "  ${RED}✗${NC} $test"
        done
        echo ""
        return 1
    else
        echo "${GREEN}All tests passed! ✓${NC}"
        echo ""
        return 0
    fi
}

main "$@"
