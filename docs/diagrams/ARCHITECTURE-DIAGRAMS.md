# flow-cli Architecture Diagrams

**Version:** 5.10.0
**Last Updated:** 2026-01-15

---

## System Overview

```mermaid
graph TB
    subgraph "User Interface"
        CLI[ZSH Commands]
        Aliases[Shell Aliases]
        Completions[Tab Completions]
    end

    subgraph "Core Layer"
        Core[lib/core.zsh<br/>Colors, Logging, Utils]
        Config[lib/config.zsh<br/>Configuration]
        Cache[lib/project-cache.zsh<br/>Caching]
    end

    subgraph Dispatchers ["Dispatchers (13)"]
        G[g - Git]
        CC[cc - Claude Code]
        MCP[mcp - MCP Servers]
        WT[wt - Worktrees]
        Teach[teach - Teaching]
        R[r - R Packages]
        Qu[qu - Quarto]
        TM[tm - Terminal]
        Obs[obs - Obsidian]
        Dot[dot - Dotfiles]
        Prompt[prompt - Prompt Engine]
        V[v - Vibe/Workflow]
        EM[em - Email]
    end

    subgraph Commands [Commands]
        Work[work/finish/hop<br/>Session Management]
        Pick[pick<br/>Project Picker]
        Dash[dash<br/>Dashboard]
        Doctor[flow doctor<br/>Health Check]
        ADHD[js/next/stuck<br/>ADHD Helpers]
        Morning[morning/today<br/>Daily Routine]
        Capture[catch/win/yay<br/>Quick Capture]
        AI[ai/flow do<br/>AI Assistance]
    end

    subgraph "External Tools"
        Git[Git]
        Claude[Claude CLI]
        FZF[fzf]
        Atlas[Atlas<br/>(optional)]
    end

    CLI --> Core
    Aliases --> Dispatchers
    Completions --> Commands

    Core --> Cache
    Core --> Config

    Dispatchers --> Core
    Commands --> Core

    G --> Git
    CC --> Claude
    Pick --> FZF

    style Core fill:#e1f5ff
    style Dispatchers fill:#fff3e0
    style Commands fill:#f3e5f5
```

---

## Dispatcher Architecture

```mermaid
graph LR
    subgraph "Dispatcher Pattern"
        User[User Input]
        Router[Dispatcher Function]
        Sub1[Subcommand 1]
        Sub2[Subcommand 2]
        Sub3[Subcommand 3]
        Help[Help Function]
    end

    User -->|"g push"| Router
    Router -->|parse| Sub1
    Router -->|parse| Sub2
    Router -->|parse| Sub3
    Router -->|"--help"| Help

    Sub1 -->|delegate| External[External Tool]
    Sub2 -->|execute| Internal[Internal Logic]

    style Router fill:#4fc3f7
    style Help fill:#ffb74d
```

**Example Flow:**

```
User types: g push origin main
    ↓
g() function receives args
    ↓
Parse: subcommand="push", args=[origin, main]
    ↓
Route to: _g_push origin main
    ↓
Execute: git push origin main
    ↓
Log result with _flow_log_success
```

---

## Worktree Detection Flow

```mermaid
flowchart TD
    Start[_proj_list_worktrees]
    ScanL1[Scan Level 1<br/>~/.git-worktrees/*/]

    CheckGit{Is .git<br/>a FILE?}
    ParseGit[Parse gitdir line]
    ExtractNames[Extract project & branch]
    AddFlat[Add to flat worktrees]

    ScanL2[Scan Level 2<br/>dir/*/]
    CheckL2{Has .git?}
    AddHier[Add to hierarchical worktrees]

    Merge[Merge & Sort Results]
    Return[Return Worktree List]

    Start --> ScanL1
    ScanL1 --> CheckGit

    CheckGit -->|Yes| ParseGit
    ParseGit --> ExtractNames
    ExtractNames --> AddFlat
    AddFlat --> ScanL2

    CheckGit -->|No| ScanL2
    ScanL2 --> CheckL2
    CheckL2 -->|Yes| AddHier
    CheckL2 -->|No| ScanL2

    AddHier --> Merge
    ScanL2 --> Merge
    Merge --> Return

    style CheckGit fill:#fff9c4
    style ParseGit fill:#c5e1a5
    style Merge fill:#b3e5fc
```

