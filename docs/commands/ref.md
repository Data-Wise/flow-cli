# ref

> Quick-reference card viewer for commands and workflows

The `ref` command displays flow-cli's quick-reference cards directly in your terminal — no need to open a browser or find the docs directory. It renders `docs/reference/COMMAND-QUICK-REFERENCE.md` or `docs/reference/WORKFLOW-QUICK-REFERENCE.md` using the best available viewer (`bat`, `glow`, or `less`).

---

## Usage

```bash
ref [type]
```

## Commands

| Command             | Alias           | Description                          |
| -------------------- | ---------------- | ------------------------------------- |
| `ref` / `ref command` | `ref cmd`, `ref c` | Show command quick reference (default) |
| `ref workflow`        | `ref work`, `ref w` | Show workflow quick reference          |
| `ref help`             | `-h`               | Show help                              |

Any unrecognized argument falls back to the command reference (the default).

---

## Examples

### Command Reference (Default)

```bash
# Quick lookup of all commands
ref

# Same, explicit
ref command
ref cmd
ref c
```

### Workflow Reference

```bash
# See common workflows
ref workflow
ref work
ref w
```

### Help

```bash
ref help
ref -h
```

---

## How It Resolves the Reference File

`ref` locates the flow-cli plugin root via `$FLOW_PLUGIN_DIR` (falling back to the script's own location if unset), then reads:

- `docs/reference/COMMAND-QUICK-REFERENCE.md` — for `command`/`cmd`/`c` (and the default)
- `docs/reference/WORKFLOW-QUICK-REFERENCE.md` — for `workflow`/`work`/`w`

If the resolved file doesn't exist, `ref` prints an error with the full path it looked for and returns a non-zero exit code.

---

## Display Tool Fallback

`ref` picks the best available renderer, in this order:

1. **`bat`** — syntax-highlighted, paged (`--style=plain --paging=always --language=markdown`)
2. **`glow`** — rendered markdown (`glow -p`)
3. **`less`** — plain paging of the raw file
4. **`cat`** — last resort if `less` isn't available either

No extra configuration needed — install `bat` or `glow` via Homebrew for a nicer view; `ref` works without either.

---

## Related Commands

| Command                 | Description                     |
| ------------------------ | -------------------------------- |
| `flow help`               | Full help system                 |
| `<cmd> help`               | Command-specific help            |
| [`dash`](dash.md)         | Project dashboard                |
| [`doctor`](doctor.md)     | System-wide health check         |

---

## See Also

- [Master Dispatcher Guide](../reference/MASTER-DISPATCHER-GUIDE.md)
- `docs/reference/COMMAND-QUICK-REFERENCE.md`
- `docs/reference/WORKFLOW-QUICK-REFERENCE.md`

---

**Last Updated:** 2026-07-02
**Status:** Implemented in `commands/ref.zsh`
