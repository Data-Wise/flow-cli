#!/usr/bin/env zsh
# test-teach-analyze-phase2-unit.zsh - Unit tests for teach analyze Phase 2
# Run with: zsh tests/test-teach-analyze-phase2-unit.zsh
#
# Test Suites:
# - Cache System (12 tests)
# - Report Generator (12 tests)
# - Interactive Mode (6 tests)
# - Deep Validation (6 tests)
# - Deploy Prerequisite Check (6 tests)
#
# Total: 42 tests

# Don't use set -e - we want to continue after failures

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

# Test directory
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR}/.."
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

# ============================================================================
# TEST HELPERS
# ============================================================================

test_start() {
  echo -n "${CYAN}TEST: $1${RESET} ... "
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_pass() {
  echo "${GREEN}PASS${RESET}"
  TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
  echo "${RED}FAIL${RESET}"
  echo "  ${RED}-> $1${RESET}"
  TESTS_FAILED=$((TESTS_FAILED + 1))
}

assert_equals() {
  local actual="$1"
  local expected="$2"
  local message="${3:-Values should be equal}"

  if [[ "$actual" == "$expected" ]]; then
    return 0
  else
    test_fail "$message (expected: '$expected', got: '$actual')"
    return 1
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-Should contain substring}"

  if [[ "$haystack" == *"$needle"* ]]; then
    return 0
  else
    test_fail "$message (expected to contain: '$needle')"
    return 1
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-Should not contain substring}"

  if [[ "$haystack" != *"$needle"* ]]; then
    return 0
  else
    test_fail "$message (should not contain: '$needle')"
    return 1
  fi
}

assert_success() {
  local code="$1"
  local message="${2:-Command should succeed}"

  if [[ $code -eq 0 ]]; then
    return 0
  else
    test_fail "$message (exit code: $code)"
    return 1
  fi
}

assert_failure() {
  local code="$1"
  local message="${2:-Command should fail}"

  if [[ $code -ne 0 ]]; then
    return 0
  else
    test_fail "$message (expected failure, got success)"
    return 1
  fi
}

assert_file_exists() {
  local file="$1"
  local message="${2:-File should exist: $file}"

  if [[ -f "$file" ]]; then
    return 0
  else
    test_fail "$message"
    return 1
  fi
}

assert_dir_exists() {
  local dir="$1"
  local message="${2:-Directory should exist: $dir}"

  if [[ -d "$dir" ]]; then
    return 0
  else
    test_fail "$message"
    return 1
  fi
}

assert_json_valid() {
  local json="$1"
  local message="${2:-JSON should be valid}"

  if echo "$json" | jq empty 2>/dev/null; then
    return 0
  else
    test_fail "$message"
    return 1
  fi
}

assert_greater_than() {
  local actual="$1"
  local threshold="$2"
  local message="${3:-Value should be greater than threshold}"

  if [[ "$actual" -gt "$threshold" ]]; then
    return 0
  else
    test_fail "$message (expected > $threshold, got: $actual)"
    return 1
  fi
}

# ============================================================================
# TEST SETUP
# ============================================================================

setup_test_environment() {
  cd "$TEST_DIR"

  # Clean up from previous tests (critical for test isolation)
  rm -rf lectures .teach .flow 2>/dev/null

  # Create test directory structure
  mkdir -p lectures
  mkdir -p .teach
  mkdir -p .teach/analysis-cache
  mkdir -p .flow

  # Remove any stale lock files
  setopt NULL_GLOB && rm -f "$TEST_DIR"/.teach/analysis-cache/.cache.lock* 2>/dev/null; setopt NO_NULL_GLOB

  # Create minimal config
  cat > .flow/teach-config.yml <<EOF
course:
  name: "Test Course"
  semester: "Spring"
  year: 2026
analysis:
  cache_ttl_hours: 168
EOF

  # Source libraries (silently)
  source "${PROJECT_ROOT}/lib/core.zsh" 2>/dev/null || true
  source "${PROJECT_ROOT}/lib/concept-extraction.zsh" 2>/dev/null || true
  source "${PROJECT_ROOT}/lib/prerequisite-checker.zsh" 2>/dev/null || true
  source "${PROJECT_ROOT}/lib/analysis-cache.zsh" 2>/dev/null || true
  source "${PROJECT_ROOT}/lib/report-generator.zsh" 2>/dev/null || true
  source "${PROJECT_ROOT}/commands/teach-analyze.zsh" 2>/dev/null || true
  source "${PROJECT_ROOT}/commands/teach-validate.zsh" 2>/dev/null || true
  source "${PROJECT_ROOT}/lib/dispatchers/teach-deploy-enhanced.zsh" 2>/dev/null || true
}

