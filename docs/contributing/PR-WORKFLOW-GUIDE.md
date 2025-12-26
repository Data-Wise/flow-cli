# Pull Request Workflow Guide

**Complete guide to contributing code to flow-cli**

**Last Updated:** 2025-12-24
**Target Audience:** Contributors and maintainers

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

# 3. Make changes and test
npm install
npm test

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

- [Documentation Home](../index.md) - Project overview
- [CONTRIBUTING.md](../contributing/CONTRIBUTING.md) - Contribution guidelines
- [Architecture Overview](../architecture/README.md) - System design
- [Testing Guide](../testing/TESTING.md) - Test requirements

### 3. Understand the Architecture

**flow-cli uses Clean Architecture (3 layers):**

```
Domain Layer (Entities)
   ↓
Use Cases Layer (Business Logic)
   ↓
Adapters Layer (Controllers, Repositories, UI)
```

**Read:** [Architecture Diagrams](../architecture/ARCHITECTURE-DIAGRAM.md)

### 4. Set Up Development Environment

```bash
# Install dependencies
npm install

# Run tests to verify setup
npm test

# Install pre-commit hooks
# (Husky is installed automatically via npm install)

# Verify CLI works
npm run build
./cli/bin/flow.js --help
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
git checkout -b docs/update-api-reference

# Refactoring
git checkout -b refactor/simplify-cache-logic
```

**Pattern:** `type/short-description-kebab-case`

### Step 2: Make Changes

**Follow coding standards:**

1. **Clean Architecture principles**
   - Domain logic in `cli/domain/`
   - Use cases in `cli/use-cases/`
   - Adapters in `cli/adapters/`

2. **Code style**
   - ESLint will check on commit
   - Prettier formatting is automatic
   - Use JSDoc comments for public APIs

3. **Testing required**
   - Unit tests for domain logic
   - Integration tests for file I/O
   - E2E tests for CLI commands
   - Aim for 100% pass rate

### Step 3: Write Tests

**Test-Driven Development (TDD) encouraged:**

```bash
# 1. Write failing test
npm test -- --watch

# 2. Implement feature
# 3. Test passes
# 4. Refactor if needed
```

**Test requirements:**

- [ ] Unit tests for new domain entities
- [ ] Integration tests for repositories
- [ ] E2E tests for new CLI commands
- [ ] All tests pass: `npm test`

**See:** [Testing Guide](../testing/TESTING.md)

### Step 4: Commit Your Changes

**Use Conventional Commits:**

```bash
# Feature
git commit -m "feat: add dashboard auto-refresh"

# Bug fix
git commit -m "fix: resolve session timeout race condition"

# Documentation
git commit -m "docs: update API reference for new methods"

# Tests
git commit -m "test: add integration tests for project scanning"

# Refactor
git commit -m "refactor: simplify cache invalidation logic"

# Performance
git commit -m "perf: optimize project scanning with parallelization"

# Breaking change
git commit -m "feat!: change session API to async

BREAKING CHANGE: Session.create() now returns Promise"
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

- [ ] Follows Clean Architecture principles
- [ ] Clear, readable code with good naming
- [ ] Appropriate comments for complex logic
- [ ] No unnecessary complexity

**2. Testing**

- [ ] All tests pass (`npm test`)
- [ ] New tests added for new functionality
- [ ] Tests are clear and maintainable
- [ ] Edge cases covered

**3. Documentation**

- [ ] API documentation updated (JSDoc)
- [ ] User-facing docs updated if needed
- [ ] Architecture diagrams updated if structure changed
- [ ] CHANGELOG.md updated (for releases)

**4. Breaking Changes**

- [ ] Clearly documented in commit message
- [ ] Migration guide provided if needed
- [ ] Deprecation warnings added for gradual migration

**5. Performance**

- [ ] No performance regressions
- [ ] Benchmark tests if claiming performance improvement
- [ ] Efficient algorithms and data structures

### Responding to Review Comments

**Be professional and collaborative:**

```markdown
# Good response

