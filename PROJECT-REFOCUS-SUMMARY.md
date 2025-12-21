# Project Refocus Summary

**Date:** 2025-12-20
**Action:** Comprehensive project scope redefinition
**Outcome:** Personal productivity & project management system

---

## What Changed

### Before (Unclear Focus)

- ❓ **Purpose:** Documentation repo? Framework? Tool?
- ❓ **User:** Me? Others? Academic community?
- ❓ **Scope:** Too broad, too many directions
- 📦 **Status:** Just removed Electron app, simplified to CLI

### After (Crystal Clear Focus)

- ✅ **Purpose:** Personal productivity & project management system
- ✅ **User:** DT (me) - managing 30+ projects
- ✅ **Scope:** 5 core features, 3-month roadmap
- ✅ **Architecture:** Three-layer design (ZSH → Node.js → External tools)
- ✅ **Integration:** Leverage existing dev-tools packages (no duplication)

---

## Core Features

### 1. Workflow State Manager ⭐

**Problem:** Losing mental context when switching between 30+ projects

**Solution:** Track, persist, and restore workflow state

**Key Features:**

- Session persistence (save project + context + next actions)
- Automatic restoration (<30 seconds to get back to work)
- Integration with existing `work`/`finish` commands
- Session templates (R package, research, teaching)

**Success Metric:** Never lose context, <30 second restoration

### 2. Project Dashboard ⭐

**Problem:** Hard to see status of all 32 projects at a glance

**Solution:** Multi-project overview dashboard

**Key Features:**

- Aggregate status from all .STATUS files
- Group by category (R packages, teaching, research, dev-tools)
- Highlight active projects and quick wins
- Export to Apple Notes (via apple-notes-sync)

**Success Metric:** See all projects in <2 seconds, find quick wins in <10 seconds

### 3. Project Dependency Tracker ⭐

**Problem:** Unclear which projects depend on each other

**Solution:** Map project relationships and impact analysis

**Key Features:**

- Track dependencies (depends-on, used-by, related-to, blocks)
- Impact analysis ("What breaks if I update medfit?")
- Ecosystem visualization (mediationverse packages)
- Relationship graph

**Success Metric:** Understand dependencies instantly, clear impact awareness

### 4. Multi-Project Task Aggregation

**Problem:** Next actions scattered across 32 .STATUS files

**Solution:** Unified task list across all projects

**Key Features:**

- Aggregate tasks from all .STATUS files
- Filter by priority (P0/P1/P2/P3), effort, category
- Quick wins view (tasks <30 min)
- Due date tracking

**Success Metric:** Find next task in <5 seconds, identify quick wins instantly

### 5. Project Picker (pp) ⭐

**Problem:** Slow project navigation, hard to remember project names

**Solution:** Fast fuzzy finder for project switching

**Key Features:**

- Fuzzy search by name
- Preview pane with .STATUS content
- Recent projects first
- One-key selection → cd + show status

**Success Metric:** Switch projects in <30 seconds with visual preview

---

## Integration: The Magic

**These features work together:**

1. **Start session:** `work rmediation`
   - Detects project type: R package (via zsh-claude-workflow)
   - Switches terminal context (via aiterm if installed)
   - Saves session with all context
2. **Resume session:** New shell → restore prompt
   - Restores project (cd, show context)
   - Ready to work in <30 seconds
3. **View dashboard:** `dashboard`
   - Shows all 32 projects
   - Highlights quick wins and priorities
4. **Switch project:** `pp` (project picker)
   - Fuzzy finder interface
   - Preview .STATUS content
   - Fast navigation

**Result:** Complete workflow management (discovery → selection → restoration → productivity)

---

## Implementation Roadmap (3 Months)

### Week 1: Foundation (Dec 20-27)

- [x] PROJECT-SCOPE.md created
- [x] ARCHITECTURE-INTEGRATION.md created
- [ ] Create directory structure
- [ ] Set up zsh-claude-workflow integration
- [ ] Build basic project scanner

### Week 2: State Manager Core (Dec 28 - Jan 3)

- [ ] Build session persistence (save/load)
- [ ] Create session-adapter.js
- [ ] Implement work/finish/resume commands
- [ ] Test with 3 real projects

### Week 3: Dashboard (Jan 4-10)

- [ ] Adapt .STATUS parser from apple-notes-sync
- [ ] Build dashboard generator
- [ ] Create dashboard command with colored output
- [ ] Test with all 32 projects

### Week 4: Project Picker (Jan 11-17)

- [ ] Build project scanner with search/filter
- [ ] Integrate fzf for fuzzy finding
- [ ] Add preview pane with .STATUS content
- [ ] Test fast project switching

### Month 2: Dependency Tracking & Tasks (Jan 18 - Feb 17)

- [ ] Build dependency tracker
- [ ] Map project relationships
- [ ] Create task aggregator
- [ ] Implement filtering and sorting

### Month 3: Polish & Evaluate (Feb 18 - Mar 17)

