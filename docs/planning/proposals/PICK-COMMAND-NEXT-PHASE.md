# Pick Command - Next Phase Enhancement Plan

**Created:** 2025-12-18
**Status:** 📋 Planning Phase
**Current Version:** v2.0 (Comprehensive Fix - Complete)
**Next Version:** v3.0 (Advanced Features)

---

## 🎯 Vision

Transform `pick` from a simple project switcher into a **powerful project command center** with:
- Smart context awareness (.STATUS integration)
- Rich preview pane
- Batch operations
- Recent/frecency-based suggestions
- Multi-action workflows

---

## ✅ Current State (v2.0 - Implemented 2025-12-18)

### Working Features
- ✅ Process substitution (no output pollution)
- ✅ Branch truncation (20 char limit)
- ✅ fzf key bindings (Ctrl-W, Ctrl-O)
- ✅ Fast mode (`--fast`)
- ✅ Category normalization (forgiving input)
- ✅ Dynamic headers
- ✅ Error handling

### Current Limitations
- ⚠️ No preview of project contents
- ⚠️ One project at a time (no multi-select)
- ⚠️ No recent/frecency sorting
- ⚠️ Limited actions (only cd, work, code)
- ⚠️ No .STATUS integration
- ⚠️ No performance caching

---

## 🚀 Enhancement Roadmap

### Phase 1: Preview Pane (P6A) - ⭐ RECOMMENDED NEXT

**Goal:** Show rich context about selected project before opening

**Effort:** 🔧 Medium (2-3 hours)

**Features:**
```bash
# fzf preview shows:
╭─ PROJECT INFO ────────────────────────────────╮
│ Name: mediationverse                          │
│ Type: R Package (📦)                          │
│ Path: ~/projects/r-packages/active/           │
│ Branch: main (⚠️ 1 uncommitted change)        │
├─ .STATUS ────────────────────────────────────│
│ Status: Active                                │
│ Progress: 75% (Phase 3/4)                     │
│ Next: Write unit tests for product-of-three  │
├─ RECENT ACTIVITY ────────────────────────────│
│ Last commit: 2 hours ago                      │
│ Last work session: Today 9:15am               │
├─ QUICK STATS ────────────────────────────────│
│ Files: 47 R scripts, 12 tests                 │
│ Size: 2.3 MB                                  │
╰───────────────────────────────────────────────╯
```

**Implementation:**
```zsh
# Add preview helper function
_pick_preview() {
    local dir="$1"

    # Project info
    echo "╭─ PROJECT INFO ────────────────────────────────╮"
    echo "│ Name: $(basename "$dir")"
    echo "│ Type: $(detect_project_type "$dir")"

    # Git status
    if [[ -d "$dir/.git" ]]; then
        local branch=$(git -C "$dir" branch --show-current)
        local changes=$(git -C "$dir" status --short | wc -l)
        echo "│ Branch: $branch ($changes changes)"
    fi

    # .STATUS file (if exists)
    if [[ -f "$dir/.STATUS" ]]; then
        echo "├─ .STATUS ────────────────────────────────────"
        grep "^status:" "$dir/.STATUS" | head -1
        grep "^progress:" "$dir/.STATUS" | head -1
        grep "^next:" "$dir/.STATUS" | head -1
    fi

    # Recent activity
    if [[ -d "$dir/.git" ]]; then
        echo "├─ RECENT ACTIVITY ────────────────────────────"
        local last_commit=$(git -C "$dir" log -1 --format="%ar")
        echo "│ Last commit: $last_commit"
    fi

    echo "╰───────────────────────────────────────────────╯"
}

# Update fzf call
fzf --preview='_pick_preview {4}' \
    --preview-window=right:50%:wrap \
    ...
```

**Benefits:**
- See project status before switching
- Understand context (last activity, pending work)
- Make informed decisions
- Reduce context switching cost

**Testing:**
- [ ] Preview shows for all project types
- [ ] .STATUS file parsed correctly
- [ ] Git info displays accurately
- [ ] Preview updates on selection change
- [ ] Handles missing .STATUS gracefully

---

### Phase 2: Recent Projects & Frecency (P6B)

**Goal:** Smart sorting based on usage patterns

**Effort:** 🔧 Medium (2-3 hours)

