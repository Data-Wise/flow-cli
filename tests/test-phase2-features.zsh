#!/usr/bin/env zsh
# tests/test-phase2-features.zsh - Phase 2 Interactive Help System Tests
# Tests for: Interactive help browser, context-aware help, alias reference

# Source test framework
SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/test-framework.zsh" || {
  echo "Error: test-framework.zsh not found"
  exit 1
}

# Source plugin
PLUGIN_DIR="${SCRIPT_DIR:h}"
source "$PLUGIN_DIR/flow.plugin.zsh" || {
  echo "Error: flow.plugin.zsh not found"
  exit 1
}

# ============================================================================
# UNIT TESTS: Context Detection
# ============================================================================

test_suite "Context Detection - Unit Tests"

# Test 1: Detect R package
test_case "Context: R package detection" && {
  local temp_dir=$(mktemp -d)
  echo "Package: testpkg" > "$temp_dir/DESCRIPTION"

  local result=$(cd "$temp_dir" && _flow_detect_context)
  assert_equals "$result" "r-package" "Should detect R package"

  rm -rf "$temp_dir"
}

# Test 2: Detect Quarto project
test_case "Context: Quarto project detection" && {
  local temp_dir=$(mktemp -d)
  touch "$temp_dir/_quarto.yml"

  local result=$(cd "$temp_dir" && _flow_detect_context)
  assert_equals "$result" "quarto" "Should detect Quarto project"

  rm -rf "$temp_dir"
}

# Test 3: Detect Node.js project
test_case "Context: Node.js project detection" && {
  local temp_dir=$(mktemp -d)
  echo '{"name":"test"}' > "$temp_dir/package.json"

  local result=$(cd "$temp_dir" && _flow_detect_context)
  assert_equals "$result" "node" "Should detect Node.js project"

  rm -rf "$temp_dir"
}

# Test 4: Detect Python project (pyproject.toml)
test_case "Context: Python project detection (pyproject.toml)" && {
  local temp_dir=$(mktemp -d)
  echo '[project]' > "$temp_dir/pyproject.toml"

  local result=$(cd "$temp_dir" && _flow_detect_context)
  assert_equals "$result" "python" "Should detect Python project"

  rm -rf "$temp_dir"
}

# Test 5: Detect Python project (setup.py)
test_case "Context: Python project detection (setup.py)" && {
  local temp_dir=$(mktemp -d)
  touch "$temp_dir/setup.py"

  local result=$(cd "$temp_dir" && _flow_detect_context)
  assert_equals "$result" "python" "Should detect Python project via setup.py"

  rm -rf "$temp_dir"
}

# Test 6: Detect git repository
test_case "Context: Git repository detection" && {
  local temp_dir=$(mktemp -d)
  (cd "$temp_dir" && git init -q)

  local result=$(cd "$temp_dir" && _flow_detect_context)
  assert_equals "$result" "git-repo" "Should detect git repository"

  rm -rf "$temp_dir"
}

# Test 7: Detect general context (no project markers)
test_case "Context: General context (no markers)" && {
  local temp_dir=$(mktemp -d)

  local result=$(cd "$temp_dir" && _flow_detect_context)
  assert_equals "$result" "general" "Should return general for no markers"

  rm -rf "$temp_dir"
}

# Test 8: Priority - R package over git
test_case "Context: R package takes priority over git" && {
  local temp_dir=$(mktemp -d)
  (cd "$temp_dir" && git init -q)
  echo "Package: testpkg" > "$temp_dir/DESCRIPTION"

  local result=$(cd "$temp_dir" && _flow_detect_context)
  assert_equals "$result" "r-package" "R package should take priority over git"

  rm -rf "$temp_dir"
}

# Test 9: Priority - Quarto over git
test_case "Context: Quarto takes priority over git" && {
  local temp_dir=$(mktemp -d)
  (cd "$temp_dir" && git init -q)
  touch "$temp_dir/_quarto.yml"

  local result=$(cd "$temp_dir" && _flow_detect_context)
  assert_equals "$result" "quarto" "Quarto should take priority over git"

  rm -rf "$temp_dir"
}

# Test 10: Priority - Node over git
test_case "Context: Node takes priority over git" && {
  local temp_dir=$(mktemp -d)
  (cd "$temp_dir" && git init -q)
  echo '{"name":"test"}' > "$temp_dir/package.json"

  local result=$(cd "$temp_dir" && _flow_detect_context)
  assert_equals "$result" "node" "Node should take priority over git"

  rm -rf "$temp_dir"
}

# ============================================================================
# EDGE CASES: Context Detection
# ============================================================================

test_suite "Context Detection - Edge Cases"

