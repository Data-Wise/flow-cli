# ORCHESTRATE: Scholar Config Sync + New Wrappers

**Issue:** #423
**Spec:** `docs/specs/SPEC-scholar-config-sync-2026-02-26.md`
**Branch:** `feature/scholar-config`
**Estimated:** 3-4 hours (7 increments)

---

## Pre-Flight

Before starting, verify:

```bash
# Confirm Scholar plugin has --config support
ls ~/.claude/plugins/scholar/src/teaching/config/loader.js
# Confirm existing config infrastructure
grep -n '_teach_find_config' lib/dispatchers/teach-dispatcher.zsh
grep -n '_flow_config_hash' lib/config-validator.zsh
grep -n '_flow_config_changed' lib/config-validator.zsh
```

---

## Increment 1: Core Config Wiring (30 min)

**File:** `lib/dispatchers/teach-dispatcher.zsh`

### Task 1.1: Config injection in command assembly block

**Location:** ~lines 2153-2201 (after existing flag appends)

Add after the existing `--instructions`/`--context`/`--template`/`--prompt` appends:

```zsh
# Config injection (Scholar Config Sync, #423)
local config_path
config_path=$(_teach_find_config 2>/dev/null)
if [[ -n "$config_path" ]]; then
    scholar_cmd="$scholar_cmd --config \"$config_path\""
fi
```

### Task 1.2: Stale config warning in `_teach_preflight()`

**Location:** `_teach_preflight()` (~line 1349)

Add after existing config validation:

```zsh
# Stale config warning (#423)
if _flow_config_changed 2>/dev/null; then
    _flow_log_warn "Config changed since last Scholar run"
    _flow_log_warn "  Run: teach config check"
fi
```

### Task 1.3: Legacy deprecation warning in `_teach_preflight()`

Add after the stale config warning:

```zsh
# Legacy file deprecation warning (#423)
local legacy_style="${FLOW_PROJECT_ROOT}/.claude/teaching-style.local.md"
if [[ -f "$legacy_style" ]] && [[ -n "$config_path" ]]; then
    _flow_log_warn "Deprecated: .claude/teaching-style.local.md"
    _flow_log_warn "  Scholar now reads from: .flow/teach-config.yml"
    _flow_log_warn "  teaching_style section takes precedence"
fi
```

### Verify

```bash
source flow.plugin.zsh
# With config: verify --config appears in Scholar command
# Without config: verify no --config (graceful fallback)
```

---

## Increment 2: Config Subcommands (30 min)

**File:** `lib/dispatchers/teach-dispatcher.zsh`

### Task 2.1: Add config subcommand routing

Find the `config)` case in the main dispatcher. Add new subcommands:

```zsh
config)
    shift
    case "$1" in
        check)     _teach_scholar_wrapper "config" "validate" "--strict" ;;
        diff)      _teach_scholar_wrapper "config" "diff" "${@:2}" ;;
        show)      _teach_scholar_wrapper "config" "show" "${@:2}" ;;
        scaffold)  _teach_scholar_wrapper "config" "scaffold" "${@:2}" ;;
        # existing handlers below (edit, view, cat, etc.)
        *)         _teach_config_edit "$@" ;;
    esac
    ;;
```

### Task 2.2: Verify `_teach_scholar_wrapper` handles config subcommands

The wrapper function should map `config validate` to `/teaching:config validate`. Check `_teach_build_command()` (~line 1389) to see if `config` is already handled. If not, add:

```zsh
config) scholar_cmd="/teaching:config $*" ;;
```

### Verify

```bash
# Each should dispatch to Scholar correctly:
teach config check
teach config diff
teach config show
teach config scaffold exam
```

---

## Increment 3: New Scholar Wrappers (45 min)

**File:** `lib/dispatchers/teach-dispatcher.zsh`

### Task 3.1: Add dispatcher cases

Add to the main `teach()` case statement:

```zsh
solution)    shift; _teach_scholar_wrapper "solution" "$@" ;;
sync)        shift; _teach_scholar_wrapper "sync" "$@" ;;
validate-r)  shift; _teach_scholar_wrapper "validate-r" "$@" ;;
```

