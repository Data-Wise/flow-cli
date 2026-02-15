# Migration Guide: dot → dots / sec / tok

> **Version:** v7.1.0 | **Breaking Change:** Yes (clean break, no aliases)

## What Changed

The monolithic `dot` dispatcher (4,395 lines, 70+ functions) has been split into 3 focused dispatchers:

| Old Command | New Dispatcher | Purpose |
|-------------|----------------|---------|
| `dot status`, `dot edit`, `dot sync`, `dot push` | **`dots`** | Dotfile management |
| `dot unlock`, `dot secret list`, `dot secrets` | **`sec`** | Secret management |
| `dot token github`, `dot token rotate` | **`tok`** | Token management |

## Quick Migration

### Dotfiles (dots)

```bash
# Before                    # After
dot status                  dots status
dot edit .zshrc             dots edit .zshrc
dot add ~/.config/nvim      dots add ~/.config/nvim
dot sync                    dots sync
dot push                    dots push
dot diff                    dots diff
dot apply                   dots apply
dot ignore add "*.log"      dots ignore add "*.log"
dot size                    dots size
dot doctor                  dots doctor
dot env init                dots env init
dot init                    dots init
dot undo                    dots undo
```

### Secrets (sec)

```bash
# Before                    # After
dot unlock                  sec unlock
dot lock                    sec lock
dot secret GITHUB_TOKEN     sec GITHUB_TOKEN
dot secret list             sec list
dot secret add KEY VALUE    sec add KEY VALUE
dot secret delete KEY       sec delete KEY
dot secret check            sec check
dot secret status           sec status
dot secret tutorial         sec tutorial
dot secrets                 sec dashboard
dot secrets sync github     sec sync github
```

### Tokens (tok)

```bash
# Before                    # After
dot token github            tok github
dot token npm               tok npm
dot token pypi              tok pypi
dot token rotate            tok rotate
dot token refresh           tok refresh
dot token expiring          tok expiring
```

## What Stayed the Same

- **`flow doctor --dot`** flag works unchanged
- **macOS Keychain** service name (`flow-cli`) unchanged — no secret re-entry needed
- **Bitwarden** vault integration unchanged
- **Tab completion** available for all 3 dispatchers (`_dots`, `_sec`, `_tok`)
- **Help** via `dots help`, `sec help`, `tok help`

## Shell Configuration Updates

If you have aliases or functions referencing `dot`, update them:

```zsh
# Before
alias ds="dot status"
alias du="dot unlock"
alias dtg="dot token github"

# After
alias ds="dots status"
alias du="sec unlock"
alias dtg="tok github"
```

## Scripts and Automation

If you have scripts that call `dot` subcommands, update them:

```bash
# Before
dot unlock && dot secret DEPLOY_KEY | pbcopy

# After
sec unlock && sec DEPLOY_KEY | pbcopy
```

## Why the Split?

1. **Faster help discovery** — `tok help` shows only token commands (not 70+ entries)
2. **Shorter commands** — `sec list` vs `dot secret list`
3. **Cleaner architecture** — each dispatcher is ~1,500 lines instead of one 4,400-line file
4. **Independent evolution** — token features can grow without bloating dotfile management

## Troubleshooting

### "command not found: dots"

Ensure you're on flow-cli v7.1.0+:

```bash
flow --version
```

If using a plugin manager, update the plugin. If installed via Homebrew:

```bash
brew upgrade flow-cli
```

### "command not found: dot" (expected)

The old `dot` command no longer exists. Use `dots`, `sec`, or `tok` instead. See the mapping table above.

### Completions not working

Re-source your shell or restart the terminal:

```bash
exec zsh
```
