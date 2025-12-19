# adhd-helpers.zsh Function Map

**File:** `~/.config/zsh/functions/adhd-helpers.zsh`
**Total Lines:** 3198
**Total Functions:** 65
**Generated:** 2025-12-19

## Function Inventory by Category

### Decision & Energy Helpers (6 functions)

| Line | Function | Description | Category for Extraction |
|------|----------|-------------|-------------------------|
| 24 | `just-start()` | Decision paralysis helper - finds next task | `helpers/energy-helpers.zsh` |
| 158 | `why()` | Show context/reason for current task | `helpers/energy-helpers.zsh` |
| 219 | `win()` | Log a win (dopamine boost) | `helpers/energy-helpers.zsh` |
| 274 | `yay()` | Celebration helper | `helpers/energy-helpers.zsh` |
| 288 | `wins()` | Show recent wins | `helpers/energy-helpers.zsh` |
| 324 | `wins-history()` | Show full win history | `helpers/energy-helpers.zsh` |

### Focus & Time Management (3 functions)

| Line | Function | Description | Category for Extraction |
|------|----------|-------------|-------------------------|
| 358 | `focus()` | Pomodoro focus timer | **CONFLICT** - Agent 1 creating dispatcher |
| 405 | `focus-stop()` | Stop focus timer | `helpers/focus-helpers.zsh` |
| 442 | `time-check()` | Check timer status | `helpers/focus-helpers.zsh` |

### Morning/Night Routines (1 function)

| Line | Function | Description | Category for Extraction |
|------|----------|-------------|-------------------------|
| 490 | `morning()` | Morning routine | `helpers/energy-helpers.zsh` |

**Note:** There's also `pmorning()` at line 2749 - need to reconcile these.

### Breadcrumb Navigation (3 functions)

| Line | Function | Description | Category for Extraction |
|------|----------|-------------|-------------------------|
| 607 | `breadcrumb()` | Leave project breadcrumb | `helpers/session-management.zsh` |
| 634 | `crumbs()` | View breadcrumbs | `helpers/session-management.zsh` |
| 665 | `crumbs-clear()` | Clear breadcrumbs | `helpers/session-management.zsh` |

### Next Actions (2 functions)

| Line | Function | Description | Category for Extraction |
|------|----------|-------------|-------------------------|
| 694 | `what-next()` | Show what's next | `helpers/session-management.zsh` |
| 790 | `whatnext()` | Alias for what-next | `helpers/session-management.zsh` |

### Workflow Logging (2 functions)

| Line | Function | Description | Category for Extraction |
|------|----------|-------------|-------------------------|
| 947 | `worklog()` | Show recent activity log | `helpers/session-management.zsh` |
| 976 | `showflow()` | Show workflow | `helpers/session-management.zsh` |

### Session Management (5 functions)

| Line | Function | Description | Category for Extraction |
|------|----------|-------------|-------------------------|
| 1024 | `startsession()` | Start a work session | `helpers/session-management.zsh` |
| 1043 | `endsession()` | End a work session | `helpers/session-management.zsh` |
| 1079 | `sessioninfo()` | Current session info | `helpers/session-management.zsh` |
| 1093 | `logged()` | Check if logged | `helpers/session-management.zsh` |
| 1111 | `flowstats()` | Flow statistics | `helpers/session-management.zsh` |

### Dashboard & Sync (3 functions)

| Line | Function | Description | Category for Extraction |
|------|----------|-------------|-------------------------|
| 1159 | `dashsync()` | Sync dashboard | `helpers/dashboard-helpers.zsh` |
| 1184 | `weeklysync()` | Weekly sync | `helpers/dashboard-helpers.zsh` |
| 1281 | `statusupdate()` | Update status | `helpers/dashboard-helpers.zsh` |

### Project Management (2 functions)

| Line | Function | Description | Category for Extraction |
|------|----------|-------------|-------------------------|
| 1363 | `setprogress()` | Set project progress | `helpers/project-helpers.zsh` |
| 1417 | `projectnotes()` | Project notes | `helpers/project-helpers.zsh` |

### MediationVerse Ecosystem (9 functions)

| Line | Function | Description | Category for Extraction |
|------|----------|-------------|-------------------------|
| 1440 | `mediationverse_report()` | Ecosystem health report | **Keep or move to mediationverse-specific file** |
| 1457 | `mediationverse_sync()` | Sync ecosystem | **Keep or move to mediationverse-specific file** |
| 1488 | `mvcd()` | cd to mediationverse | **Keep or move to mediationverse-specific file** |
| 1498 | `mvst()` | MediationVerse status | **Keep or move to mediationverse-specific file** |
| 1578 | `mvci()` | MediationVerse CI check | **Keep or move to mediationverse-specific file** |
| 1587 | `mvpush()` | Push to mediationverse | **Keep or move to mediationverse-specific file** |
| 1596 | `mvpull()` | Pull from mediationverse | **Keep or move to mediationverse-specific file** |
| 1607 | `mvmerge()` | Merge mediationverse | **Keep or move to mediationverse-specific file** |
| 1616 | `mvrebase()` | Rebase mediationverse | **Keep or move to mediationverse-specific file** |
| 1625 | `mvdev()` | MediationVerse dev mode | **Keep or move to mediationverse-specific file** |

