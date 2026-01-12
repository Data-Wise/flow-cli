# Teaching Workflow v2.0 - Testing Instructions

**Version:** Increment 1 (Core Deployment)
**Branch:** `feature/teaching-workflow`
**Status:** Ready for Testing
**Estimated Time:** 30-45 minutes

---

## 🎯 Testing Overview

This document provides step-by-step instructions for testing the teaching workflow implementation before merging to `dev` branch.

**What We're Testing:**
- ✅ Core functionality (teach-init, work, deployment)
- ✅ Branch safety warnings
- ✅ Configuration validation
- ✅ Automation scripts
- ✅ Documentation accuracy

**Testing Levels:**
1. **Automated Tests** (5 min) - Unit and integration tests
2. **Manual Integration** (15-20 min) - Real workflow testing
3. **Documentation Verification** (10 min) - Docs match behavior

---

## 📋 Prerequisites

### Required Tools

```bash
# Check prerequisites
command -v git && echo "✅ Git installed" || echo "❌ Git missing"
command -v yq && echo "✅ yq installed" || echo "❌ yq missing"
command -v zsh && echo "✅ ZSH installed" || echo "✅ ZSH installed"
```

**Install Missing Tools:**
```bash
brew install yq
```

### Environment Setup

```bash
# 1. Navigate to feature branch worktree
cd ~/.git-worktrees/flow-cli-teaching-workflow

# 2. Verify branch
git branch --show-current
# Expected: feature/teaching-workflow

# 3. Ensure clean state
git status
# Expected: nothing to commit, working tree clean

# 4. Source the plugin (loads latest changes)
source flow.plugin.zsh
```

---

## 🧪 Phase 1: Automated Tests (5 minutes)

### 1.1 Run Basic Test Suite

```bash
./tests/test-teach-init.zsh
```

**Expected Output:**
```
╔════════════════════════════════════════════════════════════╗
║  Teaching Workflow Test Suite                              ║
╚════════════════════════════════════════════════════════════╝

✓ File exists: .../lib/templates/teaching/quick-deploy.sh
✓ File exists: .../lib/templates/teaching/semester-archive.sh
✓ File exists: .../lib/templates/teaching/exam-to-qti.sh
✓ File exists: .../lib/templates/teaching/deploy.yml.template
✓ File exists: .../lib/templates/teaching/teach-config.yml.template
✓ teach-init command available
✓ Equals: teaching
✓ Equals: 0
✓ Equals: 1

╔════════════════════════════════════════════════════════════╗
║  Test Summary                                              ║
╚════════════════════════════════════════════════════════════╝

  Tests run:    9
  Passed:       9
  Failed:       0

✓ All tests passed!
```

**✅ Pass Criteria:** All 9 tests passing, 0 failures

**❌ Fail Actions:**
- Review test output for specific failures
- Check file exists in `lib/templates/teaching/`
- Verify `teach-init` command loaded
- Report issue with error details

---

### 1.2 Run Comprehensive Test Suite

```bash
./tests/test-teaching-workflow-comprehensive.zsh
```

**Expected Output:**
```
╔════════════════════════════════════════════════════════════╗
║  Teaching Workflow - Comprehensive Test Suite             ║
╚════════════════════════════════════════════════════════════╝

━━━ Category 1: Project Detection ━━━
✓ Equals: teaching
✓ Equals: teaching
✓ Equals: teaching
✓ Equals: teaching

━━━ Category 2: Config Validation ━━━
✓ Equals: 0
✓ Equals: 0
✓ Equals: 1
✓ Equals: 1
✓ Equals: 1
✓ Equals: 0

━━━ Category 3: Template Files ━━━
✓ File exists: .../quick-deploy.sh
[... more tests ...]

╔════════════════════════════════════════════════════════════╗
║  Test Summary                                              ║
╚════════════════════════════════════════════════════════════╝

  Tests run:    32
  Passed:       32
  Failed:       0
  Skipped:      0

  Coverage:     100%

✓ All tests passed!
```

**✅ Pass Criteria:** All 32 tests passing, 100% coverage

**❌ Fail Actions:**
- Note which category failed
- Check test output for error details
- Verify specific component (detection, validation, etc.)
- Report with category and error message

---

### 1.3 Run All Existing Tests (Regression Check)

```bash
./tests/run-all.sh
```

**Expected:** All existing tests still pass (no regressions)

**✅ Pass Criteria:** No test regressions introduced

**❌ Fail Actions:**
- Identify which existing test broke
- Verify teaching workflow didn't interfere with other features
- Check project detection priority order
- Report regression with test name

---

## 🔬 Phase 2: Manual Integration Testing (15-20 minutes)

### 2.1 Test: Initialize New Course

**Scenario:** Initialize teaching workflow in a brand new course

**Steps:**

