# ORCHESTRATE: Wire lib/doctor-cache.zsh into commands/doctor.zsh GitHub token validation

**Branch:** `feature/wire-doctor-cache`
**Base:** `dev` @ `74af31b1`
**Related:** commit `74af31b1` (test-side caching of `doctor --verbose`); `.STATUS` Pending item "Doctor command bypasses its own cache" (filed 2026-05-13)

## Context

The doctor command's GitHub token validation at `commands/doctor.zsh:405` calls `curl https://api.github.com/user` directly, ignoring the file-based cache at `lib/doctor-cache.zsh` (25 KB, fully implemented). Every `flow doctor` invocation eats ~5–8 s of network time for a result that's stable until the token rotates.

The previous commit (`74af31b1`) papered over this in tests by caching `doctor --verbose` output in `setup()`. This feature wires the cache into the production code path so the speedup benefits all end users and removes the test-side workaround's reason to exist.

## Goal

`flow doctor` (default and `--verbose` modes) should consult `_doctor_cache_token_get` before calling curl. On cache hit within TTL: skip curl entirely. On miss/expired/corrupt: curl, then `_doctor_cache_token_set` the result.

Success: second `flow doctor` invocation within TTL completes in ≤1 s.

## API to use (read first)

Read these specific ranges in `lib/doctor-cache.zsh` before implementing:

| Lines | Function | Purpose |
|---|---|---|
| 722–746 | `_doctor_cache_token_get <key>` | Returns cached token-validation result if non-expired; non-zero exit on miss |
| 747–771 | `_doctor_cache_token_set <key> <value> [ttl]` | Stores validation result |
| 772–793 | `_doctor_cache_token_clear <key>` | Invalidate (use on token rotation) |
| 264–354 | `_doctor_cache_get` | Low-level get (read this to understand return format and exit codes) |
| 355–484 | `_doctor_cache_set` | Low-level set |
| 76–104 | Cache directory location (`DOCTOR_CACHE_DIR`, default `~/.flow/cache/doctor/`) |

Do not modify the cache library. The wiring goes in `commands/doctor.zsh` only.

## Implementation

### Step 1 — Read the cache API

Read all line ranges above. Confirm:
- What does `_doctor_cache_token_get` print on hit? (one line? multi-line? JSON?)
- What's the default TTL on `_doctor_cache_token_set`?
- Does the cache key need to vary by token value (so rotation invalidates automatically) or by an opaque name like `"github-token-validation"`?

If `_doctor_cache_token_*` doesn't expose a way to make the key derive from the token, use `_doctor_cache_get`/`_doctor_cache_set` with a manually-constructed key like `"github-token-$(echo "$token" | shasum -a 256 | cut -c1-12)"`. Decide based on what the API reveals.

### Step 2 — Modify `commands/doctor.zsh:404–417`

Current code:

```zsh
else
  # Validate token via API
  local api_response=$(curl -s -w "\n%{http_code}" \
    -H "Authorization: token $token" \
    "https://api.github.com/user" 2>/dev/null)

  local http_code=$(echo "$api_response" | tail -1)
  local username=$(echo "$api_response" | sed '$d' | jq -r '.login // "unknown"')

  if [[ "$http_code" != "200" ]]; then
    _doctor_log_quiet "  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} Invalid/Expired"
    token_issues+=("invalid")
  else
    _doctor_log_quiet "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Valid (@$username)"
    ...
```

Target shape:

```zsh
else
  # Validate token via API, using cache when available
  local cache_key="github-token-$(_doctor_token_fingerprint "$token")"  # 12-char hash, see Step 1
  local cached
  local http_code username

  if cached=$(_doctor_cache_token_get "$cache_key" 2>/dev/null); then
    # Cache hit — parse stored "http_code|username" (or chosen format from Step 1)
    http_code="${cached%%|*}"
    username="${cached#*|}"
    _doctor_log_verbose "  ${FLOW_COLORS[muted]}[Cache hit]${FLOW_COLORS[reset]}"
  else
    # Cache miss — curl, then store
    local api_response=$(curl -s -w "\n%{http_code}" \
      -H "Authorization: token $token" \
      "https://api.github.com/user" 2>/dev/null)
    http_code=$(echo "$api_response" | tail -1)
    username=$(echo "$api_response" | sed '$d' | jq -r '.login // "unknown"')

    # Only cache successful validations (don't cache transient curl failures)
    if [[ "$http_code" == "200" ]]; then
      _doctor_cache_token_set "$cache_key" "${http_code}|${username}" 3600
    fi
  fi

  # Existing http_code / username handling continues unchanged from line 412
  if [[ "$http_code" != "200" ]]; then
  ...
```

**Decisions to confirm with user before coding (in the new session):**

1. **TTL** — proposed 1 hour (3600 s). Justification: token-validation result is stable for the token's full ~90-day lifetime; 1 h balances freshness with the ~30 cold starts per day a heavy user might do. Alternatives: 15 min (cautious), 24 h (aggressive).
2. **Cache key derivation** — fingerprint of token value (rotation auto-invalidates) vs static key + explicit clear. Recommendation: **fingerprint** (12-char sha256 prefix). Token rotation should not require manual cache clearing.
3. **`--no-cache` / `--fresh` flag** — should `flow doctor` get an option to bypass cache? Recommendation: **yes**, low cost. Add to the argparse around line 39 in doctor.zsh; if set, skip the `_doctor_cache_token_get` call. Useful for "why is my token broken?" troubleshooting.
4. **What to store** — `"${http_code}|${username}"` pipe-delimited is simplest; alternatively JSON via jq if richer state is needed later. Recommendation: pipe-delimited for now; we're only caching a binary result + display name.

