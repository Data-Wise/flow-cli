# SPEC: flow-cli Restructure for Maintainability

**Status:** Draft  
**Date:** 2026-07-06  
**Target versions:** Planning now; implementation begins no earlier than v7.16.x  
**Author:** Claude Code / craft review  
**Related:** `SPEC-dot-rename-split-2026-02-14.md`, `docs/internal/conventions/code/ZSH-COMMANDS-HELP.md`, `CLAUDE.md`

---

## 1. Context & Current State

flow-cli is a pure-ZSH workflow plugin positioned as Layer 1 of the dev-tools stack: sub-10 ms commands, zero runtime dependencies, 14 active dispatchers plus the `at` Atlas bridge. It shipped v7.15.0 on 2026-07-02.

### 1.1 Scale snapshot

| Area | Count | Notes |
|------|-------|-------|
| Total tracked files | ~1,828 | Includes `site/`, `docs/demos/`, `node_modules/`, `.archive/` |
| Source `.zsh` files | ~180 | `lib/` 100, `commands/` 33, `tests/` 231 `.zsh` |
| Active dispatchers | 14 | `g`, `mcp`, `qu`, `r`, `cc`, `tm`, `wt`, `dots`, `sec`, `tok`, `teach`, `prompt`, `v`, `em` |
| Man pages | 23 | Version-sync guard enforces `.TH` = `FLOW_VERSION` |
| Completions | 16 | Auto-discovered via fpath |
| Docs files | 534 | 66 MB; includes generated `site/` and archived references |
| Spec files | 106 | Many historical; `_archive/` holds retired specs |
| Node dev footprint | 86 MB | `husky`, `lint-staged`, `prettier` only (not runtime) |
| CI gate | Full Test Suite | 75 registered runs in `run-all.sh`, blocking on `main` |

### 1.2 Hotspots

The following files exceed the project’s implicit complexity budget:

| File | Lines | Functions | Concern |
|------|-------|-----------|---------|
| `lib/dispatchers/teach-dispatcher.zsh` | 307 | 0 | Loader only; functions moved to `lib/dispatchers/teach/*.zsh` (Phase 1 complete) |
| `lib/dispatchers/teach/*.zsh` (combined) | 5,452 | 82 | Modular split; largest module is `teach-help.zsh` (~1,268 lines) |
| `lib/dispatchers/email-dispatcher.zsh` | 3,214 | 56 | Email subsystem (31 commands) is larger than most entire plugins |
| `commands/doctor.zsh` | 2,027 | 24 | Knows about every integration; grows with every new dispatcher |
| `lib/dotfile-helpers.zsh` | 1,832 | ~20 | Cross-cutting dotfile/secrets logic |
| `lib/plugin-loader.zsh` | 1,234 | 23 | Central loader; any extension mechanism lands here |
| `docs/reference/MASTER-API-REFERENCE.md` | 7,843 | — | Generated reference, stale risk |

---

## 2. Maintainability Risk Audit

### 2.1 Mega-dispatchers
`teach-dispatcher.zsh` and `email-dispatcher.zsh` together contain ~138 functions and 8,800 lines. A change to one email subcommand can force a full email test run; a change to `teach` can require updating the teaching guide, refcards, man page, completions, and 6+ test files.

### 2.2 Test surface
`tests/run-all.sh` invokes 75 suites with a 30 s default timeout (`test-doctor` needs 45 s). Full suite runtime is long enough that CI has a dedicated blocking job. Adding new dispatchers linearly increases this surface.

### 2.3 Documentation debt
534 docs files and 66 MB. A large fraction is generated `site/` output, archived references, and 106 specs. The doc-version sweep (`release.sh`) touches ~47 files per release, which is high friction.

### 2.4 Man-page namespace pressure
flow-cli already collided with the system `R.1` man page (APFS case-insensitive). Each new dispatcher increases collision risk with system or Homebrew formulae.

### 2.5 Cross-cutting integration in `doctor`
`doctor` must validate Atlas, Homebrew, GitHub tokens, email (IMAP), teaching config, etc. Every new domain adds a section to doctor, a man-page update, and tests.

