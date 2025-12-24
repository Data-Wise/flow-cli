# Architecture Quick Reference Card

## ZSH Configuration System

**Version:** 1.0 | **Date:** 2025-12-21 | **Print-friendly:** Yes

---

## 🎯 The Big Picture (30-Second Version)

```
Clean Architecture = Concentric Circles
┌─────────────────────────────────────┐
│  Frameworks (Shell, Node, Vendor)   │  ← Outer (details)
│  ┌───────────────────────────────┐  │
│  │  Adapters (Controllers, Repos) │ │  ← Interface
│  │  ┌─────────────────────────┐  │  │
│  │  │  Use Cases (App Logic)  │  │  │  ← Orchestration
│  │  │  ┌───────────────────┐  │  │  │
│  │  │  │  Domain (Entities)│  │  │  │  ← Core (business rules)
│  │  │  └───────────────────┘  │  │  │
│  │  └─────────────────────────┘  │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘

Dependencies flow INWARD only ➡️
Inner layers NEVER import outer layers
```

**Golden Rule:** Domain knows nothing about databases, UI, or frameworks!

---

## 📊 The Four Layers

### Layer 1: Domain (Innermost - Pure Business Logic)

**What:** Entities, Value Objects, Business Rules

**Dependencies:** ZERO (no imports from outer layers)

**Examples:**

- `Session` entity (has ID, behavior, validation)
- `ProjectType` value object (immutable, no identity)
- `SessionValidator` domain service

**File Location:** `cli/domain/`

**Key Principle:** If you deleted Node.js tomorrow, this code would still work

---

### Layer 2: Use Cases (Application Logic)

**What:** Orchestrate domain objects, implement app workflows

**Dependencies:** Domain layer only (+ interfaces)

**Examples:**

- `CreateSessionUseCase` - starts a work session
- `ScanProjectsUseCase` - finds projects
- `GenerateDashboardUseCase` - builds dashboard data

**File Location:** `cli/use-cases/`

**Pattern:**

```javascript
class CreateSessionUseCase {
  constructor(sessionRepo, projectRepo) {} // Inject dependencies
  execute(request) {} // One public method
}
```

---

### Layer 3: Adapters (Interface Layer)

**What:** Implement domain interfaces, translate between layers

**Dependencies:** Use Cases + Domain (implements their interfaces)

**Types:**

- **Controllers** - Handle input (CLI, API requests)
- **Presenters** - Format output (JSON, Terminal)
- **Gateways/Repositories** - Access external systems (files, git)

**File Location:** `cli/adapters/`

**Examples:**

- `SessionController` - handles CLI commands
- `FileSystemSessionRepository` - saves sessions to disk
- `ProjectDetectorGateway` - wraps vendored scripts

---

### Layer 4: Frameworks & Drivers (Outermost - External Tools)

**What:** ZSH, Node.js, vendored scripts, UI, databases

**Dependencies:** Everything (top of dependency chain)

**Components:**

- ZSH shell interface (`work`, `finish` commands)
- Node.js runtime
- Vendored shell scripts
- External tools (git, fzf)

**File Location:** `cli/frameworks/`, `zsh/`, `cli/vendor/`

---

## 🔌 Ports & Adapters (Hexagonal Architecture)

**Port** = Interface (what we need)
**Adapter** = Implementation (how we get it)

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
                             │ - findById() → array.find│
                             └──────────────────────────┘
```

**Benefit:** Swap implementations without changing domain!

---

## 📝 Domain-Driven Design (DDD) Components

### Entities (Have Identity)

- **Session** - work session with unique ID
- **Project** - codebase with unique path
- **Task** - todo item with unique ID

**Characteristics:**

- Has ID (can track over time)
- Has behavior (methods that enforce rules)
- Mutable state (changes over time)

### Value Objects (No Identity)

- **ProjectType** (`'r-package'`, `'quarto'`, etc.)
- **SessionState** (`ACTIVE`, `PAUSED`, `ENDED`)
- **TaskPriority** (`HIGH`, `MEDIUM`, `LOW`)

**Characteristics:**

- No ID (two with same value are identical)
- Immutable (never changes after creation)
- Compared by value, not reference

### Repository Interfaces

- **ISessionRepository** - session persistence
- **IProjectRepository** - project storage
- **ITaskRepository** - task management

**Characteristics:**

- Defined in domain layer
- Implemented in adapters layer
- Hides persistence details from domain

---

## 🚦 The Dependency Rule (MOST IMPORTANT!)

```
✅ ALLOWED:
Domain    ← Use Cases      (inner ← outer: OK!)
Use Cases ← Adapters       (inner ← outer: OK!)
Adapters  ← Frameworks     (inner ← outer: OK!)

