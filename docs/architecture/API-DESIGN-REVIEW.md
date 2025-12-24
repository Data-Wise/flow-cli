# API Design Review - ZSH Configuration System

**Date:** 2025-12-20
**Reviewer:** Claude Code (using api-design-principles skill)
**Status:** Week 1 Complete + Planning Review

---

## Executive Summary

> **TL;DR:**
>
> - This is a Node.js library API (not REST/HTTP)
> - Current: ✅ Good foundation - clear naming, promises, graceful errors
> - Needs: Input validation, TypeScript definitions, ES modules consistency
> - Best APIs: Project Detection (excellent), Workflow (needs work)

The flow-cli system follows **Node.js module patterns** rather than traditional REST/GraphQL APIs, which is appropriate for a CLI/library tool. This review evaluates the API design against general API principles adapted for Node.js modules.

**Overall Assessment:** ✅ **Good Foundation** with clear improvement opportunities

**Strengths:**

- Clear function naming and semantics
- Consistent error handling patterns
- Good separation of concerns (API → Adapter → Vendor)
- Promise-based async patterns

**Areas for Improvement:**

- Inconsistent module formats (CommonJS vs ES Modules)
- Missing input validation
- No standardized error types
- Limited TypeScript support

---

## Design Philosophy

### Current Approach: Node.js Library API

```
User Code
    ↓
import { detectProjectType } from 'flow-cli'
    ↓
JavaScript Functions (Promise-based)
    ↓
Return Data or throw Errors
```

**This is appropriate for:**

- ✅ CLI tools
- ✅ Desktop applications (Electron)
- ✅ Local development utilities
- ✅ Build scripts

**NOT suitable for:**

- ❌ Remote HTTP APIs
- ❌ Third-party integrations over network
- ❌ Browser-based applications (without bundling)

---

## Module-by-Module Review

> **TL;DR:**
>
> - **Project Detection API**: ✅ Excellent - use this as the template for all APIs
> - **Status API**: ⚠️ Needs ES modules, input validation, consistent error handling
> - **Workflow API**: ⚠️ Uses success/error objects instead of exceptions (anti-pattern)
> - Key fix: Throw errors instead of returning `{success: false, error: "..."}` objects

### 1. Project Detection API ✅ Excellent

**Module:** `cli/lib/project-detector-bridge.js`

#### Strengths

**1. Clear Function Semantics**

```javascript
// ✅ Good: Verb-noun naming
detectProjectType(path) // Action + Subject
detectMultipleProjects(paths) // Action + Plural Subject
getSupportedTypes() // Get + Plural Noun
isTypeSupported(type) // Boolean check (is*)
```

**2. Consistent Return Types**

```javascript
// Single operation
detectProjectType() → Promise<string>

// Batch operation
detectMultipleProjects() → Promise<Object>  // Map structure

// Metadata queries
getSupportedTypes() → string[]  // Synchronous
isTypeSupported() → boolean     // Synchronous
```

**3. Graceful Error Handling**

```javascript
// ✅ Good: Returns safe default instead of throwing
try {
  const type = await detectProjectType(invalidPath)
  return mapProjectType(type)
} catch (error) {
  console.error(`Failed: ${error.message}`)
  return 'unknown' // Safe default
}
```

This follows the **graceful degradation pattern** - appropriate for ADHD-friendly tools where interruptions should be minimized.

#### Areas for Improvement

**1. Input Validation**

```javascript
// ❌ Current: No validation
export async function detectProjectType(projectPath) {
  // Assumes projectPath is valid string
}

// ✅ Better: Validate inputs
export async function detectProjectType(projectPath) {
  if (typeof projectPath !== 'string') {
    throw new TypeError('projectPath must be a string')
  }
  if (!projectPath.trim()) {
    throw new Error('projectPath cannot be empty')
  }
  if (!path.isAbsolute(projectPath)) {
    throw new Error('projectPath must be absolute')
  }
  // ... rest of function
}
```

**2. TypeScript Definitions**

