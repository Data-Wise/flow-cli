# Help System Phase 2: Multi-Mode Help

**Timeline:** Week 2 (after Phase 1 complete)
**Effort:** 4-6 hours
**Dependencies:** Phase 1 complete
**Goal:** Add multiple help modes for flexible access patterns

---

## 🎯 Objectives

Add help system modes to support different use cases:
1. **Quick mode** (default) - Essential info only
2. **Full mode** - Complete reference (enhanced Phase 1 output)
3. **Examples mode** - Usage examples with explanations
4. **Search mode** - Find commands by keyword
5. **List mode** - Machine-readable output for scripting

---

## 📋 Implementation Checklist

### 1. Refactor Help Architecture (30-45 min)

**Current:**
```zsh
r() {
    case "$1" in
        help|h)
            cat << 'EOF'
            [static help text]
EOF
            ;;
    esac
}
```

**New:**
```zsh
r() {
    case "$1" in
        help|h)
            local mode="${2:-quick}"  # Default to quick
            case "$mode" in
                quick|"")    _r_help_quick ;;
                full)        _r_help_full ;;
                examples)    _r_help_examples "${@:3}" ;;
                search)      _r_help_search "${@:3}" ;;
                --list)      _r_help_list ;;
                *)           _r_help_search "$mode" ;;  # Treat unknown as search
            esac
            return
            ;;
    esac
}
```

### 2. Implement Helper Functions (2-3 hours)

#### A. Quick Mode (Default)
**Purpose:** Show essentials only (what Phase 1 creates)

```zsh
_r_help_quick() {
    # This is the Phase 1 enhanced help
    # Already colorized, with examples, most common
    cat << 'EOF'
╭─────────────────────────────────────╮
│ r - R Package Development           │
╰─────────────────────────────────────╯

🔥 MOST COMMON:
  r test             Run all tests
  r cycle            Full cycle
  r load             Load package

💡 EXAMPLES:
  r test
  r cycle

📚 MORE HELP:
  r help full        Complete reference
  r help examples    More examples
  r help test        Search for "test"
EOF
}
```

#### B. Full Mode
**Purpose:** Complete reference with all commands

```zsh
_r_help_full() {
    local GREEN='\033[0;32m'
    local CYAN='\033[0;36m'
    local YELLOW='\033[1;33m'
    local NC='\033[0m'

    cat << EOF
╭──────────────────────────────────────────────────────────────╮
│ ${GREEN}r - R Package Development${NC} (Complete Reference)          │
╰──────────────────────────────────────────────────────────────╯

${GREEN}🔥 MOST COMMON (80% of daily use):${NC}
  ${CYAN}r test${NC}             Run all tests
  ${CYAN}r cycle${NC}            Full cycle: doc → test → check
  ${CYAN}r load${NC}             Load package

${YELLOW}💡 QUICK EXAMPLES:${NC}
  r test                    # Run all tests
  r test filter="auth"      # Test auth module
  r cycle                   # Complete dev cycle
  r load && r test          # Quick iteration

${GREEN}📋 CORE WORKFLOW:${NC}
  ${CYAN}r load${NC}             Load package (devtools::load_all)
  ${CYAN}r test${NC}             Run tests (devtools::test)
  ${CYAN}r doc${NC}              Generate docs (devtools::document)
  ${CYAN}r check${NC}            R CMD check (devtools::check)
  ${CYAN}r build${NC}            Build package (devtools::build)
  ${CYAN}r install${NC}          Install package (devtools::install)

${GREEN}🔀 COMBINED WORKFLOWS:${NC}
  ${CYAN}r cycle${NC}            doc → test → check (full development cycle)
  ${CYAN}r quick${NC}            load → test (fast iteration)

${GREEN}📊 QUALITY CHECKS:${NC}
  ${CYAN}r cov${NC}              Coverage report (covr::package_coverage)
  ${CYAN}r spell${NC}            Spell check (spelling::spell_check_package)

${GREEN}📚 DOCUMENTATION:${NC}
  ${CYAN}r pkgdown${NC}          Build pkgdown site
  ${CYAN}r preview${NC}          Preview pkgdown site

${GREEN}🏷️ CRAN CHECKS:${NC}
  ${CYAN}r cran${NC}             Check as CRAN (--as-cran)
  ${CYAN}r fast${NC}             Fast check (skip examples/tests/vignettes)
  ${CYAN}r win${NC}              Windows dev check

${GREEN}🔢 VERSION MANAGEMENT:${NC}
  ${CYAN}r patch${NC}            Bump patch version (0.0.X)
  ${CYAN}r minor${NC}            Bump minor version (0.X.0)
  ${CYAN}r major${NC}            Bump major version (X.0.0)

${GREEN}ℹ️ PACKAGE INFO:${NC}
  ${CYAN}r info${NC}             Package summary (rpkginfo)
  ${CYAN}r tree${NC}             Package structure (rpkgtree)

${GREEN}🔗 SHORTCUTS STILL WORK:${NC}
  rload, rtest, rdoc, rcheck, rbuild, rinstall

${GREEN}📖 OTHER HELP MODES:${NC}
  r help examples           Show detailed examples
  r help test              Search for "test" commands
  r help --list            Machine-readable list
  r ?                      Interactive picker (Phase 3)
EOF
}
```

