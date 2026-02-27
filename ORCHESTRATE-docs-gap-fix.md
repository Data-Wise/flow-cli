# ORCHESTRATE: Documentation Gap Fix

> **Branch:** `feature/docs-gap-fix`
> **Base:** `dev` (30db9b78)
> **Worktree:** `~/.git-worktrees/flow-cli/feature-docs-gap-fix`
> **Created:** 2026-02-27

## Objective

Close documentation gaps identified in the pre-release gap analysis. Fix stale help files, version references, tutorial numbering, and missing dispatcher coverage to bring docs from B+ to A- before the v7.6.0 release.

## Scope

**In scope:** Fix existing docs, update stale content, add missing refcards/guides for underserved dispatchers.
**Out of scope:** New tutorials, nav restructuring, splitting MASTER-DISPATCHER-GUIDE (post-release).

---

## Phase Overview

| Phase | Task | Priority | Effort | Status |
|-------|------|----------|--------|--------|
| 1 | Fix stale help files (TROUBLESHOOTING.md, WORKFLOWS.md) | Critical | 30 min | |
| 2 | Fix tutorial 27 duplicate numbering | Critical | 15 min | |
| 3 | Update REFCARD-TEACH-DISPATCHER for v7.6.0 Scholar commands | High | 20 min | |
| 4 | Sweep stale version references (v5.x/v6.x) in 10 files | High | 45 min | |
| 5 | Add wt/dots/sec dispatcher coverage (refcards) | High | 1.5 hr | |
| 6 | Add g dispatcher refcard (most-used dispatcher) | Medium | 30 min | |
| 7 | Validate, commit, PR | Final | 15 min | |

---

## Phase 1: Fix Stale Help Files (Critical)

### Files
- `docs/help/TROUBLESHOOTING.md` — currently v5.17.0-dev, update to v7.6.0
- `docs/help/WORKFLOWS.md` — currently v5.17.0-dev, update to v7.6.0

### Tasks
1. Read both files fully
2. Update version references from v5.17.0-dev to v7.6.0
3. Add any missing v7.x features (em v2.0, Scholar config sync, help guards)
4. Update command examples if stale
5. Verify cross-references still valid

### Commit
```
docs: update help files to v7.6.0 (TROUBLESHOOTING, WORKFLOWS)
```

---

## Phase 2: Fix Tutorial Duplicate Numbering (Critical)

### Problem
Two files named `27-*.md`:
- `docs/tutorials/27-lesson-plan-management.md`
- `docs/tutorials/27-lint-quickstart.md`

### Tasks
1. Rename `27-lint-quickstart.md` to `28-lint-quickstart.md`
2. Update mkdocs.yml nav entry
3. Check for any internal cross-references pointing to `27-lint-quickstart.md`
4. Update any links found

### Commit
```
fix: rename duplicate tutorial 27 to 28 (lint-quickstart)
```

---

## Phase 3: Update REFCARD-TEACH-DISPATCHER for v7.6.0 (High)

### File
- `docs/reference/REFCARD-TEACH-DISPATCHER.md`

### Tasks
1. Read current refcard
2. Add v7.6.0 Scholar commands: `teach solution`, `teach sync`, `teach validate-r`
3. Add shortcuts: `sol`, `vr`
4. Add `teach config check/diff/show/scaffold` commands
5. Update version header to v7.6.0

### Commit
```
docs: add v7.6.0 Scholar commands to teach dispatcher refcard
```

---

## Phase 4: Sweep Stale Version References (High)

### Files with v5.x/v6.x References
1. `docs/guides/TEACHING-DATES-GUIDE.md` — v5.11.0, v5.12.0 ("Coming in v5.12.0")
2. `docs/guides/QUALITY-GATES.md` — v6.6.0, v6.7.0
3. `docs/guides/CONFIG-MANAGEMENT-WORKFLOW.md` — v3.x, v4.x, v5.0.0
4. `docs/guides/DOCTOR-TOKEN-USER-GUIDE.md` — v5.17.0 (Phase 1)
5. `docs/guides/DOT-WORKFLOW.md` — v5.5.0 (Keychain), v5.2.0
6. `docs/guides/DEVELOPER-GUIDE.md` — v5.10.0 examples
7. `docs/guides/QUARTO-WORKFLOW-PHASE-2-GUIDE.md` — v4.7.0+
8. `docs/guides/LINT-GUIDE.md` — v5.24.0+
9. `docs/guides/TEACHING-SYSTEM-ARCHITECTURE.md` — v5.4.1, v5.5.0
10. `docs/guides/SAFE-TESTING-v5.9.0.md` — v5.9.0

