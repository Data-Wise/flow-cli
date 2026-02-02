# Teach Comprehensive - Orchestration Plan

> **Branch:** `feature/teach-comprehensive`
> **Base:** `dev`
> **Worktree:** `~/.git-worktrees/flow-cli/feature-teach-comprehensive`
> **Created:** 2026-02-02

## Objective

Make the flow-cli teaching system more comprehensive by filling documentation gaps, adding missing reference cards, improving tutorials, and ensuring Scholar wrapper commands are properly documented. The teaching system has 29 subcommands but uneven coverage -- the primary AI-generation features (lecture, exam, quiz, etc.) are almost undocumented.

## Gap Analysis Summary

### Current Coverage Matrix

| Command | Docs | Tests | REFCARD | Tutorial | Priority |
|---------|------|-------|---------|----------|----------|
| teach plan | Full | 71+ | Yes | #27 | - |
| teach prompt | Full | E2E | Yes | #28 | - |
| teach templates | Full | Yes | Yes | #24 | - |
| teach macros | Full | Yes | Yes | #26 | - |
| teach validate | Full | Yes | Yes | #27-lint | - |
| teach analyze | Good | E2E | No | #21 | Medium |
| teach dates | Partial | Limited | No | #20 | Medium |
| teach deploy | Partial | No | No | Mentioned | High |
| teach doctor | Partial | Some | No | Mentioned | Medium |
| teach config | Minimal | No | No | Mentioned | High |
| teach status | Minimal | No | No | Mentioned | Medium |
| teach init | Minimal | No | No | Mentioned | High |
| **Scholar wrappers** | **None** | **None** | **No** | **None** | **Critical** |
| teach archive | None | No | No | No | Low |
| teach backup | None | No | No | No | Low |
| teach clean | None | No | No | No | Low |
| teach cache | None | No | No | No | Low |
| teach hooks | None | No | No | No | Low |
| teach profiles | None | No | No | No | Low |

### Scholar Wrappers (UNDOCUMENTED)

These are the primary AI-generation commands and have NO documentation:
- `teach lecture` / `teach lec`
- `teach slides` / `teach sl`
- `teach exam` / `teach e`
- `teach quiz` / `teach q`
- `teach assignment` / `teach hw`
- `teach syllabus` / `teach syl`
- `teach rubric` / `teach rb`
- `teach feedback` / `teach fb`
- `teach demo`

## Phase Overview

| Phase | Task | Priority | Status |
|-------|------|----------|--------|
| 1 | Create REFCARD-TEACH-DISPATCHER.md (all 29 commands) | Critical | Pending |
| 2 | Document Scholar wrapper commands with examples | Critical | Pending |
| 3 | Expand Tutorial 14 or create new comprehensive tutorial | High | Pending |
| 4 | Create teach init walkthrough guide | High | Pending |
| 5 | Create teach deploy strategies guide | High | Pending |
| 6 | Create teach config schema documentation | High | Pending |
| 7 | Add missing REFCARD files (analyze, dates, doctor) | Medium | Pending |
| 8 | Update mkdocs.yml navigation for new docs | Medium | Pending |

## Phase Details

### Phase 1: REFCARD-TEACH-DISPATCHER.md

**Goal:** Single reference card covering ALL 29 teach subcommands.
**File:** `docs/reference/REFCARD-TEACH-DISPATCHER.md`
**Approach:** Quick-reference table format, similar to existing REFCARDs. Group by category (Scholar wrappers, project management, content management, infrastructure).

### Phase 2: Scholar Wrapper Documentation

**Goal:** Document the 9 AI-generation commands that make the teach system valuable.
**File:** `docs/guides/SCHOLAR-WRAPPERS-GUIDE.md`
**Approach:** For each wrapper: syntax, options, examples, config requirements, output format. Include sample teach-config.yml snippets showing required fields.

### Phase 3: Comprehensive Tutorial

**Goal:** Either expand Tutorial 14 or create a new "Teaching System Deep Dive" tutorial.
**File:** `docs/tutorials/14-teach-dispatcher.md` (expand) or new tutorial
**Approach:** Walk through a complete course setup workflow: init -> config -> plan -> content generation -> validate -> deploy.

### Phase 4: teach init Walkthrough

**Goal:** Dedicated guide for initializing a new teaching project.
**File:** `docs/guides/TEACH-INIT-GUIDE.md`
**Approach:** Step-by-step from empty directory to configured course with templates, lesson plans, and config.

### Phase 5: teach deploy Strategies

**Goal:** Document deployment workflow and strategies.
**File:** `docs/guides/TEACH-DEPLOY-GUIDE.md`
**Approach:** Local preview, GitHub Pages deployment, CI/CD setup, custom deployment targets.

### Phase 6: teach config Schema

**Goal:** Formal documentation of teach-config.yml schema and options.
**File:** `docs/reference/TEACH-CONFIG-SCHEMA.md`
**Approach:** Document every field, valid values, defaults, and examples. Include lesson-plans.yml schema too.

### Phase 7: Additional REFCARDs

**Files:**
- `docs/reference/REFCARD-ANALYSIS.md` - teach analyze quick reference
- `docs/reference/REFCARD-DATES.md` - teach dates quick reference
- `docs/reference/REFCARD-DOCTOR.md` - teach doctor quick reference

### Phase 8: Navigation Update

**File:** `mkdocs.yml`
**Approach:** Add all new docs to site navigation structure.

## Acceptance Criteria

- [ ] All 29 teach subcommands documented in REFCARD-TEACH-DISPATCHER.md
- [ ] Scholar wrappers have examples and config requirements
- [ ] New user can follow guides from init to deploy
- [ ] mkdocs.yml navigation includes all new pages
- [ ] `mkdocs build` succeeds without errors

## How to Start

```bash
cd ~/.git-worktrees/flow-cli/feature-teach-comprehensive
claude
```

Focus on Phases 1-2 first (reference card + Scholar wrappers) as they have the highest impact.
