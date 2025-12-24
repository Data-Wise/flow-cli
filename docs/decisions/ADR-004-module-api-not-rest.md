# ADR-004: Use Node.js Module API Pattern (Not REST/HTTP)

**Status:** ✅ Accepted
**Date:** 2025-12-20
**Deciders:** Development Team
**Technical Story:** API Design Review (Week 1)

---

## Context and Problem Statement

The flow-cli system needs to expose functionality to various consumers (CLI, Desktop UI, future integrations). We need to decide on the API pattern that balances usability, performance, and future extensibility.

**Key Question:** Should we use REST/HTTP APIs, GraphQL, RPC, or Node.js module APIs?

---

## Decision Drivers

- **Primary Use Case** - CLI tool and Desktop app (local, not networked)
- **Performance** - Low latency required for interactive commands
- **Simplicity** - Easy to call from JavaScript/Node.js
- **Type Safety** - TypeScript support desirable
- **Future Flexibility** - May need HTTP API later
- **Developer Experience** - Clear, discoverable API

---

## Considered Options

### Option 1: REST/HTTP API

```javascript
// User code
const response = await fetch('http://localhost:3000/api/sessions', {
  method: 'POST',
  body: JSON.stringify({ project: 'rmediation' })
})

const data = await response.json()
if (data.status === 200) {
  console.log(data.data.sessionId)
}
```

**Pros:**

- ✅ Language-agnostic (could call from any language)
- ✅ Well-understood patterns
- ✅ Network-capable (remote access)

**Cons:**

- ❌ Requires HTTP server (overhead)
- ❌ Slower (network roundtrip even locally)
- ❌ Complex error handling (HTTP status codes)
- ❌ Serialization overhead (JSON encode/decode)
- ❌ Overkill for local-only tool

### Option 2: GraphQL

```javascript
// User code
const result = await client.query({
  query: gql`
    mutation CreateSession($project: String!) {
      createSession(project: $project) {
        id
        project
        startTime
      }
    }
  `,
  variables: { project: 'rmediation' }
})
```

**Pros:**

- ✅ Flexible queries
- ✅ Type system
- ✅ Efficient data fetching

**Cons:**

- ❌ Too complex for simple CRUD operations
- ❌ Requires GraphQL server
- ❌ Learning curve for users
- ❌ Overkill for local tool

### Option 3: Node.js Module API (Functions) ✅ CHOSEN

```javascript
// User code
import { createSession } from 'flow-cli'

const session = await createSession({
  project: 'rmediation',
  task: 'Fix bug #123'
})

console.log(session.id)
```

**Pros:**

- ✅ Simple and direct (just function calls)
- ✅ Fast (no network overhead)
- ✅ Natural JavaScript (async/await)
- ✅ Easy error handling (try/catch)
- ✅ TypeScript-friendly
- ✅ IDE autocomplete works great
- ✅ No serialization overhead

**Cons:**

