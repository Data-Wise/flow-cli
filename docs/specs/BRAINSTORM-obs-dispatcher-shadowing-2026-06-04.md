# 🧠 BRAINSTORM: obs dispatcher shadowing fix

**Date:** 2026-06-04 · **Depth:** default · **Focus:** architecture / shell-integration
**Pairs with:** `SPEC-obs-dispatcher-shadowing-2026-06-04.md`
**Converged approach:** **B + A** (general binary-precedence guard **and** delete the dead obs dispatcher)

---

## TL;DR

The spec's *direction* is right (delete `obs` dispatcher + add a general guard), but its **Option B code sketch is broken** and would not actually generalize. The guard derives the command name from the **filename**, but every real dispatcher file is named `X-dispatcher.zsh` while the command it defines is `X`. `obs.zsh` is the lone bare-named file — so the sketch works *only for obs by accident* and protects nothing else.

Fixing that naming/identity gap is the real design decision hiding inside this spec.

---

## 🚨 Critical Finding — Option B's sketch is a happy accident

The spec sketch:

```zsh
local name="${${disp_file:t}:r}"   # filename without dir/ext
command -v "$name" ...             # is there a binary with that name?
```

Evaluated against the actual files:

| File on disk | `name` derived | Command actually defined | `command -v $name` | Guard behavior |
|---|---|---|---|---|
| `obs.zsh` | `obs` | `obs()` | `/opt/homebrew/bin/obs` ✅ | **Skips — correct** |
| `g-dispatcher.zsh` | `g-dispatcher` | `g()` | (nothing) | Sources — but for the wrong reason |
| `mcp-dispatcher.zsh` | `mcp-dispatcher` | `mcp()` | (nothing) | Sources |
| `r-dispatcher.zsh` | `r-dispatcher` | `r()` | (nothing) | Sources |

**Consequence:** the guard never tests the *real* command names (`g`, `mcp`, `r`, …). It only ever tests `obs` because `obs.zsh` is uniquely bare-named. If someone later adds `node-dispatcher.zsh` defining `node()`, the guard checks `command -v node-dispatcher` (nothing) → sources it → **re-shadows the real `node` binary.** The "general hazard" the spec set out to kill is still wide open.

So Option B as written = Option A with extra steps.

---

## The real fork: how does the guard learn a file's command name?

To make B *genuinely* general, the loader must map a dispatcher file → the command(s) it defines. Four ways:

| Way | Mechanism | Pros | Cons |
|---|---|---|---|
| **B1. Strip `-dispatcher` suffix** | `name="${${disp_file:t}:r}"; name="${name%-dispatcher}"` | Tiny diff; matches the existing convention | Relies on naming discipline; `obs.zsh` (no suffix) is the exception — but it's being deleted, so post-delete every file follows the convention |
| **B2. Explicit registry** | A `typeset -A FLOW_DISPATCHER_CMDS=( g-dispatcher g  mcp-dispatcher mcp … )` | Unambiguous; supports multi-command files | Manual upkeep; another thing to forget when adding a dispatcher |
| **B3. Post-source self-check** | Source the file, then for each function it defined, if a same-named **external binary** also exists, `unfunction` it (unless forced) | Uses the *actual* command names — zero naming assumptions | Heavier; must diff `${(k)functions}` before/after; ordering vs. `disable r` |
| **B4. Per-dispatcher opt-in header** | Each file declares `# flow-command: g` and loader greps it | Self-documenting, co-located | Parsing comments at load time; perf |

**Recommendation: B1** (strip the suffix). After Option A deletes `obs.zsh`, **every remaining file follows `X-dispatcher.zsh`**, so suffix-stripping yields the true command name for all of them — making the guard genuinely general with a one-line change. Keep `FLOW_FORCE_DISPATCHER_<NAME>=1` as the escape hatch. Add a **convention test** (filename must be `<cmd>-dispatcher.zsh`) so B1 stays valid as dispatchers are added.

