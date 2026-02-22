# Project Scope: Personal Productivity & Project Management System

**Created:** 2025-12-20
**Revised:** 2025-12-20 (removed MCP hub, added architecture)
**Status:** Active
**Type:** Personal Productivity Tool

---

## Objective

Build a **personal productivity and project management system** that eliminates context-switching overhead for managing 30+ simultaneous projects across R packages, teaching, research, and development.

**Core Principle:** Integrate with existing dev-tools packages rather than duplicating functionality.

---

## Target User

**DT** (personal productivity tool)

**Use Case:** Academic developer juggling:
- 6 R packages (active development + maintenance)
- 3 teaching courses (active + archived)
- 11 research projects (various stages)
- 16 dev-tools projects (shell automation, CLI tools, etc.)

**Pain Points:**
1. **Context Switching:** Losing mental context when switching between projects
2. **Project Discovery:** Hard to remember all 30+ projects and their status
3. **Task Overload:** Next actions scattered across projects, no unified view
4. **Morning Startup:** 10+ minutes to remember what I was working on
5. **Dependency Confusion:** Unclear which projects depend on others

---

## Core Features

### 1. Workflow State Manager ⭐ (PRIMARY)

**What It Does:**
Tracks, persists, and restores workflow state across sessions and projects.

**State Tracked:**
- **Session State:** Active project, current task, started time
- **Mental Context:** What I was thinking, next steps, blockers
- **Project State:** .STATUS content, git status, recent commits
- **Work Log:** Time tracking, session notes, accomplishments
- **Environment:** Last working directory, git branch

**Restoration Flow:**

```text
1. Start shell → Detect last session
2. Prompt: "Resume [project-name]? (Last: 2 hours ago)"
3. If yes:
   - cd to project directory
   - Show last context (what you were doing)
   - Display next actions from .STATUS
   - Ready to work in <30 seconds
```

**Integration:**
- Uses **vendored functions** from zsh-claude-workflow (~300 lines ported)
- Optionally coordinates with **aiterm** for terminal context switching (if installed)
- Stores session state in `~/.local/share/flow-cli/sessions/`
- **Standalone** - No external dependencies required

---

### 2. Project Dashboard ⭐ (CORE VISIBILITY)

**What It Does:**
Displays comprehensive overview of all projects at a glance.

**Dashboard View:**

```text
═══════════════════════════════════════════════
Personal Projects Overview (32 total)
═══════════════════════════════════════════════

R Packages (Active: 3, Paused: 3)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  rmediation    ● 3 hours ago    Fix failing test
  medfit        ● Yesterday      Update vignette
  probmed       ⏸ 3 days ago     Blocked: reviewer feedback

Teaching (Active: 2)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  stat-440      ● Today          Grade HW 5
  causal-inf    ● 2 days ago     Prepare Week 14 lecture

Dev Tools (Active: 5, Archive: 3)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  zsh-config    ● Now            Architecture design
  aiterm        ● 2 days ago     Testing v0.1.0
  obs-cli       ● 4 days ago     Simplification phase

Quick Wins Available: 7 tasks < 30 minutes
Next Review: stat-440 (HW 5 due Friday)
```

**Integration:**
- Adapts **.STATUS parser** logic from apple-notes-sync
- Uses **vendored project detection** functions
- Can export to Apple Notes via apple-notes-sync scripts (optional)

---

### 3. Project Dependency Tracker ⭐ (COORDINATION)

**What It Does:**
Maps relationships between projects to understand impact of changes.

**Tracked Relationships:**
- **Depends On:** Project requires another (e.g., rmediation depends on medfit)
- **Used By:** Project is used by another (e.g., zsh-claude-workflow used by aiterm)
- **Related To:** Projects in same ecosystem (e.g., all mediationverse packages)
- **Blocks:** Project blocked by another (e.g., probmed blocked by reviewer feedback)

**Use Cases:**
- "What projects will be affected if I update medfit?"
- "Why is probmed paused?" → "Blocked by reviewer feedback on sensitivity"
- "Show me all projects in mediationverse ecosystem"

---

### 4. Multi-Project Task Aggregation

**What It Does:**
Aggregates next actions across all projects into unified task list.

**Task Views:**
- **By Priority:** P0 (urgent) → P3 (someday)
- **By Effort:** Quick wins (<30 min) → Long projects (>4 hours)
- **By Category:** R packages, teaching, research, dev-tools
- **By Date:** Due today, this week, this month

