# ZSH Commands Help Standard

> **TL;DR:** Consistent help output for all shell commands. Every command gets `--help`, every function gets a usage message.

---

## Quick Reference

```bash
# Every command should support:
mycommand --help      # Full help
mycommand -h          # Same as --help
mycommand help        # Subcommand style (for dispatchers)

# Every function should show usage on:
myfunction            # No args (if args required)
myfunction --help     # Explicit help request
```

---

## Standard Help Format

### Minimal (Simple Commands)

```
Usage: command [options] <required> [optional]

Description of what the command does.

Options:
  -h, --help    Show this help
  -v, --verbose Verbose output
```

### Full (Complex Commands)

```
Usage: command [options] <subcommand> [args]

One-line description of the command.

Subcommands:
  view      View the resource
  edit      Edit the resource
  delete    Remove the resource

Options:
  -h, --help     Show this help
  -v, --verbose  Verbose output
  -q, --quiet    Suppress output

Examples:
  command view myfile        # View a file
  command edit -v myfile     # Edit with verbose output
  command delete myfile      # Delete a file

See also: related-command, other-command
```

---

## Implementation Patterns

### Pattern 1: Simple Function

```zsh
myfunction() {
    emulate -L zsh

    # Help handling
    if [[ "$1" == "-h" || "$1" == "--help" || -z "$1" ]]; then
        cat <<'EOF'
Usage: myfunction <name>

Does something useful with the given name.

Examples:
  myfunction foo    # Process foo
  myfunction bar    # Process bar
EOF
        return 0
    fi

    local name="$1"
    # ... actual implementation
}
```

### Pattern 2: With Subcommands

```zsh
mycommand() {
    emulate -L zsh
    local cmd="${1:-help}"

    case "$cmd" in
        -h|--help|help)
            cat <<'EOF'
Usage: mycommand <subcommand> [args]

Manages resources.

Subcommands:
  view <name>     View a resource
  edit <name>     Edit a resource
  list            List all resources
  help            Show this help

Examples:
  mycommand view foo
  mycommand list
EOF
            ;;
        view)
            shift
            _mycommand_view "$@"
            ;;
        edit)
            shift
            _mycommand_edit "$@"
            ;;
        list)
            _mycommand_list
            ;;
        *)
            echo "Unknown subcommand: $cmd" >&2
            echo "Run 'mycommand help' for usage" >&2
            return 1
            ;;
    esac
}
```

### Pattern 3: Dispatcher Function

```zsh
# Main dispatcher
d() {
    emulate -L zsh
    local cmd="${1:-help}"
    shift 2>/dev/null

    case "$cmd" in
        -h|--help|help|"")
            _d_help
            ;;
        sub1) _d_sub1 "$@" ;;
        sub2) _d_sub2 "$@" ;;
        *)
            echo "d: unknown command '$cmd'" >&2
            echo "Run 'd help' for available commands" >&2
            return 1
            ;;
    esac
}

# Separate help function for cleaner code
_d_help() {
    cat <<'EOF'
Usage: d <command> [args]

Project dispatcher for common tasks.

Commands:
  sub1 [args]    Description of sub1
  sub2 [args]    Description of sub2
  help           Show this help

Examples:
  d sub1 foo
  d sub2 --verbose

Aliases: d1 → d sub1, d2 → d sub2
EOF
}
```

### Pattern 4: With Options Parsing

```zsh
mycommand() {
    emulate -L zsh

    local verbose=0
    local quiet=0
    local output=""

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                _mycommand_help
                return 0
                ;;
            -v|--verbose)
                verbose=1
                shift
                ;;
            -q|--quiet)
                quiet=1
                shift
                ;;
            -o|--output)
                output="$2"
                shift 2
                ;;
            --)
                shift
                break
                ;;
            -*)
                echo "Unknown option: $1" >&2
                echo "Run 'mycommand --help' for usage" >&2
                return 1
                ;;
            *)
                break
                ;;
        esac
    done

    # ... rest of implementation
}

_mycommand_help() {
    cat <<'EOF'
Usage: mycommand [options] <input>

Processes input files.

Options:
  -h, --help        Show this help
  -v, --verbose     Verbose output
  -q, --quiet       Suppress output
  -o, --output FILE Write output to FILE

Examples:
  mycommand input.txt
  mycommand -v -o out.txt input.txt
EOF
}
```

---

## Help Content Guidelines

### Required Elements

1. **Usage line** — Shows syntax
2. **Description** — One line explaining purpose
3. **At least one example** — Copy-paste ready

### Recommended Elements

