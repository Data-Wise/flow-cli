# Project Hub Proposal (Option D+ Revised)

> **TL;DR:** Single command center (`project-hub/`) aggregates all domains. Domain-specific hubs (`mediation-planning`, `dev-planning`) handle coordination. `flow-cli` owns standards only.

**Status:** Approved for implementation
**Created:** 2025-12-17
**Revised:** 2025-12-17 (Added dev-planning, clarified architecture)
**Future:** Obsidian integration planned

---

## Final Architecture Decision

After brainstorming, we decided on a **three-tier hub system**:

| Tier | Hub | Purpose |
|------|-----|---------|
| **Master** | `project-hub/` | Aggregates all domains, weekly planning |
| **Domain** | `mediation-planning/`, `dev-planning/` | Domain-specific coordination |
| **Standards** | `flow-cli/standards/` | Universal conventions |

**Key decision:** Create separate `dev-planning/` repo (not nested in `flow-cli/`) to:
1. Follow `mediation-planning` pattern exactly
2. Keep `flow-cli` focused on standards + shell config
3. Clean parallel structure for project-hub links

---

## Architecture Overview

```
~/projects/
├── project-hub/                    # MASTER HUB - Command Center (NEW)
│   ├── PROJECT-HUB.md              # Master entry point
│   ├── .STATUS                     # Today's focus
│   ├── TODOS.md                    # All active tasks
│   ├── domains/
│   │   ├── r-packages.md           # → links to mediation-planning
│   │   ├── dev-tools.md            # → links to dev-planning
│   │   ├── research.md             # Research coordination
│   │   └── teaching.md             # Teaching coordination
│   ├── cross-domain/
│   │   └── INTEGRATIONS.md         # Cross-domain tasks
│   ├── weekly/
│   │   └── WEEK-XX.md              # Weekly focus files
│   └── reference/
│       └── standards → flow-cli/standards/  # Symlink
│
├── r-packages/
│   └── mediation-planning/         # DOMAIN HUB - R Packages (EXISTS)
│       ├── PROJECT-HUB.md
│       ├── .STATUS
│       ├── docs/, specs/, proposals/
│       └── ...
│
└── dev-tools/
    ├── dev-planning/               # DOMAIN HUB - Dev Tools (NEW)
    │   ├── PROJECT-HUB.md          # Dev tools dashboard
    │   ├── .STATUS
    │   ├── TODOS.md
    │   ├── docs/
    │   │   ├── TOOL-INVENTORY.md   # All 16 tools
    │   │   └── INTEGRATION-MAP.md  # How tools connect
    │   ├── by-project/             # Per-project tracking
    │   │   ├── flow-cli.md
    │   │   ├── obsidian-cli-ops.md
    │   │   └── ...
    │   └── proposals/
    │
    └── flow-cli/          # STANDARDS HUB - Standards + Shell
        ├── standards/              # Universal standards (all domains)
        ├── templates/              # Project scaffolding
        ├── docs/planning/          # Planning docs for THIS repo only
        └── zsh/                    # Shell config (symlinked)
```

---

## Data Flow

```
Individual Projects              Domain Hubs                   Master Hub
─────────────────               ───────────                   ──────────

r-packages/active/medfit/
  └─ .STATUS ─────────────┐
                          ├──→ mediation-planning/ ──────┐
r-packages/active/probmed/│       └─ PROJECT-HUB.md      │
  └─ .STATUS ─────────────┘                              │
                                                         │
dev-tools/flow-cli/                             │
  └─ .STATUS ─────────────┐                              │
                          ├──→ dev-planning/ ────────────┼──→ project-hub/
dev-tools/obsidian-cli-ops/│      └─ PROJECT-HUB.md      │       └─ PROJECT-HUB.md
  └─ .STATUS ─────────────┘                              │
                                                         │
research/product-of-three/                               │
  └─ .STATUS ─────────────┐                              │
                          ├──→ domains/research.md ──────┤
research/collider/        │                              │
  └─ .STATUS ─────────────┘                              │
                                                         │
teaching/stat-440/                                       │
  └─ .STATUS ─────────────┐                              │
                          ├──→ domains/teaching.md ──────┘
teaching/causal-inference/│
  └─ .STATUS ─────────────┘
```

**Note:** R packages and dev tools have dedicated domain hubs. Research and teaching are tracked directly in project-hub (fewer projects, less need for separate hubs).

---

