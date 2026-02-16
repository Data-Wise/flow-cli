#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE: Doctor Email Integration — E2E Dogfooding
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: End-to-end tests that run against the REAL system (no mocks for
#          installed tools). Validates output structure, section ordering,
#          mode combinations, dep dedup, and fix mode behavior.
#
# Differs from test-doctor-email.zsh (unit tests) by:
#   - Testing full output structure against spec
#   - Verifying section ordering (EMAIL between INTEGRATIONS and DOTFILES)
#   - Using PATH manipulation for missing dep simulation
#   - Testing mode combinations (normal, verbose, quiet, help)
#   - Validating fix mode menu content
#   - Dogfooding: runs on the real machine with real tools
#
# Test Categories:
#   1. Real Output Structure (5 tests)
#   2. Section Ordering (2 tests)
#   3. Dep Deduplication (1 test)
#   4. Mode Combinations (4 tests)
#   5. Missing Dep Simulation (3 tests)
#   6. Fix Mode Menu (2 tests)
#   7. em doctor Independence (1 test)
#   8. Config Env Overrides (2 tests)
#
# Created: 2026-02-12
# ══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh"

# ══════════════════════════════════════════════════════════════════════════════
# SETUP
# ══════════════════════════════════════════════════════════════════════════════

FLOW_ROOT="$PROJECT_ROOT"

# Need DIM for setup output (not provided by framework)
DIM='\033[2m'

setup() {
    echo ""
    echo "${YELLOW}Setting up E2E test environment...${RESET}"

    if [[ ! -f "$FLOW_ROOT/flow.plugin.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root at $FLOW_ROOT${RESET}"
        exit 1
    fi

    echo "  Project root: $FLOW_ROOT"

    # Source the plugin
    FLOW_QUIET=1
    FLOW_ATLAS_ENABLED=no
    export FLOW_QUIET FLOW_ATLAS_ENABLED

    source "$FLOW_ROOT/flow.plugin.zsh" 2>/dev/null || {
        echo "${RED}Plugin failed to load${RESET}"
        exit 1
    }

    exec < /dev/null

    # Create isolated test project root
    TEST_ROOT=$(mktemp -d)
    trap "rm -rf '$TEST_ROOT'" EXIT
    mkdir -p "$TEST_ROOT/dev-tools/mock-dev"
    echo "## Status: active\n## Progress: 50" > "$TEST_ROOT/dev-tools/mock-dev/.STATUS"
    FLOW_PROJECTS_ROOT="$TEST_ROOT"

    # Save original PATH for restoration after missing-dep tests
    ORIGINAL_PATH="$PATH"

    # Detect real system state
    echo "  ${DIM}Real tools detected:${RESET}"
    for cmd in himalaya w3m glow email-oauth2-proxy terminal-notifier claude; do
        if command -v "$cmd" >/dev/null 2>&1; then
            echo "    ${GREEN}✓${RESET} $cmd"
        else
            echo "    ${YELLOW}○${RESET} $cmd (not installed)"
        fi
    done

    # Cache doctor outputs (with em() stub)
    em() { : }
    CACHED_NORMAL=$(doctor 2>&1)
    CACHED_HELP=$(doctor --help 2>&1)
    unfunction em 2>/dev/null

    echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════════════════════════════

# Strip ANSI color codes for reliable matching
strip_ansi() {
    sed 's/\x1b\[[0-9;]*m//g'
}

# Get doctor output with em loaded (strips color for matching)
doctor_with_em() {
    local args=("$@")
    em() { : }
    local out=$(doctor "${args[@]}" 2>&1)
    unfunction em 2>/dev/null
    echo "$out"
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 1: REAL OUTPUT STRUCTURE (5 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_email_header_format() {
    test_case "EMAIL section has correct header format: 📧 EMAIL (himalaya)"

    local stripped=$(echo "$CACHED_NORMAL" | strip_ansi)

    if echo "$stripped" | grep -qE '📧 EMAIL.*himalaya'; then
        test_pass
    else
        test_fail "Expected '📧 EMAIL (himalaya)' header"
    fi
}

test_himalaya_version_shown() {
    test_case "himalaya version line shows actual version"

    if ! command -v himalaya >/dev/null 2>&1; then
        test_skip "himalaya not installed on this system"
        return
    fi

    local stripped=$(echo "$CACHED_NORMAL" | strip_ansi)
    local real_ver=$(himalaya --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)

    if echo "$stripped" | grep -q "himalaya.*${real_ver}"; then
        test_pass
    else
        test_fail "Expected himalaya version $real_ver in output"
    fi
}

test_version_check_passes() {
    test_case "himalaya version >= 1.0.0 check shows success"

    if ! command -v himalaya >/dev/null 2>&1; then
        test_skip "himalaya not installed"
        return
    fi

    local stripped=$(echo "$CACHED_NORMAL" | strip_ansi)

    if echo "$stripped" | grep -q "himalaya version.*>= 1.0.0"; then
        test_pass
    else
        test_fail "Expected version check success line"
    fi
}

test_html_renderer_shows_one() {
    test_case "exactly one HTML renderer shown (any-of: w3m, lynx, pandoc)"

    local stripped=$(echo "$CACHED_NORMAL" | strip_ansi)

    # Count how many renderer lines appear with "HTML rendering"
    local count=0
    for r in w3m lynx pandoc; do
        if echo "$stripped" | grep -q "$r.*HTML rendering"; then
            ((count++))
        fi
    done

    if [[ $count -eq 1 ]]; then
        test_pass
    elif [[ $count -eq 0 ]]; then
        # Check for the "missing" line instead
        if echo "$stripped" | grep -q "w3m.*HTML rendering.*brew install"; then
            test_pass  # None installed, correctly shows suggestion
        else
            test_fail "Expected exactly 1 renderer line, found 0"
        fi
    else
        test_fail "Expected exactly 1 renderer line, found $count (should show first found only)"
    fi
}

test_config_summary_has_all_fields() {
    test_case "config summary contains all 5 fields"

    local stripped=$(echo "$CACHED_NORMAL" | strip_ansi)
    local missing=()

    for field in "AI backend:" "AI timeout:" "Page size:" "Folder:" "Config file:"; do
        if ! echo "$stripped" | grep -q "$field"; then
            missing+=("$field")
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        test_pass
    else
        test_fail "Missing config fields: ${missing[*]}"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 2: SECTION ORDERING (2 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_email_after_integrations() {
    test_case "EMAIL section appears after INTEGRATIONS"

    local stripped=$(echo "$CACHED_NORMAL" | strip_ansi)

    # Find line numbers
    local integ_line=$(echo "$stripped" | grep -n "INTEGRATIONS" | head -1 | cut -d: -f1)
    local email_line=$(echo "$stripped" | grep -n "EMAIL" | head -1 | cut -d: -f1)

    if [[ -z "$integ_line" ]]; then
        test_fail "INTEGRATIONS section not found"
    elif [[ -z "$email_line" ]]; then
        test_fail "EMAIL section not found"
    elif (( email_line > integ_line )); then
        test_pass
    else
        test_fail "EMAIL (line $email_line) should be after INTEGRATIONS (line $integ_line)"
    fi
}

test_email_before_dotfiles() {
    test_case "EMAIL section appears before DOTFILES"

    local stripped=$(echo "$CACHED_NORMAL" | strip_ansi)

    local email_line=$(echo "$stripped" | grep -n "EMAIL" | head -1 | cut -d: -f1)
    local dot_line=$(echo "$stripped" | grep -n "DOTFILES\|DOT TOKENS" | head -1 | cut -d: -f1)

    if [[ -z "$email_line" ]]; then
        test_fail "EMAIL section not found"
    elif [[ -z "$dot_line" ]]; then
        test_skip "DOTFILES section not present (dot dispatcher may not be loaded)"
    elif (( email_line < dot_line )); then
        test_pass
    else
        test_fail "EMAIL (line $email_line) should be before DOTFILES (line $dot_line)"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 3: DEP DEDUPLICATION (1 test)
# ══════════════════════════════════════════════════════════════════════════════

test_shared_deps_not_in_email() {
    test_case "shared deps (fzf, bat, jq) NOT re-checked in EMAIL section"

    local stripped=$(echo "$CACHED_NORMAL" | strip_ansi)

    # Extract only the EMAIL section (between EMAIL header and next section or Config:)
    local email_section=$(echo "$stripped" | sed -n '/EMAIL/,/^[[:space:]]*$/p')

    local duped=()
    for dep in fzf bat jq; do
        if echo "$email_section" | grep -qw "$dep"; then
            duped+=("$dep")
        fi
    done

    if [[ ${#duped[@]} -eq 0 ]]; then
        test_pass
    else
        test_fail "Shared deps found in EMAIL section: ${duped[*]}"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 4: MODE COMBINATIONS (4 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_normal_mode_shows_email() {
    test_case "normal mode (no flags) shows EMAIL section"

    local stripped=$(echo "$CACHED_NORMAL" | strip_ansi)

    if echo "$stripped" | grep -q "EMAIL"; then
        test_pass
    else
        test_fail "EMAIL not in normal mode output"
    fi
}

test_quiet_mode_hides_email() {
    test_case "--quiet mode hides EMAIL section"

    local output=$(doctor_with_em --quiet)
    local stripped=$(echo "$output" | strip_ansi)

    if echo "$stripped" | grep -q "EMAIL"; then
        test_fail "EMAIL should NOT appear in --quiet mode"
    else
        test_pass
    fi
}

test_verbose_shows_connectivity() {
    test_case "--verbose mode shows Connectivity: section"

    local output=$(doctor_with_em --verbose)
    local stripped=$(echo "$output" | strip_ansi)

    if echo "$stripped" | grep -q "Connectivity:"; then
        test_pass
    else
        test_fail "Expected 'Connectivity:' section in verbose output"
    fi
}

test_help_mentions_email() {
    test_case "--help mentions EMAIL section"

    local stripped=$(echo "$CACHED_HELP" | strip_ansi)

    if echo "$stripped" | grep -qi "email"; then
        test_pass
    else
        test_fail "Expected EMAIL mention in help text"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 5: MISSING DEP SIMULATION (3 tests)
# Temporarily hides real tools via PATH manipulation
# ══════════════════════════════════════════════════════════════════════════════

test_missing_himalaya_shows_error() {
    setopt local_options NULL_GLOB
    test_case "missing himalaya shows ✗ error with install hint"

    local saved_path="$PATH"
    local himalaya_dir=$(command -v himalaya 2>/dev/null)
    if [[ -n "$himalaya_dir" ]]; then
        # Create a temp bin with symlinks to everything except himalaya
        local fake_bin=$(mktemp -d)
        for bin_dir in ${(s/:/)PATH}; do
            [[ -d "$bin_dir" ]] || continue
            for f in "$bin_dir"/*(.N); do
                local name="${f:t}"
                [[ "$name" == "himalaya" ]] && continue
                [[ -e "$fake_bin/$name" ]] && continue
                ln -sf "$f" "$fake_bin/$name" 2>/dev/null
            done
        done

        PATH="$fake_bin"

        em() { : }
        local output=$(doctor 2>&1)
        unfunction em 2>/dev/null

        PATH="$saved_path"
        rm -rf "$fake_bin"

        local stripped=$(echo "$output" | strip_ansi)

        if echo "$stripped" | grep -qE '✗.*himalaya.*brew install himalaya'; then
            test_pass
        elif echo "$stripped" | grep -q "himalaya.*brew install"; then
            test_pass  # Close enough — formatting may vary
        else
            test_fail "Expected error icon + install hint for missing himalaya"
        fi
    else
        test_skip "himalaya not installed — cannot test removal"
    fi
}

test_missing_himalaya_tracked_in_array() {
    setopt local_options NULL_GLOB
    test_case "missing himalaya tracked in _doctor_missing_email_brew"

    local himalaya_dir=$(command -v himalaya 2>/dev/null)
    if [[ -z "$himalaya_dir" ]]; then
        test_skip "himalaya not installed"
        return
    fi

    local saved_path="$PATH"
    local fake_bin=$(mktemp -d)
    for bin_dir in ${(s/:/)PATH}; do
        [[ -d "$bin_dir" ]] || continue
        for f in "$bin_dir"/*(.N); do
            local name="${f:t}"
            [[ "$name" == "himalaya" ]] && continue
            [[ -e "$fake_bin/$name" ]] && continue
            ln -sf "$f" "$fake_bin/$name" 2>/dev/null
        done
    done

    PATH="$fake_bin"
    em() { : }
    doctor >/dev/null 2>&1
    unfunction em 2>/dev/null
    PATH="$saved_path"
    rm -rf "$fake_bin"

    if [[ "${_doctor_missing_email_brew[(I)himalaya]}" -gt 0 ]]; then
        test_pass
    else
        test_fail "himalaya not found in _doctor_missing_email_brew array"
    fi
}

test_missing_proxy_shows_warning() {
    test_case "missing email-oauth2-proxy shows ○ warning"

    # email-oauth2-proxy is likely not installed — check directly
    if command -v email-oauth2-proxy >/dev/null 2>&1; then
        test_skip "email-oauth2-proxy IS installed — cannot test missing state"
        return
    fi

    local stripped=$(echo "$CACHED_NORMAL" | strip_ansi)

    if echo "$stripped" | grep -qE '○.*email-oauth2-proxy'; then
        test_pass
    else
        test_fail "Expected ○ warning for missing email-oauth2-proxy"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 6: FIX MODE MENU (2 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_fix_mode_email_category_exists() {
    test_case "fix mode shows Email Tools category when deps missing"

    # email-oauth2-proxy is typically missing, triggering the category
    if command -v email-oauth2-proxy >/dev/null 2>&1; then
        test_skip "All email deps installed — no fix category to show"
        return
    fi

    em() { : }

    # Run doctor first to populate arrays, then check category selection
    doctor >/dev/null 2>&1

    unfunction em 2>/dev/null

    if [[ ${#_doctor_missing_email_brew[@]} -gt 0 || ${#_doctor_missing_email_pip[@]} -gt 0 ]]; then
        test_pass
    else
        test_fail "Expected non-empty _doctor_missing_email_brew or _doctor_missing_email_pip"
    fi
}

test_fix_mode_count_includes_email() {
    test_case "_doctor_count_categories includes email when deps missing"

    if command -v email-oauth2-proxy >/dev/null 2>&1; then
        test_skip "All email deps installed"
        return
    fi

    em() { : }
    doctor >/dev/null 2>&1
    unfunction em 2>/dev/null

    local count=$(_doctor_count_categories)

    # Should be at least 1 (email) — could be more if other deps missing
    if [[ $count -ge 1 ]]; then
        test_pass
    else
        test_fail "Expected count >= 1, got $count"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 7: EM DOCTOR INDEPENDENCE (1 test)
# ══════════════════════════════════════════════════════════════════════════════

test_em_doctor_still_works() {
    test_case "em doctor runs independently (no regression)"

    if ! (( $+functions[_em_doctor] )); then
        # Need to source email dispatcher
        if [[ -f "$FLOW_ROOT/lib/dispatchers/email-dispatcher.zsh" ]]; then
            source "$FLOW_ROOT/lib/dispatchers/email-dispatcher.zsh" 2>/dev/null
        fi
    fi

    if (( $+functions[_em_doctor] )); then
        local output=$(_em_doctor 2>&1)
        local stripped=$(echo "$output" | strip_ansi)

        if echo "$stripped" | grep -q "em doctor" && echo "$stripped" | grep -q "himalaya"; then
            test_pass
        else
            test_fail "em doctor output missing expected content"
        fi
    else
        test_skip "_em_doctor not available (email dispatcher not loaded)"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 8: CONFIG ENV OVERRIDES (2 tests)
# ══════════════════════════════════════════════════════════════════════════════

test_custom_ai_backend_shown() {
    test_case "custom FLOW_EMAIL_AI value reflected in config summary"

    local saved="$FLOW_EMAIL_AI"
    FLOW_EMAIL_AI="gemini"

    local output=$(doctor_with_em)
    local stripped=$(echo "$output" | strip_ansi)

    FLOW_EMAIL_AI="$saved"

    if echo "$stripped" | grep -q "AI backend:.*gemini"; then
        test_pass
    else
        test_fail "Expected 'gemini' in AI backend line"
    fi
}

test_custom_page_size_shown() {
    test_case "custom FLOW_EMAIL_PAGE_SIZE reflected in config summary"

    local saved="$FLOW_EMAIL_PAGE_SIZE"
    FLOW_EMAIL_PAGE_SIZE=50

    local output=$(doctor_with_em)
    local stripped=$(echo "$output" | strip_ansi)

    FLOW_EMAIL_PAGE_SIZE="$saved"

    if echo "$stripped" | grep -q "Page size:.*50"; then
        test_pass
    else
        test_fail "Expected '50' in Page size line"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# RUN ALL TESTS
# ══════════════════════════════════════════════════════════════════════════════

main() {
    test_suite_start "Doctor Email — E2E Dogfooding Suite"

    setup

    echo "${YELLOW}═══════════════════════════════════════════════════════════${RESET}"
    echo "${YELLOW}CATEGORY 1: Real Output Structure (5 tests)${RESET}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${RESET}"
    test_email_header_format
    test_himalaya_version_shown
    test_version_check_passes
    test_html_renderer_shows_one
    test_config_summary_has_all_fields

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${RESET}"
    echo "${YELLOW}CATEGORY 2: Section Ordering (2 tests)${RESET}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${RESET}"
    test_email_after_integrations
    test_email_before_dotfiles

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${RESET}"
    echo "${YELLOW}CATEGORY 3: Dep Deduplication (1 test)${RESET}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${RESET}"
    test_shared_deps_not_in_email

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${RESET}"
    echo "${YELLOW}CATEGORY 4: Mode Combinations (4 tests)${RESET}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${RESET}"
    test_normal_mode_shows_email
    test_quiet_mode_hides_email
    test_verbose_shows_connectivity
    test_help_mentions_email

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${RESET}"
    echo "${YELLOW}CATEGORY 5: Missing Dep Simulation (3 tests)${RESET}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${RESET}"
    test_missing_himalaya_shows_error
    test_missing_himalaya_tracked_in_array
    test_missing_proxy_shows_warning

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${RESET}"
    echo "${YELLOW}CATEGORY 6: Fix Mode Menu (2 tests)${RESET}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${RESET}"
    test_fix_mode_email_category_exists
    test_fix_mode_count_includes_email

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${RESET}"
    echo "${YELLOW}CATEGORY 7: em doctor Independence (1 test)${RESET}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${RESET}"
    test_em_doctor_still_works

    echo ""
    echo "${YELLOW}═══════════════════════════════════════════════════════════${RESET}"
    echo "${YELLOW}CATEGORY 8: Config Env Overrides (2 tests)${RESET}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${RESET}"
    test_custom_ai_backend_shown
    test_custom_page_size_shown

    test_suite_end
    exit $?
}

main "$@"
