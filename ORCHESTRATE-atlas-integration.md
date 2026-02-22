# ORCHESTRATE: Atlas Integration Update

> **Feature:** feature/atlas-integration
> **Base:** dev (bc0df546)
> **Spec:** docs/specs/SPEC-atlas-integration-update-2026-02-22.md
> **Brainstorm:** BRAINSTORM-atlas-plugin-update-2026-02-22.md
> **Estimated:** ~6 hours across 2-3 sessions

---

## Context

flow-cli has an Atlas bridge (`lib/atlas-bridge.zsh`) that exposes only 6 of 43 Atlas CLI commands. The help browser lists only 8 of 15 dispatchers. There is no API contract. Atlas help doesn't follow flow-cli conventions.

**Key decision:** Enhanced bridge (not dispatcher). Atlas owns its commands, flow-cli coordinates via `at()` passthrough with flow-cli-styled help and graceful fallbacks.

**Performance model:** Hot path (< 10ms, ZSH-native) for session/catch/crumb. Warm path (< 500ms, Atlas CLI) for stats/plan/park/dash.

---

## Increments

### Increment 1: Fix Help Browser (30 min)

**Goal:** All 15 dispatchers + `at` visible in help browser.

**Files to modify:**
- `lib/help-browser.zsh`

**Tasks:**
1. Add 7 missing dispatchers to `commands` array (line ~93-137):
   ```
   "dots:Dotfile management (chezmoi sync, diff, edit)"
   "sec:Secret management (macOS Keychain, Bitwarden)"
   "tok:Token management (create, rotate, expire)"
   "teach:Teaching workflow (analyze, deploy, exam, plan)"
   "prompt:Prompt engine switcher (set, show, compare)"
   "v:Vibe coding mode (start, stop, status)"
   "em:Email management (himalaya, 31 commands)"
   "at:Atlas CLI (stats, plan, park, dash)"
   ```

2. Fix dispatcher regex in `_flow_show_help_preview()` (line ~36):
   ```zsh
   # Before:
   if [[ "$cmd" =~ ^(g|cc|wt|mcp|r|qu|obs|tm)$ ]]; then
   # After:
   if [[ "$cmd" =~ ^(g|cc|wt|mcp|r|qu|obs|tm|dots|sec|tok|teach|prompt|v|em|at)$ ]]; then
   ```

3. Fix same regex on line ~177 (full help display):
   ```zsh
   # Before:
   if [[ "$cmd" =~ ^(g|cc|wt|mcp|r|qu|obs|tm)$ ]]; then
   # After:
   if [[ "$cmd" =~ ^(g|cc|wt|mcp|r|qu|obs|tm|dots|sec|tok|teach|prompt|v|em|at)$ ]]; then
   ```

**Verify:**
- `source flow.plugin.zsh` loads without error
- All 16 entries appear in help browser list
- `_flow_show_help_preview "dots"` shows dots help
- `_flow_show_help_preview "at"` shows at help (after Increment 2)

**Commit:** `fix: add all 15 dispatchers + at to help browser`

---

### Increment 2: Add `_at_help()` + Enhance `at()` (1.5 hours)

**Goal:** `at help` shows flow-cli-styled help page. `at` handles new subcommands with helpful fallbacks.

**Files to modify:**
- `lib/atlas-bridge.zsh`

**Tasks:**

1. Add `_at_help()` function (after the `at()` function, ~line 950):
   - Box header: `╭── at - Atlas Project Intelligence ──╮`
   - MOST COMMON section: stats, plan, park, unpark, dash
   - QUICK EXAMPLES section: real `$ at ...` examples
   - Grouped commands: SESSION, CAPTURE, CONTEXT, PROJECT
   - Footer: Atlas version + "at = atlas shortcut"
   - Use `$_C_BOLD`, `$_C_CYAN`, `$_C_GREEN`, `$_C_YELLOW`, `$_C_DIM`, `$_C_NC` color vars
   - Reference: `lib/dispatchers/g-dispatcher.zsh` `_g_help()` for exact pattern