**Example Output:**

```text
Quick Wins (< 30 min):
  ⚡ rmediation: Fix typo in README
  ⚡ stat-440: Upload answer key
  ⚡ zsh-config: Update CLAUDE.md

Medium Tasks (1-2 hours):
  🔧 medfit: Write new vignette
  🔧 aiterm: Test Python 3.12 compatibility

Long Projects (> 4 hours):
  🏗️ probmed: Respond to all reviewer comments
  🏗️ obs-cli: Complete simplification phase
```

---

### 5. Project Picker (pp) ⭐ (ADHD-FRIENDLY UX)

**What It Does:**
Fast fuzzy finder for switching between projects.

**Interface:**

```bash
> pp
# Opens fzf with project list:

> rmed▊
  📦 rmediation         R package    Fix failing test
  📊 causal-inference   Teaching     Prepare lecture 14
  🔧 flow-cli  Dev tool     Architecture design

# Select → cd to project + show .STATUS
```

**Features:**
- Fuzzy search by name
- Filter by type/category
- Recent projects first
- Preview pane shows .STATUS content

---

## Architecture

**Three-Layer Design:**

```text
┌─────────────────────────────────────────────────────────┐
│ FRONTEND LAYER (ZSH Shell)                              │
│ - User commands (work, finish, dashboard, pp)           │
│ - Interactive prompts, fzf integration                  │
│ - Terminal UI (colored output, tables)                  │
└──────────────────┬──────────────────────────────────────┘
                   │ exec(), JSON communication
┌──────────────────▼──────────────────────────────────────┐
│ BACKEND LAYER (Node.js Core)                            │
│ - Session state manager                                 │
│ - Project scanner (uses zsh-claude-workflow)            │
│ - Dependency tracker                                    │
│ - Dashboard generator (adapts apple-notes-sync)         │
│ - Task aggregator                                       │
└──────────────────┬──────────────────────────────────────┘
                   │ import/require, shell exec
┌──────────────────▼──────────────────────────────────────┐
│ INTEGRATION LAYER (External Tools)                      │
│ - zsh-claude-workflow (project detection)               │
│ - aiterm (terminal context switching)                   │
│ - apple-notes-sync (dashboard patterns)                 │
└─────────────────────────────────────────────────────────┘
```

---

## Integration with Existing Dev-Tools

### Vendoring Essential Functions

**UPDATE 2025-12-20:** Changed from dependency approach to porting functions.

| Feature Needed | Source Tool | Integration Method |
|----------------|-------------|-------------------|
| Project type detection | zsh-claude-workflow | **Port** project-detector.sh (~200 lines) |
| Shared utilities | zsh-claude-workflow | **Port** core.sh (~100 lines) |
| Terminal switching | aiterm | **Optional** - Call `ait context apply` if installed |
| .STATUS parsing | apple-notes-sync | **Adapt** scanner.sh logic |
| Dashboard templates | apple-notes-sync | **Reuse** RTF/AppleScript patterns |

**Total Vendored Code:** ~300 lines from zsh-claude-workflow

**Why Port Instead of Depend:**
- ✅ Truly standalone package (npm-installable)
- ✅ No external dependencies required
- ✅ Works out-of-box for all users
- ✅ Clear attribution to original source

### What We're Building (Unique Contributions)

- **Session State Manager** - No existing tool handles session persistence
- **Multi-Project Dashboard** - Global view across all 30+ projects
- **Dependency Tracker** - Map project relationships
- **Task Aggregator** - Unified cross-project task list
- **Project Picker** - Fast fuzzy finder with preview

---

## Success Criteria

### Primary Metrics (Workflow State Manager)

- ✅ **Context restoration:** <30 seconds from shell start to productive work
- ✅ **Zero context loss:** 100% session restoration accuracy
- ✅ **Morning startup:** 2-minute dashboard review → know exactly what to do
- ✅ **Project switching:** <1 minute between projects

### Secondary Metrics (Dashboard & Coordination)

- ✅ **Project visibility:** See all 30+ projects at a glance
- ✅ **Quick win identification:** Find tasks <30 min in <10 seconds
- ✅ **Dependency awareness:** Understand project relationships instantly
- ✅ **Task prioritization:** Clear view of P0/P1/P2/P3 across all projects

### User Experience

