# DOT Dispatcher Quick Reference

**Command:** `dot` (Dotfiles)
**Pattern:** `dot <action> [target] [options]`
**Philosophy:** Fast, forgiving, discoverable

---

## Command Comparison Matrix

| Action | git (`g`) | MCP (`mcp`) | Dotfiles (`dot`) |
|--------|-----------|-------------|-----------------|
| **Default** | `g` → status | `mcp` → list | `dot` → status |
| **Edit** | `g commit` | `mcp edit` | `dot edit .zshrc` |
| **Sync** | `g pull` | - | `dot sync` |
| **Push** | `g push` | - | `dot push` |
| **Status** | `g status` | `mcp status` | `dot status` |
| **List** | `g log` | `mcp list` | `dot list` |
| **Diff** | `g diff` | - | `dot diff` |
| **Test** | - | `mcp test` | `dot doctor` |
| **Help** | `g help` | `mcp help` | `dot help` |

---

## Visual Command Tree

```
df
├── (no args)     → Status overview + quick actions
│
├── edit <file>   → Edit dotfile (preview + apply)
│   ├── .zshrc
│   ├── .gitconfig
│   ├── .ssh/config
│   └── Brewfile
│
├── sync          → Pull latest from remote
│   ├── (preview changes)
│   └── (prompt to apply)
│
├── push          → Push local changes
│   ├── (show diff)
│   └── (confirm before push)
│
├── diff          → Show pending changes
│
├── apply         → Apply pending changes
│   └── (with backup)
│
├── status        → Full sync status
│   ├── --verbose  (-v)
│   └── --json
│
├── list          → List tracked files
│   ├── --all      (-a)
│   └── --modified (-m)
│
├── secret        → Secret management
│   ├── list       (show all secrets)
│   ├── add        (add new secret)
│   ├── test       (test injection)
│   └── unlock     (unlock vault)
│
├── unlock        → Unlock Bitwarden
│
├── doctor        → Health check + troubleshoot
│   ├── (check chezmoi)
│   ├── (check bitwarden)
│   ├── (check git remote)
│   └── (suggest fixes)
│
├── undo          → Undo last apply
│   ├── --list     (show history)
│   └── <n>        (undo to commit n)
│
├── init          → Initialize dotfiles
│   ├── --from <url>
│   └── --setup-secrets
│
└── help          → Show full help
```

---

## Usage Frequency Map

```
DAILY (80% of usage)
┌─────────────────────────────────────────┐
│ df                    (quick status)    │  ████████████ 40%
│ df edit .zshrc        (edit config)     │  ██████████   30%
│ df sync               (pull changes)    │  ██████       20%
│ df push               (push changes)    │  ████         10%
└─────────────────────────────────────────┘

WEEKLY (15% of usage)
┌─────────────────────────────────────────┐
│ df diff               (preview changes) │  ████          8%
│ df secret list        (check secrets)   │  ██            4%
│ df unlock             (unlock vault)    │  ██            3%
└─────────────────────────────────────────┘

RARE (5% of usage)
┌─────────────────────────────────────────┐
│ df doctor             (troubleshoot)    │  ██            3%
│ df undo               (rollback)        │  █             1%
│ df init               (first-time)      │  █             1%
└─────────────────────────────────────────┘
```

---

## State Diagram

```
┌─────────────┐
│   SYNCED    │  🟢 All good
└──────┬──────┘
       │
       ├─── df edit .zshrc ──→ MODIFIED (local changes)
       │                           │
       │                           ├─→ df diff (preview)
       │                           │
       │                           └─→ df push ──→ SYNCED
       │
       ├─── df sync ──────────→ BEHIND (remote ahead)
       │                           │
       │                           ├─→ df diff (preview)
       │                           │
       │                           └─→ df apply ──→ SYNCED
       │
       └─── (remote changes) ──→ CONFLICT
                                   │
                                   ├─→ df doctor (resolve)
                                   │
                                   └─→ df apply --force ──→ SYNCED
```

---

## Smart Path Resolution

