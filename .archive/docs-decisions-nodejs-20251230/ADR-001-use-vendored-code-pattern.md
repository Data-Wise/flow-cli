# ADR-001: Use Vendored Code Pattern for Project Detection

**Status:** ✅ Accepted
**Date:** 2025-12-20
**Deciders:** Development Team
**Technical Story:** Week 1 - Project Detection Integration

---

## Context and Problem Statement

The flow-cli system needs to detect project types (R packages, Quarto, research projects, etc.) to provide context-aware workflows. The detection logic already exists in the `zsh-claude-workflow` repository and is battle-tested in production.

**Key Question:** Should we require users to install `zsh-claude-workflow` separately, or should we vendor (copy) the detection scripts into `flow-cli`?

---

## Decision Drivers

- **User Experience** - One-command installation (`npm install`) is critical
- **Reliability** - External dependencies can break or become unavailable
- **Maintainability** - Need clear update path for bug fixes
- **Code Reuse** - Don't want to reimplement working logic
- **Attribution** - Must properly credit original authors

---

## Considered Options

### Option 1: External Dependency

```bash
# User must install both
brew install zsh-claude-workflow
npm install flow-cli
```

**Pros:**

- Always uses latest version
- No code duplication
- Automatic updates

**Cons:**

- ❌ Two-step installation (poor UX)
- ❌ Fragile (breaks if zsh-claude-workflow not installed)
- ❌ Platform-dependent (Homebrew required)
- ❌ Hard to test in isolation

### Option 2: Reimplement in JavaScript

```javascript
// cli/lib/project-detector.js
function detectProjectType(path) {
  // Rewrite all detection logic in JS
}
```

**Pros:**

- Pure JavaScript (no shell dependency)
- Full control over implementation
- Easy to test

**Cons:**

- ❌ Code duplication (violates DRY)
- ❌ Bug fixes need to be applied twice
- ❌ Logic divergence over time
- ❌ Significant development effort

### Option 3: Vendored Code ✅ CHOSEN

```
cli/vendor/zsh-claude-workflow/
├── core.sh (~100 lines)
└── project-detector.sh (~200 lines)

cli/lib/project-detector-bridge.js
└── Calls vendored scripts via child_process
```

**Pros:**

- ✅ One-command installation (`npm install`)
- ✅ Self-contained (works everywhere npm works)
- ✅ Leverages battle-tested logic
- ✅ Clear attribution in headers
- ✅ Documented update process

**Cons:**

- ⚠️ Manual sync required for updates
- ⚠️ Slight code duplication (acceptable)

---

## Decision Outcome

**Chosen option:** "Vendored Code Pattern" (Option 3)

### Rationale

1. **User Experience First**
   Users should run `npm install flow-cli` and have a working tool immediately. External dependencies create friction.

2. **Reliability**
   Vendored code is guaranteed to be present and version-compatible. No "works on my machine" issues from mismatched external versions.

3. **Battle-Tested Logic**
   The detection logic in `zsh-claude-workflow` has been refined through production use. Reimplementing would introduce bugs and require time to stabilize.

4. **Clear Update Path**
   We document the source repository and commit hash in vendored file headers. Updates are manual but traceable:

   ```bash
   # Copy from source
   cp ~/projects/dev-tools/zsh-claude-workflow/lib/project-detector.sh \
      cli/vendor/zsh-claude-workflow/

   # Commit with attribution
   git commit -m "vendor: update project-detector from zsh-claude-workflow@abc123"
   ```

5. **Proper Attribution**
   Each vendored file includes a header:
   ```bash
   ###############################################################################
   # Vendored from: zsh-claude-workflow
   # Source: https://github.com/Data-Wise/zsh-claude-workflow
   # License: MIT
   # Last Updated: 2025-12-20
   ###############################################################################
   ```

### Implementation

```javascript
// cli/lib/project-detector-bridge.js
import { execFile } from 'child_process'
import { promisify } from 'util'
import { fileURLToPath } from 'url'
import { dirname, join } from 'path'

const execFileAsync = promisify(execFile)
const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)

const DETECTOR_SCRIPT = join(__dirname, '../vendor/zsh-claude-workflow/project-detector.sh')

export async function detectProjectType(projectPath) {
  try {
    const { stdout } = await execFileAsync('bash', [DETECTOR_SCRIPT, 'detect', projectPath])
    return stdout.trim() || 'unknown'
  } catch (error) {
    console.error('Detection failed:', error)
    return 'unknown'
  }
}
```

---

## Consequences

### Positive

- ✅ **Zero external dependencies** - Works everywhere npm works
- ✅ **Reliable** - Guaranteed version compatibility
- ✅ **Fast installation** - No multi-step setup
- ✅ **Production-tested logic** - Leverages proven detection patterns
- ✅ **Clear attribution** - Honors original authors

### Negative

- ⚠️ **Manual updates required** - Need to sync with source periodically
- ⚠️ **Code duplication** - Same logic exists in two repos (acceptable trade-off)
- ⚠️ **Shell dependency** - Still requires bash (but bash is ubiquitous)

### Neutral

- ℹ️ **Bridge pattern** - JavaScript wraps shell scripts (clean abstraction)
- ℹ️ **Version tracking** - Must document source commit hash in each update

---

## Validation

### Success Criteria (Week 1)

- [x] Vendored scripts work on macOS, Linux, Windows (WSL)
- [x] Detection accuracy matches source repository (100%)
- [x] Installation requires only `npm install` (no other steps)
- [x] Attribution headers present in all vendored files
- [x] Update process documented

### Test Results

```bash
✓ 7/7 tests passing (project-detector-bridge.test.js)
✓ Detection: R packages, Quarto, research, generic
✓ Batch detection (parallel execution)
✓ Error handling (graceful fallback to 'unknown')
✓ Metadata queries (supported types, type validation)
```

---

## Related Decisions

- **ADR-002**: Use Clean Architecture for Long-Term Maintainability
- **ADR-003**: JavaScript Bridge Pattern for Shell Integration
- **Future**: May replace with pure JavaScript implementation later

---

## References

- [zsh-claude-workflow](https://github.com/Data-Wise/zsh-claude-workflow) - Source repository
- [Vendoring Best Practices](https://github.com/golang/go/wiki/Modules#when-should-i-use-the-replace-directive) - Go community patterns

---

**Last Updated:** 2025-12-23
**Next Review:** 2026-01-20 (quarterly)
