#!/usr/bin/env zsh
# test-dispatcher-binary-precedence.zsh
# ──────────────────────────────────────────────────────────────────────────────
# Regression guard for the B3 binary-precedence guard in flow.plugin.zsh.
#
# Invariant: when a dispatcher defines a command function whose name also
# exists as an external binary on $PATH, the loader DROPS the function so the
# binary wins — UNLESS the command is an intentional shadow (listed in
# FLOW_INTENTIONAL_SHADOWS, e.g. cc/r/mcp) or force-kept via
# FLOW_FORCE_DISPATCHER_<NAME>=1. `_`-prefixed helpers are never touched.
#
# This is the general fix behind the `obs` shadowing bug: flow-cli's broken
# obs() dispatcher used to mask the real Homebrew obs binary. obs is now
# deleted (Phase 1); this guard stops any FUTURE dispatcher from re-shadowing
# a working binary by accident.
#
# Usage: zsh tests/test-dispatcher-binary-precedence.zsh
# ──────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

source "$SCRIPT_DIR/test-framework.zsh"

# ── Fixtures ─────────────────────────────────────────────────────────────────
TMPROOT=$(mktemp -d)
TMPBIN="$TMPROOT/bin"
mkdir -p "$TMPBIN"

# A stub external binary the test dispatchers will try to shadow.
print -r -- '#!/bin/sh' > "$TMPBIN/flowfaketool"
print -r -- 'echo stub-binary' >> "$TMPBIN/flowfaketool"
chmod +x "$TMPBIN/flowfaketool"

# Throwaway dispatcher files (one public fn each, plus a helper case).
print -r -- 'flowfaketool() { echo from-dispatcher; }' > "$TMPROOT/collide.zsh"
print -r -- 'flownobinaryxyz() { echo ok; }'           > "$TMPROOT/nobin.zsh"
{
  print -r -- 'flowfaketool() { echo cmd; }'
  print -r -- '_flowfaketool_helper() { echo helper; }'
} > "$TMPROOT/both.zsh"

cleanup() { rm -rf "$TMPROOT"; }

# ── Load the plugin (defines _flow_load_dispatcher + FLOW_INTENTIONAL_SHADOWS,
#    and loads the real dispatchers for the "don't break the user" checks). ────
export FLOW_QUIET=1
source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null

if ! typeset -f _flow_load_dispatcher >/dev/null 2>&1; then
    echo "${RED}ERROR: _flow_load_dispatcher not defined after sourcing plugin${RESET}"
    cleanup
    exit 1
fi

# Run the guard on a file in an isolated subshell with the stub on $PATH, then
# print how the named function resolves (whence -w => "<name>: command|function").
# $3 is extra setup eval'd inside the subshell (allowlist/force tweaks).
_run_guard() {
    local file="$1" fn="$2" extra="$3"
    (
        PATH="$TMPBIN:$PATH"
        rehash
        eval "$extra"
        _flow_load_dispatcher "$file"
        whence -w "$fn"
    )
}

# ── Tests ────────────────────────────────────────────────────────────────────

test_case "shadowing dispatcher is dropped (binary wins)"
out=$(_run_guard "$TMPROOT/collide.zsh" flowfaketool "")
assert_contains "$out" "flowfaketool: command" "expected fn dropped -> resolves to binary"
test_case_end

test_case "FLOW_INTENTIONAL_SHADOWS keeps a deliberate shadow"
out=$(_run_guard "$TMPROOT/collide.zsh" flowfaketool "FLOW_INTENTIONAL_SHADOWS+=(flowfaketool)")
assert_contains "$out" "flowfaketool: function" "expected allowlisted fn kept"
test_case_end

test_case "FLOW_FORCE_DISPATCHER_<NAME>=1 keeps the function"
out=$(_run_guard "$TMPROOT/collide.zsh" flowfaketool "export FLOW_FORCE_DISPATCHER_FLOWFAKETOOL=1")
assert_contains "$out" "flowfaketool: function" "expected forced fn kept"
test_case_end

test_case "non-colliding dispatcher loads normally"
out=$(_run_guard "$TMPROOT/nobin.zsh" flownobinaryxyz "")
assert_contains "$out" "flownobinaryxyz: function" "expected non-colliding fn kept"
test_case_end

