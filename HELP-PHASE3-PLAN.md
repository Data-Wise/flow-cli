# Help System Phase 3: Interactive fzf Picker

**Timeline:** Week 3 (after Phase 2 complete)
**Effort:** 6-8 hours
**Dependencies:** Phase 2 complete, fzf installed
**Goal:** Add visual, interactive command browsing with fuzzy search

---

## 🎯 Objectives

Add interactive command picker using `fzf`:
1. **Visual browsing** - See all commands at once
2. **Fuzzy search** - Type to filter instantly
3. **Preview pane** - See details before executing
4. **Quick execution** - Select and run (optional)
5. **Fallback mode** - Works without fzf

---

## 📋 Implementation Checklist

### 1. Check fzf Availability (15 min)

```zsh
# Add dependency check function
_has_fzf() {
    command -v fzf >/dev/null 2>&1
}

# Install instructions if missing
_suggest_fzf() {
    cat << 'EOF'
fzf not found. Install for interactive help:

  brew install fzf         # macOS
  sudo apt install fzf     # Ubuntu/Debian

Or continue using static help modes:
  r help              # Quick mode
  r help full         # Complete reference
  r help examples     # Usage examples
EOF
}
```

### 2. Implement Interactive Mode (3-4 hours)

#### A. Add `?` Shortcut

```zsh
r() {
    case "$1" in
        \?)  # Shortcut for interactive help
            _r_help_interactive
            return
            ;;

        help|h)
            case "${2:-quick}" in
                browse|interactive)
                    _r_help_interactive
                    ;;
                # ... other modes
            esac
            ;;
    esac
}
```

#### B. Create Interactive Help Function

```zsh
_r_help_interactive() {
    # Check for fzf
    if ! _has_fzf; then
        echo "Interactive mode requires fzf"
        echo ""
        _suggest_fzf
        echo ""
        echo "Falling back to static help..."
        _r_help_full
        return
    fi

    local selected
    local GREEN='\033[0;32m'
    local CYAN='\033[0;36m'
    local YELLOW='\033[1;33m'
    local NC='\033[0m'

    # Command database: cmd|category|description|example
    selected=$(cat <<'EOF' | \
        fzf --ansi \
            --delimiter='|' \
            --with-nth=1,3 \
            --preview='_r_preview {1}' \
            --preview-window=right:50%:wrap \
            --header='r - R Package Development (Press Enter to see usage, Ctrl-C to exit)' \
            --bind='enter:execute(echo Selected: r {1})' \
            --height=80%
🔥|most|test|Run all tests
🔥|most|cycle|Full development cycle
🔥|most|load|Load package
📋|core|load|Load package (devtools::load_all)
📋|core|test|Run tests (devtools::test)
📋|core|doc|Generate documentation (devtools::document)
📋|core|check|R CMD check (devtools::check)
📋|core|build|Build package (devtools::build)
📋|core|install|Install package (devtools::install)
🔀|combined|cycle|Full cycle: doc → test → check
🔀|combined|quick|Quick: load → test
📊|quality|cov|Coverage report
📊|quality|spell|Spell check
📚|docs|pkgdown|Build pkgdown site
📚|docs|preview|Preview pkgdown site
🏷️|cran|cran|Check as CRAN
🏷️|cran|fast|Fast check (skip slow parts)
🏷️|cran|win|Windows dev check
🔢|version|patch|Bump patch version (0.0.X)
🔢|version|minor|Bump minor version (0.X.0)
🔢|version|major|Bump major version (X.0.0)
ℹ️|info|info|Package summary
ℹ️|info|tree|Package structure
EOF
)

    # Extract the command from selection
    if [[ -n "$selected" ]]; then
        local cmd=$(echo "$selected" | cut -d'|' -f1)
        echo ""
        echo "${GREEN}Selected:${NC} r $cmd"
        echo ""
        echo "${YELLOW}Run this command? (y/n)${NC}"
        read -q && echo "" && eval "r $cmd"
    fi
}
```

