# DF Dispatcher Implementation Checklist

**Version:** 1.0
**Status:** Ready for Development
**Estimated Time:** 26 hours (3-4 weeks)

---

## Pre-Implementation

### Design Review

- [x] UX design document complete (`dotfile-ux-design.md`)
- [x] Visual mockups complete (`dot-dispatcher-visual-mockups.md`)
- [x] Quick reference card (`dot-dispatcher-refcard.md`)
- [x] Executive summary (`DOTFILE-INTEGRATION-SUMMARY.md`)
- [ ] User approval on command name (`dot` vs alternatives)
- [ ] User approval on auto-apply behavior
- [ ] User approval on dashboard integration intensity

### Environment Setup

- [ ] Chezmoi installed on both machines (iMac + MacBook)
- [ ] Bitwarden CLI installed on both machines
- [ ] Test dotfiles repository created (private GitHub repo)
- [ ] Flow-cli dev environment ready

---

## Phase 1: Foundation (Week 1 - 4 hours)

### File Creation

- [ ] Create `lib/dispatchers/dot-dispatcher.zsh`
- [ ] Create `lib/dotfile-helpers.zsh`
- [ ] Add loader to `flow.plugin.zsh`

### Basic Structure

```bash
# In dot-dispatcher.zsh
df() {
    case "$1" in
        status|st|"") _dot_status "$@" ;;
        help|h) _dot_help ;;
        *) echo "df: unknown action: $1" >&2; return 1 ;;
    esac
}

_dot_status() {
    # TODO: Implement
}

_dot_help() {
    # TODO: Implement
}
```

### Checklist

- [ ] `dot` command loads without errors
- [ ] `dot help` displays help text (from mockup)
- [ ] `dot status` shows basic status
- [ ] Help text matches visual mockup
- [ ] Color scheme matches ADHD-friendly palette
- [ ] Committed to git: `feat(df): add basic dispatcher skeleton`

---

## Phase 2: Core Workflows (Week 1-2 - 8 hours)

### Edit Command

- [ ] Implement `_dot_edit()`
- [ ] Smart path resolution (fuzzy matching)
- [ ] Multiple match handling (fzf picker)
- [ ] Editor integration ($EDITOR)
- [ ] Auto-preview after save
- [ ] Apply prompt with confirmation
- [ ] Backup creation before apply
- [ ] Success/error messages
- [ ] Test: `dot edit .zshrc` → edit → preview → apply

### Sync Command

- [ ] Implement `_dot_sync()`
- [ ] Pull from remote (chezmoi update)
- [ ] Show diff before applying
- [ ] Apply confirmation prompt
- [ ] Backup before overwrite
- [ ] Conflict detection
- [ ] Success message with source info
- [ ] Test: `dot sync` on MacBook after iMac changes

### Push Command

- [ ] Implement `_dot_push()`
- [ ] Show local changes (diff)
- [ ] Auto-generate commit message
- [ ] Confirmation prompt
- [ ] Git push to remote
- [ ] Success message
- [ ] Test: `dot push` after local edits

### Diff Command

- [ ] Implement `_dot_diff()`
- [ ] Show modified files
- [ ] Color-coded diff output (red/green)
- [ ] Summary line (files/additions/deletions)
- [ ] Next action suggestions
- [ ] Test: `dot diff` shows pending changes

### Apply Command

- [ ] Implement `_dot_apply()`
- [ ] Show what will be applied
- [ ] Backup creation
- [ ] Apply changes (chezmoi apply)
- [ ] Success confirmation
- [ ] Test: `dot apply` applies pending changes

### Phase 2 Testing

- [ ] Edit workflow: edit → preview → apply → push
- [ ] Sync workflow: sync → preview → apply
- [ ] Error handling: editor fails, backup fails
- [ ] Color output matches mockups
- [ ] Performance: all commands < 3 seconds
- [ ] Committed: `feat(df): add core workflows`

---

## Phase 3: Secret Management (Week 2-3 - 6 hours)

### Bitwarden Integration

- [ ] Implement `_dot_unlock()`
- [ ] Session detection (bw status)
- [ ] Auto-prompt on locked session
- [ ] Password prompt (masked input)
- [ ] Session expiry display
- [ ] Test: `dot unlock` unlocks vault

### Secret Commands

- [ ] Implement `_dot_secret_list()`
- [ ] Show all secrets from vault
- [ ] Show where secrets are used
- [ ] Injection status (✓ or ✗)
- [ ] Test: `dot secret list` displays secrets

- [ ] Implement `_dot_secret_add()`
- [ ] Interactive prompts (name, value, location)
- [ ] Create Bitwarden item
- [ ] Add to template (.zshrc.tmpl)
- [ ] Validation before save
- [ ] Test: `dot secret add` adds new secret

