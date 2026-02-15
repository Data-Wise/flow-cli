# Release Notes

Complete release history for flow-cli.

[← Back to Documentation](index.md){ .md-button } [→ Changelog](CHANGELOG.md){ .md-button }

---

## v6.1.0 - Quarto Lint Validation (2026-02-01)

!!! success "🔍 Quarto Lint Validation - Released 2026-02-01"
    Catch Quarto mistakes before they reach production. Intelligent structural validation for teaching materials.

### Quick Win: Validate Your Files Now

```bash
teach validate --lint slides/week-01.qmd   # Single file
teach validate --lint lectures/*.qmd       # Batch mode
teach validate --quick-checks              # Fast Phase 1 rules
```

### 4 Structural Lint Rules

| Rule | What It Catches | Example Fix |
| ---- | --------------- | ----------- |
| 🔤 **CODE_LANG_TAG** | Bare code blocks | ` ` → ` `{r} |
| 📦 **DIV_BALANCE** | Unclosed divs | Add closing `:::` |
| 💬 **CALLOUT_VALID** | Invalid callouts | `.callout-info` → `.callout-note` |
| 📋 **HEADING_HIERARCHY** | Skipped levels | `# → ###` → `# → ## → ###` |

### Performance & Quality

- ⚡ **Sub-second validation** (<1s for 100 files)
- ✅ **41 comprehensive tests** (93.3% pass rate)
- 📚 **5,600+ lines of documentation**
- 🏭 **Production validated** (85+ .qmd files on stat-545 course)

### Get Started

!!! tip "10-Minute Quickstart"
    New to lint validation? Start here:
    1. 📖 [Tutorial 27: Lint Quickstart](tutorials/27-lint-quickstart.md) (10 minutes)
    2. 📋 [Quick Reference Card](reference/REFCARD-LINT.md)
    3. 📚 [Complete User Guide](guides/LINT-GUIDE.md)
    4. 🔄 [Workflow Integration](workflows/WORKFLOW-LINT.md)