```bash
# 1. Create test course directory
mkdir -p /tmp/test-teaching-course
cd /tmp/test-teaching-course

# 2. Initialize git
git init
git config user.email "test@example.com"
git config user.name "Test User"

# 3. Create initial content
echo "# Test Course" > README.md
git add README.md
git commit -m "Initial commit"

# 4. Initialize teaching workflow
teach-init "Test Course"
```

**Interactive Prompts:**
```
Choose migration strategy:
  1. In-place conversion
  2. Two-branch setup

Choice [1/2]: 1

Continue? [y/N] y
```

**Expected Results:**

- ✅ Migration strategy prompt appears
- ✅ Templates installed in `scripts/` directory
- ✅ Configuration created at `.flow/teach-config.yml`
- ✅ GitHub Actions workflow created at `.github/workflows/deploy.yml`
- ✅ `production` and `draft` branches created
- ✅ Git commit created with message containing "Initialize teaching workflow"
- ✅ Scripts are executable (`ls -la scripts/`)

**Verify:**

```bash
# Check branches
git branch -a
# Expected: draft, production

# Check files created
ls -la .flow/teach-config.yml
ls -la scripts/quick-deploy.sh
ls -la scripts/semester-archive.sh
ls -la .github/workflows/deploy.yml

# Verify executability
test -x scripts/quick-deploy.sh && echo "✅ Executable" || echo "❌ Not executable"
test -x scripts/semester-archive.sh && echo "✅ Executable" || echo "❌ Not executable"

# Check config content
cat .flow/teach-config.yml
# Expected: Contains course.name, branches.draft, branches.production
```

**✅ Pass Criteria:**
- All files created
- Branches exist
- Scripts executable
- Config valid YAML
- Commit created

**❌ Fail Actions:**
- Note missing files/branches
- Check terminal output for errors
- Verify yq installed (`command -v yq`)
- Report with specific missing component

---

### 2.2 Test: Branch Safety Warning

**Scenario:** Work command warns when on production branch

**Steps:**

```bash
# Still in /tmp/test-teaching-course

# 1. Switch to production branch
git checkout production

# 2. Start work session
work test-course
```

**Expected Interactive Prompt:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  WARNING: You are on PRODUCTION branch
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Branch: production
  Students see this branch!

  Recommended: Switch to draft branch for edits
  Draft branch: draft

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Continue on production anyway? [y/N]
```

**Test Actions:**

1. **Type `n` (switch to draft)**
   ```bash
   n
   ```

   **Expected:**
   - Message: "Switching to draft branch: draft"
   - Git checkout happens
   - Editor opens (Ctrl+C to cancel)
   - Current branch is now `draft`

2. **Verify branch switched:**
   ```bash
   git branch --show-current
   # Expected: draft
   ```

**✅ Pass Criteria:**
- Warning displays with red color/emoji
- Prompt appears with timeout
- Selecting 'n' switches to draft
- Editor opens after switch

**❌ Fail Actions:**
- If no warning: Check config exists
- If no prompt: Verify timeout works
- If switch fails: Check git state
- Report with behavior observed

---

### 2.3 Test: Safe Work on Draft Branch

**Scenario:** No warning when working on draft branch

**Steps:**

```bash
# Still in /tmp/test-teaching-course

# 1. Ensure on draft branch
git checkout draft

# 2. Start work session
work test-course
```

**Expected Output:**
```
📚 Test Course
  Branch: draft

Shortcuts loaded:
  test-course → work test-course
  test-coursed → ./scripts/quick-deploy.sh

[Editor opens]
```

**Expected Results:**

- ✅ No warning displayed
- ✅ Course name shown
- ✅ Current branch shown (draft)
- ✅ Shortcuts displayed
- ✅ Editor opens (Ctrl+C to cancel)

**✅ Pass Criteria:**
- Clean output (no warnings)
- Course context displayed
- Shortcuts loaded
- Editor launches

**❌ Fail Actions:**
- If warning appears: Check branch detection logic
- If no shortcuts: Verify config shortcuts section
- If no editor: Check EDITOR variable
- Report with actual output

---

### 2.4 Test: Quick Deployment Script

**Scenario:** Deploy changes from draft to production

**Steps:**

```bash
# Still in /tmp/test-teaching-course

# 1. Ensure on draft branch
git checkout draft

# 2. Make a change
echo "## Week 1: Introduction" > lectures.md
git add lectures.md
git commit -m "Add week 1 lecture"

# 3. Run deployment script
./scripts/quick-deploy.sh
```

**Expected Output:**
```
🚀 Quick Deploy: draft → production

Merging draft...
Pushing to remote...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Deployed to production in Xs
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🌐 Site: https://data-wise.github.io/test-course
⏳ GitHub Actions deploying (usually < 2 min)

💡 Tip: Check deployment status at:
   https://github.com/.../actions
