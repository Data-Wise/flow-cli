# Smart Functions Help System Overhaul - Proposal

**Date:** 2025-12-14
**Status:** Proposal for Review
**Current State:** 8 functions, basic help with heredocs

---

## 📊 Current State Analysis

### What We Have

**Strengths:**
- ✅ All 8 functions have help systems
- ✅ Consistent pattern (`<cmd> help` or `<cmd> h`)
- ✅ Clear section headers (CORE, SESSION, MANAGE, etc.)
- ✅ Documentation of shortcuts that still work
- ✅ 100% test coverage

**Current Format Example:**
```bash
r help
# Output:
r <action> - R Package Development

CORE WORKFLOW:
  r load         Load package (devtools::load_all)
  r test         Run tests (devtools::test)
  r doc          Generate docs (devtools::document)
  r check        R CMD check (devtools::check)
  ...

SHORTCUTS STILL WORK:
  rload, rtest, rdoc, rcheck, rbuild, rinstall
```

### Pain Points Identified

1. **No Visual Hierarchy** - All text looks the same
2. **No Examples** - Users don't see actual usage
3. **No Context** - Can't see "related commands" or "typical workflow"
4. **Static Only** - No interactive elements
5. **Overwhelming** - Long lists for functions like `r` and `cc`
6. **No Quick Reference** - Can't get just the essentials
7. **No Colors** - Hard to scan quickly (ADHD issue)
8. **No Search** - Can't find specific action quickly

---

## 🎯 Design Goals (ADHD-Optimized)

### Core Principles

1. **Cognitive Load Reduction**
   - Quick scan in <3 seconds
   - Essential info first, details on demand
   - Visual cues (colors, icons, hierarchy)

2. **Multiple Access Patterns**
   - Quick mode: Show just essentials
   - Full mode: Complete reference
   - Example mode: See it in action
   - Search mode: Find specific action

3. **Progressive Disclosure**
   - Start with most common commands
   - Expand to advanced features
   - Layer complexity

4. **Visual Differentiation**
   - Colors for categories
   - Icons for command types
   - Highlighting for emphasis

---

## 💡 Proposed Options

### Option A: Enhanced Static Help (Low Effort)

**What Changes:**
- Add colors to section headers
- Add usage examples
- Add "Most Common" section at top
- Add related commands footer
- Better formatting

**Example Output:**
```bash
r help

╭─────────────────────────────────────────────────╮
│ r <action> - R Package Development              │
╰─────────────────────────────────────────────────╯

🔥 MOST COMMON (80% of usage):
  r test             Run tests
  r cycle            Full cycle: doc → test → check
  r load             Load package

💡 QUICK START EXAMPLES:
  r test             # Run all tests
  r test -f          # Run specific test file
  r cycle            # Complete dev cycle
  r info             # Show package status

📋 CORE WORKFLOW:
  r load             Load package (devtools::load_all)
  r test             Run tests (devtools::test)
  r doc              Generate docs (devtools::document)
  r check            R CMD check (devtools::check)
  r build            Build package (devtools::build)

🔀 COMBINED:
  r cycle            doc → test → check
  r quick            load → test

📊 QUALITY:
  r cov              Coverage report
  r spell            Spell check

🔗 RELATED: rload, rtest, rpkginfo
📚 MORE: r help full (for complete reference)
```

**Pros:**
- ✅ Easy to implement (just update heredocs)
- ✅ Backward compatible
- ✅ Immediate improvement
- ✅ No dependencies

**Cons:**
- ❌ Still static
- ❌ Colors may not work in all terminals
- ❌ No interactivity

**Effort:** 2-3 hours
**Risk:** Low

---

### Option B: Multi-Mode Help System (Medium Effort)

**What Changes:**
- Keep basic help as default
- Add modes: `help quick`, `help examples`, `help full`
- Add search: `help <keyword>`
- Add interactive picker (optional)

**Usage:**
```bash
r help              # Quick essentials
r help full         # Complete reference
r help examples     # Show usage examples
r help test         # Search for "test" related commands
r help --list       # List all actions (parseable)
```

**Example Quick Mode:**
```bash
r help

╭─ r - R Package Development ─╮
│ 🔥 Most Used:               │
│   r test      Run tests     │
│   r cycle     Full cycle    │
│   r load      Load package  │
│                             │
│ 💡 Try:                     │
│   r help examples           │
│   r help full               │
│   r help <action>           │
╰─────────────────────────────╯
```

**Example Full Mode:**
```bash
r help full
# Shows current full help with colors + examples
```

