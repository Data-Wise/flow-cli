# ADR Summary - Executive Overview

**Quick reference to all architecture decisions**

This document provides a high-level summary of all Architecture Decision Records (ADRs). For full details, see individual ADR documents.

**Last Updated:** 2025-12-21
**Total ADRs:** 3 (2 Accepted, 1 Proposed)

---

## Quick Reference Table

| ADR                                         | Title                                | Status      | Impact | Date       |
| ------------------------------------------- | ------------------------------------ | ----------- | ------ | ---------- |
| [001](ADR-001-use-vendored-code-pattern.md) | Vendored Code Pattern                | ✅ Accepted | High   | 2025-12-20 |
| [002](ADR-002-adopt-clean-architecture.md)  | Clean Architecture                   | 🟡 Proposed | High   | 2025-12-20 |
| [003](ADR-003-bridge-pattern.md)            | Bridge Pattern for Shell Integration | ✅ Accepted | Medium | 2025-12-20 |

---

## ADR-001: Vendored Code Pattern ✅

**Decision:** Copy external shell scripts into our codebase instead of depending on external repositories

**Context:**

- Need project detection functionality from `zsh-claude-workflow`
- Want zero external dependencies
- Need ability to evolve independently

**Solution:**

```
cli/vendor/
└── zsh-claude-workflow/
    ├── project-detector.sh    # Vendored detection logic
    └── core.sh                # Vendored core utilities
```

**Key Benefits:**

- ✅ Zero npm/external dependencies
- ✅ Complete control over code
- ✅ No breaking changes from upstream
- ✅ Fast, reliable builds

**Trade-offs:**

- ⚠️ Manual sync required for updates
- ⚠️ Duplicate code across projects

**Impact:**

- **Current:** Project detection working in CLI
- **Future:** Template for other vendored integrations

**Read Full ADR:** [ADR-001-use-vendored-code-pattern.md](ADR-001-use-vendored-code-pattern.md)

---

## ADR-002: Clean Architecture 🟡

**Decision:** Adopt 4-layer Clean Architecture for the system

**Context:**

- Current 3-layer (CLI → Lib → Vendor) works but:
  - Business logic mixed with adapters
  - Hard to test without file I/O
  - Unclear where new code belongs

**Proposed Solution:**

```
Domain Layer         # Pure business logic (Entities, Value Objects)
   ↓
Use Cases Layer      # Application logic (orchestration)
   ↓
Adapters Layer       # External integrations (file system, shell)
   ↓
Frameworks Layer     # CLI, web, etc.
```

**Key Benefits:**

- ✅ Testable without I/O (in-memory adapters)
- ✅ Clear layer responsibilities
- ✅ Easy to swap implementations
- ✅ Domain logic protected from framework changes

**Trade-offs:**

- ⚠️ More files/directories
- ⚠️ Requires refactoring existing code
- ⚠️ Learning curve for contributors

**Status:** Proposed (evaluation in progress)

**Implementation Options:**

1. **Quick Wins (1 week):** Error classes + validation only
2. **Pragmatic (2 weeks):** + Use Cases + TypeScript definitions
3. **Full (4-6 weeks):** Complete 4-layer refactoring

**Read Full ADR:** [ADR-002-adopt-clean-architecture.md](ADR-002-adopt-clean-architecture.md)

---

## ADR-003: Bridge Pattern for Shell Integration ✅

**Decision:** Use Bridge Pattern to integrate JavaScript with shell scripts

**Context:**

- JavaScript needs to execute ZSH scripts
- Two incompatible environments:
  - **JavaScript:** async/await, objects, exceptions
  - **Shell:** text output, exit codes

**Solution:**

```javascript
// JavaScript Bridge Layer

export async function detectProjectType(projectPath) {
  try {
    // Execute shell command
    const { stdout } = await execAsync(`source "${script}" && get_project_type "${path}"`, {
      shell: '/bin/zsh'
    })

    // Transform: Shell string → JavaScript string
    const shellType = stdout.trim()

    // Transform: Shell type → API type
    return mapProjectType(shellType) // 'rpkg' → 'r-package'
  } catch (error) {
    // Transform: Shell error → Graceful degradation
    return 'unknown'
  }
}
```

**Key Benefits:**

- ✅ Clean separation (JavaScript ↔ Shell)
- ✅ Type mapping at boundary
- ✅ Centralized error handling
- ✅ Testable (can mock execAsync)
- ✅ Graceful degradation

**Trade-offs:**

- ⚠️ Performance overhead (~20-50ms per call)
- ⚠️ Requires /bin/zsh to be available

**Impact:**

- **Current:** All 7 project detector tests passing
- **Pattern:** Reusable for other shell integrations

**Read Full ADR:** [ADR-003-bridge-pattern.md](ADR-003-bridge-pattern.md)

---

## Decision Matrix

### By Implementation Status

| Status                             | Count | ADRs                                              |
| ---------------------------------- | ----- | ------------------------------------------------- |
| ✅ **Accepted & Implemented**      | 2     | ADR-001 (Vendored Code), ADR-003 (Bridge Pattern) |
| 🟡 **Proposed (Under Evaluation)** | 1     | ADR-002 (Clean Architecture)                      |
| ❌ **Rejected**                    | 0     | -                                                 |
| 🔄 **Superseded**                  | 0     | -                                                 |

### By Impact Level

