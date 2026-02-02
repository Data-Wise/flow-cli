# Teach Comprehensive - Brainstorm

**Generated:** 2026-02-02
**Mode:** deep + save
**Focus:** feature (all categories)
**Context:** flow-cli teaching system, branch feature/teach-comprehensive

## Overview

The flow-cli teaching system has 29 subcommands but uneven documentation coverage. Scholar wrappers (the 9 AI-generation commands) have zero documentation despite being the primary user-facing features. This brainstorm identified gaps and produced a comprehensive spec for documentation improvements.

## Gap Analysis

### Coverage Matrix

| Category | Commands | Documented | Gap |
|----------|----------|------------|-----|
| Scholar wrappers | 9 | 0 | 9 commands |
| Core workflow | 4 (init, deploy, config, status) | ~0.5 | 3.5 commands |
| Content management | 8 (plan, templates, macros, prompt, analyze, validate, dates, hooks) | 6 | 2 commands |
| Infrastructure | 8 (doctor, cache, clean, backup, archive, profiles, hooks) | ~1 | 7 commands |
| **Total** | **29** | **~7.5** | **~21.5 commands** |

### What's Well-Documented

- teach plan: REFCARD + Tutorial 27 + 71 tests
- teach prompt: REFCARD + Tutorial 28 + E2E tests
- teach templates: REFCARD + Tutorial 24 + tests
- teach macros: REFCARD + Tutorial 26 + tests
- teach validate: REFCARD-LINT + Tutorial 27-lint
- teach analyze: Tutorial 21 + E2E tests

### What's Missing

- **Scholar wrappers:** lecture, slides, exam, quiz, assignment, syllabus, rubric, feedback -- the PRIMARY features
- **Core workflow:** init, deploy, config, status -- the FOUNDATIONAL commands
- **Infrastructure:** doctor, cache, clean, backup, archive, profiles, hooks
- **Unified reference:** No single REFCARD covering all 29 commands
- **Config schema:** teach-config.yml never formally documented
- **Architecture diagrams:** No Mermaid diagrams for the teaching system

## Decision Log

| # | Question | Decision |
|---|----------|----------|
| 1 | Goal | Documentation first |
| 2 | Scope | All 4 categories |
| 3 | Scholar docs | Self-contained with setup + usage |
| 4 | Format | REFCARDs + Guides |
| 5 | Structure | Unified REFCARD + per-feature REFCARDs |
| 6 | Config schema | Dedicated reference with validation rules |
| 7 | Deploy targets | GitHub Pages + local preview + CI/CD |
| 8 | Audience | Primary user (your workflow) |
| 9 | Integration | Full (files + mkdocs.yml + build) |
| 10 | Examples | STAT-101 demo course fixture |
| 11 | Quality | Publication-ready |
| 12 | Diagrams | 4 Mermaid diagrams |
| 13 | Phasing | One big PR |
| 14 | Out of scope | No new features (docs only) |
| 15 | Linking | Bidirectional cross-references |
| 16 | Schema depth | Full with validation rules |

## Deliverables

### New Files (8)

| File | Type | Purpose |
|------|------|---------|
| `docs/reference/REFCARD-TEACH-DISPATCHER.md` | REFCARD | All 29 commands unified reference |
| `docs/guides/SCHOLAR-WRAPPERS-GUIDE.md` | Guide | 9 AI-generation commands documentation |
| `docs/reference/TEACH-CONFIG-SCHEMA.md` | Reference | Config field reference with validation |
| `docs/guides/TEACH-DEPLOY-GUIDE.md` | Guide | Deployment strategies (3 targets) |
| `docs/reference/REFCARD-ANALYSIS.md` | REFCARD | teach analyze quick reference |
| `docs/reference/REFCARD-DATES.md` | REFCARD | teach dates quick reference |
| `docs/reference/REFCARD-DOCTOR.md` | REFCARD | teach doctor quick reference |
| `docs/specs/SPEC-teach-comprehensive-2026-02-02.md` | Spec | This spec |

### Modified Files (7+)

| File | Change |
|------|--------|
| `mkdocs.yml` | Add 7 new pages to navigation |
| `docs/tutorials/14-teach-dispatcher.md` | Add cross-references |
| `docs/tutorials/28-teach-prompt.md` | Add cross-references |
| `docs/tutorials/24-template-management.md` | Add cross-references |
| `docs/tutorials/26-latex-macros.md` | Add cross-references |
| `docs/reference/MASTER-DISPATCHER-GUIDE.md` | Add cross-reference |
| Scholar Enhancement tutorials | Add cross-references |

### Mermaid Diagrams (4)

1. Teaching Workflow Overview (init -> deploy flow)
2. Scholar Integration Architecture (data flow)
3. Config Resolution Chain (precedence)
4. Command Taxonomy (29 commands categorized)

## Recommended Implementation Order

1. REFCARD-TEACH-DISPATCHER.md (foundation)
2. TEACH-CONFIG-SCHEMA.md (needed by Scholar guide)
3. SCHOLAR-WRAPPERS-GUIDE.md (highest impact)
4. TEACH-DEPLOY-GUIDE.md (standalone)
5. Per-feature REFCARDs (analysis, dates, doctor)
6. mkdocs.yml navigation update
7. Bidirectional cross-references
8. Build verification (`mkdocs build`)

## Next Steps

1. Start a new session in the worktree:
   ```bash
   cd ~/.git-worktrees/flow-cli/feature-teach-comprehensive
   claude
   ```
2. Begin with Deliverable 1 (REFCARD-TEACH-DISPATCHER.md)
3. Work through deliverables in order
4. Ship as one PR to dev