```typescript
// Add: cli/lib/project-detector-bridge.d.ts
export type ProjectType =
  | 'r-package'
  | 'quarto'
  | 'quarto-extension'
  | 'research'
  | 'generic'
  | 'unknown'

export interface DetectionOptions {
  /** Custom type mappings */
  mappings?: Record<string, ProjectType>
  /** Timeout in milliseconds */
  timeout?: number
}

export function detectProjectType(
  projectPath: string,
  options?: DetectionOptions
): Promise<ProjectType>

export function detectMultipleProjects(
  projectPaths: string[],
  options?: DetectionOptions
): Promise<Record<string, ProjectType>>

export function getSupportedTypes(): ProjectType[]

export function isTypeSupported(type: string): type is ProjectType
```

**3. Options Pattern for Extensibility**

```javascript
// ✅ Future-proof with options object
export async function detectProjectType(projectPath, options = {}) {
  const { timeout = 5000, mappings = {}, cache = true } = options

  // Use options...
}

// Usage
await detectProjectType('/path', {
  timeout: 10000,
  cache: false
})
```

---

### 2. Status API ⚠️ Needs Modernization

**Module:** `cli/api/status-api.js`

#### Issues

**1. CommonJS vs ES Modules Inconsistency**

```javascript
// ❌ Current: CommonJS
const statusAdapter = require('../adapters/status')

module.exports = {
  getDashboardData,
  getSessionStatus
}

// ✅ Should be: ES Modules (match project-detector-bridge)
import { statusAdapter } from '../adapters/status.js'

export { getDashboardData, getSessionStatus }
```

**2. Inconsistent Error Handling**

```javascript
// ❌ Current: Some functions return error objects
async function getProgressSummary(projectPath) {
  const project = await statusAdapter.getProjectStatus(projectPath)

  if (project.error) {
    return {
      error: project.error, // Error as data
      hasProgress: false
    }
  }
  // ...
}

// ✅ Better: Throw errors consistently
async function getProgressSummary(projectPath) {
  const project = await statusAdapter.getProjectStatus(projectPath)

  if (project.error) {
    throw new ProjectNotFoundError(project.error)
  }
  // ...
}
```

**3. Missing Input Validation**

```javascript
// ❌ Current: No validation
async function getDashboardData(projectPath = process.cwd()) {
  const status = await statusAdapter.getCompleteStatus(projectPath)
  // ...
}

// ✅ Better: Validate projectPath
async function getDashboardData(projectPath = process.cwd()) {
  if (!(await exists(projectPath))) {
    throw new Error(`Project path does not exist: ${projectPath}`)
  }
  // ...
}
```

#### Recommendations

**1. Standardize Error Types**

```javascript
// Create: cli/lib/errors.js
export class ZshConfigError extends Error {
  constructor(message, code) {
    super(message)
    this.name = 'ZshConfigError'
    this.code = code
  }
}

export class ProjectNotFoundError extends ZshConfigError {
  constructor(path) {
    super(`Project not found: ${path}`, 'PROJECT_NOT_FOUND')
    this.path = path
  }
}

export class NoActiveSessionError extends ZshConfigError {
  constructor() {
    super('No active session', 'NO_ACTIVE_SESSION')
  }
}

export class ValidationError extends ZshConfigError {
  constructor(field, message) {
    super(`Validation failed for ${field}: ${message}`, 'VALIDATION_ERROR')
    this.field = field
  }
}
```

**2. Consistent Return Types**

```javascript
// ✅ Good pattern: Always return structured objects
interface DashboardData {
  session: SessionData | null;
  project: ProjectData;
  timestamp: string;
}

interface SessionData {
  active: boolean;
  project?: string;
  startTime?: string;
  duration?: string;
  // ...
}
```

---

### 3. Workflow API ⚠️ Needs Modernization

**Module:** `cli/api/workflow-api.js`

#### Issues

**1. Result Object Inconsistency**

```javascript
// Different success/error patterns
async function startSession(project, options = {}) {
  // ...
  return {
    success: false,
    error: 'Already in an active session', // Pattern 1
    currentSession: existingSession
  }
}

async function endSession(options = {}) {
  // ...
  return {
    success: false,
    error: result.stderr || 'Failed to end session', // Pattern 2
    session,
    timestamp: result.timestamp
  }
}
```

