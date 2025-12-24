# Phase P5D: Alpha Release Plan

**Created:** 2025-12-22
**Status:** Planning
**Estimated Time:** 4-5 hours total
**Target:** Production-ready v2.0 alpha release

---

## 🎯 Goals

**Primary Objective:** Prepare flow-cli v2.0 for alpha release to early adopters

**Success Criteria:**

- ✅ All tutorials accurate and validated for 28-alias system
- ✅ Documentation site fully functional with no broken links
- ✅ Installation process tested and documented
- ✅ Version tagged and changelog created
- ✅ GitHub release package published
- ✅ Migration guide for v1.0 users

---

## 📊 Current State Assessment

### ✅ What's Already Complete

**Documentation (Phase P5 - COMPLETE):**

- ✅ 63-page documentation site deployed (data-wise.github.io/flow-cli)
- ✅ Architecture documentation (6,200+ lines across 11 files)
- ✅ Contributing guide (30-minute onboarding)
- ✅ API documentation (2 comprehensive pages)
- ✅ Help system (20+ functions with `--help`)
- ✅ Tutorials updated for 28-alias system (Dec 21)

**Code Quality:**

- ✅ Alias cleanup complete (179 → 28, 84% reduction)
- ✅ CLI integration working (vendored project detection)
- ✅ Test suites passing (CLI tests validated)
- ✅ Git workflow clean (all changes committed)

**Project Infrastructure:**

- ✅ Project renamed to flow-cli
- ✅ GitHub repository updated
- ✅ MkDocs site deployed
- ✅ Cloud sync configured (Google Drive + Dropbox)

### ⚠️ What Needs Work

**Tutorial Validation:**

- ⚠️ Need automated validation that examples work
- ⚠️ Link checking not automated (manual only)
- ⚠️ Tutorial exercises not tested end-to-end

**Release Packaging:**

- ⚠️ No CHANGELOG.md yet
- ⚠️ No version tagging (currently untagged)
- ⚠️ No GitHub Release created
- ⚠️ No migration guide for v1.0 → v2.0

**Installation Experience:**

- ⚠️ Installation guide exists but not tested on fresh system
- ⚠️ No quick validation script for new users
- ⚠️ Setup script needs update for v2.0

---

## 📋 Work Breakdown (4 Phases)

### Phase 1: Tutorial Validation ⏱️ 1-2 hours

**Goal:** Ensure all tutorial commands work correctly

#### Tasks

**1.1 Create Tutorial Validation Script** [30 min]

```bash
# File: scripts/validate-tutorials.sh
# Purpose: Parse tutorial markdown, extract commands, validate they exist
```

**What to validate:**

- ✅ All commands mentioned in tutorials exist (rtest, rload, rdoc, etc.)
- ✅ All aliases referenced are in the 28-alias system
- ✅ No references to removed commands (js → just-start, etc.)
- ✅ Function names match actual implementation
- ✅ Examples use correct syntax

**Deliverable:**

- `scripts/validate-tutorials.sh` - Automated validation script
- `docs/testing/TUTORIAL-VALIDATION-RESULTS.md` - Validation report

**1.2 Fix Any Discovered Issues** [30 min - 1 hour]

- Update tutorials if validation finds errors
- Verify all workflow examples are accurate
- Test interactive examples where possible

**Files to validate:**

- `../user/WORKFLOW-TUTORIAL.md` ✅ (Updated Dec 21)
- `../user/WORKFLOWS-QUICK-WINS.md` ✅ (Updated Dec 21)
- `../user/ALIAS-REFERENCE-CARD.md`
- `../getting-started/quick-start.md`

---

### Phase 2: Site & Link Quality ⏱️ 45 min - 1 hour

**Goal:** Ensure documentation site is production-ready

#### Tasks

**2.1 Automated Link Checking** [20 min]

```bash
# Add to package.json scripts
npm run link-check     # Check all markdown links
npm run site-validate  # Build site and check for errors
```

**What to check:**

- Internal links (between docs pages)
- External links (GitHub, websites)
- Code block references (file paths mentioned in docs)
- Navigation menu links (mkdocs.yml)

**Tools to use:**

- `markdown-link-check` (npm package)
- `mkdocs build --strict` (fail on warnings)

**2.2 Site Build Validation** [15 min]

```bash
# Test full site build
mkdocs build --strict
mkdocs serve
# Manual review of key pages
```

**Key pages to review:**

- Home page (docs/index.md)
- Quick Start Guide
- Alias Reference Card
- Architecture overview
- Contributing guide

**2.3 Fix Broken Links** [10-20 min]

- Update any broken internal links
- Fix or remove broken external links
- Update outdated references