# A file that defines BOTH a colliding command and a helper: command dropped,
# helper preserved (the guard ignores `_`-prefixed names).
out=$(
    PATH="$TMPBIN:$PATH"; rehash
    _flow_load_dispatcher "$TMPROOT/both.zsh"
    print -r -- "CMD=$(whence -w flowfaketool) HELP=$(whence -w _flowfaketool_helper)"
)
test_case "colliding command in a multi-fn file is dropped"
assert_contains "$out" "CMD=flowfaketool: command" "command should be dropped"
test_case_end
test_case "internal _helper in the same file is preserved"
assert_contains "$out" "HELP=_flowfaketool_helper: function" "helper should survive"
test_case_end

# Don't break the user: intentional shadows survive a real plugin load even
# though r/mcp/cc/tm all have PATH binaries on dev machines.
for d in r mcp cc tm; do
    test_case "intentional shadow '$d' survives plugin load"
    assert_function_exists "$d"
    test_case_end
done

# Regression (ci-full-suite-gate): `tm` collides with a real `tm` binary present
# on some Linux distros / GitHub ubuntu runners (absent on macOS dev boxes), so
# the guard used to SILENTLY unfunction the documented `tm` dispatcher there —
# only caught once the full suite ran in CI. tm must now survive the collision.
mkdir -p "$TMPROOT/tmbin"
print -r -- '#!/bin/sh' > "$TMPROOT/tmbin/tm"
print -r -- 'echo "fake tm binary"' >> "$TMPROOT/tmbin/tm"
chmod +x "$TMPROOT/tmbin/tm"
test_case "tm dispatcher survives a real 'tm' binary on PATH (runner regression)"
out=$(
    PATH="$TMPROOT/tmbin:$PATH"; rehash
    _flow_load_dispatcher "$PROJECT_ROOT/lib/dispatchers/tm-dispatcher.zsh"
    whence -w tm
)
assert_contains "$out" "tm: function" "tm must stay a function despite a 'tm' binary on PATH"
test_case_end

# Non-colliding real dispatchers still load.
for d in g qu em teach tok dots; do
    test_case "dispatcher '$d' loads"
    assert_function_exists "$d"
    test_case_end
done

# Regression: the obs dispatcher is gone, so obs must NOT be a function.
test_case "obs is not a function (shadowing bug fixed)"
if typeset -f obs >/dev/null 2>&1; then
    test_fail "obs() is still defined — it should resolve to the binary/PATH"
else
    test_pass
fi

# Footgun caveat (documented in CLAUDE.md): FLOW_INTENTIONAL_SHADOWS=() is
# "set but empty" (zsh ${+arr} is 1 for an empty array), so the (r mcp cc)
# default is NOT applied and a normally protected shadow like `cc` (vs
# /usr/bin/cc) gets dropped. This must run in a genuinely fresh shell: the
# guard only acts on functions NEW to the current source pass, so re-sourcing
# in this already-loaded test shell would be a no-op. Hence `zsh -f`.
# Needs a real `cc` binary to observe; skipped otherwise.
test_case "empty FLOW_INTENTIONAL_SHADOWS overrides the default (cc dropped)"
if [[ -z "${commands[cc]}" ]]; then
    test_skip "no cc binary on PATH"
else
    out=$(FLOW_TEST_ROOT="$PROJECT_ROOT" zsh -fc '
        export FLOW_QUIET=1
        typeset -ga FLOW_INTENTIONAL_SHADOWS=()
        source "$FLOW_TEST_ROOT/flow.plugin.zsh" 2>/dev/null
        whence -w cc
    ')
    assert_contains "$out" "cc: command" "cc should be dropped when the allowlist is explicitly emptied"
    test_case_end
fi

# Counterpart: with the var UNSET, the default (r mcp cc) IS applied and cc
# survives — proving the gate, not just the guard.
test_case "unset FLOW_INTENTIONAL_SHADOWS applies the (r mcp cc) default (cc kept)"
if [[ -z "${commands[cc]}" ]]; then
    test_skip "no cc binary on PATH"
else
    out=$(FLOW_TEST_ROOT="$PROJECT_ROOT" zsh -fc '
        export FLOW_QUIET=1
        unset FLOW_INTENTIONAL_SHADOWS
        source "$FLOW_TEST_ROOT/flow.plugin.zsh" 2>/dev/null
        whence -w cc
    ')
    assert_contains "$out" "cc: function" "cc should be kept when the allowlist defaults apply"
    test_case_end
fi

cleanup
print_summary
exit $?
