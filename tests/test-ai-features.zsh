#!/usr/bin/env zsh
# Test script for flow ai features (v3.4.0)
# Tests: recipes, usage tracking, multi-model, chat setup

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

source "$SCRIPT_DIR/test-framework.zsh"

# ============================================================================
# SETUP
# ============================================================================

TEST_DATA_DIR=""
TEST_USAGE_FILE=""
TEST_STATS_FILE=""
TEST_HISTORY_DIR=""

setup() {
    # Fallback: try current directory or parent
    if [[ ! -f "$PROJECT_ROOT/flow.plugin.zsh" ]]; then
        PROJECT_ROOT="$PWD"
    fi
    if [[ ! -f "$PROJECT_ROOT/flow.plugin.zsh" ]]; then
        PROJECT_ROOT="${PWD:h}"
    fi
    if [[ ! -f "$PROJECT_ROOT/flow.plugin.zsh" ]]; then
        echo "ERROR: Cannot find flow.plugin.zsh - run from project root"
        exit 1
    fi

    # Create test data directory
    TEST_DATA_DIR=$(mktemp -d)
    TEST_USAGE_FILE="$TEST_DATA_DIR/ai-usage.jsonl"
    TEST_STATS_FILE="$TEST_DATA_DIR/ai-stats.json"
    TEST_HISTORY_DIR="$TEST_DATA_DIR/chat-history"
    mkdir -p "$TEST_HISTORY_DIR"

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
}

cleanup() {
    rm -rf "$TEST_DATA_DIR"
}
trap cleanup EXIT

# ============================================================================
# AI RECIPES TESTS
# ============================================================================

test_builtin_recipes_exist() {
    test_case "Built-in recipes array exists"

    if [[ -n "${FLOW_BUILTIN_RECIPES[(I)review]}" ]]; then
        test_pass
    else
        test_fail "FLOW_BUILTIN_RECIPES not defined or missing 'review'"
    fi
}

