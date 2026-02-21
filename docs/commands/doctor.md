# `doctor` - Health Check & Dependency Manager

> **Comprehensive dependency checker with interactive installation and health diagnostics**

**Command:** `flow doctor [options]`
**Purpose:** Check installed dependencies and optionally fix issues
**Type:** Setup/Diagnostics
**Added:** v3.1.0 (2025-12-26)

---

## Synopsis

```bash
flow doctor                 # Check all dependencies
flow doctor --fix           # Interactive fix mode
flow doctor --fix -y        # Auto-install everything
flow doctor --dot           # Check only DOT tokens
```bash

**Quick examples:**

```bash
# Quick health check
flow doctor

# Interactive install
flow doctor --fix

# Auto-install all missing (skip confirmations)
flow doctor --fix -y

# Check only DOT tokens (fast, < 3s)
flow doctor --dot

# Check specific token
flow doctor --dot=github

# Fix only token issues
flow doctor --fix-token

# Detailed output + connectivity checks
flow doctor --verbose
```diff

---

## Quick Summary

The `doctor` command checks all flow-cli dependencies across multiple categories (required, recommended, optional, integrations, email, ZSH plugins). It can also interactively or automatically install missing tools using Homebrew, npm, or pip. When the `em` email dispatcher is loaded, an EMAIL section checks himalaya and all email-specific dependencies.

---

## Visual Flow

### Simple View

```mermaid
flowchart LR
    A([flow doctor]) --> B{Check Dependencies}
    B --> C[Display Status]
    C --> D{--fix mode?}
    D -->|yes| E[Install Missing]
    D -->|no| F([Done])
    E --> F

    style A fill:#4CAF50,stroke:#2E7D32,color:#fff
    style F fill:#2196F3,stroke:#1565C0,color:#fff
```bash

**In plain words:** Check → Report → (Optional) Fix

---

## Usage

```bash
# Check all dependencies
flow doctor

# Interactive fix mode (prompts before each install)
flow doctor --fix

# Auto-fix mode (install all without prompts)
flow doctor --fix -y

# AI-assisted troubleshooting (via Claude CLI)
flow doctor --ai

# Verbose output
flow doctor --verbose
```diff

---

## Options

| Option          | Short | Description                                    |
| --------------- | ----- | ---------------------------------------------- |
| `--fix`         | `-f`  | Enable fix mode (install missing tools)        |
| `--yes`         | `-y`  | Auto-confirm all installs (use with --fix)     |
| `--ai`          | `-a`  | AI-assisted troubleshooting via Claude CLI     |
| `--verbose`     | `-v`  | Show detailed info + connectivity checks       |
| `--quiet`       | `-q`  | Minimal output (errors only)                   |
| `--dot`         | -     | Check only DOT tokens (isolated, < 3s)         |
| `--dot=TOKEN`   | -     | Check specific token (e.g., `--dot=github`)    |
| `--fix-token`   | -     | Fix only token issues (< 60s)                  |
| `--update-docs` | `-u`  | Regenerate help files and docs                 |
| `--help`        | `-h`  | Show help                                      |

---

## Dependency Categories

### Required (Core Functionality)

| Tool    | Purpose                                               |
| ------- | ----------------------------------------------------- |
| **fzf** | Fuzzy finder for `pick`, `dash -i`, interactive modes |

### Recommended (Enhanced Experience)

| Tool        | Purpose                           | Replaces  |
| ----------- | --------------------------------- | --------- |
| **eza**     | Modern ls with icons & git status | `ls`      |
| **bat**     | Syntax-highlighted file viewer    | `cat`     |
| **zoxide**  | Smart directory jumping           | `cd`, `z` |
| **fd**      | Fast file finder                  | `find`    |
| **ripgrep** | Fast text search                  | `grep`    |

### Optional (Nice to Have)