### Step 3 — Update `--fix` path

Search `commands/doctor.zsh` for the `--fix` handler. When the user rotates a token via `tok rotate github-token` (or similar) and re-runs `flow doctor --fix`, the cache should be cleared. Either:
- Have the `--fix` path call `_doctor_cache_token_clear "$cache_key"` before re-validating, OR
- Trust the fingerprint-based key to auto-invalidate (new token → new fingerprint → cache miss → curl).

If using fingerprint keys (Step 1 decision), this step is a no-op. Verify by reading the fix path.

### Step 4 — Tests

**Production code coverage:**

In `tests/test-doctor.zsh`, add three new test functions (after `test_doctor_tracks_missing_brew`):

```zsh
test_doctor_cache_hit() {
    # Run doctor twice; second invocation should not curl
    # Easiest: mock curl, count invocations
    # Alternative: time both runs; assert second < first by significant margin
}

test_doctor_cache_miss_after_token_rotation() {
    # If fingerprint-based keys: change token value, assert curl runs again
}

test_doctor_no_cache_flag() {
    # If --no-cache flag added: assert curl runs even with valid cache
}
```

Use the existing `tests/test-framework.zsh` mocking helpers. Inspect `reset_mocks` (called in `cleanup()` of test-doctor.zsh) to find the mock infrastructure.

**Avoid the test-doctor.zsh timing regression:** the previous fix (commit `74af31b1`) caches `doctor` output at setup. The cache used at the application layer means the FIRST doctor call in setup() will still hit curl (cache miss on fresh test env). Total test time should not regress; if it does, the test should set `DOCTOR_CACHE_DIR=$TEST_ROOT/cache` so cache state stays isolated and primed via a mocked curl.

**Test-side simplification (optional, separate commit):**

After the production caching works, the test's `CACHED_DOCTOR_VERBOSE` workaround from commit `74af31b1` may be removable — second `doctor --verbose` call will hit cache. Confirm this by running the test under `timeout 30` and ensuring it still completes; if so, drop the `CACHED_DOCTOR_VERBOSE` setup and inline the `doctor --verbose` calls back into the two test functions. Do NOT bundle this with the production change; commit separately as `refactor(tests): drop now-redundant doctor --verbose cache`.

### Step 5 — Verification

```bash
# 1. Unit tests pass under run-all.sh timeout
./tests/run-all.sh

# 2. End-to-end timing: cold + warm cache
rm -rf ~/.flow/cache/doctor/
time flow doctor          # cold: should be ~current speed (≤8s)
time flow doctor          # warm: should be ≤1s
time flow doctor --no-cache   # if flag added: should match cold timing

# 3. Token rotation invalidates (if fingerprint keys):
# (capture current cache state; rotate via sec; verify cache miss on next run)

# 4. Cache file inspection
ls -la ~/.flow/cache/doctor/
cat ~/.flow/cache/doctor/github-token-*.cache    # confirm format matches what was set
```

### Step 6 — Documentation

Files to update once the implementation is verified:

- `.STATUS` (main repo) — log session entry, move pending item from Pending → Recent Releases / completed, update worktree row to "Implemented, pending merge"
- `CHANGELOG.md` (or wherever flow-cli tracks user-facing changes) — note the doctor performance improvement under unreleased
- If `--no-cache` flag was added: `docs/commands/doctor.md` and `flow doctor --help` output (in `_doctor_help` function)

### Step 7 — Integration

```bash
git checkout feature/wire-doctor-cache
git fetch origin dev && git rebase origin/dev    # in case dev advanced
./tests/run-all.sh                                # full sanity check
gh pr create --base dev --title "feat(doctor): cache GitHub token validation"
```

After PR merges, in main repo:
```bash
git worktree remove ~/.git-worktrees/flow-cli/wire-doctor-cache
```

## Risks

1. **Test isolation** — production cache lives in `~/.flow/cache/doctor/`, which is shared with the developer's actual flow setup. If tests don't override `DOCTOR_CACHE_DIR`, they'll pollute it. Mitigation: setup() must `export DOCTOR_CACHE_DIR=$TEST_ROOT/.flow/cache/doctor` before sourcing the plugin.
2. **Cache corruption** — if a cache file is truncated or has unexpected format, `_doctor_cache_token_get` should fail cleanly and fall through to curl. Read lines 289–354 to verify; if not, add a try/catch-equivalent (set -e off temporarily, check return code).
3. **`--fix` path silent breakage** — if `--fix` re-runs validation after installing a new token, ensure the new token's fingerprint generates a different cache key. With fingerprint-based keys this is automatic; with static keys, the `--fix` flow needs an explicit clear.
4. **TTL too short causing thrash** — if TTL is set to ≤60s, repeated `flow doctor` in a CI loop will still curl. 3600s is recommended.

## STOP Condition (Per flow-cli CLAUDE.md Step 3)

After committing this ORCHESTRATE file:
- **STOP.** Do not begin implementation in this session.
- The implementing user must `cd ~/.git-worktrees/flow-cli/wire-doctor-cache` and start a fresh `claude` session.
- That session will read this file as its starting context, then begin Step 1.