## File Specifications

### `project-hub/PROJECT-HUB.md`

```markdown
# 📊 Project Command Center

> **Today:** [Current focus from .STATUS]

## Quick Status

| Domain | Hub | Status | Next Action |
|--------|-----|--------|-------------|
| R Packages | [mediation-planning](../r-packages/mediation-planning/) | 🟢 | [from hub] |
| Dev Tools | [dev-tools.md](domains/dev-tools.md) | 🟢 | [from file] |
| Research | [research.md](domains/research.md) | 🟡 | [from file] |
| Teaching | [teaching.md](domains/teaching.md) | 🟢 | [from file] |

## This Week

See [weekly/WEEK-XX.md](weekly/)

## Cross-Domain

See [INTEGRATIONS.md](cross-domain/INTEGRATIONS.md)
```

### `project-hub/domains/research.md`

```markdown
# 📝 Research Projects

> **Active:** 3 | **Paused:** 5 | **Complete:** 3

## Dashboard

| Project | Status | Progress | Target | Next Action |
|---------|--------|----------|--------|-------------|
| product-of-three | Draft | 75% | JASA | Write discussion |
| collider | Under Review | — | Biostatistics | Address R2 comments |
| sensitivity | Paused | 40% | Psych Methods | — |
| pmed | ✅ Published | 100% | — | — |

## By Stage

### 🔴 Active Writing
- **product-of-three** — Discussion section needed

### 🟡 Under Review
- **collider** — R2 received

### ⏸️ Paused
- **sensitivity** — Blocked on medrobust

## Quick Commands

```bash
rst                    # Research dashboard
rms                    # Open current manuscript
work "product of three"  # Start session
```
```

### `project-hub/domains/teaching.md`

```markdown
# 📚 Teaching Courses

> **Semester:** Fall 2024 | **Week:** 14/15

## Dashboard

| Course | Week | Status | Next Action |
|--------|------|--------|-------------|
| STAT-440 | 14/15 | 🟢 | Final exam prep |
| STAT-579 | 14/15 | 🟢 | Project presentations |

## This Week

### STAT-440 (Regression Analysis)
- [ ] Finalize final exam questions
- [ ] Post review materials

### STAT-579 (Causal Inference)
- [ ] Grade project drafts
- [ ] Prepare presentation rubric

## Quick Commands

```bash
tst                    # Teaching dashboard
tweek                  # Current week info
tlec 14                # Open week 14 lecture
```
```

### `project-hub/domains/dev-tools.md`

```markdown
# 🔧 Dev Tools

> **Active:** 16 projects | **Hub:** [dev-planning](../../dev-tools/dev-planning/)

## Quick Status

See [dev-planning/PROJECT-HUB.md](../../dev-tools/dev-planning/PROJECT-HUB.md) for full dashboard.

## Highlights

| Project | Status | Next Action |
|---------|--------|-------------|
| flow-cli | 🟢 Phase 1 ✅ | Phase 2: Templates |
| obsidian-cli-ops | 🟢 v2.2.0 | Maintenance |
| claude-mcp | ✅ Stable | — |

## Standards Reference

See [flow-cli/standards/](../../dev-tools/flow-cli/standards/)
```

### `dev-planning/PROJECT-HUB.md` (New Domain Hub)

```markdown
# 🔧 Dev Tools - Project Control Hub

> **Quick Status:** 🟢 Active | **Projects:** 16 | **Progress:** Mixed

**Last Updated:** 2025-12-17

---

## Dashboard

| Project | Status | Progress | Priority | Next Action |
|---------|--------|----------|----------|-------------|
| flow-cli | 🟢 Active | Phase 1 ✅ | P1 | Phase 2: Templates |
| obsidian-cli-ops | 🟢 Active | 98% | P2 | Maintenance |
| claude-mcp | ✅ Stable | 100% | — | — |
| zsh-claude-workflow | 🟢 Active | 90% | P2 | Integration tests |
| claude-statistical-research | 🟢 Active | — | P1 | MCP improvements |
| shell-mcp-server | ✅ Stable | 100% | — | — |
| ... | | | | |

## By Status

### 🟢 Active Development
- **flow-cli** — Standards hub, shell config
- **obsidian-cli-ops** — Obsidian CLI with graph analysis
- **claude-statistical-research** — MCP server for research

### ✅ Stable / Maintenance
- **claude-mcp** — Browser extension
- **shell-mcp-server** — Shell MCP server

### ⏸️ Paused
- (none currently)

## Quick Links

| Resource | Location |
|----------|----------|
| Standards | [flow-cli/standards/](../flow-cli/standards/) |
| Project details | [by-project/](by-project/) |
| Integration map | [docs/INTEGRATION-MAP.md](docs/INTEGRATION-MAP.md) |

## Current Focus

**This Week:** flow-cli Phase 2 (templates, unified commands)

---

*See also: [project-hub](../../project-hub/) for master dashboard*
```

