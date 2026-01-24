# Feature Request: Quarto Workflow Enhancements for Teaching Sites

**Status:** Proposal
**Priority:** Medium
**Target:** flow-cli v4.6.0+
**Created:** 2026-01-20
**Category:** Teaching Workflow Enhancement

---

## Summary

Integrate Quarto performance optimizations and validation workflows developed for STAT 545 into the flow-cli teaching system. This includes freeze caching, automated git hooks, and comprehensive error detection.

**Value Proposition:** Faster development, earlier error detection, cleaner git history.

---

## Background

While working on the STAT 545 course site (~/projects/teaching/stat-545), we developed a robust workflow for managing Quarto-based teaching materials:

1. **Quarto Freeze** - Caches R code execution for 10-100x faster rendering
2. **Git Hooks** - Validates and renders files before commits/pushes
3. **Validation Scripts** - Manual pre-commit testing
4. **Clear Documentation** - Render vs Preview, error handling

These improvements should be integrated into flow-cli's `teach` commands.

---

## Current State (flow-cli Teaching)

### Existing Commands

```bash
teach init        # Initialize teaching project
teach deploy      # Deploy to GitHub Pages
teach status      # Show semester status
teach archive     # Archive semester
```

### Current Limitations

1. ❌ No Quarto freeze configuration
2. ❌ No automated validation before commits
3. ❌ No render vs preview guidance
4. ❌ Manual git hook setup required
5. ❌ No error detection workflow

---

## Proposed Enhancements

### 1. Automatic Quarto Freeze Setup

**Command:** `teach init` (enhanced)

**What it does:**

```bash
teach init stat-545

# New behavior:
# 1. Creates _quarto.yml with freeze: auto
# 2. Adds _freeze/ to .gitignore
# 3. Documents freeze in CLAUDE.md
# 4. Adds freeze commands to README.md
```

**Configuration:**

```yaml
# Auto-added to _quarto.yml
project:
  type: website
  execute:
    freeze: auto  # Only re-execute changed files
```

**Benefit:** 10-100x faster subsequent renders

---

### 2. Automated Git Hook Installation

**Command:** `teach init` or `teach hooks install`

**What it does:**

```bash
teach hooks install

# Creates:
# 1. .git/hooks/pre-commit (validates & renders changed files)
# 2. .git/hooks/pre-push (full site render on production)
# 3. scripts/validate-changes.sh (manual validation)
```

**Pre-commit Hook Behavior:**
- ✅ YAML frontmatter validation
- ✅ Quarto syntax check (`quarto inspect`)
- ✅ Full render of changed `.qmd` files
- ✅ Image reference validation
- ⏱️ Fast execution (1-5s per file with freeze)

**Pre-push Hook Behavior:**
- ✅ Full site render (production branch only)
- ✅ Blocks push if any file fails
- ⏱️ 2-5 minutes (full render)

**Environment Variable:**

```bash
# Disable rendering in pre-commit if needed
QUARTO_PRE_COMMIT_RENDER=0 git commit -m "wip"
```

---

### 3. Validation Workflow

**Command:** `teach validate` or `teach check`

**What it does:**

```bash
teach validate

# Renders only changed files:
# 1. Finds modified/staged .qmd files
# 2. Renders each one individually
# 3. Shows pass/fail status
# 4. Fast (uses freeze cache)
```

**Example Output:**

```
Validating changed files...

Files to validate:
  - lectures/week-05_factorial-anova.qmd
  - syllabus/syllabus-final.qmd

Rendering lectures/week-05_factorial-anova.qmd...
✓ OK: lectures/week-05_factorial-anova.qmd

Rendering syllabus/syllabus-final.qmd...
✗ FAILED: syllabus/syllabus-final.qmd
  Error: object 'exam_data' not found

════════════════════════════════════════
  Validation failed: 1 file(s)
════════════════════════════════════════
```

---

### 4. Enhanced Documentation Generation

**Command:** `teach init` (enhanced)

**Auto-generated documentation:**

**README.md additions:**

```markdown
## Development Workflow

### 1. Local Development
- Use `quarto preview` for live editing
- Changes reload automatically in browser

### 2. Before Committing
- Run `teach validate` to check changes
- Or rely on pre-commit hook (automatic)

### 3. Commit Changes
- Pre-commit hook validates and renders
- Fast thanks to freeze caching
- Blocks commit if errors found

### 4. Deploy
- Use `teach deploy` or `./scripts/quick-deploy.sh`
- Pre-push hook validates full site
- GitHub Actions deploys to Pages
```

