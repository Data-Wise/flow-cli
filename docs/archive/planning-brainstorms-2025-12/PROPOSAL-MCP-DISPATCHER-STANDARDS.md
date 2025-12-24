# MCP Dispatcher Standards Alignment

**Generated:** 2025-12-19
**Context:** flow-cli standards compliance
**Current:** Individual functions (mcp-list, mcp-cd, etc.)
**Proposed:** Dispatcher pattern (mcp + keywords)

---

## Current Implementation Analysis

### What We Have Now (mcp-utils.zsh)

**Functions:**

- `mcp-list` - List all MCP servers with status
- `mcp-cd` - Navigate to MCP servers directory
- `mcp-edit` - Edit MCP server in $EDITOR
- `mcp-test` - Test MCP server runs correctly
- `mcp-status` - Check configuration status
- `mcp-pick` - Interactive server picker (fzf)
- `mcp-readme` - View MCP server README
- `mcp-help` - Show help

**Aliases:**

- `ml` = mcp-list
- `mc` = mcp-cd
- `mcpl` = mcp-list
- `mcpc` = mcp-cd
- `mcpe` = mcp-edit
- `mcpt` = mcp-test
- `mcps` = mcp-status
- `mcpr` = mcp-readme
- `mcpp` = mcp-pick
- `mcph` = mcp-help

**Pattern:** `mcp-<action>` (verb-noun with dash)

---

## Standards Violations & Issues

### ❌ V1: Not Following Dispatcher Pattern

**From CONVENTIONS.md:**

> Pattern: command + keyword + options

**Current:**

```bash
mcp-list
mcp-cd docling
mcp-test statistical-research
```

**Standard Pattern (like g, r, v):**

```bash
mcp list
mcp cd docling
mcp test statistical-research
```

### ❌ V2: Inconsistent with Existing Dispatchers

**Other dispatchers in flow-cli:**

- `g status` (not `g-status`)
- `r test` (not `r-test`)
- `v build` (not `v-build`)
- `qu render` (not `qu-render`)

**MCP should be:**

- `mcp list` (not `mcp-list`)

### ❌ V3: Alias Naming Confusion

**Current aliases:**

- `ml` = mcp-list (good)
- `mc` = mcp-cd (conflicts! `mc` usually = Midnight Commander)
- `mcpl`, `mcpc`, `mcpe` (too verbose, non-standard)

**Standard approach:**

- Short aliases for common actions only
- No "mc" prefix (conflicts with Midnight Commander)

### ❌ V4: No Dispatcher Help Structure

**Missing:**

- `_mcp_help()` function
- Categories in help (like other dispatchers)
- "MOST COMMON" section
- "QUICK EXAMPLES" section

---

## Proposed Solutions

### Option A: Full Dispatcher (Recommended) ⭐

**Convert to standard dispatcher pattern like g, r, v**

**Implementation:**

```bash
mcp() {
    # No arguments → default action (list)
    if [[ $# -eq 0 ]]; then
        _mcp_list
        return
    fi

    case "$1" in
        # ─────────────────────────────────────────────────────────────
        # CORE ACTIONS
        # ─────────────────────────────────────────────────────────────
        list|ls|l)
            shift
            _mcp_list "$@"
            ;;

        cd|goto|g)
            shift
            _mcp_cd "$@"
            ;;

        test|t)
            shift
            _mcp_test "$@"
            ;;

        edit|e)
            shift
            _mcp_edit "$@"
            ;;

        # ─────────────────────────────────────────────────────────────
        # INFO
        # ─────────────────────────────────────────────────────────────
        status|s)
            shift
            _mcp_status "$@"
            ;;

        readme|r|doc)
            shift
            _mcp_readme "$@"
            ;;

        pick|p)
            shift
            _mcp_pick "$@"
            ;;

        # ─────────────────────────────────────────────────────────────
        # HELP
        # ─────────────────────────────────────────────────────────────
        help|h|--help|-h)
            _mcp_help
            ;;

        *)
            echo "Unknown action: $1"
            echo "Run 'mcp help' for available commands"
            return 1
            ;;
    esac
}
```

**Usage:**