### Project Detection (Internal Helpers) (6 functions)

| Line | Function | Description | Category for Extraction |
|------|----------|-------------|-------------------------|
| 1667 | `_proj_detect_type()` | Detect project type | `helpers/project-detection.zsh` |
| 1702 | `_proj_name_from_path()` | Extract project name | `helpers/project-detection.zsh` |
| 1708 | `_proj_find()` | Find project directory | `helpers/project-detection.zsh` |
| 1743 | `_proj_list_all()` | List all projects | `helpers/project-detection.zsh` |
| 1769 | `_proj_git_status()` | Get git status | `helpers/project-detection.zsh` |
| 1797 | `_show_teaching_context()` | Show teaching context | `helpers/project-detection.zsh` |
| 1824 | `_show_research_context()` | Show research context | `helpers/project-detection.zsh` |
| 1865 | `_truncate_branch()` | Truncate branch name | `helpers/project-detection.zsh` |

### Interactive Picker (1 function)

| Line | Function | Description | Category for Extraction |
|------|----------|-------------|-------------------------|
| 1875 | `pick()` | Interactive project picker (198 lines) | `dispatchers/pick-dispatcher.zsh` |

### Core Workflow Commands (2 functions)

| Line | Function | Description | Category for Extraction |
|------|----------|-------------|-------------------------|
| 2083 | `finish()` | Finish current task | `helpers/session-management.zsh` |
| 2181 | `now()` | Current session info | `helpers/session-management.zsh` |
| 2247 | `next()` | What's next | `helpers/session-management.zsh` |

### Dashboard Display (1 function)

| Line | Function | Description | Category for Extraction |
|------|----------|-------------|-------------------------|
| 2320 | `_dash_display()` | Display dashboard | `helpers/dashboard-helpers.zsh` |

### Project Shortcuts (p* commands) (12 functions)

These are project-aware shortcuts that detect context and dispatch:

| Line | Function | Description | Category for Extraction |
|------|----------|-------------|-------------------------|
| 2397 | `pt()` | Project test | `helpers/project-shortcuts.zsh` |
| 2439 | `pb()` | Project build | `helpers/project-shortcuts.zsh` |
| 2490 | `pc()` | Project check | `helpers/project-shortcuts.zsh` |
| 2512 | `pr()` | Project render | `helpers/project-shortcuts.zsh` |
| 2538 | `pv()` | Project preview/view | `helpers/project-shortcuts.zsh` |
| 2571 | `pcd()` | Project cd | `helpers/project-shortcuts.zsh` |
| 2592 | `phelp()` | Project help | `helpers/project-shortcuts.zsh` |
| 2649 | `pcheck()` | Project check (alt) | `helpers/project-shortcuts.zsh` |
| 2667 | `pdoc()` | Project doc | `helpers/project-shortcuts.zsh` |
| 2681 | `pinstall()` | Project install | `helpers/project-shortcuts.zsh` |
| 2695 | `pload()` | Project load | `helpers/project-shortcuts.zsh` |
| 2710 | `plog()` | Project log | `helpers/project-shortcuts.zsh` |

### Morning Routine (1 function)

| Line | Function | Description | Category for Extraction |
|------|----------|-------------|-------------------------|
| 2749 | `pmorning()` | Morning routine (project-specific?) | `helpers/energy-helpers.zsh` |

**Note:** This conflicts with `morning()` at line 490. Need to reconcile.

### Teaching Shortcuts (t* commands) (6 functions)

| Line | Function | Description | Category for Extraction |
|------|----------|-------------|-------------------------|
| 2816 | `tweek()` | Current teaching week | `helpers/teaching-helpers.zsh` |
| 2857 | `tlec()` | Open teaching lecture | `helpers/teaching-helpers.zsh` |
| 2902 | `tslide()` | Open teaching slides | `helpers/teaching-helpers.zsh` |
| 2933 | `tpublish()` | Publish teaching materials | `helpers/teaching-helpers.zsh` |
| 2946 | `tst()` | Teaching status | `helpers/teaching-helpers.zsh` |

### Research Shortcuts (r* commands) (4 functions)