- ✅ **ADHD-friendly:** Clear visual hierarchy, immediate feedback, low cognitive load
- ✅ **Fast:** All operations complete in <5 seconds
- ✅ **Reliable:** Never lose work, always recoverable
- ✅ **Intuitive:** Commands follow existing patterns (work/finish/dashboard)

---

## Implementation Roadmap (3 Months)

### Week 1: Foundation & Porting (Dec 20-27) 🚧

**Goal:** Set up architecture and port essential functions

- [x] Create PROJECT-SCOPE.md (this document)
- [x] Update documents to reflect porting approach
- [ ] Create directory structure (cli/core, cli/vendor, data/sessions)
- [ ] Port zsh-claude-workflow functions (~300 lines, 3 hours)
- [ ] Build basic project scanner using vendored functions

**Deliverable:** Can scan all projects and detect types (standalone, no dependencies)

---

### Week 2: Session State Manager (Dec 28 - Jan 3)

**Goal:** Basic session persistence and restoration

**Core Components:**
- `cli/core/session-manager.js` - Save/load/restore logic
- `cli/adapters/session-adapter.js` - ZSH bridge
- `config/zsh/functions/session-commands.zsh` - User commands

**Commands:**
- `work <project>` - Start session (detect type, save state)
- `finish [message]` - End session (save notes, time tracking)
- `resume` - Restore last session (prompt on new shell)

**Test Plan:**
- Use with 3 different projects for 1 week
- Verify restoration works after reboot
- Measure time to productive work (<30 sec goal)

**Deliverable:** Working session persistence, tested with real projects

---

### Week 3: Dashboard & Status Aggregation (Jan 4-10)

**Goal:** Multi-project overview dashboard

**Core Components:**
- `cli/core/dashboard-generator.js` - Aggregate status from all projects
- Adapt scanner.sh logic from apple-notes-sync
- `config/zsh/functions/dashboard-commands.zsh` - Display formatting

**Commands:**
- `dashboard` - Show all projects overview
- `dashboard --category r-packages` - Filter by category
- `dashboard --quick-wins` - Show tasks <30 min

**Features:**
- Group by category (R packages, teaching, research, dev-tools)
- Highlight active projects (worked on today/yesterday)
- Show quick wins separately
- Calculate summary statistics

**Deliverable:** Beautiful terminal dashboard showing all 32 projects

---

### Week 4: Project Picker & Navigation (Jan 11-17)

**Goal:** Fast project switching with fuzzy finder

**Core Components:**
- `cli/core/project-scanner.js` - Search/filter projects
- `config/zsh/functions/project-commands.zsh` - Fzf integration

**Commands:**
- `pp` - Project picker (fzf interface)
- `pp --recent` - Recent projects only
- `pp --category teaching` - Filter by category

**Features:**
- Fuzzy search by name
- Preview pane shows .STATUS content
- Recent projects sorted first
- One-key selection → cd + show status

**Deliverable:** Sub-second project switching with visual preview

---

### Month 2: Dependency Tracking & Task Aggregation (Jan 18 - Feb 17)

**Goal:** Understand project relationships and unified task view

**Week 5-6: Dependency Tracker**
- `cli/core/dependency-tracker.js` - Map relationships
- Define dependency types (depends-on, used-by, related-to, blocks)
- Build dependency graph from .STATUS files or manual config
- Commands: `deps <project>`, `deps --graph`, `deps --impact`

**Week 7-8: Task Aggregator**
- `cli/core/task-aggregator.js` - Collect next actions from all .STATUS files
- Group by priority, effort, category, date
- Commands: `tasks`, `tasks --quick-wins`, `tasks --p0`
- Smart filtering and sorting

**Deliverable:** Know which projects depend on each other, unified task list

---

### Month 3: Polish & Enhancement (Feb 18 - Mar 17)

**Goal:** Production-ready with advanced features

**Week 9-10: Session Templates & History**
- Session templates (R package, teaching, research)
- Session history viewer
- Session analytics (time per project, productivity patterns)

**Week 11: Integration Enhancements**
- Deeper aiterm integration (auto-switch profiles)
- Apple Notes export (via apple-notes-sync)
- Git integration (branch tracking, commit history)

**Week 12: Testing & Documentation**
- Comprehensive test suite (Node.js + ZSH tests)
- User documentation (quick start, command reference)
- Architecture documentation updates
- Performance optimization