❌ FORBIDDEN:
Domain    → Use Cases      (inner → outer: NEVER!)
Domain    → Adapters       (inner → outer: NEVER!)
Use Cases → Adapters       (inner → outer: NEVER!)
```

**How to fix violations:**

- Inner layer defines interface (Port)
- Outer layer implements it (Adapter)
- Inject implementation at runtime (Dependency Injection)

---

## 🛠️ Common Patterns

### 1. Creating a New Feature

**Step 1:** Define domain entity/value object

```javascript
// cli/domain/entities/Task.js
export class Task {}
```

**Step 2:** Define repository interface

```javascript
// cli/domain/repositories/ITaskRepository.js
export class ITaskRepository {
  save(task) {
    throw new Error('Not implemented')
  }
}
```

**Step 3:** Create use case

```javascript
// cli/use-cases/CreateTaskUseCase.js
export class CreateTaskUseCase {
  constructor(taskRepo) {
    this.taskRepo = taskRepo
  }
  execute(request) {
    /* ... */
  }
}
```

**Step 4:** Implement repository

```javascript
// cli/adapters/repositories/FileSystemTaskRepository.js
export class FileSystemTaskRepository extends ITaskRepository {
  save(task) {
    /* write to file */
  }
}
```

**Step 5:** Wire it up

```javascript
// cli/frameworks/di-container.js
const taskRepo = new FileSystemTaskRepository()
const createTask = new CreateTaskUseCase(taskRepo)
```

---

### 2. Testing Strategy

```
Domain Tests:
  ✓ No mocks needed (pure logic)
  ✓ Fast (milliseconds)
  ✓ Test business rules

Use Case Tests:
  ✓ Mock repositories (use in-memory)
  ✓ Test workflows
  ✓ Verify domain is used correctly

Adapter Tests:
  ✓ Test real implementations
  ✓ Integration tests
  ✓ Can be slower

Framework Tests:
  ✓ E2E tests
  ✓ Test full stack
  ✓ Slowest but most realistic
```

---

## 📁 Directory Structure (At A Glance)

```
cli/
├── domain/                    # Layer 1 (inner)
│   ├── entities/
│   │   ├── Session.js
│   │   ├── Project.js
│   │   └── Task.js
│   ├── value-objects/
│   │   ├── ProjectType.js
│   │   └── SessionState.js
│   └── repositories/          # Interfaces (Ports)
│       ├── ISessionRepository.js
│       └── IProjectRepository.js
│
├── use-cases/                 # Layer 2
│   ├── CreateSessionUseCase.js
│   ├── EndSessionUseCase.js
│   └── ScanProjectsUseCase.js
│
├── adapters/                  # Layer 3
│   ├── controllers/
│   │   └── SessionController.js
│   ├── presenters/
│   │   └── TerminalPresenter.js
│   └── repositories/          # Implementations (Adapters)
│       └── FileSystemSessionRepository.js
│
└── frameworks/                # Layer 4 (outer)
    ├── cli/
    │   └── index.js
    └── di-container.js
```

---

## 🎓 When to Use Each Layer

### Add to Domain when:

- ✅ It's a core business rule
- ✅ It would exist even if we changed tech stack
- ✅ It needs validation or behavior

### Add to Use Cases when:

- ✅ It's workflow logic (A then B then C)
- ✅ It coordinates multiple entities
- ✅ It's app-specific (not universal business rule)

### Add to Adapters when:

- ✅ It talks to external systems
- ✅ It implements a domain interface
- ✅ It transforms data between layers

### Add to Frameworks when:

- ✅ It's framework-specific code
- ✅ It's vendor integration
- ✅ It's infrastructure (CLI, servers)

---

## ⚠️ Common Mistakes

### ❌ Domain imports Node.js modules

```javascript
// cli/domain/entities/Session.js
import fs from 'fs' // ❌ WRONG! Domain can't import frameworks
```

**Fix:** Move file operations to repository adapter

### ❌ Use Case returns database objects

```javascript
// cli/use-cases/GetSessionUseCase.js
execute() {
  return this.db.query('SELECT * FROM sessions');  // ❌ Returns DB object
}
```

**Fix:** Return domain entities, not database records

### ❌ Controller has business logic

```javascript
// cli/adapters/controllers/SessionController.js
start(req) {
  if (req.project.length < 3) {  // ❌ Business rule in controller
    throw new Error('Invalid');
  }
}
```

**Fix:** Move validation to domain entity or use case

---

## 🚀 Quick Wins

### Start Here (5 minutes):

1. Read this card
2. Look at [ARCHITECTURE-PATTERNS-ANALYSIS.md](ARCHITECTURE-PATTERNS-ANALYSIS.md)
3. Sketch the 4 layers for your next feature

### Next Steps (30 minutes):

1. Create one domain entity
2. Create one use case that uses it
3. Test the use case (no frameworks!)

### Advanced (2 hours):

1. Implement repository interface
2. Wire up dependency injection
3. Connect to CLI/API

---

## 📚 Further Reading

**Essential Docs:**

- [ARCHITECTURE-PATTERNS-ANALYSIS.md](ARCHITECTURE-PATTERNS-ANALYSIS.md) - Full analysis
- [API-DESIGN-REVIEW.md](API-DESIGN-REVIEW.md) - API patterns
- [VENDOR-INTEGRATION-ARCHITECTURE.md](VENDOR-INTEGRATION-ARCHITECTURE.md) - Vendoring strategy

**External Resources:**

- Clean Architecture (Uncle Bob) - Book
- Hexagonal Architecture (Alistair Cockburn) - Pattern
- Domain-Driven Design (Eric Evans) - Book

---

## 🎯 Remember

**The Goal:** Delay decisions about frameworks as long as possible

**The Benefit:** Easy to test, easy to change, easy to understand

**The Cost:** More files, more interfaces (but worth it!)

---

**Generated:** 2025-12-21
**Part of:** Documentation Sprint (Week 1)
**Next:** Print this card and keep it at your desk! 📌
