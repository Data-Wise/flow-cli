#!/usr/bin/env zsh
# tests/test-r-helpers-unit.zsh - Unit tests for R Package Detection and Installation
# Tests R package detection, installation checking, and auto-install

# Source test framework
TEST_DIR="${0:A:h}"
source "$TEST_DIR/test-framework.zsh"

# Source the modules we're testing
source "$TEST_DIR/../lib/core.zsh"
source "$TEST_DIR/../lib/r-helpers.zsh"
source "$TEST_DIR/../lib/renv-integration.zsh"

# ============================================================================
# TEST FIXTURES
# ============================================================================

setup_test_project_with_r() {
    local test_dir="$1"

    mkdir -p "$test_dir/.flow"

    # Create teaching.yml with R packages
    cat > "$test_dir/.flow/teaching.yml" << 'EOF'
course:
  name: "Test Course"
  code: "TEST-101"

r_packages:
  - ggplot2
  - dplyr
  - tidyr
  - knitr
EOF
}

setup_test_project_with_renv() {
    local test_dir="$1"

    mkdir -p "$test_dir"

    # Create renv.lock
    cat > "$test_dir/renv.lock" << 'EOF'
{
  "R": {
    "Version": "4.3.0",
    "Repositories": [
      {
        "Name": "CRAN",
        "URL": "https://cloud.r-project.org"
      }
    ]
  },
  "Packages": {
    "ggplot2": {
      "Package": "ggplot2",
      "Version": "3.4.2",
      "Source": "Repository",
      "Repository": "CRAN"
    },
    "dplyr": {
      "Package": "dplyr",
      "Version": "1.1.2",
      "Source": "Repository",
      "Repository": "CRAN"
    },
    "rmarkdown": {
      "Package": "rmarkdown",
      "Version": "2.21",
      "Source": "Repository",
      "Repository": "CRAN"
    }
  }
}
EOF
}

setup_test_project_with_description() {
    local test_dir="$1"

    mkdir -p "$test_dir"

    # Create DESCRIPTION file (R package)
    cat > "$test_dir/DESCRIPTION" << 'EOF'
Package: testpkg
Title: Test Package
Version: 1.0.0
Imports:
    ggplot2,
    dplyr,
    tidyr
Depends:
    R (>= 4.0.0),
    knitr
EOF
}

# ============================================================================
# R PACKAGE DETECTION TESTS (teaching.yml)
# ============================================================================

test_detect_r_packages_from_teaching_yml() {
    local test_dir=$(mktemp -d)
    setup_test_project_with_r "$test_dir"

    cd "$test_dir"
    local packages
    packages=$(_detect_r_packages)
    local ret=$?

    assert_equals 0 $ret "Should detect packages successfully"
    assert_contains "$packages" "ggplot2" "Should find ggplot2"
    assert_contains "$packages" "dplyr" "Should find dplyr"
    assert_contains "$packages" "tidyr" "Should find tidyr"
    assert_contains "$packages" "knitr" "Should find knitr"

    cd - > /dev/null
    rm -rf "$test_dir"
}

test_detect_r_packages_no_teaching_yml() {
    local test_dir=$(mktemp -d)

    cd "$test_dir"
    _detect_r_packages > /dev/null 2>&1
    local ret=$?

    assert_equals 1 $ret "Should return 1 when teaching.yml not found"

    cd - > /dev/null
    rm -rf "$test_dir"
}

test_detect_r_packages_no_r_packages_key() {
    local test_dir=$(mktemp -d)
    mkdir -p "$test_dir/.flow"

    cat > "$test_dir/.flow/teaching.yml" << 'EOF'
course:
  name: "Test Course"
EOF

    cd "$test_dir"
    _detect_r_packages > /dev/null 2>&1
    local ret=$?

    assert_equals 2 $ret "Should return 2 when no r_packages defined"

    cd - > /dev/null
    rm -rf "$test_dir"
}

# ============================================================================
# R PACKAGE DETECTION TESTS (DESCRIPTION)
# ============================================================================

test_detect_r_packages_from_description() {
    local test_dir=$(mktemp -d)
    setup_test_project_with_description "$test_dir"

    cd "$test_dir"
    local packages
    packages=$(_detect_r_packages_from_description)
    local ret=$?

    assert_equals 0 $ret "Should detect packages from DESCRIPTION"
    assert_contains "$packages" "ggplot2" "Should find ggplot2"
    assert_contains "$packages" "dplyr" "Should find dplyr"
    assert_contains "$packages" "tidyr" "Should find tidyr"
    assert_contains "$packages" "knitr" "Should find knitr"
    assert_not_contains "$packages" "R " "Should not include R itself"

    cd - > /dev/null
    rm -rf "$test_dir"
}

test_detect_r_packages_from_description_no_file() {
    local test_dir=$(mktemp -d)

    cd "$test_dir"
    _detect_r_packages_from_description > /dev/null 2>&1
    local ret=$?

    assert_equals 1 $ret "Should return 1 when DESCRIPTION not found"

    cd - > /dev/null
    rm -rf "$test_dir"
}

