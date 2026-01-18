# Teaching Workflow v3.0 - Phase 1 Implementation

**Session Brief for Claude Code Orchestration**

---

## Overview

Implement Teaching Workflow v3.0 enhancements (Phase 1) as specified in approved spec document.

**Spec:** `/Users/dt/projects/dev-tools/flow-cli/docs/specs/SPEC-teaching-workflow-v3-enhancements.md` (v3.0)
**Target Release:** flow-cli v5.14.0
**Estimated Effort:** ~23 hours
**Testing:** Unit + Integration + scholar-demo-course validation

---

## Phase 1 Tasks (10 Total)

### Core Modifications

1. **Remove teach-init Standalone** [1h]
   - Delete `commands/teach-init.zsh` entirely
   - Remove from dispatchers (no deprecation warning)
   - Update help system

2. **Basic teach doctor** [2h]
   - Dependency checks (yq, git, quarto, gh)
   - Config file existence validation
   - `.flow/teach-config.yml` validation check
   - Basic error reporting

3. **Add --help Flags** [3h]
   - Add `--help` handling to 10 sub-commands
   - Include usage examples for each
   - Consistent format across all helps

4. **Full teach doctor** [3h]
   - Add `--fix` interactive mode (offer to install missing deps)
   - Add `--json` output format
   - Comprehensive dependency validation
   - Pretty-printed status report

5. **Backup System** [4h]
   - `.backups/` folders inside content directories
   - Timestamp naming: `<name>.<YYYY-MM-DD-HHMM>/`
   - teach-config.yml schema for retention policies
   - Archive helper functions

6. **Prompt Before Delete** [1h]
   - Interactive confirmation before backup deletion
   - Preview what will be deleted
   - Option to cancel

### New Enhancements

7. **teach status Enhancement** [2h]
   - Add deployment status section (last deploy, PR status)
   - Add backup summary (total backups, last backup, by type)
   - Enhanced output format

8. **teach deploy Preview** [2h]
   - Show diff preview before creating PR
   - Display files changed summary
   - Confirm before PR creation

9. **Scholar Template + Lesson Plan** [4h]
   - Add template selection to Scholar wrappers
   - Auto-load lesson-plan.yml context when exists
   - Pass to Scholar commands via flags
   - Update all 9 Scholar wrappers

10. **teach init Enhancements** [1h]
    - Add `--config <file>` flag (load external config)
    - Add `--github` flag (create GitHub repo)
    - Both optional, maintain non-interactive flow

---

## Files to Modify

### Core Files (~580 lines changes)
- `lib/dispatchers/teach-dispatcher.zsh` - Main dispatcher logic
- `commands/teach-init.zsh` - **DELETE THIS FILE**
- `lib/git-helpers.zsh` - Deploy preview (~50 lines)
- `lib/templates/teaching/teach-config.schema.json` - Backup schema

### Test Files
- `tests/test-teach-deploy.zsh` - Update for new preview
- `tests/test-teach-doctor.zsh` - NEW (comprehensive tests)
- `tests/test-teach-backup.zsh` - NEW (backup system tests)
- `tests/test-teach-init.zsh` - Update for new flags

### Documentation
- `docs/reference/TEACH-DISPATCHER-REFERENCE.md` - Update all commands
- `docs/guides/TEACHING-WORKFLOW.md` - Update workflows
- `CHANGELOG.md` - Add v5.14.0 entry

---

## Implementation Order

**Recommended sequence for atomic commits:**

1. **Task 1** - Remove teach-init (clean slate)
2. **Task 2** - Basic doctor (foundation)
3. **Task 4** - Full doctor with --fix (complete health check)
4. **Task 3** - Add --help to all commands (UX improvement)
5. **Task 5** - Backup system (infrastructure)
6. **Task 6** - Prompt before delete (safety layer)
7. **Task 7** - Enhanced teach status (user visibility)
8. **Task 8** - Deploy preview (deployment safety)
9. **Task 9** - Scholar templates + lesson plan (power feature)
10. **Task 10** - teach init flags (optional enhancement)

Each task should be:
- Implemented completely
- Tested (unit + integration)
- Committed with conventional commit message
- Documented in code comments

---

## Testing Requirements

### Unit Tests
- Each task MUST have corresponding unit tests
- Test both success and failure paths
- Test edge cases (missing files, invalid config, etc.)

### Integration Tests
- Test full workflows end-to-end
- Use scholar-demo-course as test fixture
- Validate all commands work together

### Validation Checklist
```bash
# Before each commit
./tests/test-teach-doctor.zsh           # If modifying doctor
./tests/test-teach-backup.zsh           # If modifying backups
./tests/test-teach-deploy.zsh          # If modifying deploy
./tests/run-all.sh                     # Full suite before PR

# Manual testing
cd ~/projects/teaching/scholar-demo-course
teach doctor                           # Should pass all checks
teach doctor --fix                     # Should offer installs
teach status                           # Should show new sections
teach deploy                           # Should show preview
```

---

## Success Criteria

**Before marking Phase 1 complete:**

- ✅ All 10 tasks implemented
- ✅ All tests passing (100%)
- ✅ scholar-demo-course tested successfully
- ✅ Documentation updated
- ✅ CHANGELOG.md updated
- ✅ PR ready for review (dev branch)

---

## Orchestration Strategy

**Use `/craft:orchestrate` for optimal workflow:**

```bash
# In new session, run:
/craft:orchestrate

# Or manually:
# 1. Review this ORCHESTRATE.md
# 2. Read spec: docs/specs/SPEC-teaching-workflow-v3-enhancements.md
# 3. Start with Task 1 (atomic implementation)
# 4. Commit after each task
# 5. Test continuously
```

**Key Principles:**
- Small, atomic commits (conventional commit format)
- Test after each task
- Document as you go
- Keep spec open for reference
- Ask questions if requirements unclear

---

## Quick Reference

**Spec Location:**
`/Users/dt/projects/dev-tools/flow-cli/docs/specs/SPEC-teaching-workflow-v3-enhancements.md`

**Key Configuration:**
```yaml
# teach-config.yml additions
backups:
  gitignore: true
  retention:
    assessments: archive    # Archive per semester
    syllabi: archive        # Archive per semester
    lectures: semester      # Keep current semester only
  archive_dir: ".flow/archives"
```

**teach doctor Output Example:**
```
📋 Teaching Environment Health Check
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Dependencies:
  ✅ yq (4.35.1)
  ✅ git (2.42.0)
  ✅ quarto (1.4.550)
  ✅ gh (2.40.1)

Configuration:
  ✅ .flow/teach-config.yml (valid)
  ✅ Schema validation passed

Environment:
  ✅ Git repository initialized
  ✅ Draft branch exists (draft)
  ✅ Production branch exists (main)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Status: ✅ All checks passed
```

---

**Ready to implement!**

Start a new Claude Code session in this worktree:
```bash
cd ~/.git-worktrees/flow-cli/teaching-workflow-v3
claude
```

Then use `/craft:orchestrate` or implement tasks sequentially.
