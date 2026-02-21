# Homebrew Release Fix — Orchestration Plan

> **Branch:** `feature/homebrew-release-fix`
> **Base:** `dev`
> **Worktree:** `~/.git-worktrees/flow-cli/feature-homebrew-release-fix`
> **Spec:** `docs/specs/SPEC-homebrew-release-fix-2026-02-21.md`
> **Target version:** v7.4.1

## Objective

Fix bloated Homebrew install (74MB → < 20MB). Delete stale root files, update formula to selective install, add CI version guard, and cut v7.4.1.

---

## Phase Overview

| Phase | Task | Priority | Status |
|-------|------|----------|--------|
| 1 | Delete stale root-level files (52 files) | High | Pending |
| 2 | Update Homebrew formula (selective install) | High | Pending |
| 3 | Add CI version guard workflow | Medium | Pending |
| 4 | Version bump + release prep | High | Pending |

---

## Phase 1: Repo Root Cleanup

### Task 1.1: Delete stale planning docs (48 files)

Delete these files from repo root:

```
BRAINSTORM-teach-doctor-improvements-2026-02-07.md
CC-UNIFICATION-IMPROVEMENTS.md
DEPENDENCY-TRACKING-FIX.md
DESIGN-DECISIONS-2026-01-09.md
DOCUMENTATION-COMPLETE.md
DOCUMENTATION-SUMMARY-v3.0.md
DOCUMENTATION-SUMMARY.md
DOCUMENTATION-UPDATE-2026-01-24.md
FEATURE-REQUEST-teach-deploy-direct-mode.md
FINAL-DOCUMENTATION-REPORT.md
FIX-SUMMARY-index-helpers.md
GIF-RECORDING-MIGRATION.md
IDEAS.md
IMPLEMENTATION-SUMMARY.md
INSTALLATION-UPDATES-SUMMARY.md
INTEGRATION-FIXES-CHECKLIST.md
INTEGRATION-VERIFIED.md
LEARNING-PATH-INTEGRATION-SUMMARY.md
PARTIAL-DEPLOY-INDEX-MANAGEMENT.md
PLAN-teach-analyze-phase0.md
PLAN-teach-analyze-phase1.md
PR-DESCRIPTION-UPDATE.md
PR-SUBMISSION-COMPLETE.md
PROJECT-HUB.md
QUARTO-WORKFLOW-QUICK-START.md
RELEASE-v4.8.0.md
RELEASE-v4.9.1.md
SITE-UPDATE-COMPLETE.md
SITE-UPDATE-SUMMARY.md
STAT-545-ANALYSIS-SUMMARY.md
TEACH-DEPLOY-DEEP-DIVE.md
TEACH-DOCTOR-QUICK-REF.md
TEACHING-DOCS-REVIEW.md
TEACHING-DOCUMENTATION-SUMMARY.md
TEACHING-MENU-CONSOLIDATION-PLAN.md
TEACHING-MENU-IMPLEMENTATION-COMPLETE.md
TEACHING-MENU-MIGRATION-SUMMARY.md
TEACHING-MENU-VISUAL-COMPARISON.md
TEACHING-SYSTEM-ARCHITECTURE.md
TEACHING-WORKFLOW-V3-COMPLETE.md
TEST-RESULTS-SUMMARY.md
TESTING-SUMMARY-v5.16.0.md
TODO.md
WAVE-1-COMPLETED.md
WAVE-2-COMPLETE.md
WAVE-3-DEMO.md
WAVE-3-TODO.md
WAVE-5-COMPLETE.md
WAVE2-IMPLEMENTATION-SUMMARY.md
WAVE3-IMPLEMENTATION.md
WORKFLOW-ENHANCEMENT-PLAN-SUMMARY.md
WORKTREE-PLAN.md
WORKTREE-SETUP-COMPLETE.md
WT-DOCUMENTATION-SUMMARY.md
```

**Commit:** `chore: delete 48 stale planning docs from repo root`

### Task 1.2: Delete old scripts and artifacts (4 files)

```
debug-context.zsh
test-doctor-cache.zsh
test-phase4.sh
test-preview-functions.zsh
test-preview-non-interactive.zsh
test-task1-task4.zsh
flow-cli.code-workspace
eslint.config.js
```

**Keep:** `package.json` and `package-lock.json` — they configure husky + lint-staged + prettier pre-commit hooks. Essential for development workflow.

**Keep:** `sbom.spdx.json` — investigate if actively maintained. If not, delete in a follow-up.

**Commit:** `chore: delete old test scripts, debug helpers, and Node.js lint config`

### Task 1.3: Verify nothing broke

```bash
source flow.plugin.zsh   # Plugin still loads
./tests/run-all.sh        # Tests still pass
```

---

## Phase 2: Homebrew Formula (selective install)

### Task 2.1: Update flow-cli.rb in homebrew-tap

**File:** `Formula/flow-cli.rb` in `Data-Wise/homebrew-tap` repo (NOT the local copy in `Formula/`)

Replace the install block:

```ruby
def install
  # Man pages to proper Homebrew location
  man1.install Dir["man/man1/*"] if (buildpath/"man/man1").exist?
  rm_r(buildpath/"man") if (buildpath/"man").exist?

  # Core runtime files only
  prefix.install "flow.plugin.zsh"
  prefix.install "lib"
  prefix.install "commands"
  prefix.install "completions"
  prefix.install "hooks"
  prefix.install "setup"
  prefix.install "scripts"
  prefix.install "config" if (buildpath/"config").exist?
  prefix.install "plugins" if (buildpath/"plugins").exist?
  prefix.install "zsh" if (buildpath/"zsh").exist?

  # Essential docs
  prefix.install "README.md"
  prefix.install "CHANGELOG.md"
  prefix.install "LICENSE"

  # Installer scripts
  prefix.install "install.sh"
  prefix.install "uninstall.sh"

  # Loader script
  (prefix/"bin/flow-cli-init").write <<~EOS
    #!/bin/zsh
    echo "source #{prefix}/flow.plugin.zsh"
  EOS
  (prefix/"bin/flow-cli-init").chmod 0755
end
```

**Method:** Use `gh api` or clone homebrew-tap to make this edit. Can also be done via manual PR.

**Verify locally:**
```bash
brew uninstall flow-cli
brew install --build-from-source data-wise/tap/flow-cli
du -sh $(brew --prefix flow-cli)/
# Expected: < 5MB
```

### Task 2.2: Update local Formula/ copy

Update `Formula/flow-cli.rb` in this repo to match (keep in sync).

**Commit in homebrew-tap:** `flow-cli: selective install — reduce 74MB to ~4MB`

---

## Phase 3: CI Version Guard

### Task 3.1: Create version-guard.yml

**File:** `.github/workflows/version-guard.yml`

**Trigger:** `release: types: [created]`

**Logic:**
1. Checkout the tag
2. Extract tag version (strip `v` prefix)
3. Extract FLOW_VERSION from `flow.plugin.zsh`
4. If match → exit success
5. If mismatch → sed fix, commit with `[skip ci]`, delete + recreate tag, force-push tag

**Critical details:**
- Use `[skip ci]` in auto-fix commit to prevent infinite loops
- Add `concurrency` group to prevent parallel runs
- Push fix commit to `main` branch (since tag is on main)
- Use GITHUB_TOKEN (has tag push permissions)

**Commit:** `ci: add version guard with auto-fix for FLOW_VERSION mismatch`

### Task 3.2: Test version guard

- Create a test tag with wrong FLOW_VERSION
- Verify the workflow detects and fixes it
- Delete test tag after

---

## Phase 4: Release v7.4.1

### Task 4.1: Version bump

Update FLOW_VERSION in these files:
- `flow.plugin.zsh` → `FLOW_VERSION="7.4.1"`
- `package.json` → `"version": "7.4.1"`
- `README.md` → version badge (if hardcoded)
- `CLAUDE.md` → `Current Version: v7.4.1`

### Task 4.2: Update CHANGELOG.md

Add entry:

```markdown
### v7.4.1 (2026-02-XX) — Homebrew Cleanup

- chore: delete 52 stale root-level files (planning docs, scripts, artifacts)
- fix: Homebrew formula selective install — reduce 74MB to ~4MB
- ci: add version guard with auto-fix for FLOW_VERSION mismatch
```

### Task 4.3: Update .STATUS

Update current session, version, and any pending items.

### Task 4.4: PR → dev → main → release

1. `gh pr create --base dev` (feature → dev)
2. After merge: `gh pr create --base main --head dev --title "Release: v7.4.1"`
3. After merge to main: `git tag -a v7.4.1 -m "v7.4.1" && git push --tags`
4. Create GitHub release
5. Verify homebrew-release.yml fires and updates formula SHA
6. `brew upgrade data-wise/tap/flow-cli`
7. Verify: `du -sh $(brew --prefix flow-cli)/` → expect < 5MB

---

## Acceptance Criteria

- [ ] No stale planning docs in repo root
- [ ] No ad-hoc test scripts in repo root
- [ ] `brew install` Cellar < 20MB (target < 5MB)
- [ ] Formula installs only: lib/, commands/, completions/, hooks/, setup/, scripts/, config/, plugins/, zsh/, flow.plugin.zsh, README, CHANGELOG, LICENSE, man pages
- [ ] CI version guard workflow exists and tested
- [ ] FLOW_VERSION = 7.4.1 in flow.plugin.zsh
- [ ] All tests pass (47/47 suites)
- [ ] v7.4.1 released on GitHub
- [ ] Homebrew formula auto-updated to v7.4.1
- [ ] `flow --version` reports 7.4.1 after brew upgrade

## Open Questions (resolve during implementation)

1. `sbom.spdx.json` — keep or delete?
2. `Formula/flow-cli.rb` in repo root — keep in sync with tap or delete?
3. Version guard auto-fix complexity — may simplify to "block release" if re-tagging is too fragile

---

## How to Start

```bash
cd ~/.git-worktrees/flow-cli/feature-homebrew-release-fix
claude
```

Then follow phases 1-4 in order. Each phase has clear commits.
