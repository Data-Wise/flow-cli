#!/usr/bin/env zsh
# e2e-doctor-install.zsh - End-to-end tests for `doctor`'s INSTALLATION section
#
# Targets the exact failure class fixed in homebrew-tap PR #135: a Homebrew
# formula install that "succeeds" (brew reports installed, brew upgrade says
# "already installed") but never actually links — man-page name collisions
# on case-insensitive filesystems, stale Cellar kegs after a formula fix,
# and shell/Cellar version drift after an upgrade. All of these leave the
# user silently running broken or stale code with no error message.
#
# Drives the real `_doctor_check_installation` function against a mocked
# `brew` covering: no Homebrew, not brew-installed, healthy link, broken
# link (installed-but-unlinked), version drift, and man-page collisions
# across two formulae's Cellar kegs.
#
# Usage: zsh tests/e2e-doctor-install.zsh

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local test_name="$1"
    local test_func="$2"

    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "  ${CYAN}[$TESTS_RUN] $test_name...${RESET} "

    local output
    output=$(eval "$test_func" 2>&1)
    local rc=$?

    if [[ $rc -eq 0 ]]; then
        echo "${GREEN}PASS${RESET}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "${RED}FAIL${RESET}"
        [[ -n "$output" ]] && echo "    ${DIM}${output:0:300}${RESET}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

echo ""
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo "${CYAN}  E2E: doctor INSTALLATION checks (Homebrew distribution health)${RESET}"
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo ""

FLOW_QUIET=1
FLOW_ATLAS_ENABLED=no
FLOW_PLUGIN_DIR="$PROJECT_ROOT"
source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
    echo "${RED}Failed to load plugin${RESET}"
    exit 1
}

exec < /dev/null

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT

# Builds a fake Cellar under a given root (each scenario gets its own root
# so man-page fixtures never leak across scenarios): $1=cellar_root
# $2=formula $3=version $4... =man1 basenames to ship
_fake_keg() {
    local cellar_root="$1" formula="$2" version="$3"
    shift 3
    local mandir="$cellar_root/$formula/$version/share/man/man1"
    mkdir -p "$mandir"
    for name in "$@"; do
        touch "$mandir/$name"
    done
}

# ─────────────────────────────────────────────────────────────────
# Scenario 1: brew not present at all — must skip silently, no error
# ─────────────────────────────────────────────────────────────────
test_no_brew() {
    unfunction brew 2>/dev/null
    local orig_path="$PATH"
    PATH="/nonexistent_bin_dir_for_test"
    local out
    out=$(_doctor_check_installation 2>&1)
    PATH="$orig_path"
    assert_output_contains "$out" "not present"
}

# ─────────────────────────────────────────────────────────────────
# Scenario 2: brew present, flow-cli not installed via it — skip
# ─────────────────────────────────────────────────────────────────
test_not_brew_installed() {
    brew() {
        case "$1 $2" in
            "list --formula") echo "some-other-formula" ;;
        esac
    }
    local out
    out=$(_doctor_check_installation 2>&1)
    unfunction brew
    assert_output_contains "$out" "not installed via Homebrew"
}

# ─────────────────────────────────────────────────────────────────
# Scenario 3: healthy install — linked, version matches, no collisions
# ─────────────────────────────────────────────────────────────────
test_healthy_install() {
    local cellar="$TEST_TMP/cellar-healthy"
    local optdir="$TEST_TMP/prefix-healthy/opt/flow-cli"
    mkdir -p "$cellar/flow-cli/${FLOW_VERSION}"
    mkdir -p "$TEST_TMP/prefix-healthy/opt"
    ln -sfn "$cellar/flow-cli/${FLOW_VERSION}" "$optdir"

    brew() {
        if [[ "$1 $2" == "list --formula" ]]; then echo "flow-cli"
        elif [[ "$1 $2" == "list --versions" && "$3" == "flow-cli" ]]; then echo "flow-cli ${FLOW_VERSION}"
        elif [[ "$1" == "--prefix" ]]; then echo "$TEST_TMP/prefix-healthy"
        elif [[ "$1" == "--cellar" ]]; then echo "$cellar"
        fi
    }

    local out
    out=$(_doctor_check_installation 2>&1)
    unfunction brew

    assert_output_contains "$out" "Homebrew link" &&
    assert_output_not_contains "$out" "not linked" &&
    assert_output_not_contains "$out" "drift" &&
    assert_output_not_contains "$out" "Shell has"
}

