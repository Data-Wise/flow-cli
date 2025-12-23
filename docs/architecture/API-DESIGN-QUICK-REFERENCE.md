# API Design Quick Reference Card
## Node.js Module API Patterns

**Version:** 1.0 | **Date:** 2025-12-23 | **Print-friendly:** Yes

---

## 🎯 This is a Library API, Not REST

```
❌ NOT This (REST/HTTP):
GET /api/sessions
POST /api/sessions
{status: 200, data: {...}}

✅ This (Node.js Module):
import { createSession } from 'flow-cli'
const session = await createSession(options)
```

**Why it matters:** Different patterns, different best practices!

---

## ⚡ The Golden Rules

### 1. **Throw Errors, Don't Return Them**

```javascript
// ❌ BAD: Returns error objects
function detectProject(path) {
  if (!exists(path)) {
    return { success: false, error: 'Path not found' }
  }
}

// ✅ GOOD: Throws exceptions
function detectProject(path) {
  if (!exists(path)) {
    throw new ProjectNotFoundError(path)
  }
  return projectType
}
```

**Why:** JavaScript has `try/catch`. Use it! Error objects force every caller to check `if (result.success)`.

### 2. **Promise Everything Async**

```javascript
// ❌ BAD: Callback hell
function scanProjects(path, callback) {
  fs.readdir(path, (err, files) => {
    if (err) return callback(err)
    callback(null, files)
  })
}

// ✅ GOOD: Promise-based
async function scanProjects(path) {
  const files = await fs.promises.readdir(path)
  return files
}
```

### 3. **Return Domain Objects, Not Primitives**

```javascript
// ❌ BAD: Returns string
function createSession(project) {
  return 'session-12345'  // Just an ID?
}

// ✅ GOOD: Returns entity
function createSession(project) {
  return new Session({
    id: 'session-12345',
    project,
    startTime: new Date(),
    state: SessionState.ACTIVE
  })
}
```

### 4. **Validate Input Early**

```javascript
// ❌ BAD: Fails deep in stack
async function createSession(project) {
  await saveToDatabase(project)  // Crashes here if project invalid
}

// ✅ GOOD: Validates immediately
async function createSession(project) {
  if (!project || project.trim() === '') {
    throw new ValidationError('Project name required')
  }
  if (project.length < 2) {
    throw new ValidationError('Project name must be at least 2 characters')
  }

  await saveToDatabase(project)
}
```

### 5. **Consistent Naming Conventions**

```javascript
// Actions (verbs)
createSession()      // Create new
deleteSession()      // Remove
updateSession()      // Modify
startSession()       // Begin process
endSession()         // Finish process

// Queries (get/find/is)
getSession()         // Get by ID (expects to find)
findSession()        // Search (may not find)
listSessions()       // Get multiple
isSessionActive()    // Boolean check

// Batch operations (plural)
createSessions()     // Multiple at once
deleteSessions()     // Multiple at once
```

---

## 📋 Function Signature Patterns

### Pattern 1: Single Parameter Object

```javascript
// ✅ BEST for complex operations
async function createSession({
  project,
  task = 'Work session',    // Default values
  branch = 'main',
  context = {}
}) {
  // Implementation
}

// Usage
await createSession({
  project: 'rmediation',
  task: 'Fix bug #123',
  context: { priority: 'high' }
})
```

**Benefits:**
- Named parameters (self-documenting)
- Easy to add new options
- Default values built-in
- Order doesn't matter

### Pattern 2: Simple Required + Options

```javascript
// ✅ GOOD for clear required params
async function detectProjectType(
  projectPath,              // Required, obvious
  options = {}              // Optional config
) {
  const { cache = true, parallel = false } = options
  // Implementation
}

// Usage
await detectProjectType('/path/to/project')
await detectProjectType('/path/to/project', { cache: false })
```

### Pattern 3: Multiple Required Params

```javascript
// ⚠️ OK for 2-3 clear required params
function createProject(name, path, type) {
  // But switch to object pattern if > 3 params!
}
```

---

## 🎨 Return Type Patterns

### Simple Operations

```javascript
// Return the entity
async function createSession(opts) {
  const session = new Session(...)
  await repository.save(session)
  return session  // ✅ Return domain object
}

// Return boolean for checks
function isSessionActive(session) {
  return session.state === SessionState.ACTIVE
}

// Return array for lists
async function listActiveSessions() {
  return await repository.findAll({ state: 'active' })
}
```

### Complex Operations (Use Result Object)

```javascript
// For operations that return multiple pieces of info
async function scanProjects(basePath) {
  const projects = await findProjects(basePath)
  const stats = computeStats(projects)

  return {
    projects,         // Array of Project entities
    count: projects.length,
    stats,
    scannedAt: new Date()
  }
}
```