**Example Search:**
```bash
r help test

Found 3 commands matching "test":
  r test         Run all tests
  r quick        load → test (combined)
  rtest          Alias (backward compatible)

Examples:
  r test                    # Run all tests
  r test filter="regex"     # Run filtered tests

Related:
  r load, r cycle, rtestfile
```

**Implementation:**
```zsh
r() {
    # ... existing code ...

    case "$1" in
        help|h)
            local mode="${2:-quick}"  # Default to quick
            case "$mode" in
                quick)   _r_help_quick ;;
                full)    _r_help_full ;;
                examples) _r_help_examples ;;
                --list)  _r_help_list ;;
                *)       _r_help_search "$mode" ;;
            esac
            ;;
        # ... rest
    esac
}

_r_help_quick() {
    # Concise, most-used commands
}

_r_help_full() {
    # Current full help with enhancements
}

_r_help_examples() {
    # Real-world examples
}

_r_help_search() {
    # Search for keyword
}
```

**Pros:**
- ✅ Flexible (multiple modes)
- ✅ Quick reference available
- ✅ Search capability
- ✅ Progressive disclosure
- ✅ ADHD-friendly (less overwhelming)

**Cons:**
- ❌ More complex implementation
- ❌ Needs testing for all modes
- ❌ Slightly more to learn

**Effort:** 6-8 hours
**Risk:** Medium

---

### Option C: Interactive Help with fzf (Higher Effort)

**What Changes:**
- Add interactive picker using `fzf`
- Visual browsing of commands
- Preview pane with details
- Live search/filter

**Usage:**
```bash
r help              # Opens fzf picker
r help quick        # Static quick mode (no fzf)
r help --no-fzf     # Force static mode
```

**fzf Interface:**
```
┌─ r - Select Action ────────────────────────────────────────┐
│ > test                                                     │
│   load                                                     │
│   cycle                                                    │
│   quick                                                    │
│   doc                                                      │
│   check                                                    │
│   build                                                    │
│                                                            │
│ 7/25                                                       │
├────────────────────────────────────────────────────────────┤
│ Preview: r test                                            │
│                                                            │
│ Run all tests (devtools::test)                            │
│                                                            │
│ Examples:                                                  │
│   r test                 # All tests                       │
│   r test filter="foo"    # Specific tests                  │
│                                                            │
│ Related: r load, r quick, rtest                            │
└────────────────────────────────────────────────────────────┘
```

**Features:**
- ✅ Visual browsing
- ✅ Fuzzy search (type to filter)
- ✅ Preview pane with details
- ✅ Execute action directly (optional)
- ✅ Most ADHD-friendly option

**Implementation:**
```zsh
r() {
    case "$1" in
        help|h)
            if [[ "$2" == "quick" || "$2" == "--no-fzf" ]]; then
                _r_help_static
            elif command -v fzf >/dev/null; then
                _r_help_interactive
            else
                _r_help_static
            fi
            ;;
        # ... rest
    esac
}

_r_help_interactive() {
    local selected
    selected=$(cat <<'EOF' | fzf --preview '_r_preview {1}' --preview-window=right:50%
test|Run all tests|r test
load|Load package|r load
cycle|Full cycle: doc → test → check|r cycle
quick|load → test|r quick
doc|Generate docs|r doc
check|R CMD check|r check
...
EOF
)

    if [[ -n "$selected" ]]; then
        local action=$(echo "$selected" | cut -d'|' -f1)
        echo "Selected: r $action"
        # Optional: execute directly
        # eval "r $action"
    fi
}

_r_preview() {
    local action="$1"
    case "$action" in
        test) cat <<'EOF'
Run all tests (devtools::test)

Examples:
  r test                 # All tests
  r test filter="foo"    # Specific tests

Related: r load, r quick, rtest
EOF
        ;;
        # ... more previews
    esac
}
```

**Pros:**
- ✅ Most discoverable
- ✅ Best ADHD experience
- ✅ Visual and interactive
- ✅ Fuzzy search built-in
- ✅ Preview without executing

**Cons:**
- ❌ Requires fzf dependency
- ❌ More complex implementation
- ❌ Needs fallback for no-fzf
- ❌ Harder to test

**Effort:** 10-12 hours
**Risk:** Medium-High

---

### Option D: Hybrid Approach (Recommended)

**Combine best of all options:**

**Default: Quick Static Help (Option A style)**
```bash
r help
# Shows colorized quick reference
```

**Full: Complete Reference (Option B)**
```bash
r help full
# Shows complete help with all sections
```

