# Shell Configuration Management Brainstorm

**Date:** 2025-12-17
**Context:** Following alias reorganization session
**Goal:** Document philosophy, create rules, implement testing

---

## Part 1: Research Summary

### Best Practices from Industry (2024-2025)

Based on research from [Scott Spence](https://scottspence.com/posts/my-updated-zsh-config-2025), [Christopher Allen's Zsh Guide](https://gist.github.com/ChristopherA/562c2e62d01cf60458c5fa87df046fbd), and [Cursor Rules Guide](https://cursorrules.org/article/zsh-cursor-mdc-file):

#### Directory Structure
```
~/.config/zsh/
├── .zshrc              # Main entry point (loader)
├── aliases/            # Domain-specific alias files
├── functions/          # Dispatcher functions
├── completions/        # Custom completions
├── lib/                # Shared utilities
├── conf/               # Configuration settings
└── tests/              # Validation tests
```

#### Key Principles
1. **Modular Organization** - Split code into logical modules
2. **Performance First** - Lazy loading, minimal plugins
3. **Portable & Adaptive** - Works across machines
4. **Self-Documenting** - Built-in help systems
5. **Testable** - Automated validation

### Testing Tools

From [ShellCheck](https://www.shellcheck.net/) and [CICDToolbox](https://github.com/CICDToolbox/shellcheck):

- **ShellCheck** - Static analysis for shell scripts
- **CI/CD Integration** - Automated linting on push
- **.shellcheckrc** - Per-project configuration
- **Docker testing** - Clean environment validation

---

## Part 2: Current Architecture Analysis

### What We Built Today

#### Dispatcher Pattern (`command + keyword + options`)
```
r test              # R package
g status            # Git
qu preview          # Quarto
v dash              # Workflow
cc                  # Claude
gm                  # Gemini
```

#### File Organization
```
~/.config/zsh/
├── .zshrc                              # Main config (~1150 lines)
└── functions/
    ├── smart-dispatchers.zsh           # r, qu, cc, gm dispatchers
    ├── v-dispatcher.zsh                # v/vibe dispatcher
    ├── g-dispatcher.zsh                # g (git) dispatcher [NEW]
    ├── adhd-helpers.zsh                # work, dash, pb, pv, pt
    ├── work.zsh                        # Work session management
    ├── dash.zsh                        # Dashboard
    ├── status.zsh                      # Status functions
    ├── fzf-helpers.zsh                 # FZF integrations
    └── ...                             # Other helpers
```

#### Strengths
- Consistent dispatcher pattern
- Self-documenting (`<cmd> help`)
- ADHD-friendly (discoverable)
- Passthrough for unknown commands

#### Weaknesses
- .zshrc is still monolithic (~1150 lines)
- No automated testing
- Some dead code (REMOVED comments)
- Aliases still scattered in .zshrc

---

## Part 3: Brainstorm Ideas

### Category 1: Documentation

| Idea | ADHD Score | Effort | Priority |
|------|------------|--------|----------|
| ⭐ **PHILOSOPHY.md** - Core principles document | ⭐⭐⭐⭐⭐ | Low | High |
| ⭐ **CONVENTIONS.md** - Naming/structure rules | ⭐⭐⭐⭐⭐ | Low | High |
| **ARCHITECTURE.md** - Technical deep-dive | ⭐⭐⭐ | Medium | Medium |
| **CHANGELOG.md** - Track all changes | ⭐⭐⭐⭐ | Low | Medium |
| **README.md** - Quick start guide | ⭐⭐⭐⭐⭐ | Low | High |
| **Inline comments** - In each file | ⭐⭐⭐ | Medium | Medium |

### Category 2: Testing & Validation

| Idea | ADHD Score | Effort | Priority |
|------|------------|--------|----------|
| ⭐ **ShellCheck integration** | ⭐⭐⭐⭐ | Low | High |
| ⭐ **Dispatcher test suite** | ⭐⭐⭐⭐⭐ | Medium | High |
| **Duplicate alias checker** | ⭐⭐⭐⭐⭐ | Low | High |
| **Load time benchmark** | ⭐⭐⭐⭐ | Low | Medium |
| **CI/CD on push** | ⭐⭐⭐ | Medium | Low |
| **Docker clean test** | ⭐⭐ | High | Low |

### Category 3: Refactoring

| Idea | ADHD Score | Effort | Priority |
|------|------------|--------|----------|
| ⭐ **Split .zshrc into modules** | ⭐⭐⭐⭐ | High | Medium |
| **Move aliases to separate files** | ⭐⭐⭐⭐ | Medium | Medium |
| **Remove dead code** | ⭐⭐⭐⭐⭐ | Low | High |
| **Consolidate R aliases** | ⭐⭐⭐⭐ | Low | Medium |
| **Create alias→dispatcher migration** | ⭐⭐⭐ | Medium | Low |

### Category 4: Tooling

| Idea | ADHD Score | Effort | Priority |
|------|------------|--------|----------|
| ⭐ **`zsh-lint` command** | ⭐⭐⭐⭐⭐ | Medium | High |
| **`zsh-doctor` health check** | ⭐⭐⭐⭐⭐ | Medium | Medium |
| **`zsh-help` unified help** | ⭐⭐⭐⭐ | Medium | Medium |
| **Auto-generate cheatsheet** | ⭐⭐⭐⭐ | Medium | Medium |
| **Profile startup time** | ⭐⭐⭐ | Low | Low |

### Category 5: Knowledge Management

| Idea | ADHD Score | Effort | Priority |
|------|------------|--------|----------|
| ⭐ **Session summaries** (auto-generated) | ⭐⭐⭐⭐⭐ | Medium | High |
| **Decision log** | ⭐⭐⭐⭐ | Low | Medium |
| **Integration with Obsidian** | ⭐⭐⭐ | High | Low |
| **Searchable command database** | ⭐⭐⭐ | Medium | Medium |

---

## Part 4: The Philosophy

### Core Principles (Proposed)

```markdown
# ZSH Configuration Philosophy

## 1. Dispatcher Pattern
- One command per domain: `r`, `g`, `qu`, `v`, `cc`, `gm`
- Pattern: `command + keyword + options`
- Built-in help: `<cmd> help`
- Passthrough for unknown: `g cherry-pick` → `git cherry-pick`

## 2. ADHD-Friendly Design
- Discoverable: Help always available
- Consistent: Same pattern everywhere
- Memorable: Short, mnemonic commands
- Forgiving: Typo tolerance aliases

## 3. Modular Architecture
- Each domain has its own file
- Functions > Aliases (for complex logic)
- Aliases for simple shortcuts only
- No duplicates across files

## 4. Performance
- Lazy loading where possible
- Minimal plugins (antidote)
- No blocking operations at startup
- Target: <200ms shell startup

## 5. Maintainability
- Self-documenting code
- Clear file organization
- Automated testing
- Version controlled

## 6. Portability
- Works on macOS (primary)
- Graceful degradation if tools missing
- No hardcoded paths
```

---

## Part 5: Proposed Rules

### Naming Conventions

```markdown
# RULE: Dispatcher Naming
- Single letter for high-frequency: r, g, v
- Two letters for medium-frequency: qu, cc, gm
- Full word for low-frequency: work, dash, pick

# RULE: Keyword Naming
- Use verbs: test, check, build, push, pull
- Use nouns for info: status, log, branch
- Keep short: 3-8 characters
- Use common abbreviations: cov (coverage), doc (document)

# RULE: File Naming
- Dispatchers: `<letter>-dispatcher.zsh`
- Helpers: `<domain>-helpers.zsh`
- Utilities: `<purpose>.zsh`
- Tests: `test-<name>.zsh`
```

### Structural Rules

```markdown
# RULE: No Duplicate Definitions
- Each alias/function defined in exactly ONE file
- Use grep to check before adding

# RULE: Dispatcher Structure
function <cmd>() {
    if [[ $# -eq 0 ]]; then
        # Default action or help
    fi

    case "$1" in
        action1) ... ;;
        action2) ... ;;
        help|h)  _<cmd>_help ;;
        *)       passthrough or error ;;
    esac
}

# RULE: Help Function
- Every dispatcher MUST have _<cmd>_help()
- Show most common commands first
- Include examples
- Use colors consistently

# RULE: Comments
- File header with purpose and date
- Section headers for grouping
- Inline comments for non-obvious logic
```

---

## Part 6: Test Suite Design

### Test Categories

#### 1. Syntax Validation
```bash
# test-syntax.zsh
# Run ShellCheck on all .zsh files

for f in ~/.config/zsh/**/*.zsh; do
    shellcheck -s bash "$f" || echo "FAIL: $f"
done
```

#### 2. Duplicate Detection
```bash
# test-duplicates.zsh
# Check for duplicate alias/function names

grep -rh "^alias \|^function \|^[a-z_]*() {" ~/.config/zsh/ | \
    sed 's/=.*//' | sort | uniq -d
```

#### 3. Dispatcher Tests
```bash
# test-dispatchers.zsh
# Verify each dispatcher works

test_dispatcher() {
    local cmd=$1

    # Test help exists
    $cmd help &>/dev/null || echo "FAIL: $cmd help"

    # Test no-args behavior
    $cmd &>/dev/null || echo "FAIL: $cmd (no args)"
}

test_dispatcher r
test_dispatcher g
test_dispatcher qu
test_dispatcher v
```

#### 4. Load Time Test
```bash
# test-performance.zsh
# Measure shell startup time

time (for i in {1..10}; do zsh -ic exit; done)
# Target: <200ms average
```

#### 5. Integration Test
```bash
# test-integration.zsh
# Test common workflows

# Test: R package cycle
cd /tmp && mkdir test-pkg && cd test-pkg
r help | grep -q "R Package" || echo "FAIL: r help"

# Test: Git workflow
g help | grep -q "Git Commands" || echo "FAIL: g help"
```

---

## Part 7: Implementation Plan

### Phase 1: Quick Wins (Today)
1. ✅ Create PHILOSOPHY.md
2. ✅ Create CONVENTIONS.md
3. ✅ Create basic test-duplicates.zsh
4. ✅ Remove dead code from .zshrc

### Phase 2: Testing (This Week)
1. Set up ShellCheck
2. Create test-dispatchers.zsh
3. Create test-performance.zsh
4. Add pre-commit hook

### Phase 3: Refactoring (Next Week)
1. Split .zshrc into modules
2. Move remaining aliases to files
3. Create auto-generated cheatsheet
4. Create zsh-doctor command

### Phase 4: CI/CD (Future)
1. GitHub Actions for testing
2. Auto-lint on push
3. Version tagging

---

## Part 8: Decision Log

### 2025-12-17: Alias Reorganization

**Decision:** Adopt dispatcher pattern for all domains

**Rationale:**
- Consistent mental model
- Self-documenting
- Easier to maintain
- ADHD-friendly

**Changes Made:**
- Created `g` dispatcher for git
- Removed old `gst`, `gco`, `gp` aliases
- Removed old `qp`, `qr`, `qc` aliases
- Removed quota system entirely
- `qu` = Quarto (not quota)

**Trade-offs:**
- Some muscle memory adjustment needed
- Slightly more typing: `g push` vs `gp`
- Benefit: Discoverable, consistent, documented

---

## Part 9: Next Actions

### Immediate (Choose 1-2)
1. **Create PHILOSOPHY.md** - Document the principles
2. **Create test-duplicates.zsh** - Catch duplicate issues
3. **Clean dead code** - Remove REMOVED comments

### This Week
1. Set up ShellCheck integration
2. Create dispatcher test suite
3. Document architecture

### Backlog
1. Split .zshrc into modules
2. CI/CD pipeline
3. Auto-generated docs

---

## Sources

- [Scott Spence - My Updated ZSH Config 2025](https://scottspence.com/posts/my-updated-zsh-config-2025)
- [Zsh Best Practices - Christopher Allen](https://gist.github.com/ChristopherA/562c2e62d01cf60458c5fa87df046fbd)
- [Zsh Cursor Rules Guide](https://cursorrules.org/article/zsh-cursor-mdc-file)
- [ShellCheck - Shell Script Analysis](https://www.shellcheck.net/)
- [CICDToolbox/shellcheck](https://github.com/CICDToolbox/shellcheck)
- [Dotfile ShellCheck with Docker](https://bananamafia.dev/post/dotfile-shellcheck/)

---

*Generated: 2025-12-17*
