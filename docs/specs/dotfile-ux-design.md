# Dotfile Management UX Design for flow-cli

**Date:** 2026-01-08
**Version:** 1.0
**Status:** Design Proposal

---

## Executive Summary

This document proposes UX integration for dotfile management (chezmoi + Bitwarden) into flow-cli. The design follows flow-cli's ADHD-friendly principles: **discoverable, consistent, forgiving, fast**.

**Recommendation:** Use `dot` dispatcher pattern with 3 core actions: edit, sync, status

---

## 1. Command Naming Analysis

### Option A: `dot` (Dotfiles) - RECOMMENDED

**Pros:**
- Short, memorable (2 letters like `cc`, `wt`, `tm`)
- Domain-specific (dotfile = df)
- Available (no conflicts with common commands)
- Follows dispatcher naming pattern

**Cons:**
- Minor conflict with GNU coreutils `dot` (disk free)
  - Mitigation: Users typically use full `/usr/bin/df` or `disk free` alternatives (duf, dust)
  - flow-cli users likely prefer modern alternatives already installed via Brewfile

**Example commands:**
```bash
df              # Status overview (default)
df edit .zshrc  # Edit dotfile
df sync         # Pull latest changes
df push         # Push local changes
df status       # Show sync status
```

### Option B: `dot` (Explicit)

**Pros:**
- Clear, unambiguous
- No conflicts

**Cons:**
- 3 characters (longer than flow-cli convention)
- Less ergonomic for daily use
- Graphviz users might find minor conflict

### Option C: `config` (Generic)

**Pros:**
- Self-documenting

