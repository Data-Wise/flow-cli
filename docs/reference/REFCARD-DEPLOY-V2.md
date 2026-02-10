---
tags: [reference, teaching, deploy]
---

# Quick Reference: teach deploy v2

> Enhanced Git-based Course Deployment with PR Workflow & Rollback

## Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `teach deploy` | `teach dep` | Full site deploy via PR (draft → production) |
| `teach deploy -d` | `teach dep -d` | Direct merge, no PR (8-15s) |
| `teach deploy --dry-run` | `teach dep --preview` | Preview without executing |
| `teach deploy --rollback [N]` | `teach dep --rb [N]` | Rollback deployment N (1=most recent) |
| `teach deploy --history [N]` | `teach dep --hist [N]` | Show last N deploys (default: 10) |
| `teach deploy <files>` | `teach dep <files>` | Partial deploy (specific files/dirs) |

## Deploy Modes

| Mode | Command | Speed | Use Case |
|------|---------|-------|----------|
| PR (default) | `teach deploy` | 45-90s | Review before production |
| Direct merge | `teach deploy -d` | 8-15s | Quick fixes, solo instructor |
| Partial | `teach deploy file.qmd` | Varies | Single file updates |
| Dry-run | `teach deploy --dry-run` | <1s | Preview before executing |

## Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--direct` | `-d` | Direct merge mode (no PR) |
| `--dry-run` | `--preview` | Preview without executing |
| `--rollback [N]` | `--rb [N]` | Revert deployment N from history |
| `--history [N]` | `--hist [N]` | Show recent deployments |
| `--ci` | | Force non-interactive mode |
| `--message "text"` | `-m` | Custom commit message |
| `--auto-commit` | | Auto-commit dirty files |
| `--auto-tag` | | Tag with timestamp |
| `--skip-index` | | Skip index management |
| `--check-prereqs` | | Validate prerequisites |
| `--direct-push` | | Alias for `--direct` (backward compat) |

## Smart Commit Messages

Auto-generated from changed file paths:

```
lectures/*.qmd        → "content: week-05 lecture"
assignments/*.qmd     → "content: assignment 3"
_quarto.yml           → "config: quarto settings"
styles/*.css          → "style: theme update"
Mixed files           → "deploy: STAT-101 update"
```

Override with custom message:

```bash
teach deploy -d -m "Week 5 lecture + lab"
```

## Deploy History

Stored in `.flow/deploy-history.yml` (git-tracked):

```yaml
deploys:
  - timestamp: '2026-02-03T14:30:22-06:00'
    mode: 'direct'
    commit_hash: 'a1b2c3d4'
    branch_from: 'draft'
    branch_to: 'main'
    file_count: 15
    commit_message: 'content: week-05 lecture'
```

View history:

```bash
teach deploy --history      # Last 10 deploys
teach deploy --history 20   # Last 20 deploys
```

## Rollback

```bash
teach deploy --rollback        # Interactive picker
teach deploy --rollback 1      # Most recent deploy
teach deploy --rollback 2 --ci # 2nd most recent, non-interactive
```

Uses `git revert` (forward rollback, not destructive reset). Merge commits are detected automatically and reverted with `-m 1` (parent specification). Rollback is recorded in history with `mode: "rollback"`.

## Safety Features (v6.6.0+)

### Display Math Validation

Scans changed `.qmd` files for blank lines and unclosed `$$` blocks (both break Quarto renders):

```
  [ok] Display math blocks valid          ← all clean
  [!!] Blank lines in display math        ← blank line inside $$
  [!!] Unclosed $$ block (breaks render)  ← missing closing $$
```

**CI mode:** Math issues block deployment. **Interactive:** Warns only.

Uses pure ZSH state machine (`_check_math_blanks`) — no Python dependency.

### Uncommitted Changes Prompt

With a dirty working tree, deploy prompts to commit instead of blocking:

```
  Uncommitted changes detected
  Suggested: content: week-05 lecture
  Commit and continue? [Y/n]:
```

Press Enter (or Y) to auto-commit with the smart message. Press N to cancel.

**CI mode:** Fails immediately with `"Commit changes before deploying in CI mode"`.

### Pre-Commit Hook Failure Recovery

If a commit fails (e.g., Quarto pre-commit hook), you get 3 actionable options:

```
  ERROR: Commit failed (likely pre-commit hook)

  Options:
    1. Fix the issues above, then teach deploy again
    2. Skip validation: QUARTO_PRE_COMMIT_RENDER=0 teach deploy ...
    3. Force commit: git commit --no-verify -m "message"

  Your changes are still staged. Nothing was lost.
```

### Trap Handler (Branch Safety)

Both direct merge and PR modes set a trap: if an error or signal (Ctrl+C, kill) occurs mid-deploy, you're automatically returned to your draft branch. No more getting stuck on production.