### Rules
- **DO update:** "Coming in vX.Y.Z" → "Added in vX.Y.Z" (feature shipped)
- **DO update:** Version baselines ("v5.24.0+" → "v7.0.0+") when feature still current
- **DO NOT update:** Historical changelog entries, "New in vX.Y.Z" sections describing past releases
- **DO NOT update:** `SAFE-TESTING-v5.9.0.md` filename (historical artifact)

### Tasks
1. Read each file, identify stale version strings
2. Categorize: update vs preserve (historical)
3. Apply updates
4. Grep to verify no unintended changes

### Commit
```
docs: update stale version references (v5.x/v6.x → v7.x)
```

---

## Phase 5: Add wt/dots/sec Dispatcher Refcards (High)

### Gap
wt, dots, sec dispatchers have zero dedicated docs (F grade). Create refcards for each.

### Template
Follow REFCARD-EMAIL-DISPATCHER.md structure (scaled down):
- Header with purpose/version
- Command table (subcommand | description | example)
- Common workflows (2-3)
- See also links

### Files to Create
1. `docs/reference/REFCARD-WORKTREE-DISPATCHER.md` (~100 lines)
   - Source: `lib/dispatchers/wt-dispatcher.zsh` for all subcommands
   - Commands: wt create, wt list, wt clean, wt cd, wt status, etc.

2. `docs/reference/REFCARD-DOTFILE-DISPATCHER.md` (~100 lines)
   - Source: `lib/dispatchers/dots-dispatcher.zsh`
   - Commands: dots status, dots sync, dots diff, dots edit, dots add, etc.

3. `docs/reference/REFCARD-SECRET-DISPATCHER.md` (~100 lines)
   - Source: `lib/dispatchers/sec-dispatcher.zsh`
   - Commands: sec get, sec set, sec list, sec delete, sec export, etc.

### Tasks
1. Read each dispatcher source file to extract all subcommands
2. Create refcard following template
3. Add each to mkdocs.yml nav (under Reference Cards)
4. Cross-reference from QUICK-REFERENCE.md

### Commit
```
docs: add refcards for wt, dots, sec dispatchers
```

---

## Phase 6: Add g Dispatcher Refcard (Medium)

### Gap
`g` (git) is the most-used dispatcher but has no refcard. Only covered in MASTER-DISPATCHER-GUIDE.

### File to Create
- `docs/reference/REFCARD-GIT-DISPATCHER.md` (~150 lines)
  - Source: `lib/dispatchers/g-dispatcher.zsh`
  - Commands: g status, g push, g pull, g feature, g sync, g stash, g log, g diff, etc.
  - Common workflows: feature branch, quick commit, sync with upstream

### Tasks
1. Read `lib/dispatchers/g-dispatcher.zsh` for all subcommands
2. Create refcard
3. Add to mkdocs.yml nav
4. Cross-reference from QUICK-REFERENCE.md

### Commit
```
docs: add git dispatcher refcard
```

---

## Phase 7: Validate and PR

### Tasks
1. Run `mkdocs build --strict` to catch broken links
2. Verify all new files are in mkdocs.yml nav
3. Run test suite (`./tests/run-all.sh`) — should still be 52/52
4. Final git status + diff review
5. Commit any remaining fixes
6. Push and create PR to dev

### Commit (if needed)
```
chore: fix validation issues from docs gap fix
```

### PR
```
Title: docs: close documentation gaps for v7.6.0 release
Base: dev
```

---

## Acceptance Criteria

- [ ] TROUBLESHOOTING.md and WORKFLOWS.md updated to v7.6.0
- [ ] No duplicate tutorial numbering
- [ ] REFCARD-TEACH-DISPATCHER includes v7.6.0 Scholar commands
- [ ] No stale v5.x/v6.x version references (except historical entries)
- [ ] wt, dots, sec each have a refcard
- [ ] g dispatcher has a refcard
- [ ] All new files in mkdocs.yml nav
- [ ] `mkdocs build --strict` passes
- [ ] 52/52 tests still pass

---

## How to Start

```bash
cd ~/.git-worktrees/flow-cli/feature-docs-gap-fix
claude
```

Then tell Claude: "Implement the ORCHESTRATE plan starting from Phase 1"
