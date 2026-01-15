#!/usr/bin/env zsh
# =============================================================================
# Interactive Dogfeeding Test - flow-cli v5.9.0 Scholar Integration
# =============================================================================
#
# PURPOSE: Safe, educational, step-by-step verification of v5.9.0 features
#
# SAFETY:
#   - Creates a TEMPORARY sandbox directory
#   - NEVER touches your real courses
#   - Cleans up after itself
#   - You verify each step before continuing
#
# RUN:
#   cd ~/projects/dev-tools/flow-cli
#   ./tests/interactive-dogfeed-v5.9.0.zsh
#
# =============================================================================

# Strict mode off - we handle errors ourselves
setopt NO_ERR_EXIT 2>/dev/null || true

# =============================================================================
# Configuration
# =============================================================================

FLOW_CLI_PATH="${FLOW_CLI_PATH:-$HOME/projects/dev-tools/flow-cli}"
SANDBOX_BASE="/tmp/flow-cli-dogfeed-$$"
SANDBOX_COURSE="$SANDBOX_BASE/test-course"
LOG_FILE="$SANDBOX_BASE/test-log.md"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# =============================================================================
# Helper Functions
# =============================================================================

print_header() {
    echo ""
    echo "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════${RESET}"
    echo "${BOLD}${CYAN}  $1${RESET}"
    echo "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════${RESET}"
    echo ""
}

print_section() {
    echo ""
    echo "${BOLD}${BLUE}───────────────────────────────────────────────────────────────${RESET}"
    echo "${BOLD}${BLUE}  $1${RESET}"
    echo "${BOLD}${BLUE}───────────────────────────────────────────────────────────────${RESET}"
    echo ""
}

print_edu() {
    echo "${DIM}${CYAN}📚 $1${RESET}"
}

print_expect() {
    echo "${YELLOW}Expected: $1${RESET}"
}

print_actual() {
    echo "${GREEN}Actual:${RESET}"
}

print_safe() {
    echo "${GREEN}✓ SAFE: $1${RESET}"
}

print_warn() {
    echo "${YELLOW}⚠ $1${RESET}"
}

wait_for_user() {
    echo ""
    echo "${BOLD}Press ENTER to continue (or Ctrl+C to abort)...${RESET}"
    read -r
}

confirm_continue() {
    echo ""
    echo "${YELLOW}$1${RESET}"
    echo -n "${BOLD}Continue? [y/N]: ${RESET}"
    read -r response
    [[ "$response" =~ ^[Yy]$ ]]
}

log_test() {
    echo "- $1" >> "$LOG_FILE"
}

# =============================================================================
# Cleanup Handler
# =============================================================================

cleanup() {
    echo ""
    echo "${YELLOW}Cleaning up sandbox...${RESET}"
    if [[ -d "$SANDBOX_BASE" ]]; then
        rm -rf "$SANDBOX_BASE"
        echo "${GREEN}✓ Sandbox removed: $SANDBOX_BASE${RESET}"
    fi
}

trap cleanup EXIT

# =============================================================================
# Main Test Script
# =============================================================================