---

## Edge cases pressure-test

| Case | Risk | Handling |
|---|---|---|
| **`r` is a builtin** (`disable r` at line 72) | Guard might mis-handle builtins | Guard checks **external binaries only** (`command -v` of a *file*, not a builtin). `r` has no `/path` binary → not skipped. ✅ Already noted in spec. |
| **Symlink `zsh/functions/obs.zsh`** → obsidian-cli-ops source | Dangling/legacy after delete | Loader never sources `zsh/functions/`. Still: **delete the symlink** as part of A so it doesn't mislead. |
| **`obs.1` man page** | Drift vs. man-page-sync guard | Man-page spec lists `obs` as a flow dispatcher. Remove `obs.1` + the inventory row, or the sync guard fails CI. Coordinate the two specs in one PR. |
| **Test env has no `obs` binary** | `type obs` assertion flips | Test must **mock an `obs` on PATH** (stub in a temp dir prepended to `$PATH`) before asserting the guard skips it. Otherwise the guard correctly sources nothing-to-skip and the assert is vacuous. |
| **User already has `unfunction obs` in zshrc** | Now redundant/confusing | Acceptance criterion already says no workaround needed; note in release notes so the user can remove it. |
| **`FLOW_DEBUG` log on skip** | Noise | Gate behind `$FLOW_DEBUG` (spec already does). |
| **Forced re-enable** (`FLOW_FORCE_DISPATCHER_OBS=1`) but obs deleted | Dead env var | Harmless; document only if obs is kept. With A, the var simply has no file to act on. |

---

## Quick Wins (< 30 min each)

1. ⚡ **Delete `lib/dispatchers/obs.zsh`** — dead code that can't run (wants a `python/obs_cli.py` flow-cli never ships).
2. ⚡ **Delete the `zsh/functions/obs.zsh` symlink** — unsourced, points into a sibling repo, pure confusion.
3. ⚡ **Drop `obs` from the loader comment** at `flow.plugin.zsh:24` (`# Load v, g, mcp, obs dispatchers`).

## Medium Effort (1–2 hours)

4. □ **Implement guard B1** — suffix-strip + external-binary check + `FLOW_FORCE_DISPATCHER_<NAME>` escape hatch, with `$FLOW_DEBUG` skip log.
5. □ **Convention guard test** — assert every `lib/dispatchers/*.zsh` is named `<cmd>-dispatcher.zsh` (keeps B1 honest).
6. □ **Shadow regression test** — stub an `obs` binary on `$PATH`, source the plugin, assert `type obs` is a *file*, not a function; assert the guard sources `g`/`mcp`/`r` normally.
7. □ **Man-page + inventory sync** — remove `obs.1` and the `obs` row; satisfy `test-manpage-version-sync.zsh` in the same PR.

## Long-term (future)

8. □ Consider a tiny **dispatcher manifest** (B2) only if multi-command dispatchers or non-conventional names ever appear. Not needed today.

---

## Recommended Path

→ **Single feature worktree, one PR, in this order:** (A) delete obs dispatcher + symlink + man page/inventory → (B1) add the suffix-stripping guard → tests (convention + shadow regression) → coordinate the man-page-sync spec so CI stays green.

The decisive correction vs. the current spec: **replace the Option B sketch with B1 (suffix-strip)** so the guard keys on the true command name. Without that, the "general guard" protects exactly one command (`obs`) and reopens the hazard for the next collision.

---

## Open Questions

1. Keep the `FLOW_FORCE_DISPATCHER_<NAME>` escape hatch even though obs is deleted? (Recommend **yes** — it's the only override for the *general* guard.)
2. Should the convention test be a hard CI gate or advisory? (Recommend **hard** — it's the invariant B1 depends on.)
3. Any other installed binaries that collide with a *future* planned dispatcher name? (Audit `command -v` for the dispatcher roadmap before shipping.)
