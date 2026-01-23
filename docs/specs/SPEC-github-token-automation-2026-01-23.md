# SPEC: GitHub Token Security & Automation

**Status:** In Progress
**Created:** 2026-01-23
**Target Release:** v5.18.0
**Estimated Effort:** 4 hours (1.5h Phase 1 + 2h Phase 2 + 0.5h testing/docs)
**Worktree:** `~/.git-worktrees/flow-cli/feature-token-automation`
**Branch:** `feature/token-automation`

---

## Overview

Semi-automated GitHub Personal Access Token (PAT) lifecycle management with macOS Keychain integration, expiration detection, and ADHD-optimized workflow integration across 9 flow-cli dispatchers.

**Critical Security Context:**
- **RESOLVED:** Exposed GitHub token found in `~/.claude/settings.json` (line 205)
- **Token:** `gho_[REDACTED]` (to be revoked immediately)
- **Root Cause:** Manual token management, no expiration tracking, plain text storage

**Key Benefits:**
- **Security:** Keychain storage with Touch ID, no plain text tokens in config
- **Automation:** 90% automated rotation (only browser token generation manual)
- **Proactive:** 7-day expiration warning (at 83 days, before 90-day expiration)
- **ADHD-Friendly:** One-command fixes, visual indicators, non-blocking checks
- **Comprehensive:** Integrated into 9 dispatchers (g, dash, work, finish, teach, doctor, gh CLI, git, MCP)

---

## Primary User Story

**As a** developer using GitHub frequently across multiple services (git, gh CLI, Claude Code, MCP servers),
**I want to** have my GitHub tokens automatically managed with expiration warnings,
**So that** I never experience authentication failures or security vulnerabilities from expired/exposed tokens.

**Acceptance Criteria:**
1. GitHub token stored in macOS Keychain (not plain text config) ✓
2. Token expiration detected 7 days before 90-day lifecycle ends ✓
3. One-command token rotation: `dot token rotate github` ✓
4. Automatic token validation before git operations (push/pull/fetch) ✓
5. Visual status in `dash dev` showing token health ✓
6. Token auto-synced to gh CLI configuration ✓
7. Weekly async health check (non-blocking shell startup) ✓
8. Complete audit trail in `~/.claude/logs/token-rotation.log` ✓
9. Zero manual configuration after initial setup ✓
10. Token metadata tracking (creation date, rotation history) ✓

---

## Secondary User Stories

### 1. Proactive Expiration Warnings

**As a** developer starting a work session,
**I want to** be notified when my GitHub token is expiring soon,
**So that** I can rotate it before it causes authentication failures.

**Acceptance:**
- Warning appears in `work` command when token < 7 days to expiration
- Non-intrusive: single line with one-command fix
- Example: `⚠️  GitHub token expires in 5 days — Run: dot token rotate github`

### 2. Safe Pre-Push Validation

**As a** developer pushing code,
**I want to** be warned if my GitHub token is invalid before the push fails,
**So that** I don't waste time on failed operations.

**Acceptance:**
- `g push`, `g pull`, `g fetch` validate token silently
- If invalid: prompt with one-command fix
- User can bypass validation if desired
- < 200ms validation overhead

### 3. One-Command Token Rotation

**As a** developer rotating my GitHub token,
**I want to** complete the process with a single command,
**So that** I don't need to remember multi-step procedures.

**Acceptance:**
- `dot token rotate github` handles entire lifecycle:
  1. Backs up old token
  2. Opens browser to GitHub token generation page
  3. Waits for user to paste new token
  4. Validates new token via GitHub API
  5. Stores in Keychain with metadata
  6. Syncs to gh CLI
  7. Prompts to revoke old token
  8. Updates audit log
- Total time: ~2 minutes (30s generation + 90s automation)

### 4. Dashboard Token Health

**As a** developer checking project status,
**I want to** see GitHub token health in the dashboard,
**So that** I know if action is needed without running separate commands.

**Acceptance:**
- `dash dev` shows token status line:
  - `✓ GitHub token: Valid (expires in 45 days)`
  - `⚠️ GitHub token: Expiring soon (5 days) — dot token rotate github`
  - `✗ GitHub token: Expired — dot token rotate github`