| Line | Function | Description | Category for Extraction |
|------|----------|-------------|-------------------------|
| 3003 | `rms()` | Open research manuscript | `helpers/research-helpers.zsh` |
| 3033 | `rsim()` | Run research simulation | `helpers/research-helpers.zsh` |
| 3079 | `rlit()` | Research literature search | `helpers/research-helpers.zsh` |
| 3108 | `rst()` | Research status | `helpers/research-helpers.zsh` |

### Help Commands (2 functions)

| Line | Function | Description | Category for Extraction |
|------|----------|-------------|-------------------------|
| 3169 | `thelp()` | Teaching help | `helpers/teaching-helpers.zsh` |
| 3185 | `rhelp()` | Research help | `helpers/research-helpers.zsh` |

## Extraction Plan by New File

### `dispatchers/pick-dispatcher.zsh`
- **Lines:** 1875-2073 (198 lines)
- **Functions:** `pick()`
- **Dependencies:**
  - `_proj_list_all()` (line 1743)
  - `_proj_find()` (line 1708)
  - Must source `helpers/project-detection.zsh` first

### `helpers/energy-helpers.zsh`
**Functions (9 total):**
- `just-start()` (line 24)
- `why()` (line 158)
- `win()` (line 219)
- `yay()` (line 274)
- `wins()` (line 288)
- `wins-history()` (line 324)
- `morning()` (line 490) - reconcile with pmorning
- `pmorning()` (line 2749) - reconcile with morning

**Estimated Lines:** ~500 lines

### `helpers/focus-helpers.zsh`
**Functions (2 total):**
- `focus-stop()` (line 405)
- `time-check()` (line 442)

**Note:** Main `focus()` function (line 358) will be handled by Agent 1 as dispatcher.

**Estimated Lines:** ~100 lines

### `helpers/session-management.zsh`
**Functions (15 total):**
- `breadcrumb()` (line 607)
- `crumbs()` (line 634)
- `crumbs-clear()` (line 665)
- `what-next()` (line 694)
- `whatnext()` (line 790)
- `worklog()` (line 947)
- `showflow()` (line 976)
- `startsession()` (line 1024)
- `endsession()` (line 1043)
- `sessioninfo()` (line 1079)
- `logged()` (line 1093)
- `flowstats()` (line 1111)
- `finish()` (line 2083)
- `now()` (line 2181)
- `next()` (line 2247)

**Estimated Lines:** ~800 lines

### `helpers/dashboard-helpers.zsh`
**Functions (4 total):**
- `dashsync()` (line 1159)
- `weeklysync()` (line 1184)
- `statusupdate()` (line 1281)
- `_dash_display()` (line 2320)

**Estimated Lines:** ~300 lines

### `helpers/project-detection.zsh`
**Functions (8 total):**
- `_proj_detect_type()` (line 1667)
- `_proj_name_from_path()` (line 1702)
- `_proj_find()` (line 1708)
- `_proj_list_all()` (line 1743)
- `_proj_git_status()` (line 1769)
- `_show_teaching_context()` (line 1797)
- `_show_research_context()` (line 1824)
- `_truncate_branch()` (line 1865)

**Estimated Lines:** ~200 lines

### `helpers/project-shortcuts.zsh`
**Functions (12 total):**
- `pt()` (line 2397)
- `pb()` (line 2439)
- `pc()` (line 2490)
- `pr()` (line 2512)
- `pv()` (line 2538)
- `pcd()` (line 2571)
- `phelp()` (line 2592)
- `pcheck()` (line 2649)
- `pdoc()` (line 2667)
- `pinstall()` (line 2681)
- `pload()` (line 2695)
- `plog()` (line 2710)

**Estimated Lines:** ~400 lines

### `helpers/teaching-helpers.zsh`
**Functions (6 total):**
- `tweek()` (line 2816)
- `tlec()` (line 2857)
- `tslide()` (line 2902)
- `tpublish()` (line 2933)
- `tst()` (line 2946)
- `thelp()` (line 3169)

**Estimated Lines:** ~300 lines

### `helpers/research-helpers.zsh`
**Functions (5 total):**
- `rms()` (line 3003)
- `rsim()` (line 3033)
- `rlit()` (line 3079)
- `rst()` (line 3108)
- `rhelp()` (line 3185)

**Estimated Lines:** ~200 lines

### `helpers/project-helpers.zsh`
**Functions (2 total):**
- `setprogress()` (line 1363)
- `projectnotes()` (line 1417)

**Estimated Lines:** ~100 lines

### MediationVerse Functions - Decision Needed

