---
tags:
  - tutorial
  - security
  - configuration
---

# Tutorial 47: Token Auto-Sync to GitHub Actions Secrets

> **Fan out one token to GitHub Actions secrets across every repo that needs it**
>
> **Time:** ~15 minutes | **Level:** Intermediate | **v7.8.1**

---

## What You'll Learn

By the end of this tutorial, you'll be able to:

- ✅ Configure `tok` to push a token to GitHub Actions secrets across multiple repos
- ✅ Audit planned sync targets with a safe dry run (no writes)
- ✅ Push secrets manually with a single confirmation gate
- ✅ Trigger auto-sync automatically after creating or rotating a token
- ✅ Disable sync per-command and in CI with `--no-sync` / `FLOW_TOK_AUTOSYNC=0`
- ✅ Skip a secret entirely using OIDC Trusted Publishing

---

## Prerequisites

Before starting:

- ✓ Flow-CLI installed (`flow doctor` works)
- ✓ GitHub CLI installed and authenticated (`gh auth status`)
- ✓ A token you actually manage with `tok` (GitHub App, npm, PyPI, etc.)

!!! tip "New to flow-cli or tok?"
    Complete [Tutorial 1: First Session](01-first-session.md) for the basics, and
    [Tutorial 23: Token Automation](23-token-automation.md) to understand how `tok` stores
    and validates tokens. This tutorial builds directly on that foundation.

---

## Step 1: Why Auto-Sync?

**The Problem:**

The Homebrew release pipeline authenticates with a GitHub App, which means two secrets —
`APP_ID` and `APP_PRIVATE_KEY` — must exist as GitHub Actions secrets in **every**
tap-caller repo (`flow-cli`, `aiterm`, `examark`, `nexus-cli`). When you rotate the app
key, you used to run `gh secret set` by hand, once per secret, once per repo:

```bash
gh secret set APP_ID --repo data-wise/flow-cli
gh secret set APP_PRIVATE_KEY --repo data-wise/flow-cli
gh secret set APP_ID --repo data-wise/aiterm
# ...and six more times. Miss one and a release silently fails.
```

**The Solution:**

Auto-sync fans a single token out to every configured target in one step. After you create
or rotate a token, `tok` reads a flat config file, lists the planned `repo : secret`
targets, asks once, and pushes each value via `gh secret set`.

- **🔁 One source, many repos** — define targets once, sync everywhere
- **🔒 Safe by design** — values go over stdin only, config is parsed (never sourced)
- **👀 Auditable** — dry-run inspection before any write
- **⚙️ CI-friendly** — opt out per-command or with one env var

---

## Step 2: Create the Config File

Sync is driven by a flat, whitespace-delimited config at
`~/.config/flow/tok-sync.conf`. It is a chezmoi-managed dotfile, so the same targets
follow you across machines. Override the path with `FLOW_TOK_SYNC_CONF` if needed.

A ready-to-copy example ships with flow-cli at
`docs/reference/examples/tok-sync.conf.example`. Copy it into place:

```bash
mkdir -p ~/.config/flow
cp docs/reference/examples/tok-sync.conf.example ~/.config/flow/tok-sync.conf
```

Each non-comment line has the format `<token-name> <secret-name> <owner/repo> [oidc]`:

```text
# <token-name>  <secret-name>     <owner/repo>     [oidc]
github-app       APP_ID            data-wise/flow-cli
github-app       APP_PRIVATE_KEY   data-wise/flow-cli
github-app       APP_ID            data-wise/aiterm
github-app       APP_PRIVATE_KEY   data-wise/aiterm
github-app       APP_ID            data-wise/examark
github-app       APP_PRIVATE_KEY   data-wise/examark
github-app       APP_ID            data-wise/nexus-cli
github-app       APP_PRIVATE_KEY   data-wise/nexus-cli
pypi             PYPI_TOKEN        data-wise/nexus-cli   oidc
```

| Field | Meaning |
|-------|---------|
| `<token-name>` | The token as `tok` knows it (e.g. `github-app`, `npm`, `pypi`) |
| `<secret-name>` | The GitHub Actions secret name to write |
| `<owner/repo>` | The repo that receives the secret |
| `[oidc]` | Optional flag — marks a row that should use Trusted Publishing instead (Step 7) |

