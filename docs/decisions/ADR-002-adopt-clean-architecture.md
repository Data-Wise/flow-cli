# ADR-002: Adopt Clean Architecture for Long-Term Maintainability

**Status:** ✅ Accepted
**Date:** 2025-12-20
**Deciders:** Development Team
**Technical Story:** Planning for Week 2+ Architecture Refactor

---

## Context and Problem Statement

The flow-cli system currently uses a simple 3-layer architecture (Frontend → Backend → Vendor) that works well for the initial implementation. As the system grows, we need to decide on a more robust architectural pattern that will:

- Support testing without extensive mocking
- Allow swapping implementations (e.g., file system → database)
- Keep business logic independent of frameworks
- Enable multiple interfaces (CLI, Desktop UI, REST API)

**Key Question:** Should we continue with the current ad-hoc structure, or adopt a formal architecture pattern like Clean Architecture, Hexagonal Architecture, or Layered Architecture?

---

## Decision Drivers

- **Testability** - Must be able to test business logic without I/O
- **Flexibility** - Should easily swap data sources (files → DB → API)
- **Independence** - Core logic shouldn't depend on frameworks
- **Maintainability** - New developers should understand structure quickly
- **Scalability** - Architecture should support growth (desktop app, web UI)
- **ADHD-Friendly** - Clear boundaries reduce cognitive load

---

## Considered Options

### Option 1: Continue Current 3-Layer Architecture

```
Frontend (ZSH) → Backend (Node.js) → Vendor (Shell)
```

**Pros:**

- ✅ Simple and straightforward
- ✅ Easy to implement initially
- ✅ Minimal files and boilerplate

**Cons:**

- ❌ Business logic mixed with infrastructure
- ❌ Hard to test (file system dependencies)
- ❌ Difficult to swap implementations
- ❌ Controllers know too much about data access

### Option 2: Layered Architecture

```
Presentation → Business Logic → Data Access
```

**Pros:**

- ✅ Well-understood pattern
- ✅ Clear separation of concerns
- ✅ Better than current state

**Cons:**

- ❌ Allows dependencies to flow downward only (not ideal)
- ❌ Database layer often becomes coupled to business logic
- ❌ Doesn't enforce dependency inversion

### Option 3: Clean Architecture + Hexagonal (Ports & Adapters) ✅ CHOSEN

```
┌─────────────────────────────────┐
│  Frameworks & Drivers (Outer)  │
│  ┌───────────────────────────┐  │
│  │  Adapters (Interfaces)    │  │
│  │  ┌─────────────────────┐  │  │
│  │  │  Use Cases (Logic)  │  │  │
│  │  │  ┌───────────────┐  │  │  │
│  │  │  │  Domain       │  │  │  │
│  │  │  │  (Entities)   │  │  │  │
│  │  │  └───────────────┘  │  │  │
│  │  └─────────────────────┘  │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
  Dependencies point INWARD →
```

**4 Layers:**

1. **Domain** - Entities, value objects, business rules (innermost)
2. **Use Cases** - Application-specific workflows
3. **Adapters** - Controllers, gateways, presenters
4. **Frameworks** - ZSH, Node.js, vendor scripts (outermost)

**Pros:**

- ✅ Business logic completely independent of I/O
- ✅ Easy to test (mock interfaces, not implementations)
- ✅ Swap implementations without changing core
- ✅ Framework-agnostic (could replace Node.js someday)
- ✅ Clear dependency direction (inward only)
- ✅ Well-documented pattern (books, articles, examples)

**Cons:**

- ⚠️ More files and boilerplate (acceptable trade-off)
- ⚠️ Steeper learning curve initially (mitigated by docs)
- ⚠️ Requires discipline to maintain boundaries

---

## Decision Outcome

**Chosen option:** "Clean Architecture + Hexagonal Architecture" (Option 3)

### Rationale

1. **Testability is Critical**
   The current system is hard to test because business logic is intertwined with file I/O. Clean Architecture separates these concerns completely:

   ```javascript
   // BEFORE: Hard to test
   async function createSession(project) {
     const path = `~/.config/zsh/.worklog`
     await fs.writeFile(path, JSON.stringify({ project }))
   }

   // AFTER: Easy to test
   class CreateSessionUseCase {
     constructor(sessionRepository) {
       this.repo = sessionRepository // Interface, not file system
     }

     async execute({ project }) {
       const session = new Session(id, project)
       await this.repo.save(session)
       return session
     }
   }

   // Test with mock repository (no file I/O)
   const mockRepo = { save: async s => s }
   const useCase = new CreateSessionUseCase(mockRepo)
   ```

2. **Future-Proofing for Multiple Interfaces**
   We plan to add:
   - Desktop UI (Electron) - in progress
   - REST API (future)
   - Web dashboard (future)

   Clean Architecture makes this trivial - same use cases, different controllers:

   ```javascript
   // Same use case, different controllers
   const useCase = new CreateSessionUseCase(repo)

   // CLI Controller
   class CLIController {
     handleCommand(args) {
       return useCase.execute({ project: args[0] })
     }
   }

   // REST Controller
   class APIController {
     handleRequest(req, res) {
       return useCase.execute({ project: req.body.project })
     }
   }

   // Desktop Controller
   class ElectronController {
     handleIPC(event, data) {
       return useCase.execute({ project: data.project })
     }
   }
   ```