### `project-hub/cross-domain/INTEGRATIONS.md`

```markdown
# Cross-Domain Integrations

Tasks that span multiple domains.

## Active

### product-of-three ↔ medfit
- **Need:** Simulation code requires `medfit::fit_mediation()`
- **Status:** 🟢 Ready
- **Action:** Update `R/03-simulations.R`

### STAT-579 ↔ medrobust
- **Need:** Teaching materials for sensitivity lecture
- **Status:** 🟡 Waiting
- **Action:** Create simplified example

### flow-cli ↔ mediation-planning
- **Need:** Add `medstatus` command
- **Status:** 🟢 Ready
- **Action:** Implement in Phase 2

## Completed

- [x] flow-cli standards → used by all projects
```

### `project-hub/weekly/WEEK-50.md`

```markdown
# Week 50 (Dec 16-22, 2025)

## Focus Areas

1. **R Packages:** Merge medfit PR #10
2. **Research:** Write product-of-three discussion
3. **Teaching:** Final exam prep

## Daily Plan

### Monday
- [ ] Review medfit PR
- [ ] Outline discussion section

### Tuesday
- [ ] Merge PR, update probmed
- [ ] Draft discussion intro

### Wednesday
- [ ] STAT-440 office hours
- [ ] Continue discussion

### Thursday
- [ ] Finalize exam questions
- [ ] Discussion draft complete

### Friday
- [ ] Final review
- [ ] Week 51 planning

## Wins

- [ ] medfit 1.0 ready
- [ ] Discussion section drafted
- [ ] Exams finalized
```

---

## Workflow Commands

### Existing (Unchanged)

```bash
work NAME              # Start session (smart context)
rst                    # Research dashboard
tst                    # Teaching dashboard
tweek                  # Current week info
pb/pt/pd/pc            # Universal build/test/doc/check
```

### New Commands

```bash
# Quick focus check
today() {
    bat ~/projects/project-hub/.STATUS
}

# This week's plan
week() {
    local week_num=$(date +%V)
    bat ~/projects/project-hub/weekly/WEEK-${week_num}.md
}

# Master dashboard (updated)
dash() {
    bat ~/projects/project-hub/PROJECT-HUB.md
}

# Open hub in editor
hub() {
    cd ~/projects/project-hub && $EDITOR .
}
```

---

## Why This Design

| Benefit | How |
|---------|-----|
| **Single entry point** | `PROJECT-HUB.md` aggregates all domains |
| **R packages unchanged** | `mediation-planning` keeps working |
| **Cross-domain has home** | `cross-domain/INTEGRATIONS.md` |
| **Weekly planning** | `weekly/WEEK-XX.md` files |
| **Standards centralized** | Symlink to `flow-cli/standards/` |
| **ADHD-friendly** | `today` command, visual dashboards |
| **Existing workflow** | `rst`, `tst`, `work` unchanged |

---

## Implementation Plan

### Phase 1: Create project-hub structure ✅ COMPLETE
- [x] Create `~/projects/project-hub/` directory
- [x] Create `PROJECT-HUB.md`
- [x] Create `.STATUS`
- [x] Create `domains/` files (research, teaching, dev-tools, r-packages)
- [x] Create `cross-domain/INTEGRATIONS.md`
- [x] Create `weekly/` with current week
- [x] Symlink `reference/standards` → `flow-cli/standards/`

### Phase 2: Create dev-planning hub ✅ COMPLETE
- [x] Create `~/projects/dev-tools/dev-planning/` directory
- [x] Create `PROJECT-HUB.md` (dev tools dashboard)
- [x] Create `.STATUS`
- [x] Create `TODOS.md`
- [x] Create `docs/TOOL-INVENTORY.md`
- [x] Create `docs/INTEGRATION-MAP.md`
- [x] Create `by-project/` with key project files
- [x] Initialize as git repo