- [ ] Implement `_dot_secret_test()`
- [ ] Test secret injection
- [ ] Show injected values (masked)
- [ ] Detect missing secrets
- [ ] Test: `dot secret test` validates injection

### Auto-Recovery

- [ ] Detect expired session on any `dot` command
- [ ] Prompt to unlock before continuing
- [ ] Resume original command after unlock
- [ ] Graceful degradation if user declines
- [ ] Test: `dot edit .zshrc` when BW locked → auto-unlock

### Phase 3 Testing

- [ ] Unlock workflow: expired → prompt → unlock → continue
- [ ] Secret list shows all secrets
- [ ] Secret add creates vault item + updates template
- [ ] Secret test validates injection
- [ ] Template rendering works with secrets
- [ ] Committed: `feat(df): add secret management`

---

## Phase 4: Status & Info Commands (Week 3 - 3 hours)

### Status Command (Enhanced)

- [ ] Show sync state (🟢/🟡/🔴/🔵)
- [ ] Machine identification
- [ ] Last sync time
- [ ] Bitwarden status
- [ ] Secret injection count
- [ ] Modified file count
- [ ] Remote commit count (behind/ahead)
- [ ] Quick action hints at bottom
- [ ] Test: `dot` matches visual mockup

### List Command

- [ ] Implement `_dot_list()`
- [ ] Show all tracked files
- [ ] Group by category (shell, git, ssh, etc.)
- [ ] Modified indicator
- [ ] Total file count
- [ ] Actionable hints
- [ ] Test: `dot list` shows all dotfiles

### Phase 4 Testing

- [ ] Status output matches Mockup 1-4
- [ ] List output matches Mockup 12
- [ ] All state transitions correct (synced → modified → behind)
- [ ] Committed: `feat(df): enhance status and list commands`

---

## Phase 5: Troubleshooting (Week 3 - 3 hours)

### Doctor Command

- [ ] Implement `_dot_doctor()`
- [ ] Check chezmoi installed
- [ ] Check bitwarden-cli installed
- [ ] Check git installed
- [ ] Check chezmoi initialized
- [ ] Check git remote accessible
- [ ] Check Bitwarden vault accessible
- [ ] Check secret configuration
- [ ] Check templates valid
- [ ] Check file conflicts
- [ ] Check sync status
- [ ] Auto-fix option (`dot doctor --fix`)
- [ ] Test: `dot doctor` runs all checks

### Undo Command

- [ ] Implement `_dot_undo()`
- [ ] Show last change
- [ ] Restore from backup
- [ ] Confirmation prompt
- [ ] Support undo history (`--list`)
- [ ] Support undo to specific commit
- [ ] Test: `dot undo` restores previous state

### Init Command

- [ ] Implement `_dot_init()`
- [ ] Interactive setup wizard
- [ ] Clone from remote repo option
- [ ] Initialize new repo option
- [ ] Bitwarden setup
- [ ] Test dotfile tracking
- [ ] Success confirmation
- [ ] Test: `dot init` on fresh machine

### Phase 5 Testing

- [ ] Doctor detects all issues
- [ ] Doctor output matches Mockup 16-17
- [ ] Undo restores backups correctly
- [ ] Init wizard guides first-time setup
- [ ] Committed: `feat(df): add troubleshooting commands`

---

## Phase 6: Error Handling (Week 3-4 - 2 hours)

### Error Cases

- [ ] Chezmoi not installed → suggest install
- [ ] Bitwarden locked → auto-prompt unlock
- [ ] Git conflict → show resolution options
- [ ] Secret missing → suggest `dot secret add`
- [ ] Network error → show retry option
- [ ] File conflict → guided merge
- [ ] Template error → show syntax issue
- [ ] Remote unreachable → offline mode

### Error Messages

- [ ] Every error shows:
  - What went wrong (clear message)
  - Why it matters (context)
  - How to fix (command)
- [ ] All errors match visual mockups
- [ ] No raw error dumps (parse and humanize)
- [ ] Test all error paths

### Phase 6 Testing

- [ ] All error scenarios tested
- [ ] Error messages actionable
- [ ] Auto-recovery works
- [ ] No crashes on edge cases
- [ ] Committed: `feat(df): robust error handling`

---

## Phase 7: Integration (Week 4 - 4 hours)

### Dashboard Integration

- [ ] Add `_dash_dotfiles()` function to `commands/dash.zsh`
- [ ] Show one-line status in dashboard
- [ ] Status icon (🟢/🟡/🔴)
- [ ] Key metrics (secrets, modified files)
- [ ] Next action hint
- [ ] Only show when out-of-sync (optional)
- [ ] Test: `dash` shows dotfile status (Mockup 20)

### Work Command Integration

