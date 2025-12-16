# Response Viewer Refactoring Task

**Date:** 2025-12-16
**Priority:** Medium
**Effort:** 1-2 hours
**Status:** Ready for Implementation

---

## 🎯 Goal

Refactor Claude response viewer from flat namespace (`glowclip`, `glowlast`, etc.) to professional dispatcher pattern (`resp <subcommand>`).

---

## 📋 Current Implementation

**Location:** `~/.config/zsh/functions/claude-response-viewer.zsh` (420 lines)

**Current Commands (Flat Namespace):**
```bash
glowsplit <file> ["Title"] [mode]   # Save file and open
glowclip "Title" [mode]             # Save from clipboard
glowlast [mode]                     # View last response
glowlist                            # List all responses
glowopen <number> [mode]            # Open specific response
glowclean [keep]                    # Delete old responses
glowhelp                            # Show help
```

**Problems:**
1. ❌ Pollutes namespace (7 commands)
2. ❌ Not discoverable (hard to remember all commands)
3. ❌ Doesn't match modern CLI patterns (git, docker, kubectl)
4. ❌ Inconsistent with user's existing patterns (`vibe`, `work`, `focus`)

---

## 🎨 Proposed Design

### Main Dispatcher: `resp`

**Why `resp`:**
- ✅ Short (4 letters)
- ✅ Semantic (response)
- ✅ Matches existing style (`vibe`, `work`, `focus`, `win`)
- ✅ Professional (single namespace)
- ✅ ADHD-friendly (clear action verb)

### Subcommand Structure

```bash
resp <subcommand> [args]

# Core subcommands:
resp clip "Title" [mode]      # Save from clipboard
resp split <file> [title] [mode]  # Save from file
resp last [mode]              # View last saved
resp list                     # List all saved
resp open <#> [mode]          # Open by number
resp clean [keep]             # Delete old
resp help                     # Show help

# Aliases (for discoverability):
resp ls         → resp list
resp rm         → resp clean
resp view       → resp last
```

### Viewing Modes (Unchanged)

```bash
split    # iTerm2 horizontal split (default)
tab      # iTerm2 new tab
window   # iTerm2 new window
default  # System default app
none     # Just save, don't open
```

---

## 📂 Current File Structure

**Main File:** `~/.config/zsh/functions/claude-response-viewer.zsh`

**Key Functions:**
```bash
# Main commands
glowsplit()           # Lines 22-82
glowclip()            # Lines 206-216
glowlast()            # Lines 219-244
glowlist()            # Lines 247-273
glowopen()            # Lines 275-311
glowclean()           # Lines 314-339

# Helper functions (keep these)
_open_in_split()      # Lines 85-120
_open_in_tab()        # Lines 123-153
_open_in_window()     # Lines 156-184
_open_with_default()  # Lines 189-203
_glowsplit_help()     # Lines 342-403
_glowsplit_widget()   # Lines 261-264

# Configuration (keep)
CLAUDE_RESPONSES_DIR="$HOME/.claude/responses"
CLAUDE_CURRENT_RESPONSE="$CLAUDE_RESPONSES_DIR/current.md"
```

---

## 🔧 Implementation Plan

### Step 1: Create Dispatcher Function

**New function:** `resp()`

```bash
resp() {
    local subcommand="${1:-help}"
    shift

    case "$subcommand" in
        clip|clipboard)
            _resp_clip "$@"
            ;;
        split|save)
            _resp_split "$@"
            ;;
        last|view)
            _resp_last "$@"
            ;;
        list|ls)
            _resp_list "$@"
            ;;
        open)
            _resp_open "$@"
            ;;
        clean|rm)
            _resp_clean "$@"
            ;;
        help|--help|-h)
            _resp_help
            ;;
        *)
            echo "❌ Unknown subcommand: $subcommand"
            echo ""
            _resp_help
            return 1
            ;;
    esac
}
```

### Step 2: Rename Internal Functions

**Rename pattern:** `glowXXX()` → `_resp_XXX()`