### Phase 3: Shell integration ✅ COMPLETE

- [x] Add `today` command (with --help) [renamed from `focus` due to conflict]
- [x] Add `week` command (with --help)
- [x] Add `hub` command (with --help, subcommands)
- [x] Add `devhub` command (with --help, subcommands)
- [x] Add `rhub` command (with --help, subcommands)
- [x] Add `hub-new-week` command
- [x] Add aliases: f, wk, dh, rh
- [x] Commands follow ZSH-COMMANDS-HELP.md standard

### Phase 3.5: Standards & Documentation ✅ COMPLETE
- [x] Create GETTING-STARTED-TEMPLATE.md (user onboarding standard)
- [x] Create project-hub/GETTING-STARTED.md (hands-on guide)
- [x] Create ZSH-COMMANDS-HELP.md (help output standard)
- [x] Create TUTORIAL-TEMPLATE.md (deep learning guides)
- [x] Create REFCARD-TEMPLATE.md (quick reference cards)
- [x] Update hub-commands.zsh to follow help standard

### Phase 4: Automation (optional)
- [ ] Script to aggregate `.STATUS` files into domain files
- [ ] Weekly file generator

---

## Future: Obsidian Integration

**Planned:** Use Obsidian as visual hub for project and knowledge management.

**Integration tool:** `~/projects/dev-tools/obsidian-cli-ops/` (v2.2.0, 98% complete)

### What obsidian-cli-ops Provides

| Feature | Description | Relevance to project-hub |
|---------|-------------|--------------------------|
| **Multi-vault management** | Discover, scan, sync vaults | Manage project-hub as vault |
| **Graph analysis** | PageRank, centrality, clustering | Visualize cross-domain connections |
| **Hub/orphan detection** | Find highly connected or isolated notes | Identify integration gaps |
| **Link resolution** | Resolve wikilinks, detect broken | Validate domain file links |
| **TUI interface** | Full-screen terminal UI | Visual dashboard alternative |
| **AI features** | Similarity, duplicates, analysis | Find related projects/notes |
| **R-Dev integration** | Link R projects to Obsidian | Connect research projects |

### Integration Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         OBSIDIAN                                │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  project-hub/ (as Obsidian vault)                        │  │
│  │  ├── PROJECT-HUB.md     ← Graph view shows connections   │  │
│  │  ├── domains/           ← Wikilinks to projects          │  │
│  │  ├── cross-domain/      ← Backlinks show dependencies    │  │
│  │  └── weekly/            ← Daily notes integration        │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                  │
│                              ▼                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  obs CLI (obsidian-cli-ops)                              │  │
│  │  - obs graph project-hub    → ASCII graph visualization  │  │
│  │  - obs stats project-hub    → Vault statistics           │  │
│  │  - obs ai similar <note>    → Find related projects      │  │
│  │  - obs tui                  → Interactive browser        │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                      SHELL WORKFLOW                             │
│  dash    → bat PROJECT-HUB.md (current)                        │
│  dash    → obs tui project-hub (future - visual mode)          │
│  today   → .STATUS file                                         │
│  week    → weekly/WEEK-XX.md                                    │
└─────────────────────────────────────────────────────────────────┘
```

### Integration Options

#### Option 1: project-hub as Obsidian Vault
Make `~/projects/project-hub/` a full Obsidian vault:

```bash
# Initialize as vault
mkdir -p ~/projects/project-hub/.obsidian

# Scan with obs
obs scan ~/projects/project-hub

# Use graph view
obs graph project-hub
```

**Benefits:**
- Full Obsidian features (graph, backlinks, search)
- Daily notes for weekly planning
- Tags for status (#active, #paused)
- Canvas for visual planning

**Workflow integration:**
```bash
# Open in Obsidian app
obs open project-hub

# Or use TUI from terminal
obs tui project-hub

# Quick stats
obs stats project-hub
```

#### Option 2: Federated Vaults (Link to Existing)
Keep project-hub as markdown folder, link to existing vaults:

```markdown
# In project-hub/domains/research.md
## Projects

- [[product-of-three]] → obsidian://open?vault=Research&file=product-of-three
- [[collider]] → obsidian://open?vault=Research&file=collider
```

**Benefits:**
- No vault migration needed
- Uses existing Obsidian setup
- Cross-vault linking

#### Option 3: obs CLI Integration Only
Use `obs` commands without Obsidian app:

```bash
# Shell aliases
alias dash='obs tui project-hub'
alias pgraph='obs graph project-hub'
alias pstats='obs stats project-hub'

