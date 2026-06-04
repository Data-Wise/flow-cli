#!/usr/bin/env zsh
# e2e-tok-sync.zsh - End-to-end tests for tok auto-sync (config-driven fan-out)
#
# Unlike the unit tests (tests/test-tok-sync.zsh, tests/test-tok.zsh) which
# source lib/tok-sync.zsh and the dispatcher DIRECTLY, this e2e loads the FULL
# plugin via `source flow.plugin.zsh` and drives the feature through the real
# `tok` entry point. This catches integration issues (sourcing order, load
# guards, dispatcher routing under full load) that direct-sourcing can't.
#
# All scenarios are dry-run only (`tok sync repos`) — NO gh required.
#
# Usage: zsh tests/e2e-tok-sync.zsh

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

# Colors
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
    elif [[ $rc -eq 77 ]]; then
        echo "${YELLOW}SKIP${RESET}"
    else
        echo "${RED}FAIL${RESET}"
        [[ -n "$output" ]] && echo "    ${DIM}${output:0:300}${RESET}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# ============================================================================
# SETUP
# ============================================================================

echo ""
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo "${CYAN}  E2E: tok Auto-Sync (full-plugin dry-run path)${RESET}"
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo ""

# Load the FULL plugin (non-interactive) — this is the key difference from the
# unit tests, which source lib/tok-sync.zsh directly.
FLOW_QUIET=1
FLOW_ATLAS_ENABLED=no
FLOW_PLUGIN_DIR="$PROJECT_ROOT"
exec < /dev/null
source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
    echo "${RED}Failed to load plugin${RESET}"
    exit 1
}

ORIGINAL_DIR=$(pwd)

# Canonical fixture conf (APP_ID + APP_PRIVATE_KEY across two repos, plus one
# oidc row). Written with mktemp + chmod 0600 + cleanup trap.
FIXTURE_CONF=$(mktemp)
chmod 0600 "$FIXTURE_CONF"
cat > "$FIXTURE_CONF" <<'EOF'
# <token-name>  <secret-name>     <owner/repo>     [oidc]
github-app       APP_ID            data-wise/flow-cli
github-app       APP_PRIVATE_KEY   data-wise/flow-cli
github-app       APP_ID            data-wise/aiterm
github-app       APP_PRIVATE_KEY   data-wise/aiterm
pypi             PYPI_TOKEN        data-wise/nexus-cli   oidc
EOF

cleanup() {
    cd "$ORIGINAL_DIR"
    rm -f "$FIXTURE_CONF"
}
trap cleanup EXIT

# Point the feature at the fixture for all scenarios.
export FLOW_TOK_SYNC_CONF="$FIXTURE_CONF"

# ============================================================================
# SECTION 1: Integration — full plugin load resolves the feature surface
# ============================================================================

echo "${CYAN}--- Section 1: Full-Plugin Load ---${RESET}"

run_test "tok entry point resolves after full plugin load" '
    typeset -f tok >/dev/null 2>&1 || return 1
'

run_test "_tok_sync_push resolves after full plugin load" '
    typeset -f _tok_sync_push >/dev/null 2>&1 || return 1
'

run_test "_tok_sync_repos resolves after full plugin load" '
    typeset -f _tok_sync_repos >/dev/null 2>&1 || return 1
'

run_test "_tok_sync_load_targets resolves after full plugin load" '
    typeset -f _tok_sync_load_targets >/dev/null 2>&1 || return 1
'

run_test "_tok_autosync_hook resolves after full plugin load" '
    typeset -f _tok_autosync_hook >/dev/null 2>&1 || return 1
'

echo ""

# ============================================================================
# SECTION 2: tok sync repos — dry-run inspect (canonical seed)
# ============================================================================

echo "${CYAN}--- Section 2: Dry-Run Inspect (github-app) ---${RESET}"