| Impact     | ADRs                                                           |
| ---------- | -------------------------------------------------------------- |
| **High**   | ADR-001 (dependency management), ADR-002 (system architecture) |
| **Medium** | ADR-003 (integration pattern)                                  |
| **Low**    | -                                                              |

### By Architectural Layer

| Layer          | ADRs                                             |
| -------------- | ------------------------------------------------ |
| **Domain**     | ADR-002 (proposed - will define domain layer)    |
| **Use Cases**  | ADR-002 (proposed - will define use cases layer) |
| **Adapters**   | ADR-003 (shell integration adapter)              |
| **Frameworks** | ADR-001 (vendored code in framework layer)       |

### By Topic

| Topic              | ADRs                                              |
| ------------------ | ------------------------------------------------- |
| **Dependencies**   | ADR-001 (zero external dependencies)              |
| **Integration**    | ADR-001 (vendored code), ADR-003 (bridge pattern) |
| **Architecture**   | ADR-002 (clean architecture)                      |
| **Testing**        | ADR-002 (testability), ADR-003 (mockable bridge)  |
| **Error Handling** | ADR-003 (graceful degradation)                    |

---

## Roadmap - Planned ADRs

Future architectural decisions to document:

### ADR-004: Domain-Driven Design for Sessions and Projects

**Status:** Planned
**Context:** Need to model Sessions and Projects as domain entities
**Key Questions:**

- What are the invariants?
- What are value objects vs entities?
- How to enforce business rules?

### ADR-005: Graceful Degradation Pattern

**Status:** Planned
**Context:** How to handle errors without crashing
**Key Questions:**

- When to fail fast vs degrade gracefully?
- What are acceptable fallbacks?
- How to log degradation for debugging?

### ADR-006: Parallel Execution for Batch Operations

**Status:** Planned
**Context:** Need to process multiple projects/sessions efficiently
**Key Questions:**

- How to parallelize safely?
- How to handle errors in parallel operations?
- What's the right concurrency limit?

### ADR-007: File System vs Database for Persistence

**Status:** Planned
**Context:** Current file-based storage may not scale
**Key Questions:**

- When to switch to SQLite/database?
- How to migrate existing data?
- Performance trade-offs?

### ADR-008: Event-Driven Architecture for Session Management

**Status:** Planned
**Context:** Session lifecycle has many events (start, pause, resume, end)
**Key Questions:**

- Should we use event sourcing?
- What events to track?
- How to replay events?

---

## How to Use This Summary

### For New Contributors

**Start here** to understand key architectural decisions:

1. Read this summary (5 min)
2. Read [ADR-001](ADR-001-use-vendored-code-pattern.md) - Understand dependency approach (10 min)
3. Read [ADR-003](ADR-003-bridge-pattern.md) - Understand JS ↔ Shell integration (10 min)
4. Skim [ADR-002](ADR-002-adopt-clean-architecture.md) - Proposed architecture (optional, 15 min)

**Total:** 25-40 minutes for full context

### For Architecture Discussions

**Reference this summary** when:

- Proposing new features (which layer?)
- Debating trade-offs (what did we decide before?)
- Evaluating alternatives (why did we reject option X?)

### For Implementation

**Check ADRs** before:

- Adding external dependencies → See ADR-001
- Integrating with shell scripts → See ADR-003
- Creating new layers/modules → See ADR-002
- Handling errors → See ADR-003 (graceful degradation)

---

## Statistics

### ADR Coverage

- **Total decisions documented:** 3
- **Accepted & implemented:** 2 (67%)
- **Under evaluation:** 1 (33%)
- **Planned for future:** 5

### Documentation Size

| ADR       | Lines     | Sections | Code Examples |
| --------- | --------- | -------- | ------------- |
| ADR-001   | 566       | 11       | 8             |
| ADR-002   | 700       | 13       | 12            |
| ADR-003   | 293       | 11       | 6             |
| **Total** | **1,559** | **35**   | **26**        |

### Decision Quality

- ✅ All ADRs include context, decision, consequences, alternatives
- ✅ All ADRs include code examples
- ✅ All ADRs link to related documentation
- ✅ All ADRs have "Last Updated" dates

---

## Related Documentation

### Process

- [ADR Index](README.md) - Full ADR index with template
- [Contributing Guide](../contributing/CONTRIBUTING.md) - Development patterns

---

## Creating New ADRs

### When to Create an ADR

Create an ADR when making decisions that:

- ✅ Affect system architecture
- ✅ Have multiple valid options
- ✅ Impact multiple components
- ✅ Have long-term consequences
- ✅ Need team alignment

### Quick Start

1. **Copy template** from [ADR Index](README.md)
2. **Fill in sections:**
   - Context and Problem Statement
   - Decision Drivers
   - Decision (with code examples)
   - Consequences (positive, negative, neutral)
   - Alternatives Considered (with rejection reasons)
3. **Set status** to 🟡 Proposed
4. **Get team review**
5. **Update status** to ✅ Accepted or ❌ Rejected
6. **Update this summary** with new ADR

### ADR Workflow

```
🟡 Proposed → 💬 Discussion → ✅ Accepted → 🏗️ Implementation → ✅ Complete
                ↓
              ❌ Rejected
```

---

**Questions about ADRs?** See [ADR Index](README.md)

---

**Last Updated:** 2025-12-26
**Part of:** Architecture Documentation Sprint
**See Also:** [ADR Index](README.md)
