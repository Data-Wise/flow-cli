# SPEC: Flow Alias Enhancement

**Status:** complete
**Created:** 2026-01-12
**Completed:** 2026-01-12
**From Brainstorm:** Deep brainstorm session

---

## Overview

Expand `flow alias` command from a read-only reference tool to a full alias management suite with validation, creation, removal, testing, and health checking capabilities. Primary goal: eliminate broken/conflicting aliases through comprehensive validation.

---

## Primary User Story

**As a** developer using flow-cli
**I want to** validate, create, and manage shell aliases safely
**So that** I don't have broken aliases, conflicts with system commands, or duplicates

### Acceptance Criteria

- [x] `flow alias doctor` checks all aliases for issues
- [x] `flow alias add` creates validated aliases
- [x] `flow alias rm` safely removes aliases (comment out + backup)
- [x] `flow alias test` validates and dry-runs aliases
- [x] `flow alias find` searches aliases by pattern
- [x] `flow alias edit` opens .zshrc at alias section

---

## Secondary User Stories

### Story 2: Alias Conflict Detection
**As a** power user with many aliases
**I want to** know when an alias shadows a system command
**So that** I don't accidentally break expected behavior

### Story 3: Safe Alias Removal
**As a** user cleaning up old aliases
**I want to** remove aliases without risk of data loss
**So that** I can easily undo if something breaks

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ commands/alias.zsh                                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ flow_alias()              # Main dispatcher (extend)        │
│   ├── (existing)          # Show categories                 │
│   ├── add)                # → _flow_alias_add               │
│   ├── rm|remove)          # → _flow_alias_remove            │
│   ├── doctor)             # → _flow_alias_doctor            │
│   ├── test)               # → _flow_alias_test              │
│   ├── find)               # → _flow_alias_find              │
│   └── edit)               # → _flow_alias_edit              │
│                                                             │
│ # Core functions                                            │
│ _flow_alias_add()         # Create with validation          │
│ _flow_alias_remove()      # Safe removal (comment + backup) │
│ _flow_alias_doctor()      # Health check all aliases        │
│ _flow_alias_test()        # Validate → dry-run → execute    │
│ _flow_alias_find()        # Pattern search                  │
│ _flow_alias_edit()        # Open in $EDITOR                 │
│                                                             │
│ # Validation helpers                                        │
│ _flow_alias_validate()    # Core validation logic           │
│ _flow_alias_check_shadow()# Check command conflicts         │
│ _flow_alias_check_target()# Check target exists             │
│ _flow_alias_parse_zshrc() # Parse aliases from file         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## API Design

### Command Interface

| Command | Description | Example |
|---------|-------------|---------|
| `flow alias doctor` | Health check all aliases | `flow alias doctor` |
| `flow alias add [def]` | Create alias (interactive or one-liner) | `flow alias add bcl='brew list --cask'` |
| `flow alias rm <name>` | Safe removal (comment out) | `flow alias rm bcl` |
| `flow alias test <name>` | Validate and dry-run | `flow alias test bcl` |
| `flow alias find <pattern>` | Search aliases | `flow alias find brew` |
| `flow alias edit` | Open .zshrc at alias section | `flow alias edit` |

### Doctor Output Format

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🩺 Alias Health Check
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Scanning: ~/.config/zsh/.zshrc
Found: 27 aliases

❌ ERRORS (n)
  <alias>='<command>'
    └─ <issue description>
    └─ <suggestion>

⚠️  WARNINGS (n)
  <alias>='<command>'
    └─ <issue description>

✅ HEALTHY (n)
  <comma-separated list>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Summary: n errors, n warnings, n healthy
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Data Models

### Alias Validation Result

```zsh
# Returned by _flow_alias_validate()
# Format: "status:message"
# status: ok|error|warning
# message: description of issue

# Examples:
# "ok:valid"
# "error:shadows /bin/cat"
# "warning:long command, consider function"
```

### Parsed Alias Entry

```zsh
# Format from _flow_alias_parse_zshrc()
# line_number:alias_name:alias_value

# Example:
# "143:bcl:brew list --cask"
```

---

## Dependencies