- Color-coded: green (>7 days), yellow (≤7 days), red (expired/invalid)
- Non-blocking: dashboard loads even if token check fails

---

## Technical Requirements

### Architecture

**Pattern:** Extension of existing `dot` dispatcher with token management subcommands

**Design Decisions:**

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Storage** | macOS Keychain | Instant access (<1ms) vs Bitwarden (2-5s), Touch ID support |
| **Automation Level** | Semi-automated (90%) | GitHub API doesn't support programmatic PAT generation |
| **Expiration Warning** | 7 days (83 days after creation) | Balance between proactive and non-annoying |
| **Metadata Storage** | JSON in Keychain notes field | Encrypted with token, no separate DB |
| **Health Checks** | Weekly async (non-blocking) | Avoid shell startup lag |
| **Revocation** | User approval required | Safety: prevent accidental service disruption |

**File Structure:**
```
lib/
├── dispatchers/
│   └── dot-dispatcher.zsh          # Extended with token commands (lines ~2145+)
└── keychain-helpers.zsh            # Already exists, no changes needed

hooks/
└── token-health-check.zsh          # New: Weekly async health check

docs/
├── reference/
│   └── DOT-DISPATCHER-REFERENCE.md # Update with token commands
└── tutorials/
    └── github-token-setup.md       # New: Setup guide

tests/
└── test-dot-token.zsh              # New: Token management tests
```

### GitHub API Limitations (Critical)

**What GitHub API CAN do:**
- ✅ Validate tokens (`GET /user`)
- ✅ Check token scopes (`GET /user` → headers)
- ✅ Revoke tokens (`DELETE /applications/{client_id}/token`)
- ✅ List user's authorized apps

**What GitHub API CANNOT do:**
- ❌ Generate new PATs programmatically (security by design)
- ❌ Rotate tokens automatically
- ❌ Check token expiration date directly (must track via metadata)

**Implication:** Token generation MUST be manual (open browser, copy/paste)

### Token Lifecycle

```
┌─────────────────────────────────────────────────────────────┐
│ Token Lifecycle (90 days)                                    │
├─────────────────────────────────────────────────────────────┤
│ Day 0:    Created, stored in Keychain with metadata          │
│ Day 1-82: Valid, no warnings                                 │
│ Day 83:   Expiration warning triggered (7 days remaining)    │
│ Day 83+:  Warnings in work/dash/finish commands              │
│ Day 90:   Expired, validation fails                          │
│ Day 90+:  All git operations blocked until rotation          │
└─────────────────────────────────────────────────────────────┘
```

**Metadata Format (Keychain notes field):**
```json
{
  "created_at": "2026-01-23T04:30:00Z",
  "expires_at": "2026-04-23T04:30:00Z",
  "rotation_history": [
    {"date": "2026-01-23", "reason": "initial_setup"},
    {"date": "2026-04-16", "reason": "proactive_rotation"}
  ],
  "last_validated": "2026-01-23T10:15:00Z",
  "scopes": ["repo", "workflow", "read:org"]
}
```

---

## Implementation Phases

### Phase 1: Core Token Automation (1.5 hours)

**Goal:** Semi-automated token lifecycle with keychain integration

**Tasks:**

1. **Task 1.1: Token Expiration Detector (15 min)**
   - File: `lib/dispatchers/dot-dispatcher.zsh` (after line ~2145)
   - Functions: `_dot_token_expiring()`, `_dot_token_age_days()`
   - Logic: Check all `github*` secrets in keychain, validate via API, calculate age

2. **Task 1.2: Token Metadata Tracking (15 min)**
   - File: `lib/dispatchers/dot-dispatcher.zsh`
   - Functions: `_dot_token_save_metadata()`, `_dot_token_get_metadata()`
   - Logic: Store/retrieve JSON from Keychain notes field

3. **Task 1.3: Semi-Automated Token Rotation (30 min)**
   - File: `lib/dispatchers/dot-dispatcher.zsh`
   - Function: `_dot_token_rotate_github()`
   - Logic: Backup → Browser → Validate → Store → Sync → Revoke prompt
   - User approval at 2 checkpoints: (1) Before opening browser, (2) Before revocation