**Features:**
```bash
pick                 # Shows recent + frecency sorted
pick --recent        # Recent only (last 10)
pick --all           # All projects (alphabetical)

# Display shows recency indicator:
mediationverse       📦 r    ⚠️  [main]  🕐 2h ago
flow-cli    🔧 dev  ✅ [dev]    🕐 Today
claude-mcp           🔧 dev  ✅ [main]   🕐 Yesterday
```

**Implementation:**
```zsh
# Track usage in ~/.local/share/pick-history
_pick_record_access() {
    local proj_dir="$1"
    local timestamp=$(date +%s)
    local history_file="$HOME/.local/share/pick-history"

    # Append: timestamp|project_path
    echo "$timestamp|$proj_dir" >> "$history_file"

    # Keep last 1000 entries
    tail -1000 "$history_file" > "$history_file.tmp"
    mv "$history_file.tmp" "$history_file"
}

# Calculate frecency score
_pick_frecency_score() {
    local proj_dir="$1"
    local history_file="$HOME/.local/share/pick-history"
    local now=$(date +%s)
    local score=0

    # Weight recent accesses higher
    grep "|$proj_dir$" "$history_file" | while read line; do
        local ts=$(echo "$line" | cut -d'|' -f1)
        local age=$((now - ts))

        # Scoring: recent = higher weight
        if [[ $age -lt 3600 ]]; then
            score=$((score + 100))      # Last hour
        elif [[ $age -lt 86400 ]]; then
            score=$((score + 50))       # Last day
        elif [[ $age -lt 604800 ]]; then
            score=$((score + 10))       # Last week
        else
            score=$((score + 1))        # Older
        fi
    done

    echo "$score"
}
```

**Benefits:**
- Muscle memory: frequently-used projects bubble to top
- Time-aware: recent projects preferred over stale
- ADHD-friendly: less cognitive load (common projects on top)

**Testing:**
- [ ] History file created on first use
- [ ] Scores calculated correctly
- [ ] Sorting works (high score = top)
- [ ] Recency indicators accurate
- [ ] File doesn't grow unbounded

---

### Phase 3: Multi-Select & Batch Operations (P6C)

**Goal:** Operate on multiple projects at once

**Effort:** 🏗️ Large (3-4 hours)

**Features:**
```bash
pick --multi         # Enable multi-select mode

# In fzf:
# Tab: toggle selection
# Ctrl-A: select all visible
# Ctrl-D: deselect all

# Available batch actions:
# 1. Open all in workspace (VS Code multi-root)
# 2. Update all (git pull)
# 3. Check status on all
# 4. Run command on all (e.g., rcheck, npm test)
```

**Implementation:**
```zsh
pick() {
    local multi_mode=0
    if [[ "$1" == "--multi" ]]; then
        multi_mode=1
        shift
    fi

    # ... existing code ...

    if [[ $multi_mode -eq 1 ]]; then
        local selections=$(cat "$tmpfile" | fzf \
            --multi \
            --bind="ctrl-a:select-all,ctrl-d:deselect-all" \
            --header="Tab=select | Ctrl-A=all | Enter=action menu")

        if [[ -n "$selections" ]]; then
            _pick_batch_action "$selections"
        fi
    else
        # ... existing single-select code ...
    fi
}

_pick_batch_action() {
    local selections="$1"

    echo ""
    echo "╭─ BATCH ACTIONS ──────────────────────╮"
    echo "│ 1. Open in workspace (VS Code)      │"
    echo "│ 2. Git pull all                     │"
    echo "│ 3. Show status summary              │"
    echo "│ 4. Run custom command               │"
    echo "│ q. Cancel                            │"
    echo "╰──────────────────────────────────────╯"

    read -k1 action

    case "$action" in
        1) _pick_open_workspace "$selections" ;;
        2) _pick_git_pull_all "$selections" ;;
        3) _pick_status_summary "$selections" ;;
        4) _pick_custom_command "$selections" ;;
    esac
}

_pick_open_workspace() {
    # Create VS Code workspace file
    local workspace=$(mktemp --suffix=.code-workspace)

    echo '{"folders": [' > "$workspace"

    echo "$1" | while IFS='|' read -r line; do
        local proj_name=$(echo "$line" | awk '{print $1}')
        local proj_dir=$(_proj_find "$proj_name")
        echo "  {\"path\": \"$proj_dir\"}," >> "$workspace"
    done

    echo ']}' >> "$workspace"

    code "$workspace"
}
```

