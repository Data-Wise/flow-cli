---
tags:
  - tutorial
  - teaching
  - deploy
---

# Tutorial 31: Fast Deployments with teach deploy v2

> Learn to deploy your course website in seconds instead of minutes.

## What You'll Learn

- Deploy directly to production without PRs (8-15 seconds)
- Use smart auto-generated commit messages
- Preview changes before deploying
- View deployment history
- Rollback problematic deployments
- Run deployments in CI/automation

## Prerequisites

- flow-cli v6.4.0+
- Git, yq, and gh CLI installed
- A course project with `.flow/teach-config.yml`
- Draft and production branches configured (e.g., `dev` and `gh-pages`)

## Step 1: Your First Direct Deploy

The traditional PR workflow takes 45-90 seconds:

```bash
# The old way (slow)
teach deploy
```

This creates a PR, waits for GitHub checks, merges, and deploys. For quick updates, this is overkill.

Try the new direct deploy:

```bash
# The new way (fast - 8-15 seconds)
teach deploy --direct
```

Expected output:

```
🚀 Direct Deploy to gh-pages

Changes to deploy:
  M lectures/week-05.qmd
  M _quarto.yml

Commit message: content: week-05 lecture

[✓] All safety checks passed
[✓] Pushed to gh-pages
[✓] Deployment recorded

🎉 Deploy complete in 12s
```

Use `-d` as a shortcut for `--direct`.

## Step 2: Smart Commit Messages

Deploy automatically generates commit messages from your file paths:

Edit a lecture file:

```bash
# After editing lectures/week-05.qmd
teach deploy -d
# → "content: week-05 lecture"
```

Edit a config file:

```bash
# After editing _quarto.yml
teach deploy -d
# → "config: quarto settings"
```

Edit multiple files:

```bash
# After editing 3 different files
teach deploy -d
# → "deploy: 3 file updates"
```

Override with a custom message:

```bash
teach deploy -d -m "Fix typo in regression notes"
# → Uses your custom message
```

## Step 3: Preview with Dry-Run

Always preview before deploying to production:

```bash
teach deploy --dry-run --direct
```

Expected output:

```
🔍 Deploy Preview (DRY RUN)

Changes to deploy:
  M lectures/week-05.qmd
  M lectures/week-06.qmd

Commit message: deploy: 2 file updates
Target branch: gh-pages

Would execute:
  1. git push origin gh-pages
  2. Record deployment history
  3. Trigger GitHub Pages

🔹 No changes made (dry-run mode)
```

This shows exactly what would happen without actually deploying.

## Step 4: Deploy History

View your past deployments:

```bash
teach deploy --history
```

Output:

```
Recent Deployments
─────────────────────────────────────────────────────────

  #  Date                Commit      Message                  Files  Type
  ─────────────────────────────────────────────────────────────────────────
  1  2026-02-03 14:23    a3f8d92     content: week-05 lecture    1    direct
  2  2026-02-03 10:15    b2e4c81     config: quarto settings     1    direct
  3  2026-02-02 16:30    c9a1f45     deploy: 3 file updates      3    direct
  4  2026-02-02 09:00    d8b2c33     Weekly content update       12   pr

Recent: 4 deploys (3 direct, 1 PR) | Avg time: 11s
```

Limit results:

```bash
teach deploy --history --limit 10
```

View specific deployment:

```bash
teach deploy --history --show 1
```

The history is stored in `.flow/deploy-history.yml`.

## Step 5: Rollback a Deployment

Made a mistake? Roll back to the previous state:

```bash
teach deploy --rollback 1
```

This performs a **forward rollback** using `git revert`:

```
🔄 Rolling back deployment #1

Previous state:
  Commit: a3f8d92
  Message: content: week-05 lecture
  Date: 2026-02-03 14:23

Creating revert commit...
[✓] Reverted a3f8d92
[✓] Pushed to gh-pages
[✓] Rollback recorded in history

🎉 Rollback complete
```