# AI-powered project discovery
obs ai similar "mediation analysis" --vault=project-hub
```

**Benefits:**
- Terminal-native workflow
- No Obsidian app required
- AI features from CLI

### Recommended: Hybrid Approach

1. **Make project-hub an Obsidian vault** (Option 1)
2. **Use wikilinks** in domain files: `[[product-of-three]]`
3. **Use obs CLI** for terminal workflows
4. **Open in Obsidian app** for visual planning sessions

### Implementation Steps

#### Phase 4: Obsidian Integration (Future)

- [ ] Initialize project-hub as Obsidian vault
- [ ] Add wikilinks to domain files
- [ ] Configure obs to include project-hub
- [ ] Add `obs` aliases to shell workflow
- [ ] Create Obsidian templates for weekly files
- [ ] Set up daily notes → weekly integration
- [ ] Test graph visualization for cross-domain

### obs Commands for project-hub

```bash
# Initialize vault
obs scan ~/projects/project-hub --name "Project Hub"

# View graph (ASCII in terminal)
obs graph project-hub

# Interactive TUI
obs tui project-hub

# Statistics
obs stats project-hub

# Find similar projects
obs ai similar "causal inference" --vault project-hub

# Detect orphaned domain files
obs graph project-hub --orphans

# Find hub notes (most connected)
obs graph project-hub --hubs
```

### Tags Strategy

Use Obsidian tags for filtering:

```markdown
# In domains/research.md

## product-of-three #active #research #jasa
## collider #review #research #biostatistics
## sensitivity #paused #research
```

Then in Obsidian:
- Search `#active` → all active projects
- Search `#paused` → projects needing attention
- Graph filtered by tag → domain-specific views

---

## Future Work (Backlog)

Items identified during brainstorming for future phases:

### Standards Expansion

| Standard | Domain | Status | Description |
|----------|--------|--------|-------------|
| ZSH-COMMANDS-HELP.md | code/ | ✅ DONE | Help system standards for zsh commands |
| GETTING-STARTED-TEMPLATE.md | adhd/ | ✅ DONE | User onboarding/training guides |
| TUTORIAL-TEMPLATE.md | adhd/ | ✅ DONE | Standard structure for tutorials |
| REFCARD-TEMPLATE.md | adhd/ | ✅ DONE | Reference card design standards |
| R-PACKAGE-DESIGN.md | project/ | 🔲 TODO | R package architecture patterns |
| DEV-TOOL-DESIGN.md | project/ | 🔲 TODO | Dev tool architecture patterns |

### Documentation Integration

| Item | Description | Action |
|------|-------------|--------|
| GitHub docs repo | Existing documentation repository | Audit, migrate useful content, deprecate |
| data-wise website | Personal/professional website | Integrate with project showcases |

### Domain-Specific Standards

**R Packages:**
- Vignette structure
- pkgdown site design
- CRAN submission checklist
- Test coverage requirements

**Dev Tools:**
- CLI design patterns
- Help system format
- README structure
- Release process

### Phase 5+: Website Integration

- **data-wise website:** Integrate project showcases
- Link to package documentation (pkgdown sites)
- Research project summaries
- Teaching resources

---

## Document History

- **2025-12-17:** Initial proposal created, approved for implementation
- **2025-12-17:** Added detailed Obsidian integration section with obs CLI
- **2025-12-17:** Major revision - Added separate `dev-planning/` hub decision
  - Decided against nesting dev tools tracking in `flow-cli`
  - Created three-tier hub system (master → domain → standards)
  - Updated data flow diagram and implementation phases
- **2025-12-17:** Added future work backlog
  - Standards expansion (ZSH help, tutorials, refcards)
  - Documentation integration (GitHub docs repo, data-wise website)
  - Domain-specific standards for R packages and dev tools
- **2025-12-17:** Phases 1-3.5 complete
  - project-hub/ created with full structure
  - dev-planning/ created with full structure
  - Shell commands (today, week, hub, devhub, rhub) implemented
  - Standards created: GETTING-STARTED-TEMPLATE, ZSH-COMMANDS-HELP, TUTORIAL-TEMPLATE, REFCARD-TEMPLATE
  - project-hub/GETTING-STARTED.md user guide created
  - All commands follow ZSH-COMMANDS-HELP standard
