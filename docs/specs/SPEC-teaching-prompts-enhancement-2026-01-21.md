# SPEC: Teaching Prompts Enhancement System

**Version:** 1.0.0
**Status:** Draft
**Created:** 2026-01-21
**From Brainstorm:** BRAINSTORM-teaching-prompts-enhancement-2026-01-21.md

---

## Overview

Enhance PR #283's static teaching prompts into an integrated, intelligent content generation system with 3-tier storage, template rendering, and interactive workflows.

---

## Primary User Story

**As a** statistics instructor using flow-cli
**I want** seamless prompt integration with teach-dispatcher commands
**So that** I can generate course content with one command instead of manual copy-paste

**Acceptance Criteria:**
- ✅ `teach prompt list` shows available prompts
- ✅ `teach prompt show <type>` displays prompt with pagination
- ✅ `teach lecture "Topic"` auto-uses lecture-notes.md prompt
- ✅ Prompts auto-fill from teach-config.yml (packages, notation)
- ✅ Generated content validates against prompt requirements

---

## Secondary User Stories

### Discovery
**As a** new flow-cli user
**I want** to discover available prompts easily
**So that** I know what content types I can generate

### Customization
**As an** instructor with specific pedagogical preferences
**I want** to customize prompts for my course
**So that** generated content matches my teaching style

### Sharing
**As a** lead instructor
**I want** to share prompt customizations with TAs
**So that** all sections have consistent teaching materials

---

## Technical Requirements

### Architecture

**3-Tier Storage System:**

```
Tier 1: Global Defaults (read-only)
  lib/templates/teaching/claude-prompts/
  - Shipped with flow-cli releases
  - Source of truth for fresh installs

Tier 2: User Library (editable)
  ~/.flow/prompts/
  - User-wide customizations
  - Survives flow-cli updates
  - Named collections: ~/.flow/libraries/

Tier 3: Course-Specific (versioned)
  .claude/prompts/*.local.md
  - Full copies (isolated per course)
  - Committed to git
  - Shared with TAs
```

**Precedence:** Course → User → Global

---

### API Design

#### Core Commands (Phase 1)

```bash
teach prompt list              # Show available prompts
teach prompt show <type>       # Display prompt (paginated)
teach prompt info <type>       # Show metadata
```

#### Management Commands (Phase 2)

```bash
teach prompt edit <type>       # Copy to .claude/, open in $EDITOR
teach prompt enhance <type>    # Interactive wizard
teach prompt add <name>        # Create new prompt
teach prompt promote <type>    # Copy .local.md → ~/.flow/
```

#### Advanced Commands (Phase 3)

```bash
teach prompt library create <name>
teach prompt library use <name>
teach prompt catalog install <name>
teach prompt versions <type>
teach prompt upgrade <type>
```

---

### Data Models

#### teach-config.yml Schema

```yaml
course:
  name: string
  code: string
  r_packages:
    core: string[]
    diagnostics: string[]
    reporting: string[]
  notation:
    expectation: string
    variance: string
    style: "macros" | "inline" | "mixed"
  pedagogy:
    derivation_depth: "heuristic" | "rigorous-with-intuition" | "full-rigor"
    practice_problems_count: [number, number]
    include_diagnostic_workflow: boolean
```

#### Prompt Metadata

```markdown
<!--
Version: semver
Last Modified: ISO-8601 date
Author: string
Customizer: string (optional)
Compatible with: string[]
Tags: string[]
-->
```

---

### Dependencies

**Required:**
- yq (YAML parsing)
- git (version control)
- ZSH (shell environment)

**Optional:**
- Scholar plugin v2.x (enhanced teaching commands)
- Claude Code (AI recipe triggers)

---

## UI/UX Specifications

### Interactive Enhancement Wizard

**Flow:**

```
teach prompt enhance lecture
  ↓
Step 1/5: R Package Customization
  Current: emmeans, lme4, car
  Add more? [y/N]: y
  Packages: DHARMa, broom
  ✓
Step 2/5: Derivation Depth
  1. Heuristic only
  2. Rigorous-with-intuition ✓
  3. Full rigor
  Choice: 2
  ✓
Step 3/5: Practice Problems
  Current: 4-10
  Change? [y/N]: y
  New count: 6-8
  ✓
Step 4/5: Add Custom Section
  Add section? [y/N]: y
  Name: Computational Performance
  (Opens editor for content)
  ✓
Step 5/5: Save Location
  (g) Global ~/.flow/
  (l) Local .claude/ [recommended]
  Choice: l
  ✓
Enhanced prompt saved to .claude/prompts/lecture-notes.local.md
```

