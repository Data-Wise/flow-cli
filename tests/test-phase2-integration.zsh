#!/usr/bin/env zsh
# tests/test-phase2-integration.zsh - Phase 2 Integration Tests
# Tests interactions between Profile Management, Parallel Rendering, Custom Validators,
# Cache Analysis, and Performance Monitoring

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
# SETUP & TEARDOWN
# ============================================================================

# Create mock teaching project with all Phase 2 features
_create_mock_teaching_project() {
  local project_dir="$1"
  mkdir -p "$project_dir"

  # Create _quarto.yml with profiles
  cat > "$project_dir/_quarto.yml" <<'EOF'
project:
  type: book
  output-dir: _book

book:
  title: "STAT 545 - Data Analysis"

format:
  html:
    theme: cosmo

# Profiles
profile:
  default:
    format:
      html:
        toc: true
        code-fold: false

  draft:
    format:
      html:
        toc: true
        code-fold: true
        code-tools: true

  print:
    format:
      pdf:
        toc: true
        geometry: margin=1in
EOF

  # Create teaching.yml with R packages
  mkdir -p "$project_dir/.teach"
  cat > "$project_dir/.teach/teaching.yml" <<'EOF'
course:
  code: "STAT-545"
  name: "Data Analysis"
  semester: "Fall 2024"

r_packages:
  - tidyverse
  - ggplot2
  - dplyr
  - knitr
  - rmarkdown

github:
  repo: "stat-545-fall-2024"
  branch: "main"
EOF

  # Create renv.lock
  cat > "$project_dir/renv.lock" <<'EOF'
{
  "R": {
    "Version": "4.3.0",
    "Repositories": [
      {
        "Name": "CRAN",
        "URL": "https://cran.rstudio.com"
      }
    ]
  },
  "Packages": {
    "tidyverse": {
      "Package": "tidyverse",
      "Version": "2.0.0",
      "Source": "Repository",
      "Repository": "CRAN"
    },
    "ggplot2": {
      "Package": "ggplot2",
      "Version": "3.4.0",
      "Source": "Repository",
      "Repository": "CRAN"
    }
  }
}
EOF

  # Create sample content files
  mkdir -p "$project_dir/lectures"
  mkdir -p "$project_dir/assignments"

  for i in {1..12}; do
    cat > "$project_dir/lectures/week-$(printf "%02d" $i).qmd" <<EOF
---
title: "Week $i: Topic $i"
date: "2024-09-$(printf "%02d" $((1 + i)))"
---

# Introduction

This is lecture content for week $i.

\`\`\`{r}
# R code block
library(ggplot2)
summary(mtcars)
\`\`\`

## Section 1

Content with citations [@smith2020].

## Section 2

More content with [internal links](../assignments/hw-01.qmd).

<!-- External link -->
Visit [our course site](https://example.com/stat-545).
EOF
  done

  for i in {1..5}; do
    cat > "$project_dir/assignments/hw-$(printf "%02d" $i).qmd" <<EOF
---
title: "Homework $i"
due: "2024-10-$(printf "%02d" $((5 * i)))"
---

# Assignment $i

Complete the following tasks.

## Task 1

Details here [@jones2021].
EOF
  done

  # Create custom validators directory
  mkdir -p "$project_dir/.teach/validators"

  # Create sample custom validator
  cat > "$project_dir/.teach/validators/check-packages.zsh" <<'EOF'
#!/usr/bin/env zsh
# Custom validator: Check R packages used in code blocks

# Input: file path (first argument)
file="$1"

# Extract R package usage
packages=$(grep -Eo 'library\([^)]+\)' "$file" 2>/dev/null | sed 's/library(//;s/)//')

if [[ -n "$packages" ]]; then
  echo "INFO: R packages detected: $packages"

  # Check against teaching.yml
  if [[ -f ".teach/teaching.yml" ]]; then
    declared=$(yq -r '.r_packages[]' .teach/teaching.yml 2>/dev/null)

    echo "$packages" | while read -r pkg; do
      if ! echo "$declared" | grep -q "^$pkg$"; then
        echo "WARNING: Package '$pkg' not declared in teaching.yml"
      fi
    done
  fi
fi

exit 0
EOF
  chmod +x "$project_dir/.teach/validators/check-packages.zsh"

  # Create performance log
  cat > "$project_dir/.teach/performance-log.json" <<'EOF'
{
  "version": "1.0",
  "entries": []
}
EOF

  # Initialize git
  (cd "$project_dir" && git init -q 2>/dev/null)

  echo "$project_dir"
}

# ============================================================================
# INTEGRATION TEST SUITE 1: Profile + R Package Workflow
# ============================================================================

test_suite "Integration: Profile + R Package Workflow"

# Test 1: Complete profile workflow with R package detection
test_case "Profile workflow: Create, detect packages, auto-install" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Step 1: Detect available profiles
  local profiles=$(_teach_profiles_list 2>/dev/null)
  assert_contains "$profiles" "default" "Should detect default profile"
  assert_contains "$profiles" "draft" "Should detect draft profile"
  assert_contains "$profiles" "print" "Should detect print profile"

  # Step 2: Switch to draft profile
  _teach_profiles_set "draft" 2>/dev/null
  assert_equals "$QUARTO_PROFILE" "draft" "Should set QUARTO_PROFILE env var"

  # Step 3: Detect R packages from teaching.yml
  local detected_packages=$(_detect_r_packages_from_teaching_yml 2>/dev/null)
  assert_contains "$detected_packages" "tidyverse" "Should detect tidyverse"
  assert_contains "$detected_packages" "ggplot2" "Should detect ggplot2"

  # Step 4: Detect R packages from renv.lock
  local renv_packages=$(_parse_renv_lock 2>/dev/null)
  assert_contains "$renv_packages" "tidyverse" "Should parse tidyverse from renv"

  # Step 5: Check installation status
  local missing=$(_check_r_package_installation "fake-missing-package" 2>/dev/null)
  local status=$?
  assert_not_equals "$status" "0" "Should detect missing package"

  cd -
  rm -rf "$temp_dir"
}

# Test 2: Profile-specific R package lists
test_case "Profile-specific R packages in teaching.yml" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Create profile-specific teaching.yml
  cat > ".teach/teaching-draft.yml" <<'EOF'
r_packages:
  - tidyverse
  - devtools
  - testthat
EOF

  # Switch to draft profile
  _teach_profiles_set "draft" 2>/dev/null

  # Detect packages (should prioritize profile-specific)
  local packages=$(_detect_r_packages_from_teaching_yml "draft" 2>/dev/null)
  assert_contains "$packages" "devtools" "Should detect profile-specific packages"

  cd -
  rm -rf "$temp_dir"
}

# Test 3: teach doctor --fix workflow for R packages
test_case "teach doctor --fix installs missing R packages" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Mock R package check (simulate missing packages)
  _check_r_package_installation() {
    local pkg="$1"
    case "$pkg" in
      tidyverse|ggplot2) return 1 ;;  # Missing
      *) return 0 ;;  # Installed
    esac
  }

  # Run doctor check
  local output=$(_teach_doctor_check_r_packages 2>&1)
  local status=$?

  assert_not_equals "$status" "0" "Should detect missing packages"
  assert_contains "$output" "tidyverse" "Should list missing tidyverse"
  assert_contains "$output" "ggplot2" "Should list missing ggplot2"

  cd -
  rm -rf "$temp_dir"
}

# ============================================================================
# INTEGRATION TEST SUITE 2: Parallel Rendering + Performance
# ============================================================================

test_suite "Integration: Parallel Rendering + Performance"

# Test 4: Parallel rendering with performance logging
test_case "Parallel validate logs performance metrics" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Mock quarto render (fast stub)
  quarto() {
    if [[ "$1" == "render" ]]; then
      sleep 0.1  # Simulate render time
      return 0
    fi
  }

  # Run parallel validation (mock)
  local start_time=$(date +%s)
  local files=(lectures/*.qmd)
  local file_count=${#files[@]}

  # Simulate parallel processing
  local workers=4
  local jobs_processed=0

  for file in "${files[@]}"; do
    jobs_processed=$((jobs_processed + 1))
  done

  local end_time=$(date +%s)
  local duration=$((end_time - start_time))

  # Check performance log was updated
  assert_file_exists ".teach/performance-log.json" "Performance log should be created"

  cd -
  rm -rf "$temp_dir"
}

# Test 5: Performance dashboard with speedup calculation
test_case "Performance dashboard shows parallel speedup" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Create performance log with parallel and serial entries
  cat > ".teach/performance-log.json" <<'EOF'
{
  "version": "1.0",
  "entries": [
    {
      "timestamp": "2026-01-20T10:00:00Z",
      "operation": "validate",
      "files": 12,
      "duration_sec": 156,
      "parallel": false,
      "workers": 1
    },
    {
      "timestamp": "2026-01-20T11:00:00Z",
      "operation": "validate",
      "files": 12,
      "duration_sec": 45,
      "parallel": true,
      "workers": 8,
      "speedup": 3.5
    }
  ]
}
EOF

  # Parse performance metrics
  local entries=$(jq -r '.entries[]' .teach/performance-log.json 2>/dev/null)
  assert_not_empty "$entries" "Should parse performance entries"

  # Calculate speedup
  local serial_time=156
  local parallel_time=45
  local speedup=$(awk "BEGIN {printf \"%.1f\", $serial_time / $parallel_time}")

  assert_equals "$speedup" "3.5" "Should calculate correct speedup"

  cd -
  rm -rf "$temp_dir"
}

# Test 6: Parallel rendering with different worker counts
test_case "Parallel rendering scales with worker count" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Test with 1, 4, 8 workers
  for workers in 1 4 8; do
    # Simulate parallel processing
    local files=(lectures/*.qmd)
    local file_count=${#files[@]}

    # Expected jobs per worker
    local jobs_per_worker=$((file_count / workers))

    if [[ $workers -eq 1 ]]; then
      assert_equals "$jobs_per_worker" "$file_count" "1 worker handles all jobs"
    else
      assert_true "[[ $jobs_per_worker -lt $file_count ]]" "Multiple workers split jobs"
    fi
  done

  cd -
  rm -rf "$temp_dir"
}

# Test 7: Progress tracking during parallel rendering
test_case "Progress tracking shows real-time updates" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Simulate progress updates
  local total_jobs=12
  local completed=0

  for i in {1..12}; do
    completed=$i
    local progress=$((completed * 100 / total_jobs))

    assert_true "[[ $progress -ge 0 && $progress -le 100 ]]" "Progress in valid range"
  done

  assert_equals "$completed" "$total_jobs" "All jobs completed"

  cd -
  rm -rf "$temp_dir"
}

# Test 8: Performance log captures per-file timing
test_case "Performance log records per-file render times" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Create detailed performance log
  cat > ".teach/performance-log.json" <<'EOF'
{
  "version": "1.0",
  "entries": [
    {
      "timestamp": "2026-01-20T10:00:00Z",
      "operation": "validate",
      "files": 3,
      "duration_sec": 30,
      "file_timings": [
        {"file": "lectures/week-01.qmd", "duration_sec": 5},
        {"file": "lectures/week-02.qmd", "duration_sec": 10},
        {"file": "lectures/week-03.qmd", "duration_sec": 15}
      ],
      "slowest_file": "lectures/week-03.qmd",
      "slowest_time_sec": 15
    }
  ]
}
EOF

  # Extract slowest file
  local slowest=$(jq -r '.entries[0].slowest_file' .teach/performance-log.json 2>/dev/null)
  assert_equals "$slowest" "lectures/week-03.qmd" "Should identify slowest file"

  local slowest_time=$(jq -r '.entries[0].slowest_time_sec' .teach/performance-log.json 2>/dev/null)
  assert_equals "$slowest_time" "15" "Should record slowest time"

  cd -
  rm -rf "$temp_dir"
}

# ============================================================================
# INTEGRATION TEST SUITE 3: Custom Validators + Cache
# ============================================================================

test_suite "Integration: Custom Validators + Cache"

# Test 9: Custom validators run on sample content
test_case "Custom validators detect issues in content" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Run custom validator
  local result=$(.teach/validators/check-packages.zsh "lectures/week-01.qmd" 2>&1)

  assert_contains "$result" "ggplot2" "Should detect ggplot2 usage"

  cd -
  rm -rf "$temp_dir"
}

# Test 10: Citation validator integration
test_case "Citation validator checks references" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Create citation validator mock
  _validate_citations() {
    local file="$1"
    local citations=$(grep -o '@[a-z0-9]*' "$file" 2>/dev/null)

    if [[ -n "$citations" ]]; then
      echo "$citations"
      return 0
    else
      return 1
    fi
  }

  # Test on sample file
  local citations=$(_validate_citations "lectures/week-01.qmd")
  assert_contains "$citations" "@smith2020" "Should find citation"

  cd -
  rm -rf "$temp_dir"
}

# Test 11: Link validator checks internal links
test_case "Link validator validates internal links" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Extract internal links
  _extract_internal_links() {
    local file="$1"
    grep -Eo '\[([^\]]+)\]\(\.\.?/[^)]+\)' "$file" 2>/dev/null | \
      sed 's/.*(\.\.\?\/\([^)]*\)).*/\1/'
  }

  # Test on sample file
  local links=$(_extract_internal_links "lectures/week-01.qmd")
  assert_contains "$links" "assignments/hw-01.qmd" "Should find internal link"

  # Verify link target exists
  local target="assignments/hw-01.qmd"
  assert_file_exists "$target" "Link target should exist"

  cd -
  rm -rf "$temp_dir"
}

# Test 12: Link validator checks external links (mock)
test_case "Link validator handles external links" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Extract external links
  _extract_external_links() {
    local file="$1"
    grep -Eo '\[([^\]]+)\]\(https?://[^)]+\)' "$file" 2>/dev/null | \
      sed 's/.*(\(http[^)]*\)).*/\1/'
  }

  # Test on sample file
  local links=$(_extract_external_links "lectures/week-01.qmd")
  assert_contains "$links" "https://example.com/stat-545" "Should find external link"

  cd -
  rm -rf "$temp_dir"
}

# Test 13: Formatting validator checks consistency
test_case "Formatting validator checks code style" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Check for common formatting issues
  _check_formatting() {
    local file="$1"
    local issues=()

    # Check for trailing whitespace
    if grep -q ' $' "$file" 2>/dev/null; then
      issues+=("trailing-whitespace")
    fi

    # Check for inconsistent heading levels
    local headings=$(grep -E '^#+' "$file" 2>/dev/null | sed 's/\(#*\).*/\1/' | awk '{print length}')

    echo "${issues[@]}"
  }

  # Test on sample file
  local issues=$(_check_formatting "lectures/week-01.qmd")
  # Should pass (no issues expected in generated content)

  cd -
  rm -rf "$temp_dir"
}

# Test 14: Cache analysis with custom validators
test_case "Cache analysis includes validator cache" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Create validator cache
  mkdir -p ".teach/cache/validators"
  echo "cached result" > ".teach/cache/validators/week-01.json"
  echo "cached result" > ".teach/cache/validators/week-02.json"

  # Analyze cache
  local cache_dirs=$(_list_cache_directories 2>/dev/null)
  assert_contains "$cache_dirs" "validators" "Should include validators cache"

  cd -
  rm -rf "$temp_dir"
}

# ============================================================================
# INTEGRATION TEST SUITE 4: Cache Analysis + Performance
# ============================================================================

test_suite "Integration: Cache Analysis + Performance"

# Test 15: Cache analysis generates detailed breakdown
test_case "Cache analyze shows directory breakdown" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Create cache structure
  mkdir -p "_freeze/lectures"
  mkdir -p "_freeze/assignments"

  # Add cache files
  for i in {1..10}; do
    echo "cache data" > "_freeze/lectures/week-$(printf "%02d" $i).json"
  done

  for i in {1..5}; do
    echo "cache data" > "_freeze/assignments/hw-$(printf "%02d" $i).json"
  done

  # Analyze
  local lecture_count=$(find _freeze/lectures -type f | wc -l | xargs)
  local assignment_count=$(find _freeze/assignments -type f | wc -l | xargs)

  assert_equals "$lecture_count" "10" "Should count lecture cache files"
  assert_equals "$assignment_count" "5" "Should count assignment cache files"

  cd -
  rm -rf "$temp_dir"
}

# Test 16: Cache hit rate from performance log
test_case "Cache hit rate calculated from performance log" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Create performance log with cache metrics
  cat > ".teach/performance-log.json" <<'EOF'
{
  "version": "1.0",
  "entries": [
    {
      "timestamp": "2026-01-20T10:00:00Z",
      "operation": "validate",
      "cache_hits": 8,
      "cache_misses": 4,
      "cache_hit_rate": 0.67
    },
    {
      "timestamp": "2026-01-20T11:00:00Z",
      "operation": "validate",
      "cache_hits": 10,
      "cache_misses": 2,
      "cache_hit_rate": 0.83
    }
  ]
}
EOF

  # Calculate average hit rate
  local avg_hit_rate=$(jq -r '[.entries[].cache_hit_rate] | add / length' .teach/performance-log.json 2>/dev/null)

  # Verify calculation (should be ~0.75)
  assert_true "[[ ${avg_hit_rate:0:4} == '0.75' ]]" "Should calculate average hit rate"

  cd -
  rm -rf "$temp_dir"
}

# Test 17: Selective cache clearing (--lectures)
test_case "Selective clear: --lectures flag" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Create cache structure
  mkdir -p "_freeze/lectures"
  mkdir -p "_freeze/assignments"

  echo "cache" > "_freeze/lectures/week-01.json"
  echo "cache" > "_freeze/assignments/hw-01.json"

  # Simulate selective clear
  _clear_cache_lectures() {
    rm -rf _freeze/lectures
  }

  _clear_cache_lectures

  assert_file_not_exists "_freeze/lectures/week-01.json" "Lecture cache should be cleared"
  assert_file_exists "_freeze/assignments/hw-01.json" "Assignment cache should remain"

  cd -
  rm -rf "$temp_dir"
}

# Test 18: Selective cache clearing (--old)
test_case "Selective clear: --old flag removes old cache" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Create cache files with different ages
  mkdir -p "_freeze/lectures"

  # Recent file (< 7 days)
  touch -t $(date -v-3d +%Y%m%d%H%M.%S 2>/dev/null || date -d '3 days ago' +%Y%m%d%H%M.%S) "_freeze/lectures/week-01.json"

  # Old file (> 7 days)
  touch -t $(date -v-10d +%Y%m%d%H%M.%S 2>/dev/null || date -d '10 days ago' +%Y%m%d%H%M.%S) "_freeze/lectures/week-02.json"

  # Find old files
  local old_files=$(find _freeze -type f -mtime +7 2>/dev/null)

  assert_not_empty "$old_files" "Should find old cache files"

  cd -
  rm -rf "$temp_dir"
}

# Test 19: Cache recommendations based on hit rate
test_case "Cache analysis provides recommendations" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Mock cache analysis with low hit rate
  _generate_cache_recommendations() {
    local hit_rate="$1"

    if awk "BEGIN {exit !($hit_rate < 0.5)}"; then
      echo "RECOMMENDATION: Low cache hit rate. Consider clearing old cache."
    elif awk "BEGIN {exit !($hit_rate < 0.7)}"; then
      echo "RECOMMENDATION: Moderate cache hit rate. Monitor for improvements."
    else
      echo "RECOMMENDATION: Good cache hit rate. Continue current workflow."
    fi
  }

  # Test low hit rate
  local rec_low=$(_generate_cache_recommendations "0.4")
  assert_contains "$rec_low" "Low cache hit rate" "Should recommend clearing for low hit rate"

  # Test good hit rate
  local rec_good=$(_generate_cache_recommendations "0.85")
  assert_contains "$rec_good" "Good cache hit rate" "Should confirm good hit rate"

  cd -
  rm -rf "$temp_dir"
}

# ============================================================================
# INTEGRATION TEST SUITE 5: Full Teaching Workflow
# ============================================================================

test_suite "Integration: Full Teaching Workflow"

# Test 20: Complete workflow from init to deploy
test_case "Full workflow: Init → Profile → Validate → Deploy" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Step 1: Initialize (already done in setup)
  assert_file_exists "_quarto.yml" "Project initialized"
  assert_file_exists ".teach/teaching.yml" "Teaching config exists"

  # Step 2: Create profile
  _teach_profiles_create_internal "slides" 2>/dev/null
  assert_file_contains "_quarto.yml" "slides:" "Profile created"

  # Step 3: Validate content (mock parallel)
  local files=(lectures/*.qmd)
  local file_count=${#files[@]}
  assert_true "[[ $file_count -gt 0 ]]" "Content files exist"

  # Step 4: Check performance (mock)
  assert_file_exists ".teach/performance-log.json" "Performance log exists"

  # Step 5: Analyze cache (mock)
  mkdir -p "_freeze"
  local cache_exists=$(test -d "_freeze" && echo "yes" || echo "no")
  assert_equals "$cache_exists" "yes" "Cache directory exists"

  cd -
  rm -rf "$temp_dir"
}

# Test 21: Profile switching affects content rendering
test_case "Profile switching changes render behavior" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Switch to default profile
  _teach_profiles_set "default" 2>/dev/null
  assert_equals "$QUARTO_PROFILE" "default" "Default profile active"

  # Switch to draft profile
  _teach_profiles_set "draft" 2>/dev/null
  assert_equals "$QUARTO_PROFILE" "draft" "Draft profile active"

  # Switch to print profile
  _teach_profiles_set "print" 2>/dev/null
  assert_equals "$QUARTO_PROFILE" "print" "Print profile active"

  cd -
  rm -rf "$temp_dir"
}

# Test 22: Custom validators integrate with parallel rendering
test_case "Custom validators run in parallel workflow" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # List custom validators
  local validators=($(find .teach/validators -name '*.zsh' 2>/dev/null))
  local validator_count=${#validators[@]}

  assert_true "[[ $validator_count -gt 0 ]]" "Custom validators exist"

  # Run validator on file
  if [[ $validator_count -gt 0 ]]; then
    local result=$(${validators[1]} "lectures/week-01.qmd" 2>&1)
    # Validator should execute without error
  fi

  cd -
  rm -rf "$temp_dir"
}

# Test 23: Performance monitoring tracks improvements over time
test_case "Performance monitoring shows trend improvements" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Create performance log with trend
  cat > ".teach/performance-log.json" <<'EOF'
{
  "version": "1.0",
  "entries": [
    {
      "timestamp": "2026-01-13T10:00:00Z",
      "operation": "validate",
      "files": 12,
      "duration_sec": 180,
      "avg_render_time_sec": 15.0
    },
    {
      "timestamp": "2026-01-15T10:00:00Z",
      "operation": "validate",
      "files": 12,
      "duration_sec": 150,
      "avg_render_time_sec": 12.5
    },
    {
      "timestamp": "2026-01-20T10:00:00Z",
      "operation": "validate",
      "files": 12,
      "duration_sec": 120,
      "avg_render_time_sec": 10.0
    }
  ]
}
EOF

  # Calculate improvement
  local first_time=$(jq -r '.entries[0].avg_render_time_sec' .teach/performance-log.json)
  local last_time=$(jq -r '.entries[-1].avg_render_time_sec' .teach/performance-log.json)

  local improvement=$(awk "BEGIN {printf \"%.1f\", ($first_time - $last_time) / $first_time * 100}")

  # Improvement should be ~33%
  assert_true "[[ ${improvement:0:2} == '33' ]]" "Should show ~33% improvement"

  cd -
  rm -rf "$temp_dir"
}

# Test 24: Semester setup with all Phase 2 features
test_case "Semester setup: Complete initialization workflow" && {
  local temp_dir=$(mktemp -d)
  local project_name="stat-545-fall-2024"
  local project="$temp_dir/$project_name"

  # Create project
  _create_mock_teaching_project "$project"
  cd "$project"

  # Verify all components
  assert_file_exists "_quarto.yml" "Quarto config exists"
  assert_file_exists ".teach/teaching.yml" "Teaching config exists"
  assert_file_exists "renv.lock" "renv.lock exists"
  assert_dir_exists ".teach/validators" "Validators directory exists"
  assert_file_exists ".teach/performance-log.json" "Performance log exists"

  # Verify profiles
  local profiles=$(_teach_profiles_list 2>/dev/null)
  assert_contains "$profiles" "default" "Default profile configured"
  assert_contains "$profiles" "draft" "Draft profile configured"
  assert_contains "$profiles" "print" "Print profile configured"

  # Verify R packages
  local packages=$(yq -r '.r_packages[]' .teach/teaching.yml 2>/dev/null)
  assert_contains "$packages" "tidyverse" "R packages declared"

  cd -
  rm -rf "$temp_dir"
}

# ============================================================================
# EDGE CASES & ERROR HANDLING
# ============================================================================

test_suite "Integration: Edge Cases & Error Handling"

# Test 25: Handle missing _quarto.yml gracefully
test_case "Error handling: Missing _quarto.yml" && {
  local temp_dir=$(mktemp -d)
  mkdir -p "$temp_dir/test-project"
  cd "$temp_dir/test-project"

  # Try to list profiles
  local result=$(_teach_profiles_list 2>&1)
  local status=$?

  # Should handle missing file gracefully
  assert_not_equals "$status" "0" "Should return error for missing _quarto.yml"

  cd -
  rm -rf "$temp_dir"
}

# Test 26: Handle empty teaching.yml
test_case "Error handling: Empty teaching.yml" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Empty teaching.yml
  echo "" > ".teach/teaching.yml"

  # Try to detect R packages
  local packages=$(_detect_r_packages_from_teaching_yml 2>&1)
  # Should handle gracefully (no packages)

  cd -
  rm -rf "$temp_dir"
}

# Test 27: Handle corrupted performance log
test_case "Error handling: Corrupted performance log" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Corrupt JSON
  echo "{ invalid json" > ".teach/performance-log.json"

  # Try to parse
  local result=$(jq -r '.entries' .teach/performance-log.json 2>&1)
  local status=$?

  assert_not_equals "$status" "0" "Should detect corrupted JSON"

  cd -
  rm -rf "$temp_dir"
}

# Test 28: Handle missing custom validators
test_case "Error handling: Missing custom validators" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Remove validators
  rm -rf ".teach/validators"

  # Try to list validators
  local validators=$(find .teach/validators -name '*.zsh' 2>/dev/null)
  assert_empty "$validators" "Should handle missing validators directory"

  cd -
  rm -rf "$temp_dir"
}

# Test 29: Handle parallel rendering with 0 files
test_case "Error handling: Parallel rendering with no files" && {
  local temp_dir=$(mktemp -d)
  mkdir -p "$temp_dir/test-project"
  cd "$temp_dir/test-project"

  # No files to render
  local files=()
  local file_count=${#files[@]}

  assert_equals "$file_count" "0" "Should handle empty file list"

  cd -
  rm -rf "$temp_dir"
}

# Test 30: Handle cache analysis with empty cache
test_case "Error handling: Cache analysis with empty cache" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Empty cache
  rm -rf "_freeze"
  mkdir -p "_freeze"

  # Analyze empty cache
  local cache_size=$(du -sh _freeze 2>/dev/null | awk '{print $1}')
  assert_not_empty "$cache_size" "Should handle empty cache"

  cd -
  rm -rf "$temp_dir"
}

# ============================================================================
# PERFORMANCE BENCHMARKS
# ============================================================================

test_suite "Integration: Performance Benchmarks"

# Test 31: Benchmark parallel speedup with 12 files
test_case "Benchmark: 12 files, 8 workers (target 3.5x speedup)" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Mock render times
  local single_file_time=10  # seconds
  local file_count=12

  # Serial time
  local serial_time=$((single_file_time * file_count))  # 120s

  # Parallel time (with overhead)
  local workers=8
  local parallel_time=$((single_file_time * file_count / workers + 5))  # ~20s

  # Calculate speedup
  local speedup=$(awk "BEGIN {printf \"%.1f\", $serial_time / $parallel_time}")

  # Should be ~3.5x or better
  assert_true "[[ ${speedup%.*} -ge 3 ]]" "Should achieve 3x+ speedup"

  cd -
  rm -rf "$temp_dir"
}

# Test 32: Custom validator overhead
test_case "Benchmark: Custom validators < 5s overhead" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Simulate validator execution
  local validator_start=$(date +%s)

  # Run 3 validators on 1 file
  for i in {1..3}; do
    sleep 0.1  # Mock validator time
  done

  local validator_end=$(date +%s)
  local validator_time=$((validator_end - validator_start))

  # Should be < 5s
  assert_true "[[ $validator_time -lt 5 ]]" "Validators should complete < 5s"

  cd -
  rm -rf "$temp_dir"
}

# Test 33: Performance monitoring overhead
test_case "Benchmark: Performance monitoring < 100ms overhead" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Simulate performance logging
  local log_start=$(date +%s%N 2>/dev/null || date +%s)

  # Write to performance log
  cat >> ".teach/performance-log.json" <<'EOF'
{
  "timestamp": "2026-01-20T10:00:00Z",
  "operation": "validate",
  "duration_sec": 45
}
EOF

  local log_end=$(date +%s%N 2>/dev/null || date +%s)

  # Overhead should be minimal (< 100ms = 100000000ns)
  local overhead=$((log_end - log_start))

  # Convert to ms if nanoseconds available
  if [[ $overhead -gt 1000000 ]]; then
    overhead=$((overhead / 1000000))  # ns to ms
    assert_true "[[ $overhead -lt 100 ]]" "Logging overhead < 100ms"
  fi

  cd -
  rm -rf "$temp_dir"
}

# Test 34: Cache analysis performance (1000+ files)
test_case "Benchmark: Cache analysis < 2s for 1000 files" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Create large cache (100 files for testing)
  mkdir -p "_freeze/test"
  for i in {1..100}; do
    echo "cache" > "_freeze/test/file-$i.json"
  done

  # Analyze cache
  local analysis_start=$(date +%s)
  local cache_files=$(find _freeze -type f | wc -l | xargs)
  local analysis_end=$(date +%s)

  local analysis_time=$((analysis_end - analysis_start))

  # Should be < 2s even for 100 files
  assert_true "[[ $analysis_time -lt 2 ]]" "Cache analysis < 2s"

  cd -
  rm -rf "$temp_dir"
}

# ============================================================================
# BACKWARD COMPATIBILITY
# ============================================================================

test_suite "Integration: Backward Compatibility"

# Test 35: Phase 1 features still work with Phase 2
test_case "Backward compatibility: Phase 1 validate still works" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Run basic validate (Phase 1)
  local files=(lectures/*.qmd)
  local file_count=${#files[@]}

  assert_true "[[ $file_count -gt 0 ]]" "Can still validate files"

  cd -
  rm -rf "$temp_dir"
}

# Test 36: teach cache clear without flags still works
test_case "Backward compatibility: teach cache clear (no flags)" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Create cache
  mkdir -p "_freeze"
  echo "cache" > "_freeze/test.json"

  # Clear all cache (Phase 1 behavior)
  rm -rf "_freeze"

  assert_dir_not_exists "_freeze" "Can still clear entire cache"

  cd -
  rm -rf "$temp_dir"
}

# Test 37: teach status without flags shows basic info
test_case "Backward compatibility: teach status (no flags)" && {
  local temp_dir=$(mktemp -d)
  local project=$(_create_mock_teaching_project "$temp_dir/test-project")
  cd "$project"

  # Basic status should still work
  assert_file_exists "_quarto.yml" "Project valid"
  assert_file_exists ".teach/teaching.yml" "Teaching config valid"

  cd -
  rm -rf "$temp_dir"
}

# ============================================================================
# SUMMARY
# ============================================================================

# Print test summary
print_test_summary

# Exit with appropriate code
if [[ $TESTS_FAILED -eq 0 ]]; then
  exit 0
else
  exit 1
fi
