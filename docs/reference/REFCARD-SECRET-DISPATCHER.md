# Secret Dispatcher Quick Reference

> All `sec` subcommands at a glance.
>
> **Version:** v7.6.0 (v3.0.0 dispatcher) | **Dispatcher:** `lib/dispatchers/sec-dispatcher.zsh`
>
> **Backends:** macOS Keychain (primary), Bitwarden (optional secondary).

## Commands

### Core Operations

| Command | Aliases | Description |
|---------|---------|-------------|
| `sec <name>` | — | Get secret by name (shortcut for `sec get`) |
| `sec list` | `ls` | List all Keychain secrets |
| `sec get <name>` | — | Retrieve a secret value |
| `sec add <name>` | `new` | Add secret to Keychain (interactive prompt) |
| `sec delete <name>` | `rm`, `remove` | Delete secret from Keychain |
| `sec check` | — | Check for expiring secrets |
| `sec status` | — | Show backend configuration and health |
| `sec help` | `-h` | Show help |

### Bitwarden Integration

| Command | Aliases | Description |
|---------|---------|-------------|
| `sec unlock` | `u` | Unlock Bitwarden vault |
| `sec lock` | `l` | Lock Bitwarden vault |
| `sec bw <name>` | — | Get secret from Bitwarden |
| `sec sync` | — | Sync secrets between Keychain and Bitwarden |
| `sec import` | — | Import secrets from Keychain to managed config |

### Diagnostics

| Command | Aliases | Description |
|---------|---------|-------------|
| `sec dashboard` | — | Secrets dashboard (overview of all managed secrets) |
| `sec doctor` | `dr` | Secret-specific health diagnostics |

## Quick Examples

```bash
# Get a secret (shortest form)
sec GITHUB_TOKEN

# List all managed secrets
sec list

# Add a new secret
sec add API_KEY
# [Prompted for value securely]

# Check for expiring tokens
sec check

# Show secrets dashboard
sec dashboard

# Run diagnostics
sec doctor
```

## Bitwarden Workflows

```bash
# Unlock vault
sec unlock
# [Touch ID or master password]

# Get secret from Bitwarden
sec bw DEPLOY_KEY

# Sync Keychain ↔ Bitwarden
sec sync

# Lock when done
sec lock
```

## Common Workflows

### Token Rotation

```bash
sec check                    # Find expiring tokens
sec delete OLD_TOKEN         # Remove old
sec add NEW_TOKEN            # Add replacement
sec check                    # Verify
```

### CI/CD Secret Setup

```bash
sec list                     # See what's available
sec DEPLOY_KEY               # Get value for CI config
sec dashboard                # Overview of all secrets
```

## See Also

- [DOT-WORKFLOW.md](../guides/DOT-WORKFLOW.md) — Keychain and Bitwarden integration
- [MASTER-DISPATCHER-GUIDE.md](MASTER-DISPATCHER-GUIDE.md#sec-dispatcher)
- [Tutorial 23: Token Automation](../tutorials/23-token-automation.md)

---

**Version:** v7.6.0
**Last Updated:** 2026-02-27