#### C. Create Preview Function

```zsh
_r_preview() {
    local cmd="$1"
    local GREEN='\033[0;32m'
    local CYAN='\033[0;36m'
    local YELLOW='\033[1;33m'
    local MAGENTA='\033[0;35m'
    local NC='\033[0m'

    case "$cmd" in
        🔥|test)
            echo -e "${GREEN}r test${NC} - Run all tests"
            echo ""
            echo -e "${YELLOW}Description:${NC}"
            echo "  Run all tests using devtools::test()"
            echo ""
            echo -e "${YELLOW}Examples:${NC}"
            echo -e "  ${CYAN}r test${NC}                    # All tests"
            echo -e "  ${CYAN}r test filter=\"auth\"${NC}      # Specific tests"
            echo ""
            echo -e "${MAGENTA}Related:${NC} r load, r quick, r cycle"
            echo -e "${MAGENTA}Shortcut:${NC} rtest"
            ;;

        🔥|cycle)
            echo -e "${GREEN}r cycle${NC} - Full development cycle"
            echo ""
            echo -e "${YELLOW}Description:${NC}"
            echo "  Complete workflow: doc → test → check"
            echo "  Perfect before committing changes"
            echo ""
            echo -e "${YELLOW}Examples:${NC}"
            echo -e "  ${CYAN}r cycle${NC}                   # Run full cycle"
            echo ""
            echo -e "${MAGENTA}Related:${NC} r doc, r test, r check"
            echo -e "${MAGENTA}Time:${NC} ~2-5 minutes depending on package size"
            ;;

        🔥|load)
            echo -e "${GREEN}r load${NC} - Load package"
            echo ""
            echo -e "${YELLOW}Description:${NC}"
            echo "  Load package code using devtools::load_all()"
            echo "  Hot-reload changes without reinstalling"
            echo ""
            echo -e "${YELLOW}Examples:${NC}"
            echo -e "  ${CYAN}r load${NC}                    # Load package"
            echo -e "  ${CYAN}r load && r test${NC}          # Load then test"
            echo ""
            echo -e "${MAGENTA}Related:${NC} r test, r quick"
            echo -e "${MAGENTA}Shortcut:${NC} rload"
            ;;

        📋|doc)
            echo -e "${GREEN}r doc${NC} - Generate documentation"
            echo ""
            echo -e "${YELLOW}Description:${NC}"
            echo "  Generate .Rd files from roxygen2 comments"
            echo "  Updates NAMESPACE automatically"
            echo ""
            echo -e "${YELLOW}Examples:${NC}"
            echo -e "  ${CYAN}r doc${NC}                     # Generate docs"
            echo -e "  ${CYAN}r doc && r test${NC}           # Doc then test"
            echo ""
            echo -e "${MAGENTA}Related:${NC} r test, r check, r cycle"
            ;;

        # Add more preview cases for all commands...

        *)
            echo -e "${GREEN}r $cmd${NC}"
            echo ""
            echo "Preview not available for this command"
            echo ""
            echo "Try: r help $cmd"
            ;;
    esac
}
```

### 3. Enhanced Features (2-3 hours)

#### A. Add Category Filtering

```zsh
_r_help_interactive() {
    # ... existing code ...

    selected=$(cat <<'EOF' | \
        fzf --ansi \
            --bind='ctrl-f:reload(cat <<DATA | grep "most"
                🔥|most|test|Run all tests
                🔥|most|cycle|Full cycle
                🔥|most|load|Load package
DATA
)' \
            --bind='ctrl-a:reload(cat <<DATA
                [all commands...]
DATA
)' \
            --header='Ctrl-F: favorites | Ctrl-A: all | Enter: select'
    # ... rest of implementation ...
}
```

#### B. Add Execute Mode

