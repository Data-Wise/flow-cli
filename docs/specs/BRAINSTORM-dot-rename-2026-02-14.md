# BRAINSTORM: Rename `dot` Dispatcher

**Generated:** 2026-02-14
**Context:** flow-cli v7.0.2 → v7.1.0
**Mode:** deep + feature + save
**Spec:** SPEC-dot-rename-split-2026-02-14.md

---

## The Problem

Graphviz installs `dot` at `/opt/homebrew/bin/dot` (v14.1.2). Flow-cli's `dot()` shell function shadows it, causing:

1. **Tab completion confusion** — `dot<TAB>` shows flow-cli subcommands, not Graphviz options
2. **`which dot` mismatch** — returns Graphviz binary, but shell actually runs flow-cli's function
3. **Scripts break** — any script calling `dot` expecting Graphviz gets flow-cli instead
4. **Cognitive overhead** — "did I mean dotfiles or diagrams?"

---

## Decision: `dots`

**Why `dots` over alternatives:**

| Name | Pros | Cons | Verdict |
|------|------|------|---------|
| `dots` | Minimal mental shift, plural of dot, no collisions | Could imply "multiple dots" | **Winner** |
| `df` | Short like g/wt/cc, matches convention | Collides with `df` (disk free!) | Fatal collision |
| `cfg` | Broader scope | Doesn't evoke "dotfiles" | Too generic |
| `stow` | GNU Stow heritage | Collides with actual `stow` | Fatal collision |
| `dtf` | Unique, "dotfiles" abbreviation | Ugly, hard to remember | No |
| `chezmoi` | Direct tool name | Too long, not all users use chezmoi | No |

`dots` wins: familiar, unique, 1 character longer, zero collisions.

---

## Decision: 3-Way Split

The 4,395-line monolith has natural fault lines:

| Dispatcher | Responsibility | Lines | % |
|---|---|---|---|
| `dots` | Dotfile management (chezmoi) | ~1,400 | 32% |
| `sec` | Secret management (Keychain + Bitwarden) | ~1,800 | 41% |
| `tok` | Token management (GitHub, NPM, PyPI) | ~1,300 | 30% |

**Why split now:**
- Secrets and tokens are independent of dotfile syncing
- `sec` and `tok` are useful even without chezmoi
- Each dispatcher becomes focused and testable
- Help output is cleaner per-dispatcher

---

## Quick Wins (within the v7.1.0 release)

1. **Cross-reference help** — `dots help` shows "See also: sec, tok"
2. **Session-scoped Keychain cache** — avoid repeated `security` lookups in `sec`
3. **Cleaner doctor** — each dispatcher's doctor is focused, flow doctor aggregates
4. **Simpler chezmoi init** — reduce wizard questions in `dots init`

---

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Missed `_dot_` rename | High | Tests fail | Grep + sed, then run full suite |
| Breaking user muscle memory | Medium | UX friction | Clean break is fast to relearn (1 char) |
| Shared helper confusion | Medium | Runtime errors | Clear ownership of helpers |
| Doc staleness | Medium | User confusion | Update docs in same PR |

---

## Not Doing

- No deprecated `dot()` alias (clean break)
- No new dependencies
- No Keychain service name migration
- No Bitwarden item renaming
- No new test framework

---

## Recommended Path

→ Single worktree, 7 increments, one PR to dev, one release as v7.1.0.
→ Start with Increment 1 (file split) — it's the hardest and most informative.
→ Run tests after every increment to catch regressions early.

---

## Next Steps

1. [ ] Review and approve spec: `SPEC-dot-rename-split-2026-02-14.md`
2. [ ] Create worktree: `git worktree add ~/.git-worktrees/flow-cli/feature-dot-rename -b feature/dot-rename dev`
3. [ ] Start new Claude session in worktree
4. [ ] Execute Increment 1 (core file split)