!!! note "Never sourced, always parsed"
    The config file is read line by line and parsed — it is **never** `source`d or executed.
    Lines starting with `#` and blank lines are ignored. Secret and repo names are validated
    against an allowlist before any `gh` call, so a typo or injected value is rejected, not run.

---

## Step 3: Audit Targets with a Dry Run

Before writing anything, inspect what a sync *would* do. `tok sync repos <name>` lists the
planned targets and OIDC notes without making a single write:

```bash
tok sync repos github-app
```

**Expected output:**

```text
🔁 Planned sync targets for 'github-app' (dry run, no writes):
    data-wise/flow-cli : APP_ID
    data-wise/flow-cli : APP_PRIVATE_KEY
ℹ would push 2 secret(s) across 1 repo(s) (dry run, no writes)
```

!!! success "Safe to run anytime"
    `tok sync repos` never touches GitHub. Use it to confirm your config is correct before
    a real push, or just to remember which repos a token feeds.

---

## Step 4: Push Manually with the Confirm Gate

When you're ready to write the secrets, use `tok sync push <name>`. It lists the targets,
then asks for a **single** `[y/N]` confirmation (default **N**) before writing each value via
`gh secret set` over stdin:

```bash
tok sync push github-app
```

**Expected output:**

```text
🔁 Sync targets for 'github-app':
    data-wise/flow-cli : APP_ID
    data-wise/flow-cli : APP_PRIVATE_KEY

Push 2 secret(s) to 1 repo(s)? [y/N] y
  ✓ data-wise/flow-cli : APP_ID
  ✓ data-wise/flow-cli : APP_PRIVATE_KEY
```

The default is **N** — pressing Enter without typing anything cancels with no writes. One
confirmation covers the whole batch, so you don't get prompted per secret.

!!! warning "Don't confuse `tok sync push` with `tok sync gh`"
    `tok sync gh` is the **existing** command that runs `gh auth login` to authenticate the
    GitHub CLI itself. It is unrelated to the secret fan-out. The new commands are
    `tok sync repos` (dry run) and `tok sync push` (write).

---

## Step 5: Auto-Sync on Create and Rotate

You usually won't call `tok sync push` directly. The whole point is that sync happens
**automatically** at the moment you create or rotate a token. After a successful:

- `tok github`
- `tok npm`
- `tok pypi`
- `tok rotate`
- `tok <name> --refresh`

…`tok` checks whether that token name has any config targets. If it does, it lists them and
asks once before pushing — the same confirm gate as `tok sync push`.

```bash
tok github-app --refresh
```

**Expected output:**

```text
✓ Token 'github-app' refreshed and validated

🔁 Sync targets for 'github-app':
    data-wise/flow-cli : APP_ID
    data-wise/flow-cli : APP_PRIVATE_KEY

Push 2 secret(s) to 1 repo(s)? [y/N] y
  ✓ data-wise/flow-cli : APP_ID
  ✓ data-wise/flow-cli : APP_PRIVATE_KEY
```

!!! note "Auto-sync is ON by default"
    If a token has no config targets, nothing happens — auto-sync is a clean no-op. Tokens
    with targets prompt you once. You stay in control: the default answer is always **N**.

---

## Step 6: Disable Sync (Per-Command and in CI)

Sometimes you want to rotate a token without touching any repo — for example in CI, a
non-interactive script, or when you only want the local vault updated. Two bypasses:

### Per-command flag

```bash
tok github-app --refresh --no-sync
```

`--no-sync` skips the fan-out entirely for that one command. The token is still created,
validated, and stored locally — only the GitHub push is suppressed.

### Environment variable (CI / non-interactive)

```bash
FLOW_TOK_AUTOSYNC=0 tok rotate github-app
```

Set `FLOW_TOK_AUTOSYNC=0` to disable auto-sync for the whole shell or job. This is the right
switch for CI runners and cron jobs where no one is present to answer the confirm prompt.

| Control | Scope | Effect |
|---------|-------|--------|
| (default) | — | Auto-sync ON, prompts once per token with targets |
| `--no-sync` | Single command | Skip fan-out for this invocation only |
| `FLOW_TOK_AUTOSYNC=0` | Shell / job | Disable auto-sync everywhere |

!!! tip "gh missing? Also a no-op"
    Auto-sync requires `gh` to be installed and authenticated (`gh auth status`). If `gh` is
    missing or logged out, the sync step is skipped cleanly without erroring your rotation.