**CLAUDE.md additions:**
- Quarto Freeze section
- Git Hooks documentation
- Render vs Preview comparison
- Error handling workflow

---

### 5. Teaching-Specific Commands

**New commands:**

```bash
# Preview specific week's lecture
teach preview week 5

# Validate all lectures
teach validate lectures

# Validate all assignments
teach validate assignments

# Check site health
teach check --full

# Refresh freeze cache
teach cache refresh
teach cache clear
```

---

## Implementation Plan

### Phase 1: Core Freeze Integration (v4.6.0)

- [ ] Add `execute: freeze: auto` to `teach init` template
- [ ] Update `.gitignore` to exclude `_freeze/`
- [ ] Add freeze documentation to generated docs
- [ ] Create `teach cache` commands

### Phase 2: Git Hooks (v4.6.0)

- [ ] Create hook templates in `flow-cli/templates/hooks/`
- [ ] Implement `teach hooks install` command
- [ ] Add `teach hooks uninstall` command
- [ ] Document hook behavior and bypass options

### Phase 3: Validation (v4.7.0)

- [ ] Implement `teach validate` command
- [ ] Add file filtering (lectures, assignments, all)
- [ ] Create validation script template
- [ ] Add progress indicators and colored output

### Phase 4: Enhanced Documentation (v4.7.0)

- [ ] Update `teach init` templates (README.md, CLAUDE.md)
- [ ] Add Quarto workflow guide
- [ ] Create troubleshooting section
- [ ] Add example error scenarios

### Phase 5: Teaching-Specific Helpers (v4.8.0)

- [ ] Implement `teach preview week <N>`
- [ ] Add `teach check --full` health check
- [ ] Create `teach status` enhancements
- [ ] Add freeze cache statistics

---

## Technical Specifications

### Hook Templates Location

```
flow-cli/
├── templates/
│   ├── hooks/
│   │   ├── pre-commit.template
│   │   ├── pre-push.template
│   │   └── validate-changes.sh.template
│   └── quarto/
│       ├── _quarto.yml.template
│       ├── README.md.template
│       └── CLAUDE.md.template
```

### Configuration Files

**~/.config/flow/teach.conf** (new):

```bash
# Quarto settings
TEACH_QUARTO_FREEZE=1              # Enable freeze by default
TEACH_HOOKS_AUTO_INSTALL=1         # Auto-install hooks on teach init
TEACH_VALIDATION_ON_COMMIT=1       # Render on pre-commit
TEACH_VALIDATION_SHOW_OUTPUT=1     # Show render output

# Hook behavior
TEACH_HOOK_PRE_COMMIT_RENDER=1     # Default: enabled
TEACH_HOOK_PRE_PUSH_FULL_SITE=1    # Default: enabled
```

### Error Handling

**Pre-commit hook error:**

```bash
$ git commit -m "update lecture"

Running pre-commit checks...
  ✓ YAML valid
  ✓ Syntax valid
  Rendering lectures/week-05.qmd...
  ✗ Render failed
    Error: object 'data' not found
    Line 127

Pre-commit failed: 1 error(s)
Fix errors or use: git commit --no-verify
```

**Action on error:**
1. Commit is BLOCKED
2. Changes remain staged
3. Error output shown with line numbers
4. User fixes error and retries

---

## Benefits

### For Instructors

1. **Faster Iteration** - Freeze caching makes development 10-100x faster
2. **Early Error Detection** - Catch R errors at commit time, not deploy time
3. **Cleaner History** - No broken commits in git log
4. **Confidence** - Know files work before pushing

### For flow-cli

1. **Best Practices** - Codifies proven workflows
2. **Automation** - Reduces manual setup and validation
3. **Documentation** - Auto-generates comprehensive guides
4. **Teaching Focus** - Optimized for course material workflow

---

## Backwards Compatibility

### Migration Path

**Existing projects:**

```bash
cd ~/projects/teaching/stat-545

# Update to new workflow
teach hooks install
teach cache refresh

# Optional: update configs
teach upgrade
```

**New projects:**

```bash
# Everything auto-configured
teach init stat-545
cd stat-545
quarto preview
```

### Opt-Out

Users can disable features:

```bash
# Disable freeze
export TEACH_QUARTO_FREEZE=0

# Disable hook rendering
export TEACH_HOOK_PRE_COMMIT_RENDER=0

# Skip hooks entirely
git commit --no-verify
```

---

## Success Metrics

