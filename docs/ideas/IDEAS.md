# Ideas for ZSH Configuration

## 🎯 ACTIVE - Workflow Command Redesign (2025-12-14 Evening)

### Context-Aware Command Design - IN PROGRESS 🚧

**Status:** Brainstorming complete, ready to implement
**Goal:** Reduce cognitive load and make commands more intuitive

**Problem Identified:**

- Commands require explicit project names (not context-aware)
- Unclear when to use keywords vs options
- Too many decisions required
- Not leveraging current working directory

**Key Proposals (See WORKFLOW-COMMAND-REDESIGN-BRAINSTORM.md):**

1. **Proposal A: Smart Defaults (P0 - RECOMMENDED)** ⭐
   - `status` with no args → auto-detects current project
   - `status active P0 "Task" 85` → updates current project (no name needed)
   - Falls back to fuzzy picker if not in a project
   - **Time:** 2-3 hours | **Breaking Changes:** None | **ADHD Score:** 9/10

2. **Proposal D: Context-Aware `work` (P0 - RECOMMENDED)** ⭐
   - `work` with no args → opens current project OR smart picker
   - `work med` → fuzzy match to mediationverse
   - Works from anywhere
   - **Time:** 1-2 hours | **Breaking Changes:** None | **ADHD Score:** 8/10

3. **Proposal E: Fuzzy Matching (P1)** ⭐
   - `status med` → matches "mediationverse"
   - `work stat` → matches "stat-440"
   - Tab completion for project names
   - **Time:** 2 hours | **Breaking Changes:** None | **ADHD Score:** 9/10

4. **Proposal B: Unified Dashboard (P1)**
   - `dash active` → filter by status
   - `dash P0` → filter by priority
   - `dash teaching active` → combined filters
   - **Time:** 2-3 hours | **Breaking Changes:** Minor | **ADHD Score:** 8/10

5. **Proposal F: Visual Menu (P2)**
   - `pm` command shows interactive menu
   - Good for first-time learning
   - **Time:** 2-3 hours | **Breaking Changes:** None | **ADHD Score:** 8/10

6. **Proposal C: Command Consolidation (P2)**
   - C1: New `proj` command (consolidates everything)
   - C2: Keep current, add smart modes
   - **Time:** 6-8 hours (C1) or 2-3 hours (C2) | **Breaking Changes:** Major (C1) or None (C2)

**Recommended Implementation Plan:**

**Phase 1: Smart Defaults (2-3 hours)** - P0

- [ ] Make `status` context-aware (detect PWD)
- [ ] Make `work` context-aware (detect PWD)
- [ ] Add `status active/paused/etc` shortcuts for current project
- [ ] Test with real workflows
- **Impact:** 66% less typing, zero decisions when in project

**Phase 2: Fuzzy Matching (2 hours)** - P1

- [ ] Implement `_fuzzy_match_project` helper
- [ ] Update `status`, `work`, `dash` to use fuzzy matching
- [ ] Add tab completion
- [ ] Test with partial names
- **Impact:** Typo tolerant, less typing

**Phase 3: Enhanced Dashboard (2-3 hours)** - P1

- [ ] Add filtering to `dash` (active, P0, combined)
- [ ] Add `dash --update` interactive mode
- [ ] Add `dash --start` quick jump
- **Impact:** More powerful views, better navigation

**Expected Outcome:**

```bash
# Before:
status mediationverse active P0 "Continue sims" 85  # 47 chars

# After Phase 1:
cd ~/projects/r-packages/active/mediationverse
status active P0 "Continue sims" 85  # 35 chars, no name!

# After Phase 2:
status med active P0 "Continue sims" 85  # Fuzzy match from anywhere
```

**ADHD Benefits:**

- ✅ 66% less typing on average
- ✅ Zero decisions when in a project
- ✅ Typo tolerant with fuzzy matching
- ✅ Context aware (location matters)
- ✅ No breaking changes
- ✅ Consistent patterns across commands

**Files:**

- Analysis: `WORKFLOW-COMMAND-REDESIGN-BRAINSTORM.md` (complete implementation details)
- Original workflow docs: `WORKFLOW-IMPLEMENTATION-SUMMARY.md`

**Next:** Implement Phase 1 (Smart Defaults) - ~2-3 hours