**Deliverable:** Production-ready personal productivity system

---

## Use Cases & Scenarios

### Scenario 1: Monday Morning Startup

```bash
# 8:00 AM - Start shell
> New shell detected. Resume last session?

  Last session: rmediation (Friday 5:30 PM)
  Task: Fix failing test in test-mediation.R
  Duration: 2 hours 15 minutes

> [y/n] y

> ✓ Restored: rmediation
> ✓ Directory: ~/projects/r-packages/stable/rmediation
> ✓ Branch: main (dirty)
> ✓ Task: Fix failing test

Next actions:
  1. Run test suite (rtest)
  2. Fix issue in mediation.R line 342
  3. Update documentation

[Ready to work in 20 seconds]
```

---

### Scenario 2: Mid-Day Context Switch

```bash
# Working on R package, need to switch to teaching

> finish "Fixed test, updated docs"
✓ Session saved: rmediation (2.5 hours)
✓ Worklog updated

> pp
# Fuzzy finder opens
> stat▊

  📊 stat-440           Teaching     Grade HW 5
  📦 rmediation         R package    ✓ Just finished
  🔧 statistical-research  Dev tool   Update MCP server

# Select stat-440

> ✓ Switched to: stat-440
> ✓ Directory: ~/projects/teaching/stat-440
> ✓ Next: Grade HW 5 (due Friday)

Terminal profile: Teaching (yellow theme)
[Switched in <30 seconds]
```

---

### Scenario 3: Finding Quick Wins

```bash
# Friday afternoon, tired, need easy tasks

> tasks --quick-wins

Quick Wins (< 30 min):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ⚡ rmediation         Fix typo in README
  ⚡ stat-440           Upload answer key to Canvas
  ⚡ flow-cli  Update CLAUDE.md
  ⚡ medfit             Increment version number
  ⚡ aiterm             Add test for new feature

> work rmediation
# Knock out easy tasks, build momentum
```

---

### Scenario 4: Understanding Dependencies

```bash
# About to update medfit, which projects will be affected?

> deps medfit --impact

medfit → Impact Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Used By (3 projects will be affected):
  📦 rmediation        (depends on medfit)
  📦 probmed           (depends on medfit)
  📊 product-of-three  (uses medfit in analysis)

Recommendation:
  1. Update medfit
  2. Test rmediation with new medfit
  3. Test probmed with new medfit
  4. Update product-of-three analysis if API changed

[Clear understanding of impact in <5 seconds]
```

---

### Scenario 5: Dashboard Overview

```bash
# What's the state of all my projects?

> dashboard

═══════════════════════════════════════════════
Personal Projects Overview (32 total)
═══════════════════════════════════════════════

📊 Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Active:    12 projects
  Paused:    8 projects
  Blocked:   3 projects
  Archived:  9 projects

🎯 Priorities
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  P0 (Urgent):        3 projects
  P1 (High):          5 projects
  P2 (Medium):        7 projects
  P3 (Low):          17 projects

⚡ Quick Wins Available: 7 tasks (< 30 min)

📦 R Packages (Active: 3, Paused: 3)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  rmediation    ● 3 hours ago    P0  Fix failing test
  medfit        ● Yesterday      P1  Update vignette
  probmed       ⏸ 3 days ago     P2  Blocked: reviewer

📊 Teaching (Active: 2)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  stat-440      ● Today          P0  Grade HW 5
  causal-inf    ● 2 days ago     P1  Lecture 14

[Complete overview in <2 seconds]
```

---

## Technology Stack

### Runtime

- **ZSH** - Frontend (user commands, output formatting)
- **Node.js 18+** - Backend (zero external npm dependencies)
- **JSON** - Data storage (simple, debuggable, version-controllable)

### External Tools (Integration Layer)

- **zsh-claude-workflow** (REQUIRED) - Project detection
- **aiterm** (OPTIONAL) - Terminal context switching
- **apple-notes-sync** (OPTIONAL) - Dashboard export
- **fzf** (OPTIONAL) - Fuzzy finder for project picker

### Data Storage

```text
~/.local/share/flow-cli/
├── sessions/
│   ├── current.json              # Active session
│   └── history/                  # Past sessions (date-named)
│       ├── 2025-12-20.json
│       └── 2025-12-19.json
├── projects/
│   ├── registry.json             # All known projects
│   └── dependencies.json         # Project relationships
└── cache/
    └── last-scan.json            # Cached project scan results
```