# ─────────────────────────────────────────────────────────────────
# Scenario 4: installed but NOT linked (the PR #135 symptom before the fix)
# ─────────────────────────────────────────────────────────────────
test_installed_not_linked() {
    local cellar="$TEST_TMP/cellar-broken"
    mkdir -p "$cellar/flow-cli/${FLOW_VERSION}"
    mkdir -p "$TEST_TMP/prefix-broken/opt"
    # deliberately do NOT create the opt symlink

    brew() {
        if [[ "$1 $2" == "list --formula" ]]; then echo "flow-cli"
        elif [[ "$1 $2" == "list --versions" && "$3" == "flow-cli" ]]; then echo "flow-cli ${FLOW_VERSION}"
        elif [[ "$1" == "--prefix" ]]; then echo "$TEST_TMP/prefix-broken"
        elif [[ "$1" == "--cellar" ]]; then echo "$cellar"
        fi
    }

    local out
    out=$(_doctor_check_installation 2>&1)
    unfunction brew

    assert_output_contains "$out" "not linked"
}

# ─────────────────────────────────────────────────────────────────
# Scenario 5: version drift — shell's loaded version != installed keg
# ─────────────────────────────────────────────────────────────────
test_version_drift() {
    local cellar="$TEST_TMP/cellar-drift"
    local optdir="$TEST_TMP/prefix-drift/opt/flow-cli"
    mkdir -p "$cellar/flow-cli/99.99.99"
    mkdir -p "$TEST_TMP/prefix-drift/opt"
    ln -sfn "$cellar/flow-cli/99.99.99" "$optdir"

    brew() {
        if [[ "$1 $2" == "list --formula" ]]; then echo "flow-cli"
        elif [[ "$1 $2" == "list --versions" && "$3" == "flow-cli" ]]; then echo "flow-cli 99.99.99"
        elif [[ "$1" == "--prefix" ]]; then echo "$TEST_TMP/prefix-drift"
        elif [[ "$1" == "--cellar" ]]; then echo "$cellar"
        fi
    }

    local out
    out=$(_doctor_check_installation 2>&1)
    unfunction brew

    assert_output_contains "$out" "99.99.99" &&
    assert_output_contains "$out" "restart your shell"
}

# ─────────────────────────────────────────────────────────────────
# Scenario 6: flow-cli's own man page lost a collision — its r.1 was never
# linked into the shared man1 dir because the `r` formula's R.1 took the
# case-insensitive slot instead (the exact PR #135 symptom, pre-fix).
# ─────────────────────────────────────────────────────────────────
test_manpage_collision_detected() {
    local cellar="$TEST_TMP/cellar-collide"
    local prefix="$TEST_TMP/prefix-collide"
    local optdir="$prefix/opt/flow-cli"
    mkdir -p "$prefix/opt"
    _fake_keg "$cellar" "flow-cli" "${FLOW_VERSION}" "agenda.1" "r.1"
    _fake_keg "$cellar" "r" "4.5.0" "R.1"
    ln -sfn "$cellar/flow-cli/${FLOW_VERSION}" "$optdir"

    # Simulate the shared man1 dir after a lost collision: agenda.1 links to
    # flow-cli as expected, but the r.1 slot resolved to the `r` formula's
    # keg instead of flow-cli's.
    mkdir -p "$prefix/share/man/man1"
    ln -sfn "$cellar/flow-cli/${FLOW_VERSION}/share/man/man1/agenda.1" "$prefix/share/man/man1/agenda.1"
    ln -sfn "$cellar/r/4.5.0/share/man/man1/R.1" "$prefix/share/man/man1/r.1"

    brew() {
        if [[ "$1 $2" == "list --formula" ]]; then echo "flow-cli"
        elif [[ "$1 $2" == "list --versions" && "$3" == "flow-cli" ]]; then echo "flow-cli ${FLOW_VERSION}"
        elif [[ "$1" == "--prefix" ]]; then echo "$prefix"
        elif [[ "$1" == "--cellar" ]]; then echo "$cellar"
        fi
    }

    local out
    out=$(_doctor_check_installation 2>&1)
    unfunction brew

    assert_output_contains "$out" "not linked (collision" &&
    assert_output_contains "$out" "r.1"
}

