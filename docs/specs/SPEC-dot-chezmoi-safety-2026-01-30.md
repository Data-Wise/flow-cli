# SPEC: Dot Dispatcher - Chezmoi Safety & Health Enhancements

**Status:** Draft (Awaiting Approval)
**Created:** 2026-01-30
**Target Release:** flow-cli v6.0.0
**Estimated Effort:** 12-16 hours over 1-2 weeks
**Dependencies:** flow-cli v5.3.0+, chezmoi v2.69.3+

---

## Overview

Enhance the `dot` dispatcher with intelligent safety features to prevent redundant file tracking (e.g., .git directories), provide repository health visibility, and streamline ignore pattern management. These improvements address real issues discovered during chezmoi setup cleanup (196KB of redundant nvim/.git files tracked).

**Key Benefits:**
- **Prevention:** Auto-detects problematic patterns before they're committed
- **Visibility:** Repository size analysis identifies bloat proactively
- **Convenience:** User-friendly ignore pattern management
- **Health:** Integrated doctor checks catch issues early
- **Safety:** Preview-before-add prevents costly mistakes

---

## Problem Statement

### Issue 1: Redundant .git Directory Tracking
**Discovery:** While setting up CLAUDE.md in `~/.config`, found 30 .git metadata files (196KB) from LazyVim starter template accidentally tracked by chezmoi.

**Impact:**
- Bloated chezmoi repository (196KB for single .git directory)
- Sync conflicts when LazyVim updates its git state
- Confusion between nvim config tracking vs LazyVim template tracking
- No warning during `chezmoi add ~/.config/nvim`

**Root Cause:** `chezmoi add` doesn't detect or warn about nested .git directories

### Issue 2: Manual .chezmoiignore Management
**Discovery:** Had to manually create `.chezmoiignore` and add `**/.git` patterns

**Impact:**
- Requires knowledge of chezmoi ignore syntax
- No discovery mechanism for what patterns are active
- No validation of patterns (typos persist silently)
- Manual file editing (not integrated into `dot` workflow)

### Issue 3: No Repository Health Visibility
**Discovery:** Only discovered the 196KB bloat by manually checking git log and file sizes

**Impact:**
- No proactive monitoring of repository size
- Large files go unnoticed until sync becomes slow
- No visibility into what chezmoi is tracking
- Reactive rather than proactive management

### Issue 4: No Safety Checks Before Add
**Discovery:** `dot add ~/.config/nvim` silently added 45 files including all .git metadata