**Performance:**
- ✅ First render: ~5-10 minutes (baseline)
- ✅ Subsequent renders: ~5-30 seconds (with freeze)
- ✅ Pre-commit validation: ~1-5 seconds per file

**Reliability:**
- ✅ Reduce failed CI builds by 80% (errors caught locally)
- ✅ Zero broken commits entering main/production
- ✅ 100% of errors shown with context and line numbers

**Adoption:**
- ✅ Auto-configured for all new `teach init` projects
- ✅ Easy migration for existing projects
- ✅ Documented in README, CLAUDE.md, flow-cli docs

---

## Examples from STAT 545

### Working Implementation

**Repository:** ~/projects/teaching/stat-545
**Branch:** draft
**Status:** ✅ Production-ready

**Files:**
- `_quarto.yml` - Freeze configuration
- `.gitignore` - Excludes _freeze/
- `scripts/setup-hooks.sh` - Hook installer
- `scripts/validate-changes.sh` - Manual validation
- `.git/hooks/pre-commit` - Auto-validation
- `.git/hooks/pre-push` - Full site check
- `README.md` - Complete workflow guide
- `CLAUDE.md` - Technical documentation

**Proven Results:**
- 50+ commits with automatic validation
- Zero broken commits reached production
- Render time: 10 minutes → 30 seconds (average)
- Hook overhead: ~2 seconds per commit

---

## Related Work

### Existing flow-cli Features

- ✅ `teach init` - Project scaffolding
- ✅ `teach deploy` - GitHub Pages deployment
- ✅ `teach status` - Semester tracking
- ✅ `teach archive` - Semester archival

### New Dependencies

- Quarto CLI (already required for teaching)
- Git (already required)
- No new npm packages
- No new Python dependencies

### Integration Points

```bash
# teach init creates:
_quarto.yml (with freeze)
.gitignore (excludes _freeze/)
scripts/setup-hooks.sh
scripts/validate-changes.sh
README.md (with workflow)
CLAUDE.md (with freeze docs)

# teach hooks install runs:
./scripts/setup-hooks.sh

# teach validate runs:
./scripts/validate-changes.sh

# teach deploy still works:
Same as before, but:
- Pre-push hook validates
- Faster builds with freeze
```

---

## Questions & Discussion

### Q: Should freeze be opt-out or opt-in?

**Recommendation:** Opt-out (enabled by default)

**Rationale:**
- Massive performance benefit
- No drawbacks for solo instructors
- Easy to disable if conflicts arise
- Proven in STAT 545 production

### Q: Should hooks auto-install or require manual setup?

**Recommendation:** Auto-install with prompt

```bash
teach init stat-545

# Prompts:
Install git hooks for automatic validation? [Y/n] y

Hooks installed:
✓ pre-commit (validates changed files)
✓ pre-push (validates full site)

Disable anytime with:
  teach hooks uninstall
  git commit --no-verify
```

### Q: What about multi-author teaching repos?

**Recommendation:** Document freeze conflicts

Add to README.md:
> **Note:** This project uses Quarto freeze for performance. The `_freeze/` directory is gitignored to prevent conflicts. Each contributor maintains their own local cache.

### Q: Should validation be mandatory or optional?

**Recommendation:** Mandatory by default, easy bypass

**Rationale:**
- Prevents broken commits (quality)
- Fast enough with freeze (~1-5s)
- Clear error messages help debugging
- Always have `--no-verify` escape hatch

---

## Next Steps

1. **Review** - Gather feedback from flow-cli maintainers
2. **Prototype** - Test integration in flow-cli/dev branch
3. **Document** - Update flow-cli/docs with new features
4. **Implement** - Phase 1 (Freeze + Hooks) in v4.6.0
5. **Test** - Validate with STAT 545 and other courses
6. **Release** - Announce in CHANGELOG.md

---

## References

**STAT 545 Implementation:**
- Repository: ~/projects/teaching/stat-545
- Scripts: scripts/setup-hooks.sh, scripts/validate-changes.sh
- Docs: README.md, CLAUDE.md
- Config: _quarto.yml, .gitignore

**Quarto Documentation:**
- Freeze: https://quarto.org/docs/projects/code-execution.html#freeze
- Profiles: https://quarto.org/docs/projects/profiles.html

**flow-cli Context:**
- Teaching arch: docs/TEACHING-SYSTEM-ARCHITECTURE.md
- Conventions: docs/CONVENTIONS.md
- Philosophy: docs/PHILOSOPHY.md

---

**Author:** DT
**Reviewers:** TBD
**Approval:** Pending
