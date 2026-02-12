# Em Doctor Integration — Orchestration Plan

> **Branch:** `feature/em-doctor-integration`
> **Base:** `dev`
> **Worktree:** `~/.git-worktrees/flow-cli/feature-em-doctor-integration`
> **Spec:** `docs/specs/SPEC-em-doctor-flow-integration-2026-02-12.md`

## Objective

Add an EMAIL section to `flow doctor` that checks himalaya and all email
dependencies when the `em` dispatcher is loaded. Include verbose connectivity
testing (IMAP, OAuth2, SMTP config) and guided email setup in `--fix` mode.

## Phase Overview

| Phase | Task | Priority | Status |
| ----- | ---- | -------- | ------ |
| 1 | Add `_doctor_check_email()` with all dep checks | High | done |
| 2 | Add email category to `--fix` mode menu | High | done |
| 3 | Add `_doctor_email_connectivity()` for `--verbose` | Medium | done |
| 4 | Add `_doctor_email_setup()` guided config wizard | Medium | done |
| 5 | Update `_doctor_help()` and docs | Low | done |
| 6 | Add tests for conditional gate + all paths | Low | done |

## Phase 1: Dep Checking (`_doctor_check_email`)

**Files:** `commands/doctor.zsh`

- Add conditional gate: `(( $+functions[em] )) && _doctor_check_email`
- Place after INTEGRATIONS section, before DOTFILES
- Check email-unique deps only (dedup fzf/bat/jq from earlier sections):
  - himalaya (required, brew) + version >= 1.0.0
  - w3m/lynx/pandoc (any-of, recommended)
  - glow (recommended, brew)
  - email-oauth2-proxy (recommended, pip)
  - terminal-notifier (optional, brew)
  - AI backend: claude or gemini (conditional on $FLOW_EMAIL_AI)
- Show config summary (AI backend, timeout, page size, config file)

## Phase 2: Fix Mode Category

**Files:** `commands/doctor.zsh`

- Track email-specific missing packages in `_doctor_missing_email_brew[]`
- Add "email" category to `_doctor_select_fix_category()`
- Add email fix path to `_doctor_apply_fixes()`
- Install via brew (himalaya, glow, w3m, terminal-notifier)
- Install via pip (email-oauth2-proxy)

## Phase 3: Verbose Connectivity

**Files:** `commands/doctor.zsh`

- `_doctor_email_connectivity()` — only runs in `--verbose` mode
- Tests: account config, IMAP ping (1 message), OAuth2 proxy running, SMTP config validation
- All failures shown as warnings (yellow), not errors
- 5s timeout per test, 15s max total

## Phase 4: Guided Email Setup

**Files:** `commands/doctor.zsh`

- `_doctor_email_setup()` — runs in `--fix` mode when no config found
- Interactive prompts: email address, IMAP host/port, auth method
- Provider auto-detection (gmail, outlook, yahoo, icloud)
- Generate `~/.config/himalaya/config.toml`
- Offer OAuth2 proxy setup for Gmail/Outlook
- Run connectivity test after setup

## Phase 5: Help & Docs

**Files:** `commands/doctor.zsh`, docs

- Update `_doctor_help()` with EMAIL section mention
- Update CLAUDE.md if needed

## Phase 6: Tests

**Files:** `tests/test-doctor-email.zsh`

- Conditional gate: em loaded vs not loaded
- Dep checking with mock commands
- Version check
- Fix mode email category
- Connectivity tests (mocked)

## Acceptance Criteria

- [ ] `flow doctor` shows EMAIL section when em() loaded
- [ ] `flow doctor` skips EMAIL section when em() not loaded
- [ ] All email deps checked with correct levels
- [ ] `flow doctor --fix` includes Email Tools category
- [ ] `flow doctor --verbose` tests IMAP connectivity
- [ ] `flow doctor --fix` offers guided himalaya setup
- [ ] `em doctor` still works independently
- [ ] Tests pass for all code paths

## How to Start

```bash
cd ~/.git-worktrees/flow-cli/feature-em-doctor-integration
claude
```

Read this file and the spec, then start Phase 1.