```

**Expected Results:**

- ✅ Deployment completes successfully
- ✅ Duration displayed (< 120 seconds for local merge)
- ✅ Returns to draft branch after deploy
- ✅ Production branch has the new commit
- ✅ Draft branch unchanged

**Verify:**

```bash
# Check current branch (should be draft)
git branch --show-current
# Expected: draft

# Check production has the commit
git log production --oneline -1
# Expected: Shows "Add week 1 lecture" or merge commit

# Verify file exists on production
git show production:lectures.md
# Expected: Shows "## Week 1: Introduction"
```

**✅ Pass Criteria:**
- Script completes without errors
- Merge successful
- Returns to draft branch
- Production updated
- Timing displayed

**❌ Fail Actions:**
- If "Must be on draft branch": Check current branch
- If merge conflict: Note error handling
- If push fails: Expected (no remote), note behavior
- Report with error details

---

### 2.5 Test: Deployment Safety (Wrong Branch)

**Scenario:** Script rejects deployment from production branch

**Steps:**

```bash
# Still in /tmp/test-teaching-course

# 1. Switch to production branch
git checkout production

# 2. Try to deploy
./scripts/quick-deploy.sh
```

**Expected Output:**
```
❌ Must be on draft branch
Current branch: production
Run: git checkout draft
```

**Expected Results:**

- ✅ Script exits with error
- ✅ Error message clear and actionable
- ✅ Suggests correct command
- ✅ Exit code non-zero

**Verify:**

```bash
# Check exit code
./scripts/quick-deploy.sh
echo $?
# Expected: Non-zero (1 or higher)
```

**✅ Pass Criteria:**
- Script rejects deployment
- Error message helpful
- Non-zero exit code
- No changes made

**❌ Fail Actions:**
- If deployment proceeds: Critical safety bug
- If unclear error: Note messaging issue
- Report immediately if safety check fails

---

### 2.6 Test: Configuration Validation

**Scenario:** Invalid config rejected by work command

**Steps:**

```bash
# Still in /tmp/test-teaching-course

# 1. Break the config (remove required field)
cat > .flow/teach-config.yml <<EOF
course:
  name: "Test Course"
# Missing branches section!
EOF

# 2. Try to use work command
git checkout draft
work test-course
```

**Expected Output:**
```
✗ Missing required field: branches.draft
[or similar error message]
```

**Expected Results:**

- ✅ Config validation detects missing field
- ✅ Error message identifies the problem
- ✅ Work command handles gracefully

**Restore Config:**

```bash
# Restore valid config
git checkout .flow/teach-config.yml
```

**✅ Pass Criteria:**
- Invalid config detected
- Specific error shown
- No crash/hang

**❌ Fail Actions:**
- If validation passes: Check validation logic
- If crash occurs: Note crash details
- Report with config state

---

### 2.7 Test: Shortcut Loading

**Scenario:** Course shortcuts available in work session

**Steps:**

```bash
# Still in /tmp/test-teaching-course

# 1. Start work session
work test-course
# Ctrl+C to cancel editor

# 2. Check if shortcuts loaded
alias | grep test-course

# 3. Try using shortcut (if defined in config)
type test-coursed
```

**Expected Results:**

- ✅ Aliases shown in work output
- ✅ Shortcuts exist in current session
- ✅ Typing shortcut name shows definition

**✅ Pass Criteria:**
- Shortcuts displayed during work
- Aliases active in shell
- Shortcuts functional

**❌ Fail Actions:**
- If no shortcuts: Check config shortcuts section
- If not active: Check eval logic in _load_teaching_shortcuts
- Report with alias output

---

### 2.8 Test: Cleanup

```bash
# Clean up test directory
cd /tmp
rm -rf test-teaching-course

