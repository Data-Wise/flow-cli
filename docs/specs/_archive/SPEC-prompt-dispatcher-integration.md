# SPEC: Prompt Engine Dispatcher Integration

**Status:** Draft
**Created:** 2026-01-14
**From Brainstorm:** BRAINSTORM-flow-cli-prompt-dispatcher.md
**Priority:** Medium
**Target Release:** v5.7.0+

---

## Overview

Integrate the dual-mode prompt engine (Powerlevel10k ↔ Starship) into flow-cli as a new `prompt` dispatcher. This provides a discoverable, consistent command interface that follows flow-cli's architecture patterns and makes the prompt engine a first-class feature.

**Current State:**
- ✅ Dual-mode system fully implemented (75/75 tests passing)
- ✅ Configuration complete (.zshrc, .zshenv, starship.toml, .p10k.zsh)
- ⚠️ Not discoverable as flow-cli feature (scattered as aliases)

**After Integration:**
- ✅ Accessible via `prompt <action>` (status, toggle, list, help)
- ✅ Discoverable: `prompt help` shows all options
- ✅ Consistent with other dispatchers (g, r, mcp, teach, tm)
- ✅ Foundation for future extensions

---

## User Stories

### Primary User Story

**As a** flow-cli user
**I want to** manage my prompt engine (Powerlevel10k ↔ Starship) via a discoverable flow-cli dispatcher
**So that** I can easily switch between lightweight and feature-rich prompts without remembering multiple aliases

**Acceptance Criteria:**
- [ ] `prompt status` shows current engine and available alternatives
- [ ] `prompt toggle` switches to the other engine seamlessly
- [ ] `prompt starship` forces switch to Starship specifically
- [ ] `prompt p10k` forces switch to Powerlevel10k specifically
- [ ] `prompt list` shows all available engines
- [ ] `prompt help` displays complete documentation
- [ ] No errors or warnings when switching engines
- [ ] New shell loads correct engine after switch

### Secondary User Story 1

**As a** flow-cli contributor
**I want to** extend the prompt system with new features (themes, history, analytics)
**So that** I can add sophisticated prompt management features without redesigning the foundation

**Acceptance Criteria:**
- [ ] Dispatcher structure supports adding new subcommands
- [ ] Each subcommand has its own function (`_prompt_*()`)
- [ ] Easy to add `prompt theme`, `prompt history`, `prompt profile` in future
- [ ] No architectural changes needed for extensions

### Secondary User Story 2

**As a** developer
**I want to** the prompt engine fully integrated into flow-cli
**So that** the system is cohesive and doesn't have scattered external aliases

**Acceptance Criteria:**
- [ ] `prompt` dispatcher is the primary interface
- [ ] No external aliases (ptoggle, pstarship, pp10k removed)
- [ ] All functionality in `prompt <action>` commands
- [ ] Help system is complete and discoverable

---

## Technical Requirements

### Architecture

#### Dispatcher Pattern

```
prompt [action] [options]
    ├── status (s)  → _prompt_status()
    ├── toggle (t)  → _prompt_toggle()
    ├── starship    → _prompt_starship()
    ├── p10k        → _prompt_p10k()
    ├── list (ls)   → _prompt_list()
    └── help        → _prompt_help()
```

#### File Structure

```
lib/dispatchers/prompt-dispatcher.zsh    # Main dispatcher + functions
completions/_prompt                       # Tab completion
docs/reference/MASTER-DISPATCHER-GUIDE.md   # Documentation
docs/guides/PROMPT-DISPATCHER.md         # Guide
tests/test-prompt-dispatcher.zsh         # Unit & E2E tests
```

#### Environment

- Uses existing `FLOW_PROMPT_ENGINE` variable
- Reads from ~/.zshenv, ~/.zshrc
- Accesses existing config files unchanged
- No new environment variables needed

### Functional Requirements

| Requirement | Priority | Details |
|-------------|----------|---------|
| **Status command** | MUST | Show current engine with clean output |
| **Toggle command** | MUST | Switch between engines without errors |
| **Engine-specific commands** | MUST | `prompt starship` and `prompt p10k` for forced switches |
| **List command** | SHOULD | Show available engines (could be 2+) |
| **Help system** | MUST | Display usage and examples |
| **Tab completion** | SHOULD | Autocomplete actions (status, toggle, etc.) |
| **Clean primary interface** | MUST | `prompt` is the only way to access (no external aliases) |
| **Discoverable** | MUST | `prompt help` shows all options |
| **Error handling** | SHOULD | Graceful failures with clear messages |

### Non-Functional Requirements

| Requirement | Priority | Details |
|-------------|----------|---------|
| **Performance** | SHOULD | Dispatcher load < 1ms, toggle < 500ms |
| **Testing** | MUST | 30+ unit tests, E2E tests, edge cases |
| **Documentation** | MUST | Complete dispatcher docs + examples |
| **Maintainability** | SHOULD | Clear function names, consistent patterns |

---

## Implementation Plan

### Phase 1: Core Dispatcher (Session 2)