---

## ✅ COMPLETED - Workflow System Overhaul (2025-12-14 Afternoon)

### ADHD-Optimized Project Management - IMPLEMENTED ✅

**Completed:** December 14, 2025 Afternoon
**Status:** Production ready

**What Was Built:**

- ✅ `dash` - Master dashboard (see all projects in <5 seconds)
- ✅ `status` - Easy status updates (interactive or quick mode)
- ✅ Enhanced `js` - Works across all project types (not just R packages)
- ✅ Unified .STATUS format across all projects
- ✅ Category filters (teaching/research/packages/dev)
- ✅ Priority-aware (P0/P1/P2) with color coding
- ✅ Zero-decision workflows

**Files Created:**

- `~/.config/zsh/functions/dash.zsh` (315 lines)
- `~/.config/zsh/functions/status.zsh` (360 lines)
- `WORKFLOW-IMPLEMENTATION-SUMMARY.md`
- `WORKFLOW-QUICK-REFERENCE.md`
- `WORKFLOW-ANALYSIS-2025-12-14.md`

**Benefits:**

- 🧠 ADHD-optimized (visual scan <5 seconds)
- 🎯 Unified view of all work (no more scattered info)
- ⚡ Zero decisions (js picks for you)
- 📋 No manual .STATUS editing
- 🎨 Visual hierarchy with colors and icons

**User Feedback:** "It's a bit confusing" → Led to Proposal A-F redesign (above)

---

## ✅ COMPLETED - Help System Phase 1 (2025-12-14 Afternoon)

### Enhanced Help Screens - IMPLEMENTED ✅

**Completed:** December 14, 2025 Afternoon
**Status:** All 8 smart functions enhanced

**What Was Built:**

- ✅ Enhanced all 8 smart function help screens (r, cc, qu, gm, focus, note, obs, workflow)
- ✅ Color-coded sections (🔥💡📋🤖🔐⏱️📱📊👁️📝🔗📚)
- ✅ "Most Common" sections (top 3-4 commands per function)
- ✅ "Quick Examples" with real usage patterns
- ✅ Visual hierarchy with Unicode box borders
- ✅ NO_COLOR environment variable support
- ✅ Backward compatible (all shortcuts preserved)

**Files:**

- `~/.config/zsh/functions/smart-dispatchers.zsh` (~730 lines)
- `HELP-OVERHAUL-ROADMAP.md` (complete 3-week plan)
- `PHASE1-IMPLEMENTATION-REPORT.md` (technical details)
- `ENHANCED-HELP-QUICK-START.md` (user guide)

**Testing:**

- ✅ 91/91 tests passing (100%)
- ✅ Fixed 3 cosmetic text mismatches

**Next:** Phase 2 (Week 2) - Multi-mode help system

---

## ✅ COMPLETED - Alias Refactoring (2025-12-14)

### Smart Function Architecture - IMPLEMENTED ✅

**Completed:** December 14, 2025  
**Status:** Ready to deploy

**What Was Built:**

- ✅ 8 smart functions (r, qu, cc, gm, focus, note, obs, workflow)
- ✅ Built-in help systems (`<cmd> help`)
- ✅ Full-word actions (r test, focus 25, cc project)
- ✅ Removed 55 obsolete aliases (33% reduction)
- ✅ Preserved 112 essential aliases
- ✅ Zero new aliases to memorize
- ✅ Backward compatible (old names still work)

**Files Created:**

- `~/.config/zsh/functions/smart-dispatchers.zsh` (631 lines)
- `refactoring-2025-12-14/README.md`
- `refactoring-2025-12-14/IMPLEMENTATION.md`
- `refactoring-2025-12-14/remove-obsolete-aliases.sh`

**Benefits:**

- 🧠 ADHD-optimized (self-documenting, discoverable)
- 💪 Muscle memory preserved (f15, qp, gs all work)
- ⚡ Minimal migration (only 2 commands change: tc, fs)
- 📚 Consistent pattern everywhere
- 🔍 Low cognitive load

**Next:** Deploy (15-20 min) - See TODO.md

---

## 🎨 NEW - Website Design Standards Unification (2025-12-20)

### Unified ADHD-Optimized Design System - PROPOSED 📋