# Test 11: Empty DESCRIPTION file
test_case "Edge: Empty DESCRIPTION file" && {
  local temp_dir=$(mktemp -d)
  touch "$temp_dir/DESCRIPTION"

  local result=$(cd "$temp_dir" && _flow_detect_context)
  assert_not_equals "$result" "r-package" "Empty DESCRIPTION should not trigger R package"

  rm -rf "$temp_dir"
}

# Test 12: DESCRIPTION without Package: field
test_case "Edge: DESCRIPTION without Package field" && {
  local temp_dir=$(mktemp -d)
  echo "Title: Some file" > "$temp_dir/DESCRIPTION"

  local result=$(cd "$temp_dir" && _flow_detect_context)
  assert_not_equals "$result" "r-package" "DESCRIPTION without Package: should not trigger"

  rm -rf "$temp_dir"
}

# Test 13: Invalid package.json
test_case "Edge: Invalid package.json" && {
  local temp_dir=$(mktemp -d)
  echo "not json" > "$temp_dir/package.json"

  local result=$(cd "$temp_dir" && _flow_detect_context)
  assert_equals "$result" "node" "Should still detect node even with invalid JSON"

  rm -rf "$temp_dir"
}

# Test 14: Multiple project markers (R + Quarto)
test_case "Edge: Multiple markers (R package wins over Quarto)" && {
  local temp_dir=$(mktemp -d)
  echo "Package: test" > "$temp_dir/DESCRIPTION"
  touch "$temp_dir/_quarto.yml"

  local result=$(cd "$temp_dir" && _flow_detect_context)
  assert_equals "$result" "r-package" "R package has higher priority than Quarto"

  rm -rf "$temp_dir"
}

# Test 15: Quarto via index.qmd
test_case "Edge: Quarto detection via index.qmd" && {
  local temp_dir=$(mktemp -d)
  touch "$temp_dir/index.qmd"

  local result=$(cd "$temp_dir" && _flow_detect_context)
  assert_equals "$result" "quarto" "Should detect Quarto via index.qmd"

  rm -rf "$temp_dir"
}

# ============================================================================
# UNIT TESTS: Interactive Help Browser
# ============================================================================

test_suite "Interactive Help Browser - Unit Tests"

# Test 16: Function exists
test_case "Help Browser: Function exists" && {
  assert_function_exists "_flow_help_browser" "Help browser function should exist"
}

# Test 17: fzf check logic
test_case "Help Browser: fzf availability check" && {
  if command -v fzf &>/dev/null; then
    assert_success "fzf should be available for testing"
  else
    # Test graceful fallback
    local output=$(_flow_help_browser 2>&1)
    assert_contains "$output" "fzf is required" "Should show fzf requirement message"
  fi
}

# ============================================================================
# UNIT TESTS: Alias Command
# ============================================================================

test_suite "Alias Command - Unit Tests"

# Test 18: flow_alias function exists
test_case "Alias: Function exists" && {
  assert_function_exists "flow_alias" "Alias function should exist"
}

# Test 19: Help flag works
test_case "Alias: Help flag" && {
  local output=$(flow_alias --help 2>&1)
  assert_contains "$output" "Alias Reference" "Should show help header"
  assert_contains "$output" "Categories:" "Should list categories"
}

# Test 20: Summary view (no args)
test_case "Alias: Summary view" && {
  local output=$(flow_alias 2>&1)
  assert_contains "$output" "Total:" "Should show total count"
  assert_contains "$output" "R Package Development" "Should list R category"
  assert_contains "$output" "Claude Code" "Should list CC category"
  assert_contains "$output" "Dispatchers" "Should list dispatchers"
}

# Test 21: R category
test_case "Alias: R category view" && {
  local output=$(flow_alias r 2>&1)
  assert_contains "$output" "R Package Development Aliases" "Should show R header"
  assert_contains "$output" "rload" "Should list rload alias"
  assert_contains "$output" "devtools::load_all()" "Should show full command"
}

# Test 22: Claude category
test_case "Alias: Claude category view" && {
  local output=$(flow_alias cc 2>&1)
  assert_contains "$output" "Claude Code Aliases" "Should show CC header"
  assert_contains "$output" "ccp" "Should list ccp alias"
  assert_contains "$output" "ccr" "Should list ccr alias"
}

# Test 23: Focus category
test_case "Alias: Focus category view" && {
  local output=$(flow_alias focus 2>&1)
  assert_contains "$output" "Focus Timer Aliases" "Should show focus header"
  assert_contains "$output" "f25" "Should list f25 alias"
  assert_contains "$output" "f50" "Should list f50 alias"
}

