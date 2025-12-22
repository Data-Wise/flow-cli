# Command Rename Implementation Plan
# status → up Migration Plan

**Date:** 2025-12-14
**Target:** Rename `status` command to clearer alternatives
**Timeline:** 3 weeks (with 1-week testing period)

---

## Overview

### The Change
```bash
# OLD (confusing)
status <project>                   # Multi-mode: update/show/create
status <project> --show            # Show (requires flag)
status <project> --create          # Create (hidden mode)

# NEW (clear)
dash <project>                     # Show (existing command)
up <project>                       # Update (new, clear verb)
pinit <project>                    # Project init (new, rare use)
```

---

## Phase 1: Preparation (15 minutes)

### Step 1: Create New Functions

**File:** `/Users/dt/.config/zsh/functions/up.zsh`

```bash
#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# UP - Update Project Status
# ══════════════════════════════════════════════════════════════════════════════
#
# File:         ~/.config/zsh/functions/up.zsh
# Version:      1.0
# Date:         2025-12-14
# Purpose:      Update .STATUS files (renamed from 'status')
#
# Usage:        up <project> [status] [priority] [task] [progress]
# Examples:     up mediationverse
#               up medfit active P1 "Add vignette" 60
#
# ══════════════════════════════════════════════════════════════════════════════

emulate -L zsh

up() {
    local project="$1"

    # Color setup
    local GREEN='\033[0;32m'
    local CYAN='\033[0;36m'
    local YELLOW='\033[1;33m'
    local RED='\033[0;31m'
    local BOLD='\033[1m'
    local DIM='\033[2m'
    local NC='\033[0m'

    # Show help
    if [[ -z "$project" ]] || [[ "$project" == "--help" ]] || [[ "$project" == "-h" ]]; then
        _up_help
        return 0
    fi

    # Find project directory (reuse existing logic from status.zsh)
    local project_dir=""
    local search_paths=(
        "$HOME/projects/r-packages/active"
        "$HOME/projects/r-packages/stable"
        "$HOME/projects/teaching"
        "$HOME/projects/research"
        "$HOME/projects/dev-tools"
        "$HOME/projects/quarto"
        "$HOME/projects"
    )

    # Direct match
    for base in "${search_paths[@]}"; do
        if [[ -d "$base/$project" ]]; then
            project_dir="$base/$project"
            break
        fi
    done

    # Fuzzy match if not found
    if [[ -z "$project_dir" ]]; then
        project_dir=$(find ~/projects -maxdepth 3 -type d -name "*$project*" 2>/dev/null | head -1)
    fi

    # Check if current directory
    if [[ -z "$project_dir" ]] && [[ "$(basename $PWD)" == "$project" ]]; then
        project_dir="$PWD"
    fi

    if [[ -z "$project_dir" ]]; then
        echo -e "${RED}❌ Project not found: $project${NC}"
        echo ""
        echo "Searched in:"
        for path in "${search_paths[@]}"; do
            echo -e "  ${DIM}$path${NC}"
        done
        return 1
    fi

    local status_file="$project_dir/.STATUS"

    # Quick update mode (all args provided)
    if [[ $# -ge 5 ]]; then
        _up_quick_update "$project_dir" "$2" "$3" "$4" "$5"
        return $?
    fi

    # Interactive update mode
    _up_interactive "$project_dir"
}

# Copy the helper functions from status.zsh:
# - _up_interactive (was _status_interactive)
# - _up_quick_update (was _status_quick_update)
# - _up_help (was _status_help)
# Note: Remove --show and --create logic (handled by dash/pinit)

# ... [Include modified versions of helper functions here]
```

**File:** `/Users/dt/.config/zsh/functions/pinit.zsh`

```bash
#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# PINIT - Initialize Project Status File
# ══════════════════════════════════════════════════════════════════════════════
#
# File:         ~/.config/zsh/functions/pinit.zsh
# Version:      1.0
# Date:         2025-12-14
# Purpose:      Create new .STATUS files (extracted from 'status --create')
#
# Usage:        pinit <project>
# Example:      pinit new-package
#
# ══════════════════════════════════════════════════════════════════════════════

emulate -L zsh

pinit() {
    local project="$1"

    # Color setup
    local GREEN='\033[0;32m'
    local CYAN='\033[0;36m'
    local YELLOW='\033[1;33m'
    local RED='\033[0;31m'
    local BOLD='\033[1m'
    local NC='\033[0m'

    # Show help
    if [[ -z "$project" ]] || [[ "$project" == "--help" ]] || [[ "$project" == "-h" ]]; then
        _pinit_help
        return 0
    fi

    # Find project directory (same logic as up)
    # ... [Copy from status.zsh _status_create function]

    # Create .STATUS file
    # ... [Copy logic from status.zsh _status_create function]
}

# ... [Include _pinit_help function]
```