4. **Task 1.4: gh CLI Auto-Sync (15 min)**
   - File: `lib/dispatchers/dot-dispatcher.zsh`
   - Function: `_dot_token_sync_gh()`
   - Logic: Export to `$GITHUB_TOKEN`, run `gh auth login --with-token`

5. **Task 1.5: Weekly Health Check Hook (15 min)**
   - File: `hooks/token-health-check.zsh`
   - Trigger: Weekly (check last run timestamp)
   - Logic: Async check, log to `~/.claude/logs/token-rotation.log`

### Phase 2: flow-cli Integration (2 hours)

**Goal:** Integrate token health into existing workflows

**Tasks:**

1. **Task 2.1: g Dispatcher Validation (20 min)**
   - File: `lib/dispatchers/g-dispatcher.zsh`
   - Hook: Before `g push`, `g pull`, `g fetch` (if GitHub remote)
   - Logic: Silent validation, prompt only if invalid

2. **Task 2.2: dash Integration (20 min)**
   - File: `commands/dash.zsh` (in `_dash_show_dev()`)
   - Display: Token status line in dev category
   - Format: Color-coded status + expiration countdown

3. **Task 2.3: work Command Integration (20 min)**
   - File: `commands/work.zsh`
   - Hook: Session start (non-blocking)
   - Logic: Check expiration, show warning if < 7 days

4. **Task 2.4: finish Command Integration (15 min)**
   - File: `commands/work.zsh` (in `finish()`)
   - Hook: Session end (if git operations during session)
   - Logic: Reminder to rotate if expiring

5. **Task 2.5: flow doctor Integration (30 min)**
   - File: `commands/doctor.zsh`
   - Category: "GitHub Integration"
   - Checks: Token exists, valid, not expiring, gh CLI synced

6. **Task 2.6: flow token Alias (5 min)**
   - File: `commands/flow.zsh`
   - Alias: `flow token` → `dot token`
   - Rationale: Discoverability for new users

---

## Integration Points (9 Dispatchers)

| Dispatcher | Integration | Trigger | Action |
|------------|-------------|---------|--------|
| **dot** | Token commands | `dot token *` | Full token lifecycle management |
| **g** | Pre-operation validation | Before push/pull/fetch | Validate token, prompt if invalid |
| **dash** | Status display | `dash dev` | Show token health with expiration |
| **work** | Session start check | `work <project>` | Warn if token expiring soon |
| **finish** | Session end reminder | `finish` (if git used) | Remind to rotate if expiring |
| **teach** | Scholar MCP dependency | Before Scholar commands | Validate token (Scholar uses GitHub API) |
| **flow doctor** | Health check | `flow doctor` | Comprehensive token diagnostics |
| **gh CLI** | Auto-sync | After token rotation | Sync token to gh CLI config |
| **git credentials** | Environment export | Shell startup | Export `$GITHUB_TOKEN` |

---

## Dependencies

### Required
- **macOS Keychain** (via `security` command) - Already available
- **curl** - For GitHub API calls - Already available
- **jq** - For JSON parsing - Already available
- **Existing `dot secret` commands** - Already implemented in keychain-helpers.zsh

### Optional
- **gh CLI** - For GitHub CLI integration (already a flow-cli dependency)
- **git** - For detecting GitHub remotes (already a flow-cli dependency)

### No New Dependencies
All required tools are already part of flow-cli's existing dependencies.

---

## Security Considerations

### Threat Model

| Threat | Mitigation |
|--------|------------|
| **Token exposure in config** | Store in Keychain (encrypted at rest) |
| **Token exposure in logs** | Never log token value, only validation status |
| **Token exposure in shell history** | Use stdin for token input, not command args |
| **Token exposure in process list** | Pass via pipe, not environment variable (for input) |
| **Expired token usage** | Proactive validation before operations |
| **Accidental revocation** | Require user approval before revocation |
| **Token theft from Keychain** | Keychain protected by user password + Touch ID |

### Safe Practices

