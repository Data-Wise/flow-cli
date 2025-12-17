# ZSH Configuration Conventions

> Rules and standards for maintaining the shell configuration.

---

## Naming Conventions

### Dispatchers

| Frequency | Style | Examples |
|-----------|-------|----------|
| Daily (50+ times) | Single letter | `r`, `g`, `v` |
| Frequent (10-50) | Two letters | `qu`, `cc`, `gm` |
| Occasional (<10) | Full word | `work`, `dash`, `pick` |

### Keywords (Dispatcher Actions)

```bash
# Use verbs for actions
test, check, build, push, pull, add, commit, render

# Use nouns for information
status, log, branch, diff, help

# Use abbreviations consistently
doc  = document
cov  = coverage
cob  = checkout -b (create branch)
```

### Files

| Type | Pattern | Example |
|------|---------|---------|
| Dispatcher | `<letter>-dispatcher.zsh` | `g-dispatcher.zsh` |
| Helper collection | `<domain>-helpers.zsh` | `adhd-helpers.zsh` |
| Single purpose | `<purpose>.zsh` | `work.zsh` |
| Test file | `test-<name>.zsh` | `test-duplicates.zsh` |

### Functions

```bash
# Public function (user-facing)
g()           # Dispatcher
work()        # Helper function
dash()        # Helper function

# Private function (internal)
_g_help()           # Help for g
_v_test_run()       # Internal to v dispatcher
_c_bold()           # Color helper
```

### Aliases

```bash
# Simple shortcuts only (no logic)
alias ..='cd ..'
alias ll='eza -lah'
alias reload='source ~/.zshrc'

# Typo tolerance (redirect to dispatcher)
alias gti='g'
alias gis='g'
```

---

## File Organization

### Directory Structure

```
~/.config/zsh/
├── .zshrc                      # Main entry point
├── functions/                  # All function files
│   ├── smart-dispatchers.zsh   # r, qu, cc, gm, focus
│   ├── v-dispatcher.zsh        # v/vibe
│   ├── g-dispatcher.zsh        # git
│   ├── adhd-helpers.zsh        # work, dash, pb, pv, pt
│   ├── work.zsh                # Work session
│   ├── dash.zsh                # Dashboard
│   ├── status.zsh              # Status functions
│   └── fzf-helpers.zsh         # FZF integrations
├── completions/                # Custom completions
└── tests/                      # Test scripts
```

### File Header Template

```bash
#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# <NAME> - <Brief Description>
# ══════════════════════════════════════════════════════════════════════════════
#
# File:         ~/.config/zsh/functions/<filename>.zsh
# Version:      1.0
# Date:         YYYY-MM-DD
# Pattern:      command + keyword + options
#
# Usage:        <cmd> <action> [args]
#
# Examples:
#   <cmd> action1           # Description
#   <cmd> action2 arg       # Description
#
# ══════════════════════════════════════════════════════════════════════════════
```

---

## Dispatcher Structure

### Template

```bash
<cmd>() {
    # No arguments → default action
    if [[ $# -eq 0 ]]; then
        <default_action>
        return
    fi

    case "$1" in
        # ─────────────────────────────────────────────────────────────
        # CATEGORY 1
        # ─────────────────────────────────────────────────────────────
        action1|a1)
            shift
            <implementation> "$@"
            ;;

        action2|a2)
            shift
            <implementation> "$@"
            ;;

        # ─────────────────────────────────────────────────────────────
        # HELP
        # ─────────────────────────────────────────────────────────────
        help|h|--help|-h)
            _<cmd>_help
            ;;

        # ─────────────────────────────────────────────────────────────
        # PASSTHROUGH (optional)
        # ─────────────────────────────────────────────────────────────
        *)
            <underlying_command> "$@"
            ;;
    esac
}
```

### Help Function Template

```bash
_<cmd>_help() {
    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ <cmd> - <Domain Description>               │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}<cmd> action1${_C_NC}     Description
  ${_C_CYAN}<cmd> action2${_C_NC}     Description

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} <cmd> action1     ${_C_DIM}# Comment${_C_NC}
  ${_C_DIM}\$${_C_NC} <cmd> action2     ${_C_DIM}# Comment${_C_NC}

${_C_BLUE}📋 ALL ACTIONS${_C_NC}:
  ${_C_CYAN}<cmd> action1${_C_NC}     Description
  ${_C_CYAN}<cmd> action2${_C_NC}     Description
  ${_C_CYAN}<cmd> action3${_C_NC}     Description

${_C_MAGENTA}💡 TIP${_C_NC}: Unknown commands pass through
  ${_C_DIM}<cmd> anything → <underlying> anything${_C_NC}
"
}
```

