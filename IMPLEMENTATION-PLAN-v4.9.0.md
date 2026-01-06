# v4.9.0 Implementation Plan - Progressive Enhancement

**Created:** 2026-01-05
**Status:** Ready to Start
**Approach:** Progressive enhancement (Quick Wins → Interactive Help → Full Onboarding)

---

## Key Insight from Analysis

**Finding:** Installation documentation is **EXCELLENT** post-v4.8.1

- Homebrew-first approach ✅
- Comprehensive installation.md (300+ lines) ✅
- Multiple learning paths (quick-start, tutorials, FAQ) ✅
- install.sh and uninstall.sh already exist ✅

**Main Gap:** **Discoverability and first-run experience**

- Users don't know what commands exist after install
- No guided onboarding
- Help system exists but needs better UX
- Advanced features stay hidden

**Strategy:** Build on excellent foundation, focus on user experience improvements

---

## Implementation Phases

### Phase 1: Quick Wins Sprint (Week 1, ~2.5 hours) ⚡

**Goal:** Immediate UX improvements with minimal effort
**Status:** **RECOMMENDED START HERE**

#### Tasks

1. **First-run welcome message** (~30 min)
   - Detect first `work` command
   - Show welcome + available commands
   - Create `~/.config/flow-cli/.welcomed` marker
   - **Files:** `commands/work.zsh`

2. **Add "See also" to help output** (~20 min)
   - Cross-reference related commands
   - Pattern: `📚 See also: finish, hop, dash`
   - **Files:** All `_*_help()` functions

3. **Random tips in dashboard** (~15 min)
   - 20% chance per `dash` invocation
   - Examples: "Use 'pick --recent' to see Claude sessions"
   - **Files:** `commands/dash.zsh`

4. **Quick reference card command** (~25 min)
   - New command: `flow ref`
   - Pretty-print COMMAND-QUICK-REFERENCE.md
   - **Files:** New `commands/ref.zsh`

5. **Command usage examples** (~60 min)
   - Add EXAMPLES section to all help functions
   - Pattern:
     ```
     EXAMPLES:
       $ work my-project    # Start working on project
       $ work               # Interactive picker
       $ work -l            # List recent projects
     ```
   - **Files:** Update all 19 command help functions

**Deliverable:** Improved discoverability with zero breaking changes

---

### Phase 2: Interactive Help (Week 2, ~3 hours) 🔧

**Goal:** Much better help discoverability with interactive tools
**Prerequisites:** Phase 1 complete

#### Tasks

1. **Interactive help browser** (~90 min)
   - New: `flow help --interactive` or `flow help -i`
   - Use fzf to browse all commands
   - Show preview of help text
   - Press Enter for full help
   - **Files:** `commands/flow.zsh`, new `lib/help-browser.zsh`

2. **Context-aware help** (~60 min)
   - `flow help` shows different content by context
   - Git repo → show git workflows
   - R package → show r dispatcher
   - New user → show getting started
   - **Files:** `commands/flow.zsh`

3. **Command aliases reference** (~30 min)
   - New: `flow alias` shows all aliases
   - Format: `ccy → cc yolo  # Claude Code in YOLO mode`
   - **Files:** New `commands/alias.zsh`

**Deliverable:** Interactive help system with contextual awareness

---

### Phase 3: Enhanced Onboarding (v4.9.0, ~8-11 hours) 🏗️

**Goal:** Complete first-run experience transformation
**Prerequisites:** Phases 1-2 complete
**Reference:** SPEC-v4.9.0-installation-onboarding.md

#### Tasks

1. **Enhanced `flow doctor --fix`** (~4 hours)
   - Interactive install mode
   - Batch mode (`-y` flag)
   - Package manager detection
   - Categories: core/recommended/optional
   - **Files:** `commands/doctor.zsh`

2. **First-run wizard** (`flow setup`) (~4-6 hours)
   - Step 1: Verify installation
   - Step 2: Install recommended tools
   - Step 3: Configure projects directory
   - Step 4: Quick tutorial
   - **Files:** New `commands/setup.zsh`

3. **Troubleshooter mode** (~2 hours)
   - `flow doctor --diagnose` interactive troubleshooter
   - Guided problem solving
   - **Files:** `commands/doctor.zsh`

4. **Testing & polish** (~2-3 hours)
   - E2E test: Fresh install → wizard → first command
   - Test all OS combinations
   - Update all documentation
   - **Files:** New tests in `tests/`

**Deliverable:** Zero-friction onboarding experience

---

## Progressive Enhancement Benefits

