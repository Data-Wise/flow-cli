# Teaching System Troubleshooting

> Quick fixes for common issues with the teach dispatcher.
>
> **Version:** v6.1.0+
> **Last Updated:** 2026-02-02

---

## Quick Diagnostics

**First steps for any issue:**

```bash
teach doctor                 # Full health check
teach doctor --fix           # Auto-fix common issues
teach doctor --json          # Machine-readable output
```

**Category-specific checks:**

```bash
teach doctor --dot           # Check only dependencies
teach doctor --quiet         # Show only warnings/failures
teach doctor --verbose       # Detailed debug output
```

---

## Configuration Issues

### "teach-config.yml not found"

**Symptoms:**
- Error: `.flow/teach-config.yml not found`
- Commands fail with "Run 'teach init' to create the configuration"

**Cause:**
- Project not initialized with flow-cli teaching workflow
- Running commands from wrong directory

**Fix:**

```bash
# Create new teaching project
teach init

# Or navigate to project root
cd /path/to/your/course
teach doctor
```

**Verify:**

```bash
ls .flow/teach-config.yml    # Should exist
teach config view            # Display configuration
```

---

### "Invalid config: course.semester must be..."

**Symptoms:**
- `teach doctor` reports validation errors
- Error: "Invalid semester 'fall' - must be Spring, Summer, Fall, or Winter"

**Common typos and fixes:**

| Error                        | Cause          | Fix                      |
|------------------------------|----------------|--------------------------|
| `semester: fall`             | Lowercase      | `semester: Fall`         |
| `semester: spring 2025`      | Not enum       | `semester: Spring`       |
| `year: "2025"`               | String not int | `year: 2025`             |
| `start_date: 01-15-2025`     | Wrong format   | `start_date: 2025-01-15` |

**Fix:**

```bash
# Edit config
$EDITOR .flow/teach-config.yml

# Valid semester values
course:
  semester: Spring    # or Summer, Fall, Winter (capitalized)
  year: 2025          # integer, 2020-2100
```

**Verify:**

```bash
teach validate --config       # Run full config validation
teach doctor --quiet          # Check for remaining issues
```

---

### "Config changed, reloading" warnings

**Symptoms:**
- Frequent warnings: "Config changed, reloading..."
- Performance degradation
- Cache invalidation messages

**Cause:**
- Hash-based change detection triggering on every access
- File modification time updated by editor/tools
- Cached hash out of sync

**When to ignore:**
- Single warning after editing `.flow/teach-config.yml` (expected)
- After running `teach init` or `teach config set`

**When to investigate:**
- Warning appears on every command
- No recent config edits
- Multiple rapid warnings

**Fix:**

```bash
# Clear config cache
rm -f ~/.local/share/flow-cli/cache/teach-config.hash

# Force re-hash
teach config view

# Verify no more warnings
teach doctor
```

**Prevent:**
- Avoid editing config while commands are running
- Use `teach config set` instead of manual edits
- Disable file watchers on `.flow/teach-config.yml`

---

## Scholar / AI Generation Issues

### "Scholar plugin not found"

**Symptoms:**
- Error: "Claude Code not found"
- Warning: "Scholar skills not detected"
- `teach exam` fails with "Scholar unavailable"

**Cause:**
- Claude Code CLI not installed
- Scholar plugin not configured in Claude settings

**Fix:**

```bash
# 1. Check if Claude Code is installed
which claude
# If not found, install from: https://code.claude.com

# 2. Check Scholar plugin
claude --list-skills | grep scholar:

# 3. If missing, install Scholar plugin
# Follow: https://github.com/Data-Wise/scholar

# 4. Verify integration
teach doctor
```

**Verify:**

```bash
# Should show Scholar skills
claude --list-skills | grep -A 3 "scholar:"
# Expected output:
#   scholar:exam-generate
#   scholar:quiz-generate
#   scholar:lecture-outline
```

---

