# Flow-CLI Workflow Enhancement Plan - Executive Summary

**Date:** 2026-01-09
**Status:** Design approved, ready for implementation
**Total Effort:** 46 hours over 12 weeks
**Releases:** 4 incremental releases (v5.1.0 → v5.2.0 → v5.3.0 → v5.4.0)

---

## Executive Summary

This document summarizes the comprehensive workflow enhancement plan for flow-cli, addressing key ADHD pain points and improving feature discoverability. The plan includes 4 major features delivered incrementally to gather early user feedback and validate assumptions.

### Key Achievements

✅ **Comprehensive Analysis Complete:**

- Analyzed 20 commands (11,373 LOC)
- Analyzed 11 dispatchers (including new `dot` dispatcher in v5.0.0)
- Identified 4 high-impact enhancement opportunities
- Answered all 8 critical design questions

✅ **Documentation Complete:**

- 32 KB brainstorm document
- 12 KB design decisions document
- Complete implementation plan (645 lines)
- Updated .STATUS and Claude plan files

---

## The 4 Enhancements

### 1. Context Restoration (v5.1.0) - Priority 1

**Problem:** "What was I doing?" when returning to projects

**Solution:** Session metadata with restoration prompt

- Captures: branch, modified files, next action, uncommitted changes
- Always prompts on `work` command (ADHD-friendly control)
- 80% reduction in re-entry overhead

**Effort:** 12 hours (Week 1-3)