### 2.6 Node.js for a "pure ZSH" plugin
86 MB of `node_modules` for formatting and lint-staged is acceptable for contributors but conflicts with the zero-dependency user promise. It also slows CI checkout.

---

## 3. Option A: Extract Dispatchers/Skills to Sibling dev-tools Repos

Move domain-heavy subsystems to the repos that already own those domains:

| flow-cli subsystem | Natural sibling home | Rationale |
|--------------------|----------------------|-----------|
| `teach` dispatcher + `teach-*` commands | `craft` | craft is the orchestration/teaching layer; already has docs and conventions for teaching workflow |
| `em` dispatcher + email helpers | `himalaya-mcp` or new `flow-cli-email` | Email is a full client; himalaya-mcp already exists as the bridge target |
| `qu`, `r` | `aiterm` | aiterm is the Quarto/R rich-viz layer; it has a `flow-integration/` directory |
| `cc`, `wt`, `g` | `craft` | These are Claude Code / git workflow tools adjacent to craft’s scope |
| `at` bridge | `atlas` | The contract (`ATLAS-CONTRACT.md`) is already bilateral; Atlas could ship the ZSH bridge |
| `tok` | `craft` or `homebrew-tap` | Token management is release/automation infrastructure |

### 3.1 Assumption audit

1. **Sibling repos want the maintenance burden.** craft and aiterm are larger projects; they may not want to own ZSH plugin surfaces.
2. **A shared library contract exists.** Today there is no packaged `flow-cli-lib`; every dispatcher imports `lib/core.zsh`, `lib/tui.zsh`, etc. directly.
3. **Users will install multiple plugins.** The current value proposition is "one plugin, instant commands."
4. **CI/test duplication is acceptable.** Each sibling repo would need its own ZSH test harness.

### 3.2 Gap analysis

- No shared ZSH library release artifact.
- No cross-repo version pinning or compatibility matrix.
- No installer that composes `flow-cli` + sibling plugins.
- Sibling repos use different languages/architectures (craft is Claude Code plugin + JS; aiterm is Python; atlas is Node). Forcing ZSH plugin maintenance onto them is a paradigm mismatch.

### 3.3 Verdict
Option A is attractive for the two largest subsystems (`teach`, `em`) because they have natural homes, but wholesale decomposition forces non-ZSH repos to maintain ZSH surfaces. **Recommended only as a follow-up extraction for `teach` and `em`, not as the primary strategy.**

---

## 4. Option B: Split flow-cli into Core + Extensions Repos

Create two repositories under the Data-Wise org:

1. **`flow-cli-core`** — instant workflow commands and the shared runtime.
2. **`flow-cli-extensions`** — the 14 dispatchers and Atlas bridge.

### 4.1 Proposed core boundary

`flow-cli-core` retains:

- `flow.plugin.zsh` entry point with optional extension loading
- `commands/`: `work`, `finish`, `hop`, `dash`, `agenda`, `catch`, `js`, `win`, `yay`, `goal`, `doctor` (framework only), `status`, `tutorial`, `setup`
- `lib/core.zsh`, `lib/tui.zsh`, `lib/project-detector.zsh`, `lib/git-helpers.zsh` (minimal), `lib/plugin-loader.zsh`, `lib/schedule.zsh`, `lib/date-parser.zsh`
- `completions/_flow`, `_work`, `_dash`, `_agenda`
- Tests for core commands only

### 4.2 Proposed extensions boundary

`flow-cli-extensions` contains:

- `lib/dispatchers/*.zsh` (all 14)
- `commands/` that are dispatcher-specific: `claude.zsh`, `pick.zsh`, most of `doctor.zsh` sections, `sync.zsh`, `ai.zsh`, `alias.zsh`, `secret-tutorial.zsh`, etc.
- Man pages for dispatchers
- Completions for dispatchers
- Dispatcher-specific docs, tests, and E2E suites

### 4.3 Extension loading mechanism

Core ships a thin discovery contract:

```zsh
# flow-cli-core
export FLOW_EXTENSIONS_DIR="${FLOW_EXTENSIONS_DIR:-$HOME/.config/flow-cli/extensions}"
for ext in $FLOW_EXTENSIONS_DIR/*.plugin.zsh(N); do
  source "$ext"
done
```

`flow-cli-extensions` installs a single `flow-cli-extensions.plugin.zsh` into that directory (or a Homebrew path). This preserves the "one plugin install" user experience while decoupling release cycles.

### 4.4 Assumption audit

1. **A clean boundary can be drawn.** Some helpers (e.g., `lib/git-helpers.zsh`) are used by both core and dispatchers; they become shared libs in core.
2. **Users tolerate a two-repo install.** If both are Homebrew formulae, `brew install flow-cli flow-cli-extensions` is acceptable.
3. **Version compatibility is manageable.** Extensions declare a minimum core version; core warns on mismatch.
4. **Test harness stays in core.** Extensions repo sources core’s test framework via git subtree or shared action.

### 4.5 Gap analysis

- Need to refactor `doctor.zsh` into a plugin-health framework where extensions register checks.
- Need to extract shared helpers into a stable `lib/` surface.
- Need to split docs, man pages, and completions without breaking existing URLs/paths.
- CI duplication: both repos need the same ZSH environment.

### 4.6 Verdict
Option B gives flow-cli a maintainable ownership model without pushing ZSH maintenance onto non-ZSH sibling repos. It also creates a clear path for later Option A extractions. **This is the recommended strategic direction.**

---

## 5. Option Comparison

| Criterion | Option A: Sibling extraction | Option B: Core + extensions | Weight |
|-----------|------------------------------|------------------------------|--------|
| **Reduces flow-cli size** | High (extract big domains) | Medium (keeps all dispatchers under org) | High |
| **Preserves dev-tools stack layering** | Mixed (blurs Layer 1 / Layer 2) | Strong (Layer 1 stays Layer 1) | High |
| **Avoids paradigm mismatch** | Weak (ZSH plugin in JS/Python repos) | Strong (both repos are ZSH plugins) | High |
| **User install experience** | Poor (many plugins to install) | Good (two formulae, opt-in extensions) | Medium |
| **Release coordination** | Complex (N repos) | Moderate (2 repos + version contract) | Medium |
| **CI/test duplication** | High | Low-medium (shared harness) | Medium |
| **Backward compatibility** | Hard (commands move) | Manageable (core keeps commands, extensions ship separately) | High |
| **Time to value** | Slow (negotiate sibling ownership) | Fast (single org decision) | Medium |
| **Risk of abandonment** | Medium (sibling teams may deprioritize) | Low (same owner, same incentives) | High |

**Score:** Option B wins on 6 of 9 criteria, ties on none, and loses only on "reduces flow-cli size," where it still delivers meaningful reduction.

---

## 6. Recommendation

**Adopt Option B: split flow-cli into `flow-cli-core` and `flow-cli-extensions`, executed in three phases.**

The split solves the maintainability crisis without forcing non-ZSH sibling repos to own ZSH surfaces. It preserves the ADHD-friendly "install and go" promise and keeps release authority with the flow-cli maintainers.

The first extraction in Phase 2 can borrow from Option A: move `teach` and `em` to dedicated extension packages (`flow-cli-teach`, `flow-cli-email`) rather than dumping them into `craft` or `himalaya-mcp`. This gives the size benefits of Option A while keeping the ownership model clean.

---

## 7. Phased Migration / Extraction Plan

### Phase 1 — Internal refactoring (v7.16.x, no repo split)

1. Break `teach-dispatcher.zsh` into `lib/dispatchers/teach/*.zsh` modules by subcommand group (main, content, help, init-config, slides, style, backup, status, archive, map).
2. Break `email-dispatcher.zsh` into `lib/dispatchers/em-*.zsh` modules (send, organize, manage, ai).
3. Refactor `doctor.zsh` into a registration framework: `_doctor_register_check <category> <fn>`.
4. Extract shared helpers into stable `lib/core-*.zsh` modules with documented public functions.
5. Archive generated `site/` and stale specs to reduce docs friction.
6. Move node-only dev tooling to optional `package.json` scripts; document that contributors need Node.