```bash
# Old → New
glowsplit()    → _resp_split()
glowclip()     → _resp_clip()
glowlast()     → _resp_last()
glowlist()     → _resp_list()
glowopen()     → _resp_open()
glowclean()    → _resp_clean()
_glowsplit_help() → _resp_help()
```

**Keep unchanged:**
- `_open_in_split()`
- `_open_in_tab()`
- `_open_in_window()`
- `_open_with_default()`
- Configuration variables

### Step 3: Add Backward Compatibility (Optional)

```bash
# Deprecation aliases (keep for 1 month)
glowclip() {
    echo "⚠️  'glowclip' is deprecated. Use 'resp clip' instead."
    resp clip "$@"
}

glowlast() {
    echo "⚠️  'glowlast' is deprecated. Use 'resp last' instead."
    resp last "$@"
}

# ... etc for all old commands
```

### Step 4: Update Help Text

**New help:** `_resp_help()`

```bash
_resp_help() {
    cat << 'EOF'
╔════════════════════════════════════════════════════════════╗
║        📖 Claude Response Manager                          ║
╚════════════════════════════════════════════════════════════╝

USAGE:
  resp <subcommand> [args]

SUBCOMMANDS:
  clip <title> [mode]      Save from clipboard and view
  split <file> [title] [mode]  Save file and view
  last [mode]              View last saved response
  list                     List all saved responses
  open <number> [mode]     Open specific response
  clean [keep]             Delete old responses (default: keep 10)
  help                     Show this help

ALIASES:
  ls         → list
  rm         → clean
  view       → last

VIEWING MODES:
  split      iTerm2 horizontal split (default)
  tab        iTerm2 new tab
  window     iTerm2 new window
  default    System default markdown app
  none       Just save, don't open

EXAMPLES:
  # Save from clipboard
  resp clip "Brainstorm Results"
  resp clip "Analysis" tab

  # View last response
  resp last
  resp last window

  # List and open
  resp list
  resp open 3 tab

  # Clean up
  resp clean 10

See: ~/.config/zsh/functions/claude-response-viewer.zsh
EOF
}
```

### Step 5: Update Sourcing (if needed)

File is already sourced in `~/.config/zsh/.zshrc`:

```bash
# Claude Response Viewer with Glow (2025-12-16)
if [[ -f ~/.config/zsh/functions/claude-response-viewer.zsh ]]; then
    source ~/.config/zsh/functions/claude-response-viewer.zsh
fi
```

**No changes needed** - refactoring is internal to the file.

---

## 🧪 Testing Checklist

After refactoring, test all commands:

```bash
# Test save from clipboard
resp clip "Test Response"
resp clip "Test Tab" tab
resp clip "Test Window" window
resp clip "Test Default" default
resp clip "Test None" none

# Test view last
resp last
resp last tab
resp last window
resp last default

# Test list
resp list
resp ls  # alias

# Test open
resp open 1
resp open 1 tab
resp open 1 window

# Test clean
resp clean 5

# Test help
resp help
resp --help
resp -h
resp  # (should show help)

# Test unknown subcommand
resp foo  # Should show error + help

# Test backward compatibility (if implemented)
glowclip "Old Command Test"  # Should warn + work
glowlast  # Should warn + work
```

---

## 📊 Migration Strategy

### Phase 1: Internal Refactor (Week 1)
- ✅ Rename functions to `_resp_*`
- ✅ Create `resp()` dispatcher
- ✅ Update help text
- ✅ Test all subcommands

### Phase 2: User Transition (Week 2-3)
- ✅ Add deprecation warnings to old commands
- ✅ Update documentation
- ✅ Update PROMPT-MODES-GUIDE.md
- ✅ Announce change

### Phase 3: Cleanup (Week 4+)
- ✅ Remove old command aliases
- ✅ Remove deprecation warnings
- ✅ Final documentation update

---

## 📚 Files to Update

**Implementation:**
1. `~/.config/zsh/functions/claude-response-viewer.zsh` - Main refactor

