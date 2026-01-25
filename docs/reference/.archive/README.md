# Archived Reference Documentation

**Archived:** 2026-01-24
**Reason:** Documentation consolidation (66 files → 7 master documents)
**Migration:** v5.17.0 documentation refactoring

---

## Overview

This directory contains **66 reference files** that were consolidated into **7 master documents** during the v5.17.0 documentation consolidation project.

**Why archived:**
- Scattered content across 66 files
- Duplicate information
- Inconsistent formats
- Hard to navigate and maintain

**Replaced by:**
- `docs/reference/MASTER-API-REFERENCE.md` - Complete API documentation
- `docs/reference/MASTER-DISPATCHER-GUIDE.md` - All 12 dispatchers
- `docs/reference/MASTER-ARCHITECTURE.md` - System architecture
- `docs/help/00-START-HERE.md` - Main documentation hub
- `docs/help/QUICK-REFERENCE.md` - Quick command lookup
- `docs/help/WORKFLOWS.md` - Real-world workflow patterns
- `docs/help/TROUBLESHOOTING.md` - Common issues and solutions

---

## Migration Map

This map shows where content from archived files can now be found.

### Dispatcher Documentation

| Old File | New Location |
|----------|--------------|
| `CC-DISPATCHER-REFERENCE.md` | `MASTER-DISPATCHER-GUIDE.md` (cc section) |
| `DOT-DISPATCHER-REFERENCE.md` | `MASTER-DISPATCHER-GUIDE.md` (dot section) |
| `G-DISPATCHER-REFERENCE.md` | `MASTER-DISPATCHER-GUIDE.md` (g section) |
| `MCP-DISPATCHER-REFERENCE.md` | `MASTER-DISPATCHER-GUIDE.md` (mcp section) |
| `OBS-DISPATCHER-REFERENCE.md` | `MASTER-DISPATCHER-GUIDE.md` (obs section) |
| `PROMPT-DISPATCHER-REFERENCE.md` | `MASTER-DISPATCHER-GUIDE.md` (prompt section) |
| `QU-DISPATCHER-REFERENCE.md` | `MASTER-DISPATCHER-GUIDE.md` (qu section) |
| `R-DISPATCHER-REFERENCE.md` | `MASTER-DISPATCHER-GUIDE.md` (r section) |
| `TEACH-DISPATCHER-REFERENCE.md` | `MASTER-DISPATCHER-GUIDE.md` (teach section) |
| `TM-DISPATCHER-REFERENCE.md` | `MASTER-DISPATCHER-GUIDE.md` (tm section) |
| `V-DISPATCHER-REFERENCE.md` | `MASTER-DISPATCHER-GUIDE.md` (v section) |
| `WT-DISPATCHER-REFERENCE.md` | `MASTER-DISPATCHER-GUIDE.md` (wt section) |
| `DISPATCHER-REFERENCE.md` | `MASTER-DISPATCHER-GUIDE.md` (overview) |

### API Documentation

| Old File | New Location |
|----------|--------------|
| `API-COMPLETE.md` | `MASTER-API-REFERENCE.md` |
| `API-REFERENCE.md` | `MASTER-API-REFERENCE.md` |
| `CORE-API-REFERENCE.md` | `MASTER-API-REFERENCE.md` (Core Library section) |
| `DOCTOR-TOKEN-API-REFERENCE.md` | `MASTER-API-REFERENCE.md` (Git Helpers section) |
| `INTEGRATION-API-REFERENCE.md` | `MASTER-API-REFERENCE.md` |
| `TEACH-ANALYZE-API-REFERENCE.md` | `MASTER-API-REFERENCE.md` (Teaching Libraries section) |
| `DATE-PARSER-API-REFERENCE.md` | `MASTER-API-REFERENCE.md` (Teaching Libraries section) |

### Architecture Documentation

| Old File | New Location |
|----------|--------------|
| `ARCHITECTURE-OVERVIEW.md` | `MASTER-ARCHITECTURE.md` |
| `ARCHITECTURE.md` | `MASTER-ARCHITECTURE.md` |
| `EXISTING-SYSTEM-SUMMARY.md` | `MASTER-ARCHITECTURE.md` (System Overview section) |

