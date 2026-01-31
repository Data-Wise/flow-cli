# Git Directory Detection - Usage Examples

**Function:** `_dot_check_git_in_path()`
**Purpose:** Detect .git directories before tracking with chezmoi

---

## Basic Usage

### Example 1: Simple Detection

```zsh
#!/usr/bin/env zsh
source lib/core.zsh
source lib/dotfile-helpers.zsh

target="/Users/dt/projects/myproject"

if _dot_check_git_in_path "$target" >/dev/null; then
    echo "⚠️  Warning: This directory contains git repositories"
else
    echo "✓ Safe to add to chezmoi"
fi
```

**Output (with .git):**
```
⚠️  Warning: This directory contains git repositories
```

**Output (without .git):**
```
✓ Safe to add to chezmoi
```

---

## Capturing Results

### Example 2: List All .git Directories Found

```zsh
target="/Users/dt/projects/monorepo"

if git_dirs=$(_dot_check_git_in_path "$target"); then
    echo "Found .git directories:"
    for gitdir in ${(s: :)git_dirs}; do
        echo "  - $gitdir"
    done
else
    echo "No .git directories found"
fi
```

**Output:**
```
Found .git directories:
  - /Users/dt/projects/monorepo/.git
  - /Users/dt/projects/monorepo/packages/frontend/.git
  - /Users/dt/projects/monorepo/packages/backend/.git
```

---

## Interactive Confirmation

### Example 3: Warn and Ask User

```zsh
_dot_add_with_safety() {
    local target="$1"

    # Check for git directories
    if git_dirs=$(_dot_check_git_in_path "$target"); then
        _flow_log_warning "Found .git directories in target:"

        for gitdir in ${(s: :)git_dirs}; do
            echo "  ${FLOW_COLORS[muted]}$gitdir${FLOW_COLORS[reset]}"
        done

        _flow_log_info "Adding this will track git metadata (not recommended)"
        _flow_log_info "Tip: Consider adding to .chezmoiignore instead"

        read -q "REPLY?Continue anyway? (y/N) "
        echo

        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            _flow_log_info "Cancelled. No files were added."
            return 1
        fi
    fi

    # Proceed with chezmoi add
    chezmoi add "$target"
}
```

**Interactive Session:**
```
⚠ Found .git directories in target:
  /Users/dt/projects/myapp/.git
ℹ Adding this will track git metadata (not recommended)
ℹ Tip: Consider adding to .chezmoiignore instead
Continue anyway? (y/N) n
ℹ Cancelled. No files were added.
```

---

## Auto-Ignore Pattern

### Example 4: Automatically Add to .chezmoiignore

```zsh
_dot_add_with_auto_ignore() {
    local target="$1"
    local chezmoi_dir="$HOME/.local/share/chezmoi"
    local ignore_file="$chezmoi_dir/.chezmoiignore"

    # Check for git directories
    if git_dirs=$(_dot_check_git_in_path "$target"); then
        _flow_log_info "Found .git directories - adding to .chezmoiignore"

        # Add .git pattern if not already present
        if ! grep -q "^\.git$" "$ignore_file" 2>/dev/null; then
            echo ".git" >> "$ignore_file"
            _flow_log_success "Added '.git' to .chezmoiignore"
        fi
    fi

    # Proceed with chezmoi add
    chezmoi add "$target"
    _flow_log_success "Added $target to chezmoi (excluding .git)"
}
```

**Output:**
```
ℹ Found .git directories - adding to .chezmoiignore
✓ Added '.git' to .chezmoiignore
✓ Added /Users/dt/projects/myapp to chezmoi (excluding .git)
```

---

## Performance-Aware Scanning

### Example 5: Warn on Large Directories

