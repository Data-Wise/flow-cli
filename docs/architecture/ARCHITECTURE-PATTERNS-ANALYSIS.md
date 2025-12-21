# Architecture Patterns Analysis - ZSH Configuration

**Date:** 2025-12-20
**Analysis:** Applying Clean Architecture, Hexagonal Architecture, and DDD principles
**Current State:** Week 1 Complete, Planning Week 2+

---

## Executive Summary

The zsh-configuration system currently uses a **three-layer architecture** that partially aligns with Clean Architecture and Hexagonal Architecture principles. This analysis identifies where the system already follows best practices and where architectural patterns can improve maintainability, testability, and extensibility.

**Assessment:** 🟡 **Moderate Alignment** - Good foundation with clear improvement path

**Strengths:**
- ✅ Clear separation of concerns (Frontend → Backend → Vendor)
- ✅ Dependency inversion in project-detector-bridge
- ✅ Interface-based design (adapters pattern)

**Opportunities:**
- 🔧 Apply Clean Architecture layers more explicitly
- 🔧 Implement Ports & Adapters for all integrations
- 🔧 Use Domain-Driven Design for session/project models
- 🔧 Separate use cases from API controllers

---

## Current Architecture Analysis

### Existing Three-Layer Structure

```
┌─────────────────────────────────────────────────────────┐
│ FRONTEND LAYER (ZSH Shell)                              │
│ - User commands (work, finish, dashboard, pp)           │
│ - Interactive prompts, fzf integration                  │
│ - Terminal UI (colored output, tables)                  │
└──────────────────┬──────────────────────────────────────┘
                   │ exec(), JSON communication
┌──────────────────▼──────────────────────────────────────┐
│ BACKEND LAYER (Node.js Core)                            │
│ - Session state manager                                 │
│ - Project scanner (uses zsh-claude-workflow)            │
│ - Dependency tracker                                    │
│ - Dashboard generator (adapts apple-notes-sync)         │
│ - Task aggregator                                       │
└──────────────────┬──────────────────────────────────────┘
                   │ shell exec
┌──────────────────▼──────────────────────────────────────┐
│ VENDOR LAYER (Shell Scripts)                            │
│ - Vendored zsh-claude-workflow functions (~300 lines)   │
│ - Optional aiterm integration (if installed)            │
│ - Adapted apple-notes-sync patterns                     │
└─────────────────────────────────────────────────────────┘
```

**This maps to:**
- Frontend Layer ≈ **Controllers/Presenters** (Outer Layer)
- Backend Layer ≈ **Use Cases** (mixed with some domain logic)
- Vendor Layer ≈ **Infrastructure/Frameworks** (Outer Layer)

**Issues:**
- Backend layer mixes use cases with infrastructure
- No explicit domain layer for business rules
- Controllers (Frontend) too tightly coupled to use cases

---

## Recommended Clean Architecture Mapping

### Four-Layer Design

```
┌─────────────────────────────────────────────────────────┐
│ LAYER 4: FRAMEWORKS & DRIVERS (Outer)                   │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ - ZSH Shell Interface (Frontend)                    │ │
│ │ - CLI commands (work, finish, pp)                   │ │
│ │ - Terminal UI rendering                             │ │
│ │                                                       │ │
│ │ - Vendor Layer (Shell Scripts)                      │ │
│ │ - project-detector.sh, core.sh                      │ │
│ │ - External tool integrations                        │ │
│ └─────────────────────────────────────────────────────┘ │
└──────────────────┬──────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────┐
│ LAYER 3: INTERFACE ADAPTERS (Controllers/Gateways)      │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ Controllers:                                         │ │
│ │ - SessionController, ProjectController              │ │
│ │ - DashboardController                               │ │
│ │                                                       │ │
│ │ Gateways (Adapters to external systems):            │ │
│ │ - ProjectDetectorGateway (wraps vendored scripts)   │ │
│ │ - FileSystemGateway (reads .STATUS, .worklog)       │ │
│ │ - GitGateway (git operations)                       │ │
│ │                                                       │ │
│ │ Presenters:                                          │ │
│ │ - JSONPresenter, TerminalPresenter                  │ │
│ └─────────────────────────────────────────────────────┘ │
└──────────────────┬──────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────┐
│ LAYER 2: USE CASES (Application Business Rules)         │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ - CreateSessionUseCase                              │ │
│ │ - EndSessionUseCase                                 │ │
│ │ - ScanProjectsUseCase                               │ │
│ │ - GenerateDashboardUseCase                          │ │
│ │ - AggregateTasksUseCase                             │ │
│ │ - TrackDependenciesUseCase                          │ │
│ └─────────────────────────────────────────────────────┘ │
└──────────────────┬──────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────┐
│ LAYER 1: DOMAIN (Enterprise Business Rules)             │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ Entities:                                            │ │
│ │ - Session, Project, Task                            │ │
│ │                                                       │ │
│ │ Value Objects:                                       │ │
│ │ - ProjectType, TaskPriority, SessionState           │ │
│ │                                                       │ │
│ │ Domain Services:                                     │ │
│ │ - SessionValidator, ProjectOrganizer                │ │
│ │                                                       │ │
│ │ Repository Interfaces (Ports):                       │ │
│ │ - ISessionRepository, IProjectRepository            │ │
│ └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

---

## Domain Layer Design (DDD)

### 1. Entities (with Identity)

```javascript
// cli/domain/entities/Session.js

