# Documentation Coverage Report

**Generated:** 2026-01-22
**Version:** flow-cli v5.15.1

---

## Executive Summary

| Metric | Value | Status |
|--------|-------|--------|
| **Total Functions** | 853 | - |
| **With Help Text** | 73 | 8.6% |
| **With Inline Docstrings** | 261 | 30.6% (+80 in Phase 3) |
| **Documentation Files** | 309 | 166,000 lines |
| **User-Facing Docs** | ~79,000 lines | ✅ Good |
| **Internal API Docs** | ~4,500 lines | ✅ Phase 3 Complete |

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

| Library | Functions | Docstrings | Doc Status |
|---------|-----------|------------|------------|
| `core.zsh` | 14 | **14** | ✅ **Phase 1 Complete** |
| `tui.zsh` | 16 | **16** | ✅ **Phase 1 Complete** |
| `git-helpers.zsh` | 17 | **17** | ✅ **Phase 1 Complete** |
| `validation-helpers.zsh` | 19 | **19** | ✅ **Phase 2 Complete** |
| `backup-helpers.zsh` | 12 | **12** | ✅ **Phase 2 Complete** |
| `cache-helpers.zsh` | 11 | **11** | ✅ **Phase 2 Complete** |
| `index-helpers.zsh` | 12 | **12** | ✅ **Phase 2 Complete** |
| `teaching-utils.zsh` | 7 | **7** | ✅ **Phase 2 Complete** |
| `atlas-bridge.zsh` | 21 | **21** | ✅ **Phase 3 Complete** |
| `plugin-loader.zsh` | 23 | **23** | ✅ **Phase 3 Complete** |
| `config.zsh` | 16 | **16** | ✅ **Phase 3 Complete** |
| `keychain-helpers.zsh` | 7 | **7** | ✅ **Phase 3 Complete** |
| `project-detector.zsh` | 4 | **4** | ✅ **Phase 3 Complete** |
| `project-cache.zsh` | 9 | **9** | ✅ **Phase 3 Complete** |
| `parallel-helpers.zsh` | 10 | 0 | ⏳ Phase 4 |
| *... (17 more)* | 215 | 2 | ⏳ Phase 4 |

**Library Coverage:** 61.8% (261/422 functions with inline docstrings)
**API Reference:** `docs/reference/CORE-API-REFERENCE.md` (1,661 lines) + `docs/reference/TEACHING-API-REFERENCE.md` (~1,400 lines) + `docs/reference/INTEGRATION-API-REFERENCE.md` (~1,400 lines)

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

**Impact:** ~~High~~ → Low (Phase 3 complete)
**Scope:** ~~32 files, 422 functions~~ → 18 files, 234 functions remaining
**Status:** Phase 3 Complete (14 libraries, 188 functions documented)

**✅ COMPLETED (Phase 1):**

```
lib/core.zsh (14 functions) ✅
├── _flow_log() ✅
├── _flow_log_success() ✅
├── _flow_log_warning() ✅
├── _flow_log_error() ✅
├── _flow_log_info() ✅
├── _flow_log_muted() ✅
├── _flow_log_debug() ✅
├── _flow_status_icon() ✅
├── _flow_project_name() ✅
├── _flow_find_project_root() ✅
├── _flow_in_project() ✅
├── _flow_format_duration() ✅
├── _flow_time_ago() ✅
├── _flow_confirm() ✅
├── _flow_array_contains() ✅
├── _flow_read_file() ✅
└── _flow_get_config() ✅

lib/tui.zsh (16 functions) ✅
├── _flow_progress_bar() ✅
├── _flow_sparkline() ✅
├── _flow_table() ✅
├── _flow_box() ✅
├── _flow_has_fzf() ✅
├── _flow_pick_project() ✅
├── _flow_show_project_preview() ✅
├── _flow_has_gum() ✅
├── _flow_input() ✅
├── _flow_confirm_styled() ✅
├── _flow_choose() ✅
├── _flow_widget_status() ✅
├── _flow_widget_timer() ✅
├── _flow_spinner_start() ✅
├── _flow_spinner_stop() ✅
└── _flow_with_spinner() ✅

lib/git-helpers.zsh (17 functions) ✅
├── _git_teaching_commit_message() ✅
├── _git_is_clean() ✅
├── _git_is_synced() ✅
├── _git_teaching_files() ✅
├── _git_interactive_commit() ✅
├── _git_create_deploy_pr() ✅
├── _git_in_repo() ✅
├── _git_current_branch() ✅
├── _git_remote_branch() ✅
├── _git_commit_teaching_content() ✅
├── _git_push_current_branch() ✅
├── _git_detect_production_conflicts() ✅
├── _git_get_commit_count() ✅
├── _git_get_commit_list() ✅
├── _git_generate_pr_body() ✅
├── _git_rebase_onto_production() ✅
└── _git_has_unpushed_commits() ✅
```

