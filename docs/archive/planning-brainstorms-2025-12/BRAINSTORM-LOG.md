# Brainstorm Log: Project Hub Architecture

> **Purpose:** Document the thinking process and decision-making for the hub architecture.

---

## Session: 2025-12-17

### Initial Problem

**Context:**

- 16 dev-tools projects, 6 R packages, 11 research projects, 3 courses
- Each has different conventions
- Context-switching is expensive (ADHD tax)
- No unified dashboard or coordination system

**Trigger:** User asked to imagine expert DevOps approach for multi-project management.

---

### Brainstorm Phase 1: Single Hub (DEVOPS-HUB-PROPOSAL.md)

**Initial idea:** Make `flow-cli` the central hub for everything.

```
flow-cli/
├── standards/           # Universal standards
├── templates/           # Project scaffolding
├── r-ecosystem/         # R package coordination
└── zsh/                 # Shell config
```

**Implemented:**

- Created `standards/` directory
- Created `standards/code/R-STYLE-GUIDE.md`
- Created `standards/code/COMMIT-MESSAGES.md`
- Created `standards/project/PROJECT-STRUCTURE.md`
- Created `standards/adhd/QUICK-START-TEMPLATE.md`

**Pushed to GitHub:** Phase 1 Foundation complete.

---

### Brainstorm Phase 2: Discovered mediation-planning

**Discovery:** User pointed to `~/projects/r-packages/mediation-planning/` as a reference.

**What we learned:**

- `mediation-planning` uses a proven pattern for domain coordination
- Structure: `PROJECT-HUB.md`, `.STATUS`, `TODOS.md`, `docs/`, `specs/`, `proposals/`
- ADHD-friendly: visual progress bars, decision points, quick links
- Works well for coordinating multiple related packages (mediationverse)

**Key insight:** This pattern is effective and already in use.

---

### Brainstorm Phase 3: Options Analysis

**Question:** Should we create a similar `dev-planning` folder, or use `flow-cli`?

**Options explored:**

#### Option A: Single Hub (flow-cli does everything)

- Pros: One location, unified commands
- Cons: Gets bloated, mixes shell config with project coordination

#### Option B: Separate Domain Hubs

- Each domain gets own planning repo (like mediation-planning)
- Pros: Follows proven pattern, clean separation
- Cons: Multiple repos to maintain

#### Option C: Hybrid - Standards Hub Only

- flow-cli = standards authority
- Domain hubs = coordination
- Pros: Clean separation
- Cons: Cross-domain coordination unclear

#### Option D: Meta Hub + Standards

- project-hub = command center
- mediation-planning = R packages (exists)
- flow-cli = standards + shell
- Pros: Clean aggregation
- Cons: Still need dev tools coordination

#### Option D+ (Refined): Three-Tier System

- Master: project-hub (aggregates all)
- Domain: mediation-planning, dev-planning
- Standards: flow-cli

---

### Brainstorm Phase 4: Workflow Integration

**Critical question:** How does each option fit existing workflows?

**Existing commands:**

- `work NAME` - Start session
- `dash` - Master dashboard
- `rst` - Research dashboard
- `tst` - Teaching dashboard
- `pb/pt/pd/pc` - Universal build/test/doc/check

**Analysis:**

- Option C: `dash` would need to read from 4 sources
- Option D+: `dash` reads from 2 sources (project-hub + mediation-planning)
- Cross-domain tasks need a home → `project-hub/cross-domain/`

**Decision factor:** Simpler data flow with Option D+.

---

### Brainstorm Phase 5: Research & Teaching

**Question:** How do research and teaching fit?

**Analysis:**

- Research: 11 projects, various stages (draft, review, published)
- Teaching: 3 courses, semester-based
- Both already use `.STATUS` files

**Decision:**

- Research & teaching tracked in `project-hub/domains/` (not separate hubs)
- Fewer projects, less need for dedicated coordination repos
- R packages and dev tools get dedicated hubs (more projects, more complexity)

---

### Brainstorm Phase 6: Obsidian Integration

**User input:** Considering Obsidian for project and knowledge management.

**Reference:** `obsidian-cli-ops` (v2.2.0) already provides:

- Multi-vault management
- Graph analysis (PageRank, centrality)
- TUI interface
- AI features (similarity, duplicates)
- R-Dev integration

**Integration options:**

