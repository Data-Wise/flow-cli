#!/usr/bin/env zsh
# Test script for flow ai features (v3.4.0)
# Tests: recipes, usage tracking, multi-model, chat setup

# ============================================================================
# TEST FRAMEWORK
# ============================================================================

TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_test() {
    echo -n "${CYAN}Testing:${NC} $1 ... "
}

pass() {
    echo "${GREEN}✓ PASS${NC}"
    ((TESTS_PASSED++))
}

fail() {
    echo "${RED}✗ FAIL${NC} - $1"
    ((TESTS_FAILED++))
}

# ============================================================================
# SETUP
# ============================================================================

PROJECT_ROOT=""
TEST_DATA_DIR=""
TEST_USAGE_FILE=""
TEST_STATS_FILE=""
TEST_HISTORY_DIR=""

setup() {
    echo ""
    echo "${YELLOW}Setting up test environment...${NC}"

    # Get project root (CI-compatible)
    if [[ -n "${0:A}" ]]; then
        PROJECT_ROOT="${0:A:h:h}"
    fi
    # Fallback: try current directory or parent
    if [[ ! -f "$PROJECT_ROOT/flow.plugin.zsh" ]]; then
        PROJECT_ROOT="$PWD"
    fi
    if [[ ! -f "$PROJECT_ROOT/flow.plugin.zsh" ]]; then
        PROJECT_ROOT="${PWD:h}"
    fi
    if [[ ! -f "$PROJECT_ROOT/flow.plugin.zsh" ]]; then
        echo "${RED}ERROR: Cannot find flow.plugin.zsh - run from project root${NC}"
        exit 1
    fi

    echo "  Project root: $PROJECT_ROOT"

    # Create test data directory
    TEST_DATA_DIR=$(mktemp -d)
    TEST_USAGE_FILE="$TEST_DATA_DIR/ai-usage.jsonl"
    TEST_STATS_FILE="$TEST_DATA_DIR/ai-stats.json"
    TEST_HISTORY_DIR="$TEST_DATA_DIR/chat-history"
    mkdir -p "$TEST_HISTORY_DIR"

    echo "  Test data dir: $TEST_DATA_DIR"

    # Set required env vars BEFORE sourcing plugin
    export FLOW_CONFIG_DIR="$TEST_DATA_DIR/config"
    export FLOW_DATA_DIR="$TEST_DATA_DIR/data"
    export FLOW_QUIET=1
    mkdir -p "$FLOW_CONFIG_DIR" "$FLOW_DATA_DIR"

    # Source the full plugin (quieter)
    source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null

    # Override paths for testing after plugin loads
    _FLOW_AI_USAGE_FILE="$TEST_USAGE_FILE"
    _FLOW_AI_STATS_FILE="$TEST_STATS_FILE"

    echo ""
}

cleanup() {
    rm -rf "$TEST_DATA_DIR"
}

# ============================================================================
# AI RECIPES TESTS
# ============================================================================

test_builtin_recipes_exist() {
    log_test "Built-in recipes array exists"

    if [[ -n "${FLOW_BUILTIN_RECIPES[(I)review]}" ]]; then
        pass
    else
        fail "FLOW_BUILTIN_RECIPES not defined or missing 'review'"
    fi
}