# ============================================================================
# R PACKAGE DETECTION TESTS (All Sources)
# ============================================================================

test_list_r_packages_from_all_sources() {
    local test_dir=$(mktemp -d)
    setup_test_project_with_r "$test_dir"
    setup_test_project_with_renv "$test_dir"

    cd "$test_dir"
    local packages
    packages=$(_list_r_packages_from_sources)

    # Should get unique list from both sources
    assert_contains "$packages" "ggplot2" "Should find ggplot2"
    assert_contains "$packages" "dplyr" "Should find dplyr"
    assert_contains "$packages" "rmarkdown" "Should find rmarkdown from renv"

    # Check uniqueness (should not have duplicates)
    local count
    count=$(echo "$packages" | grep -c "ggplot2")
    assert_equals 1 $count "Should have unique packages only"

    cd - > /dev/null
    rm -rf "$test_dir"
}

test_list_r_packages_from_sources_no_packages() {
    local test_dir=$(mktemp -d)

    cd "$test_dir"
    _list_r_packages_from_sources > /dev/null 2>&1
    local ret=$?

    assert_equals 1 $ret "Should return 1 when no packages found"

    cd - > /dev/null
    rm -rf "$test_dir"
}

# ============================================================================
# RENV LOCKFILE TESTS
# ============================================================================

test_get_renv_packages() {
    local test_dir=$(mktemp -d)
    setup_test_project_with_renv "$test_dir"

    cd "$test_dir"
    local packages
    packages=$(_get_renv_packages)
    local ret=$?

    assert_equals 0 $ret "Should extract packages from renv.lock"
    assert_contains "$packages" "ggplot2" "Should find ggplot2"
    assert_contains "$packages" "dplyr" "Should find dplyr"
    assert_contains "$packages" "rmarkdown" "Should find rmarkdown"

    cd - > /dev/null
    rm -rf "$test_dir"
}

test_get_renv_packages_no_file() {
    local test_dir=$(mktemp -d)

    cd "$test_dir"
    _get_renv_packages > /dev/null 2>&1
    local ret=$?

    assert_equals 1 $ret "Should return 1 when renv.lock not found"

    cd - > /dev/null
    rm -rf "$test_dir"
}

test_get_renv_package_version() {
    local test_dir=$(mktemp -d)
    setup_test_project_with_renv "$test_dir"

    cd "$test_dir"
    local version
    version=$(_get_renv_package_version "ggplot2")

    assert_equals "3.4.2" "$version" "Should get ggplot2 version from renv.lock"

    cd - > /dev/null
    rm -rf "$test_dir"
}

test_get_renv_package_source() {
    local test_dir=$(mktemp -d)
    setup_test_project_with_renv "$test_dir"

    cd "$test_dir"
    local source
    source=$(_get_renv_package_source "ggplot2")

    assert_equals "Repository" "$source" "Should get package source"

    cd - > /dev/null
    rm -rf "$test_dir"
}

# ============================================================================
# R PACKAGE INSTALLATION CHECK TESTS
# ============================================================================

# Note: These tests assume R is installed and certain packages may or may not be installed
# We'll use conditional tests based on R availability

test_check_r_package_installed_needs_r() {
    if ! command -v R &>/dev/null; then
        skip_test "R not available"
        return
    fi

    # Test with a common base package that should be installed
    _check_r_package_installed "base" > /dev/null 2>&1
    local ret=$?

    assert_equals 0 $ret "Should find base package"
}

test_check_r_package_installed_nonexistent() {
    if ! command -v R &>/dev/null; then
        skip_test "R not available"
        return
    fi

    _check_r_package_installed "nonexistentpackage12345" > /dev/null 2>&1
    local ret=$?

    assert_not_equals 0 $ret "Should not find nonexistent package"
}

test_get_r_package_version_needs_r() {
    if ! command -v R &>/dev/null; then
        skip_test "R not available"
        return
    fi

    local version
    version=$(_get_r_package_version "base" 2>/dev/null)

    assert_not_empty "$version" "Should get version for base package"
}

# ============================================================================
# MISSING PACKAGES CHECK TESTS
# ============================================================================

test_check_missing_r_packages() {
    if ! command -v R &>/dev/null; then
        skip_test "R not available"
        return
    fi

    # Create a list with mix of installed and non-installed packages
    local packages="base
stats
nonexistentpackage12345
anotherfakepackage99999"

    local missing
    missing=$(_check_missing_r_packages <<< "$packages")

    # Should find the fake packages as missing
    assert_contains "$missing" "nonexistentpackage12345" "Should detect missing package 1"
    assert_contains "$missing" "anotherfakepackage99999" "Should detect missing package 2"
    assert_not_contains "$missing" "base" "Should not list installed packages"
}

# ============================================================================
# R PACKAGE STATUS TESTS
# ============================================================================

