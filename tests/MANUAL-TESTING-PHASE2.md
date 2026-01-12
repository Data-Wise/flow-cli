# Phase 2 Manual Testing Instructions

**Feature:** Intelligent Quarto Migration Workflow
**Phase:** Phase 2 - Migration Logic
**Date:** 2026-01-12
**Estimated Time:** 45-60 minutes

---

## Prerequisites

### Setup

1. **Load the feature branch:**
   ```bash
   cd ~/.git-worktrees/flow-cli-teach-init-migration
   source flow.plugin.zsh
   ```

2. **Verify Phase 1 tests pass:**
   ```bash
   ./tests/test-teach-init-phase1.zsh
   # Expected: 13/13 tests passing
   ```

3. **Create test workspace:**
   ```bash
   mkdir -p ~/tmp/teach-init-tests
   cd ~/tmp/teach-init-tests
   ```

---

## Test Suite 1: Dry-Run Mode (5 min)

### Test 1.1: Dry-Run on Quarto Project

**Setup:**
```bash
cd ~/projects/teaching/stat-545
```

**Execute:**
```bash
teach-init --dry-run "STAT 545"
```

**Expected Output:**
```
🔍 DRY RUN MODE - No changes will be made

┌────────────────────────────────────────────────────────────┐
│ Migration Plan for: STAT 545
├────────────────────────────────────────────────────────────┤
│
│ Detection:
│   ✅ Git repository found
│   ✅ Current branch: draft
│   ✅ Project type: Quarto website
│
│ Validation:
│   ✅ _quarto.yml found
│   ✅ index.qmd found
│   ⚠️  renv/ detected (will prompt to exclude)
│
│ Actions that would be taken:
│   1. Create rollback tag: january-2026-pre-migration
│   2. Rename draft → production
│   3. Create draft branch from production
│   4. Add .flow/teach-config.yml
│   5. Add scripts/quick-deploy.sh
│   6. Add scripts/semester-archive.sh
│   7. Add .github/workflows/deploy.yml
│   8. Prompt for semester dates
│   9. Prompt for GitHub push (optional)
│  10. Generate MIGRATION-COMPLETE.md
│
│ Estimated time: ~3 minutes
│
│ To execute for real:
│   teach-init "STAT 545"
│
└────────────────────────────────────────────────────────────┘
```

**Validation:**
- [ ] Shows "DRY RUN MODE" message
- [ ] Detects "Quarto website" correctly
- [ ] Shows _quarto.yml and index.qmd found
- [ ] Shows renv/ warning (if present)
- [ ] Lists all 10 migration steps
- [ ] No files created (verify: `ls -la .flow` fails)

---

## Test Suite 2: Project Type Detection (5 min)

### Test 2.1: Detect Quarto Project

**Setup:**
```bash
cd ~/tmp/teach-init-tests
mkdir test-quarto && cd test-quarto
git init
touch _quarto.yml index.qmd
git add . && git commit -m "Initial"
```

**Execute:**
```bash
teach-init --dry-run "Test Quarto"
```

**Expected:**
- [ ] Shows "Project type: Quarto website"
- [ ] Shows validation checks for _quarto.yml and index.qmd

**Cleanup:**
```bash
cd .. && rm -rf test-quarto
```

---

### Test 2.2: Detect Generic Repository

**Setup:**
```bash
mkdir test-generic && cd test-generic
git init
echo "# Test" > README.md
git add . && git commit -m "Initial"
```

**Execute:**
```bash
teach-init --dry-run "Test Generic"
```

**Expected:**
- [ ] Shows "Project type: Generic git repository"
- [ ] Shows standard migration (not Quarto-specific)

**Cleanup:**
```bash
cd .. && rm -rf test-generic
```

---

## Test Suite 3: Quarto Validation (10 min)

### Test 3.1: Valid Quarto Project

**Setup:**
```bash
mkdir test-valid-quarto && cd test-valid-quarto
git init
touch _quarto.yml index.qmd
git add . && git commit -m "Initial"
```

**Execute:**
```bash
# Source the plugin to get functions
source ~/.git-worktrees/flow-cli-teach-init-migration/flow.plugin.zsh

# Run validation
_teach_validate_quarto_project && echo "✅ PASS" || echo "❌ FAIL"
```