### "Empty output from Scholar"

**Symptoms:**
- `teach exam "Linear Regression"` generates empty file
- Claude returns no content
- No error messages, but file is 0 bytes

**Causes (ordered by likelihood):**

**1. Missing config fields**

```bash
# Check required Scholar fields
teach config view | grep -A 10 "scholar:"

# Required fields:
#   scholar.course_info.level: undergraduate|graduate|both
#   scholar.course_info.difficulty: beginner|intermediate|advanced
#   scholar.style.tone: formal|conversational
```

**Fix:**

```bash
teach config set scholar.course_info.level undergraduate
teach config set scholar.course_info.difficulty intermediate
teach validate --config
```

**2. Claude timeout**

```bash
# Default timeout: 60s (may be too short for complex content)
# Increase timeout in Claude settings or retry with simpler prompt

teach exam "Simple topic" --verbose   # Watch for timeout messages
```

**3. Network issues**

```bash
# Check Claude Code connectivity
claude --version
ping anthropic.com

# Test with simple prompt
echo "Generate a test question" | claude
```

**Verify:**

```bash
# Generate simple content first
teach quiz "Basic Math" --questions 3

# Check file created
ls -lh quizzes/quiz-*.qmd
# Should be > 0 bytes

# View content
head -20 quizzes/quiz-*.qmd
```

---

### "LaTeX macros not rendering"

**Symptoms:**
- Generated content uses `E[Y]` instead of `\E{Y}`
- Macros not expanded in output
- Math notation inconsistent with course style

**Causes:**

**1. Macro source not synced**

```bash
# Check macro sources
teach macros list
# If empty or outdated, sync

# Sync from sources
teach macros sync

# Verify extraction
teach macros list | head -20
# Should show: \E, \V, \Cov, etc.
```

**2. Export format mismatch**

```bash
# Check export format in config
teach config view | grep -A 5 "latex_macros:"

# Should match:
scholar:
  latex_macros:
    enabled: true
    export:
      format: qmd              # or mathjax, latex, json
      include_in_prompts: true
```

**Fix:**

```bash
# 1. Create macro source file
cat > _macros.qmd <<'EOF'
$$
\newcommand{\E}[1]{\mathbb{E}\left[#1\right]}
\newcommand{\V}[1]{\text{Var}\left(#1\right)}
\newcommand{\Cov}[2]{\text{Cov}\left(#1, #2\right)}
$$
EOF

# 2. Sync macros
teach macros sync

# 3. Export for Scholar
teach macros export --format qmd

# 4. Verify CLAUDE.md updated
grep -A 10 "LaTeX Macros" CLAUDE.md
```

**Verify:**

```bash
# Generate content with macros
teach exam "Expected Value" --verbose

# Check macro usage
grep -E '\\E\{|\\V\{|\\Cov\{' exams/exam-*.qmd
```

---

### "Conflicting content flags"

**Symptoms:**
- Warning: "Multiple content flags specified"
- Error: "Cannot use --conceptual with --computational"

**Cause:**
- Multiple style flags passed simultaneously
- Flags have priority: `--rigorous` > `--conceptual` > `--computational`

**Flag priority rules:**

```bash
# Only ONE flag is used (highest priority wins)
teach exam "Topic" --conceptual --computational   # Uses: conceptual
teach exam "Topic" --rigorous --conceptual        # Uses: rigorous
```

**Fix:**

```bash
# Remove conflicting flags, use only one
teach exam "Regression" --conceptual       # ✓ Good
teach exam "Regression" --computational    # ✓ Good
teach exam "Regression" --rigorous         # ✓ Good

# Configure default in teach-config.yml
teach config set scholar.style.default_style conceptual
```

**Verify:**

```bash
# Check effective style
teach config view | grep default_style

# Test generation
teach quiz "Statistics" --questions 3
```

---

## Deployment Issues

### "Deploy failed: git conflict on gh-pages"

