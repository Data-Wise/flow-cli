# Architecture Documentation Index & Glossary

**Quick lookup for terms, concepts, and documentation locations**

---

## 📖 Glossary of Terms

### A

**Adapter**
- **Definition:** Implementation of a port (interface) that connects to external systems
- **Example:** `FileSystemSessionRepository` adapts file system to `ISessionRepository` interface
- **See:** [ADR-002](./decisions/ADR-002-adopt-clean-architecture.md), [Hexagonal Architecture](#hexagonal-architecture)

**ADR (Architecture Decision Record)**
- **Definition:** Document capturing an important architectural decision with context and consequences
- **Location:** `/docs/architecture/decisions/`
- **See:** [ADR README](./decisions/README.md)

**Aggregate**
- **Definition:** Cluster of entities with one root that enforces consistency boundaries
- **Example:** `Session` is an aggregate root containing tasks and context
- **See:** [DDD](#domain-driven-design-ddd), [CODE-EXAMPLES.md](./CODE-EXAMPLES.md)

**API (Application Programming Interface)**
- **Our Pattern:** Node.js module functions (not REST/HTTP)
- **Why:** Local tool, not web service
- **See:** [ADR-003](./decisions/ADR-003-nodejs-module-api-not-rest.md), [API-DESIGN-REVIEW.md](./API-DESIGN-REVIEW.md)

---

### B

**Bridge Pattern**
- **Definition:** JavaScript code that calls shell scripts via `child_process`
- **Example:** `project-detector-bridge.js` calls `project-detector.sh`
- **See:** [VENDOR-INTEGRATION-ARCHITECTURE.md](./VENDOR-INTEGRATION-ARCHITECTURE.md)

**Business Logic**
- **Definition:** Core rules and workflows specific to the domain
- **Location:** Domain layer (entities, value objects)
- **Example:** "Cannot end inactive session" rule in `Session.end()`

---

### C

**Clean Architecture**
- **Definition:** 4-layer pattern where dependencies point inward
- **Layers:** Domain → Use Cases → Adapters → Frameworks
- **See:** [ADR-002](./decisions/ADR-002-adopt-clean-architecture.md), [ARCHITECTURE-PATTERNS-ANALYSIS.md](./ARCHITECTURE-PATTERNS-ANALYSIS.md)

**Controller**
- **Definition:** Handles user input and delegates to use cases
- **Example:** `SessionController` handles CLI commands
- **Layer:** Adapters (interface adapters)

---

### D

**DDD (Domain-Driven Design)**
- **Definition:** Design approach focused on modeling the business domain
- **Components:** Entities, Value Objects, Aggregates, Repositories, Services
- **See:** [ARCHITECTURE-PATTERNS-ANALYSIS.md](./ARCHITECTURE-PATTERNS-ANALYSIS.md)

**Dependency Injection**
- **Definition:** Passing dependencies via constructor instead of creating them internally
- **Example:** `new CreateSessionUseCase(repository)` instead of `new CreateSessionUseCase()` creating repository
- **Why:** Testability, flexibility

**Dependency Rule**
- **Definition:** Dependencies point INWARD only (inner layers never depend on outer layers)
- **Example:** Domain never imports from Use Cases, Use Cases never import from Adapters
- **See:** [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)

**Domain**
- **Definition:** Innermost layer containing pure business logic
- **Contains:** Entities, Value Objects, Domain Services, Repository Interfaces
- **Rules:** ZERO external dependencies

---

### E

**Entity**
- **Definition:** Object with identity that encapsulates behavior and state
- **Example:** `Session`, `Project`, `Task`
- **Characteristics:** Has ID, mutable, enforces business rules
- **See:** [CODE-EXAMPLES.md](./CODE-EXAMPLES.md#creating-a-new-entity)

**Event**
- **Definition:** Something that happened (past tense, immutable)
- **Example:** `SessionStarted`, `ProjectScanned`
- **Use:** Trigger side effects, audit trail, event sourcing

---

### F

**Frameworks & Drivers**
- **Definition:** Outermost layer with external tools and libraries
- **Examples:** ZSH shell, Node.js runtime, vendor scripts, Express.js
- **See:** [4-Layer Architecture](#clean-architecture)

---

### G

**Gateway**
- **Definition:** Adapter that wraps external systems
- **Example:** `ProjectDetectorGateway` wraps vendored shell scripts
- **Pattern:** Adapter pattern in hexagonal architecture

---

### H

**Hexagonal Architecture (Ports & Adapters)**
- **Definition:** Pattern where application core is surrounded by adapters
- **Ports:** Interfaces (what we need)
- **Adapters:** Implementations (how we get it)
- **See:** [QUICK-REFERENCE.md](./QUICK-REFERENCE.md#ports--adapters)

---

### I

**Interface Adapters**
- **Definition:** Layer 3 in Clean Architecture
- **Contains:** Controllers, Gateways, Presenters, Repository implementations
- **Purpose:** Translate between use cases and external systems

---

### L

**Layer**
- **Concept:** Horizontal slice of architecture with specific responsibilities
- **Our Layers:**
  1. Domain (core)
  2. Use Cases (application logic)
  3. Adapters (interfaces)
  4. Frameworks (external tools)

---

### P

**Port**
- **Definition:** Interface (contract) defined by inner layers
- **Example:** `ISessionRepository` (interface)
- **Implemented by:** Adapters (outer layers)
- **See:** [Hexagonal Architecture](#hexagonal-architecture-ports--adapters)

**Presenter**
- **Definition:** Formats output for specific interface
- **Examples:** `JSONPresenter`, `TerminalPresenter`
- **Layer:** Adapters

---

### R

**Repository**
- **Definition:** Interface for persisting and retrieving aggregates
- **Pattern:** One repository per aggregate root
- **Example:** `ISessionRepository` (interface), `FileSystemSessionRepository` (implementation)
- **See:** [CODE-EXAMPLES.md](./CODE-EXAMPLES.md#repository-interfaces)

---

### U

**Use Case**
- **Definition:** Application-specific business workflow
- **Example:** `CreateSessionUseCase`, `ScanProjectsUseCase`
- **Layer:** Layer 2 (application logic)
- **Depends on:** Domain (entities, interfaces)
- **See:** [CODE-EXAMPLES.md](./CODE-EXAMPLES.md#use-cases-layer)

---

### V

**Value Object**
- **Definition:** Immutable object defined by its attributes (no identity)
- **Example:** `ProjectType`, `SessionState`, `TaskPriority`
- **Characteristics:** Immutable, compared by value, no ID
- **See:** [CODE-EXAMPLES.md](./CODE-EXAMPLES.md#value-objects)

**Vendoring**
- **Definition:** Copying external code into repository
- **Why:** Zero dependencies, reliable, one-command install
- **Example:** Shell scripts from `zsh-claude-workflow` copied to `cli/vendor/`
- **See:** [ADR-001](./decisions/ADR-001-use-vendored-code-pattern.md)

---

## 🔍 Concept Index

| Concept | Defined In | Examples In |
|---------|-----------|-------------|
| Clean Architecture | [ADR-002](./decisions/ADR-002-adopt-clean-architecture.md) | [ARCHITECTURE-PATTERNS-ANALYSIS.md](./ARCHITECTURE-PATTERNS-ANALYSIS.md) |
| Hexagonal Architecture | [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) | [ARCHITECTURE-PATTERNS-ANALYSIS.md](./ARCHITECTURE-PATTERNS-ANALYSIS.md) |
| Domain-Driven Design | [ARCHITECTURE-PATTERNS-ANALYSIS.md](./ARCHITECTURE-PATTERNS-ANALYSIS.md) | [CODE-EXAMPLES.md](./CODE-EXAMPLES.md) |
| Dependency Inversion | [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) | [GETTING-STARTED.md](./GETTING-STARTED.md) |
| Vendored Code Pattern | [ADR-001](./decisions/ADR-001-use-vendored-code-pattern.md) | [VENDOR-INTEGRATION-ARCHITECTURE.md](./VENDOR-INTEGRATION-ARCHITECTURE.md) |
| Module API Pattern | [ADR-003](./decisions/ADR-003-nodejs-module-api-not-rest.md) | [API-DESIGN-REVIEW.md](./API-DESIGN-REVIEW.md) |
| Entities | [CODE-EXAMPLES.md](./CODE-EXAMPLES.md) | [GETTING-STARTED.md](./GETTING-STARTED.md) |
| Value Objects | [CODE-EXAMPLES.md](./CODE-EXAMPLES.md) | [ARCHITECTURE-PATTERNS-ANALYSIS.md](./ARCHITECTURE-PATTERNS-ANALYSIS.md) |
| Repositories | [CODE-EXAMPLES.md](./CODE-EXAMPLES.md) | [GETTING-STARTED.md](./GETTING-STARTED.md) |
| Use Cases | [CODE-EXAMPLES.md](./CODE-EXAMPLES.md) | [GETTING-STARTED.md](./GETTING-STARTED.md) |

---

## 📂 File Location Index

### Core Architecture Docs

| File | Purpose | Audience | Reading Time |
|------|---------|----------|--------------|
| [ARCHITECTURE-PATTERNS-ANALYSIS.md](./ARCHITECTURE-PATTERNS-ANALYSIS.md) | Deep architectural analysis | Architects, Senior Devs | 30-45 min |
| [API-DESIGN-REVIEW.md](./API-DESIGN-REVIEW.md) | API design patterns | All developers | 20-30 min |
| [VENDOR-INTEGRATION-ARCHITECTURE.md](./VENDOR-INTEGRATION-ARCHITECTURE.md) | Vendored code integration | Integration developers | 15-20 min |

### Quick References

| File | Purpose | Use When |
|------|---------|----------|
| [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) | One-page cheat sheet | Need quick reminder |
| [VENDOR-INTEGRATION-QUICK-REFERENCE.md](./VENDOR-INTEGRATION-QUICK-REFERENCE.md) | Vendoring quick ref | Updating vendor code |
| [API-DESIGN-QUICK-REFERENCE.md](./API-DESIGN-QUICK-REFERENCE.md) | API patterns quick ref | Writing new APIs |

### Learning Resources

| File | Purpose | Time Required |
|------|---------|---------------|
| [GETTING-STARTED.md](./GETTING-STARTED.md) | Hands-on tutorial | 30-45 min |
| [CODE-EXAMPLES.md](./CODE-EXAMPLES.md) | Copy-paste examples | 10-60 min (by section) |
| [DOCUMENTATION-MAP.md](./DOCUMENTATION-MAP.md) | Navigation guide | 5 min |

### Decisions (ADRs)

| File | Decision | Status |
|------|----------|--------|
| [ADR-001](./decisions/ADR-001-use-vendored-code-pattern.md) | Vendored Code Pattern | ✅ Accepted |
| [ADR-002](./decisions/ADR-002-adopt-clean-architecture.md) | Clean Architecture | ✅ Accepted |
| [ADR-003](./decisions/ADR-003-nodejs-module-api-not-rest.md) | Module API (not REST) | ✅ Accepted |

---

## 🎯 Quick Lookups

### "Where should this code go?"

| Code Type | Layer | Directory |
|-----------|-------|-----------|
| Business rules | Domain | `cli/domain/entities/` |
| Data structures (immutable) | Domain | `cli/domain/value-objects/` |
| Data access contracts | Domain | `cli/domain/repositories/` (interfaces) |
| Application workflows | Use Cases | `cli/use-cases/` |
| User input handling | Adapters | `cli/adapters/controllers/` |
| External system wrappers | Adapters | `cli/adapters/gateways/` |
| Data persistence | Adapters | `cli/adapters/repositories/` (implementations) |
| Output formatting | Adapters | `cli/adapters/presenters/` |
| Shell scripts, vendor code | Frameworks | `cli/vendor/` |
| CLI setup | Frameworks | `cli/frameworks/` |

### "How do I..."

| Task | See |
|------|-----|
| Create a new entity | [GETTING-STARTED.md](./GETTING-STARTED.md#step-1-create-domain-entity) |
| Write a use case | [GETTING-STARTED.md](./GETTING-STARTED.md#step-3-create-use-case) |
| Implement a repository | [GETTING-STARTED.md](./GETTING-STARTED.md#step-4-implement-repository) |
| Write tests | [CODE-EXAMPLES.md](./CODE-EXAMPLES.md#testing-patterns) |
| Update vendored scripts | [VENDOR-INTEGRATION-QUICK-REFERENCE.md](./VENDOR-INTEGRATION-QUICK-REFERENCE.md#maintenance-checklist) |
| Design an API | [API-DESIGN-QUICK-REFERENCE.md](./API-DESIGN-QUICK-REFERENCE.md) |

### "What pattern should I use?"

| Scenario | Pattern | Reference |
|----------|---------|-----------|
| Wrapping external code | Gateway (Adapter) | [VENDOR-INTEGRATION](./VENDOR-INTEGRATION-ARCHITECTURE.md) |
| Swappable implementations | Port & Adapter (Interface + Impl) | [QUICK-REFERENCE](./QUICK-REFERENCE.md#ports--adapters) |
| Business rules | Entity methods | [GETTING-STARTED](./GETTING-STARTED.md#step-1) |
| Immutable data | Value Object | [CODE-EXAMPLES](./CODE-EXAMPLES.md#value-objects) |
| Data persistence | Repository | [GETTING-STARTED](./GETTING-STARTED.md#step-2) |
| Workflow orchestration | Use Case | [GETTING-STARTED](./GETTING-STARTED.md#step-3) |

---

## 🔗 Cross-References

### By Topic

**Architecture Patterns:**
- Clean Architecture: [ADR-002](./decisions/ADR-002-adopt-clean-architecture.md), [ARCHITECTURE-PATTERNS-ANALYSIS.md](./ARCHITECTURE-PATTERNS-ANALYSIS.md)
- Hexagonal Architecture: [QUICK-REFERENCE.md](./QUICK-REFERENCE.md), [ARCHITECTURE-PATTERNS-ANALYSIS.md](./ARCHITECTURE-PATTERNS-ANALYSIS.md)
- Domain-Driven Design: [ARCHITECTURE-PATTERNS-ANALYSIS.md](./ARCHITECTURE-PATTERNS-ANALYSIS.md), [CODE-EXAMPLES.md](./CODE-EXAMPLES.md)

**Integration:**
- Vendored Code: [ADR-001](./decisions/ADR-001-use-vendored-code-pattern.md), [VENDOR-INTEGRATION-ARCHITECTURE.md](./VENDOR-INTEGRATION-ARCHITECTURE.md)
- Bridge Pattern: [VENDOR-INTEGRATION-QUICK-REFERENCE.md](./VENDOR-INTEGRATION-QUICK-REFERENCE.md)

**API Design:**
- Module Pattern: [ADR-003](./decisions/ADR-003-nodejs-module-api-not-rest.md), [API-DESIGN-REVIEW.md](./API-DESIGN-REVIEW.md)
- Best Practices: [API-DESIGN-QUICK-REFERENCE.md](./API-DESIGN-QUICK-REFERENCE.md)

**Implementation:**
- Getting Started: [GETTING-STARTED.md](./GETTING-STARTED.md)
- Code Examples: [CODE-EXAMPLES.md](./CODE-EXAMPLES.md)

---

**Last Updated:** 2025-12-23
**Part of:** Architecture Enhancement Plan (A→C Implementation)
**Maintained By:** Development Team
