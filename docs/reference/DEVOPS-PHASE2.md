# DevOps Phase 2: Release & Documentation Automation

**Status:** ✅ Complete (2025-12-23)
**Prerequisites:** Phase 1 (CI/CD foundations)

## Overview

Phase 2 adds automated release management and documentation deployment to streamline the development workflow.

## 1. Semantic Release ✅

**File:** `.releaserc.json`

Automated versioning and changelog generation based on conventional commits.

### Features

- **Automated Versioning**: Determines next version based on commit messages
- **Changelog Generation**: Creates CHANGELOG.md automatically
- **GitHub Releases**: Creates GitHub releases with release notes
- **npm Publishing**: Publishes to npm registry (if configured)
- **Git Tagging**: Automatically tags releases

### Conventional Commit Types

| Type               | Release | Description                            |
| ------------------ | ------- | -------------------------------------- |
| `feat:`            | Minor   | New feature                            |
| `fix:`             | Patch   | Bug fix                                |
| `perf:`            | Patch   | Performance improvement                |
| `docs:`            | Patch   | Documentation only (with README scope) |
| `refactor:`        | Patch   | Code refactoring                       |
| `style:`           | Patch   | Code style changes                     |
| `chore(deps):`     | Patch   | Dependency updates                     |
| `BREAKING CHANGE:` | Major   | Breaking API changes                   |

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Examples

```bash
# Minor release (new feature)
git commit -m "feat(cli): add project picker command"

# Patch release (bug fix)
git commit -m "fix(status): resolve timing calculation error"

# Major release (breaking change)
git commit -m "feat(api)!: redesign status API

BREAKING CHANGE: StatusController.getStatus() now returns Promise"

# No release (chore)
git commit -m "chore: update README formatting"
```

### Release Workflow

**Trigger:** Push to `main` branch

**Process:**

1. Analyze commits since last release
2. Determine version bump (major/minor/patch)
3. Generate changelog
4. Update package.json version
5. Create git tag
6. Create GitHub release
7. Publish to npm (if configured)
8. Commit changelog and version updates with `[skip ci]`

### GitHub Actions Workflow

**File:** `.github/workflows/release.yml`

Runs automatically on push to `main`:

- Installs dependencies
- Runs test suite
- Executes semantic-release

### Configuration

```json
{
  "branches": ["main"],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/changelog",
    "@semantic-release/npm",
    "@semantic-release/github",
    "@semantic-release/git"
  ]
}
```

## 2. Documentation Deployment ✅

**File:** `.github/workflows/docs.yml`

Automated deployment of MkDocs documentation to GitHub Pages.

### Features

- **Auto-deploy on main**: Deploys when docs/ or mkdocs.yml changes
- **Manual trigger**: Can be triggered via workflow_dispatch
- **Fast deployment**: Uses mkdocs gh-deploy
- **Clean builds**: Forces clean rebuild on each deploy

### Trigger Paths

```yaml
paths:
  - 'docs/**'
  - 'mkdocs.yml'
  - '.github/workflows/docs.yml'
```

### Deployment Process

1. Checkout repository with full history
2. Setup Python 3.x
3. Install MkDocs and plugins:
   - mkdocs
   - mkdocs-material (theme)
   - mkdocs-mermaid2-plugin (diagrams)
4. Build and deploy to gh-pages branch
5. GitHub Pages serves from gh-pages branch

### Manual Deployment

```bash
# From local machine
mkdocs gh-deploy

# From GitHub UI
Actions → Deploy Documentation → Run workflow
```

### Documentation URL

https://data-wise.github.io/flow-cli/

## 3. E2E Tests ✅

**File:** `tests/e2e/cli.test.js`

End-to-end tests for CLI commands using the actual binary.

### Test Coverage

**Categories:**

1. Help and Version (5 tests)
2. Error Handling (2 tests)
3. Status Command (3 tests)
4. CLI Performance (2 tests)
5. Exit Codes (2 tests)

**Total:** 14 E2E tests

### Test Examples