**Symptoms:**
- Error: `Force-push conflict detected`
- Deploy stops with "Production branch has updates"
- git error: `rejected (non-fast-forward)`

**Cause:**
- GitHub Pages auto-commits to `gh-pages` branch
- Local `gh-pages` diverged from remote
- Force-push protection enabled

**Resolution:**

```bash
# Check current state
git status
git log --oneline gh-pages..origin/gh-pages

# Option 1: Rebase onto remote (recommended)
git checkout gh-pages
git pull --rebase origin gh-pages
teach deploy

# Option 2: Reset to remote (destructive)
git checkout gh-pages
git fetch origin
git reset --hard origin/gh-pages
teach deploy

# Option 3: Skip gh-pages update
teach deploy --skip-index
```

**Prevent:**

```bash
# Always pull before deploy
git checkout draft
git pull origin draft
teach deploy
```

**Verify:**

```bash
# Check deployment status
gh pr list --base production

# Verify remote sync
git fetch origin
git status
```

---

### "Deploy failed: Quarto build error"

**Symptoms:**
- Error during `quarto render`
- Deploy stops at "Building site..."
- YAML parsing errors or missing dependencies

**Causes:**

**1. Validation first**

```bash
# ALWAYS validate before deploy
teach validate --deep
teach validate --render
```

**2. Common Quarto YAML errors**

| Error                                   | Cause            | Fix                                 |
|-----------------------------------------|------------------|-------------------------------------|
| `unexpected key 'format'`               | Indentation      | Use 2 spaces, not tabs              |
| `expecting a single document`           | Multiple `---`   | Remove extra YAML delimiters        |
| `could not find shortcode handler`      | Missing ext      | `quarto add <extension>`            |
| `'lectures/week-01.qmd' not found`      | Broken ref       | Fix cross-reference path            |

**3. Missing dependencies**

```bash
# Check Quarto installation
quarto check

# Check R packages (if using)
teach doctor | grep "R package"

# Install missing packages
teach doctor --fix
```

**Fix:**

```bash
# 1. Run full validation
teach validate --deep --stats

# 2. Fix reported errors
$EDITOR lectures/week-05.qmd

# 3. Test render locally
quarto render lectures/week-05.qmd

# 4. Re-run deploy
teach deploy
```

**Verify:**

```bash
# Local preview
quarto preview

# Check build artifacts
ls _site/lectures/week-05.html
```

---

### "Site deployed but content missing"

**Symptoms:**
- GitHub Pages shows site but lectures/exams are blank
- Navigation links broken
- Index shows old content

**Causes:**

**1. Partial deploy vs full deploy**

```bash
# Partial deploy (updates specific files)
teach deploy lectures/week-05.qmd    # Only week-05 updated

# Full deploy (rebuilds entire site)
teach deploy                         # All content updated
```

**2. Index not updated**

```bash
# Check index files
git diff origin/gh-pages home_lectures.qmd home_exams.qmd

# If missing updates, re-deploy with index
teach deploy lectures/week-05.qmd --auto-commit
# Don't use --skip-index
```

**Fix:**

```bash
# 1. Full site rebuild
teach deploy

# 2. Force index regeneration
teach deploy --force-index

# 3. Verify index content
cat home_lectures.qmd | grep week-05
```

**Verify:**

```bash
# Check deployed site
gh pr view --web    # View PR
# After merge, check https://<user>.github.io/<repo>/

# Verify index links
curl -s https://<user>.github.io/<repo>/ | grep week-05
```

---

## Content Management Issues

### "teach plan create fails"

**Symptoms:**
- Error: `lesson-plans.yml format errors`
- Warning: `Week number conflicts`
- YAML parsing fails

**Causes:**

**1. Invalid YAML format**

```yaml
# ❌ WRONG - Missing quotes for colons in topic
week: 3
topic: Linear Models: Simple Regression

# ✓ CORRECT
week: 3
topic: "Linear Models: Simple Regression"
```

