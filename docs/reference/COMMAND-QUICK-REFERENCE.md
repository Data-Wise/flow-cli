# Command Quick Reference (ADHD-Friendly)

> **Pattern:** `command + keyword + options`
> **Philosophy:** One command per domain, discoverable with `help`

---

## Dispatchers

### R Package Development: `r`

```bash
r                   # R console (radian)
r test              # Run tests
r doc               # Document package
r check             # Check package
r build             # Build package
r cycle             # Full cycle: doc → test → check
r quick             # Quick: load → test
r cov               # Coverage report
r cran              # CRAN check
r help              # Show all commands
```

### Git: `g`

```bash
g                   # Status (short)
g status            # Full status
g add .             # Stage all
g commit "msg"      # Commit with message
g push              # Push to remote
g pull              # Pull from remote
g log               # Pretty log (20 lines)
g branch            # List branches
g checkout <b>      # Switch branch
g stash             # Stash changes
g stash pop         # Pop stash
g undo              # Undo last commit (keep changes)
g help              # Show all commands
```

### Quarto: `qu`

```bash
qu                  # Show help
qu preview          # Live preview
qu render           # Render document
qu check            # Check installation
qu clean            # Remove build artifacts
qu new <name>       # Create new project
qu help             # Show all commands
```

### Workflow Automation: `v` / `vibe`

```bash
v                   # Show help
v test              # Run tests (context-aware)
v dash              # Dashboard
v coord             # Coordination
v plan              # Planning
v status            # Project status
v help              # Show all commands
vibe test           # Full name also works
```

### AI Tools: `cc` / `gm`

```bash
cc                  # Claude Code
cc --continue       # Continue conversation
gm                  # Gemini
gm help             # Gemini help
```

---

## Workflow Functions

### Session Management

```bash
work <project>      # Start work session
finish [msg]        # End session (commit + push)
here                # Quick context (pwd + status + ls)
```

### Project Operations

```bash
pb                  # Build (auto-detects type)
pv                  # Preview/view
pt                  # Test
pick                # FZF picker
dash                # Master dashboard
```

### Teaching

```bash
tst                 # Teaching status
tweek               # Current week
tlec [N]            # Open lecture N
tpublish            # Deploy to GitHub Pages
```

### Research

```bash
rst                 # Research status
rms                 # Open manuscript
rsim                # Run simulation
```

---

## Utility Aliases

```bash
..                  # cd ..
...                 # cd ../..
ll                  # Long listing (eza)
la                  # All files
reload              # Reload zshrc
```

---

## Pattern Summary

| Domain    | Command | Pattern              |
| --------- | ------- | -------------------- |
| R Package | `r`     | `r <action> [args]`  |
| Git       | `g`     | `g <action> [args]`  |
| Quarto    | `qu`    | `qu <action> [args]` |
| Workflow  | `v`     | `v <action> [args]`  |
| Claude    | `cc`    | Direct or with flags |
| Gemini    | `gm`    | Direct or with flags |

**Get help:** Any dispatcher + `help` (e.g., `r help`, `g help`)

---

## Files

| File                                            | Purpose                   |
| ----------------------------------------------- | ------------------------- |
| `~/.config/zsh/functions/smart-dispatchers.zsh` | r, qu, cc, gm dispatchers |
| `~/.config/zsh/functions/v-dispatcher.zsh`      | v/vibe dispatcher         |
| `~/.config/zsh/functions/g-dispatcher.zsh`      | g (git) dispatcher        |
| `~/.config/zsh/functions/adhd-helpers.zsh`      | work, dash, pb, pv, pt    |

---

_Updated: 2025-12-17_