**Exit criteria:** `teach-dispatcher.zsh` < 2,000 lines; `email-dispatcher.zsh` < 1,500 lines; full suite green.

### Phase 2 — First extractions (v8.0.0)

1. Create `Data-Wise/flow-cli-extensions` repo. Seed it with all 14 dispatchers and the `at` bridge.
2. Create `Data-Wise/flow-cli-core` repo. Seed it with core commands and shared libs.
3. Create `Data-Wise/flow-cli-teach` and `Data-Wise/flow-cli-email` repos for the two largest subsystems, importing their git history.
4. Update `flow-cli-extensions` to depend on `flow-cli-core` via Homebrew formula dependency.
5. Update Homebrew tap with new formulae and a transitional `flow-cli` formula that installs core + extensions for backward compatibility.

**Exit criteria:** Existing `brew install flow-cli` still works; `flow doctor` passes; full suite green across repos.

### Phase 3 — Mature extension ecosystem (v8.x)

1. Deprecate the transitional `flow-cli` formula in favor of `flow-cli-core` + `flow-cli-extensions`.
2. Introduce a lightweight extension registry (`flow extension install <name>`).
3. Consider merging `flow-cli-teach` into `craft` only if craft team accepts ZSH surface ownership.

---

## 8. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Breaking existing users** | High | Keep `flow-cli` as a meta-formula that installs core + extensions during transition |
| **Doctor fragmentation** | Medium | Register checks via `_doctor_register_check`; core iterates categories |
| **Test harness drift** | Medium | Core owns the test framework; extensions repo vendors it via git subtree |
| **Man-page path breaks** | Medium | Meta-formula keeps old man paths; new docs use `/core/` and `/extensions/` URLs |
| **Release coordination** | Medium | Use a release orchestration script that bumps both repos and verifies compatibility |
| **Man-page collisions persist** | Low-Medium | Fewer dispatchers per formula reduce collision surface |
| **Docs split hurts discoverability** | Medium | Keep unified docs site that pulls from both repos via mkdocs-monorepo or git submodules |

---

## 9. Rollback Triggers

Rollback to the monorepo should occur if any of the following happen before v8.0.0 GA:

1. Phase 1 refactoring cannot reduce `teach-dispatcher.zsh` below 2,000 lines without breaking tests.
2. A clean core/extensions boundary cannot be drawn for more than 3 shared helpers.
3. CI across the two repos cannot stay green for 2 consecutive weeks.
4. Homebrew meta-formula cannot preserve `brew install flow-cli` behavior.

---

## 10. Next-Action Checklist

Phase 1 (teach dispatcher split) — **DONE** in PR #490:

- [x] Review and approve this spec; update `.STATUS` Next Action to reflect Phase 1
- [x] Create worktree `feature/restructure-phase1` from `dev`
- [x] Write characterization tests for `teach-dispatcher.zsh` current behavior
- [x] Split `teach-dispatcher.zsh` into a loader + 10 modules (`lib/dispatchers/teach/*.zsh`)
- [x] Run `./tests/run-all.sh` after each refactor; full suite green (75/0/0/1)
- [x] Update active docs + `CLAUDE.md` to reflect the modular layout

Remaining Phase 1/2 work:

- [ ] Draft module split plan for `email-dispatcher.zsh` (target 3–4 modules)
- [ ] Implement `_doctor_register_check` framework with backward-compatible defaults
- [ ] Update `CLAUDE.md` architecture section to document the core/extensions boundary
- [ ] Schedule Phase 2 kickoff once Phase 1 metrics are met

---

## 11. Conclusion

flow-cli’s maintainability problem is real but solvable. A big-bang decomposition into sibling repos is risky because it forces non-ZSH projects to own ZSH surfaces. A phased core/extensions split keeps ownership aligned, preserves the user experience, and creates a migration path for the heaviest subsystems. The first milestone is purely internal refactoring in v7.16.x; repo splits follow only after the boundary is proven.
