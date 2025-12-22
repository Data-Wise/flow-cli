# Help Creation & Update Workflow

> **TL;DR:** Step-by-step process for creating and updating help commands in ZSH functions.

---

## Quick Decision Tree

```
New function? → Follow "Creating New Help"
Existing function needs help? → Follow "Adding Help to Existing Function"
Updating help text? → Follow "Updating Existing Help"
Help not working? → Follow "Testing & Debugging"
```

---

## Creating New Help (From Scratch)

### Step 1: Identify Function Type

Choose your pattern based on function complexity:

| Type | Pattern | Example |
|------|---------|---------|
| Simple (no subcommands) | Pattern 1 | `rload`, `rtest` |
| With subcommands | Pattern 2/3 | `dash`, `work` |
| With complex options | Pattern 4 | Functions with `-v`, `-q`, etc. |

### Step 2: Copy Template

**For Simple Functions (Pattern 1):**

```zsh
myfunction() {
    emulate -L zsh

    # Help handling (ALWAYS FIRST!)
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

**For Dispatcher Functions (Pattern 3):**

```zsh
mycommand() {
    emulate -L zsh
    local cmd="${1:-help}"

    case "$cmd" in
        -h|--help|help)
            _mycommand_help
            ;;
        sub1) shift; _mycommand_sub1 "$@" ;;
        sub2) shift; _mycommand_sub2 "$@" ;;
        *)
            echo "mycommand: unknown command '$cmd'" >&2
            echo "Run 'mycommand help' for usage" >&2
            return 1
            ;;
    esac
}

_mycommand_help() {
    cat <<'EOF'
Usage: mycommand <command> [args]

Project dispatcher for common tasks.

Commands:
  sub1 [args]    Description of sub1
  sub2 [args]    Description of sub2
  help           Show this help

Examples:
  mycommand sub1 foo
  mycommand sub2 --verbose

See also: related-cmd, other-cmd
EOF
}
```

### Step 3: Customize Content

Follow these guidelines:

1. **Usage line** — Show actual syntax
   - Use `<required>` for required args
   - Use `[optional]` for optional args
   - Example: `mycommand [options] <input> [output]`

2. **Description** — One clear sentence
   - Use present tense: "Processes files" not "Process files"
   - Be specific: "Runs R package tests" not "Runs tests"

3. **Examples** — At least one, copy-paste ready
   - Add `#` comments explaining what it does
   - Show common use cases first
   - Example: `mycommand foo.txt  # Process foo.txt`

4. **See also** (optional) — Related commands
   - List 2-4 related commands
   - Example: `See also: othercommand, relatedcommand`

### Step 4: Test the Help

Run the checklist (see "Testing & Debugging" section below).

---

## Adding Help to Existing Function

### Workflow

1. **Read the function** to understand what it does
   ```bash
   bat ~/.config/zsh/functions/myfunction.zsh
   ```

2. **Identify function type** (Simple/Dispatcher/Complex)

3. **Add help handling at the TOP** (before any logic):
   ```zsh
   # For simple functions
   if [[ "$1" == "-h" || "$1" == "--help" ]]; then
       cat <<'EOF'
   [help text here]
   EOF
       return 0
   fi
   ```

4. **Write help content** following standards (see Step 3 above)

5. **Update error messages** to reference help:
   ```zsh
   # Change this:
   echo "Error: missing argument"

   # To this:
   echo "myfunction: missing required argument <name>" >&2
   echo "Run 'myfunction --help' for usage" >&2
   return 1
   ```

6. **Test** (see "Testing & Debugging" below)

---

## Updating Existing Help

### Workflow

1. **Find the help function**:
   ```bash
   # If help is inline
   grep -A 20 "cat <<'EOF'" ~/.config/zsh/functions/myfunction.zsh

   # If help is in separate function
   grep -A 30 "_myfunction_help" ~/.config/zsh/functions/myfunction.zsh
   ```

2. **Make your changes** following standards:
   - Add new examples for new features
   - Update usage line if signature changed
   - Update subcommands list if added/removed subcommands

3. **Maintain formatting**:
   - Keep alignment consistent
   - Use 2 spaces for option descriptions
   - Keep examples with `#` comments

4. **Test the changes**:
   ```bash
   source ~/.config/zsh/functions/myfunction.zsh
   myfunction --help
   ```

---

## Testing & Debugging

### Standard Test Checklist

Run these tests for **every** help command:

```bash
# 1. Help works with --help
mycommand --help
# Expected: Shows help, exits 0

# 2. Help works with -h
mycommand -h
# Expected: Same as --help

# 3. Help works with 'help' subcommand (for dispatchers)
mycommand help
# Expected: Shows help, exits 0

# 4. No args behavior (if args required)
mycommand
# Expected: Shows help OR shows error + hint

# 5. Invalid option shows hint
mycommand --invalid-option
# Expected: Error message + "Run 'mycommand --help' for usage"

# 6. Invalid subcommand shows hint (for dispatchers)
mycommand invalid-subcommand
# Expected: Error message + "Run 'mycommand help' for usage"
```

### Verification Script