```zsh
_r_help_interactive() {
    local execute_mode=false

    # Check if called with --execute flag
    if [[ "$1" == "--execute" ]]; then
        execute_mode=true
    fi

    # ... fzf setup ...

    if $execute_mode; then
        # Execute directly without confirmation
        local cmd=$(echo "$selected" | cut -d'|' -f3)
        echo "Executing: r $cmd"
        eval "r $cmd"
    else
        # Show selection and ask for confirmation
        # ... existing confirmation code ...
    fi
}
```

#### C. Add History Tracking

```zsh
# Track most-used commands
_r_track_usage() {
    local cmd="$1"
    local history_file="$HOME/.cache/zsh/r-command-history"

    mkdir -p "$(dirname "$history_file")"
    echo "$(date +%s)|$cmd" >> "$history_file"
}

# Get most common commands
_r_get_popular() {
    local history_file="$HOME/.cache/zsh/r-command-history"

    if [[ -f "$history_file" ]]; then
        # Get top 5 most used commands from last 30 days
        local thirty_days_ago=$(( $(date +%s) - 2592000 ))

        awk -F'|' -v cutoff="$thirty_days_ago" \
            '$1 >= cutoff {print $2}' "$history_file" | \
            sort | uniq -c | sort -rn | head -5 | \
            awk '{print $2}'
    fi
}

# Update interactive mode to show popular commands first
_r_help_interactive() {
    local popular=$(_r_get_popular)

    # Build command list with popular commands first
    # ... rest of implementation ...
}
```

### 4. Apply to All 8 Functions (1-2 hours)

**Template approach:**
```zsh
# Create generic preview function
_help_preview_template() {
    local func_name="$1"
    local cmd="$2"

    # Load command database for this function
    # Display formatted preview
}

# Apply to each function:
_r_preview() { _help_preview_template "r" "$1"; }
_cc_preview() { _help_preview_template "cc" "$1"; }
_gm_preview() { _help_preview_template "gm" "$1"; }
# etc.
```

### 5. Testing (1 hour)

**Manual Testing:**
```bash
# Test interactive mode
r ?
cc ?
gm ?

# Test with fzf available
which fzf && r ?

# Test without fzf (fallback)
PATH="/tmp:$PATH" r ?  # Should fall back gracefully

# Test search
r ?  # Type "test" to filter
r ?  # Type "doc" to filter

# Test preview
r ?  # Navigate and check preview pane

# Test execution
r ? --execute  # Should execute without confirmation
```

**Automated Testing:**
```zsh
# Update test suite
test_interactive_mode() {
    # Test fzf detection
    if _has_fzf; then
        # Test interactive mode loads
        # Can't fully test fzf interaction in automated tests
        assert_function_exists "_r_help_interactive"
        assert_function_exists "_r_preview"
    fi

    # Test fallback
    # Temporarily hide fzf
    local old_path="$PATH"
    PATH="/tmp"
    output=$(r ? 2>&1)
    assert_output_contains "requires fzf" "$output"
    PATH="$old_path"
}
```

---

## 🎨 User Experience

### Launch Interactive Mode:
```bash
r ?
# or
r help browse
```

### Interface:
```
┌─ r - R Package Development ────────────────┬─ Preview ─────────────────────┐
│ > 🔥 test                                   │ r test - Run all tests        │
│   🔥 cycle                                  │                               │
│   🔥 load                                   │ Description:                  │
│   📋 doc                                    │   Run all tests using         │
│   📋 check                                  │   devtools::test()            │
│   📋 build                                  │                               │
│   🔀 quick                                  │ Examples:                     │
│   📊 cov                                    │   r test            # All     │
│   📚 pkgdown                                │   r test filter="auth"        │
│                                             │                               │
│   9/25                                      │ Related: r load, r quick      │
├─────────────────────────────────────────────┴───────────────────────────────┤
│ Ctrl-F: favorites | Ctrl-A: all | Enter: select | Ctrl-C: exit             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Workflow:
1. Type `r ?`
2. Start typing to filter (fuzzy search)
3. Use arrow keys to navigate
4. Press Enter to select
5. Confirm to execute (or Ctrl-C to cancel)

---

## 📊 Success Criteria

- [ ] Interactive mode works for all 8 functions
- [ ] Fuzzy search filters commands instantly
- [ ] Preview pane shows detailed information
- [ ] Works with and without fzf (graceful fallback)
- [ ] `?` shortcut works for all functions
- [ ] Category filtering works (favorites, all, etc.)
- [ ] Execution mode optional (--execute flag)
- [ ] Usage tracking implemented
- [ ] All tests pass
- [ ] Documentation updated

---

## 🎯 Usage Examples (After Phase 3)

```bash
# Quick interactive picker
r ?
cc ?
gm ?