2. Enhance `at()` function to handle new subcommands:
   ```zsh
   at() {
     case "$1" in
       help|--help|-h) _at_help ;;
       *)
         if _flow_has_atlas; then
           atlas "$@"
         else
           case "$1" in
             catch|c)   shift; _flow_catch "$@" ;;
             inbox|i)   _flow_inbox ;;
             where|w)   shift; _flow_where "$@" ;;
             crumb|b)   shift; _flow_crumb "$@" ;;
             stats|plan|park|unpark|parked|dash|dashboard|focus|triage|trail)
               _flow_log_error "'at $1' requires Atlas CLI"
               echo "  Install: ${_C_CYAN}npm i -g @data-wise/atlas${_C_NC}"
               echo "  Or:      ${_C_CYAN}brew install data-wise/tap/atlas${_C_NC}"
               ;;
             *)
               _flow_log_error "Atlas not installed"
               echo "  Available without Atlas: catch, inbox, where, crumb"
               echo "  Install: ${_C_CYAN}npm i -g @data-wise/atlas${_C_NC}"
               echo ""
               echo "  Run ${_C_CYAN}at help${_C_NC} for all commands"
               ;;
           esac
         fi
         ;;
     esac
   }
   ```

**Verify:**
- `at help` renders styled help page
- `at stats` calls `atlas stats` (if installed)
- Without Atlas: `at stats` shows install message
- `at catch "test"` still works as before (fallback)
- `source flow.plugin.zsh` loads without error

**Commit:** `feat: add _at_help() and enhance at() with subcommand handling`

---

### Increment 3: API Contract Document (1 hour)

**Goal:** Formal contract between flow-cli and Atlas.

**Files to create:**
- `docs/ATLAS-CONTRACT.md`

**Tasks:**

1. Create `docs/ATLAS-CONTRACT.md` with:
   - Version compatibility table (flow-cli v7.4.x ↔ Atlas v0.9.x)
   - Required commands table (what flow-cli depends on)
   - Output format specifications (names, json, table, shell)
   - Exit code contract (0=success, 1=error, 2=not found)
   - Breaking change policy
   - Help format convention (flow-cli wrapper pattern)

2. Reference the contract from:
   - `docs/reference/MASTER-ARCHITECTURE.md` (add Atlas section)
   - `CLAUDE.md` (add contract reference)

**Verify:**
- Contract covers all 6 currently-bridged commands
- Contract covers all new warm-path commands (stats, plan, park, etc.)
- Output format specs are precise enough for tests

**Commit:** `docs: add Atlas API contract specification`

---

### Increment 4: Contract Integration Tests (1.5 hours)

**Goal:** Tests that verify Atlas CLI contract compliance.

**Files to create:**
- `tests/test-atlas-contract.zsh`

**Tasks:**

1. Create test file with contract verification:
   - Test `atlas -v` returns version string
   - Test `atlas project list --format=names` returns plain text (no JSON)
   - Test `atlas session start/end` exit codes
   - Test `atlas catch` confirmation output
   - Test `atlas where` context output
   - Test each warm-path command exists and responds
   - Skip all tests gracefully when Atlas not installed

2. Follow `tests/test-framework.zsh` patterns:
   - `test_suite_start "Atlas Contract Tests"`
   - `test_case` / `test_pass` / `test_fail` / `test_skip`
   - `assert_equals`, `assert_contains`, `assert_not_contains`
   - Cleanup with trap

3. Add to `tests/run-all.sh` test discovery

**Verify:**
- Tests pass when Atlas is installed
- Tests skip gracefully when Atlas is not installed
- `./tests/run-all.sh` still passes (45/45 or 46/46)

**Commit:** `test: add Atlas API contract integration tests`

---

### Increment 5: Enhanced Doctor + Reference Docs (1 hour)

