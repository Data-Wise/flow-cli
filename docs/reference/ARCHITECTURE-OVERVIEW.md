# flow-cli Architecture Overview

**Version:** 5.15.0
**Updated:** 2026-01-21

---

## System Architecture

```mermaid
flowchart TB
    subgraph "User Interface"
        CLI[ZSH Shell]
        COMP[Tab Completions]
    end

    subgraph "Entry Point"
        PLUGIN[flow.plugin.zsh]
    end

    subgraph "Command Layer"
        CMDS[commands/*.zsh]
        CMDS --> WORK[work.zsh]
        CMDS --> DASH[dash.zsh]
        CMDS --> FLOW[flow.zsh]
        CMDS --> PICK[pick.zsh]
        CMDS --> CAPTURE[capture.zsh]
    end

    subgraph "Dispatcher Layer (11 Active)"
        DISP[lib/dispatchers/*.zsh]
        DISP --> G[g - Git]
        DISP --> CC[cc - Claude Code]
        DISP --> TEACH[teach - Teaching]
        DISP --> R[r - R Packages]
        DISP --> QU[qu - Quarto]
        DISP --> MCP[mcp - MCP Servers]
        DISP --> OBS[obs - Obsidian]
        DISP --> TM[tm - Terminal]
        DISP --> WT[wt - Worktrees]
        DISP --> DOT[dot - Dotfiles]
        DISP --> PROMPT[prompt - Engine]
    end

    subgraph "Helper Libraries (32)"
        LIB[lib/*.zsh]
        LIB --> CORE[core.zsh]
        LIB --> ATLAS[atlas-bridge.zsh]
        LIB --> TUI[tui.zsh]
        LIB --> GIT[git-helpers.zsh]
        LIB --> VALID[validation-helpers.zsh]
        LIB --> CACHE[cache-helpers.zsh]
    end

    subgraph "Templates"
        TPL[lib/templates/]
        TPL --> TEACHING[teaching/]
        TEACHING --> PROMPTS[claude-prompts/]
        TEACHING --> CONFIG[teach-config.yml.template]
    end

    subgraph "External Integrations"
        SCHOLAR[Scholar Plugin]
        ATLASEXT[Atlas State Engine]
        MCPSERV[MCP Servers]
    end

    CLI --> PLUGIN
    COMP --> CLI
    PLUGIN --> CMDS
    PLUGIN --> DISP
    PLUGIN --> LIB
    CMDS --> LIB
    DISP --> LIB
    TEACH -.->|uses| SCHOLAR
    DISP -.->|optional| ATLASEXT
    MCP -.->|manages| MCPSERV
```

---

## Component Hierarchy

### Layer 1: Entry Point

```
flow.plugin.zsh
├── Sources lib/core.zsh (utilities, colors, logging)
├── Sources lib/*.zsh (helper libraries)
├── Sources lib/dispatchers/*.zsh (11 dispatchers)
├── Sources commands/*.zsh (core commands)
├── Sets up completions
└── Initializes hooks
```

### Layer 2: Dispatchers (Smart Commands)

Each dispatcher follows this pattern:

```mermaid
flowchart LR
    subgraph "Dispatcher Pattern"
        MAIN[main function]
        MAIN --> CASE{case $1}
        CASE --> |action1| A1[_dispatcher_action1]
        CASE --> |action2| A2[_dispatcher_action2]
        CASE --> |help| HELP[_dispatcher_help]
        CASE --> |*| DEFAULT[show help]
    end
```

**Active Dispatchers:**

| Dispatcher | Command | Functions | Purpose |
|------------|---------|-----------|---------|
| g | `g` | 10 | Git workflows |
| cc | `cc` | 7 | Claude Code launcher |
| teach | `teach` | 75 | Teaching workflows |
| r | `r` | 1+ | R package development |
| qu | `qu` | 1+ | Quarto publishing |
| mcp | `mcp` | 8 | MCP server management |
| obs | `obs` | 6 | Obsidian notes |
| tm | `tm` | 6 | Terminal manager |
| wt | `wt` | 9 | Git worktrees |
| dot | `dot` | 41 | Dotfile management |
| prompt | `prompt` | 12 | Prompt engine switcher |

### Layer 3: Helper Libraries

```mermaid
flowchart TB
    subgraph "Core Utilities"
        CORE[core.zsh]
        CORE --> |colors| COLORS[CYAN, GREEN, etc.]
        CORE --> |logging| LOG[_flow_log_*]
        CORE --> |utils| UTILS[_flow_find_root, etc.]
    end

    subgraph "Integration"
        ATLAS[atlas-bridge.zsh]
        GIT[git-helpers.zsh]
        KEYCHAIN[keychain-helpers.zsh]
    end

    subgraph "Teaching"
        VALID[validation-helpers.zsh]
        BACKUP[backup-helpers.zsh]
        CACHE[cache-helpers.zsh]
        PARALLEL[parallel-helpers.zsh]
    end

    subgraph "UI"
        TUI[tui.zsh]
        INV[inventory.zsh]
        HELP[help-browser.zsh]
    end
```

---

## Data Flow

### Session Lifecycle

