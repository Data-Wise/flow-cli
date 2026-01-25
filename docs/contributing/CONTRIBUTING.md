# Contributing to flow-cli

Thank you for your interest in contributing! This guide will help you get started.

---

## Quick Start

### Prerequisites

- **ZSH** (default shell on macOS)
- **Git** (for version control)
- **fzf** (optional, for interactive features)

### Setup

1. **Clone the repository:**

   ```bash
   git clone https://github.com/Data-Wise/flow-cli.git
   cd flow-cli
   ```

2. **Source the plugin:**

   ```bash
   source flow.plugin.zsh
   ```

3. **Run tests:**

   ```bash
   zsh tests/test-cc-dispatcher.zsh
   ```

4. **Build documentation (optional):**

   ```bash
   mkdocs serve
   # Visit http://127.0.0.1:8000
   ```

---

## Project Structure

```
flow-cli/
├── flow.plugin.zsh           # Plugin entry point
├── lib/
│   ├── core.zsh              # Colors, logging, utilities
│   ├── atlas-bridge.zsh      # Optional Atlas integration
│   ├── project-detector.zsh  # Project type detection
│   ├── tui.zsh               # Terminal UI components
│   └── dispatchers/          # Smart command dispatchers
│       ├── cc-dispatcher.zsh     # Claude Code
│       ├── g-dispatcher.zsh      # Git workflows
│       ├── wt-dispatcher.zsh     # Worktrees
│       ├── mcp-dispatcher.zsh    # MCP servers
│       ├── r-dispatcher.zsh      # R packages
│       ├── qu-dispatcher.zsh     # Quarto
│       ├── tm-dispatcher.zsh     # Terminal
│       └── obs.zsh               # Obsidian
├── commands/                 # Core command implementations
├── completions/              # ZSH completions
├── tests/                    # Test suite
└── docs/                     # Documentation (MkDocs)
```

---

## Development Workflow

### Making Changes

1. **Create a feature branch:**

   ```bash
   g feature start my-feature
   # or: git checkout -b feature/my-feature
   ```

2. **Make your changes:**
   - Dispatchers: `lib/dispatchers/<name>-dispatcher.zsh`
   - Commands: `commands/<name>.zsh`
   - Core utilities: `lib/core.zsh`

3. **Test your changes:**

   ```bash
   # Source and test manually
   source flow.plugin.zsh
   my_command help

   # Run automated tests
   zsh tests/test-<name>-dispatcher.zsh
   ```

4. **Commit your changes:**

   ```bash
   git add .
   git commit -m "feat: add new feature"
   ```

### Commit Message Format

We use conventional commits:

```
<type>(<scope>): <description>
```

**Types:**

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**

```
feat(cc): add worktree integration
fix(g): handle missing dev branch
docs(reference): update dispatcher docs
test(mcp): add validation tests
```

---

## Testing

### Running Tests

```bash
# Run specific dispatcher test
zsh tests/test-cc-dispatcher.zsh

# Run all dispatcher tests
for f in tests/test-*-dispatcher.zsh; do zsh "$f"; done

# Interactive validation (fun!)
./tests/interactive-dog-feeding.zsh
```

### Writing Tests

Create `tests/test-<name>.zsh`:

```zsh
#!/usr/bin/env zsh

# Test framework
TESTS_PASSED=0
TESTS_FAILED=0

pass() {
    echo "✓ PASS"
    ((TESTS_PASSED++))
}

fail() {
    echo "✗ FAIL - $1"
    ((TESTS_FAILED++))
}

# Setup
setup() {
    local project_root="${0:A:h:h}"
    source "$project_root/lib/dispatchers/my-dispatcher.zsh"
}

# Tests
test_help_shows_usage() {
    echo -n "Testing: help shows usage ... "
    local output=$(my_command help 2>&1)
    if [[ "$output" == *"Usage:"* ]]; then
        pass
    else
        fail "Usage not found"
    fi
}

# Run
setup
test_help_shows_usage

# Summary
echo "Passed: $TESTS_PASSED, Failed: $TESTS_FAILED"
[[ $TESTS_FAILED -eq 0 ]] && exit 0 || exit 1
```

### Test Guidelines

- Test function existence, help output, error handling
- Follow existing test patterns
- Add to CI workflow when ready

---

## Code Style

### ZSH Functions

**General:**

- Use `local` for all variables
- Add `help` subcommand to dispatchers
- Error messages to stderr (`>&2`)
- Follow naming: `_dispatcher_action()`

**Dispatcher Pattern:**

