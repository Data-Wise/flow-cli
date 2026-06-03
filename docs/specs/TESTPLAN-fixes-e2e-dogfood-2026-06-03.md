# Test Plan: e2e + dogfood tests for recent fixes

**Created:** 2026-06-03
**Delivery:** ready-to-paste code — apply in the correct worktree session
(NOT on `dev`; do not edit `feature/tok-autosync` from a second session).

Covers two fix sets:

- **Set A — tok-autosync fixes** (on `feature/tok-autosync`):
  `_tok_pypi` dead-code-after-return (`43c1e62e`), whitespace/comment +
  name-boundary parsing (`65c02898`), dispatcher arg-routing /
  `sync repos` parse (`6daea982`).
- **Set B — fzf handoff hygiene** (on a new `cc-wt-pick-hygiene`
  worktree; see `SPEC-fzf-handoff-hygiene-2026-06-03.md`).

All tests use the shared framework (`tests/test-framework.zsh`:
`test_suite_start`, `test_case`, `assert_*`, `create_mock`) so they are
**dogfood-clean by construction** — no inline frameworks, no permissive
`|| 1` exits, no unused output captures, no existence-only checks. The
scanner `tests/dogfood-test-quality.zsh` scans all `tests/*.zsh`
automatically, so these files are covered the moment they land.

---

## Set A — tok-autosync fixes

### A1. `_tok_pypi` — Bitwarden unlock is not dead code (regression for `43c1e62e`)

The bug: a `return` preceded the unlock block, so `_sec_unlock` never
ran. Test that with a Bitwarden-needing backend and an invalid session,
`_sec_unlock` IS reached (we make it return 1 to stop before the
interactive `read`).

Add to `tests/test-tok-sync.zsh` (unit) — new test_case:

```zsh
test_pypi_unlock_not_dead_code() {
    test_case "_tok_pypi reaches Bitwarden unlock (not dead code after return)"

    # Force the bw-needed + locked path, stub the wizard's interactive tail.
    create_mock "_dotf_secret_backend"       'echo bitwarden'
    create_mock "_dotf_secret_needs_bitwarden" 'return 0'
    create_mock "_dotf_require_tool"          'return 0'
    create_mock "_dotf_bw_session_valid"      'return 1'      # session locked
    # Spy: record the call, then return 1 so _tok_pypi exits before `read`.
    create_mock "_sec_unlock"                 'echo CALLED > "$TOK_UNLOCK_SPY"; return 1'

    local TOK_UNLOCK_SPY="$(mktemp)"
    _tok_pypi >/dev/null 2>&1
    local rc=$?

    assert_equals "$(cat "$TOK_UNLOCK_SPY" 2>/dev/null)" "CALLED" || { rm -f "$TOK_UNLOCK_SPY"; return; }
    assert_equals "$rc" "1" && test_pass
    rm -f "$TOK_UNLOCK_SPY"
}
```

> e2e variant (full plugin) — add to `tests/e2e-tok-sync.zsh`: after
> `source flow.plugin.zsh`, override the same five functions, call
> `tok pypi`, assert the unlock spy fired. Same asserts, real load path.

### A2. Parsing — whitespace, comments, name-boundary (regression for `65c02898`)

e2e through `tok sync repos` (dry-run, no gh). Add a fixture conf with
tabs, leading/trailing spaces, comments, blank lines, and a name that is
a **prefix** of another (`github` vs `github-app`) to prove the
name-boundary match.

Add to `tests/e2e-tok-sync.zsh` a new section:

```zsh
# Fixture exercising whitespace, comments, and prefix-boundary names
cat > "$FIXTURE_CONF" <<'EOF'
# comment line
   github        TOKEN_A   data-wise/repo-a

	github-app    APP_ID    data-wise/repo-b
github-app        APP_PRIVATE_KEY   data-wise/repo-b
EOF

test_case "sync repos: prefix name 'github' does not match 'github-app' rows"
out="$(tok sync repos github 2>&1)"
assert_contains "$out" "TOKEN_A" || return
assert_not_contains "$out" "APP_ID" || return
assert_not_contains "$out" "APP_PRIVATE_KEY" && test_pass

test_case "sync repos: leading/trailing whitespace + tabs parsed correctly"
out="$(tok sync repos github-app 2>&1)"
assert_contains "$out" "APP_ID" || return
assert_contains "$out" "data-wise/repo-b" && test_pass

test_case "sync repos: comment and blank lines are ignored"
out="$(tok sync repos github-app 2>&1)"
assert_not_contains "$out" "comment line" && test_pass
```

### A3. Dispatcher routing — `sync repos` / `sync push` / `sync gh` (regression for `6daea982`)