#### C. Examples Mode
**Purpose:** Show detailed usage examples

```zsh
_r_help_examples() {
    local topic="${1:-all}"
    local GREEN='\033[0;32m'
    local CYAN='\033[0;36m'
    local YELLOW='\033[1;33m'
    local NC='\033[0m'

    case "$topic" in
        all|"")
            cat << EOF
╭──────────────────────────────────────────────────────────────╮
│ ${GREEN}r - Usage Examples${NC}                                         │
╰──────────────────────────────────────────────────────────────╯

${YELLOW}💡 BASIC WORKFLOWS:${NC}

  ${GREEN}# Run all tests${NC}
  r test

  ${GREEN}# Run tests matching pattern${NC}
  r test filter="authentication"

  ${GREEN}# Load package and run tests (quick iteration)${NC}
  r load && r test

  ${GREEN}# Full development cycle${NC}
  r cycle                # doc → test → check

${YELLOW}💡 DOCUMENTATION:${NC}

  ${GREEN}# Generate documentation${NC}
  r doc

  ${GREEN}# Build and preview pkgdown site${NC}
  r pkgdown
  r preview              # Opens in browser

${YELLOW}💡 QUALITY CHECKS:${NC}

  ${GREEN}# Check package${NC}
  r check                # Standard check
  r fast                 # Quick check (skip slow parts)
  r cran                 # CRAN-ready check

  ${GREEN}# Test coverage${NC}
  r cov                  # Generate coverage report

${YELLOW}💡 VERSION MANAGEMENT:${NC}

  ${GREEN}# Bump version${NC}
  r patch                # 0.1.0 → 0.1.1
  r minor                # 0.1.0 → 0.2.0
  r major                # 0.1.0 → 1.0.0

${YELLOW}💡 COMBINED WORKFLOWS:${NC}

  ${GREEN}# Typical development session${NC}
  r load                 # Load package
  r test                 # Run tests
  r doc                  # Update docs
  r check                # Final check

  ${GREEN}# Or use the shortcut${NC}
  r cycle                # Does all of above

${GREEN}📚 MORE:${NC}
  r help examples test   # Examples for test command
  r help examples doc    # Examples for documentation
  r help full            # Complete reference
EOF
            ;;

        test|testing)
            cat << EOF
${GREEN}💡 TESTING EXAMPLES:${NC}

  ${GREEN}# Run all tests${NC}
  r test

  ${GREEN}# Run specific test file${NC}
  r test filter="test-authentication"

  ${GREEN}# Run tests matching pattern${NC}
  r test filter="user.*login"

  ${GREEN}# Quick load + test${NC}
  r load && r test
  r quick                # Shortcut for above

  ${GREEN}# Test with coverage${NC}
  r test && r cov

${GREEN}See also:${NC} r help full, r help examples doc
EOF
            ;;

        doc|documentation)
            cat << EOF
${GREEN}💡 DOCUMENTATION EXAMPLES:${NC}

  ${GREEN}# Generate roxygen2 docs${NC}
  r doc

  ${GREEN}# Build pkgdown site${NC}
  r pkgdown

  ${GREEN}# Preview site locally${NC}
  r preview

  ${GREEN}# Full cycle with docs${NC}
  r doc && r test && r check

${GREEN}See also:${NC} r help full, r help examples test
EOF
            ;;

        *)
            echo "No specific examples for '$topic'"
            echo "Try: r help examples (for all examples)"
            echo "Available topics: test, doc"
            ;;
    esac
}
```