- [ ] Session templates
- [ ] Session history and analytics
- [ ] Integration enhancements (aiterm, Apple Notes)
- [ ] Comprehensive testing
- [ ] Documentation
- [ ] Evaluate success criteria

---

## Success Criteria (3 Months)

### Workflow State Manager

- ✅ Session restoration: <30 seconds
- ✅ Context loss: Never (100% restoration)
- ✅ Morning startup: 2-minute dashboard review → productive
- ✅ Project switching: <1 minute

### Project Dashboard

- ✅ Overview speed: <2 seconds to see all projects
- ✅ Quick wins: Find tasks <30 min in <10 seconds
- ✅ Status visibility: All projects visible at a glance

### Dependency Tracker

- ✅ Impact awareness: Instant understanding of dependencies
- ✅ Relationship clarity: Clear project connections

### Task Aggregation

- ✅ Task discovery: Find next task in <5 seconds
- ✅ Priority clarity: P0/P1/P2/P3 visible instantly

### Project Picker

- ✅ Switching speed: <30 seconds between projects
- ✅ Visual preview: See .STATUS before switching

### Combined

- ✅ Complete workflow: Discovery → Selection → Restoration in <1 minute
- ✅ Zero cognitive overhead: Don't think about tools, they're just there
- ✅ Daily workflow satisfaction: 8+/10

---

## Integration with Existing Dev-Tools

### Leveraging, Not Duplicating

| Package | What We're Using | Integration Method |
|---------|------------------|-------------------|
| **zsh-claude-workflow** | Project detection, context gathering | Symlink lib/, call commands |
| **aiterm** | Terminal context switching | Call `ait context apply` |
| **apple-notes-sync** | .STATUS parser, dashboard patterns | Adapt scanner.sh logic |
| **obsidian-cli-ops** | ZSH+Python hybrid pattern | Copy architecture approach |
| **dev-planning** | Hub organization pattern | Replicate PROJECT-HUB.md structure |

### What We're Building (Unique)

- ✅ **Session State Manager** - No existing tool does this
- ✅ **Multi-Project Dashboard** - Global view across 30+ projects
- ✅ **Dependency Tracker** - Unique to multi-project coordination
- ✅ **Task Aggregator** - Cross-project task list
- ✅ **Project Picker** - Fast fuzzy finder with preview

---

## Architecture

### Three-Layer Design

```
┌─────────────────────────────────────────┐
│ FRONTEND (ZSH Shell)                    │
│ - Commands: work, finish, dashboard, pp│
│ - Colored output, fzf integration      │
└──────────────┬──────────────────────────┘
               │ exec(), JSON
┌──────────────▼──────────────────────────┐
│ BACKEND (Node.js Core)                  │
│ - Session manager, project scanner     │
│ - Dashboard generator, task aggregator │
└──────────────┬──────────────────────────┘
               │ import, shell exec
┌──────────────▼──────────────────────────┐
│ INTEGRATION (External Tools)            │
│ - zsh-claude-workflow, aiterm          │
│ - apple-notes-sync patterns            │
└─────────────────────────────────────────┘
```

See [ARCHITECTURE-INTEGRATION.md](ARCHITECTURE-INTEGRATION.md) for complete details.

---

## What This Solves

### Pain Point 1: Context Switching

**Before:** Spend 5-10 minutes re-orienting when switching projects
**After:** <1 minute with automatic context restoration

### Pain Point 2: Project Discovery

**Before:** "What was I working on? Which projects are active?"
**After:** `dashboard` → See all 32 projects in 2 seconds

### Pain Point 3: Task Overload

**Before:** Next actions scattered across 32 .STATUS files
**After:** `tasks --quick-wins` → 7 tasks <30 min, pick one

### Pain Point 4: Dependency Confusion

**Before:** "Will updating medfit break rmediation?"
**After:** `deps medfit --impact` → Know exactly what's affected

### Pain Point 5: Project Navigation

**Before:** `cd ~/projects/...` → Type full path, misremember names
**After:** `pp` → Fuzzy find, preview, select in <30 seconds

---

## What's NOT Changing

✅ **Keep:** Zero external dependencies (vanilla Node.js + ZSH)
✅ **Keep:** Personal tool (no external users, no maintenance burden)
✅ **Keep:** Minimal tech stack (JSON files, simple CLI)
✅ **Keep:** ADHD-optimized design (clear focus, immediate value)
✅ **Keep:** Integration with existing dev-tools ecosystem

❌ **Not building:** Web dashboard, desktop app, multi-user support
❌ **Not building:** Complex analytics, advanced visualizations
❌ **Not building:** Shareable framework (can extract later if valuable)
❌ **Not building:** MCP Server Hub (removed from scope)

---

## Technology Stack

**No changes to current stack:**

- **Runtime:** Node.js 18+ (zero npm packages)
- **Shell:** ZSH (existing configuration)
- **Storage:** JSON files (simple, debuggable)
- **Integration:** CLI adapters → exec() → ZSH