**2. Week number conflicts**

```bash
# Check existing weeks
teach plan list

# Error if week already exists
teach plan create 3 --topic "New Topic"
# Error: Week 3 already exists

# Fix: Edit existing or delete first
teach plan edit 3
# or
teach plan delete 3 --force
```

**Fix:**

```bash
# 1. Validate lesson plans file
yq eval '.weeks' .flow/lesson-plans.yml

# 2. Fix YAML errors
$EDITOR .flow/lesson-plans.yml

# 3. Verify structure
teach plan list --json | jq .

# 4. Create plan
teach plan create 5 --topic "ANOVA" --style rigorous
```

**Verify:**

```bash
teach plan show 5        # Display week 5 details
teach plan list          # Show all weeks with gaps
```

---

### "teach validate reports errors"

**Symptoms:**
- Long list of validation errors
- Markdown lint violations
- Cross-reference warnings

**Common QMD lint issues:**

| Error                                       | Cause                    | Fix                                |
|---------------------------------------------|--------------------------|------------------------------------|
| `MD001: Heading levels should increase`     | Skipped heading level    | h2 → h3, not h2 → h4               |
| `MD009: Trailing spaces`                    | Whitespace at line end   | Trim trailing spaces               |
| `MD022: Headings should be surrounded`      | No blank lines           | Add blank line before/after `##`   |
| `MD034: Bare URL used`                      | URL not in link syntax   | `[text](url)` or `<url>`           |

**How to read validation output:**

```bash
# Layer-by-layer validation
teach validate --deep

# Output structure:
# ═══════════════════════════════════════
# Layer 1: YAML Front Matter Validation
# ═══════════════════════════════════════
#   ✓ lectures/week-01.qmd: valid
#   ✗ lectures/week-02.qmd: missing 'date' field
#
# Layer 2: Markdown Syntax Check
# ═══════════════════════════════════════
#   ⚠ lectures/week-02.qmd:15: MD001 (heading-increment)
#   ⚠ lectures/week-02.qmd:42: MD009 (no-trailing-spaces)
```

**Auto-fix common issues:**

```bash
# Use markdownlint-cli for auto-fix
npm install -g markdownlint-cli

markdownlint --fix lectures/*.qmd

# Re-validate
teach validate --syntax
```

**Fix manually:**

```bash
# Jump to error line
$EDITOR +42 lectures/week-02.qmd

# Fix and re-check
teach validate lectures/week-02.qmd
```

**Verify:**

```bash
# Full validation
teach validate --deep --stats

# Should show:
# ✓ 15 files passed validation
# ✗ 0 files failed
```

---

### "teach templates new creates empty file"

**Symptoms:**
- Created file is 0 bytes
- Variables not substituted
- Template content missing

**Causes:**

**1. Template not found**

```bash
# Check available templates
teach templates list

# If empty, sync from plugin defaults
teach templates sync
```

**2. Variable substitution failures**

```bash
# Check teach-config.yml has required fields
teach config view | grep -E "name|semester|year"

# Required for variable substitution:
course:
  name: "STAT 440"
  semester: Fall
  year: 2025
```

**Fix:**

```bash
# 1. Sync templates
teach templates sync

# 2. Verify templates exist
teach templates list
# Should show: lecture, lab, assignment, slides

# 3. Create with variables
teach templates new lecture week-05 --topic "Regression"

# 4. Check output
ls -lh lectures/week-05-lecture.qmd
head -20 lectures/week-05-lecture.qmd
```

**Verify:**

```bash
# Variables should be substituted
grep -E "STAT 440|Fall 2025|Regression" lectures/week-05-lecture.qmd
```

---

## Git Integration Issues

### "teach deploy: uncommitted changes"

**Symptoms:**
- Error: `Uncommitted changes detected`
- Deploy blocked at pre-flight check
- Warning: `X uncommitted changes`