---

### Step 2: Update `dash` (If Needed)

Check if `dash` already handles single project:

```bash
# Test current behavior
dash mediationverse
```

If not implemented, add to `/Users/dt/.config/zsh/functions/dash.zsh`:

```bash
dash() {
    local filter="$1"

    # If argument looks like a project name (not a category), show single project
    if [[ -n "$filter" ]] && [[ "$filter" != "teaching" ]] && [[ "$filter" != "research" ]] && [[ "$filter" != "packages" ]] && [[ "$filter" != "dev" ]]; then
        # Try to find and show single project .STATUS file
        local project_dir=$(find ~/projects -maxdepth 3 -type d -name "*$filter*" 2>/dev/null | head -1)
        if [[ -n "$project_dir" ]] && [[ -f "$project_dir/.STATUS" ]]; then
            echo ""
            echo -e "${BOLD}╭─────────────────────────────────────────────╮${NC}"
            echo -e "${BOLD}│ 📋 $(basename $project_dir)${NC}"
            echo -e "${BOLD}╰─────────────────────────────────────────────╯${NC}"
            echo ""
            cat "$project_dir/.STATUS"
            echo ""
            return 0
        fi
    fi

    # Otherwise, show dashboard (existing logic)
    # ... existing dash code ...
}
```

---

### Step 3: Source New Functions

Add to `/Users/dt/.config/zsh/.zshrc`:

```bash
# Status management (updated 2025-12-14)
source ~/.config/zsh/functions/up.zsh        # Update project status
source ~/.config/zsh/functions/pinit.zsh     # Initialize .STATUS files
source ~/.config/zsh/functions/dash.zsh      # Dashboard (show status)
```

---

## Phase 2: Testing Period (1 Week)

### Step 1: Test New Commands

```bash
# Test show (single project)
dash mediationverse                # Should show .STATUS

# Test update (interactive)
up mediationverse                  # Should prompt for updates

# Test update (quick)
up medfit active P1 "Test" 50      # Should update directly

# Test create
mkdir -p ~/projects/test/test-project
pinit test-project                 # Should create .STATUS
rm -rf ~/projects/test/test-project
```

### Step 2: Daily Usage Tracking

**Day 1-3:** Use new commands alongside old
```bash
# Try to use naturally:
dash                               # Morning scan
up medfit                          # Update status
work medfit                        # Start work
```

**Day 4-7:** Evaluate comfort level
- Does `up` feel natural?
- Is `dash project` intuitive?
- Any muscle memory conflicts?

---

## Phase 3: Deprecation (Week 2)

### Step 1: Add Warning to `status`

Modify `/Users/dt/.config/zsh/functions/status.zsh`:

```bash
status() {
    # Deprecation warning
    echo ""
    echo -e "${YELLOW}⚠️  DEPRECATION WARNING${NC}"
    echo -e "   The ${BOLD}status${NC} command has been split for clarity:"
    echo ""
    echo -e "   ${CYAN}dash <project>${NC}     # Show status (read-only)"
    echo -e "   ${GREEN}up <project>${NC}       # Update status (interactive/quick)"
    echo -e "   ${MAGENTA}pinit <project>${NC}   # Create new .STATUS file"
    echo ""
    echo -e "   This command will be removed in 1 week."
    echo ""

    # Offer to run correct command
    read -q "REPLY?Run 'up $@' instead? (y/n) "
    echo ""
    if [[ "$REPLY" == "y" ]]; then
        up "$@"
    fi
}
```

### Step 2: Update Documentation

**Files to update:**
- [ ] `/Users/dt/projects/dev-tools/flow-cli/WORKFLOW-QUICK-REFERENCE.md`
- [ ] `/Users/dt/projects/dev-tools/flow-cli/ALIAS-REFERENCE-CARD.md`
- [ ] `/Users/dt/projects/dev-tools/flow-cli/.STATUS`
- [ ] `/Users/dt/.config/zsh/functions/adhd-helpers.zsh` (help text)

**Changes:**
```diff
- status <project>                   # Update status
+ up <project>                       # Update status
+ dash <project>                     # Show status
+ pinit <project>                    # Create .STATUS
```

---

## Phase 4: Final Migration (Week 3)

### Step 1: Remove Old Command

**Option A: Complete Removal**
```bash
# Delete status.zsh
rm ~/.config/zsh/functions/status.zsh

# Remove from .zshrc
# (delete line: source ~/.config/zsh/functions/status.zsh)
```

