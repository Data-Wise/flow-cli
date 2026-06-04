#!/usr/bin/env zsh
# test-manpage-version-sync.zsh - Anti-drift guard for man pages
#
# Problem this guards: the man/man1/ set silently froze at flow-cli 3.0.0
# (2025-12-26) while FLOW_VERSION marched to 7.8.0 — `man flow` became a lie.
# This guard fails CI whenever any flow-cli man page's .TH version string
# diverges from FLOW_VERSION in flow.plugin.zsh, so the freeze can't recur.
#
# .TH line format (the 2nd quoted field is "<product> <version>"):
#     .TH G 1 "December 2025" "flow-cli 7.8.0" "User Commands"
#                              ^^^^^^^^ ^^^^^
#                              product  version
#
# Scope: ONLY pages whose product token == "flow-cli". A vendored page like
# scribe.1 ("scribe 1.1.0") tracks its own version and must NOT be flagged.
#
# Standalone harness (no test-framework.zsh), consistent with the sibling
# source-scan guards (test-terminal-hygiene-regression.zsh etc.): these assert
# static invariants with awk over .TH lines, not runtime behavior. run_check is
# intentionally distinct from pass/fail/log_test/run_test to avoid
# dogfood-test-quality.zsh's inline-framework check.
#
# Usage: zsh tests/test-manpage-version-sync.zsh

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
CYAN='\033[0;36m'; DIM='\033[2m'; RESET='\033[0m'

CHECKS_RUN=0; CHECKS_PASSED=0; CHECKS_FAILED=0

run_check() {
    local check_name="$1" check_func="$2"
    CHECKS_RUN=$((CHECKS_RUN + 1))
    echo -n "${CYAN}[$CHECKS_RUN] $check_name...${RESET} "
    local output
    if output=$(eval "$check_func" 2>&1); then
        echo "${GREEN}✓${RESET}"; CHECKS_PASSED=$((CHECKS_PASSED + 1))
    else
        echo "${RED}✗${RESET}"; [[ -n "$output" ]] && echo "    ${DIM}$output${RESET}"
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
    fi
}

PLUGIN="$PROJECT_ROOT/flow.plugin.zsh"
MAN_DIR="$PROJECT_ROOT/man/man1"

# ── .TH parsing primitives (the core logic) ─────────────────────────────────

# 2nd quoted field of the first .TH line, e.g. `flow-cli 7.8.0`.
_th_source_field() { awk -F'"' '/^\.TH/ {print $4; exit}' "$1"; }
# Product token (everything before the last space), e.g. `flow-cli`.
_th_product() { local f; f=$(_th_source_field "$1"); print -r -- "${f% *}"; }
# Version token (everything after the last space), e.g. `7.8.0`.
_th_version() { local f; f=$(_th_source_field "$1"); print -r -- "${f##* }"; }

_flow_version() {
    grep -oE 'FLOW_VERSION="?[0-9]+\.[0-9]+\.[0-9]+' "$PLUGIN" \
        | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1
}

# ── logic self-tests (prove the parser, independent of real page state) ──────
# These pass immediately and stay green; they prove the guard CATCHES a
# mismatch and PASSES a synced page (Review Checklist: "Guard fails on a
# deliberately-mismatched .TH, passes when synced.").

run_check "FLOW_VERSION is extractable from flow.plugin.zsh" '
    v=$(_flow_version)
    [[ "$v" =~ "^[0-9]+\.[0-9]+\.[0-9]+$" ]] || { echo "got: [$v]"; exit 1; }
'

run_check "parser reads version + product from a synced .TH fixture" '
    tmp=$(mktemp -d); trap "rm -rf $tmp" EXIT
    print -r -- ".TH FOO 1 \"June 2026\" \"flow-cli 7.8.0\" \"User Commands\"" > "$tmp/foo.1"
    [[ "$(_th_product "$tmp/foo.1")" == "flow-cli" ]] || { echo "product wrong: $(_th_product "$tmp/foo.1")"; exit 1; }
    [[ "$(_th_version "$tmp/foo.1")" == "7.8.0" ]]    || { echo "version wrong: $(_th_version "$tmp/foo.1")"; exit 1; }
'

run_check "parser flags a deliberately-mismatched .TH version" '
    tmp=$(mktemp -d); trap "rm -rf $tmp" EXIT
    print -r -- ".TH BAR 1 \"June 2026\" \"flow-cli 1.2.3\" \"User Commands\"" > "$tmp/bar.1"
    [[ "$(_th_version "$tmp/bar.1")" != "7.8.0" ]] || { echo "should differ from 7.8.0"; exit 1; }
'

run_check "parser identifies non-flow-cli (vendored) pages by product" '
    tmp=$(mktemp -d); trap "rm -rf $tmp" EXIT
    print -r -- ".TH SCRIBE 1 \"June 2026\" \"scribe 1.1.0\" \"User Commands\"" > "$tmp/scribe.1"
    [[ "$(_th_product "$tmp/scribe.1")" == "scribe" ]] || { echo "product: $(_th_product "$tmp/scribe.1")"; exit 1; }
'

# ── the real assertion: every flow-cli man page matches FLOW_VERSION ─────────
# RED until Wave 2 bumps the .TH lines from 3.0.0 -> FLOW_VERSION.

run_check "at least one flow-cli man page is present" '
    found=0
    for p in "$MAN_DIR"/*.1(N); do
        [[ "$(_th_product "$p")" == "flow-cli" ]] && found=$((found+1))
    done
    (( found > 0 )) || { echo "no flow-cli .TH pages under $MAN_DIR"; exit 1; }
'

run_check "every flow-cli man page .TH version == FLOW_VERSION" '
    want=$(_flow_version)
    checked=0; stale=""
    for p in "$MAN_DIR"/*.1(N); do
        [[ "$(_th_product "$p")" == "flow-cli" ]] || continue   # skip vendored pages
        checked=$((checked+1))
        v=$(_th_version "$p")
        [[ "$v" == "$want" ]] || stale+="${p:t}=$v "
    done
    (( checked > 0 )) || { echo "no flow-cli pages checked"; exit 1; }
    if [[ -n "$stale" ]]; then
        echo "stale pages (expected flow-cli $want): $stale"
        echo "    fix: bump the .TH 2nd field to \"flow-cli $want\" on each"
        exit 1
    fi
'

echo ""
echo "${CYAN}──────────────────────────────────────────────────────────────${RESET}"
if [[ $CHECKS_FAILED -eq 0 ]]; then
    echo "${GREEN}All $CHECKS_PASSED/$CHECKS_RUN man-page version-sync checks passed${RESET}"; exit 0
else
    echo "${RED}$CHECKS_FAILED/$CHECKS_RUN checks failed${RESET}"
    echo "${YELLOW}Man pages drifted from FLOW_VERSION — see SPEC-manpage-refresh-2026-06-04.${RESET}"
    exit 1
fi