**Auto-stage behavior:**

```bash
# Partial deploy auto-commits changed files
teach deploy lectures/week-05.qmd --auto-commit

# Full deploy requires clean tree (unless configured otherwise)
teach deploy    # Blocks if dirty
```

**How to commit before deploy:**

```bash
# Option 1: Manual commit
git add .
git commit -m "Update week 05 lecture"
teach deploy

# Option 2: Auto-commit
teach deploy --auto-commit

# Option 3: Disable clean requirement
teach config set git.require_clean false
```

**Verify:**

```bash
git status                  # Should be clean
teach doctor | grep "Working tree"
# Should show: ✓ Working tree clean
```

---

### "Git hooks blocking operations"

**Symptoms:**
- Pre-commit hook fails
- Error: `Hook execution failed`
- Deploy interrupted by hook

**Check hook status:**

```bash
# List installed hooks
teach doctor | grep -A 5 "Git Hooks"

# View hook content
cat .git/hooks/pre-commit

# Check if flow-cli managed
grep "auto-generated by teach hooks install" .git/hooks/pre-commit
```

**Disabling problematic hooks:**

```bash
# Temporary disable (make non-executable)
chmod -x .git/hooks/pre-commit

# Deploy
teach deploy

# Re-enable
chmod +x .git/hooks/pre-commit

# Permanent removal
rm .git/hooks/pre-commit
```

**Reinstall hooks:**

```bash
# Remove all hooks
teach hooks uninstall

# Reinstall with defaults
teach hooks install

# Verify
teach doctor | grep "Hook installed"
```

**Verify:**

```bash
# Test hook execution
git commit --allow-empty -m "Test hooks"

# Should succeed without errors
```

---

## Performance Issues

### "teach analyze is slow"

**Symptoms:**
- `teach analyze` takes >5 minutes
- High CPU usage
- Analyzing every QMD file repeatedly

**Causes:**

**1. Cache not being used**

```bash
# Check cache status
teach doctor | grep -A 3 "Cache Health"

# Should show:
#   ✓ Freeze cache exists (2.3MB)
#   ✓ Cache is fresh (rendered today)

# If stale or missing:
#   ⚠ Cache is stale (45 days old) → Run: quarto render
```

**2. Too many phases enabled**

```bash
# Default runs all 5 phases (slow)
teach analyze

# Run only needed phases
teach analyze --phases 0,1,2    # Structure + Content + Cross-refs only
```

**3. Large course with many files**

```bash
# Count files being analyzed
find . -name "*.qmd" | wc -l
# If > 50 files, consider selective analysis

teach analyze lectures/        # Analyze directory only
teach analyze --phases 0,1     # Skip expensive phases
```

**Cache usage:**

```bash
# Check cache directory
ls -lh .flow/cache/

# Clear stale cache
teach cache clear

# Rebuild cache
teach analyze --phases 0,1,2,3,4
```

**Phase selection for speed:**

| Phases  | Analysis                        | Time      | Cache  |
|---------|---------------------------------|-----------|--------|
| 0       | Structure only                  | < 10s     | ✓ Yes  |
| 0,1     | + Content analysis              | < 30s     | ✓ Yes  |
| 0,1,2   | + Cross-references              | < 1 min   | ✓ Yes  |
| 0,1,2,3 | + Concept extraction            | 1-3 min   | ✓ Yes  |
| ALL     | + Prerequisites + Readability   | 3-10 min  | ✓ Yes  |

**Verify:**

```bash
# Time analysis
time teach analyze --phases 0,1,2

# Should be < 1 minute for < 20 files
```

---

## Recovery Procedures

### Rollback a bad deployment

**Scenario:** Deployed broken content to production, need to revert.

**Steps:**