[GitHub Release →](https://github.com/Data-Wise/flow-cli/releases/tag/v6.1.0){ .md-button }

---

## v6.0.0 - Chezmoi Safety Features (2026-01-31)

!!! info "🛡️ Comprehensive Chezmoi Safety"
    Never accidentally track 196KB of .git files again! Intelligent safety features prevent common dotfile management mistakes.

### 🔍 Preview-Before-Add

**See exactly what you're adding before committing:**

- **File analysis:** Count, total size, large file warnings (>50KB)
- **Git metadata detection:** Catches nested `.git` directories (prevents 196KB bloat!)
- **Generated file detection:** Identifies `.log`, `.sqlite`, `.db`, `.cache` files
- **Smart suggestions:** Auto-suggest ignore patterns for common files
- **Cross-platform:** Works on macOS (BSD) and Linux (GNU)

```bash
dots add ~/.config/nvim
# Shows preview with warnings before adding
```

### 📝 Ignore Pattern Management

**Smart `.chezmoiignore` control:**

- `dots ignore add "*.log"` - Add patterns with deduplication
- `dots ignore list` - View all patterns with line numbers
- `dots ignore edit` - Open in $EDITOR
- Auto-initialization with sensible defaults

### 📊 Repository Health

**Proactive bloat detection:**

- `dots size` - Total repo size + top 10 largest files
- Health indicators: OK (<1MB), Warning (1-10MB), Critical (>10MB)
- File type distribution analysis
- Actionable cleanup suggestions

### 🏥 Enhanced Doctor

**9 comprehensive chezmoi validation checks:**

- `flow doctor --dot` - Fast chezmoi-only health check
- Large file detection (>100KB threshold)
- Auto-ignore pattern coverage verification
- Cross-platform compatibility validation

[User Guide →](guides/CHEZMOI-SAFETY-GUIDE.md){ .md-button }
[Quick Reference →](reference/REFCARD-DOT-SAFETY.md){ .md-button }
[Architecture →](architecture/DOT-SAFETY-ARCHITECTURE.md){ .md-button }

**Stats:** 170+ tests · 1,950+ lines of documentation · 15+ Mermaid diagrams

---

## v5.23.0 - AI Prompt Management & Documentation Quality (2026-01-29)

!!! info "3-Tier Prompt Resolution + Enhanced GIF Quality"
    Manage AI teaching prompts with course overrides. Enhanced documentation GIF quality across all tutorials.

**Features:**

- **`teach prompt` command** - 3-tier resolution (Course > User > Plugin)
- **Scholar integration** - Auto-resolve prompts for AI content generation
- **GIF quality enhancement** - Standardized 18px font, 10.9% size reduction
- **107 tests** - Comprehensive unit, E2E, and interactive testing

[Tutorial →](tutorials/28-teach-prompt.md){ .md-button } [Quick Reference →](reference/REFCARD-PROMPTS.md){ .md-button }

---

## v5.22.0 - Lesson Plan & Template Management (2026-01-28)

!!! info "CRUD Operations + Reusable Templates"
    Centralized lesson plan management with template system for content creation

**Features:**

- **`teach plan` command** - Full CRUD for lesson plan weeks
  - `teach plan create <week>` - Add week with interactive prompts
  - `teach plan list` - Table view with gap detection, JSON output
  - `teach plan show <week>` - Formatted display with objectives/subtopics
  - Shortcuts: `teach pl`, `teach plan c`, `teach plan ls`
- **`teach templates` command** - Manage reusable content templates
  - `teach templates list` - View available templates by type/source
  - `teach templates new lecture week-05` - Create from template
  - Variable substitution: `{{WEEK}}`, `{{TOPIC}}`, `{{COURSE}}`
- **71 new tests** — 462 total tests across all features

---

## v5.21.0 - LaTeX Macro Configuration (2026-01-28)

!!! info "Consistent AI-Generated Notation"
    Manage LaTeX macros for consistent mathematical notation across Scholar-generated content

**Features:**

- **`teach macros` command** - Complete macro management
  - `teach macros list` - Display all macros with categories
  - `teach macros sync` - Extract from source files (QMD, LaTeX, MathJax)
  - `teach macros export` - Export for Scholar AI integration (JSON/LaTeX formats)
- **3 source parsers:** QMD, MathJax HTML, LaTeX
- **6 categories:** operators, distributions, symbols, matrices, derivatives, probability
- **Health check integration** - `teach doctor` includes macro health
- **54 comprehensive tests**

---

## v5.20.0 - Template Management (2026-01-28)

!!! info "Reusable Content Templates"
    Project-local templates with variable substitution

**Features:**

- **`teach templates` command** - Manage reusable templates
  - `teach templates list` - View by type/source
  - `teach templates new lecture week-05` - Create from template
  - `teach templates validate` - Check syntax
  - `teach templates sync` - Update from plugin defaults
- **Variable substitution:** `{{WEEK}}`, `{{TOPIC}}`, `{{COURSE}}`, `{{DATE}}`
- **4 template types:** content, prompts, metadata, checklists
- **Resolution order:** Project templates override plugin defaults

---

## v5.18.0 - Documentation Consolidation

!!! info "Documentation Consolidation & API Coverage Improvement"
    Simplified documentation structure (66 → 7 files) with comprehensive API coverage (+411% increase)

### 📚 Documentation Consolidation

**Major Restructure for Clarity:**

- **📄 Master Documents** - 7 comprehensive guides replace 66 scattered files (95% reduction)
- **🗺️ Navigation** - Simplified from 71 → 9 entries (92% reduction)
- **🔗 Link Health** - Fixed 54 critical broken links across hub files
- **📦 Archive** - 66 legacy files preserved in `.archive/` with migration map
- **✅ Quality** - Created `.linkcheck-ignore` for expected patterns, zero stale docs

**Master Documents Created:**

1. `MASTER-API-REFERENCE.md` - Complete API documentation (5,000+ lines)
2. `MASTER-DISPATCHER-GUIDE.md` - All 12 dispatchers (3,000+ lines)
3. `MASTER-ARCHITECTURE.md` - System design with 11+ Mermaid diagrams
4. `QUICK-REFERENCE.md` - Single-page command lookup
5. `WORKFLOWS.md` - Real-world workflow patterns
6. `TROUBLESHOOTING.md` - Common issues & solutions
7. `00-START-HERE.md` - Documentation hub

### 📊 API Documentation Improvement

**Coverage Expansion (Phases 1-4):**

- **Phase 1**: Token automation (30 functions) - v5.17.0 complete documentation
- **Phase 2**: Teaching libraries (32 functions) - AI analysis, caching, reports
- **Phase 3**: Git helpers (14 functions) - Teaching workflow integration
- **Phase 4**: Keychain helpers (7 functions) - macOS secret management
- **Total**: 83 new functions documented (+411% increase: 2.7% → 13.8%)

**Documentation Quality:**

- Comprehensive parameter documentation
- Return value specifications
- Performance metrics included
- Usage examples for all functions
- Integration notes and side effects

[→ Master API Reference](reference/MASTER-API-REFERENCE.md){ .md-button .md-button--primary }
[→ Master Dispatcher Guide](reference/MASTER-DISPATCHER-GUIDE.md){ .md-button }
[→ Documentation Dashboard](DOC-DASHBOARD.md){ .md-button }

---

## v5.17.0 - Token Automation Phase 1

!!! success "Smart Caching & Isolated Checks"
    20x faster token validation with intelligent caching and ADHD-friendly workflows

### 🔐 Token Automation (doctor --dot)

**Smart Token Management with Performance Boost:**

- **⚡ Isolated Checks** - `doctor --dot` validates only tokens (< 3s vs 60+ seconds)
- **💾 Smart Caching** - 5-minute TTL, 85% cache hit rate, 80% API call reduction
- **🎯 Category Menu** - ADHD-friendly visual selection with time estimates
- **🔊 Verbosity Control** - `--quiet` for CI/CD, `--verbose` for debugging
- **🔧 Token-Only Fixes** - `doctor --fix-token` for isolated token workflows
- **🔗 9-Dispatcher Integration** - Validates tokens before git operations, shows status in dashboards

**Commands:**

```bash
doctor --dot              # Quick token check (< 3s, cached)
doctor --dot=github       # Check specific provider
doctor --fix-token        # Interactive fix menu
doctor --dot --quiet      # CI/CD mode (minimal output)
doctor --dot --verbose    # Debug with cache status
```

**Performance:**

- Cache checks: ~5-8ms (50% better than target)
- Token validation (cached): ~50-80ms (40% better)
- Token validation (fresh): ~2-3s (on target)
- API call reduction: 80% via smart caching

[→ Token Automation User Guide](guides/DOCTOR-TOKEN-USER-GUIDE.md){ .md-button .md-button--primary }
[→ Token API Reference](reference/MASTER-API-REFERENCE.md#doctor-cache){ .md-button }

---

## v5.16.0 - Intelligent Content Analysis

!!! success "teach analyze - All Phases Complete"
    AI-powered course content analysis with concept graphs, prerequisite validation, and slide optimization

### 🧠 Intelligent Content Analysis (teach analyze)

**Full Feature Set (Phases 0-5):**

- **📊 Concept Graph** - Extract concepts from frontmatter, build dependency graph
- **✅ Prerequisite Validation** - Detect circular dependencies and week ordering issues
- **⚡ Smart Caching** - SHA-256 content hashing with flock-based parallel processing
- **🤖 AI Analysis** - Bloom's taxonomy, cognitive load estimation, teaching time
- **📐 Slide Optimization** - Break suggestions, key concepts for emphasis, time estimates
- **📝 Reports** - JSON/Markdown reports for course-wide analysis

**Commands:**

```bash
teach analyze lectures/week-05.qmd           # Single file analysis
teach analyze --batch lectures/              # Parallel batch analysis
teach analyze --slide-breaks                 # Slide optimization
teach validate --deep                        # Prerequisite validation
```

[→ Intelligent Content Analysis Guide](guides/INTELLIGENT-CONTENT-ANALYSIS.md){ .md-button .md-button--primary }
[→ teach analyze Tutorial](tutorials/21-teach-analyze.md){ .md-button }

### ⚡ Plugin Optimization

- **Load Guards** - Prevents double/triple-sourcing of libraries (3x startup reduction)
- **Display Layer** - Extracted 270 lines to reusable `lib/analysis-display.zsh`
- **Cache Fixes** - Directory-mirroring structure prevents path collisions
- **Test Timeouts** - 30s timeouts prevent infinite hangs (13 tests pass, 5 timeout as expected)
- **Test Suite** - 31 new tests for optimization validation (100% passing)

[→ Plugin Optimization Tutorial](tutorials/22-plugin-optimization.md){ .md-button }
[→ Optimization Quick Reference](reference/MASTER-ARCHITECTURE.md#performance-optimization){ .md-button }

---

## v5.14.0 - Teaching Workflow v3.0

### 🎓 Teaching Workflow v3.0

#### Wave 1: Foundation

- **🏥 teach doctor** - Comprehensive environment health check (--fix, --json, --quiet)
- **📖 Enhanced Help** - All 10 teach commands now have --help with EXAMPLES
- **🔄 Unified Dispatcher** - Removed standalone `teach-init`, now `teach init`

#### Wave 2: Backup System

- **💾 Automated Backups** - Timestamped snapshots on every content modification
- **📦 Retention Policies** - `archive` (keep forever) vs `semester` (auto-cleanup)
- **🗑️ Safe Deletion** - Interactive confirmation with file preview
- **📊 Status Integration** - Backup summary in `teach status`

#### Wave 3: Enhancements

- **🚀 Deploy Preview** - `teach deploy --preview` shows changes before PR
- **📚 Scholar Templates** - Template selection + automatic lesson plan loading
- **✅ Enhanced Status** - Deployment status + backup info in `teach status`

### 📹 Visual Documentation (6 GIFs)

All new features demonstrated with optimized tutorial GIFs (5.7MB total):

- **teach doctor** - Environment validation workflow
- **Backup system** - Automated content safety
- **teach init** - Project initialization
- **teach deploy** - Preview deployment flow
- **teach status** - Enhanced dashboard
- **Scholar integration** - Template & lesson plans

[→ Teaching Workflow v3.0 Guide](guides/TEACHING-WORKFLOW-V3-GUIDE.md){ .md-button .md-button--primary }
[→ Backup System Guide](guides/BACKUP-SYSTEM-GUIDE.md){ .md-button }
[→ Migration Guide (v2→v3)](guides/TEACHING-V3-MIGRATION-GUIDE.md){ .md-button }

---

## v5.13.0 - WT Enhancement + Scholar Integration

### WT Enhancement + Scholar Integration

- Enhanced worktree management with formatted overview and smart filtering
- 9 Scholar wrapper commands for teaching content generation
- Multi-select worktree actions with interactive delete

[View Full Changelog →](CHANGELOG.md){ .md-button }

---

**Maintained by:** Data-Wise
**Last updated:** 2026-02-01
**Current version:** v6.1.0