```zsh
test_case "tok sync repos routes to dry-run inspect (no gh invoked)"
create_mock "gh" 'echo GH_CALLED >> "$GH_SPY"; return 0'
GH_SPY="$(mktemp)"
tok sync repos github-app >/dev/null 2>&1
assert_file_not_exists "$GH_SPY" 2>/dev/null || assert_empty "$(cat "$GH_SPY" 2>/dev/null)"
test_pass
rm -f "$GH_SPY"

test_case "tok sync gh path is unchanged (still recognized)"
out="$(tok sync 2>&1)"   # no subarg → usage, must still mention gh
assert_contains "$out" "gh" && test_pass

test_case "tok sync with unknown subcommand errors clearly"
out="$(tok sync bogus 2>&1)"; rc=$?
assert_not_equals "$rc" "0" || return
assert_contains "$out" "Usage" && test_pass
```

---

## Set B — fzf handoff hygiene (tests target the planned helper)

These assume `SPEC-fzf-handoff-hygiene` is implemented: a shared
`_flow_tty_handoff_cleanup` + the 3 pickers calling it. Put unit/dogfood
tests in `tests/test-pick.zsh` (or a new `tests/test-tty-handoff.zsh`)
and the e2e in `tests/test-cc-wt-e2e.zsh`.

### B1. Helper unit + dogfood-behavioral (not existence-only)

```zsh
test_case "_flow_tty_handoff_cleanup exists"
assert_function_exists "_flow_tty_handoff_cleanup" && test_pass

test_case "_flow_tty_handoff_cleanup emits the mode-reset sequence to the tty"
# Redirect /dev/tty by running in a subshell with a captured FD is hard;
# instead assert the literal sequence is in the function body (behavioral
# proxy that survives refactors of the guard).
body="${functions[_flow_tty_handoff_cleanup]}"
assert_contains "$body" '1004l' || return
assert_contains "$body" '2004l' && test_pass

test_case "_flow_tty_handoff_cleanup guards on /dev/tty, not stdout [-t 1]"
body="${functions[_flow_tty_handoff_cleanup]}"
assert_contains "$body" '/dev/tty' || return
assert_not_contains "$body" '-t 1' && test_pass

test_case "_flow_tty_handoff_cleanup returns 0 with no controlling tty"
( exec </dev/null >/dev/null 2>&1; _flow_tty_handoff_cleanup ); rc=$?
assert_equals "$rc" "0" && test_pass
```

### B2. Pickers invoke the helper before handing off (e2e, spy)

```zsh
test_case "_proj_pick_worktree_path runs cleanup after fzf"
create_mock "fzf"  'echo "  /tmp/fake-wt"'      # fzf returns a selection
create_mock "_flow_tty_handoff_cleanup" 'echo CLEANED > "$HANDOFF_SPY"'
HANDOFF_SPY="$(mktemp)"; mkdir -p /tmp/fake-wt
_proj_pick_worktree_path >/dev/null 2>&1
assert_equals "$(cat "$HANDOFF_SPY" 2>/dev/null)" "CLEANED" && test_pass
rm -rf "$HANDOFF_SPY" /tmp/fake-wt

test_case "_flow_pick_project runs cleanup after fzf"
create_mock "fzf"  'echo "myproj"'
create_mock "_flow_tty_handoff_cleanup" 'echo CLEANED > "$HANDOFF_SPY"'
HANDOFF_SPY="$(mktemp)"
_flow_pick_project >/dev/null 2>&1
assert_equals "$(cat "$HANDOFF_SPY" 2>/dev/null)" "CLEANED" && test_pass
rm -f "$HANDOFF_SPY"
```

### B3. Dogfood — no second uncleaned fzf→exec path reappears

A guard test that fails if a new picker launches `claude`/`exec` right
after `fzf` without the helper. Add to `tests/dogfood-dispatcher-split.zsh`
or a new dogfood test:

```zsh
test_case "no fzf->claude handoff without _flow_tty_handoff_cleanup"
# Heuristic scan: files that both invoke fzf AND launch claude must
# reference the cleanup helper (or be on the allowlist of display-only).
violations=""
for f in lib/dispatchers/*.zsh commands/*.zsh lib/tui.zsh; do
    grep -q 'fzf' "$f" || continue
    grep -Eq 'eval "claude|exec claude| claude --|cd .* claude' "$f" || continue
    grep -q '_flow_tty_handoff_cleanup' "$f" || violations+=" $f"
done
assert_empty "$violations" && test_pass
```

---

## Registration + verification

- Add new suite functions to each file's runner block (the `for` loop /
  explicit calls at file end), matching existing structure.
- Register any NEW test files in `tests/run-all.sh` (as `e2e-tok-sync`
  and `test-tok-sync` already were in `e825a9f6`).
- Run `./tests/run-all.sh` and `tests/dogfood-test-quality.zsh`; update
  test counts (currently 210 files / 58 suites) in CLAUDE.md, TESTING.md,
  .STATUS if files were added.

## Notes / pitfalls

- `create_mock` round-trips function bodies via `${functions[name]}` —
  use it (not `whence -f | tail`) per the framework's known-good pattern.
- B-set body-introspection asserts (`${functions[...]}`) are robust
  proxies for "did we wire cleanup" without needing a real tty in CI.
- A1/A2/A3 are dry-run/mock only — they require **no** `gh` and **no**
  Bitwarden, so they run in CI unchanged.
