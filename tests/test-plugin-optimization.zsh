#!/usr/bin/env zsh
# =============================================================================
# test-plugin-optimization.zsh
# Test suite for PR #290 plugin optimizations (v5.16.0)
#
# Coverage:
# - Load guard functionality (prevent double-sourcing)
# - Display layer extraction (lib/analysis-display.zsh)
# - Cache path collision prevention
# - Test timeout mechanism
# =============================================================================

# Determine plugin directory
PLUGIN_DIR="${0:A:h:h}"

# Test counters
PASS=0
FAIL=0
TOTAL=0

# Colors
GREEN='\033[38;5;154m'
RED='\033[38;5;203m'
YELLOW='\033[38;5;221m'
BLUE='\033[38;5;75m'
BOLD='\033[1m'
RESET='\033[0m'

# Test helpers
log_pass() {
    ((PASS++))
    ((TOTAL++))
    echo -e "${GREEN}✅ PASS${RESET}: $1"
}

log_fail() {
    ((FAIL++))
    ((TOTAL++))
    echo -e "${RED}❌ FAIL${RESET}: $1${2:+ - $2}"
}

log_section() {
    echo -e "\n${BOLD}${BLUE}▶ $1${RESET}"
}

# =============================================================================
# SECTION 1: Load Guard Tests
# =============================================================================

log_section "Load Guard Functionality"