### Task 3.2: Add command mappings in `_teach_build_command()`

Add to the case statement in `_teach_build_command()`:

```zsh
solution)    scholar_cmd="/teaching:solution $*" ;;
sync)        scholar_cmd="/teaching:sync $*" ;;
validate-r)  scholar_cmd="/teaching:validate-r $*" ;;
```

### Task 3.3: Update `_teach_help()` with new commands

Add new sections to help output:

```
Config Management:
  teach config check       Validate config (pre-flight)
  teach config diff        Compare prompts vs defaults
  teach config show        Show resolved 4-layer config
  teach config scaffold    Copy default prompts for customization
  teach config edit        Open config in editor (existing)

Content Generation:
  teach solution <topic>   Generate solution key
  teach sync               Sync config to Scholar format

Code Quality:
  teach validate-r         Validate R code in .qmd files
```

### Verify

```bash
teach solution "Bayesian inference"
teach sync
teach validate-r
teach help  # should show new commands
```

---

## Increment 4: Doctor Integration (15 min)

**File:** `commands/teach-doctor.zsh`

### Task 4.1: Add config sync section

Create `_teach_doctor_config_sync()` function:

```zsh
_teach_doctor_config_sync() {
    local config_path
    config_path=$(_teach_find_config 2>/dev/null)

    _flow_log_header "Scholar Config"

    if [[ -n "$config_path" ]]; then
        _flow_log_success "Config file: $config_path"
        # Check if Scholar section exists
        if grep -q "scholar:" "$config_path" 2>/dev/null || grep -q "teaching_style:" "$config_path" 2>/dev/null; then
            _flow_log_success "Scholar section: present"
        else
            _flow_log_warn "Scholar section: missing (add teaching_style: or scholar: to config)"
        fi
        _flow_log_success "Auto-injection: enabled"
    else
        _flow_log_warn "Config file: not found"
        _flow_log_warn "  Run: teach init (to create .flow/teach-config.yml)"
    fi

    # Legacy file check
    local legacy_style="${FLOW_PROJECT_ROOT}/.claude/teaching-style.local.md"
    if [[ -f "$legacy_style" ]]; then
        _flow_log_warn "Legacy file: .claude/teaching-style.local.md (deprecated)"
    fi
}
```

### Task 4.2: Wire into doctor

Add `_teach_doctor_config_sync` call to both quick and full doctor modes.

### Verify

```bash
teach doctor        # quick mode shows config sync
teach doctor --full # full mode shows config sync
```

---

## Increment 5: Tests (30 min)

**File:** `tests/test-scholar-config-sync.zsh` (NEW)

### Test Cases

1. `test_config_injection_when_found` — mock `_teach_find_config` returning a path, verify `--config` appears in scholar_cmd
2. `test_config_injection_when_missing` — mock `_teach_find_config` returning empty, verify no `--config`
3. `test_config_changed_warning` — mock `_flow_config_changed` returning true, verify warning output
4. `test_legacy_deprecation_warning` — create both files, verify deprecation message
5. `test_config_check_dispatch` — verify `teach config check` maps to correct Scholar command
6. `test_config_diff_dispatch` — verify `teach config diff` mapping
7. `test_config_show_dispatch` — verify `teach config show` mapping
8. `test_config_scaffold_dispatch` — verify `teach config scaffold` mapping
9. `test_solution_dispatch` — verify `teach solution` mapping
10. `test_sync_dispatch` — verify `teach sync` mapping
11. `test_validate_r_dispatch` — verify `teach validate-r` mapping
12. `test_help_includes_new_commands` — verify help output contains all 7 new commands
13. `test_doctor_config_sync_section` — verify doctor shows config sync status

### Framework

```zsh
#!/usr/bin/env zsh
PROJECT_ROOT="${0:A:h:h}"
source "${0:A:h}/test-framework.zsh"
test_suite "Scholar Config Sync Tests"
# ... test functions ...
test_suite_end
print_summary
exit $(( TESTS_FAILED > 0 ? 1 : 0 ))
```