**Better:** Use exceptions for errors

```javascript
async function startSession(project, options = {}) {
  const existingSession = await statusAdapter.getCurrentSession()
  if (existingSession && existingSession.project) {
    throw new SessionAlreadyActiveError(existingSession)
  }
  // ... successful path
  return newSession
}
```

**2. Magic Strings for Commands**

```javascript
// ❌ Current: String literals
async function build() {
  const result = await workflowAdapter.executeSmartCommand('build');
  // ...
}

// ✅ Better: Constants or enums
export const WorkflowCommands = {
  BUILD: 'build',
  TEST: 'test',
  PREVIEW: 'preview'
} as const;

async function build() {
  const result = await workflowAdapter.executeSmartCommand(WorkflowCommands.BUILD);
  // ...
}
```

---

## Planned APIs - Design Recommendations

> **TL;DR:**
>
> - **Session Manager**: Use class-based EventEmitter pattern (recommended design included)
> - **Project Scanner**: Use constructor injection + caching strategy
> - Key patterns: Validate inputs, throw custom errors, emit events for extensibility
> - See code examples below - copy/paste ready for implementation

### 4. Session Manager (Week 2)

#### Recommended API Design

```javascript
// cli/core/session-manager.js

import { EventEmitter } from 'events'

export class SessionManager extends EventEmitter {
  constructor(options = {}) {
    super()
    this.storageDir = options.storageDir || getDefaultStorageDir()
  }

  /**
   * Create a new work session
   * @param {string} project - Project name (required)
   * @param {Object} options - Session options
   * @param {string} options.task - What you're working on
   * @param {string} options.branch - Git branch
   * @param {Object} options.context - Additional context
   * @returns {Promise<Session>} Created session
   * @throws {SessionAlreadyActiveError} If session already active
   * @throws {ValidationError} If project is invalid
   */
  async createSession(project, options = {}) {
    // Validate inputs
    if (!project || typeof project !== 'string') {
      throw new ValidationError('project', 'Project name is required')
    }

    // Check for existing session
    const active = await this.getActiveSession()
    if (active) {
      throw new SessionAlreadyActiveError(active)
    }

    // Create session
    const session = {
      id: generateId(),
      project,
      task: options.task,
      branch: options.branch,
      context: options.context || {},
      startTime: new Date().toISOString(),
      state: 'active'
    }

    await this.save(session)
    this.emit('session:created', session)

    return session
  }

  /**
   * Get currently active session
   * @returns {Promise<Session|null>} Active session or null
   */
  async getActiveSession() {
    const sessions = await this.listSessions({ state: 'active' })
    return sessions[0] || null
  }

  /**
   * Update session metadata
   * @param {string} sessionId - Session ID
   * @param {Object} updates - Fields to update
   * @returns {Promise<Session>} Updated session
   * @throws {SessionNotFoundError} If session doesn't exist
   */
  async updateSession(sessionId, updates) {
    const session = await this.getSession(sessionId)
    if (!session) {
      throw new SessionNotFoundError(sessionId)
    }

    const updated = {
      ...session,
      ...updates,
      updatedAt: new Date().toISOString()
    }

    await this.save(updated)
    this.emit('session:updated', updated)

    return updated
  }

  /**
   * End a session
   * @param {string} sessionId - Session ID
   * @param {Object} result - Session outcome
   * @param {string} result.outcome - 'completed', 'paused', 'abandoned'
   * @param {string} result.summary - Summary of work done
   * @returns {Promise<Session>} Ended session
   */
  async endSession(sessionId, result = {}) {
    const session = await this.getSession(sessionId)
    if (!session) {
      throw new SessionNotFoundError(sessionId)
    }

    const ended = {
      ...session,
      state: 'ended',
      endTime: new Date().toISOString(),
      outcome: result.outcome || 'completed',
      summary: result.summary,
      duration: calculateDuration(session.startTime)
    }

    await this.save(ended)
    this.emit('session:ended', ended)

    return ended
  }

  /**
   * List sessions with filters
   * @param {Object} filters - Filter criteria
   * @param {string} filters.project - Filter by project
   * @param {string} filters.state - Filter by state
   * @param {string} filters.since - Filter by date (ISO string)
   * @returns {Promise<Session[]>} Matching sessions
   */
  async listSessions(filters = {}) {
    // Implementation...
  }
}

// Error classes
export class SessionAlreadyActiveError extends Error {
  constructor(session) {
    super(`Session already active for project: ${session.project}`)
    this.name = 'SessionAlreadyActiveError'
    this.session = session
  }
}

export class SessionNotFoundError extends Error {
  constructor(sessionId) {
    super(`Session not found: ${sessionId}`)
    this.name = 'SessionNotFoundError'
    this.sessionId = sessionId
  }
}
```