4. **Options section** — If any flags exist
5. **Subcommands section** — If dispatcher-style
6. **See also** — Related commands

### Style Rules

| Rule | Good | Bad |
|------|------|-----|
| Align descriptions | `-v, --verbose  Show more` | `-v, --verbose Show more` |
| Use consistent verbs | "Show", "Create", "Delete" | "Shows", "Creating", "Removes" |
| Examples use `#` comments | `cmd foo  # do thing` | `cmd foo (does thing)` |
| Required args in `<>` | `<file>` | `file` or `FILE` |
| Optional args in `[]` | `[options]` | `(options)` |

---

## Error Messages

### Standard Error Format

```zsh
# For invalid arguments
echo "mycommand: missing required argument <name>" >&2
echo "Run 'mycommand --help' for usage" >&2
return 1

# For invalid options
echo "mycommand: unknown option '$1'" >&2
echo "Run 'mycommand --help' for usage" >&2
return 1

# For invalid subcommands
echo "mycommand: unknown command '$cmd'" >&2
echo "Run 'mycommand help' for available commands" >&2
return 1
```

### Pattern: Validation Function

```zsh
_require_arg() {
    local cmd="$1"
    local arg_name="$2"
    local arg_value="$3"

    if [[ -z "$arg_value" ]]; then
        echo "$cmd: missing required argument <$arg_name>" >&2
        echo "Run '$cmd --help' for usage" >&2
        return 1
    fi
}

# Usage:
mycommand() {
    _require_arg "mycommand" "file" "$1" || return 1
    # ...
}
```

---

## Testing Help Output

### Checklist

```bash
# Every command should pass these tests:
mycommand --help          # Shows help, exits 0
mycommand -h              # Same as --help
mycommand help            # For dispatcher-style
mycommand                 # Shows help if args required, OR works if no args needed
mycommand --invalid       # Shows error + hint, exits 1
```

### Automated Test Pattern

```zsh
test_help_output() {
    local cmd="$1"

    # Should exit 0 and contain "Usage:"
    local output
    output=$($cmd --help 2>&1)
    local status=$?

    [[ $status -eq 0 ]] || { echo "FAIL: $cmd --help exited $status"; return 1; }
    [[ "$output" == *"Usage:"* ]] || { echo "FAIL: $cmd --help missing Usage:"; return 1; }

    echo "PASS: $cmd --help"
}
```

---

## Migration Guide

### Adding Help to Existing Functions

1. **Identify the function type:**
   - Simple (no subcommands) → Pattern 1
   - Dispatcher (subcommands) → Pattern 2 or 3
   - Complex options → Pattern 4

2. **Add help handling at the top:**
   ```zsh
   # Add this as first thing in function
   if [[ "$1" == "-h" || "$1" == "--help" ]]; then
       # help output
       return 0
   fi
   ```

3. **Update error messages:**
   ```zsh
   # Change this:
   echo "Error: invalid input"

   # To this:
   echo "mycommand: invalid input '$1'" >&2
   echo "Run 'mycommand --help' for usage" >&2
   ```

---

## Examples from This Project

### hub-commands.zsh

```zsh
hub() {
    local cmd="${1:-view}"

    case "$cmd" in
        -h|--help|help)
            cat <<'EOF'
Usage: hub [subcommand]

Navigate the master project hub.

Subcommands:
  view (v)    Display PROJECT-HUB.md (default)
  edit (e)    Open in editor
  open (o)    Open in Finder
  cd (c)      Change to hub directory

Examples:
  hub         # View dashboard
  hub edit    # Edit dashboard
  hub cd      # Go to hub directory
EOF
            return 0
            ;;
        view|v) cat "$HUB_PROJECT_HUB/PROJECT-HUB.md" ;;
        edit|e) ${EDITOR:-vim} "$HUB_PROJECT_HUB/PROJECT-HUB.md" ;;
        open|o) open "$HUB_PROJECT_HUB" ;;
        cd|c)   cd "$HUB_PROJECT_HUB" ;;
        *)
            echo "hub: unknown subcommand '$cmd'" >&2
            echo "Run 'hub --help' for usage" >&2
            return 1
            ;;
    esac
}
```

---

## Checklist for New Commands

- [ ] `--help` and `-h` both work
- [ ] Help shows `Usage:` line
- [ ] Help includes at least one example
- [ ] Invalid args show error + "Run 'cmd --help' for usage"
- [ ] Exit codes: 0 for success/help, 1 for errors
- [ ] Help fits in 80 columns
- [ ] Descriptions use consistent verb tense
