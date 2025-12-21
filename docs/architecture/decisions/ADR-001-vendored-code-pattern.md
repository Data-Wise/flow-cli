# ADR-001: Use Vendored Code Pattern for Project Detection

**Status:** ✅ Accepted

**Date:** 2025-12-20

**Deciders:** DT

**Technical Story:** Week 1 - Project Detection System Implementation

---

## Context and Problem Statement

The zsh-configuration system needs project detection functionality. The [zsh-claude-workflow](https://github.com/Data-Wise/zsh-claude-workflow) project already has battle-tested shell scripts (`project-detector.sh`, ~200 lines) that detect project types accurately.

**Question:** How should we integrate this existing functionality?

**Options Considered:**
1. **Git submodule** - Reference as external dependency
2. **npm package dependency** - Publish zsh-claude-workflow to npm
3. **Vendored code** - Copy scripts into our codebase
4. **Rewrite in JavaScript** - Fresh implementation

---

## Decision Drivers

- **Independence**: Should work without external tools/services
- **Simplicity**: One-command `npm install` for users
- **Reliability**: Proven detection logic (production-tested)
- **Maintainability**: Clear update process
- **Performance**: Fast detection (<50ms per project)

---

## Decision

**Chosen option: "Vendored Code Pattern"** - Copy shell scripts into `cli/vendor/zsh-claude-workflow/`

### Implementation

```
cli/vendor/zsh-claude-workflow/
├── core.sh                  # ~100 lines
├── project-detector.sh      # ~200 lines
└── README.md                # Attribution + sync process
```

### Bridge Pattern

JavaScript bridge wraps vendored scripts:

```javascript
// cli/lib/project-detector-bridge.js
export async function detectProjectType(projectPath) {
  const { stdout } = await execAsync(
    `source "${coreScript}" && source "${detectorScript}" && cd "${projectPath}" && get_project_type`,
    { shell: '/bin/zsh' }
  );
  return mapProjectType(stdout.trim());
}
```

---

## Consequences

### Positive

- ✅ **Zero runtime dependencies** - No external tools required
- ✅ **Simple installation** - `npm install` works immediately
- ✅ **Guaranteed availability** - Code can't disappear or break
- ✅ **Version control** - All code tracked in our repository
- ✅ **Production-tested** - Leverage existing battle-tested logic
- ✅ **Fast implementation** - 2 hours vs 8+ hours for rewrite

### Negative

- ⚠️ **Code duplication** - ~300 lines duplicated across projects
- ⚠️ **Manual syncing** - Must manually update when upstream changes
- ⚠️ **Attribution required** - Must maintain clear source attribution
- ⚠️ **Divergence risk** - Could drift from upstream over time

### Neutral

- 📝 **Clear sync process** - Quarterly review and update cycle
- 📝 **Test coverage** - 7/7 tests ensure behavior stays correct

---

## Validation

### Success Metrics (Week 1)

- ✅ 7/7 tests passing
- ✅ Zero external dependencies
- ✅ 2-hour implementation time
- ✅ 20-30ms detection latency
- ✅ Clear attribution in vendor README

### Alternative Considered: Git Submodule

**Rejected because:**
- Requires users to run `git submodule update --init`
- Complicates npm installation
- Fragile when repository moves
- Not suitable for npm-published packages

### Alternative Considered: npm Dependency

**Rejected because:**
- Requires publishing zsh-claude-workflow to npm
- Adds external dependency (defeats independence goal)
- Version management complexity
- Overhead for ~300 lines of code

### Alternative Considered: JavaScript Rewrite

**Rejected because:**
- 8+ hours estimated implementation time
- Risk of logic errors (vs proven code)
- Must maintain feature parity
- No performance benefit

---

## Related Decisions

- [ADR-002: Clean Architecture Layers](ADR-002-clean-architecture.md)
- [ADR-003: Bridge Pattern for Shell Integration](ADR-003-bridge-pattern.md)

---

## Notes

### Update Process

```bash
# Quarterly sync (every 3 months)
cp ~/projects/dev-tools/zsh-claude-workflow/lib/project-detector.sh cli/vendor/zsh-claude-workflow/
cp ~/projects/dev-tools/zsh-claude-workflow/lib/core.sh cli/vendor/zsh-claude-workflow/
npm run test:detector  # Ensure tests pass
# Update version in vendor README
git commit -m "chore: sync vendored code from zsh-claude-workflow v1.X.0"
```

### Attribution

All vendored files include:
- Source URL
- Original author
- License (MIT)
- Last sync date
- Version number

---

**Last Updated:** 2025-12-21
**Part of:** Documentation Sprint (Week 1)
**See Also:** [VENDOR-INTEGRATION-ARCHITECTURE.md](../VENDOR-INTEGRATION-ARCHITECTURE.md)