**Benefits:**

- ✅ Class-based API with EventEmitter for extensibility
- ✅ Clear method signatures with JSDoc
- ✅ Consistent error handling with custom error types
- ✅ Input validation on all public methods
- ✅ Events for integration (session:created, session:updated, session:ended)

---

### 5. Project Scanner (Week 1 Remaining)

#### Recommended API Design

```javascript
// cli/core/project-scanner.js

import { detectMultipleProjects } from '../lib/project-detector-bridge.js'

export class ProjectScanner {
  constructor(options = {}) {
    this.cacheEnabled = options.cache !== false
    this.cacheDir = options.cacheDir || getDefaultCacheDir()
    this.maxDepth = options.maxDepth || 3
  }

  /**
   * Scan directory recursively for projects
   * @param {string} basePath - Directory to scan
   * @param {Object} options - Scan options
   * @param {number} options.maxDepth - Maximum directory depth (default: 3)
   * @param {boolean} options.includeHidden - Include hidden directories
   * @param {string[]} options.types - Filter by project types
   * @returns {Promise<Project[]>} Discovered projects
   */
  async scanDirectory(basePath, options = {}) {
    // Validate
    if (!(await exists(basePath))) {
      throw new Error(`Directory does not exist: ${basePath}`)
    }

    const { maxDepth = this.maxDepth, includeHidden = false, types = [] } = options

    // Find all potential project directories
    const dirs = await this.findProjectDirectories(basePath, {
      maxDepth,
      includeHidden
    })

    // Detect types in parallel
    const detections = await detectMultipleProjects(dirs)

    // Build project objects
    const projects = await Promise.all(
      Object.entries(detections).map(async ([path, type]) => {
        // Filter by type if specified
        if (types.length > 0 && !types.includes(type)) {
          return null
        }

        return {
          path,
          name: basename(path),
          type,
          metadata: await this.extractMetadata(path, type),
          status: await this.readStatus(path)
        }
      })
    )

    return projects.filter(Boolean)
  }

  /**
   * Scan all known project locations
   * @returns {Promise<Project[]>} All projects
   */
  async scanAllProjects() {
    const locations = [
      join(homedir(), 'projects/r-packages'),
      join(homedir(), 'projects/teaching'),
      join(homedir(), 'projects/research'),
      join(homedir(), 'projects/dev-tools')
    ]

    const results = await Promise.all(locations.map(loc => this.scanDirectory(loc)))

    return results.flat()
  }

  /**
   * Find a project by name
   * @param {string} name - Project name
   * @returns {Promise<Project|null>} Project or null
   */
  async findProject(name) {
    const cache = await this.getCache()
    return cache.find(p => p.name === name) || null
  }

  /**
   * Get projects by type
   * @param {string} type - Project type
   * @returns {Promise<Project[]>} Projects of type
   */
  async getProjectsByType(type) {
    const cache = await this.getCache()
    return cache.filter(p => p.type === type)
  }

  /**
   * Update project cache
   * @returns {Promise<void>}
   */
  async updateProjectCache() {
    const projects = await this.scanAllProjects()
    await this.saveCache(projects)
  }
}
```

**Design Principles Applied:**

- ✅ Constructor injection for configuration
- ✅ Sensible defaults with override capability
- ✅ Async/await throughout
- ✅ Input validation
- ✅ Clear method responsibilities
- ✅ Caching strategy built-in

---

## Best Practices Applied