**Interactive: fzf Browser (Option C)**
```bash
r help browse
# OR
r ?
# Opens fzf picker
```

**Search: Keyword Search**
```bash
r help test
# Search for "test" related commands
```

**Examples: Usage Examples**
```bash
r help examples
r help examples test    # Examples for "test" action
```

**Implementation Strategy:**
```zsh
r() {
    case "$1" in
        help|h)
            case "${2:-quick}" in
                quick|"")     _r_help_quick ;;          # Default
                full)         _r_help_full ;;            # Complete
                browse)       _r_help_interactive ;;     # fzf
                examples)     _r_help_examples "$3" ;;   # Examples
                --list)       _r_help_list ;;            # Machine readable
                *)            _r_help_search "$2" ;;     # Search
            esac
            return
            ;;

        \?)  # Shortcut for interactive help
            _r_help_interactive
            return
            ;;

        # ... rest of implementation
    esac
}
```

**Pros:**
- ✅ Best of all worlds
- ✅ Progressive disclosure
- ✅ Fallback for missing dependencies
- ✅ Flexible access patterns
- ✅ ADHD-optimized
- ✅ Power user friendly

**Cons:**
- ❌ Most complex implementation
- ❌ More code to maintain
- ❌ Needs comprehensive testing

**Effort:** 12-16 hours
**Risk:** Medium

---

## 🎨 Design Elements

### Color Scheme (Terminal Safe)

```bash
# Section headers
GREEN='\033[0;32m'      # 🔥 Most Common
BLUE='\033[0;34m'       # 📋 Core
YELLOW='\033[1;33m'     # 💡 Examples
CYAN='\033[0;36m'       # 🔗 Related
MAGENTA='\033[0;35m'    # 📚 More Info
NC='\033[0m'            # No Color
```

### Icons (Safe Alternatives)

```bash
# Unicode-safe icons
[FIRE]     🔥 or ⭐ or >
[INFO]     💡 or ℹ️ or i
[LIST]     📋 or • or -
[LINK]     🔗 or → or ->
[BOOK]     📚 or ? or h
[EXAMPLE]  💡 or $ or >
```

### Box Drawing (ASCII Safe)

```bash
# Unicode
╭──────╮
│ Text │
╰──────╯

# ASCII fallback
+------+
| Text |
+------+
```

---

## 📋 Implementation Checklist

### Phase 1: Quick Wins (Option A - 2-3 hours)
- [ ] Add color to section headers
- [ ] Add "Most Common" section
- [ ] Add examples to each function
- [ ] Add related commands footer
- [ ] Test colors in different terminals
- [ ] Update tests for new format

### Phase 2: Multi-Mode (Option B - 4-6 hours)
- [ ] Implement help modes (quick/full/examples)
- [ ] Implement search functionality
- [ ] Add --list mode for scripting
- [ ] Create helper functions
- [ ] Update all 8 functions
- [ ] Add tests for all modes

### Phase 3: Interactive (Option C - 6-8 hours)
- [ ] Implement fzf integration
- [ ] Create preview functions
- [ ] Add fallback for no-fzf
- [ ] Test interactive mode
- [ ] Document fzf dependency

### Phase 4: Polish (2-3 hours)
- [ ] Optimize performance
- [ ] Add completion hints
- [ ] Update documentation
- [ ] Create quick reference card
- [ ] User testing with ADHD workflows

---

## 🧪 Testing Strategy

### Unit Tests (Extend existing 91 tests)

```zsh
# Test help modes
test_r_help_quick()
test_r_help_full()
test_r_help_examples()
test_r_help_search()

# Test output format
test_help_has_colors()
test_help_has_examples()
test_help_has_most_common()

# Test fallbacks
test_help_no_fzf_fallback()
test_help_no_color_fallback()
```

### Manual Testing

- [ ] Test in iTerm2
- [ ] Test in Terminal.app
- [ ] Test in tmux
- [ ] Test with NO_COLOR env var
- [ ] Test without fzf installed
- [ ] Test in different screen sizes

---

## 📊 Comparison Matrix