**Expected:**
- [ ] Validation passes (exit code 0)
- [ ] Shows "✅ PASS"

**Cleanup:**
```bash
cd .. && rm -rf test-valid-quarto
```

---

### Test 3.2: Missing _quarto.yml

**Setup:**
```bash
mkdir test-missing-quarto && cd test-missing-quarto
git init
touch index.qmd
git add . && git commit -m "Initial"
```

**Execute:**
```bash
source ~/.git-worktrees/flow-cli-teach-init-migration/flow.plugin.zsh
_teach_validate_quarto_project 2>&1
```

**Expected:**
```
Project validation failed:
  Missing _quarto.yml
```

**Validation:**
- [ ] Shows validation error
- [ ] Lists "Missing _quarto.yml"
- [ ] Returns exit code 1

**Cleanup:**
```bash
cd .. && rm -rf test-missing-quarto
```

---

### Test 3.3: Missing index.qmd

**Setup:**
```bash
mkdir test-missing-index && cd test-missing-index
git init
touch _quarto.yml
git add . && git commit -m "Initial"
```

**Execute:**
```bash
source ~/.git-worktrees/flow-cli-teach-init-migration/flow.plugin.zsh
_teach_validate_quarto_project 2>&1
```

**Expected:**
```
Project validation failed:
  Missing index.qmd (homepage)
```

**Validation:**
- [ ] Shows validation error
- [ ] Lists "Missing index.qmd (homepage)"
- [ ] Returns exit code 1

**Cleanup:**
```bash
cd .. && rm -rf test-missing-index
```

---

## Test Suite 4: Migration Strategy 1 - Convert Existing (15 min)

### Test 4.1: Successful Strategy 1 Migration

**Setup:**
```bash
cd ~/tmp/teach-init-tests
mkdir test-strategy1 && cd test-strategy1
git init

# Create minimal Quarto project
cat > _quarto.yml << 'EOF'
project:
  type: website
EOF

cat > index.qmd << 'EOF'
# Test Course
Welcome to the test course.
EOF

git add . && git commit -m "Initial commit"
```

**Execute:**
```bash
source ~/.git-worktrees/flow-cli-teach-init-migration/flow.plugin.zsh

# Run migration (simulate user input)
teach-init "Test Course" << 'INPUT'
1
y
2025-01-13
n
n
INPUT
```

**Expected Output Flow:**
1. Detection: "Detected: Quarto website"
2. Validation: "✅ Validation passed"
3. Strategy menu: Shows 3 options
4. Confirmation: "This will:" followed by 4 steps
5. Progress messages:
   - "Creating rollback tag: january-2026-pre-migration"
   - "Renaming main → production..."
   - "Creating draft branch..."
   - "Installing templates..."
   - "Offering GitHub push..."
   - "Generating documentation..."
6. Success: "✅ Migration complete"

**Validation:**
```bash
# Check branches
git branch -a
# Expected: * draft, production

# Check files
ls -la .flow/teach-config.yml
ls -la scripts/quick-deploy.sh
ls -la scripts/semester-archive.sh
ls -la .github/workflows/deploy.yml
ls -la MIGRATION-COMPLETE.md

# Check rollback tag
git tag -l "*pre-migration"
# Expected: january-2026-pre-migration

# Verify on draft branch
git branch --show-current
# Expected: draft
```

**Checklist:**
- [ ] Branches created: draft, production
- [ ] Current branch: draft
- [ ] Rollback tag exists: *-pre-migration
- [ ] Files created:
  - [ ] .flow/teach-config.yml
  - [ ] scripts/quick-deploy.sh (executable)
  - [ ] scripts/semester-archive.sh (executable)
  - [ ] .github/workflows/deploy.yml
  - [ ] MIGRATION-COMPLETE.md
- [ ] MIGRATION-COMPLETE.md contains course name
- [ ] Config has semester dates

**Cleanup:**
```bash
cd .. && rm -rf test-strategy1
```

---

### Test 4.2: Strategy 1 with Cancellation

**Setup:**
```bash
mkdir test-strategy1-cancel && cd test-strategy1-cancel
git init
touch _quarto.yml index.qmd
git add . && git commit -m "Initial"
```