**Benefits:**
- Manage related projects together (e.g., all mediationverse packages)
- Bulk operations save time
- Workspace support for complex development

**Use Cases:**
- Update all R packages at once
- Open entire ecosystem in one workspace
- Check status across all research projects

---

### Phase 4: Advanced Actions (P6D)

**Goal:** More than just cd/work/code

**Effort:** 🔧 Medium (2 hours)

**New Actions:**
```bash
# In fzf:
Ctrl-F  → finish (commit + push)
Ctrl-S  → show .STATUS
Ctrl-G  → git graph (tig or lazygit)
Ctrl-T  → run tests
Ctrl-P  → create PR
Ctrl-I  → project info
```

**Implementation:**
```zsh
local selection=$(cat "$tmpfile" | fzf \
    --bind="ctrl-w:execute-silent(echo work > $action_file)+accept" \
    --bind="ctrl-o:execute-silent(echo code > $action_file)+accept" \
    --bind="ctrl-f:execute-silent(echo finish > $action_file)+accept" \
    --bind="ctrl-s:execute-silent(echo status > $action_file)+accept" \
    --bind="ctrl-g:execute-silent(echo graph > $action_file)+accept" \
    --bind="ctrl-t:execute-silent(echo test > $action_file)+accept" \
    --bind="ctrl-p:execute-silent(echo pr > $action_file)+accept" \
    --bind="ctrl-i:execute-silent(echo info > $action_file)+accept")

case "$action" in
    finish)
        cd "$proj_dir"
        finish "Auto-commit from pick"
        ;;
    status)
        cd "$proj_dir"
        if [[ -f .STATUS ]]; then
            bat .STATUS || cat .STATUS
        else
            echo "No .STATUS file found"
        fi
        ;;
    graph)
        cd "$proj_dir"
        if command -v tig &>/dev/null; then
            tig
        else
            git log --graph --oneline --all
        fi
        ;;
    test)
        cd "$proj_dir"
        pt  # Project test command (context-aware)
        ;;
    pr)
        cd "$proj_dir"
        gh pr create
        ;;
    info)
        _pick_preview "$proj_dir" | less
        ;;
esac
```

---

### Phase 5: Smart Filters (P6E)

**Goal:** Filter by attributes beyond category

**Effort:** 🔧 Medium (2 hours)

**Features:**
```bash
pick --dirty         # Only projects with uncommitted changes
pick --clean         # Only clean repos
pick --behind        # Projects behind remote
pick --stale         # Not touched in 30+ days
pick --active        # .STATUS = Active
pick --progress=50+  # .STATUS progress >= 50%
```

**Implementation:**
```zsh
_pick_apply_filters() {
    local filter="$1"
    local tmpfile="$2"

    case "$filter" in
        dirty)
            # Keep only projects with changes
            while IFS='|' read line; do
                local changes=$(echo "$line" | grep -o '⚠️')
                [[ -n "$changes" ]] && echo "$line"
            done < "$tmpfile"
            ;;
        clean)
            # Keep only clean projects
            while IFS='|' read line; do
                local clean=$(echo "$line" | grep -o '✅')
                [[ -n "$clean" ]] && echo "$line"
            done < "$tmpfile"
            ;;
        stale)
            # Projects not touched in 30 days
            local cutoff=$(($(date +%s) - 2592000))
            while IFS='|' read -r name type icon dir; do
                local last_mod=$(git -C "$dir" log -1 --format=%ct 2>/dev/null || echo 0)
                [[ $last_mod -lt $cutoff ]] && echo "$name|$type|$icon|$dir"
            done < <(cat "$tmpfile" | ...)
            ;;
    esac
}
```

---

### Phase 6: Performance Optimization (P6F)

**Goal:** Sub-100ms response time even with 100+ projects

**Effort:** 🏗️ Large (3-4 hours)

**Strategies:**

1. **Cache Git Status**
   ```zsh
   # Cache for 5 minutes
   _git_status_cached() {
       local dir="$1"
       local cache_file="/tmp/pick-cache-$(echo "$dir" | md5sum | cut -d' ' -f1)"
       local cache_max_age=300  # 5 minutes

       if [[ -f "$cache_file" ]]; then
           local cache_age=$(( $(date +%s) - $(stat -f %m "$cache_file") ))
           if [[ $cache_age -lt $cache_max_age ]]; then
               cat "$cache_file"
               return
           fi
       fi

       # Regenerate cache
       _proj_git_status "$dir" > "$cache_file"
       cat "$cache_file"
   }
   ```