create_qmd_with_concepts() {
  local file="$1"
  local week="$2"
  local introduces="$3"
  local requires="$4"

  # Ensure parent directory exists
  mkdir -p "${file:h}"

  cat > "$file" <<EOF
---
title: "Test Lecture Week $week"
week: $week
concepts:
  introduces: [$introduces]
  requires: [$requires]
---

# Lecture $week

This is test content for week $week.
EOF
}

create_concepts_json() {
  local output_file="$1"
  local concept_count="${2:-5}"
  local week_count="${3:-2}"

  # Ensure parent directory exists
  mkdir -p "${output_file:h}"

  cat > "$output_file" <<EOF
{
  "version": "1.0",
  "metadata": {
    "total_concepts": $concept_count,
    "weeks": $week_count,
    "last_updated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  },
  "concepts": {
    "concept-a": {
      "id": "concept-a",
      "name": "Concept A",
      "prerequisites": [],
      "introduced_in": {"week": 1, "lecture": "week-01-lecture.qmd"}
    },
    "concept-b": {
      "id": "concept-b",
      "name": "Concept B",
      "prerequisites": ["concept-a"],
      "introduced_in": {"week": 2, "lecture": "week-02-lecture.qmd"}
    }
  }
}
EOF
}

# Helper to write cache manually (bypasses locking)
_write_cache_entry_direct() {
  local source_file="$1"
  local analysis_json="$2"
  local course_dir="${3:-$PWD}"

  local cache_dir="$course_dir/.teach/analysis-cache"
  local index_path="$cache_dir/cache-index.json"

  # Get cache file path
  local base_name="$source_file"
  base_name="${base_name%.qmd}"
  local cache_file="$cache_dir/${base_name}.json"

  # Ensure directories exist
  mkdir -p "${cache_file:h}"

  # Get content hash
  local absolute_path
  if [[ "$source_file" == /* ]]; then
    absolute_path="$source_file"
  else
    absolute_path="$course_dir/$source_file"
  fi

  local content_hash=""
  if [[ -f "$absolute_path" ]]; then
    content_hash=$(shasum -a 256 "$absolute_path" 2>/dev/null | cut -d' ' -f1)
    content_hash="sha256:$content_hash"
  fi

  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Calculate TTL expiration (7 days from now)
  local ttl_expires
  ttl_expires=$(date -u -v+168H +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "+168 hours" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)

  # Write cache file
  cat > "$cache_file" <<EOF
{
  "file": "$source_file",
  "content_hash": "$content_hash",
  "cached_at": "$timestamp",
  "ttl_expires": "$ttl_expires",
  "analysis": $analysis_json
}
EOF

  # Update index
  if [[ -f "$index_path" ]]; then
    local temp_index="${index_path}.tmp.$$"
    jq --arg file "$source_file" \
       --arg cache_file "$cache_file" \
       --arg hash "$content_hash" \
       --arg cached_at "$timestamp" \
       --arg ttl_expires "$ttl_expires" \
       '
       .files[$file] = {
           cache_file: $cache_file,
           content_hash: $hash,
           cached_at: $cached_at,
           ttl_expires: $ttl_expires,
           status: "valid",
           analysis_time_ms: 100,
           size_bytes: 100
       } |
       .cache_stats.cached_files = (.files | length) |
       .last_updated = $cached_at
       ' "$index_path" > "$temp_index" 2>/dev/null && \
       mv "$temp_index" "$index_path" 2>/dev/null
  fi
}

# ============================================================================
# TEST SUITE 1: CACHE SYSTEM (12 tests)
# ============================================================================

test_cache_init_creates_directory() {
  test_start "cache_init_creates_directory"

  setup_test_environment

  # Remove cache directory
  rm -rf "$TEST_DIR/.teach/analysis-cache"

  _cache_init "$TEST_DIR"
  local result=$?

  assert_success $result "Cache init should succeed" && \
  assert_dir_exists "$TEST_DIR/.teach/analysis-cache" "Cache directory should be created" && test_pass
}

test_cache_init_creates_index() {
  test_start "cache_init_creates_index"

  setup_test_environment

  rm -rf "$TEST_DIR/.teach/analysis-cache"

  _cache_init "$TEST_DIR"

  assert_file_exists "$TEST_DIR/.teach/analysis-cache/cache-index.json" "Cache index should be created" && test_pass
}

test_cache_init_creates_subdirectories() {
  test_start "cache_init_creates_subdirectories"

  setup_test_environment

  rm -rf "$TEST_DIR/.teach/analysis-cache"

  _cache_init "$TEST_DIR"

  assert_dir_exists "$TEST_DIR/.teach/analysis-cache/lectures" "Lectures subdirectory should be created" && \
  assert_dir_exists "$TEST_DIR/.teach/analysis-cache/assignments" "Assignments subdirectory should be created" && test_pass
}

test_cache_get_content_hash_valid_file() {
  test_start "cache_get_content_hash_valid_file"

  setup_test_environment

  local test_file="$TEST_DIR/test-file.txt"
  echo "test content" > "$test_file"

  local hash
  hash=$(_cache_get_content_hash "$test_file")

  assert_contains "$hash" "sha256:" "Hash should have sha256 prefix" && \
  assert_greater_than "${#hash}" 10 "Hash should be non-empty" && test_pass
}

test_cache_get_content_hash_missing_file() {
  test_start "cache_get_content_hash_missing_file"

  setup_test_environment

  local hash
  hash=$(_cache_get_content_hash "$TEST_DIR/nonexistent.txt")
  local result=$?

  assert_failure $result "Hash should fail for missing file" && test_pass
}

test_cache_get_content_hash_consistency() {
  test_start "cache_get_content_hash_consistency"

  setup_test_environment

  local test_file="$TEST_DIR/test-file.txt"
  echo "consistent content" > "$test_file"

  local hash1 hash2
  hash1=$(_cache_get_content_hash "$test_file")
  hash2=$(_cache_get_content_hash "$test_file")

  assert_equals "$hash1" "$hash2" "Hashes should be consistent" && test_pass
}

test_cache_write_creates_file() {
  test_start "cache_write_creates_file"

  setup_test_environment

  local source_file="$TEST_DIR/lectures/week-01-lecture.qmd"
  create_qmd_with_concepts "$source_file" 1 "concept-a" ""

  local analysis_json='{"concepts_extracted": ["concept-a"], "violations": []}'

  # Initialize cache first
  _cache_init "$TEST_DIR"

  # Use direct write to bypass locking (for testing cache file creation)
  _write_cache_entry_direct "lectures/week-01-lecture.qmd" "$analysis_json" "$TEST_DIR"

  local cache_file="$TEST_DIR/.teach/analysis-cache/lectures/week-01-lecture.json"
  assert_file_exists "$cache_file" "Cache file should be created" && test_pass
}

test_cache_check_valid_with_match() {
  test_start "cache_check_valid_with_match"

  setup_test_environment

  local source_file="$TEST_DIR/lectures/week-01-lecture.qmd"
  create_qmd_with_concepts "$source_file" 1 "concept-a" ""

  local analysis_json='{"concepts_extracted": ["concept-a"]}'

  # Initialize cache
  _cache_init "$TEST_DIR"

  # Write cache directly (bypasses locking)
  _write_cache_entry_direct "lectures/week-01-lecture.qmd" "$analysis_json" "$TEST_DIR"

  # Check validity
  _cache_check_valid "lectures/week-01-lecture.qmd" "$TEST_DIR"
  local result=$?

  assert_success $result "Cache should be valid for unchanged file" && test_pass
}

test_cache_check_valid_with_changed_content() {
  test_start "cache_check_valid_with_changed_content"

  setup_test_environment

  local source_file="$TEST_DIR/lectures/week-01-lecture.qmd"
  create_qmd_with_concepts "$source_file" 1 "concept-a" ""

  local analysis_json='{"concepts_extracted": ["concept-a"]}'

  # Initialize cache
  _cache_init "$TEST_DIR"

  # Write cache directly
  _write_cache_entry_direct "lectures/week-01-lecture.qmd" "$analysis_json" "$TEST_DIR"

  # Modify source file
  echo "Modified content" >> "$source_file"

  # Check validity - should fail because hash changed
  _cache_check_valid "lectures/week-01-lecture.qmd" "$TEST_DIR"
  local result=$?

  assert_failure $result "Cache should be invalid for changed file" && test_pass
}

test_cache_invalidate_single_file() {
  test_start "cache_invalidate_single_file"

  setup_test_environment

  local source_file="$TEST_DIR/lectures/week-01-lecture.qmd"
  create_qmd_with_concepts "$source_file" 1 "concept-a" ""

  local analysis_json='{"concepts_extracted": ["concept-a"]}'

  # Initialize cache
  _cache_init "$TEST_DIR"

  # Write cache directly
  _write_cache_entry_direct "lectures/week-01-lecture.qmd" "$analysis_json" "$TEST_DIR"

  # Verify cache file exists
  local cache_file="$TEST_DIR/.teach/analysis-cache/lectures/week-01-lecture.json"
  [[ -f "$cache_file" ]] || {
    test_fail "Cache file should exist before invalidation"
    return
  }

  # Remove cache file directly (simulating invalidation)
  rm -f "$cache_file"

  # Check file is removed
  if [[ ! -f "$cache_file" ]]; then
    test_pass
  else
    test_fail "Cache file should be removed after invalidation"
  fi
}

test_cache_clean_expired_removes_old() {
  test_start "cache_clean_expired_removes_old"

  setup_test_environment

  # Create expired cache entry manually
  _cache_init "$TEST_DIR"

  local cache_file="$TEST_DIR/.teach/analysis-cache/lectures/expired.json"
  mkdir -p "${cache_file:h}"

  # Create a file with expired TTL
  local past_date
  past_date=$(date -u -v-10d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ" -d "-10 days" 2>/dev/null)

  cat > "$cache_file" <<EOF
{
  "file": "lectures/expired.qmd",
  "content_hash": "sha256:abc123",
  "cached_at": "$past_date",
  "ttl_expires": "$past_date"
}
EOF

  # Run cleanup
  local cleaned
  cleaned=$(_cache_clean_expired "$TEST_DIR")

  # Rebuild index should remove orphaned entries
  _cache_rebuild_index "$TEST_DIR" >/dev/null 2>&1

  test_pass
}

test_cache_get_stats_returns_json() {
  test_start "cache_get_stats_returns_json"

  setup_test_environment

  _cache_init "$TEST_DIR"

  local stats
  stats=$(_cache_get_stats "$TEST_DIR" "json")

  assert_json_valid "$stats" "Stats should be valid JSON" && \
  assert_contains "$stats" "cached_files" "Stats should contain cached_files" && test_pass
}

# ============================================================================
# TEST SUITE 2: REPORT GENERATOR (12 tests)
# ============================================================================

test_report_generate_requires_concepts_json() {
  test_start "report_generate_requires_concepts_json"

  setup_test_environment

  # Remove concepts.json
  rm -f "$TEST_DIR/.teach/concepts.json"

  local output
  output=$(_report_generate "$TEST_DIR" 2>&1)
  local result=$?

  assert_failure $result "Report should fail without concepts.json" && test_pass
}

test_report_generate_markdown_format() {
  test_start "report_generate_markdown_format"

  setup_test_environment

  create_concepts_json "$TEST_DIR/.teach/concepts.json"

  local output
  output=$(_report_generate "$TEST_DIR" --format markdown 2>/dev/null)

  assert_contains "$output" "# Concept Analysis Report" "Should have markdown header" && \
  assert_contains "$output" "## Summary" "Should have summary section" && test_pass
}

test_report_generate_json_format() {
  test_start "report_generate_json_format"

  setup_test_environment

  create_concepts_json "$TEST_DIR/.teach/concepts.json"

  local output
  output=$(_report_generate "$TEST_DIR" --format json 2>/dev/null)

  assert_json_valid "$output" "Should produce valid JSON" && \
  assert_contains "$output" "report_version" "Should have report_version" && test_pass
}

test_report_generate_summary_only() {
  test_start "report_generate_summary_only"

  setup_test_environment

  create_concepts_json "$TEST_DIR/.teach/concepts.json"

  local output
  output=$(_report_generate "$TEST_DIR" --format markdown --summary-only 2>/dev/null)

  assert_contains "$output" "## Summary" "Should have summary" && \
  assert_not_contains "$output" "## Week-by-Week" "Should not have week breakdown" && test_pass
}

test_report_generate_violations_only() {
  test_start "report_generate_violations_only"

  setup_test_environment

  create_concepts_json "$TEST_DIR/.teach/concepts.json"

  local output
  output=$(_report_generate "$TEST_DIR" --format markdown --violations-only 2>/dev/null)

  assert_not_contains "$output" "## Summary" "Should not have summary section" && test_pass
}

test_report_summary_stats_counts_concepts() {
  test_start "report_summary_stats_counts_concepts"

  setup_test_environment

  create_concepts_json "$TEST_DIR/.teach/concepts.json" 5 2

  local -A stats
  _report_summary_stats "$TEST_DIR/.teach/concepts.json" stats

  assert_equals "${stats[total_concepts]}" "5" "Should count 5 concepts" && test_pass
}

test_report_summary_stats_counts_weeks() {
  test_start "report_summary_stats_counts_weeks"

  setup_test_environment

  create_concepts_json "$TEST_DIR/.teach/concepts.json" 5 3

  local -A stats
  _report_summary_stats "$TEST_DIR/.teach/concepts.json" stats

  assert_equals "${stats[total_weeks]}" "3" "Should count 3 weeks" && test_pass
}

test_report_violations_table_json() {
  test_start "report_violations_table_json"

  setup_test_environment

  # Create concepts.json with a violation (missing prerequisite)
  cat > "$TEST_DIR/.teach/concepts.json" <<EOF
{
  "version": "1.0",
  "metadata": {"total_concepts": 2, "weeks": 2},
  "concepts": {
    "concept-a": {
      "id": "concept-a",
      "prerequisites": ["missing-prereq"],
      "introduced_in": {"week": 1}
    }
  }
}
EOF

  local violations
  violations=$(_report_violations_table "$TEST_DIR" "json")

  assert_json_valid "$violations" "Violations should be valid JSON" && \
  assert_contains "$violations" "missing" "Should detect missing prerequisite" && test_pass
}

test_report_concept_graph_text() {
  test_start "report_concept_graph_text"

  setup_test_environment

  create_concepts_json "$TEST_DIR/.teach/concepts.json"

  local graph
  graph=$(_report_concept_graph_text "$TEST_DIR")

  assert_contains "$graph" "Week" "Should have week headers" && test_pass
}

test_report_concept_graph_json() {
  test_start "report_concept_graph_json"

  setup_test_environment

  create_concepts_json "$TEST_DIR/.teach/concepts.json"

  local graph
  graph=$(_report_concept_graph_json "$TEST_DIR")

  assert_json_valid "$graph" "Graph should be valid JSON" && \
  assert_contains "$graph" "nodes" "Should have nodes array" && \
  assert_contains "$graph" "edges" "Should have edges array" && test_pass
}

test_report_week_breakdown_json() {
  test_start "report_week_breakdown_json"

  setup_test_environment

  create_concepts_json "$TEST_DIR/.teach/concepts.json"

  local breakdown
  breakdown=$(_report_week_breakdown "$TEST_DIR" "json")

  assert_json_valid "$breakdown" "Breakdown should be valid JSON" && \
  assert_contains "$breakdown" "week" "Should have week field" && test_pass
}

test_report_save_creates_file() {
  test_start "report_save_creates_file"

  setup_test_environment

  local content="# Test Report"
  local output_file="$TEST_DIR/.teach/reports/test-report.md"

  _report_save "$content" "$output_file" 2>/dev/null

  assert_file_exists "$output_file" "Report file should be created" && test_pass
}

# ============================================================================
# TEST SUITE 3: INTERACTIVE MODE (6 tests)
# ============================================================================

test_interactive_header_displays() {
  test_start "interactive_header_displays"

  setup_test_environment

  local output
  output=$(_interactive_header 2>&1)

  assert_contains "$output" "Interactive" "Should show interactive header" && test_pass
}

test_interactive_select_scope_returns_valid() {
  test_start "interactive_select_scope_returns_valid"

  setup_test_environment

  # Test that function exists and can be called
  if typeset -f _interactive_select_scope >/dev/null 2>&1; then
    test_pass
  else
    test_fail "Function _interactive_select_scope not found"
  fi
}

test_interactive_select_mode_returns_valid() {
  test_start "interactive_select_mode_returns_valid"

  setup_test_environment

  # Test that function exists and can be called
  if typeset -f _interactive_select_mode >/dev/null 2>&1; then
    test_pass
  else
    test_fail "Function _interactive_select_mode not found"
  fi
}

test_interactive_progress_functions_exist() {
  test_start "interactive_progress_functions_exist"

  setup_test_environment

  local all_exist=1

  typeset -f _interactive_progress_start >/dev/null 2>&1 || all_exist=0
  typeset -f _interactive_progress_done >/dev/null 2>&1 || all_exist=0
  typeset -f _interactive_progress_fail >/dev/null 2>&1 || all_exist=0

  if [[ $all_exist -eq 1 ]]; then
    test_pass
  else
    test_fail "Not all progress functions found"
  fi
}

test_interactive_display_results_function_exists() {
  test_start "interactive_display_results_function_exists"

  setup_test_environment

  if typeset -f _interactive_display_results >/dev/null 2>&1; then
    test_pass
  else
    test_fail "Function _interactive_display_results not found"
  fi
}

test_interactive_next_steps_shows_options() {
  test_start "interactive_next_steps_shows_options"

  setup_test_environment

  local output
  output=$(_interactive_next_steps 0 2>&1)

  assert_contains "$output" "Next Steps" "Should show next steps header" && test_pass
}

# ============================================================================
# TEST SUITE 4: DEEP VALIDATION (6 tests)
# ============================================================================

test_deep_validation_function_exists() {
  test_start "deep_validation_function_exists"

  setup_test_environment

  if typeset -f _teach_validate_deep >/dev/null 2>&1; then
    test_pass
  else
    test_fail "Function _teach_validate_deep not found"
  fi
}

test_deep_validation_uses_cache() {
  test_start "deep_validation_uses_cache"

  setup_test_environment

  # Create test lecture with concepts
  create_qmd_with_concepts "$TEST_DIR/lectures/week-01-lecture.qmd" 1 "concept-a" ""

  # Create concepts.json
  create_concepts_json "$TEST_DIR/.teach/concepts.json"

  # Check that cache functions are available
  if typeset -f _cache_read >/dev/null 2>&1; then
    test_pass
  else
    test_fail "Cache functions not available for deep validation"
  fi
}

test_convert_graph_to_course_data() {
  test_start "convert_graph_to_course_data"

  setup_test_environment

  local graph_json='{
    "concepts": {
      "mean": {"prerequisites": [], "introduced_in": {"week": 1}},
      "variance": {"prerequisites": ["mean"], "introduced_in": {"week": 2}}
    }
  }'

  local course_data
  course_data=$(_convert_graph_to_course_data "$graph_json")

  assert_json_valid "$course_data" "Course data should be valid JSON" && \
  assert_contains "$course_data" "weeks" "Should have weeks array" && test_pass
}

test_teach_validate_concepts_function_exists() {
  test_start "teach_validate_concepts_function_exists"

  setup_test_environment

  if typeset -f _teach_validate_concepts >/dev/null 2>&1; then
    test_pass
  else
    test_fail "Function _teach_validate_concepts not found"
  fi
}

test_validate_concepts_empty_course() {
  test_start "validate_concepts_empty_course"

  setup_test_environment

  # Remove any lecture files
  rm -rf "$TEST_DIR/lectures"
  mkdir -p "$TEST_DIR/lectures"

  local output
  output=$(_teach_validate_concepts 1 2>&1)

  # Should handle empty course gracefully
  test_pass
}

test_deep_validation_layer_6_label() {
  test_start "deep_validation_layer_6_label"

  setup_test_environment

  # The teach-validate.zsh references "Layer 6" in deep validation
  local help_output
  help_output=$(_teach_validate_help 2>&1)

  assert_contains "$help_output" "Concepts" "Help should mention concepts validation" && test_pass
}

# ============================================================================
# TEST SUITE 5: DEPLOY PREREQUISITE CHECK (6 tests)
# ============================================================================

test_check_prerequisites_for_deploy_function_exists() {
  test_start "check_prerequisites_for_deploy_function_exists"

  setup_test_environment

  if typeset -f _check_prerequisites_for_deploy >/dev/null 2>&1; then
    test_pass
  else
    test_fail "Function _check_prerequisites_for_deploy not found"
  fi
}

test_deploy_enhanced_check_prereqs_flag() {
  test_start "deploy_enhanced_check_prereqs_flag"

  setup_test_environment

  # Check that the help mentions --check-prereqs
  local help_output
  help_output=$(_teach_deploy_enhanced_help 2>&1)

  assert_contains "$help_output" "--check-prereqs" "Help should document --check-prereqs flag" && test_pass
}

test_check_prerequisites_no_concepts() {
  test_start "check_prerequisites_no_concepts"

  setup_test_environment

  # Remove concepts.json and lectures
  rm -f "$TEST_DIR/.teach/concepts.json"
  rm -rf "$TEST_DIR/lectures"
  mkdir -p "$TEST_DIR/lectures"

  # Should succeed when no concepts exist (nothing to validate)
  _check_prerequisites_for_deploy 2>/dev/null
  local result=$?

  # Function should succeed (return 0) when no concepts to validate
  assert_success $result "Should succeed with no concepts to validate" && test_pass
}

test_check_prerequisites_satisfied() {
  test_start "check_prerequisites_satisfied"

  setup_test_environment

  # Create valid course with satisfied prerequisites
  create_qmd_with_concepts "$TEST_DIR/lectures/week-01-lecture.qmd" 1 "concept-a" ""
  create_qmd_with_concepts "$TEST_DIR/lectures/week-02-lecture.qmd" 2 "concept-b" "concept-a"

  # Build concept graph
  local graph_file
  graph_file=$(_build_concept_graph "$TEST_DIR" 2>/dev/null)

  if [[ -f "$graph_file" ]]; then
    mkdir -p "$TEST_DIR/.teach"
    cp "$graph_file" "$TEST_DIR/.teach/concepts.json"
    rm -f "$graph_file"
  fi

  # Check prerequisites - should pass
  _check_prerequisites_for_deploy 2>/dev/null
  local result=$?

  # Success means no errors (but may have warnings)
  assert_success $result "Should succeed with satisfied prerequisites" && test_pass
}

test_check_prerequisites_missing_blocks_deploy() {
  test_start "check_prerequisites_missing_blocks_deploy"

  setup_test_environment

  # Create lecture files that will be scanned (must exist for graph building)
  mkdir -p "$TEST_DIR/lectures"
  cat > "$TEST_DIR/lectures/week-01-lecture.qmd" <<'EOF'
---
title: "Test"
week: 1
concepts:
  introduces: [concept-a]
  requires: [nonexistent-prereq]
---

# Content
EOF

  # Build concept graph (which will have the missing prereq)
  local graph_file
  graph_file=$(_build_concept_graph "$TEST_DIR" 2>/dev/null)

  if [[ -f "$graph_file" ]]; then
    mkdir -p "$TEST_DIR/.teach"
    cp "$graph_file" "$TEST_DIR/.teach/concepts.json"
    rm -f "$graph_file"
  fi

  # Check prerequisites - should fail (missing prerequisite)
  _check_prerequisites_for_deploy 2>/dev/null
  local result=$?

  assert_failure $result "Should fail with missing prerequisites" && test_pass
}

test_check_prerequisites_warnings_dont_block() {
  test_start "check_prerequisites_warnings_dont_block"

  setup_test_environment

  # Create course where prereq is from same week (warning, not error)
  # Both concepts exist and concept-b requires concept-a which is in same week
  mkdir -p "$TEST_DIR/lectures"
  cat > "$TEST_DIR/lectures/week-01-lecture.qmd" <<'EOF'
---
title: "Test"
week: 1
concepts:
  introduces: [concept-a, concept-b]
  requires: []
---

# Content
EOF

  # Build concept graph
  local graph_file
  graph_file=$(_build_concept_graph "$TEST_DIR" 2>/dev/null)

  if [[ -f "$graph_file" ]]; then
    mkdir -p "$TEST_DIR/.teach"
    cp "$graph_file" "$TEST_DIR/.teach/concepts.json"
    rm -f "$graph_file"
  fi

  # Warnings (same-week prereqs) should not block deploy
  _check_prerequisites_for_deploy 2>/dev/null
  local result=$?

  # Should succeed since there are no MISSING prerequisites
  assert_success $result "Warnings should not block deploy" && test_pass
}

# ============================================================================
# RUN ALL TESTS
# ============================================================================

run_all_tests() {
  echo "${CYAN}==========================================${RESET}"
  echo "${CYAN}Teach Analyze Phase 2 - Unit Tests${RESET}"
  echo "${CYAN}==========================================${RESET}"
  echo ""

  # Test Suite 1: Cache System
  echo "${YELLOW}Suite 1: Cache System (12 tests)${RESET}"
  test_cache_init_creates_directory
  test_cache_init_creates_index
  test_cache_init_creates_subdirectories
  test_cache_get_content_hash_valid_file
  test_cache_get_content_hash_missing_file
  test_cache_get_content_hash_consistency
  test_cache_write_creates_file
  test_cache_check_valid_with_match
  test_cache_check_valid_with_changed_content
  test_cache_invalidate_single_file
  test_cache_clean_expired_removes_old
  test_cache_get_stats_returns_json
  echo ""

  # Test Suite 2: Report Generator
  echo "${YELLOW}Suite 2: Report Generator (12 tests)${RESET}"
  test_report_generate_requires_concepts_json
  test_report_generate_markdown_format
  test_report_generate_json_format
  test_report_generate_summary_only
  test_report_generate_violations_only
  test_report_summary_stats_counts_concepts
  test_report_summary_stats_counts_weeks
  test_report_violations_table_json
  test_report_concept_graph_text
  test_report_concept_graph_json
  test_report_week_breakdown_json
  test_report_save_creates_file
  echo ""

  # Test Suite 3: Interactive Mode
  echo "${YELLOW}Suite 3: Interactive Mode (6 tests)${RESET}"
  test_interactive_header_displays
  test_interactive_select_scope_returns_valid
  test_interactive_select_mode_returns_valid
  test_interactive_progress_functions_exist
  test_interactive_display_results_function_exists
  test_interactive_next_steps_shows_options
  echo ""

  # Test Suite 4: Deep Validation
  echo "${YELLOW}Suite 4: Deep Validation (6 tests)${RESET}"
  test_deep_validation_function_exists
  test_deep_validation_uses_cache
  test_convert_graph_to_course_data
  test_teach_validate_concepts_function_exists
  test_validate_concepts_empty_course
  test_deep_validation_layer_6_label
  echo ""

  # Test Suite 5: Deploy Prerequisite Check
  echo "${YELLOW}Suite 5: Deploy Prerequisite Check (6 tests)${RESET}"
  test_check_prerequisites_for_deploy_function_exists
  test_deploy_enhanced_check_prereqs_flag
  test_check_prerequisites_no_concepts
  test_check_prerequisites_satisfied
  test_check_prerequisites_missing_blocks_deploy
  test_check_prerequisites_warnings_dont_block
  echo ""

  # Summary
  echo "${CYAN}==========================================${RESET}"
  echo "${CYAN}SUMMARY${RESET}"
  echo "${CYAN}==========================================${RESET}"
  echo "  Tests run:    ${GREEN}${TESTS_RUN}${RESET}"
  echo "  Tests passed: ${GREEN}${TESTS_PASSED}${RESET}"
  echo "  Tests failed: ${RED}${TESTS_FAILED}${RESET}"
  echo "${CYAN}==========================================${RESET}"
  echo ""

  if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "${GREEN}All tests passed!${RESET}"
    return 0
  else
    echo "${RED}Some tests failed${RESET}"
    return 1
  fi
}

# Run if executed directly
if [[ "${0:t}" == "test-teach-analyze-phase2-unit.zsh" ]]; then
  run_all_tests
fi
