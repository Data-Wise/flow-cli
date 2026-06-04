# Token Cookbook — Practical Recipes for tok

> Copy-paste workflows for token rotation, vault hygiene, and GitHub Actions secrets auto-sync.
>
> **Dispatcher:** `tok` | **Feature:** auto-sync (fan-out to GitHub Actions secrets)
> **Last Updated:** 2026-06-03

Each recipe follows the same structure: a one-line goal, then a single copy-pasteable code block with inline `# Step` comments and example output.
For full reference, see the [refcard](../reference/REFCARD-TOKEN-SECRETS.md) and the [complete guide](TOKEN-MANAGEMENT-COMPLETE.md).

> **Note:** `tok` is an interactive ZSH dispatcher — it prompts for input on a TTY. Run these recipes in your own terminal, not from a non-interactive shell.

---

## Table of Contents

1. [Rotate a GitHub App Key and Fan It Out Everywhere](#1-rotate-a-github-app-key-and-fan-it-out-everywhere)
2. [Audit What Would Be Pushed Before Trusting Auto-Push](#2-audit-what-would-be-pushed-before-trusting-auto-push)
3. [Add a New Repo to the Sync Mapping](#3-add-a-new-repo-to-the-sync-mapping)
4. [Manually Push a Token to Its Mapped Secrets](#4-manually-push-a-token-to-its-mapped-secrets)
5. [Unblock a Repo Whose Actions Secrets Were Never Configured](#5-unblock-a-repo-whose-actions-secrets-were-never-configured)
6. [Disable Auto-Sync for a One-Off (and in CI)](#6-disable-auto-sync-for-a-one-off-and-in-ci)
7. [Migrate a PyPI Publish to OIDC Trusted Publishing](#7-migrate-a-pypi-publish-to-oidc-trusted-publishing)
8. [Proactively Rotate Tokens Nearing Expiry](#8-proactively-rotate-tokens-nearing-expiry)
9. [Set Up the Sync Config From Scratch](#9-set-up-the-sync-config-from-scratch)
10. [Verify What Landed on a Repo After a Push](#10-verify-what-landed-on-a-repo-after-a-push)

---

## 1. Rotate a GitHub App Key and Fan It Out Everywhere

**Goal:** Rotate a GitHub App private key once and have the new value land in every tap-caller repo automatically.

```zsh
# Step 1: Refresh the token in your local vault.
#         The auto-sync hook fires after a successful refresh.
tok github-app --refresh

# Step 2: tok prints the fan-out plan, then asks ONCE to confirm.
#         Default is N — you must type y to proceed.
#   Auto-sync: github-app → 8 secrets across 4 repos
#     APP_ID, APP_PRIVATE_KEY → data-wise/flow-cli
#     APP_ID, APP_PRIVATE_KEY → data-wise/aiterm
#     APP_ID, APP_PRIVATE_KEY → data-wise/examark
#     APP_ID, APP_PRIVATE_KEY → data-wise/nexus-cli
#   Push these secrets now? [y/N] y

# Step 3: tok writes each secret via stdin (values never appear on the
#         command line or in shell history).
#   ✓ data-wise/flow-cli   APP_ID, APP_PRIVATE_KEY
#   ✓ data-wise/aiterm     APP_ID, APP_PRIVATE_KEY
#   ✓ data-wise/examark    APP_ID, APP_PRIVATE_KEY
#   ✓ data-wise/nexus-cli  APP_ID, APP_PRIVATE_KEY
#   Done. 8 secrets updated across 4 repos.
```

One refresh replaces the entire `gh secret set NAME --repo org/repo` loop you used to run by hand. The mapping comes from `~/.config/flow/tok-sync.conf`; rows are matched by token name (`github-app`).

---

## 2. Audit What Would Be Pushed Before Trusting Auto-Push

**Goal:** See exactly which secrets and repos a token maps to — without writing anything.

```zsh
# Step 1: Dry inspect the mapping for a token. No network writes happen.
tok sync repos github-app

# Step 2: Read the plan. This is the same plan auto-sync would execute.
#   github-app → 8 secrets across 4 repos
#     APP_ID            → data-wise/flow-cli
#     APP_PRIVATE_KEY   → data-wise/flow-cli
#     APP_ID            → data-wise/aiterm
#     APP_PRIVATE_KEY   → data-wise/aiterm
#     APP_ID            → data-wise/examark
#     APP_PRIVATE_KEY   → data-wise/examark
#     APP_ID            → data-wise/nexus-cli
#     APP_PRIVATE_KEY   → data-wise/nexus-cli
#   (OIDC-flagged rows, if any, are listed but never pushed.)
```

`tok sync repos` is read-only — it parses the config and resolves the mapping but performs zero writes. Run it whenever you change the config or before a big rotation so you trust what auto-sync will do.

---

## 3. Add a New Repo to the Sync Mapping

**Goal:** Start fanning a token out to one more repo by editing a single config file.

```zsh
# Step 1: Open the chezmoi-managed sync config.
$EDITOR ~/.config/flow/tok-sync.conf

# Step 2: Add one row per secret for the new repo. Format:
#   <token-name>  <secret-name>     <owner/repo>     [oidc]
#
#   github-app    APP_ID            data-wise/new-tool
#   github-app    APP_PRIVATE_KEY   data-wise/new-tool

# Step 3: Confirm the new rows are picked up (dry, no writes).
tok sync repos github-app
#   github-app → now 10 secrets across 5 repos

# Step 4: Push the token to the newly mapped repo (and all others).
tok sync push github-app
```

The config is a flat, never-sourced file: `#` comments and blank lines are ignored. Because it lives under chezmoi, commit the change in your dotfiles so the mapping travels with you. Override the path for testing with `FLOW_TOK_SYNC_CONF`.

---

## 4. Manually Push a Token to Its Mapped Secrets

**Goal:** Fan a token out on demand, without rotating it first.

```zsh
# Step 1: Trigger a manual fan-out for a token already in your vault.
tok sync push npm

# Step 2: Confirm at the single gate (default N).
#   Auto-sync: npm → 1 secret across 1 repo
#     NPM_TOKEN → data-wise/flow-cli
#   Push this secret now? [y/N] y
#   ✓ data-wise/flow-cli  NPM_TOKEN
#   Done. 1 secret updated across 1 repo.
```

`tok sync push` is the manual equivalent of the auto-sync hook: same mapping, same single `[y/N]` confirm (default N), same stdin-only writes. Use it when a secret got out of sync on a repo but the vault token itself is still valid.

---

## 5. Unblock a Repo Whose Actions Secrets Were Never Configured

**Goal:** Fix a repo (e.g. `nexus-cli`) whose CI fails because its Actions secrets were never set.

```zsh
# Step 1: Confirm the repo is in the mapping (or add it — see Recipe 3).
tok sync repos github-app | grep nexus-cli
#   APP_ID            → data-wise/nexus-cli
#   APP_PRIVATE_KEY   → data-wise/nexus-cli

# Step 2: Push the current vault token to all mapped repos, nexus-cli included.
tok sync push github-app
#   Push these secrets now? [y/N] y
#   ✓ data-wise/nexus-cli  APP_ID, APP_PRIVATE_KEY
#   Done.

# Step 3: Verify the secrets now exist on the repo (see Recipe 10).
gh secret list --repo data-wise/nexus-cli
```

This is the common "new repo, red CI" fix: the repo was added to the mapping but never received the secrets. A single `tok sync push` populates it without touching your token rotation schedule.

---

## 6. Disable Auto-Sync for a One-Off (and in CI)

**Goal:** Refresh a token locally without triggering the fan-out — once, or for an entire CI run.

```zsh
# One-off: skip the auto-sync hook for this command only.
tok github --refresh --no-sync
#   (Token refreshed in vault. No secrets pushed.)

# CI / scripted: disable auto-sync for the whole shell/session.
export FLOW_TOK_AUTOSYNC=0
tok rotate github-app
#   (Rotated in vault. Auto-sync skipped because FLOW_TOK_AUTOSYNC=0.)
```

Auto-sync is **ON by default**. Use `--no-sync` for a single command, or set `FLOW_TOK_AUTOSYNC=0` to disable it everywhere — handy in CI where you do not want a confirm prompt or unexpected secret writes.

---

## 7. Migrate a PyPI Publish to OIDC Trusted Publishing

**Goal:** Stop syncing a stored `PYPI_TOKEN` secret and switch the repo to OIDC Trusted Publishing.

```zsh
# Step 1: Mark the row 'oidc' in the sync config. tok will never push it.
$EDITOR ~/.config/flow/tok-sync.conf
#   pypi    PYPI_TOKEN    data-wise/nexus-cli    oidc

# Step 2: tok now skips the row and prints a Trusted Publishing nudge
#         on the next sync/rotate.
tok sync repos pypi
#   pypi → PYPI_TOKEN → data-wise/nexus-cli  [oidc — NOT pushed]
#   ℹ Trusted Publishing: add to your workflow instead of a stored token:
#       permissions:
#         id-token: write
#       - uses: pypa/gh-action-pypi-publish@release/v1

# Step 3: Update the publish workflow in the repo to match the nudge.
#   .github/workflows/publish.yml
#     permissions:
#       id-token: write          # required for OIDC
#     steps:
#       - uses: pypa/gh-action-pypi-publish@release/v1
#         # no 'password:' / token needed — PyPI trusts the repo via OIDC
```

OIDC-flagged rows are **never pushed** — `tok` lists them but refuses to write a stored secret, then prints the workflow snippet you need. Once the workflow uses `pypa/gh-action-pypi-publish` with `id-token: write`, you can delete the old `PYPI_TOKEN` secret from the repo.

---

## 8. Proactively Rotate Tokens Nearing Expiry

**Goal:** Find tokens about to expire, rotate them, and let auto-sync update every repo.

```zsh
# Step 1: List vault tokens nearing their expiry date.
tok expiring
#   ⚠ github-app   expires in 6 days   (8 mapped secrets, 4 repos)
#   ⚠ npm          expires in 11 days  (1 mapped secret, 1 repo)

# Step 2: Rotate the one that is closest. Auto-sync fans it out.
tok rotate github-app
#   ✓ Rotated in vault.
#   Auto-sync: github-app → 8 secrets across 4 repos
#   Push these secrets now? [y/N] y
#   Done. 8 secrets updated across 4 repos.

# Step 3: Re-check that nothing else is imminent.
tok expiring
#   npm   expires in 11 days
```

`tok expiring` reads expiry metadata from the vault so you can rotate ahead of breakage. Because rotation triggers auto-sync, the repos are updated in the same step — no separate `gh secret set` pass needed.

---

## 9. Set Up the Sync Config From Scratch

**Goal:** Create the mapping file for the first time and put it under chezmoi.

```zsh
# Step 1: Copy the shipped example to the config location.
mkdir -p ~/.config/flow
cp docs/reference/examples/tok-sync.conf.example ~/.config/flow/tok-sync.conf

# Step 2: Edit the mapping. Columns: token-name, secret-name, owner/repo, [oidc]
$EDITOR ~/.config/flow/tok-sync.conf
```

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

```zsh
# Step 3: Track it with chezmoi so the mapping travels with your dotfiles.
chezmoi add ~/.config/flow/tok-sync.conf

# Step 4: Sanity-check the mapping (read-only, no writes).
tok sync repos github-app
```

The file is **never sourced** — `tok` parses it line by line with an allowlisted format, so a stray line cannot execute code. `#` comments and blank lines are ignored. Set `FLOW_TOK_SYNC_CONF` to point at a different file (useful for tests or a second machine profile).

---

## 10. Verify What Landed on a Repo After a Push

**Goal:** Confirm the secrets are actually present on a repo after a sync.

```zsh
# Step 1: List the Actions secrets configured on the repo.
gh secret list --repo data-wise/flow-cli
#   APP_ID          Updated 2026-06-03
#   APP_PRIVATE_KEY Updated 2026-06-03
#   NPM_TOKEN       Updated 2026-05-21

# Step 2: gh shows names + update timestamps only — secret VALUES are never
#         readable back. A fresh 'Updated' date confirms the push landed.
```

`gh secret list` is the trust-but-verify step. GitHub never exposes secret values once written, so confirmation is by name and timestamp. If a `tok sync gh` auth check is needed first, note that `tok sync gh` is unchanged — it only verifies your `gh` authentication and does not touch the mapping.

---

## See Also

- [47-tok-auto-sync.md](../tutorials/47-tok-auto-sync.md) — Step-by-step tutorial for the auto-sync feature
- [23-token-automation.md](../tutorials/23-token-automation.md) — Token automation fundamentals (create, validate, store)
- [TOKEN-MANAGEMENT-COMPLETE.md](TOKEN-MANAGEMENT-COMPLETE.md) — Complete token management guide
- [REFCARD-TOKEN-SECRETS.md](../reference/REFCARD-TOKEN-SECRETS.md) — All `tok` commands and flags at a glance
- [tok-sync.conf.example](../reference/examples/tok-sync.conf.example) — Canonical sync config template

---

**Feature:** tok auto-sync — flow-cli
**Last Updated:** 2026-06-03
