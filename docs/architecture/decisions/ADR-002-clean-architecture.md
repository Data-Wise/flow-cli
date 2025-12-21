# ADR-002: Adopt Clean Architecture with Four Explicit Layers

**Status:** 🟡 Proposed (Planned for Week 2+)

**Date:** 2025-12-20

**Deciders:** DT

**Technical Story:** Architecture review and future roadmap

---

## Context and Problem Statement

The current zsh-configuration system uses a 3-layer architecture (Frontend ZSH → Backend Node.js → Vendor Shell). While this works, it mixes concerns - the backend layer combines use cases with infrastructure, and there's no explicit domain layer for business rules.

**Question:** How should we structure the codebase for long-term maintainability and testability?

**Current Pain Points:**
- Business logic scattered across layers
- Hard to test without filesystem/shell execution
- Controllers tightly coupled to use cases
- No clear separation between "what" (domain) and "how" (infrastructure)

---

## Decision Drivers

- **Testability**: Must be able to test business logic without external dependencies
- **Maintainability**: Changes should be localized to one layer
- **Flexibility**: Should be easy to swap implementations (file system → database)
- **Clarity**: Architecture should be self-documenting
- **ADHD-friendly**: Clear structure reduces cognitive load

---

## Decision

**Chosen option: "Clean Architecture with Four Explicit Layers"**

### Layer Structure

```
┌─────────────────────────────────────────┐
│ Layer 4: Frameworks & Drivers (Outer)  │
│ - ZSH Shell, Vendor Scripts, External  │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│ Layer 3: Interface Adapters             │
│ - Controllers, Gateways, Presenters     │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│ Layer 2: Use Cases (Application Logic)  │
│ - CreateSession, ScanProjects, etc.     │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│ Layer 1: Domain (Business Rules)        │
│ - Entities, Value Objects, Ports        │
└─────────────────────────────────────────┘
```

### Dependency Rule

**Critical:** Dependencies point INWARD only

- ✅ Layer 4 can depend on Layer 3, 2, 1
- ✅ Layer 3 can depend on Layer 2, 1
- ✅ Layer 2 can depend on Layer 1
- ❌ Layer 1 depends on NOTHING
- ❌ Inner layers NEVER depend on outer layers

### Directory Mapping

```
cli/
├── domain/                    # Layer 1 (innermost)
│   ├── entities/              # Session, Project, Task
│   ├── value-objects/         # ProjectType, SessionState
│   └── repositories/          # ISessionRepository (interfaces)
│
├── use-cases/                 # Layer 2
│   ├── CreateSessionUseCase.js
│   └── ScanProjectsUseCase.js
│
├── adapters/                  # Layer 3
│   ├── controllers/           # SessionController
│   ├── gateways/              # ProjectDetectorGateway
│   ├── presenters/            # TerminalPresenter
│   └── repositories/          # FileSystemSessionRepository
│
└── frameworks/                # Layer 4 (outermost)
    ├── cli/                   # CLI entry point
    ├── vendor/                # Vendored shell scripts
    └── di-container.js        # Dependency injection
```

---

## Consequences

### Positive

- ✅ **Testability**: Domain layer has zero dependencies (pure functions)
- ✅ **Flexibility**: Easy to swap file system for database
- ✅ **Clarity**: Each layer has single responsibility
- ✅ **Maintainability**: Changes isolated to one layer
- ✅ **Domain-Driven**: Business rules explicit and protected
- ✅ **Framework Independence**: Could move from Node.js to Rust without touching domain

### Negative

- ⚠️ **More files**: More boilerplate (interfaces, adapters)
- ⚠️ **Learning curve**: Team must understand layer boundaries
- ⚠️ **Migration effort**: Must refactor existing code
- ⚠️ **Abstraction overhead**: More indirection to follow

### Neutral

- 📝 **Dependency Injection**: Requires DI container setup
- 📝 **Testing strategy**: Different approaches per layer
- 📝 **Documentation**: Must document layer responsibilities

---

## Validation

### Acceptance Criteria

1. **Domain Layer**:
   - ✅ Zero imports from outer layers
   - ✅ 100% test coverage without mocks
   - ✅ Business rules encapsulated in entities

2. **Use Cases Layer**:
   - ✅ Single responsibility (one use case = one workflow)
   - ✅ Depends only on domain interfaces
   - ✅ Tested with in-memory repositories

3. **Adapters Layer**:
   - ✅ Implements domain interfaces
   - ✅ Translates between domain and external formats
   - ✅ Integration tests verify external integrations

4. **Frameworks Layer**:
   - ✅ Thin wrapper around use cases
   - ✅ Wires dependencies via DI container
   - ✅ E2E tests verify full stack

### Implementation Roadmap

**Phase 1 (Week 2)**: Foundation
- Create domain entities (Session, Project, Task)
- Create value objects (ProjectType, SessionState)
- Define repository interfaces

**Phase 2 (Week 3)**: Migration
- Extract use cases from existing backend
- Implement adapters (file system, shell gateway)
- Create DI container

**Phase 3 (Week 4)**: Enhancement
- Add domain events
- Implement additional use cases
- Complete test coverage

---

## Alternative Considered: Keep Current 3-Layer Architecture

**Pros:**
- ✓ Simpler (fewer files)
- ✓ Faster short-term development
- ✓ No migration needed

**Cons:**
- ✗ Business logic scattered
- ✗ Hard to test
- ✗ Tight coupling
- ✗ Framework lock-in

**Decision:** Rejected - Technical debt will compound as system grows

---

## Alternative Considered: Microservices Architecture

**Pros:**
- ✓ Independent deployment
- ✓ Technology diversity
- ✓ Scalability

**Cons:**
- ✗ Massive overkill for CLI tool
- ✗ Network overhead
- ✗ Operational complexity
- ✗ Local-only tool doesn't need network separation

**Decision:** Rejected - Not appropriate for local CLI tool

---

## Ports & Adapters (Hexagonal Architecture)

This decision implements Hexagonal Architecture principles:

- **Ports** = Interfaces defined by domain (e.g., `ISessionRepository`)
- **Adapters** = Implementations in outer layer (e.g., `FileSystemSessionRepository`)

```
Domain defines:               Adapters implement:
┌─────────────────┐          ┌──────────────────────────┐
│ ISessionRepo    │  ←───────│ FileSystemSessionRepo    │
│ - save()        │          │ - save() → writes JSON   │
│ - findById()    │          │ - findById() → reads file│
└─────────────────┘          └──────────────────────────┘
                             ┌──────────────────────────┐
                             │ InMemorySessionRepo      │
                             │ - save() → array.push()  │
                             └──────────────────────────┘
```

**Benefit:** Swap implementations without changing domain!

---

## Related Decisions

- [ADR-001: Vendored Code Pattern](ADR-001-vendored-code-pattern.md)
- [ADR-003: Bridge Pattern for Shell Integration](ADR-003-bridge-pattern.md)
- [ADR-004: Domain-Driven Design for Sessions and Projects](ADR-004-domain-driven-design.md)

---

## References

- **Clean Architecture** (Robert C. Martin) - Book
- **Hexagonal Architecture** (Alistair Cockburn) - Pattern
- **Domain-Driven Design** (Eric Evans) - Book

---

**Last Updated:** 2025-12-21
**Part of:** Documentation Sprint (Week 1)
**See Also:** [ARCHITECTURE-PATTERNS-ANALYSIS.md](../ARCHITECTURE-PATTERNS-ANALYSIS.md), [QUICK-REFERENCE.md](../QUICK-REFERENCE.md)