#### D. Search Mode
**Purpose:** Find commands by keyword

```zsh
_r_help_search() {
    local query="$1"

    if [[ -z "$query" ]]; then
        echo "Usage: r help <keyword>"
        echo "Example: r help test"
        return 1
    fi

    local GREEN='\033[0;32m'
    local CYAN='\033[0;36m'
    local YELLOW='\033[1;33m'
    local NC='\033[0m'

    # Search database (could be generated or hardcoded)
    local results=()
    local found=0

    # Check each command
    case "$query" in
        *test*)
            results+=("r test|Run all tests|r test")
            results+=("r quick|load → test|r quick")
            results+=("r cycle|doc → test → check|r cycle")
            found=1
            ;;
        *doc*)
            results+=("r doc|Generate docs|r doc")
            results+=("r pkgdown|Build site|r pkgdown")
            results+=("r cycle|doc → test → check|r cycle")
            found=1
            ;;
        *check*)
            results+=("r check|R CMD check|r check")
            results+=("r fast|Fast check|r fast")
            results+=("r cran|CRAN check|r cran")
            results+=("r cycle|doc → test → check|r cycle")
            found=1
            ;;
        *load*)
            results+=("r load|Load package|r load")
            results+=("r quick|load → test|r quick")
            found=1
            ;;
        *version*|*bump*)
            results+=("r patch|Bump patch|r patch")
            results+=("r minor|Bump minor|r minor")
            results+=("r major|Bump major|r major")
            found=1
            ;;
    esac

    if [[ $found -eq 0 ]]; then
        echo "${YELLOW}No commands found matching: ${NC}'$query'"
        echo ""
        echo "Try: r help full (see all commands)"
        return 1
    fi

    echo ""
    echo "${GREEN}Found ${#results[@]} command(s) matching${NC} '$query':"
    echo ""

    for result in "${results[@]}"; do
        local cmd=$(echo "$result" | cut -d'|' -f1)
        local desc=$(echo "$result" | cut -d'|' -f2)
        local example=$(echo "$result" | cut -d'|' -f3)

        echo "  ${CYAN}${cmd}${NC}"
        echo "    $desc"
        echo "    ${YELLOW}Example:${NC} $example"
        echo ""
    done

    echo "${GREEN}More help:${NC}"
    echo "  r help examples $query"
    echo "  r help full"
}
```

#### E. List Mode
**Purpose:** Machine-readable output for scripts

```zsh
_r_help_list() {
    # Output: command|short_alias|description
    cat << 'EOF'
load|l|Load package (devtools::load_all)
test|t|Run tests (devtools::test)
doc|d|Generate docs (devtools::document)
check|c|R CMD check (devtools::check)
build|b|Build package (devtools::build)
install|i|Install package (devtools::install)
cycle||Full cycle: doc → test → check
quick|q|load → test
cov||Coverage report
spell||Spell check
pkgdown|pd|Build pkgdown site
preview|pv|Preview pkgdown site
cran||Check as CRAN
fast||Fast check
win||Windows dev check
patch||Bump patch version
minor||Bump minor version
major||Bump major version
info||Package info summary
tree||Show package structure
EOF
}
```