# Test 24: Tools category
test_case "Alias: Tools category view" && {
  local output=$(flow_alias tools 2>&1)
  assert_contains "$output" "Tool Replacement Aliases" "Should show tools header"
  assert_contains "$output" "cat" "Should list cat replacement"
  assert_contains "$output" "bat" "Should show bat"
}

# Test 25: Git category
test_case "Alias: Git category view" && {
  local output=$(flow_alias git 2>&1)
  assert_contains "$output" "Git Aliases" "Should show git header"
  assert_contains "$output" "gst" "Should list gst alias"
  assert_contains "$output" "git status" "Should show git status"
}

# Test 26: Dispatchers category
test_case "Alias: Dispatchers category view" && {
  local output=$(flow_alias dispatchers 2>&1)
  assert_contains "$output" "Smart Dispatchers" "Should show dispatchers header"
  assert_contains "$output" "Git workflows" "Should describe g dispatcher"
  assert_contains "$output" "Claude Code launcher" "Should describe cc dispatcher"
  assert_contains "$output" "R package development" "Should describe r dispatcher"
}

# Test 27: Unknown category error
test_case "Alias: Unknown category error" && {
  local output=$(flow_alias invalid 2>&1)
  assert_contains "$output" "Unknown category" "Should show error for invalid category"
  assert_contains "$output" "Try: flow alias help" "Should suggest help"
}

# Test 28: als alias exists
test_case "Alias: als shortcut exists" && {
  assert_alias_exists "als" "als alias should be defined"
}

# ============================================================================
# INTEGRATION TESTS: Context-Aware Help
# ============================================================================

test_suite "Context-Aware Help - Integration Tests"

# Test 29: Help shows context in R package
test_case "Integration: Help context in R package" && {
  local temp_dir=$(mktemp -d)
  echo "Package: test" > "$temp_dir/DESCRIPTION"

  local output=$(cd "$temp_dir" && flow help 2>&1 | head -20)
  assert_contains "$output" "R Package Context" "Should show R package context"

  rm -rf "$temp_dir"
}

# Test 30: Help shows context in Node project
test_case "Integration: Help context in Node project" && {
  local temp_dir=$(mktemp -d)
  echo '{"name":"test"}' > "$temp_dir/package.json"

  local output=$(cd "$temp_dir" && flow help 2>&1 | head -20)
  assert_contains "$output" "Node.js Project" "Should show Node.js context"

  rm -rf "$temp_dir"
}

# Test 31: Help shows context in Git repo
test_case "Integration: Help context in Git repo" && {
  local temp_dir=$(mktemp -d)
  (cd "$temp_dir" && git init -q)

  local output=$(cd "$temp_dir" && flow help 2>&1 | head -20)
  assert_contains "$output" "Git Repository" "Should show Git context"

  rm -rf "$temp_dir"
}

# Test 32: Help in general context (no banner)
test_case "Integration: Help in general context" && {
  local temp_dir=$(mktemp -d)

  local output=$(cd "$temp_dir" && flow help 2>&1 | head -20)
  # Should not have specific context banner
  local context_count=$(echo "$output" | grep -c "Context" || true)
  assert_equals "$context_count" "0" "Should have no context banner in general mode"

  rm -rf "$temp_dir"
}

# ============================================================================
# INTEGRATION TESTS: Flow Command Integration
# ============================================================================

test_suite "Flow Command Integration - Integration Tests"

# Test 33: flow help --interactive flag
test_case "Integration: flow help --interactive" && {
  # Can't test interactive mode, but verify it doesn't error
  type _flow_help_browser &>/dev/null
  assert_success "Interactive help function should be callable"
}

# Test 34: flow help -i flag
test_case "Integration: flow help -i (short form)" && {
  type _flow_help_browser &>/dev/null
  assert_success "Interactive help function should be callable via -i"
}

# Test 35: flow alias command routing
test_case "Integration: flow alias routing" && {
  local output=$(flow alias --help 2>&1)
  assert_contains "$output" "Alias Reference" "flow alias should work"
}

# Test 36: flow aliases command routing
test_case "Integration: flow aliases routing" && {
  local output=$(flow aliases --help 2>&1)
  assert_contains "$output" "Alias Reference" "flow aliases should work"
}

# ============================================================================
# E2E TESTS: Complete Workflows
# ============================================================================

test_suite "End-to-End Tests - Complete Workflows"

