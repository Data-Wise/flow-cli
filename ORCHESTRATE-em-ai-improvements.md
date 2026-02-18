# Email AI Improvements Orchestration Plan

> **Branch:** `feature/em-ai-improvements`
> **Base:** `dev`
> **Worktree:** `~/.git-worktrees/flow-cli/feature-em-ai-improvements`
> **Spec:** `docs/specs/SPEC-em-ai-improvements-2026-02-18.md`

## Objective

Add runtime AI backend switching, Gemini CLI speed optimization, and cross-dispatcher email-to-task capture to the `em` dispatcher.

## Phase Overview

| Phase | Task                                        | Priority | Status  |
| ----- | ------------------------------------------- | -------- | ------- |
| 1     | `em ai` subcommand (runtime backend switch) | High     | Pending |
| 2     | Gemini `extra_args` support                 | High     | Pending |
| 3     | `em catch` email-to-task capture            | Medium   | Pending |
| 4     | Tests for all new features                  | High     | Pending |
| 5     | Help text + docs updates                    | Medium   | Pending |

## Phase Details

### Phase 1: `em ai` Subcommand

**Files:** `lib/em-ai.zsh`, `lib/dispatchers/email-dispatcher.zsh`

- Add `_em_ai_cmd()`, `_em_ai_switch()`, `_em_ai_toggle()`, `_em_ai_status()`
- Fix `_em_ai_backend_for_op()` to read live `$FLOW_EMAIL_AI` (not frozen value)
- Add `ai|AI` case to dispatcher
- Subcommands: `em ai`, `em ai claude`, `em ai gemini`, `em ai none`, `em ai toggle`, `em ai auto`

### Phase 2: Gemini `extra_args`

**Files:** `lib/em-ai.zsh`

- Add `[gemini_extra_args]` and `[claude_extra_args]` to `_EM_AI_BACKENDS`
- Modify `_em_ai_execute()` gemini case to spread `${=extra}`
- Add `FLOW_EMAIL_GEMINI_EXTRA_ARGS` config var
- Show in `em ai` status and `em doctor`

### Phase 3: `em catch`

**Files:** `lib/dispatchers/email-dispatcher.zsh`

- Add `catch|c` case to dispatcher
- Implement `_em_catch()`: read email → AI summarize → pipe to `catch`
- Graceful fallback: no AI → use subject line, no `catch` cmd → display only
- Add Ctrl-C binding to `_em_pick()` fzf keybinds

### Phase 4: Tests

**Files:** `tests/test-em-ai-switch.zsh`, `tests/test-em-catch.zsh`

- Test `_em_ai_switch` validation (valid/invalid backends)
- Test `_em_ai_toggle` cycling
- Test `_em_ai_status` output
- Test `_em_catch` with mocked himalaya + AI
- Test graceful degradation paths

### Phase 5: Docs + Help

**Files:** `lib/dispatchers/email-dispatcher.zsh` (`_em_help`), docs

- Update `_em_help()` with new subcommands
- Update `em doctor` config summary
- Update MASTER-DISPATCHER-GUIDE.md

## Acceptance Criteria

- [ ] `em ai` shows current backend
- [ ] `em ai gemini` switches immediately, next `em reply` uses Gemini
- [ ] `em ai toggle` cycles claude → gemini → claude
- [ ] `em ai none` disables AI
- [ ] Invalid backend shows error + available list
- [ ] Gemini with extra_args completes in < 3s
- [ ] `em catch 42` produces summary and logs to catch
- [ ] Graceful fallback if catch command unavailable
- [ ] Graceful fallback if AI unavailable (uses subject line)
- [ ] All new subcommands appear in `em help`
- [ ] No `local path=` ZSH gotcha in new functions
- [ ] Tests pass for all new features

## How to Start

```bash
cd ~/.git-worktrees/flow-cli/feature-em-ai-improvements
claude
```