export class Session {
  constructor(id, project, options = {}) {
    this.id = id;
    this.project = project;
    this.task = options.task || 'Work session';
    this.branch = options.branch || 'main';
    this.startTime = new Date();
    this.endTime = null;
    this.state = SessionState.ACTIVE;
    this.context = options.context || {};
    this._events = [];
  }

  /**
   * Business rule: Can only end active sessions
   */
  end(outcome = 'completed') {
    if (this.state !== SessionState.ACTIVE) {
      throw new Error('Can only end active sessions');
    }

    this.endTime = new Date();
    this.state = SessionState.ENDED;
    this.outcome = outcome;

    // Domain event
    this._events.push(new SessionEndedEvent(this.id, outcome));
  }

  /**
   * Business rule: Duration must be positive
   */
  getDuration() {
    const end = this.endTime || new Date();
    const duration = end - this.startTime;

    if (duration < 0) {
      throw new Error('Invalid session duration');
    }

    return Math.floor(duration / 60000); // minutes
  }

  /**
   * Business rule: Session is in flow state after 15 minutes
   */
  isInFlowState() {
    return this.state === SessionState.ACTIVE && this.getDuration() >= 15;
  }

  /**
   * Update context (preserves immutability of core properties)
   */
  updateContext(updates) {
    this.context = { ...this.context, ...updates };
    this._events.push(new SessionUpdatedEvent(this.id, updates));
  }

  /**
   * Get pending domain events
   */
  getEvents() {
    return [...this._events];
  }

  /**
   * Clear events after publishing
   */
  clearEvents() {
    this._events = [];
  }
}
```

```javascript
// cli/domain/entities/Project.js

export class Project {
  constructor(id, name, path, type) {
    this.id = id;
    this.name = name;
    this.path = path;
    this.type = type;
    this.status = null;
    this.metadata = {};
    this.lastAccessed = null;
  }

  /**
   * Business rule: Update last accessed time
   */
  recordAccess() {
    this.lastAccessed = new Date();
  }

  /**
   * Business rule: Project is active if status indicates so
   */
  isActive() {
    return this.status?.currentStatus === 'active';
  }

  /**
   * Business rule: Has quick wins if tasks exist
   */
  hasQuickWins() {
    return this.status?.nextActions?.some(a => a.status === '⚡') || false;
  }

  /**
   * Update status from .STATUS file
   */
  updateStatus(statusData) {
    this.status = statusData;
  }
}
```

### 2. Value Objects (Immutable)

```javascript
// cli/domain/value-objects/ProjectType.js

export class ProjectType {
  static R_PACKAGE = 'r-package';
  static QUARTO = 'quarto';
  static QUARTO_EXTENSION = 'quarto-extension';
  static RESEARCH = 'research';
  static GENERIC = 'generic';
  static UNKNOWN = 'unknown';

  static ALL = [
    ProjectType.R_PACKAGE,
    ProjectType.QUARTO,
    ProjectType.QUARTO_EXTENSION,
    ProjectType.RESEARCH,
    ProjectType.GENERIC,
    ProjectType.UNKNOWN
  ];

