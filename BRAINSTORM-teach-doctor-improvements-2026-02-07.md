# Teach Doctor Improvements - Brainstorm

**Generated:** 2026-02-07
**Context:** flow-cli `teach doctor` command review
**Source:** `lib/dispatchers/teach-doctor-impl.zsh` (813 lines)

## Observed Issues

### Bug 1: Quarto Extensions Arithmetic Error

```
_teach_doctor_check_quarto_extensions:13: bad math expression: operator expected at `Terminal R...'
```

**Root cause:** Line 484 uses `find _extensions -mindepth 2 -maxdepth 2 -type d` piped to `wc -l`. When `_extensions/` exists but contains entries with spaces or special characters in directory names, the `ext_count` variable gets polluted. The `[[ "$ext_count" -gt 0 ]]` comparison on line 486 then fails because `ext_count` contains non-numeric text.

**Likely scenario:** The `find` output or `wc -l` is including unexpected text (possibly from a directory named with "Terminal R..." in the path, or `find` is outputting an error message that gets counted).

**Fix:** Sanitize `ext_count` or use a glob-based count instead of `find`:

```zsh
# Option A: Glob-based (pure ZSH, faster)
local -a ext_dirs=(_extensions/*/*(N/))
local ext_count=${#ext_dirs}

# Option B: Sanitize find output
local ext_count=$(find _extensions -mindepth 2 -maxdepth 2 -type d 2>/dev/null | wc -l)
ext_count=${ext_count//[^0-9]/}  # Strip non-numeric
[[ -z "$ext_count" ]] && ext_count=0
```

---

### Bug 2: R Package Detection Shows 27 Warnings

All R packages show `not found` even though they're likely installed. Two sub-issues:

1. **Source detection fails silently**: `_list_r_packages_from_sources` returns nothing (no `teaching.yml`, no `renv.lock`, no `DESCRIPTION` in cwd), so code falls back to a hardcoded list of 5 packages... but the output shows 27 packages. This means `_list_r_packages_from_sources` IS returning packages (from `renv.lock`), but `_check_r_package_installed` is failing for each one.

2. **Per-package R invocation is slow and fragile**: Each package check spawns `R --quiet --slave -e "if (!require(...))"`. If renv is active, R might be looking in the renv library (which is project-local) and not finding system-installed packages. This is the most likely cause of all 27 "not found" warnings.

**Fix options:**

```zsh
# Option A: Batch check (single R invocation for ALL packages)
_check_r_packages_batch() {
    local packages="$1"  # newline-separated
    local pkg_vector=$(echo "$packages" | sed 's/.*/"&"/' | paste -sd, -)
    R --quiet --slave -e "
        pkgs <- c($pkg_vector)
        installed <- rownames(installed.packages())
        for (p in pkgs) {
            cat(p, ifelse(p %in% installed, 'YES', 'NO'), '\n')
        }
    " 2>/dev/null
}

# Option B: Use installed.packages() file scan (no library loading)
# Faster than require() which actually loads the package
R --quiet --slave -e "cat(rownames(installed.packages()), sep='\n')" 2>/dev/null
```

---

### Bug 3: R Packages Section Runs Inside Dependencies

The R package check is called from `_teach_doctor_check_dependencies()` (line 118-120), which means "R Packages:" appears nested under "Dependencies:" in the output. This is confusing because it's a separate category.

**Fix:** Move R package check to its own section in `_teach_doctor()` main function, between dependencies and quarto extensions.

---

## Improvement Proposals

### Quick Wins (< 30 min each)

1. **Fix Quarto extensions arithmetic error** - Replace `find | wc -l` with ZSH glob `_extensions/*/*(N/)` count
2. **Fix R package check context** - Use `installed.packages()` instead of `require()` to avoid renv library isolation
3. **Batch R package check** - Single R invocation instead of 27 separate ones (5+ seconds faster)
4. **Move R Packages to own section** - Extract from `_teach_doctor_check_dependencies()` to top-level

### Medium Effort (1-2 hours)

5. **Add `--dot` quick mode** - Skip slow checks (R packages, cache freshness) for fast < 3s doctor run
6. **Parallel section execution** - Run independent checks concurrently with background subshells
7. **Summary with actionable fix commands** - Group warnings by "fix priority" and show copy-pasteable commands
8. **Add `--section` flag** - Run only specific sections (`teach doctor --section r-packages`)

### Long-term (Future sessions)

9. **Doctor result caching** - Cache results for N minutes, skip re-running unchanged checks
10. **CI integration** - `teach doctor --ci` that exits non-zero on any failure (for GitHub Actions)
11. **HTML report** - `teach doctor --html` for shareable environment reports

---

## Architecture Observations

### Current Flow

```
_teach_doctor()
  ├── _teach_doctor_check_dependencies()
  │     ├── dep checks (yq, git, quarto, gh, examark, claude)
  │     ├── _teach_doctor_check_r_packages()     ← nested here (wrong level)
  │     └── _teach_doctor_check_quarto_extensions() ← also nested (wrong level)
  ├── _teach_doctor_check_config()
  ├── _teach_doctor_check_git()
  ├── _teach_doctor_check_scholar()
  ├── _teach_doctor_check_hooks()
  ├── _teach_doctor_check_cache()
  ├── _teach_doctor_check_macros()
  └── _teach_doctor_check_teaching_style()
```

### Proposed Flow

```
_teach_doctor()
  ├── _teach_doctor_check_dependencies()   ← CLI tools only
  ├── _teach_doctor_check_r_packages()     ← promoted to top-level
  ├── _teach_doctor_check_quarto_extensions() ← promoted to top-level
  ├── _teach_doctor_check_config()
  ├── _teach_doctor_check_git()
  ├── _teach_doctor_check_scholar()
  ├── _teach_doctor_check_hooks()
  ├── _teach_doctor_check_cache()
  ├── _teach_doctor_check_macros()
  └── _teach_doctor_check_teaching_style()
```

---

## Recommended Path

Start with the **3 bugs** (Quick Wins 1-4), which would immediately fix the broken output. Then the batch R check (Quick Win 3) gives the biggest UX improvement by cutting doctor runtime from ~30s to ~5s.

## Next Steps

1. [ ] Fix Quarto extensions arithmetic error (glob-based count)
2. [ ] Fix R package detection (batch check with `installed.packages()`)
3. [ ] Promote R packages and Quarto extensions to top-level sections
4. [ ] Test with `./tests/test-teach-doctor-unit.zsh`