3. **Dependency Inversion Principle**
   Inner layers define interfaces (ports), outer layers implement them (adapters). This inverts dependencies:

   ```javascript
   // Domain defines what it needs (port)
   class ISessionRepository {
     async save(session) {
       throw new Error('Not implemented')
     }
   }

   // Adapters provide implementations
   class FileSystemSessionRepository extends ISessionRepository {
     async save(session) {
       /* write to file */
     }
   }

   class DatabaseSessionRepository extends ISessionRepository {
     async save(session) {
       /* write to DB */
     }
   }

   // Use case doesn't care which implementation
   const useCase = new CreateSessionUseCase(new FileSystemSessionRepository())
   // Later, swap easily:
   const useCase = new CreateSessionUseCase(new DatabaseSessionRepository())
   ```

4. **Domain-Driven Design Benefits**
   Business rules live in entities, not scattered across layers:

   ```javascript
   class Session {
     end() {
       // Business rule: Can only end active sessions
       if (this.state !== SessionState.ACTIVE) {
         throw new Error('Cannot end inactive session')
       }

       this.endTime = new Date()
       this.state = SessionState.ENDED
     }
   }
   ```

5. **Clear Boundaries Reduce Cognitive Load**
   For ADHD-friendly development, clear boundaries help:
   - "This is domain code - pure business logic, no I/O"
   - "This is adapter code - talks to external systems"
   - "Dependencies always point inward"

---

## Implementation Plan

### Phase 1: Foundation (Week 2)

**Create core structure:**

```
cli/
├── domain/
│   ├── entities/          # Session, Project, Task
│   ├── value-objects/     # ProjectType, SessionState
│   └── repositories/      # ISessionRepository (interfaces)
├── use-cases/
│   ├── CreateSessionUseCase.js
│   ├── EndSessionUseCase.js
│   └── ScanProjectsUseCase.js
├── adapters/
│   ├── controllers/       # SessionController
│   ├── repositories/      # FileSystemSessionRepository
│   └── gateways/          # ProjectDetectorGateway
└── frameworks/
    ├── cli/
    └── vendor/
```

**Start with:**

1. Session entity (domain)
2. CreateSessionUseCase (use case)
3. FileSystemSessionRepository (adapter)
4. SessionController (adapter)

### Phase 2: Migration (Week 3)

**Migrate existing code:**

- `project-detector-bridge.js` → `ProjectDetectorGateway` (adapter)
- Status/workflow APIs → Use cases + domain entities
- CLI commands → Controllers

### Phase 3: Enhancement (Week 4+)

**Add advanced features:**

- Event publishing (domain events)
- Multiple repository implementations (in-memory for tests)
- Plugin system using ports & adapters

---

## Consequences

### Positive

- ✅ **Highly testable** - Business logic has zero I/O dependencies
- ✅ **Flexible** - Swap implementations without touching core
- ✅ **Framework-independent** - Could replace Node.js if needed
- ✅ **Multiple interfaces** - CLI, Desktop, Web from same core
- ✅ **Clear boundaries** - Easy to reason about code location
- ✅ **Industry-standard** - Well-documented pattern with examples

### Negative

- ⚠️ **More boilerplate** - More files and interfaces (one-time cost)
- ⚠️ **Learning curve** - Team needs to understand pattern (mitigated by docs)
- ⚠️ **Discipline required** - Must maintain boundaries (code reviews help)

### Neutral

- ℹ️ **Gradual migration** - Can adopt incrementally (no big-bang rewrite)
- ℹ️ **Documentation critical** - Need good examples and reference cards

---

## Validation

### Success Criteria

- [ ] Domain layer has **zero external dependencies** (pure business logic)
- [ ] Use cases can be tested with **in-memory repositories** (no file I/O)
- [ ] **Same use case** can be called from CLI, Desktop UI, and API controllers
- [ ] New developers can **understand structure** from reference docs
- [ ] Adding new features takes **< 30 min** following established patterns

### Metrics (Post-Implementation)

```bash
# Dependency direction validation
npm run arch-check
✓ No outward dependencies from domain
✓ No outward dependencies from use cases
✓ All adapters implement interfaces

# Test independence
npm test -- domain/
✓ 100% coverage, 0ms avg (no I/O)

npm test -- use-cases/
✓ Uses in-memory repos only

# Interface count (measure of flexibility)
# Interfaces: 3 (ISessionRepository, IProjectRepository, IProjectDetector)
# Implementations: 6 (File/Memory/DB repositories, etc.)
```

---

## Related Decisions

- **ADR-001**: Use Vendored Code Pattern - Vendor scripts become "frameworks" layer
- **ADR-003**: JavaScript Bridge Pattern - Bridges become "gateways" (adapters)
- **Future ADR**: Event Sourcing (if we adopt CQRS pattern later)

---

## References

**Books:**

- _Clean Architecture_ by Robert C. Martin (Uncle Bob)
- _Domain-Driven Design_ by Eric Evans
- _Implementing Domain-Driven Design_ by Vaughn Vernon

**Articles:**

- [The Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html) - Uncle Bob
- [Hexagonal Architecture](https://alistair.cockburn.us/hexagonal-architecture/) - Alistair Cockburn
- [Ports & Adapters Pattern](https://herbertograca.com/2017/09/14/ports-adapters-architecture/)

**Internal Docs:**

- [ARCHITECTURE-PATTERNS-ANALYSIS.md](../ARCHITECTURE-PATTERNS-ANALYSIS.md) - Full analysis
- [QUICK-REFERENCE.md](../QUICK-REFERENCE.md) - Cheat sheet

---

**Last Updated:** 2025-12-23
**Next Review:** 2026-01-20 (after Phase 2 implementation)