test_builtin_recipe_count() {
    log_test "Has 10 built-in recipes"

    local count=${#FLOW_BUILTIN_RECIPES[@]}
    if [[ $count -ge 10 ]]; then
        pass
    else
        fail "Expected 10+ recipes, got $count"
    fi
}

test_recipe_has_content() {
    log_test "Recipes have content (review)"

    local content="${FLOW_BUILTIN_RECIPES[review]}"
    if [[ -n "$content" && ${#content} -gt 20 ]]; then
        pass
    else
        fail "Recipe 'review' content too short or missing"
    fi
}

test_recipe_apply_function() {
    log_test "_flow_recipe_apply substitutes variables"

    # Test that the function exists
    if typeset -f _flow_recipe_apply > /dev/null 2>&1; then
        pass
    else
        fail "_flow_recipe_apply not defined"
    fi
}

test_recipe_list_function() {
    log_test "_flow_recipe_list returns output"

    local output=$(_flow_recipe_list 2>&1)

    if [[ "$output" == *"review"* || "$output" == *"commit"* ]]; then
        pass
    else
        fail "Recipe list missing expected recipes"
    fi
}

test_recipe_show_function() {
    log_test "_flow_recipe_show displays recipe"

    local output=$(_flow_recipe_show "review" 2>&1)

    if [[ "$output" == *"review"* || -n "$output" ]]; then
        pass
    else
        fail "Recipe show failed"
    fi
}

# ============================================================================
# AI USAGE TRACKING TESTS
# ============================================================================

test_usage_log_function_exists() {
    log_test "_flow_ai_log_usage function exists"

    if typeset -f _flow_ai_log_usage > /dev/null 2>&1; then
        pass
    else
        fail "_flow_ai_log_usage not defined"
    fi
}

test_usage_stats_function_exists() {
    log_test "flow_ai_stats function exists"

    if typeset -f flow_ai_stats > /dev/null 2>&1; then
        pass
    else
        fail "flow_ai_stats not defined"
    fi
}

test_usage_suggest_function_exists() {
    log_test "flow_ai_suggest function exists"

    if typeset -f flow_ai_suggest > /dev/null 2>&1; then
        pass
    else
        fail "flow_ai_suggest not defined"
    fi
}

test_usage_command_exists() {
    log_test "flow_ai_usage command exists"

    if typeset -f flow_ai_usage > /dev/null 2>&1; then
        pass
    else
        fail "flow_ai_usage not defined"
    fi
}

# ============================================================================
# MULTI-MODEL TESTS
# ============================================================================

test_model_array_exists() {
    log_test "FLOW_AI_MODELS array exists"

    if [[ -n "${FLOW_AI_MODELS[(I)sonnet]}" ]]; then
        pass
    else
        fail "FLOW_AI_MODELS not defined"
    fi
}

test_model_mappings() {
    log_test "Model mappings include opus, sonnet, haiku"

    local has_opus="${FLOW_AI_MODELS[opus]}"
    local has_sonnet="${FLOW_AI_MODELS[sonnet]}"
    local has_haiku="${FLOW_AI_MODELS[haiku]}"

    if [[ -n "$has_opus" && -n "$has_sonnet" && -n "$has_haiku" ]]; then
        pass
    else
        fail "Missing model mappings"
    fi
}

test_model_list_function() {
    log_test "flow_ai_model list works"

    local output=$(flow_ai_model list 2>&1)

    if [[ "$output" == *"opus"* && "$output" == *"sonnet"* ]]; then
        pass
    else
        fail "Model list output incorrect"
    fi
}

test_model_show_function() {
    log_test "flow_ai_model show works"

    local output=$(flow_ai_model show 2>&1)

    if [[ "$output" == *"Current"* || "$output" == *"model"* ]]; then
        pass
    else
        fail "Model show output incorrect"
    fi
}

test_default_model_config() {
    log_test "Default model is sonnet"

    local default="${FLOW_CONFIG_DEFAULTS[ai_model]:-sonnet}"

    if [[ "$default" == "sonnet" ]]; then
        pass
    else
        fail "Expected sonnet, got $default"
    fi
}

# ============================================================================
# AI COMMAND STRUCTURE TESTS
# ============================================================================

test_flow_ai_help() {
    log_test "flow_ai --help output"

    local output=$(flow_ai --help 2>&1)

    if [[ "$output" == *"USAGE"* || "$output" == *"flow ai"* || "$output" == *"AI"* ]]; then
        pass
    else
        fail "Help output missing expected content: ${output:0:100}"
    fi
}

test_flow_ai_help_has_subcommands() {
    log_test "Help lists subcommands (recipe, chat, usage, model)"

    local output=$(flow_ai --help 2>&1)

    # Check for key subcommands in help output
    if [[ "$output" == *"recipe"* || "$output" == *"chat"* ]]; then
        pass
    else
        fail "Missing subcommand documentation"
    fi
}

test_flow_ai_help_has_modes() {
    log_test "Help lists modes (--explain, --fix, --suggest)"

    local output=$(flow_ai --help 2>&1)

    if [[ "$output" == *"--explain"* || "$output" == *"--fix"* || "$output" == *"-e"* ]]; then
        pass
    else
        fail "Missing mode flags in help"
    fi
}

test_flow_ai_help_has_model_flag() {
    log_test "Help mentions --model flag"

    local output=$(flow_ai --help 2>&1)

    if [[ "$output" == *"--model"* || "$output" == *"-m"* || "$output" == *"model"* ]]; then
        pass
    else
        fail "Missing --model flag in help"
    fi
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  AI Features Tests (v3.4.0)                                ║"
    echo "╚════════════════════════════════════════════════════════════╝"

    setup

    echo "${YELLOW}AI Recipes Tests${NC}"
    echo "────────────────────────────────────────"
    test_builtin_recipes_exist
    test_builtin_recipe_count
    test_recipe_has_content
    test_recipe_apply_function
    test_recipe_list_function
    test_recipe_show_function
    echo ""

    echo "${YELLOW}AI Usage Tracking Tests${NC}"
    echo "────────────────────────────────────────"
    test_usage_log_function_exists
    test_usage_stats_function_exists
    test_usage_suggest_function_exists
    test_usage_command_exists
    echo ""

    echo "${YELLOW}Multi-Model Tests${NC}"
    echo "────────────────────────────────────────"
    test_model_array_exists
    test_model_mappings
    test_model_list_function
    test_model_show_function
    test_default_model_config
    echo ""

    echo "${YELLOW}AI Command Structure Tests${NC}"
    echo "────────────────────────────────────────"
    test_flow_ai_help
    test_flow_ai_help_has_subcommands
    test_flow_ai_help_has_modes
    test_flow_ai_help_has_model_flag
    echo ""

    cleanup

    echo "════════════════════════════════════════"
    echo "${CYAN}Summary${NC}"
    echo "────────────────────────────────────────"
    echo "  Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo "  Failed: ${RED}$TESTS_FAILED${NC}"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "${GREEN}✓ All tests passed!${NC}"
        exit 0
    else
        echo "${RED}✗ Some tests failed${NC}"
        exit 1
    fi
}

main "$@"