**Time:** ~1 hour
**Deliverables:**
- Create `lib/dispatchers/prompt-dispatcher.zsh`
- Implement `prompt()` function with case statement
- Implement helper functions:
  - `_prompt_status()` - Current engine + alternatives
  - `_prompt_toggle()` - Switch engines
  - `_prompt_starship()` - Force Starship
  - `_prompt_p10k()` - Force P10k
  - `_prompt_list()` - Available engines
  - `_prompt_help()` - Display help
- Load dispatcher in `flow.plugin.zsh`

**Test:** Basic functionality tests

### Phase 2: Polish & Completions (Session 3)

**Time:** ~45 minutes
**Deliverables:**
- Add `completions/_prompt` for tab completion
- Update `flow.plugin.zsh` to ensure proper loading
- Add help text with examples
- Implement `_prompt_validate()` for error checking
- Test with different shell environments

### Phase 3: Documentation (Session 3)

**Time:** ~20 minutes
**Deliverables:**
- Update `docs/reference/MASTER-DISPATCHER-GUIDE.md`
- Add prompt section with all actions documented
- Update `docs/help/QUICK-REFERENCE.md`
- Update `CLAUDE.md` quick reference
- Create `docs/guides/PROMPT-DISPATCHER.md` if detailed guide needed

### Phase 4: Comprehensive Testing (Session 4)

**Time:** ~1 hour
**Deliverables:**
- Create `tests/test-prompt-dispatcher.zsh` with:
  - 15+ unit tests for dispatcher logic
  - 5+ E2E tests for actual engine switching
  - Edge case tests (invalid engines, missing configs, etc.)
  - Integration tests with other flow-cli components
- Verify all existing tests still pass
- Test backward compatibility with aliases

### Phase 5: Integration & Release (Session 5)

**Time:** ~30 minutes
**Deliverables:**
- Final validation in feature branch
- Create PR to `dev` with comprehensive description
- Merge to `dev`
- Prepare release notes for v5.7.0+

---

## Data Models

### FLOW_PROMPT_ENGINE Variable

```bash
# In ~/.zshenv
export FLOW_PROMPT_ENGINE="${FLOW_PROMPT_ENGINE:-powerlevel10k}"

# Valid values
- "powerlevel10k"
- "starship"

# Accessed by dispatcher
$FLOW_PROMPT_ENGINE  # Current engine
```

### Engine Configuration

```
Powerlevel10k:
  - Config: ~/.config/zsh/.p10k.zsh
  - Instant prompt: ~/.cache/p10k-instant-prompt-${user}.zsh
  - Plugin: via antidote (from .zsh_plugins.txt)
  - Init: source ~/.p10k.zsh (after antidote loads)

Starship:
  - Config: ~/.config/starship.toml
  - Binary: /opt/homebrew/bin/starship (or in PATH)
  - Init: eval "$(starship init zsh)"
  - Cache: ~/.cache/starship
```

---

## API Design

### Command Structure

```bash
prompt [action] [options]

# Actions
prompt status              # Show current engine info
prompt toggle              # Switch to other engine
prompt starship            # Switch to Starship
prompt p10k                # Switch to P10k
prompt list                # List available engines
prompt help                # Show this help
```

### Output Format

#### `prompt status`

```
🎨 Current Prompt Engine: powerlevel10k
   Alternative: starship

   To switch: prompt toggle
```

#### `prompt toggle`

```
✅ Switched to starship

[... terminal reloads ...]
```

#### `prompt list`

```
Available Prompt Engines:

  ● powerlevel10k (current)
    Feature-rich, highly customizable
    Config: ~/.config/zsh/.p10k.zsh

  ○ starship
    Minimal, fast Rust-based prompt
    Config: ~/.config/starship.toml
```

#### `prompt help`

```
🎨 PROMPT DISPATCHER
   Manage dual-mode prompt system (Powerlevel10k ↔ Starship)

USAGE:
   prompt <action> [options]

ACTIONS:
   status          Show current engine & alternatives
   toggle          Switch to other engine
   starship        Force switch to Starship
   p10k            Force switch to Powerlevel10k
   list            List available engines
   help            Show this help

EXAMPLES:
   prompt status            # See what's active
   prompt toggle            # Switch engines
   prompt starship          # Go to Starship
   prompt p10k              # Go to Powerlevel10k
   prompt list              # See available engines
```

---

## Testing Strategy

### Unit Tests (test-prompt-dispatcher.zsh)

```
✓ Dispatcher routing (all actions)
✓ Status output format
✓ Toggle logic and validation
✓ Engine switching (force starship/p10k)
✓ List output format
✓ Help text content
✓ Error handling (invalid actions, missing configs)
✓ Validation helper function
✓ Get current engine function
✓ Get alternatives function
```

### E2E Tests

```
✓ Prompt loads correct engine after toggle
✓ No errors in fresh shell
✓ Backward compatible aliases work
✓ Status shows correct engine after switch
✓ Multiple toggles in sequence
✓ Switching to same engine (idempotent)
```