```zsh
_dot_add_smart() {
    local target="$1"

    # Check directory size first
    local dir_size=$(du -sk "$target" 2>/dev/null | awk '{print $1}')

    if (( dir_size > 100000 )); then  # > 100MB
        _flow_log_warning "Large directory detected ($((dir_size / 1024)) MB)"
        _flow_log_info "Git scan may take a few seconds or timeout"

        read -q "REPLY?Proceed with scan? (Y/n) "
        echo
        [[ $REPLY =~ ^[Nn]$ ]] && return 1
    fi

    # Proceed with git detection
    if git_dirs=$(_dot_check_git_in_path "$target"); then
        _flow_log_warning "Found $(echo $git_dirs | wc -w) .git directories"
        # ... handle as needed
    fi
}
```

---

## Integration with flow doctor

### Example 6: Health Check for Chezmoi Safety

```zsh
_doctor_check_chezmoi_safety() {
    local chezmoi_source="$HOME/.local/share/chezmoi"

    if [[ ! -d "$chezmoi_source" ]]; then
        _flow_log_info "Chezmoi not initialized"
        return 0
    fi

    _flow_log_info "Checking for tracked .git directories..."

    # Check if any .git directories are tracked
    local tracked_git=()
    while IFS= read -r file; do
        if [[ "$file" =~ "\.git/" ]] || [[ "$file" == *"/.git" ]]; then
            tracked_git+=("$file")
        fi
    done < <(chezmoi managed 2>/dev/null)

    if (( ${#tracked_git[@]} > 0 )); then
        _flow_log_warning "Found ${#tracked_git[@]} tracked .git files/directories:"
        for file in "${tracked_git[@]}"; do
            echo "  ${FLOW_COLORS[muted]}$file${FLOW_COLORS[reset]}"
        done
        _flow_log_info "Recommendation: Add .git to .chezmoiignore"
        return 1
    else
        _flow_log_success "No .git directories tracked"
        return 0
    fi
}
```

**Output (issue found):**
```
ℹ Checking for tracked .git directories...
⚠ Found 3 tracked .git files/directories:
  .config/nvim/.git/config
  .config/nvim/.git/HEAD
  .config/nvim/.git/index
ℹ Recommendation: Add .git to .chezmoiignore
```

---

## Symlink Handling Examples

### Example 7: Symlink with User Prompt

```zsh
# Assuming ~/.config/zsh is a symlink to ~/dotfiles/zsh
target="$HOME/.config/zsh"

result=$(_dot_check_git_in_path "$target")
```

**Interactive Prompt:**
```
⚠ Target is a symlink: /Users/dt/.config/zsh
Follow symlink and scan target? (Y/n) y
ℹ Following to: /Users/dt/dotfiles/zsh
ℹ Found 1 git submodule(s) in /Users/dt/dotfiles/zsh
```

**Result:**
```
/Users/dt/dotfiles/zsh/.git
/Users/dt/dotfiles/zsh/plugins/zsh-autosuggestions/.git
```

---

## Error Handling Examples

### Example 8: Graceful Degradation

```zsh
_safe_git_check() {
    local target="$1"

    # Validate input
    if [[ -z "$target" ]]; then
        _flow_log_error "No target specified"
        return 1
    fi

    if [[ ! -e "$target" ]]; then
        _flow_log_error "Target does not exist: $target"
        return 1
    fi

    if [[ ! -d "$target" ]]; then
        _flow_log_error "Target is not a directory: $target"
        return 1
    fi

    # Check for git directories (with error handling)
    local git_dirs
    if ! git_dirs=$(_dot_check_git_in_path "$target" 2>&1); then
        local exit_code=$?

        # Check for timeout (exit 124)
        if (( exit_code == 124 )); then
            _flow_log_warning "Git scan timed out"
            _flow_log_info "Large directory - may contain undetected .git directories"
        fi

        # No .git found (or error occurred)
        return 0
    fi

    # Found .git directories
    echo "$git_dirs"
    return 0
}
```

---

## Real-World Integration Example

### Example 9: Complete `dot add` Command