**Option B: Redirect to Help**
```bash
status() {
    echo ""
    echo -e "${RED}❌ 'status' has been removed${NC}"
    echo ""
    echo "Use these instead:"
    echo -e "  ${CYAN}dash <project>${NC}     # Show status"
    echo -e "  ${GREEN}up <project>${NC}       # Update status"
    echo -e "  ${MAGENTA}pinit <project>${NC}   # Create .STATUS"
    echo ""
    echo "See: WORKFLOW-QUICK-REFERENCE.md"
    echo ""
}
```

### Step 2: Update Tests

If tests exist in `/Users/dt/.config/zsh/tests/`, update:

```bash
# Find test files that reference 'status'
grep -r "status" ~/.config/zsh/tests/

# Update test calls:
# status → up (for updates)
# status --show → dash (for shows)
# status --create → pinit (for creates)
```

### Step 3: Final Verification

```bash
# Test all scenarios
dash                               # Show all projects
dash mediationverse                # Show one project
up mediationverse                  # Update (interactive)
up medfit active P1 "X" 60         # Update (quick)
pinit new-test                     # Create .STATUS

# Verify old command is gone/redirected
status mediationverse              # Should show error/help
```

---

## Rollback Plan

If migration fails or feels wrong:

### Quick Rollback
```bash
# Restore status.zsh from backup
cp ~/.config/zsh/functions/status.zsh.backup ~/.config/zsh/functions/status.zsh

# Re-source
source ~/.config/zsh/.zshrc
```

### Alternative Solutions
If `up` doesn't work, try alternatives:
- `pup` (project update)
- `pset` (project set)
- `track` (track status)
- `pupdate` (project update, explicit)

---

## Success Criteria

Migration is successful if:

- [ ] `up` feels natural after 1 week
- [ ] No confusion about what `up` does
- [ ] `dash project` is intuitive
- [ ] `pinit` is clear enough (despite rare use)
- [ ] No muscle memory conflicts
- [ ] All documentation updated
- [ ] Tests pass (if any)

---

## Communication Plan

### Week 1 (Testing)
"Testing new command names. `status` → `up` for clarity."

### Week 2 (Deprecation)
"Migration in progress. Use `up`/`dash`/`pinit` instead of `status`."

### Week 3 (Completion)
"Migration complete! `status` removed. Use `up` to update, `dash` to show."

---

## File Checklist

### New Files to Create
- [ ] `/Users/dt/.config/zsh/functions/up.zsh`
- [ ] `/Users/dt/.config/zsh/functions/pinit.zsh`

### Files to Modify
- [ ] `/Users/dt/.config/zsh/functions/dash.zsh` (add single-project mode)
- [ ] `/Users/dt/.config/zsh/.zshrc` (source new functions)
- [ ] `/Users/dt/.config/zsh/functions/status.zsh` (deprecation warning, then remove)

### Documentation to Update
- [ ] `WORKFLOW-QUICK-REFERENCE.md`
- [ ] `ALIAS-REFERENCE-CARD.md`
- [ ] `.STATUS`
- [ ] `TODO.md`
- [ ] Help text in functions

### Backups to Create
- [ ] `/Users/dt/.config/zsh/functions/status.zsh.backup`
- [ ] `/Users/dt/.config/zsh/.zshrc.backup`

---

## Timeline Summary

| Week | Phase | Action | Time |
|------|-------|--------|------|
| 1 | Prep | Create `up.zsh`, `pinit.zsh` | 15 min |
| 1 | Test | Daily usage of new commands | 7 days |
| 2 | Deprecate | Add warnings, update docs | 30 min |
| 3 | Complete | Remove `status`, verify all | 15 min |

**Total Time:** ~1 hour of work + 2 weeks of testing

---

## Next Steps

1. **Read full research:** `CLI-COMMAND-PATTERNS-RESEARCH.md`
2. **Review alternatives:** `STATUS-COMMAND-ALTERNATIVES.md`
3. **Decide:** Confirm `up` is the right choice
4. **Implement:** Create `up.zsh` and `pinit.zsh`
5. **Test:** Use for 1 week
6. **Migrate:** Follow phases above

---

## Questions to Consider

Before implementing:

1. **Is `up` too short?** (Could conflict with `uptime` or other tools)
2. **Is `pinit` clear enough?** (Alternatives: `pnew`, `pcreate`)
3. **Should `dash project` be a separate command?** (Like `show project`)
4. **Any other commands with similar issues?** (Audit all commands)

---

## Reference

- **Research:** `CLI-COMMAND-PATTERNS-RESEARCH.md` (full analysis)
- **Alternatives:** `STATUS-COMMAND-ALTERNATIVES.md` (visual guide)
- **Current code:** `/Users/dt/.config/zsh/functions/status.zsh`