---

## Step 7: OIDC — Skip the Secret Entirely

A config row marked with the `oidc` flag is **never** pushed as a secret. Instead, `tok`
prints a Trusted Publishing recommendation:

```bash
tok sync repos pypi
```

**Expected output:**

```text
ℹ OIDC: 'PYPI_TOKEN' for data-wise/nexus-cli — use Trusted Publishing instead of a stored secret.
    Add 'permissions: id-token: write' + 'pypa/gh-action-pypi-publish' to the workflow.
```

**Why prefer OIDC?** A long-lived token stored as a secret is something you must guard,
rotate, and eventually revoke. With OIDC Trusted Publishing, the workflow mints a
short-lived, scoped credential at run time — there is no stored secret to leak or rotate at
all. For PyPI, that means deleting `PYPI_TOKEN` from the repo and letting the workflow
authenticate by identity.

To adopt it, add the permission and the publish action to your workflow:

```yaml
permissions:
  id-token: write

jobs:
  publish:
    steps:
      - uses: pypa/gh-action-pypi-publish@release/v1
```

!!! note "The `oidc` flag documents intent"
    Keeping the OIDC row in your config (rather than deleting it) is useful: `tok sync repos`
    reminds you that this repo *deliberately* has no stored token, and why.

---

## Step 8: Adding a New Tap-Caller Repo

Onboarding a new repo into the release pipeline is now a one-file edit. Add its rows to the
chezmoi-managed config:

```text
github-app       APP_ID            data-wise/new-repo
github-app       APP_PRIVATE_KEY   data-wise/new-repo
```

Then audit and push:

```bash
tok sync repos github-app   # confirm the new rows appear
tok sync push github-app    # write to all repos, including the new one
```

Because `~/.config/flow/tok-sync.conf` is managed by chezmoi, applying your dotfiles on
another machine brings the new target along automatically. No per-repo `gh secret set`
commands, no checklist to forget.

---

## Security Notes

Auto-sync was built to handle secrets safely:

- **Stdin only** — secret values are piped to `gh secret set` over stdin. They never appear
  as command-line arguments (which leak into process listings and shell history) and are
  never written to temp files.
- **Parsed, never executed** — the config file is read as data. It is never `source`d, so a
  malicious or corrupted config can't run code.
- **Allowlist validation** — secret names and `owner/repo` values are validated against an
  allowlist before any `gh` call. Anything that doesn't match is rejected, not pushed.
- **Confirm-gated** — every write path (manual or auto) requires an explicit `y`. The default
  is always **N**.

---

## Recap

You've set up token auto-sync end to end. 🎉

- ✅ Created `~/.config/flow/tok-sync.conf` from the shipped example
- ✅ Audited targets safely with `tok sync repos` (dry run, no writes)
- ✅ Pushed secrets with `tok sync push` and its single confirm gate
- ✅ Triggered auto-sync from `tok github-app --refresh`
- ✅ Disabled sync with `--no-sync` and `FLOW_TOK_AUTOSYNC=0`
- ✅ Skipped a secret with OIDC Trusted Publishing
- ✅ Onboarded a new repo by editing one chezmoi file

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Sync step never runs | `gh` not installed or logged out | Run `gh auth status`; install/authenticate `gh` |
| "no sync targets" message | Token name not in config | Check the `<token-name>` column in `tok-sync.conf` matches the token |
| A row never pushes | Row has the `oidc` flag | Intended — use Trusted Publishing instead (Step 7) |
| Config changes ignored | Wrong path | Confirm `~/.config/flow/tok-sync.conf` or set `FLOW_TOK_SYNC_CONF` |
| Prompt never appears in CI | Auto-sync disabled | Expected if `FLOW_TOK_AUTOSYNC=0`; use `tok sync push` interactively |
| Secret/repo rejected | Failed allowlist validation | Fix the secret name or `owner/repo` spelling in the config |

---

## Next Steps

- **[Tutorial 23: Token Automation](23-token-automation.md)** — How `tok` stores, caches, and validates tokens
- **[Tutorial 1: First Session](01-first-session.md)** — flow-cli fundamentals
- **Example config** — `docs/reference/examples/tok-sync.conf.example`

---

**Tutorial 47 Complete!**

<small>flow-cli v7.7.1 | [Home](../index.md) | [Tutorials](index.md)</small>