```bash
# 1. Check current production state
git checkout production
git log --oneline -5

# 2. Identify last good commit
git log --oneline --grep="Deploy"    # Find previous deploy

# 3. Create revert commit
git revert <bad-commit-sha>

# 4. Push revert
git push origin production

# 5. Update gh-pages (if needed)
git checkout gh-pages
git pull origin gh-pages
git revert <bad-commit-sha>
git push origin gh-pages

# 6. Return to draft
git checkout draft
```

**Verify:**

```bash
# Check production site
open https://<user>.github.io/<repo>/

# Verify content reverted
curl -s https://<user>.github.io/<repo>/lectures/week-05.html | grep -A 5 "title"
```

---

### Restore from backup

**Scenario:** Corrupted lesson plans or config, need to restore.

**Steps:**

```bash
# 1. List available backups
teach backup list
# Shows backups in: .flow/backups/

# 2. View backup content
cat .flow/backups/lesson-plans-2025-01-15.yml

# 3. Restore specific file
teach backup restore lesson-plans 2025-01-15

# Or manual restore:
cp .flow/backups/lesson-plans-2025-01-15.yml .flow/lesson-plans.yml

# 4. Validate restored file
teach plan list
teach validate --config
```

**Verify:**

```bash
# Check restoration
teach plan list        # Should show expected weeks
git diff .flow/lesson-plans.yml    # Review changes
```

---

### Reset teaching config

**Scenario:** Config completely broken, need fresh start without losing content.

**Steps:**

```bash
# 1. Backup current config
cp .flow/teach-config.yml .flow/teach-config.yml.broken

# 2. Backup existing content
cp .flow/lesson-plans.yml .flow/lesson-plans.yml.backup

# 3. Reinitialize config
teach init --force

# 4. Restore custom settings (selectively)
# Edit new config, copy over valid sections from .broken file
$EDITOR .flow/teach-config.yml

# 5. Restore lesson plans
cp .flow/lesson-plans.yml.backup .flow/lesson-plans.yml

# 6. Validate
teach doctor
teach validate --config
```

**Verify:**

```bash
# Config should validate
teach doctor | grep "Config: valid"

# Content should be intact
teach plan list
ls lectures/ labs/ exams/
```

---

## Getting Help

### Verbose debug output

```bash
# Enable verbose mode for any command
teach doctor --verbose
teach analyze --verbose
teach deploy --verbose

# Output includes:
# - Cache hit/miss status
# - File processing timestamps
# - Scholar API calls
# - Git operations
```

### Collect diagnostics

```bash
# Generate diagnostic report
teach doctor --json > diagnostics.json

# Share for troubleshooting
cat diagnostics.json | jq .
```

### Documentation resources

```bash
# Built-in help
teach help
teach doctor --help
teach deploy --help

# Online documentation
open https://Data-Wise.github.io/flow-cli/

# Quick reference cards
cat docs/reference/REFCARD-TEACH-PLAN.md
cat docs/reference/REFCARD-TEMPLATES.md
```

### GitHub issues

If problems persist after trying these solutions:

1. **Check existing issues:** https://github.com/Data-Wise/flow-cli/issues
2. **Search discussions:** https://github.com/Data-Wise/flow-cli/discussions
3. **Create new issue with:**
   - Output from `teach doctor --json`
   - Steps to reproduce
   - Expected vs actual behavior
   - Flow-cli version: `flow --version`

---

## See Also

- [Getting Started Troubleshooting](../getting-started/troubleshooting.md) - General flow-cli issues
- [TEACH DOCTOR Reference](../reference/REFCARD-DOCTOR.md) - Complete health check guide
- [Teaching Workflow v3 Guide](TEACHING-WORKFLOW-V3-GUIDE.md) - Deep dive into validation system
- [Deployment Guide](TEACH-DEPLOY-GUIDE.md) - Advanced deployment workflows
- [Configuration Schema](../reference/TEACH-CONFIG-SCHEMA.md) - Complete config reference

---

**Last Updated:** 2026-02-02
**Flow CLI Version:** v6.1.0+
