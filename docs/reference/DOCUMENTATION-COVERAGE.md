# Documentation Coverage Report

**Generated:** 2026-01-21
**Version:** flow-cli v5.15.0

---

## Executive Summary

| Metric | Value | Status |
|--------|-------|--------|
| **Total Functions** | 853 | - |
| **With Help Text** | 73 | 8.6% |
| **Documentation Files** | 306 | 161,464 lines |
| **User-Facing Docs** | ~79,000 lines | ✅ Good |
| **Internal API Docs** | ~0 lines | ❌ Critical Gap |

---

## Coverage by Component

### Dispatchers (11 Active)

| Dispatcher | Functions | Help Funcs | Reference Doc | Status |
|------------|-----------|------------|---------------|--------|
| `g` | 10 | 3 | ✅ Yes | Good |
| `cc` | 7 | 2 | ✅ Yes | Good |
| `teach` | 75 | 24 | ✅ Yes (3 versions) | Excellent |
| `r` | 1+ | 1 | ✅ Yes | Good |
| `qu` | 1+ | 1 | ✅ Yes | Good |
| `mcp` | 8 | 1 | ✅ Yes | Good |
| `obs` | 6 | 1 | ✅ Yes | Good |
| `tm` | 6 | 1 | ✅ Yes | Good |
| `wt` | 9 | 2 | ✅ Yes | Good |
| `dot` | 41 | 5 | ✅ Yes | Good |
| `prompt` | 12 | 1 | ✅ Yes | Good |
| `v` | 12 | 2 | ✅ Yes (NEW) | Good |

**Dispatcher Coverage:** 100% (all have reference docs)

### Commands (27 Files)

| Command | Functions | Help | Doc Status |
|---------|-----------|------|------------|
| `work.zsh` | 9 | 3 | ✅ Documented |
| `dash.zsh` | 24 | 1 | ✅ Documented |
| `flow.zsh` | 14 | 2 | ✅ Documented |
| `sync.zsh` | 22 | 3 | ✅ Documented |
| `pick.zsh` | 15 | 0 | ⚠️ No help funcs |
| `tutorial.zsh` | 14 | 0 | ⚠️ No help funcs |
| `capture.zsh` | 6 | 0 | ⚠️ No help funcs |
| `morning.zsh` | 5 | 0 | ⚠️ No help funcs |

**Command Coverage:** ~70% (missing help in 4 commands)

### Helper Libraries (32 Files)

| Library | Functions | Help | Doc Status |
|---------|-----------|------|------------|
| `core.zsh` | 14 | 0 | ❌ No API docs |
| `atlas-bridge.zsh` | 22 | 0 | ❌ No API docs |
| `tui.zsh` | 16 | 0 | ❌ No API docs |
| `git-helpers.zsh` | 17 | 0 | ❌ No API docs |
| `validation-helpers.zsh` | 19 | 0 | ❌ No API docs |
| `cache-helpers.zsh` | 9 | 0 | ❌ No API docs |
| `parallel-helpers.zsh` | 10 | 0 | ❌ No API docs |
| *... (24 more)* | 315 | 2 | ❌ No API docs |

**Library Coverage:** 0.5% (422 functions, 2 with help)

---

## Documentation Inventory

### By Category

| Category | Files | Lines | Coverage |
|----------|-------|-------|----------|
| **Reference** | 50 | 24,563 | ✅ Complete |
| **Guides** | 37 | 31,600 | ✅ Complete |
| **Tutorials** | 27 | 13,411 | ✅ Complete |
| **Commands** | 22 | 6,807 | ⚠️ Some outdated |
| **Getting Started** | 7 | 2,577 | ✅ Complete |
| **Specs/Planning** | 163 | 82,906 | Internal |

### Key Documentation Hubs

```
docs/
├── getting-started/     7 files    2,577 lines  ✅
├── tutorials/          27 files   13,411 lines  ✅
├── guides/             37 files   31,600 lines  ✅
├── reference/          50 files   24,563 lines  ✅
├── commands/           22 files    6,807 lines  ⚠️
└── specs/             163 files   82,906 lines  Internal
```

---

## Critical Gaps

### 1. Helper Library API Documentation

**Impact:** High - Developers must read source code
**Scope:** 32 files, 422 functions
**Recommendation:** Generate API reference for all public functions

**Priority Functions to Document:**

```
lib/core.zsh
├── _flow_log_success()
├── _flow_log_error()
├── _flow_log_warning()
├── _flow_log_info()
├── _flow_log_header()
├── _flow_find_project_root()
├── _flow_detect_project_type()
└── ... (7 more)

lib/tui.zsh
├── _flow_table()
├── _flow_box()
├── _flow_progress_bar()
└── ... (13 more)

lib/git-helpers.zsh
├── _flow_git_current_branch()
├── _flow_git_is_dirty()
├── _flow_git_ahead_behind()
└── ... (14 more)
```

### 2. Command Help Functions

**Impact:** Medium - Users can't get help for some commands
**Scope:** 4 commands missing help

| Command | Functions | Action Needed |
|---------|-----------|---------------|
| `pick.zsh` | 15 | Add `_pick_help()` |
| `tutorial.zsh` | 14 | Add `_tutorial_help()` |
| `capture.zsh` | 6 | Add `_capture_help()` |
| `morning.zsh` | 5 | Add `_morning_help()` |

### 3. Test Documentation

**Impact:** Low - Affects contributors only
**Scope:** 100+ test files
**Recommendation:** Add TESTING-PATTERNS.md guide

---

## Recommendations

### Priority 1: Critical (This Session)

- [x] Add V-DISPATCHER-REFERENCE.md
- [x] Add ARCHITECTURE-OVERVIEW.md
- [x] Add to mkdocs.yml navigation

### Priority 2: High (Next Sprint)

- [ ] Create HELPER-LIBRARY-API.md with all public functions
- [ ] Add help functions to pick, tutorial, capture, morning
- [ ] Update outdated command docs

### Priority 3: Medium (Future)

- [ ] Generate inline docstrings for all functions
- [ ] Create function index with search
- [ ] Add deprecation warnings system

---

## Documentation Standards

### Required for New Functions

```zsh
# Function: _flow_example
# Purpose: Brief description
# Args:
#   $1 - argument description
#   $2 - (optional) argument description
# Returns: 0 on success, 1 on error
# Example: _flow_example "arg1" "arg2"
_flow_example() {
    # implementation
}
```

### Required for New Commands

1. `--help` / `-h` flag support
2. Entry in `docs/commands/`
3. Entry in mkdocs.yml navigation
4. Completions in `completions/`

### Required for New Dispatchers

1. `_NAME_help()` function
2. Reference doc in `docs/reference/NAME-DISPATCHER-REFERENCE.md`
3. Entry in `DISPATCHER-REFERENCE.md`
4. Entry in mkdocs.yml navigation

---

## Metrics Over Time

| Version | Functions | Documented | Coverage |
|---------|-----------|------------|----------|
| v5.10.0 | ~600 | ~50 | 8.3% |
| v5.14.0 | ~750 | ~65 | 8.7% |
| v5.15.0 | 853 | 73 | 8.6% |

**Trend:** Function count growing faster than documentation

---

## Next Steps

1. **Immediate:** Update mkdocs.yml to include V-DISPATCHER-REFERENCE.md
2. **This Week:** Document core.zsh and tui.zsh helper functions
3. **This Month:** Complete helper library API documentation
4. **Ongoing:** Maintain 100% dispatcher coverage
