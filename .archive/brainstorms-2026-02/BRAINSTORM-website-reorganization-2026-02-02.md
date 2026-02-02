# Website Reorganization - Brainstorm Proposal

**Generated:** 2026-02-02
**Context:** flow-cli documentation site (MkDocs Material)
**URL:** https://Data-Wise.github.io/flow-cli/
**Branch:** feature/teach-comprehensive

## Overview

The flow-cli documentation site has grown to 426 files with 154 in navigation, but the structure has accumulated organizational debt: 14 top-level sections, 158 orphaned files, overlapping sections, and inconsistent grouping. This proposal reorganizes the site into a cleaner information architecture that's ADHD-friendly and scales with growth.

---

## Current State Analysis

### By the Numbers

| Metric | Value | Assessment |
|--------|-------|------------|
| Total .md files | 426 | Large, needs triage |
| Files in nav | 154 | ~36% coverage |
| Orphaned files | 158 | Excludes _archive/specs/planning |
| Top-level sections | 14 | Too many (cognitive overload) |
| Duplicate nav entries | 1 | `tutorials/08-git-feature-workflow.md` |
| Teaching subsections | 7 | Best-organized section |

### Current 14 Top-Level Sections

```
1. Home
2. Documentation Hub
3. Getting Started
4. Tutorials           ← Flat list of 18 numbered items
5. Teaching             ← Well-organized (7 subsections)
6. Workflows            ← Overlaps with Guides
7. Guides               ← Catch-all, overlaps with Workflows
8. Visuals              ← Only 2 items
9. Help & Quick Ref     ← Overlaps with Getting Started
10. Reference           ← Only 5 items (REFCARDs buried in Teaching)
11. Commands            ← Good, but flat
12. Testing             ← Only 4 items, dev-focused
13. Development         ← Dev-focused, could merge
14. Architecture        ← Only 4 items, dev-focused
```

### Key Problems

1. **14 tabs is overwhelming** - Material theme shows top-level sections as tabs. Users scanning tabs see: Home, Docs Hub, Getting Started, Tutorials, Teaching, Workflows, Guides, Visuals, Help, Reference, Commands, Testing, Development, Architecture, Planning. That's a lot.

2. **Overlapping sections** - "Workflows" vs "Guides" vs "Help" all contain workflow-oriented content. "Getting Started" vs "Help & Quick Reference" both serve orientation.

3. **Flat Tutorials section** - 18 numbered tutorials with no grouping, spanning flow-cli basics to vim motions to teaching workflows.

4. **Tiny sections** - Visuals (2 items), Architecture (4), Planning (2), Testing (4) don't warrant top-level tabs.

5. **REFCARDs scattered** - Teaching REFCARDs are under Teaching > Reference, but general REFCARDs (token, dot-safety) are under Help & Quick Reference. Inconsistent.

6. **158 orphaned files** - Conventions, bugs, demos, reports, diagrams, and many more have no nav entry.

---

## Proposed Structure

### Option A: 7-Section Restructure (Recommended)

Reduce from 14 to 7 top-level sections by merging related content.