  constructor(value) {
    if (!ProjectType.ALL.includes(value)) {
      throw new Error(`Invalid project type: ${value}`);
    }
    this._value = value;
    Object.freeze(this);
  }

  get value() {
    return this._value;
  }

  equals(other) {
    return other instanceof ProjectType && this._value === other._value;
  }

  toString() {
    return this._value;
  }

  isResearch() {
    return this._value === ProjectType.RESEARCH;
  }

  isRPackage() {
    return this._value === ProjectType.R_PACKAGE;
  }

  isQuarto() {
    return [ProjectType.QUARTO, ProjectType.QUARTO_EXTENSION].includes(this._value);
  }
}
```

```javascript
// cli/domain/value-objects/SessionState.js

export class SessionState {
  static ACTIVE = 'active';
  static PAUSED = 'paused';
  static ENDED = 'ended';

  constructor(value) {
    if (![SessionState.ACTIVE, SessionState.PAUSED, SessionState.ENDED].includes(value)) {
      throw new Error(`Invalid session state: ${value}`);
    }
    this._value = value;
    Object.freeze(this);
  }

  get value() {
    return this._value;
  }

  isActive() {
    return this._value === SessionState.ACTIVE;
  }

  canTransitionTo(newState) {
    const validTransitions = {
      [SessionState.ACTIVE]: [SessionState.PAUSED, SessionState.ENDED],
      [SessionState.PAUSED]: [SessionState.ACTIVE, SessionState.ENDED],
      [SessionState.ENDED]: []
    };

    return validTransitions[this._value]?.includes(newState) || false;
  }
}
```

### 3. Repository Interfaces (Ports)

```javascript
// cli/domain/repositories/ISessionRepository.js

/**
 * Port: Session repository interface
 * No implementation details, just contract
 */
export class ISessionRepository {
  /**
   * Find session by ID
   * @param {string} sessionId
   * @returns {Promise<Session|null>}
   */
  async findById(sessionId) {
    throw new Error('Not implemented');
  }

  /**
   * Find active session
   * @returns {Promise<Session|null>}
   */
  async findActive() {
    throw new Error('Not implemented');
  }

  /**
   * Find sessions by project
   * @param {string} projectName
   * @returns {Promise<Session[]>}
   */
  async findByProject(projectName) {
    throw new Error('Not implemented');
  }

  /**
   * Save session
   * @param {Session} session
   * @returns {Promise<Session>}
   */
  async save(session) {
    throw new Error('Not implemented');
  }

  /**
   * Delete session
   * @param {string} sessionId
   * @returns {Promise<boolean>}
   */
  async delete(sessionId) {
    throw new Error('Not implemented');
  }

  /**
   * List all sessions with filters
   * @param {Object} filters
   * @returns {Promise<Session[]>}
   */
  async list(filters = {}) {
    throw new Error('Not implemented');
  }
}
```

```javascript
// cli/domain/repositories/IProjectRepository.js

export class IProjectRepository {
  async findById(projectId) {
    throw new Error('Not implemented');
  }

  async findByPath(path) {
    throw new Error('Not implemented');
  }

  async findByType(type) {
    throw new Error('Not implemented');
  }

  async save(project) {
    throw new Error('Not implemented');
  }

  async list(filters = {}) {
    throw new Error('Not implemented');
  }
}
```

---

## Use Cases Layer

### Example: CreateSessionUseCase

```javascript
// cli/use-cases/CreateSessionUseCase.js

import { Session } from '../domain/entities/Session.js';
import { SessionState } from '../domain/value-objects/SessionState.js';

export class CreateSessionUseCase {
  constructor(sessionRepository, projectRepository, eventPublisher) {
    this.sessionRepository = sessionRepository;
    this.projectRepository = projectRepository;
    this.eventPublisher = eventPublisher;
  }