**Deliverable:**

- ✅ All links working
- ✅ Site builds with zero warnings
- ✅ Navigation tested end-to-end

---

### Phase 3: Version & Release Package ⏱️ 1-1.5 hours

**Goal:** Create proper version documentation and release artifacts

#### Tasks

**3.1 Create CHANGELOG.md** [30 min]

**Structure:**

```markdown
# Changelog

## [2.0.0-alpha.1] - 2025-12-22

### Major Changes

- **BREAKING:** Reduced custom aliases from 179 to 28 (84% reduction)
- **NEW:** 28-alias system based on frequency analysis (10+ uses/day rule)
- **NEW:** Help system - 20+ functions with `--help` support
- **NEW:** Documentation site with 63 pages

### Added

- Architecture documentation (6,200+ lines)
- Contributing guide (30-minute onboarding)
- CLI integration with vendored project detection
- ADHD-optimized workflows
- Copy-paste code examples (88+ patterns)

### Changed

- Project renamed from zsh-configuration to flow-cli
- Tutorial updates for 28-alias system
- Alias reference card rewritten
- Website design (ADHD-optimized cyan/purple theme)

### Removed

- 151 low-frequency aliases (with migration guide)
- Desktop app (Electron - paused due to technical issues)

### Fixed

- Pick command git repo validation
- Node version consistency in CLI workspace
- Help system standardization

### Migration Guide

See: docs/user/MIGRATION-v1-to-v2.md

## [1.0.0] - 2025-12-14

- Initial stable release (179-alias system)
```

**What to include:**

- All major changes since v1.0
- Breaking changes clearly marked
- Migration guide reference
- Credit to contributors

**3.2 Create Migration Guide** [30 min]

**File:** `docs/user/MIGRATION-v1-to-v2.md`

**Content:**

- Before/after alias comparison table
- Command mapping (old → new)
- What was removed and why
- How to adapt existing workflows
- FAQ for common questions

**Example table:**

```markdown
| Old Command      | New Command    | Notes                  |
| ---------------- | -------------- | ---------------------- |
| js / idk / stuck | just-start     | Unified to one command |
| t                | rtest          | R package test         |
| lt               | rload && rtest | Load then test         |
| dt               | rdoc && rtest  | Document then test     |
| qcommit          | git commit     | Use git directly       |
```

**3.3 Version Tagging** [10 min]

```bash
# Update package.json version
npm version 2.0.0-alpha.1 --no-git-tag-version

# Create git tag
git add package.json CHANGELOG.md
git commit -m "chore: release v2.0.0-alpha.1"
git tag -a v2.0.0-alpha.1 -m "flow-cli v2.0.0 Alpha Release 1

Major changes:
- 28-alias system (84% reduction)
- Help system for 20+ functions
- Documentation site with 63 pages
- Architecture docs (6,200+ lines)
- CLI integration with project detection

See CHANGELOG.md for full details."

git push origin main --tags
```

**3.4 Update Installation Guide** [20 min]

**File:** `docs/getting-started/installation.md`

**Add:**

- Version compatibility notes (requires Node 18+, ZSH 5.8+)
- Quick validation command (after install)
- Troubleshooting section
- Uninstall instructions

**Quick validation script:**

```bash
# File: scripts/health-check.sh
# Purpose: Validate installation after setup

echo "🔍 flow-cli v2.0 Health Check"
echo ""

# Check ZSH config exists
if [ -f ~/.config/zsh/.zshrc ]; then
  echo "✅ ZSH config found"
else
  echo "❌ ZSH config missing"
fi

# Check key aliases exist
if alias rtest &>/dev/null; then
  echo "✅ Aliases loaded"
else
  echo "❌ Aliases not loaded"
fi

# Check key functions exist
if type just-start &>/dev/null; then
  echo "✅ Functions loaded"
else
  echo "❌ Functions not loaded"
fi

echo ""
echo "📖 Run 'ah' to see all available commands"
```

---

### Phase 4: GitHub Release ⏱️ 30-45 min

**Goal:** Create GitHub Release with assets

#### Tasks

**4.1 Prepare Release Assets** [15 min]

**What to include:**

