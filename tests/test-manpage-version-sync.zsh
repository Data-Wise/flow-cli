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
# This file also guards man-page COVERAGE: every dispatcher (a public top-level
# command function in lib/dispatchers/*.zsh or lib/atlas-bridge.zsh, aliases
# excluded) must have a man/man1/<cmd>.1, and no flow-cli page may be an orphan
# (a page with no matching dispatcher). So adding a dispatcher without its page —
# or deleting a dispatcher but leaving its page — fails CI.
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
DISP_DIR="$PROJECT_ROOT/lib/dispatchers"
ATLAS="$PROJECT_ROOT/lib/atlas-bridge.zsh"

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

# ── dispatcher-command extraction (for the coverage / missing-page guard) ────
# A "dispatcher" is a public top-level command function (e.g. `tok() { ... }`)
# defined in a dispatcher source file. We derive the set from the functions the
# shell actually exposes — NOT from filenames (irregular: obs.zsh,
# email-dispatcher.zsh -> em, at lives in atlas-bridge.zsh) and NOT from a
# `_<cmd>_help` convention (teach has none). Pure aliases whose entire body is a
# lone `<cmd> "$@"` delegation (e.g. vibe -> v) are excluded.
#
# Body of a top-level `name() {` ... up to the first `}` at column 0.
_msync_func_body() {
    local file="$1" fn="$2"
    awk -v fn="$fn" '
        $0 ~ "^" fn "\\(\\) *\\{" {f=1; next}
        f && /^\}/ {exit}
        f {print}
    ' "$file"
}

# Print dispatcher command names found across the given source files, one per
# line, sorted/unique, aliases removed.
_msync_dispatcher_cmds() {
    local file name body sig
    for file in "$@"; do
        [[ -f "$file" ]] || continue
        for name in ${(f)"$(grep -oE '^[a-z][a-z0-9]*\(\) \{' "$file" | sed 's/() {//')"}; do
            body=$(_msync_func_body "$file" "$name")
            sig=$(echo "$body" | grep -vE '^[[:space:]]*(#|$)')   # drop comments + blanks
            # pure-alias delegation: exactly one statement, `<word> "$@"`
            if [[ $(echo "$sig" | grep -c .) -eq 1 ]] \
               && echo "$sig" | grep -qE '^[[:space:]]*[a-z][a-z0-9]*[[:space:]]+"\$@"[[:space:]]*$'; then
                continue
            fi
            echo "$name"
        done
    done | sort -u
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

# ── coverage / missing-page logic self-tests (fixtures) ─────────────────────
# Prove the detector flags a dispatcher with no page, and ignores aliases and
# non-dispatcher helper files — independent of the real tree.

run_check "coverage detector finds a real dispatcher function" '
    tmp=$(mktemp -d); trap "rm -rf $tmp" EXIT
    printf "foo() {\n  case \"\$1\" in\n    *) _foo_help ;;\n  esac\n}\n" > "$tmp/foo-dispatcher.zsh"
    cmds=$(_msync_dispatcher_cmds "$tmp/foo-dispatcher.zsh")
    [[ "$cmds" == "foo" ]] || { echo "got: [$cmds]"; exit 1; }
'

run_check "coverage detector flags a dispatcher missing its man page" '
    tmp=$(mktemp -d); trap "rm -rf $tmp" EXIT
    mkdir -p "$tmp/man"
    printf "foo() {\n  case \"\$1\" in\n    *) _foo_help ;;\n  esac\n}\n" > "$tmp/foo-dispatcher.zsh"
    missing=""
    for c in ${(f)"$(_msync_dispatcher_cmds "$tmp/foo-dispatcher.zsh")"}; do
        [[ -f "$tmp/man/$c.1" ]] || missing+="$c "
    done
    [[ "$missing" == "foo " ]] || { echo "expected foo flagged missing, got: [$missing]"; exit 1; }
'

run_check "coverage detector ignores pure-alias public functions (vibe-style)" '
    tmp=$(mktemp -d); trap "rm -rf $tmp" EXIT
    printf "baz() {\n    qux \"\$@\"\n}\n" > "$tmp/baz-dispatcher.zsh"
    cmds=$(_msync_dispatcher_cmds "$tmp/baz-dispatcher.zsh")
    [[ -z "$cmds" ]] || { echo "alias baz should be skipped, got: [$cmds]"; exit 1; }
'

run_check "coverage detector ignores helper files with no public function" '
    tmp=$(mktemp -d); trap "rm -rf $tmp" EXIT
    printf "_helper_only() { echo x; }\n" > "$tmp/teach-dates.zsh"
    cmds=$(_msync_dispatcher_cmds "$tmp/teach-dates.zsh")
    [[ -z "$cmds" ]] || { echo "helper should yield no cmds, got: [$cmds]"; exit 1; }
'

# ── the real assertions: dispatcher <-> man-page coverage ───────────────────

run_check "every dispatcher command has a man page" '
    cmds=$(_msync_dispatcher_cmds "$DISP_DIR"/*.zsh(N) "$ATLAS")
    [[ -n "$cmds" ]] || { echo "no dispatcher commands detected"; exit 1; }
    missing=""
    for c in ${(f)cmds}; do
        [[ -f "$MAN_DIR/$c.1" ]] || missing+="$c "
    done
    if [[ -n "$missing" ]]; then
        echo "dispatchers with no man/man1/<cmd>.1: $missing"
        echo "    fix: add a page for each (model: man/man1/g.1)"
        exit 1
    fi
'

run_check "no orphan flow-cli dispatcher page (page without a dispatcher)" '
    cmds=$(_msync_dispatcher_cmds "$DISP_DIR"/*.zsh(N) "$ATLAS")
    orphan=""
    for p in "$MAN_DIR"/*.1(N); do
        [[ "$(_th_product "$p")" == "flow-cli" ]] || continue   # skip vendored
        base="${p:t:r}"
        [[ "$base" == "flow" ]] && continue                     # flow is the index, not a dispatcher
        print -r -- "$cmds" | grep -qx "$base" || orphan+="$base "
    done
    if [[ -n "$orphan" ]]; then
        echo "man pages with no matching dispatcher: $orphan"
        echo "    fix: remove the stale page, or it names a real command not detected"
        exit 1
    fi
'

echo ""
echo "${CYAN}──────────────────────────────────────────────────────────────${RESET}"
if [[ $CHECKS_FAILED -eq 0 ]]; then
    echo "${GREEN}All $CHECKS_PASSED/$CHECKS_RUN man-page guard checks passed${RESET}"; exit 0
else
    echo "${RED}$CHECKS_FAILED/$CHECKS_RUN checks failed${RESET}"
    echo "${YELLOW}Man-page version drift or coverage gap — see SPEC-manpage-refresh-2026-06-04.${RESET}"
    exit 1
fi
