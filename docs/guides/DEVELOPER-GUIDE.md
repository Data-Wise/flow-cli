# flow-cli Developer Guide

**Version:** 5.10.0
**Last Updated:** 2026-01-15
**Audience:** Contributors, Plugin Developers, Advanced Users

---

## Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Architecture Overview](#architecture-overview)
- [Adding New Features](#adding-new-features)
- [Testing](#testing)
- [Code Style](#code-style)
- [Documentation](#documentation)
- [Release Process](#release-process)

---

## Getting Started

### Prerequisites

**Required:**
- macOS 10.15+ or Linux
- ZSH 5.8+
- Git 2.30+
- Basic shell scripting knowledge

**Recommended:**
- fzf 0.40+ (for interactive features)
- Claude CLI (for AI integration testing)
- tmux (for session management features)

### Clone and Setup

```bash
# Clone repository
git clone https://github.com/Data-Wise/flow-cli.git
cd flow-cli

# Load plugin in current shell
source flow.plugin.zsh

# Verify installation
flow --version
```

---

## Development Setup

### Project Structure

```
flow-cli/
├── flow.plugin.zsh           # Plugin entry point
├── lib/                       # Core libraries
│   ├── core.zsh              # Utilities, colors, logging
│   ├── config.zsh            # Configuration handling
│   ├── project-cache.zsh     # Project caching
│   ├── config-validator.zsh  # Schema validation
│   └── dispatchers/          # 11 dispatchers
├── commands/                  # Command implementations
│   ├── work.zsh              # work, finish, hop
│   ├── pick.zsh              # Project picker
│   ├── dash.zsh              # Dashboard
│   └── ...
├── completions/              # ZSH completions
├── hooks/                    # ZSH hooks (chpwd, precmd)
├── tests/                    # Test suites
│   ├── test-*.zsh           # Unit/integration tests
│   └── interactive-*.zsh    # Interactive tests
└── docs/                     # Documentation
    ├── reference/           # API reference
    ├── guides/              # How-to guides
    └── tutorials/           # Step-by-step tutorials
```

### Development Workflow

1. **Create Feature Branch:**

   ```bash
   # IMPORTANT: Always work on dev branch, never main
   git checkout dev
   git pull origin dev

   # Create feature branch via worktree
   git worktree add ~/.git-worktrees/flow-cli-feature -b feature/my-feature dev
   ```

2. **Make Changes:**

   ```bash
   cd ~/.git-worktrees/flow-cli-feature
   # Edit files
   ```

3. **Test Changes:**

   ```bash
   # Reload plugin
   source flow.plugin.zsh

   # Run relevant tests
   ./tests/test-my-feature.zsh

   # Run all tests
   ./tests/run-all.sh
   ```

4. **Commit and PR:**

   ```bash
   git add -A
   git commit -m "feat: add new feature"
   git push origin feature/my-feature

   # Create PR to dev (NOT main)
   gh pr create --base dev
   ```

---

## Architecture Overview

### Core Principles

**1. Pure ZSH**
- No Node.js runtime required
- All commands are native ZSH functions
- Sub-10ms response time for core commands

**2. ADHD-Friendly Design**
- Discoverable: Built-in help (`<cmd> help`)
- Consistent: Same patterns everywhere
- Forgiving: Smart defaults, no errors on typos
- Fast: Instant feedback

**3. Dispatcher Pattern**
- One function per domain (e.g., `g` for git, `r` for R)
- Subcommands for specific operations
- Self-documenting help system

**4. Optional Enhancement**
- Atlas integration is optional
- Graceful degradation without dependencies

### Key Modules

#### `lib/core.zsh`

**Purpose:** Core utilities shared by all commands

**Exports:**
- `FLOW_COLORS` - Color scheme
- `_flow_log_*` - Logging functions
- `_flow_find_project_root` - Project detection
- `_flow_detect_project_type` - Type detection

**Usage:**

```zsh
source lib/core.zsh

_flow_log_success "Task completed"
root=$(_flow_find_project_root)
```

#### `lib/project-cache.zsh`

**Purpose:** Project scanning and caching

**Exports:**
- `_proj_scan_projects` - Full project scan
- `_proj_cache_invalidate` - Clear cache
- `_proj_list_worktrees` - List git worktrees

**Cache TTL:** 5 minutes

**Usage:**

```zsh
# Invalidate after worktree operations
_proj_cache_invalidate

# Get cached project list
projects=$(_proj_scan_projects)
```

#### `lib/config-validator.zsh`

**Purpose:** YAML config validation via JSON Schema

**Exports:**
- `_teach_validate_config` - Validate config file
- `_teach_config_hash` - Calculate SHA-256 hash

**Schema:** `lib/templates/teaching/teach-config.schema.json`

**Usage:**

```zsh
if _teach_validate_config "teach-config.yml"; then
    echo "Valid"
else
    echo "Invalid"
fi
```

---

## Adding New Features

### Adding a New Dispatcher

**Step 1:** Create dispatcher file

```bash
touch lib/dispatchers/my-dispatcher.zsh
```

**Step 2:** Implement dispatcher

```zsh
# lib/dispatchers/my-dispatcher.zsh

# Main dispatcher function (single-letter or 2-letter)
my() {
    case "$1" in
        action1)
            shift
            _my_action1 "$@"
            ;;
        action2)
            shift
            _my_action2 "$@"
            ;;
        help|--help|-h)
            _my_help
            ;;
        *)
            _my_help
            return 1
            ;;
    esac
}

_my_action1() {
    local arg="$1"
    _flow_log_info "Executing action1 with: $arg"
    # Implementation
}

_my_action2() {
    _flow_log_success "Executing action2"
    # Implementation
}

_my_help() {
    cat << 'EOF'
Usage: my <subcommand> [options]

Subcommands:
  action1 <arg>  Do something with arg
  action2        Do something else

Examples:
  my action1 foo
  my action2
EOF
}
```

**Step 3:** Register in `flow.plugin.zsh`

```zsh
# Add to plugin file
source "$FLOW_PLUGIN_DIR/lib/dispatchers/my-dispatcher.zsh"
```

**Step 4:** Add completion

```zsh
# completions/_my
#compdef my

_my() {
    local -a commands
    commands=(
        'action1:Do something'
        'action2:Do something else'
    )

    _describe 'my commands' commands
}

_my "$@"
```

**Step 5:** Add tests

```zsh
# tests/test-my-dispatcher.zsh
source "${0:a:h}/../flow.plugin.zsh"

test_my_action1() {
    result=$(my action1 test)
    [[ "$result" == *"test"* ]] || {
        echo "FAIL: action1 test"
        return 1
    }
    echo "PASS: action1 test"
}

test_my_action1
```

**Step 6:** Update documentation

- Add to `do../reference/MASTER-DISPATCHER-GUIDE.md`
- Add to `docs/help/QUICK-REFERENCE.md`
- Update `CLAUDE.md` if needed

### Adding a New Command

**Step 1:** Create command file

```bash
touch commands/mycommand.zsh
```

**Step 2:** Implement command

```zsh
# commands/mycommand.zsh

mycommand() {
    local option=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --option)
                option="$2"
                shift 2
                ;;
            --help|-h)
                _mycommand_help
                return 0
                ;;
            *)
                _flow_log_error "Unknown argument: $1"
                return 1
                ;;
        esac
    done

    # Implementation
    _flow_log_success "Executed with option: $option"
}

_mycommand_help() {
    cat << 'EOF'
Usage: mycommand [--option VALUE]

Description:
  Do something useful

Options:
  --option VALUE  Set option value

Examples:
  mycommand --option foo
EOF
}
```

**Step 3:** Source in plugin

```zsh
# flow.plugin.zsh
source "$FLOW_PLUGIN_DIR/commands/mycommand.zsh"
```

**Step 4:** Add completion**

```zsh
# completions/_mycommand
#compdef mycommand

_mycommand() {
    _arguments \
        '--option[Set option value]:value:' \
        '--help[Show help]'
}

_mycommand "$@"
```

**Step 5:** Add tests

```zsh
# tests/test-mycommand.zsh
source "${0:a:h}/../flow.plugin.zsh"

test_mycommand_basic() {
    result=$(mycommand --option test)
    [[ "$result" == *"test"* ]] || {
        echo "FAIL: basic test"
        return 1
    }
    echo "PASS: basic test"
}

test_mycommand_basic
```

---

## Testing

### Test Structure

**Test File Naming:**
- `test-<feature>.zsh` - Unit/integration tests
- `interactive-<feature>.zsh` - Interactive tests (require user input)

**Test Pattern:**

```zsh
#!/usr/bin/env zsh

# Load plugin
source "${0:a:h}/../flow.plugin.zsh"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test function
test_feature() {
    ((TESTS_RUN++))

    # Setup
    local expected="value"

    # Execute
    local actual=$(command_under_test)

    # Assert
    if [[ "$actual" == "$expected" ]]; then
        ((TESTS_PASSED++))
        echo "✓ Test passed"
        return 0
    else
        ((TESTS_FAILED++))
        echo "✗ Test failed: expected '$expected', got '$actual'"
        return 1
    fi
}

# Run tests
test_feature

# Report
echo ""
echo "Tests run: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"

[[ $TESTS_FAILED -eq 0 ]]
```

### Assertion Helpers

```zsh
# String equality
assert_equals() {
    local expected="$1"
    local actual="$2"
    [[ "$actual" == "$expected" ]] || {
        echo "Expected: $expected"
        echo "Got: $actual"
        return 1
    }
}

# Contains substring
assert_contains() {
    local haystack="$1"
    local needle="$2"
    [[ "$haystack" == *"$needle"* ]] || {
        echo "Expected to contain: $needle"
        echo "Got: $haystack"
        return 1
    }
}

# File exists
assert_file_exists() {
    [[ -f "$1" ]] || {
        echo "File not found: $1"
        return 1
    }
}
```

### Running Tests

**Run All Tests:**

```bash
./tests/run-all.sh
```

**Run Specific Test:**

```bash
./tests/test-pick-command.zsh
```

**Run with Debug Output:**

```bash
FLOW_DEBUG=1 ./tests/test-my-feature.zsh
```

### Mock Environment

```zsh
# Create temporary test directory
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# Mock git repository
git init
git config user.name "Test User"
git config user.email "test@example.com"

# Cleanup after test
cleanup() {
    cd /
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT
```

### Test Coverage

**Current Coverage:**
- Core functions: 100%
- Dispatchers: 100%
- Commands: ~95%

**Coverage Goals:**
- New features: 100% coverage required
- Bug fixes: Add regression test

---

## Code Style

### ZSH Best Practices

**1. Function Naming:**
- Public functions: `commandname` or `dispatcher`
- Private functions: `_internal_function`
- Dispatcher subcommands: `_dispatcher_subcommand`

**2. Variable Naming:**
- Local variables: lowercase with underscores
- Global variables: UPPERCASE
- Associative arrays: UPPERCASE

**3. Quoting:**
- Always quote variables: `"$var"`
- Use `$()` for command substitution
- Avoid backticks

**4. Error Handling:**

```zsh
# Check command success
if command; then
    _flow_log_success "Success"
else
    _flow_log_error "Failed"
    return 1
fi

# Check exit code
if [[ $? -ne 0 ]]; then
    _flow_log_error "Previous command failed"
    return 1
fi
```

**5. Arrays:**

```zsh
# Declare arrays
local -a items
items=("item1" "item2" "item3")

# Iterate
for item in "${items[@]}"; do
    echo "$item"
done

# Length
echo "${#items[@]}"
```

**6. Associative Arrays:**

```zsh
# Declare
typeset -gA MY_ARRAY
MY_ARRAY=(
    [key1]="value1"
    [key2]="value2"
)

# Access
echo "${MY_ARRAY[key1]}"

# Iterate
for key in "${(@k)MY_ARRAY}"; do
    echo "$key = ${MY_ARRAY[$key]}"
done
```

### Code Formatting

**Indentation:**
- Use 4 spaces (not tabs)
- Consistent indentation throughout

**Line Length:**
- Prefer lines under 80 characters
- Break long lines at logical points

**Comments:**

```zsh
# Single-line comment

# Multi-line description
# continues here
# and here

function_name() {
    # Brief description of function
    local var="value"  # Inline comment
}
```

### Color Usage

**Always use FLOW_COLORS:**

```zsh
# Good
echo -e "${FLOW_COLORS[success]}✓ Success${FLOW_COLORS[reset]}"

# Bad
echo -e "\033[32m✓ Success\033[0m"
```

**Available Colors:**
- `success`, `warning`, `error`, `info`
- `active`, `paused`, `blocked`, `archived`
- `header`, `accent`, `muted`, `cmd`

---

## Documentation

### Required Documentation

**For New Features:**
1. Add to `CLAUDE.md` (AI context)
2. Add to reference docs (`docs/reference/`)
3. Add to quick reference (`docs/help/QUICK-REFERENCE.md`)
4. Add examples to guides (`docs/guides/`)

**For Bug Fixes:**
1. Update relevant docs if behavior changed
2. Add regression test

### Documentation Style

**Command Documentation:**

```markdown
### command-name

**Description:** Brief one-line description

**Usage:** `command-name [options] <args>`

**Parameters:**
- `arg1` (type): Description
- `--option` (flag): Description

**Examples:**
```bash
command-name foo
command-name --option bar
```

**See Also:** Related commands

```

**API Documentation:**
```markdown
#### function_name(param1, param2)

**Description:** What the function does

**Parameters:**
- `param1` (type): Parameter description
- `param2` (type, optional): Optional parameter

**Returns:**
- type: Return value description
- Exit code: 0 on success, 1 on failure

**Example:**
```zsh
result=$(function_name "arg1" "arg2")
```

```

---

<a id="release-process"></a>

## Release Process

### Version Numbering

**Semantic Versioning:** `MAJOR.MINOR.PATCH`

- **MAJOR:** Breaking changes
- **MINOR:** New features (backward compatible)
- **PATCH:** Bug fixes

**Example:** v5.10.0
- Major: 5 (current architecture)
- Minor: 10 (worktree detection feature)
- Patch: 0 (initial release of feature)

### Release Checklist

**1. Prepare Release (on dev branch):**
```bash
# Update version numbers
./scripts/release.sh 5.10.0

# Verify changes
git diff

# Commit version bump
git add -A
git commit -m "chore: bump version to v5.10.0"
git push origin dev
```

**2. Create Release PR:**

```bash
# Create PR from dev to main
gh pr create \
    --base main \
    --head dev \
    --title "Release v5.10.0" \
    --body "$(cat CHANGELOG.md)"
```

**3. After PR Merge:**

```bash
# Checkout main and tag
git checkout main
git pull origin main

# Create and push tag
git tag -a v5.10.0 -m "Release v5.10.0"
git push origin v5.10.0
```

**4. GitHub Release:**
- GitHub Actions automatically creates release from tag
- Homebrew formula automatically updated via PR

**5. Verify Release:**

```bash
# Test Homebrew install
brew update
brew upgrade flow-cli
flow --version  # Should show 5.10.0
```

---

## Common Development Tasks

### Debugging

**Enable Debug Mode:**

```bash
export FLOW_DEBUG=1
```

**Debug Output:**

```zsh
[[ -n "$FLOW_DEBUG" ]] && echo "Debug: $variable"
```

**Trace Execution:**

```bash
zsh -x flow.plugin.zsh
```

### Profiling Performance

```zsh
# Time a command
time mycommand

# Profile with zprof
zmodload zsh/zprof
source flow.plugin.zsh
mycommand
zprof
```

### Working with Worktrees

```bash
# List worktrees
git worktree list

# Create feature worktree
git worktree add ~/.git-worktrees/flow-cli-feature -b feature/name dev

# Remove worktree
git worktree remove ~/.git-worktrees/flow-cli-feature

# Prune deleted worktrees
git worktree prune
```

---

## Troubleshooting

### Common Issues

**Issue:** Changes not taking effect
**Solution:** Reload plugin

```bash
source flow.plugin.zsh
```

**Issue:** Completion not working
**Solution:** Rebuild completion cache

```bash
rm -f ~/.zcompdump
compinit
```

**Issue:** Cache stale
**Solution:** Invalidate cache

```zsh
_proj_cache_invalidate
```

**Issue:** Test failures
**Solution:** Check for environment differences

```bash
# Reset test environment
unset FLOW_DEBUG
unset FLOW_QUIET

# Clean cache
rm -rf ~/.cache/flow-cli

# Run tests
./tests/test-feature.zsh
```

---

## Contributing Guidelines

### Before Submitting PR

- [ ] All tests pass (`./tests/run-all.sh`)
- [ ] Code follows style guide
- [ ] New features have tests (100% coverage)
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Commit messages follow conventional commits
- [ ] PR targets `dev` branch (NOT `main`)

### Conventional Commits

**Format:** `type(scope): description`

**Types:**
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation only
- `refactor:` Code restructure
- `test:` Add/modify tests
- `chore:` Maintenance

**Examples:**

```
feat(wt): add cache invalidation on worktree create
fix(pick): handle flat worktree naming
docs: update API reference for v5.10.0
test: add regression test for worktree detection
```

---

## Resources

- **GitHub:** https://github.com/Data-Wise/flow-cli
- **Documentation:** https://Data-Wise.github.io/flow-cli/
- **Issues:** https://github.com/Data-Wise/flow-cli/issues
- **Discussions:** https://github.com/Data-Wise/flow-cli/discussions

---

## Getting Help

- Check existing docs first
- Search GitHub issues
- Ask in GitHub Discussions
- Reach out to maintainers

---

**Last Updated:** 2026-01-15
**Version:** 5.10.0
