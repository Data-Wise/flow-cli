# BRAINSTORM: Integrate em doctor with flow doctor

**Generated:** 2026-02-12
**Context:** flow-cli / email dispatcher integration
**Mode:** feature | **Depth:** deep (8 questions)

## Overview

Integrate email health checking into `flow doctor` so himalaya and email dependencies are verified alongside core flow-cli tools. Currently `em doctor` and `flow doctor` operate independently — this unifies them while keeping both functional.

## Quick Wins (< 30 min each)

1. Add `_doctor_check_email()` function to `commands/doctor.zsh`
2. Gate behind `(( $+functions[em] ))` — zero overhead when em not loaded
3. Himalaya version check reusing existing `_em_semver_lt` pattern
4. Config summary (AI backend, timeout, page size, config file)

## Medium Effort (1-2 hours)

- HTML renderer "any-of" check (w3m OR lynx OR pandoc)
- Email category in `--fix` mode category selection menu
- Dedup strategy for shared deps (fzf, bat, jq)

## Long-term (Future sessions)

- `em doctor` detects flow doctor EMAIL section → reduces duplicate output
- `flow doctor --email` flag (mirrors `--dot` pattern)

## Architecture

### Section Placement

```
SHELL → REQUIRED → RECOMMENDED → OPTIONAL → INTEGRATIONS → EMAIL → DOTFILES → ...
```

### Conditional Gate

```zsh
if (( $+functions[em] )); then
    _doctor_check_email
fi
```

### Deps Checked

| Tool | Level | Install | Notes |
|------|-------|---------|-------|
| himalaya | required | brew | + version >= 1.0.0 |
| w3m/lynx/pandoc | recommended | brew | Any-of check |
| glow | recommended | brew | Markdown rendering |
| email-oauth2-proxy | recommended | pip | OAuth2 IMAP/SMTP |
| terminal-notifier | optional | brew | Desktop notifications |
| claude/gemini | optional | varies | Based on $FLOW_EMAIL_AI |

### Dedup Strategy

fzf, bat, jq already checked in earlier sections. EMAIL section only checks unique email tools. Shared tools get a reference: "jq ✓ (checked above)".

### Fix Mode

New "Email Tools" category in `_doctor_select_fix_category` menu. Uses existing `_doctor_missing_brew[]` / `_doctor_missing_pip[]` arrays — no new infrastructure.

### Key Design Decisions

1. **Reuse `_doctor_check_cmd`** — consistent with all other sections
2. **Both doctors remain standalone** — em doctor and flow doctor both work independently
3. **Binary check only** — no IMAP connectivity test (keeps flow doctor fast)
4. **Brew only for himalaya** — consistent with other flow deps
5. **Show config summary** — AI backend, timeout, page size, config file path

## Recommended Path

Start with inline `_doctor_check_email()` function. One new function + one conditional call. Automatic --fix support via existing arrays.

## Next Steps

1. [ ] Implement `_doctor_check_email()` in `commands/doctor.zsh`
2. [ ] Add email category to fix mode menu
3. [ ] Add himalaya version check
4. [ ] Add config summary block
5. [ ] Test with em loaded vs not loaded
6. [ ] Update doctor help text
