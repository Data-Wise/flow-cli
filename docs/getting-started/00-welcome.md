# Welcome to Flow CLI

**Choose your learning path based on your time and goals:**

---

## 🚀 5-Minute Quick Start

**Perfect if you:** Just want to try it out and see what it does.

**You'll learn:** How to install, run your first command, and see immediate results.

**Start here:** [Quick Start Guide](quick-start.md)

**What you'll do:**

1. Install flow-cli (source the plugin)
2. Run `dash` to see your project dashboard
3. Try `work <project>` to start a session
4. Use `win "text"` to log accomplishments

**Time investment:** 5 minutes
**Outcome:** Working installation + first successful command

---

## 📚 30-Minute Tutorial Path

**Perfect if you:** Want to learn the complete workflow from start to finish.

**You'll learn:** How to use flow-cli in your daily development workflow.

**Recommended sequence:**

### Tutorial 1: Your First Session (10 min)

→ [Tutorial: Your First Session](../tutorials/01-first-session.md)

**What you'll learn:**

- Create and manage work sessions
- Track time and context
- Understand flow state
- End sessions with outcome tracking

**Outcome:** Comfortable with session management

### Tutorial 2: Multiple Projects (10 min)

→ [Tutorial: Multiple Projects](../tutorials/02-multiple-projects.md)

**What you'll learn:**

- Use the project picker (`pick`)
- Filter by project type and status
- Track recent activity
- Use dispatchers for domain-specific workflows

**Outcome:** Efficiently switch between projects

### Tutorial 3: Status Visualizations (10 min)

→ [Tutorial: Status Visualizations](../tutorials/03-status-visualizations.md)

**What you'll learn:**

- Read dashboard visualizations
- Interpret productivity metrics (streaks, wins)
- Use interactive mode (`dash -i`)
- Understand .STATUS file format

**Outcome:** Master the dashboard features

**Time investment:** 30 minutes
**Outcome:** Complete workflow mastery

---

## 🔬 Deep Dive (1-2 hours)

**Perfect if you:** Want to master the system and contribute.

**You'll learn:** Dispatchers, customization, testing, and contribution.

**Learning path:**

### Phase 1: Advanced Features (30 min)

1. [Dispatcher Reference](../reference/DISPATCHER-REFERENCE.md) - All 8 dispatchers
2. [Command Reference](../reference/COMMAND-QUICK-REFERENCE.md) - Complete command list
3. [Workflow Quick Reference](../reference/WORKFLOW-QUICK-REFERENCE.md) - Common patterns

### Phase 2: Customization & Extension (30-60 min)