Safety guarantees:

- ✅ **Non-destructive** - Creates new revert commit (preserves history)
- ✅ **Traceable** - Rollback recorded in deploy history
- ✅ **Safe for collaboration** - Works even if others have pulled

Roll back an older deployment:

```bash
teach deploy --rollback 3
# Reverts deployment #3 from history (use --history to see index)
```

## Step 6: CI Mode for Automation

Run deployments in scripts or CI without interactive prompts:

```bash
teach deploy --ci -d -m "Automated weekly deploy"
```

The `--ci` flag:

- ✅ Disables all interactive prompts
- ✅ Auto-detects TTY (no manual flag needed in CI)
- ✅ Exits with proper status codes (0 = success, 1 = failure)

Example GitHub Actions workflow:

```yaml
- name: Deploy course website
  run: teach deploy --ci -d -m "Automated deploy from CI"
```

## Step 7: Combining Flags

Practical flag combinations for common workflows:

Quick deploy with automatic tagging:

```bash
teach deploy -d --auto-tag
# Deploys and creates a git tag (v1.2.0, v1.2.1, etc.)
```

CI direct deploy with custom message:

```bash
teach deploy --ci -d -m "Weekly content update"
# Non-interactive, direct, custom message
```

Preview partial deploy:

```bash
teach deploy --dry-run lectures/week-05.qmd
# Preview deploying just one file
```

Safe production deploy:

```bash
teach deploy --dry-run -d && teach deploy -d
# Preview first, then deploy
```

## Step 8: Understanding Deploy Modes

Deploy v2 supports two modes:

### Direct Mode (Fast - 8-15s)

```bash
teach deploy --direct
```

- ✅ No PR created
- ✅ Direct push to production branch
- ✅ Minimal GitHub API calls
- ⚠️ Use for: quick fixes, content updates, trusted changes

### PR Mode (Safe - 45-90s)

```bash
teach deploy
```

- ✅ Creates PR for review
- ✅ Runs GitHub checks
- ✅ Audit trail
- ⚠️ Use for: major changes, breaking updates, collaborative courses

Choose based on your needs:

| Scenario | Mode | Command |
|----------|------|---------|
| Fix typo | Direct | `teach deploy -d -m "Fix typo"` |
| Weekly update | Direct | `teach deploy -d` |
| New semester | PR | `teach deploy` |
| Major redesign | PR | `teach deploy` |

## What You Learned

You now know how to:

1. ✅ Deploy in 8-15 seconds with `--direct`
2. ✅ Use smart auto-generated commit messages
3. ✅ Preview changes with `--dry-run`
4. ✅ View deployment history with `--history`
5. ✅ Rollback problematic deployments with `--rollback`
6. ✅ Automate deployments with `--ci`
7. ✅ Combine flags for powerful workflows
8. ✅ Choose between direct and PR modes

## Tips

- **Preview first.** Use `--dry-run` before deploying to production.
- **Check history.** Use `--history` to track what you've deployed.
- **Rollback safely.** Use `--rollback` instead of manual git reverts.
- **Automate wisely.** Use `--ci` for scripts, but keep `--direct` for manual deploys.

## Quick Reference

```bash
teach dep -d              # Fast direct deploy
teach dep --dry-run       # Preview changes
teach dep --history       # View past deploys
teach dep --rollback 1    # Undo last deploy
teach dep --ci -d         # CI mode
teach dep -d -m "msg"     # Custom message
```

## Next Steps

- See [REFCARD-DEPLOY-V2.md](../reference/REFCARD-DEPLOY-V2.md) for complete flag reference
- Read [TEACH-DEPLOY-GUIDE.md](../guides/TEACH-DEPLOY-GUIDE.md) for advanced workflows
- Try `teach deploy --history` to track your deployments
- Explore `teach deploy --rollback` for safe recovery

---

*v6.4.0 - teach deploy v2 command*