### Void Operations

```javascript
// No return value for actions with side effects
async function deleteSession(sessionId) {
  await repository.delete(sessionId)
  // No return (or return void/undefined)
}

// Or return boolean for success/failure
async function deleteSession(sessionId) {
  const deleted = await repository.delete(sessionId)
  return deleted  // true if deleted, false if not found
}
```

---

## 🚫 Anti-Patterns to Avoid

### ❌ Success/Error Objects

```javascript
// DON'T DO THIS
function doSomething() {
  try {
    const result = performAction()
    return { success: true, data: result }
  } catch (error) {
    return { success: false, error: error.message }
  }
}

// Every caller must check:
const result = doSomething()
if (!result.success) {
  console.error(result.error)
}

// ✅ DO THIS INSTEAD
function doSomething() {
  const result = performAction()  // Let errors throw
  return result                    // Return data directly
}

// Caller uses standard error handling:
try {
  const result = doSomething()
} catch (error) {
  console.error(error.message)
}
```

### ❌ Mixing Sync and Async

```javascript
// DON'T MIX
function getSupportedTypes() {
  return ['r-package', 'quarto']  // Sync
}

async function detectType(path) {
  return await shellExec(...)      // Async
}

// ✅ BE CONSISTENT
// If the module is async, make metadata async too (or clearly separate)
```

### ❌ Silent Failures

```javascript
// DON'T SWALLOW ERRORS
async function detectProject(path) {
  try {
    return await shellExec(path)
  } catch {
    return 'unknown'  // ❌ Hides errors
  }
}

// ✅ LET ERRORS SURFACE (or log + throw)
async function detectProject(path) {
  try {
    return await shellExec(path)
  } catch (error) {
    console.error('Detection failed:', error)
    throw error  // Re-throw so caller knows
  }
}
```

### ❌ God Functions

```javascript
// DON'T CREATE ONE FUNCTION TO RULE THEM ALL
async function manageSession(action, ...params) {
  if (action === 'create') { }
  else if (action === 'delete') { }
  else if (action === 'update') { }
  // ...
}

// ✅ SEPARATE FUNCTIONS
async function createSession(opts) { }
async function deleteSession(id) { }
async function updateSession(id, updates) { }
```

---

## 🎓 Error Handling Best Practices

### Custom Error Classes

```javascript
// Define domain-specific errors
class SessionError extends Error {
  constructor(message) {
    super(message)
    this.name = 'SessionError'
  }
}

class SessionNotFoundError extends SessionError {
  constructor(sessionId) {
    super(`Session not found: ${sessionId}`)
    this.sessionId = sessionId
  }
}

class SessionAlreadyActiveError extends SessionError {
  constructor(currentSession) {
    super(`Session already active: ${currentSession.project}`)
    this.currentSession = currentSession
  }
}

// Usage
async function createSession(opts) {
  const active = await repository.findActive()
  if (active) {
    throw new SessionAlreadyActiveError(active)
  }
  // ...
}

// Caller can catch specific errors
try {
  await createSession({ project: 'test' })
} catch (error) {
  if (error instanceof SessionAlreadyActiveError) {
    console.log('End current session first:', error.currentSession.project)
  } else {
    throw error
  }
}
```

### Error Context

```javascript
// Include helpful context
class ValidationError extends Error {
  constructor(field, value, reason) {
    super(`Validation failed for ${field}: ${reason}`)
    this.field = field
    this.value = value
    this.reason = reason
  }
}

// Throw with context
if (!project || project.trim() === '') {
  throw new ValidationError('project', project, 'Project name cannot be empty')
}
```

---

## 📦 Module Exports Pattern

### ES Modules (Preferred)

```javascript
// cli/lib/sessions.js

// Named exports (recommended)
export async function createSession(opts) { }
export async function endSession(id) { }
export async function listSessions(filters) { }

// Value exports
export const SessionState = {
  ACTIVE: 'active',
  PAUSED: 'paused',
  ENDED: 'ended'
}

// Default export for main class
export default class SessionManager {
  constructor(repository) { }
  // ...
}

// Usage
import { createSession, SessionState } from './lib/sessions.js'
import SessionManager from './lib/sessions.js'
```

### Barrel Exports (Index Files)

```javascript
// cli/domain/index.js
// Re-export from subdirectories

export { Session } from './entities/Session.js'
export { Project } from './entities/Project.js'
export { Task } from './entities/Task.js'

export { ProjectType } from './value-objects/ProjectType.js'
export { SessionState } from './value-objects/SessionState.js'

export { ISessionRepository } from './repositories/ISessionRepository.js'
export { IProjectRepository } from './repositories/IProjectRepository.js'

// Now consumers can import from one place:
// import { Session, ProjectType, ISessionRepository } from './domain/index.js'
```