```zsh
# Main dispatcher function
mydisp() {
    case "$1" in
        action1) shift; _mydisp_action1 "$@" ;;
        action2) shift; _mydisp_action2 "$@" ;;
        help|--help|-h) _mydisp_help ;;
        *) _mydisp_help ;;
    esac
}

# Action implementation
_mydisp_action1() {
    # Implementation
}

# Help function
_mydisp_help() {
    cat << 'EOF'
mydisp - Description

Usage: mydisp <command> [options]

Commands:
  action1     Do something
  action2     Do something else
  help        Show this help

Examples:
  mydisp action1
  mydisp action2 --flag
EOF
}
```

**Avoid:**

- Global variables (use `local`)
- External dependencies where ZSH builtins work
- `eval` unless absolutely necessary
- Bash-specific syntax (`[[ ]]` is fine, `$'...'` is fine)

---

## Adding a New Dispatcher

1. **Create the file:**

   ```bash
   touch lib/dispatchers/mydisp-dispatcher.zsh
   ```

2. **Implement the pattern:**
   - Main function: `mydisp()`
   - Help function: `_mydisp_help()`
   - Action functions: `_mydisp_action()`

3. **Create tests:**

   ```bash
   touch tests/test-mydisp-dispatcher.zsh
   ```

4. **Add to CI:**
   Edit `.github/workflows/test.yml`

5. **Document:**
   Create `docs/reference/MYDISP-DISPATCHER-REFERENCE.md`

---

## Documentation

### Adding Documentation

1. **Create markdown file in `docs/`**
2. **Add to `mkdocs.yml` navigation**
3. **Test locally:** `mkdocs serve`
4. **Deploy:** `mkdocs gh-deploy --force`

### Documentation Guidelines

**ADHD-Friendly Writing:**

- Use visual hierarchy (headers, bullets, tables)
- Keep sections short (< 200 words)
- Add examples liberally
- Provide quick reference tables

**File Naming:**

- Reference docs: `NAME-REFERENCE.md` (CAPS)
- Tutorials: `01-tutorial-name.md` (numbered)
- Guides: `GUIDE-NAME.md`

---

## Submitting Changes

### Pull Request Process

1. **Ensure tests pass:**

   ```bash
   zsh tests/test-<name>-dispatcher.zsh
   ```

2. **Create PR to `dev` branch:**

   ```bash
   g feature finish
   # or: git push && gh pr create
   ```

3. **Wait for CI checks**

4. **PR description should include:**
   - What changed and why
   - Testing instructions
   - Related issues

### Merge Flow

```
feature/* → dev → main
```

- Feature branches merge to `dev`
- `dev` merges to `main` for releases
- Direct pushes to `main` are blocked

---

## CI/CD Automation

### GitHub Actions Workflows

| Workflow | File | Trigger | Purpose |
|----------|------|---------|---------|
| **CI Tests** | `test.yml` | Push/PR to any branch | Run ZSH plugin tests |
| **Deploy Docs** | `docs.yml` | Push to `main` (docs/**) | Auto-deploy to GitHub Pages |
| **Homebrew Release** | `homebrew-release.yml` | GitHub release published | Update Homebrew formula |
| **Release** | `release.yml` | Push to `main` | Semantic release + install tests |

### What Happens Automatically

**On PR/Push:**
- ZSH plugin tests run (~10-15s)
- Must pass before merge to protected branches

**On Merge to `main`:**
- Documentation auto-deploys to https://data-wise.github.io/flow-cli/
- Only triggers if `docs/**` or `mkdocs.yml` changed
- Install script tests run in Docker (ubuntu, debian, alpine)

**On GitHub Release Published:**
- Homebrew formula auto-updates in `homebrew-tap` repo
- Creates PR to update version and SHA256
- PR is auto-merged (configurable)

### Creating a Release

```bash
# 1. Merge dev to main via PR
gh pr create --base main --head dev --title "Release vX.Y.Z"
gh pr merge <PR_NUMBER> --merge --admin

# 2. Tag the release
git checkout main && git pull
git tag -a vX.Y.Z -m "vX.Y.Z - Description"
git push origin vX.Y.Z

# 3. Create GitHub release (triggers Homebrew update)
gh release create vX.Y.Z --title "vX.Y.Z - Title" --notes "Release notes"
```

### Manual Deployment (if needed)

```bash
# Documentation
mkdocs gh-deploy --force

# Homebrew (via workflow dispatch)
gh workflow run homebrew-release.yml -f version=X.Y.Z
```

### CI Files Location

```
.github/workflows/
├── test.yml              # ZSH plugin tests
├── docs.yml              # MkDocs deployment
├── homebrew-release.yml  # Homebrew formula updates
└── release.yml           # Semantic release + install tests
```

---

## Questions?

- **Testing:** See [TESTING.md](../testing/TESTING.md)
- **Dispatchers:** See [DISPATCHER-REFERENCE.md](../reference/MASTER-DISPATCHER-GUIDE.md)
- **Issues:** https://github.com/Data-Wise/flow-cli/issues

---

**Last Updated:** 2026-01-12
**Version:** v5.4.0