**✅ COMPLETED (Phase 2):**

```
lib/validation-helpers.zsh (19 functions) ✅
├── _validate_yaml() ✅
├── _validate_yaml_batch() ✅
├── _validate_syntax() ✅
├── _validate_syntax_batch() ✅
├── _validate_render() ✅
├── _validate_render_batch() ✅
├── _check_empty_chunks() ✅
├── _check_images() ✅
├── _check_freeze_staged() ✅
├── _is_quarto_preview_running() ✅
├── _get_validation_status() ✅
├── _update_validation_status() ✅
├── _debounce_validation() ✅
├── _validate_file_full() ✅
├── _find_quarto_files() ✅
├── _get_staged_quarto_files() ✅
├── _track_validation_start() ✅
├── _track_validation_end() ✅
└── _show_validation_stats() ✅

lib/backup-helpers.zsh (12 functions) ✅
├── _resolve_backup_path() ✅
├── _teach_backup_content() ✅
├── _teach_get_retention_policy() ✅
├── _teach_list_backups() ✅
├── _teach_count_backups() ✅
├── _teach_backup_size() ✅
├── _teach_delete_backup() ✅
├── _teach_cleanup_backups() ✅
├── _teach_archive_semester() ✅
├── _teach_confirm_delete() ✅
├── _teach_preview_cleanup() ✅
└── _teach_restore_backup() ✅

lib/cache-helpers.zsh (11 functions) ✅
├── _cache_status() ✅
├── _cache_format_time_ago() ✅
├── _cache_clear() ✅
├── _clear_cache_selective() ✅
├── _cache_rebuild() ✅
├── _cache_analyze() ✅
├── _cache_clean() ✅
├── _cache_format_bytes() ✅
├── _cache_is_freeze_enabled() ✅
├── _cache_get_config() ✅
└── _cache_init() ✅

lib/index-helpers.zsh (12 functions) ✅
├── _find_dependencies() ✅
├── _validate_cross_references() ✅
├── _detect_index_changes() ✅
├── _extract_title() ✅
├── _parse_week_number() ✅
├── _update_index_link() ✅
├── _find_insertion_point() ✅
├── _remove_index_link() ✅
├── _prompt_index_action() ✅
├── _get_index_file() ✅
├── _process_index_changes() ✅
└── _generate_link_text() ✅

lib/teaching-utils.zsh (7 functions) ✅
├── _calculate_current_week() ✅
├── _is_break_week() ✅
├── _date_to_week() ✅
├── _validate_date_format() ✅
├── _calculate_semester_end() ✅
├── _suggest_semester_start() ✅
└── _get_week_dates() ✅
```

**✅ COMPLETED (Phase 3):**

