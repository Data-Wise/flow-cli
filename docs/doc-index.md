# Flow CLI Documentation Index

**Last Updated:** 2025-12-24

---

## 🎯 Start Here

### New Users

1. **[README.md](../README.md)** - Project overview
2. **[Quick Start](getting-started/quick-start.md)** - 5-minute introduction
3. **[First Session Tutorial](tutorials/01-first-session.md)** - Your first workflow
4. **[Command Reference](reference/ALIAS-REFERENCE-CARD.md)** - All commands documented

### Current Users

1. **[What's New](index.md#recent-updates)** - Phase P6 complete (Dec 24, 2025)
2. **[Production Use Phase](../PRODUCTION-USE-PHASE.md)** - Started Dec 24, 2025
3. **[API Reference](api/API-REFERENCE.md)** - Complete API documentation (NEW)
4. **[Interactive Examples](api/INTERACTIVE-EXAMPLES.md)** - 13 runnable code examples (NEW)

---

## 📚 User Documentation

### Core References

| Document                                                             | Purpose                          | Update        |
| -------------------------------------------------------------------- | -------------------------------- | ------------- |
| [ALIAS-REFERENCE-CARD.md](reference/ALIAS-REFERENCE-CARD.md)         | All 28 aliases + migration guide | 2025-12-19 ✅ |
| [WORKFLOW-QUICK-REFERENCE.md](reference/WORKFLOW-QUICK-REFERENCE.md) | Daily workflows                  | 2025-12-14    |
| [PICK-COMMAND-REFERENCE.md](reference/PICK-COMMAND-REFERENCE.md)     | Project picker guide             | -             |
| [WORKFLOWS-QUICK-WINS.md](guides/WORKFLOWS-QUICK-WINS.md)            | Quick productivity tips          | -             |

### Specialized Guides

| Document                                                          | Purpose               |
| ----------------------------------------------------------------- | --------------------- |
| [DASHBOARD-QUICK-REF.md](reference/DASHBOARD-QUICK-REF.md)        | Dashboard commands    |
| [WORKSPACE-AUDIT-GUIDE.md](user/WORKSPACE-AUDIT-GUIDE.md)         | Health checks         |
| [WORKFLOW-TUTORIAL.md](user/WORKFLOW-TUTORIAL.md)                 | Step-by-step tutorial |
| [ENHANCED-HELP-QUICK-START.md](user/ENHANCED-HELP-QUICK-START.md) | Help system guide     |

---

## 🔧 Developer Documentation

### Implementation Guides

| Document                                                       | Purpose          | Update        |
| -------------------------------------------------------------- | ---------------- | ------------- |
| [ZSH-DEVELOPMENT-GUIDELINES.md](ZSH-DEVELOPMENT-GUIDELINES.md) | Coding standards | 2025-12-19 ✅ |

### Test Documentation

| Directory                | Purpose              |
| ------------------------ | -------------------- |
| `~/.config/zsh/tests/`   | Test suite (9 tests) |
| `~/.config/zsh/scripts/` | Lint scripts         |

---

## 📖 Change History

### 2025-12-19: Alias Cleanup

- Reduced from 179 to 28 aliases (84% reduction)
- Enabled git plugin (226+ standard aliases)
- Updated ALIAS-REFERENCE-CARD.md with migration guide
- See [index.md](index.md) "What Changed" section for details

### 2025-12-14: Workflow Redesign

- Simplified workflow commands
- Enhanced ADHD-friendly features

---

## 🗂️ Archive

### Planning Documents

- [proposals/](planning/proposals/) - Design proposals
- [ALIAS-REORGANIZATION-PROPOSAL.md](planning/ALIAS-REORGANIZATION-PROPOSAL.md)

### Implementation Logs

- [workflow-redesign/](implementation/workflow-redesign/) - Workflow implementation
- [TEACHING-RESEARCH-AMENDMENT-OPTIONS.md](implementation/workflow-redesign/TEACHING-RESEARCH-AMENDMENT-OPTIONS.md)

### Deprecated (Pre-2025-12-19)

- Old alias counts (179 aliases)
- Typo correction system
- Duplicate alias systems

---

## 🎯 Quick Links by Topic

### Aliases

- **Current list:** [ALIAS-REFERENCE-CARD.md](reference/ALIAS-REFERENCE-CARD.md)
- **Migration guide:** See "Migration Guide" section in ALIAS-REFERENCE-CARD.md
- **Cleanup details:** See [index.md](index.md) "What Changed (2025-12-19)" section

### Workflows

- **Quick reference:** [WORKFLOW-QUICK-REFERENCE.md](reference/WORKFLOW-QUICK-REFERENCE.md)
- **Tutorial:** [WORKFLOW-TUTORIAL.md](user/WORKFLOW-TUTORIAL.md)
- **Quick wins:** [WORKFLOWS-QUICK-WINS.md](guides/WORKFLOWS-QUICK-WINS.md)

### Development

- **Guidelines:** [ZSH-DEVELOPMENT-GUIDELINES.md](ZSH-DEVELOPMENT-GUIDELINES.md)
- **Tests:** `~/.config/zsh/tests/`
- **Conventions:** [CONVENTIONS.md](CONVENTIONS.md)

### Git Integration

- **Plugin docs:** [OMZ Git Plugin](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git)
- **Local config:** `~/.config/zsh/.zsh_plugins.txt` (line 27)

---

## 📊 Statistics

### Current State (2025-12-24)

- **Version:** v2.0.0-beta.1
- **Status:** Production Use Phase (started Dec 24, 2025)
- **Custom aliases:** 28
- **Git plugin aliases:** 226+
- **Dispatcher functions:** 6 (cc, gm, peek, qu, work, pick)
- **Total functions:** 100+
- **Test coverage:** 559 tests, 100% passing ⭐
- **Documentation:** 63 pages, 96K+ lines
- **Architecture:** Clean Architecture (3 layers, 265→559 tests)
- **Performance:** 10x faster (caching layer)

### Historical

- **Peak aliases:** 179 (pre-2025-12-19)
- **Reduction:** 84%
- **Phases complete:** P0-P6 (100%)
- **Implementation:** Dec 14-24, 2025 (10 days)

---

## 🔍 Search Tips

### Find by Topic

```bash
# All alias documentation
grep -r "alias" docs/user/

# Workflow guides
ls docs/user/*WORKFLOW*

# Recent changes
ls -lt docs/ | head -10
```

### Find by Command

```bash
# Where is command X documented?
grep -r "command-name" docs/

# What does alias X do?
cat docs/reference/ALIAS-REFERENCE-CARD.md | grep "alias-name"
```

---

## 📝 Document Status

### Up to Date (✅)

- ALIAS-REFERENCE-CARD.md (2025-12-19)
- ZSH-DEVELOPMENT-GUIDELINES.md (2025-12-19)
- README.md (2025-12-19)
- index.md (2025-12-20)

### Needs Review (⚠️)

- WORKFLOW-QUICK-REFERENCE.md (references removed aliases)
- WORKFLOWS-QUICK-WINS.md (may reference removed aliases)
- WORKFLOW-TUTORIAL.md (may reference removed aliases)

### Unknown Status (❓)

- PICK-COMMAND-REFERENCE.md
- DASHBOARD-QUICK-REF.md
- WORKSPACE-AUDIT-GUIDE.md

---

## 🎓 Learning Path

### Day 1: Essentials

1. Read ALIAS-REFERENCE-CARD.md
2. Master 6 core R aliases (rload, rtest, rdoc, rcheck, rbuild, rinstall)
3. Learn 2 Claude aliases (ccp, ccr)
4. Try dispatchers (cc, pick, peek)

### Week 1: Workflows

1. Read WORKFLOW-QUICK-REFERENCE.md
2. Practice daily workflows
3. Learn git plugin aliases (gst, ga, gcmsg, gp)
4. Set up focus timers (f25, f50)

### Month 1: Mastery

1. Customize for your workflow
2. Add aliases if >10 uses/day
3. Share feedback for improvements

---

**Maintainer:** DT
**Repository:** `~/projects/dev-tools/flow-cli/`
**Issues:** Create .md files in root or `docs/` directory