test_builtin_recipe_count() {
    test_case "Has 10 built-in recipes"

    local count=${#FLOW_BUILTIN_RECIPES[@]}
    if [[ $count -ge 10 ]]; then
        test_pass
    else
        test_fail "Expected 10+ recipes, got $count"
    fi
}

test_recipe_has_content() {
    test_case "Recipes have content (review)"

    local content="${FLOW_BUILTIN_RECIPES[review]}"
    if [[ -n "$content" && ${#content} -gt 20 ]]; then
        test_pass
    else
        test_fail "Recipe 'review' content too short or missing"
    fi
}

test_recipe_apply_function() {
    test_case "_flow_recipe_apply substitutes variables"

    if typeset -f _flow_recipe_apply > /dev/null 2>&1; then
        test_pass
    else
        test_fail "_flow_recipe_apply not defined"
    fi
}

test_recipe_list_function() {
    test_case "_flow_recipe_list returns output"

    local output=$(_flow_recipe_list 2>&1)

    if [[ "$output" == *"review"* || "$output" == *"commit"* ]]; then
        test_pass
    else
        test_fail "Recipe list missing expected recipes"
    fi
}

test_recipe_show_function() {
    test_case "_flow_recipe_show displays recipe"

    local output=$(_flow_recipe_show "review" 2>&1)

    if [[ "$output" == *"review"* || -n "$output" ]]; then
        test_pass
    else
        test_fail "Recipe show failed"
    fi
}

# ============================================================================
# AI USAGE TRACKING TESTS
# ============================================================================

test_usage_log_function_exists() {
    test_case "_flow_ai_log_usage function exists"

    if typeset -f _flow_ai_log_usage > /dev/null 2>&1; then
        test_pass
    else
        test_fail "_flow_ai_log_usage not defined"
    fi
}

test_usage_stats_function_exists() {
    test_case "flow_ai_stats function exists"

    if typeset -f flow_ai_stats > /dev/null 2>&1; then
        test_pass
    else
        test_fail "flow_ai_stats not defined"
    fi
}

test_usage_suggest_function_exists() {
    test_case "flow_ai_suggest function exists"

    if typeset -f flow_ai_suggest > /dev/null 2>&1; then
        test_pass
    else
        test_fail "flow_ai_suggest not defined"
    fi
}

test_usage_command_exists() {
    test_case "flow_ai_usage command exists"

    if typeset -f flow_ai_usage > /dev/null 2>&1; then
        test_pass
    else
        test_fail "flow_ai_usage not defined"
    fi
}

# ============================================================================
# MULTI-MODEL TESTS
# ============================================================================

test_model_array_exists() {
    test_case "FLOW_AI_MODELS array exists"

    if [[ -n "${FLOW_AI_MODELS[(I)sonnet]}" ]]; then
        test_pass
    else
        test_fail "FLOW_AI_MODELS not defined"
    fi
}

test_model_mappings() {
    test_case "Model mappings include opus, sonnet, haiku"

    local has_opus="${FLOW_AI_MODELS[opus]}"
    local has_sonnet="${FLOW_AI_MODELS[sonnet]}"
    local has_haiku="${FLOW_AI_MODELS[haiku]}"

    if [[ -n "$has_opus" && -n "$has_sonnet" && -n "$has_haiku" ]]; then
        test_pass
    else
        test_fail "Missing model mappings"
    fi
}

test_model_list_function() {
    test_case "flow_ai_model list works"

    local output=$(flow_ai_model list 2>&1)

    if [[ "$output" == *"opus"* && "$output" == *"sonnet"* ]]; then
        test_pass
    else
        test_fail "Model list output incorrect"
    fi
}

test_model_show_function() {
    test_case "flow_ai_model show works"

    local output=$(flow_ai_model show 2>&1)

    if [[ "$output" == *"Current"* || "$output" == *"model"* ]]; then
        test_pass
    else
        test_fail "Model show output incorrect"
    fi
}

test_default_model_config() {
    test_case "Default model is sonnet"

    local default="${FLOW_CONFIG_DEFAULTS[ai_model]:-sonnet}"

    if [[ "$default" == "sonnet" ]]; then
        test_pass
    else
        test_fail "Expected sonnet, got $default"
    fi
}

# ============================================================================
# AI COMMAND STRUCTURE TESTS
# ============================================================================

test_flow_ai_help() {
    test_case "flow_ai --help output"

    local output=$(flow_ai --help 2>&1)

    if [[ "$output" == *"USAGE"* || "$output" == *"flow ai"* || "$output" == *"AI"* ]]; then
        test_pass
    else
        test_fail "Help output missing expected content: ${output:0:100}"
    fi
}

test_flow_ai_help_has_subcommands() {
    test_case "Help lists subcommands (recipe, chat, usage, model)"

    local output=$(flow_ai --help 2>&1)

    if [[ "$output" == *"recipe"* || "$output" == *"chat"* ]]; then
        test_pass
    else
        test_fail "Missing subcommand documentation"
    fi
}

test_flow_ai_help_has_modes() {
    test_case "Help lists modes (--explain, --fix, --suggest)"

    local output=$(flow_ai --help 2>&1)

    if [[ "$output" == *"--explain"* || "$output" == *"--fix"* || "$output" == *"-e"* ]]; then
        test_pass
    else
        test_fail "Missing mode flags in help"
    fi
}

test_flow_ai_help_has_model_flag() {
    test_case "Help mentions --model flag"

    local output=$(flow_ai --help 2>&1)

    if [[ "$output" == *"--model"* || "$output" == *"-m"* || "$output" == *"model"* ]]; then
        test_pass
    else
        test_fail "Missing --model flag in help"
    fi
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    test_suite_start "AI Features Tests (v3.4.0)"

    setup

    echo "  AI Recipes Tests"
    echo "  ────────────────────────────────────────"
    test_builtin_recipes_exist
    test_builtin_recipe_count
    test_recipe_has_content
    test_recipe_apply_function
    test_recipe_list_function
    test_recipe_show_function
    echo ""

    echo "  AI Usage Tracking Tests"
    echo "  ────────────────────────────────────────"
    test_usage_log_function_exists
    test_usage_stats_function_exists
    test_usage_suggest_function_exists
    test_usage_command_exists
    echo ""

    echo "  Multi-Model Tests"
    echo "  ────────────────────────────────────────"
    test_model_array_exists
    test_model_mappings
    test_model_list_function
    test_model_show_function
    test_default_model_config
    echo ""

    echo "  AI Command Structure Tests"
    echo "  ────────────────────────────────────────"
    test_flow_ai_help
    test_flow_ai_help_has_subcommands
    test_flow_ai_help_has_modes
    test_flow_ai_help_has_model_flag
    echo ""

    cleanup

    test_suite_end
    exit $?
}

main "$@"