```mermaid
sequenceDiagram
    participant U as User
    participant W as work command
    participant A as Atlas (optional)
    participant S as Session State

    U->>W: work myproject
    W->>W: Find project root
    W->>W: Detect project type
    W->>A: Register session (if enabled)
    A->>S: Store state
    W->>U: Session started

    Note over U,S: ... working ...

    U->>W: finish "commit message"
    W->>W: Git commit (if changes)
    W->>A: End session
    A->>S: Clear state
    W->>U: Session ended
```

### Teaching Workflow

```mermaid
flowchart LR
    subgraph "Content Creation"
        A[teach init] --> B[Configure course]
        B --> C[teach exam "Topic"]
        C --> D[Scholar generates]
    end

    subgraph "Validation"
        E[teach validate] --> F{Errors?}
        F -->|Yes| G[Fix issues]
        F -->|No| H[Ready]
    end

    subgraph "Deployment"
        H --> I[teach deploy]
        I --> J[Create PR]
        J --> K[GitHub Pages]
    end

    D --> E
    G --> E
```

---

## File Organization

```
flow-cli/
├── flow.plugin.zsh          # Entry point
│
├── lib/
│   ├── core.zsh             # Core utilities (colors, logging)
│   ├── atlas-bridge.zsh     # Optional Atlas integration
│   ├── tui.zsh              # Terminal UI components
│   ├── git-helpers.zsh      # Git integration
│   ├── keychain-helpers.zsh # macOS Keychain secrets
│   ├── config-validator.zsh # Config validation
│   ├── ...                  # (32 helper libraries total)
│   │
│   ├── dispatchers/         # Smart command dispatchers
│   │   ├── g-dispatcher.zsh
│   │   ├── cc-dispatcher.zsh
│   │   ├── teach-dispatcher.zsh
│   │   ├── ...              # (11 active dispatchers)
│   │   └── v-dispatcher.zsh # Experimental
│   │
│   └── templates/           # Template files
│       └── teaching/
│           ├── claude-prompts/
│           ├── teach-config.yml.template
│           └── exam-template.md
│
├── commands/                # Core commands
│   ├── work.zsh            # Session management
│   ├── dash.zsh            # Dashboard
│   ├── flow.zsh            # Main flow command
│   ├── pick.zsh            # Project picker
│   └── ...                 # (27 command files)
│
├── completions/            # ZSH completions
│   └── _*                  # Completion functions
│
├── hooks/                  # ZSH hooks
│
├── setup/                  # Installation scripts
│
├── tests/                  # Test suite (100+ files)
│
└── docs/                   # Documentation (306 files)
    ├── getting-started/
    ├── tutorials/
    ├── guides/
    ├── reference/
    └── commands/
```

---

## Integration Points

### External Systems

```mermaid
flowchart LR
    subgraph "flow-cli"
        TEACH[teach dispatcher]
        MCP[mcp dispatcher]
        CC[cc dispatcher]
        DOT[dot dispatcher]
    end

    subgraph "External"
        SCHOLAR[Scholar Plugin]
        MCPSERV[MCP Servers]
        CLAUDE[Claude Code]
        KEYCHAIN[macOS Keychain]
        ATLAS[Atlas Engine]
    end

    TEACH -.->|content generation| SCHOLAR
    MCP -.->|server management| MCPSERV
    CC -.->|launches| CLAUDE
    DOT -.->|secrets| KEYCHAIN
    ALL -.->|state| ATLAS
```

### Configuration

| Config | Location | Purpose |
|--------|----------|---------|
| Plugin settings | `~/.config/zsh/.zshrc` | Environment variables |
| Teaching config | `.teach/teaching.yml` | Course configuration |
| MCP config | `~/.claude/settings.json` | MCP server settings |
| Atlas state | `~/.atlas/` | Session state |

---

## Performance Considerations

### Design Goals

1. **Sub-10ms response** for core commands
2. **Lazy loading** where possible
3. **Cached project scanning**
4. **Parallel operations** for teaching workflows

### Key Optimizations

- Helper libraries only loaded when needed
- Project detection cached per session
- Parallel rendering for Quarto (3-10x speedup)
- Frecency-based project sorting

---

## Extension Points

### Adding a New Dispatcher

1. Create `lib/dispatchers/NAME-dispatcher.zsh`
2. Follow the dispatcher pattern (main function + case statement)
3. Add `_NAME_help()` function
4. Source in `flow.plugin.zsh`
5. Add completions in `completions/_NAME`
6. Document in `docs/reference/NAME-DISPATCHER-REFERENCE.md`

### Adding a New Command

1. Create `commands/NAME.zsh`
2. Use helpers from `lib/core.zsh`
3. Add help with `--help` flag
4. Source in `flow.plugin.zsh`
5. Add completions if needed

---

## Version Compatibility

| Component | Minimum Version |
|-----------|-----------------|
| ZSH | 5.8+ |
| Git | 2.30+ |
| macOS | 11.0+ (for Keychain) |
| Quarto | 1.3+ (for teaching) |

---

## Related Documentation

- [DISPATCHER-REFERENCE.md](DISPATCHER-REFERENCE.md) - All dispatchers overview
- [API-REFERENCE.md](API-REFERENCE.md) - Function reference
- [PHILOSOPHY.md](../PHILOSOPHY.md) - Design principles
- [CONVENTIONS.md](../CONVENTIONS.md) - Code standards