- README.md (overview)
- CHANGELOG.md (what's new)
- MIGRATION-v1-to-v2.md (upgrade guide)
- Installation guide (quick start)
- Link to documentation site

**Optional assets:**

- Zipped source code (GitHub does this automatically)
- Installation script (`setup.sh`)

**4.2 Create GitHub Release** [15 min]

**Using gh CLI:**

````bash
gh release create v2.0.0-alpha.1 \
  --title "flow-cli v2.0.0 Alpha 1 - The 28-Alias Revolution" \
  --notes "$(cat << 'EOF'
# 🚀 flow-cli v2.0.0 Alpha Release 1

**The ADHD-Optimized Flow CLI**

## 🎯 What's New

### Major Changes
- **84% alias reduction** - From 179 to 28 essential aliases
- **Help system** - 20+ functions with `--help` support
- **Documentation site** - 63 pages deployed at data-wise.github.io/flow-cli
- **Architecture docs** - 6,200+ lines of comprehensive documentation

### Breaking Changes ⚠️
This is a **breaking release**. If upgrading from v1.0:
- Read the [Migration Guide](docs/user/MIGRATION-v1-to-v2.md)
- 151 aliases removed (with replacements documented)
- New 28-alias system based on frequency analysis

### Installation

**New users:**
```bash
git clone https://github.com/Data-Wise/flow-cli
cd flow-cli
./scripts/setup.sh
````

**Existing users:**

```bash
cd ~/projects/dev-tools/flow-cli
git pull origin main
git checkout v2.0.0-alpha.1
./scripts/health-check.sh
```

### Documentation

- 📚 [Full Documentation](https://data-wise.github.io/flow-cli)
- 🚀 [Quick Start Guide](../getting-started/quick-start.md)
- 📖 [Workflow Tutorials](../user/WORKFLOWS-QUICK-WINS.md)
- 🎯 [Alias Reference](../user/ALIAS-REFERENCE-CARD.md)

### What's Next (Roadmap)

- Help system phase 2 (remaining functions)
- Performance optimization (startup time, caching)
- Tutorial quality improvements
- Desktop app resumption (optional)

See [CHANGELOG.md](../../CHANGELOG.md) for complete details.

---

**Note:** This is an **alpha release** - suitable for early adopters and testing. Production release (v2.0.0 stable) planned for early 2026.
EOF
)" \
 --prerelease \
 --latest=false

# Attach migration guide

gh release upload v2.0.0-alpha.1 docs/user/MIGRATION-v1-to-v2.md

````

**4.3 Verify Release** [10 min]
- Check release appears on GitHub
- Test download link works
- Verify assets are attached
- Review release notes formatting

**4.4 Announcement** [10 min]

**Update README.md badge:**
```markdown
![Version](https://img.shields.io/badge/version-2.0.0--alpha.1-blue)
![Status](https://img.shields.io/badge/status-alpha-yellow)
````

**Optional announcements:**

- Project discussions (GitHub)
- Personal blog/notes
- Social media (if desired)

---

## 🎯 Quality Gates

**Before release, verify:**

- [ ] All tutorial commands validated (phase 1)
- [ ] Zero broken links in documentation (phase 2)
- [ ] Site builds with `--strict` mode (phase 2)
- [ ] CHANGELOG.md complete (phase 3)
- [ ] Migration guide created (phase 3)
- [ ] Git tag created and pushed (phase 3)
- [ ] Health check script works (phase 3)
- [ ] GitHub Release published (phase 4)
- [ ] Release assets attached (phase 4)

---

## 📈 Success Metrics

**After alpha release:**

- Documentation site accessible and functional
- New users can install and validate in < 10 minutes
- Existing users can migrate with clear guidance
- Zero critical bugs in issue tracker
- Feedback from 2-3 early adopters

**User feedback to collect:**

- Installation experience (easy/hard?)
- Documentation clarity (helpful/confusing?)
- Tutorial quality (practical/theoretical?)
- Workflow improvements (better/worse than v1?)

---

## 🚨 Risk Mitigation

### Risk: Tutorial validation finds major issues

**Mitigation:**

- Budget extra time for fixes (1-2 hours)
- Prioritize critical workflows (top 10)
- Document known issues in release notes

### Risk: Link checking reveals widespread problems

**Mitigation:**

- Fix critical navigation links first
- Mark non-critical issues for post-release
- Update mkdocs.yml if structural changes needed

### Risk: Migration guide is incomplete

**Mitigation:**

- Focus on most-used commands first (top 20)
- Create FAQ section for edge cases
- Plan follow-up docs after user feedback

### Risk: Installation fails on fresh system

**Mitigation:**

- Test on clean VM or container
- Document prerequisites clearly
- Provide troubleshooting guide

---

## 📅 Suggested Timeline

### Option A: Single Session (4-5 hours)

**Best for:** Hyperfocus day, high energy

```
Hour 1:    Phase 1 - Tutorial validation
Hour 2:    Phase 2 - Site & link quality
Hour 3-4:  Phase 3 - Version & release package
Hour 5:    Phase 4 - GitHub release
```

### Option B: Split Sessions (2-3 days)

**Best for:** ADHD-friendly, sustainable pace

**Day 1 (2 hours):**

- Phase 1: Tutorial validation
- Phase 2: Site & link quality

**Day 2 (2 hours):**

- Phase 3: Version & release package

**Day 3 (1 hour):**

- Phase 4: GitHub release
- Announcement and wrap-up

### Option C: Phased Rollout (1 week)

**Best for:** Careful validation, early feedback

**Week 1:**

- Mon-Tue: Phases 1-2 (validation)
- Wed-Thu: Phase 3 (version docs)
- Fri: Phase 4 (release)
- Weekend: Monitor feedback

---

## ✅ Phase Completion Checklist

### Phase 1: Tutorial Validation

- [ ] Create `scripts/validate-tutorials.sh`
- [ ] Run validation on all tutorials
- [ ] Fix discovered issues
- [ ] Document results in `docs/testing/TUTORIAL-VALIDATION-RESULTS.md`
- [ ] Test 3 key workflows manually

### Phase 2: Site & Link Quality

- [ ] Install `markdown-link-check`
- [ ] Run link checking on all docs
- [ ] Build site with `--strict` flag
- [ ] Manually review top 5 pages
- [ ] Fix all broken links
- [ ] Verify navigation works

### Phase 3: Version & Release Package

- [ ] Write CHANGELOG.md (all sections)
- [ ] Create MIGRATION-v1-to-v2.md
- [ ] Update package.json version
- [ ] Create git tag with message
- [ ] Push tag to GitHub
- [ ] Create `scripts/health-check.sh`
- [ ] Update installation guide
- [ ] Test health check script

### Phase 4: GitHub Release

- [ ] Prepare release notes
- [ ] Create GitHub Release (prerelease)
- [ ] Attach migration guide
- [ ] Verify download works
- [ ] Update README.md badges
- [ ] Optional: Write announcement

---

## 🎉 Post-Release Actions

**Immediate (same day):**

- [ ] Monitor GitHub for issues
- [ ] Test installation on second machine
- [ ] Share with 1-2 trusted users

**Week 1:**

- [ ] Collect user feedback
- [ ] Fix critical bugs (if any)
- [ ] Update documentation based on questions

**Week 2-4:**

- [ ] Plan v2.0.0-beta.1 based on feedback
- [ ] Consider help system phase 2
- [ ] Evaluate performance optimization priority

---

## 💡 Future Enhancements (Post-Alpha)

**Not in scope for alpha, but consider for beta/stable:**

1. **Automated Testing** [3-4 hours]
   - CI/CD for tutorial validation
   - Automated link checking in GitHub Actions
   - Pre-commit hooks for docs quality

2. **Tutorial Improvements** [2-3 hours]
   - Interactive exercises with validation
   - Video walkthroughs (optional)
   - Quizzes/challenges

3. **Installation Wizard** [4-5 hours]
   - Interactive setup script
   - Conflict detection (existing configs)
   - Backup/restore functionality

4. **Performance Metrics** [2-3 hours]
   - Startup time benchmarking
   - Function execution profiling
   - Optimization recommendations

---

## 📚 Reference Documents

**Planning:**

- `.STATUS` - Current status and recent work
- `PROJECT-HUB.md` - Strategic roadmap

**Documentation:**

- `../user/WORKFLOW-TUTORIAL.md` - Main tutorial
- `../user/WORKFLOWS-QUICK-WINS.md` - Top 10 workflows
- `../user/ALIAS-REFERENCE-CARD.md` - Alias reference

**Architecture:**

- `CONTRIBUTING.md` - Contributor guide
- `docs/architecture/` - Architecture documentation

**Testing:**

- `cli/test/` - CLI test suites
- `~/.config/zsh/tests/` - ZSH function tests

---

## 🎯 Definition of Done

**Phase P5D is complete when:**

1. ✅ v2.0.0-alpha.1 tag exists on GitHub
2. ✅ GitHub Release published with assets
3. ✅ CHANGELOG.md documents all changes
4. ✅ Migration guide helps v1.0 users upgrade
5. ✅ Documentation site has zero broken links
6. ✅ Tutorial commands validated and working
7. ✅ Health check script passes on fresh install
8. ✅ README.md updated with version badge

**Ready for beta when:**

- At least 3 alpha users provide feedback
- Critical bugs (if any) are fixed
- Documentation questions addressed
- Tutorial quality validated by users

---

**Created by:** Claude Code (Sonnet 4.5)
**Review:** Recommended before execution
**Estimated Total Time:** 4-5 hours (single session) or 3-5 days (split sessions)
