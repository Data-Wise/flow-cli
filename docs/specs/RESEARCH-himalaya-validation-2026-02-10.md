# Research: himalaya Validation for `em` Dispatcher

**Generated:** 2026-02-10
**Issue:** #331
**Status:** Complete
**Verdict:** himalaya is the right foundation. Proceed.

---

## 1. himalaya Has Matured Significantly

Our brainstorm (earlier today) said "pre-1.0" -- that's wrong. The situation has improved:

| Milestone | Date | Significance |
|-----------|------|--------------|
| v1.0.0 | Dec 9, 2024 | Stable release after 4 betas |
| v1.1.0 | Jan 11, 2025 | Refinement release (quiet flag, TLS certs, multi-config) |
| NLnet funding extended | 2025 | Grant extended to June 2026, another year possible |
| 5.4K GitHub stars | Current | Significant community interest |
| 970 commits | Current | Substantial codebase |

**What changed in v1.0.0:**

- **Scope reduction:** Sync and envelope watching removed -- moved to dedicated tools (Neverest CLI for sync, Mirador CLI for monitoring)
- **Config restructured:** Standardized `backend.*` and `message.send.backend.*` namespaces
- **Native OAuth2/XOAUTH2:** Built-in, no proxy needed for O365
- **JSON output:** Reliable for scripting (our fzf picker)
- **`$EDITOR` integration:** Native compose/reply via `$EDITOR`
- **Keyring integration:** Credential storage via system keyring

**Impact on our `em` dispatcher:**

- The scope reduction is actually **good for us** -- himalaya focuses on what we need (read, send, compose) without the complexity of sync/watch
- Native OAuth2 means we may not need `email-oauth2-proxy` at all
- Stable CLI interface (post-1.0 = semver, breaking changes require major bump)

---

## 2. himalaya's Future Is Secure

| Factor | Assessment |
|--------|------------|
| **Funding** | NLnet grant through June 2026, extension possible |
| **Maintainer** | soywod (active, transparent about slowdowns) |
| **Vision** | Evolving into Pimalaya PIM suite (Calendula, Cardamum, Himalaya) |
| **Architecture** | I/O-free core lib refactor (better maintainability) |
| **Community** | 5.4K stars, FOSDEM presence, Lobsters/HN visibility |

**Risk:** Single maintainer. Personal circumstances have slowed development in 2025. But the funding runway and architectural investment suggest commitment.

**Mitigation for us:** Our `em` dispatcher wraps ~5-10 himalaya commands through a thin adapter layer. If himalaya stalls, we update one ZSH file. We're not building a plugin or deep integration.

---

## 3. Alternatives Considered

### aerc (Go, TUI)

**Why NOT:** It's a full TUI email client -- you'd live inside it, not wrap it. That's the opposite of the dispatcher pattern. No JSON output, no composable CLI interface. The O365 setup requires oama + SASL xoauth2 plugin + manual compilation on macOS.

### NeoMutt (C, TUI)

**Why NOT:** Configuration nightmare. Not composable. Ancient architecture. Same TUI problem as aerc.

### meli (Rust, TUI)

**Why NOT:** Same TUI problem. Smaller community than aerc. Limited OAuth2 support.

### mblaze (C, CLI)

**Why NOT:** Maildir-only, no native IMAP. Requires local mail sync layer (offlineimap/mbsync). himalaya does IMAP natively.

---

## 4. Why himalaya Wins

| Requirement | himalaya | aerc | NeoMutt | mblaze |
|-------------|----------|------|---------|--------|
| CLI (not TUI) | **YES** | No | No | Yes |
| JSON output for fzf | **YES** | No | No | No |
| Native IMAP | **YES** | Yes | Yes | No |
| Native OAuth2/XOAUTH2 | **YES** | Via oama | Via helper | N/A |
| `$EDITOR` support | **YES** | Built-in | Built-in | No |
| Composable with pipes | **YES** | No | No | Yes |
| macOS Homebrew | **YES** | Yes | Yes | Manual |
| Keyring integration | **YES** | Via oama | No | No |
| Active development | **YES** (funded) | Yes | Slow | Minimal |

himalaya is the **only CLI email tool** that has native IMAP + OAuth2, outputs JSON (for fzf), supports `$EDITOR` (for nvim), and is composable with shell pipes (for AI drafts).

---

## 5. What Changed from Brainstorm

| Brainstorm Claim | Reality | Impact |
|------------------|---------|--------|
| "himalaya is pre-1.0" | v1.0.0 shipped Dec 2024, v1.1.0 Jan 2025 | **CLI is stable** -- semver means no breaking changes without major bump |
| "CLI interface has changed across versions" | True historically, but post-1.0 is semver-stable | **Lower maintenance risk** |
| "Needs email-oauth2-proxy for O365" | himalaya has **native OAuth2/XOAUTH2** | **Simpler stack** -- may not need the proxy at all |
| "Fragile ecosystem" | nvim plugins are fragile (still true), but himalaya CLI is solid | Approach B (CLI wrapper) avoids the fragile parts |

---

## 6. Spec Update Summary

These specs need "pre-1.0" references corrected:

| File | Change |
|------|--------|
| `SPEC-em-dispatcher-2026-02-10.md` | Update adapter rationale (lines 19, 121-123) |
| `SPEC-email-dispatcher.md` | Update Risk 1 assessment (lines 381-388) |
| `PROPOSAL-email-dispatcher-2026-02-10.md` | Update risk text + doctor output + deps table (lines 66, 182-183, 243-244) |
| `ANALYSIS-nvim-email-architecture-2026-02-10.md` | Update fragility assessments (lines 41, 48, 59, 299) |
| `BRAINSTORM-nvim-himalaya-integration-2026-02-10.md` | Update ecosystem assessment (lines 31, 37) |
| `SPEC-email-himalaya-nvim-ux-analysis.md` | Update API change reference (line 99) |

---

## 7. Open Question: Native OAuth2 vs email-oauth2-proxy

This needs testing in the worktree session:

```toml
# himalaya config.toml -- native O365 OAuth2 (try this first)
[accounts.lobomail]
email = "user@lobo.example.edu"

[accounts.lobomail.backend]
type = "imap"
host = "outlook.office365.com"
port = 993
encryption = "tls"

[accounts.lobomail.backend.auth]
type = "oauth2"
method = "xoauth2"
client-id = "<azure-app-client-id>"
auth-url = "https://login.microsoftonline.com/common/oauth2/v2.0/authorize"
token-url = "https://login.microsoftonline.com/common/oauth2/v2.0/token"
scope = "https://outlook.office.com/IMAP.AccessAsUser.All"
```

If native OAuth2 works, remove `email-oauth2-proxy` from the dependency stack entirely.

---

## Sources

- himalaya GitHub: 5.4K stars, 970 commits
- himalaya Releases: v1.0.0 (Dec 2024), v1.1.0 (Jan 2025)
- The Future of Himalaya (Discussion #118): NLnet funding, PIM suite vision
- NLnet Himalaya Grant: Institutional funding
- HN Discussion on v1.0.0: Community reception
- himalaya CHANGELOG: Scope reduction details

---

**Last Updated:** 2026-02-10