**Execute:**
```bash
source ~/.git-worktrees/flow-cli-teach-init-migration/flow.plugin.zsh

# Run migration and cancel at confirmation
teach-init "Test Cancel" << 'INPUT'
1
n
INPUT
```

**Expected:**
```
Choose migration strategy:
  1. Convert existing branch → production (preserve history)
  ...

⚠️  This will:
  1. Create rollback tag (safe recovery point)
  2. Rename main → production
  3. Create new draft branch from production
  4. Add .flow/teach-config.yml and scripts/

Continue? [y/N] n
Cancelled
```

**Validation:**
```bash
# Verify no changes made
git branch
# Expected: * main (only)

ls .flow 2>/dev/null
# Expected: No such file or directory

git tag -l
# Expected: (empty)
```

**Checklist:**
- [ ] Shows "Cancelled" message
- [ ] No branches created
- [ ] No files created
- [ ] No tags created

**Cleanup:**
```bash
cd .. && rm -rf test-strategy1-cancel
```

---

## Test Suite 5: Migration Strategy 2 - Parallel Branches (10 min)

### Test 5.1: Successful Strategy 2 Migration

**Setup:**
```bash
cd ~/tmp/teach-init-tests
mkdir test-strategy2 && cd test-strategy2
git init
touch _quarto.yml index.qmd
git add . && git commit -m "Initial"
```

**Execute:**
```bash
source ~/.git-worktrees/flow-cli-teach-init-migration/flow.plugin.zsh

# Run migration with Strategy 2
teach-init "Test Strategy 2" << 'INPUT'
2
y
2025-01-13
n
n
INPUT
```

**Validation:**
```bash
# Check branches
git branch -a
# Expected: main, * draft, production

# Verify main branch unchanged
git checkout main
git log --oneline
# Expected: Only "Initial" commit

# Verify draft and production have workflow files
git checkout draft
ls .flow/teach-config.yml
```

**Checklist:**
- [ ] All 3 branches exist: main, draft, production
- [ ] Main branch unchanged (only initial commit)
- [ ] Draft and production have workflow files
- [ ] Current branch: draft

**Cleanup:**
```bash
cd .. && rm -rf test-strategy2
```

---

## Test Suite 6: Migration Strategy 3 - Fresh Start (10 min)

### Test 5.2: Successful Strategy 3 Migration

**Setup:**
```bash
cd ~/tmp/teach-init-tests
mkdir test-strategy3 && cd test-strategy3
git init
touch _quarto.yml index.qmd
git add . && git commit -m "Initial commit"
echo "More content" >> index.qmd
git add . && git commit -m "Second commit"
```

**Execute:**
```bash
source ~/.git-worktrees/flow-cli-teach-init-migration/flow.plugin.zsh

# Run migration with Strategy 3
teach-init "Test Strategy 3" << 'INPUT'
3
y
2025-01-13
n
n
INPUT
```

**Expected:**
- Creates archive tag (not rollback tag)
- Shows "✅ Migration complete (fresh start)"
- Shows "💡 Original history preserved in tag: ..."

**Validation:**
```bash
# Check archive tag
git tag -l "*archive"
# Expected: january-2026-archive

# Check production branch is orphan (no parent)
git checkout production
git log --oneline
# Expected: Only 1 commit (Initial teaching workflow)

# Check draft branch
git checkout draft
git log --oneline
# Expected: Same as production (1 commit)

# Verify original history in archive
git log january-2026-archive --oneline
# Expected: Shows "Initial commit" and "Second commit"
```

**Checklist:**
- [ ] Archive tag exists
- [ ] Production branch is orphan (1 commit only)
- [ ] Draft created from production
- [ ] Original history preserved in archive tag
- [ ] Message shows "fresh start"

**Cleanup:**
```bash
cd .. && rm -rf test-strategy3
```

---

## Test Suite 7: renv Handling (5 min)

### Test 7.1: renv Detection and Exclusion

**Setup:**
```bash
cd ~/tmp/teach-init-tests
mkdir test-renv && cd test-renv
git init
touch _quarto.yml index.qmd
mkdir -p renv/library
git add . && git commit -m "Initial"
```

