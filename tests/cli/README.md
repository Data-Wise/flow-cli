# flow-cli Automated Test Suite

CI-ready test suite for validating flow CLI functionality.

## Quick Start

```bash
# Run automated tests
bash tests/cli/automated-tests.sh

# Run from any directory
bash /path/to/flow-cli/tests/cli/automated-tests.sh
```

## Test Coverage

The test suite validates **95 test cases** across 15 sections:

| Section                      | Tests | Description                                     |
| ---------------------------- | ----- | ----------------------------------------------- |
| Installation & Prerequisites | 5     | Plugin file, directories, ZSH availability      |
| Plugin Loading               | 5     | Sourcing, function definitions, core utilities  |
| Help System                  | 8     | Help output, command mentions, sync/doctor help |
| Sync Command                 | 12    | Functions, targets, schedule, dry-run           |
| Doctor Command               | 2     | Function exists, diagnostic output              |
| Config Command               | 2     | Function exists, show works                     |
| Plugin Command               | 2     | Function exists, list works                     |
| Dispatchers                  | 15    | File existence, function defs, help output      |
| Completions                  | 8     | Completion files, sync targets, schedule        |
| Core Commands                | 15    | Command files, function definitions             |
| Command Behavior             | 7     | work, dash, finish, pick, status, hop, why      |
| ADHD Features                | 4     | win, goal, js, yay functions                    |
| Error Handling               | 2     | Invalid command handling                        |
| Documentation                | 4     | Key doc files exist                             |
| Performance Benchmarks       | 3     | Plugin source time, help response time          |

## Code Coverage by Component

| Component       | Files Tested | Functions Tested | Coverage  |
| --------------- | ------------ | ---------------- | --------- |
| **Core**        | 8/8          | 15+              | ✅ High   |
| **Commands**    | 8/8          | 20+              | ✅ High   |
| **Dispatchers** | 6/6          | 12+              | ✅ High   |
| **Completions** | 6/6          | N/A              | ✅ High   |
| **Lib**         | 3/5          | 8+               | 🔶 Medium |
| **Hooks**       | 0/2          | 0                | ⚠️ Low    |

### Untested Areas

The following areas need additional test coverage:

- `hooks/chpwd.zsh` - Directory change hooks
- `hooks/precmd.zsh` - Pre-command hooks
- `lib/tui.zsh` - Interactive TUI components
- Integration tests with actual git repositories

## Requirements

- **macOS or Linux** with bash 4+
- **ZSH** installed (for function tests)
- No external dependencies

## CI Integration

### GitHub Actions

```yaml
# .github/workflows/test.yml
name: CLI Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run CLI Tests
        run: bash tests/cli/automated-tests.sh
```

### Exit Codes

- `0` - All tests passed
- `1` - One or more tests failed

## Output Format

```
═══════════════════════════════════════════════════════════════
  AUTOMATED CLI TEST SUITE: flow-cli
═══════════════════════════════════════════════════════════════
  Directory: /path/to/flow-cli
  Date: 2025-12-27 15:58:00

▶ Installation & Prerequisites
✅ PASS: Plugin file exists
✅ PASS: Core library exists
...

═══════════════════════════════════════════════════════════════
  RESULTS
═══════════════════════════════════════════════════════════════
  Total:   85
  Passed:  84
  Failed:  0
  Skipped: 1

  Pass Rate: 98%

All tests passed!
```

## Test Types

### File Existence Tests

Check that required files exist:

```bash
[[ -f "$FLOW_CLI_DIR/flow.plugin.zsh" ]]
```

### Function Definition Tests

Verify functions are defined after sourcing:

```bash
zsh -c "source '$FLOW_CLI_DIR/flow.plugin.zsh' && typeset -f work >/dev/null"
```

### Output Validation Tests

Check command output contains expected content:

```bash
zsh -c "source '$FLOW_CLI_DIR/flow.plugin.zsh' && flow help" 2>&1 | grep -q "FLOW"
```

### Grep Validation Tests

Verify file contents:

```bash
grep -q "sync_targets" "$FLOW_CLI_DIR/completions/_flow"
```

## Related Tests

- **Unit tests**: `tests/test-sync.zsh` (82 tests for sync functionality)
- **Interactive tests**: `tests/interactive-dog-feeding.zsh` (gamified testing)
- **Integration tests**: `tests/integration/` (Atlas + flow-cli)

## Maintenance

When adding new features:

1. Add file existence tests if new files are created
2. Add function definition tests for new commands
3. Add output validation for new help/commands
4. Update test count in this README

---

_Generated: 2025-12-27_
_Version: flow-cli v4.0.0_
