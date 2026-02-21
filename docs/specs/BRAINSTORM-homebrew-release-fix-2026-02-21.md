# BRAINSTORM: Fix Homebrew Release Pipeline

> **Mode:** deep feat | **Duration:** ~8 min | **Date:** 2026-02-21

## Problem Statement

The Homebrew install of flow-cli is **74MB** — should be **< 20MB**. Root causes:

1. **58 stale planning .md files** in repo root (BRAINSTORM-*, WAVE-*, IMPLEMENTATION-*, etc.)
2. **44MB docs/demos/** (GIF recordings) included in tarball
3. **16MB docs/assets/** included in tarball
4. **4.1MB tests/** not needed for users
5. **Node.js artifacts** (package.json, package-lock.json, eslint.config.js, node_modules) still in repo
6. **FLOW_VERSION** missed in v7.4.0 release (no CI guard)
7. **Formula uses `prefix.install Dir["*"]`** — installs everything blindly

## Decisions (from Q&A)

| Decision | Choice |
|----------|--------|
| Target size | < 20MB (standard) |
| Fix location | Formula (selective install in .rb) |
| Tests in install | No — exclude tests/ |
| Docs in install | Essential only (README, CHANGELOG, man pages) |
| Repo cleanup | Full — delete planning docs + old scripts + Node.js artifacts |
| Generator | Hand-edit formula |
| Version guard | CI auto-fix (update FLOW_VERSION, commit, re-tag) |
| Release | v7.4.1 patch release |

---

## Plan: 4 Increments

### Increment 1: Repo Root Cleanup (Quick Win)

**Goal:** Delete 58+ stale files from repo root. Estimated savings: files won't be in future tarballs.

#### Files to DELETE (55 files)

**Planning docs (45):**

- `BRAINSTORM-teach-doctor-improvements-2026-02-07.md`
- `CC-UNIFICATION-IMPROVEMENTS.md`
- `DEPENDENCY-TRACKING-FIX.md`
- `DESIGN-DECISIONS-2026-01-09.md`
- `DOCUMENTATION-COMPLETE.md`
- `DOCUMENTATION-SUMMARY-v3.0.md`
- `DOCUMENTATION-SUMMARY.md`
- `DOCUMENTATION-UPDATE-2026-01-24.md`
- `FEATURE-REQUEST-teach-deploy-direct-mode.md`
- `FINAL-DOCUMENTATION-REPORT.md`
- `FIX-SUMMARY-index-helpers.md`
- `GIF-RECORDING-MIGRATION.md`
- `IDEAS.md`
- `IMPLEMENTATION-SUMMARY.md`
- `INSTALLATION-UPDATES-SUMMARY.md`
- `INTEGRATION-FIXES-CHECKLIST.md`
- `INTEGRATION-VERIFIED.md`
- `LEARNING-PATH-INTEGRATION-SUMMARY.md`
- `PARTIAL-DEPLOY-INDEX-MANAGEMENT.md`
- `PLAN-teach-analyze-phase0.md`
- `PLAN-teach-analyze-phase1.md`
- `PR-DESCRIPTION-UPDATE.md`
- `PR-SUBMISSION-COMPLETE.md`
- `PROJECT-HUB.md`
- `QUARTO-WORKFLOW-QUICK-START.md`
- `RELEASE-v4.8.0.md`
- `RELEASE-v4.9.1.md`
- `SITE-UPDATE-COMPLETE.md`
- `SITE-UPDATE-SUMMARY.md`
- `STAT-545-ANALYSIS-SUMMARY.md`
- `TEACH-DEPLOY-DEEP-DIVE.md`
- `TEACH-DOCTOR-QUICK-REF.md`
- `TEACHING-DOCS-REVIEW.md`
- `TEACHING-DOCUMENTATION-SUMMARY.md`
- `TEACHING-MENU-CONSOLIDATION-PLAN.md`
- `TEACHING-MENU-IMPLEMENTATION-COMPLETE.md`
- `TEACHING-MENU-MIGRATION-SUMMARY.md`
- `TEACHING-MENU-VISUAL-COMPARISON.md`
- `TEACHING-SYSTEM-ARCHITECTURE.md`
- `TEACHING-WORKFLOW-V3-COMPLETE.md`
- `TEST-RESULTS-SUMMARY.md`
- `TESTING-SUMMARY-v5.16.0.md`
- `TODO.md`
- `WAVE-1-COMPLETED.md`, `WAVE-2-COMPLETE.md`, `WAVE-3-DEMO.md`, `WAVE-3-TODO.md`, `WAVE-5-COMPLETE.md`
- `WAVE2-IMPLEMENTATION-SUMMARY.md`, `WAVE3-IMPLEMENTATION.md`
- `WORKFLOW-ENHANCEMENT-PLAN-SUMMARY.md`
- `WORKTREE-PLAN.md`, `WORKTREE-SETUP-COMPLETE.md`
- `WT-DOCUMENTATION-SUMMARY.md`

**Old scripts/artifacts (10):**

- `debug-context.zsh` — debug helper, not needed
- `test-doctor-cache.zsh` — ad-hoc test script
- `test-phase4.sh` — ad-hoc test script
- `test-preview-functions.zsh` — ad-hoc test script
- `test-preview-non-interactive.zsh` — ad-hoc test script
- `test-task1-task4.zsh` — ad-hoc test script
- `eslint.config.js` — Node.js relic (pure ZSH project)
- `package.json` — Node.js relic (only used for lint-staged config?)
- `package-lock.json` — Node.js relic
- `flow-cli.code-workspace` — VS Code workspace file

#### Files to KEEP at root

- `flow.plugin.zsh` — plugin entry point
- `README.md` — project readme
- `CHANGELOG.md` — release history
- `CONTRIBUTING.md` — contributor guide
- `CLAUDE.md` — Claude Code instructions
- `LICENSE` — MIT license
- `install.sh` — standalone installer
- `uninstall.sh` — uninstaller
- `mkdocs.yml` — docs site config

#### Investigate before deleting

- `package.json` — check if lint-staged uses it (pre-commit hook config?)
- `Formula/` directory in repo root — what is this?
- `data/`, `r-ecosystem/`, `plugins/`, `templates/`, `tui/`, `zsh/`, `site/` — what are these?

**Commit:** `chore: delete 55 stale root-level files (planning docs, old scripts, Node.js artifacts)`

---

### Increment 2: Formula Selective Install

**Goal:** Replace `prefix.install Dir["*"]` with explicit file list. Target: < 20MB.

#### New install block for `flow-cli.rb`

```ruby
def install
  # Man pages to proper Homebrew location
  man1.install Dir["man/man1/*"] if (buildpath/"man/man1").exist?

  # Core runtime files only
  prefix.install "flow.plugin.zsh"
  prefix.install "lib"
  prefix.install "commands"
  prefix.install "completions"
  prefix.install "hooks"
  prefix.install "setup"
  prefix.install "scripts"
  prefix.install "config" if (buildpath/"config").exist?

  # Essential docs (not the full docs/ tree)
  prefix.install "README.md"
  prefix.install "CHANGELOG.md"
  prefix.install "LICENSE"

  # Installer scripts
  prefix.install "install.sh"
  prefix.install "uninstall.sh"

  # Create loader script
  (prefix/"bin/flow-cli-init").write <<~EOS
    #!/bin/zsh
    echo "source #{prefix}/flow.plugin.zsh"
  EOS
  (prefix/"bin/flow-cli-init").chmod 0755
end
```

**Expected install size:** ~4MB (lib 2.2MB + commands 0.8MB + completions + hooks + setup + scripts + docs ~0.5MB)

**Commit in homebrew-tap:** `flow-cli: selective install — reduce 74MB → ~4MB`

---

### Increment 3: CI Version Guard (Auto-Fix)

**Goal:** Prevent FLOW_VERSION mismatch. When a release tag is created, CI verifies the version matches and auto-fixes if not.

#### New workflow: `.github/workflows/version-guard.yml`

```yaml
name: Version Guard

on:
  release:
    types: [created]

jobs:
  check-version:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.release.tag_name }}

      - name: Check FLOW_VERSION matches tag
        id: check
        run: |
          TAG="${GITHUB_REF#refs/tags/v}"
          FLOW_VER=$(grep 'FLOW_VERSION=' flow.plugin.zsh | head -1 | sed 's/.*="//' | sed 's/".*//')
          echo "tag=$TAG" >> $GITHUB_OUTPUT
          echo "flow_version=$FLOW_VER" >> $GITHUB_OUTPUT
          if [ "$TAG" != "$FLOW_VER" ]; then
            echo "mismatch=true" >> $GITHUB_OUTPUT
            echo "::warning::FLOW_VERSION ($FLOW_VER) != tag ($TAG)"
          fi

      - name: Auto-fix version mismatch
        if: steps.check.outputs.mismatch == 'true'
        env:
          TAG: ${{ steps.check.outputs.tag }}
        run: |
          sed -i "s/FLOW_VERSION=\"[^\"]*\"/FLOW_VERSION=\"$TAG\"/" flow.plugin.zsh

          # Also fix package.json, README badge if needed
          if [ -f package.json ]; then
            sed -i "s/\"version\": \"[^\"]*\"/\"version\": \"$TAG\"/" package.json
          fi

          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add -A
          git commit -m "chore: auto-fix FLOW_VERSION to $TAG"

          # Delete and recreate tag
          git tag -d "v$TAG"
          git tag -a "v$TAG" -m "v$TAG"
          git push origin "v$TAG" --force
          git push origin HEAD:main