- [ ] Add dotfile check to `commands/work.zsh`
- [ ] Check for remote updates on `work` start
- [ ] Prompt to sync if behind
- [ ] Option to skip
- [ ] Opt-out flag: `FLOW_DF_CHECK_ON_WORK=0`
- [ ] Test: `work flow-cli` checks dotfiles (Mockup 21)

### Flow Doctor Integration

- [ ] Add `_flow_doctor_dotfiles()` to `commands/doctor.zsh`
- [ ] Include in `flow doctor` checks
- [ ] Show status in health report
- [ ] Test: `flow doctor` includes dotfiles

### Phase 7 Testing

- [ ] Dashboard integration works
- [ ] Work command integration works
- [ ] Flow doctor integration works
- [ ] All integrations non-intrusive
- [ ] Committed: `feat(df): integrate with dash, work, doctor`

---

## Phase 8: Completions (Week 4 - 2 hours)

### ZSH Completions

- [ ] Create `completions/_dot`
- [ ] Complete subcommands (edit, sync, push, etc.)
- [ ] Complete file paths for `dot edit`
- [ ] Complete secret names for `dot secret`
- [ ] Complete options (--help, --dry-run, etc.)
- [ ] Test: `dot <TAB>` shows completions
- [ ] Test: `dot edit <TAB>` shows tracked files

### Completion Features

- [ ] Fuzzy matching for file paths
- [ ] Description text for each completion
- [ ] Context-aware completions
- [ ] Fast (< 100ms)
- [ ] Committed: `feat(df): add ZSH completions`

---

## Phase 9: Documentation (Week 4 - 3 hours)

### Reference Documentation

- [ ] Create `docs/reference/DOT-DISPATCHER-REFERENCE.md`
- [ ] Include all commands
- [ ] Include examples
- [ ] Include screenshots (or mockups)
- [ ] Include troubleshooting section
- [ ] Update `DISPATCHER-REFERENCE.md` to include `dot`

### Tutorial

- [ ] Create `docs/tutorials/dotfile-setup.md`
- [ ] First-time setup guide
- [ ] Daily workflow examples
- [ ] Multi-machine setup
- [ ] Secret management guide
- [ ] Common troubleshooting

### Updates to Existing Docs

- [ ] Update `README.md` to mention `dot` dispatcher
- [ ] Update `CLAUDE.md` to include dotfile management
- [ ] Update `COMMAND-QUICK-REFERENCE.md`
- [ ] Update `WORKFLOW-QUICK-REFERENCE.md`
- [ ] Update `mkdocs.yml` navigation

### Committed

- [ ] `docs: add dotfile management documentation`

---

## Phase 10: Testing (Week 4 - 2 hours)

### Unit Tests

- [ ] Create `tests/dot-dispatcher.test.zsh`
- [ ] Test: `dot` shows status
- [ ] Test: `dot help` shows help
- [ ] Test: `dot edit` smart path resolution
- [ ] Test: `dot sync` pulls changes
- [ ] Test: `dot push` pushes changes
- [ ] Test: `dot diff` shows changes
- [ ] Test: `dot secret list` shows secrets
- [ ] Test: `dot unlock` unlocks vault
- [ ] Test: `dot doctor` runs checks
- [ ] Test: `dot undo` restores backup

### Integration Tests

- [ ] Test: Edit workflow (edit → diff → apply → push)
- [ ] Test: Sync workflow (sync → apply)
- [ ] Test: Secret workflow (add → test → inject)
- [ ] Test: Multi-machine sync (iMac ↔ MacBook)
- [ ] Test: Conflict resolution
- [ ] Test: Dashboard integration
- [ ] Test: Work integration
- [ ] Test: Doctor integration

### Error Handling Tests

- [ ] Test: Chezmoi not installed
- [ ] Test: Bitwarden locked
- [ ] Test: Git conflict
- [ ] Test: Secret missing
- [ ] Test: Network error
- [ ] Test: File conflict
- [ ] Test: Invalid input

### Performance Tests

- [ ] Test: `dot` completes in < 0.5s
- [ ] Test: `dot edit` completes in < 1s
- [ ] Test: `dot sync` completes in < 3s
- [ ] Test: `dot push` completes in < 2s
- [ ] Test: All commands < 3s

### Committed

- [ ] `test: add comprehensive df dispatcher tests`

---

## Phase 11: Polish (Week 4 - 2 hours)

### Code Review

- [ ] Clean up debug statements
- [ ] Consistent error handling
- [ ] Consistent color scheme
- [ ] Consistent naming conventions
- [ ] Remove TODOs
- [ ] Add inline comments for complex logic

### Performance Optimization

- [ ] Profile slow commands
- [ ] Cache repeated operations
- [ ] Minimize external command calls
- [ ] Optimize chezmoi queries

### UX Polish

- [ ] Verify all output matches mockups
- [ ] Verify color scheme consistency
- [ ] Verify icon usage consistency
- [ ] Test on different terminal widths
- [ ] Test with different color schemes

