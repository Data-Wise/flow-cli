# Teaching Menu Consolidation Plan

**Created:** 2026-01-29
**Purpose:** Consolidate scattered teaching documentation into a unified "Teaching" navigation section

---

## Current State Analysis

### Teaching Docs Currently Scattered Across:

1. **Tutorials Section** (4 items)
   - 14. Teach Dispatcher
   - 19. Teaching + Git Integration
   - 21. Teach Analyze
   - 28. Teach Prompt

2. **Workflows Section** (3 items)
   - Teaching Workflow v3.0
   - Teaching Workflow (Legacy)
   - Teaching Visual Guide

3. **Guides Section** (7 items under "Teaching v3.0" + "Teaching (Legacy)")
   - v3.0 User Guide
   - Concept Analysis
   - Backup System Guide
   - Help System Guide
   - Migration Guide
   - Course Planning Best Practices
   - System Architecture, Commands, Demo, Dates (legacy)

4. **Help & Quick Reference** (4 teaching refcards)
   - Token & Secrets Quick Ref
   - Templates Quick Ref
   - LaTeX Macros Quick Ref
   - Lesson Plan Quick Ref
   - Prompts Quick Ref

5. **Commands Section** (2 items)
   - teach (dispatcher)
   - teach-init

---

## Proposed Consolidated Structure

```yaml
- 🎓 Teaching:
    # Getting Started (Beginner-friendly entry points)
    - Getting Started:
        - Quick Start: tutorials/14-teach-dispatcher.md
        - Setup & Initialization: commands/teach-init.md
        - System Health Check: guides/BACKUP-SYSTEM-GUIDE.md (extract doctor section)

    # Core Workflows (Main teaching tasks)
    - Workflows:
        - Complete v3.0 Workflow: guides/TEACHING-WORKFLOW-V3-GUIDE.md
        - Content Creation: guides/INTELLIGENT-CONTENT-ANALYSIS.md
        - Git Integration: tutorials/19-teaching-git-integration.md
        - Deployment: guides/TEACHING-WORKFLOW-V3-GUIDE.md#deployment-workflow
        - Visual Workflow Guide: guides/TEACHING-WORKFLOW-VISUAL.md

    # Features & Capabilities (What you can do)
    - Features:
        - Content Analysis: tutorials/21-teach-analyze.md
        - AI-Powered Prompts: tutorials/28-teach-prompt.md
        - Template Management: tutorials/24-template-management.md
        - LaTeX Macros: tutorials/26-latex-macros.md
        - Lesson Plans: tutorials/27-lesson-plan-management.md
        - Backup & Safety: guides/BACKUP-SYSTEM-GUIDE.md

    # Reference (Command docs & quick refs)
    - Reference:
        - Command Overview: commands/teach.md
        - Quick Reference Cards:
            - Templates: reference/REFCARD-TEMPLATES.md
            - LaTeX Macros: reference/REFCARD-MACROS.md
            - Lesson Plans: reference/REFCARD-TEACH-PLAN.md
            - Prompts: reference/REFCARD-PROMPTS.md
            - Tokens & Secrets: reference/REFCARD-TOKEN-SECRETS.md
        - Help System: guides/HELP-SYSTEM-GUIDE.md

    # Advanced Topics (Power users)
    - Advanced:
        - Scholar Integration: tutorials/scholar-enhancement/index.md
        - Course Planning Best Practices: guides/COURSE-PLANNING-BEST-PRACTICES.md
        - Migration from v2: guides/TEACHING-V3-MIGRATION-GUIDE.md
        - System Architecture: guides/TEACHING-SYSTEM-ARCHITECTURE.md

    # Legacy Documentation (Archived but accessible)
    - Legacy (v2.x):
        - v2 Workflow: guides/TEACHING-WORKFLOW.md
        - Commands Deep Dive: guides/TEACHING-COMMANDS-DETAILED.md
        - Dates Guide: guides/TEACHING-DATES-GUIDE.md
        - Demo & GIFs: guides/TEACHING-DEMO-GUIDE.md
```

---

## Design Principles

### 1. Progressive Disclosure

- **Beginner → Intermediate → Advanced**
- Start with Quick Start, end with Architecture
- Clear skill level indicators

### 2. ADHD-Friendly Organization

- **Task-oriented** (not feature-oriented)
- Clear visual hierarchy with emoji icons
- Grouped by user intent ("I want to...")
- No more than 5 items per section

### 3. Minimize Duplication

- One canonical source per topic
- Use section links (#anchors) for subsections
- Legacy docs clearly marked but accessible

### 4. Discoverability

- Emoji icon (🎓) for visual recognition
- Clear section names (Getting Started, Workflows, Features)
- Consistent naming patterns

---

## Migration Notes

### Removed from Other Sections:

**Tutorials:**

- 14, 19, 21, 28 → Teaching section

**Workflows:**

- All 3 teaching workflows → Teaching section

**Guides:**

- "Teaching v3.0" subsection → Teaching section
- "Teaching (Legacy)" subsection → Teaching/Legacy section

**Help & Quick Reference:**

- Teaching refcards → Teaching/Reference section
- (Token refcard stays - used by other dispatchers too)

**Commands:**

- teach, teach-init → Teaching/Reference section

### Preserved in Other Sections:

**Help & Quick Reference:**

- Token & Secrets Quick Ref (used by dot dispatcher, git, etc.)
- Keep here + link from Teaching/Reference

---

## Benefits

1. **Single Source of Truth** - All teaching docs in one place
2. **Better Onboarding** - Clear learning path for new users
3. **Reduced Cognitive Load** - No hunting across sections
4. **Maintains Context** - Related docs grouped together
5. **Future-Proof** - Easy to add new teaching features

---

## Implementation Steps

1. Create Teaching section in mkdocs.yml
2. Move items from scattered sections
3. Optional: Create landing page (docs/teaching/index.md)
4. Test navigation locally (mkdocs serve)
5. Deploy to GitHub Pages
6. Update CLAUDE.md to reflect new structure

---

## Notes

- Keep Token & Secrets refcard in both locations (it's cross-cutting)
- Legacy docs remain accessible but clearly marked
- Scholar Enhancement tutorials could be Teaching/Advanced or standalone
- Consider creating teaching/index.md landing page for overview