```

**Note:** This is complex — force-pushing tags can retrigger workflows. May need `[skip ci]` in the commit message, or a simpler approach (just block the release with a failing check instead of auto-fix). Worth discussing during implementation.

---

### Increment 4: v7.4.1 Patch Release

**Goal:** Cut release with clean repo, updated formula.

#### Steps

1. All cleanup committed on feature branch → PR to dev → merge
2. PR dev → main with title "Release: v7.4.1"
3. Bump FLOW_VERSION in `flow.plugin.zsh` to "7.4.1"
4. Update CHANGELOG.md with v7.4.1 entry
5. Merge to main, tag `v7.4.0`, create GitHub release
6. `homebrew-release.yml` fires → updates formula SHA
7. Verify: `brew upgrade flow-cli && du -sh $(brew --prefix flow-cli)/`
8. Confirm install size < 20MB

---

## Quick Wins (< 30 min each)

1. Delete 55 root-level files — immediate repo hygiene
2. Hand-edit formula install block — 10 lines of Ruby
3. Test locally: `brew install --build-from-source data-wise/tap/flow-cli`

## Medium Effort (1-2 hours)

1. Investigate root directories (data/, r-ecosystem/, plugins/, templates/, tui/, zsh/, site/, Formula/)
2. CI version guard workflow
3. v7.4.1 release cycle

## Long-term (Future sessions)

1. Add `.gitattributes` export-ignore as defense-in-depth
2. Consider `brew audit --strict` in flow-cli CI (not just homebrew-tap)
3. Periodic `du` check in CI to catch size regressions

---

## Recommended Path

> Start with **Increment 1** (repo cleanup) since it's the biggest impact with lowest risk. Then **Increment 2** (formula fix) which is the actual Homebrew fix. These two together solve the problem. Increments 3-4 are the release mechanics.

**Estimated total effort:** 2-3 hours across 1 worktree session.

---

## Size Budget

| Component | Size | Include? |
|-----------|------|----------|
| lib/ | 2.2MB | Yes — core runtime |
| commands/ | 772KB | Yes — command files |
| completions/ | ~100KB | Yes — ZSH completions |
| hooks/ | ~50KB | Yes — ZSH hooks |
| setup/ | ~200KB | Yes — installation |
| scripts/ | ~100KB | Yes — validators |
| config/ | ~50KB | Yes — config templates |
| flow.plugin.zsh | ~20KB | Yes — entry point |
| README + CHANGELOG + LICENSE | ~100KB | Yes — essential docs |
| man/ | ~50KB | Yes — man pages |
| **Total** | **~3.6MB** | |
| tests/ | 4.1MB | No |
| docs/ | 66MB | No |
| 58 root .md files | ~500KB | No |
| Node.js artifacts | ~100KB | No |
