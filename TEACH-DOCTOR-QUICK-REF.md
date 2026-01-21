# Teach Doctor - Quick Reference Card

**Version:** v4.6.0 | **Status:** ✅ Production Ready

---

## Commands

```bash
teach doctor              # Full health check (all 6 categories)
teach doctor --quiet      # Only show warnings/failures
teach doctor --fix        # Interactive fix mode (prompts for installs)
teach doctor --json       # JSON output for CI/CD
teach doctor --help       # Show help
```

---

## Check Categories (6)

| # | Category | Checks |
|---|----------|--------|
| 1 | **Dependencies** | yq, git, quarto, gh, examark, claude, R packages, Quarto extensions |
| 2 | **Configuration** | .flow/teach-config.yml, YAML syntax, schema validation, course metadata |
| 3 | **Git Setup** | Repository, draft branch, production branch, remote, working tree |
| 4 | **Scholar** | Claude Code, Scholar skills, lesson-plan.yml |
| 5 | **Git Hooks** | pre-commit, pre-push, prepare-commit-msg (flow-cli managed vs custom) |
| 6 | **Cache Health** | _freeze/ size, last render time, freshness, file count |

---

## Exit Codes

- `0` - All checks passed (warnings OK)
- `1` - One or more checks failed

---

## Interactive Fix Example

```bash
$ teach doctor --fix

Dependencies:
  ✗ yq not found
  → Install yq? [Y/n] y
  → brew install yq
  ✓ yq installed

R Packages:
  ⚠ R package 'ggplot2' not found (optional)
  → Install R package 'ggplot2'? [y/N] y
  → Rscript -e "install.packages('ggplot2')"
  ✓ ggplot2 installed

Cache Health:
  ⚠ Cache is stale (31 days old)
  → Clear stale cache? [y/N] n
```

---

## JSON Output

```json
{
  "summary": {
    "passed": 28,
    "warnings": 3,
    "failures": 0,
    "status": "healthy"
  },
  "checks": [
    {"check":"dep_yq","status":"pass","message":"4.35.2"},
    {"check":"cache_freshness","status":"warn","message":"31 days old"}
  ]
}
```

---

## CI/CD Integration

### GitHub Actions

```yaml
- name: Health Check
  run: |
    teach doctor --json > health.json
    jq -e '.summary.status == "healthy"' health.json

- name: Upload Results
  if: always()
  uses: actions/upload-artifact@v3
  with:
    name: health-check
    path: health.json
```

### Check Status

```bash
# Extract status
teach doctor --json | jq -r '.summary.status'
# Output: "healthy" or "unhealthy"

# Count failures
teach doctor --json | jq '.summary.failures'
# Output: 0 (or number of failures)
```

---

## Files

| File | Lines | Purpose |
|------|-------|---------|
| `lib/dispatchers/teach-doctor-impl.zsh` | 626 | Implementation |
| `tests/test-teach-doctor-unit.zsh` | 615 | Unit tests (39 tests, 100% pass) |
| `tests/demo-teach-doctor.sh` | 60 | Interactive demo |
| `docs/teach-doctor-implementation.md` | 585 | Complete documentation |

---

## Performance

- **Execution Time:** 2-5 seconds (depending on checks)
- **Test Time:** ~5 seconds (39 tests)
- **Non-blocking:** All checks are read-only (except --fix)

---

## Troubleshooting

### Issue: yq not found but installed
```bash
which yq              # Check PATH
brew reinstall yq     # Reinstall
```

### Issue: R packages check fails
```bash
R
> install.packages(c("ggplot2", "dplyr", "tidyr", "knitr", "rmarkdown"))
```

### Issue: Git hooks not detected
```bash
ls -la .git/hooks/         # Check permissions
chmod +x .git/hooks/*      # Make executable
```

### Issue: Cache freshness incorrect
```bash
find _freeze -type f -exec stat -f "%m %N" {} \; | sort -rn | head
```

---

## Color Legend

- ✓ **Green** - Passed
- ⚠ **Yellow** - Warning (optional or non-critical)
- ✗ **Red** - Failed (required dependency missing)
- → **Blue** - Action hint or fix suggestion
- **Gray** - Muted info (details)

---

## Quick Diagnosis

```bash
# Check if healthy
teach doctor --quiet && echo "✅ All good" || echo "⚠️ Issues found"

# Get summary
teach doctor --json | jq '.summary'

# List failures only
teach doctor --json | jq -r '.checks[] | select(.status=="fail") | .check'

# Count problems
teach doctor --json | jq '[.checks[] | select(.status!="pass")] | length'
```

---

**Documentation:** `docs/teach-doctor-implementation.md`

**Tests:** `./tests/test-teach-doctor-unit.zsh`

**Demo:** `./tests/demo-teach-doctor.sh`