```bash
# Quick test helper
test-help() {
    local cmd="$1"

    echo "Testing: $cmd --help"
    if $cmd --help 2>&1 | grep -q "Usage:"; then
        echo "✅ Help works"
    else
        echo "❌ Help missing or broken"
    fi

    echo "Testing: $cmd -h"
    if $cmd -h 2>&1 | grep -q "Usage:"; then
        echo "✅ -h alias works"
    else
        echo "❌ -h alias broken"
    fi
}

# Usage:
test-help dash
test-help work
```

### Common Issues & Fixes

| Problem | Cause | Fix |
|---------|-------|-----|
| Help doesn't show | Help check not first | Move help check to top of function |
| Colors don't work | Not using `echo -e` | Change to `echo -e` or use `cat` |
| Alignment broken | Tab vs space mixing | Use spaces consistently |
| No newline at end | Missing echo after heredoc | Add `echo ""` or blank line in heredoc |
| Help shows in error cases | No `return 0` after help | Add `return 0` after help output |

---

## File Organization

### Where to Put Help Files

| Content Type | Location |
|--------------|----------|
| Function with inline help | Same file as function |
| Separate help function | Same file, prefixed with `_` |
| Shared help utilities | `~/.config/zsh/functions/help-utils.zsh` |
| Help text files (if long) | `~/.config/zsh/help/command-name.txt` |

### Example File Structure

```
~/.config/zsh/functions/
├── dash.zsh                 # Function with _dash_help() inside
├── work.zsh                 # Function with _work_help() inside
├── timer.zsh                # Function with inline help
└── help-utils.zsh           # Shared formatting helpers
```

---

## Documentation Workflow

After creating/updating help:

### 1. Update User Documentation

If adding new command or major changes:

```bash
# Add to quick reference
vim ~/projects/dev-tools/flow-cli/docs/user/WORKFLOW-QUICK-REFERENCE.md

# Add to alias reference (if aliased)
vim ~/projects/dev-tools/flow-cli/docs/user/ALIAS-REFERENCE-CARD.md

# Add to dashboard reference (if dashboard command)
vim ~/projects/dev-tools/flow-cli/docs/user/DASHBOARD-QUICK-REF.md
```

### 2. Update Standards if Needed

If you created new pattern or improved workflow:

```bash
# Update the standard
vim ~/projects/dev-tools/flow-cli/standards/code/ZSH-COMMANDS-HELP.md

# Document the workflow improvement
vim ~/projects/dev-tools/flow-cli/standards/workflow/HELP-CREATION-WORKFLOW.md
```

### 3. Commit Changes

```bash
cd ~/.config/zsh
git add functions/mycommand.zsh
git commit -m "docs: add help to mycommand

- Added --help and -h support
- Included usage examples
- Updated error messages to reference help

Follows standards/code/ZSH-COMMANDS-HELP.md Pattern 3"
```

---

## ADHD-Friendly Enhancements (Optional)

Consider adding these enhancements:

### 1. Visual Hierarchy

```zsh
echo ""
echo -e "${BOLD}╭─────────────────────────────────────────────╮${NC}"
echo -e "${BOLD}│ dash - Master Dashboard                     │${NC}"
echo -e "${BOLD}╰─────────────────────────────────────────────╯${NC}"
echo ""
```

### 2. Color Coding

```zsh
local GREEN='\033[0;32m'
local CYAN='\033[0;36m'
local YELLOW='\033[1;33m'
local NC='\033[0m'

echo -e "${GREEN}🔥 USAGE${NC}:"
echo -e "  ${CYAN}command${NC}    Description"
```

### 3. Icons for Scanning

```zsh
echo "🔥 Most Common:"
echo "💡 Examples:"
echo "📚 See Also:"
```

---

## Quick Reference Card Template

For commands with many options, create a separate quick reference:

**File:** `docs/user/COMMAND-QUICK-REF.md`

```markdown
# Command Quick Reference

## TL;DR
[One sentence what it does]

## Most Common (90% Use Cases)
- `command action` — [What it does]
- `command action2` — [What it does]

## All Commands
[Full reference table]

## Examples
[Copy-paste ready examples]
```

See existing example: [DASHBOARD-QUICK-REF.md](docs/user/DASHBOARD-QUICK-REF.md)

---

## Checklist: New Command Complete

- [ ] Function has help handling (-h, --help work)
- [ ] Help includes Usage line
- [ ] Help includes at least one example
- [ ] Error messages reference help
- [ ] All tests pass (6 tests from checklist)
- [ ] User docs updated (if needed)
- [ ] Git commit created
- [ ] Help fits in 80 columns
- [ ] Consistent verb tense in descriptions

---

## See Also

- [ZSH-COMMANDS-HELP.md](../code/ZSH-COMMANDS-HELP.md) — Detailed standards and patterns
- [REFCARD-TEMPLATE.md](../adhd/REFCARD-TEMPLATE.md) — Quick reference card template
- [DASHBOARD-QUICK-REF.md](../../docs/user/DASHBOARD-QUICK-REF.md) — Example reference doc

---

**Last Updated:** 2025-12-20
**Maintainer:** DT