**Worktree Structure Detection:**

```mermaid
graph TB
    subgraph "Flat Structure (Level 1)"
        Flat1[~/.git-worktrees/scholar-github-actions/]
        FlatGit[.git FILE]
        FlatGitDir["gitdir: /path/scholar/.git/worktrees/github-actions"]
    end

    subgraph "Hierarchical Structure (Level 2)"
        Hier1[~/.git-worktrees/scribe/]
        Hier2[quarto-v115/]
        HierGit[.git FILE]
    end

    Flat1 --> FlatGit
    FlatGit --> FlatGitDir

    Hier1 --> Hier2
    Hier2 --> HierGit

    style Flat1 fill:#ffccbc
    style Hier1 fill:#c5cae9
```

---

## Cache Invalidation Flow

```mermaid
sequenceDiagram
    participant User
    participant WT as wt create
    participant Git
    participant Cache as _proj_cache_invalidate
    participant Pick as pick command

    User->>WT: wt create feature/new
    WT->>Git: git worktree add
    Git-->>WT: Worktree created

    WT->>Cache: _proj_cache_invalidate()
    Cache->>Cache: Remove cache file
    Cache-->>WT: Cache cleared

    WT-->>User: ✓ Created worktree

    User->>Pick: pick wt
    Pick->>Pick: Cache miss → Full scan
    Pick->>Pick: Detect new worktree
    Pick-->>User: Show all worktrees (including new)

    Note over Cache,Pick: No TTL wait - immediate visibility
```

---

## Teaching System Integration

```mermaid
graph TB
    subgraph "flow-cli Layer"
        TeachInit[teach init]
        TeachStatus[teach status]
        TeachExam[teach exam]
        Validator[Config Validator<br/>JSON Schema]
    end

    subgraph "Configuration"
        Config[teach-config.yml]
        Schema[teach-config.schema.json]
    end

    subgraph "Scholar Layer"
        ScholarExam["/teaching:exam"]
        ScholarQuiz["/teaching:quiz"]
        ScholarSlides["/teaching:slides"]
    end

    subgraph "External"
        Claude[Claude CLI]
    end

    TeachInit -->|create| Config
    Config -->|validate against| Schema
    Validator -->|read| Schema
    Validator -->|validate| Config

    TeachStatus -->|check| Validator
    TeachExam -->|validate config| Validator
    TeachExam -->|call| Claude
    Claude -->|invoke| ScholarExam
    ScholarExam -->|read| Config

    style Config fill:#fff59d
    style Validator fill:#a5d6a7
    style Claude fill:#90caf9
```

**Config Ownership Protocol:**

```mermaid
graph LR
    subgraph "teach-config.yml"
        Course[course:<br/>name, semester, year]
        Semester[semester_info:<br/>dates, breaks]
        Scholar[scholar:<br/>style, topics, grading]
    end

    FlowCLI[flow-cli<br/>OWNS]
    ScholarPlugin[Scholar<br/>OWNS]

    FlowCLI -->|read/write| Course
    FlowCLI -->|read/write| Semester

    ScholarPlugin -->|read only| Course
    ScholarPlugin -->|read/write| Scholar

    style FlowCLI fill:#81c784
    style ScholarPlugin fill:#64b5f6
    style Course fill:#fff59d
    style Scholar fill:#ce93d8
```

---

## Session Management Flow

```mermaid
stateDiagram-v2
    [*] --> Idle

    Idle --> Working: work <project>
    Working --> Working: continue working
    Working --> Finished: finish [message]
    Working --> Switched: hop <project>

    Switched --> Working: tmux window created

    Finished --> Idle: session logged

    note right of Working
        Session tracked:
        - Start time
        - Project
        - Changes
    end note

    note right of Finished
        Optional git commit
        Session duration logged
    end note
```

---

## Pick Command Data Flow