---

## 🧪 Testing Patterns

### Mock Repository Pattern

```javascript
// Create in-memory implementation for testing
class InMemorySessionRepository {
  constructor() {
    this.sessions = []
  }

  async save(session) {
    this.sessions.push(session)
    return session
  }

  async findById(id) {
    return this.sessions.find(s => s.id === id)
  }

  async findActive() {
    return this.sessions.find(s => s.state === 'active')
  }

  async clear() {
    this.sessions = []
  }
}

// Use in tests
describe('CreateSessionUseCase', () => {
  let repository
  let useCase

  beforeEach(() => {
    repository = new InMemorySessionRepository()
    useCase = new CreateSessionUseCase(repository)
  })

  test('creates session successfully', async () => {
    const result = await useCase.execute({ project: 'test' })
    expect(result.project).toBe('test')

    const saved = await repository.findById(result.id)
    expect(saved).toBeDefined()
  })
})
```

---

## 📊 API Quality Checklist

### Before Publishing API

- [ ] All async functions return Promises
- [ ] Errors throw exceptions (not returned in objects)
- [ ] Parameters use object pattern for > 2 args
- [ ] Return types are consistent and documented
- [ ] Custom error classes for domain errors
- [ ] Input validation at API boundary
- [ ] JSDoc comments on public functions
- [ ] Examples in documentation
- [ ] Unit tests for all public functions
- [ ] Integration tests for adapters
- [ ] TypeScript definitions (if TS project)

---

## 🎯 Quick Decision Guide

**"Should this throw or return?"**

```
Is this an expected outcome? → Return
Is this an error condition? → Throw

Examples:
- findSession() may not find → Return null (expected)
- Database connection fails → Throw (error)
- Validation fails → Throw (error)
- List is empty → Return [] (expected)
```

**"Sync or async?"**

```
Does it do I/O (file, network, DB)? → Async
Does it run shell commands? → Async
Is it pure computation? → Sync
Does it access in-memory data? → Sync (usually)

Be consistent within a module!
```

**"What should I return?"**

```
Creating entity? → Return the entity
Deleting entity? → Return boolean or void
Querying one? → Return entity or null
Querying many? → Return array (empty if none)
Complex operation? → Return object with multiple fields
```

---

## 📚 Real-World Examples

### Example 1: Project Detection API ✅

```javascript
// Excellent API design

// Simple, clear names
detectProjectType(path)           // Verb + noun
detectMultipleProjects(paths)     // Plural for batch
getSupportedTypes()               // Query metadata
isTypeSupported(type)             // Boolean check

// Returns domain values
detectProjectType() → string      // 'r-package', 'quarto', etc.
detectMultipleProjects() → Object // Map of path → type

// Graceful errors
// Returns 'unknown' instead of throwing for missing projects
// (This is appropriate - "unknown type" is a valid result)
```

### Example 2: Session Management (Improved)

```javascript
// BEFORE (anti-pattern)
function startSession(project, task, branch) {
  if (!project) {
    return { success: false, error: 'Project required' }
  }
  // ...
  return { success: true, data: session }
}

// AFTER (correct pattern)
async function startSession({ project, task, branch = 'main' }) {
  if (!project || project.trim() === '') {
    throw new ValidationError('project', project, 'Project name required')
  }

  const active = await sessionRepository.findActive()
  if (active) {
    throw new SessionAlreadyActiveError(active)
  }

  const session = new Session({ project, task, branch })
  await sessionRepository.save(session)

  return session
}
```

---

## 🚀 TypeScript Bonus Tips

### Type Definitions for Better DX

```typescript
// Even if you're using JavaScript, provide .d.ts files

// cli/lib/sessions.d.ts
export interface SessionOptions {
  project: string
  task?: string
  branch?: string
  context?: Record<string, unknown>
}

export interface Session {
  id: string
  project: string
  task: string
  branch: string
  startTime: Date
  endTime?: Date
  state: 'active' | 'paused' | 'ended'
}

export function createSession(options: SessionOptions): Promise<Session>
export function endSession(sessionId: string): Promise<void>
export function listSessions(filters?: object): Promise<Session[]>
```

---

**Generated:** 2025-12-23
**Part of:** Architecture Enhancement Plan (A→C Implementation)
**Purpose:** Quick reference for Node.js module API design patterns
**See Also:** [API-DESIGN-REVIEW.md](API-DESIGN-REVIEW.md) - Full review