### Add to run-all.sh

Add `test-scholar-config-sync.zsh` to `tests/run-all.sh`.

### Verify

```bash
zsh tests/test-scholar-config-sync.zsh        # all pass
./tests/run-all.sh                             # full suite passes
zsh tests/dogfood-test-quality.zsh             # no anti-patterns
```

---

## Increment 6: Documentation (30 min)

### Task 6.1: Update `docs/reference/MASTER-DISPATCHER-GUIDE.md`

Add to the teach dispatcher section:

- Config Commands Table (check/diff/show/scaffold with Scholar mappings)
- New Generation Commands table (solution/sync/validate-r)
- Config Auto-Injection section explaining transparent `--config` passing

### Task 6.2: Update `docs/guides/TEACHING-SYSTEM-ARCHITECTURE.md`

Add "Config Sync Architecture" section:
- Config discovery chain
- Change detection
- Legacy migration
- 4-layer style resolution

### Task 6.3: Update `docs/help/QUICK-REFERENCE.md`

Add all 7 new commands to the teach section.

### Task 6.4: Update `CLAUDE.md`

Add to Teaching Subcommands list: `teach solution`, `teach sync`, `teach validate-r`, `teach config check/diff/show/scaffold`

### Task 6.5: Create `docs/guides/SCHOLAR-INTEGRATION-GUIDE.md` (NEW)

Full integration guide covering:
- Prerequisites
- How Config Sync works
- Setting up Config Sync
- Config Management Commands (check/diff/show/scaffold)
- New Generation Commands (solution/sync/validate-r)
- Troubleshooting

### Verify

```bash
mkdocs build --strict 2>&1 | grep -E "(WARNING|ERROR)"  # no issues
```

---

## Increment 7: Final Verification (15 min)

### Full Test Suite

```bash
./tests/run-all.sh                    # all suites pass
zsh tests/dogfood-test-quality.zsh    # no anti-patterns
```

### Manual Smoke Test

```bash
# In a course directory with .flow/teach-config.yml:
teach exam "Test Topic"     # should inject --config
teach config check          # should validate
teach config show           # should show 4-layer config
teach solution "Topic"      # should generate solution key
teach doctor                # should show config sync section
teach help                  # should list all new commands
```

### Docs Check

```bash
mkdocs serve  # spot-check new pages render correctly
```

---

## Commit Strategy

| Increment | Commit Message |
|-----------|---------------|
| 1 | `feat: wire --config injection to Scholar commands (#423)` |
| 2 | `feat: add teach config check/diff/show/scaffold subcommands (#423)` |
| 3 | `feat: add teach solution, sync, validate-r wrappers (#423)` |
| 4 | `feat: add config sync section to teach doctor (#423)` |
| 5 | `test: add Scholar Config Sync test suite (#423)` |
| 6 | `docs: add Scholar integration guide and update references (#423)` |
| 7 | (no commit — verification only) |

---

## Definition of Done

- [ ] All 9 Scholar-wrapped commands receive `--config` when config exists
- [ ] Graceful fallback when no config file present
- [ ] Hash change detection wired and warning shown
- [ ] Legacy deprecation warning present
- [ ] Doctor reports config sync status
- [ ] Config subcommands (check/diff/show/scaffold) dispatch correctly
- [ ] New wrappers (solution/sync/validate-r) dispatch correctly
- [ ] Help output includes all new commands
- [ ] Tests: 13+ test functions covering all scenarios
- [ ] Docs updated (dispatcher guide, architecture, quick reference, integration guide)
- [ ] `./tests/run-all.sh` passes with new test file
- [ ] `zsh tests/dogfood-test-quality.zsh` passes

---

## Post-Implementation

After all increments complete:

```bash
git fetch origin dev && git rebase origin/dev
./tests/run-all.sh
gh pr create --base dev --title "feat: Scholar Config Sync + new teach wrappers (#423)"
```