> **TL;DR:**
>
> - **Keep doing**: Promise-based async, graceful degradation, parallel operations
> - **Start doing**: Input validation, custom error types, TypeScript definitions
> - **Future**: Plugin system, middleware hooks, streaming APIs for large datasets

### ✅ Already Following

1. **Promise-based Async** - All async operations return Promises
2. **Graceful Degradation** - Return safe defaults instead of crashing
3. **Separation of Concerns** - API → Adapter → Vendor layers
4. **Descriptive Naming** - Clear verb-noun patterns
5. **Parallel Operations** - `detectMultipleProjects` uses `Promise.all()`

### ⚠️ Should Adopt

1. **Input Validation** - Validate all public API inputs
2. **Custom Error Types** - Create semantic error classes
3. **TypeScript Definitions** - Add `.d.ts` files for better DX
4. **Options Objects** - Use extensible options pattern
5. **ES Modules Consistency** - Migrate all to ES modules
6. **Event-Based Integration** - Use EventEmitter for extensibility

### 📋 Future Enhancements

1. **Plugin System** - Allow custom project type detectors
2. **Middleware Pattern** - Pre/post-processing hooks
3. **Streaming APIs** - For large project scans
4. **Rate Limiting** - Prevent resource exhaustion
5. **Telemetry** - Optional usage analytics

---

## Design Patterns Recommended

> **TL;DR:**
>
> - **Factory Pattern**: Centralize object creation (SessionFactory)
> - **Repository Pattern**: Abstract data storage (SessionRepository)
> - **Builder Pattern**: Fluent query APIs (ProjectQueryBuilder)
> - All three patterns already have copy/paste-ready code below

### 1. Factory Pattern for Complex Objects

```javascript
// cli/lib/factories/session-factory.js

export class SessionFactory {
  static create(project, options = {}) {
    return {
      id: generateId(),
      project,
      task: options.task || 'Work session',
      branch: options.branch || 'main',
      context: {
        cwd: process.cwd(),
        editor: options.editor || 'unknown',
        ...options.context
      },
      startTime: new Date().toISOString(),
      state: 'active',
      metadata: {
        hostname: os.hostname(),
        user: os.userInfo().username
      }
    }
  }

  static fromJSON(json) {
    return {
      ...json,
      startTime: new Date(json.startTime),
      endTime: json.endTime ? new Date(json.endTime) : null
    }
  }
}
```

### 2. Repository Pattern for Data Access

```javascript
// cli/lib/repositories/session-repository.js

export class SessionRepository {
  constructor(storageDir) {
    this.storageDir = storageDir
  }

  async save(session) {
    const filePath = join(this.storageDir, `${session.id}.json`)
    await writeFile(filePath, JSON.stringify(session, null, 2))
  }

  async findById(id) {
    const filePath = join(this.storageDir, `${id}.json`)
    try {
      const content = await readFile(filePath, 'utf-8')
      return JSON.parse(content)
    } catch (error) {
      if (error.code === 'ENOENT') return null
      throw error
    }
  }

  async findAll(filters = {}) {
    const files = await readdir(this.storageDir)
    const sessions = await Promise.all(
      files.filter(f => f.endsWith('.json')).map(f => this.findById(f.replace('.json', '')))
    )

    return sessions.filter(s => s && this.matchesFilters(s, filters))
  }

  matchesFilters(session, filters) {
    if (filters.project && session.project !== filters.project) return false
    if (filters.state && session.state !== filters.state) return false
    if (filters.since && session.startTime < filters.since) return false
    return true
  }
}
```

### 3. Builder Pattern for Complex Queries