2. **Parallel Git Calls**
   ```zsh
   # Use xargs for parallelism
   _proj_list_all | xargs -P 8 -I {} zsh -c '_proj_git_status_fast {}'
   ```

3. **Lazy Loading**
   ```zsh
   # Only load git status when preview opens
   # Use fzf's reload mechanism
   fzf --bind='focus:reload(_load_git_info {})' ...
   ```

---

## 📊 Prioritization Matrix

| Phase | Value | Effort | Priority | Est. Time |
|-------|-------|--------|----------|-----------|
| P6A: Preview Pane | ⭐⭐⭐⭐⭐ | Medium | **🔥 HIGH** | 2-3h |
| P6B: Frecency | ⭐⭐⭐⭐ | Medium | 🟡 Medium | 2-3h |
| P6D: Actions | ⭐⭐⭐⭐ | Medium | 🟡 Medium | 2h |
| P6E: Filters | ⭐⭐⭐ | Medium | 🟢 Low | 2h |
| P6C: Multi-Select | ⭐⭐⭐ | Large | 🟢 Low | 3-4h |
| P6F: Performance | ⭐⭐ | Large | 🔵 Future | 3-4h |

**Recommended Order:**
1. **P6A (Preview)** - Highest value, immediate benefit
2. **P6B (Frecency)** - ADHD-friendly, low complexity
3. **P6D (Actions)** - Builds on keybinding foundation
4. **P6E (Filters)** - Nice-to-have for power users
5. **P6C (Multi-Select)** - Complex, niche use case
6. **P6F (Performance)** - Only if needed (>50 projects)

---

## 🎯 Quick Wins (Can Implement Now - <30 min each)

### 1. Add Ctrl-S for .STATUS Quick View
```zsh
--bind="ctrl-s:execute(bat {4}/.STATUS 2>/dev/null || echo 'No .STATUS')"
```

### 2. Add Ctrl-L for Git Log
```zsh
--bind="ctrl-l:execute(git -C {4} log --oneline -10 | less)"
```

### 3. Add Color to Status Icons
```zsh
# In printf statement:
local status_icon="✅"
if [[ "$changes" -gt 0 ]]; then
    status_icon="\033[33m⚠️\033[0m"  # Yellow warning
fi
```

### 4. Show Uncommitted Count
```zsh
# Instead of just ⚠️, show: ⚠️(5)
printf "%-20s %s %-4s %s(%d) [%s]\n" \
    "$name" "$icon" "$type" "$status_icon" "$changes" "$branch_display"
```

### 5. Add Help Text at Bottom
```zsh
--header="Enter=cd | Ctrl-W=work | Ctrl-O=code | Ctrl-S=status | Ctrl-L=log | ?=help"
```

---

## 🧪 Testing Strategy

For each phase, test:

1. **Edge Cases:**
   - Empty project list
   - Projects without .git
   - Projects without .STATUS
   - Very long project names
   - Special characters in paths

2. **Performance:**
   - 10 projects: should be <50ms
   - 50 projects: should be <200ms
   - 100+ projects: should be <500ms

3. **UX:**
   - Key bindings don't conflict
   - Error messages are clear
   - Preview updates smoothly
   - Actions provide feedback

---

## 📝 Documentation Updates Needed

After each phase:

1. Update `PROPOSAL-PICK-COMMAND-ENHANCEMENT.md`
2. Update `WORKFLOW-QUICK-REFERENCE.md`
3. Update `ALIAS-REFERENCE-CARD.md`
4. Add examples to README.md
5. Update `ah project` help screen

---

## 🚦 Next Steps

**To start P6A (Preview Pane):**

1. Read current `pick` implementation
2. Create `_pick_preview()` helper function
3. Update fzf call with `--preview` flag
4. Test with 5-10 projects
5. Handle edge cases (no .STATUS, no git)
6. Document in proposal

**Estimated Time:** 2-3 hours
**Best Time:** When you have uninterrupted focus
**Dependencies:** None (can start immediately)

Would you like me to implement P6A (Preview Pane) now?
