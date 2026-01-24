# flow-cli Architecture

**Version:** v5.9.0
**Last Updated:** 2026-01-14

---

## System Overview

```mermaid
graph TB
    subgraph "User Interface"
        CLI[ZSH Commands]
        Completions[Tab Completions]
    end

    subgraph "Core Layer"
        Plugin[flow.plugin.zsh]
        Core[lib/core.zsh]
        Commands[commands/*.zsh]
    end

    subgraph "Dispatchers"
        G[g - Git]
        CC[cc - Claude Code]
        DOT[dot - Dotfiles]
        MCP[mcp - MCP Servers]
        R[r - R Packages]
        QU[qu - Quarto]
        WT[wt - Worktrees]
        TM[tm - Terminal]
        OBS[obs - Obsidian]
        TEACH[teach - Teaching]
    end

    subgraph "State Layer"
        ENV[Environment Variables]
        Files[Local Files]
        Project[Project State]
        Atlas[Atlas Engine]
    end

    subgraph "External Tools"
        Git[git]
        Chezmoi[chezmoi]
        BW[Bitwarden CLI]
        Keychain[macOS Keychain]
        Claude[Claude Code]
    end

    CLI --> Plugin
    Plugin --> Core
    Plugin --> Commands
    Plugin --> Dispatchers

    G --> Git
    DOT --> Chezmoi
    DOT --> BW
    DOT --> Keychain
    CC --> Claude
    WT --> Git

    Core --> ENV
    Core --> Files
    Commands --> Project
    Core -.-> Atlas
```

---

## Dispatcher Architecture

Each dispatcher follows a consistent pattern:

```mermaid
graph LR
    User[User Input] --> Dispatcher[Dispatcher Function]
    Dispatcher --> Router{Command Router}
    Router -->|action1| Handler1[_dispatcher_action1]
    Router -->|action2| Handler2[_dispatcher_action2]
    Router -->|help| Help[_dispatcher_help]
    Router -->|default| Default[Default Action]

    Handler1 --> External[External Tool]
    Handler2 --> Internal[Internal Logic]
```

### Dispatcher Pattern

```zsh
# Standard dispatcher structure
<letter>() {
    local cmd="$1"
    shift 2>/dev/null

    case "$cmd" in
        action1) _<letter>_action1 "$@" ;;
        action2) _<letter>_action2 "$@" ;;
        help|--help|-h) _<letter>_help ;;
        *) _<letter>_default "$cmd" "$@" ;;
    esac
}
```

---

## State Management

```mermaid
graph TB
    subgraph "Layer 1: Environment (Ephemeral)"
        FLOW_PROJECT[FLOW_CURRENT_PROJECT]
        FLOW_START[FLOW_SESSION_START]
        FLOW_ROOT[FLOW_PROJECTS_ROOT]
    end

    subgraph "Layer 2: User Files (Persistent)"
        Session[.current-session]
        Worklog[worklog]
        Wins[wins.md]
        Inbox[inbox.md]
    end

    subgraph "Layer 3: Project State"
        STATUS[.STATUS]
        CLAUDE[.claude/]
        GIT[.git/]
    end

    subgraph "Layer 4: Atlas (Optional)"
        AtlasDB[(Atlas State Engine)]
    end

    FLOW_PROJECT --> Session
    Session --> STATUS
    STATUS -.-> AtlasDB
```

### State Locations

| Layer | Location | Persistence | Purpose |
|-------|----------|-------------|---------|
| 1 | `$FLOW_*` | Session | Current context |
| 2 | `~/.config/flow-cli/` | User | Session history |
| 2 | `~/Library/Application Support/flow-cli/` | User | Logs, captures |
| 3 | `{project}/.STATUS` | Project | Project metadata |
| 4 | Atlas database | Global | Enhanced state (optional) |

---

## Secret Management Architecture (v5.5.0)

```mermaid
graph TB
    subgraph "Primary: macOS Keychain"
        KC[Keychain Access]
        TouchID[Touch ID]
        AppleWatch[Apple Watch]
    end

    subgraph "Fallback: Bitwarden"
        BW[Bitwarden CLI]
        Session[15-min Session Cache]
        Cloud[Bitwarden Cloud]
    end

    subgraph "DOT Secret Commands"
        Add[dot secret add]
        Get[dot secret get]
        List[dot secret list]
        Import[dot secret import]
    end

    Add --> KC
    Get --> KC
    Get -.->|fallback| BW
    List --> KC
    Import --> BW
    Import --> KC

    KC --> TouchID
    KC --> AppleWatch
    BW --> Session
    Session --> Cloud
```

### Secret Storage Comparison

| Feature | macOS Keychain | Bitwarden |
|---------|----------------|-----------|
| Access Speed | Instant | Requires unlock |
| Authentication | Touch ID, Watch | Master password |
| Offline | Yes | After unlock |
| Team Sharing | No | Yes |
| Cross-device | iCloud Keychain | Cloud sync |
| Session timeout | None (auto-lock) | 15 minutes |

---

## Config Validation Architecture (v5.9.0)

