# Plan A: Documentation Polish - Implementation

**Date:** 2025-12-24
**Effort:** 30-50 minutes
**Status:** In Progress

---

## Issues Identified

### 1. Duplicate/Inconsistent ADR Files ❌

**Problem:** Multiple versions of the same ADR exist with different content:

| Shorter Name (in mkdocs.yml)                           | Longer Name (not linked)                                     | Issue                                                     |
| ------------------------------------------------------ | ------------------------------------------------------------ | --------------------------------------------------------- |
| ADR-001-vendored-code-pattern.md (166 lines)           | ADR-001-use-vendored-code-pattern.md (227 lines)             | Longer version has more content                           |
| ADR-002-clean-architecture.md (255 lines, 🟡 Proposed) | ADR-002-adopt-clean-architecture.md (376 lines, ✅ Accepted) | **WRONG VERSION IN NAV** - implemented version not linked |
| ADR-003-bridge-pattern.md (296 lines)                  | ADR-003-nodejs-module-api-not-rest.md (504 lines)            | Different topics entirely                                 |

**Root Cause:** ADRs were created/updated at different times, creating multiple versions

### 2. Outdated Documentation Indexes

**doc-index.md:**

- Last updated: 2025-12-19 (before Phase P6 completion)
- Missing: Week 2 CLI enhancements, Production Use Phase
- Stale status markers ("Needs Review" for fixed docs)

**docs/README.md:**

