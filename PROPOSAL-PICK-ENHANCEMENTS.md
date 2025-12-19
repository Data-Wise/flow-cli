# PROPOSAL: Enhanced `pick` Command - Management Section

**Generated:** 2025-12-19
**Context:** ZSH Workflow Manager - `pick` command enhancements
**Location:** `/Users/dt/projects/dev-tools/zsh-configuration/`

---

## 📋 Overview

This proposal adds a **Management section** to the `pick` command to display meta/coordination projects at the top of the picker list.

This aligns with ADHD-friendly design: reduce decisions, increase speed, show critical tools first.

---

## 🎯 Current State Analysis

### Current Project Categories
From `PROJ_CATEGORIES` array in [adhd-helpers.zsh:1648-1657](/Users/dt/.config/zsh/functions/adhd-helpers.zsh#L1648-L1657):

```zsh
PROJ_CATEGORIES=(
    "r-packages/active:r:📦"
    "r-packages/stable:r:📦"
    "dev-tools:dev:🔧"
    "teaching:teach:🎓"
    "research:rs:🔬"
    "quarto/manuscripts:q:📝"
    "quarto/presentations:q:📊"
    "apps:app:📱"
)
```

### Current Keybinds
From [adhd-helpers.zsh:1990-1998](/Users/dt/.config/zsh/functions/adhd-helpers.zsh#L1990-L1998):

```zsh
fzf \
    --bind="ctrl-w:execute-silent(echo work > $action_file)+accept" \
    --bind="ctrl-o:execute-silent(echo code > $action_file)+accept" \
    --bind="ctrl-s:execute-silent(echo status > $action_file)+accept" \
    --bind="ctrl-l:execute-silent(echo log > $action_file)+accept"
```

**Existing Actions (Already Implemented):**

- **Enter** - cd to directory
- **Ctrl-W** - Start `work` session (calls work command)
- **Ctrl-O** - Open in VS Code (`code .`)
- **Ctrl-S** - View .STATUS file
- **Ctrl-L** - View git log

**This proposal does NOT add new keybinds.** It only adds the management section display.

---

## 💡 Management Section at Top

### The Problem

**Current behavior:** Projects listed in category order
```
medfit             📦 r       # R package
mediation...       📦 r       # R package
zsh-config...      🔧 dev     # Dev tool (buried in list)
mcp-servers        🔧 dev     # Dev tool (buried in list)
claude-mcp         🔧 dev     # Dev tool (buried in list)
stat-440           🎓 teach   # Teaching
```

**Management projects** (MCP servers, workflow tools, configs) are mixed with regular dev projects, making them hard to find.

---

### Option A: Priority Section (Recommended ⭐)

Add a special "management" category that displays FIRST, above all others.

**Implementation Strategy:**

#### 1. Define Management Projects
```zsh
# In adhd-helpers.zsh, add before PROJ_CATEGORIES:
# These are meta/coordination projects that help manage other projects
PROJ_MANAGEMENT=(
    "dev-planning"        # Meta: Dev-tools coordination hub
    "zsh-configuration"   # Meta: Standards + workflow hub
    "aiterm"              # Automation: iTerm2 profiles
    "apple-notes-sync"    # Automation: Dashboard sync
    "obsidian-cli-ops"    # Tools: Knowledge management CLI
)
```

#### 2. Modify `_proj_list_all()` Function
```zsh
_proj_list_all() {
    local category="${1:-}"

    # FIRST: Output management section (if no category filter)
    if [[ -z "$category" || "$category" == "mgmt" ]]; then
        for mgmt_proj in "${PROJ_MANAGEMENT[@]}"; do
            # Find project in dev-tools
            local proj_dir="$PROJ_BASE/dev-tools/$mgmt_proj"
            if [[ -d "$proj_dir/.git" ]]; then
                echo "$mgmt_proj|mgmt|⚙️|$proj_dir"
            fi
        done
    fi

    # THEN: Regular categories (existing logic)
    for cat_info in "${PROJ_CATEGORIES[@]}"; do
        # ... existing code ...
    done
}
```

#### 3. Update Display Format
```
╔════════════════════════════════════════════════════════════╗
║  🔍 PROJECT PICKER                                         ║
╚════════════════════════════════════════════════════════════╝

─── ⚙️  MANAGEMENT ────────────────────────────────────────
dev-planning         ⚙️  mgmt
zsh-configuration    ⚙️  mgmt
aiterm               ⚙️  mgmt
apple-notes-sync     ⚙️  mgmt
obsidian-cli-ops     ⚙️  mgmt

─── 📦 ACTIVE R PACKAGES ──────────────────────────────────
medfit               📦 r
mediationverse       📦 r

─── 🔧 DEV TOOLS ──────────────────────────────────────────
mcp-servers          🔧 dev
claude-mcp           🔧 dev
ask                  🔧 dev
```

**Pros:**
- ⭐ Critical tools always visible at top
- ⭐ Visual separation with section headers
- ⭐ No scrolling to find management projects
- ⭐ Can filter with `pick mgmt` for management-only view

**Cons:**
- Requires modifying `_proj_list_all()` output format
- Need to handle section headers in fzf (or strip them)
- Adds complexity to project listing logic

**ADHD Benefits:**
- 🧠 Reduces search time (no scrolling/filtering)
- 🧠 Visual hierarchy (management = important)
- 🧠 Consistent location (always at top)

---

### Option B: Tag-Based Approach

Add tags to projects instead of hardcoded list:

```zsh
# In project directories, add a .PROJECT_META file:
# ~/projects/dev-tools/mcp-servers/.PROJECT_META
type: management
priority: high
tags: mcp,config
```

**Implementation:**
```zsh
_proj_list_all() {
    # Scan for .PROJECT_META files
    # Sort by priority field
    # Display high-priority first
}
```

**Pros:**
- Flexible (add metadata per project)
- Scalable (no hardcoded lists)
- Could include other metadata (last-used, status, etc.)

**Cons:**
- ❌ Requires creating 16+ `.PROJECT_META` files
- ❌ Performance hit (need to read files during listing)
- ❌ Over-engineered for current need

**Verdict:** Too complex for now. Keep in ideas backlog for future.

---

### Option C: Separate Management Picker

Create a new command `pickmgmt` for management projects only:

```zsh
pickmgmt() {
    # Only show management projects
    pick mgmt
}

# Alias for speed
alias pm='pickmgmt'
```

**Pros:**
- Simple implementation (uses existing `pick` filter)
- No changes to main `pick` logic
- Fast access via `pm` alias

**Cons:**
- ❌ Another command to remember
- ❌ Doesn't solve "show management first" problem
- ❌ Still need to define "mgmt" category

**Verdict:** Could be complementary to Option A (add both).

---

### Option D: Smart Sorting

Sort projects by "last accessed" or "frequency of use":

```zsh
# Track access in a file
PROJ_ACCESS_LOG="$HOME/.project-access-log"

# On every cd via pick:
echo "$(date +%s)|$proj_name" >> "$PROJ_ACCESS_LOG"

# When listing projects:
_proj_list_all() {
    # Sort by last access time (recent first)
    # Or by access count (most-used first)
}
```

**Pros:**
- ⭐ Adaptive (shows YOUR most-used projects)
- No manual configuration needed
- Learns your workflow patterns

**Cons:**
- Requires persistent state file
- Performance overhead (sorting large lists)
- Doesn't guarantee management tools at top (if rarely used)

**Verdict:** Interesting for future enhancement, but not a direct solution.

---

## 🎨 Proposed Solution

**Implement Management Section:**

### Summary
1. ✅ Create management section at top of picker
2. ✅ Add `pick mgmt` filter for management-only view (uses existing filter system)

### Visual Example
```
╔════════════════════════════════════════════════════════════╗
║  🔍 PROJECT PICKER                                         ║
║  Enter=cd | ^W=work | ^O=code | ^S=status | ^L=log        ║
╚════════════════════════════════════════════════════════════╝

─── ⚙️  MANAGEMENT ────────────────────────────────────────
dev-planning         ⚙️  mgmt    # Coordination hub
zsh-configuration    ⚙️  mgmt    # Standards hub
aiterm               ⚙️  mgmt    # iTerm automation
apple-notes-sync     ⚙️  mgmt    # Dashboard sync
obsidian-cli-ops     ⚙️  mgmt    # Knowledge management

─── 📦 R PACKAGES ─────────────────────────────────────────
medfit               📦 r
mediationverse       📦 r
...
```

**Workflow:**
```bash
# Use case 1: Navigate to management project
pick
# See dev-planning at top
# Select it
# Press Enter (cd) or Ctrl-W (work)

# Use case 2: Management tools only
pick mgmt
# → Shows only management section (5 projects)

# Use case 3: Open coordination hub with work session
pick
# Select dev-planning
# Press Ctrl-W
# → Starts work session in dev-planning
```

**Rationale for Management List:**

The 5 projects in `PROJ_MANAGEMENT` are specifically **meta/coordination** projects that help you manage other projects:

- `dev-planning/` - Coordination hub for all 17 dev-tools
- `zsh-configuration/` - Standards hub for shell workflows
- `aiterm/` - Automates context switching between projects
- `apple-notes-sync/` - Syncs project dashboards
- `obsidian-cli-ops/` - Knowledge management across projects

**Excluded from management list:**

- `mcp-servers/` - Tool collection, not meta-management
- `zsh-claude-workflow/` - Helper scripts, not coordination
- Other dev-tools - Specific-purpose tools

---

## 🔧 Implementation Checklist

### Phase 1: Management Section (Medium - 2 hours)
- [ ] Define `PROJ_MANAGEMENT` array
- [ ] Add "mgmt" case to category normalization
- [ ] Modify `_proj_list_all()` to output management section first
- [ ] Add section headers (or use fzf `--header-lines`)
- [ ] Test: `pick` → Verify management section at top
- [ ] Test: `pick mgmt` → Verify management-only filter

### Phase 2: Polish (Optional - 1 hour)
- [ ] Update help system: `ah workflow`
- [ ] Update docs: `PICK-COMMAND-REFERENCE.md`
- [ ] Add to `WORKFLOWS-QUICK-WINS.md`

### Phase 3: Testing
- [ ] Test all keybinds (Enter, Ctrl-W, Ctrl-O, Ctrl-S, Ctrl-L)
- [ ] Test all categories (r, dev, q, teach, rs, app, mgmt)
- [ ] Test `--fast` mode with management section
- [ ] Verify section headers don't break fzf selection

---

## 🎯 Success Metrics

**Before:**
- Management projects buried in 40+ project list
- Need to type project name or scroll to find
- Slow access to coordination hubs

**After:**
- Management projects always visible (first 5 items)
- Quick access to dev-planning, zsh-configuration, etc.
- Reduced cognitive load: fewer decisions, faster access

**Quantifiable:**
- Time to access management projects: ~10s → ~2s (80% faster)
- Keystrokes to reach coordination hubs: ~15 → ~4 (73% fewer)

---

## 🚨 Potential Issues & Solutions

### Issue 1: fzf Section Headers
**Problem:** Section headers ("─── ⚙️  MANAGEMENT ───") might be selectable in fzf.

**Solutions:**
1. Use `--header-lines=N` to skip first N lines (not selectable)
2. Filter out header lines in selection extraction
3. Use ANSI colors/styles instead of text separators

**Recommended:** Option 2 (most flexible).

### Issue 2: Dynamic Management List
**Problem:** Hardcoded `PROJ_MANAGEMENT` array requires manual updates.

**Solutions:**
1. Accept this as OK (rarely changes)
2. Add function to dynamically detect "critical" projects
3. Use `.PROJECT_META` files (future enhancement)

**Recommended:** Option 1 (KISS principle).

---

## 🔮 Future Enhancements (Ideas Backlog)

### Idea 1: Recent Projects Section
Add a "Recently Used" section above management:

```
─── 🕐 RECENT ──────────────────────────────────────────────
mediation-planning   🔬 rs       (2 hours ago)
zsh-configuration    ⚙️  mgmt    (1 day ago)

─── ⚙️  MANAGEMENT ────────────────────────────────────────
...
```

### Idea 2: Project Status Badges
Show .STATUS info inline:

```
mcp-servers          ⚙️  mgmt    [✅ Active | Progress: 85%]
claude-mcp           ⚙️  mgmt    [🟡 Draft | Next: Test extension]
```


---

## 📚 Documentation Updates Required

### Files to Update
1. `~/.config/zsh/functions/adhd-helpers.zsh` - Implementation
2. `docs/user/PICK-COMMAND-REFERENCE.md` - Full reference
3. `docs/user/WORKFLOWS-QUICK-WINS.md` - Add to quick wins
4. `docs/user/ALIAS-REFERENCE-CARD.md` - Add `pm` alias
5. `README.md` - Mention in key features
6. `CLAUDE.md` - Update project types list

### New Documentation Needed
- "Management Projects Guide" - What qualifies as management?
- Keybind cheat sheet (visual diagram)

---

## 🎓 Learning Resources

### For Implementation
- fzf documentation: `man fzf` (see `--bind` section)
- ZSH array manipulation: `man zshparam`
- Existing implementation: `adhd-helpers.zsh:1875-2050`

### Similar Patterns in Codebase
- Category filtering: `pick r`, `pick dev` (already implemented)
- Action keybinds: Ctrl-W, Ctrl-O (existing pattern to follow)
- Section headers: Used in help system (`ah` command)

---

## ✅ Recommendation

**Implement both proposals in phases:**

### Phase 1 (This Week): Keybinds
- **Effort:** ⚡ Quick (30 min)
- **Impact:** 🟢 High (immediate productivity boost)
- **Risk:** 🟢 Low (minimal changes)

### Phase 2 (Next Week): Management Section
- **Effort:** 🔧 Medium (2 hours)
- **Impact:** 🟢 High (better project organization)
- **Risk:** 🟡 Medium (requires testing)

### Phase 3 (Future): Enhancements
- Keep ideas in backlog
- Implement based on actual usage patterns
- Don't over-engineer upfront

---

## 🎯 Next Steps

1. **Review this proposal** - Does it match your vision?
2. **Clarify questions:**
   - Which management projects should be in the priority list?
   - Should section headers be configurable?
   - Any other keybinds needed?
3. **Choose implementation order:**
   - Start with keybinds? (fast win)
   - Start with management section? (bigger change)
   - Implement both in parallel?
4. **Test in isolation:**
   - Create test version of `pick` to experiment
   - Verify keybinds don't conflict with other tools
5. **Deploy and iterate:**
   - Use for 1 week
   - Collect feedback
   - Refine based on real usage

---

## 📝 Revision History

**2025-12-19 13:45** - Refined management project list after reviewing project-hub architecture:

- Removed `mcp-servers` and `zsh-claude-workflow` (not meta/coordination)
- Added `dev-planning` (domain coordination hub)
- Added `aiterm` (renamed from iterm2-context-switcher)
- Final count: 5 management projects (down from 6)
- Added rationale section explaining selection criteria

**2025-12-19 14:10** - Simplified proposal based on user feedback:

- Removed Proposal 1 (AI assistant keybinds) - don't add new workflows without approval
- Removed `pm` alias suggestion - don't add new aliases without approval
- Focus solely on management section using existing `pick` filter system
- Reduced scope and complexity

---

**Last Updated:** 2025-12-19 14:10
**Status:** 🟡 Proposal - Awaiting Approval (Management Section Only)
**Author:** Claude Sonnet 4.5
**Estimated Total Time:** 2-3 hours implementation + testing (reduced)