```bash
# User types     → Resolves to
df edit zshrc    → ~/.config/zsh/.zshrc
df edit .zshrc   → ~/.config/zsh/.zshrc
df edit git      → ~/.gitconfig
df edit gitconfig → ~/.gitconfig
df edit ssh      → ~/.ssh/config
df edit brew     → ~/.local/share/chezmoi/Brewfile

# Fuzzy match logic:
# 1. Exact match in tracked files
# 2. Basename match (.zshrc)
# 3. Substring match (git → gitconfig)
# 4. Multiple matches → fzf picker
```

---

## Error Recovery Flowchart

```
┌───────────────────┐
│  Run df command   │
└────────┬──────────┘
         │
         ├─→ [Bitwarden locked?]
         │   └─→ YES: Prompt unlock → Continue
         │   └─→ NO: Continue
         │
         ├─→ [Chezmoi not installed?]
         │   └─→ YES: df doctor → Install
         │
         ├─→ [Git conflict?]
         │   └─→ YES: df doctor → Resolve
         │
         ├─→ [Secret missing?]
         │   └─→ YES: df secret add → Retry
         │
         └─→ [Success]
```

---

## Color Coding (ADHD-Friendly)

```
Status Indicators:
🟢 Synced            → #72B372 (Soft Green)
🟡 Modified          → #DDB05E (Warm Yellow)
🔴 Conflict          → #CB6B7B (Soft Red)
🔵 Behind Remote     → #75B0E3 (Calm Blue)
⚫ Not Initialized   → #787878 (Gray)

Action Colors:
📝 Edit              → Blue
🔄 Sync              → Cyan
📤 Push              → Green
🔐 Secret            → Purple
⚠ Warning            → Yellow
✗ Error              → Red
✓ Success            → Green
```

---

## Integration Points

### Dashboard Integration

```bash
$ dash

📊 Flow Dashboard
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📍 Right Now
  MacBook Pro • 2026-01-08 14:30

🎯 Current Project: flow-cli

📦 Dotfiles: 🟢 Synced (2h ago)        ← NEW!
  3 secrets active • 0 pending changes
  💡 df sync to update
```

### Work Command Integration

```bash
$ work my-project
✓ Starting session: my-project
📦 Checking dotfiles...               ← NEW!
  ⚠ Behind remote by 2 commits
  💡 Run 'df sync' to update? [Y/n]
```

### Flow Doctor Integration

```bash
$ flow doctor
[...existing checks...]

📦 Dotfiles:
  ✓ chezmoi installed
  ✓ bitwarden-cli installed
  ✓ Repository connected
  ✓ Secrets configured
  ✓ Synced with remote
```

---

## Keyboard Shortcuts (via ZSH completion)

```bash
df <TAB>        → Show all actions
df e<TAB>       → Complete to 'edit'
df s<TAB>       → Ambiguous: sync, status, secret
df edit <TAB>   → List tracked files
df se<TAB>      → Complete to 'secret'
df sec <TAB>    → Show: list, add, test, unlock
```

---

## Comparison: flow-cli vs Raw Chezmoi

| Task | Raw Chezmoi | flow-cli (`dot`) | ADHD Score |
|------|-------------|-----------------|------------|
| Edit config | `chezmoi edit ~/.zshrc` | `dot edit zshrc` | 9/10 (shorter) |
| Preview changes | `chezmoi diff` | `dot diff` | 9/10 (same) |
| Apply changes | `chezmoi apply` | `dot apply` | 9/10 (same) |
| Sync from remote | `chezmoi update` | `dot sync` | 10/10 (clearer name) |
| Push to remote | `cd ~/.local/share/chezmoi && git push` | `dot push` | 10/10 (one command!) |
| Check status | `chezmoi status` + `git status` | `dot` | 10/10 (unified) |
| Unlock secrets | `export BW_SESSION=$(bw unlock --raw)` | `dot unlock` | 10/10 (much simpler) |
| List secrets | `bw list items --search ...` | `dot secret list` | 10/10 (intuitive) |
| Add secret | `bw create item ...` (complex JSON) | `dot secret add` | 10/10 (guided) |
| Troubleshoot | (manual debugging) | `dot doctor` | 10/10 (automated) |

**Average improvement:** 9.7/10

---

## Aliases (Optional)

