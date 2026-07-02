# setup

> Interactive first-time setup wizard

The `setup` command walks you through getting flow-cli fully configured — checking for recommended tools, offering to install anything missing, and verifying core environment variables. It's the ADHD-friendly on-ramp for new installs.

---

## Usage

```bash
setup [option]
```

## Options

| Option        | Description                          |
| ------------- | ------------------------------------- |
| *(none)*      | Interactive wizard (default)          |
| `-q, --quick` | Quick non-interactive install         |
| `-f, --full`  | Full setup with all options           |
| `-h, --help`  | Show help                             |

**Alias:** `flow-setup` (same as `setup`)

---

## Examples

```bash
# Interactive wizard
setup

# Auto-install everything, no prompts
setup --quick

# Full setup + optional extras
setup --full

# Help
setup --help
```

---

## Interactive Mode (default)

`setup` (no arguments) runs a four-step wizard:

### Step 1 — Health Check

Checks for six recommended CLI tools: `fzf`, `eza`, `bat`, `fd`, `rg` (ripgrep), `zoxide`. If all are already installed, the wizard exits early with a success message and suggests running `dash`.

### Step 2 — Install Tools (only if tools are missing)

Presents three choices:

1. **Install all recommended tools (Homebrew)** — runs `brew bundle` against `setup/Brewfile` if present, otherwise installs each missing tool individually via `brew install`.
2. **Choose which tools to install** — walks through each of the six tools one at a time, showing what's already installed and prompting `y/N` to install what's missing.
3. **Skip for now** — leaves tools as-is; you can re-run `setup` anytime.

If Homebrew itself isn't installed, `setup` reports that and shows the official install command instead of attempting to install tools.

### Step 3 — Configuration

Checks two things and reports pass/fail for each:

- `$FLOW_PROJECTS_ROOT` is set (shows the export line to add to `.zshrc` if not)
- flow-cli is actually loaded (checks `$FLOW_PLUGIN_LOADED` and reports the version)

### Step 4 — Next Steps

Prints a short list of commands to try next: `dash`, `work <name>`, `doctor`, `flow help`.

---

## Quick Mode (`--quick` / `-q`)

Skips all prompts and runs `doctor --fix -y` directly — the non-interactive equivalent of "just fix everything you can."

```bash
setup --quick
```

---

## Full Mode (`--full` / `-f`)

Runs the full interactive wizard (Steps 1–4 above), then shows an additional "Additional Configuration" section listing optional integrations:

- `npm install -g @data-wise/atlas` — enhanced state management
- `pip install radian` — better R console

```bash
setup --full
```

---

## What Gets Installed

| Tool      | Purpose                                             |
| --------- | ---------------------------------------------------- |
| `fzf`     | Fuzzy finder (**required** for the project picker)   |
| `eza`     | Modern `ls` replacement (prettier file listings)     |
| `bat`     | `cat` with syntax highlighting                       |
| `fd`      | Fast `find` replacement                              |
| `ripgrep` | Fast `grep` replacement (binary: `rg`)               |
| `zoxide`  | Smart `cd` with history                              |

---

## Related Commands

| Command                | Description                        |
| ------------------------ | ------------------------------------ |
| [`doctor`](doctor.md)    | System-wide health check             |
| [`tutorial`](tutorial.md) | Interactive hands-on tutorial       |
| [`dash`](dash.md)         | Project dashboard                    |
| [`work`](work.md)         | Start a focused work session         |

---

## See Also

- [Master Dispatcher Guide](../reference/MASTER-DISPATCHER-GUIDE.md)

---

**Last Updated:** 2026-07-02
**Status:** Implemented in `commands/setup.zsh`