### Integration Tests

```
✓ Dispatcher loads with flow-cli
✓ Help system recognizes prompt
✓ Tab completion works
✓ No conflicts with other dispatchers
✓ Works with custom flow-cli settings
```

---

## UI/UX Specifications

### User Interaction Flow

#### Scenario 1: Check Current Engine

```
User: prompt status
System: Shows current engine + alternatives
        "To switch: prompt toggle"
Time: ~100ms
```

#### Scenario 2: Switch Engines

```
User: prompt toggle
System: Shows "✅ Switched to starship"
        Shell reloads (exec zsh)
        New prompt loads
Time: ~500ms
```

#### Scenario 3: Learn Available Options

```
User: prompt help
System: Shows all actions with examples
Time: ~50ms
```

#### Scenario 4: Legacy Alias Usage

```
User: ptoggle
System: (maps to prompt toggle)
        Shows "✅ Switched to ..."
        Works exactly as before
Time: ~500ms
```

### Error Handling

| Scenario | Message | Recovery |
|----------|---------|----------|
| Invalid action | "Unknown action: xyz. Use: prompt help" | Show help |
| Invalid engine | "Engine 'zsh-pure' not available" | Suggest alternatives |
| Config missing | "Starship config not found. Run: starship config" | Guide to setup |
| Starship not installed | "Starship not found in PATH" | Suggest: brew install starship |

---

## Dependencies

### Required

- Flow-cli base system (already present)
- ZSH shell (already required)
- Powerlevel10k (already configured)
- Starship (already installed)

### No New Dependencies

- Uses existing `FLOW_PROMPT_ENGINE` variable
- Uses existing prompt system configuration
- No additional tools or libraries needed

---

## Open Questions

1. **Should status show performance metrics?**
   - Load time for each engine?
   - Decision: Defer to future version (v5.8.0+)

2. **Should we add prompt theme management?**
   - `prompt theme list`, `prompt theme apply <name>`
   - Decision: Future enhancement, documented in roadmap

3. **Should we auto-detect engine preference on first run?**
   - Run wizard to choose default?
   - Decision: Defer - current default (P10k) is fine

4. **Future: Smart switching based on context?**
   - Auto-switch Starship for minimal terminals?
   - Auto-switch P10k for feature terminals?
   - Decision: Future (v5.8.0+), requires profiling

---

## Review Checklist

- [ ] Architecture approved (dispatcher pattern)
- [ ] Feature branch created
- [ ] Core dispatcher implemented
- [ ] All helper functions complete
- [ ] Tab completion added
- [ ] Documentation updated
- [ ] All unit tests passing (30+)
- [ ] E2E tests passing
- [ ] Integration tests passing
- [ ] Backward compatibility verified
- [ ] No new aliases introduced
- [ ] PR created to dev
- [ ] Merged to dev
- [ ] Release notes prepared
- [ ] Documented in CLAUDE.md

---

## Release Notes (v5.7.0+)

### New Feature: Prompt Dispatcher

**What's New:**
- New `prompt` dispatcher provides discoverable interface for dual-mode prompt system
- Commands: `prompt status|toggle|starship|p10k|list|help`
- Tab completion for all actions
- Primary interface integrated into flow-cli

**Usage:**

```bash
prompt help             # See all options
prompt status          # Show current engine
prompt toggle          # Switch to other engine
prompt starship        # Go to Starship
prompt p10k            # Go to Powerlevel10k
prompt list            # See available engines
```

**Why:**
- Follows flow-cli dispatcher pattern
- Fully integrated into flow-cli framework
- Discoverable via help system
- Foundation for future prompt management features

**Setup:**
- Already configured in flow-cli
- Use `prompt <action>` to manage prompt engine
- No additional setup needed

---

## Implementation Notes

### Key Considerations

1. **Backward Compatibility is Critical**
   - Don't rename aliases (ptoggle, pstarship, pp10k)
   - Don't change behavior of existing functions
   - Keep existing config files unchanged

2. **Consistency with Other Dispatchers**
   - Follow `lib/dispatchers/g-dispatcher.zsh` pattern
   - Same help format as other dispatchers
   - Same error handling approach

3. **Testing is Extensive**
   - Test in fresh shell (not current shell)
   - Test with different shell profiles
   - Test edge cases (missing configs, invalid engines)

4. **Performance**
   - Dispatcher should add < 1ms to load time
   - Toggle switch < 500ms total
   - No impact on daily shell usage

### Environment Assumptions

- ZSH 5.8+
- Antidote plugin manager
- Homebrew for starship binary
- Standard ~/.config/ directory structure

---

## History

| Date | Author | Change | Status |
|------|--------|--------|--------|
| 2026-01-14 | Claude | Initial spec created from brainstorm | Draft |
| - | DT | (Approval pending) | Pending |
| - | - | (Implementation in next session) | Planned |

---

**Spec Status:** Ready for Implementation
**Next Steps:** Create feature branch and implement Phase 1 (dispatcher core)