| Tool      | Purpose             | Replaces |
| --------- | ------------------- | -------- |
| **dust**  | Disk usage analyzer | `du`     |
| **duf**   | Disk free viewer    | `df`     |
| **btop**  | System monitor      | `top`    |
| **delta** | Better git diffs    | `diff`   |
| **gh**    | GitHub CLI          | -        |
| **jq**    | JSON processor      | -        |

### Integrations

| Tool       | Purpose                             | Install Via |
| ---------- | ----------------------------------- | ----------- |
| **atlas**  | Session tracking & state management | npm         |
| **radian** | Enhanced R console (if R installed) | pip         |

### Email (conditional — when `em` dispatcher loaded)

| Tool                     | Level       | Purpose                   | Install Via |
| ------------------------ | ----------- | ------------------------- | ----------- |
| **himalaya**             | required    | Email CLI backend         | brew        |
| **w3m/lynx/pandoc**      | recommended | HTML rendering (any-of)   | brew        |
| **glow**                 | recommended | Markdown rendering        | brew        |
| **email-oauth2-proxy**   | recommended | OAuth2 for Gmail/Outlook  | pip         |
| **terminal-notifier**    | optional    | Desktop notifications     | brew        |
| **claude/gemini**        | conditional | AI backend (per `$FLOW_EMAIL_AI`) | varies |

> This section only appears when `em()` is loaded. Shared deps (fzf, bat, jq) are checked in earlier sections and skipped here.

### ZSH Plugins (via antidote)

| Plugin                  | Purpose                 |
| ----------------------- | ----------------------- |
| **powerlevel10k**       | Modern ZSH prompt theme |
| **autosuggestions**     | Fish-like suggestions   |
| **syntax-highlighting** | Command syntax colors   |
| **completions**         | Extended completions    |

---

## Example Output

### Check Mode (Default)

```text
╭─────────────────────────────────────────────╮
│  🩺 flow-cli Health Check                   │
╰─────────────────────────────────────────────╯

🐚 SHELL
  ✓ zsh          5.9
  ✓ git          2.43.0

⚡ REQUIRED (core functionality)
  ✓ fzf          0.46.0

✨ RECOMMENDED (enhanced experience)
  ✓ eza          0.18.0
  ✓ bat          0.24.0
  ✓ zoxide       0.9.2
  ✓ fd           9.0.0
  ✓ rg           14.1.0

📦 OPTIONAL (nice to have)
  ✓ dust         0.8.6
  ✓ duf          0.8.1
  ✓ btop         1.2.13
  ✓ delta        0.16.5
  ✓ gh           2.40.0
  ✓ jq           1.7

🔌 INTEGRATIONS
  ✓ atlas        1.2.0
  ✓ radian       0.6.7

📧 EMAIL (himalaya)
  ✓ himalaya         1.1.0
    ✓ himalaya version >= 1.0.0
  ✓ w3m              w3m/0.5.3+git20230121  (HTML rendering)
  ✓ glow             2.1.1                  (Markdown rendering)
  ○ email-oauth2-proxy                      pip install email-oauth2-proxy
  ✓ terminal-notifier 2.0.0                 (Desktop notifications)
  ✓ claude           2.1.39                 (AI backend)

  Config:
    AI backend:  claude
    AI timeout:  30s
    Page size:   25
    Folder:      INBOX
    Config file: ~/.config/himalaya/config.toml

🔧 ZSH PLUGINS (via antidote)
  ✓ powerlevel10k
  ✓ autosuggestions
  ✓ syntax-highlighting
  ✓ completions

🌊 FLOW-CLI
  ✓ Plugin loaded    v7.4.1
  ✓ Plugin directory ~/projects/dev-tools/flow-cli

────────────────────────────────────────────────
✅ All dependencies OK!
```text

### With Missing Dependencies

