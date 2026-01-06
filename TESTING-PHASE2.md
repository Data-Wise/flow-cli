# Manual Testing Guide - Phase 2: Interactive Help System

**Version:** v4.9.0 Phase 2
**Date:** 2026-01-05
**Branch:** dev
**Automated Tests:** `tests/test-phase2-features.zsh` (47 tests)

---

## Overview

Phase 2 adds three major features:

1. **Interactive Help Browser** - fzf-based command exploration
2. **Context-Aware Help** - Smart project type detection
3. **Alias Reference Command** - Comprehensive alias documentation

This guide provides step-by-step manual testing procedures to verify all features work correctly in real-world usage.

---

## Prerequisites

### Required Tools

```bash
# Check for required tools
command -v fzf &>/dev/null && echo "✓ fzf installed" || echo "✗ fzf missing"
command -v git &>/dev/null && echo "✓ git installed" || echo "✗ git missing"

# Load flow-cli plugin (if not already loaded)
source flow.plugin.zsh
```

### Test Environment Setup

```bash
# Create test directories for context detection
mkdir -p /tmp/flow-test/{r-package,node-project,git-repo,empty}

# R package
echo "Package: testpkg" > /tmp/flow-test/r-package/DESCRIPTION

# Node project
echo '{"name":"testpkg"}' > /tmp/flow-test/node-project/package.json

# Git repo
(cd /tmp/flow-test/git-repo && git init -q)
```

---

## Feature 1: Interactive Help Browser

### Test 1.1: Basic Launch

```bash
# Launch interactive help
flow help --interactive

# OR short form
flow help -i
```

**Expected Result:**

- fzf window opens with ~48 commands listed
- Prompt shows: `📚 Flow Commands >`
- Commands show format: `command - description`
- Window has rounded border

**Visual Verification:**

- [ ] fzf window displays
- [ ] All commands visible
- [ ] Descriptions readable
- [ ] Prompt formatted correctly

### Test 1.2: Search Functionality

```bash
# Launch and type "work"
flow help -i
# (type "work" in fzf)
```

**Expected Result:**

- Filters to commands containing "work": work, workflow
- Preview pane shows help text for highlighted command
- Arrow keys navigate filtered results

**Visual Verification:**

- [ ] Search filters commands
- [ ] Preview pane updates on navigation
- [ ] Help text formatted correctly

### Test 1.3: Preview Pane

```bash
# Launch and navigate through commands
flow help -i
# (use arrow keys to browse)
```

**Expected Result:**

- Preview pane shows full help for each command
- Help includes usage, options, examples
- Colors preserved in preview
- Preview updates instantly

**Visual Verification:**

- [ ] Preview shows complete help
- [ ] Colors display correctly
- [ ] Updates smoothly on navigation
- [ ] No rendering glitches

### Test 1.4: Graceful Fallback (No fzf)

```bash
# Temporarily hide fzf
export PATH_BACKUP="$PATH"
export PATH="/usr/bin:/bin"

flow help -i

# Restore
export PATH="$PATH_BACKUP"
```

**Expected Result:**

- Error message: "fzf is required for interactive help"
- Suggests: "Install fzf: brew install fzf"
- Suggests fallback: "Or use non-interactive help: flow help"
- Exit code: 1

**Visual Verification:**

- [ ] Clear error message
- [ ] Installation instructions shown
- [ ] Fallback suggestion provided
- [ ] No crash or stack trace

---

## Feature 2: Context-Aware Help

### Test 2.1: R Package Context

```bash
cd /tmp/flow-test/r-package
flow help
```

**Expected Result:**

- Context banner: `📦 R Package Context - Try: r help, flow test, flow check`
- Regular help content follows
- Banner uses box-drawing characters

**Visual Verification:**

- [ ] Context banner displays
- [ ] Correct emoji (📦)
- [ ] Suggested commands relevant to R
- [ ] Banner formatted correctly

### Test 2.2: Node.js Project Context

```bash
cd /tmp/flow-test/node-project
flow help
```

**Expected Result:**

- Context banner: `📦 Node.js Project - Try: flow test, flow build, npm run`
- Regular help content follows

**Visual Verification:**

- [ ] Context banner displays
- [ ] Suggests Node-specific commands
- [ ] Banner formatted correctly

### Test 2.3: Git Repository Context

```bash
cd /tmp/flow-test/git-repo
flow help
```

**Expected Result:**

- Context banner: `📂 Git Repository - Try: g help, flow sync, wt help`
- Regular help content follows

**Visual Verification:**

