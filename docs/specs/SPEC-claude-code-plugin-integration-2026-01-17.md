# SPEC: Claude Code Plugin Integration - Scholar & Craft Dispatchers

**Feature:** CLI wrappers for scholar and craft Claude Code plugins  
**Status:** Design Phase  
**Created:** 2026-01-17  
**Target Release:** flow-cli v5.13.0  
**Estimated Effort:** 18-24 hours over 2-3 weeks

---

## Metadata

| Field | Value |
|-------|-------|
| **Status** | Design → Implementation |
| **Priority** | High (enables research + teaching workflows) |
| **Complexity** | Medium (18-24 hours) |
| **Risk Level** | Low (additive, no breaking changes) |
| **Dependencies** | Claude Code CLI, scholar plugin, craft plugin |
| **Related Projects** | scholar v2.3.0+, craft v1.17.0+ |
| **Target Users** | Academic researchers, course instructors |
| **Branch Strategy** | feature/plugin-dispatchers → dev → main |

---

## Executive Summary

**Problem:** Scholar and craft are powerful Claude Code plugins with 108 combined commands (22 scholar + 86 craft), but they only work inside interactive Claude Code sessions. Users cannot leverage them from the command line for scripting, automation, or integration with flow-cli workflows.

**Solution:** Create two new flow-cli dispatchers (`scholar` and `craft`) that wrap Claude Code plugin commands, enabling CLI usage while maintaining the power of AI-assisted generation.

**Key Benefits:**
- **Teaching workflows:** `scholar quiz "topic" > quiz.md` for rapid content generation
- **Research automation:** `scholar arxiv "query" > papers.txt` for literature review  
- **Quality assurance:** `craft check --for release` for pre-publication validation
- **Scripting:** All commands usable in shell scripts and automation
- **ADHD-friendly:** Fast, predictable, composable with existing flow-cli tools

**Impact:**
- 10x faster course material creation (hours → minutes)
- Seamless integration with existing `teach-*`, `work`, `dash` commands
- Scriptable research pipelines (literature → code → paper)
- Zero context switching between terminal and Claude sessions

---

## Problem Statement

### Current State

**Scholar Plugin (22 commands):**
- Literature: `/arxiv`, `/doi`, `/bib:search`, `/bib:add`
- Teaching: `/teaching:exam`, `/teaching:quiz`, `/teaching:syllabus`, `/teaching:slides`
- Research: `/scholar:lit-gap`, `/scholar:hypothesis`, `/scholar:analysis-plan`
- Manuscript: `/manuscript:methods`, `/manuscript:results`, `/manuscript:reviewer`

**Craft Plugin (86 commands):**
- Smart orchestration: `/craft:do`, `/craft:check`, `/craft:hub`
- Testing: `/craft:test:run`, `/craft:test:coverage`
- Quality: `/craft:code:lint`, `/craft:security:scan`
- Documentation: `/craft:docs:validate`, `/craft:site:publish`

**Problem:** Only work inside `claude` interactive sessions.

**Limitations:**
1. Not scriptable - Cannot automate workflows
2. Manual context switching - Must enter/exit Claude sessions
3. No piping - Cannot compose with Unix tools
4. Flow-cli integration friction

### Desired State

```bash
# Scripting
scholar arxiv "bootstrap mediation" > lit-review.txt
scholar quiz "Linear Regression" > quiz.md

# Integration
teach-exam "Hypothesis Testing"  # Calls scholar
craft check --for release        # Pre-publication

# Automation
for topic in "regression" "anova"; do
  scholar quiz "$topic" > "quizzes/$topic.md"
done
```

---

## Design Overview

### Architecture

**3-layer integration:**

```
┌────────────────────────────────────────────────┐
│ Layer 3: flow-cli Workflows                    │
│ teach-exam, teach-quiz, work, dash            │
├────────────────────────────────────────────────┤
│ Layer 2: CLI Dispatchers (NEW)                │
│ scholar-dispatcher.zsh, craft-dispatcher.zsh  │
├────────────────────────────────────────────────┤
│ Layer 1: Claude Code CLI                      │
│ claude -p "/command" (print mode)             │
│ claude "/command" (interactive mode)          │
└────────────────────────────────────────────────┘
```

**Key Decisions:**

| Decision | Rationale |
|----------|-----------|
| Dispatcher pattern | Consistency with g, cc, mcp, r |
| Print mode default | Non-interactive, scriptable |
| Interactive fallback | Complex tasks need iteration |
| Output to stdout | Enable piping, redirection |
| Config integration | Read `.flow/teach-config.yml` |
| Completion support | ZSH completions for discovery |

---

## Implementation Plan

### Phase 1: Foundation (Week 1, 6h)

**Deliverables:**
- [ ] `lib/dispatchers/scholar-dispatcher.zsh`
- [ ] `lib/dispatchers/craft-dispatcher.zsh`
- [ ] Argument parsing
- [ ] Help system
- [ ] Error handling

### Phase 2: Scholar (Week 1-2, 10h)

**Deliverables:**
- [ ] Literature commands
- [ ] Teaching commands
- [ ] Config auto-detection
- [ ] Output formatting

### Phase 3: Craft (Week 2-3, 4h)

**Deliverables:**
- [ ] Smart orchestration
- [ ] Testing commands
- [ ] Site management
- [ ] Mode selection

### Phase 4: Integration (Week 3, 5h)

**Deliverables:**
- [ ] Teaching workflow integration
- [ ] Work/dash enhancements
- [ ] Completions
- [ ] Documentation
- [ ] Tests

---

## Success Metrics

**Week 1:** Both dispatchers load, help works  
**Week 2:** All scholar commands work, config auto-detection  
**Week 3:** Craft commands work, integration complete  
**Week 4+:** Daily usage, zero manual plugin invocation

---

## Example Workflows

### Teaching Workflow
```bash
cd ~/teaching/stat-579
work stat-579

scholar slides "Sequential Mediation" 75 --output slides/week08.qmd
scholar quiz "Sequential Mediation" --output quizzes/week08.md
craft site:validate
craft site:publish

finish "Week 8 materials"
```

### Research Workflow  
```bash
cd ~/research/multiply-robust
work mr-paper

scholar arxiv "multiply robust mediation" > lit-review.txt
scholar doi "10.1093/biomet/asz073" > paper.bib
scholar lit-gap "multiply robust" > gaps.md

win "Literature review complete"
```

---

## Documentation

**Reference:**
- `docs/reference/SCHOLAR-DISPATCHER-REFERENCE.md`
- `docs/reference/CRAFT-DISPATCHER-REFERENCE.md`

**Tutorials:**
- `docs/tutorials/scholar-cli-usage.md`
- `docs/tutorials/craft-cli-usage.md`

---

## Next Steps

1. ✅ Specification complete
2. Review with stakeholders  
3. Approve command structure
4. Begin Phase 1
5. Weekly progress reviews

---

**Contact:**  
Issues: https://github.com/Data-Wise/flow-cli/issues