```javascript
// Help command
test('shows help with --help', () => {
  const { stdout, exitCode } = runCLI('--help')
  expect(exitCode).toBe(0)
  expect(stdout).toContain('Usage: flow <command>')
})

// Error handling
test('shows error for unknown command', () => {
  const { stderr, exitCode } = runCLI('nonexistent')
  expect(exitCode).toBe(1)
  expect(stderr).toContain("unknown command 'nonexistent'")
})

// Performance
test('help command executes quickly', () => {
  const start = Date.now()
  runCLI('--help')
  const duration = Date.now() - start
  expect(duration).toBeLessThan(2000)
})
```

### Running E2E Tests

```bash
# Run all E2E tests
npm test -- tests/e2e/

# Run specific E2E test file
npm test -- tests/e2e/cli.test.js

# Run all tests (unit + integration + E2E)
npm test
```

## Test Statistics

**Before Phase 2:** 504 tests
**After Phase 2:** 518 tests (+14 E2E tests)

All tests passing ✅

## Files Added

```
.releaserc.json                      # Semantic Release config
.github/workflows/release.yml        # Release automation
.github/workflows/docs.yml           # Docs deployment
tests/e2e/cli.test.js               # E2E tests
docs/reference/DEVOPS-PHASE2.md      # This file
```

## Dependencies Added

```json
{
  "devDependencies": {
    "semantic-release": "^25.0.2",
    "@semantic-release/changelog": "^6.0.3",
    "@semantic-release/git": "^10.0.1",
    "@semantic-release/github": "^12.0.2"
  }
}
```

## Usage Examples

### Releasing a New Version

1. Develop on `dev` branch
2. Create PR to `main` with conventional commits
3. Merge PR to `main`
4. GitHub Actions automatically:
   - Runs tests
   - Determines version
   - Generates changelog
   - Creates release
   - Publishes to npm (if configured)

### Updating Documentation

1. Edit files in `docs/` directory
2. Test locally: `mkdocs serve`
3. Commit and push to `main`
4. GitHub Actions automatically deploys to GitHub Pages

### Adding E2E Tests

```javascript
describe('New Feature E2E', () => {
  test('feature works end-to-end', () => {
    const { stdout, exitCode } = runCLI('new-command --option')
    expect(exitCode).toBe(0)
    expect(stdout).toContain('expected output')
  })
})
```

## Troubleshooting

### Semantic Release Not Creating Release

**Check:**

1. Commits follow conventional commit format
2. Commits are on `main` branch
3. GITHUB_TOKEN has write permissions
4. At least one commit since last release triggers a version bump

**Debug:**

```bash
# Run locally with debug
npx semantic-release --dry-run --debug
```

### Docs Not Deploying

**Check:**

1. Changes are in `docs/` or `mkdocs.yml`
2. Pushed to `main` branch
3. GitHub Pages is enabled in repository settings
4. gh-pages branch exists

**Manual Deploy:**

```bash
mkdocs gh-deploy --force
```

### E2E Tests Failing

**Check:**

1. CLI binary is executable: `chmod +x cli/bin/flow.js`
2. Node version is compatible (18.x+)
3. Dependencies are installed: `npm install`

**Debug:**

```bash
# Run E2E tests with verbose output
npm test -- tests/e2e/cli.test.js --verbose
```

## Best Practices

### Commit Messages

✅ **Good:**

```
feat(status): add sparkline visualization for session trends

Added ASCII sparkline chart to show visual trend of recent sessions.
Improves at-a-glance understanding of productivity patterns.
```

❌ **Bad:**

```
updated files
```

### Documentation

- Update docs/ when adding features
- Test locally with `mkdocs serve` before pushing
- Use Mermaid diagrams for complex flows
- Keep navigation structure flat (max 2 levels)

### E2E Testing

- Test critical user flows
- Verify exit codes
- Check both stdout and stderr
- Test error handling
- Add performance tests for slow commands

## Next Steps: Phase 3

Phase 3 will add observability and advanced security:

1. **Structured Logging** - JSON logs for monitoring
2. **CodeQL Security Scanning** - Advanced vulnerability detection
3. **Test Environment Isolation** - Improved reliability

**Estimated Effort:** 2 hours

## Resources

- [Semantic Release Docs](https://semantic-release.gitbook.io/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [MkDocs Documentation](https://www.mkdocs.org/)
- [GitHub Pages](https://docs.github.com/en/pages)