# Browse all commands
r help browse
cc help interactive

# Execute directly (skip confirmation)
r ? --execute

# Fallback to static if no fzf
# Automatically uses r help full
```

---

## 🔗 Dependencies

**Required:**
- Phase 2 complete
- ZSH 5.0+

**Optional:**
- fzf 0.20+ (for interactive mode)
  - Install: `brew install fzf`
  - Graceful fallback if missing

**fzf Features Used:**
- `--preview` - Show preview pane
- `--preview-window` - Configure preview
- `--header` - Show instructions
- `--bind` - Custom key bindings
- `--ansi` - Color support
- `--delimiter` - Parse command data

---

## 📝 Implementation Notes

### fzf Configuration:

```zsh
# Optimal fzf settings for command picker
FZF_OPTS=(
    --ansi                          # Color support
    --height=80%                    # Use 80% of screen
    --layout=reverse                # Results on top
    --border=rounded                # Rounded borders
    --preview-window=right:50%:wrap # Preview on right, 50% width
    --bind='ctrl-/:toggle-preview'  # Toggle preview with Ctrl-/
    --bind='ctrl-u:preview-page-up' # Scroll preview up
    --bind='ctrl-d:preview-page-down' # Scroll preview down
    --header-lines=0                # No header in results
    --prompt='❯ '                   # Custom prompt
    --pointer='▶'                   # Custom pointer
    --marker='✓'                    # Custom marker
)
```

### Performance:

- Command database loaded once
- Preview function cached
- No external commands in hot path
- Instant filtering (fzf handles it)

### Accessibility:

- Works without mouse
- Keyboard-driven interface
- Clear visual feedback
- Graceful fallback

---

## 🚀 Rollout Strategy

1. **Beta test with r() only:**
   - Get feedback on UX
   - Refine before rolling out to all

2. **Document fzf installation:**
   - Add to README
   - Include in help system
   - Provide install instructions

3. **Promote gradual adoption:**
   - Announce in Phase 1/2 help
   - Show example in README
   - Create demo video/GIF

4. **Monitor usage:**
   - Track which mode used most
   - Identify popular commands
   - Refine based on data

---

## 🔮 Future Enhancements (Beyond Phase 3)

**Possible additions:**
- Multi-select mode (execute multiple commands)
- Command chaining (r test → r doc → r check)
- Custom command lists/favorites
- Share command history across functions
- Integration with shell history
- Bookmarks for frequent workflows
- Command recommendations based on context

---

## 📅 Timeline

**Day 1 (3-4 hours):**
- Implement fzf integration for r()
- Create preview function
- Test thoroughly

**Day 2 (3-4 hours):**
- Apply to remaining 7 functions
- Add enhanced features (filtering, history)
- Write tests
- Update documentation

**Total:** 6-8 hours over 2-3 days

---

## ⚠️ Risk Mitigation

**Risk:** fzf not installed
**Mitigation:** Graceful fallback to `help full`

**Risk:** fzf version too old
**Mitigation:** Feature detection, fallback for missing features

**Risk:** Preview function slow
**Mitigation:** Cache previews, optimize rendering

**Risk:** Terminal too small
**Mitigation:** Adaptive height, minimum size check

---

**Status:** 📋 Planned (Ready to implement after Phase 2)
**Next:** Wait for Phase 1 completion, deploy Phase 2, then Phase 3
