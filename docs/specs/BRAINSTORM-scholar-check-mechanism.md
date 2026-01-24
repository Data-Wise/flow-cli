# BRAINSTORM: flow-cli Scholar Check Mechanism

**Generated:** 2026-01-14
**Context:** flow-cli + Scholar coordination
**Principle:** Teaching will ALWAYS be coordinated with Scholar

---

## Overview

Create a mechanism for flow-cli to verify Scholar availability before invoking Scholar teaching commands.

---

## Problem Statement

When a user runs `teach exam "Topic"` (future wrapper), flow-cli needs to:
1. Check if Claude Code CLI is available
2. Check if Scholar plugin is installed/enabled
3. Check if the specific command exists
4. Optionally check version compatibility

Currently, flow-cli has no way to verify Scholar availability - it would just fail if Scholar isn't present.

---

## Options

### Option A: Simple CLI Check (Recommended)

**Effort:** ⚡ Quick (30 min)
**Pros:** Simple, no dependencies, works offline
**Cons:** Can't check plugin availability directly

```zsh
_teach_check_scholar() {
    # 1. Check Claude Code CLI exists
    if ! command -v claude &>/dev/null; then
        _flow_log_error "Claude Code CLI not found"
        _flow_log_info "Install: https://claude.ai/code"
        return 1
    fi

    # 2. Check version (optional)
    local version=$(claude --version 2>/dev/null | head -1)
    if [[ -z "$version" ]]; then
        _flow_log_warn "Could not determine Claude Code version"
    fi

    return 0
}
```

---

### Option B: Plugin Detection via Settings

**Effort:** 🔧 Medium (1-2 hours)
**Pros:** Can verify Scholar is actually installed
**Cons:** Relies on settings file structure (may change)

```zsh
_teach_check_scholar() {
    local settings_global="$HOME/.claude/settings.json"
    local settings_local=".claude/settings.local.json"

    # Check if Scholar plugin is configured
    # Note: This depends on Claude Code settings structure

    # Global settings
    if [[ -f "$settings_global" ]]; then
        if grep -q '"scholar"' "$settings_global" 2>/dev/null; then
            return 0
        fi
    fi

    # Local settings
    if [[ -f "$settings_local" ]]; then
        if grep -q '"scholar"' "$settings_local" 2>/dev/null; then
            return 0
        fi
    fi

    _flow_log_warn "Scholar plugin not detected in Claude Code settings"
    return 1
}
```

---

### Option C: Runtime Validation (Most Robust)

**Effort:** 🏗️ Large (2-3 hours)
**Pros:** Actually tests Scholar availability
**Cons:** Requires Claude API call, slower, costs API credits

```zsh
_teach_validate_scholar() {
    # Actually call Scholar to verify it works
    local result=$(claude --print "/scholar:ping" 2>&1)

    if [[ "$result" == *"pong"* ]]; then
        return 0
    else
        _flow_log_error "Scholar plugin not responding"
        return 1
    fi
}
```

**Note:** This requires Scholar to have a `/scholar:ping` command (doesn't exist yet).

---

### Option D: Hybrid Approach (Pragmatic)

**Effort:** 🔧 Medium (1 hour)
**Pros:** Fast local checks + graceful degradation
**Cons:** More complex logic

```zsh
_teach_check_scholar() {
    local status=0

    # Level 1: CLI exists
    if ! command -v claude &>/dev/null; then
        _flow_log_error "Claude Code CLI not found"
        _flow_log_info "Install: https://claude.ai/code"
        return 1
    fi

    # Level 2: Config exists (optional)
    if [[ ! -f ".flow/teach-config.yml" ]]; then
        _flow_log_warn "No .flow/teach-config.yml found"
        _flow_log_info "Run 'teach init' to create config"
        status=2  # Warning level
    fi

    # Level 3: Scholar section in config (optional)
    if [[ -f ".flow/teach-config.yml" ]] && ! grep -q "^scholar:" .flow/teach-config.yml; then
        _flow_log_warn "No 'scholar:' section in config"
        _flow_log_info "Scholar will use defaults"
        # Don't fail - Scholar can work without explicit config
    fi

    return $status
}
```

---

## Recommended Path

**Start with Option A + D hybrid:**

1. **Phase 1:** Implement simple CLI check (Option A)
   - Fast, reliable, no false negatives
   - Works offline

2. **Phase 2:** Add config validation (Option D)
   - Check for .flow/teach-config.yml
   - Check for scholar section
   - Provide helpful messages

3. **Future:** Consider Option C if Scholar adds `/scholar:ping`
   - Only for explicit validation scenarios
   - Not for every command invocation

---

## Implementation Location

```
lib/dispatchers/teach-dispatcher.zsh
├── _teach_check_scholar()      # NEW: Validation function
├── _teach_scholar_wrapper()    # Uses _teach_check_scholar
└── teach()                     # Main dispatcher
```

---

## Integration with Wrapper Spec

The wrapper spec (`SPEC-teach-scholar-wrappers.md`) already defines preflight checks:

```zsh
_teach_preflight() {
    # 1. Check config exists
    # 2. Check Scholar section exists (warning only)
    # 3. Check Claude Code available  ← This is _teach_check_scholar
}
```

The `_teach_check_scholar()` function implements step 3.

---

## User Experience

### Before (no check)

```bash
$ teach exam "Hypothesis Testing"
# ... long pause ...
# Cryptic error from Claude CLI
```

### After (with check)

```bash
$ teach exam "Hypothesis Testing"
❌ teach: Claude Code CLI not found
   Install: https://claude.ai/code

# OR

⚠️  teach: No .flow/teach-config.yml found
   Run 'teach init' first or Scholar will use defaults

Proceeding with Scholar...
```

---

## Quick Wins

1. ⚡ Add `command -v claude` check to teach dispatcher (5 min)
2. ⚡ Add helpful error messages with install links (10 min)
3. ⚡ Add config existence check (10 min)

---

## Next Steps

1. [ ] Decide which option to implement
2. [ ] Add to teach-dispatcher.zsh
3. [ ] Test with and without Claude Code installed
4. [ ] Update SPEC-teach-scholar-wrappers.md with final implementation

---

## Questions for User

1. Should the check run on every `teach` command, or only Scholar wrappers?
2. Should we fail hard (exit 1) or warn and continue?
3. Want to add a `teach doctor` command for explicit validation?

---

*Last Updated: 2026-01-14*