| Feature | Current | Option A | Option B | Option C | Option D |
|---------|---------|----------|----------|----------|----------|
| Colors | ❌ | ✅ | ✅ | ✅ | ✅ |
| Examples | ❌ | ✅ | ✅ | ✅ | ✅ |
| Quick Mode | ❌ | ✅ | ✅ | ✅ | ✅ |
| Full Mode | ✅ | ✅ | ✅ | ✅ | ✅ |
| Search | ❌ | ❌ | ✅ | ✅ | ✅ |
| Interactive | ❌ | ❌ | ❌ | ✅ | ✅ |
| fzf Picker | ❌ | ❌ | ❌ | ✅ | ✅ |
| Effort | 0h | 2-3h | 6-8h | 10-12h | 12-16h |
| Risk | Low | Low | Med | Med-High | Med |
| ADHD Score | 5/10 | 7/10 | 8/10 | 9/10 | 10/10 |

---

## 🎯 Recommendations

### Recommended Approach: **Option D (Hybrid)**

**Why:**
1. **Best ADHD Experience** - Multiple access patterns
2. **Progressive Adoption** - Can implement in phases
3. **Backward Compatible** - Old help still works
4. **Future Proof** - Room to grow
5. **Flexible** - Works with or without fzf

### Implementation Phases:

**Week 1: Foundation (Option A)**
- Implement colorized quick help
- Add examples and most common sections
- Deploy and gather feedback

**Week 2: Modes (Option B)**
- Add help modes (quick/full/examples)
- Implement search
- Update documentation

**Week 3: Interactive (Option C)**
- Add fzf integration
- Create preview functions
- Polish and optimize

**Week 4: Refinement**
- User testing
- Performance optimization
- Documentation updates
- Release v2.0

---

## 🔍 Example: Complete "r" Help Overhaul

### Current State:
```bash
r help
# Plain text, no colors, comprehensive but overwhelming
```

### Proposed (Quick Mode):
```bash
r help

╭─ r - R Package Development ─╮
│                              │
│ 🔥 Most Common:              │
│   r test      Run tests      │
│   r cycle     Full cycle     │
│   r load      Load package   │
│                              │
│ 💡 Examples:                 │
│   r test                     │
│   r cycle                    │
│   r load && r test           │
│                              │
│ 📚 More Help:                │
│   r help full                │
│   r help examples            │
│   r ? (interactive)          │
╰──────────────────────────────╯
```

### Proposed (Full Mode):
```bash
r help full

╭──────────────────────────────────────╮
│ r <action> - R Package Development   │
╰──────────────────────────────────────╯

🔥 MOST COMMON (80% of usage):
  r test             Run tests
  r cycle            Full cycle
  r load             Load package

💡 EXAMPLES:
  r test                    # Run all tests
  r test filter="auth"      # Test auth module
  r cycle                   # doc → test → check
  r load && r test          # Quick iteration

📋 CORE WORKFLOW:
  r load             Load package
  r test             Run tests
  r doc              Generate docs
  r check            R CMD check
  r build            Build package
  r install          Install package

🔀 COMBINED:
  r cycle            doc → test → check
  r quick            load → test

📊 QUALITY:
  r cov              Coverage report
  r spell            Spell check

📚 DOCUMENTATION:
  r pkgdown          Build pkgdown site
  r preview          Preview site

🏷️ VERSION:
  r patch            Bump patch (0.0.X)
  r minor            Bump minor (0.X.0)
  r major            Bump major (X.0.0)

ℹ️ INFO:
  r info             Package summary
  r tree             Package structure

🔗 SHORTCUTS STILL WORK:
  rload, rtest, rdoc, rcheck, rbuild

📚 MORE HELP:
  r help examples test      # Examples for test
  r help test              # Search "test"
  r ?                      # Interactive picker
```

### Proposed (Interactive Mode):
```bash
r ?

# Opens fzf with all actions, live search, preview
```

---

## 💭 Open Questions

1. **Should we support ZSH completion?**
   - Could add `compdef` for native tab completion
   - Would need custom completion functions
   - Effort: 4-6 hours additional

2. **Should help be paginated?**
   - Use `less` for long help output?
   - Or always fit on screen?

3. **Should we support NO_COLOR env var?**
   - Respect NO_COLOR=1 for accessibility
   - Add --no-color flag

4. **Should examples be executable?**
   - Allow running examples directly from help
   - Confirmation before execution

5. **Should we add man-style pages?**
   - More detailed documentation
   - `r man test` for full details

---

## 📞 Next Steps

**Decision Needed:**
- Which option to pursue?
- Phase implementation or all-at-once?
- Priority order if phased?

**User Input:**
- What help patterns do you use most?
- What frustrates you about current help?
- Which option excites you most?
- Any must-have features?

---

**Created:** 2025-12-14 20:15
**Status:** Awaiting User Feedback
**Effort Estimates:** Conservative (include testing)
**Risk Assessment:** Based on complexity and dependencies