- [ ] Context banner displays
- [ ] Suggests git-related commands
- [ ] Banner formatted correctly

### Test 2.4: General Context (No Project Markers)

```bash
cd /tmp/flow-test/empty
flow help
```

**Expected Result:**

- Context banner: `🚀 Getting Started - Try: flow help --interactive, pick, dash`
- Regular help content follows

**Visual Verification:**

- [ ] Context banner displays
- [ ] Suggests discovery commands
- [ ] Banner formatted correctly

### Test 2.5: Context Priority (Multiple Markers)

```bash
# Create directory with both R package AND Node markers
mkdir -p /tmp/flow-test/multi
echo "Package: test" > /tmp/flow-test/multi/DESCRIPTION
echo '{"name":"test"}' > /tmp/flow-test/multi/package.json

cd /tmp/flow-test/multi
flow help
```

**Expected Result:**

- Context banner shows **R Package** (higher priority than Node.js)
- Node.js marker ignored due to priority ordering

**Visual Verification:**

- [ ] R Package context wins
- [ ] Priority order correct: R > Quarto > Node > Python > Git > General

### Test 2.6: Context Detection Speed

```bash
cd /tmp/flow-test/r-package
time flow help > /dev/null
```

**Expected Result:**

- Total time < 100ms (ADHD-friendly target)
- Most time should be in help rendering, not detection

**Performance Verification:**

- [ ] Context detection near-instant
- [ ] No noticeable delay
- [ ] Sub-100ms total

---

## Feature 3: Alias Reference Command

### Test 3.1: Summary View (No Arguments)

```bash
flow alias
```

**Expected Result:**

- Header: "Total: 28 custom aliases + 8 dispatchers + 226+ git aliases"
- Categories listed:
  - 📦 R Package Development (23 aliases)
  - 🤖 Claude Code (2 aliases)
  - ⏱️ Focus Timers (2 aliases)
  - 🔧 Tool Replacements (1 alias)
  - 🌿 Git Plugin Aliases (226+)
  - 🎯 Smart Dispatchers (8 functions)
- Each category shows brief preview + "flow alias <cat> for details"

**Visual Verification:**

- [ ] All categories present
- [ ] Counts accurate
- [ ] Emojis display
- [ ] Preview text helpful
- [ ] Call-to-action clear

### Test 3.2: R Package Category

```bash
flow alias r
```

**Expected Result:**

- Header: "📦 R Package Development Aliases"
- Sections: Core Workflow, Quality & Coverage, Documentation, etc.
- Each alias shows: `alias → full command # description`
- All 23 R aliases listed
- Organized into logical groups

**Visual Verification:**

- [ ] All 23 aliases present
- [ ] Table formatting clean
- [ ] Sections clearly separated
- [ ] Descriptions helpful
- [ ] Commands accurate

### Test 3.3: Claude Code Category

```bash
flow alias cc
```

**Expected Result:**

- Header: "🤖 Claude Code Aliases"
- Lists:
  - `ccp → claude -p # Print mode`
  - `ccr → claude -r # Resume session`
- Tip: "Use cc dispatcher for full Claude workflow"
- See also: "cc help for all Claude commands"

**Visual Verification:**

- [ ] Both aliases shown
- [ ] Descriptions clear
- [ ] Helpful tips included
- [ ] Related commands referenced

### Test 3.4: Dispatchers Category

```bash
flow alias dispatchers
```

**Expected Result:**

- Header: "🎯 Smart Dispatchers"
- All 8 dispatchers listed:
  - g, cc, wt, mcp, r, qu, obs, tm
- Each shows brief description
- Footer: "Get help: <dispatcher> help"

**Visual Verification:**

- [ ] All 8 dispatchers present
- [ ] Descriptions accurate
- [ ] Help instructions clear
- [ ] Formatting consistent

### Test 3.5: Git Aliases Category

```bash
flow alias git
```

**Expected Result:**

- Header: "🌿 Git Plugin Aliases (Oh My Zsh)"
- Note about 226+ aliases from git plugin
- Instructions to run: `alias | grep "^g"`
- Links to Oh My Zsh git plugin docs

**Visual Verification:**

- [ ] Clear explanation
- [ ] Command to list all provided
- [ ] External docs referenced
- [ ] Acknowledges source

### Test 3.6: Invalid Category

```bash
flow alias invalid
```

**Expected Result:**

- Shows help for `flow alias` command
- Lists valid categories
- Returns to summary view

**Visual Verification:**

- [ ] Help displayed
- [ ] Valid categories listed
- [ ] No error/crash