---

### Conflict Resolution

**Flow:**

```
teach lecture "ANOVA"
  ↓
⚠️ Prompt exists in both global + local
  ↓
Show diff:
  Section: R Packages
    Global: emmeans, lme4, car
    Local:  emmeans, lme4, car, DHARMa, broom
    Change: +2 packages
  ↓
Which version?
  (l) Local [recommended]
  (g) Global
  (d) Show full diff
  (m) Merge interactively
  ↓
Using local version
```

---

## Open Questions

1. **Should prompts validate teach-config.yml exists?**
   - Option A: Require teach-config.yml for template rendering
   - Option B: Work without it (no variable substitution)
   - **Recommendation:** Option B (graceful degradation)

2. **How to handle prompt upgrades with breaking changes?**
   - Option A: Auto-upgrade with migration
   - Option B: Notify user, manual upgrade
   - **Recommendation:** Option B (explicit user control)

3. **Should validation block content generation?**
   - Option A: Hard block (prevent generation if invalid)
   - Option B: Warn only (allow generation, show warnings)
   - **Recommendation:** Option B for Phase 1, Option A opt-in for Phase 2

---

## Review Checklist

**Architecture:**
- [ ] 3-tier storage implemented
- [ ] Precedence rules working (Course → User → Global)
- [ ] Auto-restore if ~/.flow/prompts/ deleted
- [ ] Full copies per course (not symlinks)

**Commands:**
- [ ] `teach prompt list` shows all prompts
- [ ] `teach prompt show <type>` paginates correctly
- [ ] `teach prompt edit <type>` copies to .claude/
- [ ] `teach prompt enhance <type>` wizard works
- [ ] `teach prompt promote <type>` with backup

**Template Rendering:**
- [ ] teach-config.yml schema documented
- [ ] Variables render correctly ({{course.*}})
- [ ] Graceful degradation without teach-config.yml
- [ ] All 3 prompts support template variables

**Testing:**
- [ ] Unit tests for template rendering
- [ ] Integration tests for conflict resolution
- [ ] Manual testing with real course
- [ ] Validation schema tests

**Documentation:**
- [ ] README updated with examples
- [ ] teach-dispatcher help updated
- [ ] Migration guide for existing courses
- [ ] Quick start guide

---

## Implementation Notes

### Phase 1: Quick Wins (1-2 hours)

**Wave 1: Foundation (20 min)**
- Add versioning headers to prompts
- Create 3 sample outputs

**Wave 2: teach-dispatcher Integration (30 min)**
- Add `teach prompt list/show` commands
- Update routing and help

**Wave 3: User Library (15 min)**
- Initialize ~/.flow/prompts/ on first use
- Auto-restore if deleted

**Wave 4: Documentation (15 min)**
- Enhance README with examples
- Add Quick Start guide

---

### Phase 2: Power Features (3-5 hours)

**Wave 1: Edit & Promote (1 hour)**
- `teach prompt edit <type>`
- `teach prompt promote <type>`
- Conflict resolution

**Wave 2: Template Rendering (1.5 hours)**
- Create teach-config.yml.template
- Implement rendering engine
- Add template variables to prompts

**Wave 3: Enhancement Wizard (1.5 hours)**
- Design wizard flow
- Implement step-by-step enhancement
- Save location decision

**Wave 4: Validation (1 hour)**
- Create validation schemas
- Implement `teach validate <file>`
- Course-specific schema support

---

### Phase 3: Advanced Systems (8-12 hours)

**Wave 1: Named Collections (2 hours)**
- ~/.flow/libraries/ structure
- `teach prompt library` commands
- Library selection in teach init

**Wave 2: New Prompts (6 hours)**
- assignment.md
- exam.md
- syllabus.md
- rubric.md

**Wave 3: Built-in Catalog (2 hours)**
- CATALOG.yml schema
- `teach prompt browse/install`
- Community prompts

**Wave 4: Version Management (2 hours)**
- `teach prompt versions/upgrade/diff`
- Migration guide system

---

## History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-01-21 | 1.0.0 | DT | Initial specification from brainstorm |

---

## Related Documents

- **Brainstorm:** `docs/specs/BRAINSTORM-teaching-prompts-enhancement-2026-01-21.md`
- **Architecture:** `docs/architecture/ARCHITECTURE-prompt-storage-2026-01-21.md`
- **UX Spec:** `docs/specs/UX-SPEC-prompt-management-2026-01-21.md`
- **Implementation Plan:** `docs/planning/FINAL-IMPLEMENTATION-PLAN-2026-01-21.md`
- **Original PR:** PR #283 (teaching prompts)

