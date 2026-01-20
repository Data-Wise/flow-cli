# Integration Test Fixes - Action Checklist

**Date:** 2026-01-20
**Branch:** `feature/quarto-workflow`
**Current Status:** 263/275 tests passing (95.6%)
**Target:** 275/275 tests passing (100%)

---

## Critical Priority (Fix First)

### [ ] Issue #7: Missing Help Function
**File:** `lib/dispatchers/teach-dispatcher.zsh`
**Time:** 30 min - 1 hour
**Impact:** `teach help` completely broken

**Tasks:**
- [ ] Create `_teach_dispatcher_help()` function
- [ ] Include all teach commands (init, deploy, hooks, validate, cache, doctor, backup, status, etc.)
- [ ] Add examples for each command
- [ ] Test: `teach help` displays correctly
- [ ] Test: `teach --help` works
- [ ] Test: `teach -h` works

**Template:**
```zsh
_teach_dispatcher_help() {
    cat << 'EOF'
╭──────────────────────────────────────────────────────╮
│  TEACH - Teaching Workflow Dispatcher               │
╰──────────────────────────────────────────────────────╯

USAGE:
  teach <command> [options]

CORE COMMANDS:
  init              Initialize teaching project
  status            Show project dashboard
  doctor            Health check

CONTENT GENERATION (via Scholar):
  lecture <topic>   Generate lecture
  exam <topic>      Generate exam
  [etc...]

VALIDATION & DEPLOYMENT:
  validate [files]  Validate Quarto files
  deploy [files]    Deploy to production
  hooks install     Install git hooks

CACHE & CLEANUP:
  cache status      Show cache status
  clean             Remove _freeze/ and _site/

BACKUP:
  backup create     Create snapshot
  backup list       List backups

For detailed help: teach <command> --help
EOF
}
```

---

## High Priority (Fix Before PR)

### [ ] Issue #1: Index Link Manipulation
**File:** `lib/index-helpers.zsh` (or similar)
**Time:** 2-3 hours
**Tests:** Fixes #12, #13, #14

**Tasks:**
- [ ] Implement `_add_link_to_index()` function
  - [ ] Parse week number from filename
  - [ ] Extract title from YAML frontmatter
  - [ ] Find correct insertion point (sorted by week)
  - [ ] Insert markdown link: `- [Week N: Title](path/to/file.qmd)`

- [ ] Implement `_update_link_in_index()` function
  - [ ] Find existing link by path
  - [ ] Update title if changed
  - [ ] Preserve week ordering

- [ ] Fix week number sorting
  - [ ] Extract numeric week from "Week 5" format
  - [ ] Sort numerically (not lexicographically)
  - [ ] Handle edge cases (Week 1, Week 10, Week 05)

**Test:**
```bash
./tests/test-index-management-unit.zsh
# Should pass tests 12, 13, 14
```

---

### [ ] Issue #2: Dependency Scanning
**File:** `lib/deploy-helpers.zsh` (or similar)
**Time:** 2-4 hours
**Tests:** Fixes #16, #17, #5, #6 (deploy suite)

**Tasks:**
- [ ] Implement `_find_sourced_files()` function
  - [ ] Scan for R: `source("path/to/file.R")`
  - [ ] Scan for R: `source('path/to/file.R')`
  - [ ] Resolve relative paths to project root
  - [ ] Return list of absolute paths

- [ ] Implement `_find_cross_references()` function
  - [ ] Scan for Quarto: `@sec-label`
  - [ ] Scan for Quarto: `@fig-label`
  - [ ] Scan for Quarto: `@tbl-label`
  - [ ] Find files containing matching `#sec-label` / `#fig-label`
  - [ ] Return list of referenced .qmd files

- [ ] Integrate into `_teach_deploy_enhanced()`
  - [ ] Call dependency finders for each file
  - [ ] Add dependencies to deploy list
  - [ ] Prevent duplicates

**Test:**
```bash
./tests/test-index-management-unit.zsh  # Tests 16, 17
./tests/test-teach-deploy-unit.zsh      # Tests 5, 6
```

---

### [ ] Issue #3: Cross-Reference Validation
**File:** `lib/validate-helpers.zsh` (or similar)
**Time:** 1-2 hours
**Tests:** Fixes #19

