#!/usr/bin/env zsh
# test-alias-shadowing.zsh
#
# Dispatchers run in the user's INTERACTIVE shell, where aliases are live and
# expand at parse time. A user alias on a coreutil silently hijacks any
# pipeline that uses it.
#
# This is not hypothetical. A real user had:
#
#     tr='track-activity report'
#
# so every `... | tr -d ' '` in lib/ ran `track-activity report -d ' '`, and
# its output landed in the variable instead of the count. Observed live in
# `teach deploy --dry-run`:
#
#     Would deploy Monthly Terminal Report (2026-08):
#     ================================== files:
#
# where "675" belonged. 101 pipeline sites across 34 files were affected.
# The fix is `command tr`, which bypasses aliases and functions.
#
# This test plants a hostile alias and asserts the count still comes out
# numeric — it is a positive control, so it FAILS if the `command` prefix is
# ever dropped.

set -uo pipefail
ROOT="${0:A:h}/.."

PASS=0
FAIL=0
_ok()  { PASS=$((PASS+1)); echo "  ✅ $1"; }
_bad() { FAIL=$((FAIL+1)); echo "  ❌ $1"; [[ -n "${2:-}" ]] && echo "     $2"; }

echo "=== alias shadowing ==="

# 1. No bare `| tr` survives in shipped lib/. This is the whole-codebase guard;
#    a new one added later fails here rather than in a user's terminal.
bare=$(grep -rn '|[[:space:]]*tr ' "$ROOT/lib" --include='*.zsh' 2>/dev/null | wc -l | command tr -d ' ')
if [[ "$bare" == "0" ]]; then
  _ok "no bare '| tr' in lib/*.zsh (all use 'command tr')"
else
  _bad "$bare bare '| tr' pipeline(s) in lib/" \
       "$(grep -rn '|[[:space:]]*tr ' "$ROOT/lib" --include='*.zsh' 2>/dev/null | head -3)"
fi

# 2. Behavioural: with a hostile alias live, `command tr` still yields a count.
hostile=$(zsh -c '
  alias tr="echo HIJACKED"
  setopt aliases
  printf "a\nb\nc\n" | wc -l | command tr -d " "
' 2>/dev/null | command tr -d ' \n')
if [[ "$hostile" == "3" ]]; then
  _ok "'command tr' survives a hostile tr alias (got 3)"
else
  _bad "'command tr' was hijacked" "expected 3, got '$hostile'"
fi

# 3. Negative control: the bare form MUST be hijacked. If this stops failing,
#    the environment no longer reproduces the bug and assertion 2 proves
#    nothing — better to know that than to trust a green test.
naive=$(zsh -c '
  alias tr="echo HIJACKED"
  setopt aliases
  eval "printf \"a\nb\nc\n\" | wc -l | tr -d \" \""
' 2>/dev/null | command tr -d ' \n')
if [[ "$naive" == *HIJACKED* ]]; then
  _ok "negative control: bare 'tr' IS hijacked, so the guard is meaningful"
else
  _bad "negative control did not reproduce the hijack" \
       "got '$naive' — assertion 2 may be vacuous; check zsh alias semantics"
fi

echo ""
echo "=== $PASS passed, $FAIL failed ==="
[[ $FAIL -eq 0 ]]
