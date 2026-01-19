# Teaching Workflow v3.0 Phase 1 - Test Suite

Comprehensive test suites for all 10 tasks across Waves 1-3.

## Test Suites

### 1. Automated Tests (`automated-tests.sh`)

**Purpose:** CI/CD-ready, non-interactive validation

**What it tests:**
- ✅ File existence/deletion (Task 1)
- ✅ Function implementation (Tasks 2-10)
- ✅ Code patterns and structure
- ✅ Integration points
- ✅ ZSH syntax validation

**Usage:**
```bash
# Run all automated tests
bash tests/teaching-workflow-v3/automated-tests.sh

# Exit code 0 = all pass, 1 = failures
```

**Output:**
```
Teaching Workflow v3.0 - Automated Test Suite
═══════════════════════════════════════════════

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
WAVE 1: Foundation Tests
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Task 1: commands/teach-init.zsh deleted
✓ Task 2: teach-doctor-impl.zsh exists
...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total Tests:  45
Passed:       45
Failed:       0

✅ All tests passed!
```

### 2. Interactive Tests (`interactive-tests.sh`)

**Purpose:** Human-guided quality assurance

**What it tests:**
- 📋 Actual command execution
- 👁️ Visual output verification
- 🔍 Edge cases and error handling
- ✨ User experience

**Usage:**
```bash
# Run interactive test suite
bash tests/teaching-workflow-v3/interactive-tests.sh

# Follow prompts for each test:
#   [y] Pass - Output matches expected
#   [n] Fail - Output doesn't match
#   [s] Skip - Skip this test
#   [q] Quit - Exit test suite
```

**Output:**
```
╔════════════════════════════════════════════════════════╗
║  Teaching Workflow v3.0 - Interactive Test Suite      ║
╚════════════════════════════════════════════════════════╝

This suite tests all 10 tasks from Waves 1-3.
For each test, review the output and judge if it matches expectations.

Total Tests: 28

Press Enter to start...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST 1/28: Task 1: teach-init deletion
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Command:
  test -f commands/teach-init.zsh && echo 'EXISTS' || echo 'DELETED'

Expected Behavior:
  Should output 'DELETED'

Actual Output:
  Running command...
DELETED

Does the output match expected behavior?
  [y] Pass  [n] Fail  [s] Skip  [q] Quit
  Your choice: _
```

## Test Coverage

### Wave 1 (Tasks 1-4) - Foundation

| Task | Feature | Automated | Interactive |
|------|---------|-----------|-------------|
| 1 | Remove teach-init | ✅ File deletion | ✅ Stub message |
| 2 | Basic doctor | ✅ Functions exist | ✅ Dependency checks |
| 3 | Help enhancement | ✅ EXAMPLES present | ✅ Help output |
| 4 | Full doctor | ✅ JSON/git checks | ✅ All check types |

### Wave 2 (Tasks 5-6) - Backup System

| Task | Feature | Automated | Interactive |
|------|---------|-----------|-------------|
| 5 | Backup system | ✅ Functions exist | ✅ Retention logic |
| 6 | Delete confirm | ✅ Prompt function | ✅ Interactive flow |

### Wave 3 (Tasks 7-10) - Enhancements

| Task | Feature | Automated | Interactive |
|------|---------|-----------|-------------|
| 7 | Enhanced status | ✅ Sections added | ✅ Output format |
| 8 | Deploy preview | ✅ Preview code | ✅ Diff viewing |
| 9 | Scholar integration | ✅ Auto-load/template | ✅ Context files |
| 10 | teach init | ✅ Flags present | ✅ Config generation |

## Test Logs

Interactive tests save detailed logs:

```
tests/teaching-workflow-v3/logs/
└── interactive-test-20260118-143000.log
```

Each log contains:
- Test descriptions
- Commands executed
- Actual output
- Pass/fail results

## CI Integration

Add to `.github/workflows/test.yml`:

```yaml
name: Teaching Workflow Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install ZSH
        run: sudo apt-get install -y zsh

      - name: Run Automated Tests
        run: bash tests/teaching-workflow-v3/automated-tests.sh
```

## Manual Testing Checklist

Beyond automated tests, manually verify:

### Task 1: teach-init deletion
- [ ] `teach init` shows stub message
- [ ] Message guides to v5.14.0
- [ ] No errors when trying to use

### Task 2 & 4: teach doctor
- [ ] `teach doctor` runs without errors
- [ ] Shows 4 check categories
- [ ] `teach doctor --json` outputs valid JSON
- [ ] `teach doctor --quiet` suppresses pass messages
- [ ] All 7 dependencies detected

### Task 3: Help system
- [ ] `teach exam --help` shows EXAMPLES
- [ ] `teach quiz --help` shows EXAMPLES
- [ ] `teach status --help` shows USAGE
- [ ] All help functions work

### Task 5: Backup system
- [ ] Create test content folder with files
- [ ] Run `_teach_backup_content` (source plugin first)
- [ ] Verify `.backups/` folder created
- [ ] Check timestamped backup exists
- [ ] Verify retention policies work

### Task 6: Delete confirmation
- [ ] Try to delete a backup
- [ ] Verify interactive prompt appears
- [ ] Test 'y' accepts deletion
- [ ] Test 'n' cancels deletion

### Task 7: Enhanced teach status
- [ ] Run `teach status` in teaching project
- [ ] Verify Deployment Status section
- [ ] Verify Backup Summary section
- [ ] Check last deploy shows correctly
- [ ] Check backup counts accurate

### Task 8: Deploy preview
- [ ] Create test teaching project with changes
- [ ] Run `teach deploy`
- [ ] Verify Changes Preview section
- [ ] Verify files changed summary
- [ ] Test view diff option

### Task 9: Scholar integration
- [ ] Create `lesson-plan.yml` file
- [ ] Run any teach command
- [ ] Verify auto-loaded (check with --verbose)
- [ ] Test `--template` flag
- [ ] Verify template passed to Scholar

### Task 10: teach init
- [ ] `teach init "Test Course"` - basic
- [ ] `teach init --config external.yml` - load config
- [ ] Verify .flow/teach-config.yml created
- [ ] Check default values set correctly

## Troubleshooting

### Automated tests fail

1. **Check syntax errors:**
   ```bash
   zsh -n lib/dispatchers/teach-dispatcher.zsh
   zsh -n lib/dispatchers/teach-doctor-impl.zsh
   zsh -n lib/backup-helpers.zsh
   ```

2. **Verify file structure:**
   ```bash
   ls -la lib/dispatchers/teach-*.zsh
   ls -la lib/backup-helpers.zsh
   ```

3. **Check git status:**
   ```bash
   git status
   git diff
   ```

### Interactive tests don't run

1. **Make executable:**
   ```bash
   chmod +x tests/teaching-workflow-v3/*.sh
   ```

2. **Check bash version:**
   ```bash
   bash --version  # Should be 4.0+
   ```

## Contributing

When adding new features to Teaching Workflow:

1. Add automated tests to `automated-tests.sh`
2. Add interactive tests to `interactive-tests.sh`
3. Update this README with new test cases
4. Run both test suites before committing

---

**Generated:** 2026-01-18
**For:** Teaching Workflow v3.0 Phase 1
**Tasks:** 1-10 (Waves 1-3)