---

## Future Enhancements (Beyond 3 Months)

### AI Assistant Integration

**Goal:** Smart recommendations and automation

**Features:**
- Smart project suggestions based on context
- Automatic task generation from .STATUS files
- Pattern recognition (e.g., "You usually work on R packages Friday afternoons")
- Natural language queries ("What teaching tasks are due this week?")

**Timeline:** Month 4-6
**Dependencies:** Gemini API or local LLM integration

---

### Advanced Analytics

**Goal:** Productivity insights and optimization

**Features:**
- Time tracking across projects
- Productivity patterns (best times of day for each project type)
- Project velocity (how quickly making progress)
- Bottleneck detection (projects frequently blocked)

**Timeline:** Month 6+

---

### Multi-User Support (Maybe Never)

**Current:** Personal tool for DT only
**Future:** Could be extracted into shareable framework
**Decision:** Build for personal use first, extract later if valuable

---

## What's NOT in Scope

❌ **MCP Server Hub** - Removed from scope (was in earlier versions)
❌ **Web Dashboard** - CLI-only (can add later with Tauri if needed)
❌ **Desktop App** - Archived Electron app, focusing on CLI
❌ **Multi-user support** - Personal tool only
❌ **Cloud sync** - Local JSON files (already in Google Drive via symlinks)
❌ **Mobile app** - Out of scope
❌ **Advanced visualizations** - Terminal output only (colored tables, not graphs)

---

## Open Questions

### Technical Decisions

1. **Session Auto-save Frequency**
   - Every command? 15 minutes? On idle?
   - **Recommendation:** Save on `finish`, auto-save every 15 min, prompt on new shell

2. **Project Discovery Scope**
   - Scan all of ~/projects/ or require manual registration?
   - **Recommendation:** Auto-scan with manual opt-out (.zsh-ignore file)

3. **Dependency Definition**
   - Manual config or auto-detect from imports?
   - **Recommendation:** Start manual, add auto-detection later

### Integration Decisions

1. **aiterm Coordination**
   - Auto-call or user opt-in?
   - **Recommendation:** Auto-call if installed, silent skip if not

2. **Session Storage Location**
   - `~/.zsh-sessions/` vs `~/.local/share/flow-cli/`?
   - **Recommendation:** `~/.local/share/flow-cli/` (XDG-compliant)

---

## Getting Started

### Prerequisites

```bash
# Required (minimal)
zsh --version          # ZSH 5.8+
node --version         # Node.js 18+

# Optional (enhanced features)
ait --version          # aiterm (terminal context switching)
fzf --version          # Fuzzy finder (project picker)
```

**No external dependencies required!** flow-cli is standalone.

### Installation (Week 1+)

**From npm (future):**

```bash
npm install -g flow-cli
```

**From source (current):**

```bash
cd ~/projects/dev-tools/flow-cli

# Create directory structure
./scripts/setup.sh

# Port zsh-claude-workflow functions (one-time, 3 hours)
mkdir -p cli/vendor/zsh-claude-workflow
cp ~/projects/dev-tools/zsh-claude-workflow/lib/project-detector.sh cli/vendor/zsh-claude-workflow/
cp ~/projects/dev-tools/zsh-claude-workflow/lib/core.sh cli/vendor/zsh-claude-workflow/

# Build project scanner
npm install  # (no dependencies, just sets up workspace)
npm run dev  # Test scanner

# Scan projects
node cli/core/project-scanner.js ~/projects/
```

---

## Success Stories (What Good Looks Like)

**Morning startup:**
> Open terminal → "Resume rmediation?" → y → Productive in 20 seconds

**Context switching:**
> `finish` → `pp` → Select project → Switched in <30 seconds

**Finding work:**
> `tasks --quick-wins` → 7 easy tasks → Pick one, build momentum

**Understanding impact:**
> `deps medfit --impact` → Know which 3 projects will be affected

**Daily overview:**
> `dashboard` → See all 32 projects, priorities, quick wins in 2 seconds

---

**Status:** ✅ Scope defined (project management focus)
**Architecture:** ✅ Three-layer design (ZSH → Node.js → External tools)
**Integration:** ✅ Leverage existing dev-tools packages
**Timeline:** 3 months to production-ready system
**Next Action:** Create directory structure and set up integrations (Week 1)