# Return to feature branch
cd ~/.git-worktrees/flow-cli-teaching-workflow
```

---

## 📖 Phase 3: Documentation Verification (10 minutes)

### 3.1 Quick Start Accuracy

**Test:** Follow quick start in `docs/guides/TEACHING-WORKFLOW.md`

**Steps:**

1. Open guide: `cat docs/guides/TEACHING-WORKFLOW.md | head -100`
2. Verify quick start section matches actual behavior
3. Check command syntax is correct
4. Verify expected outputs match reality

**✅ Pass Criteria:**
- Commands work as documented
- Output matches examples
- No outdated information

**❌ Fail Actions:**
- Note discrepancies between docs and behavior
- List specific examples that don't match
- Update documentation accordingly

---

### 3.2 Reference Card Accuracy

**Test:** Verify `docs/reference/REFCARD-TEACHING.md`

**Checklist:**

- [ ] Commands table accurate
- [ ] Configuration fields match `.flow/teach-config.yml` structure
- [ ] Shortcuts example works
- [ ] Troubleshooting solutions valid

**✅ Pass Criteria:**
- All information accurate
- Examples work

**❌ Fail Actions:**
- Note inaccuracies
- Update reference card

---

### 3.3 Demo Script Validity

**Test:** Review `docs/demos/teaching-workflow.tape`

**Check:**

- [ ] Commands are valid
- [ ] Sequence makes sense
- [ ] Timings appropriate

**✅ Pass Criteria:**
- Demo script executable (if VHS installed)
- Commands valid

**❌ Fail Actions:**
- Note invalid commands
- Fix demo script

---

## ✅ Success Criteria

### Required for Approval

**All Must Pass:**

- ✅ 9/9 basic tests passing
- ✅ 32/32 comprehensive tests passing
- ✅ No test regressions
- ✅ teach-init creates all required files
- ✅ Branch safety warning displays
- ✅ Work command functions on draft branch
- ✅ Quick deploy script works
- ✅ Deployment safety check prevents wrong-branch deploy
- ✅ Config validation catches errors
- ✅ Documentation accurate

**Performance:**

- ✅ Tests complete in < 2 minutes
- ✅ Deployment script shows timing
- ✅ No noticeable slowdown in other commands

---

## 📊 Testing Checklist

### Automated Tests

- [ ] Basic test suite (9 tests) - PASS
- [ ] Comprehensive test suite (32 tests) - PASS
- [ ] Regression tests (existing tests) - PASS

### Manual Integration

- [ ] teach-init creates files - PASS
- [ ] Branch safety warning works - PASS
- [ ] Work on draft (no warning) - PASS
- [ ] Quick deployment script - PASS
- [ ] Deployment safety check - PASS
- [ ] Config validation - PASS
- [ ] Shortcut loading - PASS

### Documentation

- [ ] Quick start guide accurate - PASS
- [ ] Reference card accurate - PASS
- [ ] Demo script valid - PASS

---

## 🐛 Troubleshooting Test Failures

### "teach-init: command not found"

**Cause:** Plugin not loaded

**Fix:**
```bash
source flow.plugin.zsh
teach-init --help
```

---

### Tests Fail with "yq: command not found"

**Cause:** yq not installed

**Fix:**
```bash
brew install yq
```

---

### "Teaching config not found"

**Cause:** Config file missing

**Fix:**
```bash
# Check file exists
ls -la .flow/teach-config.yml

# If missing, re-run teach-init
teach-init "Course Name"
```

---

### Permission Denied on Scripts

**Cause:** Scripts not executable

**Fix:**
```bash
chmod +x scripts/*.sh
```

---

## 📝 Test Report Template

Use this template when reporting test results:

```markdown
## Teaching Workflow v2.0 - Test Report

**Tester:** [Your Name]
**Date:** [YYYY-MM-DD]
**Branch:** feature/teaching-workflow
**Commit:** [git rev-parse --short HEAD]

### Automated Tests
- Basic Suite (9 tests): ✅ PASS / ❌ FAIL
- Comprehensive Suite (32 tests): ✅ PASS / ❌ FAIL
- Regression Tests: ✅ PASS / ❌ FAIL

### Manual Integration Tests
- teach-init: ✅ PASS / ❌ FAIL
- Branch safety warning: ✅ PASS / ❌ FAIL
- Work on draft: ✅ PASS / ❌ FAIL
- Quick deploy: ✅ PASS / ❌ FAIL
- Deployment safety: ✅ PASS / ❌ FAIL
- Config validation: ✅ PASS / ❌ FAIL
- Shortcut loading: ✅ PASS / ❌ FAIL

### Documentation Verification
- User guide: ✅ ACCURATE / ❌ NEEDS UPDATE
- Reference card: ✅ ACCURATE / ❌ NEEDS UPDATE
- Demo script: ✅ VALID / ❌ NEEDS FIX

### Issues Found
[List any issues discovered]

### Recommendation
✅ APPROVED FOR MERGE / ❌ NEEDS FIXES

### Notes
[Any additional observations]
```

---

## 🚀 After Testing

### If All Tests Pass

```bash
# 1. Create summary
git log --oneline feature/teaching-workflow --not dev | wc -l
# Note: X commits ready for merge

# 2. Push branch
git push origin feature/teaching-workflow

# 3. Create PR
gh pr create --base dev \
  --title "Teaching Workflow v2.0 - Complete Implementation" \
  --body "See TESTING-INSTRUCTIONS.md - all tests passing"
```

### If Tests Fail

1. Document failures in test report
2. Create GitHub issue for each bug
3. Fix issues in feature branch
4. Re-run tests
5. Repeat until all pass

---

**Questions?** Open an issue: https://github.com/Data-Wise/flow-cli/issues

---

**Last Updated:** 2026-01-11
**Version:** Teaching Workflow v2.0 (Increment 1)