**Execute:**
```bash
source ~/.git-worktrees/flow-cli-teach-init-migration/flow.plugin.zsh

# Run migration (answer Y to renv exclusion)
teach-init "Test renv" << 'INPUT'
1
y
2025-01-13
n
n
y
INPUT
```

**Expected:**
During migration, should see:
```
⚠️  Detected renv/ directory
  R package management with symlinks (not suitable for git)

  Exclude renv/ from git? [Y/n]: y
  ✅ Added renv/ to .gitignore
```

**Validation:**
```bash
# Check .gitignore
grep "^renv/$" .gitignore
# Expected: renv/

# Verify renv not tracked
git status --short
# Expected: No renv/ files listed
```

**Checklist:**
- [ ] Shows renv warning
- [ ] Prompts to exclude
- [ ] Adds renv/ to .gitignore
- [ ] renv/ not tracked by git

**Cleanup:**
```bash
cd .. && rm -rf test-renv
```

---

### Test 7.2: renv Already Excluded

**Setup:**
```bash
mkdir test-renv-existing && cd test-renv-existing
git init
touch _quarto.yml index.qmd
mkdir -p renv/library
echo "renv/" > .gitignore
git add . && git commit -m "Initial"
```

**Execute:**
```bash
source ~/.git-worktrees/flow-cli-teach-init-migration/flow.plugin.zsh

# Run migration
teach-init "Test renv existing" << 'INPUT'
1
y
2025-01-13
n
n

INPUT
```

**Expected:**
Should see:
```
ℹ️  renv/ already in .gitignore
```

**Validation:**
```bash
# Check .gitignore has only one renv/ entry
grep -c "^renv/$" .gitignore
# Expected: 1
```

**Checklist:**
- [ ] Shows "already in .gitignore" message
- [ ] Does not duplicate entry

**Cleanup:**
```bash
cd .. && rm -rf test-renv-existing
```

---

## Test Suite 8: Rollback on Error (10 min)

### Test 8.1: Simulate Template Installation Failure

**Setup:**
```bash
cd ~/tmp/teach-init-tests
mkdir test-rollback && cd test-rollback
git init
touch _quarto.yml index.qmd
git add . && git commit -m "Initial"
```

**Execute:**
```bash
source ~/.git-worktrees/flow-cli-teach-init-migration/flow.plugin.zsh

# Temporarily break FLOW_PLUGIN_DIR to cause template failure
export FLOW_PLUGIN_DIR="/nonexistent/path"

# Run migration (should fail and rollback)
teach-init "Test Rollback" << 'INPUT'
1
y
2025-01-13
n
INPUT
```

**Expected:**
Should see rollback sequence:
```
Installing templates...
cp: /nonexistent/path/lib/templates/teaching/quick-deploy.sh: No such file or directory

Migration failed - rolling back to january-2026-pre-migration

  ✅ Reset to tag: january-2026-pre-migration
  ✅ Removed .flow/ directory
  ✅ Removed scripts/ directory
  ✅ Removed .github/workflows/deploy.yml
  ✅ Deleted rollback tag

Your repository is back to its original state.
```

**Validation:**
```bash
# Check branch
git branch --show-current
# Expected: main (reverted)

# Check no workflow files
ls .flow 2>/dev/null
# Expected: No such file or directory

# Check no tags
git tag -l
# Expected: (empty)

# Check git log
git log --oneline
# Expected: Only "Initial" commit

# Restore FLOW_PLUGIN_DIR
export FLOW_PLUGIN_DIR="$HOME/.git-worktrees/flow-cli-teach-init-migration"
```

**Checklist:**
- [ ] Shows "Migration failed" message
- [ ] Shows rollback steps
- [ ] Reverts to original branch (main)
- [ ] Removes all created files
- [ ] Deletes rollback tag
- [ ] Repository in original state

**Cleanup:**
```bash
cd .. && rm -rf test-rollback
```

---

## Test Suite 9: GitHub Push Integration (10 min)

### Test 9.1: GitHub Push - No Existing Remote

**Setup:**
```bash
cd ~/tmp/teach-init-tests
mkdir test-github-new && cd test-github-new
git init
touch _quarto.yml index.qmd
git add . && git commit -m "Initial"
```