test_show_r_package_status() {
    if ! command -v R &>/dev/null; then
        skip_test "R not available"
        return
    fi

    local test_dir=$(mktemp -d)
    setup_test_project_with_r "$test_dir"

    cd "$test_dir"
    local output
    output=$(_show_r_package_status 2>&1)

    assert_contains "$output" "R Package Status" "Should show status header"

    cd - > /dev/null
    rm -rf "$test_dir"
}

test_show_r_package_status_json() {
    if ! command -v R &>/dev/null; then
        skip_test "R not available"
        return
    fi

    local test_dir=$(mktemp -d)
    setup_test_project_with_r "$test_dir"

    cd "$test_dir"
    local output
    output=$(_show_r_package_status --json)

    assert_contains "$output" '"packages"' "Should have packages array"
    assert_contains "$output" '"installed_count"' "Should have installed count"
    assert_contains "$output" '"missing_count"' "Should have missing count"

    cd - > /dev/null
    rm -rf "$test_dir"
}

# ============================================================================
# RENV STATUS TESTS
# ============================================================================

test_show_renv_status() {
    if ! command -v R &>/dev/null; then
        skip_test "R not available"
        return
    fi

    if ! command -v jq &>/dev/null; then
        skip_test "jq not available"
        return
    fi

    local test_dir=$(mktemp -d)
    setup_test_project_with_renv "$test_dir"

    cd "$test_dir"
    local output
    output=$(_show_renv_status 2>&1)

    assert_contains "$output" "renv Status" "Should show renv status header"

    cd - > /dev/null
    rm -rf "$test_dir"
}

test_show_renv_status_json() {
    if ! command -v R &>/dev/null; then
        skip_test "R not available"
        return
    fi

    if ! command -v jq &>/dev/null; then
        skip_test "jq not available"
        return
    fi

    local test_dir=$(mktemp -d)
    setup_test_project_with_renv "$test_dir"

    cd "$test_dir"
    local output
    output=$(_show_renv_status --json)

    assert_contains "$output" '"synced"' "Should have synced array"
    assert_contains "$output" '"missing"' "Should have missing array"
    assert_contains "$output" '"version_mismatch"' "Should have version_mismatch array"

    cd - > /dev/null
    rm -rf "$test_dir"
}

test_show_renv_status_no_file() {
    local test_dir=$(mktemp -d)

    cd "$test_dir"
    _show_renv_status > /dev/null 2>&1
    local ret=$?

    assert_not_equals 0 $ret "Should fail when renv.lock not found"

    cd - > /dev/null
    rm -rf "$test_dir"
}

# ============================================================================
# EDGE CASES
# ============================================================================

test_detect_r_packages_empty_list() {
    local test_dir=$(mktemp -d)
    mkdir -p "$test_dir/.flow"

    cat > "$test_dir/.flow/teaching.yml" << 'EOF'
course:
  name: "Test Course"

r_packages: []
EOF

    cd "$test_dir"
    _detect_r_packages > /dev/null 2>&1
    local ret=$?

    assert_equals 2 $ret "Should return 2 for empty r_packages list"

    cd - > /dev/null
    rm -rf "$test_dir"
}

test_renv_lock_invalid_json() {
    local test_dir=$(mktemp -d)

    # Create invalid JSON
    echo "{ invalid json }" > "$test_dir/renv.lock"

    cd "$test_dir"
    _get_renv_packages > /dev/null 2>&1
    local ret=$?

    assert_not_equals 0 $ret "Should fail for invalid JSON"

    cd - > /dev/null
    rm -rf "$test_dir"
}

# ============================================================================
# RUN TESTS
# ============================================================================

echo "Running R Package Detection Tests..."
echo ""

# Check if required tools are available
if ! command -v yq &>/dev/null; then
    echo "WARNING: yq not found - some tests will fail"
fi

if ! command -v jq &>/dev/null; then
    echo "WARNING: jq not found - renv tests will be skipped"
fi

if ! command -v R &>/dev/null; then
    echo "WARNING: R not found - installation tests will be skipped"
fi

echo ""

run_test test_detect_r_packages_from_teaching_yml
run_test test_detect_r_packages_no_teaching_yml
run_test test_detect_r_packages_no_r_packages_key

run_test test_detect_r_packages_from_description
run_test test_detect_r_packages_from_description_no_file

run_test test_list_r_packages_from_all_sources
run_test test_list_r_packages_from_sources_no_packages

run_test test_get_renv_packages
run_test test_get_renv_packages_no_file
run_test test_get_renv_package_version
run_test test_get_renv_package_source

run_test test_check_r_package_installed_needs_r
run_test test_check_r_package_installed_nonexistent
run_test test_get_r_package_version_needs_r

run_test test_check_missing_r_packages

run_test test_show_r_package_status
run_test test_show_r_package_status_json

run_test test_show_renv_status
run_test test_show_renv_status_json
run_test test_show_renv_status_no_file

run_test test_detect_r_packages_empty_list
run_test test_renv_lock_invalid_json

print_test_summary