```bash
# Already matches dispatcher pattern, so minimal aliases needed:

alias dfe='df edit'        # df edit .zshrc
alias dfs='df sync'        # df sync
alias dfp='df push'        # df push
alias dfd='df diff'        # df diff
alias dfst='df status'     # df status

# Most users will just use: df edit, df sync, df push
```

---

## Help Output Preview

```bash
$ df help

╭─────────────────────────────────────────────╮
│ df - Dotfile Management                     │
╰─────────────────────────────────────────────╯

🔥 MOST COMMON (80% of daily use):
  df                Show status overview
  df edit .zshrc    Edit and apply config
  df sync           Pull latest changes
  df push           Push local changes

💡 QUICK EXAMPLES:
  $ df                  # Quick status
  $ df edit zshrc       # Edit config
  $ df diff             # Preview changes
  $ df sync             # Pull & apply
  $ df push             # Push to remote

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
  df                Status overview (default)
  df status         Full sync status
  df list           List tracked files
  df diff           Show changes

🛠 SETUP & MAINTENANCE:
  df init           Initialize dotfiles
  df doctor         Health check
  df undo           Undo last apply

🔗 SHORTCUTS:
  e = edit, s = sync, st = status, d = diff
  sec = secret, ls = list, up = push

💡 TIP: Run 'df' for quick status check
       All changes are backed up (use 'df undo')

📚 See also: dash (shows dotfile status)
            work (checks for updates)
            flow doctor (includes dotfile check)
```

---

## Decision Tree: Which Command?

```
Need to...
│
├─ Check if configs are synced?
│  └─→ df (or df status)
│
├─ Edit a config file?
│  └─→ df edit .zshrc
│
├─ Pull latest changes from other machine?
│  └─→ df sync
│
├─ Push local changes to remote?
│  └─→ df push
│
├─ See what changed?
│  └─→ df diff
│
├─ Manage API keys/secrets?
│  └─→ df secret list
│  └─→ df secret add
│
├─ Fix sync issues?
│  └─→ df doctor
│
├─ Undo recent changes?
│  └─→ df undo
│
└─ First-time setup?
   └─→ df init
```

---

## Mental Model

```
Dotfiles = Git for Configs + Secrets
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Git Concepts         Dotfile Equivalent
────────────        ────────────────────
git pull            → df sync
git push            → df push
git status          → df status
git diff            → df diff
git log             → df list
git commit          → (automatic on df push)
git checkout --     → df undo

Plus:
🔐 Secret injection (Bitwarden)
📝 Template rendering (machine-specific)
🔄 Auto-backup before changes
```

---

## Performance Targets (ADHD-Optimized)

```
Command             Target Time    Actual (Expected)
───────────────────────────────────────────────────
df                  < 0.5s         0.3s  ✓
df edit .zshrc      < 1.0s         0.8s  ✓
df sync             < 3.0s         2.5s  ✓
df push             < 2.0s         1.8s  ✓
df diff             < 0.5s         0.4s  ✓
df status           < 0.5s         0.3s  ✓
df secret list      < 1.0s         0.9s  ✓
df unlock           < 2.0s         1.5s  ✓ (depends on user input)
df doctor           < 2.0s         1.7s  ✓

All commands must complete in < 3s for ADHD-friendliness
```

---

## Testing Checklist

### Unit Tests
- [ ] `dot` shows status
- [ ] `dot help` displays help
- [ ] `dot edit` opens correct file
- [ ] `dot diff` shows changes
- [ ] `dot sync` pulls changes
- [ ] `dot push` pushes changes
- [ ] `dot unlock` prompts for password
- [ ] `dot secret list` shows secrets

### Integration Tests
- [ ] Edit → diff → apply workflow
- [ ] Sync → conflict → resolve workflow
- [ ] Secret injection in templates
- [ ] Multi-machine sync (iMac ↔ MacBook)
- [ ] Dashboard shows dotfile status
- [ ] Work command checks dotfiles
- [ ] Flow doctor includes dotfiles

### Error Handling
- [ ] Graceful handling when chezmoi not installed
- [ ] Graceful handling when BW locked
- [ ] Graceful handling when git conflict
- [ ] Graceful handling when secret missing
- [ ] Actionable error messages

---

**Status:** Design Complete
**Next:** Implement dot-dispatcher.zsh skeleton
**Files:** See dotfile-ux-design.md for full implementation plan
