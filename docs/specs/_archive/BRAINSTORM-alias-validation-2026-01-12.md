# BRAINSTORM: Flow Alias Enhancement

**Date:** 2026-01-12
**Mode:** Feature | **Depth:** Deep
**Spec:** `docs/specs/SPEC-flow-alias-enhancement-2026-01-12.md`

---

## Requirements Gathered

| Requirement | Choice |
|-------------|--------|
| **Pain Point** | No validation (conflicts, typos, broken aliases) |
| **Validation** | All 4: conflicts, syntax, target exists, duplicates |
| **Storage** | Keep in .zshrc (current approach) |
| **Create** | Both interactive + one-liner |
| **Doctor** | All 4: shadows, broken, unused, duplicates |
| **Remove** | Comment out + backup (safe, reversible) |
| **Test** | Full pipeline: validate → dry-run → optional execute |
| **Scope** | Complete (~400 lines) |

---

## Proposed Commands

```bash
flow alias                    # Show all (existing)
flow alias <category>         # Show category (existing)
flow alias help               # Help (existing)

# NEW
flow alias add [name=cmd]     # Create new alias
flow alias rm <name>          # Remove alias (safe)
flow alias doctor             # Health check all aliases
flow alias test <name>        # Test specific alias
flow alias find <pattern>     # Search aliases
flow alias edit               # Open .zshrc at alias section
```

---

## Quick Wins

1. **`flow alias doctor`** - Core value add (~45 min)
2. **`flow alias find`** - Simple grep wrapper (~5 min)
3. **`flow alias edit`** - Open in editor (~5 min)

## Medium Effort

1. **`flow alias add`** - Interactive + one-liner (~50 min)
2. **`flow alias rm`** - Safe removal (~30 min)
3. **`flow alias test`** - Full pipeline (~30 min)

---

## Implementation Order

| Phase | Feature | Time |
|-------|---------|------|
| 1 | doctor | 45 min |
| 2 | find + edit | 15 min |
| 3 | add | 50 min |
| 4 | rm | 30 min |
| 5 | test | 30 min |
| **Total** | | ~3 hours |

---

## Next Steps

1. Review spec: `docs/specs/SPEC-flow-alias-enhancement-2026-01-12.md`
2. Say "implement doctor" to start Phase 1
3. Or "implement all" for full implementation