```mermaid
graph TB
    subgraph "Config Files"
        YAML[teach-config.yml]
        Schema[teach-config.schema.json]
    end

    subgraph "Validation Layer"
        Validator[_teach_validate_config]
        HashCheck[_flow_config_hash]
        Cache[Hash Cache]
    end

    subgraph "Validation Rules"
        Required[Required Fields]
        Enum[Enum Validation]
        Range[Range Validation]
        Sum[Grading Sum Check]
    end

    subgraph "Consumers"
        Status[teach status]
        Exam[teach exam]
        Quiz[teach quiz]
    end

    YAML --> Validator
    Schema --> Validator
    Validator --> Required
    Validator --> Enum
    Validator --> Range
    Validator --> Sum

    YAML --> HashCheck
    HashCheck --> Cache

    Status --> Validator
    Exam --> Validator
    Quiz --> Validator
```

### Validation Flow

```mermaid
sequenceDiagram
    participant User
    participant teach
    participant Validator
    participant Schema
    participant Cache

    User->>teach: teach exam "Topic"
    teach->>Validator: _teach_validate_config()
    Validator->>Cache: _flow_config_changed()
    alt Config Changed
        Cache-->>Validator: changed (0)
        Validator->>Schema: Validate against schema
        Schema-->>Validator: validation result
        Validator->>Cache: Update hash
    else Config Unchanged
        Cache-->>Validator: unchanged (1)
        Validator-->>teach: Use cached result
    end
    teach->>User: Proceed or show errors
```

### Config Ownership Protocol

```mermaid
graph LR
    subgraph "flow-cli Owns"
        Course[course]
        Semester[semester_info]
        Branches[branches]
        Deploy[deployment]
    end

    subgraph "Scholar Owns"
        ScholarInfo[scholar.course_info]
        Style[scholar.style]
        Topics[scholar.topics]
        Grading[scholar.grading]
    end

    subgraph "Shared"
        Examark[examark]
        Shortcuts[shortcuts]
    end

    Course --> Config[teach-config.yml]
    Semester --> Config
    Branches --> Config
    Deploy --> Config
    ScholarInfo --> Config
    Style --> Config
    Topics --> Config
    Grading --> Config
    Examark --> Config
    Shortcuts --> Config
```

---

## Command Flow

```mermaid
sequenceDiagram
    participant User
    participant ZSH
    participant Dispatcher
    participant Handler
    participant External

    User->>ZSH: cc pick
    ZSH->>Dispatcher: cc("pick")
    Dispatcher->>Handler: _cc_pick()
    Handler->>External: fzf (project selection)
    External-->>Handler: selected project
    Handler->>External: claude (launch)
    External-->>User: Claude Code session
```

---

## Project Detection

```mermaid
flowchart TD
    Start[Detect Project Type] --> Check1{package.json?}
    Check1 -->|Yes| Node[Node.js Project]
    Check1 -->|No| Check2{DESCRIPTION?}
    Check2 -->|Yes| R[R Package]
    Check2 -->|No| Check3{_quarto.yml?}
    Check3 -->|Yes| Quarto[Quarto Project]
    Check3 -->|No| Check4{.obsidian/?}
    Check4 -->|Yes| Obsidian[Obsidian Vault]
    Check4 -->|No| Check5{pyproject.toml?}
    Check5 -->|Yes| Python[Python Project]
    Check5 -->|No| Generic[Generic Project]
```

---

## File Structure

```
flow-cli/
├── flow.plugin.zsh       # Entry point
├── lib/
│   ├── core.zsh          # Logging, colors, utilities
│   ├── atlas-bridge.zsh  # Optional Atlas integration
│   ├── project-detector.zsh
│   ├── tui.zsh           # Terminal UI components
│   ├── keychain-helpers.zsh  # macOS Keychain (v5.5.0)
│   └── dispatchers/
│       ├── cc-dispatcher.zsh    # Claude Code
│       ├── dot-dispatcher.zsh   # Dotfiles + Secrets
│       ├── g-dispatcher.zsh     # Git workflows
│       ├── mcp-dispatcher.zsh   # MCP servers
│       ├── r-dispatcher.zsh     # R packages
│       ├── qu-dispatcher.zsh    # Quarto
│       ├── wt-dispatcher.zsh    # Worktrees
│       ├── tm-dispatcher.zsh    # Terminal
│       ├── obs.zsh              # Obsidian
│       └── teach-dispatcher.zsh # Teaching
├── commands/
│   ├── work.zsh          # work, finish, hop
│   ├── dash.zsh          # Dashboard
│   ├── capture.zsh       # win, yay, catch
│   ├── pick.zsh          # Project picker
│   ├── doctor.zsh        # Health check
│   └── flow.zsh          # Main flow command
├── completions/          # ZSH completions
├── hooks/                # chpwd, precmd hooks
└── tests/                # Test suites
```

---

## Performance Targets

| Operation | Target | Actual |
|-----------|--------|--------|
| Plugin load | < 50ms | ~30ms |
| Core commands | < 10ms | ~5ms |
| Dispatchers | < 100ms | ~50ms |
| Dashboard | < 500ms | ~300ms |
| Keychain access | < 100ms | ~50ms |

---

## Design Principles

1. **Pure ZSH** - No Node.js runtime, no build step
2. **ADHD-Friendly** - Fast, forgiving, discoverable
3. **Graceful Degradation** - Works without optional dependencies
4. **Consistent Patterns** - Same structure across all dispatchers
5. **Progressive Disclosure** - Simple defaults, power when needed

---

## See Also

- [Workflow Architecture Analysis](../specs/workflow-system-architecture-analysis.md)
- [Dispatcher Reference](DISPATCHER-REFERENCE.md)
- [Project Detection Guide](PROJECT-DETECTION-GUIDE.md)