**Goal:** `flow doctor` shows rich Atlas status. Reference docs updated.

**Files to modify:**
- `commands/doctor.zsh`
- `docs/help/QUICK-REFERENCE.md`
- `docs/reference/MASTER-DISPATCHER-GUIDE.md`

**Tasks:**

1. Enhance `flow doctor` Atlas section (~line 347):
   ```
   ## Atlas Integration
     ✓ atlas installed (v0.9.0)
     ✓ atlas connected (filesystem backend)
     ✓ project list works (12 projects)
     ○ atlas MCP server (optional, not running)
   ```
   - Show Atlas version
   - Show storage backend
   - Show project count
   - Check MCP server status (optional)

2. Update `docs/help/QUICK-REFERENCE.md`:
   - Add `at` to dispatcher list
   - Add `at` examples to quick reference

3. Update `docs/reference/MASTER-DISPATCHER-GUIDE.md`:
   - Add `at` section with full command reference
   - Cross-reference to `docs/ATLAS-CONTRACT.md`

**Verify:**
- `flow doctor` shows enhanced Atlas section
- QUICK-REFERENCE lists `at` with examples
- MASTER-DISPATCHER-GUIDE has `at` section

**Commit:** `docs: update doctor, quick-reference, and dispatcher guide for Atlas`

---

### Increment 6: Final Verification + Cleanup (30 min)

**Tasks:**
1. Run full test suite: `./tests/run-all.sh`
2. Source plugin: `source flow.plugin.zsh` (verify no errors)
3. Test `at help`, `at stats`, `at plan` manually
4. Test help browser shows all 16 entries
5. Test `flow doctor` Atlas section
6. Clean up any ORCHESTRATE files
7. Final commit if needed

**Verify:**
- All tests pass (45/45 or 46/46)
- Plugin loads cleanly
- No regressions in existing functionality

**Final:** Create PR `gh pr create --base dev`

---

## File Change Summary

| File | Action | Increment |
|------|--------|-----------|
| `lib/help-browser.zsh` | MODIFY | 1 |
| `lib/atlas-bridge.zsh` | MODIFY | 2 |
| `docs/ATLAS-CONTRACT.md` | CREATE | 3 |
| `tests/test-atlas-contract.zsh` | CREATE | 4 |
| `commands/doctor.zsh` | MODIFY | 5 |
| `docs/help/QUICK-REFERENCE.md` | MODIFY | 5 |
| `docs/reference/MASTER-DISPATCHER-GUIDE.md` | MODIFY | 5 |
| `docs/reference/MASTER-ARCHITECTURE.md` | MODIFY | 3 |
| `CLAUDE.md` | MODIFY | 3 |

---

## Dependencies Between Increments

```
Increment 1 (help browser) ─── independent
Increment 2 (at help + at()) ── depends on understanding Increment 1 patterns
Increment 3 (contract) ──────── independent
Increment 4 (contract tests) ── depends on Increment 3 (contract spec)
Increment 5 (doctor + docs) ─── depends on Increment 2 (at commands exist)
Increment 6 (verification) ──── depends on all above
```

**Recommended order:** 1 → 2 → 3 → 4 → 5 → 6

Can parallelize: Increment 1 + 3 (help browser + contract doc)

---

## Key References

- **Spec:** `docs/specs/SPEC-atlas-integration-update-2026-02-22.md`
- **Brainstorm:** `BRAINSTORM-atlas-plugin-update-2026-02-22.md`
- **Help convention:** `docs/internal/conventions/adhd/HELP-PAGE-TEMPLATE.md`
- **Help example:** `lib/dispatchers/g-dispatcher.zsh` → `_g_help()`
- **Test framework:** `tests/test-framework.zsh`
- **Atlas CLAUDE.md:** `/Users/dt/projects/dev-tools/atlas/CLAUDE.md`
- **Atlas CLI entry:** `/Users/dt/projects/dev-tools/atlas/bin/atlas.js`
