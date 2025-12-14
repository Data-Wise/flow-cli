# Ideas for ZSH Configuration

## 🧪 Testing Ideas

### Quick Wins (< 30 min each)

- **[2025-12-14]** Test `crumbs-clear` function
  - Verify it removes breadcrumb file
  - Check output messages
  - Impact: Medium | Risk: Safe

- **[2025-12-14]** Test `whatnext` alias existence
  - Similar pattern to existing alias tests
  - 5-line addition to current suite
  - Impact: Low | Risk: Safe

- **[2025-12-14]** Test `worklog` function basics
  - Check file creation
  - Verify timestamp format
  - High-value session tracking feature
  - Impact: High | Risk: Safe

- **[2025-12-14]** Test alias loading after fix (REGRESSION TEST)
  - Verify js, idk, stuck all work
  - Verify ah → aliashelp
  - Regression test for 2025-12-14 bug fix
  - Impact: High | Risk: Safe

- **[2025-12-14]** Test morning alias variants
  - Verify 'morning' and 'gmorning' work
  - Ensure 'gm' is NOT defined (Gemini conflict fix)
  - Impact: Medium | Risk: Safe

### Medium Effort (1-2 hours each)

- **[2025-12-14]** Test `work.zsh` multi-editor command
  - Test editor detection
  - Test project type detection
  - Mock editor launches (don't actually open)
  - ~15-20 test cases
  - Impact: High | Risk: Moderate

- **[2025-12-14]** Test session tracking workflow
  - startsession → worklog → endsession flow
  - Test sessioninfo output
  - Test logged entries
  - Integration test (multiple functions)
  - Impact: High | Risk: Moderate

- **[2025-12-14]** Test project status functions
  - statusupdate, setprogress
  - Test .STATUS file parsing/writing
  - Test progress calculations
  - Impact: Medium | Risk: Moderate

- **[2025-12-14]** Test focus timer edge cases
  - Multiple concurrent timers
  - Invalid time formats
  - Cleanup after interruption
  - Impact: Medium | Risk: Safe

- **[2025-12-14]** Test error handling
  - Missing dependencies
  - Invalid arguments
  - File permission errors
  - Non-existent projects
  - Impact: High | Risk: Moderate

### Big Ideas (3+ hours)

- **[2025-12-14]** Create test suite for `claude-workflows.zsh`
  - Test all cc* aliases
  - Mock Claude CLI calls
  - Test context passing
  - ~30 test cases
  - Impact: High | Risk: Moderate

- **[2025-12-14]** Integration tests for full workflows
  - Complete morning routine flow
  - Full development session cycle
  - Project switching workflow
  - End-to-end scenarios
  - Impact: High | Risk: Moderate

- **[2025-12-14]** Test coverage reporting
  - Script to calculate % coverage
  - List untested functions
  - Generate coverage report
  - CI/CD integration ready
  - Impact: Medium | Risk: Low

- **[2025-12-14]** Performance/load testing
  - Test with 100+ projects
  - Test with large win logs
  - Benchmark slow functions
  - Optimize bottlenecks
  - Impact: Low | Risk: Low

- **[2025-12-14]** Cross-shell compatibility tests
  - Test in different ZSH versions
  - Test with different ZDOTDIR setups
  - Test P10k integration
  - Impact: Medium | Risk: Moderate

## 📊 Current Testing Status

**Tested (25 tests):**
- ✅ adhd-helpers.zsh core functions: just-start, why, win, yay, wins, wins-history
- ✅ Focus timer: focus, focus-stop, time-check
- ✅ Morning routine: morning
- ✅ Breadcrumbs: breadcrumb, crumbs
- ✅ What-next: what-next
- ✅ Various aliases

**Not Tested:**
- ❌ adhd-helpers.zsh: ~15 functions (crumbs-clear, worklog, session tracking, etc.)
- ❌ work.zsh: Multi-editor work command
- ❌ claude-workflows.zsh: All cc* workflows
- ❌ obsidian-bridge.zsh: Obsidian integration
- ❌ genpass.zsh: Password generation

## 💡 Recommendations

**Immediate (next session):**
1. Add regression test for alias loading (prevents today's bug from returning)
2. Test worklog basics (high-value session tracking)
3. Test crumbs-clear (completes breadcrumb coverage)

**This week:**
- Test work.zsh multi-editor command
- Test session tracking workflow
- Add error handling tests

**Future:**
- Test coverage reporting tool
- Integration test suite
- Performance testing

---

*Last updated: 2025-12-14*
*Context: Documentation-only repo for ZSH configuration*
*Actual config: ~/.config/zsh/*