```bash
mcp              # List all servers (default)
mcp list         # or: mcp ls, mcp l
mcp cd docling   # or: mcp goto docling, mcp g docling
mcp test docling # or: mcp t docling
mcp edit shell   # or: mcp e shell
mcp status       # or: mcp s
mcp pick         # or: mcp p (interactive picker)
mcp help         # or: mcp h
```

**Aliases (simplified):**

```bash
# Short forms for power users
alias ml='mcp list'     # Keep (common)
alias mcd='mcp cd'      # Better than 'mc' (no conflict)
alias mcp='mcp pick'    # Interactive picker
```

**Pros:**

- ✅ Follows flow-cli standards
- ✅ Consistent with g, r, v dispatchers
- ✅ Single mental model (cmd + keyword)
- ✅ Extensible (easy to add new actions)
- ✅ Help structure matches other dispatchers

**Cons:**

- ⚠️ Breaking change (existing functions)
- ⚠️ Need to update tests
- ⚠️ Documentation update required

---

### Option B: Hybrid (Keep Both)

**Keep current functions + add dispatcher**

**Implementation:**

```bash
# Dispatcher calls existing functions
mcp() {
    if [[ $# -eq 0 ]]; then
        mcp-list
        return
    fi

    case "$1" in
        list|ls|l) shift; mcp-list "$@" ;;
        cd|g) shift; mcp-cd "$@" ;;
        test|t) shift; mcp-test "$@" ;;
        edit|e) shift; mcp-edit "$@" ;;
        status|s) shift; mcp-status "$@" ;;
        readme|r) shift; mcp-readme "$@" ;;
        pick|p) shift; mcp-pick "$@" ;;
        help|h) _mcp_help ;;
        *) echo "Unknown: $1. Try: mcp help" ;;
    esac
}
```

**Usage:**

```bash
# Both work:
mcp list         # Dispatcher
mcp-list         # Direct function

mcp cd docling   # Dispatcher
mcp-cd docling   # Direct function
```

**Pros:**

- ✅ No breaking changes
- ✅ Gradual migration path
- ✅ Power users can use either

**Cons:**

- ❌ Violates R1: No Duplicates rule
- ❌ Two ways to do everything (confusing)
- ❌ More maintenance burden

---

### Option C: Keep Current (Not Recommended)

**Keep mcp-<action> pattern as-is**

**Pros:**

- ✅ No changes needed
- ✅ Works today

**Cons:**

- ❌ Violates standards
- ❌ Inconsistent with g, r, v
- ❌ Harder to remember (dash vs space)
- ❌ Aliases are clunky (mcpl, mcpc, mcpe)

---

## Detailed Comparison

| Feature                       | Current (mcp-\*) | Option A (Dispatcher) | Option B (Hybrid) |
| ----------------------------- | ---------------- | --------------------- | ----------------- |
| **Standards Compliant**       | ❌ No            | ✅ Yes                | ⚠️ Partial        |
| **Consistent with g, r, v**   | ❌ No            | ✅ Yes                | ✅ Yes            |
| **ADHD-Friendly**             | ⚠️ OK            | ✅ Better             | ⚠️ Confusing      |
| **Breaking Changes**          | ✅ None          | ❌ Yes                | ✅ None           |
| **Follows R1: No Duplicates** | ✅ Yes           | ✅ Yes                | ❌ No             |
| **Help Structure**            | ❌ Basic         | ✅ Full               | ⚠️ Partial        |
| **Extensibility**             | ⚠️ OK            | ✅ Excellent          | ⚠️ OK             |
| **Migration Effort**          | N/A              | 🔧 Medium             | ⚡ Low            |

---

## Help Structure (Option A)

### Proposed \_mcp_help()