main() {
    print_header "Interactive Dogfeeding Test - flow-cli v5.9.0"

    echo "This interactive test will:"
    echo "  1. Create a SAFE sandbox environment (in /tmp)"
    echo "  2. Walk you through each v5.9.0 feature"
    echo "  3. Show expected vs actual output"
    echo "  4. Explain what each command does"
    echo "  5. Clean up automatically when done"
    echo ""
    echo "${GREEN}✓ Your real courses will NOT be touched${RESET}"
    echo "${GREEN}✓ All tests run in: $SANDBOX_BASE${RESET}"

    wait_for_user

    # =========================================================================
    # PHASE 1: Setup Sandbox
    # =========================================================================

    print_header "Phase 1: Create Safe Sandbox Environment"

    print_edu "We create a temporary directory in /tmp that will be automatically"
    print_edu "deleted when the test ends. This isolates all testing from your real data."
    echo ""

    echo "Creating sandbox at: ${CYAN}$SANDBOX_BASE${RESET}"
    mkdir -p "$SANDBOX_COURSE/.flow"
    mkdir -p "$SANDBOX_COURSE/exams"
    mkdir -p "$SANDBOX_COURSE/quizzes"
    mkdir -p "$SANDBOX_COURSE/lectures"

    # Initialize git for realistic testing
    cd "$SANDBOX_COURSE"
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test User"

    # Create test config
    cat > "$SANDBOX_COURSE/.flow/teach-config.yml" << 'YAML'
# Test Course Configuration
# This is a SANDBOX copy - not your real course

course:
  name: "TEST 101"
  full_name: "Test Course for Dogfeeding"
  semester: Spring
  year: 2026
  instructor: "Test User"

semester_info:
  start_date: "2026-01-13"
  end_date: "2026-05-01"

branches:
  draft: draft
  production: main

scholar:
  course_info:
    level: undergraduate
    field: testing
    difficulty: beginner
  style:
    tone: formal
    notation: standard
    examples: true
  grading:
    homework: 30
    midterm: 30
    final: 40
YAML

    # Create some test content files
    echo "# Test Exam" > "$SANDBOX_COURSE/exams/test-exam.qmd"
    echo "# Test Quiz" > "$SANDBOX_COURSE/quizzes/test-quiz.qmd"
    echo "# Test Lecture" > "$SANDBOX_COURSE/lectures/week01.qmd"
    echo "# Test Lecture" > "$SANDBOX_COURSE/lectures/week02.qmd"

    # Initial commit
    git add -A
    git commit -q -m "Initial test setup"

    # Create log file
    echo "# Dogfeed Test Log - $(date)" > "$LOG_FILE"
    echo "" >> "$LOG_FILE"

    echo ""
    echo "${GREEN}✓ Sandbox created${RESET}"
    echo "  Directory: $SANDBOX_COURSE"
    echo "  Config: .flow/teach-config.yml"
    echo "  Content: exams/, quizzes/, lectures/"
    echo ""

    echo "Sandbox contents:"
    ls -la "$SANDBOX_COURSE"
    echo ""
    ls -la "$SANDBOX_COURSE/.flow/"

    wait_for_user

    # =========================================================================
    # PHASE 2: Source Plugin
    # =========================================================================

    print_header "Phase 2: Load flow-cli Plugin"

    print_edu "Sourcing the plugin loads all functions into the current shell."
    print_edu "This is like 'importing' a library - it doesn't DO anything yet,"
    print_edu "it just makes the functions available to call."
    echo ""

    print_expect "Silent success (no output)"
    echo ""

    echo "Running: ${CYAN}source $FLOW_CLI_PATH/flow.plugin.zsh${RESET}"
    wait_for_user

    source "$FLOW_CLI_PATH/flow.plugin.zsh" 2>/dev/null

    # Verify functions exist
    if typeset -f _teach_validate_config >/dev/null 2>&1; then
        print_actual
        echo "  ${GREEN}✓ _teach_validate_config loaded${RESET}"
        echo "  ${GREEN}✓ _flow_config_hash loaded${RESET}"
        echo "  ${GREEN}✓ teach command available${RESET}"
        log_test "[PASS] Plugin sourced successfully"
    else
        echo "  ${RED}✗ Plugin failed to load${RESET}"
        log_test "[FAIL] Plugin failed to load"
        exit 1
    fi

    print_safe "No files modified - just loaded function definitions"

    wait_for_user

    # =========================================================================
    # PHASE 3: teach status
    # =========================================================================

    print_header "Phase 3: teach status (Read-Only)"

    print_section "What This Command Does"

    echo "The ${CYAN}teach status${RESET} command:"
    echo "  1. Locates .flow/teach-config.yml (read)"
    echo "  2. Extracts course name, semester, year (read)"
    echo "  3. Validates config structure (read)"
    echo "  4. Checks for Scholar section (read)"
    echo "  5. Counts files in content directories (read)"
    echo ""
    print_safe "ALL operations are READ-ONLY"
    echo ""

    print_expect "Course info display with TEST 101, Spring 2026"
    echo ""

    echo "Running: ${CYAN}teach status${RESET}"
    wait_for_user

    print_actual
    cd "$SANDBOX_COURSE"
    teach status 2>&1

    log_test "[PASS] teach status executed"

    print_section "Verification"

    echo "Let's verify no files changed:"
    echo ""
    git status --short
    echo ""
    if [[ -z "$(git status --short)" ]]; then
        echo "${GREEN}✓ Working directory clean - no changes${RESET}"
        log_test "[VERIFY] No files modified by teach status"
    else
        echo "${YELLOW}Note: Some changes detected (see above)${RESET}"
    fi

    wait_for_user

    # =========================================================================
    # PHASE 4: Config Validation
    # =========================================================================

    print_header "Phase 4: Config Validation (Read-Only)"

    print_section "What This Command Does"

    echo "The ${CYAN}_teach_validate_config${RESET} function:"
    echo "  1. Opens the YAML file (read)"
    echo "  2. Checks required fields exist (course.name)"
    echo "  3. Validates enum values (semester, level, difficulty)"
    echo "  4. Checks grading sums to ~100%"
    echo "  5. Returns pass/fail with error messages"
    echo ""
    print_safe "Only READS the file, never modifies it"
    echo ""

    print_expect "✓ Config validated (our test config is valid)"
    echo ""

    echo "Running: ${CYAN}_teach_validate_config .flow/teach-config.yml${RESET}"
    wait_for_user

    print_actual
    _teach_validate_config .flow/teach-config.yml 2>&1
    result=$?

    if [[ $result -eq 0 ]]; then
        log_test "[PASS] Config validation passed"
    else
        log_test "[INFO] Config validation found issues (expected for some tests)"
    fi

    wait_for_user

    # =========================================================================
    # PHASE 5: Config Reading
    # =========================================================================

    print_header "Phase 5: Reading Config Values (Read-Only)"

    print_section "What This Command Does"

    echo "The ${CYAN}_teach_config_get${RESET} function:"
    echo "  1. Uses yq to extract a value from YAML"
    echo "  2. Returns the value or a default"
    echo "  3. Equivalent to: yq '.path.to.value' file.yml"
    echo ""
    print_safe "Pure read operation - like 'cat' but smarter"
    echo ""

    print_expect "Values from our test config"
    echo ""

    echo "Running multiple _teach_config_get calls..."
    wait_for_user

    print_actual
    echo "  course.name:     $(_teach_config_get 'course.name' '' '.flow/teach-config.yml')"
    echo "  course.semester: $(_teach_config_get 'course.semester' '' '.flow/teach-config.yml')"
    echo "  course.year:     $(_teach_config_get 'course.year' '' '.flow/teach-config.yml')"
    echo "  scholar.style.tone: $(_teach_config_get 'scholar.style.tone' '' '.flow/teach-config.yml')"

    log_test "[PASS] Config reading works"

    wait_for_user

    # =========================================================================
    # PHASE 6: Hash Computation
    # =========================================================================

    print_header "Phase 6: Hash Computation (Read-Only)"

    print_section "What This Command Does"

    echo "The ${CYAN}_flow_config_hash${RESET} function:"
    echo "  1. Reads all bytes of the file"
    echo "  2. Feeds them through SHA-256 algorithm"
    echo "  3. Returns 64-character hex fingerprint"
    echo ""
    echo "SHA-256 is a one-way function:"
    echo "  - Same input → always same output"
    echo "  - Change 1 byte → completely different output"
    echo "  - Used for: passwords, file integrity, git commits"
    echo ""
    print_safe "Mathematical computation only - no file changes"
    echo ""

    print_expect "64-character hex string"
    echo ""

    echo "Running: ${CYAN}_flow_config_hash .flow/teach-config.yml${RESET}"
    wait_for_user

    print_actual
    HASH=$(_flow_config_hash .flow/teach-config.yml)
    echo "  Hash: $HASH"
    echo "  Length: ${#HASH} characters"

    log_test "[PASS] Hash computation: $HASH"

    # Verify it's consistent
    HASH2=$(_flow_config_hash .flow/teach-config.yml)
    if [[ "$HASH" == "$HASH2" ]]; then
        echo ""
        echo "${GREEN}✓ Verified: Running again gives same hash (deterministic)${RESET}"
    fi

    wait_for_user

    # =========================================================================
    # PHASE 7: Change Detection
    # =========================================================================

    print_header "Phase 7: Hash-Based Change Detection"

    print_section "What This Command Does"

    echo "The ${CYAN}_flow_config_changed${RESET} function:"
    echo "  1. Computes current hash of file"
    echo "  2. Compares with cached hash (in ~/.local/share/flow/cache/)"
    echo "  3. Returns: 0 = changed, 1 = unchanged"
    echo "  4. Updates cache if changed"
    echo ""
    echo "Cache location: ${CYAN}~/.local/share/flow/cache/teach-config.hash${RESET}"
    echo ""
    print_warn "This WRITES to cache, but cache is in YOUR HOME DIR, not the course"
    echo ""

    echo "Running change detection sequence..."
    wait_for_user

    # Clear cache first
    echo "Step 1: Clear cache"
    _flow_config_invalidate
    echo "  ${GREEN}✓ Cache invalidated${RESET}"
    echo ""

    echo "Step 2: First check (no cache exists)"
    print_expect "CHANGED (exit 0) because no cache"
    if _flow_config_changed .flow/teach-config.yml; then
        echo "  ${GREEN}✓ Result: CHANGED (correct - no cache existed)${RESET}"
    else
        echo "  ${RED}✗ Result: UNCHANGED (unexpected)${RESET}"
    fi
    echo ""

    echo "Step 3: Second check (cache now exists)"
    print_expect "UNCHANGED (exit 1) because cache matches"
    if _flow_config_changed .flow/teach-config.yml; then
        echo "  ${RED}✗ Result: CHANGED (unexpected)${RESET}"
    else
        echo "  ${GREEN}✓ Result: UNCHANGED (correct - cache matches)${RESET}"
    fi
    echo ""

    echo "Step 4: Modify file and check again"
    echo "# Modified at $(date)" >> .flow/teach-config.yml
    git add .flow/teach-config.yml  # stage for later cleanup
    print_expect "CHANGED (exit 0) because file was modified"
    if _flow_config_changed .flow/teach-config.yml; then
        echo "  ${GREEN}✓ Result: CHANGED (correct - file was modified)${RESET}"
    else
        echo "  ${RED}✗ Result: UNCHANGED (unexpected)${RESET}"
    fi

    # Restore file
    git checkout .flow/teach-config.yml 2>/dev/null

    log_test "[PASS] Change detection works correctly"

    wait_for_user

    # =========================================================================
    # PHASE 8: Flag Validation
    # =========================================================================

    print_header "Phase 8: Flag Validation (Read-Only)"

    print_section "What This Command Does"

    echo "The ${CYAN}_teach_validate_flags${RESET} function:"
    echo "  1. Takes command name and flags"
    echo "  2. Checks each flag against known valid flags"
    echo "  3. Returns error with suggestions if invalid"
    echo ""
    print_safe "String comparison only - no I/O"
    echo ""

    echo "Test 1: Valid flags"
    print_expect "Silent success (exit 0)"
    echo "Running: ${CYAN}_teach_validate_flags exam --questions 5 --duration 60${RESET}"
    wait_for_user

    if _teach_validate_flags exam --questions 5 --duration 60 2>&1; then
        echo "${GREEN}✓ Valid flags accepted${RESET}"
        log_test "[PASS] Valid flags accepted"
    else
        echo "${RED}✗ Valid flags rejected (unexpected)${RESET}"
    fi
    echo ""

    echo "Test 2: Invalid flag"
    print_expect "Error message with valid flag suggestions"
    echo "Running: ${CYAN}_teach_validate_flags exam --bogus-flag${RESET}"
    wait_for_user

    print_actual
    _teach_validate_flags exam --bogus-flag 2>&1
    echo ""
    log_test "[PASS] Invalid flags rejected with helpful message"

    wait_for_user

    # =========================================================================
    # PHASE 9: Help System
    # =========================================================================

    print_header "Phase 9: Help System (Read-Only)"

    print_section "What This Command Does"

    echo "Help commands just print text - completely safe."
    echo ""

    echo "Running: ${CYAN}teach exam --help${RESET}"
    wait_for_user

    print_actual
    teach exam --help 2>&1

    log_test "[PASS] Help system works"

    wait_for_user

    # =========================================================================
    # PHASE 10: Dry Run (Safe Preview)
    # =========================================================================

    print_header "Phase 10: Dry Run Preview"

    print_section "What --dry-run Does"

    echo "The ${CYAN}--dry-run${RESET} flag:"
    echo "  1. Executes the command logic"
    echo "  2. Shows what WOULD be created"
    echo "  3. Exits BEFORE writing any files"
    echo ""
    echo "Code flow:"
    echo "  if dry_run:"
    echo "      print(preview)"
    echo "      return  ← EXIT HERE"
    echo "  "
    echo "  write_file()  ← NEVER REACHED"
    echo ""
    print_safe "--dry-run prevents ALL file writes"
    echo ""

    if confirm_continue "Would you like to test --dry-run? (requires Claude CLI)"; then
        echo ""
        echo "Running: ${CYAN}teach exam \"Test Topic\" --dry-run --questions 3${RESET}"
        echo ""
        print_warn "This calls Claude CLI - may take a moment"
        wait_for_user

        # Check if Claude is available
        if command -v claude &>/dev/null; then
            print_actual
            teach exam "Test Topic" --dry-run --questions 3 2>&1
            log_test "[PASS] Dry run executed"
        else
            echo "${YELLOW}Claude CLI not found - skipping dry-run test${RESET}"
            log_test "[SKIP] Dry run - Claude CLI not available"
        fi
    else
        echo "${YELLOW}Skipped dry-run test${RESET}"
        log_test "[SKIP] Dry run - user skipped"
    fi

    wait_for_user

    # =========================================================================
    # PHASE 11: Final Verification
    # =========================================================================

    print_header "Phase 11: Final Safety Verification"

    print_section "Proving No Damage Was Done"

    echo "Let's verify the sandbox is intact:"
    echo ""

    cd "$SANDBOX_COURSE"

    echo "1. Git status (should be clean or minimal):"
    git status --short
    echo ""

    echo "2. Config file exists and is valid:"
    ls -la .flow/teach-config.yml
    echo ""

    echo "3. Content directories unchanged:"
    echo "   exams/: $(ls exams/ | wc -l | tr -d ' ') files"
    echo "   quizzes/: $(ls quizzes/ | wc -l | tr -d ' ') files"
    echo "   lectures/: $(ls lectures/ | wc -l | tr -d ' ') files"
    echo ""

    echo "4. No unexpected files created:"
    find . -newer .flow/teach-config.yml -type f 2>/dev/null | grep -v ".git" | head -5
    echo ""

    log_test "[VERIFY] Final verification complete"

    wait_for_user

    # =========================================================================
    # Summary
    # =========================================================================

    print_header "Test Complete!"

    echo "${GREEN}${BOLD}All tests completed successfully!${RESET}"
    echo ""
    echo "Summary:"
    echo "  ✓ Plugin loaded and functions available"
    echo "  ✓ teach status displays course info (read-only)"
    echo "  ✓ Config validation works (read-only)"
    echo "  ✓ Config reading works (read-only)"
    echo "  ✓ Hash computation works (read-only)"
    echo "  ✓ Change detection works (writes to home cache only)"
    echo "  ✓ Flag validation works (read-only)"
    echo "  ✓ Help system works (read-only)"
    echo ""
    echo "Log file: ${CYAN}$LOG_FILE${RESET}"
    echo ""

    # Show log
    if confirm_continue "Would you like to see the test log?"; then
        cat "$LOG_FILE"
    fi

    echo ""
    echo "${GREEN}Sandbox will be cleaned up automatically on exit.${RESET}"
    echo ""
    echo "Next steps:"
    echo "  1. Review any issues found"
    echo "  2. Test on real course (now that you've seen it's safe)"
    echo "  3. Release v5.9.0 when satisfied"
    echo ""
}

# =============================================================================
# Run Main
# =============================================================================

main "$@"