**Execute:**
```bash
source ~/.git-worktrees/flow-cli-teach-init-migration/flow.plugin.zsh

# Run migration (skip actual push)
teach-init "Test GitHub" << 'INPUT'
1
y
2025-01-13
n
n
n
INPUT
```

**Expected:**
Should see:
```
GitHub Integration (Optional)
  Push to GitHub remote? [y/N]: n
  ℹ️  Skipped - push manually later:
     git remote add origin <url>
     git push -u origin draft production
```

**Validation:**
```bash
# Verify no remote added
git remote
# Expected: (empty)
```

**Checklist:**
- [ ] Shows GitHub integration prompt
- [ ] Shows manual push instructions when skipped
- [ ] No remote added when skipped

**Cleanup:**
```bash
cd .. && rm -rf test-github-new
```

---

### Test 9.2: GitHub Push - Existing Remote (Same URL)

**Setup:**
```bash
mkdir test-github-existing && cd test-github-existing
git init
touch _quarto.yml index.qmd
git add . && git commit -m "Initial"

# Add fake remote
git remote add origin https://github.com/test/test.git
```

**Execute:**
```bash
source ~/.git-worktrees/flow-cli-teach-init-migration/flow.plugin.zsh

# Run migration (answer Y to push, provide same URL)
# Note: This will fail to push (no real remote), but tests the logic
teach-init "Test GitHub Existing" << 'INPUT'
1
y
2025-01-13
n
https://github.com/test/test.git
INPUT
```

**Expected:**
Should see:
```
GitHub Integration (Optional)
  Push to GitHub remote? [y/N]: y
  GitHub remote URL: https://github.com/test/test.git
  ℹ️  Remote origin already configured
  ... (push output or error)
```

**Validation:**
```bash
# Verify remote unchanged
git remote get-url origin
# Expected: https://github.com/test/test.git
```

**Checklist:**
- [ ] Detects existing remote
- [ ] Shows "already configured" message
- [ ] Attempts to push (may fail without real remote)

**Cleanup:**
```bash
cd .. && rm -rf test-github-existing
```

---

## Test Suite 10: Documentation Generation (5 min)

### Test 10.1: MIGRATION-COMPLETE.md Generation

**Setup:**
```bash
cd ~/tmp/teach-init-tests
mkdir test-docs && cd test-docs
git init
touch _quarto.yml index.qmd
git add . && git commit -m "Initial"
```

**Execute:**
```bash
source ~/.git-worktrees/flow-cli-teach-init-migration/flow.plugin.zsh

teach-init "Documentation Test" << 'INPUT'
1
y
2025-01-13
n
n
INPUT
```

**Validation:**
```bash
# Check file exists
test -f MIGRATION-COMPLETE.md && echo "✅ File exists"

# Check file content
cat MIGRATION-COMPLETE.md
```

**Expected Content:**
```markdown
# Documentation Test Teaching Workflow Migration - COMPLETE ✅

**Date:** 2026-01-12
**Status:** Successfully migrated to flow-cli teaching workflow v2.0
**Branch:** draft (ready for editing)

---

## Migration Summary

### What Was Done

1. **Git Repository** ✅
   - Pre-migration tag: january-2026-pre-migration
   - Branch structure: draft + production

2. **Teaching Workflow Configured** ✅
   - Config: .flow/teach-config.yml
   - Course: Documentation Test
   - Semester: spring 2025
   - Dates: 2025-01-13 to 2025-05-06

3. **Deployment Tools Created** ✅
   ...
```

**Checklist:**
- [ ] File created: MIGRATION-COMPLETE.md
- [ ] Contains course name
- [ ] Contains migration date
- [ ] Contains semester dates (if configured)
- [ ] Contains daily workflow section
- [ ] Contains next steps
- [ ] Markdown format valid

**Cleanup:**
```bash
cd .. && rm -rf test-docs
```

---

## Test Suite 11: Edge Cases (5 min)

### Test 11.1: Invalid Choice Handling

**Setup:**
```bash
cd ~/tmp/teach-init-tests
mkdir test-invalid && cd test-invalid
git init
touch _quarto.yml index.qmd
git add . && git commit -m "Initial"
```

**Execute:**
```bash
source ~/.git-worktrees/flow-cli-teach-init-migration/flow.plugin.zsh

# Try invalid strategy choice
teach-init "Test Invalid" << 'INPUT'
5
INPUT
```

