# BRAINSTORM: Scholar Config Sync

**Date:** 2026-02-26
**Depth:** max | **Focus:** feat | **Action:** save
**Issue:** #299 (Scholar Config Sync)
**Prerequisite:** #298 (teach migrate-config) — Complete

---

## Key Discovery

Scholar already has `--config PATH` fully implemented on all 9 `/teaching:*` commands (Scholar v2.2.0+). The config loader (`loader.js`), 4-layer style system (`style-loader.js`), lesson plan loader, and `/teaching:config` command with scaffold/show/validate/diff/trace are all operational.

**The only missing piece is flow-cli auto-injecting `--config` when calling Scholar.**

---

## Implementation Status

| Component | Scholar Plugin | flow-cli |
|-----------|---------------|----------|
| `--config PATH` flag | Done (all 9 commands) | NOT injected |
| Config YAML reader | Done (`loader.js`) | Done (`config-validator.zsh`) |
| 4-layer style system | Done (`style-loader.js`) | N/A (Scholar owns) |
| Lesson plan loader | Done (`.flow/lesson-plans.yml`) | Done (`teach migrate-config`) |
| Hash change detection | N/A | Built, unwired |
| `/teaching:config` cmd | Done (5 subcommands) | N/A |
| Config path discovery | Done (`findConfigFile()`) | Done (`_teach_find_config()`) |

---

## Quick Wins (< 30 min each)

1. **Wire `--config` injection** — In `_teach_build_command()` or command assembly block (~lines 2153-2201 of teach-dispatcher.zsh), call `_teach_find_config` and append `--config "$config_path"` to `scholar_cmd`
2. **Wire hash change detection** — In `_teach_preflight()`, call `_flow_config_changed()` and show warning if config changed since last Scholar run
3. **Add `teach config sync` alias** — Map to `/teaching:config show` for quick status check

## Medium Effort (1-2 hours)

4. **`teach config check`** — Wrap `/teaching:config validate --strict` with flow-cli colored output
5. **`teach config diff`** — Wrap `/teaching:config diff` to show flow-cli vs Scholar prompt differences
6. **Deprecation warning for legacy path** — When `.claude/teaching-style.local.md` exists alongside `.flow/teach-config.yml`, warn

## Long-term (Future sessions)

7. **`teach config scaffold`** — Wrap `/teaching:config scaffold` with flow-cli UX
8. **`teach config trace`** — Surface generation provenance in flow-cli
9. **Config change auto-invalidation** — Auto-trigger Scholar cache refresh on config change

---

## Decisions (from expert questions)

| Decision | Choice |
|----------|--------|
| Scope | Both sides (flow-cli + Scholar) |
| Canonical config path | `.flow/teach-config.yml` (not `config-teach.yml`) |
| Legacy `.claude/teaching-style.local.md` | Deprecate with fallback |
| Sync trigger | Auto on teach commands (inject --config automatically) |
| Config depth | Full context (Scholar reads course, semester, grading, style, macros) |
| Change detection | Warn on stale config |
| Sync direction | One-way: flow-cli → Scholar (flow-cli owns the file) |
| Lesson plans | Include in this spec |

---

## Recommended Path

Start with Quick Win #1 (wire --config injection). This is the entire core of issue #299 — approximately a 10-line change in `teach-dispatcher.zsh`. Everything else is enhancement.