```zsh
#!/usr/bin/env zsh
# File: lib/dispatchers/dot-dispatcher.zsh

_dot_add() {
    local target="$1"

    # Validate input
    if [[ -z "$target" ]]; then
        _flow_log_error "Usage: dot add <file|directory>"
        return 1
    fi

    # Expand path
    target="${target:A}"

    if [[ ! -e "$target" ]]; then
        _flow_log_error "Target does not exist: $target"
        return 1
    fi

    # Safety check: detect .git directories
    if [[ -d "$target" ]]; then
        if git_dirs=$(_dot_check_git_in_path "$target" 2>/dev/null); then
            _flow_log_warning "⚠️  Git directories detected in target:"

            for gitdir in ${(s: :)git_dirs}; do
                # Make paths relative to target for cleaner display
                local rel_path="${gitdir#$target/}"
                echo "  ${FLOW_COLORS[muted]}$rel_path${FLOW_COLORS[reset]}"
            done

            echo
            _flow_log_info "Options:"
            echo "  1. ${FLOW_COLORS[cmd]}dot ignore '$target/.git'${FLOW_COLORS[reset]} (recommended)"
            echo "  2. Add to ${FLOW_COLORS[muted]}~/.local/share/chezmoi/.chezmoiignore${FLOW_COLORS[reset]}"
            echo "  3. Continue anyway (not recommended)"
            echo

            read -q "REPLY?How to proceed? [1/2/3] "
            echo

            case "$REPLY" in
                1)
                    # Add to ignore automatically
                    echo ".git" >> "$HOME/.local/share/chezmoi/.chezmoiignore"
                    _flow_log_success "Added .git to ignore patterns"
                    ;;
                2)
                    # Open .chezmoiignore for manual editing
                    ${EDITOR:-vim} "$HOME/.local/share/chezmoi/.chezmoiignore"
                    _flow_log_info "Edit .chezmoiignore and run 'dot add' again"
                    return 0
                    ;;
                3)
                    # Continue with warning
                    _flow_log_warning "Proceeding with git metadata included"
                    ;;
                *)
                    _flow_log_info "Cancelled"
                    return 1
                    ;;
            esac
        fi
    fi

    # Proceed with chezmoi add
    _flow_log_info "Adding to chezmoi: $target"
    if chezmoi add "$target"; then
        _flow_log_success "Successfully added to dotfile management"

        # Show status
        local status=$(chezmoi status "$target" 2>/dev/null)
        if [[ -n "$status" ]]; then
            echo "${FLOW_COLORS[muted]}Status: $status${FLOW_COLORS[reset]}"
        fi
    else
        _flow_log_error "Failed to add target"
        return 1
    fi
}
```

**Interactive Session:**
```
$ dot add ~/projects/myapp

⚠ Git directories detected in target:
  .git
  frontend/.git
  backend/.git

Options:
  1. dot ignore '/Users/dt/projects/myapp/.git' (recommended)
  2. Add to ~/.local/share/chezmoi/.chezmoiignore
  3. Continue anyway (not recommended)

How to proceed? [1/2/3] 1
✓ Added .git to ignore patterns
ℹ Adding to chezmoi: /Users/dt/projects/myapp
✓ Successfully added to dotfile management
```

---

## Summary

These examples demonstrate:

1. **Basic detection** - Simple true/false checks
2. **Result capture** - Getting list of .git directories found
3. **User interaction** - Prompting for confirmation
4. **Auto-remediation** - Adding to .chezmoiignore automatically
5. **Performance** - Handling large directories gracefully
6. **Health checks** - Integration with doctor command
7. **Symlinks** - Interactive symlink following
8. **Error handling** - Graceful degradation and timeouts
9. **Real-world** - Complete integration example

---

**Reference:**
- Implementation: `lib/dotfile-helpers.zsh` (lines 1334-1427)
- Tests: `tests/manual-test-git-detection.zsh`
- Documentation: `docs/implementation/GIT-DETECTION-IMPLEMENTATION.md`