```mermaid
flowchart LR
    subgraph "Input"
        Args[Arguments<br/>pick wt scholar]
    end

    subgraph "Processing"
        Parse[Parse Category<br/>wt]
        Filter[Parse Filter<br/>scholar]
        Scan[Scan Function<br/>_proj_list_worktrees]
    end

    subgraph "Data Sources"
        Cache{Cache<br/>Valid?}
        FullScan[Full Scan<br/>~/.git-worktrees]
        Sessions[Session Data<br/>~/.cache/claude]
    end

    subgraph "Output"
        Format[Format Results<br/>+ icons + session age]
        FZF[fzf Preview]
        Select[User Selection]
        Action[Execute Action]
    end

    Args --> Parse
    Parse --> Filter
    Filter --> Scan

    Scan --> Cache
    Cache -->|Hit| Format
    Cache -->|Miss| FullScan
    FullScan --> Format

    Sessions --> Format
    Format --> FZF
    FZF --> Select
    Select --> Action

    Action -->|Enter| CD[cd to directory]
    Action -->|Ctrl-O| CC[Launch Claude]

    style Cache fill:#fff9c4
    style Format fill:#c5e1a5
    style FZF fill:#b3e5fc
```

---

## Dependency Graph

```mermaid
graph TD
    subgraph "Required"
        ZSH[ZSH 5.8+]
        Git[Git 2.30+]
    end

    subgraph "Recommended"
        FZF[fzf 0.40+]
        Claude[Claude CLI]
    end

    subgraph "Optional"
        Atlas[Atlas]
        Tmux[tmux]
        JQ[jq]
        YQ[yq]
    end

    subgraph "Features"
        Core[Core Commands]
        Pick[Project Picker]
        CC[Claude Integration]
        Optional[Optional Features]
    end

    ZSH --> Core
    Git --> Core

    FZF --> Pick
    Claude --> CC

    Atlas --> Optional
    Tmux --> Optional
    JQ --> Optional
    YQ --> Optional

    style ZSH fill:#4caf50
    style Git fill:#4caf50
    style FZF fill:#ff9800
    style Claude fill:#ff9800
    style Atlas fill:#9e9e9e
```

---

## Color System Architecture

```mermaid
graph TB
    subgraph "FLOW_COLORS Associative Array"
        Status[Status Colors<br/>success, warning, error, info]
        Project[Project Status<br/>active, paused, blocked, archived]
        UI[UI Elements<br/>header, accent, muted, cmd]
        Format[Formatting<br/>reset, bold, dim]
    end

    subgraph "Usage"
        Log[_flow_log functions]
        Output[Command output]
        TUI[TUI components]
    end

    Status --> Log
    Project --> Output
    UI --> TUI
    Format --> Log
    Format --> Output

    style Status fill:#c8e6c9
    style Project fill:#fff9c4
    style UI fill:#b3e5fc
```

**Color Palette (ADHD-Friendly):**

```
Success:  #729C51 (Soft Green)
Warning:  #E5C07B (Warm Yellow)
Error:    #E06C75 (Soft Red)
Info:     #61AFEF (Calm Blue)
Active:   #729C51 (Green)
Paused:   #E5C07B (Yellow)
Header:   #9D9CC9 (Soft Purple)
Accent:   #D19A66 (Soft Orange)
```

---

## Plugin Architecture (Extensibility)

```mermaid
graph TB
    subgraph "flow-cli Core"
        PluginLoader[lib/plugin-loader.zsh]
        PluginAPI[Plugin API]
    end

    subgraph "Plugin Structure"
        PluginJSON[plugin.json<br/>Metadata]
        PluginMain[main.zsh<br/>Entry Point]
        PluginCmds[commands/<br/>Custom Commands]
    end

    subgraph "Plugin Types"
        Dispatcher[Dispatcher Plugin<br/>New dispatcher]
        Command[Command Plugin<br/>New command]
        Hook[Hook Plugin<br/>Event hooks]
    end

    PluginLoader -->|discover| PluginJSON
    PluginLoader -->|load| PluginMain
    PluginLoader -->|register| PluginCmds

    PluginAPI -->|enable| Dispatcher
    PluginAPI -->|enable| Command
    PluginAPI -->|enable| Hook

    style PluginLoader fill:#4fc3f7
    style PluginAPI fill:#81c784
```