**Tasks:**
- [ ] Fix `_validate_cross_references()` return code
  - [ ] Return 1 if any references are broken
  - [ ] Return 0 only if all references resolve

- [ ] Implement reference resolution
  - [ ] Extract all `@sec-*`, `@fig-*`, `@tbl-*` from file
  - [ ] Search project for matching labels
  - [ ] Report missing references

- [ ] Add to validation pipeline
  - [ ] Include in `teach validate` command
  - [ ] Include in pre-commit hook

**Test:**
```bash
./tests/test-index-management-unit.zsh  # Test 19
```

---

## Medium Priority (Nice to Have)

### [ ] Issue #4: Insertion Point Off-by-One
**File:** `lib/index-helpers.zsh`
**Time:** 30 min - 1 hour
**Tests:** Fixes #20

**Tasks:**
- [ ] Debug `_find_insertion_point()` function
- [ ] Fix off-by-one error (returns line 6, should be line 5)
- [ ] Test edge cases:
  - [ ] Insert before all existing weeks
  - [ ] Insert after all existing weeks
  - [ ] Insert in middle

**Test:**
```bash
./tests/test-index-management-unit.zsh  # Test 20
```

---

### [ ] Issue #5: Git Test Environment
**File:** `tests/test-teach-deploy-unit.zsh`
**Time:** 30 minutes
**Tests:** Fixes #24

**Tasks:**
- [ ] Update test setup to create `main` branch
- [ ] Add commits to main branch
- [ ] Create test commits on draft branch
- [ ] Test commit counting works

**Code:**
```zsh
# In test setup
git checkout -b main
git commit --allow-empty -m "Initial commit"
git checkout -b draft
git commit --allow-empty -m "Draft changes"
# Now test: git rev-list --count main..draft
```

**Test:**
```bash
./tests/test-teach-deploy-unit.zsh  # Test 24
```

---

## Low Priority (Polish)

### [ ] Issue #6: Status Header Format
**File:** `tests/test-teach-status-unit.zsh`
**Time:** 15 minutes
**Tests:** Fixes #29

**Options:**
1. **Update test expectation** to match actual output
2. **Change status output** to include "Teaching Project Status" header

**Recommended:** Update test expectation (implementation is correct)

**Tasks:**
- [ ] Review actual `teach status --full` output
- [ ] Update test to expect current format
- [ ] Or: add "Teaching Project Status" header to full view

**Test:**
```bash
./tests/test-teach-status-unit.zsh  # Test 29
```

---

## Testing Workflow

After each fix:

1. **Run specific test suite:**
   ```bash
   ./tests/test-<suite-name>.zsh
   ```

2. **Run ALL tests:**
   ```bash
   ./tests/run-all.sh
   ```

3. **Verify plugin loads:**
   ```bash
   source flow.plugin.zsh
   teach help  # Should work after Issue #7 fixed
   ```

4. **Check integration:**
   ```bash
   teach status       # Should display dashboard
   teach doctor       # Should run health checks
   teach validate     # Should validate files
   ```

---

## Completion Criteria

- [ ] All 8 test suites pass 100%
- [ ] Plugin loads without errors
- [ ] `teach help` displays correctly
- [ ] All teach commands functional
- [ ] Performance targets met:
  - [ ] Pre-commit hook <5s
  - [ ] teach validate <3s
  - [ ] teach doctor <5s
  - [ ] teach status <1s

---

## Estimated Timeline

| Priority | Issues | Estimated Time |
|----------|--------|----------------|
| Critical | 1      | 0.5-1 hour     |
| High     | 3      | 5-9 hours      |
| Medium   | 2      | 1-2 hours      |
| Low      | 1      | 0.25 hours     |
| **TOTAL** | **7** | **6.75-12.25 hours** |

**Recommended Approach:** Fix in priority order, test after each fix.

---

## Next Steps After 100%

1. Re-run complete integration test suite
2. Update `.STATUS` file with completion
3. Create PR: `feature/quarto-workflow` → `dev`
4. Update documentation
5. Plan Phase 2 implementation

---

**Last Updated:** 2026-01-20
**Status:** Ready to fix