- Last updated: 2025-12-20 (before API documentation generation)
- Missing: API-REFERENCE.md, INTERACTIVE-EXAMPLES.md, ARCHITECTURE-DIAGRAM.md
- Stats out of date (doesn't reflect 63-page site, 559 tests)

**docs/index.md (website home):**

- Doesn't mention Production Use Phase (started Dec 24)
- Week 2 features not highlighted in recent updates
- Quick Stats section doesn't show Phase P6 completion

### 3. Missing Cross-References

**New documentation not linked:**

- docs/api/API-REFERENCE.md (800+ lines) - not in docs/README.md
- docs/api/INTERACTIVE-EXAMPLES.md (650+ lines) - not in docs/README.md
- docs/architecture/ARCHITECTURE-DIAGRAM.md (750+ lines) - not in docs/README.md
- PRODUCTION-USE-PHASE.md - not mentioned in docs/index.md

---

## Fixes to Implement

### Fix 1: Consolidate ADR Files (20 min)

**Decision on which to keep:**

**ADR-001:**

- **KEEP:** ADR-001-use-vendored-code-pattern.md (227 lines, more comprehensive)
- **DELETE:** ADR-001-vendored-code-pattern.md (166 lines, abbreviated)
- **UPDATE:** mkdocs.yml to point to longer version

**ADR-002:**

- **KEEP:** ADR-002-adopt-clean-architecture.md (376 lines, ✅ Accepted, implemented)
- **DELETE:** ADR-002-clean-architecture.md (255 lines, 🟡 Proposed, outdated)
- **UPDATE:** mkdocs.yml to point to correct (adopted) version

**ADR-003:**

- **ISSUE:** These are DIFFERENT ADRs, not duplicates!
  - ADR-003-bridge-pattern.md - About Node.js ↔ Shell bridge
  - ADR-003-nodejs-module-api-not-rest.md - About choosing module API over REST
- **ACTION:** Rename to ADR-003 and ADR-004 (create new number)
- **DECISION:** Keep both, renumber second one

**Actions:**

```bash
# Delete outdated versions
rm docs/decisions/ADR-001-vendored-code-pattern.md
rm docs/decisions/ADR-002-clean-architecture.md

# Rename ADR-003 conflict (nodejs-module is actually different decision)
mv docs/decisions/ADR-003-nodejs-module-api-not-rest.md docs/decisions/ADR-004-module-api-not-rest.md

# Update mkdocs.yml
# Change: ADR-001-vendored-code-pattern.md → ADR-001-use-vendored-code-pattern.md
# Change: ADR-002-clean-architecture.md → ADR-002-adopt-clean-architecture.md
# Add: ADR-004 Module API (new entry)
```

### Fix 2: Update docs/doc-index.md (10 min)

**Changes needed:**

- Update "Last Updated" to 2025-12-24
- Add Phase P6 completion to statistics
- Remove stale "Needs Review" warnings (WORKFLOW-TUTORIAL.md was updated)
- Update alias count from "28" to current state
- Add Production Use Phase section

### Fix 3: Update docs/README.md (10 min)

**Add to API Documentation section:**

```markdown
- **[Complete API Reference](api/API-REFERENCE.md)** - Full system API (800+ lines) ⭐ **NEW**
  - Domain Layer (Session, Project, Task entities)
  - Use Cases Layer (GetStatus, CreateSession, etc.)
  - Adapters Layer (Controllers, Repositories, Gateways)
  - Code examples for every component

- **[Interactive Examples](api/INTERACTIVE-EXAMPLES.md)** - 13 runnable code examples ⭐ **NEW**
  - Quick start workflows
  - Session management patterns
  - Custom integrations
  - Testing strategies

- **[Architecture Diagrams](architecture/ARCHITECTURE-DIAGRAM.md)** - 15 Mermaid diagrams ⭐ **NEW**
  - System overview
  - Sequence diagrams
  - Data flows
  - Deployment architecture
```

**Update stats:**

- Total documentation files: 214
- Total lines: 96,151
- Site pages: 63
- Test coverage: 559 tests (100% passing)

### Fix 4: Update docs/index.md (10 min)

**Add to "What's New" section:**

```markdown
## Recent Updates (December 2025)

### Phase P6 Complete - CLI Enhancements (2025-12-24) 🎉

- 559 tests passing (100% pass rate)
- Enhanced status command with ASCII visualizations
- Interactive TUI dashboard
- 10x performance boost with caching
- 4 ADHD-friendly tutorials
- v2.0.0-beta.1 released

### Production Use Phase Started (2025-12-24) 🚀

- 1-2 week validation period
- Focus on real usage feedback
- Friction log for systematic feedback
- Feature freeze until user validation complete
```

**Update Quick Stats:**

```markdown
- **Version:** v2.0.0-beta.1
- **Status:** Production Use Phase (Started Dec 24, 2025)
- **Tests:** 559 passing (100%)
- **Documentation:** 63 pages, 96K+ lines
- **Phase:** P6 Complete, P7 (optional) awaiting user feedback
```

---

## Files to Create/Modify

### Files to Delete (3 files)

1. `docs/decisions/ADR-001-vendored-code-pattern.md` (superseded by longer version)
2. `docs/decisions/ADR-002-clean-architecture.md` (outdated, pre-implementation)

### Files to Rename (1 file)

1. `docs/decisions/ADR-003-nodejs-module-api-not-rest.md` → `ADR-004-module-api-not-rest.md`

### Files to Modify (4 files)

1. `mkdocs.yml` - Update ADR navigation links
2. `docs/doc-index.md` - Update stats, add Phase P6, remove stale warnings
3. `docs/README.md` - Add new API docs, update stats
4. `docs/index.md` - Add Phase P6 completion, Production Use Phase

---

## Expected Outcomes

**After implementation:**

- ✅ No duplicate ADR files (3 files deleted)
- ✅ All ADRs correctly numbered (1, 2, 3, 4)
- ✅ mkdocs.yml points to correct, current versions
- ✅ All indexes updated with Phase P6 completion
- ✅ New API documentation discoverable from main indexes
- ✅ Production Use Phase clearly communicated
- ✅ Stats accurate (559 tests, 63 pages, v2.0.0-beta.1)

---

## Implementation Checklist

- [ ] Delete outdated ADR files (3 files)
- [ ] Rename ADR-003 conflict to ADR-004
- [ ] Update mkdocs.yml navigation
- [ ] Update docs/doc-index.md
- [ ] Update docs/README.md
- [ ] Update docs/index.md
- [ ] Test site build (`mkdocs build`)
- [ ] Verify all links work
- [ ] Commit changes with clear message
- [ ] Deploy to GitHub Pages

---

**Status:** Ready for implementation
**Next:** Execute fixes in order listed above