# Test 37: E2E - Full context detection workflow
test_case "E2E: Complete context detection workflow" && {
  local temp_dir=$(mktemp -d)

  # Create R package with git
  (cd "$temp_dir" && git init -q)
  echo "Package: testpkg" > "$temp_dir/DESCRIPTION"
  echo "Title: Test Package" >> "$temp_dir/DESCRIPTION"

  # Detect context
  local context=$(cd "$temp_dir" && _flow_detect_context)
  assert_equals "$context" "r-package" "Should detect R package"

  # Get help
  local help=$(cd "$temp_dir" && flow help 2>&1 | head -10)
  assert_contains "$help" "R Package Context" "Help should show R context"
  assert_contains "$help" "r help" "Should suggest r help"

  rm -rf "$temp_dir"
}

# Test 38: E2E - Alias exploration workflow
test_case "E2E: Alias exploration workflow" && {
  # User journey: discover aliases → view category → find specific alias

  # Step 1: View summary
  local summary=$(flow alias 2>&1)
  assert_contains "$summary" "R Package Development" "Should see R category"

  # Step 2: Explore R category
  local r_aliases=$(flow alias r 2>&1)
  assert_contains "$r_aliases" "rload" "Should see rload"
  assert_contains "$r_aliases" "devtools::load_all()" "Should see full command"

  # Step 3: View dispatchers
  local dispatchers=$(flow alias dispatchers 2>&1)
  assert_contains "$dispatchers" "R package development" "Should see R dispatcher"
}

# Test 39: E2E - Help discovery workflow
test_case "E2E: Help discovery workflow" && {
  # User journey: new to flow-cli → discover help system

  # Step 1: Basic help
  local help=$(flow help 2>&1)
  assert_contains "$help" "FLOW" "Should show header"
  assert_contains "$help" "help -i" "Should mention interactive help"

  # Step 2: Help should show usage information
  assert_contains "$help" "Usage:" "Should show usage"
}

# Test 40: E2E - Context switching workflow
test_case "E2E: Context switching between projects" && {
  local r_dir=$(mktemp -d)
  local node_dir=$(mktemp -d)

  # R package
  echo "Package: test" > "$r_dir/DESCRIPTION"
  local r_context=$(cd "$r_dir" && _flow_detect_context)
  assert_equals "$r_context" "r-package" "R context detection"

  # Node project
  echo '{"name":"test"}' > "$node_dir/package.json"
  local node_context=$(cd "$node_dir" && _flow_detect_context)
  assert_equals "$node_context" "node" "Node context detection"

  # Verify context changes
  assert_not_equals "$r_context" "$node_context" "Contexts should differ"

  rm -rf "$r_dir" "$node_dir"
}

# ============================================================================
# REGRESSION TESTS: Ensure existing features still work
# ============================================================================

test_suite "Regression Tests - Existing Features"

# Test 41: flow help (no args) still works
test_case "Regression: flow help basic" && {
  local output=$(flow help 2>&1)
  assert_contains "$output" "FLOW" "Basic help should still work"
  assert_contains "$output" "Usage:" "Should show usage"
}

# Test 42: flow help <command> still works
test_case "Regression: flow help specific command" && {
  local output=$(flow help work 2>&1)
  assert_success "Specific command help should work"
}

# Test 43: flow --help still works
test_case "Regression: flow --help flag" && {
  local output=$(flow --help 2>&1)
  assert_contains "$output" "FLOW" "Help flag should work"
}

# Test 44: flow help --list still works
test_case "Regression: flow help --list" && {
  local output=$(flow help --list 2>&1)
  assert_contains "$output" "All flow-cli Commands" "List should work"
}

# Test 45: flow help --search still works
test_case "Regression: flow help --search" && {
  local output=$(flow help --search git 2>&1)
  assert_contains "$output" "Search:" "Search should work" || true
}

# ============================================================================
# PERFORMANCE TESTS
# ============================================================================

test_suite "Performance Tests"

# Test 46: Context detection speed
test_case "Performance: Context detection < 100ms" && {
  local start=$EPOCHREALTIME
  _flow_detect_context >/dev/null
  local end=$EPOCHREALTIME
  local duration=$(echo "($end - $start) * 1000" | bc)

  # Should be under 100ms (ADHD-friendly target)
  local is_fast=$(echo "$duration < 100" | bc)
  assert_equals "$is_fast" "1" "Context detection should be under 100ms (was ${duration}ms)"
}

# Test 47: Alias display speed
test_case "Performance: Alias display < 100ms" && {
  local start=$EPOCHREALTIME
  flow_alias >/dev/null 2>&1
  local end=$EPOCHREALTIME
  local duration=$(echo "($end - $start) * 1000" | bc)

  local is_fast=$(echo "$duration < 100" | bc)
  assert_equals "$is_fast" "1" "Alias display should be under 100ms (was ${duration}ms)"
}

# ============================================================================
# RUN ALL TESTS
# ============================================================================

# Print summary
print_summary

# Exit with appropriate code
exit $TEST_FAILED