```
lib/atlas-bridge.zsh (21 functions) ✅
├── _flow_timestamp() ✅
├── _flow_timestamp_short() ✅
├── _flow_has_atlas() ✅
├── _flow_refresh_atlas() ✅
├── _flow_init_atlas() ✅
├── _flow_atlas() ✅
├── _flow_atlas_silent() ✅
├── _flow_atlas_json() ✅
├── _flow_atlas_async() ✅
├── _flow_get_project() ✅
├── _flow_get_project_fallback() ✅
├── _flow_list_projects() ✅
├── _flow_list_projects_fallback() ✅
├── _flow_session_start() ✅
├── _flow_session_end() ✅
├── _flow_session_current() ✅
├── _flow_today_session_time() ✅
├── _flow_catch() ✅
├── _flow_inbox() ✅
├── _flow_where() ✅
└── _flow_where_fallback() ✅

lib/plugin-loader.zsh (23 functions) ✅
├── _flow_plugin_dir() ✅
├── _flow_plugin_list() ✅
├── _flow_plugin_enabled() ✅
├── _flow_plugin_load() ✅
├── _flow_plugin_unload() ✅
├── _flow_plugin_enable() ✅
├── _flow_plugin_disable() ✅
├── _flow_plugin_info() ✅
├── _flow_plugin_create() ✅
├── _flow_plugin_validate() ✅
├── _flow_plugin_dependencies() ✅
├── _flow_plugin_hook_register() ✅
├── _flow_plugin_hook_unregister() ✅
├── _flow_plugin_hook_run() ✅
├── _flow_plugin_hook_list() ✅
├── _flow_plugin_config_get() ✅
├── _flow_plugin_config_set() ✅
├── _flow_plugin_config_list() ✅
├── _flow_plugin_update() ✅
├── _flow_plugin_install() ✅
├── _flow_plugin_remove() ✅
├── _flow_plugin_search() ✅
└── _flow_plugin_init() ✅

lib/config.zsh (16 functions) ✅
├── _flow_config_file() ✅
├── _flow_config_get() ✅
├── _flow_config_set() ✅
├── _flow_config_unset() ✅
├── _flow_config_list() ✅
├── _flow_config_has() ✅
├── _flow_config_keys() ✅
├── _flow_config_export() ✅
├── _flow_config_import() ✅
├── _flow_config_reset() ✅
├── _flow_config_validate() ✅
├── _flow_config_migrate() ✅
├── _flow_config_backup() ✅
├── _flow_config_restore() ✅
├── _flow_config_profile_set() ✅
└── _flow_config_profile_get() ✅

lib/keychain-helpers.zsh (7 functions) ✅
├── _flow_keychain_get() ✅
├── _flow_keychain_set() ✅
├── _flow_keychain_delete() ✅
├── _flow_keychain_has() ✅
├── _flow_keychain_list() ✅
├── _flow_keychain_export() ✅
└── _flow_keychain_import() ✅

lib/project-detector.zsh (4 functions) ✅
├── _flow_detect_project_type() ✅
├── _flow_project_markers() ✅
├── _flow_project_icon() ✅
└── _flow_project_color() ✅

lib/project-cache.zsh (9 functions) ✅
├── _flow_cache_projects() ✅
├── _flow_cache_invalidate() ✅
├── _flow_cache_get() ✅
├── _flow_cache_set() ✅
├── _flow_cache_has() ✅
├── _flow_cache_age() ✅
├── _flow_cache_refresh() ✅
├── _flow_cache_clear_all() ✅
└── _flow_cache_stats() ✅
```

**⏳ REMAINING (Phase 4):**

| Phase | Libraries | Functions | Priority |
|-------|-----------|-----------|----------|
| Phase 4 | 18 remaining libraries | ~155 | Low |

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

### Priority 1: Critical (This Session) ✅ COMPLETE

- [x] Add V-DISPATCHER-REFERENCE.md
- [x] Add ARCHITECTURE-OVERVIEW.md
- [x] Add to mkdocs.yml navigation
- [x] **Phase 1 Documentation Debt: Core Libraries** (47 functions)
  - [x] Add inline docstrings to core.zsh (14 functions)
  - [x] Add inline docstrings to tui.zsh (16 functions)
  - [x] Add inline docstrings to git-helpers.zsh (17 functions)
  - [x] Create CORE-API-REFERENCE.md (1,661 lines)
  - [x] Update mkdocs.yml with API Reference section

### Priority 2: High (Next Sprint) ✅ COMPLETE

- [x] **Phase 2: Teaching Libraries** (61 functions)
  - [x] validation-helpers.zsh (19 functions)
  - [x] backup-helpers.zsh (12 functions)
  - [x] cache-helpers.zsh (11 functions)
  - [x] index-helpers.zsh (12 functions)
  - [x] teaching-utils.zsh (7 functions)
  - [x] Create TEACHING-API-REFERENCE.md (~1,400 lines)
- [ ] Add help functions to pick, tutorial, capture, morning
- [ ] Update outdated command docs

### Priority 3: Medium (This Sprint) ✅ COMPLETE

- [x] **Phase 3: Integration Libraries** (80 functions)
  - [x] atlas-bridge.zsh (21 functions)
  - [x] plugin-loader.zsh (23 functions)
  - [x] config.zsh (16 functions)
  - [x] keychain-helpers.zsh (7 functions)
  - [x] project-detector.zsh (4 functions)
  - [x] project-cache.zsh (9 functions)
  - [x] Create INTEGRATION-API-REFERENCE.md (~1,400 lines)

### Priority 4: Low (Future)