**Impact:** 🔥 Highest (addresses #1 ADHD pain point)

---

### 2. Command Search (v5.2.0) - Priority 2

**Problem:** Users don't discover existing features

**Solution:** `flow search <query>` with intelligent ranking

- Searches built-in commands only (fast, no dependencies)
- Ranks by relevance: exact > partial > description
- Shows command + description + example

**Effort:** 6 hours (Week 4-5)

**Impact:** 🔥 High (unlocks existing features, reduces support burden)

---

### 3. Ecosystem Operations (v5.3.0) - Priority 3

**Problem:** Manual multi-package coordination

**Solution:** Delegate to RForge MCP (already implemented!)

- `flow ecosystem detect/cascade/deps/impact/status`
- Zero implementation cost (just wrapper commands)
- Graceful degradation if RForge not available

**Effort:** 4 hours (Week 6-7)

**Impact:** 🔥 High value, low effort

---

### 4. Workspaces + AI Energy (v5.4.0) - Priority 4

**Problem:** Manual project switching, no energy-aware suggestions

**Solution:** Named workspaces + AI energy tracking

- tmux integration with fallback mode (works without tmux)
- AI learns user energy patterns over time
- Energy-aware task suggestions in `flow next`

**Effort:** 24 hours (Week 8-12)

**Impact:** 🔥 Complex but valuable

---

## Design Decisions (8 Questions Answered)

### Question 1: Command Search Scope

**Decision:** Built-in commands only

**Rationale:**

- Fast (< 100ms guaranteed)
- No dependency on MCP servers
- Simpler implementation
- Can expand later if needed

---

### Question 2: Context Restoration Behavior

**Decision:** Always prompt (no silent behavior)

**Rationale:**

- Most ADHD-friendly (user maintains control)
- No configuration needed
- Clear what's happening (no surprises)
- Can quickly skip with 'n' or 'skip'

**Example:**

```
$ work flow-cli

📋 Last Session (2h ago):
  Branch: feature/context-restoration
  Files: lib/session-metadata.zsh (+89 lines)
  Next: Write tests for capture/restore

🔄 Restore? [Y/n/skip]
```

---

### Question 3: Workspace Dependencies

**Decision:** Provide fallback (tmux optional, not required)

**Rationale:**

- Broader compatibility (works even without tmux)
- Still provides value (quick project switching)
- Progressive enhancement (better with tmux)
- Users can install tmux later

**Impact:** +8 hours implementation (24h total vs 16h)

**With tmux:**

```bash
$ flow workspace start mcp-ecosystem
🚀 Creating tmux session with 3 windows
[Attaches to tmux]
```

**Without tmux:**

```bash
$ flow workspace start mcp-ecosystem
📦 Workspace: mcp-ecosystem
Select project: 1) statistical-research 2) nexus 3) rforge
```

---

### Question 4: Ecosystem Operations Naming

**Decision:** `flow ecosystem`

**Rationale:**

- Clear, descriptive
- Broader scope (not just R packages)
- Follows pattern: `flow doctor`, `flow session`, `flow workspace`
- Matches RForge MCP terminology

---

### Question 5: Energy Detection

**Decision:** AI-powered (analyze past patterns)

**Rationale:**

- Most personalized (learns YOUR patterns)
- Improves over time (better predictions)
- Still allows manual override
- Privacy-preserving (all data local)

**Impact:** +12 hours implementation (vs +6h for manual)

**Data Tracked:**

```json
{
  "timestamp": 1736419200,
  "hour": 15,
  "task": "Write documentation",
  "task_type": "low-focus",
  "completed": true,
  "duration_minutes": 45
}
```

**Prediction:**

```bash
$ flow next
🤖 Predicted Energy: Low (based on 3 PM pattern)

Suggested low-energy tasks:
  1. Write documentation
  2. Format code
  3. Review small PR

Override: flow energy high
```

---

### Question 6: Priority Order

**Decision:** 1→2→3→4 (Context → Search → Ecosystem → Workspaces)

**Rationale:**

- Highest impact/effort ratio first
- Each feature builds on previous
- Quick wins early (Search in just 6h)

---

### Question 7: Release Strategy

**Decision:** Incremental (v5.1.0, v5.2.0, v5.3.0, v5.4.0)

**Rationale:**

- Faster user feedback (validate early)
- Less risk (smaller changesets)
- More ADHD-friendly (celebrate wins quarterly)
- Easier rollback if issues

**Schedule:**

- **v5.1.0 (Week 3):** Context Restoration
- **v5.2.0 (Week 5):** Command Search
- **v5.3.0 (Week 7):** Ecosystem Operations
- **v5.4.0 (Week 12):** Workspaces + AI Energy

---

### Question 8: Documentation Style

**Decision:** Balanced (both reference + tutorials)

**Rationale:**

- Serves different learning styles
- Reference: Quick lookup for power users
- Tutorial: Learning for new users
- Matches existing flow-cli pattern

**Structure per feature:**

```
docs/
├── reference/<feature>-reference.md    # Command syntax, options
└── guides/<feature>-guide.md           # Step-by-step tutorial
```

---

## Implementation Timeline

### Sprint 1: v5.1.0 - Context Restoration (Week 1-3)

**Effort:** 12 hours

**Week 1: Core Functions (4h)**

- [x] Design session metadata format
- [ ] Create `lib/session-metadata.zsh`
- [ ] Implement capture/restore functions
- [ ] Implement duration formatting

**Week 2: Integration (4h)**

- [ ] Modify `commands/work.zsh` (restoration prompt)
- [ ] Modify finish logic (capture session state)
- [ ] Implement prompt UI (Y/n/skip)
- [ ] Implement restoration actions

**Week 3: Polish (4h)**

- [ ] Create test suite (20+ tests)
- [ ] Write reference documentation
- [ ] Write tutorial guide
- [ ] Release v5.1.0

---

### Sprint 2: v5.2.0 - Command Search (Week 4-5)

**Effort:** 6 hours

**Week 4: Core Search (4h)**

- [ ] Build search index (parse help text)
- [ ] Implement ranking algorithm
- [ ] Implement `flow search` command
- [ ] Display formatting

**Week 5: Polish (2h)**

- [ ] Test suite (15+ tests)
- [ ] Documentation (reference + guide)
- [ ] Release v5.2.0

---

### Sprint 3: v5.3.0 - Ecosystem Operations (Week 6-7)

**Effort:** 4 hours

**Week 6: Wrapper Commands (2h)**

- [ ] Create `commands/ecosystem.zsh`
- [ ] Implement delegation to RForge MCP
- [ ] Graceful degradation

**Week 7: Polish (2h)**

- [ ] Test suite (12+ tests)
- [ ] Documentation (reference + guide)
- [ ] Release v5.3.0

---

### Sprint 4: v5.4.0 - Workspaces + AI Energy (Week 8-12)

**Effort:** 24 hours

**Week 8-9: Workspace Management (8h)**

- [ ] Create `commands/workspace.zsh`
- [ ] Implement tmux integration
- [ ] Implement fallback mode (no tmux)
- [ ] Workspace state persistence

**Week 10-11: AI Energy Tracking (12h)**

- [ ] Create `lib/energy-tracking.zsh`
- [ ] Implement task logging
- [ ] Implement ML prediction (time-based clustering)
- [ ] Integration with `flow next`
- [ ] Integration with finish/win/stuck

**Week 12: Polish (4h)**

- [ ] Test suites (35+ tests total)
- [ ] Documentation (4 docs: 2 reference + 2 guides)
- [ ] Privacy opt-out: `FLOW_ENERGY_TRACKING=no`
- [ ] Release v5.4.0

---

## Success Metrics

### v5.1.0 (Context Restoration)

- [ ] 80% reduction in "what was I doing?" overhead
- [ ] Restoration prompt adds < 100ms to `work` command
- [ ] User satisfaction: 8/10

### v5.2.0 (Command Search)

- [ ] Users discover 2-3 new commands per month
- [ ] 50% reduction in "how do I...?" questions
- [ ] Search < 100ms response time

### v5.3.0 (Ecosystem Operations)

- [ ] 40% of R package users adopt
- [ ] 90% reduction in dependency errors
- [ ] 95% cascade operation success rate

### v5.4.0 (Workspaces + AI Energy)

- [ ] 30% of users create workspaces
- [ ] 50% reduction in switching overhead
- [ ] 75% AI prediction accuracy (2 weeks)
- [ ] 7/10 energy suggestion helpfulness

---

## Architecture Principles Maintained

All enhancements follow flow-cli's core principles:

✅ **Zero-Overhead:** Core commands remain < 10ms
✅ **Optional Enhancement:** All features gracefully degrade
✅ **ADHD-Friendly:** Discoverable, consistent, forgiving, fast
✅ **Pure ZSH:** No Node.js runtime required
✅ **Consistent Patterns:** Same patterns as existing dispatchers
✅ **Privacy-Preserving:** All data local, opt-out available

---

## Files to Create

### Sprint 1 (Context Restoration)

```
lib/session-metadata.zsh                              # NEW (300+ lines)
tests/session-metadata.test.zsh                       # NEW (400+ lines)
docs/reference/CONTEXT-RESTORATION-REFERENCE.md       # NEW
docs/guides/context-restoration-guide.md              # NEW
```

### Sprint 2 (Command Search)

```
commands/search.zsh                                   # NEW (200+ lines)
lib/search-index.json                                 # NEW (~15 KB)
tests/command-search.test.zsh                         # NEW (300+ lines)
docs/reference/COMMAND-SEARCH-REFERENCE.md            # NEW
docs/guides/command-search-guide.md                   # NEW
```

### Sprint 3 (Ecosystem Operations)

```
commands/ecosystem.zsh                                # NEW (150+ lines)
tests/ecosystem.test.zsh                              # NEW (250+ lines)
docs/reference/ECOSYSTEM-OPERATIONS-REFERENCE.md      # NEW
docs/guides/ecosystem-operations-guide.md             # NEW
```

### Sprint 4 (Workspaces + AI Energy)

```
commands/workspace.zsh                                # NEW (400+ lines)
lib/energy-tracking.zsh                               # NEW (350+ lines)
tests/workspace.test.zsh                              # NEW (400+ lines)
tests/energy-tracking.test.zsh                        # NEW (300+ lines)
docs/reference/WORKSPACE-REFERENCE.md                 # NEW
docs/reference/ENERGY-TRACKING-REFERENCE.md           # NEW
docs/guides/workspace-guide.md                        # NEW
docs/guides/energy-aware-workflow.md                  # NEW
```

**Total New Files:** 20 files (~8,000+ lines of code + docs)

---

## Files to Modify

### Sprint 1

- `commands/work.zsh` - Add restoration prompt
- `commands/finish.zsh` - Add capture logic

### Sprint 2

- `commands/flow.zsh` - Add search subcommand
- `docs/reference/COMMAND-QUICK-REFERENCE.md`

### Sprint 3

- `commands/flow.zsh` - Add ecosystem subcommand
- `docs/reference/COMMAND-QUICK-REFERENCE.md`

### Sprint 4

- `commands/flow.zsh` - Add workspace subcommand
- `commands/adhd.zsh` (next) - Energy-aware suggestions
- `commands/finish.zsh` - Energy logging
- `commands/capture.zsh` (win) - Energy logging
- `commands/adhd.zsh` (stuck) - Energy logging
- `docs/reference/COMMAND-QUICK-REFERENCE.md`

**Total Modified Files:** ~8 existing files

---

## Performance Targets

| Feature                    | Target     | Current |
| -------------------------- | ---------- | ------- |
| Context restoration prompt | < 100ms    | TBD     |
| Command search             | < 100ms    | TBD     |
| Ecosystem detect           | < 3s       | TBD     |
| Workspace start (tmux)     | < 2s       | TBD     |
| Workspace start (fallback) | < 500ms    | TBD     |
| Energy prediction          | < 50ms     | TBD     |
| Energy logging             | < 10ms     | TBD     |
| **Core commands**          | **< 10ms** | **✅**  |

---

## Risk Assessment

### Low Risk

- Context restoration (extends existing patterns)
- Command search (isolated feature)
- Ecosystem operations (delegates to existing MCP)

### Medium Risk

- Workspace fallback mode (dual codepaths increase complexity)
- AI energy tracking (privacy concerns, opt-out required)

### Mitigation Strategies

1. **Privacy:** Clear opt-out (`FLOW_ENERGY_TRACKING=no`), local-only data
2. **Complexity:** Thorough testing (82+ tests total)
3. **User education:** Complete documentation (reference + tutorials)
4. **Incremental releases:** Early feedback reduces risk

---

## Related Documents

### Comprehensive Analysis

- **BRAINSTORM-flow-cli-workflow-review-2026-01-09.md** (32 KB)
  - Complete analysis of 20 commands, 11 dispatchers
  - UX pain points and opportunities
  - Architecture recommendations

### Design Decisions

- **DESIGN-DECISIONS-2026-01-09.md** (12 KB)
  - All 8 design questions answered
  - Rationale for each decision
  - Implementation impact analysis

### Implementation Plan

- **`/Users/dt/.claude/plans/buzzing-riding-torvalds.md`** (645 lines)
  - Complete 4-sprint implementation plan
  - Week-by-week tasks
  - Testing strategies
  - Success metrics

### Project Status

- **`.STATUS`** (updated)
  - Current phase: v5.1.0 PLANNING
  - Sprint 1 tasks and timeline
  - Links to all related documents

### Previous Work

- **v5.0.0 Dotfile Management** (completed 2026-01-09)
  - `dot` dispatcher implemented (450 LOC)
  - Chezmoi + Bitwarden integration
  - 112+ tests passing
  - A- grade review (91/100)

---

## Timeline Summary

```
Week 1-3   ████████████ Sprint 1: Context Restoration (12h) → v5.1.0
Week 4-5   ██████ Sprint 2: Command Search (6h) → v5.2.0
Week 6-7   ████ Sprint 3: Ecosystem Operations (4h) → v5.3.0
Week 8-12  ████████████████████████ Sprint 4: Workspaces + AI (24h) → v5.4.0
           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
           Total: 12 weeks, 46 hours, 4 releases
```

---

## Next Steps

### Immediate (Today)

1. ✅ Comprehensive brainstorm complete
2. ✅ All 8 design questions answered
3. ✅ Implementation plan documented
4. ✅ .STATUS updated with Sprint 1 goals
5. ✅ Claude plan file updated
6. ✅ Summary document created

### This Week (Sprint 1 Kickoff)

1. [ ] Create feature branch: `git checkout -b feature/context-restoration`
2. [ ] Create skeleton files: `lib/session-metadata.zsh`, `tests/session-metadata.test.zsh`
3. [ ] Implement `_flow_capture_session_state()` function
4. [ ] Implement `_flow_restore_session_state()` function
5. [ ] Write initial unit tests

### Next 12 Weeks

- **Week 3:** Release v5.1.0 (Context Restoration)
- **Week 5:** Release v5.2.0 (Command Search)
- **Week 7:** Release v5.3.0 (Ecosystem Operations)
- **Week 12:** Release v5.4.0 (Workspaces + AI Energy)

---

## Questions & Answers

**Q: Why incremental releases instead of one big v6.0.0?**
A: Faster user feedback, less risk, more ADHD-friendly (celebrate wins quarterly).

**Q: Why provide tmux fallback instead of requiring it?**
A: Broader compatibility, progressive enhancement, users can upgrade later.

**Q: Why AI-powered energy instead of manual?**
A: Learns user's specific patterns (morning person vs night owl), improves over time, still allows manual override.

**Q: Can I opt out of energy tracking?**
A: Yes! `FLOW_ENERGY_TRACKING=no` or `flow energy clear` to delete all data.

**Q: What if I don't have RForge MCP installed?**
A: `flow ecosystem` commands will show helpful install instructions (graceful degradation).

**Q: Will these features slow down core commands?**
A: No! Core commands (work, dash, pick) remain < 10ms. New features are opt-in or isolated.

---

## Conclusion

This comprehensive plan delivers 4 high-impact workflow enhancements over 12 weeks with 46 hours of implementation effort. The incremental release strategy ensures early user feedback, reduces risk, and maintains momentum with quarterly wins.

The plan addresses the #1 ADHD pain point (context restoration), unlocks existing features (command search), enables ecosystem-wide operations (RForge delegation), and adds sophisticated multi-project workflows with AI-powered energy awareness.

All enhancements maintain flow-cli's core principles: zero-overhead, ADHD-friendly design, pure ZSH implementation, and graceful degradation.

---

**Status:** ✅ Planning complete, design approved, ready for Sprint 1 implementation
**Next Milestone:** v5.1.0 release (Week 3)
**Total Impact:** 70-80% reduction in workflow friction

---

**Prepared by:** Claude Sonnet 4.5 (Deep Brainstorm Mode)
**Date:** 2026-01-09
**Version:** 1.0