- **Required:** ZSH, standard Unix tools (grep, sed)
- **Optional:** None (pure ZSH implementation)
- **Files:** `~/.config/zsh/.zshrc` (alias storage location)

---

## UI/UX Specifications

### User Flow: Doctor

```
User: flow alias doctor
  │
  ├─→ Parse .zshrc for all aliases
  ├─→ For each alias:
  │     ├─→ Check if shadows system command
  │     ├─→ Check if target exists
  │     ├─→ Check syntax validity
  │     └─→ Categorize: error/warning/healthy
  │
  └─→ Display formatted report
```

### User Flow: Add (Interactive)

```
User: flow alias add
  │
  ├─→ Prompt: "Alias name:"
  ├─→ Prompt: "Command:"
  ├─→ Validate (shadow, target, syntax)
  │     ├─→ If error: show issue, ask to proceed anyway
  │     └─→ If ok: continue
  ├─→ Append to .zshrc
  └─→ Show: "Added. Run: source ~/.config/zsh/.zshrc"
```

### User Flow: Remove

```
User: flow alias rm bcl
  │
  ├─→ Find alias in .zshrc
  │     └─→ If not found: error + exit
  ├─→ Show: "Found: alias bcl='...' (line 143)"
  ├─→ Confirm: "Remove? [y/N]"
  ├─→ Create backup: .zshrc.alias-backup
  ├─→ Comment out line (not delete)
  └─→ Show: "Done. Undo: flow alias undo bcl"
```

### Wireframe: Doctor Output

```
┌─────────────────────────────────────────────────────────────┐
│ 🩺 Alias Health Check                                       │
├─────────────────────────────────────────────────────────────┤
│ Scanning: ~/.config/zsh/.zshrc                              │
│ Found: 27 aliases                                           │
│                                                             │
│ ❌ ERRORS                                                   │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ cat='bat'                                               │ │
│ │   └─ Shadows: /bin/cat                                  │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ ⚠️  WARNINGS                                                │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ nexus='cd ... && npm start'                             │ │
│ │   └─ Long command - consider function                   │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ ✅ HEALTHY: 24 aliases                                      │
│ bi, bci, bl, bcl, bs, bo, bu, bup, bdr, ...                 │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│ Summary: 2 errors, 1 warning, 24 healthy                    │
└─────────────────────────────────────────────────────────────┘
```

### Accessibility Checklist

- [x] Color-coded output (red=error, yellow=warning, green=healthy)
- [x] Text labels alongside colors (❌, ⚠️, ✅)
- [x] Summary line for quick scan
- [x] Suggestions for each issue

---

## Open Questions

1. **Undo feature:** Should `flow alias undo` be implemented to uncomment removed aliases?
2. **Unused detection:** Include shell history analysis in doctor, or separate command?
3. **Category for brew:** Add `brew` category to existing `flow alias` reference?

---

## Review Checklist

- [x] Architecture approved
- [x] API design approved
- [x] Implementation plan approved
- [x] Ready for implementation
- [x] Implementation complete
- [x] Tests written (42 tests)
- [x] Documentation updated

---

## Implementation Notes

### Phase 1: Doctor (~45 min)
- Core validation engine
- Shadow detection using `command -v` and `which`
- Target existence check
- Formatted output with colors

### Phase 2: Find + Edit (~15 min)
- Simple grep wrapper for find
- `$EDITOR +<line>` for edit

### Phase 3: Add (~50 min)
- One-liner parsing: `name='command'` format
- Interactive mode with prompts
- Append to .zshrc with comment header

### Phase 4: Remove (~30 min)
- Find line in .zshrc
- Backup file before modification
- Comment out, don't delete

### Phase 5: Test (~30 min)
- Reuse validation from doctor
- Dry-run using `echo` expansion
- Optional execute with confirmation

### Estimated Total: ~3 hours, ~310 new lines

---

## History

| Date | Change |
|------|--------|
| 2026-01-12 | Initial spec from deep brainstorm |
| 2026-01-12 | Implementation complete - all 6 commands working |
| 2026-01-12 | 42 tests written (test-alias-management.zsh) |
| 2026-01-12 | Documentation complete (reference + workflow guide) |
