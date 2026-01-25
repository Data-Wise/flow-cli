# Release Checklist: v5.14.0 - Teaching Workflow v3.0

**Release Type:** Minor (Feature Release)
**Current Version:** v5.13.0
**Target Version:** v5.14.0
**Branch:** dev → main
**Date:** 2026-01-18

---

## 📋 Pre-Release Checklist

### Version Management

- [ ] Bump version: 5.13.0 → 5.14.0 in all files
  - [ ] package.json
  - [ ] README.md (badge)
  - [ ] CLAUDE.md
  - [ ] docs/reference/CC-DISPATCHER-REFERENCE.md

### Documentation

- [ ] Update CHANGELOG.md with v5.14.0 section
- [ ] Verify all 6 GIFs embedded in guides
- [ ] Check MkDocs builds without errors
- [ ] Deploy documentation to GitHub Pages
- [ ] Verify GIFs load in production

### Quality Checks

- [ ] All tests passing (300+ tests)
- [ ] No syntax errors in ZSH files
- [ ] Git status clean (no uncommitted changes)
- [ ] Branch up to date with remote

### Release Content Verification

- [ ] Teaching Workflow v3.0 Phase 1 complete (10 tasks)
- [ ] Visual documentation complete (6 GIFs)
- [ ] All documentation guides updated
- [ ] VHS tape guidelines documented

---

## 🚀 Release Steps

### 1. Version Bump

- [ ] Run: `./scripts/release.sh 5.14.0`
- [ ] Verify all version files updated
- [ ] Review changes: `git diff`

### 2. Update CHANGELOG

- [ ] Add v5.14.0 section with complete feature list
- [ ] Include visual documentation highlights
- [ ] List all breaking changes (none expected)
- [ ] Credit contributors

### 3. Commit Version Bump

- [ ] Stage all version files
- [ ] Commit: "chore: bump version to 5.14.0"
- [ ] Push to dev branch

### 4. Deploy Documentation

- [ ] Run: `mkdocs build`
- [ ] Run: `mkdocs gh-deploy --force`
- [ ] Verify: https://Data-Wise.github.io/flow-cli/
- [ ] Test GIF loading in production

### 5. Create Release PR

- [ ] Create PR: dev → main
- [ ] Title: "Release v5.14.0 - Teaching Workflow v3.0"
- [ ] Include comprehensive release notes
- [ ] Request review (if applicable)

### 6. Merge and Tag

- [ ] Merge PR to main
- [ ] Switch to main: `git checkout main && git pull`
- [ ] Tag: `git tag -a v5.14.0 -m "v5.14.0 - Teaching Workflow v3.0"`
- [ ] Push tag: `git push --tags`

### 7. GitHub Release

- [ ] Create release on GitHub
- [ ] Use v5.14.0 tag
- [ ] Add detailed release notes
- [ ] Attach assets (if needed)
- [ ] Publish release

### 8. Homebrew Auto-Update

- [ ] Verify GitHub Actions creates PR
- [ ] Review formula update PR
- [ ] Merge formula PR
- [ ] Test: `brew upgrade flow-cli`

---

## 📝 Post-Release

### Verification

- [ ] GitHub release published
- [ ] Documentation live with GIFs
- [ ] Homebrew formula updated
- [ ] Tag pushed successfully

### Communication

- [ ] Update project README highlights
- [ ] Share release announcement (if applicable)
- [ ] Update issue/PR references

### Development Continuation

- [ ] Merge main back to dev
- [ ] Continue development on dev branch

---

## 🎉 Release Notes Draft

### v5.14.0 - Teaching Workflow v3.0 (2026-01-18)

**Major Feature:** Complete overhaul of teaching workflow with 10 tasks across 3 waves

#### 🎓 Teaching Workflow v3.0 - Core Features

**Wave 1: Foundation**
- ✅ Removed standalone `teach-init` command (integrated into dispatcher)
- ✅ New `teach doctor` - Environment health check with --fix, --json, --quiet
- ✅ Added --help flags with EXAMPLES to all 10 teach sub-commands

**Wave 2: Backup System**
- ✅ Automated backup system with timestamped snapshots
- ✅ Retention policies (archive vs semester)
- ✅ Interactive delete confirmation with preview
- ✅ Archive management for semester-end

**Wave 3: Enhancements**
- ✅ Enhanced `teach status` - Deployment + backup info
- ✅ Deploy preview before PR creation
- ✅ Scholar template selection + lesson plan auto-load
- ✅ Reimplemented `teach init` with --config, --github flags

#### 📚 Visual Documentation

**6 comprehensive tutorial GIFs (5.7MB optimized):**
- teach doctor: Environment health check
- Backup system: Automated content safety
- teach init: Project initialization
- teach deploy: Preview deployment
- teach status: Enhanced project overview
- Scholar integration: Template & lesson plans

All GIFs embedded in documentation guides with accessibility captions.

#### 📊 Statistics

- Files changed: 18 (+7,294 / -1,510 lines)
- Tests: 73 tests (100% passing)
- Documentation: 3 comprehensive guides
- Visual demos: 6 GIFs, all optimized

#### 🔗 Documentation

- [Teaching Workflow v3.0 Guide](https://Data-Wise.github.io/flow-cli/guides/TEACHING-WORKFLOW-V3-GUIDE/)
- [Backup System Guide](https://Data-Wise.github.io/flow-cli/guides/BACKUP-SYSTEM-GUIDE/)
- [Migration Guide](https://Data-Wise.github.io/flow-cli/guides/TEACHING-V3-MIGRATION-GUIDE/)

#### ⚠️ Breaking Changes

**None** - All changes are backward compatible

- `teach-init` command still works (deprecated, use `teach init`)
- All existing teach sub-commands unchanged
- Config files automatically upgraded

#### 🙏 Credits

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>

---

## 📦 Installation

```bash
# Via Homebrew (recommended)
brew upgrade flow-cli

# Via plugin manager
antidote update

# Manual update
cd ~/projects/dev-tools/flow-cli
git pull origin main
source flow.plugin.zsh
```

---

**Full Changelog:** https://github.com/Data-Wise/flow-cli/compare/v5.13.0...v5.14.0