### Quick Reference Cards

| Old File | New Location |
|----------|--------------|
| `ALIAS-REFERENCE-CARD.md` | `../help/QUICK-REFERENCE.md` |
| `COMMAND-QUICK-REFERENCE.md` | `../help/QUICK-REFERENCE.md` |
| `DASHBOARD-QUICK-REF.md` | `../help/QUICK-REFERENCE.md` (dash section) |
| `NVIM-QUICK-REFERENCE.md` | `../help/QUICK-REFERENCE.md` (plugins section) |
| `CACHE-QUICK-REFERENCE.md` | `../help/QUICK-REFERENCE.md` |
| `REFCARD-OPTIMIZATION.md` | `../tutorials/22-plugin-optimization.md` |
| `REFCARD-QUARTO.md` | `../reference/MASTER-DISPATCHER-GUIDE.md` (qu section) |
| `REFCARD-TEACH-ANALYZE.md` | `../reference/MASTER-DISPATCHER-GUIDE.md` (teach section) |
| `REFCARD-TEACH-DATES.md` | `../reference/MASTER-DISPATCHER-GUIDE.md` (teach section) |
| `REFCARD-TOKEN.md` | `../help/QUICK-REFERENCE.md` (dot section) |

### Workflow Documentation

| Old File | New Location |
|----------|--------------|
| `WORKFLOW-QUICK-REFERENCE.md` | `../help/WORKFLOWS.md` |
| `WORKFLOWS.md` | `../help/WORKFLOWS.md` |

### Help & Navigation

| Old File | New Location |
|----------|--------------|
| `00-START-HERE.md` | `../help/00-START-HERE.md` |
| `INDEX.md` | `../help/00-START-HERE.md` |
| `LEARNING-PATH-NAVIGATION.md` | `../help/00-START-HERE.md` (Learning Paths section) |
| `COMMAND-EXPLORER.md` | `../help/00-START-HERE.md` |

### Specialized Topics

| Old File | New Location |
|----------|--------------|
| `ADHD-HELPERS-FUNCTION-MAP.md` | `../guides/DOPAMINE-FEATURES-GUIDE.md` |
| `CLI-COMMAND-PATTERNS-RESEARCH.md` | `MASTER-ARCHITECTURE.md` (Design Patterns section) |
| `FILE-REORGANIZATION-VISUAL.md` | `MASTER-ARCHITECTURE.md` (Project Structure section) |
| `DOCUMENTATION-COVERAGE.md` | `../DOC-DASHBOARD.md` (auto-generated) |

### Tutorials & Guides (if in reference/)

| Old File | New Location |
|----------|--------------|
| `INTELLIGENT-CONTENT-ANALYSIS.md` | `../guides/` or `../tutorials/` |
| `TEACH-ANALYZE-ARCHITECTURE.md` | `MASTER-ARCHITECTURE.md` (Teaching Workflow section) |

### Remaining Files

All other archived files were either:
- Duplicate content (consolidated into master docs)
- Outdated information (updated in master docs)
- Planning documents (kept in `.archive/planning/`)
- Auto-generated content (replaced by automation scripts)

---

## How to Find Content

**If you're looking for...**

1. **Command usage** → `docs/help/QUICK-REFERENCE.md`
2. **Dispatcher commands** → `docs/reference/MASTER-DISPATCHER-GUIDE.md`
3. **Function API** → `docs/reference/MASTER-API-REFERENCE.md`
4. **System architecture** → `docs/reference/MASTER-ARCHITECTURE.md`
5. **Workflows** → `docs/help/WORKFLOWS.md`
6. **Troubleshooting** → `docs/help/TROUBLESHOOTING.md`
7. **Getting started** → `docs/help/00-START-HERE.md`

---

## Restoration

If you need to restore any archived file for reference:

```bash
# View archived file
cat docs/reference/.archive/<filename>

# Find content in new docs
grep -r "topic" docs/reference/MASTER-*.md docs/help/*.md
```

**Note:** Archived files are kept for historical reference only. All content has been migrated, updated, and improved in the master documents.

---

**Archived:** 2026-01-24
**Files Archived:** 66
**Master Documents:** 7
**Documentation Coverage:** 2.7% → targeting 80%
