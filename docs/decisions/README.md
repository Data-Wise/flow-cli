# Architecture Decision Records (ADRs)

This directory contains Architecture Decision Records for the flow-cli system.

## What is an ADR?

An Architecture Decision Record (ADR) captures an important architectural decision along with its context and consequences. ADRs help:

- **Document "why"** decisions were made
- **Provide context** for future developers
- **Track trade-offs** and consequences
- **Enable discussion** before committing to decisions

## Format

Each ADR includes:

- **Status**: ✅ Accepted, 🟡 Proposed, ❌ Rejected, 🔄 Superseded
- **Date**: When the decision was made
- **Context**: What forces led to this decision?
- **Decision**: What did we decide?
- **Consequences**: What are the trade-offs?
- **Alternatives**: What else did we consider?

## Index

### Accepted

| ADR                                             | Title                                                  | Status      | Date       |
| ----------------------------------------------- | ------------------------------------------------------ | ----------- | ---------- |
| [ADR-001](ADR-001-use-vendored-code-pattern.md) | Use Vendored Code Pattern for Project Detection        | ✅ Accepted | 2025-12-20 |
| [ADR-002](ADR-002-adopt-clean-architecture.md)  | Adopt Clean Architecture for Long-Term Maintainability | ✅ Accepted | 2025-12-20 |
| [ADR-003](ADR-003-bridge-pattern.md)            | Bridge Pattern for Shell Integration                   | ✅ Accepted | 2025-12-20 |
| [ADR-004](ADR-004-module-api-not-rest.md)       | Use Node.js Module API Pattern (Not REST/HTTP)         | ✅ Accepted | 2025-12-20 |

### Proposed

| ADR            | Title | Status | Date |
| -------------- | ----- | ------ | ---- |
| None currently |       |        |      |

## Decision Matrix

### By Layer

| Layer          | Decisions                                             |
| -------------- | ----------------------------------------------------- |
| **Domain**     | ADR-002 (Clean Architecture), ADR-004 (DDD - planned) |
| **Adapters**   | ADR-003 (Bridge Pattern)                              |
| **Frameworks** | ADR-001 (Vendored Code)                               |

### By Topic

| Topic              | Decisions                                         |
| ------------------ | ------------------------------------------------- |
| **Architecture**   | ADR-002 (Clean Architecture)                      |
| **Integration**    | ADR-001 (Vendored Code), ADR-003 (Bridge Pattern) |
| **Testing**        | ADR-002 (testability focus)                       |
| **Dependencies**   | ADR-001 (zero external deps)                      |
| **Error Handling** | ADR-003 (graceful degradation)                    |

## Creating New ADRs

### Template

```markdown
# ADR-XXX: [Short Title]

**Status:** 🟡 Proposed / ✅ Accepted / ❌ Rejected / 🔄 Superseded by ADR-YYY

**Date:** YYYY-MM-DD

**Deciders:** [Names]

**Technical Story:** [Context]

---

## Context and Problem Statement

[Describe the context and problem...]

**Question:** [The question we're answering]

---

## Decision Drivers

- [Driver 1]
- [Driver 2]

---

## Decision

**Chosen option: "[Name]"** because [reasons]

[Detailed explanation with code examples]

---

## Consequences

### Positive

- ✅ [Benefit 1]

### Negative

- ⚠️ [Drawback 1]

### Neutral

- 📝 [Neutral consequence 1]

---

## Alternative Considered: [Name]

**Rejected because:** [reasons]

---

## Related Decisions

- [ADR-XXX: Title](ADR-XXX-title.md)

---

## References

- [Source 1]

---

**Last Updated:** YYYY-MM-DD
**See Also:** [Related docs]
```

### Workflow

1. **Propose**: Create ADR with status 🟡 Proposed
2. **Discuss**: Team reviews and discusses
3. **Decide**: Update status to ✅ Accepted or ❌ Rejected
4. **Implement**: Follow through on decision
5. **Update**: Add learnings to "Consequences" section

### Superseding ADRs

When a decision is reversed:

1. Create new ADR with new decision
2. Update old ADR status to 🔄 Superseded
3. Add link to new ADR
4. Keep old ADR for historical context

## Reading Order

**For new contributors:**

1. [ADR-002: Clean Architecture](ADR-002-adopt-clean-architecture.md) - Overall system structure
2. [ADR-001: Vendored Code Pattern](ADR-001-use-vendored-code-pattern.md) - How we handle dependencies
3. [ADR-003: Bridge Pattern](ADR-003-bridge-pattern.md) - Shell integration patterns
4. [ADR-004: Node.js Module API](ADR-004-module-api-not-rest.md) - API design philosophy

**For architecture decisions:**

- Start with [ADR-002: Clean Architecture](ADR-002-adopt-clean-architecture.md)
- Then read layer-specific ADRs

**For integration patterns:**

- Start with [ADR-001: Vendored Code](ADR-001-use-vendored-code-pattern.md)
- Then [ADR-003: Bridge Pattern](ADR-003-bridge-pattern.md)
- Then [ADR-004: Module API Pattern](ADR-004-module-api-not-rest.md)

## Statistics

- **Total ADRs**: 4
- **Accepted**: 4
- **Proposed**: 0
- **Rejected**: 0
- **Superseded**: 0

## Planned ADRs

Future decisions to document:

- **ADR-005**: Domain-Driven Design for Sessions and Projects
- **ADR-006**: Graceful Degradation Pattern for Error Handling
- **ADR-007**: Parallel Execution for Batch Operations
- **ADR-008**: File System vs Database for Persistence
- **ADR-009**: Event-Driven Architecture for Session Management

---

**Last Updated:** 2025-12-26
**Part of:** Architecture Enhancement Plan
**See Also:** [Architecture Quick Wins](../architecture/ARCHITECTURE-QUICK-WINS.md)