**Expected:**
```
Choose migration strategy:
  1. Convert existing branch → production (preserve history)
  2. Create parallel branches (keep existing + add draft/production)
  3. Fresh start (tag current, start new structure)

Choice [1/2/3]: 5
Invalid choice
```

**Validation:**
```bash
# Verify no changes made
git branch
# Expected: * main (only)

ls .flow 2>/dev/null
# Expected: No such file or directory
```

**Checklist:**
- [ ] Shows "Invalid choice" message
- [ ] Exits cleanly (no error)
- [ ] No changes made to repository

**Cleanup:**
```bash
cd .. && rm -rf test-invalid
```

---

## Test Suite 12: Integration with STAT 545 (Real Project) (5 min)

### Test 12.1: Dry-Run on STAT 545

**Execute:**
```bash
cd ~/projects/teaching/stat-545
source ~/.git-worktrees/flow-cli-teach-init-migration/flow.plugin.zsh
teach-init --dry-run "STAT 545 Real"
```

**Validation:**
- [ ] Detects Quarto website
- [ ] Shows validation passed
- [ ] Shows renv/ warning (if present)
- [ ] Shows all 10 steps
- [ ] No files created (verify: no new files in git status)

---

## Summary Checklist

### Phase 2 Features Tested

**Detection & Routing:**
- [ ] Test 2.1: Detects Quarto projects correctly
- [ ] Test 2.2: Detects generic projects correctly
- [ ] Dry-run shows correct project type

**Validation:**
- [ ] Test 3.1: Passes validation for valid Quarto
- [ ] Test 3.2: Fails validation without _quarto.yml
- [ ] Test 3.3: Fails validation without index.qmd

**Migration Strategies:**
- [ ] Test 4.1: Strategy 1 (convert) succeeds
- [ ] Test 4.2: Strategy 1 cancellation works
- [ ] Test 5.1: Strategy 2 (parallel) succeeds
- [ ] Test 5.2: Strategy 3 (fresh) succeeds

**Safety Features:**
- [ ] Test 7.1: renv detection and exclusion
- [ ] Test 7.2: renv already excluded handling
- [ ] Test 8.1: Rollback on error works correctly

**GitHub Integration:**
- [ ] Test 9.1: Skip GitHub push works
- [ ] Test 9.2: Existing remote handling works

**Documentation:**
- [ ] Test 10.1: MIGRATION-COMPLETE.md generated correctly

**Edge Cases:**
- [ ] Test 11.1: Invalid choice handled gracefully

**Real World:**
- [ ] Test 12.1: STAT 545 dry-run works

---

## Test Results Summary

**Date:** _____________
**Tester:** _____________
**Environment:** _____________

**Total Tests:** 18
**Passed:** _____
**Failed:** _____
**Skipped:** _____

### Failed Tests (if any)

| Test | Issue | Notes |
|------|-------|-------|
|      |       |       |

---

## Notes

- All tests should complete in ~60 minutes
- Save test output for debugging: `teach-init ... 2>&1 | tee test-output.log`
- If a test fails, check:
  - FLOW_PLUGIN_DIR is set correctly
  - flow.plugin.zsh is sourced
  - git is initialized in test directory
- Clean up all test directories after completion
- Report any unexpected behavior or error messages

---

## Final Cleanup

```bash
# Remove all test directories
cd ~/tmp
rm -rf teach-init-tests

# Verify Phase 1 tests still pass
cd ~/.git-worktrees/flow-cli-teach-init-migration
./tests/test-teach-init-phase1.zsh
```

**Expected:** All 13 Phase 1 tests passing, no regressions.

---

## Success Criteria

Phase 2 is considered **PASSING** if:

1. ✅ All 18 manual tests pass
2. ✅ All 13 Phase 1 unit tests still pass
3. ✅ STAT 545 dry-run works correctly
4. ✅ No data loss in rollback tests
5. ✅ All 3 migration strategies complete successfully
6. ✅ GitHub integration works (even when skipped)
7. ✅ Documentation generation produces valid markdown

**Phase 2 Status:** ⬜ NOT TESTED | ⬜ PASSING | ⬜ FAILING

**Sign-off:** _________________ **Date:** _____________
