# ZSH Development Guidelines

**Last Updated:** 2025-12-19
**Purpose:** Best practices and anti-patterns for DT's ZSH configuration

---

## Table of Contents

1. [Interactive vs Programmatic Functions](#interactive-vs-programmatic-functions)
2. [Command Substitution Anti-Patterns](#command-substitution-anti-patterns)
3. [Alias vs Function Naming](#alias-vs-function-naming)
4. [Output Redirection Best Practices](#output-redirection-best-practices)
5. [Testing Requirements](#testing-requirements)

---

## Interactive vs Programmatic Functions

### Rule: Don't Mix Interactive UI with Return Values

**Interactive functions** are designed for direct user interaction:

- Display UI elements (headers, boxes, colors)
- Use tools like `fzf`, `select`, `read`
- Have side effects (change directory, modify files)
- Print status messages to stdout

**Programmatic functions** are designed to return values:

- Output only the return value to stdout
- Send all messages to stderr
- Can be captured with `$()`
- No user interaction

### Anti-Pattern: Capturing Interactive Function Output

```zsh
# ❌ WRONG - Don't do this!
my_interactive_picker() {
    echo "╔════════════════════════╗"
    echo "║  PROJECT PICKER        ║"
    echo "╚════════════════════════╝"
    local selection=$(fzf < project_list.txt)
    cd "$selection"
    echo "📂 Changed to: $selection"
}

# Later in code...
local dir=$(my_interactive_picker)  # Gets box-drawing chars + messages!
cd "$dir" && do_something            # FAILS - $dir is garbage
```

### Correct Pattern: Chain Interactive Functions

```zsh
# ✅ RIGHT - Chain with &&
my_interactive_picker() {
    echo "╔════════════════════════╗"
    echo "║  PROJECT PICKER        ║"
    echo "╚════════════════════════╝"
    local selection=$(fzf < project_list.txt)
    cd "$selection"
    echo "📂 Changed to: $selection"
}

# Later in code...
my_interactive_picker && do_something  # Works! Uses side effects
```

### Alternative: Separate UI from Logic

```zsh
# ✅ BETTER - Programmatic function that returns clean output
_get_project_dir() {
    # All UI goes to stderr
    echo "╔════════════════════════╗" >&2
    echo "║  PROJECT PICKER        ║" >&2
    echo "╚════════════════════════╝" >&2

    # Only the result goes to stdout
    fzf < project_list.txt
}

# Later in code...
local dir=$(_get_project_dir)  # Clean! Only gets the directory
cd "$dir" && do_something
```

---

## Command Substitution Anti-Patterns

### Historical Bugs Fixed

#### Bug 1: `cc` and `gm` Functions (2025-12-19)

**Problem:**

```zsh
cc() {
    if [[ $# -eq 0 ]]; then
        local project_dir=$(pick)  # ❌ Captures UI noise
        if [[ -n "$project_dir" ]]; then
            cd "$project_dir" && claude
        fi
    fi
}
```

**Error:**

```
cc:cd:6: no such file or directory: \n╔════════════════...
```

**Fix:**

```zsh
cc() {
    if [[ $# -eq 0 ]]; then
        pick && claude  # ✅ Uses side effect (cd)
    fi
}
```

### Lint Rules

**Never capture these interactive functions:**

- `pick`, `pickr`, `pickdev`, `pickq`
- `fzf` (directly - wrap it properly)
- Any function that prints box-drawing characters
- Any function that calls `cd` as a side effect

**Regex patterns to avoid:**

```bash
# These patterns should trigger warnings:
\$\(pick\)
\$\(pickr\)
\$\(pickdev\)
\$\(pickq\)
local.*=\$\(pick
```

---

## Alias vs Function Naming

### Rule: Functions Override Aliases

**Problem:** Cannot define a function with the same name as an existing alias.

#### Bug: `peek` Alias Conflict (2025-12-19)

**Problem:**

```zsh
# In .zshrc (line 145)
alias peek='bat'

# In smart-dispatchers.zsh (line 1207)
peek() {  # ❌ FAILS - parse error!
    # Advanced peek functionality...
}
```

**Error:**

```
defining function based on alias `peek'
parse error near `()'
```

**Fix:** Remove the simple alias, let the advanced function take over:

```zsh
# In .zshrc
# Note: peek is now a function in smart-dispatchers.zsh
```

### Best Practices

1. **Check for conflicts before defining functions:**

   ```zsh
   # Good practice - unalias first if needed
   unalias peek 2>/dev/null
   peek() {
       # function definition
   }
   ```

2. **Use namespacing for complex commands:**

   ```zsh
   # Instead of overriding 'ls'
   alias ls='eza'

   # Better - create a new command
   alias ll='eza -l'
   ```

3. **Document when functions replace aliases:**
   ```zsh
   # REPLACED: alias peek='bat'
   # NOW: peek() function in smart-dispatchers.zsh
   peek() {
       # Advanced functionality
   }
   ```

---

## Output Redirection Best Practices

### Stdout vs Stderr

**Rule:** User messages go to stderr, data goes to stdout.

```zsh
# ✅ CORRECT
my_function() {
    echo "Processing..." >&2          # Status message → stderr
    echo "Found 5 files" >&2          # Info message → stderr
    echo "/path/to/result"            # Data → stdout
}

# Usage
result=$(my_function)  # Gets "/path/to/result", sees messages
```

```zsh
# ❌ WRONG
my_function() {
    echo "Processing..."              # Pollutes stdout!
    echo "Found 5 files"              # Pollutes stdout!
    echo "/path/to/result"            # Data mixed with noise
}

# Usage
result=$(my_function)  # Gets "Processing...\nFound 5 files\n/path/to/result"
```

### When to Print to Stdout

✅ **Print to stdout when:**

- Returning data to be captured by `$()`
- Piping to another command
- Output is the primary purpose of the function

❌ **Don't print to stdout when:**

- Showing status messages
- Displaying UI elements
- Logging progress
- Asking for user input

---

## Testing Requirements

### Required Tests for New Functions

1. **Load Test:** Function loads without errors
2. **Help Test:** Help/usage message displays correctly
3. **Basic Execution:** Function runs without crashing
4. **Command Substitution Test:** If function can be captured with `$()`, test it

### Example Test Suite

```zsh
# test-new-function.zsh

test_function_loads() {
    source ~/.config/zsh/functions/my-functions.zsh
    assert_function_exists "my_new_function"
}

test_function_help() {
    output=$(my_new_function --help 2>&1)
    assert_output_contains "Usage:" "$output"
}

test_command_substitution() {
    # Only test this if function is designed to be captured
    result=$(my_programmatic_function)
    assert_not_contains "╔" "$result"  # No box-drawing chars
    assert_not_contains "echo" "$result"  # No debug output
}

test_interactive_function_side_effects() {
    # For interactive functions, test the side effects
    local before_dir="$PWD"
    my_interactive_picker  # Should change directory
    local after_dir="$PWD"
    assert_not_equal "$before_dir" "$after_dir"
}
```

---

## Common Anti-Patterns Checklist

Before committing new shell functions, check for these:

- [ ] No `$(interactive_function)` patterns
- [ ] No function names that conflict with existing aliases
- [ ] Status messages go to stderr, data goes to stdout
- [ ] Help/usage messages documented
- [ ] Tests added to test suite
- [ ] No unquoted variable expansions (`$var` → `"$var"`)
- [ ] Error cases handled with meaningful messages
- [ ] Functions use `local` for all variables

---

## Quick Reference

### Good Patterns ✅

```zsh
# Interactive function chaining
pick && do_something

# Programmatic function with clean output
result=$(get_data)

# Proper stderr usage
echo "Status: processing..." >&2

# Function before alias definition
unalias cmd 2>/dev/null
cmd() { ... }
```

### Bad Patterns ❌

```zsh
# Don't capture interactive functions
dir=$(pick)

# Don't pollute stdout in programmatic functions
get_data() {
    echo "Loading..."  # ❌ Goes to stdout!
    echo "$result"
}

# Don't override aliases with functions (without unalias)
alias peek='bat'
peek() { ... }  # ❌ Parse error!
```

---

## Resources

- Test suite: `~/.config/zsh/tests/`
- Lint script: `~/.config/zsh/scripts/lint-zsh.sh`
- Documentation: `~/projects/dev-tools/flow-cli/docs/`

---

## Changelog

- **2025-12-19:** Initial guidelines created
  - Documented interactive vs programmatic function patterns
  - Added alias/function conflict rules
  - Created anti-pattern checklist