```bash
⚡ REQUIRED (core functionality)
  ✗ fzf          NOT INSTALLED → brew install fzf

✨ RECOMMENDED (enhanced experience)
  ✓ eza          0.18.0
  ✗ bat          NOT INSTALLED → brew install bat
  ✓ zoxide       0.9.2
  ...

────────────────────────────────────────────────
⚠️  Some dependencies are missing

Quick fix options:
  flow doctor --fix       Interactive install (prompts each)
  flow doctor --fix -y    Auto-install all missing
  brew bundle --file=$FLOW_PLUGIN_DIR/setup/Brewfile
```text

---

## Fix Mode

### Interactive Fix (`--fix`)

Prompts before each installation:

```bash
$ flow doctor --fix

Found 3 missing tools:
  1. fzf (required) - brew install fzf
  2. bat (recommended) - brew install bat
  3. dust (optional) - brew install dust

Install fzf? (y/N) y
⏳ Running: brew install fzf
✓ fzf installed successfully

Install bat? (y/N) y
⏳ Running: brew install bat
✓ bat installed successfully

Install dust? (y/N) n
⏸️  Skipped dust

────────────────────────────────────────────────
✅ Installed 2 tools, skipped 1
```text

### Fix Mode with Email (`--fix`)

When email dependencies are missing, the fix menu includes an Email Tools category:

```text
╭─ Select Category to Fix ────────────────────────╮
│                                                  │
│  1. 📦 Missing Tools (2 tools, ~1m)              │
│  2. 📧 Email Tools (3 issues, ~1m 30s)           │
│                                                  │
│  3. ✨ Fix All Categories (~2m 30s)              │
│                                                  │
│  0. Exit without fixing                          │
│                                                  │
╰──────────────────────────────────────────────────╯
```text

Email fix mode installs missing brew packages (himalaya, glow, w3m, terminal-notifier) and pip packages (email-oauth2-proxy). If no himalaya config is found, it offers a guided setup wizard.

### Auto-Fix (`--fix -y`)

Installs all missing without prompts:

```bash
$ flow doctor --fix -y

Auto-installing 3 missing tools...

⏳ brew install fzf...
✓ fzf installed

⏳ brew install bat...
✓ bat installed

⏳ brew install dust...
✓ dust installed

────────────────────────────────────────────────
✅ Installed 3 tools
```bash

---

## Verbose Mode (Email Connectivity)

When the `em` dispatcher is loaded, `--verbose` runs email connectivity tests:

```bash
$ flow doctor --verbose

# ... normal check output ...

📧 EMAIL (himalaya)
  ✓ himalaya         1.1.0
    ✓ himalaya version >= 1.0.0
  ✓ w3m              w3m/0.5.3  (HTML rendering)
  ✓ glow             2.1.1      (Markdown rendering)

  🔗 Connectivity:
    ✓ himalaya config found
    ✓ IMAP connection OK (1 message fetched)
    ⚠ OAuth2 proxy not running
    ✓ SMTP config present
```yaml

Connectivity checks have a 5-second timeout per test (15s max total). All failures are shown as warnings, not errors.

---

## Guided Email Setup

When running `--fix` mode with no himalaya config found, `flow doctor` offers a guided setup wizard:

```bash
$ flow doctor --fix

📧 Email Setup Wizard
No himalaya configuration found.

Email address: user@gmail.com
✓ Detected provider: Gmail

Setting up Gmail with OAuth2...
  IMAP: imap.gmail.com:993
  SMTP: smtp.gmail.com:465

Generated: ~/.config/himalaya/config.toml

Set up OAuth2 proxy for Gmail? (Y/n) y
⏳ Configuring email-oauth2-proxy...
✓ OAuth2 proxy configured

Testing connectivity...
✓ IMAP connection OK
```text

The wizard auto-detects providers (Gmail, Outlook, Yahoo, iCloud) and configures appropriate IMAP/SMTP settings.

---

## AI Mode

Uses Claude CLI for intelligent troubleshooting:

```bash
$ flow doctor --ai

🤖 AI-Assisted Troubleshooting

Analyzing your environment...

Based on your flow-cli installation and missing dependencies,
here are my recommendations:

1. **fzf is required** - This is the core dependency for interactive
   project picking. Install with: brew install fzf

2. **Consider adding radian** - Since you have R installed, radian
   provides a much better console experience with syntax highlighting
   and multiline editing.

3. **Your ZSH plugins look good** - All recommended plugins are installed.

Would you like me to run the installation commands? (y/N)
```bash

---

## Quick Install All

For a complete setup, use the included Brewfile:

```bash
# Install all recommended tools at once
brew bundle --file=~/projects/dev-tools/flow-cli/setup/Brewfile

# Then verify
flow doctor
```diff

---

## Related Commands

| Command        | Purpose                             |
| -------------- | ----------------------------------- |
| `flow help`    | Show all flow-cli commands          |
| `flow version` | Show flow-cli version               |
| `em doctor`    | Email-specific health check         |
| `man flow`     | View man page                       |

---

## Troubleshooting

### Issue: "brew not found"

**Cause:** Homebrew not installed

**Solution:**

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```bash

### Issue: ZSH plugin shows as missing

**Cause:** Plugin not in antidote bundle

**Solution:**

```bash
# Add to ~/.config/zsh/.zsh_plugins.txt
echo "romkatv/powerlevel10k" >> ~/.config/zsh/.zsh_plugins.txt

# Rebuild antidote bundle
antidote bundle < ~/.config/zsh/.zsh_plugins.txt > ~/.config/zsh/.zsh_plugins.zsh
```bash

### Issue: npm packages fail to install

**Cause:** Global npm permissions issue

**Solution:**

```bash
# Use npx instead of global install for atlas
npx @data-wise/atlas --version

# Or fix npm permissions
npm config set prefix ~/.npm-global
export PATH=~/.npm-global/bin:$PATH
```

---

## Source Code

**File:** `commands/doctor.zsh`
**Dependencies:**

- `brew` command (Homebrew)
- `npm` command (optional, for atlas)
- `pip` command (optional, for radian)
- `claude` command (optional, for --ai mode)

**Key Functions:**

- `doctor()` - Main entry point
- `_doctor_check_cmd()` - Check individual command
- `_doctor_check_zsh_plugin()` - Check ZSH plugin
- `_doctor_install()` - Install missing tool
- `_doctor_check_email()` - Check all email dependencies (conditional on `em()`)
- `_doctor_check_email_cmd()` - Check individual email command with level tracking
- `_doctor_email_connectivity()` - IMAP/SMTP/OAuth2 connectivity tests (verbose mode)
- `_doctor_email_setup()` - Guided himalaya config wizard (fix mode)
- `_doctor_fix_email()` - Install missing email packages (fix mode)
- `_doctor_help()` - Display help

---

## Design Philosophy

The `doctor` command follows these principles:

1. **Non-Destructive** - Check mode is read-only, fix mode requires explicit flag
2. **Categorized** - Clear distinction between required/recommended/optional
3. **Progressive** - Start with check, graduate to fix if needed
4. **Multi-Manager** - Supports Homebrew, npm, and pip package managers
5. **AI-Augmented** - Optional Claude integration for smart troubleshooting
6. **Conditional** - Email section only appears when `em` dispatcher is loaded

---

## See Also

- [Setup Guide](../getting-started/quick-start.md) - First-time setup
- [Brewfile](https://github.com/Data-Wise/flow-cli/blob/main/setup/Brewfile) - All recommended tools
- [DISPATCHER-REFERENCE.md](../reference/MASTER-DISPATCHER-GUIDE.md) - Command reference
- [Email Dispatcher Guide](../guides/EMAIL-DISPATCHER-GUIDE.md) - Email workflow docs
- [Email Dispatcher Refcard](../reference/REFCARD-EMAIL-DISPATCHER.md) - Email quick reference

---

**Last Updated:** 2026-02-12
**Command Version:** v7.4.1 (doctor v2.0 — email integration)
**Status:** ✅ Production ready with interactive install + email diagnostics
