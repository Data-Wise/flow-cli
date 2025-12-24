# DevOps Infrastructure Setup

**Status:** ✅ Phase 1 Complete (2025-12-23)
**Next:** Phase 2 (Release & Documentation Automation)

## Overview

This document describes the DevOps infrastructure implemented for the flow-cli project. The setup follows a phased approach to ensure quality, security, and maintainability.

## Phase 1: Critical DevOps Foundations ✅

Phase 1 establishes the core CI/CD infrastructure and development workflow automation.

### 1. GitHub Actions CI ✅

**File:** `.github/workflows/test.yml`

**Features:**
- Multi-version Node.js testing (18.x, 20.x, 22.x)
- Automated test execution on push and PR
- Test coverage generation (Node 20.x)
- Codecov integration for coverage reporting
- Separate lint job for code quality

**Triggers:**
- Push to `main` or `dev` branches
- Pull requests to `main` or `dev` branches

**Jobs:**
1. **test** - Runs tests on all Node versions
2. **lint** - Runs ESLint and Prettier checks

### 2. Dependabot ✅

**File:** `.github/dependabot.yml`

**Features:**
- Weekly npm dependency updates (Mondays, 9:00 AM)
- Weekly GitHub Actions updates
- Automatic PR creation with conventional commit messages
- PR limits: 5 for npm, 3 for GitHub Actions
- Auto-labeling: `dependencies`, `automated`, `ci`

**Update Schedule:**
```yaml
npm: Weekly (Monday 9:00 AM)
github-actions: Weekly (Monday 9:00 AM)
```

### 3. Pre-commit Hooks (Husky) ✅

**File:** `.husky/pre-commit`

**Features:**
- Runs full test suite before commits
- Executes lint-staged for changed files
- Prevents commits with failing tests

**Lint-staged Configuration:**
```json
{
  "*.js": [
    "npm run lint --if-present",
    "npm run format --if-present",
    "npm test -- --findRelatedTests --bail"
  ],
  "*.{json,md,yml,yaml}": [
    "npm run format --if-present"
  ]
}
```

### 4. ESLint ✅

**File:** `eslint.config.js`

**Features:**
- ES2025 syntax support (including import assertions with `with`)
- Jest plugin for test files
- Prettier integration (no conflicts)
- Comprehensive ignore patterns

**Configuration Highlights:**
- **Error Rules:** `prefer-const`, `no-var` (must fix)
- **Warning Rules:** `no-unused-vars`, `no-undef`, `no-empty` (should fix)
- **Ignored:** Legacy CommonJS files, generated files, archives

**Scripts:**
```bash
npm run lint          # Check code quality
npm run lint:fix      # Auto-fix issues
```

**Current Status:**
- ✅ 0 errors
- ⚠️ 49 warnings (non-blocking)

### 5. Prettier ✅

**File:** `.prettierrc`

**Configuration:**
```json
{
  "semi": false,
  "singleQuote": true,
  "trailingComma": "none",
  "printWidth": 100,
  "tabWidth": 2,
  "arrowParens": "avoid",
  "endOfLine": "lf"
}
```

**Scripts:**
```bash
npm run format         # Format all files
npm run format:check   # Check formatting
```

### 6. Security Audit ✅

**Status:** ✅ 0 vulnerabilities in both workspaces

```bash
npm audit             # Root workspace
cd cli && npm audit   # CLI workspace
```

## File Structure

```
flow-cli/
├── .github/
│   ├── workflows/
│   │   └── test.yml              # CI pipeline
│   └── dependabot.yml            # Dependency updates
├── .husky/
│   └── pre-commit                # Pre-commit hook
├── eslint.config.js              # ESLint configuration
├── .prettierrc                   # Prettier configuration
├── .prettierignore               # Prettier ignore patterns
└── docs/reference/
    └── DEVOPS-SETUP.md           # This file
```

## Scripts Reference

| Command | Purpose |
|---------|---------|
| `npm test` | Run all tests |
| `npm run lint` | Run ESLint |
| `npm run lint:fix` | Auto-fix ESLint issues |
| `npm run format` | Format code with Prettier |
| `npm run format:check` | Check formatting |
| `npm audit` | Security audit |

## CI/CD Workflow

### On Every Push/PR:
1. GitHub Actions triggers
2. Runs tests on Node 18.x, 20.x, 22.x
3. Generates coverage report (Node 20.x)
4. Uploads coverage to Codecov
5. Runs ESLint checks
6. Runs Prettier checks
7. Reports status to PR

### On Every Commit:
1. Husky pre-commit hook triggers
2. Runs full test suite
3. Runs lint-staged on changed files
4. Blocks commit if tests fail

### Weekly:
1. Dependabot checks for updates
2. Creates PRs for npm dependencies
3. Creates PRs for GitHub Actions updates

## Next Steps: Phase 2

Phase 2 will add release and documentation automation:

1. **Semantic Release** - Automated versioning and changelog
2. **Docs Deployment** - Auto-deploy MkDocs to GitHub Pages
3. **E2E Tests** - Basic end-to-end testing

**Estimated Effort:** 2 hours

## Phase 3 (Future)

1. **Structured Logging** - JSON logs for monitoring
2. **CodeQL Security Scanning** - Advanced security analysis
3. **Test Environment Isolation** - Improved test reliability

**Estimated Effort:** 2 hours

## Maintenance

### Update Dependencies:
```bash
# Review and merge Dependabot PRs weekly
# Or manually update:
npm update
cd cli && npm update
```

### Fix Linting Warnings:
```bash
npm run lint:fix
# Review and commit changes
```

### Monitor CI:
- Check GitHub Actions status: https://github.com/Data-Wise/flow-cli/actions
- Review Codecov reports (once token configured)

## Troubleshooting

### Pre-commit Hook Fails:
```bash
# Run tests manually:
npm test

# Fix linting issues:
npm run lint:fix

# If needed, bypass hook (not recommended):
git commit --no-verify
```

### ESLint Errors:
```bash
# Check specific file:
npx eslint <file>

# Auto-fix if possible:
npm run lint:fix
```

### Husky Not Working:
```bash
# Reinstall hooks:
npx husky install
```

## Contributors

When contributing:
1. Pre-commit hooks will run automatically
2. Ensure `npm test` passes
3. Fix linting warnings when possible
4. CI must pass before merging

## Resources

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Dependabot Docs](https://docs.github.com/en/code-security/dependabot)
- [Husky Docs](https://typicode.github.io/husky/)
- [ESLint Docs](https://eslint.org/docs/latest/)
- [Prettier Docs](https://prettier.io/docs/en/)
