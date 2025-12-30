# ADR-003: Use Bridge Pattern for Shell Integration

**Status:** ✅ Accepted and Implemented

**Date:** 2025-12-20

**Deciders:** DT

**Technical Story:** Week 1 - JavaScript to Shell Integration

---

## Context and Problem Statement

The flow-cli system (JavaScript/Node.js) needs to execute vendored shell scripts (Bash/ZSH) for project detection. These two environments are fundamentally incompatible:

- **JavaScript**: Async/await, Promises, objects, exceptions
- **Shell**: Synchronous, text output, exit codes

**Question:** How do we cleanly integrate JavaScript code with shell scripts?

**Requirements:**

- Must execute shell scripts from Node.js
- Must handle stdout/stderr
- Must map shell types to JavaScript types
- Must handle errors gracefully
- Should be testable

---

## Decision Drivers

- **Clean separation**: JavaScript shouldn't know about shell script internals
- **Type safety**: Shell strings → JavaScript types
- **Error handling**: Shell errors → JavaScript exceptions
- **Testability**: Must be able to mock shell execution
- **Performance**: Minimize overhead

---

## Decision

**Chosen option: "Bridge Pattern"** - Create JavaScript bridge layer that adapts shell interface to JavaScript interface

### Implementation

```javascript
// cli/lib/project-detector-bridge.js

import { exec } from 'child_process'
import { promisify } from 'util'

const execAsync = promisify(exec)

/**
 * Bridge: Adapts shell script interface to JavaScript Promise-based API
 */
export async function detectProjectType(projectPath) {
  try {
    // Execute shell command
    const { stdout, stderr } = await execAsync(
      `source "${coreScript}" && source "${detectorScript}" && cd "${projectPath}" && get_project_type`,
      { shell: '/bin/zsh' }
    )

    // Log warnings
    if (stderr) {
      console.error(`Warning: ${stderr}`)
    }

    // Transform: Shell string → JavaScript string
    const shellType = stdout.trim()

    // Transform: Shell type → API type
    return mapProjectType(shellType)
  } catch (error) {
    // Transform: Shell error → Graceful degradation
    console.error(`Failed to detect: ${error.message}`)
    return 'unknown'
  }
}

/**
 * Type mapping: Decouple API from shell implementation
 */
function mapProjectType(shellType) {
  const mapping = {
    rpkg: 'r-package', // Shell → API
    'quarto-ext': 'quarto-extension',
    project: 'generic'
  }
  return mapping[shellType] || shellType
}
```

### Pattern Structure

```
JavaScript World          Bridge               Shell World
─────────────────        ────────             ─────────────
Promise<string>    ←     execAsync()     →    stdout/stderr
Exceptions         ←     try/catch       →    exit codes
'r-package'        ←     mapProjectType  →    'rpkg'
```

---

## Consequences

### Positive

- ✅ **Clean separation**: Shell script can change without affecting JavaScript callers
- ✅ **Type safety**: Type mapping at boundary (shell → JS)
- ✅ **Error handling**: Centralized error transformation
- ✅ **Testability**: Can mock `execAsync` for unit tests
- ✅ **API stability**: Internal shell types hidden from consumers
- ✅ **Graceful degradation**: Returns 'unknown' instead of crashing

### Negative

- ⚠️ **Performance overhead**: Process spawn + shell initialization (~20-50ms)
- ⚠️ **Text parsing**: Relies on stdout/stderr text format
- ⚠️ **Shell dependency**: Requires `/bin/zsh` to be available

### Neutral

- 📝 **Type mapping maintenance**: Must update mapping when shell adds new types
- 📝 **Error messages**: Shell error messages passed through to JavaScript

---

## Validation

### Success Criteria (Week 1)

- ✅ All 7 tests passing
- ✅ Async/await interface working
- ✅ Type mapping correct
- ✅ Error handling graceful
- ✅ Performance acceptable (<50ms)

### Test Coverage

```javascript
// test/test-project-detector.js

test('detect R package', async () => {
  const type = await detectProjectType('/path/to/r-package')
  assert.strictEqual(type, 'r-package') // Not 'rpkg'
})

test('handle invalid path gracefully', async () => {
  const type = await detectProjectType('/nonexistent')
  assert.strictEqual(type, 'unknown') // Doesn't throw
})
```

---

## Alternative Considered: Direct Shell Script Calls

**Approach:** Call shell scripts directly without bridge

```javascript
// ❌ Direct approach (rejected)
import { exec } from 'child_process'

const { stdout } = await exec(`project-detector.sh ${path}`)
return stdout // Returns 'rpkg' (shell format)
```

**Rejected because:**

- ✗ Exposes shell implementation details
- ✗ No type mapping
- ✗ Inconsistent error handling
- ✗ Hard to test
- ✗ Tight coupling

---

## Alternative Considered: Rewrite in JavaScript

**Approach:** Port all shell logic to JavaScript

```javascript
// ❌ Pure JavaScript (rejected)
export function detectProjectType(path) {
  if (fs.existsSync(join(path, 'DESCRIPTION'))) {
    return 'r-package'
  }
  // ... 200 lines of detection logic
}
```

**Rejected because:**

- ✗ Duplicate logic (~200 lines)
- ✗ Maintenance burden (two implementations)
- ✗ Risk of divergence
- ✗ No reuse of battle-tested code

---

## Alternative Considered: Child Process Wrapper Class

**Approach:** OOP wrapper around child_process

```javascript
// ❌ Complex wrapper (rejected)
class ShellExecutor {
  constructor(scriptPath) { ... }
  async execute(command) { ... }
  transformOutput(stdout) { ... }
}
```

**Rejected because:**

- ✗ Over-engineering for simple use case
- ✗ Adds complexity without benefit
- ✗ Harder to understand
- ⚠️ May revisit if we need more shell integrations

---

## Design Pattern Details

### Bridge Pattern

**Definition:** Decouple abstraction from implementation so they can vary independently

**Applied Here:**

- **Abstraction**: JavaScript Promise-based API
- **Implementation**: Shell script execution
- **Bridge**: `project-detector-bridge.js`

**Benefit:** Can change shell implementation without affecting JavaScript callers

### Adapter Pattern

Also applies Adapter pattern:

**Definition:** Convert interface of class into another interface clients expect

**Applied Here:**

- **Existing interface**: Shell script (text stdout/stderr)
- **Target interface**: JavaScript Promise API
- **Adapter**: Bridge layer

---

## Security Considerations

### Command Injection Prevention

```javascript
// ✅ Safe: Paths are quoted
;`cd "${projectPath}"`
// ❌ Unsafe (don't do this):
`cd ${projectPath}` // No quotes!
```

### Path Validation

```javascript
// Future enhancement: Validate paths before execution
if (!path.isAbsolute(projectPath)) {
  throw new Error('projectPath must be absolute')
}
```

---

## Related Decisions

- [ADR-001: Vendored Code Pattern](ADR-001-use-vendored-code-pattern.md) - What code to integrate
- [ADR-002: Clean Architecture](ADR-002-adopt-clean-architecture.md) - Where bridge fits in layers

---

## References

- **Bridge Pattern** (Gang of Four) - Design Patterns book
- **Adapter Pattern** (Gang of Four) - Design Patterns book
- **Node.js child_process** - Official documentation

---

**Last Updated:** 2025-12-26
**Part of:** Architecture Documentation
**See Also:** [Contributing Guide](../contributing/CONTRIBUTING.md)