run_test "repos lists all repo:secret push targets" '
    local output
    output=$(tok sync repos github-app 2>&1)
    [[ "$output" == *"dry run, no writes"* ]] || { echo "no dry-run header: $output"; return 1; }
    [[ "$output" == *"data-wise/flow-cli : APP_ID"* ]] || { echo "missing flow-cli APP_ID"; return 1; }
    [[ "$output" == *"data-wise/flow-cli : APP_PRIVATE_KEY"* ]] || { echo "missing flow-cli APP_PRIVATE_KEY"; return 1; }
    [[ "$output" == *"data-wise/aiterm : APP_ID"* ]] || { echo "missing aiterm APP_ID"; return 1; }
    [[ "$output" == *"data-wise/aiterm : APP_PRIVATE_KEY"* ]] || { echo "missing aiterm APP_PRIVATE_KEY"; return 1; }
'

run_test "repos summary: would push 4 secrets across 2 repos" '
    local output
    output=$(tok sync repos github-app 2>&1)
    [[ "$output" == *"would push 4 secret(s) across 2 repo(s)"* ]] || { echo "Got: $output"; return 1; }
'

echo ""

# ============================================================================
# SECTION 3: OIDC row → Trusted-Publishing note, never a push target
# ============================================================================

echo "${CYAN}--- Section 3: OIDC / Trusted Publishing ---${RESET}"

run_test "oidc row surfaces Trusted-Publishing note, 0 push targets" '
    local output
    output=$(tok sync repos pypi 2>&1)
    [[ "$output" == *"Trusted Publishing"* ]] || { echo "missing Trusted Publishing note: $output"; return 1; }
    [[ "$output" == *"id-token: write"* ]] || { echo "missing id-token note"; return 1; }
    [[ "$output" == *"pypa/gh-action-pypi-publish"* ]] || { echo "missing publish action note"; return 1; }
    [[ "$output" == *"would push 0 secret(s)"* ]] || { echo "expected 0 push targets: $output"; return 1; }
    # oidc rows must NOT appear as push targets.
    [[ "$output" != *"data-wise/nexus-cli : PYPI_TOKEN"* ]] || { echo "oidc row listed as push target"; return 1; }
'

echo ""

# ============================================================================
# SECTION 4: Usage / error paths
# ============================================================================

echo "${CYAN}--- Section 4: Usage & Errors ---${RESET}"

run_test "tok sync <bogus> → usage error, rc 1" '
    local output rc
    output=$(tok sync bogus 2>&1)
    rc=$?
    [[ $rc -eq 1 ]] || { echo "expected rc 1, got $rc"; return 1; }
    [[ "$output" == *"tok sync <gh|push|repos>"* ]] || { echo "missing usage text: $output"; return 1; }
'

run_test "tok sync repos (no name) → rc 1" '
    local rc
    tok sync repos >/dev/null 2>&1
    rc=$?
    [[ $rc -eq 1 ]] || { echo "expected rc 1, got $rc"; return 1; }
'

echo ""

# ============================================================================
# SECTION 5: Dry-run performs NO writes (no `gh secret set` invoked)
# ============================================================================

echo "${CYAN}--- Section 5: No-Writes Guarantee ---${RESET}"

run_test "repos path never invokes 'gh secret set'" '
    local fake_dir sentinel old_path
    fake_dir=$(mktemp -d)
    sentinel="$fake_dir/gh-was-called"
    cat > "$fake_dir/gh" <<GHEOF
#!/usr/bin/env zsh
for a in "\$@"; do
  if [[ "\$a" == "set" ]]; then touch "$sentinel"; fi
done
exit 0
GHEOF
    chmod +x "$fake_dir/gh"
    old_path="$PATH"
    export PATH="$fake_dir:$PATH"

    tok sync repos github-app >/dev/null 2>&1

    export PATH="$old_path"
    local found=1
    [[ -e "$sentinel" ]] && found=0
    rm -rf "$fake_dir"
    [[ $found -eq 1 ]] || { echo "gh secret set WAS invoked by dry-run path"; return 1; }
'

echo ""

# ============================================================================
# SUMMARY
# ============================================================================

cd "$ORIGINAL_DIR"
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "${GREEN}All $TESTS_PASSED/$TESTS_RUN e2e tests passed${RESET}"
    exit 0
else
    echo "${RED}$TESTS_FAILED/$TESTS_RUN tests failed (${TESTS_PASSED} passed)${RESET}"
    exit 1
fi