- ⚠️ Node.js only (acceptable - that's our platform)
- ⚠️ Not network-capable (can add HTTP wrapper later if needed)

### Option 4: Event-Driven (EventEmitter)

```javascript
// User code
import { sessions } from 'flow-cli'

sessions.on('created', session => {
  console.log('Session created:', session.id)
})

sessions.create({ project: 'rmediation' })
```

**Pros:**

- ✅ Decoupled
- ✅ Good for reactive programming

**Cons:**

- ❌ Complex control flow
- ❌ Harder to reason about
- ❌ Not suitable for request/response pattern
- ❌ Error handling is awkward

---

## Decision Outcome

**Chosen option:** "Node.js Module API" (Option 3)

### Rationale

1. **Matches Use Case Perfectly**
   The flow-cli is a local Node.js tool, not a web service. Users import it as a module, so exposing functions is the most natural API:

   ```javascript
   // Natural for Node.js users
   import { detectProjectType, createSession } from 'flow-cli'

   const type = await detectProjectType('/path/to/project')
   const session = await createSession({ project: 'rmediation' })
   ```

2. **Performance**
   Direct function calls are orders of magnitude faster than HTTP:

   ```javascript
   // Module API: ~1ms
   const type = await detectProjectType(path)

   // vs. HTTP API: ~50-100ms (network + serialization)
   const res = await fetch('http://localhost:3000/detect', {
     method: 'POST',
     body: JSON.stringify({ path })
   })
   ```

3. **Developer Experience**
   - IDE autocomplete works perfectly
   - TypeScript definitions integrate seamlessly
   - Errors are native JavaScript exceptions (natural try/catch)
   - No need to remember HTTP status codes or GraphQL syntax

4. **Simplicity**

   ```javascript
   // No boilerplate, just call the function
   try {
     const session = await createSession({ project: 'test' })
     console.log('Created:', session.id)
   } catch (error) {
     console.error('Failed:', error.message)
   }
   ```

5. **Future Flexibility**
   If we need HTTP API later, we can wrap the module functions:

   ```javascript
   // Later: Add HTTP wrapper
   // use-cases/ remain unchanged!

   // express-api/routes/sessions.js
   import { createSession } from '../../../use-cases/CreateSessionUseCase.js'

   app.post('/api/sessions', async (req, res) => {
     try {
       const session = await createSession(req.body)
       res.json({ status: 200, data: session })
     } catch (error) {
       res.status(400).json({ status: 400, error: error.message })
     }
   })
   ```

   The use cases remain pure JavaScript functions - HTTP is just another adapter!

---

## API Design Principles

### 1. **Throw Errors, Don't Return Them**

```javascript
// ❌ BAD: Error objects
function createSession(opts) {
  if (!opts.project) {
    return { success: false, error: 'Project required' }
  }
  return { success: true, data: session }
}

// ✅ GOOD: Throw exceptions
function createSession(opts) {
  if (!opts.project) {
    throw new ValidationError('Project required')
  }
  return session // Return data directly
}
```

**Why:** JavaScript has `try/catch`. Use it! Error objects force every caller to check `if (result.success)`.

### 2. **Promise Everything Async**

```javascript
// ✅ All async operations return promises
async function detectProjectType(path) {
  return await shellExec(path)
}

async function createSession(opts) {
  return await repository.save(new Session(opts))
}

// Usage with async/await
const type = await detectProjectType(path)
const session = await createSession({ project: 'test' })
```

### 3. **Parameter Objects for Flexibility**

```javascript
// ❌ BAD: Positional parameters
function createSession(project, task, branch, context) {
  // Hard to remember order, can't skip parameters
}

// ✅ GOOD: Object parameter with defaults
async function createSession({ project, task = 'Work session', branch = 'main', context = {} }) {
  // Named parameters, defaults, any order
}

// Usage
await createSession({
  project: 'rmediation',
  context: { priority: 'high' }
  // task and branch use defaults
})
```

### 4. **Return Domain Objects**

```javascript
// ❌ BAD: Return primitives
function createSession(opts) {
  return 'session-12345' // Just an ID?
}

// ✅ GOOD: Return entities
function createSession(opts) {
  return new Session({
    id: 'session-12345',
    project: opts.project,
    startTime: new Date(),
    state: SessionState.ACTIVE
  })
}

// User gets full object
const session = await createSession({ project: 'test' })
console.log(session.id) // 'session-12345'
console.log(session.startTime) // Date object
console.log(session.state) // SessionState.ACTIVE
```

### 5. **Consistent Naming**

| Pattern     | Use When                    | Example               |
| ----------- | --------------------------- | --------------------- |
| `createX()` | Create new entity           | `createSession()`     |
| `deleteX()` | Remove entity               | `deleteSession()`     |
| `updateX()` | Modify entity               | `updateSession()`     |
| `getX()`    | Get by ID (expects to find) | `getSession()`        |
| `findX()`   | Search (may not find)       | `findSession()`       |
| `listXs()`  | Get multiple                | `listSessions()`      |
| `isX()`     | Boolean check               | `isSessionActive()`   |
| `detectX()` | Analyze/discover            | `detectProjectType()` |

---

## Implementation Examples

### Example 1: Project Detection API ✅

```javascript
// cli/lib/project-detector-bridge.js

// Single detection
export async function detectProjectType(projectPath) {
  const result = await execShellScript(projectPath)
  return result.trim() || 'unknown'
}

// Batch detection
export async function detectMultipleProjects(projectPaths) {
  const results = await Promise.all(projectPaths.map(path => detectProjectType(path)))

  return projectPaths.reduce((acc, path, i) => {
    acc[path] = results[i]
    return acc
  }, {})
}

// Metadata queries (synchronous)
export function getSupportedTypes() {
  return ['r-package', 'quarto', 'research', 'generic', 'unknown']
}

export function isTypeSupported(type) {
  return getSupportedTypes().includes(type)
}
```

**Usage:**

```javascript
import { detectProjectType, detectMultipleProjects, getSupportedTypes } from 'flow-cli'

// Single
const type = await detectProjectType('/path/to/rmediation')
console.log(type) // 'r-package'

// Batch
const results = await detectMultipleProjects(['/path/to/rmediation', '/path/to/quarto-doc'])
console.log(results)
// { '/path/to/rmediation': 'r-package', '/path/to/quarto-doc': 'quarto' }

// Metadata
const types = getSupportedTypes()
console.log(types) // ['r-package', ...]
```

### Example 2: Session Management (Future)

```javascript
// cli/use-cases/sessions/index.js

// Create
export async function createSession({ project, task, branch }) {
  if (!project) {
    throw new ValidationError('project', 'Project name required')
  }

  const session = new Session({
    id: generateId(),
    project,
    task: task || 'Work session',
    branch: branch || 'main'
  })

  await sessionRepository.save(session)
  return session
}

// End
export async function endSession(sessionId) {
  const session = await sessionRepository.findById(sessionId)
  if (!session) {
    throw new NotFoundError('Session', sessionId)
  }

  session.end()
  await sessionRepository.save(session)
}

// Query
export async function listActiveSessions() {
  return await sessionRepository.findAll({ state: 'active' })
}
```

---

## Consequences

### Positive

- ✅ **Fast** - No network/serialization overhead
- ✅ **Simple** - Just function calls, natural JavaScript
- ✅ **Type-safe** - TypeScript definitions work perfectly
- ✅ **IDE-friendly** - Autocomplete, go-to-definition work
- ✅ **Error handling** - Native try/catch, no status codes
- ✅ **Testable** - Easy to mock/stub functions
- ✅ **Future-proof** - Can wrap with HTTP layer later

### Negative

- ⚠️ **Node.js only** - Not callable from other languages (acceptable)
- ⚠️ **Local only** - No network access (can add later)

### Neutral

- ℹ️ **HTTP later** - If needed, wrap use cases with Express/Fastify
- ℹ️ **Documentation** - Need good JSDoc comments (automated tooling)

---

## Validation

### Success Criteria

- [x] All async operations return Promises
- [x] Errors throw exceptions (not returned in objects)
- [x] Functions use parameter objects for > 2 params
- [x] Return types are domain objects (not primitives)
- [x] Naming follows conventions (create/delete/get/find/is/list)
- [x] JSDoc comments on all public functions
- [x] TypeScript definitions provided (.d.ts files)

### API Review Checklist

```javascript
// ✓ Async with promises
async function createSession(opts) { }

// ✓ Throws errors
if (!opts.project) throw new ValidationError(...)

// ✓ Parameter object
function createSession({ project, task = 'Work' }) { }

// ✓ Returns domain object
return new Session(...)

// ✓ Consistent naming
createSession(), deleteSession(), listSessions()

// ✓ JSDoc
/**
 * Create a new work session
 * @param {Object} options
 * @param {string} options.project - Project name
 * @returns {Promise<Session>}
 */
```

---

## Related Decisions

- **ADR-002**: Clean Architecture - Use cases are pure functions (perfect for module API)
- **Future ADR**: HTTP API Wrapper (if we add REST endpoint later)
- **Future ADR**: GraphQL Layer (if we add GraphQL later)

---

## References

**Best Practices:**

- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)
- [API Design Guide](https://github.com/microsoft/api-guidelines)
- [Promise Patterns](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises)

**Internal Docs:**

- [API-DESIGN-REVIEW.md](../API-DESIGN-REVIEW.md) - Full API review
- [API-DESIGN-QUICK-REFERENCE.md](../API-DESIGN-QUICK-REFERENCE.md) - Cheat sheet

---

**Last Updated:** 2025-12-23
**Next Review:** 2026-01-20 (after adding HTTP wrapper, if needed)