# ─────────────────────────────────────────────────────────────────
# Scenario 7: all of flow-cli's own man pages link cleanly — including
# alongside an unrelated formula (jq) that ships its own, non-colliding page.
# ─────────────────────────────────────────────────────────────────
test_no_manpage_collision() {
    local cellar="$TEST_TMP/cellar-clean"
    local prefix="$TEST_TMP/prefix-clean"
    local optdir="$prefix/opt/flow-cli"
    mkdir -p "$prefix/opt"
    _fake_keg "$cellar" "flow-cli" "${FLOW_VERSION}" "agenda.1" "dash.1"
    _fake_keg "$cellar" "jq" "1.7" "jq.1"
    ln -sfn "$cellar/flow-cli/${FLOW_VERSION}" "$optdir"

    mkdir -p "$prefix/share/man/man1"
    ln -sfn "$cellar/flow-cli/${FLOW_VERSION}/share/man/man1/agenda.1" "$prefix/share/man/man1/agenda.1"
    ln -sfn "$cellar/flow-cli/${FLOW_VERSION}/share/man/man1/dash.1" "$prefix/share/man/man1/dash.1"
    ln -sfn "$cellar/jq/1.7/share/man/man1/jq.1" "$prefix/share/man/man1/jq.1"

    brew() {
        if [[ "$1 $2" == "list --formula" ]]; then echo "flow-cli"
        elif [[ "$1 $2" == "list --versions" && "$3" == "flow-cli" ]]; then echo "flow-cli ${FLOW_VERSION}"
        elif [[ "$1" == "--prefix" ]]; then echo "$prefix"
        elif [[ "$1" == "--cellar" ]]; then echo "$cellar"
        fi
    }

    local out
    out=$(_doctor_check_installation 2>&1)
    unfunction brew

    assert_output_contains "$out" "All flow-cli man pages linked cleanly"
}

# ─────────────────────────────────────────────────────────────────
# Assertion helpers (self-contained, mirrors test-framework.zsh's contract)
# ─────────────────────────────────────────────────────────────────
assert_output_contains() {
    local haystack="$1" needle="$2"
    [[ "$haystack" == *"$needle"* ]] || { echo "expected to contain: $needle"; return 1; }
}

assert_output_not_contains() {
    local haystack="$1" needle="$2"
    [[ "$haystack" != *"$needle"* ]] || { echo "expected NOT to contain: $needle"; return 1; }
}

run_test "no brew on PATH → skip" test_no_brew
run_test "brew present, flow-cli not installed via it → skip" test_not_brew_installed
run_test "healthy install → linked, version matches, no collisions" test_healthy_install
run_test "installed but not linked → flagged" test_installed_not_linked
run_test "version drift (shell vs Cellar) → flagged" test_version_drift
run_test "man-page collision across formulae → detected" test_manpage_collision_detected
run_test "no man-page collision → clean" test_no_manpage_collision

echo ""
echo "${CYAN}──────────────────────────────────────────────────────────────${RESET}"
echo "  Results: ${GREEN}${TESTS_PASSED} passed${RESET}, ${RED}${TESTS_FAILED} failed${RESET} (${TESTS_RUN} total)"
echo "${CYAN}──────────────────────────────────────────────────────────────${RESET}"
echo ""

[[ $TESTS_FAILED -eq 0 ]]