---

## Configuration Hierarchy

```mermaid
graph TD
    subgraph "Configuration Sources"
        Defaults[Built-in Defaults]
        Global[~/.config/flow-cli/config.yml]
        Project[.flow-cli.yml]
        Env[Environment Variables]
    end

    subgraph "Resolution"
        Merge[Configuration Merger]
    end

    subgraph "Result"
        Runtime[Runtime Config]
    end

    Defaults -->|lowest priority| Merge
    Global -->|medium priority| Merge
    Project -->|high priority| Merge
    Env -->|highest priority| Merge

    Merge --> Runtime

    style Env fill:#ff9800
    style Project fill:#4caf50
    style Global fill:#2196f3
    style Defaults fill:#9e9e9e
```

**Priority Order:**

1. Environment Variables (highest)
2. Project `.flow-cli.yml`
3. Global `~/.config/flow-cli/config.yml`
4. Built-in Defaults (lowest)

---

## Error Handling Flow

```mermaid
flowchart TD
    Start[Command Execution]
    Try{Try Operation}

    Success[_flow_log_success]
    Warning[_flow_log_warning]
    Error[_flow_log_error]

    HandleError{Error Type}
    Recoverable[Suggest Fix]
    Fatal[Exit with Code]

    Start --> Try
    Try -->|Success| Success
    Try -->|Warning| Warning
    Try -->|Error| Error

    Error --> HandleError
    HandleError -->|Recoverable| Recoverable
    HandleError -->|Fatal| Fatal

    Recoverable -->|User Action| Start

    style Success fill:#c8e6c9
    style Warning fill:#fff9c4
    style Error fill:#ffcdd2
    style Fatal fill:#ef9a9a
```

**Error Types:**

- **Recoverable:** Missing dependency, config issue → Suggest `flow doctor --fix`
- **Fatal:** Permission denied, git error → Exit with code 1

---

## Test Architecture

```mermaid
graph TB
    subgraph "Test Suites"
        Unit[Unit Tests<br/>39 tests]
        Integration[Integration Tests<br/>37 tests]
        E2E[E2E Tests<br/>112 tests]
    end

    subgraph "Test Framework"
        Assert[Assertion Helpers]
        Mock[Mock Environment]
        Cleanup[Cleanup Hooks]
    end

    subgraph "CI/CD"
        GitHub[GitHub Actions]
        Local[Local Test Runner]
    end

    Unit --> Assert
    Integration --> Mock
    E2E --> Mock

    Assert --> Cleanup
    Mock --> Cleanup

    GitHub -->|run| Unit
    GitHub -->|run| Integration
    Local -->|run| E2E

    style Unit fill:#c5e1a5
    style Integration fill:#b3e5fc
    style E2E fill:#f8bbd0
```

---

## Deployment Pipeline

```mermaid
flowchart LR
    subgraph "Development"
        Dev[dev branch]
        Feature[feature/* branches]
        Worktree[Worktrees]
    end

    subgraph "Testing"
        Tests[Run All Tests]
        Lint[Linting]
    end

    subgraph "Integration"
        PR[Pull Request]
        Review[Code Review]
    end

    subgraph "Release"
        Main[main branch]
        Tag[Git Tag]
        Homebrew[Homebrew Formula]
        Docs[GitHub Pages]
    end

    Feature --> Worktree
    Worktree --> Tests
    Tests --> Lint
    Lint --> PR

    PR --> Review
    Review -->|Approved| Dev

    Dev -->|Release PR| Main
    Main --> Tag
    Tag --> Homebrew
    Tag --> Docs

    style Dev fill:#81c784
    style Main fill:#4caf50
    style Tag fill:#ff9800
```

---

## See Also

- [API-COMPLETE.md](../reference/MASTER-API-REFERENCE.md) - Complete API reference
- [ARCHITECTURE.md](../reference/MASTER-ARCHITECTURE.md) - System architecture document
- [DISPATCHER-REFERENCE.md](../reference/MASTER-DISPATCHER-GUIDE.md) - Dispatcher details

---

**Last Updated:** 2026-01-15
**Version:** 5.10.0
