# Flow-CLI Design Specifications

This directory contains comprehensive design specifications for flow-cli features and enhancements.

---

## Current Specifications

### Dotfile Management Integration (2026-01-08)

A complete UX design for integrating dotfile management (chezmoi + Bitwarden) into flow-cli via a new `dot` dispatcher.

**Status:** Design Complete → Ready for Implementation

#### Documents

| Document | Purpose | Size |
|----------|---------|------|
| [DOTFILE-INTEGRATION-SUMMARY.md](DOTFILE-INTEGRATION-SUMMARY.md) | Executive summary with key recommendations | Quick read |
| [dotfile-ux-design.md](dotfile-ux-design.md) | Complete UX design document | Comprehensive |
| [dot-dispatcher-refcard.md](dot-dispatcher-refcard.md) | Quick reference card with command patterns | Reference |
| [dot-dispatcher-visual-mockups.md](dot-dispatcher-visual-mockups.md) | 21 visual mockups of terminal output | Visual |
| [dot-dispatcher-implementation-checklist.md](dot-dispatcher-implementation-checklist.md) | Step-by-step implementation guide | Development |

#### Quick Start

**For reviewers:**
1. Read: [DOTFILE-INTEGRATION-SUMMARY.md](DOTFILE-INTEGRATION-SUMMARY.md) (5 min)
2. Browse: [dot-dispatcher-visual-mockups.md](dot-dispatcher-visual-mockups.md) (3 min)
3. Approve: Command name (`dot`) and core design

**For developers:**
1. Review: [dotfile-ux-design.md](dotfile-ux-design.md) (20 min)
2. Follow: [dot-dispatcher-implementation-checklist.md](dot-dispatcher-implementation-checklist.md)
3. Reference: [dot-dispatcher-refcard.md](dot-dispatcher-refcard.md) during development

#### Key Decisions

| Decision | Rationale |
|----------|-----------|
| **Command name: `dot`** | Short, memorable, follows dispatcher pattern |
| **Dispatcher pattern** | Consistency with existing architecture (g, mcp, cc, etc.) |
| **3 core operations** | `dot` (status), `df edit`, `df sync` cover 80% of daily use |
| **ADHD-optimized** | Fast, forgiving, discoverable, consistent |
| **Integration points** | Dashboard, work command, flow doctor |

#### Implementation

**Estimated effort:** 26 hours over 3-4 weeks

**Phases:**
1. Foundation (4h) - Basic dispatcher skeleton
2. Core workflows (8h) - Edit, sync, push, diff, apply
3. Secret management (6h) - Bitwarden integration
4. Integration (4h) - Dashboard, work, doctor
5. Polish (4h) - Tests, docs, completions

**Deliverables:**
- `lib/dispatchers/dot-dispatcher.zsh`
- `lib/dotfile-helpers.zsh`
- `completions/_df`
- `docs/reference/DOT-DISPATCHER-REFERENCE.md`
- `docs/tutorials/dotfile-setup.md`
- `tests/dot-dispatcher.test.zsh`

#### Success Metrics

**Week 4 (MVP):**
- All core commands work
- Secret management operational
- Dashboard/work integration complete
- Tests passing

**Week 8 (Adoption):**
- User runs `dot` daily
- Zero manual chezmoi commands
- No sync conflicts

**Week 12 (Mastery):**
- 100% sync reliability
- Zero friction
- Natural integration

---

## Related Documents

### Architecture
- [CLAUDE.md](../CLAUDE.md) - Project guidance for AI assistants
- [DISPATCHER-REFERENCE.md](../reference/DISPATCHER-REFERENCE.md) - Existing dispatcher patterns

### Background Research
- [dotfile-management-plan_1.md](dotfile-management-plan_1.md) - Original infrastructure plan
  - Comparison: Chezmoi+BW vs SOPS vs Nix
  - Architecture decisions
  - Daily workflows
  - New machine setup

---

## Design Philosophy

All specifications in this directory follow flow-cli's core principles:

### 1. ADHD-Friendly Design

**Discoverable:**
- Built-in help at every level
- Progressive disclosure (simple → detailed)
- Inline hints and suggestions

**Consistent:**
- Same patterns across all dispatchers
- Predictable command structure
- Uniform color scheme and icons

**Forgiving:**
- Smart defaults
- Fuzzy matching
- Auto-recovery from errors
- Undo always available

**Fast:**
- Sub-10ms response for core commands
- All operations < 3 seconds
- Instant visual feedback

### 2. User Experience Principles

**Status-First:**
- Most useful information at zero effort
- Clear visual indicators (🟢/🟡/🔴)
- Quick action suggestions

**Error Recovery:**
- Every error shows what/why/how
- Auto-recovery when possible
- Guided resolution for conflicts
- No raw error dumps

**Progressive Disclosure:**
- Level 1: Quick status (zero typing)
- Level 2: Full help (one command)
- Level 3: Detailed docs (as needed)

**Integration:**
- Seamless with existing commands
- Non-intrusive notifications
- Opt-out always available

---

## Document Structure

All design specs should include:

1. **Executive Summary** - Key decisions and recommendations
2. **Problem Statement** - What are we solving?
3. **Design Overview** - High-level architecture
4. **Detailed Design** - Complete specifications
5. **Visual Mockups** - What users will see
6. **Implementation Plan** - Step-by-step checklist
7. **Testing Strategy** - How to verify success
8. **Success Metrics** - How to measure adoption

---

## Review Process

### Design Phase
1. Create spec documents
2. Review with stakeholders
3. Get approval on key decisions
4. Finalize design

### Implementation Phase
1. Follow implementation checklist
2. Build according to design
3. Match visual mockups exactly
4. Write tests for all features

### Release Phase
1. Verify all success criteria
2. Update documentation
3. Deploy to production
4. Monitor for issues

---

## Contributing

When adding new specifications:

1. **Create a directory** if the spec is large (multiple files)
2. **Use consistent naming**: `feature-name-ux-design.md`, `feature-name-refcard.md`, etc.
3. **Include visual mockups** for terminal output
4. **Write an implementation checklist** for developers
5. **Update this README** to list the new spec

### Template Structure

```markdown
# Feature Name - UX Design

**Date:** YYYY-MM-DD
**Status:** Design | Development | Released
**Estimated Effort:** X hours

## Executive Summary
[Key recommendations]

## Problem Statement
[What we're solving]

## Design Overview
[High-level architecture]

## Detailed Design
[Complete specifications]

## Visual Mockups
[Terminal output examples]

## Implementation Plan
[Step-by-step guide]

## Testing Strategy
[How to verify]

## Success Metrics
[How to measure]
```

---

## Contact

For questions about these specifications:
- See: [CLAUDE.md](../CLAUDE.md) for project context
- See: [CONTRIBUTING.md](../../CONTRIBUTING.md) for development guidelines
- Issues: https://github.com/Data-Wise/flow-cli/issues

---

**Last Updated:** 2026-01-08
**Next Spec:** TBD