```javascript
// cli/lib/builders/project-query-builder.js

export class ProjectQueryBuilder {
  constructor() {
    this.filters = {}
    this.sorting = {}
    this.pagination = {}
  }

  filterByType(...types) {
    this.filters.types = types
    return this
  }

  filterByCategory(category) {
    this.filters.category = category
    return this
  }

  filterByStatus(status) {
    this.filters.status = status
    return this
  }

  sortBy(field, direction = 'asc') {
    this.sorting = { field, direction }
    return this
  }

  paginate(page, pageSize) {
    this.pagination = { page, pageSize }
    return this
  }

  async execute(scanner) {
    let projects = await scanner.scanAllProjects()

    // Apply filters
    if (this.filters.types) {
      projects = projects.filter(p => this.filters.types.includes(p.type))
    }
    if (this.filters.category) {
      projects = projects.filter(p => p.category === this.filters.category)
    }
    if (this.filters.status) {
      projects = projects.filter(p => p.status?.currentStatus === this.filters.status)
    }

    // Apply sorting
    if (this.sorting.field) {
      projects.sort((a, b) => {
        const aVal = a[this.sorting.field]
        const bVal = b[this.sorting.field]
        const cmp = aVal < bVal ? -1 : aVal > bVal ? 1 : 0
        return this.sorting.direction === 'asc' ? cmp : -cmp
      })
    }

    // Apply pagination
    if (this.pagination.page) {
      const { page, pageSize } = this.pagination
      const start = (page - 1) * pageSize
      projects = projects.slice(start, start + pageSize)
    }

    return projects
  }
}

// Usage
const rPackages = await new ProjectQueryBuilder()
  .filterByType('r-package')
  .filterByStatus('active')
  .sortBy('lastModified', 'desc')
  .paginate(1, 20)
  .execute(scanner)
```

---

## Implementation Priority

> **TL;DR:**
>
> - **Phase 1 (Week 2)**: Foundation - errors, validation, ES modules, TypeScript
> - **Phase 2 (Week 3)**: Enhancement - Session Manager, events, factories, repositories
> - **Phase 3 (Week 4+)**: Polish - plugins, middleware, tests, performance
> - Start with Phase 1 items #1-4 - they're quick wins with high impact

### Phase 1 (Week 2) - Foundation

1. **Create Error Classes** (`cli/lib/errors.js`)
2. **Add Input Validation** to all existing APIs
3. **Migrate to ES Modules** (Status API, Workflow API)
4. **Add TypeScript Definitions** for Project Detection API

### Phase 2 (Week 3) - Enhancement

5. **Implement Session Manager** with recommended design
6. **Add Event System** to key operations
7. **Create Factory Classes** for complex objects
8. **Add Repository Pattern** for data access

### Phase 3 (Week 4+) - Polish

9. **Plugin System** for extensibility
10. **Middleware Hooks** for customization
11. **Comprehensive Test Suite** for all APIs
12. **Performance Monitoring** and optimization

---

## Success Metrics

### API Quality

- ✅ 100% input validation coverage
- ✅ Custom error types for all error conditions
- ✅ TypeScript definitions for all public APIs
- ✅ Consistent async/await patterns

### Developer Experience

- ✅ Clear documentation with examples
- ✅ Predictable behavior (no surprises)
- ✅ Helpful error messages
- ✅ IDE autocomplete support

### Maintainability

- ✅ Consistent module format (ES modules)
- ✅ Clear separation of concerns
- ✅ Testable design (dependency injection)
- ✅ Extensible without modification

---

## Conclusion

> **TL;DR:**
>
> - **Current state**: Solid foundation, needs modernization
> - **Template**: Use Project Detection API as the gold standard
> - **Top 5 fixes**: ES modules, input validation, error classes, TypeScript, design patterns
> - **Result**: Professional-grade API that's easy to use, hard to misuse, easy to extend

The flow-cli API design is **solid but needs modernization**. The Project Detection API (Week 1) demonstrates good patterns that should be applied consistently across all modules.

**Key Recommendations:**

1. **Standardize on ES modules** - Consistency aids maintenance
2. **Add input validation** - Fail fast with clear errors
3. **Create error hierarchy** - Semantic error types improve DX
4. **Use TypeScript definitions** - Better IDE support
5. **Apply design patterns** - Factory, Repository, Builder for complex operations

By following these recommendations, the system will have a **professional-grade API** that's:

- Easy to use (clear semantics)
- Hard to misuse (validation)
- Easy to extend (patterns & events)
- Easy to test (dependency injection)

---

**Last Updated:** 2025-12-20
**Reviewer:** Claude Code
**Next Review:** After Week 2 implementation
