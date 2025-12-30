# Pull Request Workflow Guide

**Complete guide to contributing code to flow-cli**

**Last Updated:** 2025-12-30
**Target Audience:** Contributors and maintainers
**Architecture:** Pure ZSH plugin (v4.4.x)

---

## Table of Contents

- [Quick Start](#quick-start)
- [Before You Start](#before-you-start)
- [Creating a Pull Request](#creating-a-pull-request)
- [PR Review Process](#pr-review-process)
- [After Merge](#after-merge)
- [Common Scenarios](#common-scenarios)
- [Troubleshooting](#troubleshooting)

---

## Quick Start

```bash
# 1. Fork and clone
git clone https://github.com/YOUR-USERNAME/flow-cli.git
cd flow-cli

# 2. Create feature branch
git checkout -b feature/your-feature-name

# 3. Load plugin and test
source flow.plugin.zsh
zsh tests/run-tests.zsh

# 4. Commit with conventional commits
git commit -m "feat: add new feature"

# 5. Push and create PR
git push origin feature/your-feature-name
# Then create PR on GitHub
```

---

## Before You Start

### 1. Check Existing Work

**Avoid duplicate effort:**

```bash
# Search for existing issues
# Visit: https://github.com/Data-Wise/flow-cli/issues

# Search for existing PRs
# Visit: https://github.com/Data-Wise/flow-cli/pulls
```

### 2. Read Project Documentation

**Essential reading:**

- [CLAUDE.md](https://github.com/Data-Wise/flow-cli/blob/main/CLAUDE.md) - Architecture overview
- [CONTRIBUTING.md](../contributing/CONTRIBUTING.md) - Contribution guidelines
- [Testing Guide](../testing/TESTING.md) - Test requirements

### 3. Understand the Architecture

**flow-cli is a pure ZSH plugin with this structure:**

```
flow-cli/
├── flow.plugin.zsh       # Plugin entry point
├── lib/
│   ├── core.zsh          # Core utilities
│   ├── atlas-bridge.zsh  # Atlas integration
│   ├── project-detector.zsh
│   ├── tui.zsh           # Terminal UI
│   └── dispatchers/      # Smart dispatchers
├── commands/             # Command implementations
├── completions/          # ZSH completions
├── hooks/                # ZSH hooks
└── tests/                # Test suite
```

**Key principles:**

- Pure ZSH (no external runtime)
- Sub-10ms response time
- ADHD-friendly design

### 4. Set Up Development Environment

```bash
# Load the plugin in your current shell
source flow.plugin.zsh

# Run tests to verify setup
zsh tests/run-tests.zsh

# Verify commands work
work --help
dash --help
r help
```

---

## Creating a Pull Request

### Step 1: Create Feature Branch

**Branch naming convention:**

```bash
# Features
git checkout -b feature/add-dashboard-widget

# Bug fixes
git checkout -b fix/session-timeout-bug

# Documentation
git checkout -b docs/update-dispatcher-reference

# Refactoring
git checkout -b refactor/simplify-cache-logic
```

**Pattern:** `type/short-description-kebab-case`

### Step 2: Make Changes

**Follow coding standards:**

1. **ZSH plugin patterns**
   - Commands in `commands/`
   - Dispatchers in `lib/dispatchers/`
   - Utilities in `lib/core.zsh`

2. **Code style**
   - Use `_flow_` prefix for internal functions
   - Use `_<dispatcher>_` prefix for dispatcher internals
   - Add inline comments for complex logic

3. **Testing required**
   - Add tests to `tests/`
   - Use the existing test framework
   - Aim for 100% pass rate

### Step 3: Write Tests

**Test-Driven Development (TDD) encouraged:**

```bash
# 1. Write failing test
# 2. Implement feature
# 3. Test passes
# 4. Refactor if needed

# Run tests
zsh tests/run-tests.zsh
```

**Test requirements:**

- [ ] Unit tests for new functions
- [ ] Integration tests for commands
- [ ] All tests pass

**See:** [Testing Guide](../testing/TESTING.md)

### Step 4: Commit Your Changes

**Use Conventional Commits:**

```bash
# Feature
git commit -m "feat: add dashboard auto-refresh"

# Bug fix
git commit -m "fix: resolve session timeout race condition"

# Documentation
git commit -m "docs: update dispatcher reference for new commands"

# Tests
git commit -m "test: add integration tests for project scanning"

# Refactor
git commit -m "refactor: simplify cache invalidation logic"

# Performance
git commit -m "perf: optimize project scanning with caching"

# Breaking change
git commit -m "feat!: change session API signature

BREAKING CHANGE: work command now requires project name"
```

**Commit message format:**

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Types:**

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation only
- `test:` - Adding tests
- `refactor:` - Code change that neither fixes bug nor adds feature
- `perf:` - Performance improvement
- `chore:` - Maintenance (dependencies, build, etc.)

### Step 5: Push and Create PR

```bash
# Push your branch
git push origin feature/your-feature-name

# GitHub CLI (optional)
gh pr create --title "Add dashboard auto-refresh" --body "Closes #123"

# Or create PR via GitHub web interface
```

**PR template will guide you through:**

1. Description of changes
2. Type of change (feature, fix, docs, etc.)
3. Testing checklist
4. Breaking changes (if any)

---

## PR Review Process

### What Reviewers Look For

**1. Code Quality**

- [ ] Follows ZSH plugin patterns
- [ ] Clear, readable code with good naming
- [ ] Appropriate comments for complex logic
- [ ] No unnecessary complexity

**2. Testing**

- [ ] All tests pass
- [ ] New tests added for new functionality
- [ ] Tests are clear and maintainable
- [ ] Edge cases covered

**3. Documentation**

- [ ] CLAUDE.md updated if architecture changed
- [ ] User-facing docs updated if needed
- [ ] Help functions updated (`_<cmd>_help`)
- [ ] Completions updated if commands changed

**4. Breaking Changes**

- [ ] Clearly documented in commit message
- [ ] Migration guide provided if needed
- [ ] Deprecation warnings added for gradual migration

**5. Performance**

- [ ] No performance regressions
- [ ] Maintains sub-10ms response time for core commands
- [ ] Efficient ZSH patterns

### Responding to Review Comments

**Be professional and collaborative:**

```markdown
# Good response

Thanks for catching that! I've updated the implementation to use
the dispatcher pattern as you suggested. See commit abc123.

# Address each comment

- Fixed variable naming in work.zsh
- Added edge case test for empty project list
- Still working on the performance optimization - will update soon
```

**Iterate quickly:**

```bash
# Make requested changes
git add .
git commit -m "refactor: address review comments"
git push origin feature/your-feature-name

# PR automatically updates
```

### Approval and Merge

**Merge criteria:**

1. All tests passing
2. At least one approval from maintainer
3. All review comments addressed
4. No merge conflicts
5. CI/CD checks passing

**Merge strategies:**

- **Squash and merge** (default) - All commits squashed into one
- **Rebase and merge** - Linear history, individual commits preserved
- **Merge commit** - Preserves full history

**Most PRs use squash and merge** for clean history.

---

## After Merge

### 1. Delete Your Branch

```bash
# Delete local branch
git checkout main
git branch -d feature/your-feature-name

# Delete remote branch (usually done automatically by GitHub)
git push origin --delete feature/your-feature-name
```

### 2. Update Your Fork

```bash
# Add upstream remote (one-time setup)
git remote add upstream https://github.com/Data-Wise/flow-cli.git

# Fetch and merge
git fetch upstream
git merge upstream/main
git push origin main
```

### 3. Celebrate!

Your contribution is now part of flow-cli! Thank you for contributing.

---

## Common Scenarios

### Scenario 1: Adding a New Command

```bash
# 1. Create issue first (discuss approach)
# 2. Get approval/feedback
# 3. Create branch
git checkout -b feature/new-command

# 4. Implement
# - Add command to commands/yourcommand.zsh
# - Add help function _yourcommand_help()
# - Add completion to completions/_yourcommand
# - Write tests

# 5. Update documentation
# - Add to COMMAND-QUICK-REFERENCE.md
# - Update CLAUDE.md if significant

# 6. Create PR with clear description
```

### Scenario 2: Adding a Dispatcher Subcommand

```bash
# 1. Edit lib/dispatchers/<name>-dispatcher.zsh
# 2. Add case in main function
# 3. Add implementation function _<name>_<action>()
# 4. Update _<name>_help() function
# 5. Add tests
# 6. Update DISPATCHER-REFERENCE.md
```

### Scenario 3: Fixing a Bug

```bash
# 1. Reproduce the bug
# 2. Write failing test that demonstrates bug

# 3. Create fix branch
git checkout -b fix/session-timeout-issue

# 4. Fix the bug
# 5. Verify test now passes
zsh tests/run-tests.zsh

# 6. Create PR
# - Reference issue number: "Fixes #123"
# - Explain root cause and solution
```

### Scenario 4: Updating Documentation

```bash
# 1. Create docs branch
git checkout -b docs/improve-dispatcher-reference

# 2. Make documentation changes
# - Update markdown files
# - Fix typos, improve clarity
# - Add examples

# 3. Test documentation build
mkdocs build --strict

# 4. Create PR
# - Explain what was unclear before
# - Show improvement
```

---

## Troubleshooting

### Tests Failing Locally

```bash
# Run tests to see failures
zsh tests/run-tests.zsh

# Run specific test file
zsh tests/unit/test-core.zsh

# Check for syntax errors
zsh -n lib/core.zsh
```

**Common causes:**

- Forgot to update tests after code change
- Missing source statement in flow.plugin.zsh
- ZSH syntax error (different from bash)

### Merge Conflicts

```bash
# Update your branch with latest main
git fetch origin
git merge origin/main

# Resolve conflicts manually
# Edit conflicted files
# Remove conflict markers (<<<<, ====, >>>>)

# Mark as resolved
git add .
git commit -m "resolve merge conflicts"
git push origin feature/your-feature-name
```

### CI/CD Checks Failing

**GitHub Actions runs tests on every PR:**

1. Check Actions tab for detailed logs
2. Common issues:
   - Tests pass locally but fail in CI (environment differences)
   - Missing files (ensure all changes committed)
   - ZSH version differences

3. Fix and push:
   ```bash
   git add .
   git commit -m "fix: resolve CI test failures"
   git push origin feature/your-feature-name
   ```

### Need Help?

**Ask for help early:**

- Comment on your PR: "I'm stuck on X, any suggestions?"
- Tag a maintainer: `@Data-Wise could you review this approach?`
- Open a discussion: GitHub Discussions tab

---

## Best Practices

### DO

1. **Keep PRs focused**
   - One feature/fix per PR
   - Easier to review and merge
   - Reduces merge conflicts

2. **Write clear descriptions**
   - Explain what and why
   - Link to relevant issues
   - Add examples for new commands

3. **Test thoroughly**
   - Write tests for new code
   - Run full test suite
   - Test edge cases

4. **Update documentation**
   - Keep docs in sync with code
   - Add examples for new features
   - Update help functions

5. **Respond to reviews promptly**
   - Address comments quickly
   - Ask questions if unclear
   - Be open to feedback

### DON'T

1. **Large PRs**
   - Hard to review
   - More likely to have bugs
   - Delays merge

2. **Mixed changes**
   - Refactor + feature in same PR
   - Multiple unrelated fixes
   - Code + unrelated docs

3. **Ignoring tests**
   - Skipping test coverage
   - Leaving tests broken
   - Not testing edge cases

4. **Breaking changes without notice**
   - No migration guide
   - No deprecation warnings
   - Surprise API changes

5. **Force pushing after review**
   - Loses review comments
   - Confuses reviewers
   - Use regular push instead

---

## Quick Reference

### Essential Commands

```bash
# Setup
git clone <fork-url>
source flow.plugin.zsh
zsh tests/run-tests.zsh

# Development
git checkout -b feature/name
# edit files
zsh tests/run-tests.zsh
git commit -m "type: message"
git push origin feature/name

# Keep updated
git fetch upstream
git merge upstream/main

# Cleanup
git branch -d feature/name
git push origin --delete feature/name
```

### Links

- **Issues:** https://github.com/Data-Wise/flow-cli/issues
- **PRs:** https://github.com/Data-Wise/flow-cli/pulls
- **Actions:** https://github.com/Data-Wise/flow-cli/actions
- **Documentation:** https://data-wise.github.io/flow-cli/

---

## Related Documentation

- [Contributing Guide](../contributing/CONTRIBUTING.md) - High-level contribution guidelines
- [Testing Guide](../testing/TESTING.md) - How to write and run tests
- [CLAUDE.md](https://github.com/Data-Wise/flow-cli/blob/main/CLAUDE.md) - Architecture overview

---

**Last Updated:** 2025-12-30
**Version:** v4.4.x
**Questions?** Open an issue or discussion on GitHub