```bash
_mcp_help() {
    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ mcp - MCP Server Management                 │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}mcp${_C_NC}              List all MCP servers (default)
  ${_C_CYAN}mcp test NAME${_C_NC}    Test server runs correctly
  ${_C_CYAN}mcp cd NAME${_C_NC}      Navigate to server directory

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} mcp                      ${_C_DIM}# List all servers${_C_NC}
  ${_C_DIM}\$${_C_NC} mcp test docling         ${_C_DIM}# Test docling server${_C_NC}
  ${_C_DIM}\$${_C_NC} mcp cd statistical-research  ${_C_DIM}# Go to server dir${_C_NC}
  ${_C_DIM}\$${_C_NC} mcp pick                 ${_C_DIM}# Interactive picker${_C_NC}

${_C_BLUE}📋 ALL ACTIONS${_C_NC}:

  ${_C_BOLD}Core:${_C_NC}
    ${_C_CYAN}list${_C_NC} (ls, l)     List all MCP servers with status
    ${_C_CYAN}cd${_C_NC} (goto, g)     Navigate to MCP servers directory
    ${_C_CYAN}test${_C_NC} (t)         Test MCP server runs correctly
    ${_C_CYAN}edit${_C_NC} (e)         Edit MCP server in \$EDITOR

  ${_C_BOLD}Info:${_C_NC}
    ${_C_CYAN}status${_C_NC} (s)       Check configuration status
    ${_C_CYAN}readme${_C_NC} (r, doc)  View MCP server README
    ${_C_CYAN}pick${_C_NC} (p)         Interactive server picker (fzf)

  ${_C_BOLD}Help:${_C_NC}
    ${_C_CYAN}help${_C_NC} (h)         Show this help

${_C_MAGENTA}💡 TIP${_C_NC}: Shortcuts available:
  ${_C_DIM}ml    → mcp list${_C_NC}
  ${_C_DIM}mcd   → mcp cd${_C_NC}
  ${_C_DIM}mcpp  → mcp pick${_C_NC}

${_C_BLUE}📍 Locations${_C_NC}:
  Servers:  ${_C_DIM}~/projects/dev-tools/mcp-servers/${_C_NC}
  Symlinks: ${_C_DIM}~/mcp-servers/${_C_NC}
  Desktop:  ${_C_DIM}~/.claude/settings.json${_C_NC}
  Browser:  ${_C_DIM}~/projects/dev-tools/claude-mcp/MCP_SERVER_CONFIG.json${_C_NC}
"
}
```

---

## Migration Path (Option A)

### Step 1: Create New Dispatcher ✅

**File:** `mcp-dispatcher.zsh` (new file)

- Implement `mcp()` function
- Keep all existing `_mcp_*()` internal functions
- Add `_mcp_help()` with full structure

### Step 2: Deprecate Old Functions 📝

**In mcp-utils.zsh:**

```bash
# Deprecated: Use 'mcp list' instead
mcp-list() {
    echo "⚠️  Deprecated: Use 'mcp list' instead"
    _mcp_list "$@"
}

# Deprecated: Use 'mcp cd' instead
mcp-cd() {
    echo "⚠️  Deprecated: Use 'mcp cd' instead"
    _mcp_cd "$@"
}
```

### Step 3: Update Aliases 📝

**In .zshrc:**

```bash
# MCP shortcuts
alias ml='mcp list'      # List servers
alias mcd='mcp cd'       # Navigate to server
alias mcpp='mcp pick'    # Interactive picker
```

### Step 4: Update Documentation 📝

- Update `ZSH-MCP-FUNCTIONS.md`
- Update `mcp-servers/README.md`
- Update test suite

### Step 5: Remove Old Functions (v2.0) 🗑️

After 1-2 weeks, remove deprecated functions entirely.

---

## Quick Wins (< 30 min each)

1. ⚡ **Create \_mcp_help()** - Add help structure
2. ⚡ **Fix mc alias conflict** - Rename to `mcd`
3. ⚡ **Update README** - Document new pattern

## Medium Effort (1-2 hours)

- [ ] Implement full dispatcher pattern (Option A)
- [ ] Update test suite for new pattern
- [ ] Add deprecation warnings

## Long-term (Future sessions)

- [ ] Remove deprecated functions (after migration period)
- [ ] Add ZSH completions for dispatcher keywords
- [ ] Create REFCARD for mcp commands

---

## Recommended Next Step

→ **Start with Option A: Full Dispatcher**

**Why:**

1. Aligns with flow-cli standards
2. Consistent mental model (like g, r, v)
3. Better ADHD experience (one pattern to remember)
4. More extensible for future features
5. Proper help structure

**First Action:**

```bash
# Create the dispatcher
1. Rename mcp-utils.zsh → mcp-dispatcher.zsh
2. Convert mcp-* functions → mcp + keywords
3. Add _mcp_help() with full structure
4. Update .zshrc to source new file
5. Test with: mcp help
```

---

**Remember:** The goal is consistency! Users should learn ONE pattern (cmd + keyword) that works everywhere (g, r, v, mcp).