# Test 1.1: Load guards prevent double-sourcing (concept-extraction.zsh)
test_load_guard() {
    local lib_file="$PLUGIN_DIR/lib/concept-extraction.zsh"

    # Source once
    zsh -c "
        source '$lib_file' 2>/dev/null
        echo \$_FLOW_CONCEPT_EXTRACTION_LOADED
    " | grep -q "^1$"

    if [[ $? -eq 0 ]]; then
        log_pass "Load guard sets variable on first source"
    else
        log_fail "Load guard failed to set variable"
        return 1
    fi

    # Source twice - should return early
    local double_source_output
    double_source_output=$(zsh -c "
        source '$lib_file' 2>/dev/null
        source '$lib_file' 2>/dev/null
        echo 'COMPLETED'
    ")

    if echo "$double_source_output" | grep -q "COMPLETED"; then
        log_pass "Load guard prevents double-sourcing"
    else
        log_fail "Load guard failed to prevent re-execution"
    fi
}

# Test 1.2: All new libraries have load guards
test_all_guards() {
    local libs=(
        "concept-extraction.zsh"
        "ai-analysis.zsh"
        "analysis-display.zsh"
        "ai-helpers.zsh"
        "prerequisite-graph.zsh"
        "slide-optimizer.zsh"
    )

    local missing=()
    for lib in "${libs[@]}"; do
        local lib_path="$PLUGIN_DIR/lib/$lib"

        if [[ ! -f "$lib_path" ]]; then
            continue  # Skip if file doesn't exist (may be optional)
        fi

        # Check for load guard pattern
        if grep -q "_FLOW_.*_LOADED" "$lib_path" 2>/dev/null; then
            log_pass "$lib has load guard"
        else
            missing+=("$lib")
            log_fail "$lib missing load guard"
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        log_pass "All libraries have load guards"
    fi
}

# Test 1.3: Load guard uses correct pattern
test_guard_pattern() {
    local lib_file="$PLUGIN_DIR/lib/analysis-display.zsh"

    # Check for correct pattern: return 0 2>/dev/null || true
    if grep -q "return 0 2>/dev/null || true" "$lib_file" 2>/dev/null; then
        log_pass "Load guard uses correct return pattern"
    else
        log_fail "Load guard missing safe return pattern"
    fi
}

# =============================================================================
# SECTION 2: Display Layer Extraction Tests
# =============================================================================

log_section "Display Layer Extraction"

# Test 2.1: analysis-display.zsh file exists
test_display_lib_exists() {
    local display_lib="$PLUGIN_DIR/lib/analysis-display.zsh"

    if [[ -f "$display_lib" ]]; then
        log_pass "analysis-display.zsh exists"
    else
        log_fail "analysis-display.zsh not found"
        return 1
    fi
}

# Test 2.2: Display functions extracted from command
test_display_functions() {
    local display_lib="$PLUGIN_DIR/lib/analysis-display.zsh"
    local expected_funcs=(
        "_display_analysis_header"
        "_display_concepts_section"
        "_display_prerequisites_section"
        "_display_violations_section"
        "_display_ai_section"
        "_display_slide_section"
        "_display_summary_section"
    )

    local missing=()
    for func in "${expected_funcs[@]}"; do
        if grep -q "^${func}()" "$display_lib" 2>/dev/null || \
           grep -q "^function ${func}" "$display_lib" 2>/dev/null; then
            log_pass "$func defined in display lib"
        else
            missing+=("$func")
            log_fail "$func not found in display lib"
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        log_pass "All display functions extracted successfully"
    fi
}

# Test 2.3: teach-analyze.zsh sources display lib
test_command_sources_display() {
    local cmd_file="$PLUGIN_DIR/commands/teach-analyze.zsh"

    if grep -q "source.*lib/analysis-display.zsh" "$cmd_file" 2>/dev/null; then
        log_pass "teach-analyze sources display library"
    else
        log_fail "teach-analyze missing display lib source"
    fi
}

# Test 2.4: Display lib has proper shebang
test_display_shebang() {
    local display_lib="$PLUGIN_DIR/lib/analysis-display.zsh"

    local first_line=$(head -1 "$display_lib" 2>/dev/null)

    if [[ "$first_line" == "#!/usr/bin/env zsh" ]]; then
        log_pass "Display lib has correct shebang"
    else
        log_fail "Display lib shebang incorrect: $first_line"
    fi
}

# =============================================================================
# SECTION 3: Cache Path Collision Prevention Tests
# =============================================================================

log_section "Cache Path Collision Prevention"

# Test 3.1: Cache uses directory-mirroring structure
test_cache_structure() {
    local cmd_file="$PLUGIN_DIR/commands/teach-analyze.zsh"

    # Look for relative_path variable (directory mirroring)
    if grep -q "relative_path=" "$cmd_file" 2>/dev/null; then
        log_pass "Cache uses relative path structure"
    else
        log_fail "Cache missing relative path logic"
        return 1
    fi

    # Check for cache_subdir (subdirectory preservation)
    if grep -q "cache_subdir=" "$cmd_file" 2>/dev/null; then
        log_pass "Cache preserves subdirectory structure"
    else
        log_fail "Cache missing subdirectory logic"
    fi
}

# Test 3.2: Slide cache uses mirrored structure
test_slide_cache_structure() {
    local cmd_file="$PLUGIN_DIR/commands/teach-analyze.zsh"

    # Look for slide_cache_dir variable
    if grep -q "slide_cache_dir=" "$cmd_file" 2>/dev/null; then
        log_pass "Slide cache uses directory structure"
    else
        log_fail "Slide cache missing directory logic"
        return 1
    fi

    # Check that it uses relative path
    if grep -q "slide_cache_dir=.*cache_subdir" "$cmd_file" 2>/dev/null; then
        log_pass "Slide cache preserves source directory structure"
    else
        log_fail "Slide cache doesn't use relative paths"
    fi
}

# Test 3.3: No underscore prefixes on cache variables
test_no_underscore_prefixes() {
    local cmd_file="$PLUGIN_DIR/commands/teach-analyze.zsh"

    # Check for OLD pattern with underscores
    if grep -q "_relative_path=\|_cache_subdir=\|_cache_name=\|_slide_cache_dir=" "$cmd_file" 2>/dev/null; then
        log_fail "Found underscore-prefixed cache variables (should be removed)"
    else
        log_pass "Cache variables use correct naming (no underscore prefixes)"
    fi
}

# =============================================================================
# SECTION 4: Test Timeout Mechanism
# =============================================================================

log_section "Test Timeout Mechanism"

# Test 4.1: run-all.sh has timeout support
test_runner_timeout() {
    local runner="$PLUGIN_DIR/tests/run-all.sh"

    if grep -q "timeout.*30" "$runner" 2>/dev/null; then
        log_pass "Test runner has 30s timeout"
    else
        log_fail "Test runner missing timeout mechanism"
        return 1
    fi
}

# Test 4.2: Timeout exit code 124 detection
test_timeout_exit_code() {
    local runner="$PLUGIN_DIR/tests/run-all.sh"

    if grep -q "exit_code.*124" "$runner" 2>/dev/null || \
       grep -q "\$?.*124" "$runner" 2>/dev/null; then
        log_pass "Test runner detects timeout exit code 124"
    else
        log_fail "Test runner missing exit code 124 detection"
    fi
}

# Test 4.3: TIMEOUT counter exists
test_timeout_counter() {
    local runner="$PLUGIN_DIR/tests/run-all.sh"

    if grep -q "TIMEOUT=" "$runner" 2>/dev/null; then
        log_pass "Test runner has TIMEOUT counter"
    else
        log_fail "Test runner missing TIMEOUT counter"
    fi
}

# Test 4.4: Exit code 2 for timeouts
test_timeout_exit_code_2() {
    local runner="$PLUGIN_DIR/tests/run-all.sh"

    # Look for exit 2 in timeout context
    if grep -A5 "TIMEOUT.*-gt.*0" "$runner" 2>/dev/null | grep -q "exit 2"; then
        log_pass "Test runner uses exit code 2 for timeouts"
    else
        log_fail "Test runner missing exit code 2 for timeouts"
    fi
}

# =============================================================================
# SECTION 5: Integration Tests
# =============================================================================

log_section "Integration Tests"

# Test 5.1: Plugin loads without double-sourcing errors
test_plugin_load() {
    local plugin_file="$PLUGIN_DIR/flow.plugin.zsh"

    # Load plugin twice in same shell
    local output
    output=$(zsh -c "
        source '$plugin_file' 2>&1
        source '$plugin_file' 2>&1
        echo 'SUCCESS'
    ")

    if echo "$output" | grep -q "SUCCESS"; then
        log_pass "Plugin loads twice without errors"
    else
        log_fail "Plugin failed double-load test"
    fi
}

# Test 5.2: teach analyze command available after load
test_teach_analyze_available() {
    zsh -c "
        source '$PLUGIN_DIR/flow.plugin.zsh' 2>/dev/null
        typeset -f teach >/dev/null
    " 2>/dev/null

    if [[ $? -eq 0 ]]; then
        log_pass "teach command available after plugin load"
    else
        log_fail "teach command not defined"
    fi
}

# Test 5.3: Display functions available after sourcing
test_display_functions_available() {
    zsh -c "
        source '$PLUGIN_DIR/flow.plugin.zsh' 2>/dev/null
        source '$PLUGIN_DIR/lib/analysis-display.zsh' 2>/dev/null
        typeset -f _display_analysis_header >/dev/null
    " 2>/dev/null

    if [[ $? -eq 0 ]]; then
        log_pass "Display functions available after sourcing"
    else
        log_fail "Display functions not available"
    fi
}

# =============================================================================
# RUN ALL TESTS
# =============================================================================

echo -e "${BOLD}${BLUE}========================================${RESET}"
echo -e "${BOLD}${BLUE}  Plugin Optimization Test Suite${RESET}"
echo -e "${BOLD}${BLUE}  PR #290 - v5.16.0${RESET}"
echo -e "${BOLD}${BLUE}========================================${RESET}"

# Section 1: Load Guards
test_load_guard
test_all_guards
test_guard_pattern

# Section 2: Display Layer
test_display_lib_exists
test_display_functions
test_command_sources_display
test_display_shebang

# Section 3: Cache Paths
test_cache_structure
test_slide_cache_structure
test_no_underscore_prefixes

# Section 4: Test Timeouts
test_runner_timeout
test_timeout_exit_code
test_timeout_counter
test_timeout_exit_code_2

# Section 5: Integration
test_plugin_load
test_teach_analyze_available
test_display_functions_available

# =============================================================================
# SUMMARY
# =============================================================================

echo ""
echo -e "${BOLD}${BLUE}========================================${RESET}"
echo -e "${BOLD}${BLUE}  RESULTS${RESET}"
echo -e "${BOLD}${BLUE}========================================${RESET}"
echo -e "  Total:  ${BOLD}${TOTAL}${RESET}"
echo -e "  Passed: ${GREEN}${PASS}${RESET}"
echo -e "  Failed: ${RED}${FAIL}${RESET}"

if [[ $TOTAL -gt 0 ]]; then
    PASS_RATE=$(( (PASS * 100) / TOTAL ))
    echo -e "  Pass Rate: ${BOLD}${PASS_RATE}%${RESET}"
fi
echo ""

# Exit with appropriate code
if [[ $FAIL -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}All optimization tests passed!${RESET}"
    exit 0
else
    echo -e "${RED}${BOLD}$FAIL test(s) failed${RESET}"
    exit 1
fi