**Impact:**
- No preview of what will be tracked
- No warnings about generated files (.log, .sqlite, .db)
- No size warnings for large files
- Trust-based operation (can't verify before committing)

---

## Primary User Story

**As a** flow-cli user managing dotfiles with chezmoi,
**I want** intelligent safety checks and repository health visibility,
**So that** I never accidentally track bloated or inappropriate files.

**Acceptance Criteria:**
1. `dot add <path>` detects .git directories and warns before adding
2. `dot add <path>` shows preview with file count, size, warnings
3. `dot ignore add <pattern>` adds patterns without manual file editing
4. `dot ignore list` shows all active ignore patterns
5. `dot size` reports repository size and identifies bloat
6. `flow doctor` includes chezmoi health checks (large files, .git dirs, .chezmoiignore existence)
7. Auto-suggestions for common generated files (.log, .sqlite, .db, .cache)
8. All operations maintain < 3s performance target
9. Zero false positives in git directory detection
10. Help text updated with new commands

---

## Secondary User Stories

### 1. Git Directory Detection
**As a** user adding a directory to chezmoi,
**I want** automatic detection of .git directories,
**So that** I don't accidentally track git metadata.

**Scenario:**
```bash
$ dot add ~/.config/ghostty
⚠️  Git directory detected in /Users/dt/.config/ghostty
    Git metadata should not be tracked by chezmoi.

Auto-create ignore rule? (Y/n): y
✓ Added .config/ghostty/.git to .chezmoiignore
✓ Added .config/ghostty/.git/** to .chezmoiignore

Adding .config/ghostty to chezmoi...
✓ Added 12 files (skipped 45 .git files)
```

**Acceptance:**
- Detects both `path/.git` and nested `path/subdir/.git`
- Offers to auto-create ignore patterns
- Shows how many files were skipped
- Completes in < 2s even with large directories

### 2. Ignore Pattern Management
**As a** user managing ignore patterns,
**I want** commands to add/list/remove patterns,
**So that** I don't need to manually edit .chezmoiignore.

**Scenario:**
```bash
# Add pattern
$ dot ignore add "**/.git"
✓ Added pattern to .chezmoiignore: **/.git

# List patterns
$ dot ignore list
.chezmoiignore patterns:
  1  **/.git
  2  **/.git/**
  3  *.log
  4  *.sqlite
  5  .DS_Store

# Remove pattern
$ dot ignore remove "*.log"
✓ Removed pattern from .chezmoiignore: *.log

# Edit directly (fallback)
$ dot ignore edit
# Opens .chezmoiignore in $EDITOR
```

**Acceptance:**
- `add` creates .chezmoiignore if missing
- `list` shows numbered list for easy reference
- `remove` validates pattern exists before removing
- `edit` opens in $EDITOR with syntax highlighting

### 3. Repository Size Analysis
**As a** user maintaining a chezmoi repository,
**I want** visibility into repository size and bloat,
**So that** I can identify and fix tracking issues proactively.

**Scenario:**
```bash
$ dot size

Chezmoi Repository Size
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total: 1.4 MB

Top 10 largest files:
  ⚠️  196 KB  dot_config/nvim/dot_git/objects/pack/pack-*.pack
              (Git metadata - should be ignored)
      7.4 KB  dot_config/wezterm/wezterm.lua
      6.9 KB  dot_config/CLAUDE.md
      3.4 KB  dot_config/starship.toml
      3.1 KB  dot_config/GEMINI.md
      1.4 KB  dot_config/nvim/lazyvim.json
      1.2 KB  dot_config/ghostty/config
      0.8 KB  dot_config/git/ignore
      0.5 KB  dot_config/git/gitk
      0.4 KB  dot_zshrc

⚠ Found 1 nested .git directory (should be ignored)
  Run 'dot ignore add "**/.git"' to fix
```

**Acceptance:**
- Shows total repository size (human-readable)
- Lists top 10 files by size
- Highlights .git directories with warning
- Suggests fix commands for detected issues
- Excludes chezmoi's own .git directory from warnings

### 4. Preview Before Add
**As a** user adding files to chezmoi,
**I want** a preview of what will be tracked,
**So that** I can verify before committing.

**Scenario:**
```bash
$ dot add ~/.config/obs

Preview: dot add /Users/dt/.config/obs
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Files to add: 4
Total size: 163 KB

⚠️  Generated files detected:
  - vault_db.sqlite (163 KB)
  - obs.log (7 KB)

💡 Consider excluding:
  - *.sqlite (databases)
  - *.log (logs)

Auto-add ignore patterns? (Y/n): y
✓ Added *.sqlite to .chezmoiignore
✓ Added *.log to .chezmoiignore

Proceed with add? (Y/n): y
✓ Added 2 files (skipped 2 generated files)
```

**Acceptance:**
- Shows file count and total size before adding
- Warns about large files (>50KB)
- Detects generated files (.log, .sqlite, .db, .cache)
- Offers to auto-add ignore patterns
- Requires explicit confirmation before adding
- Can be bypassed with `dot add --no-preview <path>`

### 5. Doctor Integration
**As a** user running flow doctor,
**I want** chezmoi health checks included,
**So that** I catch issues before they become problems.

**Scenario:**
```bash
$ flow doctor

System Health Check
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
...

Dotfile Management:
  ✓ chezmoi installed (v2.69.3)
  ✓ Repository initialized
  ✓ Connected to remote (github.com/data-wise/dotfiles)
  ✓ .chezmoiignore configured (5 patterns)
  ✓ 47 files managed
  ✓ Repository size: 1.2 MB (healthy)
  ⚠ Large file tracked: dot_config/nvim/lazy-lock.json (6.3 KB)
     Consider: dot ignore add "nvim/lazy-lock.json"
  ✓ No nested .git directories tracked
  ✓ Last sync: 2 hours ago (synced)
```

**Acceptance:**
- Checks chezmoi installation and version
- Verifies repository initialization
- Checks remote connection
- Validates .chezmoiignore exists and is not empty
- Reports managed file count
- Checks repository size (warns if > 5MB)
- Detects large files (> 100KB)
- Detects nested .git directories
- Shows sync status and last sync time

### 6. Auto-Suggestions for Common Patterns
**As a** user adding directories with common generated files,
**I want** intelligent suggestions for ignore patterns,
**So that** I don't track unnecessary files.

**Trigger Patterns:**
- `.log` → Suggest ignoring `*.log`
- `.sqlite`, `.db` → Suggest ignoring `*.sqlite`, `*.db`
- `.cache` → Suggest ignoring `*.cache`
- `.git` → Suggest ignoring `**/.git`
- `node_modules/` → Suggest ignoring `node_modules/`
- `.DS_Store` → Suggest ignoring `.DS_Store`

**Scenario:**
```bash
$ dot add ~/.config/micro

Preview: dot add /Users/dt/.config/micro
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Files to add: 8
Total size: 12 KB

⚠️  Cache files detected:
  - backups/2026-01-30.cache
  - buffers/session.cache

💡 These look like temporary files. Add to ignore? (Y/n): y
✓ Added *.cache to .chezmoiignore

Proceed with add? (Y/n): y
✓ Added 6 files (skipped 2 cache files)
```

**Acceptance:**
- Detects patterns automatically during preview
- Groups suggestions by file type (logs, databases, caches)
- Explains why files should be ignored
- Batch-adds related patterns (e.g., *.sqlite + *.db)
- Never blocks adding (always optional)

---

## Technical Requirements

### Architecture

**Pattern:** Extend existing `dot` dispatcher (maintain consistency)

**New Functions:**
```
lib/dotfile-helpers.zsh:
  - _dot_check_git_in_path()       # Detect .git directories
  - _dot_preview_add()              # Preview before add
  - _dot_suggest_ignore_patterns()  # Auto-suggest patterns
  - _dot_get_repo_size()            # Calculate repository size
  - _dot_find_large_files()         # Identify bloat

lib/dispatchers/dot-dispatcher.zsh:
  - dot ignore [add|list|remove|edit]  # Ignore management
  - dot size                            # Repository analysis
  - _dot_doctor_check_chezmoi_health() # Doctor integration
```

**Modified Commands:**
```
dot add <path>:
  1. Run _dot_preview_add() - show file count, size, warnings
  2. Run _dot_check_git_in_path() - detect .git directories
  3. Run _dot_suggest_ignore_patterns() - auto-suggest ignores
  4. Prompt for confirmation
  5. Execute chezmoi add with filtered paths
```

### Performance Targets

| Operation | Target | Current | Status |
|-----------|--------|---------|--------|
| `dot add` preview | < 2.0s | N/A | New |
| `dot ignore list` | < 0.5s | N/A | New |
| `dot size` | < 3.0s | N/A | New |
| `flow doctor` (chezmoi) | < 2.0s | N/A | New |
| Git detection | < 1.0s | N/A | New |

### File Structure

```
flow-cli/
├── lib/
│   ├── dotfile-helpers.zsh               # Add new functions
│   └── dispatchers/
│       └── dot-dispatcher.zsh            # Modify for new commands
├── completions/
│   └── _dot                              # Add ignore/size completions
├── tests/
│   └── test-dot-chezmoi-safety.zsh       # New test suite
└── docs/specs/
    ├── dot-dispatcher-refcard.md         # Update with new commands
    └── SPEC-dot-chezmoi-safety-2026-01-30.md  # This spec
```

---

## Implementation Plan

### Phase 1: Safety Features (Week 1)
**Effort:** 6-8 hours

#### 1.1 Git Directory Detection
**File:** `lib/dotfile-helpers.zsh`

```zsh
_dot_check_git_in_path() {
    local target="$1"
    local git_dirs=()

    # Check if target itself has .git
    if [[ -d "$target/.git" ]]; then
        git_dirs+=("$target/.git")
    fi

    # Find nested .git directories (limit depth for performance)
    while IFS= read -r gitdir; do
        git_dirs+=("$gitdir")
    done < <(find "$target" -name ".git" -type d -maxdepth 5 2>/dev/null)

    if (( ${#git_dirs[@]} > 0 )); then
        echo "${git_dirs[@]}"
        return 0
    fi
    return 1
}
```

**Modify:** `dot add` command in `dot-dispatcher.zsh`

```zsh
"add")
    if [[ -z "$2" ]]; then
        _dot_error "Usage: dot add <file>"
        return 1
    fi

    local target="$2"
    local no_preview=false

    # Check for --no-preview flag
    if [[ "$3" == "--no-preview" ]]; then
        no_preview=true
    fi

    # Check for git directories
    local git_dirs=$(_dot_check_git_in_path "$target")
    if [[ -n "$git_dirs" ]]; then
        _dot_warn "⚠️  Git directory detected in $target"
        _dot_info "Git metadata should not be tracked by chezmoi."
        echo
        read -q "REPLY?Auto-create ignore rule? (Y/n) "
        echo
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            # Extract relative path from target
            local rel_path="${target#$HOME/}"
            local ignore_file="$HOME/.local/share/chezmoi/.chezmoiignore"

            # Create .chezmoiignore if missing
            if [[ ! -f "$ignore_file" ]]; then
                touch "$ignore_file"
                _dot_info "Created .chezmoiignore"
            fi

            # Add patterns
            echo "${rel_path}/.git" >> "$ignore_file"
            echo "${rel_path}/.git/**" >> "$ignore_file"
            _dot_success "Added ${rel_path}/.git to .chezmoiignore"
        fi
    fi

    # Show preview unless --no-preview
    if [[ "$no_preview" == false ]]; then
        _dot_preview_add "$target" || return 1
    fi

    # Execute add
    chezmoi add "$target"
    _dot_success "Added $target to chezmoi"
    ;;
```

#### 1.2 Preview Before Add
**File:** `lib/dotfile-helpers.zsh`

```zsh
_dot_preview_add() {
    local target="$1"

    if [[ ! -e "$target" ]]; then
        _dot_error "Path does not exist: $target"
        return 1
    fi

    _dot_header "Preview: dot add $target"
    echo

    # Count files and calculate size
    local file_count=0
    local total_size=0
    local large_files=()
    local generated_files=()
    local git_files=0

    if [[ -d "$target" ]]; then
        while IFS= read -r file; do
            ((file_count++))

            local size=$(stat -f%z "$file" 2>/dev/null || echo 0)
            ((total_size += size))

            # Check for git files
            if [[ "$file" == *"/.git/"* ]]; then
                ((git_files++))
            fi

            # Check for large files (>50KB)
            if (( size > 51200 )); then
                large_files+=("$file:$size")
            fi

            # Check for generated files
            if [[ "$file" =~ \.(log|sqlite|db|cache)$ ]]; then
                generated_files+=("$file")
            fi
        done < <(find "$target" -type f 2>/dev/null)
    else
        file_count=1
        total_size=$(stat -f%z "$target" 2>/dev/null || echo 0)
    fi

    # Display summary
    echo "Files to add: $file_count"
    if command -v numfmt &>/dev/null; then
        echo "Total size: $(numfmt --to=iec $total_size)"
    else
        echo "Total size: ${total_size} bytes"
    fi
    echo

    # Show warnings
    local has_warnings=false

    if (( git_files > 0 )); then
        has_warnings=true
        _dot_warn "⚠️  $git_files git metadata files detected"
        _dot_info "These will be skipped (covered by .chezmoiignore)"
        echo
    fi

    if (( ${#large_files[@]} > 0 )); then
        has_warnings=true
        _dot_warn "⚠️  Large files detected:"
        for item in "${large_files[@]}"; do
            local file="${item%:*}"
            local size="${item#*:}"
            if command -v numfmt &>/dev/null; then
                echo "  - $(numfmt --to=iec $size)  ${file#$target/}"
            else
                echo "  - ${size} bytes  ${file#$target/}"
            fi
        done
        echo
    fi

    if (( ${#generated_files[@]} > 0 )); then
        has_warnings=true
        _dot_warn "⚠️  Generated files detected:"
        for file in "${generated_files[@]}"; do
            echo "  - ${file#$target/}"
        done
        echo
        _dot_info "💡 Consider excluding: *.log, *.sqlite, *.db, *.cache"

        read -q "REPLY?Auto-add ignore patterns? (Y/n) "
        echo
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            _dot_suggest_ignore_patterns "${generated_files[@]}"
        fi
        echo
    fi

    # Confirmation
    read -q "REPLY?Proceed with add? (Y/n) "
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        return 0
    else
        _dot_info "Add cancelled"
        return 1
    fi
}

_dot_suggest_ignore_patterns() {
    local files=("$@")
    local ignore_file="$HOME/.local/share/chezmoi/.chezmoiignore"
    local patterns=()

    # Extract unique file extensions
    for file in "${files[@]}"; do
        if [[ "$file" =~ \.([^.]+)$ ]]; then
            local ext="${BASH_REMATCH[1]}"
            patterns+=("*.${ext}")
        fi
    done

    # Remove duplicates
    patterns=($(printf '%s\n' "${patterns[@]}" | sort -u))

    # Create .chezmoiignore if missing
    if [[ ! -f "$ignore_file" ]]; then
        touch "$ignore_file"
    fi

    # Add patterns
    for pattern in "${patterns[@]}"; do
        if ! grep -qF "$pattern" "$ignore_file" 2>/dev/null; then
            echo "$pattern" >> "$ignore_file"
            _dot_success "Added $pattern to .chezmoiignore"
        fi
    done
}
```

**Testing:**
```bash
# Test 1: Directory with .git
mkdir -p /tmp/test-dotfile/.git
dot add /tmp/test-dotfile
# Expected: Warning, auto-ignore prompt, preview

# Test 2: Single file
echo "test" > /tmp/test.txt
dot add /tmp/test.txt
# Expected: Preview with 1 file, small size

# Test 3: Directory with generated files
mkdir -p /tmp/test-gen
touch /tmp/test-gen/app.log /tmp/test-gen/db.sqlite
dot add /tmp/test-gen
# Expected: Preview warns about .log/.sqlite, suggests ignoring
```

#### 1.3 Ignore Management Commands
**File:** `lib/dispatchers/dot-dispatcher.zsh`

```zsh
"ignore")
    local ignore_file="$HOME/.local/share/chezmoi/.chezmoiignore"

    case "$2" in
        "add")
            if [[ -z "$3" ]]; then
                _dot_error "Usage: dot ignore add <pattern>"
                return 1
            fi

            # Create file if missing
            if [[ ! -f "$ignore_file" ]]; then
                touch "$ignore_file"
                _dot_info "Created .chezmoiignore"
            fi

            # Check if pattern exists
            if grep -qF "$3" "$ignore_file" 2>/dev/null; then
                _dot_warn "Pattern already in .chezmoiignore: $3"
                return 0
            fi

            # Add pattern
            echo "$3" >> "$ignore_file"
            _dot_success "Added pattern to .chezmoiignore: $3"
            ;;

        "list"|"ls"|"")
            if [[ ! -f "$ignore_file" ]]; then
                _dot_info "No .chezmoiignore file found"
                _dot_info "Create patterns with: dot ignore add <pattern>"
                return 0
            fi

            _dot_header ".chezmoiignore patterns:"
            cat "$ignore_file" | nl -w2 -s"  "
            ;;

        "remove"|"rm")
            if [[ -z "$3" ]]; then
                _dot_error "Usage: dot ignore remove <pattern>"
                return 1
            fi

            if [[ ! -f "$ignore_file" ]]; then
                _dot_error "No .chezmoiignore file found"
                return 1
            fi

            # Check if pattern exists
            if ! grep -qF "$3" "$ignore_file" 2>/dev/null; then
                _dot_error "Pattern not found in .chezmoiignore: $3"
                return 1
            fi

            # Remove using sed (cross-platform)
            local escaped="${3//\//\\/}"
            sed -i.bak "/^${escaped}$/d" "$ignore_file"
            rm -f "${ignore_file}.bak"
            _dot_success "Removed pattern from .chezmoiignore: $3"
            ;;

        "edit")
            if [[ ! -f "$ignore_file" ]]; then
                touch "$ignore_file"
                _dot_info "Created .chezmoiignore"
            fi

            ${EDITOR:-vim} "$ignore_file"
            ;;

        *)
            _dot_error "Unknown ignore command: $2"
            echo
            _dot_info "Usage: dot ignore [add|list|remove|edit]"
            _dot_info ""
            _dot_info "Examples:"
            _dot_info "  dot ignore add '**/.git'     # Ignore all .git directories"
            _dot_info "  dot ignore list              # Show all patterns"
            _dot_info "  dot ignore remove '*.log'    # Remove pattern"
            _dot_info "  dot ignore edit              # Edit .chezmoiignore"
            return 1
            ;;
    esac
    ;;
```

**Testing:**
```bash
# Test ignore management
dot ignore add "**/.git"
dot ignore add "*.log"
dot ignore list
# Expected: Shows 2 patterns with line numbers

dot ignore remove "*.log"
dot ignore list
# Expected: Shows 1 pattern

dot ignore edit
# Expected: Opens .chezmoiignore in $EDITOR
```

### Phase 2: Health & Visibility (Week 2)
**Effort:** 6-8 hours

#### 2.1 Repository Size Analysis
**File:** `lib/dispatchers/dot-dispatcher.zsh`

```zsh
"size")
    local chezmoi_dir="$HOME/.local/share/chezmoi"

    if [[ ! -d "$chezmoi_dir" ]]; then
        _dot_error "Chezmoi directory not found: $chezmoi_dir"
        return 1
    fi

    _dot_header "Chezmoi Repository Size"
    echo

    # Total size
    local total_size=$(du -sh "$chezmoi_dir" 2>/dev/null | cut -f1)
    echo "Total: $total_size"
    echo

    # Top 10 largest files
    _dot_info "Top 10 largest files:"
    (
        cd "$chezmoi_dir" || return 1
        find . -type f -not -path "./.git/*" -exec du -h {} + 2>/dev/null | \
        sort -rh | \
        head -10 | \
        while IFS=$'\t' read -r size path; do
            # Strip leading ./
            path="${path#./}"

            # Warn if .git in path
            if [[ "$path" == *".git"* ]] || [[ "$path" == *"dot_git"* ]]; then
                echo "  ⚠️  $size  $path"
                echo "      (Git metadata - should be ignored)"
            else
                echo "      $size  $path"
            fi
        done
    )
    echo

    # Check for nested .git directories
    local git_count=$(find "$chezmoi_dir" -name ".git" -type d -not -path "$chezmoi_dir/.git" 2>/dev/null | wc -l | tr -d ' ')
    local git_dot_count=$(find "$chezmoi_dir" -name "dot_git" -type d 2>/dev/null | wc -l | tr -d ' ')
    local total_git_dirs=$((git_count + git_dot_count))

    if (( total_git_dirs > 0 )); then
        _dot_warn "Found $total_git_dirs nested git directories (should be ignored)"
        _dot_info "Fix with: dot ignore add '**/.git' && chezmoi forget '.config/*/.git'"
        echo
    else
        _dot_success "No nested git directories tracked"
    fi

    # Check for large files (>100KB)
    local large_count=$(find "$chezmoi_dir" -type f -not -path "./.git/*" -size +100k 2>/dev/null | wc -l | tr -d ' ')
    if (( large_count > 0 )); then
        _dot_warn "Found $large_count files larger than 100KB"
        _dot_info "Consider reviewing with: find ~/.local/share/chezmoi -type f -size +100k"
    fi
    ;;
```

**Testing:**
```bash
dot size
# Expected: Shows total size, top 10 files, warnings for .git dirs
```

#### 2.2 Doctor Integration
**File:** `lib/dispatchers/dot-dispatcher.zsh`

```zsh
_dot_doctor_check_chezmoi_health() {
    local chezmoi_dir="$HOME/.local/share/chezmoi"
    local ignore_file="$chezmoi_dir/.chezmoiignore"

    _dot_header "Dotfile Management"

    # Check chezmoi installed
    if command -v chezmoi &>/dev/null; then
        local version=$(chezmoi --version 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        _dot_success "chezmoi installed ($version)"
    else
        _dot_error "chezmoi not installed"
        _dot_info "Install with: brew install chezmoi"
        return 1
    fi

    # Check repository initialized
    if [[ -d "$chezmoi_dir/.git" ]]; then
        _dot_success "Repository initialized"

        # Check remote connection
        local remote=$(cd "$chezmoi_dir" && git remote get-url origin 2>/dev/null)
        if [[ -n "$remote" ]]; then
            _dot_success "Connected to remote ($remote)"
        else
            _dot_warn "No remote repository configured"
            _dot_info "Add with: chezmoi git remote add origin <url>"
        fi
    else
        _dot_error "Repository not initialized"
        _dot_info "Initialize with: chezmoi init"
        return 1
    fi

    # Check .chezmoiignore
    if [[ -f "$ignore_file" ]]; then
        local pattern_count=$(grep -c -v '^$' "$ignore_file" 2>/dev/null || echo 0)
        if (( pattern_count > 0 )); then
            _dot_success ".chezmoiignore configured ($pattern_count patterns)"
        else
            _dot_warn ".chezmoiignore is empty"
            _dot_info "Add patterns with: dot ignore add <pattern>"
        fi
    else
        _dot_warn "No .chezmoiignore file found"
        _dot_info "Create with: dot ignore add '**/.git'"
    fi

    # Check managed file count
    local managed_count=$(chezmoi managed 2>/dev/null | wc -l | tr -d ' ')
    if (( managed_count > 0 )); then
        _dot_success "$managed_count files managed"
    else
        _dot_warn "No files managed by chezmoi"
    fi

    # Check repository size
    if [[ -d "$chezmoi_dir" ]]; then
        local size_bytes=$(du -sk "$chezmoi_dir" 2>/dev/null | cut -f1)
        local size_mb=$((size_bytes / 1024))

        if (( size_mb < 5 )); then
            _dot_success "Repository size: ${size_mb} MB (healthy)"
        elif (( size_mb < 20 )); then
            _dot_warn "Repository size: ${size_mb} MB (consider cleanup)"
            _dot_info "Analyze with: dot size"
        else
            _dot_error "Repository size: ${size_mb} MB (too large)"
            _dot_info "Cleanup with: dot size"
        fi
    fi

    # Check for large files
    local large_files=$(find "$chezmoi_dir" -type f -not -path "$chezmoi_dir/.git/*" -size +100k 2>/dev/null)
    if [[ -n "$large_files" ]]; then
        _dot_warn "Large files tracked (>100KB):"
        echo "$large_files" | while read -r file; do
            local size=$(du -h "$file" 2>/dev/null | cut -f1)
            local rel_path="${file#$chezmoi_dir/}"
            echo "  - $size  $rel_path"
        done
        _dot_info "Consider adding ignore patterns"
    else
        _dot_success "No large files tracked"
    fi

    # Check for nested .git
    local git_dirs=$(find "$chezmoi_dir" -name ".git" -type d -not -path "$chezmoi_dir/.git" 2>/dev/null)
    local git_dot_dirs=$(find "$chezmoi_dir" -name "dot_git" -type d 2>/dev/null)

    if [[ -n "$git_dirs" ]] || [[ -n "$git_dot_dirs" ]]; then
        _dot_error "Git directories tracked (should be ignored):"
        if [[ -n "$git_dirs" ]]; then
            echo "$git_dirs" | while read -r gitdir; do
                echo "  - ${gitdir#$chezmoi_dir/}"
            done
        fi
        if [[ -n "$git_dot_dirs" ]]; then
            echo "$git_dot_dirs" | while read -r gitdir; do
                echo "  - ${gitdir#$chezmoi_dir/}"
            done
        fi
        _dot_info "Fix with: dot ignore add '**/.git'"
    else
        _dot_success "No nested git directories tracked"
    fi

    # Check sync status
    local status=$(_dot_get_sync_status 2>/dev/null || echo "unknown")
    local last_sync=$(_dot_get_last_sync_time 2>/dev/null || echo "never")

    case "$status" in
        "synced")
            _dot_success "Last sync: $last_sync (synced)"
            ;;
        "modified")
            _dot_warn "Last sync: $last_sync (local changes)"
            _dot_info "Sync with: dot push"
            ;;
        "behind")
            _dot_warn "Last sync: $last_sync (behind remote)"
            _dot_info "Pull with: dot sync"
            ;;
        "ahead")
            _dot_info "Last sync: $last_sync (ahead of remote)"
            _dot_info "Push with: dot push"
            ;;
        *)
            _dot_info "Sync status: $status"
            ;;
    esac
}
```

**Integration:** Add call to existing `flow doctor` command

**Testing:**
```bash
flow doctor
# Expected: Includes "Dotfile Management" section with all checks
```

### Phase 3: Completions & Documentation
**Effort:** 2-4 hours

#### 3.1 Update Completions
**File:** `completions/_dot`

Add completions for new commands:
```zsh
# After existing completions, add:
'ignore:manage ignore patterns:->ignore_cmd'

case $state in
    ignore_cmd)
        local -a ignore_cmds
        ignore_cmds=(
            'add:add ignore pattern'
            'list:list ignore patterns'
            'ls:list ignore patterns (alias)'
            'remove:remove ignore pattern'
            'rm:remove ignore pattern (alias)'
            'edit:edit .chezmoiignore file'
        )
        _describe -t commands 'ignore commands' ignore_cmds
        ;;
esac
```

#### 3.2 Update Documentation
**Files:**
- `docs/specs/dot-dispatcher-refcard.md` - Add new commands
- `docs/specs/SPEC-dotfile-integration-2026-01-08.md` - Mark enhancements
- `README.md` - Update feature list

**Updates:**
- Add `dot ignore` section with examples
- Add `dot size` to troubleshooting section
- Update `flow doctor` section
- Add FAQ: "How do I prevent tracking .git directories?"

---

## Testing Strategy

### Unit Tests
**File:** `tests/test-dot-chezmoi-safety.zsh`

```zsh
#!/usr/bin/env zsh

# Test git directory detection
test_git_detection() {
    local test_dir="/tmp/test-dot-$$"
    mkdir -p "$test_dir/.git"

    local result=$(_dot_check_git_in_path "$test_dir")
    [[ -n "$result" ]] && echo "✓ Git detection works"

    rm -rf "$test_dir"
}

# Test ignore management
test_ignore_management() {
    local ignore_file="/tmp/test-chezmoiignore-$$"
    HOME="/tmp" dot ignore add "**/.git" 2>&1

    [[ -f "$ignore_file" ]] && grep -q ".git" "$ignore_file" && echo "✓ Ignore add works"

    rm -f "$ignore_file"
}

# Test preview calculation
test_preview_calculation() {
    local test_dir="/tmp/test-preview-$$"
    mkdir -p "$test_dir"
    echo "test" > "$test_dir/file1.txt"
    dd if=/dev/zero of="$test_dir/large.bin" bs=1024 count=100 2>/dev/null

    # Mock preview (capture output)
    local output=$(_dot_preview_add "$test_dir" 2>&1)

    [[ "$output" == *"Files to add: 2"* ]] && echo "✓ Preview counts files"
    [[ "$output" == *"Large files detected"* ]] && echo "✓ Preview detects large files"

    rm -rf "$test_dir"
}

# Run tests
echo "Running dot chezmoi safety tests..."
test_git_detection
test_ignore_management
test_preview_calculation
echo "Tests complete"
```

### Integration Tests
**Scenarios:**
1. Add directory with .git → Verify warning and ignore prompt
2. Add directory with .log files → Verify suggestion
3. Run `dot size` → Verify output format
4. Run `flow doctor` → Verify chezmoi section included
5. Use `dot ignore add/list/remove` → Verify file modified correctly

### Manual Test Checklist

```markdown
## Pre-flight
- [ ] Backup ~/.local/share/chezmoi
- [ ] Backup ~/.config/nvim

## Git Detection
- [ ] Create test dir with .git
- [ ] Run `dot add <dir>`
- [ ] Verify warning shown
- [ ] Accept auto-ignore
- [ ] Verify .chezmoiignore updated
- [ ] Verify `chezmoi managed` doesn't list .git files

## Preview Functionality
- [ ] Create dir with mix of files (small, large, .log, .sqlite)
- [ ] Run `dot add <dir>`
- [ ] Verify file count shown
- [ ] Verify size calculated
- [ ] Verify warnings for large/.log/.sqlite
- [ ] Accept auto-ignore suggestions
- [ ] Verify correct files added

## Ignore Management
- [ ] Run `dot ignore add "*.log"`
- [ ] Run `dot ignore list` - verify shown
- [ ] Run `dot ignore remove "*.log"`
- [ ] Run `dot ignore list` - verify removed
- [ ] Run `dot ignore edit` - verify opens editor

## Size Analysis
- [ ] Run `dot size`
- [ ] Verify total size shown
- [ ] Verify top 10 files listed
- [ ] Verify .git warning if present
- [ ] Verify large file count if present

## Doctor Integration
- [ ] Run `flow doctor`
- [ ] Verify "Dotfile Management" section present
- [ ] Verify checks: installed, initialized, remote, .chezmoiignore, files managed, size, large files, .git dirs, sync status
- [ ] Verify actionable recommendations shown

## Performance
- [ ] Time `dot add <large-dir>` - verify < 2s
- [ ] Time `dot ignore list` - verify < 0.5s
- [ ] Time `dot size` - verify < 3s
- [ ] Time `flow doctor` chezmoi section - verify < 2s

## Edge Cases
- [ ] Run `dot add` on non-existent path - verify error
- [ ] Run `dot ignore remove` on non-existent pattern - verify error
- [ ] Run `dot size` with no chezmoi repo - verify error
- [ ] Run with empty .chezmoiignore - verify works
- [ ] Run with missing .chezmoiignore - verify creates
```

---

## Documentation Updates

### Quick Reference Card
**File:** `docs/specs/dot-dispatcher-refcard.md`

Add sections:
```markdown
## Ignore Pattern Management

| Command | Action |
|---------|--------|
| `dot ignore add <pattern>` | Add ignore pattern |
| `dot ignore list` | List all patterns |
| `dot ignore remove <pattern>` | Remove pattern |
| `dot ignore edit` | Edit .chezmoiignore |

## Repository Health

| Command | Action |
|---------|--------|
| `dot size` | Analyze repository size |
| `flow doctor` | Health checks (includes chezmoi) |

## Safety Features

- **Git detection**: Warns when adding .git directories
- **Preview**: Shows file count/size before adding
- **Auto-suggestions**: Intelligent ignore pattern suggestions
- **Large file warnings**: Alerts for files >50KB
```

### Help Text
Update `dot` help command:

```zsh
"help"|"h"|"-h"|"--help")
    _dot_header "Dotfile Management (dot)"
    echo
    echo "Usage: dot <command> [args]"
    echo
    echo "Status & Info:"
    echo "  status, s          Show sync status and quick actions"
    echo "  help, h            Show this help"
    echo
    echo "File Management:"
    echo "  add <file>         Add file to chezmoi (with preview)"
    echo "  edit <file>        Edit dotfile with auto-apply"
    echo "  diff, d            Show pending changes"
    echo "  apply              Apply changes with backup"
    echo
    echo "Sync Operations:"
    echo "  sync, pull         Pull from remote with preview"
    echo "  push, p            Push to remote"
    echo
    echo "Ignore Patterns:"
    echo "  ignore add <pat>   Add ignore pattern"
    echo "  ignore list        List all patterns"
    echo "  ignore remove <pat> Remove pattern"
    echo "  ignore edit        Edit .chezmoiignore"
    echo
    echo "Repository Health:"
    echo "  size               Analyze repository size"
    echo
    echo "Secrets:"
    echo "  secret <name>      Retrieve secret"
    echo "  token <type>       Manage API tokens"
    echo
    echo "Troubleshooting:"
    echo "  doctor             Health checks (via 'flow doctor')"
    echo "  undo               Undo last apply"
    echo
    echo "Options:"
    echo "  --no-preview       Skip preview on add"
    echo
    echo "Examples:"
    echo "  dot add ~/.zshrc"
    echo "  dot ignore add '**/.git'"
    echo "  dot size"
    ;;
```

---

## Success Criteria

### Functional Requirements
- [x] Git directory detection warns before adding
- [x] Auto-creates ignore patterns on user confirmation
- [x] Preview shows file count, size, warnings
- [x] Auto-suggests ignore patterns for .log/.sqlite/.db/.cache
- [x] `dot ignore` manages patterns without manual editing
- [x] `dot size` reports repository size and identifies bloat
- [x] `flow doctor` includes comprehensive chezmoi health checks
- [x] All operations complete within performance targets

### Non-Functional Requirements
- [x] Maintains existing `dot` command behavior (backward compatible)
- [x] No breaking changes to existing workflows
- [x] Preserves < 3s performance target for all commands
- [x] Clear, actionable error messages
- [x] ADHD-friendly output (scannable, hierarchical)

### User Experience
- [x] No false positives in git detection
- [x] Confirmation prompts respect muscle memory (Y default)
- [x] Preview can be skipped with --no-preview flag
- [x] Help text includes all new commands
- [x] Completions work for all new commands

---

## Rollback Plan

If issues arise:

1. **Backup restoration:**
   ```bash
   # Restore chezmoi repo
   cd ~/.local/share/chezmoi
   git reset --hard <commit-before-changes>

   # Restore flow-cli
   cd ~/projects/dev-tools/flow-cli
   git checkout <previous-version-tag>
   ```

2. **Feature flags:**
   - Add `FLOW_DOT_PREVIEW_ENABLED` env var (default: true)
   - Add `FLOW_DOT_GIT_CHECK_ENABLED` env var (default: true)
   - Users can disable with `export FLOW_DOT_PREVIEW_ENABLED=false`

3. **Gradual rollout:**
   - Phase 1: Git detection only
   - Phase 2: Add preview (opt-in with --preview flag)
   - Phase 3: Make preview default (opt-out with --no-preview)

---

## Future Enhancements (Out of Scope)

### Phase 4 Candidates
1. **Conflict resolution UI** - Interactive 3-way merge for chezmoi conflicts
2. **Template validation** - Check chezmoi templates for syntax errors
3. **Backup history** - Show last N backups, restore from backup
4. **Multi-machine sync status** - Show which machines are ahead/behind
5. **Secret rotation reminders** - Warn when tokens/secrets are old

### Integration Opportunities
1. **`work` command** - Auto-sync dotfiles on session start
2. **Dashboard** - Show dotfile health score
3. **Plugin system** - Allow custom ignore pattern rules

---

## Appendix

### Example Outputs

#### `dot add` with git detection
```
$ dot add ~/.config/ghostty

⚠️  Git directory detected in /Users/dt/.config/ghostty
    Git metadata should not be tracked by chezmoi.

Auto-create ignore rule? (Y/n): y
✓ Added .config/ghostty/.git to .chezmoiignore
✓ Added .config/ghostty/.git/** to .chezmoiignore

Preview: dot add /Users/dt/.config/ghostty
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Files to add: 12
Total size: 24 KB

Proceed with add? (Y/n): y
✓ Added /Users/dt/.config/ghostty to chezmoi
```

#### `dot size` output
```
$ dot size

Chezmoi Repository Size
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total: 1.2 MB

Top 10 largest files:
      7.4 KB  dot_config/wezterm/wezterm.lua
      6.9 KB  dot_config/CLAUDE.md
      6.3 KB  dot_config/nvim/lazy-lock.json
      3.4 KB  dot_config/starship.toml
      3.1 KB  dot_config/GEMINI.md
      1.4 KB  dot_config/nvim/lazyvim.json
      1.2 KB  dot_config/ghostty/config
      0.8 KB  dot_config/git/ignore
      0.5 KB  dot_config/git/gitk
      0.4 KB  dot_zshrc

✓ No nested git directories tracked
```

#### `flow doctor` with chezmoi checks
```
$ flow doctor

System Health Check
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

... (existing checks) ...

Dotfile Management:
  ✓ chezmoi installed (v2.69.3)
  ✓ Repository initialized
  ✓ Connected to remote (github.com/data-wise/dotfiles)
  ✓ .chezmoiignore configured (5 patterns)
  ✓ 47 files managed
  ✓ Repository size: 1.2 MB (healthy)
  ✓ No large files tracked
  ✓ No nested git directories tracked
  ✓ Last sync: 2 hours ago (synced)
```

---

**End of Specification**