**Documentation:**
2. `~/.claude/PROMPT-MODES-GUIDE.md` - Update examples
3. `~/.claude/GLOW-RESPONSE-VIEWER-REFCARD.md` - Update all commands
4. `~/.claude/RESPONSE-VIEWER-IMPLEMENTATION.md` - Update implementation details

**Testing:**
5. Create test script: `~/.config/zsh/tests/test-resp-commands.sh`

---

## 🎯 Success Criteria

**Functionality:**
- ✅ All subcommands work (`clip`, `split`, `last`, `list`, `open`, `clean`)
- ✅ All viewing modes work (split, tab, window, default, none)
- ✅ Tab completion works (optional enhancement)
- ✅ Help text is clear and comprehensive

**User Experience:**
- ✅ `resp` alone shows help (discoverable)
- ✅ `resp <tab>` shows subcommands (if completion added)
- ✅ Error messages are helpful
- ✅ Backward compatibility maintained (during transition)

**Documentation:**
- ✅ All docs updated with new syntax
- ✅ Migration guide provided
- ✅ Examples are current

---

## 💡 Optional Enhancements

### Tab Completion

**File:** `~/.config/zsh/completions/_resp`

```bash
#compdef resp

_resp() {
    local -a subcommands
    subcommands=(
        'clip:Save from clipboard'
        'split:Save from file'
        'last:View last response'
        'list:List all responses'
        'open:Open specific response'
        'clean:Delete old responses'
        'help:Show help'
    )

    _arguments \
        '1: :->subcommand' \
        '*::arg:->args'

    case $state in
        subcommand)
            _describe 'subcommand' subcommands
            ;;
        args)
            case $words[1] in
                clip|split|last|open)
                    local -a modes
                    modes=(split tab window default none)
                    _describe 'viewing mode' modes
                    ;;
            esac
            ;;
    esac
}

_resp "$@"
```

**Enable:**
```bash
# Add to ~/.config/zsh/.zshrc
fpath=(~/.config/zsh/completions $fpath)
```

---

## 🔗 Related Projects

**Integration Points:**
- Background modes (`[analyze:bg]`, etc.) - Use `resp` for viewing results
- PROMPT-MODES-GUIDE.md - Update workflow examples
- Response viewer already integrated with background agents

---

## 📝 Example PR Description

```markdown
# Refactor: Response Viewer → `resp` Dispatcher Pattern

## Summary
Refactor Claude response viewer from flat namespace (`glowclip`, `glowlast`)
to modern dispatcher pattern (`resp <subcommand>`).

## Changes
- ✅ Created `resp()` dispatcher function
- ✅ Renamed internal functions: `glowXXX()` → `_resp_XXX()`
- ✅ Updated help text
- ✅ Added backward compatibility aliases (temporary)
- ✅ Updated all documentation

## Benefits
- Professional CLI pattern (like git, docker)
- Single namespace (7 commands → 1 command)
- More discoverable (`resp help`)
- Tab completion ready
- Matches existing style (`vibe`, `work`, `focus`)

## Migration
Old commands work with deprecation warnings for 1 month:
```bash
glowclip "Title"  # ⚠️ Deprecated, use: resp clip "Title"
```

## Testing
- ✅ All subcommands tested
- ✅ All viewing modes tested
- ✅ Backward compatibility verified
- ✅ Documentation updated

## Breaking Changes
None (backward compatible during transition)

## Files Changed
- `functions/claude-response-viewer.zsh` (refactored)
- `PROMPT-MODES-GUIDE.md` (updated examples)
- `GLOW-RESPONSE-VIEWER-REFCARD.md` (updated commands)
```

---

## 🚀 Ready to Implement

**Estimated Time:** 1-2 hours
**Complexity:** Low (mostly renaming)
**Risk:** Low (backward compatible)
**Impact:** High (better UX)

**Next Step:** Assign to zsh-configuration project for implementation.

---

**Handoff Date:** 2025-12-16
**Created By:** Claude (Phase 1 Background Agents implementation)
**Assigned To:** zsh-configuration project
**Status:** Ready for pickup