```
nav:
  - Home: index.md

  - Getting Started:                          # MERGE: Getting Started + Help
      - Choose Your Path: ...
      - Quick Start (5-min): ...
      - Installation: ...
      - I'm Stuck: ...
      - FAQ: ...
      - FAQ - Dependencies: ...
      - Troubleshooting: ...
      - Quick Reference: help/QUICK-REFERENCE.md
      - Common Workflows: help/WORKFLOWS.md
      - Claude Code Environment: ...
      - Release Notes: RELEASES.md
      - Changelog: CHANGELOG.md

  - Learn:                                    # MERGE: Tutorials (grouped)
      - Overview & Learning Path: ...
      - Core Workflows:
          - Your First Session: ...
          - Multiple Projects: ...
          - Status Visualizations: ...
          - Web Dashboard: ...
          - AI-Powered Commands: ...
          - Dopamine Features: ...
      - Git & Projects:
          - Sync Command: ...
          - Git Feature Workflow: ...
          - Worktrees: ...
          - Plugin Optimization: ...
          - Token Automation: ...
      - Dispatchers:
          - CC Dispatcher: ...
          - TM Dispatcher: ...
          - DOT Dispatcher: ...
          - Prompt Dispatcher: ...
      - Editor (Neovim):
          - Nvim Quick Start: ...
          - Vim Motions: ...
          - LazyVim Basics: ...
          - LazyVim Showcase: ...

  - Teaching:                                 # KEEP (already well-organized)
      - Overview: ...
      - Getting Started: (3 items)
      - Core Workflows: (5 items)
      - Features: (9 items)
      - Tutorials: (2 items)
      - Reference: (12 items)
      - Advanced: (6 items)
      - Legacy: (4 items)

  - Workflows & Guides:                       # MERGE: Workflows + Guides
      - Start Here: guides/00-START-HERE.md
      - Quick Wins: ...
      - Git & Branching:
          - Git Feature Flow: ...
          - Worktree Workflow: ...
      - Dotfiles & Config:
          - Dotfile Workflow: ...
          - Dotfile Management: ...
          - Chezmoi Safety: ...
          - Config Management: ...
          - Alias Management: ...
      - Tools & Integrations:
          - ZSH Plugin Ecosystem: ...
          - Token Management: ...
          - Quarto Workflow: ...
          - Lint Validation: (2 items)
          - Mermaid Diagrams: ...
          - Enhanced Help: ...
          - Monorepo Commands: ...
      - Advanced:
          - YOLO Mode: ...
          - Plugin Management: ...
          - Project Scope: ...
          - Workflow Tutorial: ...

  - Reference:                                # MERGE: Reference + Commands + REFCARDs
      - API & Architecture:
          - Master API Reference: ...
          - Master Dispatcher Guide: ...
          - Master Architecture: ...
          - Documentation Dashboard: ...
      - Commands:
          - flow (main): ...
          - work: ...
          - finish: ...
          - hop: ...
          - pick: ...
          - (all 20 commands)
      - Quick Reference Cards:
          - Token & Secrets: ...
          - Chezmoi Safety: ...
          - Chezmoi Safety API: ...
      - Architecture Deep Dives:
          - Chezmoi Safety: ...
          - Doctor Token System: ...
          - Teaching Dates: ...
          - Scholar Enhancement: ...

  - Contributing:                             # MERGE: Development + Testing + Architecture
      - Developer Guide: ...
      - Contributing: ...
      - Branch Workflow: ...
      - PR Workflow Guide: ...
      - Documentation Style Guide: ...
      - GIF Creation Guide: ...              # From Visuals
      - Documentation Templates: ...         # From Visuals
      - Guidelines: ...
      - Conventions: ...
      - Philosophy: ...
      - Testing:
          - Testing Guide: ...
          - Safe Testing: ...
          - Interactive Tests: (2 items)
      - Planning:
          - v4.3.0+ Roadmap: ...
          - Install Improvements: ...
```

#### Section Count Comparison

| Current | Proposed | Change |
|---------|----------|--------|
| Home | Home | Same |
| Documentation Hub | (removed) | Merged into Home |
| Getting Started | Getting Started | Expanded |
| Tutorials | Learn | Grouped into 4 subsections |
| Teaching | Teaching | Same |
| Workflows | Workflows & Guides | Merged |
| Guides | (merged above) | Combined |
| Visuals | (merged into Contributing) | 2 items moved |
| Help & Quick Reference | (merged into Getting Started + Reference) | Split |
| Reference | Reference | Expanded |
| Commands | (merged into Reference) | Subsection |
| Testing | (merged into Contributing) | Subsection |
| Development | Contributing | Renamed + expanded |
| Architecture | (merged into Reference) | Subsection |
| Planning | (merged into Contributing) | Subsection |