Thanks for catching that! I've updated the implementation to use
the repository pattern as you suggested. See commit abc123.

# Address each comment

- ✅ Fixed variable naming in Session.js
- ✅ Added edge case test for empty project list
- ⏳ Still working on the performance optimization - will update soon
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

1. ✅ All tests passing
2. ✅ At least one approval from maintainer
3. ✅ All review comments addressed
4. ✅ No merge conflicts
5. ✅ CI/CD checks passing

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

### 3. Celebrate! 🎉

Your contribution is now part of flow-cli! Thank you for contributing.

---

## Common Scenarios

### Scenario 1: Adding a New Feature

```bash
# 1. Create issue first (discuss approach)
# 2. Get approval/feedback
# 3. Create branch
git checkout -b feature/new-visualization

# 4. Implement with tests
# - Add domain entity if needed
# - Create use case
# - Add adapter/controller
# - Write comprehensive tests

# 5. Update documentation
# - API docs (JSDoc)
# - User guides
# - Architecture diagrams

# 6. Create PR with clear description
```

### Scenario 2: Fixing a Bug

```bash
# 1. Reproduce the bug
# 2. Write failing test that demonstrates bug

# 3. Create fix branch
git checkout -b fix/session-timeout-issue

# 4. Fix the bug
# 5. Verify test now passes
npm test

# 6. Create PR
# - Reference issue number: "Fixes #123"
# - Explain root cause and solution
```

### Scenario 3: Updating Documentation

```bash
# 1. Create docs branch
git checkout -b docs/improve-api-reference

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

### Scenario 4: Refactoring

```bash
# 1. Ensure tests exist for code being refactored
npm test -- --coverage

# 2. Create refactor branch
git checkout -b refactor/simplify-cache-layer

# 3. Refactor incrementally
# - Make small changes
# - Run tests after each change
# - Commit often

# 4. Create PR
# - Explain why refactoring improves codebase
# - Show before/after comparisons
# - Emphasize no behavior changes
```

---

## Troubleshooting

### Tests Failing Locally

```bash
# Run tests to see failures
npm test

# Run specific test file
npm test -- tests/unit/domain/entities/Session.test.js

# Run in watch mode
npm test -- --watch

# Check for open handles (resource leaks)
npm test -- --detectOpenHandles
```

**Common causes:**

- Forgot to update tests after code change
- Missing dependencies: `npm install`
- Race conditions (use isolated temp directories)

### Pre-commit Hook Failing

```bash
# Pre-commit runs tests automatically
# Fix failing tests before committing

# Bypass hook (use sparingly)
git commit --no-verify -m "message"
```

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
   - Node version mismatch (CI uses Node 20)
   - Missing files (ensure all changes committed)

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
- Check Discord/Slack (if project has one)

---

## Best Practices

### DO ✅

1. **Keep PRs focused**
   - One feature/fix per PR
   - Easier to review and merge
   - Reduces merge conflicts

2. **Write clear descriptions**
   - Explain what and why
   - Link to relevant issues
   - Add screenshots for UI changes

3. **Test thoroughly**
   - Write tests for new code
   - Run full test suite
   - Test edge cases

4. **Update documentation**
   - Keep docs in sync with code
   - Add examples for new features
   - Update architecture diagrams

5. **Respond to reviews promptly**
   - Address comments quickly
   - Ask questions if unclear
   - Be open to feedback

### DON'T ❌

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
npm install
npm test

# Development
git checkout -b feature/name
npm test -- --watch
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
- [Architecture Overview](../architecture/README.md) - System design principles
- [ADR Process Guide](ADR-PROCESS-GUIDE.md) - Writing architecture decisions

---

**Last Updated:** 2025-12-24
**Version:** v2.0.0-beta.1
**Questions?** Open an issue or discussion on GitHub