1. **Never echo tokens** - Use `read -s` for input
2. **Never log tokens** - Log validation status only
3. **Never pass in args** - Use stdin or environment variables
4. **Always validate before use** - Check GitHub API before operations
5. **Always backup before rotation** - Store old token in Keychain (30-day retention)
6. **Always audit** - Log all token operations to audit file

---

## Testing Strategy

### Unit Tests
- Token age calculation (various dates)
- Metadata storage/retrieval (JSON parsing)
- Expiration detection (edge cases: 0 days, 7 days, 90 days)
- GitHub API validation (mock responses)

### Integration Tests
- Full rotation workflow (with mock GitHub API)
- g dispatcher validation (with mock token)
- dash display (various token states)
- work/finish warnings (expiration scenarios)

### Manual Testing Checklist
1. Initial setup: `dot token github` (create new token)
2. Validation: `dot token status` (check expiration)
3. Rotation: `dot token rotate github` (full lifecycle)
4. Integration: `g push` (validation), `dash dev` (display)
5. Health check: Wait 7 days, verify warning triggers
6. Expiration: Set metadata to 89 days ago, verify blocked operations

---

## Documentation Plan

### Reference Documentation
- **DOT-DISPATCHER-REFERENCE.md** - Update with token commands section
- **API Reference** - Document all `_dot_token_*()` functions

### Tutorial
- **github-token-setup.md** - Step-by-step setup guide:
  1. Initial token creation
  2. First-time setup
  3. Rotation workflow
  4. Troubleshooting

### Quick Reference Card
- Update `REFCARD-*.md` with token commands
- Add token troubleshooting section

---

## Rollout Plan

### Phase 1: Core Automation (Week 1)
- Implement token lifecycle functions
- Test with mock data
- Document API

### Phase 2: Integration (Week 1)
- Integrate into 9 dispatchers
- Test workflows
- Update documentation

### Phase 3: Testing & Docs (Week 1)
- Write test suites
- Create tutorial
- Update reference docs

### Phase 4: Release (Week 2)
- Merge to dev
- Create PR to main
- Release v5.18.0

---

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Time to setup** | < 5 minutes | Initial `dot token github` |
| **Time to rotate** | < 2 minutes | Full rotation workflow |
| **Validation overhead** | < 200ms | g dispatcher pre-check |
| **False positive warnings** | 0% | No warnings when token valid |
| **Authentication failures** | 0% after setup | No git/gh CLI failures |
| **User satisfaction** | No complaints | ADHD-friendly, non-intrusive |

---

## Related Documents

### Brainstorm Documents (External)
- `~/BRAINSTORM-github-token-security-2026-01-23.md` (19KB) - Initial security analysis
- `~/BRAINSTORM-automated-token-management-2026-01-23.md` (36KB) - Automation design with 18 Q&A decisions
- `~/BRAINSTORM-flow-github-integration-2026-01-23.md` (22KB) - Integration design with 12 Q&A decisions

### Implementation Plan
- `~/.git-worktrees/flow-cli/feature-token-automation/IMPLEMENTATION-PLAN.md` - Detailed orchestration plan

---

## Risks & Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| **GitHub API rate limits** | Validation failures | Low | Cache validation results (5 min TTL) |
| **Keychain access denied** | Setup failures | Low | Clear error messages, fallback instructions |
| **User forgets to approve rotation** | Expired token | Medium | Multiple warning levels (7d, 3d, 1d, 0d) |
| **Token revocation breaks services** | Service disruption | Low | Backup old token, 30-day retention |
| **Shell startup lag** | Poor UX | Low | Async health checks, non-blocking |

---

## Future Enhancements (v5.19.0+)

1. **Multi-token support** - Separate tokens for different services
2. **Token scope validation** - Warn if insufficient permissions
3. **Remote sync** - Sync tokens across machines via encrypted channel
4. **Integration with other services** - GitLab, Bitbucket, etc.
5. **Token usage analytics** - Track which services use which tokens

---

**Last Updated:** 2026-01-23
**Status:** In Progress - Implementation started
**Next Step:** Begin Phase 1, Task 1.1 (Token Expiration Detector)
