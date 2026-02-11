# Email Cache Management — Brainstorm

**Generated:** 2026-02-11
**Context:** flow-cli em dispatcher, `lib/em-cache.zsh`
**Branch:** `feature/em-dispatcher`

---

## Problem Statement

The em email cache currently:
1. Grows unbounded — no max size cap
2. Only prunes expired entries on *read* (lazy TTL) — never sweeps
3. Lives in `.flow/email-cache/` (project-local) or `$FLOW_DATA_DIR/email-cache/` (global)
4. Could be wiped by macOS cache cleaners (Mole, CleanMyMac, etc.)

---

## Research Findings

### Current Cache Location Analysis

| Location | When Used | Risk |
|----------|-----------|------|
| `$PROJECT_ROOT/.flow/email-cache/` | Inside a flow project | Safe from Mole (project-local, not in system cache paths) |
| `$FLOW_DATA_DIR/email-cache/` | No project root detected | Depends on `FLOW_DATA_DIR` value |
| `$HOME/.local/share/flow-cli/email-cache/` | Fallback (from config-validator pattern) | Safe from Mole |

### Mole App Risk Assessment

Mole ([tw93/Mole](https://github.com/tw93/Mole)) targets:
- `~/Library/Caches/*` — macOS app caches
- `~/Library/Logs/*` — system logs
- Browser caches (Chrome, Safari, Firefox)
- Developer tool caches (Xcode, npm, Node.js)
- Empty directories in `~/Library/Application Support/`

**Mole does NOT target:**
- `~/.local/share/` — XDG data directory
- `~/.flow/` — project-local hidden directories
- `$PROJECT_ROOT/.flow/` — project-local directories

**Verdict: Current locations are safe from Mole.** The risk would only exist if:
- Cache was placed in `~/Library/Caches/flow-cli/` (macOS convention)
- Cache was placed in `~/.cache/flow-cli/` (XDG cache convention)

Neither of these is used. The current `$FLOW_DATA_DIR` (`~/.local/share/flow-cli`) and project-local `.flow/` locations are both in the XDG *data* directory, not *cache* directory — which is correct since Mole and similar tools target cache dirs, not data dirs.

### XDG Best Practices for CLI Cache

| Directory | Purpose | Safe to Delete? | Convention |
|-----------|---------|-----------------|------------|
| `$XDG_CACHE_HOME` (`~/.cache/`) | Expendable cached data | Yes — apps must handle loss | For truly disposable data |
| `$XDG_DATA_HOME` (`~/.local/share/`) | Persistent application data | No — loss means data loss | For data worth keeping |
| `$XDG_CONFIG_HOME` (`~/.config/`) | Configuration | No — user settings | For config files |
| Project-local (`.flow/`) | Per-project state | No — project-specific | For project-scoped state |

**Key insight:** If cache is truly expendable (can be regenerated), it *should* go in `$XDG_CACHE_HOME`. If loss would degrade UX but not lose data, it belongs in `$XDG_DATA_HOME`.

For em email cache:
- **Summaries, classifications** — regenerable via AI (expendable, but costs API tokens)
- **Drafts** — user-composed content (NOT expendable)
- **Unread counts** — trivially regenerable (expendable)

---

## Options

### Option A: Keep Current Location (Recommended)

**Effort:** None
**Pros:** Already safe from Mole, project-local is intuitive, matches flow-cli patterns
**Cons:** Doesn't follow XDG cache convention (minor)

Current locations:
- `.flow/email-cache/` (project-local) — safe from cleaners
- `$FLOW_DATA_DIR/email-cache/` (global) — safe from cleaners

**Just add:** `prune` subcommand + max size cap.

### Option B: Move to XDG Cache Home

**Effort:** Small (change `_em_cache_dir()`)
**Pros:** Follows XDG convention, cleaners can reclaim space automatically
**Cons:** Mole/CleanMyMac *would* wipe it, losing AI summaries (costs API tokens to regenerate)

```
$XDG_CACHE_HOME/flow-cli/email/  (defaults to ~/.cache/flow-cli/email/)
```

### Option C: Split by Expendability

**Effort:** Medium
**Pros:** Correct semantics — drafts are data, summaries are cache
**Cons:** Complexity, two locations

```
$XDG_CACHE_HOME/flow-cli/email/   → summaries, classifications, unread (expendable)
$FLOW_DATA_DIR/email-drafts/       → drafts, user-composed content (keep)
```

---

## Recommended Path

**Option A + hardening.** The current location is already Mole-safe. Add these missing pieces:

### 1. `em cache prune` — Sweep Expired Entries

Remove stale files without clearing everything. Run automatically on `em cache stats`.

### 2. Max Size Cap

`FLOW_EMAIL_CACHE_MAX_MB=50` — when exceeded, delete oldest files first (LRU eviction).

### 3. Enhanced `em cache stats`

Show expired count, total size, oldest entry, and whether cap is exceeded.

### 4. Auto-Prune on Startup

When `em` is first invoked in a session, background-prune expired entries.

---

## Quick Wins

1. Add `em cache prune` subcommand (~20 lines)
2. Add `FLOW_EMAIL_CACHE_MAX_MB` cap with LRU eviction (~25 lines)
3. Enhance `em cache stats` with age/expiry info (~10 lines)

## Next Steps

1. [ ] Implement prune + cap in `lib/em-cache.zsh`
2. [ ] Add `prune` to `_em_cache_cmd()` dispatcher
3. [ ] Add tests for prune and cap behavior
4. [ ] Update refcard with new subcommand

---

## Sources

- [tw93/Mole](https://github.com/tw93/Mole) — macOS cache cleaner
- [Mole issue #234](https://github.com/tw93/Mole/issues/234) — paths covered by cleanup
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir/latest/)
- [XDG Base Directory - ArchWiki](https://wiki.archlinux.org/title/XDG_Base_Directory)
- [macOS CLI XDG conventions](https://atmos.tools/changelog/macos-xdg-cli-conventions)