**Result: 14 sections → 7 sections**

---

### Option B: 5-Section Ultra-Minimal

More aggressive consolidation for maximum simplicity.

```
nav:
  - Home
  - Learn:           # Getting Started + Tutorials + Teaching
  - Use:             # Workflows + Guides + Commands
  - Reference:       # API + Architecture + REFCARDs
  - Contribute:      # Development + Testing + Planning
```

**Pros:** Maximum simplicity, 5 tabs
**Cons:** "Learn" becomes massive (80+ pages), Teaching loses its dedicated tab

---

### Option C: 9-Section Moderate Trim

Less aggressive, preserves Teaching and Commands as top-level.

```
nav:
  - Home
  - Getting Started   # + Help
  - Tutorials          # Grouped into subsections
  - Teaching           # Unchanged
  - Guides             # + Workflows
  - Commands           # Unchanged
  - Reference          # + Architecture + REFCARDs
  - Contributing       # + Testing + Development + Planning
```

**Pros:** Less change, Commands stays visible
**Cons:** Still 9 sections (was 14), Tutorials still needs grouping

---

## Quick Wins

1. **Remove Documentation Hub** - It's a meta-page that adds a tab without clear value. Make Home the entry point.

2. **Fix the duplicate** - `tutorials/08-git-feature-workflow.md` appears in both Tutorials and Workflows.

3. **Group Tutorials** - Add subsection headers (Core, Git, Dispatchers, Editor) to break up the flat list of 18.

4. **Merge Visuals into Contributing** - Only 2 items, both about documentation creation standards.

5. **Merge Testing/Planning into Development** - Small sections that are developer-focused.

## Medium Effort

6. **Merge Workflows + Guides** - Content overlap is significant. "Worktree Workflow" (Workflows) vs "Dotfile Management" (Guides) are the same content type.

7. **Move Commands under Reference** - Commands are reference material by nature.

8. **Consolidate Help items** - Move Quick Reference and common workflows into Getting Started. Move REFCARDs into Reference.

9. **Move Architecture under Reference** - Architecture docs are reference material for developers.

## Long-term

10. **Triage 158 orphaned files** - Decide: add to nav, archive, or delete. Priority directories:
    - `reference/.archive/` (67 files) - Already archived, verify not needed
    - `guides/` (9 orphaned) - Should be in nav
    - `reports/` (8 files) - Decide if user-facing
    - `tutorials/` (6 orphaned) - Should be in nav
    - `conventions/` (17 files) - Move useful ones to Contributing

11. **Create landing pages** - Each section gets an index.md with cards/links (Teaching already has this).

12. **Add search tags** - MkDocs Material supports tags plugin for cross-cutting discoverability.

---

## Recommended Path

**Option A (7 sections)** is the best balance of simplicity and organization:
- Cuts cognitive load in half (14 → 7 tabs)
- Teaching keeps its dedicated section (largest, best-organized)
- No content is deleted, only reorganized
- Tutorials get meaningful groupings instead of a flat numbered list
- Reference becomes the single source for all lookup-oriented content

### Implementation Order

1. Group Tutorials into subsections (within existing section, low risk)
2. Merge tiny sections: Visuals → Contributing, Testing → Contributing, Planning → Contributing
3. Merge overlapping sections: Workflows + Guides, Help → Getting Started + Reference
4. Move Commands under Reference
5. Move Architecture under Reference
6. Remove Documentation Hub tab
7. Update cross-references and internal links
8. Triage orphaned files (separate PR)

---

## Next Steps

1. [ ] Review this proposal and select option (A/B/C)
2. [ ] Create implementation spec: `SPEC-website-reorganization-2026-02-02.md`
3. [ ] Implement in phases (each phase = one PR)
4. [ ] Triage orphaned files (separate effort)

---

**Generated by:** /craft:do → brainstorm
**Duration:** Analysis of 426 files, 154 nav entries, 14 sections