1. [Contributing Guide](../contributing/CONTRIBUTING.md) - How to contribute
2. [Testing Guide](../testing/TESTING.md) - 150+ ZSH tests
3. [CLAUDE.md](https://github.com/Data-Wise/flow-cli/blob/main/CLAUDE.md) - Project overview

**Time investment:** 1-2 hours
**Outcome:** Expert-level understanding + ability to customize/contribute

---

## 🎯 Goal-Based Paths

### "I Just Want to Track My Work"

1. Read: [Quick Start](quick-start.md) (5 min)
2. Do: [Tutorial 1: First Session](../tutorials/01-first-session.md) (10 min)
3. Use: `dash` and `win` daily

**Total time:** 15 minutes

### "I Work on Multiple Projects"

1. Read: [Quick Start](quick-start.md) (5 min)
2. Do: [Tutorial 2: Multiple Projects](../tutorials/02-multiple-projects.md) (10 min)
3. Learn: Project filters and `pick` command
4. Use: Dispatchers (`cc`, `g`, `r`, `qu`)

**Total time:** 20 minutes

### "I Want Beautiful Dashboards"

1. Read: [Quick Start](quick-start.md) (5 min)
2. Do: [Tutorial 3: Status Visualizations](../tutorials/03-status-visualizations.md) (10 min)
3. Try: `dash -i` for interactive mode
4. Try: `dash --watch` for live updates

**Total time:** 20 minutes

### "I'm a Developer - Show Me the Code"

1. Read: [CLAUDE.md](https://github.com/Data-Wise/flow-cli/blob/main/CLAUDE.md) (10 min)
2. Browse: [Dispatcher Reference](../reference/DISPATCHER-REFERENCE.md) (15 min)
3. Review: [Testing Guide](../testing/TESTING.md) (15 min)
4. Run: `flow doctor` to check your setup

**Total time:** 45 minutes

### "I Want to Contribute"

1. Read: [Contributing Guide](../contributing/CONTRIBUTING.md) (15 min)
2. Review: [Testing Guide](../testing/TESTING.md) (15 min)
3. Run: `zsh tests/test-cc-dispatcher.zsh` (5 min)
4. Build: Pick a [good first issue](https://github.com/Data-Wise/flow-cli/labels/good%20first%20issue)

**Total time:** 1 hour (+ implementation time)

---

## 📖 Reference Materials

### Quick References (Keep These Handy)

- [Command Quick Reference](../reference/COMMAND-QUICK-REFERENCE.md) - All commands
- [Dispatcher Reference](../reference/DISPATCHER-REFERENCE.md) - All 8 dispatchers
- [Workflow Quick Reference](../reference/WORKFLOW-QUICK-REFERENCE.md) - Common patterns
- [Alias Reference Card](../reference/ALIAS-REFERENCE-CARD.md) - Shortcuts

### Comprehensive Guides

- [Documentation Home](../index.md) - Everything organized
- [Dopamine Features](../guides/DOPAMINE-FEATURES-GUIDE.md) - Win tracking, streaks

---

## 🆘 Getting Help

### Common Questions

**"Which commands do I use daily?"**
→ `work`, `dash`, `win`, `finish` - See [Quick Start](quick-start.md)

**"How do I switch between projects?"**
→ Use `pick` or `hop` - See [Tutorial 2](../tutorials/02-multiple-projects.md)

**"What are the dispatchers?"**
→ `cc`, `g`, `mcp`, `obs`, `qu`, `r`, `tm`, `wt` - See [Dispatcher Reference](../reference/DISPATCHER-REFERENCE.md)

**"How do I check my setup?"**
→ Run `flow doctor` - See [Installation](installation.md)

### Still Stuck?

1. **Run health check:** `flow doctor`
2. **Check troubleshooting:** [Troubleshooting Guide](troubleshooting.md)
3. **Search the docs:** Use the [documentation site](https://Data-Wise.github.io/flow-cli/)
4. **Ask for help:** [GitHub Issues](https://github.com/Data-Wise/flow-cli/issues)

---

## 🎉 What's New (v4.4.x)

### Latest Features

- ✅ **8 dispatchers** - `cc`, `g`, `mcp`, `obs`, `qu`, `r`, `tm`, `wt`
- ✅ **150+ tests** - Full ZSH test suite with CI
- ✅ **Worktree integration** - `cc wt <branch>` for Claude in worktrees
- ✅ **Git feature workflow** - `g feature start/sync/finish`
- ✅ **Dopamine features** - Win tracking, streaks, daily goals

### Pure ZSH Architecture

- 🚀 **Sub-10ms response** - No Node.js runtime
- 📦 **Zero dependencies** - Just ZSH and Git
- 🔌 **Plugin manager support** - antidote, zinit, oh-my-zsh

**Current status:** v4.4.x is production-ready and actively maintained.

---

## 🎓 Learning Tips

### For ADHD-Friendly Learning

- ✅ **Hands-on learners:** Jump straight to [Tutorial 1](../tutorials/01-first-session.md)
- ✅ **Reference learners:** Bookmark [Command Reference](../reference/COMMAND-QUICK-REFERENCE.md)
- ✅ **Speed learners:** Use the [5-Minute Quick Start](#5-minute-quick-start)

### Best Practices

- **Start small:** Don't try to learn everything at once
- **Practice immediately:** Use what you learn right away
- **Bookmark references:** Keep quick reference cards handy
- **Ask questions:** Use GitHub Issues if you get stuck

### Progressive Mastery

1. **Week 1:** Basic workflow (Quick Start + Tutorial 1)
2. **Week 2:** Multiple projects (Tutorial 2 + Dispatchers)
3. **Week 3:** Advanced features (Dashboard modes + Dopamine)
4. **Month 2+:** Customization (Contributing + Testing)

---

**Ready to start?** Pick your path above and dive in!

**Questions?** See the [Getting Help](#getting-help) section.

**Version:** v4.4.x
**Last updated:** 2025-12-30