**Additions (minimal):**

- Session state schema (JSON)
- Project registry schema (JSON)
- State manager module (save/load)
- Dashboard generator (status aggregation)
- Dependency tracker (relationship mapping)

**External Tools (integration only):**

- zsh-claude-workflow (REQUIRED) - Project detection
- aiterm (OPTIONAL) - Terminal context
- apple-notes-sync (OPTIONAL) - Dashboard export
- fzf (OPTIONAL) - Fuzzy finder

---

## Example Workflows

### Monday Morning

```bash
$ # New shell after weekend
> Resume "rmediation"? (Last: Friday 5:30 PM)
> y
> ✓ Project: rmediation (R package)
> ✓ Task: Fix failing test
> [Productive in 20 seconds]
```

### Context Switch

```bash
$ # Switch from R package to teaching
> finish  # saves session
> pp
> [Fuzzy finder: stat-440]
> ✓ Switched to stat-440
> ✓ Next: Grade HW 5
> [Right context automatically]
```

### Quick Wins

```bash
$ # Friday afternoon, need easy tasks
> tasks --quick-wins
> ⚡ rmediation: Fix typo in README
> ⚡ stat-440: Upload answer key
> ⚡ zsh-config: Update CLAUDE.md
> [7 tasks found in 3 seconds]
```

### Dependency Check

```bash
$ # About to update medfit
> deps medfit --impact
> Used By: rmediation, probmed, product-of-three
> [Clear impact in 2 seconds]
```

---

## Key Decisions

### 2025-12-20: Removed MCP Server Hub

- **Previous:** Dual objective (State Manager + MCP Hub)
- **Decision:** Focus on project management and personal productivity only
- **Rationale:** MCP hub is separate concern, project management is higher priority
- **Impact:** Simpler scope, clearer focus, faster implementation

### 2025-12-20: Integration over Duplication

- **Decision:** Leverage existing dev-tools packages instead of reimplementing
- **Strategy:** Thin orchestration layer over existing tools
- **Impact:** Faster development, better integration, less maintenance

### 2025-12-20: Three-Layer Architecture

- **Decision:** Frontend (ZSH) → Backend (Node.js) → Integration (External)
- **Benefit:** Clear separation, testable core, flexible integration
- **Impact:** Maintainable architecture, easy to extend

### 2025-12-20: Personal Tool First

- **Focus:** Build for personal use, not shareable framework
- **Can share later if valuable**
- **Low maintenance burden**

### 2025-12-20: Removed App Workspace

- **Archive Electron app** (environment issues)
- **Focus on CLI development**
- **753 lines preserved for future**

---

## Open Questions

### State Persistence

- How often to auto-save? (every command? 15 min? on idle?)
- Minimum state needed for restoration?
- Include open files?

**Recommendation:** Save on `finish`, auto-save every 15 min, prompt on new shell

### Project Discovery

- Auto-scan ~/projects/ or require manual registration?
- How to handle excluded projects?

**Recommendation:** Auto-scan with manual opt-out (.zsh-ignore file)

### Integration

- Auto-activate aiterm or ask first?
- How to handle missing optional dependencies?

**Recommendation:** Auto-call if installed, silent skip if not

---

## Success Stories (What Good Looks Like)

**Complete restoration:**

> Project + context in <30 seconds

**Zero cognitive overhead:**

> Don't think about which tools to use, they're just there

**Fast discovery:**

> Find right project or task in <10 seconds

**Clear dependencies:**

> Understand project impact instantly

**Daily overview:**

> See all 32 projects at a glance in 2 seconds

---

## Next Immediate Steps

1. **Create directory structure** (5 min)

   ```bash
   mkdir -p cli/core cli/lib config/zsh/functions data/sessions data/projects integrations
   ```

2. **Set up zsh-claude-workflow integration** (15 min)

   - Create symlink to lib/
   - Build project-detector-bridge.js
   - Test detection on 3 projects

3. **Build minimal session manager** (Week 2)

   - Start simple (without complex features)
   - Test with 1 project for 1 week
   - Iterate based on real use

---

## Files Created Today

1. **PROJECT-SCOPE.md** (650+ lines)

   - Complete project specification (project management focus)
   - 3-month roadmap
   - Success criteria and use cases
   - Architecture overview

2. **ARCHITECTURE-INTEGRATION.md** (500+ lines)

   - Complete architecture design
   - Frontend/backend separation
   - Integration strategy with existing dev-tools
   - Data flow examples

3. **PROJECT-REFOCUS-SUMMARY.md** (this file)

   - Executive summary of refocus
   - Quick reference for the plan
   - Key decisions documented

---

**Status:** ✅ Project refocus complete
**Clarity:** ✅ Crystal clear objectives and roadmap
**Architecture:** ✅ Three-layer design defined
**Integration:** ✅ Leverage existing dev-tools packages
**Next Action:** Create directory structure and set up integrations (Week 1, task 3)
**Estimated Time to Value:** 2 weeks (minimal state manager working)