### Committed

- [ ] `refactor: polish df dispatcher for release`

---

## Phase 12: Release (Week 4)

### Pre-Release Checklist

- [ ] All tests passing
- [ ] Documentation complete
- [ ] Code reviewed
- [ ] No TODOs remaining
- [ ] No known bugs
- [ ] Performance targets met
- [ ] Mockups match reality

### Version Bump

- [ ] Update version in `package.json`
- [ ] Update version in `README.md`
- [ ] Update version in `CLAUDE.md`
- [ ] Update version in docs

### Release Notes

- [ ] Create `CHANGELOG.md` entry for v5.0.0
- [ ] List new features
- [ ] List breaking changes (if any)
- [ ] Include examples
- [ ] Include migration guide (if needed)

### Git

- [ ] Commit: `chore: bump version to 5.0.0`
- [ ] Tag: `git tag -a v5.0.0 -m "Add df (dotfile) dispatcher"`
- [ ] Push: `git push origin main --tags`

### Documentation

- [ ] Deploy docs: `mkdocs gh-deploy --force`
- [ ] Verify docs site: https://Data-Wise.github.io/flow-cli/

### Announcement

- [ ] Update project README
- [ ] Share in relevant channels
- [ ] Test on both machines (iMac + MacBook)

---

## Post-Release

### Monitoring (Week 5+)

- [ ] Monitor for bug reports
- [ ] Collect user feedback
- [ ] Track usage metrics (if available)
- [ ] Watch for edge cases

### Future Enhancements

- [ ] Version management integration (`dot version`)
- [ ] Package sync (`dot pkg`)
- [ ] Template picker (`dot template`)
- [ ] Automated sync (`dot watch`)
- [ ] Multi-repo support

---

## Quick Reference

### Development Commands

```bash
# Load plugin in current shell
source flow.plugin.zsh

# Test a command
df status

# Run tests
zsh tests/dot-dispatcher.test.zsh

# Deploy docs
mkdocs serve  # Preview
mkdocs gh-deploy --force  # Deploy
```

### Git Workflow

```bash
# Feature branch
git checkout -b feature/dot-dispatcher

# Commit pattern
git commit -m "feat(df): <description>"
git commit -m "fix(df): <bug fix>"
git commit -m "docs(df): <documentation>"
git commit -m "test(df): <test addition>"

# Push
git push origin feature/dot-dispatcher

# Create PR
gh pr create --base dev --fill
```

---

## Success Criteria

### Week 4 (MVP Complete)

- [ ] All core commands work (`dot`, `edit`, `sync`, `push`, `diff`)
- [ ] Secret management works (`unlock`, `secret list`)
- [ ] Dashboard integration works
- [ ] Work integration works
- [ ] Doctor integration works
- [ ] All tests passing
- [ ] Documentation complete

### Week 8 (Adoption)

- [ ] User runs `dot` daily
- [ ] Zero manual chezmoi commands
- [ ] Secrets injected correctly
- [ ] No sync conflicts

### Week 12 (Mastery)

- [ ] User comfortable with all commands
- [ ] Integration feels natural
- [ ] Zero dotfile-related friction
- [ ] Both machines in sync 100%

---

## Troubleshooting Development

### Common Issues

**Plugin not loading:**

```bash
# Check syntax
zsh -n lib/dispatchers/dot-dispatcher.zsh

# Source manually
source lib/dispatchers/dot-dispatcher.zsh

# Check if function exists
whence -f df
```

**Colors not working:**

```bash
# Check terminal support
echo $TERM

# Test color output
echo -e "\033[32mGreen\033[0m"

# Use flow-cli color functions
source lib/core.zsh
_flow_log_success "Test"
```

**Tests failing:**

```bash
# Run in debug mode
FLOW_DEBUG=1 zsh tests/dot-dispatcher.test.zsh

# Check chezmoi state
chezmoi status

# Check bitwarden state
bw status
```

---

## Time Tracking

| Phase | Estimated | Actual | Notes |
|-------|-----------|--------|-------|
| Phase 1: Foundation | 4h | | |
| Phase 2: Core Workflows | 8h | | |
| Phase 3: Secret Management | 6h | | |
| Phase 4: Status Commands | 3h | | |
| Phase 5: Troubleshooting | 3h | | |
| Phase 6: Error Handling | 2h | | |
| Phase 7: Integration | 4h | | |
| Phase 8: Completions | 2h | | |
| Phase 9: Documentation | 3h | | |
| Phase 10: Testing | 2h | | |
| Phase 11: Polish | 2h | | |
| Phase 12: Release | 1h | | |
| **Total** | **26h** | | |

---

**Status:** Ready to begin implementation
**First Step:** Phase 1 - Create dot-dispatcher.zsh skeleton
**Estimated Completion:** 4 weeks from start date