- [ ] **Phase 4: Specialized Libraries** (~155 functions)
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

| Version | Functions | Documented | Coverage | Notes |
|---------|-----------|------------|----------|-------|
| v5.10.0 | ~600 | ~50 | 8.3% | - |
| v5.14.0 | ~750 | ~65 | 8.7% | - |
| v5.15.0 | 853 | 73 | 8.6% | - |
| v5.15.1 | 853 | 120 | 14.1% | +47 (Phase 1) |
| v5.15.1 | 853 | 181 | 21.2% | +61 (Phase 2) |
| **v5.15.1** | **853** | **261** | **30.6%** | **+80 (Phase 3)** |

**Trend:** ~~Function count growing faster than documentation~~ → Documentation catching up! Phase 1 added 47 functions, Phase 2 added 61, Phase 3 added 80 more. Total: 188 fully documented functions.

---

## Next Steps

1. ~~**Immediate:** Update mkdocs.yml to include V-DISPATCHER-REFERENCE.md~~ ✅ Done
2. ~~**This Week:** Document core.zsh and tui.zsh helper functions~~ ✅ Done (Phase 1)
3. ~~**This Month:** Complete Phase 2 (Teaching libraries ~60 functions)~~ ✅ Done (Phase 2)
4. ~~**Next:** Complete Phase 3 (Integration libraries ~80 functions)~~ ✅ Done (Phase 3)
5. **Next:** Complete Phase 4 (Specialized libraries ~155 functions)
6. **Ongoing:** Maintain 100% dispatcher coverage

---

## Phase 1 Completion Summary (2026-01-22)

**Branch:** `feature/documentation-debt`
**Deliverables:**
- 47 functions with inline docstrings
- 1,661-line CORE-API-REFERENCE.md
- mkdocs.yml updated with API Reference section

**Files Modified:**
- `lib/core.zsh` - 14 functions documented
- `lib/tui.zsh` - 16 functions documented
- `lib/git-helpers.zsh` - 17 functions documented
- `docs/reference/CORE-API-REFERENCE.md` - Created
- `mkdocs.yml` - API Reference section added
- `docs/reference/DOCUMENTATION-COVERAGE.md` - Metrics updated

---

## Phase 2 Completion Summary (2026-01-22)

**Branch:** `feature/documentation-debt`
**Deliverables:**
- 61 functions with inline docstrings
- ~1,400-line TEACHING-API-REFERENCE.md
- mkdocs.yml updated with Teaching Libraries reference

**Files Modified:**
- `lib/validation-helpers.zsh` - 19 functions documented
- `lib/backup-helpers.zsh` - 12 functions documented
- `lib/cache-helpers.zsh` - 11 functions documented
- `lib/index-helpers.zsh` - 12 functions documented
- `lib/teaching-utils.zsh` - 7 functions documented
- `docs/reference/TEACHING-API-REFERENCE.md` - Created
- `mkdocs.yml` - Teaching Libraries added to API Reference
- `docs/reference/DOCUMENTATION-COVERAGE.md` - Metrics updated

**Cumulative Progress (Phase 1 + 2):**
- Total functions documented: 108 (47 + 61)
- Total API reference lines: ~3,100 (1,661 + ~1,400)
- Coverage increased: 8.6% → 21.2%

---

## Phase 3 Completion Summary (2026-01-22)

**Branch:** `feature/documentation-debt`
**Deliverables:**
- 80 functions with inline docstrings
- ~1,400-line INTEGRATION-API-REFERENCE.md
- mkdocs.yml updated with Integration Libraries reference

**Files Modified:**
- `lib/atlas-bridge.zsh` - 21 functions documented
- `lib/plugin-loader.zsh` - 23 functions documented
- `lib/config.zsh` - 16 functions documented
- `lib/keychain-helpers.zsh` - 7 functions documented
- `lib/project-detector.zsh` - 4 functions documented
- `lib/project-cache.zsh` - 9 functions documented
- `docs/reference/INTEGRATION-API-REFERENCE.md` - Created
- `mkdocs.yml` - Integration Libraries added to API Reference
- `docs/reference/DOCUMENTATION-COVERAGE.md` - Metrics updated

**Cumulative Progress (Phase 1 + 2 + 3):**
- Total functions documented: 188 (47 + 61 + 80)
- Total API reference lines: ~4,500 (1,661 + ~1,400 + ~1,400)
- Coverage increased: 8.6% → 30.6%
