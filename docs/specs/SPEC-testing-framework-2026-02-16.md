# SPEC: Comprehensive Testing Framework for Zsh/Bash Projects

**Date:** 2026-02-16
**Status:** Draft
**Branch:** feature/testing-overhaul
**Scope:** flow-cli (primary), extensible to all dev-tools projects

## Context & Scope

Complete testing strategy for shell-based projects (zsh/bash) with three layers:

1. **Unit tests** - Individual function validation
2. **End-to-end (E2E) tests** - Complete workflow validation
3. **Dogfooding tests** - Real-world usage scenarios

## Specific Requirements

### 1. Unit Testing Framework

- **Tool specification**: Native assert functions (Option C from research) — no external deps
- **Coverage targets**: All exported functions, edge cases, error handling
- **Mock requirements**: External commands (git, curl, etc.), filesystem operations
- **Assertion types**: Exit codes, stdout/stderr, variable states, file existence
- **Isolation**: Each test must be independent with setup/teardown

### 2. E2E Testing Specifications

- **Workflow scope**: Complete user journeys from command invocation to final output
- **Environment**: Temporary test directories, clean shell state
- **Integration points**: File I/O, external tool chains, configuration files
- **Success criteria**: Expected output files, correct side effects, proper cleanup
- **Failure scenarios**: Graceful degradation, error messages, rollback mechanisms

### 3. Dogfooding Test Requirements

- **Real usage**: Actual workflows used daily (not synthetic tests)
- **Performance**: Measure execution time, resource usage
- **User experience**: Command discoverability, error clarity, help text
- **Platform coverage**: macOS (primary), Linux compatibility checks
- **Regression prevention**: Capture known issues, prevent reoccurrence

## Constraints & Preferences

- **Speed**: Unit tests <100ms each, E2E <5s, full suite <30s
- **ADHD-friendly output**:
  - Color-coded results
  - Progress indicators [X/Y tests]
  - Summary sections with counts
  - Clear failure diagnostics
- **CI/CD ready**: GitHub Actions compatible, exit codes
- **No external dependencies**: Minimize required installations
- **Portable**: Works in both zsh and bash environments

## Framework Selection: Enhanced Native (Option C)

### Rationale

| Considered | Decision | Why |
|-----------|----------|-----|
| ShellSpec | Rejected | BDD DSL learning curve, full rewrite needed for 186 existing files |
| BATS-core | Rejected | Bash-only, no ZSH support |
| ZTAP | Future option | Good for new projects, but migration cost for existing tests |
| ZUnit | Rejected | Stale maintenance |
| **Native enhanced** | **Selected** | Zero deps, incremental migration, immediate value |

### What "Enhanced Native" Means

Add to existing `tests/test-framework.zsh`:

1. **Strict assertions**: `assert_exit_code`, `assert_output_contains`, `assert_output_excludes`
2. **Mock registry**: `create_mock`, `assert_mock_called`, `assert_mock_args`, `reset_mocks`
3. **Subshell isolation**: `run_isolated` wrapper per test
4. **Anti-pattern scanner**: Dogfood test that finds permissive tests

## Test Taxonomy

| Layer | Purpose | Count target | Speed | Pattern |
|-------|---------|-------------|-------|---------|
| **Unit** | Single function, mocked deps | ~60% of tests | <100ms each | `assert_exit_code`, `assert_output_contains` |
| **Integration** | Multiple functions together | ~25% of tests | <1s each | Real plugin sourced, mock only externals |
| **E2E/Dogfood** | Full workflow scenarios | ~10% of tests | <5s each | Source plugin, run real commands, check real output |
| **Regression** | Specific bug reproductions | ~5% of tests | <100ms each | One test per bug, linked to issue |

## Deliverables

1. **Assertion helpers** in `tests/test-framework.zsh` (6+ functions)
2. **Mock registry** in `tests/test-framework.zsh` (4+ functions)
3. **Converted test files**: test-work.zsh, test-dispatchers.zsh, test-core.zsh
4. **Dogfood scanner**: `tests/dogfood-test-quality.zsh` — finds anti-patterns
5. **Documentation**: Update `docs/guides/TESTING.md` with new patterns

## Anti-Patterns to Eliminate

| Anti-Pattern | Example | Fix |
|-------------|---------|-----|
| Permissive exit code | `if [[ $? -eq 0 \|\| $? -eq 1 ]]` | `assert_exit_code 1 $?` |
| Existence-only check | `if type X &>/dev/null` | Test behavior, not existence |
| No output assertion | Run command, don't check output | `assert_output_contains` |
| Unverified mock | Override function, never check call | `assert_mock_called` |
| Shared global state | Tests affect each other | `run_isolated` wrapper |

## Success Metrics

- [ ] Can add new unit test in <2 minutes
- [ ] Test failures show exact line + context
- [ ] Full test suite completes in <30 seconds
- [ ] Zero false positives
- [ ] CI integration blocks broken commits
- [ ] Anti-pattern scanner catches new permissive tests

## Implementation

See `ORCHESTRATE-testing-overhaul.md` for concrete task breakdown and parallel execution plan.
