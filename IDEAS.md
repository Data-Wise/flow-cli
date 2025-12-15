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

## 🔧 Alias Refactoring Ideas

### Comprehensive Refactoring Plans (2025-12-14)

**Analysis Complete:** Three detailed plans created
- **Plan A: Minimal Changes** (125 aliases, 25% reduction)
  - Keep high-frequency shortcuts (ts, rd, qp, cc)
  - Remove only duplicates and conflicts
  - Minimal muscle memory disruption
  - Impact: Low | Risk: Safe | Effort: 2 hours

- **Plan B: Full Standardization** (90 aliases, 46% reduction)
  - Extend proj- pattern to all aliases
  - One consistent domain-action pattern
  - Biggest cleanup, requires relearning
  - Impact: High | Risk: Moderate | Effort: 1 week

- **Plan C: Hybrid Frequency-Based** (110 aliases, 34% reduction) ⭐ Recommended
  - Keep shortcuts for daily commands (30x/day)
  - Standardize medium-frequency (5x/day)
  - Best balance for ADHD workflow
  - Impact: Medium | Risk: Low | Effort: 3-4 hours

**Documents Created:**
- `ALIAS-REFACTOR-PLAN-2025-12-14.md` - Initial comprehensive analysis
- `ALIAS-REFACTOR-PLANS-A-B-2025-12-14.md` - First revision with 2 plans
- `ALIAS-REFACTOR-3-PLANS-2025-12-14.md` - Second revision extending proj- pattern
- `ALIAS-REFACTOR-EXISTING-PATTERNS-2025-12-14.md` - Final analysis with comparison ⭐

**Key Insights:**
- User has 5 existing patterns (full names, 2-letter, 1-letter, atomic pairs, domain-action)
- User specifically likes `proj-*` pattern (domain-action)
- User finds 1-2 letter aliases hard to remember (ADHD consideration)
- 42-79 aliases can be removed (duplicates, conflicts, over-specific prompts)
- Current: 167 aliases → Target: 88-125 aliases depending on plan

**Next Steps (When Ready):**
1. Review all planning documents
2. Choose preferred plan (A, B, or C)
3. Create migration script
4. Test in parallel (old + new aliases)
5. Gradual transition over 1-3 weeks
6. Update help system and documentation

---

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