### Test 3.7: Alias Shortcut

```bash
als
```

**Expected Result:**

- Same output as `flow alias`
- Backward compatibility maintained

**Visual Verification:**

- [ ] `als` works
- [ ] Output identical to `flow alias`

---

## Integration Tests

### Test 4.1: Flow Command Routing

```bash
# Test all new subcommands route correctly
flow help              # Regular help (with context banner)
flow help -i           # Interactive help browser
flow help --interactive # Interactive help browser (long form)
flow alias             # Alias reference summary
flow alias r           # R aliases
```

**Expected Result:**

- Each command routes to correct function
- No "command not found" errors
- Output matches expectations

**Visual Verification:**

- [ ] All routes work
- [ ] No errors
- [ ] Correct output for each

### Test 4.2: Context Switching

```bash
# Switch between project types rapidly
cd /tmp/flow-test/r-package && flow help | head -5
cd /tmp/flow-test/node-project && flow help | head -5
cd /tmp/flow-test/git-repo && flow help | head -5
cd /tmp/flow-test/empty && flow help | head -5
```

**Expected Result:**

- Context banner changes correctly for each directory
- No caching issues
- Detection is immediate

**Visual Verification:**

- [ ] Context updates each time
- [ ] No stale banners
- [ ] Fast detection

### Test 4.3: Interactive to Non-Interactive Transition

```bash
# Launch interactive, press Esc, then run normal help
flow help -i
# (press Esc to exit)
flow help
```

**Expected Result:**

- Interactive mode exits cleanly
- Normal help works after
- No terminal corruption

**Visual Verification:**

- [ ] fzf exits cleanly
- [ ] Terminal restored
- [ ] Normal help displays correctly

### Test 4.4: Alias Command in Different Contexts

```bash
cd /tmp/flow-test/r-package
flow alias r

cd /tmp/flow-test/node-project
flow alias r
```

**Expected Result:**

- Alias output **identical** in both contexts
- Context detection doesn't affect alias display
- Aliases work globally

**Visual Verification:**

- [ ] Output same in all contexts
- [ ] R aliases work in Node project
- [ ] No context-specific filtering

---

## Regression Tests

### Test 5.1: Existing Help Still Works

```bash
flow help
flow help work
flow help --list
flow help --search dash
```

**Expected Result:**

- All existing help patterns still function
- New context banner added to regular help
- --list and --search unchanged

**Visual Verification:**

- [ ] Regular help works
- [ ] Topic help works
- [ ] --list works
- [ ] --search works
- [ ] Context banner added (non-breaking)

### Test 5.2: Dispatcher Help Unaffected

```bash
r help
g help
mcp help
qu help
cc help
wt help
obs help
tm help
```

**Expected Result:**

- All dispatcher help commands work
- No interference from new features
- Output unchanged

**Visual Verification:**

- [ ] All dispatcher helps work
- [ ] No errors
- [ ] Output format unchanged

### Test 5.3: Existing Commands Unaffected

```bash
work
finish
dash
pick
catch "test"
js
```

**Expected Result:**

- All existing commands work normally
- No breaking changes
- Functionality preserved

**Visual Verification:**

- [ ] All commands work
- [ ] No new errors
- [ ] Behavior unchanged

---

## Edge Cases

### Test 6.1: Large Terminal Width

```bash
# Resize terminal to very wide (>200 columns)
flow alias r
```

**Expected Result:**

- Output still readable
- No line wrapping issues
- Table formatting maintained

**Visual Verification:**

- [ ] No wrapping issues
- [ ] Readable at all widths

### Test 6.2: Small Terminal Width

```bash
# Resize terminal to narrow (80 columns)
flow alias r
```

**Expected Result:**

- Output wraps gracefully
- Content still accessible
- No truncation of critical info

**Visual Verification:**

- [ ] Wraps gracefully
- [ ] All content visible

### Test 6.3: No Color Terminal

```bash
export NO_COLOR=1
flow help
flow alias
unset NO_COLOR
```

**Expected Result:**

- Output still readable without colors
- Structure preserved
- No ANSI escape codes visible

**Visual Verification:**

- [ ] Readable without color
- [ ] No escape codes shown
- [ ] Structure clear

### Test 6.4: Context Detection with Broken Files

```bash
# Create invalid project files
mkdir -p /tmp/flow-test/broken
echo "INVALID JSON" > /tmp/flow-test/broken/package.json
cd /tmp/flow-test/broken
flow help
```

**Expected Result:**

- No crash
- Falls back to "general" context
- Error handling graceful