**Status:** Proposal complete, ready for Sprint 1
**Goal:** Create unified design standards for MkDocs, Quarto+pkgdown, Quarto+altdoc
**Priority:** P2 (Quality improvement, not urgent)

**Problem:**

- ADHD-optimized MkDocs implementation complete (Sprint 1-3) ✅
- No standardized ADHD design system for R packages
- Risk of standards diverging across tools
- Manual sync burden to project management hubs

**Recommended Solution:** Hierarchical standard with single base + tool implementations

**Structure:**

```bash
standards/
├── 00-BASE/          # Core ADHD principles (tool-agnostic)
├── 01-IMPLEMENTATIONS/
│   ├── mkdocs/       # ✅ Already complete
│   ├── quarto-pkgdown/   # To implement
│   └── quarto-altdoc/    # To implement
├── 02-EXAMPLES/      # Working examples
└── 03-TEMPLATES/     # Copy-paste ready
```

**Implementation Plan:**

#### Sprint 1: Foundation (3-4 hours) ⭐ RECOMMENDED FIRST

- [ ] Create standards/ directory structure
- [ ] Extract COLOR-PALETTE.md (universal hex values)
- [ ] Extract DESIGN-SYSTEM-BASE.md (tool-agnostic principles)
- [ ] Document existing MkDocs implementation
- [ ] Update sync-standards.sh to include website standards
- [ ] Test sync to one PM hub

#### Sprint 2: R Package Research (2-3 hours)

- [ ] Create test R package
- [ ] Test pkgdown theming (Bootstrap vars, custom CSS)
- [ ] Test altdoc theming (SCSS, Quarto themes)
- [ ] Document findings and choose best approach

#### Sprint 3: R Package Implementations (4-6 hours)

- [ ] Create quarto-pkgdown implementation guide
- [ ] Create quarto-altdoc implementation guide
- [ ] Test with real R packages (medfit, probmed)
- [ ] Iterate based on findings

#### Sprint 4: Templates & Examples (3-4 hours)

- [ ] Create working example sites
- [ ] Create copy-paste ready templates
- [ ] Write comprehensive README
- [ ] Create Quick Start guides
- [ ] Final sync to all PM hubs

**Total Estimated Effort:** 12-17 hours (spread across 4 sessions)

**Benefits:**

- ✅ Consistent ADHD-optimized branding across all projects
- ✅ Single source of truth for color values
- ✅ Easy updates (change once, sync everywhere)
- ✅ Scalable to new tools (Hugo, Sphinx, VuePress)
- ✅ Could publish as open-source ADHD design system

**Color Palette (Already Defined):**

- Primary: Cyan `#00bcd4` / `#4dd0e1` (dark)
- Accent: Purple `#9c27b0` / `#ba68c8` (dark)
- All WCAG AAA compliant (8.4:1 to 11.5:1 contrast ratios)

**Files:**

- Full proposal: `PROPOSAL-WEBSITE-DESIGN-STANDARDS-UNIFICATION.md`
- Current MkDocs impl: `docs/stylesheets/adhd-colors.css`
- Color psychology: `ADHD-COLOR-PSYCHOLOGY.md`

**Wild Ideas (Future):**

- ADHD Design System npm package (@adhd-tools/design-system)
- Browser extension for ADHD colors (like Dark Reader)
- R package for ADHD Quarto themes (install.packages("adhdtheme"))
- GitHub Action for automated standards sync
- Interactive documentation site with live color picker

**Next:** Quick win - Document MkDocs work (15-20 min) or Foundation Sprint (3-4 hours)

---

## 🧪 Testing Ideas

### Quick Wins (< 30 min each)

- [x] **[2025-12-14]** Test `crumbs-clear` function ✅ COMPLETE
- [x] **[2025-12-14]** Test `whatnext` alias existence ✅ COMPLETE
- [x] **[2025-12-14]** Test `worklog` function basics ✅ COMPLETE
- [x] **[2025-12-14]** Test alias loading after fix (REGRESSION TEST) ✅ COMPLETE
- [x] **[2025-12-14]** Test morning alias variants ✅ COMPLETE

### Medium Effort (1-2 hours each)