### GitHub Actions Link

The deployment summary box now includes a direct link to GitHub Actions:

```
╭─ Deployment Summary ─────────────────────────────────╮
│  🚀 Mode:     Direct merge                            │
│  📦 Files:    3 changed (+45 / -12)                   │
│  ⏱  Duration: 8s                                      │
│  🔀 Commit:   a1b2c3d4                                │
│  🌐 URL:      https://example.github.io/stat-545/    │
│  ⚙  Actions:  https://github.com/user/stat-545/actions│  ← NEW
╰──────────────────────────────────────────────────────╯
```

Automatically detected from `remote.origin.url`. Skipped for non-GitHub remotes.

### Environment Variables

| Variable | Purpose |
|----------|---------|
| `QUARTO_PRE_COMMIT_RENDER=0` | Skip Quarto pre-commit render validation |

## CI Mode

Auto-detected when no TTY (`[[ ! -t 0 ]]`), or forced with `--ci`:

```bash
teach deploy --ci -d           # Direct merge, no prompts
echo | teach deploy            # Auto-detected (piped input)
```

**CI behavior for safety features:**

| Feature | Interactive | CI Mode |
|---------|-------------|---------|
| Display math issues | Warns, continues | Blocks deploy |
| Uncommitted changes | Prompts to commit | Fails with error |
| Hook failure | Shows 3 options | Exits non-zero |
| Trap handler | Returns to draft | Returns to draft |
| Actions link | Shown in summary | Shown in summary |

## .STATUS Auto-Updates

After successful deploy, non-destructively updates `.STATUS`:

- `last_deploy:` → today's date
- `deploy_count:` → total deploys from history
- `teaching_week:` → calculated from `semester_info.start_date`

Skips if `.STATUS` absent.

## Output Format (Direct Mode)

```
  Pre-flight Checks
─────────────────────────────────────────────────
  [ok] Git repository
  [ok] Config file found
  [ok] On draft branch
  [ok] Working tree clean
  [ok] Display math blocks valid
  [ok] No production conflicts

  Smart commit: content: week-05 lecture

  Direct merge: draft -> production
  ✓ [1/5] Push draft to origin
  ✓ [2/5] Switch to production
  ✓ [3/5] Merge draft → production
  ✓ [4/5] Push production to origin
  ✓ [5/5] Switch back to draft

╭─ Deployment Summary ─────────────────────────────────╮
│  🚀 Mode:     Direct merge                            │
│  📦 Files:    3 changed (+45 / -12)                   │
│  ⏱  Duration: 11s                                     │
│  🔀 Commit:   a1b2c3d4                                │
│  🌐 URL:      https://example.github.io/stat-545/    │
│  ⚙  Actions:  https://github.com/user/stat-545/actions│
╰──────────────────────────────────────────────────────╯
```

## Configuration

In `.flow/teach-config.yml`:

```yaml
git:
  draft_branch: draft         # Default: "draft"
  production_branch: main     # Default: "main"
  auto_pr: true               # Default: true
  require_clean: true         # Default: true
```

## Workflows

### Quick deploy (direct merge)

```bash
# Make changes on draft branch
teach deploy -d
# 8-15 seconds → live
```

### Deploy via PR (default)

```bash
# Make changes on draft branch
teach deploy
# Opens PR → review → merge → live
```

### Partial deploy (specific files)

```bash
teach deploy lectures/week-05.qmd
teach deploy lectures/ assignments/hw-03.qmd
```

### Preview before deploying

```bash
teach deploy --dry-run
# Shows what would happen without executing
```

### Rollback to previous version

```bash
teach deploy --rollback
# Interactive picker shows recent deploys
# Select deployment to revert
```

### Non-interactive (CI/CD)

```bash
teach deploy --ci -d -m "Auto-deploy from GitHub Actions"
```

## Files

| File | Purpose |
|------|---------|
| `lib/dispatchers/teach-deploy-enhanced.zsh` | Main deploy implementation |
| `lib/git-helpers.zsh` | Smart commit messages |
| `lib/deploy-history-helpers.zsh` | History tracking |
| `lib/deploy-rollback-helpers.zsh` | Rollback via git revert |
| `.flow/deploy-history.yml` | Deploy history (git-tracked) |
| `.STATUS` | Auto-updated after deploy |

## Related

- `teach doctor` - Health check with deploy validation
- `teach init` - Initialize teaching project
- Guide: `docs/guides/TEACH-DEPLOY-GUIDE.md`
- Spec: `docs/specs/SPEC-teach-deploy-v2-2026-02-03.md`
- Spec: `docs/specs/SPEC-teach-deploy-safety-2026-02-08.md`

---

*v6.7.0 - teach deploy v2 with math preflight + quality gates*
