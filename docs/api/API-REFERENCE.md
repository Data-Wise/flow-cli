# Flow CLI - Complete API Reference

**Version:** 2.0.0-beta.1
**Last Updated:** 2025-12-24
**Architecture:** Clean Architecture (4-Layer)

---

## Table of Contents

- [Overview](#overview)
- [Architecture Layers](#architecture-layers)
- [Domain Layer](#domain-layer)
  - [Entities](#entities)
  - [Value Objects](#value-objects)
  - [Domain Events](#domain-events)
  - [Repositories (Interfaces)](#repositories-interfaces)
- [Use Cases Layer](#use-cases-layer)
- [Adapters Layer](#adapters-layer)
  - [Controllers](#controllers)
  - [Repositories (Implementations)](#repositories-implementations)
  - [Gateways](#gateways)
- [Frameworks Layer](#frameworks-layer)
- [CLI Commands](#cli-commands)
- [Code Examples](#code-examples)

---

## Overview

Flow CLI provides a programmatic API for managing ADHD-optimized workflow sessions. The system follows Clean Architecture principles with clear separation of concerns across four layers.

**Key Features:**

- Session management (create, end, pause, resume)
- Project tracking with .STATUS file integration
- Productivity metrics and analytics
- Git integration
- Interactive TUI dashboard
- Web-based dashboard

**Design Principles:**

- Domain-driven design
- Dependency inversion
- Repository pattern
- Event sourcing (domain events)
- ADHD-friendly (< 10ms ZSH, ~100ms Node.js)

---

## Architecture Layers

```
┌─────────────────────────────────────────┐
│  Frameworks & Drivers (Outer Layer)    │  ← CLI, ZSH, Node.js
│  ┌───────────────────────────────────┐  │
│  │  Adapters (Interface Layer)       │  │  ← Controllers, Repos, Gateways
│  │  ┌─────────────────────────────┐  │  │
│  │  │  Use Cases (Application)    │  │  │  ← Business workflows
│  │  │  ┌───────────────────────┐  │  │  │
│  │  │  │  Domain (Core)        │  │  │  │  ← Entities, Value Objects
│  │  │  └───────────────────────┘  │  │  │
│  │  └─────────────────────────────┘  │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘

Dependencies flow INWARD ONLY (Dependency Rule)
```

**Dependency Rule:** Source code dependencies point ONLY inward. Inner layers know nothing about outer layers.

---

## Domain Layer

Pure business logic with zero dependencies on frameworks or infrastructure.

### Entities

Entities represent core business concepts with identity and behavior.

#### Session Entity

**File:** `cli/domain/entities/Session.js`

Represents a work session with identity, state, and business rules.

**Constructor:**

```javascript
new Session(id, project, options)
```

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | string | Yes | Unique session identifier (UUID) |
| `project` | string | Yes | Project name (max 100 chars) |
| `options.task` | string | No | Task description (max 500 chars) |
| `options.branch` | string | No | Git branch name (default: "main") |
| `options.startTime` | Date | No | Session start time (default: now) |
| `options.context` | Object | No | Additional metadata |
| `options._skipEvents` | boolean | No | Skip event emission (for testing) |

**Properties:**

```javascript
{
  id: string,              // Unique identifier
  project: string,         // Project name
  task: string,            // Task description
  branch: string,          // Git branch
  startTime: Date,         // When session started
  endTime: Date | null,    // When session ended
  pausedAt: Date | null,   // When session was paused
  resumedAt: Date | null,  // When session was resumed
  totalPausedTime: number, // Total pause duration (ms)
  state: SessionState,     // Current state (ACTIVE, PAUSED, ENDED)
  outcome: string | null,  // Session outcome
  context: Object          // Additional metadata
}
```

**Methods:**

##### `validate()`

Validates business rules for session data.

**Throws:**

- `Error` if project name is empty or > 100 characters
- `Error` if task description > 500 characters

**Example:**

```javascript
const session = new Session('uuid-123', 'flow-cli', {
  task: 'Implement status command'
})
session.validate() // Throws if invalid
```

##### `end(outcome)`

Ends an active session.

**Parameters:**

- `outcome` (string): One of `'completed'`, `'cancelled'`, `'interrupted'`

**Throws:**

- `Error` if session is already ended
- `Error` if outcome is invalid

**Side Effects:**

- Sets `endTime` to current time
- Changes `state` to `SessionState.ENDED`
- Sets `outcome`
- Emits `SessionEndedEvent`

**Example:**

```javascript
session.end('completed')
console.log(session.endTime) // Current timestamp
console.log(session.state.value) // 'ended'
```

##### `pause()`

Pauses an active session.

**Throws:**

- `Error` if session is not active

**Side Effects:**

- Sets `pausedAt` to current time
- Changes `state` to `SessionState.PAUSED`
- Emits `SessionPausedEvent`

**Example:**

```javascript
session.pause()
console.log(session.state.isPaused()) // true
```

##### `resume()`

Resumes a paused session.

**Throws:**

- `Error` if session is not paused

**Side Effects:**

- Adds pause duration to `totalPausedTime`
- Sets `resumedAt` to current time
- Clears `pausedAt`
- Changes `state` to `SessionState.ACTIVE`
- Emits `SessionResumedEvent`

**Example:**

```javascript
session.resume()
console.log(session.state.isActive()) // true
```

##### `getDuration(): number`

Gets session duration in minutes (excluding paused time).

**Returns:**

- `number` - Duration in minutes (active work time only)

**Example:**

```javascript
const duration = session.getDuration()
console.log(`${duration} minutes of active work`)
```

##### `isInFlowState(): boolean`

Checks if session is in flow state (≥ 15 minutes of active work).

**Returns:**

- `boolean` - True if active and duration ≥ 15 minutes

**Business Rule:** Flow state is achieved after 15 minutes of uninterrupted work.

**Example:**

```javascript
if (session.isInFlowState()) {
  console.log('🔥 IN FLOW STATE')
}
```

##### `updateContext(updates)`

Updates session metadata.

**Parameters:**

- `updates` (Object): Key-value pairs to merge into context

**Side Effects:**

- Merges `updates` into `context`
- Emits `SessionContextUpdatedEvent`

**Example:**

```javascript
session.updateContext({
  editor: 'vscode',
  filesChanged: 5
})
```

##### `getSummary(): Object`

Gets session summary for display.

**Returns:**

```javascript
{
  id: string,
  project: string,
  task: string,
  duration: number,        // Minutes
  state: string,
  outcome: string | null,
  isFlowState: boolean
}
```

**Example:**

```javascript
const summary = session.getSummary()
console.log(JSON.stringify(summary, null, 2))
```

##### `getEvents(): Array`

Gets pending domain events.

**Returns:**

- `Array<DomainEvent>` - Domain events emitted during session lifecycle

**Example:**

```javascript
const events = session.getEvents()
events.forEach(event => console.log(event.eventType))
// SessionStartedEvent
// SessionPausedEvent
// SessionResumedEvent
```

##### `clearEvents()`

Clears pending domain events (after publishing).

**Example:**

```javascript
session.clearEvents()
console.log(session.getEvents().length) // 0
```

---

#### Project Entity

**File:** `cli/domain/entities/Project.js`

Represents a project that can have sessions.

**Constructor:**

```javascript
new Project(id, name, options)
```

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | string | Yes | Unique identifier (usually directory path) |
| `name` | string | Yes | Project name (max 100 chars) |
| `options.type` | string\|ProjectType | No | Project type (default: "general") |
| `options.path` | string | No | File system path (default: id) |
| `options.description` | string | No | Description (max 500 chars) |
| `options.tags` | string[] | No | Tags array (default: []) |
| `options.metadata` | Object | No | Additional metadata |
| `options.totalSessions` | number | No | Total sessions count |
| `options.totalDuration` | number | No | Total duration (minutes) |

**Properties:**

```javascript
{
  id: string,              // Unique identifier
  name: string,            // Project name
  type: ProjectType,       // Project type (R, Quarto, Dev, etc)
  path: string,            // File system path
  description: string,     // Description
  tags: string[],          // Tags
  metadata: Object,        // Additional metadata
  createdAt: Date,         // Creation time
  lastAccessedAt: Date,    // Last access time
  totalSessions: number,   // Number of sessions
  totalDuration: number    // Total work time (minutes)
}
```

**Methods:**

##### `validate()`

Validates business rules.

**Throws:**

- `Error` if id or name is empty
- `Error` if name > 100 characters
- `Error` if description > 500 characters
- `Error` if tags is not an array of strings

##### `touch()`

Updates last accessed time to now.

##### `recordSession(duration)`

Records a completed session.

**Parameters:**

- `duration` (number): Session duration in minutes

**Throws:**

- `Error` if duration is negative

**Side Effects:**

- Increments `totalSessions`
- Adds to `totalDuration`
- Calls `touch()`

##### `getAverageSessionDuration(): number`

Gets average session duration.

**Returns:**

- `number` - Average duration in minutes (rounded)

##### `isRecentlyAccessed(hours): boolean`

Checks if project was accessed recently.

**Parameters:**

- `hours` (number): Hours to consider "recent" (default: 24)

**Returns:**

- `boolean` - True if last accessed within specified hours

##### `hasTag(tag): boolean`

Checks if project has a specific tag.

##### `addTag(tag)`

Adds a tag (if not already present).

##### `removeTag(tag)`

Removes a tag.

##### `updateMetadata(updates)`

Merges updates into metadata.

##### `matchesSearch(query): boolean`

Checks if project matches search query.

**Parameters:**

- `query` (string): Search query

**Returns:**

- `boolean` - True if name, description, path, tags, or type matches

##### `getSummary(): Object`

Gets project summary.

**Returns:**

```javascript
{
  id: string,
  name: string,
  type: string,
  typeIcon: string,
  typeDisplayName: string,
  path: string,
  description: string,
  tags: string[],
  totalSessions: number,
  totalDuration: number,
  averageDuration: number,
  lastAccessed: Date,
  isRecent: boolean
}
```

---

### Value Objects

Immutable objects representing domain concepts without identity.

#### SessionState

**File:** `cli/domain/value-objects/SessionState.js`

**Constants:**

```javascript
SessionState.ACTIVE = 'active'
SessionState.PAUSED = 'paused'
SessionState.ENDED = 'ended'
```

**Constructor:**

```javascript
new SessionState(value)
```

**Methods:**

- `isActive(): boolean`
- `isPaused(): boolean`
- `isEnded(): boolean`
- `toString(): string`

---

#### ProjectType

**File:** `cli/domain/value-objects/ProjectType.js`

**Constants:**

```javascript
ProjectType.R_PACKAGE = 'r-package'
ProjectType.QUARTO = 'quarto'
ProjectType.TEACHING = 'teaching'
ProjectType.RESEARCH = 'research'
ProjectType.DEV_TOOLS = 'dev-tools'
ProjectType.OBSIDIAN = 'obsidian'
ProjectType.GENERAL = 'general'
```

**Constructor:**

```javascript
new ProjectType(value)
```

**Methods:**

- `getIcon(): string` - Returns icon (📦, 📝, 📚, 📊, 🔧, 📓, 📁)
- `getDisplayName(): string` - Returns human-readable name
- `toString(): string`

---

### Domain Events

Events emitted during entity lifecycle.

#### SessionEvent Types

**File:** `cli/domain/events/SessionEvent.js`

**Available Events:**

```javascript
SessionStartedEvent(sessionId, project, task)
SessionEndedEvent(sessionId, outcome, duration)
SessionPausedEvent(sessionId)
SessionResumedEvent(sessionId)
SessionContextUpdatedEvent(sessionId, updates)
```

**Base Event Structure:**

```javascript
{
  eventType: string,     // Event type name
  occurredAt: Date,      // When event occurred
  aggregateId: string,   // Session ID
  payload: Object        // Event-specific data
}
```

---

### Repositories (Interfaces)

Repository interfaces define contracts for data access.

#### ISessionRepository

**File:** `cli/domain/repositories/ISessionRepository.js`

**Interface:**

```javascript
class ISessionRepository {
  async save(session)                    // Save session
  async findById(id)                     // Find by ID
  async findActive()                     // Find active session
  async list(options)                    // List sessions with filters
  async delete(id)                       // Delete session
}
```

**List Options:**

```javascript
{
  since: Date,           // Filter by start time
  until: Date,           // Filter by end time
  project: string,       // Filter by project
  state: string,         // Filter by state
  orderBy: string,       // Sort field
  order: 'asc'|'desc',   // Sort direction
  limit: number          // Max results
}
```

---

#### IProjectRepository

**File:** `cli/domain/repositories/IProjectRepository.js`

**Interface:**

```javascript
class IProjectRepository {
  async save(project)                    // Save project
  async findById(id)                     // Find by ID
  async findAll()                        // Find all projects
  async findRecent(hours, limit)         // Find recently accessed
  async findTopByDuration(limit)         // Find top by total duration
  async findByTag(tag)                   // Find by tag
  async search(query)                    // Search projects
  async delete(id)                       // Delete project
}
```

---

## Use Cases Layer

Application-specific business workflows.

### GetStatusUseCase

**File:** `cli/use-cases/GetStatusUseCase.js`

Gets comprehensive workflow status with metrics.

**Constructor:**

```javascript
new GetStatusUseCase(
  sessionRepository, // ISessionRepository
  projectRepository, // IProjectRepository
  gitGateway, // GitGateway (optional)
  statusFileGateway // StatusFileGateway (optional)
)
```

**Method:**

```javascript
async execute(input)
```

**Input:**

```javascript
{
  includeRecentSessions: boolean,  // Default: true
  includeProjectStats: boolean,    // Default: true
  recentDays: number               // Default: 7
}
```

**Output:**

```javascript
{
  activeSession: {
    id: string,
    project: string,
    task: string,
    branch: string,
    duration: number,
    isFlowState: boolean,
    state: string,
    startTime: Date,
    context: Object,
    gitStatus: Object,      // If git gateway provided
    statusFile: Object      // If status file gateway provided
  },

  today: {
    sessions: number,
    totalDuration: number,
    completedSessions: number,
    flowSessions: number
  },

  recent: {
    days: number,
    sessions: number,
    totalDuration: number,
    averageDuration: number,
    recentSessions: Array
  },

  projects: {
    total: number,
    recentProjects: Array,
    topByDuration: Array
  },

  metrics: {
    todayMinutes: number,
    dailyAverage: number,
    flowPercentage: number,
    completionRate: number,
    streak: number,
    trend: 'up'|'down'
  }
}
```

**Example:**

```javascript
const useCase = new GetStatusUseCase(sessionRepo, projectRepo, gitGateway, statusFileGateway)

const status = await useCase.execute({
  includeRecentSessions: true,
  recentDays: 7
})

console.log(`Active: ${status.activeSession?.project}`)
console.log(`Today: ${status.today.sessions} sessions`)
console.log(`Streak: ${status.metrics.streak} days`)
```

---

### CreateSessionUseCase

**File:** `cli/use-cases/CreateSessionUseCase.js`

Creates a new work session.

**Constructor:**

```javascript
new CreateSessionUseCase(
  sessionRepository, // ISessionRepository
  projectRepository, // IProjectRepository
  eventPublisher // IEventPublisher (optional)
)
```

**Method:**

```javascript
async execute(input)
```

**Input:**

```javascript
{
  project: string,       // Required
  task: string,          // Optional
  branch: string,        // Optional
  context: Object        // Optional
}
```

**Output:**

```javascript
{
  session: Session,
  created: boolean
}
```

**Business Rules:**

- Only one active session allowed at a time
- Validates project name
- Generates UUID for session ID
- Publishes `SessionStartedEvent`

**Example:**

```javascript
const useCase = new CreateSessionUseCase(sessionRepo, projectRepo)

const result = await useCase.execute({
  project: 'flow-cli',
  task: 'Implement API docs',
  branch: 'feature/api-docs'
})

console.log(`Session created: ${result.session.id}`)
```

---

### EndSessionUseCase

**File:** `cli/use-cases/EndSessionUseCase.js`

Ends the active work session.

**Constructor:**

```javascript
new EndSessionUseCase(
  sessionRepository, // ISessionRepository
  projectRepository, // IProjectRepository
  eventPublisher // IEventPublisher (optional)
)
```

**Method:**

```javascript
async execute(input)
```

**Input:**

```javascript
{
  outcome: string,       // 'completed', 'cancelled', 'interrupted'
  notes: string          // Optional
}
```

**Output:**

```javascript
{
  session: Session,
  duration: number
}
```

**Business Rules:**

- Must have an active session
- Records session in project statistics
- Publishes `SessionEndedEvent`

---

### ScanProjectsUseCase

**File:** `cli/use-cases/ScanProjectsUseCase.js`

Scans file system for projects with .STATUS files.

**Constructor:**

```javascript
new ScanProjectsUseCase(
  projectRepository, // IProjectRepository
  cache // ProjectScanCache (optional)
)
```

**Method:**

```javascript
async execute(input)
```

**Input:**

```javascript
{
  basePath: string,              // Base directory to scan
  filters: {
    type: string,                // Filter by project type
    status: string,              // Filter by status
    tag: string                  // Filter by tag
  },
  useCache: boolean,             // Use cached results (default: true)
  onProgress: (current, total)   // Progress callback
}
```

**Output:**

```javascript
{
  projects: Project[],
  cacheStats: {
    hit: boolean,
    age: number,
    ttl: number
  }
}
```

**Performance:**

- First scan: ~3ms for 60 projects
- Cached scan: <1ms
- Cache TTL: 1 hour

---

## Adapters Layer

Interface adapters between use cases and frameworks.

### Controllers

#### StatusController

**File:** `cli/adapters/controllers/StatusController.js`

Handles status command presentation logic.

**Constructor:**

```javascript
new StatusController(getStatusUseCase)
```

**Methods:**

##### `async showStatus(options)`

**Parameters:**

```javascript
{
  verbose: boolean,      // Show detailed metrics
  web: boolean,          // Launch web dashboard
  format: string         // 'text', 'json'
}
```

**Output:**

- Formatted status display (ASCII charts, colors)
- Web dashboard (if `web: true`)
- JSON output (if `format: 'json'`)

**Features:**

- Progress bars (ASCII)
- Sparkline charts
- Flow state indicator (🔥)
- Color-coded metrics
- Quick actions menu

---

### Repositories (Implementations)

#### FileSystemSessionRepository

**File:** `cli/adapters/repositories/FileSystemSessionRepository.js`

File-based implementation of `ISessionRepository`.

**Storage:** `~/.config/zsh/.sessions/` (JSON files)

**Methods:**

- Implements all `ISessionRepository` methods
- File format: `{sessionId}.json`
- Atomic writes with temp files

---

#### FileSystemProjectRepository

**File:** `cli/adapters/repositories/FileSystemProjectRepository.js`

Scans file system for projects with .STATUS files.

**Features:**

- In-memory caching (1-hour TTL)
- Parallel directory scanning
- Smart filters (.STATUS parsing)
- Progress callbacks

**Cache Performance:**

- First scan: ~3ms
- Cached: <1ms
- Auto-invalidation after 1 hour

---

### Gateways

#### GitGateway

**File:** `cli/adapters/gateways/GitGateway.js`

Interfaces with Git via shell commands.

**Methods:**

##### `async getStatus(cwd)`

**Returns:**

```javascript
{
  branch: string,
  ahead: number,
  behind: number,
  dirty: boolean,
  untracked: number,
  staged: number
}
```

---

#### StatusFileGateway

**File:** `cli/adapters/gateways/StatusFileGateway.js`

Reads and writes .STATUS files.

**Methods:**

##### `async read(projectPath)`

**Returns:**

```javascript
{
  status: string,
  priority: string,
  progress: number,
  next: string,
  type: string,
  raw: string
}
```

##### `async write(projectPath, data)`

**Parameters:**

- `data` (Object): Status fields to write

---

## Frameworks Layer

Outer layer containing frameworks, drivers, and CLI commands.

### CLI Commands

#### flow status

**File:** `cli/commands/status.js`

**Usage:**

```bash
flow status [options]
```

**Options:**

- `-v, --verbose` - Show detailed metrics
- `--web` - Launch web dashboard
- `--json` - JSON output
- `--help` - Show help

**Examples:**

```bash
flow status                # Basic status
flow status -v             # Verbose with metrics
flow status --web          # Web dashboard
flow status --json         # JSON output
```

---

#### flow dashboard

**File:** `cli/commands/dashboard.js`

**Usage:**

```bash
flow dashboard [options]
```

**Options:**

- `--interval <ms>` - Auto-refresh interval (default: 5000)
- `--help` - Show help

**Features:**

- Real-time TUI (blessed/blessed-contrib)
- Auto-refresh
- Keyboard shortcuts (r=refresh, /=filter, q=quit, ?=help)
- Grid layout (4 widgets)

**Example:**

```bash
flow dashboard --interval 3000
```

---

## Code Examples

### Example 1: Create and End Session

```javascript
import { Session } from './domain/entities/Session.js'
import { CreateSessionUseCase } from './use-cases/CreateSessionUseCase.js'
import { EndSessionUseCase } from './use-cases/EndSessionUseCase.js'
import { FileSystemSessionRepository } from './adapters/repositories/FileSystemSessionRepository.js'

// Setup repositories
const sessionRepo = new FileSystemSessionRepository()
const projectRepo = new FileSystemProjectRepository()

// Create session
const createUseCase = new CreateSessionUseCase(sessionRepo, projectRepo)
const { session } = await createUseCase.execute({
  project: 'flow-cli',
  task: 'Write API docs',
  branch: 'feature/api-docs'
})

console.log(`Session started: ${session.id}`)

// ... do work ...

// End session
const endUseCase = new EndSessionUseCase(sessionRepo, projectRepo)
const { duration } = await endUseCase.execute({
  outcome: 'completed',
  notes: 'Documented all domain entities'
})

console.log(`Session completed: ${duration} minutes`)
```

---

### Example 2: Get Status with Metrics

```javascript
import { GetStatusUseCase } from './use-cases/GetStatusUseCase.js'
import { StatusController } from './adapters/controllers/StatusController.js'

// Setup use case
const useCase = new GetStatusUseCase(sessionRepo, projectRepo, gitGateway, statusFileGateway)

// Get status
const status = await useCase.execute({
  includeRecentSessions: true,
  includeProjectStats: true,
  recentDays: 7
})

// Display with controller
const controller = new StatusController(useCase)
await controller.showStatus({ verbose: true })

// Or use status data directly
console.log(`Active: ${status.activeSession?.project}`)
console.log(`Flow state: ${status.activeSession?.isFlowState ? '🔥' : '❄️'}`)
console.log(`Today: ${status.today.sessions} sessions, ${status.today.totalDuration}min`)
console.log(`Streak: ${status.metrics.streak} days`)
console.log(`Flow %: ${status.metrics.flowPercentage}%`)
```

---

### Example 3: Scan Projects with Filters

```javascript
import { ScanProjectsUseCase } from './use-cases/ScanProjectsUseCase.js'
import { ProjectFilters } from './utils/ProjectFilters.js'

// Setup use case with cache
const scanUseCase = new ScanProjectsUseCase(projectRepo, cache)

// Scan with filters
const result = await scanUseCase.execute({
  basePath: '/Users/dt/projects',
  filters: {
    type: 'r-package',
    status: 'active'
  },
  useCache: true,
  onProgress: (current, total) => {
    console.log(`Scanning: ${current}/${total}`)
  }
})

console.log(`Found ${result.projects.length} projects`)
console.log(`Cache hit: ${result.cacheStats.hit}`)

// Use project data
for (const project of result.projects) {
  console.log(`${project.name} - ${project.totalSessions} sessions`)
}
```

---

### Example 4: Domain Events

```javascript
import { Session } from './domain/entities/Session.js'

// Create session (emits SessionStartedEvent)
const session = new Session('uuid-123', 'flow-cli', {
  task: 'Write docs'
})

// Pause (emits SessionPausedEvent)
session.pause()

// Resume (emits SessionResumedEvent)
session.resume()

// End (emits SessionEndedEvent)
session.end('completed')

// Get all events
const events = session.getEvents()
console.log(events.map(e => e.eventType))
// ['SessionStartedEvent', 'SessionPausedEvent', 'SessionResumedEvent', 'SessionEndedEvent']

// Publish events (your implementation)
for (const event of events) {
  await eventPublisher.publish(event)
}

// Clear events after publishing
session.clearEvents()
```

---

### Example 5: Custom Repository Implementation

```javascript
import { ISessionRepository } from './domain/repositories/ISessionRepository.js'

class PostgresSessionRepository extends ISessionRepository {
  constructor(pool) {
    super()
    this.pool = pool
  }

  async save(session) {
    const query = `
      INSERT INTO sessions (id, project, task, state, start_time)
      VALUES ($1, $2, $3, $4, $5)
      ON CONFLICT (id) DO UPDATE SET
        state = EXCLUDED.state,
        end_time = EXCLUDED.end_time
    `
    await this.pool.query(query, [
      session.id,
      session.project,
      session.task,
      session.state.value,
      session.startTime
    ])
  }

  async findActive() {
    const result = await this.pool.query(`
      SELECT * FROM sessions WHERE state = 'active' LIMIT 1
    `)
    if (result.rows.length === 0) return null
    return this.rowToSession(result.rows[0])
  }

  // ... implement other methods
}
```

---

## Testing

### Unit Testing

**Run tests:**

```bash
npm test                    # All tests
npm run test:unit           # Unit tests only
npm run test:integration    # Integration tests only
```

**Test Coverage:**

- 559 tests (100% passing)
- Domain: 265 tests
- Use Cases: 120 tests
- Adapters: 174 tests

### Example Test

```javascript
import { Session } from '../domain/entities/Session.js'

describe('Session Entity', () => {
  it('should create valid session', () => {
    const session = new Session('uuid-123', 'flow-cli')
    expect(session.project).toBe('flow-cli')
    expect(session.state.isActive()).toBe(true)
  })

  it('should enforce flow state rule', () => {
    const session = new Session('uuid-123', 'flow-cli')

    // Not in flow initially
    expect(session.isInFlowState()).toBe(false)

    // Mock 15 minutes of work
    session.startTime = new Date(Date.now() - 16 * 60 * 1000)

    // Now in flow
    expect(session.isInFlowState()).toBe(true)
  })
})
```

---

## Performance

**Benchmarks:**

- Session creation: <1ms
- Status retrieval: <10ms (cached)
- Project scanning: 3ms first, <1ms cached (60 projects)
- CLI startup: ~100ms (Node.js)

**ADHD Optimization:**

- ZSH commands: <10ms (instant response)
- Node.js CLI: ~100ms (rich features)
- Mental model: ZSH for doing, flow for viewing

---

## See Also

- [Architecture Overview](../architecture/README.md)
- [ADR-002: Clean Architecture](../decisions/ADR-002-adopt-clean-architecture.md)
- [Getting Started Guide](../getting-started/quick-start.md)
- [CLI Commands Reference](../commands/)
- [Testing Guide](../testing/TESTING.md)

---

**Last Updated:** 2025-12-24
**Version:** 2.0.0-beta.1
**License:** MIT
