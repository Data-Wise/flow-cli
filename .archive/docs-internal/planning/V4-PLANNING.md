# v4.0.0 Planning - Ecosystem Integration

**Status:** Planning Phase
**Target:** Q1 2025
**Theme:** Cross-tool orchestration, remote sync, team features

---

## Overview

v4.0.0 focuses on **ecosystem integration** - making flow-cli the central hub for managing multiple development tools while maintaining the ADHD-friendly, sub-10ms response time philosophy.

### Core Principles

1. **Local-first** - Cloud features are always optional
2. **Privacy-respecting** - No telemetry, no data sharing
3. **Incremental adoption** - Each feature stands alone
4. **Graceful degradation** - Works without any external services

---

## Feature Set

### 1. Cross-Tool Orchestration

**Goal:** Unified commands for managing multiple tools

#### Commands

```bash
# Sync everything
flow sync all              # Atlas + Git + Obsidian + .STATUS

# Component-specific sync
flow sync atlas            # Sync atlas project registry
flow sync git              # Fetch all repos, show status
flow sync notes            # Obsidian vault sync

# Unified status
flow status all            # Aggregate status across all tools
flow status --json         # Machine-readable output

# Export/Import
flow export                # Export all state to archive
flow import <file>         # Import from archive
```

#### Implementation

| Component       | Description              | Priority |
| --------------- | ------------------------ | -------- |
| `flow sync`     | Orchestration dispatcher | High     |
| Atlas bridge    | Sync atlas registry      | High     |
| Git integration | Multi-repo status        | Medium   |
| Obsidian bridge | Vault sync               | Low      |
| Export format   | JSON + markdown          | Medium   |

#### Dependencies

- atlas v0.6+ (for registry API)
- git (already required)
- obsidian-cli-ops (optional)

---

### 2. Remote State Sync

**Goal:** Optional cloud backup for .STATUS files and flow state

#### Commands

```bash
# Initialize cloud backend
flow cloud init                    # Interactive setup wizard
flow cloud init --backend github   # GitHub gist backend
flow cloud init --backend s3       # S3 bucket backend

# Push/Pull
flow cloud push                    # Upload local state
flow cloud pull                    # Download remote state
flow cloud sync                    # Bidirectional sync

# Status
flow cloud status                  # Show sync status
flow cloud diff                    # Show local/remote differences

# Configuration
flow cloud config show             # Show current config
flow cloud config set key value    # Set config value
```

#### Backends (Ordered by Priority)

1. **GitHub Gist** (First implementation)
   - Uses existing gh CLI authentication
   - Free, widely available
   - Private gists for security

2. **Local file sync** (Second)
   - Sync to Dropbox/iCloud folder
   - Zero configuration
   - Uses existing cloud sync

3. **S3-compatible** (Future)
   - Self-hosted option
   - End-to-end encryption
   - For advanced users

#### Security Requirements

- [ ] End-to-end encryption for all data
- [ ] Local encryption key (never uploaded)
- [ ] Minimal data exposure (no project content)
- [ ] Clear data deletion capability

#### Implementation

| Component           | Description                 | Priority |
| ------------------- | --------------------------- | -------- |
| `flow cloud`        | Cloud dispatcher            | High     |
| GitHub backend      | gh gist integration         | High     |
| Encryption          | AES-256 local encryption    | High     |
| Conflict resolution | Last-write-wins with backup | Medium   |
| Local backend       | Folder-based sync           | Low      |
| S3 backend          | aws-cli integration         | Future   |

---

### 3. Team Features

**Goal:** Optional sharing of project templates and dashboards

#### Commands

```bash
# Team space
flow team init                     # Initialize team workspace
flow team invite <email>           # Invite team member
flow team members                  # List team members

# Templates
flow team template list            # List shared templates
flow team template share <name>    # Share project template
flow team template use <name>      # Use shared template

# Dashboard
flow team dash                     # Team activity dashboard
flow team dash --project <name>    # Project-specific team view
```

#### Scope Limitations

- **No real-time sync** - Templates only
- **No project content** - Metadata only
- **Opt-in only** - Never auto-share

#### Implementation

| Component       | Description            | Priority |
| --------------- | ---------------------- | -------- |
| Template export | .STATUS → template     | Medium   |
| Template import | template → new project | Medium   |
| Team registry   | Simple JSON + git      | Low      |
| Activity feed   | Recent team actions    | Future   |

---

## Implementation Phases

### Phase 1: Cross-Tool Sync (v4.0.0-alpha)

**Timeline:** 2 weeks
**Deliverables:**

- [ ] `flow sync` dispatcher
- [ ] Atlas registry sync
- [ ] Git multi-repo status
- [ ] Basic export/import

### Phase 2: Cloud Backup (v4.0.0-beta)

**Timeline:** 3 weeks
**Deliverables:**

- [ ] `flow cloud` dispatcher
- [ ] GitHub gist backend
- [ ] Local encryption
- [ ] Conflict handling

### Phase 3: Team Features (v4.0.0-rc)

**Timeline:** 2 weeks
**Deliverables:**

- [ ] Template export/import
- [ ] Team workspace init
- [ ] Team dashboard

### Phase 4: Polish (v4.0.0)

**Timeline:** 1 week
**Deliverables:**

- [ ] Documentation
- [ ] Migration guide
- [ ] Performance testing
- [ ] Release notes

---

## Technical Decisions

### Storage Format

```yaml
# ~/.flow/cloud.yml
backend: github
gist_id: abc123...
last_sync: 2025-01-15T10:30:00Z
encryption_key_path: ~/.flow/cloud.key
```

### Encryption

- AES-256-GCM for data at rest
- Key derived from user passphrase
- Key never leaves local machine

### Conflict Resolution

1. Detect conflict (local and remote modified)
2. Create backup of both versions
3. Apply last-write-wins
4. Notify user of resolution
5. Keep conflict log for audit

---

## Non-Goals

These are explicitly **out of scope** for v4.0.0:

- [ ] Real-time collaboration
- [ ] Project file sync (use git)
- [ ] Centralized server
- [ ] User accounts/authentication (use existing tools)
- [ ] Billing/premium features

---

## Success Metrics

| Metric                     | Target                 |
| -------------------------- | ---------------------- |
| Sync command latency       | < 500ms for local ops  |
| Cloud push latency         | < 2s for typical state |
| New command learning curve | < 5 minutes            |
| Breaking changes           | Zero (additive only)   |

---

## Open Questions

1. **Backend priority:** Start with GitHub or local folder sync?
2. **Encryption UX:** Passphrase on every sync or session-based?
3. **Team scope:** Worth including in v4.0.0 or defer to v4.1.0?

---

## Related Documents

- [Architecture Roadmap](../architecture/ARCHITECTURE-ROADMAP.md)
- [.STATUS](../../.STATUS)
- [Dispatcher Reference](../reference/DISPATCHER-REFERENCE.md)

---

**Last Updated:** 2025-12-27
**Status:** Planning
**Next Action:** Finalize Phase 1 scope
