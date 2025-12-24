# Testing Guide

Comprehensive testing documentation for flow-cli.

---

## Table of Contents

- [Overview](#overview)
- [Test Statistics](#test-statistics)
- [Test Architecture](#test-architecture)
- [Running Tests](#running-tests)
- [Writing Tests](#writing-tests)
- [Test Patterns](#test-patterns)
- [Testing Best Practices](#testing-best-practices)
- [Troubleshooting](#troubleshooting)
- [CI/CD Integration](#cicd-integration)

---

## Overview

flow-cli uses a comprehensive testing strategy with **559 tests** covering unit, integration, E2E, and benchmark testing. The test suite emphasizes:

- **Clean Architecture**: Tests isolated by layer (Domain → Use Cases → Adapters)
- **Fast Feedback**: Unit tests run in <1 second, full suite in ~6 seconds
- **Reliability**: No flaky tests - all race conditions resolved
- **Coverage**: 100% pass rate maintained throughout development

### Test Philosophy

1. **TDD-Friendly**: Tests written alongside implementation
2. **Layer Isolation**: Each architecture layer tested independently
3. **Real I/O**: Integration tests use actual file system (in temp directories)
4. **Performance**: Benchmark tests validate 10x+ speedup claims
5. **Stability**: Isolated temp directories prevent race conditions

---

## Test Statistics

### Current Status (v2.0.0-beta.1)

```
Test Suites: 27 passed, 27 total
Tests:       559 passed, 559 total
Time:        ~6 seconds
Pass Rate:   100%
Flaky Tests: 0
```

### Test Distribution

| Category              | Count   | Purpose                |
| --------------------- | ------- | ---------------------- |
| **Unit Tests**        | 265     | Pure logic, no I/O     |
| **Integration Tests** | 270     | Real file system I/O   |
| **E2E Tests**         | 14      | Full CLI execution     |
| **Benchmark Tests**   | 10      | Performance validation |
| **Total**             | **559** | **100% passing**       |

### Layer Breakdown

| Layer     | Tests | Files | Coverage                        |
| --------- | ----- | ----- | ------------------------------- |
| Domain    | 153   | 8     | Entities, Value Objects, Events |
| Use Cases | 70    | 5     | Application business rules      |
| Adapters  | 42    | 3     | File system, Container          |
| Features  | 270   | 11    | Status, Dashboard, Scanning     |
| CLI       | 14    | 1     | End-to-end commands             |
| Utils     | 10    | 3     | Filters, Cache, MRU tracker     |

---

## Test Architecture

### Directory Structure

```
tests/
├── unit/                          # Unit tests (265 tests)
│   ├── domain/                    # Domain layer (153 tests)
│   │   ├── entities/             # Session, Project, Task
│   │   ├── value-objects/        # SessionState, ProjectType
│   │   └── events/               # Domain events
│   ├── use-cases/                # Use Cases layer (70 tests)
│   │   ├── CreateSessionUseCase.test.js
│   │   ├── EndSessionUseCase.test.js
│   │   ├── ScanProjectsUseCase.test.js
│   │   ├── GetStatusUseCase.test.js
│   │   └── GetRecentProjectsUseCase.test.js
│   ├── adapters/                 # Adapters layer (42 tests)
│   │   ├── repositories/
│   │   └── Container.test.js
│   └── utils/                    # Utility tests (10 tests)
│       ├── ProjectFilters.test.js
│       ├── ProjectScanCache.test.js
│       └── MRUTracker.test.js
│
├── integration/                   # Integration tests (270 tests)
│   ├── FileSystemSessionRepository.test.js
│   ├── FileSystemProjectRepository.test.js
│   ├── status-command.test.js
│   ├── ParallelScanningWithCache.test.js
│   ├── ScanningPerformanceBenchmark.test.js
│   └── ascii-visualizations-integration.test.js
│
└── e2e/                          # End-to-end tests (24 tests)
    ├── cli.test.js               # CLI commands (14 tests)
    └── dashboard.test.js         # TUI dashboard (24 tests)
```

### Test Naming Convention

```javascript
// Format: [Component] › [Category] › [Specific Behavior]

describe('Session Entity', () => {
  describe('Creation', () => {
    test('creates session with valid data', () => { ... })
    test('rejects session with missing project', () => { ... })
  })

  describe('State Transitions', () => {
    test('transitions from active to paused', () => { ... })
  })
})
```

---

## Running Tests

### All Tests

```bash
# Run all tests (recommended)
npm test

# Run tests in watch mode
npm test -- --watch

# Run tests with coverage
npm test -- --coverage
```

### Specific Test Suites

```bash
# Run only unit tests
npm test -- tests/unit

# Run only integration tests
npm test -- tests/integration

# Run only E2E tests
npm test -- tests/e2e

# Run specific test file
npm test -- tests/unit/domain/entities/Session.test.js

# Run tests matching pattern
npm test -- --testNamePattern="Session Entity"
```

### Performance & Debugging

```bash
# Run tests serially (no parallel execution)
npm test -- --maxWorkers=1

# Detect open handles (find resource leaks)
npm test -- --detectOpenHandles

# Run with verbose output
npm test -- --verbose

# Run specific test suite multiple times (flake detection)
for i in {1..5}; do echo "Run $i"; npm test -- tests/integration/ParallelScanningWithCache.test.js; done
```

### Pre-commit Testing

Tests automatically run on commit via husky pre-commit hook:

```bash
# Bypass pre-commit hook (use sparingly)
git commit --no-verify -m "message"
```

---

## Writing Tests

### Unit Test Template

```javascript
/**
 * Unit tests for [Component Name]
 *
 * Tests pure business logic with no I/O
 */

import { describe, test, expect } from '@jest/globals'
import { ComponentName } from '../path/to/component.js'

describe('ComponentName', () => {
  describe('Feature Category', () => {
    test('should handle normal case', () => {
      // Arrange
      const input = createTestData()

      // Act
      const result = component.method(input)

      // Assert
      expect(result).toBe(expectedValue)
    })

    test('should handle edge case', () => {
      // Arrange, Act, Assert
    })

    test('should throw on invalid input', () => {
      expect(() => {
        component.method(invalidInput)
      }).toThrow('Expected error message')
    })
  })
})
```

### Integration Test Template

```javascript
/**
 * Integration tests for [Component Name]
 *
 * Tests real file system I/O in isolated temp directories
 */

import { describe, test, expect, beforeEach, afterEach } from '@jest/globals'
import { promises as fs } from 'fs'
import { join } from 'path'
import { tmpdir } from 'os'

describe('Component Integration', () => {
  let tempDir
  let component

  beforeEach(async () => {
    // Create isolated temp directory with PID + timestamp + random
    const uniqueId = `${process.pid}-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`
    tempDir = join(tmpdir(), `flow-cli-test-${uniqueId}`)
    await fs.mkdir(tempDir, { recursive: true })

    // Initialize component
    component = new Component(tempDir)
  })

  afterEach(async () => {
    // Cleanup temp directory
    try {
      await fs.rm(tempDir, { recursive: true, force: true })
    } catch (error) {
      // Ignore cleanup errors
    }
  })

  test('should persist data to file system', async () => {
    // Test implementation
  })
})
```

### E2E Test Template

```javascript
/**
 * End-to-end tests for CLI commands
 *
 * Tests actual binary execution
 */

import { describe, test, expect } from '@jest/globals'
import { exec } from 'child_process'
import { promisify } from 'util'

const execAsync = promisify(exec)

describe('CLI Commands', () => {
  test('should execute command successfully', async () => {
    const { stdout, stderr } = await execAsync('flow status --help')

    expect(stderr).toBe('')
    expect(stdout).toContain('Usage: flow status')
  })

  test('should return correct exit code', async () => {
    try {
      await execAsync('flow unknown-command')
      fail('Should have thrown')
    } catch (error) {
      expect(error.code).toBe(1)
    }
  })
})
```

### Benchmark Test Template

```javascript
/**
 * Performance benchmark tests
 *
 * Validates performance claims (10x+ speedup, etc.)
 */

describe('Performance Benchmarks', () => {
  test('should achieve 10x+ speedup with cache', async () => {
    // First scan (no cache)
    const uncachedStart = Date.now()
    await repository.scan(projectsDir)
    const uncachedTime = Date.now() - uncachedStart

    // Cached scan
    const cachedStart = Date.now()
    await repository.scan(projectsDir)
    const cachedTime = Date.now() - cachedStart

    // Calculate speedup
    const speedup = uncachedTime / Math.max(cachedTime, 1)

    console.log(`Speedup: ${speedup.toFixed(1)}x faster with cache`)
    expect(speedup).toBeGreaterThanOrEqual(10)
  })
})
```

---

## Test Patterns

### 1. Arrange-Act-Assert (AAA)

```javascript
test('calculates session duration correctly', () => {
  // Arrange - Set up test data
  const session = new Session('s1', 'project', 'task')
  session.startTime = new Date('2025-01-01T10:00:00Z')
  session.endTime = new Date('2025-01-01T10:30:00Z')

  // Act - Execute the behavior
  const duration = session.getDuration()

  // Assert - Verify the outcome
  expect(duration).toBe(30) // 30 minutes
})
```

### 2. Test Doubles (Mocks, Stubs, Spies)

```javascript
// Mock repository for use case testing
const mockRepository = {
  findActive: jest.fn(),
  save: jest.fn(),
  list: jest.fn()
}

test('creates session when no active session exists', async () => {
  // Stub - Return predetermined value
  mockRepository.findActive.mockResolvedValue(null)
  mockRepository.save.mockResolvedValue(undefined)

  const useCase = new CreateSessionUseCase(mockRepository)
  const result = await useCase.execute({ project: 'test', task: 'work' })

  // Spy - Verify method was called
  expect(mockRepository.save).toHaveBeenCalledTimes(1)
  expect(result.success).toBe(true)
})
```

### 3. Isolated Temp Directories

**Critical for preventing race conditions in parallel test execution:**

```javascript
beforeEach(async () => {
  // ALWAYS use PID + timestamp + random for true isolation
  const uniqueId = `${process.pid}-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`
  tempDir = join(tmpdir(), `flow-cli-test-${uniqueId}`)
  await fs.mkdir(tempDir, { recursive: true })
})

afterEach(async () => {
  // ALWAYS cleanup, even on test failure
  try {
    await fs.rm(tempDir, { recursive: true, force: true })
  } catch (error) {
    // Ignore cleanup errors (directory may not exist)
  }
})
```

**Why this pattern:**

- `process.pid` - Different value per Jest worker process
- `Date.now()` - Millisecond timestamp
- `Math.random()` - Additional uniqueness (7 random chars)
- Result: Zero collisions even with 100+ parallel tests

### 4. Async Testing

```javascript
// Use async/await for all async operations
test('loads project from file', async () => {
  await repository.save(project)
  const loaded = await repository.findById(project.id)
  expect(loaded.name).toBe(project.name)
})

// Handle rejections
test('throws on invalid data', async () => {
  await expect(repository.save(invalidProject)).rejects.toThrow('Invalid project data')
})
```

### 5. Parameterized Tests

```javascript
// Test multiple scenarios with same logic
const testCases = [
  { type: ProjectType.NODE, marker: 'package.json' },
  { type: ProjectType.R_PACKAGE, marker: 'DESCRIPTION' },
  { type: ProjectType.PYTHON, marker: 'pyproject.toml' }
]

testCases.forEach(({ type, marker }) => {
  test(`detects ${type} projects`, async () => {
    await fs.writeFile(join(projectDir, marker), '')
    const detected = await repository.detectType(projectDir)
    expect(detected).toBe(type)
  })
})
```

### 6. Timeout Handling

```javascript
// Extend timeout for slow operations
test('handles large project scan', async () => {
  // Create 1000 test projects
  for (let i = 0; i < 1000; i++) {
    await createProject(i)
  }

  const result = await repository.scan(projectsDir)
  expect(result.length).toBe(1000)
}, 30000) // 30 second timeout
```

---

## Testing Best Practices

### ✅ DO

1. **Test behavior, not implementation**

   ```javascript
   // Good - Tests behavior
   test('filters active projects', () => {
     const projects = [active, inactive, active]
     const result = ProjectFilters.active()(projects)
     expect(result.length).toBe(2)
   })

   // Bad - Tests implementation details
   test('calls internal _filterByDate method', () => {
     // Don't test private methods
   })
   ```

2. **Use descriptive test names**

   ```javascript
   // Good
   test('returns empty array when no projects match filter', () => { ... })

   // Bad
   test('filter test', () => { ... })
   ```

3. **One assertion per concept**

   ```javascript
   // Good - Tests one concept
   test('creates session with correct initial state', () => {
     const session = new Session('s1', 'project', 'task')
     expect(session.state.value).toBe('active')
   })

   test('creates session with current timestamp', () => {
     const session = new Session('s1', 'project', 'task')
     expect(session.startTime).toBeInstanceOf(Date)
   })

   // Bad - Tests multiple unrelated things
   test('session creation', () => {
     const session = new Session('s1', 'project', 'task')
     expect(session.state.value).toBe('active')
     expect(session.startTime).toBeInstanceOf(Date)
     expect(session.getDuration()).toBe(0)
     expect(session.project).toBe('project')
     // ... 10 more assertions
   })
   ```

4. **Test edge cases**

   ```javascript
   test('handles empty array', () => { ... })
   test('handles null input', () => { ... })
   test('handles maximum value', () => { ... })
   test('handles concurrent modifications', () => { ... })
   ```

5. **Clean up resources**
   ```javascript
   afterEach(async () => {
     await fs.rm(tempDir, { recursive: true, force: true })
   })
   ```

### ❌ DON'T

1. **Don't use `Date.now()` alone for temp directories**

   ```javascript
   // Bad - Race conditions in parallel execution
   tempDir = join(tmpdir(), `test-${Date.now()}`)

   // Good - True isolation
   const uniqueId = `${process.pid}-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`
   tempDir = join(tmpdir(), `test-${uniqueId}`)
   ```

2. **Don't test implementation details**

   ```javascript
   // Bad
   expect(component._privateMethod).toHaveBeenCalled()

   // Good
   expect(component.publicMethod()).toBe(expectedResult)
   ```

3. **Don't use long timeouts as band-aids**

   ```javascript
   // Bad - Hiding real issues
   test('slow operation', async () => {
     await slowOperation()
   }, 60000) // 60 seconds!

   // Good - Fix the root cause or use mocks
   test('operation completes quickly', async () => {
     await mockedFastOperation()
   })
   ```

4. **Don't share state between tests**

   ```javascript
   // Bad - Tests affect each other
   let sharedCounter = 0
   test('increments counter', () => {
     sharedCounter++
     expect(sharedCounter).toBe(1) // Fails on second run!
   })

   // Good - Each test is isolated
   test('increments counter', () => {
     let counter = 0
     counter++
     expect(counter).toBe(1)
   })
   ```

5. **Don't skip cleanup on failure**

   ```javascript
   // Bad - Leaves files on disk
   afterEach(async () => {
     await fs.rm(tempDir, { recursive: true })
   })

   // Good - Cleanup even on errors
   afterEach(async () => {
     try {
       await fs.rm(tempDir, { recursive: true, force: true })
     } catch (error) {
       // Ignore cleanup errors
     }
   })
   ```

---

## Troubleshooting

### Flaky Tests

**Symptom:** Test passes when run alone but fails in parallel execution

**Common Causes:**

1. **Temp directory collisions**

   ```javascript
   // Fix: Use PID + timestamp + random
   const uniqueId = `${process.pid}-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`
   tempDir = join(tmpdir(), `flow-cli-test-${uniqueId}`)
   ```

2. **Shared state between tests**

   ```javascript
   // Fix: Use beforeEach to reset state
   beforeEach(() => {
     component = new Component()
   })
   ```

3. **Race conditions in cleanup**
   ```javascript
   // Fix: Ensure directory exists before second operation
   await fs.mkdir(tempDir, { recursive: true })
   await fs.writeFile(join(tempDir, 'file'), 'data')
   ```

### Detecting Flaky Tests

```bash
# Run test suite multiple times
for i in {1..10}; do
  echo "Run $i"
  npm test || echo "FAILED on run $i"
done

# Run with detect-open-handles
npm test -- --detectOpenHandles

# Run serially to isolate parallel issues
npm test -- --maxWorkers=1
```

### Slow Tests

**Target:** Full suite should run in < 10 seconds

**Optimization strategies:**

1. **Use mocks for expensive operations**

   ```javascript
   // Before: Real file I/O (~100ms)
   const data = await fs.readFile(largeFile)

   // After: Mocked I/O (<1ms)
   const mockFs = { readFile: jest.fn().mockResolvedValue(mockData) }
   ```

2. **Reduce test data size**

   ```javascript
   // Before: 1000 projects
   for (let i = 0; i < 1000; i++) await createProject(i)

   // After: 10 projects (enough to test behavior)
   for (let i = 0; i < 10; i++) await createProject(i)
   ```

3. **Run tests in parallel**
   ```javascript
   // Jest runs tests in parallel by default
   // Don't use --maxWorkers=1 unless necessary
   ```

### Memory Leaks

**Detecting leaks:**

```bash
# Run with heap snapshot
node --expose-gc --inspect ./node_modules/.bin/jest --runInBand --logHeapUsage
```

**Common causes:**

1. **Unclosed file handles**
2. **Event listeners not removed**
3. **Timers not cleared**

**Fixes:**

```javascript
afterEach(() => {
  // Clear timers
  jest.clearAllTimers()

  // Remove event listeners
  emitter.removeAllListeners()

  // Close file handles
  await fileHandle.close()
})
```

---

## CI/CD Integration

### GitHub Actions

Tests run automatically on:

- Every push to `main` or `dev` branches
- Every pull request
- Before semantic-release

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: 20
      - run: npm install
      - run: npm test
```

### Pre-commit Hook

Tests run automatically before every commit:

```bash
# .husky/pre-commit
npm test
```

**Bypass (use sparingly):**

```bash
git commit --no-verify -m "message"
```

### Test Coverage

```bash
# Generate coverage report
npm test -- --coverage

# View HTML report
open coverage/lcov-report/index.html
```

---

## Performance Benchmarks

### Benchmark Test Results

| Operation                  | Without Cache | With Cache | Speedup  |
| -------------------------- | ------------- | ---------- | -------- |
| Project scan (60 projects) | ~3ms          | <1ms       | **10x+** |
| Status command             | 80ms          | 40ms       | **2x**   |
| Project filters            | 5ms           | 1ms        | **5x**   |

### Running Benchmarks

```bash
# Run all benchmark tests
npm test -- tests/integration/ScanningPerformanceBenchmark.test.js

# Sample output:
# Without cache: 3.33ms avg
# With cache:    0.00ms avg
# Speedup:       Infinityx faster
# ✅ Target achieved: 10x+ speedup with caching
```

---

## Test Coverage Goals

### Current Coverage (v2.0.0-beta.1)

- **Domain Layer**: 100% (all entities, value objects, events)
- **Use Cases Layer**: 100% (all use cases)
- **Adapters Layer**: 95% (file system operations, some edge cases excluded)
- **Overall**: ~98%

### Coverage Targets

| Layer        | Target | Current | Status |
| ------------ | ------ | ------- | ------ |
| Domain       | 100%   | 100%    | ✅     |
| Use Cases    | 100%   | 100%    | ✅     |
| Adapters     | 90%+   | 95%     | ✅     |
| CLI Commands | 80%+   | 85%     | ✅     |
| Overall      | 90%+   | 98%     | ✅     |

---

## Additional Resources

- **Jest Documentation**: https://jestjs.io/docs/getting-started
- **Clean Architecture Testing**: https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html
- **Test Doubles**: https://martinfowler.com/bliki/TestDouble.html
- **TDD Best Practices**: https://www.jamesshore.com/v2/books/aoad1/test_driven_development

---

## Contributing

When adding new features:

1. **Write tests first** (TDD approach)
2. **Maintain 100% pass rate** (no broken tests)
3. **Add integration tests** for file I/O operations
4. **Add benchmark tests** for performance claims
5. **Update this document** with new patterns

**Test Requirements for PR Approval:**

- ✅ All 559 existing tests must pass
- ✅ New features must include tests
- ✅ Test coverage must not decrease
- ✅ No flaky tests (run suite 3x to verify)

---

**Last Updated:** 2025-12-24
**Test Count:** 559 tests (100% passing)
**Version:** v2.0.0-beta.1
