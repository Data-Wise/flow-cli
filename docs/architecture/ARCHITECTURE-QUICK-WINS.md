# Architecture Quick Wins

**Practical architecture patterns you can use TODAY**

This guide extracts the most immediately useful patterns from our comprehensive architecture documentation. Perfect for daily development when you need a quick answer.

**Last Updated:** 2025-12-21
**For Full Details:** See [Architecture Hub](README.md)

---

## 📋 Table of Contents

- [Error Handling](#error-handling)
- [Input Validation](#input-validation)
- [Bridge Pattern (JS ↔ Shell)](#bridge-pattern-js-shell)
- [Repository Pattern](#repository-pattern)
- [TypeScript Definitions](#typescript-definitions)
- [Testing Patterns](#testing-patterns)
- [File Organization](#file-organization)

---

## Error Handling

### Quick Win: Semantic Error Classes

**Problem:** Generic `Error` doesn't convey meaning
**Solution:** Create semantic error hierarchy

```javascript
// lib/errors.js

export class ZshConfigError extends Error {
  constructor(message, code) {
    super(message)
    this.name = 'ZshConfigError'
    this.code = code
  }
}

export class ValidationError extends ZshConfigError {
  constructor(field, message) {
    super(`Validation failed for ${field}: ${message}`, 'VALIDATION_ERROR')
    this.field = field
  }
}

export class NotFoundError extends ZshConfigError {
  constructor(resource, id) {
    super(`${resource} not found: ${id}`, 'NOT_FOUND')
    this.resource = resource
    this.id = id
  }
}

export class ShellExecutionError extends ZshConfigError {
  constructor(command, exitCode, stderr) {
    super(`Shell execution failed: ${command}`, 'SHELL_ERROR')
    this.command = command
    this.exitCode = exitCode
    this.stderr = stderr
  }
}
```

**Usage:**

```javascript
import { ValidationError, NotFoundError } from './lib/errors.js'

// Throw semantic errors
throw new ValidationError('projectPath', 'must be absolute path')
throw new NotFoundError('Session', sessionId)

// Catch by type
try {
  await detector.detect(path)
} catch (error) {
  if (error instanceof ValidationError) {
    console.error(`Invalid input: ${error.message}`)
  } else if (error instanceof NotFoundError) {
    console.error(`Resource missing: ${error.message}`)
  }
}
```

**Benefits:**

- ✅ Self-documenting error types
- ✅ Easy to catch specific errors
- ✅ Better error messages for users

---

## Input Validation

### Quick Win: Fail-Fast Validation Functions

**Problem:** Validation scattered throughout code
**Solution:** Centralized validation utilities

```javascript
// lib/validation.js

export function validatePath(path, fieldName = 'path') {
  if (!path) {
    throw new ValidationError(fieldName, 'is required')
  }
  if (typeof path !== 'string') {
    throw new ValidationError(fieldName, 'must be a string')
  }
  if (!path.trim()) {
    throw new ValidationError(fieldName, 'cannot be empty')
  }
  return path
}

export function validateAbsolutePath(path, fieldName = 'path') {
  validatePath(path, fieldName)
  if (!path.startsWith('/')) {
    throw new ValidationError(fieldName, 'must be absolute path')
  }
  return path
}

export function validateEnum(value, allowedValues, fieldName = 'value') {
  if (!allowedValues.includes(value)) {
    throw new ValidationError(fieldName, `must be one of: ${allowedValues.join(', ')}`)
  }
  return value
}

export function validateObject(obj, fieldName = 'object') {
  if (!obj || typeof obj !== 'object') {
    throw new ValidationError(fieldName, 'must be an object')
  }
  return obj
}
```

**Usage:**

```javascript
import { validateAbsolutePath, validateEnum } from './lib/validation.js'

export async function detectProjectType(projectPath, options = {}) {
  // Validate at entry point
  validateAbsolutePath(projectPath, 'projectPath')

  if (options.format) {
    validateEnum(options.format, ['json', 'text'], 'options.format')
  }

  // Now safe to proceed
  const type = await detector.detect(projectPath)
  return type
}
```

**Benefits:**

- ✅ Consistent validation across codebase
- ✅ Clear error messages
- ✅ Fail fast (errors at API boundary)

---

## Bridge Pattern (JS ↔ Shell)

### Quick Win: Shell Script Adapter

**Problem:** Need to call shell scripts from Node.js
**Solution:** Bridge pattern with error transformation

```javascript
// lib/shell-bridge.js

import { exec } from 'child_process'
import { promisify } from 'util'
import { ShellExecutionError } from './errors.js'

const execAsync = promisify(exec)

/**
 * Execute shell script and return stdout
 *
 * @param {string} scriptPath - Absolute path to shell script
 * @param {string} functionName - Function to call
 * @param {string[]} args - Arguments to pass
 * @returns {Promise<string>} - Trimmed stdout
 * @throws {ShellExecutionError} - On execution failure
 */
export async function executeShellFunction(scriptPath, functionName, args = []) {
  try {
    const argsString = args.map(arg => `"${arg}"`).join(' ')
    const command = `source "${scriptPath}" && ${functionName} ${argsString}`

    const { stdout, stderr } = await execAsync(command, {
      shell: '/bin/zsh',
      timeout: 5000 // 5 second timeout
    })

    // Log warnings but don't fail
    if (stderr) {
      console.error(`Warning from ${functionName}: ${stderr}`)
    }

    return stdout.trim()
  } catch (error) {
    // Transform to semantic error
    throw new ShellExecutionError(
      `${functionName} ${args.join(' ')}`,
      error.code || 1,
      error.stderr || error.message
    )
  }
}

/**
 * Execute shell script with graceful fallback
 */
export async function executeShellFunctionSafe(
  scriptPath,
  functionName,
  args = [],
  fallback = null
) {
  try {
    return await executeShellFunction(scriptPath, functionName, args)
  } catch (error) {
    console.error(`Shell execution failed, using fallback: ${error.message}`)
    return fallback
  }
}
```

**Usage:**

```javascript
import { executeShellFunction, executeShellFunctionSafe } from './lib/shell-bridge.js'

// Strict execution (throws on error)
const result = await executeShellFunction('/path/to/script.sh', 'get_project_type', [
  '/path/to/project'
])

// Graceful execution (returns fallback on error)
const type = await executeShellFunctionSafe(
  '/path/to/detector.sh',
  'get_project_type',
  ['/path/to/project'],
  'unknown' // fallback
)
```

**Benefits:**

- ✅ Clean separation JS ↔ Shell
- ✅ Consistent error handling
- ✅ Graceful degradation option

---

## Repository Pattern

### Quick Win: In-Memory Repository

**Problem:** Hard to test code that writes to file system
**Solution:** Repository pattern with in-memory implementation

```javascript
// lib/session-repository.js

/**
 * Repository interface (use for dependency injection)
 */
export class SessionRepository {
  async save(session) {
    throw new Error('Not implemented')
  }
  async findById(id) {
    throw new Error('Not implemented')
  }
  async findAll() {
    throw new Error('Not implemented')
  }
  async delete(id) {
    throw new Error('Not implemented')
  }
}

/**
 * In-memory implementation (perfect for tests)
 */
export class InMemorySessionRepository extends SessionRepository {
  constructor() {
    super()
    this.sessions = new Map()
  }

  async save(session) {
    this.sessions.set(session.id, { ...session })
    return session
  }

  async findById(id) {
    const session = this.sessions.get(id)
    return session ? { ...session } : null
  }

  async findAll() {
    return Array.from(this.sessions.values()).map(s => ({ ...s }))
  }

  async delete(id) {
    return this.sessions.delete(id)
  }
}

/**
 * File system implementation (production)
 */
export class FileSystemSessionRepository extends SessionRepository {
  constructor(storageDir) {
    super()
    this.storageDir = storageDir
  }

  async save(session) {
    const filePath = path.join(this.storageDir, `${session.id}.json`)
    await fs.writeFile(filePath, JSON.stringify(session, null, 2))
    return session
  }

  async findById(id) {
    try {
      const filePath = path.join(this.storageDir, `${id}.json`)
      const data = await fs.readFile(filePath, 'utf-8')
      return JSON.parse(data)
    } catch (error) {
      if (error.code === 'ENOENT') return null
      throw error
    }
  }

  // ... similar implementations
}
```

**Usage:**

```javascript
// Production: use file system
const repo = new FileSystemSessionRepository('~/.zsh-config/sessions')

// Tests: use in-memory
const repo = new InMemorySessionRepository()

// Same API for both!
await repo.save({ id: '123', name: 'My Session' })
const session = await repo.findById('123')
```

**Benefits:**

- ✅ Testable without file I/O
- ✅ Swap implementations easily
- ✅ Clear interface

---

## TypeScript Definitions

### Quick Win: .d.ts for IDE Support

**Problem:** No autocomplete in VS Code for JavaScript
**Solution:** Add `.d.ts` files (no TypeScript conversion needed!)

```typescript
// lib/project-detector.d.ts

/**
 * Detect project type from directory
 *
 * @param projectPath - Absolute path to project directory
 * @returns Promise resolving to project type
 * @throws {ValidationError} If path is invalid
 * @throws {ShellExecutionError} If detection fails
 */
export function detectProjectType(projectPath: string): Promise<string>

/**
 * Detect project type with fallback
 *
 * @param projectPath - Absolute path to project directory
 * @param fallback - Value to return on error (default: 'unknown')
 * @returns Promise resolving to project type or fallback
 */
export function detectProjectTypeSafe(projectPath: string, fallback?: string): Promise<string>

/**
 * Get project metadata
 */
export interface ProjectMetadata {
  type: string
  path: string
  name: string
  icon?: string
}

export function getProjectMetadata(projectPath: string): Promise<ProjectMetadata>
```

**Benefits:**

- ✅ Autocomplete in VS Code
- ✅ Parameter hints
- ✅ Type checking (optional)
- ✅ No need to convert to TypeScript!

**How to add:**

1. Create `.d.ts` file next to `.js` file
2. Add type definitions
3. VS Code automatically picks them up
4. Keep writing JavaScript!

---

## Testing Patterns

### Quick Win: Test Structure

**Problem:** Tests hard to write and maintain
**Solution:** Clear test structure with arrange-act-assert

```javascript
// test/test-project-detector.js

import { strict as assert } from 'assert'
import { detectProjectType } from '../lib/project-detector.js'
import { ValidationError } from '../lib/errors.js'

describe('Project Detector', () => {
  describe('detectProjectType()', () => {
    it('should detect R package from DESCRIPTION file', async () => {
      // ARRANGE
      const testPath = '/path/to/test/r-package'

      // ACT
      const type = await detectProjectType(testPath)

      // ASSERT
      assert.strictEqual(type, 'r-package')
    })

    it('should throw ValidationError for empty path', async () => {
      // ARRANGE
      const invalidPath = ''

      // ACT & ASSERT
      await assert.rejects(async () => await detectProjectType(invalidPath), ValidationError)
    })

    it('should throw ValidationError for relative path', async () => {
      // ARRANGE
      const relativePath = 'relative/path'

      // ACT & ASSERT
      await assert.rejects(
        async () => await detectProjectType(relativePath),
        error => {
          assert(error instanceof ValidationError)
          assert(error.message.includes('absolute path'))
          return true
        }
      )
    })
  })

  describe('Integration Tests', () => {
    it('should detect all project types in test fixtures', async () => {
      const fixtures = [
        { path: '/fixtures/r-package', expected: 'r-package' },
        { path: '/fixtures/quarto-ext', expected: 'quarto-extension' },
        { path: '/fixtures/node-app', expected: 'node' }
      ]

      for (const { path, expected } of fixtures) {
        const actual = await detectProjectType(path)
        assert.strictEqual(actual, expected, `Failed for ${path}`)
      }
    })
  })
})
```

**Benefits:**

- ✅ Clear test structure (Arrange-Act-Assert)
- ✅ Good test names (should...)
- ✅ Proper error testing
- ✅ Integration test examples

---

## File Organization

### Quick Win: Layer-Based Structure

**Problem:** Files scattered everywhere
**Solution:** Organize by architectural layer

```
lib/
├── domain/               # Business logic (no dependencies)
│   ├── session.js        # Session entity
│   ├── project.js        # Project entity
│   └── errors.js         # Domain errors
│
├── use-cases/            # Application logic
│   ├── create-session.js
│   ├── detect-project.js
│   └── list-sessions.js
│
├── adapters/             # External integrations
│   ├── shell-bridge.js   # Shell script adapter
│   ├── fs-repository.js  # File system adapter
│   └── in-memory-repo.js # Test adapter
│
└── utils/                # Shared utilities
    ├── validation.js
    └── logging.js

cli/
├── adapters/             # CLI-specific adapters
│   ├── project-detector-adapter.js
│   └── session-manager-adapter.js
│
└── commands/             # CLI commands
    ├── detect.js
    └── session.js

test/
├── unit/                 # Fast, isolated tests
├── integration/          # Multi-component tests
└── fixtures/             # Test data
```

**Benefits:**

- ✅ Clear separation of concerns
- ✅ Easy to find files
- ✅ Testable layers
- ✅ Follows Clean Architecture

---

## Copy-Paste Checklist

When implementing a new feature, use this checklist:

### 1. Start with Errors

- [ ] Copy error classes from [Error Handling](#error-handling)
- [ ] Add semantic errors for your domain

### 2. Add Validation

- [ ] Copy validation functions from [Input Validation](#input-validation)
- [ ] Validate at API entry points

### 3. Choose Storage Pattern

- [ ] Need file I/O? Use [Repository Pattern](#repository-pattern)
- [ ] Need shell scripts? Use [Bridge Pattern](#bridge-pattern-js-shell)

### 4. Add Types (Optional)

- [ ] Copy `.d.ts` template from [TypeScript Definitions](#typescript-definitions)
- [ ] Add type definitions for IDE support

### 5. Write Tests

- [ ] Copy test structure from [Testing Patterns](#testing-patterns)
- [ ] Write unit tests (in-memory adapters)
- [ ] Write integration tests (real adapters)

### 6. Organize Files

- [ ] Follow [File Organization](#file-organization) structure
- [ ] Put domain logic in `lib/domain/`
- [ ] Put use cases in `lib/use-cases/`
- [ ] Put adapters in `lib/adapters/`

---

## Quick Reference

| Need to...               | Use this pattern     | Example                                            |
| ------------------------ | -------------------- | -------------------------------------------------- |
| **Throw semantic error** | Error classes        | `throw new ValidationError('path', 'is required')` |
| **Validate input**       | Validation utilities | `validateAbsolutePath(path)`                       |
| **Call shell script**    | Bridge pattern       | `executeShellFunction(script, func, args)`         |
| **Store data**           | Repository pattern   | `repo.save(session)`                               |
| **Add IDE support**      | `.d.ts` files        | Create `file.d.ts` next to `file.js`               |
| **Write tests**          | AAA pattern          | Arrange → Act → Assert                             |
| **Organize files**       | Layer structure      | `lib/domain/`, `lib/use-cases/`, `lib/adapters/`   |

---

## Related Documentation

**For deeper understanding:**

- [Architecture Patterns Analysis](ARCHITECTURE-PATTERNS-ANALYSIS.md) - Full Clean Architecture explanation
- [API Design Review](API-DESIGN-REVIEW.md) - API best practices
- [Code Examples](CODE-EXAMPLES.md) - 88+ production-ready examples
- [ADRs](decisions/README.md) - Why we made these decisions

**For quick reference:**

- [Architecture Quick Reference](QUICK-REFERENCE.md) - Patterns and cheatsheet

---

**Last Updated:** 2025-12-24
**Part of:** Architecture Documentation Sprint
**See Also:** [Architecture Hub](README.md)
