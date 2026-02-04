# Commit Message Standards

> **TL;DR:** Use conventional commits. Type + scope + imperative summary.

## Format

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

## Types

| Type | When to Use | Example |
|------|-------------|---------|
| `feat` | New feature | `feat(api): add bootstrap CI endpoint` |
| `fix` | Bug fix | `fix(calc): correct variance formula` |
| `docs` | Documentation only | `docs(readme): add installation guide` |
| `style` | Formatting, no code change | `style(r): apply styler formatting` |
| `refactor` | Code change, no new feature/fix | `refactor(utils): simplify helper functions` |
| `test` | Adding/fixing tests | `test(bootstrap): add edge case tests` |
| `chore` | Build, tooling, deps | `chore(deps): update testthat to 3.0` |
| `perf` | Performance improvement | `perf(sim): vectorize loop operations` |

## Scope (Optional)

Use the affected area:

| Project Type | Common Scopes |
|--------------|---------------|
| R Package | `R`, `tests`, `vignettes`, `docs`, function name |
| Research | `manuscript`, `analysis`, `sim`, `data` |
| Teaching | `lectures`, `hw`, `exams`, `syllabus` |
| ZSH | `functions`, `aliases`, `config`, `tests` |

## Subject Rules

1. **Imperative mood** — "add feature" not "added feature"
2. **No period** at the end
3. **Max 50 characters** (72 absolute max)
4. **Lowercase** first letter

```bash
# GOOD
feat(mediation): add sensitivity analysis function
fix(bootstrap): handle zero variance edge case
docs: update installation instructions

# BAD
feat(mediation): Added sensitivity analysis function.   # Past tense, period
FIX: Bootstrap zero variance                           # Caps, unclear
updated docs                                           # Past tense, no type
```

## Body (When Needed)

- Wrap at 72 characters
- Explain **why**, not what (code shows what)
- Reference issues: `Fixes #123`, `Closes #456`

```
fix(bootstrap): handle zero variance edge case

The bootstrap CI calculation failed when sample variance was exactly
zero (constant values). Now returns NA with a warning instead of
crashing.

Fixes #42
```

## Breaking Changes

Use `!` after type or `BREAKING CHANGE:` in footer:

```
feat(api)!: change return type to list

BREAKING CHANGE: indirect_effect() now returns a list with
$estimate and $ci instead of a numeric vector.
```

---

## Quick Reference

```bash
# Feature
git commit -m "feat(scope): add new capability"

# Bug fix
git commit -m "fix(scope): resolve specific issue"

# Docs
git commit -m "docs: update readme"

# Tests
git commit -m "test(scope): add tests for feature"

# Refactor
git commit -m "refactor(scope): improve code structure"

# Chore
git commit -m "chore(deps): update dependencies"
```

## R Package Examples

```bash
# New exported function
feat(R): add calculate_nde function

# Internal helper
feat(utils): add bootstrap helper function

# Bug fix
fix(mediate): correct coefficient extraction for glm

# Documentation
docs(vignettes): add sensitivity analysis tutorial

# Tests
test(nde): add tests for binary mediator

# CRAN submission prep
chore: prepare for CRAN submission
```

## Research Project Examples

```bash
# Manuscript
docs(manuscript): draft methods section
docs(manuscript): revise based on R1 feedback

# Analysis
feat(analysis): implement simulation study
fix(analysis): correct standard error calculation

# Data
chore(data): add cleaned dataset
```

---

## Automation

### Git Hooks (Optional)

Add to `.git/hooks/commit-msg`:

```bash
#!/bin/bash
# Validate conventional commit format
if ! grep -qE "^(feat|fix|docs|style|refactor|test|chore|perf)(\(.+\))?!?: .{1,50}" "$1"; then
    echo "Invalid commit message format."
    echo "Use: type(scope): subject"
    exit 1
fi
```

### Aliases

```bash
# Add to your shell config
alias gcf='git commit -m "feat: '
alias gcx='git commit -m "fix: '
alias gcd='git commit -m "docs: '
alias gct='git commit -m "test: '
alias gcr='git commit -m "refactor: '
alias gcc='git commit -m "chore: '
```

## Tools

- **commitlint** — Lint commit messages
- **conventional-changelog** — Generate changelogs from commits
- **semantic-release** — Automated versioning from commits

## Resources

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Angular Commit Guidelines](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#commit)