- [ ] **[2025-12-14]** Test `work.zsh` multi-editor command
  - Test editor detection
  - Test project type detection
  - Mock editor launches (don't actually open)
  - ~15-20 test cases
  - Impact: High | Risk: Moderate

- [ ] **[2025-12-14]** Test session tracking workflow
  - startsession → worklog → endsession flow
  - Test sessioninfo output
  - Test logged entries
  - Integration test (multiple functions)
  - Impact: High | Risk: Moderate

- [ ] **[2025-12-14]** Test project status functions
  - statusupdate, setprogress
  - Test .STATUS file parsing/writing
  - Test progress calculations
  - Impact: Medium | Risk: Moderate

- [ ] **[2025-12-14]** Test focus timer edge cases
  - Multiple concurrent timers
  - Invalid time formats
  - Cleanup after interruption
  - Impact: Medium | Risk: Safe

- [ ] **[2025-12-14]** Test error handling
  - Missing dependencies
  - Invalid arguments
  - File permission errors
  - Non-existent projects
  - Impact: High | Risk: Moderate

### Big Ideas (3+ hours)

- [ ] **[2025-12-14]** Create test suite for `claude-workflows.zsh`
  - Test all cc\* aliases
  - Mock Claude CLI calls
  - Test context passing
  - ~30 test cases
  - Impact: High | Risk: Moderate

- [ ] **[2025-12-14]** Integration tests for full workflows
  - Complete morning routine flow
  - Full development session cycle
  - Project switching workflow
  - End-to-end scenarios
  - Impact: High | Risk: Moderate

- [ ] **[2025-12-14]** Test coverage reporting
  - Script to calculate % coverage
  - List untested functions
  - Generate coverage report
  - CI/CD integration ready
  - Impact: Medium | Risk: Low

- [ ] **[2025-12-14]** Performance/load testing
  - Test with 100+ projects
  - Test with large win logs
  - Benchmark slow functions
  - Optimize bottlenecks
  - Impact: Low | Risk: Low

- [ ] **[2025-12-14]** Cross-shell compatibility tests
  - Test in different ZSH versions
  - Test with different ZDOTDIR setups
  - Test P10k integration
  - Impact: Medium | Risk: Moderate

---

## 🚀 Future Enhancement Ideas

### Shell Improvements

- [ ] **Smart completion for smart functions**
  - Tab completion for r, cc, qu actions
  - Context-aware suggestions
  - Impact: High | Effort: Medium

- [ ] **Integration with fzf**
  - fuzzy find for project switching
  - Fuzzy find for help topics
  - Impact: Medium | Effort: Medium

- [ ] **Color-coded help output**
  - Syntax highlighting in help
  - Better visual hierarchy
  - Impact: Low | Effort: Low

### Workflow Enhancements

- [ ] **Project templates**
  - Quick project scaffolding
  - R package, Quarto, etc.
  - Impact: Medium | Effort: Medium

- [ ] **AI-powered suggestions**
  - Suggest next action based on context
  - Learn from usage patterns
  - Impact: High | Effort: High

- [ ] **Dashboard integration**
  - Terminal dashboard with project status
  - Quick access to all commands
  - Impact: Medium | Effort: Medium

---

## 📊 Current Testing Status

**Test Suite:**

- Total: 49 tests
- Pass rate: 96%
- Coverage: ~60% of ADHD helpers

**Tested:**

- ✅ adhd-helpers.zsh core functions
- ✅ Focus timer functions
- ✅ Morning routine
- ✅ Breadcrumbs (complete)
- ✅ What-next
- ✅ Worklog (complete)
- ✅ Alias loading (regression tests)

**Not Tested:**

- ❌ work.zsh multi-editor
- ❌ claude-workflows.zsh
- ❌ obsidian-bridge.zsh
- ❌ genpass.zsh
- ❌ Session tracking workflow
- ❌ Project status functions

---

## 💡 Recommendations

**Immediate (Post-Refactoring):**

1. Deploy smart functions (15-20 min)
2. Test in daily workflow (1 week)
3. Note any improvements needed

**Next Week:**

- Resume testing priorities (work.zsh, session tracking)
- Add smart function tests
- Update documentation

**Long-term:**

- Integration tests
- Performance optimization
- Enhanced completion

---

_Last updated: 2025-12-14 18:45_  
_Major milestone: Smart function architecture complete!_