**Visual Verification:**

- [ ] No crash or error
- [ ] Graceful fallback
- [ ] Help still displays

---

## Performance Tests

### Test 7.1: Context Detection Speed

```bash
# Test in different project types
for dir in r-package node-project git-repo empty; do
  echo -n "$dir: "
  (cd "/tmp/flow-test/$dir" && time flow help > /dev/null)
done
```

**Expected Result:**

- All contexts < 100ms total
- Context detection < 10ms
- Most time in rendering

**Performance Verification:**

- [ ] R package: < 100ms
- [ ] Node project: < 100ms
- [ ] Git repo: < 100ms
- [ ] Empty dir: < 100ms

### Test 7.2: Alias Display Speed

```bash
time flow alias
time flow alias r
time flow alias dispatchers
```

**Expected Result:**

- All alias displays < 50ms
- Near-instant rendering
- No perceptible delay

**Performance Verification:**

- [ ] Summary: < 50ms
- [ ] Category: < 50ms
- [ ] Dispatchers: < 50ms

---

## User Experience Tests

### Test 8.1: First-Time User Discovery

```bash
# Simulate new user
cd /tmp/flow-test/empty
flow help
```

**Expected Result:**

- Context banner suggests exploration tools
- Help output is approachable
- Clear next steps

**UX Verification:**

- [ ] Helpful for new users
- [ ] Clear guidance
- [ ] Not overwhelming

### Test 8.2: R Developer Discovery

```bash
cd /tmp/flow-test/r-package
flow help
flow alias r
```

**Expected Result:**

- R-specific context immediately visible
- Relevant aliases easy to find
- R dispatcher discoverable

**UX Verification:**

- [ ] R tools highlighted
- [ ] Workflow clear
- [ ] Aliases useful

### Test 8.3: Command Exploration Flow

```bash
# Natural discovery flow
flow help              # See context banner
flow help -i           # Explore interactively
flow alias             # Browse aliases
flow alias cc          # Dig into category
```

**Expected Result:**

- Smooth progression through features
- Each step leads naturally to next
- No dead ends

**UX Verification:**

- [ ] Flow feels natural
- [ ] Features interconnected
- [ ] Easy to explore

---

## Cleanup

```bash
# Remove test directories
rm -rf /tmp/flow-test
```

---

## Sign-Off Checklist

### Feature 1: Interactive Help Browser

- [ ] fzf integration works
- [ ] Search/filter functional
- [ ] Preview pane updates
- [ ] Graceful fallback without fzf
- [ ] No crashes or errors

### Feature 2: Context-Aware Help

- [ ] R package detection
- [ ] Node.js detection
- [ ] Git repo detection
- [ ] General fallback
- [ ] Context banner formatting
- [ ] Priority order correct
- [ ] Performance < 100ms

### Feature 3: Alias Reference

- [ ] Summary view complete
- [ ] All categories work
- [ ] R aliases (23) accurate
- [ ] Claude Code aliases correct
- [ ] Dispatcher list complete
- [ ] Git plugin reference clear
- [ ] `als` shortcut works

### Integration

- [ ] Flow command routing
- [ ] Context switching
- [ ] Interactive/non-interactive transition
- [ ] Cross-context alias display

### Regression

- [ ] Existing help unchanged
- [ ] Dispatcher helps work
- [ ] Core commands functional
- [ ] No breaking changes

### Edge Cases

- [ ] Wide terminal
- [ ] Narrow terminal
- [ ] No color mode
- [ ] Broken project files

### Performance

- [ ] Context detection < 10ms
- [ ] Help display < 100ms
- [ ] Alias display < 50ms

### User Experience

- [ ] New user friendly
- [ ] R developer friendly
- [ ] Exploration flow natural
- [ ] Documentation clear

---

## Test Results

**Tester:** ******\_\_\_******
**Date:** ******\_\_\_******
**Environment:** ******\_\_\_******
**Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

**Notes:**

```


```

**Issues Found:**

```


```

**Blockers:**

```


```

---

## Automated Test Coverage

This manual test guide complements automated tests in `tests/test-phase2-features.zsh`:

- **Manual tests:** 31 test procedures (UX, visual, integration)
- **Automated tests:** 47 tests (unit, edge cases, E2E, regression, performance)
- **Total coverage:** Core functionality + user workflows

Run automated tests:

```bash
./tests/test-phase2-features.zsh
```

---

**Version:** v4.9.0 Phase 2
**Last Updated:** 2026-01-05
**Status:** Ready for Testing