1. Make project-hub an Obsidian vault
2. Federated vaults with cross-links
3. CLI-only (no Obsidian app)

**Recommendation:** Hybrid - vault + obs CLI commands

---

### Brainstorm Phase 7: Final Decision

**Question:** Should dev tools tracking live in `flow-cli` or separate `dev-planning`?

**Arguments for separate `dev-planning`:**

1. Follows `mediation-planning` pattern exactly
2. Keeps `flow-cli` focused
3. Clean parallel in project-hub links:
   - R packages → mediation-planning
   - Dev tools → dev-planning
4. Scalable for 16+ projects

**Arguments for nesting in `flow-cli`:**

1. Fewer repos to maintain
2. Already has planning docs

**Final decision:** Create separate `dev-planning/` repo.

**Rationale:**

- Consistency > convenience
- `flow-cli` name doesn't suggest "dev tools hub"
- Cleaner mental model

---

## Final Architecture

```
~/projects/
├── project-hub/                    # MASTER HUB
│   ├── PROJECT-HUB.md              # Aggregates all domains
│   ├── domains/                    # Domain summaries
│   ├── cross-domain/               # Integration tasks
│   └── weekly/                     # Weekly planning
│
├── r-packages/
│   └── mediation-planning/         # DOMAIN HUB (exists)
│
├── dev-tools/
│   ├── dev-planning/               # DOMAIN HUB (new)
│   └── flow-cli/          # STANDARDS HUB
│       └── standards/              # Universal conventions
│
├── research/                       # → project-hub/domains/research.md
└── teaching/                       # → project-hub/domains/teaching.md
```

---

## Key Decisions Log

| Decision             | Options Considered              | Choice                    | Rationale                          |
| -------------------- | ------------------------------- | ------------------------- | ---------------------------------- |
| Hub structure        | Single vs Multiple              | Three-tier                | Separation of concerns             |
| Dev tools tracking   | In zsh-config vs separate       | Separate `dev-planning`   | Follows mediation-planning pattern |
| Research/teaching    | Separate hubs vs in project-hub | In project-hub            | Fewer projects, less complexity    |
| Standards location   | Per-repo vs centralized         | Centralized in zsh-config | Single source of truth             |
| Obsidian integration | Now vs later                    | Phase 4 (future)          | Core structure first               |

---

## Open Questions for Future

1. Should `research-planning` become a separate hub if research projects grow?
2. How to handle semester transitions in teaching tracking?
3. Automation level: manual updates vs `.STATUS` aggregation scripts?
4. Obsidian daily notes → weekly file integration workflow?

---

## Future Work Backlog (Added 2025-12-17)

### Standards to Create

| Standard             | Location           | Purpose                                |
| -------------------- | ------------------ | -------------------------------------- |
| ZSH-COMMANDS-HELP.md | standards/code/    | Help system standards for zsh commands |
| TUTORIAL-TEMPLATE.md | standards/adhd/    | Standard structure for tutorials       |
| REFCARD-TEMPLATE.md  | standards/adhd/    | Reference card design standards        |
| R-PACKAGE-DESIGN.md  | standards/project/ | R package architecture patterns        |
| DEV-TOOL-DESIGN.md   | standards/project/ | Dev tool architecture patterns         |

### Integration Needed

| Item              | Location                 | Action                                               |
| ----------------- | ------------------------ | ---------------------------------------------------- |
| GitHub docs repo  | Unknown - need to locate | Audit, migrate useful content, deprecate             |
| data-wise website | Personal website         | Integrate with project showcases, link pkgdown sites |

### Domain-Specific Standards

**R Packages (for mediation-planning or standards/):**

- Vignette structure template
- pkgdown site design standards
- CRAN submission checklist
- Test coverage requirements (target %)
- Documentation standards (roxygen2)

**Dev Tools (for dev-planning or standards/):**

- CLI design patterns
- Help system format (`--help`, man pages, etc.)
- README structure for tools
- Release process (versioning, changelog)
- Test requirements

---

## Related Documents

- [PROJECT-HUB-PROPOSAL.md](PROJECT-HUB-PROPOSAL.md) - Final architecture (approved)
- [DEVOPS-HUB-PROPOSAL.md](DEVOPS-HUB-PROPOSAL.md) - Initial brainstorm (superseded)
- `~/projects/r-packages/mediation-planning/` - Reference implementation
- `~/projects/dev-tools/obsidian-cli-ops/` - Future integration tool