| Phase            | Time  | Impact                        | Risk   |
| ---------------- | ----- | ----------------------------- | ------ |
| Quick Wins       | 2.5h  | High - Immediate improvement  | Low    |
| Interactive Help | 3h    | High - Better discoverability | Low    |
| Full Onboarding  | 8-11h | Very High - Transformative    | Medium |

**Rationale for phased approach:**

- ✅ Deliver value quickly (Quick Wins in one session)
- ✅ Validate approach before large investment
- ✅ Each phase builds on previous
- ✅ Can stop at any phase and still have improvement
- ✅ ADHD-friendly: Small, achievable milestones

---

## Files to Create/Modify

### Phase 1 Files

- `commands/work.zsh` - Add first-run detection
- All `_*_help()` functions - Add "See also" sections
- `commands/dash.zsh` - Add random tips
- `commands/ref.zsh` - NEW: Quick reference command
- All command help functions - Add EXAMPLES sections

### Phase 2 Files

- `lib/help-browser.zsh` - NEW: Interactive help with fzf
- `commands/flow.zsh` - Enhanced help command
- `commands/alias.zsh` - NEW: Alias reference

### Phase 3 Files

- `commands/doctor.zsh` - Enhanced with --fix and --diagnose
- `commands/setup.zsh` - NEW: First-run wizard
- `tests/test-first-run.zsh` - NEW: E2E tests

---

## Documentation Updates

### After Phase 1

- Update `docs/commands/*.md` with examples
- Add "See also" cross-references
- Document `flow ref` command

### After Phase 2

- Document interactive help (`flow help -i`)
- Update FAQ with help discovery tips

### After Phase 3

- Update installation.md with wizard details
- New troubleshooting guide
- Video/GIF of first-run experience

---

## Success Criteria

### Phase 1

- [ ] First-run welcome appears on first `work` command
- [ ] All help functions have "See also" sections
- [ ] Dashboard shows tips ~20% of time
- [ ] `flow ref` displays quick reference card
- [ ] All commands have EXAMPLES in help

### Phase 2

- [ ] `flow help -i` launches fzf browser
- [ ] Context-aware help works in git/R/new contexts
- [ ] `flow alias` lists all aliases

### Phase 3

- [ ] `flow doctor --fix` installs missing tools
- [ ] `flow setup` wizard completes in < 60 seconds
- [ ] First-time user reaches first `win` in < 2 minutes
- [ ] All tests pass

---

## Risk Mitigation

| Risk                                     | Mitigation                                        |
| ---------------------------------------- | ------------------------------------------------- |
| Phase 1 changes break existing workflows | Extensive testing, all changes additive           |
| fzf not installed for Phase 2            | Check for fzf, offer to install, fallback to text |
| Wizard too long in Phase 3               | Add `--quick` mode, make all steps skippable      |
| Network failures during tool installs    | Add retry logic, offline fallback                 |

---

## Timeline Estimate

| Phase     | Optimistic | Realistic | Pessimistic |
| --------- | ---------- | --------- | ----------- |
| Phase 1   | 2h         | 2.5h      | 3h          |
| Phase 2   | 2.5h       | 3h        | 4h          |
| Phase 3   | 8h         | 10h       | 13h         |
| **Total** | 12.5h      | 15.5h     | 20h         |

**Recommended cadence:**

- Week 1: Phase 1 (one session)
- Week 2: Phase 2 (one session)
- Week 3-4: Phase 3 (2-3 sessions)

---

## Next Steps

### To Start Phase 1 (Quick Wins Sprint)

1. Create feature branch: `git checkout -b feature/quick-wins`
2. Implement first-run welcome in `commands/work.zsh`
3. Update all help functions with "See also"
4. Add random tips to `commands/dash.zsh`
5. Create `commands/ref.zsh`
6. Add EXAMPLES to all help functions
7. Test: Source plugin and verify each feature
8. Create PR and merge

**Estimated time:** One focused session (~2-3 hours)

---

## References

- **Brainstorm:** `BRAINSTORM-installation-help-docs-2026-01-05.md`
- **Full spec:** `SPEC-v4.9.0-installation-onboarding.md`
- **Current status:** `.STATUS`
- **Existing docs:** `docs/getting-started/installation.md` (excellent!)

---

## Decision Point

**Start with Phase 1 (Quick Wins Sprint)?**

✅ Recommended - Immediate value, low risk, builds foundation for Phase 2
⏭️ Or skip to Phase 2 if interactive help is higher priority
🏗️ Or skip to Phase 3 if full onboarding is critical now

**Current recommendation:** Phase 1 → Phase 2 → Phase 3 (progressive enhancement)

---

**Last Updated:** 2026-01-05
**Status:** Ready for Phase 1 implementation