**Functions (9 total):**
- `mediationverse_report()` (line 1440)
- `mediationverse_sync()` (line 1457)
- `mvcd()` (line 1488)
- `mvst()` (line 1498)
- `mvci()` (line 1578)
- `mvpush()` (line 1587)
- `mvpull()` (line 1596)
- `mvmerge()` (line 1607)
- `mvrebase()` (line 1616)
- `mvdev()` (line 1625)

**Options:**
1. Keep in adhd-helpers.zsh (project-specific)
2. Create `helpers/mediationverse-helpers.zsh`
3. Move to mediationverse project itself
4. Create `dispatchers/mv-dispatcher.zsh` (convert to dispatcher pattern)

**Recommendation:** Create `helpers/mediationverse-helpers.zsh` for now, consider dispatcher pattern later.

## Dependencies Map

### Critical Dependencies
- `pick()` depends on `_proj_list_all()` and `_proj_find()`
- All project shortcuts (p*, t*, r*) depend on project detection functions
- Session management functions may depend on project detection
- Dashboard helpers depend on project detection

### Sourcing Order Requirements

1. **First:** `helpers/project-detection.zsh` (foundation for everything)
2. **Second:** All other helpers (no interdependencies expected)
3. **Third:** Dispatchers (depend on helpers)

### Shared State Files

Functions write to/read from:
- `~/.workflow_log` - workflow logging
- `~/.breadcrumbs` - breadcrumb trail
- `~/.wins_log` - win logging
- `~/.focus_timer` - focus timer state
- `~/projects/*/.STATUS` - project status files
- Session-specific logs

## Issues & Conflicts to Resolve

### 1. Duplicate Functions
- `morning()` (line 490) vs `pmorning()` (line 2749)
  - **Resolution:** Check if they're duplicates or serve different purposes

### 2. Focus Timer
- `focus()` (line 358) in adhd-helpers.zsh
- Agent 1 creating `timer-dispatcher.zsh` with `timer()` function
  - **Resolution:** Coordinate with Agent 1
  - **Options:**
    - Keep `focus()` as-is, create `timer()` as new alternative
    - Deprecate `focus()`, replace with `timer()`
    - Have `focus()` call `timer()` internally

### 3. Next Actions Functions
- `what-next()` (line 694)
- `whatnext()` (line 790)
- `next()` (line 2247)
  - **Resolution:** Determine if these are duplicates or serve different purposes

## Estimated File Sizes After Extraction

| New File | Estimated Lines | Functions |
|----------|-----------------|-----------|
| `dispatchers/pick-dispatcher.zsh` | 200 | 1 |
| `helpers/energy-helpers.zsh` | 500 | 9 |
| `helpers/focus-helpers.zsh` | 100 | 2 |
| `helpers/session-management.zsh` | 800 | 15 |
| `helpers/dashboard-helpers.zsh` | 300 | 4 |
| `helpers/project-detection.zsh` | 200 | 8 |
| `helpers/project-shortcuts.zsh` | 400 | 12 |
| `helpers/teaching-helpers.zsh` | 300 | 6 |
| `helpers/research-helpers.zsh` | 200 | 5 |
| `helpers/project-helpers.zsh` | 100 | 2 |
| `helpers/mediationverse-helpers.zsh` | 300 | 9 |
| **TOTAL EXTRACTED** | **~3400 lines** | **73 functions** |

**Original file:** 3198 lines, 65 functions

**Note:** Estimated totals exceed original due to:
- Added headers/documentation
- Proper spacing between functions
- Dependency imports/sources

## Next Steps

1. **Validate function boundaries:** Ensure line ranges are accurate
2. **Check for hidden dependencies:** Look for global variables, shared state
3. **Resolve conflicts:** morning/pmorning, focus/timer, next/what-next
4. **Create extraction scripts:** Automate the tedious work
5. **Test extraction:** One file at a time
6. **Update documentation:** Reflect new structure

## Automated Extraction Template

```bash
#!/usr/bin/env zsh
# extract-function.sh - Extract function ranges from adhd-helpers.zsh

SOURCE_FILE="$HOME/.config/zsh/functions/adhd-helpers.zsh"
TARGET_DIR="$HOME/.config/zsh/functions/helpers"

extract_function() {
    local func_name="$1"
    local start_line="$2"
    local end_line="$3"
    local target_file="$4"

    echo "Extracting $func_name (lines $start_line-$end_line) to $target_file"

    # Extract function
    sed -n "${start_line},${end_line}p" "$SOURCE_FILE" >> "$target_file"
    echo "" >> "$target_file"  # Add blank line after function
}

# Example usage:
# extract_function "just-start" 24 157 "$TARGET_DIR/energy-helpers.zsh"
```

---

**Generated:** 2025-12-19
**Agent:** Agent 4 (File Organizer)
**Status:** Analysis complete, ready for extraction planning