### 3. Apply to All 8 Functions (1-2 hours)

**Create template helpers:**
- `_help_quick_template()`
- `_help_full_template()`
- `_help_examples_template()`
- `_help_search_template()`

**Apply to:**
1. r() - Most complex
2. cc() - Second most complex
3. qu() - Medium
4. gm() - Medium
5. focus() - Simple
6. note() - Simple
7. obs() - Simple
8. workflow() - Simple

### 4. Testing (30-45 min)

**Manual Testing:**
```bash
# Test all modes for each function
r help              # Quick
r help full         # Full
r help examples     # Examples all
r help examples test # Examples specific
r help test         # Search
r help --list       # List

# Repeat for: cc, qu, gm, focus, note, obs, workflow
```

**Automated Testing:**
Update `test-smart-functions.zsh`:
```zsh
# Test Phase 2 modes
test_r_help_modes() {
    # Quick mode
    output=$(r help 2>&1)
    assert_output_contains "Most Common" "$output"

    # Full mode
    output=$(r help full 2>&1)
    assert_output_contains "Complete Reference" "$output"

    # Examples mode
    output=$(r help examples 2>&1)
    assert_output_contains "Usage Examples" "$output"

    # Search mode
    output=$(r help test 2>&1)
    assert_output_contains "Found.*matching" "$output"

    # List mode
    output=$(r help --list 2>&1)
    assert_output_contains "|" "$output"  # Pipe-separated
}
```

---

## 📊 Success Criteria

- [ ] All 8 functions support 5 help modes
- [ ] Quick mode is default (backward compatible)
- [ ] Full mode shows complete reference
- [ ] Examples mode shows usage patterns
- [ ] Search mode finds commands by keyword
- [ ] List mode outputs machine-readable format
- [ ] All existing tests pass
- [ ] New tests added for modes
- [ ] Documentation updated

---

## 🎯 Usage Examples (After Phase 2)

```bash
# Quick reference (default)
r help
cc help

# Complete reference
r help full
cc help full

# See examples
r help examples
r help examples test
cc help examples project

# Search for commands
r help test
r help doc
cc help session

# Machine-readable (for scripts)
r help --list | grep test
cc help --list | cut -d'|' -f1
```

---

## 📝 Implementation Notes

**Code Organization:**
```
~/.config/zsh/functions/
├── smart-dispatchers.zsh         # Main file
└── help-helpers.zsh (optional)   # Shared help utilities
```

**Color Management:**
```zsh
# Respect NO_COLOR env var
if [[ -n "$NO_COLOR" ]]; then
    GREEN=""
    CYAN=""
    YELLOW=""
    NC=""
else
    GREEN='\033[0;32m'
    CYAN='\033[0;36m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
fi
```

**Performance:**
- Keep functions lightweight
- Avoid external commands when possible
- Cache color detection

---

## 🔗 Dependencies

**Required:**
- Phase 1 complete
- ZSH 5.0+
- Terminal with ANSI color support (optional)

**Optional:**
- None (all built-in ZSH features)

---

## 📅 Timeline

**Day 1 (2-3 hours):**
- Refactor help architecture
- Implement helper functions for r()
- Test r() thoroughly

**Day 2 (2-3 hours):**
- Apply to remaining 7 functions
- Write automated tests
- Update documentation

**Total:** 4-6 hours over 2 days

---

## 🚀 Rollout Strategy

1. **Deploy incrementally:**
   - Start with r() only
   - Test with real usage
   - Get feedback
   - Apply to others

2. **Announce in help:**
   - Phase 1 already mentions "coming soon"
   - Update to show it's available
   - Promote in README

3. **Gather feedback:**
   - Monitor which modes used most
   - Adjust based on usage
   - Iterate on search quality

---

**Status:** 📋 Planned (Ready to implement after Phase 1)
**Next:** Phase 3 - Interactive fzf picker