---

## Color Conventions

```bash
# Standard colors (define once, use everywhere)
_C_BOLD='\033[1m'      # Headers, emphasis
_C_DIM='\033[2m'       # Comments, less important
_C_NC='\033[0m'        # Reset

_C_GREEN='\033[32m'    # Success, most common
_C_YELLOW='\033[33m'   # Examples, warnings
_C_BLUE='\033[34m'     # Categories, info
_C_CYAN='\033[36m'     # Commands, actions
_C_MAGENTA='\033[35m'  # Tips, related info
_C_RED='\033[31m'      # Errors
```

### Usage

```bash
echo -e "${_C_GREEN}Success!${_C_NC}"
echo -e "${_C_RED}Error:${_C_NC} Something went wrong"
echo -e "${_C_CYAN}g push${_C_NC}  Push to remote"
```

---

## Rules

### R1: No Duplicates

```bash
# WRONG: Same alias in multiple places
# .zshrc:         alias gst='git status'
# g-dispatcher:   g status → git status

# RIGHT: Single source of truth
# g-dispatcher:   g status → git status
# .zshrc:         (no gst alias)
```

**Check before adding:**
```bash
grep -rn "alias <name>=" ~/.config/zsh/
grep -rn "^<name>()" ~/.config/zsh/
```

### R2: Functions > Aliases

```bash
# WRONG: Complex alias
alias deploy='git push && ssh server "cd /app && pull && restart"'

# RIGHT: Function with logic
deploy() {
    echo "Pushing to remote..."
    git push || return 1
    echo "Deploying to server..."
    ssh server "cd /app && git pull && ./restart.sh"
}
```

### R3: Always Provide Help

```bash
# WRONG: No help available
mycmd() {
    case "$1" in
        action1) ... ;;
        *) echo "Unknown" ;;
    esac
}

# RIGHT: Help is always available
mycmd() {
    case "$1" in
        action1) ... ;;
        help|h) _mycmd_help ;;
        *) echo "Unknown. Run: mycmd help" ;;
    esac
}
```

### R4: Graceful Degradation

```bash
# WRONG: Assumes tool exists
alias ls='eza --icons'

# RIGHT: Check first
if command -v eza &>/dev/null; then
    alias ls='eza --icons'
else
    alias ls='ls -G'
fi
```

### R5: No Blocking Startup

```bash
# WRONG: Blocking call in .zshrc
WEATHER=$(curl -s wttr.in/\?format=3)

# RIGHT: Lazy function
weather() {
    curl -s "wttr.in/?format=3"
}
```

### R6: Document Changes

When modifying configuration:

1. Update relevant help functions
2. Add entry to decision log (if significant)
3. Update COMMAND-QUICK-REFERENCE.md
4. Run tests before committing

---

## Testing Requirements

### Before Committing

```bash
# 1. Syntax check
shellcheck ~/.config/zsh/functions/*.zsh

# 2. Duplicate check
./tests/test-duplicates.zsh

# 3. Dispatcher test
./tests/test-dispatchers.zsh

# 4. Load test (optional)
time zsh -ic exit
```

### Test File Template

```bash
#!/usr/bin/env zsh
# test-<name>.zsh - <Description>

source ~/.config/zsh/functions/<file>.zsh

# Test cases
test_<function>() {
    # Setup
    local result

    # Execute
    result=$(<function> <args>)

    # Assert
    if [[ "$result" == "expected" ]]; then
        echo "✓ <function>: passed"
    else
        echo "✗ <function>: FAILED"
        echo "  Expected: expected"
        echo "  Got: $result"
    fi
}

# Run tests
test_<function>
```

---

## Checklist for New Dispatchers

- [ ] Single file: `<letter>-dispatcher.zsh`
- [ ] Function named: `<letter>()`
- [ ] Help function: `_<letter>_help()`
- [ ] Default action (no args)
- [ ] Passthrough for unknown commands
- [ ] Sourced in `.zshrc`
- [ ] Added to COMMAND-QUICK-REFERENCE.md
- [ ] Tests written

---

*Last Updated: 2025-12-17*