**Cons:**
- 6 characters (too long for ADHD-friendly quick commands)
- Conflicts with many tools (git config, npm config, etc.)
- Too generic (doesn't specify dotfiles vs app configs)

**Decision:** Use `dot` dispatcher

---

## 2. Dispatcher Architecture

### Pattern: `dot <action> [target] [options]`

Following established flow-cli dispatcher patterns (g, mcp, cc, wt):

```zsh
df() {
    case "$1" in
        # Core workflows
        edit|e)     _dot_edit "$@" ;;
        sync|pull)  _dot_sync "$@" ;;
        push|up)    _dot_push "$@" ;;
        apply)      _dot_apply "$@" ;;

        # Status & info
        status|st)  _dot_status "$@" ;;
        diff|d)     _dot_diff "$@" ;;
        list|ls)    _dot_list "$@" ;;

        # Secret management
        secret|sec) _dot_secret "$@" ;;
        unlock)     _dot_unlock "$@" ;;

        # Setup & troubleshooting
        init)       _dot_init "$@" ;;
        doctor)     _dot_doctor "$@" ;;

        # Help
        help|h)     _dot_help ;;

        # Default: status
        "")         _dot_status ;;
        *)          echo "df: unknown action: $1" >&2; return 1 ;;
    esac
}
```

---

## 3. The 3 Most Frequent Operations

Based on dotfile workflow analysis:

### 1. `dot edit <file>` - Quick Edit (60% of daily use)

**Flow:**
```bash
df edit .zshrc
# Opens in chezmoi: chezmoi edit ~/.zshrc
# User makes changes
# Auto-preview on save
# Prompt: Apply changes? [Y/n]
```

**ADHD-friendly features:**
- One command, no mental overhead
- Preview changes before applying
- Smart default (apply = yes)
- Undo available via `dot diff` + `dot apply --force`

**Smart path resolution:**
```bash
df edit .zshrc     → ~/.config/zsh/.zshrc
df edit zshrc      → ~/.config/zsh/.zshrc (fuzzy match)
df edit git        → ~/.gitconfig (intelligent match)
df edit ssh        → ~/.ssh/config
```

### 2. `dot sync` - Pull Latest (25% of daily use)

**Flow:**
```bash
df sync
# Pull from remote → preview changes → apply
# Output:
# ✓ Pulled latest from origin/main
# 📝 Changes to apply:
#    M ~/.zshrc (3 lines changed)
#    M ~/.gitconfig (1 line added)
# Apply now? [Y/n]
```

**Safety features:**
- Shows diff before applying
- Backs up current files
- Rollback available: `dot undo`

### 3. `dot status` - Check Sync State (15% of daily use)

**Flow:**
```bash
df
# OR: df status

# Output:
# 📦 Dotfiles Status
#
# 🟢 Synced (last: 2h ago)
# 📍 Machine: iMac.local
# 🔐 Bitwarden: unlocked
#
# Tracked files: 12
# Modified: 0
# Behind remote: 0 commits
# Secrets: 3 injected
#
# 💡 Next: df sync (to pull latest)
```

**Information hierarchy:**
1. Sync state (most critical)
2. Machine context (helps with multi-device)
3. Security status (peace of mind)
4. File counts (overview)
5. Suggested action (ADHD-friendly next step)

---

## 4. Error Recovery Design

### Problem 1: Bitwarden Session Expired

**UX Flow:**
```bash
$ df edit .zshrc
⚠ Bitwarden session expired
🔓 Unlock now? [Y/n] y
🔑 Enter master password: ********
✓ Unlocked Bitwarden
✓ Opening ~/.zshrc in $EDITOR...
```

**Auto-recovery features:**
- Detects expired session before opening editor
- One-step unlock prompt
- Remembers intended action after unlock
- Falls back to no-secret mode if user declines

**Manual unlock:**
```bash
df unlock
# OR
df secret unlock
```

### Problem 2: Chezmoi Merge Conflicts

**UX Flow:**
```bash
$ df sync
⚠ Merge conflict detected:
   ~/.zshrc (local changes vs remote changes)

Options:
  1) Keep local changes (discard remote)
  2) Keep remote changes (discard local)
  3) Manual merge (open in editor)
  4) Abort (stay in current state)

Choice [1-4]: 3

✓ Opening merge editor...
(After user resolves)
✓ Conflict resolved
Apply merged version? [Y/n]
```

**Safety mechanisms:**
- Always shows both versions before merge
- Backup created automatically
- Undo available: `dot undo`
- Merge help: `dot doctor conflict`

### Problem 3: Secret Injection Failure

**UX Flow:**
```bash
$ df apply
⚠ Secret injection failed: API key not found in Bitwarden
❓ Item name: "Desktop Commander API"

Troubleshoot:
  1) df secret list (see all secrets)
  2) df secret add (add missing secret)
  3) df doctor (diagnose issues)

Proceed without secrets? [y/N] n
✗ Aborted. Fix secrets first.
```

**Graceful degradation:**
- Clear error message with exact item name
- Actionable suggestions
- Option to skip secrets temporarily
- Doctor command for diagnosis

---

## 5. Discoverability

### Help System (Tiered Disclosure)

**Level 1: Quick help (`dot`)**
```bash
$ df
# Shows status + quick actions at bottom

💡 Quick actions:
  df edit .zshrc    Edit config
  df sync           Pull latest
  df push           Push changes
  df help           Full help
```

**Level 2: Full help (`dot help`)**
```bash
$ df help

╭─────────────────────────────────────────────╮
│ df - Dotfile Management                     │
╰─────────────────────────────────────────────╯

🔥 MOST COMMON (80% of daily use):
  df edit .zshrc    Edit and apply config
  df sync           Pull latest changes
  df push           Push local changes
  df                Status overview

💡 QUICK EXAMPLES:
  $ df edit zshrc       # Quick edit
  $ df diff             # Preview changes
  $ df sync             # Pull & apply
  $ df secret list      # Show secrets

📝 CORE WORKFLOWS:
  df edit <file>    Edit dotfile (with preview)
  df apply          Apply pending changes
  df sync           Pull latest from remote
  df push           Push local changes
  df diff           Show pending changes

🔐 SECRET MANAGEMENT:
  df secret list    List all secrets
  df secret add     Add new secret
  df unlock         Unlock Bitwarden
  df secret test    Test secret injection

📋 STATUS & INFO:
  df status         Sync status overview
  df list           List tracked files
  df diff           Show changes
  df doctor         Troubleshoot issues

🛠 SETUP & MAINTENANCE:
  df init           Initialize dotfiles
  df doctor         Health check
  df undo           Undo last apply

🔗 SHORTCUTS:
  e = edit, s = sync, st = status, d = diff
  sec = secret, ls = list, up = push

💡 TIP: Run 'df' without arguments for quick status
```

**Level 3: Command-specific help**
```bash
$ df edit --help
# Detailed help for edit subcommand
```

### Inline Hints

Every command output includes contextual next steps:

```bash
$ df diff
# Shows changes...
💡 Next: df apply (to apply changes)
       df edit <file> (to modify)
```

### Integration with `dash`

Add dotfile status to dashboard:

```bash
$ dash

📊 Flow Dashboard
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📍 Right Now
  MacBook Pro • 2026-01-08 14:30
  Session: flow-cli (2h 15m)

🎯 Current Project: flow-cli
  Status: ACTIVE
  Next: Add dotfile dispatcher

📦 Dotfiles: 🟢 Synced (2h ago)        # NEW!
  3 secrets active • 0 pending changes
  💡 df sync to update

...
```

### Integration with `work`

Trigger dotfile check when starting work:

```bash
$ work flow-cli
✓ Starting session: flow-cli
📦 Checking dotfiles...
  ⚠ Behind remote by 2 commits
  💡 Run 'df sync' to update? [Y/n] n
  Skipped. You can sync later with 'df sync'.

✓ Session started
```

**Configuration (opt-out):**
```bash
# In .zshrc or flow-cli config
export FLOW_DF_CHECK_ON_WORK=0  # Disable auto-check
```

---

## 6. Command Reference Table

| Command | Action | Frequency | ADHD Score |
|---------|--------|-----------|------------|
| `dot` | Show status | Daily | 10/10 (zero typing) |
| `dot edit <file>` | Edit config | Daily | 9/10 (1 command) |
| `dot sync` | Pull & apply | Daily | 9/10 (safe default) |
| `dot push` | Push changes | 2-3x/week | 8/10 (explicit) |
| `dot diff` | Preview changes | As needed | 9/10 (visual feedback) |
| `dot apply` | Apply changes | Automatic | 8/10 (explicit when needed) |
| `dot secret list` | List secrets | Weekly | 7/10 (clear name) |
| `dot unlock` | Unlock vault | Daily (first use) | 8/10 (auto-prompted) |
| `dot doctor` | Troubleshoot | Rare | 9/10 (guided) |
| `dot init` | First-time setup | Once | 7/10 (interactive) |

---

## 7. Visual Design (Terminal UI)

### Color Scheme (ADHD-Friendly)

```bash
# Status indicators
🟢 Synced     → Green (#72B372)
🟡 Modified   → Yellow (#DDB05E)
🔴 Conflict   → Soft Red (#CB6B7B)
🔵 Info       → Calm Blue (#75B0E3)

# Icons (consistent with flow-cli)
📦 Dotfiles   ✓ Success   ⚠ Warning   ✗ Error
🔐 Secrets    📝 File     🔄 Sync     💡 Tip
```

### Layout Pattern

```bash
[HEADER]      Bold, colored header
━━━━━━━━━━    Separator line

[CONTENT]     Hierarchical information
              • Bullets for lists
              → Arrows for actions

[FOOTER]      💡 Next step suggestions
              🔗 Related commands
```

### Example: `dot status` output

```bash
📦 Dotfiles Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🟢 Synced with remote
   Last sync: 2 hours ago
   Machine: iMac.local

🔐 Secrets
   ✓ Bitwarden unlocked
   ✓ 3 secrets injected

📝 Tracked Files (12)
   ✓ ~/.config/zsh/.zshrc
   ✓ ~/.gitconfig
   ✓ ~/.ssh/config
   ✓ Brewfile
   ... (8 more)

📊 Repository
   ✓ Up to date with origin/main
   • 0 files modified locally
   • 0 commits behind remote

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 Next: df edit .zshrc (to modify config)
       df sync (to pull latest changes)

🔗 See also: df list (all files)
            df doctor (troubleshoot)
```

---

## 8. Smart Defaults & Forgiveness

### Smart Path Resolution

```bash
df edit zshrc       # → ~/.config/zsh/.zshrc
df edit .zshrc      # → ~/.config/zsh/.zshrc
df edit git         # → ~/.gitconfig
df edit gitconfig   # → ~/.gitconfig
df edit ssh         # → ~/.ssh/config
```

**Fuzzy matching logic:**
1. Exact match in tracked files
2. Basename match (e.g., "zshrc" → ".zshrc")
3. Substring match (e.g., "git" → ".gitconfig")
4. If multiple matches: show picker

### Safe Defaults

- `dot sync` → Preview before applying (default: yes)
- `dot push` → Show diff before pushing (default: yes)
- `dot edit` → Preview changes after save (default: apply)
- `dot apply` → Create backup before applying

### Undo Support

```bash
df undo             # Undo last apply
df undo --list      # Show undo history (last 10)
df undo 3           # Undo to 3 commits ago
```

**Implementation:** Leverage chezmoi's backup system

### Dry Run Mode

```bash
df sync --dry-run   # Preview without applying
df push -n          # Preview without pushing
df apply --dry      # Show what would change
```

---

## 9. Testing & Validation Plan

### Phase 1: Core Dispatcher (Week 1)

**Test scenarios:**
- [ ] `dot` shows status
- [ ] `dot help` displays help
- [ ] `dot edit .zshrc` opens editor
- [ ] `dot diff` shows changes
- [ ] `dot apply` applies changes

**Success metric:** Basic edit → preview → apply workflow works

### Phase 2: Sync Workflow (Week 2)

**Test scenarios:**
- [ ] `dot sync` pulls and applies
- [ ] Conflict detection works
- [ ] Backup/restore works
- [ ] Multi-machine sync (iMac ↔ MacBook)

**Success metric:** Can sync configs between two machines

### Phase 3: Secret Management (Week 3)

**Test scenarios:**
- [ ] `dot unlock` prompts for password
- [ ] Secret injection works in templates
- [ ] `dot secret list` shows secrets
- [ ] Graceful degradation when BW locked

**Success metric:** Secrets injected correctly on both machines

### Phase 4: Integration (Week 4)

**Test scenarios:**
- [ ] `dash` shows dotfile status
- [ ] `work` checks dotfile sync
- [ ] `flow doctor` includes dotfile health
- [ ] Error messages are actionable

**Success metric:** Dotfiles feel like native flow-cli feature

---

## 10. Implementation Roadmap

### Files to Create

```
flow-cli/
├── lib/
│   └── dispatchers/
│       └── dot-dispatcher.zsh          # Main dispatcher
├── lib/
│   └── dotfile-helpers.zsh            # Helper functions
├── completions/
│   └── _dot                            # ZSH completion
├── docs/
│   └── reference/
│       └── DOT-DISPATCHER-REFERENCE.md # Full documentation
└── tests/
    └── dot-dispatcher.test.zsh         # Test suite
```

### Development Phases

**Phase 1: Foundation (4 hours)**
- [ ] Create dot-dispatcher.zsh skeleton
- [ ] Implement `dot status`
- [ ] Implement `dot help`
- [ ] Add to flow.plugin.zsh

**Phase 2: Core Workflows (8 hours)**
- [ ] Implement `dot edit`
- [ ] Implement `dot sync`
- [ ] Implement `dot push`
- [ ] Implement `dot diff`
- [ ] Implement `dot apply`

**Phase 3: Secret Management (6 hours)**
- [ ] Implement `dot unlock`
- [ ] Implement `dot secret list`
- [ ] Implement `dot secret add`
- [ ] Handle session expiration

**Phase 4: Integration (4 hours)**
- [ ] Add to `dash` command
- [ ] Add to `work` command
- [ ] Add to `flow doctor`
- [ ] Update documentation

**Phase 5: Polish (4 hours)**
- [ ] Add ZSH completions
- [ ] Write tests
- [ ] Update DISPATCHER-REFERENCE.md
- [ ] Create tutorial in docs/

**Total estimated time:** 26 hours (3-4 weeks at 6-8 hours/week)

---

## 11. Future Enhancements (Post-MVP)

### Version Management Integration

```bash
df version status              # Show R/Python versions across machines
df version sync                # Sync mise configurations
df version set R@4.5.2         # Set R version for project
```

### Package Sync

```bash
df pkg status                  # Compare Homebrew packages
df pkg sync                    # Install missing packages
df pkg export                  # Update Brewfile
```

### Template Picker

```bash
df template                    # Interactive template editor
df template add-machine        # Add machine-specific config
df template test               # Preview template rendering
```

### Automated Sync

```bash
df watch                       # Auto-sync on file changes
df schedule hourly             # Scheduled sync (via launchd)
```

---

## 12. Alternatives Considered

### Option: Integrate into `flow` command

```bash
flow dotfile edit
flow dotfile sync
```

**Rejected because:**
- `flow` command is meta-level (flow test, flow build, flow doctor)
- Dotfiles are domain-specific (like git, mcp, obs)
- Dispatcher pattern is more discoverable

### Option: Separate `chezmoi` wrapper

```bash
cm edit .zshrc
cm sync
```

**Rejected because:**
- Not integrated with flow-cli ecosystem
- Another command to remember
- Loses dash/work integration

### Option: No integration, use chezmoi directly

**Rejected because:**
- Chezmoi UX is not ADHD-optimized
- No integration with flow-cli workflows
- More cognitive load for users

---

## 13. Open Questions for User Feedback

1. **Command naming:** `dot` vs `dot` vs `dotfiles`?
2. **Default behavior:** Should `dot sync` auto-apply or prompt?
3. **Integration intensity:** Show dotfile status in every `dash` call, or only when out-of-sync?
4. **Secret prompts:** Auto-unlock Bitwarden on first command, or explicit `dot unlock`?
5. **Backup retention:** Keep last 10 backups, or configurable?

---

## 14. Success Metrics

**Adoption (Week 4):**
- [ ] User runs `dot` at least once per day
- [ ] Zero manual `chezmoi` commands needed
- [ ] Secrets successfully injected on both machines

**ADHD-Friendliness (Week 8):**
- [ ] Average command length ≤ 3 words
- [ ] Error messages actionable in ≤ 1 step
- [ ] Status check completes in < 1 second

**Reliability (Week 12):**
- [ ] Zero sync conflicts (auto-resolved)
- [ ] Zero secret injection failures
- [ ] 100% uptime on both machines

---

## Appendix: Command Cheat Sheet

### Daily Workflows

```bash
# Morning: Sync configs
df sync

# Work: Edit config
df edit .zshrc

# Preview before applying
df diff

# Explicit apply
df apply

# Evening: Push changes
df push

# Check status anytime
df
```

### Troubleshooting

```bash
# Full health check
df doctor

# Unlock secrets
df unlock

# Show all secrets
df secret list

# Undo last change
df undo

# Show sync status
df status -v
```

### One-Time Setup

```bash
# Initialize (first time)
df init

# Add new dotfile
df add ~/.tmux.conf

# Add new secret
df secret add "API Key"
```

---

**Document Status:** Ready for Implementation
**Next Step:** Create dot-dispatcher.zsh skeleton
**Feedback Requested:** Command naming (`dot` vs alternatives)