  /**
   * Execute use case
   * @param {Object} request
   * @param {string} request.project - Project name
   * @param {string} request.task - Task description
   * @param {string} request.branch - Git branch
   * @param {Object} request.context - Additional context
   * @returns {Promise<CreateSessionResult>}
   */
  async execute(request) {
    // Validate: Only one active session allowed
    const activeSession = await this.sessionRepository.findActive();
    if (activeSession) {
      return {
        success: false,
        error: `Session already active for project: ${activeSession.project}`,
        existingSession: activeSession
      };
    }

    // Validate: Project should exist (optional check)
    const project = await this.projectRepository.findByPath(request.projectPath);
    if (project) {
      project.recordAccess();
      await this.projectRepository.save(project);
    }

    // Create domain entity
    const session = new Session(
      this.generateId(),
      request.project,
      {
        task: request.task,
        branch: request.branch,
        context: request.context
      }
    );

    // Persist
    const savedSession = await this.sessionRepository.save(session);

    // Publish domain events
    for (const event of session.getEvents()) {
      await this.eventPublisher.publish(event);
    }
    session.clearEvents();

    return {
      success: true,
      session: savedSession
    };
  }

  generateId() {
    return `session-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }
}
```

### Example: ScanProjectsUseCase

```javascript
// cli/use-cases/ScanProjectsUseCase.js

import { Project } from '../domain/entities/Project.js';
import { ProjectType } from '../domain/value-objects/ProjectType.js';

export class ScanProjectsUseCase {
  constructor(
    projectRepository,
    projectDetectorGateway,
    fileSystemGateway
  ) {
    this.projectRepository = projectRepository;
    this.projectDetector = projectDetectorGateway;
    this.fileSystem = fileSystemGateway;
  }

  /**
   * Scan directories for projects
   * @param {Object} request
   * @param {string} request.basePath - Directory to scan
   * @param {number} request.maxDepth - Max recursion depth
   * @param {string[]} request.types - Filter by types
   * @returns {Promise<ScanResult>}
   */
  async execute(request) {
    const {
      basePath,
      maxDepth = 3,
      types = []
    } = request;

    // Find all potential project directories
    const directories = await this.fileSystem.findDirectories(basePath, {
      maxDepth,
      excludeHidden: true
    });

    // Detect types in parallel
    const detections = await this.projectDetector.detectMultiple(directories);

    // Create domain entities
    const projects = [];
    for (const [path, typeStr] of Object.entries(detections)) {
      // Filter by type if specified
      if (types.length > 0 && !types.includes(typeStr)) {
        continue;
      }

      const projectType = new ProjectType(typeStr);

      // Create Project entity
      const project = new Project(
        this.generateId(path),
        this.extractName(path),
        path,
        projectType
      );

      // Load metadata
      const metadata = await this.fileSystem.extractMetadata(path, projectType);
      project.metadata = metadata;

      // Load status if exists
      const status = await this.fileSystem.readStatus(path);
      if (status) {
        project.updateStatus(status);
      }

      projects.push(project);

      // Save to repository
      await this.projectRepository.save(project);
    }

    return {
      success: true,
      projects,
      count: projects.length
    };
  }

  generateId(path) {
    return `project-${path.split('/').pop()}`;
  }

  extractName(path) {
    return path.split('/').pop();
  }
}
```

---

## Adapters Layer (Hexagonal Architecture)

### Adapters (Implementations of Ports)

```javascript
// cli/adapters/repositories/FileSystemSessionRepository.js

import { ISessionRepository } from '../../domain/repositories/ISessionRepository.js';
import { Session } from '../../domain/entities/Session.js';
import { readFile, writeFile, readdir } from 'fs/promises';
import { join } from 'path';

/**
 * Adapter: File system implementation of session repository
 */
export class FileSystemSessionRepository extends ISessionRepository {
  constructor(storageDir) {
    super();
    this.storageDir = storageDir;
  }

  async findById(sessionId) {
    try {
      const filePath = join(this.storageDir, `${sessionId}.json`);
      const content = await readFile(filePath, 'utf-8');
      return this.toEntity(JSON.parse(content));
    } catch (error) {
      if (error.code === 'ENOENT') return null;
      throw error;
    }
  }

  async findActive() {
    const all = await this.list({ state: 'active' });
    return all[0] || null;
  }

  async findByProject(projectName) {
    const all = await this.list();
    return all.filter(s => s.project === projectName);
  }

  async save(session) {
    const filePath = join(this.storageDir, `${session.id}.json`);
    const data = this.toJSON(session);
    await writeFile(filePath, JSON.stringify(data, null, 2));
    return session;
  }

  async delete(sessionId) {
    try {
      const filePath = join(this.storageDir, `${sessionId}.json`);
      await unlink(filePath);
      return true;
    } catch (error) {
      if (error.code === 'ENOENT') return false;
      throw error;
    }
  }

  async list(filters = {}) {
    const files = await readdir(this.storageDir);
    const sessions = [];

    for (const file of files) {
      if (!file.endsWith('.json')) continue;

      const session = await this.findById(file.replace('.json', ''));
      if (session && this.matchesFilters(session, filters)) {
        sessions.push(session);
      }
    }

    return sessions;
  }

  /**
   * Map JSON to domain entity
   */
  toEntity(json) {
    const session = new Session(json.id, json.project, {
      task: json.task,
      branch: json.branch,
      context: json.context
    });

    session.startTime = new Date(json.startTime);
    if (json.endTime) {
      session.endTime = new Date(json.endTime);
    }
    session.state = json.state;
    session.outcome = json.outcome;

    return session;
  }

  /**
   * Map entity to JSON
   */
  toJSON(session) {
    return {
      id: session.id,
      project: session.project,
      task: session.task,
      branch: session.branch,
      context: session.context,
      startTime: session.startTime.toISOString(),
      endTime: session.endTime?.toISOString() || null,
      state: session.state,
      outcome: session.outcome
    };
  }

  matchesFilters(session, filters) {
    if (filters.state && session.state !== filters.state) return false;
    if (filters.project && session.project !== filters.project) return false;
    if (filters.since && session.startTime < new Date(filters.since)) return false;
    return true;
  }
}
```

```javascript
// cli/adapters/gateways/ProjectDetectorGateway.js

import { detectProjectType, detectMultipleProjects } from '../../lib/project-detector-bridge.js';

/**
 * Gateway: Wraps vendored project detector
 * Adapts external dependency to our domain interface
 */
export class ProjectDetectorGateway {
  /**
   * Detect single project type
   * @param {string} projectPath
   * @returns {Promise<string>}
   */
  async detect(projectPath) {
    return await detectProjectType(projectPath);
  }

  /**
   * Detect multiple projects in parallel
   * @param {string[]} projectPaths
   * @returns {Promise<Object>}
   */
  async detectMultiple(projectPaths) {
    return await detectMultipleProjects(projectPaths);
  }
}
```

---

## Controllers Layer

```javascript
// cli/adapters/controllers/SessionController.js

import { CreateSessionUseCase } from '../../use-cases/CreateSessionUseCase.js';
import { EndSessionUseCase } from '../../use-cases/EndSessionUseCase.js';

/**
 * Controller: Handles command-line interface concerns
 * Delegates business logic to use cases
 */
export class SessionController {
  constructor(
    createSessionUseCase,
    endSessionUseCase,
    getSessionUseCase
  ) {
    this.createSession = createSessionUseCase;
    this.endSession = endSessionUseCase;
    this.getSession = getSessionUseCase;
  }

  /**
   * Handle 'work <project>' command
   */
  async handleStartCommand(args) {
    const [project, ...taskParts] = args;
    const task = taskParts.join(' ') || 'Work session';

    const result = await this.createSession.execute({
      project,
      task,
      branch: await this.getCurrentBranch(),
      context: {
        cwd: process.cwd(),
        timestamp: new Date().toISOString()
      }
    });

    if (!result.success) {
      console.error(`❌ ${result.error}`);
      return 1;
    }

    console.log(`✅ Started session for ${project}`);
    console.log(`   Task: ${task}`);
    console.log(`   Branch: ${result.session.branch}`);

    return 0;
  }

  /**
   * Handle 'finish' command
   */
  async handleFinishCommand(args) {
    const message = args.join(' ') || 'Completed work session';

    const result = await this.endSession.execute({
      outcome: 'completed',
      summary: message
    });

    if (!result.success) {
      console.error(`❌ ${result.error}`);
      return 1;
    }

    const duration = result.session.getDuration();
    console.log(`✅ Ended session: ${result.session.project}`);
    console.log(`   Duration: ${duration} minutes`);
    console.log(`   Summary: ${message}`);

    return 0;
  }

  async getCurrentBranch() {
    // Git integration
    return 'main';
  }
}
```

---

## Directory Structure (Recommended)

```
cli/
├── domain/                          # LAYER 1: Domain (core business)
│   ├── entities/
│   │   ├── Session.js
│   │   ├── Project.js
│   │   └── Task.js
│   ├── value-objects/
│   │   ├── ProjectType.js
│   │   ├── SessionState.js
│   │   └── TaskPriority.js
│   ├── services/
│   │   └── SessionValidator.js
│   └── repositories/               # Interfaces (Ports)
│       ├── ISessionRepository.js
│       ├── IProjectRepository.js
│       └── ITaskRepository.js
│
├── use-cases/                       # LAYER 2: Use Cases
│   ├── session/
│   │   ├── CreateSessionUseCase.js
│   │   ├── EndSessionUseCase.js
│   │   └── GetActiveSessionUseCase.js
│   ├── project/
│   │   ├── ScanProjectsUseCase.js
│   │   └── FindProjectUseCase.js
│   └── dashboard/
│       └── GenerateDashboardUseCase.js
│
├── adapters/                        # LAYER 3: Interface Adapters
│   ├── repositories/                # Repository implementations
│   │   ├── FileSystemSessionRepository.js
│   │   ├── CachedProjectRepository.js
│   │   └── InMemorySessionRepository.js  # For testing
│   ├── gateways/                    # External service adapters
│   │   ├── ProjectDetectorGateway.js
│   │   ├── FileSystemGateway.js
│   │   └── GitGateway.js
│   ├── controllers/                 # CLI controllers
│   │   ├── SessionController.js
│   │   ├── ProjectController.js
│   │   └── DashboardController.js
│   └── presenters/
│       ├── JSONPresenter.js
│       └── TerminalPresenter.js
│
├── infrastructure/                  # LAYER 4: Frameworks & Drivers
│   ├── config/
│   │   └── paths.js
│   ├── events/
│   │   └── EventPublisher.js
│   └── logging/
│       └── Logger.js
│
├── lib/                             # Existing bridges (will migrate)
│   └── project-detector-bridge.js   # → becomes ProjectDetectorGateway
│
├── vendor/                          # External dependencies
│   └── zsh-claude-workflow/
│       ├── project-detector.sh
│       └── core.sh
│
└── test/
    ├── unit/
    │   ├── entities/
    │   ├── use-cases/
    │   └── value-objects/
    └── integration/
        └── repositories/
```

---

## Benefits of This Architecture

### 1. Testability

**Before (current):**
```javascript
// Hard to test - tightly coupled to file system
async function createSession(project) {
  const worklogPath = path.join(os.homedir(), '.config/zsh/.worklog');
  await fs.writeFile(worklogPath, JSON.stringify({ project }));
}
```

**After (Clean Architecture):**
```javascript
// Easy to test - inject mock repository
const useCase = new CreateSessionUseCase(mockRepository);
const result = await useCase.execute({ project: 'test' });
```

### 2. Flexibility

**Swap implementations without changing business logic:**
```javascript
// Development: In-memory repository
const repo = new InMemorySessionRepository();

// Production: File system repository
const repo = new FileSystemSessionRepository('/path/to/sessions');

// Future: Database repository
const repo = new PostgresSessionRepository(dbPool);

// Use case doesn't care which implementation
const useCase = new CreateSessionUseCase(repo);
```

### 3. Domain-Driven Design

**Business rules in entities:**
```javascript
// Business logic in domain, not scattered in use cases
const session = new Session(id, project);

if (!session.canEnd()) {
  throw new Error('Cannot end inactive session');
}

session.end('completed');
```

### 4. Dependency Inversion

**Dependencies point inward:**
```
Use Case (inner) depends on IRepository (interface)
Repository (outer) implements IRepository
```

**NOT:**
```
Use Case (inner) depends on FileSystemRepository (concrete)
```

---

## Implementation Roadmap

### Phase 1: Foundation (Week 2)

1. **Create Domain Layer**
   - Session entity
   - Project entity
   - Value objects (ProjectType, SessionState)
   - Repository interfaces

2. **Create Use Cases**
   - CreateSessionUseCase
   - EndSessionUseCase
   - ScanProjectsUseCase

3. **Create Adapters**
   - FileSystemSessionRepository
   - ProjectDetectorGateway

### Phase 2: Migration (Week 3)

4. **Migrate Existing Code**
   - Move project-detector-bridge → ProjectDetectorGateway
   - Move status-api → Use cases + Domain
   - Move workflow-api → Use cases + Controllers

5. **Add Controllers**
   - SessionController
   - ProjectController

### Phase 3: Enhancement (Week 4)

6. **Add Advanced Features**
   - Event publishing
   - Plugin system using ports
   - Multiple repository implementations

---

## Testing Strategy

### Unit Tests (Domain)

```javascript
// test/unit/entities/Session.test.js

import { Session } from '../../../domain/entities/Session.js';
import { SessionState } from '../../../domain/value-objects/SessionState.js';

describe('Session Entity', () => {
  test('creates active session', () => {
    const session = new Session('id-1', 'rmediation');

    expect(session.id).toBe('id-1');
    expect(session.project).toBe('rmediation');
    expect(session.state).toBe(SessionState.ACTIVE);
  });

  test('cannot end inactive session', () => {
    const session = new Session('id-1', 'project');
    session.end();

    expect(() => session.end()).toThrow('Can only end active sessions');
  });

  test('calculates duration correctly', () => {
    const session = new Session('id-1', 'project');

    // Simulate 30 minutes passing
    session.startTime = new Date(Date.now() - 30 * 60 * 1000);

    const duration = session.getDuration();
    expect(duration).toBeGreaterThanOrEqual(30);
  });

  test('detects flow state after 15 minutes', () => {
    const session = new Session('id-1', 'project');

    expect(session.isInFlowState()).toBe(false);

    // Simulate 20 minutes passing
    session.startTime = new Date(Date.now() - 20 * 60 * 1000);

    expect(session.isInFlowState()).toBe(true);
  });
});
```

### Integration Tests (Use Cases)

```javascript
// test/integration/use-cases/CreateSessionUseCase.test.js

import { CreateSessionUseCase } from '../../../use-cases/session/CreateSessionUseCase.js';
import { InMemorySessionRepository } from '../../../adapters/repositories/InMemorySessionRepository.js';

describe('CreateSessionUseCase', () => {
  let repository;
  let useCase;

  beforeEach(() => {
    repository = new InMemorySessionRepository();
    useCase = new CreateSessionUseCase(repository);
  });

  test('creates session successfully', async () => {
    const result = await useCase.execute({
      project: 'rmediation',
      task: 'Fix failing test'
    });

    expect(result.success).toBe(true);
    expect(result.session.project).toBe('rmediation');
  });

  test('prevents multiple active sessions', async () => {
    await useCase.execute({ project: 'project1' });

    const result = await useCase.execute({ project: 'project2' });

    expect(result.success).toBe(false);
    expect(result.error).toContain('already active');
  });
});
```

---

## Comparison: Before vs After

### Before (Current)

**Pros:**
- ✅ Simple and straightforward
- ✅ Easy to understand initially
- ✅ Fast to implement

**Cons:**
- ❌ Business logic scattered across layers
- ❌ Hard to test (file system dependencies)
- ❌ Difficult to swap implementations
- ❌ Controllers know too much about data access

### After (Clean Architecture)

**Pros:**
- ✅ Business logic centralized in domain
- ✅ Highly testable (dependency injection)
- ✅ Easy to swap implementations
- ✅ Clear separation of concerns
- ✅ Controllers are thin and focused

**Cons:**
- ⚠️ More files and boilerplate
- ⚠️ Steeper learning curve initially
- ⚠️ Requires discipline to maintain

**Verdict:** Worth it for a system that will grow and evolve over time.

---

## Conclusion

The zsh-configuration system has a **solid foundation** that can be enhanced with Clean Architecture and DDD principles. The recommended approach:

1. **Start with domain entities** (Session, Project) - capture business rules
2. **Define repository ports** - interfaces for data access
3. **Implement use cases** - orchestrate business logic
4. **Create adapters** - implement ports with concrete technologies
5. **Keep controllers thin** - delegate to use cases

**This architecture will make the system:**
- More testable (mock dependencies easily)
- More maintainable (clear boundaries)
- More flexible (swap implementations)
- More scalable (add features without breaking existing code)

**Next Step:** Implement Phase 1 (Domain Layer + Use Cases) in Week 2.

---

**Last Updated:** 2025-12-20
**Author:** Claude Code (architecture-patterns analysis)
**Status:** Recommended for Week 2 implementation
